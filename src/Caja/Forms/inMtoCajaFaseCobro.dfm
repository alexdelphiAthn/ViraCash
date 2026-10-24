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
        010400000AA008060000004E824D080000836749444154789CEDDD079C1DE57D
        EFFFEF295B551002866A8AE8BD4B148130B8E312C7C1CEC44EFCBF4E1C27F726
        7112E7DA4EEE24C4F1C429D7BE89E3343BD5F5986AAAA9068404120221AAE8A2
        8936A208D52DA7FC5FBF39B3CB22EFAE76F7CC9C3373CEE79DD7C6F64A3B333A
        7BE67B9E79CAEF91000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        000000000000000000000000000000000000000000000000002425A7ACBB5079
        BD7472416F2CA8EA924B2AD177F3B33EB4688FA17C616F297FAC8AB9E355D161
        B96AEDC0AA6A7BE4A5B992FA5B7CE548B76D5569535EB90DB57CEE1915F4B8CA
        B5FBA5EA83DDD5CA4B5BAFBE6B83A46AF8372FB8A0A05DD7E5B5F7EA8ABE127D
        2FA3B21B0835E574CE9282962EB55F40F84BE83AFFF4632A3D85138BCA9FA59A
        16A95A394CF97CAF7239A9568BFE562DFAF9E83F81F1E4466E8D9C948FFE77F8
        1EAA0E285F785C39DD5556755961B0B266F8DA150F457F39AF254BF2BA6D6945
        B991375AB664311072BAE082FC686BE053EF9E95DFB2F5A37915CECFE7738B95
        D37ECAE7A57245AAD4A45AB5AA9AFD72ECF793CF293FFA6FCEE2BF1DCD530BFF
        BFBD7B54AD856F979CFD5F3EAF424E2A162C1CEC6FADAF566BCBABAA5C5B9D3D
        EB27FAC14D5B475B0D975C621F41990A865C568360974F2F99B77D73F9D755CD
        FDAA72F96394CF1554B110D0B06AE1EF211FFEF2EC9708C4A566FF674990AB2A
        97970AEA52C1C2A15651ADFA90F2B5EFF7CD29FEC79BDF5DBA318BC1908D9BE5
        C20BF35ABB361786C14796CC2B76E57E255F2E7F41F9FC82B019570EA3DA5EF4
        9C72F65BCAC8BF0B595753ADFEE9234B87A27D00E5ACE5B0AE5A2C7EA33C5CFB
        91AE5CBA310C85A38EAAE92B5F497DFF42FA6F9C0B54D0250A5B05855F38EB3D
        855CEDAB2A1416AA5C952A154B6AEB4D20049086B64355AAE554285838D8FB73
        55A596FBD3CA15CB6EDCF1BD9C56E90E84DF3CB94BDF593DACF72DDEA37B56EE
        2BAAD53EAB5CBEA8C1E18A72B991D600902EB55A55B55A4D3D5D05D5AA65E572
        FF36B4B576A1AE5FBE61F43D9D52B9B4F717143F74E669B9AEC23773B9FC420D
        0DD51F0D2C1480B4AB55CBE1A3447777BE56ABAEAA0D573E5FBEFA8E9569EE57
        48E3276C4E175E18F617747DE4ACFF2F5FC85F9F53CDC2A09EAA8401B222177D
        700D0D0DDB7BD8DECBF69E0EFBC2EC3D9EC20FE4B45D505E175C606150EBFEC5
        255F52ADF6B57068A71A36BB681520BB6AB5B2F2F96238249ECBFDC9D0E54BFF
        66E4BD3E3AC1290572291C49A8767D64F15FE48A054F43657B16B3E903696CC9
        00D353B5C7DD9CD45DCCD7CA157FF8CAE57F163E1AA76804229FAA60BAE4924A
        4F1806794FC3C3C336804018A06DE473F9F03D3D3C3C6CEF717BAF8F996E9F8A
        0FE7545C84962C296AE9D272F72F9CF56515F35FD3507958B55A915104B4ED28
        442E575677B14BE5EA9F0C5DB1ECAF47EE81565F5AEB03217A21BA3E7CE6AFE5
        0AF9EFAA1CCE2D082789B6FAD280C4D4A7D3D7542CE46B95EAA787AFBAE37B69
        0885D63E325C1885C1F98B4FCE1573DF54B516BE4C8401DA5E2E5AFE54ADD5EC
        BD6FF7401806764FB4F4B25ADC89D8BFE965A73C2B77B5A49335345C513E5F68
        D93501CD56AD56D4DD65EFF9D5C5ADB50F6D9BBB57D0CA4EC656B51072236B13
        CAFDB93F513E77B286CBC384013A4E3E5FA8BFF7732787F7827532DABDD1A20F
        EBD6B410EA33B52AB636219FD3F5B94AA5A29A0AE17464A0D3D46AB61EA7522B
        140AD59ADE17AE7D88EE91665F4A2B6EC0FA39DFB7704E776FCFCF94CF9DC2A3
        023A5E357A74A8D6EE191A183C4FD7AFDA1CBD26B5F67E64A84FD9ACF5F4143E
        A5AE0261008C3C3A581F5A57E194F0DEB020A8DF2B4DD5DC13D66AB64251BBBE
        EB5D73B7CEDA76AF72850355B55611331101D9C23DEB53AF559E99B5B5FFA437
        6EBE795338533767B399DAB18570CE39D69B5ADBDABBF5B32A1617A86235CE08
        03A02E970FEF89627141788F582BA17ECFB4650BA1DE73FAC10FF676E737AE54
        2177ACCA15AB6BC0302330A256ABA85828A8527B70A83AEF345D73CD40D48F50
        6BAF16C2514775D9A86B5EAF7D4C5DF9C35409EBD21106C0DB586DD06AD5EE91
        F05EB19590F57B47ED15086B8FAE4817E6F3C5FCF952AE473559A96A0063855D
        EE56662DD753BF576C029FDD3BCDD1D45BB2EBBDA71E9DEBEFBB41B5EABE610A
        52020D187FF153C10AB6E65FA86DDBFEDEE11BEE7E58EDD8A958E9EE3D45F9FC
        BE51C113DA07C078ECDEB07B249FDF37BC679AA87981B0644931DF953B336C93
        54C361140201185F2EBC476CD328BB676C1564BB05C2ACEEA1F9F96AB8BD5ABD
        6F11C024AA79BB57EC9EB17B474DD2B41B73A8BFBC8FAA651B5DA8296F85E500
        4CC8EE11BB57AAE5C3C27BA7499A766316F285E35428F48675E5785C00762617
        DE2B85426F78EFB45B205454383E9C9498BA4AF4404AD5A2C98B76EF3449F39A
        EEB5FC21D1842B3A138129B17BA516DD3BCDD1B4DECB5CB57A503D7FE83E00A6
        261FEE445FBF779AA369776735A73DEA7B2C30DC084C89DD2BB55AFDDE69B740
        C8D534970E0460BA6AD1BDD36E8120F5471D8AF42100531356660EEF9D26E181
        1EC0280201C028765446474872295DAD8DE6D6D042406784412EC130A8A96DD0
        42407BCB49958A541EAAF7CEC5AA26E58A39F57449D18EA4994720A06DD90D3A
        3C5CD36EF3F3FAFCE766A9BB2767758D6351AD497D3D393DF57445FFFC9FDB54
        689362800402DA534D2A7449836F4A67BCA75BEF59DCADAD65291FD3A778A522
        CDEBCEE9C1878655D95A53CFFC9CCAC3D91F542710D0966C1D9DDDA0C55EE9EC
        33BBC230D8B2C556DEC777FCE7B75675FD2D43CAF5D61F19B21E068640405BB2
        26FCF64D351D7D5451471E51D4D0502DFC5EA3CFF9397B0C294BBBF6E774DB1D
        C37AF1858ABA67C5F728D26A6D1B08F99C6D12D5FCC80EABCB6798BD66F6DA35
        9375D257637CDDECF2ADF7BF56914E5FD4ADB9B373DAF8663D10623BBE6ABA79
        E9501804F542C9EDA13D032197D3C0D0403DCA9BF9EB2A14D4DDD3ABCCCAE564
        1B710F0E6C6FD609EBBF9B7C5EDDBDFDB1FD9EC24FF1C19AE6EF9ED7698BBA34
        6CCFF631192E4BB3FB737A767D45F73F5056A1375C7FD436DA2E10EC13AE3C3C
        ACA30E38580BF6DC478395B2724D78B8B3CD765E7BF34DDDFBD4236175F9AC7D
        6A84857ECBC39A377BAE4E3CFE14E573F9F053304976FCEE62317CDD563FF188
        72313DE05B209407A5A3171675F001056DDB1E5FDF41AD2AF574E5B4FCAE61BD
        F14655BDB3ACB091DA46DB054257A1A8C137376AF16147EBDB7FF0A74D3DF70B
        AF6DD0B97FF41B7AF2A517D5DBDF1FEE5497155DC5A2B66C7C43BFFCFE8FEA5B
        FFEB4B4D3DF77F5E7FA556AE59A559F37753B9526EF813D79E3E8A05E9AC33BB
        D55594CA65A92B86BD8FAA16063DD2E66D55AD5811353B2C68B2F36BEEBC998A
        152B43D7D7A7CB572ED5A3EB9F0D9F4D87CA6555AA95C4BEECC61F1C1ED69EBB
        CED7E2634F51757020537BD084ADAAF2B00A3D3D5A72FCA96129BFC1E1A1B03F
        24C9D7CCCEB365FB767DEFE6AB65BB1E5BDDF15A8369602D81E1A19AF6DCA7A0
        452715B56D20BEBE839ACD3DE8CD69ED63153DF644595D7DEDF5B860B2F3AE9D
        227B06EEE99BA5578397B5ECC17B473BC9AC099CD457B8C94E4E2AE60B3AEBB8
        9394EBEA56A59C9DBD68ACC0EFE0E0A00ED9777F9D72D891619815F285445F37
        7B6DECFFD6BDB45E773EF6B0BA66CD562586817C7BC9AB43D269A776698FF979
        6D1FB002BF8DBF46B57A574778792BEE1AD2C0965AD8EA6897D185B60D84FA27
        8CCD4A29EA926537AB5CAD86CFF7E11B30C12F0B057B263EFB9813B560AFBD35
        383490994008FB3B868674CA11C7EA4067EFF013BC1E72C9BD5EE1797339FDE4
        8E5B34BC65B3BABA8AAAC6F0715BAE4A5DBDD23B17776BB8529F8814D7877857
        97B4E1B5AA56AE1AB6DD4933D547D4B18110367F2B6575F5CFD2F287EFD7132F
        3C1B7EBF5EFD3D3905DBB4B752D182BDF6D1A9471DAFDAF070665E5C7BACB23E
        84F34E3835FCDF35ABE397609859685BEB63B852D695AB964BDD3DE135347A4E
        7B3418DE261D7168970E3FACA8ADDBE27B5CA886FD0739DD7F7F59CF3D57564F
        7F4E151BC46A335979CF4E4FB5A6AE6297B66FD9A44B97FD6CF44D9EA891B16F
        49E79E708A8AF97C2C9F7849B31B736878487BEDB1A7DE7DD2A2FAF712DE4767
        E4E65FB1F601AD5DF784BAFAFA1A9F87600B8D2C4FCA359D7B56B7FA7AEB3771
        5C72F628529196DE31541F29CDDA3052470742B857A6B51DBB75C5CADB35541E
        56BE5068B8C36A67C266B6A4779FB848BBCDDF5D83E5E1D43F3684C38DC3433A
        E1D023B5DFEE4EF8BAD9BF234923BF85F07733B85DC55CE31FE3F982343850D3
        BC3D725A784A970606A267FEB8861A7BA4E7D65774CF03C32AF6E7EBAD8374FF
        6A67A43D03217A44E8EEE9D1E3CF3CA9E50FDD1F7E7C273D8BD03E59ED863A70
        CF7DB4F0C8E3541B18CCC6AE7535E9430B1787FF35E9568D1DDF5A4F9BB66DD5
        2D6B56A956EC8E65BE83054265BBB4E8A42EEDB3775E43C3F14D72AA54EB2B1B
        97AF18D2D6D7A3CEC4366C1D980CBC5B67CE7ACAB76EDBA6CB57DC5AFFA46EC2
        6F71E486FAE869678D7E1626DD329929FB80B321D9B973E78D3E2E24DD3AB00E
        4BBBCB963E78AF9E78769DBABBBB1B7E7D6C84D73EB18B5DF5B9078562FD7121
        8EC659D51A9A5DD2966D35DD76C79072DDD1C8421BB60EDA3E104CAEAB4BB7DF
        BB4AAF6D7E53854221D639F3E319B9A1DE79C242CDD965D7FAE34A0A5B097613
        160A455506B6EACCA38ED5817BEE1D7E2FE9479C9159A337DCB342DB06B6A958
        2C36FC2C6ECFF343DB6B3AF0C0A28E3DBA183E3AC4F1CFC859EBA02CCDEACBE9
        A1B5653DFD74455DBDED35337147E97BA7C6FC69DDD5DBABC79E7F56B7DC7F4F
        F866B7894B49B273D88DB5EF1E7BEAECA38E5365EBD6308852D74AC88D74C255
        F4C145D69AC925FFB86043C0F9BC5E7CFD552DBDFF6EE58A5DF5CDFD1A4D8468
        21D3A2855DDA7DD7BC0687E2E93FA8D965E5EB2D90DB960F697830BE7A0A69D5
        D6816037A14D651E1ADAAE1B56DD110D77E513BF39C320CAE7F59133CEA9774D
        47419126364C3A3834A8D9F3E66BC9B12737E51AABD150C0CA471ED423CFAE53
        4F5F7FC32DB691E5C873E6E474E6695D966FB13D19562A527F6F4E2FBE5CD5EA
        3565E5BBD5F6DA3A104C18023DBDBAF9DE557AEAE517C3267DD29F8423B7D559
        C79EA4F9BBEFA9C1C181C49FCDA7C71E170AAA6CDFA6C5471CAB83F6DC27FC94
        4E3AB26C0CC63A766F5C75872A8303E1E342C3FD07E142A69A0E3BACA8C30F29
        860B99E29CAADCDB23DDB366582FBD54517777FB4D55DE519ADEA589B0C9427D
        7DFD7AF6C5E7B462EDFDE1F7925EC567ABF6EC8D7EC01E7BE9CCC38F5165DB36
        E5AD1B3C35EA83E8B57259E79E749AFA7B7B55A9343E3168A7C19CCFEBA5D75E
        D5B5F7AE50BEBF3F1AF569FC7791AB4A4B1677872301D65AC8C7D59958940686
        6A5AB172387C24B1D1510221E3C2D640F4E97CF9B29F859D7C8584171E858FE6
        D5AAFA7A7AF4CE934F0BBF570BBBBD959EB50B43839A376F379D75EC89CD795C
        88FA6EEE7CE47EAD7FE139F5F6CE522586C1FCA16169BE930FD72E6C1BB469EA
        F1CD17EAE9CD69DDD315DDFB6059455BC8D466EB163AB285505FC9575671D66C
        FDECC1D57AF69597EB93719AF4D8B0F89813B4C76EBB6B6878307C6E4F4B2094
        07B6EBF8830FD351FB1FD494D105EBBB31972DBBA57EAE4667FAD597ABA8BABD
        A6D34EE9D2DE7BE6639D8C642C5C6CDDC2D6372AEA8E79E6635AB57D208C7C3A
        DB78F7E6D75FD3352B6FAB7FAFD68C494A351D7FD0A13AF1D0A3541E184C4FDD
        FE708E754D671D7FAAE6F6CF0A97222759366D2470D66F784537DD77B772FDD6
        3AA8CF476874BF857C577D215378B3C638D5A45090366DAE69D98A61E546FA0E
        DABCFFA06302C1DE287673DA54E68B97DD1A3EBBD62B0225C76E309B84631581
        161F73A272B55AE22134157663869391FAE7E89CE34E8ABE97EC39EDF5B67E9B
        6BEF5EAE37DE7855DD363BB1C13BB7BE90A91676241E755451DBADEE418C25D6
        FB7AA5B58F96F5C4536575F7450B99D212E809EA8C40B031F66A45C5DE3E3DF0
        D4A3BAD7CA758DAC7748F2AC51EFD67B4F5AA4B973E76AA85C69F9F0A3055579
        684087BC637F2D3AE298F0D129E9895323B50F2EBBF3B6307D2C1C1B528B5A03
        C3D2E233BA3567B6D5828CE786CD45DBBEE50B39DD72FB50788EB03FB8035A07
        1D1408755D85BCB66FDFAA8B96472B20935EEC94AB0F719E74E8913A7AC161AA
        0CD963438B3F66A2C948671F7FAA66F7DA2A437B5C48EE6D608F0616386B9F5B
        A7FB1F7B44859EDEFA7C8406D80D6A4554E7CCCF69D1A9F11651AD54EA35135F
        7AB9A255F70E2BDF1F5FD86441470542F81858ECD6CDF7AC0C17D724BD4479A4
        1562055ADE73C2C2B0B85FAB03A152ADA9A7BB47EF3BF9F42810931E5DA8CF6F
        B86AE5326DB0C785AEAE58CAA495B74B271E57D482FDF31A1A8C71AA72C5A62A
        4B2BEF1ED6EB1BAAEAEEEA9CD641E70542AD16762E3EF1EC53BAF581D5F5B2E3
        D14CC2A45FE0F72F3C53DD7D7D2A875BFCB48695461B1A18D001FBBE438B8F3E
        61B4D25352461E47ACDEE46DB6B23186E1CD919BD6FA10CE3CBD3B2C5A62730F
        E25CC83430645395873B29073A3310ACABD866C76D1BDCAEEBEFBE23FC56E2C3
        6DD1B4B9130F3942C71C74A88607B635A536C3F88B99F2D2D080CE3DF664CDEA
        ED8DA54AD164466A2BDCFBE463BAEBD18754B4422831CC4CB4C7857DF62DE894
        13BB341053EBC0946DAA727F4E8F3E51D6638F9755B43D17D4593A2A1046468E
        725D3DBAF5DEBBF4DC8697EB8F0D09772E5A2BA4AB50D0476C11D1E0E068BDC2
        66B24EBDF0DF5928EAC3A79D1D7EAFD6A44BB8FDC1D5DAB8F1B5F051258ED7BA
        3A2C9D745297F6DABDA06D56443586E91DE1FCB59C15CA95EEBC6B585B3759D5
        ADF62BA2BA331D1508C6DE90BD7D7D7A62FDB3BA63ED034D59E537B2E4F73DA7
        9CA15C5FBF86879B5F49A9502C843B322DD8EF002D3CE298F07BF5FA4E49B648
        0A7A63CB66FD74E5EDCAD932E718CE6779D2DB9B0BE71E54A29A7571BC9476A8
        9E9E9C5E7DA3AA55AB86948BE77233A7E30261E48D5AAD9475ED9D4B351CF6B2
        275C03203AFEE1FB1DA093171CA6A1EDDBC28EC66619594750DBBE5DE71D77B2
        E6CD9E1D4ED64A7AED821DFDF1F5CF6AE5630FABD83FBBE1FE1AFB04B725C80B
        0E2DEA98230B61D192B09C422DA640E896EE7FA8AC279FB19989D6A252C7E9B8
        4018190A2BF4CDD2F5F7DEA5675F79A97EB3243CDA60E7DC75F61CBDEFD433A4
        260F3F86B326AD27AEAB4BEF5B78565849AA1905606D32D235563771EBE67074
        219C9D38F3838575096A43359D734657B8618A4D168AEB65B4BED54A55BA73C5
        B0AA83F5EA4BEDBE90693C1D19083655B7A7A757AFBDFAB26EB9F7AEF07B49DF
        2023CFEBE79C70AAFA67CFD1D0D050A2E3FF3B06C2C0C0761DB8D73E3AFEE043
        DF36692AC9736E1F1AD21577DD6EAB841AEEC0B497CAB674B7B907672CEA0A57
        215A232BAED6812D6D7E399A7B5018997BD0813A3210C2AA46B6FEBF50D48F6F
        BF31FCEF49CFD61B792C39FAA04374E4FE0B343C38A07C1C5B0A4DF1DCB5C101
        9D75CC493AC0D92B6CBA27B9016E3855B956D3DD8F3EA4B5CF3C15164269B475
        60377F659BB4E8C42EEDB74F215CC81457EBC066B55B55E555F794F57A50B5FC
        EAC8C7858E0D84D1C78659B3B4F2D1B57AF8E975E1ED91E46883CD01B096C95E
        BBECAAC5C79D1C6EE4D2F014DE299D37A76AA5AA7CB1A8734E5C186E37174E16
        6A42BFC9C5CB6E52351C55697098359A7B601D7D4BCEEE897DED857D160C0C4A
        B72C1FEC889A0793E9D84030DDD1662EF6C63589CE5A1C3355FADC134E55AF8D
        36D856F54DB831ADF6C1BEBBEFA5338E3C36FC5E3EE9B907B99C366FDFA69BD6
        DCAD5C0C8F0BB6CCB95E44B5A0638F29863513E3522F93263DF144395CCC54EC
        E0C705757A20842D826297AEBDFB0E0D0C0DD5F7674C301446CAB72D39EE241D
        F68E03353460FD08495739B6CD4F8774D2114787A31CE14ACF446727D6EB9FDF
        B87AA59E59FF9CBA7A7A62D946CF16199DB1B04BF3E7D9CC447BC46BFC5A472A
        F3771773BAD58AA86E8F6763D82CEBE87F7E5884D5367379FA292D7B684DBD98
        4A825399473672D9A57FB6161E759C548EF1A36E02F5C2B2D292634E8A0AC354
        13EB3F18BB36E29ABB976BD8AA533578E786EB16866A9A3D27A7D34EEB0E270A
        C53559285CC8D493D36B1B6B5A794F59853EDB88B67ECE46BF9AD45F1CBB8C5E
        767C6FE062A1A82DDBB7EAAA95B747DF6CCE793F70CA19EAB2A1B8441F536C43
        D58AE6CF9BAF0F2C3C33FC5E92231BD5688EC7B31B5ED69DF7AF0EF7C4501C53
        9507A4C38F28EA88830B61DD8358163269EC42A621BDF84C39BC1986876B2A37
        FA3554D3F090D5BF50E6D87CACCE66D5BCBABA74EB7DABF4E21BAF6A9F79BB87
        CDEAA416FD8C4C5B3EEF8453B4DFDEFBE9E9975F544F4F4F228F2AF97C4E95ED
        033AF6E813C2C7055B766CDF4B8A1580C929AF650FDDA7752FAF578F2DAF6EF0
        DF3532A578F1195D9ADD97D38637EA5BA9C531B210F64D94A595AB8735BB27A7
        AED9D6013BF3D767F45F6AAD8C9CB46DA896B9A5D31D1F08D684EFE9EDD5E3CF
        ADD31D0FDFAF0B169F97E84ED1234BA2E7F6CFD6BB8E3F45FFF6CC452AF4C73F
        9D79B44E62A5AC0F9C727AFD7B36DA90D00CC9704F937C41E54A5937DD7D87CA
        4343EA9D3527ACCE345376F94343D2FCDDF33AFDD4EEF0060B9BE33134E4C247
        839CB47D7B4D9FBAA04F1FFFC53E15F2D1F6DD0DB00098DB9DD7BD8F0EEB1FFE
        655B7DA397E6EC22188B8E0F84B01FA1CB56CD6DD40DAB96EBA3A79F531FB74F
        70686E6491D5F90B17EBDFAEBDB45E913981FE8AA14A593DB3E684E731CD58D9
        B82E78255C5A5EE8B1D64163C7B41BB63A58D34927766BDFBDF37A73933DE2C5
        F7546737A9BD2407ED5FA8DFB46AFC78D6022BD46AFACEF78735B8BDA6BE5DA2
        F26B19D1F18160C24784BE59BAE19E957AFED557C28D4B92EC7CB3C0B1239F7E
        D4717AC7DEFBE9855703F5F4F4C5579BC19EE58B450D6EDEA245C79CA8057BEF
        573F6FA293AFEAB7D31D0FDDABE75F5CAFFE79BB86AD854658A05875A4F3CEB2
        1DA2C79E255EB626A2E14FF05CD43A982BFDF46783BAF5D621F5EE9ABD21CC8E
        EE541C3B49C91E1BD6BFBC5ECB1F5C137E2FC9265E3853B25AD56E73E7E9BD27
        2C52D5367229C438E4195639AFB7B73F72DA12F558E765D2F52373F9705EC5D5
        2B6E0F5FBC46D78758760D0D48072DA86FE0BA756B7C3B32EDC88E6B8BA48A8D
        7C15EA8559ED3A2FBE7440F9DE682665C6663C1208A3CFDBF5B1A28B97DE140D
        D5255F5ACC9AD8EF5BB4387C4785B30963FA04B767F9A1F250F8B8B0E4F85395
        B491D7EBB9E0E5B0CC7A71F6EC7056E68C1F51A2BD756A8335BDF3CC2ECD9D93
        0B8B97A459D9F697ECCFE98A6B06F5F41315F5CCCA662D46026187CD5C6E7D68
        8D9E7AE9F9D15D9C9332B2B8E8F80587EA80BDF6D5A055528A2B100A050D6FDD
        AA530E3D5287EDB77FFD133BC9FE83E875BAF19E15DAB4F1357577F734B476C1
        A60FDB42A6FE5D723A6D5157F8DF53B535E63825DD66CFCAE9A9E72ABAEC8AED
        EA9A63A315CAA494BECCCD677D06369579EB9B6FE8F2E5F5CD5C926C665B93DE
        FA0C0E74F6D6D9C79EA4EAC0406C376DCE1EBE6DDFC613176ADEACD9E1B67249
        76288E04D945CB7E56DFE2BDDA5887ACCD162C6F954E3CBEA803F72F5A91A9D4
        7ED0D6A2CF0CABAEF4C3D28036BE5E5321C34BA7098448BD4550AFB279F99DB7
        85376B929D7023DBC959A194734F5EA442577763CDEC884D3C1A2E0FA96FF61C
        9D196DC492A4709D82A4879F7D4AAB9F58AB7C6F639DA3616FBFCD7ECE4B679F
        D11D162DB13A05ADAE5E3FD9A3C22E7373BA6BF5B096DE3EA4EE59D9DE039240
        D8A14479B1B7570FAD7B4C2B1F79A8BEA949925399A377F999471DAF77387B6A
        382C9C926FF85164687050C71C78B0161E7264E2FD2123332D2FBFE3366DDDFC
        A6BA1BECF9B37FFEE0404DFBEE57D089C7DBE3427A9FC3AB23559A07A51F5D32
        A0ED83D96E1D1802E16D6AEACA5B8FF6165D7EE7ADF5EF2418F7D602B1C79283
        F7DA57C71F7694AAC3430DBFF7C39F2F97B5F0E8E3B5EB9CB961A025D5D209CB
        D1D97C87F2B0AEBFE74ED5F2C5981663E574CAC9D106AE83E9ED3FA8D5A4D9FD
        39DDB274506B560FAB37C37D072352FA52B7522D5C0169FB08BCBE79938AF9A2
        2A0985C2482564BB61DF73F269E1B2E1460228EC1CAD54D4DFDBA7F79CB828AA
        6B986421947A3DCA95560865DDE3D1CAC6997F3C46132BD5D7272D3EAD6BF453
        388D0D849AAD92ECCAE9B5376A61EBA056C8D68CC48910083BB03774776F8FD6
        3EFDA46E8F564026593865E4D3FBFDA79CA1DDE6EFA1C1067677B29F1A1A1ED2
        BE7BEE136E436FC7497657E7FA7FDEB07A85366E7E5345EB506C30106C17A605
        871474DC51456DDB96DCDC834655AAB6878374C535037AF6A98A7A67676B46E2
        440884F1A63217BBC21A8437DC7DE7E84ED189FD02F2F5CE459B1D79923DF35B
        69B5199E2F67E13238A4C5C79EA8F9B3E7265AFB60A443F48D2D9BC23D2E6CA5
        502C751A2BF5D6C19C59F9B0104A1A3B136B1606BDD2D3CF5674F995832ACC8A
        1E155278ADD345208C23EC88EBE9D14DAB576AFDAB1BC2E7E4A496295B937EE4
        31E17CABC81C8D34CCE493366CAE17F2FAF0C2B3C2FF9DE43C8A912A48AB9F7C
        546B9E7854DDE1C6B18DB5A46C4BB6D9BBE474C669DDDA3E6461A6D4C9D9FA8A
        9AD4DB93D30F7EBC5D6F6EACAABB3BFB8F0A2352F892B79E4DAAE9ED9FA575EB
        9FD1CA47EEAF7F33D17A8BF58F165B843467DE7C0D0E0F4DFB93DD8E313434A8
        7D9CBD75D6712786DF4B6A65E3C8F9EC1EB8E5DE551AD8B625DC3373C681305A
        44B5A6534FEAD6C10716C2D6810D39DAF71BFD8AD3D090346F4E4E77DD5BD66D
        CB86D43DB2157D9B2010C61116210DE7E257F593E53F0B8B8C24392761E41161
        3F672F9D7DF4F1E1DA066B8E4FF5137E64F319DB88E55DC79FACDDE6EC12AE95
        48EA8A4746175EDDB45157DAAE4CE1CAC6C68AA8862B0F0BD219A716B56D6B2D
        5C13B0654B4D5B67FA15FDBC1D2BAE4FEF6AD5CAB54BDB066BFAFE8FB68513A6
        D2DAC73153AC769C646395C2ACD9BA61CDDD7A6143A003F7DABBBE9B71420FB5
        23FB3F7E60D1625DBBECE6F05162AA9D8B2365E5CD07A2A5CE560CA590E43A8C
        5C4EF73DF998D63EFBA47AFB678753BF1B11EE23D39FD37FFC7040FFF983ED0D
        3F8F5BF193ED6FD674DAA26EFDC1EFCE0AEB308E2C776E689871564E57FD7450
        6BEE2BD78719333C09693C04C2642B20BB7BB4F1B50DFAE9AA65FA9F1FFE78FD
        133BB15EAEFAE7F999479FA8D9BBEEA681A1C170A7EA9D37C3EDD3BAA0C1EDDB
        B5D75EFBE8F4A38E0FBF9BE470E348505D7AFB4DD2E0B00A730AE1EBD5D0462C
        51D59357365462598A5C2CE454DE58D51E7BE6D5DB2B0DBC595F30D5D8DE8FD2
        86D7AA2AD96AC6627D1255B50D4616C6E29161D225CAB5702ADA8F97FDACFE62
        C5514563A25F44D86CAEE9907DDEA1B38E3C4EE56D5BA6BCFF63B857E5F66D7A
        E731276AEFF9BB8FEEE5985865A45C4E1BB76CD6756B5629DFDFA74A0343A53B
        B2A2A7B6996B235FB6CD9B2D47EE9E97D7314716C34EC0B0FC6B039758ADDAF2
        E69CAEBC6648CFAF8B56330EABED10083B69C617FB7AB5E6F1B5BAEFA9C7C377
        54A55649EE31A55AD1AC9E1EBDFB9433C28FA4B048CB4EDEC536D5396C45E4F3
        3AEFE4D3C2C78E241765594BC06E2E2BB3BEFEC5E7D56DFB2EC4D8C56E97DEE8
        97191CACC9999FD73BF62B68D8862F1BBCA6BE3E69DDD3155D76D5F6B0F662AD
        4D8619774420EC844D65DEB275B32E0E9FEBEB434EC9A9BFC3161D79ACE6EF32
        5F4383433B0D046B090C0E0C68DF3DF60E7F2E3C4A8283F7B9E8EB272B96263E
        13B211B5B2B4FF0179EDB15BBEA1E5D3B9A8C689CD4AFCFE45DBB579634DC5EE
        F6DDEA8D40988A624137DDB352DB0607A2CD569279378C54193AEEA04374FC21
        87AB1C4E52DA590B21A7CAE0804E3EEC281DB2F77E09777C5ADDC4829EDFF08A
        EE78704D385723C9B51E33155E524D3AFCD0A27ABB6D73DF993F2E0C976D9831
        3FBA9AB15E99B93D5B078640D8097B6F7575F786BDE9B73F745F78B325359539
        5C5D59A968766F9FCE3E6161F8CE9EF453385C2A5C0987486DDFC6DEAEEE863B
        F72613FEBB73F5A9CA2F6D7859DD5DDD4DD9567E2613876CC3D6230FB77528F5
        F912335ECD58CC6960A0A61FFC78202CD91E6791D734221076C2C6F3BB8B3636
        BE453F5DB5FCADEF27357331BA99DF73D242ED326797B04EE1447990575E43C3
        65EDB1CBAE3AEBD87AED83C42A458F56A1AE852B1BCBD572E23B66CF946DB6B2
        EBFC82161C5008574BCE747BB64A559A335BBAE1D6413D70FFB07A3B60DFC774
        FE465326FC8CEEEAD6AD6BEED20BAF6DA84F024A281046F6973CF5B0A374E87E
        07A96C3512265B1D3834A8A30E3E4C271D7CD86829F424D86392FDBB1F7EEE69
        AD7AF801E5BB7B52F949190E0495A503F7CF6B77EB3F189E59FF41351A5578E5
        D5AA2EBB6CB0BE9AB1CD26218D87409802EBFDEFE9EFD743CF3CA5958F3C585F
        B69C600BC19ED5BB0A45BDEBA485616D83898BA6E494AB5674EEF1A7D61F6592
        DC4BC2A66048BAEDFE7BF57CF0927A6D76620A7BD6C27F7D453AFA88A2BA8BD1
        36F2333C566F4F5434755D597DB3DB7398714704C2141F1B6C0F489BC87ECD8A
        A51A2E47CDE5841F1B7EE1F425EAEEED9FB06A933D4EF4F5CFD6FB6D515483E3
        EC93A9AF99CA873B64DF78F7F2F01BF5A9DDE96B23847B39744B471E5154D946
        63ADC5909B59EBE0C97565FDE4CA0115DB6CBDC2640884A9189DCADCAFEB56AF
        D44B6FBC5AFF444EE89732D2EC3FE9902374E4FE0B343CB0FDE79ED7ED7FDB28
        C4310B0ED589071F16AD2F486A9BB6FA7C88275E7C5EB73D749F8AFDB3E2DB54
        2646235BBFEDB65B3EDC8DC9E6228473BBA6995BB5FA7C34FDC0861937D5F792
        0C472EDA7464612C02613A8F0DBDFD7AE5951775EB7D7787DF4B72C82D7C6C28
        16F5BE9316D92C9BB7F55B8CCE441C1AD27B4F5A14064192BDFD23E7BDF5DE55
        DAF4FA06F5D864A4143E2E848DB6A19A0E5D50D0FC5DADB4DBF403A51C154D5D
        79F7B0962E1B52CF9CCE691D1802613A3745546FA074DB8DD114DEE45FBE0F9E
        7EB60ABD7DE1E2A191F905A3FB48F4CFD207179D5DFF5E82D710AE95181ED665
        5667D29639D76AE97B5C18596652918E39B22BDC4D69BA795DA9D47761B22DE7
        BFF7E3ED0DCD5FC82A02619AF50A0BFDB3B5FCE1FBF5C4FAE7122DAF36F28870
        F48187E8F8830FD3D0B6ADE17E8D76235A7FC6D0F66D3AE68005E123C5D8BF1F
        B7917FDFA3CF3FAD158F3EA8AEBE59AA54E25BBB109B68C3947C8F4D48B216D3
        F46FE66A55DA65764ED7DF3CA4871FB48D72DB6F35E3CE1008D3647312ACDCF8
        A5CB6F0EFF7762A30DD1CDB84BFF2CBDFBC485AA0D0E8EB610C29B7F7050EF3F
        E574CDEAED0DCBC72765A42570F91DB76A78DBD670AD441ACB03854F50B67EC1
        C96BFF7714C2E9CAD309040B93BEBE9C5EDA50D525970F2857B07A94EA3804C2
        34855BB7178BBAF2AE65A3350B936A3E8F4C433EFBF85355E8B735FDC3E192E8
        E1E1A1B083F35D279F1E854432E71F29BC622D82AB562E1B7D5C48633BDAFA53
        6B83D2A10B8ADA755E5EE5690E11DA3FA9A75BBAE2EA413DFF4C593DB3EB21D1
        69088469B25BAFABA7578FAE7B5CCB1E5E137E9227B5BAB0BEDCBAA6930E395C
        C71DB04043DBB6851D8D83F6B8F08E8375D4FE07857F2FA9DBD3FE5D160ACB1E
        BE4F4F3CB72EFC77878198D65F8CAD5F38AC10DED8D37964B0BE065B36FDE4BA
        4A38EF6074BD42072210665495B9A84D5B36859F9A496E0A3BD26FB1D7AEBBE9
        AC134F55CD3A16ED0FCAC37AE749A786DFB7390A894D46B2399AB99C2EBFF376
        6DB5C7056B0D297DC2D18161A9D82F1D7E88F5B34CAFCD6411679D893FBC78BB
        36BF515557378180E92A766BE9BD77E9B54D6F86854C92E85C1C29646A961C73
        92FAFAFAB47D70403DBD7D5A7CF4893BAC3188577D1AB49559DFAC3B1E581DEE
        669AC63018E93FB0F50B7BEF51D0FEFB17C2E9CAB9DA1483A452EF48BC6BD5B0
        6E5B3AA4EE5D6C04A733E61C8C8716C20C9BD25676FCA1679ED4F2B5F78F6EDC
        9A8442A1FEA9BCF8E8E375D0DEEFD0E096CD3A64DFFD757A54FBA090D0D0A7ED
        56658F2CF6B8F0F0334FAABB3BDE422871AB0D2B0C833DE6E7353C5C2F6FB633
        517790B60F4ADFB561C65A7D666327231066C03E956DEBF8A1703397E5A3958D
        92B85D6CAE83CD9274E6CDD719B6A271EB562D3AFA78EDB3DB1EE1D4E524861B
        C3726351A7E6CFEE5D15F659D8E635A99B7B1019B92C1B6E0C778B9EE2FC8170
        12D2ACBC7E7AE3A01E7EB81CAE664C6B1749B310088D7C82F6F6E9BA7B56EAF9
        683397A46F980F9E7A867AFAFAF4CEE34F4DF43C23731D5E7C6D836EBCE74EE5
        BBBBA7BD1EA0A9F50F2A524F9F74C4E1F5FA89531985B5D0B0ADD85E082ABAF8
        27DBEB455373CDB8E27423101AA9CADCD7AF67D63FA3BB1EAE6FE692E4926873
        DA91C7EAC8238ED5D9C79C90E8E3C2C848C2BD4F3EAAC79E5BA71E5BBB90E231
        382BB1BEDBAE051D74407D8397A934FBEDE6B7D58C3FB96A502F3E5BED885A07
        534120CC543847201F36AD2FBEFDA6680FC8643E62463A0DAD108AF7C9CF6A9F
        F97B243A3BD1965BDBE8C65577DCAA5A7938DC012A8D6B17C6D63FD87FA4FEC1
        D0CE3788B57F4A7F5F4E8F3E51D695D70E84BB2FA5F49FD77404C24C85438265
        E5FB67EBA607EED1F31B5E4E74087224003EB6F8DC2997679F89FAC2A95C387A
        72FD9ABB948B5A07A99BAA3C56553AEA88A27A8AF63B99DA008135AE7E74F180
        B6BE19154DA5751022101A609F9ADD5D5DDAF4FA6BBAF2CEDB46BF97A4A4FB29
        46162EDD7ADF2ABDF0D20BEA4DE9CAC611E1D619DDD251875BFD03AB6D35F990
        A13D165859345BCD78EBED43EAEDF061C61D11080D083F35ED062D1675E91DB7
        D6471B129EBC93F427B51DDFBE2E8E36A7092746A77474C15E0A1B629C37FFAD
        FE83C9965A848B550BE132107DAFB4BDBDABA5CE1081D020FBF42CF6F6EA8127
        1ED59A271F4BB42A73D246D64E5899F5E50FDFA7427F7FD89790D6C785B0FEC1
        604D871C94D76EF3A3FA891317A80E5B02F366E774ED8D435ABBB6ACEE0E5CCD
        B83304421C6B1B0A456DDEBA4997DE714BF8BDA4F66D48DA48905DB9E276BDFA
        FA8670AE456A8D4E96908E39A2F856FD83090261381C66CCE98557AABAECF268
        6FC6665F73061008B1C8A95628EAE6D52BB565FBB6C42B1825B56EC15A07365A
        F2D3BB97ABD684E22F71D43FC859FD44EB3F88364F99E865B79BDF262D5D72C5
        809E7FCE8AE6D23A184FCA7FEBD9B9996C8FC3479E79524B1F5A337A6365C9C8
        52EE079F794AF73CFA90F25DE92CB3FEB6F50B4392B3474107D8FA05DBAE2D37
        F1FE0AB68DFB238F9775FD75432ACE9A7E35A54E4120C4D4D4EEEAEAD2D62D9B
        75D33D2BC2EFA5F4B17B42238F3937AFB94BAFBEF19A7ABABBD2DB17527BABFF
        E0B00505CD9B67D3BB277ECDC3CACBAA0F33BEB9A9AAEE9ECE5DCDB83304424C
        C2BA21DD3DBA69F50ABDF0FA06156D0FC8B4DE503BB0C71BDBD476EBC0806EBE
        E7CEFAE3794A77650A8DDCF8559BAE5C507757BD15F0737F2D7AAC983D3BA795
        AB86B56CD9B07A18669C548A7FEB59DCCC65961E79F629AD7AE4A17ABF4246FA
        11AC7AB48D243C68D7FED843EAEAB54D58D27BED23D591F37D391D76687DFD42
        6E9261C681ED357DB7B45DB6917DC61A6E4D4720C4BC998B1531B9F28E5BC367
        F2547FCA8E151514B96DCD2ABDF1FA6BEAE9E951B53ACD1AE64D642F6B79A8A6
        7D9CBC0ED8AF10CE4598688E82D53AB8E6FA413DBAB6AC5E8619772A23EFD80C
        884AA35B55E66BEF5D11AE14B4CEC5F47ECED685E5E40B056DDDBE5DD7DCB54C
        B265CE4AB77085E390C2C948B6298B1547D991B52066D96AC697ABBAF48A0115
        7A681B4C058110F36343776FAF5E0D5E0EFB124CDAFB11AC6563B7CA43CF3E19
        3E2E74CF9A1D4E464AEB287D3839347A490F3DB4A0DEA8FEC1D8C6D8C8939AAD
        66BCE4CA01BDB8DE0ADAD41735617204420253997385A24A4B6FAABFC0291F6E
        18F96CBDF6AEE5F532EB5D291E5D885800D83C82230EABF71FECD85563976F1D
        890F3F56D675D70FAA6B96F5E7B4EA6AB385408859B55251BEAF5F2B1F7D486B
        9F5D97E8662E71D55AD83E34A8CBEFBC4DB9DEBED4AF6CACF70DD4C2A5CEB67F
        A3EDE5B8E3E55A6BC15EF21F5E34A0CD6F56D5D543EB60AA088498D90751B73D
        936FDEA84B96D717085552FAF13452F4C4B6B87FD4CAAC87A30BE90DAF1161FD
        8377E4B5C7EE390DDA84A431EFE29161C615770DE9F665B69A31DF11DBB8C785
        40486A8B807C41D7DD73A7068606C33909691C821CB9A28B97DDACEAD0F06865
        A6548BF65FB0C785EEA21572797B85A46241DABEADA6EFFE7840B9BCADDC4CE5
        4653A99581774046F76EE8E9D3234F3DA13BD73E1836C1D33695392CB35E2868
        E396CDBA75CDDDE1AE4CA9DD84650CEB33B09986471E510CB7B01BD9B72A7C94
        284B7367E774F5F5837AFC115BCD18EDBE94DE27A0D42110922A52DA659BB96C
        D64FEFBE63E4BB4A5B9158BB4F6EBCF72E3DFBE2F3EAB64050BA8D4C48DA757E
        4E071F50D080D54FCCBFF5FDFEDE9CD6BF54D1C5B637632FEB1566824048B2D0
        48B1A89FDDBB42AF6C7C43C57005643A3E81C31B3FEA89BB7EF58AF0B1C63671
        4DE363CDF8F30F8AE1FC83B0FE41D48168FA7A72BAE827830A5EAEAAA7879185
        992010121C6DE8EEEBD7C3EB9ED45D8F3D18BE9BD3321D382CEA922FE8D9E0E5
        7057262BB39E8EA89AC4C85E8DD59A8E39B2A0AE42BD0E6218125569CE9C9C1E
        786458D7DF38A8AEFE683513A68D404888B506BABA8A1A1E1CD0752B97D7A732
        E7D2B137A20582DD5B773C7C9F9E7AE1D970E976EA4717A21B3FD79DD3918777
        A95C8D5631462B1FAD73F1C7970E68EBE65A586331EDFF9CB422101253EF48CC
        F7F7EBA7F7DCA9975F7F4D859177700B855BBCE7F32A57ABE1262C95E1FA16F3
        697F5CB097CEE61CD850E381FBD7CBADDB16F0E130E3AC9C56DE35ACA5CB87D4
        3797FD151A412024A8522EABA7B75FCFBDF0AC6E7F7075D83A687525A570ED42
        3EAF675E794937DC7B97F27D56663DFD1FA7392B9E3A54D3A10715B4EBBC9C86
        A2B905563A6DDBB69ABEF7E3EDA3159753D25593490442D2375FF4325F74FB4D
        E11BB6D55399475A022B1EBE4F2FBFF2A27A6D7662DAAB858C2C6F2E4B471FD1
        A5AEAE7A1F818D2CCC9D95D335370CEAB1B565F5CC895A070C33CE188190F048
        832D142ACC9AA55B1FB8574FBFF262A23B454FC54879B74B975940E5DF2A259F
        6256DE71B4FEC161365A53EF23E8EBB361C6AA2EBA6C40C5FE9C6A29CFB52C20
        109A516FD13673D9F8BA2E5B1655656E518F97059105C0B3C14BBAEDA1FB959F
        3D2BDC7D2AEDF5DEC24EC3C19AF67272DA7FBFFAFA058BB0BE1EE947976ED786
        57AA614762CA732D13088466084BF71475E58AA5618BC1B64A6BC5B8D8C84CC4
        AB562CD5A6375E0BCBACA77E746164FEC1B074C84145CDDF35A781819AE6CEC9
        E9BE07CBFAD9CD432AF6D36F101702A1499FCC859E5E3DF0D4A3BAFBB187C34D
        62CB4DEEC81BA99368D974555808C53632A8B718D22EFCE4AF49871D5A507777
        2E9A8C5453E9D2016DDE520BBF9792291E99472034A923AFC7A6326FDEA42B57
        2E1BFD5E33DFC3D612B0FE83FBD73DAE358FAD0D779BCA42EBC06E7E5BADD81D
        D54FB44EC359FD39DDB162582BEF1C520FC38CB122109A24BCF90B05DDB666A5
        5EDFB229DCC1B9998B89466E7E6B1DBCB9F9CD70B7A92C7CA8D6D729D4E4EC91
        D701EFB0E989D2962D357DFFA20195735139F62CFC4332824068662BA1B75FF7
        AD7B5C2B1E7DA8A98553C247967C5E83C3C3E1BE11B52C2C731EC3EABD1E7040
        3EEC3FB0CEC36B6F1CD4E36BCBEAB361C6F4D682CDA462AB2FA0D3B68EDFB269
        A36EBEFB4EBDF7C445F525D149BFA3C365C195B045B0F2D107F5E0BAC754EC49
        F7AE4C638DD64F3CB8A85D7BF37A6C7D4597FC644085FEFA5A06C42B5B1F1519
        575155F9DE3E5DBB6A99366DDBAA9EEEEEB0747BA25FF9A2FABA7BC247949BD7
        ACD29B6F6E544F57777646176A524F8F74D8C145F528A71F5DBC5DAF6EB0B268
        AC664C022D8426AA942B2AF6F4EAA90D1BF4C9BFF1B4D7AEBB45DBAD27BD4972
        FD04B73DB85AC5FEFED496741B8F153DD96D97824E38A6A83B1F19D2CF6E1D54
        B74D424A7F9E651281D074B5F0D3FAFABB9737B79C4FAD162EB4EAEAB24D58B2
        7137859328076B3AE4A0BCE6ED92D39FFFED760D6C93FA76895E3AC48E406889
        9AFAFA674761D0AC4F6B1BABAF86DBB665457DFD424D8B4EEED25D770F6BD58A
        7AD1D48CE4592611082D92B61A8B6954B6FA89B3F2DA77DF425834D5E65184D3
        986DA563FAE75365129D8A48A5B068EAF69AF63FA0A087D79675DFFDC3EAB69D
        9B098344110848A5B0A3352F7515A51B970E867B33867DA1B40C12C5230352C9
        9EA86C8DC253CF55C2FF5EE862015333D04240AA591F688B168776240201A996
        81C5986D854000308A4000308A4000308A4000D0FC40A849DBA23164FA8B81A9
        09B7B70EEF9DB60B849C3631AB0498AE5C74EFB45920E46BDA505FE04E0B0198
        12BB576CFD86DD3B6DD742C8E79FAECF3061510F3035F55959E1BDD3769D8AB9
        EA93F547861C7D08C094D8BD928BEE9D360B84822AF787F3509979064C4D3865
        BB5ABF77DA2D102AD5CA03AA546C51BB9D93560230B95A78AF542A03E1BDD36E
        81D0BDADF8A2F2C5C755C837AFFE389055D56A35BC57F2C5C7C37BA7DD0261EB
        50F7EBD5BCEE52BE60A725108049E5AB76AFD83D63F78EDAAE5371E9D27275B8
        7647F8B090AFB1A01598582DBC476CDB7BBB67962E2DB7E5D4E5C2D0C03DAA56
        5F503E5F0CB73202F0F3ECDEB07BA45A7D21BC679AA88981704161F8860F3C52
        AD5596DB1E87528E42DAC0B87215BB47EC5EB17BC6EE1DB55D201CF57041FA4A
        B55AAE5E6BD5F6955381B1066007F5BA9105BB47EAF7CA57AAF57BA7DD0261ED
        5AAB979BAF6AB7CB345CB5D106DBB7975602F036B54A786F0C571F0FEF15BB47
        EBF74EDBF521D4B464495ED75CB34DD5CAF7EAD39801FC1CBB37EC1EB17BC5EE
        9926CEDB69EE5D59ABE56CB1C6AEEF7AD7DCADB3B6DDAB5CE1C0FA16BEE16425
        A0C3D5C2A146D52ACFCCDADA7FD21B37DFBC29AC3D9F6BDE74FFE6DE88F60FBB
        F0C2DC1B37DFFC664EB56FA8AB905795D1062064F74297CD46AA7DC3EE11BB57
        9A1906A615EDF6FA39DFB7704E776FCFCF94CF9DA2A1E18AF2E18C25A03355AB
        157577D9D0C23D430383E7E9FA559BA33F696A20B4A2A95ED30517E475FDAA4D
        15E9FFD4C231D75C8D7909E858B5FA3D60EC9EB07B23BC475AB0E6A735CFEE97
        5C52D50517142A572CBB31A7DC3FA9DB36EC52D36663012953B67BC0EE05BB27
        ECDE08EF91166855675E4D471D652D8542715BED6BAAD656ABABD815369B804E
        52AD56EAEFFDDAEAF05EB030B07BA3452B825BD7BBFF159B7011E4B6DDB0ECA5
        DA60F5735275A30A6127230B9FD019AA56ECA090B7F7BEDD03762FD83D11DE1B
        2DD2FAC9004B96146DF146D787CFFCB55C21FF5D952B56452527FB3FA05DD5AC
        0550ABA958C8D72AD54F0F5F75C7F746EE85565E56EBC7FFED0558B2A418BE20
        35FDB17ABA2C0A8655A3A5803655AB55C3F7B8BDD76BFAE3B484413A02C12C5D
        5AD18517E687AE58F6D7B9E1CA5FAAABD0AD9C2A6C008EF653B330A8D87BDCDE
        EBF69EB7F77E780FA4403A0261A403E5820B0A83572EFFB35AB9EAABABABCB0A
        D2D3A780B6EA33A8E564EF6D7B8FDB7B3DEC44AC4B453980B43DA7E775C10539
        5D7249ADFB17977C49351B81A85A4F6C59B99C0D4D02D954AB95C31A07B6A62F
        97FB93A1CB97FECDC87B3D4D7B13A4A58530A21A8EBF5E78A1862E5FFA57B56A
        ED7F28977B535D052BA842BF02B2D95F50AB0D87EFE15CEE4D7B4FDB7BDBDEE3
        D15C83D484411A5B082372E14CAD4B2EA9143F74E669B9AEC23773B9FC420D0D
        55EBCF60795A0B48BF5AB51C2EDCEBEECED76AD555B5E1CAE7CB57DFB172CCC4
        A3543C26642110EA7EF3E42E7D67F5B0DEB7788FEE59B9AFA856FB6C180683C3
        15E56C68925592486DABA0A69EAE42180AB9DCBF0D6DAD5DA8EB976F187D4FA7
        54BA03C15CA0822EB11107A9F00B67BDA790AB7D5585C24295AB52259CB3603B
        E4E633F16F41BBCF2CA886DB1ADB64A362DEDE9FAB2AB5DC9F86D39177782FA7
        55366E221B9659BBD63A602AFAC89279C5AEDCAFE4CBE52F289F5F10AE172F5B
        CF63386F61A4D5908D7F17B2AE16CD97B1A2051602F9FA86C6D575D562F11BE5
        E1DA8F74E5D28DA3D3915B380371AAB274E38CF62BD8FFD8E5D34BE66DDF5CFE
        755573BFAA5CFE18E57305552A52C5263585BFA3BC72F60BCAD4BF11596807D4
        EC0328677D59B64761575834B85AABA8567D48F9DAF7FBE614FFE3CDEF2EDD18
        FEFD14F7178C278B37CBDB82419F7AF7ACFC96AD1FCDAB707E3E9F5BAC9CF60B
        8776CA160E363BB46A9B6ADB7FA9D7A6B28818390E30B15AF8FFEDDDA36AB4E9
        AAFD5F3EAF424E2A5A0858C354EBABD5DAF2AA2AD75667CFFA897E70D3D62C06
        81327F5358CFC1394B0A5ABA7474E8A6EBFCD38FA9F4144E2C2A7F966A5AA46A
        E530E5F3BD6133CE1E2DC2BF15FD7E28D484C9E4C67C6E840FA123EFA1EA80F2
        85C795D35D65559715062B6B86AF5DF150F497F3610DC4DB9656146EB3923DD9
        0D8411172AAF974E2EE88D05368761A4C3263FEB438BF618CA17F696F2C7AA98
        3B5E151D96ABD60EACAAB6475E9A2BA9BFC5578E74DB569536E595DB50CBE79E
        51418FAB5CBB5FAA3ED85DADBCB4F5EABB368CCE21B0D6C0AEEBF2DA7B75455F
        49D7BC0200000000000000000000000000000000000000000000000000000000
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
        00000000000000000000000080ACCBB5FA02D07A8EEFCE9774B8A48325ED69DF
        8ABE7693D4B3C3575E6D26F04A27B4FA1AD2A2D8EA0B404B6EFE33249D29E974
        494749DA83DF030C81D0011CDF5D20E963D1D7425A86980881D0A61CDFB5DFED
        47257D3E6A0D003B4520B419C7770B923E2BE94F24BDA3D5D7836C2110DA88E3
        BBEF96F477928E6EF5B5209B088436E0F86EAFA46F48FA9FADBE16641B81D01E
        1D863F91745CABAF05D947206498E3BBF66870A3A47D5A7D2D680F04424639BE
        6B2D825BA2C943402CDA6ED65927707CD726125D4518206E044236E7175C2EE9
        80565F0BDA0F81903D7F286971AB2F02ED8940C8DE88C29FB7FA3AD0BE08846C
        F95B497DADBE08B42F0221231CDF3D3C5A9B00248640C88E2FF2FB42D208840C
        707CB75FD22FB7FA3AD0FE08846CF8A0240B0520510442365CD0EA0B40672010
        B2E19C565F003A038190728EEF1E2269F7565F073A0381907E560815680A0221
        FD8E6CF505A0731008E97760AB2F009D8340483F02014D438194F4DB4BE95496
        3424A9D6EA0B417C0884F49BD5A2F35624AD96748FA4FB253D25E93949AF49DA
        1878A56A8BAE0B092210D2AF993314EDD3FE6649DF95F4D3C02BBDD1C4732305
        0884F46BD672E7AB257981577AA049E7430A1108E93790F063C31649BF1178A5
        8B123C0732824048BF37130C04EB0F389756014630EC988D4048828D109C4F18
        602C02A17303E1CF03AF745742C746461108E9B72E8163AE97F4FF12382E328E
        4048BF247AFDBF1378A5C1048E8B8C23103A33101851C0B80884F4B35982717A
        39F04A8FC77C4CB4090221E502AFF4A2A407633CE423311E0B6D8640C806DBCB
        312ECFC7782CB41902211B7E12F3CC44605C044206045EE9FE189BFA85988E83
        36442064C7FF8DE93873633A0EDA1081901D3F88EA1134CA769006C645206444
        E09586257D3D86431DE5F82E8F0D181781902DFF1AC310E41C490B63BA1EB419
        02217BAD84CF44E5CD1AE1C6744968330442C6045EC96A1C7EA3C1C37CCAF1DD
        5D62BA24B41102219B2E94B4A2819FDF55D29763BC1EB4895CAB2F0033E3F8EE
        1E92AC9EC141333C843D7E9C1E7825ABAC0C8468216454E0953658C5232B893E
        C3437449BAC4F1DD3D63BE3464188190618157B2D98B1F9034D372E9D6BAB82E
        6A6D000442D6055EC9FA12CE92F4C20C0F71A2A4E58EEFB2A92CE84368178EEF
        1E20E9464987CDF0105B25FDA1A47F0BBC12DBB375281E19DA44E0959E8D261C
        5D3CC34358A9F76F4BBAD3F1DDF362BE3C6404A30C6DC8F1DDCF4AFAFB06B781
        BB57D27F49BA2CF04A2FC5787948B18E0F04C7770F517B3A2AAAA310472BD0A6
        4BAF8AEA3B5A4BE4A5E811A32D0AB5065EE9C9565F435AB07393F444AB7F0919
        706CF4D5AE3AFE8371047D08004611080046110800461108000804003F8F1602
        8051040280510402805104028051040280510402805104028051040280510402
        8051040280510402805104028051040280510402805104028051040280510402
        8051040280510402805104028051ECDC245DFBD6CB0100000000000000000000
        000000000000000000000000005220D7EA0B001CDFED92F40E490748DA45D22C
        49F6BDCD92DE94B449D2F381577A89572B5904025A1500EF91F47E4967483A4E
        52610A3FBA41D2FD92564BFA89A4558157AA35E1923B068180A6717C771F495F
        90F4FF499A1FC3219F937491A4BF0FBCD28B311CAFE31108489CE3BBF608F067
        923E2FA92781530C48FA17497F1D78A52081E3770C020189727C77B1A41F457D
        0449DB28E97F055EC9CE8719201032C4F15D6B66CF8DF190B5C02B3DAB8438BE
        FB7B92BED18262BEF618F1B9C02B598724A681AACBD9F23D49E7C778BCCB257D
        4C09707CF7AB923CB5C627241DEDF8EEFB03AFB4BE45D79049ECCB90118EEF5A
        2FFC59311EB21A3DD7C7CEF1DD3F6D61188C3846D20AC777ED3F31450442769C
        1CF3E3C2C581577A5831737CF7D724FD85D2613F49373BBEBBA0D51792150442
        769C1BF3F1FE5F026160F309BEAD74D953D2758EEFEEDEEA0BC90202213BDE19
        E3B156045EE9EE98C3A04FD225927A953E8749BAD4F15DDEEF3BC10B94018EEF
        5AE7AF0DDFC5E55F15BF3F8F6EBCB45A22E98BADBE88B42310B2E14849FD311D
        6B7B34ED373651C7DD1F2AFDBEE2F8EE09ADBE88342310B2C19ECDE37275E095
        6CD1509CFE6F4686B0BB25FD53AB2F22CD08846C383EC6635D1173EBC0FA36DE
        A7EC38C3F1DD5F6AF545A41581D0598160730F6E52BC1299CB90B0BF8AFA65B0
        0302A1B31E19EE09BCD2AB31B60E6CE9F239CA9E43247DBCD51791460442CA39
        BEBB87A4BD623ADC72C5EB8F945DBFDFEA0B48230221FD0E8CF15877C575A068
        F6DF47945DA73ABE7B66AB2F226D0884F48B73D9F0CA188FF5DB6DF0FEF94CAB
        2F206DB2FE0BED047105C2E6C02B5985A18639BEDB1D553DCABA8F46E5DC1021
        103A27101E537C3E2AA91DD606EC2AE9BDADBE88342110D22F8D81F069B58F5F
        68F505A40981907EFBC6749C588A903ABEBB675431B95D9CD7EA0B48130221FD
        66C7749CB8F634F8F8144BA667C5818EEFC6399293690442FAC5B5A829AE6AC4
        17A8FDC4B9B43CD398BE997E71AE726C88E3BB7B4B6AD6D8FD33922E93F47854
        0CF82849B606C1F67688DBA992FE2B81E3660E81907E567824AEBD0B1AF5B126
        B52AAD40EB5703AF343CF69B8EEF5A3D830B25FD718A178F651A8F0C9DD342B0
        854D8D6AC62AC12F055EE9CF760C031378A5C1C02BFD490281709CE3BB6C4940
        2064824D028A83ED9E34638EEFEE1573D5E7F15C1A78A5BF9DC2DFFB1B49B7C6
        DC717B608CC7CB2C5A08E9379492D18A0B127EBFBC114D87DEA96883D73F4E60
        0564C72310D26F30A6E3ECDFE0CF7F4AC9F2A7B3343BF04AB650EB8118CF7F50
        8CC7CA2C02A17302E1D099FEA0E3BB874B5AA8E46C88366B9DAEEFC6780D07C5
        78ACCC2210D2EFCD141459F94D25EBDF02AF349361D19B62DED4A5E31108E9F7
        6A8C3DE9BB4DF7871CDF9D23E937941CEB0FF88F19FEECC3D18ECF71D823A6E3
        641A81907ED69C8E436E862BFB3E17F316723BBA25F04AEB66F2838157B2A1D4
        D5315DC76E311D27D30884F48B6BCAF1B49BFED14226AF093B5A37E2E998AE63
        B7988E93690442FACDE8D373024B1CDFB569BA53F57549BB283936F9E8EA068F
        114BD11749F668D4F10884F47B32E6E37D672A25C81DDFFDDD260C35DE167825
        9B7FD0F265DD314E00CB3402A1F302C1B632FBF164A5C31CDFFD55497FAFE4D9
        E2A5466D553C7A623A4EA6B1B829FDACD25125E61A04B64869A9E3BBB62EE076
        EB9C8BE6F29F10EDD19874CBC05887E095311C679BE2D11DD371328D1642CA05
        5EC9DEF08F2670E8D3A3F5009B1CDF7D269AEF706F93C2C0AC0CBCD2CB2959C5
        3932FCD9F108846C886B686DA2454F07B4A0532DAE1DA8E3AA9A3C1CD371328D
        40C8867BD45EEC71E1A2942D0F1F8EE93899462064C3CFD45E6C74E1F9342CEB
        4E60CD48A61108191078A5B5310EAFA5419C8B92ACAC5B1C36C5749C4C2310B2
        23EE6DDC5B65734CC38D712DEB8E7B1159A61108D971B9DA4329F04A71CD1D88
        331036C6749C4C2310B2E37A49AF2BFBBE13F3F18E4EE19A91CC22103222F04A
        564AED1265DB8AC02BC53684EAF8EEBC68C8344D1BD9641A81902DDF56B67D33
        E6E3D9CCCAB8BC18E3B1328B40C890C02BADC9F010A4ADDABC34E6639E11E3B1
        9E8FF15899452064CFFF5536FD4DE0956C4D469CCE4DF122B24C22103226F04A
        37485AAE6CB1B512FF1DE7011DDFED89B985F0448CC7CA2C02219BFE20638B71
        FE34EA148DD39218B7B97B35F04A0C3B1208D91478A57B629EED97A4BB25FD30
        81E3C6B9ADDC83311E2BD3682164BB95F07C061631FD76B4D3526C1CDFB5DA10
        BF10E321EF8BF1589946206454D4C4FDD59836714DCAD7E39C7730C63B632E9B
        6EA3372010B22DF04A4B25FD1FA5D33D09566C8E7BE39855311F2FB3D802BB0D
        38BEFB2D49BFA3F4B04A480B635CE2BC6369F8E7632C8CB221F04A4E4CC7CA3C
        1E19DAC3E7257D5FE960CB883F944418447E3DC6303077C478ACCC2310DA40B4
        83D1A76DF24F8B2FC59610BF371A05895D34F7C0CAC3C7E996988F976904429B
        B09EFCC02B7D39DA8731AE4AC4D3F1944D140ABCD2CA04CFF119497BC57C4C9B
        E885087D086DC8F1DDC3A2790AA735E99436CFE07763D8746542D1E632369BF0
        C0180FBB2EF04A07C778BCCCA385D08602AFF4B8A4C5360740D2FA044F65137A
        DE1F78A54F251906635A07718681B936E6E3651E2D8436173D77DB63C467251D
        1FD3616D3F877FB252EA51FF45A21CDF9D1DB50EE27E5C581278A5DB633E66A6
        B173539B0BBCD26074F3FE93E3BB8746537ECF8AC2619F692C4E5A1D2DBDBE26
        C1118489FCEF04C2E0A50C2E124B1C2D840EE6F8EEEE9216443B3CDB977D12DB
        12E5EDD188C10B36E61F78A5CD2DBECE5F8EAE2D4E4F075E29ABB52500000000
        000000000000000000000000000000000000A0DD510F016FE3F8EE7E92F68B8A
        A7D8D7DE512D82DE6873D5DEA80C7ADBBC7702AF14E7B6709946C5A40EE6F8AE
        DDF0EF9274725441C9BEE6B5FABAD03A044287717C7791A48F497A9FA4635B7D
        3D481702A10338BEBB6BB431AC155A3DA6D5D783F42210DA98E3BB7325FD51B4
        757CDC3509D186088436E4F8AEEDB7F17B92FE54D2FC565F0FB2834068338EEF
        2E88766DB28D5A806961E7A636E2F8AE2BE97EC200334520B409C777BF1CEDB1
        485F01668C478636E0F8EEB724FD4EABAF03D9470B21E31CDFFD0A6180B81008
        19E6F8AEED88FC67ADBE0EB40F0221A31CDF3D49D2B75B7D1D682F044276B778
        FF1E7D40881B81904D5F957474AB2F02ED8740C818C7770F8EA62203B12310B2
        C74615182E462208840C717CD7562ADA6C4420110442B67C9EDF199244206484
        E3BB3625F9975B7D1D686F0442767C82750A481A81901D9F6CF505A0FD1108D9
        795CA0BE0112472064C3B951E973205104423658856420714C70C986D39A78AE
        37243D2CE9B5E8EB0449B6906A265E8DCAB98DC7367D991D6D0A6365DF0E543C
        ECDAD7C774AC8ED336BBEFB42BC7772DB4B748B2054D49794AD2BF4ABA45D27D
        8157AA8E39FF17247D7D86C77D35F04A7B4CE52F3ABEBB9BA4B3247D38DA37C2
        2A46CFC45A499F0EBCD23D33FCF98E4620646376E283091D7E7D5499F9078157
        2A4F70FE8F4ABABC8173CC09BC9205DA743B51ADD6C39F48DA7306E7B47FCBD7
        24F981571A9EC1CF772CFA10D2CFB6574BC22A49A7065EE9BF270A83C8BA06CF
        73D0747FC00224F04AFF20E91049DF94549BE6218A51E198BB1CDFDD7FBAE7EF
        640442FAD9F375DC6E93744EE0955E9EC2DF6D7A20EC100CBF2FE9BD51DFC674
        9D286965544C06534020A49F6DC81AA7D7257D2AF04ADBA7F29703AFB439EA1C
        6C7A208CB9869BA28ED51766F0E3B67BF5ED8EEF9EDFE875740202A1F302E177
        02AF34DD1B6B5D2B03C1045EE97149EF9C6138CD927485E3BBD6D2C0240884CE
        0A84A7255D34839F6B792098C02B3D21E9E3922A33F871EB57B8C4F15D7B8CC0
        040884F48B736FC66F8F1D52CC5A2098C02BDD2AE9EF66F8E373245D4B47E3C4
        0884F4B3093C71F9C10C7FAE9140886BC2D158174A7A65863F6B7D0ADF757C97
        21F7711008E9D71BD3715E9841DF411C8130279A74149BC02B6D93F48D060E71
        8EA4DF8EF192DA0681D0392D049B7730532D1B7A9CC47F47139066EA6F1CDF3D
        20C6EB690B0442FA75C7749CFB1AF8D9E7250DA7291002AFB44192F527CC94CD
        86FC8B182FA92D1008E93714E3FC8319893A229F4D590B61648255237E850EC6
        B72310D26F4A1388A66063833F9F9A918631D634F8F33614F9C598AEA52D1008
        E947204CBE4AB3519F8916538140C804EB518F43231D708DB6106CB7A92458BD
        86383A6DDF1FC371DA022D84F40B623A8E4DDF6D55202C707CB7D1F38F6720A6
        E3FC424CC7C93C0221FD5E6A8340B0F799D575885B5C4DFDF31DDFA5662581D0
        5181D0E87C8646E7229CACF44EEBDE25A1C0CA1C5A089D130833A93C342AF04A
        6F36F8CCFE41C52FCE8945C7C678ACCC2210D2EF9914DD3C8DB412CE4DA0373F
        CEBD2A8E8DF158994520A4DFA36D12083D09EC5CFDAE188F754C8CC7CA2C0221
        FD1E6B9340305F727CB710C3755821D653242D527CF68EF158994520A45CE095
        B6C6B4CFC082189AEC4F36F8F3361FE137150F4FF19A1BF3F1328940C806DB6B
        208EDFF54929787CF9BAE3BB47367200C7777F5DD24714AFB9311F2F9308846C
        581DD371AC99DDEA40E8977495E3BB335ADFE0F8AEF51B5889F6B8CD49E09899
        432064C3DD311D6761233F1C78A5D7639A3969FB2DDCE9F8EE92A9FE80553872
        7CF7B3927E1A854ADCF2091C3373D8DBB1B302E15D8EEFE667585771C4BD316D
        3EBB972D5F767CF7CA683396E5E3EDB2E4F8AE8D4EBC3BDA61AAA1406BD222B2
        4C23103220F04AEB1DDF7D39BA891AB15B7453AD6CE0182B63DE8DFA23D1D726
        C7775747B512AD25322FEAF9B7EB4D621DC48EB637E11CA9472064C75D3175A4
        BD3F864048C2DC68DF855679AD85E74E0D9E9BB2E3F694ACEC5B19C352EA347A
        BED51790060442762C8DE938C735B2D761B4A6E14EB59FE75A7D0169402064C7
        9A196E783A9E4F37F8F3D7A9FD3CD2EA0B4803022123A2918146AA0CEF585CB4
        91F5FF57ABFDDCD3EA0B480302215BE2FA64DEDD4261A63F1C78A5871B2CEB9E
        36956838B5E31108D9629372E2F2470D6E67F63DB58F3B02AFB4A5D517910604
        4286045EE9C5182729D972DF0F34F0F33F8CB1A661AB5DD5EA0B480B02217B2E
        8FF1585F9EE90F065E2968935682F5CD5CDAEA8B480B02217B2E8AF1588B1DDF
        6D64B2936DB8DAC834E834B82EF04A8DEC4AD55608848C09BCD2D331CF03B04D
        4F67346335F04A8FB7412BE15BADBE80342110B2E93F633CD6E10D162DF91349
        59ED905B1678A51B5A7D1169422064F7B161538CC7FB0BC7779D99FC60E0955E
        CAE82ECA351B6969F545A40D819041D110D9BFC778C8DD1A2C3AF28D18D75A34
        CB3F065E6955AB2F226D0884ECFA668C5BC59B4F38BEFBA1066651FE5A8C53AB
        9B5192EE4BADBE88346A64620A5ACCF1DDDF8AB97CF8FAC02BFD7503D773B6A4
        1BA392EB6965CB9CCF883A44B1030201B1727CF713D1A4A558CAAD275004E5BC
        C02BAD68F585A4158F0C8855E095ACC3F3E3920653F6D2DAB2EDF7120693A385
        804438BE7B8EA41F37BAA7644C6CE2D18703AFF440AB2F24ED682120118157BA
        4DD2F1926E4AC154EF130983A9A1858044452B2A3F29C93A2BF76D72ABE08B81
        57BAB889E7CC3C02014DE1F8AEEDA5F03949BF2B69469BB44C23086C4EC5BF04
        5E894ACAD34420A0A96C5F8868D9F505923E28697E0C87B5895AD7463338AF0A
        BC92153CC10C100868996851D5C9D1DE0BF67558B44BB533C97BD3460B9E8936
        9EBD3B2A4FBF22F04A691BD5C8240201A9E3F86E77B4D7A23D66F44665DFB759
        4B20DA0D1B00000000000000000000000000000000905DAC659802C7776DD1CD
        82E47F1D1A0ABCD22DEA508EEF9E2BC9D63124E9C9C02BD9C2288C63465B7875
        A07F95F4CE266D2BD6B181102D8BFE42C2E7B0D591A7257C8ECCA284DA4E38BE
        6B3501ADBC78D26C59EF57D4D9BE2A6943C2E758E4F8EE99099F23B308849DFB
        58934A8AFF65E0956CCF808E1578250BC5FFD38453FD6113CE914904C2CE5955
        9FA45910FC5313CE9305FF21E9B184CFF111C777F74EF81C9944204CC2F15DDB
        816849137E0FDF0ABC921500E978D1B6705F4BF885B016DFAF74FC8B3D0E0261
        728BA3AA3D49B20A40FF98F039B2E647929E4EF81C9F4AF8F89944204CEEBC26
        FC0E7ED4E97D073B0ABC92954CFB9B844F7382E3BB47257C8ECC211026777A13
        7E07FFD5847364D10F246D4AF81C1F4DF8F89943204CC0F15D7BCE3C35E1D7FF
        51F61A1C5F544CD5368D4DD2FB123E7EE61008133B56D2AC845FFFEF257CFCAC
        FB76C2C73FCDF1DD79099F23530884899DD084D7FFAA269C23B302AF74BF24FB
        4A72A6EEBB123C7EE61008133B26E1D77E5DE0951E4EF81CEDC0366B4D523386
        95338340685D205C9DF0F1DB45D281C0BA8631088489253D2465DBA5632702AF
        F450B46D5B528E777CD77687028130E95662496F5D7E27EFC029BB39C1D7AA2B
        DA5F1204C284F64FF8B5792AF04A01EFC0295B9AF06B7562C2C7CF0C1E19C677
        5013D6E463EA6E4FF8C53A32E1E367068130710B21496B133E7E5B09BCD28B36
        2A93E02908840881303E47C97A34E1E3B7A307133C3681102110C667559292F4
        48C2C76F4736DA9094BD1CDFDD25C1E3670681D09A16C233091FBF1D253D89EB
        80848F9F0904C2F8764BF035DF4231941949BA8AD2BE091F3F130884F1CD49F0
        357F39C163B733EB584CD27E091F3F130884E607C22B091EBB9DD9BC8D4A82C7
        DF2FC163670681D0FC40D892E0B1DBBDD6629261BA5782C7CE0C02617CB3137C
        CD07133C76BB7B35C163EF9AE0B133834098787E7B5206123C76BB4BF2B59B97
        E0B133834068FE1677B410668E40481881D0FC16024B6DD31908BB2478ECCC20
        109ADF42487A9F8776661D8B59EC48CE0C02617C490E6F255DB8B59D2519A6DD
        091E3B330884F10D27F89AD34248E76BD795E0B1338340687E20304576E60884
        841108CDEFBCDA3B2AD18674CD15E84AF0D89941208C6F53C2AF79D20558DA75
        27EEBD32DA919C1904C2F83666BC445B3BB2E5C9B98C7624670681D09A403829
        E1E3B7A38332DC6F941904426B56249E91F0F1DB51D2FB6494133E7E261008E3
        7B21E1D79DDD82A6EF74256B5BC2C7CF0402A135C5381CC7770F4BF81CEDE6F4
        0C772467068130BEE79AF0DA7FB409E7680B8EEFBEA309054CDE4CF8F8994020
        B4A67E9FB9A009E768171F6AC239DE68C239528F4018DF53092FA431273BBE7B
        60C2E76817CD08CF979B708ED42310C6117825AB59F074135EFFFFD18473649A
        E3BB3619E9EC269CEAA5269C23F5088489AD69C2EBFF3F1DDFED6BC279B2EC93
        4D7A9FBED08473A41E8130B1D54D78FD7797F4FF35E13C99E4F8AE4D27FE7C93
        4EF77493CE936A04426B03C17CC1F15D16D68CEF13926C84A1199E6CD279528D
        4098D8CA26CD6F3F58D2EF37E13C99E2F8AEBD37BFD4A4D355A38EE48E47204C
        20F04A9B9BD84AF8D3A8F30C6FF99CA4639BF4823C197524773C0261724B9BF4
        0EB17A7EDF68D2B952CFF15DDB5BD36FE229EF6BE2B9528D4098DC756A9E5F71
        7CF7534D3C5F9A5938CE6FB311A54C201026B7AC094BA1C7FA17C7770F570773
        7CF757257DBAC9A7BDABC9E74B2D02611281572A37B995605BC85DECF86E925B
        C9A596E3BBB6C4F95F9A7CDAE1A8031904C2945CD2E477CA7192AE884A86750C
        C7776D4EC6E52D2853BF3AF04ADB9B7CCED4A285B0733F6DF26383394FD20F1D
        DF2DA80338BE6BBB26DD28A9158F4B3F6BC139538B40D8896838AAD9AD04F331
        49DF6DF7494B8EEFCE8A42F7C4165D829D1B1102616AFE4DAD9BC77F9DE3BB73
        D5861CDFDD3B1ADA6D5549B9D7E83F783B02610A02AF74B724FB6A057B7C58EE
        F86E5B956E777CF77849AB6C19780B2FE32781574A7A997BA6100853F74F6A1D
        9BB177BFE3BBAEDA80E3BB9FB1906B4215A49DF9718BCF9F3A49D6B96F2BD16E
        4B4F3671B1CD447E24E97F055EA9D91D9D0D8BA667DBE3D7075B7D2D51FD83FD
        6821BC1D81300D8EEFFEAEA47F50EBBD2AE92F24FD6BE095863312A6B636E1CF
        9B3C0371327F197825AFD517913604C23444C54CD625BCA5D874588BC5DED497
        065EA992D2158BF698F3D594ED5665FD060B02AFF46CAB2F246D088469727CF7
        B75A309B6E67D65B6BC19AE381570A5A7D318EEFEE119587B356C102A5CF5581
        57FA48AB2F228D08849955F179A84593687666281A57BF4AD2358157DAD0AC13
        3BBE3B4FD2FB25FD42F495E61DAE17075EE98E565F441A110833E0F8AE758A5D
        AD74AB4673F46D9CFF1E1B360DBCD2F3711DDCF15D271A323C45D2B976936564
        07E5E581573AABD517915604C20C39BE7B99A45F54B604D19E13CF455FCF47FB
        586E8FB632B3FF1C9064B323FBC67CD93A83FDA31196FDA3D651AB475B66EABC
        C02BDDD2EA8B48AB2C247A5A59F1CFF7442B14B3C289BE3AD58D84C1E4989834
        438157B28EBC2FCCF4E7D174360AF3455EF7C911080D08BCD277ACF3AE9163A0
        69FE25F04AF7F37A4F8E4068DC6F44CFE1482FDBA68D49485340203428F04AAF
        44FB07587525A4D3E702AFC4EECE534020C420F04A36B4F7E5388E85D8FD67E0
        956C5E06A680408849E095AC52F0F7E23A1E62F1389BE04C0F81107F7FC2AD31
        1F1333B3D5E689441BEE608A088418452B0F6DB2D203711E17D35693F4EB8157
        7A98D76E7A08849845750ADE1DCD08446B788157BA88177FFA98BA9C10C777F7
        8DD611D866AE689EEF045EC95659620668212424F04A2F483A5BD2DAA4CE819F
        F37D49BFCDEB327304428202AFF462140ACDDA45BA935969B9FF4149B4C61008
        090BBC9295FA5E9281E5D2596643BE9F4A63D5A8ACA10FA1B9E5C4BE2EE90F9A
        75CE0E60351F7E3FF04ADF6AF585B40B02A1C91CDFB5CD57BEDD823D0CDB8DD5
        6EF895C02B5DD1EA0B69270442EB7639BE54D291AD387F1BB0E2A89F08BC12DB
        B8C78C3E841608BCD2DAA8FCD83F44936830753FB01DB2098364D0426831C777
        DF29E9DF535A9D384DDEB02145261C258B16428B055EC9D63E1C1DED5D603B4D
        E3E7DD10B50A987D98305A0829E2F8AECD6AFC2B49BFC4EF26646B11BE187825
        B66C6F120221851CDFB5D2E65F8BD644746A85A30B25FD07730B9A8B40487F30
        FC71B4F149273CDED906ACFF2CE9EF03AFB4A5D517D3890884EC3C4AFC56B43D
        DA6E6A3FB68BD23F4ABA2C0B9BD7B6330221431CDFED91647B12DAE4A6F7A57C
        BBB4A98C1A5C2EE99F02AFB4A6D517833A0221A31CDFDD55D287257D28EA6B98
        ABF4B3DDA2AE8CBE96065E89C2B4294320B401C7776DEBB533A34554B6BAF234
        49FDADBEAEA83CFDDDD11E933FA525907E04421B727CB7104D8B3E49D289D17F
        3F54D20192ECCFE23610ED13F9B4A4FB24AD8A3697B51601328440E8208EEF5A
        9FC37E92AC9AD33E92F692648F1EBB445FB6E0AA2BFA2A44DBCB6F1BB311ECC8
        7F6E8C02C06EF86703AF649BC802000000000000000000000000000000000000
        000000000000B1A3400ADEC6F15D2BA0B25F5440C5BEF696345B52AFA4BEE83F
        BBDAE9BD1378252B730F49455E85CEE5F8AEDDF0EF8A369E3D3EFA9AD7EAEB42
        EB10081DC6F1DD45923E1695713FB6D5D7837421103AA764FBAF4AFAACA4635A
        7D3D482F02A18D39BE6B7B35FC91A43F88FA01804911086DC8F15DDB07F2F724
        FDA9A4F9ADBE1E640781D0661CDF5D20E9BB9216B7FA5A903D9DB0A370C7707C
        D795743F6180992210DA84E3BB5F96F443FA0AD0081E19DA80E3BBDF92F43BAD
        BE0E641F2D848C737CF72B8401E242206498E3BB9F91F467ADBE0EB40F0221A3
        1CDFB59D9DBFDDEAEB407B211032C8F1DD1E49DFA30F08712310B2E9AB928E6E
        F545A0FD100819E3F8EEC1D1546420760442F6D8A802C3C548048190218EEFDA
        4A459B8D08248240C896CFF33B439208848C707CD7962FFF72ABAF03ED8D40C8
        8E4FB04E01492310B2E393ADBE00B43F02213B8F0BD43740E208846C38372A7D
        0E248A40C806AB900C248E092ED9705A13CFF586A48725BD167D9D20C91652CD
        C4AB5139B7F1D8A62FB3A34D61ACECDB818A875DFBFA988ED571DA66F79D76E5
        F8AE85F61649B6A029294F49FA5749B748BA2FF04AD531E7FF82A4AFCFF0B8AF
        065E698FA9FC45C77777937496A40F47FB4658C5E899582BE9D38157BA67863F
        DFD108846CCC4E7C30A1C3AF8F2A33FF20F04AE509CEFF51499737708E398157
        B2409B6E27AAD57AF813497BCEE09CF66FF99A243FF04AC333F8F98E451F42FA
        D9F66A495825E9D4C02BFDF744611059D7E0790E9AEE0F5880045EE91F241D22
        E99B926AD33C44312A1C7397E3BBFB4FF7FC9D8C40483F7BBE8EDB6D92CE09BC
        D2CB53F8BB4D0F841D82E1F725BD37EADB98AE1325AD8C8AC9600A0884F4B30D
        59E3F4BAA44F055E69FB54FE72E09536479D834D0F8431D77053D4B1FAC20C7E
        DC76AFBEDDF1DDF31BBD8E4E4020745E20FC4EE095A67B63AD6B652098C02B3D
        2EE99D330CA75992AE707CD75A1A980481D05981F0B4A48B66F0732D0F041378
        A527247D5C5265063F6EFD0A9738BE6B8F11980081907E71EECDF8EDB1438A59
        0B041378A55B25FDDD0C7F7C8EA46BE9689C1881907E3681272E3F98E1CF3512
        08714D381AEB4249AFCCF067AD4FE1BB8EEF32E43E0E0221FD7A633ACE0B33E8
        3B882310E644938E621378A56D92BED1C021CE91F4DB315E52DB20103AA78560
        F30E66AA65438F93F8EF6802D24CFD8DE3BB07C4783D6D814048BFEE988E735F
        033FFBBCA4E1340542E0953648B2FE8499B2D9907F11E325B5050221FD86629C
        7F30235147E4B3296B218C4CB06AC4AFD0C1F8760442FA4D6902D1146C6CF0E7
        5333D230C69A067FDE8622BF18D3B5B4050221FD0884C9576936EA33D1622A10
        0899603DEA7168A403AED11682ED369504ABD71047A7EDFB63384E5BA085907E
        414CC7B1E9BBAD0A84058EEF367AFEF10CC4749C5F88E938994720A4DF4B6D10
        08F63EB3BA0E718BABA97FBEE3BBD4AC24103A2A101A9DCFD0E85C849395DE69
        DDBB24145899430BA173026126958746055EE9CD069FD93FA8F8C539B1E8D818
        8F95590442FA3D93A29BA79156C2B909F4E6C7B957C5B1311E2BB30884F47BB4
        4D02A127819DABDF15E3B18E89F158994520A4DF636D1208E64B8EEF1662B80E
        2BC47A8AA4458ACFDE311E2BB30884940BBCD2D698F61958104393FDC9067FDE
        E623FCA6E2E1295E73633E5E261108D9607B0DC4F1BB3E29058F2F5F777CF7C8
        460EE0F8EEAF4BFA88E23537E6E3651281900DAB633A8E35B35B1D08FD92AE72
        7C7746EB1B1CDFB57E032BD11EB739091C337308846CB83BA6E32C6CE48703AF
        F47A4C33276DBF853B1DDF5D32D51FB00A478EEF7E56D24FA350895B3E816366
        0E7B3B765620BCCBF1DDFC0CEB2A8EB837A6CD67F7B2E5CB8EEF5E196DC6B27C
        BC5D961CDFB5D18977473B4C3514684D5A449669044206045E69BDE3BB2F4737
        5123768B6EAA950D1C6365CCBB517F24FADAE4F8EEEAA856A2B544E6453DFF76
        BD49AC83D8D1F6269C23F50884ECB82BA68EB4F7C7100849981BEDBBD02AAFB5
        F0DCA9C1735376DC9E92957D2B63584A9D46CFB7FA02D28040C88EA5311DE7B8
        46F63A8CD634DCA9F6F35CAB2F200D0884EC5833C30D4FC7F3E9067FFE3AB59F
        475A7D0169402064443432D04895E11D8B8B36B2FEFF6AB59F7B5A7D01694020
        644B5C9FCCBB5B28CCF48703AFF4708365DDD3A6120DA7763C02215B6C524E5C
        FEA8C1EDCCBEA7F67147E095B6B4FA22D28040C890C02BBD18E324255BEEFB81
        067EFE8731D6346CB5AB5A7D0169412064CFE5311EEBCB33FDC1C02B056DD24A
        B0BE994B5B7D1169412064CF45311E6BB1E3BB8D4C76B20D571B99069D06D705
        5EA9915DA9DA0A81903181577A3AE67900B6E9E98C66AC065EE9F13668257CAB
        D5179026044236FD678CC73ABCC1A2257F2229AB1D72CB02AF7443AB2F224D08
        84EC3E366C8AF1787FE1F8AE33931F0CBCD24B19DD45B966232DADBE88B42110
        32281A22FBF7180FB95B834547BE11E35A8B66F9C7C02BAD6AF545A40D81905D
        DF8C71AB78F309C7773FD4C02CCA5F8B716A75334AD27DA9D51791468D4C4C41
        8B39BEFB5B31970F5F1F78A5BF6EE07ACE96746354723DAD6C99F31951872876
        402020568EEF7E229AB4144BB9F5048AA09C1778A515ADBE90B4E29101B10ABC
        9275787E5CD260CA5E5A5BB6FD5EC26072B4109008C777CF91F4E346F7948C89
        4D3CFA70E0951E68F585A41D2D042422F04AB7493A5ED24D2998EA7D22613035
        B41090A86845E527255967E5BE4D6E157C31F04A1737F19C994720A0291CDFB5
        BD143E27E97725CD689396690481CDA9F897C02B5149799A08043495ED0B112D
        BBBE40D20725CD8FE1B03651EBDA6806E7558157B28227980102012D132DAA3A
        39DA7BC1BE0E8B76A97626796FDA68C133D1C6B37747E5E957045E296DA31A99
        442020751CDFED8EF65AB4C78CDEA8ECFB366B0944BB61030000000000A085E8
        54CC00C7776725FCBB1AA6971E86DD9F53CEF1DDA3253D94F0693E1B73C11564
        146B19D26F46454BA6E16549DF4FF81CC8080221FD6CC24E92FE95C7058C2010
        D2EFE0848FFF93848F8F0C2110D26F9F048FFD0CCB82311681907E36C290949F
        25786C641081907E49162CB56DDD81510442FAC5596A7D470402DE8640483F5B
        E597145B460C8C2210D2CFE6092425CEEDE0D0060884F47B3EC1636F4EF0D8C8
        200221FD929CB64C9521BC0D81907EF72678ECD9091E1B194420A4DF2D091E7B
        D7048F8D0C2210522EF04AD6A9B83AA1C31F9AD0719151044236FC20A1E3DAD2
        6A601481900DDF8DF61E88DB79091C131946206440E095DE90F4ED040E7D8EE3
        BB742C621481901D7F29E9B504164EFD4ACCC744861108D96A257C2181437F21
        DA41092010B224F04AD69710F76EC6B67DDA6FC77C4C64142D84ECF98CA43531
        1FF3AF1CDF3D3CE663228308848C89F636B4DD931F8DB92FE152C77799A8D4E1
        0884EC4E567A67CCD39A8FB12DD51DDF9D1BE33191310442B643E16C4997C578
        D8D325DDE9F8EE81311E1319C2CE4D6DC0F1DDFF29E9FF46DBA7C761A3A4DF09
        BCD20F633A1E3282406813D1A7FAB7247D30C6C3DE20E98B5466EE1C04429B71
        7CD7FA16BE26E9B4980E599574751436B7045EA916D371914204429B727CF71C
        497F188D4814623AEC7A49975BE7A3A4158157A2E2529B211032C2F1DD4366F8
        A3FB49FAB36854224E95A86AF3C3D110A8957A7B45D2AB9206A26A4CF677522F
        F04A4FB6FA1AD28229ABD9F184D2C55A1DC7455F59C7076384614700A3080400
        A3080400A3080400A3080400A3080400A3080400A3080400A3080400A3080400
        A3080400A3080400A3080400A3080400A3080400A3080400A3080400A3080400
        A3080400A3080400A3080400A3080400A3080400A3080400A3080400A3D8B929
        3B6C3F4500000000000000000000000000000000000000000000000000000000
        0050978BFE133BE1F86E97A443251D2069AEA48AA48D92D6497A3AF04A355E44
        641D813009C777AD08ED2F49FA55494B24CD9AE0AFBE26E90649DF0DBCD28DC9
        FCAA80E4110813707CF70392FE41D2C1D37C4D574BFA9DC02BAD8CF97A0E89F3
        78784BE0959EE4F5A8A30CFBF8AD82FF27E9773533274BBAC3F1DD3F93F4B518
        1F259E88E938F8797C3046D8A8E5E7C3E0470D84C1D8D7D597F42F8EEFF26643
        6610086FF797922E88F1F5FD9CA42FC7783C20510442C4F1DDF74AFADF09BCC6
        7FE1F8EEE2048E0BC48E40A887418FA4FF4AE859D21E43BE1F3D8E00A94620D4
        7D5AD2DE09BECE074AFA6482C70762D1F1811075FA7D41C9FB221D8C48BB8E0F
        0449C7493AAC09AFF551928E6EC27980192310EA33109BE59C269E0B98360241
        3A5BCD432020D5080469419B9E0B98360241DA4DED792E60DA0884E6DEA4BB37
        F15CC0B411085241CD6313A080D42210EAB50C9A655B13CF054C1B81D0DC4078
        A989E702A68D4090D6AB7928C481542310A4654D7CBDEF6EE2B980692310A4DB
        D43C567711482D0241BAA749CFF6CF488AB5CE2210B78E0F84C02B95257D53C9
        FB474AB523ED3A3E1022FF2A6973C21D97FF9CE0F181581008F532DC6F4AFA03
        25E7B702AFB43DC1E303B12010228157FA0F4917297E7F1B78A56B13382E103B
        02E1ED7E33DA68252EFF4DD5656409813046E09536497AB7A45B62786DFF5AD2
        67E84844965009780781577A232AC96EFB2978335890F4ACA4DF0EBCD2758A17
        8F1D481CBB0A4DC2F1DD7D25FDBEA44F49DA6B27AFA53D6A7CC71E1302AF3414
        EFAF09680E02610AA26AC9C74A3A312AA93E27DA0EFEF568CFC59581577A31F9
        5F170000000000000000000000000000681F8EEF9EDCEA6B009A89A9CB93707C
        B716954EFFB17D055EE9E1E6FD6A80E62310761E08633D34261C9E4AF6570334
        1F8130BD40D8B15AB385C34581576AE6662F406208849907C208FB3B7744E170
        49E09582F87E3D407311088D07C258B624FAD6281C2EB7622B8DFD7A80E62210
        E20D84B186A29D9A2C1CAE0ABCD296068E05340581905C208C6525D8AF89C2E1
        A781571A88E9B840AC0884E604C258B621CC155138DC1478A5E104CE01CC0881
        D0FC4018CB4AB05D1685C36D8157AA267C3E605204426B0361AC976D94220A87
        15946F472B1008E909841D4BB95F144D805AD3A26B40072210D21908633D3E66
        76E423ADBE18B4370221FD8130D60363C2E1E9565F0CDA0F8190AD40186B5514
        0E17075EE985565F0CDA038190DD4018612313CBA370B834F04A1B5A7D41C82E
        0221FB81305659D2CFA270F849E095DE6CF505215B0884F60A84B106255D1F85
        C3D58157DADAEA0B42FA1108ED1B08636DB35088C2E1BAC02B5958003F8740E8
        8C4018EBCD3153A76F0EBC923D66002102A1F30261AC57C74C9DBE9DA9D32010
        3A3B10C6B2EDEC2F8EE638DCD5EA8B416B100893E8B04018EBE93153A7EF6FF5
        C5A0790884497470208CF5E898D9918FB5FA62902C02611204C2CFB96F4C61D9
        67127C5FA2450884491008935A3966EAF44B31BF2FD12204C2240884294F9DBE
        7DCCD4E9D7627A6FA2050884491008D366731A6E8AC2E18AC02B6D6AE0BD8916
        201026412034C40AC95E1785C3358157B2D99248390261128EEF5E28E983926C
        D3575EAB99B375145745E1707DE095AC443D528837F91438BEBB57140CF6F52E
        49B392FFD5B4AD8DB612330A879F055EC936B7414A1008D3E4F86E8FA473C704
        C4FEC9FC6A3A82D56EB8340A876514966D3D02A1418EEF1E1705C387242D9494
        8FE757D371D68F993A7D77AB2FA653110831727C770F491F88C2E1DD92E6C679
        FC0EF2D498A9D30FB6FA623A09819010C777BB252D895A0FE74B3A38A973B5B9
        B563A64E3FD1EA8B697704429338BE7BD4987E873324159A75EE3672EF98A9D3
        CFB5FA62DA1181D0028EEFCE97F4FEE8D1E2BD92E6B5E23A32CC169DAD88C2E1
        92C02BD9AE57880181D0628EEF16252D8EC2C15A0F87B5FA9A323875FAD6281C
        2E0FBC92ED978919221052C6F1DD43C784C359922C303035B693F68D51385C19
        7825DB691BD34020A498E3BBBB487A5F140EF688B15BABAF296353A7AF8DC2E1
        DAC02B6D6FF50565018190118EEF5A27E4E9635A0FD64989A9D9622D86281C6E
        08BC92B524300E0221A31CDF3D684C38D8F0A60D7362E7DEB0BE86281C6E65EA
        F4DB11086DC0F1DD3992DE1385834D8C725A7D4D19F14A54C3E1775A7D216941
        20B419C777F3D114EA91E9D436B51A9308BC12F7418417A2CD39BEFB8E31E1F0
        4E49BDADBEA6B42110DE42207410C777FBA33516238F16FBB4FA9AD28040780B
        81D0A11CDFCD45855F46A6539FD4A9EF0702E12D1DF906C0CF737C77EF318F16
        E749B2D644472010DE4220E0E738BEDB1B1581F950B452D3FA21DA1681F01602
        013BE5F8EE09631E2D16B6DBFB8640784B5BFD62913CC7779DA8D5F0C168EEC3
        ECACBFEE04C25B0804345A04E69C318F16367B32730884B71008888DE3BB478F
        994E7D5A568AC010086F21109008C777778BE63A7C302A02632B37538940780B
        8180C439BEDB15D576383F5AC67D649A5E7602E12D04025A359DFABDD1D0E6E2
        560F6B12086F21109096805824E944492744B51EDED1AC3E0802E12D0402D2BA
        62F31D51EBE13B49CF9A2410DE42BD3EB494E3BB7DD164A7D3A2A5DAC7483A82
        822FAD4120A0151D8C6746939ACE8B1E13EC7B48010201CDDA3DFBFC310BA732
        3FBBB15D11084884E3BB278E99A4740AFD55D9402020CEBE80B12B24F7E3A5CD
        1E020133E6F8EE3E631E05DE25C9420119462060BA55964E1AF328D0B15596DA
        158180A9D4613C6FCCA3007518DB1881809FE3F8EEBE3B9453A3527387201030
        F22870CA9847011B21400722103A94E3BBB3A28EC09147019B2B800E472074EE
        A62D3644D8D3EA6B42BA1008EDFF28B070CCA3C0F1ADBE26A41B81D0661CDF9D
        1DEDCEF4A1A862D19EADBE26640781D0061CDF3D60CCA380153DE55100334220
        64B75EC0A2318F02C7B6FA9A32ECC9565F409A30CB2C231CDF9D132D191E7914
        D8A3D5D79461CF4ABA58D24581575ADDEA8B49130221C51CDF3D68CCA3C0128A
        8634E40549974421B032AEDF51BB2110D2F72870FA984701DBE70033F78AA44B
        2D04242D0FBC528D17737204428B39BE3B37AA40FCA1A844F9EEADBEA68C7B55
        D2E55108DC1678A56AAB2F284B088416707CF7E0318F02675342AC611B25FD24
        0A819F055EA91CC7EFA91311084DE0F8AE95133F63CCA340AA362AC9A8CD92AE
        8C42E0C6C02B0DB5FA82DA01819010C7776DEBB2F78D7914989FD4B93AC85649
        D74421705DE095065A7D41ED86408891E3BB878E7914B0ADCB98E7D138BBE97F
        1A85C0358157DA16C331310102A1018EEF16A392E2238F028737723C8CB2E6FF
        0D51085C1578257B3C40131008D3E4F8EEAE631E05EC3FED7FA371D611787314
        0257045EC93A0AD16404C21438BE7BF89847016B11F028108F8A0D0D46217079
        E0955E8BE9B898210261128EEF7E230A01EB1B403C6C5EC0F228042E0DBC52C0
        0B9B1E7CD24DEE0F9BF47B687736437065140297045EE9C5565F10C647202049
        F744217071E0959EE3A54E3F020171BB3F0A015B44B48E97375B0804C461ED98
        10788C9734BB0804CCD4136342E0215EC6F64020603A9E1E5358640D2F5DFB21
        10B033EBC784C02A5EAEF64620603C2F8D292C722785453A078180B185452E8B
        42602985453A1381D0D9DE185358E4160A8B8040E83C9B76282C32DCEA0B427A
        10089D5358E4EA318545065B7D41482702A17D6D1F5358E45A0A8B602A0884F6
        32B84361912DADBE20640B81907DC33B141679B3D51784EC2210B25B58E4D631
        85455E6FF505A13D1008D92A2CB26C4C61910DADBE20B41F0221FD8545568C29
        2C62330881C41008E974F798C222CFB7FA62D0390884F4B86FCC72625B550834
        1D81D05A0F8F0981C75B7C2D0081D0028F8F09010B042035682134C7BA313505
        ECD1004825022139CF8F0901EB2404528F4088970D0B5E123D12ACA0B008B286
        40685C30A6B0C8320A8B20CB088499B1A9C2974721706BE0956C2A31907904C2
        D4D9A2A12BA210B899C222684704C2E46CF9F0555108DC406111A08339BEDBD7
        EA6B000000000000000000000000000000000000000000000000000000000000
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
        0000000000000000000000000000000000000000000000000000000000000000
        00000000000000000000000000000000000000000000000000000000684BB956
        5F409A39BEDB2FE97D92DE29E92449074ADA55528FA401495B24BD28E92949F7
        4AFA99A4558157AA4DE31CA7493A5F92FDE72192F6888EFFBAA440D2D3926E90
        745DE095D64DF3FAEF9174F214FE6A35FAB76C94F498A435927E22E9AEA9FC5B
        A6719EB2A4CDD1791E1D394FE095ECE71B92E4EBD84908847138BEBBA7A42F4B
        FA754973A6F99ABE2FF04AF6C69B94E3BB9F94F47F241D398D635F2DE98F03AF
        F4F054FEF2346ED489D80DFB7B81575A9EF079EE93F43B8157BA63BA3FD88CD7
        B19310083B707CF737257D7D064130E2FD8157BA7EA23F747C776F493F9274CE
        0C8F5F91F45792FE6C679FDE31DCA8239FEABF1E78A5EF257C9E6A749EFF9ECA
        5F6EE6EBD849F2ADBE80B4707CB7E8F8AEBD19BFDD4018ECEC1C47495ADDC09B
        D8142479927EE8F8AE3589935694F4EF8EEF1EDF84F7E27F38BE7B6A9BBE8E99
        60BFEC8EE7F8AEBD194B927E29A917C3F1DDBDA23E06FBCF38B892B6478F35D3
        B556D283D17FEF95B4BFA4E3A29B643C5D51B3FCE3D33CCF3351FF8AA263DB73
        FD11939CC77E0F7F23E9DC8CBC8E6D8740A8FBDA14C26050923D4BDF2F6943F4
        B8352F7A83DBA79A3561C7E5F86E210A9CC9DEC4F6A6B4478D47246D8AFEAE75
        664EF6C9FC19C777974DB5993D8675E4793B5CA35DFF3F4AFAC5097EE67CC777
        73D36C5EFF709CF3D8BFEB6F25FDEA043FB3C4F1DD3D02AF64AF71DA5FC7B6D3
        F181E0F8EED992BE38C96BB4397A037F33F04AF6DF7F8EDD2892165AC798A4E1
        71FECA1FECA479FB1D495F0ABCD2C609AEEF3F251D3CC1CFFE83E3BB57065EE9
        0D3520F04A2F39BEFBCB51EBC17AE97764232EBB497AB5C1F3BCECF8EEA7251D
        2469F104AD041BD1B9218BAF63D67574204437F23727E95CB5E6EE8702AF649F
        36138A3E35EF8ABE763C8735C9FFF7243F6EBDDD7F3DC9B16F777CF72C49CB26
        78335B7FC7EF4AFA0B3528F04AC38EEF5E1F05DB7862E97CB3D7CBF1DDFF9A20
        108C8DF264F675CCB24EEF547CBFA41326F833FBA478F7CEC2600A3E63EFE709
        FEEC8AC9DEC4633FBD25FDDA2437E4EF59A7A8E23134D1654463FA71B1FE85C9
        461CB2FE3A6652A707C2FF98E4CF7E37F04A3699A5511F9FE44D6F4DE02909BC
        D29D92AE9AE08F778B61D86FC444C7B934E6E1B9C94672D6B7C1EB98491D1B08
        8EEF76452D84F13C29E9C7319CA3379A39379E1B02AF34D9A7E478BE3BC99F59
        C759431CDF7DAF75EA8DF347AF471DAF717AD7249DB7ABB2FC3A665927378F6C
        986DD6047F7659E0956CE24AA3EC4D3CD118F78D3338DEED93FCD98C3ED9A226
        F201D1F09B0D2D8ED76BFF4B81577A6126C79FE09C474F32CCF7A3C02B6DCBDA
        EBD82E3AB68520C9DE9413591AD339EC469B88AD7D9896C02BBD16AD9D188F8D
        F14FD5FF717CD73AF66AD1A888B588BE1ACD4918CB86584F0FBCD2AD8AA913D7
        F1DD0F4BBA4552DF387FC586092FCCD0EBD8763AB985B0DF349F6167C29E4935
        4927DD4CD8B0DF3EE37C7F77C56753D4DBFEF70DB6947ECDF1DD9161427B445B
        30C975DA14E95F09BCD2F36DF43A664E27B71026EBD48A6B2C7AFE247F36EE9C
        862998E8E76C9E405CE646EB399E747CF78B0D4CED7D87A433A3AF8593DC6CAF
        448BC2AE6DB3D731733A391026FBE49BA86F61BAEC536F22B36778CC89DEB071
        0E098E38309A4ABCCAF1DDC95A5433F542D412392CF04A361DB95D5FC7CCE8E4
        40B0E7484D7562CC0C4D36AB6FA64DD35D6770AE1D3D2EE9CA315F365967BCA6
        FAD80ED81B1CDF9DE9CD379195B6A029F04AF68892C5D7B1ED74721FC264BFF8
        D376D2133D553F371F7F0C9B1035ADF5FF8EEFCE9DA4836D3AA30097ECB8C620
        3ABECDE4FBBB097ADA8F8A6A44FCDCCF35E063F638E1F8EE7B02AF34B2D82A4B
        AF63DBE9E4168255069AC887623AC7643DE0E7CDE078674D32CDDA3EE51B1278
        A565D14AC3893A557F339AEE3D557F1978A55CD429F87B5195A91DD9E2A39F46
        4569DAE275CCB24E0E045B4F3F515375B1E3BBA7377A82C02B3D21E9B909FEF8
        83D1CABFE9B0E9BB13896568306ABEFF709221B9836770CCD703AFF4AD68DAF0
        78F68BEA12E4DAE575CCAA8E0D846838EDB649FE8A15EB88A373F1BA09BEDF15
        F5E44F89E3BBD653FFD109FE784DE0959E557C261AA39FECD97BA702AF7489A4
        7F9BE493FE736DF63A664EC70642E49F26F933ABD177A5E3BBBB34788EBF9B60
        B18EF9A4E3BBFF6B6707707CD70A98FC609266AE95028B932D4D5642BDF05F9A
        64EEC05F4FF2699FC5D731733A3A1002AF74E38EF3E6C7F9D45AEDF8EE27A2AA
        4A13AE8B707CF73CC7772FB2FFDCE11CD65771F124E7F896E3BB7FE7F8EEB8F3
        221CDF3D3F2ACC624380E3B1D5989729268EEF5AAFFDA726F8E381463BDDA27A
        037F3CC11F5BF8FEFD043F97A9D731AB3A799461C4E7A3A9CADD13FCF9C1D142
        A77F727CD7C6CA6D05E4C6689AEFEE51EFFB2963263AD93AFF1DFD6154D863BC
        4F3FFBB4FA7D49BFE1F8EE75D190E040348BCE16001D3AC9B5DBDFFB54E09526
        FAE49C16C777ADC7FEBF2719CABB39F04AE3750C4ED77F458F073659694716BE
        FF3541E5EA4CBC8E5946D5E5FA8DF0DB92FE39A6D774DCAACBD190DE2D3187F0
        6703AFF4EF33A8863CB6A6A2A2703B340AB7C9BC33F04AB74DE33C36CA30EE30
        A5E3BB0BA37908E3BD076DDF846302AFB43D0DAF6327E9E84786118157FA1749
        7F1E5745A009CEB12CAADBB83586C355A27A0D337D13DB8DFF89315F1F994218
        FCDB7861305381575A35416B4AD19A873FCDC0EBD876088448E095BE1215E1B0
        1D8C121178259B15689F70CF3638C3F2238157B282A8CD62C390D68A8A9BF525
        BC39C19FFD51546EBD9D5EC7D42310C608BCD2A5D1A7D3D767F809F4E4CE564A
        065E694D54A9F90BD39C26BB2DEA053F7892454071B30EC45F0BBCD2A762AA0F
        F13681570A2658EE3C329CF8ED49E62664E975CC0C3A15771095FFFEDF8EEF7E
        359AB5775E54667D8FA8B36D56D409B535BAF9ED79F76E9BD3103583772AEA98
        FB7F8EEFFE73D44966959B16456B28F688827A43B40AD0B639B34EB29B02AF94
        58EB25AA54B431FA37D9BFC33AF5AE492208C619FAFD0DEB3318E7CF16478554
        FE3D43AF23000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        000000000000000000000000000000000000000000002805FE7FF186C538F14E
        9E160000000049454E44AE426082}
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
