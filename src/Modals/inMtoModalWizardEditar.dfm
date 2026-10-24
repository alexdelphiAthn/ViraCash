inherited frmModalWizardEditar: TfrmModalWizardEditar
  BorderIcons = [biSystemMenu]
  Caption = 'Editar informe'
  ClientHeight = 600
  ClientWidth = 1100
  Position = poMainFormCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnShow = FormShow
  TextHeight = 19
  object wzWizard: TJvWizard [0]
    Left = 0
    Top = 0
    Width = 1100
    Height = 600
    ButtonBarHeight = 52
    ButtonBack.Caption = '< &Anterior'
    ButtonBack.Width = 100
    ButtonNext.Caption = '&Siguiente >'
    ButtonNext.Width = 100
    ButtonFinish.Caption = '&Finalizar'
    ButtonFinish.Width = 100
    ButtonCancel.Caption = '&Cancelar'
    ButtonCancel.Width = 100
    ShowRouteMap = False
    OnFinishButtonClick = wzWizardFinishButtonClick
    OnCancelButtonClick = wzWizardCancelButtonClick
    object pgFormato: TJvWizardInteriorPage
      OnNextButtonClick = pgFormatoNextButtonClick
      object pnlPaso1: TPanel
        Left = 0
        Top = 0
        Width = 1100
        Height = 471
        Align = alClient
        BevelOuter = bvNone
        Color = clWindow
        ParentBackground = False
        TabOrder = 0
        object lblOrigen: TcxLabel
          Left = 48
          Top = 40
          Caption = 'Informe'
          Transparent = True
        end
        object edtOrigen: TcxTextEdit
          Left = 240
          Top = 37
          Enabled = False
          Properties.ReadOnly = True
          Style.Color = clBtnFace
          TabOrder = 0
          Width = 420
        end
        object lblFormato: TcxLabel
          Left = 48
          Top = 84
          Caption = 'Formato'
          Transparent = True
        end
        object cbbFormato: TcxComboBox
          Left = 240
          Top = 81
          Properties.DropDownListStyle = lsFixedList
          Properties.OnChange = cbbFormatoPropertiesChange
          TabOrder = 1
          Width = 420
        end
        object lblNombreNuevo: TcxLabel
          Left = 48
          Top = 128
          Caption = 'Nombre nuevo'
          Transparent = True
        end
        object edtNombreNuevo: TcxTextEdit
          Left = 240
          Top = 125
          TabOrder = 2
          Width = 420
        end
        object lblScope: TcxLabel
          Left = 48
          Top = 172
          Caption = 'Permiso (scope)'
          Transparent = True
        end
        object cbbScope: TcxComboBox
          Left = 240
          Top = 169
          Properties.DropDownListStyle = lsFixedList
          TabOrder = 3
          Width = 420
        end
        object lblAyudaPaso1: TcxLabel
          Left = 48
          Top = 220
          Caption = 'En el siguiente paso podr'#225's ver los datasets del informe (cabecera y detalle) y configurar las gu'#237'as de datos que se ligar'#225'n a este formato.'
          Properties.WordWrap = True
          Style.Font.Charset = DEFAULT_CHARSET
          Style.Font.Color = 6710886
          Style.Font.Height = -15
          Style.Font.Name = 'Source Sans 3'
          Style.Font.Style = [fsItalic]
          Style.IsFontAssigned = True
          Transparent = True
          Width = 612
        end
      end
    end
    object pgGuias: TJvWizardInteriorPage
      OnPage = pgGuiasShow
      object pnlPaso2: TPanel
        Left = 0
        Top = 0
        Width = 1100
        Height = 471
        Align = alClient
        BevelOuter = bvNone
        ParentBackground = False
        TabOrder = 0
        object pnlInfoGuias: TPanel
          Left = 0
          Top = 0
          Width = 1100
          Height = 30
          Align = alTop
          BevelOuter = bvNone
          Color = 16444393
          ParentBackground = False
          TabOrder = 0
          object lblTituloGuias: TcxLabel
            Left = 16
            Top = 4
            Caption = 'Gu'#237'as'
            Style.Font.Charset = DEFAULT_CHARSET
            Style.Font.Color = 3618615
            Style.Font.Height = -15
            Style.Font.Name = 'Source Sans 3'
            Style.Font.Style = [fsBold]
            Style.IsFontAssigned = True
            Transparent = True
          end
        end
        object pnlSelectorDS: TPanel
          Left = 0
          Top = 30
          Width = 1100
          Height = 220
          Align = alTop
          BevelOuter = bvNone
          Color = 16380385
          ParentBackground = False
          TabOrder = 1
          object lblDatasets: TcxLabel
            Left = 16
            Top = 8
            Caption = '1. Dataset master'
            Style.Font.Charset = DEFAULT_CHARSET
            Style.Font.Color = 3618615
            Style.Font.Height = -15
            Style.Font.Name = 'Source Sans 3'
            Style.Font.Style = [fsBold]
            Style.IsFontAssigned = True
            Transparent = True
          end
          object lstDatasets: TcxListBox
            Left = 16
            Top = 32
            Width = 200
            Height = 178
            ItemHeight = 19
            Style.Font.Charset = DEFAULT_CHARSET
            Style.Font.Color = clWindowText
            Style.Font.Height = -15
            Style.Font.Name = 'Source Sans 3'
            Style.IsFontAssigned = True
            TabOrder = 0
            OnClick = lstDatasetsClick
          end
          object lblCampos: TcxLabel
            Left = 232
            Top = 8
            Caption = '2. Master fields (uno o varios)'
            Style.Font.Charset = DEFAULT_CHARSET
            Style.Font.Color = 3618615
            Style.Font.Height = -15
            Style.Font.Name = 'Source Sans 3'
            Style.Font.Style = [fsBold]
            Style.IsFontAssigned = True
            Transparent = True
          end
          object lstCampos: TcxCheckListBox
            Left = 232
            Top = 32
            Width = 240
            Height = 178
            Items = <>
            Style.Font.Charset = DEFAULT_CHARSET
            Style.Font.Color = clWindowText
            Style.Font.Height = -15
            Style.Font.Name = 'Source Sans 3'
            Style.IsFontAssigned = True
            TabOrder = 1
          end
          object lblTablas: TcxLabel
            Left = 488
            Top = 8
            Caption = '3. Tabla o vista externa'
            Style.Font.Charset = DEFAULT_CHARSET
            Style.Font.Color = 3618615
            Style.Font.Height = -15
            Style.Font.Name = 'Source Sans 3'
            Style.Font.Style = [fsBold]
            Style.IsFontAssigned = True
            Transparent = True
          end
          object lstTablas: TcxListBox
            Left = 488
            Top = 32
            Width = 240
            Height = 178
            ItemHeight = 19
            Style.Font.Charset = DEFAULT_CHARSET
            Style.Font.Color = clWindowText
            Style.Font.Height = -15
            Style.Font.Name = 'Source Sans 3'
            Style.IsFontAssigned = True
            TabOrder = 2
            OnClick = lstTablasClick
          end
          object lblCamposTabla: TcxLabel
            Left = 744
            Top = 8
            Caption = '4. Campo de uni'#243'n (PK marcada con *)'
            Style.Font.Charset = DEFAULT_CHARSET
            Style.Font.Color = 3618615
            Style.Font.Height = -15
            Style.Font.Name = 'Source Sans 3'
            Style.Font.Style = [fsBold]
            Style.IsFontAssigned = True
            Transparent = True
          end
          object lstCamposTabla: TcxListBox
            Left = 744
            Top = 32
            Width = 340
            Height = 178
            ItemHeight = 19
            MultiSelect = True
            Style.Font.Charset = DEFAULT_CHARSET
            Style.Font.Color = clWindowText
            Style.Font.Height = -13
            Style.Font.Name = 'Consolas'
            Style.IsFontAssigned = True
            TabOrder = 3
            OnClick = lstCamposTablaClick
          end
        end
        object pnlAddGuia: TPanel
          Left = 0
          Top = 250
          Width = 1100
          Height = 50
          Align = alTop
          BevelOuter = bvNone
          Color = 16513252
          ParentBackground = False
          TabOrder = 2
          object lblCodigoNuevo: TcxLabel
            Left = 16
            Top = 15
            Caption = '5. Los campos de la tabla externa se a'#241'aden al master (UserName se mantiene). Colisiones -> sufijo 1,2,...'
            Style.Font.Charset = DEFAULT_CHARSET
            Style.Font.Color = 4210752
            Style.Font.Height = -15
            Style.Font.Name = 'Source Sans 3'
            Style.Font.Style = [fsItalic]
            Style.IsFontAssigned = True
            Transparent = True
          end
          object btnAddGuia: TcxButton
            Left = 760
            Top = 9
            Width = 320
            Height = 31
            Caption = '+ A'#241'adir gu'#237'a con esta configuraci'#243'n'
            LookAndFeel.NativeStyle = False
            LookAndFeel.SkinName = 'Office2019Colorful'
            TabOrder = 0
            OnClick = btnAddGuiaClick
          end
        end
        object grdGuias: TcxGrid
          Left = 0
          Top = 300
          Width = 1100
          Height = 171
          Align = alClient
          TabOrder = 2
          LookAndFeel.NativeStyle = False
          object tvGuias: TcxGridDBTableView
            Navigator.Buttons.CustomButtons = <>
            Navigator.Buttons.ConfirmDelete = True
            Navigator.Buttons.Insert.Visible = False
            Navigator.Buttons.Delete.Visible = True
            Navigator.Buttons.Edit.Visible = True
            Navigator.Buttons.Post.Visible = True
            Navigator.Buttons.Cancel.Visible = True
            Navigator.Buttons.Refresh.Visible = True
            Navigator.Visible = True
            DataController.DataSource = dsGuias
            DataController.Options = [dcoCaseInsensitive, dcoAssignGroupingValues, dcoAssignMasterDetailKeys, dcoSaveExpanding]
            OptionsBehavior.GoToNextCellOnEnter = True
            OptionsBehavior.IncSearch = True
            OptionsCustomize.ColumnHiding = True
            OptionsData.Deleting = True
            OptionsData.DeletingConfirmation = True
            OptionsData.Editing = True
            OptionsData.Inserting = False
            OptionsView.GroupByBox = False
            OptionsView.Indicator = True
            Styles.Header = cxsHeader
            object tvGuiasCODIGO: TcxGridDBColumn
              Caption = 'C'#243'digo (UserName)'
              DataBinding.FieldName = 'CODIGO_INFGUI'
              Options.Sorting = False
              Width = 180
            end
            object tvGuiasTIPO: TcxGridDBColumn
              Caption = 'Tipo'
              DataBinding.FieldName = 'TIPO_INFGUI'
              PropertiesClassName = 'TcxComboBoxProperties'
              Properties.DropDownListStyle = lsFixedList
              Properties.Items.Strings = (
                'TABLA'
                'SQL')
              Width = 80
            end
            object tvGuiasTABLA: TcxGridDBColumn
              Caption = 'Tabla'
              DataBinding.FieldName = 'TABLA_INFGUI'
              Width = 160
            end
            object tvGuiasSQL: TcxGridDBColumn
              Caption = 'SQL libre'
              DataBinding.FieldName = 'SQL_INFGUI'
              Width = 180
            end
            object tvGuiasMASTER_FIELDS: TcxGridDBColumn
              Caption = 'Master fields'
              DataBinding.FieldName = 'MASTER_FIELDS_INFGUI'
              Width = 180
            end
            object tvGuiasDETAIL_FIELDS: TcxGridDBColumn
              Caption = 'Detail fields'
              DataBinding.FieldName = 'DETAIL_FIELDS_INFGUI'
              Width = 180
            end
            object tvGuiasORDEN: TcxGridDBColumn
              Caption = 'Orden'
              DataBinding.FieldName = 'ORDEN_INFGUI'
              Width = 60
            end
            object tvGuiasACTIVO: TcxGridDBColumn
              Caption = 'Activo'
              DataBinding.FieldName = 'ESACTIVO_INFGUI'
              PropertiesClassName = 'TcxComboBoxProperties'
              Properties.DropDownListStyle = lsFixedList
              Properties.Items.Strings = (
                'S'
                'N')
              Width = 60
            end
          end
          object lvGuias: TcxGridLevel
            GridView = tvGuias
          end
        end
      end
    end
  end
  inherited Localizer1: TcxLocalizer
    Left = 944
    Top = 504
  end
  object dsGuias: TDataSource
    Left = 192
    Top = 504
  end
  object ActionList1: TActionList
    Left = 272
    Top = 504
    object actCancelar: TAction
      Caption = 'Cancelar'
      ShortCut = 27
      OnExecute = actCancelarExecute
    end
  end
  object cxStyleRepo: TcxStyleRepository
    Left = 352
    Top = 504
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
