inherited frmVistaLlamadas: TfrmVistaLlamadas
  BorderStyle = bsDialog
  ClientHeight = 390
  ClientWidth = 470
  Position = poOwnerFormCenter
  object lblCampos: TcxLabel
    Left = 16
    Top = 10
    FocusControl = lstCampos
  end
  object lstCampos: TcxCheckListBox
    Left = 16
    Top = 36
    Width = 436
    Height = 157
    TabOrder = 1
  end
  object lblFiltro: TcxLabel
    Left = 16
    Top = 201
    FocusControl = cmbFiltro
  end
  object cmbFiltro: TcxComboBox
    Left = 16
    Top = 226
    Width = 436
    Properties.DropDownListStyle = lsFixedList
    TabOrder = 3
  end
  object lblNombre: TcxLabel
    Left = 16
    Top = 262
    FocusControl = edtNombre
  end
  object edtNombre: TcxTextEdit
    Left = 16
    Top = 287
    Width = 436
    TabOrder = 5
  end
  object btnGuardar: TcxButton
    Left = 192
    Top = 340
    Width = 144
    Height = 34
    Default = True
    ModalResult = 1
    TabOrder = 6
  end
  object btnCancelar: TcxButton
    Left = 344
    Top = 340
    Width = 108
    Height = 34
    Cancel = True
    ModalResult = 2
    TabOrder = 7
  end
end
