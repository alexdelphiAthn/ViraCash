inherited frmMtoAlbaranes: TfrmMtoAlbaranes
  Caption = 'Mantenimiento de Albaranes'
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
            object dbcGrdAlbNUMERO_ALB: TcxGridDBColumn
              Caption = 'N'#250'mero'
              DataBinding.FieldName = 'NUMERO_ALB'
              Width = 90
            end
            object dbcGrdAlbSERIE_ALB: TcxGridDBColumn
              Caption = 'Serie'
              DataBinding.FieldName = 'SERIE_ALB'
              Width = 80
            end
            object dbcGrdAlbINSTANTEMOVIMIENTO_ALB: TcxGridDBColumn
              Caption = 'Fecha y hora stock'
              DataBinding.FieldName = 'INSTANTE_MOVIMIENTO_ALB'
              PropertiesClassName = 'TcxDateEditProperties'
              Properties.DisplayFormat = 'dd/mm/yyyy hh:nn:ss'
              Properties.Kind = ckDateTime
              Width = 145
            end
            object dbcGrdAlbESTADO_ALB: TcxGridDBColumn
              Caption = 'Estado'
              DataBinding.FieldName = 'ESTADO_ALB'
              Width = 110
            end
            object dbcGrdAlbCODIGO_EMP_ALB: TcxGridDBColumn
              Caption = 'Empresa'
              DataBinding.FieldName = 'CODIGO_EMP_ALB'
              Width = 100
            end
            object dbcGrdAlbRSEMP_ALB: TcxGridDBColumn
              Caption = 'Raz'#243'n Social Empresa'
              DataBinding.FieldName = 'RAZON_SOCIAL_EMPRESA_ALB'
              Width = 220
            end
            object dbcGrdAlbNOMBRE_ALM_ALB: TcxGridDBColumn
              Caption = 'Almac'#233'n'
              DataBinding.FieldName = 'NOMBRE_ALM_ALB'
              Width = 160
            end
            object dbcGrdAlbCODIGO_CLI_ALB: TcxGridDBColumn
              Caption = 'Cliente'
              DataBinding.FieldName = 'CODIGO_CLI_ALB'
              Width = 100
            end
            object dbcGrdAlbRSCLI_ALB: TcxGridDBColumn
              Caption = 'Raz'#243'n Social Cliente'
              DataBinding.FieldName = 'RAZON_SOCIAL_CLIENTE_ALB'
              Width = 220
            end
            object dbcGrdAlbNUMERO_PED_ALB: TcxGridDBColumn
              Caption = 'Pedido'
              DataBinding.FieldName = 'NUMERO_PED_ALB'
              Width = 90
            end
            object dbcGrdAlbSERIE_PED_ALB: TcxGridDBColumn
              Caption = 'Serie Pedido'
              DataBinding.FieldName = 'SERIE_PED_ALB'
              Width = 90
            end
            object dbcGrdAlbNUMERO_FAC_ALB: TcxGridDBColumn
              Caption = 'Borrador'
              DataBinding.FieldName = 'NUMERO_FAC_ALB'
              Width = 90
            end
            object dbcGrdAlbSERIE_FAC_ALB: TcxGridDBColumn
              Caption = 'Serie Borrador'
              DataBinding.FieldName = 'SERIE_FAC_ALB'
              Width = 90
            end
            object dbcGrdAlbTOTAL_LIQUIDO_ALB: TcxGridDBColumn
              Caption = 'Total'
              DataBinding.FieldName = 'TOTAL_LIQUIDO_ALB'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 110
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
          Height = 230
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          object pcCab: TcxPageControl
            Left = 0
            Top = 0
            Width = 937
            Height = 230
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsCabecera
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 226
            ClientRectLeft = 4
            ClientRectRight = 933
            ClientRectTop = 28
            object tsCabecera: TcxTabSheet
              Caption = 'Cabecera'
              object lblNroAlbaran: TcxLabel
                Left = 8
                Top = 12
                Caption = 'N'#250'mero'
                TabOrder = 9
                Transparent = True
              end
              object txtNUMERO_ALB: TcxDBTextEdit
                Left = 8
                Top = 32
                DataBinding.DataField = 'NUMERO_ALB'
                DataBinding.DataSource = dsTablaG
                TabOrder = 0
                Width = 100
              end
              object lblSerieAlbaran: TcxLabel
                Left = 116
                Top = 12
                Caption = 'Serie'
                TabOrder = 10
                Transparent = True
              end
              object cbbSERIE_ALB: TcxDBComboBox
                Left = 116
                Top = 32
                DataBinding.DataField = 'SERIE_ALB'
                DataBinding.DataSource = dsTablaG
                Properties.MaxLength = 12
                Properties.OnInitPopup = cbbSERIE_ALBPropertiesInitPopup
                TabOrder = 1
                Width = 80
              end
              object lblFechaAlbaran: TcxLabel
                Left = 204
                Top = 12
                Caption = 'Fecha y hora stock'
                TabOrder = 11
                Transparent = True
              end
              object dteINSTANTEMOVIMIENTO_ALB: TcxDBDateEdit
                Left = 204
                Top = 32
                DataBinding.DataField = 'INSTANTE_MOVIMIENTO_ALB'
                DataBinding.DataSource = dsTablaG
                Properties.DisplayFormat = 'dd/mm/yyyy hh:nn:ss'
                Properties.Kind = ckDateTime
                TabOrder = 2
                Width = 156
              end
              object lblEstadoAlbaran: TcxLabel
                Left = 366
                Top = 12
                Caption = 'Estado'
                TabOrder = 12
                Transparent = True
              end
              object txtESTADO_ALB: TcxDBTextEdit
                Left = 366
                Top = 32
                DataBinding.DataField = 'ESTADO_ALB'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 3
                Width = 110
              end
              object lblPedidoOrigen: TcxLabel
                Left = 486
                Top = 12
                Caption = 'Pedido origen (N'#250'mero / Serie)'
                TabOrder = 13
                Transparent = True
                Visible = False
              end
              object txtNUMERO_PED_ALB: TcxDBTextEdit
                Left = 486
                Top = 32
                DataBinding.DataField = 'NUMERO_PED_ALB'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 4
                Visible = False
                Width = 90
              end
              object txtSERIE_PED_ALB: TcxDBTextEdit
                Left = 586
                Top = 32
                DataBinding.DataField = 'SERIE_PED_ALB'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 5
                Visible = False
                Width = 80
              end
              object btnIrDocumento: TcxButton
                Left = 486
                Top = 56
                Width = 190
                Height = 23
                Action = actIrDocumento
                TabOrder = 18
                Visible = False
              end
              object lblFacturaDestino: TcxLabel
                Left = 686
                Top = 12
                Caption = 'Borrador (N'#250'mero / Serie)'
                TabOrder = 14
                Transparent = True
                Visible = False
              end
              object txtNUMERO_FAC_ALB: TcxDBTextEdit
                Left = 686
                Top = 32
                DataBinding.DataField = 'NUMERO_FAC_ALB'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 6
                Visible = False
                Width = 90
              end
              object txtSERIE_FAC_ALB: TcxDBTextEdit
                Left = 786
                Top = 32
                DataBinding.DataField = 'SERIE_FAC_ALB'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 7
                Visible = False
                Width = 80
              end
              object lblCodigoEmpresa: TcxLabel
                Left = 8
                Top = 80
                Caption = 'Empresa Emisora'
                TabOrder = 15
                Transparent = True
              end
              object btnCODIGO_EMP_ALB: TcxDBButtonEdit
                Left = 8
                Top = 100
                DataBinding.DataField = 'CODIGO_EMP_ALB'
                DataBinding.DataSource = dsTablaG
                Properties.Buttons = <
                  item
                    Default = True
                    Kind = bkEllipsis
                  end>
                Properties.OnButtonClick = btnCODIGO_EMP_ALBPropertiesButtonClick
                Properties.OnEditValueChanged = btnCODIGO_EMP_ALBPropertiesEditValueChanged
                TabOrder = 8
                OnKeyUp = btnCODIGO_EMP_ALBKeyUp
                Width = 130
              end
              object cxdblblRAZON_SOCIAL_EMPRESA_ALB: TcxDBLabel
                Left = 144
                Top = 100
                DataBinding.DataField = 'RAZON_SOCIAL_EMPRESA_ALB'
                DataBinding.DataSource = dsTablaG
                TabOrder = 19
                Transparent = True
                Height = 21
                Width = 380
              end
              object lblCodigoAlmacen: TcxLabel
                Left = 544
                Top = 80
                Caption = 'Almac'#233'n salida'
                TabOrder = 22
                Transparent = True
              end
              object cbbCODIGO_ALM_ALB: TcxDBLookupComboBox
                Left = 544
                Top = 100
                DataBinding.DataField = 'CODIGO_ALM_ALB'
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
                Properties.ListOptions.ShowHeader = False
                Properties.OnEditValueChanged = cbbCODIGO_ALM_ALBPropertiesEditValueChanged
                TabOrder = 23
                Width = 240
              end
              object lblCodigoCliente: TcxLabel
                Left = 8
                Top = 140
                Caption = 'Cliente'
                TabOrder = 16
                Transparent = True
              end
              object btnCODIGO_CLI_ALB: TcxDBButtonEdit
                Left = 8
                Top = 160
                DataBinding.DataField = 'CODIGO_CLI_ALB'
                DataBinding.DataSource = dsTablaG
                Properties.Buttons = <
                  item
                    Default = True
                    Kind = bkEllipsis
                  end>
                Properties.OnButtonClick = btnCODIGO_CLI_ALBPropertiesButtonClick
                Properties.OnEditValueChanged = btnCODIGO_CLI_ALBPropertiesEditValueChanged
                TabOrder = 17
                OnKeyUp = btnCODIGO_CLI_ALBKeyUp
                Width = 130
              end
              object cxdblblRAZON_SOCIAL_CLIENTE_ALB: TcxDBLabel
                Left = 144
                Top = 160
                DataBinding.DataField = 'RAZON_SOCIAL_CLIENTE_ALB'
                DataBinding.DataSource = dsTablaG
                TabOrder = 20
                Transparent = True
                Height = 21
                Width = 380
              end
              object lblVendedorAlbaran: TcxLabel
                Left = 544
                Top = 140
                Caption = 'Vendedor'
                TabOrder = 27
                Transparent = True
              end
              
              object cbbCODIGO_VENDEDOR_ALB: TcxDBLookupComboBox
                Left = 544
                Top = 160
                DataBinding.DataField = 'CODIGO_VENDEDOR_ALB'
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
                TabOrder = 18
                Width = 240
              end
              object lblTarifaAlbaran: TcxLabel
                Left = 792
                Top = 80
                Caption = 'Tarifa'
                TabOrder = 24
                Transparent = True
              end
              object cbbTarifaAlbaran: TcxDBLookupComboBox
                Left = 792
                Top = 100
                DataBinding.DataField = 'TARIFA_ARTICULO_CLIENTE_ALB'
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
                Properties.OnChange = cbbTarifaAlbaranPropertiesChange
                TabOrder = 25
                Width = 132
              end
              object chkTarifaImpuestosIncluidosAlbaran: TcxDBCheckBox
                Left = 792
                Top = 129
                Caption = 'Imp. incl.'
                DataBinding.DataField = 'ESIMP_INCL_TARIFA_CLIENTE_ALB'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                Properties.ValueChecked = 'S'
                Properties.ValueUnchecked = 'N'
                TabOrder = 26
                Transparent = True
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
                object txtNIF_EMPRESA_ALB: TcxDBTextEdit
                  Left = 12
                  Top = 44
                  DataBinding.DataField = 'NIF_EMPRESA_ALB'
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
                object txtMOVIL_EMPRESA_ALB: TcxDBTextEdit
                  Left = 152
                  Top = 44
                  DataBinding.DataField = 'MOVIL_EMPRESA_ALB'
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
                object txtEMAIL_EMPRESA_ALB: TcxDBTextEdit
                  Left = 292
                  Top = 44
                  DataBinding.DataField = 'EMAIL_EMPRESA_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 2
                  Width = 220
                end
                object txtDIRECCION1_EMPRESA_ALB: TcxDBTextEdit
                  Left = 12
                  Top = 84
                  DataBinding.DataField = 'DIRECCION1_EMPRESA_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 3
                  Width = 350
                end
                object txtDIRECCION2_EMPRESA_ALB: TcxDBTextEdit
                  Left = 372
                  Top = 84
                  DataBinding.DataField = 'DIRECCION2_EMPRESA_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 4
                  Width = 250
                end
                object txtPOBLACION_EMPRESA_ALB: TcxDBTextEdit
                  Left = 12
                  Top = 116
                  DataBinding.DataField = 'POBLACION_EMPRESA_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 5
                  Width = 200
                end
                object txtPROVINCIA_EMPRESA_ALB: TcxDBTextEdit
                  Left = 220
                  Top = 116
                  DataBinding.DataField = 'PROVINCIA_EMPRESA_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 6
                  Width = 200
                end
                object txtCODIGO_POSTAL_EMPRESA_ALB: TcxDBTextEdit
                  Left = 428
                  Top = 116
                  DataBinding.DataField = 'CODIGO_POSTAL_EMPRESA_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 7
                  Width = 80
                end
                object txtNOMBRE_PAI_EMPRESA_ALB: TcxDBTextEdit
                  Left = 516
                  Top = 116
                  DataBinding.DataField = 'NOMBRE_PAI_EMPRESA_ALB'
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
                object txtRAZON_SOCIAL_CLIENTE_ALB: TcxDBTextEdit
                  Left = 12
                  Top = 24
                  DataBinding.DataField = 'RAZON_SOCIAL_CLIENTE_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 0
                  Width = 320
                end
                object txtNIF_CLIENTE_ALB: TcxDBTextEdit
                  Left = 342
                  Top = 24
                  DataBinding.DataField = 'NIF_CLIENTE_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 1
                  Width = 130
                end
                object txtEMAIL_CLIENTE_ALB: TcxDBTextEdit
                  Left = 482
                  Top = 24
                  DataBinding.DataField = 'EMAIL_CLIENTE_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 2
                  Width = 220
                end
                object txtMOVIL_CLIENTE_ALB: TcxDBTextEdit
                  Left = 712
                  Top = 24
                  DataBinding.DataField = 'MOVIL_CLIENTE_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 3
                  Width = 130
                end
                object txtDIRECCION1_CLIENTE_ALB: TcxDBTextEdit
                  Left = 12
                  Top = 60
                  DataBinding.DataField = 'DIRECCION1_CLIENTE_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 4
                  Width = 350
                end
                object txtDIRECCION2_CLIENTE_ALB: TcxDBTextEdit
                  Left = 372
                  Top = 60
                  DataBinding.DataField = 'DIRECCION2_CLIENTE_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 5
                  Width = 250
                end
                object txtPOBLACION_CLIENTE_ALB: TcxDBTextEdit
                  Left = 12
                  Top = 96
                  DataBinding.DataField = 'POBLACION_CLIENTE_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 6
                  Width = 200
                end
                object txtPROVINCIA_CLIENTE_ALB: TcxDBTextEdit
                  Left = 220
                  Top = 96
                  DataBinding.DataField = 'PROVINCIA_CLIENTE_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 7
                  Width = 200
                end
                object txtCODIGO_POSTAL_CLIENTE_ALB: TcxDBTextEdit
                  Left = 428
                  Top = 96
                  DataBinding.DataField = 'CODIGO_POSTAL_CLIENTE_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 8
                  Width = 80
                end
                object txtNOMBRE_PAI_CLIENTE_ALB: TcxDBTextEdit
                  Left = 516
                  Top = 96
                  DataBinding.DataField = 'NOMBRE_PAI_CLIENTE_ALB'
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
                object txtNOMBRE_CLI_ENVIO_ALB: TcxDBTextEdit
                  Left = 12
                  Top = 24
                  DataBinding.DataField = 'NOMBRE_CLI_ENVIO_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 0
                  Width = 320
                end
                object txtMOVIL_CLIENTE_ENVIO_ALB: TcxDBTextEdit
                  Left = 342
                  Top = 24
                  DataBinding.DataField = 'MOVIL_CLIENTE_ENVIO_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 1
                  Width = 130
                end
                object txtDIRECCION1_CLIENTE_ENVIO_ALB: TcxDBTextEdit
                  Left = 12
                  Top = 60
                  DataBinding.DataField = 'DIRECCION1_CLIENTE_ENVIO_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 2
                  Width = 350
                end
                object txtDIRECCION2_CLIENTE_ENVIO_ALB: TcxDBTextEdit
                  Left = 372
                  Top = 60
                  DataBinding.DataField = 'DIRECCION2_CLIENTE_ENVIO_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 3
                  Width = 250
                end
                object txtPOBLACION_CLIENTE_ENVIO_ALB: TcxDBTextEdit
                  Left = 12
                  Top = 96
                  DataBinding.DataField = 'POBLACION_CLIENTE_ENVIO_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 4
                  Width = 200
                end
                object txtPROVINCIA_CLIENTE_ENVIO_ALB: TcxDBTextEdit
                  Left = 220
                  Top = 96
                  DataBinding.DataField = 'PROVINCIA_CLIENTE_ENVIO_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 5
                  Width = 200
                end
                object txtCODIGO_POSTAL_CLIENTE_ENVIO_ALB: TcxDBTextEdit
                  Left = 428
                  Top = 96
                  DataBinding.DataField = 'CODIGO_POSTAL_CLIENTE_ENVIO_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 6
                  Width = 80
                end
                object txtNOMBRE_PAI_CLIENTE_ENVIO_ALB: TcxDBTextEdit
                  Left = 516
                  Top = 96
                  DataBinding.DataField = 'NOMBRE_PAI_CLIENTE_ENVIO_ALB'
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
          Top = 238
          Width = 937
          Height = 40
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 1
          object btnAnadirLinea: TcxButton
            Left = 4
            Top = 6
            Width = 110
            Height = 28
            Caption = 'A'#241'adir l'#237'nea'
            TabOrder = 0
            OnClick = btnAnadirLineaClick
          end
          object btnBorrarLinea: TcxButton
            Left = 118
            Top = 6
            Width = 110
            Height = 28
            Caption = 'Borrar l'#237'nea'
            TabOrder = 1
            OnClick = btnBorrarLineaClick
          end
          object btnFacturarSeleccionadas: TcxButton
            Left = 240
            Top = 6
            Width = 197
            Height = 28
            Caption = 'Crear borr. l'#237'neas selec.'
            TabOrder = 2
            OnClick = btnFacturarSeleccionadasClick
          end
          object btnFacturarTodo: TcxButton
            Left = 443
            Top = 6
            Width = 150
            Height = 28
            Caption = 'Crear borr albar'#225'n'
            TabOrder = 3
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Source Sans 3'
            Font.Style = [fsBold]
            ParentFont = False
            OnClick = btnFacturarTodoClick
          end
          object btnFacturarPorFechas: TcxButton
            Left = 599
            Top = 6
            Width = 225
            Height = 28
            Caption = 'Crear borr por fechas / serie'
            TabOrder = 4
            OnClick = btnFacturarPorFechasClick
          end
        end
        object pnlBodyFicha: TPanel
          Left = 0
          Top = 278
          Width = 937
          Height = 375
          Align = alClient
          BevelOuter = bvNone
          TabOrder = 2
          object pcAlbaran: TcxPageControl
            Left = 0
            Top = 0
            Width = 937
            Height = 383
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsLineasAlbaran
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 379
            ClientRectLeft = 4
            ClientRectRight = 933
            ClientRectTop = 28
            object tsLineasAlbaran: TcxTabSheet
              Caption = '&1_L'#237'neas Albar'#225'n'
              object cxgrdLineasAlbaran: TcxGrid
                Left = 0
                Top = 0
                Width = 929
                Height = 351
                Align = alClient
                TabOrder = 0
                object tvLineasAlbaran: TcxGridDBTableView
                  OptionsSelection.MultiSelect = True
                  OptionsView.Footer = False
                  OptionsView.GroupByBox = False
                  object cxgrdcLineaAlb: TcxGridDBColumn
                    Caption = 'L'#237'nea'
                    DataBinding.FieldName = 'LINEA_ALBLIN'
                    Width = 60
                  end
                  object cxgrdcArtAlb: TcxGridDBColumn
                    Caption = 'C'#243'digo Art'#237'culo'
                    DataBinding.FieldName = 'CODIGO_ART_ALBLIN'
                    PropertiesClassName = 'TcxButtonEditProperties'
                    Properties.Buttons = <
                      item
                        Default = True
                        Kind = bkEllipsis
                      end>
                    Properties.OnButtonClick = cxgrdcArtAlbPropertiesButtonClick
                    Properties.OnValidate = cxgrdcArtAlbPropertiesValidate
                    Width = 130
                  end
                  object cxgrdcSkuAlb: TcxGridDBColumn
                    Caption = 'SKU'
                    DataBinding.FieldName = 'CODIGO_UNIDAD_ALBLIN'
                    Visible = False
                    Width = 150
                  end
                  object cxgrdcVarAlb: TcxGridDBColumn
                    Caption = 'Variaci'#243'n'
                    DataBinding.FieldName = 'DESCRIPCION_VARIACION_ALBLIN'
                    Visible = False
                    Width = 160
                  end
                  object cxgrdcDescrAlb: TcxGridDBColumn
                    Caption = 'Descripci'#243'n'
                    DataBinding.FieldName = 'DESCRIPCION_ARTICULO_ALBLIN'
                    Width = 240
                  end
                  object cxgrdcLoteAlb: TcxGridDBColumn
                    Caption = 'Lote'
                    DataBinding.FieldName = 'LOTE_ALBLIN'
                    Visible = False
                    Width = 90
                  end
                  object cxgrdcCadAlb: TcxGridDBColumn
                    Caption = 'Caducidad'
                    DataBinding.FieldName = 'FECHA_CADUCIDAD_ALBLIN'
                    Visible = False
                    Width = 100
                  end
                  object cxgrdcCantAlb: TcxGridDBColumn
                    Caption = 'Cantidad'
                    DataBinding.FieldName = 'CANTIDAD_ALBLIN'
                    Width = 80
                  end
                  object colTipoCantAlb: TcxGridDBColumn
                    DataBinding.FieldName = 'TIPO_CANTIDAD_ARTICULO_ALBLIN'
                    Visible = False
                    VisibleForCustomization = False
                  end
                  object cxgrdcPSivaAlb: TcxGridDBColumn
                    Caption = 'PVP S/IVA'
                    DataBinding.FieldName = 'PRECIO_VENTA_SIVA_ARTICULO_ALBLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Width = 90
                  end
                  object cxgrdcPCivaAlb: TcxGridDBColumn
                    Caption = 'PVP C/IVA'
                    DataBinding.FieldName = 'PRECIO_VENTA_CIVA_ARTICULO_ALBLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Width = 90
                  end
                  object cxgrdcTotalAlb: TcxGridDBColumn
                    Caption = 'Total'
                    DataBinding.FieldName = 'TOTAL_ALBLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Width = 100
                  end
                  object cxgrdcEsFactAlb: TcxGridDBColumn
                    Caption = 'Con borrador?'
                    DataBinding.FieldName = 'ESFACTURADA_ALBLIN'
                    Options.Editing = False
                    Width = 90
                  end
                  object cxgrdcNumFacAlb: TcxGridDBColumn
                    Caption = 'Borrador'
                    DataBinding.FieldName = 'NUMERO_FAC_ALBLIN'
                    Options.Editing = False
                    Width = 90
                  end
                  object cxgrdcSerFacAlb: TcxGridDBColumn
                    Caption = 'Serie Fac.'
                    DataBinding.FieldName = 'SERIE_FAC_ALBLIN'
                    Options.Editing = False
                    Width = 80
                  end
                  object cxgrdcPedAlb: TcxGridDBColumn
                    Caption = 'L'#237'nea Pedido'
                    DataBinding.FieldName = 'LINEA_PED_ALBLIN'
                    Width = 90
                  end
                end
                object cxgrdlvlLineasAlbaran: TcxGridLevel
                  GridView = tvLineasAlbaran
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
                Height = 351
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
                object spnVentaPORCENTAJE_DTO_COMERCIAL_ALB: TcxDBSpinEdit
                  Left = 185
                  Top = 240
                  DataBinding.DataField = 'PORCENTAJE_DTO_COMERCIAL_ALB'
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
                object curVentaTOTAL_DTO_COMERCIAL_ALB: TcxDBCurrencyEdit
                  Left = 272
                  Top = 240
                  DataBinding.DataField = 'TOTAL_DTO_COMERCIAL_ALB'
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
                object spnVentaPORCENTAJE_DTO_FINANCIERO_ALB: TcxDBSpinEdit
                  Left = 185
                  Top = 270
                  DataBinding.DataField = 'PORCENTAJE_DTO_FINANCIERO_ALB'
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
                object curVentaTOTAL_DTO_FINANCIERO_ALB: TcxDBCurrencyEdit
                  Left = 272
                  Top = 270
                  DataBinding.DataField = 'TOTAL_DTO_FINANCIERO_ALB'
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
                object curTotalesTOTAL_BASES_ALB: TcxDBCurrencyEdit
                  Left = 230
                  Top = 18
                  DataBinding.DataField = 'TOTAL_BASES_ALB'
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
                object curTotalesTOTAL_IMPUESTOS_ALB: TcxDBCurrencyEdit
                  Left = 230
                  Top = 50
                  DataBinding.DataField = 'TOTAL_IMPUESTOS_ALB'
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
                object spnTotalesPORCENTAJE_RETENCION_ALB: TcxDBSpinEdit
                  Left = 230
                  Top = 82
                  DataBinding.DataField = 'PORCENTAJE_RETENCION_ALB'
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
                object curTotalesTOTAL_RETENCION_ALB: TcxDBCurrencyEdit
                  Left = 230
                  Top = 114
                  DataBinding.DataField = 'TOTAL_RETENCION_ALB'
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
                object curTotalesTOTAL_LIQUIDO_ALB: TcxDBCurrencyEdit
                  Left = 230
                  Top = 146
                  DataBinding.DataField = 'TOTAL_LIQUIDO_ALB'
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
                object cbbTotalesFORMA_PAGO_ALB: TcxDBLookupComboBox
                  Left = 230
                  Top = 178
                  DataBinding.DataField = 'FORMA_PAGO_ALB'
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
                object chkTotalesESIVA_RECARGO_CLIENTE_ALB: TcxDBCheckBox
                  Left = 56
                  Top = 210
                  Caption = 'Recargo equivalencia cliente'
                  DataBinding.DataField = 'ESIVA_RECARGO_CLIENTE_ALB'
                  DataBinding.DataSource = dsTablaG
                  Properties.ValueChecked = 'S'
                  Properties.ValueUnchecked = 'N'
                  Style.TransparentBorder = False
                  TabOrder = 12
                  Transparent = True
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
                  TabOrder = 13
                  Transparent = True
                end
                object lblTotalPrendasAlb: TcxLabel
                  Properties.Alignment.Vert = taVCenter
                  Properties.Alignment.Horz = taRightJustify
                  Left = 230
                  Top = 300
                  AutoSize = False
                  Caption = '0'
                  TabOrder = 14
                  Transparent = True
                  Height = 24
                  Width = 133
                end
                object grpDesgloseImpuestos: TcxGroupBox
                  Left = 384
                  Top = 10
                  Width = 525
                  Height = 280
                  Caption = 'Desglose Impuestos'
                  TabOrder = 15
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
                    Caption = 'Base neta'
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
                  object curTotalesTOTAL_BASEI_IVAN_ALB: TcxDBCurrencyEdit
                    Left = 145
                    Top = 80
                    DataBinding.DataField = 'TOTAL_BASEI_IVAN_ALB'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 9
                    Width = 92
                  end
                  object curTotalesTOTAL_BASEI_IVAR_ALB: TcxDBCurrencyEdit
                    Left = 145
                    Top = 128
                    DataBinding.DataField = 'TOTAL_BASEI_IVAR_ALB'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 10
                    Width = 92
                  end
                  object curTotalesTOTAL_BASEI_IVAS_ALB: TcxDBCurrencyEdit
                    Left = 145
                    Top = 176
                    DataBinding.DataField = 'TOTAL_BASEI_IVAS_ALB'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 11
                    Width = 92
                  end
                  object curTotalesTOTAL_BASEI_IVAE_ALB: TcxDBCurrencyEdit
                    Left = 145
                    Top = 224
                    DataBinding.DataField = 'TOTAL_BASEI_IVAE_ALB'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 12
                    Width = 92
                  end
                  object curTotalesTOTAL_IVAN_ALB: TcxDBCurrencyEdit
                    Left = 296
                    Top = 80
                    DataBinding.DataField = 'TOTAL_IVAN_ALB'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 13
                    Width = 86
                  end
                  object curTotalesTOTAL_IVAR_ALB: TcxDBCurrencyEdit
                    Left = 296
                    Top = 128
                    DataBinding.DataField = 'TOTAL_IVAR_ALB'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 14
                    Width = 86
                  end
                  object curTotalesTOTAL_IVAS_ALB: TcxDBCurrencyEdit
                    Left = 296
                    Top = 176
                    DataBinding.DataField = 'TOTAL_IVAS_ALB'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 15
                    Width = 86
                  end
                  object curTotalesTOTAL_IVAE_ALB: TcxDBCurrencyEdit
                    Left = 296
                    Top = 224
                    DataBinding.DataField = 'TOTAL_IVAE_ALB'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 16
                    Width = 86
                  end
                  object curTotalesTOTAL_REN_ALB: TcxDBCurrencyEdit
                    Left = 442
                    Top = 80
                    DataBinding.DataField = 'TOTAL_REN_ALB'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 17
                    Width = 75
                  end
                  object curTotalesTOTAL_RER_ALB: TcxDBCurrencyEdit
                    Left = 442
                    Top = 128
                    DataBinding.DataField = 'TOTAL_RER_ALB'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 18
                    Width = 75
                  end
                  object curTotalesTOTAL_RES_ALB: TcxDBCurrencyEdit
                    Left = 442
                    Top = 176
                    DataBinding.DataField = 'TOTAL_RES_ALB'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 19
                    Width = 75
                  end
                  object curTotalesTOTAL_REE_ALB: TcxDBCurrencyEdit
                    Left = 442
                    Top = 224
                    DataBinding.DataField = 'TOTAL_REE_ALB'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 20
                    Width = 75
                  end
                  object spnTotalesPORCENTAJE_IVAN_ALB: TcxDBSpinEdit
                    Left = 238
                    Top = 80
                    DataBinding.DataField = 'PORCENTAJE_IVAN_ALB'
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
                  object spnTotalesPORCENTAJE_IVAR_ALB: TcxDBSpinEdit
                    Left = 238
                    Top = 128
                    DataBinding.DataField = 'PORCENTAJE_IVAR_ALB'
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
                  object spnTotalesPORCENTAJE_IVAS_ALB: TcxDBSpinEdit
                    Left = 238
                    Top = 176
                    DataBinding.DataField = 'PORCENTAJE_IVAS_ALB'
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
                  object spnTotalesPORCENTAJE_IVAE_ALB: TcxDBSpinEdit
                    Left = 238
                    Top = 224
                    DataBinding.DataField = 'PORCENTAJE_IVAE_ALB'
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
                  object spnTotalesPORCENTAJE_REN_ALB: TcxDBSpinEdit
                    Left = 388
                    Top = 80
                    DataBinding.DataField = 'PORCENTAJE_REN_ALB'
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
                  object spnTotalesPORCENTAJE_RER_ALB: TcxDBSpinEdit
                    Left = 388
                    Top = 128
                    DataBinding.DataField = 'PORCENTAJE_RER_ALB'
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
                  object spnTotalesPORCENTAJE_RES_ALB: TcxDBSpinEdit
                    Left = 388
                    Top = 176
                    DataBinding.DataField = 'PORCENTAJE_RES_ALB'
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
                  object spnTotalesPORCENTAJE_REE_ALB: TcxDBSpinEdit
                    Left = 388
                    Top = 224
                    DataBinding.DataField = 'PORCENTAJE_REE_ALB'
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
            object tsFacturas: TcxTabSheet
              Caption = '&3_Borradores'
              object pnlBorradoresAcciones: TcxGroupBox
                Left = 784
                Top = 0
                Align = alRight
                PanelStyle.Active = True
                Style.BorderStyle = ebsNone
                TabOrder = 1
                Height = 351
                Width = 145
                object btnIrFacturaCreada: TcxButton
                  Left = 5
                  Top = 5
                  Width = 135
                  Height = 28
                  Action = actIrFacturaCreada
                  TabOrder = 0
                end
              end
              object cxGrdFacturas: TcxGrid
                Left = 0
                Top = 0
                Width = 784
                Height = 351
                Align = alClient
                TabOrder = 0
                object tvFacturas: TcxGridDBTableView
                  OptionsData.Deleting = False
                  OptionsData.Editing = False
                  OptionsData.Inserting = False
                  OptionsView.GroupByBox = False
                  object cxgrdcFacNum: TcxGridDBColumn
                    Caption = 'N'#250'mero'
                    DataBinding.FieldName = 'NUMERO_FAC'
                    Width = 100
                  end
                  object cxgrdcFacSer: TcxGridDBColumn
                    Caption = 'Serie'
                    DataBinding.FieldName = 'SERIE_FAC'
                    Width = 80
                  end
                  object cxgrdcFacFec: TcxGridDBColumn
                    Caption = 'Fecha'
                    DataBinding.FieldName = 'FECHA_FAC'
                    Width = 110
                  end
                  object cxgrdcFacFase: TcxGridDBColumn
                    Caption = 'Fase'
                    DataBinding.FieldName = 'FASE_FAC'
                    Width = 110
                  end
                  object cxgrdcFacTot: TcxGridDBColumn
                    Caption = 'Total'
                    DataBinding.FieldName = 'TOTAL_LIQUIDO_FAC'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Width = 110
                  end
                end
                object cxGrdFacturasLevel: TcxGridLevel
                  GridView = tvFacturas
                end
              end
            end
            object tsMovimientos: TcxTabSheet
              Caption = '&4_Movimientos'
              object cxGrdMovimientos: TcxGrid
                Left = 0
                Top = 0
                Width = 929
                Height = 351
                Align = alClient
                TabOrder = 0
                object tvMovimientos: TcxGridDBTableView
                  OptionsData.Editing = False
                  OptionsView.GroupByBox = False
                  object cxgrdcMovNum: TcxGridDBColumn
                    Caption = 'N'#250'mero Mov.'
                    DataBinding.FieldName = 'NUMERO_MOV'
                    Width = 110
                  end
                  object cxgrdcMovFec: TcxGridDBColumn
                    Caption = 'Fecha'
                    DataBinding.FieldName = 'FECHA_MOV'
                    Width = 130
                  end
                  object cxgrdcMovLin: TcxGridDBColumn
                    Caption = 'L'#237'nea'
                    DataBinding.FieldName = 'LINEA_MOV'
                    Width = 60
                  end
                  object cxgrdcMovAlm: TcxGridDBColumn
                    Caption = 'Almac'#233'n'
                    DataBinding.FieldName = 'NOMBRE_ALMACEN_ORIGEN'
                    Width = 140
                  end
                  object cxgrdcMovArt: TcxGridDBColumn
                    Caption = 'Art'#237'culo'
                    DataBinding.FieldName = 'CODIGO_ART_MOV'
                    Width = 100
                  end
                  object cxgrdcMovSku: TcxGridDBColumn
                    Caption = 'SKU'
                    DataBinding.FieldName = 'CODIGO_UNIDAD_MOV'
                    Width = 140
                  end
                  object cxgrdcMovDescr: TcxGridDBColumn
                    Caption = 'Descripci'#243'n'
                    DataBinding.FieldName = 'DESCRIPCION_ARTICULO_MOV'
                    Width = 200
                  end
                  object cxgrdcMovTipo: TcxGridDBColumn
                    Caption = 'Tipo'
                    DataBinding.FieldName = 'TIPO_MOV'
                    Width = 50
                  end
                  object cxgrdcMovCant: TcxGridDBColumn
                    Caption = 'Cantidad'
                    DataBinding.FieldName = 'CANTIDAD_MOV'
                    Width = 90
                  end
                  object cxgrdcMovPMP: TcxGridDBColumn
                    Caption = 'PMP'
                    DataBinding.FieldName = 'PRECIO_MEDIO_MOV'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Width = 90
                  end
                  object cxgrdcMovTot: TcxGridDBColumn
                    Caption = 'Total Coste'
                    DataBinding.FieldName = 'TOTAL_COSTE_MOV'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Width = 100
                  end
                end
                object cxGrdMovimientosLevel: TcxGridLevel
                  GridView = tvMovimientos
                end
              end
            end
            object tsObservaciones: TcxTabSheet
              Caption = '&5_Observaciones'
              object memObservaciones: TcxDBMemo
                Left = 0
                Top = 0
                Align = alClient
                DataBinding.DataField = 'OBSERVACIONES_ALB'
                DataBinding.DataSource = dsTablaG
                TabOrder = 0
                Height = 351
                Width = 929
              end
            end
          end
        end
        object pnlBottomTotales: TPanel
          Left = 0
          Top = 653
          Width = 937
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
          object curTOTAL_BASES_ALB: TcxDBCurrencyEdit
            Left = 425
            Top = 8
            DataBinding.DataField = 'TOTAL_BASES_ALB'
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
          object curTOTAL_IMPUESTOS_ALB: TcxDBCurrencyEdit
            Left = 570
            Top = 8
            DataBinding.DataField = 'TOTAL_IMPUESTOS_ALB'
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
          object curTOTAL_LIQUIDO_ALB: TcxDBCurrencyEdit
            Left = 740
            Top = 8
            DataBinding.DataField = 'TOTAL_LIQUIDO_ALB'
            DataBinding.DataSource = dsTablaG
            Properties.DisplayFormat = '#,##0.00 '#8364
            Properties.ReadOnly = True
            TabOrder = 2
            Width = 130
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
    object btnImprimir: TcxButton
      Left = 2
      Top = 338
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
    object actIrFacturaCreada: TAction
      Caption = 'Ir a borrador'
      Enabled = False
      OnExecute = actIrFacturaCreadaExecute
      OnUpdate = actIrFacturaCreadaUpdate
    end
  end
end
