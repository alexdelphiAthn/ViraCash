{******************************************************************************}
{                                                                              }
{  Módulo:       inLibParametrosBase                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       25/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Motor común y seguro para los parámetros de aplicación y de caja.         }
{******************************************************************************}
unit inLibParametrosBase;

interface

uses
  System.SysUtils, System.SyncObjs, System.Generics.Collections,
  inLibParametrosIntf, inLibPerfilesUsuarioIntf;

type
  TParametroDef = class
  public
    Categoria: string;
    Nombre: string;
    Descripcion: string;
    Tipo: TTipoParametro;
    ValorPorDefecto: string;
    ValorActual: string;
    constructor Create(
      const ACategoria, ANombre, ADescripcion: string;
      ATipo: TTipoParametro;
      const AValorPorDefecto: string
    );
  end;

  TParametrosBase = class(
    TInterfacedObject,
    IParametros,
    IParametrosEdicion
  )
  private
    FSeccionCritica: TCriticalSection;
    FDefiniciones: TObjectDictionary<string, TParametroDef>;
    FPerfilesLectura: ILectorPerfilesUsuario;
    FCachePerfiles: ICachePerfilesUsuario;
    FFormularioPerfil: string;
    FClavesExcluidas: TArray<string>;
    FUsuarioRecarga: string;
    function EsClaveExcluida(const AClave: string): Boolean;
    procedure RegistrarDefectosSinBloqueo;
    procedure RegistrarParametroSinBloqueo(
      const ACategoria, ANombre, ADescripcion: string;
      ATipo: TTipoParametro;
      const AValorPorDefecto: string
    );
  protected
    constructor Create(
      const APerfilesLectura: ILectorPerfilesUsuario;
      const ACachePerfiles: ICachePerfilesUsuario;
      const AFormularioPerfil: string;
      const AClavesExcluidas: TArray<string>
    );
    procedure DespuesDeRecargar; virtual;
    procedure Inicializar(const AUsuario, AGrupo: string);
    procedure RegistrarParametro(
      const ACategoria, ANombre, ADescripcion: string;
      ATipo: TTipoParametro;
      const AValorPorDefecto: string
    );
    // Usuario con el que se cargaron los valores; disponible en el
    // hook DespuesDeRecargar.
    property UsuarioRecargado: string read FUsuarioRecarga;
  public
    destructor Destroy; override;
    function GetString(
      const AKey: string;
      const ADefault: string = ''
    ): string;
    function GetBool(
      const AKey: string;
      const ADefault: Boolean = False
    ): Boolean;
    function GetInt(
      const AKey: string;
      const ADefault: Integer = 0
    ): Integer;
    function ListarDefiniciones: TArray<TParamInfo>;
    procedure Recargar(const AUsuario, AGrupo: string);
  end;

implementation

uses
  inLibMsgConfiguracion;

{ TParametroDef }

constructor TParametroDef.Create(
  const ACategoria, ANombre, ADescripcion: string;
  ATipo: TTipoParametro;
  const AValorPorDefecto: string);
begin
  Categoria := ACategoria;
  Nombre := ANombre;
  Descripcion := ADescripcion;
  Tipo := ATipo;
  ValorPorDefecto := AValorPorDefecto;
  ValorActual := AValorPorDefecto;
end;

{ TParametrosBase }

constructor TParametrosBase.Create(
  const APerfilesLectura: ILectorPerfilesUsuario;
  const ACachePerfiles: ICachePerfilesUsuario;
  const AFormularioPerfil: string;
  const AClavesExcluidas: TArray<string>);
begin
  inherited Create;
  if not Assigned(APerfilesLectura) or
     not Assigned(ACachePerfiles) then
    raise EArgumentNilException.Create(
      SErrorServicioPerfilesNoProporcionado);
  FSeccionCritica := TCriticalSection.Create;
  FDefiniciones :=
    TObjectDictionary<string, TParametroDef>.Create([doOwnsValues]);
  FPerfilesLectura := APerfilesLectura;
  FCachePerfiles := ACachePerfiles;
  FFormularioPerfil := AFormularioPerfil;
  FClavesExcluidas := System.Copy(
    AClavesExcluidas,
    0,
    Length(AClavesExcluidas)
  );
end;

destructor TParametrosBase.Destroy;
begin
  FPerfilesLectura := nil;
  FCachePerfiles := nil;
  FreeAndNil(FDefiniciones);
  FreeAndNil(FSeccionCritica);
  inherited;
end;

function TParametrosBase.EsClaveExcluida(const AClave: string): Boolean;
var
  ClaveExcluida: string;
begin
  Result := False;
  for ClaveExcluida in FClavesExcluidas do
  begin
    if SameText(AClave, ClaveExcluida) then
      Result := True;
  end;
end;

procedure TParametrosBase.RegistrarParametroSinBloqueo(
  const ACategoria, ANombre, ADescripcion: string;
  ATipo: TTipoParametro;
  const AValorPorDefecto: string);
begin
  FDefiniciones.AddOrSetValue(
    ANombre,
    TParametroDef.Create(
      ACategoria,
      ANombre,
      ADescripcion,
      ATipo,
      AValorPorDefecto
    )
  );
end;

procedure TParametrosBase.RegistrarParametro(
  const ACategoria, ANombre, ADescripcion: string;
  ATipo: TTipoParametro;
  const AValorPorDefecto: string);
begin
  FSeccionCritica.Acquire;
  try
    RegistrarParametroSinBloqueo(
      ACategoria,
      ANombre,
      ADescripcion,
      ATipo,
      AValorPorDefecto
    );
  finally
    FSeccionCritica.Release;
  end;
end;

procedure TParametrosBase.RegistrarDefectosSinBloqueo;
var
  Parametro: TParametroDef;
begin
  for Parametro in FDefiniciones.Values do
    Parametro.ValorActual := Parametro.ValorPorDefecto;
end;

procedure TParametrosBase.Inicializar(
  const AUsuario, AGrupo: string);
begin
  Recargar(AUsuario, AGrupo);
end;

procedure TParametrosBase.Recargar(
  const AUsuario, AGrupo: string);
var
  Perfil: TProfileDicc;
  ParPerfil: TPair<string, TDictValue>;
  Parametro: TParametroDef;
begin
  FUsuarioRecarga := AUsuario;
  Perfil := nil;
  try
    FCachePerfiles.ResincronizarPerfilFormulario(FFormularioPerfil);
    if not FPerfilesLectura.CargarPerfilFormulario(
      FFormularioPerfil,
      AUsuario,
      AGrupo,
      Perfil
    ) then
      raise Exception.CreateFmt(
        SErrorCargarPerfilParametros,
        [FFormularioPerfil]
      );
    if not Assigned(Perfil) then
      Perfil := TProfileDicc.Create;
    FSeccionCritica.Acquire;
    try
      RegistrarDefectosSinBloqueo;
      for ParPerfil in Perfil do
      begin
        if not EsClaveExcluida(ParPerfil.Key) then
        begin
          if FDefiniciones.TryGetValue(ParPerfil.Key, Parametro) then
            Parametro.ValorActual := ParPerfil.Value.sValue
          else
          begin
            RegistrarParametroSinBloqueo(
              'Otros (Heredados de BD)',
              ParPerfil.Key,
              'Parámetro sin descripción',
              tpString,
              ParPerfil.Value.sValue
            );
          end;
        end;
      end;
    finally
      FSeccionCritica.Release;
    end;
  finally
    FreeAndNil(Perfil);
  end;
  DespuesDeRecargar;
end;

procedure TParametrosBase.DespuesDeRecargar;
begin
end;

function TParametrosBase.GetString(
  const AKey, ADefault: string): string;
var
  Parametro: TParametroDef;
begin
  FSeccionCritica.Acquire;
  try
    if FDefiniciones.TryGetValue(AKey, Parametro) then
      Result := Parametro.ValorActual
    else
      Result := ADefault;
  finally
    FSeccionCritica.Release;
  end;
end;

function TParametrosBase.GetBool(
  const AKey: string;
  const ADefault: Boolean): Boolean;
var
  Parametro: TParametroDef;
begin
  FSeccionCritica.Acquire;
  try
    if FDefiniciones.TryGetValue(AKey, Parametro) then
      Result := SameText(Parametro.ValorActual, 'True') or
        (Parametro.ValorActual = '1')
    else
      Result := ADefault;
  finally
    FSeccionCritica.Release;
  end;
end;

function TParametrosBase.GetInt(
  const AKey: string;
  const ADefault: Integer): Integer;
var
  Parametro: TParametroDef;
begin
  FSeccionCritica.Acquire;
  try
    if FDefiniciones.TryGetValue(AKey, Parametro) then
    begin
      if not TryStrToInt(Parametro.ValorActual, Result) then
        Result := ADefault;
    end
    else
      Result := ADefault;
  finally
    FSeccionCritica.Release;
  end;
end;

function TParametrosBase.ListarDefiniciones: TArray<TParamInfo>;
var
  Parametro: TParametroDef;
  Indice: Integer;
begin
  FSeccionCritica.Acquire;
  try
    SetLength(Result, FDefiniciones.Count);
    Indice := 0;
    for Parametro in FDefiniciones.Values do
    begin
      Result[Indice].Categoria := Parametro.Categoria;
      Result[Indice].Nombre := Parametro.Nombre;
      Result[Indice].Descripcion := Parametro.Descripcion;
      Result[Indice].Tipo := Parametro.Tipo;
      Result[Indice].ValorPorDefecto := Parametro.ValorPorDefecto;
      Result[Indice].ValorActual := Parametro.ValorActual;
      Inc(Indice);
    end;
  finally
    FSeccionCritica.Release;
  end;
end;

end.
