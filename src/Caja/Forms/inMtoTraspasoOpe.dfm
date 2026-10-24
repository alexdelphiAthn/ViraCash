inherited frmMtoOpeTraspaso: TfrmMtoOpeTraspaso
  Caption = 'Traspasos'
  ClientHeight = 647
  ClientWidth = 896
  StyleElements = [seFont, seClient, seBorder]
  OnDestroy = FormDestroy
  OnShow = FormShow
  ExplicitLeft = 3
  ExplicitTop = 3
  ExplicitWidth = 912
  ExplicitHeight = 678
  TextHeight = 17
  object pnlModos: TPanel [0]
    Left = 0
    Top = 0
    Width = 896
    Height = 40
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    ExplicitWidth = 894
    object btnModoTraspaso: TcxButton
      Left = 8
      Top = 6
      Width = 112
      Height = 28
      Caption = 'Traspaso'
      TabOrder = 0
      OnClick = btnModoClick
    end
    object btnModoReposicion: TcxButton
      Tag = 3
      Left = 126
      Top = 6
      Width = 148
      Height = 28
      Caption = 'F5 Reposiciones'
      TabOrder = 1
      OnClick = btnModoClick
    end
    object btnModoSolicitar: TcxButton
      Tag = 1
      Left = 282
      Top = 6
      Width = 215
      Height = 28
      Caption = 'F6 Solicitar a otro almac'#233'n'
      TabOrder = 2
      OnClick = btnModoClick
    end
    object btnModoAtender: TcxButton
      Tag = 2
      Left = 505
      Top = 6
      Width = 185
      Height = 28
      Caption = 'F7 Atender solicitudes'
      TabOrder = 3
      OnClick = btnModoClick
    end
    object btnMisPeticiones: TcxButton
      Left = 698
      Top = 6
      Width = 96
      Height = 28
      Caption = 'Mis peticiones'
      TabOrder = 4
      OnClick = btnMisPeticionesClick
    end
    object btnConfirmarPropuesta: TcxButton
      Left = 798
      Top = 6
      Width = 92
      Height = 28
      Caption = 'Confirmar propuesta'
      TabOrder = 5
      OnClick = btnConfirmarPropuestaClick
    end
  end
  object pnlTop: TPanel [1]
    Left = 0
    Top = 40
    Width = 896
    Height = 89
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    ExplicitWidth = 894
    object lblOrigen: TcxLabel
      Left = 16
      Top = 14
      Caption = 'ALMAC'#201'N ORIGEN'
      TabOrder = 3
    end
    object txtOrigen: TcxTextEdit
      Left = 163
      Top = 14
      Properties.ReadOnly = True
      TabOrder = 0
      Width = 222
    end
    object lblDestino: TcxLabel
      Left = 420
      Top = 14
      Caption = 'ALMAC'#201'N DESTINO'
      TabOrder = 4
    end
    object cboDestino: TcxComboBox
      Left = 576
      Top = 14
      TabOrder = 1
      Width = 304
    end
    object lblEmpleado: TcxLabel
      Left = 16
      Top = 52
      Caption = 'Empleado (responsable)'
      TabOrder = 5
    end
    object txtEmpleado: TcxButtonEdit
      Left = 200
      Top = 52
      Properties.Buttons = <
        item
          Default = True
          Kind = bkEllipsis
        end>
      Properties.OnButtonClick = txtEmpleadoButtonClick
      TabOrder = 2
      OnExit = txtEmpleadoExit
      Width = 120
    end
    object lblEmpleadoNombre: TcxLabel
      Left = 330
      Top = 52
      TabOrder = 6
    end
    object lblVentasDesde: TcxLabel
      Left = 16
      Top = 94
      Caption = 'VENTAS DESDE'
      TabOrder = 7
      Visible = False
    end
    object dteVentasDesde: TcxDateEdit
      Left = 136
      Top = 91
      Properties.DisplayFormat = 'dd/mm/yyyy hh:nn:ss'
      Properties.EditFormat = 'dd/mm/yyyy hh:nn:ss'
      Properties.Kind = ckDateTime
      Properties.OnChange = dteVentasPropertiesChange
      TabOrder = 3
      Visible = False
      Width = 180
    end
    object lblVentasHasta: TcxLabel
      Left = 332
      Top = 94
      Caption = 'VENTAS HASTA'
      TabOrder = 8
      Visible = False
    end
    object dteVentasHasta: TcxDateEdit
      Left = 452
      Top = 91
      Properties.DisplayFormat = 'dd/mm/yyyy hh:nn:ss'
      Properties.EditFormat = 'dd/mm/yyyy hh:nn:ss'
      Properties.Kind = ckDateTime
      Properties.OnChange = dteVentasPropertiesChange
      TabOrder = 4
      Visible = False
      Width = 180
    end
    object btnCargarVentas: TcxButton
      Left = 648
      Top = 89
      Width = 232
      Height = 28
      Caption = 'Cargar ventas'
      TabOrder = 5
      Visible = False
      OnClick = btnCargarVentasClick
    end
  end
  object pnlBottom: TPanel [2]
    Left = 0
    Top = 579
    Width = 896
    Height = 68
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 3
    ExplicitTop = 571
    ExplicitWidth = 894
    object lblTotal: TcxLabel
      Left = 16
      Top = 20
      Caption = 'Importe traspaso: 0,00'
      TabOrder = 3
    end
    object btnF8: TcxButton
      Left = 330
      Top = 10
      Width = 170
      Height = 40
      Caption = 'F8 Borrar l'#237'nea'
      TabOrder = 0
      OnClick = btnF8Click
    end
    object btnF11: TcxButton
      Left = 520
      Top = 10
      Width = 170
      Height = 40
      Caption = 'F11 Sin ticket'
      TabOrder = 1
      OnClick = btnF11Click
    end
    object btnF12: TcxButton
      Left = 700
      Top = 10
      Width = 170
      Height = 40
      Caption = 'F12 Con ticket'
      TabOrder = 2
      OnClick = btnF12Click
    end
  end
  object pnlCentro: TPanel [3]
    Left = 0
    Top = 129
    Width = 896
    Height = 450
    Align = alClient
    BevelOuter = bvNone
    Padding.Left = 4
    Padding.Right = 4
    TabOrder = 2
    ExplicitWidth = 894
    ExplicitHeight = 442
    object FGrid: TcxGrid
      Left = 0
      Top = 0
      Width = 896
      Height = 272
      Align = alClient
      TabOrder = 0
      ExplicitWidth = 894
      ExplicitHeight = 264
      object FView: TcxGridDBTableView
        OptionsBehavior.FocusCellOnTab = True
        OptionsBehavior.FocusFirstCellOnNewRecord = True
        OptionsBehavior.GoToNextCellOnEnter = True
      end
      object lvlLineas: TcxGridLevel
        GridView = FView
      end
    end
    object FStockPanel: TPanel
      Left = 0
      Top = 280
      Width = 896
      Height = 170
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 1
      ExplicitTop = 272
      ExplicitWidth = 894
      object FFotoPanel: TPanel
        Left = 736
        Top = 0
        Width = 160
        Height = 170
        Align = alRight
        BevelOuter = bvNone
        TabOrder = 1
        ExplicitLeft = 734
        object FFotoImg: TImage
          Left = 0
          Top = 0
          Width = 160
          Height = 170
          Align = alClient
          Center = True
          Proportional = True
        end
      end
      object FFotoSplitter: TcxSplitter
        Left = 728
        Top = 0
        Width = 8
        Height = 170
        AlignSplitter = salRight
        Control = FFotoPanel
        ExplicitLeft = 726
      end
      object FStockGrid: TcxGrid
        Left = 0
        Top = 0
        Width = 728
        Height = 170
        Align = alClient
        TabOrder = 0
        ExplicitWidth = 726
        object FStockView: TcxGridDBTableView
        end
        object lvlStock: TcxGridLevel
          GridView = FStockView
        end
      end
    end
    object FStockSplitter: TcxSplitter
      Left = 0
      Top = 272
      Width = 896
      Height = 8
      AlignSplitter = salBottom
      ExplicitTop = 264
      ExplicitWidth = 894
    end
  end
end
