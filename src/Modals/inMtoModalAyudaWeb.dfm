inherited frmModalAyudaWeb: TfrmModalAyudaWeb
  Caption = 'Ayuda'
  ClientHeight = 720
  ClientWidth = 1100
  Constraints.MinHeight = 480
  Constraints.MinWidth = 640
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  OnShow = FormShow
  TextHeight = 18
  object pnlNavegacion: TPanel [0]
    Left = 0
    Top = 0
    Width = 1100
    Height = 52
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object btnAtras: TcxButton
      Left = 12
      Top = 9
      Width = 100
      Height = 34
      Caption = 'Atr'#225's'
      Enabled = False
      TabOrder = 0
      OnClick = btnAtrasClick
    end
    object btnAdelante: TcxButton
      Left = 120
      Top = 9
      Width = 100
      Height = 34
      Caption = 'Adelante'
      Enabled = False
      TabOrder = 1
      OnClick = btnAdelanteClick
    end
    object btnRecargar: TcxButton
      Left = 228
      Top = 9
      Width = 100
      Height = 34
      Caption = 'Recargar'
      TabOrder = 2
      OnClick = btnRecargarClick
    end
    object btnSalir: TcxButton
      Left = 988
      Top = 9
      Width = 100
      Height = 34
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Salir'
      ModalResult = 2
      TabOrder = 3
    end
  end
  object lblEstado: TcxLabel [1]
    Left = 0
    Top = 52
    Align = alClient
    AutoSize = False
    Properties.Alignment.Horz = taCenter
    Properties.Alignment.Vert = taVCenter
    Properties.WordWrap = True
    Height = 668
    Width = 1100
  end
  object navegador: TEdgeBrowser [2]
    Left = 0
    Top = 52
    Width = 1100
    Height = 668
    Align = alClient
    TabOrder = 2
    OnCreateWebViewCompleted = navegadorCreado
    OnHistoryChanged = navegadorHistorial
    OnNavigationStarting = navegadorIniciaNavegacion
    OnNewWindowRequested = navegadorNuevaVentana
  end
end
