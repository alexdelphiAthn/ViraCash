inherited dmUnidadesMedida: TdmUnidadesMedida
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO `fza_unidades_medida`'
      '  (`CODIGO_UNIMED`, `DESCRIPCION_UNIMED`, `DECIMALES_UNIMED`,'
      '   `MAGNITUD_UNIMED`, `ESBASE_UNIMED`, `FACTOR_BASE_UNIMED`,'
      '   `ORDEN_UNIMED`, `ESACTIVO_UNIMED`,'
      '   `INSTANTE_MODIF`, `INSTANTE_ALTA`,'
      '   `USUARIO_ALTA`, `USUARIO_MODIF`)'
      'VALUES'
      '  (:`CODIGO_UNIMED`, :`DESCRIPCION_UNIMED`, :`DECIMALES_UNIMED`,'
      '   :`MAGNITUD_UNIMED`, :`ESBASE_UNIMED`, :`FACTOR_BASE_UNIMED`,'
      '   :`ORDEN_UNIMED`, :`ESACTIVO_UNIMED`,'
      '   :`INSTANTE_MODIF`, :`INSTANTE_ALTA`,'
      '   :`USUARIO_ALTA`, :`USUARIO_MODIF`)')
    SQLDelete.Strings = (
      'DELETE FROM `fza_unidades_medida`'
      'WHERE'
      '  `CODIGO_UNIMED` = :`Old_CODIGO_UNIMED`')
    SQLUpdate.Strings = (
      'UPDATE `fza_unidades_medida`'
      'SET'
      '  `CODIGO_UNIMED` = :`CODIGO_UNIMED`,'
      '  `DESCRIPCION_UNIMED` = :`DESCRIPCION_UNIMED`,'
      '  `DECIMALES_UNIMED` = :`DECIMALES_UNIMED`,'
      '  `MAGNITUD_UNIMED` = :`MAGNITUD_UNIMED`,'
      '  `ESBASE_UNIMED` = :`ESBASE_UNIMED`,'
      '  `FACTOR_BASE_UNIMED` = :`FACTOR_BASE_UNIMED`,'
      '  `ORDEN_UNIMED` = :`ORDEN_UNIMED`,'
      '  `ESACTIVO_UNIMED` = :`ESACTIVO_UNIMED`,'
      '  `INSTANTE_MODIF` = :`INSTANTE_MODIF`,'
      '  `USUARIO_MODIF` = :`USUARIO_MODIF`'
      'WHERE'
      '  `CODIGO_UNIMED` = :`Old_CODIGO_UNIMED`')
    SQLLock.Strings = (
      'SELECT * FROM `fza_unidades_medida`'
      'WHERE'
      '  `CODIGO_UNIMED` = :`Old_CODIGO_UNIMED`'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      'SELECT * FROM `fza_unidades_medida`'
      'WHERE'
      '  `CODIGO_UNIMED` = :`CODIGO_UNIMED`')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_unidades_medida')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *'
      'FROM fza_unidades_medida'
      'ORDER BY ORDEN_UNIMED, MAGNITUD_UNIMED, CODIGO_UNIMED'
      '')
    Active = True
    AfterInsert = unqryTablaGAfterInsert
    AfterPost = unqryTablaGAfterPost
    Left = 24
  end
end
