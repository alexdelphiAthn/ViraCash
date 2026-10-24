inherited frmModalDistribuidor: TfrmModalDistribuidor
  Caption = 'Distribuidor por almac'#233'n / talla'
  ClientHeight = 480
  ClientWidth = 900
  StyleElements = [seFont, seClient, seBorder]
  OnDestroy = FormDestroy
  ExplicitWidth = 916
  ExplicitHeight = 519
  TextHeight = 19
  inherited pnlButton: TPanel
    Top = 421
    Width = 900
    StyleElements = [seFont, seClient, seBorder]
    ExplicitTop = 421
    ExplicitWidth = 900
    inherited btnCancelar: TcxButton
      Left = 486
      Top = 10
      OnClick = btnCancelarClick
      ExplicitLeft = 486
      ExplicitTop = 10
    end
    inherited btnAceptar: TcxButton
      Left = 690
      Top = 10
      ExplicitLeft = 690
      ExplicitTop = 10
    end
  end
  inherited pnlBody: TPanel
    Width = 900
    Height = 421
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 0
    ExplicitTop = 0
    ExplicitWidth = 900
    ExplicitHeight = 421
    object pnlCab: TPanel
      Left = 1
      Top = 1
      Width = 898
      Height = 50
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
      object lblTitulo: TcxLabel
        Left = 16
        Top = 12
        Caption = 'Distribuci'#243'n almac'#233'n / talla'
        TabOrder = 1
        Transparent = True
      end
      object lblLinea: TcxLabel
        Left = 320
        Top = 14
        Caption = 'L'#237'nea:'
        TabOrder = 2
        Transparent = True
      end
      object edtLinea: TcxTextEdit
        Left = 380
        Top = 12
        Enabled = False
        TabOrder = 0
        Width = 80
      end
      object btnKitTodos: TcxButton
        Left = 560
        Top = 8
        Width = 300
        Height = 32
        Caption = 'Aplicar kit en todos los almacenes'
        Colors.Default = 12579775
        Colors.Normal = 12579775
        LookAndFeel.Kind = lfFlat
        LookAndFeel.NativeStyle = False
        TabOrder = 3
        Visible = False
        OnClick = btnKitTodosClick
      end
    end
    object pnlCuadrante: TPanel
      Left = 1
      Top = 51
      Width = 898
      Height = 369
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 1
      object cxgrdCuadr: TcxGrid
        Left = 0
        Top = 0
        Width = 898
        Height = 369
        Align = alClient
        TabOrder = 0
        object tvCuadr: TcxGridDBTableView
          DataController.DataSource = dsCuadr
          OptionsBehavior.FocusCellOnTab = True
          OptionsBehavior.GoToNextCellOnEnter = True
          OptionsBehavior.ImmediateEditor = True
          OptionsBehavior.IncSearch = False
          OptionsCustomize.ColumnHiding = True
          OptionsData.Deleting = False
          OptionsData.DeletingConfirmation = False
          OptionsData.Inserting = False
          OptionsView.GroupByBox = False
        end
        object cxlvlCuadr: TcxGridLevel
          GridView = tvCuadr
        end
      end
    end
  end
  object cdsCuadr: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 16
    Top = 60
  end
  object dsCuadr: TDataSource
    DataSet = cdsCuadr
    Left = 56
    Top = 60
  end
end
