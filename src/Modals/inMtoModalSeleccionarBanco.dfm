inherited frmModalSeleccionarBanco: TfrmModalSeleccionarBanco
  Caption = 'Seleccionar banco de la empresa'
  ClientHeight = 420
  ClientWidth = 720
  StyleElements = [seFont, seClient, seBorder]
  OnCreate = FormCreate
  ExplicitWidth = 720
  ExplicitHeight = 420
  TextHeight = 19
  object pnlInfo: TPanel [0]
    Left = 0
    Top = 0
    Width = 720
    Height = 40
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblInfo: TcxLabel
      Left = 16
      Top = 10
      Caption = 'Cuenta de la empresa:'
      Transparent = True
    end
  end
  object pnlGrid: TPanel [1]
    Left = 0
    Top = 40
    Width = 720
    Height = 320
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object cxgrdBancos: TcxGrid
      Left = 0
      Top = 0
      Width = 720
      Height = 320
      Align = alClient
      TabOrder = 0
      object tvBancos: TcxGridDBTableView
        OnDblClick = tvBancosDblClick
        OptionsData.Deleting = False
        OptionsData.Editing = False
        OptionsData.Inserting = False
        OptionsSelection.MultiSelect = False
        OptionsView.GroupByBox = False
        object colNombre: TcxGridDBColumn
          Caption = 'Nombre cuenta'
          DataBinding.FieldName = 'NOMBRE_EMPBAN'
          Width = 150
        end
        object colIban: TcxGridDBColumn
          Caption = 'IBAN'
          DataBinding.FieldName = 'IBAN_EMPBAN'
          Width = 210
        end
        object colBanco: TcxGridDBColumn
          Caption = 'Banco'
          DataBinding.FieldName = 'NOMBRE_BAN_VIEW_EMPBAN'
          Width = 160
        end
        object colCobro: TcxGridDBColumn
          Caption = 'Def. Cobro'
          DataBinding.FieldName = 'ESDEFECTO_COBRO_EMPBAN'
          Width = 70
        end
        object colPago: TcxGridDBColumn
          Caption = 'Def. Pago'
          DataBinding.FieldName = 'ESDEFECTO_PAGO_EMPBAN'
          Width = 70
        end
      end
      object lvlBancos: TcxGridLevel
        GridView = tvBancos
      end
    end
  end
  object pnlButton: TPanel [2]
    Left = 0
    Top = 360
    Width = 720
    Height = 60
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object btnCancelar: TcxButton
      Left = 40
      Top = 12
      Width = 170
      Height = 38
      Cancel = True
      Caption = '&Cancelar'
      TabOrder = 0
      OnClick = btnCancelarClick
    end
    object btnAceptar: TcxButton
      Left = 510
      Top = 12
      Width = 170
      Height = 38
      Caption = '&Aceptar'
      Default = True
      TabOrder = 1
      OnClick = btnAceptarClick
    end
  end
end
