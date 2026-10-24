object FormNormalizer: TFormNormalizer
  Left = 0
  Top = 0
  Caption = 'ViraCash Normalizer'
  ClientHeight = 704
  ClientWidth = 1176
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = 'Source Sans 3'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object PanelTop: TPanel
    Left = 0
    Top = 0
    Width = 1176
    Height = 49
    Align = alTop
    BevelOuter = bvNone
    Padding.Left = 8
    Padding.Top = 8
    Padding.Right = 8
    Padding.Bottom = 8
    TabOrder = 0
    ExplicitWidth = 1174
    object lblSourceFile: TLabel
      Left = 600
      Top = 18
      Width = 95
      Height = 15
      Caption = 'Origen: (ninguno)'
    end
    object btnLoadSQL: TButton
      Left = 8
      Top = 12
      Width = 140
      Height = 25
      Caption = 'Cargar Copia Seg. SQL...'
      TabOrder = 0
      OnClick = btnLoadSQLClick
    end
    object btnLoadCSV: TButton
      Left = 154
      Top = 12
      Width = 88
      Height = 25
      Caption = 'Cargar CSV...'
      TabOrder = 1
      OnClick = btnLoadCSVClick
    end
    object btnGenerate: TButton
      Left = 248
      Top = 12
      Width = 87
      Height = 25
      Caption = 'Generar plan'
      TabOrder = 2
      OnClick = btnGenerateClick
    end
    object btnExport: TButton
      Left = 341
      Top = 12
      Width = 113
      Height = 25
      Caption = 'Exportar Plan...'
      TabOrder = 3
      OnClick = btnExportClick
    end
    object btnEditConfig: TButton
      Left = 460
      Top = 12
      Width = 130
      Height = 25
      Caption = 'Editar configuraci'#243'n'#8230
      TabOrder = 4
      OnClick = btnEditConfigClick
    end
  end
  object PageControl: TPageControl
    Left = 0
    Top = 49
    Width = 1176
    Height = 636
    ActivePage = tabCodeSearch
    Align = alClient
    TabOrder = 1
    ExplicitWidth = 1174
    ExplicitHeight = 628
    object tabPlan: TTabSheet
      Caption = 'Plan'
      object GridPlan: TStringGrid
        Left = 0
        Top = 0
        Width = 1168
        Height = 606
        Align = alClient
        DefaultRowHeight = 18
        FixedCols = 0
        RowCount = 2
        TabOrder = 0
      end
    end
    object tabColumnSQL: TTabSheet
      Caption = 'SQL columnas'
      ImageIndex = 1
      object MemoColumnSQL: TMemo
        Left = 0
        Top = 0
        Width = 1168
        Height = 606
        Align = alClient
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Consolas'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssBoth
        TabOrder = 0
        WordWrap = False
      end
    end
    object tabIndexSQL: TTabSheet
      Caption = 'SQL '#237'ndices'
      ImageIndex = 2
      object MemoIndexSQL: TMemo
        Left = 0
        Top = 0
        Width = 1168
        Height = 606
        Align = alClient
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Consolas'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssBoth
        TabOrder = 0
        WordWrap = False
      end
    end
    object tabSQLSearch: TTabSheet
      Caption = 'B'#250'squeda SQL'
      ImageIndex = 3
      object PanelSQLSearchTop: TPanel
        Left = 0
        Top = 0
        Width = 1168
        Height = 49
        Align = alTop
        BevelOuter = bvNone
        Padding.Left = 8
        Padding.Top = 8
        Padding.Right = 8
        Padding.Bottom = 8
        TabOrder = 0
        object lblSQLSearchInfo: TLabel
          Left = 320
          Top = 19
          Width = 110
          Height = 15
          Caption = 'Sin escanear todav'#237'a.'
        end
        object btnScanSQL: TButton
          Left = 8
          Top = 12
          Width = 145
          Height = 25
          Caption = 'Escanear SQL'
          TabOrder = 0
          OnClick = btnScanSQLClick
        end
        object btnGenerateReplaceSQL: TButton
          Left = 159
          Top = 12
          Width = 155
          Height = 25
          Caption = 'Generar SQL de reemplazo'
          TabOrder = 1
          OnClick = btnGenerateReplaceSQLClick
        end
      end
      object GridSQLMatches: TStringGrid
        Left = 0
        Top = 49
        Width = 1168
        Height = 557
        Align = alClient
        DefaultRowHeight = 18
        FixedCols = 0
        RowCount = 2
        TabOrder = 1
      end
    end
    object tabFullSQL: TTabSheet
      Caption = 'SQL completo modificado'
      ImageIndex = 4
      object MemoFullSQL: TMemo
        Left = 0
        Top = 0
        Width = 1168
        Height = 606
        Align = alClient
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Consolas'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssBoth
        TabOrder = 0
        WordWrap = False
      end
    end
    object tabCodeSearch: TTabSheet
      Caption = 'B'#250'squeda c'#243'digo'
      ImageIndex = 5
      object PanelCodeTop: TPanel
        Left = 0
        Top = 0
        Width = 1168
        Height = 193
        Align = alTop
        BevelOuter = bvNone
        Padding.Left = 8
        Padding.Top = 8
        Padding.Right = 8
        Padding.Bottom = 8
        TabOrder = 0
        object lblFolders: TLabel
          Left = 8
          Top = 12
          Width = 169
          Height = 15
          Caption = 'Carpetas a escanear (.pas/.dfm):'
        end
        object lblCodeInfo: TLabel
          Left = 320
          Top = 116
          Width = 110
          Height = 15
          Caption = 'Sin escanear todav'#237'a.'
        end
        object ListBoxFolders: TListBox
          Left = 8
          Top = 30
          Width = 480
          Height = 80
          ItemHeight = 15
          TabOrder = 0
        end
        object btnAddFolder: TButton
          Left = 494
          Top = 30
          Width = 130
          Height = 25
          Caption = 'A'#241'adir carpeta'#8230
          TabOrder = 1
          OnClick = btnAddFolderClick
        end
        object btnRemoveFolder: TButton
          Left = 494
          Top = 60
          Width = 130
          Height = 25
          Caption = 'Quitar seleccionada'
          TabOrder = 2
          OnClick = btnRemoveFolderClick
        end
        object btnScanCode: TButton
          Left = 688
          Top = 30
          Width = 145
          Height = 25
          Caption = 'Escanear c'#243'digo'
          TabOrder = 3
          OnClick = btnScanCodeClick
        end
        object btnApplyCodeReplacements: TButton
          Left = 688
          Top = 63
          Width = 172
          Height = 25
          Caption = 'Aplicar reemplazos (con .bak)'
          TabOrder = 4
          OnClick = btnApplyCodeReplacementsClick
        end
        object btnGenerateApplyScript: TButton
          Left = 688
          Top = 97
          Width = 165
          Height = 25
          Caption = 'Generar script aplicaci'#243'n'#8230
          TabOrder = 5
          OnClick = btnGenerateApplyScriptClick
        end
        object btnFixOldParams: TButton
          Left = 688
          Top = 128
          Width = 172
          Height = 25
          Caption = 'Sanear par'#225'metros Old_*'
          TabOrder = 6
          OnClick = btnFixOldParamsClick
        end
        object btnPatchFR3Dump: TButton
          Left = 688
          Top = 159
          Width = 172
          Height = 25
          Caption = 'Parchear reports en dump SQL'
          TabOrder = 7
          OnClick = btnPatchFR3DumpClick
        end
      end
      object GridCodeMatches: TStringGrid
        Left = 0
        Top = 193
        Width = 1168
        Height = 413
        Align = alClient
        DefaultRowHeight = 18
        FixedCols = 0
        RowCount = 2
        TabOrder = 1
        ExplicitTop = 145
        ExplicitWidth = 1166
        ExplicitHeight = 453
      end
    end
    object tabAudit: TTabSheet
      Caption = 'Auditor'#237'a'
      ImageIndex = 6
      object PanelAuditTop: TPanel
        Left = 0
        Top = 0
        Width = 1168
        Height = 49
        Align = alTop
        BevelOuter = bvNone
        Padding.Left = 8
        Padding.Top = 8
        Padding.Right = 8
        Padding.Bottom = 8
        TabOrder = 0
        object lblAuditInfo: TLabel
          Left = 320
          Top = 19
          Width = 101
          Height = 15
          Caption = 'Sin auditar todav'#237'a.'
        end
        object btnAuditCode: TButton
          Left = 8
          Top = 12
          Width = 145
          Height = 25
          Caption = 'Auditar c'#243'digo'
          TabOrder = 0
          OnClick = btnAuditCodeClick
        end
        object btnExportAudit: TButton
          Left = 159
          Top = 12
          Width = 145
          Height = 25
          Caption = 'Exportar a TXT'#8230
          TabOrder = 1
          OnClick = btnExportAuditClick
        end
      end
      object GridAuditMatches: TStringGrid
        Left = 0
        Top = 49
        Width = 1168
        Height = 557
        Align = alClient
        DefaultRowHeight = 18
        FixedCols = 0
        RowCount = 2
        TabOrder = 1
      end
    end
    object tabReport: TTabSheet
      Caption = 'Informe'
      ImageIndex = 7
      object MemoReport: TMemo
        Left = 0
        Top = 0
        Width = 1168
        Height = 606
        Align = alClient
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Consolas'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
      end
    end
    object tabLog: TTabSheet
      Caption = 'Log'
      ImageIndex = 8
      object MemoLog: TMemo
        Left = 0
        Top = 0
        Width = 1168
        Height = 606
        Align = alClient
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Consolas'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
      end
    end
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 685
    Width = 1176
    Height = 19
    Panels = <>
    SimplePanel = True
    SimpleText = 'Listo.'
    ExplicitTop = 677
    ExplicitWidth = 1174
  end
  object SaveDialogAudit: TSaveDialog
    Left = 600
    Top = 12
  end
  object OpenDialog: TOpenDialog
    Left = 800
    Top = 8
  end
end
