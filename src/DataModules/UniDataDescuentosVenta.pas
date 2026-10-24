{******************************************************************************}
{  Modulo: UniDataDescuentosVenta. Persistencia de descuentos en conversiones.  }
{  Autor: Alejandro Laorden Hidalgo. Fecha: 13/10/2026.                         }
{  SPDX-License-Identifier: MPL-2.0                                            }
{******************************************************************************}
unit UniDataDescuentosVenta;

interface

uses
  Uni;

procedure CopiarDescuentosPedidoAlbaran(AConexion: TUniConnection;
  const ASerie, ANumero, ALineaDesde: string);
procedure CopiarDescuentosAlbaranBorrador(AConexion: TUniConnection;
  const ASerie, ANumero: string);

implementation

uses
  System.SysUtils, Data.DB, inLibVentasImpuestos,
  UniDataImpuestosRepositorio, inLibMsgVentas;

const
  SQL_ORIGEN_PEDIDO_ALBARAN =
    'SELECT COUNT(*) AS LINEAS, COUNT(H.NUMERO_PED) AS COPIADAS, ' +
    'MIN(CASE WHEN H.NUMERO_PED IS NOT NULL THEN ' +
    'COALESCE(H.PORCENTAJE_DTO_COMERCIAL_PED, 0) END) AS COMERCIAL, ' +
    'MAX(CASE WHEN H.NUMERO_PED IS NOT NULL THEN ' +
    'COALESCE(H.PORCENTAJE_DTO_COMERCIAL_PED, 0) END) AS ' +
    'MAX_COMERCIAL, MIN(CASE WHEN H.NUMERO_PED IS NOT NULL THEN ' +
    'COALESCE(H.PORCENTAJE_DTO_FINANCIERO_PED, 0) END) AS FINANCIERO, ' +
    'MAX(CASE WHEN H.NUMERO_PED IS NOT NULL THEN ' +
    'COALESCE(H.PORCENTAJE_DTO_FINANCIERO_PED, 0) END) AS ' +
    'MAX_FINANCIERO FROM fza_albaranes_lineas D LEFT JOIN ' +
    'fza_pedidos_lineas L ON D.NUMERO_PED_ALBLIN = L.NUMERO_PED_PEDLIN ' +
    'AND D.SERIE_PED_ALBLIN = L.SERIE_PED_PEDLIN AND ' +
    'D.LINEA_PED_ALBLIN = L.LINEA_PEDLIN LEFT JOIN fza_pedidos H ON ' +
    'H.SERIE_PED = L.SERIE_PED_PEDLIN AND H.NUMERO_PED = ' +
    'L.NUMERO_PED_PEDLIN WHERE D.SERIE_ALB_ALBLIN = :SERIE AND ' +
    'D.NUMERO_ALB_ALBLIN = :NUMERO';
  SQL_LINEAS_PEDIDO_ALBARAN =
    'UPDATE fza_albaranes_lineas D JOIN fza_pedidos_lineas L ON ' +
    'D.NUMERO_PED_ALBLIN = L.NUMERO_PED_PEDLIN AND D.SERIE_PED_ALBLIN ' +
    '= L.SERIE_PED_PEDLIN AND D.LINEA_PED_ALBLIN = L.LINEA_PEDLIN SET ' +
    'D.PRECIO_SALIDA_ALBLIN = COALESCE(L.PRECIO_SALIDA_PEDLIN, ' +
    'IF(L.ESIMP_INCL_TARIFA_PEDLIN = ''S'', ' +
    'L.PRECIO_VENTA_CIVA_ARTICULO_PEDLIN, ' +
    'L.PRECIO_VENTA_SIVA_ARTICULO_PEDLIN)), D.PORCENTAJE_DTO_ALBLIN = ' +
    'COALESCE(L.PORCENTAJE_DTO_PEDLIN, 0), D.PRECIO_DTO_ALBLIN = ' +
    'COALESCE(L.PRECIO_DTO_PEDLIN, 0) WHERE D.SERIE_ALB_ALBLIN = ' +
    ':SERIE AND D.NUMERO_ALB_ALBLIN = :NUMERO ' +
    'AND D.LINEA_ALBLIN > :DESDE';
  SQL_CABECERA_PEDIDO_ALBARAN =
    'SELECT PORCENTAJE_DTO_COMERCIAL_ALB AS COMERCIAL, ' +
    'PORCENTAJE_DTO_FINANCIERO_ALB AS FINANCIERO FROM fza_albaranes ' +
    'WHERE SERIE_ALB = :SERIE AND NUMERO_ALB = :NUMERO FOR UPDATE';
  SQL_ACTUALIZAR_PEDIDO_ALBARAN =
    'UPDATE fza_albaranes SET PORCENTAJE_DTO_COMERCIAL_ALB = ' +
    ':COMERCIAL, PORCENTAJE_DTO_FINANCIERO_ALB = :FINANCIERO WHERE ' +
    'SERIE_ALB = :SERIE AND NUMERO_ALB = :NUMERO';
  SQL_ORIGEN_ALBARAN_BORRADOR =
    'SELECT COUNT(*) AS LINEAS, COUNT(H.NUMERO_ALB) AS COPIADAS, ' +
    'MIN(CASE WHEN H.NUMERO_ALB IS NOT NULL THEN ' +
    'COALESCE(H.PORCENTAJE_DTO_COMERCIAL_ALB, 0) END) AS COMERCIAL, ' +
    'MAX(CASE WHEN H.NUMERO_ALB IS NOT NULL THEN ' +
    'COALESCE(H.PORCENTAJE_DTO_COMERCIAL_ALB, 0) END) AS ' +
    'MAX_COMERCIAL, MIN(CASE WHEN H.NUMERO_ALB IS NOT NULL THEN ' +
    'COALESCE(H.PORCENTAJE_DTO_FINANCIERO_ALB, 0) END) AS FINANCIERO, ' +
    'MAX(CASE WHEN H.NUMERO_ALB IS NOT NULL THEN ' +
    'COALESCE(H.PORCENTAJE_DTO_FINANCIERO_ALB, 0) END) AS ' +
    'MAX_FINANCIERO FROM fza_facturas_lineas D LEFT JOIN ' +
    'fza_albaranes_lineas L ON D.NUMERO_FAC_FACLIN = ' +
    'L.NUMERO_FAC_ALBLIN AND D.SERIE_FAC_FACLIN = L.SERIE_FAC_ALBLIN ' +
    'AND D.LINEA_FACLIN = L.LINEA_FAC_ALBLIN LEFT JOIN fza_albaranes H ' +
    'ON H.SERIE_ALB = L.SERIE_ALB_ALBLIN AND H.NUMERO_ALB = ' +
    'L.NUMERO_ALB_ALBLIN WHERE D.SERIE_FAC_FACLIN = :SERIE AND ' +
    'D.NUMERO_FAC_FACLIN = :NUMERO';
  SQL_LINEAS_ALBARAN_BORRADOR =
    'UPDATE fza_facturas_lineas D JOIN fza_albaranes_lineas L ON ' +
    'D.NUMERO_FAC_FACLIN = L.NUMERO_FAC_ALBLIN AND D.SERIE_FAC_FACLIN ' +
    '= L.SERIE_FAC_ALBLIN AND D.LINEA_FACLIN = L.LINEA_FAC_ALBLIN SET ' +
    'D.PRECIO_SALIDA_FACLIN = COALESCE(L.PRECIO_SALIDA_ALBLIN, ' +
    'IF(L.ESIMP_INCL_TARIFA_ALBLIN = ''S'', ' +
    'L.PRECIO_VENTA_CIVA_ARTICULO_ALBLIN, ' +
    'L.PRECIO_VENTA_SIVA_ARTICULO_ALBLIN)), D.PORCENTAJE_DTO_FACLIN = ' +
    'COALESCE(L.PORCENTAJE_DTO_ALBLIN, 0), D.PRECIO_DTO_FACLIN = ' +
    'COALESCE(L.PRECIO_DTO_ALBLIN, 0) WHERE D.SERIE_FAC_FACLIN = ' +
    ':SERIE AND D.NUMERO_FAC_FACLIN = :NUMERO';
  SQL_CABECERA_ALBARAN_BORRADOR =
    'SELECT PORCENTAJE_DTO_COMERCIAL_FAC AS COMERCIAL, ' +
    'PORCENTAJE_DTO_FINANCIERO_FAC AS FINANCIERO FROM fza_facturas ' +
    'WHERE SERIE_FAC = :SERIE AND NUMERO_FAC = :NUMERO FOR UPDATE';
  SQL_ACTUALIZAR_ALBARAN_BORRADOR =
    'UPDATE fza_facturas SET PORCENTAJE_DTO_COMERCIAL_FAC = ' +
    ':COMERCIAL, PORCENTAJE_DTO_FINANCIERO_FAC = :FINANCIERO WHERE ' +
    'SERIE_FAC = :SERIE AND NUMERO_FAC = :NUMERO';
  SQL_CABECERA_RECALCULO_ALBARAN =
    'SELECT PORCENTAJE_DTO_COMERCIAL_ALB, TOTAL_DTO_COMERCIAL_ALB, ' +
    'PORCENTAJE_DTO_FINANCIERO_ALB, TOTAL_DTO_FINANCIERO_ALB, ' +
    'NUMERO_ALB, SERIE_ALB, FECHA_ALB, INSTANTE_MOVIMIENTO_ALB, ' +
    'ESCONSOLIDADO_ALB, ESTADO_ALB, NUMERO_PED_ALB, SERIE_PED_ALB, ' +
    'NUMERO_FAC_ALB, SERIE_FAC_ALB, CODIGO_EMP_ALB, CODIGO_ALM_ALB, ' +
    'RAZON_SOCIAL_EMPRESA_ALB, NIF_EMPRESA_ALB, MOVIL_EMPRESA_ALB, ' +
    'EMAIL_EMPRESA_ALB, DIRECCION1_EMPRESA_ALB, ' +
    'DIRECCION2_EMPRESA_ALB, POBLACION_EMPRESA_ALB, ' +
    'PROVINCIA_EMPRESA_ALB, CODIGO_PAI_EMPRESA_ALB, ' +
    'NOMBRE_PAI_EMPRESA_ALB, CODIGO_POSTAL_EMPRESA_ALB, ' +
    'GRUPO_ZONA_IVA_EMPRESA_ALB, ESRETENCIONES_EMPRESA_ALB, ' +
    'ESREGIMENESPECIALAGRICOLA_EMPRESA_ALB, CODIGO_CLI_ALB, ' +
    'RAZON_SOCIAL_CLIENTE_ALB, NIF_CLIENTE_ALB, MOVIL_CLIENTE_ALB, ' +
    'EMAIL_CLIENTE_ALB, DIRECCION1_CLIENTE_ALB, ' +
    'DIRECCION2_CLIENTE_ALB, POBLACION_CLIENTE_ALB, ' +
    'PROVINCIA_CLIENTE_ALB, CODIGO_POSTAL_CLIENTE_ALB, ' +
    'CODIGO_PAI_CLIENTE_ALB, NOMBRE_PAI_CLIENTE_ALB, ' +
    'NOMBRE_CLI_ENVIO_ALB, MOVIL_CLIENTE_ENVIO_ALB, ' +
    'DIRECCION1_CLIENTE_ENVIO_ALB, DIRECCION2_CLIENTE_ENVIO_ALB, ' +
    'POBLACION_CLIENTE_ENVIO_ALB, PROVINCIA_CLIENTE_ENVIO_ALB, ' +
    'CODIGO_POSTAL_CLIENTE_ENVIO_ALB, CODIGO_PAI_CLIENTE_ENVIO_ALB, ' +
    'NOMBRE_PAI_CLIENTE_ENVIO_ALB, TRANSPORTISTA_ALB, CODIGO_IVA_ALB, ' +
    'ESIVA_RECARGO_CLIENTE_ALB, ESIVA_EXENTO_CLIENTE_ALB, ' +
    'ESINTRACOMUNITARIO_CLIENTE_ALB, ESRETENCIONES_CLIENTE_ALB, ' +
    'ESREGIMENESPECIALAGRICOLA_CLIENTE_ALB, ' +
    'TARIFA_ARTICULO_CLIENTE_ALB, ESIMP_INCL_TARIFA_CLIENTE_ALB, ' +
    'ESAPLICA_RE_ZONA_IVA_ALB, PORCENTAJE_REN_ALB, TOTAL_REN_ALB, ' +
    'PORCENTAJE_RER_ALB, TOTAL_RER_ALB, PORCENTAJE_RES_ALB, ' +
    'TOTAL_RES_ALB, PORCENTAJE_REE_ALB, TOTAL_REE_ALB, ' +
    'TOTAL_BASEI_IVAN_ALB, TOTAL_BASEI_IVAR_ALB, TOTAL_BASEI_IVAS_ALB, ' +
    'TOTAL_BASEI_IVAE_ALB, PORCENTAJE_IVAN_ALB, TOTAL_IVAN_ALB, ' +
    'PORCENTAJE_IVAR_ALB, TOTAL_IVAR_ALB, PORCENTAJE_IVAS_ALB, ' +
    'TOTAL_IVAS_ALB, PORCENTAJE_IVAE_ALB, TOTAL_IVAE_ALB, ' +
    'TOTAL_BASES_ALB, TOTAL_IMPUESTOS_ALB, PORCENTAJE_RETENCION_ALB, ' +
    'TOTAL_RETENCION_ALB, TOTAL_LIQUIDO_ALB, FORMA_PAGO_ALB, ' +
    'CONTADOR_LINEAS_ALB, COMENTARIOS_ALB, OBSERVACIONES_ALB, ' +
    'INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF FROM ' +
    'fza_albaranes WHERE SERIE_ALB = :SERIE AND NUMERO_ALB = :NUMERO';
  SQL_LINEAS_RECALCULO_ALBARAN =
    'SELECT NUMERO_ALB_ALBLIN, SERIE_ALB_ALBLIN, LINEA_ALBLIN, ' +
    'CODIGO_ART_ALBLIN, CANTIDAD_ALBLIN, ESIMP_INCL_TARIFA_ALBLIN, ' +
    'PORCENTAJE_IVA_ALBLIN, TIPO_IVA_ARTICULO_ALBLIN, ' +
    'PRECIO_VENTA_SIVA_ARTICULO_ALBLIN, ' +
    'PRECIO_VENTA_CIVA_ARTICULO_ALBLIN, TOTAL_ALBLIN FROM ' +
    'fza_albaranes_lineas WHERE SERIE_ALB_ALBLIN = :SERIE AND ' +
    'NUMERO_ALB_ALBLIN = :NUMERO ORDER BY LINEA_ALBLIN';

function CrearConsulta(AConexion: TUniConnection;
  const ASql, ASerie, ANumero: string): TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  try
    Result.Connection := AConexion;
    Result.SQL.Text := ASql;
    Result.ParamByName('SERIE').AsString := ASerie;
    Result.ParamByName('NUMERO').AsString := ANumero;
  except
    Result.Free;
    raise;
  end;
end;

procedure ValidarDescuentosAgrupados(ACabecera, AOrigen: TDataSet;
  ADestinoConLineas: Boolean);
begin
  if (AOrigen.FieldByName('COMERCIAL').AsFloat <>
      AOrigen.FieldByName('MAX_COMERCIAL').AsFloat) or
     (AOrigen.FieldByName('FINANCIERO').AsFloat <>
      AOrigen.FieldByName('MAX_FINANCIERO').AsFloat) or
     ((ADestinoConLineas or
       (AOrigen.FieldByName('LINEAS').AsInteger <>
        AOrigen.FieldByName('COPIADAS').AsInteger)) and
      ((ACabecera.FieldByName('COMERCIAL').AsFloat <>
        AOrigen.FieldByName('COMERCIAL').AsFloat) or
       (ACabecera.FieldByName('FINANCIERO').AsFloat <>
        AOrigen.FieldByName('FINANCIERO').AsFloat))) then
    raise Exception.Create(SErrorAgruparDescuentosVenta);
end;

procedure CopiarDescuentos(AConexion: TUniConnection;
  const ASerie, ANumero, ASqlCabecera, ASqlOrigen, ASqlLineas,
  ASqlActualizar, ALineaDesde: string);
var
  Cabecera, Origen, Lineas, Actualizar: TUniQuery;
begin
  Cabecera := CrearConsulta(AConexion, ASqlCabecera, ASerie, ANumero);
  Origen := CrearConsulta(AConexion, ASqlOrigen, ASerie, ANumero);
  Lineas := CrearConsulta(AConexion, ASqlLineas, ASerie, ANumero);
  Actualizar := CrearConsulta(AConexion, ASqlActualizar, ASerie, ANumero);
  try
    Cabecera.Open;
    Origen.Open;
    if Origen.FieldByName('COPIADAS').AsInteger > 0 then
    begin
      ValidarDescuentosAgrupados(Cabecera, Origen, ALineaDesde <> '');
      if Lineas.Params.FindParam('DESDE') <> nil then
        Lineas.ParamByName('DESDE').AsString := ALineaDesde;
      Lineas.ExecSQL;
      Actualizar.ParamByName('COMERCIAL').AsFloat :=
        Origen.FieldByName('COMERCIAL').AsFloat;
      Actualizar.ParamByName('FINANCIERO').AsFloat :=
        Origen.FieldByName('FINANCIERO').AsFloat;
      Actualizar.ExecSQL;
    end;
  finally
    Actualizar.Free;
    Lineas.Free;
    Origen.Free;
    Cabecera.Free;
  end;
end;

procedure RecalcularAlbaran(AConexion: TUniConnection;
  const ASerie, ANumero: string);
var
  Cabecera, Lineas: TUniQuery;
begin
  Cabecera := CrearConsulta(AConexion, SQL_CABECERA_RECALCULO_ALBARAN,
    ASerie, ANumero);
  Lineas := CrearConsulta(AConexion, SQL_LINEAS_RECALCULO_ALBARAN,
    ASerie, ANumero);
  try
    Cabecera.UpdatingTable := 'fza_albaranes';
    Cabecera.KeyFields := 'NUMERO_ALB;SERIE_ALB';
    Lineas.UpdatingTable := 'fza_albaranes_lineas';
    Lineas.KeyFields := 'NUMERO_ALB_ALBLIN;SERIE_ALB_ALBLIN;LINEA_ALBLIN';
    Cabecera.Open;
    Lineas.Open;
    CalcularTotalesDocumentoVenta(CrearLecturasImpuestos(AConexion),
      Cabecera, Lineas, 'ALB', 'TOTAL_ALBLIN',
      'TIPO_IVA_ARTICULO_ALBLIN', 'PORCENTAJE_IVA_ALBLIN');
    if Cabecera.State in dsEditModes then
      Cabecera.Post;
  finally
    Lineas.Free;
    Cabecera.Free;
  end;
end;

procedure CopiarDescuentosPedidoAlbaran(AConexion: TUniConnection;
  const ASerie, ANumero, ALineaDesde: string);
begin
  CopiarDescuentos(AConexion, ASerie, ANumero,
    SQL_CABECERA_PEDIDO_ALBARAN, SQL_ORIGEN_PEDIDO_ALBARAN,
    SQL_LINEAS_PEDIDO_ALBARAN, SQL_ACTUALIZAR_PEDIDO_ALBARAN, ALineaDesde);
  RecalcularAlbaran(AConexion, ASerie, ANumero);
end;

procedure CopiarDescuentosAlbaranBorrador(AConexion: TUniConnection;
  const ASerie, ANumero: string);
begin
  CopiarDescuentos(AConexion, ASerie, ANumero,
    SQL_CABECERA_ALBARAN_BORRADOR, SQL_ORIGEN_ALBARAN_BORRADOR,
    SQL_LINEAS_ALBARAN_BORRADOR, SQL_ACTUALIZAR_ALBARAN_BORRADOR, '');
end;

end.
