inherited frmModalCambioArticuloColor: TfrmModalCambioArticuloColor
  BorderStyle = bsDialog
  Caption = 'Cambio de c'#243'digo de art'#237'culo o color'
  ClientHeight = 445
  ClientWidth = 650
  Position = poMainFormCenter
  OnCreate = FormCreate
  TextHeight = 19
  object pnlPrincipal: TPanel [0]
    Left = 0
    Top = 0
    Width = 650
    Height = 387
    Align = alClient
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 0
    object lblIntroduccion: TcxLabel
      Left = 20
      Top = 12
      AutoSize = False
      Caption =
        'Cambie el art'#237'culo o el color de forma independiente. El ' +
        'cambio se aplicar'#225' a todos sus documentos relacionados.'
      Style.TextColor = clNavy
      Style.Font.Size = 10
      Style.Font.Style = [fsBold]
      Style.IsFontAssigned = True
      Properties.WordWrap = True
      TabOrder = 0
      Transparent = True
      Height = 46
      Width = 610
    end
    object gbArticulo: TcxGroupBox
      Left = 20
      Top = 64
      Caption = ' Cambio de art'#237'culo '
      TabOrder = 1
      Height = 116
      Width = 610
      object lblArticuloAntiguo: TcxLabel
        Left = 16
        Top = 29
        Caption = 'Art'#237'culo antiguo:'
        TabOrder = 3
        Transparent = True
      end
      object txtArticuloAntiguo: TcxTextEdit
        Left = 16
        Top = 55
        Properties.MaxLength = 20
        TabOrder = 0
        Width = 170
      end
      object lblArticuloNuevo: TcxLabel
        Left = 202
        Top = 29
        Caption = 'Art'#237'culo nuevo:'
        TabOrder = 4
        Transparent = True
      end
      object txtArticuloNuevo: TcxTextEdit
        Left = 202
        Top = 55
        Properties.MaxLength = 20
        TabOrder = 1
        Width = 170
      end
      object btnCambiarArticulo: TcxButton
        Left = 394
        Top = 48
        Width = 198
        Height = 35
        Action = actCambiarArticulo
        TabOrder = 2
      end
    end
    object gbColor: TcxGroupBox
      Left = 20
      Top = 194
      Caption = ' Cambio de color '
      TabOrder = 2
      Height = 116
      Width = 610
      object lblColorAntiguo: TcxLabel
        Left = 16
        Top = 29
        Caption = 'Color antiguo:'
        TabOrder = 3
        Transparent = True
      end
      object txtColorAntiguo: TcxTextEdit
        Left = 16
        Top = 55
        Properties.MaxLength = 100
        TabOrder = 0
        Width = 170
      end
      object lblColorNuevo: TcxLabel
        Left = 202
        Top = 29
        Caption = 'Color nuevo:'
        TabOrder = 4
        Transparent = True
      end
      object txtColorNuevo: TcxTextEdit
        Left = 202
        Top = 55
        Properties.MaxLength = 100
        TabOrder = 1
        Width = 170
      end
      object btnCambiarColor: TcxButton
        Left = 394
        Top = 48
        Width = 198
        Height = 35
        Action = actCambiarColor
        TabOrder = 2
      end
    end
    object lblAdvertencia: TcxLabel
      Left = 20
      Top = 326
      AutoSize = False
      Caption =
        'Seguridad: si existen ventas del art'#237'culo o del color, no se ' +
        'realizar'#225' ning'#250'n cambio.'
      Style.TextColor = clMaroon
      Style.Font.Style = [fsBold]
      Style.IsFontAssigned = True
      Properties.WordWrap = True
      TabOrder = 3
      Transparent = True
      Height = 42
      Width = 610
    end
  end
  object pnlBotones: TPanel [1]
    Left = 0
    Top = 387
    Width = 650
    Height = 58
    Align = alBottom
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 1
    object btnHistorico: TcxButton
      Left = 20
      Top = 10
      Width = 160
      Height = 35
      Action = actHistorico
      TabOrder = 0
    end
    object btnCerrar: TcxButton
      Left = 500
      Top = 10
      Width = 130
      Height = 35
      Action = actCerrar
      Cancel = True
      TabOrder = 1
    end
  end
  object alAcciones: TActionList
    Left = 20
    Top = 397
    object actCambiarArticulo: TAction
      Caption = 'Cambiar art'#237'culo (Ctrl+F9)'
      ShortCut = 16504
      OnExecute = actCambiarArticuloExecute
    end
    object actCambiarColor: TAction
      Caption = 'Cambiar color (F10)'
      ShortCut = 121
      OnExecute = actCambiarColorExecute
    end
    object actHistorico: TAction
      Caption = 'Histórico (F8)'
      ShortCut = 119
      OnExecute = actHistoricoExecute
    end
    object actCerrar: TAction
      Caption = 'Cerrar (ESC)'
      ShortCut = 27
      OnExecute = actCerrarExecute
    end
  end
end
