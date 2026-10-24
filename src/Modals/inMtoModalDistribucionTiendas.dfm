inherited frmModalDistribucionTiendas: TfrmModalDistribucionTiendas
  Caption = 'Distribuci'#243'n entre almacenes'
  ClientHeight = 800
  ClientWidth = 1280
  StyleElements = [seFont, seClient, seBorder]
  ExplicitWidth = 1296
  ExplicitHeight = 839
  TextHeight = 19
  inherited pnlButton: TPanel
    Top = 741
    Width = 1280
    StyleElements = [seFont, seClient, seBorder]
    ExplicitTop = 741
    ExplicitWidth = 1280
    inherited btnCancelar: TcxButton
      Left = 20
      Width = 220
      Caption = '&Cerrar (ESC)'
      ExplicitLeft = 20
      ExplicitWidth = 220
    end
    inherited btnAceptar: TcxButton
      Left = 1020
      Width = 240
      Caption = 'Guardar y cerrar (F12)'
      ExplicitLeft = 1020
      ExplicitWidth = 240
    end
    object btnGuardar: TcxButton
      Left = 790
      Top = 9
      Width = 220
      Height = 40
      Caption = '&Guardar'
      Enabled = False
      TabOrder = 2
      OnClick = btnGuardarClick
    end
  end
  inherited pnlBody: TPanel
    Width = 1280
    Height = 741
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 0
    ExplicitTop = 0
    ExplicitWidth = 1280
    ExplicitHeight = 741
    object pnlOpciones: TPanel
      Left = 1
      Top = 1
      Width = 1278
      Height = 60
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
      object lblOrigen: TcxLabel
        Left = 16
        Top = 20
        Caption = 'Origen'
        TabOrder = 5
        Transparent = True
      end
      object cbbOrigen: TcxComboBox
        Left = 80
        Top = 16
        Properties.DropDownListStyle = lsFixedList
        Properties.OnChange = cbbOrigenPropertiesChange
        TabOrder = 0
        Width = 320
      end
      object lblMinimo: TcxLabel
        Left = 416
        Top = 20
        Caption = 'M'#237'nimo en origen'
        TabOrder = 6
        Transparent = True
      end
      object edtMinimoOrigen: TcxSpinEdit
        Left = 560
        Top = 16
        Properties.AssignedValues.MinValue = True
        Properties.ValueType = vtFloat
        Properties.OnChange = edtMinimoOrigenPropertiesChange
        TabOrder = 1
        Width = 90
      end
      object btnPrioridades: TcxButton
        Left = 668
        Top = 11
        Width = 180
        Height = 38
        Caption = '&Prioridades...'
        TabOrder = 2
        OnClick = btnPrioridadesClick
      end
      object btnRepartoAutomatico: TcxButton
        Left = 858
        Top = 11
        Width = 230
        Height = 38
        Caption = 'Reparto &autom'#225'tico...'
        TabOrder = 3
        OnClick = btnRepartoAutomaticoClick
      end
      object btnVaciar: TcxButton
        Left = 1098
        Top = 11
        Width = 170
        Height = 38
        Caption = '&Vaciar reparto'
        TabOrder = 4
        OnClick = btnVaciarClick
      end
    end
    object lblAviso: TcxLabel
      Left = 1
      Top = 712
      Align = alBottom
      AutoSize = False
      TabOrder = 2
      Transparent = True
      Height = 28
      Width = 1278
    end
    object pcDistribucion: TcxPageControl
      Left = 1
      Top = 61
      Width = 1278
      Height = 651
      Align = alClient
      TabOrder = 1
      Properties.ActivePage = tsReparto
      Properties.CustomButtons.Buttons = <>
      ClientRectBottom = 647
      ClientRectLeft = 4
      ClientRectRight = 1274
      ClientRectTop = 28
      object tsReparto: TcxTabSheet
        Caption = 'Reparto'
        ImageIndex = 0
        object cxgrdGrupos: TcxGrid
          Left = 0
          Top = 0
          Width = 1270
          Height = 240
          Align = alTop
          TabOrder = 0
          object tvGrupos: TcxGridTableView
            Navigator.Buttons.CustomButtons = <>
            ScrollbarAnnotations.CustomAnnotations = <>
            DataController.Summary.DefaultGroupSummaryItems = <>
            DataController.Summary.FooterSummaryItems = <>
            DataController.Summary.SummaryGroups = <>
            OptionsBehavior.IncSearch = True
            OptionsCustomize.ColumnFiltering = False
            OptionsCustomize.ColumnSorting = False
            OptionsData.Deleting = False
            OptionsData.DeletingConfirmation = False
            OptionsData.Editing = False
            OptionsData.Inserting = False
            OptionsSelection.CellSelect = False
            OptionsView.GroupByBox = False
          end
          object glGrupos: TcxGridLevel
            GridView = tvGrupos
          end
        end
        object splDetalle: TcxSplitter
          Left = 0
          Top = 240
          Width = 1270
          Height = 8
          AlignSplitter = salTop
          Control = cxgrdGrupos
        end
        object pnlDetalle: TPanel
          Left = 0
          Top = 248
          Width = 1270
          Height = 371
          Align = alClient
          BevelOuter = bvNone
          TabOrder = 2
          object cxgrdReparto: TcxGrid
            Left = 0
            Top = 0
            Width = 1270
            Height = 339
            Align = alClient
            TabOrder = 0
            OnEnter = cxgrdRepartoEnter
            OnExit = cxgrdRepartoExit
            object tvReparto: TcxGridTableView
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
              OptionsCustomize.ColumnSorting = False
              OptionsData.Deleting = False
              OptionsData.DeletingConfirmation = False
              OptionsData.Inserting = False
              OptionsView.GroupByBox = False
            end
            object glReparto: TcxGridLevel
              GridView = tvReparto
            end
          end
          object pnlLeyenda: TPanel
            Left = 0
            Top = 339
            Width = 1270
            Height = 32
            Align = alBottom
            BevelOuter = bvNone
            TabOrder = 1
            object lblLeyendaExistencias: TcxLabel
              Left = 8
              Top = 6
              Caption = 'Existencias actuales'
              TabOrder = 0
              Transparent = True
            end
            object lblLeyendaReparto: TcxLabel
              Left = 180
              Top = 6
              Caption = '+ Recibe la tienda'
              TabOrder = 1
              Transparent = True
            end
            object lblLeyendaSalida: TcxLabel
              Left = 340
              Top = 6
              Caption = '- Sale del origen'
              TabOrder = 2
              Transparent = True
            end
            object lblLeyendaAyuda: TcxLabel
              Left = 500
              Top = 6
              Caption =
                'Teclee lo que recibe cada tienda, o arrastre con May'#250'sculas de' +
                ' un almac'#233'n a otro (con Control, todo).'
              TabOrder = 3
              Transparent = True
            end
          end
        end
      end
      object tsPropuestas: TcxTabSheet
        Caption = 'Propuestas de traspaso'
        ImageIndex = 1
        object pnlAccionesPropuestas: TPanel
          Left = 0
          Top = 0
          Width = 1270
          Height = 54
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          object btnImprimirPropuestas: TcxButton
            Left = 8
            Top = 8
            Width = 230
            Height = 38
            Caption = '&Imprimir propuestas'
            TabOrder = 0
            OnClick = btnImprimirPropuestasClick
          end
          object btnConfirmarPropuesta: TcxButton
            Left = 248
            Top = 8
            Width = 230
            Height = 38
            Caption = 'C&onfirmar propuesta'
            TabOrder = 1
            OnClick = btnConfirmarPropuestaClick
          end
          object btnConfirmarTodas: TcxButton
            Left = 488
            Top = 8
            Width = 230
            Height = 38
            Caption = 'Confirmar &todas'
            TabOrder = 2
            OnClick = btnConfirmarTodasClick
          end
          object btnEliminarPropuesta: TcxButton
            Left = 728
            Top = 8
            Width = 230
            Height = 38
            Caption = '&Eliminar propuesta'
            TabOrder = 3
            OnClick = btnEliminarPropuestaClick
          end
        end
        object cxgrdPropuestas: TcxGrid
          Left = 0
          Top = 54
          Width = 1270
          Height = 565
          Align = alClient
          TabOrder = 1
          object tvPropuestas: TcxGridTableView
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
          object glPropuestas: TcxGridLevel
            GridView = tvPropuestas
          end
        end
      end
    end
  end
end
