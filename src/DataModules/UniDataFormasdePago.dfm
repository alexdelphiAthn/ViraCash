inherited dmFormasdePago: TdmFormasdePago
  Height = 155
  Width = 522
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *  '
      '  FROM vi_formapago'
      '')
    Active = True
    AfterInsert = unqryTablaGAfterInsert
  end
  inherited unqryPerfiles: TUniQuery
    SQL.Strings = (
      'select *'
      'from fza_usuarios_perfiles'
      'where (KEY_USUPER = '#39'dmFormasdePago'#39' '
      'OR KEY_USUPER='#39'frmMtoFormasdePago'#39')')
  end
  object unstrdprcContador: TUniStoredProc
    StoredProcName = 'PRC_GET_NEXT_CONT'
    Connection = dmConn.conUni
    Left = 8
    Top = 84
  end
  object unqryFacturasLineas: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_historia'
      
        '  (ID, CODIGO_ART_ART, DESCRIPCION_ART, CODIGO_CLI_CLI, PRECIOVE' +
        'NTA_ARTICULO, FECHA, ZONA, DESCRIPCION_HISTORIA, NUMERO_FAC, LIN' +
        'EA_LINEA, ODONTOLOGO, SERIE_FAC)'
      'VALUES'
      
        '  (:ID, :CODIGO_ART_ART, :DESCRIPCION_ART, :CODIGO_CLI_CLI, :PRE' +
        'CIOVENTA_ARTICULO, :FECHA, :ZONA, :DESCRIPCION_HISTORIA, :NUMERO' +
        '_FAC, :LINEA_LINEA, :ODONTOLOGO, :SERIE_FAC)')
    SQLDelete.Strings = (
      'DELETE FROM fza_historia'
      'WHERE'
      '  ID = :Old_ID')
    SQLUpdate.Strings = (
      'UPDATE fza_historia'
      'SET'
      
        '  ID = :ID, CODIGO_ART_ART = :CODIGO_ART_ART, DESCRIPCION_ART = ' +
        ':DESCRIPCION_ART, CODIGO_CLI_CLI = :CODIGO_CLI_CLI, PRECIOVENTA_' +
        'ARTICULO = :PRECIOVENTA_ARTICULO, FECHA = :FECHA, ZONA = :ZONA, ' +
        'DESCRIPCION_HISTORIA = :DESCRIPCION_HISTORIA, NUMERO_FAC = :NUME' +
        'RO_FAC, LINEA_LINEA = :LINEA_LINEA, ODONTOLOGO = :ODONTOLOGO, SE' +
        'RIE_FAC = :SERIE_FAC'
      'WHERE'
      '  ID = :Old_ID')
    SQLLock.Strings = (
      'SELECT * FROM fza_historia'
      'WHERE'
      '  ID = :Old_ID'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT ID, CODIGO_ART_ART, DESCRIPCION_ART, CODIGO_CLI_CLI, PREC' +
        'IOVENTA_ARTICULO, FECHA, ZONA, DESCRIPCION_HISTORIA, NUMERO_FAC,' +
        ' LINEA_LINEA, ODONTOLOGO, SERIE_FAC FROM fza_historia'
      'WHERE'
      '  ID = :ID')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_historia')
    Connection = dmConn.conUni
    SQL.Strings = (
      'select *'
      'from vi_fac_lin_busquedas l'
      'inner join vi_fac_busquedas f'
      'on l.NUMERO_FAC_FACLIN = f.NUMERO_FAC'
      'AND l.SERIE_FAC_FACLIN = f.SERIE_FAC'
      '')
    MasterFields = 'CODIGO_FP_FP'
    DetailFields = 'FORMA_PAGO_FAC'
    ReadOnly = True
    Active = True
    Left = 215
    Top = 24
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'CODIGO_FP_FP'
        Value = nil
      end>
  end
  object unqryFacturas: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_historia'
      
        '  (ID, CODIGO_ART_ART, DESCRIPCION_ART, CODIGO_CLI_CLI, PRECIOVE' +
        'NTA_ARTICULO, FECHA, ZONA, DESCRIPCION_HISTORIA, NUMERO_FAC, LIN' +
        'EA_LINEA, ODONTOLOGO, SERIE_FAC)'
      'VALUES'
      
        '  (:ID, :CODIGO_ART_ART, :DESCRIPCION_ART, :CODIGO_CLI_CLI, :PRE' +
        'CIOVENTA_ARTICULO, :FECHA, :ZONA, :DESCRIPCION_HISTORIA, :NUMERO' +
        '_FAC, :LINEA_LINEA, :ODONTOLOGO, :SERIE_FAC)')
    SQLDelete.Strings = (
      'DELETE FROM fza_historia'
      'WHERE'
      '  ID = :Old_ID')
    SQLUpdate.Strings = (
      'UPDATE fza_historia'
      'SET'
      
        '  ID = :ID, CODIGO_ART_ART = :CODIGO_ART_ART, DESCRIPCION_ART = ' +
        ':DESCRIPCION_ART, CODIGO_CLI_CLI = :CODIGO_CLI_CLI, PRECIOVENTA_' +
        'ARTICULO = :PRECIOVENTA_ARTICULO, FECHA = :FECHA, ZONA = :ZONA, ' +
        'DESCRIPCION_HISTORIA = :DESCRIPCION_HISTORIA, NUMERO_FAC = :NUME' +
        'RO_FAC, LINEA_LINEA = :LINEA_LINEA, ODONTOLOGO = :ODONTOLOGO, SE' +
        'RIE_FAC = :SERIE_FAC'
      'WHERE'
      '  ID = :Old_ID')
    SQLLock.Strings = (
      'SELECT * FROM fza_historia'
      'WHERE'
      '  ID = :Old_ID'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT ID, CODIGO_ART_ART, DESCRIPCION_ART, CODIGO_CLI_CLI, PREC' +
        'IOVENTA_ARTICULO, FECHA, ZONA, DESCRIPCION_HISTORIA, NUMERO_FAC,' +
        ' LINEA_LINEA, ODONTOLOGO, SERIE_FAC FROM fza_historia'
      'WHERE'
      '  ID = :ID')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_historia')
    Connection = dmConn.conUni
    SQL.Strings = (
      'select * from vi_fac_busquedas')
    MasterFields = 'CODIGO_FP_FP'
    DetailFields = 'FORMA_PAGO_FAC'
    ReadOnly = True
    Active = True
    Left = 359
    Top = 24
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'CODIGO_FP_FP'
        Value = nil
      end>
  end
  object dsFacturas: TDataSource
    DataSet = unqryFacturas
    Left = 215
    Top = 80
  end
  object dsFacturasLineas: TDataSource
    DataSet = unqryFacturasLineas
    Left = 359
    Top = 80
  end
end
