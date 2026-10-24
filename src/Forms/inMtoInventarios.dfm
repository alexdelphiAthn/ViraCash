inherited frmMtoInventarios: TfrmMtoInventarios
  Caption = 'Mantenimiento de Inventarios'
  ClientHeight = 720
  ClientWidth = 1280
  StyleElements = [seFont, seClient, seBorder]
  OnDestroy = FormDestroy
  ExplicitWidth = 1280
  ExplicitHeight = 720
  TextHeight = 18
  inherited pButtonPage: TPanel
    Width = 1140
    Height = 720
    StyleElements = [seFont, seClient, seBorder]
    ExplicitWidth = 1140
    ExplicitHeight = 720
    inherited pcPantalla: TcxPageControl
      Width = 1140
      Height = 680
      ExplicitWidth = 1140
      ExplicitHeight = 680
      ClientRectBottom = 676
      ClientRectRight = 1136
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 28
        ExplicitWidth = 1132
        ExplicitHeight = 648
        inherited cxGrdPrincipal: TcxGrid
          Width = 1132
          Height = 648
          ExplicitWidth = 1132
          ExplicitHeight = 648
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            object colCODIGO_EMP_INV: TcxGridDBColumn
              Caption = 'Empresa'
              DataBinding.FieldName = 'CODIGO_EMP_INV'
              Width = 102
            end
            object colCODIGO_ALM_INV: TcxGridDBColumn
              Caption = 'Almac'#233'n'
              DataBinding.FieldName = 'CODIGO_ALM_INV'
              Width = 80
            end
            object colSERIE_INV: TcxGridDBColumn
              Caption = 'Serie'
              DataBinding.FieldName = 'SERIE_INV'
              Width = 80
            end
            object colNUMERO_INV: TcxGridDBColumn
              Caption = 'N'#250'mero'
              DataBinding.FieldName = 'NUMERO_INV'
              Width = 88
            end
            object colFECHA_INV: TcxGridDBColumn
              Caption = 'Fecha'
              DataBinding.FieldName = 'FECHA_INV'
              PropertiesClassName = 'TcxDateEditProperties'
              Properties.SaveTime = False
              Properties.ShowTime = False
              Width = 127
            end
            object colESTADO_INV: TcxGridDBColumn
              Caption = 'Estado'
              DataBinding.FieldName = 'ESTADO_INV'
              Width = 134
            end
            object colDESCRIPCION_INV: TcxGridDBColumn
              Caption = 'Descripci'#243'n'
              DataBinding.FieldName = 'DESCRIPCION_INV'
              Width = 260
            end
            object colTOT_UDS_DIF_INV: TcxGridDBColumn
              Caption = 'Uds. diferencia'
              DataBinding.FieldName = 'TOTAL_UNIDADES_DIFERENCIA_INV'
              PropertiesClassName = 'TcxCalcEditProperties'
              Properties.DisplayFormat = '+,0.00;-,0.00'
              HeaderAlignmentHorz = taRightJustify
              Width = 110
            end
            object colTOT_EUR_DIF_INV: TcxGridDBColumn
              Caption = #8364' diferencia'
              DataBinding.FieldName = 'TOTAL_EUROS_DIFERENCIA_INV'
              PropertiesClassName = 'TcxCalcEditProperties'
              Properties.DisplayFormat = '+,0.00 '#8364';-,0.00 '#8364
              HeaderAlignmentHorz = taRightJustify
              Width = 120
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 29
        ExplicitWidth = 1132
        ExplicitHeight = 647
        object pnlTopFicha: TPanel
          Left = 0
          Top = 0
          Width = 1132
          Height = 174
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          object pnlBodyFicha: TPanel
            Left = 0
            Top = 0
            Width = 1132
            Height = 174
            Align = alClient
            BevelOuter = bvNone
            TabOrder = 0
            object lblEmpresa: TcxLabel
              Left = 32
              Top = 15
              Caption = 'Empresa'
              TabOrder = 0
              Transparent = True
            end
            object cbbCODIGO_EMPRESA_INVENTARIO: TcxDBLookupComboBox
              Left = 121
              Top = 11
              DataBinding.DataField = 'CODIGO_EMP_INV'
              DataBinding.DataSource = dsTablaG
              Properties.KeyFieldNames = 'CODIGO_EMP_EMP'
              Properties.ListColumns = <
                item
                  Width = 80
                  FieldName = 'CODIGO_EMP_EMP'
                end
                item
                  Width = 200
                  FieldName = 'RAZON_SOCIAL_EMP'
                end>
              Properties.OnEditValueChanged = cbbCODIGO_EMPRESA_INVENTARIOPropertiesEditValueChanged
              TabOrder = 1
              Width = 280
            end
            object lblAlmacen: TcxLabel
              Left = 31
              Top = 47
              Caption = 'Almac'#233'n'
              TabOrder = 2
              Transparent = True
            end
            object cbbCODIGO_ALMACEN_INVENTARIO: TcxDBLookupComboBox
              Left = 121
              Top = 43
              DataBinding.DataField = 'CODIGO_ALM_INV'
              DataBinding.DataSource = dsTablaG
              Properties.KeyFieldNames = 'CODIGO_ALMACEN'
              Properties.ListColumns = <
                item
                  Width = 80
                  FieldName = 'CODIGO_ALMACEN'
                end
                item
                  Width = 200
                  FieldName = 'DESCRIPCION_ALMACEN'
                end>
              TabOrder = 3
              Width = 280
            end
            object lblSerie: TcxLabel
              Left = 62
              Top = 85
              Caption = 'Serie'
              TabOrder = 4
              Transparent = True
            end
            object cbbSERIE_INVENTARIO: TcxDBLookupComboBox
              Left = 121
              Top = 78
              DataBinding.DataField = 'SERIE_INV'
              DataBinding.DataSource = dsTablaG
              Properties.KeyFieldNames = 'EMPSER'
              Properties.ListColumns = <
                item
                  Width = 120
                  FieldName = 'EMPSER'
                end>
              TabOrder = 5
              Width = 120
            end
            object lblNumero: TcxLabel
              Left = 35
              Top = 115
              Caption = 'N'#250'mero'
              TabOrder = 6
              Transparent = True
            end
            object txtNRO_INVENTARIO: TcxDBTextEdit
              Left = 121
              Top = 111
              DataBinding.DataField = 'NUMERO_INV'
              DataBinding.DataSource = dsTablaG
              TabOrder = 7
              Width = 174
            end
            object lblFecha: TcxLabel
              Left = 353
              Top = 115
              Caption = 'Fecha'
              TabOrder = 8
              Transparent = True
            end
            object dtFECHA_INVENTARIO: TcxDBDateEdit
              Left = 418
              Top = 111
              DataBinding.DataField = 'FECHA_INV'
              DataBinding.DataSource = dsTablaG
              TabOrder = 9
              Width = 228
            end
            object lblEstado: TcxLabel
              Left = 346
              Top = 85
              Caption = 'Estado'
              TabOrder = 10
              Transparent = True
            end
            object txtESTADO_INVENTARIO: TcxDBTextEdit
              Left = 418
              Top = 78
              DataBinding.DataField = 'ESTADO_INV'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = True
              TabOrder = 11
              Width = 228
            end
            object lblDescripcion: TcxLabel
              Left = 3
              Top = 144
              Caption = 'Descripci'#243'n'
              TabOrder = 12
              Transparent = True
            end
            object txtDESCRIPCION_INVENTARIO: TcxDBTextEdit
              Left = 121
              Top = 144
              DataBinding.DataField = 'DESCRIPCION_INV'
              DataBinding.DataSource = dsTablaG
              TabOrder = 13
              Width = 457
            end
            object btnEnviarRecuento: TcxButton
              Left = 703
              Top = 73
              Width = 226
              Height = 30
              Caption = 'Enviar a recuento m'#243'vil'
              TabOrder = 14
              OnClick = btnEnviarRecuentoClick
            end
            object btnRecogerRecuento: TcxButton
              Left = 703
              Top = 109
              Width = 226
              Height = 30
              Caption = 'Recoger recuento m'#243'vil'
              TabOrder = 15
              OnClick = btnRecogerRecuentoClick
            end
          end
        end
        object pnlButtonFicha: TPanel
          Left = 0
          Top = 182
          Width = 1132
          Height = 465
          Align = alClient
          TabOrder = 1
          object pcDetail: TcxPageControl
            Left = 1
            Top = 1
            Width = 1130
            Height = 463
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsDetalle
            Properties.CustomButtons.Buttons = <>
            OnChange = pcDetailChange
            ClientRectBottom = 459
            ClientRectLeft = 4
            ClientRectRight = 1126
            ClientRectTop = 29
            object tsDetalle: TcxTabSheet
              Caption = '&1. Detalle del inventario'
              ImageIndex = 1
              object pnlDetalleTop: TPanel
                Left = 0
                Top = 0
                Width = 1122
                Height = 52
                Align = alTop
                BevelOuter = bvNone
                TabOrder = 0
                object btnAnadirLinea: TcxButton
                  Left = 7
                  Top = 11
                  Width = 130
                  Height = 30
                  Caption = '+ A'#241'adir l'#237'nea'
                  TabOrder = 0
                  Visible = False
                  OnClick = btnAnadirLineaClick
                end
                object btnAnadirSkusArt: TcxButton
                  Left = 7
                  Top = 11
                  Width = 170
                  Height = 30
                  Hint = 
                    'A'#241'ade todos los SKUs del art'#237'culo de la l'#237'nea actual que tengan ' +
                    'movimientos en el almac'#233'n del inventario.'
                  Caption = '+ SKUs con mov.'
                  ParentShowHint = False
                  ShowHint = True
                  TabOrder = 1
                  OnClick = btnAnadirSkusArtClick
                end
                object btnRecalcularDetalle: TcxButton
                  Left = 183
                  Top = 11
                  Width = 200
                  Height = 30
                  Caption = 'Recalcular te'#243'rico/PMP'
                  TabOrder = 2
                  OnClick = btnRecalcularDetalleClick
                end
                object btnCargarExcel: TcxButton
                  Left = 389
                  Top = 11
                  Width = 130
                  Height = 30
                  Caption = 'Cargar Excel'
                  TabOrder = 3
                  OnClick = btnCargarExcelClick
                end
                object btnExportarInv: TcxButton
                  Left = 525
                  Top = 11
                  Width = 140
                  Height = 30
                  Caption = 'Exportar a Excel'
                  TabOrder = 4
                  OnClick = btnExportarInvClick
                end
                object btnIraArticulo: TcxButton
                  Left = 671
                  Top = 11
                  Width = 130
                  Height = 30
                  Caption = 'Ir a Art'#237'culo'
                  TabOrder = 5
                  OnClick = btnIraArticuloClick
                end
                object btnImportarInventario: TcxButton
                  Left = 807
                  Top = 11
                  Width = 160
                  Height = 30
                  Caption = 'Importar inventario'
                  TabOrder = 6
                  OnClick = btnImportarInventarioClick
                end
                object chkVerColumnasAtributos: TcxCheckBox
                  Left = 24
                  Top = 47
                  Hint = 
                    'Activa la construcci'#243'n de las columnas SKU1..SKU5 con los nombre' +
                    's de atributo del art'#237'culo. Implica recorrer todas las l'#237'neas pa' +
                    'ra desempaquetar el SKU. Si hay m'#225's de 150 l'#237'neas se muestra una' +
                    ' barra de progreso.'
                  Caption = 'Ver atributos en columnas'
                  ParentShowHint = False
                  Properties.OnChange = chkVerColumnasAtributosPropertiesChange
                  ShowHint = True
                  TabOrder = 7
                end
              end
              object cxgrdLineas: TcxGrid
                Left = 0
                Top = 52
                Width = 1122
                Height = 378
                Align = alClient
                TabOrder = 1
                OnEnter = cxgrdLineasEnter
                object tvLineas: TcxGridDBTableView
                  Navigator.Buttons.ConfirmDelete = True
                  Navigator.Buttons.PriorPage.Visible = False
                  Navigator.Buttons.NextPage.Visible = False
                  Navigator.Buttons.Append.Visible = False
                  Navigator.Buttons.Edit.Visible = False
                  Navigator.Buttons.SaveBookmark.Visible = False
                  Navigator.Buttons.GotoBookmark.Visible = False
                  Navigator.Buttons.Filter.Visible = False
                  Navigator.Visible = True
                  OnCustomDrawCell = tvLineasCustomDrawCell
                  OnEditing = tvLineasEditing
                  OnEditKeyDown = tvLineasEditKeyDown
                  OnFocusedRecordChanged = tvLineasFocusedRecordChanged
                  OnInitEdit = tvLineasInitEdit
                  OptionsBehavior.FocusCellOnTab = True
                  OptionsBehavior.GoToNextCellOnEnter = True
                  OptionsBehavior.FocusCellOnCycle = True
                  OptionsData.Appending = True
                  OptionsSelection.HideFocusRectOnExit = False
                  OptionsView.GroupByBox = False
                  object tvLineasLINEA: TcxGridDBColumn
                    Caption = 'L'#237'nea'
                    DataBinding.FieldName = 'LINEA_INVLIN'
                    Options.Editing = False
                    Width = 68
                  end
                  object tvLineasARTICULO: TcxGridDBColumn
                    Caption = 'Art'#237'culo'
                    DataBinding.FieldName = 'CODIGO_ART_INVLIN'
                    PropertiesClassName = 'TcxButtonEditProperties'
                    Properties.Buttons = <
                      item
                        Default = True
                        Kind = bkEllipsis
                      end>
                    Properties.OnButtonClick = tvLineasUnidadPropertiesButtonClick
                    Properties.OnValidate = tvLineasUnidadPropertiesValidate
                    Visible = False
                    Width = 130
                  end
                  object tvLineasUNIDAD: TcxGridDBColumn
                    Caption = 'SKU/Art'#237'culo'
                    DataBinding.FieldName = 'CODIGO_UNIDAD_INVLIN'
                    PropertiesClassName = 'TcxButtonEditProperties'
                    Properties.Buttons = <
                      item
                        Default = True
                        Kind = bkEllipsis
                      end>
                    Properties.OnButtonClick = tvLineasUnidadPropertiesButtonClick
                    Properties.OnValidate = tvLineasUnidadPropertiesValidate
                    Width = 180
                  end
                  object tvLineasSKU1: TcxGridDBColumn
                    Tag = 1
                    Caption = 'SKU 1'
                    DataBinding.FieldName = 'ATTR1_VALOR'
                    PropertiesClassName = 'TcxButtonEditProperties'
                    Properties.Buttons = <
                      item
                        Default = True
                        Kind = bkEllipsis
                      end>
                    Properties.OnButtonClick = tvLineasSkuPropertiesButtonClick
                    Visible = False
                    Width = 80
                  end
                  object tvLineasSKU2: TcxGridDBColumn
                    Tag = 2
                    Caption = 'SKU 2'
                    DataBinding.FieldName = 'ATTR2_VALOR'
                    PropertiesClassName = 'TcxButtonEditProperties'
                    Properties.Buttons = <
                      item
                        Default = True
                        Kind = bkEllipsis
                      end>
                    Properties.OnButtonClick = tvLineasSkuPropertiesButtonClick
                    Visible = False
                    Width = 80
                  end
                  object tvLineasSKU3: TcxGridDBColumn
                    Tag = 3
                    Caption = 'SKU 3'
                    DataBinding.FieldName = 'ATTR3_VALOR'
                    PropertiesClassName = 'TcxButtonEditProperties'
                    Properties.Buttons = <
                      item
                        Default = True
                        Kind = bkEllipsis
                      end>
                    Properties.OnButtonClick = tvLineasSkuPropertiesButtonClick
                    Visible = False
                    Width = 80
                  end
                  object tvLineasSKU4: TcxGridDBColumn
                    Tag = 4
                    Caption = 'SKU 4'
                    DataBinding.FieldName = 'ATTR4_VALOR'
                    PropertiesClassName = 'TcxButtonEditProperties'
                    Properties.Buttons = <
                      item
                        Default = True
                        Kind = bkEllipsis
                      end>
                    Properties.OnButtonClick = tvLineasSkuPropertiesButtonClick
                    Visible = False
                    Width = 80
                  end
                  object tvLineasSKU5: TcxGridDBColumn
                    Tag = 5
                    Caption = 'SKU 5'
                    DataBinding.FieldName = 'ATTR5_VALOR'
                    PropertiesClassName = 'TcxButtonEditProperties'
                    Properties.Buttons = <
                      item
                        Default = True
                        Kind = bkEllipsis
                      end>
                    Properties.OnButtonClick = tvLineasSkuPropertiesButtonClick
                    Visible = False
                    Width = 80
                  end
                  object tvLineasDESCRIPCION: TcxGridDBColumn
                    Caption = 'Descripci'#243'n'
                    DataBinding.FieldName = 'DESCRIPCION_ARTICULO_INVLIN'
                    Options.Editing = False
                    Width = 220
                  end
                  object tvLineasLOTE: TcxGridDBColumn
                    Caption = 'Lote'
                    DataBinding.FieldName = 'LOTE_INVLIN'
                    Visible = False
                    Width = 80
                  end
                  object tvLineasCADUCIDAD: TcxGridDBColumn
                    Caption = 'Caducidad'
                    DataBinding.FieldName = 'FECHA_CADUCIDAD_INVLIN'
                    Visible = False
                    Width = 90
                  end
                  object tvLineasUDS_TEORICAS: TcxGridDBColumn
                    Caption = 'Uds. te'#243'ricas'
                    DataBinding.FieldName = 'CANTIDAD_TEORICA_INVLIN'
                    HeaderAlignmentHorz = taRightJustify
                    Options.Editing = False
                    Width = 141
                  end
                  object tvLineasUDS_FISICAS: TcxGridDBColumn
                    Caption = 'Recuento'
                    DataBinding.FieldName = 'CANTIDAD_FISICA_INVLIN'
                    HeaderAlignmentHorz = taRightJustify
                    Width = 110
                  end
                  object tvLineasPMP_ACTUAL: TcxGridDBColumn
                    Caption = 'PMP actual'
                    DataBinding.FieldName = 'PRECIO_MEDIO_INVLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    HeaderAlignmentHorz = taRightJustify
                    Options.Editing = False
                    Width = 119
                  end
                  object tvLineasPMP_NUEVO: TcxGridDBColumn
                    Caption = 'PMP nuevo'
                    DataBinding.FieldName = 'PRECIO_MEDIO_NUEVO_INVLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    HeaderAlignmentHorz = taRightJustify
                    Width = 128
                  end
                  object tvLineasPMP_CORREGIDO: TcxGridDBColumn
                    Caption = 'PMP manual'
                    DataBinding.FieldName = 'ESPRECIO_MEDIO_CORREGIDO_INVLIN'
                    PropertiesClassName = 'TcxCheckBoxProperties'
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    Width = 90
                  end
                  object tvLineasDIF_UNIDADES: TcxGridDBColumn
                    Caption = 'Dif. uds.'
                    DataBinding.FieldName = 'CANTIDAD_DIFERENCIA_INVLIN'
                    HeaderAlignmentHorz = taRightJustify
                    Options.Editing = False
                    Width = 90
                  end
                  object tvLineasDIF_COSTE: TcxGridDBColumn
                    Caption = 'Dif. coste'
                    DataBinding.FieldName = 'TOTAL_COSTE_DIFERENCIA_INVLIN'
                    HeaderAlignmentHorz = taRightJustify
                    Options.Editing = False
                    Width = 110
                  end
                  object tvLineasUDS_REGULARIZADAS: TcxGridDBColumn
                    Caption = 'Uds. regul.'
                    DataBinding.FieldName = 'UDS_REGULARIZADAS'
                    HeaderAlignmentHorz = taRightJustify
                    Options.Editing = False
                    Width = 116
                  end
                  object tvLineasFECHA_RECUENTO: TcxGridDBColumn
                    Caption = 'Hora recuento'
                    DataBinding.FieldName = 'FECHA_RECUENTO_INVLIN'
                    Options.Editing = False
                    Width = 212
                  end
                  object tvLineasUSUARIO: TcxGridDBColumn
                    Caption = 'Usuario'
                    DataBinding.FieldName = 'USUARIO_MODIF'
                    Visible = False
                    Options.Editing = False
                    Width = 110
                  end
                end
                object cxgrdlvlLineas: TcxGridLevel
                  GridView = tvLineas
                end
              end
            end
            object tsMovsRegul: TcxTabSheet
              Caption = '&2. Movimientos regularizados'
              ImageIndex = 2
              object pnlMovsTop: TPanel
                Left = 0
                Top = 0
                Width = 1122
                Height = 50
                Align = alTop
                BevelOuter = bvNone
                TabOrder = 0
                object lblInfoMovs: TcxLabel
                  Left = 16
                  Top = 16
                  Caption = 'Movimientos generados al aplicar este inventario en el Kardex'
                  TabOrder = 1
                  Transparent = True
                end
                object btnEliminarRegularizacion: TcxButton
                  Left = 560
                  Top = 10
                  Width = 241
                  Height = 30
                  Caption = 'Eliminar regularizaci'#243'n'
                  TabOrder = 0
                  OnClick = btnEliminarRegularizacionClick
                end
              end
              object cxgrdMovs: TcxGrid
                Left = 0
                Top = 50
                Width = 1001
                Height = 380
                Align = alClient
                TabOrder = 1
                object tvMovs: TcxGridDBTableView
                  OptionsData.Deleting = False
                  OptionsData.Editing = False
                  OptionsData.Inserting = False
                  OptionsView.GroupByBox = False
                  object tvMovsNUMERO: TcxGridDBColumn
                    Caption = 'N'#250'mero'
                    DataBinding.FieldName = 'NUMERO_MOV'
                    Width = 160
                  end
                  object tvMovsTIPO: TcxGridDBColumn
                    Caption = 'Tipo'
                    DataBinding.FieldName = 'TIPO_MOV'
                    Width = 50
                  end
                  object tvMovsARTICULO: TcxGridDBColumn
                    Caption = 'Art'#237'culo'
                    DataBinding.FieldName = 'CODIGO_ART_MOV'
                    Width = 130
                  end
                  object tvMovsUNIDAD: TcxGridDBColumn
                    Caption = 'SKU'
                    DataBinding.FieldName = 'CODIGO_UNIDAD_MOV'
                    Width = 200
                  end
                  object tvMovsCANTIDAD: TcxGridDBColumn
                    Caption = 'Cantidad'
                    DataBinding.FieldName = 'CANTIDAD_MOV'
                    HeaderAlignmentHorz = taRightJustify
                    Width = 100
                  end
                  object tvMovsPRECIO: TcxGridDBColumn
                    Caption = 'PMP'
                    DataBinding.FieldName = 'PRECIO_MEDIO_MOV'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    HeaderAlignmentHorz = taRightJustify
                    Width = 100
                  end
                  object tvMovsCOSTE: TcxGridDBColumn
                    Caption = 'Coste'
                    DataBinding.FieldName = 'COSTE_MOV'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    HeaderAlignmentHorz = taRightJustify
                    Width = 110
                  end
                  object tvMovsFECHA: TcxGridDBColumn
                    Caption = 'Fecha'
                    DataBinding.FieldName = 'FECHA_MOV'
                    Width = 140
                  end
                  object tvMovsACTIVO: TcxGridDBColumn
                    Caption = 'Activo'
                    DataBinding.FieldName = 'ESACTIVO_MOV'
                    Width = 60
                  end
                end
                object cxgrdlvlMovs: TcxGridLevel
                  GridView = tvMovs
                end
              end
              object pnlBotonesAccion: TPanel
                Left = 1001
                Top = 50
                Width = 121
                Height = 380
                Align = alRight
                TabOrder = 2
                object btnExportarExcel: TcxButton
                  Left = 3
                  Top = 11
                  Width = 116
                  Height = 34
                  Caption = '&Exp Excel'
                  TabOrder = 0
                end
                object btnIraArticuloMov: TcxButton
                  Left = 3
                  Top = 51
                  Width = 116
                  Height = 34
                  Caption = 'Ir a Art'#237'culo'
                  TabOrder = 1
                  OnClick = btnIraArticuloMovClick
                end
              end
            end
            object tsCabecera: TcxTabSheet
              Caption = '&3.Otros'
              ImageIndex = 0
              object pnlCabecera: TPanel
                Left = 0
                Top = 0
                Width = 1122
                Height = 480
                Align = alTop
                BevelOuter = bvNone
                TabOrder = 0
                object lblObservaciones: TcxLabel
                  Left = 24
                  Top = 196
                  Caption = 'Observaciones'
                  TabOrder = 2
                  Transparent = True
                end
                object mmoOBSERVACIONES_INVENTARIO: TcxDBMemo
                  Left = 156
                  Top = 194
                  DataBinding.DataField = 'OBSERVACIONES_INV'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 0
                  Height = 90
                  Width = 574
                end
                object pnlTotales: TGroupBox
                  Left = 21
                  Top = 24
                  Width = 480
                  Height = 130
                  Caption = '  Totales del descuadre  '
                  TabOrder = 1
                  object lblTotalUnidades: TcxLabel
                    Left = 16
                    Top = 32
                    Caption = 'Total unidades de descuadre'
                    TabOrder = 1
                    Transparent = True
                  end
                  object txtTOTAL_UNIDADES_DIFERENCIA: TcxDBTextEdit
                    Left = 265
                    Top = 30
                    DataBinding.DataField = 'TOTAL_UNIDADES_DIFERENCIA_INV'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    TabOrder = 0
                    Width = 177
                  end
                  object lblTotalEuros: TcxLabel
                    Left = 52
                    Top = 76
                    Caption = 'Variaci'#243'n econ'#243'mica ('#8364')'
                    TabOrder = 2
                    Transparent = True
                  end
                  object curTOTAL_EUROS_DIFERENCIA_INV: TcxDBCurrencyEdit
                    Left = 265
                    Top = 72
                    DataBinding.DataField = 'TOTAL_EUROS_DIFERENCIA_INV'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 3
                    Width = 177
                  end
                end
                object pnlAuditoria: TPanel
                  Left = 21
                  Top = 306
                  Width = 684
                  Height = 110
                  BevelOuter = bvLowered
                  TabOrder = 3
                  object lblUsuarioAlta: TcxLabel
                    Left = 8
                    Top = 8
                    Caption = 'Alta'
                    TabOrder = 4
                    Transparent = True
                  end
                  object txtUSUARIOALTA: TcxDBTextEdit
                    Left = 74
                    Top = 6
                    DataBinding.DataField = 'USUARIO_ALTA'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    TabOrder = 0
                    Width = 166
                  end
                  object lblInstanteAlta: TcxLabel
                    Left = 245
                    Top = 8
                    Caption = 'Fecha Alta'
                    TabOrder = 5
                    Transparent = True
                  end
                  object txtINSTANTEALTA: TcxDBTextEdit
                    Left = 364
                    Top = 6
                    DataBinding.DataField = 'INSTANTE_ALTA'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    TabOrder = 1
                    Width = 285
                  end
                  object lblUsuarioModif: TcxLabel
                    Left = 8
                    Top = 50
                    Caption = 'Modif.'
                    TabOrder = 6
                    Transparent = True
                  end
                  object txtUSUARIOMODIF: TcxDBTextEdit
                    Left = 74
                    Top = 48
                    DataBinding.DataField = 'USUARIO_MODIF'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    TabOrder = 2
                    Width = 166
                  end
                  object lblInstanteModif: TcxLabel
                    Left = 245
                    Top = 50
                    Caption = 'Fecha Modif.'
                    TabOrder = 7
                    Transparent = True
                  end
                  object txtINSTANTEMODIF: TcxDBTextEdit
                    Left = 364
                    Top = 48
                    DataBinding.DataField = 'INSTANTE_MODIF'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    TabOrder = 3
                    Width = 285
                  end
                end
              end
            end
          end
        end
        object splSplitterFicha: TcxSplitter
          Left = 0
          Top = 174
          Width = 1132
          Height = 8
          HotZoneClassName = 'TcxMediaPlayer9Style'
          AlignSplitter = salTop
          Control = pnlButtonFicha
        end
      end
      inherited tsPerfil: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 29
        ExplicitWidth = 1132
        ExplicitHeight = 647
        inherited pnlPerfilTop: TPanel
          Width = 1132
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 1132
          inherited edtPerfilBusq: TcxTextEdit
            ExplicitHeight = 25
          end
        end
        inherited pnlPerfilDetail: TPanel
          Width = 1132
          Height = 590
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 1132
          ExplicitHeight = 591
          inherited cxgrdPerfil: TcxGrid
            Width = 1132
            Height = 591
            ExplicitWidth = 1132
            ExplicitHeight = 591
          end
        end
      end
    end
    inherited pnlTopPage: TPanel
      Width = 1140
      StyleElements = [seFont, seClient, seBorder]
      ExplicitWidth = 1140
      inherited pnlTopGrid: TPanel
        Width = 1140
        StyleElements = [seFont, seClient, seBorder]
        ExplicitWidth = 1140
        inherited edtBusqGlobal: TcxTextEdit
          ExplicitHeight = 26
        end
      end
    end
  end
  inherited pButtonRightBar: TPanel
    Left = 1140
    Height = 720
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 1140
    ExplicitHeight = 720
    inherited pButtonGen: TPanel
      Top = 522
      StyleElements = [seFont, seClient, seBorder]
      ExplicitTop = 522
    end
    inherited pButtonBDStat: TPanel
      StyleElements = [seFont, seClient, seBorder]
      inherited pnStateDataSet: TPanel
        StyleElements = [seFont, seClient, seBorder]
        inherited lblEditMode: TcxLabel
          Left = 17
          Top = 7
          ExplicitLeft = 17
          ExplicitTop = 7
        end
      end
      inherited pnlDataSetName: TPanel
        StyleElements = [seFont, seClient, seBorder]
      end
    end
    object btnAplicar: TcxButton
      Left = 0
      Top = 333
      Width = 137
      Height = 40
      Caption = '&Regularizar'
      TabOrder = 2
      OnClick = btnAplicarClick
    end
    object btnCargar: TcxButton
      Left = 0
      Top = 282
      Width = 137
      Height = 40
      Caption = 'Car&gar'
      OptionsImage.ImageIndex = 0
      TabOrder = 3
      OnClick = btnCargarClick
    end
    object btnRevalorizarPmp: TcxButton
      Left = 0
      Top = 384
      Width = 137
      Height = 40
      Action = actRevalorizarPmp
      ParentShowHint = False
      ShowHint = True
      TabOrder = 4
    end
  end
  inherited dsTablaG: TDataSource
    DataSet = dmInventarios.unqryTablaG
    OnDataChange = dsTablaGDataChange
    Left = 120
    Top = 432
  end
  object dlgAbrir: TOpenDialog
    Filter = 
      'Archivos CSV (*.csv;*.txt)|*.csv;*.txt|Excel (*.xlsx)|*.xlsx|Tod' +
      'os|*.*'
    Options = [ofHideReadOnly, ofPathMustExist, ofFileMustExist]
    Left = 948
    Top = 224
  end
  object ActionList1: TActionList
    Left = 608
    Top = 288
    object actIraArticulo: TAction
      Caption = 'Ir a art'#237'culo'
      ShortCut = 16466
      OnExecute = actIraArticuloExecute
    end
    object actRevalorizarPmp: TAction
      ShortCut = 24658
      OnExecute = actRevalorizarPmpExecute
    end
  end
end
