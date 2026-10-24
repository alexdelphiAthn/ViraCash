inherited dmAlbaranes: TdmAlbaranes
  Height = 529
  Width = 626
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    Connection = dmConn.conUni
    SQLDelete.Strings = (
      'DELETE FROM fza_albaranes'
      'WHERE'
      '  NUMERO_ALB = :Old_NUMERO_ALB'
      '  AND SERIE_ALB = :Old_SERIE_ALB')
    SQL.Strings = (
      'SELECT V.*'
      '  FROM vi_albaranes V'
      ' ORDER BY V.INSTANTE_MOVIMIENTO_ALB DESC, V.NUMERO_ALB DESC')
    AfterInsert = unqryTablaGAfterInsert
    AfterPost = unqryTablaGAfterPost
    BeforeDelete = unqryTablaGBeforeDelete
    Left = 48
    Top = 24
  end
  object unqryAlbaranesLineas: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM fza_albaranes_lineas')
    MasterFields = 'NUMERO_ALB;SERIE_ALB'
    DetailFields = 'NUMERO_ALB_ALBLIN;SERIE_ALB_ALBLIN'
    AfterInsert = unqryAlbaranesLineasAfterInsert
    BeforePost = unqryAlbaranesLineasBeforePost
    AfterPost = unqryAlbaranesLineasAfterPost
    AfterDelete = unqryAlbaranesLineasAfterDelete
    Left = 520
    Top = 8
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'NUMERO_ALB'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'SERIE_ALB'
        Value = nil
      end>
  end
  object dsAlbaranesLineas: TDataSource
    DataSet = unqryAlbaranesLineas
    Left = 520
    Top = 72
  end
  object unqryEmpDataAlb: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM fza_empresas')
    Left = 48
    Top = 192
  end
  object unqryCliDataAlb: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM fza_clientes')
    Left = 48
    Top = 248
  end
  object unqryArtDataLinAlb: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM fza_articulos')
    Left = 48
    Top = 304
  end
  object unqrySkusAlb: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT CODIGO_UNIDAD_SKU, CODIGO_ART_SKU '
      '  FROM fza_articulos_skus '
      ' WHERE CODIGO_UNIDAD_SKU = :pSKU')
    Left = 48
    Top = 360
    ParamData = <
      item
        DataType = ftString
        Name = 'pSKU'
        ParamType = ptInput
        Value = nil
      end>
  end
  object unqryAlmacenesAlb: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM, CODIGO_EMP_ALM'
      '  FROM fza_almacenes'
      ' WHERE ESACTIVO_ALM = '#39'S'#39
      '   AND COALESCE(TIPO_USO_ALM, '#39#39') NOT IN ('#39'TR'#193'NSITO'#39', '#39'TRANSITO'#39')'
      '   AND CODIGO_EMP_ALM = :EMPRESA'
      ' ORDER BY COALESCE(ORDEN_ALM, 2147483647), CODIGO_ALM_ALM')
    Left = 160
    Top = 360
    ParamData = <
      item
        DataType = ftString
        Name = 'EMPRESA'
        ParamType = ptInput
        Value = nil
      end>
  end
  object dsAlmacenesAlb: TDataSource
    DataSet = unqryAlmacenesAlb
    Left = 160
    Top = 424
  end
  object unqryFacturas: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT NUMERO_FAC, SERIE_FAC, FECHA_FAC, FASE_FAC, '
      '       TOTAL_LIQUIDO_FAC '
      '  FROM fza_facturas '
      ' WHERE (NUMERO_FAC, SERIE_FAC) IN ('
      '   SELECT NUMERO_FAC_ALB, SERIE_FAC_ALB '
      '     FROM fza_albaranes '
      '    WHERE NUMERO_ALB = :NUMERO_ALB '
      '      AND SERIE_ALB  = :SERIE_ALB '
      '      AND NUMERO_FAC_ALB IS NOT NULL '
      '   UNION '
      '   SELECT NUMERO_FAC_ALBLIN, SERIE_FAC_ALBLIN '
      '     FROM fza_albaranes_lineas '
      '    WHERE NUMERO_ALB_ALBLIN = :NUMERO_ALB '
      '      AND SERIE_ALB_ALBLIN  = :SERIE_ALB '
      '      AND NUMERO_FAC_ALBLIN IS NOT NULL '
      ' ) '
      ' ORDER BY FECHA_FAC DESC, NUMERO_FAC DESC')
    MasterFields = 'NUMERO_ALB;SERIE_ALB'
    ReadOnly = True
    Left = 384
    Top = 200
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'NUMERO_ALB'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'SERIE_ALB'
        Value = nil
      end>
  end
  object dsFacturas: TDataSource
    DataSet = unqryFacturas
    Left = 464
    Top = 200
  end
  object unqryMovimientosAlb: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT M.NUMERO_MOV, M.FECHA_MOV, M.LINEA_MOV, '
      '       M.CODIGO_ALM_MOV, M.NOMBRE_ALMACEN_ORIGEN, '
      '       M.CODIGO_ART_MOV, M.CODIGO_UNIDAD_MOV, '
      '       LEFT(COALESCE(M.DESCRIPCION_ARTICULO_MOV, '
      '                     A.DESCRIPCION_ART), 100) '
      '         AS DESCRIPCION_ARTICULO_MOV, '
      '       M.TIPO_MOV, M.CANTIDAD_MOV, '
      '       M.PRECIO_MEDIO_MOV, M.TOTAL_COSTE_MOV '
      '  FROM vi_movimientos M '
      '  LEFT JOIN fza_articulos A '
      '    ON A.CODIGO_ART_ART = M.CODIGO_ART_MOV '
      ' WHERE M.TIPO_DOC_MOV   = '#39'AV'#39' '
      '   AND M.SERIE_DOC_MOV  = :SERIE_ALB '
      '   AND M.NUMERO_DOC_MOV = :NUMERO_ALB '
      ' ORDER BY M.LINEA_MOV')
    MasterFields = 'NUMERO_ALB;SERIE_ALB'
    Left = 384
    Top = 256
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'NUMERO_ALB'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'SERIE_ALB'
        Value = nil
      end>
  end
  object dsMovimientosAlb: TDataSource
    DataSet = unqryMovimientosAlb
    Left = 464
    Top = 256
  end
  object unstrdprcGetContadorAlbaran: TUniStoredProc
    StoredProcName = 'PRC_GET_NEXT_CONT_FACT_SERIE'
    Connection = dmConn.conUni
    Left = 256
    Top = 24
  end
  object unstrdprcCrearFacturaInicio: TUniStoredProc
    StoredProcName = 'PRC_ALB_CREAR_FACTURA_INICIO'
    Connection = dmConn.conUni
    Left = 256
    Top = 200
  end
  object unstrdprcCrearFacturaLinea: TUniStoredProc
    StoredProcName = 'PRC_ALB_CREAR_FACTURA_LINEA'
    Connection = dmConn.conUni
    Left = 256
    Top = 256
  end
  object unstrdprcCrearFacturaFin: TUniStoredProc
    StoredProcName = 'PRC_ALB_CREAR_FACTURA_FIN'
    Connection = dmConn.conUni
    Left = 256
    Top = 312
  end
  object unstrdprcInsertarMovAlb: TUniStoredProc
    StoredProcName = 'PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT'
    Connection = dmConn.conUni
    Left = 256
    Top = 368
  end
  object fxdsPrintAlb: TfrxDBDataset
    UserName = 'frxDBDataset1'
    CloseDataSource = False
    BCDToCurrency = False
    DataSetOptions = []
    Left = 384
    Top = 24
  end
  object fxdstPrintLinAlb: TfrxDBDataset
    UserName = 'frxDBDataset2'
    CloseDataSource = False
    DataSet = unqryAlbaranesLineas
    BCDToCurrency = False
    DataSetOptions = []
    Left = 384
    Top = 80
  end
  object unqryFormasPago: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM vi_formapago')
    ReadOnly = True
    Left = 512
    Top = 312
  end
  object dsFormasPago: TDataSource
    DataSet = unqryFormasPago
    Left = 512
    Top = 368
  end
  object unqryTarifas: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT CODIGO_TAR_ARTTAR, NOMBRE_TAR_TAR, ESIMP_INCL_TAR'
      '  FROM vi_tarifas'
      ' ORDER BY NOMBRE_TAR_TAR, CODIGO_TAR_ARTTAR')
    ReadOnly = True
    Left = 600
    Top = 312
  end
  object dsTarifas: TDataSource
    DataSet = unqryTarifas
    Left = 600
    Top = 368
  end
end
