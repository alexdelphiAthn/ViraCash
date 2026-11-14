inherited frmCajaReferenciaPago: TfrmCajaReferenciaPago
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Datos de Pago'
  ClientHeight = 541
  ClientWidth = 500
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -14
  Font.Name = 'Source Sans 3'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  OnShow = FormShow
  TextHeight = 16
  object pnlPrincipal: TPanel
    Left = 0
    Top = 0
    Width = 500
    Height = 481
    Align = alClient
    BevelOuter = bvNone
    ParentColor = True
    TabOrder = 0
    ExplicitWidth = 498
    ExplicitHeight = 452
    object gbInfoPago: TcxGroupBox
      Left = 10
      Top = 9
      Caption = ' Informaci'#243'n del Pago '
      ParentFont = False
      Style.Font.Charset = DEFAULT_CHARSET
      Style.Font.Color = clWindowText
      Style.Font.Height = -17
      Style.Font.Name = 'Source Sans 3'
      Style.Font.Style = []
      Style.IsFontAssigned = True
      TabOrder = 0
      Height = 100
      Width = 480
      object lblFormaPago: TcxLabel
        Left = 8
        Top = 23
        AutoSize = False
        Caption = 'Forma de Pago:'
        Properties.Alignment.Horz = taRightJustify
        TabOrder = 0
        Height = 24
        Width = 152
        AnchorX = 160
      end
      object lblFormaPagoValor: TcxLabel
        Left = 170
        Top = 23
        AutoSize = False
        Caption = 'Tarjeta Bancaria'
        Properties.ShowEndEllipsis = True
        TabOrder = 1
        Height = 24
        Width = 290
      end
      object lblImporte: TcxLabel
        Left = 8
        Top = 61
        AutoSize = False
        Caption = 'Importe:'
        Properties.Alignment.Horz = taRightJustify
        TabOrder = 2
        Height = 24
        Width = 152
        AnchorX = 160
      end
      object edtImporteDivisa: TcxCurrencyEdit
        Left = 170
        Top = 57
        ParentFont = False
        Properties.DecimalPlaces = 11
        Properties.DisplayFormat = ',0.00######### ;-,0.00######### '
        Style.Font.Charset = DEFAULT_CHARSET
        Style.Font.Color = clWindowText
        Style.Font.Height = -17
        Style.Font.Name = 'Source Sans 3'
        Style.Font.Style = []
        Style.IsFontAssigned = True
        TabOrder = 3
        Width = 153
      end
      object txtPendiente: TcxCurrencyEdit
        Left = 360
        Top = 57
        Enabled = False
        ParentFont = False
        Properties.DisplayFormat = ',0.00 '#8364' ;-,0.00 '#8364' '
        Style.Font.Charset = DEFAULT_CHARSET
        Style.Font.Color = clWindowText
        Style.Font.Height = -17
        Style.Font.Name = 'Source Sans 3'
        Style.Font.Style = []
        Style.IsFontAssigned = True
        TabOrder = 4
        Width = 100
      end
      object cxLabel1: TcxLabel
        Left = 375
        Top = 34
        Caption = 'Pendiente'
        Enabled = False
        TabOrder = 5
      end
    end
    object gbReferencia: TcxGroupBox
      Left = 10
      Top = 116
      Caption = ' Referencia '
      ParentFont = False
      Style.Font.Charset = DEFAULT_CHARSET
      Style.Font.Color = clWindowText
      Style.Font.Height = -17
      Style.Font.Name = 'Source Sans 3'
      Style.Font.Style = []
      Style.IsFontAssigned = True
      TabOrder = 1
      Height = 94
      Width = 480
      object lblReferencia: TcxLabel
        Left = 8
        Top = 25
        AutoSize = False
        Caption = 'Referencia:'
        Properties.Alignment.Horz = taRightJustify
        TabOrder = 0
        Height = 24
        Width = 152
        AnchorX = 160
      end
      object lblEjemplo: TcxLabel
        Left = 170
        Top = 52
        Caption = 'Ej: 123456'
        TabOrder = 1
      end
      object edtReferencia: TcxTextEdit
        Left = 170
        Top = 22
        ParentFont = False
        Style.Font.Charset = DEFAULT_CHARSET
        Style.Font.Color = clWindowText
        Style.Font.Height = -17
        Style.Font.Name = 'Source Sans 3'
        Style.Font.Style = []
        Style.IsFontAssigned = True
        TabOrder = 2
        Width = 290
      end
    end
    object gbDivisa: TcxGroupBox
      Left = 10
      Top = 207
      Caption = ' Otra Divisa '
      TabOrder = 2
      Height = 162
      Width = 480
      object lblDivisa: TcxLabel
        Left = 8
        Top = 35
        AutoSize = False
        Caption = 'Divisa:'
        Properties.Alignment.Horz = taRightJustify
        TabOrder = 2
        Height = 24
        Width = 152
        AnchorX = 160
      end
      object lblFactorCambio: TcxLabel
        Left = 8
        Top = 69
        AutoSize = False
        Caption = 'Cotizaci'#243'n:'
        Properties.Alignment.Horz = taRightJustify
        TabOrder = 3
        Height = 24
        Width = 152
        AnchorX = 160
      end
      object lblImporteDivisa: TcxLabel
        Left = 192
        Top = 106
        AutoSize = False
        Caption = 'Importe final:'
        Properties.Alignment.Horz = taRightJustify
        TabOrder = 4
        Height = 24
        Width = 150
        AnchorX = 342
      end
      object lblEquivale: TcxLabel
        Left = 12
        Top = 102
        Caption = '0,00 EUR = 0.00 USD'
        TabOrder = 5
      end
      object edtFactorCambio: TcxCurrencyEdit
        Left = 170
        Top = 66
        Properties.DecimalPlaces = 11
        Properties.DisplayFormat = '0.00#########'
        Properties.ReadOnly = False
        Properties.OnChange = edtFactorCambioPropertiesChange
        TabOrder = 0
        Width = 145
      end
      object edtImporteEuros: TcxCurrencyEdit
        Left = 350
        Top = 103
        Properties.ReadOnly = True
        Properties.OnChange = edtImporteDivisaPropertiesChange
        TabOrder = 1
        Width = 110
      end
      object txtDivisa: TcxTextEdit
        Left = 170
        Top = 31
        Enabled = False
        TabOrder = 6
        Width = 290
      end
      object btnGetDivisa: TcxButton
        Left = 321
        Top = 60
        Width = 40
        Height = 34
        OptionsImage.Glyph.SourceDPI = 96
        OptionsImage.Glyph.Data = {
          89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
          610000001974455874536F6674776172650041646F626520496D616765526561
          647971C9653C00000023744558745469746C6500436F6E766572743B52657065
          61743B4172726F773B45786368616E6765762368D2000000C049444154785EA5
          D3B10983501087F1141619C0259C20A033BC29EC1C20609914AE90116C1C208E
          E00E366EF04AC1E2F205727024175E24C5AFF3FF71A01E4424E9DCDF04011FCF
          EC08F811FB90CA51A3C78C0DE244DC4085019210BC408111E24B5F703183051D
          4A1CED385CEF27B45E603281C6790B3A8E98BCC00A4144A663C528438460FD76
          41C4F3C400790B3410C0BFA0B5E397234A74584CE0E27E483A4E1851E866EF78
          40A59B5F2ED830A3478D3CF92FD88886AD6440237B027F7900F82BA5E5BA0A0F
          4B0000000049454E44AE426082}
        TabOrder = 7
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -17
        Font.Name = 'Source Sans 3'
        Font.Style = []
        ParentFont = False
        OnClick = btnGetDivisaClick
      end
      object lblEquivale2: TcxLabel
        Left = 12
        Top = 119
        Caption = '0,00 EUR = 0.00 USD'
        TabOrder = 8
      end
    end
    object gbBlockchain: TcxGroupBox
      Left = 10
      Top = 368
      Caption = ' Blockchain '
      TabOrder = 3
      Visible = False
      Height = 99
      Width = 480
      object lblRedBlockchain: TcxLabel
        Left = 8
        Top = 25
        AutoSize = False
        Caption = 'Red:'
        Properties.Alignment.Horz = taRightJustify
        TabOrder = 0
        Height = 24
        Width = 152
        AnchorX = 160
      end
      object lblTxHash: TcxLabel
        Left = 8
        Top = 55
        AutoSize = False
        Caption = 'TX Hash:'
        Properties.Alignment.Horz = taRightJustify
        TabOrder = 1
        Height = 24
        Width = 152
        AnchorX = 160
      end
      object cbbRedBlockchain: TcxComboBox
        Left = 170
        Top = 22
        Properties.DropDownListStyle = lsFixedList
        TabOrder = 2
        Width = 200
      end
      object edtTxHash: TcxTextEdit
        Left = 170
        Top = 52
        TabOrder = 3
        Width = 290
      end
    end
  end
  object pnlBotones: TPanel
    Left = 0
    Top = 481
    Width = 500
    Height = 60
    Align = alBottom
    BevelOuter = bvNone
    ParentColor = True
    TabOrder = 1
    ExplicitTop = 452
    ExplicitWidth = 498
    object btnAceptar: TcxButton
      Left = 357
      Top = 9
      Width = 133
      Height = 45
      Caption = 'Aceptar (F12)'
      TabOrder = 0
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -17
      Font.Name = 'Source Sans 3'
      Font.Style = []
      ParentFont = False
      OnClick = btnAceptarClick
    end
    object btnCancelar: TcxButton
      Left = 208
      Top = 9
      Width = 143
      Height = 45
      Caption = 'Cancelar (ESC)'
      TabOrder = 1
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -17
      Font.Name = 'Source Sans 3'
      Font.Style = []
      ParentFont = False
      OnClick = btnCancelarClick
    end
    object txtSobra: TcxCurrencyEdit
      Left = 75
      Top = 4
      Enabled = False
      ParentFont = False
      Properties.DisplayFormat = ',0.00 '#8364' ;-,0.00 '#8364' '
      Style.Font.Charset = DEFAULT_CHARSET
      Style.Font.Color = clWindowText
      Style.Font.Height = -17
      Style.Font.Name = 'Source Sans 3'
      Style.Font.Style = []
      Style.IsFontAssigned = True
      TabOrder = 2
      Width = 100
    end
    object cxLabel2: TcxLabel
      Left = 10
      Top = 7
      Caption = 'Sobra:'
      Enabled = False
      TabOrder = 3
    end
  end
end
