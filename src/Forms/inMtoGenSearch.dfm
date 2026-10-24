inherited frmMtoSearch: TfrmMtoSearch
  BorderStyle = bsSizeable
  Caption = 'Búsqueda'
  ClientHeight = 501
  ClientWidth = 929
  Visible = False
  StyleElements = [seFont, seClient, seBorder]
  ExplicitWidth = 945
  ExplicitHeight = 540
  TextHeight = 19
  inherited pButtonPage: TPanel
    Width = 789
    Height = 501
    StyleElements = [seFont, seClient, seBorder]
    ExplicitWidth = 789
    ExplicitHeight = 501
    inherited pcPantalla: TcxPageControl
      Width = 789
      Height = 391
      Properties.ActivePage = tsLista
      Properties.HideTabs = True
      ExplicitWidth = 789
      ExplicitHeight = 391
      ClientRectBottom = 387
      ClientRectRight = 785
      ClientRectTop = 4
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 4
        ExplicitWidth = 781
        ExplicitHeight = 383
        inherited cxGrdPrincipal: TcxGrid
          Width = 781
          Height = 383
          ExplicitWidth = 781
          ExplicitHeight = 383
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            OnCellDblClick = cxGrdDBTabPrinCellDblClick
            OptionsData.Appending = False
            OptionsData.CancelOnExit = False
            OptionsData.Deleting = False
            OptionsData.DeletingConfirmation = False
            OptionsData.Inserting = False
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        TabVisible = False
        ExplicitLeft = 4
        ExplicitTop = 4
        ExplicitWidth = 781
        ExplicitHeight = 383
      end
      inherited tsPerfil: TcxTabSheet
        TabVisible = False
        ExplicitTop = 4
        ExplicitWidth = 781
        ExplicitHeight = 383
        inherited pnlPerfilTop: TPanel
          Width = 781
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 781
          inherited edtPerfilBusq: TcxTextEdit
            ExplicitHeight = 27
          end
        end
        inherited pnlPerfilDetail: TPanel
          Width = 781
          Height = 326
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 781
          ExplicitHeight = 326
          inherited cxgrdPerfil: TcxGrid
            Width = 781
            Height = 326
            ExplicitWidth = 781
            ExplicitHeight = 326
          end
        end
      end
    end
    inherited pnlTopPage: TPanel
      Width = 789
      StyleElements = [seFont, seClient, seBorder]
      ExplicitWidth = 789
      inherited pnlTopGrid: TPanel
        Width = 789
        StyleElements = [seFont, seClient, seBorder]
        ExplicitWidth = 789
        inherited sbExportExcel: TSpeedButton
          Visible = False
        end
        inherited edtBusqGlobal: TcxTextEdit
          ExplicitHeight = 27
        end
        inherited nvNavegador: TcxDBNavigator
          Visible = False
        end
      end
    end
    object pnl1: TPanel
      Left = 0
      Top = 431
      Width = 789
      Height = 70
      Align = alBottom
      TabOrder = 2
      object btnAceptar: TcxButton
        Left = 320
        Top = 24
        Width = 177
        Height = 25
        Caption = '&Aceptar (F12)'
        TabOrder = 0
        OnClick = btnAceptarClick
      end
      object btnCancelar1: TcxButton
        Left = 18
        Top = 24
        Width = 177
        Height = 25
        Caption = '&Cancelar (ESC)'
        TabOrder = 1
        OnClick = btnCancelarClick
      end
    end
  end
  inherited pButtonRightBar: TPanel
    Left = 789
    Height = 501
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 789
    ExplicitHeight = 501
    inherited pButtonGen: TPanel
      Top = 303
      StyleElements = [seFont, seClient, seBorder]
      ExplicitTop = 303
      inherited btnGrabar: TcxButton
        Visible = False
      end
      inherited btnCancelar: TcxButton
        Visible = False
      end
      inherited btnSalir: TcxButton
        Visible = False
      end
    end
    inherited pButtonBDStat: TPanel
      StyleElements = [seFont, seClient, seBorder]
      inherited pnStateDataSet: TPanel
        StyleElements = [seFont, seClient, seBorder]
      end
      inherited pnlDataSetName: TPanel
        StyleElements = [seFont, seClient, seBorder]
        inherited lblTablaOrigen: TcxLabel
          ParentFont = False
          Style.Font.Height = -15
          Style.IsFontAssigned = True
          ExplicitWidth = 92
          ExplicitHeight = 21
        end
      end
    end
    object btnAltaRapida: TcxButton
      Left = 7
      Top = 96
      Width = 130
      Height = 33
      Caption = 'Alta &R'#225'pida'
      TabOrder = 2
      OnClick = btnAltaRapidaClick
    end
  end
  inherited Localizer1: TcxLocalizer
    Top = 264
  end
  inherited dsTablaG: TDataSource
    Left = 104
    Top = 264
  end
  inherited saveDialog: TdxSaveFileDialog
    Left = 520
    Top = 256
  end
end
