inherited frmModalSelFamilia: TfrmModalSelFamilia
  Caption = 'Seleccionar familia'
  ClientHeight = 520
  ClientWidth = 560
  StyleElements = [seFont, seClient, seBorder]
  OnClose = FormClose
  OnCreate = FormCreate
  OnShow = FormShow
  ExplicitWidth = 560
  ExplicitHeight = 520
  TextHeight = 19
  object pnlBody: TPanel [0]
    Left = 0
    Top = 0
    Width = 560
    Height = 460
    Align = alClient
    TabOrder = 0
    object pnlFiltro: TPanel
      Left = 1
      Top = 1
      Width = 558
      Height = 40
      Align = alTop
      TabOrder = 0
      object lblFiltro: TcxLabel
        Left = 8
        Top = 12
        Caption = 'Filtro'
        Transparent = True
      end
      object txtFiltro: TcxTextEdit
        Left = 60
        Top = 8
        Properties.OnChange = txtFiltroPropertiesChange
        TabOrder = 0
        Width = 490
      end
    end
    object tlFamilias: TcxDBTreeList
      Left = 1
      Top = 41
      Width = 558
      Height = 418
      Align = alClient
      Bands = <
        item
        end>
      DataController.DataSource = dsFamilias
      DataController.KeyField = 'CODIGO_FAM_FAM'
      DataController.ParentField = 'CODIGO_PADRE_FAM'
      OptionsBehavior.CopyCaptionsToClipboard = False
      OptionsData.Editing = False
      OptionsData.Deleting = False
      OptionsData.Inserting = False
      OptionsSelection.CellSelect = False
      OptionsSelection.MultiSelect = False
      OptionsView.Headers = True
      RootValue = ''
      ScrollbarAnnotations.CustomAnnotations = <>
      TabOrder = 1
      OnDblClick = tlFamiliasDblClick
      object tlcCodigo: TcxDBTreeListColumn
        Caption.Text = 'C'#243'digo'
        DataBinding.FieldName = 'CODIGO_FAM_FAM'
        Width = 140
        Position.ColIndex = 0
        Position.RowIndex = 0
        Position.BandIndex = 0
      end
      object tlcNombre: TcxDBTreeListColumn
        Caption.Text = 'Nombre'
        DataBinding.FieldName = 'NOMBRE_FAM_FAM'
        Width = 360
        Position.ColIndex = 1
        Position.RowIndex = 0
        Position.BandIndex = 0
      end
    end
  end
  object pnlButton: TPanel [1]
    Left = 0
    Top = 460
    Width = 560
    Height = 60
    Align = alBottom
    TabOrder = 1
    object btnCancelar: TcxButton
      Left = 40
      Top = 12
      Width = 180
      Height = 36
      Cancel = True
      Caption = '&Cancelar (ESC)'
      TabOrder = 0
      OnClick = btnCancelarClick
    end
    object btnAceptar: TcxButton
      Left = 340
      Top = 12
      Width = 180
      Height = 36
      Caption = '&Aceptar (F12 / Enter)'
      Default = True
      TabOrder = 1
      OnClick = btnAceptarClick
    end
  end
  object dsFamilias: TDataSource
    Left = 480
    Top = 72
  end
  object ActionList1: TActionList
    Left = 480
    Top = 128
    object actAceptar: TAction
      Caption = 'Aceptar'
      ShortCut = 123
      OnExecute = actAceptarExecute
    end
    object actCancelar: TAction
      Caption = 'Cancelar'
      ShortCut = 27
      OnExecute = actCancelarExecute
    end
  end
end
