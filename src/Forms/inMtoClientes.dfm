inherited frmMtoClientes: TfrmMtoClientes
  Caption = 'Clientes'
  ClientHeight = 703
  ClientWidth = 1141
  StyleElements = [seFont, seClient, seBorder]
  ExplicitWidth = 1141
  ExplicitHeight = 703
  TextHeight = 17
  inherited pButtonPage: TPanel
    Width = 1001
    Height = 703
    TabOrder = 0
    StyleElements = [seFont, seClient, seBorder]
    ExplicitWidth = 1001
    ExplicitHeight = 703
    inherited pcPantalla: TcxPageControl
      Width = 1001
      Height = 663
      TabOrder = 1
      ExplicitWidth = 1001
      ExplicitHeight = 663
      ClientRectBottom = 659
      ClientRectRight = 997
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 28
        ExplicitWidth = 993
        ExplicitHeight = 631
        inherited cxGrdPrincipal: TcxGrid
          Width = 993
          Height = 631
          ParentFont = False
          ExplicitWidth = 993
          ExplicitHeight = 631
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            object cxgrdbclmnGrdDBTabPrinCODIGO_CLIENTE: TcxGridDBColumn
              Caption = 'C'#243'digo'
              DataBinding.FieldName = 'CODIGO_CLI_CLI'
              Width = 106
            end
            object cxgrdbclmnGrdDBTabPrinACTIVO_CLIENTE: TcxGridDBColumn
              Caption = 'Activo'
              DataBinding.FieldName = 'ESACTIVO_CLI'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 69
            end
            object cxgrdbclmnGrdDBTabPrinRAZONSOCIAL_CLIENTE: TcxGridDBColumn
              Caption = 'Raz'#243'n Social'
              DataBinding.FieldName = 'RAZON_SOCIAL_CLI'
              Width = 212
            end
            object cxgrdbclmnGrdDBTabPrinNIF_CLIENTE: TcxGridDBColumn
              Caption = 'Nif Cif'
              DataBinding.FieldName = 'NIF_CLI'
              PropertiesClassName = 'TcxMaskEditProperties'
              Width = 104
            end
            object cxgrdbclmnGrdDBTabPrinMOVIL_CLIENTE: TcxGridDBColumn
              Caption = 'Tel'#233'fono M'#243'vil'
              DataBinding.FieldName = 'MOVIL_CLI'
              Width = 150
            end
            object cxgrdbclmnGrdDBTabPrinTELEFONO_CLIENTE: TcxGridDBColumn
              Caption = 'Tel'#233'fono fijo'
              DataBinding.FieldName = 'TELEFONO_CLI'
              Width = 123
            end
            object cxgrdbclmnGrdDBTabPrinEMAIL_CLIENTE: TcxGridDBColumn
              Caption = 'Email'
              DataBinding.FieldName = 'EMAIL_CLI'
              Width = 196
            end
            object cxgrdbclmnGrdDBTabPrinDIRECCION1_CLIENTE: TcxGridDBColumn
              Caption = 'Direcci'#243'n'
              DataBinding.FieldName = 'DIRECCION1_CLI'
              Width = 251
            end
            object cxgrdbclmnGrdDBTabPrinDIRECCION2_CLIENTE: TcxGridDBColumn
              Caption = 'M'#225's Direcci'#243'n'
              DataBinding.FieldName = 'DIRECCION2_CLI'
              Width = 173
            end
            object cxgrdbclmnGrdDBTabPrinPOBLACION_CLIENTE: TcxGridDBColumn
              Caption = 'Poblaci'#243'n'
              DataBinding.FieldName = 'POBLACION_CLI'
              Width = 146
            end
            object cxgrdbclmnGrdDBTabPrinPROVINCIA_CLIENTE: TcxGridDBColumn
              Caption = 'Provincia'
              DataBinding.FieldName = 'PROVINCIA_CLI'
              Width = 135
            end
            object cxgrdbclmnGrdDBTabPrinCPOSTAL_CLIENTE: TcxGridDBColumn
              Caption = 'C'#243'digo Postal'
              DataBinding.FieldName = 'CODIGO_POSTAL_CLI'
              Width = 95
            end
            object cxgrdbclmnGrdDBTabPrinPAIS_CLIENTE: TcxGridDBColumn
              Caption = 'Pa'#237's'
              DataBinding.FieldName = 'PAIS_CLIENTE'
              Width = 118
            end
            object cxgrdbclmnGrdDBTabPrinOBSERVACIONES_CLIENTE: TcxGridDBColumn
              Caption = 'Observaciones'
              DataBinding.FieldName = 'OBSERVACIONES_CLI'
              Width = 192
            end
            object cxgrdbclmnGrdDBTabPrinREFERENCIA_CLIENTE: TcxGridDBColumn
              Caption = 'Referencia'
              DataBinding.FieldName = 'REFERENCIA_CLI'
              Width = 184
            end
            object cxgrdbclmnGrdDBTabPrinCONTACTO_CLIENTE: TcxGridDBColumn
              Caption = 'Contacto'
              DataBinding.FieldName = 'CONTACTO_CLI'
              Width = 151
            end
            object cxgrdbclmnGrdDBTabPrinTELEFONO_CONTACTO_CLIENTE: TcxGridDBColumn
              Caption = 'Tel'#233'fono de Contacto'
              DataBinding.FieldName = 'TELEFONO_CONTACTO_CLI'
              Width = 140
            end
            object cxgrdbclmnGrdDBTabPrinIBAN_CLIENTE: TcxGridDBColumn
              Caption = 'Nro Cuenta'
              DataBinding.FieldName = 'IBAN_CLI'
              Visible = False
              Width = 50
            end
            object cxgrdbclmnGrdDBTabPrinIVA_RECARGO_CLIENTE: TcxGridDBColumn
              Caption = 'Aplicar RE'
              DataBinding.FieldName = 'ESIVA_RECARGO_CLI'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.DisplayChecked = 'False'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 109
            end
            object cxgrdbclmnGrdDBTabPrinTEXTO_LEGAL_FACTURA_CLIENTE: TcxGridDBColumn
              Caption = 'Texto Legal Borrador'
              DataBinding.FieldName = 'TEXTO_LEGAL_FACTURA_CLI'
              Visible = False
              Width = 100
            end
            object cxgrdbclmnGrdDBTabPrinRETENCIONES_CLIENTE: TcxGridDBColumn
              Caption = 'Aplicar Retenciones'
              DataBinding.FieldName = 'ESRETENCIONES_CLI'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 184
            end
            object cxGrdDBTabPrinESIVA_EXENTO_CLIENTE: TcxGridDBColumn
              Caption = 'Tiene IVA exento'
              DataBinding.FieldName = 'ESIVA_EXENTO_CLI'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 166
            end
            object cxGrdDBTabPrinESINTRACOMUNITARIO_CLIENTE: TcxGridDBColumn
              Caption = 'Es Intracomunitario'
              DataBinding.FieldName = 'ESINTRACOMUNITARIO_CLI'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 179
            end
            object cxGrdDBTabPrinESREGIMENESPECIALAGRICOLA_CLIENTE: TcxGridDBColumn
              Caption = 'Es Agricultor'
              DataBinding.FieldName = 'ESREGIMENESPECIALAGRICOLA_CLI'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 127
            end
            object cxGrdDBTabPrinCODIGO_FORMA_PAGO_CLIENTE: TcxGridDBColumn
              Caption = 'Forma de pago por defecto'
              DataBinding.FieldName = 'CODIGO_FP_CLI'
              Width = 278
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 28
        ExplicitWidth = 993
        ExplicitHeight = 631
        object pnlTopFicha: TPanel
          Left = 0
          Top = 0
          Width = 993
          Height = 179
          Margins.Left = 4
          Margins.Top = 4
          Margins.Right = 4
          Margins.Bottom = 4
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          DesignSize = (
            993
            179)
          object cxgrpbxObservaciones: TcxGroupBox
            AlignWithMargins = True
            Left = 22
            Top = 0
            TabStop = True
            Anchors = [akLeft, akTop, akRight, akBottom]
            TabOrder = 0
            Height = 167
            Width = 885
            object lblRazonSocial: TcxLabel
              Left = 200
              Top = 10
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              Caption = 'Raz'#243'n Social Fiscal'
              TabOrder = 0
              Transparent = True
            end
            object lblCodigoCliente: TcxLabel
              Left = 21
              Top = 10
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              Caption = 'C'#243'digo'
              TabOrder = 1
              Transparent = True
            end
            object txtCODIGO_CLIENTE: TcxDBTextEdit
              Left = 21
              Top = 34
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              BiDiMode = bdLeftToRight
              DataBinding.DataField = 'CODIGO_CLI_CLI'
              DataBinding.DataSource = dsTablaG
              ParentBiDiMode = False
              Properties.Alignment.Horz = taRightJustify
              TabOrder = 2
              Width = 149
            end
            object txtRAZONSOCIAL_CLIENTE: TcxDBTextEdit
              Left = 200
              Top = 34
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              DataBinding.DataField = 'RAZON_SOCIAL_CLI'
              DataBinding.DataSource = dsTablaG
              TabOrder = 3
              Width = 507
            end
            object chkActivo: TcxDBCheckBox
              Left = 21
              Top = 68
              Caption = 'Activo'
              DataBinding.DataField = 'ESACTIVO_CLI'
              DataBinding.DataSource = dsTablaG
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Style.TransparentBorder = False
              TabOrder = 4
              Transparent = True
            end
            object lblEmail: TcxLabel
              AutoSize = False
              Width = 72
              Height = 24
              Left = 301
              Top = 78
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              Caption = 'Email'
              TabOrder = 5
              Transparent = True
            end
            object txtEMAIL_CLIENTE: TcxDBTextEdit
              Left = 378
              Top = 78
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              DataBinding.DataField = 'EMAIL_CLI'
              DataBinding.DataSource = dsTablaG
              TabOrder = 6
              Width = 328
            end
            object lblNif: TcxLabel
              Left = 22
              Top = 107
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              Caption = 'NIF/CIF'
              TabOrder = 7
              Transparent = True
            end
            object txtNIF_CLIENTE: TcxDBTextEdit
              Left = 22
              Top = 130
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              DataBinding.DataField = 'NIF_CLI'
              DataBinding.DataSource = dsTablaG
              TabOrder = 8
              Width = 149
            end
            object lblTelefonos: TcxLabel
              Left = 264
              Top = 123
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              Caption = 'Tel'#233'fonos'
              TabOrder = 9
              Transparent = True
            end
            object txtMOVIL_CLIENTE: TcxDBTextEdit
              Left = 355
              Top = 122
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              DataBinding.DataField = 'MOVIL_CLI'
              DataBinding.DataSource = dsTablaG
              TabOrder = 10
              Width = 163
            end
            object txtTELEFONO_CLIENTE: TcxDBTextEdit
              Left = 526
              Top = 122
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              DataBinding.DataField = 'TELEFONO_CLI'
              DataBinding.DataSource = dsTablaG
              TabOrder = 11
              Width = 180
            end
          end
        end
        object pnlBodyFicha: TPanel
          Left = 0
          Top = 187
          Width = 993
          Height = 444
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
            Width = 993
            Height = 444
            Margins.Left = 4
            Margins.Top = 4
            Margins.Right = 4
            Margins.Bottom = 4
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsMasDatos
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 440
            ClientRectLeft = 4
            ClientRectRight = 989
            ClientRectTop = 28
            object tsDomicilioFiscal: TcxTabSheet
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              Caption = '&1_Domicilio fiscal'
              ImageIndex = 0
              object scrDomicilioFiscal: TcxScrollBox
                Left = 0
                Top = 0
                Width = 985
                Height = 412
                Align = alClient
                BorderStyle = cxcbsNone
                TabOrder = 0
                DesignSize = (
                  985
                  412)
                object cxgrpbxIdentificacion: TcxGroupBox
                  AlignWithMargins = True
                  Left = 18
                  Top = 0
                  TabStop = True
                  Anchors = [akLeft, akTop]
                  TabOrder = 0
                  Height = 265
                  Width = 620
                  object lblDireccion1Texto: TcxLabel
                    Left = 47
                    Top = 25
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    Caption = 'Direcci'#243'n 1'
                    Properties.Alignment.Horz = taRightJustify
                    TabOrder = 0
                    Transparent = True
                    AnchorX = 135
                  end
                  object txtDIRECCION1_CLIENTE: TcxDBTextEdit
                    Left = 147
                    Top = 21
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    DataBinding.DataField = 'DIRECCION1_CLI'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 1
                    Width = 303
                  end
                  object lblDireccion2Texto: TcxLabel
                    Left = 47
                    Top = 64
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    Caption = 'Direcci'#243'n 2'
                    Properties.Alignment.Horz = taRightJustify
                    TabOrder = 2
                    Transparent = True
                    AnchorX = 135
                  end
                  object txtDIRECCION2_CLIENTE: TcxDBTextEdit
                    Left = 147
                    Top = 60
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    DataBinding.DataField = 'DIRECCION2_CLI'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 3
                    Width = 304
                  end
                  object lblCodPostal: TcxLabel
                    Left = 29
                    Top = 103
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    Caption = 'C'#243'digo Postal'
                    Properties.Alignment.Horz = taRightJustify
                    TabOrder = 4
                    Transparent = True
                    AnchorX = 135
                  end
                  object txtCPOSTAL_CLIENTE: TcxDBTextEdit
                    Left = 147
                    Top = 99
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    DataBinding.DataField = 'CODIGO_POSTAL_CLI'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 5
                    Width = 77
                  end
                  object lblPoblacion: TcxLabel
                    Left = 58
                    Top = 143
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    Caption = 'Poblaci'#243'n'
                    Properties.Alignment.Horz = taRightJustify
                    TabOrder = 6
                    Transparent = True
                    AnchorX = 135
                  end
                  object txtPOBLACION_CLIENTE: TcxDBTextEdit
                    Left = 147
                    Top = 139
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    DataBinding.DataField = 'POBLACION_CLI'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 7
                    Width = 303
                  end
                  object lblProvincia: TcxLabel
                    Left = 63
                    Top = 182
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    Caption = 'Provincia'
                    Properties.Alignment.Horz = taRightJustify
                    TabOrder = 8
                    Transparent = True
                    AnchorX = 135
                  end
                  object txtPROVINCIA_CLIENTE: TcxDBTextEdit
                    Left = 147
                    Top = 178
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    DataBinding.DataField = 'PROVINCIA_CLI'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 9
                    Width = 303
                  end
                  object lblPais: TcxLabel
                    Left = 102
                    Top = 222
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    Caption = 'Pa'#237's'
                    Properties.Alignment.Horz = taRightJustify
                    TabOrder = 10
                    Transparent = True
                    AnchorX = 135
                  end
                  object txtPAIS_CLIENTE: TcxDBTextEdit
                    Left = 147
                    Top = 218
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    DataBinding.DataField = 'NOMBRE_PAI_CLI'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 11
                    Visible = False
                    Width = 237
                  end
                  object txtNOMBRE_PAIS_CLIENTE: TcxDBTextEdit
                    Left = 402
                    Top = 218
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    DataBinding.DataField = 'CODIGO_PAI_CLI'
                    DataBinding.DataSource = dsTablaG
                    Enabled = False
                    Properties.OnChange = txtNOMBRE_PAIS_CLIENTEPropertiesChange
                    TabOrder = 12
                    Width = 48
                  end
                  object cbbPaises: TcxDBLookupComboBox
                    Left = 147
                    Top = 218
                    DataBinding.DataField = 'CODIGO_PAI_CLI'
                    DataBinding.DataSource = dsTablaG
                    Properties.KeyFieldNames = 'CODIGO'
                    Properties.ListColumns = <
                      item
                        Caption = 'Nombre Pais'
                        FieldName = 'NOMBRE'
                      end>
                    Properties.ListOptions.CaseInsensitive = True
                    Properties.ListOptions.ShowHeader = False
                    Properties.ListSource = dmClientes.dsPaises
                    TabOrder = 13
                    Width = 203
                  end
                end
                object cxgrpbxTratamientoFiscal: TcxGroupBox
                  Left = 646
                  Top = 0
                  TabStop = True
                  Anchors = [akTop, akRight]
                  Caption = 'Tratamiento Fiscal'
                  TabOrder = 1
                  Height = 265
                  Width = 321
                  object chkREGIMENAGRICOLA: TcxDBCheckBox
                    Left = 6
                    Top = 24
                    Hint = 
                      'S'#243'lo es importante para empresas que facturen de agricultor a ag' +
                      'ricultor'
                    Caption = 'R'#233'gimen especial agricola/ganadero/pesca'
                    DataBinding.DataField = 'ESREGIMENESPECIALAGRICOLA_CLI'
                    DataBinding.DataSource = dsTablaG
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    Style.TransparentBorder = False
                    TabOrder = 0
                    Transparent = True
                  end
                  object chkINTRACOMUNITARIO: TcxDBCheckBox
                    Left = 6
                    Top = 66
                    Caption = 'Es Intracomunitario'
                    DataBinding.DataField = 'ESINTRACOMUNITARIO_CLI'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayUnchecked = 'True'
                    Properties.DisplayGrayed = 'False'
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    Style.TransparentBorder = False
                    TabOrder = 1
                    Transparent = True
                  end
                  object chkIVAEXENTO: TcxDBCheckBox
                    Left = 6
                    Top = 108
                    Caption = 'IVA Exento'
                    DataBinding.DataField = 'ESIVA_EXENTO_CLI'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayUnchecked = 'True'
                    Properties.DisplayGrayed = 'False'
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    Style.TransparentBorder = False
                    TabOrder = 2
                    Transparent = True
                  end
                  object chkRECARGO_EQUIV: TcxDBCheckBox
                    Left = 6
                    Top = 150
                    Caption = 'Con recargo de equivalencia'
                    DataBinding.DataField = 'ESIVA_RECARGO_CLI'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayUnchecked = 'True'
                    Properties.DisplayGrayed = 'False'
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    Style.TransparentBorder = False
                    TabOrder = 3
                    Transparent = True
                  end
                  object chkRETENCIONES: TcxDBCheckBox
                    Left = 6
                    Top = 192
                    Caption = 'Aplicar Retenciones (Es profesional)'
                    DataBinding.DataField = 'ESRETENCIONES_CLI'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayUnchecked = 'True'
                    Properties.DisplayGrayed = 'False'
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    Style.TransparentBorder = False
                    TabOrder = 4
                    Transparent = True
                  end
                end
              end
            end
            object tsMasDatos: TcxTabSheet
              Caption = '&2_M'#225's datos'
              ImageIndex = 1
              object scrMasDatos: TcxScrollBox
                Left = 0
                Top = 0
                Width = 985
                Height = 412
                Align = alClient
                BorderStyle = cxcbsNone
                TabOrder = 0
                DesignSize = (
                  985
                  412)
                object cxgrpbxDomicilio: TcxGroupBox
                  AlignWithMargins = True
                  Left = 21
                  Top = 0
                  TabStop = True
                  Anchors = [akLeft, akTop]
                  TabOrder = 0
                  Height = 570
                  Width = 460
                  object lblContacto: TcxLabel
                    Left = 94
                    Top = 23
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    Caption = 'Contacto'
                    Properties.Alignment.Horz = taRightJustify
                    TabOrder = 0
                    Transparent = True
                    AnchorX = 163
                  end
                  object txtCONTACTO_CLIENTE: TcxDBTextEdit
                    Left = 170
                    Top = 19
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    DataBinding.DataField = 'CONTACTO_CLI'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 1
                    Width = 199
                  end
                  object lblTelefonoContacto: TcxLabel
                    Left = 450
                    Top = 63
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    Caption = 'Tel'#233'fono Contacto'
                    Properties.Alignment.Horz = taRightJustify
                    TabOrder = 2
                    Transparent = True
                    AnchorX = 163
                  end
                  object txtTELEFONO_CONTACTO_CLIENTE: TcxDBTextEdit
                    Left = 170
                    Top = 59
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    DataBinding.DataField = 'TELEFONO_CONTACTO_CLI'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 3
                    Width = 237
                  end
                  object lblReferencia: TcxLabel
                    Left = 81
                    Top = 103
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    Caption = 'Referencia'
                    Properties.Alignment.Horz = taRightJustify
                    TabOrder = 4
                    Transparent = True
                    AnchorX = 163
                  end
                  object txtREFERENCIA_CLIENTE: TcxDBTextEdit
                    Left = 170
                    Top = 99
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    DataBinding.DataField = 'REFERENCIA_CLI'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 5
                    Width = 263
                  end
                  object lblObservaciones: TcxLabel
                    Left = 52
                    Top = 139
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    Caption = 'Observaciones'
                    Properties.Alignment.Horz = taRightJustify
                    TabOrder = 6
                    Transparent = True
                    AnchorX = 163
                  end
                  object cxdbmOBSERVACIONES_CLIENTE: TcxDBMemo
                    Left = 170
                    Top = 139
                    DataBinding.DataField = 'OBSERVACIONES_CLI'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 7
                    Height = 68
                    Width = 263
                  end
                  object lblFormadePago: TcxLabel
                    Left = 450
                    Top = 223
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    Caption = 'Forma de Pago'
                    Properties.Alignment.Horz = taRightJustify
                    TabOrder = 8
                    Transparent = True
                    AnchorX = 163
                  end
                  object cbbFORMAPAGO: TcxDBLookupComboBox
                    Left = 170
                    Top = 219
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    DataBinding.DataField = 'CODIGO_FP_CLI'
                    DataBinding.DataSource = dsTablaG
                    Properties.KeyFieldNames = 'CODIGO_FP_FP'
                    Properties.ListColumns = <
                      item
                        FieldName = 'DESCRIPCION_FORMA_PAGO_FP'
                      end>
                    Properties.ListOptions.ShowHeader = False
                    Properties.ListSource = dmClientes.dsFormasPago
                    TabOrder = 9
                    Width = 237
                  end
                  object lblBancoCobroCli: TcxLabel
                    Left = 450
                    Top = 263
                    Caption = 'Banco cobro'
                    Properties.Alignment.Horz = taRightJustify
                    TabOrder = 21
                    Transparent = True
                    AnchorX = 163
                  end
                  object cbbBancoCobroCli: TcxDBLookupComboBox
                    Left = 170
                    Top = 259
                    DataBinding.DataField = 'CODIGO_EMPBAN_CLI'
                    DataBinding.DataSource = dsTablaG
                    Properties.KeyFieldNames = 'CODIGO_EMPBAN'
                    Properties.ListColumns = <
                      item
                        Caption = 'Cuenta'
                        MinWidth = 40
                        FieldName = 'NOMBRE_EMPBAN'
                      end
                      item
                        Caption = 'IBAN'
                        MinWidth = 40
                        FieldName = 'IBAN_EMPBAN'
                      end>
                    Properties.ListSource = dmClientes.dsEmpresasBancos
                    TabOrder = 22
                    Width = 237
                  end
                  object lblNroCuenta: TcxLabel
                    Left = 450
                    Top = 303
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    Caption = 'IBAN Bancario'
                    Properties.Alignment.Horz = taRightJustify
                    TabOrder = 10
                    Transparent = True
                    AnchorX = 163
                  end
                  object lblTextoLegalAlt: TcxLabel
                    Left = 34
                    Top = 343
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    Caption = 'Tarifa por defecto'
                    Properties.Alignment.Horz = taRightJustify
                    TabOrder = 11
                    Transparent = True
                    AnchorX = 163
                  end
                  object cbbTARIFA: TcxDBLookupComboBox
                    Left = 170
                    Top = 339
                    DataBinding.DataField = 'TARIFA_ARTICULO_CLI'
                    DataBinding.DataSource = dsTablaG
                    Properties.KeyFieldNames = 'CODIGO_TAR_ARTTAR'
                    Properties.ListColumns = <
                      item
                        Fixed = True
                        FieldName = 'NOMBRE_TAR_TAR'
                      end>
                    Properties.ListOptions.ShowHeader = False
                    TabOrder = 12
                    Width = 263
                  end
                  object txtTARIFA_ARTICULO_CLIENTE: TcxDBTextEdit
                    Left = 308
                    Top = 341
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    DataBinding.DataField = 'TARIFA_ARTICULO_CLI'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 13
                    Visible = False
                    Width = 33
                  end
                  object txtIBAN_CLIENTE: TcxDBMaskEdit
                    Left = 170
                    Top = 299
                    DataBinding.DataField = 'IBAN_CLI'
                    DataBinding.DataSource = dsTablaG
                    Properties.IgnoreMaskBlank = True
                    Properties.EditMask = 'aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa'
                    TabOrder = 14
                    Width = 151
                  end
                  object btnValidar: TcxButton
                    Left = 327
                    Top = 297
                    Width = 80
                    Height = 27
                    Caption = 'Vali&dar'
                    TabOrder = 15
                    OnClick = btnValidarClick
                  end
                  object lblExtra1: TcxLabel
                    Left = 53
                    Top = 383
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    Caption = 'L'#237'mite Deuda'
                    Properties.Alignment.Horz = taRightJustify
                    TabOrder = 16
                    Transparent = True
                    AnchorX = 163
                  end
                  object curTOTAL_LIMITE_CREDITO_CLI: TcxDBCurrencyEdit
                    Left = 170
                    Top = 379
                    DataBinding.DataField = 'TOTAL_LIMITE_CREDITO_CLI'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 17
                    Width = 121
                  end
                  object chkESPERMITE_DEUDA_CLI: TcxDBCheckBox
                    Left = 170
                    Top = 459
                    Caption = 'Permite deuda en Caja'
                    DataBinding.DataField = 'ESPERMITE_DEUDA_CLI'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayChecked = 'S'
                    Properties.DisplayUnchecked = 'N'
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    Style.TransparentBorder = False
                    TabOrder = 18
                    Transparent = True
                  end
                  object curTOTAL_DEUDA_CLI: TcxDBCurrencyEdit
                    Left = 170
                    Top = 419
                    DataBinding.DataField = 'TOTAL_DEUDA_CLI'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 19
                    Width = 121
                  end
                  object chkESVARIOS_CLI: TcxDBCheckBox
                    Left = 170
                    Top = 491
                    Hint = 'Cliente genérico: sus préstamos son apartados sin deuda que se completan con F4'
                    Caption = 'Es cliente de Varios'
                    DataBinding.DataField = 'ESVARIOS_CLI'
                    DataBinding.DataSource = dsTablaG
                    ParentShowHint = False
                    Properties.DisplayChecked = 'S'
                    Properties.DisplayUnchecked = 'N'
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    ShowHint = True
                    Style.TransparentBorder = False
                    TabOrder = 23
                    Transparent = True
                  end
                  object lblVendedorCliente: TcxLabel
                    Left = 101
                    Top = 531
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    Caption = 'Vendedor'
                    Properties.Alignment.Horz = taRightJustify
                    TabOrder = 24
                    Transparent = True
                    AnchorX = 163
                  end
                  
                  object cbbCODIGO_VENDEDOR_CLI: TcxDBLookupComboBox
                    Left = 170
                    Top = 527
                    DataBinding.DataField = 'CODIGO_VENDEDOR_CLI'
                    DataBinding.DataSource = dsTablaG
                    Properties.ClearKey = 46
                    Properties.DropDownListStyle = lsFixedList
                    Properties.KeyFieldNames = 'CODIGO_EMPL'
                    Properties.ListColumns = <
                      item
                        Caption = 'C'#243'digo'
                        Width = 80
                        FieldName = 'CODIGO_EMPL'
                      end
                      item
                        Caption = 'Vendedor'
                        Width = 220
                        FieldName = 'NOMBRE_VENDEDOR'
                      end>
                    Properties.ListFieldIndex = 1
                    TabOrder = 25
                    Width = 263
                  end
                  object lblExtra2: TcxLabel
                    Left = 450
                    Top = 423
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    Caption = 'Deuda Actual'
                    Properties.Alignment.Horz = taRightJustify
                    TabOrder = 20
                    Transparent = True
                    AnchorX = 163
                  end
                end
              end
            end
            object tsParametrosEDoc: TcxTabSheet
              Caption = '&3_Par'#225'metros eDoc'
              ImageIndex = 2
              object cxgrpbxParametrosEDoc: TcxGroupBox
                AlignWithMargins = True
                Left = 21
                Top = 0
                TabStop = True
                Caption = 'Par'#225'metros eDoc'
                TabOrder = 0
                Height = 174
                Width = 890
                object lblCodigoOficinaContable: TcxLabel
                  Left = 39
                  Top = 32
                  Caption = 'Oficina contable'
                  Properties.Alignment.Horz = taRightJustify
                  TabOrder = 0
                  Transparent = True
                  AnchorX = 163
                end
                object txtCODIGO_OFICINA_CONTABLE_CLIENTE: TcxDBTextEdit
                  Left = 170
                  Top = 28
                  DataBinding.DataField = 'CODIGO_OFICINA_CONTABLE_CLI'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 1
                  Width = 160
                end
                object lblCodigoOrganoGestor: TcxLabel
                  Left = 56
                  Top = 72
                  Caption = 'Organo gestor'
                  Properties.Alignment.Horz = taRightJustify
                  TabOrder = 2
                  Transparent = True
                  AnchorX = 163
                end
                object txtCODIGO_ORGANO_GESTOR_CLIENTE: TcxDBTextEdit
                  Left = 170
                  Top = 68
                  DataBinding.DataField = 'CODIGO_ORGANO_GESTOR_CLI'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 3
                  Width = 160
                end
                object lblCodigoUnidadTramitadora: TcxLabel
                  Left = 21
                  Top = 112
                  Caption = 'Unidad tramitadora'
                  Properties.Alignment.Horz = taRightJustify
                  TabOrder = 4
                  Transparent = True
                  AnchorX = 163
                end
                object txtCODIGO_UNIDAD_TRAMITADORA_CLIENTE: TcxDBTextEdit
                  Left = 170
                  Top = 108
                  DataBinding.DataField = 'CODIGO_UNIDAD_TRAMITADORA_CLI'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 5
                  Width = 160
                end
                object lblNombrePersonaCliente: TcxLabel
                  Left = 376
                  Top = 32
                  Caption = 'Nombre persona f'#237'sica'
                  Properties.Alignment.Horz = taRightJustify
                  TabOrder = 6
                  Transparent = True
                  AnchorX = 543
                end
                object txtNOMBRE_PERSONA_CLIENTE: TcxDBTextEdit
                  Left = 550
                  Top = 28
                  DataBinding.DataField = 'NOMBRE_PERSONA_CLIENTE_CLI'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 7
                  Width = 250
                end
                object lblApellidosPersonaCliente: TcxLabel
                  Left = 364
                  Top = 72
                  Caption = 'Apellidos persona f'#237'sica'
                  Properties.Alignment.Horz = taRightJustify
                  TabOrder = 8
                  Transparent = True
                  AnchorX = 543
                end
                object txtAPELLIDOS_PERSONA_CLIENTE: TcxDBTextEdit
                  Left = 550
                  Top = 68
                  DataBinding.DataField = 'APELLIDOS_PERSONA_CLIENTE_CLI'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 9
                  Width = 250
                end
              end
            end
            object tsHistoriaFacturacion: TcxTabSheet
              Caption = '&4_Historia Borradores'
              ImageIndex = 4
              object pnlFacturaCli: TPanel
                Left = 0
                Top = 0
                Width = 985
                Height = 412
                Align = alClient
                BevelOuter = bvNone
                TabOrder = 0
                object cxgrdClientesFacturas: TcxGrid
                  Left = 0
                  Top = 0
                  Width = 868
                  Height = 412
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Align = alClient
                  TabOrder = 0
                  object tvFacturacion: TcxGridDBTableView
                    Navigator.Buttons.ConfirmDelete = True
                    Navigator.Visible = True
                    DataController.DataModeController.SmartRefresh = True
                    DataController.Summary.DefaultGroupSummaryItems = <
                      item
                        Kind = skSum
                        Column = tvFacturacionTOTAL_LIQUIDO_FACTURA
                      end
                      item
                        Kind = skSum
                        Column = tvFacturacionTOTAL_RETENCION_FACTURA
                      end
                      item
                        Kind = skSum
                        Column = tvFacturacionTOTAL_IMPUESTOS_FACTURA
                      end
                      item
                        Kind = skSum
                        Column = tvFacturacionTOTAL_BASES_FACTURA
                      end>
                    DataController.Summary.FooterSummaryItems = <
                      item
                        Format = '##,##.00 '#8364
                        Kind = skSum
                        Column = tvFacturacionTOTAL_LIQUIDO_FACTURA
                      end
                      item
                        Format = '##,##.00 '#8364
                        Kind = skSum
                        Column = tvFacturacionTOTAL_RETENCION_FACTURA
                      end
                      item
                        Format = '##,##.00 '#8364
                        Kind = skSum
                        Column = tvFacturacionTOTAL_IMPUESTOS_FACTURA
                      end
                      item
                        Format = '##,##.00 '#8364
                        Kind = skSum
                        Column = tvFacturacionTOTAL_BASES_FACTURA
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
                    object tvFacturacionFECHA_FACTURA: TcxGridDBColumn
                      Caption = 'Fecha'
                      DataBinding.FieldName = 'FECHA_FAC'
                    end
                    object tvFacturacionNRO_FACTURA: TcxGridDBColumn
                      Caption = 'Nro'
                      DataBinding.FieldName = 'NUMERO_FAC'
                    end
                    object tvFacturacionSERIE_FACTURA: TcxGridDBColumn
                      Caption = 'Serie'
                      DataBinding.FieldName = 'SERIE_FAC'
                    end
                    object tvFacturacionTOTAL_LIQUIDO_FACTURA: TcxGridDBColumn
                      Caption = 'Total a pagar'
                      DataBinding.FieldName = 'TOTAL_LIQUIDO_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 117
                    end
                    object tvFacturacionPORCEN_RETENCION_FACTURA: TcxGridDBColumn
                      Caption = '% IRPF'
                      DataBinding.FieldName = 'PORCENTAJE_RETENCION_FAC'
                    end
                    object tvFacturacionTOTAL_RETENCION_FACTURA: TcxGridDBColumn
                      Caption = 'Total IRPF'
                      DataBinding.FieldName = 'TOTAL_RETENCION_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 99
                    end
                    object tvFacturacionTOTAL_IMPUESTOS_FACTURA: TcxGridDBColumn
                      Caption = 'Total IVA + RE'
                      DataBinding.FieldName = 'TOTAL_IMPUESTOS_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 134
                    end
                    object tvFacturacionTOTAL_BASES_FACTURA: TcxGridDBColumn
                      Caption = 'Bases Imponible'
                      DataBinding.FieldName = 'TOTAL_BASES_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 142
                    end
                    object tvFacturacionFORMA_PAGO_FACTURA: TcxGridDBColumn
                      Caption = 'Forma Pago'
                      DataBinding.FieldName = 'FORMA_PAGO_FAC'
                      Width = 103
                    end
                    object tvFacturacionDESCRIPCION_FORMAPAGO: TcxGridDBColumn
                      Caption = 'Descripci'#243'n Forma Pago'
                      DataBinding.FieldName = 'DESCRIPCION_FORMA_PAGO_FP'
                      Width = 230
                    end
                    object tvFacturacionCODIGO_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'C'#243'digo Empresa'
                      DataBinding.FieldName = 'CODIGO_EMP_FAC'
                      Width = 142
                    end
                    object tvFacturacionRAZONSOCIAL_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'Raz'#243'n Social Empresa'
                      DataBinding.FieldName = 'RAZON_SOCIAL_EMPRESA_FAC'
                      Width = 188
                    end
                    object tvFacturacionNIF_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'Nif Empresa'
                      DataBinding.FieldName = 'NIF_EMPRESA_FAC'
                      Width = 105
                    end
                    object tvFacturacionMOVIL_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'M'#243'vil Empresa'
                      DataBinding.FieldName = 'MOVIL_EMPRESA_FAC'
                      Width = 126
                    end
                    object tvFacturacionEMAIL_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'Email Empresa'
                      DataBinding.FieldName = 'EMAIL_EMPRESA_FAC'
                      Width = 125
                    end
                    object tvFacturacionDIRECCION1_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'Direcci'#243'n1 Empresa'
                      DataBinding.FieldName = 'DIRECCION1_EMPRESA_FAC'
                      Width = 172
                    end
                    object tvFacturacionDIRECCION2_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'Direcci'#243'n2 Empresa'
                      DataBinding.FieldName = 'DIRECCION2_EMPRESA_FAC'
                      Width = 172
                    end
                    object tvFacturacionPOBLACION_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'Poblaci'#243'n Empresa'
                      DataBinding.FieldName = 'POBLACION_EMPRESA_FAC'
                      Width = 175
                    end
                    object tvFacturacionPROVINCIA_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'Provincia Empresa'
                      DataBinding.FieldName = 'PROVINCIA_EMPRESA_FAC'
                      Width = 157
                    end
                    object tvFacturacionPAIS_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'Pa'#237's Empresa'
                      DataBinding.FieldName = 'PAIS_EMPRESA_FACTURA'
                      Width = 114
                    end
                    object tvFacturacionCPOSTAL_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'CPostal Empresa'
                      DataBinding.FieldName = 'CODIGO_POSTAL_EMPRESA_FAC'
                      Width = 156
                    end
                    object tvFacturacionESRETENCIONES_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'Empresa Retiene IRPF'
                      DataBinding.FieldName = 'ESRETENCIONES_EMPRESA_FAC'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Width = 184
                    end
                    object tvFacturacionDESCRIPCION_ZONA_IVA_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'Zona IVA'
                      DataBinding.FieldName = 'DESCRIPCION_ZONA_IVA_EMPRESA_FACTURA'
                      Visible = False
                      Width = 80
                    end
                    object tvFacturacionDESCRIPCION_ZONA_IVA: TcxGridDBColumn
                      Caption = 'Zona IVA'
                      DataBinding.FieldName = 'DESCRIPCION_IVA_IVAGRP'
                      Visible = False
                      Width = 80
                    end
                    object tvFacturacionESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'Es REAGP'
                      DataBinding.FieldName = 'ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Width = 81
                    end
                    object tvFacturacionESIRPF_IMP_INCL_ZONA_IVA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'ESIRPF_IMP_INCL_ZONA_IVA_FAC'
                      Visible = False
                    end
                    object tvFacturacionESAPLICA_RE_ZONA_IVA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'ESAPLICA_RE_ZONA_IVA_FAC'
                      Visible = False
                    end
                    object tvFacturacionESIVAAGRICOLA_ZONA_IVA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'ESIVAAGRICOLA_ZONA_IVA_FAC'
                      Visible = False
                    end
                    object tvFacturacionPALABRA_REPORTS_ZONA_IVA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'PALABRA_REPORTS_ZONA_IVA_FAC'
                      Visible = False
                    end
                    object tvFacturacionESVENTA_ACTIVO_FIJO_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'ESVENTA_ACTIVO_FIJO_FAC'
                      Visible = False
                    end
                    object tvFacturacionPORCEN_IVAN_FACTURA: TcxGridDBColumn
                      Caption = '% IVA Normal'
                      DataBinding.FieldName = 'PORCENTAJE_IVAN_FAC'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                      Properties.ValueType = vtFloat
                      Width = 115
                    end
                    object tvFacturacionTOTAL_IVAN_FACTURA: TcxGridDBColumn
                      Caption = 'Total IVA Normal'
                      DataBinding.FieldName = 'TOTAL_IVAN_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 159
                    end
                    object tvFacturacionPORCEN_REN_FACTURA: TcxGridDBColumn
                      Caption = '% RE Normal'
                      DataBinding.FieldName = 'PORCENTAJE_REN_FAC'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                      Properties.ValueType = vtFloat
                      Width = 107
                    end
                    object tvFacturacionTOTAL_REN_FACTURA: TcxGridDBColumn
                      Caption = 'Total RE Normal'
                      DataBinding.FieldName = 'TOTAL_REN_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 139
                    end
                    object tvFacturacionTOTAL_BASEI_IVAN_FACTURA: TcxGridDBColumn
                      Caption = 'Base Imponible IVA Normal'
                      DataBinding.FieldName = 'TOTAL_BASEI_IVAN_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 232
                    end
                    object tvFacturacionPORCEN_IVAR_FACTURA: TcxGridDBColumn
                      Caption = '% IVA Reducido'
                      DataBinding.FieldName = 'PORCENTAJE_IVAR_FAC'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                      Properties.ValueType = vtFloat
                      Width = 133
                    end
                    object tvFacturacionTOTAL_IVAR_FACTURA: TcxGridDBColumn
                      Caption = 'IVA Reducido'
                      DataBinding.FieldName = 'TOTAL_IVAR_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 129
                    end
                    object tvFacturacionPORCEN_RER_FACTURA: TcxGridDBColumn
                      Caption = '% RE Reducido'
                      DataBinding.FieldName = 'PORCENTAJE_RER_FAC'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                      Properties.ValueType = vtFloat
                      Width = 137
                    end
                    object tvFacturacionTOTAL_RER_FACTURA: TcxGridDBColumn
                      Caption = 'RE Reducido'
                      DataBinding.FieldName = 'TOTAL_RER_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 109
                    end
                    object tvFacturacionTOTAL_BASEI_IVAR_FACTURA: TcxGridDBColumn
                      Caption = 'Base Imponible IVA Reducido'
                      DataBinding.FieldName = 'TOTAL_BASEI_IVAR_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 310
                    end
                    object tvFacturacionPORCEN_IVAS_FACTURA: TcxGridDBColumn
                      Caption = '% IVA S'#250'per Reducido'
                      DataBinding.FieldName = 'PORCENTAJE_IVAS_FAC'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                      Properties.ValueType = vtFloat
                      Width = 186
                    end
                    object tvFacturacionTOTAL_IVAS_FACTURA: TcxGridDBColumn
                      Caption = 'IVA S'#250'per Reducido'
                      DataBinding.FieldName = 'TOTAL_IVAS_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 170
                    end
                    object tvFacturacionPORCEN_RES_FACTURA: TcxGridDBColumn
                      Caption = '% RE S'#250'per Reducido'
                      DataBinding.FieldName = 'PORCENTAJE_RES_FAC'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                      Properties.ValueType = vtFloat
                      Width = 178
                    end
                    object tvFacturacionTOTAL_RES_FACTURA: TcxGridDBColumn
                      Caption = 'RE S'#250'per Reducido'
                      DataBinding.FieldName = 'TOTAL_RES_FAC'
                      Width = 162
                    end
                    object tvFacturacionTOTAL_BASEI_IVAS_FACTURA: TcxGridDBColumn
                      Caption = 'Base Imponible IVA S'#250'per Reducido'
                      DataBinding.FieldName = 'TOTAL_BASEI_IVAS_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 298
                    end
                    object tvFacturacionPORCEN_IVAE_FACTURA: TcxGridDBColumn
                      Caption = '% IVA Exento'
                      DataBinding.FieldName = 'PORCENTAJE_IVAE_FAC'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                      Properties.ValueType = vtFloat
                      Width = 112
                    end
                    object tvFacturacionTOTAL_IVAE_FACTURA: TcxGridDBColumn
                      Caption = 'IVA Exento'
                      DataBinding.FieldName = 'TOTAL_IVAE_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                    end
                    object tvFacturacionPORCEN_REE_FACTURA: TcxGridDBColumn
                      Caption = '% RE Exento'
                      DataBinding.FieldName = 'PORCENTAJE_REE_FAC'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                      Properties.ValueType = vtFloat
                      Width = 107
                    end
                    object tvFacturacionTOTAL_REE_FACTURA: TcxGridDBColumn
                      Caption = 'RE Exento'
                      DataBinding.FieldName = 'TOTAL_REE_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 100
                    end
                    object tvFacturacionTOTAL_BASEI_IVAE_FACTURA: TcxGridDBColumn
                      Caption = 'Base Imponible Exento'
                      DataBinding.FieldName = 'TOTAL_BASEI_IVAE_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 208
                    end
                    object tvFacturacionCODIGO_CLIENTE_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'CODIGO_CLI_FAC'
                      Visible = False
                    end
                    object tvFacturacionRAZONSOCIAL_CLIENTE_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'RAZON_SOCIAL_CLIENTE_FAC'
                      Visible = False
                    end
                    object tvFacturacionNIF_CLIENTE_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'NIF_CLIENTE_FAC'
                      Visible = False
                    end
                    object tvFacturacionMOVIL_CLIENTE_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'MOVIL_CLIENTE_FAC'
                      Visible = False
                    end
                    object tvFacturacionEMAIL_CLIENTE_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'EMAIL_CLIENTE_FAC'
                      Visible = False
                    end
                    object tvFacturacionDIRECCION1_CLIENTE_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'DIRECCION1_CLIENTE_FAC'
                      Visible = False
                    end
                    object tvFacturacionDIRECCION2_CLIENTE_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'DIRECCION2_CLIENTE_FAC'
                      Visible = False
                    end
                    object tvFacturacionPOBLACION_CLIENTE_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'POBLACION_CLIENTE_FAC'
                      Visible = False
                    end
                    object tvFacturacionPROVINCIA_CLIENTE_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'PROVINCIA_CLIENTE_FAC'
                      Visible = False
                    end
                    object tvFacturacionCPOSTAL_CLIENTE_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'CODIGO_POSTAL_CLIENTE_FAC'
                      Visible = False
                    end
                    object tvFacturacionPAIS_CLIENTE_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'PAIS_CLIENTE_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionESIVA_RECARGO_CLIENTE_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'ESIVA_RECARGO_CLIENTE_FAC'
                      Visible = False
                    end
                    object tvFacturacionESIVA_EXENTO_CLIENTE_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'ESIVA_EXENTO_CLIENTE_FAC'
                      Visible = False
                    end
                    object tvFacturacionESREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC'
                      Visible = False
                    end
                    object tvFacturacionESRETENCIONES_CLIENTE_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'ESRETENCIONES_CLIENTE_FAC'
                      Visible = False
                    end
                    object tvFacturacionNOMBRE_TARIFA_CLIENTE: TcxGridDBColumn
                      DataBinding.FieldName = 'NOMBRE_TARIFA_CLIENTE'
                      Visible = False
                    end
                    object tvFacturacionESIMP_INCL_TARIFA_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Precios incl. Impuestos'
                      DataBinding.FieldName = 'ESIMP_INCL_TARIFA_CLIENTE_FAC'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Width = 198
                    end
                    object tvFacturacionESINTRACOMUNITARIO_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Venta Intracomunitaria'
                      DataBinding.FieldName = 'ESINTRACOMUNITARIO_CLIENTE_FAC'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Width = 212
                    end
                    object tvFacturacionGRUPO_ZONA_IVA_EMPRESA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'GRUPO_ZONA_IVA_EMPRESA_FAC'
                      Visible = False
                    end
                    object tvFacturacionTARIFA_ARTICULO_CLIENTE_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'TARIFA_ARTICULO_CLIENTE_FAC'
                      Visible = False
                    end
                    object tvFacturacionCODIGO_IVA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'CODIGO_IVA_FAC'
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
                      Caption = 'C'#243'digo Linea'
                      DataBinding.FieldName = 'LINEA_FACLIN'
                      Width = 28
                    end
                    object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CODIGO_ARTICULO_LINEA: TcxGridDBColumn
                      Caption = 'C'#243'digo Art'#237'culo'
                      DataBinding.FieldName = 'CODIGO_ART_FACLIN'
                      Width = 164
                    end
                    object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1DESCRIPCION_ARTICULO_LINEA: TcxGridDBColumn
                      Caption = 'Descripci'#243'n Art'#237'culo'
                      DataBinding.FieldName = 'DESCRIPCION_ARTICULO_FACLIN'
                      Width = 162
                    end
                    object tvLineasFacturacionTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                      Caption = 'Tipo Ctd'
                      DataBinding.FieldName = 'TIPO_CANTIDAD_ARTICULO_FACLIN'
                    end
                    object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CANTIDAD_LINEA: TcxGridDBColumn
                      Caption = 'Cantidad'
                      DataBinding.FieldName = 'CANTIDAD_FACLIN'
                      Width = 84
                    end
                    object tvLineasFacturacionPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                      Caption = 'Precio Sin IVA'
                      DataBinding.FieldName = 'PRECIO_VENTA_SIVA_ARTICULO_FACLIN'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                    end
                    object dbcLineasFacturacionNOMBRE_TIPO_IVA: TcxGridDBColumn
                      Caption = 'Tipo IVA'
                      DataBinding.FieldName = 'NOMBRE_TIPO_IVA_IVATIP'
                    end
                    object tvLineasFacturacionPORCEN_IVA_FACTURA_LINEA: TcxGridDBColumn
                      Caption = 'Porcentaje IVA'
                      DataBinding.FieldName = 'PORCENTAJE_IVA_FACLIN'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.EditFormat = '0.00 %'
                    end
                    object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1PRECIOVENTA_ARTICULO_LINEA: TcxGridDBColumn
                      Caption = 'Precio Con IVA'
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
                    object tvLineasFacturacionFECHA_ENTREGA_FACTURA_LINEA: TcxGridDBColumn
                      Caption = 'Fecha de Entrega'
                      DataBinding.FieldName = 'FECHA_ENTREGA_FACLIN'
                      PropertiesClassName = 'TcxDateEditProperties'
                    end
                  end
                  object cxgrdlvlClientesFacturasMaster: TcxGridLevel
                    GridView = tvFacturacion
                    object cxgrdlvlClientesFacturasDetail: TcxGridLevel
                      GridView = tvLineasFacturacion
                    end
                  end
                end
                object pnlFacturaOpts: TPanel
                  Left = 868
                  Top = 0
                  Width = 117
                  Height = 412
                  Align = alRight
                  BevelOuter = bvNone
                  TabOrder = 1
                  object btnIraFactura: TcxButton
                    Left = 6
                    Top = 16
                    Width = 107
                    Height = 34
                    Caption = '&Ir a Borrador'
                    TabOrder = 0
                    OnClick = btnIraFacturaClick
                  end
                  object btnIraEmpresa: TcxButton
                    Left = 7
                    Top = 56
                    Width = 106
                    Height = 34
                    Caption = '&Ir a Empresa'
                    TabOrder = 1
                    OnClick = btnIraEmpresaClick
                  end
                  object btnExportar: TcxButton
                    Left = 6
                    Top = 137
                    Width = 107
                    Height = 34
                    Caption = '&Exp Excel'
                    TabOrder = 3
                    OnClick = btnExportarClick
                  end
                  object btnIraArticulo: TcxButton
                    Left = 7
                    Top = 96
                    Width = 105
                    Height = 34
                    Caption = 'I&r a Art'#237'culo'
                    TabOrder = 2
                    OnClick = btnIraArticuloClick
                  end
                end
              end
            end
            object tsPresupuestos: TcxTabSheet
              Caption = 'Historia Presupuestos'
              ImageIndex = 4
              TabVisible = False
              object cxgrdPresupuestos: TcxGrid
                Left = 0
                Top = 0
                Width = 985
                Height = 412
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Align = alClient
                TabOrder = 0
                object tvPresupuestos: TcxGridDBTableView
                  Navigator.Buttons.ConfirmDelete = True
                  Navigator.Visible = True
                  DataController.DataModeController.SmartRefresh = True
                  OptionsBehavior.GoToNextCellOnEnter = True
                  OptionsCustomize.ColumnGrouping = False
                  OptionsData.Deleting = False
                  OptionsData.Editing = False
                  OptionsData.Inserting = False
                  OptionsSelection.InvertSelect = False
                  OptionsView.NoDataToDisplayInfoText = '<No hay datos a mostrar>'
                  OptionsView.GroupByBox = False
                  object tvPresupuestosFECHA_FAC: TcxGridDBColumn
                    AlternateCaption = 'Fecha Presupuesto'
                    Caption = 'Fecha Presupuesto'
                    DataBinding.FieldName = 'FECHA_FAC'
                    PropertiesClassName = 'TcxDateEditProperties'
                    Width = 102
                  end
                  object tvPresupuestosNUMERO_FAC: TcxGridDBColumn
                    AlternateCaption = 'Nro Presupuesto'
                    Caption = 'Nro Presupuesto'
                    DataBinding.FieldName = 'NUMERO_FAC'
                    Width = 101
                  end
                  object tvPresupuestosSERIE_FAC: TcxGridDBColumn
                    Caption = 'Serie'
                    DataBinding.FieldName = 'SERIE_FAC'
                  end
                  object tvPresupuestosCODIGO_CLI_FAC: TcxGridDBColumn
                    Caption = 'C'#243'digo Paciente'
                    DataBinding.FieldName = 'CODIGO_CLI_FAC'
                    Width = 104
                  end
                  object tvPresupuestosRAZON_SOCIAL_CLIENTE_FAC: TcxGridDBColumn
                    Caption = 'Raz'#243'n Social'
                    DataBinding.FieldName = 'RAZON_SOCIAL_CLIENTE_FAC'
                    Width = 203
                  end
                  object tvPresupuestosNIF_CLIENTE_FAC: TcxGridDBColumn
                    Caption = 'Nif'
                    DataBinding.FieldName = 'NIF_CLIENTE_FAC'
                    Width = 144
                  end
                  object tvPresupuestosMOVIL_CLIENTE_FAC: TcxGridDBColumn
                    Caption = 'Tel'#233'fono1'
                    DataBinding.FieldName = 'MOVIL_CLIENTE_FAC'
                    Width = 164
                  end
                  object tvPresupuestosEMAIL_CLIENTE_FAC: TcxGridDBColumn
                    Caption = 'Email'
                    DataBinding.FieldName = 'EMAIL_CLIENTE_FAC'
                    Width = 179
                  end
                  object tvPresupuestosDIRECCION1_CLIENTE_FAC: TcxGridDBColumn
                    Caption = 'Direcci'#243'n1'
                    DataBinding.FieldName = 'DIRECCION1_CLIENTE_FAC'
                    Width = 204
                  end
                  object tvPresupuestosDIRECCION2_CLIENTE_FAC: TcxGridDBColumn
                    Caption = 'Direcci'#243'n2'
                    DataBinding.FieldName = 'DIRECCION2_CLIENTE_FAC'
                    Width = 190
                  end
                  object tvPresupuestosPOBLACION_CLIENTE_FAC: TcxGridDBColumn
                    Caption = 'Poblaci'#243'n'
                    DataBinding.FieldName = 'POBLACION_CLIENTE_FAC'
                    Width = 185
                  end
                  object tvPresupuestosPROVINCIA_CLIENTE_FAC: TcxGridDBColumn
                    Caption = 'Provincia'
                    DataBinding.FieldName = 'PROVINCIA_CLIENTE_FAC'
                    Width = 183
                  end
                  object tvPresupuestosCODIGO_POSTAL_CLIENTE_FAC: TcxGridDBColumn
                    Caption = 'C'#243'digo Postal'
                    DataBinding.FieldName = 'CODIGO_POSTAL_CLIENTE_FAC'
                  end
                  object tvPresupuestosPAIS_CLIENTE_FACTURA: TcxGridDBColumn
                    Caption = 'Pa'#237's'
                    DataBinding.FieldName = 'PAIS_CLIENTE_FACTURA'
                    Width = 144
                  end
                  object tvPresupuestosTOTAL_LIQUIDO_FAC: TcxGridDBColumn
                    Caption = 'Total L'#237'quido'
                    DataBinding.FieldName = 'TOTAL_LIQUIDO_FAC'
                  end
                  object tvPresupuestosFORMA_PAGO_FAC: TcxGridDBColumn
                    Caption = 'Forma de Pago'
                    DataBinding.FieldName = 'FORMA_PAGO_FAC'
                    Width = 151
                  end
                  object tvPresupuestosCOMENTARIOS_FAC: TcxGridDBColumn
                    Caption = 'Comentarios'
                    DataBinding.FieldName = 'COMENTARIOS_FAC'
                  end
                end
                object tvLineasPresupuesto: TcxGridDBTableView
                  DataController.DetailKeyFieldNames = 'NUMERO_FAC_FACLIN; SERIE_FAC_FACLIN'
                  DataController.KeyFieldNames = 'LINEA_LINEA'
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
                  object tvLineasPresupuestoLINEA_LINEA: TcxGridDBColumn
                    DataBinding.FieldName = 'LINEA_LINEA'
                    Width = 28
                  end
                  object tvLineasPresupuestoCODIGO_ARTICULO_LINEA: TcxGridDBColumn
                    Caption = 'C'#243'digo Tratamiento'
                    DataBinding.FieldName = 'CODIGO_ARTICULO_LINEA'
                    Width = 164
                  end
                  object tvLineasPresupuestoDESCRIPCION_ARTICULO_LINEA: TcxGridDBColumn
                    Caption = 'Descripci'#243'n Tratamiento'
                    DataBinding.FieldName = 'DESCRIPCION_ARTICULO_LINEA'
                    Width = 804
                  end
                  object tvLineasPresupuestoZONA: TcxGridDBColumn
                    Caption = 'Nro Pieza'
                    DataBinding.FieldName = 'ZONA'
                    Width = 484
                  end
                  object tvLineasPresupuestoPRECIOVENTA_ARTICULO_LINEA: TcxGridDBColumn
                    Caption = 'Precio'
                    DataBinding.FieldName = 'PRECIOVENTA_ARTICULO_LINEA'
                    Width = 84
                  end
                  object tvLineasPresupuestoCANTIDAD_LINEA: TcxGridDBColumn
                    Caption = 'Cantidad'
                    DataBinding.FieldName = 'CANTIDAD_LINEA'
                    Width = 84
                  end
                  object tvLineasPresupuestoSUM_TOTAL_LINEA: TcxGridDBColumn
                    Caption = 'Total'
                    DataBinding.FieldName = 'SUM_TOTAL_LINEA'
                    Width = 84
                  end
                  object tvLineasPresupuestoODONTOLOGO: TcxGridDBColumn
                    Caption = 'Nro Odont'#243'logo'
                    DataBinding.FieldName = 'ODONTOLOGO'
                    Width = 68
                  end
                end
                object cxgrdlvlPresupuestos: TcxGridLevel
                  GridView = tvPresupuestos
                  object cxgrdlvlLineasPresupuesto: TcxGridLevel
                    GridView = tvLineasPresupuesto
                  end
                end
              end
            end
            object tsPrestamos: TcxTabSheet
              Caption = '&5_Pr'#233'stamos Caja'
              ImageIndex = 4
              object pnlPrestamosBody: TPanel
                Left = 0
                Top = 0
                Width = 985
                Height = 412
                Align = alClient
                BevelOuter = bvNone
                TabOrder = 0
                object cxgrdPrestamosCliente: TcxGrid
                  Left = 0
                  Top = 0
                  Width = 868
                  Height = 412
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Align = alClient
                  TabOrder = 0
                  object tvFacturasCliente: TcxGridDBTableView
                    Navigator.Buttons.ConfirmDelete = True
                    Navigator.Visible = True
                    DataController.DataModeController.SmartRefresh = True
                    DataController.Summary.DefaultGroupSummaryItems = <
                      item
                        Kind = skSum
                        Column = tvFacturasClienteTOTAL_LIQUIDO_FAC
                      end
                      item
                        Kind = skSum
                        Column = tvFacturasClienteTOTAL_RETENCION_FAC
                      end
                      item
                        Kind = skSum
                        Column = tvFacturasClienteTOTAL_IMPUESTOS_FAC
                      end
                      item
                        Kind = skSum
                        Column = tvFacturasClienteTOTAL_BASES_FAC
                      end>
                    DataController.Summary.FooterSummaryItems = <
                      item
                        Format = '##,##.00 '#8364
                        Kind = skSum
                        Column = tvFacturasClienteTOTAL_LIQUIDO_FAC
                      end
                      item
                        Format = '##,##.00 '#8364
                        Kind = skSum
                        Column = tvFacturasClienteTOTAL_RETENCION_FAC
                      end
                      item
                        Format = '##,##.00 '#8364
                        Kind = skSum
                        Column = tvFacturasClienteTOTAL_IMPUESTOS_FAC
                      end
                      item
                        Format = '##,##.00 '#8364
                        Kind = skSum
                        Column = tvFacturasClienteTOTAL_BASES_FAC
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
                    object tvFacturasClienteFECHA_FAC: TcxGridDBColumn
                      Caption = 'Fecha'
                      DataBinding.FieldName = 'FECHA_FAC'
                    end
                    object tvFacturasClienteNUMERO_FAC: TcxGridDBColumn
                      Caption = 'Nro'
                      DataBinding.FieldName = 'NUMERO_FAC'
                    end
                    object tvFacturasClienteSERIE_FAC: TcxGridDBColumn
                      Caption = 'Serie'
                      DataBinding.FieldName = 'SERIE_FAC'
                    end
                    object tvFacturasClienteTOTAL_LIQUIDO_FAC: TcxGridDBColumn
                      Caption = 'Total a pagar'
                      DataBinding.FieldName = 'TOTAL_LIQUIDO_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 117
                    end
                    object tvFacturasClientePORCENTAJE_RETENCION_FAC: TcxGridDBColumn
                      Caption = '% IRPF'
                      DataBinding.FieldName = 'PORCENTAJE_RETENCION_FAC'
                    end
                    object tvFacturasClienteTOTAL_RETENCION_FAC: TcxGridDBColumn
                      Caption = 'Total IRPF'
                      DataBinding.FieldName = 'TOTAL_RETENCION_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 99
                    end
                    object tvFacturasClienteTOTAL_IMPUESTOS_FAC: TcxGridDBColumn
                      Caption = 'Total IVA + RE'
                      DataBinding.FieldName = 'TOTAL_IMPUESTOS_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 134
                    end
                    object tvFacturasClienteTOTAL_BASES_FAC: TcxGridDBColumn
                      Caption = 'Bases Imponible'
                      DataBinding.FieldName = 'TOTAL_BASES_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 142
                    end
                    object tvFacturasClienteFORMA_PAGO_FAC: TcxGridDBColumn
                      Caption = 'Forma Pago'
                      DataBinding.FieldName = 'FORMA_PAGO_FAC'
                      Width = 103
                    end
                    object tvFacturasClienteDESCRIPCION_FORMA_PAGO_FP: TcxGridDBColumn
                      Caption = 'Descripci'#243'n Forma Pago'
                      DataBinding.FieldName = 'DESCRIPCION_FORMA_PAGO_FP'
                      Width = 230
                    end
                    object tvFacturasClienteCODIGO_EMP_FAC: TcxGridDBColumn
                      Caption = 'C'#243'digo Empresa'
                      DataBinding.FieldName = 'CODIGO_EMP_FAC'
                      Width = 142
                    end
                    object tvFacturasClienteRAZON_SOCIAL_EMPRESA_FAC: TcxGridDBColumn
                      Caption = 'Raz'#243'n Social Empresa'
                      DataBinding.FieldName = 'RAZON_SOCIAL_EMPRESA_FAC'
                      Width = 188
                    end
                    object tvFacturasClienteNIF_EMPRESA_FAC: TcxGridDBColumn
                      Caption = 'Nif Empresa'
                      DataBinding.FieldName = 'NIF_EMPRESA_FAC'
                      Width = 105
                    end
                    object tvFacturasClienteMOVIL_EMPRESA_FAC: TcxGridDBColumn
                      Caption = 'M'#243'vil Empresa'
                      DataBinding.FieldName = 'MOVIL_EMPRESA_FAC'
                      Width = 126
                    end
                    object tvFacturasClienteEMAIL_EMPRESA_FAC: TcxGridDBColumn
                      Caption = 'Email Empresa'
                      DataBinding.FieldName = 'EMAIL_EMPRESA_FAC'
                      Width = 125
                    end
                    object tvFacturasClienteDIRECCION1_EMPRESA_FAC: TcxGridDBColumn
                      Caption = 'Direcci'#243'n1 Empresa'
                      DataBinding.FieldName = 'DIRECCION1_EMPRESA_FAC'
                      Width = 172
                    end
                    object tvFacturasClienteDIRECCION2_EMPRESA_FAC: TcxGridDBColumn
                      Caption = 'Direcci'#243'n2 Empresa'
                      DataBinding.FieldName = 'DIRECCION2_EMPRESA_FAC'
                      Width = 172
                    end
                    object tvFacturasClientePOBLACION_EMPRESA_FAC: TcxGridDBColumn
                      Caption = 'Poblaci'#243'n Empresa'
                      DataBinding.FieldName = 'POBLACION_EMPRESA_FAC'
                      Width = 175
                    end
                    object tvFacturasClientePROVINCIA_EMPRESA_FAC: TcxGridDBColumn
                      Caption = 'Provincia Empresa'
                      DataBinding.FieldName = 'PROVINCIA_EMPRESA_FAC'
                      Width = 157
                    end
                    object tvFacturasClientePAIS_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'Pa'#237's Empresa'
                      DataBinding.FieldName = 'PAIS_EMPRESA_FACTURA'
                      Width = 114
                    end
                    object tvFacturasClienteCODIGO_POSTAL_EMPRESA_FAC: TcxGridDBColumn
                      Caption = 'CPostal Empresa'
                      DataBinding.FieldName = 'CODIGO_POSTAL_EMPRESA_FAC'
                      Width = 156
                    end
                    object tvFacturasClienteESRETENCIONES_EMPRESA_FAC: TcxGridDBColumn
                      Caption = 'Empresa Retiene IRPF'
                      DataBinding.FieldName = 'ESRETENCIONES_EMPRESA_FAC'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Width = 184
                    end
                    object tvFacturasClienteDESCRIPCION_ZONA_IVA_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'Zona IVA'
                      DataBinding.FieldName = 'DESCRIPCION_ZONA_IVA_EMPRESA_FACTURA'
                      Visible = False
                      Width = 80
                    end
                    object tvFacturasClienteDESCRIPCION_IVA_IVAGRP: TcxGridDBColumn
                      Caption = 'Zona IVA'
                      DataBinding.FieldName = 'DESCRIPCION_IVA_IVAGRP'
                      Visible = False
                      Width = 80
                    end
                    object tvFacturasClienteESREGIMENESPECIALAGRICOLA_EMPRESA_FAC: TcxGridDBColumn
                      Caption = 'Es REAGP'
                      DataBinding.FieldName = 'ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Width = 81
                    end
                    object tvFacturasClienteESIRPF_IMP_INCL_ZONA_IVA_FAC: TcxGridDBColumn
                      DataBinding.FieldName = 'ESIRPF_IMP_INCL_ZONA_IVA_FAC'
                      Visible = False
                    end
                    object tvFacturasClienteESAPLICA_RE_ZONA_IVA_FAC: TcxGridDBColumn
                      DataBinding.FieldName = 'ESAPLICA_RE_ZONA_IVA_FAC'
                      Visible = False
                    end
                    object tvFacturasClienteESIVAAGRICOLA_ZONA_IVA_FAC: TcxGridDBColumn
                      DataBinding.FieldName = 'ESIVAAGRICOLA_ZONA_IVA_FAC'
                      Visible = False
                    end
                    object tvFacturasClientePALABRA_REPORTS_ZONA_IVA_FAC: TcxGridDBColumn
                      DataBinding.FieldName = 'PALABRA_REPORTS_ZONA_IVA_FAC'
                      Visible = False
                    end
                    object tvFacturasClienteESVENTA_ACTIVO_FIJO_FAC: TcxGridDBColumn
                      DataBinding.FieldName = 'ESVENTA_ACTIVO_FIJO_FAC'
                      Visible = False
                    end
                    object tvFacturasClientePORCENTAJE_IVAN_FAC: TcxGridDBColumn
                      Caption = '% IVA Normal'
                      DataBinding.FieldName = 'PORCENTAJE_IVAN_FAC'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                      Properties.ValueType = vtFloat
                      Width = 115
                    end
                    object tvFacturasClienteTOTAL_IVAN_FAC: TcxGridDBColumn
                      Caption = 'Total IVA Normal'
                      DataBinding.FieldName = 'TOTAL_IVAN_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 159
                    end
                    object tvFacturasClientePORCENTAJE_REN_FAC: TcxGridDBColumn
                      Caption = '% RE Normal'
                      DataBinding.FieldName = 'PORCENTAJE_REN_FAC'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                      Properties.ValueType = vtFloat
                      Width = 107
                    end
                    object tvFacturasClienteTOTAL_REN_FAC: TcxGridDBColumn
                      Caption = 'Total RE Normal'
                      DataBinding.FieldName = 'TOTAL_REN_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 139
                    end
                    object tvFacturasClienteTOTAL_BASEI_IVAN_FAC: TcxGridDBColumn
                      Caption = 'Base Imponible IVA Normal'
                      DataBinding.FieldName = 'TOTAL_BASEI_IVAN_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 232
                    end
                    object tvFacturasClientePORCENTAJE_IVAR_FAC: TcxGridDBColumn
                      Caption = '% IVA Reducido'
                      DataBinding.FieldName = 'PORCENTAJE_IVAR_FAC'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                      Properties.ValueType = vtFloat
                      Width = 133
                    end
                    object tvFacturasClienteTOTAL_IVAR_FAC: TcxGridDBColumn
                      Caption = 'IVA Reducido'
                      DataBinding.FieldName = 'TOTAL_IVAR_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 129
                    end
                    object tvFacturasClientePORCENTAJE_RER_FAC: TcxGridDBColumn
                      Caption = '% RE Reducido'
                      DataBinding.FieldName = 'PORCENTAJE_RER_FAC'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                      Properties.ValueType = vtFloat
                      Width = 137
                    end
                    object tvFacturasClienteTOTAL_RER_FAC: TcxGridDBColumn
                      Caption = 'RE Reducido'
                      DataBinding.FieldName = 'TOTAL_RER_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 109
                    end
                    object tvFacturasClienteTOTAL_BASEI_IVAR_FAC: TcxGridDBColumn
                      Caption = 'Base Imponible IVA Reducido'
                      DataBinding.FieldName = 'TOTAL_BASEI_IVAR_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 310
                    end
                    object tvFacturasClientePORCENTAJE_IVAS_FAC: TcxGridDBColumn
                      Caption = '% IVA S'#250'per Reducido'
                      DataBinding.FieldName = 'PORCENTAJE_IVAS_FAC'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                      Properties.ValueType = vtFloat
                      Width = 186
                    end
                    object tvFacturasClienteTOTAL_IVAS_FAC: TcxGridDBColumn
                      Caption = 'IVA S'#250'per Reducido'
                      DataBinding.FieldName = 'TOTAL_IVAS_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 170
                    end
                    object tvFacturasClientePORCENTAJE_RES_FAC: TcxGridDBColumn
                      Caption = '% RE S'#250'per Reducido'
                      DataBinding.FieldName = 'PORCENTAJE_RES_FAC'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                      Properties.ValueType = vtFloat
                      Width = 178
                    end
                    object tvFacturasClienteTOTAL_RES_FAC: TcxGridDBColumn
                      Caption = 'RE S'#250'per Reducido'
                      DataBinding.FieldName = 'TOTAL_RES_FAC'
                      Width = 162
                    end
                    object tvFacturasClienteTOTAL_BASEI_IVAS_FAC: TcxGridDBColumn
                      Caption = 'Base Imponible IVA S'#250'per Reducido'
                      DataBinding.FieldName = 'TOTAL_BASEI_IVAS_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 298
                    end
                    object tvFacturasClientePORCENTAJE_IVAE_FAC: TcxGridDBColumn
                      Caption = '% IVA Exento'
                      DataBinding.FieldName = 'PORCENTAJE_IVAE_FAC'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                      Properties.ValueType = vtFloat
                      Width = 112
                    end
                    object tvFacturasClienteTOTAL_IVAE_FAC: TcxGridDBColumn
                      Caption = 'IVA Exento'
                      DataBinding.FieldName = 'TOTAL_IVAE_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                    end
                    object tvFacturasClientePORCENTAJE_REE_FAC: TcxGridDBColumn
                      Caption = '% RE Exento'
                      DataBinding.FieldName = 'PORCENTAJE_REE_FAC'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                      Properties.ValueType = vtFloat
                      Width = 107
                    end
                    object tvFacturasClienteTOTAL_REE_FAC: TcxGridDBColumn
                      Caption = 'RE Exento'
                      DataBinding.FieldName = 'TOTAL_REE_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 100
                    end
                    object tvFacturasClienteTOTAL_BASEI_IVAE_FAC: TcxGridDBColumn
                      Caption = 'Base Imponible Exento'
                      DataBinding.FieldName = 'TOTAL_BASEI_IVAE_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 208
                    end
                    object tvFacturasClienteCODIGO_CLI_FAC: TcxGridDBColumn
                      DataBinding.FieldName = 'CODIGO_CLI_FAC'
                      Visible = False
                    end
                    object tvFacturasClienteRAZON_SOCIAL_CLIENTE_FAC: TcxGridDBColumn
                      DataBinding.FieldName = 'RAZON_SOCIAL_CLIENTE_FAC'
                      Visible = False
                    end
                    object tvFacturasClienteNIF_CLIENTE_FAC: TcxGridDBColumn
                      DataBinding.FieldName = 'NIF_CLIENTE_FAC'
                      Visible = False
                    end
                    object tvFacturasClienteMOVIL_CLIENTE_FAC: TcxGridDBColumn
                      DataBinding.FieldName = 'MOVIL_CLIENTE_FAC'
                      Visible = False
                    end
                    object tvFacturasClienteEMAIL_CLIENTE_FAC: TcxGridDBColumn
                      DataBinding.FieldName = 'EMAIL_CLIENTE_FAC'
                      Visible = False
                    end
                    object tvFacturasClienteDIRECCION1_CLIENTE_FAC: TcxGridDBColumn
                      DataBinding.FieldName = 'DIRECCION1_CLIENTE_FAC'
                      Visible = False
                    end
                    object tvFacturasClienteDIRECCION2_CLIENTE_FAC: TcxGridDBColumn
                      DataBinding.FieldName = 'DIRECCION2_CLIENTE_FAC'
                      Visible = False
                    end
                    object tvFacturasClientePOBLACION_CLIENTE_FAC: TcxGridDBColumn
                      DataBinding.FieldName = 'POBLACION_CLIENTE_FAC'
                      Visible = False
                    end
                    object tvFacturasClientePROVINCIA_CLIENTE_FAC: TcxGridDBColumn
                      DataBinding.FieldName = 'PROVINCIA_CLIENTE_FAC'
                      Visible = False
                    end
                    object tvFacturasClienteCODIGO_POSTAL_CLIENTE_FAC: TcxGridDBColumn
                      DataBinding.FieldName = 'CODIGO_POSTAL_CLIENTE_FAC'
                      Visible = False
                    end
                    object tvFacturasClientePAIS_CLIENTE_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'PAIS_CLIENTE_FACTURA'
                      Visible = False
                    end
                    object tvFacturasClienteESIVA_RECARGO_CLIENTE_FAC: TcxGridDBColumn
                      DataBinding.FieldName = 'ESIVA_RECARGO_CLIENTE_FAC'
                      Visible = False
                    end
                    object tvFacturasClienteESIVA_EXENTO_CLIENTE_FAC: TcxGridDBColumn
                      DataBinding.FieldName = 'ESIVA_EXENTO_CLIENTE_FAC'
                      Visible = False
                    end
                    object tvFacturasClienteESREGIMENESPECIALAGRICOLA_CLIENTE_FAC: TcxGridDBColumn
                      DataBinding.FieldName = 'ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC'
                      Visible = False
                    end
                    object tvFacturasClienteESRETENCIONES_CLIENTE_FAC: TcxGridDBColumn
                      DataBinding.FieldName = 'ESRETENCIONES_CLIENTE_FAC'
                      Visible = False
                    end
                    object tvFacturasClienteNOMBRE_TARIFA_CLIENTE: TcxGridDBColumn
                      DataBinding.FieldName = 'NOMBRE_TARIFA_CLIENTE'
                      Visible = False
                    end
                    object tvFacturasClienteESIMP_INCL_TARIFA_CLIENTE_FAC: TcxGridDBColumn
                      Caption = 'Precios incl. Impuestos'
                      DataBinding.FieldName = 'ESIMP_INCL_TARIFA_CLIENTE_FAC'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Width = 198
                    end
                    object tvFacturasClienteESINTRACOMUNITARIO_CLIENTE_FAC: TcxGridDBColumn
                      Caption = 'Venta Intracomunitaria'
                      DataBinding.FieldName = 'ESINTRACOMUNITARIO_CLIENTE_FAC'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Width = 212
                    end
                    object tvFacturasClienteGRUPO_ZONA_IVA_EMPRESA_FAC: TcxGridDBColumn
                      DataBinding.FieldName = 'GRUPO_ZONA_IVA_EMPRESA_FAC'
                      Visible = False
                    end
                    object tvFacturasClienteTARIFA_ARTICULO_CLIENTE_FAC: TcxGridDBColumn
                      DataBinding.FieldName = 'TARIFA_ARTICULO_CLIENTE_FAC'
                      Visible = False
                    end
                    object tvFacturasClienteCODIGO_IVA_FAC: TcxGridDBColumn
                      DataBinding.FieldName = 'CODIGO_IVA_FAC'
                      Visible = False
                    end
                  end
                  object tvLineasFacturaCliente: TcxGridDBTableView
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
                    object tvLineasFacturaClienteLINEA_FACLIN: TcxGridDBColumn
                      Caption = 'C'#243'digo Linea'
                      DataBinding.FieldName = 'LINEA_FACLIN'
                      Width = 28
                    end
                    object tvLineasFacturaClienteCODIGO_ART_FACLIN: TcxGridDBColumn
                      Caption = 'C'#243'digo Art'#237'culo'
                      DataBinding.FieldName = 'CODIGO_ART_FACLIN'
                      Width = 164
                    end
                    object tvLineasFacturaClienteDESCRIPCION_ARTICULO_FACLIN: TcxGridDBColumn
                      Caption = 'Descripci'#243'n Art'#237'culo'
                      DataBinding.FieldName = 'DESCRIPCION_ARTICULO_FACLIN'
                      Width = 162
                    end
                    object tvLineasFacturaClienteTIPO_CANTIDAD_ARTICULO_FACLIN: TcxGridDBColumn
                      Caption = 'Tipo Ctd'
                      DataBinding.FieldName = 'TIPO_CANTIDAD_ARTICULO_FACLIN'
                    end
                    object tvLineasFacturaClienteCANTIDAD_FACLIN: TcxGridDBColumn
                      Caption = 'Cantidad'
                      DataBinding.FieldName = 'CANTIDAD_FACLIN'
                      Width = 84
                    end
                    object tvLineasFacturaClientePRECIO_VENTA_SIVA_ARTICULO_FACLIN: TcxGridDBColumn
                      Caption = 'Precio Sin IVA'
                      DataBinding.FieldName = 'PRECIO_VENTA_SIVA_ARTICULO_FACLIN'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                    end
                    object tvLineasFacturaClienteNOMBRE_TIPO_IVA_IVATIP: TcxGridDBColumn
                      Caption = 'Tipo IVA'
                      DataBinding.FieldName = 'NOMBRE_TIPO_IVA_IVATIP'
                    end
                    object tvLineasFacturaClientePORCENTAJE_IVA_FACLIN: TcxGridDBColumn
                      Caption = 'Porcentaje IVA'
                      DataBinding.FieldName = 'PORCENTAJE_IVA_FACLIN'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.EditFormat = '0.00 %'
                    end
                    object tvLineasFacturaClientePRECIO_VENTA_CIVA_ARTICULO_FACLIN: TcxGridDBColumn
                      Caption = 'Precio Con IVA'
                      DataBinding.FieldName = 'PRECIO_VENTA_CIVA_ARTICULO_FACLIN'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 84
                    end
                    object tvLineasFacturaClienteTOTAL_FACLIN: TcxGridDBColumn
                      Caption = 'Total'
                      DataBinding.FieldName = 'TOTAL_FACLIN'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 84
                    end
                    object tvLineasFacturaClienteFECHA_ENTREGA_FACLIN: TcxGridDBColumn
                      Caption = 'Fecha de Entrega'
                      DataBinding.FieldName = 'FECHA_ENTREGA_FACLIN'
                      PropertiesClassName = 'TcxDateEditProperties'
                    end
                  end
                  object tvDepositosCliente: TcxGridDBTableView
                    DataController.DataSource = dmClientes.dsDepositos
                    OptionsView.GroupByBox = False
                    object tvDepositosClienteID_DEPOSITO_DEP: TcxGridDBColumn
                      Caption = 'IdDep'#243'sito'
                      DataBinding.FieldName = 'ID_DEPOSITO_DEP'
                      Width = 120
                    end
                    object tvDepositosClienteFECHA_CREACION_DEP: TcxGridDBColumn
                      Caption = 'Fecha'
                      DataBinding.FieldName = 'FECHA_CREACION_DEP'
                      Width = 126
                    end
                    object tvDepositosClienteCODIGO_EMPRESA_DEP: TcxGridDBColumn
                      Caption = 'C'#243'digo Empresa'
                      DataBinding.FieldName = 'CODIGO_EMP_DEP'
                      Width = 164
                    end
                    object tvDepositosClienteCODIGO_CLIENTE_DEP: TcxGridDBColumn
                      DataBinding.FieldName = 'CODIGO_CLI_DEP'
                      Visible = False
                    end
                    object tvDepositosClienteCODIGO_ARTICULO_DEP: TcxGridDBColumn
                      Caption = 'C'#243'digo Art'#237'culo'
                      DataBinding.FieldName = 'CODIGO_ART_DEP'
                      Width = 156
                    end
                    object tvDepositosClienteCODIGO_UNIDAD_DEP: TcxGridDBColumn
                      Caption = 'SKU'
                      DataBinding.FieldName = 'CODIGO_UNIDAD_DEP'
                      Width = 136
                    end
                    object tvDepositosClienteDESCRIPCION_ARTICULO: TcxGridDBColumn
                      Caption = 'Descripci'#243'n'
                      DataBinding.FieldName = 'DESCRIPCION_ART'
                      Width = 349
                    end
                    object tvDepositosClienteCANTIDAD_PENDIENTE_DEP: TcxGridDBColumn
                      Caption = 'Uds'
                      DataBinding.FieldName = 'CANTIDAD_PENDIENTE_DEP'
                      Width = 47
                    end
                    object tvDepositosClientePRECIO_VENTA_DEP: TcxGridDBColumn
                      Caption = 'Precio Ud'
                      DataBinding.FieldName = 'PRECIO_VENTA_DEP'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                    end
                    object tvDepositosClienteIMPORTE_ANTICIPO_DEP: TcxGridDBColumn
                      Caption = 'Anticipo'
                      DataBinding.FieldName = 'IMPORTE_ANTICIPO_DEP'
                    end
                    object tvDepositosClienteESTADO_DEP: TcxGridDBColumn
                      Caption = 'Estado'
                      DataBinding.FieldName = 'ESTADO_DEP'
                    end
                    object tvDepositosClienteINSTANTEMODIF: TcxGridDBColumn
                      DataBinding.FieldName = 'INSTANTE_MODIF'
                      Visible = False
                    end
                    object tvDepositosClienteINSTANTEALTA: TcxGridDBColumn
                      DataBinding.FieldName = 'INSTANTE_ALTA'
                      Visible = False
                    end
                    object tvDepositosClienteUSUARIOALTA: TcxGridDBColumn
                      DataBinding.FieldName = 'USUARIO_ALTA'
                      Visible = False
                    end
                    object tvDepositosClienteUSUARIOMODIF: TcxGridDBColumn
                      DataBinding.FieldName = 'USUARIO_MODIF'
                      Visible = False
                    end
                    object tvDepositosClienteTIPO_IVA_DEP: TcxGridDBColumn
                      DataBinding.FieldName = 'TIPO_IVA_DEP'
                      Visible = False
                    end
                    object tvDepositosClientePORCEN_IVA_DEP: TcxGridDBColumn
                      DataBinding.FieldName = 'PORCENTAJE_IVA_DEP'
                      Visible = False
                    end
                    object tvDepositosClienteESIMP_INCL_DEP: TcxGridDBColumn
                      DataBinding.FieldName = 'ESIMP_INCL_DEP'
                      Visible = False
                    end
                    object tvDepositosClienteFECHA_ENTREGA_DEP: TcxGridDBColumn
                      DataBinding.FieldName = 'FECHA_ENTREGA_DEP'
                      Visible = False
                    end
                  end
                  object cxgrdlvlPrestamos: TcxGridLevel
                    GridView = tvDepositosCliente
                  end
                end
                object pnlPrestamosBotones: TPanel
                  Left = 868
                  Top = 0
                  Width = 117
                  Height = 412
                  Align = alRight
                  BevelOuter = bvNone
                  TabOrder = 1
                  object btnExportarExcelPrestamos: TcxButton
                    Left = 7
                    Top = 49
                    Width = 107
                    Height = 34
                    Caption = '&Exp Excel'
                    TabOrder = 1
                    OnClick = cxButton4Click
                  end
                  object btnIrAArticuloPres: TcxButton
                    Left = 8
                    Top = 8
                    Width = 105
                    Height = 34
                    Caption = 'I&r a Art'#237'culo'
                    TabOrder = 0
                    OnClick = btnIrAArticuloPresClick
                  end
                end
              end
            end
            object tsOtros: TcxTabSheet
              Caption = '&6_Otros'
              ImageIndex = 4
              object pnlUserInstantBottom: TcxGroupBox
                Left = 0
                Top = 333
                Width = 985
                Height = 79
                Align = alBottom
                TabOrder = 6
                PanelStyle.Active = True
                Style.BorderStyle = ebsNone
                Transparent = True
                object txtUSUARIOALTA: TcxDBTextEdit
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
                  Left = 165
                  Top = 9
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Instante Alta'
                  TabOrder = 1
                  Transparent = True
                end
                object txtINSTANTEALTA: TcxDBTextEdit
                  Left = 165
                  Top = 37
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'INSTANTE_ALTA'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 3
                  Width = 196
                end
                object txtINSTANTEMODIF: TcxDBTextEdit
                  Left = 569
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
                  Left = 569
                  Top = 9
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Instante Modificaci'#243'n'
                  TabOrder = 5
                  Transparent = True
                end
                object txtUSUARIOMODIF: TcxDBTextEdit
                  Left = 380
                  Top = 37
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'USUARIO_MODIF'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 4
                  Width = 171
                end
                object lblUsuarioModif: TcxLabel
                  Left = 380
                  Top = 9
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Usuario '#218'lt. ModiF.'
                  TabOrder = 6
                  Transparent = True
                end
              end
              object mTEXTO_LEGAL_FACTURA_CLIENTE: TcxDBMemo
                Left = 17
                Top = 46
                DataBinding.DataField = 'TEXTO_LEGAL_FACTURA_CLI'
                DataBinding.DataSource = dsTablaG
                TabOrder = 0
                Height = 113
                Width = 684
              end
              object lblTextoLegal: TcxLabel
                Left = 17
                Top = 19
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Caption = 'Texto legal en Borrador de Cliente'
                TabOrder = 3
                Transparent = True
              end
              object lblSerieDefault: TcxLabel
                Left = 17
                Top = 179
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Caption = 'Serie por defecto en Documentos'
                TabOrder = 4
                Transparent = True
              end
              object txtSERIE_CONTADOR: TcxDBTextEdit
                Left = 302
                Top = 178
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                DataBinding.DataField = 'SERIE_CON_CLI'
                DataBinding.DataSource = dsTablaG
                TabOrder = 1
                Width = 109
              end
              object lblOrdenListado: TcxLabel
                Left = 435
                Top = 179
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Caption = 'Orden en Listados'
                TabOrder = 5
                Transparent = True
              end
              object spORDEN_CLIENTE: TcxDBSpinEdit
                Left = 593
                Top = 178
                DataBinding.DataField = 'ORDEN_CLI'
                DataBinding.DataSource = dsTablaG
                TabOrder = 2
                Width = 106
              end
            end
          end
        end
        object splFicha: TcxSplitter
          Left = 0
          Top = 179
          Width = 993
          Height = 8
          HotZoneClassName = 'TcxMediaPlayer9Style'
          AlignSplitter = salTop
          Control = pnlTopFicha
        end
      end
      inherited tsPerfil: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 28
        ExplicitWidth = 993
        ExplicitHeight = 631
        inherited pnlPerfilTop: TPanel
          Width = 993
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 993
          inherited edtPerfilBusq: TcxTextEdit
            ExplicitHeight = 25
          end
        end
        inherited pnlPerfilDetail: TPanel
          Width = 993
          Height = 574
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 993
          ExplicitHeight = 574
          inherited cxgrdPerfil: TcxGrid
            Width = 993
            Height = 574
            ExplicitWidth = 993
            ExplicitHeight = 574
          end
        end
      end
    end
    inherited pnlTopPage: TPanel
      Width = 1001
      TabOrder = 0
      StyleElements = [seFont, seClient, seBorder]
      ExplicitWidth = 1001
      inherited pnlTopGrid: TPanel
        Width = 1001
        StyleElements = [seFont, seClient, seBorder]
        ExplicitWidth = 1001
        inherited edtBusqGlobal: TcxTextEdit
          ExplicitHeight = 25
        end
        inherited nvNavegador: TcxDBNavigator
          Top = 5
          Height = 25
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
    Left = 1001
    Height = 703
    TabOrder = 1
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 1001
    ExplicitHeight = 703
    inherited pButtonGen: TPanel
      Top = 505
      TabOrder = 2
      StyleElements = [seFont, seClient, seBorder]
      ExplicitTop = 505
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
    object btnNuevoCliente: TcxButton
      Left = 1
      Top = 157
      Width = 138
      Height = 25
      Caption = '&Nuevo Cliente'
      TabOrder = 1
      OnClick = btnNuevoClienteClick
    end
    object btnImprimirEtiqueta: TcxButton
      Left = 7
      Top = 229
      Width = 128
      Height = 52
      Caption = '&Imprimir etiqueta'
      TabOrder = 3
      WordWrap = True
      OnClick = blbEtiquetaClick
    end
  end
  object ActionListClientes: TActionList [4]
    Left = 656
    Top = 400
    object actEmpresas: TAction
      Caption = 'Empresas'
      ShortCut = 49221
      OnExecute = actEmpresasExecute
    end
    object actFacturas: TAction
      Caption = 'Borradores'
      ShortCut = 49222
      OnExecute = actFacturasExecute
    end
    object actArticulos: TAction
      Caption = 'Articulos'
      ShortCut = 16466
      OnExecute = actArticulosExecute
    end
  end
  inherited dsTablaG: TDataSource
    DataSet = dmClientes.unqryTablaG
    Left = 544
    Top = 392
  end
end
