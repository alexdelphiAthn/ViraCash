inherited frmModalDevolucionTicket: TfrmModalDevolucionTicket
  BorderStyle = bsDialog
  Caption = 'Devoluci'#243'n por ticket (F4)'
  ClientHeight = 440
  ClientWidth = 560
  Position = poScreenCenter
  StyleElements = [seFont, seClient, seBorder]
  OnShow = FormShow
  TextHeight = 17
  object pnlPrincipal: TPanel [0]
    Left = 0
    Top = 0
    Width = 560
    Height = 390
    Align = alClient
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 0
    object lblTitulo: TcxLabel
      Left = 16
      Top = 8
      Caption = 'Escanee el ticket o localice la operaci'#243'n'
      Style.TextColor = clNavy
      TabOrder = 6
      Transparent = True
    end
    object gbCodigo: TcxGroupBox
      Left = 16
      Top = 36
      Caption = ' C'#243'digo de barras del ticket (29...) '
      TabOrder = 0
      Height = 74
      Width = 528
      object txtCodigoBarras: TcxTextEdit
        Left = 16
        Top = 28
        Properties.MaxLength = 13
        TabOrder = 0
        OnKeyDown = txtCodigoBarrasKeyDown
        Width = 300
      end
    end
    object gbOperacion: TcxGroupBox
      Left = 16
      Top = 120
      Caption = ' Por operaci'#243'n de caja '
      TabOrder = 1
      Height = 106
      Width = 528
      object lblEmpresaLbl: TcxLabel
        Left = 16
        Top = 28
        Caption = 'Empresa:'
        TabOrder = 5
        Transparent = True
      end
      object txtEmpresa: TcxTextEdit
        Left = 16
        Top = 50
        Properties.MaxLength = 10
        TabOrder = 0
        Width = 80
      end
      object lblAlmacenLbl: TcxLabel
        Left = 112
        Top = 28
        Caption = 'Almac'#233'n:'
        TabOrder = 6
        Transparent = True
      end
      object txtAlmacen: TcxTextEdit
        Left = 112
        Top = 50
        Properties.MaxLength = 10
        TabOrder = 1
        Width = 80
      end
      object lblCajaLbl: TcxLabel
        Left = 208
        Top = 28
        Caption = 'Caja:'
        TabOrder = 7
        Transparent = True
      end
      object txtCaja: TcxTextEdit
        Left = 208
        Top = 50
        Properties.MaxLength = 10
        TabOrder = 2
        Width = 60
      end
      object lblOperacionLbl: TcxLabel
        Left = 284
        Top = 28
        Caption = 'N'#186' operaci'#243'n:'
        TabOrder = 8
        Transparent = True
      end
      object txtOperacion: TcxTextEdit
        Left = 284
        Top = 50
        Properties.MaxLength = 20
        TabOrder = 3
        Width = 110
      end
      object btnBuscarOperacion: TcxButton
        Left = 412
        Top = 46
        Width = 100
        Height = 30
        Caption = 'Buscar'
        TabOrder = 4
        OnClick = btnBuscarOperacionClick
      end
    end
    object gbDocumento: TcxGroupBox
      Left = 16
      Top = 236
      Caption = ' Por documento (serie / n'#250'mero) '
      TabOrder = 2
      Height = 106
      Width = 528
      object lblSerieLbl: TcxLabel
        Left = 16
        Top = 28
        Caption = 'Serie:'
        TabOrder = 3
        Transparent = True
      end
      object txtSerie: TcxTextEdit
        Left = 16
        Top = 50
        Properties.MaxLength = 20
        TabOrder = 0
        Width = 150
      end
      object lblNumeroLbl: TcxLabel
        Left = 182
        Top = 28
        Caption = 'N'#250'mero:'
        TabOrder = 4
        Transparent = True
      end
      object txtNumero: TcxTextEdit
        Left = 182
        Top = 50
        Properties.MaxLength = 20
        TabOrder = 1
        Width = 150
      end
      object btnBuscarDocumento: TcxButton
        Left = 412
        Top = 46
        Width = 100
        Height = 30
        Caption = 'Buscar'
        TabOrder = 2
        OnClick = btnBuscarDocumentoClick
      end
    end
    object lblResultado: TcxLabel
      Left = 16
      Top = 354
      AutoSize = False
      Style.TextColor = clGreen
      TabOrder = 5
      Transparent = True
      Height = 24
      Width = 528
    end
  end
  object pnlBotones: TPanel [1]
    Left = 0
    Top = 390
    Width = 560
    Height = 50
    Align = alBottom
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 1
    object btnAceptar: TcxButton
      Left = 230
      Top = 8
      Width = 150
      Height = 35
      Action = actAceptar
      Default = True
      TabOrder = 0
    end
    object btnCancelar: TcxButton
      Left = 394
      Top = 8
      Width = 150
      Height = 35
      Action = actCancelar
      Cancel = True
      TabOrder = 1
    end
  end
  object alAcciones: TActionList
    Left = 16
    Top = 396
    object actAceptar: TAction
      Caption = 'Cargar devoluci'#243'n (F12)'
      ShortCut = 123
      OnExecute = actAceptarExecute
    end
    object actCancelar: TAction
      Caption = 'Cancelar (ESC)'
      OnExecute = actCancelarExecute
    end
  end
end
