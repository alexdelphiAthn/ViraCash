inherited dmVariaciones: TdmVariaciones
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    KeyFields = 'CODIGO_VAR'
    SQLInsert.Strings = (
      'INSERT INTO `fza_variaciones`'

        '  (`CODIGO_VAR`, `NOMBRE_VAR`, `ESACTIVO_VAR`, `ORDEN_VAR`, `ROT' +
        'ULO_OTRO_VAR`, `ESCOLOR_BASICO_VAR`, `INSTANTE_MODIF`, `INSTANT' +
        'E_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`)'
      'VALUES'

        '  (:`CODIGO_VAR`, :`NOMBRE_VAR`, :`ESACTIVO_VAR`, :`ORDEN_VAR`, ' +
        ':`ROTULO_OTRO_VAR`, :`ESCOLOR_BASICO_VAR`, ' +
        ':`INSTANTE_MODIF`, :`INSTANTE_ALTA`, :`USUARIO_ALTA`, :`USUARIO_' +
        'MODIF`)')
    SQLDelete.Strings = (
      'DELETE FROM `fza_variaciones`'
      'WHERE'
      '  `CODIGO_VAR` = :`Old_CODIGO_VAR`')
    SQLUpdate.Strings = (
      'UPDATE `fza_variaciones`'
      'SET'
      
        '  `CODIGO_VAR` = :`CODIGO_VAR`, `NOMBRE_VAR` = :`NOMBRE_VAR`, `E' +
        'SACTIVO_VAR` = :`ESACTIVO_VAR`, `ORDEN_VAR` = :`ORDEN_VAR`, `ROT' +
        'ULO_OTRO_VAR` = :`ROTULO_OTRO_VAR`, `ESCOLOR_BASICO_VAR` = :`ESC' +
        'OLOR_BASICO_VAR`, `INS' +
        'TANTE_MODIF` = :`INSTANTE_MODIF`, `INSTANTE_ALTA` = :`INSTANTE_A' +
        'LTA`, `USUARIO_ALTA` = :`USUARIO_ALTA`, `USUARIO_MODIF` = :`USUA' +
        'RIO_MODIF`'
      'WHERE'
      '  `CODIGO_VAR` = :`Old_CODIGO_VAR`')
    SQLLock.Strings = (
      'SELECT * FROM `fza_variaciones`'
      'WHERE'
      '  `CODIGO_VAR` = :`Old_CODIGO_VAR`'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      'SELECT * FROM `fza_variaciones`'
      'WHERE'
      '  `CODIGO_VAR` = :`CODIGO_VAR`')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_variaciones')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *'
      'FROM fza_variaciones'
      'ORDER BY ORDEN_VAR'
      '')
    CachedUpdates = True
    AfterPost = unqryTablaGAfterPost
    AfterDelete = unqryTablaGAfterDelete
    AfterCancel = unqryTablaGAfterCancel
    AfterInsert = unqryTablaGAfterInsert
    Active = True
    Left = 24
  end
  object unqryArticulosVariacion: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT a.CODIGO_ART_ART, a.DESCRIPCION_ART, a.ESACTIVO_ART,'
      '       a.CODIGO_FAM_ART, f.NOMBRE_FAM_FAM,'
      '       a.ESVARIACION_ART, a.TIPO_VARIACION_ART,'
      '       a.ORDEN_ART'
      '  FROM fza_articulos a'
      '  LEFT JOIN fza_articulos_familias f'
      '    ON f.CODIGO_FAM_FAM = a.CODIGO_FAM_ART'
      ' ORDER BY a.ORDEN_ART, a.CODIGO_ART_ART')
    MasterFields = 'CODIGO_VAR'
    DetailFields = 'TIPO_VARIACION_ART'
    Left = 200
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_VAR'
        ParamType = ptInput
        Value = nil
      end>
  end
  object dsArticulosVariacion: TDataSource
    DataSet = unqryArticulosVariacion
    Left = 200
    Top = 80
  end
  object unqryAtributosVariacion: TUniQuery
    KeyFields = 'ID_VAR_VA;ID_ATB_VA'
    SQLInsert.Strings = (
      'INSERT INTO fza_variaciones_atributos'
      '  (ID_VAR_VA, ID_ATB_VA, NOMBRE_VA, ORDEN_VA, NOMBRE_VISIBLE_VA,'
      '   EJE_VA)'
      'VALUES'
      '  (:ID_VAR_VA, :ID_ATB_VA, :NOMBRE_VA, :ORDEN_VA,'
      '   NULLIF(:NOMBRE_VISIBLE_VA, '#39#39'), NULLIF(:EJE_VA, '#39#39'))')
    SQLDelete.Strings = (
      'DELETE FROM fza_variaciones_atributos'
      'WHERE'
      '  ID_VAR_VA = :Old_ID_VAR_VA'
      '  AND ID_ATB_VA = :Old_ID_ATB_VA')
    SQLUpdate.Strings = (
      'UPDATE fza_variaciones_atributos'
      'SET'
      '  ID_VAR_VA = :ID_VAR_VA, ID_ATB_VA = :ID_ATB_VA,'
      '  NOMBRE_VA = :NOMBRE_VA, ORDEN_VA = :ORDEN_VA,'
      '  NOMBRE_VISIBLE_VA = NULLIF(:NOMBRE_VISIBLE_VA, '#39#39'),'
      '  EJE_VA = NULLIF(:EJE_VA, '#39#39')'
      'WHERE'
      '  ID_VAR_VA = :Old_ID_VAR_VA'
      '  AND ID_ATB_VA = :Old_ID_ATB_VA')
    SQLLock.Strings = (
      'SELECT * FROM fza_variaciones_atributos'
      'WHERE'
      '  ID_VAR_VA = :Old_ID_VAR_VA'
      '  AND ID_ATB_VA = :Old_ID_ATB_VA'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      'SELECT * FROM fza_variaciones_atributos'
      'WHERE'
      '  ID_VAR_VA = :ID_VAR_VA'
      '  AND ID_ATB_VA = :ID_ATB_VA')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_variaciones_atributos')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT ID_VAR_VA, ID_ATB_VA, NOMBRE_VA, ORDEN_VA,'
      '       NOMBRE_VISIBLE_VA, EJE_VA'
      '  FROM fza_variaciones_atributos'
      ' ORDER BY ORDEN_VA, ID_ATB_VA')
    MasterFields = 'CODIGO_VAR'
    DetailFields = 'ID_VAR_VA'
    CachedUpdates = True
    Options.LocalMasterDetail = True
    BeforeInsert = PrepararCambioAtributos
    BeforeEdit = PrepararEdicionAtributo
    BeforeDelete = PrepararBorradoAtributo
    AfterInsert = unqryAtributosVariacionAfterInsert
    BeforePost = unqryAtributosVariacionBeforePost
    AfterOpen = InvalidarLecturaAtributos
    AfterRefresh = InvalidarLecturaAtributos
    AfterPost = AtributoConfirmado
    AfterDelete = AtributoBorrado
    Left = 24
    Top = 152
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_VAR'
        ParamType = ptInput
        Value = nil
      end>
  end
  object dsAtributosVariacion: TDataSource
    DataSet = unqryAtributosVariacion
    Left = 24
    Top = 224
  end
  object unqrySkusArticulo: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT CODIGO_UNIDAD_SKU, CODIGO_ART_SKU,'
      '       CODIGO_VAR_SKU, ESACTIVO_SKU'
      '  FROM fza_articulos_skus'
      ' ORDER BY CODIGO_UNIDAD_SKU')
    MasterSource = dsArticulosVariacion
    MasterFields = 'CODIGO_ART_ART'
    DetailFields = 'CODIGO_ART_SKU'
    Left = 376
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_ART_ART'
        ParamType = ptInput
        Value = nil
      end>
  end
  object dsSkusArticulo: TDataSource
    DataSet = unqrySkusArticulo
    Left = 376
    Top = 80
  end
end
