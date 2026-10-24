inherited frmMtoCajaArqueosHist: TfrmMtoCajaArqueosHist
  Caption = 'Hist'#243'rico de Arqueos de Caja'
  TextHeight = 19
  inherited pButtonPage: TPanel
    inherited pcPantalla: TcxPageControl
      Properties.ActivePage = tsLista
      inherited tsLista: TcxTabSheet
        Caption = '&1_Lista'
        ExplicitLeft = 4
        ExplicitTop = 30
        ExplicitWidth = 943
        ExplicitHeight = 484
        inherited cxGrdPrincipal: TcxGrid
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            OptionsData.Editing = False
            object cxGrdDBTabPrinCODIGO_ARQ: TcxGridDBColumn
              Caption = 'C'#243'digo Arqueo'
              DataBinding.FieldName = 'CODIGO_ARQ'
              Width = 200
            end
            object cxGrdDBTabPrinCODIGO_EMP_ARQ: TcxGridDBColumn
              Caption = 'Empresa'
              DataBinding.FieldName = 'CODIGO_EMP_ARQ'
              Width = 90
            end
            object cxGrdDBTabPrinCODIGO_ALM_ARQ: TcxGridDBColumn
              Caption = 'Almac'#233'n'
              DataBinding.FieldName = 'CODIGO_ALM_ARQ'
              Width = 90
            end
            object cxGrdDBTabPrinCODIGO_CAJA_ARQ: TcxGridDBColumn
              Caption = 'Caja'
              DataBinding.FieldName = 'CODIGO_CAJA_ARQ'
              Width = 70
            end
            object cxGrdDBTabPrinFECHA_DESDE_ARQ: TcxGridDBColumn
              Caption = 'Fecha Desde'
              DataBinding.FieldName = 'FECHA_DESDE_ARQ'
              PropertiesClassName = 'TcxDateEditProperties'
              Properties.DisplayFormat = 'dd/mm/yyyy hh:nn'
              Width = 140
            end
            object cxGrdDBTabPrinFECHA_HASTA_ARQ: TcxGridDBColumn
              Caption = 'Fecha Hasta'
              DataBinding.FieldName = 'FECHA_HASTA_ARQ'
              PropertiesClassName = 'TcxDateEditProperties'
              Properties.DisplayFormat = 'dd/mm/yyyy hh:nn'
              Width = 140
            end
            object cxGrdDBTabPrinFASE_ARQ: TcxGridDBColumn
              Caption = 'Fase'
              DataBinding.FieldName = 'FASE_ARQ'
              Width = 80
            end
            object cxGrdDBTabPrinCANTIDAD_VENTAS_ARQ: TcxGridDBColumn
              Caption = 'Ventas'
              DataBinding.FieldName = 'CANTIDAD_VENTAS_ARQ'
              Width = 70
            end
            object cxGrdDBTabPrinTOTAL_NETO_ARQ: TcxGridDBColumn
              Caption = 'Neto'
              DataBinding.FieldName = 'TOTAL_NETO_ARQ'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Width = 120
            end
            object cxGrdDBTabPrinTOTAL_VENTAS_ARQ: TcxGridDBColumn
              Caption = 'Total Ventas'
              DataBinding.FieldName = 'TOTAL_VENTAS_ARQ'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Width = 120
            end
            object cxGrdDBTabPrinTOTAL_EFECTIVO_CAJA_ARQ: TcxGridDBColumn
              Caption = 'Efectivo Caja'
              DataBinding.FieldName = 'TOTAL_EFECTIVO_CAJA_ARQ'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Width = 120
            end
            object cxGrdDBTabPrinTOTAL_OTROS_INGRESOS_ARQ: TcxGridDBColumn
              Caption = 'Otros Ingresos'
              DataBinding.FieldName = 'TOTAL_OTROS_INGRESOS_ARQ'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Width = 120
            end
            object cxGrdDBTabPrinTOTAL_SALDO_RECONTAR_ARQ: TcxGridDBColumn
              Caption = 'Saldo Te'#243'rico'
              DataBinding.FieldName = 'TOTAL_SALDO_RECONTAR_ARQ'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Width = 120
            end
            object cxGrdDBTabPrinTOTAL_RECUENTO_ARQ: TcxGridDBColumn
              Caption = 'Recuento'
              DataBinding.FieldName = 'TOTAL_RECUENTO_ARQ'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Width = 120
            end
            object cxGrdDBTabPrinDIFERENCIA_TOTAL_ARQ: TcxGridDBColumn
              Caption = 'Diferencia'
              DataBinding.FieldName = 'DIFERENCIA_TOTAL_ARQ'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Width = 120
            end
            object cxGrdDBTabPrinOBSERVACIONES_ARQ: TcxGridDBColumn
              Caption = 'Observaciones'
              DataBinding.FieldName = 'OBSERVACIONES_ARQ'
              Width = 250
            end
            object cxGrdDBTabPrinINSTANTE_ALTA: TcxGridDBColumn
              Caption = 'Instante Alta'
              DataBinding.FieldName = 'INSTANTE_ALTA'
              Options.Editing = False
              Width = 150
            end
            object cxGrdDBTabPrinUSUARIO_ALTA: TcxGridDBColumn
              Caption = 'Usuario Alta'
              DataBinding.FieldName = 'USUARIO_ALTA'
              Options.Editing = False
              Width = 130
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        Caption = '&2_Recuento'
        TabVisible = True
        ExplicitLeft = 4
        ExplicitTop = 30
        ExplicitWidth = 943
        ExplicitHeight = 484
        object cxgrdRecuento: TcxGrid
          Left = 0
          Top = 0
          Width = 943
          Height = 484
          Align = alClient
          TabOrder = 0
          object tvRecuento: TcxGridDBTableView
            Navigator.Buttons.CustomButtons = <>
            ScrollbarAnnotations.CustomAnnotations = <>
            DataController.DataSource = dmCajaArqueosHist.dsRecuento
            DataController.Summary.DefaultGroupSummaryItems = <>
            DataController.Summary.FooterSummaryItems = <>
            DataController.Summary.SummaryGroups = <>
            OptionsData.Deleting = False
            OptionsData.Editing = False
            OptionsData.Inserting = False
            OptionsView.ColumnAutoWidth = True
            OptionsView.GroupByBox = False
            object tvRecuentoCodigo: TcxGridDBColumn
              Caption = 'C'#243'digo'
              DataBinding.FieldName = 'CODIGO_FP_CFP_ARQR'
              Width = 90
            end
            object tvRecuentoDescripcion: TcxGridDBColumn
              Caption = 'Forma de pago'
              DataBinding.FieldName = 'DESCRIPCION_FP_ARQR'
              Width = 250
            end
            object tvRecuentoEsCajon: TcxGridDBColumn
              Caption = 'Efectivo'
              DataBinding.FieldName = 'ESCAJON_ARQR'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 80
            end
            object tvRecuentoSistema: TcxGridDBColumn
              Caption = 'Sistema'
              DataBinding.FieldName = 'IMPORTE_SISTEMA_ARQR'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Width = 120
            end
            object tvRecuentoImporte: TcxGridDBColumn
              Caption = 'Recontado'
              DataBinding.FieldName = 'IMPORTE_RECUENTO_ARQR'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Width = 120
            end
            object tvRecuentoDiferencia: TcxGridDBColumn
              Caption = 'Diferencia'
              DataBinding.FieldName = 'DIFERENCIA_ARQR'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Width = 120
            end
          end
          object lvRecuento: TcxGridLevel
            GridView = tvRecuento
          end
        end
      end
      inherited tsPerfil: TcxTabSheet
        Caption = '&3_Perfil'
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
    DataSet = dmCajaArqueosHist.unqryTablaG
  end
end
