inherited frmPrint: TfrmPrint
  Left = 506
  Top = 279
  HorzScrollBar.Visible = False
  BorderStyle = bsSizeable
  Caption = 'Imprimir'
  ClientHeight = 240
  ClientWidth = 341
  StyleElements = [seFont, seClient, seBorder]
  OnClose = FormClose
  ExplicitWidth = 357
  ExplicitHeight = 279
  TextHeight = 17
  object pnl1: TPanel [0]
    Left = 197
    Top = 0
    Width = 144
    Height = 240
    Align = alRight
    TabOrder = 0
    object btnPDF: TcxButton
      Left = 0
      Top = 48
      Width = 142
      Height = 25
      Caption = '&PDF'
      TabOrder = 2
      OnClick = btnPDFClick
    end
    object btnImprimir: TcxButton
      Left = 0
      Top = 120
      Width = 142
      Height = 25
      Caption = '&Imprimir'
      TabOrder = 4
      OnClick = btnImprimirClick
    end
    object btnVistaPreliminar: TcxButton
      Left = 0
      Top = 0
      Width = 142
      Height = 25
      Caption = '&Vista Preliminar'
      TabOrder = 0
      OnClick = btnVistaPreliminarClick
    end
    object btnSalir: TcxButton
      Left = 1
      Top = 214
      Width = 142
      Height = 25
      Align = alBottom
      Caption = '&Salir'
      TabOrder = 5
      OnClick = btnSalirClick
    end
    object btnEditar: TcxButton
      Left = 0
      Top = 72
      Width = 142
      Height = 25
      Caption = '&Editar'
      TabOrder = 3
      OnClick = btnEditarClick
    end
    object btnExcel: TcxButton
      Left = 0
      Top = 24
      Width = 142
      Height = 25
      Caption = 'E&xcel'
      TabOrder = 1
      OnClick = btnExcelClick
    end
  end
  object frxrprt1: TfrxReport
    Version = '2025.1.1'
    DotMatrixReport = False
    IniFile = '\Software\Fast Reports'
    PreviewOptions.Buttons = [pbPrint, pbLoad, pbSave, pbExport, pbZoom, pbFind, pbOutline, pbPageSetup, pbTools, pbEdit, pbNavigator, pbExportQuick]
    PreviewOptions.Zoom = 1.000000000000000000
    PrintOptions.Printer = 'Por defecto'
    PrintOptions.PrintOnSheet = 0
    ReportOptions.Author = 'ViraCash'
    ReportOptions.CreateDate = 42481.634675740700000000
    ReportOptions.LastChange = 43706.469558402810000000
    ScriptLanguage = 'PascalScript'
    ScriptText.Strings = (
      'begin'
      'end.          ')
    Left = 80
    Top = 64
    Datasets = <>
    Variables = <>
    Style = <>
    object Data: TfrxDataPage
      Height = 1000.000000000000000000
      Width = 1000.000000000000000000
    end
    object Page1: TfrxReportPage
      PaperWidth = 210.000000000000000000
      PaperHeight = 297.000000000000000000
      PaperSize = 9
      LeftMargin = 5.000000000000000000
      RightMargin = 5.000000000000000000
      TopMargin = 20.000000000000000000
      BottomMargin = 20.000000000000000000
      Frame.Typ = []
      MirrorMode = []
    end
  end
  object frxpdfxprtPedWeb: TfrxPDFExport
    UseFileCache = True
    ShowProgress = True
    OverwritePrompt = False
    DataOnly = False
    Compressed = False
    EmbeddedFonts = True
    EmbedFontsIfProtected = False
    InteractiveFormsFontSubset = 'A-Z,a-z,0-9,#43-#47 '
    OpenAfterExport = False
    PrintOptimized = True
    Outline = False
    Background = False
    HTMLTags = True
    Quality = 95
    Transparency = False
    Author = 'Alejandro Laorden Hidalgo'
    Subject = 'ViraCash'
    Creator = 'ViraCash Software de Gesti'#243'n Retail'
    Producer = 'ViraCash Printing System'
    ProtectionFlags = [ePrint, eModify, eCopy, eAnnot]
    HideToolbar = False
    HideMenubar = False
    HideWindowUI = False
    FitWindow = False
    CenterWindow = False
    PrintScaling = False
    PdfA = False
    PDFStandard = psNone
    PDFVersion = pv14
    Left = 88
    Top = 120
  end
  object frxlsxprtExcel: TfrxXLSXExport
    UseFileCache = True
    ShowProgress = True
    OverwritePrompt = False
    CreationTime = 44864.742436493060000000
    DataOnly = False
    ChunkSize = 0
    OpenAfterExport = False
    PictureType = gpPNG
    Left = 176
    Top = 120
  end
  object frxdsgnr1: TfrxDesigner
    CloseQuery = False
    DefaultScriptLanguage = 'PascalScript'
    DefaultFont.Charset = DEFAULT_CHARSET
    DefaultFont.Color = clWindowText
    DefaultFont.Height = -14
    DefaultFont.Name = 'Arial'
    DefaultFont.Style = []
    DefaultLeftMargin = 10.000000000000000000
    DefaultRightMargin = 10.000000000000000000
    DefaultTopMargin = 10.000000000000000000
    DefaultBottomMargin = 10.000000000000000000
    DefaultPaperSize = 9
    DefaultOrientation = poPortrait
    GradientEnd = 11982554
    GradientStart = clWindow
    TemplatesExt = 'fr3'
    Restrictions = []
    RTLLanguage = False
    MemoParentFont = False
    OnSaveReport = frxdsgnr1SaveReport
    Left = 16
    Top = 120
  end
  object frxReportOrigen: TfrxReport
    Version = '2025.1.1'
    DotMatrixReport = False
    IniFile = '\Software\Fast Reports'
    PreviewOptions.Buttons = [pbPrint, pbLoad, pbSave, pbExport, pbZoom, pbFind, pbOutline, pbPageSetup, pbTools, pbEdit, pbNavigator, pbExportQuick]
    PreviewOptions.Zoom = 1.000000000000000000
    PrintOptions.Printer = 'Por defecto'
    PrintOptions.PrintOnSheet = 0
    ReportOptions.Author = 'ViraCash'
    ReportOptions.CreateDate = 42481.634675740700000000
    ReportOptions.LastChange = 46132.560265590280000000
    ScriptLanguage = 'PascalScript'
    ScriptText.Strings = (
      'begin'
      'end.          ')
    Left = 152
    Top = 16
    Datasets = <>
    Variables = <>
    Style = <>
    object Data: TfrxDataPage
      Height = 1000.000000000000000000
      Width = 1000.000000000000000000
    end
    object Page1: TfrxReportPage
      PaperWidth = 210.000000000000000000
      PaperHeight = 297.000000000000000000
      PaperSize = 9
      LeftMargin = 5.000000000000000000
      RightMargin = 5.000000000000000000
      TopMargin = 20.000000000000000000
      BottomMargin = 20.000000000000000000
      Frame.Typ = []
      MirrorMode = []
    end
  end
  object ActionList1: TActionList
    Left = 160
    Top = 184
    object actSalir: TAction
      Caption = 'Salir'
      ShortCut = 27
      OnExecute = actSalirExecute
    end
  end
  object frLocalizationController1: TfrLocalizationController
    Left = 64
    Top = 184
  end
end
