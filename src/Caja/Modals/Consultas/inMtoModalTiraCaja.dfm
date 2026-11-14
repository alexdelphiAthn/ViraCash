inherited frmModalTiraCaja: TfrmModalTiraCaja
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Tira de Caja'
  ClientHeight = 404
  ClientWidth = 470
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = 'Source Sans 3'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 19
  object lblTitulo: TcxLabel
    Left = 20
    Top = 12
    Caption = 'Tira de Caja'
    Style.Font.Charset = DEFAULT_CHARSET
    Style.Font.Color = clWindowText
    Style.Font.Height = -19
    Style.Font.Name = 'Source Sans 3'
    Style.Font.Style = [fsBold]
    Style.IsFontAssigned = True
    Transparent = True
  end
  object lblSerie: TcxLabel
    Left = 20
    Top = 48
    Caption = 'Serie de Factura Simplificada:'
    Transparent = True
  end
  object ccbSerie: TcxCheckComboBox
    Left = 20
    Top = 72
    Properties.EditValueFormat = cvfStatesString
    Properties.EmptySelectionText = '(todas las series)'
    TabOrder = 0
    Width = 430
  end
  object lblAgrupamiento: TcxLabel
    Left = 20
    Top = 110
    Caption = 'Agrupamiento:'
    Transparent = True
  end
  object cbAgrupamiento: TcxComboBox
    Left = 20
    Top = 134
    Properties.DropDownListStyle = lsFixedList
    TabOrder = 1
    Width = 430
  end
  object chkQR: TcxCheckBox
    Left = 20
    Top = 178
    Caption = 'Imprimir QR Verifactu'
    TabOrder = 2
    Transparent = True
    Width = 430
  end
  object chkTraspasos: TcxCheckBox
    Left = 20
    Top = 208
    Caption = 'Incluir traspasos salientes (origen)'
    TabOrder = 3
    Transparent = True
    Width = 430
  end
  object chkIngresos: TcxCheckBox
    Left = 20
    Top = 236
    Caption = 'Incluir ingresos por caja'
    TabOrder = 4
    Transparent = True
    Width = 430
  end
  object chkGastos: TcxCheckBox
    Left = 20
    Top = 264
    Caption = 'Incluir gastos por caja'
    TabOrder = 5
    Transparent = True
    Width = 430
  end
  object chkCredito: TcxCheckBox
    Left = 20
    Top = 292
    Caption = 'Incluir ventas a crédito (depósitos)'
    TabOrder = 6
    Transparent = True
    Width = 430
  end
  object btnImprimir: TcxButton
    Left = 12
    Top = 344
    Width = 140
    Height = 40
    Caption = 'Imprimir'
    Default = True
    ModalResult = 1
    TabOrder = 7
  end
  object btnExcel: TcxButton
    Left = 162
    Top = 344
    Width = 140
    Height = 40
    Caption = 'Ver Excel'
    ModalResult = 6
    TabOrder = 8
  end
  object btnCancelar: TcxButton
    Left = 312
    Top = 344
    Width = 145
    Height = 40
    Cancel = True
    Caption = 'Cancelar (ESC)'
    ModalResult = 2
    TabOrder = 9
  end
end
