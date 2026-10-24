inherited frmModalMovimientosSku: TfrmModalMovimientosSku
  BorderStyle = bsSizeable
  Caption = 'Movimientos de almac'#233'n'
  ClientHeight = 520
  ClientWidth = 1100
  Constraints.MinHeight = 380
  Constraints.MinWidth = 800
  Position = poScreenCenter
  OnCreate = FormCreate
  OnShow = FormShow
  TextHeight = 17
  object pnlSuperior: TPanel [0]
    Left = 0
    Top = 0
    Width = 1100
    Height = 62
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblTitulo: TcxLabel
      Left = 16
      Top = 8
      Caption = 'Movimientos de almac'#233'n'
      Style.Font.Charset = DEFAULT_CHARSET
      Style.Font.Color = clWindowText
      Style.Font.Height = -19
      Style.Font.Name = 'Source Sans 3'
      Style.Font.Style = [fsBold]
      Style.IsFontAssigned = True
      TabOrder = 0
      Transparent = True
    end
    object lblAyuda: TcxLabel
      Left = 16
      Top = 36
      Caption = 'E = entrada   S = salida'
      TabOrder = 1
      Transparent = True
    end
  end
  object cxgrdMovimientos: TcxGrid [1]
    Left = 0
    Top = 62
    Width = 1100
    Height = 402
    Align = alClient
    TabOrder = 1
    object tvMovimientos: TcxGridDBTableView
      DataController.DataSource = dsMovimientos
      OptionsBehavior.FocusCellOnTab = True
      OptionsData.Deleting = False
      OptionsData.DeletingConfirmation = False
      OptionsData.Editing = False
      OptionsData.Inserting = False
      OptionsSelection.CellSelect = False
      OptionsView.GroupByBox = False
      OptionsView.Indicator = True
      object tvMovimientosNUMERO_MOV: TcxGridDBColumn
        Caption = 'Movimiento'
        DataBinding.FieldName = 'NUMERO_MOV'
        Options.Editing = False
        Width = 110
      end
      object tvMovimientosFECHA_MOV: TcxGridDBColumn
        Caption = 'Fecha'
        DataBinding.FieldName = 'FECHA_MOV'
        PropertiesClassName = 'TcxDateEditProperties'
        Properties.DisplayFormat = 'dd/mm/yyyy hh:nn'
        Options.Editing = False
        Width = 140
      end
      object tvMovimientosTIPO_DOC_MOV: TcxGridDBColumn
        Caption = 'Tipo doc.'
        DataBinding.FieldName = 'TIPO_DOC_MOV'
        Options.Editing = False
        Width = 75
      end
      object tvMovimientosSERIE_DOC_MOV: TcxGridDBColumn
        Caption = 'Serie'
        DataBinding.FieldName = 'SERIE_DOC_MOV'
        Options.Editing = False
        Width = 110
      end
      object tvMovimientosNUMERO_DOC_MOV: TcxGridDBColumn
        Caption = 'Documento'
        DataBinding.FieldName = 'NUMERO_DOC_MOV'
        Options.Editing = False
        Width = 110
      end
      object tvMovimientosLINEA_MOV: TcxGridDBColumn
        Caption = 'L'#237'nea'
        DataBinding.FieldName = 'LINEA_MOV'
        Options.Editing = False
        Width = 65
      end
      object tvMovimientosCODIGO_ALM_MOV: TcxGridDBColumn
        Caption = 'Almac'#233'n'
        DataBinding.FieldName = 'CODIGO_ALM_MOV'
        Options.Editing = False
        Width = 90
      end
      object tvMovimientosCODIGO_ALM_CONTRA_MOV: TcxGridDBColumn
        Caption = 'Almac'#233'n contra'
        DataBinding.FieldName = 'CODIGO_ALM_CONTRA_MOV'
        Options.Editing = False
        Width = 110
      end
      object tvMovimientosTIPO_MOV: TcxGridDBColumn
        Caption = 'E/S'
        DataBinding.FieldName = 'TIPO_MOV'
        Options.Editing = False
        Width = 55
      end
      object tvMovimientosCANTIDAD_MOV: TcxGridDBColumn
        Caption = 'Cantidad'
        DataBinding.FieldName = 'CANTIDAD_MOV'
        PropertiesClassName = 'TcxCurrencyEditProperties'
        Properties.DisplayFormat = '#,##0.###;-#,##0.###;'
        HeaderAlignmentHorz = taRightJustify
        Options.Editing = False
        Width = 100
      end
      object tvMovimientosESACTIVO_MOV: TcxGridDBColumn
        Caption = 'Activo'
        DataBinding.FieldName = 'ESACTIVO_MOV'
        PropertiesClassName = 'TcxCheckBoxProperties'
        Properties.ValueChecked = 'S'
        Properties.ValueUnchecked = 'N'
        Options.Editing = False
        Width = 65
      end
    end
    object cxgrdlvlMovimientos: TcxGridLevel
      GridView = tvMovimientos
    end
  end
  object pnlBotones: TPanel [2]
    Left = 0
    Top = 464
    Width = 1100
    Height = 56
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object lblResultado: TcxLabel
      Left = 16
      Top = 18
      Caption = '0 movimientos'
      TabOrder = 3
      Transparent = True
    end
    object btnReconstruirStock: TcxButton
      Left = 492
      Top = 10
      Width = 180
      Height = 36
      Anchors = [akTop, akRight]
      Caption = 'Reconstruir Stock'
      TabOrder = 0
      OnClick = btnReconstruirStockClick
    end
    object btnIrMovimientos: TcxButton
      Left = 684
      Top = 10
      Width = 180
      Height = 36
      Anchors = [akTop, akRight]
      Caption = 'Ir a Movimientos'
      Enabled = False
      TabOrder = 1
      OnClick = btnIrMovimientosClick
    end
    object btnCerrar: TcxButton
      Left = 876
      Top = 10
      Width = 208
      Height = 36
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Cerrar (ESC)'
      TabOrder = 2
      OnClick = btnCerrarClick
    end
  end
  object dsMovimientos: TDataSource
    OnDataChange = dsMovimientosDataChange
    Left = 72
    Top = 112
  end
end
