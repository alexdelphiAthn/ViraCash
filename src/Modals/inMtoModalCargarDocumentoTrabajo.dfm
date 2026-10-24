inherited frmModalCargarDocumentoTrabajo: TfrmModalCargarDocumentoTrabajo
  Caption = 'Cargar desde documento'
  ClientHeight = 680
  ClientWidth = 1050
  Position = poMainFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  ExplicitWidth = 1050
  ExplicitHeight = 680
  TextHeight = 19
  object pnlFiltros: TPanel [0]
    Left = 0
    Top = 0
    Width = 1050
    Height = 92
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblEmpresa: TcxLabel
      Left = 16
      Top = 14
      Caption = 'Empresa'
      Transparent = True
    end
    object txtEmpresa: TcxTextEdit
      Left = 84
      Top = 12
      Properties.ReadOnly = True
      Style.Color = clBtnFace
      TabOrder = 0
      Width = 90
    end
    object lblCantidad: TcxLabel
      Left = 198
      Top = 14
      Caption = 'Mostrar'
      Transparent = True
    end
    object cbbCantidad: TcxComboBox
      Left = 260
      Top = 12
      Properties.DropDownListStyle = lsFixedList
      TabOrder = 1
      Width = 86
    end
    object lblTipo: TcxLabel
      Left = 16
      Top = 54
      Caption = 'Tipo'
      Transparent = True
    end
    object cbbTipo: TcxComboBox
      Left = 84
      Top = 52
      Properties.DropDownListStyle = lsFixedList
      TabOrder = 2
      Width = 220
    end
    object lblSerie: TcxLabel
      Left = 328
      Top = 54
      Caption = 'Serie'
      Transparent = True
    end
    object txtSerie: TcxTextEdit
      Left = 368
      Top = 52
      Properties.CharCase = ecUpperCase
      TabOrder = 3
      Width = 112
    end
    object lblNumero: TcxLabel
      Left = 504
      Top = 54
      Caption = 'N'#250'mero'
      Transparent = True
    end
    object txtNumero: TcxTextEdit
      Left = 574
      Top = 52
      TabOrder = 4
      Width = 150
    end
    object btnActualizar: TcxButton
      Left = 850
      Top = 28
      Width = 176
      Height = 36
      Anchors = [akTop, akRight]
      Caption = 'Actualizar'
      TabOrder = 5
      OnClick = btnActualizarClick
    end
  end
  object pnlDocumentos: TPanel [1]
    Left = 0
    Top = 92
    Width = 1050
    Height = 256
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    object lblDocumentos: TcxLabel
      Left = 0
      Top = 0
      Align = alTop
      Caption = #218'ltimos documentos'
      Properties.Alignment.Vert = taVCenter
      Transparent = True
      Height = 28
      Width = 1050
      AnchorY = 14
    end
    object cxgrdDocumentos: TcxGrid
      Left = 0
      Top = 28
      Width = 1050
      Height = 228
      Align = alClient
      TabOrder = 0
      object tvDocumentos: TcxGridDBTableView
        DataController.DataSource = dsDocumentos
        OptionsData.Deleting = False
        OptionsData.Editing = False
        OptionsData.Inserting = False
        OptionsSelection.CellSelect = False
        OptionsView.GroupByBox = False
        object colTipoDocumento: TcxGridDBColumn
          Caption = 'Documento'
          DataBinding.FieldName = 'TIPO_DESCRIPCION'
          Width = 170
        end
        object colFechaDocumento: TcxGridDBColumn
          Caption = 'Fecha'
          DataBinding.FieldName = 'FECHA'
          PropertiesClassName = 'TcxDateEditProperties'
          Properties.DisplayFormat = 'dd/mm/yyyy'
          Width = 90
        end
        object colSerieDocumento: TcxGridDBColumn
          Caption = 'Serie'
          DataBinding.FieldName = 'SERIE'
          Width = 76
        end
        object colNumeroDocumento: TcxGridDBColumn
          Caption = 'N'#250'mero'
          DataBinding.FieldName = 'NUMERO'
          Width = 100
        end
        object colEstadoDocumento: TcxGridDBColumn
          Caption = 'Estado'
          DataBinding.FieldName = 'ESTADO'
          Width = 94
        end
        object colTerceroDocumento: TcxGridDBColumn
          Caption = 'Tercero'
          DataBinding.FieldName = 'TERCERO'
          Width = 250
        end
        object colLineasDocumento: TcxGridDBColumn
          Caption = 'L'#237'neas'
          DataBinding.FieldName = 'NUMERO_LINEAS'
          Width = 70
        end
        object colUnidadesDocumento: TcxGridDBColumn
          Caption = 'Unidades'
          DataBinding.FieldName = 'TOTAL_UNIDADES'
          PropertiesClassName = 'TcxCurrencyEditProperties'
          Properties.DisplayFormat = '#,##0.##'
          Width = 92
        end
        object colInstanteDocumento: TcxGridDBColumn
          DataBinding.FieldName = 'INSTANTE_ALTA'
          Visible = False
        end
      end
      object glDocumentos: TcxGridLevel
        GridView = tvDocumentos
      end
    end
  end
  object splVistaPrevia: TSplitter [2]
    Left = 0
    Top = 348
    Width = 1050
    Height = 6
    Cursor = crVSplit
    Align = alTop
  end
  object pnlLineas: TPanel [3]
    Left = 0
    Top = 354
    Width = 1050
    Height = 270
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    object lblLineas: TcxLabel
      Left = 0
      Top = 0
      Align = alTop
      Caption = 'Vista previa de l'#237'neas'
      Properties.Alignment.Vert = taVCenter
      Transparent = True
      Height = 28
      Width = 1050
      AnchorY = 14
    end
    object cxgrdLineas: TcxGrid
      Left = 0
      Top = 28
      Width = 1050
      Height = 242
      Align = alClient
      TabOrder = 0
      object tvLineas: TcxGridDBTableView
        DataController.DataSource = dsLineas
        OptionsData.Deleting = False
        OptionsData.Editing = False
        OptionsData.Inserting = False
        OptionsSelection.CellSelect = False
        OptionsView.GroupByBox = False
        object colLinea: TcxGridDBColumn
          Caption = 'L'#237'nea'
          DataBinding.FieldName = 'LINEA_DOCUMENTO'
          Width = 58
        end
        object colArticulo: TcxGridDBColumn
          Caption = 'Art'#237'culo'
          DataBinding.FieldName = 'CODIGO_ARTICULO'
          Width = 92
        end
        object colSku: TcxGridDBColumn
          Caption = 'SKU'
          DataBinding.FieldName = 'CODIGO_SKU'
          Width = 110
        end
        object colAlmacen: TcxGridDBColumn
          Caption = 'Almac'#233'n'
          DataBinding.FieldName = 'CODIGO_ALMACEN'
          Width = 80
        end
        object colLote: TcxGridDBColumn
          Caption = 'Lote'
          DataBinding.FieldName = 'LOTE'
          Width = 90
        end
        object colCaducidad: TcxGridDBColumn
          Caption = 'Caducidad'
          DataBinding.FieldName = 'FECHA_CADUCIDAD'
          PropertiesClassName = 'TcxDateEditProperties'
          Properties.DisplayFormat = 'dd/mm/yyyy'
          Width = 92
        end
        object colDescripcionArticulo: TcxGridDBColumn
          Caption = 'Descripci'#243'n art'#237'culo'
          DataBinding.FieldName = 'DESCRIPCION_ARTICULO'
          Width = 190
        end
        object colDescripcionSku: TcxGridDBColumn
          Caption = 'Descripci'#243'n SKU'
          DataBinding.FieldName = 'DESCRIPCION_SKU'
          Width = 170
        end
        object colCantidad: TcxGridDBColumn
          Caption = 'Cantidad'
          DataBinding.FieldName = 'CANTIDAD'
          PropertiesClassName = 'TcxCurrencyEditProperties'
          Properties.DisplayFormat = '#,##0.##'
          Width = 86
        end
      end
      object glLineas: TcxGridLevel
        GridView = tvLineas
      end
    end
  end
  object pnlBotones: TPanel [4]
    Left = 0
    Top = 624
    Width = 1050
    Height = 56
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 3
    object btnCancelar: TcxButton
      Left = 16
      Top = 10
      Width = 140
      Height = 36
      Cancel = True
      Caption = 'Cancelar'
      ModalResult = 2
      TabOrder = 0
    end
    object btnCargar: TcxButton
      Left = 858
      Top = 10
      Width = 176
      Height = 36
      Anchors = [akTop, akRight]
      Caption = 'Cargar documento'
      Default = True
      TabOrder = 1
      OnClick = btnCargarClick
    end
  end
  object dsDocumentos: TDataSource
    OnDataChange = dsDocumentosDataChange
    Left = 896
    Top = 160
  end
  object dsLineas: TDataSource
    Left = 896
    Top = 440
  end
end
