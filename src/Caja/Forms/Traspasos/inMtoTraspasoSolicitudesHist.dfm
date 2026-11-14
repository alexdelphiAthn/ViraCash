inherited frmMtoTraspasoSolicitudesHist: TfrmMtoTraspasoSolicitudesHist
  Caption = 'Hist'#243'rico de Solicitudes de Traspaso'
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 19
  inherited pButtonPage: TPanel
    inherited pcPantalla: TcxPageControl
      Properties.ActivePage = tsLista
      inherited tsLista: TcxTabSheet
        Caption = '&Lista'
        inherited cxGrdPrincipal: TcxGrid
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            OptionsCustomize.ColumnGrouping = False
            OptionsData.Deleting = False
            OptionsData.Editing = False
            OptionsData.Inserting = False
            OptionsView.GroupByBox = False
            object cxGrdDBTabPrinSERIE_TRSOL: TcxGridDBColumn
              Caption = 'Serie'
              DataBinding.FieldName = 'SERIE_TRSOL'
              Width = 60
            end
            object cxGrdDBTabPrinNUMERO_TRSOL: TcxGridDBColumn
              Caption = 'N'#250'mero'
              DataBinding.FieldName = 'NUMERO_TRSOL'
              Width = 90
            end
            object cxGrdDBTabPrinINSTANTE_ALTA: TcxGridDBColumn
              Caption = 'Fecha y hora de solicitud'
              DataBinding.FieldName = 'INSTANTE_ALTA'
              PropertiesClassName = 'TcxDateEditProperties'
              Properties.DisplayFormat = 'dd/mm/yyyy hh:nn:ss'
              Width = 165
            end
            object cxGrdDBTabPrinCODIGO_EMP_TRSOL: TcxGridDBColumn
              Caption = 'Empresa solicitante'
              DataBinding.FieldName = 'CODIGO_EMP_TRSOL'
              Width = 105
            end
            object cxGrdDBTabPrinNOMBRE_EMPRESA_TRSOL: TcxGridDBColumn
              Caption = 'Nombre empresa solicitante'
              DataBinding.FieldName = 'NOMBRE_EMPRESA_TRSOL'
              Width = 180
            end
            object cxGrdDBTabPrinCODIGO_ALM_DESTINO_TRSOL: TcxGridDBColumn
              Caption = 'Almac'#233'n solicitante'
              DataBinding.FieldName = 'CODIGO_ALM_DESTINO_TRSOL'
              Width = 110
            end
            object cxGrdDBTabPrinNOMBRE_ALMACEN_DESTINO_TRSOL: TcxGridDBColumn
              Caption = 'Nombre almac'#233'n solicitante'
              DataBinding.FieldName = 'NOMBRE_ALMACEN_DESTINO_TRSOL'
              Width = 190
            end
            object cxGrdDBTabPrinCODIGO_EMP_CONTRA_TRSOL: TcxGridDBColumn
              Caption = 'Empresa solicitada'
              DataBinding.FieldName = 'CODIGO_EMP_CONTRA_TRSOL'
              Width = 105
            end
            object cxGrdDBTabPrinNOMBRE_EMPRESA_CONTRA_TRSOL: TcxGridDBColumn
              Caption = 'Nombre empresa solicitada'
              DataBinding.FieldName = 'NOMBRE_EMPRESA_CONTRA_TRSOL'
              Width = 180
            end
            object cxGrdDBTabPrinCODIGO_ALM_ORIGEN_TRSOL: TcxGridDBColumn
              Caption = 'Almac'#233'n solicitado'
              DataBinding.FieldName = 'CODIGO_ALM_ORIGEN_TRSOL'
              Width = 110
            end
            object cxGrdDBTabPrinNOMBRE_ALMACEN_ORIGEN_TRSOL: TcxGridDBColumn
              Caption = 'Nombre almac'#233'n solicitado'
              DataBinding.FieldName = 'NOMBRE_ALMACEN_ORIGEN_TRSOL'
              Width = 190
            end
            object cxGrdDBTabPrinCODIGO_CAJA_TRSOL: TcxGridDBColumn
              Caption = 'Caja'
              DataBinding.FieldName = 'CODIGO_CAJA_TRSOL'
              Width = 70
            end
            object cxGrdDBTabPrinNOMBRE_CAJA_TRSOL: TcxGridDBColumn
              Caption = 'Nombre caja'
              DataBinding.FieldName = 'NOMBRE_CAJA_TRSOL'
              Width = 140
            end
            object cxGrdDBTabPrinCODIGO_EMPLEADO_TRSOL: TcxGridDBColumn
              Caption = 'Empleado'
              DataBinding.FieldName = 'CODIGO_EMPLEADO_TRSOL'
              Width = 90
            end
            object cxGrdDBTabPrinNOMBRE_EMPLEADO_TRSOL: TcxGridDBColumn
              Caption = 'Nombre empleado'
              DataBinding.FieldName = 'NOMBRE_EMPLEADO_TRSOL'
              Width = 170
            end
            object cxGrdDBTabPrinESTADO_TRSOL: TcxGridDBColumn
              Caption = 'Estado'
              DataBinding.FieldName = 'ESTADO_TRSOL'
              Width = 135
            end
            object cxGrdDBTabPrinMODO_PETICION_TRSOL: TcxGridDBColumn
              Caption = 'Modo de petici'#243'n'
              DataBinding.FieldName = 'MODO_PETICION_TRSOL'
              Width = 145
            end
            object cxGrdDBTabPrinATENDIDA_TRSOL: TcxGridDBColumn
              Caption = 'Atenci'#243'n'
              DataBinding.FieldName = 'ATENDIDA_TRSOL'
              Width = 130
            end
            object cxGrdDBTabPrinTIENE_TRASPASO_TRSOL: TcxGridDBColumn
              Caption = 'Con traspaso'
              DataBinding.FieldName = 'TIENE_TRASPASO_TRSOL'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 95
            end
            object cxGrdDBTabPrinTOTAL_TRASPASOS_TRSOL: TcxGridDBColumn
              Caption = 'Traspasos'
              DataBinding.FieldName = 'TOTAL_TRASPASOS_TRSOL'
              HeaderAlignmentHorz = taRightJustify
              Width = 75
            end
            object cxGrdDBTabPrinTOTAL_LINEAS_TRSOL: TcxGridDBColumn
              Caption = 'L'#237'neas'
              DataBinding.FieldName = 'TOTAL_LINEAS_TRSOL'
              HeaderAlignmentHorz = taRightJustify
              Width = 65
            end
            object cxGrdDBTabPrinLINEAS_ATENDIDAS_TRSOL: TcxGridDBColumn
              Caption = 'L'#237'neas atendidas'
              DataBinding.FieldName = 'LINEAS_ATENDIDAS_TRSOL'
              HeaderAlignmentHorz = taRightJustify
              Width = 100
            end
            object cxGrdDBTabPrinLINEAS_SERVIDAS_TRSOL: TcxGridDBColumn
              Caption = 'L'#237'neas servidas'
              DataBinding.FieldName = 'LINEAS_SERVIDAS_TRSOL'
              HeaderAlignmentHorz = taRightJustify
              Width = 95
            end
            object cxGrdDBTabPrinLINEAS_RECHAZADAS_TRSOL: TcxGridDBColumn
              Caption = 'L'#237'neas rechazadas'
              DataBinding.FieldName = 'LINEAS_RECHAZADAS_TRSOL'
              HeaderAlignmentHorz = taRightJustify
              Width = 105
            end
            object cxGrdDBTabPrinLINEAS_PENDIENTES_TRSOL: TcxGridDBColumn
              Caption = 'L'#237'neas pendientes'
              DataBinding.FieldName = 'LINEAS_PENDIENTES_TRSOL'
              HeaderAlignmentHorz = taRightJustify
              Width = 105
            end
            object cxGrdDBTabPrinCANTIDAD_PEDIDA_TRSOL: TcxGridDBColumn
              Caption = 'Cantidad pedida'
              DataBinding.FieldName = 'CANTIDAD_PEDIDA_TRSOL'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.###'
              Width = 100
            end
            object cxGrdDBTabPrinCANTIDAD_SERVIDA_TRSOL: TcxGridDBColumn
              Caption = 'Cantidad servida'
              DataBinding.FieldName = 'CANTIDAD_SERVIDA_TRSOL'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.###'
              Width = 105
            end
            object cxGrdDBTabPrinCANTIDAD_PENDIENTE_TRSOL: TcxGridDBColumn
              Caption = 'Cantidad no servida'
              DataBinding.FieldName = 'CANTIDAD_PENDIENTE_TRSOL'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.###'
              Width = 115
            end
            object cxGrdDBTabPrinMOTIVOS_RECHAZO_TRSOL: TcxGridDBColumn
              Caption = 'Motivos de rechazo'
              DataBinding.FieldName = 'MOTIVOS_RECHAZO_TRSOL'
              Width = 280
            end
            object cxGrdDBTabPrinOBSERVACIONES_TRSOL: TcxGridDBColumn
              Caption = 'Observaciones'
              DataBinding.FieldName = 'OBSERVACIONES_TRSOL'
              Width = 250
            end
          end
        end
        object pnlFiltroModoPeticion: TPanel
          Left = 0
          Top = 0
          Width = 947
          Height = 38
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 1
          object lblFiltroModoPeticion: TcxLabel
            Left = 12
            Top = 8
            Caption = 'Modo de la petici'#243'n'
            TabOrder = 0
          end
          object cboFiltroModoPeticion: TcxComboBox
            Left = 168
            Top = 6
            Properties.DropDownListStyle = lsFixedList
            Properties.Items.Strings = (
              'Todos'
              'Pendiente'
              'Auto'
              'Atendida'
              'Rechazada parcial'
              'Rechazada Total'
              'Cancelada')
            Properties.OnChange = cboFiltroModoPeticionPropertiesChange
            TabOrder = 1
            Width = 210
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        Caption = '&Ficha'
        TabVisible = True
        object pnlCabeceraSolicitud: TPanel
          Left = 0
          Top = 0
          Width = 943
          Height = 220
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          object lblSolicitud: TcxLabel
            Left = 12
            Top = 10
            Caption = 'Solicitud'
            Transparent = True
          end
          object txtSerieSolicitud: TcxDBTextEdit
            Left = 80
            Top = 7
            DataBinding.DataField = 'SERIE_TRSOL'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 0
            Width = 50
          end
          object txtNumeroSolicitud: TcxDBTextEdit
            Left = 136
            Top = 7
            DataBinding.DataField = 'NUMERO_TRSOL'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 1
            Width = 90
          end
          object lblAltaSolicitud: TcxLabel
            Left = 244
            Top = 10
            Caption = 'Alta'
            AutoSize = False
            Width = 68
            Transparent = True
          end
          object datAltaSolicitud: TcxDBDateEdit
            Left = 320
            Top = 7
            DataBinding.DataField = 'INSTANTE_ALTA'
            DataBinding.DataSource = dsTablaG
            Properties.DisplayFormat = 'dd/mm/yyyy hh:nn:ss'
            Properties.ReadOnly = True
            TabOrder = 2
            Width = 145
          end
          object lblEstadoSolicitud: TcxLabel
            Left = 480
            Top = 10
            Caption = 'Estado'
            Transparent = True
          end
          object txtEstadoSolicitud: TcxDBTextEdit
            Left = 560
            Top = 7
            DataBinding.DataField = 'ESTADO_TRSOL'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 3
            Width = 170
          end
          object txtAtendidaSolicitud: TcxDBTextEdit
            Left = 738
            Top = 7
            DataBinding.DataField = 'ATENDIDA_TRSOL'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 4
            Width = 185
          end
          object chkTraspasoSolicitud: TcxDBCheckBox
            Left = 560
            Top = 40
            Caption = 'Convertida en traspaso'
            DataBinding.DataField = 'TIENE_TRASPASO_TRSOL'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            Properties.ValueChecked = 'S'
            Properties.ValueUnchecked = 'N'
            TabOrder = 5
            Transparent = True
            Width = 350
          end
          object lblEmpresaSolicitante: TcxLabel
            Left = 12
            Top = 42
            Caption = 'Empresa solicitante'
            Transparent = True
          end
          object txtEmpresaSolicitante: TcxDBTextEdit
            Left = 200
            Top = 39
            DataBinding.DataField = 'CODIGO_EMP_TRSOL'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 6
            Width = 65
          end
          object txtNombreEmpresaSolicitante: TcxDBTextEdit
            Left = 271
            Top = 39
            DataBinding.DataField = 'NOMBRE_EMPRESA_TRSOL'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 7
            Width = 260
          end
          object lblAlmacenSolicitante: TcxLabel
            Left = 12
            Top = 71
            Caption = 'Almac'#233'n solicitante'
            Transparent = True
          end
          object txtAlmacenSolicitante: TcxDBTextEdit
            Left = 200
            Top = 68
            DataBinding.DataField = 'CODIGO_ALM_DESTINO_TRSOL'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 8
            Width = 65
          end
          object txtNombreAlmacenSolicitante: TcxDBTextEdit
            Left = 271
            Top = 68
            DataBinding.DataField = 'NOMBRE_ALMACEN_DESTINO_TRSOL'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 9
            Width = 260
          end
          object lblEmpresaSolicitada: TcxLabel
            Left = 12
            Top = 100
            Caption = 'Empresa solicitada'
            Transparent = True
          end
          object txtEmpresaSolicitada: TcxDBTextEdit
            Left = 200
            Top = 97
            DataBinding.DataField = 'CODIGO_EMP_CONTRA_TRSOL'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 10
            Width = 65
          end
          object txtNombreEmpresaSolicitada: TcxDBTextEdit
            Left = 271
            Top = 97
            DataBinding.DataField = 'NOMBRE_EMPRESA_CONTRA_TRSOL'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 11
            Width = 260
          end
          object lblAlmacenSolicitado: TcxLabel
            Left = 12
            Top = 129
            Caption = 'Almac'#233'n solicitado'
            Transparent = True
          end
          object txtAlmacenSolicitado: TcxDBTextEdit
            Left = 200
            Top = 126
            DataBinding.DataField = 'CODIGO_ALM_ORIGEN_TRSOL'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 12
            Width = 65
          end
          object txtNombreAlmacenSolicitado: TcxDBTextEdit
            Left = 271
            Top = 126
            DataBinding.DataField = 'NOMBRE_ALMACEN_ORIGEN_TRSOL'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 13
            Width = 260
          end
          object lblCajaSolicitud: TcxLabel
            Left = 12
            Top = 158
            Caption = 'Caja'
            Transparent = True
          end
          object txtCajaSolicitud: TcxDBTextEdit
            Left = 200
            Top = 155
            DataBinding.DataField = 'CODIGO_CAJA_TRSOL'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 14
            Width = 65
          end
          object txtNombreCajaSolicitud: TcxDBTextEdit
            Left = 271
            Top = 155
            DataBinding.DataField = 'NOMBRE_CAJA_TRSOL'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 15
            Width = 260
          end
          object lblEmpleadoSolicitud: TcxLabel
            Left = 12
            Top = 187
            Caption = 'Empleado solicitante'
            Transparent = True
          end
          object txtEmpleadoSolicitud: TcxDBTextEdit
            Left = 200
            Top = 184
            DataBinding.DataField = 'CODIGO_EMPLEADO_TRSOL'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 16
            Width = 65
          end
          object txtNombreEmpleadoSolicitud: TcxDBTextEdit
            Left = 271
            Top = 184
            DataBinding.DataField = 'NOMBRE_EMPLEADO_TRSOL'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 17
            Width = 260
          end
          object lblObservacionesSolicitud: TcxLabel
            Left = 550
            Top = 71
            Caption = 'Observaciones'
            Transparent = True
          end
          object memObservacionesSolicitud: TcxDBMemo
            Left = 690
            Top = 68
            Anchors = [akLeft, akTop, akRight]
            DataBinding.DataField = 'OBSERVACIONES_TRSOL'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            Properties.ScrollBars = ssVertical
            TabOrder = 18
            Height = 64
            Width = 230
          end
          object lblMotivosRechazoSolicitud: TcxLabel
            Left = 550
            Top = 145
            Caption = 'Motivos rechazo'
            Transparent = True
          end
          object memMotivosRechazoSolicitud: TcxDBMemo
            Left = 690
            Top = 142
            Anchors = [akLeft, akTop, akRight]
            DataBinding.DataField = 'MOTIVOS_RECHAZO_TRSOL'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            Properties.ScrollBars = ssVertical
            TabOrder = 19
            Height = 64
            Width = 230
          end
        end
        object pcDetalleSolicitud: TcxPageControl
          Left = 0
          Top = 220
          Width = 943
          Height = 264
          Align = alClient
          TabOrder = 1
          Properties.ActivePage = tsArticulosSolicitud
          Properties.CustomButtons.Buttons = <>
          ClientRectBottom = 260
          ClientRectLeft = 4
          ClientRectRight = 939
          ClientRectTop = 30
          object tsArticulosSolicitud: TcxTabSheet
            Caption = 'Art'#237'culos solicitados'
            object cxgrdLineasSolicitud: TcxGrid
              Left = 0
              Top = 0
              Width = 727
              Height = 230
              Align = alClient
              TabOrder = 0
              object tvLineasSolicitud: TcxGridDBTableView
                Navigator.Buttons.CustomButtons = <>
                ScrollbarAnnotations.CustomAnnotations = <>
                OptionsData.Deleting = False
                OptionsData.Editing = False
                OptionsData.Inserting = False
                OptionsView.GroupByBox = False
                object tvLineasLINEA_TRSOLLIN: TcxGridDBColumn
                  Caption = 'L'#237'nea'
                  DataBinding.FieldName = 'LINEA_TRSOLLIN'
                  Width = 60
                end
                object tvLineasCODIGO_ART_TRSOLLIN: TcxGridDBColumn
                  Caption = 'Art'#237'culo'
                  DataBinding.FieldName = 'CODIGO_ART_TRSOLLIN'
                  Width = 110
                end
                object tvLineasCODIGO_UNIDAD_TRSOLLIN: TcxGridDBColumn
                  Caption = 'SKU / unidad'
                  DataBinding.FieldName = 'CODIGO_UNIDAD_TRSOLLIN'
                  Width = 150
                end
                object tvLineasDESCRIPCION_ART: TcxGridDBColumn
                  Caption = 'Descripci'#243'n'
                  DataBinding.FieldName = 'DESCRIPCION_ART'
                  Width = 240
                end
                object tvLineasCANTIDAD_PEDIDA_TRSOLLIN: TcxGridDBColumn
                  Caption = 'Pedida'
                  DataBinding.FieldName = 'CANTIDAD_PEDIDA_TRSOLLIN'
                  PropertiesClassName = 'TcxCurrencyEditProperties'
                  Properties.DisplayFormat = '#,##0.###'
                  Width = 80
                end
                object tvLineasCANTIDAD_SERVIDA_TRSOLLIN: TcxGridDBColumn
                  Caption = 'Servida'
                  DataBinding.FieldName = 'CANTIDAD_SERVIDA_TRSOLLIN'
                  PropertiesClassName = 'TcxCurrencyEditProperties'
                  Properties.DisplayFormat = '#,##0.###'
                  Width = 80
                end
                object tvLineasCANTIDAD_PENDIENTE_TRSOLLIN: TcxGridDBColumn
                  Caption = 'No servida'
                  DataBinding.FieldName = 'CANTIDAD_PENDIENTE_TRSOLLIN'
                  PropertiesClassName = 'TcxCurrencyEditProperties'
                  Properties.DisplayFormat = '#,##0.###'
                  Width = 85
                end
                object tvLineasESATENDIDA_TRSOLLIN: TcxGridDBColumn
                  Caption = 'Atendida'
                  DataBinding.FieldName = 'ESATENDIDA_TRSOLLIN'
                  PropertiesClassName = 'TcxCheckBoxProperties'
                  Properties.ValueChecked = 'S'
                  Properties.ValueUnchecked = 'N'
                  Width = 75
                end
                object tvLineasMOTIVO_RECHAZO_TRSOLLIN: TcxGridDBColumn
                  Caption = 'Motivo de rechazo'
                  DataBinding.FieldName = 'MOTIVO_RECHAZO_TRSOLLIN'
                  Width = 260
                end
                object tvLineasINSTANTE_MODIF: TcxGridDBColumn
                  Caption = 'Fecha y hora de atenci'#243'n'
                  DataBinding.FieldName = 'INSTANTE_MODIF'
                  PropertiesClassName = 'TcxDateEditProperties'
                  Properties.DisplayFormat = 'dd/mm/yyyy hh:nn:ss'
                  Width = 165
                end
              end
              object lvLineasSolicitud: TcxGridLevel
                GridView = tvLineasSolicitud
              end
            end
            object splFotoArticuloSolicitud: TcxSplitter
              Left = 727
              Top = 0
              Width = 8
              Height = 230
              AlignSplitter = salRight
              Control = pnlFotoArticuloSolicitud
            end
            object pnlFotoArticuloSolicitud: TPanel
              Left = 735
              Top = 0
              Width = 200
              Height = 230
              Align = alRight
              BevelOuter = bvLowered
              TabOrder = 1
              object imgFotoArticuloSolicitud: TImage
                Left = 1
                Top = 1
                Width = 198
                Height = 228
                Align = alClient
                Center = True
                Proportional = True
                Stretch = True
              end
            end
          end
          object tsTraspasoRealizado: TcxTabSheet
            Caption = 'Traspaso realizado'
            TabVisible = False
            object pnlTraspasosRealizados: TPanel
              Left = 0
              Top = 0
              Width = 935
              Height = 105
              Align = alTop
              BevelOuter = bvNone
              TabOrder = 0
              object cxgrdTraspasosRealizados: TcxGrid
                Left = 0
                Top = 0
                Width = 935
                Height = 105
                Align = alClient
                TabOrder = 0
                object tvTraspasosRealizados: TcxGridDBTableView
                  Navigator.Buttons.CustomButtons = <>
                  ScrollbarAnnotations.CustomAnnotations = <>
                  OptionsData.Deleting = False
                  OptionsData.Editing = False
                  OptionsData.Inserting = False
                  OptionsView.GroupByBox = False
                  object tvTraspasosNUMERO_OPERACION_OPCAJA: TcxGridDBColumn
                    Caption = 'Operaci'#243'n'
                    DataBinding.FieldName = 'NUMERO_OPERACION_OPCAJA'
                    Width = 110
                  end
                  object tvTraspasosFECHA_OPERACION_OPCAJA: TcxGridDBColumn
                    Caption = 'Fecha y hora'
                    DataBinding.FieldName = 'FECHA_OPERACION_OPCAJA'
                    PropertiesClassName = 'TcxDateEditProperties'
                    Properties.DisplayFormat = 'dd/mm/yyyy hh:nn:ss'
                    Width = 155
                  end
                  object tvTraspasosCODIGO_EMP_OPCAJA: TcxGridDBColumn
                    Caption = 'Empresa origen'
                    DataBinding.FieldName = 'CODIGO_EMP_OPCAJA'
                    Width = 95
                  end
                  object tvTraspasosCODIGO_ALM_OPCAJA: TcxGridDBColumn
                    Caption = 'Almac'#233'n origen'
                    DataBinding.FieldName = 'CODIGO_ALM_OPCAJA'
                    Width = 105
                  end
                  object tvTraspasosCODIGO_EMP_CONTRA_OPCAJA: TcxGridDBColumn
                    Caption = 'Empresa destino'
                    DataBinding.FieldName = 'CODIGO_EMP_CONTRA_OPCAJA'
                    Width = 100
                  end
                  object tvTraspasosCODIGO_ALM_CONTRA_OPCAJA: TcxGridDBColumn
                    Caption = 'Almac'#233'n destino'
                    DataBinding.FieldName = 'CODIGO_ALM_CONTRA_OPCAJA'
                    Width = 105
                  end
                  object tvTraspasosCODIGO_CAJA_OPCAJA: TcxGridDBColumn
                    Caption = 'Caja'
                    DataBinding.FieldName = 'CODIGO_CAJA_OPCAJA'
                    Width = 65
                  end
                  object tvTraspasosCODIGO_EMPLEADO_OPCAJA: TcxGridDBColumn
                    Caption = 'Empleado'
                    DataBinding.FieldName = 'CODIGO_EMPLEADO_OPCAJA'
                    Width = 85
                  end
                  object tvTraspasosNOMBRE_EMPLEADO_OPCAJA: TcxGridDBColumn
                    Caption = 'Nombre empleado'
                    DataBinding.FieldName = 'NOMBRE_EMPLEADO_OPCAJA'
                    Width = 160
                  end
                  object tvTraspasosDOCUMENTO_OPCAJA: TcxGridDBColumn
                    Caption = 'Documento'
                    DataBinding.FieldName = 'DOCUMENTO_OPCAJA'
                    Width = 130
                  end
                  object tvTraspasosIMPORTE_TOTAL_OPCAJA: TcxGridDBColumn
                    Caption = 'Importe'
                    DataBinding.FieldName = 'IMPORTE_TOTAL_OPCAJA'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Width = 90
                  end
                end
                object lvTraspasosRealizados: TcxGridLevel
                  GridView = tvTraspasosRealizados
                end
              end
            end
            object splMovimientosTraspaso: TcxSplitter
              Left = 0
              Top = 105
              Width = 935
              Height = 8
              AlignSplitter = salTop
              Control = pnlTraspasosRealizados
            end
            object pnlMovimientosTraspaso: TPanel
              Left = 0
              Top = 113
              Width = 935
              Height = 117
              Align = alClient
              BevelOuter = bvNone
              TabOrder = 2
              object cxgrdMovimientosTraspaso: TcxGrid
                Left = 0
                Top = 0
                Width = 935
                Height = 117
                Align = alClient
                TabOrder = 0
                object tvMovimientosTraspaso: TcxGridDBTableView
                  Navigator.Buttons.CustomButtons = <>
                  ScrollbarAnnotations.CustomAnnotations = <>
                  OptionsData.Deleting = False
                  OptionsData.Editing = False
                  OptionsData.Inserting = False
                  OptionsView.GroupByBox = False
                  object tvMovimientosNUMERO_MOV: TcxGridDBColumn
                    Caption = 'Movimiento'
                    DataBinding.FieldName = 'NUMERO_MOV'
                    Width = 100
                  end
                  object tvMovimientosFECHA_MOV: TcxGridDBColumn
                    Caption = 'Fecha y hora'
                    DataBinding.FieldName = 'FECHA_MOV'
                    PropertiesClassName = 'TcxDateEditProperties'
                    Properties.DisplayFormat = 'dd/mm/yyyy hh:nn:ss'
                    Width = 150
                  end
                  object tvMovimientosLINEA_MOV: TcxGridDBColumn
                    Caption = 'L'#237'nea'
                    DataBinding.FieldName = 'LINEA_MOV'
                    Width = 60
                  end
                  object tvMovimientosCODIGO_ALM_MOV: TcxGridDBColumn
                    Caption = 'Almac'#233'n origen'
                    DataBinding.FieldName = 'CODIGO_ALM_MOV'
                    Width = 105
                  end
                  object tvMovimientosCODIGO_ALM_CONTRA_MOV: TcxGridDBColumn
                    Caption = 'Almac'#233'n destino'
                    DataBinding.FieldName = 'CODIGO_ALM_CONTRA_MOV'
                    Width = 110
                  end
                  object tvMovimientosCODIGO_ART_MOV: TcxGridDBColumn
                    Caption = 'Art'#237'culo'
                    DataBinding.FieldName = 'CODIGO_ART_MOV'
                    Width = 110
                  end
                  object tvMovimientosCODIGO_UNIDAD_MOV: TcxGridDBColumn
                    Caption = 'SKU / unidad'
                    DataBinding.FieldName = 'CODIGO_UNIDAD_MOV'
                    Width = 150
                  end
                  object tvMovimientosDESCRIPCION_ART: TcxGridDBColumn
                    Caption = 'Descripci'#243'n'
                    DataBinding.FieldName = 'DESCRIPCION_ART'
                    Width = 230
                  end
                  object tvMovimientosTIPO_MOV: TcxGridDBColumn
                    Caption = 'Tipo'
                    DataBinding.FieldName = 'TIPO_MOV'
                    Width = 70
                  end
                  object tvMovimientosCANTIDAD_MOV: TcxGridDBColumn
                    Caption = 'Cantidad'
                    DataBinding.FieldName = 'CANTIDAD_MOV'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = '#,##0.###'
                    Width = 85
                  end
                  object tvMovimientosPRECIO_MEDIO_MOV: TcxGridDBColumn
                    Caption = 'Precio medio'
                    DataBinding.FieldName = 'PRECIO_MEDIO_MOV'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = '#,##0.0000'
                    Width = 95
                  end
                  object tvMovimientosTOTAL_COSTE_MOV: TcxGridDBColumn
                    Caption = 'Coste total'
                    DataBinding.FieldName = 'TOTAL_COSTE_MOV'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Width = 95
                  end
                end
                object lvMovimientosTraspaso: TcxGridLevel
                  GridView = tvMovimientosTraspaso
                end
              end
            end
          end
        end
      end
      inherited tsPerfil: TcxTabSheet
        Caption = '&3_Perfil'
        TabVisible = False
        inherited pnlPerfilTop: TPanel
          inherited edtPerfilBusq: TcxTextEdit
            ExplicitHeight = 27
          end
        end
      end
    end
    inherited pnlTopPage: TPanel
      inherited pnlTopGrid: TPanel
        inherited edtBusqGlobal: TcxTextEdit
          ExplicitHeight = 27
        end
        inherited nvNavegador: TcxDBNavigator
          Width = 240
          ExplicitWidth = 240
        end
      end
    end
  end
  inherited pButtonRightBar: TPanel
    object btnImprimirDuplicadoSolicitud: TcxButton
      Left = 1
      Top = 120
      Width = 138
      Height = 48
      Action = actImprimirDuplicadoSolicitud
      TabOrder = 2
      WordWrap = True
    end
    object btnListadoSolicitudes: TcxButton
      Left = 1
      Top = 172
      Width = 138
      Height = 48
      Caption = 'Listado solicitudes'
      TabOrder = 3
      WordWrap = True
      OnClick = btnListadoSolicitudesClick
    end
  end
  object alSolicitudesTraspasoHist: TActionList
    Left = 744
    Top = 448
    object actImprimirDuplicadoSolicitud: TAction
      Caption = 'Imprimir duplicado'
      OnExecute = actImprimirDuplicadoSolicitudExecute
      OnUpdate = actImprimirDuplicadoSolicitudUpdate
    end
  end
end
