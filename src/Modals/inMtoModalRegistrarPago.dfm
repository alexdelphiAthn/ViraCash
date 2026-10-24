inherited frmModalRegistrarPago: TfrmModalRegistrarPago
  Caption = 'Conciliar efecto'
  ClientHeight = 240
  ClientWidth = 360
  StyleElements = [seFont, seClient, seBorder]
  Position = poScreenCenter
  ExplicitWidth = 360
  ExplicitHeight = 240
  TextHeight = 19
  object pnlBody: TPanel [0]
    Left = 0
    Top = 0
    Width = 360
    Height = 184
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object lblInfo: TcxLabel
      Left = 16
      Top = 12
      Caption = ' '
      Style.Font.Style = [fsBold]
      Style.IsFontAssigned = True
      Transparent = True
    end
    object lblFecha: TcxLabel
      Left = 16
      Top = 48
      Caption = 'Fecha'
      Transparent = True
    end
    object dteFecha: TcxDateEdit
      Left = 16
      Top = 68
      TabOrder = 0
      Width = 130
    end
    object lblImporte: TcxLabel
      Left = 170
      Top = 48
      Caption = 'Importe conciliado'
      Transparent = True
    end
    object curImporte: TcxCurrencyEdit
      Left = 170
      Top = 68
      Properties.DisplayFormat = ',0.00 '#8364
      TabOrder = 1
      Width = 150
    end
    object lblTipo: TcxLabel
      Left = 16
      Top = 108
      Caption = 'Tipo'
      Transparent = True
    end
    object cbbTipo: TcxComboBox
      Left = 16
      Top = 128
      Properties.DropDownListStyle = lsFixedList
      Properties.Items.Strings = (
        'TRANSFERENCIA'
        'EFECTIVO'
        'CHEQUE'
        'DOMICILIADO'
        'CONFIRMING')
      TabOrder = 2
      Width = 130
    end
    object lblReferencia: TcxLabel
      Left = 170
      Top = 108
      Caption = 'Referencia'
      Transparent = True
    end
    object txtReferencia: TcxTextEdit
      Left = 170
      Top = 128
      Properties.MaxLength = 100
      TabOrder = 3
      Width = 150
    end
  end
  object pnlButton: TPanel [1]
    Left = 0
    Top = 184
    Width = 360
    Height = 56
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnCancelar: TcxButton
      Left = 16
      Top = 10
      Width = 130
      Height = 36
      Cancel = True
      Caption = '&Cancelar'
      TabOrder = 0
      OnClick = btnCancelarClick
    end
    object btnAceptar: TcxButton
      Left = 214
      Top = 10
      Width = 130
      Height = 36
      Caption = '&Aceptar'
      Default = True
      TabOrder = 1
      OnClick = btnAceptarClick
    end
  end
end
