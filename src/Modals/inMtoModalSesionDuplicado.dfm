inherited frmModalSesionDuplicado: TfrmModalSesionDuplicado
  Caption = 'C'#243'digo de art'#237'culo duplicado'
  ClientHeight = 380
  ClientWidth = 580
  StyleElements = [seFont, seClient, seBorder]
  OnClose = FormClose
  OnShow = FormShow
  ExplicitWidth = 580
  ExplicitHeight = 380
  TextHeight = 19
  object pnlBody: TPanel [0]
    Left = 0
    Top = 0
    Width = 580
    Height = 320
    Align = alClient
    TabOrder = 0
    object lblTitulo: TcxLabel
      Left = 16
      Top = 16
      Caption = 'El c'#243'digo de art'#237'culo ya existe en el cat'#225'logo'
      Style.Font.Style = [fsBold]
      Style.IsFontAssigned = True
      AutoSize = False
      Properties.WordWrap = True
      Height = 44
      Width = 540
      Transparent = True
    end
    object lblCodigoExistente: TcxLabel
      Left = 16
      Top = 66
      Caption = 'C'#243'digo existente:'
      Transparent = True
    end
    object lblDescripcionExistente: TcxLabel
      Left = 16
      Top = 92
      Caption = ''
      Style.TextColor = clGrayText
      Style.IsFontAssigned = True
      AutoSize = False
      Properties.WordWrap = True
      Height = 32
      Width = 540
      Transparent = True
    end
    object rgAccion: TcxRadioGroup
      Left = 16
      Top = 132
      Caption = ' Acci'#243'n '
      Properties.Items = <
        item
          Caption = 'Reusar el art'#237'culo existente (no se crear'#225' uno nuevo)'
          Value = 'REUSAR'
        end
        item
          Caption = 'Renombrar el c'#243'digo en esta sesi'#243'n'
          Value = 'RENOMBRAR'
        end>
      Properties.OnEditValueChanged = rgAccionPropertiesEditValueChanged
      ItemIndex = 0
      TabOrder = 0
      Height = 100
      Width = 540
    end
    object txtCodigo: TcxTextEdit
      Left = 16
      Top = 252
      Properties.MaxLength = 20
      TabOrder = 1
      Width = 200
    end
  end
  object pnlButton: TPanel [1]
    Left = 0
    Top = 320
    Width = 580
    Height = 60
    Align = alBottom
    TabOrder = 1
    object btnCancelar: TcxButton
      Left = 40
      Top = 12
      Width = 180
      Height = 38
      Cancel = True
      Caption = '&Cancelar (ESC)'
      TabOrder = 0
      OnClick = btnCancelarClick
    end
    object btnAceptar: TcxButton
      Left = 360
      Top = 12
      Width = 180
      Height = 38
      Caption = '&Aceptar (F12)'
      Default = True
      TabOrder = 1
      OnClick = btnAceptarClick
    end
  end
  object ActionList1: TActionList
    Left = 480
    Top = 8
    object actAceptar: TAction
      Caption = 'Aceptar'
      ShortCut = 123
      OnExecute = actAceptarExecute
    end
    object actCancelar: TAction
      Caption = 'Cancelar'
      ShortCut = 27
      OnExecute = actCancelarExecute
    end
  end
end
