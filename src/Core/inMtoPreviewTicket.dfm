object FormVisualizador: TFormVisualizador
  Left = 0
  Top = 0
  Caption = 'Ticket  |  F8 Imprimir  |  F7 PDF  |  F6 PNG  |  ESC Salir'
  ClientHeight = 572
  ClientWidth = 530
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = 'Source Sans 3'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  TextHeight = 17
  object Panel1: TPanel
    Left = 0
    Top = 522
    Width = 530
    Height = 50
    Align = alBottom
    TabOrder = 0
    ExplicitTop = 514
    ExplicitWidth = 644
    object btnCerrar: TButton
      Left = 430
      Top = 6
      Width = 100
      Height = 30
      Caption = 'ESC Cerrar'
      TabOrder = 0
      OnClick = btnCerrarClick
    end
    object btnImprimir: TButton
      Left = 0
      Top = 6
      Width = 105
      Height = 30
      Caption = 'F8 Imprimir'
      TabOrder = 1
      OnClick = btnImprimirClick
    end
    object btnPDF: TButton
      Left = 111
      Top = 6
      Width = 72
      Height = 30
      Caption = 'F7 PDF'
      TabOrder = 2
      OnClick = btnPDFClick
    end
    object btnPNG: TButton
      Left = 189
      Top = 6
      Width = 75
      Height = 30
      Caption = 'F6 PNG'
      TabOrder = 3
      OnClick = btnPNGClick
    end
    object btnImprimirTicket: TButton
      Left = 270
      Top = 6
      Width = 154
      Height = 30
      Caption = 'F5 Imprimir Ticket'
      TabOrder = 4
      OnClick = btnImprimirTicketClick
    end
    object btnEnviarCorreo: TButton
      Left = 430
      Top = 6
      Width = 130
      Height = 30
      Caption = 'F4 Enviar email'
      TabOrder = 5
      OnClick = btnEnviarCorreoClick
    end
  end
  object ScrollBox1: TScrollBox
    Left = 0
    Top = 0
    Width = 530
    Height = 522
    Align = alClient
    TabOrder = 1
    ExplicitWidth = 644
    ExplicitHeight = 514
    object Image1: TImage
      Left = 14
      Top = 3
      Width = 384
      Height = 3500
    end
  end
  object SaveDialog1: TSaveDialog
    Left = 344
    Top = 560
  end
end
