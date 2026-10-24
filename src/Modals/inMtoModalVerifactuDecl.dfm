inherited frmModalVerifactuDecl: TfrmModalVerifactuDecl
  Caption = 'Declaraci'#243'n Responsable - Verifactu'
  ClientHeight = 560
  ClientWidth = 720
  Position = poScreenCenter
  TextHeight = 19
  object mDeclaracion: TcxMemo [0]
    Left = 0
    Top = 0
    Align = alClient
    Properties.ReadOnly = True
    Properties.ScrollBars = ssVertical
    TabOrder = 0
    Height = 419
    Width = 720
  end
  object pnlInstalacion: TPanel [1]
    Left = 0
    Top = 419
    Width = 720
    Height = 82
    Align = alBottom
    TabOrder = 1
    object lblInstalacionTitulo: TcxLabel
      Left = 16
      Top = 8
      AutoSize = False
      Caption = 'N'#250'mero de instalaci'#243'n SIF'
      Properties.WordWrap = True
      Height = 22
      Width = 488
      ParentFont = False
      Style.Font.Charset = DEFAULT_CHARSET
      Style.Font.Color = clWindowText
      Style.Font.Height = -13
      Style.Font.Name = 'Segoe UI'
      Style.Font.Style = [fsBold]
      Style.IsFontAssigned = True
    end
    object lblInstalacionNumero: TcxLabel
      Left = 16
      Top = 32
      AutoSize = False
      Caption = 'N'#250'mero: (pendiente)'
      Properties.WordWrap = True
      Height = 22
      Width = 488
    end
    object lblInstalacionEstado: TcxLabel
      Left = 16
      Top = 56
      AutoSize = False
      Caption = ''
      Properties.WordWrap = True
      Style.TextColor = clMaroon
      Height = 22
      Width = 488
    end
    object btnGenerarInstalacion: TcxButton
      Left = 520
      Top = 24
      Width = 184
      Height = 34
      Caption = 'Generar n'#250'mero'
      TabOrder = 3
      OnClick = btnGenerarInstalacionClick
    end
  end
  object pnlButton: TPanel [2]
    Left = 0
    Top = 501
    Width = 720
    Height = 59
    Align = alBottom
    TabOrder = 2
    object btnImprimir: TcxButton
      Left = 176
      Top = 9
      Width = 160
      Height = 40
      Caption = '&Imprimir'
      TabOrder = 0
      OnClick = btnImprimirClick
    end
    object btnAceptar: TcxButton
      Left = 384
      Top = 9
      Width = 177
      Height = 40
      Cancel = True
      Caption = '&Aceptar'
      Default = True
      ModalResult = 1
      TabOrder = 1
    end
  end
end
