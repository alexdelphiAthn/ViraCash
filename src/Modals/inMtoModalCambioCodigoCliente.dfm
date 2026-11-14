inherited frmModalCambioCodigoCliente: TfrmModalCambioCodigoCliente
  BorderStyle = bsDialog
  Caption = 'Cambio de código de cliente'
  ClientHeight = 540
  ClientWidth = 880
  Position = poMainFormCenter
  OnCreate = FormCreate
  object lblIntroduccion: TcxLabel
    Left = 16
    Top = 12
    AutoSize = False
    Properties.WordWrap = True
    Height = 60
    Width = 848
  end
  object lblOrigen: TcxLabel
    Left = 16
    Top = 78
    Caption = 'Código actual del cliente'
  end
  object lblDestino: TcxLabel
    Left = 238
    Top = 78
    Caption = 'Código nuevo'
  end
  object txtOrigen: TcxTextEdit
    Left = 16
    Top = 104
    Properties.MaxLength = 20
    Properties.OnChange = OrigenChange
    TabOrder = 0
    Width = 202
  end
  object txtDestino: TcxTextEdit
    Left = 238
    Top = 104
    Properties.MaxLength = 20
    TabOrder = 1
    Width = 202
  end
  object btnCambiar: TcxButton
    Left = 462
    Top = 100
    Width = 188
    Height = 34
    Caption = 'Cambiar código'
    TabOrder = 2
    OnClick = CambiarClick
  end
  object btnDuplicados: TcxButton
    Left = 668
    Top = 100
    Width = 196
    Height = 34
    Caption = 'Detectar duplicados'
    TabOrder = 3
    OnClick = DuplicadosClick
  end
  object lblResultado: TcxLabel
    Left = 16
    Top = 146
    AutoSize = False
    Properties.WordWrap = True
    Height = 48
    Width = 848
  end
  object cxgrdDuplicados: TcxGrid
    Left = 16
    Top = 200
    Width = 848
    Height = 280
    TabOrder = 4
    object tvDuplicados: TcxGridTableView
      OptionsData.CancelOnExit = False
      OptionsData.Deleting = False
      OptionsData.Editing = False
      OptionsData.Inserting = False
      OptionsView.ColumnAutoWidth = True
      OptionsView.GroupByBox = False
      object colCodigo: TcxGridColumn
        Caption = 'Código'
        Width = 100
      end
      object colNombre: TcxGridColumn
        Caption = 'Cliente'
        Width = 210
      end
      object colOtroCodigo: TcxGridColumn
        Caption = 'Otro código'
        Width = 100
      end
      object colOtroNombre: TcxGridColumn
        Caption = 'Otra ficha'
        Width = 210
      end
      object colMotivo: TcxGridColumn
        Caption = 'Coincidencia'
        Width = 200
      end
    end
    object lvDuplicados: TcxGridLevel
      GridView = tvDuplicados
    end
  end
  object btnCerrar: TcxButton
    Left = 704
    Top = 496
    Width = 160
    Height = 32
    Cancel = True
    Caption = 'Cerrar'
    TabOrder = 5
    OnClick = CerrarClick
  end
end
