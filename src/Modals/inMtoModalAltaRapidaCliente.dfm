inherited frmModalAltaRapidaCliente: TfrmModalAltaRapidaCliente
  BorderStyle = bsDialog
  Caption = 'Alta rápida de cliente'
  ClientHeight = 392
  ClientWidth = 560
  Position = poOwnerFormCenter
  ActiveControl = edtRazonSocial
  object lblRazonSocial: TcxLabel
    Left = 24
    Top = 27
    Caption = 'Razón social:'
    TabOrder = 9
    Transparent = True
  end
  object edtRazonSocial: TcxTextEdit
    Left = 160
    Top = 24
    Properties.MaxLength = 200
    TabOrder = 0
    Width = 376
  end
  object lblNif: TcxLabel
    Left = 24
    Top = 67
    Caption = 'NIF:'
    TabOrder = 10
    Transparent = True
  end
  object edtNif: TcxTextEdit
    Left = 160
    Top = 64
    Properties.MaxLength = 50
    TabOrder = 1
    Width = 376
  end
  object lblDireccion: TcxLabel
    Left = 24
    Top = 107
    Caption = 'Dirección:'
    TabOrder = 11
    Transparent = True
  end
  object edtDireccion: TcxTextEdit
    Left = 160
    Top = 104
    Properties.MaxLength = 200
    TabOrder = 2
    Width = 376
  end
  object lblCodigoPostal: TcxLabel
    Left = 24
    Top = 147
    Caption = 'Código postal:'
    TabOrder = 12
    Transparent = True
  end
  object edtCodigoPostal: TcxTextEdit
    Left = 160
    Top = 144
    Properties.MaxLength = 15
    TabOrder = 3
    Width = 376
  end
  object lblPoblacion: TcxLabel
    Left = 24
    Top = 187
    Caption = 'Población:'
    TabOrder = 13
    Transparent = True
  end
  object edtPoblacion: TcxTextEdit
    Left = 160
    Top = 184
    Properties.MaxLength = 200
    TabOrder = 4
    Width = 376
  end
  object lblProvincia: TcxLabel
    Left = 24
    Top = 227
    Caption = 'Provincia:'
    TabOrder = 14
    Transparent = True
  end
  object edtProvincia: TcxTextEdit
    Left = 160
    Top = 224
    Properties.MaxLength = 200
    TabOrder = 5
    Width = 376
  end
  object lblPais: TcxLabel
    Left = 24
    Top = 267
    Caption = 'País:'
    TabOrder = 15
    Transparent = True
  end
  object cbbPais: TcxComboBox
    Left = 160
    Top = 264
    Properties.DropDownListStyle = lsFixedList
    TabOrder = 6
    Width = 376
  end
  object chkComprobarNif: TcxCheckBox
    Left = 160
    Top = 304
    Caption = 'Comprobar NIF'
    State = cbsChecked
    TabOrder = 7
    Width = 240
  end
  object pnlBotones: TPanel
    Left = 0
    Top = 344
    Width = 560
    Height = 48
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 8
    object btnCancelar: TcxButton
      Left = 80
      Top = 8
      Width = 177
      Height = 32
      Cancel = True
      Caption = '&Cancelar (ESC)'
      ModalResult = 2
      TabOrder = 0
    end
    object btnGuardar: TcxButton
      Left = 300
      Top = 8
      Width = 177
      Height = 32
      Caption = '&Guardar cliente'
      Default = True
      TabOrder = 1
      OnClick = btnGuardarClick
    end
  end
end
