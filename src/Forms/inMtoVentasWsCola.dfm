inherited frmMtoVentasWsCola: TfrmMtoVentasWsCola
  Caption = 'Cola del Web Service ViraCash'
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
              DataBinding.FieldName = 'ID_VWSC'
              Options.Editing = False
              Width = 64
            end
            object colIdEvento: TcxGridDBColumn
              Caption = 'Evento'
              DataBinding.FieldName = 'ID_EVENTO_VWSC'
              Options.Editing = False
              Visible = False
              Width = 210
            end
            object colEmpresa: TcxGridDBColumn
              Caption = 'Empresa'
              DataBinding.FieldName = 'CODIGO_EMP_VWSC'
              Options.Editing = False
              Width = 80
            end
            object colNombreEmpresa: TcxGridDBColumn
              Caption = 'Razón social'
              DataBinding.FieldName = 'RAZON_SOCIAL_EMP'
              Options.Editing = False
              Width = 220
            end
            object colSerie: TcxGridDBColumn
              Caption = 'Serie'
              DataBinding.FieldName = 'SERIE_FAC_VWSC'
              Options.Editing = False
              Width = 90
            end
            object colNumero: TcxGridDBColumn
              Caption = 'Número'
              DataBinding.FieldName = 'NUMERO_FAC_VWSC'
              Options.Editing = False
              Width = 105
            end
            object colTipo: TcxGridDBColumn
              Caption = 'Tipo de evento'
              DataBinding.FieldName = 'TIPO_EVENTO_VWSC'
              Options.Editing = False
              Width = 125
            end
            object colEstado: TcxGridDBColumn
              Caption = 'Estado'
              DataBinding.FieldName = 'ESTADO_VWSC'
              Options.Editing = False
              Width = 105
            end
            object colIntentos: TcxGridDBColumn
              Caption = 'Intentos'
              DataBinding.FieldName = 'CONTADOR_INTENTOS_VWSC'
              Options.Editing = False
              Width = 72
            end
            object colProximoIntento: TcxGridDBColumn
              Caption = 'Próximo intento'
              DataBinding.FieldName = 'INSTANTE_PROXIMO_INTENTO_VWSC'
              Options.Editing = False
              Width = 145
            end
            object colEnvio: TcxGridDBColumn
              Caption = 'Envío'
              DataBinding.FieldName = 'INSTANTE_ENVIO_VWSC'
              Options.Editing = False
              Width = 145
            end
            object colIdPeticion: TcxGridDBColumn
              Caption = 'Id petición'
              DataBinding.FieldName = 'ID_PETICION_VWSC'
              Options.Editing = False
              Width = 190
            end
            object colErrorCola: TcxGridDBColumn
              Caption = 'Error de la cola'
              DataBinding.FieldName = 'MENSAJE_ERROR_VWSC'
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
              Caption = 'Historial de intentos HTTP'
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
          object cxgrdIntentos: TcxGrid
            Left = 0
            Top = 28
            Width = 947
            Height = 125
            Align = alTop
            TabOrder = 1
            object tvIntentos: TcxGridDBTableView
              Navigator.Buttons.ConfirmDelete = True
              Navigator.Visible = False
              OptionsBehavior.IncSearch = True
              OptionsData.Appending = False
              OptionsData.Deleting = False
              OptionsData.Editing = False
              OptionsData.Inserting = False
              OptionsView.GroupByBox = False
              OptionsView.Indicator = True
              object tvIntentosId: TcxGridDBColumn
                Caption = 'Id'
                DataBinding.FieldName = 'ID_VWSCI'
                Options.Editing = False
                Width = 62
              end
              object tvIntentosNumero: TcxGridDBColumn
                Caption = 'Intento'
                DataBinding.FieldName = 'CONTADOR_INTENTO_VWSCI'
                Options.Editing = False
                Width = 65
              end
              object tvIntentosIdPeticion: TcxGridDBColumn
                Caption = 'Id petición'
                DataBinding.FieldName = 'ID_PETICION_VWSCI'
                Options.Editing = False
                Width = 180
              end
              object tvIntentosMetodo: TcxGridDBColumn
                Caption = 'Método'
                DataBinding.FieldName = 'METODO_HTTP_VWSCI'
                Options.Editing = False
                Width = 70
              end
              object tvIntentosRecurso: TcxGridDBColumn
                Caption = 'Recurso'
                DataBinding.FieldName = 'RECURSO_HTTP_VWSCI'
                Options.Editing = False
                Width = 290
              end
              object tvIntentosHttp: TcxGridDBColumn
                Caption = 'HTTP'
                DataBinding.FieldName = 'ESTADO_HTTP_VWSCI'
                Options.Editing = False
                Width = 58
              end
              object tvIntentosResultado: TcxGridDBColumn
                Caption = 'Resultado'
                DataBinding.FieldName = 'RESULTADO_VWSCI'
                Options.Editing = False
                Width = 85
              end
              object tvIntentosInicio: TcxGridDBColumn
                Caption = 'Inicio'
                DataBinding.FieldName = 'INSTANTE_INICIO_VWSCI'
                Options.Editing = False
                Width = 145
              end
              object tvIntentosDuracion: TcxGridDBColumn
                Caption = 'ms'
                DataBinding.FieldName = 'CANTIDAD_MILISEGUNDOS_VWSCI'
                Options.Editing = False
                Width = 70
              end
            end
            object lvIntentos: TcxGridLevel
              GridView = tvIntentos
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
    object btnIrADocumento: TcxButton
      Left = 1
      Top = 158
      Width = 138
      Height = 34
      Caption = 'Ir a &Documento'
      TabOrder = 3
      OnClick = btnIrADocumentoClick
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
