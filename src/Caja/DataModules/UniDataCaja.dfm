object dmCajaOpe: TdmCajaOpe
  OnCreate = DataModuleCreate
  Height = 346
  Width = 791
  PixelsPerInch = 120
  object cdsCabecera: TClientDataSet
    Aggregates = <>
    FieldDefs = <
      item
        Name = 'NUMERO_FAC'
        DataType = ftString
        Size = 20
      end
      item
        Name = 'SERIE_FAC'
        DataType = ftString
        Size = 20
      end
      item
        Name = 'FECHA_FAC'
        DataType = ftDate
      end
      item
        Name = 'CODIGO_EMPLEADO'
        DataType = ftString
        Size = 10
      end
      item
        Name = 'NOMBRE_EMPLEADO'
        DataType = ftString
        Size = 200
      end
      item
        Name = 'ESCONSOLIDADA_FAC'
        DataType = ftString
        Size = 1
      end
      item
        Name = 'INSTANTECONSO_FAC'
        DataType = ftDateTime
      end
      item
        Name = 'TIPO_FAC'
        DataType = ftString
        Size = 20
      end
      item
        Name = 'FASE_FAC'
        DataType = ftString
        Size = 20
      end
      item
        Name = 'CODIGO_EMP_FAC'
        DataType = ftString
        Size = 8
      end
      item
        Name = 'RAZON_SOCIAL_EMPRESA_FAC'
        DataType = ftString
        Size = 200
      end
      item
        Name = 'NIF_EMPRESA_FAC'
        DataType = ftString
        Size = 50
      end
      item
        Name = 'MOVIL_EMPRESA_FAC'
        DataType = ftString
        Size = 40
      end
      item
        Name = 'EMAIL_EMPRESA_FAC'
        DataType = ftString
        Size = 200
      end
      item
        Name = 'DIRECCION1_EMPRESA_FAC'
        DataType = ftString
        Size = 200
      end
      item
        Name = 'DIRECCION2_EMPRESA_FAC'
        DataType = ftString
        Size = 200
      end
      item
        Name = 'POBLACION_EMPRESA_FAC'
        DataType = ftString
        Size = 200
      end
      item
        Name = 'PROVINCIA_EMPRESA_FAC'
        DataType = ftString
        Size = 200
      end
      item
        Name = 'CODIGO_PAI_EMPRESA_FAC'
        DataType = ftString
        Size = 3
      end
      item
        Name = 'NOMBRE_PAI_EMPRESA_FAC'
        DataType = ftString
        Size = 150
      end
      item
        Name = 'CODIGO_POSTAL_EMPRESA_FAC'
        DataType = ftString
        Size = 15
      end
      item
        Name = 'ESRETENCIONES_EMPRESA_FAC'
        DataType = ftString
        Size = 1
      end
      item
        Name = 'GRUPO_ZONA_IVA_EMPRESA_FAC'
        DataType = ftString
        Size = 10
      end
      item
        Name = 'ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC'
        DataType = ftString
        Size = 1
      end
      item
        Name = 'CODIGO_CLI_FAC'
        DataType = ftString
        Size = 10
      end
      item
        Name = 'RAZON_SOCIAL_CLIENTE_FAC'
        DataType = ftString
        Size = 200
      end
      item
        Name = 'NIF_CLIENTE_FAC'
        DataType = ftString
        Size = 50
      end
      item
        Name = 'MOVIL_CLIENTE_FAC'
        DataType = ftString
        Size = 40
      end
      item
        Name = 'EMAIL_CLIENTE_FAC'
        DataType = ftString
        Size = 200
      end
      item
        Name = 'DIRECCION1_CLIENTE_FAC'
        DataType = ftString
        Size = 200
      end
      item
        Name = 'DIRECCION2_CLIENTE_FAC'
        DataType = ftString
        Size = 200
      end
      item
        Name = 'POBLACION_CLIENTE_FAC'
        DataType = ftString
        Size = 200
      end
      item
        Name = 'PROVINCIA_CLIENTE_FAC'
        DataType = ftString
        Size = 200
      end
      item
        Name = 'CODIGO_POSTAL_CLIENTE_FAC'
        DataType = ftString
        Size = 15
      end
      item
        Name = 'CODIGO_PAI_CLIENTE_FAC'
        DataType = ftString
        Size = 3
      end
      item
        Name = 'NOMBRE_PAI_CLIENTE_FAC'
        DataType = ftString
        Size = 150
      end
      item
        Name = 'CODIGO_IVA_FAC'
        DataType = ftString
        Size = 20
      end
      item
        Name = 'ESIVA_RECARGO_CLIENTE_FAC'
        DataType = ftString
        Size = 1
      end
      item
        Name = 'ESIVA_EXENTO_CLIENTE_FAC'
        DataType = ftString
        Size = 1
      end
      item
        Name = 'ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC'
        DataType = ftString
        Size = 1
      end
      item
        Name = 'ESRETENCIONES_CLIENTE_FAC'
        DataType = ftString
        Size = 1
      end
      item
        Name = 'TARIFA_ARTICULO_CLIENTE_FAC'
        DataType = ftString
        Size = 10
      end
      item
        Name = 'ESIMP_INCL_TARIFA_CLIENTE_FAC'
        DataType = ftString
        Size = 1
      end
      item
        Name = 'ESINTRACOMUNITARIO_CLIENTE_FAC'
        DataType = ftString
        Size = 1
      end
      item
        Name = 'ESIRPF_IMP_INCL_ZONA_IVA_FAC'
        DataType = ftString
        Size = 1
      end
      item
        Name = 'ESAPLICA_RE_ZONA_IVA_FAC'
        DataType = ftString
        Size = 1
      end
      item
        Name = 'ESIVAAGRICOLA_ZONA_IVA_FAC'
        DataType = ftString
        Size = 1
      end
      item
        Name = 'PALABRA_REPORTS_ZONA_IVA_FAC'
        DataType = ftString
        Size = 10
      end
      item
        Name = 'ESVENTA_ACTIVO_FIJO_FAC'
        DataType = ftString
        Size = 1
      end
      item
        Name = 'PORCENTAJE_IVAN_FAC'
        DataType = ftBCD
        Precision = 19
        Size = 6
      end
      item
        Name = 'TOTAL_BASEI_IVAN_FAC'
        DataType = ftBCD
        Precision = 18
        Size = 6
      end
      item
        Name = 'TOTAL_IVAN_FAC'
        DataType = ftBCD
        Precision = 18
        Size = 6
      end
      item
        Name = 'PORCENTAJE_REN_FAC'
        DataType = ftBCD
        Precision = 19
        Size = 6
      end
      item
        Name = 'TOTAL_REN_FAC'
        DataType = ftBCD
        Precision = 18
        Size = 6
      end
      item
        Name = 'PORCENTAJE_IVAR_FAC'
        DataType = ftBCD
        Precision = 19
        Size = 6
      end
      item
        Name = 'TOTAL_BASEI_IVAR_FAC'
        DataType = ftBCD
        Precision = 18
        Size = 6
      end
      item
        Name = 'TOTAL_IVAR_FAC'
        DataType = ftBCD
        Precision = 18
        Size = 6
      end
      item
        Name = 'PORCENTAJE_RER_FAC'
        DataType = ftBCD
        Precision = 19
        Size = 6
      end
      item
        Name = 'TOTAL_RER_FAC'
        DataType = ftBCD
        Precision = 18
        Size = 6
      end
      item
        Name = 'PORCENTAJE_IVAS_FAC'
        DataType = ftBCD
        Precision = 19
        Size = 6
      end
      item
        Name = 'TOTAL_BASEI_IVAS_FAC'
        DataType = ftBCD
        Precision = 18
        Size = 6
      end
      item
        Name = 'TOTAL_IVAS_FAC'
        DataType = ftBCD
        Precision = 18
        Size = 6
      end
      item
        Name = 'PORCENTAJE_RES_FAC'
        DataType = ftBCD
        Precision = 19
        Size = 6
      end
      item
        Name = 'TOTAL_RES_FAC'
        DataType = ftBCD
        Precision = 18
        Size = 6
      end
      item
        Name = 'PORCENTAJE_IVAE_FAC'
        DataType = ftBCD
        Precision = 19
        Size = 6
      end
      item
        Name = 'TOTAL_BASEI_IVAE_FAC'
        DataType = ftBCD
        Precision = 18
        Size = 6
      end
      item
        Name = 'TOTAL_IVAE_FAC'
        DataType = ftBCD
        Precision = 18
        Size = 6
      end
      item
        Name = 'PORCENTAJE_REE_FAC'
        DataType = ftBCD
        Precision = 19
        Size = 6
      end
      item
        Name = 'TOTAL_REE_FAC'
        DataType = ftBCD
        Precision = 18
        Size = 6
      end
      item
        Name = 'TOTAL_BASES_FAC'
        DataType = ftBCD
        Precision = 18
        Size = 6
      end
      item
        Name = 'TOTAL_IMPUESTOS_FAC'
        DataType = ftBCD
        Precision = 18
        Size = 6
      end
      item
        Name = 'PORCENTAJE_RETENCION_FAC'
        DataType = ftBCD
        Precision = 19
        Size = 6
      end
      item
        Name = 'TOTAL_RETENCION_FAC'
        DataType = ftBCD
        Precision = 18
        Size = 6
      end
      item
        Name = 'TOTAL_LIQUIDO_FAC'
        DataType = ftBCD
        Precision = 18
        Size = 6
      end
      item
        Name = 'NUMERO_FAC_ABONO_FAC'
        DataType = ftString
        Size = 8
      end
      item
        Name = 'SERIE_FAC_ABONO_FAC'
        DataType = ftString
        Size = 8
      end
      item
        Name = 'FORMA_PAGO_FAC'
        DataType = ftString
        Size = 200
      end
      item
        Name = 'TEXTO_LEGAL_CLIENTE_FAC'
        DataType = ftString
        Size = 1000
      end
      item
        Name = 'TEXTO_LEGAL_EMPRESA_FAC'
        DataType = ftString
        Size = 1000
      end
      item
        Name = 'COMENTARIOS_FAC'
        DataType = ftString
        Size = 1000
      end
      item
        Name = 'CONTADOR_LINEAS_FAC'
        DataType = ftString
        Size = 8
      end
      item
        Name = 'ESCREARARTICULOS_FAC'
        DataType = ftString
        Size = 1
      end
      item
        Name = 'ESDESCRIPCIONES_AMP_FAC'
        DataType = ftString
        Size = 1
      end
      item
        Name = 'ESFECHADEENTREGA_FAC'
        DataType = ftString
        Size = 1
      end
      item
        Name = 'XML_FAC'
        DataType = ftMemo
      end
      item
        Name = 'INSTANTE_ALTA'
        DataType = ftDateTime
      end
      item
        Name = 'INSTANTE_MODIF'
        DataType = ftDateTime
      end
      item
        Name = 'USUARIO_ALTA'
        DataType = ftString
        Size = 100
      end
      item
        Name = 'USUARIO_MODIF'
        DataType = ftString
        Size = 100
      end>
    IndexDefs = <>
    Params = <>
    StoreDefs = True
    AfterInsert = cdsCabeceraAfterInsert
    Left = 78
    Top = 128
  end
  object cdsLineas: TClientDataSet
    Aggregates = <>
    Params = <>
    AfterInsert = cdsLineasAfterInsert
    BeforeInsert = cdsLineasBeforeInsert
    BeforePost = cdsLineasBeforePost
    AfterPost = cdsLineasAfterPost
    AfterDelete = cdsLineasAfterDelete
    Left = 333
    Top = 128
  end
  object DataSetProviderCabecera: TDataSetProvider
    DataSet = cdsCabecera
    Left = 75
    Top = 233
  end
  object DataSetProviderLineas: TDataSetProvider
    DataSet = cdsLineas
    Left = 333
    Top = 228
  end
  object dsLineas: TDataSource
    DataSet = cdsLineas
    Left = 330
    Top = 38
  end
  object dsCabecera: TDataSource
    DataSet = cdsCabecera
    Left = 78
    Top = 25
  end
  object qryDefinicionArticulo: TUniQuery
    SQL.Strings = (
      'SELECT DISTINCT '
      '    N.NOMBRE_ATRIBUTO, '
      '    N.ID_ATRIBUTO'
      'FROM fza_articulos_skus SKU'
      
        'JOIN fza_atributos_sku AT ON SKU.CODIGO_UNIDAD_SKU = AT.CODIGO_U' +
        'NIDAD_SKU_SA'
      'JOIN fza_atributos_valores V ON AT.ID_AV_SA = V.ID_AV'
      'JOIN vi_atributos_nombres N ON V.ID_VA_AV = N.ID_ATRIBUTO'
      'WHERE SKU.CODIGO_ART_SKU = :ARTICULO'
      
        '-- IMPORTANTE: Ordenamos por ID o por un campo ORDEN_VISUAL_ARTV' +
        'IN si lo tienes'
      'ORDER BY N.ID_ATRIBUTO ASC '
      'LIMIT 5;')
    Left = 540
    Top = 50
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'ARTICULO'
        Value = nil
      end>
  end
  object qryVales: TUniQuery
    SQL.Strings = (
      'SELECT * FROM vi_caja_vales_ptes')
    Left = 534
    Top = 230
  end
end
