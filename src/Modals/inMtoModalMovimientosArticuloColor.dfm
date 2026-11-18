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
    Height = 198
    Width = 1200
    object lblArticulo: TcxLabel
      Left = 12
      Top = 8
      AutoSize = False
      Anchors = [akLeft, akTop, akRight]
      Transparent = True
      Height = 24
      Width = 796
    end
    object lblPrecios: TcxLabel
      Left = 12
      Top = 80
      AutoSize = False
      Anchors = [akLeft, akTop, akRight]
      Transparent = True
      Properties.WordWrap = True
      Height = 104
      Width = 796
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
    object calendario: TMonthCalendar
      Left = 824
      Top = 4
      Width = 219
      Height = 162
      Anchors = [akTop, akRight]
      AutoSize = False
      ShowToday = False
      ShowTodayCircle = False
      OnChange = calendarioChange
      TabOrder = 4
    end
    object lblFecha: TcxLabel
      Left = 816
      Top = 168
      Width = 234
      Height = 24
      Anchors = [akTop, akRight]
      AutoSize = False
      Properties.Alignment.Horz = taCenter
      Transparent = True
    end
    object imgFoto: TImage
      Left = 1054
      Top = 8
      Width = 134
      Height = 176
      Anchors = [akTop, akRight]
      Center = True
      Proportional = True
      Stretch = True
      ShowHint = True
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
    object btnIrMovimiento: TcxButton
      Left = 8
      Top = 8
      Width = 230
      Height = 32
      Action = actIrMovimiento
      TabOrder = 1
    end
    object btnIrDocumento: TcxButton
      Left = 246
      Top = 8
      Width = 270
      Height = 32
      Action = actIrDocumento
      TabOrder = 2
    end
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
    object lvlMovimientos: TcxGridLevel
    end
  end
  object dsMovimientos: TDataSource
    OnDataChange = dsMovimientosDataChange
    Left = 496
    Top = 16
  end
  object alNavegacion: TActionList
    Left = 536
    Top = 16
    object actIrMovimiento: TAction
      Caption = 'Ir a movimiento (Ctrl+M)'
      Enabled = False
      ShortCut = 16461
      OnExecute = actIrMovimientoExecute
    end
    object actIrDocumento: TAction
      Caption = 'Ir a documento (Ctrl+Mayús+A)'
      Enabled = False
      ShortCut = 24641
      OnExecute = actIrDocumentoExecute
    end
  end
end
