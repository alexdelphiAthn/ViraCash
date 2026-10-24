{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataVerifactuColaRepositorio                               }
{    Tipo:       Librería                                                      }
{ Versión:       1.2.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptador UniDAC de la cola Verifactu: encolado con envío y emisión en    }
{    modo transitorio sin Verifactu. Las operaciones sin envío (NO             }
{    VERI*FACTU, rectificativas y relaciones) viven en                         }
{    UniDataVerifactuColaOperaciones.                                          }
{******************************************************************************}
unit UniDataVerifactuColaRepositorio;
interface
uses
  Uni, inLibVerifactuColaIntf, inLibLogIntf;
function CrearServicioVerifactuColaUniDAC(
  AQry: TUniQuery;
  const ARegistroLog: IRegistroLog = nil): IServicioVerifactuCola; overload;
function CrearServicioVerifactuColaUniDAC(
  AConexion: TUniConnection;
  const ARegistroLog: IRegistroLog = nil): IServicioVerifactuCola; overload;
// True si la cola tiene SISTEMA_VFCOLA (script 791). Sin ella todas las
// filas son de VERI*FACTU.
function ColaVerifactuTieneSistema(AConexion: TUniConnection): Boolean;
// Sistema (VERIFACTU o SII) con que se encoló el alta de la factura;
// ADefecto si no tiene fila de alta. La anulación y la subsanación van
// por el mismo sistema que el alta aunque el modo haya cambiado después.
// Requiere la columna SISTEMA_VFCOLA.
function SistemaColaAltaFactura(AConexion: TUniConnection;
  const ASerie, ANumero, ADefecto: string): string;
implementation
uses
  inLibFormatoDocumentoLecturasIntf,
  inLibFormatoDocumento, UniDataFormatoDocumentoRepositorio,
  System.SysUtils, inLibParametrosIntf, inLibEmisionFiscalIntf,
  inLibVerifactu, inLibVentasWsCola, inLibMsgVerifactu,
  UniDataVerifactuColaOperaciones, UniDataVentasWsCola;
type
  TServicioVerifactuColaUniDAC = class(
    TInterfacedObject,
    IServicioVerifactuCola, IFormatoDocumentoLecturas)
  private
    FConexion: TUniConnection;
    FQry: TUniQuery;
    FQryPropia: Boolean;
    FRegistroLog: IRegistroLog;
  public
    function LeerFormatoEmpresa(const ACodigoEmpresa: string): string;
    function LeerFormatoFactura(const ASerie, ANumero: string): string;
    constructor Create(AQry: TUniQuery;
      const ARegistroLog: IRegistroLog); overload;
    constructor Create(AConexion: TUniConnection;
      const ARegistroLog: IRegistroLog); overload;
    destructor Destroy; override;
    procedure EncolarFactura(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AUsuario, ASerie, ANumero, ATipoOperacion: string;
      ABorrarMovimientos: Boolean);
    procedure RegistrarFacturaNoVerifactu(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AUsuario, ASerie, ANumero, ATipoOperacion: string;
      ABorrarMovimientos: Boolean);
    procedure MarcarFacturaSinVerifactu(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AUsuario, ASerie, ANumero, ATipoOperacion: string;
      ABorrarMovimientos: Boolean);
    procedure BorrarMovimientosFactura(
      const ASerie, ANumero: string);
    procedure EncolarRectificativa(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AServicioEmision: IServicioEmisionFiscal;
      const AUsuario, ASerieOriginal, ANumeroOriginal,
      ASerieRect, ANumeroRect, ATipoRectificativa: string;
      ABorrarMovimientosOriginales: Boolean);
    procedure VincularRectificativa(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AServicioEmision: IServicioEmisionFiscal;
      const ASolicitud: TSolicitudVinculoRectificativa);
    procedure CompletarRectificativa(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AUsuario, ASerieRect, ANumeroRect: string);
    procedure DesvincularRectificativa(
      const AUsuario, ASerieRect, ANumeroRect: string);
    procedure RegistrarRelacionFactura(
      const AUsuario, ASerie, ANumero, ASerieOrigen,
      ANumeroOrigen, ATipoRelacion: string);
  end;
function CrearServicioVerifactuColaUniDAC(
  AQry: TUniQuery;
  const ARegistroLog: IRegistroLog): IServicioVerifactuCola;
begin
  Result := TServicioVerifactuColaUniDAC.Create(AQry, ARegistroLog);
end;
function CrearServicioVerifactuColaUniDAC(
  AConexion: TUniConnection;
  const ARegistroLog: IRegistroLog): IServicioVerifactuCola;
begin
  Result := TServicioVerifactuColaUniDAC.Create(
    AConexion, ARegistroLog);
end;
function TServicioVerifactuColaUniDAC.LeerFormatoEmpresa(
  const ACodigoEmpresa: string): string;
begin
  Result := CrearFormatoDocumentoLecturas(FConexion)
    .LeerFormatoEmpresa(ACodigoEmpresa);
end;

function TServicioVerifactuColaUniDAC.LeerFormatoFactura(
  const ASerie, ANumero: string): string;
begin
  Result := CrearFormatoDocumentoLecturas(FConexion)
    .LeerFormatoFactura(ASerie, ANumero);
end;

constructor TServicioVerifactuColaUniDAC.Create(AQry: TUniQuery;
  const ARegistroLog: IRegistroLog);
begin
  if not Assigned(AQry) then
    raise EArgumentNilException.Create('AQry');
  if not Assigned(AQry.Connection) then
    raise EArgumentNilException.Create('AQry.Connection');
  inherited Create;
  FQry := AQry;
  FConexion := AQry.Connection;
  FQryPropia := False;
  FRegistroLog := ARegistroLog;
end;
constructor TServicioVerifactuColaUniDAC.Create(
  AConexion: TUniConnection;
  const ARegistroLog: IRegistroLog);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
  FQry := TUniQuery.Create(nil);
  FQry.Connection := FConexion;
  FQryPropia := True;
  FRegistroLog := ARegistroLog;
end;
destructor TServicioVerifactuColaUniDAC.Destroy;
begin
  if FQryPropia then
    FreeAndNil(FQry);
  FConexion := nil;
  FRegistroLog := nil;
  inherited;
end;
function ColaVerifactuTieneSistema(AConexion: TUniConnection): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConexion;
    Qry.SQL.Text :=
      ' SELECT COUNT(*) AS N ' +
      '   FROM INFORMATION_SCHEMA.COLUMNS ' +
      '  WHERE TABLE_SCHEMA = DATABASE() ' +
      '    AND TABLE_NAME = ''fza_verifactu_cola'' ' +
      '    AND COLUMN_NAME = ''SISTEMA_VFCOLA''';
    Qry.Open;
    Result := Qry.FieldByName('N').AsInteger > 0;
  finally
    FreeAndNil(Qry);
  end;
end;

function SistemaColaAltaFactura(AConexion: TUniConnection;
  const ASerie, ANumero, ADefecto: string): string;
var
  Qry: TUniQuery;
begin
  Result := ADefecto;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConexion;
    Qry.SQL.Text :=
      ' SELECT SISTEMA_VFCOLA ' +
      '   FROM fza_verifactu_cola ' +
      '  WHERE SERIE_FAC_VFCOLA = :SERIE ' +
      '    AND NUMERO_FAC_VFCOLA = :NUMERO ' +
      '    AND TIPO_OPERACION_VFCOLA = ''ALTA'' ' +
      '  ORDER BY ID_VFCOLA DESC ' +
      '  LIMIT 1';
    Qry.ParamByName('SERIE').AsString := ASerie;
    Qry.ParamByName('NUMERO').AsString := ANumero;
    Qry.Open;
    if (not Qry.Eof) and (Trim(Qry.Fields[0].AsString) <> '') then
      Result := Qry.Fields[0].AsString;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure TServicioVerifactuColaUniDAC.EncolarFactura(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AUsuario, ASerie, ANumero, ATipoOperacion: string;
  ABorrarMovimientos: Boolean);
var
  bSistema: Boolean;
  sColumna: string;
  sValor: string;
  sActualizar: string;
begin
  // FQry comparte transacción con la factura: ambas se confirman o
  // deshacen juntas.
  ValidarRequisitosFiscalesEmision(AParametrosApp, FConexion,
    ASerie, ANumero);
  // Cada fila recuerda su sistema (VERIFACTU o SII). Sin la columna una
  // fila del SII saldría como VERI*FACTU: en SII no se encola.
  bSistema := ColaVerifactuTieneSistema(FConexion);
  if (not bSistema) and SiiActivo(AParametrosApp) then
    raise Exception.Create(SErrorColaSiiSinSistema);
  sColumna := '';
  sValor := '';
  sActualizar := '';
  if bSistema then
  begin
    sColumna := ', SISTEMA_VFCOLA';
    sValor := ', :SISTEMA';
    sActualizar := ', SISTEMA_VFCOLA = :SISTEMA';
  end;
  // ON DUPLICATE relanza a PENDIENTE con los intentos a cero.
  FQry.SQL.Text :=
    ' INSERT INTO fza_verifactu_cola ' +
    ' (SERIE_FAC_VFCOLA, NUMERO_FAC_VFCOLA, TIPO_OPERACION_VFCOLA, ' +
    '  ESTADO_VFCOLA, CONTADOR_INTENTOS_VFCOLA, INSTANTE_ALTA, ' +
    '  USUARIO_ALTA' + sColumna + ') ' +
    ' VALUES ' +
    ' (:SERIE, :NUMERO, :TIPOOP, ''PENDIENTE'', 0, NOW(), :USUARIO' +
    sValor + ') ' +
    ' ON DUPLICATE KEY UPDATE ' +
    '  ESTADO_VFCOLA = ''PENDIENTE'', ' +
    '  CONTADOR_INTENTOS_VFCOLA = 0, ' +
    '  INSTANTE_PROXIMO_INTENTO_VFCOLA = NULL, ' +
    '  MENSAJE_ERROR_VFCOLA = NULL, ' +
    '  INSTANTE_MODIF = NOW(), ' +
    '  USUARIO_MODIF  = :USUARIO' + sActualizar;
  FQry.ParamByName('SERIE').AsString   := ASerie;
  FQry.ParamByName('NUMERO').AsString  := ANumero;
  FQry.ParamByName('TIPOOP').AsString  := ATipoOperacion;
  FQry.ParamByName('USUARIO').AsString := AUsuario;
  if bSistema then
  begin
    if SameText(ATipoOperacion, 'ALTA') then
      FQry.ParamByName('SISTEMA').AsString :=
        SistemaColaVerifactu(AParametrosApp)
    else
      FQry.ParamByName('SISTEMA').AsString := SistemaColaAltaFactura(
        FConexion, ASerie, ANumero, SistemaColaVerifactu(AParametrosApp));
  end;
  FQry.Execute;
  if ATipoOperacion = 'ANULACION' then
    TOperacionesVerifactuColaUniDAC.BorrarMovimientosFactura(
      FQry, ASerie, ANumero);
  // El lanzamiento saca la factura de BORRADOR; el QR se calcula en
  // local y la petición al ws viaja por el hilo de la cola.
  if SameText(ATipoOperacion, 'ALTA') then
  begin
    FQry.SQL.Text :=
      ' UPDATE fza_facturas ' +
      '    SET FASE_FAC = :FASE, ' +
      '        INSTANTE_MODIF = NOW(), ' +
      '        USUARIO_MODIF  = :USUARIO ' +
      '  WHERE SERIE_FAC  = :SERIE ' +
      '    AND NUMERO_FAC = :NUMERO ' +
      '    AND (FASE_FAC IS NULL OR ' +
      '         FASE_FAC IN ('''', ''BORRADOR'', ''ERROR'', ' +
      '                       ''VERIFACTU_ERROR''))';
    FQry.ParamByName('SERIE').AsString   := ASerie;
    FQry.ParamByName('NUMERO').AsString  := ANumero;
    FQry.ParamByName('FASE').AsString    :=
      cFaseFacturaVerifactuPendiente;
    FQry.ParamByName('USUARIO').AsString := AUsuario;
    FQry.Execute;
  end;
  TVentasWsCola.RegistrarFactura(
    AParametrosCaja,
    CrearRepositorioVentasWsColaUniDAC(FQry.Connection),
    AUsuario, ASerie, ANumero, ATipoOperacion);
end;
procedure TServicioVerifactuColaUniDAC.RegistrarFacturaNoVerifactu(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AUsuario, ASerie, ANumero, ATipoOperacion: string;
  ABorrarMovimientos: Boolean);
begin
  TOperacionesVerifactuColaUniDAC.RegistrarFacturaNoVerifactu(
    AParametrosApp,
    AParametrosCaja,
    FQry,
    AUsuario,
    ASerie,
    ANumero,
    ATipoOperacion,
    ABorrarMovimientos,
    FRegistroLog);
end;
procedure TServicioVerifactuColaUniDAC.MarcarFacturaSinVerifactu(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AUsuario, ASerie, ANumero, ATipoOperacion: string;
  ABorrarMovimientos: Boolean);
var
  sFase: string;
begin
  // Modo transitorio sin Verifactu: emite la factura con fase propia,
  // sin cola AEAT y sin registro NO VERI*FACTU.
  ValidarRequisitosFiscalesEmision(AParametrosApp, FConexion,
    ASerie, ANumero);
  if ATipoOperacion = 'ANULACION' then
    sFase := cFaseFacturaSinVerifactuAnulada
  else
    sFase := cFaseFacturaSinVerifactu;
  FQry.SQL.Text :=
    ' UPDATE fza_facturas ' +
    ' SET ESCONSOLIDADA_FAC = ''S'', ' +
    '     INSTANTECONSO_FAC = NOW(), ' +
    '     FASE_FAC = :FASE, ' +
    '     INSTANTE_MODIF = NOW(), ' +
    '     USUARIO_MODIF  = :USUARIO ' +
    ' WHERE SERIE_FAC  = :SERIE ' +
    '   AND NUMERO_FAC = :NUMERO';
  FQry.ParamByName('FASE').AsString := sFase;
  FQry.ParamByName('USUARIO').AsString := AUsuario;
  FQry.ParamByName('SERIE').AsString := ASerie;
  FQry.ParamByName('NUMERO').AsString := ANumero;
  FQry.Execute;
  if ATipoOperacion = 'ANULACION' then
    TOperacionesVerifactuColaUniDAC.BorrarMovimientosFactura(
      FQry, ASerie, ANumero);
  if Assigned(FRegistroLog) then
    FRegistroLog.RegistrarInformacion(
      'Factura ' + FormatearReferenciaFactura(FConexion, ASerie, ANumero) +
      ' emitida en modo SIN VERIFACTU. Operación: ' + ATipoOperacion);
  TVentasWsCola.RegistrarFactura(
    AParametrosCaja,
    CrearRepositorioVentasWsColaUniDAC(FQry.Connection),
    AUsuario, ASerie, ANumero, ATipoOperacion);
end;
procedure TServicioVerifactuColaUniDAC.BorrarMovimientosFactura(
  const ASerie, ANumero: string);
begin
  TOperacionesVerifactuColaUniDAC.BorrarMovimientosFactura(
    FQry,
    ASerie,
    ANumero);
end;
procedure TServicioVerifactuColaUniDAC.EncolarRectificativa(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AServicioEmision: IServicioEmisionFiscal;
  const AUsuario, ASerieOriginal, ANumeroOriginal,
  ASerieRect, ANumeroRect, ATipoRectificativa: string;
  ABorrarMovimientosOriginales: Boolean);
begin
  TOperacionesVerifactuColaUniDAC.EncolarRectificativa(
    AParametrosApp,
    AParametrosCaja,
    FConexion,
    AServicioEmision,
    AUsuario,
    ASerieOriginal,
    ANumeroOriginal,
    ASerieRect,
    ANumeroRect,
    ATipoRectificativa,
    ABorrarMovimientosOriginales);
end;
procedure TServicioVerifactuColaUniDAC.VincularRectificativa(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AServicioEmision: IServicioEmisionFiscal;
  const ASolicitud: TSolicitudVinculoRectificativa);
begin
  TOperacionesVerifactuColaUniDAC.VincularRectificativa(
    AParametrosApp,
    AParametrosCaja,
    FConexion,
    AServicioEmision,
    ASolicitud);
end;
procedure TServicioVerifactuColaUniDAC.CompletarRectificativa(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AUsuario, ASerieRect, ANumeroRect: string);
begin
  TOperacionesVerifactuColaUniDAC.CompletarRectificativa(
    AParametrosApp,
    AParametrosCaja,
    FConexion,
    AUsuario,
    ASerieRect,
    ANumeroRect);
end;
procedure TServicioVerifactuColaUniDAC.DesvincularRectificativa(
  const AUsuario, ASerieRect, ANumeroRect: string);
begin
  TOperacionesVerifactuColaUniDAC.DesvincularRectificativa(
    FConexion,
    AUsuario,
    ASerieRect,
    ANumeroRect);
end;
procedure TServicioVerifactuColaUniDAC.RegistrarRelacionFactura(
  const AUsuario, ASerie, ANumero, ASerieOrigen,
  ANumeroOrigen, ATipoRelacion: string);
begin
  TOperacionesVerifactuColaUniDAC.RegistrarRelacionFactura(
    FConexion,
    AUsuario,
    ASerie,
    ANumero,
    ASerieOrigen,
    ANumeroOrigen,
    ATipoRelacion);
end;
end.
