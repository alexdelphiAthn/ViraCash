inherited frmModalDesgloseEfectivo: TfrmModalDesgloseEfectivo
  BorderStyle = bsDialog
  Caption = 'Recuento de efectivo en Caja'
  ClientHeight = 560
  ClientWidth = 740
  Position = poScreenCenter
  StyleElements = [seFont, seClient, seBorder]
  OnShow = FormShow
  TextHeight = 17
  object pnlPrincipal: TPanel [0]
    Left = 0
    Top = 0
    Width = 740
    Height = 500
    Align = alClient
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 0
    object cxgrdDesglose: TcxGrid
      Left = 8
      Top = 8
      Width = 420
      Height = 484
      TabOrder = 0
      object tvDesglose: TcxGridTableView
        OnKeyDown = tvDesgloseKeyDown
        OnEditKeyDown = tvDesgloseEditKeyDown
        OnEditValueChanged = tvDesgloseEditValueChanged
        OptionsBehavior.FocusCellOnTab = True
        OptionsData.Deleting = False
        OptionsData.Inserting = False
        OptionsView.ColumnAutoWidth = True
        OptionsView.GroupByBox = False
        object tvDesgloseTipo: TcxGridColumn
          Caption = 'Tipo'
          Options.Editing = False
          Width = 80
        end
        object tvDesgloseValor: TcxGridColumn
          Caption = 'Denominaci'#243'n'
          PropertiesClassName = 'TcxCurrencyEditProperties'
          Options.Editing = False
          Width = 110
        end
        object tvDesgloseUnidades: TcxGridColumn
          Caption = 'Unidades'
          PropertiesClassName = 'TcxSpinEditProperties'
          Width = 100
        end
        object tvDesgloseImporte: TcxGridColumn
          Caption = 'Importe'
          PropertiesClassName = 'TcxCurrencyEditProperties'
          Options.Editing = False
          Width = 110
        end
      end
      object lvDesglose: TcxGridLevel
        GridView = tvDesglose
      end
    end
    object pnlResumen: TPanel
      Left = 436
      Top = 8
      Width = 296
      Height = 484
      BevelInner = bvLowered
      BevelOuter = bvNone
      ParentBackground = False
      TabOrder = 1
      object lblResumenTit: TcxLabel
        Left = 12
        Top = 10
        Caption = 'Resumen del recuento'
        Style.TextColor = clNavy
        TabOrder = 0
        Transparent = True
      end
      object lblBilletesLbl: TcxLabel
        Left = 13
        Top = 46
        Caption = 'Billetes:'
        TabOrder = 1
        Transparent = True
      end
      object lblBilletes: TcxLabel
        Left = 140
        Top = 46
        AutoSize = False
        Caption = '0,00'
        Properties.Alignment.Horz = taRightJustify
        TabOrder = 2
        Transparent = True
        Height = 19
        Width = 140
      end
      object lblMonedasLbl: TcxLabel
        Left = 13
        Top = 70
        Caption = 'Monedas:'
        TabOrder = 3
        Transparent = True
      end
      object lblMonedas: TcxLabel
        Left = 140
        Top = 70
        AutoSize = False
        Caption = '0,00'
        Properties.Alignment.Horz = taRightJustify
        TabOrder = 4
        Transparent = True
        Height = 19
        Width = 140
      end
      object lblPiezasLbl: TcxLabel
        Left = 13
        Top = 94
        Caption = 'Piezas contadas:'
        TabOrder = 5
        Transparent = True
      end
      object lblPiezas: TcxLabel
        Left = 140
        Top = 94
        AutoSize = False
        Caption = '0'
        Properties.Alignment.Horz = taRightJustify
        TabOrder = 6
        Transparent = True
        Height = 19
        Width = 140
      end
      object lblTotalLbl: TcxLabel
        Left = 13
        Top = 128
        Caption = 'Total contado:'
        Style.TextColor = clNavy
        TabOrder = 7
        Transparent = True
      end
      object lblTotal: TcxLabel
        Left = 140
        Top = 128
        AutoSize = False
        Caption = '0,00'
        Properties.Alignment.Horz = taRightJustify
        Style.TextColor = clNavy
        TabOrder = 8
        Transparent = True
        Height = 19
        Width = 140
      end
      object lblSistemaLbl: TcxLabel
        Left = 13
        Top = 162
        Caption = 'Efectivo sistema:'
        TabOrder = 9
        Transparent = True
      end
      object lblSistema: TcxLabel
        Left = 140
        Top = 162
        AutoSize = False
        Caption = '0,00'
        Properties.Alignment.Horz = taRightJustify
        TabOrder = 10
        Transparent = True
        Height = 19
        Width = 140
      end
      object lblDiferenciaLbl: TcxLabel
        Left = 13
        Top = 186
        Caption = 'Diferencia:'
        TabOrder = 11
        Transparent = True
      end
      object lblDiferencia: TcxLabel
        Left = 140
        Top = 186
        AutoSize = False
        Caption = '0,00'
        Properties.Alignment.Horz = taRightJustify
        TabOrder = 12
        Transparent = True
        Height = 19
        Width = 140
      end
      object btnLimpiar: TcxButton
        Left = 13
        Top = 226
        Width = 267
        Height = 30
        Action = actLimpiar
        TabOrder = 13
      end
      object lblAyuda: TcxLabel
        Left = 13
        Top = 274
        AutoSize = False
        Style.TextColor = clGray
        Properties.WordWrap = True
        TabOrder = 14
        Transparent = True
        Height = 190
        Width = 267
      end
    end
  end
  object pnlBotones: TPanel [1]
    Left = 0
    Top = 500
    Width = 740
    Height = 60
    Align = alBottom
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 1
    object btnAceptar: TcxButton
      Left = 420
      Top = 12
      Width = 150
      Height = 36
      Action = actAceptar
      Default = True
      TabOrder = 0
    end
    object btnCancelar: TcxButton
      Left = 580
      Top = 12
      Width = 150
      Height = 36
      Action = actCancelar
      Cancel = True
      TabOrder = 1
    end
  end
  object alAcciones: TActionList
    Left = 16
    Top = 512
    object actAceptar: TAction
      Caption = 'Aceptar (F12)'
      ShortCut = 123
      OnExecute = actAceptarExecute
    end
    object actCancelar: TAction
      Caption = 'Cancelar (ESC)'
      OnExecute = actCancelarExecute
    end
    object actLimpiar: TAction
      Caption = 'Limpiar unidades contadas'
      OnExecute = actLimpiarExecute
    end
  end
end
