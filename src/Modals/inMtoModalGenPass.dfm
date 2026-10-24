inherited frmModalGenPass: TfrmModalGenPass
  ActiveControl = edtPassword
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'Establecer Password Usuario'
  ClientHeight = 322
  ClientWidth = 440
  Position = poMainFormCenter
  OnClose = FormClose
  ExplicitWidth = 456
  ExplicitHeight = 361
  TextHeight = 19
  object edtUsuario: TcxTextEdit [0]
    Left = 24
    Top = 56
    Enabled = False
    TabOrder = 0
    Width = 392
  end
  object lbl1: TcxLabel [1]
    Left = 24
    Top = 24
    AutoSize = False
    Caption = 'Nombre usuario'
    FocusControl = edtUsuario
    Transparent = True
    Height = 24
    Width = 392
  end
  object edtPassword: TcxTextEdit [2]
    Left = 24
    Top = 131
    Properties.EchoMode = eemPassword
    Properties.PasswordChar = #9679
    Properties.MaxLength = 128
    TabOrder = 2
    Width = 392
  end
  object lbl2: TcxLabel [3]
    Left = 24
    Top = 99
    AutoSize = False
    Caption = 'Contrase'#241'a'
    FocusControl = edtPassword
    Transparent = True
    Height = 24
    Width = 392
  end
  object edtPasswordCon: TcxTextEdit [4]
    Left = 24
    Top = 206
    Properties.EchoMode = eemPassword
    Properties.PasswordChar = #9679
    Properties.MaxLength = 128
    TabOrder = 4
    Width = 392
  end
  object lbl3: TcxLabel [5]
    Left = 24
    Top = 174
    AutoSize = False
    Caption = 'Repita Contrase'#241'a'
    FocusControl = edtPasswordCon
    Transparent = True
    Height = 24
    Width = 392
  end
  object btnGuardar: TcxButton [6]
    Left = 271
    Top = 266
    Width = 145
    Height = 32
    Caption = '&Guardar'
    TabOrder = 6
    OnClick = btnGuardarClick
  end
  object btnCancelar: TcxButton [7]
    Left = 118
    Top = 266
    Width = 137
    Height = 32
    Cancel = True
    Caption = '&Cancelar'
    TabOrder = 7
    OnClick = btnCancelarClick
  end
end
