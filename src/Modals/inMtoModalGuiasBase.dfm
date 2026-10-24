inherited frmModalGuiasBase: TfrmModalGuiasBase
  BorderIcons = [biSystemMenu]
  Caption = 'Gu'#237'as'
  ClientHeight = 620
  ClientWidth = 1100
  Position = poMainFormCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnShow = FormShow
  TextHeight = 19
  object pnlCabecera: TPanel [0]
    Left = 0
    Top = 0
    Width = 1100
    Height = 42
    Align = alTop
    BevelOuter = bvNone
    Color = 16444393
    ParentBackground = False
    TabOrder = 0
    object lblTitulo: TcxLabel
      Left = 16
      Top = 10
      Caption = 'Gu'#237'as'
      Style.Font.Charset = DEFAULT_CHARSET
      Style.Font.Color = 3618615
      Style.Font.Height = -15
      Style.Font.Name = 'Source Sans 3'
      Style.Font.Style = [fsBold]
      Style.IsFontAssigned = True
      Style.TransparentBorder = False
      Transparent = True
    end
    object lblInfo: TcxLabel
      Left = 250
      Top = 12
      Caption = ' '
      Style.Font.Charset = DEFAULT_CHARSET
      Style.Font.Color = 6710886
      Style.Font.Height = -15
      Style.Font.Name = 'Source Sans 3'
      Style.Font.Style = []
      Style.IsFontAssigned = True
      Transparent = True
    end
  end
  object pnlConstructor: TPanel [1]
    Left = 0
    Top = 42
    Width = 1100
    Height = 310
    Align = alTop
    BevelOuter = bvNone
    Color = 16380385
    ParentBackground = False
    TabOrder = 1
    object pnlCamposGrid: TPanel
      Left = 8
      Top = 4
      Width = 300
      Height = 300
      BevelOuter = bvNone
      Color = 16380385
      ParentBackground = False
      TabOrder = 0
      object lblCamposMaster: TcxLabel
        Left = 0
        Top = 0
        Caption = 'Campos master:'
        Style.Font.Charset = DEFAULT_CHARSET
        Style.Font.Color = 4210752
        Style.Font.Height = -13
        Style.Font.Name = 'Source Sans 3'
        Style.Font.Style = [fsBold]
        Style.IsFontAssigned = True
        Transparent = True
      end
      object lbCamposMaster: TcxListBox
        Left = 0
        Top = 22
        Width = 296
        Height = 274
        Style.Font.Charset = DEFAULT_CHARSET
        Style.Font.Color = clWindowText
        Style.Font.Height = -12
        Style.Font.Name = 'Consolas'
        Style.Font.Style = []
        Style.IsFontAssigned = True
        TabOrder = 0
        OnClick = lbCamposMasterClick
      end
    end
    object pnlTabla: TPanel
      Left = 316
      Top = 4
      Width = 300
      Height = 300
      BevelOuter = bvNone
      Color = 16380385
      ParentBackground = False
      TabOrder = 1
      object lblTabla: TcxLabel
        Left = 0
        Top = 0
        Caption = 'Tabla externa:'
        Style.Font.Charset = DEFAULT_CHARSET
        Style.Font.Color = 4210752
        Style.Font.Height = -13
        Style.Font.Name = 'Source Sans 3'
        Style.Font.Style = [fsBold]
        Style.IsFontAssigned = True
        Transparent = True
      end
      object cbbTabla: TcxComboBox
        Left = 0
        Top = 22
        Properties.DropDownListStyle = lsEditFixedList
        Properties.OnChange = cbbTablaPropertiesChange
        Style.Font.Charset = DEFAULT_CHARSET
        Style.Font.Color = clWindowText
        Style.Font.Height = -12
        Style.Font.Name = 'Consolas'
        Style.Font.Style = []
        Style.IsFontAssigned = True
        TabOrder = 0
        Width = 296
      end
      object lblCamposTabla: TcxLabel
        Left = 0
        Top = 52
        Caption = 'Campos de la tabla (detail):'
        Style.Font.Charset = DEFAULT_CHARSET
        Style.Font.Color = 4210752
        Style.Font.Height = -13
        Style.Font.Name = 'Source Sans 3'
        Style.Font.Style = [fsBold]
        Style.IsFontAssigned = True
        Transparent = True
      end
      object lbCamposTabla: TcxListBox
        Left = 0
        Top = 74
        Width = 296
        Height = 222
        Style.Font.Charset = DEFAULT_CHARSET
        Style.Font.Color = clWindowText
        Style.Font.Height = -12
        Style.Font.Name = 'Consolas'
        Style.Font.Style = []
        Style.IsFontAssigned = True
        TabOrder = 1
        OnClick = lbCamposTablaClick
      end
    end
    object pnlAcciones: TPanel
      Left = 624
      Top = 4
      Width = 468
      Height = 300
      BevelOuter = bvNone
      Color = 16380385
      ParentBackground = False
      TabOrder = 2
      object lblCodigo: TcxLabel
        Left = 0
        Top = 0
        Caption = 'C'#243'digo de la gu'#237'a:'
        Style.Font.Charset = DEFAULT_CHARSET
        Style.Font.Color = 4210752
        Style.Font.Height = -13
        Style.Font.Name = 'Source Sans 3'
        Style.Font.Style = [fsBold]
        Style.IsFontAssigned = True
        Transparent = True
      end
      object edtCodigo: TcxTextEdit
        Left = 0
        Top = 22
        Style.Font.Charset = DEFAULT_CHARSET
        Style.Font.Color = clWindowText
        Style.Font.Height = -12
        Style.Font.Name = 'Consolas'
        Style.Font.Style = []
        Style.IsFontAssigned = True
        TabOrder = 0
        Width = 250
      end
      object lblResumen: TcxLabel
        Left = 0
        Top = 56
        Caption = 'Enlace configurado:'
        Style.Font.Charset = DEFAULT_CHARSET
        Style.Font.Color = 4210752
        Style.Font.Height = -13
        Style.Font.Name = 'Source Sans 3'
        Style.Font.Style = [fsBold]
        Style.IsFontAssigned = True
        Transparent = True
      end
      object mmoResumen: TcxMemo
        Left = 0
        Top = 78
        Properties.ReadOnly = True
        Properties.ScrollBars = ssVertical
        Style.Font.Charset = DEFAULT_CHARSET
        Style.Font.Color = clWindowText
        Style.Font.Height = -12
        Style.Font.Name = 'Consolas'
        Style.Font.Style = []
        Style.IsFontAssigned = True
        TabOrder = 1
        Height = 150
        Width = 460
      end
      object btnAnadir: TcxButton
        Left = 0
        Top = 240
        Width = 220
        Height = 36
        Caption = 'A'#241'adir gu'#237'a'
        TabOrder = 2
        OnClick = btnAnadirClick
      end
      object btnEliminar: TcxButton
        Left = 232
        Top = 240
        Width = 220
        Height = 36
        Caption = 'Eliminar seleccionada'
        TabOrder = 3
        OnClick = btnEliminarClick
      end
    end
  end
  object pnlBotones: TPanel [2]
    Left = 0
    Top = 571
    Width = 1100
    Height = 49
    Align = alBottom
    BevelOuter = bvNone
    Color = 16513252
    ParentBackground = False
    TabOrder = 2
    object btnCerrar: TcxButton
      Left = 931
      Top = 11
      Width = 155
      Height = 29
      Caption = '&Cerrar'
      Colors.Default = 14598878
      LookAndFeel.NativeStyle = False
      LookAndFeel.SkinName = 'Office2019Colorful'
      TabOrder = 0
      OnClick = btnCerrarClick
    end
  end
  object grdGuias: TcxGrid [3]
    Left = 0
    Top = 352
    Width = 1100
    Height = 219
    Align = alClient
    TabOrder = 3
    LookAndFeel.NativeStyle = False
    object tvGuias: TcxGridDBTableView
      Navigator.Buttons.CustomButtons = <>
      Navigator.Visible = False
      DataController.DataSource = dsGuias
      DataController.Options = [dcoCaseInsensitive, dcoAssignGroupingValues, dcoAssignMasterDetailKeys, dcoSaveExpanding]
      OptionsBehavior.AlwaysShowEditor = False
      OptionsBehavior.GoToNextCellOnEnter = True
      OptionsData.CancelOnExit = True
      OptionsData.Deleting = False
      OptionsData.Editing = False
      OptionsData.Inserting = False
      OptionsView.GroupByBox = False
      OptionsView.Indicator = True
      Styles.Header = cxsHeader
      object tvGuiasCODIGO: TcxGridDBColumn
        Caption = 'C'#243'digo'
        DataBinding.FieldName = 'CODIGO_INFGUI'
        Width = 140
      end
      object tvGuiasTABLA: TcxGridDBColumn
        Caption = 'Tabla'
        DataBinding.FieldName = 'TABLA_INFGUI'
        Width = 150
      end
      object tvGuiasMASTER_FIELDS: TcxGridDBColumn
        Caption = 'Master fields'
        DataBinding.FieldName = 'MASTER_FIELDS_INFGUI'
        Width = 200
      end
      object tvGuiasDETAIL_FIELDS: TcxGridDBColumn
        Caption = 'Detail fields'
        DataBinding.FieldName = 'DETAIL_FIELDS_INFGUI'
        Width = 200
      end
      object tvGuiasORDEN: TcxGridDBColumn
        Caption = 'Orden'
        DataBinding.FieldName = 'ORDEN_INFGUI'
        Width = 60
      end
      object tvGuiasACTIVO: TcxGridDBColumn
        Caption = 'Activo'
        DataBinding.FieldName = 'ESACTIVO_INFGUI'
        Width = 60
      end
    end
    object lvGuias: TcxGridLevel
      GridView = tvGuias
    end
  end
  inherited Localizer1: TcxLocalizer
    Left = 832
    Top = 400
  end
  object dsGuias: TDataSource
    Left = 32
    Top = 476
  end
  object ActionList1: TActionList
    Left = 32
    Top = 540
    object actSalir: TAction
      Caption = 'Salir'
      ShortCut = 27
      OnExecute = actSalirExecute
    end
  end
  object cxStyleRepo: TcxStyleRepository
    Left = 832
    Top = 464
    PixelsPerInch = 96
    object cxsHeader: TcxStyle
      AssignedValues = [svColor, svFont]
      Color = 14998263
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Source Sans 3'
      Font.Style = [fsBold]
    end
  end
end
