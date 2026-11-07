inherited frmMtoCajaPagosHist: TfrmMtoCajaPagosHist
  Caption = 'Hist'#243'rico de Pagos de Caja'
  TextHeight = 19
  inherited pButtonPage: TPanel
    inherited pcPantalla: TcxPageControl
      Properties.ActivePage = tsLista
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 30
        ExplicitWidth = 943
        ExplicitHeight = 484
        inherited cxGrdPrincipal: TcxGrid
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            OptionsData.Editing = True
            object cxGrdDBTabPrinCODIGO_EMPRESA_PAGO: TcxGridDBColumn
              Caption = 'Empresa'
              DataBinding.FieldName = 'CODIGO_EMP_PAGO'
              Width = 90
            end
            object cxGrdDBTabPrinCODIGO_ALMACEN_PAGO: TcxGridDBColumn
              Caption = 'Almac'#233'n'
              DataBinding.FieldName = 'CODIGO_ALM_PAGO'
              Width = 90
            end
            object cxGrdDBTabPrinCODIGO_CAJA_PAGO: TcxGridDBColumn
              Caption = 'Caja'
              DataBinding.FieldName = 'CODIGO_CAJA_PAGO'
              Width = 70
            end
            object cxGrdDBTabPrinSERIE_OPERACION_PAGO: TcxGridDBColumn
              Caption = 'Serie Op.'
              DataBinding.FieldName = 'SERIE_OPERACION_PAGO'
              Width = 90
            end
            object cxGrdDBTabPrinNUMERO_OPERACION_PAGO: TcxGridDBColumn
              Caption = 'N'#250'mero Op.'
              DataBinding.FieldName = 'NUMERO_OPERACION_PAGO'
              Width = 130
            end
            object cxGrdDBTabPrinNUMERO_LINEA_PAGO: TcxGridDBColumn
              Caption = 'L'#237'nea'
              DataBinding.FieldName = 'NUMERO_LINEA_PAGO'
              Width = 70
            end
            object cxGrdDBTabPrinFECHA_PAGO: TcxGridDBColumn
              Caption = 'Fecha Pago'
              DataBinding.FieldName = 'FECHA_PAGO'
              Options.Editing = False
              Width = 160
            end
            object cxGrdDBTabPrinCODIGO_FORMAP: TcxGridDBColumn
              Caption = 'Forma de Pago'
              DataBinding.FieldName = 'CODIGO_FP_CFP'
              Width = 120
            end
            object cxGrdDBTabPrinDESCRIPCION_FORMAP: TcxGridDBColumn
              Caption = 'Descripci'#243'n Forma de Pago'
              DataBinding.FieldName = 'DESCRIPCION_FP_PAGO'
              Width = 200
            end
            object cxGrdDBTabPrinCODIGO_DIVISA_PAGO: TcxGridDBColumn
              Caption = 'Divisa'
              DataBinding.FieldName = 'CODIGO_DIVISA_PAGO'
              Width = 80
            end
            object cxGrdDBTabPrinRED_BLOCKCHAIN: TcxGridDBColumn
              Caption = 'Red Blockchain'
              DataBinding.FieldName = 'RED_BLOCKCHAIN_PAGO'
              Width = 130
            end
            object cxGrdDBTabPrinFACTOR_CAMBIO_PAGO: TcxGridDBColumn
              Caption = 'Factor Cambio'
              DataBinding.FieldName = 'FACTOR_CAMBIO_PAGO'
              Width = 110
            end
            object cxGrdDBTabPrinIMPORTE_DIVISA_PAGO: TcxGridDBColumn
              Caption = 'Importe Divisa'
              DataBinding.FieldName = 'IMPORTE_DIVISA_PAGO'
              Width = 120
            end
            object cxGrdDBTabPrinIMPORTE_ENTREGADO_PAGO: TcxGridDBColumn
              Caption = 'Importe Entregado'
              DataBinding.FieldName = 'IMPORTE_ENTREGADO_PAGO'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 130
            end
            object cxGrdDBTabPrinIMPORTE_CAMBIO_PAGO: TcxGridDBColumn
              Caption = 'Importe Cambio'
              DataBinding.FieldName = 'IMPORTE_CAMBIO_PAGO'
              Width = 120
            end
            object cxGrdDBTabPrinREFERENCIA_PAGO: TcxGridDBColumn
              Caption = 'Referencia'
              DataBinding.FieldName = 'REFERENCIA_FACPAG'
              Width = 200
            end
            object cxGrdDBTabPrinOBSERVACIONES_PAGO: TcxGridDBColumn
              Caption = 'Observaciones'
              DataBinding.FieldName = 'OBSERVACIONES_PAGO'
              Width = 200
            end
            object cxGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn
              Caption = 'Instante Alta'
              DataBinding.FieldName = 'INSTANTE_ALTA'
              Options.Editing = False
              Width = 150
            end
            object cxGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn
              Caption = 'Instante Modif'
              DataBinding.FieldName = 'INSTANTE_MODIF'
              Options.Editing = False
              Visible = False
              Width = 150
            end
            object cxGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn
              Caption = 'Usuario Alta'
              DataBinding.FieldName = 'USUARIO_ALTA'
              Options.Editing = False
              Width = 130
            end
          end
        end
        object pnlFiltrosCaja: TPanel
          Left = 0
          Top = 0
          Width = 943
          Height = 60
          Align = alTop
          BevelOuter = bvNone
          ParentBackground = False
          TabOrder = 1
          object btnToggleFiltrosCaja: TcxButton
            Left = 0
            Top = 0
            Width = 943
            Height = 22
            Align = alTop
            Caption = #9654'  Filtros de carga'
            LookAndFeel.Kind = lfUltraFlat
            LookAndFeel.NativeStyle = False
            TabOrder = 0
            OnClick = btnToggleFiltrosCajaClick
          end
          object pnlContFiltrosCaja: TPanel
            Left = 0
            Top = 22
            Width = 943
            Height = 38
            Align = alClient
            BevelOuter = bvNone
            ParentBackground = False
            TabOrder = 1
            object lblFiltroAnyo: TcxLabel
              Left = 16
              Top = 8
              Caption = 'A'#241'os:'
              TabOrder = 3
              Transparent = True
            end
            object ccbFiltroAnyo: TcxCheckComboBox
              Left = 80
              Top = 5
              Properties.EditValueFormat = cvfStatesString
              Properties.EmptySelectionText = 'Todos'
              Properties.Items = <>
              Properties.OnCloseUp = ccbFiltroAnyoPropertiesCloseUp
              TabOrder = 0
              Width = 210
            end
            object btnCargarPagos: TcxButton
              Left = 312
              Top = 4
              Width = 95
              Height = 25
              Caption = 'Cargar'
              TabOrder = 1
              OnClick = btnCargarPagosClick
            end
            object btnGuardarPrecargaCaja: TcxButton
              Left = 416
              Top = 4
              Width = 139
              Height = 25
              Caption = 'Guardar precarga'
              TabOrder = 2
              OnClick = btnGuardarPrecargaCajaClick
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        Caption = '&Ficha'
        TabVisible = True
        object pcFichaDetalle: TcxPageControl
          Left = 0
          Top = 110
          Width = 943
          Height = 374
          Align = alClient
          TabOrder = 1
          Properties.ActivePage = tsFichaPago
          Properties.CustomButtons.Buttons = <>
          OnChange = pcFichaDetalleChange
          ClientRectBottom = 374
          ClientRectRight = 943
          ClientRectTop = 24
          object tsFichaPago: TcxTabSheet
            Caption = '&1_Pago'
            ImageIndex = 0
            object lblDivisa: TcxLabel
              Left = 16
              Top = 19
              Caption = 'Divisa'
              Transparent = True
            end
            object edtDivisa: TcxDBTextEdit
              Left = 150
              Top = 16
              DataBinding.DataField = 'CODIGO_DIVISA_PAGO'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = True
              TabStop = False
              Width = 230
            end
            object lblImporteDivisa: TcxLabel
              Left = 400
              Top = 19
              Caption = 'Importe divisa'
              Transparent = True
            end
            object edtImporteDivisa: TcxDBTextEdit
              Left = 534
              Top = 16
              DataBinding.DataField = 'IMPORTE_DIVISA_PAGO'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = True
              TabStop = False
              Width = 250
            end
            object lblFactor: TcxLabel
              Left = 16
              Top = 47
              Caption = 'Factor de cambio'
              Transparent = True
            end
            object edtFactor: TcxDBTextEdit
              Left = 150
              Top = 44
              DataBinding.DataField = 'FACTOR_CAMBIO_PAGO'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = True
              TabStop = False
              Width = 230
            end
            object lblRedBlockchain: TcxLabel
              Left = 400
              Top = 47
              Caption = 'Red blockchain'
              Transparent = True
            end
            object edtRedBlockchain: TcxDBTextEdit
              Left = 534
              Top = 44
              DataBinding.DataField = 'RED_BLOCKCHAIN_PAGO'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = True
              TabStop = False
              Width = 250
            end
            object lblObservaciones: TcxLabel
              Left = 16
              Top = 75
              Caption = 'Observaciones'
              Transparent = True
            end
            object edtObservaciones: TcxDBTextEdit
              Left = 150
              Top = 72
              DataBinding.DataField = 'OBSERVACIONES_PAGO'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = True
              TabStop = False
              Width = 614
            end
            object lblUsuarioAlta: TcxLabel
              Left = 16
              Top = 103
              Caption = 'Usuario de alta'
              Transparent = True
            end
            object edtUsuarioAlta: TcxDBTextEdit
              Left = 150
              Top = 100
              DataBinding.DataField = 'USUARIO_ALTA'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = True
              TabStop = False
              Width = 230
            end
            object lblInstanteAlta: TcxLabel
              Left = 400
              Top = 103
              Caption = 'Alta'
              Transparent = True
            end
            object edtInstanteAlta: TcxDBTextEdit
              Left = 534
              Top = 100
              DataBinding.DataField = 'INSTANTE_ALTA'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = True
              TabStop = False
              Width = 250
            end
            object lblInstanteModif: TcxLabel
              Left = 16
              Top = 131
              Caption = 'Modificaci'#243'n'
              Transparent = True
            end
            object edtInstanteModif: TcxDBTextEdit
              Left = 150
              Top = 128
              DataBinding.DataField = 'INSTANTE_MODIF'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = True
              TabStop = False
              Width = 230
            end
          end
          object tsFichaOperacion: TcxTabSheet
            Caption = '&2_Operaci'#243'n de caja'
            ImageIndex = 1
            object lblOpNumero: TcxLabel
              Left = 16
              Top = 19
              Caption = 'N'#250'mero'
              Transparent = True
            end
            object edtOpNumero: TcxDBTextEdit
              Left = 150
              Top = 16
              DataBinding.DataField = 'NUMERO_OPERACION_PAGO'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = True
              TabStop = False
              Width = 230
            end
            object lblOpSerie: TcxLabel
              Left = 400
              Top = 19
              Caption = 'Serie'
              Transparent = True
            end
            object edtOpSerie: TcxDBTextEdit
              Left = 534
              Top = 16
              DataBinding.DataField = 'SERIE_OPERACION_PAGO'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = True
              TabStop = False
              Width = 250
            end
            object lblOpTipo: TcxLabel
              Left = 16
              Top = 47
              Caption = 'Tipo'
              Transparent = True
            end
            object edtOpTipo: TcxDBTextEdit
              Left = 150
              Top = 44
              DataBinding.DataField = 'TIPO_OPERACION_PAGO'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = True
              TabStop = False
              Width = 230
            end
            object lblOpEmpleado: TcxLabel
              Left = 400
              Top = 47
              Caption = 'Empleado'
              Transparent = True
            end
            object edtOpEmpleado: TcxDBTextEdit
              Left = 534
              Top = 44
              DataBinding.DataField = 'EMPLEADO_PAGO'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = True
              TabStop = False
              Width = 250
            end
            object lblOpCliente: TcxLabel
              Left = 16
              Top = 75
              Caption = 'Cliente'
              Transparent = True
            end
            object edtOpCliente: TcxDBTextEdit
              Left = 150
              Top = 72
              DataBinding.DataField = 'CODIGO_CLI_PAGO'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = True
              TabStop = False
              Width = 230
            end
            object lblOpImporte: TcxLabel
              Left = 400
              Top = 75
              Caption = 'Importe total'
              Transparent = True
            end
            object edtOpImporte: TcxDBCurrencyEdit
              Left = 534
              Top = 72
              DataBinding.DataField = 'IMPORTE_OPERACION_PAGO'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = True
              Properties.DisplayFormat = '#,##0.00 '#8364
              TabStop = False
              Width = 250
            end
            object lblOpArqueo: TcxLabel
              Left = 16
              Top = 103
              Caption = 'Arqueo'
              Transparent = True
            end
            object edtOpArqueo: TcxDBTextEdit
              Left = 150
              Top = 100
              DataBinding.DataField = 'ARQUEO_PAGO'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = True
              TabStop = False
              Width = 230
            end
            object lblOpSerieOrigen: TcxLabel
              Left = 400
              Top = 103
              Caption = 'Serie de origen'
              Transparent = True
            end
            object edtOpSerieOrigen: TcxDBTextEdit
              Left = 534
              Top = 100
              DataBinding.DataField = 'SERIE_ORIGEN_PAGO'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = True
              TabStop = False
              Width = 250
            end
            object lblOpNumeroOrigen: TcxLabel
              Left = 16
              Top = 131
              Caption = 'N'#250'mero de origen'
              Transparent = True
            end
            object edtOpNumeroOrigen: TcxDBTextEdit
              Left = 150
              Top = 128
              DataBinding.DataField = 'NUMERO_ORIGEN_PAGO'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = True
              TabStop = False
              Width = 230
            end
            object lblOpMotivo: TcxLabel
              Left = 400
              Top = 131
              Caption = 'Motivo devoluci'#243'n'
              Transparent = True
            end
            object edtOpMotivo: TcxDBTextEdit
              Left = 534
              Top = 128
              DataBinding.DataField = 'MOTIVO_DEVOLUCION_PAGO'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = True
              TabStop = False
              Width = 250
            end
            object btnIrAOperacion: TcxButton
              Left = 150
              Top = 174
              Width = 190
              Height = 25
              Caption = 'Ir a la operaci'#243'n'
              TabOrder = 0
              OnClick = btnIrAOperacionClick
            end
          end
          object tsFichaFactura: TcxTabSheet
            Caption = '&3_Factura'
            ImageIndex = 2
            object pnlFichaFacturaBotones: TPanel
              Left = 0
              Top = 0
              Width = 935
              Height = 33
              Align = alTop
              BevelOuter = bvNone
              ParentBackground = False
              TabOrder = 0
            object btnIrAFactura: TcxButton
              Left = 8
              Top = 4
              Width = 190
              Height = 25
              Caption = 'Ir a la factura'
              TabOrder = 0
              OnClick = btnIrAFacturaClick
            end
            end
            object cxgrdFichaFactura: TcxGrid
              Left = 0
              Top = 33
              Width = 935
              Height = 305
              Align = alClient
              TabOrder = 1
              object tvFichaFactura: TcxGridDBTableView
                Navigator.Buttons.CustomButtons = <>
                DataController.Summary.DefaultGroupSummaryItems = <>
                DataController.Summary.FooterSummaryItems = <>
                DataController.Summary.SummaryGroups = <>
                OptionsData.Deleting = False
                OptionsData.Editing = False
                OptionsData.Inserting = False
                OptionsView.GroupByBox = False
                OptionsView.Indicator = True
                object colFacSerie: TcxGridDBColumn
                  Caption = 'Serie'
                  DataBinding.FieldName = 'SERIE_FAC'
                  Options.Editing = False
                  Width = 90
                end
                object colFacNumero: TcxGridDBColumn
                  Caption = 'N'#250'mero'
                  DataBinding.FieldName = 'NUMERO_FAC'
                  Options.Editing = False
                  Width = 100
                end
                object colFacFecha: TcxGridDBColumn
                  Caption = 'Fecha'
                  DataBinding.FieldName = 'FECHA_FAC'
                  Options.Editing = False
                  Width = 100
                end
                object colFacTipo: TcxGridDBColumn
                  Caption = 'Tipo'
                  DataBinding.FieldName = 'TIPO_FAC'
                  Options.Editing = False
                  Width = 120
                end
                object colFacFase: TcxGridDBColumn
                  Caption = 'Fase'
                  DataBinding.FieldName = 'FASE_FAC'
                  Options.Editing = False
                  Width = 120
                end
                object colFacConsolidada: TcxGridDBColumn
                  Caption = 'Consolidada'
                  DataBinding.FieldName = 'ESCONSOLIDADA_FAC'
                  Options.Editing = False
                  Width = 90
                end
                object colFacCliente: TcxGridDBColumn
                  Caption = 'Cliente'
                  DataBinding.FieldName = 'RAZON_SOCIAL_CLIENTE_FAC'
                  Options.Editing = False
                  Width = 220
                end
                object colFacBases: TcxGridDBColumn
                  Caption = 'Bases'
                  DataBinding.FieldName = 'TOTAL_BASES_FAC'
                  Options.Editing = False
                  PropertiesClassName = 'TcxCurrencyEditProperties'
                  Properties.DisplayFormat = '#,##0.00 '#8364
                  Width = 110
                end
                object colFacImpuestos: TcxGridDBColumn
                  Caption = 'Impuestos'
                  DataBinding.FieldName = 'TOTAL_IMPUESTOS_FAC'
                  Options.Editing = False
                  PropertiesClassName = 'TcxCurrencyEditProperties'
                  Properties.DisplayFormat = '#,##0.00 '#8364
                  Width = 110
                end
                object colFacTotal: TcxGridDBColumn
                  Caption = 'Total'
                  DataBinding.FieldName = 'TOTAL_LIQUIDO_FAC'
                  Options.Editing = False
                  PropertiesClassName = 'TcxCurrencyEditProperties'
                  Properties.DisplayFormat = '#,##0.00 '#8364
                  Width = 110
                end
              end
              object tvFichaFacturaLineas: TcxGridDBTableView
                Navigator.Buttons.CustomButtons = <>
              DataController.DetailKeyFieldNames = 'NUMERO_FAC_FACLIN;SERIE_FAC_FACLIN'
              DataController.MasterKeyFieldNames = 'NUMERO_FAC;SERIE_FAC'
                DataController.Summary.DefaultGroupSummaryItems = <>
                DataController.Summary.FooterSummaryItems = <>
                DataController.Summary.SummaryGroups = <>
                OptionsData.Deleting = False
                OptionsData.Editing = False
                OptionsData.Inserting = False
                OptionsView.GroupByBox = False
                OptionsView.Indicator = True
                object colLinNumero: TcxGridDBColumn
                  Caption = 'L'#237'nea'
                  DataBinding.FieldName = 'LINEA_FACLIN'
                  Options.Editing = False
                  Width = 60
                end
                object colLinArticulo: TcxGridDBColumn
                  Caption = 'Art'#237'culo'
                  DataBinding.FieldName = 'CODIGO_ART_FACLIN'
                  Options.Editing = False
                  Width = 120
                end
                object colLinDescripcion: TcxGridDBColumn
                  Caption = 'Descripci'#243'n'
                  DataBinding.FieldName = 'DESCRIPCION_ARTICULO_FACLIN'
                  Options.Editing = False
                  Width = 240
                end
                object colLinVariacion: TcxGridDBColumn
                  Caption = 'Variaci'#243'n'
                  DataBinding.FieldName = 'DESCRIPCION_VARIACION_FACLIN'
                  Options.Editing = False
                  Width = 180
                end
                object colLinTipoCant: TcxGridDBColumn
                  Caption = 'TipoCant'
                  DataBinding.FieldName = 'TIPO_CANTIDAD_ARTICULO_FACLIN'
                  Options.Editing = False
                  Width = 80
                end
                object colLinCantidad: TcxGridDBColumn
                  Caption = 'Cantidad'
                  DataBinding.FieldName = 'CANTIDAD_FACLIN'
                  Options.Editing = False
                  Width = 90
                end
                object colLinPrecio: TcxGridDBColumn
                  Caption = 'Precio'
                  DataBinding.FieldName = 'PRECIO_SALIDA_FACLIN'
                  Options.Editing = False
                  PropertiesClassName = 'TcxCurrencyEditProperties'
                  Properties.DisplayFormat = '#,##0.00 '#8364
                  Width = 100
                end
                object colLinPrecioIva: TcxGridDBColumn
                  Caption = 'Precio con IVA'
                  DataBinding.FieldName = 'PRECIO_VENTA_CIVA_ARTICULO_FACLIN'
                  Options.Editing = False
                  PropertiesClassName = 'TcxCurrencyEditProperties'
                  Properties.DisplayFormat = '#,##0.00 '#8364
                  Width = 120
                end
                object colLinTotal: TcxGridDBColumn
                  Caption = 'Total'
                  DataBinding.FieldName = 'TOTAL_FACLIN'
                  Options.Editing = False
                  PropertiesClassName = 'TcxCurrencyEditProperties'
                  Properties.DisplayFormat = '#,##0.00 '#8364
                  Width = 110
                end
              end
              object lvlFichaFactura: TcxGridLevel
                GridView = tvFichaFactura
                object lvlFichaFacturaLineas: TcxGridLevel
                  Caption = 'L'#237'neas'
                  GridView = tvFichaFacturaLineas
                end
              end
            end
          end
        end
        object pnlFichaCabecera: TPanel
          Left = 0
          Top = 0
          Width = 943
          Height = 110
          Align = alTop
          BevelOuter = bvNone
          ParentBackground = False
          TabOrder = 0
            object lblFpCodigo: TcxLabel
              Left = 16
              Top = 15
              Caption = 'Forma de pago'
              Transparent = True
            end
            object edtFpCodigo: TcxDBTextEdit
              Left = 150
              Top = 12
              DataBinding.DataField = 'CODIGO_FP_CFP'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = True
              TabStop = False
              Width = 230
            end
            object lblFpDescripcion: TcxLabel
              Left = 400
              Top = 15
              Caption = 'Descripci'#243'n'
              Transparent = True
            end
            object edtFpDescripcion: TcxDBTextEdit
              Left = 534
              Top = 12
              DataBinding.DataField = 'DESCRIPCION_FP_PAGO'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = True
              TabStop = False
              Width = 250
            end
            object lblReferencia: TcxLabel
              Left = 16
              Top = 43
              Caption = 'Referencia'
              Transparent = True
            end
            object edtReferencia: TcxDBTextEdit
              Left = 150
              Top = 40
              DataBinding.DataField = 'REFERENCIA_FACPAG'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = True
              TabStop = False
              Width = 230
            end
            object lblFechaPago: TcxLabel
              Left = 400
              Top = 43
              Caption = 'Fecha'
              Transparent = True
            end
            object edtFechaPago: TcxDBTextEdit
              Left = 534
              Top = 40
              DataBinding.DataField = 'FECHA_PAGO'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = True
              TabStop = False
              Width = 250
            end
            object lblEntregado: TcxLabel
              Left = 16
              Top = 71
              Caption = 'Entregado'
              Transparent = True
            end
            object edtEntregado: TcxDBCurrencyEdit
              Left = 150
              Top = 68
              DataBinding.DataField = 'IMPORTE_ENTREGADO_PAGO'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = True
              Properties.DisplayFormat = '#,##0.00 '#8364
              TabStop = False
              Width = 230
            end
            object lblCambio: TcxLabel
              Left = 400
              Top = 71
              Caption = 'Cambio'
              Transparent = True
            end
            object edtCambio: TcxDBCurrencyEdit
              Left = 534
              Top = 68
              DataBinding.DataField = 'IMPORTE_CAMBIO_PAGO'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = True
              Properties.DisplayFormat = '#,##0.00 '#8364
              TabStop = False
              Width = 250
            end
        end
      end
      inherited tsPerfil: TcxTabSheet
        inherited pnlPerfilTop: TPanel
          inherited edtPerfilBusq: TcxTextEdit
            ExplicitHeight = 27
          end
        end
      end
    end
    inherited pnlTopPage: TPanel
      inherited pnlTopGrid: TPanel
        inherited edtBusqGlobal: TcxTextEdit
          ExplicitHeight = 27
        end
        inherited nvNavegador: TcxDBNavigator
          Width = 240
          ExplicitWidth = 240
        end
      end
    end
  end
  inherited pButtonRightBar: TPanel
    object btnImprimirInforme: TcxButton
      Left = 1
      Top = 120
      Width = 138
      Height = 48
      Caption = 'Imprimir Informe A4'
      TabOrder = 2
      WordWrap = True
      OnClick = btnImprimirInformeClick
    end
  end
  inherited dsTablaG: TDataSource
    DataSet = dmCajaPagosHist.unqryTablaG
  end
end
