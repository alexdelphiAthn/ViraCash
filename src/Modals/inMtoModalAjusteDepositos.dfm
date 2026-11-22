inherited frmModalAjusteDepositos: TfrmModalAjusteDepositos
  BorderStyle = bsDialog
  Caption = 'Cambiar almacén de depósitos abiertos'
  ClientHeight = 446
  ClientWidth = 900
  Position = poOwnerFormCenter
  object lblDesde: TcxLabel
    Left = 16
    Top = 16
    Caption = 'Fecha del movimiento desde'
    TabOrder = 0
  end
  object dteDesde: TcxDateEdit
    Left = 16
    Top = 38
    Properties.OnEditValueChanged = FiltroCambiado
    TabOrder = 1
    Width = 162
  end
  object lblHasta: TcxLabel
    Left = 192
    Top = 16
    Caption = 'Hasta'
    TabOrder = 2
  end
  object dteHasta: TcxDateEdit
    Left = 192
    Top = 38
    Properties.OnEditValueChanged = FiltroCambiado
    TabOrder = 3
    Width = 112
  end
  object lblOrigen: TcxLabel
    Left = 318
    Top = 16
    Caption = 'Almacén de origen'
    TabOrder = 4
  end
  object cboOrigen: TcxComboBox
    Left = 318
    Top = 38
    Properties.DropDownListStyle = lsFixedList
    Properties.OnEditValueChanged = FiltroCambiado
    TabOrder = 5
    Width = 244
  end
  object lblTipo: TcxLabel
    Left = 576
    Top = 16
    Caption = 'Tipo de movimiento'
    TabOrder = 6
  end
  object cboTipo: TcxComboBox
    Left = 576
    Top = 38
    Properties.DropDownListStyle = lsFixedList
    Properties.Items.Strings = (
      'Todos'
      'Entrada original'
      'Entrada por cambio de almacén')
    Properties.OnEditValueChanged = FiltroCambiado
    TabOrder = 7
    Width = 210
  end
  object btnBuscar: TcxButton
    Left = 798
    Top = 36
    Width = 86
    Height = 27
    Caption = 'Buscar'
    Enabled = False
    TabOrder = 8
    OnClick = BuscarClick
  end
  object chkDepositos: TcxCheckListBox
    Left = 16
    Top = 76
    Width = 868
    Height = 252
    TabOrder = 9
  end
  object lblResultado: TcxLabel
    Left = 16
    Top = 340
    TabOrder = 10
  end
  object btnMarcar: TcxButton
    Left = 753
    Top = 336
    Width = 131
    Height = 27
    Caption = 'Marcar todos'
    Enabled = False
    TabOrder = 11
    OnClick = MarcarClick
  end
  object lblDestino: TcxLabel
    Left = 16
    Top = 373
    Caption = 'Almacén de destino'
    TabOrder = 12
  end
  object cboDestino: TcxComboBox
    Left = 16
    Top = 395
    Properties.DropDownListStyle = lsFixedList
    TabOrder = 13
    Width = 330
  end
  object btnTrasladar: TcxButton
    Left = 615
    Top = 392
    Width = 165
    Height = 30
    Caption = 'Trasladar seleccionados'
    Enabled = False
    TabOrder = 14
    OnClick = TrasladarClick
  end
  object btnCerrar: TcxButton
    Left = 798
    Top = 392
    Width = 86
    Height = 30
    Cancel = True
    Caption = 'Cerrar'
    ModalResult = 2
    TabOrder = 15
  end
end
