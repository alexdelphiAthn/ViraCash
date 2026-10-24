inherited dmFamilias: TdmFamilias
  Height = 282
  Width = 887
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_articulos_familias ('
      '  CODIGO_FAM_FAM,'
      '  ESACTIVO_FAM,'
      '  ORDEN_FAM,'
      '  ESDEFAULT_FAM,'
      '  CODIGO_PADRE_FAM,'
      '  NOMBRE_FAM_FAM,'
      '  DESCRIPCION_FAM,'
      '  CONTADOR_ART_FAM,'
      '  ESCONTADOR_ART_FAM,'
      '  PAD_ART_FAM,'
      '  TIPO_TRAZABILIDAD_FAM,'
      '  INSTANTE_MODIF,'
      '  INSTANTE_ALTA,'
      '  USUARIO_ALTA,'
      '  USUARIO_MODIF)'
      'VALUES ('
      '  :CODIGO_FAM_FAM,'
      '  :ESACTIVO_FAM,'
      '  :ORDEN_FAM,'
      '  :ESDEFAULT_FAM,'
      '  :CODIGO_PADRE_FAM,'
      '  :NOMBRE_FAM_FAM,'
      '  :DESCRIPCION_FAM,'
      '  :CONTADOR_ART_FAM,'
      '  :ESCONTADOR_ART_FAM,'
      '  :PAD_ART_FAM,'
      '  :TIPO_TRAZABILIDAD_FAM,'
      '  :INSTANTE_MODIF,'
      '  :INSTANTE_ALTA,'
      '  :USUARIO_ALTA,'
      '  :USUARIO_MODIF)')
    SQLDelete.Strings = (
      'DELETE FROM `fza_articulos_familias`'
      'WHERE'
      '  `CODIGO_FAM_FAM` = :`Old_CODIGO_FAM_FAM`')
    SQLUpdate.Strings = (
      'UPDATE fza_articulos_familias SET'
      '  CODIGO_FAM_FAM = :CODIGO_FAM_FAM,'
      '  ESACTIVO_FAM = :ESACTIVO_FAM,'
      '  ORDEN_FAM = :ORDEN_FAM,'
      '  ESDEFAULT_FAM = :ESDEFAULT_FAM,'
      '  CODIGO_PADRE_FAM = :CODIGO_PADRE_FAM,'
      '  NOMBRE_FAM_FAM = :NOMBRE_FAM_FAM,'
      '  DESCRIPCION_FAM = :DESCRIPCION_FAM,'
      '  CONTADOR_ART_FAM = :CONTADOR_ART_FAM,'
      '  ESCONTADOR_ART_FAM = :ESCONTADOR_ART_FAM,'
      '  PAD_ART_FAM = :PAD_ART_FAM,'
      '  TIPO_TRAZABILIDAD_FAM = :TIPO_TRAZABILIDAD_FAM,'
      '  INSTANTE_MODIF = :INSTANTE_MODIF,'
      '  INSTANTE_ALTA = :INSTANTE_ALTA,'
      '  USUARIO_ALTA = :USUARIO_ALTA,'
      '  USUARIO_MODIF = :USUARIO_MODIF'
      'WHERE CODIGO_FAM_FAM = :Old_CODIGO_FAM_FAM')
    SQLLock.Strings = (
      'SELECT'
      '  CODIGO_FAM_FAM,'
      '  ESACTIVO_FAM,'
      '  ORDEN_FAM,'
      '  ESDEFAULT_FAM,'
      '  CODIGO_PADRE_FAM,'
      '  NOMBRE_FAM_FAM,'
      '  DESCRIPCION_FAM,'
      '  CONTADOR_ART_FAM,'
      '  ESCONTADOR_ART_FAM,'
      '  PAD_ART_FAM,'
      '  TIPO_TRAZABILIDAD_FAM,'
      '  INSTANTE_MODIF,'
      '  INSTANTE_ALTA,'
      '  USUARIO_ALTA,'
      '  USUARIO_MODIF'
      'FROM fza_articulos_familias'
      'WHERE CODIGO_FAM_FAM = :Old_CODIGO_FAM_FAM'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      'SELECT'
      '  CODIGO_FAM_FAM,'
      '  ESACTIVO_FAM,'
      '  ORDEN_FAM,'
      '  ESDEFAULT_FAM,'
      '  CODIGO_PADRE_FAM,'
      '  NOMBRE_FAM_FAM,'
      '  DESCRIPCION_FAM,'
      '  CONTADOR_ART_FAM,'
      '  ESCONTADOR_ART_FAM,'
      '  PAD_ART_FAM,'
      '  TIPO_TRAZABILIDAD_FAM,'
      '  INSTANTE_MODIF,'
      '  INSTANTE_ALTA,'
      '  USUARIO_ALTA,'
      '  USUARIO_MODIF'
      'FROM fza_articulos_familias'
      'WHERE CODIGO_FAM_FAM = :CODIGO_FAM_FAM')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_articulos_familias')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT'
      '  F.CODIGO_FAM_FAM,'
      '  F.ESACTIVO_FAM,'
      '  F.ORDEN_FAM,'
      '  F.ESDEFAULT_FAM,'
      '  F.CODIGO_PADRE_FAM,'
      '  F.NOMBRE_FAM_FAM,'
      '  F.DESCRIPCION_FAM,'
      '  F.CONTADOR_ART_FAM,'
      '  F.ESCONTADOR_ART_FAM,'
      '  F.PAD_ART_FAM,'
      '  F.TIPO_TRAZABILIDAD_FAM,'
      '  F.INSTANTE_MODIF,'
      '  F.INSTANTE_ALTA,'
      '  F.USUARIO_ALTA,'
      '  F.USUARIO_MODIF,'
      '  (SELECT SUB.NOMBRE_FAM_FAM'
      '     FROM fza_articulos_familias SUB'
      '    WHERE SUB.CODIGO_FAM_FAM = F.CODIGO_PADRE_FAM)'
      '    AS NOMBRE_SUBFAMILIA'
      'FROM fza_articulos_familias F')
    Active = True
    AfterInsert = unqryTablaGAfterInsert
  end
  inherited unqryPerfiles: TUniQuery
    SQL.Strings = (
      'select *'
      'from fza_usuarios_perfiles'
      'where (KEY_USUPER = '#39'dmFamilias'#39' '
      'OR KEY_USUPER='#39'frmMtoFamilias'#39')')
  end
  object unstrdprcContador: TUniStoredProc
    StoredProcName = 'PRC_GET_NEXT_CONT'
    Connection = dmConn.conUni
    Left = 8
    Top = 84
  end
  object unqryArticulosFamilias: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_articulos_tarifas'
      
        '  (CODIGO_ART_ARTTAR, CODIGO_VARIACION_TARIFA, CODIGO_UNICO_ARTT' +
        'AR, CODIGO_TAR_ARTTAR, ESACTIVO_ARTTAR, PRECIOFINAL, FECHA_DESDE' +
        '_ARTTAR, FECHA_HASTA_ARTTAR, INSTANTE_MODIF, INSTANTE_ALTA, USUA' +
        'RIO_ALTA, USUARIO_MODIF)'
      'VALUES'
      
        '  (:CODIGO_ART_ARTTAR, :CODIGO_VARIACION_TARIFA, :CODIGO_UNICO_A' +
        'RTTAR, :CODIGO_TAR_ARTTAR, :ESACTIVO_ARTTAR, :PRECIOFINAL, :FECH' +
        'A_DESDE_ARTTAR, :FECHA_HASTA_ARTTAR, :INSTANTE_MODIF, :INSTANTE_' +
        'ALTA, :USUARIO_ALTA, :USUARIO_MODIF)')
    SQLDelete.Strings = (
      'DELETE FROM fza_articulos_tarifas'
      'WHERE'
      '  CODIGO_UNICO_ARTTAR = :Old_CODIGO_UNICO_ARTTAR')
    SQLUpdate.Strings = (
      'UPDATE fza_articulos_tarifas'
      'SET'
      
        '  CODIGO_ART_ARTTAR = :CODIGO_ART_ARTTAR, CODIGO_VARIACION_TARIF' +
        'A = :CODIGO_VARIACION_TARIFA, CODIGO_UNICO_ARTTAR = :CODIGO_UNIC' +
        'O_ARTTAR, CODIGO_TAR_ARTTAR = :CODIGO_TAR_ARTTAR, ESACTIVO_ARTTA' +
        'R = :ESACTIVO_ARTTAR, PRECIOFINAL = :PRECIOFINAL, FECHA_DESDE_AR' +
        'TTAR = :FECHA_DESDE_ARTTAR, FECHA_HASTA_ARTTAR = :FECHA_HASTA_AR' +
        'TTAR, INSTANTE_MODIF = :INSTANTE_MODIF, INSTANTE_ALTA = :INSTANT' +
        'E_ALTA, USUARIO_ALTA = :USUARIO_ALTA, USUARIO_MODIF = :USUARIO_M' +
        'ODIF'
      'WHERE'
      '  CODIGO_UNICO_ARTTAR = :Old_CODIGO_UNICO_ARTTAR')
    SQLLock.Strings = (
      'SELECT * FROM fza_articulos_tarifas'
      'WHERE'
      '  CODIGO_UNICO_ARTTAR = :Old_CODIGO_UNICO_ARTTAR'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT CODIGO_ART_ARTTAR, CODIGO_VARIACION_TARIFA, CODIGO_UNICO_' +
        'ARTTAR, CODIGO_TAR_ARTTAR, ESACTIVO_ARTTAR, PRECIOFINAL, FECHA_D' +
        'ESDE_ARTTAR, FECHA_HASTA_ARTTAR, INSTANTE_MODIF, INSTANTE_ALTA, ' +
        'USUARIO_ALTA, USUARIO_MODIF FROM fza_articulos_tarifas'
      'WHERE'
      '  CODIGO_UNICO_ARTTAR = :CODIGO_UNICO_ARTTAR')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_articulos_tarifas')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *  '
      '  FROM vi_art_busquedas'
      '')
    MasterSource = frmMtoFamilias.dsTablaG
    MasterFields = 'CODIGO_FAM_FAM'
    DetailFields = 'CODIGO_FAM_ART'
    Active = True
    BeforeInsert = unqryTablaGBeforeInsert
    AfterInsert = unqryTablaGAfterInsert
    BeforePost = unqryTablaGBeforePost
    Left = 256
    Top = 32
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_FAM_FAM'
        ParamType = ptInput
        Value = 'BOLSOS'
      end>
  end
  object dsArticulosFamilias: TDataSource
    DataSet = unqryArticulosFamilias
    Left = 256
    Top = 104
  end
  object unqrySubFamilias: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'select *'
      'from vi_articulos_familias_list')
    Left = 424
    Top = 32
  end
  object dsSubFamilias: TDataSource
    DataSet = unqrySubFamilias
    Left = 424
    Top = 96
  end
  object unqryFamiliasAtributos: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_familias_atributos'
      
        '  (CODIGO_FAM_FAM, CODIGO_PROP_ARTPROP, ESREQUERIDO_FA, ORDEN_MO' +
        'STRAR_FA)'
      'VALUES'
      
        '  (:CODIGO_FAM_FAM, :CODIGO_PROP_ARTPROP, :ESREQUERIDO_FA, :ORDE' +
        'N_MOSTRAR_FA)')
    SQLDelete.Strings = (
      'DELETE FROM fza_familias_atributos'
      'WHERE'
      
        '  CODIGO_FAM_FAM = :Old_CODIGO_FAM_FAM AND CODIGO_PROP_ARTPROP =' +
        ' :Old_CODIGO_PROP_ARTPROP')
    SQLUpdate.Strings = (
      'UPDATE fza_familias_atributos'
      'SET'
      
        '  CODIGO_FAM_FAM = :CODIGO_FAM_FAM, CODIGO_PROP_ARTPROP = :CODIG' +
        'O_PROP_ARTPROP, ESREQUERIDO_FA = :ESREQUERIDO_FA, ORDEN_MOSTRAR_' +
        'FA = :ORDEN_MOSTRAR_FA'
      'WHERE'
      
        '  CODIGO_FAM_FAM = :Old_CODIGO_FAM_FAM AND CODIGO_PROP_ARTPROP =' +
        ' :Old_CODIGO_PROP_ARTPROP')
    SQLLock.Strings = (
      
        'SELECT CODIGO_FAM_FAM, CODIGO_PROP_ARTPROP, ESREQUERIDO_FA, ORDE' +
        'N_MOSTRAR_FA FROM fza_familias_atributos'
      'WHERE'
      
        '  CODIGO_FAM_FAM = :Old_CODIGO_FAM_FAM AND CODIGO_PROP_ARTPROP =' +
        ' :Old_CODIGO_PROP_ARTPROP'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT CODIGO_FAM_FAM, CODIGO_PROP_ARTPROP, ESREQUERIDO_FA, ORDE' +
        'N_MOSTRAR_FA FROM fza_familias_atributos'
      'WHERE'
      
        '  CODIGO_FAM_FAM = :CODIGO_FAM_FAM AND CODIGO_PROP_ARTPROP = :CO' +
        'DIGO_PROP_ARTPROP')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_familias_atributos')
    Connection = dmConn.conUni
    SQL.Strings = (
      
        'SELECT fa.CODIGO_FAM_FAM, fa.CODIGO_PROP_ARTPROP, p.NOMBRE_PROP_' +
        'PROP, '
      '       fa.ESREQUERIDO_FA, fa.ORDEN_MOSTRAR_FA'
      'FROM fza_familias_atributos fa'
      
        'LEFT JOIN fza_propiedades p ON p.CODIGO_PROP_ARTPROP = fa.CODIGO' +
        '_PROP_ARTPROP'
      'ORDER BY fa.ORDEN_MOSTRAR_FA, p.NOMBRE_PROP_PROP')
    MasterSource = frmMtoFamilias.dsTablaG
    MasterFields = 'CODIGO_FAM_FAM'
    DetailFields = 'CODIGO_FAM_FAM'
    Active = True
    AfterInsert = unqryFamiliasAtributosAfterInsert
    BeforePost = unqryFamiliasAtributosBeforePost
    AfterPost = unqryFamiliasAtributosAfterPost
    Left = 648
    Top = 32
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_FAM_FAM'
        ParamType = ptInput
        Value = 'BOLSOS'
      end>
  end
  object dsFamiliasAtributos: TDataSource
    DataSet = unqryFamiliasAtributos
    Left = 648
    Top = 104
  end
  object unqryPropiedades: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_familias_atributos'
      
        '  (CODIGO_FAM_FAM, CODIGO_PROP_ARTPROP, ESREQUERIDO_FA, ORDEN_MO' +
        'STRAR_FA)'
      'VALUES'
      
        '  (:CODIGO_FAM_FAM, :CODIGO_PROP_ARTPROP, :ESREQUERIDO_FA, :ORDE' +
        'N_MOSTRAR_FA)')
    SQLDelete.Strings = (
      'DELETE FROM fza_familias_atributos'
      'WHERE'
      
        '  CODIGO_FAM_FAM = :Old_CODIGO_FAM_FAM AND CODIGO_PROP_ARTPROP =' +
        ' :Old_CODIGO_PROP_ARTPROP')
    SQLUpdate.Strings = (
      'UPDATE fza_familias_atributos'
      'SET'
      
        '  CODIGO_FAM_FAM = :CODIGO_FAM_FAM, CODIGO_PROP_ARTPROP = :CODIG' +
        'O_PROP_ARTPROP, ESREQUERIDO_FA = :ESREQUERIDO_FA, ORDEN_MOSTRAR_' +
        'FA = :ORDEN_MOSTRAR_FA'
      'WHERE'
      
        '  CODIGO_FAM_FAM = :Old_CODIGO_FAM_FAM AND CODIGO_PROP_ARTPROP =' +
        ' :Old_CODIGO_PROP_ARTPROP')
    SQLLock.Strings = (
      
        'SELECT CODIGO_FAM_FAM, CODIGO_PROP_ARTPROP, ESREQUERIDO_FA, ORDE' +
        'N_MOSTRAR_FA FROM fza_familias_atributos'
      'WHERE'
      
        '  CODIGO_FAM_FAM = :Old_CODIGO_FAM_FAM AND CODIGO_PROP_ARTPROP =' +
        ' :Old_CODIGO_PROP_ARTPROP'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT CODIGO_FAM_FAM, CODIGO_PROP_ARTPROP, ESREQUERIDO_FA, ORDE' +
        'N_MOSTRAR_FA FROM fza_familias_atributos'
      'WHERE'
      
        '  CODIGO_FAM_FAM = :CODIGO_FAM_FAM AND CODIGO_PROP_ARTPROP = :CO' +
        'DIGO_PROP_ARTPROP')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_familias_atributos')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT '
      '  P.CODIGO_PROP_ARTPROP, '
      '  P.NOMBRE_PROP_PROP'
      'FROM fza_propiedades  P'
      
        'WHERE P.ESACTIVO_PROP = '#39'S'#39' -- Solo mostramos las que est'#233'n acti' +
        'vas'
      
        'ORDER BY P.CODIGO_PROP_ARTPROP ASC; -- Ordenado alfab'#233'ticamente ' +
        'para el combo')
    DetailFields = 'CODIGO_FAM_FAM'
    BeforeInsert = unqryTablaGBeforeInsert
    BeforePost = unqryTablaGBeforePost
    Left = 792
    Top = 32
  end
  object dsPropiedades: TDataSource
    DataSet = unqryPropiedades
    Left = 792
    Top = 104
  end
end
