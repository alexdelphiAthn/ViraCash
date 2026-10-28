inherited frmMtoArticulos: TfrmMtoArticulos
  Left = 5
  Top = 4
  Caption = 'Articulos'
  ClientHeight = 711
  ClientWidth = 1217
  OnDestroy = FormDestroy
  ExplicitWidth = 1217
  ExplicitHeight = 711
  TextHeight = 17
  inherited pButtonPage: TPanel
    Width = 1077
    Height = 711
    TabOrder = 0
    ExplicitWidth = 1077
    ExplicitHeight = 711
    inherited pcPantalla: TcxPageControl
      Width = 1077
      Height = 671
      TabOrder = 1
      ExplicitWidth = 1077
      ExplicitHeight = 671
      ClientRectBottom = 667
      ClientRectRight = 1073
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 28
        ExplicitWidth = 1069
        ExplicitHeight = 639
        inherited cxGrdPrincipal: TcxGrid
          Top = 60
          Width = 1069
          Height = 579
          ExplicitTop = 60
          ExplicitWidth = 1069
          ExplicitHeight = 578
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            object cxgrdbclmnGrdDBTabPrinCODIGO_ARTICULO: TcxGridDBColumn
              Caption = 'C'#243'digo Art'#237'culo'
              DataBinding.FieldName = 'CODIGO_ART_ART'
              Width = 150
            end
            object cxgrdbclmnGrdDBTabPrinACTIVO_ARTICULO: TcxGridDBColumn
              Caption = 'Activo'
              DataBinding.FieldName = 'ESACTIVO_ART'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 76
            end
            object cxgrdbclmnGrdDBTabPrinDESCRIPCION_ARTICULO: TcxGridDBColumn
              Caption = 'Descripci'#243'n'
              DataBinding.FieldName = 'DESCRIPCION_ART'
              Width = 205
            end
            object cxgrdbclmnGrdDBTabPrinCODIGO_FAMILIA_ARTICULO: TcxGridDBColumn
              Caption = 'C'#243'digo Familia'
              DataBinding.FieldName = 'CODIGO_FAM_ART'
              PropertiesClassName = 'TcxTextEditProperties'
              Width = 149
            end
            object cxgrdbclmnGrdDBTabPrinDESCRIPCION_FAMILIA: TcxGridDBColumn
              Caption = 'Descripci'#243'n Familia'
              DataBinding.FieldName = 'DESCRIPCION_FAM'
              Width = 470
            end
            object cxgrdbclmnGrdDBTabPrinTIPOIVA_ARTICULO: TcxGridDBColumn
              Caption = 'Tipo IVA'
              DataBinding.FieldName = 'NOMBRE_TIPO_IVA_IVATIP'
              PropertiesClassName = 'TcxTextEditProperties'
              Width = 130
            end
            object cxgrdbclmnGrdDBTabPrinREF_PROVEEDOR: TcxGridDBColumn
              Caption = 'Modelo Proveedor'
              DataBinding.FieldName = 'REF_PROVEEDOR'
              PropertiesClassName = 'TcxTextEditProperties'
              Width = 150
            end
            object cxgrdbclmnGrdDBTabPrinNOMBRE_PRV: TcxGridDBColumn
              Caption = 'Proveedor'
              DataBinding.FieldName = 'NOMBRE_PRV'
              PropertiesClassName = 'TcxTextEditProperties'
              Width = 180
            end
            object cxgrdbclmnGrdDBTabPrinTEMPORADA_ART: TcxGridDBColumn
              Caption = 'Temporada'
              DataBinding.FieldName = 'TEMPORADA_ART'
              PropertiesClassName = 'TcxTextEditProperties'
              Width = 150
            end
          end
        end
        object pnlFiltrosArt: TPanel
          Left = 0
          Top = 0
          Width = 1069
          Height = 60
          Align = alTop
          BevelOuter = bvNone
          ParentBackground = False
          TabOrder = 1
          object btnToggleFiltrosArt: TcxButton
            Left = 0
            Top = 0
            Width = 1069
            Height = 22
            Align = alTop
            Caption = #9654'  Filtros de carga'
            LookAndFeel.Kind = lfUltraFlat
            LookAndFeel.NativeStyle = False
            TabOrder = 0
            OnClick = btnToggleFiltrosArtClick
          end
          object pnlContFiltrosArt: TPanel
            Left = 0
            Top = 22
            Width = 1069
            Height = 38
            Align = alClient
            BevelOuter = bvNone
            ParentBackground = False
            TabOrder = 1
            object lblFiltroEstadoArt: TcxLabel
              Left = 32
              Top = 8
              Caption = 'Estado:'
              TabOrder = 3
              Transparent = True
            end
            object cbbFiltroEstadoArt: TcxComboBox
              Left = 98
              Top = 4
              Properties.DropDownListStyle = lsFixedList
              Properties.Items.Strings = (
                'Todos'
                'S'#243'lo activos'
                'S'#243'lo inactivos')
              Properties.OnEditValueChanged = cbbFiltroEstadoArtPropertiesEditValueChanged
              TabOrder = 0
              Text = 'S'#243'lo activos'
              Width = 145
            end
            object chkFiltroConStockArt: TcxCheckBox
              Left = 297
              Top = 8
              Caption = 'S'#243'lo con stock'
              Properties.OnEditValueChanged = chkFiltroConStockArtPropertiesEditValueChanged
              TabOrder = 1
              Transparent = True
            end
            object lblFiltroTemporadaArt: TcxLabel
              Left = 477
              Top = 8
              Caption = 'Temporadas:'
              TabOrder = 4
              Transparent = True
            end
            object ccbFiltroTemporadaArt: TcxCheckComboBox
              Left = 605
              Top = 4
              Properties.EmptySelectionText = 'Ninguna seleccionada'
              Properties.EditValueFormat = cvfStatesString
              Properties.Items = <>
              Properties.OnCloseUp = ccbFiltroTemporadaArtPropertiesCloseUp
              TabOrder = 2
              Width = 210
            end
            object btnCargarAhoraArt: TcxButton
              Left = 823
              Top = 4
              Width = 105
              Height = 25
              Caption = 'Cargar ahora'
              TabOrder = 5
              OnClick = btnCargarAhoraArtClick
            end
            object btnGuardarPrecargaArt: TcxButton
              Left = 932
              Top = 4
              Width = 137
              Height = 25
              Caption = 'Guardar precarga'
              TabOrder = 6
              OnClick = btnGuardarPrecargaArtClick
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 28
        ExplicitWidth = 1069
        ExplicitHeight = 639
        object pnlTopFicha: TPanel
          Left = 0
          Top = 0
          Width = 1069
          Height = 174
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          object pnlBodyFicha: TPanel
            Left = 0
            Top = 0
            Width = 1069
            Height = 174
            Align = alClient
            BevelOuter = bvNone
            TabOrder = 0
            object txtCODIGO_ARTICULO: TcxDBTextEdit
              Left = 100
              Top = 13
              DataBinding.DataField = 'CODIGO_ART_ART'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = False
              TabOrder = 0
              OnExit = txtCODIGO_ARTICULOExit
              Width = 231
            end
            object lblCodigo: TcxLabel
              Left = 41
              Top = 14
              Caption = 'C'#243'digo'
              TabOrder = 1
              Transparent = True
            end
            object lblNombre: TcxLabel
              Left = 36
              Top = 55
              Caption = 'Nombre'
              TabOrder = 5
              Transparent = True
            end
            object txtDESCRIPCION_ARTICULO: TcxDBTextEdit
              Left = 100
              Top = 54
              DataBinding.DataField = 'DESCRIPCION_ART'
              DataBinding.DataSource = dsTablaG
              TabOrder = 4
              Width = 597
            end
            object chkActivo: TcxDBCheckBox
              Left = 348
              Top = 10
              Caption = 'Activo'
              DataBinding.DataField = 'ESACTIVO_ART'
              DataBinding.DataSource = dsTablaG
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              TabOrder = 2
              Transparent = True
            end
            object chkEnWeb: TcxDBCheckBox
              Left = 420
              Top = 10
              Caption = 'En web'
              DataBinding.DataField = 'ESWEB_ART'
              DataBinding.DataSource = dsTablaG
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              TabOrder = 3
              Transparent = True
            end
            object cbbFamilia: TcxDBLookupComboBox
              Left = 100
              Top = 95
              DataBinding.DataField = 'CODIGO_FAM_ART'
              DataBinding.DataSource = dsTablaG
              ParentShowHint = False
              Properties.AllowDropDownWhenReadOnly = False
              Properties.KeyFieldNames = 'CODIGO_FAM_FAM'
              Properties.ListColumns = <
                item
                  Fixed = True
                  SortOrder = soAscending
                  Width = 100
                  FieldName = 'CODIGO_FAM_FAM'
                end
                item
                  Fixed = True
                  FieldName = 'NOMBRE_FAM_FAM'
                end>
              Properties.ListOptions.ShowHeader = False
              Properties.ReadOnly = True
              Properties.OnEditValueChanged = cbbFamiliaPropertiesEditValueChanged
              ShowHint = True
              TabOrder = 6
              Width = 322
            end
            object btnSeleccionarFamilia: TcxButton
              Left = 428
              Top = 94
              Width = 34
              Height = 24
              Hint = 'Seleccionar familia en '#225'rbol'
              Caption = '...'
              ParentShowHint = False
              ShowHint = True
              TabOrder = 7
              OnClick = btnSeleccionarFamiliaClick
            end
            object btnQuitarFamilia: TcxButton
              Left = 468
              Top = 94
              Width = 34
              Height = 24
              Hint = 'Quitar familia'
              Caption = 'X'
              ParentShowHint = False
              ShowHint = True
              TabOrder = 8
              OnClick = btnQuitarFamiliaClick
            end
            object lblFamilia: TcxLabel
              Left = 39
              Top = 96
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              Caption = 'Familia'
              Properties.Alignment.Horz = taRightJustify
              TabOrder = 9
              Transparent = True
              AnchorX = 90
            end
            object dbcDESCRIPCION_FAM: TcxDBLabel
              Left = 298
              Top = 128
              DataBinding.DataField = 'DESCRIPCION_FAM'
              DataBinding.DataSource = dsTablaG
              TabOrder = 10
              Transparent = True
              Height = 21
              Width = 538
            end
            object dbcNOMBRE_FAM_FAM: TcxDBLabel
              Left = 18
              Top = 128
              DataBinding.DataField = 'NOMBRE_FAM_FAM'
              DataBinding.DataSource = dsTablaG
              TabOrder = 11
              Transparent = True
              Height = 21
              Width = 274
            end
          end
        end
        object pnlButtonFicha: TPanel
          Left = 0
          Top = 182
          Width = 1069
          Height = 457
          Align = alClient
          BevelOuter = bvNone
          TabOrder = 2
          object pcDetail: TcxPageControl
            Left = 0
            Top = 0
            Width = 1069
            Height = 457
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsGeneral
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 453
            ClientRectLeft = 4
            ClientRectRight = 1065
            ClientRectTop = 28
            object tsGeneral: TcxTabSheet
              Caption = '&1_General'
              ImageIndex = 4
              ExplicitTop = 29
              ExplicitHeight = 423
              object sbGeneral: TcxScrollBox
                Left = 0
                Top = 0
                Width = 1061
                Height = 425
                Align = alClient
                BorderStyle = cxcbsNone
                LookAndFeel.ScrollbarMode = sbmClassic
                TabOrder = 0
                object pnlContenidoGeneral: TPanel
                  Left = 0
                  Top = 0
                  Width = 1061
                  Height = 220
                  Align = alTop
                  AutoSize = True
                  BevelOuter = bvNone
                  Constraints.MinWidth = 620
                  TabOrder = 0
                  object rgTipoIVA: TcxDBRadioGroup
                    Left = 408
                    Top = 19
                    Caption = 'Tipo de IVA'
                    DataBinding.DataField = 'TIPO_IVA_ART'
                    DataBinding.DataSource = dsTablaG
                    Properties.Items = <
                      item
                        Caption = 'Normal'
                        Value = 'N'
                      end
                      item
                        Caption = 'Reducido'
                        Value = 'R'
                      end
                      item
                        Caption = 'S'#250'per Reducido'
                        Value = 'S'
                      end
                      item
                        Caption = 'Exento'
                        Value = 'E'
                      end>
                    TabOrder = 0
                    Height = 122
                    Width = 185
                  end
                  object cxGroupBox2: TcxGroupBox
                    Left = 23
                    Top = 19
                    Caption = 'Tipolog'#237'a'
                    TabOrder = 1
                    Height = 122
                    Width = 379
                    object lblNombre1: TcxLabel
                      Left = 24
                      Top = 77
                      Caption = 'Tipo de Cantidad'
                      TabOrder = 0
                      Transparent = True
                    end
                    object cbbTipoCantidad: TcxDBLookupComboBox
                      Left = 180
                      Top = 71
                      DataBinding.DataField = 'TIPO_CANTIDAD_ART'
                      DataBinding.DataSource = dsTablaG
                      Properties.KeyFieldNames = 'CODIGO_UNIMED'
                      Properties.ListColumns = <
                        item
                          Fixed = True
                          Width = 80
                          FieldName = 'CODIGO_UNIMED'
                        end
                        item
                          FieldName = 'DESCRIPCION_UNIMED'
                        end>
                      Properties.ListOptions.ShowHeader = False
                      TabOrder = 1
                      Width = 130
                    end
                    object lblTipoArticulo: TcxLabel
                      Left = 32
                      Top = 37
                      Caption = 'Tipo de Art'#237'culo'
                      TabOrder = 2
                      Transparent = True
                    end
                    object cbbTIPO_ART: TcxDBComboBox
                      Left = 180
                      Top = 33
                      DataBinding.DataField = 'TIPO_ART'
                      DataBinding.DataSource = dsTablaG
                      Properties.Items.Strings = (
                        'ESTANDAR'
                        'SERVICIO')
                      Properties.OnEditValueChanged = cxDBComboBox1PropertiesEditValueChanged
                      TabOrder = 3
                      Width = 167
                    end
                  end
                  object chkESVARIACION_ART: TcxDBCheckBox
                    Left = 23
                    Top = 147
                    Caption = 'Tiene Variaciones/SKU m'#250'ltiple'
                    DataBinding.DataField = 'ESVARIACION_ART'
                    DataBinding.DataSource = dsTablaG
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    Properties.OnEditValueChanged = cxDBCheckBox1PropertiesEditValueChanged
                    TabOrder = 2
                    Transparent = True
                  end
                  object chkESTRAZABLE_ART: TcxDBCheckBox
                    Left = 23
                    Top = 184
                    Caption =
                      'Trazabilidad/Serializaci'#243'n por unidad y/o LOTE/Fecha de Caducida' +
                      'd'
                    DataBinding.DataField = 'ESTRAZABLE_ART'
                    DataBinding.DataSource = dsTablaG
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    TabOrder = 3
                    Transparent = True
                  end
                end
              end
            end
            object tsSkuMto: TcxTabSheet
              Caption = '&2_SKUs'
              ImageIndex = 6
              ExplicitLeft = 0
              ExplicitTop = 0
              ExplicitWidth = 0
              ExplicitHeight = 0
              object pnlTopSkus: TPanel
                Left = 0
                Top = 0
                Width = 1061
                Height = 257
                Align = alTop
                BevelOuter = bvNone
                TabOrder = 0
                object pnlSkuMto: TPanel
                  Left = 881
                  Top = 0
                  Width = 180
                  Height = 257
                  Align = alRight
                  TabOrder = 0
                  object addSkuAll: TcxButton
                    Left = 0
                    Top = 21
                    Width = 175
                    Height = 34
                    Caption = '&A'#241'adir SKU'
                    TabOrder = 0
                    OnClick = addSkuAllClick
                  end
                  object btnColorSkus: TcxButton
                    Left = 0
                    Top = 61
                    Width = 175
                    Height = 34
                    Caption = 'Activar/Desact. fila'
                    TabOrder = 1
                    OnClick = btnColorSkusClick
                  end
                end
                object cxgrdSkuMto: TcxGrid
                  Left = 0
                  Top = 0
                  Width = 881
                  Height = 257
                  Align = alClient
                  TabOrder = 1
                  object tvSkuMto: TcxGridDBTableView
                    Navigator.Buttons.ConfirmDelete = True
                    Navigator.Buttons.Insert.Visible = True
                    Navigator.Buttons.Delete.Visible = True
                    Navigator.Buttons.Edit.Visible = False
                    Navigator.Buttons.Post.Visible = True
                    Navigator.Buttons.Cancel.Visible = True
                    Navigator.Visible = True
                    DataController.DataSource = dmArticulos.dsSkus
                    DataController.Options = [dcoCaseInsensitive, dcoAssignGroupingValues, dcoAssignMasterDetailKeys, dcoSaveExpanding]
                    OptionsBehavior.AlwaysShowEditor = True
                    OptionsBehavior.GoToNextCellOnEnter = True
                    OptionsBehavior.IncSearch = True
                    OptionsCustomize.ColumnHiding = True
                    OptionsData.Inserting = False
                    OptionsView.GroupByBox = False
                    OptionsView.Indicator = True
                    object tvSkuMtoCODIGO_UNIDAD_SKU: TcxGridDBColumn
                      Caption = 'C'#243'digo SKU'
                      DataBinding.FieldName = 'CODIGO_UNIDAD_SKU'
                      Options.Editing = False
                      Width = 350
                    end
                    object tvSkuMtoCODIGO_VAR_SKU: TcxGridDBColumn
                      Caption = 'Variaci'#243'n'
                      DataBinding.FieldName = 'CODIGO_VAR_SKU'
                      Options.Editing = False
                      Width = 80
                    end
                    object tvSkuMtoESACTIVO_SKU: TcxGridDBColumn
                      Caption = 'Activo'
                      DataBinding.FieldName = 'ESACTIVO_SKU'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Width = 70
                    end
                    object tvSkuMtoPRECIO_ULT_COMPRA_SKUC: TcxGridDBColumn
                      Caption = 'Precio '#218'lt Compra'
                      DataBinding.FieldName = 'PRECIO_ULT_COMPRA_SKUC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Options.Editing = False
                      Width = 165
                    end
                    object tvSkuMtoFECHA_ULT_COMPRA_SKUC: TcxGridDBColumn
                      Caption = 'Fecha '#218'lt Compra'
                      DataBinding.FieldName = 'FECHA_ULT_COMPRA_SKUC'
                      PropertiesClassName = 'TcxDateEditProperties'
                      Options.Editing = False
                      Width = 145
                    end
                    object tvSkuMtoCODIGO_ART_SKU: TcxGridDBColumn
                      DataBinding.FieldName = 'CODIGO_ART_SKU'
                      Visible = False
                    end
                  end
                  object cxgrdSkuMtoLevel: TcxGridLevel
                    GridView = tvSkuMto
                  end
                end
              end
              object splSkuAtributosBasicos: TcxSplitter
                Left = 0
                Top = 257
                Width = 1061
                Height = 10
                AlignSplitter = salTop
                Control = pnlTopSkus
              end
              object gbSkuAtributosBasicos: TcxGroupBox
                Left = 0
                Top = 267
                Align = alClient
                Caption = ' Atributos del SKU + Atributo b'#225'sico (helper) '
                TabOrder = 2
                Height = 158
                Width = 1061
                object cxgrdSkuAtributosBasicos: TcxGrid
                  Left = 2
                  Top = 22
                  Width = 1057
                  Height = 134
                  Align = alClient
                  PopupMenu = pmColorSkus
                  TabOrder = 0
                  ExplicitTop = 23
                  ExplicitHeight = 131
                  object tvSkuAtributosBasicos: TcxGridDBTableView
                    OnDblClick = tvSkuAtributosBasicosDblClick
                    Navigator.Buttons.ConfirmDelete = True
                    Navigator.Buttons.First.Visible = True
                    Navigator.Buttons.PriorPage.Visible = False
                    Navigator.Buttons.Prior.Visible = True
                    Navigator.Buttons.Next.Visible = True
                    Navigator.Buttons.NextPage.Visible = False
                    Navigator.Buttons.Last.Visible = True
                    Navigator.Buttons.Insert.Visible = False
                    Navigator.Buttons.Append.Visible = False
                    Navigator.Buttons.Delete.Visible = False
                    Navigator.Buttons.Edit.Visible = False
                    Navigator.Buttons.Post.Visible = False
                    Navigator.Buttons.Cancel.Visible = True
                    Navigator.Buttons.Refresh.Visible = True
                    Navigator.Buttons.SaveBookmark.Visible = False
                    Navigator.Buttons.GotoBookmark.Visible = False
                    Navigator.Buttons.Filter.Visible = True
                    Navigator.Visible = True
                    DataController.DataSource = dmArticulos.dsDetallesAtributos
                    DataController.Options = [dcoCaseInsensitive, dcoAssignGroupingValues, dcoAssignMasterDetailKeys, dcoSaveExpanding]
                    OptionsBehavior.IncSearch = True
                    OptionsCustomize.ColumnHiding = True
                    OptionsData.Deleting = False
                    OptionsData.DeletingConfirmation = False
                    OptionsData.Inserting = False
                    OptionsView.GroupByBox = False
                    OptionsView.Indicator = True
                    object tvSkuAtributosBasicosID_VA_AV: TcxGridDBColumn
                      Caption = 'Atributo'
                      DataBinding.FieldName = 'ID_VA_AV'
                      Options.Editing = False
                      Width = 105
                    end
                    object tvSkuAtributosBasicosNOMBRE_ATRIBUTO: TcxGridDBColumn
                      Caption = 'Nombre atributo'
                      DataBinding.FieldName = 'NOMBRE_ATRIBUTO'
                      Options.Editing = False
                      Width = 169
                    end
                    object tvSkuAtributosBasicosVALOR_AV: TcxGridDBColumn
                      Caption = 'Valor proveedor'
                      DataBinding.FieldName = 'VALOR_AV'
                      Options.Editing = False
                      Width = 140
                    end
                    object tvSkuAtributosBasicosID_ATB_AV: TcxGridDBColumn
                      Caption = 'Atributo b'#225'sico'
                      DataBinding.FieldName = 'ID_ATB_AV'
                      PropertiesClassName = 'TcxLookupComboBoxProperties'
                      Properties.DropDownAutoSize = True
                      Properties.DropDownListStyle = lsEditList
                      Properties.KeyFieldNames = 'ID_ATB'
                      Properties.ListColumns = <
                        item
                          Caption = 'C'#243'digo'
                          Width = 110
                          FieldName = 'CODIGO_ATB'
                        end
                        item
                          Caption = 'Paleta'
                          Width = 32
                          FieldName = 'HEX_ATB'
                        end>
                      Properties.ListOptions.ShowHeader = False
                      Properties.ListSource = dmArticulos.dsAtributosBasicosLookup
                      Properties.OnCloseUp = tvSkuAtributosBasicosID_ATB_AVPropertiesCloseUp
                      Properties.OnEditValueChanged = tvSkuAtributosBasicosID_ATB_AVPropertiesEditValueChanged
                      Properties.OnInitPopup = tvSkuAtributosBasicosID_ATB_AVPropertiesInitPopup
                      Properties.OnValidate = tvSkuAtributosBasicosID_ATB_AVPropertiesValidate
                      Width = 190
                    end
                    object tvSkuAtributosBasicosDESCRIPCION_AAB: TcxGridDBColumn
                      Caption = 'Descripci'#243'n del valor'
                      DataBinding.FieldName = 'DESCRIPCION_AAB'
                      PropertiesClassName = 'TcxTextEditProperties'
                      Properties.OnEditValueChanged = tvSkuAtributosBasicosDESCRIPCION_AABPropertiesEditValueChanged
                      Width = 220
                    end
                    object tvSkuAtributosBasicosNOMBRE_ATB: TcxGridDBColumn
                      Caption = 'Nombre b'#225'sico'
                      DataBinding.FieldName = 'NOMBRE_ATB'
                      PropertiesClassName = 'TcxTextEditProperties'
                      Properties.OnEditValueChanged = tvSkuAtributosBasicosNOMBRE_ATBPropertiesEditValueChanged
                      Visible = False
                      Width = 130
                    end
                    object tvSkuAtributosBasicosHEX_ATB: TcxGridDBColumn
                      Caption = 'Paleta'
                      DataBinding.FieldName = 'HEX_ATB'
                      PropertiesClassName = 'TcxButtonEditProperties'
                      Properties.Buttons = <
                        item
                          Default = True
                          Kind = bkEllipsis
                        end>
                      Properties.OnButtonClick = tvSkuAtributosBasicosHEX_ATBPropertiesButtonClick
                      OnCustomDrawCell = tvSkuAtributosBasicosHEX_ATBCustomDrawCell
                      Width = 100
                    end
                    object tvSkuAtributosBasicosVALOR_NUM_ATB: TcxGridDBColumn
                      Caption = 'Valor b'#225'sico'
                      DataBinding.FieldName = 'VALOR_NUM_ATB'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Properties.DisplayFormat = '#,##0.##;-#,##0.##; '
                      Properties.OnEditValueChanged = tvSkuAtributosBasicosVALOR_NUM_ATBPropertiesEditValueChanged
                      Width = 90
                    end
                    object tvSkuAtributosBasicosUNIDAD_ATB: TcxGridDBColumn
                      Caption = 'Unidad'
                      DataBinding.FieldName = 'UNIDAD_ATB'
                      PropertiesClassName = 'TcxTextEditProperties'
                      Properties.OnEditValueChanged = tvSkuAtributosBasicosUNIDAD_ATBPropertiesEditValueChanged
                      Width = 60
                    end
                    object tvSkuAtributosBasicosETIQUETA_BASICO: TcxGridDBColumn
                      Caption = 'Equivalencia'
                      DataBinding.FieldName = 'ETIQUETA_BASICO'
                      Visible = False
                      Options.Editing = False
                      Width = 160
                    end
                    object tvSkuAtributosBasicosFUENTE_ATB: TcxGridDBColumn
                      Caption = 'Fuente'
                      DataBinding.FieldName = 'FUENTE_ATB'
                      Visible = False
                      OnGetDisplayText = tvSkuAtributosBasicosFUENTE_ATBGetDisplayText
                      Options.Editing = False
                      Width = 80
                    end
                  end
                  object cxgrdSkuAtributosBasicosLevel: TcxGridLevel
                    GridView = tvSkuAtributosBasicos
                  end
                end
              end
            end
            object tsPropiedades: TcxTabSheet
              Caption = '&3_Propiedades'
              ImageIndex = 9
              ExplicitLeft = 0
              ExplicitTop = 0
              ExplicitWidth = 0
              ExplicitHeight = 0
            end
            object tsSKUs: TcxTabSheet
              Caption = '&4_CB'
              ImageIndex = 6
              ExplicitLeft = 0
              ExplicitTop = 0
              ExplicitWidth = 0
              ExplicitHeight = 0
              object pnlBotonesCB: TPanel
                Left = 940
                Top = 0
                Width = 121
                Height = 423
                Align = alRight
                TabOrder = 0
                object btnExportarExcelCB: TcxButton
                  Left = 0
                  Top = 141
                  Width = 116
                  Height = 34
                  Caption = '&Exp Excel'
                  TabOrder = 0
                  OnClick = btnExportarProveedorClick
                end
                object btnGenerarCB: TcxButton
                  Left = 0
                  Top = 61
                  Width = 116
                  Height = 34
                  Caption = '&Generar CB'
                  TabOrder = 2
                  OnClick = btnGenerarCBClick
                end
                object btnVerificarCB: TcxButton
                  Left = 0
                  Top = 101
                  Width = 116
                  Height = 34
                  Caption = '&Verificar CB'
                  TabOrder = 1
                  OnClick = btnVerificarCBClick
                end
              end
              object cxgrdSkus: TcxGrid
                Left = 0
                Top = 0
                Width = 940
                Height = 423
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Align = alClient
                TabOrder = 1
                object tvSkus: TcxGridDBTableView
                  OnDblClick = cxGrdDBTabPrinDblClick
                  Navigator.Buttons.ConfirmDelete = True
                  Navigator.Buttons.First.Hint = 'Va al primer Registro'
                  Navigator.Buttons.First.Visible = False
                  Navigator.Buttons.PriorPage.Hint = 'Va a la p'#225'gina anterior'
                  Navigator.Buttons.PriorPage.Visible = False
                  Navigator.Buttons.Prior.Hint = 'Va al Registro Anterior'
                  Navigator.Buttons.Prior.Visible = False
                  Navigator.Buttons.Next.Hint = 'Va al siguiente Registro'
                  Navigator.Buttons.Next.Visible = False
                  Navigator.Buttons.NextPage.Hint = 'Va a la p'#225'gina siguiente'
                  Navigator.Buttons.NextPage.Visible = False
                  Navigator.Buttons.Last.Hint = 'Va al '#250'ltimo registro'
                  Navigator.Buttons.Last.Visible = False
                  Navigator.Buttons.Insert.Hint = 'Inserta un nuevo Registro'
                  Navigator.Buttons.Insert.Visible = True
                  Navigator.Buttons.Delete.Hint = 'Borra el registro Activo'
                  Navigator.Buttons.Delete.Visible = True
                  Navigator.Buttons.Edit.Enabled = False
                  Navigator.Buttons.Edit.Hint = 'Edita registro Actual'
                  Navigator.Buttons.Edit.Visible = False
                  Navigator.Buttons.Post.Hint = 'Guarda Datos introducidos'
                  Navigator.Buttons.Post.Visible = True
                  Navigator.Buttons.Cancel.Hint = 'Cancela la edici'#243'n actual'
                  Navigator.Buttons.Cancel.Visible = True
                  Navigator.Buttons.Refresh.Hint = 'Refresca Datos Activos'
                  Navigator.Buttons.SaveBookmark.Enabled = False
                  Navigator.Buttons.SaveBookmark.Hint = 'Marca Registro Actual'
                  Navigator.Buttons.SaveBookmark.Visible = False
                  Navigator.Buttons.GotoBookmark.Enabled = False
                  Navigator.Buttons.GotoBookmark.Hint = 'Va al registro Marcado'
                  Navigator.Buttons.GotoBookmark.Visible = False
                  Navigator.Buttons.Filter.Hint = 'Filtro personalizado'
                  Navigator.Visible = True
                  DataController.DataSource = dmArticulos.dsVariacionesArticulos
                  DataController.Options = [dcoCaseInsensitive, dcoAssignGroupingValues, dcoAssignMasterDetailKeys, dcoSaveExpanding]
                  DataController.Summary.FooterSummaryItems = <
                    item
                      Format = '#.##'
                      Kind = skSum
                    end
                    item
                      Format = '##,##.00 '#8364
                      Kind = skSum
                    end>
                  OptionsBehavior.AlwaysShowEditor = True
                  OptionsBehavior.GoToNextCellOnEnter = True
                  OptionsBehavior.IncSearch = True
                  OptionsCustomize.ColumnHiding = True
                  OptionsData.Appending = True
                  OptionsView.Footer = True
                  OptionsView.GroupByBox = False
                  OptionsView.Indicator = True
                  object tvSkusCODIGO_UNIDAD_SKU: TcxGridDBColumn
                    Caption = 'C'#243'digo SKU'
                    DataBinding.FieldName = 'CODIGO_UNIDAD_SKU'
                    Width = 328
                  end
                  object tvSkusCODIGO_ARTICULO_SKU: TcxGridDBColumn
                    DataBinding.FieldName = 'CODIGO_ART_SKU'
                    Visible = False
                  end
                  object tvSkusESACTIVO_SKU: TcxGridDBColumn
                    Caption = 'Activo'
                    DataBinding.FieldName = 'ESACTIVO_SKU'
                    PropertiesClassName = 'TcxCheckBoxProperties'
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    Width = 80
                  end
                  object tvSkusINSTANTEMODIF: TcxGridDBColumn
                    DataBinding.FieldName = 'INSTANTE_MODIF'
                    Visible = False
                  end
                  object tvSkusINSTANTEALTA: TcxGridDBColumn
                    DataBinding.FieldName = 'INSTANTE_ALTA'
                    Visible = False
                  end
                  object tvSkusUSUARIOALTA: TcxGridDBColumn
                    DataBinding.FieldName = 'USUARIO_ALTA'
                    Visible = False
                  end
                  object tvSkusUSUARIOMODIF: TcxGridDBColumn
                    DataBinding.FieldName = 'USUARIO_MODIF'
                    Visible = False
                  end
                  object tvSkusCODIGO_BARRAS_CB: TcxGridDBColumn
                    Caption = 'C'#243'digo de Barras'
                    DataBinding.FieldName = 'CODIGO_BARRAS_CB'
                    Width = 194
                  end
                  object tvSkusTIPO_CODIGO_CB: TcxGridDBColumn
                    Caption = 'Tipo'
                    DataBinding.FieldName = 'TIPO_CODIGO_CB'
                    Width = 100
                  end
                  object tvSkusESPRINCIPAL_CB: TcxGridDBColumn
                    Caption = 'Etiqueta'
                    DataBinding.FieldName = 'ESPRINCIPAL_CB'
                    PropertiesClassName = 'TcxCheckBoxProperties'
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    Width = 87
                  end
                  object tvSkusID_CB: TcxGridDBColumn
                    DataBinding.FieldName = 'ID_CB'
                    Visible = False
                  end
                  object tvSkusSTOCK_TOTAL: TcxGridDBColumn
                    Caption = 'Stock Total'
                    DataBinding.FieldName = 'STOCK_TOTAL'
                    HeaderAlignmentHorz = taRightJustify
                    Width = 134
                  end
                end
                object cxgrdlvlSkus: TcxGridLevel
                  GridView = tvSkus
                end
              end
            end
            object tsTarifas: TcxTabSheet
              Caption = '&5_Tarifas'
              ImageIndex = 1
              ExplicitLeft = 0
              ExplicitTop = 0
              ExplicitWidth = 0
              ExplicitHeight = 0
              object cxgrdTarifas: TcxGrid
                Left = 0
                Top = 0
                Width = 928
                Height = 423
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Align = alClient
                TabOrder = 0
                object tvTarifas: TcxGridDBTableView
                  OnDblClick = cxGrdDBTabPrinDblClick
                  OnKeyDown = tvTarifasKeyDown
                  Navigator.Buttons.ConfirmDelete = True
                  Navigator.Buttons.First.Hint = 'Va al primer Registro'
                  Navigator.Buttons.First.Visible = False
                  Navigator.Buttons.PriorPage.Hint = 'Va a la p'#225'gina anterior'
                  Navigator.Buttons.PriorPage.Visible = False
                  Navigator.Buttons.Prior.Hint = 'Va al Registro Anterior'
                  Navigator.Buttons.Prior.Visible = False
                  Navigator.Buttons.Next.Hint = 'Va al siguiente Registro'
                  Navigator.Buttons.Next.Visible = False
                  Navigator.Buttons.NextPage.Hint = 'Va a la p'#225'gina siguiente'
                  Navigator.Buttons.NextPage.Visible = False
                  Navigator.Buttons.Last.Hint = 'Va al '#250'ltimo registro'
                  Navigator.Buttons.Last.Visible = False
                  Navigator.Buttons.Insert.Hint = 'Inserta un nuevo Registro'
                  Navigator.Buttons.Insert.Visible = True
                  Navigator.Buttons.Delete.Hint = 'Borra el registro Activo'
                  Navigator.Buttons.Delete.Visible = True
                  Navigator.Buttons.Edit.Enabled = False
                  Navigator.Buttons.Edit.Hint = 'Edita registro Actual'
                  Navigator.Buttons.Edit.Visible = False
                  Navigator.Buttons.Post.Hint = 'Guarda Datos introducidos'
                  Navigator.Buttons.Post.Visible = True
                  Navigator.Buttons.Cancel.Hint = 'Cancela la edici'#243'n actual'
                  Navigator.Buttons.Cancel.Visible = True
                  Navigator.Buttons.Refresh.Hint = 'Refresca Datos Activos'
                  Navigator.Buttons.SaveBookmark.Enabled = False
                  Navigator.Buttons.SaveBookmark.Hint = 'Marca Registro Actual'
                  Navigator.Buttons.SaveBookmark.Visible = False
                  Navigator.Buttons.GotoBookmark.Enabled = False
                  Navigator.Buttons.GotoBookmark.Hint = 'Va al registro Marcado'
                  Navigator.Buttons.GotoBookmark.Visible = False
                  Navigator.Buttons.Filter.Hint = 'Filtro personalizado'
                  Navigator.Visible = True
                  DataController.DataSource = dmArticulos.dsTarifasArticulos
                  DataController.Options = [dcoCaseInsensitive, dcoAssignGroupingValues, dcoAssignMasterDetailKeys, dcoSaveExpanding]
                  OptionsBehavior.AlwaysShowEditor = True
                  OptionsBehavior.FocusCellOnTab = True
                  OptionsBehavior.GoToNextCellOnEnter = True
                  OptionsBehavior.IncSearch = True
                  OptionsBehavior.FocusCellOnCycle = True
                  OptionsCustomize.ColumnHiding = True
                  OptionsData.Inserting = False
                  OptionsView.GroupByBox = False
                  OptionsView.Indicator = True
                  OnCellDblClick = tvTarifasCellDblClick
                  object cxgrdbclmnTarifasACTIVO_TARIFA: TcxGridDBColumn
                    Caption = 'Activo'
                    DataBinding.FieldName = 'ESACTIVO_ARTTAR'
                    PropertiesClassName = 'TcxCheckBoxProperties'
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    HeaderAlignmentHorz = taCenter
                    Width = 60
                  end
                  object cxgrdbclmnTarifasNOMBRE_TARIFA: TcxGridDBColumn
                    Caption = 'Tarifa'
                    DataBinding.FieldName = 'NOMBRE_TAR_TAR'
                    PropertiesClassName = 'TcxTextEditProperties'
                    Properties.ReadOnly = True
                    Width = 130
                  end
                  object cxgrdbclmnTarifasCODIGO_TARIFA: TcxGridDBColumn
                    Caption = 'C'#243'digo'
                    DataBinding.FieldName = 'CODIGO_TAR_ARTTAR'
                    PropertiesClassName = 'TcxTextEditProperties'
                    Properties.ReadOnly = True
                    Width = 95
                  end
                  object tvTarifasCODIGO_UNIDAD_TARIFA: TcxGridDBColumn
                    Caption = 'Sku'
                    DataBinding.FieldName = 'CODIGO_UNIDAD_ARTTAR'
                    Visible = False
                    VisibleForCustomization = False
                    Width = 140
                  end
                  object dbcTarifasESIMP_INCL_TARIFA: TcxGridDBColumn
                    Caption = 'Imp. Incl.'
                    DataBinding.FieldName = 'ESIMP_INCL_TAR'
                    PropertiesClassName = 'TcxCheckBoxProperties'
                    Properties.ReadOnly = True
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    HeaderAlignmentHorz = taCenter
                    Width = 72
                  end
                  object cxgrdbclmnTarifasPRECIO_ULT_COMPRA: TcxGridDBColumn
                    Caption = 'Precio de coste'
                    DataBinding.FieldName = 'PRECIO_COSTE_ARTTAR'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    HeaderAlignmentHorz = taRightJustify
                    OnGetDisplayText = MostrarCosteTarifa
                    Width = 110
                  end
                  object cxgrdbclmnTarifasFECHA_VALIDEZ: TcxGridDBColumn
                    Caption = 'Fecha últ. compra'
                    DataBinding.FieldName = 'FECHA_ULT_COMPRA_ARTTAR'
                    PropertiesClassName = 'TcxDateEditProperties'
                    OnGetDisplayText = MostrarFechaCompraTarifa
                    Width = 100
                  end
                  object cxgrdbclmnTarifasCODIGO_PROVEEDOR: TcxGridDBColumn
                    Caption = 'Código proveedor'
                    DataBinding.FieldName = 'CODIGO_PRV_ARTTAR'
                    PropertiesClassName = 'TcxTextEditProperties'
                    OnGetDisplayText = MostrarProveedorCompraTarifa
                    Width = 120
                  end
                  object dbcTarifasMARGEN: TcxGridDBColumn
                    Caption = 'Margen'
                    DataBinding.FieldName = 'CODIGO_UNICO_ARTTAR'
                    PropertiesClassName = 'TcxTextEditProperties'
                    Properties.Alignment.Horz = taRightJustify
                    Properties.ReadOnly = True
                    OnGetDisplayText = dbcTarifasMARGENGetDisplayText
                    HeaderAlignmentHorz = taRightJustify
                    Options.Editing = False
                    Width = 85
                  end
                  object dbcTarifasPRECIOSALIDA: TcxGridDBColumn
                    Caption = 'Precio Salida'
                    DataBinding.FieldName = 'PRECIO_SALIDA_ARTTAR'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.OnEditValueChanged = dbcTarifasPRECIOSALIDAPropertiesEditValueChanged
                    HeaderAlignmentHorz = taRightJustify
                    Width = 95
                  end
                  object dbcTarifasPORCEN_DTO_TARIFA: TcxGridDBColumn
                    Caption = '% Dto.'
                    DataBinding.FieldName = 'PORCENTAJE_DTO_ARTTAR'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = '0.## %'
                    Properties.EditFormat = '0.######'
                    Properties.OnEditValueChanged = dbcTarifasPORCEN_DTO_TARIFAPropertiesEditValueChanged
                    HeaderAlignmentHorz = taRightJustify
                    Width = 70
                  end
                  object dbcTarifasPRECIO_DTO_TARIFA: TcxGridDBColumn
                    Caption = 'Importe Dto.'
                    DataBinding.FieldName = 'PRECIO_DTO_ARTTAR'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.OnEditValueChanged = dbcTarifasPRECIO_DTO_TARIFAPropertiesEditValueChanged
                    HeaderAlignmentHorz = taRightJustify
                    Width = 90
                  end
                  object dbcTarifasPRECIOFINAL: TcxGridDBColumn
                    Caption = 'Precio Final'
                    DataBinding.FieldName = 'PRECIO_FINAL_ARTTAR'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.OnEditValueChanged = dbcTarifasPRECIOFINALPropertiesEditValueChanged
                    HeaderAlignmentHorz = taRightJustify
                    Width = 90
                  end
                  object cxgrdbclmnTarifasFECHA_DESDE_TARIFA: TcxGridDBColumn
                    Caption = 'Desde'
                    DataBinding.FieldName = 'FECHA_DESDE_ARTTAR'
                    Width = 90
                  end
                  object cxgrdbclmnTarifasFECHA_HASTA_TARIFA: TcxGridDBColumn
                    Caption = 'Hasta'
                    DataBinding.FieldName = 'FECHA_HASTA_ARTTAR'
                    Width = 90
                  end
                  object cxgrdbclmnTarifasRAZONSOCIAL_PROVEEDOR: TcxGridDBColumn
                    Caption = 'Nombre Proveedor'
                    DataBinding.FieldName = 'RAZON_SOCIAL_PRV'
                    PropertiesClassName = 'TcxTextEditProperties'
                    Properties.ReadOnly = True
                    Visible = False
                    Width = 200
                  end
                  object cxgrdbclmnTarifasINSTANTEALTA: TcxGridDBColumn
                    Caption = 'Fecha Alta'
                    DataBinding.FieldName = 'INSTANTE_ALTA'
                    Visible = False
                    Width = 130
                  end
                  object cxgrdbclmnTarifasINSTANTEMODIF: TcxGridDBColumn
                    Caption = 'Fecha Modif.'
                    DataBinding.FieldName = 'INSTANTE_MODIF'
                    Visible = False
                    Width = 130
                  end
                  object cxgrdbclmnTarifasUSUARIOALTA: TcxGridDBColumn
                    Caption = 'Usuario Alta'
                    DataBinding.FieldName = 'USUARIO_ALTA'
                    Visible = False
                    Width = 110
                  end
                  object cxgrdbclmnTarifasUSUARIOMODIF: TcxGridDBColumn
                    Caption = 'Usuario Modif.'
                    DataBinding.FieldName = 'USUARIO_MODIF'
                    Visible = False
                    Width = 110
                  end
                  object cxgrdbclmnTarifasCODIGO_ARTICULO_TARIFA: TcxGridDBColumn
                    Caption = 'C'#243'digo Art'#237'culo'
                    DataBinding.FieldName = 'CODIGO_ART_ARTTAR'
                    Visible = False
                    VisibleForCustomization = False
                  end
                  object cxgrdbclmnTarifasDESCRIPCION_ARTICULO: TcxGridDBColumn
                    Caption = 'Descripci'#243'n'
                    DataBinding.FieldName = 'DESCRIPCION_ART'
                    Visible = False
                    VisibleForCustomization = False
                  end
                  object cxgrdbclmnTarifasTIPO_CANTIDAD_ARTICULO: TcxGridDBColumn
                    Caption = 'Tipo Cantidad'
                    DataBinding.FieldName = 'TIPO_CANTIDAD_ART'
                    Visible = False
                    VisibleForCustomization = False
                  end
                  object cxgrdbclmnTarifasTIPO_IVA_ARTICULO: TcxGridDBColumn
                    Caption = 'Tipo IVA'
                    DataBinding.FieldName = 'TIPO_IVA_ARTICULO'
                    Visible = False
                    VisibleForCustomization = False
                  end
                  object cxgrdbclmnTarifasCODIGO_FAMILIA_ARTICULO: TcxGridDBColumn
                    Caption = 'Familia'
                    DataBinding.FieldName = 'CODIGO_FAM_ART'
                    PropertiesClassName = 'TcxTextEditProperties'
                    Properties.ReadOnly = True
                    Visible = False
                    VisibleForCustomization = False
                    Width = 252
                  end
                  object cxgrdbclmnTarifasDESCRIPCION_FAMILIA: TcxGridDBColumn
                    Caption = 'Descripci'#243'n Familia'
                    DataBinding.FieldName = 'DESCRIPCION_FAM'
                    PropertiesClassName = 'TcxTextEditProperties'
                    Properties.ReadOnly = True
                    Visible = False
                    VisibleForCustomization = False
                    Width = 339
                  end
                  object tvTarifasESVARIACION_ARTICULO: TcxGridDBColumn
                    Caption = 'Variaci'#243'n'
                    DataBinding.FieldName = 'ESVARIACION_ART'
                    Visible = False
                    VisibleForCustomization = False
                  end
                  object tvTarifasNUM_ATRIBUTOS_REQ: TcxGridDBColumn
                    Caption = 'N'#186' Atributos'
                    DataBinding.FieldName = 'NUM_ATRIBUTOS_REQ'
                    Visible = False
                    VisibleForCustomization = False
                  end
                end
                object cxgrdlvlTarifas: TcxGridLevel
                  GridView = tvTarifas
                end
              end
              object pnlFacturaOpts2: TPanel
                Left = 928
                Top = 0
                Width = 133
                Height = 423
                Align = alRight
                BevelOuter = bvNone
                TabOrder = 1
                object btnIraTarifa: TcxButton
                  Left = 3
                  Top = 16
                  Width = 124
                  Height = 34
                  Caption = 'Ir a &Tarifa'
                  TabOrder = 0
                  OnClick = btnIraTarifaClick
                end
                object btnExportarTarifa: TcxButton
                  Left = 4
                  Top = 113
                  Width = 123
                  Height = 34
                  Caption = '&Exp Excel'
                  TabOrder = 1
                  OnClick = btnExportarTarifaClick
                end
                object btnAddSKU: TcxButton
                  Left = 4
                  Top = 65
                  Width = 123
                  Height = 34
                  Caption = 'A&'#241'adir precio'
                  TabOrder = 2
                  OnClick = btnAddSKUClick
                end
              end
            end
            object tsProveedores: TcxTabSheet
              Caption = '&6_Proveedores'
              ImageIndex = 2
              ExplicitLeft = 0
              ExplicitTop = 0
              ExplicitWidth = 0
              ExplicitHeight = 0
              object cxgrdProveedores: TcxGrid
                Left = 0
                Top = 0
                Width = 921
                Height = 423
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Align = alClient
                TabOrder = 0
                object tvProveedores: TcxGridDBTableView
                  OnDblClick = cxGrdDBTabPrinDblClick
                  Navigator.Buttons.ConfirmDelete = True
                  Navigator.Buttons.First.Hint = 'Va al primer Registro'
                  Navigator.Buttons.First.Visible = False
                  Navigator.Buttons.PriorPage.Hint = 'Va a la p'#225'gina anterior'
                  Navigator.Buttons.PriorPage.Visible = False
                  Navigator.Buttons.Prior.Hint = 'Va al Registro Anterior'
                  Navigator.Buttons.Prior.Visible = False
                  Navigator.Buttons.Next.Hint = 'Va al siguiente Registro'
                  Navigator.Buttons.Next.Visible = False
                  Navigator.Buttons.NextPage.Hint = 'Va a la p'#225'gina siguiente'
                  Navigator.Buttons.NextPage.Visible = False
                  Navigator.Buttons.Last.Hint = 'Va al '#250'ltimo registro'
                  Navigator.Buttons.Last.Visible = False
                  Navigator.Buttons.Insert.Hint = 'Inserta un nuevo Registro'
                  Navigator.Buttons.Insert.Visible = True
                  Navigator.Buttons.Delete.Hint = 'Borra el registro Activo'
                  Navigator.Buttons.Delete.Visible = True
                  Navigator.Buttons.Edit.Enabled = False
                  Navigator.Buttons.Edit.Hint = 'Edita registro Actual'
                  Navigator.Buttons.Edit.Visible = False
                  Navigator.Buttons.Post.Hint = 'Guarda Datos introducidos'
                  Navigator.Buttons.Post.Visible = True
                  Navigator.Buttons.Cancel.Hint = 'Cancela la edici'#243'n actual'
                  Navigator.Buttons.Cancel.Visible = True
                  Navigator.Buttons.Refresh.Hint = 'Refresca Datos Activos'
                  Navigator.Buttons.SaveBookmark.Enabled = False
                  Navigator.Buttons.SaveBookmark.Hint = 'Marca Registro Actual'
                  Navigator.Buttons.SaveBookmark.Visible = False
                  Navigator.Buttons.GotoBookmark.Enabled = False
                  Navigator.Buttons.GotoBookmark.Hint = 'Va al registro Marcado'
                  Navigator.Buttons.GotoBookmark.Visible = False
                  Navigator.Buttons.Filter.Hint = 'Filtro personalizado'
                  Navigator.Visible = True
                  DataController.DataSource = dmArticulos.dsProveedoresArticulos
                  DataController.Options = [dcoCaseInsensitive, dcoAssignGroupingValues, dcoAssignMasterDetailKeys, dcoSaveExpanding]
                  OptionsBehavior.AlwaysShowEditor = True
                  OptionsBehavior.GoToNextCellOnEnter = True
                  OptionsBehavior.IncSearch = True
                  OptionsCustomize.ColumnHiding = True
                  OptionsData.CancelOnExit = False
                  OptionsData.DeletingConfirmation = False
                  OptionsData.Inserting = False
                  OptionsView.GroupByBox = False
                  OptionsView.Indicator = True
                  object cxgrdbclmnProveedoresESPROVEEDORPRINCIPAL: TcxGridDBColumn
                    Caption = 'Principal'
                    DataBinding.FieldName = 'ESPROVEEDORPRINCIPAL'
                    PropertiesClassName = 'TcxCheckBoxProperties'
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    Width = 89
                  end
                  object tvProveedoresREF_PROVEEDOR: TcxGridDBColumn
                    Caption = 'Modelo Proveedor'
                    DataBinding.FieldName = 'REF_PROVEEDOR'
                    Width = 181
                  end
                  object cxgrdbclmnProveedoresCODIGO_PROVEEDOR: TcxGridDBColumn
                    Caption = 'C'#243'digo Proveedor'
                    DataBinding.FieldName = 'CODIGO_PRV_PRV'
                    PropertiesClassName = 'TcxButtonEditProperties'
                    Properties.Buttons = <
                      item
                        Default = True
                        Kind = bkEllipsis
                      end>
                    Properties.OnButtonClick = cxgrdbclmnProveedoresCODIGO_PROVEEDORPropertiesButtonClick
                    Width = 189
                  end
                  object cxgrdbclmnProveedoresRAZONSOCIAL_PROVEEDOR: TcxGridDBColumn
                    Caption = 'Raz'#243'n Social Proveedor'
                    DataBinding.FieldName = 'RAZON_SOCIAL_PRV'
                    PropertiesClassName = 'TcxTextEditProperties'
                    Properties.ReadOnly = True
                    Width = 221
                  end
                  object cxgrdbclmnProveedoresCODIGO_ARTICULO: TcxGridDBColumn
                    DataBinding.FieldName = 'CODIGO_ART_ART'
                    Visible = False
                    VisibleForCustomization = False
                  end
                  object cxgrdbclmnProveedoresINSTANTEMODIF: TcxGridDBColumn
                    DataBinding.FieldName = 'INSTANTE_MODIF'
                    Visible = False
                    VisibleForCustomization = False
                  end
                  object cxgrdbclmnProveedoresINSTANTEALTA: TcxGridDBColumn
                    DataBinding.FieldName = 'INSTANTE_ALTA'
                    Visible = False
                    VisibleForCustomization = False
                  end
                  object cxgrdbclmnProveedoresUSUARIOALTA: TcxGridDBColumn
                    DataBinding.FieldName = 'USUARIO_ALTA'
                    Visible = False
                    VisibleForCustomization = False
                  end
                  object cxgrdbclmnProveedoresUSUARIOMODIF: TcxGridDBColumn
                    DataBinding.FieldName = 'USUARIO_MODIF'
                    Visible = False
                    VisibleForCustomization = False
                  end
                end
                object cxgrdlvlProveedores: TcxGridLevel
                  GridView = tvProveedores
                end
              end
              object grpComprasTarifas: TcxGroupBox
                Left = 0
                Top = 213
                Align = alBottom
                Caption = 'Último coste por proveedor y SKU (informativo)'
                TabOrder = 2
                Height = 210
                Width = 1061
                object cxgrdComprasTarifas: TcxGrid
                  Left = 3
                  Top = 18
                  Width = 1055
                  Height = 182
                  Align = alClient
                  TabOrder = 0
                  object tvComprasTarifas: TcxGridDBTableView
                    DataController.KeyFieldNames = 'CODIGO_PRV_ARTTAR;CODIGO_UNIDAD_ARTTAR'
                    OptionsData.Deleting = False
                    OptionsData.Editing = False
                    OptionsData.Inserting = False
                    OptionsView.ColumnAutoWidth = True
                    OptionsView.GroupByBox = False
                    OptionsView.Indicator = True
                    object colCompraProveedor: TcxGridDBColumn
                      Caption = 'Código proveedor'
                      DataBinding.FieldName = 'CODIGO_PRV_ARTTAR'
                      Width = 115
                    end
                    object colCompraNombreProveedor: TcxGridDBColumn
                      Caption = 'Proveedor'
                      DataBinding.FieldName = 'RAZON_SOCIAL_PRV'
                      Width = 230
                    end
                    object colCompraSku: TcxGridDBColumn
                      Caption = 'SKU'
                      DataBinding.FieldName = 'CODIGO_UNIDAD_ARTTAR'
                      Width = 225
                    end
                    object colCompraCoste: TcxGridDBColumn
                      Caption = 'Precio de coste'
                      DataBinding.FieldName = 'PRECIO_COSTE_ARTTAR'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 145
                    end
                    object colCompraFecha: TcxGridDBColumn
                      Caption = 'Fecha últ. compra'
                      DataBinding.FieldName = 'FECHA_ULT_COMPRA_ARTTAR'
                      PropertiesClassName = 'TcxDateEditProperties'
                      Width = 140
                    end
                  end
                  object lvlComprasTarifas: TcxGridLevel
                    GridView = tvComprasTarifas
                  end
                end
              end
              object pnlFacturaOpts1: TPanel
                Left = 921
                Top = 0
                Width = 140
                Height = 423
                Align = alRight
                TabOrder = 1
                object btnIraProveedor: TcxButton
                  Left = 5
                  Top = 61
                  Width = 130
                  Height = 34
                  Caption = '&Ir a Proveedor'
                  TabOrder = 1
                  OnClick = btnIraProveedorClick
                end
                object btnExportarProveedor: TcxButton
                  Left = 5
                  Top = 101
                  Width = 116
                  Height = 34
                  Caption = '&Exp Excel'
                  TabOrder = 2
                  OnClick = btnExportarProveedorClick
                end
                object btnAddProveedor: TcxButton
                  Left = 5
                  Top = 21
                  Width = 116
                  Height = 34
                  Caption = '&A'#241'adir'
                  TabOrder = 0
                  OnClick = btnAddProveedorClick
                end
              end
            end
            object tsLineasFactura: TcxTabSheet
              Caption = '&7_Lineas de Venta - '
              ImageIndex = 3
              ExplicitLeft = 0
              ExplicitWidth = 0
              object cxgrdLinFac: TcxGrid
                Left = 0
                Top = 0
                Width = 948
                Height = 423
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Align = alClient
                TabOrder = 0
                ExplicitHeight = 425
                object tvLinFac: TcxGridDBTableView
                  OnDblClick = cxGrdDBTabPrinDblClick
                  Navigator.Buttons.ConfirmDelete = True
                  Navigator.Buttons.First.Hint = 'Va al primer Registro'
                  Navigator.Buttons.First.Visible = False
                  Navigator.Buttons.PriorPage.Hint = 'Va a la p'#225'gina anterior'
                  Navigator.Buttons.PriorPage.Visible = False
                  Navigator.Buttons.Prior.Hint = 'Va al Registro Anterior'
                  Navigator.Buttons.Prior.Visible = False
                  Navigator.Buttons.Next.Hint = 'Va al siguiente Registro'
                  Navigator.Buttons.Next.Visible = False
                  Navigator.Buttons.NextPage.Hint = 'Va a la p'#225'gina siguiente'
                  Navigator.Buttons.NextPage.Visible = False
                  Navigator.Buttons.Last.Hint = 'Va al '#250'ltimo registro'
                  Navigator.Buttons.Last.Visible = False
                  Navigator.Buttons.Insert.Hint = 'Inserta un nuevo Registro'
                  Navigator.Buttons.Insert.Visible = True
                  Navigator.Buttons.Delete.Hint = 'Borra el registro Activo'
                  Navigator.Buttons.Delete.Visible = True
                  Navigator.Buttons.Edit.Enabled = False
                  Navigator.Buttons.Edit.Hint = 'Edita registro Actual'
                  Navigator.Buttons.Edit.Visible = False
                  Navigator.Buttons.Post.Hint = 'Guarda Datos introducidos'
                  Navigator.Buttons.Post.Visible = True
                  Navigator.Buttons.Cancel.Hint = 'Cancela la edici'#243'n actual'
                  Navigator.Buttons.Cancel.Visible = True
                  Navigator.Buttons.Refresh.Hint = 'Refresca Datos Activos'
                  Navigator.Buttons.SaveBookmark.Enabled = False
                  Navigator.Buttons.SaveBookmark.Hint = 'Marca Registro Actual'
                  Navigator.Buttons.SaveBookmark.Visible = False
                  Navigator.Buttons.GotoBookmark.Enabled = False
                  Navigator.Buttons.GotoBookmark.Hint = 'Va al registro Marcado'
                  Navigator.Buttons.GotoBookmark.Visible = False
                  Navigator.Buttons.Filter.Hint = 'Filtro personalizado'
                  Navigator.Visible = True
                  DataController.DataSource = dmArticulos.dsLinFacturasArticulos
                  DataController.Options = [dcoCaseInsensitive, dcoAssignGroupingValues, dcoAssignMasterDetailKeys, dcoSaveExpanding]
                  DataController.Summary.FooterSummaryItems = <
                    item
                      Format = '#.##'
                      Kind = skSum
                      Column = cxgrdbclmnLinFacCANTIDAD_FACTURA_LINEA
                    end
                    item
                      Format = '##,##.00 '#8364
                      Kind = skSum
                      Column = cxgrdbclmnLinFacTOTAL_FACTURA_LINEA
                    end>
                  OptionsBehavior.AlwaysShowEditor = True
                  OptionsBehavior.GoToNextCellOnEnter = True
                  OptionsBehavior.IncSearch = True
                  OptionsCustomize.ColumnHiding = True
                  OptionsData.CancelOnExit = False
                  OptionsData.Deleting = False
                  OptionsData.DeletingConfirmation = False
                  OptionsData.Editing = False
                  OptionsData.Inserting = False
                  OptionsView.Footer = True
                  OptionsView.GroupByBox = False
                  OptionsView.Indicator = True
                  object tvLinFacFECHA_FAC: TcxGridDBColumn
                    Caption = 'Fecha'
                    DataBinding.FieldName = 'FECHA_FAC'
                  end
                  object cxgrdbclmnLinFacSERIE_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Serie'
                    DataBinding.FieldName = 'SERIE_FAC_FACLIN'
                    Width = 141
                  end
                  object cxgrdbclmnLinFacNRO_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Nro'
                    DataBinding.FieldName = 'NUMERO_FAC_FACLIN'
                    Width = 119
                  end
                  object cxgrdbclmnLinFacLINEA_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Nro Linea'
                    DataBinding.FieldName = 'LINEA_FACLIN'
                    Width = 109
                  end
                  object cxgrdbclmnLinFacTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Tipo Cantidad'
                    DataBinding.FieldName = 'TIPO_CANTIDAD_ARTICULO_FACLIN'
                    Width = 134
                  end
                  object cxgrdbclmnLinFacCANTIDAD_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Cantidad'
                    DataBinding.FieldName = 'CANTIDAD_FACLIN'
                    Width = 99
                  end
                  object cxgrdbclmnLinFacDESCRIPCION_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Descripci'#243'n Linea'
                    DataBinding.FieldName = 'DESCRIPCION_ARTICULO_FACLIN'
                    Width = 276
                  end
                  object cxgrdbclmnLinFacNOMBRE_TARIFA: TcxGridDBColumn
                    Caption = 'Tarifa Aplicada'
                    DataBinding.FieldName = 'NOMBRE_TAR_TAR'
                    Width = 143
                  end
                  object cxgrdbclmnLinFacESIMP_INCL_TARIFA_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Precio Imp. Incl.'
                    DataBinding.FieldName = 'ESIMP_INCL_TARIFA_FACLIN'
                    PropertiesClassName = 'TcxCheckBoxProperties'
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    Width = 137
                  end
                  object cxgrdbclmnLinFacPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Precio sin IVA'
                    DataBinding.FieldName = 'PRECIO_VENTA_SIVA_ARTICULO_FACLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Width = 131
                  end
                  object cxgrdbclmnLinFacTIPOIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Tipo IVA'
                    DataBinding.FieldName = 'TIPO_IVA_ARTICULO_FACLIN'
                    Width = 108
                  end
                  object cxgrdbclmnLinFacPORCEN_IVA_FACTURA_LINEA: TcxGridDBColumn
                    Caption = '% IVA'
                    DataBinding.FieldName = 'PORCENTAJE_IVA_FACLIN'
                    PropertiesClassName = 'TcxSpinEditProperties'
                    Properties.DisplayFormat = '0.00 %'
                    Properties.EditFormat = '0.00 %'
                    Properties.MaxValue = 100.000000000000000000
                    Properties.ValueType = vtFloat
                    Width = 80
                  end
                  object cxgrdbclmnLinFacPRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Precio Con IVA'
                    DataBinding.FieldName = 'PRECIO_VENTA_CIVA_ARTICULO_FACLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Width = 152
                  end
                  object cxgrdbclmnLinFacCODIGO_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                    DataBinding.FieldName = 'CODIGO_ART_FACLIN'
                    Visible = False
                    VisibleForCustomization = False
                  end
                  object cxgrdbclmnLinFacCODIGO_FAMILIA_FACTURA_LINEA: TcxGridDBColumn
                    DataBinding.FieldName = 'CODIGO_FAM_FACLIN'
                    Visible = False
                    VisibleForCustomization = False
                  end
                  object cxgrdbclmnLinFacNOMBRE_FAMILIA_FACTURA_LINEA: TcxGridDBColumn
                    DataBinding.FieldName = 'NOMBRE_FAM_FACLIN'
                    Visible = False
                    VisibleForCustomization = False
                  end
                  object cxgrdbclmnLinFacTOTAL_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Total Linea'
                    DataBinding.FieldName = 'TOTAL_FACLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Width = 118
                  end
                  object cxgrdbclmnLinFacFECHA_ENTREGA_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Fecha Entrega'
                    DataBinding.FieldName = 'FECHA_ENTREGA_FACLIN'
                    PropertiesClassName = 'TcxDateEditProperties'
                    Width = 136
                  end
                  object tvLinFacNOMBRE_TIPO_IVA_IVATIP: TcxGridDBColumn
                    DataBinding.FieldName = 'NOMBRE_TIPO_IVA_IVATIP'
                    Visible = False
                  end
                  object tvLinFacCODIGO_TAR_FACLIN: TcxGridDBColumn
                    DataBinding.FieldName = 'CODIGO_TAR_FACLIN'
                    Visible = False
                  end
                  object tvLinFacPRECIO_SALIDA_FACLIN: TcxGridDBColumn
                    DataBinding.FieldName = 'PRECIO_SALIDA_FACLIN'
                    Visible = False
                  end
                  object tvLinFacPORCENTAJE_DTO_FACLIN: TcxGridDBColumn
                    DataBinding.FieldName = 'PORCENTAJE_DTO_FACLIN'
                    Visible = False
                  end
                  object tvLinFacPRECIO_DTO_FACLIN: TcxGridDBColumn
                    DataBinding.FieldName = 'PRECIO_DTO_FACLIN'
                    Visible = False
                  end
                  object tvLinFacTOTAL_FAC_SIVA_FACLIN: TcxGridDBColumn
                    DataBinding.FieldName = 'TOTAL_FAC_SIVA_FACLIN'
                    Visible = False
                  end
                  object tvLinFacCODIGO_CLIENTE_FACTURA_LINEA: TcxGridDBColumn
                    DataBinding.FieldName = 'CODIGO_CLIENTE_FACTURA_LINEA'
                    Visible = False
                  end
                  object tvLinFacCODIGO_EMP_FACLIN: TcxGridDBColumn
                    DataBinding.FieldName = 'CODIGO_EMP_FACLIN'
                    Visible = False
                  end
                  object tvLinFacNUMERO_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'NUMERO_FAC'
                    Visible = False
                  end
                  object tvLinFacSERIE_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'SERIE_FAC'
                    Visible = False
                  end
                  object tvLinFacTOTAL_LIQUIDO_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'TOTAL_LIQUIDO_FAC'
                    Visible = False
                  end
                  object tvLinFacPORCENTAJE_RETENCION_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'PORCENTAJE_RETENCION_FAC'
                    Visible = False
                  end
                  object tvLinFacTOTAL_RETENCION_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'TOTAL_RETENCION_FAC'
                    Visible = False
                  end
                  object tvLinFacTOTAL_IMPUESTOS_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'TOTAL_IMPUESTOS_FAC'
                    Visible = False
                  end
                  object tvLinFacTOTAL_BASES_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'TOTAL_BASES_FAC'
                    Visible = False
                  end
                  object tvLinFacFORMA_PAGO_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'FORMA_PAGO_FAC'
                    Visible = False
                  end
                  object tvLinFacDESCRIPCION_FORMA_PAGO_FP: TcxGridDBColumn
                    DataBinding.FieldName = 'DESCRIPCION_FORMA_PAGO_FP'
                    Visible = False
                  end
                  object tvLinFacCODIGO_EMP_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'CODIGO_EMP_FAC'
                    Visible = False
                  end
                  object tvLinFacRAZON_SOCIAL_EMPRESA_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'RAZON_SOCIAL_EMPRESA_FAC'
                    Visible = False
                  end
                  object tvLinFacNIF_EMPRESA_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'NIF_EMPRESA_FAC'
                    Visible = False
                  end
                  object tvLinFacMOVIL_EMPRESA_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'MOVIL_EMPRESA_FAC'
                    Visible = False
                  end
                  object tvLinFacEMAIL_EMPRESA_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'EMAIL_EMPRESA_FAC'
                    Visible = False
                  end
                  object tvLinFacDIRECCION1_EMPRESA_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'DIRECCION1_EMPRESA_FAC'
                    Visible = False
                  end
                  object tvLinFacDIRECCION2_EMPRESA_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'DIRECCION2_EMPRESA_FAC'
                    Visible = False
                  end
                  object tvLinFacPOBLACION_EMPRESA_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'POBLACION_EMPRESA_FAC'
                    Visible = False
                  end
                  object tvLinFacPROVINCIA_EMPRESA_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'PROVINCIA_EMPRESA_FAC'
                    Visible = False
                  end
                  object tvLinFacNOMBRE_PAI_EMPRESA_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'NOMBRE_PAI_EMPRESA_FAC'
                    Visible = False
                  end
                  object tvLinFacCODIGO_POSTAL_EMPRESA_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'CODIGO_POSTAL_EMPRESA_FAC'
                    Visible = False
                  end
                  object tvLinFacESRETENCIONES_EMPRESA_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'ESRETENCIONES_EMPRESA_FAC'
                    Visible = False
                  end
                  object tvLinFacGRUPO_ZONA_IVA_EMPRESA_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'GRUPO_ZONA_IVA_EMPRESA_FAC'
                    Visible = False
                  end
                  object tvLinFacESREGIMENESPECIALAGRICOLA_EMPRESA_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC'
                    Visible = False
                  end
                  object tvLinFacCODIGO_CLI_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'CODIGO_CLI_FAC'
                    Visible = False
                  end
                  object tvLinFacRAZON_SOCIAL_CLIENTE_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'RAZON_SOCIAL_CLIENTE_FAC'
                    Visible = False
                  end
                  object tvLinFacNIF_CLIENTE_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'NIF_CLIENTE_FAC'
                    Visible = False
                  end
                  object tvLinFacMOVIL_CLIENTE_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'MOVIL_CLIENTE_FAC'
                    Visible = False
                  end
                  object tvLinFacEMAIL_CLIENTE_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'EMAIL_CLIENTE_FAC'
                    Visible = False
                  end
                  object tvLinFacDIRECCION1_CLIENTE_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'DIRECCION1_CLIENTE_FAC'
                    Visible = False
                  end
                  object tvLinFacDIRECCION2_CLIENTE_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'DIRECCION2_CLIENTE_FAC'
                    Visible = False
                  end
                  object tvLinFacPOBLACION_CLIENTE_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'POBLACION_CLIENTE_FAC'
                    Visible = False
                  end
                  object tvLinFacPROVINCIA_CLIENTE_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'PROVINCIA_CLIENTE_FAC'
                    Visible = False
                  end
                  object tvLinFacCODIGO_POSTAL_CLIENTE_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'CODIGO_POSTAL_CLIENTE_FAC'
                    Visible = False
                  end
                  object tvLinFacNOMBRE_PAI_CLIENTE_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'NOMBRE_PAI_CLIENTE_FAC'
                    Visible = False
                  end
                  object tvLinFacESIVA_RECARGO_CLIENTE_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'ESIVA_RECARGO_CLIENTE_FAC'
                    Visible = False
                  end
                  object tvLinFacESIVA_EXENTO_CLIENTE_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'ESIVA_EXENTO_CLIENTE_FAC'
                    Visible = False
                  end
                  object tvLinFacESREGIMENESPECIALAGRICOLA_CLIENTE_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC'
                    Visible = False
                  end
                  object tvLinFacESRETENCIONES_CLIENTE_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'ESRETENCIONES_CLIENTE_FAC'
                    Visible = False
                  end
                  object tvLinFacTARIFA_ARTICULO_CLIENTE_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'TARIFA_ARTICULO_CLIENTE_FAC'
                    Visible = False
                  end
                  object tvLinFacESIMP_INCL_TARIFA_CLIENTE_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'ESIMP_INCL_TARIFA_CLIENTE_FAC'
                    Visible = False
                  end
                  object tvLinFacESINTRACOMUNITARIO_CLIENTE_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'ESINTRACOMUNITARIO_CLIENTE_FAC'
                    Visible = False
                  end
                  object tvLinFacESIRPF_IMP_INCL_ZONA_IVA_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'ESIRPF_IMP_INCL_ZONA_IVA_FAC'
                    Visible = False
                  end
                  object tvLinFacESAPLICA_RE_ZONA_IVA_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'ESAPLICA_RE_ZONA_IVA_FAC'
                    Visible = False
                  end
                  object tvLinFacESIVAAGRICOLA_ZONA_IVA_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'ESIVAAGRICOLA_ZONA_IVA_FAC'
                    Visible = False
                  end
                  object tvLinFacPALABRA_REPORTS_ZONA_IVA_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'PALABRA_REPORTS_ZONA_IVA_FAC'
                    Visible = False
                  end
                  object tvLinFacCODIGO_IVA_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'CODIGO_IVA_FAC'
                    Visible = False
                  end
                  object tvLinFacESVENTA_ACTIVO_FIJO_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'ESVENTA_ACTIVO_FIJO_FAC'
                    Visible = False
                  end
                  object tvLinFacPORCENTAJE_IVAN_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'PORCENTAJE_IVAN_FAC'
                    Visible = False
                  end
                  object tvLinFacTOTAL_IVAN_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'TOTAL_IVAN_FAC'
                    Visible = False
                  end
                  object tvLinFacPORCENTAJE_REN_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'PORCENTAJE_REN_FAC'
                    Visible = False
                  end
                  object tvLinFacTOTAL_REN_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'TOTAL_REN_FAC'
                    Visible = False
                  end
                  object tvLinFacTOTAL_BASEI_IVAN_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'TOTAL_BASEI_IVAN_FAC'
                    Visible = False
                  end
                  object tvLinFacPORCENTAJE_IVAR_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'PORCENTAJE_IVAR_FAC'
                    Visible = False
                  end
                  object tvLinFacTOTAL_IVAR_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'TOTAL_IVAR_FAC'
                    Visible = False
                  end
                  object tvLinFacPORCENTAJE_RER_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'PORCENTAJE_RER_FAC'
                    Visible = False
                  end
                  object tvLinFacTOTAL_RER_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'TOTAL_RER_FAC'
                    Visible = False
                  end
                  object tvLinFacTOTAL_BASEI_IVAR_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'TOTAL_BASEI_IVAR_FAC'
                    Visible = False
                  end
                  object tvLinFacPORCENTAJE_IVAS_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'PORCENTAJE_IVAS_FAC'
                    Visible = False
                  end
                  object tvLinFacTOTAL_IVAS_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'TOTAL_IVAS_FAC'
                    Visible = False
                  end
                  object tvLinFacPORCENTAJE_RES_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'PORCENTAJE_RES_FAC'
                    Visible = False
                  end
                  object tvLinFacTOTAL_RES_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'TOTAL_RES_FAC'
                    Visible = False
                  end
                  object tvLinFacTOTAL_BASEI_IVAS_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'TOTAL_BASEI_IVAS_FAC'
                    Visible = False
                  end
                  object tvLinFacPORCENTAJE_IVAE_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'PORCENTAJE_IVAE_FAC'
                    Visible = False
                  end
                  object tvLinFacTOTAL_IVAE_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'TOTAL_IVAE_FAC'
                    Visible = False
                  end
                  object tvLinFacPORCENTAJE_REE_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'PORCENTAJE_REE_FAC'
                    Visible = False
                  end
                  object tvLinFacTOTAL_REE_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'TOTAL_REE_FAC'
                    Visible = False
                  end
                  object tvLinFacTOTAL_BASEI_IVAE_FAC: TcxGridDBColumn
                    DataBinding.FieldName = 'TOTAL_BASEI_IVAE_FAC'
                    Visible = False
                  end
                end
                object cxgrdlvlLinFac: TcxGridLevel
                  GridView = tvLinFac
                end
              end
              object pnlFacturaOpts: TPanel
                Left = 948
                Top = 0
                Width = 113
                Height = 423
                Align = alRight
                TabOrder = 1
                ExplicitHeight = 425
                object btnIraFactura: TcxButton
                  Left = 6
                  Top = 16
                  Width = 100
                  Height = 34
                  Caption = 'Ir a F&'
                  TabOrder = 0
                  OnClick = btnIraFacturaClick
                end
                object btnIraEmpresa: TcxButton
                  Left = 7
                  Top = 56
                  Width = 99
                  Height = 34
                  Caption = 'Ir a &Empr.'
                  TabOrder = 1
                  OnClick = btnIraEmpresaClick
                end
                object btnExportarLineas: TcxButton
                  Left = 6
                  Top = 138
                  Width = 100
                  Height = 34
                  Caption = '&Exp Excel'
                  TabOrder = 3
                end
                object btnIraCliente: TcxButton
                  Left = 7
                  Top = 96
                  Width = 99
                  Height = 34
                  Caption = 'Ir a C&liente'
                  TabOrder = 2
                  OnClick = btnIraClienteClick
                end
              end
            end
            object cxTabSheet3: TcxTabSheet
              Caption = '&8_Stock'
              ImageIndex = 7
              ExplicitLeft = 0
              ExplicitTop = 0
              ExplicitWidth = 0
              ExplicitHeight = 0
              object cxGrdStock: TcxGrid
                Left = 0
                Top = 0
                Width = 880
                Height = 423
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Align = alClient
                TabOrder = 0
                object tvStock: TcxGridDBTableView
                  OnDblClick = cxGrdDBTabPrinDblClick
                  Navigator.Buttons.ConfirmDelete = True
                  Navigator.Buttons.First.Hint = 'Va al primer Registro'
                  Navigator.Buttons.First.Visible = False
                  Navigator.Buttons.PriorPage.Hint = 'Va a la p'#225'gina anterior'
                  Navigator.Buttons.PriorPage.Visible = False
                  Navigator.Buttons.Prior.Hint = 'Va al Registro Anterior'
                  Navigator.Buttons.Prior.Visible = False
                  Navigator.Buttons.Next.Hint = 'Va al siguiente Registro'
                  Navigator.Buttons.Next.Visible = False
                  Navigator.Buttons.NextPage.Hint = 'Va a la p'#225'gina siguiente'
                  Navigator.Buttons.NextPage.Visible = False
                  Navigator.Buttons.Last.Hint = 'Va al '#250'ltimo registro'
                  Navigator.Buttons.Last.Visible = False
                  Navigator.Buttons.Insert.Hint = 'Inserta un nuevo Registro'
                  Navigator.Buttons.Insert.Visible = True
                  Navigator.Buttons.Delete.Hint = 'Borra el registro Activo'
                  Navigator.Buttons.Delete.Visible = True
                  Navigator.Buttons.Edit.Enabled = False
                  Navigator.Buttons.Edit.Hint = 'Edita registro Actual'
                  Navigator.Buttons.Edit.Visible = False
                  Navigator.Buttons.Post.Hint = 'Guarda Datos introducidos'
                  Navigator.Buttons.Post.Visible = True
                  Navigator.Buttons.Cancel.Hint = 'Cancela la edici'#243'n actual'
                  Navigator.Buttons.Cancel.Visible = True
                  Navigator.Buttons.Refresh.Hint = 'Refresca Datos Activos'
                  Navigator.Buttons.SaveBookmark.Enabled = False
                  Navigator.Buttons.SaveBookmark.Hint = 'Marca Registro Actual'
                  Navigator.Buttons.SaveBookmark.Visible = False
                  Navigator.Buttons.GotoBookmark.Enabled = False
                  Navigator.Buttons.GotoBookmark.Hint = 'Va al registro Marcado'
                  Navigator.Buttons.GotoBookmark.Visible = False
                  Navigator.Buttons.Filter.Hint = 'Filtro personalizado'
                  Navigator.Visible = True
                  OnCustomDrawCell = tvStockCustomDrawCell
                  DataController.DataSource = dmArticulos.dsStockArticulos
                  DataController.Options = [dcoCaseInsensitive, dcoAssignGroupingValues, dcoAssignMasterDetailKeys, dcoSaveExpanding]
                  OptionsBehavior.AlwaysShowEditor = True
                  OptionsBehavior.GoToNextCellOnEnter = True
                  OptionsBehavior.IncSearch = True
                  OptionsCustomize.ColumnHiding = True
                  OptionsData.CancelOnExit = False
                  OptionsData.Deleting = False
                  OptionsData.DeletingConfirmation = False
                  OptionsData.Editing = False
                  OptionsData.Inserting = False
                  OptionsView.GroupByBox = False
                  OptionsView.Indicator = True
                  object tvStockAlmacen: TcxGridDBColumn
                    DataBinding.FieldName = 'Almacen'
                    Width = 239
                  end
                  object tvStockColor: TcxGridDBColumn
                    DataBinding.FieldName = 'Color'
                    Width = 82
                  end
                  object tvStockDBColumn42: TcxGridDBColumn
                    DataBinding.FieldName = '42'
                    Width = 60
                  end
                  object tvStockDBColumn43: TcxGridDBColumn
                    DataBinding.FieldName = '43'
                    Width = 54
                  end
                  object tvStockTotal: TcxGridDBColumn
                    DataBinding.FieldName = 'Total'
                  end
                end
                object cxgrdlvlStock: TcxGridLevel
                  GridView = tvStock
                end
              end
              object pnlBotonesTarifas: TPanel
                Left = 880
                Top = 0
                Width = 181
                Height = 423
                Align = alRight
                TabOrder = 1
                object btnStockExportarExcel: TcxButton
                  Left = 7
                  Top = 61
                  Width = 162
                  Height = 34
                  Caption = '&Exp Excel'
                  TabOrder = 1
                  OnClick = btnStockExportarExcelClick
                end
                object btnReconstruirStock: TcxButton
                  Left = 5
                  Top = 21
                  Width = 164
                  Height = 34
                  Caption = '&Reconstruir Stock'
                  TabOrder = 0
                  OnClick = btnReconstruirStockClick
                end
                object btnImprimirEtiquetas: TcxButton
                  Left = 7
                  Top = 101
                  Width = 162
                  Height = 34
                  Caption = 'Imprimir &Etiquetas'
                  TabOrder = 2
                  OnClick = btnImprimirEtiquetasClick
                end
              end
            end
            object tsMovimientos: TcxTabSheet
              Caption = '&9_Movimientos'
              ImageIndex = 8
              ExplicitLeft = 0
              ExplicitTop = 0
              ExplicitWidth = 0
              ExplicitHeight = 0
              object cxGrdMovimientos: TcxGrid
                Left = 0
                Top = 0
                Width = 940
                Height = 423
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Align = alClient
                TabOrder = 0
                object tvMovimientos: TcxGridDBTableView
                  OnDblClick = cxGrdDBTabPrinDblClick
                  Navigator.Buttons.ConfirmDelete = True
                  Navigator.Buttons.First.Hint = 'Va al primer Registro'
                  Navigator.Buttons.First.Visible = False
                  Navigator.Buttons.PriorPage.Hint = 'Va a la p'#225'gina anterior'
                  Navigator.Buttons.PriorPage.Visible = False
                  Navigator.Buttons.Prior.Hint = 'Va al Registro Anterior'
                  Navigator.Buttons.Prior.Visible = False
                  Navigator.Buttons.Next.Hint = 'Va al siguiente Registro'
                  Navigator.Buttons.Next.Visible = False
                  Navigator.Buttons.NextPage.Hint = 'Va a la p'#225'gina siguiente'
                  Navigator.Buttons.NextPage.Visible = False
                  Navigator.Buttons.Last.Hint = 'Va al '#250'ltimo registro'
                  Navigator.Buttons.Last.Visible = False
                  Navigator.Buttons.Insert.Hint = 'Inserta un nuevo Registro'
                  Navigator.Buttons.Insert.Visible = True
                  Navigator.Buttons.Delete.Hint = 'Borra el registro Activo'
                  Navigator.Buttons.Delete.Visible = True
                  Navigator.Buttons.Edit.Enabled = False
                  Navigator.Buttons.Edit.Hint = 'Edita registro Actual'
                  Navigator.Buttons.Edit.Visible = False
                  Navigator.Buttons.Post.Hint = 'Guarda Datos introducidos'
                  Navigator.Buttons.Post.Visible = True
                  Navigator.Buttons.Cancel.Hint = 'Cancela la edici'#243'n actual'
                  Navigator.Buttons.Cancel.Visible = True
                  Navigator.Buttons.Refresh.Hint = 'Refresca Datos Activos'
                  Navigator.Buttons.SaveBookmark.Enabled = False
                  Navigator.Buttons.SaveBookmark.Hint = 'Marca Registro Actual'
                  Navigator.Buttons.SaveBookmark.Visible = False
                  Navigator.Buttons.GotoBookmark.Enabled = False
                  Navigator.Buttons.GotoBookmark.Hint = 'Va al registro Marcado'
                  Navigator.Buttons.GotoBookmark.Visible = False
                  Navigator.Buttons.Filter.Hint = 'Filtro personalizado'
                  Navigator.Visible = True
                  DataController.DataSource = dmArticulos.dsMovimientosArticulos
                  DataController.Options = [dcoCaseInsensitive, dcoAssignGroupingValues, dcoAssignMasterDetailKeys, dcoSaveExpanding]
                  DataController.Summary.FooterSummaryItems = <
                    item
                      Format = '#.##'
                      Kind = skSum
                    end
                    item
                      Format = '##,##.00 '#8364
                      Kind = skSum
                    end>
                  OptionsBehavior.AlwaysShowEditor = True
                  OptionsBehavior.GoToNextCellOnEnter = True
                  OptionsBehavior.IncSearch = True
                  OptionsCustomize.ColumnHiding = True
                  OptionsData.CancelOnExit = False
                  OptionsData.Deleting = False
                  OptionsData.DeletingConfirmation = False
                  OptionsData.Editing = False
                  OptionsData.Inserting = False
                  OptionsView.Footer = True
                  OptionsView.GroupByBox = False
                  OptionsView.Indicator = True
                  object tvMovimientosCODIGO_UNIDAD_MOV: TcxGridDBColumn
                    Caption = 'Sku'
                    DataBinding.FieldName = 'CODIGO_UNIDAD_MOV'
                    Width = 228
                  end
                  object tvMovimientosCANTIDAD_MOV: TcxGridDBColumn
                    Caption = 'Ctd'
                    DataBinding.FieldName = 'CANTIDAD_MOV'
                    Width = 50
                  end
                  object tvMovimientosCODIGO_EMPRESA_MOV: TcxGridDBColumn
                    Caption = 'C'#243'd Empresa'
                    DataBinding.FieldName = 'CODIGO_EMP_MOV'
                    Width = 121
                  end
                  object tvMovimientosCODIGO_ALMACEN_MOV: TcxGridDBColumn
                    Caption = 'Alm Origen'
                    DataBinding.FieldName = 'CODIGO_ALM_MOV'
                  end
                  object tvMovimientosNUMERO_MOV: TcxGridDBColumn
                    Caption = 'Nro. Mov'
                    DataBinding.FieldName = 'NUMERO_MOV'
                    Width = 92
                  end
                  object tvMovimientosTIPO_DOC_MOV: TcxGridDBColumn
                    Caption = 'Tipo'
                    DataBinding.FieldName = 'TIPO_DOC_MOV'
                    Width = 44
                  end
                  object tvMovimientosTIPO_MOVIMIENTO_MOV: TcxGridDBColumn
                    Caption = 'E/S'
                    DataBinding.FieldName = 'TIPO_MOV'
                    Width = 38
                  end
                  object tvMovimientosSERIE_DOC_MOV: TcxGridDBColumn
                    Caption = 'Serie'
                    DataBinding.FieldName = 'SERIE_DOC_MOV'
                    Width = 54
                  end
                  object tvMovimientosNRO_DOC_MOV: TcxGridDBColumn
                    Caption = 'Nro Doc'
                    DataBinding.FieldName = 'NUMERO_DOC_MOV'
                    Width = 83
                  end
                  object tvMovimientosLINEA_MOV: TcxGridDBColumn
                    Caption = 'NroLinea'
                    DataBinding.FieldName = 'LINEA_MOV'
                    Width = 94
                  end
                  object tvMovimientosFECHA_MOV: TcxGridDBColumn
                    Caption = 'Fecha Hora'
                    DataBinding.FieldName = 'FECHA_MOV'
                  end
                  object tvMovimientosCODIGO_ARTICULO_MOV: TcxGridDBColumn
                    Caption = 'C'#243'd Art.'
                    DataBinding.FieldName = 'CODIGO_ART_MOV'
                    Visible = False
                    Width = 114
                  end
                  object tvMovimientosDESCRIPCION_ARTICULO_MOV: TcxGridDBColumn
                    Caption = 'Descripción'
                    DataBinding.FieldName = 'DESCRIPCION_ARTICULO_MOV'
                    Width = 261
                  end
                  object tvMovimientosPRECIO_COSTE_UNITARIO_MOV: TcxGridDBColumn
                    Caption = 'Coste Ud'
                    DataBinding.FieldName = 'PRECIO_COSTE_UNITARIO_MOV'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Width = 82
                  end
                  object tvMovimientosTOTAL_COSTE_MOV: TcxGridDBColumn
                    Caption = 'Total Coste'
                    DataBinding.FieldName = 'TOTAL_COSTE_MOV'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                  end
                  object tvMovimientosPRECIO_MEDIO_MOV: TcxGridDBColumn
                    Caption = 'Precio MP'
                    DataBinding.FieldName = 'PRECIO_MEDIO_MOV'
                  end
                  object tvMovimientosCODIGO_ALMACEN_CONTRA_MOV: TcxGridDBColumn
                    Caption = 'Almac'#233'n Dest'
                    DataBinding.FieldName = 'CODIGO_ALM_CONTRA_MOV'
                  end
                  object tvMovimientosCODIGO_CLIENTE_MOV: TcxGridDBColumn
                    Caption = 'C'#243'digo Cliente'
                    DataBinding.FieldName = 'CODIGO_CLI_MOV'
                    Width = 132
                  end
                  object tvMovimientosCODIGO_PROVEEDOR_MOV: TcxGridDBColumn
                    Caption = 'C'#243'digo Prov'
                    DataBinding.FieldName = 'CODIGO_PRV_MOV'
                    Width = 114
                  end
                  object tvMovimientosESACTIVO_MOV: TcxGridDBColumn
                    Caption = 'Activo'
                    DataBinding.FieldName = 'ESACTIVO_MOV'
                    Width = 100
                  end
                  object tvMovimientosINSTANTEMODIF: TcxGridDBColumn
                    Caption = 'Instante Modif'
                    DataBinding.FieldName = 'INSTANTE_MODIF'
                    Visible = False
                  end
                  object tvMovimientosINSTANTEALTA: TcxGridDBColumn
                    Caption = 'Instante Alta'
                    DataBinding.FieldName = 'INSTANTE_ALTA'
                    Visible = False
                  end
                  object tvMovimientosUSUARIOALTA: TcxGridDBColumn
                    Caption = 'Usuario Alta'
                    DataBinding.FieldName = 'USUARIO_ALTA'
                    Visible = False
                  end
                  object tvMovimientosUSUARIOMODIF: TcxGridDBColumn
                    Caption = 'Usuario Modif'
                    DataBinding.FieldName = 'USUARIO_MODIF'
                    Visible = False
                  end
                  object tvMovimientosTIPO_DOC_REF_MOV: TcxGridDBColumn
                    Caption = 'Tipo Ref.'
                    DataBinding.FieldName = 'TIPO_DOC_REF_MOV'
                    Width = 183
                  end
                  object tvMovimientosSERIE_DOC_REF_MOV: TcxGridDBColumn
                    Caption = 'Serie Ref.'
                    DataBinding.FieldName = 'SERIE_DOC_REF_MOV'
                  end
                  object tvMovimientosNRO_DOC_REF_MOV: TcxGridDBColumn
                    Caption = 'Nro. Ref.'
                    DataBinding.FieldName = 'NUMERO_DOC_REF_MOV'
                  end
                  object tvMovimientosLINEA_REF_MOV: TcxGridDBColumn
                    Caption = 'L'#237'nea Ref.'
                    DataBinding.FieldName = 'LINEA_REF_MOV'
                    Width = 148
                  end
                  object tvMovimientosLOTE_MOV: TcxGridDBColumn
                    Caption = 'Lote'
                    DataBinding.FieldName = 'LOTE_MOV'
                    Width = 96
                  end
                  object tvMovimientosFECHA_CADUCIDAD_MOV: TcxGridDBColumn
                    Caption = 'F. Caducidad'
                    DataBinding.FieldName = 'FECHA_CADUCIDAD_MOV'
                  end
                  object tvMovimientosNOMBRE_ALMACEN_ORIGEN: TcxGridDBColumn
                    Caption = 'Nombre alm. origen'
                    DataBinding.FieldName = 'NOMBRE_ALMACEN_ORIGEN'
                    Width = 241
                  end
                  object tvMovimientosNOMBRE_ALMACEN_DESTINO: TcxGridDBColumn
                    Caption = 'Nombre alm. destino'
                    DataBinding.FieldName = 'NOMBRE_ALMACEN_DESTINO'
                    Width = 250
                  end
                  object tvMovimientosDESCRIPCION_TIPODOCUMENTO: TcxGridDBColumn
                    Caption = 'Tipo de documento'
                    DataBinding.FieldName = 'DESCRIPCION_TIPO_DOCUMENTO_TD'
                    Width = 278
                  end
                  object tvMovimientosRAZONSOCIAL_CLIENTE: TcxGridDBColumn
                    Caption = 'Cliente'
                    DataBinding.FieldName = 'RAZON_SOCIAL_CLI'
                    Width = 223
                  end
                  object tvMovimientosRAZONSOCIAL_PROVEEDOR: TcxGridDBColumn
                    Caption = 'Proveedor'
                    DataBinding.FieldName = 'RAZON_SOCIAL_PRV'
                    Width = 231
                  end
                end
                object cxgrdlvlStockAlt: TcxGridLevel
                  GridView = tvMovimientos
                end
              end
              object pnlBotonesStock: TPanel
                Left = 940
                Top = 0
                Width = 121
                Height = 423
                Align = alRight
                TabOrder = 1
                object btnExportarExcelStock: TcxButton
                  Left = 3
                  Top = 13
                  Width = 116
                  Height = 34
                  Caption = '&Exp Excel'
                  TabOrder = 0
                  OnClick = cxButton11Click
                end
              end
            end
            object tsOtros: TcxTabSheet
              Caption = '&0_Otros'
              ImageIndex = 3
              ExplicitTop = 29
              ExplicitHeight = 423
              object pnl3: TPanel
                Left = 0
                Top = 346
                Width = 1061
                Height = 79
                Align = alBottom
                TabOrder = 3
                ExplicitTop = 344
                object cxdbtxtdtDIRECCION1_CLIENTE: TcxDBTextEdit
                  Left = 17
                  Top = 37
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'USUARIO_ALTA'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 2
                  Width = 136
                end
                object lblUsuarioAlta: TcxLabel
                  Left = 17
                  Top = 9
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Usuario Alta'
                  TabOrder = 0
                  Transparent = True
                end
                object lblInstanteAlta: TcxLabel
                  Left = 163
                  Top = 9
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Instante Alta'
                  TabOrder = 1
                  Transparent = True
                end
                object cxdbtxtdtUSUARIOALTA: TcxDBTextEdit
                  Left = 163
                  Top = 37
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'INSTANTE_ALTA'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 3
                  Width = 192
                end
                object cxdbtxtdtINSTANTEALTA: TcxDBTextEdit
                  Left = 511
                  Top = 37
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'INSTANTE_MODIF'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 7
                  Width = 198
                end
                object lblInstanteModif: TcxLabel
                  Left = 514
                  Top = 9
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Instante Modificaci'#243'n'
                  TabOrder = 5
                  Transparent = True
                end
                object cxdbtxtdtUSUARIOALTA1: TcxDBTextEdit
                  Left = 359
                  Top = 37
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'USUARIO_ALTA'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 4
                  Width = 136
                end
                object lblUsuarioModif: TcxLabel
                  Left = 359
                  Top = 9
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Us '#218'lt. Modif.'
                  TabOrder = 6
                  Transparent = True
                end
              end
              object chkACTIVO_ARTICULO: TcxDBCheckBox
                Left = 48
                Top = 24
                Caption = 'Es Activo fijo --Es Maquinaria o Aperos-- (S'#243'lo REAGP)'
                DataBinding.DataField = 'ESACTIVO_FIJO_ART'
                DataBinding.DataSource = dsTablaG
                Properties.ValueChecked = 'S'
                Properties.ValueUnchecked = 'N'
                TabOrder = 0
                Transparent = True
              end
              object lblTextoLegal11: TcxLabel
                Left = 376
                Top = 110
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Caption = 'Orden en Listados'
                TabOrder = 2
                Transparent = True
              end
              object cxdbspndtORDEN_CLIENTE: TcxDBSpinEdit
                Left = 537
                Top = 106
                DataBinding.DataField = 'ORDEN_ART'
                DataBinding.DataSource = dsTablaG
                TabOrder = 1
                Width = 106
              end
            end
          end
        end
        object splSplitterFicha: TcxSplitter
          Left = 0
          Top = 174
          Width = 1069
          Height = 8
          HotZoneClassName = 'TcxMediaPlayer9Style'
          AlignSplitter = salTop
          Control = pnlButtonFicha
          ExplicitWidth = 8
        end
      end
      inherited tsPerfil: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 29
        ExplicitWidth = 1069
        ExplicitHeight = 638
        inherited pnlPerfilTop: TPanel
          Width = 1069
          ExplicitWidth = 1069
          inherited edtPerfilBusq: TcxTextEdit
            ExplicitHeight = 26
          end
        end
        inherited pnlPerfilDetail: TPanel
          Width = 1069
          Height = 582
          ExplicitWidth = 1069
          ExplicitHeight = 581
          inherited cxgrdPerfil: TcxGrid
            Width = 1069
            Height = 581
            ExplicitWidth = 1069
            ExplicitHeight = 581
          end
        end
      end
    end
    inherited pnlTopPage: TPanel
      Width = 1077
      TabOrder = 0
      ExplicitWidth = 1077
      inherited pnlTopGrid: TPanel
        Width = 1077
        ExplicitWidth = 1077
        inherited edtBusqGlobal: TcxTextEdit
          TabOrder = 4
          ExplicitHeight = 26
        end
        inherited nvNavegador: TcxDBNavigator
          Width = 324
          ExplicitWidth = 324
        end
        inherited rbBBDD: TcxRadioButton
          Top = 3
          Font.Quality = fqClearTypeNatural
          TabOrder = 0
          ExplicitTop = 3
        end
      end
    end
  end
  inherited pButtonRightBar: TPanel
    Left = 1077
    Height = 711
    TabOrder = 1
    ExplicitLeft = 1077
    ExplicitHeight = 711
    inherited pButtonGen: TPanel
      Top = 513
      TabOrder = 2
      ExplicitTop = 513
    end
    inherited pButtonBDStat: TPanel
      inherited pnStateDataSet: TPanel
        TabOrder = 1
      end
      inherited pnlDataSetName: TPanel
        TabOrder = 0
      end
    end
    object btnNuevoArticulo: TcxButton
      Left = 1
      Top = 157
      Width = 138
      Height = 44
      Caption = '&Nuevo Art'#237'culo'
      TabOrder = 1
      OnClick = btnNuevoArticuloClick
    end
  end
  inherited Localizer1: TcxLocalizer
    Left = 680
    Top = 424
  end
  object ActionListArticulos: TActionList [4]
    Left = 528
    Top = 352
    object actFacturas: TAction
      Caption = 'actBorradores'
      ShortCut = 49222
      OnExecute = actFacturasExecute
    end
    object actEmpresas: TAction
      ShortCut = 49221
      OnExecute = actEmpresasExecute
    end
    object actClientes: TAction
      Caption = 'actClientes'
      ShortCut = 16459
      OnExecute = actClientesExecute
    end
    object actProveedores: TAction
      Caption = 'actProveedores'
      ShortCut = 16464
      OnExecute = actProveedoresExecute
    end
    object actTarifas: TAction
      Caption = 'actTarifas'
      ShortCut = 16468
      OnExecute = actTarifasExecute
    end
    object actFamilias: TAction
      Caption = 'actFamilias'
      ShortCut = 16462
      OnExecute = actFamiliasExecute
    end
  end
  inherited dsTablaG: TDataSource
    DataSet = dmArticulos.unqryTablaG
    Left = 676
    Top = 351
  end
  inherited saveDialog: TdxSaveFileDialog
    Left = 688
    Top = 504
  end
  object pmColorSkus: TPopupMenu
    Left = 600
    Top = 424
    object miActivarColor: TMenuItem
      Caption = 'Activar todos los SKU con este valor de fila'
      OnClick = miActivarColorClick
    end
    object miDesactivarColor: TMenuItem
      Caption = 'Desactivar todos los SKU con este valor de fila'
      OnClick = miDesactivarColorClick
    end
  end
end
