object dmConsultaOpe: TdmConsultaOpe
  OnCreate = DataModuleCreate
  Height = 500
  Width = 750
  PixelsPerInch = 120
  object qryMaestro: TUniQuery
    Left = 50
    Top = 22
  end
  object qryOperacion: TUniQuery
    Left = 346
    Top = 60
  end
  object qryPagos: TUniQuery
    Left = 458
    Top = 63
  end
  object qryVales: TUniQuery
    Left = 458
    Top = 230
  end
  object qryMovimientos: TUniQuery
    Left = 570
    Top = 66
  end
  object qryCliente: TUniQuery
    Left = 50
    Top = 240
  end
  object qryDepositos: TUniQuery
    Left = 50
    Top = 310
  end
  object qryFactura: TUniQuery
    Left = 50
    Top = 380
  end
  object qryFacturaLin: TUniQuery
    Left = 50
    Top = 450
  end
  object dsMaestro: TDataSource
    DataSet = qryMaestro
    Left = 200
    Top = 22
  end
  object dsOperacion: TDataSource
    DataSet = qryOperacion
    Left = 344
    Top = 140
  end
  object dsPagos: TDataSource
    DataSet = qryPagos
    Left = 456
    Top = 143
  end
  object dsVales: TDataSource
    DataSet = qryVales
    Left = 568
    Top = 230
  end
  object dsMovimientos: TDataSource
    DataSet = qryMovimientos
    Left = 568
    Top = 146
  end
  object dsCliente: TDataSource
    DataSet = qryCliente
    Left = 200
    Top = 240
  end
  object dsDepositos: TDataSource
    DataSet = qryDepositos
    Left = 200
    Top = 310
  end
  object dsFactura: TDataSource
    DataSet = qryFactura
    Left = 200
    Top = 380
  end
  object dsFacturaLin: TDataSource
    DataSet = qryFacturaLin
    Left = 200
    Top = 450
  end
end
