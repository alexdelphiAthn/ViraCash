inherited frmMtoCajaValesHist: TfrmMtoCajaValesHist
  Caption = 'Hist'#243'rico de Vales'
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
            object cxGrdDBTabPrinCODIGO_VL: TcxGridDBColumn
              Caption = 'C'#243'digo Vale'
              DataBinding.FieldName = 'CODIGO_VL'
              Width = 200
            end
            object cxGrdDBTabPrinESTADO_VL: TcxGridDBColumn
              Caption = 'Estado'
              DataBinding.FieldName = 'ESTADO_VL'
              Width = 100
            end
            object cxGrdDBTabPrinIMPORTE_NOMINAL_VL: TcxGridDBColumn
              Caption = 'Importe Nominal'
              DataBinding.FieldName = 'IMPORTE_NOMINAL_VL'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 130
            end
            object cxGrdDBTabPrinFECHA_EMISION_VL: TcxGridDBColumn
              Caption = 'F. Emisi'#243'n'
              DataBinding.FieldName = 'FECHA_EMISION_VL'
              Width = 140
            end
            object cxGrdDBTabPrinFECHA_CADUCIDAD_VL: TcxGridDBColumn
              Caption = 'F. Caducidad'
              DataBinding.FieldName = 'FECHA_CADUCIDAD_VL'
              Width = 120
            end
            object cxGrdDBTabPrinCODIGO_PADRE_VL: TcxGridDBColumn
              Caption = 'Vale Padre'
              DataBinding.FieldName = 'CODIGO_PADRE_VL'
              Width = 180
            end
            object cxGrdDBTabPrinPIN_SEGURIDAD_VL: TcxGridDBColumn
              Caption = 'PIN'
              DataBinding.FieldName = 'PIN_SEGURIDAD_VL'
              Width = 100
            end
            object cxGrdDBTabPrinCODIGO_EMPRESA_EMI_VL: TcxGridDBColumn
              Caption = 'Empresa Emi.'
              DataBinding.FieldName = 'CODIGO_EMP_EMI_VL'
              Width = 110
            end
            object cxGrdDBTabPrinCODIGO_ALMACEN_EMI_VL: TcxGridDBColumn
              Caption = 'Almac'#233'n Emi.'
              DataBinding.FieldName = 'CODIGO_ALM_EMI_VL'
              Width = 110
            end
            object cxGrdDBTabPrinCODIGO_CAJA_EMI_VL: TcxGridDBColumn
              Caption = 'Caja Emi.'
              DataBinding.FieldName = 'CODIGO_CAJA_EMI_VL'
              Width = 100
            end
            object cxGrdDBTabPrinNUMERO_OPERACION_EMI_VL: TcxGridDBColumn
              Caption = 'N'#250'm. Op. Emi.'
              DataBinding.FieldName = 'NUMERO_OPERACION_EMI_VL'
              Width = 160
            end
            object cxGrdDBTabPrinSERIE_FACTURA_EMI_VL: TcxGridDBColumn
              Caption = 'Serie Fac. Emi.'
              DataBinding.FieldName = 'SERIE_FAC_EMI_VL'
              Width = 110
            end
            object cxGrdDBTabPrinNRO_FACTURA_EMI_VL: TcxGridDBColumn
              Caption = 'Nro. Fac. Emi.'
              DataBinding.FieldName = 'NUMERO_FAC_EMI_VL'
              Width = 110
            end
            object cxGrdDBTabPrinFECHA_REDENCION_VL: TcxGridDBColumn
              Caption = 'F. Redenci'#243'n'
              DataBinding.FieldName = 'FECHA_REDENCION_VL'
              Width = 140
            end
            object cxGrdDBTabPrinIMPORTE_REDIMIDO_VL: TcxGridDBColumn
              Caption = 'Importe Redimido'
              DataBinding.FieldName = 'IMPORTE_REDIMIDO_VL'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 130
            end
            object cxGrdDBTabPrinCODIGO_EMPRESA_RED_VL: TcxGridDBColumn
              Caption = 'Empresa Red.'
              DataBinding.FieldName = 'CODIGO_EMP_RED_VL'
              Width = 110
              Visible = False
            end
            object cxGrdDBTabPrinCODIGO_ALMACEN_RED_VL: TcxGridDBColumn
              Caption = 'Almac'#233'n Red.'
              DataBinding.FieldName = 'CODIGO_ALM_RED_VL'
              Width = 110
              Visible = False
            end
            object cxGrdDBTabPrinCODIGO_CAJA_RED_VL: TcxGridDBColumn
              Caption = 'Caja Red.'
              DataBinding.FieldName = 'CODIGO_CAJA_RED_VL'
              Width = 100
              Visible = False
            end
            object cxGrdDBTabPrinNUMERO_OPERACION_RED_VL: TcxGridDBColumn
              Caption = 'N'#250'm. Op. Red.'
              DataBinding.FieldName = 'NUMERO_OPERACION_RED_VL'
              Width = 160
              Visible = False
            end
            object cxGrdDBTabPrinSERIE_FACTURA_RED_VL: TcxGridDBColumn
              Caption = 'Serie Fac. Red.'
              DataBinding.FieldName = 'SERIE_FAC_RED_VL'
              Width = 110
              Visible = False
            end
            object cxGrdDBTabPrinNRO_FACTURA_RED_VL: TcxGridDBColumn
              Caption = 'Nro. Fac. Red.'
              DataBinding.FieldName = 'NUMERO_FAC_RED_VL'
              Width = 110
              Visible = False
            end
            object cxGrdDBTabPrinCODIGO_CLIENTE_VL: TcxGridDBColumn
              Caption = 'Cliente'
              DataBinding.FieldName = 'CODIGO_CLI_VL'
              Width = 130
            end
            object cxGrdDBTabPrinOBSERVACIONES_VL: TcxGridDBColumn
              Caption = 'Observaciones'
              DataBinding.FieldName = 'OBSERVACIONES_VL'
              Width = 220
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
            object cxGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn
              Caption = 'Usuario Modif'
              DataBinding.FieldName = 'USUARIO_MODIF'
              Options.Editing = False
              Visible = False
              Width = 130
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        TabVisible = False
        ExplicitLeft = 4
        ExplicitTop = 30
        ExplicitWidth = 943
        ExplicitHeight = 484
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
    object btnIrOperacionOrigen: TcxButton
      Left = 1
      Top = 120
      Width = 138
      Height = 48
      Action = actIrOperacionOrigen
      TabOrder = 2
      WordWrap = True
    end
    object btnIrOperacionRedencion: TcxButton
      Left = 1
      Top = 172
      Width = 138
      Height = 48
      Action = actIrOperacionRedencion
      TabOrder = 3
      WordWrap = True
    end
    object btnReimprimirVale: TcxButton
      Left = 1
      Top = 224
      Width = 138
      Height = 48
      Action = actReimprimirVale
      TabOrder = 4
      WordWrap = True
    end
  end
  inherited dsTablaG: TDataSource
    DataSet = dmCajaValesHist.unqryTablaG
  end
  object alValesHist: TActionList
    Left = 744
    Top = 448
    object actIrOperacionOrigen: TAction
      Caption = 'Ir a la operaci'#243'n origen'
      OnExecute = actIrOperacionOrigenExecute
      OnUpdate = actIrOperacionOrigenUpdate
    end
    object actIrOperacionRedencion: TAction
      Caption = 'Ir a la operaci'#243'n de redenci'#243'n'
      OnExecute = actIrOperacionRedencionExecute
      OnUpdate = actIrOperacionRedencionUpdate
    end
    object actReimprimirVale: TAction
      Caption = 'Reimprimir vale'
      OnExecute = actReimprimirValeExecute
      OnUpdate = actReimprimirValeUpdate
    end
  end
end
