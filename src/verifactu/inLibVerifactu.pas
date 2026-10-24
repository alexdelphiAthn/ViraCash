{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVerifactu                                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       12/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Núcleo del subsistema Verifactu (AEAT). Construcción de la URL de         }
{    cotejo del QR tributario (Orden HAC/1177/2024), helpers de formato y      }
{    registro de eventos encadenados por hash en fza_verifactu_eventos.        }
{******************************************************************************}
unit inLibVerifactu;

interface

uses
  System.SysUtils, Uni, frxClass, Data.DB, inLibParametrosIntf,
  inLibVerifactuTipos;

const
  cModoVerifactuSin = 'SIN';
  cModoVerifactuVerifactu = 'VERIFACTU';
  cModoVerifactuNoVerifactu = 'NO_VERIFACTU';
  cModoVerifactuSii = 'SII';
  // Sistema de cada fila de fza_verifactu_cola (SISTEMA_VFCOLA, script
  // 791): la fila sale por el sistema con el que se encoló
  cSistemaColaVerifactu = 'VERIFACTU';
  cSistemaColaSii = 'SII';
  cFaseFacturaBorrador = 'BORRADOR';
  cFaseFacturaSinVerifactu = 'SIN_VERIFACTU';
  cFaseFacturaSinVerifactuAnulada = 'SIN_VERIF_ANULADA';
  cFaseFacturaVerifactuPendiente = 'VERIFACTU_PENDIENTE';
  cFaseFacturaVerifactuOk = 'VERIFACTU_OK';
  cFaseFacturaVerifactuError = 'VERIFACTU_ERROR';
  cFaseFacturaVerifactuAnulada = 'VERIFACTU_ANULADA';
  cFaseFacturaNoVerifactuOk = 'NOVERIFACTU_OK';
  cFaseFacturaNoVerifactuAnulada = 'NOVERIFACTU_ANULADA';
  // Original sustituida o abonada por una rectificativa ya emitida.
  cFaseFacturaRectificada = 'RECTIFICADA';
  // Factura emitida abierta a corrección: al registrar la subsanación
  // vuelve a su fase de registro (VERIFACTU_OK / NOVERIFACTU_OK).
  cFaseFacturaSubsanacion = 'SUBSANACION';
  // URLs oficiales del servicio de cotejo del QR tributario. Se pueden
  // sobreescribir con los parámetros app*UrlQRPre / app*UrlQRPro.
  cVerifactuUrlQRPre =
    'https://prewww2.aeat.es/wlpl/TIKE-CONT/ValidarQR';
  cVerifactuUrlQRPro =
    'https://www2.agenciatributaria.gob.es/wlpl/TIKE-CONT/ValidarQR';
  cNoVerifactuUrlQRPre =
    'https://prewww2.aeat.es/wlpl/TIKE-CONT/ValidarQRNoVerifactu';
  cNoVerifactuUrlQRPro =
    'https://www2.agenciatributaria.gob.es/wlpl/TIKE-CONT/' +
    'ValidarQRNoVerifactu';
  // Tipos de evento para TIPO_EVENTO_LOG de fza_verifactu_eventos.
  // Pendiente de unificar con el catálogo de tipos de OdaVeriFactu.
  cEventoVerifactuInfo       = 1;
  cEventoVerifactuEncolado   = 2;
  cEventoVerifactuEnvioOk    = 3;
  cEventoVerifactuEnvioError = 4;
  cEventoNoVerifactuInicio       = 101;
  cEventoNoVerifactuFin          = 102;
  cEventoNoVerifactuCambioConfig = 103;
  cEventoNoVerifactuExportFact   = 108;
  cEventoNoVerifactuExportEventos = 109;
  cEventoNoVerifactuIncidenciaCert = 110;
  cEventoNoVerifactuIncidenciaReloj = 111;

// Modo fiscal activo: SIN, VERIFACTU, NO_VERIFACTU o SII.
// appVerifactuActivo=False fuerza SIN como interruptor maestro.
function ModoVerifactu(
  const AParametrosApp: IParametrosAplicacion): TModoVerifactu;
function ModoVerifactuTexto(
  const AParametrosApp: IParametrosAplicacion): string;
// True si el modo fiscal activo es VERIFACTU
function VerifactuActivo(
  const AParametrosApp: IParametrosAplicacion): Boolean;
// True si el modo fiscal activo es NO_VERIFACTU
function NoVerifactuActivo(
  const AParametrosApp: IParametrosAplicacion): Boolean;
// True si el modo fiscal activo es SIN
function SinVerifactuActivo(
  const AParametrosApp: IParametrosAplicacion): Boolean;
// True si el modo fiscal activo es SII (Suministro Inmediato)
function SiiActivo(
  const AParametrosApp: IParametrosAplicacion): Boolean;
// Sistema con el que se encola una factura en el modo activo
function SistemaColaVerifactu(
  const AParametrosApp: IParametrosAplicacion): string;
// True si ESTADO_FACCON es un registro del SII vigente en la AEAT
// (procesado, aceptado con errores, duplicado o modificado). El SII no
// encadena: estos registros no tienen CHAIN_HASH_FACCON.
function EsEstadoSiiAceptado(const AEstado: string): Boolean;
// True si el modo activo imprime QR tributario (VERI*FACTU y NO
// VERI*FACTU). El SII no lleva QR ni leyenda (FZ-ISSUE-293).
function QrTributarioActivo(
  const AParametrosApp: IParametrosAplicacion): Boolean;
// FZ-ISSUE-311: True si un suceso de ATipoEvento va al registro de eventos
// del SIF (fza_verifactu_eventos, RD 1007/2023). El SII queda fuera del
// reglamento de SIF: en modo SII solo se registra el cambio de
// configuración, que deja constancia de la salida del régimen SIF.
function DebeRegistrarEventoSif(AModo: TModoVerifactu;
  ATipoEvento: Integer): Boolean;
// FZ-ISSUE-311: línea INFO del log de la aplicación con la que la cola deja
// constancia de un resultado del SII en lugar del registro del SIF.
function TextoSucesoColaSii(const ADescripcion, ADatosAdicionales,
  ASerieFac, ANumeroFac: string): string;
// True si se firman registros y eventos con certificado de empresa
function VerifactuFirmaCertificado(
  const AParametrosApp: IParametrosAplicacion): Boolean;
// Impide emitir en modo fiscal si faltan el SIF o el certificado.
procedure ValidarRequisitosFiscalesEmision(
  const AParametrosApp: IParametrosAplicacion;
  AConn: TUniConnection;
  const ASerie, ANumero: string);
// 'PRE' (pruebas) o 'PRO' (producción) según appVerifactuEntorno
function VerifactuEntorno(
  const AParametrosApp: IParametrosAplicacion): string;
// Identificador serie+número que se comunica a la AEAT, con el formato de
// documento de la empresa (FORMATO_DOCUMENTO_EMP), el mismo que se imprime
// en la factura. DEBE coincidir en el QR y en el registro que se envíe.
function ComponerNumSerieFactura(
  const AFormato, ASerie, ANumero: string): string;
// Importe con 2 decimales y punto como separador (formato QR y registro)
function FormatearImporteVerifactu(AImporte: Currency): string;
// NIF normalizado para Verifactu: solo letras y dígitos, en mayúsculas.
// El MISMO valor debe viajar en el QR y en el registro de facturación.
function NormalizarNifVerifactu(const AValor: string): string;
// Nombre y NIF del productor (bloque SistemaInformatico). Lanzan excepción
// si el parámetro no coincide con el hash del productor de ViraCash.
function LeerProductorSoftwareVerifactu(
  const AParametrosApp: IParametrosAplicacion): string;
function LeerNifProductorSoftwareVerifactu(
  const AParametrosApp: IParametrosAplicacion): string;
function EsNifProductorSoftwareVerifactu(const ANif: string): Boolean;
// URL completa de cotejo para el QR tributario del ticket / factura
function ConstruirUrlQR(
                        const AParametrosApp: IParametrosAplicacion;
                        const ANif, AFormato, ASerie, ANumero: string;
                        AFecha: TDateTime;
                        AImporteTotal: Currency): string;
// El QR de una factura emitida depende de su fase y de la URL registrada,
// no del modo fiscal seleccionado para las nuevas facturas.
function ObtenerUrlQRFactura(
  const AParametrosApp: IParametrosAplicacion;
  ADataSet: TDataSet): string;
// PNG del QR tributario (ISO/IEC 18004:2015, corrección M) como bytes.
// Sin canvas ni handles GDI compartidos: usable desde el hilo de envío.
function GenerarQRPngVerifactu(const AUrl: string;
                               AEscala: Integer = 4): TBytes;
// FastReport: rellena el TfrxPictureView llamado 'qrverifactu' con el
// QR tributario de la factura del registro activo de su banda (campos
// NIF_EMPRESA_FAC, SERIE_FAC, NUMERO_FAC, FECHA_FAC,
// TOTAL_BASES_FAC, TOTAL_IMPUESTOS_FAC). Encadenar desde
// TfrxReport.OnBeforePrint.
procedure SustituirQRVerifactuEnReport(
  const AParametrosApp: IParametrosAplicacion;
  Component: TfrxReportComponent);
// FastReport: si el formato cargado no trae un TfrxPictureView llamado
// 'qrverifactu', lo crea (30 mm, arriba a la derecha) dentro de la
// cabecera de página; los objetos sueltos en la página no reciben
// OnBeforePrint y el hueco quedaba sin rellenar. Si el diseñador ya lo
// colocó, se respeta su posición.
procedure AsegurarQRVerifactuEnReport(AReport: TfrxReport);
// FastReport: ajusta el memo de título de los formatos de factura
// ('FACTURA') al tipo del registro activo: FACTURA SIMPLIFICADA /
// FACTURA RECTIFICATIVA / FACTURA. Encadenar desde OnBeforePrint.
// Requiere que el dataset de cabecera lleve TIPO_FAC.
// True mientras la factura siga siendo un borrador sin consolidar: lo
// que se imprima o se exporte todavia no es una factura emitida.
function EsFacturaPendienteConsolidar(ADataSet: TDataSet): Boolean;
procedure SustituirTituloFacturaEnReport(Component: TfrxReportComponent);
// FastReport: vía fiable. En esta versión el OnBeforePrint NO llega a
// los objetos sueltos de las bandas estáticas (cabecera/pie/título de
// página), solo a las bandas y a los objetos de bandas de datos. El QR
// y el título 'FACTURA' viven en la cabecera de página, así que cuando
// se dispara una banda recorremos sus hijos y rellenamos el QR y el
// título con el registro de factura activo. Encadenar desde
// OnBeforePrint además de las dos anteriores.
procedure AplicarVerifactuEnBanda(
  const AParametrosApp: IParametrosAplicacion;
  Component: TfrxReportComponent);
// FastReport: rellena directamente (sin esperar a OnBeforePrint) el QR
// y el título de TODO el informe con el registro de ADataSet. Para una
// sola factura, llamar tras cargar el formato y antes de PrepareReport:
// el QR sale por defecto aunque el hueco quede suelto en la página.
procedure AplicarVerifactuEnReportDirecto(
                                          const AParametrosApp:
                                          IParametrosAplicacion;
                                          AReport: TfrxReport;
                                          ADataSet: TDataSet);
// FastReport (impresión de factura): fuerza, sea cual sea el formato
// cargado (base del .dfm o copia guardada en el diseñador), que el QR
// salga: lo rellena donde lo haya puesto el formato ('qrverifactu' o
// 'qr', en la cabecera en el original) o, si no hay, lo crea arriba a
// la derecha de la banda del título. Ajusta también el título por tipo.
procedure PrepararImpresionFacturaVerifactu(
                                            const AParametrosApp:
                                            IParametrosAplicacion;
                                            AReport: TfrxReport;
                                            ADataSet: TDataSet);
// Registra un evento en fza_verifactu_eventos manteniendo la cadena de
// hashes (HASH_ANTERIOR -> HASH_PROPIO). AConn puede ser la conexión
// global o la propia del hilo de la cola.
procedure RegistrarEventoVerifactu(
                                   const AParametrosApp:
                                   IParametrosAplicacion;
                                   AConn: TUniConnection;
                                   const AUsuario: string;
                                   ATipoEvento: Integer;
                                   const ADescripcion: string;
                                   const ADatosAdicionales: string = '';
                                   const ASerieFac: string = '';
                                   const ANumeroFac: string = '');

implementation

uses
  UniDataFormatoDocumentoRepositorio,
  System.Classes, System.Hash, System.StrUtils,
  Vcl.Imaging.pngimage,
  DelphiZXIngQRCode, frxDBSet,
  inLibGlobalVar, inLibFotos, inLibXades, inLibFormatoDocumento,
  inLibMsgFacturas, inLibMsgVerifactu,
  inLibRelojFiscal, inLibVerifactuInstalacion,
  inLibVerifactuRegistroEventos, UniDataVerifactuColaRepositorio;

type
  TRepositorioRegistroEventosUniDAC = class(
    TInterfacedObject,
    IRepositorioRegistroEventosVerifactu)
  private
    FParametrosApp: IParametrosAplicacion;
    FConexion: TUniConnection;
    procedure InicializarEmpresa(
      out ADatos: TEmpresaRegistroEventoVerifactu);
    procedure ConsultarEmpresa(
      var ADatos: TEmpresaRegistroEventoVerifactu);
    procedure ValidarEmpresa(
      const ADatos: TEmpresaRegistroEventoVerifactu);
    procedure PrepararSqlGuardar(
      AQry: TUniQuery;
      ATieneColumnasFirma: Boolean);
    procedure AsignarParametrosGuardar(
      AQry: TUniQuery;
      const ARegistro: TRegistroEventoVerifactu);
  public
    constructor Create(
      const AParametrosApp: IParametrosAplicacion;
      AConexion: TUniConnection);
    function TieneColumnasFirma: Boolean;
    function CargarEmpresa: TEmpresaRegistroEventoVerifactu;
    function CargarAnterior: TEventoAnteriorVerifactu;
    procedure Guardar(const ARegistro: TRegistroEventoVerifactu);
  end;

  TValidadorRelojRegistroEventos = class(
    TInterfacedObject,
    IValidadorRelojRegistroEventosVerifactu)
  private
    FParametrosApp: IParametrosAplicacion;
  public
    constructor Create(
      const AParametrosApp: IParametrosAplicacion);
    procedure ExigirRelojFiscal;
  end;

  TFirmadorRegistroEventos = class(
    TInterfacedObject,
    IFirmadorRegistroEventosVerifactu)
  public
    function Firmar(
      const AXml, AHuella, ASerieCertificado,
      ATitularCertificado: string): TFirmaRegistroEventoVerifactu;
  end;

function ExtraerEtiquetaXml(const AXml, AEtiqueta: string): string;
var
  iIni: Integer;
  iFin: Integer;
  sApertura: string;
  sCierre: string;
begin
  Result := '';
  sApertura := '<' + AEtiqueta + '>';
  sCierre := '</' + AEtiqueta + '>';
  iIni := Pos(sApertura, AXml);
  if iIni > 0 then
  begin
    iIni := iIni + Length(sApertura);
    iFin := PosEx(sCierre, AXml, iIni);
    if iFin > iIni then
      Result := Copy(AXml, iIni, iFin - iIni);
  end;
end;

constructor TRepositorioRegistroEventosUniDAC.Create(
  const AParametrosApp: IParametrosAplicacion;
  AConexion: TUniConnection);
begin
  inherited Create;
  FParametrosApp := AParametrosApp;
  FConexion := AConexion;
end;

function TRepositorioRegistroEventosUniDAC.TieneColumnasFirma: Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConexion;
    Qry.SQL.Text :=
      ' SELECT COUNT(*) AS N ' +
      ' FROM INFORMATION_SCHEMA.COLUMNS ' +
      ' WHERE TABLE_SCHEMA = DATABASE() ' +
      '   AND TABLE_NAME = ''fza_verifactu_eventos'' ' +
      '   AND COLUMN_NAME IN (''REGISTRO_XML_LOG'', ' +
      '       ''FIRMA_XADES_LOG'', ''SERIE_CERTIFICADO_LOG'', ' +
      '       ''TITULAR_CERTIFICADO_LOG'', ''HUELLA_CERTIFICADO_LOG'')';
    Qry.Open;
    Result := Qry.FieldByName('N').AsInteger = 5;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure TRepositorioRegistroEventosUniDAC.InicializarEmpresa(
  out ADatos: TEmpresaRegistroEventoVerifactu);
begin
  ADatos := Default(TEmpresaRegistroEventoVerifactu);
  ADatos.NifProductor := LeerNifProductorSoftwareVerifactu(FParametrosApp);
  ADatos.NombreProductor := LeerProductorSoftwareVerifactu(FParametrosApp);
  ADatos.EsMultiOt := 'N';
end;

procedure TRepositorioRegistroEventosUniDAC.ConsultarEmpresa(
  var ADatos: TEmpresaRegistroEventoVerifactu);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConexion;
    Qry.SQL.Text :=
      ' SELECT RAZON_SOCIAL_EMP, NIF_EMP, CODIGO_CERTIFICADO_EMP, ' +
      '        TITULAR_CERTIFICADO_EMP, NUMERO_INSTALACION_EMP, ' +
      '        VERSION_INSTALACION_EMP, CODIGO_SIF_INSTALACION_EMP, ' +
      '        (SELECT COUNT(*) FROM fza_empresas ' +
      '          WHERE ESACTIVO_EMP = ''S'') AS NUM_EMP ' +
      ' FROM fza_empresas ' +
      ' ORDER BY IF(ESACTIVO_EMP = ''S'', 0, 1), ORDEN_EMP, ' +
      '          CODIGO_EMP_EMP ' +
      ' LIMIT 1';
    Qry.Open;
    if Qry.IsEmpty then
      raise Exception.Create(SErrorEmpresaEventosVerifactuNoConfigurada);
    ADatos.NombreObligado :=
      Trim(Qry.FieldByName('RAZON_SOCIAL_EMP').AsString);
    ADatos.NifObligado := NormalizarNifVerifactu(
      Qry.FieldByName('NIF_EMP').AsString);
    ADatos.SerialCertificado :=
      Trim(Qry.FieldByName('CODIGO_CERTIFICADO_EMP').AsString);
    ADatos.TitularCertificado :=
      Trim(Qry.FieldByName('TITULAR_CERTIFICADO_EMP').AsString);
    ADatos.IdInstalacion :=
      Trim(Qry.FieldByName('NUMERO_INSTALACION_EMP').AsString);
    ADatos.VersionInstalacion :=
      Trim(Qry.FieldByName('VERSION_INSTALACION_EMP').AsString);
    ADatos.CodigoSifInstalacion :=
      Trim(Qry.FieldByName('CODIGO_SIF_INSTALACION_EMP').AsString);
    if Qry.FieldByName('NUM_EMP').AsInteger > 1 then
      ADatos.EsMultiOt := 'S';
  finally
    FreeAndNil(Qry);
  end;
end;

procedure TRepositorioRegistroEventosUniDAC.ValidarEmpresa(
  const ADatos: TEmpresaRegistroEventoVerifactu);
begin
  if Length(ADatos.NifObligado) <> 9 then
    raise Exception.CreateFmt(SErrorNifEmisorEventoNoVerifactuInvalido,
      [ADatos.NifObligado]);
  ValidarInstalacionSif(ADatos.IdInstalacion,
                        ADatos.VersionInstalacion,
                        ADatos.CodigoSifInstalacion,
                        ADatos.NombreObligado,
                        ADatos.NifObligado);
end;

function TRepositorioRegistroEventosUniDAC.CargarEmpresa:
  TEmpresaRegistroEventoVerifactu;
begin
  InicializarEmpresa(Result);
  ConsultarEmpresa(Result);
  ValidarEmpresa(Result);
end;

function TRepositorioRegistroEventosUniDAC.CargarAnterior:
  TEventoAnteriorVerifactu;
var
  Qry: TUniQuery;
begin
  Result := Default(TEventoAnteriorVerifactu);
  Result.EsPrimero := True;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConexion;
    Qry.SQL.Text :=
      ' SELECT TIPO_EVENTO_LOG, TIMESTAMP_LOG, HASH_PROPIO_LOG ' +
      ' FROM fza_verifactu_eventos ' +
      ' ORDER BY ID_LOG DESC ' +
      ' LIMIT 1';
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      Result.EsPrimero := False;
      Result.TipoEvento :=
        Qry.FieldByName('TIPO_EVENTO_LOG').AsInteger;
      Result.Instante := Qry.FieldByName('TIMESTAMP_LOG').AsDateTime;
      Result.Huella := Qry.FieldByName('HASH_PROPIO_LOG').AsString;
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure TRepositorioRegistroEventosUniDAC.PrepararSqlGuardar(
  AQry: TUniQuery;
  ATieneColumnasFirma: Boolean);
begin
  if ATieneColumnasFirma then
    AQry.SQL.Text :=
      ' INSERT INTO fza_verifactu_eventos ' +
      ' (TIMESTAMP_LOG, TIPO_EVENTO_LOG, USUARIO_LOG, VERSION_LOG, ' +
      '  DESCRIPCION_LOG, DATOS_ADICIONALES_LOG, HASH_ANTERIOR_LOG, ' +
      '  HASH_PROPIO_LOG, FIRMA_DIGITAL_LOG, NUMERO_FAC_LOG, ' +
      '  SERIE_FAC_LOG, REGISTRO_XML_LOG, FIRMA_XADES_LOG, ' +
      '  SERIE_CERTIFICADO_LOG, TITULAR_CERTIFICADO_LOG, ' +
      '  HUELLA_CERTIFICADO_LOG) VALUES ' +
      ' (:INSTANTE, :TIPO, :USUARIO, :VERSION, :DESCRIPCION, ' +
      '  NULLIF(:DATOS, ''''), :HASHANT, :HASHPROPIO, :FIRMA, ' +
      '  NULLIF(:NUMERO, ''''), NULLIF(:SERIE, ''''), :XML, ' +
      '  NULLIF(:FIRMAXADES, ''''), NULLIF(:SERIECERT, ''''), ' +
      '  NULLIF(:TITULARCERT, ''''), NULLIF(:HUELLACERT, ''''))'
  else
    AQry.SQL.Text :=
      ' INSERT INTO fza_verifactu_eventos ' +
      ' (TIMESTAMP_LOG, TIPO_EVENTO_LOG, USUARIO_LOG, VERSION_LOG, ' +
      '  DESCRIPCION_LOG, DATOS_ADICIONALES_LOG, HASH_ANTERIOR_LOG, ' +
      '  HASH_PROPIO_LOG, FIRMA_DIGITAL_LOG, NUMERO_FAC_LOG, ' +
      '  SERIE_FAC_LOG) VALUES ' +
      ' (:INSTANTE, :TIPO, :USUARIO, :VERSION, :DESCRIPCION, ' +
      '  NULLIF(:DATOS, ''''), :HASHANT, :HASHPROPIO, :FIRMA, ' +
      '  NULLIF(:NUMERO, ''''), NULLIF(:SERIE, ''''))';
end;

procedure TRepositorioRegistroEventosUniDAC.AsignarParametrosGuardar(
  AQry: TUniQuery;
  const ARegistro: TRegistroEventoVerifactu);
begin
  AQry.ParamByName('INSTANTE').AsString := ARegistro.Instante;
  AQry.ParamByName('TIPO').AsInteger := ARegistro.TipoEvento;
  AQry.ParamByName('USUARIO').AsString := ARegistro.Usuario;
  AQry.ParamByName('VERSION').AsString := ARegistro.Version;
  AQry.ParamByName('DESCRIPCION').AsString := ARegistro.Descripcion;
  AQry.ParamByName('DATOS').AsString := ARegistro.DatosAdicionales;
  AQry.ParamByName('HASHANT').AsString := ARegistro.HashAnterior;
  AQry.ParamByName('HASHPROPIO').AsString := ARegistro.HashPropio;
  AQry.ParamByName('FIRMA').AsString := ARegistro.FirmaDigital;
  AQry.ParamByName('NUMERO').AsString := ARegistro.NumeroFactura;
  AQry.ParamByName('SERIE').AsString := ARegistro.SerieFactura;
  if ARegistro.TieneColumnasFirma then
  begin
    AQry.ParamByName('XML').AsString := ARegistro.Xml;
    AQry.ParamByName('FIRMAXADES').AsString := ARegistro.FirmaXades;
    AQry.ParamByName('SERIECERT').AsString :=
      ARegistro.SerieCertificado;
    AQry.ParamByName('TITULARCERT').AsString :=
      ARegistro.TitularCertificado;
    AQry.ParamByName('HUELLACERT').AsString :=
      ARegistro.HuellaCertificado;
  end;
end;

procedure TRepositorioRegistroEventosUniDAC.Guardar(
  const ARegistro: TRegistroEventoVerifactu);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConexion;
    PrepararSqlGuardar(Qry, ARegistro.TieneColumnasFirma);
    AsignarParametrosGuardar(Qry, ARegistro);
    Qry.Execute;
  finally
    FreeAndNil(Qry);
  end;
end;

constructor TValidadorRelojRegistroEventos.Create(
  const AParametrosApp: IParametrosAplicacion);
begin
  inherited Create;
  FParametrosApp := AParametrosApp;
end;

procedure TValidadorRelojRegistroEventos.ExigirRelojFiscal;
begin
  inLibRelojFiscal.ExigirRelojFiscal(
    FParametrosApp, 'Evento NO VERI*FACTU');
end;

function TFirmadorRegistroEventos.Firmar(
  const AXml, AHuella, ASerieCertificado,
  ATitularCertificado: string): TFirmaRegistroEventoVerifactu;
var
  oDatosCertificado: TXadesDatosCertificado;
  oOpciones: TXadesOpciones;
begin
  oOpciones := OpcionesXadesNoVerifactu('FZ-EVENTO-' + AHuella);
  oOpciones.NombreNodoInsercionFirma := 'sf:Evento';
  oOpciones.FirmaSilenciosa := False;
  Result.XmlFirmado := FirmarXmlXadesEnveloped(
    AXml, ASerieCertificado, ATitularCertificado, oOpciones,
    oDatosCertificado);
  Result.FirmaXades := ExtraerEtiquetaXml(
    Result.XmlFirmado, 'ds:SignatureValue');
  Result.FirmaDigital := UpperCase(
    THashSHA2.GetHashString(Result.FirmaXades));
  Result.SerieCertificado := oDatosCertificado.NumeroSerie;
  Result.TitularCertificado := oDatosCertificado.Titular;
  Result.HuellaCertificado := oDatosCertificado.HuellaSha1;
end;

// True si el dataset tiene los campos de cabecera de factura que
// necesitan el QR y el título (vi_facturas / vi_facturas_print)
function TieneCamposFactura(ADataSet: TDataSet): Boolean;
begin
  Result := (ADataSet <> nil) and
            (ADataSet.FindField('NIF_EMPRESA_FAC') <> nil) and
            (ADataSet.FindField('SERIE_FAC') <> nil) and
            (ADataSet.FindField('NUMERO_FAC') <> nil) and
            (ADataSet.FindField('FECHA_FAC') <> nil) and
            (ADataSet.FindField('TOTAL_BASES_FAC') <> nil) and
            (ADataSet.FindField('TOTAL_IMPUESTOS_FAC') <> nil);
end;

// Dataset de cabecera de factura para un objeto del report: primero la
// banda padre; si el objeto cuelga de una banda sin datos (cabecera de
// página) o de la propia página, se busca entre los datasets del
// report el que tenga los campos de factura.
function DataSetFacturaDeReport(AObj: TfrxComponent): TDataSet;
var
  oReport: TfrxReport;
  oDs:     TDataSet;
  i:       Integer;
begin
  Result := ObtenerDataSetDeBandaPadre(AObj);
  if not TieneCamposFactura(Result) then
  begin
    Result := nil;
    oReport := AObj.Report;
    if oReport <> nil then
    begin
      for i := 0 to oReport.Datasets.Count - 1 do
      begin
        if (Result = nil) and
           (oReport.Datasets[i].DataSet is TfrxDBDataset) then
        begin
          oDs := TfrxDBDataset(oReport.Datasets[i].DataSet).GetDataSet;
          if TieneCamposFactura(oDs) then
            Result := oDs;
        end;
      end;
    end;
  end;
end;

function ModoVerifactuTexto(
  const AParametrosApp: IParametrosAplicacion): string;
begin
  if not AParametrosApp.GetBool('appVerifactuActivo', False) then
    Result := cModoVerifactuSin
  else
  begin
    Result := UpperCase(Trim(
      AParametrosApp.GetString('appVerifactuModo', '')));
    if Result = '' then
      Result := cModoVerifactuVerifactu
    else if (Result <> cModoVerifactuVerifactu) and
            (Result <> cModoVerifactuNoVerifactu) and
            (Result <> cModoVerifactuSii) then
      Result := cModoVerifactuSin;
  end;
end;

function ModoVerifactu(
  const AParametrosApp: IParametrosAplicacion): TModoVerifactu;
var
  sModo: string;
begin
  sModo := ModoVerifactuTexto(AParametrosApp);
  if sModo = cModoVerifactuVerifactu then
    Result := mvVerifactu
  else if sModo = cModoVerifactuNoVerifactu then
    Result := mvNoVerifactu
  else if sModo = cModoVerifactuSii then
    Result := mvSii
  else
    Result := mvSinVerifactu;
end;

function VerifactuActivo(
  const AParametrosApp: IParametrosAplicacion): Boolean;
begin
  Result := ModoVerifactu(AParametrosApp) = mvVerifactu;
end;

function NoVerifactuActivo(
  const AParametrosApp: IParametrosAplicacion): Boolean;
begin
  Result := ModoVerifactu(AParametrosApp) = mvNoVerifactu;
end;

function SinVerifactuActivo(
  const AParametrosApp: IParametrosAplicacion): Boolean;
begin
  Result := ModoVerifactu(AParametrosApp) = mvSinVerifactu;
end;

function SiiActivo(
  const AParametrosApp: IParametrosAplicacion): Boolean;
begin
  Result := ModoVerifactu(AParametrosApp) = mvSii;
end;

function DebeRegistrarEventoSif(AModo: TModoVerifactu;
  ATipoEvento: Integer): Boolean;
begin
  Result := (AModo in [mvVerifactu, mvNoVerifactu]) or
            (ATipoEvento = cEventoNoVerifactuCambioConfig);
end;

function TextoSucesoColaSii(const ADescripcion, ADatosAdicionales,
  ASerieFac, ANumeroFac: string): string;
begin
  Result := 'Cola SII: ' + ADescripcion;
  if (ASerieFac <> '') or (ANumeroFac <> '') then
    Result := Result + '. Factura ' + ASerieFac + '/' + ANumeroFac;
  if ADatosAdicionales <> '' then
    Result := Result + '. ' + ADatosAdicionales;
end;

function SistemaColaVerifactu(
  const AParametrosApp: IParametrosAplicacion): string;
begin
  if SiiActivo(AParametrosApp) then
    Result := cSistemaColaSii
  else
    Result := cSistemaColaVerifactu;
end;

function EsEstadoSiiAceptado(const AEstado: string): Boolean;
begin
  Result := MatchText(Trim(AEstado), ['SII_PROCESADO', 'SII_ACEPT_ERR',
    'SII_DUPLICADO', 'SII_MODIFICADO']);
end;

function QrTributarioActivo(
  const AParametrosApp: IParametrosAplicacion): Boolean;
begin
  Result := ModoVerifactu(AParametrosApp) in [mvVerifactu, mvNoVerifactu];
end;

function VerifactuFirmaCertificado(
  const AParametrosApp: IParametrosAplicacion): Boolean;
begin
  Result :=
    AParametrosApp.GetBool('appVerifactuFirmaCertificado', False);
end;

procedure ValidarRequisitosFiscalesEmision(
  const AParametrosApp: IParametrosAplicacion;
  AConn: TUniConnection;
  const ASerie, ANumero: string);
var
  Qry: TUniQuery;
  sCodigoEmpresa: string;
  sCodigoSif: string;
  sNombreEmpresa: string;
  sNifEmpresa: string;
  sNumeroInstalacion: string;
  sSerialCertificado: string;
  sTitularCertificado: string;
  sVersionInstalacion: string;
begin
  if not SinVerifactuActivo(AParametrosApp) then
  begin
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := AConn;
      Qry.SQL.Text :=
        ' SELECT f.CODIGO_EMP_FAC, e.RAZON_SOCIAL_EMP, e.NIF_EMP, ' +
        '        e.NUMERO_INSTALACION_EMP, e.VERSION_INSTALACION_EMP, ' +
        '        e.CODIGO_SIF_INSTALACION_EMP, ' +
        '        e.CODIGO_CERTIFICADO_EMP, e.TITULAR_CERTIFICADO_EMP ' +
        ' FROM fza_facturas f ' +
        ' LEFT JOIN fza_empresas e ' +
        '   ON e.CODIGO_EMP_EMP = f.CODIGO_EMP_FAC ' +
        ' WHERE f.SERIE_FAC = :SERIE AND f.NUMERO_FAC = :NUMERO';
      Qry.ParamByName('SERIE').AsString := ASerie;
      Qry.ParamByName('NUMERO').AsString := ANumero;
      Qry.Open;
      if Qry.IsEmpty then
        raise Exception.Create(FormatearMensajeDocumentos(
          CrearFormatoDocumentoLecturas(AConn)
          .LeerFormatoFactura(ASerie, ANumero),
          SErrorFacturaRequisitosFiscalesNoExiste, [ASerie, ANumero]));
      sCodigoEmpresa :=
        Trim(Qry.FieldByName('CODIGO_EMP_FAC').AsString);
      sNombreEmpresa :=
        Trim(Qry.FieldByName('RAZON_SOCIAL_EMP').AsString);
      sNifEmpresa := NormalizarNifVerifactu(
        Qry.FieldByName('NIF_EMP').AsString);
      sNumeroInstalacion :=
        Trim(Qry.FieldByName('NUMERO_INSTALACION_EMP').AsString);
      sVersionInstalacion :=
        Trim(Qry.FieldByName('VERSION_INSTALACION_EMP').AsString);
      sCodigoSif :=
        Trim(Qry.FieldByName('CODIGO_SIF_INSTALACION_EMP').AsString);
      sSerialCertificado :=
        Trim(Qry.FieldByName('CODIGO_CERTIFICADO_EMP').AsString);
      sTitularCertificado :=
        Trim(Qry.FieldByName('TITULAR_CERTIFICADO_EMP').AsString);
    finally
      FreeAndNil(Qry);
    end;
    if sNombreEmpresa = '' then
      sNombreEmpresa := sCodigoEmpresa;
    if Length(sNifEmpresa) <> 9 then
      raise Exception.CreateFmt(SErrorEmpresaSinNifEmisionFiscal,
        [sNombreEmpresa]);
    // El SII no es un SIF: sin productor, instalación ni firma; solo
    // hacen falta el NIF de la empresa y su certificado.
    if not SiiActivo(AParametrosApp) then
    begin
      LeerNifProductorSoftwareVerifactu(AParametrosApp);
      LeerProductorSoftwareVerifactu(AParametrosApp);
      ValidarInstalacionSif(sNumeroInstalacion, sVersionInstalacion,
        sCodigoSif, sNombreEmpresa, sNifEmpresa);
    end;
    try
      ValidarCertificadoXades(sSerialCertificado,
        sTitularCertificado);
    except
      on E: Exception do
        raise Exception.CreateFmt(SErrorCertificadoFiscalEmpresaNoUtilizable,
          [sNombreEmpresa, E.Message]);
    end;
    if NoVerifactuActivo(AParametrosApp) and
       (not VerifactuFirmaCertificado(AParametrosApp)) then
      raise Exception.Create(SErrorFirmaCertificadoNoVerifactuDesactivada);
  end;
end;

function VerifactuEntorno(
  const AParametrosApp: IParametrosAplicacion): string;
begin
  Result := UpperCase(Trim(
    AParametrosApp.GetString('appVerifactuEntorno', 'PRE')));
  if Result <> 'PRO' then
    Result := 'PRE';
end;

function ComponerNumSerieFactura(
  const AFormato, ASerie, ANumero: string): string;
begin
  // El número de la factura es el que figura en ella: serie y número
  // unidos con el separador del formato de la empresa. Ajustar SOLO aquí:
  // el QR y el registro enviado a la AEAT deben llevar el mismo valor.
  Result := FormatearDocumento(AFormato, ASerie, ANumero);
end;

function FormatearImporteVerifactu(AImporte: Currency): string;
var
  oFmt: TFormatSettings;
begin
  oFmt := TFormatSettings.Create;
  oFmt.DecimalSeparator  := '.';
  oFmt.ThousandSeparator := #0;
  Result := FormatFloat('0.00', AImporte, oFmt);
end;

function NormalizarNifVerifactu(const AValor: string): string;
var
  cActual: Char;
begin
  Result := '';
  for cActual in UpperCase(Trim(AValor)) do
  begin
    if ((cActual >= 'A') and (cActual <= 'Z')) or
       ((cActual >= '0') and (cActual <= '9')) then
      Result := Result + cActual;
  end;
end;

function LeerProductorSoftwareVerifactu(
  const AParametrosApp: IParametrosAplicacion): string;
const
  // SHA-256 (UTF-8, hex) del nombre del productor del software
  cHashProductorSoftware =
    'b536ead94548d821636435953328882d910dd2e6403dc4be9e1282ac8228ab79';
begin
  // Las demos se distribuyen con el perfil editable: no se admite que
  // el registro fiscal declare otro productor del software.
  Result := Trim(AParametrosApp.GetString('appVerifactuSifNombreRazon',
    ''));
  if not SameText(THashSHA2.GetHashString(Result),
    cHashProductorSoftware) then
    raise Exception.CreateFmt(SErrorProductorSoftwareVerifactuNoAutorizado,
      [Result]);
end;

function EsNifProductorSoftwareVerifactu(const ANif: string): Boolean;
const
  // SHA-256 (UTF-8, hex) del NIF normalizado del productor del software
  cHashNifProductorSoftware =
    'b4b8669db480b2edc455c84ced286b2e0422c776e85890bfc72db703ba9006ff';
begin
  Result := SameText(
    THashSHA2.GetHashString(NormalizarNifVerifactu(ANif)),
    cHashNifProductorSoftware);
end;

function LeerNifProductorSoftwareVerifactu(
  const AParametrosApp: IParametrosAplicacion): string;
begin
  Result := NormalizarNifVerifactu(
    AParametrosApp.GetString('appVerifactuSifNif', ''));
  if not EsNifProductorSoftwareVerifactu(Result) then
    raise Exception.CreateFmt(
      SErrorNifProductorSoftwareVerifactuNoAutorizado, [Result]);
end;

// Percent-encode de un valor de parámetro de URL (RFC 3986): solo quedan
// sin codificar los caracteres no reservados.
function CodificarParametroURL(const AValor: string): string;
var
  aBytes:   TBytes;
  iOcteto:  Byte;
  oSalida:  TStringBuilder;
begin
  oSalida := TStringBuilder.Create;
  try
    aBytes := TEncoding.UTF8.GetBytes(AValor);
    for iOcteto in aBytes do
    begin
      if ((iOcteto >= Ord('A')) and (iOcteto <= Ord('Z'))) or
         ((iOcteto >= Ord('a')) and (iOcteto <= Ord('z'))) or
         ((iOcteto >= Ord('0')) and (iOcteto <= Ord('9'))) or
         (iOcteto = Ord('-')) or (iOcteto = Ord('.')) or
         (iOcteto = Ord('_')) or (iOcteto = Ord('~')) then
        oSalida.Append(Char(iOcteto))
      else
        oSalida.Append('%' + IntToHex(iOcteto, 2));
    end;
    Result := oSalida.ToString;
  finally
    FreeAndNil(oSalida);
  end;
end;

function ConstruirUrlQRConBase(const ABase, ANif, AFormato, ASerie,
  ANumero: string; AFecha: TDateTime;
  AImporteTotal: Currency): string;
begin
  // Formato fijado por la AEAT (documento técnico del QR tributario):
  // nif, numserie, fecha dd-mm-aaaa e importe total con punto decimal
  Result := ABase +
    '?nif='      + CodificarParametroURL(NormalizarNifVerifactu(ANif)) +
    '&numserie=' + CodificarParametroURL(
                     ComponerNumSerieFactura(AFormato, ASerie, ANumero)) +
    '&fecha='    + CodificarParametroURL(
                     FormatDateTime('dd-mm-yyyy', AFecha)) +
    '&importe='  + CodificarParametroURL(
                     FormatearImporteVerifactu(AImporteTotal));
end;

function ConstruirUrlQR(
                        const AParametrosApp: IParametrosAplicacion;
                        const ANif, AFormato, ASerie, ANumero: string;
                        AFecha: TDateTime;
                        AImporteTotal: Currency): string;
var
  sBase: string;
begin
  if VerifactuEntorno(AParametrosApp) = 'PRO' then
  begin
    if NoVerifactuActivo(AParametrosApp) then
      sBase := AParametrosApp.GetString('appNoVerifactuUrlQRPro',
        cNoVerifactuUrlQRPro)
    else
      sBase := AParametrosApp.GetString('appVerifactuUrlQRPro',
        cVerifactuUrlQRPro);
  end
  else if NoVerifactuActivo(AParametrosApp) then
    sBase := AParametrosApp.GetString('appNoVerifactuUrlQRPre',
      cNoVerifactuUrlQRPre)
  else
    sBase := AParametrosApp.GetString('appVerifactuUrlQRPre',
      cVerifactuUrlQRPre);
  Result := ConstruirUrlQRConBase(sBase, ANif, AFormato, ASerie, ANumero,
    AFecha, AImporteTotal);
end;

// Estado y URL del QR del último registro fiscal de la factura del
// registro activo. False si el dataset no es UniDAC o no hay registro.
function LeerConsolidacionQr(ADataSet: TDataSet;
  out AEstado, AUrl: string): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  AEstado := '';
  AUrl := '';
  if (ADataSet is TCustomUniDataSet) and
     (TCustomUniDataSet(ADataSet).Connection <> nil) then
  begin
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := TCustomUniDataSet(ADataSet).Connection;
      Qry.SQL.Text :=
        ' SELECT ESTADO_FACCON, VERIFACTU_URL_FACCON ' +
        '   FROM fza_facturas_consolidaciones ' +
        '  WHERE SERIE_FAC_FACCON = :SERIE ' +
        '    AND NUMERO_FAC_FACCON = :NUMERO ' +
        '  ORDER BY ID_FACCON DESC ' +
        '  LIMIT 1';
      Qry.ParamByName('SERIE').AsString :=
        ADataSet.FieldByName('SERIE_FAC').AsString;
      Qry.ParamByName('NUMERO').AsString :=
        ADataSet.FieldByName('NUMERO_FAC').AsString;
      Qry.Open;
      Result := not Qry.IsEmpty;
      if Result then
      begin
        AEstado := Trim(Qry.Fields[0].AsString);
        AUrl := Trim(Qry.Fields[1].AsString);
      end;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

// Factura sin registro fiscal todavía: True si su alta está encolada para
// el SII (SISTEMA_VFCOLA). Sin fila de alta, sin la columna (script 791)
// o sin BBDD a mano, ADefecto (el modo activo). FZ-ISSUE-293.
function FacturaPendienteDelSii(ADataSet: TDataSet;
  ADefecto: Boolean): Boolean;
var
  oConexion: TUniConnection;
  sDefecto: string;
begin
  Result := ADefecto;
  if (ADataSet is TCustomUniDataSet) and
     (TCustomUniDataSet(ADataSet).Connection <> nil) then
  begin
    oConexion := TCustomUniDataSet(ADataSet).Connection;
    if ColaVerifactuTieneSistema(oConexion) then
    begin
      if ADefecto then
        sDefecto := cSistemaColaSii
      else
        sDefecto := cSistemaColaVerifactu;
      Result := SameText(SistemaColaAltaFactura(oConexion,
        ADataSet.FieldByName('SERIE_FAC').AsString,
        ADataSet.FieldByName('NUMERO_FAC').AsString, sDefecto),
        cSistemaColaSii);
    end;
  end;
end;

function ObtenerUrlQRFactura(
  const AParametrosApp: IParametrosAplicacion;
  ADataSet: TDataSet): string;
var
  sBase: string;
  sFase: string;
  sFormato: string;
  sEstado: string;
  sUrl: string;
  oCampoUrl: TField;
  oCampoEstado: TField;
  oCampoFormato: TField;
  bFacturaSii: Boolean;
  bModoSii: Boolean;
begin
  Result := '';
  if TieneCamposFactura(ADataSet) and ADataSet.Active and
     (ADataSet.FindField('FASE_FAC') <> nil) then
  begin
    sFase := UpperCase(Trim(ADataSet.FieldByName('FASE_FAC').AsString));
    if (sFase = cFaseFacturaVerifactuPendiente) or
       (sFase = cFaseFacturaVerifactuOk) or
       (sFase = cFaseFacturaVerifactuError) then
    begin
      // El SII reutiliza estas fases pero no lleva QR (FZ-ISSUE-293)
      oCampoEstado := ADataSet.FindField('ESTADO_FACCON');
      bFacturaSii := (oCampoEstado <> nil) and
        StartsText('SII_', Trim(oCampoEstado.AsString));
      oCampoUrl := ADataSet.FindField('VERIFACTU_URL_FACCON');
      if (oCampoUrl <> nil) and not bFacturaSii then
        Result := Trim(oCampoUrl.AsString);
      // Sin URL en el dataset decide la factura, no el modo: su registro
      // (SII_* sin QR; VERI*FACTU con su URL guardada, p. ej. al
      // reimprimirla en modo SII) o, si aún no se ha enviado, el sistema
      // de su alta en la cola. Sin BBDD a mano, el modo activo.
      bModoSii := SiiActivo(AParametrosApp);
      if (Result = '') and not bFacturaSii then
      begin
        if LeerConsolidacionQr(ADataSet, sEstado, sUrl) then
        begin
          bFacturaSii := StartsText('SII_', sEstado);
          if not bFacturaSii then
            Result := sUrl;
        end
        else
          bFacturaSii := FacturaPendienteDelSii(ADataSet, bModoSii);
      end;
      if (Result = '') and not bFacturaSii and
         (Trim(ADataSet.FieldByName('NUMERO_FAC').AsString) <> '') and
         not ADataSet.FieldByName('FECHA_FAC').IsNull then
      begin
        if VerifactuEntorno(AParametrosApp) = 'PRO' then
          sBase := AParametrosApp.GetString('appVerifactuUrlQRPro',
            cVerifactuUrlQRPro)
        else
          sBase := AParametrosApp.GetString('appVerifactuUrlQRPre',
            cVerifactuUrlQRPre);
        sFormato := '';
        oCampoFormato := ADataSet.FindField('FORMATO_DOCUMENTO_EMP');
        if oCampoFormato <> nil then
          sFormato := oCampoFormato.AsString;
        Result := ConstruirUrlQRConBase(sBase,
          ADataSet.FieldByName('NIF_EMPRESA_FAC').AsString,
          sFormato,
          ADataSet.FieldByName('SERIE_FAC').AsString,
          ADataSet.FieldByName('NUMERO_FAC').AsString,
          ADataSet.FieldByName('FECHA_FAC').AsDateTime,
          ADataSet.FieldByName('TOTAL_BASES_FAC').AsCurrency +
          ADataSet.FieldByName('TOTAL_IMPUESTOS_FAC').AsCurrency);
      end;
    end;
  end;
end;

function GenerarQRPngVerifactu(const AUrl: string;
                               AEscala: Integer = 4): TBytes;
var
  oQR:     TDelphiZXIngQRCode;
  oPng:    TPngImage;
  oStream: TMemoryStream;
  iX:      Integer;
  iY:      Integer;
  pLinea:  PByteArray;
begin
  SetLength(Result, 0);
  if (Trim(AUrl) <> '') and (AEscala >= 1) then
  begin
    oQR     := TDelphiZXIngQRCode.Create;
    oPng    := nil;
    oStream := nil;
    try
      oQR.ErrorCorrectionLevel := qreM;
      oQR.Encoding             := qrUTF8NoBOM;
      oQR.QuietZone            := 4;
      oQR.Data                 := AUrl;
      // RGB (24 bits), no escala de grises: el TfrxPictureView de
      // FastReport y la hoja dxSpreadSheet pintan PNG RGB con fiabilidad
      // (las fotos, que sí se ven, son RGB); el gris se mostraba bien
      // solo en el visor VCL (TcxDBImage de la ficha) pero no en el A4.
      oPng := TPngImage.CreateBlank(COLOR_RGB, 8,
                                    oQR.Columns * AEscala,
                                    oQR.Rows * AEscala);
      for iY := 0 to oPng.Height - 1 do
      begin
        pLinea := oPng.Scanline[iY];
        for iX := 0 to oPng.Width - 1 do
        begin
          if oQR.IsBlack[iY div AEscala, iX div AEscala] then
          begin
            pLinea[iX * 3]     := 0;
            pLinea[iX * 3 + 1] := 0;
            pLinea[iX * 3 + 2] := 0;
          end
          else
          begin
            pLinea[iX * 3]     := 255;
            pLinea[iX * 3 + 1] := 255;
            pLinea[iX * 3 + 2] := 255;
          end;
        end;
      end;
      oStream := TMemoryStream.Create;
      oPng.SaveToStream(oStream);
      SetLength(Result, oStream.Size);
      if oStream.Size > 0 then
        Move(oStream.Memory^, Result[0], oStream.Size);
    finally
      FreeAndNil(oStream);
      FreeAndNil(oPng);
      FreeAndNil(oQR);
    end;
  end;
end;

const
  TAG_QR_FACTURA_AJUSTADO = 20260923;

function EsPictureQRFactura(APic: TfrxPictureView): Boolean;
begin
  Result := SameText(APic.Name, 'qrverifactu') or
    SameText(APic.DataField, 'QRCODE_PNG_FACCON') or
    (SameText(APic.Name, 'qr') and
     (APic.Tag = TAG_QR_FACTURA_AJUSTADO));
end;

// Rellena un TfrxPictureView con el QR tributario de la factura del
// dataset dado. Desvincula la imagen para que FastReport no la reponga.
procedure RellenarQRPicture(
  const AParametrosApp: IParametrosAplicacion;
  APic: TfrxPictureView;
  ADataSet: TDataSet);
var
  aPng:    TBytes;
  oPng:    TPngImage;
  oStream: TBytesStream;
  sUrl:    string;
begin
  sUrl := ObtenerUrlQRFactura(AParametrosApp, ADataSet);
  APic.Tag := TAG_QR_FACTURA_AJUSTADO;
  APic.DataField := '';
  APic.DataSet := nil;
  APic.Visible := sUrl <> '';
  if sUrl = '' then
    APic.Picture.Assign(nil)
  else
  begin
    aPng := GenerarQRPngVerifactu(sUrl);
    oPng := TPngImage.Create;
    oStream := TBytesStream.Create(aPng);
    try
      oPng.LoadFromStream(oStream);
      APic.Picture.Assign(oPng);
    finally
      FreeAndNil(oStream);
      FreeAndNil(oPng);
    end;
  end;
end;

// Ajusta el memo de título 'FACTURA' al tipo del dataset (SIMPLIFICADA
// / RECTIFICATIVA / normal). Solo actúa sobre el memo de título.
// True mientras la factura siga siendo un borrador sin consolidar: lo
// que se imprima todavia no es una factura emitida.
function EsFacturaPendienteConsolidar(ADataSet: TDataSet): Boolean;
var
  sFase: string;
begin
  Result := False;
  if (ADataSet <> nil) and ADataSet.Active and
     (ADataSet.FindField('FASE_FAC') <> nil) and
     (ADataSet.FindField('ESCONSOLIDADA_FAC') <> nil) then
  begin
    sFase := UpperCase(Trim(
      ADataSet.FieldByName('FASE_FAC').AsString));
    Result := ((sFase = '') or (sFase = 'BORRADOR')) and
      not SameText(
        Trim(ADataSet.FieldByName('ESCONSOLIDADA_FAC').AsString),
        'S');
  end;
end;

// AComoProforma titula el documento como proforma. Un borrador que aun no
// esta registrado no puede salir del programa llamandose factura: quien lo
// recibiera lo tomaria por un documento entregable.
// Marca en Tag de los memos de titulo que ha reescrito este codigo. Un
// 'FACTURA PROFORMA' sin la marca viene del diseno del formato (el usuario
// ha hecho un formato de proforma) y se respeta; con la marca lo puso esta
// rutina para un borrador y puede volver a 'FACTURA' en el siguiente registro.
const
  TAG_TITULO_FACTURA_AJUSTADO = 20260921;

procedure AjustarTituloMemo(AMemo: TfrxMemoView; ADataSet: TDataSet;
  AComoProforma: Boolean);
var
  sTexto: string;
  sTipo:  string;
begin
  sTexto := UpperCase(Trim(AMemo.Text));
  if ((sTexto = 'FACTURA') or
      (sTexto = 'FACTURA SIMPLIFICADA') or
      (sTexto = 'FACTURA RECTIFICATIVA') or
      ((sTexto = 'FACTURA PROFORMA') and
       (AMemo.Tag = TAG_TITULO_FACTURA_AJUSTADO))) and
     (ADataSet <> nil) and
     (ADataSet.FindField('TIPO_FAC') <> nil) then
  begin
    sTipo := UpperCase(Trim(ADataSet.FieldByName('TIPO_FAC').AsString));
    if AComoProforma then
      AMemo.Text := 'FACTURA PROFORMA'
    else if sTipo = 'SIMPLIFICADA' then
      AMemo.Text := 'FACTURA SIMPLIFICADA'
    else if sTipo = 'RECTIFICATIVA' then
      AMemo.Text := 'FACTURA RECTIFICATIVA'
    else
      AMemo.Text := 'FACTURA';
    AMemo.Tag := TAG_TITULO_FACTURA_AJUSTADO;
  end;
end;

procedure SustituirQRVerifactuEnReport(
  const AParametrosApp: IParametrosAplicacion;
  Component: TfrxReportComponent);
begin
  if (Component is TfrxPictureView) and
     EsPictureQRFactura(TfrxPictureView(Component)) then
    RellenarQRPicture(AParametrosApp, TfrxPictureView(Component),
                      DataSetFacturaDeReport(Component));
end;

// Memo de título 'FACTURA' en cualquier nivel del árbol (recursivo)
function BuscarMemoTitulo(AComp: TfrxComponent): TfrxMemoView;
var
  i: Integer;
  s: string;
begin
  Result := nil;
  if AComp <> nil then
  begin
    if AComp is TfrxMemoView then
    begin
      s := UpperCase(Trim(TfrxMemoView(AComp).Text));
      if (s = 'FACTURA') or
         (s = 'FACTURA SIMPLIFICADA') or
         (s = 'FACTURA RECTIFICATIVA') then
        Result := TfrxMemoView(AComp);
    end;
    if Result = nil then
    begin
      for i := 0 to AComp.Objects.Count - 1 do
      begin
        if Result = nil then
          Result := BuscarMemoTitulo(TfrxComponent(AComp.Objects[i]));
      end;
    end;
  end;
end;

// Primera banda de un tipo concreto entre los hijos directos de la página
function PrimeraBanda(APage: TfrxReportPage; AClase: TClass): TfrxBand;
var
  j: Integer;
begin
  Result := nil;
  for j := 0 to APage.Objects.Count - 1 do
  begin
    if (Result = nil) and (TObject(APage.Objects[j]).InheritsFrom(AClase)) then
      Result := TfrxBand(APage.Objects[j]);
  end;
end;

procedure AsegurarQRVerifactuEnReport(AReport: TfrxReport);
var
  i:      Integer;
  oPage:  TfrxReportPage;
  oBanda: TfrxBand;
  oMemo:  TfrxMemoView;
  oParent: TfrxComponent;
  oPic:   TfrxPictureView;
  dLado:  Extended;
  dBase:  Extended;
begin
  if (AReport <> nil) and (AReport.FindObject('qrverifactu') = nil) then
  begin
    oPage := nil;
    for i := 0 to AReport.PagesCount - 1 do
    begin
      if (oPage = nil) and (AReport.Pages[i] is TfrxReportPage) then
        oPage := TfrxReportPage(AReport.Pages[i]);
    end;
    if oPage <> nil then
    begin
      // El QR debe alojarse DENTRO de una banda imprimible. La más
      // segura es la del memo de título 'FACTURA' (existe y se imprime);
      // si no, cabecera de página / título de informe / banda de datos.
      oBanda := nil;
      oMemo  := BuscarMemoTitulo(oPage);
      if oMemo <> nil then
      begin
        oParent := oMemo.Parent;
        while (oParent <> nil) and (not (oParent is TfrxBand)) do
          oParent := oParent.Parent;
        if oParent is TfrxBand then
          oBanda := TfrxBand(oParent);
      end;
      if oBanda = nil then
        oBanda := PrimeraBanda(oPage, TfrxPageHeader);
      if oBanda = nil then
        oBanda := PrimeraBanda(oPage, TfrxReportTitle);
      if oBanda = nil then
        oBanda := PrimeraBanda(oPage, TfrxDataBand);
      // 30 mm (mínimo AEAT 30x30). fr01cm = 1 mm en unidades del informe.
      dLado := 30 * fr01cm;
      if oBanda <> nil then
      begin
        oPic := TfrxPictureView.Create(oBanda);
        // CLAVE: sin Parent, FastReport NO dibuja el objeto aunque
        // exista (el memo de título sí se dibuja porque ya lo trae)
        oPic.Parent := oBanda;
        dBase := oBanda.Width;
        if dBase <= 0 then
          dBase := oPage.Width;
        if oBanda.Height < dLado then
          oBanda.Height := dLado;
      end
      else
      begin
        oPic := TfrxPictureView.Create(oPage);
        oPic.Parent := oPage;
        dBase := oPage.Width;
      end;
      oPic.Name    := 'qrverifactu';
      oPic.SetBounds(dBase - dLado, 0, dLado, dLado);
      oPic.Center  := True;
      oPic.KeepAspectRatio := True;
    end;
  end;
end;

procedure SustituirTituloFacturaEnReport(Component: TfrxReportComponent);
begin
  if Component is TfrxMemoView then
    AjustarTituloMemo(TfrxMemoView(Component),
                      DataSetFacturaDeReport(Component),
                      False);
end;

// Recorre recursivamente los hijos de una banda aplicando el QR y el
// título a los que correspondan, con el registro de factura activo
procedure AplicarVerifactuARama(
  const AParametrosApp: IParametrosAplicacion;
  AComp: TfrxComponent;
  ADataSet: TDataSet;
  AComoProforma: Boolean);
var
  i:    Integer;
  oPic: TfrxPictureView;
begin
  if AComp <> nil then
  begin
    if AComp is TfrxPictureView then
    begin
      oPic := TfrxPictureView(AComp);
      if EsPictureQRFactura(oPic) then
        RellenarQRPicture(AParametrosApp, oPic, ADataSet);
    end;
    if AComp is TfrxMemoView then
      AjustarTituloMemo(
        TfrxMemoView(AComp), ADataSet, AComoProforma);
    for i := 0 to AComp.Objects.Count - 1 do
      AplicarVerifactuARama(
        AParametrosApp,
        TfrxComponent(AComp.Objects[i]),
        ADataSet,
        AComoProforma);
  end;
end;

procedure AplicarVerifactuEnBanda(
  const AParametrosApp: IParametrosAplicacion;
  Component: TfrxReportComponent);
var
  oDataSet: TDataSet;
begin
  if Component is TfrxBand then
  begin
    oDataSet := DataSetFacturaDeReport(Component);
    if TieneCamposFactura(oDataSet) then
      AplicarVerifactuARama(
        AParametrosApp,
        Component,
        oDataSet,
        not SinVerifactuActivo(AParametrosApp) and
          EsFacturaPendienteConsolidar(oDataSet));
  end;
end;

procedure AplicarVerifactuEnReportDirecto(
                                          const AParametrosApp:
                                          IParametrosAplicacion;
                                          AReport: TfrxReport;
                                          ADataSet: TDataSet);
var
  i:    Integer;
  oObj: TfrxComponent;
  bProforma: Boolean;
begin
  // Relleno directo, sin esperar a OnBeforePrint. Para una sola factura
  // (vista previa / impresión / PDF) el QR y el título salen por defecto.
  if (AReport <> nil) and TieneCamposFactura(ADataSet) then
  begin
    bProforma := not SinVerifactuActivo(AParametrosApp) and
      EsFacturaPendienteConsolidar(ADataSet);
    // El QR por nombre (FindObject recorre todo el informe; más fiable
    // que la jerarquía Objects para un objeto recién cargado)
    oObj := AReport.FindObject('qrverifactu');
    if oObj is TfrxPictureView then
      RellenarQRPicture(
        AParametrosApp,
        TfrxPictureView(oObj),
        ADataSet);
    // El título recorriendo los memos de cada página
    for i := 0 to AReport.PagesCount - 1 do
    begin
      if AReport.Pages[i] is TfrxReportPage then
        AplicarVerifactuARama(
          AParametrosApp,
          TfrxReportPage(AReport.Pages[i]),
          ADataSet,
          bProforma);
    end;
  end;
end;

function BuscarPictureQRFactura(AComp: TfrxComponent): TfrxPictureView;
var
  i: Integer;
begin
  Result := nil;
  if AComp is TfrxPictureView then
  begin
    if EsPictureQRFactura(TfrxPictureView(AComp)) then
      Result := TfrxPictureView(AComp);
  end;
  if (Result = nil) and (AComp <> nil) then
  begin
    for i := 0 to AComp.Objects.Count - 1 do
    begin
      if Result = nil then
        Result := BuscarPictureQRFactura(
          TfrxComponent(AComp.Objects[i]));
    end;
  end;
end;

procedure PrepararImpresionFacturaVerifactu(
                                            const AParametrosApp:
                                            IParametrosAplicacion;
                                            AReport: TfrxReport;
                                            ADataSet: TDataSet);
var
  oPage:  TfrxReportPage;
  oBanda: TfrxBand;
  oComp:  TfrxComponent;
  oQr:    TfrxPictureView;
  i:      Integer;
  dLado:  Extended;
  bProforma: Boolean;
  sUrl: string;
begin
  if (AReport <> nil) and TieneCamposFactura(ADataSet) then
  begin
    bProforma := not SinVerifactuActivo(AParametrosApp) and
      EsFacturaPendienteConsolidar(ADataSet);
    sUrl := ObtenerUrlQRFactura(AParametrosApp, ADataSet);
    oPage := nil;
    for i := 0 to AReport.PagesCount - 1 do
    begin
      if (oPage = nil) and (AReport.Pages[i] is TfrxReportPage) then
        oPage := TfrxReportPage(AReport.Pages[i]);
    end;
    if (oPage <> nil) and (sUrl <> '') then
    begin
      // El QR va donde lo puso el formato (el original lo trae como
      // 'qr' en la cabecera, arriba a la derecha). El OnBeforePrint lo
      // vuelve a rellenar con el dataset 'Facturas' vía GetDataSet.
      oComp := AReport.FindObject('qrverifactu');
      if not (oComp is TfrxPictureView) then
        oComp := AReport.FindObject('qr');
      if oComp is TfrxPictureView then
        oQr := TfrxPictureView(oComp)
      else
        oQr := BuscarPictureQRFactura(oPage);
      if oQr = nil then
      begin
        // Formato sin QR: se crea arriba a la derecha de la banda del
        // título 'FACTURA' (o de la cabecera, o la de datos)
        oBanda := nil;
        oComp := BuscarMemoTitulo(oPage);
        if oComp <> nil then
          oComp := oComp.Parent;
        while (oComp <> nil) and not (oComp is TfrxBand) do
          oComp := oComp.Parent;
        if oComp is TfrxBand then
          oBanda := TfrxBand(oComp);
        if oBanda = nil then
          oBanda := PrimeraBanda(oPage, TfrxPageHeader);
        if oBanda = nil then
          oBanda := PrimeraBanda(oPage, TfrxReportTitle);
        if oBanda = nil then
          oBanda := PrimeraBanda(oPage, TfrxMasterData);
        if oBanda <> nil then
        begin
          dLado := 30 * fr01cm;
          if oBanda.Height < dLado then
            oBanda.Height := dLado;
          oQr := TfrxPictureView.Create(oBanda);
          oQr.Name := 'qrverifactu';
          oQr.Parent := oBanda;
          oQr.SetBounds(oBanda.Width - dLado, 0, dLado, dLado);
          oQr.KeepAspectRatio := True;
        end;
      end;
      if oQr <> nil then
      begin
        oQr.Stretched := True;
        RellenarQRPicture(AParametrosApp, oQr, ADataSet);
      end;
    end;
    // Título por tipo (recorre los memos de todas las páginas)
    for i := 0 to AReport.PagesCount - 1 do
    begin
      if AReport.Pages[i] is TfrxReportPage then
        AplicarVerifactuARama(
          AParametrosApp,
          TfrxReportPage(AReport.Pages[i]),
          ADataSet,
          bProforma);
    end;
  end;
end;

procedure RegistrarEventoVerifactu(
                                   const AParametrosApp:
                                   IParametrosAplicacion;
                                   AConn: TUniConnection;
                                   const AUsuario: string;
                                   ATipoEvento: Integer;
                                   const ADescripcion: string;
                                   const ADatosAdicionales: string;
                                   const ASerieFac: string;
                                   const ANumeroFac: string);
var
  oFirmador: IFirmadorRegistroEventosVerifactu;
  oRegistro: IRegistroEventosVerifactu;
  oRepositorio: IRepositorioRegistroEventosVerifactu;
  oValidadorReloj: IValidadorRelojRegistroEventosVerifactu;
  oSolicitud: TSolicitudRegistroEventoVerifactu;
begin
  // En SII y SIN no hay registro de eventos del SIF (ni productor
  // del software que firmar); el llamante deja constancia en su log.
  if not DebeRegistrarEventoSif(ModoVerifactu(AParametrosApp),
                                ATipoEvento) then
    Exit;
  oSolicitud.EsNoVerifactu := NoVerifactuActivo(AParametrosApp);
  oSolicitud.FirmarCertificado :=
    VerifactuFirmaCertificado(AParametrosApp);
  oSolicitud.InstanteRegistro := Now;
  oSolicitud.InstanteEvento := Now;
  oSolicitud.Version := oVersion;
  oSolicitud.Usuario := AUsuario;
  oSolicitud.TipoEvento := ATipoEvento;
  oSolicitud.Descripcion := ADescripcion;
  oSolicitud.DatosAdicionales := ADatosAdicionales;
  oSolicitud.SerieFactura := ASerieFac;
  oSolicitud.NumeroFactura := ANumeroFac;
  oRepositorio := TRepositorioRegistroEventosUniDAC.Create(
    AParametrosApp, AConn);
  oValidadorReloj := TValidadorRelojRegistroEventos.Create(
    AParametrosApp);
  oFirmador := TFirmadorRegistroEventos.Create;
  oRegistro := CrearRegistroEventosVerifactu(
    oRepositorio, oValidadorReloj, oFirmador);
  oRegistro.Registrar(oSolicitud);
end;

end.
