inherited dmComprasSesiones: TdmComprasSesiones
  Height = 726
  Width = 1127
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_compras_sesiones'
      
        '  (SERIE_SES, NUMERO_SES, FECHA_SES, ESTADO_SES, CODIGO_EMP_SES,' +
        ' CODIGO_PRV_SES, REF_PRV_SES, CODIGO_FAM_SES, CODIGO_ALM_SES, MO' +
        'NEDA_SES, TIPO_IVA_SES, PORCENTAJE_MARGEN_SES, CODIGO_TAR_SES, E' +
        'SPRECIOS_SIN_IVA_SES, ESREDONDEO_VENTA_SES, MULTIPLO_REDONDEO_SE' +
        'S, AJUSTE_FINAL_SES, CODIGO_VAR_SES, ID_VA_PIVOT_SES, ID_AC_PIVO' +
        'T_SES, ID_VA_FILA_SES, ID_AC_FILA_SES, ESVAR_FIJA_SES, PREFIJO_E' +
        'AN_SES, INSTANTE_MATERIALIZA_SES, USUARIO_MATERIALIZA_SES, ESGEN' +
        'ERA_PEDIDO_SES, ESGENERA_ALBARAN_SES, ESFORMATO_DISTRIBUIDO_SES,' +
        ' SERIE_PEDC_SES, NUMERO_PEDC_SES, SERIE_ALBC_SES, NUMERO_ALBC_SE' +
        'S, MENSAJE_ERROR_SES, CONTADOR_LINEAS_SES, COMENTARIOS_SES, INST' +
        'ANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF, ESPRECIO' +
        '_POR_SKU_SES, ID_PV_TEMPORADA_SES, ESVARIOS_TIPOS_IVA_SES, E' +
        'SIVA_RECARGO_COMPRAS_SES)'
      'VALUES'
      
        '  (:SERIE_SES, :NUMERO_SES, :FECHA_SES, :ESTADO_SES, :CODIGO_EMP' +
        '_SES, :CODIGO_PRV_SES, :REF_PRV_SES, :CODIGO_FAM_SES, :CODIGO_AL' +
        'M_SES, :MONEDA_SES, :TIPO_IVA_SES, :PORCENTAJE_MARGEN_SES, :CODI' +
        'GO_TAR_SES, :ESPRECIOS_SIN_IVA_SES, :ESREDONDEO_VENTA_SES, :MULT' +
        'IPLO_REDONDEO_SES, :AJUSTE_FINAL_SES, :CODIGO_VAR_SES, :ID_VA_PI' +
        'VOT_SES, :ID_AC_PIVOT_SES, :ID_VA_FILA_SES, :ID_AC_FILA_SES, :ES' +
        'VAR_FIJA_SES, :PREFIJO_EAN_SES, :INSTANTE_MATERIALIZA_SES, :USUA' +
        'RIO_MATERIALIZA_SES, :ESGENERA_PEDIDO_SES, :ESGENERA_ALBARAN_SES' +
        ', :ESFORMATO_DISTRIBUIDO_SES, :SERIE_PEDC_SES, :NUMERO_PEDC_SES,' +
        ' :SERIE_ALBC_SES, :NUMERO_ALBC_SES, :MENSAJE_ERROR_SES, :CONTADO' +
        'R_LINEAS_SES, :COMENTARIOS_SES, :INSTANTE_ALTA, :USUARIO_ALTA, :' +
        'INSTANTE_MODIF, :USUARIO_MODIF, :ESPRECIO_POR_SKU_SES, :ID_PV_TE' +
        'MPORADA_SES, :ESVARIOS_TIPOS_IVA_SES, :ESIVA_RECARGO_COMPRAS_S' +
        'ES)')
    SQLDelete.Strings = (
      'DELETE FROM fza_compras_sesiones'
      'WHERE'
      '  SERIE_SES = :Old_SERIE_SES AND NUMERO_SES = :Old_NUMERO_SES')
    SQLUpdate.Strings = (
      'UPDATE fza_compras_sesiones'
      'SET'
      
        '  SERIE_SES = :SERIE_SES, NUMERO_SES = :NUMERO_SES, FECHA_SES = ' +
        ':FECHA_SES, ESTADO_SES = :ESTADO_SES, CODIGO_EMP_SES = :CODIGO_E' +
        'MP_SES, CODIGO_PRV_SES = :CODIGO_PRV_SES, REF_PRV_SES = :REF_PRV' +
        '_SES, CODIGO_FAM_SES = :CODIGO_FAM_SES, CODIGO_ALM_SES = :CODIGO' +
        '_ALM_SES, MONEDA_SES = :MONEDA_SES, TIPO_IVA_SES = :TIPO_IVA_SES' +
        ', PORCENTAJE_MARGEN_SES = :PORCENTAJE_MARGEN_SES, CODIGO_TAR_SES' +
        ' = :CODIGO_TAR_SES, ESPRECIOS_SIN_IVA_SES = :ESPRECIOS_SIN_IVA_S' +
        'ES, ESREDONDEO_VENTA_SES = :ESREDONDEO_VENTA_SES, MULTIPLO_REDON' +
        'DEO_SES = :MULTIPLO_REDONDEO_SES, AJUSTE_FINAL_SES = :AJUSTE_FIN' +
        'AL_SES, CODIGO_VAR_SES = :CODIGO_VAR_SES, ID_VA_PIVOT_SES = :ID_' +
        'VA_PIVOT_SES, ID_AC_PIVOT_SES = :ID_AC_PIVOT_SES, ID_VA_FILA_SES' +
        ' = :ID_VA_FILA_SES, ID_AC_FILA_SES = :ID_AC_FILA_SES, ESVAR_FIJA' +
        '_SES = :ESVAR_FIJA_SES, PREFIJO_EAN_SES = :PREFIJO_EAN_SES, INST' +
        'ANTE_MATERIALIZA_SES = :INSTANTE_MATERIALIZA_SES, USUARIO_MATERI' +
        'ALIZA_SES = :USUARIO_MATERIALIZA_SES, ESGENERA_PEDIDO_SES = :ESG' +
        'ENERA_PEDIDO_SES, ESGENERA_ALBARAN_SES = :ESGENERA_ALBARAN_SES, ' +
        'ESFORMATO_DISTRIBUIDO_SES = :ESFORMATO_DISTRIBUIDO_SES, SERIE_PE' +
        'DC_SES = :SERIE_PEDC_SES, NUMERO_PEDC_SES = :NUMERO_PEDC_SES, SE' +
        'RIE_ALBC_SES = :SERIE_ALBC_SES, NUMERO_ALBC_SES = :NUMERO_ALBC_S' +
        'ES, MENSAJE_ERROR_SES = :MENSAJE_ERROR_SES, CONTADOR_LINEAS_SES ' +
        '= :CONTADOR_LINEAS_SES, COMENTARIOS_SES = :COMENTARIOS_SES, INST' +
        'ANTE_ALTA = :INSTANTE_ALTA, USUARIO_ALTA = :USUARIO_ALTA, INSTAN' +
        'TE_MODIF = :INSTANTE_MODIF, USUARIO_MODIF = :USUARIO_MODIF, ESPR' +
        'ECIO_POR_SKU_SES = :ESPRECIO_POR_SKU_SES, ID_PV_TEMPORADA_SES = ' +
        ':ID_PV_TEMPORADA_SES, ESVARIOS_TIPOS_IVA_SES = :ESVARIOS_TIPOS' +
        '_IVA_SES, ESIVA_RECARGO_COMPRAS_SES = :ESIVA_RECARGO_COMPRAS_SE' +
        'S'
      'WHERE'
      '  SERIE_SES = :Old_SERIE_SES AND NUMERO_SES = :Old_NUMERO_SES')
    SQLLock.Strings = (
      
        'SELECT SERIE_SES, NUMERO_SES, FECHA_SES, ESTADO_SES, CODIGO_EMP_' +
        'SES, CODIGO_PRV_SES, REF_PRV_SES, CODIGO_FAM_SES, CODIGO_ALM_SES' +
        ', MONEDA_SES, TIPO_IVA_SES, PORCENTAJE_MARGEN_SES, CODIGO_TAR_SE' +
        'S, ESPRECIOS_SIN_IVA_SES, ESREDONDEO_VENTA_SES, MULTIPLO_REDONDE' +
        'O_SES, AJUSTE_FINAL_SES, CODIGO_VAR_SES, ID_VA_PIVOT_SES, ID_AC_' +
        'PIVOT_SES, ID_VA_FILA_SES, ID_AC_FILA_SES, ESVAR_FIJA_SES, PREFI' +
        'JO_EAN_SES, INSTANTE_MATERIALIZA_SES, USUARIO_MATERIALIZA_SES, E' +
        'SGENERA_PEDIDO_SES, ESGENERA_ALBARAN_SES, ESFORMATO_DISTRIBUIDO_' +
        'SES, SERIE_PEDC_SES, NUMERO_PEDC_SES, SERIE_ALBC_SES, NUMERO_ALB' +
        'C_SES, MENSAJE_ERROR_SES, CONTADOR_LINEAS_SES, COMENTARIOS_SES, ' +
        'INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF, ESPR' +
        'ECIO_POR_SKU_SES, ID_PV_TEMPORADA_SES, ESVARIOS_TIPOS_IVA_SES, ' +
        'ESIVA_RECARGO_COMPRAS_SES' +
        ' FROM fza_compras_sesiones'
      'WHERE'
      '  SERIE_SES = :Old_SERIE_SES AND NUMERO_SES = :Old_NUMERO_SES'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT SERIE_SES, NUMERO_SES, FECHA_SES, ESTADO_SES, CODIGO_EMP_' +
        'SES, CODIGO_PRV_SES, REF_PRV_SES, CODIGO_FAM_SES, CODIGO_ALM_SES' +
        ', MONEDA_SES, TIPO_IVA_SES, PORCENTAJE_MARGEN_SES, CODIGO_TAR_SE' +
        'S, ESPRECIOS_SIN_IVA_SES, ESREDONDEO_VENTA_SES, MULTIPLO_REDONDE' +
        'O_SES, AJUSTE_FINAL_SES, CODIGO_VAR_SES, ID_VA_PIVOT_SES, ID_AC_' +
        'PIVOT_SES, ID_VA_FILA_SES, ID_AC_FILA_SES, ESVAR_FIJA_SES, PREFI' +
        'JO_EAN_SES, INSTANTE_MATERIALIZA_SES, USUARIO_MATERIALIZA_SES, E' +
        'SGENERA_PEDIDO_SES, ESGENERA_ALBARAN_SES, ESFORMATO_DISTRIBUIDO_' +
        'SES, SERIE_PEDC_SES, NUMERO_PEDC_SES, SERIE_ALBC_SES, NUMERO_ALB' +
        'C_SES, MENSAJE_ERROR_SES, CONTADOR_LINEAS_SES, COMENTARIOS_SES, ' +
        'INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF, ESPR' +
        'ECIO_POR_SKU_SES, ID_PV_TEMPORADA_SES, ESVARIOS_TIPOS_IVA_SES, ' +
        'ESIVA_RECARGO_COMPRAS_SES' +
        ' FROM fza_compras_sesiones'
      'WHERE'
      '  SERIE_SES = :SERIE_SES AND NUMERO_SES = :NUMERO_SES')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_compras_sesiones')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM vi_compras_sesiones'
      'ORDER BY FECHA_SES DESC, NUMERO_SES DESC')
    AfterInsert = unqryTablaGAfterInsert
  end
  inherited unqryPerfiles: TUniQuery
    SQL.Strings = (
      'select *'
      'from fza_usuarios_perfiles'
      'where (KEY_USUPER = '#39'dmComprasSesiones'#39
      'OR KEY_USUPER='#39'frmMtoComprasSesiones'#39')')
  end
  object unqrySesionLin: TUniQuery
    SQL.Strings = (
      'SELECT * FROM fza_compras_sesiones_lineas'
      'WHERE SERIE_SES_SESLIN = :SERIE_SES'
      '  AND NUMERO_SES_SESLIN = :NUMERO_SES'
      'ORDER BY LINEA_SESLIN')
    MasterFields = 'SERIE_SES;NUMERO_SES'
    DetailFields = 'SERIE_SES_SESLIN;NUMERO_SES_SESLIN'
    AfterInsert = unqrySesionLinAfterInsert
    BeforePost = unqrySesionLinBeforePost
    AfterPost = unqrySesionLinAfterPost
    AfterDelete = unqrySesionLinAfterDelete
    Left = 56
    Top = 16
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_SES'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_SES'
        Value = nil
      end>
  end
  object dsSesionLin: TDataSource
    DataSet = unqrySesionLin
    Left = 56
    Top = 72
  end
  object unqrySesDocs: TUniQuery
    SQL.Strings = (
      'SELECT D.TIPO_DOC_SESDOC AS TIPO,'
      '       D.SERIE_SESDOC    AS SERIE,'
      '       D.NUMERO_SESDOC   AS NUMERO,'
      '       D.CODIGO_ALM_SESDOC AS ALMACEN,'
      '       D.INSTANTE_ALTA   AS INSTANTE,'
      '       D.USUARIO_ALTA    AS USUARIO'
      '  FROM fza_compras_sesiones_documentos D'
      ' WHERE D.SERIE_SES_SESDOC  = :SERIE_SES'
      '   AND D.NUMERO_SES_SESDOC = :NUMERO_SES'
      ' ORDER BY D.INSTANTE_ALTA DESC,'
      '          D.TIPO_DOC_SESDOC,'
      '          D.SERIE_SESDOC,'
      '          D.NUMERO_SESDOC')
    MasterFields = 'SERIE_SES;NUMERO_SES'
    DetailFields = 'SERIE_SES_SESDOC;NUMERO_SES_SESDOC'
    Left = 208
    Top = 72
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_SES'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_SES'
        Value = nil
      end>
  end
  object dsSesDocs: TDataSource
    DataSet = unqrySesDocs
    Left = 208
    Top = 128
  end
  object unqrySesionFotos: TUniQuery
    SQL.Strings = (
      'SELECT F.SERIE_SES_CSF,'
      '       F.NUMERO_SES_CSF,'
      '       F.LINEA_CSF,'
      '       COALESCE(L.CODIGO_ART_TENTATIVO_SESLIN,'
      '                F.CODIGO_ART_TENTATIVO_CSF)'
      '         AS CODIGO_ART_TENTATIVO_CSF,'
      '       F.CODIGO_UNIDAD_CSF,'
      '       CASE'
      '         WHEN COALESCE(F.CODIGO_UNIDAD_CSF, '#39#39') = '#39#39
      '         THEN '#39'Art'#237'culo'#39
      '         ELSE CONCAT('#39'SKU '#39', F.CODIGO_UNIDAD_CSF)'
      '       END AS ASIGNACION_FOTO,'
      '       L.REF_PRV_SESLIN,'
      '       L.DESCRIPCION_SESLIN,'
      '       L.COLOR_TEXTO_SESLIN,'
      '       F.NOMBRE_FOT_CSF,'
      '       F.INSTANTE_MODIF,'
      '       F.USUARIO_MODIF'
      '  FROM fza_compras_sesiones_fotos F'
      '  LEFT JOIN fza_compras_sesiones_lineas L'
      '    ON L.SERIE_SES_SESLIN = F.SERIE_SES_CSF'
      '   AND L.NUMERO_SES_SESLIN = F.NUMERO_SES_CSF'
      '   AND L.LINEA_SESLIN = F.LINEA_CSF'
      ' WHERE F.SERIE_SES_CSF = :SERIE_SES'
      '   AND F.NUMERO_SES_CSF = :NUMERO_SES'
      ' ORDER BY F.LINEA_CSF, F.CODIGO_UNIDAD_CSF')
    MasterFields = 'SERIE_SES;NUMERO_SES'
    DetailFields = 'SERIE_SES_CSF;NUMERO_SES_CSF'
    Left = 352
    Top = 72
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_SES'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_SES'
        Value = nil
      end>
  end
  object dsSesionFotos: TDataSource
    DataSet = unqrySesionFotos
    Left = 352
    Top = 128
  end
  object unqrySesionFil: TUniQuery
    SQL.Strings = (
      'SELECT * FROM fza_compras_sesiones_lineas_filas'
      'WHERE SERIE_SES_SESFIL = :SERIE_SES_SESLIN'
      '  AND NUMERO_SES_SESFIL = :NUMERO_SES_SESLIN'
      '  AND LINEA_SES_SESFIL = :LINEA_SESLIN'
      'ORDER BY ORDEN_SESFIL, ID_FILA_SESFIL')
    MasterSource = dsSesionLin
    MasterFields = 'SERIE_SES_SESLIN;NUMERO_SES_SESLIN;LINEA_SESLIN'
    DetailFields = 'SERIE_SES_SESFIL;NUMERO_SES_SESFIL;LINEA_SES_SESFIL'
    Left = 216
    Top = 8
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_SES_SESLIN'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_SES_SESLIN'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'LINEA_SESLIN'
        Value = nil
      end>
  end
  object dsSesionFil: TDataSource
    DataSet = unqrySesionFil
    Left = 264
    Top = 72
  end
  object unqrySesionFilAtr: TUniQuery
    SQL.Strings = (
      'SELECT * FROM fza_compras_sesiones_lineas_filas_atr'
      'WHERE SERIE_SES_SESFILAT = :SERIE_SES_SESFIL'
      '  AND NUMERO_SES_SESFILAT = :NUMERO_SES_SESFIL'
      '  AND LINEA_SES_SESFILAT = :LINEA_SES_SESFIL'
      '  AND ID_FILA_SESFILAT = :ID_FILA_SESFIL')
    MasterSource = dsSesionFil
    Left = 368
    Top = 8
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_SES_SESFIL'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_SES_SESFIL'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'LINEA_SES_SESFIL'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'ID_FILA_SESFIL'
        Value = nil
      end>
  end
  object dsSesionFilAtr: TDataSource
    DataSet = unqrySesionFilAtr
    Left = 368
    Top = 64
  end
  object unqrySesionCel: TUniQuery
    UpdatingTable = 'fza_compras_sesiones_celdas'
    KeyFields =
      'SERIE_SES_SESCEL;NUMERO_SES_SESCEL;LINEA_SES_SESCEL;' +
      'ID_FILA_SES_SESCEL;ID_AV_PIVOT_SESCEL;CODIGO_ALM_SESCEL'
    SQL.Strings = (
      'SELECT C.SERIE_SES_SESCEL, C.NUMERO_SES_SESCEL, C.LINEA_SES_SESCEL,'
      '       C.ID_FILA_SES_SESCEL, C.ID_AV_PIVOT_SESCEL, C.CODIGO_ALM_SESCEL,'
      '       C.CANTIDAD_SESCEL, C.LOTE_SESCEL, C.CADUCIDAD_SESCEL,'
      '       C.SERIES_SESCEL, C.INSTANTE_ALTA, C.USUARIO_ALTA,'
      '       C.INSTANTE_MODIF, C.USUARIO_MODIF,'
      '       COALESCE(NULLIF(C.CODIGO_ALM_SESCEL, ''''), S.CODIGO_ALM_SES)'
      '         AS ALMACEN_DESTINO,'
      '       COALESCE(AVP.AV, '''') AS VALOR_TALLA,'
      '       COALESCE((SELECT GROUP_CONCAT(AVF.AV ORDER BY AVF.ID_AV'
      '                                    SEPARATOR ''/'')'
      '         FROM fza_compras_sesiones_lineas_filas_atr FA'
      '         JOIN fza_atributos_valores AVF ON AVF.ID_AV = FA.ID_AV_SESFILAT'
      '        WHERE FA.SERIE_SES_SESFILAT = C.SERIE_SES_SESCEL'
      '          AND FA.NUMERO_SES_SESFILAT = C.NUMERO_SES_SESCEL'
      '          AND FA.LINEA_SES_SESFILAT = C.LINEA_SES_SESCEL'
      '          AND FA.ID_FILA_SESFILAT = C.ID_FILA_SES_SESCEL), '''')'
      '         AS VALOR_FILA'
      '  FROM fza_compras_sesiones_celdas C'
      '  JOIN fza_compras_sesiones S ON S.SERIE_SES = C.SERIE_SES_SESCEL'
      '    AND S.NUMERO_SES = C.NUMERO_SES_SESCEL'
      '  LEFT JOIN fza_compras_sesiones_lineas L'
      '    ON L.SERIE_SES_SESLIN = C.SERIE_SES_SESCEL'
      '   AND L.NUMERO_SES_SESLIN = C.NUMERO_SES_SESCEL'
      '   AND L.LINEA_SESLIN = C.LINEA_SES_SESCEL'
      '  LEFT JOIN fza_atributos_conjuntos_det ACD'
      '    ON ACD.ID_AC_ACD = L.ID_AC_PIVOT_SESLIN'
      '   AND ACD.ID_AV_ACD = C.ID_AV_PIVOT_SESCEL'
      '  LEFT JOIN fza_atributos_valores AVP ON AVP.ID_AV = C.ID_AV_PIVOT_SESCEL'
      ' WHERE C.SERIE_SES_SESCEL = :SERIE_SES_SESLIN'
      '   AND C.NUMERO_SES_SESCEL = :NUMERO_SES_SESLIN'
      '   AND C.LINEA_SES_SESCEL = :LINEA_SESLIN'
      ' ORDER BY ALMACEN_DESTINO, C.ID_FILA_SES_SESCEL,'
      '   CASE WHEN ACD.ID_AV_ACD IS NULL THEN 1 ELSE 0 END,'
      '   COALESCE(ACD.ORDEN_ACD, AVP.ORDEN_AV), AVP.AV,'
      '   C.ID_AV_PIVOT_SESCEL')
    MasterSource = dsSesionLin
    MasterFields = 'SERIE_SES_SESLIN;NUMERO_SES_SESLIN;LINEA_SESLIN'
    DetailFields = 'SERIE_SES_SESCEL;NUMERO_SES_SESCEL;LINEA_SES_SESCEL'
    AfterPost = unqrySesionCelAfterPost
    Left = 496
    Top = 8
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_SES_SESLIN'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_SES_SESLIN'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'LINEA_SESLIN'
        Value = nil
      end>
  end
  object dsSesionCel: TDataSource
    DataSet = unqrySesionCel
    Left = 496
    Top = 64
  end
  object unqrySesionProps: TUniQuery
    SQL.Strings = (
      'SELECT P.*, PR.NOMBRE_PROP_PROP, PR.TIPO_VALOR_PROP'
      '  FROM fza_compras_sesiones_props P'
      '  LEFT JOIN fza_propiedades PR'
      '    ON PR.CODIGO_PROP_ARTPROP = P.CODIGO_PROP_SESPROP'
      'WHERE P.SERIE_SES_SESPROP = :SERIE_SES'
      '  AND P.NUMERO_SES_SESPROP = :NUMERO_SES'
      'ORDER BY P.ORDEN_SESPROP')
    Left = 672
    Top = 8
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_SES'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_SES'
        Value = nil
      end>
  end
  object dsSesionProps: TDataSource
    DataSet = unqrySesionProps
    Left = 672
    Top = 64
  end
  object unqrySesionLinProps: TUniQuery
    SQL.Strings = (
      'SELECT * FROM fza_compras_sesiones_lineas_props'
      'WHERE SERIE_SES_SESLPROP = :SERIE_SES_SESLIN'
      '  AND NUMERO_SES_SESLPROP = :NUMERO_SES_SESLIN'
      '  AND LINEA_SES_SESLPROP = :LINEA_SESLIN')
    MasterSource = dsSesionLin
    Left = 848
    Top = 8
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_SES_SESLIN'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_SES_SESLIN'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'LINEA_SESLIN'
        Value = nil
      end>
  end
  object dsSesionLinProps: TDataSource
    DataSet = unqrySesionLinProps
    Left = 848
    Top = 64
  end
  object unqrySesionKits: TUniQuery
    SQL.Strings = (
      'SELECT * FROM fza_compras_sesiones_kits'
      'WHERE SERIE_SES_SESKIT = :SERIE_SES'
      '  AND NUMERO_SES_SESKIT = :NUMERO_SES'
      'ORDER BY ORDEN_SESKIT')
    Left = 56
    Top = 128
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_SES'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_SES'
        Value = nil
      end>
  end
  object dsSesionKits: TDataSource
    DataSet = unqrySesionKits
    Left = 56
    Top = 184
  end
  object unqrySesionKitsDet: TUniQuery
    SQL.Strings = (
      'SELECT * FROM fza_compras_sesiones_kits_det'
      'WHERE SERIE_SES_SESKITD = :SERIE_SES_SESKIT'
      '  AND NUMERO_SES_SESKITD = :NUMERO_SES_SESKIT'
      '  AND CODIGO_SESKIT_SESKITD = :CODIGO_SESKIT'
      'ORDER BY ORDEN_SESKITD')
    MasterSource = dsSesionKits
    Left = 216
    Top = 184
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_SES_SESKIT'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_SES_SESKIT'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'CODIGO_SESKIT'
        Value = nil
      end>
  end
  object dsSesionKitsDet: TDataSource
    DataSet = unqrySesionKitsDet
    Left = 216
    Top = 240
  end
  object unqryPreviewSkus: TUniQuery
    SQL.Strings = (
      'SELECT * FROM vi_ses_preview_skus'
      'WHERE SERIE = :SERIE_SES'
      '  AND NUMERO = :NUMERO_SES'
      'ORDER BY CODIGO_ALM, LINEA, ID_FILA, ID_AV_PIVOT')
    Left = 368
    Top = 120
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_SES'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_SES'
        Value = nil
      end>
  end
  object dsPreviewSkus: TDataSource
    DataSet = unqryPreviewSkus
    Left = 368
    Top = 176
  end
  object unqryLineaSkusPrecios: TUniQuery
    SQL.Strings = (
      'SELECT C.ID_FILA_SES_SESCEL                      AS ID_FILA,'
      '       C.ID_AV_PIVOT_SESCEL                      AS ID_AV_PIVOT,'
      '       AVP.AV                                    AS VAL_PIVOT,'
      '       (SELECT GROUP_CONCAT(AV2.AV SEPARATOR '#39'/'#39')'
      '          FROM fza_compras_sesiones_lineas_filas_atr FA'
      
        '          JOIN fza_atributos_valores AV2 ON AV2.ID_AV = FA.ID_AV' +
        '_SESFILAT'
      '         WHERE FA.SERIE_SES_SESFILAT = C.SERIE_SES_SESCEL'
      '           AND FA.NUMERO_SES_SESFILAT = C.NUMERO_SES_SESCEL'
      '           AND FA.LINEA_SES_SESFILAT  = C.LINEA_SES_SESCEL'
      '           AND FA.ID_FILA_SESFILAT    = C.ID_FILA_SES_SESCEL'
      '       )                                         AS VAL_FILA,'
      '       P.PRECIO_COMPRA_SESLINSKU,'
      '       P.PRECIO_VENTA_SESLINSKU'
      '  FROM fza_compras_sesiones_celdas C'
      '  JOIN fza_atributos_valores AVP'
      '    ON AVP.ID_AV = C.ID_AV_PIVOT_SESCEL'
      '  LEFT JOIN fza_compras_sesiones_lineas_skus_precios P'
      '    ON P.SERIE_SES_SESLINSKU    = C.SERIE_SES_SESCEL'
      '   AND P.NUMERO_SES_SESLINSKU   = C.NUMERO_SES_SESCEL'
      '   AND P.LINEA_SES_SESLINSKU    = C.LINEA_SES_SESCEL'
      '   AND P.ID_FILA_SES_SESLINSKU  = C.ID_FILA_SES_SESCEL'
      '   AND P.ID_AV_PIVOT_SESLINSKU  = C.ID_AV_PIVOT_SESCEL'
      ' WHERE C.SERIE_SES_SESCEL  = :SERIE_SES_SESLIN'
      '   AND C.NUMERO_SES_SESCEL = :NUMERO_SES_SESLIN'
      '   AND C.LINEA_SES_SESCEL  = :LINEA_SESLIN'
      ' GROUP BY C.ID_FILA_SES_SESCEL, C.ID_AV_PIVOT_SESCEL'
      ' ORDER BY C.ID_FILA_SES_SESCEL, AVP.AV')
    MasterSource = dsSesionLin
    Left = 1008
    Top = 8
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_SES_SESLIN'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_SES_SESLIN'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'LINEA_SESLIN'
        Value = nil
      end>
  end
  object dsLineaSkusPrecios: TDataSource
    DataSet = unqryLineaSkusPrecios
    Left = 1008
    Top = 64
  end
  object unqryResumenAlmacen: TUniQuery
    SQL.Strings = (
      'SELECT R.CODIGO_ALM, A.NOMBRE_ALM_ALM,'
      '       R.NUM_SKUS, R.UNIDADES_TOTAL'
      '  FROM vi_ses_resumen_almacen R'
      '  LEFT JOIN fza_almacenes A'
      '    ON A.CODIGO_ALM_ALM = R.CODIGO_ALM'
      ' WHERE R.SERIE  = :SERIE_SES'
      '   AND R.NUMERO = :NUMERO_SES'
      ' ORDER BY R.CODIGO_ALM')
    Left = 1008
    Top = 120
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_SES'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_SES'
        Value = nil
      end>
  end
  object dsResumenAlmacen: TDataSource
    DataSet = unqryResumenAlmacen
    Left = 1008
    Top = 176
  end
  object unqryPrvFicha: TUniQuery
    SQL.Strings = (
      'SELECT * FROM fza_proveedores'
      ' WHERE CODIGO_PRV_PRV = :prv')
    ReadOnly = True
    Left = 392
    Top = 232
    ParamData = <
      item
        DataType = ftWideString
        Name = 'prv'
        ParamType = ptInput
        Value = nil
      end>
  end
  object dsPrvFicha: TDataSource
    DataSet = unqryPrvFicha
    Left = 392
    Top = 288
  end
  object unqryPrvKits: TUniQuery
    SQL.Strings = (
      'SELECT K.*, AC.NOMBRE_AC AS NOMBRE_TALLAS_PRVKIT'
      '  FROM fza_proveedores_kits K'
      '  LEFT JOIN fza_atributos_conjuntos AC'
      '    ON AC.ID_AC = K.ID_AC_TALLAS_PRVKIT'
      ' WHERE K.CODIGO_PRV_PRVKIT = :prv'
      ' ORDER BY K.ORDEN_PRVKIT, K.CODIGO_PRVKIT')
    ReadOnly = True
    Left = 496
    Top = 232
    ParamData = <
      item
        DataType = ftWideString
        Name = 'prv'
        ParamType = ptInput
        Value = nil
      end>
  end
  object dsPrvKits: TDataSource
    DataSet = unqryPrvKits
    Left = 496
    Top = 288
  end
  object unqryPrvKitsDet: TUniQuery
    SQL.Strings = (
      'SELECT * FROM fza_proveedores_kits_det'
      'WHERE CODIGO_PRV_PRVKITD = :CODIGO_PRV_PRVKIT'
      '  AND CODIGO_PRVKIT_PRVKITD = :CODIGO_PRVKIT'
      'ORDER BY ORDEN_PRVKITD, VALOR_DESTINO_PRVKITD')
    MasterSource = dsPrvKits
    MasterFields = 'CODIGO_PRV_PRVKIT;CODIGO_PRVKIT'
    DetailFields = 'CODIGO_PRV_PRVKITD;CODIGO_PRVKIT_PRVKITD'
    ReadOnly = True
    Left = 600
    Top = 232
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_PRV_PRVKIT'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'CODIGO_PRVKIT'
        ParamType = ptInput
        Value = nil
      end>
  end
  object dsPrvKitsDet: TDataSource
    DataSet = unqryPrvKitsDet
    Left = 600
    Top = 288
  end
  object unqryPrvKitsCombo: TUniQuery
    Left = 704
    Top = 232
  end
  object dsPrvKitsCombo: TDataSource
    DataSet = unqryPrvKitsCombo
    Left = 704
    Top = 288
  end
  object unqryProveedores: TUniQuery
    SQL.Strings = (
      'SELECT CODIGO_PRV_PRV, NOMBRE_PRV, RAZON_SOCIAL_PRV,'
      ' CONCAT(CODIGO_PRV_PRV, '#39' - '#39', COALESCE(RAZON_SOCIAL_PRV, '#39#39'))'
      ' AS PROVEEDOR_BUSQUEDA'
      '  FROM fza_proveedores'
      ' ORDER BY RAZON_SOCIAL_PRV, CODIGO_PRV_PRV')
    Left = 496
    Top = 120
  end
  object dsProveedores: TDataSource
    DataSet = unqryProveedores
    Left = 496
    Top = 176
  end
  object unqryFamilias: TUniQuery
    SQL.Strings = (
      
        'SELECT CODIGO_FAM_FAM, NOMBRE_FAM_FAM FROM fza_articulos_familia' +
        's'
      'WHERE ESACTIVO_FAM = '#39'S'#39
      'ORDER BY ORDEN_FAM, NOMBRE_FAM_FAM')
    Left = 672
    Top = 120
  end
  object dsFamilias: TDataSource
    DataSet = unqryFamilias
    Left = 672
    Top = 176
  end
  object unqryVariaciones: TUniQuery
    SQL.Strings = (
      'SELECT CODIGO_VAR, NOMBRE_VAR FROM fza_variaciones'
      ' WHERE ESACTIVO_VAR = '#39'S'#39
      ' ORDER BY ORDEN_VAR, CODIGO_VAR')
    Left = 848
    Top = 120
  end
  object dsVariaciones: TDataSource
    DataSet = unqryVariaciones
    Left = 848
    Top = 176
  end
  object unqryVariacionesAtributos: TUniQuery
    SQL.Strings = (
      
        'SELECT VA.*, COALESCE(VA.NOMBRE_VISIBLE_VA, VA.NOMBRE_VA) AS LAB' +
        'EL_VA'
      '  FROM fza_variaciones_atributos VA'
      'WHERE VA.ID_VAR_VA = :CODIGO_VAR_SES'
      'ORDER BY VA.ORDEN_VA')
    Left = 56
    Top = 240
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'CODIGO_VAR_SES'
        Value = nil
      end>
  end
  object dsVariacionesAtributos: TDataSource
    DataSet = unqryVariacionesAtributos
    Left = 56
    Top = 296
  end
  object unqryAtributosConjuntos: TUniQuery
    SQL.Strings = (
      'SELECT ID_AC, NOMBRE_AC, ID_VAR_AC, ID_VA_AC'
      '  FROM fza_atributos_conjuntos'
      'WHERE ESACTIVO_AC = '#39'S'#39
      'ORDER BY NOMBRE_AC')
    Left = 216
    Top = 296
  end
  object dsAtributosConjuntos: TDataSource
    DataSet = unqryAtributosConjuntos
    Left = 216
    Top = 352
  end
  object unqryAtributosValores: TUniQuery
    SQL.Strings = (
      'SELECT ID_AV, AV, ID_VA_AV FROM fza_atributos_valores'
      'ORDER BY ID_VA_AV, AV')
    Left = 368
    Top = 232
  end
  object dsAtributosValores: TDataSource
    DataSet = unqryAtributosValores
    Left = 368
    Top = 288
  end
  object unqryPropiedades: TUniQuery
    SQL.Strings = (
      
        'SELECT P.CODIGO_PROP_ARTPROP, P.NOMBRE_PROP_PROP, P.TIPO_VALOR_P' +
        'ROP,'
      '       FA.ESREQUERIDO_FA, FA.ORDEN_MOSTRAR_FA'
      '  FROM fza_familias_atributos FA'
      
        '  JOIN fza_propiedades P ON P.CODIGO_PROP_ARTPROP = FA.CODIGO_PR' +
        'OP_ARTPROP'
      'WHERE FA.CODIGO_FAM_FAM = :CODIGO_FAM_SES'
      'ORDER BY FA.ORDEN_MOSTRAR_FA')
    Left = 496
    Top = 232
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'CODIGO_FAM_SES'
        Value = nil
      end>
  end
  object dsPropiedades: TDataSource
    DataSet = unqryPropiedades
    Left = 496
    Top = 288
  end
  object unqryPropiedadesValores: TUniQuery
    SQL.Strings = (
      'SELECT ID_PV_ARTPROP, ID_PROP_PV, PV'
      '  FROM fza_propiedades_valores'
      'ORDER BY ID_PROP_PV, PV')
    Left = 672
    Top = 232
  end
  object dsPropiedadesValores: TDataSource
    DataSet = unqryPropiedadesValores
    Left = 672
    Top = 288
  end
  object unqryIvas: TUniQuery
    SQL.Strings = (
      'SELECT IVA_IVAGRP, DESCRIPCION_IVA_IVAGRP FROM fza_ivas_grupos'
      'ORDER BY IVA_IVAGRP')
    Left = 848
    Top = 232
  end
  object dsIvas: TDataSource
    DataSet = unqryIvas
    Left = 848
    Top = 288
  end
  object unqryAlmacenes: TUniQuery
    SQL.Strings = (
      'SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM, CODIGO_EMP_ALM'
      '  FROM fza_almacenes'
      ' WHERE ESACTIVO_ALM = '#39'S'#39
      '   AND COALESCE(TIPO_USO_ALM, '#39#39') NOT IN ('#39'TR'#193'NSITO'#39', '#39'TRANSITO'#39')'
      '   AND CODIGO_EMP_ALM = :EMPRESA'
      ' ORDER BY COALESCE(ORDEN_ALM, 2147483647), CODIGO_ALM_ALM')
    Left = 40
    Top = 392
    ParamData = <
      item
        DataType = ftString
        Name = 'EMPRESA'
        ParamType = ptInput
        Value = nil
      end>
  end
  object dsAlmacenes: TDataSource
    DataSet = unqryAlmacenes
    Left = 48
    Top = 464
  end
  object unqryTarifas: TUniQuery
    SQL.Strings = (
      'SELECT CODIGO_TAR_ARTTAR, NOMBRE_TAR_TAR FROM vi_tarifas'
      'ORDER BY NOMBRE_TAR_TAR')
    Left = 216
    Top = 408
  end
  object dsTarifas: TDataSource
    DataSet = unqryTarifas
    Left = 216
    Top = 464
  end
  object unqryEmpresas: TUniQuery
    SQL.Strings = (
      'SELECT CODIGO_EMP_EMP, RAZON_SOCIAL_EMP FROM fza_empresas'
      'ORDER BY RAZON_SOCIAL_EMP')
    Left = 368
    Top = 344
  end
  object dsEmpresas: TDataSource
    DataSet = unqryEmpresas
    Left = 368
    Top = 400
  end
  object unqryFormasPago: TUniQuery
    SQL.Strings = (
      'SELECT * FROM vi_formapago')
    ReadOnly = True
    Left = 648
    Top = 344
  end
  object dsFormasPago: TDataSource
    DataSet = unqryFormasPago
    Left = 648
    Top = 424
  end
  object unqryTemporadas: TUniQuery
    SQL.Strings = (
      'SELECT ID_PV_ARTPROP, PV'
      '  FROM fza_propiedades_valores'
      ' WHERE ID_PROP_PV = '#39'TEMPORADA'#39
      '   AND ESACTIVO_PV = '#39'S'#39
      ' ORDER BY PV')
    Left = 496
    Top = 344
  end
  object dsTemporadas: TDataSource
    DataSet = unqryTemporadas
    Left = 496
    Top = 424
  end
  object unqryEmpresaSeries: TUniQuery
    SQL.Strings = (
      'SELECT EMPSER, SUBTIPO_EMPSER, CODIGO_ALM_EMPSER'
      '  FROM vi_empresas_series'
      ' WHERE TIPO_DOC_EMPSER = '#39'SE'#39
      '   AND CODIGO_EMP_EMPSER = :CODIGO_EMP_SES'
      '   AND (FECHA_HASTA_EMPSER IS NULL'
      '        OR FECHA_HASTA_EMPSER >= CURDATE())'
      ' ORDER BY EMPSER')
    Left = 1056
    Top = 584
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'CODIGO_EMP_SES'
        Value = nil
      end>
  end
  object dsEmpresaSeries: TDataSource
    DataSet = unqryEmpresaSeries
    Left = 1056
    Top = 640
  end
  object unqryArticuloExiste: TUniQuery
    SQL.Strings = (
      'SELECT CODIGO_ART_ART, DESCRIPCION_ART FROM fza_articulos'
      'WHERE CODIGO_ART_ART = :p')
    Left = 496
    Top = 352
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'p'
        Value = nil
      end>
  end
  object unstrdprcGetContadorSesion: TUniStoredProc
    StoredProcName = 'PRC_GET_NEXT_CONT_FACT_SERIE'
    SQL.Strings = (
      
        'CALL PRC_GET_NEXT_CONT_FACT_SERIE(:pserie, :pTipoDoc, :pEMPRESA_' +
        'CONTADOR, :pUSUARIOMODIF, @pcont); SELECT @pcont AS '#39'@pcont'#39)
    Left = 672
    Top = 344
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'pserie'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'pTipoDoc'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'pEMPRESA_CONTADOR'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'pUSUARIOMODIF'
        Value = nil
      end>
  end
  object unstrdprcValidarSesion: TUniStoredProc
    StoredProcName = 'PRC_SES_VALIDAR'
    Left = 848
    Top = 344
  end
  object unqryCabSesionPrint: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT V.*,'
      '       S.TOTAL_BRUTO_SES AS TOTAL_BRUTO_SES_PRINT,'
      '       S.PORCENTAJE_DTO_COMERCIAL_SES AS PORCENTAJE_DTO_COMERCIAL_SES_PRINT,'
      '       S.TOTAL_DTO_COMERCIAL_SES AS TOTAL_DTO_COMERCIAL_SES_PRINT,'
      '       S.PORCENTAJE_DTO_FINANCIERO_SES AS PORCENTAJE_DTO_FINANCIERO_SES_PRINT,'
      '       S.TOTAL_DTO_FINANCIERO_SES AS TOTAL_DTO_FINANCIERO_SES_PRINT'
      '  FROM vi_compras_sesiones_cab_print V'
      '  LEFT JOIN fza_compras_sesiones S'
      '    ON S.SERIE_SES = V.SERIE_SES'
      '   AND S.NUMERO_SES = V.NUMERO_SES'
      ' WHERE V.SERIE_SES = :SERIE_SES'
      '   AND V.NUMERO_SES = :NUMERO_SES')
    Left = 48
    Top = 544
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_SES'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_SES'
        Value = nil
      end>
  end
  object dsCabSesionPrint: TDataSource
    DataSet = unqryCabSesionPrint
    Left = 56
    Top = 624
  end
  object unqryLinSesionPrint: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM vi_compras_sesiones_lin_print'
      'WHERE SERIE_SES = :SERIE_SES'
      '  AND NUMERO_SES = :NUMERO_SES'
      'ORDER BY LINEA_SES')
    Left = 216
    Top = 544
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_SES'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_SES'
        Value = nil
      end>
  end
  object dsLinSesionPrint: TDataSource
    DataSet = unqryLinSesionPrint
    Left = 216
    Top = 624
  end
  object unqryGuiasSesionPrint: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT'
      '  g.ID_AC,'
      '  g.NOMBRE_CORTO_AC,'
      '  g.NOMBRE_AC,'
      '  g.T01, g.T02, g.T03, g.T04, g.T05,'
      '  g.T06, g.T07, g.T08, g.T09, g.T10,'
      '  g.T11, g.T12, g.T13, g.T14, g.T15,'
      '  g.T16, g.T17, g.T18, g.T19, g.T20, g.T21'
      'FROM vi_compras_sesiones_guias_print g'
      'INNER JOIN ('
      '  SELECT DISTINCT lin.ID_AC_PIVOT_SESLIN AS ID_AC'
      '    FROM fza_compras_sesiones_lineas lin'
      '   WHERE lin.SERIE_SES_SESLIN = :SERIE_SES'
      '     AND lin.NUMERO_SES_SESLIN = :NUMERO_SES'
      '     AND lin.ID_AC_PIVOT_SESLIN IS NOT NULL'
      ') P ON P.ID_AC = g.ID_AC'
      'ORDER BY g.NOMBRE_CORTO_AC, g.ID_AC')
    Left = 360
    Top = 512
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'SERIE_SES'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NUMERO_SES'
        Value = nil
      end>
  end
  object dsGuiasSesionPrint: TDataSource
    DataSet = unqryGuiasSesionPrint
    Left = 360
    Top = 584
  end
  object fxdsCabSesion: TfrxDBDataset
    Description = 'Sesiones'
    UserName = 'Sesiones'
    CloseDataSource = False
    DataSource = dsCabSesionPrint
    BCDToCurrency = False
    DataSetOptions = []
    Left = 496
    Top = 584
  end
  object fxdsLinSesion: TfrxDBDataset
    Description = 'LineasSesiones'
    UserName = 'LineasSesiones'
    CloseDataSource = False
    DataSource = dsLinSesionPrint
    BCDToCurrency = False
    DataSetOptions = []
    Left = 496
    Top = 512
  end
  object fxdsGuiasSesion: TfrxDBDataset
    Description = 'GuiasTallas'
    UserName = 'GuiasTallas'
    CloseDataSource = False
    DataSource = dsGuiasSesionPrint
    BCDToCurrency = False
    DataSetOptions = []
    Left = 672
    Top = 432
  end
end
