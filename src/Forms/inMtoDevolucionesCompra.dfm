inherited frmMtoDevolucionesCompra: TfrmMtoDevolucionesCompra
  Caption = 'Mantenimiento de Devoluciones a Proveedor'
  ClientHeight = 765
  ClientWidth = 1085
  StyleElements = [seFont, seClient, seBorder]
  OnDestroy = FormDestroy
  ExplicitWidth = 1085
  ExplicitHeight = 765
  TextHeight = 17
  inherited pButtonPage: TPanel
    Width = 945
    Height = 765
    StyleElements = [seFont, seClient, seBorder]
    ExplicitWidth = 945
    ExplicitHeight = 765
    inherited pcPantalla: TcxPageControl
      Width = 945
      Height = 725
      Properties.ActivePage = tsLista
      ExplicitWidth = 945
      ExplicitHeight = 725
      ClientRectBottom = 721
      ClientRectRight = 941
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 28
        ExplicitWidth = 937
        ExplicitHeight = 693
        inherited cxGrdPrincipal: TcxGrid
          Width = 937
          Height = 693
          ExplicitWidth = 937
          ExplicitHeight = 693
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            object dbcGrdDevcNUMERO_DEVC: TcxGridDBColumn
              Caption = 'N'#250'mero'
              DataBinding.FieldName = 'NUMERO_DEVC'
              Width = 90
            end
            object dbcGrdDevcSERIE_DEVC: TcxGridDBColumn
              Caption = 'Serie'
              DataBinding.FieldName = 'SERIE_DEVC'
              Width = 80
            end
            object dbcGrdDevcINSTANTEMOVIMIENTO_DEVC: TcxGridDBColumn
              Caption = 'Fecha y hora stock'
              DataBinding.FieldName = 'INSTANTE_MOVIMIENTO_DEVC'
              PropertiesClassName = 'TcxDateEditProperties'
              Properties.DisplayFormat = 'dd/mm/yyyy hh:nn:ss'
              Properties.Kind = ckDateTime
              Width = 145
            end
            object dbcGrdDevcCODIGO_EMP_DEVC: TcxGridDBColumn
              Caption = 'Empresa'
              DataBinding.FieldName = 'CODIGO_EMP_DEVC'
              Width = 100
            end
            object dbcGrdDevcCODIGO_PRV_DEVC: TcxGridDBColumn
              Caption = 'Proveedor'
              DataBinding.FieldName = 'CODIGO_PRV_DEVC'
              Width = 100
            end
            object dbcGrdDevcRSPRV_DEVC: TcxGridDBColumn
              Caption = 'Raz'#243'n Social Proveedor'
              DataBinding.FieldName = 'RAZON_SOCIAL_PRV_DEVC'
              Width = 220
            end
            object dbcGrdDevcREF_PROVEEDOR_DEVC: TcxGridDBColumn
              Caption = 'Ref. proveedor'
              DataBinding.FieldName = 'REF_PROVEEDOR_DEVC'
              Width = 130
            end
            object dbcGrdDevcCODIGO_ALM_DEVC: TcxGridDBColumn
              Caption = 'Almac'#233'n'
              DataBinding.FieldName = 'CODIGO_ALM_DEVC'
              Width = 100
            end
            object dbcGrdDevcTOTAL_PRENDAS_DEVC: TcxGridDBColumn
              Caption = 'N'#186' de prendas'
              DataBinding.FieldName = 'TOTAL_PRENDAS_DEVC'
              Options.Editing = False
              Width = 100
            end
            object dbcGrdDevcTOTAL_LIQUIDO_DEVC: TcxGridDBColumn
              Caption = 'Total l'#237'quido'
              DataBinding.FieldName = 'TOTAL_LIQUIDO_DEVC'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 120
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 28
        ExplicitWidth = 937
        ExplicitHeight = 693
        object pnlTopFicha: TPanel
          Left = 0
          Top = 0
          Width = 937
          Height = 200
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          object pcCab: TcxPageControl
            Left = 0
            Top = 0
            Width = 937
            Height = 200
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsCabecera
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 196
            ClientRectLeft = 4
            ClientRectRight = 933
            ClientRectTop = 28
            object tsCabecera: TcxTabSheet
              Caption = 'Cabecera'
              object lblNroDevolucion: TcxLabel
                Left = 8
                Top = 12
                Caption = 'N'#250'mero'
                TabOrder = 0
                Transparent = True
              end
              object txtNUMERO_DEVC: TcxDBTextEdit
                Left = 8
                Top = 32
                DataBinding.DataField = 'NUMERO_DEVC'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 1
                Width = 100
              end
              object lblSerieDevolucion: TcxLabel
                Left = 116
                Top = 12
                Caption = 'Serie'
                TabOrder = 2
                Transparent = True
              end
              object cbbSERIE_DEVC: TcxDBComboBox
                Left = 116
                Top = 32
                DataBinding.DataField = 'SERIE_DEVC'
                DataBinding.DataSource = dsTablaG
                Properties.MaxLength = 12
                Properties.OnInitPopup = cbbSERIE_DEVCPropertiesInitPopup
                TabOrder = 3
                Width = 80
              end
              object lblFechaDevolucion: TcxLabel
                Left = 204
                Top = 12
                Caption = 'Fecha y hora stock'
                TabOrder = 4
                Transparent = True
              end
              object dteINSTANTEMOVIMIENTO_DEVC: TcxDBDateEdit
                Left = 204
                Top = 32
                DataBinding.DataField = 'INSTANTE_MOVIMIENTO_DEVC'
                DataBinding.DataSource = dsTablaG
                Properties.DisplayFormat = 'dd/mm/yyyy hh:nn:ss'
                Properties.Kind = ckDateTime
                TabOrder = 5
                Width = 156
              end
              object lblCabTotalPrendas: TcxLabel
                Left = 366
                Top = 12
                Caption = 'N'#186' de prendas'
                TabOrder = 6
                Transparent = True
              end
              object lblCabTotalPrendasValor: TcxLabel
                Left = 366
                Top = 32
                AutoSize = False
                Caption = '0'
                TabOrder = 7
                Transparent = True
                Height = 24
                Width = 110
              end
              object lblCodigoEmpresa: TcxLabel
                Left = 8
                Top = 72
                Caption = 'Empresa'
                TabOrder = 8
                Transparent = True
              end
              object btnCODIGO_EMP_DEVC: TcxDBButtonEdit
                Left = 8
                Top = 92
                DataBinding.DataField = 'CODIGO_EMP_DEVC'
                DataBinding.DataSource = dsTablaG
                Properties.Buttons = <
                  item
                    Default = True
                    Kind = bkEllipsis
                  end>
                Properties.OnButtonClick = btnCODIGO_EMP_DEVCPropertiesButtonClick
                TabOrder = 9
                OnKeyUp = btnCODIGO_EMP_DEVCKeyUp
                Width = 150
              end
              object lblCodigoProveedor: TcxLabel
                Left = 168
                Top = 72
                Caption = 'Proveedor'
                TabOrder = 10
                Transparent = True
              end
              object cbbCODIGO_PRV_DEVC: TcxDBLookupComboBox
                Left = 168
                Top = 92
                DataBinding.DataField = 'CODIGO_PRV_DEVC'
                DataBinding.DataSource = dsTablaG
                Properties.DropDownListStyle = lsEditList
                Properties.DropDownRows = 15
                Properties.IncrementalFiltering = True
                Properties.KeyFieldNames = 'CODIGO_PRV_PRV'
                Properties.ListColumns = <
                  item
                    Caption = 'C'#243'digo'
                    FieldName = 'CODIGO_PRV_PRV'
                  end
                  item
                    Caption = 'Proveedor'
                    FieldName = 'RAZON_SOCIAL_PRV'
                  end>
                TabOrder = 11
                OnKeyUp = cbbCODIGO_PRV_DEVCKeyUp
                Width = 150
              end
              object lblRefProveedor: TcxLabel
                Left = 328
                Top = 72
                Caption = 'Ref. proveedor'
                TabOrder = 12
                Transparent = True
              end
              object txtREF_PROVEEDOR_DEVC: TcxDBTextEdit
                Left = 328
                Top = 92
                DataBinding.DataField = 'REF_PROVEEDOR_DEVC'
                DataBinding.DataSource = dsTablaG
                TabOrder = 13
                Width = 180
              end
              object lblCodigoAlmacen: TcxLabel
                Left = 520
                Top = 72
                Caption = 'Almac'#233'n salida'
                TabOrder = 14
                Transparent = True
              end
              object cbbCODIGO_ALM_DEVC: TcxDBLookupComboBox
                Left = 520
                Top = 92
                DataBinding.DataField = 'CODIGO_ALM_DEVC'
                DataBinding.DataSource = dsTablaG
                Properties.KeyFieldNames = 'CODIGO_ALM_ALM'
                Properties.ListColumns = <
                  item
                    Caption = 'C'#243'digo'
                    Width = 60
                    FieldName = 'CODIGO_ALM_ALM'
                  end
                  item
                    Caption = 'Almac'#233'n'
                    FieldName = 'NOMBRE_ALM_ALM'
                  end>
                Properties.ListOptions.ShowHeader = False
                TabOrder = 15
                Width = 170
              end
              object lblProveedorNombreDevc: TcxLabel
                Left = 168
                Top = 116
                ParentFont = False
                Style.Font.Charset = ANSI_CHARSET
                Style.Font.Color = clWindowText
                Style.Font.Height = -15
                Style.Font.Name = 'Source Sans 3'
                Style.Font.Style = [fsBold]
                Style.IsFontAssigned = True
                TabOrder = 16
                Transparent = True
              end
            end
          end
        end
        object splSplitterFicha: TcxSplitter
          Left = 0
          Top = 200
          Width = 937
          Height = 8
          Cursor = crSizeNS
          HotZoneClassName = 'TcxMediaPlayer9Style'
          HotZone.SizePercent = 50
          AlignSplitter = salTop
          Control = pnlTopFicha
        end
        object pnlBotonesAcciones: TPanel
          Left = 0
          Top = 200
          Width = 937
          Height = 38
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 1
          object btnAnadirLinea: TcxButton
            Left = 8
            Top = 6
            Width = 110
            Height = 26
            Caption = 'A'#241'adir l'#237'nea'
            TabOrder = 0
            OnClick = btnAnadirLineaClick
          end
          object btnBorrarLinea: TcxButton
            Left = 124
            Top = 6
            Width = 110
            Height = 26
            Caption = 'Borrar l'#237'nea'
            TabOrder = 1
            OnClick = btnBorrarLineaClick
          end
          object btnTallasHorizontal: TcxButton
            Left = 398
            Top = 6
            Width = 170
            Height = 26
            Caption = 'Tallas en horizontal'
            TabOrder = 3
            OnClick = btnTallasHorizontalClick
          end
          object btnAtributosColumna: TcxButton
            Left = 574
            Top = 6
            Width = 180
            Height = 26
            Caption = 'Atributo por columna'
            TabOrder = 4
            OnClick = btnAtributosColumnaClick
          end
          object btnDevolverTodoStock: TcxButton
            Left = 240
            Top = 6
            Width = 150
            Height = 26
            Caption = 'Devolver fila'
            TabOrder = 2
            OnClick = btnDevolverTodoStockClick
          end
        end
        object pnlBodyFicha: TPanel
          Left = 0
          Top = 238
          Width = 937
          Height = 379
          Align = alClient
          BevelOuter = bvNone
          TabOrder = 2
          object pcDevolucion: TcxPageControl
            Left = 0
            Top = 0
            Width = 937
            Height = 379
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsLineasDevolucion
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 375
            ClientRectLeft = 4
            ClientRectRight = 933
            ClientRectTop = 28
            object tsLineasDevolucion: TcxTabSheet
              Caption = '&1_L'#237'neas'
              object cxgrdLineasDevolucion: TcxGrid
                Left = 0
                Top = 0
                Width = 929
                Height = 347
                Align = alClient
                TabOrder = 0
                OnEnter = cxgrdLineasDevolucionEnter
                OnExit = cxgrdLineasDevolucionExit
                object tvLineasDevolucion: TcxGridDBTableView
                  OnKeyDown = tvLineasDevolucionKeyDown
                  OnCustomDrawCell = tvLineasDevolucionCustomDrawCell
                  OnEditing = tvLineasDevolucionEditing
                  OnEditKeyDown = tvLineasDevolucionEditKeyDown
                  OnFocusedRecordChanged = tvLineasDevolucionFocusedRecordChanged
                  OptionsBehavior.FocusCellOnTab = True
                  OptionsBehavior.FocusFirstCellOnNewRecord = True
                  OptionsData.Appending = True
                  OptionsView.GroupByBox = False
                  object colLineaDevcLINEA: TcxGridDBColumn
                    Caption = 'L'#237'nea'
                    DataBinding.FieldName = 'LINEA_DEVCLIN'
                    Width = 60
                  end
                  object colLineaDevcCODIGO_ART: TcxGridDBColumn
                    Caption = 'Art'#237'culo'
                    DataBinding.FieldName = 'CODIGO_ART_DEVCLIN'
                    PropertiesClassName = 'TcxButtonEditProperties'
                    Properties.Buttons = <
                      item
                        Default = True
                        Kind = bkEllipsis
                      end>
                    Properties.OnButtonClick = colLineaDevcCODIGO_ARTPropertiesButtonClick
                    Properties.OnValidate = colLineaDevcCODIGO_ARTPropertiesValidate
                    Width = 100
                  end
                  object colLineaDevcCODIGO_UNIDAD: TcxGridDBColumn
                    Caption = 'SKU'
                    DataBinding.FieldName = 'CODIGO_UNIDAD_DEVCLIN'
                    Width = 120
                  end
                  object colLineaDevcREF_PRV: TcxGridDBColumn
                    Caption = 'Modelo prov.'
                    DataBinding.FieldName = 'REF_PRV_DEVCLIN'
                    Width = 100
                  end
                  object colLineaDevcDESCRIPCION: TcxGridDBColumn
                    Caption = 'Descripci'#243'n'
                    DataBinding.FieldName = 'DESCRIPCION_ARTICULO_DEVCLIN'
                    Width = 240
                  end
                  object colLineaDevcCANTIDAD: TcxGridDBColumn
                    Caption = 'Cantidad'
                    DataBinding.FieldName = 'CANTIDAD_DEVCLIN'
                    Width = 80
                  end
                  object colLineaDevcPRECIO_COMPRA: TcxGridDBColumn
                    Caption = 'Precio compra'
                    DataBinding.FieldName = 'PRECIO_COMPRA_SIVA_ARTICULO_DEVCLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Width = 110
                  end
                  object colLineaDevcPORCENTAJE_IVA: TcxGridDBColumn
                    Caption = '% IVA'
                    DataBinding.FieldName = 'PORCENTAJE_IVA_DEVCLIN'
                    Width = 70
                  end
                  object colLineaDevcTOTAL: TcxGridDBColumn
                    Caption = 'Total'
                    DataBinding.FieldName = 'TOTAL_DEVCLIN'
                    Width = 100
                  end
                  object colLineaDevcALMACEN: TcxGridDBColumn
                    Caption = 'Almac'#233'n'
                    DataBinding.FieldName = 'CODIGO_ALMACEN_DEVCLIN'
                    Width = 90
                  end
                end
                object cxgrdlvlLineasDevolucion: TcxGridLevel
                  GridView = tvLineasDevolucion
                end
              end
            end
            object tsTotales: TcxTabSheet
              Caption = '&2_Totales'
              ImageIndex = 2
              object scrTotales: TcxScrollBox
                HorzScrollBar.Margin = 12
                VertScrollBar.Tracking = True
                VertScrollBar.Margin = 12
                AutoScroll = True
                Left = 0
                Top = 0
                Width = 929
                Height = 347
                Align = alClient
                BorderStyle = cxcbsNone
                TabOrder = 0
                object lblTotalesTotalBase: TcxLabel
                  Properties.Alignment.Vert = taVCenter
                  Properties.Alignment.Horz = taRightJustify
                  Width = 206
                  Height = 24
                  AutoSize = False
                  Left = 16
                  Top = 18
                  Caption = 'Total Base Imponible'
                  TabOrder = 0
                  Transparent = True
                end
                object curTotalesTOTAL_BASES_DEVC: TcxDBCurrencyEdit
                  Left = 230
                  Top = 18
                  DataBinding.DataField = 'TOTAL_BASES_DEVC'
                  DataBinding.DataSource = dsTablaG
                  Properties.DisplayFormat = '#,##0.00 '#8364
                  Properties.DecimalPlaces = 2
                  Properties.ReadOnly = True
                  TabOrder = 1
                  Width = 133
                end
                object lblTotalesTotalImpuestos: TcxLabel
                  Properties.Alignment.Vert = taVCenter
                  Properties.Alignment.Horz = taRightJustify
                  Width = 206
                  Height = 24
                  AutoSize = False
                  Left = 16
                  Top = 50
                  Caption = 'Total Impuestos'
                  TabOrder = 2
                  Transparent = True
                end
                object curTotalesTOTAL_IMPUESTOS_DEVC: TcxDBCurrencyEdit
                  Left = 230
                  Top = 50
                  DataBinding.DataField = 'TOTAL_IMPUESTOS_DEVC'
                  DataBinding.DataSource = dsTablaG
                  Properties.DecimalPlaces = 2
                  Properties.DisplayFormat = '#,##0.00 '#8364
                  Properties.ReadOnly = True
                  TabOrder = 3
                  Width = 133
                end
                object lblTotalesPorcRetencion: TcxLabel
                  Properties.Alignment.Vert = taVCenter
                  Properties.Alignment.Horz = taRightJustify
                  Width = 206
                  Height = 24
                  AutoSize = False
                  Left = 16
                  Top = 82
                  Caption = '% Retenci'#243'n'
                  TabOrder = 4
                  Transparent = True
                end
                object spnTotalesPORCENTAJE_RETENCION_DEVC: TcxDBSpinEdit
                  Left = 230
                  Top = 82
                  DataBinding.DataField = 'PORCENTAJE_RETENCION_DEVC'
                  DataBinding.DataSource = dsTablaG
                  Properties.AssignedValues.MinValue = True
                  Properties.DisplayFormat = '0.00 %'
                  Properties.EditFormat = '0.00 %'
                  Properties.MaxValue = 100.000000000000000000
                  TabOrder = 5
                  Width = 133
                end
                object lblTotalesTotalRetencion: TcxLabel
                  Properties.Alignment.Vert = taVCenter
                  Properties.Alignment.Horz = taRightJustify
                  Width = 206
                  Height = 24
                  AutoSize = False
                  Left = 16
                  Top = 114
                  Caption = 'Total Retenci'#243'n'
                  TabOrder = 6
                  Transparent = True
                end
                object curTotalesTOTAL_RETENCION_DEVC: TcxDBCurrencyEdit
                  Left = 230
                  Top = 114
                  DataBinding.DataField = 'TOTAL_RETENCION_DEVC'
                  DataBinding.DataSource = dsTablaG
                  Properties.DisplayFormat = '#,##0.00 '#8364
                  Properties.ReadOnly = True
                  TabOrder = 7
                  Width = 133
                end
                object lblTotalesTotalPagar: TcxLabel
                  Properties.Alignment.Vert = taVCenter
                  Properties.Alignment.Horz = taRightJustify
                  Width = 206
                  Height = 24
                  AutoSize = False
                  Left = 16
                  Top = 146
                  Caption = 'Total a pagar'
                  TabOrder = 8
                  Transparent = True
                end
                object curTotalesTOTAL_LIQUIDO_DEVC: TcxDBCurrencyEdit
                  Left = 230
                  Top = 146
                  DataBinding.DataField = 'TOTAL_LIQUIDO_DEVC'
                  DataBinding.DataSource = dsTablaG
                  Properties.DisplayFormat = '#,##0.00 '#8364
                  Properties.ReadOnly = True
                  Properties.UseThousandSeparator = True
                  TabOrder = 9
                  Width = 133
                end
                object lblTotalesFormaPago: TcxLabel
                  Properties.Alignment.Vert = taVCenter
                  Properties.Alignment.Horz = taRightJustify
                  Width = 206
                  Height = 24
                  AutoSize = False
                  Left = 16
                  Top = 178
                  Caption = 'Forma de Pago'
                  TabOrder = 10
                  Transparent = True
                end
                object txtTotalesFORMA_PAGO_DEVC: TcxDBTextEdit
                  Left = 230
                  Top = 178
                  DataBinding.DataField = 'FORMA_PAGO_DEVC'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 11
                  Width = 133
                end
                object chkTotalesESIVA_RECARGO_COMPRAS_DEVC: TcxDBCheckBox
                  Left = 56
                  Top = 210
                  Caption = 'Recargo equivalencia compras'
                  DataBinding.DataField = 'ESIVA_RECARGO_COMPRAS_DEVC'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  Properties.ValueChecked = 'S'
                  Properties.ValueUnchecked = 'N'
                  Style.TransparentBorder = False
                  TabOrder = 12
                  Transparent = True
                end
                object lblTotalesDtoComercial: TcxLabel
                  Properties.Alignment.Vert = taVCenter
                  Properties.Alignment.Horz = taRightJustify
                  Width = 162
                  Height = 24
                  AutoSize = False
                  Left = 16
                  Top = 240
                  Caption = 'Dto. comercial'
                  TabOrder = 13
                  Transparent = True
                end
                object spnTotalesPORCENTAJE_DTO_COMERCIAL_DEVC: TcxDBSpinEdit
                  Left = 185
                  Top = 240
                  DataBinding.DataField = 'PORCENTAJE_DTO_COMERCIAL_DEVC'
                  DataBinding.DataSource = dsTablaG
                  Properties.AssignedValues.MinValue = True
                  Properties.DisplayFormat = '0.00 %'
                  Properties.EditFormat = '0.00 %'
                  Properties.MaxValue = 100.000000000000000000
                  TabOrder = 14
                  Width = 86
                end
                object curTotalesTOTAL_DTO_COMERCIAL_DEVC: TcxDBCurrencyEdit
                  Left = 272
                  Top = 240
                  DataBinding.DataField = 'TOTAL_DTO_COMERCIAL_DEVC'
                  DataBinding.DataSource = dsTablaG
                  Properties.DisplayFormat = '#,##0.00 '#8364
                  Properties.ReadOnly = True
                  TabOrder = 15
                  Width = 91
                end
                object lblTotalesDtoFinanciero: TcxLabel
                  Properties.Alignment.Vert = taVCenter
                  Properties.Alignment.Horz = taRightJustify
                  Width = 162
                  Height = 24
                  AutoSize = False
                  Left = 16
                  Top = 270
                  Caption = 'Dto. financiero'
                  TabOrder = 16
                  Transparent = True
                end
                object spnTotalesPORCENTAJE_DTO_FINANCIERO_DEVC: TcxDBSpinEdit
                  Left = 185
                  Top = 270
                  DataBinding.DataField = 'PORCENTAJE_DTO_FINANCIERO_DEVC'
                  DataBinding.DataSource = dsTablaG
                  Properties.AssignedValues.MinValue = True
                  Properties.DisplayFormat = '0.00 %'
                  Properties.EditFormat = '0.00 %'
                  Properties.MaxValue = 100.000000000000000000
                  TabOrder = 17
                  Width = 86
                end
                object curTotalesTOTAL_DTO_FINANCIERO_DEVC: TcxDBCurrencyEdit
                  Left = 272
                  Top = 270
                  DataBinding.DataField = 'TOTAL_DTO_FINANCIERO_DEVC'
                  DataBinding.DataSource = dsTablaG
                  Properties.DisplayFormat = '#,##0.00 '#8364
                  Properties.ReadOnly = True
                  TabOrder = 18
                  Width = 91
                end
                object grpDesgloseImpuestos: TcxGroupBox
                  Left = 360
                  Top = 10
                  Width = 565
                  Height = 280
                  Caption = 'Desglose Impuestos'
                  TabOrder = 21
                  object shpSeparador1: TShape
                    Left = 12
                    Top = 32
                    Width = 550
                    Height = 40
                    Brush.Style = bsClear
                  end
                  object shpSeparador2: TShape
                    Left = 12
                    Top = 72
                    Width = 550
                    Height = 48
                    Brush.Style = bsClear
                  end
                  object shpSeparador3: TShape
                    Left = 12
                    Top = 168
                    Width = 550
                    Height = 48
                    Brush.Style = bsClear
                  end
                  object shpSeparador4: TShape
                    Left = 12
                    Top = 120
                    Width = 550
                    Height = 48
                    Brush.Style = bsClear
                  end
                  object shpSeparador5: TShape
                    Left = 12
                    Top = 216
                    Width = 550
                    Height = 48
                    Brush.Style = bsClear
                  end
                  object lblTotalesTotalRe: TcxLabel
                    Properties.Alignment.Vert = taVCenter
                    Properties.Alignment.Horz = taCenter
                    AutoSize = False
                    Height = 24
                    Width = 96
                    Left = 466
                    Top = 40
                    Caption = 'Total R.E.'
                    TabOrder = 0
                    Transparent = True
                  end
                  object lblTotalesPorRe: TcxLabel
                    Properties.Alignment.Vert = taVCenter
                    Properties.Alignment.Horz = taCenter
                    AutoSize = False
                    Height = 24
                    Width = 75
                    Left = 388
                    Top = 40
                    Caption = '%R.E.'
                    TabOrder = 1
                    Transparent = True
                  end
                  object lblTotalesTotalIva: TcxLabel
                    Properties.Alignment.Vert = taVCenter
                    Properties.Alignment.Horz = taCenter
                    AutoSize = False
                    Height = 24
                    Width = 86
                    Left = 296
                    Top = 40
                    Caption = 'Total IVA'
                    TabOrder = 2
                    Transparent = True
                  end
                  object lblTotalesPorIva: TcxLabel
                    Properties.Alignment.Vert = taVCenter
                    Properties.Alignment.Horz = taCenter
                    AutoSize = False
                    Height = 24
                    Width = 55
                    Left = 238
                    Top = 40
                    Caption = '%IVA'
                    TabOrder = 3
                    Transparent = True
                  end
                  object lblTotalesBaseNeta: TcxLabel
                    Properties.Alignment.Vert = taVCenter
                    Properties.Alignment.Horz = taCenter
                    AutoSize = False
                    Height = 24
                    Width = 92
                    Left = 145
                    Top = 40
                    Caption = 'BaseNeta'
                    TabOrder = 4
                    Transparent = True
                  end
                  object lblTotalesIVAN: TcxLabel
                    Properties.Alignment.Vert = taVCenter
                    AutoSize = False
                    Height = 24
                    Width = 120
                    Left = 20
                    Top = 80
                    Caption = 'Normal'
                    TabOrder = 5
                    Transparent = True
                  end
                  object curTotalesTOTAL_BASEI_IVAN_DEVC: TcxDBCurrencyEdit
                    Left = 145
                    Top = 80
                    DataBinding.DataField = 'TOTAL_BASEI_IVAN_DEVC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 9
                    Width = 92
                  end
                  object spnTotalesPORCENTAJE_IVAN_DEVC: TcxDBSpinEdit
                    Left = 238
                    Top = 80
                    DataBinding.DataField = 'PORCENTAJE_IVAN_DEVC'
                    DataBinding.DataSource = dsTablaG
                    Properties.AssignedValues.MinValue = True
                    Properties.DisplayFormat = '0 %'
                    Properties.EditFormat = '0 %'
                    Properties.MaxValue = 100.000000000000000000
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 21
                    Width = 55
                  end
                  object curTotalesTOTAL_IVAN_DEVC: TcxDBCurrencyEdit
                    Left = 296
                    Top = 80
                    DataBinding.DataField = 'TOTAL_IVAN_DEVC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 13
                    Width = 86
                  end
                  object spnTotalesPORCENTAJE_REN_DEVC: TcxDBSpinEdit
                    Left = 388
                    Top = 80
                    DataBinding.DataField = 'PORCENTAJE_REN_DEVC'
                    DataBinding.DataSource = dsTablaG
                    Properties.AssignedValues.MinValue = True
                    Properties.DisplayFormat = '0.00 %'
                    Properties.EditFormat = '0.00 %'
                    Properties.MaxValue = 100.000000000000000000
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 25
                    Width = 75
                  end
                  object curTotalesTOTAL_REN_DEVC: TcxDBCurrencyEdit
                    Left = 466
                    Top = 80
                    DataBinding.DataField = 'TOTAL_REN_DEVC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 17
                    Width = 96
                  end
                  object lblTotalesIVAR: TcxLabel
                    Properties.Alignment.Vert = taVCenter
                    AutoSize = False
                    Height = 24
                    Width = 120
                    Left = 20
                    Top = 128
                    Caption = 'Reducido'
                    TabOrder = 6
                    Transparent = True
                  end
                  object curTotalesTOTAL_BASEI_IVAR_DEVC: TcxDBCurrencyEdit
                    Left = 145
                    Top = 128
                    DataBinding.DataField = 'TOTAL_BASEI_IVAR_DEVC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 10
                    Width = 92
                  end
                  object spnTotalesPORCENTAJE_IVAR_DEVC: TcxDBSpinEdit
                    Left = 238
                    Top = 128
                    DataBinding.DataField = 'PORCENTAJE_IVAR_DEVC'
                    DataBinding.DataSource = dsTablaG
                    Properties.AssignedValues.MinValue = True
                    Properties.DisplayFormat = '0 %'
                    Properties.EditFormat = '0 %'
                    Properties.MaxValue = 100.000000000000000000
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 22
                    Width = 55
                  end
                  object curTotalesTOTAL_IVAR_DEVC: TcxDBCurrencyEdit
                    Left = 296
                    Top = 128
                    DataBinding.DataField = 'TOTAL_IVAR_DEVC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 14
                    Width = 86
                  end
                  object spnTotalesPORCENTAJE_RER_DEVC: TcxDBSpinEdit
                    Left = 388
                    Top = 128
                    DataBinding.DataField = 'PORCENTAJE_RER_DEVC'
                    DataBinding.DataSource = dsTablaG
                    Properties.AssignedValues.MinValue = True
                    Properties.DisplayFormat = '0.00 %'
                    Properties.EditFormat = '0.00 %'
                    Properties.MaxValue = 100.000000000000000000
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 26
                    Width = 75
                  end
                  object curTotalesTOTAL_RER_DEVC: TcxDBCurrencyEdit
                    Left = 466
                    Top = 128
                    DataBinding.DataField = 'TOTAL_RER_DEVC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 18
                    Width = 96
                  end
                  object lblTotalesIVAS: TcxLabel
                    Properties.Alignment.Vert = taVCenter
                    AutoSize = False
                    Height = 24
                    Width = 120
                    Left = 20
                    Top = 176
                    Caption = 'S'#250'per Reducido'
                    TabOrder = 7
                    Transparent = True
                  end
                  object curTotalesTOTAL_BASEI_IVAS_DEVC: TcxDBCurrencyEdit
                    Left = 145
                    Top = 176
                    DataBinding.DataField = 'TOTAL_BASEI_IVAS_DEVC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 11
                    Width = 92
                  end
                  object spnTotalesPORCENTAJE_IVAS_DEVC: TcxDBSpinEdit
                    Left = 238
                    Top = 176
                    DataBinding.DataField = 'PORCENTAJE_IVAS_DEVC'
                    DataBinding.DataSource = dsTablaG
                    Properties.AssignedValues.MinValue = True
                    Properties.DisplayFormat = '0 %'
                    Properties.EditFormat = '0 %'
                    Properties.MaxValue = 100.000000000000000000
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 23
                    Width = 55
                  end
                  object curTotalesTOTAL_IVAS_DEVC: TcxDBCurrencyEdit
                    Left = 296
                    Top = 176
                    DataBinding.DataField = 'TOTAL_IVAS_DEVC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 15
                    Width = 86
                  end
                  object spnTotalesPORCENTAJE_RES_DEVC: TcxDBSpinEdit
                    Left = 388
                    Top = 176
                    DataBinding.DataField = 'PORCENTAJE_RES_DEVC'
                    DataBinding.DataSource = dsTablaG
                    Properties.AssignedValues.MinValue = True
                    Properties.DisplayFormat = '0.00 %'
                    Properties.EditFormat = '0.00 %'
                    Properties.MaxValue = 100.000000000000000000
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 27
                    Width = 75
                  end
                  object curTotalesTOTAL_RES_DEVC: TcxDBCurrencyEdit
                    Left = 466
                    Top = 176
                    DataBinding.DataField = 'TOTAL_RES_DEVC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 19
                    Width = 96
                  end
                  object lblTotalesIVAE: TcxLabel
                    Properties.Alignment.Vert = taVCenter
                    AutoSize = False
                    Height = 24
                    Width = 120
                    Left = 20
                    Top = 224
                    Caption = 'Exento'
                    TabOrder = 8
                    Transparent = True
                  end
                  object curTotalesTOTAL_BASEI_IVAE_DEVC: TcxDBCurrencyEdit
                    Left = 145
                    Top = 224
                    DataBinding.DataField = 'TOTAL_BASEI_IVAE_DEVC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 12
                    Width = 92
                  end
                  object spnTotalesPORCENTAJE_IVAE_DEVC: TcxDBSpinEdit
                    Left = 238
                    Top = 224
                    DataBinding.DataField = 'PORCENTAJE_IVAE_DEVC'
                    DataBinding.DataSource = dsTablaG
                    Properties.AssignedValues.MinValue = True
                    Properties.DisplayFormat = '0 %'
                    Properties.EditFormat = '0 %'
                    Properties.MaxValue = 100.000000000000000000
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 24
                    Width = 55
                  end
                  object curTotalesTOTAL_IVAE_DEVC: TcxDBCurrencyEdit
                    Left = 296
                    Top = 224
                    DataBinding.DataField = 'TOTAL_IVAE_DEVC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 16
                    Width = 86
                  end
                  object spnTotalesPORCENTAJE_REE_DEVC: TcxDBSpinEdit
                    Left = 388
                    Top = 224
                    DataBinding.DataField = 'PORCENTAJE_REE_DEVC'
                    DataBinding.DataSource = dsTablaG
                    Properties.AssignedValues.MinValue = True
                    Properties.DisplayFormat = '0.00 %'
                    Properties.EditFormat = '0.00 %'
                    Properties.MaxValue = 100.000000000000000000
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 28
                    Width = 75
                  end
                  object curTotalesTOTAL_REE_DEVC: TcxDBCurrencyEdit
                    Left = 466
                    Top = 224
                    DataBinding.DataField = 'TOTAL_REE_DEVC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 20
                    Width = 96
                  end
                end
              end
            end
            object tsProveedor: TcxTabSheet
              Caption = '&3_Movimientos'
              object cxgrdMovimientosProveedor: TcxGrid
                Left = 0
                Top = 0
                Width = 929
                Height = 347
                Align = alClient
                TabOrder = 0
                object tvMovimientosProveedor: TcxGridDBTableView
                  OptionsData.Editing = False
                  OptionsView.GroupByBox = False
                  object colMovProvDevcNUMERO_MOV: TcxGridDBColumn
                    Caption = 'N'#250'mero Mov.'
                    DataBinding.FieldName = 'NUMERO_MOV'
                    Width = 110
                  end
                  object colMovProvDevcFECHA_MOV: TcxGridDBColumn
                    Caption = 'Fecha'
                    DataBinding.FieldName = 'FECHA_MOV'
                    Width = 130
                  end
                  object colMovProvDevcLINEA_MOV: TcxGridDBColumn
                    Caption = 'L'#237'nea'
                    DataBinding.FieldName = 'LINEA_MOV'
                    Width = 60
                  end
                  object colMovProvDevcALMACEN: TcxGridDBColumn
                    Caption = 'Almac'#233'n'
                    DataBinding.FieldName = 'NOMBRE_ALMACEN_ORIGEN'
                    Width = 140
                  end
                  object colMovProvDevcARTICULO: TcxGridDBColumn
                    Caption = 'Art'#237'culo'
                    DataBinding.FieldName = 'CODIGO_ART_MOV'
                    Width = 100
                  end
                  object colMovProvDevcSKU: TcxGridDBColumn
                    Caption = 'SKU'
                    DataBinding.FieldName = 'CODIGO_UNIDAD_MOV'
                    Width = 140
                  end
                  object colMovProvDevcDESCRIPCION: TcxGridDBColumn
                    Caption = 'Descripci'#243'n'
                    DataBinding.FieldName = 'DESCRIPCION_ARTICULO_MOV'
                    Width = 220
                  end
                  object colMovProvDevcTIPO: TcxGridDBColumn
                    Caption = 'Tipo'
                    DataBinding.FieldName = 'TIPO_MOV'
                    Width = 50
                  end
                  object colMovProvDevcCANTIDAD: TcxGridDBColumn
                    Caption = 'Cantidad'
                    DataBinding.FieldName = 'CANTIDAD_MOV'
                    Width = 90
                  end
                  object colMovProvDevcPMP: TcxGridDBColumn
                    Caption = 'PMP'
                    DataBinding.FieldName = 'PRECIO_MEDIO_MOV'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Width = 90
                  end
                  object colMovProvDevcTOTAL: TcxGridDBColumn
                    Caption = 'Total coste'
                    DataBinding.FieldName = 'TOTAL_COSTE_MOV'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Width = 100
                  end
                end
                object cxgrdlvlMovimientosProveedor: TcxGridLevel
                  GridView = tvMovimientosProveedor
                end
              end
            end
            object tsObservaciones: TcxTabSheet
              Caption = '&4_Observaciones'
              object memObservaciones: TcxDBMemo
                Left = 0
                Top = 0
                Align = alClient
                DataBinding.DataField = 'OBSERVACIONES_DEVC'
                DataBinding.DataSource = dsTablaG
                TabOrder = 0
                Height = 347
                Width = 929
              end
            end
          end
        end
        object pnlBottomTotales: TPanel
          Left = 0
          Top = 617
          Width = 937
          Height = 76
          Align = alBottom
          BevelOuter = bvNone
          TabOrder = 3
          object lblTotalBases: TcxLabel
            Left = 16
            Top = 8
            Caption = 'Total bases'
            TabOrder = 0
            Transparent = True
          end
          object curTOTAL_BASES_DEVC: TcxDBCurrencyEdit
            Left = 16
            Top = 32
            DataBinding.DataField = 'TOTAL_BASES_DEVC'
            DataBinding.DataSource = dsTablaG
            Properties.DisplayFormat = '#,##0.00 '#8364
            Properties.ReadOnly = True
            TabOrder = 1
            Width = 140
          end
          object lblTotalImpuestos: TcxLabel
            Left = 176
            Top = 8
            Caption = 'Total impuestos'
            TabOrder = 2
            Transparent = True
          end
          object curTOTAL_IMPUESTOS_DEVC: TcxDBCurrencyEdit
            Left = 176
            Top = 32
            DataBinding.DataField = 'TOTAL_IMPUESTOS_DEVC'
            DataBinding.DataSource = dsTablaG
            Properties.DisplayFormat = '#,##0.00 '#8364
            Properties.ReadOnly = True
            TabOrder = 3
            Width = 140
          end
          object lblTotalLiquido: TcxLabel
            Left = 336
            Top = 8
            Caption = 'Total l'#237'quido'
            TabOrder = 4
            Transparent = True
          end
          object curTOTAL_LIQUIDO_DEVC: TcxDBCurrencyEdit
            Left = 336
            Top = 32
            DataBinding.DataField = 'TOTAL_LIQUIDO_DEVC'
            DataBinding.DataSource = dsTablaG
            Properties.DisplayFormat = '#,##0.00 '#8364
            Properties.ReadOnly = True
            TabOrder = 5
            Width = 160
          end
        end
      end
      inherited tsPerfil: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 28
        ExplicitWidth = 937
        ExplicitHeight = 693
        inherited pnlPerfilTop: TPanel
          Width = 937
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 937
          inherited edtPerfilBusq: TcxTextEdit
            ExplicitHeight = 25
          end
        end
        inherited pnlPerfilDetail: TPanel
          Width = 937
          Height = 636
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 937
          ExplicitHeight = 636
          inherited cxgrdPerfil: TcxGrid
            Width = 937
            Height = 636
            ExplicitWidth = 937
            ExplicitHeight = 636
          end
        end
      end
    end
    inherited pnlTopPage: TPanel
      Width = 945
      StyleElements = [seFont, seClient, seBorder]
      ExplicitWidth = 945
      inherited pnlTopGrid: TPanel
        Width = 945
        StyleElements = [seFont, seClient, seBorder]
        ExplicitWidth = 945
        inherited edtBusqGlobal: TcxTextEdit
          ExplicitHeight = 25
        end
      end
    end
  end
  inherited pButtonRightBar: TPanel
    Left = 945
    Height = 765
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 945
    ExplicitHeight = 765
    inherited pButtonGen: TPanel
      Top = 567
      StyleElements = [seFont, seClient, seBorder]
      ExplicitTop = 567
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
    object btnImprimirH: TcxButton
      Left = 0
      Top = 307
      Width = 137
      Height = 48
      Caption = 'Imprimir hor.'
      TabOrder = 2
      OnClick = btnImprimirHClick
    end
    object btnImprimirV: TcxButton
      Left = 0
      Top = 254
      Width = 137
      Height = 46
      Caption = 'Imprimir vert.'
      TabOrder = 3
      OnClick = btnImprimirVClick
    end
    object btnPegatinas: TcxButton
      Left = 0
      Top = 204
      Width = 137
      Height = 43
      Caption = 'Etiquetas'
      TabOrder = 4
      OnClick = btnPegatinasClick
    end
  end
  object ActionList1: TActionList
    Left = 528
    Top = 368
    object actArticulos: TAction
      Caption = 'actArticulos'
      ShortCut = 16466
      OnExecute = actArticulosExecute
    end
    object actIrProveedor: TAction
      Caption = 'Ir a proveedor'
      ShortCut = 16464
      OnExecute = actIrProveedorExecute
    end
  end
end
