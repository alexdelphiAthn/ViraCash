inherited frmModalAddBlockBase: TfrmModalAddBlockBase
  BorderIcons = [biSystemMenu]
  Caption = 'Carga masiva con filtros'
  ClientHeight = 760
  ClientWidth = 1180
  Position = poMainFormCenter
  StyleElements = [seFont, seClient, seBorder]
  OnClose = FormClose
  ExplicitWidth = 1196
  ExplicitHeight = 799
  TextHeight = 19
  object pnlCabeceraExtra: TPanel [0]
    Left = 0
    Top = 0
    Width = 1180
    Height = 100
    Align = alTop
    BevelOuter = bvNone
    Caption = ' '
    TabOrder = 0
  end
  object pnlCabeceraComun: TPanel [1]
    Left = 0
    Top = 100
    Width = 1180
    Height = 50
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    ExplicitWidth = 1182
    object chkSoloActivos: TcxCheckBox
      Left = 12
      Top = 8
      Caption = 'S'#243'lo art'#237'culos activos'
      TabOrder = 0
      Transparent = True
    end
    object chkExcluirYaCargados: TcxCheckBox
      Left = 200
      Top = 8
      Caption = 'Excluir art'#237'culos ya cargados'
      TabOrder = 1
      Transparent = True
    end
    object chkSoloConStock: TcxCheckBox
      Left = 430
      Top = 8
      Caption = 'S'#243'lo art'#237'culos con stock'
      TabOrder = 2
      Transparent = True
    end
    object lblStockAviso: TcxLabel
      Left = 640
      Top = 12
      Style.TextColor = clGray
      TabOrder = 5
      Transparent = True
    end
    object btnPrevisualizar: TcxButton
      Left = 939
      Top = 12
      Width = 111
      Height = 28
      Caption = 'Previsualizar'
      TabOrder = 3
      OnClick = btnPrevisualizarClick
    end
    object btnLimpiarFiltros: TcxButton
      Left = 1060
      Top = 12
      Width = 105
      Height = 28
      Caption = 'Limpiar'
      TabOrder = 4
      OnClick = btnLimpiarFiltrosClick
    end
  end
  object pcFiltros: TcxPageControl [2]
    Left = 0
    Top = 150
    Width = 1180
    Height = 338
    Align = alClient
    TabOrder = 2
    Properties.ActivePage = tsFamilias
    Properties.CustomButtons.Buttons = <>
    ClientRectBottom = 336
    ClientRectLeft = 2
    ClientRectRight = 1178
    ClientRectTop = 29
    object tsFamilias: TcxTabSheet
      Caption = '&1_Familias'
      ImageIndex = 0
      ExplicitLeft = 3
      ExplicitTop = 32
      ExplicitWidth = 1171
      ExplicitHeight = 302
      object pnlFamiliasTop: TPanel
        Left = 0
        Top = 0
        Width = 1176
        Height = 35
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        ExplicitWidth = 1171
        object chkPropagarHijos: TcxCheckBox
          Left = 8
          Top = 8
          Caption = 'Propagar selecci'#243'n a subfamilias'
          State = cbsChecked
          TabOrder = 0
          Transparent = True
        end
        object btnExpandirFamilias: TcxButton
          Left = 270
          Top = 4
          Width = 90
          Height = 25
          Caption = 'Expandir'
          TabOrder = 1
          OnClick = btnExpandirFamiliasClick
        end
        object btnContraerFamilias: TcxButton
          Left = 366
          Top = 4
          Width = 90
          Height = 25
          Caption = 'Contraer'
          TabOrder = 2
          OnClick = btnContraerFamiliasClick
        end
        object btnQuitarSelFamilias: TcxButton
          Left = 458
          Top = 4
          Width = 138
          Height = 25
          Caption = 'Quitar selecci'#243'n'
          TabOrder = 3
          OnClick = btnQuitarSelFamiliasClick
        end
        object lblSelFamilias: TcxLabel
          Left = 600
          Top = 8
          Caption = '(0 sel.)'
          TabOrder = 4
          Transparent = True
        end
      end
      object tlFamilias: TcxDBTreeList
        Left = 0
        Top = 35
        Width = 1176
        Height = 272
        Align = alClient
        Bands = <
          item
          end>
        OptionsBehavior.CopyCaptionsToClipboard = False
        OptionsData.Editing = False
        OptionsData.Deleting = False
        OptionsSelection.CellSelect = False
        OptionsSelection.MultiSelect = True
        OptionsView.CheckGroups = True
        OptionsView.ColumnAutoWidth = True
        OptionsView.Headers = False
        RootValue = ''
        ScrollbarAnnotations.CustomAnnotations = <>
        OnNodeCheckChanged = tlFamiliasNodeCheckChanged
        TabOrder = 1
        ExplicitWidth = 1171
        ExplicitHeight = 267
        object tlcolFamiliasNombre: TcxDBTreeListColumn
          DataBinding.FieldName = 'NOMBRE_FAM_FAM'
          Width = 600
          Position.ColIndex = 0
          Position.RowIndex = 0
          Position.BandIndex = 0
        end
        object tlcolFamiliasCodigo: TcxDBTreeListColumn
          Visible = False
          DataBinding.FieldName = 'CODIGO_FAM_FAM'
          Width = 120
          Position.ColIndex = 1
          Position.RowIndex = 0
          Position.BandIndex = 0
        end
      end
    end
    object tsProveedores: TcxTabSheet
      Caption = '&2_Proveedores'
      ImageIndex = 1
      ExplicitLeft = 3
      ExplicitTop = 32
      ExplicitWidth = 1171
      ExplicitHeight = 302
      object pnlProveedoresTop: TPanel
        Left = 0
        Top = 0
        Width = 1176
        Height = 35
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        ExplicitWidth = 1171
        object edtFiltroProveedor: TcxTextEdit
          Left = 8
          Top = 6
          Properties.OnChange = edtFiltroProveedorPropertiesChange
          TabOrder = 0
          Width = 250
        end
        object chkSoloPrincipal: TcxCheckBox
          Left = 270
          Top = 8
          Caption = 'S'#243'lo proveedores principales'
          TabOrder = 1
          Transparent = True
        end
        object btnQuitarSelProveedores: TcxButton
          Left = 510
          Top = 4
          Width = 138
          Height = 25
          Caption = 'Quitar selecci'#243'n'
          TabOrder = 2
          OnClick = btnQuitarSelProveedoresClick
        end
        object lblSelProveedores: TcxLabel
          Left = 650
          Top = 8
          Caption = '(0 sel.)'
          TabOrder = 3
          Transparent = True
        end
      end
      object grdProveedores: TcxGrid
        Left = 0
        Top = 35
        Width = 1176
        Height = 272
        Align = alClient
        TabOrder = 1
        ExplicitWidth = 1171
        ExplicitHeight = 267
        object tvProveedores: TcxGridDBTableView
          OnSelectionChanged = tvProveedoresSelectionChanged
          OptionsData.CancelOnExit = False
          OptionsData.Deleting = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsSelection.CheckBoxVisibility = [cbvColumnHeader, cbvDataRow]
          OptionsSelection.MultiSelect = True
          OptionsSelection.MultiSelectMode = msmPersistent
          OptionsView.GroupByBox = False
          object colProvCodigo: TcxGridDBColumn
            DataBinding.FieldName = 'CODIGO_PRV_PRV'
            Width = 120
          end
          object colProvNombreComercial: TcxGridDBColumn
            Caption = 'Proveedor'
            DataBinding.FieldName = 'NOMBRE_PRV'
            Width = 400
          end
          object colProvRazonSocial: TcxGridDBColumn
            DataBinding.FieldName = 'RAZON_SOCIAL_PRV'
            Width = 300
          end
          object colProvNif: TcxGridDBColumn
            DataBinding.FieldName = 'NIF_PRV'
            Width = 150
          end
        end
        object lvProveedores: TcxGridLevel
          GridView = tvProveedores
        end
      end
    end
    object tsPropiedades: TcxTabSheet
      Caption = '&3_Propiedades (incluye temporada)'
      ImageIndex = 2
      ExplicitLeft = 3
      ExplicitTop = 32
      ExplicitWidth = 1171
      ExplicitHeight = 302
      object pnlPropiedadesTop: TPanel
        Left = 0
        Top = 0
        Width = 1176
        Height = 35
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        ExplicitWidth = 1171
        object lblPropiedad: TcxLabel
          Left = 8
          Top = 9
          Caption = 'Filtrar propiedad:'
          TabOrder = 2
          Transparent = True
        end
        object cbxPropiedad: TcxComboBox
          Left = 130
          Top = 6
          Properties.DropDownListStyle = lsFixedList
          Properties.OnChange = cbxPropiedadPropertiesChange
          TabOrder = 0
          Width = 300
        end
        object btnQuitarSelPropiedades: TcxButton
          Left = 450
          Top = 4
          Width = 138
          Height = 25
          Caption = 'Quitar selecci'#243'n'
          TabOrder = 1
          OnClick = btnQuitarSelPropiedadesClick
        end
        object lblSelPropiedades: TcxLabel
          Left = 595
          Top = 8
          Caption = '(0 sel.)'
          TabOrder = 3
          Transparent = True
        end
      end
      object grdPropValores: TcxGrid
        Left = 0
        Top = 35
        Width = 1176
        Height = 272
        Align = alClient
        TabOrder = 1
        ExplicitWidth = 1171
        ExplicitHeight = 267
        object tvPropValores: TcxGridDBTableView
          OnSelectionChanged = tvPropValoresSelectionChanged
          OptionsData.CancelOnExit = False
          OptionsData.Deleting = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsSelection.CheckBoxVisibility = [cbvColumnHeader, cbvDataRow]
          OptionsSelection.MultiSelect = True
          OptionsSelection.MultiSelectMode = msmPersistent
          object colPropIdValor: TcxGridDBColumn
            DataBinding.FieldName = 'ID_PV_ARTPROP'
            Visible = False
          end
          object colPropPropiedad: TcxGridDBColumn
            Caption = 'Propiedad'
            DataBinding.FieldName = 'NOMBRE_PROP_PROP'
            GroupIndex = 0
            SortIndex = 0
            SortOrder = soAscending
            Width = 200
          end
          object colPropValor: TcxGridDBColumn
            Caption = 'Valor'
            DataBinding.FieldName = 'PV'
            Width = 500
          end
        end
        object lvPropValores: TcxGridLevel
          GridView = tvPropValores
        end
      end
    end
    object tsAlmacenes: TcxTabSheet
      Caption = '&4_Almacenes (para filtro de stock)'
      ImageIndex = 3
      object pnlAlmacenesTop: TPanel
        Left = 0
        Top = 0
        Width = 1176
        Height = 80
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object lblAlmacenInfo: TcxLabel
          Left = 8
          Top = 8
          Caption = 
            'Marca uno o varios almacenes para acotar el filtro "S'#243'lo con stock". Si no marcas ninguno y activas el filtro, no se incluir'#225' ning'#250'n art'#237'culo.'
          TabOrder = 3
          Transparent = True
        end
        object rgStockCombinacion: TcxRadioGroup
          Left = 8
          Top = 32
          Caption = ' Combinaci'#243'n entre almacenes '
          Properties.Columns = 3
          Properties.Items = <
            item
              Caption = 'Stock > 0 en cualquiera (OR)'
            end
            item
              Caption = 'Stock > 0 en todos (AND)'
            end
            item
              Caption = 'Suma total > 0'
            end>
          ItemIndex = 0
          TabOrder = 0
          Height = 45
          Width = 480
        end
        object btnMarcarTodosAlm: TcxButton
          Left = 510
          Top = 44
          Width = 130
          Height = 25
          Caption = 'Marcar todos'
          TabOrder = 1
          OnClick = btnMarcarTodosAlmClick
        end
        object btnDesmarcarTodosAlm: TcxButton
          Left = 650
          Top = 44
          Width = 138
          Height = 25
          Caption = 'Desmarcar todos'
          TabOrder = 2
          OnClick = btnDesmarcarTodosAlmClick
        end
        object lblSelAlmacenes: TcxLabel
          Left = 800
          Top = 48
          Caption = '(0 sel.)'
          TabOrder = 4
          Transparent = True
        end
        object lblReservaStockOrigen: TcxLabel
          Left = 8
          Top = 86
          Caption = 'Stock m'#237'nimo que debe quedar en origen:'
          TabOrder = 5
          Transparent = True
          Visible = False
        end
        object spnReservaStockOrigen: TcxSpinEdit
          Left = 295
          Top = 82
          Properties.MinValue = 0.000000000000000000
          TabOrder = 6
          Value = 0
          Visible = False
          Width = 80
        end
        object lblMaximoServirPorSku: TcxLabel
          Left = 400
          Top = 86
          Caption = 'Cantidad m'#225'xima a servir por SKU:'
          TabOrder = 7
          Transparent = True
          Visible = False
        end
        object spnMaximoServirPorSku: TcxSpinEdit
          Left = 640
          Top = 82
          Properties.MinValue = 1.000000000000000000
          TabOrder = 8
          Value = 1
          Visible = False
          Width = 80
        end
      end
      object chkLstAlmacenes: TcxCheckListBox
        Left = 0
        Top = 80
        Width = 1176
        Height = 227
        Align = alClient
        Columns = 2
        Items = <>
        TabOrder = 1
      end
    end
    object tsFechaAlta: TcxTabSheet
      Caption = '&5_Fecha alta'
      ImageIndex = 4
      ExplicitLeft = 3
      ExplicitTop = 32
      ExplicitWidth = 1171
      ExplicitHeight = 302
      object chkAplicarFechaAlta: TcxCheckBox
        Left = 16
        Top = 16
        Caption = 'Filtrar por fecha de alta del art'#237'culo'
        TabOrder = 0
        Transparent = True
      end
      object lblAltaDesde: TcxLabel
        Left = 16
        Top = 56
        Caption = 'Desde:'
        TabOrder = 3
        Transparent = True
      end
      object dtAltaDesde: TcxDateEdit
        Left = 100
        Top = 52
        TabOrder = 1
        Width = 140
      end
      object lblAltaHasta: TcxLabel
        Left = 16
        Top = 96
        Caption = 'Hasta:'
        TabOrder = 4
        Transparent = True
      end
      object dtAltaHasta: TcxDateEdit
        Left = 100
        Top = 92
        TabOrder = 2
        Width = 140
      end
    end
    object tsVentas: TcxTabSheet
      Caption = '&6_Ventas'
      ImageIndex = 5
      object chkConVenta: TcxCheckBox
        Left = 16
        Top = 16
        Caption = 'Filtrar seg'#250'n hist'#243'rico de ventas'
        TabOrder = 0
        Transparent = True
      end
      object lblVtaDesde: TcxLabel
        Left = 16
        Top = 56
        Caption = 'Periodo desde:'
        TabOrder = 5
        Transparent = True
      end
      object dtVtaDesde: TcxDateEdit
        Left = 150
        Top = 52
        TabOrder = 1
        Width = 140
      end
      object lblVtaHasta: TcxLabel
        Left = 16
        Top = 96
        Caption = 'Periodo hasta:'
        TabOrder = 6
        Transparent = True
      end
      object dtVtaHasta: TcxDateEdit
        Left = 150
        Top = 92
        TabOrder = 2
        Width = 140
      end
      object rgConSinVenta: TcxRadioGroup
        Left = 16
        Top = 130
        Caption = ' Tipo '
        Properties.Items = <
          item
            Caption = 'Art'#237'culos CON ventas en el periodo'
          end
          item
            Caption = 'Art'#237'culos SIN ventas en el periodo'
          end>
        ItemIndex = 0
        TabOrder = 3
        Height = 70
        Width = 350
      end
      object lblNumMinVtas: TcxLabel
        Left = 16
        Top = 220
        Caption = 'N'#250'mero m'#237'nimo de ventas:'
        TabOrder = 7
        Transparent = True
      end
      object spnNumMinVtas: TcxSpinEdit
        Left = 220
        Top = 216
        Properties.MinValue = 1.000000000000000000
        TabOrder = 4
        Value = 1
        Width = 80
      end
      object lblAlmacenesVentas: TcxLabel
        Left = 410
        Top = 16
        Caption = 'Almacenes donde se realizaron las ventas:'
        TabOrder = 5
        Transparent = True
        Visible = False
      end
      object chkLstAlmacenesVentas: TcxCheckListBox
        Left = 410
        Top = 45
        Width = 390
        Height = 210
        Items = <>
        TabOrder = 6
        Visible = False
      end
      object chkFiltrarStockAlmacenVenta: TcxCheckBox
        Left = 820
        Top = 45
        Caption = 'Cargar art'#237'culos sin stock en almac'#233'n de ventas'
        TabOrder = 7
        Visible = False
        Transparent = True
      end
      object lblStockMaximoAlmacenVenta: TcxLabel
        Left = 842
        Top = 82
        Caption = 'Stock m'#225'ximo a considerar:'
        TabOrder = 8
        Transparent = True
        Visible = False
      end
      object spnStockMaximoAlmacenVenta: TcxSpinEdit
        Left = 1045
        Top = 78
        Properties.MinValue = 0.000000000000000000
        TabOrder = 9
        Value = 0
        Visible = False
        Width = 80
      end
    end
  end
  object splitterPreview: TcxSplitter [3]
    Left = 0
    Top = 488
    Width = 1180
    Height = 10
    AlignSplitter = salBottom
    Control = pnlPreview
    ExplicitTop = 163
    ExplicitWidth = 622
  end
  object pnlPreview: TPanel [4]
    Left = 0
    Top = 498
    Width = 1180
    Height = 220
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 4
    ExplicitWidth = 1182
    object lblPreviewInfo: TcxLabel
      Left = 12
      Top = 4
      Caption = '0 art'#237'culos'
      TabOrder = 1
      Transparent = True
    end
    object grdPreview: TcxGrid
      Left = 0
      Top = 0
      Width = 1180
      Height = 220
      Align = alClient
      TabOrder = 0
      ExplicitTop = 28
      ExplicitHeight = 192
      object tvPreview: TcxGridDBTableView
        OptionsData.CancelOnExit = False
        OptionsData.Deleting = False
        OptionsData.Editing = False
        OptionsData.Inserting = False
        OptionsView.GroupByBox = False
        object colPrevCodigo: TcxGridDBColumn
          Caption = 'Artículo'
          DataBinding.FieldName = 'CODIGO_ART_ART'
          Width = 130
        end
        object colPrevDescripcion: TcxGridDBColumn
          Caption = 'Descripción'
          DataBinding.FieldName = 'DESCRIPCION_ART'
          Width = 280
        end
        object colPrevFamilia: TcxGridDBColumn
          Caption = 'Familia'
          DataBinding.FieldName = 'NOMBRE_FAM_FAM'
          Width = 150
        end
        object colPrevProveedor: TcxGridDBColumn
          Caption = 'Proveedores'
          DataBinding.FieldName = 'PROVEEDORES'
          Width = 120
        end
        object colPrevStock: TcxGridDBColumn
          Caption = 'Stock'
          DataBinding.FieldName = 'STOCK_TOTAL'
          PropertiesClassName = 'TcxCurrencyEditProperties'
          Properties.DisplayFormat = '#,##0.##'
          Width = 70
        end
        object colPrevYaCargado: TcxGridDBColumn
          Caption = 'Ya cargado'
          DataBinding.FieldName = 'YA_CARGADO'
          Width = 80
        end
      end
      object lvPreview: TcxGridLevel
        GridView = tvPreview
      end
    end
  end
  object pnlBotonera: TPanel [5]
    Left = 0
    Top = 718
    Width = 1180
    Height = 42
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 5
    object btnAceptar: TcxButton
      Left = 960
      Top = 8
      Width = 100
      Height = 28
      Caption = '&Aceptar'
      Default = True
      TabOrder = 0
      OnClick = btnAceptarClick
    end
    object btnCancelar: TcxButton
      Left = 1068
      Top = 8
      Width = 100
      Height = 28
      Cancel = True
      Caption = '&Cancelar'
      TabOrder = 1
      OnClick = btnCancelarClick
    end
  end
  inherited Localizer1: TcxLocalizer
    Left = 16
    Top = 600
  end
end
