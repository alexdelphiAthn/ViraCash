inherited frmStockConsulta: TfrmStockConsulta
  Left = 0
  Top = 0
  Caption = 'Consulta de stock (Ctrl+U)'
  ClientHeight = 612
  ClientWidth = 898
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = 'Source Sans 3'
  Font.Style = []
  Position = poDesigned
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 17
  object pnlCabecera: TPanel
    Left = 0
    Top = 0
    Width = 898
    Height = 256
    Align = alTop
    BevelOuter = bvNone
    Constraints.MinHeight = 256
    TabOrder = 0
    ExplicitWidth = 896
    DesignSize = (
      898
      256)
    object imgFoto: TImage
      Left = 493
      Top = 8
      Width = 397
      Height = 240
      Anchors = [akTop, akRight, akBottom]
      Center = True
      Proportional = True
      Stretch = True
    end
    object btnOperacionesCaja: TcxButton
      Left = 16
      Top = 12
      Width = 120
      Height = 28
      Hint = 'Muestra las operaciones de caja de la talla seleccionada'
      Caption = 'Op de Caja'
      ShowHint = True
      TabOrder = 0
      OnClick = btnOperacionesCajaClick
    end
    object btnMovimientos: TcxButton
      Left = 148
      Top = 12
      Width = 120
      Height = 28
      Hint = 'Muestra los movimientos de almac'#233'n de la talla seleccionada'
      Caption = 'Movimientos'
      ShowHint = True
      TabOrder = 1
      OnClick = btnMovimientosClick
    end
    object lblArt: TcxLabel
      Left = 16
      Top = 54
      Caption = 'Art'#237'culo'
      TabOrder = 3
      Transparent = True
    end
    object btnArt: TcxButtonEdit
      Left = 90
      Top = 52
      Properties.Buttons = <
        item
          Default = True
          Kind = bkEllipsis
        end>
      Properties.OnButtonClick = btnArtPropertiesButtonClick
      Properties.OnEditValueChanged = btnArtPropertiesEditValueChanged
      TabOrder = 2
      Width = 200
    end
    object lblDescr: TcxLabel
      Left = 16
      Top = 86
      TabOrder = 4
      Transparent = True
    end
    object mInfoCabecera: TcxMemo
      Left = 16
      Top = 118
      Anchors = [akLeft, akTop, akRight, akBottom]
      Properties.ReadOnly = True
      Properties.ScrollBars = ssVertical
      Properties.WordWrap = True
      Style.BorderStyle = ebsNone
      StyleFocused.BorderStyle = ebsNone
      StyleHot.BorderStyle = ebsNone
      StyleReadOnly.BorderStyle = ebsNone
      TabOrder = 5
      Height = 130
      Width = 461
    end
    object lblLetreroTemp: TcxLabel
      Left = 0
      Top = 222
      Align = alBottom
      AutoSize = False
      Caption = ' '
      Properties.Alignment.Horz = taCenter
      Properties.Alignment.Vert = taVCenter
      Properties.WordWrap = True
      TabOrder = 6
      Transparent = False
      Visible = False
      Height = 34
      Width = 898
    end
  end
  object pnlFiltros: TPanel
    Left = 0
    Top = 256
    Width = 898
    Height = 44
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    ExplicitWidth = 896
    object lblEstado: TcxLabel
      Left = 16
      Top = 12
      Caption = 'Estado del stock'
      TabOrder = 1
      Transparent = True
    end
    object cbbEstado: TcxComboBox
      Left = 162
      Top = 10
      Properties.DropDownListStyle = lsFixedList
      Properties.OnEditValueChanged = cbbEstadoPropertiesEditValueChanged
      TabOrder = 0
      Width = 188
    end
  end
  object pnlBody: TPanel
    Left = 0
    Top = 300
    Width = 898
    Height = 284
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    ExplicitWidth = 896
    ExplicitHeight = 276
    object splVert: TcxSplitter
      Left = 280
      Top = 0
      Width = 8
      Height = 284
      Control = pnlIzq
    end
    object pnlIzq: TPanel
      Left = 0
      Top = 0
      Width = 280
      Height = 284
      Align = alLeft
      BevelOuter = bvNone
      TabOrder = 0
      ExplicitHeight = 276
      object pcFiltros: TcxPageControl
        Left = 0
        Top = 0
        Width = 280
        Height = 284
        Align = alClient
        TabOrder = 0
        Properties.ActivePage = tsColores
        Properties.CustomButtons.Buttons = <>
        ExplicitHeight = 276
        ClientRectBottom = 280
        ClientRectLeft = 4
        ClientRectRight = 276
        ClientRectTop = 28
        object tsColores: TcxTabSheet
          Caption = '1 Colores'
          ImageIndex = 0
          ExplicitHeight = 244
          DesignSize = (
            272
            252)
          object lblColores: TcxLabel
            Left = 8
            Top = 4
            Caption = 'Colores del art'#237'culo'
            TabOrder = 1
            Transparent = True
          end
          object lstColores: TcxListBox
            Left = 8
            Top = 32
            Width = 252
            Height = 269
            Anchors = [akLeft, akTop, akRight, akBottom]
            MultiSelect = True
            TabOrder = 0
            OnClick = lstColoresClick
            ExplicitHeight = 261
          end
        end
        object tsAlmacenes: TcxTabSheet
          Caption = '2 Almacenes'
          ImageIndex = 1
          ExplicitLeft = 0
          ExplicitTop = 0
          ExplicitWidth = 0
          ExplicitHeight = 0
          DesignSize = (
            272
            252)
          object lblAlmacenes: TcxLabel
            Left = 8
            Top = 4
            Caption = 'Almacenes'
            TabOrder = 1
            Transparent = True
          end
          object lstAlmacenes: TcxListBox
            Left = 8
            Top = 32
            Width = 252
            Height = 269
            Anchors = [akLeft, akTop, akRight, akBottom]
            MultiSelect = True
            TabOrder = 0
            OnClick = lstAlmacenesClick
          end
        end
      end
    end
    object pnlDer: TPanel
      Left = 283
      Top = 0
      Width = 615
      Height = 284
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 1
      ExplicitWidth = 613
      ExplicitHeight = 276
      object pcVistas: TcxPageControl
        Left = 0
        Top = 0
        Width = 615
        Height = 30
        Align = alTop
        TabOrder = 0
        Properties.ActivePage = tsPorAlmacen
        Properties.CustomButtons.Buttons = <>
        OnChange = pcVistasChange
        ExplicitWidth = 613
        ClientRectBottom = 28
        ClientRectLeft = 4
        ClientRectRight = 611
        ClientRectTop = 28
        object tsPorAlmacen: TcxTabSheet
          Caption = '3 Por almacenes'
          ImageIndex = 0
          ExplicitWidth = 605
        end
        object tsPorColor: TcxTabSheet
          Caption = '4 Por colores'
          ImageIndex = 1
          ExplicitLeft = 0
          ExplicitTop = 0
          ExplicitWidth = 0
        end
      end
      object grdStock: TcxGrid
        Left = 0
        Top = 30
        Width = 615
        Height = 254
        Align = alClient
        TabOrder = 1
        ExplicitWidth = 613
        ExplicitHeight = 246
        object tvStock: TcxGridDBTableView
          OnCellDblClick = tvStockCellDblClick
          OptionsCustomize.ColumnMoving = False
          OptionsData.Editing = False
          OptionsView.GroupByBox = False
        end
        object glStock: TcxGridLevel
          GridView = tvStock
        end
      end
    end
  end
  object pnlLeyenda: TPanel
    Left = 0
    Top = 584
    Width = 898
    Height = 28
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 3
    ExplicitTop = 576
    ExplicitWidth = 896
  end
end
