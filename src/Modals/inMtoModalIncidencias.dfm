inherited frmModalIncidencias: TfrmModalIncidencias
  Caption = 'Incidencias'
  ClientHeight = 480
  ClientWidth = 700
  StyleElements = [seFont, seClient, seBorder]
  OnClose = FormClose
  ExplicitWidth = 700
  ExplicitHeight = 480
  TextHeight = 19
  object pnlBody: TPanel [0]
    Left = 0
    Top = 0
    Width = 700
    Height = 420
    Align = alClient
    TabOrder = 0
    object lblTitulo: TcxLabel
      Left = 16
      Top = 12
      Caption = 'Se han detectado las siguientes incidencias:'
      Style.Font.Style = [fsBold]
      Style.IsFontAssigned = True
      Transparent = True
    end
    object memInc: TcxMemo
      Left = 16
      Top = 44
      Anchors = [akLeft, akTop, akRight, akBottom]
      Properties.ReadOnly = True
      Properties.ScrollBars = ssVertical
      Properties.WordWrap = True
      Style.Font.Name = 'Consolas'
      Style.IsFontAssigned = True
      TabOrder = 0
      Height = 360
      Width = 668
    end
  end
  object pnlButton: TPanel [1]
    Left = 0
    Top = 420
    Width = 700
    Height = 60
    Align = alBottom
    TabOrder = 1
    object btnAceptar: TcxButton
      Left = 510
      Top = 12
      Width = 170
      Height = 38
      Cancel = True
      Caption = '&Aceptar'
      Default = True
      TabOrder = 0
      OnClick = btnAceptarClick
    end
  end
end
