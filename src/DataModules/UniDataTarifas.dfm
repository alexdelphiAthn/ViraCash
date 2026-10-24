inherited dmTarifas: TdmTarifas
  Width = 400
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *  '
      '  FROM vi_tarifas'
      '')
    AfterInsert = unqryTablaGAfterInsert
    AfterPost = unqryTablaGAfterPost
    BeforeDelete = unqryTablaGBeforeDelete
    AfterDelete = unqryTablaGAfterDelete
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
    SQL.Strings = (
      
        'CALL PRC_GET_NEXT_CONT(:pTipoDoc, @pcont); SELECT CAST(@pcont AS' +
        ' SIGNED) AS '#39'@pcont'#39)
    Connection = dmConn.conUni
    Left = 8
    Top = 84
    ParamData = <
      item
        DataType = ftString
        Name = 'pTipoDoc'
        ParamType = ptInput
        Size = 2
        Value = nil
      end
      item
        DataType = ftInteger
        Name = 'pcont'
        ParamType = ptOutput
        Value = nil
      end>
    CommandStoredProcName = 'PRC_GET_NEXT_CONT'
  end
  object unqryArticulosTarifas: TUniQuery
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
      '  FROM vi_articulos_tarifas'
      '')
    MasterSource = frmMtoTarifas.dsTablaG
    MasterFields = 'CODIGO_TAR_ARTTAR'
    DetailFields = 'CODIGO_TAR_ARTTAR'
    BeforeInsert = unqryTablaGBeforeInsert
    AfterInsert = unqryTablaGAfterInsert
    BeforePost = unqryArticulosTarifasBeforePost
    AfterPost = unqryArticulosTarifasAfterPost
    BeforeDelete = unqryArticulosTarifasBeforeDelete
    AfterDelete = unqryArticulosTarifasAfterDelete
    Left = 200
    Top = 24
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_TAR_ARTTAR'
        ParamType = ptInput
        Value = '0'
      end>
  end
  object dsArticulosTarifas: TDataSource
    DataSet = unqryArticulosTarifas
    Left = 200
    Top = 80
  end
end
