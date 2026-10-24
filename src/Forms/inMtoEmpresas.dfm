inherited frmMtoEmpresas: TfrmMtoEmpresas
  Left = 5
  Top = 4
  Margins.Left = 0
  Margins.Top = 0
  Margins.Right = 0
  Margins.Bottom = 0
  Caption = 'Empresas'
  ClientHeight = 715
  ClientWidth = 1085
  StyleElements = [seFont, seClient, seBorder]
  ExplicitWidth = 1085
  ExplicitHeight = 715
  TextHeight = 18
  inherited pButtonPage: TPanel
    Width = 945
    Height = 715
    TabOrder = 0
    StyleElements = [seFont, seClient, seBorder]
    ExplicitWidth = 945
    ExplicitHeight = 715
    inherited pcPantalla: TcxPageControl
      Width = 945
      Height = 675
      TabOrder = 1
      ExplicitWidth = 945
      ExplicitHeight = 675
      ClientRectBottom = 673
      ClientRectRight = 943
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 2
        ExplicitTop = 28
        ExplicitWidth = 941
        ExplicitHeight = 645
        inherited cxGrdPrincipal: TcxGrid
          Width = 941
          Height = 645
          ExplicitWidth = 941
          ExplicitHeight = 645
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            object cxgrdbclmnGrdDBTabPrinCODIGO_EMPRESA: TcxGridDBColumn
              Caption = 'C'#243'digo'
              DataBinding.FieldName = 'CODIGO_EMP_EMP'
              Width = 79
            end
            object cxgrdbclmnGrdDBTabPrinORDEN_EMPRESA: TcxGridDBColumn
              Caption = 'Orden'
              DataBinding.FieldName = 'ORDEN_EMP'
              Width = 70
            end
            object cxgrdbclmnGrdDBTabPrinACTIVA_EMPRESA: TcxGridDBColumn
              Caption = 'Activo'
              DataBinding.FieldName = 'ESACTIVO_EMP'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 71
            end
            object cxgrdbclmnGrdDBTabPrinRAZONSOCIAL_EMPRESA: TcxGridDBColumn
              Caption = 'Raz'#243'n Social'
              DataBinding.FieldName = 'RAZON_SOCIAL_EMP'
              Width = 186
            end
            object cxgrdbclmnGrdDBTabPrinNIF_EMPRESA: TcxGridDBColumn
              Caption = 'Nif'
              DataBinding.FieldName = 'NIF_EMP'
              Width = 91
            end
            object cxgrdbclmnGrdDBTabPrinMOVIL_EMPRESA: TcxGridDBColumn
              Caption = 'M'#243'vil'
              DataBinding.FieldName = 'MOVIL_EMP'
              Width = 115
            end
            object cxgrdbclmnGrdDBTabPrinEMAIL_EMPRESA: TcxGridDBColumn
              Caption = 'Email'
              DataBinding.FieldName = 'EMAIL_EMP'
              Width = 189
            end
            object cxgrdbclmnGrdDBTabPrinDIRECCION1_EMPRESA: TcxGridDBColumn
              Caption = 'Direci'#243'n'
              DataBinding.FieldName = 'DIRECCION1_EMP'
              Width = 146
            end
            object cxgrdbclmnGrdDBTabPrinDIRECCION2_EMPRESA: TcxGridDBColumn
              Caption = 'M'#225's Direcci'#243'n'
              DataBinding.FieldName = 'DIRECCION2_EMP'
              Width = 138
            end
            object cxgrdbclmnGrdDBTabPrinPOBLACION_EMPRESA: TcxGridDBColumn
              Caption = 'Poblaci'#243'n'
              DataBinding.FieldName = 'POBLACION_EMP'
              Width = 132
            end
            object cxgrdbclmnGrdDBTabPrinPROVINCIA_EMPRESA: TcxGridDBColumn
              Caption = 'Provincia'
              DataBinding.FieldName = 'PROVINCIA_EMP'
              Width = 113
            end
            object cxgrdbclmnGrdDBTabPrinCPOSTAL_EMPRESA: TcxGridDBColumn
              Caption = 'C'#243'digo Postal'
              DataBinding.FieldName = 'CODIGO_POSTAL_EMP'
              Width = 138
            end
            object cxGrdDBTabPrinDESCRIPCION_ZONA_IVA: TcxGridDBColumn
              Caption = 'Zona de IVA principal'
              DataBinding.FieldName = 'DESCRIPCION_IVA_IVAGRP'
              Width = 302
            end
            object cxgrdbclmnGrdDBTabPrin_ESREGIMENESPECIALAGRICOLA_EMPRESA: TcxGridDBColumn
              Caption = 'Es REAGP'
              DataBinding.FieldName = 'ESREGIMENESPECIALAGRICOLA_EMP'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 86
            end
            object cxgrdbclmnGrdDBTabPrinESRETENCIONES_EMPRESA: TcxGridDBColumn
              Caption = 'Aplica Retenciones'
              DataBinding.FieldName = 'ESRETENCIONES_EMP'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 170
            end
            object cxgrdbclmnGrdDBTabPrinESIVA_RECARGO_COMPRAS_EMPRESA: TcxGridDBColumn
              Caption = 'R.E. compras'
              DataBinding.FieldName = 'ESIVA_RECARGO_COMPRAS_EMP'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 115
            end
            object cxgrdbclmnGrdDBTabPrinTEXTO_LEGAL_FACTURA_EMPRESA: TcxGridDBColumn
              Caption = 'Texto en Borrador'
              DataBinding.FieldName = 'TEXTO_LEGAL_FACTURA_EMP'
              Width = 366
            end
            object cxgrdbclmnGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn
              DataBinding.FieldName = 'INSTANTE_MODIF'
              Visible = False
            end
            object cxgrdbclmnGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn
              DataBinding.FieldName = 'INSTANTE_ALTA'
              Visible = False
            end
            object cxgrdbclmnGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn
              DataBinding.FieldName = 'USUARIO_ALTA'
              Visible = False
              Width = 88
            end
            object cxgrdbclmnGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn
              DataBinding.FieldName = 'USUARIO_MODIF'
              Visible = False
              Width = 96
            end
            object cxGrdDBTabPrinPAIS_EMPRESA: TcxGridDBColumn
              DataBinding.FieldName = 'PAIS_EMPRESA'
              Visible = False
            end
            object cxGrdDBTabPrinGRUPO_ZONA_IVA_EMPRESA: TcxGridDBColumn
              DataBinding.FieldName = 'GRUPO_ZONA_IVA_EMP'
              Visible = False
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        OnEnter = tsFichaEnter
        ExplicitLeft = 2
        ExplicitTop = 28
        ExplicitWidth = 941
        ExplicitHeight = 645
        object pnlFichaDetail: TPanel
          Left = 0
          Top = 188
          Width = 941
          Height = 457
          Align = alClient
          BevelOuter = bvNone
          TabOrder = 2
          object pcPestana: TcxPageControl
            Left = 0
            Top = 0
            Width = 941
            Height = 457
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsMasDatos
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 455
            ClientRectLeft = 2
            ClientRectRight = 939
            ClientRectTop = 28
            object tsMasDatos: TcxTabSheet
              Caption = '&1_M'#225's Datos'
              ImageIndex = 0
              DesignSize = (
                937
                427)
              object cxgrpbxIdentificacion: TcxGroupBox
                AlignWithMargins = True
                Left = 19
                Top = 3
                TabStop = True
                Anchors = [akLeft, akTop, akRight, akBottom]
                PanelStyle.Active = True
                PanelStyle.BorderWidth = 2
                PanelStyle.CaptionIndent = 4
                PanelStyle.OfficeBackgroundKind = pobkGradient
                PanelStyle.WordWrap = True
                TabOrder = 0
                Transparent = True
                Height = 421
                Width = 745
                object lblMovil: TcxLabel
                  Left = 8
                  Top = 21
                  AutoSize = False
                  Caption = 'M'#243'vil'
                  Properties.Alignment.Horz = taRightJustify
                  Properties.Alignment.Vert = taVCenter
                  TabOrder = 12
                  Transparent = True
                  Height = 24
                  Width = 90
                end
                object txtMOVIL_EMPRESA: TcxDBTextEdit
                  Left = 106
                  Top = 21
                  DataBinding.DataField = 'MOVIL_EMP'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 0
                  Width = 322
                end
                object lblEmail: TcxLabel
                  Left = 8
                  Top = 59
                  AutoSize = False
                  Caption = 'Email'
                  Properties.Alignment.Horz = taRightJustify
                  Properties.Alignment.Vert = taVCenter
                  TabOrder = 13
                  Transparent = True
                  Height = 24
                  Width = 90
                end
                object lblDireccion: TcxLabel
                  Left = 8
                  Top = 94
                  AutoSize = False
                  Caption = 'Direcci'#243'n'
                  Properties.Alignment.Horz = taRightJustify
                  Properties.Alignment.Vert = taVCenter
                  TabOrder = 14
                  Transparent = True
                  Height = 24
                  Width = 90
                end
                object txtDIRECCION1_EMPRESA: TcxDBTextEdit
                  Left = 106
                  Top = 94
                  DataBinding.DataField = 'DIRECCION1_EMP'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 2
                  Width = 322
                end
                object txtEMAIL_EMPRESA: TcxDBTextEdit
                  Left = 106
                  Top = 59
                  DataBinding.DataField = 'EMAIL_EMP'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 1
                  Width = 322
                end
                object txtDIRECCION2_EMPRESA: TcxDBTextEdit
                  Left = 106
                  Top = 132
                  DataBinding.DataField = 'DIRECCION2_EMP'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 3
                  Width = 322
                end
                object txtPOBLACION_EMPRESA: TcxDBTextEdit
                  Left = 106
                  Top = 203
                  DataBinding.DataField = 'POBLACION_EMP'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 5
                  Width = 322
                end
                object lblPoblacion: TcxLabel
                  Left = 8
                  Top = 203
                  AutoSize = False
                  Caption = 'Poblaci'#243'n'
                  Properties.Alignment.Horz = taRightJustify
                  Properties.Alignment.Vert = taVCenter
                  TabOrder = 16
                  Transparent = True
                  Height = 24
                  Width = 90
                end
                object lblProvincia: TcxLabel
                  Left = 8
                  Top = 240
                  AutoSize = False
                  Caption = 'Provincia'
                  Properties.Alignment.Horz = taRightJustify
                  Properties.Alignment.Vert = taVCenter
                  TabOrder = 17
                  Transparent = True
                  Height = 24
                  Width = 90
                end
                object txtPROVINCIA_EMPRESA: TcxDBTextEdit
                  Left = 106
                  Top = 240
                  DataBinding.DataField = 'PROVINCIA_EMP'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 6
                  Width = 322
                end
                object chkRegimenEspecial: TcxDBCheckBox
                  Left = 69
                  Top = 350
                  Caption = 'R'#233'gimen especial agricola/ganadero/pesca'
                  DataBinding.DataField = 'ESREGIMENESPECIALAGRICOLA_EMP'
                  DataBinding.DataSource = dsTablaG
                  Properties.ValueChecked = 'S'
                  Properties.ValueUnchecked = 'N'
                  Properties.OnChange = chkAplicaRetencionesPropertiesChange
                  Style.TransparentBorder = False
                  TabOrder = 10
                  Transparent = True
                end
                object txtCODIGO_POSTAL_EMP: TcxDBTextEdit
                  Left = 106
                  Top = 166
                  DataBinding.DataField = 'CODIGO_POSTAL_EMP'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 4
                  Width = 322
                end
                object lblCodPostal: TcxLabel
                  Left = 8
                  Top = 166
                  AutoSize = False
                  Caption = 'C'#243'd Postal'
                  Properties.Alignment.Horz = taRightJustify
                  Properties.Alignment.Vert = taVCenter
                  TabOrder = 15
                  Transparent = True
                  Height = 24
                  Width = 90
                end
                object lblIBAN: TcxLabel
                  Left = 8
                  Top = 306
                  AutoSize = False
                  Caption = 'IBAN'
                  Properties.Alignment.Horz = taRightJustify
                  Properties.Alignment.Vert = taVCenter
                  TabOrder = 21
                  Transparent = True
                  Height = 24
                  Width = 90
                end
                object txtIBAN_EMPRESA: TcxDBMaskEdit
                  Left = 107
                  Top = 306
                  DataBinding.DataField = 'IBAN_EMP'
                  DataBinding.DataSource = dsTablaG
                  Properties.IgnoreMaskBlank = True
                  Properties.EditMask = 'aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa'
                  TabOrder = 8
                  Width = 369
                end
                object btnValidar: TcxButton
                  Left = 482
                  Top = 306
                  Width = 98
                  Height = 27
                  Caption = 'Vali&dar'
                  TabOrder = 9
                  OnClick = btnValidarClick
                end
                object lblProvincia1: TcxLabel
                  Left = 8
                  Top = 273
                  AutoSize = False
                  Caption = 'Pa'#237's'
                  Properties.Alignment.Horz = taRightJustify
                  Properties.Alignment.Vert = taVCenter
                  TabOrder = 20
                  Transparent = True
                  Height = 24
                  Width = 90
                end
                object txtNOMBRE_PAIS_EMPRESA: TcxDBTextEdit
                  Left = 176
                  Top = 273
                  DataBinding.DataField = 'NOMBRE_PAI_EMP'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 19
                  Visible = False
                  Width = 254
                end
                object txtCODIGO_PAIS_EMPRESA: TcxDBTextEdit
                  Left = 106
                  Top = 273
                  DataBinding.DataField = 'CODIGO_PAI_EMP'
                  DataBinding.DataSource = dsTablaG
                  Enabled = False
                  Properties.OnChange = txtCODIGO_PAIS_EMPRESAPropertiesChange
                  TabOrder = 18
                  Width = 64
                end
                object cbbPaises: TcxDBLookupComboBox
                  Left = 187
                  Top = 273
                  DataBinding.DataField = 'CODIGO_PAI_EMP'
                  DataBinding.DataSource = dsTablaG
                  Properties.KeyFieldNames = 'CODIGO'
                  Properties.ListColumns = <
                    item
                      Caption = 'Nombre Pais'
                      FieldName = 'NOMBRE'
                    end>
                  Properties.ListOptions.CaseInsensitive = True
                  Properties.ListOptions.ShowHeader = False
                  Properties.ListSource = dmEmpresas.dsPaises
                  TabOrder = 7
                  Width = 203
                end
                object chkRecargoEquivalenciaCompras: TcxDBCheckBox
                  Left = 69
                  Top = 374
                  Caption = 'Recargo equivalencia compras'
                  DataBinding.DataField = 'ESIVA_RECARGO_COMPRAS_EMP'
                  DataBinding.DataSource = dsTablaG
                  Properties.ValueChecked = 'S'
                  Properties.ValueUnchecked = 'N'
                  Style.TransparentBorder = False
                  TabOrder = 11
                  Transparent = True
                end
                object lblClienteTraspasos: TcxLabel
                  Left = 450
                  Top = 25
                  Caption = 'Cliente de traspasos'
                  TabOrder = 22
                  Transparent = True
                end
                object cbbClienteTraspasos: TcxDBLookupComboBox
                  Left = 450
                  Top = 50
                  Hint = 'Cliente al que se emiten las facturas internas de traspasos (TA/TV)'
                  DataBinding.DataField = 'CODIGO_CLI_TRASPASOS_EMP'
                  DataBinding.DataSource = dsTablaG
                  ParentShowHint = False
                  Properties.DropDownWidth = 420
                  Properties.KeyFieldNames = 'CODIGO_CLI_CLI'
                  Properties.ListColumns = <
                    item
                      FieldName = 'RAZON_SOCIAL_CLI'
                    end
                    item
                      FieldName = 'CODIGO_CLI_CLI'
                    end>
                  Properties.ListOptions.CaseInsensitive = True
                  Properties.ListOptions.ShowHeader = False
                  ShowHint = True
                  TabOrder = 23
                  Width = 280
                end
                object btnCrearClienteTraspasos: TcxButton
                  Left = 450
                  Top = 84
                  Width = 280
                  Height = 27
                  Caption = 'Crear cliente de traspaso entre empresas'
                  TabOrder = 24
                  OnClick = btnCrearClienteTraspasosClick
                end
                object lblTotalMaximoLinea: TcxLabel
                  Left = 450
                  Top = 125
                  Caption = 'Total m'#225'ximo por l'#237'nea'
                  TabOrder = 25
                  Transparent = True
                end
                object curTOTAL_MAXIMO_LINEA_EMPRESA: TcxDBCurrencyEdit
                  Left = 450
                  Top = 150
                  Hint = 
                    'Una l'#237'nea de venta, compra o TPV con un total mayor pide ' +
                    'confirmaci'#243'n antes de grabarse. Vac'#237'o o 0 = sin l'#237'mite'
                  DataBinding.DataField = 'TOTAL_MAXIMO_LINEA_EMP'
                  DataBinding.DataSource = dsTablaG
                  ParentShowHint = False
                  Properties.DecimalPlaces = 2
                  Properties.DisplayFormat = '#,##0.00 '#8364';-#,##0.00 '#8364';'#39#39
                  ShowHint = True
                  TabOrder = 26
                  Width = 140
                end
              end
            end
            object tsRetenciones: TcxTabSheet
              Caption = '&2_Retenciones'
              ImageIndex = 2
              object pnlRetenOpts: TPanel
                Left = 827
                Top = 0
                Width = 110
                Height = 427
                Align = alRight
                BevelOuter = bvNone
                TabOrder = 1
                object btnAddIRPF: TcxButton
                  Left = 0
                  Top = 13
                  Width = 105
                  Height = 25
                  Caption = '&A'#241'adir IRPF'
                  TabOrder = 0
                  OnClick = btnAddIRPFClick
                end
              end
              object pnlRetencionesCli: TPanel
                Left = 0
                Top = 0
                Width = 827
                Height = 427
                Align = alClient
                BevelOuter = bvNone
                TabOrder = 0
                object cxgrdRetenciones: TcxGrid
                  Left = 0
                  Top = 0
                  Width = 827
                  Height = 427
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Align = alClient
                  TabOrder = 0
                  object tvRetenciones: TcxGridDBTableView
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
                    OptionsBehavior.AlwaysShowEditor = True
                    OptionsBehavior.GoToNextCellOnEnter = True
                    OptionsBehavior.IncSearch = True
                    OptionsCustomize.ColumnHiding = True
                    OptionsData.Appending = True
                    OptionsView.GroupByBox = False
                    OptionsView.Indicator = True
                    object cxgrdbclmntv1CODIGO_RETENCION: TcxGridDBColumn
                      Caption = 'C'#243'digo Retenci'#243'n'
                      DataBinding.FieldName = 'CODIGO_RETENCION_EMPRET'
                      Width = 163
                    end
                    object cxgrdbclmntv1CODIGO_EMPRESA_RETENCION: TcxGridDBColumn
                      DataBinding.FieldName = 'CODIGO_EMP_EMPRET'
                      Visible = False
                      Width = 122
                    end
                    object tvRetencionesPORCENRETENCION_RETENCION: TcxGridDBColumn
                      Caption = '% Retenci'#243'n'
                      DataBinding.FieldName = 'PORCENTAJE_EMPRET'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Width = 107
                    end
                    object cxgrdbclmntv1FECHA_DESDE_RETENCION: TcxGridDBColumn
                      Caption = 'Fecha Aplicaci'#243'n desde'
                      DataBinding.FieldName = 'FECHA_DESDE_EMPRET'
                      PropertiesClassName = 'TcxDateEditProperties'
                      Width = 151
                    end
                    object cxgrdbclmntv1FECHA_HASTA_RETENCION: TcxGridDBColumn
                      Caption = 'Fecha Aplicaci'#243'n hasta'
                      DataBinding.FieldName = 'FECHA_HASTA_EMPRET'
                      PropertiesClassName = 'TcxDateEditProperties'
                      Width = 150
                    end
                    object cxgrdbclmntv1INSTANTEMODIF: TcxGridDBColumn
                      DataBinding.FieldName = 'INSTANTE_MODIF'
                      Visible = False
                    end
                    object cxgrdbclmntv1INSTANTEALTA: TcxGridDBColumn
                      DataBinding.FieldName = 'INSTANTE_ALTA'
                      Visible = False
                    end
                    object cxgrdbclmntv1USUARIOALTA: TcxGridDBColumn
                      DataBinding.FieldName = 'USUARIO_ALTA'
                      Visible = False
                    end
                    object cxgrdbclmntv1USUARIOMODIF: TcxGridDBColumn
                      DataBinding.FieldName = 'USUARIO_MODIF'
                      Visible = False
                    end
                  end
                  object cxgrdlvlRetenciones: TcxGridLevel
                    GridView = tvRetenciones
                  end
                end
              end
            end
            object tsHistoriaFacturacion: TcxTabSheet
              Caption = '&3_Hist'#243'rico Borradores'
              ImageIndex = 3
              object pnlFactura: TPanel
                Left = 0
                Top = 0
                Width = 937
                Height = 427
                Align = alClient
                TabOrder = 0
                object cxgrdEmpresasFacturas: TcxGrid
                  Left = 1
                  Top = 1
                  Width = 818
                  Height = 425
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
                    DataController.DataSource = dmEmpresas.dsFacturasEmpresas
                    DataController.Summary.DefaultGroupSummaryItems = <
                      item
                        Kind = skSum
                        Column = tvFacturacionTOTAL_LIQUIDO_FACTURA
                      end
                      item
                        Format = '0,00 '#8364';-0,00 '#8364
                        Position = spFooter
                        Column = tvFacturacionTOTAL_LIQUIDO_FACTURA
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
                        Column = tvFacturacionTOTAL_BASES_FACTURA
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
                      PropertiesClassName = 'TcxDateEditProperties'
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
                      Caption = 'Total a Pagar'
                      DataBinding.FieldName = 'TOTAL_LIQUIDO_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 126
                    end
                    object tvFacturacionPORCEN_RETENCION_FACTURA: TcxGridDBColumn
                      Caption = '% IRPF'
                      DataBinding.FieldName = 'PORCENTAJE_RETENCION_FAC'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                      Width = 71
                    end
                    object tvFacturacionTOTAL_RETENCION_FACTURA: TcxGridDBColumn
                      Caption = 'Total IRPF'
                      DataBinding.FieldName = 'TOTAL_RETENCION_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 118
                    end
                    object tvFacturacionTOTAL_BASES_FACTURA: TcxGridDBColumn
                      Caption = 'Total Bases Imponibles'
                      DataBinding.FieldName = 'TOTAL_BASES_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 199
                    end
                    object tvFacturacionTOTAL_IMPUESTOS_FACTURA: TcxGridDBColumn
                      Caption = 'IVA + RE'
                      DataBinding.FieldName = 'TOTAL_IMPUESTOS_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 74
                    end
                    object tvFacturacionFORMA_PAGO_FACTURA: TcxGridDBColumn
                      Caption = 'Forma de Pago'
                      DataBinding.FieldName = 'FORMA_PAGO_FAC'
                      Width = 129
                    end
                    object tvFacturacionDESCRIPCION_FORMAPAGO: TcxGridDBColumn
                      Caption = 'Descripci'#243'n Forma Pago'
                      DataBinding.FieldName = 'DESCRIPCION_FORMA_PAGO_FP'
                      Width = 230
                    end
                    object tvFacturacionCODIGO_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'C'#243'digo Cliente'
                      DataBinding.FieldName = 'CODIGO_CLI_FAC'
                      Width = 131
                    end
                    object tvFacturacionRAZONSOCIAL_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Raz'#243'n Social Clietne'
                      DataBinding.FieldName = 'RAZON_SOCIAL_CLIENTE_FAC'
                      Width = 189
                    end
                    object tvFacturacionNIF_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Nif Cliente'
                      DataBinding.FieldName = 'NIF_CLIENTE_FAC'
                      Width = 94
                    end
                    object tvFacturacionMOVIL_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'M'#243'vil Cliente'
                      DataBinding.FieldName = 'MOVIL_CLIENTE_FAC'
                      Width = 115
                    end
                    object tvFacturacionEMAIL_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Email Cliente'
                      DataBinding.FieldName = 'EMAIL_CLIENTE_FAC'
                      Width = 114
                    end
                    object tvFacturacionDIRECCION1_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Direcci'#243'n1 Cliente'
                      DataBinding.FieldName = 'DIRECCION1_CLIENTE_FAC'
                      Width = 161
                    end
                    object tvFacturacionDIRECCION2_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Direcci'#243'n2 Cliente'
                      DataBinding.FieldName = 'DIRECCION2_CLIENTE_FAC'
                      Width = 161
                    end
                    object tvFacturacionCPOSTAL_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'CPostal Cliente'
                      DataBinding.FieldName = 'CODIGO_POSTAL_CLIENTE_FAC'
                      Width = 133
                    end
                    object tvFacturacionPOBLACION_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Poblaci'#243'n Cliente'
                      DataBinding.FieldName = 'POBLACION_CLIENTE_FAC'
                      Width = 152
                    end
                    object tvFacturacionPROVINCIA_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Provincia Cliente'
                      DataBinding.FieldName = 'PROVINCIA_CLIENTE_FAC'
                      Width = 146
                    end
                    object tvFacturacionPAIS_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Pa'#237's Cliente'
                      DataBinding.FieldName = 'PAIS_CLIENTE_FACTURA'
                      Width = 149
                    end
                    object tvFacturacionESIVA_RECARGO_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Tiene RE Cliente'
                      DataBinding.FieldName = 'ESIVA_RECARGO_CLIENTE_FAC'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Width = 155
                    end
                    object tvFacturacionESIVA_EXENTO_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'IVA Exento Cliente'
                      DataBinding.FieldName = 'ESIVA_EXENTO_CLIENTE_FAC'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Width = 161
                    end
                    object tvFacturacionESREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'REAGP Cliente'
                      DataBinding.FieldName = 'ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Width = 123
                    end
                    object tvFacturacionESRETENCIONES_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Tiene IRPF Cliente'
                      DataBinding.FieldName = 'ESRETENCIONES_CLIENTE_FAC'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Width = 155
                    end
                    object tvFacturacionNOMBRE_TARIFA_CLIENTE: TcxGridDBColumn
                      Caption = 'Tarifa Cliente'
                      DataBinding.FieldName = 'NOMBRE_TARIFA_CLIENTE'
                      Width = 118
                    end
                    object tvFacturacionESIMP_INCL_TARIFA_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Tarifa tiene Imp Incl'
                      DataBinding.FieldName = 'ESIMP_INCL_TARIFA_CLIENTE_FAC'
                      Visible = False
                      Width = 184
                    end
                    object tvFacturacionESINTRACOMUNITARIO_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Es Cliente Intracomunitario'
                      DataBinding.FieldName = 'ESINTRACOMUNITARIO_CLIENTE_FAC'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Width = 235
                    end
                    object tvFacturacionESIRPF_IMP_INCL_ZONA_IVA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'ESIRPF_IMP_INCL_ZONA_IVA_FAC'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Visible = False
                    end
                    object tvFacturacionESAPLICA_RE_ZONA_IVA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'ESAPLICA_RE_ZONA_IVA_FAC'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Visible = False
                    end
                    object tvFacturacionESIVAAGRICOLA_ZONA_IVA_FACTURA: TcxGridDBColumn
                      Caption = 'IVA Agr'#237'cola'
                      DataBinding.FieldName = 'ESIVAAGRICOLA_ZONA_IVA_FAC'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Visible = False
                    end
                    object tvFacturacionPALABRA_REPORTS_ZONA_IVA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'PALABRA_REPORTS_ZONA_IVA_FAC'
                      Visible = False
                    end
                    object tvFacturacionDESCRIPCION_ZONA_IVA: TcxGridDBColumn
                      Caption = 'Zona IVA'
                      DataBinding.FieldName = 'DESCRIPCION_IVA_IVAGRP'
                      Width = 90
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
                      Width = 127
                    end
                    object tvFacturacionTOTAL_IVAN_FACTURA: TcxGridDBColumn
                      Caption = 'IVA Normal'
                      DataBinding.FieldName = 'TOTAL_IVAN_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 99
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
                      Width = 107
                    end
                    object tvFacturacionTOTAL_REN_FACTURA: TcxGridDBColumn
                      Caption = 'RE Normal'
                      DataBinding.FieldName = 'TOTAL_REN_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 91
                    end
                    object tvFacturacionTOTAL_BASEI_IVAN_FACTURA: TcxGridDBColumn
                      Caption = 'Base Imp Normal'
                      DataBinding.FieldName = 'TOTAL_BASEI_IVAN_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 158
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
                      Width = 145
                    end
                    object tvFacturacionTOTAL_IVAR_FACTURA: TcxGridDBColumn
                      Caption = 'IVA Reducido'
                      DataBinding.FieldName = 'TOTAL_IVAR_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 117
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
                      Width = 125
                    end
                    object tvFacturacionTOTAL_RER_FACTURA: TcxGridDBColumn
                      Caption = 'RE Reducido'
                      DataBinding.FieldName = 'TOTAL_RER_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 121
                    end
                    object tvFacturacionTOTAL_BASEI_IVAR_FACTURA: TcxGridDBColumn
                      Caption = 'Base Imp Reducido'
                      DataBinding.FieldName = 'TOTAL_BASEI_IVAR_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 163
                    end
                    object tvFacturacionPORCEN_IVAS_FACTURA: TcxGridDBColumn
                      Caption = '% IVA S'#250'perReducido'
                      DataBinding.FieldName = 'PORCENTAJE_IVAS_FAC'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                      Width = 181
                    end
                    object tvFacturacionTOTAL_IVAS_FACTURA: TcxGridDBColumn
                      Caption = 'IVA S'#250'perReducido'
                      DataBinding.FieldName = 'TOTAL_IVAS_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 165
                    end
                    object tvFacturacionPORCEN_RES_FACTURA: TcxGridDBColumn
                      Caption = '% RE S'#250'perReducido'
                      DataBinding.FieldName = 'PORCENTAJE_RES_FAC'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                      Width = 173
                    end
                    object tvFacturacionTOTAL_RES_FACTURA: TcxGridDBColumn
                      Caption = 'RE S'#250'perReducido'
                      DataBinding.FieldName = 'TOTAL_RES_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 157
                    end
                    object tvFacturacionTOTAL_BASEI_IVAS_FACTURA: TcxGridDBColumn
                      Caption = 'Base Imp S'#250'perReducido'
                      DataBinding.FieldName = 'TOTAL_BASEI_IVAS_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 224
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
                      Width = 112
                    end
                    object tvFacturacionTOTAL_IVAE_FACTURA: TcxGridDBColumn
                      Caption = 'IVA Exento'
                      DataBinding.FieldName = 'TOTAL_IVAE_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 108
                    end
                    object tvFacturacionPORCEN_REE_FACTURA: TcxGridDBColumn
                      Caption = 'RE Exento'
                      DataBinding.FieldName = 'PORCENTAJE_REE_FAC'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                      Width = 88
                    end
                    object tvFacturacionTOTAL_REE_FACTURA: TcxGridDBColumn
                      Caption = 'RE Exento'
                      DataBinding.FieldName = 'TOTAL_REE_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 88
                    end
                    object tvFacturacionTOTAL_BASEI_IVAE_FACTURA: TcxGridDBColumn
                      Caption = 'Base Imp Exento'
                      DataBinding.FieldName = 'TOTAL_BASEI_IVAE_FAC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 143
                    end
                    object tvFacturacionCODIGO_EMPRESA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'CODIGO_EMP_FAC'
                      Visible = False
                    end
                    object tvFacturacionRAZONSOCIAL_EMPRESA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'RAZON_SOCIAL_EMPRESA_FAC'
                      Visible = False
                    end
                    object tvFacturacionNIF_EMPRESA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'NIF_EMPRESA_FAC'
                      Visible = False
                    end
                    object tvFacturacionMOVIL_EMPRESA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'MOVIL_EMPRESA_FAC'
                      Visible = False
                    end
                    object tvFacturacionEMAIL_EMPRESA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'EMAIL_EMPRESA_FAC'
                      Visible = False
                    end
                    object tvFacturacionDIRECCION1_EMPRESA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'DIRECCION1_EMPRESA_FAC'
                      Visible = False
                    end
                    object tvFacturacionDIRECCION2_EMPRESA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'DIRECCION2_EMPRESA_FAC'
                      Visible = False
                    end
                    object tvFacturacionPOBLACION_EMPRESA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'POBLACION_EMPRESA_FAC'
                      Visible = False
                    end
                    object tvFacturacionPROVINCIA_EMPRESA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'PROVINCIA_EMPRESA_FAC'
                      Visible = False
                    end
                    object tvFacturacionPAIS_EMPRESA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'PAIS_EMPRESA_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionCPOSTAL_EMPRESA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'CODIGO_POSTAL_EMPRESA_FAC'
                      Visible = False
                    end
                    object tvFacturacionESRETENCIONES_EMPRESA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'ESRETENCIONES_EMPRESA_FAC'
                      Visible = False
                    end
                    object tvFacturacionDESCRIPCION_ZONA_IVA_EMPRESA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'DESCRIPCION_ZONA_IVA_EMPRESA_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC'
                      Visible = False
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
                    object tvLineasFacturacionLINEA_LINEA: TcxGridDBColumn
                      Caption = 'Nro Linea'
                      DataBinding.FieldName = 'LINEA_FACLIN'
                      Width = 28
                    end
                    object tvLineasFacturacionCODIGO_ARTICULO_LINEA: TcxGridDBColumn
                      Caption = 'C'#243'digo Art'#237'culo'
                      DataBinding.FieldName = 'CODIGO_ART_FACLIN'
                      Width = 164
                    end
                    object tvLineasFacturacionDESCRIPCION_ARTICULO_LINEA: TcxGridDBColumn
                      Caption = 'Descripci'#243'n'
                      DataBinding.FieldName = 'DESCRIPCION_ARTICULO_FACLIN'
                      Width = 162
                    end
                    object tvLineasFacturacionCANTIDAD_LINEA: TcxGridDBColumn
                      Caption = 'Cantidad'
                      DataBinding.FieldName = 'CANTIDAD_FACLIN'
                      Width = 84
                    end
                    object tvLineasFacturacionTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                      Caption = 'Tipo Cantidad'
                      DataBinding.FieldName = 'TIPO_CANTIDAD_ARTICULO_FACLIN'
                    end
                    object tvLineasFacturacionPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                      Caption = 'Precio SIVA'
                      DataBinding.FieldName = 'PRECIO_VENTA_SIVA_ARTICULO_FACLIN'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                    end
                    object tvLineasFacturacionPORCEN_IVA_FACTURA_LINEA: TcxGridDBColumn
                      Caption = 'Porcentaje IVA'
                      DataBinding.FieldName = 'PORCENTAJE_IVA_FACLIN'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                    end
                    object dbcLineasFacturacionNOMBRE_TIPO_IVA: TcxGridDBColumn
                      DataBinding.FieldName = 'NOMBRE_TIPO_IVA_IVATIP'
                    end
                    object tvLineasFacturacionPRECIOVENTA_ARTICULO_LINEA: TcxGridDBColumn
                      Caption = 'Precio CIVA'
                      DataBinding.FieldName = 'PRECIO_VENTA_CIVA_ARTICULO_FACLIN'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 84
                    end
                    object tvLineasFacturacionSUM_TOTAL_LINEA: TcxGridDBColumn
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
                  object cxgrdlvlcxgrd1Level1: TcxGridLevel
                    GridView = tvFacturacion
                    object cxgrdlvlcxgrd1Level2: TcxGridLevel
                      GridView = tvLineasFacturacion
                    end
                  end
                end
                object pnlFacturaOpts: TPanel
                  Left = 819
                  Top = 1
                  Width = 117
                  Height = 425
                  Align = alRight
                  TabOrder = 1
                  object btnIraFactura: TcxButton
                    Left = 6
                    Top = 16
                    Width = 106
                    Height = 34
                    Caption = '&Ir a Borrador'
                    TabOrder = 0
                    OnClick = btnIraFacturaClick
                  end
                  object btnIraCliente: TcxButton
                    Left = 7
                    Top = 56
                    Width = 105
                    Height = 34
                    Caption = 'I&r a Cliente'
                    TabOrder = 1
                    OnClick = btnIraClienteClick
                  end
                  object btnExportarExcel: TcxButton
                    Left = 5
                    Top = 136
                    Width = 106
                    Height = 34
                    Caption = 'Exp. Excel'
                    TabOrder = 3
                    OnClick = btnExportarExcelClick
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
            object tsSeries: TcxTabSheet
              Caption = '&4_Series'
              ImageIndex = 4
              object pnlSeriesOpts: TPanel
                Left = 819
                Top = 0
                Width = 118
                Height = 427
                Align = alRight
                BevelOuter = bvNone
                TabOrder = 1
                object btnAddSerie: TcxButton
                  Left = 6
                  Top = 13
                  Width = 108
                  Height = 25
                  Caption = 'A'#241'adir Serie'
                  TabOrder = 0
                  OnClick = btnAddSerieClick
                end
                object btnCrearSeriesDoc: TcxButton
                  Left = 6
                  Top = 44
                  Width = 108
                  Height = 48
                  Caption = 'A'#241'adir serie a todos'
                  TabOrder = 1
                  WordWrap = True
                  OnClick = btnCrearSeriesDocClick
                end
              end
              object pnlSeriesCli: TPanel
                Left = 0
                Top = 0
                Width = 819
                Height = 427
                Align = alClient
                BevelOuter = bvNone
                TabOrder = 0
                object cxGrdSeries: TcxGrid
                  Left = 0
                  Top = 0
                  Width = 819
                  Height = 427
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Align = alClient
                  TabOrder = 0
                  object tvSeries: TcxGridDBTableView
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
                    DataController.DataSource = dmEmpresas.dsSeries
                    DataController.Options = [dcoCaseInsensitive, dcoAssignGroupingValues, dcoAssignMasterDetailKeys, dcoSaveExpanding]
                    OptionsBehavior.AlwaysShowEditor = True
                    OptionsBehavior.GoToNextCellOnEnter = True
                    OptionsBehavior.IncSearch = True
                    OptionsCustomize.ColumnHiding = True
                    OptionsData.Appending = True
                    OptionsView.GroupByBox = False
                    OptionsView.Indicator = True
                    object dbmSeriesCODIGO_ALMACEN_SERIE: TcxGridDBColumn
                      Caption = 'Almac'#233'n'
                      DataBinding.FieldName = 'CODIGO_ALM_EMPSER'
                    end
                    object dbmSeriesCODIGO_CAJA_SERIE: TcxGridDBColumn
                      Caption = 'Caja'
                      DataBinding.FieldName = 'CODIGO_CAJA_EMPSER'
                    end
                    object dbmSeriesSERIE_SERIE: TcxGridDBColumn
                      Caption = 'Serie base'
                      DataBinding.FieldName = 'EMPSER'
                    end
                    object tvSeriesSERIE_TOKENIZADA_EMPSER: TcxGridDBColumn
                      Caption = 'Serie tokenizada'
                      DataBinding.FieldName = 'SERIE_TOKENIZADA_EMPSER'
                      Width = 115
                    end
                    object dbmSeriesTIPODOC_SERIE: TcxGridDBColumn
                      Caption = 'Tipo Doc'
                      DataBinding.FieldName = 'TIPO_DOC_EMPSER'
                      Width = 45
                    end
                    object dbmSeriesSUBITPO_SERIE: TcxGridDBColumn
                      Caption = 'Subtipo'
                      DataBinding.FieldName = 'SUBTIPO_EMPSER'
                      Width = 107
                    end
                    object tvSeriesESDEFECTO_EMPSER: TcxGridDBColumn
                      Caption = 'Por defecto'
                      DataBinding.FieldName = 'ESDEFECTO_EMPSER'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Width = 75
                    end
                    object dbmSeriesFECHA_DESDE_SERIE: TcxGridDBColumn
                      Caption = 'Fecha Desde'
                      DataBinding.FieldName = 'FECHA_DESDE_EMPSER'
                      Width = 121
                    end
                    object dbmSeriesFECHA_HASTA_SERIE: TcxGridDBColumn
                      Caption = 'Fecha Hasta'
                      DataBinding.FieldName = 'FECHA_HASTA_EMPSER'
                    end
                  end
                  object lvSeries: TcxGridLevel
                    GridView = tvSeries
                  end
                end
              end
            end
            object tsBancos: TcxTabSheet
              Caption = '&7_Bancos'
              object pnlBancosOpts: TPanel
                Left = 811
                Top = 0
                Width = 126
                Height = 427
                Align = alRight
                BevelOuter = bvNone
                TabOrder = 1
                object btnAddBanco: TcxButton
                  Left = 6
                  Top = 13
                  Width = 115
                  Height = 25
                  Caption = 'A'#241'adir Banco'
                  TabOrder = 0
                  OnClick = btnAddBancoClick
                end
              end
              object pnlBancosCli: TPanel
                Left = 0
                Top = 0
                Width = 811
                Height = 427
                Align = alClient
                BevelOuter = bvNone
                TabOrder = 0
                object cxGrdBancos: TcxGrid
                  Left = 0
                  Top = 0
                  Width = 811
                  Height = 427
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Align = alClient
                  TabOrder = 0
                  object tvBancos: TcxGridDBTableView
                    Navigator.Buttons.ConfirmDelete = True
                    Navigator.Buttons.First.Visible = False
                    Navigator.Buttons.PriorPage.Visible = False
                    Navigator.Buttons.Prior.Visible = False
                    Navigator.Buttons.Next.Visible = False
                    Navigator.Buttons.NextPage.Visible = False
                    Navigator.Buttons.Last.Visible = False
                    Navigator.Buttons.Insert.Hint = 'Inserta un nuevo Registro'
                    Navigator.Buttons.Insert.Visible = True
                    Navigator.Buttons.Delete.Hint = 'Borra el registro Activo'
                    Navigator.Buttons.Delete.Visible = True
                    Navigator.Buttons.Edit.Enabled = False
                    Navigator.Buttons.Edit.Visible = False
                    Navigator.Buttons.Post.Hint = 'Guarda Datos introducidos'
                    Navigator.Buttons.Post.Visible = True
                    Navigator.Buttons.Cancel.Visible = True
                    Navigator.Buttons.SaveBookmark.Enabled = False
                    Navigator.Buttons.SaveBookmark.Visible = False
                    Navigator.Buttons.GotoBookmark.Enabled = False
                    Navigator.Buttons.GotoBookmark.Visible = False
                    Navigator.Visible = True
                    DataController.DataSource = dmEmpresas.dsBancos
                    DataController.Options = [dcoCaseInsensitive, dcoAssignGroupingValues, dcoAssignMasterDetailKeys, dcoSaveExpanding]
                    OptionsBehavior.AlwaysShowEditor = True
                    OptionsBehavior.GoToNextCellOnEnter = True
                    OptionsBehavior.IncSearch = True
                    OptionsCustomize.ColumnHiding = True
                    OptionsData.Appending = True
                    OptionsView.GroupByBox = False
                    OptionsView.Indicator = True
                    object tvBancosNOMBRE_EMPBAN: TcxGridDBColumn
                      Caption = 'Nombre cuenta'
                      DataBinding.FieldName = 'NOMBRE_EMPBAN'
                      Width = 160
                    end
                    object tvBancosIBAN_EMPBAN: TcxGridDBColumn
                      Caption = 'IBAN'
                      DataBinding.FieldName = 'IBAN_EMPBAN'
                      Width = 210
                    end
                    object tvBancosNOMBRE_BAN: TcxGridDBColumn
                      Caption = 'Banco'
                      DataBinding.FieldName = 'NOMBRE_BAN_VIEW_EMPBAN'
                      Options.Editing = False
                      Width = 170
                    end
                    object tvBancosESDEFECTO_COBRO_EMPBAN: TcxGridDBColumn
                      Caption = 'Def. Cobro'
                      DataBinding.FieldName = 'ESDEFECTO_COBRO_EMPBAN'
                      Width = 70
                    end
                    object tvBancosESDEFECTO_PAGO_EMPBAN: TcxGridDBColumn
                      Caption = 'Def. Pago'
                      DataBinding.FieldName = 'ESDEFECTO_PAGO_EMPBAN'
                      Width = 70
                    end
                    object tvBancosESACTIVO_EMPBAN: TcxGridDBColumn
                      Caption = 'Activo'
                      DataBinding.FieldName = 'ESACTIVO_EMPBAN'
                      Width = 55
                    end
                  end
                  object lvBancos: TcxGridLevel
                    GridView = tvBancos
                  end
                end
              end
            end
            object tsPieTicketCaja: TcxTabSheet
              Caption = '&5_Pie Ticket Caja'
              ImageIndex = 5
              DesignSize = (
                937
                427)
              object lblPieTicketCaja1: TcxLabel
                Left = 31
                Top = 31
                Caption = 'L'#237'nea 1'
                TabOrder = 0
                Transparent = True
              end
              object txtTEXTO_PIE_TICKET_CAJA_1_EMP: TcxDBTextEdit
                Left = 120
                Top = 27
                Anchors = [akLeft, akTop, akRight]
                DataBinding.DataField = 'TEXTO_PIE_TICKET_CAJA_1_EMP'
                DataBinding.DataSource = dsTablaG
                Properties.MaxLength = 42
                TabOrder = 1
                Width = 568
              end
              object lblPieTicketCaja2: TcxLabel
                Left = 31
                Top = 69
                Caption = 'L'#237'nea 2'
                TabOrder = 2
                Transparent = True
              end
              object txtTEXTO_PIE_TICKET_CAJA_2_EMP: TcxDBTextEdit
                Left = 120
                Top = 65
                Anchors = [akLeft, akTop, akRight]
                DataBinding.DataField = 'TEXTO_PIE_TICKET_CAJA_2_EMP'
                DataBinding.DataSource = dsTablaG
                Properties.MaxLength = 42
                TabOrder = 3
                Width = 568
              end
              object lblPieTicketCaja3: TcxLabel
                Left = 31
                Top = 107
                Caption = 'L'#237'nea 3'
                TabOrder = 4
                Transparent = True
              end
              object txtTEXTO_PIE_TICKET_CAJA_3_EMP: TcxDBTextEdit
                Left = 120
                Top = 103
                Anchors = [akLeft, akTop, akRight]
                DataBinding.DataField = 'TEXTO_PIE_TICKET_CAJA_3_EMP'
                DataBinding.DataSource = dsTablaG
                Properties.MaxLength = 42
                TabOrder = 5
                Width = 568
              end
              object lblPieTicketCaja4: TcxLabel
                Left = 31
                Top = 145
                Caption = 'L'#237'nea 4'
                TabOrder = 6
                Transparent = True
              end
              object txtTEXTO_PIE_TICKET_CAJA_4_EMP: TcxDBTextEdit
                Left = 120
                Top = 141
                Anchors = [akLeft, akTop, akRight]
                DataBinding.DataField = 'TEXTO_PIE_TICKET_CAJA_4_EMP'
                DataBinding.DataSource = dsTablaG
                Properties.MaxLength = 42
                TabOrder = 7
                Width = 568
              end
            end
            object tsOtros: TcxTabSheet
              Caption = '&6_Otros'
              ImageIndex = 3
              object scrOtros: TcxScrollBox
                Left = 0
                Top = 0
                Width = 937
                Height = 427
                HorzScrollBar.Visible = False
                VertScrollBar.Tracking = True
                Align = alClient
                BorderStyle = cxcbsNone
                TabOrder = 0
                DesignSize = (
                  937
                  427)
                object pnlUserInstantBottom: TcxGroupBox
                  Left = 0
                  Top = 342
                  Anchors = [akLeft, akTop, akRight]
                  PanelStyle.Active = True
                  TabOrder = 4
                  Transparent = True
                  Height = 79
                  Width = 937
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
                    Width = 152
                  end
                  object lblUsuarioAlta: TcxLabel
                    Left = 17
                    Top = 6
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
                    Top = 6
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
                    Width = 192
                  end
                  object cxdbtxtdtINSTANTEALTA: TcxDBTextEdit
                    Left = 593
                    Top = 37
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    DataBinding.DataField = 'INSTANTE_MODIF'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    TabOrder = 7
                    Width = 188
                  end
                  object lblInstanteModif: TcxLabel
                    Left = 593
                    Top = 6
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    Caption = 'Instante Modificaci'#243'n'
                    TabOrder = 5
                    Transparent = True
                  end
                  object cxdbtxtdtUSUARIOALTA1: TcxDBTextEdit
                    Left = 377
                    Top = 37
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    DataBinding.DataField = 'USUARIO_ALTA'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    TabOrder = 4
                    Width = 168
                  end
                  object lblUsuarioModif: TcxLabel
                    Left = 337
                    Top = 6
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    Caption = 'Usuario '#218'ltima Modificaci'#243'n'
                    TabOrder = 6
                    Transparent = True
                  end
                end
                object lblTextoLegal: TcxLabel
                  Left = 29
                  Top = 167
                  Caption = 'Texto legal en Borradores'
                  TabOrder = 2
                  Transparent = True
                end
                object cxdbmTEXTO_LEGAL_FACTURA_EMPRESA: TcxDBMemo
                  Left = 31
                  Top = 196
                  DataBinding.DataField = 'TEXTO_LEGAL_FACTURA_EMP'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 0
                  Height = 89
                  Width = 586
                end
                object lblOrden: TcxLabel
                  Left = 22
                  Top = 291
                  Caption = 'Orden en Listados'
                  TabOrder = 3
                  Transparent = True
                end
                object cxdbspndtORDEN_EMPRESA: TcxDBSpinEdit
                  Left = 183
                  Top = 288
                  DataBinding.DataField = 'ORDEN_EMP'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 1
                  Width = 86
                end
                object lblTextoLegal1: TcxLabel
                  Left = 31
                  Top = 18
                  Caption = 'Firma electr'#243'nica en Borradores'
                  TabOrder = 5
                  Transparent = True
                end
                object lblDBNumeroSerieCertificado: TcxDBLabel
                  Left = 207
                  Top = 47
                  DataBinding.DataField = 'CODIGO_CERTIFICADO_EMP'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 6
                  Transparent = True
                  Height = 21
                  Width = 410
                end
                object lblNumSerie: TcxLabel
                  Left = 60
                  Top = 47
                  Caption = 'N'#250'mero de Serie'
                  TabOrder = 7
                  Transparent = True
                end
                object lblTipoCertificado: TcxLabel
                  Left = 37
                  Top = 74
                  Caption = 'Tipo de Certificado'
                  TabOrder = 8
                  Transparent = True
                end
                object lblDBTipoCertificado: TcxDBLabel
                  Left = 207
                  Top = 74
                  DataBinding.DataField = 'TIPO_CERTIFICADO_EMP'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 9
                  Transparent = True
                  Height = 21
                  Width = 410
                end
                object lblTitular: TcxLabel
                  Left = 142
                  Top = 101
                  Caption = 'Titular'
                  TabOrder = 10
                  Transparent = True
                end
                object lblDBTitularCertificado: TcxDBLabel
                  Left = 207
                  Top = 101
                  DataBinding.DataField = 'TITULAR_CERTIFICADO_EMP'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 11
                  Transparent = True
                  Height = 21
                  Width = 410
                end
                object btnSeleccionarCer: TcxButton
                  Left = 290
                  Top = 17
                  Width = 327
                  Height = 23
                  Caption = '&Seleccionar certificado de Almac'#233'n'
                  TabOrder = 12
                  WordWrap = True
                  OnClick = btnSeleccionarCerClick
                end
                object lblFechaCaducidad: TcxLabel
                  Left = 60
                  Top = 130
                  Caption = 'FechaCaducidad'
                  TabOrder = 13
                  Transparent = True
                end
                object txtFECHACADUCIDAD: TcxDBTextEdit
                  Left = 207
                  Top = 128
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'FECHA_HASTA_CERTIFICADO_EMP'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 14
                  Width = 192
                end
                object lblFormatoDocumento: TcxLabel
                  Left = 640
                  Top = 167
                  Caption = 'Formato documentos'
                  TabOrder = 15
                  Transparent = True
                end
                object txtFORMATO_DOCUMENTO_EMP: TcxDBTextEdit
                  Left = 640
                  Top = 196
                  DataBinding.DataField = 'FORMATO_DOCUMENTO_EMP'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 16
                  Width = 250
                end
                object lblFormatoDocumentoAyuda: TcxLabel
                  Left = 640
                  Top = 229
                  Caption = 
                    'Tokens: Serie y NroDocumento. Ej.: Serie.NroDocumento o NroDocum' +
                    'ento.Serie. La coma no est'#225' permitida.'
                  Properties.WordWrap = True
                  TabOrder = 17
                  Transparent = True
                  Width = 242
                end
              end
            end
            object cxTabSheet1: TcxTabSheet
              Caption = '&8_Verifactu'
              ImageIndex = 7
              object lblNumeroInstalacionSif: TcxLabel
                Left = 37
                Top = 23
                Caption = 'N'#186' instalaci'#243'n SIF'
                TabOrder = 0
                Transparent = True
              end
              object txtNUMERO_INSTALACION_EMP: TcxDBTextEdit
                Left = 37
                Top = 47
                DataBinding.DataField = 'NUMERO_INSTALACION_EMP'
                DataBinding.DataSource = dsTablaG
                ParentFont = False
                Properties.ReadOnly = True
                Style.Font.Charset = ANSI_CHARSET
                Style.Font.Color = clWindowText
                Style.Font.Height = -15
                Style.Font.Name = 'Source Sans 3'
                Style.Font.Style = []
                Style.IsFontAssigned = True
                TabOrder = 1
                Width = 372
              end
              object lblVersionInstalacionSif: TcxLabel
                Left = 37
                Top = 79
                Caption = 'Versi'#243'n SIF'
                TabOrder = 2
                Transparent = True
              end
              object txtVERSION_INSTALACION_EMP: TcxDBTextEdit
                Left = 37
                Top = 102
                DataBinding.DataField = 'VERSION_INSTALACION_EMP'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 3
                Width = 196
              end
              object btnGenerarInstalacionSif: TcxButton
                Left = 37
                Top = 145
                Width = 245
                Height = 28
                Caption = 'Generar / actualizar n'#250'mero SIF'
                TabOrder = 4
                WordWrap = True
                OnClick = btnGenerarInstalacionSifClick
              end
            end
          end
        end
        object spltFicha: TcxSplitter
          Left = 0
          Top = 178
          Width = 941
          Height = 10
          HotZoneClassName = 'TcxMediaPlayer9Style'
          AlignSplitter = salTop
          Control = pnlFichaDetail
        end
        object pnlFichaCab: TPanel
          Left = 0
          Top = 0
          Width = 941
          Height = 178
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          DesignSize = (
            941
            178)
          object cxgrpbxFiscalidad: TcxGroupBox
            AlignWithMargins = True
            Left = 9
            Top = 5
            TabStop = True
            Anchors = [akLeft, akTop, akRight, akBottom]
            TabOrder = 0
            Transparent = True
            Height = 166
            Width = 896
            object lblCodigo: TcxLabel
              Left = 24
              Top = 17
              Caption = 'C'#243'digo'
              TabOrder = 0
              Transparent = True
            end
            object txtCODIGO_EMPRESA: TcxDBTextEdit
              Left = 102
              Top = 15
              DataBinding.DataField = 'CODIGO_EMP_EMP'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = False
              TabOrder = 1
              Width = 126
            end
            object lblNif: TcxLabel
                  Left = 300
              Top = 17
              Caption = 'Nif'
              TabOrder = 8
              Transparent = True
            end
            object txtNIF_EMPRESA: TcxDBTextEdit
              Left = 352
              Top = 15
              DataBinding.DataField = 'NIF_EMP'
              DataBinding.DataSource = dsTablaG
              TabOrder = 2
              Width = 161
            end
            object lblNombre: TcxLabel
              Left = 24
              Top = 59
              Caption = 'Raz'#243'n Social'
              TabOrder = 9
              Transparent = True
            end
            object txtRAZONSOCIAL_EMPRESA: TcxDBTextEdit
              Left = 146
              Top = 55
              DataBinding.DataField = 'RAZON_SOCIAL_EMP'
              DataBinding.DataSource = dsTablaG
              TabOrder = 3
              Width = 367
            end
            object chkActivo: TcxDBCheckBox
              Left = 24
              Top = 88
              Caption = 'Activo'
              DataBinding.DataField = 'ESACTIVO_EMP'
              DataBinding.DataSource = dsTablaG
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Style.TransparentBorder = False
              TabOrder = 5
              Transparent = True
            end
            object chkAplicaRetenciones: TcxDBCheckBox
              Left = 24
              Top = 122
              Width = 150
              Height = 36
              Caption = 'Retiene IRPF'
              Properties.MultiLine = True
              DataBinding.DataField = 'ESRETENCIONES_EMP'
              DataBinding.DataSource = dsTablaG
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Properties.OnChange = chkAplicaRetencionesPropertiesChange
              Style.TransparentBorder = False
              TabOrder = 6
              Transparent = True
            end
            object lblCanalIVA: TcxLabel
              Left = 197
              Top = 93
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              Caption = 'Canal de IVA'
              Properties.Alignment.Horz = taRightJustify
              TabOrder = 10
              Transparent = True
              AnchorX = 279
            end
            object cbbZonaIVA: TcxDBLookupComboBox
              Left = 180
              Top = 122
              DataBinding.DataField = 'GRUPO_ZONA_IVA_EMP'
              DataBinding.DataSource = dsTablaG
              Properties.KeyFieldNames = 'IVA_IVAGRP'
              Properties.ListColumns = <
                item
                  FieldName = 'DESCRIPCION_IVA_IVAGRP'
                end>
              Properties.ListOptions.ShowHeader = False
              Properties.ValidateOnEnter = False
              TabOrder = 4
              Width = 333
            end
            object chkESTOKENS_CALENDARIO_NATURAL_EMP: TcxDBCheckBox
              Left = 528
              Top = 128
              Caption = 'Hacer coincidir calendario natural con tokens'
              DataBinding.DataField = 'ESTOKENS_CALENDARIO_NATURAL_EMP'
              DataBinding.DataSource = dsTablaG
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Style.TransparentBorder = False
              TabOrder = 7
              Transparent = True
            end
          end
        end
      end
      inherited tsPerfil: TcxTabSheet
        ExplicitLeft = 2
        ExplicitWidth = 941
        ExplicitHeight = 645
        inherited pnlPerfilTop: TPanel
          Width = 941
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 941
          inherited edtPerfilBusq: TcxTextEdit
            ExplicitHeight = 26
          end
        end
        inherited pnlPerfilDetail: TPanel
          Width = 941
          Height = 588
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 941
          ExplicitHeight = 588
          inherited cxgrdPerfil: TcxGrid
            Width = 941
            Height = 588
            ExplicitWidth = 941
            ExplicitHeight = 588
          end
        end
      end
    end
    inherited pnlTopPage: TPanel
      Width = 945
      TabOrder = 0
      StyleElements = [seFont, seClient, seBorder]
      ExplicitWidth = 945
      inherited pnlTopGrid: TPanel
        Width = 945
        StyleElements = [seFont, seClient, seBorder]
        ExplicitWidth = 945
        inherited edtBusqGlobal: TcxTextEdit
          ExplicitHeight = 26
        end
        inherited nvNavegador: TcxDBNavigator
          Width = 240
          ExplicitWidth = 240
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
    Left = 945
    Height = 715
    TabOrder = 1
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 945
    ExplicitHeight = 715
    inherited pButtonGen: TPanel
      Top = 517
      TabOrder = 2
      StyleElements = [seFont, seClient, seBorder]
      ExplicitTop = 517
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
    object btnNuevaEmpresa: TcxButton
      Left = 1
      Top = 154
      Width = 138
      Height = 25
      Caption = '&Nueva Empresa'
      TabOrder = 1
      OnClick = btnNuevaEmpresaClick
    end
  end
  inherited Localizer1: TcxLocalizer
    Left = 808
    Top = 400
  end
  object ActionListEmpresas: TActionList [4]
    Left = 808
    Top = 312
    object actClientes: TAction
      Caption = 'Clientes'
      ShortCut = 16459
      OnExecute = actClientesExecute
    end
    object actArticulos: TAction
      Caption = 'actArticulos'
      ShortCut = 16466
      OnExecute = actArticulosExecute
    end
    object actFacturas: TAction
      Caption = 'actBorradores'
      ShortCut = 49222
      OnExecute = actFacturasExecute
    end
  end
  inherited dsTablaG: TDataSource
    DataSet = dmEmpresas.unqryTablaG
    Left = 628
    Top = 535
  end
  inherited saveDialog: TdxSaveFileDialog
    Left = 792
    Top = 496
  end
end
