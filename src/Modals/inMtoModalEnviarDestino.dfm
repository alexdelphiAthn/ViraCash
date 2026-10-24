inherited frmModalEnviarDestino: TfrmModalEnviarDestino
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Enviar a...'
  ClientHeight = 168
  ClientWidth = 320
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  TextHeight = 15
  object lblAlmacen: TcxLabel
    Left = 16
    Top = 16
    Caption = 'Almacén'
  end
  object cbbAlmacen: TcxComboBox
    Left = 112
    Top = 14
    Properties.DropDownListStyle = lsFixedList
    TabOrder = 0
    Width = 185
  end
  object lblSerie: TcxLabel
    Left = 16
    Top = 48
    Caption = 'Serie'
  end
  object cbbSerie: TcxComboBox
    Left = 112
    Top = 46
    Properties.DropDownListStyle = lsFixedList
    TabOrder = 1
    Width = 185
  end
  object lblNumero: TcxLabel
    Left = 16
    Top = 80
    Caption = 'Número'
  end
  object txtNumero: TcxTextEdit
    Left = 112
    Top = 78
    TabOrder = 2
    Text = '0'
    Width = 185
  end
  object btnAceptar: TcxButton
    Left = 112
    Top = 120
    Width = 88
    Height = 30
    Caption = 'Aceptar'
    Default = True
    ModalResult = 1
    TabOrder = 3
  end
  object btnCancelar: TcxButton
    Left = 209
    Top = 120
    Width = 88
    Height = 30
    Cancel = True
    Caption = 'Cancelar'
    ModalResult = 2
    TabOrder = 4
  end
end
