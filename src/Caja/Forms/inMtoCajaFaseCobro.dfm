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
        010400000AA008060000004E824D08000095DD49444154789CEDDD07985CD579
        F0F177766767AB7AA3480249081012022454404834D3C16063071B3BC63D7149
        8CEDB8E0E016773B7189E3F8B3E35EE8BDA302EA5D4802A18E90847A2FDBDB7C
        CF7B66E7D522EDAE7667EE9DB977E6FF7B1EC51142B3C3ECCC7FEF3DF7DC7322
        B13167C7050044A48057014012410060080200431000188200C0100400862000
        300401802108000C410060080200431000188200C01004008620003004018021
        08000C410060080200431000188200C0100400862000300401802108000C4100
        60080200431000188200C0100400862000300401802108000C41006008020043
        1000188200C0100400262A9163BF0190DF38420060080200431000188200C010
        0400862000300401802108000C410060080200431000188200C0100400862000
        300401802108000C410060080200431000188200C01004008620003004018021
        08000C410060A2C2D64D005A708400C0100400862000300401802108000C4100
        60080200431000188200C0100400862000300401802108000C41006008020043
        1000188200C0100400862000300401802108000C410060080200431000188200
        C0100400862000300401802108000C410060A29213222DFF1B6FF58F2222D142
        915854E2455191C2028914168814EABF5B205290FC3B401B9AF5BDD42CD21497
        7893FE6FB3441A1A45EA1B451A9B44E2F18EDF7F2115F220445ABE092DDF88C2
        4291E22291922289C7A22D0188BA3624FEB5F8B15F40470A222291A848342211
        7D0325DF434D8D2E10110D436D83485D834853531BEFC9708A863E04FAFF96C4
        245E5E22118D415151E2DFD0AA37378B3436B6FA6B1C15A00BE26DFC00894424
        A2EFB1926291EE22D2D020F1BA068954D58AD4D6B7FA77C319866878431011A9
        28917859A9444A8A129FF5C66691FA86B77FF88900D27EDB45DEFE7BFD41933C
        2A2828904845A94879A9C46B1B24525D2352591BDA30842808AD5ED88A528957
        942542A0DF1C3DB773FF8A1EDA7114804CBC1D2389FFD50FBE9E3EE83F2A8E8A
        94F690787999442AAB452A6B5ADEB3E1894234142FBCAB6D3C313ED0AB42A4B4
        5822763440041080F7A8D2F7A43449A4A850A45F0F77042B072B13E30C6F7B2F
        0757F083A02FA0BE903DCB45BA9525FE9986204E0810309196FFE3C6AF9A4462
        4522037A891CAD16395415F8188423085ADB3EDDDD5181D4E9A1594B20383340
        D0C3D0A8E30CFAC3AC227174BBFF884843EB2B12C113EC894965C589C216C712
        875DFA42334680B088B4FCE0D2F7AEBE87F5BDACEFE9000B6E1074E4B65FCF44
        6175D0901020AC222DEF617D2FEB7B5ADFDB0115C820C4BB97255E387D1175C6
        183140D8452289F7B2BEA7FBF54CBCC70328706308FA424574CCA0BE9E102037
        C716EAEBDD7BDC5D903C522D4112AC23848A5289F4E971EC7222909322EE3DEE
        DEEB013B7D084E10F42A425F8D413D31401E8824DEEBFA9ED7F77E40643708C9
        B101BD1B514F13F4BE039D5F00E483B85E9A6C4CBCF7F533A0B23C5E96DD20B8
        93A888C47B777373C2130388597D4640E6E87B5DDFF3050589CF809BC928F91A
        8496F9DD3A8858569228255713906F2289A304F71970571E92F73EE455101231
        88EBD4CE1EE55C51407E8BB48C27F4284F7C26B21885EC04C1CD3894C4FD092A
        F853BC017F253F03FA99487E3EF22608F1B8C4CB8B25525E92B8AF9C5305E4BB
        88DE14D5E43E13FAD9C8D68D50D93B42282F6BB95D9451442041C7139A139F8D
        2C7D2CA259F9C2BADC99DEE4C10424E0ED9A9B129F0D3D7AD665D972FE0841AF
        AC949726EE1967EC00783BB7906B73E23392851FD6990F42714C2225B1C4BDE2
        8C1D006D5C866C4A7C46F496E9DC0D422277719DA6C9022740FB5AD6FD709F15
        FB073917847862B394523D3A68B9371C401B5A262BE96745F716C9E0B975664F
        1974D285FE0AC1DA724056E96724F979C9A0CC0641D795A30540E7C45B3E33B9
        3A8610D7FF38DD47813B1A818EE967A4B939F199C9C9318468A144F48E46BDDC
        C8F001D031FD8CE81E92FA99D14D8B732E08B1C2C47F18E30740E7E867C5ED60
        9E83418847A3CC3B00BA4A2F3FEA6727E78E1074C3158E0E80AED1CF8C7E7672
        2E08051A84EC2F11058446A4650525FDECE45A102205C1DFE812089C783CF1D9
        C9B92304B748124100BABED9B1E4E2294370567C0742A520831FD38C7D250081
        47100018820020B89BBD02BE9D867B3DA61D498CF9E5D258394140CED30F6C6D
        B50FA3F571914834925377F41304E4FAA648D2B347443EFF9572298E45DCCDB6
        5E88C7458A8B45366D6E925FFFAE460A73240A040139CBDD5C5B13978957C7E4
        FA49C572A421EEC915BC88249604ED198BC8CA55D5D2581B97A2E288DB6224EC
        080272961E0D141447E4EA29311783AA2A6F82903CFAD8561597175FAA9782E2
        C4D7CA050401394967FBD6D5C6E5ACB3A232724454EAEAE2E2D54D83CDBA974A
        794466CFAB979DDB9BA4A4DCBB53916CCBD92014442212C9F08D547A0AD91CF2
        774644225290C1B9F37EBD6E9102917883C8E59716497959440E1D8E4BA147F7
        08C55BFE77FAACFAC4C0620EDDAF979B418844A4B6AE4EA4495777CEA0820229
        2E2995788847979AE24D5297E91D832205122B29F1F4217530B1AC6744265F1A
        93DA3AEF4E15E23A981813D9B6BD5996AD6C9068496E8C1DE46C10F4A8A0B9A1
        41460E1926A7F7EED772C775240337A044E44855A52CD9B0460A4378DF46A4E5
        A774B7B2321977C1B8CC6C49DE72E3CED1EA6A59B27EB51478F4BAE99140CDD1
        B88C1B13933307154AA5876307CDCD22A5251199BFB84E2A0FC4A5B407410834
        7D53D5D5D5CA9861E7C85FBEF8AD8C7EEDDAFA3A19F6B1DB65D7C17D52142D0A
        D591426161A1D4551E95F75EF74EF9CD67BF9AD1AFFD7F2F3E290B562C91B21E
        3DA5D1831FB7C9975D0713BDFE5950502052531B9797E6D44B24472E35B616BE
        1F6527A13FE50A4BCBE4C985B365C7817DD21C6F96A6A626F7CF7DFB156F9686
        C646298915CB55175C2CCD3535A13B4A70F12A28909BC74F72FF4DF58D8DFEBE
        66CDCDEEC3DFD4DC2CBF7FF129D1113F2F02AA01A8AF1739E5F442B9F8A222A9
        AEF1FEE860CDFA2659BFA1498A4A72673031295CEFDA4ED037557151911C39B0
        4F9E593447229182C4A2330505FEFD8A14B8D392B8C4E5E6099725D6C193F0D0
        E75ED7502FA79D7ABA5C3E6A8CFB6F2A2A2CF4F535D353856861A1ACDBB64596
        6F5C234525A52E0EE9D2876EAE8DCBA40945D2BB5724B1499897AB991589CC9A
        5B2F4DB5F1C4A64A392607FF935A7EDA1546E581D9D3DD59702646CDF5884047
        E8AFB970BCF4ED7F8AD4D5D767FC2A473ACFBDB9B6562E1F7591742F2B771F4C
        BF9F7B737322990FCF9D21F595952E405ED055FE75A0EFCAC931696CF0EE0A40
        5C97052D12D97FA059E62D6E90821C3C3AC8D920E81BBAA8B44C16AC5E29EBB7
        6F753FC1FDBE1CA81F20FDBABDBB7597ABF5B4A1B6C67DDD30481EAADF36F172
        F7C6CFC4D8878B5073B33BB593584C9A3DF89A7A74D050139773CE2E9473CF2A
        74E7FA5E9F2E2C59DE28BBB637E953CEB9F103158E776C0AF4274EEDD123F2F0
        DC97DCEFBD78C39D8C7E90F4ABDC32FEB2C45A7891B09C2E3448DF7E03E4EA8B
        C6B9232ABFC73F9247207A4566E5C6B5EE52AD17C1766B92368A3B3A282EF6F6
        2778A4E594E1E539F5F6FB5C94B341D043D248ACD81D92EAE0552606F912A70D
        22575F384E7AF6E9E73E687A1A1164EEE8A9AE56269D375AFA74EB9191D385E4
        11C8E3F367BA5315AFBE370D0D22DDFA14C8A4F13ECC3D2816D9B2AD4996BFD6
        20D1D2DC3C5DC8ED20C49BDD6497D736AE93651BD7DA21BDEF73209A9BE5945E
        7DE4F2F32F92263D6D08F8D506F7D96F6E96775D7245E64E170A0BDC20E6130B
        674BA4B8C493A3031DE06BAC89CBB88BA272FA6905EE4A83575D6B6E1629298E
        C89C050D527D282E45D1DCDDB338D8EF562FCE53EB6BE58159D3DCEF33F166D7
        5313FD2AEFBAF44AF74E0AF269833E35BDBC58D1B3B73BAA490CC066E0744122
        B268DDEBB26EF346292E29F1E474CE3D42A1CE3D28F6FCDCBEB050A4AA3A2E33
        E7D64B24963B3732E55D10F4274FA4B8549E58384B6AEAEADC652EBF93A01F28
        FD60BDE3827152D1ABB7D4373406F66A833ED7C6DA1AB96CE40532B06F7F779A
        A5F780F82BF11D7870F63437BFD88BAFE7E61ED4890C1A5C28178C8AFA3298F8
        FADA46796353A3C48A23393998981F4188C7A5A4B858366FDB22335F7BC5FDB3
        A6667F279EEB1B5C4F574EEFDB4F268D182D8D757AB521984170A16A6C945B74
        EE44CB69969FF408ADB0A0D0C5F999C5F3A5A0A4C4BBB9077571997269CC2D86
        E2F5DC83C2421D4C6C90E6FADCDF4D20C7FFF35ADEF4CD4D72DFCC1713BFCFC0
        205FF21AFBBB2EBDC2DD6015C423047D1D1A9A1AA5B4474FB976CC44F7CFFC9E
        AFA1476CFACACC7875A96CDDB1558A637A789FFE8F5B9DED1C2B8FC8944B8A12
        63071E0E26C662227BF635CB8225F55298A3730FF22A08FA13A8B0A44C5E58B6
        500E1C3DE2C615FC1E4B489E87DF38EE52E9D6AB8F3B4F0FDA60827EF81B6A6A
        64DCD9E7C959A70E744753BECF9BD05BD27532D29CE9EE53EC4528F5A5AEAF8D
        BB350F860F2D4C5C5D88783CF7E09506D9B7BB3967E71EE45510DC54E6584CF6
        EDDD29CF2E99E77E42F97DB52171DA1097417D07C8C5C3CF73E7E985010B42F2
        74E1868B2F75BFF77BE256E274A1400E561E95175F592405A5659E7C1FDCCBDA
        2472F5E531292AF278EE4124B154DACB73F5B023F76390174150EE1B192990FB
        674D4D8CA467E0C399FC80BD73E264F7C10BDA6983CECD28AEE896787E19784D
        921FFEA9AF2C92DDBB7648492C96F6915AF246A65EFD0A64C2D8224F0713E371
        919292885B4475E56B8D39792353DE06A1B9B949A2A56532E7B55764CB9E5DEE
        90DEEF01B4E4F9B8CE5A2CEDDED3DD0D1914FADF5F5F572BE70F192EE70D1AE2
        3E987E5F6E4C06F191798999A35EFCB4758BA8D6C6E5927145724A7FEFE71E14
        C744E62CA897DAA3DE2DBF16747911047DEFC5A251A93C74501E9BF7F2DB06FE
        7C9D01188FCBB05307CAF873464A439D7733F2D2E58E06EAEBE5A6F193DCEFFD
        3E85D2D741FFDB771F3A20D3962F72B7A76BA4D37EDC66DD17213155590716BD
        3CC8292C14A9AC8CCBECF90D12F170F9F6A00BC63B3403DCE16951913C347746
        E25252063E9CC9D3861B2EBEC4CDAB0DCA698306A0A0A4546E999099D385E4D5
        85E796CC97C3FBF7B9DBD3E35E0C26D6C565D8B0A89C7F9E0F730F4A23F2EAEA
        4679F3CD468995E4C7F8415E05413F04B1923259B6EE757975F3069B669C91D3
        860993255651E1CEDB23015951EADC3386CAE833CF726B38F87DBAE016BC1591
        077432924E0EF368219478BDC8944B8BA4A2DCDB65CCE2EE0786C88CD9F5EE66
        A90CAF399B55791304152D2C9086EA2A7970F6F48CDC01A9A70DFAE61F31E84C
        193BFC3CA9AFAD9148964F1BDCD1405D9D1BDB288A46A5491710F0918ED56870
        74EC66FEEB2B25EAD19D8D3A2453D23D22974D8CE97F8EA78389B198C8AE3DCD
        B27859435ECC3DC8DB2024A63297C863F35F767722EA4D367E4BDE3D78B3DE12
        DDD090F5598B89BB40636E8E84CAD442284FCC9F2995870EB8B11C2F4E171A6A
        E372D1E8A80C3D2331F720E2F1DC83454B1BE4E0DEE69CDAB7B133F22B083A27
        A1A444D66D7E43E6AF79D5CDD6CBC41D90C97104BDD2D198C51F371AA3BAFA5A
        396BD01037D099FC67BE7ECD961FDD8F2F98E5C670BC3A5DD0AA5C7959B11414
        7AFB812DD0B1890691E9B3EBDDCD5279D482FC0B827D001A1BE5FE99535BFE89
        BFDFF2E4CCC80B860C97F3879DED4E1BB2B592927E38E3B5B5F28E0BC7494951
        2C31A6E16310F4884C5FEF356F6D96856B5E959807EB26B69CF1C880D30A64DC
        98A8D4D478B7014BB3CE3D288EC8C64D8DB27A8D0E26E6D7E9425E06C18DB097
        96CA334BE6C9D1EA2A77B38DDF5399DDD72C289077EAA87E7D7DC677464A7263
        26D1A84D46F2FBEC253946F3E4C259525779C4DD6DEAD522AA978C8B49DF3E05
        6E5114AFC49B13E307B31734487D9577A10993BC0B426255E698ECDCB95D5E5C
        BE28635399958E23E8E53EBFBF5EBB4BA5D5D7C9A0D306C9E49117259E97CF03
        9C7A74A4FFAD6E19BB58B12783B8FAD21596885C35B9C8D3455455342A72F848
        5CE6CCD70D5CF3EFE8202F8390903809D53B2023191858D32B0BFA51B860E870
        77B94F670966FAB4C19DBAD4D6CA95A3C748B9DE76EC2E81467C1F4C7D75F346
        B76E62CC83AB0BC91B99CE1E1E9511E7F8B3EEC18AD71A64EB9626ED575E0D26
        E67510DC662E6565F2D28AA5B2F3E0FEC4CA4A3E7EF7DDFD374D4D525418751B
        A1C4EBEA32BFA16ACB462CBA549A3D29BFBF9E883C347BBA34D5D448D4834FAE
        9B7BD02072C5A498FBF07AFA13BC65D3D697E63488E80CC83C9A7B20F91E049D
        8C531C2D92C307F6CA933AFA9D81BBFD924721FA812C28F66661905456569E32
        AAE574C1E72314BDA4AB83964F26D74D4CF746A69645542B7A17C86513BDBF91
        498F0876EC6A96A5CB138BA8E6D206AE5D919741387E33974C9D4FABB1679D2B
        670D3A43EAEBEB323627C1DD57515B23578D1EEBF68DF07B65E5E4BA890BD7AD
        92755BDE905871B127A70B8DB571197B4154069D5EE8CB22AAF31737C8E17DCD
        6E43967C95B741486EE6A297C3743BB1E4D2677ED29F983A3BF0FA3197485CC7
        1132346B31F1C189CBAD13A7646465E5D6A70BCD75759EDC37E21EB120B1EE81
        FB6F10EFE8D3ABABD70D5CEBDC7EE8F9387620F91E84E4662E75478FC8437366
        64E40EC8E44FE5774FBA4224EACD6E4527FD9A22EE74A147EF7E72E50517FBBE
        B2B2FE17E9E5C5EABA3A7976C97C89783098985C44F5F48185326674CBDC030F
        071375DD83F51B9B64EDBA2689E5F09E0B9D91D741486EE6F2E8FC97134BAD65
        E8B461E2B9A3E4ACC143DC4D46999829A8FB434C1979A19CDAAB8F4D16F24BF2
        B6E639AB96CBA6AD6FBA456ED30D9F2DA27A4991F4EC51E0F922AA3A3D595745
        6AF430346195D7FFF9AD377359B27E75463673712B1515C5E49A0BC765E4B4C1
        1D953435B97B17F463E9FF514922367A9BB9C4BD9909A9037C456511B97C52CC
        4D2BF6723C54E71E1C381497B98B121BB8E6F3E982E47B1094BBE458A79BB924
        A632FB7D7E9DFC78B8D98285519F2F7746121BB1F4EA23378E9BE4FFE942CB42
        2887AB2BE5B925F33C998495BC91E9BC73A3327C58546AF5EA8287838965A511
        79654583EC7CABC90D266A7CF45B92EEAFB09E76E47D10925399755BB1AABADA
        C4662E3E7E48931FC8C9A32E92C1A70F72B307FD1AF1D7B90EBAC0EBF8B3CF93
        C1FD06B4ACACECEFD5057DE55E5EB94C76EDDEE98E84BC583731DE2472D59498
        3BB4F7FA83A68F37735EBD9BA61C8D7AF34B1F4BAF5A84712E439EAC1477B255
        998B65CBB6AD32F3D56572D3B849EE8DEDC5BCFBB6B8D392A626292F2E91EBC7
        4C94DF3EF180141697B853093FBE969E70DF9CDC8845E3E7E3047DFD7AFA1970
        7B60E8EED769CE7E7283890D223DFB15B87513BD9C7BA0F4B1AA6BE2F2910F94
        CA5DEF2FB5BB28D33EEA288BC8AAD58DF2C39F554961C86E9FCEFB201CBF998B
        06C1F7DD8F5B1E5ED734FCED530FF9F68669D0F18A6EDDE5A6718920F8797490
        3C5DD877E490BCF4EA3229D4D385342FE3BA45542BE332614A4C4E195020478E
        787FC391BE24A79FAADBEF45DC84B5341FCDBD0E7A74F0D3FFAD93C686B84463
        E11A972008C9CD5CCACAE4C55716CAFE2387A54FF71EEE1BEB571892571B2E1F
        35464E3DE534D97D60BF1479B45640EB5393DAEA6A9930F202197EDA40DF5756
        4E1E553DB3789EECDFB34BCA7AF44CFBA847AF02EB22AA7ABAA06DF1AB673AC9
        C98B990D4D4D71E9DE3D22CF4FAF93C50B1ADC8A4E611B4BC8FB3184D67740EE
        DFB35B9E5932D7F73B20930BB3F428AF906B2E1A2FCD75359E5FF27447030DF5
        6E325226AE9E24E3F9A82EB3EED68048F7F11237329D7966A18C1E197587F67E
        F54CBF9617BF8A8A448E1E8DCB5F1FAC75774B8671751582F0B69B7F0AE5FE99
        D35A46E37D3E6D68D936FEB64B2E77D7D1BC1EC86C6C39EA712B3EFB7CBA905C
        667DEBDE5D6E1C4657864A77535DFDF0EB22AA7A2353B78AE0DF5BD0D424D2AD
        3C228F3D532B6FBDD924C52589239CB021082D9AE271899696CADCD797CBE6DD
        3B6D5F05BFE807483FA253465E247DFBF6977A0F9769771BB1D4D6C8E8A167CB
        F9BAB2B2CFA70BC99988CF2E9E27950713EB26A64BB7502BE91691CB2E89B969
        C501D9D2A2835D9E44DEDCDA240F3F5EE7E64C84ED542129C02F7386C5E3EE8D
        5C75E8A0ED2EE4E71D90C9C3781DAFB872F458379BB0D0A31937C98D58AE1F7B
        892D52E2A7E4E98E5BCD3A9AFE58889B7B501397D1A3A232F4CC42A9AD0DF6ED
        C8CD71DDE529227F7EB0568E1E6AD69720540389AD118456E2FA9D2D8AC9C373
        66B8C379BFA732274F1B6E9F7465E2F7110FE756149724567AF6790118B79275
        24221B776E93456B5F93A2520FD64D740F2C72F59498443D5E44D56BCDCD2215
        651159BAA2415E7AB95E8A43707AD31182D08A5E262B2E2D9557D6AF96959BD6
        FBBE994BF2B4E1EA0BC749AFBEFDA4BEA13EED9F847A74505F5727E79C3154C6
        9D3DC2F7B0254FAB748BBCDAA347DC0D63E948CE3DE87B6A818CBBA8C8D7C144
        2F44746678B3C81FEFAB755719827C24D319017EA9B3433F3C8D35D5F2C0AC69
        EEF7BE4E2D6E094EDFEE3DE5B2F32E90A6DAF49756732B2BD7D5BA7B25748526
        9D04E5A7646C1ED53D338B8A3CB991A9A9262E978E8F49FF7E89455483FA216B
        D281C48A884C9F5927AF2E6F9092F2F08E1D241184B60E814B4ADC54E6FAC686
        C454661FBF01C90FD0BB2FBDD21D7FA67B78EF9E7F2C26B75D9A582ACDCF0F53
        F27461E5A60DB27CC31A8995A67FABB3FE75BD6477E56545EEAEC6A0C620AE67
        9751914387E3F297076AA5309658B539EC08425B9BB914EB662E1B65EEEB2B13
        FFCC839D8A4FF613F6FAB113A5679F7E6EED8254A7FC26964AAB97C1A70E9409
        C98D583270BAA047070DD59552A4BBA678B088EAF0E18532F2DCA8547B3C55D9
        4BCDCD22E5E51179E4A95AD9BEB9C9EDE110E4B18ECE0AE8CB1D8CCD5CDC9C7C
        9FB9D38678B39CD2AB8F4C3CF77C77B521D53910C99595AFBD68BC9415FBBFB2
        B2AE9BD8D0D8284F2C9CE5D64D6C4AF3C27BEB4554F52E441F3BECC965C6CD5B
        9BE4D1A76AA5A822FCA70A4904A1833B2075C59FC35595BE6FE6A20BB5C493B7
        44A7B19B5272656537D949F978B89D5C3771C9C635B2EA8DF5EEA82ADD25E81A
        1A45CA7A4464D2F8C48D4C2E10E9DE8A2CDE6B6E4E5C66FCCB83B5527928EEEE
        70CC85A30345103A98CABC6BD77679F19545EE9FF9792D5F0FEBF5B3AB375655
        F4EAEDD630E86A14922B2B9F32E034B9F4BC0B7C5F5939DEEAEA425C178C4DF3
        D85E572AD2158BC68D2992216716BAF183E4ADC469FD2AF0E13263794496AD68
        94192FD785FE32E3F10A3C9BC87DB25FA1A3CF5BE4BE592FFA7E2D3FB9C0ABAE
        59A01F665DC3A0AB538DDD422FB5D56EDFC69EE515BEAEAC9C5C37B1B6A1DE6D
        E2AA83B0E90E26EA636ABF264D2892EAEA78E2578D37BFBC14D1B3C92691DFFD
        ADC68520636FED0C7D4EB9DBB11D3A90585852262FAF582A3B0EEC95D37AF7F3
        7581113D6DD03139DDC865EABC9753FC3047DC2DD57EAFACEC5E9B824299B77A
        A56C7A6B8B949495797275A1A83422BFFB6BADFB95EEC1BE1E19D4568B8C1D53
        245FFB62B95B9835DD01CAA626911EDD23F2F40B75B26A65CBDD8C397474A008
        423BF4ED585C5424470EEC932716CC964FDF74BBAF0B8C2443A3D38D4BBAF770
        6B197436097A2EAF5717FAF41B20EFB870BCFB7B7ECFB2546EAE466343E208C7
        8B078C8BECDBEFCDA9997E9B1A0EC765E069056EA5A5EA6A0F2E3316891C3CD4
        2C7F7D482F33EA1A1A92731843E880FB295B54240FCC4E4C52F2F343E62614C5
        E332FCB44132FE9C91D25053DDE9AFE75656AE49ACACDCB77B0F7F4F17DC9D8D
        855259532D2F2C5BE8F9E6B5FAA1F3E29706A1A05CDCFD105ECC6768D6CB8C65
        1179E8C93AD9B9552F3386F36EC693210827DBCCA5A45416AF794DD6BCB5D9F7
        A9CCC90FD6BBF42A41170616134B7FC5DD52697E9F2E24D74D9CB67CB16CDBBE
        558A63E9AF9BD89A170B9C2A9DFEDCBB4F819C31A8D0DD2D99CEF86ABCE532E3
        A6CD4DF2B85E66CC811989ED21089DD9CCA5F2A83C3467BAEF539993F30FAE1B
        7B89C42ABA756AC5218D86CEA8ECDEAB8F3BDDF07B65E5E4BA898FCD7FD97E1F
        346E45BCFAB80C3BB350FAF44AECE310F1E86EC6AA23B97599F17804E1245C00
        8A8BE5D17933DDA21FBE9E36B4ACC170EEC033E4A2B3CE957ABDB7E1245F4FCF
        DF1B6B6BDDCCC4D37AF7F575E0B3F5BA897ABAE0D64D0CE08F4AF79FDF246EB6
        63BA1FDEE696BB1917BFD2202FCFCCBDCB8CC7230827A1A7083AE9E6F54DEB64
        D1BAD77D5F8E2C797FC06D13A7B825D04EF6E14E6CC4D228EF6AB9772113A734
        D35E592CFBF6ECF2FC74C12BFA3423B14410D21D3F88B8CB8C71F9E37D35BEAE
        EB181404A1B3D7F8EBEBE4FE963B20D35F9DF7E4A70DB74C982C45E515273D6D
        D0494C25DD7AC875632626FEBE8FEFD8E4E9811B646D19040D1AB79464A3489F
        BE0572E6E0F4C60F9A5AEE669CFA52BDAC5AD928C5393C769044103A3B95B9A4
        549E5E3457AA7533171FA732EB69833EF6B983CE9451679E25F51D6CF7E66ED5
        AEAB95F1678F94A1A79E9E385DF0E9942679BAB0F3C03E99F9DA3289EA26AE01
        0D4272FCA0773AE307F1C4D50ADDE62D79993117EE663C1982D0A5CD5C36CB8C
        954B337268AE1F3EB7C14A7DFBA70DEE27764383AD8CE4F773D28FFF930B67CB
        9103FB25E6F1B2F17E8C1FE8EDC9A93EC5A6E465C6276AED326300FF733D4710
        3AC98DADC7E3C7EE80CCC0A1B9DEA49458C1B8ED0F7A6353B33BADB8619CFF2B
        2BEB6347920BA1F8BCDD5DFAE30791B4C60FE27191D212918D9B72FF32E3F108
        42577E6A9796CAD45716C9DEC38712B71AFBF4A1483EF6054386CB7943CE92BA
        365652722B2BD7D5B8AB1123070FF575656537ADBAA04036EDDA2E0B56BFEA4E
        17827A75C18D1FF489B8F1837A1D3F482108CDEE7421227F7EA046AA8FE6F665
        C6E311844ED28144BD03F2C0DEDDF2CCE2B9EE9F3565E0B4E1BA311344DCDD84
        917656569EE8FF958F9693E72716CC92AAC3073D5966DDD7F1832189F1038D43
        5783D0DC9CD85F61D1B20699353BFC8BA6761541E8027744505828F7B76C1DEF
        F70420A59713138B8F349FB0118B9E4EBC532F4FFA3C412879C4A2733174A42D
        A8A70BC7C60F8A521E3F88B8455E5B2E33C673FF32E3F108421734B74C659EF7
        FA0AD9B46B47CB6DCB3E5D6DD00FA1885C3C7C848C387398D4D51D3B6DD0FFD5
        AB0F670F1EE24E2B925700FC9C17F1FAD63765C9DAD72416D0D305154FCE3F38
        27B19E42573FCC4D4D22DDBB45E48519F5B2FAB5C69C5834B5AB084217E807B4
        281A95EAC387E4D1B9FE6EE6E27ED83535B99593AFD5D386BA63A70DEE7FEBEA
        E4C68B2F71EB12F87BBA706C219486EA2AF7F582C8FD6477E3070572E6195D1F
        3F48DECDB86F7FB3FC4D2F3316E75F0C144148E503128BC9437367F8FA93B9F5
        69804E52D20D64921F4E77376371B12D95E6EBE9426162E7A747F5DE8558B11B
        60CCC5F103BB9BF1893AD9BDAD49FF53F36620B13582D0457A44102B2E91151B
        D6C8F237129BB9F8F5133A39463169C4F9326CD019EEB4416F3DAEAFAF93A1A7
        0F96B1678D78DBBFE7D7BA89CB36AE95D7376D90625D1929A0B37392E307A352
        987FD0FA32E313CFD44AAC3CBF06125B230829D0C366DDCCE5C1D989C145BF06
        D9F43DAE5397F5EAC68D175FEA3660298A16BAFFBD41175289C5DC9FFB757C90
        FCEF7A68F6F4C4DE93415D13BDD5FD0BE79DD3F5F9076EB5A65697190B837911
        252382FB1D0EC9662EBAB069A1DBCCC5A728B4BCB3DFA9A70D8551777541FF57
        974A4BFCB9F8BA6EA2DE2BF1ECD2799EAC9BE8FFFC83C4F881BB7F21D285CB8C
        151159B8B4E53263B7FC3D3A5004218DCD5CD66FD924735E5FEE7E42FBF56149
        CE3E9C38E27C39E3F4C152537954069F3E582E3BEFC2963FF7EBEA42E253A1EB
        26AE7DF38D9665D6833F7E60EB1F743208FAEF6940FEF0F79AC442AF92DF0842
        9A9BB9DC3F3371DAE0D70D9089318A26A92829951B2EBE44E4D001B7114B45CB
        2ECBFE2D9596F8DF47F46A4AE3C96FC30EE3FA07C9CB8CCF4FAF97B5AB1AA5B8
        2C3FAF2CB44610D2DCCCE5B9650B129BB9F839BFBFE561DF7DE915122F8AD9E9
        825F5F2F79BA505953234F2F9EEBEEF40CEAE9C2DBC60FBA70FF42F232E3DE7D
        CDF2F7876B24AA5BB13567E2D9061B4148F30EC85D3BB7CBF3CB16B80F91DF57
        1BF4AAC2B9A32E92492346BBDFFB37192971BA306BD52BF2D60E5D37B138D0A7
        0B89F1834219925CFF20D2F9CB8C0F3C5E2B7BB6374B519E5E663C1E41485724
        E24E1BDC5A863E1D56274F0B7A77EB2EDFBFEB9FA54FB71E6FFBE73E7C45F77F
        DD14ED66FD8005FB74A1F5FC03DD44E5644F57A75294968AAC7FA3499E7AB6CE
        5D66CCB5FD15524510D2D0DC723FC1CBAF2E95EDFBF7BA9FE47EFF247DD72557
        F87A0F4572B2D5A1AA4A99BE7CB114949C781F4530C70F0A13F30F3AF354DD56
        EE11F9D3FD35525399B8CCC8C141024148F3C3A377FE1D3DB05F1E9F3FD3FD33
        BFCFB5FDBEB128B910CA8BCB16C8EEDD3BA5B8A838B03733A5B27E62726FC605
        4B1A64CE5C2E331E8F2078B6994B6299763F7F7A2BBF0FDF93CBAC3F346746CB
        3F90C06A3D7EE0D63F6838F9F881DE06A2F739E8DD8CEE3132F35443832078F0
        1355EF00D43B01576F7D33710764800FB13BB56EE2C1FDF2F2CAA552589AFE9E
        8D99193F2848DCBFD0D0F111825B34B55B449E6BB9CC58C265C61310040FB819
        7D55956E8AAF0AEA88FCC924C70A9E5B324F0EEEDBE3F6B60CF2E94257D64F74
        F7A41589ECD1CB8C0FD5486109730EDA4210BC9ACAAC9BB9CC7FD9DD5BA03720
        05F763D4BEE4EDD50FEBE942341AE8187475FC40FFDDB2B288DCFF68ADECD9A1
        37A87199B12D04C1037A44A07740BEFEE60659B86E55E25036C087DA6D49ECF8
        54209B77EF94D9AB960776DDC48EF65F686FF846FF334A4B23B27643A33CFD5C
        9DC4F26C59B4AE20085E2E33A69BB9B44C650EFA4FD7E32503F6F4A2395273E4
        5060D74D3C71FF85A8DDBFD09168A1C89FEEAF95DAEAB8DB191A6D23081E7EA0
        748AEF334BE64A556D8D1B5708531292B31E1FD44D6DA3C11E3B78FBFA07851D
        DEBF90BCCC387F7183CC9B977F8BA6761541F0F20EC858B16CDDB655A6AF58E2
        62909C021C74C97513D76EDB224BD7AD0EF4BA89C7EFBF70B2FB17B47375752D
        9719235C663C1982E0F51C8178DC4DF98D84E82A77F2AAC8237367485DE591C0
        AE9B98D4B26195EDBFD0DEFD0BC9BD199F995A27EB577337636710041F367399
        B67CB1EC397CD0D7CD5C3CDFCC361E770BBEE87A91415D37F16DE3070DADEE5F
        68E308A165E94BD9BDB759EE7BA456A2A5DCCDD81904C1EB3B20DD662EBBE499
        4573DC3F0BFAA177724D855736AE95E5EBD748B1DBC435D8CFB933EB27BACB8C
        A511B9FFB15AD9B7B359D7A8E56EC64E2008BE6CE612B5ADE3FD9ECA9CAEE411
        CCE30B664973C0D74D6CFD612FE860FDC4440C44D66E689267B8CCD825C1FFEE
        878CFEC42D2A29739BB9BCB1735BA0A7326B0A746197FAC606777396EE1015D4
        E77AFCFC83DEC9FD17DAB97FA1B030E20612DD6546DEE59DC64BE5035D19B9E6
        C8E1C4F263019ECAECAE2E88C892F5AB65EDE68D815E37F1C4FB17A26DDEBFA0
        038915151199B3207199B1442F3306BB718142107CDDCCE525F7FF07F5303C79
        BAF0C0AC69126F68386143D950AC7F705CBFF402496D4DDCAD75E0D3FAB3398D
        97CCAFCD5C4A4AE5D50D6BDC609DDFBB33A742978DD7CB8B35F575F2CC9279A1
        385D78FBFE8D278E1F242F333EFD629D6C5CCBDD8CA920083E89161448636D8D
        FBE9AB8276F9513FFCFA8C66BEBA4C366FDB22C5C5C15D37B133FB37262F33EE
        DCDDEC6E60D2CB8C21E85BE010049F37737972916EE6521FB8A9CC71B7499BDE
        D9F892FBD11AE465D6DBDB7FA1F5FE8D7699F1D15AD9BF8BCB8CA922083ED19F
        B625C525B271CB9B32EBB5E52D539983F1234B8F56F408E660E551B762B44EA6
        0ADA294DC7E307456FBB7F211983D5EB1AE5D917B89B311D04C1EFA9CC4D8DAD
        A6320743F2C3FFD2CA25B26BD77689057CDDC4E3E71FE880E2F1E3073A98F8A7
        FB6AA5AE86CB8CE9200819D8CC457F0A1FAA3A1A98A9CCC975191F6EB92C1AA8
        5A9DE4FE0537FF60F0B1F103BDA4A803897316D6CBFC855C664C1741C8C0662E
        BB77ED90E796CC77FF2CDB87E6C97513F71E3E28535F5914F875134FB87FE1CC
        96F9072D47083AE9A8462F33DE57EB1650457A0882DFDC0EA2117930B92A7396
        07EF92CBAC3FB774BE1CDC1FFC75134FB87F61C4B1F907C9CB8C4FB55C66646F
        C6F411049FE99A086E3397954BE5AD7DBB33B2994B4774F2917EB61E9C355D74
        E64E1862D0D6FE8DAA3826B26357B3DCF7309719BD42107CA61F37B799CBC1CC
        6DE672B27513DFDABB5BE6AE5EE14215F4B907AA65A36DDBBF51EF5FD0A7ADEB
        24FEFD915A39B887CB8C5E210819E03E744545C74E1BB234953919A22716CE72
        BB4D69A8C27084E0060F5BF65FE8D5AB40EAEA45CACB23B26A4DA33CFF229719
        BD441032389579E9BAD765D5964D893B20B3B0E64032448FCF9F158A65D63B5A
        FF400710F56EC6FA5A164DF51241C8F8662E89A9CC995E954803A4215AB76DAB
        CC5FBD528A4ACBB27EC52395F1033D3AE85E1191D9F3EB65D1A286C4DD8CE158
        BA32140842C6377399290D4D8D6E1D824C4A06E8A985B3A4EEE811290AF8BA89
        EDEDBFD0D414979A5ABD9BB1560AC2F19F102A042193AB321797CA9A3737CAC2
        B5ABDC487F267F4227D74DD45BB2DDBA89213A5D48ECBF50283DBA1748497144
        9E7ABE4E36AD6F94626E60F25CB077E3C8317AC92FB999CBE49117BA6DDF1237
        22FB7F74A241787DCB2659B171ADC44AC271AB73EBF1035D2EAD3C1691CD3B9A
        E481C7B8CCE8178E10323E95B94C9E5E3CC7FDFF3A2948F7818CFAFC2B164D7C
        9D87E6CE90C6EA2AF7CFC222397E30E2ECA8C42222F73D5AC365461F71849041
        3AAA5F5454243BF7EF935BBEFD45E9D7BDA73B3E484C15F2F1EBB6DCAE306DC5
        62899685673031397ED0AB77815B1065D9BA0679716A3D7B33FA882064E3D6E3
        68549E5F302B31F7563FA97E9F33B47C8DC2B232290CC1366DC78F1F9CA5FB37
        F688C8377E5823F5757129659D44DF10842CD00F64697985DD7598D1FB184212
        03E55E9E7A918917C764EED20659B6B8414ABAB368AA9F08429684E5B03D9BF4
        252A2C8BC8E04105F2FBBFD54801EF56DF31A888C01E1DE826AD83CF289095AB
        1A65CDEB8D122B639D44BF110404960EB616452332EDE57A298C45D88A2D0338
        084320B9FBC162225BDE6A4A9C3AB4B38723BCC51102024D23108205A1730641
        0060080200431000188200C010040059080233F380C07F760A32BD3F01802ED0
        CF4C06E75F642C08715DC28B20005D1389243E3B3979CAE06EC365BA19D0F959
        59993D6588666CA3CF46BDF79F5306A0EBBBD4B4AC9B914B470811DD7A87A303
        A06BE2F1C46727E74E191A9A384A0052393AD0CF4ECE05A1B149E2EEB6B5828C
        8E9A02A114776BE7273E331A85DC9B981497487DA3AE452E12A1084087F43352
        5090F8CC64F0276866672AD6D7676C700408BD48CB672683321C844691FA06AE
        36009D193FD0CF8A3B42C8C920E89EDECD12AF6D703B0F339000B4279ED89D5B
        3F2B4D3A0721929B63082A52539BB8FCC83002D0B678CBE546FDACD83FC8D5BB
        1DEB1B24AE7B7A470B9997001C4F7F58460B139F113D65C8B0CC0741676356D5
        262E3F32C008BC9D7E260A0B129F9178BEAC8750532BF1EA3A91106D3A0A6444
        4161E2B361A70BF910042D5F758D4854BF3C830940829E2E14243E1B59FA5864
        27089188446AEA24EE4E1D184B0044C70E0A0BDD67423F1BD9BA11307B4708FA
        EB4875E2F78C2520DF455AFE573F13C9CF47FEACA9E8964F92484343E20588C5
        B8E280FC3E3A88C5DC67C17D26120B87E4DB22AB89284865B5C4750045272B71
        7B34F2F2326334F119A8ACCE6A0CB2BFEA72CB0A4A9183958955610A32BB7E1C
        905571FD0446DC7BDF7D06922B2465517683903C22D005200E1E4D1C25702724
        F245247174E0DEFBC94550B27C941C9C7D196AEB440E1C499C4B7198809C174F
        BCD7F53DAFEFFD80084E1054558DC40F1C1689151105E4780C8A12EFF5AA1A09
        9282C01D45556A145A8E14B8090A3978D392C462EE3DAEEFF5A0D1FB9003C7BD
        50FAE2F5EA96B8FDD32DE1CE640584583CB102929B88B7FFB04402766410D823
        04A32FD8FE4389AC16714912218F4151CB1A20FA9E0E680C821D0455532FB2EF
        9088DE0A5A5C74EC900B088378CBBA1FFADEAD6B792FEB7B3AC00279CAF036BA
        04F5DEC3223DCA452A4A13FFACA949241EC9FA355BA0FD397789750D9CC35589
        5F21B87A160DC766977191C395227AD38786A1B458A4B1391106AD02614010C4
        5BFE8F8E13E85D8BFA7ED51024173A49BE97032CF841B017B065D1C9BD8744CA
        4B255E5E2A113D146BBD6E3D038FC8E67B345AE8060EE3750D12D11F603656D0
        321D39E0310847108EBFF741FFB7AA4622D5B52265C5122F6B0983FE911E3524
        37C6240EF0F5ED184FFCAF5E3928D25BF82511826A7D6FD6BDFD0759084E1542
        1804D5EA45D6175CEF1DD73014C7245E562C119DD0E42635E938434B1C5A5799
        4820A5B75DFCEDEF2177F9B0653CBEA141E255752E02111D38B47F351982F0C4
        20844168270CB5F512A9AD4F7C933408C545122F8A4A447FEFEE8F68352924F9
        0B389948A4D5AF96F75053A3C41BF448A051A44EF74D6890885B2A3DDC210879
        10925A1F96B51C15E8404E4D9D44F49BA8033B518D436162E14A0D84D65DFF7D
        BDCB0C684FB3BEB7124799717D5F35354BC46D58DC20113D357DDB0F95E47B29
        BC21C8912024B5F14DD06F987E031B9A2412DC79200881C849FF8D7047203C13
        93006414410060080200431000188200C0100400862000300401802108000C41
        0060080200431000188200C0100400862000300401802108000C410060080200
        D3B2243100708400A0154E1900188200C0100400862000300401802108000C41
        0060080200431000188200C0100400862000300401802108000C410060080200
        431000188200C0100400862000300401802108000C4100600802001365E32600
        491C2100300401802108000C410060080200431000188200C010040086200030
        0401802108000C410060080200431000188200C0100400862000300401802108
        000C410060080200431000188200C0100400862000300401802108000C410060
        080200431000188200C0100400862000300401802108000C4100600802004310
        00188200C0100400862000300401802108000C410060080200431000188200C0
        100400862000300401802108000C410060080200431000188200C01004008620
        0030040100410070228E1000188200C0100400862000300401802108000C4100
        60080200431000188200C0100400862000300401802108000C41006008020043
        1000188200C0442572EC3700F21B4708000C410060080200431000188200C010
        0400862000300401802108000C410060080200431000188200C0100400862000
        300401802108000C410060080200431000188200C01004008620003004018021
        08004C54D8BA09400B8E1000188200C0100400862000300401802108000C4100
        60080200431000188200C0100400862000300401802108000C41006008020043
        100010040027E20801802108000C410060080200431000188200C01004008620
        00300401802108000C410060080200431000188200C010040086200030040180
        2108000C410060080200431000188200C0100400862000300401802108000C41
        0060080200431000188200C01004008620003051891CFB0D80FCC61102004310
        00188200C0100400862000300401802108000C410060080200431000188200C0
        100400862000300401802108000C410060080200431000188200C01004008620
        00300401802108000C410060080200431000188200C01004008620002008004E
        C4110200431000188200C0100400862000300401802108000C41006008020043
        1000188200C0100400862000300401802108000C410060080200431000188200
        C0100400862000300401802108000C410060080200431000188200C010040086
        2000300401802108000C410060080200431000188200C0100400862000300401
        802108000C410060080200431000188200C0100400862000300401802108004C
        54229163BF0390D738420060080200431000188200C010040086200030040180
        2108000C410060080200431000188200C01004008620002008004EC411020043
        1000188200C0100400862000300401802108000C410060080200431000188200
        C0100400862000300401802108000C410060080200431000188200C010040086
        2000300401802108000C410060080200431000188200C0100400862000300401
        802108000C410060080200431000188200C0100400862000300401802108000C
        410060080200431000188200C0100400862000300401802108000C4100600802
        00431000188200C0100400862000300401802108000C41006008020043100018
        8200C010040086200030040180894A84570340024708000C4100600802004310
        00188200C0100400862000300401802108000C410060080200431000188200C0
        100400862000300401802108000C410060080200431000188200C01004008620
        00300401802108000C410060080200431000188200C010040086200030040180
        2108000C410060080200431000188200C0100400862000300401802108000C41
        0060080200431000188200C0100400862000300401802108000C410060080200
        1315891CFB1D80BCC6110200431000188200C010040086200030040180210800
        0C410060080200431000188200C0100400862000300401802108000C41006008
        0200431000188200C0100400862000300401802108000C4100600802001365E3
        2600491C2100300401802108000C410060080200431000188200C01004008620
        00300401802108000C410060080200431000188200C010040086200030040180
        2108000C410060080200431000188200C0100400862000300401802108000C41
        0060080200431000188200C0100400862000300401802108000C410060080200
        431000188200C0100400862000300401802108000C4100600802004310001882
        00C0100400862000300401802108000C410060080200431000188200C0100400
        862000300401802108000C410060080200431000188200C01004008620003004
        01802108000C410060080200431000188200C010040086200030040180210800
        0C410060A21239F61B00F98D230400862000300401802108000C410060080200
        431000188200C0100400862000300401802108000C4100600802004310001882
        00C0100400862000300401802108000C410060080200431000188200C0100400
        262A6CDD04A0054708000C410060080200431000188200C01004008620003004
        01802108000C410060080200431000188200C010040086200030040180210800
        0C410060080200431000188200C0100400862000300401802108000C41006008
        0200431000188200C0100400862000300401802108000C410060080200431000
        188200C0100400862000300401802108000C410060080200431000188200C010
        0400862000300401802108000C4100600802001395C8B1DF00C86F1C21003004
        01802108000C410060080200431000188200C010040086200030040180210800
        0C410060080200431000188200C0100400862000300401802108000C41006008
        0200431000188200C0100400862000300401802108000C410060080200431000
        188200C0100400862000300401802108000C410060080200431000188200C010
        0400862000300401802108000C410060080200431000188200C0100400862000
        300401802108000C410060080200431000188200C01004008620003004018021
        08000C410060080200431000188200C0100400862000300401802108000C4100
        60080200431000188200C0100400862000300401802108000C41006008020013
        9548E4D8EF00E4358E1000188200C0100400862000300401802108000C410060
        080200431000188200C0100400862000300401802108000C4100600802004310
        00188200C0100400862000300401802108000C410060080200431000188200C0
        100400862000300401802108000C410060080200431000188200C0100400267A
        ECFF45BEAAE85620034F8FCA29A746A567CF42E9A1BF7A1448F7EE05122D8A48
        91FE8AEAFF8A440A22926BEEFE975DD97E0A814110F2F0C33F6244B18C181193
        734614CBA04145EEC30F288290074E39252A974C2A954B2F2D93E167C724927B
        3FE4E1118290A30A0B45265E5226B7BCB342469C579CEDA78390200839A6A040
        E4DAEB2AE4BD777497BE7D0BB3FD7410320421875C7851897CEC133D65F0E0A2
        6C3F15841441C801B158443EF2B19E72E34D15D97E2A08398290030386F7DCDB
        57CE3C93A302A48F2084989E1A7CFBBBFDA4776FC60AE00D8210527A44F0DD1F
        F4976EDD984300EFF06E0A219D48F4EFDFE84B0CE0398210C2F9055FFDF7BED2
        BF3F0777F01E4108995B6FEB26E731D1083E210821BBA2F0FE0FF4C8F6D3400E
        23082172D7477ABA3907805F0842489C3E302A975C5A9AEDA7811C471042E2DD
        B777E72E45F88E208440717144264F29CBF6D3401E200821306E7CA98B02E037
        821002932E63EC009941104260D4F925D97E0AC8130421E04E3D35EA163B0532
        81775AC09D3B82E5CF90390421E0060EE29E05640E4108386E624226118480EB
        3F802304640EEFB680EBD52B98CD6E6A12696C8C4B3C9EED67022F1184802BC9
        D284A4E666913736D6CB860DF5B2F9CD06D9B5B351F6EE6D9423479BA5AAB299
        10E428821070C525993B42D09FF62B57D4CA4B33AA64D9D25AA9AC6CCED8D746
        30108480CBD4EDCE4B16D7C8DFFE7258366F6EC8C8D74330118480ABAF8F4B49
        897F51A8AD8DCB2F7F7140E6CEA9F6ED6B203C0842C05557374B49893FCBAC1F
        3DDA2CF7DEB387A30298600E61C35457F9731EAF5708FEE35B7B8901DE862004
        5C55953FD7F5EEFFFB1159BFAEDE97C74678118480DBBDABD1F3C7DCBFAF499E
        7CE2A8E78F8BF0230801E7C7A8FF8B2F544A4303338A70228210709B377B7F58
        3F872B0A68074108B83737797B8470F06093ECD8EEFD690872034108B803079A
        648B87A70DDBDE2206681F41088105F36B3C7BAC7DFB0802DA47104260E102EF
        6611D6D4309888F64585D5BD03EFCDCD0DB2EDAD061938A8C893DDA3F99EA33D
        1C2184C4638F79336FA0B48C6F39DAC7BB232466CEAC96BD7B9BD27E9C535881
        091D200821D1D41897271E3F92F6E30C1A5C24057CD7D10EDE1A21F2FCF35569
        5F822C2D8DC8D967C73C7B4EC82D0421644709FFFDDF07DCF266E9983CA5DCAB
        A7841C43104266E3867A79E2F1F40618AFB8B24CCACAF9D6E344BC2B42E8FEFB
        0ECBDAB5A9DFE350515120EF794F374F9F1372034108E9B26ADFFFEE5ED9BD3B
        F55987B7DDD64D869DC55802DE8E2084D4E1C3CDF21FDFDE275529AEA854188D
        C857BEDA477AF6F467793684134108319DBDA8CBA0A5BA5CFA800151F9E6B7FB
        4A8F1EBC0D90C03B21E4742CE19EAFEC91FDFB539BB43474684C7EF8A3019E4C
        8B46F811841CB0756B837CF5CB7B525EE7E0B4D3A3F25F3F1D20D75D5F2111EE
        6DC96B91D815A3B9FD2D47E8A5C4CF7CB6975C765959CA8FB16E5DBDFCFDAF87
        65E5CA5A4F9F1BC28120E4A06BAF2B978F7FA29714A7B12FE41B6FD4CB8CE955
        327F7E8D1C3C90FE3D140887BC0FC2A9A7E6E65E357ACFC2D7FEBDAF27A7003A
        5D7A7DCBA6AF7BF734CA81834D52571BCF99855A77EE64D198A4BC0FC2934F0F
        B21703F9E9D65BDECAF653080C061501188200C01004008620002008004EC411
        0200431000188200C0100400862000300401802108000C410060080200431000
        188200C0100400862000300401802108000C410060080200431000188200C010
        04002637F731EB82A54B6AB2FD1480C0C8FBADDC001CC3290300431000188200
        C0100400862000300401802108000C410060A2229163BF0390D7384200600802
        00431000188200C010040026EFD74340F6154623D2AF6FA1F4EB5F28E5650552
        5C12916861446A6A9AA5AABA59AAABE3B26F5F931C3CD094EDA79AF30802B212
        808B2E2A96B1634BE4DC11C572E6994552D08963D5C3879B65F39B0DB27163BD
        2C5C58231BD6D74B3C9E89679C3F22B12B2EE0254546F4EE5D28B7BDAB42AEBE
        BA5C2ABAA57FB6BA776F93CC9D532D4F3D592907387AF0044180EF4A4A2272C7
        FBBACB2DEFAC90A222EF27C2D5D7C7E585E7ABE491878FB8A308A48E20C057E7
        9D572C5FFC526FE9DBB7D0F757BAAAAA59FEDFAF0FC9EC59D5BE7FAD5C451042
        440FB3CB4ABDBC3014973D7BFC1BA8BBF9960AF9E8C77A4AA1FF2D781B3D8DF8
        D5AF0E497515470B5DC5A062887CFEF3BDE5E271259E3DDE82F935F2C31FEC17
        3F7CE083DDE51FEEE82ED970D9E4321934B848BEFDAD7DB27F1F5726BA827908
        21A1A3F0E78D8C79F6783A3A7FDFDF8F881F74BC205B31483AE38C22F9C94FFA
        BBFF45E71184901876564CCACA0A3C3DACDEBAB541BC76E5556572E707B21B83
        A43E7D0BE53FBEDB574E398503E1CE220821317A74B1A78FF7E41395E2359D4F
        F0E9CFF49220E9D9B350BEF9ADBED2BD3B6FF5CEE0550A89F33D0CC2DAB5F5B2
        6143BD7829168BC857BEDAC7FD6FD09C767A54BE724F1F8904EFA9050E410801
        1DA5D7CB775E79E179EF8F0EDE7F6777F7C10BAA51A38AE5DDB777CBF6D3083C
        821002030715497171C4B3493C0B1778BB9FA50EDCDD7A5BF03F6C3AB6316428
        838C1D210821A0E7E65E59BCB8566A6ABC9DADFEE18FF4C8F85C835444A311F9
        E77F0ED61847D01084101832C4BB202CF2F8E840C736C68CF56E6E84DFCE1D11
        934B279566FB690416410881333D0A82CE3D58B1A256BCF4BEF705E31263577C
        E8AE701CD1640341C8A353868D1BEAE5C891664F7FDA8E3ADFDBCBA19970EAA9
        5199745959B69F4620118480EBD1A3407AF5F2E6C7D9EAD575E2A577BD2BF803
        89ED79E7AD15D97E0A81441002AE7F7FEF2EE5AD5FE7DDDC039DFD37616278CF
        C5870F8FC98811DE4D05CF150421E0FAF6F3EE64779D8741B8FEC6F2D04FF479
        C735E5D97E0A8153E0366EE257605F03AFD611D04B8D7BF5CE3F0F9E53B428E2
        563D0ABB899794BAE5DCB2FD3D9600FDE208214F8E10B66F6FF0F483940BF706
        545414C89831E11B14F553F8BFAB39AE6F5F6FC610B66F6B14AF5C7555EE8CD0
        87791CC40F0421E0FAF4F1E608C1AB4548F5EEC18B2E0ACF44A493B9E0028E10
        5A23082158A0D40B070E7A1384CB2E2BEDD492E961BA8AE3E5959CB0CBA16F6D
        6EF2EAA626AF56239E9483D37EBDBCB53CEC4863C0797697635DFA3734E904A9
        111EDE86DD913D7B1A65FEFC1AD9B1BDD18D7E0F1E54E4EE41D0BD1DBC367C78
        91CC98EEF9C386124108B8628F161CA96F483F08975E5A9A91B9070F3E78441E
        7CE0A83435BDFD39FFE94F87E57DEFEF2EEF798FB73324870C618252124108B8
        98474708710FCE18327197E09FFF74581E7BEC689B7FD6D01097BFFEE5B05457
        37CB873ED4C3D37B45347471F630630C21E8BCDAE928DDC1493D5D1839D2DFD3
        85F9F36ADA8D416B8F3D7A545E7BCDBBFB32F4B56160318141C580D39F8A4108
        820E26FA79BA5059D92CBFFEF5C14EFDBBFA93FC2F7F3EECF91D90200881D7D8
        E84D10FAF54BEF0D7FC515FE4E467AE8A1A35DBA357BFDFA7AD9BCD9BBD99703
        06B04082E20821E01A3C7ACF9F7A5AEA4138FDF4A80C3FDBBF8137BD24FAFC73
        5D5FF8F5A597BCDBC371C0008E1014410838DDC034DB8BAC5C779DBF37324D9D
        5AE5167FEDAA15CB6B3DDDD4050421F0BC5AE14883D0AD5BD7FB5F5A1A916BAE
        F52F083A1E307D5A554A7F57779EF22A983D72E0662D2FF02A04DC9123DE4C39
        D601C18BC674FD1E84EBAFAFF0740BB9E3BDFA6A9DECDAD598724C366EF4E69C
        AA1B41700842C01D3EE4DD1A885D3DF4D71B99FEE10E7F97497BF9E5D48E0E92
        F6ECF6E62ECE548E9E7211AF42C0A5FAD3B3BDDD8B74E9B0CEFAC8477BF87A74
        A03311972C4E6F1C60EF5E6F8EA04A4BF928285E8580DBB9D3BB20A8CF7CA657
        A79620BFF9E60ADF2F35EAE4229D7F1084DBBAA35C647008429E0541B732FBB7
        2FF591C2C2F667195D7965997CFC133DC56F7AF352BA6A6BE3819A111A760421
        E0B66F6F9466EF8611EC26A5EFFFA09FDB532139FB50FF77E8D022F9FC177ACB
        DD9FEFEDFB4D4C3A20B87851FA970DEB3CB88B33B9CD1BB8B929F0F40DBF6D5B
        830C1EECED26A5E79E1B93EF7DAF9FFB09AB973675504D2F31668AAE007DD083
        455BBC9ADA8D048E1042E00D8F2EADB57F634F614663A0BCDA81DAAB2DD9BC9A
        221E76042104366EF46E3F8520D0D3853973AA03B5804C93376393A147104260
        E54A6FB760CB36BDBAB04FF788F0404989376F614E3D12084208BCF556836797
        D782E0A597D29B8CD45AAF5EDEBC8575D1151084D058B122378E127407A9051E
        5C6EF4EAB6EEA4EA2AC61014470821E1E587289B66CFAEF66CEE80EAE7D1CE56
        5EDD2415760421245E79A5562A8F86FF4DFBE28BDE9D2EA8411E5D8E3DE4D132
        F561471042422F8BCD9B17EEA384B56BEBE50D0FAF98949717B84BA65EF0624E
        442E200821F2C20B5D5F5528489E7EBAD2F369D85E39B09F20288210229B3635
        84F612A4DEB5397F9E774B9EA911E77AB7AC9B579741C38E2084CCE38F9F7C99
        F220D2A5D3BDBE27E3FCD12581BD892CAC0842C82C7FA55656AF0ED751826ECB
        366386B747077A77E28811DE1D21ECD84110144108A1DFFFEE70A87619FAFBDF
        8E787EAF802EF612F3689B3BBDB98BCB8E090421A4F7367839DBCF4F1B36D4CB
        AC59DE1E1D246FE1F6CA962DFEDD3C16360421C44709411F08D3A3985FFFFA90
        E7473305052213267A178437371184248210527A88FBB39F1E08F4A9830E807A
        39EF20E9FCF38BA5470FEFDEBA9B36E5D6DDA4E9200821B66A559DFCF5AFDEEE
        71E8E569CDDFFE7AC497C7BEEEFA0A4F1F4FB78543024108B9471F392ACF3E1B
        AC094B3AEBEF07DFDFEF5655F69A2E0D3F716289A7DBC8E9327548200839E0FF
        7E7B485E7ED9FB81BB546F23FEEE77F6FB36BE71CD35651D2E10DB556BD684EB
        12AEDF08420ED071845FFCFC803CFAE8D1ACC7E05BDFDCE7DB0A4F3AF7E0A69B
        BD3D5D78ED5582D01A41C8A128FCE5CF87E57F7E79D0B39588BB3A35F9CB5FDA
        EB164FF5CB3BDE512EBD7A79BB29EB2B1E6E189B0B08428E9936AD4AEEBE7BB7
        AF1FCCE3CD9A592D5FFCC21EB7B2935F7431D577DF5EE179C476307EF036EC57
        9383F44DFED5AFEC916BAF2B977F786F77DFB63AD7093D7FFAE361B75683DFF4
        E8A07F7F6FDFAE4B977274703C8290A3F446A2179EAF9219D3ABDD76EED75E5B
        2E43861479B648EA73CF56CA820535199907A14BC5BFFFCEEE9E3FEEFC90AF2F
        E1078290E3743561FDF0EAAFD34E8BBA29BFE78D2C7671E8DDBBB0D33727E9B6
        EBAFAEAC93254B6A323E43F2DDEFEEE6F9D8815E1A0DDB4D629910895D794180
        E7BAC14FDDBB17C88053A2525E562065E511292D2990E6E6B8D4D5C7DDA2A3FB
        F737C9BE7D8D6E61D46C9A3CB94C4A3CDE4846B7910FEBDA127E2208000C5719
        00188200C0100400862000300401802108000C410060080200431000188200C0
        100400862000300401802108000C0BA4E06D74B9B5BE7D0ADDE229FAAB57EF42
        292D8948512CE23657D55FBABE61C4DBE509B2EAFBDFDB9FEDA7101804218FE9
        07FE820B8BE5AC6131397348915B45A9BC9C83C67C4610F2CCD967C7DC326A63
        C696C8196778B3C622720741C80315150572C595656EA15522808E10841C5656
        5620B7BDAB426EBDB59B5BB918381982908374C0EF965B2AE48E3BBA4B4537C6
        04D0790421C79C724A543E77772F39EFBCE26C3F15841041C82153A694C9673E
        DB8BD303A48C20E488DBDFD34DFEF11F7BE4D4FC00641E41C8019FFCA79E72D3
        4DDE6E848AFCC48853C8DD7967776200CF108410D31D91EF789FF79BA0227F11
        84901A36AC483EFD995ED97E1AC8310421848A8A2272F7E77BBB9B8C002F1184
        10FAC007BACBE0C1DC8700EF4585CB54A19B78F4CE5BBB65FB69E4163E038623
        84105E55E054017E210821A2772AEA6C44C02F042144F486256622C24F042124
        F4F6E5C993393A80BF084248680C58D3007E23082171F9E51C1DC07F042104F4
        C8E0BCF362D97E1AC803042104468F2E91C2422E96C37F042104C68C61F52364
        06EB2184C039E7642E089595CDB2756B831C3DDAEC7E0D1912733752A5E2C891
        6679E9A5AA36FF4C377C292D2D903E7D0AE594530AA57F7F6FDE8AFADCF7EF6F
        F2E4B1F2114108389D95386890BFDFA65DBB1AE58517AAE4D5576B65D3A60689
        C78FFDD96DB7759361C37AA4FCD87FFCE3E14EFD7BDDBA15C8C891C5327E7C89
        5C7249A95B313A153A4FE36F7F3B221B37D6A7F4F7F31D4108B881038BDCDD8D
        7ED09FA47FFFFB119939B34A9A9ADA8F45AABA772F7003A2B5B5AD0AD30E3D1A
        59B8B0C6FDFAED6F0FB9B51EDEFBDE6ED2B367D76EE91C34A8487EFCE3FEF2C8
        2347E4C1078F4A53D3C9BF368E610C21E0CE3CD39FBB1A376CA8972F7E718FCC
        98D17E0CD4EEDDA907410D18D0F59F391A90679EA9947FFAA75DF2F4D3956F3B
        62E9EC51952E41FF9FFFD95FFAF5E31EF1AE200821B8BBD16BAB56D5C9D7BEB6
        570E1E3CF9B9763A4708A906A175187EF7BB43F2AD6FED73631B5D35746891FC
        E427FD531E03C9470421041BB27A493F583FFDE901A9AFEFDC8FDD9A9AB81B1C
        4CD58001E93FFF152B6AE54B5FDA93D26061AF5E85F2FDEFF7978B2F2E49FB79
        E403821070BD7B7BFB2DFACD6F0E75F98395CE69433A4708ADEDD8D128F7DEBB
        37A538E938C6D7BED6572EBA88289C0C41C8A32304FD60CF9953DDE5BF97CE69
        83174708ADA3F0E31FEF97E6140E58745CE12B5FE9E34E23D03E8210829D9BBD
        F2E28B555D1EA053BB763565FD0821E9B5D7EAE4C9278FA6F4774B4B23F28D6F
        F465A0B1030421E08A8BBDBBE4387366D78F0ED23D65F06AC2516BF7DF7F440E
        1D4A2D523AA670F7DDBD5957A21D0421E0BC9A83A0E306A9CEE04BE794417F2A
        EBA4232FD5D5C5E589272A53FEFBA34615CB0D37B0D3555B0842C0E9145FAFE6
        1DA42A1B73114E46A74477347FE264EEBAAB87F4EFCF1C85E3118480F3EA0841
        A724A76AEFDEA6B466FC7939B09874F870B3BCF65A6DCA7F5FAF3CDC7967EA53
        B273154108B886066FA6DEA632B127490722F7EC09CEC062EB0956E9D0056B99
        C9F8760421E03A3B81E864AAAA520F42FA971EFD09423A473DC94B91EF7E377B
        5CB44610022E2841D8BD3B9D23047FCED577EE4C6F6C43E94D54AC55794C946D
        6B824D47D4BDD0D4A4631191AC1C2124EEC7F0FE8ECDA347E39E0CDA8E1D5B2A
        F3E6D578F29CC28E238480D3C1332FA4FB53309D23040D821F3F85BD1A5F9938
        9129CD490421E00E1C680AC404A7748E1074D1123F36A7F52A327AE3136B5626
        1084803B78B03910F319D299BEACCE3AAB28B0D3BA7575A633CE60AD20451002
        AE336B167446CF9EE97DABABAB136B2CA6CA8FDB8FBD9C16ADFB668220045E3A
        E7EE5E7F78D2396D183DBAD8F371042FF7AA2008091C2104DCF6EDE95D6B4FF2
        62024E3A71D219975EEF5C7DC105DEAD46CD2943024108B8EDDBD3BFD6AEBC98
        B79FEE726AB7DF5E21051EBDE3CE3A2B26679FEDDD1182DE0509821078BAAEA0
        17FB0C7871E92FDD8940FA1CAEBBAE5CBCF00FFFE0ED0CC354977DCF35BC0A21
        B0756BFA47097AE96FD8B0F47EA26EDB96FEF3F8C8477AC8C081E98D675C734D
        994C98E0ED206559195BE5298210026FBCE1CDA623E95EFAF322083A1FE2DE7B
        FBA43C9D59C70D3EF1899EE2355DB701042114366CF0666031DD736EBD63D28B
        9993A79E1A951FFDA89F5BA8A42B4738D75E5B2EDFFC661F4F57913AF6F80441
        311B2304D259DCE4F89FAEFABE4F655DC5D6472B63C694783288F7BDEFF59545
        8B6ADD662CAB57D7B7B9E6825E9DB8F0C262B9E38E6E327CB87783887EDD4416
        760421047450512728A53B12AE4B99E951C2BA75A90746FFAE174148D2B100FD
        555D1D77B13974283101AAA222E2FE7B350299B81B91202410849058BFBE4126
        4C48FFD2D8D8B1256906C19BD397B606F5CE3F3F7BDBDEA7330B339730A81812
        AFBF9EDEEA4049E98ECE6B4CD259CB30A87499381084D04877B9B0D69BC7A6B3
        D7A1DED3B076AD37CF2548F6EDF3660258D871841012BA5C583AEB22B676D555
        E94D215EB62CF782F0D65B0441118490D02B03BA6B9117F49E8274EEFF5FB224
        F5D58E836AE3467FC646C286208488573F99BB772F90CB2F2F4DF9EF6FDDDA20
        6FBE993B1F20DD2BD2ABC95F6147104264D932EF7E32DF765B455ADB99BDF452
        6ADBC205D19A3575EE9E111084D02DA7E6D52425BDFF5F2F41A66AD6ACEA9CB9
        76BF7871EE9D02A58A23849059B0C0BB37EFEDB7A77EC7A04E617EF9E5EA9C18
        9B993F9F1597930842C8CC9D5BEDE98A43E9CC4BD00D57D399061D94D3B07476
        A5CA3504216474D5A2B56BBD1B00D34D4F7507A354ECD8D118FAB184679EA9CA
        F6530814821042D3A77BF7263EFDF4F4162DF9EB5F8F8476404E6FA85ABE9CF1
        83D6084208CD9953E36E06F2CA9D7776971E3D527B2BE84D570F3C7044C2464F
        75FEF087C3D97E1A81431042487F224F9BE6DD5182DE05F9C94FF64C6B2CC1AB
        7B2D32E5D9672B3DBB62934B084248E91A028D8DDE1D255C7659A98C1B5792F2
        4FDB9FFFFCA06753AB33314DF9CF7F0EDF514D264462575D18CE1340C8F5D797
        7BBA9FC0BE7D4DF2E8A34753FEFB234716CBB7BFDDC72D6A12547A9BF397BFBC
        D70D88E24404019ED2238D2F7EB1B767CBAD7B4927527DFDEBFB3CBD4A936B02
        F86D4398CD9D5B233FFEF101CF7666F68ADEB6FDCD6F1283932108F0DC820535
        F2AD6FED77CBA105814E3CBAE79E7DEE32233A4610E0DB822E9FFBDC6E59B1A2
        2EEB71FAFCE7F7C8E6CDB97377A69F184380BF6FB088C8E59797C9873ED45DFA
        F429CCE851C19FFF7CD89DC2A0F308023242F752D0199137DF5C91F2262D9D0D
        C133CF54CAF3CF57E5CCDD9899441090D9375C44E4E28B4B64D2A4C4BC878A8A
        024F266A2D5D5AEB66702E5E5CE3163C416A0802B2466FAAD2FD2675AF88E1C3
        8BDC7D15FDFA45DD34EAF6166FD1AB057A83976E3CABCB9EE92AD0FA2B685735
        C28A202070A2D188DB6B514F3362B188DBD1A9AE2EEE8E04C27A235558B0510B
        0247A7641F3DAABFB2FD4CF20F971D01188200C0100400862000300401802108
        000C410060080200431000188200C03075B9134E3B2D2AA79C12CDC894DD575F
        0DD772E65E1A3DBAD8DDC7E027BD294A7FA16D5109EE02B981F1E94FF794F3CF
        2FF6FDEB3CF36CA5BCFA5AFE0661ECC52572DBAD15BE7E8DF5EBEBE54B5FDEEB
        EBD708334E194EA267CF02B7BCB8DFF4B6DE071EC8EFBB791E7CF0A81C3EE2EF
        62067AABF58811315FBF4698118493B8F492D28C2C29FED0C347DD9E01F94CA3
        F8B7BFF9BF81CAADEFF4F72824CC08C2495C9CE26E465DA12178EE39762156BA
        45DDF6EDFE9EE34F98502ABD7A656E7DC73021081DD01D88468DCCCCD8812E00
        82C4B6700F3FE2EFA9931EF15D3EA59497BB0D04A103E78D88B9557BFCA42B00
        3DFB2C4707ADCD9E5DED9649F3D3155794F9FAF86145104E72192C136FFE7C1F
        3B385E5393C8A38FF97B94306448910C1AC455F7E311840E9C7BAEFFA3D13366
        54FBFE35C268D6AC6AA9AEF6F7346AE2444E1B8E47103A38CF3CEB2C7F83B06D
        5BA3AC5DC7F662ED9D4ACD9AED6F2CC78CF17FC0386C08423B749BF592127FC7
        0F5E9EC9D141475E7CC1DFB19573CE8E4979391F81D67835DA31744891F86DF1
        E25ADFBF4698BDB9B9C1FDF2735F880B2EF07F9C284C08423B069FE16F1076ED
        6E94AD5BD980B4339BB5FA29139795C38420B4E38CC1FE8E402FE1E8A053162E
        F0F728EA9C73FC3F120C1382D08E41838A7CDF2E1D27B7656B83AF7727EAE547
        DD1D0A0904A10D7A0BAEDF5B97AF59CBD585CE5AB9D2BF7816164664D8308E12
        9208421BFAF52B6C77B3512FECDAD528870F3319A9B356BDEEEFD1D4D0A10421
        8920B461C08042DFEFC947E7BDFEBABFAFD7C08104218920B4A15F5F7F83B0F5
        2D56ECE98A03079ADC5519BF0C1AC814E62482D0861E3DFD0DC2F66D04A1ABB6
        6CF6EF351B48100C416843CF1EFEBE2C6F6D63FE4157F9396743D746282BE3A3
        A07815B27084B0678FBFB7F6E622BF2771F5EFCF82298A20B4A15BB7025F6FDA
        613194AEDBBEC3DFD3AC3EBD098222086D282DF5EF9AE3C1831C1DA4E2C0017F
        2FD3F6F17920392C0842868370E810F30F527BDD9AA4D9C797AEAFCF13D1C282
        20B4A1B4D4CF53068290EA5A8B1A05BFF4ECC54741F12AB4A1D4C775101AB8C0
        90B2233EEED950C1BA080E4168677EBB5FEA1B585D39550D3EBE762C94924010
        DA5938238C6FEA5C575FEF6710B8E351118436447D9CC91A2BE28D97AA7A1F4F
        B738424820086D2828F0EF43EBF73E0FB92CDE1C0FE595A53021086DF0F3F296
        DF0BB7E6323F63EAF736F4614110DAD0D4E4DF4F228E1082F9DAF939901C2604
        A10D8D3ECE92EDCD14D9941517178472DC284C084286AF046810383C4D4D4505
        47087E23086DA8AEF66F10419766D325DAD0F59DB87BFA7817AA9F979AC38420
        B4A1AAAA39D44BB4E522BFD7B9F47320394C08421BAAAAFC9D3C346CA8FF9BC8
        E69A0103FC3DC96F6C64C29822086DF0F3269A4CED2A9D6BFCDEBA9D23840482
        D086FD3EDF7B7FCE3904A1ABCEF5F93563D19A0482D0CE2ABF7EEAD1A3404E3B
        8DEB5C413AAAF27320394C08421BF6EEF57F55A34B2696FAFE357245DFBE85BE
        EFA4555DCD188222086DD8BEDDFF450B264D22089D357E5C89F8ADB292230445
        10DAB06B57935BA1C74FBA9F202BFD06279E077D1E480E0B82D0CE4CC5DD3EEE
        1494F48EABCB7DFF1A61A77B268C1C59ECFBD739E8F34072581084766CDAE4FF
        69C30D3794B315F9495C3EA5D4D7094949FB7D1E480E0B82D08E8D6FF81F84EE
        DD0BE4EAABCA7CFF3A61A5D3896FB9A522235F2B134784614010DAF1C61B99D9
        A1F9B6DB2AB8F5B61D975D56E6AE3064C2CE9D0441118476AC5B579F91D96BA7
        9C129577BE93B184E3E969C2EDEFCECCD1810E20EB40320842BB6A6AE2193B4A
        B8E31FBABBC1331C73FD75E572C61945193B3A60F1DB048E103AB06A556682A0
        EBF97DF423DD33F2B5C2B2B7E6073F98B9D763D39B6C969144103AB0EC955AC9
        942953CAE48ACB1960541FFD480FA9A828C8A92B4A6141103AB07A759DEF6B23
        B4F6A94FF594D34FCFEF7B1CAEBCA24CAECAF09597F5EB337324180604A1034D
        4D7A945097B16F86AEC8FCE52FF5CEDB9599F516E77FFEE79E195F5057079091
        40104E62DEBC1AC9A433CF2C92AF7DAD8F5B322C9FE89C8C7BBEDA27E331DCB8
        B1C1D71DA1C286209CC4B265B5193D6D50178C2E962F7CA19714E4C977A7ACAC
        40BEFDADBE59395D7AF5D5CC1D0186419EBCE552A797A3327D94A02EBDA454EE
        FE5CAF9C9FB4A44704DFFC461F193A343397188FB77459E6068EC3802074C2D4
        69D5920D975F5E26DFFC661F292BCBCD28E8DC8BEF7FAF5FD696943B7AB499F1
        83E310844ED8B0A1DEFDCA063D7DF8E10FFAE5DCD2ED43CE2C92FFFACF7EEE36
        F06C59B8B0C6F7DBDCC3862074D273CF5749B6E88CBD5FFCBCBF4C999C1B8BAA
        BCE31D65F2C31FF6F37D15A493993327F3A7824147103A69F6EC1AD9B72F7BF3
        DD75BBF22F7EB1B77CF10BBD42BB75B99E22DC7B6F1FF997CFF6CAFAA5D58307
        9BE4D5D718503C5E38DF5959A0EBF63FFE7865B69F869BD1F8FF7E3D406EBE29
        3C7749EAD675FA7CFFE797FD65DCC5FE2F87D619D3A75773BAD08648ECEA0B39
        8BEAA4582C22BFFDCD80C0DC88A437E5FCEDEF4764FEFC9A40EE2BA0772C6AC0
        3E7067F740ED56A5E3069FFCE42ED99381C574C3862074D1F5D797CBA7323C9B
        EE64F6EF6F92E75FA892A953ABE4F0E1EC97A1872EFC7275995C777DB99CE2F3
        8E4BA958BCB856BEF7FDFDD97E1A8144105258C5E797FF3D2090F71CE869CDD2
        6575B278718D2C5D522B878F642E0E3AAE31764CB14C98582A132794047A87EB
        AFDEB357D6AC61BA725B08420AF43C5807C7824C0F8B758EFEAA55756E3938BD
        6CEAE5A0A86E3673D6B0989C7556918C1E5D2C234614876207E5D56BEAE59E7B
        F666FB690456F07ECC85C092A5B5B260418D5C7249702F03EAF9BB4EF8693DE9
        474F27B66F6F94BD7BF557930BC4A1C3CD525F17775B99D5D5C7DDCC4CFD6017
        C722122B8EB87113BDCFA05FDFA85BCE4CE743E8D151A69636F3DAFDF71FC9F6
        5308348290A2FFFBDD61B9E8A292AC5F3EEBEA4FF51E3D3410F9B9B7E4F21575
        DCBB70125C764C6320EF0F7F389CEA5F4786E955983FFF89EFD7C9108434BC38
        B5CA9D3E20F89E7FBE4ADEDCCCCA48274310D2F43FFF73500E1DCAFEA53E743C
        2B51E76BE0E408429A34063FF9C901B7BA1282E97F7F7D88EDDE3B89207860D5
        EB75F297BF707E1A443A45592722A1730882479E78B2525E7E393BEB26A06D3B
        7634CAEF7E7F8897A70B0882877EF93F87E435EEA00B84DADAB8FCE08707DC86
        3BE83C82E0F10ABEFA26DCCC6876D66769FEF27F0ECAD6AD5C55E82A82E0315D
        90F51BDFDCE76604223BFEFEF72332772E8B9FA48220F840A7087FFD1BFB64D7
        2EA2908DB9210F3F7234E35F375710041F6732DEF3B57DF2D65B4421535E9E59
        2DBFFE358388E988C4DE7111A32E3E6F5CFAED6FF6C9EA62A2F9B2C4DDCF7E71
        30900BC5840947081958EAFB6BF7EE93254BB816EEE725DF9FFE9C1878812064
        E812D8F77E70409E7A2AFB6B32E6DAD504BDEBF48F7F3AC2FA881EE19421C32E
        9F522A9FFE54CF50DD361D44BA1FE37FFDF4A02C5CC49197970842967639FEEA
        977BCBC0812C47910A5D1CF527FF79906DDC7D4010B2445722BAEB43DDE5A61B
        CBDDEA46E89C99B36AE437BFD59B95180BF70341C8B2F3CF2F96CF7EA6A79C12
        A065CA83A8B2B2597EFD9BC34C38F219410880585144DEF39E0A79F7BB2AA4A8
        88C385E32D5F5E27BFFCD52137B703FE22080172CA2951F9D03F76735BC1731A
        21B2756BA3FCE92F4764195BB6670C4108205DDAFC1F3FD85D2EBCA058F2D1C1
        43CD6E75E469D3AB996894610421E06178CFEDDDDCC627F970C4A04B9D3DF77C
        B53CF574A59BBB81CC2308213995B8FEBA3279C7D5656E2A74AE59B3B65E9E7D
        B64AE62FA875B790237B084288E880E384F1256E72D39831C581DE2EAD33570D
        162CAC95E79EAF924D9B58B72028084248555414C8F87125326E5C891B6B282B
        0B7E1C74B7A8458B6BDD1A87BA0E250BD3060F41C80185851119312226A346C6
        64E4C8989C73764C8A8B238158917AC3C67A59B7AE4196BD52CB91400810841C
        54502032686054860E8BC9D02145EEFF3FF5B4A8F4EF57E8FECC6BF50D71B74F
        E4EEDD4DF2E69B898D65376C6C704704081782904774CCA16F9F02E9DDA7507A
        F72E945E3D0BDCA947595981949745A4B82422D1C2881446352A11B7BDBCDB04
        B62EEE6E264AFEAF2E13A701D00FBCDE57A02B44213770774D1ED10FF8AEDD4D
        EE17D096DCBB860520650401802108000C410060080200431000188200802000
        38114708000C410060080200431000188200C010040086200030AC8780B739BD
        DF0019D8B7BF9CDAA75FCBAFBE52515226C5B162292D2E9692584C8A0AA312C9
        A175E1DFF3CD2F64FB29040641C863FA81BF7ACC0419337C849C3FEC6C193DF4
        6CE959D12DDB4F0B594410F2CCF87347C9BB265F2DD78E9B24A3869C95EDA783
        80210879A0574577B9F39A9BE46337BE4B469E4904D03E8290C3BA9795CBE7DF
        FB21F9D7DB3F2015A565D97E3A08018290830A2205F29977BD4FBEF6C14F48EF
        6E3DB2FD7410220421C70C39F574F9FD97BF2393465D98EDA78210220839E48E
        2BAF97FFFDFCBD9C1E20650421477CE97D1F91EF7CF4B339353F0099471072C0
        CF3FFB15F9D4AD7764FB692007307539E4BE71D73F130378862084D887AFBF55
        FEFD839FCCF6D3400E21082175D1F073E55777DF9BEDA7811C431042A8B82826
        7FF8F277245A5898EDA7821C431042E85B1FFE949C77E6B06C3F0DE420821032
        434F1B28FF7AFB07B3FD3490A30842C87CE343FFCCA9027C43104244EF54BCE3
        AAEBB3FD3490C30842887CF6DDEF77372E017EE1DD15127AFBF23F5C715DB69F
        06721C410889F75E712D372DC177042124DE7FD50DD97E0AC803042124A70B97
        8EBA28DB4F0379802084C015178E93A22837A6C27F042104AE1D7769B69F02F2
        043F764260C288F333F6B50E561E91D59B37C981238764FF91C372C1B073DC8D
        54A9D877F890FC6DDAD36DFE5949ACD89D0A0DEC37C02DFB76C680D3C40BAB37
        BF21DBF7EDF1E4B1F211410838BD8169C419437DFD1A9B766C93DF3EF388CC5C
        B158566E5C2FCDF166FBB3BBDFF38F2907417DE5373FEBD4BFD7A77B0F9974FE
        18B9F992CBDDBE11BA62742A74C5A86FFEF157B26CFDEA94FE7EBE8BC4DE7151
        3CDB4F021DCF4E7CE5FF1EF2E525DABE77B77CEB4FBF96FB663C2B8D4D4D6DFE
        3BB74EBA521EFAD67FA5FC35FABCF332A9ACA9EED2DFD12387BBAEBF55BEFAFE
        8F4AFF5E7DBAFC35F5BFE547F7FF5E7EF0F7DF4943636397FF7E3E630C21E046
        0F3BDB97C75DB276955CF2D90FCA5FA63ED56E0CD49B3BB7A7F575CE3CA5EBA7
        021A905F3D7EBF8CB8EB56F99FC7EF93783CDEE5A32A5D3866EE2FFF2283FA9F
        D2E5AF9FCF0842C0E9F9B5D766AF5C2AD7FCDB2764F781FD27FD77DFDC956E10
        527FFE1A862FFEEF7FCA4DF77CC68D6D74D585679DEBA290CE294FBE210821D8
        90D54B078E1E96BB7E78AFD4D4D575EADF3F5A5DE50607B31184A419CB16CAE4
        7FB94B76A43058784AEFBE32E3A7BF971B264C4EFB79E403821070A7791C84BB
        7FF9A32E7FB0DEDCB92DE5AF37E4546FAE1E6CD8B645AEF9B74FA614A7F29252
        79E4DB3F956B2EBEC493E792CB08421E1D216CDEB55D1E9E39B5CB7F2F9D7104
        2F8E1092366EDF2A777EF72BD2D47CEC2A4857C615EEFFFA8FDD6904DA471002
        CECBBD19FFEF9947DF7649B1B3DEDCB52D104150B3562C91FF7EF46F29FDDD6E
        65E5F2E4F7FE9B81C60E1084802B2D2EF6ECB1EE9BF15C4A7F2F9D238433069C
        2A5EFB8F3FFF3FD973F0E403A2ED8D29FCE1CBFFC10E57ED200801571C8B79F2
        383A6E90CAA09CDA944610F4A7B24E3AF252755DADFCEC91D48E12D4940B2E96
        7FBAE5BD9E3EA75C411002AE3456E2C9E32C59F77ACA7F379D41453F4E1BD45F
        5FEC78FEC4C97CEFE3FF2A837D387A093B821070B1226F6697AFDCB82EE5BFBB
        6DCFEEB466FCF91184BD870FBAF18454E96CC86FDEF5294F9F532E20080157DF
        D0E8D9FC8354E940E4D63D3B53FEFB677A74E9F178B3562E4BEBEFBFEFAA1B18
        603C0E4108B89AFA5A4F1EE770E5D1B4FE7E3AA70D7E1C21A8156FAC4DEBEFEB
        A5C87FBBE3C39E3D9F5C401002AEB693330A4FE650557A4148676071884F41D0
        BB34D375D775B7B256652B0421E07444DD0BE90CC0A57BE951779BF283AED9E0
        C565DDEBC64DF2E4F9E4028210707B0E1EF0E47174FA6E3AD29BBE7C7ADA5FBF
        2DB5F5F59E3CCE3B275DE1C9E3E402821070BB0EEC0B4810523F42D0CD6546FA
        B0396D796999278FA3373EB166650241C89320A43BE331DDB90863CE3E4FBCD6
        BB5B774F1EA74779855B88061A8488AE9BC4AFA0BE063B3D0A825B79288DE771
        B8BAD2ADB198AA1B274EF6FCB5197C8A77138B460D3D2BEBDFEB20FCE20821E0
        B6ECDEE1C9E378312B2F9DA3045D4A5E27037969D248EFF6AA18C51182431002
        6EDDD6373D799C33FA7B108434564F2A2E8AC91D577ABB73F555632678F6589C
        32241084805BBF6D4B4E1C21A87FFB870F4B6181376FB9B1679F27E3CF1D255E
        39A54F5FCF1E2BCC0842C055D5D6C8F67DBBD37E1CBDF497EE21FB1BDBDF4AEB
        EFEB7C848FDF74BB78E19E3B3F2E5E4A75D9F75C43104260CD964D693F865EFA
        BB28CDD582D6BDB539EDE7F1C34F7E5ECE1D3C24ADC7F8C8F5B7C92D977A3B77
        A05B5985A78F17560421045ED9B0C693C749F7D29F1741282B2E91C7FEE3E729
        DFDFA0E3063FFDCC97C56BDDCABC1DF00C2B8210024BD358CBA0B571699E73EB
        1D937B0FA53F7372D8698364F6CFFF2453468FEDD28E4C1FBBF1DDF2D4777FE9
        A2E2353D8202410885A5EBBCD996ECAA8B26A4FDC65FBE21BD3B0C9306F4EE23
        D3FEF3FFE4916FFD542EBFA0FDDDADF5EAC48D1326CB9CFFFEB3FCEFDDF7FA36
        A3D0ABBB4AC38EBD1D43400715755315FD10A54397321B77EE4859B4E6B5941F
        63D1DAD73CDD8D5AC702F4D791EA2A59BE61B5EC3E78C01D89F42CEF26A7F6E9
        2B179F33CA97FB20FCBAAB34EC0842482C5EFB9A2703697A675F5A4158F3AAF8
        4147F9F548215BD29985994B38710A8939AFBDE2C9E3BCF3D22BD3FAFB8BD7BC
        96F6ADD441B46DEFAE6C3F854020082131E7D5F4960B4B3A7FE8F0B42E3F1EAE
        AA9405AB574AAED9BA8720288210122B36AE4B69C3D3B6FCE3B5B7A4F5F75F5C
        324F72CD5A8FA688871D4108095DE874D68AA59E3CD61D57DE90D668FDB30B66
        4BAE7965BD375772C28E208488573F99FBF6E829EFBBF28694FFFEEA2D6FC8CA
        37525FD63D6874AFC8E51BBDB99C1A760421449E5F3CD7B3C7FAFC7BFF31ADED
        CCFE36ED19C915F35F5F219535D5D97E1A8140104264E7FEBD9ECD5AD4DB7DAF
        1F7F59CA7FFFFE979EF76C4DC36C7B66C1AC6C3F85C0200821F3C4BC973C7BAC
        2FDDF19194FFAE4E61FEDBF46772626CE6B139D3B3FD3402832084CCC333A77A
        F65893465D98D664A79F3FF2D794B6970F921717CF93ADBB53DF952AD7108490
        D9BC6BBBA7F300BEFFF17F753B18A562C3B62DA11F4BF8D5930F64FB29040A41
        08A13FBFF0A4678F75F6C033E5E337A6BE68C9D7FFF03FA11D909BBB6AB94C5B
        BA20DB4F23500842083D3C6BAABB19C82BDFB8EB53D2AF67EF949789FFDEDFFE
        4FC2261E8FCB577FF3B36C3F8DC0210821A43F91FFF8FCE39E3D9EDE05F9B334
        161DD1B104AFEEB5C8945F3FF9A02C59B72ADB4F2370084248FDF2F1FBA4BEB1
        C1B3C77BEFE5D7CA4D13A7A4F4777560F1A33FFEBA6753AB33B124DDD77EFF8B
        6C3F8D408AC4AEB9289EED2781D47CF2E6F778BA7CF8B67DBBE5270FFC31E5BF
        3FF9FC31F2EC0FFFD72D6A12547A9BF3E5777FD80D88E24404019ED2238D3FDF
        F37DCF965BF7524D5D9D5CFF957F9285ABFD59D3211704EFBB86D00F78DEF9DD
        2F4B5D43B06631EA6DDB37DFF36962701204019E7B62EE4B72F3D73E2B7B0EEE
        0FC4ABAB138FAEFEE2C7DC6546748C20C017B3572E95B1FFFC3E99F1CAC2ACC7
        69FCA7DE2FAF6DDA90D5E711168C21C0DF37582422EFBFEA06F9DEC7FE554EEB
        DB3FA34705F7FCEEE7F2C8AC6919FB9AB980202023742F05DDC6ED33B7BD2FE5
        4D5A3A1B82FF79E27EF9ED330FBB4144740D414046E9BE10D78F9F24B74FB946
        6E9C38597A77EBE1C9442D5D2BE2E1992FBA5B9975C113A48620206BF4A6AA31
        C347C8C5E78E9271E78C92E10307BB6DEB751A757B8BB7E8D5822DBB77B88D67
        97AE7F5D16AF5D258B56BF1AB8AB1A6145101038B16891DB6BB1B4B8444A62C5
        6ED9F7EABA5AA9AAA976BB61C33F6CD482C0D129D9898D53D83C25D3B8EC08C0
        100400862000308C218480EE7E9CCE92E927D3D0D8C8283D1C821070E79D314C
        96FFDFC3BE7E8D4FFDEC3BF2070F175C417871CA1070375D92DAA2259DB5FBC0
        7EF9FBF4677DFD1A080F8210703A61C74FBF7DF6114E17600842C00D3D75A0AF
        8FFFA4871BBF20FC0842C09DDAA79F6F8FAD5380B92D18AD1184105C61F0CB4B
        CB17FBF6D80827821070C5B122DF1E7BF5E6377C7B6C84134108B8FA8646DF1E
        7BF5964DBE3D36C28920045C755D8DAF6308406B0421E0749E805F8E5457FAF6
        D80827821070DBF6EEF6EDB12BABC3B9492BFC1315F16F8E3CD2F7FAE637E49A
        8B2FF1E5A5AC6BD0ADE0F8FEE3188E10026EF9C635BE3D764569996F8F8D7022
        0801F7F28A25BE3D76CF8AEEBE3D36C28920846050F1950DFE1C259C75FA205F
        1E17E1451042E0BE19CFF9766B35D01A410881BF4D7DC6ED3DE0B5AB2E1AEFF9
        6322DC0842081CAC3C22BF7BF631CF1F77CA05631958C4DB108490F8E17DBF6F
        599ADCDB1BA7DE77E5F59E3E26C28D2084E828E12BBFF9A9E78F7BF77B3EE876
        500214410891BF4E7BC6F3DD8C870F3C433E79CB7B3D7D4C84174108994FFED7
        B765C5C6759E3EE6773FFA59397BE0199E3E26C28920848CEE6DF8CE7BFF45D6
        BDB5D9D3B18407BEF113E9C544A5BC4710423A59E99A2F7D52966F5CEBD9638E
        3C73983CF1DD5F48F7B272CF1E13E14310421C85ABBFF071797CCE0CCF1E73E2
        79A365D62FFE28670C38CDB3C744B81084909F3EBCEF3B5F96CFFDF2876EBB74
        AF662F2EFEF57DF2FEAB6EF0E4F1102E91D83563E2D97E12489FFE54FFF967BF
        2C374E98ECD9CB396DE902B9E777BF6065E63C421072CCE5175C2CDFF9E86765
        C288F33D79BCE678B33CBB60B6FCEAC90765E68A25128FF3F3239711841CA5D3
        92EFBEFD8372FDF8CBA4B0C09B33C3EDFB76CB13735F96E716CD9145AB5F95A3
        3EDC5F81EC22082131ECB4D46E553EBD5F7FB9F7839F74470E5E6A6A6E76CBB8
        AFDEF286BB04AA4BBDED3EB85FF61F3E24B50DF552575FEFFE9D307863C75BD9
        7E0A81411042A26EEAB26C3F859C557CEDD86C3F85C0E02A0300431000188200
        C01004008620003004018089B2710FF21E9B57198E1000188200C01004008620
        00300401802108000C410060080200431000188200C010040086200030040180
        2108000C410060080200431000188200C0448FFDBF08B2E717CFCDF653401E88
        C4AE653B7800099C3200300401802108000C410060080200431000188200C010
        0400862000300401802108000C410060080200431000188200C0100400862000
        30040180614DC54E2A8A46E5ACD306CBE001A74AF7B272696A6E96439547E5CD
        5DDB64F3AE1D128FC73BFB50406011848E5E9CC24279F7E477C807AEBE49268F
        1E23E525A56DFE7BFB8F1C9669CB16C85FA73D2DD3972DF4EB7B05F88E4556DB
        71FDF849F2B34F7F59869E3AB04B2FE82B1BD6C8DDBFFA912C5AF39A7869D869
        833C7D3C1CF3C68EB778395A1084368E0A7EF24F5F904FDFFA3E495573BC59BE
        FDE7FF273F7AE00F9E9D4AD4BDB8CC93C7C1898AAF1BCBCBD28241C5E362F097
        AF7E3FAD18B817355220DFFEF0A7E597FF728F442291B41E0BC82482D0CA7F7C
        F83372FB947778F6E27EE2A6DBE54B777CD8B3C703FC46105A5C73F125F285F7
        7EC8F317F89B1FFA944C1A75A1E78F0BF88120E83964514C7EF7C56FF97278AF
        A7217FFCF277DCFF0241471044E41FAFB9594EE9DDD7B717F98C01A7C9FBAFBA
        C1B7C707BC92F741D0A382BB6FFFA0F8ED8BFF7017038C08BCBC0FC2F94386CB
        F08167F8FE428F183C54CE3B63A8EF5F074847DE0741672066CA94D11767EC6B
        01A92008E7672E08975FC00418045BDE0761C8295D9B9A1C96AF05A422EF83D0
        A77B0FC9C5AF05A422EF83D03B9341E8D133635F0B4845DE07A1B0A030A313A0
        8020CBFB201C387228632F76755D6DC6BE16908ABC0FC2FEA387255376EDDF9B
        B1AF05A422EF83B07DEF1EC99437766CCBD8D7025291F74198BBEA15C994A5EB
        5FCFD8D7025291F74198FD6AE656229AB67441C6BE16908ABC0FC2B2F5AB65D7
        817DE2B72DBB77C8A2B5DEAEB308782DEF83D0D8D424BF7CFC7EF1DBFF3EF920
        4BB523F0F23E08EAFF9E7D448ED654FBF6226FDFB75B7EF3CCC3BE3D3EE01582
        202287AB2AE54BFFEFBFC42F9FF9C5F7A5A6AECEB7C707BC42105AFCF18527E4
        E15953C56BFFF5D09FE5F9C5733D7F5CC00F04A1954FFFFCBB6EA315AFFC65EA
        D3F2EF7FF8A5678F07F88D20B472A4BA4A6EFCEAA765E68A2569BFB03F79F04F
        F2C99F7E9B8144840A7B3B1EE760E511B9E96B9F912FDDF111B9E7CE8F75F986
        A4AD7B76CA67FFFB07F2E292795E7E9F38ED4046B0955B074EEBDB5FFEF55D77
        CA9D57DF28037AF5E9F085D4538DDF3FF7983B4DA86F6CF0FAFB04640441E8CC
        8B1489C8A833CF920BCF3AC72DA9DE4DB7836F6A9203478FC8C6ED5BDD84A39D
        DCB8841C40100018061501188200C0100400862000300401802108004C5422C7
        7E0320BF718400C010840E8C193EA2A33F06724E2476DD9878B69F4450D5BDB0
        4CDED8F1963C34EB457968E65459BDE58D6C3F25C05704E1244168EDF5CD6FB4
        C4E145D9B4933D16907B0842178270FC6ACD1A8787674D736B2602B98020A418
        84A4783C2EF357AF74470D8FCE992E7B0F1DF0F2FB03641441483308AD353537
        CBAC954BDC78C313F35E728BAD006142103C0C426BBA488AEED4A4A715CF2C9C
        2D953E2EF30E788520F81484D66AEAEBE4B94573DC69C50B4BE64A6D7DBD278F
        0B788D20642008ADE986304FCD7FD9C561C6F245D2D0D8E8F9D700524510321C
        84D67409B6C7E7CE70A715B3572E93E678B3AF5F0F38198290C520B4B6FBE07E
        7974F6347968D65459B8E655966F475610848004E1F8A5DC7517293DAD58F1C6
        BAAC3C07E4278210C020B4B661FB167719534F2BD66E7D33DB4F07398E20043C
        08ADBDF6E60677D4A0A7159B776DCFF6D3410E2208210A426B4BD6BDEE8E1A1E
        99354D76ECDF93EDA7831C4110421A8424BD32316FD50A7978D68BF2D89C19B2
        F7F0C16C3F258418410879105A6B6C6A9297572C76A7154FCE7F590E575566FB
        29216408420E05A1B5BA867A99BA74BE1B907C76D16CA9AAADC9F65342081084
        1C0D426BD575B5F2ECC2D96ECCE1C525F35D2C80B610843C08426B7A1AF1D4FC
        992E0E2F2D5FE44E33802482906741686DDF914389A9D3335F94B9AF2D67EA34
        08423E07A135DDCEFE113775FA4559BC7655B69F0EB28423840EE453105AD349
        4FBA349CC6E1D54DEBB3FD74904104A103F91A84D6D6BDB5D916965DBF6D4BB6
        9F0E7C16895D379665D8DB51F7C252BF5FFF5059F9C67A5B5876CBEE1DD97E3A
        F00141E8004168DFA2B5AFB9390E3AEEB0EBC03EEFDF99C80A82D00182D0B9A9
        D37A85424F291E9B3B43F61F39ECDDBB131947103A4010BA46E734CC7865913B
        ADD0B90E47AAABD27B7722E30842070842EA7421D91797CE73A715BAC0ACCE96
        44F011840EDCFBC14FCA8DE32F739BBE462291CC7D57728CDE47A14BD1EB69C5
        D4A50BDC12F5082682D009037AF5919B264C961B274C96AB2E1A2FE525A5FE7F
        6772D4A1CAA3EE4E4C5DE4E5E5E58BDDE636080E82D045C54531B9E2C28B5D1C
        6E1A3F5906F53FC59FEF4C1ED0B51B740D075D3F72EEAAE52C2C1B0004214DE7
        0F199E88C3C4C932EE9C91521029F0E63B9367B6EFDB93983A3DF34559BA7E75
        B69F4EDE22081EEAD7A3975C3F7E92DC34618A5C3D6682742F2BF7F2E1F3C6A6
        9DDB5A569D9E2AAB366FCCF6D3C92B04C127B168914C1E3DC68D3DDC30FE3219
        7AEA40BFBE544E5BB37553CBAAD35365E3F6ADD97E3A398F2064C888C143E5C6
        0997B9D38B4BCEBB400A0B38B5E8AAE51BD7BA383C3C7BAABCB567972FDFA77C
        4710B2A077B7EE72DD383DB5982CD78CBD447A5674CBC6D308AD783C2E0BD7BC
        E626403D3A7BBADBF50ADE200859162D2C944B475E28374F9CE28E1E869F3E38
        DB4F297453A767AD5CEA8E1C9E98F792DB2F13A923080173D6E983DD9183FE9A
        34EA22170C748EEEA43DFD95852E0E4F2F98E976DA46D7108400EB515E21D75E
        7CA91B7BB8EEE249D2A77B8F6C3FA5504D9D7E7EF15C775AF1FCA2B952535F97
        EDA7140A042124741072E288D172933BB5B8CC0D52A2732A6BAAE5E905B3DC95
        8A69CB16B82309B48D2084D499A79CE6E63BE8A9855EDED4CB9C38B9839547E4
        89792FBB09503AF6C0D4E9B7230839A05B6999BC63EC44372879C3B849D2AF67
        EF6C3FA550D873F0803C3677BA7CEE573FCEF653090C82906374EAB44EA14E4E
        A7D6A9D5E858F1F517F312B52008396E60BF012D572DA6C8E5175C2C25B158B6
        9F52E010846308421E292B2E71F758244F2D4EEDD32FDB4F291008C23104214F
        E9822FBAF08B2E00A381B8E8AC73F376111882700C4180734AEFBE3621EACA8B
        C6BBA3897C41108E210838818E335C71C1B8C49C87F197B971885C46108E2108
        38A90B869D2D378E4F2C21A7573072EDD482201C4310D0253AC72131EE7099BC
        63CC44A9282D0BFD2B48108E21084899CE8E9C72C158B979C214B7088CCE9E0C
        2382700C418067CE3B6368CBB8C3649930E2FCD02C0243108E2108F085DE9979
        FDB8496EDC411781D13B37838A201C4310E0BBA268D4ADEDA0630FD75D7CA99C
        3B7848A05E7582700C4140C6E965CC6BC75E22575C384E268DBC30EB973509C2
        31040159A741187FEE28B970D83972C1B07364C4E02132B0DF29191B832008C7
        100404F28E4D8DC4A45117CAFF7EEEDF7D9F3549108E89B6FAFF818C2B8D15BB
        C94EE3479CEF6ED51E79E6303967D0992CF892250401191F60D47D29AE193B51
        AEBC70BC3B4DD07F8660E03B818CEC9EAD5718748EC295178ECB89D98DB98A20
        C017FA933FB120EC64193B7C44CEDDFF90AB08023C1B0BD0CB88C93B244FEFDB
        9F573684080252A62B2EB953810993E5AA31135C14106E04019DA687FDBAB292
        0620DF5759CA5504011DD23900BA82928BC0F8CB588731C711049CE0B43EFDE5
        A609C9AB02E359A9398F1004B8C37EBD1290BC2AA05708909F08429E2A2F2995
        ABF454A0E5AA80CE150008429E6EDA72C585174B71119BB6E0ED08428E9F0AE8
        7D021A005D0371F4D0B3B3FD9410700421C7E8B4E0AB2F9AE0F675BC61DC65D2
        BF171BBFA2F308420E18DCFF54371878F3C4C93265F4584E0590328210D2F502
        7441113D0AD0108C3AF3AC6C3FA5D07A63C75BD97E0A81421042A25B6999BC63
        EC44371E70FDF849D2AF47AF6C3FA5D0DABA67A73C327B9A3C3C6B9ABCB2614D
        B69F4EA0108400D37D0EDCA9C084293279F418160D49C38EFD7BE4D1D9D35D04
        16AD7DCDBB6F528E890A53D103752A3071C4F9B6B781EE7380D4ED3978401E9B
        3B5D1E9E3D4DE6BDBE42E2F178E20F78CFB78B23842CEB5E56EEF62DD05381EB
        C65D2A7DBBF7CCF6530AB57D470EC913F35E724702B35F5D26CDF1E66C3FA550
        21085930F4D4812DA70293E5B2516358422C4D87AA8ECA93F35E7647022FAF58
        2C8D4D4DDE7CA3F21041C8005D4E5CD7114CDE367CEEA0606D541246476BAAE5
        E905335D04A62F5B28F58D0DD97E4A398120F844B72EBB76ECA5EED2E075174F
        92DEDDBAFBF5A5F246556D8D3CB7788E3B1D7871E93CA9ADAFCFF653CA3904C1
        43679D3ED8DD28A4570574EBB26861A1970F9F97F443FFC292B9EE48E0B94573
        A4BAAE36DB4F29A71184745EBCC242B9D49D0A246E1B3E7BE019DE7D67F2981E
        FE4F5BB6C01D093CB370963B3D406610842EEA55D15DAEBD38715540FF577F8F
        F4E940E04BCB17B92381A7E6CF740385C83C82D009FA935F8F0034027A44C0A9
        80379A9A9B65F6AB4BDD91C013F35F92FD470E7BF4C8481541E8C08F3FF17977
        6540C706E00D9D17A093841E99354D1E9D3B43F61E3AC04B1B2091D8F5635BA6
        6FE17875CF2FE545F180CE10D4E9C27A3AF0E89CE9B273FF5E5ED780E20801BE
        59B661B53B1D7864CE34796BCF2E5EE9102008F0D4AB9BD6BB238187674D9537
        776DE7D50D198280B4ADD9BAC91D093C3C7BAAACDFB6855734C4080252B271FB
        D6C491C0ECA9F2FAE637781573044140A76DDEB5C38D07E8E9C08A37D6F1CAE5
        2082800E6DDFB727B1BAD0ECA9B264DDEBBC5A398E20E004BB0EEC93C7E6CE70
        47020BD6BC7A6C6111E43C82005B58E4F1B92FB9238139AFBEC2C222798A20E4
        B1839547E4C9F933DD91C0CC954B5858040421DF1CA9AE92A717CC724702D35F
        59280D8D8DD97E4A08108E10F26461916717E9C22253E5C5A5F3A5AE818545D0
        368290A36AEAEBE485C5F3DC91C0F38BE7B2B0083A8520E410FDC93F6DD94217
        816716CE964A16164117118490D3318097562C76A7034F2D982987AB2AB3FD94
        10620421A40B8BCC5AB9D41D09E81E04078E1EC9F653428E2008215A5864EE2A
        5D5864AA9B34B4F7F0C16C3F25E4208210603A4370E11A5D5864AA5B58446710
        027E220801B474FD6A1701BD8760DBDEDDD97E3AC82304212056EAC222B3A6BA
        10E85D85403610842C5ABD65930B808660C3F6ADD97C2A804310324C3FF8C923
        010D021024042103746D41B7A6C0ACA9EED400082A82E0131D0C4C2E2CA28384
        401810040FE96541BD3CA811D0CB852C2C82B0210869D29D871E9BF7929B30A4
        138774021110560421053A5558A70CEB91804E21D6A9C4402E20089DA4370DE9
        CD433A30A83713B1B008721141E880DE3EACB711EB9180DE56CCC222C8756CF6
        DA81D258B15B6804C81705D97E0241460C906F080200431000188200C0100400
        862000300401802108000C410060080200431000188200C01004008620003004
        01802108000C410060080200431000188200C010040086200030040180210800
        0C410060080200431000188200C0100400862000300401802108000C41006008
        0200431000188200C0100400262A91C8B1DF01C86B1C2100300401802108000C
        410060080200431000188200C0100400862000300401802108000C4100600802
        00431000188200C0100400862000300401802108000C41006008020043100018
        8200C0100400862000300401802108000C410060080200431000188200C01004
        00862000300401802108000C410060080200431000188200C010040086200030
        0401802108000C4100600802008200E0441C2100300401802108000C41006008
        0200431000188200C0100400862000300401802108000C410060080200431000
        188200C0100400862000300401802108000C410060080200431000188200C010
        0400862000300401802108000C410060080200431000188200C0442572EC3700
        F21B4708000C410060080200431000188200C010040086200030040180210800
        0C410060080200431000188200C0100400862000300401802108000C41006008
        0200431000188200C0100400862000300401802108000C410060080200431000
        188200C01004000401C08938420060080200431000188200C010040086200030
        0401802108000C410060080200431000188200C0100400862000300401802108
        000C410060080200431000188200C0444522C77E0720AF718400C01004008620
        00300401802108000C410060080200431000188200C010040086200030040180
        2108000C410060080200431000188200C0100400862000300401802108000C41
        0060080200431000188200C044D9B80940124708000C41006008020043100018
        8200C0100400862000300401802108000C410060080200431000188200C01004
        008620002008004EC4110200431000188200C010040086200030040180210800
        0C410060080200431000188200C0100400862000300401802108000C41006008
        0200431000188200C0100400862000300401802108000C410060080200431000
        188200C0100400862000300401802108000C410060080200431000188200C010
        0400862000300401802108000C410060080200431000188200C0100400862000
        300401802108000C410060080200431000188200C01004008620003004018021
        08000C410060080200431000188200C0100400262A9163BF0190DF3842004010
        009C88230400862000300401802108000C410060080200431000188200C01004
        00862000300401802108000C410060080200431000188200C010040086200030
        0401802108000C41006008020043100098A8B0751380161C2100300401802108
        000C410060080200431000188200C0100400862000300401802108000C410060
        080200431000188200C0100400862000300401802108000C4100600802004310
        00188200C0100400862000300401802108000C410060080200431000188200C0
        100400862000300401802108000C41006008020043100010040027E208018021
        08000C410060080200431000188200C0100400862000300401802108000C4100
        600802001395C8B1DF00C86F1C2100300401802108000C410060080200431000
        188200C0100400862000300401802108000C410060080200431000188200C010
        0400862000300401802108000C410060080200431000188200C0100400862000
        300401802108000C410060080200431000188200C01004008620003004018021
        08000C410060080200431000188200C0100400862000300401802108000C4100
        60080200431000188200C0100400862000300401802108000C41006008020043
        1000188200C0100400862000300401802108000C410060080200431000188200
        C0100400862000300401802108000C410060080200431000188200C010040086
        2000300401802108000C410060080200139548E4D8EF00E4358E1000188200C0
        100400862000300401802108000C410060080200431000188200C01004008620
        00300401802108000C410060080200431000188200C010040086200030040180
        2108000C410060080200431000188200C0100400862000300401802108000C41
        0060080200431000188200C0100400862000300401802108000C410060080200
        431000188200C0100400862000300401802108000C4100600802004310001882
        00C0100400862000300401802108000C410060080200431000188200C0100400
        862000300401802108000C410060080200431000188200C01004008620003004
        01802108000C410060080200431000188200C010040086200030040180894AE4
        D86F00E4378E1000188200C0100400862000300401802108000C410060080200
        431000188200C0100400862000300401802108000C4100600802004310001882
        00C0100400862000300401802108000C410060080200431000188200C0100400
        862000300401802108000C410060080200431000188200C01004008620003004
        01802108000C410060080200431000188200C010040086200030040180210800
        0C410060080200431000188200C0444522C77E0720AF718400C0100400862000
        300401802108000C410060080200431000188200C01004008620003004018021
        08000C410060080200431000188200C0100400862000300401802108000C4100
        60080200431000188200C044D9B80940124708000C4100600802004310001882
        00C0100400862000300401802108000C410060080200431000188200C0100400
        862000300401802108000C410060080200431000188200C01004008620003004
        01802108000C410060080200431000188200C010040086200030040180210800
        0C410060080200431000188200C0100400862000300401802108000C41006008
        0200431000188200C0100400862000300401802108000C410060080200431000
        188200C0100400862000300401802108000C410060080200431000188200C010
        0400862000300401802108000C410060080200431000188200C0100400862000
        300401802108000C410060080200431000188200C0442572EC3700F21B470800
        0C410060080200431000188200C0100400862000300401802108000C41006008
        0200431000188200C0100400862000300401802108000C410060080200431000
        188200C0100400862000300401802108004C54D8BA09400B8E1000188200C010
        0400862000300401802108000C410060080200431000188200C0100400862000
        300401802108000C410060080200431000188200C01004008620003004018021
        08000C410060080200431000188200C0100400862000300401802108000C4100
        60080200431000188200C0100400862000300401802108000C41006008020043
        1000188200C0100400862000300401802108000C410060080200431000188200
        C0100400262A9163BF0190DF38420060080200431000188200C0100400862000
        2008004EC4110200431000188200C0100400862000300401802108000C410060
        080200431000188200C0100400267AECFFC5F14A62C572E9A80B64DC39E7C9B9
        670C91D3FAF493EEE5E552142D92FA867AA9AEAB93BD870ECAB6BDBB65ED9637
        65D19A55F2FAE637241E8F77FAC53C7FE870993CFA22397FE85932A8FF29D2AB
        A2BBC48AA272B8AA4A0E1C392C3BF6ED95F9AFAF9479AB56C8F6BD7BBAF44DFA
        FBBDDF9711670C39E9BFD71C8F4B4D6DAD1CADA992CDBB76CABAAD9BE5A5E54B
        64D59B1B3BF5DFD2D9AFD3D4DC2455FA75AAF5EBEC90B55B37CBCBCB97C8EACD
        9B245D7EBE8EF924127BF7259D7FF7E6893EDD7BC8476EB8556EBDEC0A292F29
        EDD2DFFDCCCF7F200B5E7FF5A4FFDE8D132E938FDD749B0C39F5F44E3FF6EC95
        AFC82F1FBB5FDED8B1AD53FF7E673FA8EDD10FEC8FEFFF93ACD8B8CED7AFB3EE
        AD2DF2A3FBFE78D2AF93ADD7319F7084709C774FB95A3EFFDE0F743904499148
        C7CB58F7EDD153BEFF897F918BCF39AFCB8F3DE5823172D9F917CA1F9E7F527E
        FDE4C35D3A1249C5B983CF94FFFBD2D7E5DB7FFAAD3CB360B66F5FE79C4167C8
        EFBEFC4DF98F3FFD469E9A3FAB537F274CAF63983086D0A2B0A050BEFD914FC9
        BDFFF8F194637032434F1B28F77DFD0729BD89930A0A0AE4E337BD4BBEF7F1CF
        4A2C5A2499785DBE71D727E5EC4167F8FA750A2211F9C687FF49469E392C275F
        C7B020082D6FC61F7CF25FE4964BA7F8F642F7E9D1537EF3857F773FD9BC70FD
        F84BE59E0F7C34A5BFBB69C73699BA6481FB3573C552776AD0DCDCDCEEBF1F2D
        2C948FDD785B97BFCE8EFD7B65F19A55EED7D275ABDD217A475F47BF0FFF7AFB
        FB43F33AE6224E1944E4B3EF7E9FBC63EC840E5FA8FAC60659B1619DACDFB645
        0E1E3D2A7A66D0ADB45CCE3CF534F753ADA337A8FE34FAC127FEC5BD99DB53D7
        502FF357AD944D3BB74B554D8D7B3CFD09D8D14F661DE358BE616DA70FB39374
        20EF574F3CF4B67FA65FEFAB777E44AE1A33BECDBFA303767A3AD495C3EBE717
        CE3DE1EBE86B70F7ED77CA4D974C6EF3EF8C3DE73CE9D5ADBB1C3C7A24F0AF63
        2ECAFB208C397B84DC75DD2DEDBE4055B535F2E7179E96FB67BCE0FEFFB6E807
        45A3F0BEABAE93C6A6A613FEFC83D7DCD8E1E1ED63B367C82F1EBD4F8E5657B7
        F9FCBEF5E17F9281FD06B4F977BFF4FEBBDC4FF923D555928E7D870FC9577FFB
        DFF2E87FFCA71BA56FEB8A4B8FF20A39547934ADAFB3FFF021F9C61F7F2DA7F7
        EB2F179E754E9B47093A76D1D6C06C185EC7B0CBEB5306FD207FE97D77B53B10
        A897133FF4FDAFCBEF9E7DBCDD1828FDA9A997E8EEFDFDAFDCE1716BB1A222F9
        5007C1F9E5630FC877FFFABB36DFC4EA95F56BE4A33FFA967B2E6DD1F18EF75D
        7DBD784163A63F5DDB13176F06DFF4F57A72DECC76FFBC4FF7138F00C2F43A86
        595E0761D2A80BDC08775BF427C5A77EFA7D7973E7F6B4BEC66D93AE90DEDDBA
        B7F9672F2F5F2A7F7CFEC94EFDF4FEFAEFFFB7DDC3F5F75F75BD1BFCF3424353
        639BFFFCC0D12372A4CABB9F9E3A2FA03DCDF1E6D0BF8E6195D74178E7A42BDA
        FDB31FDFF727D9BE2FFD092CD78CBBA4DDC940FFF5E05F3AFD382BDF582FB356
        2E6BF3CF7A5454A4350FA0B511670C6DF39F4F5FB6C8D3CB731D5DC9D973F040
        E85FC7B0CADB20E8C8F9A45117B6F9676FEDD9252F2C999FF6D7D0C35C9D39D7
        9605AFAF74A3F05DF1F4FCF6E7028C3B77A4A4EB9291A365ECD9234EF8E787AB
        2AE50FCF3E215E9A306254BB83B7ABDE7C23D4AF6398E5EDA0E2F08183A5B4B8
        B8CD3F9BF1CAE20E2F8F75D6E8A1C3DBBDC6DD99D98CC77B65C39A76FF2CD59F
        6C7A887C6A9FBEEEF29B5E976F6BD4FECBFFEFE7B2E7D0893FB55335ECB48172
        DBE42BDBFCB31716CD93DAFABAD0BD8EB9226F8330ECB441EDFED9B275EDBF61
        BA423F68EDD16BFF5D75B8B2D2DD3BD1AF67AF13FE4C2FD575D6C76E7A97FB75
        32EBDFDAE2AE08E8FF7A41076FA78C1E235FBFEB93525C143BE1CFF532E1AF9F
        7A2434AF632ECADB200CE8D5BBDD3FDB7D70BF275FA34779B776FF4C6FB84985
        5EF66BEB8DDCB3A2FDAFD555FAC1FCED338FCADFA73F9FD691D2CD974C71F30A
        54B4302A03FBF56FF779EA8D4F5FFBDD2F65F781FD39F33A8651DE06A1ACA4A4
        DD3FD3BBF1BCD0A3BCBCDD3FABAEAD4DE931DBBBFC59123BF1276EAACA4B4BE5
        F3EFFDA0DC71D575F2F0CC6972FFF417DCB97D570DE8DDC7FD3A99FD470ECBBF
        FFEE7F4EB8641BF6D7318CF236081DFDE42B2D6E3F165DD1D8C1D7E828481DD1
        09426DF1F2926092DEEEFDB9DBEF747714FEEB7FFF4876B731FA9F0E1D977862
        CECBF2D769CFBAA3925C7D1DC3246F8370A8AAB2DD3FEBDDBD87BB5F3FEDAFD1
        C1ACBE540F4D753D86AE7EADE36DD9BDF36DF32B7406A27EF8DBFB69AE03B0BF
        BAFB1E3749ABBA2EB59FC86D796DD3467962EECC0E6310E4D73117E56F103AF8
        C6EB252E9DD996AEB6E6E327E9DCFAAEDEFFAF87F2A7F6EEDBE96BF7ED99BE74
        E109F718A88B869F2BFF76C787DA1C69D73B0C3F72C33BDBFC7BA9BA7ACC78B9
        70D8D9F2A99F7D5F366E7F2B74AF632ECADB79085B3A3802B8FC82B19E7C0D5D
        45A9ABD7E13B3266F8B9ED4EB3D69B73D2A58FF1C9FFFA4EBBA706BA56C4C9D6
        7B68EDF7CF3E2E633EF17EB9F2EE4FB88556EA1B4E1C87D01B957EF9B9AFBA45
        6972E5750CB3BC0DC2EA2D6FB67BA8AA37DD8C1E363CEDAFB175CF2ED975605F
        9B7F3679F4980EEFDA6BCBAD1DCCAC5CB2EE75F182BE26CF2F9ADBE69FE925B9
        F66E0EEA884E6C7AE0A517E5EB7FF8DF76AFF8E8BA04ED7D48C3F83A8655413E
        0F2A2E5DBFBADD3FFFE65DFFD4EEC4A5AE98F7DACA76674AEACA4C9DA591BAF2
        A271ED5E8BDFB9BFED0F4C2AF41A7D7BBA97B53FE27F32D3962E94C7E6BCD4E6
        9F8D1F314A6E9F72754EBD8E6194B741500FBD3CB5DD3FD335FA7EF6997F938A
        D2B2B4BEC6DFA73FE7E6DBB74547EFFFE1CA6B4FFA18A7F4EE2BDFFDF867DAFD
        09DA991B7BBAE2F4BEFD3BFC699F8EFF7EE43E77A3545B747194F67EDA87F175
        0CA3BC0E824E7B3D7EDEFCF13FB5EEFBFAF7E5DA7197B8FBF4DBA33FA5F4DFFD
        D13F7DCEFD6F6B7AB562DAD205EDFEDDAFBCFFC36E20AFBD9B7D7461923F7EE5
        5BEE2A405BF46AC18C658BC42B3A6A7FE3C4CBDAFC331D0348770AB3DE45AA0B
        9CB645E3FBA53B3ED4E69F85ED750CABBCBDCA90F49307FE2CBFFBD237A428DA
        F64BA1E7CC3FFCE4BFCAE13B3F2A8BD7AE727740EA3DF77AC34DAF8A6EEE48E2
        BC3387DA1BB1ADFBFCFFEBC1BFCAC5679FD7E64F3FFD6975E73B6E7073FBE7BD
        B642B6EEDE29750D0D6E16DD84F3CE97C16D2C56D2FA03FAEFBFFB55BB3F39BB
        4A6F05D77525DBBB94B768CD6B6D0E0C76D553F366C9ED53DE21A3869CB87EA2
        C6575FC3B6EE5108CBEB1866791F84D7366D90FF7CF02F275D574F6F8DBDE6E2
        8929BDC87A1FFE977FF30BF9EDBFDDDBEEFDF665C5255D7EFC1FDDFF4759BBB5
        FD11F8F6E83974EB5591346EFA81D14B8B1DF9EBD467C50B7A1BF58FEFFFA3FC
        F99EEFB479F8FEB50F7C4CDEF3CD2FB91BAB82FC3AE6A2BC3E6548D2E9B9BF79
        EA115F97E3D6CB595FFAF5CFA5A6EEED77F2A53A20FAA3FBFF248FCF7939A5BF
        AF1F7CFD499CFC75C585179F34063A18A80BA57A454FD5F448A12DBABCDA276E
        7E77E05FC75C44105AFCE6E947E52BBFF985A733F18EA76BF67DECC7DF4A6B24
        5BEFD4FBFCAFFE531E7CE945C994E716CD95EFFFEDF79E3FAE8E2554D6B4BDE4
        D987AEBBB9DD4885F5750C038270DCAA40B7DCF339F9CB8BCFA4F41348175639
        D94C37BDB4F5AEAF7F417EFAD0DFBA344D56D708F8C3734FCA2D5FFB9CCC7975
        B964820E20EADC817BF5FCDA83F5218EA7571BFEDF9327DEEE9C1CA8D53D32DA
        BB2210A6D7314CD8CAAD83E9ADE3CF1D29E3CF1D2523870C737B05EA609BCE4D
        D0C1AA9AFA3AD97370BF6CDBBBC7EDE7B86CDDEA0EAF58B445CFDD7515615DB9
        49A74BEB3D14FA750A0A226EBAAEDE05A8DB9CE920D9A2D5AF75F9E8A52B5BAC
        E9DD8C3A58AA41D3056375506FF6ABAF742A04ED7D1D9DA978B2A9CE3A1670FF
        377E20679DDEF6FA14DFF9CB6F4F7A48EFF7EB984F080200C329030043100018
        8200C0100400862000300401802108000C410060080200431000188200C01004
        00862000300401802108000C410060080200431000188200C01004000401C089
        38420060080200431000188200C010040086200030516967775D00F987230400
        862000300401802108000C410060080200431000188200C01004008620003004
        01802108000C410060080200431000188200C010040086200030040180210800
        0C410060080200431000188200C0100400862000300401802108000C41006008
        0200431000188200C0100400862000300401802108000C410060080200431000
        188200C0100400862000300401802108000C410060080200431000188200C010
        0400862000300401802108000C41006008020043100010040027E20801802108
        000C410060080200431000188200C0100400862000300401802108000C410060
        080200431000188200C0100400862000300401802108004CF4D8FF8B543CF9A7
        5EBC700173EB870F66FB2984164708692006C1C4F72575042145BCE9828DEF4F
        6A22B1F75C1A4FF1EFE6AD27FFC8694258DCFA114E1FBA8223842E2206E1C2F7
        AB6B080200431000188200C010040086207411A3D6E1C2F7AB6B08420A789385
        03DFA7AE230829E2CD166C7C7F524310D2C09B2E98F8BEA48E998A000C470800
        0C410060080200431000188200C0100400862000300401802108000C41006008
        0200431000188200C0100400862000300401802108000C410060080200431000
        188200C0100400862000300401802108000C410060080200431000188200C010
        04000401C08938420060080200431000188200C0100400862000300401802108
        000C4100600802001315891CFB1D80BCC6110200431000188200C01004008620
        00300401802108000C410060080200431000188200C010040086200030040180
        2108000C410060080200431000188200C0100400862000300401802108000C41
        00600802001365E32600491C2100300401802108000C41006008020043100018
        8200C0100400862000300401802108000C410060080200431000188200C01004
        00862000300401802108000C410060080200431000188200C010040086200020
        08004EC4110200431000188200C0100400862000300401802108000C41006008
        0200431000188200C010040092F4FF013810D6A6D3F6DA660000000049454E44
        AE426082}
      Align = alClient
      Properties.FitMode = ifmProportionalStretch
      Properties.ReadOnly = True
      Style.BorderStyle = ebsNone
      Style.HotTrack = False
      TabStop = False
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
