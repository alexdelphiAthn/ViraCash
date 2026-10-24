inherited frmMtoDocumentosTrabajo: TfrmMtoDocumentosTrabajo
  Caption = 'Documentos de Trabajo'
  TextHeight = 19
  inherited pButtonPage: TPanel
    inherited pcPantalla: TcxPageControl
      Properties.ActivePage = tsLista
      inherited tsLista: TcxTabSheet
        object pcAmbitoDTR: TcxPageControl
          Left = 0
          Top = 0
          Width = 943
          Height = 34
          Align = alTop
          TabOrder = 0
          Properties.ActivePage = tsAmbitoPropiosDTR
          Properties.CustomButtons.Buttons = <>
          OnChange = pcAmbitoDTRChange
          ClientRectBottom = 30
          ClientRectLeft = 4
          ClientRectRight = 939
          ClientRectTop = 28
          object tsAmbitoPropiosDTR: TcxTabSheet
            Caption = 'Mis documentos'
            ImageIndex = 0
          end
          object tsAmbitoCompartidosDTR: TcxTabSheet
            Caption = 'Compartidos conmigo'
            ImageIndex = 1
          end
          object tsAmbitoArchivadosDTR: TcxTabSheet
            Caption = 'Archivados'
            ImageIndex = 2
          end
        end
        inherited cxGrdPrincipal: TcxGrid
          Top = 34
          Align = alTop
          Height = 211
          TabOrder = 1
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            OptionsData.Editing = True
            object colDtrId: TcxGridDBColumn
              Caption = 'ID'
              DataBinding.FieldName = 'ID_DTR'
              Options.Editing = False
              Width = 70
            end
            object colDtrTitulo: TcxGridDBColumn
              Caption = 'Titulo'
              DataBinding.FieldName = 'TITULO_DTR'
              Width = 240
            end
            object colDtrTipo: TcxGridDBColumn
              Caption = 'Tipo'
              DataBinding.FieldName = 'TIPO_DTR'
              Width = 90
            end
            object colDtrEstado: TcxGridDBColumn
              Caption = 'Estado'
              DataBinding.FieldName = 'ESTADO_DTR'
              Options.Editing = False
              Width = 90
            end
            object colDtrUsuario: TcxGridDBColumn
              Caption = 'Propietario'
              DataBinding.FieldName = 'USUARIO_DTR'
              Options.Editing = False
              Width = 110
            end
            object colDtrInstante: TcxGridDBColumn
              Caption = 'Fecha'
              DataBinding.FieldName = 'INSTANTE_DOCUMENTO_DTR'
              Width = 135
            end
            object colDtrEmpresa: TcxGridDBColumn
              Caption = 'Empresa'
              DataBinding.FieldName = 'CODIGO_EMP_DTR'
              Width = 90
            end
            object colDtrAlmacen: TcxGridDBColumn
              Caption = 'Almacen'
              DataBinding.FieldName = 'CODIGO_ALM_DTR'
              Width = 90
            end
          end
        end
        object splLineasDTR: TcxSplitter
          Left = 0
          Top = 245
          Width = 943
          Height = 8
          AlignSplitter = salTop
          Control = cxGrdPrincipal
        end
        object pnlLineasDTR: TPanel
          Left = 0
          Top = 253
          Width = 943
          Height = 231
          Align = alClient
          BevelOuter = bvNone
          TabOrder = 2
          object pnlAccionesDTR: TPanel
            Left = 0
            Top = 0
            Width = 943
            Height = 32
            Align = alTop
            BevelOuter = bvNone
            TabOrder = 0
            object lblLineasDTR: TcxLabel
              Left = 0
              Top = 0
              Align = alLeft
              Caption = 'Detalle'
              Properties.Alignment.Vert = taVCenter
              Height = 32
              Width = 160
            end
            object btnListadoDTR: TcxButton
              Left = 163
              Top = 0
              Width = 120
              Height = 32
              Align = alRight
              Caption = 'Listado'
              TabOrder = 5
              OnClick = btnListadoDTRClick
            end
            object btnEnviarADTR: TcxButton
              Left = 283
              Top = 0
              Width = 180
              Height = 32
              Align = alRight
              Caption = 'Enviar a...'
              DropDownMenu = pmEnviarDTR
              Kind = cxbkDropDownButton
              TabOrder = 4
              OnClick = btnEnviarADTRClick
            end
            object btnCargarDTR: TcxButton
              Left = 463
              Top = 0
              Width = 180
              Height = 32
              Align = alRight
              Caption = 'Cargar...'
              DropDownMenu = pmCargarDTR
              Kind = cxbkDropDownButton
              TabOrder = 1
              OnClick = btnCargarDTRClick
            end
            object btnCompartirDTR: TcxButton
              Left = 643
              Top = 0
              Width = 120
              Height = 32
              Align = alRight
              Caption = 'Compartir...'
              TabOrder = 2
              OnClick = btnCompartirDTRClick
            end
            object btnImprimirEtiquetasDTR: TcxButton
              Left = 763
              Top = 0
              Width = 180
              Height = 32
              Align = alRight
              Caption = 'Imprimir etiquetas'
              TabOrder = 3
              OnClick = btnImprimirEtiquetasDTRClick
            end
          end
          object pcDetalleDTR: TcxPageControl
            Left = 0
            Top = 32
            Width = 943
            Height = 199
            Align = alClient
            TabOrder = 1
            Properties.ActivePage = tsLineasDTR
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 195
            ClientRectLeft = 4
            ClientRectRight = 939
            ClientRectTop = 28
            object tsLineasDTR: TcxTabSheet
              Caption = 'Lineas'
              ImageIndex = 0
              object cxgrdLineasDTR: TcxGrid
                Left = 0
                Top = 0
                Width = 935
                Height = 167
                Align = alClient
                TabOrder = 0
                object tvLineasDTR: TcxGridDBTableView
                  Navigator.Buttons.CustomButtons = <>
                  ScrollbarAnnotations.CustomAnnotations = <>
                  OptionsData.Editing = True
                  OptionsView.GroupByBox = False
                  object colDtlLinea: TcxGridDBColumn
                    Caption = 'Linea'
                    DataBinding.FieldName = 'LINEA_DTL'
                    Width = 70
                  end
                  object colDtlArticulo: TcxGridDBColumn
                    Caption = 'Articulo'
                    DataBinding.FieldName = 'CODIGO_ART_DTL'
                    Width = 110
                  end
                  object colDtlSku: TcxGridDBColumn
                    Caption = 'SKU'
                    DataBinding.FieldName = 'CODIGO_UNIDAD_DTL'
                    Width = 160
                  end
                  object colDtlAlmacen: TcxGridDBColumn
                    Caption = 'Almacen'
                    DataBinding.FieldName = 'CODIGO_ALM_DTL'
                    Width = 90
                  end
                  object colDtlDescripcionArticulo: TcxGridDBColumn
                    Caption = 'Descripcion articulo'
                    DataBinding.FieldName = 'DESCRIPCION_ARTICULO_DTL'
                    Width = 220
                  end
                  object colDtlModelo: TcxGridDBColumn
                    Caption = 'Modelo'
                    DataBinding.FieldName = 'REF_PROVEEDOR'
                    Options.Editing = False
                    Width = 120
                  end
                  object colDtlFamilia: TcxGridDBColumn
                    Caption = 'Familia'
                    DataBinding.FieldName = 'DESCRIPCION_FAM'
                    Options.Editing = False
                    Width = 160
                  end
                  object colDtlProveedor: TcxGridDBColumn
                    Caption = 'Proveedor'
                    DataBinding.FieldName = 'NOMBRE_PRV'
                    Options.Editing = False
                    Width = 180
                  end
                  object colDtlTemporada: TcxGridDBColumn
                    Caption = 'Temporada'
                    DataBinding.FieldName = 'TEMPORADA_ART'
                    Options.Editing = False
                    Width = 110
                  end
                  object colDtlDescripcionSku: TcxGridDBColumn
                    Caption = 'Descripcion unidad'
                    DataBinding.FieldName = 'DESCRIPCION_UNIDAD_DTL'
                    Width = 180
                  end
                  object colDtlCantidadStock: TcxGridDBColumn
                    Caption = 'Stock'
                    DataBinding.FieldName = 'CANTIDAD_STOCK_DTL'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = '#,##0.##;-#,##0.##;0'
                    Properties.EditFormat = '#,##0.##'
                    Width = 80
                  end
                  object colDtlCantidad: TcxGridDBColumn
                    Caption = 'Cantidad'
                    DataBinding.FieldName = 'CANTIDAD_DTL'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = '#,##0.##;-#,##0.##;0'
                    Properties.EditFormat = '#,##0.##'
                    Width = 90
                  end
                  object colDtlOrigen: TcxGridDBColumn
                    Caption = 'Origen'
                    DataBinding.FieldName = 'ORIGEN_DTL'
                    Width = 80
                  end
                  object colDtlInstanteStock: TcxGridDBColumn
                    Caption = 'Instante stock'
                    DataBinding.FieldName = 'INSTANTE_STOCK_DTL'
                    Width = 135
                  end
                end
                object glLineasDTR: TcxGridLevel
                  GridView = tvLineasDTR
                end
              end
            end
            object tsCompartirDTR: TcxTabSheet
              Caption = 'Compartido con'
              ImageIndex = 1
              object cxgrdCompartidosDTR: TcxGrid
                Left = 0
                Top = 0
                Width = 935
                Height = 167
                Align = alClient
                TabOrder = 0
                object tvCompartidosDTR: TcxGridDBTableView
                  Navigator.Buttons.CustomButtons = <>
                  ScrollbarAnnotations.CustomAnnotations = <>
                  OptionsData.Editing = True
                  OptionsView.GroupByBox = False
                  object colDtcTipoDestino: TcxGridDBColumn
                    Caption = 'Tipo'
                    DataBinding.FieldName = 'TIPO_DESTINO_DTC'
                    PropertiesClassName = 'TcxComboBoxProperties'
                    Properties.Items.Strings = (
                      'USUARIO'
                      'GRUPO')
                    Width = 90
                  end
                  object colDtcUsuarioGrupo: TcxGridDBColumn
                    Caption = 'Usuario / grupo'
                    DataBinding.FieldName = 'USUARIO_GRUPO_DTC'
                    Width = 200
                  end
                  object colDtcPermiso: TcxGridDBColumn
                    Caption = 'Permiso'
                    DataBinding.FieldName = 'PERMISO_DTC'
                    Width = 110
                  end
                  object colDtcAlta: TcxGridDBColumn
                    Caption = 'Alta'
                    DataBinding.FieldName = 'INSTANTE_ALTA'
                    Options.Editing = False
                    Width = 135
                  end
                end
                object glCompartidosDTR: TcxGridLevel
                  GridView = tvCompartidosDTR
                end
              end
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        TabVisible = False
      end
    end
  end
  inherited pButtonRightBar: TPanel
    object pnlLateralDTR: TPanel
      Left = 0
      Top = 110
      Width = 140
      Height = 250
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 2
      object btnArchivarDTR: TcxButton
        Left = 0
        Top = 216
        Width = 140
        Height = 34
        Align = alBottom
        Caption = '&Archivar'
        TabOrder = 2
        OnClick = btnArchivarDTRClick
      end
      object btnCambiarEstadoDTR: TcxButton
        Left = 0
        Top = 182
        Width = 140
        Height = 34
        Align = alBottom
        Caption = 'Cambiar estado'
        DropDownMenu = pmEstadoDTR
        Kind = cxbkDropDownButton
        TabOrder = 1
        OnClick = btnCambiarEstadoDTRClick
      end
      object pnlFotoArticuloActivoDTR: TPanel
        Left = 0
        Top = 0
        Width = 140
        Height = 182
        Align = alClient
        BevelOuter = bvLowered
        TabOrder = 0
        object lblFotoArticuloActivoDTR: TcxLabel
          Left = 1
          Top = 1
          Align = alTop
          Caption = 'Art'#237'culo activo'
          Properties.Alignment.Horz = taCenter
          Properties.Alignment.Vert = taVCenter
          Transparent = True
          Height = 24
          Width = 138
          AnchorX = 70
          AnchorY = 13
        end
        object imgFotoArticuloActivoDTR: TImage
          Left = 1
          Top = 25
          Width = 138
          Height = 156
          Hint = 'Foto del art'#237'culo / SKU seleccionado'
          Align = alClient
          Center = True
          Proportional = True
          ShowHint = True
          Stretch = True
        end
      end
    end
  end
  inherited alMtoGen: TActionList
    object actIrArticuloDTR: TAction
      Caption = 'Ir a art'#237'culo'
      ShortCut = 16466
      OnExecute = actIrArticuloDTRExecute
    end
  end
  object pmEnviarDTR: TPopupMenu
    Left = 48
    Top = 200
    object miEnviarAlbaranDTR: TMenuItem
      Caption = 'Albarán de venta (mayor)...'
      OnClick = miEnviarAlbaranDTRClick
    end
    object miEnviarFacturaVentaDTR: TMenuItem
      Caption = 'Borrador de factura de venta (mayor)...'
      OnClick = miEnviarFacturaVentaDTRClick
    end
    object miEnviarTpvDTR: TMenuItem
      Caption = 'Venta TPV'
      OnClick = miEnviarTpvDTRClick
    end
    object miEnviarPedidoCompraDTR: TMenuItem
      Caption = 'Pedido de compra...'
      OnClick = miEnviarPedidoCompraDTRClick
    end
    object miEnviarAlbaranCompraDTR: TMenuItem
      Caption = 'Albarán de compra...'
      OnClick = miEnviarAlbaranCompraDTRClick
    end
    object miEnviarDevolucionCompraDTR: TMenuItem
      Caption = 'Devolución a proveedor...'
      OnClick = miEnviarDevolucionCompraDTRClick
    end
    object miEnviarTraspasoCajaDTR: TMenuItem
      Caption = 'Traspaso de caja...'
      OnClick = miEnviarTraspasoCajaDTRClick
    end
    object miEnviarPeticionTraspasoDTR: TMenuItem
      Caption = 'Petición de traspaso...'
      OnClick = miEnviarPeticionTraspasoDTRClick
    end
    object miEnviarDistribucionDTR: TMenuItem
      Caption = 'Distribución entre almacenes...'
      OnClick = miEnviarDistribucionDTRClick
    end
    object miEnviarInventarioDTR: TMenuItem
      Caption = 'Inventario...'
      OnClick = miEnviarInventarioDTRClick
    end
    object miEnviarTarifasDTR: TMenuItem
      Caption = 'Sesión de cambio de tarifas'
      OnClick = miEnviarTarifasDTRClick
    end
  end
  object pmCargarDTR: TPopupMenu
    Left = 144
    Top = 200
    object miCargarFiltrosDTR: TMenuItem
      Caption = 'Por filtros...'
      OnClick = btnCargarFiltrosDTRClick
    end
    object miCargarDocumentoDTR: TMenuItem
      Caption = 'Desde documento...'
      OnClick = miCargarDocumentoDTRClick
    end
  end
  object pmEstadoDTR: TPopupMenu
    OnPopup = pmEstadoDTRPopup
    Left = 240
    Top = 200
    object miEstadoCreadoDTR: TMenuItem
      Caption = 'Creado (reabrir para reutilizar)'
      GroupIndex = 1
      RadioItem = True
      OnClick = miEstadoCreadoDTRClick
    end
    object miEstadoEnviadoDTR: TMenuItem
      Caption = 'Enviado'
      GroupIndex = 1
      RadioItem = True
      OnClick = miEstadoEnviadoDTRClick
    end
    object miEstadoArchivadoDTR: TMenuItem
      Caption = 'Archivado'
      GroupIndex = 1
      RadioItem = True
      OnClick = miEstadoArchivadoDTRClick
    end
  end
end
