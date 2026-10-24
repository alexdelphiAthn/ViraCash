inherited frmModalEntradaCambio: TfrmModalEntradaCambio
  BorderStyle = bsDialog
  Caption = 'Entrada de Cambio (F6)'
  ClientHeight = 230
  ClientWidth = 500
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 19
  object pnlPrincipal: TPanel [0]
    Left = 0
    Top = 0
    Width = 500
    Height = 180
    Align = alClient
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 0
    object lblTitulo: TcxLabel
      Left = 16
      Top = 8
      Caption = 'Introduzca el efectivo que entra en caja'
      Style.TextColor = clNavy
      Style.Font.Size = 10
      Style.Font.Style = [fsBold]
      TabOrder = 6
      Transparent = True
    end
    object lblEmpleadoLbl: TcxLabel
      Left = 16
      Top = 42
      Caption = 'Empleado:'
      TabOrder = 7
      Transparent = True
    end
    object btnEmpleado: TcxButtonEdit
      Left = 100
      Top = 40
      Properties.Buttons = <
        item
          Default = True
          Kind = bkEllipsis
        end>
      Properties.OnButtonClick = btnEmpleadoPropertiesButtonClick
      Properties.OnValidate = btnEmpleadoPropertiesValidate
      TabOrder = 0
      Width = 120
    end
    object lblEmpleadoNombre: TcxLabel
      Left = 230
      Top = 42
      AutoSize = False
      Style.TextColor = clNavy
      Style.Font.Style = [fsBold]
      TabOrder = 8
      Transparent = True
      Height = 21
      Width = 250
    end
    object lblImporteLbl: TcxLabel
      Left = 16
      Top = 80
      Caption = 'Importe:'
      TabOrder = 9
      Transparent = True
    end
    object txtImporte: TcxCurrencyEdit
      Left = 100
      Top = 78
      TabOrder = 1
      Value = 0.000000000000000000
      Width = 140
    end
    object lblConceptoLbl: TcxLabel
      Left = 16
      Top = 118
      Caption = 'Concepto:'
      TabOrder = 10
      Transparent = True
    end
    object txtConcepto: TcxTextEdit
      Left = 100
      Top = 116
      Properties.MaxLength = 100
      TabOrder = 2
      Text = ''
      Width = 380
    end
  end
  object pnlBotones: TPanel [1]
    Left = 0
    Top = 180
    Width = 500
    Height = 50
    Align = alBottom
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 1
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
    Top = 190
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
