inherited dmPropiedadesValores: TdmPropiedadesValores
  OnCreate = DataModuleCreate
  inherited unqryTablaG: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO `fza_propiedades_valores`'
      '  (`ID_PROP_PV`, `PV`, `DESCRIPCION_PV`, `ESACTIVO_PV`, `INSTANTE_MODIF`, `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`)'
      'VALUES'
      '  (:`ID_PROP_PV`, :`PV`, :`DESCRIPCION_PV`, :`ESACTIVO_PV`, :`INSTANTE_MODIF`, :`INSTANTE_ALTA`, :`USUARIO_ALTA`, :`USUARIO_MODIF`)')
    SQLDelete.Strings = (
      'DELETE FROM `fza_propiedades_valores`'
      'WHERE'
      '  `ID_PV_ARTPROP` = :`Old_ID_PV_ARTPROP`')
    SQLUpdate.Strings = (
      'UPDATE `fza_propiedades_valores`'
      'SET'
      '  `ID_PROP_PV` = :`ID_PROP_PV`,'
      '  `PV` = :`PV`,'
      '  `DESCRIPCION_PV` = :`DESCRIPCION_PV`,'
      '  `ESACTIVO_PV` = :`ESACTIVO_PV`,'
      '  `INSTANTE_MODIF` = :`INSTANTE_MODIF`,'
      '  `INSTANTE_ALTA` = :`INSTANTE_ALTA`,'
      '  `USUARIO_ALTA` = :`USUARIO_ALTA`,'
      '  `USUARIO_MODIF` = :`USUARIO_MODIF`'
      'WHERE'
      '  `ID_PV_ARTPROP` = :`Old_ID_PV_ARTPROP`')
    SQLLock.Strings = (
      'SELECT * FROM `fza_propiedades_valores`'
      'WHERE'
      '  `ID_PV_ARTPROP` = :`Old_ID_PV_ARTPROP`'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      'SELECT * FROM `fza_propiedades_valores`'
      'WHERE'
      '  `ID_PV_ARTPROP` = :`ID_PV_ARTPROP`')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_propiedades_valores')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *'
      'FROM fza_propiedades_valores'
      'ORDER BY ID_PROP_PV, ID_PV_ARTPROP'
      '')
    Active = True
    BeforePost = unqryTablaGBeforePost
    AfterPost = unqryTablaGAfterPost
    BeforeDelete = unqryTablaGBeforeDelete
    AfterDelete = unqryTablaGAfterDelete
    Left = 24
  end
  object unqryPropiedades: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT CODIGO_PROP_ARTPROP, NOMBRE_PROP_PROP'
      'FROM fza_propiedades'
      'WHERE ESACTIVO_PROP = '#39'S'#39
      'ORDER BY CODIGO_PROP_ARTPROP')
    Left = 144
    Top = 24
  end
  object dsPropiedades: TDataSource
    DataSet = unqryPropiedades
    Left = 144
    Top = 88
  end
end
