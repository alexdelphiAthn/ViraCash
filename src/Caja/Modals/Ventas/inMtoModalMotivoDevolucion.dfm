inherited frmModalMotivoDevolucion: TfrmModalMotivoDevolucion
  BorderStyle = bsDialog
  Caption = 'Motivo de la devoluci'#243'n'
  ClientHeight = 170
  ClientWidth = 480
  Position = poScreenCenter
  StyleElements = [seFont, seClient, seBorder]
  TextHeight = 17
  object pnlPrincipal: TPanel [0]
    Left = 0
    Top = 0
    Width = 480
    Height = 120
    Align = alClient
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 0
    object lblTitulo: TcxLabel
      Left = 16
      Top = 12
      Caption = 'Indique el motivo de la devoluci'#243'n'
      Style.TextColor = clNavy
      TabOrder = 1
      Transparent = True
    end
    object lblMotivoLbl: TcxLabel
      Left = 16
      Top = 52
      Caption = 'Motivo:'
      TabOrder = 2
      Transparent = True
    end
    object cbbMotivo: TcxComboBox
      Left = 90
      Top = 50
      Properties.DropDownListStyle = lsEditList
      Properties.Items.Strings = (
        'Talla incorrecta'
        'Art'#237'culo defectuoso'
        'No convence'
        'Cambio por otro art'#237'culo'
        'Otro')
      Properties.MaxLength = 50
      TabOrder = 0
      Width = 360
    end
  end
  object pnlBotones: TPanel [1]
    Left = 0
    Top = 120
    Width = 480
    Height = 50
    Align = alBottom
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 1
    object btnAceptar: TcxButton
      Left = 150
      Top = 8
      Width = 130
      Height = 35
      Action = actAceptar
      Default = True
      TabOrder = 0
    end
    object btnCancelar: TcxButton
      Left = 290
      Top = 8
      Width = 130
      Height = 35
      Action = actCancelar
      Cancel = True
      TabOrder = 1
    end
  end
  object alAcciones: TActionList
    Left = 16
    Top = 128
    object actAceptar: TAction
      Caption = 'Aceptar (F12)'
      ShortCut = 123
      OnExecute = actAceptarExecute
    end
    object actCancelar: TAction
      Caption = 'Cancelar (ESC)'
      OnExecute = actCancelarExecute
    end
  end
end
