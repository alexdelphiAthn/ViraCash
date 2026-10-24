inherited frmMtoModalArtTar: TfrmMtoModalArtTar
  BorderIcons = []
  Caption = 'Seleccionar Tarifas'
  ClientHeight = 184
  ClientWidth = 469
  OnClose = FormClose
  ExplicitWidth = 481
  ExplicitHeight = 222
  TextHeight = 19
  object pnl1: TPanel [0]
    Left = 0
    Top = 143
    Width = 469
    Height = 41
    Align = alBottom
    TabOrder = 1
    ExplicitTop = 142
    ExplicitWidth = 465
    object btnCancelar1: TcxButton
      Left = 10
      Top = 6
      Width = 177
      Height = 25
      Caption = '&Cancelar'
      TabOrder = 0
      OnClick = btnCancelar1Click
    end
    object btnAceptar: TcxButton
      Left = 248
      Top = 6
      Width = 177
      Height = 25
      Caption = '&Aceptar'
      TabOrder = 1
      OnClick = btnAceptarClick
    end
  end
  object lstTarifas: TcxListView [1]
    Left = 0
    Top = 0
    Width = 469
    Height = 143
    Align = alClient
    Checkboxes = True
    Columns = <
      item
        AutoSize = True
        Caption = 'C'#243'digo Tarifa'
      end
      item
        AutoSize = True
        Caption = 'Nombre Tarifa'
      end>
    ReadOnly = True
    TabOrder = 0
    ViewStyle = vsReport
    ExplicitWidth = 465
    ExplicitHeight = 142
  end
  inherited Localizer1: TcxLocalizer
    Left = 232
    Top = 440
  end
end
