object frmTraducciones: TfrmTraducciones
  Left = 0
  Top = 0
  Caption = 'Editor de traducciones de ViraCash'
  ClientHeight = 720
  ClientWidth = 1184
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 15
  object pnlConexion: TPanel
    Left = 0
    Top = 0
    Width = 1184
    Height = 105
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblIni: TLabel
      Left = 12
      Top = 12
      Width = 92
      Height = 15
      Caption = 'INI de ViraCash'
    end
    object lblIdioma: TLabel
      Left = 12
      Top = 62
      Width = 86
      Height = 15
      Caption = 'Idioma destino'
    end
    object edtIni: TEdit
      Left = 12
      Top = 30
      Width = 650
      Height = 23
      ReadOnly = True
      TabOrder = 0
    end
    object btnBuscarIni: TButton
      Left = 674
      Top = 28
      Width = 108
      Height = 27
      Caption = 'Examinar...'
      TabOrder = 1
      OnClick = btnBuscarIniClick
    end
    object btnConectar: TButton
      Left = 794
      Top = 28
      Width = 108
      Height = 27
      Caption = 'Conectar'
      TabOrder = 2
      OnClick = btnConectarClick
    end
    object cbbIdioma: TComboBox
      Left = 12
      Top = 80
      Width = 146
      Height = 23
      TabOrder = 3
      Text = 'en-GB'
      Items.Strings = (
        'en-GB'
        'fr-FR'
        'de-DE'
        'it-IT'
        'pt-PT')
    end
    object chkSoloPendientes: TCheckBox
      Left = 174
      Top = 82
      Width = 142
      Height = 19
      Caption = 'Sólo pendientes'
      Checked = True
      State = cbChecked
      TabOrder = 4
    end
    object btnCargar: TButton
      Left = 330
      Top = 77
      Width = 108
      Height = 27
      Caption = 'Cargar'
      TabOrder = 5
      OnClick = btnCargarClick
    end
    object btnGuardar: TButton
      Left = 450
      Top = 77
      Width = 108
      Height = 27
      Caption = 'Guardar'
      TabOrder = 6
      OnClick = btnGuardarClick
    end
    object btnImportarCatalogo: TButton
      Left = 570
      Top = 77
      Width = 164
      Height = 27
      Caption = 'Sincronizar español'
      TabOrder = 7
      OnClick = btnImportarCatalogoClick
    end
  end
  object dbgrdClaves: TDBGrid
    Left = 0
    Top = 105
    Width = 500
    Height = 593
    Align = alLeft
    DataSource = dsTraducciones
    Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines,
      dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit, dgTitleClick,
      dgTitleHotTrack]
    ReadOnly = True
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -12
    TitleFont.Name = 'Segoe UI'
    TitleFont.Style = []
    Columns = <
      item
        Expanded = False
        FieldName = 'CLAVE_TRAD'
        Title.Caption = 'Clave'
        Width = 280
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CONTEXTO_TRAD'
        Title.Caption = 'Contexto'
        Width = 180
        Visible = True
      end>
  end
  object splVertical: TSplitter
    Left = 500
    Top = 105
    Height = 593
  end
  object pnlEditor: TPanel
    Left = 503
    Top = 105
    Width = 681
    Height = 593
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    object lblOrigen: TLabel
      Left = 0
      Top = 0
      Width = 681
      Height = 24
      Align = alTop
      AutoSize = False
      Caption = ' Texto español'
      Layout = tlCenter
    end
    object dbmOrigen: TDBMemo
      Left = 0
      Top = 24
      Width = 681
      Height = 260
      Align = alTop
      DataField = 'TEXTO_ORIGEN'
      DataSource = dsTraducciones
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 0
    end
    object splHorizontal: TSplitter
      Left = 0
      Top = 284
      Width = 681
      Height = 5
      Cursor = crVSplit
      Align = alTop
    end
    object lblDestino: TLabel
      Left = 0
      Top = 289
      Width = 681
      Height = 24
      Align = alTop
      AutoSize = False
      Caption = ' Traducción'
      Layout = tlCenter
    end
    object dbmDestino: TDBMemo
      Left = 0
      Top = 313
      Width = 681
      Height = 280
      Align = alClient
      DataField = 'TEXTO_DESTINO'
      DataSource = dsTraducciones
      ScrollBars = ssVertical
      TabOrder = 1
    end
  end
  object stbEstado: TStatusBar
    Left = 0
    Top = 698
    Width = 1184
    Height = 22
    Panels = <>
    SimplePanel = True
  end
  object dsTraducciones: TDataSource
    DataSet = cdsTraducciones
    Left = 1048
    Top = 16
  end
  object cdsTraducciones: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 1104
    Top = 16
  end
  object dlgAbrirIni: TOpenDialog
    DefaultExt = 'ini'
    Filter = 'Ficheros INI (*.ini)|*.ini|Todos los ficheros (*.*)|*.*'
    Options = [ofHideReadOnly, ofFileMustExist, ofEnableSizing]
    Title = 'Seleccionar el INI de ViraCash'
    Left = 992
    Top = 16
  end
end
