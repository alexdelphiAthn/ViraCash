inherited frmModalSerieFechaFactura: TfrmModalSerieFechaFactura
  Caption = 'Borrador normal: serie y fecha'
  ClientHeight = 200
  ClientWidth = 440
  Position = poScreenCenter
  TextHeight = 19
  object lblSerie: TcxLabel [0]
    Left = 24
    Top = 35
    Caption = 'Serie borrador:'
    Transparent = True
  end
  object cbbSerie: TcxLookupComboBox [1]
    Left = 150
    Top = 32
    Width = 180
    Properties.DropDownListStyle = lsFixedList
    Properties.KeyFieldNames = 'SERIE_CON'
    Properties.ListColumns = <
      item
        Caption = 'Serie'
        Width = 120
        FieldName = 'SERIE_CON'
      end>
    Properties.ListSource = dsSeries
    TabOrder = 0
  end
  object lblFecha: TcxLabel [2]
    Left = 24
    Top = 79
    Caption = 'Fecha borrador:'
    Transparent = True
  end
  object dtFecha: TcxDateEdit [3]
    Left = 150
    Top = 76
    Width = 140
    TabOrder = 1
  end
  object pnlButton: TPanel [4]
    Left = 0
    Top = 141
    Width = 440
    Height = 59
    Align = alBottom
    TabOrder = 2
    object btnCancelar: TcxButton
      Left = 32
      Top = 9
      Width = 177
      Height = 40
      Cancel = True
      Caption = '&Cancelar (ESC)'
      TabOrder = 0
      OnClick = btnCancelarClick
    end
    object btnAceptar: TcxButton
      Left = 232
      Top = 9
      Width = 177
      Height = 40
      Caption = '&Aceptar'
      Default = True
      TabOrder = 1
      OnClick = btnAceptarClick
    end
  end
  object dsSeries: TDataSource
    Left = 360
    Top = 72
  end
end
