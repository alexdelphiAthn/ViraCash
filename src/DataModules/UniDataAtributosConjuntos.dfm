inherited dmAtributosConjuntos: TdmAtributosConjuntos
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO `fza_atributos_conjuntos`'
      
        '  (`NOMBRE_AC`, `ID_VAR_AC`, `ID_VA_AC`, `ESACTIVO_AC`, `INSTANT' +
        'E_MODIF`, `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`)'
      'VALUES'
      
        '  (:`NOMBRE_AC`, '#39#39', :`ID_VA_AC`, :`ESACTIVO_AC`, :`IN' +
        'STANTE_MODIF`, :`INSTANTE_ALTA`, :`USUARIO_ALTA`, :`USUARIO_MODI' +
        'F`)')
    SQLDelete.Strings = (
      'DELETE FROM `fza_atributos_conjuntos`'
      'WHERE'
      '  `ID_AC` = :`Old_ID_AC`')
    SQLUpdate.Strings = (
      'UPDATE `fza_atributos_conjuntos`'
      'SET'
      
        '  `NOMBRE_AC` = :`NOMBRE_AC`, `ID_VA' +
        '_AC` = :`ID_VA_AC`, `ESACTIVO_AC` = :`ESACTIVO_AC`, `INSTANTE_MO' +
        'DIF` = :`INSTANTE_MODIF`, `INSTANTE_ALTA` = :`INSTANTE_ALTA`, `U' +
        'SUARIO_ALTA` = :`USUARIO_ALTA`, `USUARIO_MODIF` = :`USUARIO_MODI' +
        'F`'
      'WHERE'
      '  `ID_AC` = :`Old_ID_AC`')
    SQLLock.Strings = (
      'SELECT * FROM `fza_atributos_conjuntos`'
      'WHERE'
      '  `ID_AC` = :`Old_ID_AC`'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      'SELECT * FROM `fza_atributos_conjuntos`'
      'WHERE'
      '  `ID_AC` = :`ID_AC`')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_atributos_conjuntos')
    AfterInsert = unqryTablaGConjuntosAfterInsert
    BeforePost = unqryTablaGConjuntosBeforePost
    BeforeDelete = unqryTablaGConjuntosBeforeDelete
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *'
      'FROM fza_atributos_conjuntos'
      'ORDER BY ID_AC'
      '')
    Active = True
    Left = 24
  end
  object unqryConjuntoDetalle: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_atributos_conjuntos_det'
      '  (ID_AC_ACD, ID_AV_ACD, ORDEN_ACD, ID_ATB_ACD,'
      '   INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF)'
      'VALUES'
      '  (:ID_AC_ACD, :ID_AV_ACD, :ORDEN_ACD, :ID_ATB_ACD,'
      
        '   :INSTANTE_MODIF, :INSTANTE_ALTA, :USUARIO_ALTA, :USUARIO_MODI' +
        'F)')
    SQLDelete.Strings = (
      'DELETE FROM fza_atributos_conjuntos_det'
      'WHERE'
      '  ID_AC_ACD = :Old_ID_AC_ACD'
      '  AND ID_AV_ACD = :Old_ID_AV_ACD')
    SQLUpdate.Strings = (
      'UPDATE fza_atributos_conjuntos_det'
      'SET'
      '  ID_AC_ACD = :ID_AC_ACD, ID_AV_ACD = :ID_AV_ACD,'
      '  ORDEN_ACD = :ORDEN_ACD, ID_ATB_ACD = :ID_ATB_ACD,'
      '  INSTANTE_MODIF = :INSTANTE_MODIF,'
      '  USUARIO_MODIF = :USUARIO_MODIF'
      'WHERE'
      '  ID_AC_ACD = :Old_ID_AC_ACD'
      '  AND ID_AV_ACD = :Old_ID_AV_ACD')
    SQLLock.Strings = (
      'SELECT ID_AC_ACD, ID_AV_ACD, ORDEN_ACD, ID_ATB_ACD,'
      
        '       INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODI' +
        'F'
      '  FROM fza_atributos_conjuntos_det'
      ' WHERE ID_AC_ACD = :Old_ID_AC_ACD'
      '   AND ID_AV_ACD = :Old_ID_AV_ACD'
      ' FOR UPDATE')
    SQLRefresh.Strings = (
      'SELECT ID_AC_ACD, ID_AV_ACD, ORDEN_ACD, ID_ATB_ACD,'
      '       (SELECT v.AV FROM fza_atributos_valores v'
      '         WHERE v.ID_AV = fza_atributos_conjuntos_det.ID_AV_ACD) AS AV,'
      
        '       INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODI' +
        'F'
      '  FROM fza_atributos_conjuntos_det'
      ' WHERE ID_AC_ACD = :ID_AC_ACD'
      '   AND ID_AV_ACD = :ID_AV_ACD')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_atributos_conjuntos_det')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT ID_AC_ACD, ID_AV_ACD, ORDEN_ACD, ID_ATB_ACD,'
      '       (SELECT v.AV FROM fza_atributos_valores v'
      '         WHERE v.ID_AV = fza_atributos_conjuntos_det.ID_AV_ACD) AS AV,'
      
        '       INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODI' +
        'F'
      '  FROM fza_atributos_conjuntos_det'
      ' ORDER BY ORDEN_ACD, ID_AV_ACD')
    MasterFields = 'ID_AC'
    DetailFields = 'ID_AC_ACD'
    Options.SetFieldsReadOnly = False
    BeforeInsert = unqryConjuntoDetalleBeforeInsert
    AfterInsert = unqryConjuntoDetalleAfterInsert
    BeforePost = unqryConjuntoDetalleBeforePost
    AfterPost = unqryConjuntoDetalleAfterPost
    BeforeDelete = unqryConjuntoDetalleBeforeDelete
    OnPostError = unqryConjuntoDetallePostError
    Left = 200
    Top = 24
    ParamData = <
      item
        DataType = ftInteger
        Name = 'ID_AC'
        ParamType = ptInput
        Value = nil
      end>
  end
  object unqryAtributosBasicosLookup: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT ID_ATB, ID_VA_ATB, CODIGO_ATB, NOMBRE_ATB,'
      '       DESCRIPCION_ATB, HEX_ATB, VALOR_NUM_ATB, UNIDAD_ATB'
      '  FROM fza_atributos_basicos'
      ' WHERE ESACTIVO_ATB = '#39'S'#39
      ' ORDER BY ID_VA_ATB, ORDEN_ATB, NOMBRE_ATB')
    Left = 712
    Top = 24
  end
  object dsAtributosBasicosLookup: TDataSource
    DataSet = unqryAtributosBasicosLookup
    Left = 712
    Top = 96
  end
  object dsConjuntoDetalle: TDataSource
    DataSet = unqryConjuntoDetalle
    Left = 200
    Top = 96
  end
  object unqryAtributosLookup: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT ID_ATB_VA,'
      '       CAST(GROUP_CONCAT(DISTINCT'
      '              COALESCE(NULLIF(TRIM(NOMBRE_VA), '#39#39'), ID_ATB_VA)'
      '              SEPARATOR '#39' / '#39') AS CHAR(200)) AS NOMBRE_VA'
      '  FROM fza_variaciones_atributos'
      ' GROUP BY ID_ATB_VA'
      ' ORDER BY MIN(ORDEN_VA), ID_ATB_VA')
    Left = 552
    Top = 176
  end
  object dsAtributosLookup: TDataSource
    DataSet = unqryAtributosLookup
    Left = 552
    Top = 248
  end
  object unqryArticulosConjunto: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT a.CODIGO_ART_ART, a.DESCRIPCION_ART, a.ESACTIVO_ART,'
      '       a.CODIGO_FAM_ART, f.NOMBRE_FAM_FAM,'
      '       asg.ID_AC_ACA'
      '  FROM fza_articulos_conjuntos_asign asg'
      
        '  INNER JOIN fza_articulos a ON a.CODIGO_ART_ART = asg.CODIGO_AR' +
        'T_ACA'
      
        '  LEFT JOIN fza_articulos_familias f ON f.CODIGO_FAM_FAM = a.COD' +
        'IGO_FAM_ART'
      ' ORDER BY a.CODIGO_ART_ART')
    MasterFields = 'ID_AC'
    DetailFields = 'ID_AC_ACA'
    Left = 552
    Top = 24
    ParamData = <
      item
        DataType = ftInteger
        Name = 'ID_AC'
        ParamType = ptInput
        Value = nil
      end>
  end
  object dsArticulosConjunto: TDataSource
    DataSet = unqryArticulosConjunto
    Left = 552
    Top = 96
  end
end
