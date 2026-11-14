inherited frmMtoCajaOperacionesHist: TfrmMtoCajaOperacionesHist
  Caption = 'Hist'#243'rico de Operaciones de Caja'
  StyleElements = [seFont, seClient, seBorder]
  OnDestroy = FormDestroy
  TextHeight = 17
  inherited pButtonPage: TPanel
    StyleElements = [seFont, seClient, seBorder]
    inherited pcPantalla: TcxPageControl
      Properties.ActivePage = tsLista
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 28
        ExplicitWidth = 943
        ExplicitHeight = 486
        inherited cxGrdPrincipal: TcxGrid
          Top = 60
          Width = 943
          Height = 426
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            OptionsData.Deleting = False
            OptionsData.Inserting = False
            object cxGrdDBTabPrinCODIGO_EMPRESA_OPCAJA: TcxGridDBColumn
              Caption = 'Empresa'
              DataBinding.FieldName = 'CODIGO_EMP_OPCAJA'
              Width = 90
            end
            object cxGrdDBTabPrinCODIGO_ALMACEN_OPCAJA: TcxGridDBColumn
              Caption = 'Almac'#233'n'
              DataBinding.FieldName = 'CODIGO_ALM_OPCAJA'
              Width = 90
            end
            object cxGrdDBTabPrinCODIGO_CAJA_OPCAJA: TcxGridDBColumn
              Caption = 'Caja'
              DataBinding.FieldName = 'CODIGO_CAJA_OPCAJA'
              Width = 70
            end
            object cxGrdDBTabPrinNUMERO_OPERACION_OPCAJA: TcxGridDBColumn
              Caption = 'N'#250'mero Operaci'#243'n'
              DataBinding.FieldName = 'NUMERO_OPERACION_OPCAJA'
              Width = 160
            end
            object cxGrdDBTabPrinFECHA_OPERACION_OPCAJA: TcxGridDBColumn
              Caption = 'Fecha/Hora'
              DataBinding.FieldName = 'FECHA_OP'
              PropertiesClassName = 'TcxDateEditProperties'
              Properties.DisplayFormat = 'dd/mm/yyyy hh:nn'
              Width = 128
            end
            object cxGrdDBTabPrinTIPO_OPERACION_OPCAJA: TcxGridDBColumn
              Caption = 'Tipos'
              DataBinding.FieldName = 'TIPOS_OP'
              PropertiesClassName = 'TcxTextEditProperties'
              Width = 86
            end
            object cxGrdDBTabPrinCODIGO_EMPLEADO_OPCAJA: TcxGridDBColumn
              Caption = 'Empleado'
              DataBinding.FieldName = 'EMPLEADO'
              Width = 100
            end
            object cxGrdDBTabPrinIMPORTE_TOTAL_OPCAJA: TcxGridDBColumn
              Caption = 'Importe'
              DataBinding.FieldName = 'IMPORTE_TOTAL'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 101
            end
            object cxGrdDBTabPrinCODIGO_CLIENTE_OPCAJA: TcxGridDBColumn
              Caption = 'Cliente'
              DataBinding.FieldName = 'CLIENTE'
              Width = 78
            end
            object cxGrdDBTabPrinRAZON_SOCIAL_CLI: TcxGridDBColumn
              Caption = 'Raz'#243'n social'
              DataBinding.FieldName = 'RAZON_SOCIAL_CLI'
              Width = 226
            end
            object cxGrdDBTabPrinSERIE_FACTURA_OPCAJA: TcxGridDBColumn
              Caption = 'Serie'
              DataBinding.FieldName = 'SERIE_FAC'
              Width = 78
            end
            object cxGrdDBTabPrinNRO_FACTURA_OPCAJA: TcxGridDBColumn
              Caption = 'N'#186' Borrador'
              DataBinding.FieldName = 'NUMERO_FAC'
              Width = 97
            end
            object cxGrdDBTabPrinCONCEPTO_GASTO_INGRESO_OPCAJA: TcxGridDBColumn
              Caption = 'Conceptos'
              DataBinding.FieldName = 'CONCEPTOS'
              PropertiesClassName = 'TcxTextEditProperties'
              Width = 230
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
              TabOrder = 2
              Transparent = True
            end
            object ccbFiltroAnyo: TcxCheckComboBox
              Left = 80
              Top = 5
              Properties.EmptySelectionText = 'Todos'
              Properties.EditValueFormat = cvfStatesString
              Properties.Items = <>
              Properties.OnCloseUp = ccbFiltroAnyoPropertiesCloseUp
              TabOrder = 0
              Width = 210
            end
            object lblFiltroAlmacen: TcxLabel
              Left = 320
              Top = 8
              Caption = 'Almacenes:'
              TabOrder = 3
              Transparent = True
            end
            object ccbFiltroAlmacen: TcxCheckComboBox
              Left = 416
              Top = 5
              Properties.EmptySelectionText = 'Todos'
              Properties.EditValueFormat = cvfStatesString
              Properties.Items = <>
              Properties.OnCloseUp = ccbFiltroAlmacenPropertiesCloseUp
              TabOrder = 1
              Width = 340
            end
            object btnGuardarPrecargaCaja: TcxButton
              Left = 768
              Top = 4
              Width = 139
              Height = 25
              Caption = 'Guardar precarga'
              TabOrder = 4
              OnClick = btnGuardarPrecargaCajaClick
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 30
        ExplicitWidth = 943
        ExplicitHeight = 484
      end
      inherited tsPerfil: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 28
        ExplicitWidth = 943
        ExplicitHeight = 486
        inherited pnlPerfilTop: TPanel
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 943
          inherited edtPerfilBusq: TcxTextEdit
            ExplicitHeight = 27
          end
        end
        inherited pnlPerfilDetail: TPanel
          StyleElements = [seFont, seClient, seBorder]
        end
      end
    end
    inherited pnlTopPage: TPanel
      StyleElements = [seFont, seClient, seBorder]
      inherited pnlTopGrid: TPanel
        StyleElements = [seFont, seClient, seBorder]
        inherited edtBusqGlobal: TcxTextEdit
          ExplicitHeight = 25
        end
        inherited nvNavegador: TcxDBNavigator
          Width = 240
          ExplicitWidth = 240
        end
        object chkVerMiniaturas: TcxCheckBox
          Left = 930
          Top = 7
          Hint = 'Muestra la columna Fotos con las miniaturas de los art'#237'culos de cada operaci'#243'n'
          Caption = 'Ver miniaturas en grid'
          ParentShowHint = False
          Properties.OnChange = chkVerMiniaturasPropertiesChange
          ShowHint = True
          TabOrder = 6
          Transparent = True
          Width = 190
        end
      end
    end
  end
  inherited pButtonRightBar: TPanel
    StyleElements = [seFont, seClient, seBorder]
    inherited pButtonGen: TPanel
      StyleElements = [seFont, seClient, seBorder]
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
    object btnImprimirDuplicado: TcxButton
      Left = 1
      Top = 120
      Width = 138
      Height = 48
      Action = actImprimirDuplicado
      TabOrder = 2
      WordWrap = True
    end
    object btnImprimirInforme: TcxButton
      Left = 1
      Top = 172
      Width = 138
      Height = 48
      Caption = 'Imprimir Informe A4'
      TabOrder = 3
      WordWrap = True
      OnClick = btnImprimirInformeClick
    end
  end
  inherited dsTablaG: TDataSource
    DataSet = dmCajaOperacionesHist.unqryTablaG
  end
  object alOperaciones: TActionList
    Left = 640
    Top = 16
    object actIrFacturaSimplif: TAction
      Caption = 'Ir a Borrador Simplificado'
      ShortCut = 24646
      OnExecute = actIrFacturaSimplifExecute
    end
    object actImprimirDuplicado: TAction
      Caption = 'Imprimir duplicado'
      OnExecute = actImprimirDuplicadoExecute
      OnUpdate = actImprimirDuplicadoUpdate
    end
  end
end
