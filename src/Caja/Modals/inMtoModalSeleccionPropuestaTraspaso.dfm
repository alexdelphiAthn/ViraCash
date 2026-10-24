inherited frmModalSeleccionPropuestaTraspaso: TfrmModalSeleccionPropuestaTraspaso
  Caption = 'Confirmar propuesta'
  ClientHeight = 700
  ClientWidth = 1100
  StyleElements = [seFont, seClient, seBorder]
  ExplicitWidth = 1116
  ExplicitHeight = 739
  TextHeight = 19
  inherited pnlButton: TPanel
    Top = 641
    Width = 1100
    StyleElements = [seFont, seClient, seBorder]
    ExplicitTop = 641
    ExplicitWidth = 1100
    inherited btnCancelar: TcxButton
      Left = 20
      Width = 200
      Caption = 'Salir (ESC)'
      ExplicitLeft = 20
      ExplicitWidth = 200
    end
    inherited btnAceptar: TcxButton
      Left = 790
      Width = 290
      Caption = 'Cargar en el traspaso'
      ExplicitLeft = 790
      ExplicitWidth = 290
    end
    object btnNoAceptar: TcxButton
      Left = 560
      Top = 9
      Width = 220
      Height = 40
      Caption = 'No aceptar'
      TabOrder = 2
      OnClick = btnNoAceptarClick
    end
  end
  inherited pnlBody: TPanel
    Width = 1100
    Height = 641
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 0
    ExplicitTop = 0
    ExplicitWidth = 1100
    ExplicitHeight = 641
    object cxgrdPropuestas: TcxGrid
      Left = 1
      Top = 1
      Width = 1098
      Height = 270
      Align = alTop
      TabOrder = 0
      object tvPropuestas: TcxGridTableView
        Navigator.Buttons.CustomButtons = <>
        ScrollbarAnnotations.CustomAnnotations = <>
        DataController.Summary.DefaultGroupSummaryItems = <>
        DataController.Summary.FooterSummaryItems = <>
        DataController.Summary.SummaryGroups = <>
        OptionsBehavior.IncSearch = True
        OptionsCustomize.ColumnFiltering = False
        OptionsData.Deleting = False
        OptionsData.DeletingConfirmation = False
        OptionsData.Editing = False
        OptionsData.Inserting = False
        OptionsSelection.CellSelect = False
        OptionsView.GroupByBox = False
      end
      object glPropuestas: TcxGridLevel
        GridView = tvPropuestas
      end
    end
    object splLineas: TcxSplitter
      Left = 1
      Top = 271
      Width = 1098
      Height = 8
      AlignSplitter = salTop
      Control = cxgrdPropuestas
    end
    object cxgrdLineas: TcxGrid
      Left = 1
      Top = 279
      Width = 1098
      Height = 361
      Align = alClient
      TabOrder = 2
      object tvLineas: TcxGridTableView
        Navigator.Buttons.CustomButtons = <>
        ScrollbarAnnotations.CustomAnnotations = <>
        DataController.Summary.DefaultGroupSummaryItems = <>
        DataController.Summary.FooterSummaryItems = <>
        DataController.Summary.SummaryGroups = <>
        OptionsCustomize.ColumnFiltering = False
        OptionsData.Deleting = False
        OptionsData.DeletingConfirmation = False
        OptionsData.Editing = False
        OptionsData.Inserting = False
        OptionsSelection.CellSelect = False
        OptionsView.GroupByBox = False
      end
      object glLineas: TcxGridLevel
        GridView = tvLineas
      end
    end
  end
end
