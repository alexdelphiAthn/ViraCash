inherited frmMtoCajaSeleccionVale: TfrmMtoCajaSeleccionVale
  Left = 0
  Top = 0
  Caption = 'Seleccionar Vale'
  ClientHeight = 520
  ClientWidth = 954
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -17
  Font.Name = 'Source Sans 3'
  Font.Style = []
  Position = poMainFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  TextHeight = 19
  object pnlPrincipal: TPanel
    Left = 0
    Top = 0
    Width = 954
    Height = 520
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    ExplicitWidth = 962
    ExplicitHeight = 521
    object pnlSuperior: TPanel
      Left = 0
      Top = 0
      Width = 958
      Height = 60
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
      ExplicitWidth = 962
      object lblBuscar: TcxLabel
        Left = 8
        Top = 20
        Caption = 'Buscar vale:'
        TabOrder = 2
        Transparent = True
      end
      object edtBuscar: TcxTextEdit
        Left = 117
        Top = 16
        TabOrder = 0
        OnKeyDown = edtBuscarPropertiesKeyDown
        Width = 233
      end
      object btnBuscar: TcxButton
        Left = 356
        Top = 15
        Width = 142
        Height = 39
        Caption = 'Buscar [Enter]'
        TabOrder = 1
        OnClick = btnBuscarClick
      end
      object cxLabel1: TcxLabel
        Left = 512
        Top = 17
        Caption = 'El Vale no se canjea hasta que confirme la operaci'#243'n.'
        TabOrder = 3
        Transparent = True
      end
    end
    object cxgrdVales: TcxGrid
      Left = 0
      Top = 60
      Width = 958
      Height = 401
      Align = alClient
      TabOrder = 1
      ExplicitWidth = 952
      ExplicitHeight = 392
      object dbtvVales: TcxGridDBTableView
        OnDblClick = dbtvValesDblClick
        OnFocusedRecordChanged = dbtvValesFocusedRecordChanged
        DataController.DataSource = dsVales
        DataController.KeyFieldNames = 'CODIGO_VL'
        OptionsBehavior.FocusCellOnTab = True
        OptionsBehavior.GoToNextCellOnEnter = True
        OptionsSelection.CellSelect = False
        object colCodigo: TcxGridDBColumn
          Caption = 'C'#243'digo Vale'
          DataBinding.FieldName = 'CODIGO_VL'
          Options.Editing = False
          Width = 170
        end
        object colEmpresa: TcxGridDBColumn
          Caption = 'Empresa'
          DataBinding.FieldName = 'CODIGO_EMP_EMI_VL'
          Options.Editing = False
          Width = 85
        end
        object colAlmacenEmisor: TcxGridDBColumn
          Caption = 'Almac'#233'n emisor'
          DataBinding.FieldName = 'CODIGO_ALM_EMI_VL'
          Options.Editing = False
          Width = 110
        end
        object colEstado: TcxGridDBColumn
          Caption = 'Estado'
          DataBinding.FieldName = 'ESTADO_VL'
          Options.Editing = False
          Width = 90
        end
        object colImporte: TcxGridDBColumn
          Caption = 'Importe'
          DataBinding.FieldName = 'IMPORTE_NOMINAL_VL'
          Options.Editing = False
          Width = 90
        end
        object colFechaEmision: TcxGridDBColumn
          Caption = 'Fecha emisi'#243'n'
          DataBinding.FieldName = 'FECHA_EMISION_VL'
          Options.Editing = False
          SortIndex = 0
          SortOrder = soDescending
          Width = 135
        end
        object colCaducidad: TcxGridDBColumn
          Caption = 'Caducidad'
          DataBinding.FieldName = 'FECHA_CADUCIDAD_VL'
          Options.Editing = False
          Width = 110
        end
        object colObservaciones: TcxGridDBColumn
          Caption = 'Observaciones'
          DataBinding.FieldName = 'OBSERVACIONES_VL'
          Options.Editing = False
          Width = 145
        end
      end
      object cxgrdlvlVales: TcxGridLevel
        GridView = dbtvVales
      end
    end
    object pnlBotones: TPanel
      Left = 0
      Top = 461
      Width = 958
      Height = 60
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 2
      ExplicitWidth = 962
      object btnAceptar: TcxButton
        Left = 808
        Top = 14
        Width = 137
        Height = 32
        Caption = 'Aceptar (F12)'
        Default = True
        TabOrder = 0
        OnClick = btnAceptarClick
      end
      object btnCancelar: TcxButton
        Left = 640
        Top = 14
        Width = 151
        Height = 32
        Cancel = True
        Caption = 'Cancelar (ESC)'
        TabOrder = 1
        OnClick = btnCancelarClick
      end
      object lblPin: TcxLabel
        Left = 7
        Top = 17
        Caption = 'PIN:'
        TabOrder = 2
        Transparent = True
      end
      object edtPin: TcxTextEdit
        Left = 51
        Top = 16
        Properties.EchoMode = eemPassword
        TabOrder = 3
        Width = 120
      end
    end
  end
  object dsVales: TDataSource
    Left = 568
    Top = 464
  end
end
