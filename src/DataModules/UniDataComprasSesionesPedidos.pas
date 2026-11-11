{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataComprasSesionesPedidos                                }
{    Tipo:       Repositorio                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Persistencia de pedidos creados desde una sesión de compra.               }
{******************************************************************************}
unit UniDataComprasSesionesPedidos;

interface

uses
  Uni,
  inLibComprasSesionesIntf,
  inLibComprasSesionesLecturasIntf,
  inLibComprasSesionesMaterializacionIntf,
  UniDataComprasSesiones;

function MaterializarPedidoSesion(
  ADM: TdmComprasSesiones;
  AConexion: TUniConnection;
  const ALecturas: TLecturasPedidosMaterializacion;
  const AUsuario, ASerie, AAlmacen: string):
  TDocumentoMaterializado;

implementation
uses
  inLibComprasImpuestos, inLibRedondeo,
  System.SysUtils,
  Data.DB, DBAccess,
  inLibMsgCompras,
  UniDataComprasSesionesArticulos, UniDataComprasSesionesColores,
  UniDataComprasSesionesDocumentosComun,
  UniDataComprasSesionesOperaciones;
procedure InsertarPedidoCompraCabecera(AConn: TUniConnection;
                                        ADM: TdmComprasSesiones;
                                        const ASeriePedc, ANumPedc,
                                              AUsuario: string;
                                        const ACodigoAlmOverride: string = '');
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'INSERT INTO fza_pedidos_compra ' +
      '  (NUMERO_PEDC, SERIE_PEDC, FECHA_PEDC, ESTADO_PEDC, ' +
      '   CODIGO_EMP_PEDC, RAZON_SOCIAL_EMPRESA_PEDC, NIF_EMPRESA_PEDC, ' +
      '   MOVIL_EMPRESA_PEDC, EMAIL_EMPRESA_PEDC, ' +
      '   DIRECCION1_EMPRESA_PEDC, DIRECCION2_EMPRESA_PEDC, ' +
      '   POBLACION_EMPRESA_PEDC, PROVINCIA_EMPRESA_PEDC, ' +
      '   CODIGO_PAI_EMPRESA_PEDC, NOMBRE_PAI_EMPRESA_PEDC, ' +
      '   CODIGO_POSTAL_EMPRESA_PEDC, ' +
      '   ESIVA_RECARGO_COMPRAS_PEDC, ' +
      '   ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ' +
      '   CODIGO_PRV_PEDC, RAZON_SOCIAL_PRV_PEDC, NIF_PRV_PEDC, ' +
      '   MOVIL_PRV_PEDC, EMAIL_PRV_PEDC, ' +
      '   DIRECCION1_PRV_PEDC, DIRECCION2_PRV_PEDC, ' +
      '   POBLACION_PRV_PEDC, PROVINCIA_PRV_PEDC, ' +
      '   CODIGO_POSTAL_PRV_PEDC, ' +
      '   REF_PROVEEDOR_PEDC, FORMA_PAGO_PEDC, CODIGO_ALM_PEDC, ' +
      '   ID_PV_TEMPORADA_PEDC, FECHA_TOPE_RECEPCION_PEDC, ' +
      '   TOTAL_BRUTO_PEDC, PORCENTAJE_DTO_COMERCIAL_PEDC, ' +
      '   TOTAL_DTO_COMERCIAL_PEDC, PORCENTAJE_DTO_FINANCIERO_PEDC, ' +
      '   TOTAL_DTO_FINANCIERO_PEDC, TOTAL_BASES_PEDC, ' +
      '   TOTAL_IMPUESTOS_PEDC, TOTAL_LIQUIDO_PEDC, ' +
      '   CONTADOR_LINEAS_PEDC, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
      'SELECT :npedc, :spedc, S.FECHA_SES, ''ABIERTO'', ' +
      '       E.CODIGO_EMP_EMP, E.RAZON_SOCIAL_EMP, E.NIF_EMP, ' +
      '       E.MOVIL_EMP, E.EMAIL_EMP, ' +
      '       E.DIRECCION1_EMP, E.DIRECCION2_EMP, ' +
      '       E.POBLACION_EMP, E.PROVINCIA_EMP, ' +
      '       E.CODIGO_PAI_EMP, E.NOMBRE_PAI_EMP, ' +
      '       E.CODIGO_POSTAL_EMP, ' +
      '       IFNULL(S.ESIVA_RECARGO_COMPRAS_SES, ' +
      '              IFNULL(E.ESIVA_RECARGO_COMPRAS_EMP, ''N'')), ' +
      '       IFNULL(S.ESIVA_EXENTO_INTRACOMUNITARIO_SES, ''N''), ' +
      '       P.CODIGO_PRV_PRV, P.RAZON_SOCIAL_PRV, P.NIF_PRV, ' +
      '       P.MOVIL_PRV, P.EMAIL_PRV, ' +
      '       P.DIRECCION1_PRV, P.DIRECCION2_PRV, ' +
      '       P.POBLACION_PRV, P.PROVINCIA_PRV, ' +
      '       P.CODIGO_POSTAL_PRV, ' +
      '       S.REF_PRV_SES, NULLIF(:forma_pago, ''''), ' +
      '       CASE WHEN :alm_ovr <> '''' THEN :alm_ovr ELSE S.CODIGO_ALM_SES ' +
      'END, ' +
      '       S.ID_PV_TEMPORADA_SES, S.FECHA_TOPE_RECEPCION_SES, ' +
      '       0, IFNULL(S.PORCENTAJE_DTO_COMERCIAL_SES, 0), ' +
      '       0, IFNULL(S.PORCENTAJE_DTO_FINANCIERO_SES, 0), ' +
      '       0, 0, 0, 0, ''0'', ' +
      '       NOW(), :u, NOW(), :u ' +
      '  FROM fza_compras_sesiones S ' +
      '  LEFT JOIN fza_empresas E    ON E.CODIGO_EMP_EMP = S.CODIGO_EMP_SES ' +
      '  LEFT JOIN fza_proveedores P ON P.CODIGO_PRV_PRV = S.CODIGO_PRV_SES ' +
      ' WHERE S.SERIE_SES = :s AND S.NUMERO_SES = :n';
    q.ParamByName('npedc').AsString := ANumPedc;
    q.ParamByName('spedc').AsString := ASeriePedc;
    q.ParamByName('s').AsString :=
      ADM.unqryTablaG.FieldByName('SERIE_SES').AsString;
    q.ParamByName('n').AsString :=
      ADM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    q.ParamByName('u').AsString := AUsuario;
    q.ParamByName('alm_ovr').AsString := ACodigoAlmOverride;
    // Usar el valor aceptado en el dialogo, ya aplicado a la cabecera.
    q.ParamByName('forma_pago').AsString := Trim(
      ADM.unqryTablaG.FieldByName('FORMA_PAGO_SES').AsString);
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

procedure InsertarLineaPedidoCompra(AConn: TUniConnection;
                                     const ASeriePedc, ANumPedc,
                                           ALineaPedc, ACodigoArt,
                                           ACodigoSku, ACodigoFam,
                                           ANombreFam, ADescripcion,
                                           ACodigoAlm, ATipoIva,
                                           ARefPrv, AColorTexto,
                                           ALote, AUsuario: string;
                                      ACaducidad: TDateTime;
                                     ACantidad, APrecio,
                                     APorIva, ADescuento: Double;
                                     AIdAcPivot: Integer);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'INSERT INTO fza_pedidos_compra_lineas ' +
      '  (NUMERO_PEDC_PEDCLIN, SERIE_PEDC_PEDCLIN, LINEA_PEDCLIN, ' +
      '   CODIGO_ART_PEDCLIN, CODIGO_UNIDAD_PEDCLIN, REF_PRV_PEDCLIN, ' +
      '   ID_AC_PIVOT_PEDCLIN, ' +
      '   CODIGO_FAM_PEDCLIN, NOMBRE_FAM_PEDCLIN, COLOR_TEXTO_PEDCLIN, ' +
      '   DESCRIPCION_ARTICULO_PEDCLIN, TIPO_CANTIDAD_ARTICULO_PEDCLIN, ' +
      '   CANTIDAD_PEDCLIN, CANTIDAD_RECIBIDA_PEDCLIN, ' +
      '   TIPO_IVA_ARTICULO_PEDCLIN, PORCENTAJE_IVA_PEDCLIN, ' +
      '   PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN, ' +
      '   PRECIO_COMPRA_CIVA_ARTICULO_PEDCLIN, ' +
      '   PORCENTAJE_DTO_PEDCLIN, ' +
      '   TOTAL_PEDCLIN, CODIGO_ALMACEN_PEDCLIN, ' +
      '   LOTE_PEDCLIN, CADUCIDAD_PEDCLIN, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
      'VALUES (:n, :s, :l, :art, :sku, :refprv, :acpivot, ' +
      '        :fam, :nomfam, :coltxt, :desc, ''Uds'', ' +
      '        :cant, 0, :tiva, :piva, :pre, :preciva, :dto, :tot, :alm, ' +
      '        :LOTE, :CADUCIDAD, NOW(), :u, NOW(), :u)';
    q.ParamByName('n').AsString    := ANumPedc;
    q.ParamByName('s').AsString    := ASeriePedc;
    q.ParamByName('l').AsString    := ALineaPedc;
    q.ParamByName('art').AsString  := ACodigoArt;
    q.ParamByName('sku').AsString  := ACodigoSku;
    if ARefPrv <> '' then
      q.ParamByName('refprv').AsString := ARefPrv
    else
      q.ParamByName('refprv').Clear;
    if AIdAcPivot > 0 then
      q.ParamByName('acpivot').AsInteger := AIdAcPivot
    else
      q.ParamByName('acpivot').Clear;
    q.ParamByName('fam').AsString  := ACodigoFam;
    q.ParamByName('nomfam').AsString := ANombreFam;
    if AColorTexto <> '' then
      q.ParamByName('coltxt').AsString := AColorTexto
    else
      q.ParamByName('coltxt').Clear;
    q.ParamByName('desc').AsString := ADescripcion;
    q.ParamByName('cant').AsFloat  := ACantidad;
    q.ParamByName('tiva').AsString := ATipoIva;
    q.ParamByName('piva').AsFloat  := APorIva;
    q.ParamByName('pre').AsFloat   := APrecio;
    q.ParamByName('dto').AsFloat := ADescuento;
    q.ParamByName('preciva').AsFloat :=
      CalcularPrecioNetoCompra(APrecio, ADescuento) *
      (1 + APorIva / 100);
    q.ParamByName('tot').AsFloat := RedondearACentimos(
      ACantidad * CalcularPrecioNetoCompra(APrecio, ADescuento));
    q.ParamByName('alm').AsString  := ACodigoAlm;
    q.ParamByName('u').AsString    := AUsuario;
    q.ParamByName('LOTE').AsString := ALote;
    if ACaducidad = 0 then
      q.ParamByName('CADUCIDAD').Clear
    else
      q.ParamByName('CADUCIDAD').AsDateTime := ACaducidad;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

// Espejo de InsertarLineasAlbaranCompra: itera celdas de la sesion
// agrupadas por (SKU, almacen) y crea una linea en
// fza_pedidos_compra_lineas por cada combinacion con cantidad > 0.
// LINEA_PEDCLIN se asigna secuencial (0010, 0020, ...).
procedure InsertarLineasPedidoCompra(AConn: TUniConnection;
                                      ADM: TdmComprasSesiones;
                                      const ALecturas:
                                      TLecturasPedidosMaterializacion;
                                      const ASerieSes, ANumSes,
                                            ASeriePedc, ANumPedc,
                                            AUsuario: string;
                                      const AFiltroAlmacen: string = '');
var
  oLineas: TLineasDocumentoCompraMaterializacion;
  sCodigoArt, sCodigoSku, sCodigoAlm, sCodigoAlmCab,
  sDescripcion, sCodigoFam, sNombreFam, sTipoIva,
  sLineaPedc, sValorPestana: string;
  iIdAvPivot, iIdAvFila, iIdAcPivot, iLineaSeq: Integer;
  iIndice: Integer;
  rCantidad, rCoste, rPorIva: Double;
begin
  sCodigoAlmCab := ADM.unqryTablaG.FieldByName('CODIGO_ALM_SES').AsString;
  if sCodigoAlmCab = '' then
    raise Exception.Create(SErrorAlmacenSesionParaPedidoCompra);
  iLineaSeq := 0;
  // FZ-ISSUE-425: el pedido no mueve stock; el lote llega con la mercancía.
  oLineas := ConsultarLineasDocumentoCompra(
    ALecturas.Documentos,
    ASerieSes,
    ANumSes,
    sCodigoAlmCab,
    AFiltroAlmacen,
    False);
  for iIndice := 0 to High(oLineas) do
  begin
    sCodigoArt := oLineas[iIndice].CodigoArticulo;
    iIdAvPivot := oLineas[iIndice].IdAvPivot;
    iIdAcPivot := oLineas[iIndice].IdAcPivot;
    sCodigoAlm := oLineas[iIndice].Almacen;
    rCantidad := oLineas[iIndice].Cantidad;
    rCoste := oLineas[iIndice].PrecioCompra;
    sDescripcion := oLineas[iIndice].Descripcion;
    sCodigoFam := oLineas[iIndice].CodigoFamilia;
    sTipoIva := oLineas[iIndice].TipoIva;
    rPorIva := 0;
    iIdAvFila := 0;
    if (Trim(oLineas[iIndice].CodigoColor) <> '') or
       (Trim(oLineas[iIndice].ColorTexto) <> '') then
      iIdAvFila := ResolverIdAvColorLinea(
        AConn,
        ALecturas.Articulos,
        sCodigoArt,
        oLineas[iIndice].ColorTexto,
        oLineas[iIndice].CodigoColor,
        AUsuario,
        sCodigoSku);
    sCodigoSku := ResolverCodigoSku(
      ALecturas.Articulos,
      sCodigoArt,
      iIdAvPivot,
      iIdAvFila,
      ResolverIdAvPestanaLinea(AConn, sCodigoArt,
        oLineas[iIndice].PestanaTexto, AUsuario, sValorPestana));
    if sCodigoSku = '' then
      raise Exception.CreateFmt(SErrorSkuSesionNoEncontrado,
        [sCodigoArt, oLineas[iIndice].ColorTexto, iIdAvPivot]);
    if sCodigoSku <> '' then
    begin
      sNombreFam := '';
      iLineaSeq := iLineaSeq + 1;
      sLineaPedc := Format('%.4d', [iLineaSeq * 10]);
      InsertarLineaPedidoCompra(
        AConn,
        ASeriePedc,
        ANumPedc,
        sLineaPedc,
        sCodigoArt,
        sCodigoSku,
        sCodigoFam,
        sNombreFam,
        sDescripcion,
        sCodigoAlm,
        sTipoIva,
        oLineas[iIndice].ReferenciaProveedor,
        oLineas[iIndice].ColorTexto,
        oLineas[iIndice].Lote,
        AUsuario,
        oLineas[iIndice].Caducidad,
        rCantidad,
        rCoste,
        rPorIva,
        oLineas[iIndice].PorcentajeDto,
        iIdAcPivot);
    end;
  end;
end;

procedure AsignarIvaCabeceraPedidoCompra(AConn: TUniConnection;
                                          const ASeriePedc, ANumPedc: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'UPDATE fza_pedidos_compra C ' +
      '  JOIN vi_ivas_empresa V ' +
      '    ON V.CODIGO_EMP_EMP = C.CODIGO_EMP_PEDC ' +
      '   AND V.ESDEFAULT_IVA_IVAGRP = ''S'' ' +
      '   SET C.CODIGO_IVA_PEDC      = V.CODIGO_IVA, ' +
      '       C.PORCENTAJE_IVAN_PEDC = CASE WHEN ' +
      'IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ''N'') = ''S'' THEN 0 ' +
      'ELSE V.PORCENTAJE_NORMAL_IVA END, ' +
      '       C.PORCENTAJE_IVAR_PEDC = CASE WHEN ' +
      'IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ''N'') = ''S'' THEN 0 ' +
      'ELSE V.PORCENTAJE_REDUCIDO_IVA END, ' +
      '       C.PORCENTAJE_IVAS_PEDC = CASE WHEN ' +
      'IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ''N'') = ''S'' THEN 0 ' +
      'ELSE V.PORCENTAJE_SUPERREDUCIDO_IVA END, ' +
      '       C.PORCENTAJE_IVAE_PEDC = 0, ' +
      '       C.PORCENTAJE_REN_PEDC  = CASE WHEN ' +
      'IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ''N'') = ''S'' THEN 0 ' +
      'ELSE V.PORCENTAJE_NORMAL_RE_IVA END, ' +
      '       C.PORCENTAJE_RER_PEDC  = CASE WHEN ' +
      'IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ''N'') = ''S'' THEN 0 ' +
      'ELSE V.PORCENTAJE_REDUCIDO_RE_IVA END, ' +
      '       C.PORCENTAJE_RES_PEDC  = CASE WHEN ' +
      'IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ''N'') = ''S'' THEN 0 ' +
      'ELSE V.PORCENTAJE_SUPERREDUCIDO_RE_IVA END, ' +
      '       C.PORCENTAJE_REE_PEDC  = CASE WHEN ' +
      'IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ''N'') = ''S'' THEN 0 ' +
      'ELSE V.PORCENTAJE_EXENTO_RE_IVA END ' +
      ' WHERE C.NUMERO_PEDC = :n AND C.SERIE_PEDC = :s';
    q.ParamByName('n').AsString := ANumPedc;
    q.ParamByName('s').AsString := ASeriePedc;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

procedure RellenarIvaLineasPedidoCompra(AConn: TUniConnection;
                                         const ASeriePedc, ANumPedc: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'UPDATE fza_pedidos_compra_lineas L ' +
      '  JOIN fza_pedidos_compra C ' +
      '    ON C.NUMERO_PEDC = L.NUMERO_PEDC_PEDCLIN ' +
      '   AND C.SERIE_PEDC  = L.SERIE_PEDC_PEDCLIN ' +
      '   SET L.TIPO_IVA_ARTICULO_PEDCLIN = ' +
      '         CASE WHEN IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ' +
      '''N'') = ''S'' ' +
      '              THEN ''E'' ELSE L.TIPO_IVA_ARTICULO_PEDCLIN END, ' +
      '       L.PORCENTAJE_IVA_PEDCLIN = ' +
      '         CASE WHEN IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ' +
      '''N'') = ''S'' ' +
      '              THEN 0 ELSE CASE L.TIPO_IVA_ARTICULO_PEDCLIN ' +
      '          WHEN ''N'' THEN IFNULL(C.PORCENTAJE_IVAN_PEDC, 0) ' +
      '          WHEN ''R'' THEN IFNULL(C.PORCENTAJE_IVAR_PEDC, 0) ' +
      '          WHEN ''S'' THEN IFNULL(C.PORCENTAJE_IVAS_PEDC, 0) ' +
      '          WHEN ''E'' THEN IFNULL(C.PORCENTAJE_IVAE_PEDC, 0) ' +
      '          ELSE 0 END END, ' +
      '       L.PRECIO_COMPRA_CIVA_ARTICULO_PEDCLIN = ' +
      '         L.PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN * ' +
      '         (1 - IFNULL(L.PORCENTAJE_DTO_PEDCLIN, 0) / 100) * ' +
      '         (1 + ' +
      '           CASE WHEN IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ' +
      '''N'') = ''S'' ' +
      '                THEN 0 ELSE CASE L.TIPO_IVA_ARTICULO_PEDCLIN ' +
      '            WHEN ''N'' THEN IFNULL(C.PORCENTAJE_IVAN_PEDC, 0) ' +
      '            WHEN ''R'' THEN IFNULL(C.PORCENTAJE_IVAR_PEDC, 0) ' +
      '            WHEN ''S'' THEN IFNULL(C.PORCENTAJE_IVAS_PEDC, 0) ' +
      '            WHEN ''E'' THEN IFNULL(C.PORCENTAJE_IVAE_PEDC, 0) ' +
      '            ELSE 0 END END / 100) ' +
      ' WHERE L.NUMERO_PEDC_PEDCLIN = :n AND L.SERIE_PEDC_PEDCLIN = :s';
    q.ParamByName('n').AsString := ANumPedc;
    q.ParamByName('s').AsString := ASeriePedc;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

procedure RecalcularTotalesPedidoCompra(AConn: TUniConnection;
                                         const ASeriePedc, ANumPedc: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'UPDATE fza_pedidos_compra C ' +
      '  JOIN ( ' +
      '       SELECT NUMERO_PEDC_PEDCLIN, SERIE_PEDC_PEDCLIN, ' +
      '              IFNULL(SUM(L.TOTAL_PEDCLIN), 0) AS BASE, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_PEDCLIN = ' +
      '''N'' THEN L.TOTAL_PEDCLIN ELSE 0 END), 0) AS BASE_N, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_PEDCLIN = ' +
      '''R'' THEN L.TOTAL_PEDCLIN ELSE 0 END), 0) AS BASE_R, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_PEDCLIN = ' +
      '''S'' THEN L.TOTAL_PEDCLIN ELSE 0 END), 0) AS BASE_S, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_PEDCLIN = ' +
      '''E'' THEN L.TOTAL_PEDCLIN ELSE 0 END), 0) AS BASE_E, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_PEDCLIN = ' +
      '''N'' THEN L.TOTAL_PEDCLIN * L.PORCENTAJE_IVA_PEDCLIN / 100 ELSE 0 ' +
      'END), 0) AS IVA_N, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_PEDCLIN = ' +
      '''R'' THEN L.TOTAL_PEDCLIN * L.PORCENTAJE_IVA_PEDCLIN / 100 ELSE 0 ' +
      'END), 0) AS IVA_R, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_PEDCLIN = ' +
      '''S'' THEN L.TOTAL_PEDCLIN * L.PORCENTAJE_IVA_PEDCLIN / 100 ELSE 0 ' +
      'END), 0) AS IVA_S, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_PEDCLIN = ' +
      '''E'' THEN L.TOTAL_PEDCLIN * L.PORCENTAJE_IVA_PEDCLIN / 100 ELSE 0 ' +
      'END), 0) AS IVA_E, ' +
      '              IFNULL(SUM(CASE WHEN ' +
      'IFNULL(H.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ''N'') <> ''S'' AND ' +
      'IFNULL(H.ESIVA_RECARGO_COMPRAS_PEDC, ''N'') = ''S'' AND ' +
      'L.TIPO_IVA_ARTICULO_PEDCLIN = ''N'' THEN ' +
      'L.TOTAL_PEDCLIN * IFNULL(V.PORCENTAJE_NORMAL_RE_IVA, 0) / 100 ELSE 0 ' +
      'END), 0) AS RE_N, ' +
      '              IFNULL(SUM(CASE WHEN ' +
      'IFNULL(H.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ''N'') <> ''S'' AND ' +
      'IFNULL(H.ESIVA_RECARGO_COMPRAS_PEDC, ''N'') = ''S'' AND ' +
      'L.TIPO_IVA_ARTICULO_PEDCLIN = ''R'' THEN ' +
      'L.TOTAL_PEDCLIN * IFNULL(V.PORCENTAJE_REDUCIDO_RE_IVA, 0) / 100 ELSE ' +
      '0 END), 0) AS RE_R, ' +
      '              IFNULL(SUM(CASE WHEN ' +
      'IFNULL(H.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ''N'') <> ''S'' AND ' +
      'IFNULL(H.ESIVA_RECARGO_COMPRAS_PEDC, ''N'') = ''S'' AND ' +
      'L.TIPO_IVA_ARTICULO_PEDCLIN = ''S'' THEN ' +
      'L.TOTAL_PEDCLIN * IFNULL(V.PORCENTAJE_SUPERREDUCIDO_RE_IVA, 0) / 100 ' +
      'ELSE 0 END), 0) AS RE_S, ' +
      '              IFNULL(SUM(CASE WHEN ' +
      'IFNULL(H.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ''N'') <> ''S'' AND ' +
      'IFNULL(H.ESIVA_RECARGO_COMPRAS_PEDC, ''N'') = ''S'' AND ' +
      'L.TIPO_IVA_ARTICULO_PEDCLIN = ''E'' THEN ' +
      'L.TOTAL_PEDCLIN * IFNULL(V.PORCENTAJE_EXENTO_RE_IVA, 0) / 100 ELSE 0 ' +
      'END), 0) AS RE_E, ' +
      '              COUNT(*) AS NLIN ' +
      '         FROM fza_pedidos_compra_lineas L ' +
      '         JOIN fza_pedidos_compra H ' +
      '           ON H.NUMERO_PEDC = L.NUMERO_PEDC_PEDCLIN ' +
      '          AND H.SERIE_PEDC = L.SERIE_PEDC_PEDCLIN ' +
      '         LEFT JOIN fza_ivas V ON V.CODIGO_IVA = H.CODIGO_IVA_PEDC ' +
      '        WHERE L.NUMERO_PEDC_PEDCLIN = :n ' +
      '          AND L.SERIE_PEDC_PEDCLIN  = :s ' +
      '        GROUP BY NUMERO_PEDC_PEDCLIN, SERIE_PEDC_PEDCLIN) AS T ' +
      '    ON T.NUMERO_PEDC_PEDCLIN = C.NUMERO_PEDC ' +
      '   AND T.SERIE_PEDC_PEDCLIN  = C.SERIE_PEDC ' +
      '   SET C.TOTAL_BASEI_IVAN_PEDC = T.BASE_N * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100), ' +
      '       C.TOTAL_BASEI_IVAR_PEDC = T.BASE_R * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100), ' +
      '       C.TOTAL_BASEI_IVAS_PEDC = T.BASE_S * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100), ' +
      '       C.TOTAL_BASEI_IVAE_PEDC = T.BASE_E * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100), ' +
      '       C.TOTAL_IVAN_PEDC = T.IVA_N * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100), ' +
      '       C.TOTAL_IVAR_PEDC = T.IVA_R * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100), ' +
      '       C.TOTAL_IVAS_PEDC = T.IVA_S * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100), ' +
      '       C.TOTAL_IVAE_PEDC = T.IVA_E * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100), ' +
      '       C.TOTAL_REN_PEDC = T.RE_N * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100), ' +
      '       C.TOTAL_RER_PEDC = T.RE_R * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100), ' +
      '       C.TOTAL_RES_PEDC = T.RE_S * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100), ' +
      '       C.TOTAL_REE_PEDC = T.RE_E * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100), ' +
      '       C.TOTAL_BRUTO_PEDC = T.BASE, ' +
      '       C.TOTAL_DTO_COMERCIAL_PEDC = T.BASE - T.BASE * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100), ' +
      '       C.TOTAL_DTO_FINANCIERO_PEDC = T.BASE * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100) * ' +
      'IFNULL(C.PORCENTAJE_DTO_FINANCIERO_PEDC, 0) / 100, ' +
      '       C.TOTAL_BASES_PEDC = T.BASE * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100), ' +
      '       C.TOTAL_RETENCION_PEDC = T.BASE * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100) * ' +
      'IFNULL(C.PORCENTAJE_RETENCION_PEDC, 0) / 100, ' +
      '       C.TOTAL_IMPUESTOS_PEDC = (T.IVA_N + T.IVA_R + T.IVA_S + ' +
      'T.IVA_E + T.RE_N + T.RE_R + T.RE_S + T.RE_E) * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100), ' +
      '       C.TOTAL_LIQUIDO_PEDC = T.BASE * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100) ' +
      '+ (T.IVA_N + T.IVA_R + T.IVA_S + T.IVA_E + T.RE_N + T.RE_R + T.RE_S + ' +
      'T.RE_E) * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100) - T.BASE * ' +
      'GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100) * ' +
      'IFNULL(C.PORCENTAJE_RETENCION_PEDC, 0) / 100 - T.BASE ' +
      '* GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100) * ' +
      'IFNULL(C.PORCENTAJE_DTO_FINANCIERO_PEDC, 0) / 100, ' +
      '       C.CONTADOR_LINEAS_PEDC = LPAD(T.NLIN * 10, 8, ''0'') ' +
      ' WHERE C.NUMERO_PEDC = :n AND C.SERIE_PEDC = :s';
    q.ParamByName('n').AsString := ANumPedc;
    q.ParamByName('s').AsString := ASeriePedc;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

// ---------------------------------------------------------------------------
// Pendiente de recibir (pedido de compra, no toca movimientos)
// ---------------------------------------------------------------------------
// Itera fza_compras_sesiones_celdas con cantidad > 0 y crea una fila por
// (SKU, almacen, doc) en fza_articulos_pdte_recibir. NO genera
// movimientos en fza_movimientos_almacen: el stock fisico no cambia,
// solo se acumula compromiso futuro. Cuando el pedido se reciba (futuro
// flujo de albaran), tocara borrar la fila correspondiente y entonces
// si crear el movimiento de entrada.
//
// ASerieSes/ANumSes son los de la sesion (para resolver lineas y celdas).
// ASerieDoc/ANumDoc son los del pedido generado (van como SERIE_DOC_PDR /
// NUMERO_DOC_PDR de la tabla).
procedure InsertarPendienteRecibirSesion(
  AQuery: TUniQuery;
  const ACodigoSku, ACodigoAlmacen, ASerieDocumento,
        ANumeroDocumento, ACodigoArticulo, ACodigoProveedor,
        ACodigoEmpresa, AUsuario: string;
  ALinea: Integer;
  ACantidad, APrecio: Double;
  AFechaPedido: TDateTime);
begin
  AQuery.SQL.Text :=
    'INSERT IGNORE INTO fza_articulos_pdte_recibir ' +
    '  (CODIGO_UNIDAD_PDR, CODIGO_ALM_PDR, SERIE_DOC_PDR, ' +
    '   NUMERO_DOC_PDR, LINEA_PDR, CODIGO_ART_PDR, ' +
    '   CODIGO_PRV_PDR, CODIGO_EMP_PDR, CANTIDAD_PDR, ' +
    '   PRECIO_COMPRA_PDR, FECHA_PEDIDO_PDR, ' +
    '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, ' +
    '   USUARIO_MODIF) ' +
    'VALUES (:sku, :alm, :s, :n, :l, :art, :prv, :emp, ' +
    '        :qty, :pre, :fped, NOW(), :u, NOW(), :u) ' +
    'ON DUPLICATE KEY UPDATE CANTIDAD_PDR = :qty, ' +
    '  PRECIO_COMPRA_PDR = :pre, FECHA_PEDIDO_PDR = :fped, ' +
    '  INSTANTE_MODIF = NOW(), USUARIO_MODIF = :u';
  AQuery.ParamByName('sku').AsString := ACodigoSku;
  AQuery.ParamByName('alm').AsString := ACodigoAlmacen;
  AQuery.ParamByName('s').AsString := ASerieDocumento;
  AQuery.ParamByName('n').AsString := ANumeroDocumento;
  AQuery.ParamByName('l').AsInteger := ALinea;
  AQuery.ParamByName('art').AsString := ACodigoArticulo;
  AQuery.ParamByName('prv').AsString := ACodigoProveedor;
  AQuery.ParamByName('emp').AsString := ACodigoEmpresa;
  AQuery.ParamByName('qty').AsFloat := ACantidad;
  AQuery.ParamByName('pre').AsFloat := APrecio;
  AQuery.ParamByName('fped').AsDateTime := AFechaPedido;
  AQuery.ParamByName('u').AsString := AUsuario;
  AQuery.ExecSQL;
end;

procedure ProcesarPendienteRecibirSesion(
  const ALecturas: TLecturasPedidosMaterializacion;
  const APendiente: TPendienteRecibirMaterializacion;
  AOperacion: TUniQuery;
  const ASerieDocumento, ANumeroDocumento,
        ACodigoProveedor, ACodigoEmpresa, AUsuario: string;
  AFechaPedido: TDateTime);
var
  sCodigoArticulo: string;
  sCodigoSku: string;
  ValorColor: string;
  ValorPestana: string;
  iIdFila: Integer;
begin
  if APendiente.TipoLinea <> 'SERVICIO' then
  begin
    if APendiente.AccionDuplicado = 'REUSAR' then
      sCodigoArticulo := APendiente.CodigoArticuloReusar
    else
      sCodigoArticulo := APendiente.CodigoArticuloTentativo;
    iIdFila := APendiente.IdAvFila;
    if (Trim(APendiente.ColorTexto) <> '') or
       (Trim(APendiente.CodigoColor) <> '') then
      iIdFila := ResolverIdAvColorLinea(AOperacion.Connection,
        ALecturas.Articulos, sCodigoArticulo, APendiente.ColorTexto,
        APendiente.CodigoColor, AUsuario, ValorColor);
    sCodigoSku := ResolverCodigoSku(
      ALecturas.Articulos,
      sCodigoArticulo,
      APendiente.IdAvPivot,
      iIdFila,
      ResolverIdAvPestanaLinea(AOperacion.Connection, sCodigoArticulo,
        APendiente.PestanaTexto, AUsuario, ValorPestana));
    if sCodigoSku = '' then
      raise Exception.CreateFmt(SErrorSkuSesionNoEncontrado,
        [sCodigoArticulo, APendiente.ColorTexto, APendiente.IdAvPivot]);
    if sCodigoSku <> '' then
      InsertarPendienteRecibirSesion(
        AOperacion,
        sCodigoSku,
        APendiente.Almacen,
        ASerieDocumento,
        ANumeroDocumento,
        sCodigoArticulo,
        ACodigoProveedor,
        ACodigoEmpresa,
        AUsuario,
        APendiente.Linea,
        APendiente.Cantidad,
        APendiente.PrecioCompra,
        AFechaPedido);
  end;
end;

procedure GenerarPedidoPdteRecibir(AConn: TUniConnection;
                                    ADM: TdmComprasSesiones;
                                    const ALecturas:
                                    TLecturasPedidosMaterializacion;
                                    const ASerieSes, ANumSes,
                                          ASerieDoc, ANumDoc,
                                          AUsuario: string);
var
  oPendientes: TPendientesRecibirMaterializacion;
  qIns: TUniQuery;
  sCodigoAlmCab: string;
  sCodigoEmpresa: string;
  sCodigoProveedor: string;
  dFechaPedido: TDateTime;
  iPendiente: Integer;
begin
  sCodigoAlmCab :=
    ADM.unqryTablaG.FieldByName('CODIGO_ALM_SES').AsString;
  if sCodigoAlmCab = '' then
    raise Exception.Create(
      SErrorAlmacenSesionParaPendienteRecibir);
  sCodigoEmpresa :=
    ADM.unqryTablaG.FieldByName('CODIGO_EMP_SES').AsString;
  sCodigoProveedor :=
    ADM.unqryTablaG.FieldByName('CODIGO_PRV_SES').AsString;
  dFechaPedido := Date;
  if not ADM.unqryTablaG.FieldByName('FECHA_SES').IsNull then
    dFechaPedido :=
      ADM.unqryTablaG.FieldByName('FECHA_SES').AsDateTime;
  oPendientes := ALecturas.Pendientes.ConsultarPendientesRecibir(
    ASerieSes,
    ANumSes,
    sCodigoAlmCab);
  qIns := TUniQuery.Create(nil);
  try
    qIns.Connection := AConn;
    for iPendiente := 0 to High(oPendientes) do
    begin
      ProcesarPendienteRecibirSesion(
        ALecturas,
        oPendientes[iPendiente],
        qIns,
        ASerieDoc,
        ANumDoc,
        sCodigoProveedor, sCodigoEmpresa, AUsuario,
        dFechaPedido);
    end;
  finally
    FreeAndNil(qIns);
  end;
end;

// ---------------------------------------------------------------------------

procedure RegistrarPedidoSesion(
  ADM: TdmComprasSesiones;
  AConexion: TUniConnection;
  const ASeriePedido, ANumeroPedido,
  AAlmacen, AUsuario: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConexion;
    q.SQL.Text :=
      'INSERT IGNORE INTO fza_compras_sesiones_documentos ' +
      '  (SERIE_SES_SESDOC, NUMERO_SES_SESDOC, TIPO_DOC_SESDOC, ' +
      '   CODIGO_ALM_SESDOC, CODIGO_EMP_SESDOC, ' +
      '   SERIE_SESDOC, NUMERO_SESDOC, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA) ' +
      'SELECT :s, :n, ''PEDC'', ' +
      '       CASE WHEN :alm_ovr <> '''' THEN :alm_ovr ' +
      '            ELSE S.CODIGO_ALM_SES END, ' +
      '       S.CODIGO_EMP_SES, :sd, :nd, NOW(), :u ' +
      '  FROM fza_compras_sesiones S ' +
      ' WHERE S.SERIE_SES = :s AND S.NUMERO_SES = :n';
    q.ParamByName('s').AsString :=
      ADM.unqryTablaG.FieldByName('SERIE_SES').AsString;
    q.ParamByName('n').AsString :=
      ADM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    q.ParamByName('alm_ovr').AsString := AAlmacen;
    q.ParamByName('sd').AsString := ASeriePedido;
    q.ParamByName('nd').AsString := ANumeroPedido;
    q.ParamByName('u').AsString := AUsuario;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

function MaterializarPedidoSesion(
  ADM: TdmComprasSesiones;
  AConexion: TUniConnection;
  const ALecturas: TLecturasPedidosMaterializacion;
  const AUsuario, ASerie, AAlmacen: string):
  TDocumentoMaterializado;
var
  sEmpresa: string;
  sNumeroSesion: string;
  sSerieSesion: string;
begin
  Result := Default(TDocumentoMaterializado);
  sSerieSesion :=
    ADM.unqryTablaG.FieldByName('SERIE_SES').AsString;
  sNumeroSesion :=
    ADM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
  Result.Tipo := 'Pedido';
  Result.Serie := Trim(ASerie);
  if Result.Serie = '' then
    Result.Serie := sSerieSesion;
  sEmpresa :=
    ADM.unqryTablaG.FieldByName('CODIGO_EMP_SES').AsString;
  Result.Numero := ReservarNumeroDocumentoSesion(
    AConexion, 'PC', sEmpresa, Result.Serie, AUsuario);
  if Result.Numero = '' then
    raise Exception.Create(Format(SErrorContadorPedidoCompra,
      [Result.Serie, sEmpresa]));
  Result.Almacen := AAlmacen;
  InsertarPedidoCompraCabecera(
    AConexion,
    ADM,
    Result.Serie,
    Result.Numero,
    AUsuario,
    AAlmacen);
  InsertarLineasPedidoCompra(
    AConexion,
    ADM,
    ALecturas,
    sSerieSesion,
    sNumeroSesion,
    Result.Serie,
    Result.Numero,
    AUsuario,
    AAlmacen);
  AsignarIvaCabeceraPedidoCompra(
    AConexion,
    Result.Serie,
    Result.Numero);
  RellenarIvaLineasPedidoCompra(
    AConexion,
    Result.Serie,
    Result.Numero);
  RecalcularTotalesPedidoCompra(
    AConexion,
    Result.Serie,
    Result.Numero);
  GenerarPedidoPdteRecibir(
    AConexion,
    ADM,
    ALecturas,
    sSerieSesion,
    sNumeroSesion,
    Result.Serie,
    Result.Numero,
    AUsuario);
  RegistrarPedidoSesion(
    ADM,
    AConexion,
    Result.Serie,
    Result.Numero,
    AAlmacen,
    AUsuario);
end;

end.
