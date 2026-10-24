{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataCajaSubsanacionRepositorio                             }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       16/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Guarda unidades, importes, stock, cobro, auditoría y registro fiscal.     }
{******************************************************************************}
unit UniDataCajaSubsanacionRepositorio;

interface

uses
  Uni, inLibCajaSubsanacionIntf, inLibParametrosIntf,
  inLibPermisosIntf, inLibLogIntf, inLibVerifactuSubsanacionIntf;

type
  TDependenciasSubsanacionCaja = record
    ParametrosApp: IParametrosAplicacion;
    ParametrosCaja: IParametrosCaja;
    Permisos: IPermisosAplicacion;
    Fiscal: IServicioVerifactuCorreccionRegistro;
    RegistroLog: IRegistroLog;
    Usuario: string;
  end;

function CrearServicioSubsanacionCajaUniDAC(AConexion: TUniConnection;
  const ADependencias: TDependenciasSubsanacionCaja): IServicioSubsanacionCaja;

implementation

uses
  inLibFormatoDocumento, UniDataFormatoDocumentoRepositorio,
  System.SysUtils, System.StrUtils, System.Classes, System.JSON, System.Hash,
  System.Diagnostics, System.Generics.Collections, Data.DB,
  Datasnap.DBClient, Datasnap.Provider,
  inLibCajaSubsanacion, inLibFacturas,
  inLibMsgPersistenciaSubsanacionCaja, UniDataCajaSubsanacionImportes,
  UniDataMovimientosAlmacenRecalculo, inLibPrestaShopColaSenal,
  inLibVerifactu, System.Math;

const
  ftotal = 'TOTAL_LIQUIDO_FAC';
  ftotalope = 'IMPORTE_TOTAL_OPCAJA';
  fentregado = 'IMPORTE_ENTREGADO_PAGO';
  fcambio = 'IMPORTE_CAMBIO_PAGO';
  fforma = 'CODIGO_FP_CFP';
  fref = 'REFERENCIA_FACPAG';
  SQL_CLAVE_OPE =
    'CODIGO_EMP_OPCAJA = :EMP AND CODIGO_ALM_OPCAJA = :ALM ' +
    'AND CODIGO_CAJA_OPCAJA = :CAJA ' +
    'AND NUMERO_OPERACION_OPCAJA = :OPE ';
  SQL_CLAVE_PAGO =
    'CODIGO_EMP_PAGO = :EMP AND CODIGO_ALM_PAGO = :ALM ' +
    'AND CODIGO_CAJA_PAGO = :CAJA AND NUMERO_OPERACION_PAGO = :OPE ';
  // Cualquier forma de pago (también divisas, criptomonedas y bonos) salvo
  // vales y deuda, que no se cambian en una subsanación.
  SQL_MEDIO_ADMITIDO =
    'CODIGO_FP_CFP NOT IN (''VALE'', ''DEUDA'') ' +
    'AND CHAR_LENGTH(CODIGO_FP_CFP) <= 10 ';
  // Líneas que el TPV graba al consumir o dejar un anticipo de depósito.
  ARTICULO_ABONO_CUENTA = 'ACUENTA';
  ARTICULO_ANTICIPO = 'ANTICIPO';
  CAMPOS_TOTALES =
    'TOTAL_BASEI_IVAN_FAC,TOTAL_BASEI_IVAR_FAC,' +
    'TOTAL_BASEI_IVAS_FAC,TOTAL_BASEI_IVAE_FAC,TOTAL_BASES_FAC,' +
    'TOTAL_IVAN_FAC,TOTAL_IVAR_FAC,TOTAL_IVAS_FAC,TOTAL_IVAE_FAC,' +
    'TOTAL_REN_FAC,TOTAL_RER_FAC,TOTAL_RES_FAC,TOTAL_REE_FAC,' +
    'TOTAL_IMPUESTOS_FAC,TOTAL_RETENCION_FAC,TOTAL_LIQUIDO_FAC';
  CAMPOS_CABECERA =
    'SERIE_FAC,NUMERO_FAC,FECHA_FAC,CODIGO_EMP_FAC,' +
    'CODIGO_ALM_FAC,CODIGO_CAJA_FAC,NUMERO_OPERACION_FAC,' +
    'ESCONSOLIDADA_FAC,TIPO_FAC,FASE_FAC,INSTANTE_MODIF,' +
    'RAZON_SOCIAL_EMPRESA_FAC,CODIGO_CLI_FAC,' +
    'RAZON_SOCIAL_CLIENTE_FAC,NIF_CLIENTE_FAC,DIRECCION1_CLIENTE_FAC,' +
    'ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC,' +
    'ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC,' +
    'ESINTRACOMUNITARIO_CLIENTE_FAC,ESVENTA_ACTIVO_FIJO_FAC,' +
    'ESRETENCIONES_CLIENTE_FAC,ESRETENCIONES_EMPRESA_FAC,' +
    'ESIVA_EXENTO_CLIENTE_FAC,ESIVA_RECARGO_CLIENTE_FAC,' +
    'ESIRPF_IMP_INCL_ZONA_IVA_FAC,ESAPLICA_RE_ZONA_IVA_FAC,' +
    'GRUPO_ZONA_IVA_EMPRESA_FAC,CODIGO_IVA_FAC,' +
    'PORCENTAJE_RETENCION_FAC,PORCENTAJE_IVAN_FAC,' +
    'PORCENTAJE_IVAR_FAC,PORCENTAJE_IVAS_FAC,PORCENTAJE_IVAE_FAC,' +
    'PORCENTAJE_REN_FAC,PORCENTAJE_RER_FAC,' +
    'PORCENTAJE_RES_FAC,PORCENTAJE_REE_FAC,' + CAMPOS_TOTALES;
  CAMPOS_IMPORTES_LINEA =
    'PRECIO_SALIDA_FACLIN,PORCENTAJE_DTO_FACLIN,PRECIO_DTO_FACLIN,' +
    'PRECIO_VENTA_SIVA_ARTICULO_FACLIN,' +
    'PRECIO_VENTA_CIVA_ARTICULO_FACLIN,' +
    'TOTAL_FAC_SIVA_FACLIN,TOTAL_FACLIN';
  // Campos que graba la subsanación en cada línea corregida: las unidades
  // y los importes que se derivan de ellas.
  CAMPOS_GUARDADO_LINEA = 'CANTIDAD_FACLIN,' + CAMPOS_IMPORTES_LINEA;
  CAMPOS_LINEAS =
    'LINEA_FACLIN,CODIGO_ART_FACLIN,CODIGO_UNIDAD_FACLIN,' +
    'DESCRIPCION_ARTICULO_FACLIN,CANTIDAD_FACLIN,NUMERO_MOV_FACLIN,' +
    'ESIMP_INCL_TARIFA_FACLIN,TIPO_IVA_ARTICULO_FACLIN,' +
    'PORCENTAJE_IVA_FACLIN,INSTANTE_MODIF,' + CAMPOS_IMPORTES_LINEA;
  // Salidas de stock del ticket, por su documento de venta.
  TIPO_DOC_MOVIMIENTO_VENTA = 'VE';
  CAMPOS_MOVIMIENTO =
    'NUMERO_MOV,LINEA_MOV,CODIGO_EMP_MOV,CODIGO_ALM_MOV,' +
    'CODIGO_ALM_CONTRA_MOV,CODIGO_UNIDAD_MOV,CODIGO_ART_MOV,TIPO_MOV,' +
    'CANTIDAD_MOV,PRECIO_MEDIO_MOV,FECHA_MOV,CODIGO_ALM_DOC_MOV,' +
    'NUMERO_OPERACION_DOC_MOV,CODIGO_CAJA_DOC_MOV,CODIGO_CLI_MOV,' +
    'ESACTIVO_MOV';

type
  // Papel de cada fila de fza_caja_operaciones de la venta.
  TFilaOperacionSubsanacion = (fosVentaNormal, fosVentaDeposito,
    fosCierreDeposito, fosConsumoAnticipo, fosAnticipo, fosVale, fosOtra);

  TDatosSubsanacionCaja = class
  public
    Cabecera: TClientDataSet;
    Lineas: TClientDataSet;
    Operacion: TClientDataSet;
    Pagos: TClientDataSet;
    PagosFactura: TClientDataSet;
    Depositos: TClientDataSet;
    // Formas de pago que devuelven cambio (tickets con el cambio sin grabar).
    FormasConCambio: TDictionary<string, Boolean>;
    // Resultado de AnalizarLineas: líneas que no se pueden corregir, venta
    // de depósito (ID_OPCAJA) y anticipo consumido de cada prenda, y la fila
    // de la venta del resto de líneas.
    LineasFijas: TDictionary<string, Boolean>;
    VentaDepositoLinea: TDictionary<string, Integer>;
    AnticipoLinea: TDictionary<string, Currency>;
    IdVentaNormal: Integer;
    constructor Create;
    destructor Destroy; override;
    function ComoJson: string;
  end;

  TServicioSubsanacionCajaUniDAC = class(TInterfacedObject,
    IServicioSubsanacionCaja)
  private
    FConexion: TUniConnection;
    FDependencias: TDependenciasSubsanacionCaja;
    function Consulta(const ASql: string;
      const AClave: TClaveOperacionSubsanacionCaja): TUniQuery;
    function LeerDatos(const AClave: TClaveOperacionSubsanacionCaja;
      ABloquear: Boolean): TDatosSubsanacionCaja;
    function LeerCopia(const ASql: string;
      const AClave: TClaveOperacionSubsanacionCaja;
      ABloquear: Boolean): TClientDataSet;
    function CrearSnapshot(const AClave: TClaveOperacionSubsanacionCaja;
      ADatos: TDatosSubsanacionCaja): TOperacionSubsanacionCaja;
    procedure ExigirPermiso;
    procedure ComprobarEsquema;
    procedure ValidarClave(const AClave: TClaveOperacionSubsanacionCaja);
    procedure ValidarDatos(ADatos: TDatosSubsanacionCaja;
      const AClave: TClaveOperacionSubsanacionCaja);
    procedure ValidarFiscal(const AClave: TClaveOperacionSubsanacionCaja);
    procedure ValidarVinculos(const AClave: TClaveOperacionSubsanacionCaja);
    procedure ValidarArqueo(ADatos: TDatosSubsanacionCaja;
      const AClave: TClaveOperacionSubsanacionCaja);
    function EsSinVerifactu: Boolean;
    procedure ValidarCabecera(ADatos: TDatosSubsanacionCaja);
    procedure ValidarOperaciones(ADatos: TDatosSubsanacionCaja;
      const AClave: TClaveOperacionSubsanacionCaja);
    procedure AnalizarLineas(ADatos: TDatosSubsanacionCaja);
    procedure LeerFormasConCambio(ADatos: TDatosSubsanacionCaja);
    procedure ValidarPago(ADatos: TDatosSubsanacionCaja);
    procedure ValidarMedio(const ASolicitud: TSolicitudSubsanacionCaja);
    procedure ValidarSolicitud(const ASolicitud: TSolicitudSubsanacionCaja;
      const AActual: TOperacionSubsanacionCaja;
      ADatos: TDatosSubsanacionCaja);
    procedure GuardarOperacionesVenta(ADatos: TDatosSubsanacionCaja;
      const ASolicitud: TSolicitudSubsanacionCaja);
    procedure Recalcular(ADatos: TDatosSubsanacionCaja;
      const ASolicitud: TSolicitudSubsanacionCaja);
    procedure ValidarLineasCalculadas(ADatos: TDatosSubsanacionCaja;
      AOriginales: TDataSet; const ALineas: TLineasSubsanacionCaja);
    procedure GuardarImportes(ADatos: TDatosSubsanacionCaja;
      const ASolicitud: TSolicitudSubsanacionCaja);
    function LeerMovimientosVenta(
      const AClave: TClaveOperacionSubsanacionCaja): TClientDataSet;
    procedure ValidarMovimientosVenta(AMovimientos: TDataSet;
      ACorregidas: TDictionary<string, TLineaSubsanacionCaja>);
    procedure BorrarMovimientosVenta(
      const AClave: TClaveOperacionSubsanacionCaja);
    procedure ReinsertarMovimientosVenta(AMovimientos: TDataSet;
      ACorregidas: TDictionary<string, TLineaSubsanacionCaja>;
      const AClave: TClaveOperacionSubsanacionCaja);
    function RegenerarMovimientosStock(ADatos: TDatosSubsanacionCaja;
      const ASolicitud: TSolicitudSubsanacionCaja): Integer;
    procedure GuardarCobro(ADatos: TDatosSubsanacionCaja;
      const ASolicitud: TSolicitudSubsanacionCaja);
    procedure InsertarCompensacion(const AClave: TClaveOperacionSubsanacionCaja;
      const ASerie: string; AOrigen, ALinea: Integer;
      const AObservacion: string);
    procedure InsertarPago(const AClave: TClaveOperacionSubsanacionCaja;
      const ASerie: string; ALinea: Integer;
      const APago: TPagoSubsanacionCaja; const AObservacion: string);
    procedure GuardarPagosFactura(ADatos: TDatosSubsanacionCaja;
      const ASolicitud: TSolicitudSubsanacionCaja);
    procedure GuardarAuditoria(const ASolicitud: TSolicitudSubsanacionCaja;
      const AAntes, ADespues: string);
    procedure ActualizarCampos(const ATabla, ACondicion,
      ACampos: string; AOrigen: TDataSet;
      const AClave: TClaveOperacionSubsanacionCaja);
  public
    constructor Create(AConexion: TUniConnection;
      const ADependencias: TDependenciasSubsanacionCaja);
    function Cargar(const AClave: TClaveOperacionSubsanacionCaja):
      TOperacionSubsanacionCaja;
    function Permitida: Boolean;
    function Guardar(const ASolicitud: TSolicitudSubsanacionCaja):
      TResultadoSubsanacionCaja;
  end;

function FasesRegistradas(
  const AParametrosApp: IParametrosAplicacion): TArray<string>;
begin
  if NoVerifactuActivo(AParametrosApp) then
    Result := [cFaseFacturaNoVerifactuOk]
  else
    Result := [cFaseFacturaVerifactuOk, 'VERIFACTU_ACEPT_ERR'];
end;

function EstadosRegistroAceptado(
  const AParametrosApp: IParametrosAplicacion): TArray<string>;
begin
  // NO VERI*FACTU no envía: basta el registro firmado y encadenado.
  if NoVerifactuActivo(AParametrosApp) then
    Result := ['NOVERIF_REGISTRADO', 'NOVERIF_SUBSANADO']
  else
    // VERI*FACTU y SII: la subsanación va por el sistema del alta
    Result := ['VERIFACTU_OK', 'VERIFACTU_PROCESADO', 'VERIFACTU_DUPLICADO',
      'VERIFACTU_SUBSANADO', 'VERIFACTU_ACEPT_ERR', 'SII_PROCESADO',
      'SII_ACEPT_ERR', 'SII_DUPLICADO', 'SII_MODIFICADO'];
end;

function ClaveCobro(ASerie: string; ALinea: Integer): string;
begin
  Result := ASerie + '|' + IntToStr(ALinea);
end;

// Líneas ya compensadas por una corrección anterior (TIPO N).
function LeerCobrosCompensados(APagos: TDataSet):
  TDictionary<string, Boolean>;
begin
  Result := TDictionary<string, Boolean>.Create;
  APagos.First;
  while not APagos.Eof do
  begin
    if APagos.FieldByName('TIPO_CORRECCION_PAGO').AsString = 'N' then
      Result.AddOrSetValue(ClaveCobro(
        APagos.FieldByName('SERIE_OPERACION_PAGO').AsString,
        APagos.FieldByName('NUMERO_LINEA_ORIGEN_PAGO').AsInteger), True);
    APagos.Next;
  end;
  APagos.First;
end;

function EsCobroVigente(APagos: TDataSet;
  ACompensados: TDictionary<string, Boolean>): Boolean;
begin
  Result := (APagos.FieldByName('TIPO_CORRECCION_PAGO').AsString <> 'N') and
    not ACompensados.ContainsKey(ClaveCobro(
      APagos.FieldByName('SERIE_OPERACION_PAGO').AsString,
      APagos.FieldByName('NUMERO_LINEA_PAGO').AsInteger));
end;

function LeerCobrosVigentes(APagos: TDataSet): TPagosSubsanacionCaja;
var
  oCompensados: TDictionary<string, Boolean>;
  oLista: TList<TPagoSubsanacionCaja>;
  oPago: TPagoSubsanacionCaja;
begin
  oCompensados := LeerCobrosCompensados(APagos);
  oLista := TList<TPagoSubsanacionCaja>.Create;
  try
    while not APagos.Eof do
    begin
      if EsCobroVigente(APagos, oCompensados) then
      begin
        oPago := Default(TPagoSubsanacionCaja);
        oPago.FormaPago := APagos.FieldByName(fforma).AsString;
        oPago.Referencia := APagos.FieldByName(fref).AsString;
        oPago.Importe := APagos.FieldByName(fentregado).AsCurrency -
          APagos.FieldByName(fcambio).AsCurrency;
        oPago.CodigoDivisa :=
          APagos.FieldByName('CODIGO_DIVISA_PAGO').AsString;
        oPago.RedBlockchain :=
          APagos.FieldByName('RED_BLOCKCHAIN_PAGO').AsString;
        oPago.FactorCambio :=
          APagos.FieldByName('FACTOR_CAMBIO_PAGO').AsFloat;
        oPago.ImporteDivisa :=
          APagos.FieldByName('IMPORTE_DIVISA_PAGO').AsFloat;
        oLista.Add(oPago);
      end;
      APagos.Next;
    end;
    APagos.First;
    Result := oLista.ToArray;
  finally
    FreeAndNil(oLista);
    FreeAndNil(oCompensados);
  end;
end;

function TotalCobros(const APagos: TPagosSubsanacionCaja): Currency;
var
  oPago: TPagoSubsanacionCaja;
begin
  Result := 0;
  for oPago in APagos do
    Result := Result + oPago.Importe;
end;

// Vales y deuda se conservan: ni se compensan ni se dan de alta de nuevo.
function EsCobroFijo(const AFormaPago: string): Boolean;
begin
  Result := MatchText(Trim(AFormaPago), ['VALE', 'DEUDA']);
end;

// Hasta 2026-09-21 la caja grababa lo entregado sin el cambio: el exceso
// sobre el total es el cambio que se devolvió con las formas que lo dan.
function DescontarCambioNoGrabado(const APagos: TPagosSubsanacionCaja;
  ATotal: Currency; AFormasConCambio: TDictionary<string, Boolean>):
  TPagosSubsanacionCaja;
var
  dExceso, dCambio: Currency;
  i: Integer;
begin
  Result := Copy(APagos);
  dExceso := TotalCobros(Result) - ATotal;
  for i := 0 to High(Result) do
    if (dExceso > 0) and (Result[i].Importe > 0) and
       AFormasConCambio.ContainsKey(UpperCase(Trim(Result[i].FormaPago))) then
    begin
      dCambio := Min(dExceso, Result[i].Importe);
      Result[i].Importe := Result[i].Importe - dCambio;
      dExceso := dExceso - dCambio;
    end;
end;

function ClasificarFilaOperacion(AOperacion: TDataSet):
  TFilaOperacionSubsanacion;
var
  sTipo: string;
  bDeposito: Boolean;
  dImporte: Currency;
begin
  sTipo := AOperacion.FieldByName('TIPO_OPERACION_OPCAJA').AsString;
  bDeposito := AOperacion.FieldByName('ID_DEPOSITO_OPCAJA').AsString <> '';
  dImporte := AOperacion.FieldByName(ftotalope).AsCurrency;
  if sTipo = 'VE' then
  begin
    if bDeposito then
      Result := fosVentaDeposito
    else
      Result := fosVentaNormal;
  end
  // Liquidación de un depósito: el préstamo se cierra (DE negativo, no
  // cuenta en el total) y el anticipo se consume (CB negativo).
  else if bDeposito and (sTipo = 'DE') and (dImporte < 0) then
    Result := fosCierreDeposito
  else if bDeposito and (sTipo = 'CB') and (dImporte < 0) then
    Result := fosConsumoAnticipo
  // Depósito nuevo o aumentado: anticipo que deja deuda al cliente.
  else if bDeposito and MatchText(sTipo, ['DE', 'CB']) then
    Result := fosAnticipo
  else if MatchText(sTipo, ['VR', 'VL']) then
    Result := fosVale
  else
    Result := fosOtra;
end;

// Importe de la fila que forma parte del total del ticket.
function ImporteFiscalFila(AOperacion: TDataSet): Currency;
begin
  Result := 0;
  if ClasificarFilaOperacion(AOperacion) in [fosVentaNormal,
     fosVentaDeposito, fosConsumoAnticipo, fosAnticipo] then
    Result := AOperacion.FieldByName(ftotalope).AsCurrency;
end;

function ContarCobrosFijos(const APagos: TPagosSubsanacionCaja):
  TDictionary<string, Integer>;
var
  oPago: TPagoSubsanacionCaja;
  sClave: string;
  iVeces: Integer;
begin
  Result := TDictionary<string, Integer>.Create;
  for oPago in APagos do
    if EsCobroFijo(oPago.FormaPago) then
    begin
      sClave := UpperCase(Trim(oPago.FormaPago)) + #9 +
        Trim(oPago.Referencia) + #9 + CurrToStr(oPago.Importe);
      if not Result.TryGetValue(sClave, iVeces) then
        iVeces := 0;
      Result.AddOrSetValue(sClave, iVeces + 1);
    end;
end;

// Los vales y la deuda del ticket deben llegar sin cambios.
procedure ValidarCobrosFijos(const AActuales, ANuevos: TPagosSubsanacionCaja);
var
  oActuales, oNuevos: TDictionary<string, Integer>;
  oPar: TPair<string, Integer>;
  iVeces: Integer;
  bIguales: Boolean;
begin
  oActuales := ContarCobrosFijos(AActuales);
  oNuevos := ContarCobrosFijos(ANuevos);
  try
    bIguales := oActuales.Count = oNuevos.Count;
    for oPar in oActuales do
      bIguales := bIguales and oNuevos.TryGetValue(oPar.Key, iVeces) and
        (iVeces = oPar.Value);
    if not bIguales then
      raise EArgumentException.Create(SSubsanacionValesFijos);
  finally
    FreeAndNil(oNuevos);
    FreeAndNil(oActuales);
  end;
end;

// Los cobros antiguos no guardaban la divisa: vacía equivale a euros.
function DivisaCobro(const APago: TPagoSubsanacionCaja): string;
begin
  Result := UpperCase(Trim(APago.CodigoDivisa));
  if Result = '' then
    Result := 'EUR';
end;

// Mismo importe por forma de pago y referencia: el cobro no se toca.
function CobrosDistintos(const AActuales,
  ANuevos: TPagosSubsanacionCaja): Boolean;
var
  oSaldos: TDictionary<string, Currency>;
  oPago: TPagoSubsanacionCaja;
  dSaldo: Currency;
  procedure Acumular(const APago: TPagoSubsanacionCaja; ASigno: Integer);
  var
    sClave: string;
  begin
    sClave := UpperCase(Trim(APago.FormaPago)) + #9 + Trim(APago.Referencia) +
      #9 + DivisaCobro(APago) + #9 + Trim(APago.RedBlockchain);
    if not oSaldos.TryGetValue(sClave, dSaldo) then
      dSaldo := 0;
    oSaldos.AddOrSetValue(sClave, dSaldo + ASigno * APago.Importe);
  end;
begin
  oSaldos := TDictionary<string, Currency>.Create;
  try
    for oPago in AActuales do
      Acumular(oPago, 1);
    for oPago in ANuevos do
      Acumular(oPago, -1);
    Result := False;
    for dSaldo in oSaldos.Values do
      Result := Result or (dSaldo <> 0);
  finally
    FreeAndNil(oSaldos);
  end;
end;

procedure ValidarCobrosSolicitud(const APagos: TPagosSubsanacionCaja;
  ATotal: Currency);
var
  oPago: TPagoSubsanacionCaja;
begin
  if Length(APagos) = 0 then
    raise EArgumentException.Create(SSubsanacionPagosInvalidos);
  for oPago in APagos do
  begin
    // Los vales emitidos son negativos; se validan aparte (sin cambios).
    if (Trim(oPago.FormaPago) = '') or
       ((oPago.Importe <= 0) and not EsCobroFijo(oPago.FormaPago)) or
       (Frac(oPago.Importe * 100) <> 0) then
      raise EArgumentException.Create(SSubsanacionPagosInvalidos);
    if Length(oPago.Referencia) > 100 then
      raise EArgumentException.Create(SSubsanacionReferenciaInvalida);
  end;
  if TotalCobros(APagos) <> ATotal then
    raise EArgumentException.Create(SSubsanacionPagosInvalidos);
end;

function HayImportesModificados(const ALineas: TLineasSubsanacionCaja):
  Boolean;
var
  oLinea: TLineaSubsanacionCaja;
begin
  Result := False;
  for oLinea in ALineas do
    Result := Result or LineaSubsanacionModificada(oLinea);
end;

function DatosComoJson(AOrigen: TDataSet): TJSONArray;
var
  oFila: TJSONObject;
  oCampo: TField;
begin
  Result := TJSONArray.Create;
  try
    AOrigen.First;
    while not AOrigen.Eof do
    begin
      oFila := TJSONObject.Create;
      Result.AddElement(oFila);
      for oCampo in AOrigen.Fields do
      begin
        if oCampo.IsNull then
          oFila.AddPair(oCampo.FieldName, TJSONNull.Create)
        else
          oFila.AddPair(oCampo.FieldName, oCampo.AsString);
      end;
      AOrigen.Next;
    end;
    AOrigen.First;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

constructor TDatosSubsanacionCaja.Create;
begin
  inherited Create;
  FormasConCambio := TDictionary<string, Boolean>.Create;
  LineasFijas := TDictionary<string, Boolean>.Create;
  VentaDepositoLinea := TDictionary<string, Integer>.Create;
  AnticipoLinea := TDictionary<string, Currency>.Create;
end;

destructor TDatosSubsanacionCaja.Destroy;
begin
  FreeAndNil(Cabecera);
  FreeAndNil(Lineas);
  FreeAndNil(Operacion);
  FreeAndNil(Pagos);
  FreeAndNil(PagosFactura);
  FreeAndNil(Depositos);
  FreeAndNil(FormasConCambio);
  FreeAndNil(LineasFijas);
  FreeAndNil(VentaDepositoLinea);
  FreeAndNil(AnticipoLinea);
  inherited;
end;

function TDatosSubsanacionCaja.ComoJson: string;
var
  oJson: TJSONObject;
begin
  oJson := TJSONObject.Create;
  try
    oJson.AddPair('factura', DatosComoJson(Cabecera));
    oJson.AddPair('lineas', DatosComoJson(Lineas));
    oJson.AddPair('operacion', DatosComoJson(Operacion));
    oJson.AddPair('cobros', DatosComoJson(Pagos));
    oJson.AddPair('pagosFactura', DatosComoJson(PagosFactura));
    Result := oJson.ToJSON;
  finally
    FreeAndNil(oJson);
  end;
end;

constructor TServicioSubsanacionCajaUniDAC.Create(
  AConexion: TUniConnection;
  const ADependencias: TDependenciasSubsanacionCaja);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  if not Assigned(ADependencias.Permisos) or
     not Assigned(ADependencias.Fiscal) or
     not Assigned(ADependencias.ParametrosApp) or
     not Assigned(ADependencias.ParametrosCaja) or
     not Assigned(ADependencias.RegistroLog) then
    raise EArgumentNilException.Create('ADependencias');
  FConexion := AConexion;
  FDependencias := ADependencias;
end;

function CrearServicioSubsanacionCajaUniDAC(AConexion: TUniConnection;
  const ADependencias: TDependenciasSubsanacionCaja): IServicioSubsanacionCaja;
begin
  Result := TServicioSubsanacionCajaUniDAC.Create(AConexion, ADependencias);
end;

function TServicioSubsanacionCajaUniDAC.Consulta(const ASql: string;
  const AClave: TClaveOperacionSubsanacionCaja): TUniQuery;
  procedure Parametro(const ANombre, AValor: string);
  begin
    if Assigned(Result.Params.FindParam(ANombre)) then
      Result.ParamByName(ANombre).AsString := AValor;
  end;
begin
  Result := TUniQuery.Create(nil);
  try
    Result.Connection := FConexion;
    Result.SQL.Text := ASql;
    Parametro('EMP', AClave.Empresa);
    Parametro('ALM', AClave.Almacen);
    Parametro('CAJA', AClave.Caja);
    Parametro('OPE', AClave.NumeroOperacion);
    Parametro('SERIE', AClave.SerieFactura);
    Parametro('NUMERO', AClave.NumeroFactura);
    Parametro('USUARIO', FDependencias.Usuario);
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TServicioSubsanacionCajaUniDAC.LeerCopia(const ASql: string;
  const AClave: TClaveOperacionSubsanacionCaja;
  ABloquear: Boolean): TClientDataSet;
var
  oConsulta: TUniQuery;
  oProveedor: TDataSetProvider;
  sSql: string;
begin
  sSql := ASql;
  if ABloquear then
    sSql := sSql + ' FOR UPDATE';
  oConsulta := Consulta(sSql, AClave);
  oProveedor := nil;
  Result := nil;
  try
    oConsulta.Open;
    oProveedor := TDataSetProvider.Create(nil);
    oProveedor.DataSet := oConsulta;
    Result := TClientDataSet.Create(nil);
    try
      Result.Data := oProveedor.Data;
    except
      FreeAndNil(Result);
      raise;
    end;
  finally
    FreeAndNil(oProveedor);
    FreeAndNil(oConsulta);
  end;
end;

function TServicioSubsanacionCajaUniDAC.Permitida: Boolean;
begin
  Result := (Trim(FDependencias.Usuario) <> '') and
    FDependencias.Permisos.Disponible and
    FDependencias.Permisos.TienePermiso(
      CodigoPermisoMto('CajaPagosHist', apmModificar), paPermitir);
end;

procedure TServicioSubsanacionCajaUniDAC.ExigirPermiso;
begin
  if not Permitida then
    raise EInvalidOpException.Create(SSubsanacionSinPermiso);
end;

procedure TServicioSubsanacionCajaUniDAC.ValidarClave(
  const AClave: TClaveOperacionSubsanacionCaja);
begin
  if (Trim(AClave.Empresa) = '') or (Trim(AClave.Almacen) = '') or
     (Trim(AClave.Caja) = '') or (Trim(AClave.NumeroOperacion) = '') or
     (Trim(AClave.SerieFactura) = '') or
     (Trim(AClave.NumeroFactura) = '') then
    raise EArgumentException.Create(SSubsanacionIdentidadInvalida);
end;

procedure TServicioSubsanacionCajaUniDAC.ComprobarEsquema;
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta(
    'SELECT COUNT(*) AS N FROM INFORMATION_SCHEMA.TABLES ' +
    'WHERE TABLE_SCHEMA = DATABASE() ' +
    'AND TABLE_NAME = ''fza_caja_subsanaciones''',
    Default(TClaveOperacionSubsanacionCaja));
  try
    oConsulta.Open;
    if oConsulta.FieldByName('N').AsInteger <> 1 then
      raise EInvalidOpException.Create(SSubsanacionEsquemaPendiente);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TServicioSubsanacionCajaUniDAC.LeerDatos(
  const AClave: TClaveOperacionSubsanacionCaja;
  ABloquear: Boolean): TDatosSubsanacionCaja;
begin
  Result := TDatosSubsanacionCaja.Create;
  try
    Result.Cabecera := LeerCopia('SELECT ' + CAMPOS_CABECERA +
      ' FROM fza_facturas WHERE SERIE_FAC = :SERIE ' +
      'AND NUMERO_FAC = :NUMERO AND CODIGO_EMP_FAC = :EMP ' +
      'AND CODIGO_ALM_FAC = :ALM AND CODIGO_CAJA_FAC = :CAJA ' +
      'AND NUMERO_OPERACION_FAC = :OPE', AClave, ABloquear);
    if Result.Cabecera.IsEmpty then
      raise EInvalidOpException.Create(SSubsanacionFacturaNoVigente);
    Result.Lineas := LeerCopia('SELECT ' + CAMPOS_LINEAS +
      ' FROM fza_facturas_lineas WHERE SERIE_FAC_FACLIN = :SERIE ' +
      'AND NUMERO_FAC_FACLIN = :NUMERO ORDER BY LINEA_FACLIN',
      AClave, ABloquear);
    Result.Operacion := LeerCopia(
      'SELECT ID_OPCAJA,TIPO_OPERACION_OPCAJA,IMPORTE_TOTAL_OPCAJA,' +
      'SERIE_FAC_OPCAJA,NUMERO_FAC_OPCAJA,FECHA_OPERACION_OPCAJA,' +
      'ID_DEPOSITO_OPCAJA,CODIGO_ARQUEO_OPCAJA,' +
      'ESTADO_DEVOLUCION_OPCAJA,IMPORTE_DEVUELTO_ACUM_OPCAJA,' +
      'INSTANTE_MODIF FROM fza_caja_operaciones WHERE ' +
      SQL_CLAVE_OPE + 'ORDER BY ID_OPCAJA', AClave, ABloquear);
    Result.Pagos := LeerCopia(
      'SELECT SERIE_OPERACION_PAGO,NUMERO_LINEA_PAGO,CODIGO_FP_CFP,' +
      'IMPORTE_ENTREGADO_PAGO,IMPORTE_CAMBIO_PAGO,REFERENCIA_FACPAG,' +
      'CODIGO_DIVISA_PAGO,RED_BLOCKCHAIN_PAGO,FACTOR_CAMBIO_PAGO,' +
      'IMPORTE_DIVISA_PAGO,NUMERO_LINEA_ORIGEN_PAGO,' +
      'TIPO_CORRECCION_PAGO,INSTANTE_MODIF ' +
      'FROM fza_caja_pagos WHERE ' + SQL_CLAVE_PAGO +
      'ORDER BY SERIE_OPERACION_PAGO,NUMERO_LINEA_PAGO',
      AClave, ABloquear);
    Result.PagosFactura := LeerCopia(
      'SELECT LINEA_FACPAG,TIPO_FACPAG,IMPORTE_FACPAG,' +
      'REFERENCIA_FACPAG,DESCRIPCION_FACPAG,ENTIDAD_FACPAG,' +
      'FECHA_FACPAG,INSTANTE_MODIF FROM fza_facturas_pagos ' +
      'WHERE SERIE_FAC_FACPAG = :SERIE AND NUMERO_FAC_FACPAG = :NUMERO ' +
      'ORDER BY LINEA_FACPAG', AClave, ABloquear);
    // Depósitos liquidados o anticipados en la venta: sólo se leen.
    Result.Depositos := LeerCopia(
      'SELECT ID_DEPOSITO_DEP,CODIGO_UNIDAD_DEP,ESTADO_DEP ' +
      'FROM fza_depositos_cliente WHERE ID_DEPOSITO_DEP IN (' +
      'SELECT ID_DEPOSITO_OPCAJA FROM fza_caja_operaciones WHERE ' +
      SQL_CLAVE_OPE + ') ORDER BY ID_DEPOSITO_DEP', AClave, False);
    LeerFormasConCambio(Result);
  except
    FreeAndNil(Result);
    raise;
  end;
end;

procedure TServicioSubsanacionCajaUniDAC.LeerFormasConCambio(
  ADatos: TDatosSubsanacionCaja);
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta(
    'SELECT CODIGO_FP_CFP FROM fza_caja_formas_pago ' +
    'WHERE COALESCE(ESDEVUELVE_CAMBIO_FORMA_PAGO_CFP, ''S'') = ''S''',
    Default(TClaveOperacionSubsanacionCaja));
  try
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      ADatos.FormasConCambio.AddOrSetValue(
        UpperCase(Trim(oConsulta.FieldByName(fforma).AsString)), True);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TServicioSubsanacionCajaUniDAC.ValidarCabecera(
  ADatos: TDatosSubsanacionCaja);
var
  oCabecera: TDataSet;
  sCliente: string;
begin
  oCabecera := ADatos.Cabecera;
  if oCabecera.FieldByName(
       'ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC').AsString = 'S' then
    raise EInvalidOpException.Create(SSubsanacionDatosFiscales);
  if EsSinVerifactu then
  begin
    // Sin VeriFactu no se valida la consolidación ni el registro fiscal.
    if (oCabecera.FieldByName('TIPO_FAC').AsString <> 'SIMPLIFICADA') or
       MatchText(oCabecera.FieldByName('FASE_FAC').AsString,
         [cFaseFacturaSinVerifactuAnulada, cFaseFacturaVerifactuAnulada,
          cFaseFacturaNoVerifactuAnulada, 'RECTIFICADA', 'CANCELADA']) then
      raise EInvalidOpException.Create(SSubsanacionFacturaNoVigente);
    Exit;
  end;
  if (oCabecera.FieldByName('ESCONSOLIDADA_FAC').AsString <> 'S') or
     (oCabecera.FieldByName('TIPO_FAC').AsString <> 'SIMPLIFICADA') or
     not MatchText(oCabecera.FieldByName('FASE_FAC').AsString,
       FasesRegistradas(FDependencias.ParametrosApp)) then
    raise EInvalidOpException.Create(SSubsanacionFacturaNoVigente);
  sCliente := oCabecera.FieldByName('CODIGO_CLI_FAC').AsString;
  if (oCabecera.FieldByName('RAZON_SOCIAL_EMPRESA_FAC').AsString = '') or
     ((sCliente <> '') and (sCliente <> '0') and
      (sCliente <> 'VENTA CONTADO') and
      (oCabecera.FieldByName('RAZON_SOCIAL_CLIENTE_FAC').AsString = '')) then
    raise EInvalidOpException.Create(SSubsanacionDatosFiscales);
end;

procedure TServicioSubsanacionCajaUniDAC.ValidarFiscal(
  const AClave: TClaveOperacionSubsanacionCaja);
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta(
    'SELECT c.ESTADO_FACCON FROM fza_facturas_consolidaciones c ' +
    'WHERE c.SERIE_FAC_FACCON = :SERIE ' +
    'AND c.NUMERO_FAC_FACCON = :NUMERO ' +
    'AND NOT EXISTS (SELECT 1 FROM fza_verifactu_cola q ' +
    'WHERE q.SERIE_FAC_VFCOLA = :SERIE ' +
    'AND q.NUMERO_FAC_VFCOLA = :NUMERO ' +
    'AND q.TIPO_OPERACION_VFCOLA IN ' +
    '(''ALTA'', ''ANULACION'', ''SUBSANACION'') ' +
    'AND (q.ESTADO_VFCOLA <> ''ENVIADA'' ' +
    'OR q.TIPO_OPERACION_VFCOLA = ''ANULACION'')) ' +
    'ORDER BY c.ID_FACCON DESC LIMIT 1', AClave);
  try
    oConsulta.Open;
    if oConsulta.IsEmpty or
       not MatchText(oConsulta.FieldByName('ESTADO_FACCON').AsString,
         EstadosRegistroAceptado(FDependencias.ParametrosApp)) then
      raise EInvalidOpException.Create(SSubsanacionRegistroNoAceptado);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TServicioSubsanacionCajaUniDAC.EsSinVerifactu: Boolean;
begin
  // El modo fiscal decide: con VeriFactu sólo se corrige lo enviado a la AEAT.
  Result := SinVerifactuActivo(FDependencias.ParametrosApp);
end;

procedure TServicioSubsanacionCajaUniDAC.ValidarVinculos(
  const AClave: TClaveOperacionSubsanacionCaja);
var
  oConsulta: TUniQuery;
begin
  // Los vales emitidos o canjeados no impiden subsanar: se conservan.
  // Sí lo impide una devolución posterior que haga referencia al ticket.
  oConsulta := Consulta(
    'SELECT 1 AS VINCULO FROM fza_recibos ' +
    'WHERE SERIE_FAC_REC = :SERIE AND NUMERO_FAC_REC = :NUMERO ' +
    'UNION ALL SELECT 1 FROM fza_caja_operaciones ' +
    'WHERE TIPO_OPERACION_OPCAJA = ''DV'' ' +
    'AND SERIE_REF_ORIGEN_OPCAJA = :SERIE ' +
    'AND NUMERO_REF_ORIGEN_OPCAJA = :NUMERO ' +
    'UNION ALL SELECT 1 FROM fza_facturas_relaciones ' +
    'WHERE SERIE_FAC_ORIGEN_FACREL = :SERIE ' +
    'AND NUMERO_FAC_ORIGEN_FACREL = :NUMERO', AClave);
  try
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      raise EInvalidOpException.Create(SSubsanacionOperacionCompleja);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TServicioSubsanacionCajaUniDAC.ValidarArqueo(
  ADatos: TDatosSubsanacionCaja;
  const AClave: TClaveOperacionSubsanacionCaja);
var
  oConsulta: TUniQuery;
  sBloqueo: string;
begin
  if ADatos.Operacion.FieldByName(
       'CODIGO_ARQUEO_OPCAJA').AsString <> '' then
    raise EInvalidOpException.Create(SSubsanacionArqueoCerrado);
  sBloqueo := '';
  if FConexion.InTransaction then
    sBloqueo := ' FOR UPDATE';
  oConsulta := Consulta(
    'SELECT CODIGO_ARQ FROM fza_caja_arqueos ' +
    'WHERE CODIGO_EMP_ARQ = :EMP AND CODIGO_ALM_ARQ = :ALM ' +
    'AND CODIGO_CAJA_ARQ = :CAJA AND FASE_ARQ = ''CERRADO'' ' +
    'AND FECHA_DESDE_ARQ <= :FECHA AND FECHA_HASTA_ARQ >= :FECHA' +
    sBloqueo, AClave);
  try
    oConsulta.ParamByName('FECHA').AsDateTime :=
      ADatos.Operacion.FieldByName('FECHA_OPERACION_OPCAJA').AsDateTime;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      raise EInvalidOpException.Create(SSubsanacionArqueoCerrado);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TServicioSubsanacionCajaUniDAC.ValidarPago(
  ADatos: TDatosSubsanacionCaja);
begin
  // Admite cualquier forma de pago, varios cobros y los de correcciones
  // anteriores; los vales y la deuda se conservan sin tocarlos.
  if ADatos.Pagos.IsEmpty then
    raise EInvalidOpException.Create(SSubsanacionPagoUnico);
end;

procedure TServicioSubsanacionCajaUniDAC.ValidarOperaciones(
  ADatos: TDatosSubsanacionCaja;
  const AClave: TClaveOperacionSubsanacionCaja);
var
  oOperacion: TDataSet;
  eFila: TFilaOperacionSubsanacion;
  iVentasNormales: Integer;
begin
  // Una venta del TPV puede dejar varias filas: la venta de las líneas
  // normales, una por prenda de depósito con su cierre y consumo de
  // anticipo, los anticipos que dejan deuda y los vales. Devoluciones y
  // cualquier otro movimiento quedan fuera.
  oOperacion := ADatos.Operacion;
  if oOperacion.IsEmpty then
    raise EInvalidOpException.Create(SSubsanacionOperacionCompleja);
  iVentasNormales := 0;
  ADatos.IdVentaNormal := 0;
  oOperacion.First;
  while not oOperacion.Eof do
  begin
    eFila := ClasificarFilaOperacion(oOperacion);
    if (eFila = fosOtra) or
       (oOperacion.FieldByName('SERIE_FAC_OPCAJA').AsString <>
         AClave.SerieFactura) or
       (oOperacion.FieldByName('NUMERO_FAC_OPCAJA').AsString <>
         AClave.NumeroFactura) or
       (oOperacion.FieldByName('IMPORTE_DEVUELTO_ACUM_OPCAJA').AsCurrency
         <> 0) then
      raise EInvalidOpException.Create(SSubsanacionOperacionCompleja);
    if eFila = fosVentaNormal then
    begin
      Inc(iVentasNormales);
      ADatos.IdVentaNormal := oOperacion.FieldByName('ID_OPCAJA').AsInteger;
    end;
    oOperacion.Next;
  end;
  oOperacion.First;
  if iVentasNormales > 1 then
    raise EInvalidOpException.Create(SSubsanacionOperacionCompleja);
end;

// Relaciona cada línea con su fila de caja: abonos a cuenta con el consumo
// de anticipo, anticipos con su depósito y prendas con su venta de depósito.
// Las líneas restantes suman la venta normal.
procedure TServicioSubsanacionCajaUniDAC.AnalizarLineas(
  ADatos: TDatosSubsanacionCaja);
var
  oLineas, oOperacion: TDataSet;
  oConsumos, oAnticipos: TList<Integer>;
  oConsumoDeposito: TDictionary<string, Currency>;
  oAsignadas: TDictionary<string, Boolean>;
  sArticulo, sLinea, sDeposito: string;
  dImporte, dVentaNormal, dNormales: Currency;
  iAbonos, iAnticipos: Integer;
  bEncontrada: Boolean;

  function ImporteFila(AId: Integer): Currency;
  begin
    if not oOperacion.Locate('ID_OPCAJA', AId, []) then
      raise EInvalidOpException.Create(SSubsanacionOperacionCompleja);
    Result := oOperacion.FieldByName(ftotalope).AsCurrency;
  end;

begin
  oLineas := ADatos.Lineas;
  oOperacion := ADatos.Operacion;
  ADatos.LineasFijas.Clear;
  ADatos.VentaDepositoLinea.Clear;
  ADatos.AnticipoLinea.Clear;
  oConsumos := TList<Integer>.Create;
  oAnticipos := TList<Integer>.Create;
  oConsumoDeposito := TDictionary<string, Currency>.Create;
  oAsignadas := TDictionary<string, Boolean>.Create;
  try
    dVentaNormal := 0;
    oOperacion.First;
    while not oOperacion.Eof do
    begin
      dImporte := oOperacion.FieldByName(ftotalope).AsCurrency;
      sDeposito := oOperacion.FieldByName('ID_DEPOSITO_OPCAJA').AsString;
      case ClasificarFilaOperacion(oOperacion) of
        fosVentaNormal:
          dVentaNormal := dImporte;
        fosConsumoAnticipo:
          begin
            oConsumos.Add(oOperacion.FieldByName('ID_OPCAJA').AsInteger);
            oConsumoDeposito.AddOrSetValue(sDeposito, -dImporte);
          end;
        // Un depósito nuevo sin anticipo graba la fila a cero sin línea.
        fosAnticipo:
          if dImporte <> 0 then
            oAnticipos.Add(oOperacion.FieldByName('ID_OPCAJA').AsInteger);
      end;
      oOperacion.Next;
    end;
    // Abonos a cuenta y anticipos, en el mismo orden en que se grabaron.
    iAbonos := 0;
    iAnticipos := 0;
    oLineas.First;
    while not oLineas.Eof do
    begin
      sLinea := oLineas.FieldByName('LINEA_FACLIN').AsString;
      sArticulo := oLineas.FieldByName('CODIGO_ART_FACLIN').AsString;
      dImporte := oLineas.FieldByName('TOTAL_FACLIN').AsCurrency;
      if SameText(sArticulo, ARTICULO_ABONO_CUENTA) then
      begin
        if (iAbonos >= oConsumos.Count) or
           (ImporteFila(oConsumos[iAbonos]) <> dImporte) then
          raise EInvalidOpException.Create(SSubsanacionOperacionCompleja);
        Inc(iAbonos);
        ADatos.LineasFijas.Add(sLinea, True);
      end
      else if SameText(sArticulo, ARTICULO_ANTICIPO) then
      begin
        if (iAnticipos >= oAnticipos.Count) or
           (ImporteFila(oAnticipos[iAnticipos]) <> dImporte) then
          raise EInvalidOpException.Create(SSubsanacionOperacionCompleja);
        Inc(iAnticipos);
        ADatos.LineasFijas.Add(sLinea, True);
      end;
      oLineas.Next;
    end;
    if (iAbonos <> oConsumos.Count) or (iAnticipos <> oAnticipos.Count) then
      raise EInvalidOpException.Create(SSubsanacionOperacionCompleja);
    // Cada venta de depósito, con la línea de su prenda (mismo SKU e importe).
    oOperacion.First;
    while not oOperacion.Eof do
    begin
      if ClasificarFilaOperacion(oOperacion) = fosVentaDeposito then
      begin
        sDeposito := oOperacion.FieldByName('ID_DEPOSITO_OPCAJA').AsString;
        dImporte := oOperacion.FieldByName(ftotalope).AsCurrency;
        if not ADatos.Depositos.Locate('ID_DEPOSITO_DEP', sDeposito, []) or
           (ADatos.Depositos.FieldByName('ESTADO_DEP').AsString <>
             'CERRADO') then
          raise EInvalidOpException.Create(SSubsanacionOperacionCompleja);
        bEncontrada := False;
        oLineas.First;
        while not oLineas.Eof and not bEncontrada do
        begin
          sLinea := oLineas.FieldByName('LINEA_FACLIN').AsString;
          bEncontrada := not ADatos.LineasFijas.ContainsKey(sLinea) and
            not oAsignadas.ContainsKey(sLinea) and
            (oLineas.FieldByName('CANTIDAD_FACLIN').AsFloat > 0) and
            SameText(oLineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString,
              ADatos.Depositos.FieldByName('CODIGO_UNIDAD_DEP').AsString) and
            (oLineas.FieldByName('TOTAL_FACLIN').AsCurrency = dImporte);
          if not bEncontrada then
            oLineas.Next;
        end;
        if not bEncontrada then
          raise EInvalidOpException.Create(SSubsanacionOperacionCompleja);
        oAsignadas.Add(sLinea, True);
        ADatos.VentaDepositoLinea.Add(sLinea,
          oOperacion.FieldByName('ID_OPCAJA').AsInteger);
        if not oConsumoDeposito.TryGetValue(sDeposito, dImporte) then
          dImporte := 0;
        ADatos.AnticipoLinea.Add(sLinea, dImporte);
      end;
      oOperacion.Next;
    end;
    oOperacion.First;
    // El resto son ventas normales: positivas y sumando su fila de caja.
    dNormales := 0;
    oLineas.First;
    while not oLineas.Eof do
    begin
      sLinea := oLineas.FieldByName('LINEA_FACLIN').AsString;
      if not ADatos.LineasFijas.ContainsKey(sLinea) and
         not oAsignadas.ContainsKey(sLinea) then
      begin
        if (oLineas.FieldByName('CANTIDAD_FACLIN').AsFloat < 0) or
           (oLineas.FieldByName('TOTAL_FACLIN').AsCurrency < 0) then
          raise EInvalidOpException.Create(SSubsanacionOperacionCompleja);
        dNormales := dNormales + oLineas.FieldByName('TOTAL_FACLIN').AsCurrency;
      end;
      oLineas.Next;
    end;
    oLineas.First;
    if (dNormales <> dVentaNormal) or
       ((dNormales <> 0) and (ADatos.IdVentaNormal = 0)) then
      raise EInvalidOpException.Create(SSubsanacionDescuadreOriginal);
  finally
    FreeAndNil(oAsignadas);
    FreeAndNil(oConsumoDeposito);
    FreeAndNil(oAnticipos);
    FreeAndNil(oConsumos);
  end;
end;

procedure TServicioSubsanacionCajaUniDAC.ValidarDatos(
  ADatos: TDatosSubsanacionCaja;
  const AClave: TClaveOperacionSubsanacionCaja);
var
  oOperacion: TDataSet;
  dTotal, dTotalFactura, dTotalOperacion: Currency;
begin
  ValidarCabecera(ADatos);
  ValidarOperaciones(ADatos, AClave);
  if not EsSinVerifactu then
    ValidarFiscal(AClave);
  ValidarVinculos(AClave);
  ValidarArqueo(ADatos, AClave);
  ValidarPago(ADatos);
  AnalizarLineas(ADatos);
  dTotal := ADatos.Cabecera.FieldByName(ftotal).AsCurrency;
  dTotalOperacion := 0;
  oOperacion := ADatos.Operacion;
  oOperacion.First;
  while not oOperacion.Eof do
  begin
    dTotalOperacion := dTotalOperacion + ImporteFiscalFila(oOperacion);
    oOperacion.Next;
  end;
  oOperacion.First;
  if (dTotal < 0) or
     (TotalSubsanacion(LeerImportesSubsanacion(ADatos.Lineas)) <> dTotal) or
     (dTotalOperacion <> dTotal) or
     (TotalCobros(DescontarCambioNoGrabado(LeerCobrosVigentes(ADatos.Pagos),
       dTotal, ADatos.FormasConCambio)) <> dTotal) then
    raise EInvalidOpException.Create(SSubsanacionDescuadreOriginal);
  dTotalFactura := 0;
  ADatos.PagosFactura.First;
  while not ADatos.PagosFactura.Eof do
  begin
    dTotalFactura := dTotalFactura +
      ADatos.PagosFactura.FieldByName('IMPORTE_FACPAG').AsCurrency;
    ADatos.PagosFactura.Next;
  end;
  ADatos.PagosFactura.First;
  if not ADatos.PagosFactura.IsEmpty and (dTotalFactura <> dTotal) then
    raise EInvalidOpException.Create(SSubsanacionDescuadreOriginal);
end;

function TServicioSubsanacionCajaUniDAC.CrearSnapshot(
  const AClave: TClaveOperacionSubsanacionCaja;
  ADatos: TDatosSubsanacionCaja): TOperacionSubsanacionCaja;
var
  i: Integer;
begin
  Result := Default(TOperacionSubsanacionCaja);
  Result.Clave := AClave;
  Result.FechaFactura := ADatos.Cabecera.FieldByName('FECHA_FAC').AsDateTime;
  Result.Lineas := LeerImportesSubsanacion(ADatos.Lineas);
  for i := 0 to High(Result.Lineas) do
  begin
    Result.Lineas[i].Fija :=
      ADatos.LineasFijas.ContainsKey(Result.Lineas[i].Numero);
    Result.Lineas[i].CantidadFija :=
      ADatos.VentaDepositoLinea.ContainsKey(Result.Lineas[i].Numero);
  end;
  Result.Total := ADatos.Cabecera.FieldByName(ftotal).AsCurrency;
  Result.Pagos := DescontarCambioNoGrabado(LeerCobrosVigentes(ADatos.Pagos),
    Result.Total, ADatos.FormasConCambio);
  Result.Version := THashSHA2.GetHashString(ADatos.ComoJson);
end;

function TServicioSubsanacionCajaUniDAC.Cargar(
  const AClave: TClaveOperacionSubsanacionCaja): TOperacionSubsanacionCaja;
var
  oDatos: TDatosSubsanacionCaja;
begin
  ExigirPermiso;
  ValidarClave(AClave);
  ComprobarEsquema;
  oDatos := LeerDatos(AClave, False);
  try
    ValidarDatos(oDatos, AClave);
    Result := CrearSnapshot(AClave, oDatos);
  finally
    FreeAndNil(oDatos);
  end;
end;

procedure TServicioSubsanacionCajaUniDAC.ValidarSolicitud(
  const ASolicitud: TSolicitudSubsanacionCaja;
  const AActual: TOperacionSubsanacionCaja;
  ADatos: TDatosSubsanacionCaja);
var
  oLineas: TDictionary<string, TLineaSubsanacionCaja>;
  oLinea, oActual: TLineaSubsanacionCaja;
  bCambio: Boolean;
  dAnticipo: Currency;
begin
  if (Trim(ASolicitud.Motivo) = '') or
     (Length(ASolicitud.Motivo) > 500) then
    raise EArgumentException.Create(SSubsanacionMotivoObligatorio);
  if (ASolicitud.Original.Version = '') or
     (ASolicitud.Original.Version <> AActual.Version) then
    raise EInvalidOpException.Create(SSubsanacionConflicto);
  ValidarImportesSubsanacion(ASolicitud.Lineas);
  if Length(ASolicitud.Lineas) <> Length(AActual.Lineas) then
    raise EInvalidOpException.Create(SSubsanacionConflicto);
  if TotalSubsanacion(ASolicitud.Lineas) < 0 then
    raise EArgumentException.Create(SSubsanacionTotalInvalido);
  ValidarCobrosSolicitud(ASolicitud.Pagos,
    TotalSubsanacion(ASolicitud.Lineas));
  ValidarCobrosFijos(AActual.Pagos, ASolicitud.Pagos);
  bCambio := CobrosDistintos(AActual.Pagos, ASolicitud.Pagos);
  oLineas := TDictionary<string, TLineaSubsanacionCaja>.Create;
  try
    for oActual in AActual.Lineas do
      oLineas.Add(oActual.Numero, oActual);
    for oLinea in ASolicitud.Lineas do
    begin
      if not oLineas.TryGetValue(oLinea.Numero, oActual) then
        raise EInvalidOpException.Create(SSubsanacionConflicto);
      if (oLinea.CantidadOriginal <> oActual.CantidadOriginal) or
         (oLinea.ImporteOriginal <> oActual.ImporteOriginal) or
         (oLinea.PrecioSalidaOriginal <> oActual.PrecioSalidaOriginal) then
        raise EInvalidOpException.Create(SSubsanacionConflicto);
      // El abono a cuenta y el anticipo ya se declararon en su ticket.
      if ADatos.LineasFijas.ContainsKey(oLinea.Numero) and
         LineaSubsanacionModificada(oLinea) then
        raise EArgumentException.CreateFmt(SSubsanacionLineaFija,
          [oLinea.Numero]);
      // La prenda de un depósito conserva las unidades del depósito; se
      // decide con los datos leídos, no con la marca de la solicitud.
      if oActual.CantidadFija and CantidadSubsanacionModificada(oLinea) then
        raise EArgumentException.CreateFmt(
          SSubsanacionCantidadPrendaDeposito, [oLinea.Numero]);
      // La prenda de un depósito no puede bajar del anticipo ya consumido.
      if ADatos.AnticipoLinea.TryGetValue(oLinea.Numero, dAnticipo) and
         (oLinea.Importe < dAnticipo) then
        raise EArgumentException.CreateFmt(SSubsanacionPrendaBajoAnticipo,
          [oLinea.Numero, CurrToStrF(dAnticipo, ffCurrency, 2)]);
      bCambio := bCambio or LineaSubsanacionModificada(oLinea);
      oLineas.Remove(oLinea.Numero);
    end;
  finally
    FreeAndNil(oLineas);
  end;
  if not bCambio then
    raise EArgumentException.Create(SSubsanacionSinCambios);
end;

procedure TServicioSubsanacionCajaUniDAC.ValidarMedio(
  const ASolicitud: TSolicitudSubsanacionCaja);
var
  oConsulta: TUniQuery;
  oPago: TPagoSubsanacionCaja;
begin
  oConsulta := Consulta(
    'SELECT CODIGO_FP_CFP,ESREQ_REFERENCIA_FORMA_PAGO_CFP ' +
    'FROM fza_caja_formas_pago WHERE ' + SQL_MEDIO_ADMITIDO +
    'AND ESACTIVO_FORMA_PAGO_CFP = ''S'' AND CODIGO_FP_CFP = :FP ' +
    'FOR UPDATE', ASolicitud.Original.Clave);
  try
    for oPago in ASolicitud.Pagos do
    begin
      // Los vales y la deuda llegan tal cual (ValidarCobrosFijos).
      if EsCobroFijo(oPago.FormaPago) then
        Continue;
      oConsulta.Close;
      oConsulta.ParamByName('FP').AsString := oPago.FormaPago;
      oConsulta.Open;
      if oConsulta.IsEmpty then
        raise EArgumentException.Create(SSubsanacionMedioInvalido);
      if (oConsulta.FieldByName('ESREQ_REFERENCIA_FORMA_PAGO_CFP').AsString
          = 'S') and (Trim(oPago.Referencia) = '') then
        raise EArgumentException.Create(SSubsanacionReferenciaInvalida);
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TServicioSubsanacionCajaUniDAC.Recalcular(
  ADatos: TDatosSubsanacionCaja;
  const ASolicitud: TSolicitudSubsanacionCaja);
var
  oTotales: TFacturaTotales;
  oOriginales: TClientDataSet;
begin
  oOriginales := TClientDataSet.Create(nil);
  oTotales := nil;
  try
    oOriginales.Data := ADatos.Lineas.Data;
    AplicarImportesSubsanacion(ADatos.Lineas, ASolicitud.Lineas);
    oTotales := TFacturaTotales.Create(nil, nil,
      ADatos.Cabecera, ADatos.Lineas, nil, FDependencias.RegistroLog);
    if not oTotales.ProcesarFacturaCompleta then
      raise EInvalidOpException.CreateFmt(SSubsanacionCalculoInvalido,
        [oTotales.MensajeError]);
    if ADatos.Cabecera.State in dsEditModes then
      ADatos.Cabecera.Post;
    if ADatos.Cabecera.FieldByName(ftotal).AsCurrency <>
       TotalSubsanacion(ASolicitud.Lineas) then
      raise EInvalidOpException.CreateFmt(SSubsanacionCalculoInvalido,
        [SSubsanacionTotalFiscalDistinto]);
    ValidarLineasCalculadas(ADatos, oOriginales, ASolicitud.Lineas);
    ADatos.Lineas.First;
  finally
    FreeAndNil(oTotales);
    FreeAndNil(oOriginales);
  end;
end;

procedure TServicioSubsanacionCajaUniDAC.ValidarLineasCalculadas(
  ADatos: TDatosSubsanacionCaja; AOriginales: TDataSet;
  const ALineas: TLineasSubsanacionCaja);
var
  oLinea: TLineaSubsanacionCaja;
  sCampo: string;
begin
  for oLinea in ALineas do
  begin
    if not AOriginales.Locate('LINEA_FACLIN', oLinea.Numero, []) or
       not ADatos.Lineas.Locate('LINEA_FACLIN', oLinea.Numero, []) then
      raise EInvalidOpException.Create(SSubsanacionConflicto);
    if (ADatos.Lineas.FieldByName('TIPO_IVA_ARTICULO_FACLIN').AsString <>
          AOriginales.FieldByName('TIPO_IVA_ARTICULO_FACLIN').AsString) or
       (ADatos.Lineas.FieldByName('PORCENTAJE_IVA_FACLIN').AsCurrency <>
          AOriginales.FieldByName('PORCENTAJE_IVA_FACLIN').AsCurrency) then
      raise EInvalidOpException.Create(SSubsanacionDatosFiscales);
    if ADatos.Lineas.FieldByName('TOTAL_FACLIN').AsCurrency <>
       oLinea.Importe then
      raise EInvalidOpException.CreateFmt(SSubsanacionCalculoInvalido,
        [SSubsanacionTotalFiscalDistinto]);
    if not SameValue(ADatos.Lineas.FieldByName('CANTIDAD_FACLIN').AsFloat,
         oLinea.Cantidad, 0.000001) then
      raise EInvalidOpException.CreateFmt(SSubsanacionCalculoInvalido,
        [Format(SSubsanacionCantidadNoAplicada, [oLinea.Numero])]);
    if not LineaSubsanacionModificada(oLinea) then
      for sCampo in CAMPOS_GUARDADO_LINEA.Split([',']) do
        if ADatos.Lineas.FieldByName(sCampo).AsCurrency <>
           AOriginales.FieldByName(sCampo).AsCurrency then
          raise EInvalidOpException.CreateFmt(SSubsanacionCalculoInvalido,
            [SSubsanacionLineaIntactaDistinta]);
  end;
end;

procedure TServicioSubsanacionCajaUniDAC.ActualizarCampos(
  const ATabla, ACondicion, ACampos: string; AOrigen: TDataSet;
  const AClave: TClaveOperacionSubsanacionCaja);
var
  oConsulta: TUniQuery;
  sCampo, sSql: string;
begin
  sSql := 'UPDATE ' + ATabla + ' SET ';
  for sCampo in ACampos.Split([',']) do
    sSql := sSql + sCampo + ' = :' + sCampo + ',';
  sSql := sSql + 'INSTANTE_MODIF = NOW(),USUARIO_MODIF = :USUARIO ' +
    'WHERE ' + ACondicion;
  oConsulta := Consulta(sSql, AClave);
  try
    for sCampo in ACampos.Split([',']) do
      oConsulta.ParamByName(sCampo).Value := AOrigen.FieldByName(sCampo).Value;
    if Assigned(oConsulta.Params.FindParam('LINEA')) then
      oConsulta.ParamByName('LINEA').AsString :=
        AOrigen.FieldByName('LINEA_FACLIN').AsString;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TServicioSubsanacionCajaUniDAC.GuardarImportes(
  ADatos: TDatosSubsanacionCaja;
  const ASolicitud: TSolicitudSubsanacionCaja);
var
  oLinea: TLineaSubsanacionCaja;
  oClave: TClaveOperacionSubsanacionCaja;
begin
  oClave := ASolicitud.Original.Clave;
  for oLinea in ASolicitud.Lineas do
  begin
    if LineaSubsanacionModificada(oLinea) then
    begin
      if not ADatos.Lineas.Locate('LINEA_FACLIN', oLinea.Numero, []) then
        raise EInvalidOpException.Create(SSubsanacionConflicto);
      ActualizarCampos('fza_facturas_lineas',
        'SERIE_FAC_FACLIN = :SERIE AND NUMERO_FAC_FACLIN = :NUMERO ' +
        'AND LINEA_FACLIN = :LINEA',
        CAMPOS_GUARDADO_LINEA, ADatos.Lineas, oClave);
    end;
  end;
  ActualizarCampos('fza_facturas',
    'SERIE_FAC = :SERIE AND NUMERO_FAC = :NUMERO',
    CAMPOS_TOTALES, ADatos.Cabecera, oClave);
  GuardarOperacionesVenta(ADatos, ASolicitud);
end;

function TServicioSubsanacionCajaUniDAC.LeerMovimientosVenta(
  const AClave: TClaveOperacionSubsanacionCaja): TClientDataSet;
begin
  Result := LeerCopia('SELECT ' + CAMPOS_MOVIMIENTO +
    ' FROM fza_movimientos_almacen WHERE TIPO_DOC_MOV = ''' +
    TIPO_DOC_MOVIMIENTO_VENTA + ''' AND SERIE_DOC_MOV = :SERIE ' +
    'AND NUMERO_DOC_MOV = :NUMERO ORDER BY NUMERO_MOV', AClave, True);
end;

// Cada línea con unidades corregidas debe conservar su salida de stock con
// las unidades vendidas; un ticket con movimientos anulados se deja estar.
procedure TServicioSubsanacionCajaUniDAC.ValidarMovimientosVenta(
  AMovimientos: TDataSet;
  ACorregidas: TDictionary<string, TLineaSubsanacionCaja>);
var
  oPar: TPair<string, TLineaSubsanacionCaja>;
begin
  AMovimientos.First;
  while not AMovimientos.Eof do
  begin
    if AMovimientos.FieldByName('ESACTIVO_MOV').AsString <> 'S' then
      raise EInvalidOpException.Create(SSubsanacionStockInactivo);
    AMovimientos.Next;
  end;
  for oPar in ACorregidas do
  begin
    if not AMovimientos.Locate('NUMERO_MOV', oPar.Key, []) or
       (AMovimientos.FieldByName('TIPO_MOV').AsString <> 'S') or
       not SameValue(AMovimientos.FieldByName('CANTIDAD_MOV').AsFloat,
         oPar.Value.CantidadOriginal, 0.000001) then
      raise EInvalidOpException.CreateFmt(SSubsanacionStockInconsistente,
        [oPar.Value.Numero]);
  end;
  AMovimientos.First;
end;

procedure TServicioSubsanacionCajaUniDAC.BorrarMovimientosVenta(
  const AClave: TClaveOperacionSubsanacionCaja);
var
  oConsulta: TUniQuery;
begin
  // El mismo procedimiento que la anulación: retira el stock y los
  // acumulados de los movimientos del ticket y recalcula desde su fecha.
  oConsulta := Consulta(
    'CALL PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE_DOC(:TIPO, :SERIE, :NUMERO)',
    AClave);
  try
    oConsulta.ParamByName('TIPO').AsString := TIPO_DOC_MOVIMIENTO_VENTA;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

// Vuelve a dar de alta cada salida con su mismo número, fecha y datos,
// cambiando sólo las unidades corregidas, por el procedimiento que mantiene
// el stock y sus acumulados (igual que la venta en caja).
procedure TServicioSubsanacionCajaUniDAC.ReinsertarMovimientosVenta(
  AMovimientos: TDataSet;
  ACorregidas: TDictionary<string, TLineaSubsanacionCaja>;
  const AClave: TClaveOperacionSubsanacionCaja);
var
  oAlta: TUniStoredProc;
  oFecha: TUniQuery;
  oLinea: TLineaSubsanacionCaja;
  sNumero: string;
  dCantidad: Double;
  procedure ParametroTexto(const ANombre, ACampo: string);
  begin
    oAlta.ParamByName(ANombre).AsString :=
      AMovimientos.FieldByName(ACampo).AsString;
  end;
begin
  oFecha := nil;
  oAlta := TUniStoredProc.Create(nil);
  try
    oAlta.Connection := FConexion;
    oAlta.StoredProcName := 'PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT';
    oAlta.Prepare;
    oFecha := TUniQuery.Create(nil);
    oFecha.Connection := FConexion;
    oFecha.SQL.Text :=
      'UPDATE fza_movimientos_almacen SET FECHA_MOV = :FECHA ' +
      'WHERE NUMERO_MOV = :NUMMOV';
    AMovimientos.First;
    while not AMovimientos.Eof do
    begin
      sNumero := AMovimientos.FieldByName('NUMERO_MOV').AsString;
      dCantidad := AMovimientos.FieldByName('CANTIDAD_MOV').AsFloat;
      if ACorregidas.TryGetValue(sNumero, oLinea) then
        dCantidad := oLinea.Cantidad;
      oAlta.ParamByName('p_NUMERO_MOV').AsString := sNumero;
      oAlta.ParamByName('p_TIPO_DOC_MOV').AsString :=
        TIPO_DOC_MOVIMIENTO_VENTA;
      oAlta.ParamByName('p_SERIE_DOC_MOV').AsString := AClave.SerieFactura;
      oAlta.ParamByName('p_NRO_DOC_MOV').AsString := AClave.NumeroFactura;
      ParametroTexto('p_LINEA_MOV', 'LINEA_MOV');
      ParametroTexto('p_CODIGO_EMPRESA_MOV', 'CODIGO_EMP_MOV');
      ParametroTexto('p_CODIGO_ALMACEN_MOV', 'CODIGO_ALM_MOV');
      if Trim(AMovimientos.FieldByName('CODIGO_ALM_CONTRA_MOV').AsString)
         = '' then
        oAlta.ParamByName('p_CODIGO_ALMACEN_CONTRA_MOV').Clear
      else
        ParametroTexto('p_CODIGO_ALMACEN_CONTRA_MOV', 'CODIGO_ALM_CONTRA_MOV');
      ParametroTexto('p_CODIGO_UNIDAD_MOV', 'CODIGO_UNIDAD_MOV');
      ParametroTexto('p_TIPO_MOVIMIENTO_MOV', 'TIPO_MOV');
      oAlta.ParamByName('p_CANTIDAD_MOV').AsFloat := Abs(dCantidad);
      oAlta.ParamByName('p_PRECIO_MEDIO_MOV').AsCurrency :=
        AMovimientos.FieldByName('PRECIO_MEDIO_MOV').AsCurrency;
      oAlta.ParamByName('p_TOTAL_COSTE_MOV').AsCurrency :=
        AMovimientos.FieldByName('PRECIO_MEDIO_MOV').AsCurrency *
        Abs(dCantidad);
      oAlta.ParamByName('p_USUARIO').AsString := FDependencias.Usuario;
      ParametroTexto('p_ALMACEN_DOC', 'CODIGO_ALM_DOC_MOV');
      ParametroTexto('p_NUMOP_DOC', 'NUMERO_OPERACION_DOC_MOV');
      ParametroTexto('p_CODIGO_CAJA_DOC_MOV', 'CODIGO_CAJA_DOC_MOV');
      ParametroTexto('p_CODCLIENTE', 'CODIGO_CLI_MOV');
      ParametroTexto('p_CODARTICULO', 'CODIGO_ART_MOV');
      oAlta.Execute;
      // El alta fecha el movimiento con NOW(): se devuelve a su fecha para
      // que el recálculo cronológico lo sitúe donde estaba.
      if not AMovimientos.FieldByName('FECHA_MOV').IsNull then
      begin
        oFecha.ParamByName('FECHA').AsDateTime :=
          AMovimientos.FieldByName('FECHA_MOV').AsDateTime;
        oFecha.ParamByName('NUMMOV').AsString := sNumero;
        oFecha.Execute;
      end;
      AMovimientos.Next;
    end;
  finally
    FreeAndNil(oFecha);
    FreeAndNil(oAlta);
  end;
end;

// Las unidades corregidas se reflejan en el stock regenerando las salidas
// del ticket, sólo cuando cambia alguna línea con movimiento. Devuelve los
// movimientos regenerados.
function TServicioSubsanacionCajaUniDAC.RegenerarMovimientosStock(
  ADatos: TDatosSubsanacionCaja;
  const ASolicitud: TSolicitudSubsanacionCaja): Integer;
var
  oCorregidas: TDictionary<string, TLineaSubsanacionCaja>;
  oMovimientos: TClientDataSet;
  oLinea: TLineaSubsanacionCaja;
  sMovimiento: string;
begin
  Result := 0;
  oCorregidas := TDictionary<string, TLineaSubsanacionCaja>.Create;
  try
    for oLinea in ASolicitud.Lineas do
      if CantidadSubsanacionModificada(oLinea) then
      begin
        if not ADatos.Lineas.Locate('LINEA_FACLIN', oLinea.Numero, []) then
          raise EInvalidOpException.Create(SSubsanacionConflicto);
        // Sin movimiento (servicios o caja sin stock) no hay nada que
        // regenerar.
        sMovimiento := Trim(
          ADatos.Lineas.FieldByName('NUMERO_MOV_FACLIN').AsString);
        if sMovimiento <> '' then
        begin
          if oCorregidas.ContainsKey(sMovimiento) then
            raise EInvalidOpException.CreateFmt(
              SSubsanacionStockInconsistente, [oLinea.Numero]);
          oCorregidas.Add(sMovimiento, oLinea);
        end;
      end;
    if oCorregidas.Count > 0 then
    begin
      oMovimientos := LeerMovimientosVenta(ASolicitud.Original.Clave);
      try
        ValidarMovimientosVenta(oMovimientos, oCorregidas);
        BorrarMovimientosVenta(ASolicitud.Original.Clave);
        ReinsertarMovimientosVenta(oMovimientos, oCorregidas,
          ASolicitud.Original.Clave);
        Result := oMovimientos.RecordCount;
      finally
        FreeAndNil(oMovimientos);
      end;
      // Recálculo cronológico de stock y PMP desde la fecha del ticket; va
      // a la cola del lote si el usuario aplaza los recálculos.
      EncolarORecalcularMovimientosDocumento(FConexion,
        TIPO_DOC_MOVIMIENTO_VENTA, ASolicitud.Original.Clave.SerieFactura,
        ASolicitud.Original.Clave.NumeroFactura,
        FormatearMensajeDocumentos(
          CrearFormatoDocumentoLecturas(FConexion).LeerFormatoEmpresa(
            ASolicitud.Original.Clave.Empresa),
          SSubsanacionMotivoRecalculoStock,
          [ASolicitud.Original.Clave.SerieFactura,
          ASolicitud.Original.Clave.NumeroFactura]),
        FDependencias.Usuario);
    end;
  finally
    FreeAndNil(oCorregidas);
  end;
end;

procedure TServicioSubsanacionCajaUniDAC.GuardarOperacionesVenta(
  ADatos: TDatosSubsanacionCaja;
  const ASolicitud: TSolicitudSubsanacionCaja);
var
  oImportes: TDictionary<Integer, Currency>;
  oLinea: TLineaSubsanacionCaja;
  oPar: TPair<Integer, Currency>;
  oConsulta: TUniQuery;
  iId: Integer;
  dNormal: Currency;
begin
  // Cada fila de venta toma el importe de sus líneas: la de la prenda de
  // depósito, el de su línea; la venta normal, la suma del resto. El
  // cierre del depósito, el consumo de anticipo, los anticipos y los vales
  // no cambian.
  oImportes := TDictionary<Integer, Currency>.Create;
  try
    dNormal := 0;
    for oLinea in ASolicitud.Lineas do
    begin
      if ADatos.VentaDepositoLinea.TryGetValue(oLinea.Numero, iId) then
        oImportes.Add(iId, oLinea.Importe)
      else if not ADatos.LineasFijas.ContainsKey(oLinea.Numero) then
        dNormal := dNormal + oLinea.Importe;
    end;
    if ADatos.IdVentaNormal <> 0 then
      oImportes.Add(ADatos.IdVentaNormal, dNormal)
    else if dNormal <> 0 then
      raise EInvalidOpException.Create(SSubsanacionConflicto);
    oConsulta := Consulta(
      'UPDATE fza_caja_operaciones SET IMPORTE_TOTAL_OPCAJA = :IMPORTE,' +
      'INSTANTE_MODIF = NOW(),USUARIO_MODIF = :USUARIO ' +
      'WHERE ID_OPCAJA = :ID AND ' + SQL_CLAVE_OPE,
      ASolicitud.Original.Clave);
    try
      for oPar in oImportes do
      begin
        if not ADatos.Operacion.Locate('ID_OPCAJA', oPar.Key, []) then
          raise EInvalidOpException.Create(SSubsanacionConflicto);
        if ADatos.Operacion.FieldByName(ftotalope).AsCurrency <>
           oPar.Value then
        begin
          oConsulta.ParamByName('ID').AsInteger := oPar.Key;
          oConsulta.ParamByName('IMPORTE').AsCurrency := oPar.Value;
          oConsulta.Execute;
          if oConsulta.RowsAffected <> 1 then
            raise EInvalidOpException.Create(SSubsanacionConflicto);
        end;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  finally
    FreeAndNil(oImportes);
  end;
end;

procedure TServicioSubsanacionCajaUniDAC.InsertarCompensacion(
  const AClave: TClaveOperacionSubsanacionCaja; const ASerie: string;
  AOrigen, ALinea: Integer; const AObservacion: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta(
    'INSERT INTO fza_caja_pagos (CODIGO_EMP_PAGO,CODIGO_ALM_PAGO,' +
    'CODIGO_CAJA_PAGO,SERIE_OPERACION_PAGO,NUMERO_OPERACION_PAGO,' +
    'NUMERO_LINEA_PAGO,CODIGO_FP_CFP,CODIGO_DIVISA_PAGO,' +
    'RED_BLOCKCHAIN_PAGO,FACTOR_CAMBIO_PAGO,IMPORTE_DIVISA_PAGO,' +
    'IMPORTE_ENTREGADO_PAGO,IMPORTE_CAMBIO_PAGO,REFERENCIA_FACPAG,' +
    'OBSERVACIONES_PAGO,INSTANTE_ALTA,INSTANTE_MODIF,USUARIO_ALTA,' +
    'NUMERO_LINEA_ORIGEN_PAGO,TIPO_CORRECCION_PAGO) ' +
    'SELECT CODIGO_EMP_PAGO,CODIGO_ALM_PAGO,CODIGO_CAJA_PAGO,' +
    'SERIE_OPERACION_PAGO,NUMERO_OPERACION_PAGO,:LINEA,CODIGO_FP_CFP,' +
    'CODIGO_DIVISA_PAGO,RED_BLOCKCHAIN_PAGO,FACTOR_CAMBIO_PAGO,' +
    '-IMPORTE_DIVISA_PAGO,-IMPORTE_ENTREGADO_PAGO,-IMPORTE_CAMBIO_PAGO,' +
    'REFERENCIA_FACPAG,:OBS,NOW(),NOW(),:USUARIO,NUMERO_LINEA_PAGO,''N'' ' +
    'FROM fza_caja_pagos WHERE ' + SQL_CLAVE_PAGO +
    'AND SERIE_OPERACION_PAGO = :SERIEP AND NUMERO_LINEA_PAGO = :ORIGEN',
    AClave);
  try
    oConsulta.ParamByName('SERIEP').AsString := ASerie;
    oConsulta.ParamByName('ORIGEN').AsInteger := AOrigen;
    oConsulta.ParamByName('LINEA').AsInteger := ALinea;
    oConsulta.ParamByName('OBS').AsString := AObservacion;
    oConsulta.Execute;
    if oConsulta.RowsAffected <> 1 then
      raise EInvalidOpException.Create(SSubsanacionConflicto);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TServicioSubsanacionCajaUniDAC.InsertarPago(
  const AClave: TClaveOperacionSubsanacionCaja; const ASerie: string;
  ALinea: Integer; const APago: TPagoSubsanacionCaja;
  const AObservacion: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta(
    'INSERT INTO fza_caja_pagos (CODIGO_EMP_PAGO,CODIGO_ALM_PAGO,' +
    'CODIGO_CAJA_PAGO,SERIE_OPERACION_PAGO,NUMERO_OPERACION_PAGO,' +
    'NUMERO_LINEA_PAGO,CODIGO_FP_CFP,CODIGO_DIVISA_PAGO,' +
    'RED_BLOCKCHAIN_PAGO,FACTOR_CAMBIO_PAGO,IMPORTE_DIVISA_PAGO,' +
    'IMPORTE_ENTREGADO_PAGO,IMPORTE_CAMBIO_PAGO,REFERENCIA_FACPAG,' +
    'OBSERVACIONES_PAGO,INSTANTE_ALTA,INSTANTE_MODIF,USUARIO_ALTA,' +
    'NUMERO_LINEA_ORIGEN_PAGO,TIPO_CORRECCION_PAGO) VALUES (' +
    ':EMP,:ALM,:CAJA,:SERIEP,:OPE,:LINEA,:FP,:DIVISA,NULLIF(:RED, ''''),' +
    ':FACTOR,:IMPDIVISA,:IMPORTE,0,' +
    'NULLIF(:REF, ''''),:OBS,NOW(),NOW(),:USUARIO,NULL,''P'')', AClave);
  try
    oConsulta.ParamByName('SERIEP').AsString := ASerie;
    oConsulta.ParamByName('LINEA').AsInteger := ALinea;
    oConsulta.ParamByName('FP').AsString := APago.FormaPago;
    oConsulta.ParamByName('DIVISA').AsString := DivisaCobro(APago);
    oConsulta.ParamByName('RED').AsString := Trim(APago.RedBlockchain);
    if APago.FactorCambio > 0 then
      oConsulta.ParamByName('FACTOR').AsFloat := APago.FactorCambio
    else
      oConsulta.ParamByName('FACTOR').AsFloat := 1;
    oConsulta.ParamByName('IMPDIVISA').AsFloat := APago.ImporteDivisa;
    oConsulta.ParamByName('IMPORTE').AsCurrency := APago.Importe;
    oConsulta.ParamByName('REF').AsString := Trim(APago.Referencia);
    oConsulta.ParamByName('OBS').AsString := AObservacion;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TServicioSubsanacionCajaUniDAC.GuardarCobro(
  ADatos: TDatosSubsanacionCaja;
  const ASolicitud: TSolicitudSubsanacionCaja);
var
  oCompensados: TDictionary<string, Boolean>;
  oUltimas: TDictionary<string, Integer>;
  oPagos: TDataSet;
  oPago: TPagoSubsanacionCaja;
  sSerie, sSerieNueva, sObservacion: string;
  iLinea: Integer;
begin
  // Como la corrección de forma de pago: sólo si cambia el cobro, se
  // compensan en negativo los cobros vigentes y se añaden los nuevos.
  if not CobrosDistintos(ASolicitud.Original.Pagos, ASolicitud.Pagos) then
    Exit;
  sObservacion := Copy(Format(SSubsanacionObservacionPago,
    [Trim(ASolicitud.Motivo)]), 1, 255);
  oPagos := ADatos.Pagos;
  oCompensados := LeerCobrosCompensados(oPagos);
  oUltimas := TDictionary<string, Integer>.Create;
  try
    sSerieNueva := '';
    while not oPagos.Eof do
    begin
      sSerie := oPagos.FieldByName('SERIE_OPERACION_PAGO').AsString;
      if not oUltimas.TryGetValue(sSerie, iLinea) then
        iLinea := 0;
      oUltimas.AddOrSetValue(sSerie, Max(iLinea,
        oPagos.FieldByName('NUMERO_LINEA_PAGO').AsInteger));
      if (sSerieNueva = '') and EsCobroVigente(oPagos, oCompensados) then
        sSerieNueva := sSerie;
      oPagos.Next;
    end;
    if sSerieNueva = '' then
      raise EInvalidOpException.Create(SSubsanacionConflicto);
    oPagos.First;
    while not oPagos.Eof do
    begin
      // Vales y deuda siguen vigentes: no se compensan.
      if EsCobroVigente(oPagos, oCompensados) and
         not EsCobroFijo(oPagos.FieldByName(fforma).AsString) then
      begin
        sSerie := oPagos.FieldByName('SERIE_OPERACION_PAGO').AsString;
        iLinea := oUltimas[sSerie] + 1;
        oUltimas[sSerie] := iLinea;
        InsertarCompensacion(ASolicitud.Original.Clave, sSerie,
          oPagos.FieldByName('NUMERO_LINEA_PAGO').AsInteger, iLinea,
          sObservacion);
      end;
      oPagos.Next;
    end;
    oPagos.First;
    for oPago in ASolicitud.Pagos do
    begin
      if EsCobroFijo(oPago.FormaPago) then
        Continue;
      iLinea := oUltimas[sSerieNueva] + 1;
      oUltimas[sSerieNueva] := iLinea;
      InsertarPago(ASolicitud.Original.Clave, sSerieNueva, iLinea, oPago,
        sObservacion);
    end;
  finally
    FreeAndNil(oUltimas);
    FreeAndNil(oCompensados);
  end;
  if not ADatos.PagosFactura.IsEmpty then
    GuardarPagosFactura(ADatos, ASolicitud);
end;

procedure TServicioSubsanacionCajaUniDAC.GuardarPagosFactura(
  ADatos: TDatosSubsanacionCaja;
  const ASolicitud: TSolicitudSubsanacionCaja);
var
  oConsulta: TUniQuery;
  oPago: TPagoSubsanacionCaja;
  dtFecha: TDateTime;
  iLinea: Integer;
begin
  // El detalle fiscal de cobros refleja los cobros vigentes tras subsanar.
  ADatos.PagosFactura.First;
  dtFecha := Now;
  if not ADatos.PagosFactura.FieldByName('FECHA_FACPAG').IsNull then
    dtFecha := ADatos.PagosFactura.FieldByName('FECHA_FACPAG').AsDateTime;
  oConsulta := Consulta(
    'DELETE FROM fza_facturas_pagos WHERE SERIE_FAC_FACPAG = :SERIE ' +
    'AND NUMERO_FAC_FACPAG = :NUMERO', ASolicitud.Original.Clave);
  try
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
  oConsulta := Consulta(
    'INSERT INTO fza_facturas_pagos (SERIE_FAC_FACPAG,NUMERO_FAC_FACPAG,' +
    'LINEA_FACPAG,TIPO_FACPAG,IMPORTE_FACPAG,REFERENCIA_FACPAG,' +
    'DESCRIPCION_FACPAG,ENTIDAD_FACPAG,FECHA_FACPAG,INSTANTE_ALTA,' +
    'USUARIO_ALTA,USUARIO_MODIF) VALUES (:SERIE,:NUMERO,:LINEAP,' +
    ':FP,:IMPORTE,NULLIF(:REF, ''''),' +
    // Los vales no tienen por qué figurar como forma de pago.
    'COALESCE((SELECT fp.DESCRIPCION_FORMA_PAGO_CFP ' +
    'FROM fza_caja_formas_pago fp WHERE fp.CODIGO_FP_CFP = :FP), :FP),' +
    'NULL,:FECHA,NOW(),:USUARIO,:USUARIO)',
    ASolicitud.Original.Clave);
  try
    iLinea := 0;
    for oPago in ASolicitud.Pagos do
    begin
      Inc(iLinea);
      oConsulta.ParamByName('LINEAP').AsInteger := iLinea;
      oConsulta.ParamByName('FP').AsString := oPago.FormaPago;
      oConsulta.ParamByName('IMPORTE').AsCurrency := oPago.Importe;
      oConsulta.ParamByName('REF').AsString := Trim(oPago.Referencia);
      oConsulta.ParamByName('FECHA').AsDateTime := dtFecha;
      oConsulta.Execute;
      if oConsulta.RowsAffected <> 1 then
        raise EInvalidOpException.Create(SSubsanacionMedioInvalido);
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TServicioSubsanacionCajaUniDAC.GuardarAuditoria(
  const ASolicitud: TSolicitudSubsanacionCaja;
  const AAntes, ADespues: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta(
    'INSERT INTO fza_caja_subsanaciones (' +
    'CODIGO_EMP_CJSUB,CODIGO_ALM_CJSUB,CODIGO_CAJA_CJSUB,' +
    'NUMERO_OPERACION_CJSUB,SERIE_FAC_CJSUB,NUMERO_FAC_CJSUB,' +
    'MOTIVO_CJSUB,DATOS_ANTES_CJSUB,DATOS_DESPUES_CJSUB,' +
    'INSTANTE_ALTA,USUARIO_ALTA) VALUES (' +
    ':EMP,:ALM,:CAJA,:OPE,:SERIE,:NUMERO,:MOTIVO,:ANTES,:DESPUES,' +
    'NOW(),:USUARIO)', ASolicitud.Original.Clave);
  try
    oConsulta.ParamByName('MOTIVO').AsString := Trim(ASolicitud.Motivo);
    oConsulta.ParamByName('ANTES').AsMemo := AAntes;
    oConsulta.ParamByName('DESPUES').AsMemo := ADespues;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TServicioSubsanacionCajaUniDAC.Guardar(
  const ASolicitud: TSolicitudSubsanacionCaja): TResultadoSubsanacionCaja;
var
  oDatos, oDespues: TDatosSubsanacionCaja;
  oActual: TOperacionSubsanacionCaja;
  sAntes: string;
  oReloj: TStopwatch;
  iMovimientos: Integer;
begin
  ExigirPermiso;
  ValidarClave(ASolicitud.Original.Clave);
  ComprobarEsquema;
  if FConexion.InTransaction then
    raise EInvalidOpException.Create(SSubsanacionTransaccionActiva);
  oReloj := TStopwatch.StartNew;
  oDatos := nil;
  oDespues := nil;
  FConexion.StartTransaction;
  try
    try
      oDatos := LeerDatos(ASolicitud.Original.Clave, True);
      ValidarDatos(oDatos, ASolicitud.Original.Clave);
      oActual := CrearSnapshot(ASolicitud.Original.Clave, oDatos);
      ValidarSolicitud(ASolicitud, oActual, oDatos);
      ValidarMedio(ASolicitud);
      sAntes := oDatos.ComoJson;
      iMovimientos := 0;
      if HayImportesModificados(ASolicitud.Lineas) then
      begin
        Recalcular(oDatos, ASolicitud);
        GuardarImportes(oDatos, ASolicitud);
        iMovimientos := RegenerarMovimientosStock(oDatos, ASolicitud);
      end;
      GuardarCobro(oDatos, ASolicitud);
      Result := Default(TResultadoSubsanacionCaja);
      Result.EncoladaVerifactu := VerifactuActivo(FDependencias.ParametrosApp)
        or SiiActivo(FDependencias.ParametrosApp);
      Result.RegistradaNoVerifactu :=
        NoVerifactuActivo(FDependencias.ParametrosApp);
      if not EsSinVerifactu then
        FDependencias.Fiscal.EncolarCorreccionRegistro(
          FDependencias.ParametrosApp, FDependencias.ParametrosCaja,
          FDependencias.Usuario, ASolicitud.Original.Clave.SerieFactura,
          ASolicitud.Original.Clave.NumeroFactura, ASolicitud.Motivo);
      oDespues := LeerDatos(ASolicitud.Original.Clave, False);
      GuardarAuditoria(ASolicitud, sAntes, oDespues.ComoJson);
      Result.Clave := ASolicitud.Original.Clave;
      Result.Total := oDatos.Cabecera.FieldByName(ftotal).AsCurrency;
      FConexion.Commit;
      FDependencias.RegistroLog.RegistrarInformacion(FormatearMensajeDocumentos(
        CrearFormatoDocumentoLecturas(FConexion).LeerFormatoEmpresa(
          ASolicitud.Original.Clave.Empresa),
        SSubsanacionRegistrada, [ASolicitud.Original.Clave.SerieFactura,
        ASolicitud.Original.Clave.NumeroFactura,
        ModoVerifactuTexto(FDependencias.ParametrosApp),
        Trim(ASolicitud.Motivo)]));
      if iMovimientos > 0 then
      begin
        FDependencias.RegistroLog.RegistrarInformacion(FormatearMensajeDocumentos(
          CrearFormatoDocumentoLecturas(FConexion).LeerFormatoEmpresa(
            ASolicitud.Original.Clave.Empresa),
          SSubsanacionStockRegenerado,
          [ASolicitud.Original.Clave.SerieFactura,
          ASolicitud.Original.Clave.NumeroFactura, iMovimientos]));
        SolicitarProcesadoPrestaShop;
      end;
    except
      on E: Exception do
      begin
        FConexion.Rollback;
        FDependencias.RegistroLog.RegistrarError(
          'Subsanar operación de caja: ' + E.Message);
        raise;
      end;
    end;
  finally
    FreeAndNil(oDespues);
    FreeAndNil(oDatos);
    FDependencias.RegistroLog.RegistrarRendimiento(
      'Caja.Subsanacion', ASolicitud.Original.Clave.NumeroOperacion,
      oReloj.ElapsedMilliseconds);
  end;
end;

end.
