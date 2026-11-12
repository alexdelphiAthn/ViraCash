inherited dmInventarios: TdmInventarios
  Height = 457
  Width = 1125
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT '
      '   CODIGO_EMP_INV,'
      '   CODIGO_ALM_INV,'
      '   SERIE_INV,'
      '   NUMERO_INV,'
      '   TIPO_DOC_INV,'
      '   FECHA_INV,'
      '   ESTADO_INV,'
      '   DESCRIPCION_INV,'
      '   OBSERVACIONES_INV,'
      '   TOTAL_UNIDADES_DIFERENCIA_INV,'
      '   TOTAL_EUROS_DIFERENCIA_INV,'
      '   ESRECUENTO_REMOTO_INV,'
      '   INSTANTE_ENVIO_RECUENTO_INV,'
      '   INSTANTE_RECOGIDA_RECUENTO_INV,'
      '   ID_RECUENTO_REMOTO_INV,'
      '   INSTANTE_ALTA, INSTANTE_MODIF,'
      '   USUARIO_ALTA,  USUARIO_MODIF'
      'FROM fza_inventarios'
      'ORDER BY FECHA_INV DESC')
    AfterInsert = unqryTablaGAfterInsert
    AfterScroll = unqryTablaGAfterScroll
    Left = 50
    Top = 22
  end
  inherited unqryPerfiles: TUniQuery
    Left = 168
    Top = 22
  end
  inherited dsPerfiles: TDataSource
    Left = 168
  end
  object unqryLineas: TUniQuery
    SQL.Strings = (
      'SELECT *'
      'FROM fza_inventarios_lineas'
      'WHERE CODIGO_EMP_INVLIN  = :EMPRESA'
      '  AND CODIGO_ALM_INVLIN = :ALMACEN'
      '  AND SERIE_INV_INVLIN          = :SERIE'
      '  AND NUMERO_INV_INVLIN            = :NUMERO'
      'ORDER BY LINEA_INVLIN')
    Left = 466
    Top = 22
    ParamData = <
      item
        DataType = ftString
        Name = 'EMPRESA'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'ALMACEN'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'SERIE'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'NUMERO'
        ParamType = ptInput
        Value = nil
      end>
  end
  object udspLineas: TDataSetProvider
    DataSet = unqryLineas
    Options = [poAllowCommandText, poUseQuoteChar]
    Left = 374
    Top = 22
  end
  object cdsLineas: TClientDataSet
    Aggregates = <>
    Params = <>
    ProviderName = 'udspLineas'
    BeforeInsert = cdsLineasBeforeInsert
    AfterEdit = cdsLineasAfterEdit
    AfterCancel = cdsLineasAfterCancel
    BeforePost = cdsLineasBeforePost
    AfterPost = cdsLineasAfterPost
    BeforeDelete = cdsLineasBeforeDelete
    AfterDelete = cdsLineasAfterDelete
    OnCalcFields = cdsLineasCalcFields
    OnNewRecord = cdsLineasNewRecord
    Left = 282
    Top = 22
    object cdsLineasCODIGO_EMPRESA_INVENTARIO_LINEA: TWideStringField
      FieldName = 'CODIGO_EMP_INVLIN'
      Size = 10
    end
    object cdsLineasCODIGO_ALMACEN_INVENTARIO_LINEA: TWideStringField
      FieldName = 'CODIGO_ALM_INVLIN'
      Size = 10
    end
    object cdsLineasSERIE_INVENTARIO_LINEA: TWideStringField
      FieldName = 'SERIE_INV_INVLIN'
    end
    object cdsLineasNRO_INVENTARIO_LINEA: TWideStringField
      FieldName = 'NUMERO_INV_INVLIN'
    end
    object cdsLineasLINEA_INVENTARIO_LINEA: TWideStringField
      FieldName = 'LINEA_INVLIN'
      Size = 8
    end
    object cdsLineasCODIGO_ARTICULO_INVENTARIO_LINEA: TWideStringField
      FieldName = 'CODIGO_ART_INVLIN'
    end
    object cdsLineasCODIGO_UNIDAD_INVENTARIO_LINEA: TWideStringField
      FieldName = 'CODIGO_UNIDAD_INVLIN'
      Size = 50
    end
    object cdsLineasLOTE_INVENTARIO_LINEA: TWideStringField
      FieldName = 'LOTE_INVLIN'
      Size = 50
    end
    object cdsLineasFECHA_CADUCIDAD_INVENTARIO_LINEA: TDateField
      FieldName = 'FECHA_CADUCIDAD_INVLIN'
    end
    object cdsLineasDESCRIPCION_ARTICULO_INVENTARIO_LINEA: TWideStringField
      FieldName = 'DESCRIPCION_ARTICULO_INVLIN'
      Size = 200
    end
    object cdsLineasCANTIDAD_TEORICA_INVENTARIO_LINEA: TFloatField
      FieldName = 'CANTIDAD_TEORICA_INVLIN'
      DisplayFormat = ',0.00'
    end
    object cdsLineasCANTIDAD_FISICA_INVENTARIO_LINEA: TFloatField
      FieldName = 'CANTIDAD_FISICA_INVLIN'
      DisplayFormat = ',0.00'
    end
    object cdsLineasCANTIDAD_DIFERENCIA_INVENTARIO_LINEA: TFloatField
      FieldName = 'CANTIDAD_DIFERENCIA_INVLIN'
      DisplayFormat = '+,0.00;-,0.00'
    end
    object cdsLineasPRECIO_MEDIO_INVENTARIO_LINEA: TFloatField
      FieldName = 'PRECIO_MEDIO_INVLIN'
      DisplayFormat = ',0.0000'
    end
    object cdsLineasPRECIO_MEDIO_NUEVO_INVENTARIO_LINEA: TFloatField
      FieldName = 'PRECIO_MEDIO_NUEVO_INVLIN'
      DisplayFormat = ',0.0000'
    end
    object cdsLineasESPRECIO_MEDIO_CORREGIDO_INVLIN: TWideStringField
      FieldName = 'ESPRECIO_MEDIO_CORREGIDO_INVLIN'
      Size = 1
    end
    object cdsLineasTOTAL_COSTE_DIFERENCIA_LINEA: TFloatField
      FieldName = 'TOTAL_COSTE_DIFERENCIA_INVLIN'
      DisplayFormat = '+,0.00 '#8364';-,0.00 '#8364
    end
    object cdsLineasFECHA_RECUENTO_INVENTARIO_LINEA: TDateTimeField
      FieldName = 'FECHA_RECUENTO_INVLIN'
      DisplayFormat = 'dd/mm/yyyy hh:nn'
    end
    object cdsLineasID_AC_PIVOT_INV_LINEA: TIntegerField
      FieldName = 'ID_AC_PIVOT_INVLIN'
    end
    object cdsLineasNUM_ATRIBUTOS_REQ_INV_LINEA: TIntegerField
      FieldKind = fkInternalCalc
      FieldName = 'NUM_ATRIBUTOS_REQ_INV_LINEA'
    end
    object cdsLineasATTR1_NOMBRE: TWideStringField
      FieldKind = fkInternalCalc
      FieldName = 'ATTR1_NOMBRE'
      Size = 50
    end
    object cdsLineasATTR1_VALOR: TWideStringField
      FieldKind = fkInternalCalc
      FieldName = 'ATTR1_VALOR'
      Size = 50
    end
    object cdsLineasATTR2_NOMBRE: TWideStringField
      FieldKind = fkInternalCalc
      FieldName = 'ATTR2_NOMBRE'
      Size = 50
    end
    object cdsLineasATTR2_VALOR: TWideStringField
      FieldKind = fkInternalCalc
      FieldName = 'ATTR2_VALOR'
      Size = 50
    end
    object cdsLineasATTR3_NOMBRE: TWideStringField
      FieldKind = fkInternalCalc
      FieldName = 'ATTR3_NOMBRE'
      Size = 50
    end
    object cdsLineasATTR3_VALOR: TWideStringField
      FieldKind = fkInternalCalc
      FieldName = 'ATTR3_VALOR'
      Size = 50
    end
    object cdsLineasATTR4_NOMBRE: TWideStringField
      FieldKind = fkInternalCalc
      FieldName = 'ATTR4_NOMBRE'
      Size = 50
    end
    object cdsLineasATTR4_VALOR: TWideStringField
      FieldKind = fkInternalCalc
      FieldName = 'ATTR4_VALOR'
      Size = 50
    end
    object cdsLineasATTR5_NOMBRE: TWideStringField
      FieldKind = fkInternalCalc
      FieldName = 'ATTR5_NOMBRE'
      Size = 50
    end
    object cdsLineasATTR5_VALOR: TWideStringField
      FieldKind = fkInternalCalc
      FieldName = 'ATTR5_VALOR'
      Size = 50
    end
    object cdsLineasTIPO_CANTIDAD_INV_LINEA: TWideStringField
      FieldKind = fkInternalCalc
      FieldName = 'TIPO_CANTIDAD_INV_LINEA'
    end
    object cdsLineasUDS_REGULARIZADAS: TFloatField
      FieldKind = fkCalculated
      FieldName = 'UDS_REGULARIZADAS'
      DisplayFormat = ',0.00'
      Calculated = True
    end
    object cdsLineasINSTANTE_ALTA: TDateTimeField
      FieldName = 'INSTANTE_ALTA'
    end
    object cdsLineasUSUARIO_ALTA: TWideStringField
      FieldName = 'USUARIO_ALTA'
      Size = 50
    end
    object cdsLineasUSUARIO_MODIF: TWideStringField
      FieldName = 'USUARIO_MODIF'
      Size = 50
    end
    object cdsLineasINSTANTE_MODIF: TDateTimeField
      FieldName = 'INSTANTE_MODIF'
    end
  end
  object dsLineas: TDataSource
    DataSet = cdsLineas
    Left = 462
    Top = 110
  end
  object unqryMovsRegul: TUniQuery
    SQL.Strings = (
      'SELECT '
      '   m.NUMERO_MOV, m.LINEA_MOV, m.TIPO_MOV,'
      '   m.CODIGO_ART_MOV, m.CODIGO_UNIDAD_MOV,'
      '   LEFT(COALESCE(m.DESCRIPCION_ARTICULO_MOV,'
      '                 a.DESCRIPCION_ART), 100)'
      '     AS DESCRIPCION_ARTICULO_MOV,'
      '   m.CANTIDAD_MOV, m.PRECIO_MEDIO_MOV,'
      '   (m.CANTIDAD_MOV * m.PRECIO_MEDIO_MOV) AS COSTE_MOV,'
      '   m.FECHA_MOV, m.ESACTIVO_MOV'
      'FROM fza_movimientos_almacen m'
      'LEFT JOIN fza_articulos a'
      '  ON a.CODIGO_ART_ART = m.CODIGO_ART_MOV'
      'WHERE m.CODIGO_EMP_MOV  = :EMPRESA'
      '  AND m.CODIGO_ALM_MOV  = :ALMACEN'
      '  AND m.TIPO_DOC_MOV    = '#39'IN'#39
      '  AND m.SERIE_DOC_MOV   = :SERIE'
      '  AND m.NUMERO_DOC_MOV  = :NUMERO'
      'ORDER BY m.LINEA_MOV')
    Left = 250
    Top = 198
    ParamData = <
      item
        DataType = ftString
        Name = 'EMPRESA'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'ALMACEN'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'SERIE'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'NUMERO'
        ParamType = ptInput
        Value = nil
      end>
  end
  object dsMovsRegul: TDataSource
    DataSet = unqryMovsRegul
    Left = 254
    Top = 278
  end
  object unqryArticulo: TUniQuery
    SQL.Strings = (
      'SELECT CODIGO_ART_ART, DESCRIPCION_ART, TIPO_ART'
      'FROM fza_articulos'
      'WHERE CODIGO_ART_ART = :CODIGO')
    Left = 778
    Top = 38
    ParamData = <
      item
        DataType = ftString
        Name = 'CODIGO'
        ParamType = ptInput
        Value = nil
      end>
  end
  object unqryDefinicionArticulo: TUniQuery
    SQL.Strings = (
      'SELECT DISTINCT NOMBRE_ATRIBUTO, ORDEN_VISUAL_ATRIBUTO'
      '  FROM vi_atributos_nombres'
      ' WHERE CODIGO_ART_PADRE_ARTVIN = :ARTICULO'
      ' ORDER BY ORDEN_VISUAL_ATRIBUTO LIMIT 5')
    Left = 606
    Top = 110
    ParamData = <
      item
        DataType = ftString
        Name = 'ARTICULO'
        ParamType = ptInput
        Value = nil
      end>
  end
  object unqryStockActual: TUniQuery
    SQL.Strings = (
      'SELECT SUM(CANTIDAD_STK) AS CANTIDAD_STK,'
      '       MAX(PRECIO_MEDIO_STK) AS PRECIO_MEDIO_STK'
      'FROM fza_articulos_stockactual'
      'WHERE CODIGO_ALM_STK = :ALMACEN'
      '  AND CODIGO_UNIDAD_STK  = :SKU')
    Left = 602
    Top = 22
    ParamData = <
      item
        DataType = ftString
        Name = 'ALMACEN'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'SKU'
        ParamType = ptInput
        Value = nil
      end>
  end
  object unqryEmpresas: TUniQuery
    SQL.Strings = (
      'SELECT CODIGO_EMP_EMP, RAZON_SOCIAL_EMP'
      'FROM fza_empresas'
      'WHERE ESACTIVO_EMP = '#39'S'#39
      'ORDER BY ORDEN_EMP, CODIGO_EMP_EMP')
    Left = 138
    Top = 198
  end
  object dsEmpresas: TDataSource
    DataSet = unqryEmpresas
    Left = 142
    Top = 278
  end
  object unqryAlmacenes: TUniQuery
    SQL.Strings = (
      'SELECT CODIGO_ALM_ALM AS CODIGO_ALMACEN,'
      '       NOMBRE_ALM_ALM AS DESCRIPCION_ALMACEN'
      'FROM fza_almacenes'
      'WHERE ESACTIVO_ALM = '#39'S'#39
      '  AND COALESCE(TIPO_USO_ALM, '#39#39') NOT IN ('#39'TR'#193'NSITO'#39', '#39'TRANSITO'#39')'
      '  AND CODIGO_EMP_ALM = :EMPRESA'
      'ORDER BY ORDEN_ALM, CODIGO_ALM_ALM')
    Left = 370
    Top = 198
    ParamData = <
      item
        DataType = ftString
        Name = 'EMPRESA'
        Value = nil
      end>
  end
  object dsAlmacenes: TDataSource
    DataSet = unqryAlmacenes
    Left = 374
    Top = 278
  end
  object unqrySeries: TUniQuery
    SQL.Strings = (
      'SELECT DISTINCT EMPSER'
      'FROM vi_empresas_series'
      'WHERE TIPO_DOC_EMPSER = '#39'IN'#39
      'ORDER BY EMPSER')
    Left = 650
    Top = 198
  end
  object dsSeries: TDataSource
    DataSet = unqrySeries
    Left = 654
    Top = 278
  end
  object unqryFamilias: TUniQuery
    SQL.Strings = (
      'SELECT CODIGO_FAM_FAM, NOMBRE_FAM_FAM AS DESCRIPCION_FAM'
      'FROM fza_articulos_familias'
      'WHERE ESACTIVO_FAM = '#39'S'#39
      'ORDER BY ORDEN_FAM, CODIGO_FAM_FAM')
    Left = 26
    Top = 198
  end
  object dsFamilias: TDataSource
    DataSet = unqryFamilias
    Left = 22
    Top = 278
  end
  object unqryProveedores: TUniQuery
    SQL.Strings = (
      'SELECT CODIGO_PRV_PRV, RAZON_SOCIAL_PRV,'
      'COALESCE(NULLIF(TRIM(NOMBRE_PRV), '#39#39'), RAZON_SOCIAL_PRV)'
      'AS NOMBRE_PRV'
      'FROM fza_proveedores'
      'ORDER BY NOMBRE_PRV, CODIGO_PRV_PRV')
    Left = 506
    Top = 198
  end
  object dsProveedores: TDataSource
    DataSet = unqryProveedores
    Left = 510
    Top = 278
  end
  object unspActualizarTeorico: TUniStoredProc
    StoredProcName = 'PRC_FZA_INVENTARIOS_ACTUALIZAR_TEORICO'
    Left = 82
    Top = 374
    ParamData = <
      item
        DataType = ftString
        Name = 'p_EMPRESA'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'p_ALMACEN'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'p_SERIE'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'p_NRO'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'p_USUARIO'
        ParamType = ptInput
        Value = nil
      end>
  end
  object unspAplicar: TUniStoredProc
    StoredProcName = 'PRC_FZA_INVENTARIOS_APLICAR'
    Left = 282
    Top = 374
    ParamData = <
      item
        DataType = ftString
        Name = 'p_EMPRESA'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'p_ALMACEN'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'p_SERIE'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'p_NRO'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'p_USUARIO'
        ParamType = ptInput
        Value = nil
      end>
  end
  object unspEliminarRegul: TUniStoredProc
    StoredProcName = 'PRC_FZA_INVENTARIOS_ELIMINAR_REGUL'
    Left = 482
    Top = 374
    ParamData = <
      item
        DataType = ftString
        Name = 'p_EMPRESA'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'p_ALMACEN'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'p_SERIE'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'p_NRO'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftString
        Name = 'p_USUARIO'
        ParamType = ptInput
        Value = nil
      end>
  end
end
