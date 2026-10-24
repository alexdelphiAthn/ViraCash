object frmSplash: TfrmSplash
  Left = 472
  Top = 190
  BorderIcons = []
  BorderStyle = bsNone
  ClientHeight = 518
  ClientWidth = 515
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = 'Source Sans 3'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 17
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 515
    Height = 518
    Align = alClient
    BevelInner = bvLowered
    TabOrder = 0
    object Panel3: TPanel
      Left = 2
      Top = 336
      Width = 511
      Height = 180
      Align = alBottom
      TabOrder = 0
      object cxLabel1: TcxLabel
        Left = 24
        Top = 48
        AutoSize = False
        Caption = 
          'Dedicado a mis hermanas, a mi mentor y maestro en programaci'#243'n J' +
          '.F.Criado, a mi compa'#241'era Ana M. y un especial agradecimiento a ' +
          ' la Biblioteca P'#250'blica de Zamora.'
        ParentFont = False
        Style.Font.Charset = DEFAULT_CHARSET
        Style.Font.Color = clWindowText
        Style.Font.Height = -15
        Style.Font.Name = 'Source Sans 3'
        Style.Font.Style = []
        Style.IsFontAssigned = True
        Properties.PenWidth = 2
        Properties.WordWrap = True
        TabOrder = 0
        Transparent = True
        OnClick = cxLabel1Click
        Height = 81
        Width = 457
      end
      object hlEmail: TcxHyperLinkEdit
        Left = 192
        Top = 6
        ParentFont = False
        Properties.Prefix = 'mailto:'
        Style.Font.Charset = DEFAULT_CHARSET
        Style.Font.Color = clWindowText
        Style.Font.Height = -15
        Style.Font.Name = 'Source Sans 3'
        Style.Font.Style = []
        Style.IsFontAssigned = True
        TabOrder = 1
        Text = 'alejandro.laorden@protonmail.com'
        Width = 289
      end
      object cxLabel2: TcxLabel
        Left = 16
        Top = 7
        AutoSize = False
        Caption = 'Contacto con el autor'
        ParentFont = False
        Style.Font.Charset = DEFAULT_CHARSET
        Style.Font.Color = clWindowText
        Style.Font.Height = -15
        Style.Font.Name = 'Source Sans 3'
        Style.Font.Style = []
        Style.IsFontAssigned = True
        Properties.PenWidth = 2
        Properties.WordWrap = True
        TabOrder = 2
        Transparent = True
        Height = 20
        Width = 185
      end
      object btnAceptar: TcxButton
        Left = 24
        Top = 135
        Width = 457
        Height = 25
        Caption = 'Aceptar'
        TabOrder = 3
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -15
        Font.Name = 'Source Sans 3'
        Font.Style = []
        ParentFont = False
        OnClick = btnAceptarClick
      end
    end
    object Panel2: TPanel
      Left = 26
      Top = 40
      Width = 457
      Height = 241
      TabOrder = 1
    end
  end
end
