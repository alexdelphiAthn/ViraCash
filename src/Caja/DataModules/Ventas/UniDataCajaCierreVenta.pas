{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataCajaCierreVenta                                        }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Persistencia transaccional y decisiones puras del cierre de venta.        }
{******************************************************************************}
unit UniDataCajaCierreVenta;

interface

uses
  System.SysUtils, Data.DB, Uni, inLibFaseCobroPersistenciaIntf;

type
  TDatosDecisionCierreVentaCaja = record
    ImporteEntregado: Currency;
    EsDevolucionEconomica: Boolean;
    TieneArticulosDevueltos: Boolean;
    ImporteValeEmitido: Currency;
    // Venta a credito sin entrega (F7): la prenda pasa a la cuenta.
    ImporteDejarCuenta: Currency;
  end;

  TPersistenciaCierreVentaCajaUniDAC = class
  private
    FConexion: TUniConnection;
    FUsuarioAuditoria: string;
    FUnidadTrabajoActiva: Boolean;
    function ConsultarCobrosVentaOrigen(const AEmpresa, AAlmacen,
      ASerie, ANumero: string): TUniQuery;
    procedure AcumularImporteOperacion(AConsulta, AOrigen: TUniQuery;
      AImporte: Currency);
    procedure RechazarDevolucionOrigen(const AEmpresa, ASerie,
      ANumero: string);
  public
    constructor Create(
      AConexion: TUniConnection;
      const AUsuarioAuditoria: string);
    function CrearConsulta: TUniQuery;
    procedure BloquearPresupuesto(const AEmpresa, ASerie, ANumero: string);
    procedure EnlazarPresupuesto(const AEmpresa, ASerie, ANumero,
      ASerieFactura, ANumeroFactura: string);
    procedure IniciarUnidadTrabajo;
    procedure ConfirmarUnidadTrabajo;
    procedure RevertirUnidadTrabajo;
    function SiguienteOperacion(
      const AEmpresa, AAlmacen, ACaja, AEmpleado: string): string;
    procedure GuardarPago(
      AConsulta: TUniQuery;
      const AEmpresa, AAlmacen, ACaja, ASerie: string;
      const ANumeroOperacion: string;
      ANumeroLinea: Integer;
      const AFormaPago: string;
      AImporteEntregado, AImporteCambio: Currency;
      const ADivisa: string = '';
      const ARedBlockchain: string = '';
      AFactorCambio: Double = 1;
      AImporteDivisa: Double = 0;
      const AReferencia: string = '';
      const AObservaciones: string = '');
    procedure GuardarOperacion(
      AConsulta: TUniQuery;
      const AEmpresa, AAlmacen, ACaja: string;
      const ANumeroOperacion, ATipoOperacion: string;
      AImporte: Currency;
      const AEmpleado: string;
      AFechaOperacion: TDateTime = 0;
      const ANumeroFactura: string = '';
      const ASerieFactura: string = '';
      const ACliente: string = '';
      const AConcepto: string = '';
      const ASerieOrigen: string = '';
      const ANumeroOrigen: string = '';
      const AMotivoDevolucion: string = '';
      const AEmpresaContra: string = '';
      const AAlmacenContra: string = '';
      const AEsTraspaso: string = 'N';
      const AIdDeposito: string = '');
    procedure AcumularDevolucionVentaOrigen(
      AConsulta: TUniQuery;
      const AEmpresa, AAlmacen, ASerie, ANumero: string;
      AImporte: Currency);
    procedure MarcarValeCanjeado(
      AConsulta: TUniQuery;
      const ACodigoVale, AEmpresa, AAlmacen, ACaja: string;
      const ANumeroOperacion, ASerie, ANumeroFactura: string;
      AImporteRedimido: Currency;
      const ARestriccion: TRestriccionCanjeVale);
  end;

function AccionTieneNovedadCierreVenta(
  const ADatos: TDatosDecisionCierreVentaCaja;
  const AAccionDeposito: string): Boolean;
function AccionRequiereFacturaCierreVenta(
  const AAccionDeposito: string;
  ATotalLiquido: Currency): Boolean;
function PagoDebePersistirseCierreVenta(
  const AFormaPago: string;
  AImporte: Currency): Boolean;

// Tras grabar, solo se ocultan los depositos sin importe facturable.
// Una venta gratuita conserva su linea para la impresion inmediata.
procedure LimpiarLineasDepositoSinImporteCaja(ALineas: TDataSet);

implementation

uses
  inLibFormatoDocumento, UniDataFormatoDocumentoRepositorio,
  inLibMsgCaja, inLibMsgPresupuestos, inLibErroresBBDD,
  UniDataFaseCobroRepositorio, UniDataCajaConsultasRepositorio,
  inLibCajaVentaIntf;

procedure LimpiarLineasDepositoSinImporteCaja(ALineas: TDataSet);
var
  Accion: string;
  EsDeposito: Boolean;
begin
  ALineas.DisableControls;
  try
    ALineas.First;
    while not ALineas.Eof do
    begin
      Accion := Trim(ALineas.FieldByName('ACCION_DEPOSITO').AsString);
      EsDeposito := (Accion = 'NUEVO_DEP') or
        (Accion = 'AUMENTAR_DEP') or
        (ALineas.FieldByName('VIENE_DE_DEPOSITO').AsString = 'S');
      if EsDeposito and
         (Abs(ALineas.FieldByName('TOTAL_FACLIN').AsCurrency) < 0.001) then
        ALineas.Delete
      else
        ALineas.Next;
    end;
  finally
    ALineas.EnableControls;
  end;
end;

function FechaOperacionCaja(AFecha: TDateTime): TDateTime;
begin
  Result := AFecha;
  if Result <= 0 then
    Result := Now;
end;

function AccionTieneNovedadCierreVenta(
  const ADatos: TDatosDecisionCierreVentaCaja;
  const AAccionDeposito: string): Boolean;
var
  sAccion: string;
begin
  sAccion := Trim(AAccionDeposito);
  Result :=
    (ADatos.ImporteEntregado > 0) or
    (ADatos.ImporteDejarCuenta > 0) or
    ADatos.EsDevolucionEconomica or
    ADatos.TieneArticulosDevueltos or
    (ADatos.ImporteValeEmitido > 0) or
    // Una venta gratuita tambien entrega articulos y requiere ticket.
    (sAccion = '') or
    (sAccion = 'COBRAR') or
    (sAccion = 'CANCELAR') or
    (sAccion = 'NUEVO_DEP');
end;

function AccionRequiereFacturaCierreVenta(
  const AAccionDeposito: string;
  ATotalLiquido: Currency): Boolean;
var
  sAccion: string;
begin
  sAccion := Trim(AAccionDeposito);
  Result :=
    (sAccion = '') or
    (sAccion = 'COBRAR') or
    ((sAccion = 'CANCELAR') and (ATotalLiquido <> 0)) or
    (((sAccion = 'NUEVO_DEP') or
      (sAccion = 'AUMENTAR_DEP')) and
     (ATotalLiquido > 0.001));
end;

function PagoDebePersistirseCierreVenta(
  const AFormaPago: string;
  AImporte: Currency): Boolean;
begin
  Result :=
    (Abs(AImporte) > 0.001) and
    (AFormaPago <> 'VALE');
end;

constructor TPersistenciaCierreVentaCajaUniDAC.Create(
  AConexion: TUniConnection;
  const AUsuarioAuditoria: string);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
  FUsuarioAuditoria := AUsuarioAuditoria;
  FUnidadTrabajoActiva := False;
end;

function TPersistenciaCierreVentaCajaUniDAC.CrearConsulta: TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

procedure TPersistenciaCierreVentaCajaUniDAC.BloquearPresupuesto(
  const AEmpresa, ASerie, ANumero: string);
var
  Consulta: TUniQuery;
begin
  Consulta := CrearConsulta;
  try
    Consulta.SQL.Text :=
      'SELECT ESTADO_PRE, NUMERO_DESTINO_PRE FROM fza_presupuestos ' +
      'WHERE CODIGO_EMP_PRE = :EMPRESA AND SERIE_PRE = :SERIE ' +
      'AND NUMERO_PRE = :NUMERO FOR UPDATE';
    Consulta.ParamByName('EMPRESA').AsString := AEmpresa;
    Consulta.ParamByName('SERIE').AsString := ASerie;
    Consulta.ParamByName('NUMERO').AsString := ANumero;
    Consulta.Open;
    if Consulta.IsEmpty then
      raise EValidacionBBDD.Create(SErrorPresupuestoNoExiste);
    if not SameText(Consulta.FieldByName('ESTADO_PRE').AsString,
      'ABIERTO') or
      (Trim(Consulta.FieldByName('NUMERO_DESTINO_PRE').AsString) <> '') then
      raise EValidacionBBDD.Create(SErrorPresupuestoCajaNoDisponible);
  finally
    FreeAndNil(Consulta);
  end;
end;

procedure TPersistenciaCierreVentaCajaUniDAC.EnlazarPresupuesto(
  const AEmpresa, ASerie, ANumero, ASerieFactura, ANumeroFactura: string);
var
  Consulta: TUniQuery;
begin
  if (Trim(ASerieFactura) = '') or (Trim(ANumeroFactura) = '') or
     (ANumeroFactura = '0') then
    raise EValidacionBBDD.Create(SErrorPresupuestoCajaCobroCompleto);
  Consulta := CrearConsulta;
  try
    Consulta.SQL.Text :=
      'UPDATE fza_presupuestos SET ESTADO_PRE = ''CONVERTIDO'', ' +
      'TIPO_DESTINO_PRE = ''FC'', SERIE_DESTINO_PRE = :FACTURA_SERIE, ' +
      'NUMERO_DESTINO_PRE = :FACTURA_NUMERO, ' +
      'SERIE_FAC_PRE = :FACTURA_SERIE, NUMERO_FAC_PRE = :FACTURA_NUMERO, ' +
      'USUARIO_MODIF = :USUARIO, INSTANTE_MODIF = NOW() ' +
      'WHERE CODIGO_EMP_PRE = :EMPRESA AND SERIE_PRE = :SERIE ' +
      'AND NUMERO_PRE = :NUMERO AND ESTADO_PRE = ''ABIERTO'' ' +
      'AND LENGTH(COALESCE(NUMERO_DESTINO_PRE, SPACE(0))) = 0';
    Consulta.ParamByName('EMPRESA').AsString := AEmpresa;
    Consulta.ParamByName('SERIE').AsString := ASerie;
    Consulta.ParamByName('NUMERO').AsString := ANumero;
    Consulta.ParamByName('FACTURA_SERIE').AsString := ASerieFactura;
    Consulta.ParamByName('FACTURA_NUMERO').AsString := ANumeroFactura;
    Consulta.ParamByName('USUARIO').AsString := FUsuarioAuditoria;
    Consulta.Execute;
    if Consulta.RowsAffected <> 1 then
      raise EValidacionBBDD.Create(SErrorPresupuestoCajaNoDisponible);
  finally
    FreeAndNil(Consulta);
  end;
end;

procedure TPersistenciaCierreVentaCajaUniDAC.IniciarUnidadTrabajo;
begin
  FConexion.StartTransaction;
  FUnidadTrabajoActiva := True;
end;

procedure TPersistenciaCierreVentaCajaUniDAC.ConfirmarUnidadTrabajo;
begin
  FConexion.Commit;
  FUnidadTrabajoActiva := False;
end;

procedure TPersistenciaCierreVentaCajaUniDAC.RevertirUnidadTrabajo;
begin
  if FUnidadTrabajoActiva and FConexion.InTransaction then
    FConexion.Rollback;
  FUnidadTrabajoActiva := False;
end;

function TPersistenciaCierreVentaCajaUniDAC.SiguienteOperacion(
  const AEmpresa, AAlmacen, ACaja, AEmpleado: string): string;
var
  oProcedimiento: TUniStoredProc;
begin
  oProcedimiento := TUniStoredProc.Create(nil);
  try
    oProcedimiento.Connection := FConexion;
    oProcedimiento.StoredProcName := 'PRC_GET_NEXT_OP_CAJA';
    oProcedimiento.Params.CreateParam(
      ftString, 'pEmpresa', ptInput).AsString := AEmpresa;
    oProcedimiento.Params.CreateParam(
      ftString, 'pAlmacen', ptInput).AsString := AAlmacen;
    oProcedimiento.Params.CreateParam(
      ftString, 'pCaja', ptInput).AsString := ACaja;
    oProcedimiento.Params.CreateParam(
      ftString, 'pUsuario', ptInput).AsString := AEmpleado;
    oProcedimiento.Params.CreateParam(
      ftString, 'pSerie', ptOutput).Size := 12;
    oProcedimiento.Params.CreateParam(
      ftString, 'pcont', ptOutput).Size := 20;
    oProcedimiento.Prepare;
    oProcedimiento.Execute;
    Result := oProcedimiento.ParamByName('pcont').AsString;
  finally
    FreeAndNil(oProcedimiento);
  end;
end;

procedure TPersistenciaCierreVentaCajaUniDAC.GuardarPago(
  AConsulta: TUniQuery;
  const AEmpresa, AAlmacen, ACaja, ASerie: string;
  const ANumeroOperacion: string;
  ANumeroLinea: Integer;
  const AFormaPago: string;
  AImporteEntregado, AImporteCambio: Currency;
  const ADivisa, ARedBlockchain: string;
  AFactorCambio, AImporteDivisa: Double;
  const AReferencia, AObservaciones: string);
begin
  AConsulta.SQL.Text :=
    'INSERT INTO fza_caja_pagos (' +
    'CODIGO_EMP_PAGO, CODIGO_ALM_PAGO, CODIGO_CAJA_PAGO, ' +
    'SERIE_OPERACION_PAGO, NUMERO_OPERACION_PAGO, ' +
    'NUMERO_LINEA_PAGO, CODIGO_FP_CFP, ' +
    'IMPORTE_ENTREGADO_PAGO, IMPORTE_CAMBIO_PAGO, ' +
    'CODIGO_DIVISA_PAGO, RED_BLOCKCHAIN_PAGO, ' +
    'FACTOR_CAMBIO_PAGO, IMPORTE_DIVISA_PAGO, ' +
    'REFERENCIA_FACPAG, OBSERVACIONES_PAGO, ' +
    'USUARIO_ALTA, INSTANTE_ALTA) VALUES (' +
    ':EMP, :ALM, :CAJA, :SERIE, :NUMOP, :LINEA, :FORMAP, ' +
    ':IMPORTE, :CAMBIO, NULLIF(:DIVISA, ''''), ' +
    'NULLIF(:BLOCKCHAIN, ''''), :FACTORCAMBIO, :IMPORTEDIVISA, ' +
    'NULLIF(:REFERENCIA, ''''), NULLIF(:OBS, ''''), ' +
    ':USUARIO, NOW())';
  AConsulta.ParamByName('EMP').AsString := AEmpresa;
  AConsulta.ParamByName('ALM').AsString := AAlmacen;
  AConsulta.ParamByName('CAJA').AsString := ACaja;
  AConsulta.ParamByName('SERIE').AsString := ASerie;
  AConsulta.ParamByName('NUMOP').AsString := ANumeroOperacion;
  AConsulta.ParamByName('LINEA').AsInteger := ANumeroLinea;
  AConsulta.ParamByName('FORMAP').AsString := AFormaPago;
  AConsulta.ParamByName('IMPORTE').AsCurrency := AImporteEntregado;
  AConsulta.ParamByName('CAMBIO').AsCurrency := AImporteCambio;
  AConsulta.ParamByName('DIVISA').AsString := ADivisa;
  AConsulta.ParamByName('BLOCKCHAIN').AsString := ARedBlockchain;
  AConsulta.ParamByName('FACTORCAMBIO').AsFloat := AFactorCambio;
  AConsulta.ParamByName('IMPORTEDIVISA').AsFloat := AImporteDivisa;
  AConsulta.ParamByName('REFERENCIA').AsString := AReferencia;
  AConsulta.ParamByName('OBS').AsString := AObservaciones;
  AConsulta.ParamByName('USUARIO').AsString := FUsuarioAuditoria;
  AConsulta.Execute;
end;

procedure TPersistenciaCierreVentaCajaUniDAC.GuardarOperacion(
  AConsulta: TUniQuery;
  const AEmpresa, AAlmacen, ACaja: string;
  const ANumeroOperacion, ATipoOperacion: string;
  AImporte: Currency;
  const AEmpleado: string;
  AFechaOperacion: TDateTime;
  const ANumeroFactura, ASerieFactura, ACliente, AConcepto: string;
  const ASerieOrigen, ANumeroOrigen, AMotivoDevolucion: string;
  const AEmpresaContra, AAlmacenContra, AEsTraspaso: string;
  const AIdDeposito: string);
var
  dtFechaOperacion: TDateTime;
begin
  dtFechaOperacion := FechaOperacionCaja(AFechaOperacion);
  AConsulta.SQL.Text :=
    'INSERT INTO fza_caja_operaciones (' +
    'CODIGO_EMP_OPCAJA, CODIGO_ALM_OPCAJA, CODIGO_CAJA_OPCAJA, ' +
    'NUMERO_OPERACION_OPCAJA, TIPO_OPERACION_OPCAJA, ' +
    'IMPORTE_TOTAL_OPCAJA, FECHA_OPERACION_OPCAJA, ' +
    'FECHA_OP_DIA_OPCAJA, CODIGO_EMPLEADO_OPCAJA, ' +
    'NUMERO_FAC_OPCAJA, SERIE_FAC_OPCAJA, CODIGO_CLI_OPCAJA, ' +
    'CONCEPTO_GASTO_INGRESO_OPCAJA, SERIE_REF_ORIGEN_OPCAJA, ' +
    'NUMERO_REF_ORIGEN_OPCAJA, MOTIVO_DEVOLUCION_OPCAJA, ' +
    'CODIGO_EMP_CONTRA_OPCAJA, CODIGO_ALM_CONTRA_OPCAJA, ' +
    'ESTRASPASO_OPCAJA, ESTADO_DEVOLUCION_OPCAJA, ' +
    'ID_DEPOSITO_OPCAJA, USUARIO_ALTA, USUARIO_MODIF, ' +
    'INSTANTE_ALTA) VALUES (' +
    ':EMP, :ALM, :CAJA, :NUMOP, :TIPOOP, :IMPORTE, :FECHAOP, ' +
    ':FECHADIA, :EMPLEADO, NULLIF(:NROFAC, ''''), ' +
    'NULLIF(:SERIEFAC, ''''), NULLIF(:CLI, ''''), ' +
    'NULLIF(:CONCEPTO, ''''), NULLIF(:SERIEORIG, ''''), ' +
    'NULLIF(:NROORIG, ''''), NULLIF(:MOTIVO, ''''), ' +
    'NULLIF(:EMPCONTRA, ''''), NULLIF(:ALMCONTRA, ''''), ' +
    ':ESTRASPASO, ''N'', :DEP, :USUARIO, :USUARIO, NOW())';
  AConsulta.ParamByName('EMP').AsString := AEmpresa;
  AConsulta.ParamByName('ALM').AsString := AAlmacen;
  AConsulta.ParamByName('CAJA').AsString := ACaja;
  AConsulta.ParamByName('NUMOP').AsString := ANumeroOperacion;
  AConsulta.ParamByName('TIPOOP').AsString := ATipoOperacion;
  AConsulta.ParamByName('IMPORTE').AsCurrency := AImporte;
  AConsulta.ParamByName('FECHAOP').AsDateTime := dtFechaOperacion;
  AConsulta.ParamByName('FECHADIA').AsDateTime := Trunc(dtFechaOperacion);
  AConsulta.ParamByName('EMPLEADO').AsString := AEmpleado;
  AConsulta.ParamByName('NROFAC').AsString := ANumeroFactura;
  AConsulta.ParamByName('SERIEFAC').AsString := ASerieFactura;
  AConsulta.ParamByName('CLI').AsString := ACliente;
  AConsulta.ParamByName('CONCEPTO').AsString := AConcepto;
  AConsulta.ParamByName('SERIEORIG').AsString := ASerieOrigen;
  AConsulta.ParamByName('NROORIG').AsString := ANumeroOrigen;
  AConsulta.ParamByName('MOTIVO').AsString := AMotivoDevolucion;
  AConsulta.ParamByName('EMPCONTRA').AsString := AEmpresaContra;
  AConsulta.ParamByName('ALMCONTRA').AsString := AAlmacenContra;
  AConsulta.ParamByName('ESTRASPASO').AsString := AEsTraspaso;
  AConsulta.ParamByName('USUARIO').AsString := FUsuarioAuditoria;
  AConsulta.ParamByName('DEP').AsString := AIdDeposito;
  AConsulta.Execute;
end;

procedure TPersistenciaCierreVentaCajaUniDAC.RechazarDevolucionOrigen(
  const AEmpresa, ASerie, ANumero: string);
begin
  raise EValidacionBBDD.Create(FormatearMensajeDocumentos(
    CrearFormatoDocumentoLecturas(FConexion).LeerFormatoEmpresa(AEmpresa),
    SErrorVentaOrigenDevolucionCajaNoActualizada, [ASerie, ANumero]));
end;

function TPersistenciaCierreVentaCajaUniDAC.ConsultarCobrosVentaOrigen(
  const AEmpresa, AAlmacen, ASerie, ANumero: string): TUniQuery;
var
  Documento: TDocumentoOrigenDevolucionCaja;
begin
  Documento := ResolverDocumentoDevolucionCajaUniDAC(
    FConexion, ASerie, ANumero);
  if (Documento.Serie <> ASerie) or (Documento.Numero <> ANumero) then
    raise EValidacionBBDD.Create(SErrorDevolucionDocumentoSustituido);
  if not SameText(Documento.Empresa, AEmpresa) then
    RechazarDevolucionOrigen(AEmpresa, ASerie, ANumero);
  Result := CrearConsulta;
  try
    // La referencia fiscal sigue siendo la factura. Solo se localizan
    // los cobros del ticket sustituido para impedir un doble reembolso.
    // La unión parte de esos documentos, no de todas las ventas de caja.
    Result.SQL.Text :=
      'SELECT O.CODIGO_EMP_OPCAJA, O.CODIGO_ALM_OPCAJA, ' +
      ' O.CODIGO_CAJA_OPCAJA, O.NUMERO_OPERACION_OPCAJA, ' +
      ' O.IMPORTE_TOTAL_OPCAJA, O.IMPORTE_DEVUELTO_ACUM_OPCAJA ' +
      ' FROM (SELECT :SERIE AS SERIE_DOC, :NUMERO AS NUMERO_DOC ' +
      ' UNION SELECT R.SERIE_FAC_ORIGEN_FACREL, ' +
      ' R.NUMERO_FAC_ORIGEN_FACREL FROM fza_facturas_relaciones R ' +
      ' WHERE R.SERIE_FAC_FACREL = :SERIE ' +
      ' AND R.NUMERO_FAC_FACREL = :NUMERO ' +
      ' AND R.TIPO_RELACION_FACREL = ''SUSTITUYE'') D ' +
      ' STRAIGHT_JOIN fza_caja_operaciones O ' +
      ' ON O.CODIGO_EMP_OPCAJA = :EMP ' +
      ' AND O.SERIE_FAC_OPCAJA = D.SERIE_DOC ' +
      ' AND O.NUMERO_FAC_OPCAJA = D.NUMERO_DOC ' +
      ' WHERE O.TIPO_OPERACION_OPCAJA = ''VE'' ' +
      ' AND O.IMPORTE_TOTAL_OPCAJA > 0 ' +
      ' AND (:ALM = '''' OR O.CODIGO_ALM_OPCAJA = :ALM ' +
      ' OR D.SERIE_DOC <> :SERIE OR D.NUMERO_DOC <> :NUMERO) ' +
      ' ORDER BY O.CODIGO_ALM_OPCAJA, O.CODIGO_CAJA_OPCAJA, ' +
      ' O.NUMERO_OPERACION_OPCAJA FOR UPDATE';
    Result.ParamByName('EMP').AsString := AEmpresa;
    Result.ParamByName('ALM').AsString := AAlmacen;
    Result.ParamByName('SERIE').AsString := ASerie;
    Result.ParamByName('NUMERO').AsString := ANumero;
    Result.Open;
  except
    Result.Free;
    raise;
  end;
end;

procedure TPersistenciaCierreVentaCajaUniDAC.AcumularImporteOperacion(
  AConsulta, AOrigen: TUniQuery; AImporte: Currency);
begin
  AConsulta.SQL.Text :=
    'UPDATE fza_caja_operaciones ' +
    'SET ESTADO_DEVOLUCION_OPCAJA = CASE ' +
    ' WHEN COALESCE(IMPORTE_DEVUELTO_ACUM_OPCAJA, 0) + :IMPORTE >= ' +
    ' IMPORTE_TOTAL_OPCAJA THEN ''T'' ELSE ''P'' END, ' +
    'IMPORTE_DEVUELTO_ACUM_OPCAJA = ' +
    ' COALESCE(IMPORTE_DEVUELTO_ACUM_OPCAJA, 0) + :IMPORTE, ' +
    'USUARIO_MODIF = :USUARIO, INSTANTE_MODIF = NOW() ' +
    'WHERE CODIGO_EMP_OPCAJA = :EMP AND CODIGO_ALM_OPCAJA = :ALM ' +
    ' AND CODIGO_CAJA_OPCAJA = :CAJA ' +
    ' AND NUMERO_OPERACION_OPCAJA = :OPERACION ' +
    ' AND TIPO_OPERACION_OPCAJA = ''VE'' ' +
    ' AND COALESCE(IMPORTE_DEVUELTO_ACUM_OPCAJA, 0) + :IMPORTE <= ' +
    ' IMPORTE_TOTAL_OPCAJA';
  AConsulta.ParamByName('EMP').AsString :=
    AOrigen.FieldByName('CODIGO_EMP_OPCAJA').AsString;
  AConsulta.ParamByName('ALM').AsString :=
    AOrigen.FieldByName('CODIGO_ALM_OPCAJA').AsString;
  AConsulta.ParamByName('CAJA').AsString :=
    AOrigen.FieldByName('CODIGO_CAJA_OPCAJA').AsString;
  AConsulta.ParamByName('OPERACION').AsString :=
    AOrigen.FieldByName('NUMERO_OPERACION_OPCAJA').AsString;
  AConsulta.ParamByName('IMPORTE').AsCurrency := AImporte;
  AConsulta.ParamByName('USUARIO').AsString := FUsuarioAuditoria;
  AConsulta.Execute;
  if AConsulta.RowsAffected <> 1 then
    raise EValidacionBBDD.Create(SErrorFacturaAbonarNoVigente);
end;

procedure TPersistenciaCierreVentaCajaUniDAC.AcumularDevolucionVentaOrigen(
  AConsulta: TUniQuery;
  const AEmpresa, AAlmacen, ASerie, ANumero: string;
  AImporte: Currency);
var
  Origenes: TUniQuery;
  Disponible, Pendiente, Aplicar: Currency;
  Propia: Boolean;
begin
  if AImporte <= 0 then
    raise EArgumentOutOfRangeException.Create('AImporte');
  Propia := not FConexion.InTransaction;
  if Propia then
    FConexion.StartTransaction;
  try
    Origenes := ConsultarCobrosVentaOrigen(AEmpresa, AAlmacen,
      ASerie, ANumero);
    try
      Disponible := 0;
      while not Origenes.Eof do
      begin
        Disponible := Disponible +
          Origenes.FieldByName('IMPORTE_TOTAL_OPCAJA').AsCurrency -
          Origenes.FieldByName('IMPORTE_DEVUELTO_ACUM_OPCAJA').AsCurrency;
        Origenes.Next;
      end;
      if Disponible < AImporte then
        RechazarDevolucionOrigen(AEmpresa, ASerie, ANumero);
      Pendiente := AImporte;
      Origenes.First;
      while not Origenes.Eof and (Pendiente > 0) do
      begin
        Aplicar := Origenes.FieldByName('IMPORTE_TOTAL_OPCAJA').AsCurrency -
          Origenes.FieldByName('IMPORTE_DEVUELTO_ACUM_OPCAJA').AsCurrency;
        if Aplicar > Pendiente then
          Aplicar := Pendiente;
        if Aplicar > 0 then
        begin
          AcumularImporteOperacion(AConsulta, Origenes, Aplicar);
          Pendiente := Pendiente - Aplicar;
        end;
        Origenes.Next;
      end;
    finally
      Origenes.Free;
    end;
    if Propia then
      FConexion.Commit;
  except
    if Propia and FConexion.InTransaction then
      FConexion.Rollback;
    raise;
  end;
end;

procedure TPersistenciaCierreVentaCajaUniDAC.MarcarValeCanjeado(
  AConsulta: TUniQuery;
  const ACodigoVale, AEmpresa, AAlmacen, ACaja: string;
  const ANumeroOperacion, ASerie, ANumeroFactura: string;
  AImporteRedimido: Currency;
  const ARestriccion: TRestriccionCanjeVale);
var
  iFilasAfectadas: Integer;
  sMensaje: string;
begin
  AConsulta.SQL.Text :=
    'UPDATE fza_caja_vales SET ESTADO_VL = ''REDIMIDO'', ' +
    'FECHA_REDENCION_VL = NOW(), IMPORTE_REDIMIDO_VL = :IMPORTE, ' +
    'CODIGO_EMP_RED_VL = :EMPRESA, CODIGO_ALM_RED_VL = :ALMACEN, ' +
    'CODIGO_CAJA_RED_VL = :CAJA, ' +
    'NUMERO_OPERACION_RED_VL = :NUMOP, ' +
    'SERIE_FAC_RED_VL = NULLIF(:SERIE, ''''), ' +
    'NUMERO_FAC_RED_VL = NULLIF(:NUMFAC, ''''), ' +
    'USUARIO_MODIF = :USUARIO, INSTANTE_MODIF = NOW() ' +
    'WHERE CODIGO_VL = :CODIGO AND ESTADO_VL = ''PENDIENTE'' ' +
    'AND (FECHA_CADUCIDAD_VL IS NULL ' +
    '     OR FECHA_CADUCIDAD_VL >= CURDATE())' +
    FiltroAmbitoCanjeVale(ARestriccion);
  AConsulta.ParamByName('CODIGO').AsString := ACodigoVale;
  AConsulta.ParamByName('IMPORTE').AsCurrency := AImporteRedimido;
  AConsulta.ParamByName('EMPRESA').AsString := AEmpresa;
  AConsulta.ParamByName('ALMACEN').AsString := AAlmacen;
  AConsulta.ParamByName('CAJA').AsString := ACaja;
  AConsulta.ParamByName('NUMOP').AsString := ANumeroOperacion;
  AConsulta.ParamByName('SERIE').AsString := ASerie;
  AConsulta.ParamByName('NUMFAC').AsString := ANumeroFactura;
  AConsulta.ParamByName('USUARIO').AsString := FUsuarioAuditoria;
  AsignarAmbitoCanjeVale(AConsulta, ARestriccion);
  AConsulta.Execute;
  iFilasAfectadas := AConsulta.RowsAffected;
  if iFilasAfectadas <> 1 then
  begin
    if CrearRepositorioFaseCobroUniDAC(FConexion).ExisteValePendiente(
         ACodigoVale, ARestriccion, sMensaje) then
      sMensaje := Format(SErrorValeCanjeNoDisponible, [ACodigoVale]);
    raise EValidacionBBDD.Create(sMensaje);
  end;
end;

end.
