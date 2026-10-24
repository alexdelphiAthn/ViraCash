{******************************************************************************}
{                                                                              }
{  Configuracion de persistencia de las consultas de facturas.                 }
{                                                                              }
{******************************************************************************}
unit UniDataFacturasConfiguracion;

interface

uses
  Uni;

type
  TReferenciasFacturaAusentes = record
    Mensaje: string;
    Cliente: Boolean;
    FormaPago: Boolean;
    Almacen: Boolean;
    Lineas: TArray<string>;
    Articulos: TArray<string>;
    Skus: TArray<string>;
  end;

function ConsultarReferenciasFacturaAusentes(AConexion: TUniConnection;
  const ASerie, ANumero: string): TReferenciasFacturaAusentes;

procedure ConfigurarPersistenciaCabeceraFactura(
  AConexion: TUniConnection;
  ACabecera: TUniQuery);
procedure ConfigurarPersistenciaLineasFactura(
  AConexion: TUniConnection;
  ALineas: TUniQuery);

implementation

uses
  System.Classes,
  System.SysUtils,
  inLibSqlSeguro, inLibMsgFacturas;

const
  SQL_REFERENCIAS_FACTURA_AUSENTES =
    'SELECT 0 AS TIPO, f.CODIGO_CLI_FAC AS CODIGO, '''' AS LINEA FROM ' +
    'fza_facturas f WHERE f.SERIE_FAC = :SERIE AND f.NUMERO_FAC = ' +
    ':NUMERO AND TRIM(COALESCE(f.CODIGO_CLI_FAC, '''')) ' +
    'NOT IN ('''', ''0'') AND NOT ' +
    'EXISTS (SELECT 1 FROM fza_clientes r WHERE r.CODIGO_CLI_CLI = ' +
    'f.CODIGO_CLI_FAC) UNION ALL SELECT 1 AS TIPO, f.FORMA_PAGO_FAC ' +
    'AS CODIGO, '''' AS LINEA FROM fza_facturas f WHERE f.SERIE_FAC = ' +
    ':SERIE AND f.NUMERO_FAC = :NUMERO AND ' +
    'TRIM(COALESCE(f.FORMA_PAGO_FAC, '''')) <> '''' AND NOT EXISTS ' +
    '(SELECT 1 FROM fza_formas_pago r WHERE r.CODIGO_FP_FP = ' +
    'f.FORMA_PAGO_FAC) UNION ALL SELECT 2 AS TIPO, f.CODIGO_ALM_FAC ' +
    'AS CODIGO, '''' AS LINEA FROM fza_facturas f WHERE f.SERIE_FAC = ' +
    ':SERIE AND f.NUMERO_FAC = :NUMERO AND ' +
    'TRIM(COALESCE(f.CODIGO_ALM_FAC, '''')) <> '''' AND NOT EXISTS ' +
    '(SELECT 1 FROM fza_almacenes r WHERE r.CODIGO_ALM_ALM = ' +
    'f.CODIGO_ALM_FAC) UNION ALL SELECT 3 AS TIPO, ' +
    'l.CODIGO_ART_FACLIN AS CODIGO, CAST(l.LINEA_FACLIN AS CHAR) AS ' +
    'LINEA FROM fza_facturas_lineas l WHERE l.SERIE_FAC_FACLIN = ' +
    ':SERIE AND l.NUMERO_FAC_FACLIN = :NUMERO AND ' +
    'TRIM(COALESCE(l.CODIGO_ART_FACLIN, '''')) <> '''' AND NOT EXISTS ' +
    '(SELECT 1 FROM fza_articulos a WHERE a.CODIGO_ART_ART = ' +
    'l.CODIGO_ART_FACLIN) UNION ALL SELECT 4 AS TIPO, ' +
    'l.CODIGO_UNIDAD_FACLIN AS CODIGO, CAST(l.LINEA_FACLIN AS CHAR) ' +
    'AS LINEA FROM fza_facturas_lineas l WHERE l.SERIE_FAC_FACLIN = ' +
    ':SERIE AND l.NUMERO_FAC_FACLIN = :NUMERO AND ' +
    'TRIM(COALESCE(l.CODIGO_UNIDAD_FACLIN, '''')) <> '''' AND EXISTS ' +
    '(SELECT 1 FROM fza_articulos a WHERE a.CODIGO_ART_ART = ' +
    'l.CODIGO_ART_FACLIN) AND NOT EXISTS (SELECT 1 FROM ' +
    'fza_articulos_skus sk WHERE sk.CODIGO_UNIDAD_SKU = ' +
    'l.CODIGO_UNIDAD_FACLIN AND sk.CODIGO_ART_SKU = ' +
    'l.CODIGO_ART_FACLIN) ORDER BY TIPO, LINEA, CODIGO';

const
  CAMPOS_COMPLEJOS_CABECERA: array[0..1] of string = (
    'DOCUMENTO_FAC',
    'XML_FAC'
  );

function ConsultarReferenciasFacturaAusentes(AConexion: TUniConnection;
  const ASerie, ANumero: string): TReferenciasFacturaAusentes;
var
  Consulta: TUniQuery;
  Tipo: Integer;
  Etiqueta, Linea, Detalle: string;
begin
  Result := Default(TReferenciasFacturaAusentes);
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := AConexion;
    Consulta.SQL.Text := SQL_REFERENCIAS_FACTURA_AUSENTES;
    Consulta.ParamByName('SERIE').AsString := ASerie;
    Consulta.ParamByName('NUMERO').AsString := ANumero;
    Consulta.Open;
    while not Consulta.Eof do
    begin
      Tipo := Consulta.FieldByName('TIPO').AsInteger;
      Linea := Consulta.FieldByName('LINEA').AsString;
      Etiqueta := '';
      case Tipo of
        0: begin
          Etiqueta := SReferenciaFacturaCliente;
          Result.Cliente := True;
        end;
        1: begin
          Etiqueta := SReferenciaFacturaFormaPago;
          Result.FormaPago := True;
        end;
        2: begin
          Etiqueta := SReferenciaFacturaAlmacen;
          Result.Almacen := True;
        end;
        3: Etiqueta := SReferenciaFacturaArticulo;
        4: Etiqueta := SReferenciaFacturaSku;
      end;
      if Tipo = 3 then
      begin
        SetLength(Result.Articulos, Length(Result.Articulos) + 1);
        Result.Articulos[High(Result.Articulos)] :=
          Consulta.FieldByName('CODIGO').AsString;
      end;
      if Tipo = 4 then
      begin
        SetLength(Result.Skus, Length(Result.Skus) + 1);
        Result.Skus[High(Result.Skus)] :=
          Consulta.FieldByName('CODIGO').AsString;
      end;
      Detalle := Etiqueta + ': ' +
        Consulta.FieldByName('CODIGO').AsString;
      if Linea <> '' then
      begin
        Detalle := Detalle + Format(SReferenciaFacturaLinea, [Linea]);
        SetLength(Result.Lineas, Length(Result.Lineas) + 1);
        Result.Lineas[High(Result.Lineas)] := Linea;
      end;
      if Result.Mensaje = '' then
        Result.Mensaje := SAvisoReferenciasFacturaAusentes;
      Result.Mensaje := Result.Mensaje + sLineBreak + Detalle;
      Consulta.Next;
    end;
  finally
    Consulta.Free;
  end;
end;

procedure QuitarCampoComplejoCabecera(
  ALista: TStrings;
  const ACampo: string);
var
  sCampoSql: string;
  sSQL: string;
begin
  if ALista <> nil then
  begin
    sCampoSql := DelimitarIdentificadorSql(
      ACampo,
      CAMPOS_COMPLEJOS_CABECERA);
    sSQL := ALista.Text;
    sSQL := StringReplace(sSQL,
      ', ' + sCampoSql + ' = :' + sCampoSql,
      '', [rfReplaceAll, rfIgnoreCase]);
    sSQL := StringReplace(sSQL,
      ', ' + sCampoSql,
      '', [rfReplaceAll, rfIgnoreCase]);
    sSQL := StringReplace(sSQL,
      ', :' + sCampoSql,
      '', [rfReplaceAll, rfIgnoreCase]);
    ALista.Text := sSQL;
  end;
end;

procedure PrepararCabeceraSinCamposComplejos(
  AConexion: TUniConnection;
  ACabecera: TUniQuery);
var
  ColumnasPermitidas: TStringList;
  i: Integer;
  qCampos: TUniQuery;
  sCampo: string;
  sCampos: string;
begin
  sCampos := '';
  if AConexion <> nil then
  begin
    ColumnasPermitidas := TStringList.Create;
    qCampos := TUniQuery.Create(nil);
    try
      qCampos.Connection := AConexion;
      qCampos.SQL.Text := 'SHOW COLUMNS FROM vi_facturas';
      qCampos.Open;
      while not qCampos.Eof do
      begin
        sCampo := qCampos.FieldByName('Field').AsString;
        ColumnasPermitidas.Add(sCampo);
        qCampos.Next;
      end;
      i := 0;
      while i < ColumnasPermitidas.Count do
      begin
        sCampo := ColumnasPermitidas[i];
        if (not SameText(sCampo, CAMPOS_COMPLEJOS_CABECERA[0])) and
           (not SameText(sCampo, CAMPOS_COMPLEJOS_CABECERA[1])) then
        begin
          if sCampos <> '' then
            sCampos := sCampos + ', ';
          sCampos := sCampos + DelimitarIdentificadorSql(
            sCampo,
            ColumnasPermitidas);
        end;
        Inc(i);
      end;
    finally
      FreeAndNil(qCampos);
      FreeAndNil(ColumnasPermitidas);
    end;
    if sCampos <> '' then
      ACabecera.SQL.Text :=
        'SELECT ' + sCampos + ' FROM vi_facturas ' +
        ' ORDER BY FECHA_FAC DESC, NUMERO_FAC DESC';
  end;
  QuitarCampoComplejoCabecera(ACabecera.SQLInsert, 'DOCUMENTO_FAC');
  QuitarCampoComplejoCabecera(ACabecera.SQLInsert, 'XML_FAC');
  QuitarCampoComplejoCabecera(ACabecera.SQLUpdate, 'DOCUMENTO_FAC');
  QuitarCampoComplejoCabecera(ACabecera.SQLUpdate, 'XML_FAC');
  QuitarCampoComplejoCabecera(ACabecera.SQLLock, 'DOCUMENTO_FAC');
  QuitarCampoComplejoCabecera(ACabecera.SQLLock, 'XML_FAC');
  QuitarCampoComplejoCabecera(ACabecera.SQLRefresh, 'DOCUMENTO_FAC');
  QuitarCampoComplejoCabecera(ACabecera.SQLRefresh, 'XML_FAC');
end;

function ColumnasSkuLineasAplicadas(AConexion: TUniConnection): Boolean;
var
  qCol: TUniQuery;
begin
  Result := False;
  if AConexion <> nil then
  begin
    qCol := TUniQuery.Create(nil);
    try
      try
        qCol.Connection := AConexion;
        qCol.SQL.Text :=
          'SELECT COUNT(*) AS N ' +
          '  FROM INFORMATION_SCHEMA.COLUMNS ' +
          ' WHERE TABLE_SCHEMA = DATABASE() ' +
          '   AND TABLE_NAME = ''fza_facturas_lineas'' ' +
          '   AND COLUMN_NAME IN (''ATTR1_VALOR_FACLIN'', ' +
          '                       ''NUM_ATRIBUTOS_FACLIN'')';
        qCol.Open;
        Result := qCol.FieldByName('N').AsInteger = 2;
      except
        // Sin migracion se conservan los SQL del DFM.
        Result := False;
      end;
    finally
      FreeAndNil(qCol);
    end;
  end;
end;

procedure ConfigurarPersistenciaCabeceraFactura(
  AConexion: TUniConnection;
  ACabecera: TUniQuery);
begin
  ACabecera.Connection := AConexion;
  ACabecera.KeyFields := 'NUMERO_FAC;SERIE_FAC';
  ACabecera.SQLDelete.Text :=
    'DELETE FROM fza_facturas ' + sLineBreak +
    'WHERE NUMERO_FAC = :Old_NUMERO_FAC ' + sLineBreak +
    '  AND SERIE_FAC = :Old_SERIE_FAC';
  PrepararCabeceraSinCamposComplejos(AConexion, ACabecera);
end;

procedure ConfigurarInsercionLineasFactura(ALineas: TUniQuery);
begin
  ALineas.SQLInsert.Text :=
      'INSERT INTO fza_facturas_lineas ' +
      ' (NUMERO_FAC_FACLIN, SERIE_FAC_FACLIN, LINEA_FACLIN, ' +
      '  CODIGO_ART_FACLIN, CODIGO_UNIDAD_FACLIN, CODIGO_FAM_FACLIN, ' +
      '  NOMBRE_FAM_FACLIN, PRECIO_ULT_COMPRA_FACLIN, CODIGO_PRV_FACLIN, ' +
      '  RAZON_SOCIAL_PROVEEDOR_FACLIN, ESPROVEEDORPRINCIPAL_FACLIN, ' +
      '  FECHA_ENTREGA_FACLIN, TIPO_CANTIDAD_ARTICULO_FACLIN, ' +
      '  ESIMP_INCL_TARIFA_FACLIN, TIPO_IVA_ARTICULO_FACLIN, ' +
      '  DESCRIPCION_ARTICULO_FACLIN, DESCRIPCION_VARIACION_FACLIN, ' +
      '  CODIGO_TAR_FACLIN, CANTIDAD_FACLIN, PRECIO_SALIDA_FACLIN, ' +
      '  PORCENTAJE_DTO_FACLIN, PRECIO_DTO_FACLIN, ' +
      '  PRECIO_VENTA_SIVA_ARTICULO_FACLIN, PORCENTAJE_IVA_FACLIN, ' +
      '  PRECIO_VENTA_CIVA_ARTICULO_FACLIN, TOTAL_FACLIN, ' +
      '  TOTAL_FAC_SIVA_FACLIN, ' +
      '  ATTR1_VALOR_FACLIN, ATTR1_NOMBRE_FACLIN, ' +
      '  ATTR2_VALOR_FACLIN, ATTR2_NOMBRE_FACLIN, ' +
      '  ATTR3_VALOR_FACLIN, ATTR3_NOMBRE_FACLIN, ' +
      '  ATTR4_VALOR_FACLIN, ATTR4_NOMBRE_FACLIN, ' +
      '  ATTR5_VALOR_FACLIN, ATTR5_NOMBRE_FACLIN, ' +
      '  NUM_ATRIBUTOS_FACLIN, CODIGO_ALM_FACLIN, ' +
      '  CODIGO_VENDEDOR_FACLIN, ' +
      '  INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES ' +
      ' (:NUMERO_FAC_FACLIN, :SERIE_FAC_FACLIN, :LINEA_FACLIN, ' +
      '  :CODIGO_ART_FACLIN, :CODIGO_UNIDAD_FACLIN, :CODIGO_FAM_FACLIN, ' +
      '  :NOMBRE_FAM_FACLIN, :PRECIO_ULT_COMPRA_FACLIN, ' +
      '  :CODIGO_PRV_FACLIN, :RAZON_SOCIAL_PROVEEDOR_FACLIN, ' +
      '  :ESPROVEEDORPRINCIPAL_FACLIN, :FECHA_ENTREGA_FACLIN, ' +
      '  :TIPO_CANTIDAD_ARTICULO_FACLIN, :ESIMP_INCL_TARIFA_FACLIN, ' +
      '  :TIPO_IVA_ARTICULO_FACLIN, :DESCRIPCION_ARTICULO_FACLIN, ' +
      '  :DESCRIPCION_VARIACION_FACLIN, :CODIGO_TAR_FACLIN, ' +
      '  :CANTIDAD_FACLIN, :PRECIO_SALIDA_FACLIN, :PORCENTAJE_DTO_FACLIN, ' +
      '  :PRECIO_DTO_FACLIN, :PRECIO_VENTA_SIVA_ARTICULO_FACLIN, ' +
      '  :PORCENTAJE_IVA_FACLIN, :PRECIO_VENTA_CIVA_ARTICULO_FACLIN, ' +
      '  :TOTAL_FACLIN, :TOTAL_FAC_SIVA_FACLIN, ' +
      '  :ATTR1_VALOR_FACLIN, :ATTR1_NOMBRE_FACLIN, ' +
      '  :ATTR2_VALOR_FACLIN, :ATTR2_NOMBRE_FACLIN, ' +
      '  :ATTR3_VALOR_FACLIN, :ATTR3_NOMBRE_FACLIN, ' +
      '  :ATTR4_VALOR_FACLIN, :ATTR4_NOMBRE_FACLIN, ' +
      '  :ATTR5_VALOR_FACLIN, :ATTR5_NOMBRE_FACLIN, ' +
      '  :NUM_ATRIBUTOS_FACLIN, :CODIGO_ALM_FACLIN, ' +
      '  NULLIF(TRIM(:CODIGO_VENDEDOR_FACLIN), ''''), ' +
      '  :INSTANTE_MODIF, :INSTANTE_ALTA, :USUARIO_ALTA, :USUARIO_MODIF)';
end;

procedure ConfigurarActualizacionLineasFactura(ALineas: TUniQuery);
begin
  ALineas.SQLUpdate.Text :=
      'UPDATE fza_facturas_lineas SET ' +
      '  NUMERO_FAC_FACLIN = :NUMERO_FAC_FACLIN, ' +
      '  SERIE_FAC_FACLIN = :SERIE_FAC_FACLIN, ' +
      '  LINEA_FACLIN = :LINEA_FACLIN, ' +
      '  CODIGO_ART_FACLIN = :CODIGO_ART_FACLIN, ' +
      '  CODIGO_UNIDAD_FACLIN = :CODIGO_UNIDAD_FACLIN, ' +
      '  CODIGO_FAM_FACLIN = :CODIGO_FAM_FACLIN, ' +
      '  NOMBRE_FAM_FACLIN = :NOMBRE_FAM_FACLIN, ' +
      '  PRECIO_ULT_COMPRA_FACLIN = :PRECIO_ULT_COMPRA_FACLIN, ' +
      '  CODIGO_PRV_FACLIN = :CODIGO_PRV_FACLIN, ' +
      '  RAZON_SOCIAL_PROVEEDOR_FACLIN = :RAZON_SOCIAL_PROVEEDOR_FACLIN, ' +
      '  ESPROVEEDORPRINCIPAL_FACLIN = :ESPROVEEDORPRINCIPAL_FACLIN, ' +
      '  FECHA_ENTREGA_FACLIN = :FECHA_ENTREGA_FACLIN, ' +
      '  TIPO_CANTIDAD_ARTICULO_FACLIN = :TIPO_CANTIDAD_ARTICULO_FACLIN, ' +
      '  ESIMP_INCL_TARIFA_FACLIN = :ESIMP_INCL_TARIFA_FACLIN, ' +
      '  TIPO_IVA_ARTICULO_FACLIN = :TIPO_IVA_ARTICULO_FACLIN, ' +
      '  DESCRIPCION_ARTICULO_FACLIN = :DESCRIPCION_ARTICULO_FACLIN, ' +
      '  DESCRIPCION_VARIACION_FACLIN = :DESCRIPCION_VARIACION_FACLIN, ' +
      '  CODIGO_TAR_FACLIN = :CODIGO_TAR_FACLIN, ' +
      '  CANTIDAD_FACLIN = :CANTIDAD_FACLIN, ' +
      '  PRECIO_SALIDA_FACLIN = :PRECIO_SALIDA_FACLIN, ' +
      '  PORCENTAJE_DTO_FACLIN = :PORCENTAJE_DTO_FACLIN, ' +
      '  PRECIO_DTO_FACLIN = :PRECIO_DTO_FACLIN, ' +
      '  PRECIO_VENTA_SIVA_ARTICULO_FACLIN = ' +
      '    :PRECIO_VENTA_SIVA_ARTICULO_FACLIN, ' +
      '  PORCENTAJE_IVA_FACLIN = :PORCENTAJE_IVA_FACLIN, ' +
      '  PRECIO_VENTA_CIVA_ARTICULO_FACLIN = ' +
      '    :PRECIO_VENTA_CIVA_ARTICULO_FACLIN, ' +
      '  TOTAL_FACLIN = :TOTAL_FACLIN, ' +
      '  TOTAL_FAC_SIVA_FACLIN = :TOTAL_FAC_SIVA_FACLIN, ' +
      '  ATTR1_VALOR_FACLIN = :ATTR1_VALOR_FACLIN, ' +
      '  ATTR1_NOMBRE_FACLIN = :ATTR1_NOMBRE_FACLIN, ' +
      '  ATTR2_VALOR_FACLIN = :ATTR2_VALOR_FACLIN, ' +
      '  ATTR2_NOMBRE_FACLIN = :ATTR2_NOMBRE_FACLIN, ' +
      '  ATTR3_VALOR_FACLIN = :ATTR3_VALOR_FACLIN, ' +
      '  ATTR3_NOMBRE_FACLIN = :ATTR3_NOMBRE_FACLIN, ' +
      '  ATTR4_VALOR_FACLIN = :ATTR4_VALOR_FACLIN, ' +
      '  ATTR4_NOMBRE_FACLIN = :ATTR4_NOMBRE_FACLIN, ' +
      '  ATTR5_VALOR_FACLIN = :ATTR5_VALOR_FACLIN, ' +
      '  ATTR5_NOMBRE_FACLIN = :ATTR5_NOMBRE_FACLIN, ' +
      '  NUM_ATRIBUTOS_FACLIN = :NUM_ATRIBUTOS_FACLIN, ' +
      // Vendedor de la línea (comisiones): vacío se guarda como NULL.
      '  CODIGO_VENDEDOR_FACLIN = ' +
      '    NULLIF(TRIM(:CODIGO_VENDEDOR_FACLIN), ''''), ' +
      '  INSTANTE_MODIF = :INSTANTE_MODIF, ' +
      '  INSTANTE_ALTA = :INSTANTE_ALTA, ' +
      '  USUARIO_ALTA = :USUARIO_ALTA, ' +
      '  USUARIO_MODIF = :USUARIO_MODIF ' +
      'WHERE NUMERO_FAC_FACLIN = :Old_NUMERO_FAC_FACLIN ' +
      '  AND SERIE_FAC_FACLIN = :Old_SERIE_FAC_FACLIN ' +
      '  AND LINEA_FACLIN = :Old_LINEA_FACLIN';
end;

procedure ConfigurarLecturaBloqueoLineasFactura(ALineas: TUniQuery);
begin
  ALineas.SQLRefresh.Text :=
      'SELECT * FROM fza_facturas_lineas ' +
      ' WHERE NUMERO_FAC_FACLIN = :NUMERO_FAC_FACLIN ' +
      '   AND SERIE_FAC_FACLIN = :SERIE_FAC_FACLIN ' +
      '   AND LINEA_FACLIN = :LINEA_FACLIN';
    ALineas.SQLLock.Text :=
      'SELECT * FROM fza_facturas_lineas ' +
      ' WHERE NUMERO_FAC_FACLIN = :Old_NUMERO_FAC_FACLIN ' +
      '   AND SERIE_FAC_FACLIN = :Old_SERIE_FAC_FACLIN ' +
      '   AND LINEA_FACLIN = :Old_LINEA_FACLIN ' +
      ' FOR UPDATE';
end;

procedure ConfigurarPersistenciaLineasFactura(
  AConexion: TUniConnection;
  ALineas: TUniQuery);
begin
  ALineas.Connection := AConexion;
  if ColumnasSkuLineasAplicadas(AConexion) then
  begin
    ConfigurarInsercionLineasFactura(ALineas);
    ConfigurarActualizacionLineasFactura(ALineas);
    ConfigurarLecturaBloqueoLineasFactura(ALineas);
  end;
end;

end.
