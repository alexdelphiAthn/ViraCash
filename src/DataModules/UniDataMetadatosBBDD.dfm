inherited dmMetadatosBBDD: TdmMetadatosBBDD
  Height = 175
  Width = 600
  PixelsPerInch = 120
  inherited unqryPerfiles: TUniQuery
    Left = 504
    Top = 112
  end
  inherited dsPerfiles: TDataSource
    Left = 504
    Top = 56
  end
  object unqryMetadatos: TUniQuery
    SQL.Strings = (
      'SELECT'
      '  CAST(CODIGO_META_META AS CHAR) AS CODIGO_META_META,'
      '  NOMBRE_META_META,'
      '  PARENT_META'
      'FROM fza_metadatos'
      'WHERE PARENT_META = :pTIPO'
      'ORDER BY NOMBRE_META_META')
    AutoCalcFields = False
    Left = 112
    Top = 112
  end
  object dsMetadatos: TDataSource
    DataSet = unqryMetadatos
    Left = 112
    Top = 56
  end
  object unqryEstructura: TUniQuery
    AutoCalcFields = False
    Left = 216
    Top = 112
  end
  object unqryContenido: TUniQuery
    AutoCalcFields = False
    Left = 320
    Top = 112
  end
  object dsContenido: TDataSource
    DataSet = unqryContenido
    Left = 320
    Top = 56
  end
  object unstrdprcRefrescar: TUniStoredProc
    StoredProcName = 'PRC_CREAR_METADATOS'
    SQL.Strings = (
      'CALL PRC_CREAR_METADATOS(:pDATABASENAME)')
    Left = 416
    Top = 112
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
end
