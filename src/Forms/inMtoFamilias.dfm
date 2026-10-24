inherited frmMtoFamilias: TfrmMtoFamilias
  Left = 5
  Top = 4
  Caption = 'Familias'
  ClientHeight = 628
  ClientWidth = 880
  StyleElements = [seFont, seClient, seBorder]
  ExplicitWidth = 880
  ExplicitHeight = 628
  TextHeight = 19
  inherited pButtonPage: TPanel
    Width = 740
    Height = 628
    TabOrder = 0
    StyleElements = [seFont, seClient, seBorder]
    ExplicitWidth = 740
    ExplicitHeight = 628
    inherited pcPantalla: TcxPageControl
      Width = 740
      Height = 588
      TabOrder = 1
      ExplicitWidth = 740
      ExplicitHeight = 588
      ClientRectBottom = 586
      ClientRectRight = 738
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 2
        ExplicitTop = 29
        ExplicitWidth = 736
        ExplicitHeight = 521
        inherited cxGrdPrincipal: TcxGrid
          Width = 736
          Height = 557
          ExplicitWidth = 736
          ExplicitHeight = 521
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            object cxgrdbclmnGrdDBTabPrinCODIGO_FAMILIA: TcxGridDBColumn
              Caption = 'C'#243'digo Familia'
              DataBinding.FieldName = 'CODIGO_FAM_FAM'
              Width = 140
            end
            object cxgrdbclmnGrdDBTabPrinACTIVO_FAMILIA: TcxGridDBColumn
              Caption = 'Es Familia activa'
              DataBinding.FieldName = 'ESACTIVO_FAM'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 162
            end
            object dbcGrdDBTabPrinESDEFAULT_FAMILIA: TcxGridDBColumn
              Caption = 'Por Defecto'
              DataBinding.FieldName = 'ESDEFAULT_FAM'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 107
            end
            object cxgrdbclmnGrdDBTabPrinNOMBRE_FAMILIA: TcxGridDBColumn
              Caption = 'Nombre Familia'
              DataBinding.FieldName = 'NOMBRE_FAM_FAM'
              Width = 191
            end
            object dbcGrdDBTabPrinCODIGO_SUBFAMILIA: TcxGridDBColumn
              Caption = 'Código familia padre'
              DataBinding.FieldName = 'CODIGO_PADRE_FAM'
              Width = 174
            end
            object dbcGrdDBTabPrinNOMBRE_SUBFAMILIA: TcxGridDBColumn
              Caption = 'Nombre familia padre'
              DataBinding.FieldName = 'NOMBRE_SUBFAMILIA'
              Width = 167
            end
            object cxgrdbclmnGrdDBTabPrinDESCRIPCION_FAMILIA: TcxGridDBColumn
              Caption = 'Descripci'#243'n'
              DataBinding.FieldName = 'DESCRIPCION_FAM'
              Width = 309
            end
            object cxgrdbclmnGrdDBTabPrinORDEN_FAMILIA: TcxGridDBColumn
              Caption = 'Orden en listados'
              DataBinding.FieldName = 'ORDEN_FAM'
              Width = 162
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        ExplicitLeft = 2
        ExplicitTop = 29
        ExplicitWidth = 736
        ExplicitHeight = 557
        object pnlTopFicha: TPanel
          Left = 0
          Top = 0
          Width = 736
          Height = 165
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          object cxdbtxtdt1: TcxDBTextEdit
            Left = 104
            Top = 33
            DataBinding.DataField = 'CODIGO'
            DataBinding.DataSource = dsTablaG
            Enabled = False
            TabOrder = 1
            Width = 121
          end
          object cxdbtxtdt2: TcxDBTextEdit
            Left = 104
            Top = 61
            DataBinding.DataField = 'DESCRIPCION'
            DataBinding.DataSource = dsTablaG
            TabOrder = 2
            Width = 241
          end
          object cxdbtxtdt15: TcxDBTextEdit
            Left = 856
            Top = 89
            DataBinding.DataField = 'modificado'
            DataBinding.DataSource = dsTablaG
            TabOrder = 3
            Width = 57
          end
          object pnlCabFich: TPanel
            Left = 0
            Top = 0
            Width = 736
            Height = 165
            Align = alClient
            BevelOuter = bvNone
            TabOrder = 0
            object txtCODIGO_FAMILIA: TcxDBTextEdit
              Left = 101
              Top = 13
              DataBinding.DataField = 'CODIGO_FAM_FAM'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = False
              Properties.OnEditValueChanged = CambiarEjemploContador
              TabOrder = 0
              Width = 121
            end
            object lblCodigo: TcxLabel
              Left = 21
              Top = 17
              Caption = 'C'#243'digo'
              TabOrder = 1
              Transparent = True
            end
            object lblNombre: TcxLabel
              Left = 18
              Top = 51
              Caption = 'Nombre'
              TabOrder = 2
              Transparent = True
            end
            object txtNOMBRE_FAMILIA: TcxDBTextEdit
              Left = 100
              Top = 48
              DataBinding.DataField = 'NOMBRE_FAM_FAM'
              DataBinding.DataSource = dsTablaG
              TabOrder = 3
              Width = 322
            end
            object chkActivo: TcxDBCheckBox
              Left = 97
              Top = 78
              Caption = 'Activo'
              DataBinding.DataField = 'ESACTIVO_FAM'
              DataBinding.DataSource = dsTablaG
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              TabOrder = 4
              Transparent = True
            end
            object cbbFamilia: TcxDBLookupComboBox
              Left = 143
              Top = 111
              DataBinding.DataField = 'CODIGO_PADRE_FAM'
              DataBinding.DataSource = dsTablaG
              Properties.DropDownWidth = 380
              Properties.KeyFieldNames = 'CODIGO_FAM_FAM'
              Properties.ListColumns = <
                item
                  MinWidth = 50
                  Width = 100
                  FieldName = 'CODIGO_FAM_FAM'
                end
                item
                  Sorting = False
                  Width = 260
                  FieldName = 'NOMBRE_FAM_FAM'
                end>
              Properties.ListOptions.ShowHeader = False
              TabOrder = 5
              Width = 202
            end
            object lblFamiliaPadre: TcxLabel
              Left = 20
              Top = 112
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              Caption = 'Familia Padre'
              Properties.Alignment.Horz = taRightJustify
              TabOrder = 6
              Transparent = True
              AnchorX = 136
            end
            object lblTrazabilidadFamilia: TcxLabel
              Left = 443
              Top = 17
              Caption = 'Trazabilidad de los artículos nuevos:'
              TabOrder = 8
              Transparent = True
            end
            object cbbTrazabilidadFamilia: TcxDBImageComboBox
              Left = 443
              Top = 48
              DataBinding.DataField = 'TIPO_TRAZABILIDAD_FAM'
              DataBinding.DataSource = dsTablaG
              Properties.Items = <>
              TabOrder = 9
              Width = 275
            end
            object chkDEFAULT_FAMILIA: TcxDBCheckBox
              Left = 249
              Top = 82
              Caption = 'Familia por defecto'
              DataBinding.DataField = 'ESDEFAULT_FAM'
              DataBinding.DataSource = dsTablaG
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Style.TransparentBorder = False
              TabOrder = 7
              Transparent = True
            end
          end
        end
        object pnlDetailFich: TPanel
          Left = 0
          Top = 175
          Width = 736
          Height = 382
          Align = alClient
          BevelOuter = bvNone
          TabOrder = 1
          object pcDetail: TcxPageControl
            Left = 0
            Top = 0
            Width = 736
            Height = 382
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsMasDatos
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 380
            ClientRectLeft = 2
            ClientRectRight = 734
            ClientRectTop = 29
            object tsMasDatos: TcxTabSheet
              Caption = '&1_M'#225's Datos'
              ImageIndex = 0
              object lblDescripcion: TcxLabel
                Left = 33
                Top = 19
                Caption = 'Descripci'#243'n'
                TabOrder = 0
                Transparent = True
              end
              object mDESCRIPCION_FAMILIA: TcxDBMemo
                Left = 33
                Top = 45
                DataBinding.DataField = 'DESCRIPCION_FAM'
                DataBinding.DataSource = dsTablaG
                TabOrder = 1
                Height = 89
                Width = 373
              end
              object gbContadorArt: TcxGroupBox
                Left = 33
                Top = 152
                Caption = ' Autogenerar c'#243'digo de art'#237'culo desde esta familia '
                TabOrder = 2
                Height = 137
                Width = 659
                object chkEsContadorArtFam: TcxDBCheckBox
                  Left = 16
                  Top = 24
                  AutoSize = False
                  Caption = 'Activar contador en sesiones de compra'
                  Width = 627
                  DataBinding.DataField = 'ESCONTADOR_ART_FAM'
                  DataBinding.DataSource = dsTablaG
                  Properties.ValueChecked = 'S'
                  Properties.ValueUnchecked = 'N'
                  TabOrder = 0
                end
                object lblContadorArt: TcxLabel
                  Left = 16
                  Top = 56
                  Caption = #218'ltimo contador'
                  TabOrder = 3
                  Transparent = True
                end
                object spnContadorArt: TcxDBSpinEdit
                  Left = 164
                  Top = 53
                  DataBinding.DataField = 'CONTADOR_ART_FAM'
                  DataBinding.DataSource = dsTablaG
                  Properties.AssignedValues.MinValue = True
                  Properties.MaxValue = 99999999.000000000000000000
                  Properties.ValueType = vtInt
                  Properties.OnEditValueChanged = CambiarEjemploContador
                  TabOrder = 1
                  Width = 90
                end
                object lblPadArt: TcxLabel
                  Left = 278
                  Top = 56
                  Caption = 'D'#237'gitos relleno'
                  TabOrder = 4
                  Transparent = True
                end
                object spnPadArt: TcxDBSpinEdit
                  Left = 414
                  Top = 53
                  DataBinding.DataField = 'PAD_ART_FAM'
                  DataBinding.DataSource = dsTablaG
                  Properties.AssignedValues.MinValue = True
                  Properties.MaxValue = 12.000000000000000000
                  Properties.ValueType = vtInt
                  Properties.OnEditValueChanged = CambiarEjemploContador
                  TabOrder = 2
                  Width = 60
                end
                object lblEjemploContador: TcxLabel
                  Left = 16
                  Top = 84
                  Caption = ''
                  Style.TextColor = clGrayText
                  TabOrder = 5
                  Transparent = True
                end
              end
            end
            object tsArticulos: TcxTabSheet
              Caption = '&2_Articulos'
              ImageIndex = 2
              ExplicitLeft = 0
              ExplicitTop = 0
              ExplicitWidth = 0
              ExplicitHeight = 0
              object cxgrdArticulosFamilias: TcxGrid
                Left = 0
                Top = 0
                Width = 732
                Height = 351
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Align = alClient
                TabOrder = 0
                object tvArticulos: TcxGridDBTableView
                  Navigator.Buttons.ConfirmDelete = True
                  Navigator.Visible = True
                  DataController.DataModeController.SmartRefresh = True
                  DataController.Summary.DefaultGroupSummaryItems = <
                    item
                      Kind = skSum
                    end
                    item
                      Kind = skSum
                    end
                    item
                      Kind = skSum
                    end
                    item
                      Kind = skSum
                    end>
                  DataController.Summary.FooterSummaryItems = <
                    item
                      Format = '0.00 '#8364';-0.00 '#8364
                      Kind = skSum
                    end
                    item
                      Format = '0.00 '#8364';-0.00 '#8364
                      Kind = skSum
                    end
                    item
                      Format = '0.00 '#8364';-0.00 '#8364
                      Kind = skSum
                    end
                    item
                      Format = '0.00 '#8364';-0.00 '#8364
                      Kind = skSum
                    end>
                  OptionsBehavior.GoToNextCellOnEnter = True
                  OptionsCustomize.ColumnGrouping = False
                  OptionsData.Deleting = False
                  OptionsData.Editing = False
                  OptionsData.Inserting = False
                  OptionsSelection.InvertSelect = False
                  OptionsView.NoDataToDisplayInfoText = '<No hay datos a mostrar>'
                  OptionsView.Footer = True
                  OptionsView.GroupByBox = False
                  OptionsView.GroupFooters = gfAlwaysVisible
                  object cxgrdbclmnArticulosCODIGO_ARTICULO: TcxGridDBColumn
                    Caption = 'C'#243'digo Art'#237'culo'
                    DataBinding.FieldName = 'CODIGO_ART_ART'
                    Width = 147
                  end
                  object cxgrdbclmnArticulosDESCRIPCION_ARTICULO: TcxGridDBColumn
                    Caption = 'Descripci'#243'n'
                    DataBinding.FieldName = 'DESCRIPCION_ART'
                    Width = 139
                  end
                  object cxgrdbclmnArticulosCODIGO_PROVEEDOR_PRINCIPAL: TcxGridDBColumn
                    Caption = 'C'#243'digo Proveedor Prin.'
                    DataBinding.FieldName = 'CODIGO_PROVEEDOR_PRINCIPAL'
                    Width = 206
                  end
                  object cxgrdbclmnArticulosRAZON_SOCIAL_PROVEEDOR_PRINCIPAL: TcxGridDBColumn
                    Caption = 'Raz'#243'n Social Proveedor Principal'
                    DataBinding.FieldName = 'RAZON_SOCIAL_PROVEEDOR_PRINCIPAL'
                    Width = 277
                  end
                  object cxgrdbclmnArticulosNOMBRE_TARIFA: TcxGridDBColumn
                    Caption = 'Tarifa'
                    DataBinding.FieldName = 'NOMBRE_TAR_TAR'
                    Width = 78
                  end
                  object cxgrdbclmnArticulosPRECIOFINAL_TARIFA: TcxGridDBColumn
                    Caption = 'Precio Salida'
                    DataBinding.FieldName = 'PRECIO_FINAL_ARTTAR'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Width = 127
                  end
                  object cxgrdbclmnArticulosESIMP_INCL_TARIFA: TcxGridDBColumn
                    Caption = 'Tarifa Imp Incl'
                    DataBinding.FieldName = 'ESIMP_INCL_TAR'
                    PropertiesClassName = 'TcxCheckBoxProperties'
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    Width = 146
                  end
                  object cxgrdbclmnArticulosNOMBRE_TIPO_IVA: TcxGridDBColumn
                    Caption = 'Tipo de IVA'
                    DataBinding.FieldName = 'NOMBRE_TIPO_IVA_IVATIP'
                    Width = 114
                  end
                  object cxgrdbclmnArticulosTIPO_CANTIDAD_ARTICULO: TcxGridDBColumn
                    Caption = 'Tipo Cantidad'
                    DataBinding.FieldName = 'TIPO_CANTIDAD_ART'
                    Width = 131
                  end
                  object cxgrdbclmnArticulosESACTIVO_FIJO_ARTICULO: TcxGridDBColumn
                    Caption = 'Activo Fijo'
                    DataBinding.FieldName = 'ESACTIVO_FIJO_ART'
                    PropertiesClassName = 'TcxCheckBoxProperties'
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    Width = 102
                  end
                end
                object tvLineasFacturacion: TcxGridDBTableView
                  DataController.DetailKeyFieldNames = 'NUMERO_FAC_FACLIN; SERIE_FAC_FACLIN'
                  DataController.KeyFieldNames = 'LINEA_FACLIN'
                  DataController.MasterKeyFieldNames = 'NUMERO_FAC; SERIE_FAC'
                  OptionsBehavior.ColumnHeaderHints = False
                  OptionsCustomize.ColumnFiltering = False
                  OptionsCustomize.ColumnGrouping = False
                  OptionsCustomize.ColumnMoving = False
                  OptionsCustomize.ColumnsQuickCustomizationShowCommands = False
                  OptionsData.Deleting = False
                  OptionsData.Editing = False
                  OptionsData.Inserting = False
                  OptionsView.GroupByBox = False
                  object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1LINEA_LINEA: TcxGridDBColumn
                    DataBinding.FieldName = 'LINEA_FACLIN'
                    Width = 28
                  end
                  object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CODIGO_ARTICULO_LINEA: TcxGridDBColumn
                    Caption = 'C'#243'digo Tratamiento'
                    DataBinding.FieldName = 'CODIGO_ART_FACLIN'
                    Width = 164
                  end
                  object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1DESCRIPCION_ARTICULO_LINEA: TcxGridDBColumn
                    Caption = 'Descripci'#243'n Tratamiento'
                    DataBinding.FieldName = 'DESCRIPCION_ARTICULO_FACLIN'
                    Width = 162
                  end
                  object cxgrdbclmnLineasFacturacionTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                    DataBinding.FieldName = 'TIPO_CANTIDAD_ARTICULO_FACLIN'
                  end
                  object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CANTIDAD_LINEA: TcxGridDBColumn
                    Caption = 'Cantidad'
                    DataBinding.FieldName = 'CANTIDAD_FACLIN'
                    Width = 84
                  end
                  object cxgrdbclmnLineasFacturacionPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                    DataBinding.FieldName = 'PRECIO_VENTA_SIVA_ARTICULO_FACLIN'
                  end
                  object cxgrdbclmnLineasFacturacionPORCEN_IVA_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Porcentaje IVA'
                    DataBinding.FieldName = 'PORCENTAJE_IVA_FACLIN'
                    PropertiesClassName = 'TcxSpinEditProperties'
                    Properties.EditFormat = '0.00 %'
                  end
                  object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1PRECIOVENTA_ARTICULO_LINEA: TcxGridDBColumn
                    Caption = 'Precio'
                    DataBinding.FieldName = 'PRECIO_VENTA_CIVA_ARTICULO_FACLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Width = 84
                  end
                  object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1SUM_TOTAL_LINEA: TcxGridDBColumn
                    Caption = 'Total'
                    DataBinding.FieldName = 'TOTAL_FACLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Width = 84
                  end
                  object cxgrdbclmnLineasFacturacionFECHA_ENTREGA_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Fecha de Entrega'
                    DataBinding.FieldName = 'FECHA_ENTREGA_FACLIN'
                    PropertiesClassName = 'TcxDateEditProperties'
                  end
                  object cxgrdbclmnLineasFacturacionTIPOIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                    DataBinding.FieldName = 'TIPO_IVA_ARTICULO_FACLIN'
                  end
                end
                object cxgrdlvlArticulosFamilias: TcxGridLevel
                  GridView = tvArticulos
                end
              end
            end
            object cxTabSheet1: TcxTabSheet
              Caption = '&3_Propiedades Art'#237'culos'
              ImageIndex = 3
              object cxGrid1: TcxGrid
                Left = 0
                Top = 0
                Width = 732
                Height = 351
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Align = alClient
                TabOrder = 0
                object tvAtributos: TcxGridDBTableView
                  Navigator.Buttons.ConfirmDelete = True
                  Navigator.Visible = True
                  DataController.DataModeController.SmartRefresh = True
                  DataController.Summary.DefaultGroupSummaryItems = <
                    item
                      Kind = skSum
                    end
                    item
                      Kind = skSum
                    end
                    item
                      Kind = skSum
                    end
                    item
                      Kind = skSum
                    end>
                  DataController.Summary.FooterSummaryItems = <
                    item
                      Format = '0.00 '#8364';-0.00 '#8364
                      Kind = skSum
                    end
                    item
                      Format = '0.00 '#8364';-0.00 '#8364
                      Kind = skSum
                    end
                    item
                      Format = '0.00 '#8364';-0.00 '#8364
                      Kind = skSum
                    end
                    item
                      Format = '0.00 '#8364';-0.00 '#8364
                      Kind = skSum
                    end>
                  OptionsBehavior.GoToNextCellOnEnter = True
                  OptionsCustomize.ColumnGrouping = False
                  OptionsData.Appending = True
                  OptionsSelection.InvertSelect = False
                  OptionsView.NoDataToDisplayInfoText = '<No hay datos a mostrar>'
                  OptionsView.Footer = True
                  OptionsView.GroupByBox = False
                  OptionsView.GroupFooters = gfAlwaysVisible
                  object tvAtributosCODIGO_FAMILIA: TcxGridDBColumn
                    DataBinding.FieldName = 'CODIGO_FAM_FAM'
                    Visible = False
                  end
                  object tvAtributosCODIGO_PROPIEDAD: TcxGridDBColumn
                    Caption = 'Cod Propiedad'
                    DataBinding.FieldName = 'CODIGO_PROP_ARTPROP'
                    PropertiesClassName = 'TcxLookupComboBoxProperties'
                    Properties.DropDownSizeable = True
                    Properties.DropDownWidth = 360
                    Properties.ImmediatePost = True
                    Properties.KeyFieldNames = 'CODIGO_PROP_ARTPROP'
                    Properties.ListColumns = <
                      item
                        Width = 100
                        FieldName = 'CODIGO_PROP_ARTPROP'
                      end
                      item
                        Width = 240
                        FieldName = 'NOMBRE_PROP_PROP'
                      end>
                    Properties.ListOptions.ShowHeader = False
                    Width = 142
                  end
                  object tvAtributosNOMBRE_PROPIEDAD: TcxGridDBColumn
                    Caption = 'Nombre Propiedad'
                    DataBinding.FieldName = 'NOMBRE_PROP_PROP'
                    Width = 193
                  end
                  object tvAtributosES_REQUERIDO: TcxGridDBColumn
                    Caption = 'Obligatorio'
                    DataBinding.FieldName = 'ESREQUERIDO_FA'
                    PropertiesClassName = 'TcxCheckBoxProperties'
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    Width = 109
                  end
                  object tvAtributosORDEN_MOSTRAR: TcxGridDBColumn
                    Caption = 'Orden'
                    DataBinding.FieldName = 'ORDEN_MOSTRAR_FA'
                    HeaderAlignmentHorz = taRightJustify
                  end
                end
                object cxGridDBTableView2: TcxGridDBTableView
                  DataController.DetailKeyFieldNames = 'NUMERO_FAC_FACLIN; SERIE_FAC_FACLIN'
                  DataController.KeyFieldNames = 'LINEA_FACLIN'
                  DataController.MasterKeyFieldNames = 'NUMERO_FAC; SERIE_FAC'
                  OptionsBehavior.ColumnHeaderHints = False
                  OptionsCustomize.ColumnFiltering = False
                  OptionsCustomize.ColumnGrouping = False
                  OptionsCustomize.ColumnMoving = False
                  OptionsCustomize.ColumnsQuickCustomizationShowCommands = False
                  OptionsData.Deleting = False
                  OptionsData.Editing = False
                  OptionsData.Inserting = False
                  OptionsView.GroupByBox = False
                  object cxGridDBColumn11: TcxGridDBColumn
                    DataBinding.FieldName = 'LINEA_FACLIN'
                    Width = 28
                  end
                  object cxGridDBColumn12: TcxGridDBColumn
                    Caption = 'C'#243'digo Tratamiento'
                    DataBinding.FieldName = 'CODIGO_ART_FACLIN'
                    Width = 164
                  end
                  object cxGridDBColumn13: TcxGridDBColumn
                    Caption = 'Descripci'#243'n Tratamiento'
                    DataBinding.FieldName = 'DESCRIPCION_ARTICULO_FACLIN'
                    Width = 162
                  end
                  object cxGridDBColumn14: TcxGridDBColumn
                    DataBinding.FieldName = 'TIPO_CANTIDAD_ARTICULO_FACLIN'
                  end
                  object cxGridDBColumn15: TcxGridDBColumn
                    Caption = 'Cantidad'
                    DataBinding.FieldName = 'CANTIDAD_FACLIN'
                    Width = 84
                  end
                  object cxGridDBColumn16: TcxGridDBColumn
                    DataBinding.FieldName = 'PRECIO_VENTA_SIVA_ARTICULO_FACLIN'
                  end
                  object cxGridDBColumn17: TcxGridDBColumn
                    Caption = 'Porcentaje IVA'
                    DataBinding.FieldName = 'PORCENTAJE_IVA_FACLIN'
                    PropertiesClassName = 'TcxSpinEditProperties'
                    Properties.EditFormat = '0.00 %'
                  end
                  object cxGridDBColumn18: TcxGridDBColumn
                    Caption = 'Precio'
                    DataBinding.FieldName = 'PRECIO_VENTA_CIVA_ARTICULO_FACLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Width = 84
                  end
                  object cxGridDBColumn19: TcxGridDBColumn
                    Caption = 'Total'
                    DataBinding.FieldName = 'TOTAL_FACLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Width = 84
                  end
                  object cxGridDBColumn20: TcxGridDBColumn
                    Caption = 'Fecha de Entrega'
                    DataBinding.FieldName = 'FECHA_ENTREGA_FACLIN'
                    PropertiesClassName = 'TcxDateEditProperties'
                  end
                  object cxGridDBColumn21: TcxGridDBColumn
                    DataBinding.FieldName = 'TIPO_IVA_ARTICULO_FACLIN'
                  end
                end
                object cxGridLevel1: TcxGridLevel
                  GridView = tvAtributos
                end
              end
            end
            object tsOtros: TcxTabSheet
              Caption = '&4_Otros'
              ImageIndex = 3
              object pnlOtros: TPanel
                Left = 0
                Top = 272
                Width = 732
                Height = 79
                Align = alBottom
                BevelOuter = bvNone
                TabOrder = 0
                object cxdbtxtdtDIRECCION1_CLIENTE: TcxDBTextEdit
                  Left = 17
                  Top = 37
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'USUARIO_ALTA'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 2
                  Width = 136
                end
                object lblUsuarioAlta: TcxLabel
                  Left = 17
                  Top = 9
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Usuario Alta'
                  TabOrder = 0
                  Transparent = True
                end
                object lblInstanteAlta: TcxLabel
                  Left = 160
                  Top = 9
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Instante Alta'
                  TabOrder = 1
                  Transparent = True
                end
                object cxdbtxtdtUSUARIOALTA: TcxDBTextEdit
                  Left = 160
                  Top = 37
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'INSTANTE_ALTA'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 3
                  Width = 195
                end
                object cxdbtxtdtINSTANTEALTA: TcxDBTextEdit
                  Left = 514
                  Top = 37
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'INSTANTE_MODIF'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 7
                  Width = 201
                end
                object lblInstanteModif: TcxLabel
                  Left = 514
                  Top = 9
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Instante Modif.'
                  TabOrder = 5
                  Transparent = True
                end
                object cxdbtxtdtUSUARIOALTA1: TcxDBTextEdit
                  Left = 364
                  Top = 37
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'USUARIO_ALTA'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 4
                  Width = 136
                end
                object lblUsuarioModif: TcxLabel
                  Left = 364
                  Top = 9
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Usuario '#218'lt. Modif'
                  TabOrder = 6
                  Transparent = True
                end
              end
              object lblOrden: TcxLabel
                Left = 20
                Top = 24
                Caption = 'Orden en Listados'
                TabOrder = 1
                Transparent = True
              end
              object cxdbspndtORDEN_CLIENTE: TcxDBSpinEdit
                Left = 179
                Top = 23
                DataBinding.DataField = 'ORDEN_FAM'
                DataBinding.DataSource = dsTablaG
                TabOrder = 2
                Width = 106
              end
            end
          end
        end
        object splFicha: TcxSplitter
          Left = 0
          Top = 165
          Width = 736
          Height = 10
          HotZoneClassName = 'TcxMediaPlayer9Style'
          AlignSplitter = salTop
          Control = pnlTopFicha
        end
      end
      inherited tsPerfil: TcxTabSheet
        ExplicitWidth = 736
        ExplicitHeight = 557
        inherited pnlPerfilTop: TPanel
          Width = 736
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 736
          inherited edtPerfilBusq: TcxTextEdit
            ExplicitHeight = 27
          end
        end
        inherited pnlPerfilDetail: TPanel
          Width = 736
          Height = 500
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 736
          ExplicitHeight = 500
          inherited cxgrdPerfil: TcxGrid
            Width = 736
            Height = 500
            ExplicitWidth = 736
            ExplicitHeight = 500
          end
        end
      end
    end
    inherited pnlTopPage: TPanel
      Width = 740
      TabOrder = 0
      StyleElements = [seFont, seClient, seBorder]
      ExplicitWidth = 740
      inherited pnlTopGrid: TPanel
        Width = 740
        StyleElements = [seFont, seClient, seBorder]
        ExplicitWidth = 740
        inherited edtBusqGlobal: TcxTextEdit
          ExplicitHeight = 27
        end
      end
    end
  end
  inherited pButtonRightBar: TPanel
    Left = 740
    Height = 628
    TabOrder = 1
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 740
    ExplicitHeight = 628
    inherited pButtonGen: TPanel
      Top = 430
      StyleElements = [seFont, seClient, seBorder]
      ExplicitTop = 430
      inherited btnGrabar: TcxButton
        ParentFont = False
      end
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
    object btnNuevaFamilia: TcxButton
      Left = 1
      Top = 157
      Width = 138
      Height = 25
      Caption = '&Nueva Familia'
      TabOrder = 2
      OnClick = btnNuevaFamiliaClick
    end
  end
  inherited dsTablaG: TDataSource
    OnDataChange = dsTablaGDataChange
    DataSet = dmFamilias.unqryTablaG
    Left = 604
    Top = 399
  end
  inherited saveDialog: TdxSaveFileDialog
    Left = 600
    Top = 344
  end
  object alFamilias: TActionList
    Left = 512
    Top = 344
    object actArticulo: TAction
      Caption = 'Articulos'
      ShortCut = 16466
      OnExecute = actArticulosExecute
    end
    object actProveedores: TAction
      Caption = 'Proveedores'
      ShortCut = 16464
      OnExecute = actProveedoresExecute
    end
    object actTarifas: TAction
      Caption = 'Tarifas'
      ShortCut = 16468
      OnExecute = actTarifasExecute
    end
  end
end
