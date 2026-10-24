inherited frmConsultaOpe: TfrmConsultaOpe
  Caption = 'Buscar operaciones'
  ClientHeight = 720
  ClientWidth = 1163
  Font.Charset = ANSI_CHARSET
  Position = poScreenCenter
  StyleElements = [seFont, seClient, seBorder]
  OnClose = FormClose
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnShow = FormShow
  ExplicitWidth = 1179
  ExplicitHeight = 759
  TextHeight = 17
  object splPrincipal: TSplitter [0]
    Left = 0
    Top = 316
    Width = 1163
    Height = 5
    Cursor = crVSplit
    Align = alTop
    ExplicitWidth = 1200
  end
  object pnlFiltros: TPanel [1]
    Left = 0
    Top = 0
    Width = 1163
    Height = 56
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblFecha: TcxLabel
      Left = 12
      Top = 18
      Caption = 'Fecha:'
      TabOrder = 2
    end
    object dtpFecha: TcxDateEdit
      Left = 72
      Top = 16
      Properties.DisplayFormat = 'dd/mm/yyyy'
      Properties.EditFormat = 'dd/mm/yyyy'
      Properties.ImmediatePost = True
      Properties.OnEditValueChanged = dtpFechaPropertiesEditValueChanged
      Properties.OnGetDayState = dtpFechaPropertiesGetDayState
      TabOrder = 0
      Width = 130
    end
    object lblBuscar: TcxLabel
      Left = 232
      Top = 18
      Caption = 'Buscar:'
      TabOrder = 3
    end
    object edtBuscar: TcxButtonEdit
      Left = 296
      Top = 16
      Properties.Buttons = <>
      Properties.OnChange = edtBuscarPropertiesChange
      TabOrder = 1
      Width = 500
    end
    object chkVerTodos: TcxCheckBox
      Left = 816
      Top = 16
      Hint = 'Muestra tambi'#233'n operaciones canceladas, anuladas y rectificadas por sustituci'#243'n'
      Caption = 'Ver todos'
      ParentShowHint = False
      Properties.OnChange = chkVerTodosPropertiesChange
      ShowHint = True
      TabOrder = 4
      Transparent = True
    end
    object chkVerMiniaturas: TcxCheckBox
      Left = 920
      Top = 16
      Hint = 'Muestra la columna Fotos con las miniaturas de los art'#237'culos de cada operaci'#243'n'
      Caption = 'Ver miniaturas en grid'
      ParentShowHint = False
      Properties.OnChange = chkVerMiniaturasPropertiesChange
      ShowHint = True
      TabOrder = 5
      Transparent = True
      Width = 190
    end
  end
  object pnlMaestro: TPanel [2]
    Left = 0
    Top = 56
    Width = 1163
    Height = 260
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    object cxGridMaestro: TcxGrid
      Left = 0
      Top = 0
      Width = 1163
      Height = 260
      Align = alClient
      TabOrder = 0
      object cxViewMaestro: TcxGridDBTableView
        OptionsBehavior.FocusCellOnCycle = True
        OptionsData.Deleting = False
        OptionsData.Editing = False
        OptionsData.Inserting = False
        OptionsSelection.CellSelect = False
        OptionsView.NoDataToDisplayInfoText = 'No hay operaciones para esta fecha'
        OptionsView.GroupByBox = False
        object colFechaOp: TcxGridDBColumn
          Caption = 'Fecha/Hora'
          DataBinding.FieldName = 'FECHA_OP'
          PropertiesClassName = 'TcxDateEditProperties'
          Properties.DisplayFormat = 'dd/mm/yyyy hh:nn'
          Properties.Kind = ckDateTime
          Width = 128
        end
        object colNumOp: TcxGridDBColumn
          Caption = 'N'#186' Operaci'#243'n'
          DataBinding.FieldName = 'NUMERO_OPERACION_OPCAJA'
          Width = 118
        end
        object colTiposOp: TcxGridDBColumn
          Caption = 'Tipos'
          DataBinding.FieldName = 'TIPOS_OP'
          PropertiesClassName = 'TcxTextEditProperties'
          Width = 86
        end
        object colSerieFactura: TcxGridDBColumn
          Caption = 'Serie'
          DataBinding.FieldName = 'SERIE_FAC'
          Width = 78
        end
        object colNroFactura: TcxGridDBColumn
          Caption = 'N'#186' Borrador'
          DataBinding.FieldName = 'NUMERO_FAC'
          Width = 97
        end
        object colFaseFactura: TcxGridDBColumn
          Caption = 'Fase'
          DataBinding.FieldName = 'FASE_FAC'
          Width = 150
        end
        object colCliente: TcxGridDBColumn
          Caption = 'Cliente'
          DataBinding.FieldName = 'CLIENTE'
          Width = 78
        end
        object colRazonSocial: TcxGridDBColumn
          Caption = 'Raz'#243'n social'
          DataBinding.FieldName = 'RAZON_SOCIAL_CLI'
          Width = 226
        end
        object colImporte: TcxGridDBColumn
          Caption = 'Importe'
          DataBinding.FieldName = 'IMPORTE_TOTAL'
          PropertiesClassName = 'TcxCurrencyEditProperties'
          Properties.DisplayFormat = '#,##0.00 '#8364
          Width = 101
        end
        object colFormaPago: TcxGridDBColumn
          Caption = 'Forma de pago'
          DataBinding.FieldName = 'FORMAS_PAGO'
          PropertiesClassName = 'TcxTextEditProperties'
          Width = 110
        end
        object colEmpleado: TcxGridDBColumn
          Caption = 'Empleado'
          DataBinding.FieldName = 'EMPLEADO'
          PropertiesClassName = 'TcxTextEditProperties'
          Width = 100
        end
        object colConceptos: TcxGridDBColumn
          Caption = 'Conceptos'
          DataBinding.FieldName = 'CONCEPTOS'
          PropertiesClassName = 'TcxTextEditProperties'
          Width = 230
        end
      end
      object cxLevelMaestro: TcxGridLevel
        GridView = cxViewMaestro
      end
    end
  end
  object pcHijos: TcxPageControl [3]
    Left = 0
    Top = 321
    Width = 1163
    Height = 326
    Align = alClient
    TabOrder = 2
    Properties.ActivePage = tsMovimientos
    Properties.CustomButtons.Buttons = <>
    ClientRectBottom = 322
    ClientRectLeft = 4
    ClientRectRight = 1159
    ClientRectTop = 28
    object tsOperacion: TcxTabSheet
      Caption = 'Operaci'#243'n '
      ImageIndex = 0
      object cxGridOpe: TcxGrid
        Left = 0
        Top = 0
        Width = 1155
        Height = 294
        Align = alClient
        TabOrder = 0
        object cxViewOpe: TcxGridDBTableView
          OptionsData.Deleting = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsView.GroupByBox = False
          object colOpeFecha: TcxGridDBColumn
            Caption = 'Fecha/Hora'
            DataBinding.FieldName = 'FECHA_OPERACION_OPCAJA'
            PropertiesClassName = 'TcxDateEditProperties'
            Properties.DisplayFormat = 'dd/mm/yyyy hh:nn:ss'
            Properties.Kind = ckDateTime
            Width = 140
          end
          object colOpeTipo: TcxGridDBColumn
            Caption = 'Tipo'
            DataBinding.FieldName = 'TIPO_OPERACION_OPCAJA'
            Width = 60
          end
          object colOpeImporte: TcxGridDBColumn
            Caption = 'Importe'
            DataBinding.FieldName = 'IMPORTE_TOTAL_OPCAJA'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00 '#8364
            Width = 110
          end
          object colOpeConcepto: TcxGridDBColumn
            Caption = 'Concepto'
            DataBinding.FieldName = 'CONCEPTO_GASTO_INGRESO_OPCAJA'
            Width = 340
          end
          object colOpeIdDep: TcxGridDBColumn
            Caption = 'Id dep'#243'sito'
            DataBinding.FieldName = 'ID_DEPOSITO_OPCAJA'
            Width = 160
          end
          object colOpeSerieRef: TcxGridDBColumn
            Caption = 'Serie ref.'
            DataBinding.FieldName = 'SERIE_REF_ORIGEN_OPCAJA'
            Width = 80
          end
          object colOpeNroRef: TcxGridDBColumn
            Caption = 'Nro ref.'
            DataBinding.FieldName = 'NUMERO_REF_ORIGEN_OPCAJA'
            Width = 80
          end
          object colOpeMotivo: TcxGridDBColumn
            Caption = 'Motivo dev.'
            DataBinding.FieldName = 'MOTIVO_DEVOLUCION_OPCAJA'
            Width = 130
          end
          object colOpeEstadoDev: TcxGridDBColumn
            Caption = 'Est.Dev.'
            DataBinding.FieldName = 'ESTADO_DEVOLUCION_OPCAJA'
            Width = 60
          end
        end
        object cxLevelOpe: TcxGridLevel
          GridView = cxViewOpe
        end
      end
    end
    object tsPagos: TcxTabSheet
      Caption = 'Pagos'
      ImageIndex = 1
      object cxGridPagos: TcxGrid
        Left = 0
        Top = 0
        Width = 1155
        Height = 294
        Align = alClient
        TabOrder = 0
        object cxViewPagos: TcxGridDBTableView
          DataController.Summary.FooterSummaryItems = <
            item
              Format = '#,##0.00 '#8364
              Kind = skSum
              Column = colPagNeto
            end>
          OptionsData.Deleting = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsView.Footer = True
          OptionsView.GroupByBox = False
          object colPagLinea: TcxGridDBColumn
            Caption = 'L'#237'nea'
            DataBinding.FieldName = 'NUMERO_LINEA_PAGO'
            Width = 96
          end
          object colPagCodigo: TcxGridDBColumn
            Caption = 'C'#243'digo'
            DataBinding.FieldName = 'CODIGO_FP_CFP'
            Width = 106
          end
          object colPagForma: TcxGridDBColumn
            Caption = 'Forma de pago'
            DataBinding.FieldName = 'DESCRIPCION_FORMA_PAGO_CFP'
            Width = 142
          end
          object colPagEntregado: TcxGridDBColumn
            Caption = 'Entregado'
            DataBinding.FieldName = 'IMPORTE_ENTREGADO_PAGO'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00 '#8364
            Width = 146
          end
          object colPagCambio: TcxGridDBColumn
            Caption = 'Cambio'
            DataBinding.FieldName = 'IMPORTE_CAMBIO_PAGO'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00 '#8364
            Width = 96
          end
          object colPagNeto: TcxGridDBColumn
            Caption = 'Neto'
            DataBinding.FieldName = 'IMPORTE_NETO_PAGO'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00 '#8364
            Width = 87
          end
          object colPagDivisa: TcxGridDBColumn
            Caption = 'Divisa'
            DataBinding.FieldName = 'CODIGO_DIVISA_PAGO'
            Width = 97
          end
          object colPagImpDivisa: TcxGridDBColumn
            Caption = 'Imp.divisa'
            DataBinding.FieldName = 'IMPORTE_DIVISA_PAGO'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00000000'
            Width = 150
          end
          object colPagBlockchain: TcxGridDBColumn
            Caption = 'Red'
            DataBinding.FieldName = 'RED_BLOCKCHAIN_PAGO'
            Width = 65
          end
          object colPagReferencia: TcxGridDBColumn
            Caption = 'Referencia'
            DataBinding.FieldName = 'REFERENCIA_FACPAG'
            Width = 131
          end
          object colPagObs: TcxGridDBColumn
            Caption = 'Observaciones'
            DataBinding.FieldName = 'OBSERVACIONES_PAGO'
            Width = 131
          end
        end
        object cxLevelPagos: TcxGridLevel
          GridView = cxViewPagos
        end
      end
    end
    object tsVales: TcxTabSheet
      Caption = 'Vales'
      ImageIndex = 2
      object cxGridVales: TcxGrid
        Left = 0
        Top = 0
        Width = 1155
        Height = 294
        Align = alClient
        TabOrder = 0
        object cxViewVales: TcxGridDBTableView
          DataController.Summary.FooterSummaryItems = <
            item
              Format = '#,##0.00 '#8364
              Kind = skSum
              Column = colValVNominal
            end
            item
              Format = '#,##0.00 '#8364
              Kind = skSum
              Column = colValVRedimido
            end>
          OptionsData.Deleting = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsView.Footer = True
          OptionsView.GroupByBox = False
          object colValVRol: TcxGridDBColumn
            Caption = 'Rol'
            DataBinding.FieldName = 'ROL_VL'
            Width = 70
          end
          object colValVCodigo: TcxGridDBColumn
            Caption = 'C'#243'd. vale'
            DataBinding.FieldName = 'CODIGO_VL'
            Width = 180
          end
          object colValVPin: TcxGridDBColumn
            Caption = 'PIN'
            DataBinding.FieldName = 'PIN_SEGURIDAD_VL'
            Width = 70
          end
          object colValVEstado: TcxGridDBColumn
            Caption = 'Estado'
            DataBinding.FieldName = 'ESTADO_VL'
            Width = 110
          end
          object colValVNominal: TcxGridDBColumn
            Caption = 'Nominal'
            DataBinding.FieldName = 'IMPORTE_NOMINAL_VL'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00 '#8364
            Width = 100
          end
          object colValVRedimido: TcxGridDBColumn
            Caption = 'Redimido'
            DataBinding.FieldName = 'IMPORTE_REDIMIDO_VL'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00 '#8364
            Width = 100
          end
          object colValVEmision: TcxGridDBColumn
            Caption = 'F. Emisi'#243'n'
            DataBinding.FieldName = 'FECHA_EMISION_VL'
            PropertiesClassName = 'TcxDateEditProperties'
            Properties.DisplayFormat = 'dd/mm/yyyy hh:nn'
            Properties.Kind = ckDateTime
            Width = 130
          end
          object colValVCaducidad: TcxGridDBColumn
            Caption = 'F. Caducidad'
            DataBinding.FieldName = 'FECHA_CADUCIDAD_VL'
            PropertiesClassName = 'TcxDateEditProperties'
            Properties.DisplayFormat = 'dd/mm/yyyy'
            Width = 110
          end
          object colValVRedencion: TcxGridDBColumn
            Caption = 'F. Redenci'#243'n'
            DataBinding.FieldName = 'FECHA_REDENCION_VL'
            PropertiesClassName = 'TcxDateEditProperties'
            Properties.DisplayFormat = 'dd/mm/yyyy hh:nn'
            Properties.Kind = ckDateTime
            Width = 130
          end
          object colValVPadre: TcxGridDBColumn
            Caption = 'Vale padre'
            DataBinding.FieldName = 'CODIGO_PADRE_VL'
            Width = 140
          end
          object colValVObs: TcxGridDBColumn
            Caption = 'Observaciones'
            DataBinding.FieldName = 'OBSERVACIONES_VL'
            Width = 200
          end
        end
        object cxLevelVales: TcxGridLevel
          GridView = cxViewVales
        end
      end
    end
    object tsMovimientos: TcxTabSheet
      Caption = 'Movimientos '
      ImageIndex = 1
      object cxGridMov: TcxGrid
        Left = 0
        Top = 0
        Width = 947
        Height = 294
        Align = alClient
        TabOrder = 0
        object cxViewMov: TcxGridDBTableView
          OnCustomDrawCell = cxViewMovCustomDrawCell
          OptionsData.Deleting = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsView.GroupByBox = False
          object colMovNum: TcxGridDBColumn
            Caption = 'N'#186' Mov'
            DataBinding.FieldName = 'NUMERO_MOV'
            Width = 94
          end
          object colMovTipoDoc: TcxGridDBColumn
            Caption = 'Tipo Doc'
            DataBinding.FieldName = 'TIPO_DOC_MOV'
            Width = 132
          end
          object colMovLinea: TcxGridDBColumn
            Caption = 'L'#237'nea'
            DataBinding.FieldName = 'LINEA_MOV'
            Width = 90
          end
          object colMovAlmacen: TcxGridDBColumn
            Caption = 'Almac'#233'n'
            DataBinding.FieldName = 'CODIGO_ALM_MOV'
            Width = 138
          end
          object colMovAlmacenContra: TcxGridDBColumn
            Caption = 'Contra'
            DataBinding.FieldName = 'CODIGO_ALM_CONTRA_MOV'
            Width = 112
          end
          object colMovArticulo: TcxGridDBColumn
            Caption = 'Art'#237'culo'
            DataBinding.FieldName = 'CODIGO_ART_MOV'
            Width = 88
          end
          object colMovSku: TcxGridDBColumn
            Caption = 'SKU'
            DataBinding.FieldName = 'CODIGO_UNIDAD_MOV'
            Width = 126
          end
          object colMovColor: TcxGridDBColumn
            Caption = 'Color'
            DataBinding.FieldName = 'COLOR_AV'
            Width = 120
          end
          object colMovTalla: TcxGridDBColumn
            Caption = 'Talla'
            DataBinding.FieldName = 'TALLA_AV'
            Width = 70
          end
          object colMovDesc: TcxGridDBColumn
            Caption = 'Descripci'#243'n'
            DataBinding.FieldName = 'DESCRIPCION_ART'
            Width = 206
          end
          object colMovTipo: TcxGridDBColumn
            Caption = 'E/S'
            DataBinding.FieldName = 'TIPO_MOV'
            Width = 89
          end
          object colMovCantidad: TcxGridDBColumn
            Caption = 'Cantidad'
            DataBinding.FieldName = 'CANTIDAD_MOV'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00'
            Width = 91
          end
          object colMovPMP: TcxGridDBColumn
            Caption = 'PMP'
            DataBinding.FieldName = 'PRECIO_MEDIO_MOV'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00 '#8364
            Width = 25
          end
          object colMovCoste: TcxGridDBColumn
            Caption = 'Total coste'
            DataBinding.FieldName = 'TOTAL_COSTE_MOV'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00 '#8364
            Width = 42
          end
        end
        object cxLevelMov: TcxGridLevel
          GridView = cxViewMov
        end
      end
      object splFotoConsulta: TcxSplitter
        Left = 947
        Top = 0
        Width = 8
        Height = 294
        AlignSplitter = salRight
        Control = pnlFotoConsulta
      end
      object pnlFotoConsulta: TPanel
        Left = 955
        Top = 0
        Width = 200
        Height = 294
        Align = alRight
        BevelOuter = bvLowered
        TabOrder = 1
        object imgFotoConsulta: TImage
          Left = 1
          Top = 1
          Width = 198
          Height = 292
          Align = alClient
          Center = True
          Proportional = True
          Stretch = True
        end
      end
    end
    object tsCliente: TcxTabSheet
      Caption = 'Cliente '
      ImageIndex = 2
      object cxGridCli: TcxGrid
        Left = 0
        Top = 0
        Width = 1155
        Height = 294
        Align = alClient
        TabOrder = 0
        object cxViewCli: TcxGridDBTableView
          OptionsData.Deleting = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsView.GroupByBox = False
          object colCliCodigo: TcxGridDBColumn
            Caption = 'C'#243'digo'
            DataBinding.FieldName = 'CODIGO_CLI_CLI'
            Width = 80
          end
          object colCliRazon: TcxGridDBColumn
            Caption = 'Raz'#243'n social'
            DataBinding.FieldName = 'RAZON_SOCIAL_CLI'
            Width = 250
          end
          object colCliNif: TcxGridDBColumn
            Caption = 'NIF'
            DataBinding.FieldName = 'NIF_CLI'
            Width = 100
          end
          object colCliMovil: TcxGridDBColumn
            Caption = 'M'#243'vil'
            DataBinding.FieldName = 'MOVIL_CLI'
            Width = 100
          end
          object colCliEmail: TcxGridDBColumn
            Caption = 'Email'
            DataBinding.FieldName = 'EMAIL_CLI'
            Width = 180
          end
          object colCliDir1: TcxGridDBColumn
            Caption = 'Direcci'#243'n'
            DataBinding.FieldName = 'DIRECCION1_CLI'
            Width = 200
          end
          object colCliPobl: TcxGridDBColumn
            Caption = 'Poblaci'#243'n'
            DataBinding.FieldName = 'POBLACION_CLI'
            Width = 130
          end
          object colCliProv: TcxGridDBColumn
            Caption = 'Provincia'
            DataBinding.FieldName = 'PROVINCIA_CLI'
            Width = 120
          end
          object colCliCP: TcxGridDBColumn
            Caption = 'C.P.'
            DataBinding.FieldName = 'CODIGO_POSTAL_CLI'
            Width = 60
          end
          object colCliDeuda: TcxGridDBColumn
            Caption = 'Deuda'
            DataBinding.FieldName = 'TOTAL_DEUDA_CLI'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00 '#8364
            Width = 100
          end
        end
        object cxLevelCli: TcxGridLevel
          GridView = cxViewCli
        end
      end
    end
    object tsDepositos: TcxTabSheet
      Caption = 'Dep'#243'sitos'
      ImageIndex = 3
      object cxGridDep: TcxGrid
        Left = 0
        Top = 0
        Width = 1155
        Height = 294
        Align = alClient
        TabOrder = 0
        object cxViewDep: TcxGridDBTableView
          DataController.Summary.FooterSummaryItems = <
            item
              Format = '#,##0.00 '#8364
              Kind = skSum
              Column = colDepAnt
            end
            item
              Format = '#,##0.00 '#8364
              Kind = skSum
              Column = colDepPendiente
            end>
          OptionsData.Deleting = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsView.Footer = True
          OptionsView.GroupByBox = False
          object colDepRol: TcxGridDBColumn
            Caption = 'Rol'
            DataBinding.FieldName = 'ROL_EN_OPERACION'
            Visible = False
            Width = 110
          end
          object colDepEstado: TcxGridDBColumn
            Caption = 'Estado'
            DataBinding.FieldName = 'ESTADO_DEP'
            Width = 130
          end
          object colDepId: TcxGridDBColumn
            Caption = 'Id dep'#243'sito'
            DataBinding.FieldName = 'ID_DEPOSITO_DEP'
            Width = 160
          end
          object colDepCli: TcxGridDBColumn
            Caption = 'Cliente'
            DataBinding.FieldName = 'CODIGO_CLI_DEP'
            Width = 110
          end
          object colDepArt: TcxGridDBColumn
            Caption = 'Art'#237'culo'
            DataBinding.FieldName = 'CODIGO_ART_DEP'
            Width = 141
          end
          object colDepSku: TcxGridDBColumn
            Caption = 'SKU'
            DataBinding.FieldName = 'CODIGO_UNIDAD_DEP'
            Width = 160
          end
          object colDepAlm: TcxGridDBColumn
            Caption = 'Almac'#233'n'
            DataBinding.FieldName = 'CODIGO_ALM_DEP'
            Width = 91
          end
          object colDepCant: TcxGridDBColumn
            Caption = 'Cantidad pdte.'
            DataBinding.FieldName = 'CANTIDAD_PENDIENTE_DEP'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00'
            Width = 131
          end
          object colDepPvp: TcxGridDBColumn
            Caption = 'Precio venta'
            DataBinding.FieldName = 'PRECIO_VENTA_DEP'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00 '#8364
            Width = 114
          end
          object colDepPorcIva: TcxGridDBColumn
            Caption = '% IVA'
            DataBinding.FieldName = 'PORCENTAJE_IVA_DEP'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '0.00'
            Width = 55
          end
          object colDepAnt: TcxGridDBColumn
            Caption = 'Anticipo'
            DataBinding.FieldName = 'IMPORTE_ANTICIPO_DEP'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00 '#8364
            Width = 90
          end
          object colDepPendiente: TcxGridDBColumn
            Caption = 'Pendiente'
            DataBinding.FieldName = 'IMPORTE_PENDIENTE_DEP'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00 '#8364
            Width = 100
          end
          object colDepFecha: TcxGridDBColumn
            Caption = 'Fecha alta'
            DataBinding.FieldName = 'FECHA_CREACION_DEP'
            PropertiesClassName = 'TcxDateEditProperties'
            Properties.DisplayFormat = 'dd/mm/yyyy hh:nn'
            Properties.Kind = ckDateTime
            Width = 120
          end
          object colDepFechaEntrega: TcxGridDBColumn
            Caption = 'Fecha entrega'
            DataBinding.FieldName = 'FECHA_ENTREGA_DEP'
            PropertiesClassName = 'TcxDateEditProperties'
            Properties.DisplayFormat = 'dd/mm/yyyy'
            Width = 146
          end
          object colDepEmpCancel: TcxGridDBColumn
            Caption = 'Emp. cancel.'
            DataBinding.FieldName = 'EMPRESA_CANCEL_DEP'
            Visible = False
            Width = 80
          end
          object colDepAlmCancel: TcxGridDBColumn
            Caption = 'Alm. cancel.'
            DataBinding.FieldName = 'ALMACEN_CANCEL_DEP'
            Visible = False
            Width = 80
          end
          object colDepCajCancel: TcxGridDBColumn
            Caption = 'Caja cancel.'
            DataBinding.FieldName = 'CAJA_CANCEL_DEP'
            Visible = False
            Width = 70
          end
          object colDepNumOpeCancel: TcxGridDBColumn
            Caption = 'Op. cancel.'
            DataBinding.FieldName = 'NUMERO_OPERACION_CANCEL_DEP'
            Visible = False
            Width = 100
          end
        end
        object cxLevelDep: TcxGridLevel
          GridView = cxViewDep
        end
      end
    end
    object tsFactura: TcxTabSheet
      Caption = 'Borrador '
      ImageIndex = 4
      object pnlFacCabecera: TPanel
        Left = 0
        Top = 0
        Width = 1155
        Height = 70
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object cxGridFacCab: TcxGrid
          Left = 0
          Top = 0
          Width = 1155
          Height = 70
          Align = alClient
          TabOrder = 0
          object cxViewFacCab: TcxGridDBTableView
            OptionsData.Deleting = False
            OptionsData.Editing = False
            OptionsData.Inserting = False
            OptionsView.GroupByBox = False
            object colFacSerie: TcxGridDBColumn
              Caption = 'Serie'
              DataBinding.FieldName = 'SERIE_FAC'
              Width = 80
            end
            object colFacNro: TcxGridDBColumn
              Caption = 'N'#186
              DataBinding.FieldName = 'NUMERO_FAC'
              Width = 80
            end
            object colFacFecha: TcxGridDBColumn
              Caption = 'Fecha'
              DataBinding.FieldName = 'FECHA_FAC'
              PropertiesClassName = 'TcxDateEditProperties'
              Properties.DisplayFormat = 'dd/mm/yyyy'
              Width = 100
            end
            object colFacTipo: TcxGridDBColumn
              Caption = 'Tipo'
              DataBinding.FieldName = 'TIPO_FAC'
              Width = 110
            end
            object colFacCliente: TcxGridDBColumn
              Caption = 'Cliente'
              DataBinding.FieldName = 'CODIGO_CLI_FAC'
              Width = 80
            end
            object colFacRazon: TcxGridDBColumn
              Caption = 'Raz'#243'n social'
              DataBinding.FieldName = 'RAZON_SOCIAL_CLIENTE_FAC'
              Width = 220
            end
            object colFacBases: TcxGridDBColumn
              Caption = 'Bases'
              DataBinding.FieldName = 'TOTAL_BASES_FAC'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 100
            end
            object colFacImp: TcxGridDBColumn
              Caption = 'Impuestos'
              DataBinding.FieldName = 'TOTAL_IMPUESTOS_FAC'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 100
            end
            object colFacLiq: TcxGridDBColumn
              Caption = 'L'#237'quido'
              DataBinding.FieldName = 'TOTAL_LIQUIDO_FAC'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 110
            end
          end
          object cxLevelFacCab: TcxGridLevel
            GridView = cxViewFacCab
          end
        end
      end
      object cxGridFacLin: TcxGrid
        Left = 0
        Top = 70
        Width = 1155
        Height = 224
        Align = alClient
        TabOrder = 1
        object cxViewFacLin: TcxGridDBTableView
          OptionsData.Deleting = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsView.GroupByBox = False
          object colFlLinea: TcxGridDBColumn
            Caption = 'L'#237'n'
            DataBinding.FieldName = 'LINEA_FACLIN'
            Width = 50
          end
          object colFlArt: TcxGridDBColumn
            Caption = 'Art'#237'culo'
            DataBinding.FieldName = 'CODIGO_ART_FACLIN'
            Width = 110
          end
          object colFlSku: TcxGridDBColumn
            Caption = 'SKU'
            DataBinding.FieldName = 'CODIGO_UNIDAD_FACLIN'
            Width = 160
          end
          object colFlDesc: TcxGridDBColumn
            Caption = 'Descripci'#243'n'
            DataBinding.FieldName = 'DESCRIPCION_ARTICULO_FACLIN'
            Width = 280
          end
          object colFlCant: TcxGridDBColumn
            Caption = 'Cant.'
            DataBinding.FieldName = 'CANTIDAD_FACLIN'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00'
            Width = 70
          end
          object colFlPrSiva: TcxGridDBColumn
            Caption = 'P.S.IVA'
            DataBinding.FieldName = 'PRECIO_VENTA_SIVA_ARTICULO_FACLIN'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00 '#8364
            Width = 90
          end
          object colFlPrCiva: TcxGridDBColumn
            Caption = 'P.C.IVA'
            DataBinding.FieldName = 'PRECIO_VENTA_CIVA_ARTICULO_FACLIN'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00 '#8364
            Width = 90
          end
          object colFlDto: TcxGridDBColumn
            Caption = '% Dto'
            DataBinding.FieldName = 'PORCENTAJE_DTO_FACLIN'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '0.00 %'
            Width = 60
          end
          object colFlTipoIva: TcxGridDBColumn
            Caption = 'T.IVA'
            DataBinding.FieldName = 'TIPO_IVA_ARTICULO_FACLIN'
            Width = 50
          end
          object colFlPorcIva: TcxGridDBColumn
            Caption = '% IVA'
            DataBinding.FieldName = 'PORCENTAJE_IVA_FACLIN'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '0.00'
            Width = 60
          end
          object colFlTotSiva: TcxGridDBColumn
            Caption = 'Tot. S.IVA'
            DataBinding.FieldName = 'TOTAL_FAC_SIVA_FACLIN'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00 '#8364
            Width = 100
          end
          object colFlTotCiva: TcxGridDBColumn
            Caption = 'Tot. C.IVA'
            DataBinding.FieldName = 'TOTAL_FACLIN'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.DisplayFormat = '#,##0.00 '#8364
            Width = 100
          end
        end
        object cxLevelFacLin: TcxGridLevel
          GridView = cxViewFacLin
        end
      end
    end
  end
  object pnlPie: TPanel [4]
    Left = 0
    Top = 647
    Width = 1163
    Height = 73
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 3
    DesignSize = (
      1163
      73)
    object btnReimprimir: TcxButton
      Left = 12
      Top = 6
      Width = 120
      Height = 28
      Caption = 'Reimprimir'
      TabOrder = 0
      OnClick = btnReimprimirClick
    end
    object btnCerrar: TcxButton
      Left = 1041
      Top = 6
      Width = 108
      Height = 28
      Anchors = [akTop, akRight]
      Caption = 'Cerrar (ESC)'
      TabOrder = 6
      OnClick = btnCerrarClick
    end
    object btnDevolverAbonar: TcxButton
      Left = 332
      Top = 6
      Width = 222
      Height = 28
      Caption = 'Devolver Abonar Operaci'#243'n'
      TabOrder = 2
      OnClick = btnDevolverAbonarClick
    end
    object btnRectificar: TcxButton
      Left = 562
      Top = 6
      Width = 100
      Height = 28
      Caption = 'Rectificar'
      TabOrder = 3
      OnClick = btnRectificarClick
    end
    object btnAnularVerifactu: TcxButton
      Left = 670
      Top = 6
      Width = 174
      Height = 28
      Caption = 'Anular registro fiscal'
      TabOrder = 4
      OnClick = btnAnularVerifactuClick
    end
    object btnFacturarTicket: TcxButton
      Left = 852
      Top = 6
      Width = 164
      Height = 28
      Caption = 'Convertir en normal'
      TabOrder = 5
      OnClick = btnFacturarTicketClick
    end
    object btnReimprimirOtros: TcxButton
      Left = 142
      Top = 6
      Width = 112
      Height = 28
      Caption = 'Previsualizar'
      TabOrder = 1
      OnClick = btnReimprimirOtrosClick
    end
    object btnEnviarEmail: TcxButton
      Left = 260
      Top = 6
      Width = 64
      Height = 28
      Caption = 'e-mail'
      TabOrder = 7
      OnClick = btnEnviarEmailClick
    end
    object btnSubsanar: TcxButton
      Left = 12
      Top = 39
      Width = 132
      Height = 28
      Caption = 'Subsanar'
      Enabled = False
      TabOrder = 9
      OnClick = btnSubsanarClick
    end
  end
  object tmrBusqueda: TTimer
    Enabled = False
    Interval = 400
    OnTimer = tmrBusquedaTimer
    Left = 840
    Top = 16
  end
end
