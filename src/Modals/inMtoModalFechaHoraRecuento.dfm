inherited frmModalFechaHoraRecuento: TfrmModalFechaHoraRecuento
  BorderStyle = bsDialog
  Caption = ''
  ClientHeight = 230
  ClientWidth = 540
  Position = poOwnerFormCenter
  TextHeight = 19
  object pnlContenido: TPanel [0]
    Left = 0
    Top = 0
    Width = 540
    Height = 171
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object lblExplicacion: TcxLabel
      Left = 24
      Top = 20
      AutoSize = False
      Caption = ''
      Properties.WordWrap = True
      Transparent = True
      Height = 64
      Width = 492
    end
    object lblFechaHora: TcxLabel
      Left = 24
      Top = 99
      Caption = ''
      Transparent = True
    end
    object dteFechaHora: TcxDateEdit
      Left = 248
      Top = 96
      Properties.DisplayFormat = 'dd/mm/yyyy hh:nn:ss'
      Properties.EditFormat = 'dd/mm/yyyy hh:nn:ss'
      Properties.Kind = ckDateTime
      TabOrder = 0
      Width = 190
    end
  end
  object pnlBotones: TPanel [1]
    Left = 0
    Top = 171
    Width = 540
    Height = 59
    Align = alBottom
    TabOrder = 1
    object btnCancelar: TcxButton
      Left = 32
      Top = 9
      Width = 220
      Height = 40
      Cancel = True
      Caption = ''
      TabOrder = 0
      OnClick = btnCancelarClick
    end
    object btnAceptar: TcxButton
      Left = 288
      Top = 9
      Width = 220
      Height = 40
      Caption = ''
      Default = True
      TabOrder = 1
      OnClick = btnAceptarClick
    end
  end
end
