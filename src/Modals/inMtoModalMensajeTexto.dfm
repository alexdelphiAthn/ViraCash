inherited frmModalMensajeTexto: TfrmModalMensajeTexto
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSizeable
  Caption = 'Información'
  ClientHeight = 330
  ClientWidth = 650
  Constraints.MinHeight = 260
  Constraints.MinWidth = 520
  Position = poOwnerFormCenter
  TextHeight = 19
  object pnlBotones: TPanel [0]
    Left = 0
    Top = 278
    Width = 650
    Height = 52
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnCopiar: TcxButton
      Left = 348
      Top = 8
      Width = 180
      Height = 32
      Anchors = [akTop, akRight]
      Caption = 'Copiar todo'
      TabOrder = 0
      OnClick = btnCopiarClick
    end
    object btnCerrar: TcxButton
      Left = 538
      Top = 8
      Width = 100
      Height = 32
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Cerrar'
      Default = True
      ModalResult = 1
      TabOrder = 1
    end
  end
  object mTexto: TcxMemo [1]
    Left = 12
    Top = 12
    Anchors = [akLeft, akTop, akRight, akBottom]
    Properties.ReadOnly = True
    Properties.ScrollBars = ssVertical
    Properties.WordWrap = True
    TabOrder = 0
    Height = 254
    Width = 626
  end
end
