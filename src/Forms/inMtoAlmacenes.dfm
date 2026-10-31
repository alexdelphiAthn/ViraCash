inherited frmMtoAlmacenes: TfrmMtoAlmacenes
  Caption = 'Almacenes'
  StyleElements = [seFont, seClient, seBorder]
  TextHeight = 19
  inherited pButtonPage: TPanel
    StyleElements = [seFont, seClient, seBorder]
    inherited pcPantalla: TcxPageControl
      Properties.ActivePage = tsFicha
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 30
        ExplicitWidth = 943
        ExplicitHeight = 484
        inherited cxGrdPrincipal: TcxGrid
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            object dbcGrdDBTabPrinCODIGO_ALMACEN_ALM: TcxGridDBColumn
              Caption = 'C'#243'digo Almac'#233'n'
              DataBinding.FieldName = 'CODIGO_ALM_ALM'
              Width = 149
            end
            object dbcGrdDBTabPrinCODIGO_PADRE_ALM: TcxGridDBColumn
              Caption = 'C'#243'digo Padre'
              DataBinding.FieldName = 'CODIGO_PADRE_ALM'
              Width = 130
            end
            object dbcGrdDBTabPrinCODIGO_EMPRESA_ALM: TcxGridDBColumn
              Caption = 'C'#243'digo Empresa'
              DataBinding.FieldName = 'CODIGO_EMP_ALM'
              Width = 151
            end
            object dbcGrdDBTabPrinNOMBRE_ALMACEN_ALM: TcxGridDBColumn
              Caption = 'Nombre Almac'#233'n'
              DataBinding.FieldName = 'NOMBRE_ALM_ALM'
              Width = 250
            end
            object dbcGrdDBTabPrinESACTIVO_ALM: TcxGridDBColumn
              Caption = 'Activo'
              DataBinding.FieldName = 'ESACTIVO_ALM'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 89
            end
            object dbcGrdDBTabPrinESWEB_ALM: TcxGridDBColumn
              Caption = 'En web'
              DataBinding.FieldName = 'ESWEB_ALM'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.NullStyle = nssUnchecked
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 89
            end
            object dbcGrdDBTabPrinESFISICO_ALM: TcxGridDBColumn
              Caption = 'Es F'#237'sico'
              DataBinding.FieldName = 'ESFISICO_ALM'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 97
            end
            object dbcGrdDBTabPrinTIPO_USO_ALM: TcxGridDBColumn
              Caption = 'Tipo Uso'
              DataBinding.FieldName = 'TIPO_USO_ALM'
              Width = 100
            end
            object dbcGrdDBTabPrinDIRECCION_ALM: TcxGridDBColumn
              Caption = 'Direcci'#243'n'
              DataBinding.FieldName = 'DIRECCION_ALM'
              Width = 200
            end
            object dbcGrdDBTabPrinPOBLACION_ALM: TcxGridDBColumn
              Caption = 'Poblaci'#243'n'
              DataBinding.FieldName = 'POBLACION_ALM'
              Width = 150
            end
            object dbcGrdDBTabPrinCODIGO_POSTAL_ALM: TcxGridDBColumn
              Caption = 'C'#243'digo Postal'
              DataBinding.FieldName = 'CODIGO_POSTAL_ALM'
              Width = 154
            end
            object dbcGrdDBTabPrinTELEFONO_ALM: TcxGridDBColumn
              Caption = 'Tel'#233'fono'
              DataBinding.FieldName = 'TELEFONO_ALM'
              Width = 100
            end
            object dbcGrdDBTabPrinEMAIL_ALM: TcxGridDBColumn
              Caption = 'Email'
              DataBinding.FieldName = 'EMAIL_ALM'
              Width = 150
            end
            object dbcGrdDBTabPrinCODIGO_CLIENTE_ALM: TcxGridDBColumn
              Caption = 'C'#243'digo Cliente'
              DataBinding.FieldName = 'CODIGO_CLI_ALM'
              Width = 156
            end
            object dbcGrdDBTabPrinALMACEN_DESTINO_ACTUAL_ALM: TcxGridDBColumn
              Caption = 'Almac'#233'n Destino'
              DataBinding.FieldName = 'DESTINO_ACTUAL_ALM'
              Width = 155
            end
            object dbcGrdDBTabPrinALMACEN_ORIGEN_ACTUAL_ALM: TcxGridDBColumn
              Caption = 'Almac'#233'n Origen'
              DataBinding.FieldName = 'ORIGEN_ACTUAL_ALM'
              Width = 141
            end
            object dbcGrdDBTabPrinORDEN_ALM: TcxGridDBColumn
              Caption = 'Orden'
              DataBinding.FieldName = 'ORDEN_ALM'
              HeaderAlignmentHorz = taRightJustify
              Width = 129
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
          Height = 121
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          object pnlBodyFicha: TPanel
            Left = 0
            Top = 0
            Width = 943
            Height = 121
            Align = alClient
            BevelOuter = bvNone
            TabOrder = 0
            object lblCodigo: TcxLabel
              Left = 16
              Top = 16
              Caption = 'C'#243'digo Almac'#233'n'
              TabOrder = 4
              Transparent = True
            end
            object txtCODIGO_ALMACEN_ALM: TcxDBTextEdit
              Left = 164
              Top = 13
              DataBinding.DataField = 'CODIGO_ALM_ALM'
              DataBinding.DataSource = dsTablaG
              TabOrder = 0
              Width = 122
            end
            object lblCodigoEmpresa: TcxLabel
              Left = 17
              Top = 48
              Caption = 'C'#243'digo Empresa'
              TabOrder = 6
              Transparent = True
            end
            object txtCODIGO_EMPRESA_ALM: TcxDBTextEdit
              Left = 164
              Top = 45
              DataBinding.DataField = 'CODIGO_EMP_ALM'
              DataBinding.DataSource = dsTablaG
              TabOrder = 5
              Width = 150
            end
            object lblNombre: TcxLabel
              Left = 11
              Top = 80
              Caption = 'Nombre Almac'#233'n'
              TabOrder = 8
              Transparent = True
            end
            object txtNOMBRE_ALMACEN_ALM: TcxDBTextEdit
              Left = 163
              Top = 76
              DataBinding.DataField = 'NOMBRE_ALM_ALM'
              DataBinding.DataSource = dsTablaG
              TabOrder = 7
              Width = 313
            end
            object chkESACTIVO_ALM: TcxDBCheckBox
              Left = 300
              Top = 16
              Caption = 'Activo'
              DataBinding.DataField = 'ESACTIVO_ALM'
              DataBinding.DataSource = dsTablaG
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              TabOrder = 1
              Transparent = True
            end
            object chkESWEB_ALM: TcxDBCheckBox
              Left = 480
              Top = 16
              Caption = 'En web'
              DataBinding.DataField = 'ESWEB_ALM'
              DataBinding.DataSource = dsTablaG
              Properties.NullStyle = nssUnchecked
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              TabOrder = 10
              Transparent = True
            end
            object chkESFISICO_ALM: TcxDBCheckBox
              Left = 380
              Top = 16
              Caption = 'Es F'#237'sico'
              DataBinding.DataField = 'ESFISICO_ALM'
              DataBinding.DataSource = dsTablaG
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              TabOrder = 3
              Transparent = True
            end
            object lblOrden: TcxLabel
              Left = 343
              Top = 47
              Caption = 'Orden'
              TabOrder = 9
              Transparent = True
            end
            object spnORDEN_ALM: TcxDBSpinEdit
              Left = 404
              Top = 47
              DataBinding.DataField = 'ORDEN_ALM'
              DataBinding.DataSource = dsTablaG
              TabOrder = 2
              Width = 100
            end
          end
        end
        object pnlButtonFicha: TPanel
          Left = 0
          Top = 129
          Width = 943
          Height = 355
          Align = alClient
          BevelOuter = bvNone
          TabOrder = 2
          object pcDetail: TcxPageControl
            Left = 0
            Top = 0
            Width = 943
            Height = 355
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsDireccion
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 351
            ClientRectLeft = 4
            ClientRectRight = 939
            ClientRectTop = 30
            object tsDireccion: TcxTabSheet
              Caption = '&0_Direcci'#243'n f'#237'sica'
              ImageIndex = 3
              object lblTelefono: TcxLabel
                Left = 30
                Top = 122
                Caption = 'Tel'#233'fono'
                TabOrder = 0
                Transparent = True
              end
              object cxdbtxtdtTELEFONO_ALM: TcxDBTextEdit
                Left = 113
                Top = 118
                DataBinding.DataField = 'TELEFONO_ALM'
                DataBinding.DataSource = dsTablaG
                TabOrder = 9
                Width = 164
              end
              object lblEmail: TcxLabel
                Left = 43
                Top = 154
                Caption = 'Email'
                TabOrder = 1
                Transparent = True
              end
              object cxdbtxtdtEMAIL_ALM: TcxDBTextEdit
                Left = 113
                Top = 151
                DataBinding.DataField = 'EMAIL_ALM'
                DataBinding.DataSource = dsTablaG
                TabOrder = 10
                Width = 250
              end
              object lblPoblacion: TcxLabel
                Left = 23
                Top = 56
                Caption = 'Poblaci'#243'n'
                TabOrder = 2
                Transparent = True
              end
              object cxdbtxtdtCODPOSTAL: TcxDBTextEdit
                Left = 116
                Top = 53
                DataBinding.DataField = 'CODIGO_POSTAL_ALM'
                DataBinding.DataSource = dsTablaG
                TabOrder = 5
                Width = 79
              end
              object cxdbtxtdtPOBLACION_ALM: TcxDBTextEdit
                Left = 201
                Top = 54
                DataBinding.DataField = 'POBLACION_ALM'
                DataBinding.DataSource = dsTablaG
                TabOrder = 7
                Width = 223
              end
              object lblDireccion: TcxLabel
                Left = 25
                Top = 24
                Caption = 'Direcci'#243'n'
                TabOrder = 3
                Transparent = True
              end
              object cxdbtxtdtDIRECCION_ALM: TcxDBTextEdit
                Left = 115
                Top = 21
                DataBinding.DataField = 'DIRECCION_ALM'
                DataBinding.DataSource = dsTablaG
                TabOrder = 4
                Width = 373
              end
              object lblProvincia: TcxLabel
                Left = 23
                Top = 88
                Caption = 'Provincia'
                TabOrder = 6
                Transparent = True
              end
              object cxdbtxtdtPROVINCIA_ALM: TcxDBTextEdit
                Left = 116
                Top = 85
                DataBinding.DataField = 'PROVINCIA_ALM'
                DataBinding.DataSource = dsTablaG
                TabOrder = 8
                Width = 269
              end
            end
            object tsCajas: TcxTabSheet
              Caption = '&1 Cajas de Venta'
              ImageIndex = 1
              object pnlSeriesCli: TPanel
                Left = 0
                Top = 0
                Width = 935
                Height = 321
                Align = alClient
                BevelOuter = bvNone
                TabOrder = 0
                object cxgrdAlmacenCajas: TcxGrid
                  Left = 0
                  Top = 0
                  Width = 935
                  Height = 321
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Align = alClient
                  TabOrder = 0
                  object tvAlmacenesCajas: TcxGridDBTableView
                    OptionsBehavior.ImmediateEditor = True
                    Navigator.Buttons.ConfirmDelete = True
                    Navigator.Buttons.First.Hint = 'Va al primer Registro'
                    Navigator.Buttons.First.Visible = False
                    Navigator.Buttons.PriorPage.Hint = 'Va a la p'#225'gina anterior'
                    Navigator.Buttons.PriorPage.Visible = False
                    Navigator.Buttons.Prior.Hint = 'Va al Registro Anterior'
                    Navigator.Buttons.Prior.Visible = False
                    Navigator.Buttons.Next.Hint = 'Va al siguiente Registro'
                    Navigator.Buttons.Next.Visible = False
                    Navigator.Buttons.NextPage.Hint = 'Va a la p'#225'gina siguiente'
                    Navigator.Buttons.NextPage.Visible = False
                    Navigator.Buttons.Last.Hint = 'Va al '#250'ltimo registro'
                    Navigator.Buttons.Last.Visible = False
                    Navigator.Buttons.Insert.Hint = 'Inserta un nuevo Registro'
                    Navigator.Buttons.Insert.Visible = True
                    Navigator.Buttons.Delete.Hint = 'Borra el registro Activo'
                    Navigator.Buttons.Delete.Visible = True
                    Navigator.Buttons.Edit.Enabled = False
                    Navigator.Buttons.Edit.Hint = 'Edita registro Actual'
                    Navigator.Buttons.Edit.Visible = False
                    Navigator.Buttons.Post.Hint = 'Guarda Datos introducidos'
                    Navigator.Buttons.Post.Visible = True
                    Navigator.Buttons.Cancel.Hint = 'Cancela la edici'#243'n actual'
                    Navigator.Buttons.Cancel.Visible = True
                    Navigator.Buttons.Refresh.Hint = 'Refresca Datos Activos'
                    Navigator.Buttons.SaveBookmark.Enabled = False
                    Navigator.Buttons.SaveBookmark.Hint = 'Marca Registro Actual'
                    Navigator.Buttons.SaveBookmark.Visible = False
                    Navigator.Buttons.GotoBookmark.Enabled = False
                    Navigator.Buttons.GotoBookmark.Hint = 'Va al registro Marcado'
                    Navigator.Buttons.GotoBookmark.Visible = False
                    Navigator.Buttons.Filter.Hint = 'Filtro personalizado'
                    Navigator.Visible = True
                    DataController.DataSource = dmAlmacenes.dsAlmacenesCajas
                    DataController.Options = [dcoCaseInsensitive, dcoAssignGroupingValues, dcoAssignMasterDetailKeys, dcoSaveExpanding]
                    OptionsBehavior.FocusCellOnTab = True
                    OptionsBehavior.AlwaysShowEditor = True
                    OptionsBehavior.GoToNextCellOnEnter = True
                    OptionsBehavior.IncSearch = False
                    OptionsCustomize.ColumnHiding = True
                    OptionsData.Appending = True
                    OptionsView.GroupByBox = False
                    OptionsView.Indicator = True
                    object dbmAlmacenesCajasCODIGO_ALMACEN_ALMCAJ: TcxGridDBColumn
                      Caption = 'C'#243'digo Almac'#233'n'
                      DataBinding.FieldName = 'CODIGO_ALM_ALMCAJ'
                      Visible = False
                    end
                    object dbmAlmacenesCajasCODIGO_CAJA_ALMCAJ: TcxGridDBColumn
                      Caption = 'C'#243'digo Caja'
                      DataBinding.FieldName = 'CODIGO_CAJA_ALMCAJ'
                      Width = 177
                    end
                    object dbmAlmacenesCajasDESCRIPCION_ALMCAJ: TcxGridDBColumn
                      Caption = 'Descripci'#243'n'
                      DataBinding.FieldName = 'DESCRIPCION_ALMCAJ'
                    end
                  end
                  object lvAlmacenCajas: TcxGridLevel
                    GridView = tvAlmacenesCajas
                  end
                end
              end
            end
            object tsUsosAlmacen: TcxTabSheet
              Caption = '&2_Usos Almac'#233'n'
              ImageIndex = 2
              object lblAlmacenDestino: TcxLabel
                Left = 29
                Top = 105
                Caption = 'Almac'#233'n Destino'
                TabOrder = 0
                Transparent = True
              end
              object lblAlmacenOrigen: TcxLabel
                Left = 37
                Top = 74
                Caption = 'Almac'#233'n Origen'
                TabOrder = 1
                Transparent = True
              end
              object cxdbtxtdtALMACEN_ORIGEN_ACTUAL_ALM: TcxDBLookupComboBox
                Left = 199
                Top = 70
                DataBinding.DataField = 'ORIGEN_ACTUAL_ALM'
                DataBinding.DataSource = dsTablaG
                Properties.ClearKey = 46
                Properties.DropDownListStyle = lsFixedList
                Properties.DropDownRows = 15
                Properties.DropDownAutoSize = True
                Properties.KeyFieldNames = 'CODIGO_ALM_ALM'
                Properties.ListColumns = <
                  item
                    Caption = 'C'#243'digo'
                    Width = 110
                    FieldName = 'CODIGO_ALM_ALM'
                  end
                  item
                    Caption = 'Almac'#233'n'
                    Width = 220
                    FieldName = 'NOMBRE_ALM_ALM'
                  end
                  item
                    Caption = 'Empresa'
                    Width = 70
                    FieldName = 'CODIGO_EMP_ALM'
                  end
                  item
                    Caption = 'Tipo de uso'
                    Width = 100
                    FieldName = 'TIPO_USO_ALM'
                  end
                  item
                    Caption = 'Activo'
                    Width = 55
                    FieldName = 'ESACTIVO_ALM'
                  end>
                TabOrder = 2
                Width = 150
              end
              object cxdbtxtdtALMACEN_DESTINO_ACTUAL_ALM: TcxDBLookupComboBox
                Left = 199
                Top = 101
                DataBinding.DataField = 'DESTINO_ACTUAL_ALM'
                DataBinding.DataSource = dsTablaG
                Properties.ClearKey = 46
                Properties.DropDownListStyle = lsFixedList
                Properties.DropDownRows = 15
                Properties.DropDownAutoSize = True
                Properties.KeyFieldNames = 'CODIGO_ALM_ALM'
                Properties.ListColumns = <
                  item
                    Caption = 'C'#243'digo'
                    Width = 110
                    FieldName = 'CODIGO_ALM_ALM'
                  end
                  item
                    Caption = 'Almac'#233'n'
                    Width = 220
                    FieldName = 'NOMBRE_ALM_ALM'
                  end
                  item
                    Caption = 'Empresa'
                    Width = 70
                    FieldName = 'CODIGO_EMP_ALM'
                  end
                  item
                    Caption = 'Tipo de uso'
                    Width = 100
                    FieldName = 'TIPO_USO_ALM'
                  end
                  item
                    Caption = 'Activo'
                    Width = 55
                    FieldName = 'ESACTIVO_ALM'
                  end>
                TabOrder = 3
                Width = 150
              end
              object lblTipoUso: TcxLabel
                Left = 69
                Top = 44
                Caption = 'Tipo de Uso'
                TabOrder = 4
                Transparent = True
              end
              object cxdbtxtdtTIPO_USO_ALM: TcxDBComboBox
                Left = 199
                Top = 40
                DataBinding.DataField = 'TIPO_USO_ALM'
                DataBinding.DataSource = dsTablaG
                Properties.DropDownListStyle = lsFixedList
                Properties.Items.Strings = (
                  'ESTANDAR'
                  'TARAS'
                  'TALLER'
                  'DEP'#211'SITO'
                  'TR'#193'NSITO')
                TabOrder = 5
                Width = 150
              end
              object lblCodigoPadre: TcxLabel
                Left = 58
                Top = 14
                Caption = 'C'#243'digo Padre'
                TabOrder = 6
                Transparent = True
              end
              object cxdbtxtdtCODIGO_PADRE_ALM: TcxDBLookupComboBox
                Left = 199
                Top = 10
                DataBinding.DataField = 'CODIGO_PADRE_ALM'
                DataBinding.DataSource = dsTablaG
                Properties.ClearKey = 46
                Properties.DropDownListStyle = lsFixedList
                Properties.DropDownRows = 15
                Properties.DropDownAutoSize = True
                Properties.KeyFieldNames = 'CODIGO_ALM_ALM'
                Properties.ListColumns = <
                  item
                    Caption = 'C'#243'digo'
                    Width = 110
                    FieldName = 'CODIGO_ALM_ALM'
                  end
                  item
                    Caption = 'Almac'#233'n'
                    Width = 220
                    FieldName = 'NOMBRE_ALM_ALM'
                  end
                  item
                    Caption = 'Empresa'
                    Width = 70
                    FieldName = 'CODIGO_EMP_ALM'
                  end
                  item
                    Caption = 'Tipo de uso'
                    Width = 100
                    FieldName = 'TIPO_USO_ALM'
                  end
                  item
                    Caption = 'Activo'
                    Width = 55
                    FieldName = 'ESACTIVO_ALM'
                  end>
                TabOrder = 7
                Width = 150
              end
              object lblCodigoCliente: TcxLabel
                Left = 44
                Top = 134
                Caption = 'C'#243'digo Cliente'
                TabOrder = 8
                Transparent = True
              end
              object cxdbtxtdtCODIGO_CLIENTE_ALM: TcxDBTextEdit
                Left = 199
                Top = 130
                DataBinding.DataField = 'CODIGO_CLI_ALM'
                DataBinding.DataSource = dsTablaG
                TabOrder = 9
                Width = 150
              end
              object chkESCOMPARTIDO_ALM: TcxDBCheckBox
                Left = 360
                Top = 41
                Hint = 
                  'Permite compartir un almacén de tránsito o taller entre ' +
                  'empresas. Las prendas conservan la empresa de su venta.'
                Caption = 'Compartido entre empresas'
                DataBinding.DataField = 'ESCOMPARTIDO_ALM'
                DataBinding.DataSource = dsTablaG
                ParentShowHint = False
                Properties.NullStyle = nssUnchecked
                Properties.ValueChecked = 'S'
                Properties.ValueUnchecked = 'N'
                ShowHint = True
                TabOrder = 10
                Transparent = True
              end
            end
            object tsAuditoria: TcxTabSheet
              Caption = '&3_Otros'
              ImageIndex = 0
              object pnlAuditoria: TPanel
                Left = 0
                Top = 0
                Width = 935
                Height = 321
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
                  Left = 136
                  Top = 13
                  DataBinding.DataField = 'USUARIO_ALTA'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 0
                  Width = 150
                end
                object lblInstanteAlta: TcxLabel
                  Left = 16
                  Top = 48
                  Caption = 'Instante Alta'
                  TabOrder = 5
                  Transparent = True
                end
                object txtINSTANTEALTA: TcxDBTextEdit
                  Left = 136
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
                  Width = 150
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
        object splSplitterFicha: TcxSplitter
          Left = 0
          Top = 121
          Width = 943
          Height = 8
          HotZoneClassName = 'TcxMediaPlayer9Style'
          AlignSplitter = salTop
          Control = pnlButtonFicha
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
    DataSet = dmAlmacenes.unqryTablaG
  end
end
