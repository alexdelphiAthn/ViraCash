inherited frmModalDescargaTraduccion: TfrmModalDescargaTraduccion
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'Descargar traducción'
  ClientHeight = 168
  ClientWidth = 560
  Position = poOwnerFormCenter
  OnCloseQuery = FormCloseQuery
  OnShow = FormShow
  TextHeight = 17
  object lblTitulo: TcxLabel [0]
    Left = 24
    Top = 20
    AutoSize = False
    Caption = 'Preparando la traducción seleccionada'
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
  object prgDescarga: TcxProgressBar [2]
    Left = 24
    Top = 112
    Properties.Max = 100.000000000000000000
    Properties.ShowTextStyle = cxtsText
    TabOrder = 2
    Height = 28
    Width = 512
  end
end
