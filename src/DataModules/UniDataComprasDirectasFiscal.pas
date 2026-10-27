{******************************************************************************}
{  Módulo:       UniDataComprasDirectasFiscal                                  }
{    Tipo:       Persistencia                                                  }
{   Fecha:       26/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{******************************************************************************}
unit UniDataComprasDirectasFiscal;

interface

uses
  Uni, inLibParametrosIntf;

type
  TTransporteFiscalCompraDirecta = reference to procedure(
    const AUrl, APeticion, ACertificado, ATitular: string;
    out AEstadoHttp: Integer; out ARespuesta: string);

function ProcesarFiscalCompraDirecta(AConexion: TUniConnection;
  const AParametros: IParametrosAplicacion;
  const ASerie, ANumero, AUsuario, AEmpresaLocal: string;
  const ATransporte: TTransporteFiscalCompraDirecta = nil): string;
procedure ExigirCompraSinRegistroFiscal(AConexion: TUniConnection;
  const ASerie, ANumero: string);

implementation

uses
  System.SysUtils, System.Hash, Data.DB,
  inLibComprasDirectas, inLibComprasDirectasFiscal,
  inLibVerifactu, inLibVerifactuTipos, inLibVerifactuEnvio,
  inLibVerifactuConstruccionEnvio, inLibSiiConstruccionEnvio,
  inLibVerifactuDesgloseFiscal, inLibVerifactuInstalacion;

const
  TRAMOS: array[0..3] of string = ('N', 'R', 'S', 'E');

resourcestring
  SCompraFiscalBloqueada =
    'El documento ya tiene un registro fiscal. No se puede modificar ' +
    'ni borrar; corresponde una rectificación.';
  SCompraFiscalCerrar = 'Cierre la compra antes de generar su registro fiscal.';
  SCompraFiscalDatos = 'Faltan datos fiscales del proveedor o de la empresa.';
  SCompraFiscalCuota =
    'Indique la fecha de registro contable y la cuota deducible del SII.';
  SCompraFiscalCuotaInvalida = 'La cuota deducible supera la cuota soportada.';
  SCompraFiscalCompensacionPendiente =
    'La compensación agrícola solo es deducible cuando se haya pagado. ' +
    'Indique cuota deducible cero si el pago está pendiente.';
  SCompraFiscalRepresentacion =
    'Confirme la autorización para remitir registros por el proveedor.';
  SCompraFiscalNoLocal = 'La compra no pertenece a la empresa local.';
  SCompraFiscalTransaccion = 'Finalice la operación anterior antes de emitir.';
  SCompraFiscalInexistente = 'No se encuentra la compra directa.';
  SCompraFiscalExcluida = 'Documento fuera de VeriFactu en el modo actual.';
  SCompraFiscalEnCurso =
    'Hay un envío en curso o de resultado incierto. Consulte su estado ' +
    'antes de volver a remitirlo.';

type
  TEmisionCompraDirecta = class
  private
    FConexion: TUniConnection;
    FParametros: IParametrosAplicacion;
    FTransporte: TTransporteFiscalCompraDirecta;
    FSerie, FNumero, FUsuario, FEmpresa: string;
    FConsulta: TUniQuery;
    FPeticion, FRespuesta, FSistema, FEntorno, FUrl: string;
    FCertificado, FTitularCertificado: string;
    FHuella, FQr, FFechaHora, FDocumento: string;
    FEstado, FError, FCsv: string;
    function EjecutarBloqueado: string;
    function CrearConsulta: TUniQuery;
    function LeerTexto(const ACampo: string): string;
    function LeerImporte(const ACampo: string): Currency;
    procedure Cargar;
    procedure ValidarDatos;
    procedure Preparar;
    procedure PrepararSii;
    procedure ValidarDeduccionAgricola(
      const AEntrada: TRegistroCompraDirectaSii);
    function DescripcionOperacion: string;
    procedure PrepararVerifactu;
    procedure Encadenar(var AEntrada: TEntradaConstruccionRegistroAlta);
    procedure GuardarCadena;
    function DocumentoAnterior(const ASerie, ANumero, AHuella: string;
      const AFormatoDefecto: string): string;
    procedure GuardarPreparado;
    procedure GuardarRespuesta;
    procedure Enviar;
    procedure Interpretar(AEstadoHttp: Integer);
    function SistemaInformatico: string;
    function UrlServicio: string;
  public
    constructor Create(AConexion: TUniConnection;
      const AParametros: IParametrosAplicacion;
      const ASerie, ANumero, AUsuario, AEmpresaLocal: string;
      const ATransporte: TTransporteFiscalCompraDirecta);
    destructor Destroy; override;
    function Ejecutar: string;
  end;

function Xml(const ATexto: string): string;
begin
  Result := StringReplace(ATexto, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
end;

constructor TEmisionCompraDirecta.Create(AConexion: TUniConnection;
  const AParametros: IParametrosAplicacion;
  const ASerie, ANumero, AUsuario, AEmpresaLocal: string;
  const ATransporte: TTransporteFiscalCompraDirecta);
begin
  inherited Create;
  FConexion := AConexion;
  FParametros := AParametros;
  FTransporte := ATransporte;
  FSerie := ASerie;
  FNumero := ANumero;
  FUsuario := AUsuario;
  FEmpresa := AEmpresaLocal;
  FConsulta := CrearConsulta;
end;

destructor TEmisionCompraDirecta.Destroy;
begin
  FreeAndNil(FConsulta);
  inherited;
end;

function TEmisionCompraDirecta.CrearConsulta: TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

function TEmisionCompraDirecta.LeerTexto(const ACampo: string): string;
begin
  Result := Trim(FConsulta.FieldByName(ACampo).AsString);
end;

function TEmisionCompraDirecta.LeerImporte(const ACampo: string): Currency;
begin
  Result := FConsulta.FieldByName(ACampo).AsCurrency;
end;

procedure TEmisionCompraDirecta.Cargar;
var
  sTramo: string;
begin
  FConsulta.SQL.Text :=
    'SELECT F.MODALIDAD_FACC, F.CODIGO_EMP_FACC, F.ESTADO_FACC, ' +
    'F.NIF_PRV_FACC, F.RAZON_SOCIAL_PRV_FACC, F.NIF_EMPRESA_FACC, ' +
    'F.RAZON_SOCIAL_EMPRESA_FACC, F.FECHA_FACC, F.TOTAL_FACC, ' +
    'F.TOTAL_BASES_FACC, F.TOTAL_IMPUESTOS_FACC, F.TOTAL_LIQUIDO_FACC, ' +
    'F.PORCENTAJE_COMPENSACION_FACC, F.TOTAL_COMPENSACION_FACC, ' +
    'F.ESREPRESENTACION_FISCAL_FACC, F.ESTADO_FISCAL_FACC, ' +
    'F.SISTEMA_FISCAL_FACC, F.XML_PETICION_FISCAL_FACC, ' +
    'F.XML_RESPUESTA_FISCAL_FACC, F.ENTORNO_FISCAL_FACC, ' +
    'F.URL_QR_FISCAL_FACC, F.ERROR_FISCAL_FACC, F.CSV_FISCAL_FACC, ' +
    'F.DOCUMENTO_FISCAL_FACC, ' +
    'F.FECHA_REGISTRO_CONTABLE_FACC, F.CUOTA_DEDUCIBLE_FACC, ' +
    'E.CODIGO_CERTIFICADO_EMP, E.TITULAR_CERTIFICADO_EMP, ' +
    'E.NUMERO_INSTALACION_EMP, E.VERSION_INSTALACION_EMP, ' +
    'E.CODIGO_SIF_INSTALACION_EMP, E.FORMATO_DOCUMENTO_EMP';
  for sTramo in TRAMOS do
    FConsulta.SQL.Add(', F.PORCENTAJE_IVA' + sTramo + '_FACC, ' +
      'F.TOTAL_BASEI_IVA' + sTramo + '_FACC, ' +
      'F.TOTAL_IVA' + sTramo + '_FACC, ' +
      'F.PORCENTAJE_RE' + sTramo + '_FACC, F.TOTAL_RE' + sTramo + '_FACC');
  FConsulta.SQL.Add('FROM fza_facturas_compra F JOIN fza_empresas E ' +
    'ON E.CODIGO_EMP_EMP = F.CODIGO_EMP_FACC ' +
    'WHERE F.SERIE_FACC = :SERIE AND F.NUMERO_FACC = :NUMERO FOR UPDATE');
  FConsulta.ParamByName('SERIE').AsString := FSerie;
  FConsulta.ParamByName('NUMERO').AsString := FNumero;
  FConsulta.Open;
  if FConsulta.IsEmpty then
    raise Exception.Create(SCompraFiscalInexistente);
  if LeerTexto('CODIGO_EMP_FACC') <> FEmpresa then
    raise Exception.Create(SCompraFiscalNoLocal);
  FEstado := LeerTexto('ESTADO_FISCAL_FACC');
  FDocumento := LeerTexto('DOCUMENTO_FISCAL_FACC');
  FPeticion := FConsulta.FieldByName('XML_PETICION_FISCAL_FACC').AsString;
  FRespuesta := FConsulta.FieldByName('XML_RESPUESTA_FISCAL_FACC').AsString;
  FSistema := LeerTexto('SISTEMA_FISCAL_FACC');
  FEntorno := LeerTexto('ENTORNO_FISCAL_FACC');
  FCsv := LeerTexto('CSV_FISCAL_FACC');
  FError := LeerTexto('ERROR_FISCAL_FACC');
  FCertificado := LeerTexto('CODIGO_CERTIFICADO_EMP');
  FTitularCertificado := LeerTexto('TITULAR_CERTIFICADO_EMP');
end;

function TEmisionCompraDirecta.DescripcionOperacion: string;
var
  oLineas: TUniQuery;
begin
  oLineas := CrearConsulta;
  try
    oLineas.SQL.Text :=
      'SELECT LEFT(GROUP_CONCAT(DISTINCT DESCRIPCION_ARTICULO_FACCLIN ' +
      'ORDER BY LINEA_FACCLIN SEPARATOR ''; ''), 500) AS DESCRIPCION ' +
      'FROM fza_facturas_compra_lineas WHERE SERIE_FACC_FACCLIN = :SERIE ' +
      'AND NUMERO_FACC_FACCLIN = :NUMERO';
    oLineas.ParamByName('SERIE').AsString := FSerie;
    oLineas.ParamByName('NUMERO').AsString := FNumero;
    oLineas.Open;
    Result := Trim(oLineas.FieldByName('DESCRIPCION').AsString);
    if Result = '' then
      Result := ClasificarCompraDirecta(
        ModalidadCompra(LeerTexto('MODALIDAD_FACC'))).TextoLegal;
  finally
    FreeAndNil(oLineas);
  end;
end;

procedure TEmisionCompraDirecta.ValidarDatos;
begin
  if LeerTexto('ESTADO_FACC') <> 'CERRADA' then
    raise Exception.Create(SCompraFiscalCerrar);
  if (Length(NormalizarNifVerifactu(LeerTexto('NIF_PRV_FACC'))) <> 9) or
     (Length(NormalizarNifVerifactu(LeerTexto('NIF_EMPRESA_FACC'))) <> 9) or
     (LeerTexto('RAZON_SOCIAL_PRV_FACC') = '') or
     (LeerTexto('RAZON_SOCIAL_EMPRESA_FACC') = '') then
    raise Exception.Create(SCompraFiscalDatos);
  if ModalidadCompra(LeerTexto('MODALIDAD_FACC')) = mcdOrdinaria then
    raise Exception.Create(SCompraFiscalInexistente);
end;

procedure TEmisionCompraDirecta.ValidarDeduccionAgricola(
  const AEntrada: TRegistroCompraDirectaSii);
var
  oPagos: TUniQuery;
begin
  oPagos := CrearConsulta;
  try
    oPagos.SQL.Text :=
      'SELECT COALESCE(SUM(IMPORTE_PAGADO_EFEC), 0) AS PAGADO ' +
      'FROM fza_efectos_compra WHERE SERIE_FACC_EFEC = :SERIE ' +
      'AND NUMERO_FACC_EFEC = :NUMERO';
    oPagos.ParamByName('SERIE').AsString := FSerie;
    oPagos.ParamByName('NUMERO').AsString := FNumero;
    oPagos.Open;
    if (AEntrada.Modalidad = mcdReagp) and (AEntrada.CuotaDeducible > 0) and
       (oPagos.FieldByName('PAGADO').AsCurrency <
        LeerImporte('TOTAL_LIQUIDO_FACC')) then
      raise Exception.Create(SCompraFiscalCompensacionPendiente);
  finally
    FreeAndNil(oPagos);
  end;
end;

procedure TEmisionCompraDirecta.PrepararSii;
var
  oEntrada: TRegistroCompraDirectaSii;
  iIndice: Integer;
  dCuota: Currency;
begin
  oEntrada := Default(TRegistroCompraDirectaSii);
  oEntrada.Modalidad := ModalidadCompra(LeerTexto('MODALIDAD_FACC'));
  oEntrada.NifEmpresa := NormalizarNifVerifactu(LeerTexto('NIF_EMPRESA_FACC'));
  oEntrada.NombreEmpresa := LeerTexto('RAZON_SOCIAL_EMPRESA_FACC');
  oEntrada.NifProveedor := NormalizarNifVerifactu(LeerTexto('NIF_PRV_FACC'));
  oEntrada.NombreProveedor := LeerTexto('RAZON_SOCIAL_PRV_FACC');
  oEntrada.Documento := FDocumento;
  oEntrada.Fecha := FConsulta.FieldByName('FECHA_FACC').AsDateTime;
  if FConsulta.FieldByName('FECHA_REGISTRO_CONTABLE_FACC').IsNull or
     FConsulta.FieldByName('CUOTA_DEDUCIBLE_FACC').IsNull then
    raise Exception.Create(SCompraFiscalCuota);
  oEntrada.FechaContable := FConsulta.FieldByName(
    'FECHA_REGISTRO_CONTABLE_FACC').AsDateTime;
  oEntrada.Descripcion := DescripcionOperacion;
  oEntrada.Total := LeerImporte('TOTAL_FACC');
  oEntrada.BaseCompensacion := LeerImporte('TOTAL_BASES_FACC');
  oEntrada.PorcentajeCompensacion :=
    LeerImporte('PORCENTAJE_COMPENSACION_FACC');
  oEntrada.ImporteCompensacion := LeerImporte('TOTAL_COMPENSACION_FACC');
  oEntrada.CuotaDeducible := LeerImporte('CUOTA_DEDUCIBLE_FACC');
  dCuota := LeerImporte('TOTAL_IVAN_FACC') +
    LeerImporte('TOTAL_IVAR_FACC') + LeerImporte('TOTAL_IVAS_FACC') +
    LeerImporte('TOTAL_IVAE_FACC');
  if oEntrada.Modalidad = mcdReagp then
    dCuota := oEntrada.ImporteCompensacion;
  if (oEntrada.CuotaDeducible < 0) or (oEntrada.CuotaDeducible > dCuota) then
    raise Exception.Create(SCompraFiscalCuotaInvalida);
  ValidarDeduccionAgricola(oEntrada);
  for iIndice := 0 to 3 do
  begin
    oEntrada.Bandas[iIndice].Base := LeerImporte(
      'TOTAL_BASEI_IVA' + TRAMOS[iIndice] + '_FACC');
    oEntrada.Bandas[iIndice].Cuota := LeerImporte(
      'TOTAL_IVA' + TRAMOS[iIndice] + '_FACC');
    oEntrada.Bandas[iIndice].Porcentaje := LeerImporte(
      'PORCENTAJE_IVA' + TRAMOS[iIndice] + '_FACC');
    oEntrada.Bandas[iIndice].PorcentajeRecargo := LeerImporte(
      'PORCENTAJE_RE' + TRAMOS[iIndice] + '_FACC');
    oEntrada.Bandas[iIndice].CuotaRecargo := LeerImporte(
      'TOTAL_RE' + TRAMOS[iIndice] + '_FACC');
  end;
  FPeticion := EnvolverSoapSii(ConstruirCompraDirectaSii(oEntrada));
end;

function TEmisionCompraDirecta.SistemaInformatico: string;
begin
  ValidarInstalacionSif(LeerTexto('NUMERO_INSTALACION_EMP'),
    LeerTexto('VERSION_INSTALACION_EMP'),
    LeerTexto('CODIGO_SIF_INSTALACION_EMP'),
    LeerTexto('RAZON_SOCIAL_EMPRESA_FACC'), LeerTexto('NIF_EMPRESA_FACC'));
  Result := '<sum1:SistemaInformatico><sum1:NombreRazon>' +
    Xml(LeerProductorSoftwareVerifactu(FParametros)) + '</sum1:NombreRazon>' +
    '<sum1:NIF>' + Xml(LeerNifProductorSoftwareVerifactu(FParametros)) +
    '</sum1:NIF><sum1:NombreSistemaInformatico>ViraCash' +
    '</sum1:NombreSistemaInformatico><sum1:IdSistemaInformatico>FZ' +
    '</sum1:IdSistemaInformatico><sum1:Version>' +
    Xml(LeerTexto('VERSION_INSTALACION_EMP')) + '</sum1:Version>' +
    '<sum1:NumeroInstalacion>' + Xml(LeerTexto('NUMERO_INSTALACION_EMP')) +
    '</sum1:NumeroInstalacion><sum1:TipoUsoPosibleSoloVerifactu>N' +
    '</sum1:TipoUsoPosibleSoloVerifactu><sum1:TipoUsoPosibleMultiOT>S' +
    '</sum1:TipoUsoPosibleMultiOT><sum1:IndicadorMultiplesOT>S' +
    '</sum1:IndicadorMultiplesOT></sum1:SistemaInformatico>';
end;

function TEmisionCompraDirecta.DocumentoAnterior(
  const ASerie, ANumero, AHuella, AFormatoDefecto: string): string;
var
  oAnterior: TUniQuery;
begin
  Result := ComponerNumSerieFactura(AFormatoDefecto, ASerie, ANumero);
  oAnterior := CrearConsulta;
  try
    oAnterior.SQL.Text :=
      'SELECT DOCUMENTO_FISCAL_FACC FROM fza_facturas_compra ' +
      'WHERE SERIE_FACC = :SERIE AND NUMERO_FACC = :NUMERO ' +
      'AND HUELLA_FISCAL_FACC = :HUELLA LIMIT 1';
    oAnterior.ParamByName('SERIE').AsString := ASerie;
    oAnterior.ParamByName('NUMERO').AsString := ANumero;
    oAnterior.ParamByName('HUELLA').AsString := AHuella;
    oAnterior.Open;
    if (not oAnterior.IsEmpty) and
       (Trim(oAnterior.FieldByName(
         'DOCUMENTO_FISCAL_FACC').AsString) <> '') then
      Result := oAnterior.FieldByName('DOCUMENTO_FISCAL_FACC').AsString;
  finally
    FreeAndNil(oAnterior);
  end;
end;

procedure TEmisionCompraDirecta.Encadenar(
  var AEntrada: TEntradaConstruccionRegistroAlta);
var
  oCadena: TUniQuery;
begin
  oCadena := CrearConsulta;
  try
    FConexion.ExecSQL('INSERT IGNORE INTO fza_verifactu_cadena ' +
      '(NIF_VFCAD, CONTADOR_VFCAD, INSTANTE_ALTA, USUARIO_ALTA) ' +
      'VALUES (:NIF, 0, NOW(), :USUARIO)', [AEntrada.NifEmisor, FUsuario]);
    oCadena.SQL.Text :=
      'SELECT SERIE_FAC_VFCAD, NUMERO_FAC_VFCAD, FECHA_FAC_VFCAD, ' +
      'HUELLA_VFCAD FROM fza_verifactu_cadena WHERE NIF_VFCAD = :NIF ' +
      'FOR UPDATE';
    oCadena.ParamByName('NIF').AsString := AEntrada.NifEmisor;
    oCadena.Open;
    AEntrada.HuellaAnterior := oCadena.FieldByName('HUELLA_VFCAD').AsString;
    AEntrada.CadenaNumSerieFactura := DocumentoAnterior(
      oCadena.FieldByName('SERIE_FAC_VFCAD').AsString,
      oCadena.FieldByName('NUMERO_FAC_VFCAD').AsString,
      AEntrada.HuellaAnterior, AEntrada.FormatoDocumento);
    AEntrada.CadenaFecha := FormatDateTime('dd-mm-yyyy',
      oCadena.FieldByName('FECHA_FAC_VFCAD').AsDateTime);
  finally
    FreeAndNil(oCadena);
  end;
end;

procedure TEmisionCompraDirecta.GuardarCadena;
begin
  FConexion.ExecSQL('UPDATE fza_verifactu_cadena ' +
    'SET CONTADOR_VFCAD = CONTADOR_VFCAD + 1, SERIE_FAC_VFCAD = :SERIE, ' +
    'NUMERO_FAC_VFCAD = :NUMERO, FECHA_FAC_VFCAD = :FECHA, ' +
    'HUELLA_VFCAD = :HUELLA, INSTANTE_MODIF = NOW(), ' +
    'USUARIO_MODIF = :USUARIO WHERE NIF_VFCAD = :NIF',
    [FSerie, FNumero, FConsulta.FieldByName('FECHA_FACC').AsDateTime,
     FHuella, FUsuario, NormalizarNifVerifactu(LeerTexto('NIF_PRV_FACC'))]);
end;

procedure TEmisionCompraDirecta.PrepararVerifactu;
var
  oEntrada: TEntradaConstruccionRegistroAlta;
  oDesglose: TEntradaDesgloseFiscal;
  oRegistro: TResultadoConstruccionRegistroAlta;
  iIndice: Integer;
begin
  if LeerTexto('ESREPRESENTACION_FISCAL_FACC') <> 'S' then
    raise Exception.Create(SCompraFiscalRepresentacion);
  oEntrada := Default(TEntradaConstruccionRegistroAlta);
  oEntrada.NifEmisor := NormalizarNifVerifactu(LeerTexto('NIF_PRV_FACC'));
  oEntrada.NombreEmisor := LeerTexto('RAZON_SOCIAL_PRV_FACC');
  oEntrada.NifCliente := NormalizarNifVerifactu(LeerTexto('NIF_EMPRESA_FACC'));
  oEntrada.NombreCliente := LeerTexto('RAZON_SOCIAL_EMPRESA_FACC');
  oEntrada.FormatoDocumento := LeerTexto('FORMATO_DOCUMENTO_EMP');
  oEntrada.Serie := FSerie;
  oEntrada.Numero := FNumero;
  oEntrada.NumSerieFactura := FDocumento;
  oEntrada.FechaExpedicion := FormatDateTime('dd-mm-yyyy',
    FConsulta.FieldByName('FECHA_FACC').AsDateTime);
  oEntrada.TipoFactura := 'F1';
  oEntrada.EmitidaPorTerceroODestinatario := 'D';
  oEntrada.DescripcionOperacion := DescripcionOperacion;
  oEntrada.CuotaTotal := FormatearImporteVerifactu(
    LeerImporte('TOTAL_IMPUESTOS_FACC'));
  oEntrada.ImporteTotal := FormatearImporteVerifactu(LeerImporte('TOTAL_FACC'));
  oEntrada.FechaHoraHuso := NuevaFechaHoraGenRegistro;
  FFechaHora := oEntrada.FechaHoraHuso;
  oEntrada.SistemaInformaticoXml := SistemaInformatico;
  oDesglose := Default(TEntradaDesgloseFiscal);
  for iIndice := 0 to 3 do
  begin
    oDesglose.Bandas[iIndice].Porcentaje := LeerImporte(
      'PORCENTAJE_IVA' + TRAMOS[iIndice] + '_FACC');
    oDesglose.Bandas[iIndice].Base := LeerImporte(
      'TOTAL_BASEI_IVA' + TRAMOS[iIndice] + '_FACC');
    oDesglose.Bandas[iIndice].Cuota := LeerImporte(
      'TOTAL_IVA' + TRAMOS[iIndice] + '_FACC');
    oDesglose.Bandas[iIndice].EsExenta := iIndice = 3;
    oDesglose.Bandas[iIndice].PorcentajeRecargo := LeerImporte(
      'PORCENTAJE_RE' + TRAMOS[iIndice] + '_FACC');
    oDesglose.Bandas[iIndice].CuotaRecargo := LeerImporte(
      'TOTAL_RE' + TRAMOS[iIndice] + '_FACC');
  end;
  oEntrada.DesgloseXml := ConstruirDesgloseFiscal(oDesglose);
  Encadenar(oEntrada);
  oRegistro := ConstruirRegistroAltaVerifactu(oEntrada);
  FHuella := oRegistro.Huella;
  FPeticion := EnvolverAutofacturaVerifactu(oEntrada.NifEmisor,
    oEntrada.NombreEmisor, oRegistro.Xml);
  FQr := ConstruirUrlQR(FParametros, oEntrada.NifEmisor,
    oEntrada.FormatoDocumento, FSerie, FNumero,
    FConsulta.FieldByName('FECHA_FACC').AsDateTime, LeerImporte('TOTAL_FACC'));
  GuardarCadena;
end;

procedure TEmisionCompraDirecta.GuardarPreparado;
begin
  FConexion.ExecSQL('UPDATE fza_facturas_compra ' +
    'SET DOCUMENTO_FISCAL_FACC = :DOCUMENTO, ' +
    'SISTEMA_FISCAL_FACC = :SISTEMA, ESTADO_FISCAL_FACC = :ESTADO, ' +
    'XML_PETICION_FISCAL_FACC = :XML, HUELLA_FISCAL_FACC = :HUELLA, ' +
    'URL_QR_FISCAL_FACC = :QR, FECHA_HORA_FISCAL_FACC = :FECHA_HORA, ' +
    'ENTORNO_FISCAL_FACC = :ENTORNO, INSTANTE_MODIF = NOW(), ' +
    'USUARIO_MODIF = :USUARIO WHERE SERIE_FACC = :SERIE ' +
    'AND NUMERO_FACC = :NUMERO',
    [FDocumento, FSistema, FEstado, FPeticion, FHuella,
     FQr, FFechaHora, FEntorno, FUsuario, FSerie, FNumero]);
end;

procedure TEmisionCompraDirecta.Preparar;
var
  oModo: TModoVerifactu;
begin
  ValidarDatos;
  FDocumento := ComponerNumSerieFactura(
    LeerTexto('FORMATO_DOCUMENTO_EMP'), FSerie, FNumero);
  oModo := ModoVerifactu(FParametros);
  FEntorno := VerifactuEntorno(FParametros);
  if (oModo = mvSinVerifactu) or
     ((LeerTexto('MODALIDAD_FACC') = 'REAGP') and (oModo <> mvSii)) then
  begin
    FSistema := 'SIN';
    FEstado := 'NO_APLICA';
  end
  else if oModo = mvSii then
  begin
    FSistema := 'SII';
    PrepararSii;
    FEstado := 'PREPARADO';
  end
  else if oModo = mvVerifactu then
  begin
    FSistema := 'VERIFACTU';
    PrepararVerifactu;
    FEstado := 'PREPARADO';
  end
  else
    raise Exception.Create(
      'Seleccione VERIFACTU o SII para remitir una compra directa.');
  GuardarPreparado;
end;

function TEmisionCompraDirecta.UrlServicio: string;
var
  sBase, sParametro: string;
begin
  sBase := 'https://prewww1.aeat.es';
  if FEntorno = 'PRO' then
    sBase := 'https://www1.agenciatributaria.gob.es';
  if FSistema = 'SII' then
  begin
    sBase := sBase + '/wlpl/SSII-FACT/ws/fr/SiiFactFRV1SOAP';
    sParametro := 'appSiiRecibidasUrlEnvio';
  end
  else
  begin
    sBase := sBase + '/wlpl/TIKE-CONT/ws/SistemaFacturacion/VerifactuSOAP';
    sParametro := 'appVerifactuUrlEnvio';
  end;
  if FEntorno = 'PRO' then
    sParametro := sParametro + 'Pro'
  else
    sParametro := sParametro + 'Pre';
  Result := FParametros.GetString(sParametro, sBase);
end;

procedure TEmisionCompraDirecta.Interpretar(AEstadoHttp: Integer);
var
  oSii: TInterpretacionRespuestaSii;
  oVf: TInterpretacionRespuestaAeat;
  bAceptado: Boolean;
begin
  bAceptado := False;
  FEstado := 'INCIERTO';
  if FSistema = 'SII' then
  begin
    if EsRespuestaSiiDefinitiva(AEstadoHttp, FRespuesta) then
    begin
      oSii := InterpretarRespuestaSii(AEstadoHttp, FRespuesta);
      bAceptado := oSii.Aceptado;
      FCsv := oSii.Csv;
      FError := oSii.CodigoError + ' ' + oSii.DescripcionError;
      FEstado := 'RECHAZADO';
    end;
  end
  else if EsRespuestaAeatDefinitiva(AEstadoHttp, FRespuesta) then
  begin
    oVf := InterpretarRespuestaAeat(AEstadoHttp, FRespuesta);
    bAceptado := oVf.Aceptado or oVf.Duplicado;
    FCsv := oVf.Csv;
    FError := oVf.CodigoError + ' ' + oVf.DescripcionError;
    FEstado := 'RECHAZADO';
  end;
  if bAceptado then
    FEstado := 'ACEPTADO';
end;

procedure TEmisionCompraDirecta.GuardarRespuesta;
begin
  FConexion.ExecSQL('UPDATE fza_facturas_compra ' +
    'SET ESTADO_FISCAL_FACC = :ESTADO, XML_RESPUESTA_FISCAL_FACC = :XML, ' +
    'CSV_FISCAL_FACC = :CSV, ERROR_FISCAL_FACC = :ERROR, ' +
    'INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO ' +
    'WHERE SERIE_FACC = :SERIE AND NUMERO_FACC = :NUMERO',
    [FEstado, FRespuesta, FCsv, Trim(FError), FUsuario, FSerie, FNumero]);
end;

procedure TEmisionCompraDirecta.Enviar;
var
  iEstadoHttp: Integer;
begin
  FUrl := UrlServicio;
  try
    if Assigned(FTransporte) then
      FTransporte(FUrl, FPeticion, FCertificado, FTitularCertificado,
        iEstadoHttp, FRespuesta)
    else
      EnviarSoapAeatConCertificado(FUrl, FPeticion,
        FCertificado, FTitularCertificado, iEstadoHttp, FRespuesta);
    Interpretar(iEstadoHttp);
  except
    on E: Exception do
    begin
      FEstado := 'INCIERTO';
      FError := E.Message;
    end;
  end;
  GuardarRespuesta;
end;

function TEmisionCompraDirecta.Ejecutar: string;
var
  oBloqueo: TUniQuery;
  sClave: string;
begin
  sClave := 'CD:' + Copy(THashSHA2.GetHashString(FSerie + #0 + FNumero), 1, 60);
  oBloqueo := CrearConsulta;
  try
    oBloqueo.SQL.Text := 'SELECT GET_LOCK(:CLAVE, 0) AS BLOQUEADO';
    oBloqueo.ParamByName('CLAVE').AsString := sClave;
    oBloqueo.Open;
    if oBloqueo.FieldByName('BLOQUEADO').AsInteger <> 1 then
      raise Exception.Create(SCompraFiscalEnCurso);
    try
      Result := EjecutarBloqueado;
    finally
      FConexion.ExecSQL('DO RELEASE_LOCK(:CLAVE)', [sClave]);
    end;
  finally
    FreeAndNil(oBloqueo);
  end;
end;

function TEmisionCompraDirecta.EjecutarBloqueado: string;
begin
  if FConexion.InTransaction then
    raise Exception.Create(SCompraFiscalTransaccion);
  FConexion.StartTransaction;
  try
    Cargar;
    if FEstado = '' then
      Preparar;
    // La petición inmutable y la cadena se confirman ANTES del transporte.
    // Un reintento reenvía exactamente el XML original (misma huella).
    if (FEstado = 'PREPARADO') or (FEstado = 'INCIERTO') or
       (FEstado = 'ENVIANDO') then
    begin
      FEstado := 'ENVIANDO';
      GuardarRespuesta;
    end;
    FConexion.Commit;
  except
    FConexion.Rollback;
    raise;
  end;
  if FEstado = 'ENVIANDO' then
    Enviar;
  if FEstado = 'NO_APLICA' then
    Result := SCompraFiscalExcluida
  else
    Result := FSistema + ': ' + FEstado + '. ' + Trim(FError);
end;

function ProcesarFiscalCompraDirecta(AConexion: TUniConnection;
  const AParametros: IParametrosAplicacion;
  const ASerie, ANumero, AUsuario, AEmpresaLocal: string;
  const ATransporte: TTransporteFiscalCompraDirecta): string;
var
  oEmision: TEmisionCompraDirecta;
begin
  oEmision := TEmisionCompraDirecta.Create(AConexion, AParametros,
    ASerie, ANumero, AUsuario, AEmpresaLocal, ATransporte);
  try
    Result := oEmision.Ejecutar;
  finally
    FreeAndNil(oEmision);
  end;
end;

procedure ExigirCompraSinRegistroFiscal(AConexion: TUniConnection;
  const ASerie, ANumero: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'SELECT 1 FROM fza_facturas_compra WHERE SERIE_FACC = :SERIE ' +
      'AND NUMERO_FACC = :NUMERO AND ' +
      '(COALESCE(XML_PETICION_FISCAL_FACC, '''') <> '''' OR ' +
      'COALESCE(ESTADO_FISCAL_FACC, '''') <> '''') LIMIT 1';
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      raise Exception.Create(SCompraFiscalBloqueada);
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.
