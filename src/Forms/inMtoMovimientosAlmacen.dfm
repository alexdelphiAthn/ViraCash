inherited frmMtoMovimientosAlmacen: TfrmMtoMovimientosAlmacen
  Caption = 'Movimientos de Almac'#233'n'
  StyleElements = [seFont, seClient, seBorder]
  OnDestroy = FormDestroy
  TextHeight = 17
  inherited pButtonPage: TPanel
    StyleElements = [seFont, seClient, seBorder]
    inherited pcPantalla: TcxPageControl
      Properties.ActivePage = tsLista
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 2
        ExplicitTop = 27
        ExplicitWidth = 947
        ExplicitHeight = 489
        inherited cxGrdPrincipal: TcxGrid
          Height = 489
          ExplicitHeight = 489
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            OptionsData.Editing = False
            object cxGrdDBTabPrinNUMERO_MOV: TcxGridDBColumn
              Caption = 'N'#250'mero Mov.'
              DataBinding.FieldName = 'NUMERO_MOV'
              Width = 130
            end
            object cxGrdDBTabPrinFECHA_MOV: TcxGridDBColumn
              Caption = 'Fecha'
              DataBinding.FieldName = 'FECHA_MOV'
              Width = 140
            end
            object cxGrdDBTabPrinTIPO_MOVIMIENTO_MOV: TcxGridDBColumn
              Caption = 'E/S'
              DataBinding.FieldName = 'TIPO_MOV'
              Width = 50
            end
            object cxGrdDBTabPrinTIPO_DOC_MOV: TcxGridDBColumn
              Caption = 'Tipo Doc.'
              DataBinding.FieldName = 'TIPO_DOC_MOV'
              Width = 80
            end
            object cxGrdDBTabPrinSERIE_DOC_MOV: TcxGridDBColumn
              Caption = 'Serie Doc.'
              DataBinding.FieldName = 'SERIE_DOC_MOV'
              Width = 100
            end
            object cxGrdDBTabPrinNRO_DOC_MOV: TcxGridDBColumn
              Caption = 'Nro. Doc.'
              DataBinding.FieldName = 'NUMERO_DOC_MOV'
              Width = 100
            end
            object cxGrdDBTabPrinLINEA_MOV: TcxGridDBColumn
              Caption = 'L'#237'nea'
              DataBinding.FieldName = 'LINEA_MOV'
              Width = 60
            end
            object cxGrdDBTabPrinCODIGO_EMPRESA_MOV: TcxGridDBColumn
              Caption = 'Empresa'
              DataBinding.FieldName = 'CODIGO_EMP_MOV'
              Width = 90
            end
            object cxGrdDBTabPrinCODIGO_ALMACEN_MOV: TcxGridDBColumn
              Caption = 'Almac'#233'n'
              DataBinding.FieldName = 'CODIGO_ALM_MOV'
              Width = 90
            end
            object cxGrdDBTabPrinCODIGO_ARTICULO_MOV: TcxGridDBColumn
              Caption = 'Art'#237'culo'
              DataBinding.FieldName = 'CODIGO_ART_MOV'
              Width = 130
            end
            object cxGrdDBTabPrinCODIGO_UNIDAD_MOV: TcxGridDBColumn
              Caption = 'SKU'
              DataBinding.FieldName = 'CODIGO_UNIDAD_MOV'
              Width = 160
            end
            object cxGrdDBTabPrinDESCRIPCION_ARTICULO_MOV: TcxGridDBColumn
              Caption = 'Descripci'#243'n'
              DataBinding.FieldName = 'DESCRIPCION_ARTICULO_MOV'
              Width = 200
            end
            object cxGrdDBTabPrinCANTIDAD_MOV: TcxGridDBColumn
              Caption = 'Cantidad'
              DataBinding.FieldName = 'CANTIDAD_MOV'
              Width = 100
            end
            object colMovTipoCantidad: TcxGridDBColumn
              DataBinding.FieldName = 'TIPO_CANTIDAD_ART'
              Visible = False
              VisibleForCustomization = False
            end
            object cxGrdDBTabPrinPRECIO_COSTE_UNITARIO_MOV: TcxGridDBColumn
              Caption = 'Coste Unit.'
              DataBinding.FieldName = 'PRECIO_COSTE_UNITARIO_MOV'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Width = 110
            end
            object cxGrdDBTabPrinTOTAL_COSTE_MOV: TcxGridDBColumn
              Caption = 'Total Coste'
              DataBinding.FieldName = 'TOTAL_COSTE_MOV'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Width = 110
            end
            object cxGrdDBTabPrinPRECIO_MEDIO_MOV: TcxGridDBColumn
              Caption = 'Precio Medio'
              DataBinding.FieldName = 'PRECIO_MEDIO_MOV'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Width = 110
            end
            object cxGrdDBTabPrinCODIGO_ALMACEN_CONTRA_MOV: TcxGridDBColumn
              Caption = 'Almac'#233'n Contra'
              DataBinding.FieldName = 'CODIGO_ALM_CONTRA_MOV'
              Visible = False
              Width = 130
            end
            object cxGrdDBTabPrinCODIGO_CLIENTE_MOV: TcxGridDBColumn
              Caption = 'Cliente'
              DataBinding.FieldName = 'CODIGO_CLI_MOV'
              Visible = False
              Width = 120
            end
            object cxGrdDBTabPrinCODIGO_PROVEEDOR_MOV: TcxGridDBColumn
              Caption = 'Proveedor'
              DataBinding.FieldName = 'CODIGO_PRV_MOV'
              Visible = False
              Width = 120
            end
            object cxGrdDBTabPrinESACTIVO_MOV: TcxGridDBColumn
              Caption = 'Activo'
              DataBinding.FieldName = 'ESACTIVO_MOV'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 70
            end
            object cxGrdDBTabPrinTIPO_DOC_REF_MOV: TcxGridDBColumn
              Caption = 'Tipo Ref.'
              DataBinding.FieldName = 'TIPO_DOC_REF_MOV'
              Visible = False
              Width = 90
            end
            object cxGrdDBTabPrinSERIE_DOC_REF_MOV: TcxGridDBColumn
              Caption = 'Serie Ref.'
              DataBinding.FieldName = 'SERIE_DOC_REF_MOV'
              Visible = False
              Width = 100
            end
            object cxGrdDBTabPrinNRO_DOC_REF_MOV: TcxGridDBColumn
              Caption = 'Nro. Ref.'
              DataBinding.FieldName = 'NUMERO_DOC_REF_MOV'
              Visible = False
              Width = 100
            end
            object cxGrdDBTabPrinLINEA_REF_MOV: TcxGridDBColumn
              Caption = 'L'#237'nea Ref.'
              DataBinding.FieldName = 'LINEA_REF_MOV'
              Visible = False
              Width = 90
            end
            object cxGrdDBTabPrinLOTE_MOV: TcxGridDBColumn
              Caption = 'Lote'
              DataBinding.FieldName = 'LOTE_MOV'
              Visible = False
              Width = 110
            end
            object cxGrdDBTabPrinFECHA_CADUCIDAD_MOV: TcxGridDBColumn
              Caption = 'F. Caducidad'
              DataBinding.FieldName = 'FECHA_CADUCIDAD_MOV'
              Visible = False
              Width = 120
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
              Visible = False
              Options.Editing = False
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
              Visible = False
              Options.Editing = False
              Width = 130
            end
          end
        end
        object pnlFiltros: TPanel
          Left = 0
          Top = 0
          Width = 947
          Height = 60
          Align = alTop
          BevelOuter = bvNone
          ParentBackground = False
          TabOrder = 1
          object btnToggleFiltros: TcxButton
            Left = 0
            Top = 0
            Width = 947
            Height = 22
            Align = alTop
            Caption = #9654'  Filtros de carga'
            LookAndFeel.Kind = lfUltraFlat
            LookAndFeel.NativeStyle = False
            TabOrder = 0
            OnClick = btnToggleFiltrosClick
          end
          object pnlContFiltros: TPanel
            Left = 0
            Top = 22
            Width = 947
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
              Properties.EditValueFormat = cvfStatesString
              Properties.EmptySelectionText = 'Todos'
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
              Properties.EditValueFormat = cvfStatesString
              Properties.EmptySelectionText = 'Todos'
              Properties.Items = <>
              Properties.OnCloseUp = ccbFiltroAlmacenPropertiesCloseUp
              TabOrder = 1
              Width = 340
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        TabVisible = False
        ExplicitLeft = 2
        ExplicitTop = 27
        ExplicitWidth = 947
        ExplicitHeight = 489
      end
      inherited tsPerfil: TcxTabSheet
        inherited pnlPerfilTop: TPanel
          StyleElements = [seFont, seClient, seBorder]
          inherited edtPerfilBusq: TcxTextEdit
            ExplicitHeight = 25
          end
        end
        inherited pnlPerfilDetail: TPanel
          StyleElements = [seFont, seClient, seBorder]
          ExplicitHeight = 432
          inherited cxgrdPerfil: TcxGrid
            Height = 432
            ExplicitHeight = 432
          end
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
    object btnIraArticulo: TcxButton
      Left = -1
      Top = 240
      Width = 138
      Height = 34
      Caption = '&Ir a Art'#237'culo'
      TabOrder = 2
      OnClick = btnIraArticuloClick
    end
    object btnIrDocumento: TcxButton
      Left = -1
      Top = 280
      Width = 138
      Height = 34
      Caption = 'Ir a &Documento'
      TabOrder = 3
      OnClick = btnIrDocumentoClick
    end
  end
  inherited dsTablaG: TDataSource
    DataSet = dmMovimientosAlmacen.unqryTablaG
  end
  inherited alMtoGen: TActionList
    object Action1: TAction
      Caption = 'Ir a Art'#237'culo'
      ShortCut = 16466
      OnExecute = Action1Execute
    end
  end
end
