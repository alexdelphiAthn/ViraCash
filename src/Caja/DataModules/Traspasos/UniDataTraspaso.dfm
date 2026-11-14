object dmTraspaso: TdmTraspaso
  OnCreate = DataModuleCreate
  Height = 311
  Width = 458
  object cdsCabecera: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 48
    Top = 24
  end
  object cdsLineas: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 48
    Top = 96
  end
  object dsCabecera: TDataSource
    DataSet = cdsCabecera
    Left = 168
    Top = 24
  end
  object dsLineas: TDataSource
    DataSet = cdsLineas
    Left = 168
    Top = 96
  end
  object qryAux: TUniQuery
    Left = 288
    Top = 24
  end
end
