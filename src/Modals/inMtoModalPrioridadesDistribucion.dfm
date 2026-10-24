inherited frmModalPrioridadesDistribucion: TfrmModalPrioridadesDistribucion
  Caption = 'Prioridades de distribuci'#243'n'
  ClientHeight = 660
  ClientWidth = 700
  StyleElements = [seFont, seClient, seBorder]
  ExplicitWidth = 716
  ExplicitHeight = 699
  TextHeight = 19
  inherited pnlButton: TPanel
    Top = 601
    Width = 700
    StyleElements = [seFont, seClient, seBorder]
    ExplicitTop = 601
    ExplicitWidth = 700
    inherited btnCancelar: TcxButton
      Left = 294
      ExplicitLeft = 294
    end
    inherited btnAceptar: TcxButton
      Left = 498
      ExplicitLeft = 498
    end
  end
  inherited pnlBody: TPanel
    Width = 700
    Height = 601
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 0
    ExplicitTop = 0
    ExplicitWidth = 700
    ExplicitHeight = 601
    object lblAyuda: TcxLabel
      Left = 1
      Top = 1
      Align = alTop
      AutoSize = False
      Caption =
        'El 1 se repone primero; dos tiendas pueden compartir n'#250'mero. Un' +
        ' almac'#233'n sin n'#250'mero no recibe traspasos desde la distribuci'#243'n.'
      Properties.WordWrap = True
      TabOrder = 1
      Transparent = True
      Height = 108
      Width = 698
    end
    object cxgrdPrioridades: TcxGrid
      Left = 1
      Top = 109
      Width = 698
      Height = 491
      Align = alClient
      TabOrder = 0
      OnEnter = cxgrdPrioridadesEnter
      OnExit = cxgrdPrioridadesExit
      object tvPrioridades: TcxGridTableView
        Navigator.Buttons.CustomButtons = <>
        ScrollbarAnnotations.CustomAnnotations = <>
        DataController.Summary.DefaultGroupSummaryItems = <>
        DataController.Summary.FooterSummaryItems = <>
        DataController.Summary.SummaryGroups = <>
        OptionsBehavior.FocusCellOnTab = True
        OptionsBehavior.GoToNextCellOnEnter = True
        OptionsBehavior.ImmediateEditor = True
        OptionsBehavior.IncSearch = False
        OptionsCustomize.ColumnFiltering = False
        OptionsCustomize.ColumnMoving = False
        OptionsData.Deleting = False
        OptionsData.DeletingConfirmation = False
        OptionsData.Inserting = False
        OptionsView.GroupByBox = False
      end
      object glPrioridades: TcxGridLevel
        GridView = tvPrioridades
      end
    end
  end
end
