inherited frmMtoProveedores: TfrmMtoProveedores
  Caption = 'Proveedores'
  ClientHeight = 525
  ClientWidth = 868
  StyleElements = [seFont, seClient, seBorder]
  ExplicitWidth = 868
  ExplicitHeight = 525
  TextHeight = 19
  inherited pButtonPage: TPanel
    Width = 714
    Height = 525
    TabOrder = 0
    StyleElements = [seFont, seClient, seBorder]
    ExplicitWidth = 714
    ExplicitHeight = 525
    inherited pcPantalla: TcxPageControl
      Width = 714
      Height = 485
      TabOrder = 1
      Properties.ActivePage = tsLista
      ExplicitWidth = 714
      ExplicitHeight = 485
      ClientRectBottom = 481
      ClientRectRight = 710
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 30
        ExplicitWidth = 706
        ExplicitHeight = 451
        inherited cxGrdPrincipal: TcxGrid
          Width = 706
          Height = 451
          ExplicitWidth = 706
          ExplicitHeight = 451
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            object cxgrdbclmnGrdDBTabPrinCODIGO_CLIENTE: TcxGridDBColumn
              Caption = 'C'#243'digo'
              DataBinding.FieldName = 'CODIGO_PRV_PRV'
              Width = 81
            end
            object cxgrdbclmnGrdDBTabPrinACTIVO_CLIENTE: TcxGridDBColumn
              Caption = 'Activo'
              DataBinding.FieldName = 'ESACTIVO_PRV'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 67
            end
            object cxgrdbclmnGrdDBTabPrinVARIOS_TIPOS_IVA_PRV: TcxGridDBColumn
              Caption = 'Varios IVA art.'
              DataBinding.FieldName = 'ESVARIOS_TIPOS_IVA_PRV'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 95
            end
            object cxgrdbclmnGrdDBTabPrinRAZONSOCIAL_CLIENTE: TcxGridDBColumn
              Caption = 'Raz'#243'n Social'
              DataBinding.FieldName = 'RAZON_SOCIAL_PRV'
              Width = 212
            end
            object cxgrdbclmnGrdDBTabPrinNOMBRE_PROVEEDOR: TcxGridDBColumn
              Caption = 'Nombre Comercial'
              DataBinding.FieldName = 'NOMBRE_PRV'
              Width = 180
            end
            object cxgrdbclmnGrdDBTabPrinNIF_CLIENTE: TcxGridDBColumn
              Caption = 'Nif Cif'
              DataBinding.FieldName = 'NIF_PRV'
              PropertiesClassName = 'TcxMaskEditProperties'
              Width = 104
            end
            object cxgrdbclmnGrdDBTabPrinMOVIL_CLIENTE: TcxGridDBColumn
              Caption = 'Tel'#233'fono M'#243'vil'
              DataBinding.FieldName = 'MOVIL_PRV'
              Width = 113
            end
            object cxgrdbclmnGrdDBTabPrinTELEFONO_CLIENTE: TcxGridDBColumn
              Caption = 'Tel'#233'fono Fijo'
              DataBinding.FieldName = 'TELEFONO_PRV'
              Width = 121
            end
            object cxgrdbclmnGrdDBTabPrinEMAIL_CLIENTE: TcxGridDBColumn
              Caption = 'Email'
              DataBinding.FieldName = 'EMAIL_PRV'
              Width = 196
            end
            object cxgrdbclmnGrdDBTabPrinDIRECCION1_CLIENTE: TcxGridDBColumn
              Caption = 'Direcci'#243'n'
              DataBinding.FieldName = 'DIRECCION1_PRV'
              Width = 251
            end
            object cxgrdbclmnGrdDBTabPrinDIRECCION2_CLIENTE: TcxGridDBColumn
              Caption = 'M'#225's Direcci'#243'n'
              DataBinding.FieldName = 'DIRECCION2_PRV'
              Width = 77
            end
            object cxgrdbclmnGrdDBTabPrinPOBLACION_CLIENTE: TcxGridDBColumn
              Caption = 'Poblaci'#243'n'
              DataBinding.FieldName = 'POBLACION_PRV'
              Width = 146
            end
            object cxgrdbclmnGrdDBTabPrinPROVINCIA_CLIENTE: TcxGridDBColumn
              Caption = 'Provincia'
              DataBinding.FieldName = 'PROVINCIA_PRV'
              Width = 135
            end
            object cxgrdbclmnGrdDBTabPrinCPOSTAL_CLIENTE: TcxGridDBColumn
              Caption = 'C'#243'digo Postal'
              DataBinding.FieldName = 'CODIGO_POSTAL_PRV'
              Width = 95
            end
            object cxgrdbclmnGrdDBTabPrinPAIS_CLIENTE: TcxGridDBColumn
              Caption = 'Pa'#237's'
              DataBinding.FieldName = 'PAIS_PRV'
              Width = 118
            end
            object cxgrdbclmnGrdDBTabPrinOBSERVACIONES_CLIENTE: TcxGridDBColumn
              Caption = 'Observaciones'
              DataBinding.FieldName = 'OBSERVACIONES_PRV'
              Width = 192
            end
            object cxgrdbclmnGrdDBTabPrinREFERENCIA_CLIENTE: TcxGridDBColumn
              Caption = 'Referencia'
              DataBinding.FieldName = 'REFERENCIA_PRV'
              Width = 184
            end
            object cxgrdbclmnGrdDBTabPrinCONTACTO_CLIENTE: TcxGridDBColumn
              Caption = 'Contacto'
              DataBinding.FieldName = 'CONTACTO_PRV'
              Width = 151
            end
            object cxgrdbclmnGrdDBTabPrinTELEFONO_CONTACTO_CLIENTE: TcxGridDBColumn
              Caption = 'Tel'#233'fono de Contacto'
              DataBinding.FieldName = 'TELEFONO_CONTACTO_PRV'
              Width = 140
            end
            object cxgrdbclmnGrdDBTabPrinIBAN_CLIENTE: TcxGridDBColumn
              Caption = 'Nro Cuenta'
              DataBinding.FieldName = 'IBAN_PRV'
              Visible = False
              Width = 50
            end
            object cxgrdbclmnGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn
              DataBinding.FieldName = 'INSTANTE_MODIF'
              PropertiesClassName = 'TcxDateEditProperties'
              Visible = False
            end
            object cxgrdbclmnGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn
              DataBinding.FieldName = 'INSTANTE_ALTA'
              PropertiesClassName = 'TcxDateEditProperties'
              Visible = False
            end
            object cxgrdbclmnGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn
              DataBinding.FieldName = 'USUARIO_ALTA'
              Visible = False
              Width = 74
            end
            object cxgrdbclmnGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn
              DataBinding.FieldName = 'USUARIO_MODIF'
              Visible = False
              Width = 108
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 30
        ExplicitWidth = 706
        ExplicitHeight = 451
        object pnlCabFicha: TPanel
          Left = 0
          Top = 0
          Width = 706
          Height = 137
          Margins.Left = 4
          Margins.Top = 4
          Margins.Right = 4
          Margins.Bottom = 4
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          object txtCODIGO_PROVEEDOR: TcxDBTextEdit
            Left = 41
            Top = 31
            Margins.Left = 4
            Margins.Top = 4
            Margins.Right = 4
            Margins.Bottom = 4
            DataBinding.DataField = 'CODIGO_PRV_PRV'
            DataBinding.DataSource = dsTablaG
            TabOrder = 1
            Width = 149
          end
          object lblCodigo: TcxLabel
            Left = 41
            Top = 7
            Margins.Left = 4
            Margins.Top = 4
            Margins.Right = 4
            Margins.Bottom = 4
            Caption = 'C'#243'digo'
            TabOrder = 0
            Transparent = True
          end
          object txtRAZONSOCIAL_PROVEEDOR: TcxDBTextEdit
            Left = 224
            Top = 31
            Margins.Left = 4
            Margins.Top = 4
            Margins.Right = 4
            Margins.Bottom = 4
            DataBinding.DataField = 'RAZON_SOCIAL_PRV'
            DataBinding.DataSource = dsTablaG
            TabOrder = 3
            Width = 300
          end
          object lblRazonSocial: TcxLabel
            Left = 224
            Top = 7
            Margins.Left = 4
            Margins.Top = 4
            Margins.Right = 4
            Margins.Bottom = 4
            Caption = 'Raz'#243'n Social Fiscal'
            TabOrder = 2
            Transparent = True
          end
          object txtNOMBRE_PROVEEDOR: TcxDBTextEdit
            Left = 540
            Top = 31
            Margins.Left = 4
            Margins.Top = 4
            Margins.Right = 4
            Margins.Bottom = 4
            DataBinding.DataField = 'NOMBRE_PRV'
            DataBinding.DataSource = dsTablaG
            TabOrder = 13
            Width = 181
          end
          object lblNombreComercial: TcxLabel
            Left = 540
            Top = 7
            Margins.Left = 4
            Margins.Top = 4
            Margins.Right = 4
            Margins.Bottom = 4
            Caption = 'Nombre Comercial'
            TabOrder = 12
            Transparent = True
          end
          object cxdbtxtdtTELEFONO2: TcxDBTextEdit
            Left = 571
            Top = 93
            Margins.Left = 4
            Margins.Top = 4
            Margins.Right = 4
            Margins.Bottom = 4
            DataBinding.DataField = 'TELEFONO_PRV'
            DataBinding.DataSource = dsTablaG
            TabOrder = 10
            Width = 150
          end
          object lblTeléfonos: TcxLabel
            Left = 320
            Top = 94
            Margins.Left = 4
            Margins.Top = 4
            Margins.Right = 4
            Margins.Bottom = 4
            Caption = 'Tel'#233'fonos'
            TabOrder = 8
            Transparent = True
          end
          object lblEmail: TcxLabel
            Left = 357
            Top = 66
            Margins.Left = 4
            Margins.Top = 4
            Margins.Right = 4
            Margins.Bottom = 4
            Caption = 'Email'
            TabOrder = 9
            Transparent = True
          end
          object cxdbtxtdtEMAIL: TcxDBTextEdit
            Left = 414
            Top = 62
            Margins.Left = 4
            Margins.Top = 4
            Margins.Right = 4
            Margins.Bottom = 4
            DataBinding.DataField = 'EMAIL_PRV'
            DataBinding.DataSource = dsTablaG
            TabOrder = 5
            Width = 307
          end
          object lblNif: TcxLabel
            Left = 41
            Top = 68
            Margins.Left = 4
            Margins.Top = 4
            Margins.Right = 4
            Margins.Bottom = 4
            Caption = 'NIF/CIF'
            TabOrder = 11
            Transparent = True
          end
          object cxdbtxtdtNIF: TcxDBTextEdit
            Left = 41
            Top = 93
            Margins.Left = 4
            Margins.Top = 4
            Margins.Right = 4
            Margins.Bottom = 4
            DataBinding.DataField = 'NIF_PRV'
            DataBinding.DataSource = dsTablaG
            TabOrder = 6
            Width = 149
          end
          object cxdbtxtdtMOVIL_CLIENTE: TcxDBTextEdit
            Left = 414
            Top = 93
            Margins.Left = 4
            Margins.Top = 4
            Margins.Right = 4
            Margins.Bottom = 4
            DataBinding.DataField = 'MOVIL_PRV'
            DataBinding.DataSource = dsTablaG
            TabOrder = 7
            Width = 139
          end
          object chkActivo: TcxDBCheckBox
            Left = 224
            Top = 62
            Caption = 'Activo'
            DataBinding.DataField = 'ESACTIVO_PRV'
            DataBinding.DataSource = dsTablaG
            Properties.ValueChecked = 'S'
            Properties.ValueUnchecked = 'N'
            TabOrder = 4
            Transparent = True
          end
        end
        object pnlDetailFicha: TPanel
          Left = 0
          Top = 145
          Width = 706
          Height = 306
          Margins.Left = 4
          Margins.Top = 4
          Margins.Right = 4
          Margins.Bottom = 4
          Align = alClient
          BevelOuter = bvNone
          TabOrder = 2
          object pcPestanas: TcxPageControl
            Left = 0
            Top = 0
            Width = 706
            Height = 306
            Margins.Left = 4
            Margins.Top = 4
            Margins.Right = 4
            Margins.Bottom = 4
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsDomicilioFiscal
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 302
            ClientRectLeft = 4
            ClientRectRight = 702
            ClientRectTop = 30
            object tsDomicilioFiscal: TcxTabSheet
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              Caption = '&1_Domicilio fiscal'
              ImageIndex = 0
              object cxdbtxtdt7: TcxDBTextEdit
                Left = 147
                Top = 21
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                DataBinding.DataField = 'DIRECCION1_PRV'
                DataBinding.DataSource = dsTablaG
                TabOrder = 0
                Width = 303
              end
              object lblDireccion1: TcxLabel
                Left = 34
                Top = 25
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Caption = 'Direcci'#243'n 1'
                Properties.Alignment.Horz = taRightJustify
                TabOrder = 1
                Transparent = True
                AnchorX = 135
              end
              object lblCodPostal: TcxLabel
                Left = 14
                Top = 103
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Caption = 'C'#243'digo Postal'
                Properties.Alignment.Horz = taRightJustify
                TabOrder = 3
                Transparent = True
                AnchorX = 135
              end
              object cxdbtxtdt8: TcxDBTextEdit
                Left = 147
                Top = 99
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                DataBinding.DataField = 'CODIGO_POSTAL_PRV'
                DataBinding.DataSource = dsTablaG
                TabOrder = 4
                Width = 77
              end
              object lblPoblacion: TcxLabel
                Left = 48
                Top = 143
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Caption = 'Poblaci'#243'n'
                Properties.Alignment.Horz = taRightJustify
                TabOrder = 5
                Transparent = True
                AnchorX = 135
              end
              object cxdbtxtdt9: TcxDBTextEdit
                Left = 147
                Top = 139
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                DataBinding.DataField = 'POBLACION_PRV'
                DataBinding.DataSource = dsTablaG
                TabOrder = 6
                Width = 303
              end
              object cxdbtxtdt10: TcxDBTextEdit
                Left = 147
                Top = 178
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                DataBinding.DataField = 'PROVINCIA_PRV'
                DataBinding.DataSource = dsTablaG
                TabOrder = 8
                Width = 303
              end
              object lblProvincia: TcxLabel
                Left = 54
                Top = 182
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Caption = 'Provincia'
                Properties.Alignment.Horz = taRightJustify
                TabOrder = 7
                Transparent = True
                AnchorX = 135
              end
              object cxdbtxtdt16: TcxDBTextEdit
                Left = 147
                Top = 218
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                DataBinding.DataField = 'PAIS_PRV'
                DataBinding.DataSource = dsTablaG
                Properties.OnChange = cxdbtxtdt16PropertiesChange
                TabOrder = 10
                Visible = False
                Width = 303
              end
              object cbbPaisPrv: TcxDBLookupComboBox
                Left = 147
                Top = 218
                DataBinding.DataField = 'CODIGO_PAI_PRV'
                DataBinding.DataSource = dsTablaG
                Properties.KeyFieldNames = 'CODIGO'
                Properties.ListColumns = <
                  item
                    Caption = 'Nombre Pais'
                    FieldName = 'NOMBRE'
                  end>
                Properties.ListOptions.CaseInsensitive = True
                Properties.ListOptions.ShowHeader = False
                Properties.OnChange = cbbPaisPrvPropertiesChange
                TabOrder = 11
                Width = 233
              end
              object chkESIVA_EXENTO_INTRACOMUNITARIO_PRV: TcxDBCheckBox
                Left = 477
                Top = 218
                Caption = 'IVA exento intracom.'
                DataBinding.DataField = 'ESIVA_EXENTO_INTRACOMUNITARIO_PRV'
                DataBinding.DataSource = dsTablaG
                Properties.ValueChecked = 'S'
                Properties.ValueUnchecked = 'N'
                Style.TransparentBorder = False
                TabOrder = 12
                Transparent = True
              end
              object chkESFACTURACION_DIRECTA_PRV: TcxDBCheckBox
                Left = 147
                Top = 245
                Width = 240
                Height = 26
                Caption = 'Facturación directa'
                DataBinding.DataField = 'ESFACTURACION_DIRECTA_PRV'
                DataBinding.DataSource = dsTablaG
                Properties.ValueChecked = 'S'
                Properties.ValueUnchecked = 'N'
                TabOrder = 13
                Transparent = True
              end
              object lblPais: TcxLabel
                Left = 98
                Top = 222
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Caption = 'Pa'#237's'
                Properties.Alignment.Horz = taRightJustify
                TabOrder = 9
                Transparent = True
                AnchorX = 135
              end
              object cxdbtxtdtDireccion: TcxDBTextEdit
                Left = 147
                Top = 60
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                DataBinding.DataField = 'DIRECCION2_PRV'
                DataBinding.DataSource = dsTablaG
                TabOrder = 2
                Width = 304
              end
              object lblDireccion2: TcxLabel
                Left = 34
                Top = 64
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Caption = 'Direcci'#243'n 2'
                Properties.Alignment.Horz = taRightJustify
                TabOrder = 11
                Transparent = True
                AnchorX = 135
              end
            end
            object tsArticulos: TcxTabSheet
              Caption = '&2_Articulos'
              ImageIndex = 3
              ExplicitLeft = 0
              ExplicitTop = 0
              ExplicitWidth = 0
              ExplicitHeight = 0
              object pnl6: TPanel
                Left = 580
                Top = 0
                Width = 118
                Height = 272
                Align = alRight
                BevelOuter = bvNone
                TabOrder = 1
                object btnIraArticulo: TcxButton
                  Left = 6
                  Top = 13
                  Width = 110
                  Height = 25
                  Caption = 'Ir a Art'#237'culo'
                  TabOrder = 0
                  OnClick = btnIraArticuloClick
                end
              end
              object pnl61: TPanel
                Left = 0
                Top = 0
                Width = 580
                Height = 272
                Align = alClient
                BevelOuter = bvNone
                TabOrder = 0
                object cxgrdArticulos: TcxGrid
                  Left = 0
                  Top = 0
                  Width = 580
                  Height = 272
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Align = alClient
                  TabOrder = 0
                  object tvArticulos: TcxGridDBTableView
                    OnDblClick = cxGrdDBTabPrinDblClick
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
                    DataController.DataSource = dmProveedores.dsArticulos
                    DataController.Options = [dcoCaseInsensitive, dcoAssignGroupingValues, dcoAssignMasterDetailKeys, dcoSaveExpanding]
                    OptionsBehavior.AlwaysShowEditor = True
                    OptionsBehavior.GoToNextCellOnEnter = True
                    OptionsBehavior.IncSearch = True
                    OptionsCustomize.ColumnHiding = True
                    OptionsData.CancelOnExit = False
                    OptionsData.Deleting = False
                    OptionsData.DeletingConfirmation = False
                    OptionsData.Inserting = False
                    OptionsView.GroupByBox = False
                    OptionsView.Indicator = True
                    object cxgrdbclmnArticulosCODIGO_PROVEEDOR: TcxGridDBColumn
                      DataBinding.FieldName = 'CODIGO_PRV_PRV'
                      Visible = False
                      VisibleForCustomization = False
                    end
                    object cxgrdbclmnArticulosCODIGO_ARTICULO: TcxGridDBColumn
                      Caption = 'C'#243'digo Art'#237'culo'
                      DataBinding.FieldName = 'CODIGO_ART_ART'
                      Options.Editing = False
                      Width = 135
                    end
                    object cxgrdbclmnArticulosDESCRIPCION_ARTICULO: TcxGridDBColumn
                      Caption = 'Descripci'#243'n'
                      DataBinding.FieldName = 'DESCRIPCION_ART'
                      Options.Editing = False
                      Width = 269
                    end
                    object cxgrdbclmnArticulosCODIGO_FAMILIA: TcxGridDBColumn
                      Caption = 'C'#243'digo Familia'
                      DataBinding.FieldName = 'CODIGO_FAM_FAM'
                      Options.Editing = False
                      Width = 130
                    end
                    object cxgrdbclmnArticulosDESCRIPCION_FAMILIA: TcxGridDBColumn
                      Caption = 'Familia'
                      DataBinding.FieldName = 'DESCRIPCION_FAM'
                      Options.Editing = False
                      Width = 222
                    end
                    object cxgrdbclmnArticulosTIPO_CANTIDAD_ARTICULO: TcxGridDBColumn
                      Caption = 'Tipo Cantidad'
                      DataBinding.FieldName = 'TIPO_CANTIDAD_ARTICULO'
                      Width = 127
                    end
                    object cxgrdbclmnArticulosESACTIVO_FIJO_ARTICULO: TcxGridDBColumn
                      DataBinding.FieldName = 'ESACTIVO_FIJO_ART'
                      Visible = False
                      VisibleForCustomization = False
                    end
                    object cxgrdbclmnArticulosPRECIO_ULT_COMPRA: TcxGridDBColumn
                      Caption = 'Precio '#218'lt. Compra'
                      DataBinding.FieldName = 'PRECIO_ULT_COMPRA'
                      Width = 167
                    end
                    object cxgrdbclmnArticulosFECHA_VALIDEZ: TcxGridDBColumn
                      Caption = 'Fecha '#218'lt Compra'
                      DataBinding.FieldName = 'FECHA_VALIDEZ'
                      Width = 159
                    end
                    object cxgrdbclmnArticulosESPROVEEDORPRINCIPAL: TcxGridDBColumn
                      Caption = 'Proveedor Principal'
                      DataBinding.FieldName = 'ESPROVEEDORPRINCIPAL'
                      Width = 183
                    end
                    object cxgrdbclmnArticulosINSTANTEMODIF: TcxGridDBColumn
                      DataBinding.FieldName = 'INSTANTE_MODIF'
                      Visible = False
                      VisibleForCustomization = False
                    end
                    object cxgrdbclmnArticulosINSTANTEALTA: TcxGridDBColumn
                      DataBinding.FieldName = 'INSTANTE_ALTA'
                      Visible = False
                      VisibleForCustomization = False
                    end
                    object cxgrdbclmnArticulosUSUARIOALTA: TcxGridDBColumn
                      DataBinding.FieldName = 'USUARIO_ALTA'
                      Visible = False
                      VisibleForCustomization = False
                    end
                    object cxgrdbclmnArticulosUSUARIOMODIF: TcxGridDBColumn
                      DataBinding.FieldName = 'USUARIO_MODIF'
                      Visible = False
                      VisibleForCustomization = False
                    end
                  end
                  object cxgrdlvlArticulos: TcxGridLevel
                    GridView = tvArticulos
                  end
                end
              end
            end
            object tsVentas: TcxTabSheet
              Caption = '&3_Ventas'
              ImageIndex = 4
              ExplicitLeft = 0
              ExplicitTop = 0
              ExplicitWidth = 0
              ExplicitHeight = 0
              object cxgrdLinFac: TcxGrid
                Left = 0
                Top = 0
                Width = 580
                Height = 272
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Align = alClient
                TabOrder = 0
                object tvLinFac: TcxGridDBTableView
                  OnDblClick = cxGrdDBTabPrinDblClick
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
                  DataController.Options = [dcoCaseInsensitive, dcoAssignGroupingValues, dcoAssignMasterDetailKeys, dcoSaveExpanding]
                  DataController.Summary.FooterSummaryItems = <
                    item
                      Format = '0.00 '#8364';-0.00 '#8364
                      Kind = skSum
                      Column = cxgrdbclmnLinFacTOTAL_FACTURA_LINEA
                    end>
                  OptionsBehavior.AlwaysShowEditor = True
                  OptionsBehavior.GoToNextCellOnEnter = True
                  OptionsBehavior.IncSearch = True
                  OptionsCustomize.ColumnHiding = True
                  OptionsData.CancelOnExit = False
                  OptionsData.Deleting = False
                  OptionsData.DeletingConfirmation = False
                  OptionsData.Editing = False
                  OptionsData.Inserting = False
                  OptionsView.Footer = True
                  OptionsView.GroupByBox = False
                  OptionsView.Indicator = True
                  object cxgrdbclmnLinFacNRO_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Nro Fact.'
                    DataBinding.FieldName = 'NUMERO_FAC_FACLIN'
                    Width = 83
                  end
                  object cxgrdbclmnLinFacSERIE_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Serie'
                    DataBinding.FieldName = 'SERIE_FAC_FACLIN'
                    Width = 59
                  end
                  object cxgrdbclmnLinFacLINEA_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Nro Linea'
                    DataBinding.FieldName = 'LINEA_FACLIN'
                    Width = 96
                  end
                  object cxgrdbclmnLinFacCANTIDAD_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Cantidad'
                    DataBinding.FieldName = 'CANTIDAD_FACLIN'
                    Width = 89
                  end
                  object cxgrdbclmnLinFacTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Tipo Cantidad'
                    DataBinding.FieldName = 'TIPO_CANTIDAD_ARTICULO_FACLIN'
                    Width = 93
                  end
                  object cxgrdbclmnLinFacCODIGO_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'C'#243'digo Art'#237'culo'
                    DataBinding.FieldName = 'CODIGO_ART_FACLIN'
                    Visible = False
                    VisibleForCustomization = False
                  end
                  object cxgrdbclmnLinFacCODIGO_FAMILIA_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'C'#243'digo Familia'
                    DataBinding.FieldName = 'CODIGO_FAM_FACLIN'
                    Visible = False
                    VisibleForCustomization = False
                  end
                  object cxgrdbclmnLinFacNOMBRE_FAMILIA_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Nombre Familia'
                    DataBinding.FieldName = 'NOMBRE_FAM_FACLIN'
                    Visible = False
                    VisibleForCustomization = False
                  end
                  object cxgrdbclmnLinFacDESCRIPCION_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Descripci'#243'n Art'#237'culo'
                    DataBinding.FieldName = 'DESCRIPCION_ARTICULO_FACLIN'
                    Width = 176
                  end
                  object cxgrdbclmnLinFacNOMBRE_TARIFA: TcxGridDBColumn
                    Caption = 'Tarifa'
                    DataBinding.FieldName = 'NOMBRE_TAR_TAR'
                    Width = 73
                  end
                  object cxgrdbclmnLinFacESIMP_INCL_TARIFA_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Imp Incl'
                    DataBinding.FieldName = 'ESIMP_INCL_TARIFA_FACLIN'
                    Width = 60
                  end
                  object cxgrdbclmnLinFacPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Precio SIVA'
                    DataBinding.FieldName = 'PRECIO_VENTA_SIVA_ARTICULO_FACLIN'
                  end
                  object dbcLinFacNOMBRE_TIPO_IVA: TcxGridDBColumn
                    Caption = 'Tipo de IVA'
                    DataBinding.FieldName = 'NOMBRE_TIPO_IVA_IVATIP'
                  end
                  object cxgrdbclmnLinFacPORCEN_IVA_FACTURA_LINEA: TcxGridDBColumn
                    Caption = '% IVA'
                    DataBinding.FieldName = 'PORCENTAJE_IVA_FACLIN'
                    Width = 57
                  end
                  object cxgrdbclmnLinFacPRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Precio CIVA'
                    DataBinding.FieldName = 'PRECIO_VENTA_CIVA_ARTICULO_FACLIN'
                    Width = 120
                  end
                  object cxgrdbclmnLinFacTOTAL_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Total Linea'
                    DataBinding.FieldName = 'TOTAL_FACLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Options.Editing = False
                    Width = 97
                  end
                  object cxgrdbclmnLinFacFECHA_ENTREGA_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Fecha Entrega'
                    DataBinding.FieldName = 'FECHA_ENTREGA_FACLIN'
                    PropertiesClassName = 'TcxDateEditProperties'
                  end
                  object dbcLinFacCODIGO_TARIFA_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Tarifa Empleada'
                    DataBinding.FieldName = 'CODIGO_TAR_FACLIN'
                    Width = 149
                  end
                  object dbcLinFacCODIGO_CLIENTE_FACTURA: TcxGridDBColumn
                    DataBinding.FieldName = 'CODIGO_CLI_FAC'
                  end
                end
                object cxgrdlvlLinFac: TcxGridLevel
                  GridView = tvLinFac
                end
              end
              object pnl62: TPanel
                Left = 580
                Top = 0
                Width = 118
                Height = 272
                Align = alRight
                BevelOuter = bvNone
                TabOrder = 1
                object btnIraFactura: TcxButton
                  Left = 6
                  Top = 13
                  Width = 110
                  Height = 25
                  Caption = 'Ir a Borrador'
                  TabOrder = 0
                  OnClick = btnIraFacturaClick
                end
                object btnIraCliente: TcxButton
                  Left = 6
                  Top = 53
                  Width = 110
                  Height = 25
                  Caption = 'Ir a Cliente'
                  TabOrder = 1
                  OnClick = btnIraClienteClick
                end
                object btnExportar: TcxButton
                  Left = 6
                  Top = 135
                  Width = 110
                  Height = 24
                  Caption = '&Exp Excel'
                  TabOrder = 2
                  OnClick = btnExportarClick
                end
                object btnIraArticuloVentas: TcxButton
                  Left = 4
                  Top = 93
                  Width = 112
                  Height = 25
                  Caption = 'Ir a Art'#237'culo'
                  TabOrder = 3
                  OnClick = btnIraArticuloClick
                end
              end
            end
            object tsMasDatos: TcxTabSheet
              Caption = '&4_M'#225's datos'
              ImageIndex = 1
              ExplicitLeft = 0
              ExplicitTop = 0
              ExplicitWidth = 0
              ExplicitHeight = 0
              object lblObservaciones: TcxLabel
                Left = -8
                Top = 105
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Caption = 'Observaciones'
                Properties.Alignment.Horz = taRightJustify
                TabOrder = 2
                Transparent = True
                AnchorX = 118
              end
              object lblReferencia: TcxLabel
                Left = 28
                Top = 66
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Caption = 'Referencia'
                Properties.Alignment.Horz = taRightJustify
                TabOrder = 3
                Transparent = True
                AnchorX = 118
              end
              object cxdbtxtdtREFERENCIA_CLIENTE: TcxDBTextEdit
                Left = 126
                Top = 62
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                DataBinding.DataField = 'REFERENCIA_PRV'
                DataBinding.DataSource = dsTablaG
                TabOrder = 4
                Width = 519
              end
              object lblContacto: TcxLabel
                Left = 39
                Top = 23
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Caption = 'Contacto'
                Properties.Alignment.Horz = taRightJustify
                TabOrder = 5
                Transparent = True
                AnchorX = 118
              end
              object cxdbtxtdtREFERENCIA_CLIENTE1: TcxDBTextEdit
                Left = 126
                Top = 19
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                DataBinding.DataField = 'CONTACTO_PRV'
                DataBinding.DataSource = dsTablaG
                TabOrder = 0
                Width = 188
              end
              object cxdbtxtdtIBAN: TcxDBTextEdit
                Left = 126
                Top = 212
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                DataBinding.DataField = 'IBAN_PRV'
                DataBinding.DataSource = dsTablaG
                TabOrder = 8
                Width = 323
              end
              object lblNroCuenta: TcxLabel
                Left = -3
                Top = 213
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Caption = 'IBAN Bancario'
                Properties.Alignment.Horz = taRightJustify
                TabOrder = 7
                Transparent = True
                AnchorX = 118
              end
              object lblTelefonoContacto: TcxLabel
                Left = 341
                Top = 23
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Caption = 'Tel'#233'fono Contacto'
                TabOrder = 9
                Transparent = True
              end
              object cxdbtxtdtCONTACTO_CLIENTE: TcxDBTextEdit
                Left = 513
                Top = 19
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                DataBinding.DataField = 'TELEFONO_CONTACTO_PRV'
                DataBinding.DataSource = dsTablaG
                TabOrder = 1
                Width = 188
              end
              object cxdbm2: TcxDBMemo
                Left = 126
                Top = 101
                DataBinding.DataField = 'OBSERVACIONES_PRV'
                DataBinding.DataSource = dsTablaG
                TabOrder = 6
                Height = 89
                Width = 575
              end
            end
            object tsOtros: TcxTabSheet
              Caption = '&5_Otros'
              ImageIndex = 4
              object pnl3: TPanel
                Left = 0
                Top = 193
                Width = 698
                Height = 79
                Align = alBottom
                BevelOuter = bvNone
                TabOrder = 2
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
                  Left = 170
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
                  Left = 170
                  Top = 37
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'INSTANTE_ALTA'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 3
                  Width = 193
                end
                object cxdbtxtdtINSTANTEALTA: TcxDBTextEdit
                  Left = 534
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
                  Left = 534
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
                  Left = 366
                  Top = 37
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'USUARIO_ALTA'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 4
                  Width = 140
                end
                object lblUsuarioModif: TcxLabel
                  Left = 366
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
              object lblTextoLegal11: TcxLabel
                Left = 353
                Top = 139
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Caption = 'Orden en Listados'
                TabOrder = 1
                Transparent = True
              end
              object cxdbspndtORDEN_CLIENTE: TcxDBSpinEdit
                Left = 520
                Top = 138
                DataBinding.DataField = 'ORDEN_PRV'
                DataBinding.DataSource = dsTablaG
                TabOrder = 0
                Width = 106
              end
            end
            object tsCompras: TcxTabSheet
              Caption = '&6_Compras'
              ImageIndex = 5
              object gbDefectosCompras: TcxGroupBox
                Left = 0
                Top = 0
                Align = alTop
                Caption = ' Defectos para sesiones de compra '
                TabOrder = 0
                Height = 158
                Width = 698
                object rbCoeficientePrv: TcxRadioButton
                  Left = 16
                  Top = 26
                  Caption = 'Coeficiente PVP %'
                  Checked = True
                  TabStop = True
                  TabOrder = 20
                  Transparent = True
                  Width = 165
                  OnClick = CambiarModoPrecio
                end
                object rbMargenVentaPrv: TcxRadioButton
                  Left = 16
                  Top = 54
                  Caption = 'Margen sobre venta %'
                  TabOrder = 21
                  Transparent = True
                  Width = 165
                  OnClick = CambiarModoPrecio
                end
                object spnMargenVentaPrv: TcxSpinEdit
                  Left = 190
                  Top = 54
                  Enabled = False
                  Hint = 'PVP = coste / (1 - margen / 100). Ej.: 20 % de 4,50 = 5,625.'
                  ShowHint = True
                  Properties.ValueType = vtFloat
                  Properties.DisplayFormat = '0.00'
                  Properties.MinValue = -100000.000000000000000000
                  Properties.MaxValue = 99.990000000000000000
                  Properties.ImmediatePost = True
                  Properties.OnChange = CambiarMargenVenta
                  Properties.OnEditValueChanged = CambiarMargenVenta
                  TabOrder = 22
                  Width = 92
                end
                object spnMargenPrv: TcxDBSpinEdit
                  Hint = 'PVP = coste × coeficiente / 100. Ej.: 120 % de 4,50 = 5,40.'
                  ShowHint = True
                  Left = 190
                  Top = 26
                  DataBinding.DataField = 'PORCENTAJE_MARGEN_PRV'
                  DataBinding.DataSource = dsTablaG
                  Properties.ValueType = vtFloat
                  Properties.OnEditValueChanged = ActualizarMargenVenta
                  TabOrder = 1
                  Width = 92
                end
                object chkVariosTiposIvaPrv: TcxDBCheckBox
                  Left = 300
                  Top = 26
                  Caption = 'Varios tipos IVA artículos'
                  DataBinding.DataField = 'ESVARIOS_TIPOS_IVA_PRV'
                  DataBinding.DataSource = dsTablaG
                  Properties.ValueChecked = 'S'
                  Properties.ValueUnchecked = 'N'
                  Style.TransparentBorder = False
                  TabOrder = 2
                  Transparent = True
                end
                object lblSistemaTallasPrv: TcxLabel
                  Left = 16
                  Top = 92
                  Caption = 'Sistema tallas'
                  TabOrder = 3
                  Transparent = True
                end
                object cbbSistemaTallasPrv: TcxDBLookupComboBox
                  Left = 120
                  Top = 88
                  DataBinding.DataField = 'ID_AC_TALLAS_PRV'
                  DataBinding.DataSource = dsTablaG
                  Properties.KeyFieldNames = 'ID_AC'
                  Properties.ListColumns = <
                    item
                      FieldName = 'NOMBRE_AC'
                    end>
                  Properties.ListOptions.ShowHeader = False
                  TabOrder = 4
                  Width = 220
                end
                object chkESDESCRIPCION_BLANCO_PRV: TcxDBCheckBox
                  Left = 368
                  Top = 88
                  Caption = ''
                  DataBinding.DataField = 'ESDESCRIPCION_BLANCO_PRV'
                  DataBinding.DataSource = dsTablaG
                  Properties.AllowGrayed = False
                  Properties.ValueChecked = 'S'
                  Properties.ValueUnchecked = 'N'
                  Style.TransparentBorder = False
                  TabOrder = 5
                  Transparent = True
                  Width = 314
                end
                object lblDefectosInfo: TcxLabel
                  Left = 16
                  Top = 122
                  Caption =
                    'Se aplican al elegir este proveedor en una sesi'#243'n de compra' +
                    ' (el sistema de tallas solo propone el defecto; cada l'#237'nea ' +
                    'lo puede cambiar).'
                  TabOrder = 6
                  Transparent = True
                end
              end
              object gbKitsPrv: TcxGroupBox
                Left = 0
                Top = 130
                Align = alClient
                Caption = ' Kits de cantidades por talla '
                TabOrder = 1
                Height = 142
                Width = 698
                object pnlKitsTop: TPanel
                  Left = 2
                  Top = 18
                  Width = 694
                  Height = 34
                  Align = alTop
                  BevelOuter = bvNone
                  TabOrder = 0
                  object btnAddKit: TcxButton
                    Left = 8
                    Top = 3
                    Width = 90
                    Height = 26
                    Caption = '+ Kit'
                    TabOrder = 0
                    OnClick = btnAddKitClick
                  end
                  object btnDelKit: TcxButton
                    Left = 102
                    Top = 3
                    Width = 90
                    Height = 26
                    Caption = '- Kit'
                    TabOrder = 1
                    OnClick = btnDelKitClick
                  end
                  object btnGenerarTallasKit: TcxButton
                    Left = 196
                    Top = 3
                    Width = 200
                    Height = 26
                    Caption = 'A'#241'adir todas las tallas'
                    TabOrder = 2
                    OnClick = btnGenerarTallasKitClick
                  end
                  object btnAddKitDet: TcxButton
                    Left = 400
                    Top = 3
                    Width = 90
                    Height = 26
                    Caption = '+ Talla'
                    TabOrder = 3
                    OnClick = btnAddKitDetClick
                  end
                  object btnDelKitDet: TcxButton
                    Left = 494
                    Top = 3
                    Width = 90
                    Height = 26
                    Caption = '- Talla'
                    TabOrder = 4
                    OnClick = btnDelKitDetClick
                  end
                end
                object cxgrdKits: TcxGrid
                  Left = 2
                  Top = 52
                  Width = 404
                  Height = 126
                  Align = alClient
                  TabOrder = 1
                  object tvKits: TcxGridDBTableView
                    OptionsBehavior.AlwaysShowEditor = True
                    OptionsBehavior.IncSearch = False
                    OptionsBehavior.ImmediateEditor = True
                    Navigator.Buttons.ConfirmDelete = True
                    Navigator.Buttons.First.Hint = 'Va al primer registro'
                    Navigator.Buttons.PriorPage.Visible = False
                    Navigator.Buttons.Prior.Hint = 'Va al registro anterior'
                    Navigator.Buttons.Next.Hint = 'Va al siguiente registro'
                    Navigator.Buttons.NextPage.Visible = False
                    Navigator.Buttons.Last.Hint = 'Va al '#250'ltimo registro'
                    Navigator.Buttons.Insert.Hint = 'Inserta un nuevo registro'
                    Navigator.Buttons.Append.Visible = False
                    Navigator.Buttons.Delete.Hint = 'Borra el registro activo'
                    Navigator.Buttons.Edit.Visible = False
                    Navigator.Buttons.Post.Hint = 'Guarda los datos introducidos'
                    Navigator.Buttons.Cancel.Hint = 'Cancela la edici'#243'n actual'
                    Navigator.Buttons.Refresh.Visible = False
                    Navigator.Buttons.SaveBookmark.Visible = False
                    Navigator.Buttons.GotoBookmark.Visible = False
                    Navigator.Buttons.Filter.Visible = False
                    Navigator.Visible = True
                    OptionsView.GroupByBox = False
                    object dbcKitCodigo: TcxGridDBColumn
                      Caption = 'C'#243'digo'
                      DataBinding.FieldName = 'CODIGO_PRVKIT'
                      PropertiesClassName = 'TcxTextEditProperties'
                      Properties.CharCase = ecUpperCase
                      Properties.MaxLength = 20
                      Width = 100
                    end
                    object dbcKitNombre: TcxGridDBColumn
                      Caption = 'Nombre'
                      DataBinding.FieldName = 'NOMBRE_PRVKIT'
                      PropertiesClassName = 'TcxTextEditProperties'
                      Properties.MaxLength = 100
                      Width = 160
                    end
                    object dbcKitSistema: TcxGridDBColumn
                      Caption = 'Sistema tallas'
                      DataBinding.FieldName = 'ID_AC_TALLAS_PRVKIT'
                      PropertiesClassName = 'TcxLookupComboBoxProperties'
                      Properties.KeyFieldNames = 'ID_AC'
                      Properties.ListColumns = <
                        item
                          Caption = 'Sistema'
                          FieldName = 'NOMBRE_AC'
                        end>
                      Properties.ListOptions.ShowHeader = False
                      Width = 150
                    end
                  end
                  object glKits: TcxGridLevel
                    GridView = tvKits
                  end
                end
                object cxgrdKitsDet: TcxGrid
                  Left = 406
                  Top = 52
                  Width = 290
                  Height = 126
                  Align = alRight
                  TabOrder = 2
                  object tvKitsDet: TcxGridDBTableView
                    OptionsBehavior.AlwaysShowEditor = True
                    OptionsBehavior.IncSearch = False
                    OptionsBehavior.ImmediateEditor = True
                    Navigator.Buttons.ConfirmDelete = True
                    Navigator.Buttons.First.Hint = 'Va al primer registro'
                    Navigator.Buttons.PriorPage.Visible = False
                    Navigator.Buttons.Prior.Hint = 'Va al registro anterior'
                    Navigator.Buttons.Next.Hint = 'Va al siguiente registro'
                    Navigator.Buttons.NextPage.Visible = False
                    Navigator.Buttons.Last.Hint = 'Va al '#250'ltimo registro'
                    Navigator.Buttons.Insert.Hint = 'Inserta un nuevo registro'
                    Navigator.Buttons.Append.Visible = False
                    Navigator.Buttons.Delete.Hint = 'Borra el registro activo'
                    Navigator.Buttons.Edit.Visible = False
                    Navigator.Buttons.Post.Hint = 'Guarda los datos introducidos'
                    Navigator.Buttons.Cancel.Hint = 'Cancela la edici'#243'n actual'
                    Navigator.Buttons.Refresh.Visible = False
                    Navigator.Buttons.SaveBookmark.Visible = False
                    Navigator.Buttons.GotoBookmark.Visible = False
                    Navigator.Buttons.Filter.Visible = False
                    Navigator.Visible = True
                    OptionsView.GroupByBox = False
                    object dbcKitDetValor: TcxGridDBColumn
                      Caption = 'Talla'
                      DataBinding.FieldName = 'VALOR_DESTINO_PRVKITD'
                      PropertiesClassName = 'TcxTextEditProperties'
                      Properties.CharCase = ecUpperCase
                      Properties.MaxLength = 50
                      Width = 90
                    end
                    object dbcKitDetCantidad: TcxGridDBColumn
                      Caption = 'Cantidad'
                      DataBinding.FieldName = 'CANTIDAD_PRVKITD'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Properties.DisplayFormat = '#,##0.##'
                      Width = 90
                    end
                    object dbcKitDetOrden: TcxGridDBColumn
                      Caption = 'Orden'
                      DataBinding.FieldName = 'ORDEN_PRVKITD'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Width = 70
                    end
                  end
                  object glKitsDet: TcxGridLevel
                    GridView = tvKitsDet
                  end
                end
              end
            end
            object tsPagos: TcxTabSheet
              Caption = '&7_Pagos'
              object lblFormaPagoPrv: TcxLabel
                Left = 34
                Top = 25
                Caption = 'Forma de pago'
                TabOrder = 0
                Transparent = True
              end
              object cbbFormaPagoPrv: TcxDBLookupComboBox
                Left = 260
                Top = 21
                DataBinding.DataField = 'CODIGO_FP_PRV'
                DataBinding.DataSource = dsTablaG
                Properties.KeyFieldNames = 'CODIGO_FP_FP'
                Properties.ListColumns = <
                  item
                    FieldName = 'DESCRIPCION_FORMA_PAGO_FP'
                  end>
                Properties.ListOptions.ShowHeader = False
                TabOrder = 1
                Width = 320
              end
              object lblEmpBanPrv: TcxLabel
                Left = 34
                Top = 65
                Caption = 'Banco para pagos (empresa)'
                TabOrder = 2
                Transparent = True
              end
              object cbbEmpBanPrv: TcxDBLookupComboBox
                Left = 260
                Top = 61
                DataBinding.DataField = 'CODIGO_EMPBAN_PRV'
                DataBinding.DataSource = dsTablaG
                Properties.KeyFieldNames = 'CODIGO_EMPBAN'
                Properties.ListColumns = <
                  item
                    Caption = 'Cuenta'
                    FieldName = 'NOMBRE_EMPBAN'
                  end
                  item
                    Caption = 'IBAN'
                    FieldName = 'IBAN_EMPBAN'
                  end
                  item
                    Caption = 'Banco'
                    FieldName = 'NOMBRE_BAN_VIEW_EMPBAN'
                  end
                  item
                    Caption = 'Empresa'
                    FieldName = 'CODIGO_EMP_EMPBAN'
                  end>
                TabOrder = 3
                Width = 470
              end
            end
          end
        end
        object cxspltr1: TcxSplitter
          Left = 0
          Top = 137
          Width = 706
          Height = 8
          HotZoneClassName = 'TcxMediaPlayer9Style'
          AlignSplitter = salTop
          Control = pnlDetailFicha
          ExplicitWidth = 8
        end
      end
      inherited tsPerfil: TcxTabSheet
        ExplicitWidth = 706
        ExplicitHeight = 451
        inherited pnlPerfilTop: TPanel
          Width = 706
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 706
          inherited edtPerfilBusq: TcxTextEdit
            ExplicitHeight = 27
          end
        end
        inherited pnlPerfilDetail: TPanel
          Width = 706
          Height = 394
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 706
          ExplicitHeight = 394
          inherited cxgrdPerfil: TcxGrid
            Width = 706
            Height = 394
            ExplicitWidth = 706
            ExplicitHeight = 394
          end
        end
      end
    end
    inherited pnlTopPage: TPanel
      Width = 714
      TabOrder = 0
      StyleElements = [seFont, seClient, seBorder]
      ExplicitWidth = 714
      inherited pnlTopGrid: TPanel
        Width = 714
        StyleElements = [seFont, seClient, seBorder]
        ExplicitWidth = 714
        inherited edtBusqGlobal: TcxTextEdit
          ExplicitHeight = 27
        end
        inherited nvNavegador: TcxDBNavigator
          Top = 5
          Height = 25
          TabOrder = 3
          ExplicitTop = 5
          ExplicitHeight = 25
        end
        inherited lblTextoaBuscar: TcxLabel
          TabOrder = 4
        end
        inherited rbBBDD: TcxRadioButton
          TabOrder = 2
        end
      end
    end
  end
  inherited pButtonRightBar: TPanel
    Left = 714
    Width = 154
    Height = 525
    TabOrder = 1
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 714
    ExplicitWidth = 154
    ExplicitHeight = 525
    inherited pButtonGen: TPanel
      Top = 327
      Width = 154
      StyleElements = [seFont, seClient, seBorder]
      ExplicitTop = 327
      ExplicitWidth = 154
    end
    inherited pButtonBDStat: TPanel
      Width = 154
      StyleElements = [seFont, seClient, seBorder]
      ExplicitWidth = 154
      inherited pnStateDataSet: TPanel
        Width = 154
        StyleElements = [seFont, seClient, seBorder]
        ExplicitWidth = 154
      end
      inherited pnlDataSetName: TPanel
        Width = 154
        StyleElements = [seFont, seClient, seBorder]
        ExplicitWidth = 154
      end
    end
    object btnNuevoProveedor: TcxButton
      Left = 1
      Top = 154
      Width = 149
      Height = 25
      Caption = '&Nuevo Proveedor'
      TabOrder = 2
      OnClick = btnNuevoProveedorClick
    end
  end
  inherited Localizer1: TcxLocalizer
    Left = 128
    Top = 416
  end
  inherited dsTablaG: TDataSource
    DataSet = dmProveedores.unqryTablaG
    Left = 24
    Top = 488
  end
  object ActionListProveedores: TActionList
    Left = 424
    Top = 248
    object actArticulos: TAction
      Caption = 'Articulos'
      ShortCut = 16466
      OnExecute = actArticulosExecute
    end
    object actFacturas: TAction
      Caption = 'Borradores'
      ShortCut = 49222
      OnExecute = actFacturasExecute
    end
    object actClientes: TAction
      Caption = 'Clientes'
      ShortCut = 16459
      OnExecute = actClientesExecute
    end
  end
end
