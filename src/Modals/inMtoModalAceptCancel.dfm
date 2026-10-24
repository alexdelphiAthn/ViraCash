inherited frmModalAceptCancel: TfrmModalAceptCancel
  Caption = ''
  ClientHeight = 408
  ClientWidth = 526
  StyleElements = [seFont, seClient, seBorder]
  OnClose = FormClose
  OnShow = FormShow
  ExplicitLeft = 3
  ExplicitTop = 3
  ExplicitWidth = 542
  ExplicitHeight = 447
  TextHeight = 19
  object pnlButton: TPanel [0]
    Left = 0
    Top = 349
    Width = 526
    Height = 59
    Align = alBottom
    TabOrder = 0
    ExplicitTop = 288
    object btnCancelar: TcxButton
      Left = 34
      Top = 9
      Width = 177
      Height = 40
      Cancel = True
      Caption = '&Cancelar (ESC)'
      TabOrder = 0
      OnClick = btnCancelarClick
    end
    object btnAceptar: TcxButton
      Left = 309
      Top = 9
      Width = 177
      Height = 40
      Caption = '&Aceptar (F12)'
      TabOrder = 1
      OnClick = btnAceptarClick
    end
  end
  object pnlBody: TPanel [1]
    Left = 0
    Top = 0
    Width = 526
    Height = 349
    Align = alClient
    TabOrder = 1
    ExplicitLeft = 176
    ExplicitTop = 200
    ExplicitWidth = 185
    ExplicitHeight = 41
  end
  object ActionList1: TActionList
    Left = 256
    Top = 208
    object Action1: TAction
      Caption = 'Action1'
      ShortCut = 123
      OnExecute = Action1Execute
    end
    object Action2: TAction
      Caption = 'Action2'
      ShortCut = 27
      OnExecute = Action2Execute
    end
  end
end
