inherited frmModalGastoCaja: TfrmModalGastoCaja
  BorderStyle = bsDialog
  Caption = 'Gastos por Caja / Retiradas (F7)'
  ClientHeight = 348
  ClientWidth = 500
  Position = poScreenCenter
  StyleElements = [seFont, seClient, seBorder]
  ExplicitWidth = 516
  ExplicitHeight = 369
  TextHeight = 17
  object pnlPrincipal: TPanel [0]
    Left = 0
    Top = 0
    Width = 500
    Height = 288
    Align = alClient
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 0
    ExplicitWidth = 498
    ExplicitHeight = 272
    object lblTitulo: TcxLabel
      Left = 16
      Top = 8
      Caption = 'Registrar gasto o retirada de efectivo'
      Style.TextColor = clNavy
      TabOrder = 4
      Transparent = True
    end
    object lblTipoLbl: TcxLabel
      Left = 16
      Top = 36
      Caption = 'Tipo:'
      TabOrder = 5
      Transparent = True
    end
    object rgTipo: TcxRadioGroup
      Left = 16
      Top = 54
      Properties.Columns = 3
      Properties.Items = <
        item
          Caption = 'Pago proveedor'
        end
        item
          Caption = 'Gastos limpieza'
        end
        item
          Caption = 'Retirada banco'
        end
        item
          Caption = 'Retirada encargado'
        end
        item
          Caption = 'Caja fuerte'
        end>
      ItemIndex = 2
      TabOrder = 0
      Height = 72
      Width = 468
    end
    object lblEmpleadoLbl: TcxLabel
      Left = 16
      Top = 140
      Caption = 'Empleado:'
      TabOrder = 6
      Transparent = True
    end
    object btnEmpleado: TcxButtonEdit
      Left = 100
      Top = 138
      Properties.Buttons = <
        item
          Default = True
          Kind = bkEllipsis
        end>
      Properties.OnButtonClick = btnEmpleadoPropertiesButtonClick
      Properties.OnValidate = btnEmpleadoPropertiesValidate
      TabOrder = 1
      Width = 120
    end
    object lblEmpleadoNombre: TcxLabel
      Left = 230
      Top = 140
      AutoSize = False
      Style.TextColor = clNavy
      TabOrder = 7
      Transparent = True
      Height = 21
      Width = 250
    end
    object lblImporteLbl: TcxLabel
      Left = 16
      Top = 178
      Caption = 'Importe:'
      TabOrder = 8
      Transparent = True
    end
    object txtImporte: TcxCurrencyEdit
      Left = 100
      Top = 176
      EditValue = 0.000000000000000000
      TabOrder = 2
      Width = 140
    end
    object lblConceptoLbl: TcxLabel
      Left = 16
      Top = 216
      Caption = 'Concepto:'
      TabOrder = 9
      Transparent = True
    end
    object txtConcepto: TcxTextEdit
      Left = 100
      Top = 214
      Properties.MaxLength = 100
      TabOrder = 3
      Width = 380
    end
  end
  object pnlBotones: TPanel [1]
    Left = 0
    Top = 298
    Width = 500
    Height = 60
    Align = alBottom
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 1
    ExplicitTop = 272
    ExplicitWidth = 498
    object btnAceptar: TcxButton
      Left = 170
      Top = 8
      Width = 130
      Height = 35
      Action = actAceptar
      Default = True
      TabOrder = 0
    end
    object btnCancelar: TcxButton
      Left = 310
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
    Top = 290
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
