{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCatalogoSqlAdmin                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Publicación, revisión y exportación del catálogo SQL en perfiles.         }
{******************************************************************************}
unit inLibCatalogoSqlAdmin;

interface

uses
  inLibCatalogoSqlIntf,
  inLibConexionPerfilIntf,
  inLibPerfilesUsuarioIntf;

type
  TEstadoPerfilSql = (
    epsSoloBase,
    epsFalta,
    epsDesactivado,
    epsBase,
    epsPersonalizado,
    epsInvalido);
  TRevisionPerfilSql = record
    ClavePerfil: string;
    Repositorio: string;
    Operacion: string;
    SqlBase: string;
    SqlPerfil: string;
    ValorPerfil: string;
    UltimaCausaFallback: string;
    Estado: TEstadoPerfilSql;
    Mensaje: string;
    HuellaBase: string;
    HuellaPerfil: string;
    Politica: TPoliticaEjecucionSql;
    Version: Integer;
    TienePerfil: Boolean;
  end;
  TRevisionesPerfilSql = array of TRevisionPerfilSql;
  TAdministradorSqlPerfiles = class
  private
    FPerfilesLectura: ILectorPerfilesUsuario;
    FPerfilesEscritura: IEscritorPerfilesUsuario;
    FMotor: TMotorBBDD;
    function CargarPerfil(
      const AClavePerfil: string): TProfileDicc;
    function PerfilActivo(const AValor: string): Boolean;
    function NombreSeguro(const ATexto: string): string;
    function NombreEstado(
      AEstado: TEstadoPerfilSql): string;
  public
    constructor Create(
      const APerfilesLectura: ILectorPerfilesUsuario;
      const APerfilesEscritura: IEscritorPerfilesUsuario); overload;
    constructor Create(
      const APerfilesLectura: ILectorPerfilesUsuario;
      const APerfilesEscritura: IEscritorPerfilesUsuario;
      AMotor: TMotorBBDD); overload;
    procedure PublicarFaltantes(
      const AClavePerfil: string;
      const ADefiniciones: TDefinicionesSql);
    procedure PublicarCatalogo(
      const ARegistro: IRegistroDefinicionesSql);
    function Revisar(
      const AClavePerfil: string;
      const ADefiniciones: TDefinicionesSql;
      const AIncidencias: IRegistroIncidenciasSql = nil
    ): TRevisionesPerfilSql;
    function RevisarCatalogo(
      const ARegistro: IRegistroDefinicionesSql;
      const AIncidencias: IRegistroIncidenciasSql = nil
    ): TRevisionesPerfilSql;
    procedure Exportar(
      const ARuta: string;
      const ADefiniciones: TDefinicionesSql); overload;
    procedure Exportar(
      const ARuta, AClavePerfil: string;
      const ADefiniciones: TDefinicionesSql;
      const AIncidencias: IRegistroIncidenciasSql = nil); overload;
    procedure ExportarCatalogo(
      const ARuta: string;
      const ARegistro: IRegistroDefinicionesSql;
      const AIncidencias: IRegistroIncidenciasSql = nil);
  end;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils,
  inLibCatalogoSqlValidacion;

resourcestring
  SErrorPerfilesSqlNoConfigurados =
    'El servicio de perfiles no está configurado.';
  SErrorRegistroSqlNoConfigurado =
    'El registro de definiciones SQL no está configurado.';

constructor TAdministradorSqlPerfiles.Create(
  const APerfilesLectura: ILectorPerfilesUsuario;
  const APerfilesEscritura: IEscritorPerfilesUsuario);
begin
  Create(
    APerfilesLectura,
    APerfilesEscritura,
    mbMariaDB);
end;

constructor TAdministradorSqlPerfiles.Create(
  const APerfilesLectura: ILectorPerfilesUsuario;
  const APerfilesEscritura: IEscritorPerfilesUsuario;
  AMotor: TMotorBBDD);
begin
  inherited Create;
  FPerfilesLectura := APerfilesLectura;
  FPerfilesEscritura := APerfilesEscritura;
  FMotor := AMotor;
end;

function TAdministradorSqlPerfiles.CargarPerfil(
  const AClavePerfil: string): TProfileDicc;
begin
  Result := nil;
  if not Assigned(FPerfilesLectura) then
    raise Exception.Create(
      SErrorPerfilesSqlNoConfigurados);
  FPerfilesLectura.CargarPerfilFormulario(
    AClavePerfil,
    PERFIL_TODOS,
    PERFIL_TODOS,
    Result);
  if not Assigned(Result) then
    Result := TProfileDicc.Create;
end;

function TAdministradorSqlPerfiles.PerfilActivo(
  const AValor: string): Boolean;
begin
  Result := SameText(
    Copy(Trim(AValor), 1, 1), 'S');
end;

function TAdministradorSqlPerfiles.NombreSeguro(
  const ATexto: string): string;
var
  cCaracter: Char;
  iIndice: Integer;
begin
  Result := '';
  for iIndice := 1 to Length(ATexto) do
  begin
    cCaracter := ATexto[iIndice];
    if CharInSet(
         cCaracter,
         ['A'..'Z', 'a'..'z', '0'..'9', '-', '_']) then
      Result := Result + cCaracter
    else
      Result := Result + '_';
  end;
end;

function TAdministradorSqlPerfiles.NombreEstado(
  AEstado: TEstadoPerfilSql): string;
begin
  case AEstado of
    epsSoloBase:
      Result := 'SOLO_BASE';
    epsFalta:
      Result := 'FALTA';
    epsDesactivado:
      Result := 'DESACTIVADO';
    epsBase:
      Result := 'BASE';
    epsPersonalizado:
      Result := 'PERSONALIZADO';
    epsInvalido:
      Result := 'INVALIDO';
  else
    Result := '';
  end;
end;

procedure TAdministradorSqlPerfiles.PublicarFaltantes(
  const AClavePerfil: string;
  const ADefiniciones: TDefinicionesSql);
var
  iIndice: Integer;
  oPerfil: TProfileDicc;
  oValor: TDictValue;
  sClaveSql: string;
  sVersion: string;
begin
  oPerfil := CargarPerfil(AClavePerfil);
  try
    for iIndice := 0 to High(ADefiniciones) do
    begin
      sClaveSql := ClavePerfilSql(
        ADefiniciones[iIndice]);
      if (ADefiniciones[iIndice].Politica <>
          pesSoloBase) and
         (not oPerfil.ContainsKey(sClaveSql)) then
      begin
        sVersion := Format(
          'S;V=%d;BASE=%s',
          [ADefiniciones[iIndice].Version,
           CalcularHuellaSql(
             ObtenerSqlBaseMotor(
               ADefiniciones[iIndice],
               FMotor))]);
        FPerfilesEscritura.GrabarPerfil(
          PERFIL_TODOS,
          AClavePerfil,
          sClaveSql,
          sVersion,
          ObtenerSqlBaseMotor(
            ADefiniciones[iIndice],
            FMotor));
        oValor.sValue := sVersion;
        oValor.sValueText :=
          ObtenerSqlBaseMotor(
            ADefiniciones[iIndice],
            FMotor);
        oPerfil.AddOrSetValue(
          sClaveSql,
          oValor);
      end;
    end;
  finally
    FreeAndNil(oPerfil);
  end;
end;

procedure TAdministradorSqlPerfiles.PublicarCatalogo(
  const ARegistro: IRegistroDefinicionesSql);
begin
  if not Assigned(ARegistro) then
    raise Exception.Create(
      SErrorRegistroSqlNoConfigurado);
  PublicarFaltantes(
    ClavePerfilCatalogoSql(FMotor),
    ARegistro.ObtenerDefiniciones);
end;

function TAdministradorSqlPerfiles.Revisar(
  const AClavePerfil: string;
  const ADefiniciones: TDefinicionesSql;
  const AIncidencias: IRegistroIncidenciasSql
): TRevisionesPerfilSql;
var
  iIndice: Integer;
  oPerfil: TProfileDicc;
  oValidacion: TResultadoValidacionSql;
  oValor: TDictValue;
  sClaveSql: string;
  sSqlPerfil: string;
begin
  SetLength(Result, Length(ADefiniciones));
  oPerfil := CargarPerfil(AClavePerfil);
  try
    for iIndice := 0 to High(ADefiniciones) do
    begin
      sClaveSql := ClavePerfilSql(
        ADefiniciones[iIndice]);
      Result[iIndice].ClavePerfil := sClaveSql;
      Result[iIndice].Repositorio :=
        ADefiniciones[iIndice].Repositorio;
      Result[iIndice].Operacion :=
        ADefiniciones[iIndice].Operacion;
      Result[iIndice].SqlBase :=
        ObtenerSqlBaseMotor(
          ADefiniciones[iIndice],
          FMotor);
      Result[iIndice].SqlPerfil := '';
      Result[iIndice].ValorPerfil := '';
      Result[iIndice].UltimaCausaFallback := '';
      Result[iIndice].HuellaBase := CalcularHuellaSql(
        ObtenerSqlBaseMotor(
          ADefiniciones[iIndice],
          FMotor));
      Result[iIndice].HuellaPerfil := '';
      Result[iIndice].Mensaje := '';
      Result[iIndice].Politica :=
        ADefiniciones[iIndice].Politica;
      Result[iIndice].Version :=
        ADefiniciones[iIndice].Version;
      Result[iIndice].TienePerfil := False;
      if ADefiniciones[iIndice].Politica =
         pesSoloBase then
        Result[iIndice].Estado := epsSoloBase
      else
        Result[iIndice].Estado := epsFalta;
      if Assigned(AIncidencias) then
        Result[iIndice].UltimaCausaFallback :=
          AIncidencias.ObtenerUltimaCausa(
            sClaveSql);
      if oPerfil.TryGetValue(sClaveSql, oValor) then
      begin
        Result[iIndice].TienePerfil := True;
        Result[iIndice].ValorPerfil :=
          oValor.sValue;
        sSqlPerfil := string(oValor.sValueText);
        Result[iIndice].SqlPerfil := sSqlPerfil;
        Result[iIndice].HuellaPerfil :=
          CalcularHuellaSql(sSqlPerfil);
        if ADefiniciones[iIndice].Politica =
           pesSoloBase then
          Result[iIndice].Estado := epsSoloBase
        else if not PerfilActivo(oValor.sValue) then
          Result[iIndice].Estado := epsDesactivado
        else
        begin
          oValidacion := ValidarSql(
            ADefiniciones[iIndice],
            sSqlPerfil,
            FMotor);
          if not oValidacion.EsValido then
          begin
            Result[iIndice].Estado := epsInvalido;
            Result[iIndice].Mensaje :=
              oValidacion.Mensaje;
          end
          else if Result[iIndice].HuellaBase =
                  Result[iIndice].HuellaPerfil then
            Result[iIndice].Estado := epsBase
          else
            Result[iIndice].Estado :=
              epsPersonalizado;
        end;
      end;
    end;
  finally
    FreeAndNil(oPerfil);
  end;
end;

function TAdministradorSqlPerfiles.RevisarCatalogo(
  const ARegistro: IRegistroDefinicionesSql;
  const AIncidencias: IRegistroIncidenciasSql
): TRevisionesPerfilSql;
begin
  if not Assigned(ARegistro) then
    raise Exception.Create(
      SErrorRegistroSqlNoConfigurado);
  Result := Revisar(
    ClavePerfilCatalogoSql(FMotor),
    ARegistro.ObtenerDefiniciones,
    AIncidencias);
end;

procedure TAdministradorSqlPerfiles.Exportar(
  const ARuta: string;
  const ADefiniciones: TDefinicionesSql);
begin
  Exportar(
    ARuta,
    ClavePerfilCatalogoSql(FMotor),
    ADefiniciones,
    nil);
end;

procedure TAdministradorSqlPerfiles.Exportar(
  const ARuta, AClavePerfil: string;
  const ADefiniciones: TDefinicionesSql;
  const AIncidencias: IRegistroIncidenciasSql);
var
  iIndice: Integer;
  oIndice: TStringList;
  oRevisiones: TRevisionesPerfilSql;
  sDirectorioRepositorio: string;
  sFichero: string;
  sMensaje: string;
begin
  ForceDirectories(ARuta);
  oRevisiones := Revisar(
    AClavePerfil,
    ADefiniciones,
    AIncidencias);
  oIndice := TStringList.Create;
  try
    oIndice.Add(
      'CLAVE | ESTADO | POLITICA | VERSION | ' +
      'HUELLA_BASE | HUELLA_PERFIL | MENSAJE | ULTIMO_FALLBACK');
    for iIndice := 0 to High(ADefiniciones) do
    begin
      sDirectorioRepositorio := TPath.Combine(
        ARuta,
        NombreSeguro(
          ADefiniciones[iIndice].Repositorio));
      ForceDirectories(sDirectorioRepositorio);
      sFichero := TPath.Combine(
        sDirectorioRepositorio,
        NombreSeguro(
          ADefiniciones[iIndice].Operacion) + '.base.sql');
      TFile.WriteAllText(
        sFichero,
        ObtenerSqlBaseMotor(
          ADefiniciones[iIndice],
          FMotor),
        TEncoding.UTF8);
      if oRevisiones[iIndice].TienePerfil then
      begin
        sFichero := TPath.Combine(
          sDirectorioRepositorio,
          NombreSeguro(
            ADefiniciones[iIndice].Operacion) + '.perfil.sql');
        TFile.WriteAllText(
          sFichero,
          oRevisiones[iIndice].SqlPerfil,
          TEncoding.UTF8);
      end;
      sMensaje := StringReplace(
        oRevisiones[iIndice].Mensaje,
        sLineBreak,
        ' ',
        [rfReplaceAll]);
      oIndice.Add(Format(
        '%s | %s | %s | V%d | %s | %s | %s | %s',
        [ClavePerfilSql(ADefiniciones[iIndice]),
         NombreEstado(oRevisiones[iIndice].Estado),
         NombrePoliticaEjecucionSql(
           ADefiniciones[iIndice].Politica),
         ADefiniciones[iIndice].Version,
         CalcularHuellaSql(
           ObtenerSqlBaseMotor(
             ADefiniciones[iIndice],
             FMotor)),
         oRevisiones[iIndice].HuellaPerfil,
         sMensaje,
         oRevisiones[iIndice].UltimaCausaFallback]));
    end;
    oIndice.SaveToFile(
      TPath.Combine(ARuta, 'catalogo_sql.txt'),
      TEncoding.UTF8);
  finally
    FreeAndNil(oIndice);
  end;
end;

procedure TAdministradorSqlPerfiles.ExportarCatalogo(
  const ARuta: string;
  const ARegistro: IRegistroDefinicionesSql;
  const AIncidencias: IRegistroIncidenciasSql);
begin
  if not Assigned(ARegistro) then
    raise Exception.Create(
      SErrorRegistroSqlNoConfigurado);
  Exportar(
    ARuta,
    ClavePerfilCatalogoSql(FMotor),
    ARegistro.ObtenerDefiniciones,
    AIncidencias);
end;

end.
