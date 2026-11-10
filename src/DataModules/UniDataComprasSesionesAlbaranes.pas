{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataComprasSesionesAlbaranes                              }
{    Tipo:       Repositorio                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Persistencia de albaranes creados desde una sesión de compra.             }
{******************************************************************************}
unit UniDataComprasSesionesAlbaranes;

interface

uses
  Uni,
  inLibComprasSesionesIntf,
  inLibComprasSesionesLecturasIntf,
  inLibComprasSesionesMaterializacionIntf,
  UniDataComprasSesiones;

function MaterializarAlbaranSesion(
  ADM: TdmComprasSesiones;
  AConexion: TUniConnection;
  const ALecturas: TLecturasAlbaranesMaterializacion;
  const AUsuario, ASerie, AAlmacen: string;
  AHoraMovimiento: TDateTime):
  TDocumentoMaterializado;

implementation
uses
  inLibComprasImpuestos, inLibRedondeo,
  System.SysUtils,
  Data.DB, DBAccess,
  inLibAlbaranesCompraMovimientos,
  UniDataAlbaranesCompraMovimientos, inLibMsgCompras,
  UniDataComprasSesionesArticulos, UniDataComprasSesionesColores,
  UniDataComprasSesionesDocumentosComun, UniDataComprasSesionesOperaciones,
  inLibTrazabilidad;

const
  // F-LOTEC-013: líneas del albarán creado sin lote de artículos trazables.
  SQL_LINEAS_SIN_LOTE_ALBARAN =
    'SELECT L.LINEA_ALBCLIN, L.CODIGO_UNIDAD_ALBCLIN, ' +
    'A.TIPO_TRAZABILIDAD_ART ' +
    'FROM fza_albaranes_compra_lineas L ' +
    'JOIN fza_articulos A ON A.CODIGO_ART_ART = L.CODIGO_ART_ALBCLIN ' +
    'WHERE L.SERIE_ALBC_ALBCLIN = :SERIE ' +
    'AND L.NUMERO_ALBC_ALBCLIN = :NUMERO ' +
    'AND COALESCE(L.LOTE_ALBCLIN, '''') = '''' ' +
    'AND A.TIPO_TRAZABILIDAD_ART <> ''NINGUNA''';
// Los lotes y series pendientes se completan en la pantalla del albarán.
function PrepararLotesAlbaranMaterializado(AConn: TUniConnection;
  const AActivacion: TActivacionTrazabilidad;
  const ASerie, ANumero: string): Integer;
var
  oConsulta: TUniQuery;
  oModo: TModoTrazabilidad;
begin
  Result := 0;
  if AActivacion.AlgunModoActivo then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConn;
      oConsulta.SQL.Text := SQL_LINEAS_SIN_LOTE_ALBARAN;
      oConsulta.ParamByName('SERIE').AsString := ASerie;
      oConsulta.ParamByName('NUMERO').AsString := ANumero;
      oConsulta.Open;
      while not oConsulta.Eof do
      begin
        oModo := AActivacion.ModoEfectivo(ModoDesdeCadena(
          oConsulta.FieldByName('TIPO_TRAZABILIDAD_ART').AsString));
        if RequiereLote(oModo) then
          Inc(Result);
        oConsulta.Next;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;
// Un lote asignado expresamente no se pierde por los parametros del
// usuario que materializa. La activacion se limita a este documento.
function ActivacionConLotesAsignados(AConexion: TUniConnection;
  const AConfigurada: TActivacionTrazabilidad;
  const ASerie, ANumero: string): TActivacionTrazabilidad;
var
  oConsulta: TUniQuery;
begin
  Result := AConfigurada;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'SELECT DISTINCT A.TIPO_TRAZABILIDAD_ART ' +
      'FROM fza_albaranes_compra_lineas L ' +
      'JOIN fza_articulos A ON A.CODIGO_ART_ART = L.CODIGO_ART_ALBCLIN ' +
      'WHERE L.SERIE_ALBC_ALBCLIN = :SERIE ' +
      'AND L.NUMERO_ALBC_ALBCLIN = :NUMERO ' +
      'AND COALESCE(TRIM(L.LOTE_ALBCLIN), '''') <> ''''';
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      case ModoDesdeCadena(oConsulta.Fields[0].AsString) of
        mtLote: Result.Lotes := True;
        mtSerie: Result.Series := True;
      end;
      oConsulta.Next;
    end;
  finally
    oConsulta.Free;
  end;
end;

procedure InsertarAlbaranCompraCabecera(AConn: TUniConnection;
                                         ADM: TdmComprasSesiones;
                                         const ASerieAlbc, ANumAlbc,
                                               AUsuario: string;
                                         AHoraMovimiento: TDateTime;
                                         const ACodigoAlmOverride: string = '');
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'INSERT INTO fza_albaranes_compra ' +
      '  (NUMERO_ALBC, SERIE_ALBC, FECHA_ALBC, INSTANTE_MOVIMIENTO_ALBC, ' +
      '   ESTADO_ALBC, ' +
      '   CODIGO_EMP_ALBC, RAZON_SOCIAL_EMPRESA_ALBC, NIF_EMPRESA_ALBC, ' +
      '   MOVIL_EMPRESA_ALBC, EMAIL_EMPRESA_ALBC, ' +
      '   DIRECCION1_EMPRESA_ALBC, DIRECCION2_EMPRESA_ALBC, ' +
      '   POBLACION_EMPRESA_ALBC, PROVINCIA_EMPRESA_ALBC, ' +
      '   CODIGO_PAI_EMPRESA_ALBC, NOMBRE_PAI_EMPRESA_ALBC, ' +
      '   CODIGO_POSTAL_EMPRESA_ALBC, ' +
      '   ESIVA_RECARGO_COMPRAS_ALBC, ' +
      '   ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ' +
      '   CODIGO_PRV_ALBC, RAZON_SOCIAL_PRV_ALBC, NIF_PRV_ALBC, ' +
      '   MOVIL_PRV_ALBC, EMAIL_PRV_ALBC, ' +
      '   DIRECCION1_PRV_ALBC, DIRECCION2_PRV_ALBC, ' +
      '   POBLACION_PRV_ALBC, PROVINCIA_PRV_ALBC, ' +
      '   CODIGO_POSTAL_PRV_ALBC, ' +
      '   REF_PROVEEDOR_ALBC, FORMA_PAGO_ALBC, ' +
      '   ID_PV_TEMPORADA_ALBC, CODIGO_ALM_ALBC, ' +
      '   TOTAL_BRUTO_ALBC, PORCENTAJE_DTO_COMERCIAL_ALBC, ' +
      '   TOTAL_DTO_COMERCIAL_ALBC, PORCENTAJE_DTO_FINANCIERO_ALBC, ' +
      '   TOTAL_DTO_FINANCIERO_ALBC, TOTAL_BASES_ALBC, ' +
      '   TOTAL_IMPUESTOS_ALBC, TOTAL_LIQUIDO_ALBC, ' +
      '   CONTADOR_LINEAS_ALBC, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
      'SELECT :nalbc, :salbc, S.FECHA_SES, ' +
      '       TIMESTAMP(COALESCE(S.FECHA_SES, CURDATE()), ' +
      '                 IF(:conhora = ''S'', :hora, CURRENT_TIME)), ' +
      '       ''ABIERTO'', E.CODIGO_EMP_EMP, E.RAZON_SOCIAL_EMP, E.NIF_EMP, ' +
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
      '       S.REF_PRV_SES, NULLIF(S.FORMA_PAGO_SES, ''''), ' +
      '       S.ID_PV_TEMPORADA_SES, ' +
      '       CASE WHEN :alm_ovr <> '''' THEN :alm_ovr ELSE S.CODIGO_ALM_SES ' +
      'END, ' +
      '       0, IFNULL(S.PORCENTAJE_DTO_COMERCIAL_SES, 0), ' +
      '       0, IFNULL(S.PORCENTAJE_DTO_FINANCIERO_SES, 0), ' +
      '       0, 0, 0, 0, ''0'', ' +
      '       NOW(), :u, NOW(), :u ' +
      '  FROM fza_compras_sesiones S ' +
      '  LEFT JOIN fza_empresas E    ON E.CODIGO_EMP_EMP = S.CODIGO_EMP_SES ' +
      '  LEFT JOIN fza_proveedores P ON P.CODIGO_PRV_PRV = S.CODIGO_PRV_SES ' +
      ' WHERE S.SERIE_SES = :s AND S.NUMERO_SES = :n';
    q.ParamByName('nalbc').AsString := ANumAlbc;
    q.ParamByName('salbc').AsString := ASerieAlbc;
    q.ParamByName('s').AsString :=
      ADM.unqryTablaG.FieldByName('SERIE_SES').AsString;
    q.ParamByName('n').AsString :=
      ADM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    q.ParamByName('u').AsString := AUsuario;
    q.ParamByName('alm_ovr').AsString := ACodigoAlmOverride;
    // Hora elegida en el diálogo común; negativa = la actual.
    if AHoraMovimiento >= 0 then
      q.ParamByName('conhora').AsString := 'S'
    else
      q.ParamByName('conhora').AsString := 'N';
    q.ParamByName('hora').AsString := FormatDateTime('hh:nn:ss',
      Frac(Abs(AHoraMovimiento)));
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;
// Inserta una linea en fza_albaranes_compra_lineas con SUM(CANTIDAD) por
// (SKU, almacen) agregando todas las celdas que aportan a esa combinacion
// dentro de la linea actual de la sesion. Devuelve la LINEA_ALBCLIN
// asignada (PK secundaria, 4 digitos LPAD).
procedure InsertarLineaAlbaranCompra(AConn: TUniConnection;
                                      const ASerieAlbc, ANumAlbc,
                                            ALineaAlbc, ACodigoArt,
                                            ACodigoSku, ACodigoFam,
                                            ANombreFam, ADescripcion,
                                            ACodigoAlm, ATipoIva,
                                            ARefPrv,
                                            ALote, AUsuario: string;
                                      ACaducidad: TDateTime;
                                      ACantidad, APrecio,
                                      APorcIva, ADescuento: Double;
                                      AIdAcPivot: Integer);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    // ID_AC_PIVOT_ALBCLIN: sistema de tallas heredado de la linea de
    // sesion. Imprescindible para que el modo 'Tallas en horizontal'
    // del Mto sepa que conjunto pivot aplicar — sin el, todas las
    // columnas talla quedan ocultas. Si AIdAcPivot=0 va NULL (linea
    // escalar sin tallaje, p.ej. SERVICIO).
    q.SQL.Text :=
      'INSERT INTO fza_albaranes_compra_lineas ' +
      '  (NUMERO_ALBC_ALBCLIN, SERIE_ALBC_ALBCLIN, LINEA_ALBCLIN, ' +
      '   CODIGO_ART_ALBCLIN, CODIGO_UNIDAD_ALBCLIN, REF_PRV_ALBCLIN, ' +
      '   ID_AC_PIVOT_ALBCLIN, ' +
      '   CODIGO_FAM_ALBCLIN, NOMBRE_FAM_ALBCLIN, ' +
      '   DESCRIPCION_ARTICULO_ALBCLIN, TIPO_CANTIDAD_ARTICULO_ALBCLIN, ' +
      '   CANTIDAD_ALBCLIN, TOTAL_UNIDADES_ALBCLIN, ' +
      '   TIPO_IVA_ARTICULO_ALBCLIN, ' +
      '   PORCENTAJE_IVA_ALBCLIN, ' +
      '   PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN, ' +
      '   PRECIO_COMPRA_CIVA_ARTICULO_ALBCLIN, ' +
      '   PORCENTAJE_DTO_ALBCLIN, ' +
      '   TOTAL_ALBCLIN, CODIGO_ALMACEN_ALBCLIN, ' +
      '   ESFACTURADA_ALBCLIN, ' +
      '   LOTE_ALBCLIN, FECHA_CADUCIDAD_ALBCLIN, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
      'VALUES (:n, :s, :l, :art, :sku, :refprv, :acpivot, ' +
      '        :fam, :nomfam, :desc, ''Uds'', ' +
      '        :cant, :cant, :tiva, :piva, :pre, :preciva, :dto, :tot, :alm, ' +
      '        ''N'', ' +
      '        :LOTE, :CADUCIDAD, NOW(), :u, NOW(), :u)';
    q.ParamByName('n').AsString    := ANumAlbc;
    q.ParamByName('s').AsString    := ASerieAlbc;
    q.ParamByName('l').AsString    := ALineaAlbc;
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
    q.ParamByName('desc').AsString := ADescripcion;
    q.ParamByName('cant').AsFloat  := ACantidad;
    q.ParamByName('tiva').AsString := ATipoIva;
    q.ParamByName('piva').AsFloat  := APorcIva;
    q.ParamByName('pre').AsFloat   := APrecio;
    q.ParamByName('dto').AsFloat := ADescuento;
    q.ParamByName('preciva').AsFloat :=
      CalcularPrecioNetoCompra(APrecio, ADescuento) *
      (1 + APorcIva / 100);
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

// Rellena los % IVA en la CABECERA del albaran desde vi_ivas_empresa
// (resuelve el IVA por defecto del grupo de la empresa de la cabecera).
// El INSERT inicial deja esos campos a 0; la sesion aporta el tipo efectivo,
// pero los porcentajes se resuelven desde el IVA de cabecera.
procedure AsignarIvaCabeceraAlbaranCompra(AConn: TUniConnection;
                                           const ASerieAlbc, ANumAlbc: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'UPDATE fza_albaranes_compra C ' +
      '  JOIN vi_ivas_empresa V ' +
      '    ON V.CODIGO_EMP_EMP = C.CODIGO_EMP_ALBC ' +
      '   AND V.ESDEFAULT_IVA_IVAGRP = ''S'' ' +
      '   SET C.CODIGO_IVA_ALBC      = V.CODIGO_IVA, ' +
      '       C.PORCENTAJE_IVAN_ALBC = CASE WHEN ' +
      'IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') = ''S'' THEN 0 ' +
      'ELSE V.PORCENTAJE_NORMAL_IVA END, ' +
      '       C.PORCENTAJE_IVAR_ALBC = CASE WHEN ' +
      'IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') = ''S'' THEN 0 ' +
      'ELSE V.PORCENTAJE_REDUCIDO_IVA END, ' +
      '       C.PORCENTAJE_IVAS_ALBC = CASE WHEN ' +
      'IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') = ''S'' THEN 0 ' +
      'ELSE V.PORCENTAJE_SUPERREDUCIDO_IVA END, ' +
      '       C.PORCENTAJE_IVAE_ALBC = 0, ' +
      '       C.PORCENTAJE_REN_ALBC  = CASE WHEN ' +
      'IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') = ''S'' THEN 0 ' +
      'ELSE V.PORCENTAJE_NORMAL_RE_IVA END, ' +
      '       C.PORCENTAJE_RER_ALBC  = CASE WHEN ' +
      'IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') = ''S'' THEN 0 ' +
      'ELSE V.PORCENTAJE_REDUCIDO_RE_IVA END, ' +
      '       C.PORCENTAJE_RES_ALBC  = CASE WHEN ' +
      'IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') = ''S'' THEN 0 ' +
      'ELSE V.PORCENTAJE_SUPERREDUCIDO_RE_IVA END, ' +
      '       C.PORCENTAJE_REE_ALBC  = CASE WHEN ' +
      'IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') = ''S'' THEN 0 ' +
      'ELSE V.PORCENTAJE_EXENTO_RE_IVA END ' +
      ' WHERE C.NUMERO_ALBC = :n AND C.SERIE_ALBC = :s';
    q.ParamByName('n').AsString := ANumAlbc;
    q.ParamByName('s').AsString := ASerieAlbc;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

// Rellena PORCENTAJE_IVA_ALBCLIN y PRECIO_COMPRA_CIVA en las lineas
// del albaran a partir de los porcentajes que viven en la cabecera
// (PORCENTAJE_IVAN_ALBC, _IVAR_ALBC, _IVAS_ALBC, _IVAE_ALBC), mapeando
// por TIPO_IVA_ARTICULO_ALBCLIN. La sesion origen aporta el tipo efectivo,
// pero InsertarLineaAlbaranCompra inserta el porcentaje a 0 y aqui se
// reconstruye. Llamar SIEMPRE antes de RecalcularTotalesAlbaranCompra
// — los totales suman IVA con este porcentaje. Requiere que la
// cabecera ya tenga los % asignados (AsignarIvaCabeceraAlbaranCompra).
procedure RellenarIvaLineasAlbaranCompra(AConn: TUniConnection;
                                          const ASerieAlbc, ANumAlbc: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'UPDATE fza_albaranes_compra_lineas L ' +
      '  JOIN fza_albaranes_compra C ' +
      '    ON C.NUMERO_ALBC = L.NUMERO_ALBC_ALBCLIN ' +
      '   AND C.SERIE_ALBC  = L.SERIE_ALBC_ALBCLIN ' +
      '   SET L.TIPO_IVA_ARTICULO_ALBCLIN = ' +
      '         CASE WHEN IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ' +
      '''N'') = ''S'' ' +
      '              THEN ''E'' ELSE L.TIPO_IVA_ARTICULO_ALBCLIN END, ' +
      '       L.PORCENTAJE_IVA_ALBCLIN = ' +
      '         CASE WHEN IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ' +
      '''N'') = ''S'' ' +
      '              THEN 0 ELSE CASE L.TIPO_IVA_ARTICULO_ALBCLIN ' +
      '          WHEN ''N'' THEN IFNULL(C.PORCENTAJE_IVAN_ALBC, 0) ' +
      '          WHEN ''R'' THEN IFNULL(C.PORCENTAJE_IVAR_ALBC, 0) ' +
      '          WHEN ''S'' THEN IFNULL(C.PORCENTAJE_IVAS_ALBC, 0) ' +
      '          WHEN ''E'' THEN IFNULL(C.PORCENTAJE_IVAE_ALBC, 0) ' +
      '          ELSE 0 END END, ' +
      '       L.PRECIO_COMPRA_CIVA_ARTICULO_ALBCLIN = ' +
      '         L.PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN * ' +
      '         (1 - IFNULL(L.PORCENTAJE_DTO_ALBCLIN, 0) / 100) * ' +
      '         (1 + ' +
      '           CASE WHEN IFNULL(C.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ' +
      '''N'') = ''S'' ' +
      '                THEN 0 ELSE CASE L.TIPO_IVA_ARTICULO_ALBCLIN ' +
      '            WHEN ''N'' THEN IFNULL(C.PORCENTAJE_IVAN_ALBC, 0) ' +
      '            WHEN ''R'' THEN IFNULL(C.PORCENTAJE_IVAR_ALBC, 0) ' +
      '            WHEN ''S'' THEN IFNULL(C.PORCENTAJE_IVAS_ALBC, 0) ' +
      '            WHEN ''E'' THEN IFNULL(C.PORCENTAJE_IVAE_ALBC, 0) ' +
      '            ELSE 0 END END / 100) ' +
      ' WHERE L.NUMERO_ALBC_ALBCLIN = :n AND L.SERIE_ALBC_ALBCLIN = :s';
    q.ParamByName('n').AsString := ANumAlbc;
    q.ParamByName('s').AsString := ASerieAlbc;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

// Recalcula los totales de la cabecera del albaran a partir de sus
// lineas. Lo llamamos justo despues de insertar todas las lineas para
// no tener que mantener acumuladores en codigo cliente.
procedure RecalcularTotalesAlbaranCompra(AConn: TUniConnection;
                                          const ASerieAlbc, ANumAlbc: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'UPDATE fza_albaranes_compra C ' +
      '  JOIN ( ' +
      '       SELECT NUMERO_ALBC_ALBCLIN, SERIE_ALBC_ALBCLIN, ' +
      '              IFNULL(SUM(L.TOTAL_ALBCLIN), 0) AS BASE, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_ALBCLIN = ' +
      '''N'' THEN L.TOTAL_ALBCLIN ELSE 0 END), 0) AS BASE_N, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_ALBCLIN = ' +
      '''R'' THEN L.TOTAL_ALBCLIN ELSE 0 END), 0) AS BASE_R, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_ALBCLIN = ' +
      '''S'' THEN L.TOTAL_ALBCLIN ELSE 0 END), 0) AS BASE_S, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_ALBCLIN = ' +
      '''E'' THEN L.TOTAL_ALBCLIN ELSE 0 END), 0) AS BASE_E, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_ALBCLIN = ' +
      '''N'' THEN L.TOTAL_ALBCLIN * L.PORCENTAJE_IVA_ALBCLIN / 100 ELSE 0 ' +
      'END), 0) AS IVA_N, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_ALBCLIN = ' +
      '''R'' THEN L.TOTAL_ALBCLIN * L.PORCENTAJE_IVA_ALBCLIN / 100 ELSE 0 ' +
      'END), 0) AS IVA_R, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_ALBCLIN = ' +
      '''S'' THEN L.TOTAL_ALBCLIN * L.PORCENTAJE_IVA_ALBCLIN / 100 ELSE 0 ' +
      'END), 0) AS IVA_S, ' +
      '              IFNULL(SUM(CASE WHEN L.TIPO_IVA_ARTICULO_ALBCLIN = ' +
      '''E'' THEN L.TOTAL_ALBCLIN * L.PORCENTAJE_IVA_ALBCLIN / 100 ELSE 0 ' +
      'END), 0) AS IVA_E, ' +
      '              IFNULL(SUM(CASE WHEN ' +
      'IFNULL(H.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') <> ''S'' AND ' +
      'IFNULL(H.ESIVA_RECARGO_COMPRAS_ALBC, ''N'') = ''S'' AND ' +
      'L.TIPO_IVA_ARTICULO_ALBCLIN = ''N'' THEN ' +
      'L.TOTAL_ALBCLIN * IFNULL(V.PORCENTAJE_NORMAL_RE_IVA, 0) / 100 ELSE 0 ' +
      'END), 0) AS RE_N, ' +
      '              IFNULL(SUM(CASE WHEN ' +
      'IFNULL(H.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') <> ''S'' AND ' +
      'IFNULL(H.ESIVA_RECARGO_COMPRAS_ALBC, ''N'') = ''S'' AND ' +
      'L.TIPO_IVA_ARTICULO_ALBCLIN = ''R'' THEN ' +
      'L.TOTAL_ALBCLIN * IFNULL(V.PORCENTAJE_REDUCIDO_RE_IVA, 0) / 100 ELSE ' +
      '0 END), 0) AS RE_R, ' +
      '              IFNULL(SUM(CASE WHEN ' +
      'IFNULL(H.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') <> ''S'' AND ' +
      'IFNULL(H.ESIVA_RECARGO_COMPRAS_ALBC, ''N'') = ''S'' AND ' +
      'L.TIPO_IVA_ARTICULO_ALBCLIN = ''S'' THEN ' +
      'L.TOTAL_ALBCLIN * IFNULL(V.PORCENTAJE_SUPERREDUCIDO_RE_IVA, 0) / 100 ' +
      'ELSE 0 END), 0) AS RE_S, ' +
      '              IFNULL(SUM(CASE WHEN ' +
      'IFNULL(H.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') <> ''S'' AND ' +
      'IFNULL(H.ESIVA_RECARGO_COMPRAS_ALBC, ''N'') = ''S'' AND ' +
      'L.TIPO_IVA_ARTICULO_ALBCLIN = ''E'' THEN ' +
      'L.TOTAL_ALBCLIN * IFNULL(V.PORCENTAJE_EXENTO_RE_IVA, 0) / 100 ELSE 0 ' +
      'END), 0) AS RE_E, ' +
      '              COUNT(*) AS NLIN ' +
      '         FROM fza_albaranes_compra_lineas L ' +
      '         JOIN fza_albaranes_compra H ' +
      '           ON H.NUMERO_ALBC = L.NUMERO_ALBC_ALBCLIN ' +
      '          AND H.SERIE_ALBC = L.SERIE_ALBC_ALBCLIN ' +
      '         LEFT JOIN fza_ivas V ON V.CODIGO_IVA = H.CODIGO_IVA_ALBC ' +
      '        WHERE L.NUMERO_ALBC_ALBCLIN = :n ' +
      '          AND L.SERIE_ALBC_ALBCLIN  = :s ' +
      '        GROUP BY NUMERO_ALBC_ALBCLIN, SERIE_ALBC_ALBCLIN) AS T ' +
      '    ON T.NUMERO_ALBC_ALBCLIN = C.NUMERO_ALBC ' +
      '   AND T.SERIE_ALBC_ALBCLIN  = C.SERIE_ALBC ' +
      '   SET C.TOTAL_BASEI_IVAN_ALBC = T.BASE_N * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_BASEI_IVAR_ALBC = T.BASE_R * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_BASEI_IVAS_ALBC = T.BASE_S * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_BASEI_IVAE_ALBC = T.BASE_E * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_IVAN_ALBC = T.IVA_N * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_IVAR_ALBC = T.IVA_R * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_IVAS_ALBC = T.IVA_S * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_IVAE_ALBC = T.IVA_E * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_REN_ALBC = T.RE_N * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_RER_ALBC = T.RE_R * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_RES_ALBC = T.RE_S * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_REE_ALBC = T.RE_E * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_BRUTO_ALBC = T.BASE, ' +
      '       C.TOTAL_DTO_COMERCIAL_ALBC = T.BASE - T.BASE * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_DTO_FINANCIERO_ALBC = T.BASE * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100) * ' +
      'IFNULL(C.PORCENTAJE_DTO_FINANCIERO_ALBC, 0) / 100, ' +
      '       C.TOTAL_BASES_ALBC = T.BASE * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_RETENCION_ALBC = T.BASE * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100) * ' +
      'IFNULL(C.PORCENTAJE_RETENCION_ALBC, 0) / 100, ' +
      '       C.TOTAL_IMPUESTOS_ALBC = (T.IVA_N + T.IVA_R + T.IVA_S + ' +
      'T.IVA_E + T.RE_N + T.RE_R + T.RE_S + T.RE_E) * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), ' +
      '       C.TOTAL_LIQUIDO_ALBC = T.BASE * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100) ' +
      '+ (T.IVA_N + T.IVA_R + T.IVA_S + T.IVA_E + T.RE_N + T.RE_R + T.RE_S + ' +
      'T.RE_E) * GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100) - T.BASE * ' +
      'GREATEST(0, 1 - ' +
      'IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100) * ' +
      'IFNULL(C.PORCENTAJE_RETENCION_ALBC, 0) / 100 - T.BASE ' +
      '* GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100) * ' +
      'IFNULL(C.PORCENTAJE_DTO_FINANCIERO_ALBC, 0) / 100, ' +
      '       C.CONTADOR_LINEAS_ALBC = LPAD(T.NLIN * 10, 8, ''0'') ' +
      ' WHERE C.NUMERO_ALBC = :n AND C.SERIE_ALBC = :s';
    q.ParamByName('n').AsString := ANumAlbc;
    q.ParamByName('s').AsString := ASerieAlbc;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

// Itera celdas de la sesion agrupadas por (SKU, almacen) y crea una
// linea en fza_albaranes_compra_lineas por cada combinacion con
// cantidad > 0. LINEA_ALBCLIN se asigna secuencial (010, 020, 030...).
procedure InsertarLineasAlbaranCompra(AConn: TUniConnection;
                                       ADM: TdmComprasSesiones;
                                       const ALecturas:
                                       TLecturasAlbaranesMaterializacion;
                                       const ASerieSes, ANumSes,
                                             ASerieAlbc, ANumAlbc,
                                             AUsuario: string;
                                       const AFiltroAlmacen: string = '');
var
  oLineas: TLineasDocumentoCompraMaterializacion;
  sCodigoArt, sCodigoSku, sCodigoAlm, sCodigoAlmCab,
  sDescripcion, sCodigoFam, sNombreFam, sTipoIva,
  sLineaAlbc, sValorPestana: string;
  iIdAvPivot, iIdAvFila, iIdAcPivot, iLineaSeq: Integer;
  iIndice: Integer;
  rCantidad, rCoste, rPorIva: Double;
begin
  sCodigoAlmCab := ADM.unqryTablaG.FieldByName('CODIGO_ALM_SES').AsString;
  if sCodigoAlmCab = '' then
    raise Exception.Create(SErrorAlmacenSesionParaAlbaranCompra);
  iLineaSeq := 0;
  oLineas := ConsultarLineasDocumentoCompra(
    ALecturas.Documentos,
    ASerieSes,
    ANumSes,
    sCodigoAlmCab,
    AFiltroAlmacen);
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
      sLineaAlbc := Format('%.4d', [iLineaSeq * 10]);
      InsertarLineaAlbaranCompra(
        AConn,
        ASerieAlbc,
        ANumAlbc,
        sLineaAlbc,
        sCodigoArt,
        sCodigoSku,
        sCodigoFam,
        sNombreFam,
        sDescripcion,
        sCodigoAlm,
        sTipoIva,
        oLineas[iIndice].ReferenciaProveedor,
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

// La generacion de movimientos del albaran de compra se ha movido a
// inLibAlbaranesCompraMovimientos.GenerarMovimientosDesdeAlbaranCompra,
// que lee del propio albaran (lineas + celdas) en vez de la sesion
// origen. Asi el flujo es identico tanto si el albaran viene de una
// sesion materializada como si se pica a mano y luego se cierra desde
// el materializador llama directamente a la nueva
// funcion despues de InsertarLineasAlbaranCompra y RecalcularTotales.

// ---------------------------------------------------------------------------
// Pedidos de compra — funciones espejo de las de albaran
// ---------------------------------------------------------------------------
// Mismo patron que InsertarAlbaranCompraCabecera/Lineas/Iva/Totales pero
// escribiendo en fza_pedidos_compra(_lineas). A diferencia del albaran,
// el pedido NO mueve stock fisico: la cantidad pendiente la deposita
// GenerarPedidoPdteRecibir en fza_articulos_pdte_recibir. Las cantidades
// de las lineas son las pedidas; CANTIDAD_RECIBIDA_PEDCLIN nace a 0 y se
// va incrementando cuando se generan albaranes desde el Mto de pedidos
// (inLibPedidosCompra.CrearAlbaranDesdePedido).


procedure RegistrarAlbaranSesion(
  ADM: TdmComprasSesiones;
  AConexion: TUniConnection;
  const ASerieAlbaran, ANumeroAlbaran,
  AUsuario: string);
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
      'SELECT :s, :n, ''ALBC'', ' +
      '       A.CODIGO_ALM_ALBC, A.CODIGO_EMP_ALBC, ' +
      '       :sd, :nd, NOW(), :u ' +
      '  FROM fza_albaranes_compra A ' +
      ' WHERE A.SERIE_ALBC = :sd AND A.NUMERO_ALBC = :nd';
    q.ParamByName('s').AsString :=
      ADM.unqryTablaG.FieldByName('SERIE_SES').AsString;
    q.ParamByName('n').AsString :=
      ADM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    q.ParamByName('sd').AsString := ASerieAlbaran;
    q.ParamByName('nd').AsString := ANumeroAlbaran;
    q.ParamByName('u').AsString := AUsuario;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

procedure CerrarAlbaranMaterializado(
  AConexion: TUniConnection;
  const ASerieAlbaran, ANumeroAlbaran,
  AUsuario: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConexion;
    q.SQL.Text :=
      'UPDATE fza_albaranes_compra SET ' +
      '  ESTADO_ALBC = ''CERRADO'', ' +
      '  INSTANTE_MODIF = NOW(), ' +
      '  USUARIO_MODIF = :u ' +
      ' WHERE SERIE_ALBC = :s AND NUMERO_ALBC = :n';
    q.ParamByName('s').AsString := ASerieAlbaran;
    q.ParamByName('n').AsString := ANumeroAlbaran;
    q.ParamByName('u').AsString := AUsuario;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

function MaterializarAlbaranSesion(
  ADM: TdmComprasSesiones;
  AConexion: TUniConnection;
  const ALecturas: TLecturasAlbaranesMaterializacion;
  const AUsuario, ASerie, AAlmacen: string;
  AHoraMovimiento: TDateTime):
  TDocumentoMaterializado;
var
  sEmpresa: string;
  sNumeroSesion: string;
  sSerieSesion: string;
  rActivacion: TActivacionTrazabilidad;
begin
  Result := Default(TDocumentoMaterializado);
  sSerieSesion :=
    ADM.unqryTablaG.FieldByName('SERIE_SES').AsString;
  sNumeroSesion :=
    ADM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
  Result.Tipo := 'Albaran';
  Result.Serie := Trim(ASerie);
  if Result.Serie = '' then
    Result.Serie := sSerieSesion;
  sEmpresa :=
    ADM.unqryTablaG.FieldByName('CODIGO_EMP_SES').AsString;
  Result.Numero := ReservarNumeroDocumentoSesion(
    AConexion, 'AB', sEmpresa, Result.Serie, AUsuario);
  if Result.Numero = '' then
    raise Exception.Create(Format(SErrorContadorAlbaranCompra,
      [Result.Serie, sEmpresa]));
  Result.Almacen := AAlmacen;
  InsertarAlbaranCompraCabecera(
    AConexion,
    ADM,
    Result.Serie,
    Result.Numero,
    AUsuario,
    AHoraMovimiento,
    AAlmacen);
  InsertarLineasAlbaranCompra(
    AConexion,
    ADM,
    ALecturas,
    sSerieSesion,
    sNumeroSesion,
    Result.Serie,
    Result.Numero,
    AUsuario,
    AAlmacen);
  AsignarIvaCabeceraAlbaranCompra(
    AConexion,
    Result.Serie,
    Result.Numero);
  RellenarIvaLineasAlbaranCompra(
    AConexion,
    Result.Serie,
    Result.Numero);
  RecalcularTotalesAlbaranCompra(
    AConexion,
    Result.Serie,
    Result.Numero);
  rActivacion := ActivacionConLotesAsignados(AConexion,
    ADM.ActivacionTrazabilidad, Result.Serie, Result.Numero);
  Result.LineasSinLote := PrepararLotesAlbaranMaterializado(AConexion,
    rActivacion, Result.Serie, Result.Numero);
  inLibAlbaranesCompraMovimientos.
    GenerarMovimientosDesdeAlbaranCompra(
      CrearMovimientosAlbaranCompraUniDAC(
        AConexion, rActivacion),
      Result.Serie,
      Result.Numero,
      AUsuario);
  CerrarAlbaranMaterializado(
    AConexion,
    Result.Serie,
    Result.Numero,
    AUsuario);
  RegistrarAlbaranSesion(
    ADM,
    AConexion,
    Result.Serie,
    Result.Numero,
    AUsuario);
end;

end.
