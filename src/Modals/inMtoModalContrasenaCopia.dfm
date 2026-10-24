inherited frmModalContrasenaCopia: TfrmModalContrasenaCopia
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'Contraseña de copia'
  ClientHeight = 224
  ClientWidth = 520
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  TextHeight = 19
  object lblExplicacion: TcxLabel [0]
    Left = 24
    Top = 16
    AutoSize = False
    Caption = 'Introduzca la contraseña de la copia.'
    Properties.WordWrap = True
    Transparent = True
    Height = 48
    Width = 472
  end
  object lblContrasena: TcxLabel [1]
    Left = 24
    Top = 77
    Caption = 'Contraseña'
    Transparent = True
  end
  object edtContrasena: TcxTextEdit [2]
    Left = 176
    Top = 75
    Properties.EchoMode = eemPassword
    Properties.PasswordChar = #9679
    TabOrder = 2
    Width = 320
  end
  object lblConfirmacion: TcxLabel [3]
    Left = 24
    Top = 117
    Caption = 'Repita la contraseña'
    Transparent = True
  end
  object edtConfirmacion: TcxTextEdit [4]
    Left = 176
    Top = 115
    Properties.EchoMode = eemPassword
    Properties.PasswordChar = #9679
    TabOrder = 4
    Width = 320
  end
  object btnAceptar: TcxButton [5]
    Left = 328
    Top = 171
    Width = 168
    Height = 32
    Caption = '&Aceptar'
    Default = True
    TabOrder = 5
    OnClick = btnAceptarClick
  end
  object btnCancelar: TcxButton [6]
    Left = 152
    Top = 171
    Width = 160
    Height = 32
    Cancel = True
    Caption = '&Cancelar'
    TabOrder = 6
    OnClick = btnCancelarClick
  end
end
