object FormConfigEditor: TFormConfigEditor
  Left = 0
  Top = 0
  BorderStyle = bsSizeable
  Caption = 'Editar configuración del normalizador'
  ClientHeight = 521
  ClientWidth = 784
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = 'Source Sans 3'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 15
  object PageControl: TPageControl
    Left = 0
    Top = 0
    Width = 784
    Height = 432
    ActivePage = tabSuffixes
    Align = alClient
    TabOrder = 0
    object tabSuffixes: TTabSheet
      Caption = 'Sufijos por tabla'
      object GridSuffixes: TStringGrid
        Left = 0
        Top = 0
        Width = 776
        Height = 402
        Align = alClient
        ColCount = 2
        DefaultRowHeight = 18
        FixedCols = 0
        RowCount = 2
        TabOrder = 0
      end
    end
    object tabAudit: TTabSheet
      Caption = 'Auditoría'
      ImageIndex = 1
      object GridAudit: TStringGrid
        Left = 0
        Top = 0
        Width = 776
        Height = 402
        Align = alClient
        ColCount = 2
        DefaultRowHeight = 18
        FixedCols = 0
        RowCount = 2
        TabOrder = 0
      end
    end
    object tabAbbrev: TTabSheet
      Caption = 'Abreviaturas'
      ImageIndex = 2
      object GridAbbrev: TStringGrid
        Left = 0
        Top = 0
        Width = 776
        Height = 402
        Align = alClient
        ColCount = 2
        DefaultRowHeight = 18
        FixedCols = 0
        RowCount = 2
        TabOrder = 0
      end
    end
    object tabExceptions: TTabSheet
      Caption = 'Excepciones'
      ImageIndex = 3
      object GridExceptions: TStringGrid
        Left = 0
        Top = 0
        Width = 776
        Height = 402
        Align = alClient
        ColCount = 3
        DefaultRowHeight = 18
        FixedCols = 0
        RowCount = 2
        TabOrder = 0
      end
    end
  end
  object PanelButtons: TPanel
    Left = 0
    Top = 432
    Width = 784
    Height = 89
    Align = alBottom
    BevelOuter = bvNone
    Padding.Left = 8
    Padding.Top = 8
    Padding.Right = 8
    Padding.Bottom = 8
    TabOrder = 1
    object lblHelp: TLabel
      Left = 8
      Top = 12
      Width = 750
      Height = 30
      AutoSize = False
      Caption =
        'Para abreviaturas: el "patrón" se aplica como palabra completa, ' +
        'no parte de un token mayor (entre _ o entre límites de cadena).' +
        ' Para excepciones: la columna se reescribe exactamente como pongas ' +
        'sin pasar por las demás reglas.'
      WordWrap = True
    end
    object btnAddRow: TButton
      Left = 8
      Top = 50
      Width = 120
      Height = 25
      Caption = 'Añadir fila'
      TabOrder = 0
      OnClick = btnAddRowClick
    end
    object btnDeleteRow: TButton
      Left = 134
      Top = 50
      Width = 120
      Height = 25
      Caption = 'Borrar fila'
      TabOrder = 1
      OnClick = btnDeleteRowClick
    end
    object btnReset: TButton
      Left = 260
      Top = 50
      Width = 130
      Height = 25
      Caption = 'Restablecer defectos'
      TabOrder = 2
      OnClick = btnResetClick
    end
    object btnOK: TButton
      Left = 568
      Top = 50
      Width = 95
      Height = 25
      Caption = 'Aceptar'
      Default = True
      ModalResult = 1
      TabOrder = 3
      OnClick = btnOKClick
    end
    object btnCancel: TButton
      Left = 669
      Top = 50
      Width = 95
      Height = 25
      Cancel = True
      Caption = 'Cancelar'
      ModalResult = 2
      TabOrder = 4
      OnClick = btnCancelClick
    end
  end
end
