inherited dmAtributosBasicos: TdmAtributosBasicos
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO `fza_atributos_basicos`'
      '  (`ID_VA_ATB`, `CODIGO_ATB`, `NOMBRE_ATB`, `DESCRIPCION_ATB`,'
      '   `HEX_ATB`, `VALOR_NUM_ATB`, `UNIDAD_ATB`,'
      '   `ORDEN_ATB`, `ESACTIVO_ATB`,'
      '   `INSTANTE_MODIF`, `INSTANTE_ALTA`,'
      '   `USUARIO_ALTA`, `USUARIO_MODIF`)'
      'VALUES'
      
        '  (:`ID_VA_ATB`, :`CODIGO_ATB`, :`NOMBRE_ATB`, :`DESCRIPCION_ATB' +
        '`,'
      '   :`HEX_ATB`, :`VALOR_NUM_ATB`, :`UNIDAD_ATB`,'
      '   :`ORDEN_ATB`, :`ESACTIVO_ATB`,'
      '   :`INSTANTE_MODIF`, :`INSTANTE_ALTA`,'
      '   :`USUARIO_ALTA`, :`USUARIO_MODIF`)')
    SQLDelete.Strings = (
      'DELETE FROM `fza_atributos_basicos`'
      'WHERE'
      '  `ID_ATB` = :`Old_ID_ATB`')
    SQLUpdate.Strings = (
      'UPDATE `fza_atributos_basicos`'
      'SET'
      '  `ID_VA_ATB` = :`ID_VA_ATB`,'
      '  `CODIGO_ATB` = :`CODIGO_ATB`,'
      '  `NOMBRE_ATB` = :`NOMBRE_ATB`,'
      '  `DESCRIPCION_ATB` = :`DESCRIPCION_ATB`,'
      '  `HEX_ATB` = :`HEX_ATB`,'
      '  `VALOR_NUM_ATB` = :`VALOR_NUM_ATB`,'
      '  `UNIDAD_ATB` = :`UNIDAD_ATB`,'
      '  `ORDEN_ATB` = :`ORDEN_ATB`,'
      '  `ESACTIVO_ATB` = :`ESACTIVO_ATB`,'
      '  `INSTANTE_MODIF` = :`INSTANTE_MODIF`,'
      '  `USUARIO_MODIF` = :`USUARIO_MODIF`'
      'WHERE'
      '  `ID_ATB` = :`Old_ID_ATB`')
    SQLLock.Strings = (
      'SELECT * FROM `fza_atributos_basicos`'
      'WHERE'
      '  `ID_ATB` = :`Old_ID_ATB`'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      'SELECT * FROM `fza_atributos_basicos`'
      'WHERE'
      '  `ID_ATB` = :`ID_ATB`')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_atributos_basicos')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *'
      'FROM fza_atributos_basicos'
      'ORDER BY ID_VA_ATB, ORDEN_ATB, NOMBRE_ATB'
      '')
    Active = True
    Left = 24
  end
  object unqryAtributosLookup: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT DISTINCT ID_ATB_VA, NOMBRE_VA, ORDEN_VA'
      '  FROM fza_variaciones_atributos'
      ' ORDER BY ORDEN_VA, ID_ATB_VA')
    Left = 200
    Top = 24
  end
  object dsAtributosLookup: TDataSource
    DataSet = unqryAtributosLookup
    Left = 200
    Top = 96
  end
end
