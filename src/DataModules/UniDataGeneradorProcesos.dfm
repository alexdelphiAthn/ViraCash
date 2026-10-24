inherited dmGeneradorProcesos: TdmGeneradorProcesos
  Height = 169
  Width = 689
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *  '
      '  FROM fza_generadorprocesos'
      '')
    AfterInsert = unqryTablaGAfterInsert
    AfterScroll = unqryTablaGAfterScroll
  end
  inherited unqryPerfiles: TUniQuery
    SQL.Strings = ()
    Top = 88
  end
  inherited dsPerfiles: TDataSource
    Top = 32
  end
  object unstrdprcContador: TUniStoredProc
    StoredProcName = 'PRC_GET_NEXT_CONT'
    SQL.Strings = (
      
        'CALL PRC_GET_NEXT_CONT(:pTipoDoc, :pUSUARIO_MODIF, @pcont); SELECT @pcont AS '#39'@pcont'#39)
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
  object unqryMetadatos: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT '
      '  CAST(CODIGO_META_META AS CHAR) AS CODIGO_META_META,'
      '  NOMBRE_META_META,'
      '  PARENT_META'
      'FROM fza_metadatos'
      'ORDER BY PARENT_META, NOMBRE_META_META')
    AutoCalcFields = False
    Left = 184
    Top = 88
  end
  object dsMetadatos: TDataSource
    DataSet = unqryMetadatos
    Left = 184
    Top = 32
  end
  object dsEstructura: TDataSource
    DataSet = unqryEstructura
    Left = 272
    Top = 32
  end
  object unqryEstructura: TUniQuery
    SQL.Strings = (
      'select *'
      'from fza_metadatos')
    AutoCalcFields = False
    Left = 272
    Top = 88
  end
  object dsContenido: TDataSource
    DataSet = unqryContenido
    Left = 369
    Top = 32
  end
  object unqryContenido: TUniQuery
    SQL.Strings = (
      'select *'
      'from fza_metadatos')
    AutoCalcFields = False
    Left = 369
    Top = 88
  end
  object unstrdprcRefresh: TUniStoredProc
    StoredProcName = 'PRC_CREAR_METADATOS'
    SQL.Strings = (
      'CALL PRC_CREAR_METADATOS(:pDATABASENAME)')
    Connection = dmConn.conUni
    Left = 464
    Top = 88
    ParamData = <
      item
        DataType = ftString
        Name = 'pDATABASENAME'
        ParamType = ptInput
        Size = 100
        Value = nil
      end>
    CommandStoredProcName = 'PRC_CREAR_METADATOS'
  end
  object unqryVista: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'select *'
      'from fza_metadatos')
    AutoCalcFields = False
    Left = 625
    Top = 88
  end
  object dsVista: TDataSource
    DataSet = unqryVista
    Left = 625
    Top = 32
  end
  object unqryCommand: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'select *'
      'from fza_metadatos')
    AutoCalcFields = False
    Left = 553
    Top = 88
  end
end
