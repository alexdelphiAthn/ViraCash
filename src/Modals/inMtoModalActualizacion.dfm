inherited frmModalActualizacion: TfrmModalActualizacion
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Comprobar actualizaciones'
  ClientHeight = 216
  ClientWidth = 560
  Position = poOwnerFormCenter
  OnCloseQuery = FormCloseQuery
  OnShow = FormShow
  TextHeight = 17
  object lblTitulo: TcxLabel [0]
    Left = 24
    Top = 20
    AutoSize = False
    Caption = 'Comprobar actualizaciones'
    ParentFont = False
    Style.Font.Charset = DEFAULT_CHARSET
    Style.Font.Color = clWindowText
    Style.Font.Height = -15
    Style.Font.Name = 'Segoe UI'
    Style.Font.Style = [fsBold]
    Style.IsFontAssigned = True
    Transparent = True
    Height = 24
    Width = 512
  end
  object lblEstado: TcxLabel [1]
    Left = 24
    Top = 56
    AutoSize = False
    Caption = 'Iniciando...'
    Properties.WordWrap = True
    Transparent = True
    Height = 42
    Width = 512
  end
  object prgProceso: TcxProgressBar [2]
    Left = 24
    Top = 112
    Properties.Max = 100.000000000000000000
    Properties.ShowTextStyle = cxtsText
    TabOrder = 2
    Height = 28
    Width = 512
  end
  object btnReintentar: TcxButton [3]
    Left = 24
    Top = 164
    Width = 100
    Height = 32
    Caption = 'Reintentar'
    TabOrder = 3
    Visible = False
    OnClick = btnReintentarClick
  end
  object btnDetalle: TcxButton [4]
    Left = 328
    Top = 164
    Width = 100
    Height = 32
    Caption = 'Ver detalle'
    TabOrder = 5
    Visible = False
    OnClick = btnDetalleClick
  end
  object btnCerrar: TcxButton [5]
    Left = 436
    Top = 164
    Width = 100
    Height = 32
    Caption = 'Cerrar'
    ModalResult = 2
    TabOrder = 6
    Visible = False
  end
  object btnCompararModelo: TcxButton [6]
    Left = 132
    Top = 164
    Width = 188
    Height = 32
    Caption = 'Comparar con modelo'
    TabOrder = 4
    Visible = False
    OnClick = btnCompararModeloClick
  end
end
