inherited frmMtoPrestaShopCola: TfrmMtoPrestaShopCola
  Caption = 'Cola de PrestaShop'
  TextHeight = 19
  inherited pButtonPage: TPanel
    inherited pcPantalla: TcxPageControl
      Properties.ActivePage = tsLista
      inherited tsLista: TcxTabSheet
        inherited cxGrdPrincipal: TcxGrid
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            OptionsData.Appending = False
            OptionsData.Deleting = False
            OptionsData.Editing = False
            OptionsData.Inserting = False
            object colIdCola: TcxGridDBColumn
              Caption = 'Id'
              DataBinding.FieldName = 'ID_PSCOLA'
              Options.Editing = False
              Width = 64
            end
            object colTienda: TcxGridDBColumn
              Caption = 'Tienda'
              DataBinding.FieldName = 'ID_TIENDA_PSCOLA'
              Options.Editing = False
              Width = 70
            end
            object colArticulo: TcxGridDBColumn
              Caption = 'Artículo'
              DataBinding.FieldName = 'CODIGO_ART_PSCOLA'
              Options.Editing = False
              Width = 105
            end
            object colNombreArticulo: TcxGridDBColumn
              Caption = 'Nombre del artículo'
              DataBinding.FieldName = 'DESCRIPCION_ART'
              Options.Editing = False
              Width = 260
            end
            object colCambioPrecio: TcxGridDBColumn
              Caption = 'Precio pend.'
              DataBinding.FieldName = 'ESCAMBIO_PRECIO_PSCOLA'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Options.Editing = False
              Width = 88
            end
            object colCambioStock: TcxGridDBColumn
              Caption = 'Stock pend.'
              DataBinding.FieldName = 'ESCAMBIO_STOCK_PSCOLA'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Options.Editing = False
              Width = 88
            end
            object colAccionVisibilidad: TcxGridDBColumn
              Caption = 'Visibilidad pend.'
              DataBinding.FieldName = 'VISIBILIDAD_PENDIENTE'
              Options.Editing = False
              Width = 110
            end
            object colPrecioReclamado: TcxGridDBColumn
              Caption = 'Precio proc.'
              DataBinding.FieldName =
                'ESCAMBIO_PRECIO_RECLAMADO_PSCOLA'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Options.Editing = False
              Visible = False
              Width = 88
            end
            object colStockReclamado: TcxGridDBColumn
              Caption = 'Stock proc.'
              DataBinding.FieldName = 'ESCAMBIO_STOCK_RECLAMADO_PSCOLA'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Options.Editing = False
              Visible = False
              Width = 88
            end
            object colAccionVisibilidadReclamada: TcxGridDBColumn
              Caption = 'Visibilidad proc.'
              DataBinding.FieldName = 'VISIBILIDAD_RECLAMADA'
              Options.Editing = False
              Visible = False
              Width = 110
            end
            object colEstado: TcxGridDBColumn
              Caption = 'Estado'
              DataBinding.FieldName = 'ESTADO_PSCOLA'
              Options.Editing = False
              Width = 105
            end
            object colIntentos: TcxGridDBColumn
              Caption = 'Intentos'
              DataBinding.FieldName = 'CONTADOR_INTENTOS_PSCOLA'
              Options.Editing = False
              Width = 72
            end
            object colProximoIntento: TcxGridDBColumn
              Caption = 'Próximo intento'
              DataBinding.FieldName = 'INSTANTE_PROXIMO_INTENTO_PSCOLA'
              Options.Editing = False
              Width = 145
            end
            object colUltimoCambio: TcxGridDBColumn
              Caption = 'Último cambio'
              DataBinding.FieldName = 'INSTANTE_ULTIMO_CAMBIO_PSCOLA'
              Options.Editing = False
              Width = 145
            end
            object colUltimoEnvio: TcxGridDBColumn
              Caption = 'Último envío'
              DataBinding.FieldName = 'INSTANTE_ULTIMO_ENVIO_PSCOLA'
              Options.Editing = False
              Width = 145
            end
            object colErrorCola: TcxGridDBColumn
              Caption = 'Error de la cola'
              DataBinding.FieldName = 'MENSAJE_ERROR_PSCOLA'
              Options.Editing = False
              Width = 340
            end
            object colAlta: TcxGridDBColumn
              Caption = 'Encolado'
              DataBinding.FieldName = 'INSTANTE_ALTA'
              Options.Editing = False
              Width = 145
            end
          end
        end
        object pnlDetalle: TPanel
          Left = 0
          Top = 207
          Width = 947
          Height = 280
          Align = alBottom
          BevelOuter = bvNone
          TabOrder = 1
          object pnlTituloHistorial: TPanel
            Left = 0
            Top = 0
            Width = 947
            Height = 28
            Align = alTop
            BevelOuter = bvNone
            TabOrder = 0
            object lblHistorial: TcxLabel
              Left = 8
              Top = 4
              Caption = 'Historial de operaciones HTTP'
              Style.Font.Charset = DEFAULT_CHARSET
              Style.Font.Color = clWindowText
              Style.Font.Height = -15
              Style.Font.Name = 'Source Sans 3'
              Style.Font.Style = [fsBold]
              Style.IsFontAssigned = True
              TabOrder = 0
              Transparent = True
            end
          end
          object cxgrdEventos: TcxGrid
            Left = 0
            Top = 28
            Width = 947
            Height = 125
            Align = alTop
            TabOrder = 1
            object tvEventos: TcxGridDBTableView
              Navigator.Buttons.ConfirmDelete = True
              Navigator.Visible = False
              OptionsBehavior.IncSearch = True
              OptionsData.Appending = False
              OptionsData.Deleting = False
              OptionsData.Editing = False
              OptionsData.Inserting = False
              OptionsView.GroupByBox = False
              OptionsView.Indicator = True
              object tvEventosId: TcxGridDBColumn
                Caption = 'Id'
                DataBinding.FieldName = 'ID_PSCEV'
                Options.Editing = False
                Width = 62
              end
              object tvEventosIntento: TcxGridDBColumn
                Caption = 'Intento'
                DataBinding.FieldName = 'CONTADOR_INTENTO_PSCEV'
                Options.Editing = False
                Width = 65
              end
              object tvEventosOrden: TcxGridDBColumn
                Caption = 'Orden'
                DataBinding.FieldName = 'ORDEN_OPERACION_PSCEV'
                Options.Editing = False
                Width = 60
              end
              object tvEventosMetodo: TcxGridDBColumn
                Caption = 'Método'
                DataBinding.FieldName = 'METODO_HTTP_PSCEV'
                Options.Editing = False
                Width = 70
              end
              object tvEventosRecurso: TcxGridDBColumn
                Caption = 'Recurso'
                DataBinding.FieldName = 'RECURSO_HTTP_PSCEV'
                Options.Editing = False
                Width = 310
              end
              object tvEventosHttp: TcxGridDBColumn
                Caption = 'HTTP'
                DataBinding.FieldName = 'ESTADO_HTTP_PSCEV'
                Options.Editing = False
                Width = 58
              end
              object tvEventosEstadoHttp: TcxGridDBColumn
                Caption = 'Estado HTTP'
                DataBinding.FieldName = 'TEXTO_ESTADO_PSCEV'
                Options.Editing = False
                Width = 150
              end
              object tvEventosResultado: TcxGridDBColumn
                Caption = 'Resultado'
                DataBinding.FieldName = 'RESULTADO_PSCEV'
                Options.Editing = False
                Width = 85
              end
              object tvEventosInicio: TcxGridDBColumn
                Caption = 'Inicio'
                DataBinding.FieldName = 'INSTANTE_INICIO_PSCEV'
                Options.Editing = False
                Width = 145
              end
              object tvEventosDuracion: TcxGridDBColumn
                Caption = 'ms'
                DataBinding.FieldName = 'CANTIDAD_MILISEGUNDOS_PSCEV'
                Options.Editing = False
                Width = 70
              end
            end
            object lvEventos: TcxGridLevel
              GridView = tvEventos
            end
          end
          object pcContenido: TcxPageControl
            Left = 0
            Top = 153
            Width = 947
            Height = 127
            Align = alClient
            TabOrder = 2
            Properties.ActivePage = tsRespuesta
            Properties.CustomButtons.Buttons = <>
            object tsPeticion: TcxTabSheet
              Caption = 'Petición'
              ImageIndex = 0
              object mPeticion: TcxMemo
                Left = 0
                Top = 0
                Align = alClient
                Properties.ReadOnly = True
                Properties.ScrollBars = ssBoth
                TabOrder = 0
              end
            end
            object tsRespuesta: TcxTabSheet
              Caption = 'Respuesta del servidor'
              ImageIndex = 1
              object mRespuesta: TcxMemo
                Left = 0
                Top = 0
                Align = alClient
                Properties.ReadOnly = True
                Properties.ScrollBars = ssBoth
                TabOrder = 0
              end
            end
            object tsError: TcxTabSheet
              Caption = 'Error'
              ImageIndex = 2
              object mError: TcxMemo
                Left = 0
                Top = 0
                Align = alClient
                Properties.ReadOnly = True
                Properties.ScrollBars = ssBoth
                TabOrder = 0
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
    object btnActualizar: TcxButton
      Left = 1
      Top = 120
      Width = 138
      Height = 34
      Caption = '&Actualizar'
      TabOrder = 2
      OnClick = btnActualizarClick
    end
    object btnIrAArticulo: TcxButton
      Left = 1
      Top = 158
      Width = 138
      Height = 34
      Caption = 'Ir a &Artículo'
      TabOrder = 3
      OnClick = btnIrAArticuloClick
    end
    object btnEnviarYa: TcxButton
      Left = 1
      Top = 196
      Width = 138
      Height = 34
      Caption = 'Enviar &ya'
      TabOrder = 4
      OnClick = btnEnviarYaClick
    end
  end
end
