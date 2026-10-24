inherited frmMtoVariaciones: TfrmMtoVariaciones
  Caption = 'Tipos de Variaciones'
  TextHeight = 19
  inherited pButtonPage: TPanel
    inherited pcPantalla: TcxPageControl
      Properties.ActivePage = tsLista
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 30
        ExplicitWidth = 943
        ExplicitHeight = 484
        inherited cxGrdPrincipal: TcxGrid
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            OptionsData.Editing = True
            object cxGrdDBTabPrinCODIGO_VAR: TcxGridDBColumn
              Caption = 'C'#243'digo'
              DataBinding.FieldName = 'CODIGO_VAR'
              Options.Editing = False
              Width = 110
            end
            object cxGrdDBTabPrinNOMBRE_VAR: TcxGridDBColumn
              Caption = 'Nombre'
              DataBinding.FieldName = 'NOMBRE_VAR'
              Width = 320
            end
            object cxGrdDBTabPrinESACTIVO_VAR: TcxGridDBColumn
              Caption = 'Activo'
              DataBinding.FieldName = 'ESACTIVO_VAR'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 80
            end
            object cxGrdDBTabPrinORDEN_VAR: TcxGridDBColumn
              Caption = 'Orden'
              DataBinding.FieldName = 'ORDEN_VAR'
              PropertiesClassName = 'TcxSpinEditProperties'
              HeaderAlignmentHorz = taRightJustify
              Width = 90
            end
            object cxGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn
              Caption = 'Instante Alta'
              DataBinding.FieldName = 'INSTANTE_ALTA'
              Options.Editing = False
              Width = 150
            end
            object cxGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn
              Caption = 'Instante Modif'
              DataBinding.FieldName = 'INSTANTE_MODIF'
              Options.Editing = False
              Visible = False
              Width = 150
            end
            object cxGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn
              Caption = 'Usuario Alta'
              DataBinding.FieldName = 'USUARIO_ALTA'
              Options.Editing = False
              Width = 130
            end
            object cxGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn
              Caption = 'Usuario Modif'
              DataBinding.FieldName = 'USUARIO_MODIF'
              Options.Editing = False
              Visible = False
              Width = 130
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 30
        ExplicitWidth = 943
        ExplicitHeight = 484
        object pnlTopFicha: TPanel
          Left = 0
          Top = 0
          Width = 943
          Height = 105
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          object pnlBodyFicha: TPanel
            Left = 0
            Top = 0
            Width = 943
            Height = 105
            Align = alClient
            BevelOuter = bvNone
            TabOrder = 0
            object lblCodigo: TcxLabel
              Left = 16
              Top = 16
              Caption = 'C'#243'digo'
              TabOrder = 4
              Transparent = True
            end
            object txtCODIGO_VAR: TcxDBTextEdit
              Left = 120
              Top = 13
              DataBinding.DataField = 'CODIGO_VAR'
              DataBinding.DataSource = dsTablaG
              TabOrder = 0
              Width = 140
            end
            object lblNombre: TcxLabel
              Left = 16
              Top = 48
              Caption = 'Nombre'
              TabOrder = 5
              Transparent = True
            end
            object txtNOMBRE_VAR: TcxDBTextEdit
              Left = 120
              Top = 45
              DataBinding.DataField = 'NOMBRE_VAR'
              DataBinding.DataSource = dsTablaG
              TabOrder = 1
              Width = 360
            end
            object chkESACTIVO_VAR: TcxDBCheckBox
              Left = 280
              Top = 16
              Caption = 'Activo'
              DataBinding.DataField = 'ESACTIVO_VAR'
              DataBinding.DataSource = dsTablaG
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              TabOrder = 2
              Transparent = True
            end
            object lblOrden: TcxLabel
              Left = 16
              Top = 78
              Caption = 'Orden'
              TabOrder = 6
              Transparent = True
            end
            object spnORDEN_VAR: TcxDBSpinEdit
              Left = 120
              Top = 75
              DataBinding.DataField = 'ORDEN_VAR'
              DataBinding.DataSource = dsTablaG
              TabOrder = 3
              Width = 100
            end
            object lblRotuloOtro: TcxLabel
              Left = 500
              Top = 48
              Caption = 'Bot'#243'n "Otro..." en sesiones'
              TabOrder = 7
              Transparent = True
            end
            object txtROTULO_OTRO_VAR: TcxDBTextEdit
              Left = 680
              Top = 45
              DataBinding.DataField = 'ROTULO_OTRO_VAR'
              DataBinding.DataSource = dsTablaG
              TabOrder = 8
              Width = 200
            end
            object chkESCOLOR_BASICO_VAR: TcxDBCheckBox
              Left = 280
              Top = 78
              Caption = 'La fila es un color con color b'#225'sico'
              DataBinding.DataField = 'ESCOLOR_BASICO_VAR'
              DataBinding.DataSource = dsTablaG
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              TabOrder = 9
              Transparent = True
            end
          end
        end
        object splSplitterFicha: TcxSplitter
          Left = 0
          Top = 105
          Width = 943
          Height = 8
          HotZoneClassName = 'TcxMediaPlayer9Style'
          AlignSplitter = salTop
          Control = pnlButtonFicha
        end
        object pnlButtonFicha: TPanel
          Left = 0
          Top = 113
          Width = 943
          Height = 371
          Align = alClient
          BevelOuter = bvNone
          TabOrder = 2
          object pcDetail: TcxPageControl
            Left = 0
            Top = 0
            Width = 943
            Height = 371
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsAtributos
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 367
            ClientRectLeft = 4
            ClientRectRight = 939
            ClientRectTop = 30
            object tsAtributos: TcxTabSheet
              Caption = '&1_Atributos'
              ImageIndex = 0
              object cxgrdAtributos: TcxGrid
                Left = 0
                Top = 0
                Width = 935
                Height = 337
                Align = alClient
                TabOrder = 0
                object tvAtributos: TcxGridDBTableView
                  Navigator.Buttons.ConfirmDelete = True
                  Navigator.Buttons.Insert.Visible = True
                  Navigator.Buttons.Delete.Visible = True
                  Navigator.Buttons.Post.Visible = True
                  Navigator.Buttons.Cancel.Visible = True
                  Navigator.Visible = True
                  DataController.DataModeController.SmartRefresh = True
                  OptionsBehavior.GoToNextCellOnEnter = True
                  OptionsCustomize.ColumnGrouping = False
                  OptionsData.Appending = True
                  OptionsView.GroupByBox = False
                  OptionsView.Indicator = True
                  OptionsView.NoDataToDisplayInfoText = '<No hay atributos para este tipo de variaci'#243'n>'
                  object tvAtributosID_VAR_VA: TcxGridDBColumn
                    Caption = 'C'#243'digo Variaci'#243'n'
                    DataBinding.FieldName = 'ID_VAR_VA'
                    Options.Editing = False
                    Visible = False
                    Width = 130
                  end
                  object tvAtributosID_ATB_VA: TcxGridDBColumn
                    Caption = 'C'#243'digo Atributo'
                    DataBinding.FieldName = 'ID_ATB_VA'
                    Width = 140
                  end
                  object tvAtributosNOMBRE_VA: TcxGridDBColumn
                    Caption = 'Nombre'
                    DataBinding.FieldName = 'NOMBRE_VA'
                    Width = 280
                  end
                  object tvAtributosNOMBRE_VISIBLE_VA: TcxGridDBColumn
                    Caption = 'Nombre visible (colecciones)'
                    DataBinding.FieldName = 'NOMBRE_VISIBLE_VA'
                    Width = 240
                  end
                  object tvAtributosORDEN_VA: TcxGridDBColumn
                    Caption = 'Orden'
                    DataBinding.FieldName = 'ORDEN_VA'
                    PropertiesClassName = 'TcxSpinEditProperties'
                    HeaderAlignmentHorz = taRightJustify
                    Width = 100
                  end
                  object tvAtributosEJE_VA: TcxGridDBColumn
                    Caption = 'Eje'
                    DataBinding.FieldName = 'EJE_VA'
                    PropertiesClassName = 'TcxImageComboBoxProperties'
                    Width = 140
                  end
                end
                object cxgrdlvlAtributos: TcxGridLevel
                  GridView = tvAtributos
                end
              end
            end
            object tsArticulos: TcxTabSheet
              Caption = '&2_Art'#237'culos'
              ImageIndex = 1
              object pnlArticulos: TPanel
                Left = 0
                Top = 0
                Width = 935
                Height = 180
                Align = alTop
                BevelOuter = bvNone
                TabOrder = 0
                object cxgrdArticulos: TcxGrid
                  Left = 0
                  Top = 0
                  Width = 935
                  Height = 180
                  Align = alClient
                  TabOrder = 0
                  object tvArticulos: TcxGridDBTableView
                    Navigator.Buttons.ConfirmDelete = True
                    Navigator.Visible = True
                    DataController.DataModeController.SmartRefresh = True
                    OptionsCustomize.ColumnGrouping = False
                    OptionsData.Deleting = False
                    OptionsData.Editing = False
                    OptionsData.Inserting = False
                    OptionsView.GroupByBox = False
                    OptionsView.NoDataToDisplayInfoText = '<No hay art'#237'culos que usen este tipo de variaci'#243'n>'
                    object tvArticulosCODIGO_ART_ART: TcxGridDBColumn
                      Caption = 'C'#243'digo Art'#237'culo'
                      DataBinding.FieldName = 'CODIGO_ART_ART'
                      Width = 160
                    end
                    object tvArticulosDESCRIPCION_ART: TcxGridDBColumn
                      Caption = 'Descripci'#243'n'
                      DataBinding.FieldName = 'DESCRIPCION_ART'
                      Width = 320
                    end
                    object tvArticulosESACTIVO_ART: TcxGridDBColumn
                      Caption = 'Activo'
                      DataBinding.FieldName = 'ESACTIVO_ART'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Width = 70
                    end
                    object tvArticulosCODIGO_FAM_ART: TcxGridDBColumn
                      Caption = 'C'#243'digo Familia'
                      DataBinding.FieldName = 'CODIGO_FAM_ART'
                      Width = 130
                    end
                    object tvArticulosNOMBRE_FAM_FAM: TcxGridDBColumn
                      Caption = 'Familia'
                      DataBinding.FieldName = 'NOMBRE_FAM_FAM'
                      Width = 180
                    end
                    object tvArticulosESVARIACION_ART: TcxGridDBColumn
                      Caption = 'Tiene Variaciones'
                      DataBinding.FieldName = 'ESVARIACION_ART'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Width = 130
                    end
                  end
                  object cxgrdlvlArticulos: TcxGridLevel
                    GridView = tvArticulos
                  end
                end
              end
              object splArticulosSkus: TcxSplitter
                Left = 0
                Top = 180
                Width = 935
                Height = 8
                HotZoneClassName = 'TcxMediaPlayer9Style'
                AlignSplitter = salTop
                Control = pnlSkus
              end
              object pnlSkus: TPanel
                Left = 0
                Top = 188
                Width = 935
                Height = 149
                Align = alClient
                BevelOuter = bvNone
                TabOrder = 2
                object cxgrdSkus: TcxGrid
                  Left = 0
                  Top = 0
                  Width = 935
                  Height = 149
                  Align = alClient
                  TabOrder = 0
                  object tvSkus: TcxGridDBTableView
                    Navigator.Buttons.ConfirmDelete = True
                    Navigator.Visible = True
                    DataController.DataModeController.SmartRefresh = True
                    OptionsCustomize.ColumnGrouping = False
                    OptionsData.Deleting = False
                    OptionsData.Editing = False
                    OptionsData.Inserting = False
                    OptionsView.GroupByBox = False
                    OptionsView.NoDataToDisplayInfoText = '<Selecciona un art'#237'culo para ver sus SKUs>'
                    object tvSkusCODIGO_UNIDAD_SKU: TcxGridDBColumn
                      Caption = 'C'#243'digo SKU'
                      DataBinding.FieldName = 'CODIGO_UNIDAD_SKU'
                      Width = 280
                    end
                    object tvSkusCODIGO_ART_SKU: TcxGridDBColumn
                      Caption = 'C'#243'digo Art'#237'culo'
                      DataBinding.FieldName = 'CODIGO_ART_SKU'
                      Width = 160
                    end
                    object tvSkusCODIGO_VAR_SKU: TcxGridDBColumn
                      Caption = 'C'#243'digo Variaci'#243'n'
                      DataBinding.FieldName = 'CODIGO_VAR_SKU'
                      Width = 130
                    end
                    object tvSkusESACTIVO_SKU: TcxGridDBColumn
                      Caption = 'Activo'
                      DataBinding.FieldName = 'ESACTIVO_SKU'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Width = 70
                    end
                  end
                  object cxgrdlvlSkus: TcxGridLevel
                    GridView = tvSkus
                  end
                end
              end
            end
            object tsAuditoria: TcxTabSheet
              Caption = '&3_Otros'
              ImageIndex = 2
              object pnlAuditoria: TPanel
                Left = 0
                Top = 0
                Width = 935
                Height = 337
                Align = alClient
                BevelOuter = bvNone
                TabOrder = 0
                object lblUsuarioAlta: TcxLabel
                  Left = 16
                  Top = 16
                  Caption = 'Usuario Alta'
                  TabOrder = 4
                  Transparent = True
                end
                object txtUSUARIOALTA: TcxDBTextEdit
                  Left = 160
                  Top = 13
                  DataBinding.DataField = 'USUARIO_ALTA'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 0
                  Width = 200
                end
                object lblInstanteAlta: TcxLabel
                  Left = 16
                  Top = 48
                  Caption = 'Instante Alta'
                  TabOrder = 5
                  Transparent = True
                end
                object txtINSTANTEALTA: TcxDBTextEdit
                  Left = 160
                  Top = 45
                  DataBinding.DataField = 'INSTANTE_ALTA'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 1
                  Width = 200
                end
                object lblUsuarioModif: TcxLabel
                  Left = 400
                  Top = 16
                  Caption = 'Usuario Modificaci'#243'n'
                  TabOrder = 6
                  Transparent = True
                end
                object txtUSUARIOMODIF: TcxDBTextEdit
                  Left = 560
                  Top = 13
                  DataBinding.DataField = 'USUARIO_MODIF'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 2
                  Width = 200
                end
                object lblInstanteModif: TcxLabel
                  Left = 400
                  Top = 48
                  Caption = 'Instante Modificaci'#243'n'
                  TabOrder = 7
                  Transparent = True
                end
                object txtINSTANTEMODIF: TcxDBTextEdit
                  Left = 560
                  Top = 45
                  DataBinding.DataField = 'INSTANTE_MODIF'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 3
                  Width = 200
                end
              end
            end
          end
        end
      end
      inherited tsPerfil: TcxTabSheet
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
  inherited dsTablaG: TDataSource
    DataSet = dmVariaciones.unqryTablaG
    OnStateChange = dsTablaGStateChange
  end
end
