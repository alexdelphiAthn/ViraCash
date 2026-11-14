inherited frmModalCambioIva: TfrmModalCambioIva
  BorderStyle = bsDialog
  Caption = 'Cambio de IVA'
  ClientHeight = 285
  ClientWidth = 400
  Position = poScreenCenter
  StyleElements = [seFont, seClient, seBorder]
  TextHeight = 17
  object pnlPrincipal: TPanel [0]
    Left = 0
    Top = 0
    Width = 400
    Height = 235
    Align = alClient
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 0
    object lblTitulo: TcxLabel
      Left = 20
      Top = 16
      AutoSize = False
      Caption = 'Seleccione el tipo de IVA para el art'#237'culo inmaterial:'
      Style.TextColor = clNavy
      TabOrder = 1
      Transparent = True
      Height = 24
      Width = 360
    end
    object rgTipoIva: TcxRadioGroup
      Left = 20
      Top = 48
      Properties.Columns = 1
      Properties.Items = <
        item
          Caption = 'Normal'
        end
        item
          Caption = 'Reducida'
        end
        item
          Caption = 'S'#250'perreducida'
        end
        item
          Caption = 'Exento'
        end>
      ItemIndex = 0
      TabOrder = 0
      Height = 168
      Width = 360
    end
  end
  object pnlBotones: TPanel [1]
    Left = 0
    Top = 235
    Width = 400
    Height = 50
    Align = alBottom
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 1
    object btnAceptar: TcxButton
      Left = 120
      Top = 8
      Width = 130
      Height = 35
      Action = actAceptar
      Default = True
      TabOrder = 0
    end
    object btnCancelar: TcxButton
      Left = 260
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
    Top = 244
    object actAceptar: TAction
      Caption = 'Aceptar (F12)'
      ShortCut = 123
      OnExecute = actAceptarExecute
    end
    object actCancelar: TAction
      Caption = 'Cancelar (ESC)'
      ShortCut = 27
      OnExecute = actCancelarExecute
    end
  end
end
