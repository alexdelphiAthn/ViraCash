inherited frmMtoModalCajDef: TfrmMtoModalCajDef
  BorderIcons = []
  Caption = 'Seleccionar Caja'
  ClientHeight = 433
  ClientWidth = 758
  StyleElements = [seFont, seClient, seBorder]
  OnClose = FormClose
  OnShow = FormShow
  ExplicitWidth = 774
  ExplicitHeight = 463
  TextHeight = 19
  object pnl1: TPanel [0]
    Left = 0
    Top = 383
    Width = 758
    Height = 50
    Align = alBottom
    TabOrder = 0
    ExplicitTop = 375
    ExplicitWidth = 756
    object btnCancelar1: TcxButton
      Left = 130
      Top = 9
      Width = 177
      Height = 32
      Caption = '&Cancelar'
      TabOrder = 0
      OnClick = btnCancelar1Click
    end
    object btnAceptar: TcxButton
      Left = 368
      Top = 9
      Width = 177
      Height = 32
      Caption = '&Aceptar'
      TabOrder = 1
      OnClick = btnAceptarClick
    end
  end
  object cxgrdAlmacenCajas: TcxGrid [1]
    Left = 0
    Top = 0
    Width = 758
    Height = 383
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Align = alClient
    TabOrder = 1
    ExplicitWidth = 756
    ExplicitHeight = 375
    object tvAlmacenesCajas: TcxGridDBTableView
      Navigator.Buttons.ConfirmDelete = True
      Navigator.Buttons.First.Hint = 'Va al primer Registro'
      Navigator.Buttons.First.Visible = False
      Navigator.Buttons.PriorPage.Hint = 'Va a la p'#225'gina anterior'
      Navigator.Buttons.PriorPage.Visible = False
      Navigator.Buttons.Prior.Hint = 'Va al Registro Anterior'
      Navigator.Buttons.Prior.Visible = False
      Navigator.Buttons.Next.Hint = 'Va al siguiente Registro'
      Navigator.Buttons.Next.Visible = False
      Navigator.Buttons.NextPage.Hint = 'Va a la p'#225'gina siguiente'
      Navigator.Buttons.NextPage.Visible = False
      Navigator.Buttons.Last.Hint = 'Va al '#250'ltimo registro'
      Navigator.Buttons.Last.Visible = False
      Navigator.Buttons.Insert.Hint = 'Inserta un nuevo Registro'
      Navigator.Buttons.Insert.Visible = True
      Navigator.Buttons.Delete.Hint = 'Borra el registro Activo'
      Navigator.Buttons.Delete.Visible = True
      Navigator.Buttons.Edit.Enabled = False
      Navigator.Buttons.Edit.Hint = 'Edita registro Actual'
      Navigator.Buttons.Edit.Visible = False
      Navigator.Buttons.Post.Hint = 'Guarda Datos introducidos'
      Navigator.Buttons.Post.Visible = True
      Navigator.Buttons.Cancel.Hint = 'Cancela la edici'#243'n actual'
      Navigator.Buttons.Cancel.Visible = True
      Navigator.Buttons.Refresh.Hint = 'Refresca Datos Activos'
      Navigator.Buttons.SaveBookmark.Enabled = False
      Navigator.Buttons.SaveBookmark.Hint = 'Marca Registro Actual'
      Navigator.Buttons.SaveBookmark.Visible = False
      Navigator.Buttons.GotoBookmark.Enabled = False
      Navigator.Buttons.GotoBookmark.Hint = 'Va al registro Marcado'
      Navigator.Buttons.GotoBookmark.Visible = False
      Navigator.Buttons.Filter.Hint = 'Filtro personalizado'
      Navigator.Visible = True
      DataController.DataSource = DataSource1
      DataController.Options = [dcoCaseInsensitive, dcoAssignGroupingValues, dcoAssignMasterDetailKeys, dcoSaveExpanding]
      OptionsBehavior.AlwaysShowEditor = True
      OptionsBehavior.GoToNextCellOnEnter = True
      OptionsBehavior.IncSearch = True
      OptionsCustomize.ColumnHiding = True
      OptionsData.CancelOnExit = False
      OptionsData.Deleting = False
      OptionsData.DeletingConfirmation = False
      OptionsData.Editing = False
      OptionsData.Inserting = False
      OptionsView.GroupByBox = False
      OptionsView.Indicator = True
      object tvAlmacenesCajasEmpresa: TcxGridDBColumn
        DataBinding.FieldName = 'Empresa'
        Width = 81
      end
      object tvAlmacenesCajasNombreEmpresa: TcxGridDBColumn
        DataBinding.FieldName = 'NombreEmpresa'
        Width = 192
      end
      object tvAlmacenesCajasAlmacn: TcxGridDBColumn
        DataBinding.FieldName = 'Almacen'
        Width = 85
      end
      object tvAlmacenesCajasNombreAlmacn: TcxGridDBColumn
        DataBinding.FieldName = 'NombreAlmac'#233'n'
        Width = 171
      end
      object tvAlmacenesCajasCaja: TcxGridDBColumn
        DataBinding.FieldName = 'Caja'
        Width = 52
      end
      object tvAlmacenesCajasNombreCaja: TcxGridDBColumn
        DataBinding.FieldName = 'NombreCaja'
        Width = 367
      end
    end
    object lvAlmacenCajas: TcxGridLevel
      GridView = tvAlmacenesCajas
    end
  end
  inherited Localizer1: TcxLocalizer
    Left = 232
    Top = 440
  end
  object DataSource1: TDataSource
    Left = 88
    Top = 32
  end
  object ActionList1: TActionList
    Left = 368
    Top = 96
    object Action1: TAction
      Caption = 'Action1'
      SecondaryShortCuts.Strings = (
        'F12')
      ShortCut = 116
      OnExecute = Action1Execute
    end
    object Action2: TAction
      Caption = 'Action2'
      ShortCut = 27
      OnExecute = Action2Execute
    end
  end
end
