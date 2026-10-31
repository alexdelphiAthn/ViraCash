{******************************************************************************}
{                                                                              }
{  Modulo:       inLibLicenciaAplicacion                                       }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       16/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Registro y validacion de la licencia local de ViraCash.                   }
{******************************************************************************}
unit inLibLicenciaAplicacion;

interface

uses
  SysUtils, Classes,
  inLibLicenciaAplicacionPersistenciaIntf;

type
  TEstadoLicenciaAplicacion = (elaValida,
                               elaInvalida,
                               elaNoEncontrada,
                               elaSinNifEmpresa);

  TResultadoLicenciaAplicacion = record
    Comprobada: Boolean;
    BBDD: string;
    Estado: TEstadoLicenciaAplicacion;
    Mensaje: string;
    class function CrearNoComprobada:
      TResultadoLicenciaAplicacion; static;
    class function Crear(
      AComprobada: Boolean;
      const ABBDD: string;
      AEstado: TEstadoLicenciaAplicacion;
      const AMensaje: string): TResultadoLicenciaAplicacion; static;
  end;

  EErrorPersistenciaLicenciaAplicacion = class(Exception)
  private
    FError: TErrorPersistenciaLicencia;
  public
    constructor Create(AError: TErrorPersistenciaLicencia;
      const ADetalle: string);
    property Error: TErrorPersistenciaLicencia read FError;
  end;

const
  LIMITE_FACTURAS_DEMO_DIA     = 10;

function RutaIniLicenciaAplicacion: string;
function RegistrarLicenciaAplicacion(
                                     const ARepositorio:
                                     IRepositorioLicenciaAplicacion;
                                     out ACodigo: string;
                                     out ANumeroNifs: Integer;
                                     out ADetalleNifs: string;
                                     out ARutaIni: string): Boolean;
function ComprobarLicenciaAplicacion(
                                     const ARepositorio:
                                     IRepositorioLicenciaAplicacion;
                                     out AEstado: TEstadoLicenciaAplicacion;
                                     out AMensaje: string;
                                     out ACodigoEsperado: string;
                                     out ACodigoGuardado: string): Boolean;
function HayConmutadorRegistroLicencia: Boolean;
function EstadoLicenciaEsDemo(AEstado: TEstadoLicenciaAplicacion): Boolean;
function ContarFacturasDemoDia(
                               const ARepositorio:
                               IRepositorioLicenciaAplicacion;
                               AFecha: TDateTime): Integer;
procedure ValidarLimiteDemoFacturas(
                                    const ARepositorio:
                                    IRepositorioLicenciaAplicacion;
                                    AEstado: TEstadoLicenciaAplicacion;
                                    AFecha: TDateTime);

implementation

uses
  IniFiles, Math, System.Hash,
  inLibConfiguracionIni, inLibDir, inLibMsgConfiguracion,
  inLibMsgFacturas;

class function TResultadoLicenciaAplicacion.CrearNoComprobada:
  TResultadoLicenciaAplicacion;
begin
  Result := Crear(False, '', elaInvalida, '');
end;

class function TResultadoLicenciaAplicacion.Crear(
  AComprobada: Boolean;
  const ABBDD: string;
  AEstado: TEstadoLicenciaAplicacion;
  const AMensaje: string): TResultadoLicenciaAplicacion;
begin
  Result.Comprobada := AComprobada;
  Result.BBDD := ABBDD;
  Result.Estado := AEstado;
  Result.Mensaje := AMensaje;
end;

constructor EErrorPersistenciaLicenciaAplicacion.Create(
  AError: TErrorPersistenciaLicencia;
  const ADetalle: string);
begin
  inherited Create(ADetalle);
  FError := AError;
end;

const
  CLAVE_MAESTRA_LICENCIA = 'Fzam_Tarabudillo_2026_Private!';
  SECCION_LICENCIA       = 'License';
  CLAVE_CODIGO           = 'Code';
  PREFIJO_CODIGO_LICENCIA = 'VC2-';
  HASH_CONMUTADOR_REG    =
    '2A4DE85043CC2B9684AE3F66B9C72C62CF74973827E069929F2148DC1C3763B4';

function NormalizarConmutador(const AValor: string): string;
begin
  Result := UpperCase(Trim(AValor));
  while (Result <> '') and CharInSet(Result[1], ['/', '-']) do
    Delete(Result, 1, 1);
end;

function HayConmutadorRegistroLicencia: Boolean;
var
  i: Integer;
  sParametro: string;
  sHash: string;
begin
  Result := False;
  i := 1;
  while (i <= ParamCount) and not Result do
  begin
    sParametro := NormalizarConmutador(ParamStr(i));
    if sParametro <> '' then
    begin
      sHash := THashSHA2.GetHashString(sParametro);
      Result := SameText(sHash, HASH_CONMUTADOR_REG);
    end;
    Inc(i);
  end;
end;

function EstadoLicenciaEsDemo(AEstado: TEstadoLicenciaAplicacion): Boolean;
begin
  Result := (AEstado = elaInvalida) or (AEstado = elaNoEncontrada);
end;

function ContarFacturasDemoDia(
                               const ARepositorio:
                               IRepositorioLicenciaAplicacion;
                               AFecha: TDateTime): Integer;
var
  oResultado: TResultadoConteoFacturas;
begin
  if not Assigned(ARepositorio) then
  begin
    raise EErrorPersistenciaLicenciaAplicacion.Create(
      eplConexionNoDisponible,
      'No se ha configurado el repositorio de licencia.');
  end;
  oResultado := ARepositorio.ContarFacturasDia(AFecha);
  if not oResultado.Exito then
  begin
    raise EErrorPersistenciaLicenciaAplicacion.Create(
      oResultado.Error, oResultado.Detalle);
  end;
  Result := oResultado.Total;
end;

procedure ValidarLimiteDemoFacturas(
                                    const ARepositorio:
                                    IRepositorioLicenciaAplicacion;
                                    AEstado: TEstadoLicenciaAplicacion;
                                    AFecha: TDateTime);
var
  iFacturas: Integer;
begin
  if Assigned(ARepositorio) and
     EstadoLicenciaEsDemo(AEstado) then
  begin
    iFacturas := ContarFacturasDemoDia(ARepositorio, AFecha);
    if iFacturas >= LIMITE_FACTURAS_DEMO_DIA then
    begin
      raise Exception.Create(Format(SErrorLimiteDemoFacturas,
        [iFacturas, FormatDateTime('dd/mm/yyyy', AFecha),
         LIMITE_FACTURAS_DEMO_DIA]));
    end;
  end;
end;

function RutaIniLicenciaAplicacion: string;
begin
  Result := RutaIniAplicacion(
    GetUserFolder);
end;

function NormalizarNifLicencia(const ANif: string): string;
begin
  Result := UpperCase(Trim(ANif));
  Result := StringReplace(Result, ' ', '', [rfReplaceAll]);
  Result := StringReplace(Result, '-', '', [rfReplaceAll]);
  Result := StringReplace(Result, '.', '', [rfReplaceAll]);
end;

function GenerarCadenaNifs(ANifs: TStrings): string;
var
  i: Integer;
  ListaOrdenada: TStringList;
begin
  Result := '';
  ListaOrdenada := TStringList.Create;
  try
    ListaOrdenada.Sorted := True;
    ListaOrdenada.Duplicates := dupIgnore;
    for i := 0 to ANifs.Count - 1 do
    begin
      if NormalizarNifLicencia(ANifs[i]) <> '' then
        ListaOrdenada.Add(NormalizarNifLicencia(ANifs[i]));
    end;
    for i := 0 to ListaOrdenada.Count - 1 do
    begin
      if Result <> '' then
        Result := Result + '|';
      Result := Result + ListaOrdenada[i];
    end;
  finally
    FreeAndNil(ListaOrdenada);
  end;
end;

function HashACodigoCorto(const AHash: string; ADigitos: Integer): string;
var
  i: Integer;
  iValor: Int64;
  sHex: string;
begin
  sHex := Copy(AHash, 1, 12);
  iValor := 0;
  for i := 1 to Length(sHex) do
  begin
    iValor := iValor * 16;
    case sHex[i] of
      '0'..'9':
        iValor := iValor + Ord(sHex[i]) - Ord('0');
      'A'..'F':
        iValor := iValor + Ord(sHex[i]) - Ord('A') + 10;
      'a'..'f':
        iValor := iValor + Ord(sHex[i]) - Ord('a') + 10;
    end;
  end;
  iValor := iValor mod Round(Power(10, ADigitos));
  Result := Format('%.' + IntToStr(ADigitos) + 'd', [iValor]);
end;

function GenerarCodigoLicencia(ANifs: TStrings): string;
var
  sHash: string;
  sNifs: string;
begin
  sNifs := GenerarCadenaNifs(ANifs);
  sHash := THashSHA2.GetHashString(
    PREFIJO_CODIGO_LICENCIA + sNifs + CLAVE_MAESTRA_LICENCIA);
  // El prefijo impide aceptar los codigos numericos de la version anterior.
  Result := PREFIJO_CODIGO_LICENCIA + HashACodigoCorto(sHash, 6);
end;

procedure CargarNifsEmpresas(
  const ARepositorio: IRepositorioLicenciaAplicacion;
  ANifs: TStrings);
var
  i: Integer;
  oResultado: TResultadoNifsLicencia;
begin
  ANifs.Clear;
  if not Assigned(ARepositorio) then
  begin
    raise EErrorPersistenciaLicenciaAplicacion.Create(
      eplConexionNoDisponible,
      'No se ha configurado el repositorio de licencia.');
  end;
  oResultado := ARepositorio.CargarNifsEmpresas;
  if not oResultado.Exito then
  begin
    raise EErrorPersistenciaLicenciaAplicacion.Create(
      oResultado.Error, oResultado.Detalle);
  end;
  for i := 0 to Length(oResultado.Nifs) - 1 do
  begin
    if Trim(oResultado.Nifs[i]) <> '' then
      ANifs.Add(Trim(oResultado.Nifs[i]));
  end;
end;

function NifsComoTexto(ANifs: TStrings): string;
var
  i: Integer;
  Lista: TStringList;
begin
  Lista := TStringList.Create;
  try
    for i := 0 to ANifs.Count - 1 do
      Lista.Add(Format('%d. %s', [i + 1, ANifs[i]]));
    Result := Lista.Text;
  finally
    FreeAndNil(Lista);
  end;
end;

function LeerCodigoLicencia: string;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(RutaIniLicenciaAplicacion);
  try
    Result := Trim(Ini.ReadString(SECCION_LICENCIA, CLAVE_CODIGO, ''));
  finally
    FreeAndNil(Ini);
  end;
end;

procedure EscribirCodigoLicencia(const ACodigo: string);
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(RutaIniLicenciaAplicacion);
  try
    Ini.WriteString(SECCION_LICENCIA, CLAVE_CODIGO, ACodigo);
  finally
    FreeAndNil(Ini);
  end;
end;

function RegistrarLicenciaAplicacion(
                                     const ARepositorio:
                                     IRepositorioLicenciaAplicacion;
                                     out ACodigo: string;
                                     out ANumeroNifs: Integer;
                                     out ADetalleNifs: string;
                                     out ARutaIni: string): Boolean;
var
  Nifs: TStringList;
begin
  Result := False;
  ACodigo := '';
  ANumeroNifs := 0;
  ADetalleNifs := '';
  ARutaIni := RutaIniLicenciaAplicacion;
  Nifs := TStringList.Create;
  try
    CargarNifsEmpresas(ARepositorio, Nifs);
    ANumeroNifs := Nifs.Count;
    if ANumeroNifs = 0 then
      ADetalleNifs := SErrorNifEmpresaLicenciaNoConfigurado
    else
    begin
      ACodigo := GenerarCodigoLicencia(Nifs);
      ADetalleNifs := NifsComoTexto(Nifs);
      EscribirCodigoLicencia(ACodigo);
      Result := True;
    end;
  finally
    FreeAndNil(Nifs);
  end;
end;

function ComprobarLicenciaAplicacion(
                                     const ARepositorio:
                                     IRepositorioLicenciaAplicacion;
                                     out AEstado: TEstadoLicenciaAplicacion;
                                     out AMensaje: string;
                                     out ACodigoEsperado: string;
                                     out ACodigoGuardado: string): Boolean;
var
  Nifs: TStringList;
begin
  Result := False;
  AEstado := elaInvalida;
  AMensaje := '';
  ACodigoEsperado := '';
  ACodigoGuardado := '';
  Nifs := TStringList.Create;
  try
    CargarNifsEmpresas(ARepositorio, Nifs);
    if Nifs.Count = 0 then
    begin
      AEstado := elaSinNifEmpresa;
      AMensaje := SInfoLicenciaSinNifEmpresa;
      Result := True;
    end
    else
    begin
      ACodigoGuardado := LeerCodigoLicencia;
      ACodigoEsperado := GenerarCodigoLicencia(Nifs);
      if ACodigoGuardado = '' then
      begin
        AEstado := elaNoEncontrada;
        AMensaje := SErrorLicenciaNoEncontrada;
      end
      else if SameText(ACodigoGuardado, ACodigoEsperado) then
      begin
        AEstado := elaValida;
        AMensaje := SInfoLicenciaValida;
        Result := True;
      end
      else
      begin
        AEstado := elaInvalida;
        AMensaje := SErrorLicenciaNifsNoCoinciden;
      end;
    end;
  finally
    FreeAndNil(Nifs);
  end;
end;

end.
