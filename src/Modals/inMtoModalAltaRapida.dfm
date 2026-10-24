inherited frmMtoModalAltaRapida: TfrmMtoModalAltaRapida
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Alta r'#225'pida'
  ClientHeight = 600
  ClientWidth = 450
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = 'Source Sans 3'
  Font.Style = []
  Position = poScreenCenter
  TextHeight = 17
  object ScrollBox: TcxScrollBox
    Left = 0
    Top = 0
    Width = 450
    Height = 550
    Align = alClient
    BorderStyle = cxcbsNone
    TabOrder = 0
    ExplicitWidth = 448
    ExplicitHeight = 542
    object BevelSep: TBevel
      Left = 25
      Top = 125
      Width = 380
      Height = 2
      Shape = bsTopLine
    end
    object lblCod: TcxLabel
      Left = 25
      Top = 15
      Caption = 'C'#243'digo:'
      TabOrder = 2
      Transparent = True
    end
    object edtCod: TcxTextEdit
      Left = 25
      Top = 35
      TabOrder = 0
      Width = 150
    end
    object lblDesc: TcxLabel
      Left = 25
      Top = 70
      Caption = 'Descripci'#243'n:'
      TabOrder = 3
      Transparent = True
    end
    object edtDesc: TcxTextEdit
      Left = 25
      Top = 90
      TabOrder = 1
      Width = 380
    end
  end
  object pnlBotones: TPanel
    Left = 0
    Top = 550
    Width = 450
    Height = 50
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    ExplicitTop = 542
    ExplicitWidth = 448
    object btnOk: TcxButton
      Left = 230
      Top = 12
      Width = 90
      Height = 30
      Caption = '&Guardar'
      Default = True
      LookAndFeel.NativeStyle = False
      ModalResult = 1
      TabOrder = 0
    end
    object btnCancel: TcxButton
      Left = 330
      Top = 12
      Width = 90
      Height = 30
      Cancel = True
      Caption = '&Cancelar'
      LookAndFeel.NativeStyle = False
      ModalResult = 2
      TabOrder = 1
    end
  end
end
