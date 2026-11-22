inherited frmModalBajasSinLote: TfrmModalBajasSinLote
  BorderStyle = bsDialog
  Caption = 'Bajas de stock sin lote'
  ClientHeight = 557
  ClientWidth = 896
  Position = poOwnerFormCenter
  object lblAlmacen: TcxLabel
    Left = 16
    Top = 14
    Caption = 'Almacén'
    TabOrder = 0
  end
  object cboAlmacen: TcxComboBox
    Left = 16
    Top = 35
    Properties.DropDownListStyle = lsFixedList
    TabOrder = 1
    Width = 198
  end
  object lblSku: TcxLabel
    Left = 228
    Top = 14
    Caption = 'SKU'
    TabOrder = 2
  end
  object edtSku: TcxTextEdit
    Left = 228
    Top = 35
    Properties.MaxLength = 50
    TabOrder = 3
    Width = 215
  end
  object lblCantidad: TcxLabel
    Left = 457
    Top = 14
    Caption = 'Cantidad'
    TabOrder = 4
  end
  object edtCantidad: TcxTextEdit
    Left = 457
    Top = 35
    TabOrder = 5
    Width = 75
  end
  object lblMotivo: TcxLabel
    Left = 546
    Top = 14
    Caption = 'Motivo'
    TabOrder = 6
  end
  object cboMotivo: TcxComboBox
    Left = 546
    Top = 35
    Properties.DropDownListStyle = lsFixedList
    TabOrder = 7
    Width = 118
  end
  object btnStock: TcxButton
    Left = 677
    Top = 32
    Width = 82
    Height = 28
    Caption = 'Ver stock'
    TabOrder = 8
    OnClick = StockClick
  end
  object btnRegistrar: TcxButton
    Left = 768
    Top = 32
    Width = 112
    Height = 28
    Caption = 'Registrar baja'
    TabOrder = 9
    OnClick = RegistrarClick
  end
  object lblEstado: TcxLabel
    Left = 16
    Top = 66
    Caption = ''
    TabOrder = 10
  end
  object lblHistorial: TcxLabel
    Left = 16
    Top = 100
    Caption = 'Historial de bajas'
    TabOrder = 11
    Style.Font.Style = [fsBold]
    Style.IsFontAssigned = True
  end
  object lblDesde: TcxLabel
    Left = 16
    Top = 126
    Caption = 'Desde'
    TabOrder = 12
  end
  object dteDesde: TcxDateEdit
    Left = 16
    Top = 146
    TabOrder = 13
    Width = 101
  end
  object lblHasta: TcxLabel
    Left = 132
    Top = 126
    Caption = 'Hasta'
    TabOrder = 14
  end
  object dteHasta: TcxDateEdit
    Left = 132
    Top = 146
    TabOrder = 15
    Width = 101
  end
  object lblFiltroAlmacen: TcxLabel
    Left = 248
    Top = 126
    Caption = 'Almacén'
    TabOrder = 16
  end
  object cboFiltroAlmacen: TcxComboBox
    Left = 248
    Top = 146
    Properties.DropDownListStyle = lsFixedList
    Properties.Items.Strings = ('Todos')
    TabOrder = 17
    Width = 214
  end
  object lblFiltroMotivo: TcxLabel
    Left = 477
    Top = 126
    Caption = 'Motivo'
    TabOrder = 18
  end
  object cboFiltroMotivo: TcxComboBox
    Left = 477
    Top = 146
    Properties.DropDownListStyle = lsFixedList
    Properties.Items.Strings = ('Todos')
    TabOrder = 19
    Width = 160
  end
  object btnBuscar: TcxButton
    Left = 651
    Top = 143
    Width = 100
    Height = 28
    Caption = 'Consultar'
    TabOrder = 20
    OnClick = BuscarClick
  end
  object gridBajas: TcxGrid
    Left = 16
    Top = 180
    Width = 864
    Height = 236
    TabOrder = 21
    object tvBajas: TcxGridTableView
      OptionsData.Editing = False
      OptionsData.Inserting = False
      OptionsData.Deleting = False
      OptionsView.GroupByBox = False
      OptionsView.ColumnAutoWidth = True
      object colFecha: TcxGridColumn
        Caption = 'Fecha'
        DataBinding.ValueType = 'DateTime'
        Width = 133
      end
      object colAlmacen: TcxGridColumn
        Caption = 'Almacén'
        Width = 80
      end
      object colSku: TcxGridColumn
        Caption = 'SKU'
        Width = 228
      end
      object colMotivo: TcxGridColumn
        Caption = 'Motivo'
        Width = 85
      end
      object colCantidad: TcxGridColumn
        Caption = 'Cantidad'
        DataBinding.ValueType = 'Float'
        Width = 72
      end
      object colUsuario: TcxGridColumn
        Caption = 'Usuario'
        Width = 133
      end
      object colMovimiento: TcxGridColumn
        Caption = 'Movimiento'
        Width = 100
      end
    end
    object nivelBajas: TcxGridLevel
      GridView = tvBajas
    end
  end
  object lblTotales: TcxLabel
    Left = 16
    Top = 422
    Caption = 'Totales por motivo y unidad'
    TabOrder = 22
  end
  object lstTotales: TcxListBox
    Left = 16
    Top = 445
    Width = 620
    Height = 94
    TabOrder = 23
  end
  object btnCerrar: TcxButton
    Left = 786
    Top = 511
    Width = 94
    Height = 28
    Caption = 'Cerrar'
    TabOrder = 24
    Cancel = True
    ModalResult = 2
  end
end
