inherited frmModalGenImpSave: TfrmModalGenImpSave
  BorderIcons = []
  BorderStyle = bsSingle
  Caption = 'Guardar Objeto Editado'
  ClientHeight = 188
  ClientWidth = 502
  Position = poMainFormCenter
  OnClose = FormClose
  ExplicitLeft = 3
  ExplicitTop = 3
  ExplicitWidth = 514
  ExplicitHeight = 226
  TextHeight = 19
  object edtNombreOrigen: TcxTextEdit [0]
    Left = 187
    Top = 24
    Enabled = False
    TabOrder = 0
    Width = 286
  end
  object lbl1: TcxLabel [1]
    Left = 47
    Top = 25
    Caption = 'Nombre origen'
    TabOrder = 1
    Transparent = True
  end
  object edtDescripcion: TcxTextEdit [2]
    Left = 187
    Top = 64
    TabOrder = 2
    Width = 286
  end
  object lbl2: TcxLabel [3]
    Left = 17
    Top = 65
    Caption = 'Nombre del objeto'
    TabOrder = 3
    Transparent = True
  end
  object lbl3: TcxLabel [4]
    Left = 107
    Top = 102
    Caption = 'Permiso'
    TabOrder = 4
    Transparent = True
  end
  object btnGuardar: TcxButton [5]
    Left = 8
    Top = 146
    Width = 145
    Height = 25
    Caption = '&Guardar'
    TabOrder = 5
    OnClick = btnGuardarClick
  end
  object btnCancelar: TcxButton [6]
    Left = 336
    Top = 146
    Width = 137
    Height = 25
    Caption = '&Cancelar'
    TabOrder = 6
    OnClick = btnCancelarClick
  end
  object cbbPermisos: TcxComboBox [7]
    Left = 184
    Top = 101
    TabOrder = 7
    Width = 289
  end
end
