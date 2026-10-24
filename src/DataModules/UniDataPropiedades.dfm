inherited dmPropiedades: TdmPropiedades
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    BeforePost = unqryTablaGBeforePost
    AfterPost = unqryTablaGAfterPost
    BeforeDelete = unqryTablaGBeforeDelete
    AfterDelete = unqryTablaGAfterDelete
    SQLInsert.Strings = (
      'INSERT INTO `fza_propiedades`'
      
        '  (`CODIGO_PROP_ARTPROP`, `NOMBRE_PROP_PROP`, `TIPO_VALOR_PROP`,' +
        ' `NIVEL_PROP`,' +
        ' `ESACTIVO_PROP`, `INSTANTE_MODIF`, `INSTANTE_ALTA`, `USUARIO_AL' +
        'TA`, `USUARIO_MODIF`)'
      'VALUES'
      
        '  (:`CODIGO_PROP_ARTPROP`, :`NOMBRE_PROP_PROP`, :`TIPO_VALOR_PRO' +
        'P`, IFNULL(:`NIVEL_PROP`, ''ARTICULO''), :`ESACTIVO_PROP`, :`INSTANTE_MODIF`, :`INSTANTE_ALTA`, :`USU' +
        'ARIO_ALTA`, :`USUARIO_MODIF`)')
    SQLDelete.Strings = (
      'DELETE FROM `fza_propiedades`'
      'WHERE'
      '  `CODIGO_PROP_ARTPROP` = :`Old_CODIGO_PROP_ARTPROP`')
    SQLUpdate.Strings = (
      'UPDATE `fza_propiedades`'
      'SET'
      
        '  `CODIGO_PROP_ARTPROP` = :`CODIGO_PROP_ARTPROP`, `NOMBRE_PROP_P' +
        'ROP` = :`NOMBRE_PROP_PROP`, `TIPO_VALOR_PROP` = :`TIPO_VALOR_PRO' +
        'P`, `NIVEL_PROP` = IFNULL(:`NIVEL_PROP`, ''ARTICULO''), `ESACTIVO_PROP` = :`ESACTIVO_PROP`, `INSTANTE_MODIF` = :`INS' +
        'TANTE_MODIF`, `INSTANTE_ALTA` = :`INSTANTE_ALTA`, `USUARIO_ALTA`' +
        ' = :`USUARIO_ALTA`, `USUARIO_MODIF` = :`USUARIO_MODIF`'
      'WHERE'
      '  `CODIGO_PROP_ARTPROP` = :`Old_CODIGO_PROP_ARTPROP`')
    SQLLock.Strings = (
      'SELECT * FROM `fza_propiedades`'
      'WHERE'
      '  `CODIGO_PROP_ARTPROP` = :`Old_CODIGO_PROP_ARTPROP`'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      'SELECT * FROM `fza_propiedades`'
      'WHERE'
      '  `CODIGO_PROP_ARTPROP` = :`CODIGO_PROP_ARTPROP`')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_propiedades')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT p.*,'
      '       (SELECT COUNT(*) FROM fza_articulos_propiedades ap'
      
        '         WHERE ap.CODIGO_PROP_ARTPROP = p.CODIGO_PROP_ARTPROP) A' +
        'S NUM_ART_USOS'
      'FROM fza_propiedades p'
      'ORDER BY p.CODIGO_PROP_ARTPROP'
      '')
    Active = True
    Left = 24
  end
  object unqryArticulos: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT ap.CODIGO_ART_ART,'
      '       a.DESCRIPCION_ART,'
      '       ap.ID_PV_ARTPROP,'
      '       pv.PV              AS VALOR_LISTA,'
      '       ap.VALOR_LIBRE_ARTPROP,'
      '       ap.INSTANTE_ALTA,'
      '       ap.USUARIO_ALTA'
      'FROM fza_articulos_propiedades ap'
      'LEFT JOIN fza_articulos a'
      '       ON a.CODIGO_ART_ART = ap.CODIGO_ART_ART'
      'LEFT JOIN fza_propiedades_valores pv'
      '       ON pv.ID_PV_ARTPROP = ap.ID_PV_ARTPROP'
      'WHERE ap.CODIGO_PROP_ARTPROP = :CODIGO_PROP_ARTPROP'
      'ORDER BY ap.CODIGO_ART_ART')
    MasterSource = frmMtoPropiedades.dsTablaG
    Left = 144
    Top = 24
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'CODIGO_PROP_ARTPROP'
        Value = nil
      end>
  end
  object dsArticulos: TDataSource
    DataSet = unqryArticulos
    Left = 144
    Top = 88
  end
  object unqryValores: TUniQuery
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
    SQLRefresh.Strings = (
      'SELECT * FROM `fza_propiedades_valores`'
      'WHERE'
      '  `ID_PV_ARTPROP` = :`ID_PV_ARTPROP`')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM fza_propiedades_valores'
      'WHERE ID_PROP_PV = :CODIGO_PROP_ARTPROP'
      'ORDER BY PV')
    MasterSource = frmMtoPropiedades.dsTablaG
    BeforePost = unqryValoresBeforePost
    AfterPost = unqryValoresAfterPost
    BeforeDelete = unqryValoresBeforeDelete
    AfterDelete = unqryValoresAfterDelete
    Left = 248
    Top = 24
  end
  object dsValores: TDataSource
    DataSet = unqryValores
    Left = 248
    Top = 88
  end
end
