inherited frmMtoRemesasCompra: TfrmMtoRemesasCompra
  Caption = 'Remesas de Pago'
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
            object dbcGrdDBTabPrinNUMERO_REMC: TcxGridDBColumn
              Caption = 'Número'
              DataBinding.FieldName = 'NUMERO_REMC'
              Width = 90
            end
            object dbcGrdDBTabPrinSERIE_REMC: TcxGridDBColumn
              Caption = 'Serie'
              DataBinding.FieldName = 'SERIE_REMC'
              Width = 70
            end
            object dbcGrdDBTabPrinFECHA_REMC: TcxGridDBColumn
              Caption = 'Fecha'
              DataBinding.FieldName = 'FECHA_REMC'
              Width = 100
            end
            object dbcGrdDBTabPrinESTADO_REMC: TcxGridDBColumn
              Caption = 'Estado'
              DataBinding.FieldName = 'ESTADO_REMC'
              Width = 100
            end
            object dbcGrdDBTabPrinCODIGO_EMP_REMC: TcxGridDBColumn
              Caption = 'Empresa'
              DataBinding.FieldName = 'CODIGO_EMP_REMC'
              Width = 90
            end
            object dbcGrdDBTabPrinRAZON_SOCIAL_EMPRESA_VIEW_REMC: TcxGridDBColumn
              Caption = 'Razón Social'
              DataBinding.FieldName = 'RAZON_SOCIAL_EMPRESA_VIEW_REMC'
              Width = 220
            end
            object dbcGrdDBTabPrinCONTADOR_EFECTOS_REMC: TcxGridDBColumn
              Caption = 'Nº efectos'
              DataBinding.FieldName = 'CONTADOR_EFECTOS_REMC'
              Width = 90
            end
            object dbcGrdDBTabPrinTOTAL_REMC: TcxGridDBColumn
              Caption = 'Total'
              DataBinding.FieldName = 'TOTAL_REMC'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 120
            end
            object dbcGrdDBTabPrinTOTAL_CARGADO_REMC: TcxGridDBColumn
              Caption = 'Cargo realizado'
              DataBinding.FieldName = 'TOTAL_CARGADO_REMC'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 120
            end
            object dbcGrdDBTabPrinTOTAL_PENDIENTE_REMC: TcxGridDBColumn
              Caption = 'Pendiente'
              DataBinding.FieldName = 'TOTAL_PENDIENTE_REMC'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 120
            end
            object dbcGrdDBTabPrinFECHA_CARGO_REMC: TcxGridDBColumn
              Caption = 'F. cargo'
              DataBinding.FieldName = 'FECHA_CARGO_REMC'
              Width = 100
            end
            object dbcGrdDBTabPrinIBAN_REMC: TcxGridDBColumn
              Caption = 'IBAN'
              DataBinding.FieldName = 'IBAN_REMC'
              Width = 200
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 30
        ExplicitWidth = 943
        ExplicitHeight = 484
        object pnlFichaCabecera: TPanel
          Left = 0
          Top = 0
          Width = 943
          Height = 190
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          object lblNumero: TcxLabel
            Left = 8
            Top = 10
            Caption = 'Número'
            TabOrder = 0
            Transparent = True
          end
          object txtNUMERO_REMC: TcxDBTextEdit
            Left = 8
            Top = 32
            DataBinding.DataField = 'NUMERO_REMC'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 1
            Width = 88
          end
          object lblSerie: TcxLabel
            Left = 108
            Top = 10
            Caption = 'Serie'
            TabOrder = 2
            Transparent = True
          end
          object txtSERIE_REMC: TcxDBTextEdit
            Left = 108
            Top = 32
            DataBinding.DataField = 'SERIE_REMC'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 3
            Width = 72
          end
          object lblFecha: TcxLabel
            Left = 192
            Top = 10
            Caption = 'Fecha'
            TabOrder = 4
            Transparent = True
          end
          object dteFECHA_REMC: TcxDBDateEdit
            Left = 192
            Top = 32
            DataBinding.DataField = 'FECHA_REMC'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 5
            Width = 104
          end
          object lblEstado: TcxLabel
            Left = 308
            Top = 10
            Caption = 'Estado'
            TabOrder = 6
            Transparent = True
          end
          object txtESTADO_REMC: TcxDBTextEdit
            Left = 308
            Top = 32
            DataBinding.DataField = 'ESTADO_REMC'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 7
            Width = 112
          end
          object lblEmpresa: TcxLabel
            Left = 432
            Top = 10
            Caption = 'Empresa'
            TabOrder = 8
            Transparent = True
          end
          object txtCODIGO_EMP_REMC: TcxDBTextEdit
            Left = 432
            Top = 32
            DataBinding.DataField = 'CODIGO_EMP_REMC'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 9
            Width = 88
          end
          object lblRazonSocial: TcxLabel
            Left = 532
            Top = 10
            Caption = 'Razón social'
            TabOrder = 10
            Transparent = True
          end
          object txtRAZON_SOCIAL_EMPRESA_VIEW_REMC: TcxDBTextEdit
            Left = 532
            Top = 32
            DataBinding.DataField = 'RAZON_SOCIAL_EMPRESA_VIEW_REMC'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 11
            Width = 240
          end
          object lblTotal: TcxLabel
            Left = 784
            Top = 10
            Caption = 'Total'
            TabOrder = 12
            Transparent = True
          end
          object curTOTAL_REMC: TcxDBCurrencyEdit
            Left = 784
            Top = 32
            DataBinding.DataField = 'TOTAL_REMC'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 13
            Width = 120
          end
          object lblContadorEfectos: TcxLabel
            Left = 8
            Top = 70
            Caption = 'Efectos'
            TabOrder = 14
            Transparent = True
          end
          object txtCONTADOR_EFECTOS_REMC: TcxDBTextEdit
            Left = 8
            Top = 92
            DataBinding.DataField = 'CONTADOR_EFECTOS_REMC'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 15
            Width = 88
          end
          object lblFechaCargo: TcxLabel
            Left = 108
            Top = 70
            Caption = 'F. cargo'
            TabOrder = 16
            Transparent = True
          end
          object dteFECHA_CARGO_REMC: TcxDBDateEdit
            Left = 108
            Top = 92
            DataBinding.DataField = 'FECHA_CARGO_REMC'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 17
            Width = 104
          end
          object lblIBAN: TcxLabel
            Left = 224
            Top = 70
            Caption = 'IBAN'
            TabOrder = 18
            Transparent = True
          end
          object txtIBAN_REMC: TcxDBTextEdit
            Left = 224
            Top = 92
            DataBinding.DataField = 'IBAN_REMC'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 19
            Width = 280
          end
          object lblCargoRealizado: TcxLabel
            Left = 516
            Top = 70
            Caption = 'Cargo realizado'
            TabOrder = 20
            Transparent = True
          end
          object curTOTAL_CARGADO_REMC: TcxDBCurrencyEdit
            Left = 516
            Top = 92
            DataBinding.DataField = 'TOTAL_CARGADO_REMC'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 21
            Width = 120
          end
          object lblPendienteCargo: TcxLabel
            Left = 648
            Top = 70
            Caption = 'Pendiente'
            TabOrder = 22
            Transparent = True
          end
          object curTOTAL_PENDIENTE_REMC: TcxDBCurrencyEdit
            Left = 648
            Top = 92
            DataBinding.DataField = 'TOTAL_PENDIENTE_REMC'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 23
            Width = 120
          end
          object lblBancoPago: TcxLabel
            Left = 8
            Top = 130
            Caption = 'Banco pago'
            TabOrder = 24
            Transparent = True
          end
          object cbbBancoPagoRemesa: TcxLookupComboBox
            Left = 108
            Top = 152
            Properties.DropDownListStyle = lsFixedList
            Properties.KeyFieldNames = 'CODIGO_EMPBAN'
            Properties.ListFieldNames = 'BANCO_VIEW_EMPBAN'
            TabOrder = 25
            Width = 396
          end
          object lblObservaciones: TcxLabel
            Left = 516
            Top = 130
            Caption = 'Observaciones'
            TabOrder = 26
            Transparent = True
          end
          object memOBSERVACIONES_REMC: TcxDBMemo
            Left = 516
            Top = 152
            DataBinding.DataField = 'OBSERVACIONES_REMC'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 27
            Height = 30
            Width = 388
          end
        end
        object pnlFichaDetalle: TPanel
          Left = 0
          Top = 190
          Width = 943
          Height = 294
          Align = alClient
          BevelOuter = bvNone
          TabOrder = 1
          object pnlEfectosTitulo: TPanel
            Left = 0
            Top = 0
            Width = 943
            Height = 32
            Align = alTop
            BevelOuter = bvNone
            TabOrder = 0
            object lblEfectosRemesa: TcxLabel
              Left = 8
              Top = 6
              Caption = 'Efectos asignados a la remesa'
              TabOrder = 0
              Transparent = True
            end
          end
          object cxgrdEfectosRemesa: TcxGrid
            Left = 0
            Top = 32
            Width = 943
            Height = 274
            Align = alClient
            TabOrder = 1
            object tvEfectosRemesa: TcxGridDBTableView
              OptionsData.Deleting = False
              OptionsData.Editing = False
              OptionsData.Inserting = False
              OptionsView.GroupByBox = False
              OptionsView.Indicator = True
              object tvEfectosRemesaNUMERO_FACC_EFEC: TcxGridDBColumn
                Caption = 'Factura'
                DataBinding.FieldName = 'NUMERO_FACC_EFEC'
                Width = 90
              end
              object tvEfectosRemesaSERIE_FACC_EFEC: TcxGridDBColumn
                Caption = 'Serie'
                DataBinding.FieldName = 'SERIE_FACC_EFEC'
                Width = 70
              end
              object tvEfectosRemesaNUMERO_EFEC: TcxGridDBColumn
                Caption = 'Efecto'
                DataBinding.FieldName = 'NUMERO_EFEC'
                Width = 60
              end
              object tvEfectosRemesaPROVEEDOR_VIEW_EFEC: TcxGridDBColumn
                Caption = 'Proveedor'
                DataBinding.FieldName = 'PROVEEDOR_VIEW_EFEC'
                Width = 190
              end
              object tvEfectosRemesaDESCRIPCION_TEFE_VIEW_EFEC: TcxGridDBColumn
                Caption = 'Tipo'
                DataBinding.FieldName = 'DESCRIPCION_TEFE_VIEW_EFEC'
                Width = 110
              end
              object tvEfectosRemesaFECHA_VENCIMIENTO_EFEC: TcxGridDBColumn
                Caption = 'Vencimiento'
                DataBinding.FieldName = 'FECHA_VENCIMIENTO_EFEC'
                Width = 100
              end
              object tvEfectosRemesaIMPORTE_EFEC: TcxGridDBColumn
                Caption = 'Importe'
                DataBinding.FieldName = 'IMPORTE_EFEC'
                PropertiesClassName = 'TcxCurrencyEditProperties'
                Properties.DisplayFormat = '#,##0.00 '#8364
                Width = 100
              end
              object tvEfectosRemesaIMPORTE_PAGADO_EFEC: TcxGridDBColumn
                Caption = 'Pagado'
                DataBinding.FieldName = 'IMPORTE_PAGADO_EFEC'
                PropertiesClassName = 'TcxCurrencyEditProperties'
                Properties.DisplayFormat = '#,##0.00 '#8364
                Width = 100
              end
              object tvEfectosRemesaIMPORTE_PENDIENTE_EFEC: TcxGridDBColumn
                Caption = 'Pendiente'
                DataBinding.FieldName = 'IMPORTE_PENDIENTE_EFEC'
                PropertiesClassName = 'TcxCurrencyEditProperties'
                Properties.DisplayFormat = '#,##0.00 '#8364
                Width = 100
              end
              object tvEfectosRemesaESTADO_EFEC: TcxGridDBColumn
                Caption = 'Estado'
                DataBinding.FieldName = 'ESTADO_EFEC'
                Width = 100
              end
              object tvEfectosRemesaREFERENCIA_DOCUMENTO_EFEC: TcxGridDBColumn
                Caption = 'Ref. doc.'
                DataBinding.FieldName = 'REFERENCIA_DOCUMENTO_EFEC'
                Width = 130
              end
              object tvEfectosRemesaFECHA_PAGO_EFEC: TcxGridDBColumn
                Caption = 'F. pago'
                DataBinding.FieldName = 'FECHA_PAGO_EFEC'
                Width = 100
              end
              object tvEfectosRemesaDOC_EXTERNO_EFEC: TcxGridDBColumn
                Caption = 'Doc. proveedor'
                DataBinding.FieldName = 'DOC_EXTERNO_EFEC'
                Width = 120
              end
            end
            object lvlEfectosRemesa: TcxGridLevel
              GridView = tvEfectosRemesa
            end
          end
        end
      end
    end
    inherited pnlTopPage: TPanel
      inherited pnlTopGrid: TPanel
        inherited nvNavegador: TcxDBNavigator
          Width = 252
          ExplicitWidth = 252
        end
      end
    end
  end
  inherited pButtonRightBar: TPanel
    object btnAnadirEfecto: TcxButton
      Left = 0
      Top = 150
      Width = 137
      Height = 40
      Caption = 'Añadir efecto'
      TabOrder = 2
      OnClick = btnAnadirEfectoClick
    end
    object btnQuitarEfecto: TcxButton
      Left = 0
      Top = 196
      Width = 137
      Height = 40
      Caption = 'Quitar efecto'
      TabOrder = 3
      OnClick = btnQuitarEfectoClick
    end
    object btnPagarEfecto: TcxButton
      Left = 0
      Top = 242
      Width = 137
      Height = 40
      Caption = 'Conciliar efecto'
      TabOrder = 4
      OnClick = btnPagarEfectoClick
    end
    object btnPagarRemesa: TcxButton
      Left = 0
      Top = 288
      Width = 137
      Height = 40
      Caption = 'Conciliar remesa'
      TabOrder = 5
      OnClick = btnPagarRemesaClick
    end
    object btnAsignarBanco: TcxButton
      Left = 0
      Top = 334
      Width = 137
      Height = 40
      Caption = 'Asignar banco'
      TabOrder = 6
      OnClick = btnAsignarBancoClick
    end
    object btnFechaCargo: TcxButton
      Left = 0
      Top = 380
      Width = 137
      Height = 40
      Caption = 'Fecha cargo'
      TabOrder = 7
      OnClick = btnFechaCargoClick
    end
  end
  inherited dsTablaG: TDataSource
    DataSet = dmRemesasCompra.unqryTablaG
  end
end
