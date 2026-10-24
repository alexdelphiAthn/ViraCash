{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPedidosPrestaShopEscrituras                           }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                        }
{   Fecha:       04/08/2026                                                   }
{   Autor:       Alejandro Laorden Hidalgo                                    }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{  SPDX-License-Identifier: MPL-2.0                                           }
{  Descripción:                                                               }
{    Escritura atómica de cabecera, líneas y mensajes de PrestaShop.          }
{******************************************************************************}
unit UniDataPedidosPrestaShopEscrituras;

interface

uses
  Uni,
  inLibLogIntf,
  inLibImpuestosLecturasIntf,
  inLibPedidosPrestaShopPortes,
  inLibPresta;

type
  TEntradaPedidoPrestaShop = record
    Pedido: TOrder;
    Origen: string;
    Numero: string;
    Serie: string;
    CodigoCliente: string;
    Empresa: string;
    Almacen: string;
    CodigosArticulo: TArray<string>;
  end;
  TPedidosPrestaShopEscrituras = class
  private
    FConexion: TUniConnection;
    FRegistroLog: IRegistroLog;
    FUsuario: string;
    procedure ConfigurarCabecera(AConsulta: TUniQuery);
    procedure AsignarCabecera(
      AConsulta: TUniQuery;
      const AEntrada: TEntradaPedidoPrestaShop;
      const AImpuestos: TPorcentajesImpuestos;
      ATieneImpuestos: Boolean);
    procedure ConfigurarLineas(AConsulta: TUniQuery);
    procedure InsertarLineas(
      AConsulta: TUniQuery;
      const AEntrada: TEntradaPedidoPrestaShop;
      const ALecturas: ILecturasImpuestos;
      const AImpuestos: TPorcentajesImpuestos;
      ATieneImpuestos: Boolean);
    procedure AsegurarArticuloGastosTransporte(AConsulta: TUniQuery);
    procedure ConfigurarLineaGastosTransporte(AConsulta: TUniQuery);
    procedure InsertarLineaGastosTransporte(
      AConsulta: TUniQuery;
      const AEntrada: TEntradaPedidoPrestaShop;
      const APortes: TPortesPedidoPrestaShop);
    procedure ConfigurarMensajes(AConsulta: TUniQuery);
    procedure InsertarMensajes(
      AConsulta: TUniQuery;
      APedido: TOrder);
  public
    constructor Create(
      AConexion: TUniConnection;
      const AUsuario: string;
      const ARegistroLog: IRegistroLog);
    procedure Ejecutar(const AEntrada: TEntradaPedidoPrestaShop);
  end;

implementation

uses
  System.SysUtils,
  UniDataImpuestosRepositorio;

resourcestring
  SErrorCrearServicioGastosTransporte =
    'No se pudo crear el servicio GASTOS_T.';
  SErrorArticuloGastosTransporteInactivo =
    'El artículo GASTOS_T existe, pero está inactivo.';
  SErrorCodigoGastosTransporteNoServicio =
    'El código GASTOS_T ya existe y no es un servicio.';
  SErrorServicioGastosTransporteIvaNoNormal =
    'El servicio GASTOS_T debe tener IVA normal (tipo N).';
  SErrorServicioGastosTransporteConVariaciones =
    'El servicio GASTOS_T no puede tener variaciones.';
  SErrorServicioGastosTransporteTrazable =
    'El servicio GASTOS_T no puede ser trazable.';
  SErrorCrearSkuGastosTransporte =
    'No se pudo crear el SKU GASTOS_T.';
  SErrorSkuGastosTransporteOtroArticulo =
    'El SKU GASTOS_T ya está asociado a otro artículo.';
  SErrorSkuGastosTransporteConVariacion =
    'El SKU GASTOS_T debe ser un SKU simple, sin variación.';
  SErrorSkuGastosTransporteInactivo =
    'El SKU GASTOS_T existe, pero está inactivo.';
  SErrorConfiguracionIvaPedidoPrestaShopNoEncontrada =
    'No se encontró una configuración de IVA vigente para la empresa ' +
    'en la fecha del pedido de PrestaShop.';

function PorcentajeTipoIva(
  const ATipoIva: string;
  const AImpuestos: TPorcentajesImpuestos): Double;
begin
  if SameText(Trim(ATipoIva), 'R') then
    Result := AImpuestos.IvaReducido
  else if SameText(Trim(ATipoIva), 'S') then
    Result := AImpuestos.IvaSuperReducido
  else if SameText(Trim(ATipoIva), 'E') then
    Result := AImpuestos.IvaExento
  else
    Result := AImpuestos.IvaNormal;
end;

constructor TPedidosPrestaShopEscrituras.Create(
  AConexion: TUniConnection;
  const AUsuario: string;
  const ARegistroLog: IRegistroLog);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
  FUsuario := AUsuario;
  FRegistroLog := ARegistroLog;
end;

procedure TPedidosPrestaShopEscrituras.ConfigurarCabecera(
  AConsulta: TUniQuery);
begin
  AConsulta.SQL.Text :=
    'INSERT INTO fza_pedidos (NUMERO_PED, SERIE_PED, FECHA_PED, ' +
    ' ESTADO_PED, CODIGO_EMP_PED, CODIGO_ALM_PED, CODIGO_CLI_PED, ' +
    ' IDPS_PED, ORIGENPS_PED, FECHAPS_PED, REFERENCIAPS_PED, ' +
    ' FORMAPAGOPS_PED, TRANSPORTISTAPS_PED, ESTADOPEDIDOPS_PED, ' +
    ' EMAIL_CLIENTE_PED, NIF_CLIENTE_PED, ' +
    ' NOMBRE_CLI_ENVIO_PED, MOVIL_CLIENTE_ENVIO_PED, ' +
    ' DIRECCION1_CLIENTE_ENVIO_PED, DIRECCION2_CLIENTE_ENVIO_PED, ' +
    ' POBLACION_CLIENTE_ENVIO_PED, PROVINCIA_CLIENTE_ENVIO_PED, ' +
    ' CODIGO_POSTAL_CLIENTE_ENVIO_PED, ' +
    ' RAZON_SOCIAL_CLIENTE_FISCAL_PED, MOVIL_CLIENTE_FISCAL_PED, ' +
    ' DIRECCION1_CLIENTE_FISCAL_PED, DIRECCION2_CLIENTE_FISCAL_PED, ' +
    ' POBLACION_CLIENTE_FISCAL_PED, PROVINCIA_CLIENTE_FISCAL_PED, ' +
    ' CODIGO_POSTAL_CLIENTE_FISCAL_PED, ' +
    ' CODIGO_IVA_PED, PORCENTAJE_IVAN_PED, PORCENTAJE_IVAR_PED, ' +
    ' PORCENTAJE_IVAS_PED, PORCENTAJE_IVAE_PED, ' +
    ' TOTAL_BASES_PED, TOTAL_IMPUESTOS_PED, ' +
    ' TOTAL_LIQUIDO_PED, TOTAL_PAGADOREALPS_PED, ' +
    ' CONTADOR_LINEAS_PED, ' +
    ' INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:NUMERO, :SERIE, :FECHA, :ESTADO, :CODEMP, :CODALM, ' +
    ' :CODCLI, :IDPS, :ORIGENPS, :FECHAPS, :REFPS, :FORMAPAGO, :TRANSP, ' +
    ' :ESTADOPS, :EMAILCLI, :NIFCLI, :NOMENV, :MOVENV, :DIR1ENV, ' +
    ' :DIR2ENV, :POBLENV, :PROVENV, :CPENV, :RSFIS, :MOVFIS, ' +
    ' :DIR1FIS, :DIR2FIS, :POBLFIS, :PROVFIS, :CPFIS, :CODIVA, ' +
    ' :IVAN, :IVAR, :IVAS, :IVAE, :BASES, :IMPUESTOS, :TOTAL, ' +
    ' :PAGADO, :CONTADOR_LINEAS, NOW(), :USU, :USU)';
end;

procedure TPedidosPrestaShopEscrituras.AsignarCabecera(
  AConsulta: TUniQuery;
  const AEntrada: TEntradaPedidoPrestaShop;
  const AImpuestos: TPorcentajesImpuestos;
  ATieneImpuestos: Boolean);
var
  oPedido: TOrder;
  sMovil: string;
  sNif: string;
begin
  oPedido := AEntrada.Pedido;
  AConsulta.ParamByName('NUMERO').AsString := AEntrada.Numero;
  AConsulta.ParamByName('SERIE').AsString := AEntrada.Serie;
  AConsulta.ParamByName('FECHA').AsDateTime := Date;
  AConsulta.ParamByName('ESTADO').AsString := 'IMPORTADO';
  AConsulta.ParamByName('CODEMP').AsString := AEntrada.Empresa;
  AConsulta.ParamByName('CODALM').AsString := AEntrada.Almacen;
  AConsulta.ParamByName('CODCLI').AsString := AEntrada.CodigoCliente;
  AConsulta.ParamByName('IDPS').AsString := oPedido.idPedido;
  AConsulta.ParamByName('ORIGENPS').AsString := AEntrada.Origen;
  AConsulta.ParamByName('FECHAPS').AsString := oPedido.FechaCreacion;
  AConsulta.ParamByName('REFPS').AsString := oPedido.ReferenciaCliente;
  AConsulta.ParamByName('FORMAPAGO').AsString := oPedido.FormaPago;
  AConsulta.ParamByName('TRANSP').AsString := oPedido.Transportista;
  AConsulta.ParamByName('ESTADOPS').AsString := oPedido.EstadoPedido;
  AConsulta.ParamByName('EMAILCLI').AsString := oPedido.custMail;
  sNif := Trim(oPedido.Vat_numberBil);
  if sNif = '' then
    sNif := Trim(oPedido.DniBil);
  if sNif = '' then
    sNif := Trim(oPedido.Vat_numberDel);
  if sNif = '' then
    sNif := Trim(oPedido.DniDel);
  AConsulta.ParamByName('NIFCLI').AsString := sNif;
  AConsulta.ParamByName('NOMENV').AsString :=
    oPedido.FirstnameDel + ' ' + oPedido.LastNameDel;
  sMovil := Trim(oPedido.Phone_moDel);
  if sMovil = '' then
    sMovil := Trim(oPedido.PhoneDel);
  AConsulta.ParamByName('MOVENV').AsString := sMovil;
  AConsulta.ParamByName('DIR1ENV').AsString := oPedido.Address1Del;
  AConsulta.ParamByName('DIR2ENV').AsString := oPedido.Address2Del;
  AConsulta.ParamByName('POBLENV').AsString := oPedido.CityDel;
  AConsulta.ParamByName('PROVENV').AsString := oPedido.NameStateDel;
  AConsulta.ParamByName('CPENV').AsString := oPedido.PostcodeDel;
  AConsulta.ParamByName('RSFIS').AsString := oPedido.CompanyBil;
  sMovil := Trim(oPedido.Phone_moBil);
  if sMovil = '' then
    sMovil := Trim(oPedido.PhoneBil);
  AConsulta.ParamByName('MOVFIS').AsString := sMovil;
  AConsulta.ParamByName('DIR1FIS').AsString := oPedido.Address1Bil;
  AConsulta.ParamByName('DIR2FIS').AsString := oPedido.Address2Bil;
  AConsulta.ParamByName('POBLFIS').AsString := oPedido.CityBil;
  AConsulta.ParamByName('PROVFIS').AsString := oPedido.NameStateBil;
  AConsulta.ParamByName('CPFIS').AsString := oPedido.PostcodeBil;
  if ATieneImpuestos then
  begin
    AConsulta.ParamByName('CODIVA').AsString := AImpuestos.CodigoIva;
    AConsulta.ParamByName('IVAN').AsFloat := AImpuestos.IvaNormal;
    AConsulta.ParamByName('IVAR').AsFloat := AImpuestos.IvaReducido;
    AConsulta.ParamByName('IVAS').AsFloat := AImpuestos.IvaSuperReducido;
    AConsulta.ParamByName('IVAE').AsFloat := AImpuestos.IvaExento;
  end
  else
  begin
    AConsulta.ParamByName('CODIVA').Clear;
    AConsulta.ParamByName('IVAN').Clear;
    AConsulta.ParamByName('IVAR').Clear;
    AConsulta.ParamByName('IVAS').Clear;
    AConsulta.ParamByName('IVAE').Clear;
  end;
  AConsulta.ParamByName('BASES').AsCurrency := oPedido.TotalPedSIVA;
  AConsulta.ParamByName('IMPUESTOS').AsCurrency :=
    oPedido.TotalPedCIVA - oPedido.TotalPedSIVA;
  AConsulta.ParamByName('TOTAL').AsCurrency := oPedido.TotalPedCIVA;
  AConsulta.ParamByName('PAGADO').AsCurrency := oPedido.TotalPagadoReal;
  AConsulta.ParamByName('CONTADOR_LINEAS').AsString := Format('%.8d',
    [(oPedido.LineasPedido.Count + Ord(
      (Abs(oPedido.TotalPortesSIVA) >= 0.005) or
      (Abs(oPedido.TotalPortesCIVA) >= 0.005))) * 10]);
  AConsulta.ParamByName('USU').AsString := FUsuario;
end;

procedure TPedidosPrestaShopEscrituras.ConfigurarLineas(
  AConsulta: TUniQuery);
begin
  AConsulta.SQL.Text :=
    'INSERT INTO fza_pedidos_lineas (NUMERO_PED_PEDLIN, ' +
    ' SERIE_PED_PEDLIN, LINEA_PEDLIN, IDLINEAPS_PEDLIN, ' +
    ' IDPRODPS_PEDLIN, CODIGOPRODPS_PEDLIN, IDATRIBPRODPS_PEDLIN, ' +
    ' CODIGO_ART_PEDLIN, CODBAR_ART_PEDLIN, ' +
    ' TIPO_IVA_ARTICULO_PEDLIN, PORCENTAJE_IVA_PEDLIN, ' +
    ' DESCRIPCION_ARTICULO_PEDLIN, CANTIDAD_PEDLIN, ' +
    ' CANTIDAD_ENTREGADA_PEDLIN, CANTIDAD_A_ALBARANAR_PEDLIN, ' +
    ' CANTIDAD_PENDIENTE_PEDLIN, ESENTREGADA_PEDLIN, ' +
    ' CODIGO_ALMACEN_PEDLIN, PRECIO_VENTA_SIVA_ARTICULO_PEDLIN, ' +
    ' PRECIO_VENTA_CIVA_ARTICULO_PEDLIN, TOTAL_PEDLIN, ' +
    ' INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:NUMERO, :SERIE, :LIN, :IDLPS, :IDPPS, :REFPROD, ' +
    ' :IDATRIB, :CODART, :EAN13, :TIVA, :PIVA, :DESCR, :CANT, ' +
    ' 0, 0, :CANT, ''N'', :CODALM, :PSIVA, :PCIVA, :TOT, ' +
    ' NOW(), :USU, :USU)';
end;

procedure TPedidosPrestaShopEscrituras.InsertarLineas(
  AConsulta: TUniQuery;
  const AEntrada: TEntradaPedidoPrestaShop;
  const ALecturas: ILecturasImpuestos;
  const AImpuestos: TPorcentajesImpuestos;
  ATieneImpuestos: Boolean);
var
  i: Integer;
  oLinea: TLineaPed;
  dCantidad: Double;
  dPorcentajeIva: Double;
  sTipoIva: string;
begin
  for i := 0 to AEntrada.Pedido.LineasPedido.Count - 1 do
  begin
    oLinea := AEntrada.Pedido.LineasPedido[i];
    dCantidad := StrToFloatDef(oLinea.sCantidad, 1);
    AConsulta.ParamByName('NUMERO').AsString := AEntrada.Numero;
    AConsulta.ParamByName('SERIE').AsString := AEntrada.Serie;
    AConsulta.ParamByName('LIN').AsString := Format('%.4d', [(i + 1) * 10]);
    AConsulta.ParamByName('IDLPS').AsString := oLinea.idLinea;
    AConsulta.ParamByName('IDPPS').AsString := oLinea.idProducto;
    AConsulta.ParamByName('REFPROD').AsString := oLinea.sRefProd;
    AConsulta.ParamByName('IDATRIB').AsString := oLinea.sRefAtrib;
    AConsulta.ParamByName('CODART').AsString :=
      AEntrada.CodigosArticulo[i];
    AConsulta.ParamByName('EAN13').AsString := oLinea.sCodEAN13;
    sTipoIva := ALecturas.LeerTipoIvaArticulo(
      AEntrada.CodigosArticulo[i]);
    if Trim(sTipoIva) = '' then
      sTipoIva := 'N';
    dPorcentajeIva := 0;
    if ATieneImpuestos then
      dPorcentajeIva := PorcentajeTipoIva(sTipoIva, AImpuestos);
    AConsulta.ParamByName('TIVA').AsString := sTipoIva;
    AConsulta.ParamByName('PIVA').AsFloat := dPorcentajeIva;
    AConsulta.ParamByName('DESCR').AsString := oLinea.sDescripcion;
    AConsulta.ParamByName('CANT').AsFloat := dCantidad;
    AConsulta.ParamByName('CODALM').AsString := AEntrada.Almacen;
    AConsulta.ParamByName('PSIVA').AsCurrency := oLinea.cPrecioSIVA;
    AConsulta.ParamByName('PCIVA').AsCurrency := oLinea.cPrecioCIVA;
    AConsulta.ParamByName('TOT').AsCurrency := oLinea.cPrecioSIVA * dCantidad;
    AConsulta.ParamByName('USU').AsString := FUsuario;
    AConsulta.Execute;
  end;
end;

procedure TPedidosPrestaShopEscrituras.AsegurarArticuloGastosTransporte(
  AConsulta: TUniQuery);
var
  sActivo: string;
  sArticuloSku: string;
  sTipoArticulo: string;
  sTipoIva: string;
  sVariacion: string;
  sTrazable: string;
begin
  AConsulta.Close;
  AConsulta.SQL.Text :=
    'INSERT INTO fza_articulos (CODIGO_ART_ART, ORDEN_ART, ' +
    ' ESACTIVO_ART, ESWEB_ART, TIPO_ART, DESCRIPCION_ART, ' +
    ' TIPO_IVA_ART, ESACTIVO_FIJO_ART, TIPO_CANTIDAD_ART, ' +
    ' ESVARIACION_ART, ESTRAZABLE_ART, INSTANTE_ALTA, ' +
    ' USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :CODIGO, COALESCE(MAX(ORDEN_ART), 0) + 1, ''S'', ''N'', ' +
    ' :TIPO_ART, :DESCRIPCION, :TIPO_IVA, ''N'', ''Uds'', ''N'', ' +
    ' ''N'', NOW(), :USUARIO, :USUARIO FROM fza_articulos ' +
    'ON DUPLICATE KEY UPDATE CODIGO_ART_ART = :CODIGO';
  AConsulta.ParamByName('CODIGO').AsString :=
    CODIGO_ARTICULO_GASTOS_TRANSPORTE;
  AConsulta.ParamByName('TIPO_ART').AsString :=
    TIPO_ARTICULO_GASTOS_TRANSPORTE;
  AConsulta.ParamByName('DESCRIPCION').AsString :=
    DESCRIPCION_GASTOS_TRANSPORTE;
  AConsulta.ParamByName('TIPO_IVA').AsString :=
    TIPO_IVA_GASTOS_TRANSPORTE;
  AConsulta.ParamByName('USUARIO').AsString := FUsuario;
  AConsulta.Execute;

  AConsulta.Close;
  AConsulta.SQL.Text :=
    'SELECT ESACTIVO_ART, TIPO_ART, TIPO_IVA_ART, ' +
    '       ESVARIACION_ART, ESTRAZABLE_ART ' +
    '  FROM fza_articulos ' +
    ' WHERE CODIGO_ART_ART = :CODIGO FOR UPDATE';
  AConsulta.ParamByName('CODIGO').AsString :=
    CODIGO_ARTICULO_GASTOS_TRANSPORTE;
  AConsulta.Open;
  if AConsulta.Eof then
    raise EPortesPedidoPrestaShop.Create(SErrorCrearServicioGastosTransporte);
  sActivo := Trim(AConsulta.FieldByName('ESACTIVO_ART').AsString);
  sTipoArticulo := Trim(AConsulta.FieldByName('TIPO_ART').AsString);
  sTipoIva := Trim(AConsulta.FieldByName('TIPO_IVA_ART').AsString);
  sVariacion := Trim(AConsulta.FieldByName('ESVARIACION_ART').AsString);
  sTrazable := Trim(AConsulta.FieldByName('ESTRAZABLE_ART').AsString);
  if not SameText(sActivo, 'S') then
    raise EPortesPedidoPrestaShop.Create(
      SErrorArticuloGastosTransporteInactivo);
  if not SameText(sTipoArticulo, TIPO_ARTICULO_GASTOS_TRANSPORTE) then
    raise EPortesPedidoPrestaShop.Create(
      SErrorCodigoGastosTransporteNoServicio);
  if not SameText(sTipoIva, TIPO_IVA_GASTOS_TRANSPORTE) then
    raise EPortesPedidoPrestaShop.Create(
      SErrorServicioGastosTransporteIvaNoNormal);
  if not SameText(sVariacion, 'N') then
    raise EPortesPedidoPrestaShop.Create(
      SErrorServicioGastosTransporteConVariaciones);
  if not SameText(sTrazable, 'N') then
    raise EPortesPedidoPrestaShop.Create(
      SErrorServicioGastosTransporteTrazable);
  AConsulta.Close;
  AConsulta.SQL.Text :=
    'UPDATE fza_articulos SET DESCRIPCION_ART = :DESCRIPCION, ' +
    ' ESWEB_ART = ''N'', USUARIO_MODIF = :USUARIO ' +
    ' WHERE CODIGO_ART_ART = :CODIGO';
  AConsulta.ParamByName('CODIGO').AsString :=
    CODIGO_ARTICULO_GASTOS_TRANSPORTE;
  AConsulta.ParamByName('DESCRIPCION').AsString :=
    DESCRIPCION_GASTOS_TRANSPORTE;
  AConsulta.ParamByName('USUARIO').AsString := FUsuario;
  AConsulta.Execute;

  AConsulta.Close;
  AConsulta.SQL.Text :=
    'INSERT INTO fza_articulos_skus (CODIGO_UNIDAD_SKU, ' +
    ' CODIGO_ART_SKU, CODIGO_VAR_SKU, ESACTIVO_SKU, ' +
    ' INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:SKU, :ARTICULO, ''-'', ''S'', NOW(), :USUARIO, :USUARIO) ' +
    'ON DUPLICATE KEY UPDATE CODIGO_UNIDAD_SKU = :SKU';
  AConsulta.ParamByName('SKU').AsString := CODIGO_SKU_GASTOS_TRANSPORTE;
  AConsulta.ParamByName('ARTICULO').AsString :=
    CODIGO_ARTICULO_GASTOS_TRANSPORTE;
  AConsulta.ParamByName('USUARIO').AsString := FUsuario;
  AConsulta.Execute;

  AConsulta.Close;
  AConsulta.SQL.Text :=
    'SELECT CODIGO_ART_SKU, CODIGO_VAR_SKU, ESACTIVO_SKU ' +
    '  FROM fza_articulos_skus ' +
    ' WHERE CODIGO_UNIDAD_SKU = :SKU FOR UPDATE';
  AConsulta.ParamByName('SKU').AsString := CODIGO_SKU_GASTOS_TRANSPORTE;
  AConsulta.Open;
  if AConsulta.Eof then
    raise EPortesPedidoPrestaShop.Create(SErrorCrearSkuGastosTransporte);
  sArticuloSku := Trim(AConsulta.FieldByName('CODIGO_ART_SKU').AsString);
  sVariacion := Trim(AConsulta.FieldByName('CODIGO_VAR_SKU').AsString);
  sActivo := Trim(AConsulta.FieldByName('ESACTIVO_SKU').AsString);
  if not SameText(sArticuloSku, CODIGO_ARTICULO_GASTOS_TRANSPORTE) then
    raise EPortesPedidoPrestaShop.Create(SErrorSkuGastosTransporteOtroArticulo);
  if sVariacion <> '-' then
    raise EPortesPedidoPrestaShop.Create(SErrorSkuGastosTransporteConVariacion);
  if not SameText(sActivo, 'S') then
    raise EPortesPedidoPrestaShop.Create(SErrorSkuGastosTransporteInactivo);
  AConsulta.Close;
end;

procedure TPedidosPrestaShopEscrituras.ConfigurarLineaGastosTransporte(
  AConsulta: TUniQuery);
begin
  AConsulta.SQL.Text :=
    'INSERT INTO fza_pedidos_lineas (NUMERO_PED_PEDLIN, ' +
    ' SERIE_PED_PEDLIN, LINEA_PEDLIN, CODIGO_ART_PEDLIN, ' +
    ' CODIGO_UNIDAD_PEDLIN, TIPO_CANTIDAD_ARTICULO_PEDLIN, ' +
    ' ESIMP_INCL_TARIFA_PEDLIN, TIPO_IVA_ARTICULO_PEDLIN, ' +
    ' DESCRIPCION_ARTICULO_PEDLIN, CANTIDAD_PEDLIN, ' +
    ' CANTIDAD_ENTREGADA_PEDLIN, CANTIDAD_A_ALBARANAR_PEDLIN, ' +
    ' CANTIDAD_PENDIENTE_PEDLIN, ESENTREGADA_PEDLIN, ' +
    ' CODIGO_ALMACEN_PEDLIN, PRECIO_VENTA_SIVA_ARTICULO_PEDLIN, ' +
    ' PORCENTAJE_IVA_PEDLIN, PRECIO_VENTA_CIVA_ARTICULO_PEDLIN, ' +
    ' TOTAL_PEDLIN, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:NUMERO, :SERIE, :LINEA, :ARTICULO, :SKU, ''Uds'', ' +
    ' ''S'', ''N'', :DESCRIPCION, 1, 0, 0, 1, ''N'', :ALMACEN, ' +
    ' :PSIVA, :PIVA, :PCIVA, :TOTAL, NOW(), :USUARIO, :USUARIO)';
end;

procedure TPedidosPrestaShopEscrituras.InsertarLineaGastosTransporte(
  AConsulta: TUniQuery;
  const AEntrada: TEntradaPedidoPrestaShop;
  const APortes: TPortesPedidoPrestaShop);
begin
  AConsulta.ParamByName('NUMERO').AsString := AEntrada.Numero;
  AConsulta.ParamByName('SERIE').AsString := AEntrada.Serie;
  AConsulta.ParamByName('LINEA').AsString := Format('%.4d',
    [(AEntrada.Pedido.LineasPedido.Count + 1) * 10]);
  AConsulta.ParamByName('ARTICULO').AsString :=
    CODIGO_ARTICULO_GASTOS_TRANSPORTE;
  AConsulta.ParamByName('SKU').AsString := CODIGO_SKU_GASTOS_TRANSPORTE;
  AConsulta.ParamByName('DESCRIPCION').AsString :=
    DESCRIPCION_GASTOS_TRANSPORTE;
  AConsulta.ParamByName('ALMACEN').AsString := AEntrada.Almacen;
  AConsulta.ParamByName('PSIVA').AsCurrency := APortes.PrecioSinIva;
  AConsulta.ParamByName('PIVA').AsFloat := APortes.PorcentajeIva;
  AConsulta.ParamByName('PCIVA').AsCurrency := APortes.PrecioConIva;
  AConsulta.ParamByName('TOTAL').AsCurrency := APortes.PrecioSinIva;
  AConsulta.ParamByName('USUARIO').AsString := FUsuario;
  AConsulta.Execute;
end;

procedure TPedidosPrestaShopEscrituras.ConfigurarMensajes(
  AConsulta: TUniQuery);
begin
  AConsulta.SQL.Text :=
    'INSERT INTO fza_pedidos_mensajes (IDPS_MENSAJES_PEDMSG, ' +
    ' IDMENSAJEPS_PEDMSG, IDEMPLEADOPS_PEDMSG, MENSAJEPS_PEDMSG, ' +
    ' FECHAPS_PEDMSG, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:HILO, :IDM, :IDE, :MSG, :FECHA, NOW(), :USU, :USU)';
end;

procedure TPedidosPrestaShopEscrituras.InsertarMensajes(
  AConsulta: TUniQuery;
  APedido: TOrder);
var
  oMensaje: TMensaje;
begin
  for oMensaje in APedido.MensajesPedido.LMensajes do
  begin
    AConsulta.ParamByName('HILO').AsString :=
      APedido.MensajesPedido.idCustomer_Threat;
    AConsulta.ParamByName('IDM').AsString := oMensaje.idMensaje;
    AConsulta.ParamByName('IDE').AsString := oMensaje.idEmpleado;
    AConsulta.ParamByName('MSG').AsString := oMensaje.Texto;
    AConsulta.ParamByName('FECHA').AsDateTime := oMensaje.InstanteMsg;
    AConsulta.ParamByName('USU').AsString := FUsuario;
    try
      AConsulta.Execute;
    except
      on E: Exception do
      begin
        if Assigned(FRegistroLog) then
          FRegistroLog.RegistrarInformacion(
            'ImportarPedidoPrestaShop: mensaje ' + oMensaje.idMensaje +
            ' no guardado: ' + E.Message);
        raise;
      end;
    end;
  end;
end;

procedure TPedidosPrestaShopEscrituras.Ejecutar(
  const AEntrada: TEntradaPedidoPrestaShop);
var
  oCabecera: TUniQuery;
  oAuxiliar: TUniQuery;
  oLineas: TUniQuery;
  oLineaPortes: TUniQuery;
  oMensajes: TUniQuery;
  oLecturas: ILecturasImpuestos;
  oImpuestos: TPorcentajesImpuestos;
  oPortes: TPortesPedidoPrestaShop;
  bHayImportePortes: Boolean;
  bTieneImpuestos: Boolean;
  EsTransaccionPropia: Boolean;
begin
  oCabecera := nil;
  oAuxiliar := nil;
  oLineas := nil;
  oLineaPortes := nil;
  oMensajes := nil;
  try
    oCabecera := TUniQuery.Create(nil);
    oAuxiliar := TUniQuery.Create(nil);
    oLineas := TUniQuery.Create(nil);
    oLineaPortes := TUniQuery.Create(nil);
    oMensajes := TUniQuery.Create(nil);
    oCabecera.Connection := FConexion;
    oAuxiliar.Connection := FConexion;
    oLineas.Connection := FConexion;
    oLineaPortes.Connection := FConexion;
    oMensajes.Connection := FConexion;
    oLecturas := CrearLecturasImpuestos(FConexion);
    oImpuestos := Default(TPorcentajesImpuestos);
    bTieneImpuestos := oLecturas.LeerPorEmpresaEnFecha(
      AEntrada.Empresa,
      AEntrada.Pedido.FechaCreacionDateTime,
      oImpuestos);
    bHayImportePortes :=
      (Abs(AEntrada.Pedido.TotalPortesSIVA) >= 0.005) or
      (Abs(AEntrada.Pedido.TotalPortesCIVA) >= 0.005);
    if not bTieneImpuestos then
      raise EPortesPedidoPrestaShop.Create(
        SErrorConfiguracionIvaPedidoPrestaShopNoEncontrada);
    oPortes := Default(TPortesPedidoPrestaShop);
    if bHayImportePortes then
      oPortes := PrepararPortesPedidoPrestaShop(
        AEntrada.Pedido.TotalPortesSIVA,
        AEntrada.Pedido.TotalPortesCIVA,
        oImpuestos.IvaNormal);
    ConfigurarCabecera(oCabecera);
    ConfigurarLineas(oLineas);
    ConfigurarLineaGastosTransporte(oLineaPortes);
    ConfigurarMensajes(oMensajes);
    EsTransaccionPropia := not FConexion.InTransaction;
    if EsTransaccionPropia then
      FConexion.StartTransaction;
    try
      if oPortes.DebeInsertarse then
        AsegurarArticuloGastosTransporte(oAuxiliar);
      AsignarCabecera(
        oCabecera, AEntrada, oImpuestos, bTieneImpuestos);
      oCabecera.Execute;
      InsertarLineas(oLineas, AEntrada, oLecturas,
        oImpuestos, bTieneImpuestos);
      if oPortes.DebeInsertarse then
        InsertarLineaGastosTransporte(
          oLineaPortes, AEntrada, oPortes);
      InsertarMensajes(oMensajes, AEntrada.Pedido);
      if EsTransaccionPropia then
        FConexion.Commit;
    except
      if EsTransaccionPropia and FConexion.InTransaction then
        FConexion.Rollback;
      raise;
    end;
  finally
    oLecturas := nil;
    FreeAndNil(oMensajes);
    FreeAndNil(oLineaPortes);
    FreeAndNil(oLineas);
    FreeAndNil(oAuxiliar);
    FreeAndNil(oCabecera);
  end;
end;

end.
