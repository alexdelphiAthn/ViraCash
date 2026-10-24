inherited frmMtoGeneradorProcesos: TfrmMtoGeneradorProcesos
  Left = 5
  Top = 4
  Caption = 'Generador de Procesos'
  ClientHeight = 571
  ClientWidth = 999
  StyleElements = [seFont, seClient, seBorder]
  ExplicitWidth = 999
  ExplicitHeight = 571
  TextHeight = 19
  inherited pButtonPage: TPanel
    Width = 859
    Height = 571
    TabOrder = 0
    StyleElements = [seFont, seClient, seBorder]
    ExplicitWidth = 859
    ExplicitHeight = 571
    inherited pcPantalla: TcxPageControl
      Width = 859
      Height = 531
      TabOrder = 1
      ExplicitWidth = 859
      ExplicitHeight = 531
      ClientRectBottom = 529
      ClientRectRight = 857
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 2
        ExplicitTop = 29
        ExplicitWidth = 855
        ExplicitHeight = 500
        inherited cxGrdPrincipal: TcxGrid
          Width = 855
          Height = 500
          ExplicitWidth = 855
          ExplicitHeight = 500
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            object cxgrdbclmnGrdDBTabPrinCODIGO_GENERADORPROCESO: TcxGridDBColumn
              Caption = 'C'#243'digo Proceso'
              DataBinding.FieldName = 'CODIGO_GENERADOR_PROCESO_GP'
            end
            object cxgrdbclmnGrdDBTabPrinNOMBRE_GENERADORPROCESO: TcxGridDBColumn
              Caption = 'Nombre Proceso'
              DataBinding.FieldName = 'NOMBRE_GENERADOR_PROCESO_GP'
              Width = 471
            end
            object cxgrdbclmnGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn
              DataBinding.FieldName = 'INSTANTE_MODIF'
              Visible = False
              VisibleForCustomization = False
            end
            object cxgrdbclmnGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn
              DataBinding.FieldName = 'INSTANTE_ALTA'
              Visible = False
              VisibleForCustomization = False
            end
            object cxgrdbclmnGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn
              DataBinding.FieldName = 'USUARIO_ALTA'
              Visible = False
              VisibleForCustomization = False
            end
            object cxgrdbclmnGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn
              DataBinding.FieldName = 'USUARIO_MODIF'
              Visible = False
              VisibleForCustomization = False
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        ExplicitLeft = 2
        ExplicitTop = 29
        ExplicitWidth = 855
        ExplicitHeight = 500
        object pnlTopFicha: TPanel
          Left = 0
          Top = 0
          Width = 855
          Height = 113
          Align = alTop
          TabOrder = 0
          object cxdbtxtdt1: TcxDBTextEdit
            Left = 104
            Top = 33
            DataBinding.DataField = 'CODIGO'
            DataBinding.DataSource = dsTablaG
            Enabled = False
            TabOrder = 1
            Width = 121
          end
          object cxdbtxtdt2: TcxDBTextEdit
            Left = 104
            Top = 61
            DataBinding.DataField = 'DESCRIPCION'
            DataBinding.DataSource = dsTablaG
            TabOrder = 2
            Width = 241
          end
          object cxdbtxtdt15: TcxDBTextEdit
            Left = 856
            Top = 89
            DataBinding.DataField = 'modificado'
            DataBinding.DataSource = dsTablaG
            TabOrder = 3
            Width = 57
          end
          object pnlInnerHeader: TPanel
            Left = 1
            Top = 1
            Width = 853
            Height = 111
            Align = alClient
            TabOrder = 0
            object txtCODIGO_FAMILIA: TcxDBTextEdit
              Left = 95
              Top = 17
              DataBinding.DataField = 'CODIGO_GENERADOR_PROCESO_GP'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = False
              TabOrder = 0
              Width = 121
            end
            object lblCodigo: TcxLabel
              Left = 21
              Top = 21
              Caption = 'C'#243'digo'
              TabOrder = 1
              Transparent = True
            end
            object lblNombre: TcxLabel
              Left = 16
              Top = 65
              Caption = 'Nombre'
              TabOrder = 2
              Transparent = True
            end
            object txtNOMBRE_FAMILIA: TcxDBTextEdit
              Left = 94
              Top = 62
              DataBinding.DataField = 'NOMBRE_GENERADOR_PROCESO_GP'
              DataBinding.DataSource = dsTablaG
              TabOrder = 3
              Width = 570
            end
          end
        end
        object pnlBodyFicha: TPanel
          Left = 0
          Top = 123
          Width = 855
          Height = 377
          Align = alClient
          TabOrder = 1
          object pcPestana: TcxPageControl
            Left = 1
            Top = 1
            Width = 853
            Height = 375
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsSQL
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 373
            ClientRectLeft = 2
            ClientRectRight = 851
            ClientRectTop = 29
            object tsSQL: TcxTabSheet
              Caption = '&1_C'#243'digo SQL'
              ImageIndex = 0
              OnShow = tsSQLShow
              ExplicitLeft = 0
              ExplicitTop = 0
              ExplicitWidth = 0
              ExplicitHeight = 0
              object pnlInferior: TPanel
                Left = 0
                Top = 259
                Width = 849
                Height = 85
                Align = alBottom
                TabOrder = 0
                object cxmResul: TcxMemo
                  Left = 1
                  Top = 1
                  Align = alClient
                  Properties.ReadOnly = True
                  TabOrder = 0
                  Height = 83
                  Width = 847
                end
              end
              object pnlScriptOuter: TPanel
                Left = 0
                Top = 0
                Width = 849
                Height = 259
                Align = alClient
                TabOrder = 1
                object pnlSidePanel: TPanel
                  Left = 731
                  Top = 1
                  Width = 117
                  Height = 257
                  Align = alRight
                  TabOrder = 0
                  object btnBonito: TButton
                    Left = 6
                    Top = 16
                    Width = 99
                    Height = 41
                    Caption = '&Bonito'
                    TabOrder = 0
                    OnClick = btnBonitoClick
                  end
                end
                object sbVertDerecho: TScrollBar
                  Left = 712
                  Top = 1
                  Width = 19
                  Height = 257
                  Align = alRight
                  Kind = sbVertical
                  Max = 10
                  Min = 1
                  PageSize = 0
                  Position = 1
                  TabOrder = 1
                  TabStop = False
                  StyleName = 'Windows'
                  OnChange = ScrollBar1Change
                end
                object DBSynEdit1: TDBSynEdit
                  Left = 1
                  Top = 1
                  Width = 711
                  Height = 257
                  Cursor = crIBeam
                  DataField = 'PROCESO_GENERADOR_PROCESO_GP'
                  DataSource = dsTablaG
                  Align = alClient
                  Font.Charset = DEFAULT_CHARSET
                  Font.Color = clWindowText
                  Font.Height = -15
                  Font.Name = 'Consolas'
                  Font.Style = []
                  Font.Quality = fqClearTypeNatural
                  ParentColor = False
                  ParentFont = False
                  TabOrder = 2
                  Gutter.Font.Charset = DEFAULT_CHARSET
                  Gutter.Font.Color = clWindowText
                  Gutter.Font.Height = -15
                  Gutter.Font.Name = 'Consolas'
                  Gutter.Font.Style = []
                  Gutter.Font.Quality = fqClearTypeNatural
                  Gutter.ShowLineNumbers = True
                  Gutter.Bands = <
                    item
                      Kind = gbkMarks
                      Width = 13
                    end
                    item
                      Kind = gbkLineNumbers
                    end
                    item
                      Kind = gbkFold
                    end
                    item
                      Kind = gbkTrackChanges
                    end
                    item
                      Kind = gbkMargin
                      Width = 3
                    end>
                  Highlighter = synsqlsyn2
                  ScrollBars = ssNone
                  WantTabs = True
                  OnStatusChange = SynEdit1StatusChange
                end
              end
            end
            object tsMetadatos: TcxTabSheet
              Caption = '&2_Metadatos'
              ImageIndex = 2
              OnShow = tsMetadatosShow
              ExplicitLeft = 0
              ExplicitTop = 0
              ExplicitWidth = 0
              ExplicitHeight = 0
              object splDetalleMeta: TcxSplitter
                Left = 377
                Top = 0
                Width = 10
                Height = 344
                HotZoneClassName = 'TcxMediaPlayer9Style'
                Control = pnlTree
              end
              object pnlTabs: TPanel
                Left = 387
                Top = 0
                Width = 462
                Height = 344
                Align = alClient
                Caption = 'pnlTabs'
                TabOrder = 1
                object pcMetadato: TcxPageControl
                  Left = 1
                  Top = 1
                  Width = 460
                  Height = 342
                  Align = alClient
                  TabOrder = 0
                  Properties.ActivePage = tsEstructura
                  Properties.CustomButtons.Buttons = <>
                  ClientRectBottom = 340
                  ClientRectLeft = 2
                  ClientRectRight = 458
                  ClientRectTop = 29
                  object tsEstructura: TcxTabSheet
                    Caption = '&Estructura Metadato'
                    ImageIndex = 0
                    ExplicitLeft = 0
                    ExplicitTop = 0
                    ExplicitWidth = 0
                    ExplicitHeight = 0
                    object mmoSalida: TMemo
                      Left = 488
                      Top = 344
                      Width = 57
                      Height = 41
                      Lines.Strings = (
                        'mm'
                        'o1')
                      TabOrder = 0
                      Visible = False
                    end
                    object pnlMetadatosBody: TPanel
                      Left = 0
                      Top = 0
                      Width = 456
                      Height = 311
                      Align = alClient
                      BevelOuter = bvNone
                      TabOrder = 1
                      object syndtEstructura: TSynEdit
                        Left = 0
                        Top = 0
                        Width = 437
                        Height = 311
                        Align = alClient
                        ParentColor = True
                        ParentFont = True
                        TabOrder = 0
                        Visible = False
                        CodeFolding.IndentGuidesColor = clBlack
                        CodeFolding.IndentGuides = False
                        UseCodeFolding = False
                        BorderStyle = bsNone
                        Gutter.Font.Charset = DEFAULT_CHARSET
                        Gutter.Font.Color = clWindowText
                        Gutter.Font.Height = -11
                        Gutter.Font.Name = 'Consolas'
                        Gutter.Font.Style = []
                        Gutter.Font.Quality = fqClearTypeNatural
                        Gutter.ShowLineNumbers = True
                        Gutter.Bands = <
                          item
                            Kind = gbkMarks
                            Width = 13
                          end
                          item
                            Kind = gbkLineNumbers
                          end
                          item
                            Kind = gbkFold
                          end
                          item
                            Kind = gbkTrackChanges
                          end
                          item
                            Kind = gbkMargin
                            Width = 3
                          end>
                        Highlighter = synsqlsyn2
                        ScrollBars = ssNone
                        ScrollbarAnnotations = <>
                        OnScroll = syndtEstructuraScroll
                        OnStatusChange = syndtEstructuraStatusChange
                        FontSmoothing = fsmNone
                        RemovedKeystrokes = <
                          item
                            Command = ecTab
                            ShortCut = 9
                          end
                          item
                            Command = ecShiftTab
                            ShortCut = 8201
                          end>
                        AddedKeystrokes = <
                          item
                            Command = ecTab
                            ShortCut = 9
                            ShortCut2 = 9
                          end
                          item
                            Command = ecShiftTab
                            ShortCut = 8201
                            ShortCut2 = 8201
                          end>
                      end
                      object sbVertCentro: TScrollBar
                        Left = 437
                        Top = 0
                        Width = 19
                        Height = 311
                        Align = alRight
                        Kind = sbVertical
                        Max = 10
                        Min = 1
                        PageSize = 0
                        Position = 1
                        TabOrder = 1
                        TabStop = False
                        StyleName = 'Windows'
                        OnChange = ScrollBar2Change
                      end
                    end
                  end
                  object tsContenido: TcxTabSheet
                    Caption = '&Vista Contenido'
                    ImageIndex = 1
                    ExplicitLeft = 0
                    ExplicitTop = 0
                    ExplicitWidth = 0
                    ExplicitHeight = 0
                    object cxgrdMetadatos1: TcxGrid
                      Left = 0
                      Top = 0
                      Width = 339
                      Height = 311
                      Margins.Left = 4
                      Margins.Top = 4
                      Margins.Right = 4
                      Margins.Bottom = 4
                      Align = alClient
                      TabOrder = 0
                      object tvMetadatostvVista: TcxGridDBTableView
                        Navigator.Buttons.ConfirmDelete = True
                        Navigator.Visible = True
                        DataController.DataModeController.SmartRefresh = True
                        DataController.Summary.DefaultGroupSummaryItems = <
                          item
                            Kind = skSum
                          end
                          item
                            Format = '0,00 '#8364';-0,00 '#8364
                            Position = spFooter
                          end>
                        DataController.Summary.FooterSummaryItems = <
                          item
                            Format = '0.00 '#8364';-0.00 '#8364
                            Kind = skSum
                          end
                          item
                            Format = '0.00 '#8364';-0.00 '#8364
                            Kind = skSum
                          end
                          item
                            Format = '0.00 '#8364';-0.00 '#8364
                            Kind = skSum
                          end
                          item
                            Format = '0.00 '#8364';-0.00 '#8364
                            Kind = skSum
                          end>
                        OptionsBehavior.GoToNextCellOnEnter = True
                        OptionsCustomize.ColumnGrouping = False
                        OptionsData.Deleting = False
                        OptionsData.Editing = False
                        OptionsData.Inserting = False
                        OptionsSelection.InvertSelect = False
                        OptionsView.NoDataToDisplayInfoText = '<No hay datos a mostrar>'
                        OptionsView.Footer = True
                        OptionsView.GroupByBox = False
                        OptionsView.GroupFooters = gfAlwaysVisible
                      end
                      object tvVistaDatos: TcxGridDBTableView
                        DataController.DetailKeyFieldNames = 'NUMERO_FAC_FACLIN; SERIE_FAC_FACLIN'
                        DataController.KeyFieldNames = 'LINEA_FACLIN'
                        DataController.MasterKeyFieldNames = 'NUMERO_FAC; SERIE_FAC'
                        OptionsBehavior.ColumnHeaderHints = False
                        OptionsCustomize.ColumnFiltering = False
                        OptionsCustomize.ColumnGrouping = False
                        OptionsCustomize.ColumnMoving = False
                        OptionsCustomize.ColumnsQuickCustomizationShowCommands = False
                        OptionsData.Deleting = False
                        OptionsData.Editing = False
                        OptionsData.Inserting = False
                        OptionsView.GroupByBox = False
                        object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1LINEA_LINEA1: TcxGridDBColumn
                          Caption = 'Nro Linea'
                          DataBinding.FieldName = 'LINEA_FACLIN'
                          Width = 28
                        end
                        object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CODIGO_ARTICULO_LINEA1: TcxGridDBColumn
                          Caption = 'C'#243'digo Art'#237'culo'
                          DataBinding.FieldName = 'CODIGO_ART_FACLIN'
                          Width = 164
                        end
                        object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1DESCRIPCION_ARTICULO_LINEA1: TcxGridDBColumn
                          Caption = 'Descripci'#243'n'
                          DataBinding.FieldName = 'DESCRIPCION_ARTICULO_FACLIN'
                          Width = 162
                        end
                        object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CANTIDAD_LINEA1: TcxGridDBColumn
                          Caption = 'Cantidad'
                          DataBinding.FieldName = 'CANTIDAD_FACLIN'
                          Width = 84
                        end
                        object cxgrdbclmnLineasFacturacionTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA1: TcxGridDBColumn
                          Caption = 'Tipo Cantidad'
                          DataBinding.FieldName = 'TIPO_CANTIDAD_ARTICULO_FACLIN'
                        end
                        object cxgrdbclmnLineasFacturacionPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA1: TcxGridDBColumn
                          Caption = 'Precio SIVA'
                          DataBinding.FieldName = 'PRECIO_VENTA_SIVA_ARTICULO_FACLIN'
                        end
                        object cxgrdbclmnLineasFacturacionPORCEN_IVA_FACTURA_LINEA1: TcxGridDBColumn
                          Caption = 'Porcentaje IVA'
                          DataBinding.FieldName = 'PORCENTAJE_IVA_FACLIN'
                          PropertiesClassName = 'TcxSpinEditProperties'
                          Properties.DisplayFormat = '0.00 %'
                          Properties.EditFormat = '0.00 %'
                          Properties.Increment = 0.100000000000000000
                          Properties.LargeIncrement = 1.000000000000000000
                          Properties.MaxValue = 100.000000000000000000
                        end
                        object cxgrdbclmnLineasFacturacionTIPOIVA_ARTICULO_FACTURA_LINEA1: TcxGridDBColumn
                          Caption = 'Tipo IVA'
                          DataBinding.FieldName = 'TIPO_IVA_ARTICULO_FACLIN'
                        end
                        object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1PRECIOVENTA_ARTICULO_LINEA1: TcxGridDBColumn
                          Caption = 'Precio CIVA'
                          DataBinding.FieldName = 'PRECIO_VENTA_CIVA_ARTICULO_FACLIN'
                          PropertiesClassName = 'TcxCurrencyEditProperties'
                          Width = 84
                        end
                        object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1SUM_TOTAL_LINEA1: TcxGridDBColumn
                          Caption = 'Total'
                          DataBinding.FieldName = 'TOTAL_FACLIN'
                          PropertiesClassName = 'TcxCurrencyEditProperties'
                          Width = 84
                        end
                        object cxgrdbclmnLineasFacturacionFECHA_ENTREGA_FACTURA_LINEA1: TcxGridDBColumn
                          Caption = 'Fecha de Entrega'
                          DataBinding.FieldName = 'FECHA_ENTREGA_FACLIN'
                          PropertiesClassName = 'TcxDateEditProperties'
                        end
                      end
                      object cxgrdlvlMetadatoslv11: TcxGridLevel
                        GridView = tvMetadatostvVista
                      end
                    end
                    object pnlFacturaOpts1: TPanel
                      Left = 339
                      Top = 0
                      Width = 117
                      Height = 311
                      Align = alRight
                      TabOrder = 1
                      object btnExportarExcelMeta: TcxButton
                        Left = 6
                        Top = 8
                        Width = 106
                        Height = 34
                        Caption = 'Exp. E&xcel'
                        TabOrder = 0
                        OnClick = btnExportarExcelMetaClick
                      end
                      object btnEditarMeta: TcxButton
                        Left = 6
                        Top = 48
                        Width = 106
                        Height = 34
                        Caption = 'Editar G&rid'
                        TabOrder = 1
                        OnClick = btnEditarMetaClick
                      end
                    end
                  end
                end
              end
              object pnlTree: TPanel
                Left = 0
                Top = 0
                Width = 377
                Height = 344
                Align = alLeft
                Caption = 'pnlTree'
                TabOrder = 2
                object pnlTreeBotton: TPanel
                  Left = 1
                  Top = 302
                  Width = 375
                  Height = 41
                  Align = alBottom
                  TabOrder = 0
                  object btnRefresh: TcxButton
                    Left = 5
                    Top = 6
                    Width = 188
                    Height = 25
                    Caption = 'Refrescar &MetaDatos'
                    TabOrder = 0
                    OnClick = btnRefreshClick
                  end
                  object lblAyudaSeleccion: TcxLabel
                    Left = 199
                    Top = 8
                    Caption = 'Control+A al editor'
                    TabOrder = 1
                    Transparent = True
                  end
                end
                object tvMetadatos: TTreeView
                  Left = 1
                  Top = 1
                  Width = 375
                  Height = 301
                  Align = alClient
                  HideSelection = False
                  Indent = 19
                  TabOrder = 1
                  OnChange = TreeView1Change
                  OnDblClick = TreeView1DblClick
                end
              end
            end
            object tsVistaDatos: TcxTabSheet
              Caption = '&3_VistaDatos'
              ImageIndex = 3
              ExplicitLeft = 0
              ExplicitTop = 0
              ExplicitWidth = 0
              ExplicitHeight = 0
              object cxVista: TcxGrid
                Left = 0
                Top = 0
                Width = 732
                Height = 344
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Align = alClient
                TabOrder = 0
                object tvVista: TcxGridDBTableView
                  Navigator.Buttons.ConfirmDelete = True
                  Navigator.Visible = True
                  DataController.DataModeController.SmartRefresh = True
                  DataController.DataSource = dmGeneradorProcesos.dsVista
                  DataController.Summary.DefaultGroupSummaryItems = <
                    item
                      Kind = skSum
                    end
                    item
                      Format = '0,00 '#8364';-0,00 '#8364
                      Position = spFooter
                    end>
                  DataController.Summary.FooterSummaryItems = <
                    item
                      Format = '0.00 '#8364';-0.00 '#8364
                      Kind = skSum
                    end
                    item
                      Format = '0.00 '#8364';-0.00 '#8364
                      Kind = skSum
                    end
                    item
                      Format = '0.00 '#8364';-0.00 '#8364
                      Kind = skSum
                    end
                    item
                      Format = '0.00 '#8364';-0.00 '#8364
                      Kind = skSum
                    end>
                  OptionsBehavior.GoToNextCellOnEnter = True
                  OptionsCustomize.ColumnGrouping = False
                  OptionsData.Deleting = False
                  OptionsData.Editing = False
                  OptionsData.Inserting = False
                  OptionsSelection.InvertSelect = False
                  OptionsView.NoDataToDisplayInfoText = '<No hay datos a mostrar>'
                  OptionsView.Footer = True
                  OptionsView.GroupByBox = False
                  OptionsView.GroupFooters = gfAlwaysVisible
                end
                object tvVistaContenido: TcxGridDBTableView
                  DataController.DetailKeyFieldNames = 'NUMERO_FAC_FACLIN; SERIE_FAC_FACLIN'
                  DataController.KeyFieldNames = 'LINEA_FACLIN'
                  DataController.MasterKeyFieldNames = 'NUMERO_FAC; SERIE_FAC'
                  OptionsBehavior.ColumnHeaderHints = False
                  OptionsCustomize.ColumnFiltering = False
                  OptionsCustomize.ColumnGrouping = False
                  OptionsCustomize.ColumnMoving = False
                  OptionsCustomize.ColumnsQuickCustomizationShowCommands = False
                  OptionsData.Deleting = False
                  OptionsData.Editing = False
                  OptionsData.Inserting = False
                  OptionsView.GroupByBox = False
                  object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1LINEA_LINEA11: TcxGridDBColumn
                    Caption = 'Nro Linea'
                    DataBinding.FieldName = 'LINEA_FACLIN'
                    Width = 28
                  end
                  object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CODIGO_ARTICULO_LINEA11: TcxGridDBColumn
                    Caption = 'C'#243'digo Art'#237'culo'
                    DataBinding.FieldName = 'CODIGO_ART_FACLIN'
                    Width = 164
                  end
                  object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1DESCRIPCION_ARTICULO_LINEA11: TcxGridDBColumn
                    Caption = 'Descripci'#243'n'
                    DataBinding.FieldName = 'DESCRIPCION_ARTICULO_FACLIN'
                    Width = 162
                  end
                  object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CANTIDAD_LINEA11: TcxGridDBColumn
                    Caption = 'Cantidad'
                    DataBinding.FieldName = 'CANTIDAD_FACLIN'
                    Width = 84
                  end
                  object cxgrdbclmnLineasFacturacionTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA11: TcxGridDBColumn
                    Caption = 'Tipo Cantidad'
                    DataBinding.FieldName = 'TIPO_CANTIDAD_ARTICULO_FACLIN'
                  end
                  object cxgrdbclmnLineasFacturacionPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA11: TcxGridDBColumn
                    Caption = 'Precio SIVA'
                    DataBinding.FieldName = 'PRECIO_VENTA_SIVA_ARTICULO_FACLIN'
                  end
                  object cxgrdbclmnLineasFacturacionPORCEN_IVA_FACTURA_LINEA11: TcxGridDBColumn
                    Caption = 'Porcentaje IVA'
                    DataBinding.FieldName = 'PORCENTAJE_IVA_FACLIN'
                    PropertiesClassName = 'TcxSpinEditProperties'
                    Properties.DisplayFormat = '0.00 %'
                    Properties.EditFormat = '0.00 %'
                    Properties.Increment = 0.100000000000000000
                    Properties.LargeIncrement = 1.000000000000000000
                    Properties.MaxValue = 100.000000000000000000
                  end
                  object cxgrdbclmnLineasFacturacionTIPOIVA_ARTICULO_FACTURA_LINEA11: TcxGridDBColumn
                    Caption = 'Tipo IVA'
                    DataBinding.FieldName = 'TIPO_IVA_ARTICULO_FACLIN'
                  end
                  object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1PRECIOVENTA_ARTICULO_LINEA11: TcxGridDBColumn
                    Caption = 'Precio CIVA'
                    DataBinding.FieldName = 'PRECIO_VENTA_CIVA_ARTICULO_FACLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Width = 84
                  end
                  object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1SUM_TOTAL_LINEA11: TcxGridDBColumn
                    Caption = 'Total'
                    DataBinding.FieldName = 'TOTAL_FACLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Width = 84
                  end
                  object cxgrdbclmnLineasFacturacionFECHA_ENTREGA_FACTURA_LINEA11: TcxGridDBColumn
                    Caption = 'Fecha de Entrega'
                    DataBinding.FieldName = 'FECHA_ENTREGA_FACLIN'
                    PropertiesClassName = 'TcxDateEditProperties'
                  end
                end
                object lvVista: TcxGridLevel
                  GridView = tvVista
                end
              end
              object pnlFacturaOpts: TPanel
                Left = 724
                Top = 0
                Width = 125
                Height = 344
                Align = alRight
                TabOrder = 1
                object btnExportarExcel: TcxButton
                  Left = 6
                  Top = 8
                  Width = 114
                  Height = 34
                  Caption = 'Exp. E&xcel'
                  TabOrder = 0
                  OnClick = btnExportarExcelClick
                end
                object btnEditar: TcxButton
                  Left = 6
                  Top = 48
                  Width = 114
                  Height = 34
                  Caption = 'Editar G&rid'
                  TabOrder = 1
                  OnClick = btnEditarClick
                end
                object btnCopiarDatos: TcxButton
                  Left = 6
                  Top = 88
                  Width = 114
                  Height = 34
                  Caption = 'Copiar &Datos'
                  TabOrder = 2
                  OnClick = btnCopiarDatosClick
                end
              end
            end
            object tsOtros: TcxTabSheet
              Caption = '&4_Otros'
              ImageIndex = 3
              object pnlBotonera: TPanel
                Left = 0
                Top = 265
                Width = 849
                Height = 79
                Align = alBottom
                TabOrder = 0
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
                object cxlblUsuarioAlta: TcxLabel
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
                object cxlblInstanteAlta: TcxLabel
                  Left = 177
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
                  Left = 177
                  Top = 37
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'INSTANTE_ALTA'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 3
                  Width = 136
                end
                object cxdbtxtdtINSTANTEALTA: TcxDBTextEdit
                  Left = 613
                  Top = 37
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'INSTANTE_MODIF'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 7
                  Width = 219
                end
                object cxlblInstanteModif: TcxLabel
                  Left = 613
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
                  Left = 337
                  Top = 37
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'USUARIO_ALTA'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 4
                  Width = 248
                end
                object cxlblUsuarioModif: TcxLabel
                  Left = 337
                  Top = 9
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Usuario '#218'ltima Modificaci'#243'n'
                  TabOrder = 6
                  Transparent = True
                end
              end
            end
          end
        end
        object splArbolMeta: TcxSplitter
          Left = 0
          Top = 113
          Width = 855
          Height = 10
          HotZoneClassName = 'TcxMediaPlayer9Style'
          AlignSplitter = salTop
          Control = pnlTopFicha
          ExplicitWidth = 10
        end
      end
      inherited tsPerfil: TcxTabSheet
        ExplicitWidth = 855
        ExplicitHeight = 500
        inherited pnlPerfilTop: TPanel
          Width = 855
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 855
          inherited edtPerfilBusq: TcxTextEdit
            ExplicitHeight = 27
          end
        end
        inherited pnlPerfilDetail: TPanel
          Width = 855
          Height = 443
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 855
          ExplicitHeight = 443
          inherited cxgrdPerfil: TcxGrid
            Width = 855
            Height = 443
            ExplicitWidth = 855
            ExplicitHeight = 443
            inherited tvPerfil: TcxGridDBTableView
              object cxgrdbclmnPerfilUSUARIO_GRUPO_PERFILES: TcxGridDBColumn
                DataBinding.FieldName = 'USUARIO_GRUPO_USUPER'
                Width = 167
              end
              object cxgrdbclmnPerfilKEY_PERFILES: TcxGridDBColumn
                DataBinding.FieldName = 'KEY_USUPER'
                Width = 112
              end
              object cxgrdbclmnPerfilSUBKEY_PERFILES: TcxGridDBColumn
                DataBinding.FieldName = 'SUBKEY_USUPER'
                Width = 291
              end
              object cxgrdbclmnPerfilVALUE_PERFILES: TcxGridDBColumn
                DataBinding.FieldName = 'VALUE_USUPER'
                Width = 188
              end
              object cxgrdbclmnPerfilVALUE_TEXT_PERFILES: TcxGridDBColumn
                DataBinding.FieldName = 'VALUE_TEXT_USUPER'
                PropertiesClassName = 'TcxBlobEditProperties'
                Properties.BlobEditKind = bekMemo
              end
              object cxgrdbclmnPerfilTYPE_BLOB_PERFILES: TcxGridDBColumn
                DataBinding.FieldName = 'TYPE_BLOB_USUPER'
              end
              object cxgrdbclmnPerfilVALUE_BLOB_PERFILES: TcxGridDBColumn
                DataBinding.FieldName = 'VALUE_BLOB_USUPER'
              end
              object cxgrdbclmnPerfilINSTANTEMODIF: TcxGridDBColumn
                DataBinding.FieldName = 'INSTANTE_MODIF'
              end
              object cxgrdbclmnPerfilINSTANTEALTA: TcxGridDBColumn
                DataBinding.FieldName = 'INSTANTE_ALTA'
              end
              object cxgrdbclmnPerfilUSUARIOALTA: TcxGridDBColumn
                DataBinding.FieldName = 'USUARIO_ALTA'
                Width = 88
              end
              object cxgrdbclmnPerfilUSUARIOMODIF: TcxGridDBColumn
                DataBinding.FieldName = 'USUARIO_MODIF'
                Width = 96
              end
            end
          end
        end
      end
    end
    inherited pnlTopPage: TPanel
      Width = 859
      TabOrder = 0
      StyleElements = [seFont, seClient, seBorder]
      ExplicitWidth = 859
      inherited pnlTopGrid: TPanel
        Width = 859
        StyleElements = [seFont, seClient, seBorder]
        ExplicitWidth = 859
        inherited edtBusqGlobal: TcxTextEdit
          ExplicitHeight = 27
        end
        inherited nvNavegador: TcxDBNavigator
          Width = 282
          ExplicitWidth = 282
        end
      end
    end
  end
  inherited pButtonRightBar: TPanel
    Left = 859
    Height = 571
    TabOrder = 1
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 859
    ExplicitHeight = 571
    inherited pButtonGen: TPanel
      Top = 373
      StyleElements = [seFont, seClient, seBorder]
      ExplicitTop = 373
    end
    inherited pButtonBDStat: TPanel
      StyleElements = [seFont, seClient, seBorder]
      inherited pnStateDataSet: TPanel
        StyleElements = [seFont, seClient, seBorder]
      end
      inherited pnlDataSetName: TPanel
        StyleElements = [seFont, seClient, seBorder]
      end
    end
    object btnEjecutar: TcxButton
      Left = 1
      Top = 328
      Width = 136
      Height = 49
      Caption = '&Ejecutar (F5)'
      TabOrder = 2
      WordWrap = True
      OnClick = btnEjecutarClick
    end
    object btnAbrirScript: TcxButton
      Left = 1
      Top = 223
      Width = 136
      Height = 49
      Caption = '&Script (F3)'
      TabOrder = 3
      WordWrap = True
      OnClick = btnAbrirScriptClick
    end
  end
  object synsqlsyn2: TSynSQLSyn [4]
    Options.AutoDetectEnabled = False
    Options.AutoDetectLineLimit = 0
    Options.Visible = False
    CommentAttri.Background = clWhite
    CommentAttri.Foreground = clGray
    ConditionalCommentAttri.Foreground = clRed
    ConsoleOutputAttri.Foreground = clBlue
    DataTypeAttri.Foreground = clNavy
    DelimitedIdentifierAttri.Background = clWhite
    DelimitedIdentifierAttri.Foreground = clGreen
    IdentifierAttri.Background = clWhite
    KeyAttri.Foreground = clBlue
    NumberAttri.Foreground = clNavy
    PLSQLAttri.Foreground = clBlue
    SQLPlusAttri.Foreground = clBlue
    StringAttri.Background = clWhite
    StringAttri.Foreground = clOlive
    ProcNameAttri.Foreground = clBlue
    TableNameAttri.Foreground = clLime
    VariableAttri.Foreground = clLime
    SQLDialect = sqlMySQL
    Left = 176
    Top = 432
  end
  inherited dsTablaG: TDataSource
    DataSet = dmGeneradorProcesos.unqryTablaG
    Left = 428
    Top = 287
  end
  object alGenerador: TActionList
    Left = 488
    Top = 272
    object ActionSeleccionar: TAction
      Caption = 'Seleccionar Todo'
      ShortCut = 16449
      OnExecute = ActionSeleccionarExecute
      OnUpdate = ActionSeleccionarUpdate
    end
    object ActionEjecutar: TAction
      Caption = 'Ejecutar'
      ShortCut = 116
      OnExecute = ActionEjecutarExecute
    end
    object actComentar: TAction
      Caption = 'Comentar'
    end
    object actAbrirScript: TAction
      Caption = 'Abrir Script'
      ShortCut = 114
      OnExecute = btnAbrirScriptClick
    end
  end
end
