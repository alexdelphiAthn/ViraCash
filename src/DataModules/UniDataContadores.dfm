inherited dmContadores: TdmContadores
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO `fza_contadores`'
      
        '  (`TIPO_DOC_CON`, `EMPRESA_CON`, `SERIE_CON`, `CON`, `NUM_DIGITOS_CON`, `ESACTIVO_CON`, `DEFAULT_CON`, `INSTANTE_MODIF`, `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`)'
      'VALUES'
      
        '  (:`TIPO_DOC_CON`, :`EMPRESA_CON`, :`SERIE_CON`, :`CON`, :`NUM_DIGITOS_CON`, :`ESACTIVO_CON`, :`DEFAULT_CON`, :`INSTANTE_MODIF`, :`INSTANTE_ALTA`, :`USUARIO_ALTA`, :`USUARIO_MODIF`)')
    SQLDelete.Strings = (
      'DELETE FROM `fza_contadores`'
      'WHERE'
      
        '  `TIPO_DOC_CON` = :`Old_TIPO_DOC_CON` AND `EMPRESA_CON` = :`Old_EMPRESA_CON` AND `SERIE_CON` = :`Old_SERIE_CON`')
    SQLUpdate.Strings = (
      'UPDATE `fza_contadores`'
      'SET'
      
        '  `TIPO_DOC_CON` = :`TIPO_DOC_CON`, `EMPRESA_CON` = :`EMPRESA_CON`, `SERIE_CON` = :`SERIE_CON`, `CON` = :`CON`, `NUM_DIGITOS_CON` = :`NUM_DIGITOS_CON`, `ESACTIVO_CON` = :`ESACTIVO_CON`, `DEFAULT_CON` ' +
        '= :`DEFAULT_CON`, `INSTANTE_MODIF` = :`INSTANTE_MODIF`, `INSTANTE_ALTA` = :`INSTANTE_ALTA`, `USUARIO_ALTA` = :`USUARIO_ALTA`, `USUARIO_MODIF` = :`USUARIO_MODIF`'
      'WHERE'
      
        '  `TIPO_DOC_CON` = :`Old_TIPO_DOC_CON` AND `EMPRESA_CON` = :`Old_EMPRESA_CON` AND `SERIE_CON` = :`Old_SERIE_CON`')
    SQLLock.Strings = (
      
        'SELECT `TIPO_DOC_CON`, `EMPRESA_CON`, `SERIE_CON`, `CON`, `NUM_DIGITOS_CON`, `ESACTIVO_CON`, `DEFAULT_CON`, `INSTANTE_MODIF`, `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF` FROM `fza_contadores`'
      'WHERE'
      
        '  `TIPO_DOC_CON` = :`Old_TIPO_DOC_CON` AND `EMPRESA_CON` = :`Old_EMPRESA_CON` AND `SERIE_CON` = :`Old_SERIE_CON`'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT `TIPO_DOC_CON`, `EMPRESA_CON`, `SERIE_CON`, `CON`, `NUM_DIGITOS_CON`, `ESACTIVO_CON`, `DEFAULT_CON`, `INSTANTE_MODIF`, `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF` FROM `fza_contadores`'
      'WHERE'
      
        '  `TIPO_DOC_CON` = :`TIPO_DOC_CON` AND `EMPRESA_CON` = :`EMPRESA_CON` AND `SERIE_CON` = :`SERIE_CON`')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_contadores')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *  '
      'FROM vi_contadores'
      '')
    Active = True
    Left = 24
  end
end
