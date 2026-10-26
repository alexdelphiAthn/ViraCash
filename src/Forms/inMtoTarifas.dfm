inherited frmMtoTarifas: TfrmMtoTarifas
  Left = 5
  Top = 4
  Caption = 'Tarifas'
  ClientHeight = 614
  ClientWidth = 1036
  StyleElements = [seFont, seClient, seBorder]
  ExplicitWidth = 1036
  ExplicitHeight = 614
  TextHeight = 17
  inherited pButtonPage: TPanel
    Width = 896
    Height = 614
    TabOrder = 0
    StyleElements = [seFont, seClient, seBorder]
    ExplicitWidth = 896
    ExplicitHeight = 614
    inherited pcPantalla: TcxPageControl
      Width = 896
      Height = 574
      TabOrder = 1
      ExplicitWidth = 896
      ExplicitHeight = 574
      ClientRectBottom = 570
      ClientRectRight = 892
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 28
        ExplicitWidth = 888
        ExplicitHeight = 542
        inherited cxGrdPrincipal: TcxGrid
          Width = 888
          Height = 542
          ExplicitWidth = 888
          ExplicitHeight = 542
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            object cxgrdbclmnGrdDBTabPrinCODIGO_TARIFA: TcxGridDBColumn
              Caption = 'C'#243'digo Tarifa'
              DataBinding.FieldName = 'CODIGO_TAR_ARTTAR'
              Width = 141
            end
            object cxgrdbclmnGrdDBTabPrinNOMBRE_TARIFA: TcxGridDBColumn
              Caption = 'Nombre Tarifa'
              DataBinding.FieldName = 'NOMBRE_TAR_TAR'
              Width = 188
            end
            object cxgrdbclmnGrdDBTabPrinACTIVO_TARIFA: TcxGridDBColumn
              Caption = 'Activa'
              DataBinding.FieldName = 'ESACTIVO_ARTTAR'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 75
            end
            object cxgrdbclmnGrdDBTabPrinESIMP_INCL_TARIFA: TcxGridDBColumn
              Caption = 'Impuestos incl.'
              DataBinding.FieldName = 'ESIMP_INCL_TAR'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 141
            end
            object cxgrdbclmnGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn
              DataBinding.FieldName = 'INSTANTE_MODIF'
              Visible = False
              VisibleForCustomization = False
            end
            object cxgrdbclmnGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn
              DataBinding.FieldName = 'INSTANTE_ALTA'
              Visible = False
              VisibleForCustomization = False
            end
            object cxgrdbclmnGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn
              DataBinding.FieldName = 'USUARIO_ALTA'
              Visible = False
              VisibleForCustomization = False
              Width = 109
            end
            object cxgrdbclmnGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn
              DataBinding.FieldName = 'USUARIO_MODIF'
              Visible = False
              VisibleForCustomization = False
              Width = 119
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 28
        ExplicitWidth = 888
        ExplicitHeight = 542
        object pnlTopFicha: TPanel
          Left = 0
          Top = 0
          Width = 888
          Height = 113
          Align = alTop
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
          object pnlInnerHeader: TPanel
            Left = 1
            Top = 1
            Width = 886
            Height = 111
            Align = alClient
            TabOrder = 0
            object txtCODIGO_TARIFA: TcxDBTextEdit
              Left = 101
              Top = 9
              DataBinding.DataField = 'CODIGO_TAR_ARTTAR'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = False
              TabOrder = 0
              Width = 121
            end
            object lblCodigo: TcxLabel
              Left = 29
              Top = 13
              Caption = 'C'#243'digo'
              TabOrder = 1
              Transparent = True
            end
            object lblNombre: TcxLabel
              Left = 22
              Top = 49
              Caption = 'Nombre'
              TabOrder = 2
              Transparent = True
            end
            object txtNOMBRE_TARIFA: TcxDBTextEdit
              Left = 100
              Top = 46
              DataBinding.DataField = 'NOMBRE_TAR_TAR'
              DataBinding.DataSource = dsTablaG
              TabOrder = 3
              Width = 322
            end
            object chkActivo: TcxDBCheckBox
              Left = 79
              Top = 78
              Caption = 'Activo'
              DataBinding.DataField = 'ESACTIVO_ARTTAR'
              DataBinding.DataSource = dsTablaG
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              TabOrder = 4
              Transparent = True
            end
            object cxdbchckbxACTIVO_TARIFA: TcxDBCheckBox
              Left = 237
              Top = 11
              Caption = 'Impuestos inclu'#237'dos en el precio final'
              DataBinding.DataField = 'ESIMP_INCL_TAR'
              DataBinding.DataSource = dsTablaG
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Style.TransparentBorder = False
              TabOrder = 5
              Transparent = True
            end
          end
        end
        object pnlBodyFicha: TPanel
          Left = 0
          Top = 121
          Width = 888
          Height = 421
          Align = alClient
          TabOrder = 1
          object pcPestana: TcxPageControl
            Left = 1
            Top = 1
            Width = 886
            Height = 419
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsOtros
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 415
            ClientRectLeft = 4
            ClientRectRight = 882
            ClientRectTop = 28
            object tsArticulos: TcxTabSheet
              Caption = '&1_Art'#237'culos'
              ImageIndex = 0
              object pnlBotonera: TPanel
                Left = 751
                Top = 0
                Width = 127
                Height = 387
                Align = alRight
                TabOrder = 0
                object btnIraArticulo: TcxButton
                  Left = 3
                  Top = 13
                  Width = 120
                  Height = 25
                  Caption = 'Ir a Art'#237'culo'
                  TabOrder = 0
                  OnClick = btnIraArticuloClick
                end
                object btnAddBlock: TcxButton
                  Left = 3
                  Top = 53
                  Width = 120
                  Height = 25
                  Caption = 'A'#241'adir Bloque'
                  TabOrder = 1
                  OnClick = btnAddBlockClick
                end
              end
              object splHorizontal: TcxSplitter
                Left = 743
                Top = 0
                Width = 8
                Height = 387
                HotZoneClassName = 'TcxMediaPlayer9Style'
                Control = pnlBotonera
              end
              object pnlArticulos: TPanel
                Left = 0
                Top = 0
                Width = 743
                Height = 387
                Align = alClient
                TabOrder = 2
                object cxgrdArticulosTarifas: TcxGrid
                  Left = 11
                  Top = 1
                  Width = 731
                  Height = 385
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
                    DataController.DataSource = dmTarifas.dsArticulosTarifas
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
                    object cxgrdbclmnArticulosACTIVO_TARIFA: TcxGridDBColumn
                      Caption = 'Precio Activo'
                      DataBinding.FieldName = 'ESACTIVO_ARTTAR'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Width = 126
                    end
                    object cxgrdbclmnArticulosCODIGO_ARTICULO_TARIFA: TcxGridDBColumn
                      Caption = 'C'#243'digo Art'#237'culo'
                      DataBinding.FieldName = 'CODIGO_ART_ARTTAR'
                      Width = 164
                    end
                    object tvArticulosCODIGO_UNICO_TARIFA_SKU: TcxGridDBColumn
                      Caption = 'SKU'
                      DataBinding.FieldName = 'CODIGO_UNICO_TARIFA_SKU'
                      Width = 181
                    end
                    object cxgrdbclmnArticulosDESCRIPCION_ARTICULO: TcxGridDBColumn
                      Caption = 'Descripci'#243'n Art'#237'culo'
                      DataBinding.FieldName = 'DESCRIPCION_ART'
                      Width = 244
                    end
                    object cxgrdbclmnArticulosCODIGO_FAMILIA_ARTICULO: TcxGridDBColumn
                      Caption = 'C'#243'digo Familia'
                      DataBinding.FieldName = 'CODIGO_FAM_ART'
                      Width = 163
                    end
                    object cxgrdbclmnArticulosDESCRIPCION_FAMILIA: TcxGridDBColumn
                      Caption = 'Descripci'#243'n Familia'
                      DataBinding.FieldName = 'DESCRIPCION_FAM'
                      Width = 265
                    end
                    object cxgrdbclmnArticulosCODIGO_PROVEEDOR: TcxGridDBColumn
                      Caption = 'C'#243'digo Proveedor'
                      DataBinding.FieldName = 'CODIGO_PRV_PRV'
                      Width = 168
                    end
                    object cxgrdbclmnArticulosRAZONSOCIAL_PROVEEDOR: TcxGridDBColumn
                      Caption = 'Nombre Proveedor'
                      DataBinding.FieldName = 'RAZON_SOCIAL_PRV'
                      Width = 208
                    end
                    object cxgrdbclmnArticulosTIPOIVA_ARTICULO: TcxGridDBColumn
                      Caption = 'Tipo de IVA'
                      DataBinding.FieldName = 'TIPO_IVA_ART'
                      Width = 152
                    end
                    object cxgrdbclmnArticulosFECHA_DESDE_TARIFA: TcxGridDBColumn
                      Caption = 'Precio desde Fecha'
                      DataBinding.FieldName = 'FECHA_DESDE_ARTTAR'
                      Width = 181
                    end
                    object cxgrdbclmnArticulosFECHA_HASTA_TARIFA: TcxGridDBColumn
                      Caption = 'Precio Hasta Fecha'
                      DataBinding.FieldName = 'FECHA_HASTA_ARTTAR'
                      Width = 195
                    end
                    object cxgrdbclmnArticulosTIPO_CANTIDAD_ARTICULO: TcxGridDBColumn
                      Caption = 'Tipo Cantidad'
                      DataBinding.FieldName = 'TIPO_CANTIDAD_ART'
                      Width = 129
                    end
                    object cxgrdbclmnArticulosPRECIO_ULT_COMPRA: TcxGridDBColumn
                      Caption = 'Precio '#218'ltima Compra'
                      DataBinding.FieldName = 'PRECIO_ULT_COMPRA'
                      Width = 214
                    end
                    object cxgrdbclmnArticulosFECHA_VALIDEZ: TcxGridDBColumn
                      Caption = 'Fecha '#218'ltima Compra'
                      DataBinding.FieldName = 'FECHA_VALIDEZ'
                    end
                    object cxgrdbclmnArticulosPRECIOFINAL: TcxGridDBColumn
                      Caption = 'Precio Salida'
                      DataBinding.FieldName = 'PRECIOFINAL'
                    end
                    object cxgrdbclmnArticulosINSTANTEALTA: TcxGridDBColumn
                      DataBinding.FieldName = 'INSTANTE_ALTA'
                      Visible = False
                      VisibleForCustomization = False
                    end
                    object cxgrdbclmnArticulosINSTANTEMODIF: TcxGridDBColumn
                      DataBinding.FieldName = 'INSTANTE_MODIF'
                      Visible = False
                      VisibleForCustomization = False
                    end
                    object cxgrdbclmnArticulosUSUARIOALTA: TcxGridDBColumn
                      DataBinding.FieldName = 'USUARIO_ALTA'
                      Visible = False
                      VisibleForCustomization = False
                      Width = 109
                    end
                    object cxgrdbclmnArticulosUSUARIOMODIF: TcxGridDBColumn
                      DataBinding.FieldName = 'USUARIO_MODIF'
                      Visible = False
                      VisibleForCustomization = False
                      Width = 131
                    end
                    object tvArticulosCODIGO_UNIDAD_TARIFA: TcxGridDBColumn
                      DataBinding.FieldName = 'CODIGO_UNIDAD_ARTTAR'
                      Visible = False
                    end
                    object tvArticulosCODIGO_TARIFA: TcxGridDBColumn
                      DataBinding.FieldName = 'CODIGO_TAR_ARTTAR'
                      Visible = False
                    end
                    object tvArticulosNOMBRE_TARIFA: TcxGridDBColumn
                      DataBinding.FieldName = 'NOMBRE_TAR_TAR'
                      Visible = False
                    end
                    object tvArticulosCODIGO_UNICO_TARIFA_PADRE: TcxGridDBColumn
                      DataBinding.FieldName = 'CODIGO_UNICO_TARIFA_PADRE'
                      Visible = False
                    end
                    object tvArticulosCODIGO_UNICO_TARIFA: TcxGridDBColumn
                      DataBinding.FieldName = 'CODIGO_UNICO_ARTTAR'
                      Visible = False
                    end
                    object tvArticulosORIGEN_PRECIO: TcxGridDBColumn
                      Caption = 'Origen'
                      DataBinding.FieldName = 'ORIGEN_PRECIO'
                    end
                    object tvArticulosPRECIOSALIDA_TARIFA: TcxGridDBColumn
                      Caption = 'Precio Salida'
                      DataBinding.FieldName = 'PRECIO_SALIDA_ARTTAR'
                      Width = 163
                    end
                    object tvArticulosPORCEN_DTO_TARIFA: TcxGridDBColumn
                      Caption = '% Dto'
                      DataBinding.FieldName = 'PORCENTAJE_DTO_ARTTAR'
                    end
                    object tvArticulosPRECIO_DTO_TARIFA: TcxGridDBColumn
                      Caption = 'Precio Dto'
                      DataBinding.FieldName = 'PRECIO_DTO_ARTTAR'
                      Width = 113
                    end
                    object tvArticulosPRECIOFINAL_TARIFA: TcxGridDBColumn
                      Caption = 'Precio Final'
                      DataBinding.FieldName = 'PRECIO_FINAL_ARTTAR'
                    end
                    object tvArticulosESIMP_INCL_TARIFA: TcxGridDBColumn
                      DataBinding.FieldName = 'ESIMP_INCL_TAR'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Visible = False
                    end
                    object tvArticulosESVARIACION_ARTICULO: TcxGridDBColumn
                      DataBinding.FieldName = 'ESVARIACION_ART'
                      Visible = False
                    end
                    object tvArticulosTIPO_IVA_ARTICULO: TcxGridDBColumn
                      Caption = 'Tipo IVA'
                      DataBinding.FieldName = 'TIPO_IVA_ARTICULO'
                      Width = 100
                    end
                    object tvArticulosTIENE_SKU: TcxGridDBColumn
                      DataBinding.FieldName = 'TIENE_SKU'
                      Visible = False
                    end
                    object tvArticulosESACTIVO_SKU: TcxGridDBColumn
                      DataBinding.FieldName = 'ESACTIVO_SKU'
                      Visible = False
                    end
                    object tvArticulosNUM_ATRIBUTOS_REQ: TcxGridDBColumn
                      DataBinding.FieldName = 'NUM_ATRIBUTOS_REQ'
                      Visible = False
                    end
                    object tvArticulosDESCRIPCION_SKU: TcxGridDBColumn
                      DataBinding.FieldName = 'DESCRIPCION_SKU'
                      Visible = False
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
                  object cxgrdlvlArticulosTarifas: TcxGridLevel
                    GridView = tvArticulos
                  end
                end
                object splVertical: TcxSplitter
                  Left = 1
                  Top = 1
                  Width = 10
                  Height = 385
                end
              end
            end
            object tsOtros: TcxTabSheet
              Caption = '&2_Otros'
              ImageIndex = 3
              object pnlOtrosDatos: TPanel
                Left = 0
                Top = 308
                Width = 878
                Height = 79
                Align = alBottom
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
                  Left = 177
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
                  Left = 177
                  Top = 37
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'INSTANTE_ALTA'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 3
                  Width = 185
                end
                object cxdbtxtdtINSTANTEALTA: TcxDBTextEdit
                  Left = 525
                  Top = 37
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'INSTANTE_MODIF'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 7
                  Width = 196
                end
                object lblInstanteModif: TcxLabel
                  Left = 525
                  Top = 9
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Instante Modificaci'#243'n'
                  TabOrder = 5
                  Transparent = True
                end
                object cxdbtxtdtUSUARIOALTA1: TcxDBTextEdit
                  Left = 373
                  Top = 37
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'USUARIO_MODIF'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 4
                  Width = 136
                end
                object lblUsuarioModif: TcxLabel
                  Left = 373
                  Top = 9
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Us. '#218'lt. Modif.'
                  TabOrder = 6
                  Transparent = True
                end
              end
              object dteFechaDtoDesde: TcxDBDateEdit
                Left = 18
                Top = 44
                DataBinding.DataField = 'FECHA_DESDE_DTO_TAR'
                DataBinding.DataSource = dsTablaG
                TabOrder = 1
                Width = 169
              end
              object dteFechaDtoHasta: TcxDBDateEdit
                Left = 226
                Top = 44
                DataBinding.DataField = 'FECHA_HASTA_DTO_TAR'
                DataBinding.DataSource = dsTablaG
                TabOrder = 2
                Width = 153
              end
              object lblDtoDesde: TcxLabel
                Left = 18
                Top = 17
                Caption = 'Dto. desde'
                TabOrder = 3
                Transparent = True
              end
              object lblDtoHasta: TcxLabel
                Left = 226
                Top = 17
                Caption = 'Dto. hasta'
                TabOrder = 4
                Transparent = True
              end
            end
          end
        end
        object splGeneral: TcxSplitter
          Left = 0
          Top = 113
          Width = 888
          Height = 8
          HotZoneClassName = 'TcxMediaPlayer9Style'
          AlignSplitter = salTop
          Control = pnlBodyFicha
        end
      end
      inherited tsPerfil: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 28
        ExplicitWidth = 888
        ExplicitHeight = 542
        inherited pnlPerfilTop: TPanel
          Width = 888
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 888
          inherited edtPerfilBusq: TcxTextEdit
            ExplicitHeight = 25
          end
        end
        inherited pnlPerfilDetail: TPanel
          Width = 888
          Height = 485
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 888
          ExplicitHeight = 485
          inherited cxgrdPerfil: TcxGrid
            Width = 888
            Height = 485
            ExplicitWidth = 888
            ExplicitHeight = 485
          end
        end
      end
    end
    inherited pnlTopPage: TPanel
      Width = 896
      TabOrder = 0
      StyleElements = [seFont, seClient, seBorder]
      ExplicitWidth = 896
      inherited pnlTopGrid: TPanel
        Width = 896
        StyleElements = [seFont, seClient, seBorder]
        ExplicitWidth = 896
        inherited edtBusqGlobal: TcxTextEdit
          ExplicitHeight = 25
        end
      end
    end
  end
  inherited pButtonRightBar: TPanel
    Left = 896
    Height = 614
    TabOrder = 1
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 896
    ExplicitHeight = 614
    inherited pButtonGen: TPanel
      Top = 416
      StyleElements = [seFont, seClient, seBorder]
      ExplicitTop = 416
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
    DataSet = dmTarifas.unqryTablaG
    Left = 404
    Top = 375
  end
  object alTarifas: TActionList
    Left = 416
    Top = 296
    object actArticulos: TAction
      Caption = 'Articulos'
      ShortCut = 16466
      OnExecute = btnIraArticuloClick
    end
    object actFamilias: TAction
      Caption = 'Familias'
      ShortCut = 16462
      OnExecute = actFamiliasExecute
    end
    object actProveedores: TAction
      Caption = 'actProveedores'
      ShortCut = 16464
      OnExecute = actProveedoresExecute
    end
  end
end
