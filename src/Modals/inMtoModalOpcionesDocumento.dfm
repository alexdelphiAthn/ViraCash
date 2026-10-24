inherited frmModalOpcionesDocumento: TfrmModalOpcionesDocumento
  Caption = 'Crear documento'
  ClientHeight = 430
  ClientWidth = 520
  Position = poScreenCenter
  TextHeight = 19
  object lblEmpresa: TcxLabel [0]
    Left = 24
    Top = 27
    Caption = 'Empresa:'
    Transparent = True
  end
  object cbbEmpresa: TcxComboBox [1]
    Left = 180
    Top = 24
    Properties.DropDownListStyle = lsFixedList
    Properties.DropDownRows = 12
    Properties.OnEditValueChanged = cbbEmpresaPropertiesEditValueChanged
    TabOrder = 0
    Width = 316
  end
  object lblAlmacen: TcxLabel [2]
    Left = 24
    Top = 67
    Caption = 'Almacén:'
    Transparent = True
  end
  object cbbAlmacen: TcxComboBox [3]
    Left = 180
    Top = 64
    Properties.DropDownListStyle = lsFixedList
    Properties.DropDownRows = 12
    Properties.OnEditValueChanged = cbbAlmacenPropertiesEditValueChanged
    TabOrder = 1
    Width = 316
  end
  object lblTipoDocumento: TcxLabel [4]
    Left = 24
    Top = 107
    Caption = 'Documento:'
    Transparent = True
  end
  object cbbTipoDocumento: TcxComboBox [5]
    Left = 180
    Top = 104
    Properties.DropDownListStyle = lsFixedList
    Properties.OnEditValueChanged = cbbTipoDocumentoPropertiesEditValueChanged
    TabOrder = 2
    Width = 316
  end
  object lblSerie: TcxLabel [6]
    Left = 24
    Top = 147
    Caption = 'Serie:'
    Transparent = True
  end
  object cbbSerie: TcxComboBox [7]
    Left = 180
    Top = 144
    Properties.CharCase = ecUpperCase
    Properties.DropDownListStyle = lsEditList
    Properties.MaxLength = 12
    TabOrder = 3
    Width = 140
  end
  object lblNumero: TcxLabel [8]
    Left = 24
    Top = 187
    Caption = 'Número:'
    Transparent = True
  end
  object chkNumeroAutomatico: TcxCheckBox [9]
    Left = 180
    Top = 185
    Caption = 'Automático'
    Properties.OnEditValueChanged = chkNumeroAutomaticoPropertiesEditValueChanged
    State = cbsChecked
    TabOrder = 4
    Transparent = True
    Width = 140
  end
  object txtNumero: TcxTextEdit [10]
    Left = 336
    Top = 184
    Enabled = False
    Properties.MaxLength = 20
    TabOrder = 5
    Width = 160
  end
  object lblFecha: TcxLabel [11]
    Left = 24
    Top = 227
    Caption = 'Fecha:'
    Transparent = True
  end
  object dteFecha: TcxDateEdit [12]
    Left = 180
    Top = 224
    TabOrder = 6
    Width = 140
  end
  object lblHora: TcxLabel [13]
    Left = 24
    Top = 247
    Caption = 'Hora:'
    Transparent = True
  end
  object tmeHora: TcxTimeEdit [14]
    Left = 180
    Top = 244
    Properties.TimeFormat = tfHourMin
    TabOrder = 7
    Width = 100
  end
  object lblFormaPago: TcxLabel [15]
    Left = 24
    Top = 267
    Caption = 'Forma de pago:'
    Transparent = True
  end
  object cbbFormaPago: TcxComboBox [16]
    Left = 180
    Top = 264
    Properties.DropDownListStyle = lsFixedList
    Properties.DropDownRows = 12
    TabOrder = 8
    Width = 316
  end
  object chkMueveStock: TcxCheckBox [17]
    Left = 180
    Top = 305
    Caption = 'Genera movimientos de stock'
    State = cbsChecked
    TabOrder = 9
    Transparent = True
    Width = 316
  end
  object btnCancelar: TcxButton [18]
    Left = 50
    Top = 360
    Width = 190
    Height = 40
    Cancel = True
    Caption = '&Cancelar (ESC)'
    TabOrder = 11
    OnClick = btnCancelarClick
  end
  object btnAceptar: TcxButton [19]
    Left = 280
    Top = 360
    Width = 190
    Height = 40
    Caption = '&Aceptar (F12)'
    Default = True
    TabOrder = 10
    OnClick = btnAceptarClick
  end
end
