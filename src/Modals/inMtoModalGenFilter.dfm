inherited frmModalGenFilter: TfrmModalGenFilter
  BorderIcons = []
  BorderStyle = bsSingle
  Caption = 'Filtrar por grupos de datos'
  ClientHeight = 366
  ClientWidth = 617
  Position = poMainFormCenter
  OnClose = FormClose
  ExplicitWidth = 629
  ExplicitHeight = 404
  TextHeight = 19
  object pnl1: TPanel [0]
    Left = 0
    Top = 325
    Width = 617
    Height = 41
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 0
    ExplicitTop = 324
    ExplicitWidth = 613
    object btnGuardar: TcxButton
      Left = 462
      Top = 8
      Width = 145
      Height = 25
      Caption = '&Aceptar'
      TabOrder = 0
      OnClick = btnGuardarClick
    end
    object btnCancelar: TcxButton
      Left = 8
      Top = 8
      Width = 137
      Height = 25
      Caption = '&Cancelar'
      TabOrder = 1
      OnClick = btnCancelarClick
    end
  end
  object cxGrid1: TcxGrid [1]
    Left = 0
    Top = 0
    Width = 617
    Height = 325
    Align = alClient
    TabOrder = 1
    ExplicitWidth = 613
    ExplicitHeight = 324
    object cxGrid1DBTableView1: TcxGridDBTableView
      Navigator.Buttons.CustomButtons = <>
      ScrollbarAnnotations.CustomAnnotations = <>
      DataController.Summary.DefaultGroupSummaryItems = <>
      DataController.Summary.FooterSummaryItems = <>
      DataController.Summary.SummaryGroups = <>
    end
    object cxGrid1Level1: TcxGridLevel
      GridView = cxGrid1DBTableView1
    end
  end
  object pnl2: TPanel [2]
    Left = 0
    Top = 0
    Width = 617
    Height = 325
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    ExplicitWidth = 613
    ExplicitHeight = 324
    object pcFiltros: TcxPageControl
      Left = 0
      Top = 0
      Width = 617
      Height = 325
      Align = alClient
      TabOrder = 0
      Properties.ActivePage = tsFamilias
      Properties.CustomButtons.Buttons = <>
      ExplicitWidth = 613
      ExplicitHeight = 324
      ClientRectBottom = 319
      ClientRectLeft = 3
      ClientRectRight = 611
      ClientRectTop = 32
      object tsEmpresas: TcxTabSheet
        Caption = '&1_Empresas -'
        ImageIndex = 0
        ExplicitWidth = 604
        ExplicitHeight = 286
        object grdEmp: TcxGrid
          Left = 0
          Top = 0
          Width = 608
          Height = 287
          Align = alClient
          TabOrder = 0
          ExplicitWidth = 604
          ExplicitHeight = 286
          object tvEmp: TcxGridDBTableView
            Navigator.Buttons.CustomButtons = <>
            ScrollbarAnnotations.CustomAnnotations = <>
            DataController.DataSource = dmGenFilter.dsEmpresas
            DataController.Summary.DefaultGroupSummaryItems = <>
            DataController.Summary.FooterSummaryItems = <>
            DataController.Summary.SummaryGroups = <>
            OptionsData.CancelOnExit = False
            OptionsData.Deleting = False
            OptionsData.DeletingConfirmation = False
            OptionsData.Editing = False
            OptionsData.Inserting = False
            OptionsSelection.MultiSelect = True
            OptionsSelection.MultiSelectMode = msmPersistent
            OptionsView.GroupByBox = False
            object tvEmpCODIGO_EMPRESA: TcxGridDBColumn
              DataBinding.FieldName = 'CODIGO_EMP_EMP'
            end
            object tvEmpRAZONSOCIAL_EMPRESA: TcxGridDBColumn
              DataBinding.FieldName = 'RAZON_SOCIAL_EMP'
            end
            object tvEmpNIF_EMPRESA: TcxGridDBColumn
              DataBinding.FieldName = 'NIF_EMP'
            end
            object tvEmpMOVIL_EMPRESA: TcxGridDBColumn
              DataBinding.FieldName = 'MOVIL_EMP'
            end
            object tvEmpEMAIL_EMPRESA: TcxGridDBColumn
              DataBinding.FieldName = 'EMAIL_EMP'
            end
            object tvEmpDIRECCION1_EMPRESA: TcxGridDBColumn
              DataBinding.FieldName = 'DIRECCION1_EMP'
            end
            object tvEmpDIRECCION2_EMPRESA: TcxGridDBColumn
              DataBinding.FieldName = 'DIRECCION2_EMP'
            end
            object tvEmpCPOSTAL_EMPRESA: TcxGridDBColumn
              DataBinding.FieldName = 'CODIGO_POSTAL_EMP'
            end
            object tvEmpPOBLACION_EMPRESA: TcxGridDBColumn
              DataBinding.FieldName = 'POBLACION_EMP'
            end
            object tvEmpPROVINCIA_EMPRESA: TcxGridDBColumn
              DataBinding.FieldName = 'PROVINCIA_EMP'
            end
            object tvEmpPAIS_EMPRESA: TcxGridDBColumn
              DataBinding.FieldName = 'PAIS_EMPRESA'
            end
            object tvEmpSERIE_CONTADOR_EMPRESA: TcxGridDBColumn
              DataBinding.FieldName = 'SERIE_CON_EMP'
            end
            object tvEmpGRUPO_ZONA_IVA_EMPRESA: TcxGridDBColumn
              DataBinding.FieldName = 'GRUPO_ZONA_IVA_EMP'
            end
            object tvEmpESRETENCIONES_EMPRESA: TcxGridDBColumn
              DataBinding.FieldName = 'ESRETENCIONES_EMP'
            end
            object tvEmpESREGIMENESPECIALAGRICOLA_EMPRESA: TcxGridDBColumn
              DataBinding.FieldName = 'ESREGIMENESPECIALAGRICOLA_EMP'
            end
            object tvEmpTEXTO_LEGAL_FACTURA_EMPRESA: TcxGridDBColumn
              DataBinding.FieldName = 'TEXTO_LEGAL_FACTURA_EMP'
            end
          end
          object lvEmp: TcxGridLevel
            GridView = tvEmp
          end
        end
      end
      object tsFamilias: TcxTabSheet
        Caption = '&2_Familias -'
        ImageIndex = 1
        object cxDBListBox2: TcxDBListBox
          AlignWithMargins = True
          Left = 3
          Top = 3
          Width = 602
          Height = 281
          Align = alClient
          Columns = 2
          ItemHeight = 19
          MultiSelect = True
          ReadOnly = True
          TabOrder = 0
        end
        object cxDBTreeList1: TcxDBTreeList
          Left = 0
          Top = 0
          Width = 608
          Height = 287
          Align = alClient
          Bands = <
            item
            end>
          DataController.ParentField = 'CODIGO_PADRE_FAM'
          DataController.KeyField = 'CODIGO_FAM_FAM'
          Navigator.Buttons.CustomButtons = <>
          OptionsBehavior.CopyCaptionsToClipboard = False
          OptionsCustomizing.BandCustomizing = False
          OptionsData.CancelOnExit = False
          OptionsData.Editing = False
          OptionsData.Deleting = False
          OptionsSelection.CellSelect = False
          OptionsSelection.HideFocusRect = False
          OptionsSelection.InvertSelect = False
          OptionsSelection.MultiSelect = True
          OptionsView.Headers = False
          OptionsView.Indicator = True
          RootValue = -1
          ScrollbarAnnotations.CustomAnnotations = <>
          TabOrder = 1
          ExplicitLeft = 216
          ExplicitTop = -82
          ExplicitWidth = 250
          ExplicitHeight = 369
          object cxDBTreeList1cxDBTreeListColumn1: TcxDBTreeListColumn
            DataBinding.FieldName = 'NOMBRE_FAM_FAM'
            Width = 210
            Position.ColIndex = 0
            Position.RowIndex = 0
            Position.BandIndex = 0
            Summary.FooterSummaryItems = <>
            Summary.GroupFooterSummaryItems = <>
          end
        end
      end
      object tsTarifas: TcxTabSheet
        Caption = '&3_Tarifas -'
        ImageIndex = 2
        object cxDBListBox3: TcxDBListBox
          AlignWithMargins = True
          Left = 3
          Top = 3
          Width = 602
          Height = 281
          Align = alClient
          Columns = 2
          ItemHeight = 19
          MultiSelect = True
          ReadOnly = True
          TabOrder = 0
        end
      end
      object tsArticulos: TcxTabSheet
        Caption = '&4_Articulos -'
        ImageIndex = 3
      end
      object tsVentas: TcxTabSheet
        Caption = '&5_Borradores -'
        ImageIndex = 4
      end
    end
  end
  inherited Localizer1: TcxLocalizer
    Left = 160
    Top = 328
  end
  object JvEnterAsTab1: TJvEnterAsTab
    Left = 240
    Top = 328
  end
end
