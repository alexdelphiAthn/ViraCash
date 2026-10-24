inherited frmMtoModalGenImpEle: TfrmMtoModalGenImpEle
  BorderIcons = []
  Caption = 'Elecci'#243'n de formulario creados por el usuario'
  ClientHeight = 152
  ClientWidth = 709
  Position = poMainFormCenter
  OnClose = FormClose
  ExplicitWidth = 721
  ExplicitHeight = 190
  TextHeight = 19
  object pnl1: TPanel [0]
    Left = 506
    Top = 0
    Width = 203
    Height = 152
    Align = alRight
    TabOrder = 0
    ExplicitLeft = 500
    ExplicitHeight = 143
    object btnUsarOriginal: TcxButton
      Left = 0
      Top = 1
      Width = 202
      Height = 25
      Caption = 'Usar &Original'
      TabOrder = 0
      OnClick = btnUsarOriginalClick
    end
    object btnSelectFormato: TcxButton
      Left = 0
      Top = 25
      Width = 202
      Height = 25
      Caption = 'Usar &Formato Elegido'
      TabOrder = 1
      OnClick = btnSelectFormatoClick
    end
    object btnDeleteFormato: TcxButton
      Left = 0
      Top = 49
      Width = 202
      Height = 25
      Caption = '&Borrar Formato Elegido'
      TabOrder = 2
      OnClick = btnDeleteFormatoClick
    end
    object btnSalir: TcxButton
      Left = 0
      Top = 73
      Width = 202
      Height = 25
      Caption = '&Volver'
      TabOrder = 3
      OnClick = btnSalirClick
    end
    object chkPredeterminado: TcxCheckBox
      Left = 14
      Top = 120
      Caption = 'Guardar selecci'#243'n'
      TabOrder = 4
      Transparent = True
    end
  end
  object pnl2: TPanel [1]
    Left = 0
    Top = 0
    Width = 506
    Height = 152
    Align = alClient
    TabOrder = 1
    ExplicitWidth = 500
    ExplicitHeight = 143
    object lstFormatos: TcxListBox
      Left = 1
      Top = 1
      Width = 504
      Height = 150
      Align = alClient
      ExtendedSelect = False
      ItemHeight = 19
      ScrollWidth = 50
      TabOrder = 0
      ExplicitWidth = 498
      ExplicitHeight = 141
    end
  end
  inherited Localizer1: TcxLocalizer
    Left = 232
    Top = 440
  end
end
