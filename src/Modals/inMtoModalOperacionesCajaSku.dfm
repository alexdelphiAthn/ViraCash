inherited frmModalOperacionesCajaSku: TfrmModalOperacionesCajaSku
  BorderStyle = bsSizeable
  Caption = 'Operaciones de caja'
  ClientHeight = 520
  ClientWidth = 1040
  Constraints.MinHeight = 380
  Constraints.MinWidth = 800
  Position = poScreenCenter
  OnCreate = FormCreate
  OnShow = FormShow
  TextHeight = 17
  object pnlSuperior: TPanel [0]
    Left = 0
    Top = 0
    Width = 1040
    Height = 62
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblTitulo: TcxLabel
      Left = 16
      Top = 8
      Caption = 'Operaciones de caja'
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
      Caption = 'DE = pr'#233'stamo   DV = devoluci'#243'n   VE = venta'
      TabOrder = 1
      Transparent = True
    end
  end
  object cxgrdOperaciones: TcxGrid [1]
    Left = 0
    Top = 62
    Width = 1040
    Height = 402
    Align = alClient
    TabOrder = 1
    object tvOperaciones: TcxGridDBTableView
      DataController.DataSource = dsOperaciones
      OptionsBehavior.FocusCellOnTab = True
      OptionsData.Deleting = False
      OptionsData.DeletingConfirmation = False
      OptionsData.Editing = False
      OptionsData.Inserting = False
      OptionsSelection.CellSelect = False
      OptionsView.GroupByBox = False
      OptionsView.Indicator = True
      object tvOperacionesTIPO_OPERACION: TcxGridDBColumn
        Caption = 'Tipo'
        DataBinding.FieldName = 'TIPO_OPERACION'
        Options.Editing = False
        Width = 55
      end
      object tvOperacionesNUMERO_OPERACION: TcxGridDBColumn
        Caption = 'N'#250'mero operaci'#243'n'
        DataBinding.FieldName = 'NUMERO_OPERACION'
        Options.Editing = False
        Width = 125
      end
      object tvOperacionesFECHA_OPERACION: TcxGridDBColumn
        Caption = 'Fecha'
        DataBinding.FieldName = 'FECHA_OPERACION'
        PropertiesClassName = 'TcxDateEditProperties'
        Properties.DisplayFormat = 'dd/mm/yyyy hh:nn'
        Options.Editing = False
        Width = 140
      end
      object tvOperacionesFACTURA: TcxGridDBColumn
        Caption = 'N'#186' factura'
        DataBinding.FieldName = 'FACTURA'
        Options.Editing = False
        Width = 150
      end
      object tvOperacionesDESCRIPCION_ARTICULO: TcxGridDBColumn
        Caption = 'Descripci'#243'n del art'#237'culo'
        DataBinding.FieldName = 'DESCRIPCION_ARTICULO'
        Options.Editing = False
        Width = 310
      end
      object tvOperacionesPRECIO_VENTA: TcxGridDBColumn
        Caption = 'Precio venta'
        DataBinding.FieldName = 'PRECIO_VENTA'
        PropertiesClassName = 'TcxCurrencyEditProperties'
        Properties.DisplayFormat = '#,##0.00 "€";-#,##0.00 "€";'
        HeaderAlignmentHorz = taRightJustify
        Options.Editing = False
        Width = 110
      end
      object tvOperacionesDESCUENTO: TcxGridDBColumn
        Caption = 'Descuento'
        DataBinding.FieldName = 'DESCUENTO'
        PropertiesClassName = 'TcxCurrencyEditProperties'
        Properties.DisplayFormat = '#,##0.## "%";-#,##0.## "%";'
        HeaderAlignmentHorz = taRightJustify
        Options.Editing = False
        Width = 100
      end
    end
    object cxgrdlvlOperaciones: TcxGridLevel
      GridView = tvOperaciones
    end
  end
  object pnlBotones: TPanel [2]
    Left = 0
    Top = 464
    Width = 1040
    Height = 56
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object lblResultado: TcxLabel
      Left = 16
      Top = 18
      Caption = '0 operaciones'
      TabOrder = 3
      Transparent = True
    end
    object btnCerrar: TcxButton
      Left = 864
      Top = 10
      Width = 160
      Height = 36
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Cerrar (ESC)'
      TabOrder = 2
      OnClick = btnCerrarClick
    end
    object btnIrOperacion: TcxButton
      Left = 424
      Top = 10
      Width = 180
      Height = 36
      Anchors = [akTop, akRight]
      Caption = 'Ir a operaci'#243'n'
      Enabled = False
      TabOrder = 0
      OnClick = btnIrOperacionClick
    end
    object btnIrFacturaSimplificada: TcxButton
      Left = 616
      Top = 10
      Width = 236
      Height = 36
      Anchors = [akTop, akRight]
      Caption = 'Ir a factura simplificada'
      Enabled = False
      TabOrder = 1
      OnClick = btnIrFacturaSimplificadaClick
    end
  end
  object dsOperaciones: TDataSource
    OnDataChange = dsOperacionesDataChange
    Left = 72
    Top = 112
  end
end
