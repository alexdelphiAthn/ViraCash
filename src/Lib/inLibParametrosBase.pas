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
    EsHeredado: Boolean;
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
    procedure ReleerParametrosInstalacion(const AClaves: array of string);
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
              SCategoriaParametrosHeredados,
              ParPerfil.Key,
              SDescripcionParametroHeredado,
              tpString,
              ParPerfil.Value.sValue
            );
            FDefiniciones[ParPerfil.Key].EsHeredado := True;
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

procedure TParametrosBase.ReleerParametrosInstalacion(
  const AClaves: array of string);
var
  Perfil: TProfileDicc;
  Clave: string;
  Valor: TDictValue;
  Parametro: TParametroDef;
begin
  Perfil := nil;
  try
    if not FPerfilesLectura.CargarPerfilFormulario(
      FFormularioPerfil, '', 'Todos', Perfil) then
      raise Exception.CreateFmt(SErrorCargarPerfilParametros,
        [FFormularioPerfil]);
    FSeccionCritica.Acquire;
    try
      for Clave in AClaves do
        if FDefiniciones.TryGetValue(Clave, Parametro) then
        begin
          Parametro.ValorActual := Parametro.ValorPorDefecto;
          if Assigned(Perfil) and Perfil.TryGetValue(Clave, Valor) then
            Parametro.ValorActual := Valor.sValue;
        end;
    finally
      FSeccionCritica.Release;
    end;
  finally
    Perfil.Free;
  end;
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
      // Resolver al listar permite cambiar de idioma sin recargar la BD.
      if Parametro.EsHeredado then
      begin
        Result[Indice].Categoria := SCategoriaParametrosHeredados;
        Result[Indice].Descripcion := SDescripcionParametroHeredado;
      end;
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
