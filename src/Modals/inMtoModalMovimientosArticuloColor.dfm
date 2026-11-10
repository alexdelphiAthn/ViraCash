inherited frmModalMovimientosArticuloColor: TfrmModalMovimientosArticuloColor
  BorderStyle = bsSizeable
  Caption = 'Movimientos por artículo/color'
  ClientHeight = 600
  ClientWidth = 1200
  Constraints.MinHeight = 360
  Constraints.MinWidth = 780
  Position = poOwnerFormCenter
  object pnlCabecera: TcxGroupBox [0]
    Align = alTop
    PanelStyle.Active = True
    Style.BorderStyle = ebsNone
    TabOrder = 0
    Transparent = True
    Height = 112
    Width = 1200
    object lblArticulo: TcxLabel
      Left = 12
      Top = 8
      AutoSize = False
      Anchors = [akLeft, akTop, akRight]
      Transparent = True
      Height = 24
      Width = 1170
    end
    object lblPrecios: TcxLabel
      Left = 12
      Top = 78
      AutoSize = False
      Anchors = [akLeft, akTop, akRight]
      Transparent = True
      Height = 24
      Width = 1170
    end
    object lblColor: TcxLabel
      Left = 12
      Top = 42
      Caption = 'Color:'
      Transparent = True
    end
    object cbbColor: TcxComboBox
      Left = 72
      Top = 38
      Properties.DropDownListStyle = lsFixedList
      Properties.OnChange = cbbColorPropertiesChange
      Properties.OnDrawItem = DibujarColorCombo
      TabOrder = 3
      Width = 260
    end
    object imgColor: TImage
      Left = 342
      Top = 38
      Width = 24
      Height = 24
      Center = True
      ShowHint = True
      Visible = False
    end
  end
  object pnlBotones: TcxGroupBox [1]
    Align = alBottom
    PanelStyle.Active = True
    Style.BorderStyle = ebsNone
    TabOrder = 2
    Transparent = True
    Height = 48
    Width = 1200
    object btnCerrar: TcxButton
      Left = 1080
      Top = 8
      Width = 106
      Height = 32
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Cerrar'
      ModalResult = 2
      TabOrder = 0
    end
  end
  object cxgrdMovimientos: TcxGrid [2]
    Align = alClient
    TabOrder = 1
    object tvMovimientos: TcxGridDBTableView
      DataController.DataSource = dsMovimientos
      FilterRow.Visible = True
      OptionsBehavior.AlwaysShowEditor = False
      OptionsData.CancelOnExit = False
      OptionsData.Deleting = False
      OptionsData.Editing = False
      OptionsData.Inserting = False
      OptionsView.ColumnAutoWidth = False
      OptionsView.HeaderAutoHeight = True
      OptionsView.GroupByBox = True
      OptionsView.NoDataToDisplayInfoText = 'Sin movimientos'
    end
    object lvlMovimientos: TcxGridLevel
      GridView = tvMovimientos
    end
  end
  object dsMovimientos: TDataSource
    Left = 496
    Top = 16
  end
end
