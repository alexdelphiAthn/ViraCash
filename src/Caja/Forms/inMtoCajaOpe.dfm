inherited frmMtoOpeCaja: TfrmMtoOpeCaja
  Caption = 'Operaci'#243'n de Caja'
  ClientHeight = 405
  ClientWidth = 1353
  Font.Charset = ANSI_CHARSET
  Font.Height = -19
  OnClose = FormClose
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnKeyPress = FormKeyPress
  OnShow = FormShow
  ExplicitWidth = 1371
  ExplicitHeight = 452
  TextHeight = 21
  object pnlUp: TPanel [0]
    Left = 0
    Top = 0
    Width = 1353
    Height = 89
    Align = alTop
    TabOrder = 0
    DesignSize = (
      1353
      89)
    object lblFecha: TcxLabel
      Left = 11
      Top = 27
      AutoSize = False
      Caption = 'Empleado'
      ParentFont = False
      Style.BorderStyle = ebsNone
      Style.Edges = []
      Style.Font.Charset = DEFAULT_CHARSET
      Style.Font.Color = clNavy
      Style.Font.Height = -20
      Style.Font.Name = 'Arial Black'
      Style.Font.Pitch = fpFixed
      Style.Font.Style = [fsBold]
      Style.Font.Quality = fqClearTypeNatural
      Style.Shadow = True
      Style.IsFontAssigned = True
      Properties.LineOptions.Alignment = cxllaBottom
      Properties.LineOptions.Visible = True
      Properties.Orientation = cxoRight
      Properties.WordWrap = True
      TabOrder = 0
      Height = 36
      Width = 116
    end
    object lblNombreEmpleado: TcxLabel
      Left = 254
      Top = 31
      AutoSize = False
      Caption = 'NOMBRE EMPLEADO'
      Style.BorderStyle = ebsFlat
      Properties.LabelStyle = cxlsLowered
      TabOrder = 1
      Height = 29
      Width = 203
    end
    object lblNombreCliente: TcxLabel
      Left = 694
      Top = 31
      AutoSize = False
      Caption = 'NOMBRE CLIENTE'
      Style.BorderStyle = ebsFlat
      Properties.LabelStyle = cxlsLowered
      TabOrder = 2
      Height = 29
      Width = 412
    end
    object lblFechaCaja: TcxLabel
      Left = 764
      Top = 64
      AutoSize = False
      Caption = 'NOMBRE CLIENTE'
      ParentFont = False
      Style.BorderStyle = ebsFlat
      Style.Font.Charset = ANSI_CHARSET
      Style.Font.Color = clWindowText
      Style.Font.Height = -14
      Style.Font.Name = 'Source Sans 3'
      Style.Font.Pitch = fpFixed
      Style.Font.Style = []
      Style.Font.Quality = fqClearTypeNatural
      Style.IsFontAssigned = True
      Properties.LabelStyle = cxlsLowered
      TabOrder = 3
      Height = 19
      Width = 342
    end
    object lblTarifa: TcxLabel
      Left = 764
      Top = 6
      AutoSize = False
      Caption = 'NOMBRE CLIENTE'
      ParentFont = False
      Style.BorderStyle = ebsFlat
      Style.Font.Charset = ANSI_CHARSET
      Style.Font.Color = clWindowText
      Style.Font.Height = -14
      Style.Font.Name = 'Source Sans 3'
      Style.Font.Pitch = fpFixed
      Style.Font.Style = []
      Style.Font.Quality = fqClearTypeNatural
      Style.IsFontAssigned = True
      Properties.LabelStyle = cxlsLowered
      TabOrder = 4
      Height = 19
      Width = 342
    end
    object lblInstrucciones: TcxLabel
      Left = 11
      Top = 66
      ParentFont = False
      Style.Font.Charset = ANSI_CHARSET
      Style.Font.Color = clWindowText
      Style.Font.Height = -13
      Style.Font.Name = 'Source Sans 3'
      Style.Font.Pitch = fpFixed
      Style.Font.Style = []
      Style.Font.Quality = fqClearTypeNatural
      Style.IsFontAssigned = True
      TabOrder = 5
    end
    object btnCodigoEmpleado: TcxButtonEdit
      Left = 133
      Top = 30
      Properties.AutoSelect = False
      Properties.Buttons = <
        item
          Default = True
          Kind = bkEllipsis
        end>
      Properties.OnButtonClick = btnCodigoEmpleadoPropertiesButtonClick
      Properties.OnValidate = btnCodigoEmpleadoPropertiesValidate
      TabOrder = 6
      OnExit = btnCodigoEmpleadoExit
      Width = 110
    end
    object lblCliente: TcxLabel
      Left = 463
      Top = 27
      AutoSize = False
      Caption = 'Cliente'
      ParentFont = False
      Style.BorderStyle = ebsNone
      Style.Edges = []
      Style.Font.Charset = DEFAULT_CHARSET
      Style.Font.Color = clNavy
      Style.Font.Height = -20
      Style.Font.Name = 'Arial Black'
      Style.Font.Pitch = fpFixed
      Style.Font.Style = [fsBold]
      Style.Font.Quality = fqClearTypeNatural
      Style.Shadow = True
      Style.IsFontAssigned = True
      Properties.LineOptions.Alignment = cxllaBottom
      Properties.LineOptions.Visible = True
      Properties.Orientation = cxoRight
      Properties.WordWrap = False
      TabOrder = 7
      Height = 36
      Width = 85
    end
    object btnCodigoCliente: TcxButtonEdit
      Left = 554
      Top = 30
      Properties.AutoSelect = False
      Properties.ValidateOnEnter = True
      Properties.Buttons = <
        item
          Default = True
          Kind = bkEllipsis
        end>
      Properties.OnButtonClick = btnCodigoClientePropertiesButtonClick
      Properties.OnValidate = btnCodigoClientePropertiesValidate
      TabOrder = 8
      OnExit = btnCodigoClienteExit
      Width = 121
    end
    object lblTipoRectificativa: TcxLabel
      Left = 1108
      Top = 6
      Anchors = [akTop, akRight]
      AutoSize = False
      Caption = 'RECTIFICATIVA'#13#10'POR DIFERENCIAS'
      ParentFont = False
      Style.BorderStyle = ebsOffice11
      Style.Font.Charset = DEFAULT_CHARSET
      Style.Font.Color = clMaroon
      Style.Font.Height = -18
      Style.Font.Name = 'Arial Black'
      Style.Font.Pitch = fpFixed
      Style.Font.Style = [fsBold]
      Style.Font.Quality = fqClearTypeNatural
      Style.TextColor = clMaroon
      Style.IsFontAssigned = True
      Properties.Alignment.Horz = taCenter
      Properties.Alignment.Vert = taVCenter
      Properties.LabelStyle = cxlsRaised
      Properties.WordWrap = True
      TabOrder = 9
      Transparent = True
      Visible = False
      Height = 77
      Width = 229
      AnchorX = 1223
      AnchorY = 45
    end
    object btnVerHistorico: TcxButton
      Left = 554
      Top = 2
      Width = 200
      Height = 26
      Caption = 'Ver hist'#243'rico'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -14
      Font.Name = 'Source Sans 3'
      Font.Style = []
      ParentFont = False
      TabOrder = 10
      TabStop = False
      Visible = False
      OnClick = btnVerHistoricoClick
    end
  end
  object pnlCli: TPanel [1]
    Left = 0
    Top = 89
    Width = 1353
    Height = 316
    Align = alClient
    TabOrder = 1
    object pnlAccionesIzq: TPanel
      Left = 1
      Top = 217
      Width = 1351
      Height = 98
      Align = alBottom
      TabOrder = 1
      object pnlTotal: TPanel
        Left = 940
        Top = 1
        Width = 410
        Height = 96
        Align = alRight
        BevelOuter = bvNone
        TabOrder = 0
        object lblTotal: TcxLabel
          Left = 0
          Top = 0
          Align = alClient
          AutoSize = False
          Caption = 'Total 0,00 '#8364
          ParentFont = False
          Style.BorderStyle = ebsOffice11
          Style.Font.Charset = DEFAULT_CHARSET
          Style.Font.Color = clNavy
          Style.Font.Height = -50
          Style.Font.Name = 'Arial Black'
          Style.Font.Pitch = fpFixed
          Style.Font.Style = [fsBold]
          Style.Font.Quality = fqClearTypeNatural
          Style.Shadow = True
          Style.IsFontAssigned = True
          Properties.Alignment.Horz = taRightJustify
          Properties.LabelEffect = cxleFun
          Properties.LabelStyle = cxlsLowered
          Properties.LineOptions.Alignment = cxllaTop
          Properties.LineOptions.Visible = True
          Properties.Orientation = cxoRight
          Properties.WordWrap = True
          TabOrder = 0
          Height = 96
          Width = 410
          AnchorX = 410
        end
      end
      object pnlBotones: TPanel
        Left = 1
        Top = 1
        Width = 939
        Height = 96
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 1
        object btnF12: TcxButton
          Left = 10
          Top = 6
          Width = 96
          Height = 57
          Caption = 'F12'
          Colors.Default = clBlue
          Colors.Normal = clBlue
          Colors.NormalText = clNavy
          TabOrder = 0
          Font.Charset = ANSI_CHARSET
          Font.Color = clBlue
          Font.Height = -27
          Font.Name = 'Segoe UI Black'
          Font.Pitch = fpFixed
          Font.Style = [fsUnderline]
          Font.Quality = fqClearTypeNatural
          ParentFont = False
          OnClick = btnF12Click
        end
        object btnF3: TcxButton
          Left = 110
          Top = 6
          Width = 96
          Height = 57
          Caption = 'F3'
          Colors.Default = clBlue
          Colors.Normal = clBlue
          Colors.NormalText = clNavy
          TabOrder = 1
          Font.Charset = ANSI_CHARSET
          Font.Color = clBlue
          Font.Height = -27
          Font.Name = 'Segoe UI Black'
          Font.Pitch = fpFixed
          Font.Style = [fsUnderline]
          Font.Quality = fqClearTypeNatural
          ParentFont = False
          OnClick = btnF3Click
        end
        object btnF8: TcxButton
          Left = 210
          Top = 6
          Width = 96
          Height = 57
          Caption = 'F8'
          Colors.Default = clBlue
          Colors.Normal = clBlue
          Colors.NormalText = clNavy
          TabOrder = 2
          Font.Charset = ANSI_CHARSET
          Font.Color = clBlue
          Font.Height = -27
          Font.Name = 'Segoe UI Black'
          Font.Pitch = fpFixed
          Font.Style = [fsUnderline]
          Font.Quality = fqClearTypeNatural
          ParentFont = False
          OnClick = btnF8Click
        end
        object btnF6: TcxButton
          Left = 310
          Top = 6
          Width = 96
          Height = 57
          Caption = 'F6'
          OnClick = btnF6Click
          Colors.Default = clBlue
          Colors.Normal = clBlue
          Colors.NormalText = clNavy
          TabOrder = 3
          Font.Charset = ANSI_CHARSET
          Font.Color = clBlue
          Font.Height = -27
          Font.Name = 'Segoe UI Black'
          Font.Pitch = fpFixed
          Font.Style = [fsUnderline]
          Font.Quality = fqClearTypeNatural
          ParentFont = False
        end
        object btnF61: TcxButton
          Left = 410
          Top = 6
          Width = 96
          Height = 57
          Caption = 'F4'
          Colors.Default = clBlue
          Colors.Normal = clBlue
          Colors.NormalText = clNavy
          TabOrder = 4
          Font.Charset = ANSI_CHARSET
          Font.Color = clBlue
          Font.Height = -27
          Font.Name = 'Segoe UI Black'
          Font.Pitch = fpFixed
          Font.Style = [fsUnderline]
          Font.Quality = fqClearTypeNatural
          ParentFont = False
          OnClick = btnF61Click
        end
        object btnF7: TcxButton
          Left = 510
          Top = 6
          Width = 96
          Height = 57
          Caption = 'F7'
          Colors.Default = clBlue
          Colors.Normal = clBlue
          Colors.NormalText = clNavy
          TabOrder = 5
          Font.Charset = ANSI_CHARSET
          Font.Color = clBlue
          Font.Height = -27
          Font.Name = 'Segoe UI Black'
          Font.Pitch = fpFixed
          Font.Style = [fsUnderline]
          Font.Quality = fqClearTypeNatural
          ParentFont = False
          OnClick = btnF7Click
        end
        object btnF5: TcxButton
          Left = 610
          Top = 6
          Width = 96
          Height = 57
          Caption = 'F5'
          Colors.Default = clBlue
          Colors.Normal = clBlue
          Colors.NormalText = clNavy
          TabOrder = 6
          Font.Charset = ANSI_CHARSET
          Font.Color = clBlue
          Font.Height = -27
          Font.Name = 'Segoe UI Black'
          Font.Pitch = fpFixed
          Font.Style = [fsUnderline]
          Font.Quality = fqClearTypeNatural
          ParentFont = False
          OnClick = btnF5Click
        end
        object btnF2: TcxButton
          Left = 710
          Top = 6
          Width = 96
          Height = 57
          Caption = 'F2'
          Colors.Default = clBlue
          Colors.Normal = clBlue
          Colors.NormalText = clNavy
          TabOrder = 7
          Font.Charset = ANSI_CHARSET
          Font.Color = clBlue
          Font.Height = -27
          Font.Name = 'Segoe UI Black'
          Font.Pitch = fpFixed
          Font.Style = [fsUnderline]
          Font.Quality = fqClearTypeNatural
          ParentFont = False
          OnClick = btnF2Click
        end
        object btnF10: TcxButton
          Left = 824
          Top = 6
          Width = 96
          Height = 57
          Hint = 'Buscar / Modificar operaciones'
          Caption = 'F10'
          Colors.Default = clBlue
          Colors.Normal = clBlue
          Colors.NormalText = clNavy
          TabOrder = 8
          Font.Charset = ANSI_CHARSET
          Font.Color = clBlue
          Font.Height = -27
          Font.Name = 'Segoe UI Black'
          Font.Pitch = fpFixed
          Font.Style = [fsUnderline]
          Font.Quality = fqClearTypeNatural
          ParentFont = False
          OnClick = btnF10Click
        end
        object lblCobro: TcxLabel
          Left = 10
          Top = 68
          AutoSize = False
          Caption = 'Cobro'
          Properties.Alignment.Horz = taCenter
          TabOrder = 9
          Transparent = True
          Height = 26
          Width = 96
          AnchorX = 58
        end
        object lblBuscar: TcxLabel
          Left = 110
          Top = 68
          AutoSize = False
          Caption = 'Buscar'
          Properties.Alignment.Horz = taCenter
          TabOrder = 10
          Transparent = True
          Height = 26
          Width = 96
          AnchorX = 158
        end
        object lblEliminar: TcxLabel
          Left = 210
          Top = 68
          AutoSize = False
          Caption = 'Eliminar'
          Properties.Alignment.Horz = taCenter
          TabOrder = 11
          Transparent = True
          Height = 26
          Width = 96
          AnchorX = 258
        end
        object lblTextoTarifa: TcxLabel
          Left = 310
          Top = 68
          AutoSize = False
          Caption = 'Tarifa'
          Properties.Alignment.Horz = taCenter
          TabOrder = 12
          Transparent = True
          Height = 26
          Width = 96
          AnchorX = 358
        end
        object lblBusqTick: TcxLabel
          Left = 408
          Top = 68
          AutoSize = False
          Caption = 'Buscar ticket'
          Properties.Alignment.Horz = taCenter
          TabOrder = 13
          Transparent = True
          Height = 26
          Width = 100
          AnchorX = 458
        end
        object lblIndIVA: TcxLabel
          Left = 510
          Top = 68
          AutoSize = False
          Caption = 'Cambio IVA'
          Properties.Alignment.Horz = taCenter
          TabOrder = 14
          Transparent = True
          Height = 26
          Width = 96
          AnchorX = 558
        end
        object lblOtro: TcxLabel
          Left = 610
          Top = 68
          AutoSize = False
          Caption = 'Otro'
          Properties.Alignment.Horz = taCenter
          TabOrder = 15
          Transparent = True
          Height = 26
          Width = 96
          AnchorX = 658
        end
        object lblCargarCta: TcxLabel
          Left = 694
          Top = 68
          AutoSize = False
          Caption = 'Cta. Cliente'
          Properties.Alignment.Horz = taCenter
          TabOrder = 16
          Transparent = True
          Height = 26
          Width = 128
          AnchorX = 758
        end
        object lblBuscarModificar: TcxLabel
          Left = 812
          Top = 68
          AutoSize = False
          Caption = 'Buscar/Modif.'
          Properties.Alignment.Horz = taCenter
          TabOrder = 17
          Transparent = True
          Height = 26
          Width = 128
          AnchorX = 876
        end
      end
    end
    object pnlAccionesDer: TPanel
      Left = 1
      Top = 1
      Width = 1351
      Height = 216
      Align = alClient
      TabOrder = 0
      ExplicitWidth = 1347
      ExplicitHeight = 215
      object cxgrdLineasOpe: TcxGrid
        Left = 1
        Top = 1
        Width = 1349
        Height = 90
        Align = alClient
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Source Sans 3'
        Font.Pitch = fpFixed
        Font.Style = []
        Font.Quality = fqClearTypeNatural
        ParentFont = False
        TabOrder = 0
        OnEnter = cxGrid1Enter
        OnExit = cxGrid1Exit
        ExplicitWidth = 1345
        ExplicitHeight = 89
        object tvLineasOpe: TcxGridDBTableView
          OnKeyDown = cxGrid1DBTableView1KeyDown
          OnMouseDown = cxGrid1DBTableView1MouseDown
          OnCanFocusRecord = cxGrid1DBTableView1CanFocusRecord
          OnCustomDrawCell = tvLineasOpeCustomDrawCell
          OnEditing = cxGrid1DBTableView1Editing
          OnEditKeyDown = cxGrid1DBTableView1EditKeyDown
          OnFocusedRecordChanged = cxGrid1DBTableView1FocusedRecordChanged
          OnInitEdit = cxGrid1DBTableView1InitEdit
          DataController.DataSource = dsLineas
          OptionsBehavior.AlwaysShowEditor = True
          OptionsBehavior.FocusCellOnTab = True
          OptionsBehavior.GoToNextCellOnEnter = True
          OptionsBehavior.FocusCellOnCycle = True
          OptionsData.Appending = True
          OptionsView.NoDataToDisplayInfoText = 'No hay art'#237'culos'
          OptionsView.ColumnAutoWidth = True
          OptionsView.GroupByBox = False
          Styles.Header = styCabecera
          object tvEmpleado: TcxGridDBColumn
            Caption = 'Vend.'
            DataBinding.FieldName = 'CODIGO_VENDEDOR_FACLIN'
            PropertiesClassName = 'TcxTextEditProperties'
            Width = 66
          end
          object tvArticulo: TcxGridDBColumn
            Caption = 'Art'#237'culo'
            DataBinding.FieldName = 'CODIGO_ART_FACLIN'
            PropertiesClassName = 'TcxExtLookupComboBoxProperties'
            Properties.DropDownListStyle = lsEditList
            Properties.View = dbtvBusq
            Properties.KeyFieldNames = 'CODIGO_PADRE'
            Properties.ListFieldItem = dbtvBusqINPUT_BUSQUEDA
            Properties.OnCloseUp = tvArticuloPropertiesCloseUp
            Properties.OnValidate = tvArticuloPropertiesValidate
            OnGetProperties = tvArticuloGetProperties
            Width = 135
          end
          object tvDescripcion: TcxGridDBColumn
            Caption = 'Descripci'#243'n'
            DataBinding.FieldName = 'DESCRIPCION_ARTICULO_FACLIN'
            Width = 306
          end
          object tvUds: TcxGridDBColumn
            Caption = 'Uds.'
            DataBinding.FieldName = 'CANTIDAD_FACLIN'
            PropertiesClassName = 'TcxTextEditProperties'
            Properties.OnEditValueChanged = tvUdsPropertiesEditValueChanged
            Properties.OnValidate = tvUdsPropertiesValidate
            OnGetDisplayText = tvUdsGetDisplayText
            BestFitMaxWidth = 50
            HeaderAlignmentHorz = taRightJustify
          end
          object tvTipoCantidad: TcxGridDBColumn
            Caption = 'Tipo de Cantidad'
            DataBinding.FieldName = 'TIPO_CANTIDAD_ARTICULO_FACLIN'
            Visible = False
            VisibleForCustomization = False
            Width = 150
          end
          object tvPrecioUni: TcxGridDBColumn
            Caption = 'Precio'
            DataBinding.FieldName = 'PRECIO_SALIDA_FACLIN'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.OnEditValueChanged = tvPrecioUniPropertiesEditValueChanged
            OnGetDisplayText = tvPrecioUniGetDisplayText
            Width = 91
          end
          object tvDescuento: TcxGridDBColumn
            Caption = '%'
            DataBinding.FieldName = 'PORCENTAJE_DTO_FACLIN'
            PropertiesClassName = 'TcxSpinEditProperties'
            Properties.DisplayFormat = '0.00 %'
            Properties.EditFormat = '0.00 %'
            Properties.Increment = 0.100000000000000000
            Properties.LargeIncrement = 1.000000000000000000
            Properties.MaxValue = 100.000000000000000000
            Properties.OnEditValueChanged = tvDescuentoPropertiesEditValueChanged
            Width = 43
          end
          object tvDescuentoMenos: TcxGridDBColumn
            Caption = 'Menos'
            DataBinding.FieldName = 'PRECIO_DTO_FACLIN'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.OnEditValueChanged = tvDescuentoMenosPropertiesEditValueChanged
            HeaderAlignmentHorz = taRightJustify
            Width = 152
          end
          object tvTotal: TcxGridDBColumn
            Caption = 'Total'
            DataBinding.FieldName = 'TOTAL_FACLIN'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.ReadOnly = False
            Properties.OnEditValueChanged = tvTotalPropertiesEditValueChanged
            OnGetDisplayText = tvTotalGetDisplayText
            HeaderAlignmentHorz = taRightJustify
            Width = 137
          end
          object tvFechaOperacion: TcxGridDBColumn
            Caption = 'Fecha op.'
            DataBinding.FieldName = 'FECHA_DEPOSITO_DEP'
            PropertiesClassName = 'TcxTextEditProperties'
            Properties.ReadOnly = True
            Visible = False
            Options.Editing = False
            Width = 120
          end
          object tvMarcaDeposito: TcxGridDBColumn
            Caption = 'Cobrar'
            DataBinding.FieldName = 'ESMARCADA_DEP'
            PropertiesClassName = 'TcxCheckBoxProperties'
            Properties.Alignment = taCenter
            Properties.ImmediatePost = True
            Properties.NullStyle = nssUnchecked
            Properties.ValueChecked = 'S'
            Properties.ValueUnchecked = 'N'
            Visible = False
            HeaderAlignmentHorz = taCenter
            Width = 70
          end
          object tvOrigenDeposito: TcxGridDBColumn
            DataBinding.FieldName = 'VIENE_DE_DEPOSITO'
            Visible = False
            VisibleForCustomization = False
          end
          object tvCantidadHistorico: TcxGridDBColumn
            DataBinding.FieldName = 'CANTIDAD_HISTORICO_DEP'
            Visible = False
            VisibleForCustomization = False
          end
          object tvPrecioOriginalDeposito: TcxGridDBColumn
            DataBinding.FieldName = 'PRECIO_ORIGINAL_DEP'
            Visible = False
            VisibleForCustomization = False
          end
        end
        object cxgrdlvlLineasOpe: TcxGridLevel
          GridView = tvLineasOpe
        end
      end
      object pnlBusqueda: TPanel
        Left = 1
        Top = 99
        Width = 1349
        Height = 116
        Align = alBottom
        TabOrder = 1
        ExplicitTop = 98
        ExplicitWidth = 1345
        object pnlFotoStock: TPanel
          Left = 1228
          Top = 1
          Width = 120
          Height = 114
          Align = alRight
          BevelOuter = bvLowered
          TabOrder = 1
          ExplicitLeft = 1224
          object imgFotoStock: TImage
            Left = 1
            Top = 1
            Width = 118
            Height = 112
            Align = alClient
            Center = True
            Proportional = True
            Stretch = True
          end
        end
        object splFotoStock: TcxSplitter
          Left = 1218
          Top = 1
          Width = 10
          Height = 114
          AlignSplitter = salRight
          Control = pnlFotoStock
          ExplicitLeft = 1214
        end
        object cxgrdStock: TcxGrid
          Left = 1
          Top = 1
          Width = 1217
          Height = 114
          Align = alClient
          Font.Charset = ANSI_CHARSET
          Font.Color = clWindowText
          Font.Height = -19
          Font.Name = 'Source Sans 3'
          Font.Pitch = fpFixed
          Font.Style = []
          Font.Quality = fqClearTypeNatural
          ParentFont = False
          TabOrder = 0
          OnEnter = cxGrid1Enter
          OnExit = cxGrid1Exit
          ExplicitWidth = 1213
          object dbtvStock: TcxGridDBTableView
            OnKeyDown = cxGrid1DBTableView1KeyDown
            OnCustomDrawCell = dbtvStockCustomDrawCell
            OnEditKeyDown = cxGrid1DBTableView1EditKeyDown
            OnInitEdit = cxGrid1DBTableView1InitEdit
            DataController.DataSource = dsStock
            OptionsBehavior.GoToNextCellOnEnter = True
            OptionsBehavior.FocusCellOnCycle = True
            OptionsData.CancelOnExit = False
            OptionsData.Deleting = False
            OptionsData.DeletingConfirmation = False
            OptionsData.Editing = False
            OptionsData.Inserting = False
            OptionsSelection.CellSelect = False
            OptionsView.NoDataToDisplayInfoText = 'Sin stock'
            OptionsView.ColumnAutoWidth = True
            OptionsView.GroupByBox = False
            Styles.Content = styImporte
            Styles.Header = styPrincipal
          end
          object cxgrdlvlBusqueda: TcxGridLevel
            GridView = dbtvStock
          end
        end
      end
      object splOpe: TcxSplitter
        Left = 1
        Top = 91
        Width = 8
        Height = 8
        HotZoneClassName = 'TcxMediaPlayer8Style'
        AlignSplitter = salBottom
        AutoSnap = True
        ExplicitTop = 90
        ExplicitWidth = 1345
      end
    end
  end
  object tmrReloj: TTimer
    OnTimer = Timer1Timer
    Left = 1040
    Top = 32
  end
  object dsLineas: TDataSource
    Left = 648
    Top = 136
  end
  object jvEnterTab: TJvEnterAsTab
    Left = 840
    Top = 432
  end
  object dsStock: TDataSource
    Left = 960
    Top = 432
  end
  object cxstylrpstry: TcxStyleRepository
    Left = 896
    Top = 432
    PixelsPerInch = 96
    object styPrincipal: TcxStyle
      AssignedValues = [svColor, svFont]
      Color = 11529442
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -12
      Font.Name = 'Source Sans 3'
      Font.Style = [fsBold]
    end
    object styImporte: TcxStyle
      AssignedValues = [svFont]
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clOlive
      Font.Height = -12
      Font.Name = 'Source Sans 3'
      Font.Style = []
    end
    object styCabecera: TcxStyle
      AssignedValues = [svColor, svFont, svTextColor]
      Color = 11529442
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = 20
      Font.Name = 'Source Sans 3'
      Font.Style = [fsBold]
      TextColor = clDefault
    end
  end
  object tmrBusq: TTimer
    Enabled = False
    Interval = 500
    OnTimer = tmrBusqTimer
    Left = 80
    Top = 136
  end
  object dsBusq: TDataSource
    Left = 80
    Top = 192
  end
  object tvrBusq: TcxGridViewRepository
    Left = 80
    Top = 312
    object dbtvBusq: TcxGridDBTableView
      DataController.DataModeController.SyncMode = False
      DataController.DataSource = dsBusq
      DataController.KeyFieldNames = 'CODIGO_PADRE'
      Filtering.MRUItemsList = False
      Filtering.ColumnAddValueItems = False
      Filtering.ColumnFilteredItemsListShowFilteredItemsOnly = False
      Filtering.ColumnMRUItemsList = False
      OptionsBehavior.ColumnHeaderHints = False
      OptionsSelection.CellSelect = False
      OptionsView.GroupByBox = False
      object dbtvBusqINPUT_BUSQUEDA: TcxGridDBColumn
        DataBinding.FieldName = 'INPUT_BUSQUEDA'
        PropertiesClassName = 'TcxTextEditProperties'
        Properties.IncrementalSearch = False
        Visible = False
        Options.Filtering = False
        Options.FilteringWithFindPanel = False
        Options.IncSearch = False
        Options.FilteringAddValueItems = False
        Options.FilteringFilteredItemsList = False
        Options.FilteringFilteredItemsListShowFilteredItemsOnly = False
        Options.FilteringMRUItemsList = False
        Options.FilteringPopup = False
        Options.FilteringPopupMultiSelect = False
        Options.GroupFooters = False
        Options.Grouping = False
      end
      object dbtvBusqCODIGO_ARTICULO: TcxGridDBColumn
        Caption = 'Art'#237'culo'
        DataBinding.FieldName = 'CODIGO_PADRE'
        Width = 120
      end
      object dbtvBusqDESCRIPCION_ARTICULO: TcxGridDBColumn
        Caption = 'Descripci'#243'n'
        DataBinding.FieldName = 'DESCRIPCION_ART'
        Width = 280
      end
      object dbtvBusqTEMPORADA: TcxGridDBColumn
        Caption = 'Temporada'
        DataBinding.FieldName = 'TEMPORADA'
      end
      object dbtvBusqPROVEEDOR: TcxGridDBColumn
        Caption = 'Proveedor'
        DataBinding.FieldName = 'RAZON_SOCIAL_PROVEEDOR'
      end
      object dbtvBusqREF_PROVEEDOR: TcxGridDBColumn
        Caption = 'Ref. proveedor'
        DataBinding.FieldName = 'REF_PROVEEDOR'
        Width = 120
      end
    end
  end
  object edtrepArticulo: TcxEditRepository
    Left = 80
    Top = 368
    PixelsPerInch = 96
    object repSoloTexto: TcxEditRepositoryTextItem
    end
    object repComboBox: TcxEditRepositoryExtLookupComboBoxItem
      Properties.AutoSearchOnPopup = False
      Properties.DropDownListStyle = lsEditList
      Properties.DropDownRows = 15
      Properties.DropDownSizeable = True
      Properties.DropDownWidth = 750
      Properties.ImmediateDropDownWhenActivated = True
      Properties.ImmediateDropDownWhenKeyPressed = False
      Properties.IncrementalFiltering = False
      Properties.View = dbtvBusq
      Properties.KeyFieldNames = 'CODIGO_PADRE'
      Properties.ListFieldItem = dbtvBusqINPUT_BUSQUEDA
      Properties.OnInitPopup = repComboBoxPropertiesInitPopup
      Properties.OnValidate = tvArticuloPropertiesValidate
    end
  end
  object alCajaOpe: TActionList
    Left = 312
    Top = 168
    object actBuscarEmpleados: TAction
      Caption = 'actBuscarEmpleados'
      SecondaryShortCuts.Strings = (
        'F3')
      ShortCut = 16397
      OnExecute = actBuscarEmpleadosExecute
    end
    object actSalir: TAction
      Caption = 'Salir'
      ShortCut = 27
      OnExecute = actSalirExecute
    end
    object actEliminarLinea: TAction
      Caption = 'Eliminar'
      ShortCut = 119
      OnExecute = actEliminarLineaExecute
    end
    object actCobro: TAction
      Caption = 'actCobro'
      ShortCut = 123
      OnExecute = btnF12Click
    end
    object actCargarCta: TAction
      Caption = 'CargarCta'
      ShortCut = 113
      OnExecute = actCargarCtaExecute
    end
    object actBuscarModificar: TAction
      Caption = 'Buscar / Modificar'
      ShortCut = 121
      OnExecute = actBuscarModificarExecute
    end
    object actGuardarLayout: TAction
      Caption = 'Guardar Layout'
      ShortCut = 32891
      OnExecute = actGuardarLayoutExecute
    end
    object actAbrirArticulos: TAction
      Caption = 'Art'#237'culos'
      ShortCut = 16466
      OnExecute = actAbrirArticulosExecute
    end
    object actConsultaStock: TAction
      Caption = 'Consulta stock'
      ShortCut = 16469
      OnExecute = actConsultaStockExecute
    end
  end
end
