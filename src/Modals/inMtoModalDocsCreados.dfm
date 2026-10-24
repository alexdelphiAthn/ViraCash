inherited frmModalDocsCreados: TfrmModalDocsCreados
  Caption = 'Documentos creados'
  ClientHeight = 420
  ClientWidth = 720
  StyleElements = [seFont, seClient, seBorder]
  OnCreate = FormCreate
  ExplicitWidth = 736
  ExplicitHeight = 459
  TextHeight = 19
  inherited pnlButton: TPanel
    Top = 361
    Width = 720
    StyleElements = [seFont, seClient, seBorder]
    ExplicitTop = 361
    ExplicitWidth = 720
    inherited btnCancelar: TcxButton
      Left = 306
      Top = 10
      Caption = '&Cerrar (ESC)'
      ExplicitLeft = 306
      ExplicitTop = 10
    end
    inherited btnAceptar: TcxButton
      Left = 510
      Top = 10
      Caption = '&Ir a documento (F12)'
      ExplicitLeft = 510
      ExplicitTop = 10
    end
  end
  inherited pnlBody: TPanel
    Width = 720
    Height = 361
    StyleElements = [seFont, seClient, seBorder]
    ExplicitWidth = 720
    ExplicitHeight = 361
    object pnlCab: TPanel
      Left = 1
      Top = 1
      Width = 718
      Height = 50
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
      object lblTitulo: TcxLabel
        Left = 16
        Top = 12
        Caption = 'Documentos creados al materializar la sesi'#243'n'
        TabOrder = 0
        Transparent = True
      end
    end
    object cxgrdDocs: TcxGrid
      Left = 1
      Top = 51
      Width = 718
      Height = 309
      Align = alClient
      TabOrder = 1
      object tvDocs: TcxGridDBTableView
        OnDblClick = tvDocsDblClick
        DataController.DataSource = dsDocs
        OptionsBehavior.FocusCellOnTab = True
        OptionsBehavior.IncSearch = False
        OptionsCustomize.ColumnHiding = True
        OptionsData.Deleting = False
        OptionsData.DeletingConfirmation = False
        OptionsData.Editing = False
        OptionsData.Inserting = False
        OptionsView.GroupByBox = False
      end
      object cxlvlDocs: TcxGridLevel
        GridView = tvDocs
      end
    end
  end
  object cdsDocs: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 16
    Top = 60
  end
  object dsDocs: TDataSource
    DataSet = cdsDocs
    Left = 56
    Top = 60
  end
end
