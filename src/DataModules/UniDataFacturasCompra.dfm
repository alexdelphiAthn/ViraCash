inherited dmFacturasCompra: TdmFacturasCompra
  Height = 480
  Width = 626
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    Connection = dmConn.conUni
    UpdatingTable = 'fza_facturas_compra'
    SQLDelete.Strings = (
      'DELETE FROM fza_facturas_compra'
      'WHERE'
      '  NUMERO_FACC = :Old_NUMERO_FACC'
      '  AND SERIE_FACC = :Old_SERIE_FACC')
    SQL.Strings = (
      'SELECT'
      '  F.NUMERO_FACC,'
      '  F.SERIE_FACC,'
      '  F.FECHA_FACC,'
      '  F.FECHA_VALOR_FACC,'
      '  F.ESTADO_FACC,'
      '  F.DOC_EXTERNO_FACC,'
      '  F.REF_PROVEEDOR_FACC,'
      '  F.CODIGO_EMP_FACC,'
      '  F.RAZON_SOCIAL_EMPRESA_FACC,'
      '  F.NIF_EMPRESA_FACC,'
      '  F.MOVIL_EMPRESA_FACC,'
      '  F.EMAIL_EMPRESA_FACC,'
      '  F.DIRECCION1_EMPRESA_FACC,'
      '  F.DIRECCION2_EMPRESA_FACC,'
      '  F.POBLACION_EMPRESA_FACC,'
      '  F.PROVINCIA_EMPRESA_FACC,'
      '  F.CODIGO_PAI_EMPRESA_FACC,'
      '  F.NOMBRE_PAI_EMPRESA_FACC,'
      '  F.CODIGO_POSTAL_EMPRESA_FACC,'
      '  F.CODIGO_PRV_FACC,'
      '  F.RAZON_SOCIAL_PRV_FACC,'
      '  F.NIF_PRV_FACC,'
      '  F.MOVIL_PRV_FACC,'
      '  F.EMAIL_PRV_FACC,'
      '  F.DIRECCION1_PRV_FACC,'
      '  F.DIRECCION2_PRV_FACC,'
      '  F.POBLACION_PRV_FACC,'
      '  F.PROVINCIA_PRV_FACC,'
      '  F.CODIGO_PAI_PRV_FACC,'
      '  F.NOMBRE_PAI_PRV_FACC,'
      '  F.CODIGO_POSTAL_PRV_FACC,'
      '  F.CODIGO_ALM_FACC,'
      '  F.CODIGO_IVA_FACC,'
      '  F.ESIVA_RECARGO_COMPRAS_FACC,'
      '  F.ESIVA_EXENTO_INTRACOMUNITARIO_FACC,'
      '  F.PORCENTAJE_IVAN_FACC,'
      '  F.TOTAL_BASEI_IVAN_FACC,'
      '  F.TOTAL_IVAN_FACC,'
      '  F.PORCENTAJE_REN_FACC,'
      '  F.TOTAL_REN_FACC,'
      '  F.PORCENTAJE_IVAR_FACC,'
      '  F.TOTAL_BASEI_IVAR_FACC,'
      '  F.TOTAL_IVAR_FACC,'
      '  F.PORCENTAJE_RER_FACC,'
      '  F.TOTAL_RER_FACC,'
      '  F.PORCENTAJE_IVAS_FACC,'
      '  F.TOTAL_BASEI_IVAS_FACC,'
      '  F.TOTAL_IVAS_FACC,'
      '  F.PORCENTAJE_RES_FACC,'
      '  F.TOTAL_RES_FACC,'
      '  F.PORCENTAJE_IVAE_FACC,'
      '  F.TOTAL_BASEI_IVAE_FACC,'
      '  F.TOTAL_IVAE_FACC,'
      '  F.PORCENTAJE_REE_FACC,'
      '  F.TOTAL_REE_FACC,'
      '  F.PORCENTAJE_DTO_COMERCIAL_FACC,'
      '  F.TOTAL_DTO_COMERCIAL_FACC,'
      '  F.PORCENTAJE_DTO_FINANCIERO_FACC,'
      '  F.TOTAL_DTO_FINANCIERO_FACC,'
      '  F.PORCENTAJE_PRONTO_PAGO_FACC,'
      '  F.TOTAL_PRONTO_PAGO_FACC,'
      '  F.PORCENTAJE_RAPPEL_FACC,'
      '  F.TOTAL_RAPPEL_FACC,'
      '  F.PORCENTAJE_FINANCIACION_FACC,'
      '  F.TOTAL_FINANCIACION_FACC,'
      '  F.TOTAL_PORTES_FACC,'
      '  F.PORCENTAJE_RETENCION_FACC,'
      '  F.TOTAL_RETENCION_FACC,'
      '  F.TOTAL_BRUTO_FACC,'
      '  F.TOTAL_BASES_FACC,'
      '  F.TOTAL_IMPUESTOS_FACC,'
      '  F.TOTAL_FACC,'
      '  F.TOTAL_LIQUIDO_FACC,'
      '  F.FORMA_PAGO_FACC,'
      '  F.ID_PV_TEMPORADA_FACC,'
      '  F.ESAGRUPAR_ALBARANES_FACC,'
      '  F.ENTIDAD_FACC,'
      '  F.OFICINA_FACC,'
      '  F.DIGITO_CONTROL_FACC,'
      '  F.CUENTA_FACC,'
      '  F.IBAN_FACC,'
      '  F.CONTADOR_LINEAS_FACC,'
      '  F.COMENTARIOS_FACC,'
      '  F.OBSERVACIONES_FACC,'
      '  F.ESPIVOTE_HORIZONTAL_FACC,'
      '  F.INSTANTE_CONTABILIZACION_FACC,'
      '  F.INSTANTE_MODIF,'
      '  F.INSTANTE_ALTA,'
      '  F.USUARIO_ALTA,'
      '  F.USUARIO_MODIF,'
      '  P.NOMBRE_PRV AS NOMBRE_PRV_VIEW_FACC,'
      '  E.RAZON_SOCIAL_EMP AS RAZON_SOCIAL_EMPRESA_VIEW_FACC'
      'FROM fza_facturas_compra F'
      'LEFT JOIN fza_proveedores P ON P.CODIGO_PRV_PRV = F.CODIGO_PRV_FACC'
      'LEFT JOIN fza_empresas E ON E.CODIGO_EMP_EMP = F.CODIGO_EMP_FACC'
      'ORDER BY F.FECHA_FACC DESC, F.NUMERO_FACC DESC')
    AfterInsert = unqryTablaGAfterInsert
    BeforePost = unqryTablaGBeforePost
    AfterPost = unqryTablaGAfterPost
    BeforeDelete = unqryTablaGBeforeDelete
    Left = 48
    Top = 24
  end
  object unqryFacturasCompraLineas: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM fza_facturas_compra_lineas'
      ' WHERE NUMERO_FACC_FACCLIN = :NUMERO_FACC'
      '   AND SERIE_FACC_FACCLIN  = :SERIE_FACC'
      ' ORDER BY LINEA_FACCLIN')
    MasterFields = 'NUMERO_FACC;SERIE_FACC'
    DetailFields = 'NUMERO_FACC_FACCLIN;SERIE_FACC_FACCLIN'
    AfterInsert = unqryFacturasCompraLineasAfterInsert
    BeforePost = unqryFacturasCompraLineasBeforePost
    AfterPost = unqryFacturasCompraLineasAfterPost
    Left = 520
    Top = 8
    ParamData = <
      item
        DataType = ftWideString
        Name = 'NUMERO_FACC'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'SERIE_FACC'
        ParamType = ptInput
        Value = nil
      end>
  end
  object dsFacturasCompraLineas: TDataSource
    DataSet = unqryFacturasCompraLineas
    Left = 520
    Top = 72
  end
  object unqryEfectos: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM fza_efectos_compra'
      ' WHERE NUMERO_FACC_EFEC = :NUMERO_FACC'
      '   AND SERIE_FACC_EFEC  = :SERIE_FACC'
      ' ORDER BY NUMERO_EFEC')
    MasterFields = 'NUMERO_FACC;SERIE_FACC'
    DetailFields = 'NUMERO_FACC_EFEC;SERIE_FACC_EFEC'
    Left = 360
    Top = 160
    ParamData = <
      item
        DataType = ftWideString
        Name = 'NUMERO_FACC'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'SERIE_FACC'
        ParamType = ptInput
        Value = nil
      end>
  end
  object dsEfectos: TDataSource
    DataSet = unqryEfectos
    Left = 360
    Top = 216
  end
  object unqryEmpDataFacc: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM fza_empresas')
    Left = 48
    Top = 192
  end
  object unqryPrvDataFacc: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM fza_proveedores ORDER BY CODIGO_PRV_PRV')
    Left = 48
    Top = 248
  end
  object dsPrvDataFacc: TDataSource
    DataSet = unqryPrvDataFacc
    Left = 112
    Top = 248
  end
  object unqryArtDataLinFacc: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM fza_articulos')
    Left = 48
    Top = 304
  end
  object unqrySkusFacc: TUniQuery
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
  object unstrdprcGetContadorFacc: TUniStoredProc
    StoredProcName = 'PRC_GET_NEXT_CONT_FACT_SERIE'
    Connection = dmConn.conUni
    Left = 256
    Top = 24
  end
  object unqryDefArticuloFacc: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT DISTINCT NOMBRE_ATRIBUTO, ORDEN_VISUAL_ATRIBUTO '
      '  FROM vi_atributos_nombres '
      ' WHERE CODIGO_ART_PADRE_ARTVIN = :ARTICULO '
      ' ORDER BY ORDEN_VISUAL_ATRIBUTO')
    Left = 256
    Top = 96
    ParamData = <
      item
        DataType = ftString
        Name = 'ARTICULO'
        ParamType = ptInput
        Value = nil
      end>
  end
  object unqryCabFaccPrint: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT V.*,'
      '       F.TOTAL_BRUTO_FACC AS TOTAL_BRUTO_FACC_PRINT,'
      '       F.PORCENTAJE_DTO_COMERCIAL_FACC AS PORCENTAJE_DTO_COMERCIAL_FACC_PRINT,'
      '       F.TOTAL_DTO_COMERCIAL_FACC AS TOTAL_DTO_COMERCIAL_FACC_PRINT,'
      '       F.PORCENTAJE_DTO_FINANCIERO_FACC AS PORCENTAJE_DTO_FINANCIERO_FACC_PRINT,'
      '       F.TOTAL_DTO_FINANCIERO_FACC AS TOTAL_DTO_FINANCIERO_FACC_PRINT'
      '  FROM vi_facturas_compra_cab_print V'
      '  LEFT JOIN fza_facturas_compra F'
      '    ON F.SERIE_FACC = V.SERIE_FACC'
      '   AND F.NUMERO_FACC = V.NUMERO_FACC'
      ' WHERE V.SERIE_FACC = :SERIE_FACC'
      '   AND V.NUMERO_FACC = :NUMERO_FACC')
    Left = 360
    Top = 24
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_FACC'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_FACC'
        Value = nil
      end>
  end
  object dsCabFaccPrint: TDataSource
    DataSet = unqryCabFaccPrint
    Left = 360
    Top = 64
  end
  object fxdsCabFacc: TfrxDBDataset
    UserName = 'Factura'
    CloseDataSource = False
    DataSource = dsCabFaccPrint
    BCDToCurrency = False
    DataSetOptions = []
    Left = 360
    Top = 104
  end
  object unqryLinFaccPrint: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM vi_facturas_compra_lin_print'
      'WHERE SERIE_FACC = :SERIE_FACC'
      '  AND NUMERO_FACC = :NUMERO_FACC'
      'ORDER BY CODIGO_ART, COLOR_TEXTO, LINEA_FACC')
    Left = 456
    Top = 24
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_FACC'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_FACC'
        Value = nil
      end>
  end
  object dsLinFaccPrint: TDataSource
    DataSet = unqryLinFaccPrint
    Left = 456
    Top = 64
  end
  object fxdsLinFacc: TfrxDBDataset
    UserName = 'LineasFactura'
    CloseDataSource = False
    DataSource = dsLinFaccPrint
    BCDToCurrency = False
    DataSetOptions = []
    Left = 456
    Top = 104
  end
  object unqryGuiasFaccPrint: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT'
      '  g.ID_AC, g.NOMBRE_CORTO_AC, g.NOMBRE_AC,'
      '  g.T01, g.T02, g.T03, g.T04, g.T05,'
      '  g.T06, g.T07, g.T08, g.T09, g.T10,'
      '  g.T11, g.T12, g.T13, g.T14, g.T15,'
      '  g.T16, g.T17, g.T18, g.T19, g.T20, g.T21'
      'FROM vi_facturas_compra_guias_print g'
      'INNER JOIN ('
      '  SELECT DISTINCT L.ID_AC_PIVOT_FACCLIN AS ID_AC'
      '    FROM fza_facturas_compra_lineas L'
      '   WHERE L.SERIE_FACC_FACCLIN  = :SERIE_FACC'
      '     AND L.NUMERO_FACC_FACCLIN = :NUMERO_FACC'
      '     AND L.ID_AC_PIVOT_FACCLIN IS NOT NULL'
      ') P ON P.ID_AC = g.ID_AC'
      'ORDER BY g.NOMBRE_CORTO_AC, g.ID_AC')
    Left = 552
    Top = 24
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_FACC'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_FACC'
        Value = nil
      end>
  end
  object dsGuiasFaccPrint: TDataSource
    DataSet = unqryGuiasFaccPrint
    Left = 552
    Top = 64
  end
  object fxdsGuiasFacc: TfrxDBDataset
    UserName = 'GuiasTallas'
    CloseDataSource = False
    DataSource = dsGuiasFaccPrint
    BCDToCurrency = False
    DataSetOptions = []
    Left = 552
    Top = 104
  end
  object unqryLinFaccSkuPrint: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT L.*'
      '  FROM fza_facturas_compra_lineas L'
      ' WHERE L.SERIE_FACC_FACCLIN = :SERIE_FACC'
      '   AND L.NUMERO_FACC_FACCLIN = :NUMERO_FACC'
      ' ORDER BY L.LINEA_FACCLIN')
    Left = 648
    Top = 24
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_FACC'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_FACC'
        Value = nil
      end>
  end
  object dsLinFaccSkuPrint: TDataSource
    DataSet = unqryLinFaccSkuPrint
    Left = 648
    Top = 64
  end
  object fxdsLinFaccSku: TfrxDBDataset
    UserName = 'LineasFacturaSku'
    CloseDataSource = False
    DataSource = dsLinFaccSkuPrint
    BCDToCurrency = False
    DataSetOptions = []
    Left = 648
    Top = 104
  end
  object unqryFormasPago: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM vi_formapago')
    ReadOnly = True
    Left = 648
    Top = 160
  end
  object dsFormasPago: TDataSource
    DataSet = unqryFormasPago
    Left = 648
    Top = 216
  end
  object unqryAlmacenesFacc: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM, CODIGO_EMP_ALM'
      '  FROM fza_almacenes'
      ' WHERE ESACTIVO_ALM = '#39'S'#39
      '   AND COALESCE(TIPO_USO_ALM, '#39#39') NOT IN ('#39'TR'#193'NSITO'#39', '#39'TRANSITO'#39')'
      '   AND CODIGO_EMP_ALM = :EMPRESA'
      ' ORDER BY COALESCE(ORDEN_ALM, 2147483647), CODIGO_ALM_ALM')
    ReadOnly = True
    Left = 744
    Top = 160
    ParamData = <
      item
        DataType = ftString
        Name = 'EMPRESA'
        ParamType = ptInput
        Value = nil
      end>
  end
  object dsAlmacenesFacc: TDataSource
    DataSet = unqryAlmacenesFacc
    Left = 744
    Top = 216
  end
end
