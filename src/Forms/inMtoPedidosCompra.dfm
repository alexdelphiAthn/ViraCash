inherited frmMtoPedidosCompra: TfrmMtoPedidosCompra
  Caption = 'Mantenimiento de Pedidos de Compra'
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
            object dbcGrdPedcCODIGO_ALM_PEDC: TcxGridDBColumn
              Caption = 'Almac'#233'n'
              DataBinding.FieldName = 'CODIGO_ALM_PEDC'
              Width = 100
            end
            object dbcGrdPedcSERIE_PEDC: TcxGridDBColumn
              Caption = 'Serie'
              DataBinding.FieldName = 'SERIE_PEDC'
              Width = 80
            end
            object dbcGrdPedcNUMERO_PEDC: TcxGridDBColumn
              Caption = 'N'#250'mero'
              DataBinding.FieldName = 'NUMERO_PEDC'
              Width = 90
            end
            object dbcGrdPedcESTADO_PEDC: TcxGridDBColumn
              Caption = 'Estado'
              DataBinding.FieldName = 'ESTADO_PEDC'
              Width = 110
            end
            object dbcGrdPedcFECHA_PEDC: TcxGridDBColumn
              Caption = 'Fecha'
              DataBinding.FieldName = 'FECHA_PEDC'
              Width = 100
            end
            object dbcGrdPedcCODIGO_PRV_PEDC: TcxGridDBColumn
              Caption = 'Proveedor'
              DataBinding.FieldName = 'CODIGO_PRV_PEDC'
              Width = 100
            end
            object dbcGrdPedcRSPRV_PEDC: TcxGridDBColumn
              Caption = 'Raz'#243'n Social Proveedor'
              DataBinding.FieldName = 'RAZON_SOCIAL_PRV_PEDC'
              Width = 220
            end
            object dbcGrdPedcTEMPORADA_PEDC: TcxGridDBColumn
              Caption = 'Temporada'
              DataBinding.FieldName = 'TEMPORADA_PEDC'
              Width = 120
            end
            object dbcGrdPedcREF_PROVEEDOR_PEDC: TcxGridDBColumn
              Caption = 'Ref. proveedor'
              DataBinding.FieldName = 'REF_PROVEEDOR_PEDC'
              Width = 130
            end
            object dbcGrdPedcFECHA_EFECTO_STOCK_PEDC: TcxGridDBColumn
              Caption = 'F.stock'
              DataBinding.FieldName = 'FECHA_EFECTO_STOCK_PEDC'
              Width = 100
            end
            object dbcGrdPedcFECHA_TOPE_RECEPCION_PEDC: TcxGridDBColumn
              Caption = 'F.tope recep.'
              DataBinding.FieldName = 'FECHA_TOPE_RECEPCION_PEDC'
              Width = 110
            end
            object dbcGrdPedcFECHA_PREVISTA_PEDC: TcxGridDBColumn
              Caption = 'F.prevista'
              DataBinding.FieldName = 'FECHA_PREVISTA_PEDC'
              Width = 100
            end
            object dbcGrdPedcTOTAL_LINEAS_PEDC: TcxGridDBColumn
              Caption = 'Neto lineas'
              DataBinding.FieldName = 'TOTAL_LINEAS_PEDC'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 110
            end
            object dbcGrdPedcTOTAL_LIQUIDO_PEDC: TcxGridDBColumn
              Caption = 'Total l'#237'quido'
              DataBinding.FieldName = 'TOTAL_LIQUIDO_PEDC'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 120
            end
            object dbcGrdPedcTOTAL_PRENDAS_PEDC: TcxGridDBColumn
              Caption = 'Prendas'
              DataBinding.FieldName = 'TOTAL_PRENDAS_PEDC'
              Width = 90
            end
            object dbcGrdPedcCANTIDAD_PEDIDA_PEDC: TcxGridDBColumn
              Caption = 'Pedidas'
              DataBinding.FieldName = 'CANTIDAD_PEDIDA_PEDC'
              Width = 90
            end
            object dbcGrdPedcCANTIDAD_RECIBIDA_PEDC: TcxGridDBColumn
              Caption = 'Recibidas'
              DataBinding.FieldName = 'CANTIDAD_RECIBIDA_PEDC'
              Width = 90
            end
            object dbcGrdPedcCANTIDAD_PENDIENTE_RECEPCION_PEDC: TcxGridDBColumn
              Caption = 'Pte. recibir'
              DataBinding.FieldName = 'CANTIDAD_PENDIENTE_RECEPCION_PEDC'
              Width = 95
            end
            object dbcGrdPedcCODIGO_EMP_PEDC: TcxGridDBColumn
              Caption = 'Empresa'
              DataBinding.FieldName = 'CODIGO_EMP_PEDC'
              Width = 100
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
          Height = 177
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          object pcCab: TcxPageControl
            Left = 0
            Top = 0
            Width = 937
            Height = 177
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsCabecera
            Properties.CustomButtons.Buttons = <>
            ExplicitHeight = 161
            ClientRectBottom = 173
            ClientRectLeft = 4
            ClientRectRight = 933
            ClientRectTop = 28
            object tsCabecera: TcxTabSheet
              Caption = 'Cabecera'
              object lblNroPedido: TcxLabel
                Left = 8
                Top = 12
                Caption = 'N'#250'mero'
                TabOrder = 0
                Transparent = True
              end
              object txtNUMERO_PEDC: TcxDBTextEdit
                Left = 8
                Top = 32
                DataBinding.DataField = 'NUMERO_PEDC'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 1
                Width = 100
              end
              object lblSeriePedido: TcxLabel
                Left = 116
                Top = 12
                Caption = 'Serie'
                TabOrder = 2
                Transparent = True
              end
              object cbbSERIE_PEDC: TcxDBComboBox
                Left = 116
                Top = 32
                DataBinding.DataField = 'SERIE_PEDC'
                DataBinding.DataSource = dsTablaG
                Properties.MaxLength = 12
                Properties.OnInitPopup = cbbSERIE_PEDCPropertiesInitPopup
                TabOrder = 3
                Width = 80
              end
              object lblFechaPedido: TcxLabel
                Left = 204
                Top = 12
                Caption = 'Fecha'
                TabOrder = 4
                Transparent = True
              end
              object dteFECHA_PEDC: TcxDBDateEdit
                Left = 204
                Top = 32
                DataBinding.DataField = 'FECHA_PEDC'
                DataBinding.DataSource = dsTablaG
                TabOrder = 5
                Width = 110
              end
              object lblFechaPrevista: TcxLabel
                Left = 320
                Top = 12
                Caption = 'F.prevista'
                TabOrder = 6
                Transparent = True
              end
              object dteFECHA_PREVISTA_PEDC: TcxDBDateEdit
                Left = 320
                Top = 32
                DataBinding.DataField = 'FECHA_PREVISTA_PEDC'
                DataBinding.DataSource = dsTablaG
                TabOrder = 7
                Width = 110
              end
              object lblFechaTopeRecepcionPedc: TcxLabel
                Left = 756
                Top = 12
                Caption = 'F.tope recep.'
                TabOrder = 20
                Transparent = True
              end
              object dteFECHA_TOPE_RECEPCION_PEDC: TcxDBDateEdit
                Left = 756
                Top = 32
                DataBinding.DataField = 'FECHA_TOPE_RECEPCION_PEDC'
                DataBinding.DataSource = dsTablaG
                TabOrder = 21
                Width = 115
              end
              object lblEstadoPedido: TcxLabel
                Left = 436
                Top = 12
                Caption = 'Estado'
                TabOrder = 8
                Transparent = True
              end
              object txtESTADO_PEDC: TcxDBTextEdit
                Left = 436
                Top = 32
                DataBinding.DataField = 'ESTADO_PEDC'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 9
                Width = 110
              end
              object lblCodigoEmpresa: TcxLabel
                Left = 8
                Top = 72
                Caption = 'Empresa'
                TabOrder = 10
                Transparent = True
              end
              object btnCODIGO_EMP_PEDC: TcxDBButtonEdit
                Left = 8
                Top = 92
                DataBinding.DataField = 'CODIGO_EMP_PEDC'
                DataBinding.DataSource = dsTablaG
                Properties.Buttons = <
                  item
                    Default = True
                    Kind = bkEllipsis
                  end>
                Properties.OnButtonClick = btnCODIGO_EMP_PEDCPropertiesButtonClick
                Properties.OnEditValueChanged = btnCODIGO_EMP_PEDCPropertiesEditValueChanged
                TabOrder = 11
                OnKeyUp = btnCODIGO_EMP_PEDCKeyUp
                Width = 150
              end
              object lblCodigoProveedor: TcxLabel
                Left = 168
                Top = 72
                Caption = 'Proveedor'
                TabOrder = 12
                Transparent = True
              end
              object cbbCODIGO_PRV_PEDC: TcxDBLookupComboBox
                Left = 168
                Top = 92
                DataBinding.DataField = 'CODIGO_PRV_PEDC'
                DataBinding.DataSource = dsTablaG
                Properties.DropDownListStyle = lsEditList
                Properties.DropDownRows = 15
                Properties.DropDownWidth = 480
                Properties.KeyFieldNames = 'CODIGO_PRV_PRV'
                Properties.IncrementalFilteringOptions = [ifoHighlightSearchText, ifoUseContainsOperator]
                Properties.ListColumns = <
                  item
                    Caption = 'C'#243'digo'
                    Width = 110
                    FieldName = 'CODIGO_PRV_PRV'
                  end
                  item
                    Caption = 'Proveedor'
                    Width = 350
                    FieldName = 'PROVEEDOR_BUSQUEDA'
                  end>
                Properties.ListFieldIndex = 1
                Properties.ListOptions.CaseInsensitive = True
                TabOrder = 13
                OnKeyUp = cbbCODIGO_PRV_PEDCKeyUp
                Width = 150
              end
              object lblRefProveedor: TcxLabel
                Left = 328
                Top = 72
                Caption = 'Ref. proveedor'
                TabOrder = 14
                Transparent = True
              end
              object txtREF_PROVEEDOR_PEDC: TcxDBTextEdit
                Left = 328
                Top = 92
                DataBinding.DataField = 'REF_PROVEEDOR_PEDC'
                DataBinding.DataSource = dsTablaG
                TabOrder = 15
                Width = 180
              end
              object lblCodigoAlmacen: TcxLabel
                Left = 520
                Top = 72
                Caption = 'Almac'#233'n destino'
                TabOrder = 16
                Transparent = True
              end
              object cbbCODIGO_ALM_PEDC: TcxDBLookupComboBox
                Left = 520
                Top = 92
                DataBinding.DataField = 'CODIGO_ALM_PEDC'
                DataBinding.DataSource = dsTablaG
                Properties.DropDownListStyle = lsFixedList
                Properties.DropDownRows = 15
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
                  end
                  item
                    Caption = 'Empresa'
                    Width = 60
                    FieldName = 'CODIGO_EMP_ALM'
                  end>
                Properties.OnEditValueChanged = cbbCODIGO_ALM_PEDCPropertiesEditValueChanged
                TabOrder = 17
                Width = 120
              end
              object lblTemporada: TcxLabel
                Left = 568
                Top = 12
                Caption = 'Temporada'
                TabOrder = 18
                Transparent = True
              end
              object cbbTemporadaPedc: TcxDBLookupComboBox
                Left = 568
                Top = 32
                DataBinding.DataField = 'ID_PV_TEMPORADA_PEDC'
                DataBinding.DataSource = dsTablaG
                Properties.KeyFieldNames = 'ID_PV_ARTPROP'
                Properties.ListColumns = <
                  item
                    Caption = 'Temporada'
                    FieldName = 'PV'
                  end>
                Properties.ListOptions.ShowHeader = False
                TabOrder = 19
                Width = 180
              end
              object lblCabCantidadPedidaPedc: TcxLabel
                Left = 650
                Top = 72
                Caption = 'Pedida'
                TabOrder = 22
                Transparent = True
              end
              object curCabCANTIDAD_PEDIDA_PEDC: TcxDBCurrencyEdit
                Left = 650
                Top = 92
                TabStop = False
                DataBinding.DataField = 'CANTIDAD_PEDIDA_PEDC'
                DataBinding.DataSource = dsTablaG
                Properties.DecimalPlaces = 3
                Properties.DisplayFormat = '#,##0.###'
                Properties.ReadOnly = True
                TabOrder = 23
                Width = 68
              end
              object lblCabCantidadRecibidaPedc: TcxLabel
                Left = 722
                Top = 72
                Caption = 'Recibida'
                TabOrder = 24
                Transparent = True
              end
              object curCabCANTIDAD_RECIBIDA_PEDC: TcxDBCurrencyEdit
                Left = 722
                Top = 92
                TabStop = False
                DataBinding.DataField = 'CANTIDAD_RECIBIDA_PEDC'
                DataBinding.DataSource = dsTablaG
                Properties.DecimalPlaces = 3
                Properties.DisplayFormat = '#,##0.###'
                Properties.ReadOnly = True
                TabOrder = 25
                Width = 68
              end
              object lblCabCantidadPendientePedc: TcxLabel
                Left = 794
                Top = 72
                Caption = 'Pte. rec.'
                TabOrder = 26
                Transparent = True
              end
              object curCabCANTIDAD_PENDIENTE_RECEPCION_PEDC: TcxDBCurrencyEdit
                Left = 794
                Top = 92
                TabStop = False
                DataBinding.DataField = 'CANTIDAD_PENDIENTE_RECEPCION_PEDC'
                DataBinding.DataSource = dsTablaG
                Properties.DecimalPlaces = 3
                Properties.DisplayFormat = '#,##0.###'
                Properties.ReadOnly = True
                TabOrder = 27
                Width = 68
              end
              object lblCabCantidadAAlbaranarPedc: TcxLabel
                Left = 866
                Top = 72
                Caption = 'A alb.'
                TabOrder = 28
                Transparent = True
              end
              object curCabCANTIDAD_A_ALBARANAR_PEDC: TcxCurrencyEdit
                Left = 866
                Top = 92
                TabStop = False
                Properties.DecimalPlaces = 3
                Properties.DisplayFormat = '#,##0.###'
                Properties.ReadOnly = True
                TabOrder = 29
                Width = 64
              end
              object lblProveedorNombrePedc: TcxLabel
                Left = 168
                Top = 116
                ParentFont = False
                Style.Font.Charset = ANSI_CHARSET
                Style.Font.Color = clWindowText
                Style.Font.Height = -15
                Style.Font.Name = 'Source Sans 3'
                Style.Font.Style = [fsBold]
                Style.IsFontAssigned = True
                TabOrder = 30
                Transparent = True
              end
            end
          end
        end
        object splSplitterFicha: TcxSplitter
          Left = 0
          Top = 177
          Width = 937
          Height = 8
          Cursor = crSizeNS
          HotZoneClassName = 'TcxMediaPlayer9Style'
          HotZone.SizePercent = 50
          AlignSplitter = salTop
          Control = pnlTopFicha
          ExplicitWidth = 8
        end
        object pnlBotonesAcciones: TPanel
          Left = 0
          Top = 185
          Width = 937
          Height = 40
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 1
          ExplicitTop = 161
          object btnAnadirLinea: TcxButton
            Left = 12
            Top = 8
            Width = 110
            Height = 26
            Caption = 'A'#241'adir l'#237'nea'
            TabOrder = 0
            OnClick = btnAnadirLineaClick
          end
          object btnBorrarLinea: TcxButton
            Left = 128
            Top = 8
            Width = 110
            Height = 26
            Caption = 'Borrar l'#237'nea'
            TabOrder = 1
            OnClick = btnBorrarLineaClick
          end
          object btnRecibirFilaEntera: TcxButton
            Left = 558
            Top = 8
            Width = 162
            Height = 26
            Caption = 'Recibir fila'
            TabOrder = 5
            OnClick = btnRecibirFilaEnteraClick
          end
          object btnTallasHorizontal: TcxButton
            Left = 558
            Top = 8
            Width = 170
            Height = 26
            Caption = 'Tallas en horizontal'
            TabOrder = 4
            OnClick = btnTallasHorizontalClick
          end
          object btnExpandirRecibidos: TcxButton
            Left = 392
            Top = 8
            Width = 160
            Height = 26
            Caption = 'Expandir recibidos'
            TabOrder = 3
            OnClick = btnExpandirRecibidosClick
          end
          object btnRecibirTodo: TcxButton
            Left = 256
            Top = 8
            Width = 130
            Height = 26
            Caption = 'Recibir Todo'
            TabOrder = 2
            OnClick = btnRecibirTodoClick
          end
        end
        object pnlBodyFicha: TPanel
          Left = 0
          Top = 225
          Width = 937
          Height = 392
          Align = alClient
          BevelOuter = bvNone
          TabOrder = 2
          ExplicitTop = 201
          ExplicitHeight = 416
          object pcPedido: TcxPageControl
            Left = 0
            Top = 0
            Width = 937
            Height = 392
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsLineasPedido
            Properties.CustomButtons.Buttons = <>
            ExplicitHeight = 416
            ClientRectBottom = 388
            ClientRectLeft = 4
            ClientRectRight = 933
            ClientRectTop = 28
            object tsLineasPedido: TcxTabSheet
              Caption = 'L'#237'neas'
              ExplicitLeft = 0
              ExplicitTop = 0
              ExplicitWidth = 0
              ExplicitHeight = 384
              object lblCambioModoLineas: TcxLabel
                Left = 0
                Top = 0
                Width = 929
                Height = 26
                Align = alTop
                AutoSize = False
                Caption = 'F1 cambiar de modo'
                Hint = 'Seleccione Desglose para editar colores y tallas.'
                ParentShowHint = False
                ShowHint = True
                Style.Font.Style = [fsBold]
                Style.IsFontAssigned = True
                Properties.Alignment.Vert = taVCenter
              end
              object cxgrdLineasPedido: TcxGrid
                Left = 0
                Top = 26
                Width = 929
                Height = 342
                Align = alClient
                TabOrder = 0
                OnEnter = cxgrdLineasPedidoEnter
                OnExit = cxgrdLineasPedidoExit
                ExplicitHeight = 384
                object tvLineasPedido: TcxGridDBTableView
                  Navigator.Buttons.ConfirmDelete = True
                  Navigator.Visible = True
                  OnCustomDrawCell = tvLineasPedidoCustomDrawCell
                  OnEditing = tvLineasPedidoEditing
                  OnFocusedRecordChanged = tvLineasPedidoFocusedRecordChanged
                  OnInitEdit = tvLineasPedidoInitEdit
                  OptionsBehavior.FocusCellOnTab = True
                  OptionsBehavior.FocusFirstCellOnNewRecord = True
                  OptionsData.Appending = True
                  OptionsView.GroupByBox = False
                  object colLineaPedcLINEA: TcxGridDBColumn
                    Caption = 'L'#237'nea'
                    DataBinding.FieldName = 'LINEA_PEDCLIN'
                    Width = 75
                  end
                  object colLineaPedcCODIGO_ART: TcxGridDBColumn
                    Caption = 'Art'#237'culo'
                    DataBinding.FieldName = 'CODIGO_ART_PEDCLIN'
                    PropertiesClassName = 'TcxButtonEditProperties'
                    Properties.Buttons = <
                      item
                        Default = True
                        Kind = bkEllipsis
                      end>
                    Properties.OnButtonClick = colLineaPedcCODIGO_ARTPropertiesButtonClick
                    Properties.OnValidate = colLineaPedcCODIGO_ARTPropertiesValidate
                    Width = 220
                  end
                  object colLineaPedcCODIGO_UNIDAD: TcxGridDBColumn
                    Caption = 'SKU'
                    DataBinding.FieldName = 'CODIGO_UNIDAD_PEDCLIN'
                    Width = 120
                  end
                  object colLineaPedcREF_PRV: TcxGridDBColumn
                    Caption = 'Modelo prov.'
                    DataBinding.FieldName = 'REF_PRV_PEDCLIN'
                    Width = 100
                  end
                  object colLineaPedcDESCRIPCION: TcxGridDBColumn
                    Caption = 'Descripci'#243'n'
                    DataBinding.FieldName = 'DESCRIPCION_ARTICULO_PEDCLIN'
                    Width = 220
                  end
                  object colLineaPedcCANTIDAD: TcxGridDBColumn
                    Caption = 'Pedida'
                    DataBinding.FieldName = 'CANTIDAD_PEDCLIN'
                    Width = 80
                  end
                  object colLineaPedcRECIBIDA: TcxGridDBColumn
                    Caption = 'Recibida'
                    DataBinding.FieldName = 'CANTIDAD_RECIBIDA_PEDCLIN'
                    Options.Editing = False
                    Width = 80
                  end
                  object colLineaPedcARecibir: TcxGridDBColumn
                    Caption = 'A recibir'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = '#,##0.###'
                    Width = 90
                  end
                  object colLineaPedcPRECIO_COMPRA: TcxGridDBColumn
                    Caption = 'Precio compra'
                    DataBinding.FieldName = 'PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Width = 110
                  end
                  object colLineaPedcPORCENTAJE_IVA: TcxGridDBColumn
                    Caption = '% IVA'
                    DataBinding.FieldName = 'PORCENTAJE_IVA_PEDCLIN'
                    Width = 70
                  end
                  object colLineaPedcTOTAL: TcxGridDBColumn
                    Caption = 'Total'
                    DataBinding.FieldName = 'TOTAL_PEDCLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Width = 100
                  end
                  object colLineaPedcALMACEN: TcxGridDBColumn
                    Caption = 'Almac'#233'n'
                    DataBinding.FieldName = 'CODIGO_ALMACEN_PEDCLIN'
                    Width = 90
                  end
                end
                object cxgrdlvlLineasPedido: TcxGridLevel
                  GridView = tvLineasPedido
                end
              end
            end
            object tsTotales: TcxTabSheet
              Caption = '&2_Totales'
              ImageIndex = 2
              ExplicitHeight = 368
              object scrTotales: TcxScrollBox
                HorzScrollBar.Margin = 12
                VertScrollBar.Tracking = True
                VertScrollBar.Margin = 12
                AutoScroll = True
                Left = 0
                Top = 0
                Width = 929
                Height = 360
                Align = alClient
                BorderStyle = cxcbsNone
                TabOrder = 0
                ExplicitHeight = 368
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
                object curTotalesTOTAL_BASES_PEDC: TcxDBCurrencyEdit
                  Left = 230
                  Top = 18
                  DataBinding.DataField = 'TOTAL_BASES_PEDC'
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
                object curTotalesTOTAL_IMPUESTOS_PEDC: TcxDBCurrencyEdit
                  Left = 230
                  Top = 50
                  DataBinding.DataField = 'TOTAL_IMPUESTOS_PEDC'
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
                object spnTotalesPORCENTAJE_RETENCION_PEDC: TcxDBSpinEdit
                  Left = 230
                  Top = 82
                  DataBinding.DataField = 'PORCENTAJE_RETENCION_PEDC'
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
                object curTotalesTOTAL_RETENCION_PEDC: TcxDBCurrencyEdit
                  Left = 230
                  Top = 114
                  DataBinding.DataField = 'TOTAL_RETENCION_PEDC'
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
                object curTotalesTOTAL_LIQUIDO_PEDC: TcxDBCurrencyEdit
                  Left = 230
                  Top = 146
                  DataBinding.DataField = 'TOTAL_LIQUIDO_PEDC'
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
                object cbbTotalesFORMA_PAGO_PEDC: TcxDBLookupComboBox
                  Left = 230
                  Top = 178
                  DataBinding.DataField = 'FORMA_PAGO_PEDC'
                  DataBinding.DataSource = dsTablaG
                  Properties.DropDownSizeable = True
                  Properties.KeyFieldNames = 'CODIGO_FP_FP'
                  Properties.ListColumns = <
                    item
                      Caption = 'C'#243'digo'
                      MinWidth = 50
                      Width = 60
                      FieldName = 'CODIGO_FP_FP'
                    end
                    item
                      Caption = 'Descripci'#243'n'
                      MinWidth = 160
                      Width = 220
                      FieldName = 'DESCRIPCION_FORMA_PAGO_FP'
                    end>
                  Properties.ListOptions.CaseInsensitive = True
                  TabOrder = 11
                  Width = 133
                end
                object chkTotalesESIVA_RECARGO_COMPRAS_PEDC: TcxDBCheckBox
                  Left = 56
                  Top = 210
                  Caption = 'Recargo equivalencia compras'
                  DataBinding.DataField = 'ESIVA_RECARGO_COMPRAS_PEDC'
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
                object spnTotalesPORCENTAJE_DTO_COMERCIAL_PEDC: TcxDBSpinEdit
                  Left = 185
                  Top = 240
                  DataBinding.DataField = 'PORCENTAJE_DTO_COMERCIAL_PEDC'
                  DataBinding.DataSource = dsTablaG
                  Properties.AssignedValues.MinValue = True
                  Properties.DisplayFormat = '0.00 %'
                  Properties.EditFormat = '0.00 %'
                  Properties.MaxValue = 100.000000000000000000
                  TabOrder = 14
                  Width = 86
                end
                object curTotalesTOTAL_DTO_COMERCIAL_PEDC: TcxDBCurrencyEdit
                  Left = 272
                  Top = 240
                  DataBinding.DataField = 'TOTAL_DTO_COMERCIAL_PEDC'
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
                object spnTotalesPORCENTAJE_DTO_FINANCIERO_PEDC: TcxDBSpinEdit
                  Left = 185
                  Top = 270
                  DataBinding.DataField = 'PORCENTAJE_DTO_FINANCIERO_PEDC'
                  DataBinding.DataSource = dsTablaG
                  Properties.AssignedValues.MinValue = True
                  Properties.DisplayFormat = '0.00 %'
                  Properties.EditFormat = '0.00 %'
                  Properties.MaxValue = 100.000000000000000000
                  TabOrder = 17
                  Width = 86
                end
                object curTotalesTOTAL_DTO_FINANCIERO_PEDC: TcxDBCurrencyEdit
                  Left = 272
                  Top = 270
                  DataBinding.DataField = 'TOTAL_DTO_FINANCIERO_PEDC'
                  DataBinding.DataSource = dsTablaG
                  Properties.DisplayFormat = '#,##0.00 '#8364
                  Properties.ReadOnly = True
                  TabOrder = 18
                  Width = 91
                end
                object lblTotalesTotalPrendas: TcxLabel
                  Properties.Alignment.Vert = taVCenter
                  Properties.Alignment.Horz = taRightJustify
                  Width = 206
                  Height = 24
                  AutoSize = False
                  Left = 16
                  Top = 300
                  Caption = 'N'#186' de prendas'
                  TabOrder = 19
                  Transparent = True
                end
                object curTotalesTOTAL_PRENDAS_PEDC: TcxDBCurrencyEdit
                  Left = 230
                  Top = 300
                  DataBinding.DataField = 'TOTAL_PRENDAS_PEDC'
                  DataBinding.DataSource = dsTablaG
                  Properties.DecimalPlaces = 0
                  Properties.DisplayFormat = '#,##0'
                  Properties.ReadOnly = True
                  TabOrder = 20
                  Width = 133
                end
                object grpDesgloseImpuestos: TcxGroupBox
                  Left = 384
                  Top = 10
                  Width = 525
                  Height = 280
                  Caption = 'Desglose Impuestos'
                  TabOrder = 21
                  object shpSeparador1: TShape
                    Left = 12
                    Top = 32
                    Width = 512
                    Height = 40
                    Brush.Style = bsClear
                  end
                  object shpSeparador2: TShape
                    Left = 12
                    Top = 72
                    Width = 512
                    Height = 48
                    Brush.Style = bsClear
                  end
                  object shpSeparador3: TShape
                    Left = 12
                    Top = 168
                    Width = 512
                    Height = 48
                    Brush.Style = bsClear
                  end
                  object shpSeparador4: TShape
                    Left = 12
                    Top = 120
                    Width = 512
                    Height = 48
                    Brush.Style = bsClear
                  end
                  object shpSeparador5: TShape
                    Left = 12
                    Top = 216
                    Width = 512
                    Height = 48
                    Brush.Style = bsClear
                  end
                  object lblTotalesTotalRe: TcxLabel
                    Properties.Alignment.Vert = taVCenter
                    Properties.Alignment.Horz = taCenter
                    AutoSize = False
                    Height = 24
                    Width = 75
                    Left = 442
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
                    Width = 53
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
                  object curTotalesTOTAL_BASEI_IVAN_PEDC: TcxDBCurrencyEdit
                    Left = 145
                    Top = 80
                    DataBinding.DataField = 'TOTAL_BASEI_IVAN_PEDC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 9
                    Width = 92
                  end
                  object spnTotalesPORCENTAJE_IVAN_PEDC: TcxDBSpinEdit
                    Left = 238
                    Top = 80
                    DataBinding.DataField = 'PORCENTAJE_IVAN_PEDC'
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
                  object curTotalesTOTAL_IVAN_PEDC: TcxDBCurrencyEdit
                    Left = 296
                    Top = 80
                    DataBinding.DataField = 'TOTAL_IVAN_PEDC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 13
                    Width = 86
                  end
                  object spnTotalesPORCENTAJE_REN_PEDC: TcxDBSpinEdit
                    Left = 388
                    Top = 80
                    DataBinding.DataField = 'PORCENTAJE_REN_PEDC'
                    DataBinding.DataSource = dsTablaG
                    Properties.AssignedValues.MinValue = True
                    Properties.DisplayFormat = '0.00 %'
                    Properties.EditFormat = '0.00 %'
                    Properties.MaxValue = 100.000000000000000000
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 25
                    Width = 53
                  end
                  object curTotalesTOTAL_REN_PEDC: TcxDBCurrencyEdit
                    Left = 442
                    Top = 80
                    DataBinding.DataField = 'TOTAL_REN_PEDC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 17
                    Width = 75
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
                  object curTotalesTOTAL_BASEI_IVAR_PEDC: TcxDBCurrencyEdit
                    Left = 145
                    Top = 128
                    DataBinding.DataField = 'TOTAL_BASEI_IVAR_PEDC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 10
                    Width = 92
                  end
                  object spnTotalesPORCENTAJE_IVAR_PEDC: TcxDBSpinEdit
                    Left = 238
                    Top = 128
                    DataBinding.DataField = 'PORCENTAJE_IVAR_PEDC'
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
                  object curTotalesTOTAL_IVAR_PEDC: TcxDBCurrencyEdit
                    Left = 296
                    Top = 128
                    DataBinding.DataField = 'TOTAL_IVAR_PEDC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 14
                    Width = 86
                  end
                  object spnTotalesPORCENTAJE_RER_PEDC: TcxDBSpinEdit
                    Left = 388
                    Top = 128
                    DataBinding.DataField = 'PORCENTAJE_RER_PEDC'
                    DataBinding.DataSource = dsTablaG
                    Properties.AssignedValues.MinValue = True
                    Properties.DisplayFormat = '0.00 %'
                    Properties.EditFormat = '0.00 %'
                    Properties.MaxValue = 100.000000000000000000
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 26
                    Width = 53
                  end
                  object curTotalesTOTAL_RER_PEDC: TcxDBCurrencyEdit
                    Left = 442
                    Top = 128
                    DataBinding.DataField = 'TOTAL_RER_PEDC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 18
                    Width = 75
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
                  object curTotalesTOTAL_BASEI_IVAS_PEDC: TcxDBCurrencyEdit
                    Left = 145
                    Top = 176
                    DataBinding.DataField = 'TOTAL_BASEI_IVAS_PEDC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 11
                    Width = 92
                  end
                  object spnTotalesPORCENTAJE_IVAS_PEDC: TcxDBSpinEdit
                    Left = 238
                    Top = 176
                    DataBinding.DataField = 'PORCENTAJE_IVAS_PEDC'
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
                  object curTotalesTOTAL_IVAS_PEDC: TcxDBCurrencyEdit
                    Left = 296
                    Top = 176
                    DataBinding.DataField = 'TOTAL_IVAS_PEDC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 15
                    Width = 86
                  end
                  object spnTotalesPORCENTAJE_RES_PEDC: TcxDBSpinEdit
                    Left = 388
                    Top = 176
                    DataBinding.DataField = 'PORCENTAJE_RES_PEDC'
                    DataBinding.DataSource = dsTablaG
                    Properties.AssignedValues.MinValue = True
                    Properties.DisplayFormat = '0.00 %'
                    Properties.EditFormat = '0.00 %'
                    Properties.MaxValue = 100.000000000000000000
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 27
                    Width = 53
                  end
                  object curTotalesTOTAL_RES_PEDC: TcxDBCurrencyEdit
                    Left = 442
                    Top = 176
                    DataBinding.DataField = 'TOTAL_RES_PEDC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 19
                    Width = 75
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
                  object curTotalesTOTAL_BASEI_IVAE_PEDC: TcxDBCurrencyEdit
                    Left = 145
                    Top = 224
                    DataBinding.DataField = 'TOTAL_BASEI_IVAE_PEDC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 12
                    Width = 92
                  end
                  object spnTotalesPORCENTAJE_IVAE_PEDC: TcxDBSpinEdit
                    Left = 238
                    Top = 224
                    DataBinding.DataField = 'PORCENTAJE_IVAE_PEDC'
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
                  object curTotalesTOTAL_IVAE_PEDC: TcxDBCurrencyEdit
                    Left = 296
                    Top = 224
                    DataBinding.DataField = 'TOTAL_IVAE_PEDC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 16
                    Width = 86
                  end
                  object spnTotalesPORCENTAJE_REE_PEDC: TcxDBSpinEdit
                    Left = 388
                    Top = 224
                    DataBinding.DataField = 'PORCENTAJE_REE_PEDC'
                    DataBinding.DataSource = dsTablaG
                    Properties.AssignedValues.MinValue = True
                    Properties.DisplayFormat = '0.00 %'
                    Properties.EditFormat = '0.00 %'
                    Properties.MaxValue = 100.000000000000000000
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 28
                    Width = 53
                  end
                  object curTotalesTOTAL_REE_PEDC: TcxDBCurrencyEdit
                    Left = 442
                    Top = 224
                    DataBinding.DataField = 'TOTAL_REE_PEDC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 20
                    Width = 75
                  end
                end
              end
            end
            object tsObservaciones: TcxTabSheet
              Caption = 'Observaciones'
              ExplicitLeft = 0
              ExplicitTop = 0
              ExplicitWidth = 0
              ExplicitHeight = 384
              object memObservaciones: TcxDBMemo
                Left = 0
                Top = 0
                Align = alClient
                DataBinding.DataField = 'OBSERVACIONES_PEDC'
                DataBinding.DataSource = dsTablaG
                TabOrder = 0
                ExplicitHeight = 368
                Height = 360
                Width = 929
              end
            end
            object tsAlbaranesPedc: TcxTabSheet
              Caption = 'Albaranes'
              ExplicitLeft = 0
              ExplicitTop = 0
              ExplicitWidth = 0
              ExplicitHeight = 384
              object cxgrdAlbaranesPedc: TcxGrid
                Left = 0
                Top = 0
                Width = 744
                Height = 368
                Align = alClient
                TabOrder = 0
                ExplicitHeight = 384
                object tvAlbaranesPedc: TcxGridDBTableView
                  OptionsData.Deleting = False
                  OptionsData.Editing = False
                  OptionsData.Inserting = False
                  OptionsView.GroupByBox = False
                  object colAlbcPedcNUMERO: TcxGridDBColumn
                    Caption = 'N'#250'mero'
                    DataBinding.FieldName = 'NUMERO_ALBC'
                    Width = 90
                  end
                  object colAlbcPedcSERIE: TcxGridDBColumn
                    Caption = 'Serie'
                    DataBinding.FieldName = 'SERIE_ALBC'
                    Width = 80
                  end
                  object colAlbcPedcFECHA: TcxGridDBColumn
                    Caption = 'Fecha'
                    DataBinding.FieldName = 'FECHA_ALBC'
                    Width = 100
                  end
                  object colAlbcPedcESTADO: TcxGridDBColumn
                    Caption = 'Estado'
                    DataBinding.FieldName = 'ESTADO_ALBC'
                    Width = 100
                  end
                  object colAlbcPedcREFPRV: TcxGridDBColumn
                    Caption = 'Modelo prov.'
                    DataBinding.FieldName = 'REF_PROVEEDOR_ALBC'
                    Width = 140
                  end
                  object colAlbcPedcTOTAL: TcxGridDBColumn
                    Caption = 'Total'
                    DataBinding.FieldName = 'TOTAL_LIQUIDO_ALBC'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Width = 110
                  end
                end
                object cxgrdlvlAlbaranesPedc: TcxGridLevel
                  GridView = tvAlbaranesPedc
                end
              end
              object Panel1: TPanel
                Left = 744
                Top = 0
                Width = 185
                Height = 368
                Align = alRight
                TabOrder = 1
                ExplicitHeight = 384
                object btnIraalbaran: TcxButton
                  Left = 6
                  Top = 16
                  Width = 160
                  Height = 26
                  Caption = 'Ir a albar'#225'n'
                  TabOrder = 0
                  OnClick = btnIraalbaranClick
                end
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
          object curTOTAL_BASES_PEDC: TcxDBCurrencyEdit
            Left = 16
            Top = 32
            DataBinding.DataField = 'TOTAL_BASES_PEDC'
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
          object curTOTAL_IMPUESTOS_PEDC: TcxDBCurrencyEdit
            Left = 176
            Top = 32
            DataBinding.DataField = 'TOTAL_IMPUESTOS_PEDC'
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
          object curTOTAL_LIQUIDO_PEDC: TcxDBCurrencyEdit
            Left = 336
            Top = 32
            DataBinding.DataField = 'TOTAL_LIQUIDO_PEDC'
            DataBinding.DataSource = dsTablaG
            Properties.DisplayFormat = '#,##0.00 '#8364
            Properties.ReadOnly = True
            TabOrder = 5
            Width = 160
          end
          object lblContextoTalla: TcxLabel
            Left = 560
            Top = 8
            TabOrder = 6
            Transparent = True
            Visible = False
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
    object btnCrearAlbaran: TcxButton
      Left = 7
      Top = 290
      Width = 121
      Height = 26
      Caption = 'Crear albar'#225'n'
      Hint = 'Crear albar'#225'n'
      ShowHint = True
      TabOrder = 2
      OnClick = btnCrearAlbaranClick
    end
    object btnImprimir: TcxButton
      Left = 7
      Top = 354
      Width = 121
      Height = 26
      Caption = 'Imprimir pedido'
      TabOrder = 4
      OnClick = btnImprimirClick
    end
    object btnPegatinas: TcxButton
      Left = 7
      Top = 322
      Width = 121
      Height = 26
      Caption = 'Etiquetas'
      TabOrder = 3
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
    object actIrDocumento: TAction
      Caption = 'Ir a documento (Ctrl+May+A)'
      ShortCut = 24641
      OnExecute = actIrDocumentoExecute
    end
    object actIrProveedor: TAction
      Caption = 'Ir a proveedor'
      ShortCut = 16464
      OnExecute = actIrProveedorExecute
    end
  end
end
