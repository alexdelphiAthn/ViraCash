inherited frmModalCorregirPago: TfrmModalCorregirPago
  BorderStyle = bsDialog
  Caption = 'Corregir forma de pago'
  ClientHeight = 366
  ClientWidth = 590
  Position = poOwnerFormCenter
  object lblCobro: TcxLabel
    Left = 16
    Top = 12
    TabOrder = 6
  end
  object cboCobro: TcxComboBox
    Left = 16
    Top = 36
    Properties.DropDownListStyle = lsFixedList
    Properties.OnChange = SeleccionChange
    TabOrder = 0
    Width = 554
  end
  object lblMedio: TcxLabel
    Left = 16
    Top = 70
    TabOrder = 7
  end
  object cboMedio: TcxComboBox
    Left = 16
    Top = 94
    Properties.DropDownListStyle = lsFixedList
    Properties.OnChange = SeleccionChange
    TabOrder = 1
    Width = 554
  end
  object lblReferencia: TcxLabel
    Left = 16
    Top = 128
    TabOrder = 8
  end
  object edtReferencia: TcxTextEdit
    Left = 16
    Top = 152
    Properties.MaxLength = 255
    TabOrder = 2
    Width = 554
  end
  object lblMotivo: TcxLabel
    Left = 16
    Top = 186
    TabOrder = 9
  end
  object edtMotivo: TcxTextEdit
    Left = 16
    Top = 210
    Properties.MaxLength = 180
    TabOrder = 3
    Width = 554
  end
  object lblResumen: TcxLabel
    Left = 16
    Top = 246
    AutoSize = False
    Properties.WordWrap = True
    TabOrder = 10
    Height = 62
    Width = 554
  end
  object btnGuardar: TcxButton
    Left = 250
    Top = 320
    Width = 190
    Height = 30
    Default = True
    TabOrder = 4
    OnClick = btnGuardarClick
  end
  object btnCancelar: TcxButton
    Left = 450
    Top = 320
    Width = 120
    Height = 30
    Cancel = True
    ModalResult = 2
    TabOrder = 5
  end
end
