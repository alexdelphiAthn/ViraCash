inherited frmMtoErroresEnvios: TfrmMtoErroresEnvios
  Caption = 'Envío de errores'
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
            object colId: TcxGridDBColumn
              Caption = 'Id'
              DataBinding.FieldName = 'ID_ERENV'
              Width = 65
            end
            object colReferencia: TcxGridDBColumn
              Caption = 'Referencia'
              DataBinding.FieldName = 'REFERENCIA_ERENV'
              Width = 210
            end
            object colUsuario: TcxGridDBColumn
              Caption = 'Usuario'
              DataBinding.FieldName = 'USUARIO_ALTA'
              Width = 120
            end
            object colInstanteError: TcxGridDBColumn
              Caption = 'Fecha y hora'
              DataBinding.FieldName = 'INSTANTE_ERROR_ERENV'
              Width = 155
            end
            object colEstado: TcxGridDBColumn
              Caption = 'Estado'
              DataBinding.FieldName = 'ESTADO_ERENV'
              Width = 130
            end
            object colCodigoHttp: TcxGridDBColumn
              Caption = 'HTTP'
              DataBinding.FieldName = 'CODIGO_HTTP_ERENV'
              Width = 65
            end
            object colClaseError: TcxGridDBColumn
              Caption = 'Clase'
              DataBinding.FieldName = 'CLASE_ERROR_ERENV'
              Width = 130
            end
            object colMensajeError: TcxGridDBColumn
              Caption = 'Error'
              DataBinding.FieldName = 'MENSAJE_ERROR_ERENV'
              Width = 330
            end
            object colComentarioTecnico: TcxGridDBColumn
              Caption = 'Comentario técnico'
              DataBinding.FieldName = 'COMENTARIO_TECNICO_ERENV'
              Width = 340
            end
            object colInstanteConsulta: TcxGridDBColumn
              Caption = 'Última consulta'
              DataBinding.FieldName = 'INSTANTE_CONSULTA_ERENV'
              Width = 155
            end
            object colEstadoScript: TcxGridDBColumn
              Caption = 'Script'
              DataBinding.FieldName = 'ESTADO_SCRIPT_ERENV'
              Width = 105
            end
            object colEstadoEjecutable: TcxGridDBColumn
              Caption = 'Actualización'
              DataBinding.FieldName = 'ESTADO_EJECUTABLE_ERENV'
              Width = 115
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        OnShow = tsFichaDetalleShow
        object pnlFichaCabecera: TPanel
          Left = 0
          Top = 0
          Width = 947
          Height = 122
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          object lblReferencia: TcxLabel
            Left = 12
            Top = 4
            Caption = 'Referencia'
            TabOrder = 0
            Transparent = True
          end
          object txtReferencia: TcxDBTextEdit
            Left = 12
            Top = 26
            DataBinding.DataField = 'REFERENCIA_ERENV'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 1
            Width = 218
          end
          object lblEstado: TcxLabel
            Left = 242
            Top = 4
            Caption = 'Estado'
            TabOrder = 2
            Transparent = True
          end
          object txtEstado: TcxDBTextEdit
            Left = 242
            Top = 26
            DataBinding.DataField = 'ESTADO_ERENV'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 3
            Width = 132
          end
          object lblFechaError: TcxLabel
            Left = 386
            Top = 4
            Caption = 'Fecha y hora del error'
            TabOrder = 4
            Transparent = True
          end
          object txtFechaError: TcxDBTextEdit
            Left = 386
            Top = 26
            DataBinding.DataField = 'INSTANTE_ERROR_ERENV'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 5
            Width = 168
          end
          object lblUsuarioError: TcxLabel
            Left = 566
            Top = 4
            Caption = 'Usuario'
            TabOrder = 6
            Transparent = True
          end
          object txtUsuarioError: TcxDBTextEdit
            Left = 566
            Top = 26
            DataBinding.DataField = 'USUARIO_ALTA'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 7
            Width = 152
          end
          object lblUltimaConsulta: TcxLabel
            Left = 730
            Top = 4
            Caption = 'Última consulta'
            TabOrder = 8
            Transparent = True
          end
          object txtUltimaConsulta: TcxDBTextEdit
            Left = 730
            Top = 26
            Anchors = [akLeft, akTop, akRight]
            DataBinding.DataField = 'INSTANTE_CONSULTA_ERENV'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 9
            Width = 205
          end
          object lblResultadoConsulta: TcxLabel
            Left = 12
            Top = 60
            Caption = 'Resultado de la consulta'
            TabOrder = 10
            Transparent = True
          end
          object txtResultadoConsulta: TcxDBTextEdit
            Left = 12
            Top = 82
            Width = 923
            Anchors = [akLeft, akTop, akRight]
            DataBinding.DataField = 'MENSAJE_CONSULTA_ERENV'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 11
          end
          object lblEstadoSincronizacion: TcxLabel
            Left = 242
            Top = 60
            Anchors = [akLeft, akTop, akRight]
            AutoSize = False
            Caption = 'Se actualizará al abrir la ficha.'
            ParentShowHint = False
            Properties.ShowEndEllipsis = True
            ShowHint = True
            Style.TextColor = clNavy
            TabOrder = 12
            Transparent = True
            Height = 19
            Width = 693
          end
        end
        object pcFichaError: TcxPageControl
          Left = 0
          Top = 122
          Width = 947
          Height = 365
          Align = alClient
          TabOrder = 1
          Properties.ActivePage = tsComunicacion
          Properties.CustomButtons.Buttons = <>
          ClientRectBottom = 363
          ClientRectLeft = 2
          ClientRectRight = 945
          ClientRectTop = 29
          object tsComunicacion: TcxTabSheet
            Caption = '&Comunicación'
            ImageIndex = 0
            object pnlAccionesComunicacion: TPanel
              Left = 0
              Top = 0
              Width = 943
              Height = 46
              Align = alTop
              BevelOuter = bvNone
              TabOrder = 0
              object btnFichaActualizar: TcxButton
                Left = 8
                Top = 6
                Width = 160
                Height = 34
                Caption = 'Actualizar mensajes'
                TabOrder = 0
                OnClick = btnActualizarEstadoClick
              end
              object btnFichaResponder: TcxButton
                Left = 176
                Top = 6
                Width = 174
                Height = 34
                Caption = 'Responder al soporte'
                TabOrder = 1
                OnClick = btnEnviarComentarioClick
              end
              object btnFichaAbrirSeguimiento: TcxButton
                Left = 358
                Top = 6
                Width = 182
                Height = 34
                Caption = 'Abrir seguimiento web'
                TabOrder = 2
                OnClick = btnAbrirSeguimientoClick
              end
            end
            object memComunicaciones: TcxDBMemo
              Left = 0
              Top = 46
              Align = alClient
              DataBinding.DataField = 'COMUNICACIONES_ERENV'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = True
              Properties.ScrollBars = ssVertical
              TabOrder = 1
              Height = 288
              Width = 943
            end
          end
          object tsDetalleTecnico: TcxTabSheet
            Caption = '&Detalle técnico'
            ImageIndex = 1
            object pnlMensajeError: TPanel
              Left = 0
              Top = 0
              Width = 943
              Height = 98
              Align = alTop
              BevelOuter = bvNone
              TabOrder = 0
              object lblMensajeError: TcxLabel
                Left = 8
                Top = 4
                Caption = 'Mensaje del error'
                TabOrder = 0
                Transparent = True
              end
              object memMensajeError: TcxDBMemo
                Left = 8
                Top = 26
                Width = 927
                Height = 64
                Anchors = [akLeft, akTop, akRight, akBottom]
                DataBinding.DataField = 'MENSAJE_ERROR_ERENV'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                Properties.ScrollBars = ssVertical
                TabOrder = 1
              end
            end
            object memDetalleError: TcxDBMemo
              Left = 0
              Top = 98
              Align = alClient
              DataBinding.DataField = 'DETALLE_ERROR_ERENV'
              DataBinding.DataSource = dsTablaG
              ParentFont = False
              Properties.ReadOnly = True
              Properties.ScrollBars = ssBoth
              Style.Font.Charset = ANSI_CHARSET
              Style.Font.Name = 'Consolas'
              Style.Font.Style = []
              Style.IsFontAssigned = True
              TabOrder = 1
              Height = 236
              Width = 943
            end
          end
          object tsScript: TcxTabSheet
            Caption = '&Script propuesto'
            ImageIndex = 2
            object pnlCabeceraScript: TPanel
              Left = 0
              Top = 0
              Width = 943
              Height = 106
              Align = alTop
              BevelOuter = bvNone
              TabOrder = 0
              object lblEstadoScript: TcxLabel
                Left = 8
                Top = 4
                Caption = 'Estado'
                TabOrder = 0
                Transparent = True
              end
              object txtEstadoScript: TcxDBTextEdit
                Left = 8
                Top = 26
                DataBinding.DataField = 'ESTADO_SCRIPT_ERENV'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 1
                Width = 136
              end
              object lblDescripcionScript: TcxLabel
                Left = 156
                Top = 4
                Caption = 'Descripción del técnico'
                TabOrder = 2
                Transparent = True
              end
              object txtDescripcionScript: TcxDBTextEdit
                Left = 156
                Top = 26
                Width = 779
                Anchors = [akLeft, akTop, akRight]
                DataBinding.DataField = 'DESCRIPCION_SCRIPT_ERENV'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 3
              end
              object lblHashScript: TcxLabel
                Left = 8
                Top = 58
                Caption = 'Huella SHA-256'
                TabOrder = 4
                Transparent = True
              end
              object txtHashScript: TcxDBTextEdit
                Left = 8
                Top = 80
                Width = 927
                Anchors = [akLeft, akTop, akRight]
                DataBinding.DataField = 'SHA256_SCRIPT_ERENV'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 5
              end
            end
            object pnlAccionScript: TPanel
              Left = 0
              Top = 286
              Width = 943
              Height = 48
              Align = alBottom
              BevelOuter = bvNone
              TabOrder = 1
              object btnFichaEjecutarScript: TcxButton
                Left = 8
                Top = 7
                Width = 238
                Height = 34
                Caption = 'Crear copia y ejecutar script'
                TabOrder = 0
                OnClick = btnEjecutarScriptClick
              end
            end
            object memScript: TcxDBMemo
              Left = 0
              Top = 106
              Align = alClient
              DataBinding.DataField = 'SCRIPT_SQL_ERENV'
              DataBinding.DataSource = dsTablaG
              ParentFont = False
              Properties.ReadOnly = True
              Properties.ScrollBars = ssBoth
              Style.Font.Charset = ANSI_CHARSET
              Style.Font.Name = 'Consolas'
              Style.Font.Style = []
              Style.IsFontAssigned = True
              TabOrder = 2
              Height = 180
              Width = 943
            end
          end
          object tsActualizacion: TcxTabSheet
            Caption = '&Actualización propuesta'
            ImageIndex = 3
            object pnlCabeceraEjecutable: TPanel
              Left = 0
              Top = 0
              Width = 943
              Height = 62
              Align = alTop
              BevelOuter = bvNone
              TabOrder = 0
              object lblEstadoEjecutable: TcxLabel
                Left = 8
                Top = 4
                Caption = 'Estado'
                TabOrder = 0
                Transparent = True
              end
              object txtEstadoEjecutable: TcxDBTextEdit
                Left = 8
                Top = 26
                DataBinding.DataField = 'ESTADO_EJECUTABLE_ERENV'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 1
                Width = 130
              end
              object lblVersionEjecutable: TcxLabel
                Left = 150
                Top = 4
                Caption = 'Versión'
                TabOrder = 2
                Transparent = True
              end
              object txtVersionEjecutable: TcxDBTextEdit
                Left = 150
                Top = 26
                DataBinding.DataField = 'VERSION_EJECUTABLE_ERENV'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 3
                Width = 145
              end
              object lblNombreEjecutable: TcxLabel
                Left = 307
                Top = 4
                Caption = 'Archivo'
                TabOrder = 4
                Transparent = True
              end
              object txtNombreEjecutable: TcxDBTextEdit
                Left = 307
                Top = 26
                Width = 350
                Anchors = [akLeft, akTop, akRight]
                DataBinding.DataField = 'NOMBRE_EJECUTABLE_ERENV'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 5
              end
              object lblTamanoEjecutable: TcxLabel
                Left = 669
                Top = 4
                Anchors = [akTop, akRight]
                Caption = 'Tamaño (bytes)'
                TabOrder = 6
                Transparent = True
              end
              object txtTamanoEjecutable: TcxDBTextEdit
                Left = 669
                Top = 26
                Width = 266
                Anchors = [akTop, akRight]
                DataBinding.DataField = 'CANTIDAD_BYTES_EJECUTABLE_ERENV'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 7
              end
            end
            object pnlDetalleEjecutable: TPanel
              Left = 0
              Top = 62
              Width = 943
              Height = 224
              Align = alClient
              BevelOuter = bvNone
              TabOrder = 1
              object lblDescripcionEjecutable: TcxLabel
                Left = 8
                Top = 4
                Caption = 'Descripción del técnico'
                TabOrder = 0
                Transparent = True
              end
              object memDescripcionEjecutable: TcxDBMemo
                Left = 8
                Top = 26
                Width = 927
                Height = 66
                Anchors = [akLeft, akTop, akRight]
                DataBinding.DataField = 'DESCRIPCION_EJECUTABLE_ERENV'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                Properties.ScrollBars = ssVertical
                TabOrder = 1
              end
              object lblUrlEjecutable: TcxLabel
                Left = 8
                Top = 98
                Caption = 'Dirección de descarga'
                TabOrder = 2
                Transparent = True
              end
              object txtUrlEjecutable: TcxDBTextEdit
                Left = 8
                Top = 120
                Width = 927
                Anchors = [akLeft, akTop, akRight]
                DataBinding.DataField = 'URL_EJECUTABLE_ERENV'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 3
              end
              object lblHashEjecutable: TcxLabel
                Left = 8
                Top = 152
                Caption = 'Huella SHA-256'
                TabOrder = 4
                Transparent = True
              end
              object txtHashEjecutable: TcxDBTextEdit
                Left = 8
                Top = 174
                Width = 927
                Anchors = [akLeft, akTop, akRight]
                DataBinding.DataField = 'SHA256_EJECUTABLE_ERENV'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 5
              end
            end
            object pnlAccionEjecutable: TPanel
              Left = 0
              Top = 286
              Width = 943
              Height = 48
              Align = alBottom
              BevelOuter = bvNone
              TabOrder = 2
              object btnFichaInstalarActualizacion: TcxButton
                Left = 8
                Top = 7
                Width = 248
                Height = 34
                Caption = 'Descargar, instalar y reiniciar'
                TabOrder = 0
                OnClick = btnInstalarActualizacionClick
              end
            end
          end
        end
      end
    end
  end
  inherited pButtonRightBar: TPanel
    object btnActualizarEstado: TcxButton
      Left = 1
      Top = 120
      Width = 138
      Height = 34
      Caption = 'Actualizar estado'
      TabOrder = 2
      OnClick = btnActualizarEstadoClick
    end
    object btnEnviarComentario: TcxButton
      Left = 1
      Top = 158
      Width = 138
      Height = 34
      Caption = 'Enviar comentario'
      TabOrder = 3
      OnClick = btnEnviarComentarioClick
    end
    object btnAbrirSeguimiento: TcxButton
      Left = 1
      Top = 196
      Width = 138
      Height = 34
      Caption = 'Abrir seguimiento'
      TabOrder = 4
      OnClick = btnAbrirSeguimientoClick
    end
    object btnEjecutarScript: TcxButton
      Left = 1
      Top = 234
      Width = 138
      Height = 34
      Caption = 'Ejecutar script'
      TabOrder = 5
      OnClick = btnEjecutarScriptClick
    end
    object btnInstalarActualizacion: TcxButton
      Left = 1
      Top = 272
      Width = 138
      Height = 42
      Caption = 'Instalar actualización'
      TabOrder = 6
      WordWrap = True
      OnClick = btnInstalarActualizacionClick
    end
  end
end
