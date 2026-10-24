inherited frmModalCargarEfectosRemesa: TfrmModalCargarEfectosRemesa
  Caption = 'Cargar efectos en remesa'
  ClientHeight = 580
  ClientWidth = 760
  StyleElements = [seFont, seClient, seBorder]
  KeyPreview = True
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  ExplicitWidth = 760
  ExplicitHeight = 580
  TextHeight = 19
  object pnlTop: TPanel [0]
    Left = 0
    Top = 0
    Width = 760
    Height = 184
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblEmpresa: TcxLabel
      Left = 16
      Top = 16
      Caption = 'Empresa'
      Transparent = True
    end
    object btnEmpresa: TcxButtonEdit
      Left = 90
      Top = 14
      Properties.Buttons = <
        item
          Default = True
          Kind = bkEllipsis
        end>
      Properties.CharCase = ecUpperCase
      Properties.MaxLength = 8
      Properties.OnButtonClick = btnEmpresaPropertiesButtonClick
      TabOrder = 0
      Width = 110
    end
    object lblHasta: TcxLabel
      Left = 224
      Top = 16
      Caption = 'Vto. hasta'
      Transparent = True
    end
    object dteHasta: TcxDateEdit
      Left = 380
      Top = 14
      TabOrder = 1
      Width = 110
    end
    object btnBuscar: TcxButton
      Left = 500
      Top = 10
      Width = 130
      Height = 30
      Caption = 'Buscar efectos'
      TabOrder = 2
      OnClick = btnBuscarClick
    end
    object rgModo: TcxRadioGroup
      Left = 16
      Top = 76
      Caption = ' Modo '
      Properties.Items = <
        item
          Caption = 'Crear remesa nueva'
        end
        item
          Caption = 'Anadir a una remesa existente'
        end>
      Properties.OnEditValueChanged = rgModoPropertiesEditValueChanged
      ItemIndex = 0
      TabOrder = 3
      Height = 64
      Width = 540
    end
    object lblRemExistente: TcxLabel
      Left = 16
      Top = 150
      Caption = 'Remesa existente'
      Transparent = True
    end
    object cbbRemExistente: TcxComboBox
      Left = 170
      Top = 148
      Properties.DropDownListStyle = lsFixedList
      TabOrder = 4
      Width = 400
    end
  end
  object pnlGrid: TPanel [1]
    Left = 0
    Top = 184
    Width = 760
    Height = 336
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object cxgrdEfe: TcxGrid
      Left = 0
      Top = 0
      Width = 760
      Height = 336
      Align = alClient
      TabOrder = 0
      object tvEfe: TcxGridDBTableView
        OptionsData.Deleting = False
        OptionsData.Editing = False
        OptionsData.Inserting = False
        OptionsSelection.MultiSelect = True
        OptionsView.GroupByBox = False
        object colSerieFac: TcxGridDBColumn
          Caption = 'Serie fra'
          DataBinding.FieldName = 'SERIE_FAC_EFECTO'
          Width = 70
        end
        object colNumFac: TcxGridDBColumn
          Caption = 'Nro fra'
          DataBinding.FieldName = 'NUMERO_FAC_EFECTO'
          Width = 80
        end
        object colNumEfe: TcxGridDBColumn
          Caption = 'Efecto'
          DataBinding.FieldName = 'NUMERO_EFECTO'
          Width = 55
        end
        object colTercero: TcxGridDBColumn
          Caption = 'Proveedor'
          DataBinding.FieldName = 'TERCERO_EFECTO'
          Width = 200
        end
        object colVto: TcxGridDBColumn
          Caption = 'Vencimiento'
          DataBinding.FieldName = 'FECHA_VENCIMIENTO_EFECTO'
          Width = 110
        end
        object colPend: TcxGridDBColumn
          Caption = 'Pendiente'
          DataBinding.FieldName = 'IMPORTE_PENDIENTE_EFECTO'
          PropertiesClassName = 'TcxCurrencyEditProperties'
          Properties.DisplayFormat = '#,##0.00 '#8364
          Width = 110
        end
        object colEstado: TcxGridDBColumn
          Caption = 'Estado'
          DataBinding.FieldName = 'ESTADO_EFECTO'
          Width = 100
        end
      end
      object lvlEfe: TcxGridLevel
        GridView = tvEfe
      end
    end
  end
  object pnlButton: TPanel [2]
    Left = 0
    Top = 520
    Width = 760
    Height = 60
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object btnSalir: TcxButton
      Left = 40
      Top = 12
      Width = 170
      Height = 38
      Cancel = True
      Caption = '&Salir'
      TabOrder = 0
      OnClick = btnSalirClick
    end
    object btnRemesar: TcxButton
      Left = 510
      Top = 12
      Width = 210
      Height = 38
      Caption = '&Cargar en remesa'
      Default = True
      TabOrder = 1
      OnClick = btnRemesarClick
    end
  end
end
