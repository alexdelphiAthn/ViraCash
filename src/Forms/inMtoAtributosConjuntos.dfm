inherited frmMtoAtributosConjuntos: TfrmMtoAtributosConjuntos
  Caption = 'Colecciones de Atributos'
  StyleElements = [seFont, seClient, seBorder]
  TextHeight = 19
  inherited pButtonPage: TPanel
    StyleElements = [seFont, seClient, seBorder]
    inherited pcPantalla: TcxPageControl
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 2
        ExplicitTop = 29
        ExplicitWidth = 947
        ExplicitHeight = 487
        inherited cxGrdPrincipal: TcxGrid
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            object cxGrdDBTabPrinID_AC: TcxGridDBColumn
              Caption = 'ID Conjunto'
              DataBinding.FieldName = 'ID_AC'
              Options.Editing = False
              Width = 128
            end
            object cxGrdDBTabPrinNOMBRE_AC: TcxGridDBColumn
              Caption = 'Nombre'
              DataBinding.FieldName = 'NOMBRE_AC'
              Width = 280
            end
            object cxGrdDBTabPrinID_VA_AC: TcxGridDBColumn
              Caption = 'Atributo'
              DataBinding.FieldName = 'ID_VA_AC'
              PropertiesClassName = 'TcxLookupComboBoxProperties'
              Properties.KeyFieldNames = 'ID_ATB_VA'
              Properties.ListColumns = <
                item
                  Caption = 'C'#243'digo'
                  Width = 60
                  FieldName = 'ID_ATB_VA'
                end
                item
                  Caption = 'Nombre'
                  Width = 220
                  FieldName = 'NOMBRE_VA'
                end>
              Properties.ListOptions.CaseInsensitive = True
              Width = 180
            end
            object cxGrdDBTabPrinESACTIVO_AC: TcxGridDBColumn
              Caption = 'Activo'
              DataBinding.FieldName = 'ESACTIVO_AC'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 80
            end
            object cxGrdDBTabPrinINSTANTE_ALTA: TcxGridDBColumn
              Caption = 'Instante Alta'
              DataBinding.FieldName = 'INSTANTE_ALTA'
              Visible = False
              Options.Editing = False
              Width = 150
            end
            object cxGrdDBTabPrinINSTANTE_MODIF: TcxGridDBColumn
              Caption = 'Instante Modif'
              DataBinding.FieldName = 'INSTANTE_MODIF'
              Visible = False
              Options.Editing = False
              Width = 150
            end
            object cxGrdDBTabPrinUSUARIO_ALTA: TcxGridDBColumn
              Caption = 'Usuario Alta'
              DataBinding.FieldName = 'USUARIO_ALTA'
              Visible = False
              Options.Editing = False
              Width = 130
            end
            object cxGrdDBTabPrinUSUARIO_MODIF: TcxGridDBColumn
              Caption = 'Usuario Modif'
              DataBinding.FieldName = 'USUARIO_MODIF'
              Visible = False
              Options.Editing = False
              Width = 130
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        ExplicitLeft = 2
        ExplicitTop = 29
        ExplicitWidth = 947
        ExplicitHeight = 487
        object pnlTopFicha: TPanel
          Left = 0
          Top = 0
          Width = 947
          Height = 105
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          object pnlBodyFicha: TPanel
            Left = 0
            Top = 0
            Width = 947
            Height = 105
            Align = alClient
            BevelOuter = bvNone
            TabOrder = 0
            object lblNombre: TcxLabel
              Left = 52
              Top = 16
              Caption = 'Nombre'
              TabOrder = 3
              Transparent = True
            end
            object txtNOMBRE_AC: TcxDBTextEdit
              Left = 127
              Top = 13
              DataBinding.DataField = 'NOMBRE_AC'
              DataBinding.DataSource = dsTablaG
              TabOrder = 0
              Width = 360
            end
            object chkESACTIVO_AC: TcxDBCheckBox
              Left = 500
              Top = 16
              Caption = 'Activo'
              DataBinding.DataField = 'ESACTIVO_AC'
              DataBinding.DataSource = dsTablaG
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              TabOrder = 1
              Transparent = True
            end
            object lblIdVa: TcxLabel
              Left = 48
              Top = 48
              Caption = 'Atributo'
              TabOrder = 5
              Transparent = True
            end
            object cbbID_VA_AC: TcxDBLookupComboBox
              Left = 127
              Top = 45
              DataBinding.DataField = 'ID_VA_AC'
              DataBinding.DataSource = dsTablaG
              Properties.KeyFieldNames = 'ID_ATB_VA'
              Properties.ListColumns = <
                item
                  Caption = 'C'#243'digo'
                  Width = 60
                  FieldName = 'ID_ATB_VA'
                end
                item
                  Caption = 'Nombre'
                  Width = 220
                  FieldName = 'NOMBRE_VA'
                end>
              Properties.ListOptions.CaseInsensitive = True
              TabOrder = 2
              Width = 220
            end
            object lblIdAc: TcxLabel
              Left = 16
              Top = 78
              Caption = 'ID Conjunto'
              TabOrder = 6
              Transparent = True
            end
            object txtID_AC: TcxDBTextEdit
              Left = 127
              Top = 75
              DataBinding.DataField = 'ID_AC'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = True
              TabOrder = 7
              Width = 100
            end
            object lblIdVaDesc: TcxLabel
              Left = 360
              Top = 48
              TabOrder = 8
              Transparent = True
            end
          end
        end
        object splSplitterFicha: TcxSplitter
          Left = 0
          Top = 105
          Width = 947
          Height = 10
          HotZoneClassName = 'TcxMediaPlayer9Style'
          AlignSplitter = salTop
          Control = pnlButtonFicha
        end
        object pnlButtonFicha: TPanel
          Left = 0
          Top = 115
          Width = 947
          Height = 372
          Align = alClient
          BevelOuter = bvNone
          TabOrder = 2
          object pcDetail: TcxPageControl
            Left = 0
            Top = 0
            Width = 947
            Height = 372
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsValores
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 370
            ClientRectLeft = 2
            ClientRectRight = 945
            ClientRectTop = 29
            object tsValores: TcxTabSheet
              Caption = '&1_Valores'
              ImageIndex = 0
              object cxgrdValores: TcxGrid
                Left = 0
                Top = 0
                Width = 943
                Height = 341
                Align = alClient
                TabOrder = 0
                object tvValores: TcxGridDBTableView
                  OptionsBehavior.AlwaysShowEditor = True
                  OptionsBehavior.IncSearch = False
                  OptionsBehavior.ImmediateEditor = True
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
                  OptionsView.NoDataToDisplayInfoText = '<No hay valores en este conjunto>'
                  OptionsView.GroupByBox = False
                  OptionsView.Indicator = True
                  object tvValoresID_AC_ACD: TcxGridDBColumn
                    Caption = 'ID Conjunto'
                    DataBinding.FieldName = 'ID_AC_ACD'
                    Visible = False
                    Options.Editing = False
                    Width = 110
                  end
                  object tvValoresAV: TcxGridDBColumn
                    Caption = 'Valor'
                    DataBinding.FieldName = 'AV'
                    PropertiesClassName = 'TcxTextEditProperties'
                    Properties.MaxLength = 100
                    Width = 220
                  end
                  object tvValoresORDEN_ACD: TcxGridDBColumn
                    Caption = 'Orden'
                    DataBinding.FieldName = 'ORDEN_ACD'
                    PropertiesClassName = 'TcxSpinEditProperties'
                    HeaderAlignmentHorz = taRightJustify
                    Width = 100
                  end
                  object tvValoresID_ATB_ACD: TcxGridDBColumn
                    Caption = 'Atributo b'#225'sico'
                    DataBinding.FieldName = 'ID_ATB_ACD'
                    PropertiesClassName = 'TcxLookupComboBoxProperties'
                    Properties.DropDownAutoSize = True
                    Properties.DropDownSizeable = True
                    Properties.ImmediatePost = True
                    Properties.KeyFieldNames = 'ID_ATB'
                    Properties.ListColumns = <
                      item
                        Caption = 'C'#243'digo'
                        Width = 90
                        FieldName = 'CODIGO_ATB'
                      end
                      item
                        Caption = 'Nombre'
                        Width = 140
                        FieldName = 'NOMBRE_ATB'
                      end
                      item
                        Caption = 'Paleta'
                        Width = 70
                        FieldName = 'HEX_ATB'
                      end
                      item
                        Caption = 'Valor'
                        Width = 60
                        FieldName = 'VALOR_NUM_ATB'
                      end
                      item
                        Caption = 'Ud'
                        Width = 40
                        FieldName = 'UNIDAD_ATB'
                      end>
                    Properties.ListFieldIndex = 1
                    Properties.ListOptions.CaseInsensitive = True
                    Properties.ListOptions.ShowHeader = True
                    Width = 220
                  end
                end
                object cxgrdlvlValores: TcxGridLevel
                  GridView = tvValores
                end
              end
            end
            object tsArticulos: TcxTabSheet
              Caption = '&2_Art'#237'culos'
              ImageIndex = 1
              object cxgrdArticulos: TcxGrid
                Left = 0
                Top = 0
                Width = 943
                Height = 341
                Align = alClient
                TabOrder = 0
                object tvArticulos: TcxGridDBTableView
                  Navigator.Visible = True
                  DataController.DataModeController.SmartRefresh = True
                  OptionsCustomize.ColumnGrouping = False
                  OptionsData.Deleting = False
                  OptionsData.Editing = False
                  OptionsData.Inserting = False
                  OptionsView.NoDataToDisplayInfoText = '<Ning'#250'n art'#237'culo usa esta colecci'#243'n>'
                  OptionsView.GroupByBox = False
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
                end
                object cxgrdlvlArticulos: TcxGridLevel
                  GridView = tvArticulos
                end
              end
            end
            object tsAuditoria: TcxTabSheet
              Caption = '&3_Otros'
              ImageIndex = 2
              object pnlAuditoria: TPanel
                Left = 0
                Top = 0
                Width = 943
                Height = 341
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
          StyleElements = [seFont, seClient, seBorder]
          inherited edtPerfilBusq: TcxTextEdit
            ExplicitHeight = 27
          end
        end
        inherited pnlPerfilDetail: TPanel
          StyleElements = [seFont, seClient, seBorder]
        end
      end
    end
    inherited pnlTopPage: TPanel
      StyleElements = [seFont, seClient, seBorder]
      inherited pnlTopGrid: TPanel
        StyleElements = [seFont, seClient, seBorder]
        inherited edtBusqGlobal: TcxTextEdit
          ExplicitHeight = 27
        end
      end
    end
  end
  inherited pButtonRightBar: TPanel
    StyleElements = [seFont, seClient, seBorder]
    inherited pButtonGen: TPanel
      StyleElements = [seFont, seClient, seBorder]
    end
    inherited pButtonBDStat: TPanel
      StyleElements = [seFont, seClient, seBorder]
      inherited pnStateDataSet: TPanel
        StyleElements = [seFont, seClient, seBorder]
      end
      inherited pnlDataSetName: TPanel
        StyleElements = [seFont, seClient, seBorder]
      end
    end
  end
  inherited dsTablaG: TDataSource
    OnDataChange = dsTablaGDataChange
    Left = 104
    Top = 424
  end
  object alConjuntos: TActionList
    Left = 216
    Top = 312
    object actArticulo: TAction
      Caption = 'Articulo'
      ShortCut = 16466
      OnExecute = actArticuloExecute
    end
  end
end
