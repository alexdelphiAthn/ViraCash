inherited frmMtoRemesasVenta: TfrmMtoRemesasVenta
  Caption = 'Remesas de Cobro'
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
            object dbcGrdDBTabPrinNUMERO_REMV: TcxGridDBColumn
              Caption = 'Número'
              DataBinding.FieldName = 'NUMERO_REMV'
              Width = 90
            end
            object dbcGrdDBTabPrinSERIE_REMV: TcxGridDBColumn
              Caption = 'Serie'
              DataBinding.FieldName = 'SERIE_REMV'
              Width = 70
            end
            object dbcGrdDBTabPrinFECHA_REMV: TcxGridDBColumn
              Caption = 'Fecha'
              DataBinding.FieldName = 'FECHA_REMV'
              Width = 100
            end
            object dbcGrdDBTabPrinESTADO_REMV: TcxGridDBColumn
              Caption = 'Estado'
              DataBinding.FieldName = 'ESTADO_REMV'
              Width = 100
            end
            object dbcGrdDBTabPrinCODIGO_EMP_REMV: TcxGridDBColumn
              Caption = 'Empresa'
              DataBinding.FieldName = 'CODIGO_EMP_REMV'
              Width = 90
            end
            object dbcGrdDBTabPrinRAZON_SOCIAL_EMPRESA_VIEW_REMV: TcxGridDBColumn
              Caption = 'Razón Social'
              DataBinding.FieldName = 'RAZON_SOCIAL_EMPRESA_VIEW_REMV'
              Width = 220
            end
            object dbcGrdDBTabPrinCONTADOR_EFECTOS_REMV: TcxGridDBColumn
              Caption = 'Nº efectos'
              DataBinding.FieldName = 'CONTADOR_EFECTOS_REMV'
              Width = 90
            end
            object dbcGrdDBTabPrinTOTAL_REMV: TcxGridDBColumn
              Caption = 'Total'
              DataBinding.FieldName = 'TOTAL_REMV'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 120
            end
            object dbcGrdDBTabPrinTOTAL_COBRADO_REMV: TcxGridDBColumn
              Caption = 'Cobro realizado'
              DataBinding.FieldName = 'TOTAL_COBRADO_REMV'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 120
            end
            object dbcGrdDBTabPrinTOTAL_PENDIENTE_REMV: TcxGridDBColumn
              Caption = 'Pendiente'
              DataBinding.FieldName = 'TOTAL_PENDIENTE_REMV'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 120
            end
            object dbcGrdDBTabPrinFECHA_CARGO_REMV: TcxGridDBColumn
              Caption = 'F. cobro'
              DataBinding.FieldName = 'FECHA_CARGO_REMV'
              Width = 100
            end
            object dbcGrdDBTabPrinIBAN_REMV: TcxGridDBColumn
              Caption = 'IBAN'
              DataBinding.FieldName = 'IBAN_REMV'
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
          object txtNUMERO_REMV: TcxDBTextEdit
            Left = 8
            Top = 32
            DataBinding.DataField = 'NUMERO_REMV'
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
          object txtSERIE_REMV: TcxDBTextEdit
            Left = 108
            Top = 32
            DataBinding.DataField = 'SERIE_REMV'
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
          object dteFECHA_REMV: TcxDBDateEdit
            Left = 192
            Top = 32
            DataBinding.DataField = 'FECHA_REMV'
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
          object txtESTADO_REMV: TcxDBTextEdit
            Left = 308
            Top = 32
            DataBinding.DataField = 'ESTADO_REMV'
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
          object txtCODIGO_EMP_REMV: TcxDBTextEdit
            Left = 432
            Top = 32
            DataBinding.DataField = 'CODIGO_EMP_REMV'
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
          object txtRAZON_SOCIAL_EMPRESA_VIEW_REMV: TcxDBTextEdit
            Left = 532
            Top = 32
            DataBinding.DataField = 'RAZON_SOCIAL_EMPRESA_VIEW_REMV'
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
          object curTOTAL_REMV: TcxDBCurrencyEdit
            Left = 784
            Top = 32
            DataBinding.DataField = 'TOTAL_REMV'
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
          object txtCONTADOR_EFECTOS_REMV: TcxDBTextEdit
            Left = 8
            Top = 92
            DataBinding.DataField = 'CONTADOR_EFECTOS_REMV'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 15
            Width = 88
          end
          object lblFechaCobro: TcxLabel
            Left = 108
            Top = 70
            Caption = 'F. cobro'
            TabOrder = 16
            Transparent = True
          end
          object dteFECHA_CARGO_REMV: TcxDBDateEdit
            Left = 108
            Top = 92
            DataBinding.DataField = 'FECHA_CARGO_REMV'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 17
            OnClick = dteFECHA_CARGO_REMVClick
            Width = 104
          end
          object lblIBAN: TcxLabel
            Left = 224
            Top = 70
            Caption = 'IBAN'
            TabOrder = 18
            Transparent = True
          end
          object txtIBAN_REMV: TcxDBTextEdit
            Left = 224
            Top = 92
            DataBinding.DataField = 'IBAN_REMV'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 19
            Width = 280
          end
          object lblCobroRealizado: TcxLabel
            Left = 516
            Top = 70
            Caption = 'Cobro realizado'
            TabOrder = 20
            Transparent = True
          end
          object curTOTAL_COBRADO_REMV: TcxDBCurrencyEdit
            Left = 516
            Top = 92
            DataBinding.DataField = 'TOTAL_COBRADO_REMV'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 21
            Width = 120
          end
          object lblPendienteCobro: TcxLabel
            Left = 648
            Top = 70
            Caption = 'Pendiente'
            TabOrder = 22
            Transparent = True
          end
          object curTOTAL_PENDIENTE_REMV: TcxDBCurrencyEdit
            Left = 648
            Top = 92
            DataBinding.DataField = 'TOTAL_PENDIENTE_REMV'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 23
            Width = 120
          end
          object lblBancoCobro: TcxLabel
            Left = 8
            Top = 130
            Caption = 'Banco cobro'
            TabOrder = 24
            Transparent = True
          end
          object cbbBancoCobroRemesa: TcxLookupComboBox
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
          object memOBSERVACIONES_REMV: TcxDBMemo
            Left = 516
            Top = 152
            DataBinding.DataField = 'OBSERVACIONES_REMV'
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
              object tvEfectosRemesaNUMERO_FAC_EFV: TcxGridDBColumn
                Caption = 'Factura'
                DataBinding.FieldName = 'NUMERO_FAC_EFV'
                Width = 90
              end
              object tvEfectosRemesaSERIE_FAC_EFV: TcxGridDBColumn
                Caption = 'Serie'
                DataBinding.FieldName = 'SERIE_FAC_EFV'
                Width = 70
              end
              object tvEfectosRemesaNUMERO_EFV: TcxGridDBColumn
                Caption = 'Efecto'
                DataBinding.FieldName = 'NUMERO_EFV'
                Width = 60
              end
              object tvEfectosRemesaCLIENTE_VIEW_EFV: TcxGridDBColumn
                Caption = 'Cliente'
                DataBinding.FieldName = 'CLIENTE_VIEW_EFV'
                Width = 190
              end
              object tvEfectosRemesaDESCRIPCION_TEFE_VIEW_EFV: TcxGridDBColumn
                Caption = 'Tipo'
                DataBinding.FieldName = 'DESCRIPCION_TEFE_VIEW_EFV'
                Width = 110
              end
              object tvEfectosRemesaFECHA_VENCIMIENTO_EFV: TcxGridDBColumn
                Caption = 'Vencimiento'
                DataBinding.FieldName = 'FECHA_VENCIMIENTO_EFV'
                Width = 100
              end
              object tvEfectosRemesaIMPORTE_EFV: TcxGridDBColumn
                Caption = 'Importe'
                DataBinding.FieldName = 'IMPORTE_EFV'
                PropertiesClassName = 'TcxCurrencyEditProperties'
                Properties.DisplayFormat = '#,##0.00 '#8364
                Width = 100
              end
              object tvEfectosRemesaIMPORTE_COBRADO_EFV: TcxGridDBColumn
                Caption = 'Cobrado'
                DataBinding.FieldName = 'IMPORTE_COBRADO_EFV'
                PropertiesClassName = 'TcxCurrencyEditProperties'
                Properties.DisplayFormat = '#,##0.00 '#8364
                Width = 100
              end
              object tvEfectosRemesaIMPORTE_PENDIENTE_EFV: TcxGridDBColumn
                Caption = 'Pendiente'
                DataBinding.FieldName = 'IMPORTE_PENDIENTE_EFV'
                PropertiesClassName = 'TcxCurrencyEditProperties'
                Properties.DisplayFormat = '#,##0.00 '#8364
                Width = 100
              end
              object tvEfectosRemesaESTADO_EFV: TcxGridDBColumn
                Caption = 'Estado'
                DataBinding.FieldName = 'ESTADO_EFV'
                Width = 100
              end
              object tvEfectosRemesaREFERENCIA_DOCUMENTO_EFV: TcxGridDBColumn
                Caption = 'Ref. doc.'
                DataBinding.FieldName = 'REFERENCIA_DOCUMENTO_EFV'
                Width = 130
              end
              object tvEfectosRemesaFECHA_COBRO_EFV: TcxGridDBColumn
                Caption = 'F. cobro'
                DataBinding.FieldName = 'FECHA_COBRO_EFV'
                Width = 100
              end
              object tvEfectosRemesaDOC_EXTERNO_EFV: TcxGridDBColumn
                Caption = 'Doc. cliente'
                DataBinding.FieldName = 'DOC_EXTERNO_EFV'
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
    object btnCobrarEfecto: TcxButton
      Left = 0
      Top = 242
      Width = 137
      Height = 40
      Caption = 'Conciliar efecto'
      TabOrder = 4
      OnClick = btnCobrarEfectoClick
    end
    object btnCobrarRemesa: TcxButton
      Left = 0
      Top = 288
      Width = 137
      Height = 40
      Caption = 'Conciliar remesa'
      TabOrder = 5
      OnClick = btnCobrarRemesaClick
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
    object btnFechaCobro: TcxButton
      Left = 0
      Top = 380
      Width = 137
      Height = 40
      Caption = 'Fecha cobro'
      TabOrder = 7
      OnClick = btnFechaCobroClick
    end
    object btnGenerarSepa: TcxButton
      Left = 0
      Top = 426
      Width = 137
      Height = 40
      Caption = 'Generar SEPA'
      TabOrder = 8
      OnClick = btnGenerarSepaClick
    end
  end
  inherited dsTablaG: TDataSource
    DataSet = dmRemesasVenta.unqryTablaG
  end
end


