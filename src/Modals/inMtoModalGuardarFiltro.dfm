inherited frmModalGuardarFiltro: TfrmModalGuardarFiltro
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Guardar filtro'
  ClientHeight = 160
  ClientWidth = 420
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = 'Source Sans 3'
  Font.Pitch = fpFixed
  Font.Style = []
  Font.Quality = fqClearTypeNatural
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 17
  object lblNombre: TcxLabel
    Left = 16
    Top = 20
    Caption = 'Nombre'
    TabOrder = 0
    Transparent = True
  end
  object txtNombre: TcxTextEdit
    Left = 120
    Top = 18
    TabOrder = 1
    Width = 284
  end
  object lblDescripcion: TcxLabel
    Left = 16
    Top = 60
    Caption = 'Descripcion'
    TabOrder = 2
    Transparent = True
  end
  object txtDescripcion: TcxTextEdit
    Left = 120
    Top = 58
    TabOrder = 3
    Width = 284
  end
  object btnGuardar: TcxButton
    Left = 120
    Top = 110
    Width = 130
    Height = 25
    Caption = '&Guardar'
    Default = True
    TabOrder = 4
    OnClick = btnGuardarClick
  end
  object btnCancelar: TcxButton
    Left = 270
    Top = 110
    Width = 130
    Height = 25
    Cancel = True
    Caption = '&Cancelar'
    TabOrder = 5
    OnClick = btnCancelarClick
  end
end
