inherited frmMtoPedidos: TfrmMtoPedidos
  Caption = 'Mantenimiento de Pedidos'
  ClientHeight = 765
  ClientWidth = 1085
  StyleElements = [seFont, seClient, seBorder]
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
      ClientRectBottom = 723
      ClientRectRight = 943
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 2
        ExplicitTop = 27
        ExplicitWidth = 941
        ExplicitHeight = 696
        inherited cxGrdPrincipal: TcxGrid
          Width = 941
          Height = 696
          ExplicitWidth = 941
          ExplicitHeight = 696
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            object dbcGrdPedNUMERO_PED: TcxGridDBColumn
              Caption = 'Nro Pedido'
              DataBinding.FieldName = 'NUMERO_PED'
              Width = 90
            end
            object dbcGrdPedSERIE_PED: TcxGridDBColumn
              Caption = 'Serie'
              DataBinding.FieldName = 'SERIE_PED'
              Width = 70
            end
            object dbcGrdPedFECHA_PED: TcxGridDBColumn
              Caption = 'Fecha'
              DataBinding.FieldName = 'FECHA_PED'
              Width = 100
            end
            object dbcGrdPedESTADO_PED: TcxGridDBColumn
              Caption = 'Estado'
              DataBinding.FieldName = 'ESTADO_PED'
              Width = 110
            end
            object dbcGrdPedCODIGO_EMP_PED: TcxGridDBColumn
              Caption = 'Empresa'
              DataBinding.FieldName = 'CODIGO_EMP_PED'
              Width = 90
            end
            object dbcGrdPedRSEMP_PED: TcxGridDBColumn
              Caption = 'Raz'#243'n Social Empresa'
              DataBinding.FieldName = 'RAZON_SOCIAL_EMPRESA_PED'
              Width = 220
            end
            object dbcGrdPedCODIGO_CLI_PED: TcxGridDBColumn
              Caption = 'Cliente'
              DataBinding.FieldName = 'CODIGO_CLI_PED'
              Width = 90
            end
            object dbcGrdPedRSCLI_PED: TcxGridDBColumn
              Caption = 'Raz'#243'n Social Cliente'
              DataBinding.FieldName = 'RAZON_SOCIAL_CLIENTE_FISCAL_PED'
              Width = 220
            end
            object dbcGrdPedIDPS_PED: TcxGridDBColumn
              Caption = 'ID PrestaShop'
              DataBinding.FieldName = 'IDPS_PED'
              Width = 90
            end
            object dbcGrdPedREFPS_PED: TcxGridDBColumn
              Caption = 'Ref. PrestaShop'
              DataBinding.FieldName = 'REFERENCIAPS_PED'
              Width = 110
            end
            object dbcGrdPedFECHAPS_PED: TcxGridDBColumn
              Caption = 'Fecha PrestaShop'
              DataBinding.FieldName = 'FECHAPS_PED'
              Width = 130
            end
            object dbcGrdPedTOTAL_LIQUIDO_PED: TcxGridDBColumn
              Caption = 'Total'
              DataBinding.FieldName = 'TOTAL_LIQUIDO_PED'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 110
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        ExplicitLeft = 2
        ExplicitTop = 27
        ExplicitWidth = 941
        ExplicitHeight = 696
        object pnlTopFicha: TPanel
          Left = 0
          Top = 0
          Width = 941
          Height = 230
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          object pcCab: TcxPageControl
            Left = 0
            Top = 0
            Width = 941
            Height = 230
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsCabecera
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 228
            ClientRectLeft = 2
            ClientRectRight = 939
            ClientRectTop = 27
            object tsCabecera: TcxTabSheet
              Caption = 'Cabecera'
              object lblNroPedido: TcxLabel
                Left = 8
                Top = 12
                Caption = 'N'#250'mero'
                TabOrder = 9
                Transparent = True
              end
              object txtNUMERO_PED: TcxDBTextEdit
                Left = 8
                Top = 32
                DataBinding.DataField = 'NUMERO_PED'
                DataBinding.DataSource = dsTablaG
                TabOrder = 0
                Width = 90
              end
              object lblSerie: TcxLabel
                Left = 106
                Top = 12
                Caption = 'Serie'
                TabOrder = 10
                Transparent = True
              end
              object cbbSERIE_PED: TcxDBComboBox
                Left = 106
                Top = 32
                DataBinding.DataField = 'SERIE_PED'
                DataBinding.DataSource = dsTablaG
                Properties.MaxLength = 12
                Properties.OnInitPopup = cbbSERIE_PEDPropertiesInitPopup
                TabOrder = 1
                Width = 70
              end
              object lblFecha: TcxLabel
                Left = 184
                Top = 12
                Caption = 'Fecha'
                TabOrder = 11
                Transparent = True
              end
              object dteFECHA_PED: TcxDBDateEdit
                Left = 184
                Top = 32
                DataBinding.DataField = 'FECHA_PED'
                DataBinding.DataSource = dsTablaG
                TabOrder = 2
                Width = 110
              end
              object lblFechaEntrega: TcxLabel
                Left = 302
                Top = 12
                Caption = 'Fecha entrega'
                TabOrder = 12
                Transparent = True
              end
              object dteFECHA_ENTREGA_PED: TcxDBDateEdit
                Left = 302
                Top = 32
                DataBinding.DataField = 'FECHA_ENTREGA_PED'
                DataBinding.DataSource = dsTablaG
                TabOrder = 3
                Width = 110
              end
              object lblEstado: TcxLabel
                Left = 420
                Top = 12
                Caption = 'Estado'
                TabOrder = 13
                Transparent = True
              end
              object txtESTADO_PED: TcxDBTextEdit
                Left = 420
                Top = 32
                DataBinding.DataField = 'ESTADO_PED'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 4
                Width = 110
              end
              object lblIDPS: TcxLabel
                Left = 540
                Top = 12
                Caption = 'ID PrestaShop'
                TabOrder = 14
                Transparent = True
              end
              object txtIDPS_PED: TcxDBTextEdit
                Left = 540
                Top = 32
                DataBinding.DataField = 'IDPS_PED'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 5
                Width = 90
              end
              object lblRefPS: TcxLabel
                Left = 540
                Top = 68
                Caption = 'Ref. PrestaShop'
                TabOrder = 15
                Transparent = True
              end
              object txtREFERENCIAPS_PED: TcxDBTextEdit
                Left = 540
                Top = 88
                DataBinding.DataField = 'REFERENCIAPS_PED'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 6
                Width = 110
              end
              object lblCodigoEmpresa: TcxLabel
                Left = 8
                Top = 80
                Caption = 'Empresa Emisora'
                TabOrder = 16
                Transparent = True
              end
              object btnCODIGO_EMP: TcxDBButtonEdit
                Left = 8
                Top = 100
                DataBinding.DataField = 'CODIGO_EMP_PED'
                DataBinding.DataSource = dsTablaG
                Properties.Buttons = <
                  item
                    Default = True
                    Kind = bkEllipsis
                  end>
                Properties.OnButtonClick = btnCODIGO_EMPPropertiesButtonClick
                Properties.OnEditValueChanged = btnCODIGO_EMPPropertiesEditValueChanged
                TabOrder = 7
                OnKeyUp = btnCODIGO_EMPKeyUp
                Width = 130
              end
              object cxdblblRAZON_SOCIAL_EMPRESA_PED: TcxDBLabel
                Left = 144
                Top = 100
                DataBinding.DataField = 'RAZON_SOCIAL_EMPRESA_PED'
                DataBinding.DataSource = dsTablaG
                TabOrder = 17
                Transparent = True
                Height = 21
                Width = 380
              end
              object lblCodigoAlmacen: TcxLabel
                Left = 544
                Top = 120
                Caption = 'Almac'#233'n salida'
                TabOrder = 18
                Transparent = True
              end
              object cbbCODIGO_ALM_PED: TcxDBLookupComboBox
                Left = 544
                Top = 140
                DataBinding.DataField = 'CODIGO_ALM_PED'
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
                Properties.OnEditValueChanged = cbbCODIGO_ALM_PEDPropertiesEditValueChanged
                TabOrder = 8
                Width = 240
              end
              object lblCodigoCliente: TcxLabel
                Left = 8
                Top = 140
                Caption = 'Cliente'
                TabOrder = 19
                Transparent = True
              end
              object btnCODIGO_CLI: TcxDBButtonEdit
                Left = 8
                Top = 160
                DataBinding.DataField = 'CODIGO_CLI_PED'
                DataBinding.DataSource = dsTablaG
                Properties.Buttons = <
                  item
                    Default = True
                    Kind = bkEllipsis
                  end>
                Properties.OnButtonClick = btnCODIGO_CLIPropertiesButtonClick
                Properties.OnEditValueChanged = btnCODIGO_CLIPropertiesEditValueChanged
                TabOrder = 9
                OnKeyUp = btnCODIGO_CLIKeyUp
                Width = 130
              end
              object cxdblblRAZON_SOCIAL_CLIENTE_PED: TcxDBLabel
                Left = 144
                Top = 160
                DataBinding.DataField = 'RAZON_SOCIAL_CLIENTE_FISCAL_PED'
                DataBinding.DataSource = dsTablaG
                TabOrder = 20
                Transparent = True
                Height = 21
                Width = 380
              end
              object lblVendedorPedido: TcxLabel
                Left = 664
                Top = 68
                Caption = 'Vendedor'
                TabOrder = 24
                Transparent = True
              end
              
              object cbbCODIGO_VENDEDOR_PED: TcxDBLookupComboBox
                Left = 664
                Top = 88
                DataBinding.DataField = 'CODIGO_VENDEDOR_PED'
                DataBinding.DataSource = dsTablaG
                Properties.ClearKey = 46
                Properties.DropDownListStyle = lsFixedList
                Properties.KeyFieldNames = 'CODIGO_EMPL'
                Properties.ListColumns = <
                  item
                    Caption = 'C'#243'digo'
                    Width = 80
                    FieldName = 'CODIGO_EMPL'
                  end
                  item
                    Caption = 'Vendedor'
                    Width = 220
                    FieldName = 'NOMBRE_VENDEDOR'
                  end>
                Properties.ListFieldIndex = 1
                TabOrder = 10
                Width = 240
              end
              object lblTarifaPedido: TcxLabel
                Left = 792
                Top = 120
                Caption = 'Tarifa'
                TabOrder = 21
                Transparent = True
              end
              object cbbTarifaPedido: TcxDBLookupComboBox
                Left = 792
                Top = 140
                DataBinding.DataField = 'TARIFA_ARTICULO_CLIENTE_PED'
                DataBinding.DataSource = dsTablaG
                Properties.DropDownListStyle = lsFixedList
                Properties.KeyFieldNames = 'CODIGO_TAR_ARTTAR'
                Properties.ListColumns = <
                  item
                    Caption = 'Tarifa'
                    FieldName = 'NOMBRE_TAR_TAR'
                  end
                  item
                    Caption = 'Imp. incl.'
                    FieldName = 'ESIMP_INCL_TAR'
                  end>
                Properties.OnChange = cbbTarifaPedidoPropertiesChange
                TabOrder = 22
                Width = 132
              end
              object chkTarifaImpuestosIncluidosPedido: TcxDBCheckBox
                Left = 792
                Top = 169
                Caption = 'Imp. incl.'
                DataBinding.DataField = 'ESIMP_INCL_TARIFA_CLIENTE_PED'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                Properties.ValueChecked = 'S'
                Properties.ValueUnchecked = 'N'
                TabOrder = 23
                Transparent = True
              end
              object lblTotalesTotalPrendas: TcxLabel
                Left = 650
                Top = 12
                Caption = 'N'#186' de prendas'
                TabOrder = 25
                Transparent = True
              end
              object lblTotalPrendasPed: TcxLabel
                Left = 650
                Top = 32
                AutoSize = False
                Caption = '0'
                TabOrder = 26
                Transparent = True
                Height = 20
                Width = 133
              end
            end
            object tsEmpresa: TcxTabSheet
              Caption = 'Empresa'
              object grpEmpresa: TcxGroupBox
                Left = 4
                Top = 4
                Caption = 'Datos Empresa Emisora'
                TabOrder = 0
                Height = 192
                Width = 920
                object lblNIFEmp: TcxLabel
                  Left = 12
                  Top = 24
                  Caption = 'NIF'
                  TabOrder = 9
                  Transparent = True
                end
                object txtNIF_EMPRESA_PED: TcxDBTextEdit
                  Left = 12
                  Top = 44
                  DataBinding.DataField = 'NIF_EMPRESA_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 0
                  Width = 130
                end
                object lblMovEmp: TcxLabel
                  Left = 152
                  Top = 24
                  Caption = 'M'#243'vil'
                  TabOrder = 10
                  Transparent = True
                end
                object txtMOVIL_EMPRESA_PED: TcxDBTextEdit
                  Left = 152
                  Top = 44
                  DataBinding.DataField = 'MOVIL_EMPRESA_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 1
                  Width = 130
                end
                object lblEmailEmp: TcxLabel
                  Left = 292
                  Top = 24
                  Caption = 'Email'
                  TabOrder = 11
                  Transparent = True
                end
                object txtEMAIL_EMPRESA_PED: TcxDBTextEdit
                  Left = 292
                  Top = 44
                  DataBinding.DataField = 'EMAIL_EMPRESA_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 2
                  Width = 220
                end
                object txtDIRECCION1_EMPRESA_PED: TcxDBTextEdit
                  Left = 12
                  Top = 84
                  DataBinding.DataField = 'DIRECCION1_EMPRESA_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 3
                  Width = 350
                end
                object txtDIRECCION2_EMPRESA_PED: TcxDBTextEdit
                  Left = 372
                  Top = 84
                  DataBinding.DataField = 'DIRECCION2_EMPRESA_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 4
                  Width = 250
                end
                object txtPOBLACION_EMPRESA_PED: TcxDBTextEdit
                  Left = 12
                  Top = 116
                  DataBinding.DataField = 'POBLACION_EMPRESA_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 5
                  Width = 200
                end
                object txtPROVINCIA_EMPRESA_PED: TcxDBTextEdit
                  Left = 220
                  Top = 116
                  DataBinding.DataField = 'PROVINCIA_EMPRESA_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 6
                  Width = 200
                end
                object txtCODIGO_POSTAL_EMPRESA_PED: TcxDBTextEdit
                  Left = 428
                  Top = 116
                  DataBinding.DataField = 'CODIGO_POSTAL_EMPRESA_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 7
                  Width = 80
                end
                object txtNOMBRE_PAI_EMPRESA_PED: TcxDBTextEdit
                  Left = 516
                  Top = 116
                  DataBinding.DataField = 'NOMBRE_PAI_EMPRESA_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 8
                  Width = 150
                end
              end
            end
            object tsDatosCliente: TcxTabSheet
              Caption = 'Cliente Fiscal'
              object grpClienteFiscal: TcxGroupBox
                Left = 4
                Top = 4
                Caption = 'Datos Cliente Fiscal'
                TabOrder = 0
                Height = 192
                Width = 920
                object txtRAZON_SOCIAL_CLIENTE_FISCAL_PED: TcxDBTextEdit
                  Left = 12
                  Top = 24
                  DataBinding.DataField = 'RAZON_SOCIAL_CLIENTE_FISCAL_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 0
                  Width = 320
                end
                object txtNIF_CLIENTE_PED: TcxDBTextEdit
                  Left = 342
                  Top = 24
                  DataBinding.DataField = 'NIF_CLIENTE_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 1
                  Width = 130
                end
                object txtEMAIL_CLIENTE_PED: TcxDBTextEdit
                  Left = 482
                  Top = 24
                  DataBinding.DataField = 'EMAIL_CLIENTE_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 2
                  Width = 220
                end
                object txtMOVIL_CLIENTE_FISCAL_PED: TcxDBTextEdit
                  Left = 712
                  Top = 24
                  DataBinding.DataField = 'MOVIL_CLIENTE_FISCAL_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 3
                  Width = 130
                end
                object txtDIRECCION1_CLIENTE_FISCAL_PED: TcxDBTextEdit
                  Left = 12
                  Top = 60
                  DataBinding.DataField = 'DIRECCION1_CLIENTE_FISCAL_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 4
                  Width = 350
                end
                object txtDIRECCION2_CLIENTE_FISCAL_PED: TcxDBTextEdit
                  Left = 372
                  Top = 60
                  DataBinding.DataField = 'DIRECCION2_CLIENTE_FISCAL_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 5
                  Width = 250
                end
                object txtPOBLACION_CLIENTE_FISCAL_PED: TcxDBTextEdit
                  Left = 12
                  Top = 96
                  DataBinding.DataField = 'POBLACION_CLIENTE_FISCAL_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 6
                  Width = 200
                end
                object txtPROVINCIA_CLIENTE_FISCAL_PED: TcxDBTextEdit
                  Left = 220
                  Top = 96
                  DataBinding.DataField = 'PROVINCIA_CLIENTE_FISCAL_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 7
                  Width = 200
                end
                object txtCODIGO_POSTAL_CLIENTE_FISCAL_PED: TcxDBTextEdit
                  Left = 428
                  Top = 96
                  DataBinding.DataField = 'CODIGO_POSTAL_CLIENTE_FISCAL_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 8
                  Width = 80
                end
                object txtNOMBRE_PAI_CLIENTE_FISCAL_PED: TcxDBTextEdit
                  Left = 516
                  Top = 96
                  DataBinding.DataField = 'NOMBRE_PAI_CLIENTE_FISCAL_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 9
                  Width = 150
                end
              end
            end
            object tsEnvio: TcxTabSheet
              Caption = 'Direcci'#243'n Env'#237'o'
              object grpClienteEnvio: TcxGroupBox
                Left = 4
                Top = 4
                Caption = 'Datos Cliente Env'#237'o'
                TabOrder = 0
                Height = 192
                Width = 920
                object txtNOMBRE_CLI_ENVIO_PED: TcxDBTextEdit
                  Left = 12
                  Top = 24
                  DataBinding.DataField = 'NOMBRE_CLI_ENVIO_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 0
                  Width = 320
                end
                object txtMOVIL_CLIENTE_ENVIO_PED: TcxDBTextEdit
                  Left = 342
                  Top = 24
                  DataBinding.DataField = 'MOVIL_CLIENTE_ENVIO_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 1
                  Width = 130
                end
                object txtDIRECCION1_CLIENTE_ENVIO_PED: TcxDBTextEdit
                  Left = 12
                  Top = 60
                  DataBinding.DataField = 'DIRECCION1_CLIENTE_ENVIO_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 2
                  Width = 350
                end
                object txtDIRECCION2_CLIENTE_ENVIO_PED: TcxDBTextEdit
                  Left = 372
                  Top = 60
                  DataBinding.DataField = 'DIRECCION2_CLIENTE_ENVIO_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 3
                  Width = 250
                end
                object txtPOBLACION_CLIENTE_ENVIO_PED: TcxDBTextEdit
                  Left = 12
                  Top = 96
                  DataBinding.DataField = 'POBLACION_CLIENTE_ENVIO_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 4
                  Width = 200
                end
                object txtPROVINCIA_CLIENTE_ENVIO_PED: TcxDBTextEdit
                  Left = 220
                  Top = 96
                  DataBinding.DataField = 'PROVINCIA_CLIENTE_ENVIO_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 5
                  Width = 200
                end
                object txtCODIGO_POSTAL_CLIENTE_ENVIO_PED: TcxDBTextEdit
                  Left = 428
                  Top = 96
                  DataBinding.DataField = 'CODIGO_POSTAL_CLIENTE_ENVIO_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 6
                  Width = 80
                end
                object txtNOMBRE_PAI_CLIENTE_ENVIO_PED: TcxDBTextEdit
                  Left = 516
                  Top = 96
                  DataBinding.DataField = 'NOMBRE_PAI_CLIENTE_ENVIO_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 7
                  Width = 150
                end
              end
            end
          end
        end
        object splSplitterFicha: TcxSplitter
          Left = 0
          Top = 230
          Width = 941
          Height = 8
          Cursor = crSizeNS
          HotZoneClassName = 'TcxMediaPlayer9Style'
          HotZone.SizePercent = 50
          AlignSplitter = salTop
          Control = pnlTopFicha
        end
        object pnlBotonesAcciones: TPanel
          Left = 0
          Top = 238
          Width = 941
          Height = 40
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 1
          object btnAnadirLinea: TcxButton
            Left = 4
            Top = 6
            Width = 120
            Height = 28
            Caption = 'A'#241'adir l'#237'nea'
            TabOrder = 0
            OnClick = btnAnadirLineaClick
          end
          object btnBorrarLinea: TcxButton
            Left = 130
            Top = 6
            Width = 120
            Height = 28
            Caption = 'Borrar l'#237'nea'
            TabOrder = 1
            OnClick = btnBorrarLineaClick
          end
          object btnEntregarTodo: TcxButton
            Left = 256
            Top = 6
            Width = 182
            Height = 28
            Caption = 'Marcar todo entregado'
            TabOrder = 2
            OnClick = btnEntregarTodoClick
          end
          object btnCrearAlbaran: TcxButton
            Left = 444
            Top = 6
            Width = 130
            Height = 28
            Caption = 'Crear albar'#225'n'
            Hint = 'Crear albar'#225'n'
            ShowHint = True
            TabOrder = 3
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Source Sans 3'
            Font.Style = [fsBold]
            ParentFont = False
            OnClick = btnCrearAlbaranClick
          end
          object btnImportarPS: TcxButton
            Left = 580
            Top = 6
            Width = 186
            Height = 28
            Caption = 'Importar de PrestaShop'
            TabOrder = 4
            OnClick = btnImportarPSClick
          end
          object btnExpandirFilas: TcxButton
            Left = 772
            Top = 6
            Width = 160
            Height = 28
            Caption = 'Expandir Filas'
            TabOrder = 5
            OnClick = btnExpandirFilasClick
          end
        end
        object pnlBodyFicha: TPanel
          Left = 0
          Top = 278
          Width = 941
          Height = 378
          Align = alClient
          BevelOuter = bvNone
          TabOrder = 2
          object pcPedido: TcxPageControl
            Left = 0
            Top = 0
            Width = 941
            Height = 386
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsLineasPedido
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 384
            ClientRectLeft = 2
            ClientRectRight = 939
            ClientRectTop = 27
            object tsLineasPedido: TcxTabSheet
              Caption = 'L'#237'neas Pedido'
              object cxGrdPedidosLineas: TcxGrid
                Left = 0
                Top = 0
                Width = 937
                Height = 357
                Align = alClient
                TabOrder = 0
                object tvPedidosLineas: TcxGridDBTableView
                  OptionsView.Footer = False
                  OptionsView.GroupByBox = False
                  object cxgrdcPedLinLINEA: TcxGridDBColumn
                    Caption = 'L'#237'nea'
                    DataBinding.FieldName = 'LINEA_PEDLIN'
                    Width = 65
                  end
                  object cxgrdcPedLinART: TcxGridDBColumn
                    Caption = 'C'#243'digo Art'#237'culo'
                    DataBinding.FieldName = 'CODIGO_ART_PEDLIN'
                    PropertiesClassName = 'TcxButtonEditProperties'
                    Properties.Buttons = <
                      item
                        Default = True
                        Kind = bkEllipsis
                      end>
                    Properties.OnButtonClick = cxgrdcPedLinARTPropertiesButtonClick
                    Properties.OnValidate = cxgrdcPedLinARTPropertiesValidate
                    Width = 154
                  end
                  object cxgrdcPedLinSKU: TcxGridDBColumn
                    Caption = 'SKU'
                    DataBinding.FieldName = 'CODIGOPRODPS_PEDLIN'
                    PropertiesClassName = 'TcxTextEditProperties'
                    Properties.OnValidate = cxgrdcPedLinSKUPropertiesValidate
                    Width = 150
                  end
                  object cxgrdcPedLinDESCR: TcxGridDBColumn
                    Caption = 'Descripci'#243'n'
                    DataBinding.FieldName = 'DESCRIPCION_ARTICULO_PEDLIN'
                    Width = 240
                  end
                  object cxgrdcPedLinCANT: TcxGridDBColumn
                    Caption = 'Pedida'
                    DataBinding.FieldName = 'CANTIDAD_PEDLIN'
                    Width = 80
                  end
                  object colTipoCantPed: TcxGridDBColumn
                    DataBinding.FieldName = 'TIPO_CANTIDAD_ARTICULO_PEDLIN'
                    Visible = False
                    VisibleForCustomization = False
                  end
                  object cxgrdcPedLinENT: TcxGridDBColumn
                    Caption = 'Entregada'
                    DataBinding.FieldName = 'CANTIDAD_ENTREGADA_PEDLIN'
                    Width = 119
                  end
                  object cxgrdcPedLinPEND: TcxGridDBColumn
                    Caption = 'Pendiente'
                    DataBinding.FieldName = 'CANTIDAD_PENDIENTE_PEDLIN'
                    Options.Editing = False
                    Width = 110
                  end
                  object cxgrdcPedLinESEN: TcxGridDBColumn
                    Caption = 'Entregada?'
                    DataBinding.FieldName = 'ESENTREGADA_PEDLIN'
                    Options.Editing = False
                    Width = 111
                  end
                  object cxgrdcPedLinPSIVA: TcxGridDBColumn
                    Caption = 'PVP S/IVA'
                    DataBinding.FieldName = 'PRECIO_VENTA_SIVA_ARTICULO_PEDLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Width = 90
                  end
                  object cxgrdcPedLinPCIVA: TcxGridDBColumn
                    Caption = 'PVP C/IVA'
                    DataBinding.FieldName = 'PRECIO_VENTA_CIVA_ARTICULO_PEDLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Width = 90
                  end
                  object cxgrdcPedLinTOT: TcxGridDBColumn
                    Caption = 'Total'
                    DataBinding.FieldName = 'TOTAL_PEDLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Width = 100
                  end
                  object cxgrdcPedLinALM: TcxGridDBColumn
                    Caption = 'Almac'#233'n'
                    DataBinding.FieldName = 'CODIGO_ALMACEN_PEDLIN'
                    Width = 80
                  end
                end
                object cxGrdPedidosLineasLevel1: TcxGridLevel
                  GridView = tvPedidosLineas
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
                Width = 937
                Height = 357
                Align = alClient
                BorderStyle = cxcbsNone
                TabOrder = 0
                object lblVentaDtoComercial: TcxLabel
                  Properties.Alignment.Vert = taVCenter
                  Properties.Alignment.Horz = taRightJustify
                  Width = 162
                  Height = 24
                  AutoSize = False
                  Left = 16
                  Top = 240
                  Caption = 'Dto. comercial'
                  TabOrder = 33
                  Transparent = True
                end
                object spnVentaPORCENTAJE_DTO_COMERCIAL_PED: TcxDBSpinEdit
                  Left = 185
                  Top = 240
                  DataBinding.DataField = 'PORCENTAJE_DTO_COMERCIAL_PED'
                  DataBinding.DataSource = dsTablaG
                  Properties.AssignedValues.MinValue = True
                  Properties.DisplayFormat = '0.00 %'
                  Properties.EditFormat = '0.00 %'
                  Properties.ImmediatePost = True
                  Properties.OnEditValueChanged = DescuentosDocumentoCambiados
                  Properties.MaxValue = 100.000000000000000000
                  TabOrder = 34
                  Width = 86
                end
                object curVentaTOTAL_DTO_COMERCIAL_PED: TcxDBCurrencyEdit
                  Left = 272
                  Top = 240
                  DataBinding.DataField = 'TOTAL_DTO_COMERCIAL_PED'
                  DataBinding.DataSource = dsTablaG
                  Properties.DisplayFormat = '#,##0.00 '#8364
                  Properties.ReadOnly = True
                  TabOrder = 35
                  Width = 91
                end
                object lblVentaDtoFinanciero: TcxLabel
                  Properties.Alignment.Vert = taVCenter
                  Properties.Alignment.Horz = taRightJustify
                  Width = 162
                  Height = 24
                  AutoSize = False
                  Left = 16
                  Top = 270
                  Caption = 'Dto. financiero'
                  TabOrder = 36
                  Transparent = True
                end
                object spnVentaPORCENTAJE_DTO_FINANCIERO_PED: TcxDBSpinEdit
                  Left = 185
                  Top = 270
                  DataBinding.DataField = 'PORCENTAJE_DTO_FINANCIERO_PED'
                  DataBinding.DataSource = dsTablaG
                  Properties.AssignedValues.MinValue = True
                  Properties.DisplayFormat = '0.00 %'
                  Properties.EditFormat = '0.00 %'
                  Properties.ImmediatePost = True
                  Properties.OnEditValueChanged = DescuentosDocumentoCambiados
                  Properties.MaxValue = 100.000000000000000000
                  TabOrder = 37
                  Width = 86
                end
                object curVentaTOTAL_DTO_FINANCIERO_PED: TcxDBCurrencyEdit
                  Left = 272
                  Top = 270
                  DataBinding.DataField = 'TOTAL_DTO_FINANCIERO_PED'
                  DataBinding.DataSource = dsTablaG
                  Properties.DisplayFormat = '#,##0.00 '#8364
                  Properties.ReadOnly = True
                  TabOrder = 38
                  Width = 91
                end
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
                object curTotalesTOTAL_BASES_PED: TcxDBCurrencyEdit
                  Left = 230
                  Top = 18
                  DataBinding.DataField = 'TOTAL_BASES_PED'
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
                object curTotalesTOTAL_IMPUESTOS_PED: TcxDBCurrencyEdit
                  Left = 230
                  Top = 50
                  DataBinding.DataField = 'TOTAL_IMPUESTOS_PED'
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
                object spnTotalesPORCENTAJE_RETENCION_PED: TcxDBSpinEdit
                  Left = 230
                  Top = 82
                  DataBinding.DataField = 'PORCENTAJE_RETENCION_PED'
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
                object curTotalesTOTAL_RETENCION_PED: TcxDBCurrencyEdit
                  Left = 230
                  Top = 114
                  DataBinding.DataField = 'TOTAL_RETENCION_PED'
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
                object curTotalesTOTAL_LIQUIDO_PED: TcxDBCurrencyEdit
                  Left = 230
                  Top = 146
                  DataBinding.DataField = 'TOTAL_LIQUIDO_PED'
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
                object cbbTotalesFORMA_PAGO_PED: TcxDBLookupComboBox
                  Left = 230
                  Top = 178
                  DataBinding.DataField = 'FORMA_PAGO_PED'
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
                object chkTotalesESIVA_RECARGO_CLIENTE_PED: TcxDBCheckBox
                  Left = 56
                  Top = 210
                  Caption = 'Recargo equivalencia cliente'
                  DataBinding.DataField = 'ESIVA_RECARGO_CLIENTE_PED'
                  DataBinding.DataSource = dsTablaG
                  Properties.ValueChecked = 'S'
                  Properties.ValueUnchecked = 'N'
                  Style.TransparentBorder = False
                  TabOrder = 12
                  Transparent = True
                end
                object chkTotalesESRETENCIONES_CLIENTE_PED: TcxDBCheckBox
                  Left = 56
                  Top = 320
                  Caption = 'Cliente sujeto a retenci'#243'n'
                  DataBinding.DataField = 'ESRETENCIONES_CLIENTE_PED'
                  DataBinding.DataSource = dsTablaG
                  Properties.ValueChecked = 'S'
                  Properties.ValueUnchecked = 'N'
                  Style.TransparentBorder = False
                  TabOrder = 13
                  Transparent = True
                end
                object chkTotalesESRETENCIONES_EMPRESA_PED: TcxDBCheckBox
                  Left = 56
                  Top = 350
                  Caption = 'Empresa aplica retenci'#243'n'
                  DataBinding.DataField = 'ESRETENCIONES_EMPRESA_PED'
                  DataBinding.DataSource = dsTablaG
                  Properties.ValueChecked = 'S'
                  Properties.ValueUnchecked = 'N'
                  Style.TransparentBorder = False
                  TabOrder = 14
                  Transparent = True
                end
                object grpDesgloseImpuestos: TcxGroupBox
                  Left = 384
                  Top = 10
                  Width = 525
                  Height = 280
                  Caption = 'Desglose Impuestos'
                  TabOrder = 17
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
                  object curTotalesTOTAL_BASEI_IVAN_PED: TcxDBCurrencyEdit
                    Left = 145
                    Top = 80
                    DataBinding.DataField = 'TOTAL_BASEI_IVAN_PED'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 9
                    Width = 92
                  end
                  object curTotalesTOTAL_BASEI_IVAR_PED: TcxDBCurrencyEdit
                    Left = 145
                    Top = 128
                    DataBinding.DataField = 'TOTAL_BASEI_IVAR_PED'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 10
                    Width = 92
                  end
                  object curTotalesTOTAL_BASEI_IVAS_PED: TcxDBCurrencyEdit
                    Left = 145
                    Top = 176
                    DataBinding.DataField = 'TOTAL_BASEI_IVAS_PED'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 11
                    Width = 92
                  end
                  object curTotalesTOTAL_BASEI_IVAE_PED: TcxDBCurrencyEdit
                    Left = 145
                    Top = 224
                    DataBinding.DataField = 'TOTAL_BASEI_IVAE_PED'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 12
                    Width = 92
                  end
                  object curTotalesTOTAL_IVAN_PED: TcxDBCurrencyEdit
                    Left = 296
                    Top = 80
                    DataBinding.DataField = 'TOTAL_IVAN_PED'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 13
                    Width = 86
                  end
                  object curTotalesTOTAL_IVAR_PED: TcxDBCurrencyEdit
                    Left = 296
                    Top = 128
                    DataBinding.DataField = 'TOTAL_IVAR_PED'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 14
                    Width = 86
                  end
                  object curTotalesTOTAL_IVAS_PED: TcxDBCurrencyEdit
                    Left = 296
                    Top = 176
                    DataBinding.DataField = 'TOTAL_IVAS_PED'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 15
                    Width = 86
                  end
                  object curTotalesTOTAL_IVAE_PED: TcxDBCurrencyEdit
                    Left = 296
                    Top = 224
                    DataBinding.DataField = 'TOTAL_IVAE_PED'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 16
                    Width = 86
                  end
                  object curTotalesTOTAL_REN_PED: TcxDBCurrencyEdit
                    Left = 442
                    Top = 80
                    DataBinding.DataField = 'TOTAL_REN_PED'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 17
                    Width = 75
                  end
                  object curTotalesTOTAL_RER_PED: TcxDBCurrencyEdit
                    Left = 442
                    Top = 128
                    DataBinding.DataField = 'TOTAL_RER_PED'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 18
                    Width = 75
                  end
                  object curTotalesTOTAL_RES_PED: TcxDBCurrencyEdit
                    Left = 442
                    Top = 176
                    DataBinding.DataField = 'TOTAL_RES_PED'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 19
                    Width = 75
                  end
                  object curTotalesTOTAL_REE_PED: TcxDBCurrencyEdit
                    Left = 442
                    Top = 224
                    DataBinding.DataField = 'TOTAL_REE_PED'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 20
                    Width = 75
                  end
                  object spnTotalesPORCENTAJE_IVAN_PED: TcxDBSpinEdit
                    Left = 238
                    Top = 80
                    DataBinding.DataField = 'PORCENTAJE_IVAN_PED'
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
                  object spnTotalesPORCENTAJE_IVAR_PED: TcxDBSpinEdit
                    Left = 238
                    Top = 128
                    DataBinding.DataField = 'PORCENTAJE_IVAR_PED'
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
                  object spnTotalesPORCENTAJE_IVAS_PED: TcxDBSpinEdit
                    Left = 238
                    Top = 176
                    DataBinding.DataField = 'PORCENTAJE_IVAS_PED'
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
                  object spnTotalesPORCENTAJE_IVAE_PED: TcxDBSpinEdit
                    Left = 238
                    Top = 224
                    DataBinding.DataField = 'PORCENTAJE_IVAE_PED'
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
                  object spnTotalesPORCENTAJE_REN_PED: TcxDBSpinEdit
                    Left = 388
                    Top = 80
                    DataBinding.DataField = 'PORCENTAJE_REN_PED'
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
                  object spnTotalesPORCENTAJE_RER_PED: TcxDBSpinEdit
                    Left = 388
                    Top = 128
                    DataBinding.DataField = 'PORCENTAJE_RER_PED'
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
                  object spnTotalesPORCENTAJE_RES_PED: TcxDBSpinEdit
                    Left = 388
                    Top = 176
                    DataBinding.DataField = 'PORCENTAJE_RES_PED'
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
                  object spnTotalesPORCENTAJE_REE_PED: TcxDBSpinEdit
                    Left = 388
                    Top = 224
                    DataBinding.DataField = 'PORCENTAJE_REE_PED'
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
                end
              end
            end
            object tsAlbaranes: TcxTabSheet
              Caption = 'Albaranes'
              object cxGrdAlbaranes: TcxGrid
                Left = 0
                Top = 0
                Width = 937
                Height = 357
                Align = alClient
                TabOrder = 0
                object tvAlbaranes: TcxGridDBTableView
                  OptionsView.GroupByBox = False
                  object cxgrdcAlbNUMERO_ALB: TcxGridDBColumn
                    Caption = 'N'#250'mero'
                    DataBinding.FieldName = 'NUMERO_ALB'
                    Width = 90
                  end
                  object cxgrdcAlbSERIE_ALB: TcxGridDBColumn
                    Caption = 'Serie'
                    DataBinding.FieldName = 'SERIE_ALB'
                    Width = 70
                  end
                  object cxgrdcAlbFECHA_ALB: TcxGridDBColumn
                    Caption = 'Fecha'
                    DataBinding.FieldName = 'FECHA_ALB'
                    Width = 100
                  end
                  object cxgrdcAlbESTADO_ALB: TcxGridDBColumn
                    Caption = 'Estado'
                    DataBinding.FieldName = 'ESTADO_ALB'
                    Width = 110
                  end
                  object cxgrdcAlbTOTAL_LIQUIDO_ALB: TcxGridDBColumn
                    Caption = 'Total'
                    DataBinding.FieldName = 'TOTAL_LIQUIDO_ALB'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Width = 110
                  end
                end
                object cxGrdAlbaranesLevel: TcxGridLevel
                  GridView = tvAlbaranes
                end
              end
            end
            object tsMensajes: TcxTabSheet
              Caption = 'Mensajes con el cliente'
              object cxGrdMensajes: TcxGrid
                Left = 0
                Top = 0
                Width = 937
                Height = 357
                Align = alClient
                TabOrder = 0
                object tvMensajes: TcxGridDBTableView
                  OptionsView.GroupByBox = False
                  object cxgrdcMsgFecha: TcxGridDBColumn
                    Caption = 'Fecha'
                    DataBinding.FieldName = 'FECHAPS_PEDMSG'
                    Width = 130
                  end
                  object cxgrdcMsgEmpleado: TcxGridDBColumn
                    Caption = 'Empleado'
                    DataBinding.FieldName = 'IDEMPLEADOPS_PEDMSG'
                    Width = 120
                  end
                  object cxgrdcMsgTexto: TcxGridDBColumn
                    Caption = 'Mensaje'
                    DataBinding.FieldName = 'MENSAJEPS_PEDMSG'
                    Width = 600
                  end
                end
                object cxGrdMensajesLevel: TcxGridLevel
                  GridView = tvMensajes
                end
              end
            end
            object tsObservaciones: TcxTabSheet
              Caption = 'Observaciones'
              object memObservaciones: TcxDBMemo
                Left = 0
                Top = 0
                Align = alClient
                DataBinding.DataField = 'OBSERVACIONES_PED'
                DataBinding.DataSource = dsTablaG
                TabOrder = 0
                Height = 357
                Width = 937
              end
            end
          end
        end
        object pnlBottomTotales: TPanel
          Left = 0
          Top = 656
          Width = 941
          Height = 40
          Align = alBottom
          BevelOuter = bvNone
          TabOrder = 3
          object lblTotalBases: TcxLabel
            Left = 380
            Top = 8
            Caption = 'Bases'
            TabOrder = 3
            Transparent = True
          end
          object curTOTAL_BASES_PED: TcxDBCurrencyEdit
            Left = 425
            Top = 8
            DataBinding.DataField = 'TOTAL_BASES_PED'
            DataBinding.DataSource = dsTablaG
            Properties.DisplayFormat = '#,##0.00 '#8364
            Properties.ReadOnly = True
            TabOrder = 0
            Width = 100
          end
          object lblTotalImpuestos: TcxLabel
            Left = 540
            Top = 8
            Caption = 'IVA'
            TabOrder = 4
            Transparent = True
          end
          object curTOTAL_IMPUESTOS_PED: TcxDBCurrencyEdit
            Left = 570
            Top = 8
            DataBinding.DataField = 'TOTAL_IMPUESTOS_PED'
            DataBinding.DataSource = dsTablaG
            Properties.DisplayFormat = '#,##0.00 '#8364
            Properties.ReadOnly = True
            TabOrder = 1
            Width = 100
          end
          object lblTotalLiquido: TcxLabel
            Left = 690
            Top = 8
            Caption = 'TOTAL'
            TabOrder = 5
            Transparent = True
          end
          object curTOTAL_LIQUIDO_PED: TcxDBCurrencyEdit
            Left = 740
            Top = 8
            DataBinding.DataField = 'TOTAL_LIQUIDO_PED'
            DataBinding.DataSource = dsTablaG
            Properties.DisplayFormat = '#,##0.00 '#8364
            Properties.ReadOnly = True
            TabOrder = 2
            Width = 130
          end
        end
      end
      inherited tsPerfil: TcxTabSheet
        ExplicitWidth = 941
        ExplicitHeight = 696
        inherited pnlPerfilTop: TPanel
          Width = 941
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 941
          inherited edtPerfilBusq: TcxTextEdit
            ExplicitHeight = 25
          end
        end
        inherited pnlPerfilDetail: TPanel
          Width = 941
          Height = 639
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 941
          ExplicitHeight = 639
          inherited cxgrdPerfil: TcxGrid
            Width = 941
            Height = 639
            ExplicitWidth = 941
            ExplicitHeight = 639
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
    object btnImprimir: TcxButton
      Left = 2
      Top = 337
      Width = 135
      Height = 28
      Caption = 'Imprimir'
      TabOrder = 2
      OnClick = btnImprimirClick
    end
  end
  object ActionList1: TActionList
    Left = 880
    Top = 8
    object actIrDocumento: TAction
      Caption = 'Ir a documento (Ctrl+May+A)'
      ShortCut = 24641
      OnExecute = actIrDocumentoExecute
    end
  end
end
