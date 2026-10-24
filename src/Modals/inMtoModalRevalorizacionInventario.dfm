inherited frmModalRevalorizacionInventario: TfrmModalRevalorizacionInventario
  BorderStyle = bsSizeable
  Caption = ''
  ClientHeight = 720
  ClientWidth = 1180
  Constraints.MinHeight = 620
  Constraints.MinWidth = 1100
  Position = poOwnerFormCenter
  StyleElements = [seFont, seClient, seBorder]
  ExplicitWidth = 1196
  ExplicitHeight = 759
  TextHeight = 19
  object pnlConfiguracion: TPanel [0]
    Left = 0
    Top = 0
    Width = 1180
    Height = 190
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblExplicacion: TcxLabel
      Left = 16
      Top = 8
      AutoSize = False
      Caption = ''
      Properties.WordWrap = True
      Transparent = True
      Height = 44
      Width = 1148
    end
    object lblInventario: TcxLabel
      Left = 16
      Top = 53
      AutoSize = False
      Caption = ''
      Style.Font.Style = [fsBold]
      Style.IsFontAssigned = True
      Transparent = True
      Height = 24
      Width = 1148
    end
    object rgTipo: TcxRadioGroup
      Left = 16
      Top = 78
      Caption = ''
      Properties.Columns = 2
      Properties.Items = <
        item
          Caption = ''
        end
        item
          Caption = ''
        end>
      Properties.OnEditValueChanged = ConfiguracionPropertiesChange
      ItemIndex = 0
      TabOrder = 0
      Height = 55
      Width = 260
    end
    object rgBase: TcxRadioGroup
      Left = 294
      Top = 78
      Caption = ''
      Properties.Columns = 2
      Properties.Items = <
        item
          Caption = ''
        end
        item
          Caption = ''
        end>
      Properties.OnEditValueChanged = ConfiguracionPropertiesChange
      ItemIndex = 0
      TabOrder = 1
      Height = 55
      Width = 330
    end
    object lblPorcentaje: TcxLabel
      Left = 642
      Top = 96
      Caption = ''
      Transparent = True
    end
    object curPorcentaje: TcxCurrencyEdit
      Left = 743
      Top = 92
      Properties.DecimalPlaces = 2
      Properties.DisplayFormat = '0.00 %'
      Properties.OnChange = ConfiguracionPropertiesChange
      TabOrder = 2
      Width = 110
    end
    object lblMargenMinimo: TcxLabel
      Left = 600
      Top = 150
      Caption = ''
      Transparent = True
      Visible = False
    end
    object curMargenMinimo: TcxCurrencyEdit
      Left = 740
      Top = 146
      Properties.DecimalPlaces = 2
      Properties.DisplayFormat = '0.00 %'
      Properties.OnChange = ConfiguracionPropertiesChange
      TabOrder = 3
      Visible = False
      Width = 110
    end
    object chkCosteYaDevaluado: TcxCheckBox
      Left = 880
      Top = 146
      Caption = ''
      Properties.OnChange = ConfiguracionPropertiesChange
      TabOrder = 4
      Transparent = True
      Visible = False
      Width = 260
    end
    object btnSimular: TcxButton
      Left = 16
      Top = 141
      Width = 140
      Height = 36
      Caption = ''
      Default = True
      TabOrder = 3
      OnClick = btnSimularClick
    end
    object btnSeleccionarTodo: TcxButton
      Left = 174
      Top = 141
      Width = 175
      Height = 36
      Caption = ''
      TabOrder = 4
      OnClick = btnSeleccionarTodoClick
    end
    object btnSeleccionarNinguno: TcxButton
      Left = 367
      Top = 141
      Width = 190
      Height = 36
      Caption = ''
      TabOrder = 5
      OnClick = btnSeleccionarNingunoClick
    end
  end
  object cxgrdSimulacion: TcxGrid [1]
    Left = 0
    Top = 190
    Width = 1180
    Height = 360
    Align = alClient
    TabOrder = 1
    object tvSimulacion: TcxGridDBTableView
      DataController.DataSource = dsSimulacion
      FilterRow.Visible = True
      Navigator.Buttons.ConfirmDelete = True
      OptionsBehavior.FocusCellOnTab = True
      OptionsCustomize.ColumnHiding = True
      OptionsData.Deleting = False
      OptionsData.DeletingConfirmation = False
      OptionsData.Inserting = False
      OptionsView.GroupByBox = False
    end
    object cxgrdlvlSimulacion: TcxGridLevel
      GridView = tvSimulacion
    end
  end
  object pnlResumen: TPanel [2]
    Left = 0
    Top = 550
    Width = 1180
    Height = 110
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object lblNumeroLineas: TcxLabel
      Left = 16
      Top = 10
      Caption = ''
      Transparent = True
    end
    object lblTotalAnterior: TcxLabel
      Left = 250
      Top = 10
      Caption = ''
      Transparent = True
    end
    object curTotalAnterior: TcxCurrencyEdit
      Left = 355
      Top = 6
      Properties.DecimalPlaces = 2
      Properties.DisplayFormat = '#,##0.00 '#8364';-#,##0.00 '#8364
      Properties.ReadOnly = True
      TabOrder = 0
      Width = 145
    end
    object lblTotalSimulado: TcxLabel
      Left = 520
      Top = 10
      Caption = ''
      Transparent = True
    end
    object curTotalSimulado: TcxCurrencyEdit
      Left = 625
      Top = 6
      Properties.DecimalPlaces = 2
      Properties.DisplayFormat = '#,##0.00 '#8364';-#,##0.00 '#8364
      Properties.ReadOnly = True
      TabOrder = 1
      Width = 145
    end
    object lblTotalDiferencia: TcxLabel
      Left = 790
      Top = 10
      Caption = ''
      Transparent = True
    end
    object curTotalDiferencia: TcxCurrencyEdit
      Left = 910
      Top = 6
      Properties.DecimalPlaces = 2
      Properties.DisplayFormat = '+#,##0.00 '#8364';-#,##0.00 '#8364
      Properties.ReadOnly = True
      TabOrder = 2
      Width = 155
    end
    object lblAvisos: TcxLabel
      Left = 16
      Top = 43
      AutoSize = False
      Caption = ''
      Properties.WordWrap = True
      Transparent = True
      Height = 58
      Width = 1148
    end
  end
  object pnlBotones: TPanel [3]
    Left = 0
    Top = 660
    Width = 1180
    Height = 60
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 3
    object btnImprimir: TcxButton
      Left = 20
      Top = 10
      Width = 240
      Height = 40
      Caption = ''
      Enabled = False
      TabOrder = 2
      OnClick = btnImprimirClick
    end
    object btnCancelar: TcxButton
      Left = 320
      Top = 10
      Width = 240
      Height = 40
      Cancel = True
      Caption = ''
      TabOrder = 0
      OnClick = btnCancelarClick
    end
    object btnPreparar: TcxButton
      Left = 620
      Top = 10
      Width = 240
      Height = 40
      Caption = ''
      Enabled = False
      TabOrder = 1
      OnClick = btnPrepararClick
    end
  end
  object cdsSimulacion: TClientDataSet
    Aggregates = <>
    Params = <>
    AfterPost = cdsSimulacionAfterPost
    Left = 1040
    Top = 168
  end
  object dsSimulacion: TDataSource
    DataSet = cdsSimulacion
    Left = 1096
    Top = 168
  end
end
