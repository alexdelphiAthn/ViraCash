inherited frmMtoCajaFaseCobro: TfrmMtoCajaFaseCobro
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'Fase de cobro'
  ClientHeight = 680
  ClientWidth = 834
  Font.Height = -16
  Position = poScreenCenter
  OnDestroy = FormDestroy
  OnShow = FormShow
  ExplicitWidth = 846
  ExplicitHeight = 718
  TextHeight = 20
  object pnlPrincipal: TPanel [0]
    Left = 65
    Top = 0
    Width = 769
    Height = 680
    Align = alClient
    BevelOuter = bvNone
    Color = clCream
    ParentBackground = False
    TabOrder = 0
    ExplicitWidth = 765
    ExplicitHeight = 679
    object pnlIzquierdo: TPanel
      Left = 0
      Top = 0
      Width = 521
      Height = 680
      Align = alClient
      BevelOuter = bvNone
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -23
      Font.Name = 'Source Sans 3'
      Font.Pitch = fpFixed
      Font.Style = [fsBold]
      Font.Quality = fqClearTypeNatural
      ParentBackground = False
      ParentFont = False
      TabOrder = 0
      ExplicitWidth = 517
      ExplicitHeight = 679
      object pnlContenedor: TPanel
        Left = 0
        Top = 0
        Width = 521
        Height = 680
        Align = alClient
        TabOrder = 0
        ExplicitWidth = 517
        ExplicitHeight = 679
        object pnlTotales: TPanel
          Left = 6
          Top = 0
          Width = 515
          Height = 201
          BevelInner = bvRaised
          BevelKind = bkSoft
          TabOrder = 0
          object lblImporteDtoLineal: TcxLabel
            Left = 8
            Top = 61
            Caption = 'Imp dto. Lineal'
            ParentFont = False
            Style.Font.Charset = DEFAULT_CHARSET
            Style.Font.Color = clNavy
            Style.Font.Height = -23
            Style.Font.Name = 'Source Sans 3'
            Style.Font.Pitch = fpFixed
            Style.Font.Style = [fsBold]
            Style.Font.Quality = fqClearTypeNatural
            Style.IsFontAssigned = True
            TabOrder = 0
          end
          object lblImporteTotalAPagar: TcxLabel
            Left = 8
            Top = 143
            Caption = 'Imp TOTAL a pagar'
            ParentFont = False
            Style.Font.Charset = DEFAULT_CHARSET
            Style.Font.Color = clNavy
            Style.Font.Height = -23
            Style.Font.Name = 'Source Sans 3'
            Style.Font.Pitch = fpFixed
            Style.Font.Style = [fsBold]
            Style.Font.Quality = fqClearTypeNatural
            Style.IsFontAssigned = True
            TabOrder = 1
          end
          object lblDescuento: TcxLabel
            Left = 8
            Top = 104
            Caption = '% Descuento'
            ParentFont = False
            Style.Font.Charset = DEFAULT_CHARSET
            Style.Font.Color = clNavy
            Style.Font.Height = -23
            Style.Font.Name = 'Source Sans 3'
            Style.Font.Pitch = fpFixed
            Style.Font.Style = [fsBold]
            Style.Font.Quality = fqClearTypeNatural
            Style.IsFontAssigned = True
            TabOrder = 2
          end
          object lblSuma: TcxLabel
            Left = 8
            Top = 18
            Caption = 'Suma'
            ParentFont = False
            Style.Font.Charset = ANSI_CHARSET
            Style.Font.Color = clNavy
            Style.Font.Height = -23
            Style.Font.Name = 'Source Sans 3'
            Style.Font.Pitch = fpFixed
            Style.Font.Style = [fsBold]
            Style.Font.Quality = fqClearTypeNatural
            Style.IsFontAssigned = True
            TabOrder = 3
          end
          object txtCantidadLineas: TcxTextEdit
            Left = 275
            Top = 14
            Properties.Alignment.Horz = taCenter
            Properties.ReadOnly = True
            Style.BorderStyle = ebsOffice11
            TabOrder = 4
            Text = '1'
            Width = 64
          end
          object txtBrutoLineas: TcxCurrencyEdit
            Left = 334
            Top = 14
            Properties.Alignment.Horz = taRightJustify
            Properties.DisplayFormat = '#,##0.00 '#8364
            Properties.EditFormat = ',0.00 '#8364
            Properties.ReadOnly = True
            Style.BorderStyle = ebsOffice11
            TabOrder = 5
            Width = 171
          end
          object txtPorcenDtoLineal: TcxTextEdit
            Left = 243
            Top = 57
            Style.BorderStyle = ebsOffice11
            TabOrder = 8
            Width = 96
          end
          object txtTotalPagar: TcxCurrencyEdit
            Left = 334
            Top = 139
            Properties.Alignment.Horz = taRightJustify
            Properties.DisplayFormat = '#,##0.00 '#8364
            Properties.EditFormat = ',0.00 '#8364
            Properties.ReadOnly = True
            Properties.OnChange = txtTotalPagarPropertiesChange
            Properties.OnValidate = txtTotalPagarPropertiesValidate
            Style.BorderStyle = ebsOffice11
            TabOrder = 10
            Width = 171
          end
          object txtDtoGlobal: TcxCurrencyEdit
            Left = 334
            Top = 100
            Properties.Alignment.Horz = taRightJustify
            Properties.DisplayFormat = '#,##0.00 '#8364
            Properties.EditFormat = ',0.00 '#8364
            Properties.ReadOnly = True
            Style.BorderStyle = ebsOffice11
            TabOrder = 7
            Width = 171
          end
          object txtTotalDtoLineal: TcxCurrencyEdit
            Left = 334
            Top = 57
            Properties.Alignment.Horz = taRightJustify
            Properties.DisplayFormat = '#,##0.00 '#8364
            TabOrder = 9
            Width = 171
          end
          object txtPorcenDtoGlobal: TcxCurrencyEdit
            Left = 243
            Top = 100
            Properties.Alignment.Horz = taRightJustify
            Properties.DisplayFormat = ',0.00 %;-,0.00 %;'#39#39
            Properties.EditFormat = ',0.00 %;-,0.00 %;'#39#39
            Properties.MinValue = 0.000000000000000000
            Properties.MaxValue = 100.000000000000000000
            Properties.ReadOnly = False
            Properties.OnChange = txtPorcenDtoGlobalPropertiesChange
            Properties.OnValidate = txtPorcenDtoGlobalPropertiesValidate
            Style.BorderStyle = ebsOffice11
            TabOrder = 6
            Width = 92
          end
        end
        object pnlCuenta: TPanel
          Left = 6
          Top = 196
          Width = 515
          Height = 108
          BevelInner = bvRaised
          BevelKind = bkSoft
          TabOrder = 1
          object lblPendienteCobro: TcxLabel
            Left = 8
            Top = 58
            Caption = 'Pendiente de cobro'
            ParentFont = False
            Style.Font.Charset = DEFAULT_CHARSET
            Style.Font.Color = clNavy
            Style.Font.Height = -23
            Style.Font.Name = 'Source Sans 3'
            Style.Font.Pitch = fpFixed
            Style.Font.Style = [fsBold]
            Style.Font.Quality = fqClearTypeNatural
            Style.IsFontAssigned = True
            TabOrder = 0
          end
          object lblImporteACuenta: TcxLabel
            Left = 8
            Top = 18
            Caption = 'Importe a dejar A CUENTA'
            ParentFont = False
            Style.Font.Charset = ANSI_CHARSET
            Style.Font.Color = clNavy
            Style.Font.Height = -23
            Style.Font.Name = 'Source Sans 3'
            Style.Font.Pitch = fpFixed
            Style.Font.Style = [fsBold]
            Style.Font.Quality = fqClearTypeNatural
            Style.IsFontAssigned = True
            TabOrder = 1
          end
          object txtDejarCuenta: TcxCurrencyEdit
            Left = 334
            Top = 17
            Properties.Alignment.Horz = taRightJustify
            Properties.DisplayFormat = '#,##0.00 '#8364
            Properties.EditFormat = ',0.00 '#8364
            Properties.ReadOnly = True
            Style.BorderStyle = ebsOffice11
            TabOrder = 2
            Width = 171
          end
          object txtPendienteCuenta: TcxCurrencyEdit
            Left = 334
            Top = 54
            Properties.Alignment.Horz = taRightJustify
            Properties.DisplayFormat = '#,##0.00 '#8364
            Properties.EditFormat = ',0.00 '#8364
            Properties.ReadOnly = True
            Style.BorderStyle = ebsOffice11
            TabOrder = 3
            Width = 171
          end
        end
        object pnlCambioVales: TPanel
          Left = 6
          Top = 299
          Width = 515
          Height = 108
          BevelInner = bvRaised
          BevelKind = bkSoft
          TabOrder = 2
          object lblValeEmitido: TcxLabel
            Left = 8
            Top = 58
            Caption = 'Vale Emitido'
            ParentFont = False
            Style.Font.Charset = DEFAULT_CHARSET
            Style.Font.Color = clNavy
            Style.Font.Height = -23
            Style.Font.Name = 'Source Sans 3'
            Style.Font.Pitch = fpFixed
            Style.Font.Style = [fsBold]
            Style.Font.Quality = fqClearTypeNatural
            Style.IsFontAssigned = True
            TabOrder = 0
          end
          object lblValeRecogido: TcxLabel
            Left = 8
            Top = 14
            Caption = 'Vale Recogido'
            ParentFont = False
            Style.Font.Charset = ANSI_CHARSET
            Style.Font.Color = clNavy
            Style.Font.Height = -23
            Style.Font.Name = 'Source Sans 3'
            Style.Font.Pitch = fpFixed
            Style.Font.Style = [fsBold]
            Style.Font.Quality = fqClearTypeNatural
            Style.IsFontAssigned = True
            TabOrder = 1
          end
          object txtValeRecogido: TcxCurrencyEdit
            Left = 334
            Top = 10
            Properties.Alignment.Horz = taRightJustify
            Properties.DisplayFormat = '#,##0.00 '#8364
            Properties.EditFormat = ',0.00 '#8364
            Properties.ReadOnly = True
            Style.BorderStyle = ebsOffice11
            TabOrder = 2
            Width = 171
          end
          object txtValeEmitido: TcxCurrencyEdit
            Left = 334
            Top = 54
            Properties.Alignment.Horz = taRightJustify
            Properties.DisplayFormat = '#,##0.00 '#8364
            Properties.EditFormat = ',0.00 '#8364
            Properties.ReadOnly = True
            Properties.OnEditValueChanged = txtValeEmitidoPropertiesEditValueChanged
            Style.BorderStyle = ebsOffice11
            TabOrder = 3
            Width = 171
          end
        end
        object cxgrdFormasPago: TcxGrid
          Left = 5
          Top = 409
          Width = 514
          Height = 186
          BevelOuter = bvRaised
          BorderStyle = cxcbsNone
          TabOrder = 3
          object dbtvFormasPago: TcxGridDBTableView
            OnEditing = dbtvFormasPagoEditing
            OnEditChanged = dbtvFormasPagoEditChanged
            DataController.DataSource = dsFormasPago
            OptionsData.Deleting = False
            OptionsData.Inserting = False
            OptionsView.GroupByBox = False
            OptionsView.Indicator = True
            Styles.Header = styCobroLine
            object cxgrdbclmnCodigo: TcxGridDBColumn
              Caption = 'C'#243'digo'
              DataBinding.FieldName = 'CODIGO_FP_CFP'
              Visible = False
              HeaderAlignmentHorz = taCenter
              Options.Editing = False
              Options.Focusing = False
              Width = 95
            end
            object dbmDescripcion: TcxGridDBColumn
              Caption = 'Descripci'#243'n'
              DataBinding.FieldName = 'DESCRIPCION_FORMA_PAGO_CFP'
              Options.Editing = False
              Options.Focusing = False
              Styles.Header = styCobroLine
              Width = 254
            end
            object dbmImporte: TcxGridDBColumn
              Caption = 'Importe Entregado'
              DataBinding.FieldName = 'IMPORTE_ENTREGADO'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Properties.EditFormat = ',0.00 '#8364';-,0.00 '#8364';'#39#39
              Properties.OnEditValueChanged = dbmImportePropertiesEditValueChanged
              Properties.OnValidate = dbmImportePropertiesValidate
              OnGetDisplayText = dbmImporteGetDisplayText
              HeaderAlignmentHorz = taRightJustify
              Styles.Header = styCobroLine
              Width = 249
            end
            object dbtvFormasPagoESDIVISA_FORMA_PAGO_CFP: TcxGridDBColumn
              DataBinding.FieldName = 'ESDIVISA_FORMA_PAGO_CFP'
              Visible = False
            end
            object dbtvFormasPagoESCRIPTO_FORMA_PAGO_CFP: TcxGridDBColumn
              DataBinding.FieldName = 'ESCRIPTO_FORMA_PAGO_CFP'
              Visible = False
            end
            object dbtvFormasPagoESIMPORTE_DIVISA: TcxGridDBColumn
              DataBinding.FieldName = 'ESIMPORTE_DIVISA'
              Visible = False
            end
          end
          object cxgrdlvlFormasPago: TcxGridLevel
            GridView = dbtvFormasPago
          end
        end
        object pnlFormasPago: TPanel
          Left = 1
          Top = 599
          Width = 519
          Height = 80
          Align = alBottom
          BevelOuter = bvNone
          ParentBackground = False
          TabOrder = 4
          ExplicitTop = 598
          ExplicitWidth = 515
          object lblPendienteCobroAlt: TcxLabel
            Left = 15
            Top = 43
            Caption = 'Pendiente de cobro'
            ParentColor = False
            ParentFont = False
            Style.Font.Charset = DEFAULT_CHARSET
            Style.Font.Color = clNavy
            Style.Font.Height = -23
            Style.Font.Name = 'Source Sans 3'
            Style.Font.Pitch = fpFixed
            Style.Font.Style = [fsBold]
            Style.Font.Quality = fqClearTypeNatural
            Style.IsFontAssigned = True
            TabOrder = 0
          end
          object txtPendienteCobro: TcxCurrencyEdit
            Left = 341
            Top = 39
            Properties.Alignment.Horz = taRightJustify
            Properties.DisplayFormat = '#,##0.00 '#8364
            Properties.EditFormat = ',0.00 '#8364
            Properties.ReadOnly = True
            Style.BorderStyle = ebsOffice11
            TabOrder = 1
            Width = 171
          end
          object lblDevolucionCambio: TcxLabel
            Left = 15
            Top = 4
            Caption = 'Devoluci'#243'n de cambio'
            ParentColor = False
            ParentFont = False
            Style.Font.Charset = DEFAULT_CHARSET
            Style.Font.Color = clNavy
            Style.Font.Height = -23
            Style.Font.Name = 'Source Sans 3'
            Style.Font.Pitch = fpFixed
            Style.Font.Style = [fsBold]
            Style.Font.Quality = fqClearTypeNatural
            Style.IsFontAssigned = True
            TabOrder = 2
          end
          object txtCambio: TcxCurrencyEdit
            Left = 341
            Top = 0
            Properties.Alignment.Horz = taRightJustify
            Properties.DisplayFormat = '#,##0.00 '#8364
            Properties.EditFormat = ',0.00 '#8364
            Properties.ReadOnly = True
            Style.BorderStyle = ebsOffice11
            TabOrder = 3
            Width = 171
          end
        end
      end
    end
    object pnlDerecho: TPanel
      Left = 521
      Top = 0
      Width = 248
      Height = 680
      Align = alRight
      BevelOuter = bvNone
      Color = clCream
      ParentBackground = False
      TabOrder = 1
      ExplicitLeft = 517
      ExplicitHeight = 679
      object pnlBotones: TPanel
        Left = 0
        Top = 0
        Width = 248
        Height = 484
        Align = alClient
        BevelOuter = bvNone
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -23
        Font.Name = 'Source Sans 3'
        Font.Pitch = fpFixed
        Font.Style = []
        Font.Quality = fqClearTypeNatural
        ParentBackground = False
        ParentFont = False
        TabOrder = 0
        ExplicitHeight = 483
        object btnSinTicket: TcxButton
          Left = 89
          Top = 0
          Width = 155
          Height = 51
          Caption = 'Si&n ticket'
          Colors.Default = clBtnFace
          Colors.Normal = clBtnFace
          Colors.Hot = clSilver
          Enabled = False
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          OptionsImage.Margin = 10
          TabOrder = 0
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -23
          Font.Name = 'Source Sans 3'
          Font.Pitch = fpFixed
          Font.Style = [fsBold]
          Font.Quality = fqClearTypeNatural
          ParentFont = False
          OnClick = btnSinTicketClick
        end
        object btnF11: TcxButton
          Left = 18
          Top = 0
          Width = 74
          Height = 51
          Caption = 'F11'
          Colors.Default = clBtnFace
          Colors.Normal = clBtnFace
          Colors.Hot = clBtnFace
          Enabled = False
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          TabOrder = 1
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clNavy
          Font.Height = -23
          Font.Name = 'Source Sans 3'
          Font.Pitch = fpFixed
          Font.Style = [fsBold, fsUnderline]
          Font.Quality = fqClearTypeNatural
          ParentFont = False
          OnClick = btnSinTicketClick
        end
        object btnConTicket: TcxButton
          Left = 89
          Top = 50
          Width = 155
          Height = 51
          Caption = '&Con ticket'
          Colors.Default = clBtnFace
          Colors.Normal = clBtnFace
          Colors.Hot = clSilver
          Enabled = False
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          OptionsImage.Margin = 10
          TabOrder = 2
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -23
          Font.Name = 'Source Sans 3'
          Font.Pitch = fpFixed
          Font.Style = [fsBold]
          Font.Quality = fqClearTypeNatural
          ParentFont = False
          OnClick = btnConTicketClick
        end
        object btnF12: TcxButton
          Left = 18
          Top = 50
          Width = 74
          Height = 51
          Caption = 'F12'
          Colors.Default = clBtnFace
          Colors.Normal = clBtnFace
          Colors.Hot = clBtnFace
          Enabled = False
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          TabOrder = 3
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clNavy
          Font.Height = -23
          Font.Name = 'Source Sans 3'
          Font.Pitch = fpFixed
          Font.Style = [fsBold, fsUnderline]
          Font.Quality = fqClearTypeNatural
          ParentFont = False
          OnClick = btnConTicketClick
        end
        object btnSinPrecios: TcxButton
          Left = 89
          Top = 100
          Width = 155
          Height = 51
          Caption = 'Sin &precios'
          Colors.Default = clBtnFace
          Colors.Normal = clBtnFace
          Colors.Hot = clSilver
          Enabled = False
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          OptionsImage.Margin = 10
          TabOrder = 4
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -23
          Font.Name = 'Source Sans 3'
          Font.Pitch = fpFixed
          Font.Style = [fsBold]
          Font.Quality = fqClearTypeNatural
          ParentFont = False
          OnClick = btnSinPreciosClick
        end
        object btnF10: TcxButton
          Left = 18
          Top = 100
          Width = 74
          Height = 51
          Caption = 'F10'
          Colors.Default = clBtnFace
          Colors.Normal = clBtnFace
          Colors.Hot = clBtnFace
          Enabled = False
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          TabOrder = 5
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clNavy
          Font.Height = -23
          Font.Name = 'Source Sans 3'
          Font.Pitch = fpFixed
          Font.Style = [fsBold, fsUnderline]
          Font.Quality = fqClearTypeNatural
          ParentFont = False
          OnClick = btnSinPreciosClick
        end
        object btnDeposito: TcxButton
          Left = 89
          Top = 149
          Width = 155
          Height = 51
          Caption = '&Pr'#233'stamo'
          Colors.Default = clBtnFace
          Colors.Normal = clBtnFace
          Colors.Hot = clSilver
          Enabled = False
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          OptionsImage.Margin = 10
          TabOrder = 6
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -23
          Font.Name = 'Source Sans 3'
          Font.Pitch = fpFixed
          Font.Style = [fsBold]
          Font.Quality = fqClearTypeNatural
          ParentFont = False
          OnClick = btnDepositoClick
        end
        object btnF7: TcxButton
          Left = 18
          Top = 149
          Width = 74
          Height = 51
          Caption = 'F7'
          Colors.Default = clBtnFace
          Colors.Normal = clBtnFace
          Colors.Hot = clBtnFace
          Enabled = False
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          TabOrder = 7
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clNavy
          Font.Height = -23
          Font.Name = 'Source Sans 3'
          Font.Pitch = fpFixed
          Font.Style = [fsBold, fsUnderline]
          Font.Quality = fqClearTypeNatural
          ParentFont = False
          OnClick = btnF7Click
        end
        object btnF8: TcxButton
          Left = 18
          Top = 198
          Width = 74
          Height = 51
          Caption = 'F8'
          Colors.Default = clBtnFace
          Colors.Normal = clBtnFace
          Colors.Hot = clBtnFace
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          TabOrder = 8
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clNavy
          Font.Height = -23
          Font.Name = 'Source Sans 3'
          Font.Pitch = fpFixed
          Font.Style = [fsBold, fsUnderline]
          Font.Quality = fqClearTypeNatural
          ParentFont = False
          OnClick = btnFacturaClick
        end
        object btnFactura: TcxButton
          Left = 89
          Top = 198
          Width = 155
          Height = 51
          Caption = '&Borrador'
          Colors.Default = clBtnFace
          Colors.Normal = clBtnFace
          Colors.Hot = clSilver
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          OptionsImage.Margin = 10
          TabOrder = 9
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -23
          Font.Name = 'Source Sans 3'
          Font.Pitch = fpFixed
          Font.Style = [fsBold]
          Font.Quality = fqClearTypeNatural
          ParentFont = False
          OnClick = btnFacturaClick
        end
        object btnF6: TcxButton
          Left = 18
          Top = 248
          Width = 74
          Height = 51
          Caption = 'F6'
          Colors.Default = clBtnFace
          Colors.Normal = clBtnFace
          Colors.Hot = clBtnFace
          Enabled = False
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          TabOrder = 10
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clNavy
          Font.Height = -23
          Font.Name = 'Source Sans 3'
          Font.Pitch = fpFixed
          Font.Style = [fsBold, fsUnderline]
          Font.Quality = fqClearTypeNatural
          ParentFont = False
          OnClick = btnF6Click
        end
        object btnBuscarVale: TcxButton
          Left = 89
          Top = 248
          Width = 155
          Height = 51
          Caption = '&Buscar Vale'
          Colors.Default = clBtnFace
          Colors.Normal = clBtnFace
          Colors.Hot = clSilver
          Enabled = False
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          OptionsImage.Margin = 10
          TabOrder = 11
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -23
          Font.Name = 'Source Sans 3'
          Font.Pitch = fpFixed
          Font.Style = [fsBold]
          Font.Quality = fqClearTypeNatural
          ParentFont = False
          OnClick = btnBuscarValeClick
        end
        object btnMasDatos: TcxButton
          Left = 89
          Top = 298
          Width = 155
          Height = 51
          Caption = '&M'#225's datos'
          Colors.Default = clBtnFace
          Colors.Normal = clBtnFace
          Colors.Hot = clSilver
          Enabled = False
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          OptionsImage.Margin = 10
          TabOrder = 12
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -23
          Font.Name = 'Source Sans 3'
          Font.Pitch = fpFixed
          Font.Style = [fsBold]
          Font.Quality = fqClearTypeNatural
          ParentFont = False
        end
        object btnF2: TcxButton
          Left = 18
          Top = 298
          Width = 74
          Height = 51
          Caption = 'F2'
          Colors.Default = clBtnFace
          Colors.Normal = clBtnFace
          Colors.Hot = clBtnFace
          Enabled = False
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          TabOrder = 13
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clNavy
          Font.Height = -23
          Font.Name = 'Source Sans 3'
          Font.Pitch = fpFixed
          Font.Style = [fsBold, fsUnderline]
          Font.Quality = fqClearTypeNatural
          ParentFont = False
        end
        object btnBuscarT: TcxButton
          Left = 89
          Top = 348
          Width = 155
          Height = 51
          Caption = 'Rellenar'
          Colors.Default = clBtnFace
          Colors.Normal = clBtnFace
          Colors.Hot = clSilver
          Enabled = False
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          OptionsImage.Margin = 10
          TabOrder = 14
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -23
          Font.Name = 'Source Sans 3'
          Font.Pitch = fpFixed
          Font.Style = [fsBold]
          Font.Quality = fqClearTypeNatural
          ParentFont = False
          OnClick = btnBuscarTClick
        end
        object btnF3: TcxButton
          Left = 18
          Top = 348
          Width = 74
          Height = 51
          Caption = 'F3'
          Colors.Default = clBtnFace
          Colors.Normal = clBtnFace
          Colors.Hot = clBtnFace
          Enabled = False
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          TabOrder = 15
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clNavy
          Font.Height = -23
          Font.Name = 'Source Sans 3'
          Font.Pitch = fpFixed
          Font.Style = [fsBold, fsUnderline]
          Font.Quality = fqClearTypeNatural
          ParentFont = False
          OnClick = btnF3Click
        end
        object btnAtras: TcxButton
          Left = 89
          Top = 398
          Width = 155
          Height = 51
          Caption = 'Atr'#225's'
          Colors.Default = clBtnFace
          Colors.Normal = clBtnFace
          Colors.Hot = clSilver
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          OptionsImage.Margin = 10
          TabOrder = 16
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -23
          Font.Name = 'Source Sans 3'
          Font.Pitch = fpFixed
          Font.Style = [fsBold]
          Font.Quality = fqClearTypeNatural
          ParentFont = False
          OnClick = btnAtrasClick
        end
        object btnESC: TcxButton
          Left = 18
          Top = 398
          Width = 74
          Height = 51
          Caption = 'ESC'
          Colors.Default = clBtnFace
          Colors.Normal = clBtnFace
          Colors.Hot = clBtnFace
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          TabOrder = 17
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clNavy
          Font.Height = -23
          Font.Name = 'Source Sans 3'
          Font.Pitch = fpFixed
          Font.Style = [fsBold, fsUnderline]
          Font.Quality = fqClearTypeNatural
          ParentFont = False
          OnClick = btnESCClick
        end
      end
      object pnlDocumento: TPanel
        Left = 0
        Top = 484
        Width = 248
        Height = 196
        Align = alBottom
        BevelOuter = bvNone
        ParentBackground = False
        TabOrder = 1
        ExplicitTop = 483
        object imgEnviarEmail: TImage
          Left = 31
          Top = 153
          Width = 24
          Height = 18
          Center = True
          Transparent = True
        end
        object lblNumDoc: TcxLabel
          Left = 30
          Top = 6
          Caption = 'N'#186' doc. venta'
          ParentFont = False
          Style.Font.Charset = ANSI_CHARSET
          Style.Font.Color = clNavy
          Style.Font.Height = -27
          Style.Font.Name = 'Source Sans 3'
          Style.Font.Pitch = fpFixed
          Style.Font.Style = []
          Style.Font.Quality = fqClearTypeNatural
          Style.IsFontAssigned = True
          TabOrder = 0
        end
        object edtNumeroDoc: TcxTextEdit
          Left = 32
          Top = 94
          ParentFont = False
          Properties.Alignment.Horz = taCenter
          Properties.CharCase = ecUpperCase
          Properties.MaxLength = 8
          Properties.ReadOnly = False
          Style.BorderStyle = ebsOffice11
          Style.Font.Charset = ANSI_CHARSET
          Style.Font.Color = clWindowText
          Style.Font.Height = -23
          Style.Font.Name = 'Source Sans 3'
          Style.Font.Pitch = fpFixed
          Style.Font.Style = []
          Style.Font.Quality = fqClearTypeNatural
          Style.IsFontAssigned = True
          TabOrder = 1
          Text = '00000000'
          Width = 209
        end
        object cbbSERIE_FAC: TcxComboBox
          Left = 32
          Top = 47
          ParentFont = False
          Properties.DropDownListStyle = lsEditList
          Properties.MaxLength = 12
          Style.Font.Charset = ANSI_CHARSET
          Style.Font.Color = clWindowText
          Style.Font.Height = -23
          Style.Font.Name = 'Source Sans 3'
          Style.Font.Pitch = fpFixed
          Style.Font.Style = []
          Style.Font.Quality = fqClearTypeNatural
          Style.IsFontAssigned = True
          TabOrder = 2
          Text = ''
          Width = 209
        end
        object chkEnviarEmail: TcxCheckBox
          Left = 61
          Top = 145
          Caption = 'Enviar por e-mail'
          ParentFont = False
          Properties.OnEditValueChanged = chkEnviarEmailPropertiesEditValueChanged
          Style.Font.Charset = ANSI_CHARSET
          Style.Font.Color = clNavy
          Style.Font.Height = -17
          Style.Font.Name = 'Source Sans 3'
          Style.Font.Pitch = fpFixed
          Style.Font.Style = []
          Style.Font.Quality = fqClearTypeNatural
          Style.IsFontAssigned = True
          TabOrder = 3
          Transparent = True
        end
      end
    end
  end
  object pnlLogoLeft: TPanel [1]
    Left = 0
    Top = 0
    Width = 65
    Height = 680
    Align = alLeft
    TabOrder = 1
    ExplicitHeight = 679
    object cxImage1: TcxImage
      Left = 0
      Top = 0
      Picture.Data = {
        0D546478536D617274496D61676589504E470D0A1A0A0000000D494844520000
        010400000AA008060000004E824D08000000097048597300000B1300000B1301
        009A9C180000200049444154789CECDD09941C55D5C0F10AD0CD1248F7245335
        01515151349074C708C2F474375B342C33016132559340043420288B0B880A0D
        533509FB220206594540164176814F500401411401010101D965DF094BFA3BAF
        0363181232D3F55EDDAA9AFFEF9C7B8EE7F37CCEABFBDEBBA9AE7AF59E650100
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000004013B2DB7CF90B99AE8DDC6C577B2DDB59
        3A27DBD97E73A6ABFDC14C57E9A96C67FB2BD9AE529D20071F1A039DEDAFA831
        A2C68A1A338DB1D3D55E6B8CA5AD37FA3C933129BA371C9BE92AED9CED2CFD2A
        D3D9FE04939DC96E620C643A4B8F67BB4A6766BA36DA498D39E9618FC5754FC8
        66B7EED826D3D97E61B6B3B48022401188760CB4BF99E96AFF4DB6B37DBA3567
        4A86C92965DAB415339D1D73329DEDFFA1085004E23006325DED4F663B3BF6B3
        B69EB20A85212A73A664B29DA5EF653A4B4F4B0F00821C649758184A4F65BBDA
        F7E18EC1B015A6B797B35DA53B99884CC4248C814C67FB7D2B76756C6E7A5E8C
        3CDDD555B39DA553B35DA585D29D4C9083ECF072B030DBD97E8A3575EA68E969
        949A5787DC153009935E88339DA57B339D1D93A4E753A265BA4A3B663B4BAF4B
        7726410EB27A72F05AA6B37D96F4BC4AA46C57692F7E22301153588C17663A4B
        0749CFAF241995E96A3F3A061D479083BAA91C643A4B47A9B12E3DD9622FD359
        3A928148311A096320D3D9FE33E9F9166BD9CED2FED29D4490836C9439E86CDF
        577ADEC5F70122AF15294823AF202DCC6CDDB183F4FC8B95CC561BADA79EC0C6
        A0730872508F3E07ED6F64B62A15A4E7613C4C9D3A3AD359FA2703916234D257
        355A5DEDAB5923DD7B2B10C53B84200759F11CB49F6C8D64EF7D9BC07264F181
        48C424070B579C5EDAD81A91AAD515B25DED77C4A013087210A331D07ED788FC
        4A527DC22C9F7C821CC4700C7496F6B646946A7525B6388BC1C02362BB9F82D5
        BDE1CAD64891EDDA684FE9A413E420CE6360C5AED21ED688D03D21CBB667F203
        8E88770E325DED8F8C886709D9AED2B6D2C926C84132C6407B9795768DDD91C5
        134D9083F88F814C67E97C2BD5BA371CABB6AD964E34410E1231063A4B0BAC6D
        D61F67A555E31015E92413E420416320D3599A6DA555B6B3FD2CE90413E42051
        63A0B3FD0C2BAD325DA5C7C4134C9083841D1B67A5913A24533AB9043948E418
        D8A6E37356DA643A3B3CF1C412E420816320D3599A61A58DDA69563AB1043948
        E418E82C1D60A54DB6B3748E7862097290C431D059FA959536D9CED2ADE28925
        C84112C74067E9162B6D329DA507C4134B9083A46EAF96368B8EC8964F2E410E
        923606329DED4F5869C3AECAF2038B486A0EDA5FB5D286BD13A5071591E01C2C
        B4D226064925C84162C7809536D20925C84192C7809536D20925C84192C78095
        36D20925C84192C7809536D20925466E0EC67A1DF5797FFE6AFD909BF4C70EA7
        6D4641A020C80F7262E839D8E6B84DEA57BEB29591D874EEC614040A02133249
        05E9B83BA6192906E73DB5657DD5EDA3B9062B6DA40705313273F0D93D2AC6EE
        0EBE73E1D4C8AEC34A1BE981418CCC1C7CEBBCCD8D1584097B5528081404F941
        4E0C2D072B6F5BAA9FF3E896468AC1CFFF392DD27EB0D226EA41FCF93933EAD3
        0ED82BD2D860EF9D123F59C7F54C8D3C6F93BFB383916BA9F46D6CECEE60FB13
        37A52024A9204CEFFB413D6ACFBCF4627D956DA3BB8D3411BB1F7F68E479DB6B
        FE5146AEA5EFFAAF18290697BDB855DDD9B1838290A482A026E6D32F3C17F9E0
        9EFAE3EF884FEA3071D55F6F8E345FEFBCFB6E7DCD1D3BB55F87B343B97EE98B
        66EE0E0EBAEE2B91F78B95361283FBF84BCFAF47EDC4CB7F233EA99B0DDBFD6A
        7DC1DB6F459AAFAB6FBFD9C8B5F4CCDFD4D8CF858E83A2597B4041D09CC4D2F7
        BE598FDA53CF3F575F697A597C723713B38F3C38F27CED724C60E45A4EBA770B
        23C5E0D78F6F595F65DBE8FBC64A1BA9417EDF638F443EC8ABFBEE263EB99B89
        0B6FBC2ED23CBDB16041E3AE44F775ACB78FB9B507BBFE7A7391BEB1D2466A90
        1F7CD6C9F5A81DF3DB73C427F77023B7FDA6F557DF7823D23CA90264E25AF6BA
        78AAB182F0B96FCB3C34B6D2466AA07FF61BDBD7172E5C18E9407FF8E927EA2B
        4E8FF62974D8D87EEE0FEB51EB39E4C7DAAF63D5ED3BEA173C6D66EDC1717744
        BBF680826028997FBEE71F910FF60DF7D9597C920F27CEBCF6CA48F3F3D26BAF
        36EE4A745FC7D443CD7DC8B4CD719B5010927E87A0E23B271E518FDAA1E7FF52
        7C920F35466F5BAD3FF7CA4B91E6E797BFBFC2C8B51C7A9399B50797BEB065BD
        B557EE61B1953692037E7CEF16F537DF8AF675DAFD8F3F2A3ED1871A5B1CB877
        3D6A5BD5BEABFD3A3EB64BB97EC5CB667E2EFCF89AE83E64A2204490D04B6EBE
        3EF2416F6A49AEEEF8F91517469A97FFBEF88291159D3B9EBE99B19F0B5FFE49
        F46B0F160F2B6DA407BD77E84FEA51F3CF39457CB22F2BD49A89279F7F36F18B
        B7569C5EAA9FF6A099B507673DB2457DA56D64FBC94A1BE9813F66FB4DEA2FBC
        FA4AA403FFAE871F149FF0CB8A8DF7DBAD1E35F537755FC794FDABC6EE0E76FE
        5534DBA45110224EEA29575F12F9E09FB87BAFF860FAA838FAA27322CDC77FFE
        FB949157B2FB5D696EEDC1A77793FF60CD4A1BE984AAD8FC47DFAE47ED27BFFC
        B9F8757F543CF8E46391E6E3B00BCED47E0DF99E8EFA6F9F35F330F1C8DBF4AF
        A4A420C4A420A87F99D4A2A128FDF5817BC5AF7B69B1FE5E5FAF476DCA9E3B6A
        BF8ECE63CCAD3DD8F248B9B5078B879536D2097D3FD4BF50515B674EB7F8752F
        29825F9F1A691EEE7DF46123D771CCDFCC6CA27AD1B35BD57333E2B1E2D44A1B
        E984BE1F93769F598FDA0F4E394EFCBA9714773EFC40A479A8FDEA24EDD7F0A9
        5DCBC6EE0E7E70B9ECDA030A4244C9FDDB83F7453A11D4D269E9013538BEB06B
        4F3D6A1376EBD17E1D737E6D6E13D52FEE5715EFA7F7C34A1BE9842E1EFB9E7A
        5CA413417D5CF5A99DB615BFEEC563FFD34F883407B7DC77B7914D54CF36B489
        EA190F6D11AB0FD4ACB4914EE8E2F189D95D8DADBBA2B4E7CF8F14BFEEC5E3E6
        7BEF8AF4FABFFB8B63B45F43A9666E13D51D223AA28D821093B8E6F65B229D10
        7FF8C75FC5AFF9FD586BA76D22FD24FCDD85EF36FEA6EEEBA85D67E643A62B5E
        DEAAFEF16FC46BD72B2B6DA4133A38763EDAAF4749DD917C6C87ADC5AF5B85DA
        E5384AD7FEFD56EDD7A0BE3CBCE47933770787DE14FD26AA1404E104B7CCD8AC
        FECA1BAF473A31763BEE10F181A5E2BA3B6E8BF4BA773D6E9EF66B50E72298FA
        B930F5D078AC3D583CACB4914EE892E29C3F5E1DE9C4505B9C4B5FF3EA33B7AC
        BFFDCE3B915DB3DAC5597D7EAEFB3A4EB8CBCCDA83DFFC77CBFA6ADDF1799848
        418830C99D077FAF1EA5B7DE79BBDED62BB70D978A6F1E3B37D26B569F9DEBBE
        86097B9BDB4475EF8BE3B3F68082107192D537F96ADBF428ED74749FE8C0BAEC
        2F37447ABD330F3B50FB35A853974D158489DF95FF9089822098E8E32E392FF1
        FF620E35C6CED8BCFEFA823723BB56B58BB37A56A3F31A56DDBE543FFF29336B
        0F4EB95FAD3D909FFC1404C144B77FEF1BF528A9ADDC5A5D99A7D8BD871D10E9
        B59EFD87ABB45FC366F3CC7DC8E49E14AFB5078B879536D209FDA8B8FB917F27
        FE367A2871EEF5D7447A9DEAC05DDDD730EF467307B88E9F1DAFB5071404A164
        AB8F6EA274C10DD7467E8DAB6DB77163EBF3A8A85D9C57FD9ADE7D0857FF7AB9
        7EF94B66EE0EFC3FC56FED01054128D96B7F63BB4857EEBDF6E61BF57C77B4B7
        A7EA5FEB28CDBFF222EDD730EB54736B0F360E643751A520C42C6EB8FB8E4827
        8C3A2929CAEB3BF5EA4B23BDBECDF6DF436BFBD5C3BE531F30B3F6E0DC27B7A8
        8FDE4E7E0C7E545869239DD065C51EC71F16E98439EBBADF45766D2B6F536E6C
        7D1E95279E7B46FB09D8EA53645377077B5C2073806B968210DF500B86A23CCC
        E5C5D75ED1FE1B3B2E7B491E75E1D9DAAF416D5662AA207C7ECF78AE3DC82E16
        56DA48277428F1DB9BFE18E9C4512B25A3B8AE9F5D1AED5A8B2FEFB393D6F6AB
        6DCCD47666A60A825AD7A03BBE7BA9DE158F56DA484FF6A1843A8D384AEA77BD
        E96B529B7CA8ADCFA3F2C013FA8FB0DBEA28736B0F4CC425CF6F55FFE437F5DE
        755869233DD98712EA16FED9975F8C6CF2A8BF65E24833C985577D67EB3FADEA
        A8BF9A799898A4835DACB4919EEC438D5FFCEEE24827D0577EB2A7D1EB51A750
        47496D62ABB3FD6BCD5107B8CA4FF22B8718E73CB645E39C080A424A0A827A5D
        16A5132FBFD0E8F5A8ADCF937C06C52E67993BC0D5446C718499BD14ACB4919E
        E8C3F9CDFDD053D11DE6A2BEB6D4FD8AEEFD28EC11ED96F36AF35ADD7D71E6C3
        660E703511C7DF39CDD8C6AC56DA484FF4E1C421E79D91F8C34FA35E92ADF64D
        D4BDB3F486079A5B7B602226EF6B6EDB762B6DA427799C0F7339F6E25F1BB98E
        DB1F88EEFC893FDEF937EDEDFFC9FF99F990C944FCF81AB31BAB5869233DC987
        1BEAF770541E7BF669EDB79A517F9FA1567AEA6CFF38AFC3D826AABAE3E2E7B6
        AAAFB9B3D92F25ADB4919EE0C38DEF9FFCD37A94D4EBC1A4B65F6D0DB7C6AC2D
        B5B67FDBE3CD7DC8A43B763AD3FCD2672B6DA427F870436D991EE566A4875FF0
        2BADEDFFD3DD7F8FACED57DC7AA3F6FCAB0774D213FDCA21BE668CE240582B6D
        A427783371F5ED372772859F2A66519E4C35FBC883B5E6FDB37B98DB4455777C
        F5F068B66CB7D2467A7237135F3FAAAF1EA5297BEEA8A5DDBB1F7F68A47B3BA8
        BD1A75E65D7D7D283DD1AF1C42FCEC1FE65E3352106218511FE612FCFA542DED
        56E73F44456DCBA633E7AB7CADA37EEE13663651D51957BCBC55BDF883E84E87
        B6D2467A72371B6ADF82A8A8BD1DC3B6D776BFDA381C252A5F0BF6D39AEF8D83
        647CC8B4FF55D16EB966A58DF4C46E36B6AA7DB71EA589BBF7866AAFFA3D1F95
        175E7DA5B157A3CE7CFFF0AAAF68FD0C599DC4A4BB185CFCDC96F58F197ECD48
        418869A8DD86A23CCCE58033E7876AEF85375E17595B4FB9FA12F1FE5956946A
        FA573BCE3E23FAEDDAADB4911E186142AD248C8A5A5DD86C3B73DB6FDA381C25
        2D5F6AEA885DCFD1FB80F2AC47B6A88FE98EFE3AACB4911E186162C37D76AE47
        699D39DD4DB5536DDC1A95279F7FB671F724DD37CB8AE3EE98968A93A1ADB491
        1E1861E3AE871F8CFD5783675E7B65646DFCE9C5E78AF7C9B2A2A5A743EB390E
        C7FE5DBD6694B9162B6DA40747D850BFEDA372D33D770EBB7DA3B7AD360E4789
        4AE97BDF14EF93289F1F5C11F16BC6C161A58DF4E0081B9FD9E56B8D4F7CA3A0
        3E4AFAF4CEC3FB94788B03F7AE47E5C1271F8B6C414E5C9E1FEC77A5EC31F156
        DA480F0E1D71FD5D7F8B6CD2ED35FFA861B5EDE7575C1859DBE69E7BBA785F44
        F9FCE06281D78C83C34A1BE9C191B425C17FBCF3F621B74BEDB8A41EF245A5F8
        ED59E27D11E5F3831D4E933F15DA4A1BE984EA08B50AF0F5056F4632E9D4CF93
        8FCFEE1C52BBD48E4B51B9E3DFF78BF74394CF0F7E25F49A71705869239D505D
        11E5C21F75473294361D7DD13991B5E947679C20DE07513E3FD8FC90781C026B
        A58D74427545F7DCFD239B7CD7DC7ECB90DAA41EF245F5B0F3B3DFD85EBC0FA2
        7A7E70F4ED5F157BCD3838ACB4914E68120F73513B118DEFDDE223DBB3FE5E5F
        AF47E5C67FFE433CFF513D3FB8E2E5ADEAEBED2DF79A71705869239D509D71D2
        EF7E1BD924DCE598E023DBA23E998ECA9E3F3F523CF7513D3FF8C1E5B2AF1907
        879536D209D5199BFCF05B914DC2CBFE72C347B6E5CE871F88A41D6A3BB93577
        1CDA43CEA43F3FF8EDB35BD6D7D8295ECBB2ADB4914EA8CE508B72FEFDE4E391
        4C4475447DABBBE46FEFBFB06B4F3D2A6AD315E9BC47F5FC60E629F2AF190787
        9536D209D51D6A714E54661D5E5B621BF63FFD84C8DAB0F3D1BE78CEA3787E70
        E6C35BD457EB8EDF2A4C2B6DA413AA3B26EC16DDBFCEBFB9F1DA25B6E1E67BEF
        8AE4EFBFB16041630D8674CEA3787EB0E9DC78BC661C1C56DA4827D444DCFAAF
        7F46B691A9DADF71F1BFBDD64EDB447610CBD20A52DA9E1F1C1DA3D78C83C34A
        1BE9849A88EFFEE2987A54D4FA87C5FFB6FAD6212A33E6FD483CD7A69F1F5CF1
        F296F575F789CF6BC6C161A58D7442937E98CBD97FB8EA037FFBBA3B6E8BE4EF
        BEF4DAAB8D9D98A4736DFAF9C1F72E377FFA5298B0D2463AA1A6E277B7DD14C9
        C47CF9F5D7EA63B65FB45BCFEA33B78CAC109DF17F978BE7D8F4F3830B9FDDB2
        DEB663FC1E242E1E56DA4827D454EC78C441F5A8741DFCFDC6DFFCE6B17323FB
        9B5BD6F611CFB1E9E707BD27C7EF356376505869239D505391EFDEACF1AF7714
        4EBBE6B2C6DF548B95A2F0DF175FA8AFB26D453CC7269F1F9CFEEF2DEAAB6E2F
        DFF6EC32C24A1BE9849A8CA8F63254DF50385E749F609F70D905E2B935FDFC40
        1D0C23DDF6EC10C24A1BE9849A0C755B1D9593AFBA38B2BF55DD7737F1DC9A7C
        7E70D45FE5364DCD0E33ACB4914EA8C950DB913FF1DC33914CD2A8D61E3CF2F4
        9389D837B1D9E707EA35E384BD93F373C84A1BE9849A8E28372989C261179C29
        9E5393CF0FF6B9345E5F3366971156DA4827D4746CB0F74EF534D175347D1C9F
        1F5CF84CFC5F336607859536D2094DDB612E26DDF3E843E2B934F9FCC03D29FE
        AF19B383C24A1BE98446113F3EE3C47A1A1C78E649E2B934F5FCE0F407B7A88F
        DE4EBECDD961869536D2098D22D4E12A511DE66292DA67413A97A69E1F54FAE2
        F93563761961A58D7442A30A759E4292A94FAAA57368EAF9C161B724E313EEEC
        12C24A1BE9844615BB1D77483DC9F639E918F11C9A787ED078CDB857725E3366
        07859536D2098D2AD4766751AD24D44DFDDCF9E4D7A78BE7D0C4F383BD2F4ED6
        6BC6ECA0B0D2463AA151C605375C5B4FA2DFFFFD56F1DC99787EA05E333A097B
        CD981D1456DA482734CAD8AEFF87F5249AF3D3B9E2B933F1FC60C649C9D8CF21
        FB1161A58D7442A38CD1DB56EBCFBC14CD612EBA2C78FBAD651E0A93C4E707A7
        25F4356376505869239DD0A823CAE3D975B8F8A6EBC57366E2F941C741C97CCD
        981D1456DA482734EA505F0A2649EF610788E74CF7F383C36E4EEE6BC6ECA0B0
        D2463AA11271FFE38FD693E0D5373EBCAB73D29F1FA8FFEE73DF4EEE6BC6ECA0
        B0D2463AA11211E5B98B619C75DDEFC473A5FBF9C19E17C57BD3D4EC30C34A1B
        E9844A845A021CD5FE053AF66A4CCBF3830B9EDEB26ECF4AF66BC6ECA0B0D246
        3AA152F1977FDD5D8FB3E75E79A971C4BD749E743E3FD8FEC4E4BF66CC0E0A2B
        6DA4132A157B9F74743DCEE65F7991788E743E3F48CB6BC6ECA0B0D2463AA152
        F1B11DB6AABFF5CEDBF5B8DA6CFF3DC473A4F3F981FAEFA4DB97351056DA4827
        5432AEB8F5C67A1C3DFACCD3F595A697C5F3A3EBF9C1A1377D45BC6D594361A5
        8D744225431DE71E47475E7896786E743D3F503F213EBB477A5E336607859536
        D209950C7504DB8BAFBD528F1BB50FA4746E743D3FF8CE85C9FE9A31BB8CB0D2
        463AA1D2A1CE488C937B1F7D583C27BA9E1F9CFFD496F5D699E97ACD981D1456
        DA4827543AA61DB0573D4E0E3EEB64F19CE87A7EB0DD09E97BCD981D1456DA48
        27543AD4C3BBC79E7DBA1E17EBEEE68AE744C7F3835FDC37ADBECAB6F2EDCA1A
        0E2B6DA4131A87500FF1E2E0B6FBEF11CF85AEE7071B1E98CED78CD94161A58D
        7442E3105FDA6B763D0E7E70CA71E2B9D0F1FCE0909BD2F33563761961A58D74
        42E312773EFC80F8BE899FDA695BF13C847D7E70D98BE97ECD981D1456DA4827
        342EB1FFE927881604B54DBC740E743C3FD8E382747DCD985D465869239DD0B8
        84DAD5F89D77E50E73D9FDF843C57310F6F941E335636FF256586643849536D2
        098D535C77C76D22C5407D53B1FACC2DC5AF3FECF3836D7F96FED78CD94161A5
        8D7442E3146A77630997FFE546F16B0FFBFC60A4BC66CC0E0A2B6DA4131AA790
        3ACC65C7230E12BFF6B0CF0F363C6064BC66CC0E0A2B6DA4131AB7287DEF9B8D
        D58B51466EFB4D13FDFCC0FF537ABF66CC2E23ACB4914E2891DC1CA8E707EA35
        E3DABB8F9CD78CD94161A58D74428952A29F1F7CEBBC91F59A313B28ACB4914E
        2891DC1CCCBBF12B23EE356376505869239D50A294D8E7079DC76C22DE8EAC70
        5869239D502299395873E7727DE511F89A313B28ACB4914E28410E923C06ACB4
        914E28410E923C06ACB4914E28410E923C06ACB4914E28410E923C06ACB4914E
        28410E923C06ACB4C97695164A27952007091D030BADB4C976955E8B41620972
        90BC31D0D9FE8A953699AED253E28925C84102C740A6B3FD092B6D329DA507A4
        134B9083248E814C67FB7D56DA64BB4A7F914E2C410E1239063ADB6FB6D226DB
        593A473CB1043948E218E82CFDCA4A9B4C67E920F1C412E4208963A0B3748095
        3699CE0E4F3CB1043948E018C8749666586993DD7AA3CF4B27962007891C03DB
        747CCE4AA34C57E931F1E412E420416320D3557ACC4A2BF570443AC1043948D6
        18683FDD4AAB4CD7463BC927982007C9190399AED28E566A6DD5D192ED6A7F53
        3AC9043948C618687FC39A5ECD5B6996E96AFF8D7CA20972908431D07E9E9576
        D9AD3BB6914F34410E123006A6973AADD49B332593E96CFF8F78B2097210E331
        90E92A3DACE68A3512ACD8D9FE1DE98413E420CE636085AD3B76B7468C6A7525
        F549A774D2097210C73190E96A7FD2EADE70656B24C976B5EF239D78821CC473
        0C6CB4A735E254AB2B64BBDAEF904F3E410E623506EE1C31CF0E065B61EB5207
        7B2D8A0F40223E3958B8C2D61D556B24CB76B69F12838E20C8415D3C079DA55F
        48CF477953A78ECE74B6DF2DDE190439E812DE26ADAB7D35E9E9180B99CED2BA
        ECCACC841CB945B9FD8DCC56A582F43C8C954C67FB2C9E27480F4C221B7D0E16
        66A6977AA5E75F2C653BDBF76550322947D418D8BAF47DE979176B99AEF623C4
        3B8920075DE67390E96A3F4E7ABE25C1A84C67E92826259332CD6320D3D57E84
        1AEBD2932D31B25DA5BDB29DA577A53B8E200759BD3958A87620979E5F497ED0
        C899904CCAB414E6D778801852769B2F7F21DB59FA470C3A932007F5667390E9
        2ADD9399BEE1443DFF548E7453A78ECE76B59FCC6B498A52028BD2C2C60AC4A9
        53474B4FA3D459617A7B99BB05F1014E740DF1AEA0B374EF8A5B6FB499F4BC49
        B7395332D9CED2DEEA9B71062793338E6320D3D8EB63A33DD517BDD2D365E4E8
        9E90555B5467BA4AF74B0F00821C6417BD4A7C44BD1D1B719B9BC4EE8EA1ABBD
        2BD3593A9F2DDE9998D117E7F637D4EEC88D0D5147EA3E06B1B555474BA6B334
        3BDBD5FE4B8E8DA33898FB49507A34DBD97E46E31095B49F9B9026D9AEF675D4
        C9B9EA38ED6C67FB59D9AEF69BD44F8CC6F387CEF657B8D5A7682C710C74B6BF
        A2C6C8A29FA3ED372D1A3BA59F34C6525A0F5E05000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000020F172F37A5BC6F57B9F6FEDEF29DB81B79D13F4CE717C6F573BE8DD
        2FCD219D7740D4EAB5AD5769F37B36B603777FC777CFB07DF71627705F7002AF
        3E1283E18811A7B5CF9D6C079E6F07DECD8EEFBE253D09E314D27D0344626CD0
        FD31DB77033B70FF2D3DE9E21C0C47A49AD3EF4EB203EF6CEE04280818C156AF
        79AD8EEF1DEBF8DE3BD2FFEA2629A4FB0DD0CEF67B767002F725E9C995C46038
        2235DA0E9F355ABD29909E54490EE93E04B4AD1BB07DF7CFD2132AE9C17044E2
        B5063357B703EF2EE9C9948690EE4B2094358FEC5ED90EDCBF484FA4B404C311
        C955B746355E29C66022A525A4BB14689AFAB6407A02A52D188E4824BBD63DDE
        F1DDE7A52750DA42BA5F81A684E4E1DB0000200049444154D8BE7796F4E44963
        301C9138B6DFF3195620521080063BF04E92FE9734ADC11043A28CADCD1C6307
        EE1BD21327AD21DDBFC0B0D881B7A3F4A44973301C91284EE05E2E3D69D21CD2
        FD0B0CDDFC3919DBF75E979E34690E862312A32DF036909E30690FE93E0686CC
        E9F3F6929E30690F862312C3F1BD53A4274CDA43BA8F8121B37DF75AE90993F6
        60382231D8319982000C60E7640A02D0F0C9DAEC95A46FA7EDC07DDA0EBCDF3B
        BE7B9C3AF6ACF1F975BF3BCBEEEBFD9AE3F76E9E8660B821317B26465F04DC97
        D4834C75B6E3F8FE6E5B3A0700163B7929C242F0A81D78BBAB731FE9002086C6
        D5DC358C1702DF5B6807EE316A3B77E9EB05B0AC33174C3E1FF0BD37ED3E777B
        3A01480827F0DE36F413E15DF56050FAFA000C831D78CF99F9A9E01E46470009
        63E43016DF7D828787400299388341AD2790BE2E004DB07DEF87BADF2AA8D799
        74069040AD7DDE967ADF2CB8774B5F138026AD59EB1EABF37B0675B6039D0124
        981DB8D7E87B7EE0F64B5F0F8010D492628D3F19F6A53380A42F61F6BD77F414
        849EEF4B5F0F8090ECC0FBB59EBB04B74667000967F7CD28A85786E19F217827
        495F0B000D1CDFBB2CF41D82EFDE40670029D0DAE74E0EFBB193FAC29165CB40
        4A38BE3757C3CF86EDA4AF0380AE7D167DF79E90770957D319404AB41DEC7E59
        DDFA872C0A1DD2D7014013A7BFA737E45B87BFAF7DECB415E91020251CDF3B30
        E4F3849F495F03005DEAD6283B707F1EF2A7C30FE910202DEAD6282770E7855B
        9BE0CD55FF3BD297024013A7CFDD27E433852BDB6AB31C3A044809B5A5BAE37B
        2F367FA7E03EAFBEAC9C50EBCE4A5F0B000DDAFC599FB27DF7A650CF1502F761
        A7DFFD9ED3EFB6D12940D2CD9F937102EFF0906F2054BCEDF8DEF54EE01DD01A
        F46CD1E2F77C7CCD23BB5796BE3CC018DBF7CE7402F7B6B485ED7B776828084B
        B983F05E6B9C05D9F81BF2D71A36985E18E0F8DEADA6260E918C1C301D308082
        203F21A583E980011404F909291D4C070CA020C84F48E9603A600005417E424A
        07D301032808F213523A980E184041909F90D2C174C0000A82FC84940EA60306
        5010E427A474301D308082203F21A583E980011404F909291D4C070CA020C84F
        48E9603A600005417E424A07D301032808F213523A980E184041909F90D2C174
        C0000A82FC84940EA603065010E427A474301D308082203F21A583E980011404
        F909291D4C070CA020C84F48E9603A600005417E424A07D301032808F213523A
        980E184041909F90D2C174C0000A82FC84940EA603065010E427A474301D3080
        82203F21A583E90000000000000000000000000000000000000000000000003E
        A06E8DB2E7CE5ADBE977A73A81F70D3BE8DDCF09BC031CDF9BBBE83FBBBB39BE
        37B3CD77375DB3D63D96EC012963D7BAC7B706EE9E8EEF5DE1F8EEF3C3DBD0C4
        7DD40EBC8BDBFCDE5DD698BBC338E96B01D0A4B683DD2FDB817B91E37BEF68DA
        EDE86D27F0AE6CEBEFDD844E0112A2C5EFF9B8ED7B179ADC06CDF6DD6B9DB9DE
        46D2D70AE023D87ECF0E4EE0BD12C9FE88BEB7D0F6BDA33F599BBD129D82D473
        FADD498EDFBBB9B6E8EFD9CCAAD59633D2D85A6D3927F07E26B169AA1D7877B5
        F5CF58CFC875017161FBEEDD7A6FB3BD0B8D34B4565DC1F6BDB3248AC162770B
        2FF26C01A9D51ACC5C5DDD126B9C346F8FEB9BB98EF686D6AD518EEF9D225A0C
        FE57F0DE6CED776768BF46409AD3DFD3ABF95FD0538CB453AD21884131F8DF75
        BA6FD9BE3BCDC4B50262ECC03D5963315838BE7FE604DD6D54B7E81A5F29EABB
        5308BCD79C60E686BAAF171063FBEE831A27C995BADBA716093981F7A4F4E4FF
        8822F8180B99900AAB1FD2FD09AD93A3CFEDD2DD4627F04E179FF4CB0CF73CDD
        D70D44CEE9F3B6D135296CDFFBAF357F4E4667FB5AFBBDAAFC641FEAF5F7ECA0
        F3DA81C839815BD338297EAAFDE324DFBD457AA20FA3203E35EED09D57D39A03
        204A8DF5FF9A2684EE77F376E06D273DC9875D1402CFD79903205276E0FE5BCF
        64705FD2FD73C10EDCBF24B020BCA6D675E8CC0310899643BA73FA1624B9BFD1
        D936B54781F4E46EBE28B8FD3A730144C2EEEF2DE99B08EEDE3ADBE604DE5589
        2D08BEFBECEAB5AD57D1990FC038C7773D5D93A02DF036D0D5AED63E77B2F4A4
        0E1FBD7374E5038884EDBBFB6AF9173170DFD0F9FC40EBCA49B9B851573E8048
        68FC84F8EFBADAD476F8ACD18EEFBE1C83091D2E7C6F61DBBC9EB574E505304E
        ED1FA863F0DBBE7B8EB636F9DE4EE2935953D87ECFF775E50530CEF1BDBF6A19
        F8817BB0B63605EE9FA427B2BE70FFA82B2F80718EEF3EA165E0FBDEAE3ADAA3
        F650D0BC2F8368D881B780B70D480C5DBFD5DBFA7AB7D6D11EDB77FBA427B1F6
        F07B37D7911BC0B8F7B61A0F3FE835ED486C07DE3FC527B0E6609112126142AD
        3BAB6FD0F716C3B6A7ADCF5D37B249EABB37D9BEBB87FAD75BDDDD387DEE3EBA
        9EA744B13F046066D9B2A6413FAEDFFB7CD8F6D8BE7790F162D0D871C9DD4D7D
        45B9A436A863DDD4EF7ECD7FF7C9B0B901A2D95855D3A01FDFD7F385B0ED51DB
        9B1BBF3308BCDD97D58EC61D83EE079BFD6E5BD8FC0089D929695CE07E294C5B
        544189E0EEE05CB19592EA8C0A20CED4BF5ABA06BCFA3231CE6F17ECC07D46FD
        441A6A7BC6F777DB6A39B6BE62E47E334C7E00E372F37A5BB44D38DFDB29E4AE
        483A3779D5B262D00EBC5FEB2B08DEDCA6F30344412D9889C3806FEDEF299B2C
        066AF155338B835A839E2D247EAE0032D4BFCCBA9EA8FBEEEF9A6D86FA0EC26C
        41F00E6CAA5DB5EE55B5ADD3F0DD1B9ACD0F101927F01ED7B56DD8DAC74E5B71
        B87F7FBCDFFB496D936EC9C5E01DF5F0B4E9FCF8DEAD9A0AC23DCDB601888CE3
        BB7FD335F9D42DF6B0FF7EE0FDD4E4DD81EDBB9784C98F1DB83FD75330DD67C2
        B4038884BAD5D738F97E3BACBFDDD73BD1E8DD41E3ED474F4F98FCD881BBBF9E
        B6B8EFAA23ECC3B40530CE09DC13B44D40DF7B476D7D36A43F7C5EF7F2A63F73
        56AF0DC39E91A0F3105CB5F14B98B600C639BEF75DBD13D1BD4D7D23B1ACBF6B
        FBEE7C93C540C7CF05DD3B3FABD7BC61DB0318A5CE61343019AF5CF3C8EE9597
        7E67E01D6EBA182CBA43E8FD7AE8FC043337D4D69E5AF7F8B0ED018CB2FD9ECF
        98998C8DC35FBEA1FEF7D51DC3B89ABB466387675D4FED971D6FEB388DD9E977
        27E96A5398B71D40946B119E8B6892461676E0FD5E477A5AE7F67C4E5BBBF8C0
        09496007EE35292C08DFD6911B9D77081C028B44503BFA484F60ADE1BB6FB5D5
        66393A72A3F319827A7EA2A34D8051493E43D1D4DB85F739FDEE543D6DF2DED4
        D526C028F5D0CFF6DD57535310FADCEDE37646847A4EA3AB4D8071EA55A1F444
        D633F1DCA79BF9A662A979F1BD03F5B4CD7D54579B00E3DAFCDE5D525210B41E
        C3EE04EEA99A0AC2BD3ADB051835B636738CED7BAF4B4FE850E17BEFA8AF2775
        E645ADBCD452A87CF75A9DED028C737CF78284DF1D5CA43521F3E764D4C3403D
        C5CA3D4D6BDB00D3DAFA7B37919ED4A1A2DF9DAA331FEAAC096DC5CAF70ED2D9
        362012B6EFDE223EB19B0AF7B6A59DB5102217DF89D3771540E4DAFA3D577E72
        47B339CBB2A8FD1DE2B22B3520A3565B2EC20F90F4FCEBEBBB7FD69E07F555A6
        EF3EAFAD9DF37A3FADBD8D40145AFDDE8AF424973E5D59730EDE1ECA1E11406C
        693D93C06C183948D509BC9FE96AA31DB8FF30D14620326A771FDBF71E89C184
        5FFA44F3BDD7D57E0B667E36B94F686BABEF9EA1BD8D80CC474FEEBBD2137F69
        D11AB87B9AB86E5D1F340D449FBB8F89760291B303EF07F1BC3B702FD1FD9AF1
        7D4EE0FE466B7BE77A1B99682720C20EDC2363550C02EF9FB9DAECBC896B7D6F
        ABB7B7F4152EEF751E28225D6AB5E5741D58A261823DA2FB7B85C5D9817BB0E6
        E2759DA9B602A21CDFFB91E37B0BE5EE0CDC7FB7F9B33E65EAFAD4166706F697
        3CC0547B01716AF311914D597DF70FE3FBBB6DA3D7E67B3FD4DDEEF107CF58DF
        649B0171EFFDCEFE5D2477058BBE36FCB155ABAE60F29AD4A94AB6EFFD57F31D
        CDD31CDF8691A16E8D7202775BDBF7EE307347D0F86972FEB8BE99EB447139EA
        D65EFF75B8A746D17620660F1CBDED1CDFBBCC0EBC051A26D10B8EEF1EDFD6E7
        AE1BE91D4FE0BD92840FAE80C450AF029D7E7796ED7B273A8177A3E3BB2F2FFB
        4EC07D42FDFC505B9F35BE089C3F271375BBF56D93F681EB7A9ED78DC0E2EAD6
        A8D56B5EABFAD2AF3598F1C536BF67E3B6C0DBA0B5AF778A7A75188B0953B746
        355664FABD9BEB0C758DD2970600000000000000000000000000000000000000
        00006058EC5AF7AA6BD6BAC7AA4FA4DFFF4C5A7D3A9CA660480083762452BB07
        BDB789E92F6DDFBDD6F1DD7B6CDF7DD5C8F66B310B060346B4B6DA2CC7F67B76
        B07DEF2CDBF79E929E90D221DD1F40E4DEDBB57827C7776F88F379901404C0A0
        16BFE7E34EE09EE004EE4BD2132FAEC10044EAAD317787718EEF1EA2CE2E949E
        70710FE9BE028C52CF071ADBA5C760B22521188E482575949AF6A3D2474048F7
        1BA09D3D77D6DA8EEFDE2F3DB992180C47A44ADBC1EE97759F7B389242BAFF00
        6D9CB9DE4676E0BD263DA9921C0C47A482EDF77C469D602C3DA1921ED2FD0884
        A6BE2FB07DF741E9C99486603822F16CDF3D477A22A525A4FB1208C509DC6DA5
        27519A82E188C46A39A43B6707EE33D293284D21DDA740D3ECC0F3A52750DA82
        E188445ABDE6B53ABEFBB2F4044A5B48F72BD01427F00E959E3C690C86239267
        FE9C8C13784F4A4F9E348674D702C36607DE76D21327ADC17044E238817BB9F4
        C4496B48F72DD0CCF6676F4A4F9CB406C31189D216789DD29326CD21DDBFC0B0
        3881F733E94993E660382251D41909D29326CD21DDBFC0B09E1F44B16DFA7B1B
        AC9C6F07DEB75BFBBDAAD3D73B716CD0FD3127F00E6FFA7F3370FF9D9BD7DBB2
        B4185B9BB9A613CCDCB0ADDF736DDF3BC2F6DD9BC25EAB1D78D7B505DE069CDC
        84D4EE8664B418F8DEF5B6EF4EB36AB5E596F4F75B0377E7109373C1D2FE7797
        C6AE758FB7FD9EEF87FAB4DB776F505BCA69EB04202E9CA0778EA162F08AEDBB
        B397F5F7DBFC9E8DC3FC1D752E4453175EABAEA0AEBDD90D60D42E52EA6EC7AA
        5BA39AFAFB401CD9817B8CEE626007DE73433DE474F543BA3F11E66FB5FABD95
        B03B49DBBE77618836FC7242AD3B1BA60D406CA8DFF59A8BC182D6FE9EF2901B
        705EF7F2EAFF27C4DFDB317412EAD62827706B8EEF2D6CAA0DBE7B6DAE363B1F
        BA1D8034DB77FFACB720B8070FB70D8EEFDDD7FCDF746BBA72E1F4797B355D14
        02EF2E75B7A1AB2D80083B701FD658109E5CF3C8EE9587DB0627F0AE0CF1374F
        D7990FC7F7E6365D0C7DF796D56B5BAFA2B33D40A4C2DCAE7F287CEF47CDB4C1
        F1DDE343DC21FC516B426AB5E5D4ABC51045E112F533486B9B8048349EB46BBB
        3BA88FF77B3FD94C33D46BC0A62760E0FD47775A5AFBBCCF86FCB6E350DD6D02
        8CB36BDDABEA2A06EABDBECCA7D7EEBB269EF287BC6B79D7F6BD0EDD6D02CC6F
        99A6AF209CD36C3BECA0B718EA6F1B5824E4CCEBFD74B30F181BE1BBF77CB236
        7B25DDED028C59B4B4574F4170FADC7D42B4634CA8BFDDEF4EB50C502B12C315
        49EF2013ED02625F10ECBEDEAF85694BA8ADDF7DF79B96014EE0FD38545E7CEF
        45B5ADBD89B601B1FEC9E0F4F76C16A62DEA955DF37FDF9D671910765975A350
        06BDFB99681B60E84B473D05615CE07E49EAE8B830CF2F3EB24DB5EEF11A72F3
        E4DAC74E5BD144FB00BDCEEB5E5E5B41E89BB94E98A6D881DBDFFCBFC2DECD96
        096A49B3EFBE1536376D7DBD5B1B691FA09BEDBBAF6A290A7DBD13C3B4A3CDEF
        DDA5F9BFEFBE64EAAB43C7779F0F9B1B3B704F36D136403BC777EFD75110D4A6
        2161DAD1E6BB9B86FAFBF37AD6B2E25B109E66F52212416D60A2A520F83D1B87
        69879AD0E1EE50DC2ECBC84F2A3DBB49A98D68B4B70FD0CDF1BD7335DD217486
        9E7C217EAFAB7D1D2CCDDA6AB31C1DB96984EFEDAABB7D807676E01DA563C0DB
        BEF72DC99F2F6A7F454BB3D6A0670B7D05C13D4E77FB00ED9CC0DD4DD3BF8073
        C3B7C5BB2A4C1B5A83195FB4340AF3E6630905E10F3ADB061811F661DE62F1CB
        B06DB17DEFC45077298177B69EAC0CFC84B95F634178425BDB0053DEDB0A3DF4
        80573B2F856D8B1D783F087997F24ED8F510A60EBF559BB2EA681760D6A2C537
        2F6B19F02137067182DEE91A0AD32DEA68FBD09F8587DAD66DC9A1F69F08D32E
        20124EE0DDA863C08FEFEBF9429876B4CEEDF99CA6C97778C81D937EADBB18A8
        58B3D63D364C7E804838BE77AC9641DFDFD31BAA21B5EA0ADAB674534FF58779
        888BFAE620CC3715C6CE9000A264FB3D3BE819F4EE09A1DB12B8FFD038096FB4
        FD9EF6617CD978BBA962A042AD6B089B1FC03875ABAF69D03F10B62DB6EFFE42
        EB44F4BD858D331D7DF727EA8D4A5B9FBBAED3EFB6A9878FEA9017DBF77EA87B
        2BFAA5857A36A1A7C700936AB5E5D407425A06FEBCDE4FCB7DE414E770DFE57B
        062446C8B311B4AD586CFC0B2E3E798DC4E3FA7A0B30CC0EDCFDF51404F7DAF0
        AF41BDC7623081B5868E751A40649CB9DE467A06BFFBAEDAAB314C5BD4FE01A9
        2B083A575102C6CD9F93D1B5598A3A78254EAB04E3106A15A6BECE0222E0F8DE
        157A0A827767981D8CD4F9883A564FC629DAFA7B37D1DB5B8061B6EFEE11975D
        989DC03D557A12EB0A752C1CAF1C9138AB1FD2FD096D13C1F72E0BD396D67EAF
        2A3D9135C695FA7A09889013787FD73309DC77437D79A8DE36686B8B6CE8D83C
        06106107EEC1DA2683EF9E11A62D8EEFCD4C7C3108BCD772F37A5BF4F5101021
        75147AA8434E3F5010BC77D442A3A61B337F4E462D874E784138496B070149FD
        1CBA31217CEFC2306D5167464A4FEA10F1B6AE0D5B00316A87606D9342DD6DCC
        F5360AD31E3BF0AE8BC1E416F9FA1310B7E87876F7057D45C1FD5B98DD82D4C6
        29DA4E988A28D469D67CEE8CD4707CF710CDFF5AEE1DB23DDF4C5641E8EDD6D7
        1B80B07135770DB5A046E35DC2CB6A43D7306D7202EF74E9893EC4E2C74F05A4
        F3A7837A65A62B421F8BAEBEB708DC6BE427FC47153EEF0A365305222C52B17D
        C8E87BD7B3441988D8276BB357B203F722F102B058A8F6AC7964F7CA0C064042
        63BBF4C6A62E6F0BDF15BCA35677B23D1A10036A8D83ED7B77C81404F75FEA23
        2CE91C00F8D0398C8DC5548F477357E03EAF36819950EBCED211405CA96F1FFA
        7B7A1B4BAF757D8FF1C142708FDA33A2EDF059A3A52F15C030A87D1DEDC0FBB6
        1D78173B81F764530F0AD5EA48DFFD83E37B07B6F5CF588F0E00D2B4F98BDFBB
        796BE0EE6CFBDE4176E01D65FBEE7CDBF7CE5CB4A9AB7B8213B8F39C3E6F2F75
        E86CA300843CBC160000000000000000000000000000000080B81ADFDF6DB7F6
        F54E311EC18C2F5A2398DAD7D17C9EBDCF4A5F2712CEF1BD53A2F88EDF0EBCB3
        AD115E10ECC07BCEF0A6292FB0AF2242EE246C7A90368AC102DBEFF9CC48EF2A
        DB77F7359E6BDFDD43FA3A9150AD41CF1691DC1DF8DE11D2D71A076A23543BF0
        FE63F82EE15E759CBDF4B52281167D876FBC18BCCEB1621FC8F96EC68BB0DFBB
        B9E0B042524573DC3927090DDEC6BDD95D948691F353C5061592A9CD9FF529F3
        FF5279EFF0E4FBC39CC03BC070417889731A10BB034CEDC0BD946EF9B035E6EE
        304EFD94329AFB3E777B728F21737CF734E305A1AFF76B74C992D9BE7796D1DC
        FBDE99E41E43A69E469B1D90EEB3A10F584D31F5E0CF7041F8AF3A614AFA3A91
        90453246CE0E583C7CF778E9EB4CC071700F9BEC03B57A51FA329100EA08B008
        16237D55FA3AE3CEF1DD43CC1665EF47D2D78804508788182E08AFF0736108FD
        D0DF5B327C97F6BB08861392CEF6BD138DDE1DF8DE85D2D79808E7752FAF7EEB
        1B2C08CFB36A11CBE404EE1FCD1604F73B74C3D0388177BAC9BE18D737731DFA
        021FC909DC474D0EC291FEA9F370D8BE3BDB68710EBC1DA5AF1131A68E117702
        F75D837707AF5AB5EA0AD2D799146A25A7D982E01E237D8D18C10350FD1C91BE
        C644A95BA3ECC07DDA587FF060111FC5E9EFD9CCF0BF483FA70786C7F6DD4BCC
        DDB1790FD11F582AA7BFA7D7F01DC2DEA47F781A47C19BEB8F7757AF6DBD0A7D
        822572FABCBD4C1604B5E90AA91F1EDBEFD9C1E85D5BDF8C027D8225727C6FAE
        C9C137BEAFE70BA47E78C605EE974CF6495BE075D2275822DB77E79B1C7CEA3B
        09523F3C2D8774E78CDE21F8DEB7E8132C911378BF3438F0DE64655C73D4EB5A
        73FDE2064C072C9113B8E7191B7881F71FD2DE1CDB771F347697E0BBA7D12F88
        FE1557E0FD93B437C709BC1B0D16043E72C292D9817B8DC181F737F2DE1C3BF0
        2E3658A86FA65FB0444EE0FEC9D8C0F3DD9B487B731CDF3BD7E8590DC09238BE
        77ABC181C7B2E52639BE7B86B97EF19E64366089ECC0BB8B3B8491F53AD80EDC
        37A4AF0F23F070163B70FF217D7D49657AD31A758EA7F43522861CDFBBCFD8C0
        F3DDFBA5AF2FA90CFF64A8F33D039648BD093058109E20EDCD7102EF7C930521
        579B9DA76F10EDFBEEC07B9BCD519AE3F8DE1566EF10BC56A6033EC4F6BDAB4D
        0EBCB6793D6B91F6D815EAFAB89ABB06FD820FB17DF7B7460B82DFB331691F3E
        27F01E377A877048F727E8177C881D78679B1C78B6EFED44DA87479D6161729F
        CB46BFD4BAC7D32FF87041F0DD5F981C784EE0FD94B40F4FEBDC9ECF19EE93FA
        D8DACC31F40B22DEAEAB717CD8ADA47D789CA077BAE982C0C35E2C913A44C56C
        4170DFE29D77BCCE78B4036F01D3014B6407DE76A6FF355287C992FEF89CA4E5
        F8DE8BF4079668FCC133D6375D106CDF3B9AF40FD1FC39193BF05E337CD7C682
        31C8ECDFB728DC47D94A6D686CBFE72BC6FBC3F7EE633E60A96CDF7BCAFC5D42
        4F3B5D108BB73EEA19C2EFE90B2C951D78D7992F08EE7CBA60196AD515ECC07D
        26823BB653E90B2C95FA8D6FBE2078AFB7D5663974C3D2B5F5F56E6DBE1834FA
        E220FA01622705311087C6F1DD3F44D40FAC1EC5D2B5F5B9EB463410FF3BEED0
        9D57A32F64DEF60C447FCF66F40196AE565BCE0EBCE7221A9087D2151FE604EE
        6FA22A08F6DC596BD307F84876E05E14C9600CBC05E3FA66AE4377FC4F6B7F4F
        D9F1BD8511158457ACF3BA9727FF103D05FA430785D4AD5174C9C042A4BB22CC
        FD1FC83B96695CBFF7F9C80665E39878774FBAA5B1EE60DF28F3EEF8EE61E41D
        F21BAE7E7860BEE50433371CC95DD316781BA89F50511604F5ED8AF47523216C
        DF3B22D27FAD02EF81356BDD63AD1148ED69A80EC38D38DFEC9484A153FF6247
        3D406DDFFD73DBE1B3468FA47E9A50EBCE1A3D537369C1474D88F5CF8681A2E0
        FD9FDA366C44F4D679DDCB9B3DB7F1230BC219D2978F84B103F76089C16AFBDE
        859FACCD5EC94AB3BA35CAF1DDD3448A81CA715FEFD7A453808451BBF13ABEF7
        8E4C51706F1ADFDF6D5B29A4EE80ECC0FD95583150DF928CB09F66D0C4F6DD4B
        A406AE3AAADCF67B3E93A6CE543B1CDB8177B35C4E1BC5F6B7D2794042D981F7
        55C9C1EB04EE4B76E0ED68A580DA3ECEF6BD4764F3D92808B3A5738124FFD60D
        BCBF4B0F622770CF4BEA6BC9358FEC5ED90EBCA34C9FAF30A4F0DDB7D698BBC3
        38E99C20C1DAFC9E1EF181BCE848F967D4AA46F5AACE4AD2BE06BE7B8F74EE16
        2FACD239411A5E8F05EEBDF28379E05FB9FB55918AF38739767F6FC909DC3F89
        E76A70F0B93392B245FB70C3F6BD87ECA077BFB89C5EACEE5C1CDFF51CDFBB5E
        3A374BCC57E0FD930FC9A0F359C28DF11CE8EE1B76E0FD5A4DC6DCBCDE9648BB
        BC565DE1BD878547D881FBB4742E965140D91D09BA9733C7E0C1D847C7DB6A27
        61C7777F62FBEE34ED770FF3E7645AFB7AA73841EF9CC6E1B8BEFB7C0CAE7908
        E13E9AA4672F4808B563B2FCE01EF6BF8C0F39BE7799ED7B273A81F7E3C6BE91
        FDEE5455E0D4E4566B1D9C79BD9F5631BE7FE604F57F53FFEA3B7D6ED77BC7DB
        1D6AFBDE59EA6CCAA8BF48D4581076931E3B48EB612EBEFB84FC0027867518CB
        FC3919E9B1839452EBE09990C92948EC7B00E39CC03B5D7AA013432806BE7735
        D30191FC74B003F7DF4CCAF81626DBF7DE6CEDF33ECB744024ECBE1905E3A713
        13617E2AFC80A9804839FDEE2C266D0C0B97EFDE10E7959C4831C7F78E159F00
        C4E2C5E0F9B6793D6B498F0B8CE4D39E7CEF4226650C0A933AE4A5CFDB467A48
        6084533BF0A85D8EC427C4080F4E7346BC162D05EE6DD29362A486EDBBE7F0F1
        126245ED8318E97164C4A2621078BFE75B05C492DAD9487ADFC09114EAA7DAB8
        43775E4DBADF8165FD7C88DF0621290B3B70FFA272CD504432B61B575F09C660
        E2A47559F2D8DACC31D2FD0C0C5DDD1A65076EBFF4E4495BA8CFD0D5E62C0C45
        249213F44E7702F705E98994F8F0BD85BC5A442AB4CEEDF99CED7B77884FAA84
        86EDBBAFAA6DE2A4FB11D0469DD9E8F8EE215247C42535D406A96DFD33D66328
        22955AFB7BCA4EE0FE4B7AA2C53FDC77D5212FEAB017E93E0322B85BF00E5487
        8FCA4FBC1886EFDD67FB5E07C310238ADADC74D136EADE42F1491887F0DD97D5
        7913AC3CC488362E70BFA4DEAD8FE042F09613B827B406335797EE0B2036DA02
        6F83459F53C7FE0C082DA17E32D9BEFB0B75A7249D7B20DEAF29D5A9C989390C
        65D885E021DB77F7E5346660B8C7A9ABC35502EF4A753293F4440E19AAFD5735
        3631618B33209CB6DA2CC7F1BD5DEDC0BD34411BBCBEE2F8EE05AAA8A92F4119
        0380B13B07779A13B8F31A07D1361ECAC563FBF3F73EFFFE696BE06EA55EAF32
        008088A989A71E4836EE20D41994BE77BDED7B4F199DFC81F79C1378B73BBE7B
        9A1D78BB8F3F78C6FA1C9B06C498FA44D8E97727A97FADDBFCDE5DD462A845CB
        A7DDE31B4FF703F73CDB772FB103F71ADB776F717CF70FEA3F3B8177BEDA96EC
        BD036E7F6A079EAF8A4D6B9FB7655B9FBBAE5DEB5E55FADA0000000000000000
        0000000000000000000000000000000000A4D8AAD529ADB98EC99BE53B267F27
        5F2E1E9A2B177E992F17AFCD950BF7E42BC507F3E5C233F94AF1F97CA5F056BE
        52ACA729A4730F881B579DF2F95CB9B077AE52BC34572E3E263D29290840C45A
        AA93D6CB578A47E7CBC587A427619C8281889163CA944CAE5AD829572EDC243D
        F1E21AD25D04446154AE5AECCE970BFF929E70710F8623522DDF317952BE5CBC
        5D7AA22525A4FB0B3065B97CA5B857BE5C7C537A922529188E489D96CDA7E4F2
        95C2FF494FAE248674DF015AB596A7ACCE4F040A0260B594D7FD78AE527844FA
        5FD92407C308A93076830DC6E42A853BA42754D243BA1F81F0A64CC9A8A5C5D2
        93290DC17044E2E52A455F7A22A525A4FB120825579EF8C5347E644441009A59
        8A5C2EFC537A12A529188448AC96F2E4DDA42750DA42BA4F81E654AB2BE5CAC5
        47A52750DA82E18844CA7514F6919E3C690CE97E059AF2DEEE45E213286DC170
        44E2E4CB932BD21327AD21DDB7C0B0E5CA8533A4274E5A8307A3624C00002000
        49444154E18864A95657C8950B2F4A4F9CB48674F702C3C2CF050A023020572E
        F44BFF2B9AE660A82151F2E5C2ADD29326CD21DDBFC070BF6A8C644BB45CB9F0
        70AE52383D572E7E5FEDD49C2F17A7E7CA85B39BFEDFAB14FF93AB16375F6A54
        267DAD71304CA57854AE52F843AE5C7C35F475948BD7E52A8539C309862312A3
        A53271A2E142F074BE5C3C20579EF4A925FEFD6AF15BCD1798E2ABC3BAD86A75
        A5967261AB7CB9786E888FB716E6CA859FAE3E65CA2ABAFA00888D7C476196A1
        42B0305729FE4C6DB2F2517F7F4C79D257C3FC9DD11B4D729AB9EEB1D5896BE6
        2B855FE4CB85779ABB5328FCABA55C6C6F3AF1401CA97316B5178372E16D5568
        86F2F757AB143F1BE66FADD631E9CB61AE5FFDFF37BD42735131D933CCDF0762
        25CC6FF8A545AE5CDC65C80D983021DBF4BFD29562BDA563B21B3607E3DAD759
        2D572E5C1CE29A8F565BD4876D07204E3D6CD35A0C2AC53387DD8672E1E1E6EF
        468AFB6B4AC572EA81678876FC4615374D6D0164E4CB85FB35DE19BCDACC6FFA
        507B37968BF3351F447351C862384A637B8068E52A85D7F41584C231CDB4215F
        2E9ED27C41285CAD331FEAE743BE52BCAFF9A25098ABB33D409496D3550C1A93
        A15A2836D3887CA5F0E31005E17EDD49C97714ABEA2D49F34561D2CEBADB0418
        D73675D2688D05E1E966DBD15229F686F8BB0BACEEEEE50DDC39FDB6F93BA5E2
        AB633699F219DD6D028C1AB3E184B1DAEE0E2AC54BC3BCFA0BF3B7D5E9527A33
        13BE4DF972E11A9E272051C6B54F5E43DB1D42B9F09366DBB16A47D10EF7B727
        572C03C2EE3ECD4F07248AFA97555741185329CC08D3965CA5F872F305A138DB
        32205F2E1E12AE50151F52DF8A98681BA05DE87F99172F08E5495F0DD3965CA5
        F0F7A6FF252E170EB20C68A914B70C9D9BEAE41D4CB40DD04E7D67A0AF201436
        08D3967CB97861F3B7E685D32D0372D5C25A61F3A27E76B08A11C9F9F4595341
        18579DF2F9304DC9970B478428087FB44CE8EE5E3ECCB2EAF7A3A5A35032D23E
        40375D7B21B4940AEB866A47A5B87BD37FBF5C7CCA3244CF5E9385C34DB50FD0
        2AD477048BC598EAE42F8569474BA5B84598BF3F7AD3F5DA2C03F2E5C2B3A1F3
        532E3C60A26D8076B972E1261D0521ECABBFD5DA27AE13AA20558A532DFD4635
        3EE5D6909FB11DC50906DA07E815E661DEE2A1FE850FD590696BAF98AF14DF8D
        D39B865CC7C4162DC57251ECA8BB7D80766A57A3C8F740587A5BFED3FC1D4AF1
        764BB396EAA40E8D05E130DDED03627BC0AB8E7FA143EECDB030BFC9E44F5A1A
        A9BD167415845CB970A5CEB601566C17DF2CFA17FA94B06DC9978BA7866CC391
        561C9FAFBCB7E3B4CEB60146A8AFF2340DFADF876D8BFA1E22DCA42BBEBA6A75
        4AAB8EBCA8B503BA8A41A36D95E2CB3ADA0598D5587CA3612D42B9F06CD8A6A8
        EF2124B6705B524E72E5E2F53A0B82FA49C38A45244298EF083E10217FC3E73B
        264FD2D28E901F3BE52BC59AE662D08896CDA7E4C2B40B8844BE523859CB6D71
        47619B30ED5873C30D570EF3EAF17F5178ABD9A2A04E950AB35BD247853A0B22
        4C7E8048B49427EFA6E95FE643C2B645ADEAD37850CC71437DA66057D71F1F6A
        D7E52184FA1B61F30318A7961D6B1AF47F8DDD3911E5E20BEAE8B596EAE46983
        4F91527724B98EC99BE5CA856343EDC730D43B84659C6205C443E3B0142D1F39
        BDABF65808D3947CA5B897C94999AB145ECF550A8FE42A85974C178041B1D0AA
        5657D0D7698041B94AF1061D03BFA55AF444F7328C6B940BCFE8EB2DC0B05CB9
        D0AF67F017CE0FD5906A7505759B2F3E81B547E1366D9D059836A65CF88A8E81
        9F2B17DE08FB7A4D1515F909AC3D2ED2D75B80617675C2AA8DD7753A8A42B5B0
        5398B6A80FA562308175474D5F6F0111C8550A376A19FCE5E2B5E1377FD5539C
        62131D93B6D6D7534004F295E28F344D80852D958913C3B425E4F1EC718BD06F
        5F80C8A949AC6F12144E0ED3965C4771FB184C642D912B17FEACAF978008E52B
        C57F6B9908E5E29BA1F6399C3225A3D60B484F664DB9D85F6B27015151ABFAB4
        FDCB18F268F45CA5F8BDE41783C23BBA376E012233B6FAC50DB5158472F1D530
        EBF7DF3B48E679F1491DAE28FE566F0F0111CB578AF7EA9B10C5E3E2B0C59B58
        183A8816884CBE52F8B1C649B120579EF4A990A74BDD9BCCBB83E2A55A3B0690
        3076D3C2C7D444D63631CAC54BC2B42757296CA2679F8448630167312035B4EF
        0D502E4E0FD31E751C5AB2EE0E0AFBEAEB0D40584B75D27A3A770E52AF10D5F2
        E8A61B34614256BDCF979EE8C3D8707639AD1D0248530795E4AAC5CD75C5E88D
        2639A19734970BF7C760C22FBDF0950BFF1CB3E184B1FA7A01C0476E1BAFEB80
        5AEDC5A052FC4FAE5A588BEE0322D45A9EB27AAE52B8236E77062DA5299F6020
        00021A07B16A3AA856C39DC165FC4C0062A0A55AFC96C0FE88EF1582C2EB6AE1
        943A365E3A0F00DEA33EA27AEF6C89A8D62A2CCC978BE7F28D0210636A45A43A
        1BC2E0F70F0BF2E5E2796A2358E96B05309C13A0CAC5E96A7155AE52783CE4F3
        8197D51264B52DDC6A9BAD3F8E4E00124E1DA1962B4FDE4EED4B90AB144E540F
        01176D3B5FB82D5F2EFC2B572EFEE3BDFF7C8D3A2C36572E06AA0034767DEAEE
        5E5EBAFD0000000000000000C4975A769BEB98F86993614D5B7B45E9EB043004
        F972E16AA32BFBCAC5A7D4DA003A0388B9B6A99346E7CB85B70D2FF5FD91F475
        0218829672B1DD703158A0BE4CA4338004C8558BDD860BC255D2D70860887295
        C21CB3CF0F0ADFA633808450BB039B2C08614F810610A15CA5E89B2B0885B7D4
        6EC974289010B94A613F5305215729DC2D7D7D008621572D7CD358412817AEA4
        33800469EC1360EC8162F15CE9EB03300CEA74628305E1143A034810B52D98C1
        6708274A5F1F8061CA978B0F992908C533E90C2061F295C22F0C3D54BC5CFADA
        000C53BE32B9CBCC3384C2BFE80C2069264CC8E6CB85670C1484B7431D010F40
        86DA7ADCC45D424BA5B8057D0A24CCE88D2639B972F1150345E1E7D2D706A009
        6A2313036F1A5E1ED7BECE6A74089034D3D65E315729FC5D7F5128EC2B7D6900
        9AD0522AACABFDA743B9F882FA49428700C97D0DA9F568757560AA6559A3A4AF
        0D4013F2E5E26CDD45215F29D6E80C20C1FB2DEAFEF990EB28EC237D5D009AD4
        529DB49E5A71A8F999C2911CB30E2454CBE65372F972F13CCDCF146E18B3C994
        CF485F1B8026E52A854D74BE96CC550AAFE5CBC54354C1A1538024EAEE5EBEA5
        5AFC56AE5C7C4CE31DC373F972F1D05CB5B096F4E50168C69429993195C28C5C
        B978BDC6C2B030572EDC942B177E30A6525CDFAA5657A0730001B98E2F4E693A
        CAC55DD41265FDFB2934DE70DC92AF144FCB978B07E4CAC56FE42B933A73D5E2
        E62D95C91B856A7384C18046E2E89ECCC4FF7220DDB7C0B03181CD1531862312
        87824041000650102808C0000A020501184041A0200003280814046000058182
        000CA0205010800114040A023080824041000650102808C0000A020501184041
        A0200003280814046000058182000CA0205010800114040A0230808240410006
        50102808C0000A020501184041A0200003280814046000058182000CA0205010
        800114040A0230A071DC3B6124070C3300000000000000000000000000000000
        0000000000000000000000000000A45E4B79DD8FE7CB853D72E5C2C5F972F1F6
        5CA5F078BE5C7C215F2EDC9FAB146FC8978BA7E62A856DDBA64E1A2DDD560086
        8CAB4EF97CAE5CB83C5F292E1CCA36E8B972E18D5CB970BC5D5D7F3C9D02A4C7
        A85CB9D09FAF14DE6AF23C84E77395495FD3D9A07CB9700D6126073AFB0969D3
        DDBD7CBE5C3C45C3C1280B739549DFD5D52C0E6AE1A01608C8950B676B9E7C7B
        E9681705818280888D291776D53EF1CA85B75BCAC5F6B06DA320501010A1D5DA
        27AE93AB145E3732F1CAC587ECEA8455C3B48F82404140847295C2E926275DAE
        5CD83B4CFB2808140444645CFBE435F295E202B305A1F8A8356142B6D9365210
        28088848BE5CDC3F9A0937B9ABE93646D2BE91197A4713122F5F295E15D1E03B
        3A441BC5274E5A43EF6842B255AB2BE42AC59723197CE5E2EDCD36537AD2A439
        F40E28247E79728483EF5D55809A69A7F4A44973E81F5548AC96EAA48E2807DF
        AA1D45BB99764A4F9A3487FE5185C4CA978BD3A31C7CEA8EA4A976C660E2A435
        F48F2A2456BE5C9819E5E05BAD63D2979B6A670C264E5A43FFA84262E52B933A
        232D08ED13D769AE9DF21327ADA17F5421B15A3A0AA5480BC266EB8F6BA69DD2
        9326CDA17F5421B1D4BFD8910DBE72E16DCBB2966BA69DD29326CDA17F5421B9
        BABB97CF950B2F4634F86E6EB699D29326CDA1774021F172E5C215510CBC5CA5
        30B7D9364A4F9A3487DED184C4CB958BDF8FA420744CDEACD9364A4F9A3487DE
        D184C4538B858CED85F07E31A814EE6EF6F981223D69D21C7A4713522157299C
        6872D0B5548B5E98F6494F9A3487BE5184D4C8550B6B19FBC8A95CF88B7A7819
        A67DD29326CDA16F142155C6540A330C0CB8E773E5499F0ADB36E94993E6D033
        7A904AF94AE1648D836D414BB9B0959E76C94F9CB4868EFE417A8D521B99841D
        64B972F19596EAE469BA1A253D69D21CBAFA0829962F177EA2561636590CFE91
        2F150B5ADB13838993D6D0D94F483135A97395E2A56A6393210DAE72F1A9966A
        F15B611F202E49AE63620B612607BAFB0A29377AA3494EAE5CFC46BE5C3C2F57
        2EFC39572E3C9C2F179E516B0BF295C2FFE5CBC523F3E5C91513850000000000
        000000000000000000000040EAE5CA85B3F3E5E2FE3AF633009070B972F1CE81
        2F182B85BB73E5C241140760845ABC202C16EFE62AC51BF295E25EA3375DAF4D
        BA8D00640BC2629F3B17DE79BF38AC5A9DD24AC70023B9207C702F8437DFDB3B
        6147BB3A6155E9B603902C088B853AE34115875CB5D86D4D5B7B453A0618C105
        61D09DC30BB972E197EAD8796BCA948CF43501902C081F8CE75471C8558B9B87
        39C509403A0AC2FF7E56948B8FE5CA85635BAA933AD44ECF743030820BC2078B
        43E161551C721D5F9C227DCD00840BC2A007928D0550AB754CFA1C1D038CF082
        B0A4E290EB98F869E95C00239E744158D2EA48BBBAFEF811DF31C0082F084B5E
        1DD951B41919C0482E084B591D39AE7D9DD51818C0482E088B45AE5C78E3FDE2
        D03675D268060630820BC2A0E2F022AB2301CD925A1006C5F303C5A15A5D8141
        028CEC82B0D89D03AB2381A6A5AD207CA038540A8F2CB6741AC0482E084B5C1D
        D93E711D460530C20BC2928AC3984DA67C8681018CF082F0C128DCA61640B596
        A7ACCEC0C088474158C2C6B21B4D7246FCC0C0C8444158C25D43B9F04EBE5CB8
        462D801ABBC10663A4FB08880C056119CF1B581D8991848230AC8791AFE7CBC5
        F31A0BA026FC7F7BF71F24C95517007C2FB9845FB99BCBDDF6EC254641F30338
        929B0967302637B39044134BA84271B3DD7B490828F147C068198828BA64BB37
        3F444154C4A0A5160291F8038D685910A910AA28D112544288800492402289B9
        23C225E4C7C57AB33F72B94CF7CEAFBBDE9DF97CAAFABF99EE99EEF7BEFDDEEB
        F7BEBDEDC8B2AF1D0C9C80D0F380A4D9910C9F4AB37673F923FD6B7BAB346B5F
        6F4D806A9EFA837247B2E61D7D66ED459566ED8AD6405AA3F668D9156C2D6F95
        66FD4EB323191AE1756DE1E52BAD54EA8DDA9EB22BD89ADE1AF53B3635EAD76C
        6E9EFAC2B2AF2BF46F72727D5807100AF5A666FDF6D22BD8304C9D6ED64F5434
        190A21116A98B8A36B3180E0D0AC5DB1E58C538F2DFB9AC2406C38FBB42D4B5D
        8BF02AB7B2EFC06B7E76E459274F289A0C87A9A9C397BA169546EDB65550D1D6
        DEB69858B6D2AC5D627624C3DBB568D61E29BDB2ADB56DBFC4B2D1E4B6A3CABE
        9E30301B4FDFB679B96BD1AC3F507A655B635B981D1982433887664732BC5D8B
        66ED736557B635B735EABB259665A8BB16A1CFBCD83CFE4EE9156E2D6D8DDAFD
        ADB92293F573C6C6C60E2BFB5AC24085F72C8445439B1AF5EB3635EAF7965EE1
        D6D05669D4EFDA6F76E43A4593E132357578786D7C98C8B398D1A8F44AB756B6
        4AA3F695101C2A8D535E5CF6658483A2D2D8FEBDBA167DCC8EDCB9FD244593A1
        74F4393B2A4F4E88AADD57F61D79AD6C655F3738140E3BA06BB1AFEC8AB75A37
        C591915399AC3D6FB96BD1A83F5C76255C4D5BD9D7064A75CC8E1DCF5E7A6A51
        69D6BE5676852C7B531CE14923DFB550182047585918D6098484A99546FDFFCA
        BE7B6B21C02A71DCE9A73F2BCCF65B78765FBFBBEC8AABCB00AB30BFE4629E82
        A1796A51F67985352FBCD26DB96BD1AC3F5876A516106035762D9AF53BCBAEE0
        5A08B07ABB168F975DE175196095386A673D7AB26B51FB66D995BFDD56F63982
        D13439B9BE359D7AF9C537AB63C664D9A70558CCF3B0B1B1FDDC8504B4F54F94
        D582703160755AD74A42BB73FBCB4322DA8541CADA5E010146CDE4E433175767
        5EBCA951BFB6D2A87D606150F2E067A62EFBAFC3C80B8F2A435AB3D5309E30F2
        17034AC92ABDB37666A551BBB2D2A8DFB29A12C72A0D70E897597FBDEC8A2F20
        C021B61613B1282470F0F229945EC1050428E93D119546ED9EB22BB4800087D8
        30A77B5798602523F44218850146A02B20204097BC54560B815136425D012D04
        68C3DBA38D2130E27405B41018F5B50293DB77B6720B346B9F2BBB19BE96B6B2
        2F1D0C4465E729472FBFEDB9597FA0EC8AB55637C591356BCBE48E17541AF5CB
        2BCDDACD9B1AB547CBAE4C6B750BA9E32BCDFAFBC263D6B2AF29744E57607041
        A0517B6871A6E54561A05531644DD878FAB6CDCB5D81467D77D977D335BD35EA
        0F2F05812D673C7F43D9D7163AD2CA25D8AC5FD6CA1E7408D2860DF5D6A83D16
        D2AF85B517479FB3A3A208B2B6BA028DDA6DA557A221090221A886D7CC957D79
        6145BA02030F048F2F058168F2B4AD8A20AB9EAEC0E05B03619E4548CEBAE58C
        538F2DFBFA42375D81CF97DE941EA620D0A8BD75E3CB761CAF08B2AA6D38FBB4
        2D4B4F052A8DDA9EB22BCFB005810D3BB79F54F6358642BA020737088409588A
        20ABD7E4E4FAA5AEC0A666FDF6B2EF9E43B535EA7784D7B685F35BF665865CBA
        0207B33B50BF73BF20B04E3164D5AB34EA9F2DFDEE39445BA551BF5B1060CD12
        1006D11DA8DDBFB01A73FB2BC21398B2AF29F44C40E839103CB01C042627D72B
        820C0501A19B96407DF77210D8B1E388B2AF1D0C9C80B0C29840B3B637AC240C
        7330C6CE3BE1198A20434D4068373028A700234A4058EE0EC82900231D10E414
        80110F08720AC0D8A807043905A013C31D105AAF71BB4C4E0118D18020A7008C
        784058CE29D0AC9FA830C0080604390560D403829C0230DA01A1D2AC7DD57262
        18E18020A7008C7A4058CC295099AC9F33363676980201A31710E41480910E08
        720AC0680784A7E414D8B6EDC8B2FF33708803829C0230EA01414E0118F180D0
        A83DB6A951FBE8A666FDA2CD2F79C9C6B2FF0F70A803C27E39058EDA598F5C00
        18BD80B09C53E039679D3C51F6EF064A0908720AC0480704390560C403829C02
        C05865B2F69A0D3BB79FE4540000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        00003048E3D9AE63A274FA87ABF3D333D5B9E4B2284BDE3891CEFC64358B7F6C
        229D7EE996D9F8D87EF65F9D9B3965224B5E11A5C96BC2BEA334BE349A8B7F22
        4AA7CF18BBEE922306F74F86D709EF3CEF19D1FCCC99D1DCCC8F4759F2735136
        73C57816BF369CD7ADF3BBB695FDFB58E326E6E21755B3E46D519AFC47354B9E
        E860FB5A94C6D78DCD4EAEEF64FF5BB2F8FBA334FEC36A9ADC5DB8DF347EB09A
        C57F150A7637BF7F3C9D6976F8BB978EF340358DBF1865F187A2347E53F5EA99
        EFEBE4385116FF41A7C788B2E4DB519A7C234AE34F4659F29E284B5E75DC6F4D
        3D6BAC57B3B38755D33889B2E46FA334FE56E1B1D3E4AB519ABC7BCB7CF2829E
        8FC7E8D99ACE3CB79A257F514D937D5D55A8C5EDB9B3AF7E66D1FEA374FAF86A
        16DFD0D3FED3E496F1ECFC171F9480F0F463ED8BD2F8FACDD9D4770D2A20E406
        A2B9E4B2B11BA60EEFE63A4559726E17C17AFFEDD110B88FBDEAC22DDD1C8F11
        149AE9D534D9D34F012F0A08A17BD1AA007DEC3FCAE287C6E7E3F30F7A407832
        30DCBD756EFA85072D202C6FF10D9D768FAA59F26BBD06ECFD8EF785F1B9E4C4
        4E8EC7081ACFE29FEFBF90E50784289B998AB2E43B03AAA4FBAA59FC33872420
        2C04A1FFDC363B75E4C10D08ADFFF5EB8517E989B175AD6ED6A0FE571ADF1FC6
        6FBA2B290CBD289BB9B89B6010A5C9C3DD048468EEFC5A94267B3BAB14F1239D
        7E2E0CA2F51210A234FE9B56B7258B6F88D2F863519ADCB1E2F1E69257761310
        42658BB2F8A3AD2D4D6E8AB2E4D60EFAF97B8FBE66AA92F79FAAF3F12F751E5C
        3A3C8F59FC85CDB3BB36F6517C1826D5F9787B6886AF70E7FAAF289DBE3C7C76
        E26D173C67BFEF4E54D39973AA597C7594C55F6E171042610B837505FBDE17A5
        C9FBABF3D36747B3534785EF84638CCF2793D52C796F71A08AEFCA2BCC4501E1
        B8D9A9CD4FF9F01363EB26E6675E16A5F17FE756D62CFEEDAE5A0869F20F077E
        36B43242CBA6A8A534914E4FB73D4E3A7D4661254FE307A32CBE320C0687270E
        E13B5BE7A7A28541C7F85F560844EFEFB8C030C4169AA09F2ABCCB8401AF4E9E
        1CDC307578354D761DD80FAE66C9AF16DCA9BF559D8F7FA868B7E3D9F48F14B5
        2EA234F9E5BE03C2A2D0E228F8ADD7F71B10F6FBCE9B0BFECF5BDB7F27F9E782
        4AFDEF9B67771D577C6DE2DF280ACA555D07C233EBA26010E61EF473968E997D
        F9B3C363B6DC9641969CDBC97EC2F843C19DFB7FDA3DBAEB2520B41EE365C9A3
        39DFFBBD410584F048B3A0723FED3813697C56FEFF4FEE9C98BDA0DAC9796CB5
        B8B412C81365C93FE5159030C8D8EF990B13630A0AF27BBAD957A860DDF4EF7B
        0908A1FF5EF07B5F35A88050749CD0FD6A738C0FE57DBE9BF919C7CC26E3D52C
        DE9DD332793804F04EF7C590D972ED6B37E4F649D3F8F3E16ED9EF3142333BB7
        75904E1FDFCDBE42D7A19BFE7D4F5D8634BE34FF7CB4EF36F51210C2A4ACFC3B
        F5F4856DBA626D1F058781CAB12E55D3F85DB9C1289D39A7DBFD3124C29D25BF
        50C697F67D8027C6D655B3E49E9CFD7FB2EBFD2DF4831FCCA9B09FE92B205C77
        C911D52CF9A9F683ABF1EEF09424EF67F5348690267F9613D81E3AB0F9BFF5CA
        F34FCBAFC0C9AF747B1AC3E06D412B28ED767F0C896A1A5F935730C6AF9A3EA9
        DFFD87197E0505EFEDBDFDE6E4969C66F6EEAEE621A4F1CD4B8F04AB59F2E96A
        167F33E777DE169EAC14FDA6AE02C2ECE4FA50E9BA69E984A712799F0F4F46BA
        3D8795D9576F2A7872F3DE6EF7C790A866C99FB6BF7B277B07B1FF7057CDAD90
        2B4C2ACAFDCD69FC2739956FDF814F37FA9A989426FF564DE3D7E54D46EA6C62
        527C7B586014B630B3307C2ECAE2AF1404C95BF77FA4BBDF7F7E4BDE770A9F2C
        14FFE6FBBA6DD530E4AA59FCF73905F9AE41ECBF68643C3C1BEF659FE10E9A7B
        B73CA0A9DD4F4008F304C2E3D8B0F2B268A2D0A0662A867902D1ECD4D6B6FB4F
        9377E47E6F71DE46D7E73167BE4594C69FEA657F0C81D08FCF299C5F3ED86314
        13F349DCDB6F4E7E336F9F0756DC414D5D0E8F358B1E8FF61310166633CE5C51
        D412094F6372CF639B164527C244B39C9BC1C77BD91F43204A938FE4341BF70C
        68FF3BF35B08C94FF7B4CF2CFEA39C16C7236110F360AD65585C2178DE200342
        18BFE864CA70354BAECDDB47AF792842906B1FA092BFEE657F0C81284B3E9053
        59F78529C9FDEE3FACBB2FA810D70E348865C93DFD3C6508FFB735553A4D3E58
        5081EF6B5781FB6B21249F5D691C20745BF2BE3F3E3FDDE8F61C865645354D1E
        1BC4DC10864851DF346F3E7DF7F31CDA17BC30CADFD334EB2CF9DF9C8AF59181
        CC545C18C4CB9DE21B65C9EB3B5EDC14D60F84751E73C92B5B9FC919D90FFDF9
        306128EFF7846B911F50A62F1F64CB2D4AE33774BB3F8644C8295070E7BA6910
        C7C85D5493268F753B425E3C7D377EF3A0024218A8CB5DCD99C67FD9EB63C730
        905A10143E9637112C0C36E63E264C937FEDE61C2EFCDEE4EDB93782F9F34FEE
        767F0C89859570F92B09F3FACCDD08D3700B82CE3BBAD95794C57F975B90AF8C
        7F605001A175ACDCE5D0F127FA99871052D2E5FDA6B0B439FFBF27B7E6FEF734
        3EABD37318B22415B4B2EE3D701C8611933FD1A75540BE115D75C109FDEC3FDC
        71AA59FC785E2BA1D33E70782A915B9172EE92BD068430E21F721FE61CEBC3FD
        0484B008AB9A255FCA39DF7BF3CEF7E25C869CFF1F7F314C36EAACCB15BF2F77
        3F593CBBE23E186EA115905F401606D2565A9EBCA472F5CCD161E9EE818FD042
        33BBA032EF0915B7F037B6B22FE7276409999FDB7DAFE731846CE69282CAF7BB
        FD4E5D2E809C536100000337494441543AE761B159BBBB74188F696537EA611E
        C3F2D4ECC2350CF1832BB59A18F1F90807DCBD6E0A29D2C3B2DDA5A5C6A1AF1D
        927184C5385196FCF95236A00313A4845642710296D08288FF38E45B5C1AC50F
        DD9985B4EC21B351D16F8B3F9ED7F7EE3620B45A0669F2B345C1272CB01AC8F2
        E78220195688B6FD4E16FF420759A3DF1252AEB712A4CC4EAE6F25CC4DE3D7B5
        A6601706FEE48D1D161786DDC4D5D3CFCBEB57F6B2B54BA1B6F00E87C1EC7FBF
        ED9EF0BE887E53A88514EF0B4962DA2F0BDEAFD2DCDA2E096A4FCB9FD3E9EFCE
        4DA796C60FB4BDDB2F34F9739741F7BA45697CA3B1039E222442296E96F71710
        826A9ABC736005394DF614E5531C7892D5347938EF78BD048495C705920FB6FB
        CE623ABACF0C30207C3A74F554079EA6F5D69F34B9F7600584D631425EC6BC41
        C6CE2BE71DA1ABB2D2251CDCD4E5E4DB4549487A0D088B8397B94DF9BC632E3C
        168D6FEC3FC8C537F6BA168211B1D894BDBE9F4ABBD28B5A5AEBF17BB9CBB552
        BA25EF0EE30B87EA452DD534FEC7959EB4F41A10565C00569040B695EA6D2EFE
        C5DC558BC50135BC39EA0DDDBE1886111606A642E52BCC96FCD4ED4BD52CFEFD
        90CCA3A303CCCE1E16264685B9052BA5265F7C4CF73BDDBE54A4FB8010EF6EAD
        024C930F87F7236C99DBF5FC4E8ED34F40289C42BE1004DF55F4DD10304292D9
        C53190FC209E268FB55E1F97C66F0A4F2C3A3D87F034C75C33F53D0B998FA72F
        0C23DDAD35FEE165AC597251A87445037B5DBDA474E1452EAF6FBDEC359BB978
        3C8B7FD49B853A17A63F2FBC9037BE20B41E42B6EC90053BB4C83C5204000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        000000000000000000000000000000000000000000000000000000000000C646
        D4FF03979A4AFC98A86FBD0000000049454E44AE426082
}
      Align = alClient
      Properties.FitMode = ifmProportionalStretch
      Properties.ReadOnly = True
      Style.BorderStyle = ebsNone
      Style.HotTrack = False
      TabStop = False
      Transparent = True
      TabOrder = 0
      Height = 680
      Width = 65
    end
  end
  object dsFormasPago: TDataSource
    Left = 472
    Top = 512
  end
  object alFaseCobro: TActionList
    Left = 304
    Top = 328
    object actSalir: TAction
      Caption = 'Salir'
      ShortCut = 27
      OnExecute = actSalirExecute
    end
    object actRellenar: TAction
      Caption = 'Rellenar'
      ShortCut = 114
      OnExecute = actRellenarExecute
    end
    object actBuscarVale: TAction
      Caption = 'BuscarVale'
      ShortCut = 117
      OnExecute = actBuscarValeExecute
    end
    object actSinTicket: TAction
      Caption = 'SinTicket'
      ShortCut = 122
      OnExecute = actSinTicketExecute
    end
    object actConTicket: TAction
      Caption = 'ConTicket'
      ShortCut = 123
      OnExecute = actConTicketExecute
    end
    object actSinPrecios: TAction
      Caption = 'SinPrecios'
      ShortCut = 121
      OnExecute = actSinPreciosExecute
    end
    object actDepositoCliente: TAction
      Caption = 'DepositoCliente'
      ShortCut = 118
      OnExecute = actDepositoClienteExecute
    end
    object actFactura: TAction
      Caption = 'Borrador'
      ShortCut = 119
      OnExecute = actFacturaExecute
    end
  end
  object styRepoCobro: TcxStyleRepository
    PixelsPerInch = 96
    object styCobroLine: TcxStyle
      AssignedValues = [svColor, svTextColor]
      Color = clSkyBlue
      TextColorType = AlphaColor
      TextColorValue = -16744448
    end
  end
end
