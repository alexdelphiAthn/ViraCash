inherited frmMtoComprasSesiones: TfrmMtoComprasSesiones
  Caption = 'Crear art'#237'culos y un pedido o un albar'#225'n'
  ClientHeight = 783
  ClientWidth = 1240
  Position = poDesigned
  OnDestroy = FormDestroy
  TextHeight = 18
  inherited pButtonPage: TPanel
    Width = 1100
    Height = 783
    inherited pcPantalla: TcxPageControl
      Width = 1100
      Height = 743
      ClientRectBottom = 739
      ClientRectRight = 1096
      inherited tsLista: TcxTabSheet
        Caption = '&Lista'
        ExplicitWidth = 943
        ExplicitHeight = 485
        inherited cxGrdPrincipal: TcxGrid
          Width = 1092
          Height = 710
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            object dbcSerieSes: TcxGridDBColumn
              Caption = 'Serie'
              DataBinding.FieldName = 'SERIE_SES'
              Width = 60
            end
            object dbcNumeroSes: TcxGridDBColumn
              Caption = 'N'#250'mero'
              DataBinding.FieldName = 'NUMERO_SES'
              Width = 80
            end
            object dbcFechaSes: TcxGridDBColumn
              Caption = 'Fecha'
              DataBinding.FieldName = 'FECHA_SES'
              Width = 100
            end
            object dbcTemporadaSes: TcxGridDBColumn
              Caption = 'Temporada'
              DataBinding.FieldName = 'TEMPORADA_SES'
              Width = 120
            end
            object dbcFechaEfectoStockSes: TcxGridDBColumn
              Caption = 'Fecha y hora stock'
              DataBinding.FieldName = 'FECHA_EFECTO_STOCK_SES'
              PropertiesClassName = 'TcxDateEditProperties'
              Properties.DisplayFormat = 'dd/mm/yyyy hh:nn:ss'
              Properties.Kind = ckDateTime
              Width = 145
            end
            object dbcFechaTopeRecepcionSes: TcxGridDBColumn
              Caption = 'F.tope recep.'
              DataBinding.FieldName = 'FECHA_TOPE_RECEPCION_SES'
              Width = 110
            end
            object dbcTotalPrendasSes: TcxGridDBColumn
              Caption = 'Prendas'
              DataBinding.FieldName = 'TOTAL_PRENDAS_SES'
              Width = 90
            end
            object dbcTotalLineasSes: TcxGridDBColumn
              Caption = 'Neto lineas'
              DataBinding.FieldName = 'TOTAL_LINEAS_SES'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 110
            end
            object dbcTotalDocumentoSes: TcxGridDBColumn
              Caption = 'Total doc.'
              DataBinding.FieldName = 'TOTAL_LIQUIDO_SES'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 110
            end
            object dbcCantidadPedidaSes: TcxGridDBColumn
              Caption = 'Pedidas'
              DataBinding.FieldName = 'CANTIDAD_PEDIDA_SES'
              Width = 90
            end
            object dbcCantidadRecibidaSes: TcxGridDBColumn
              Caption = 'Recibidas'
              DataBinding.FieldName = 'CANTIDAD_RECIBIDA_SES'
              Width = 90
            end
            object dbcCantidadPendienteSes: TcxGridDBColumn
              Caption = 'Pte. recibir'
              DataBinding.FieldName = 'CANTIDAD_PENDIENTE_RECEPCION_SES'
              Width = 95
            end
            object dbcEstadoSes: TcxGridDBColumn
              Caption = 'Estado'
              DataBinding.FieldName = 'ESTADO_SES'
              Width = 80
            end
            object dbcCodigoEmpSes: TcxGridDBColumn
              Caption = 'Empresa'
              DataBinding.FieldName = 'CODIGO_EMP_SES'
              Width = 80
            end
            object dbcCodigoPrvSes: TcxGridDBColumn
              Caption = 'Proveedor'
              DataBinding.FieldName = 'CODIGO_PRV_SES'
              Width = 100
            end
            object dbcRazonSocialPrvSes: TcxGridDBColumn
              Caption = 'Raz'#243'n social'
              DataBinding.FieldName = 'RAZON_SOCIAL_PRV_SES'
              Width = 200
            end
            object dbcNombrePrvSes: TcxGridDBColumn
              Caption = 'Nombre'
              DataBinding.FieldName = 'NOMBRE_PRV_SES'
              Width = 160
            end
            object dbcCodigoTarSes: TcxGridDBColumn
              Caption = 'Tarifa'
              DataBinding.FieldName = 'CODIGO_TAR_SES'
              Width = 90
            end
            object dbcUsuarioAltaSes: TcxGridDBColumn
              Caption = 'Usuario'
              DataBinding.FieldName = 'USUARIO_ALTA'
              Width = 100
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        Caption = '&Ficha'
        ExplicitWidth = 943
        ExplicitHeight = 485
        object pnlBottFich: TPanel
          Left = 0
          Top = 265
          Width = 1092
          Height = 445
          Align = alClient
          TabOrder = 0
          ExplicitTop = 305
          ExplicitHeight = 405
          object cxPageControl2: TcxPageControl
            Left = 1
            Top = 1
            Width = 1090
            Height = 443
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = cxTabSheet1
            Properties.CustomButtons.Buttons = <>
            ExplicitHeight = 403
            ClientRectBottom = 439
            ClientRectLeft = 4
            ClientRectRight = 1086
            ClientRectTop = 29
            object cxTabSheet1: TcxTabSheet
              Caption = '&1. L'#237'neas de Art'#237'culos'
              ImageIndex = 0
              object cxgrdLineas: TcxGrid
                Left = 0
                Top = 36
                Width = 1082
                Height = 374
                Align = alClient
                TabOrder = 0
                OnEnter = cxgrdLineasEnter
                ExplicitHeight = 334
                object tvLineas: TcxGridDBTableView
                  Navigator.Buttons.ConfirmDelete = True
                  Navigator.Buttons.PriorPage.Visible = False
                  Navigator.Buttons.NextPage.Visible = False
                  Navigator.Buttons.Append.Visible = False
                  Navigator.Buttons.Edit.Visible = False
                  Navigator.Buttons.SaveBookmark.Visible = False
                  Navigator.Buttons.GotoBookmark.Visible = False
                  Navigator.Buttons.Filter.Visible = False
                  Navigator.Visible = True
                  OnCustomDrawCell = tvLineasCustomDrawCell
                  OnEditing = tvLineasEditing
                  OnEditKeyDown = tvLineasEditKeyDown
                  OnFocusedRecordChanged = tvLineasFocusedRecordChanged
                  OnInitEdit = tvLineasInitEdit
                  OptionsBehavior.FocusCellOnTab = True
                  OptionsBehavior.GoToNextCellOnEnter = True
                  OptionsData.Appending = True
                  OptionsView.GroupByBox = False
                  object dbcLinFamilia: TcxGridDBColumn
                    Caption = 'Familia (F3)'
                    DataBinding.FieldName = 'CODIGO_FAM_SESLIN'
                    PropertiesClassName = 'TcxTextEditProperties'
                    Properties.CharCase = ecUpperCase
                    Properties.OnEditValueChanged = dbcLinFamiliaPropertiesEditValueChanged
                    Width = 110
                  end
                  object dbcLinCodArt: TcxGridDBColumn
                    Caption = 'C'#243'd. art'#237'culo'
                    DataBinding.FieldName = 'CODIGO_ART_TENTATIVO_SESLIN'
                    PropertiesClassName = 'TcxTextEditProperties'
                    Properties.CharCase = ecUpperCase
                    Properties.OnValidate = dbcLinCodArtPropertiesValidate
                    Width = 130
                  end
                  object dbcLinRefPrv: TcxGridDBColumn
                    Caption = 'Modelo prov.'
                    DataBinding.FieldName = 'REF_PRV_SESLIN'
                    PropertiesClassName = 'TcxTextEditProperties'
                    Properties.OnValidate = dbcLinRefPrvPropertiesValidate
                    Width = 130
                  end
                  object dbcLinDescripcion: TcxGridDBColumn
                    Caption = 'Descripci'#243'n'
                    DataBinding.FieldName = 'DESCRIPCION_SESLIN'
                    Width = 341
                  end
                  object dbcLinTipoIva: TcxGridDBColumn
                    Caption = 'Tipo IVA'
                    DataBinding.FieldName = 'TIPO_IVA_SESLIN'
                    PropertiesClassName = 'TcxComboBoxProperties'
                    Properties.DropDownListStyle = lsFixedList
                    Properties.Items.Strings = (
                      'N'
                      'R'
                      'S'
                      'E')
                    Visible = False
                    Width = 72
                  end
                  object dbcLinColor: TcxGridDBColumn
                    Caption = 'Color'
                    DataBinding.FieldName = 'COLOR_TEXTO_SESLIN'
                    PropertiesClassName = 'TcxComboBoxProperties'
                    Width = 140
                  end
                  object dbcLinColorBasico: TcxGridDBColumn
                    Caption = 'C. b'#225'sico'
                    DataBinding.FieldName = 'CODIGO_ATB_COLOR_SESLIN'
                    PropertiesClassName = 'TcxComboBoxProperties'
                    Properties.OnValidate = dbcLinColorBasicoPropertiesValidate
                    Width = 170
                  end
                  object dbcLinPestana: TcxGridDBColumn
                    Caption = 'Pesta'#241'a'
                    DataBinding.FieldName = 'PESTANA_TEXTO_SESLIN'
                    PropertiesClassName = 'TcxComboBoxProperties'
                    Visible = False
                    VisibleForCustomization = False
                    Width = 80
                  end
                  object dbcLinPrecioCompra: TcxGridDBColumn
                    Caption = 'Pr. compra s/IVA'
                    DataBinding.FieldName = 'PRECIO_COMPRA_SESLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.OnValidate = dbcLinPrecioCompraPropertiesValidate
                    Width = 136
                  end
                  object dbcLinDescuento: TcxGridDBColumn
                    Caption = 'Dto. %'
                    DataBinding.FieldName = 'PORCENTAJE_DTO_SESLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.MinValue = 0.000000000000000000
                    Properties.MaxValue = 100.000000000000000000
                    Properties.DisplayFormat = '0.00 "%"'
                    Width = 75
                  end
                  object dbcLinPrecioVenta: TcxGridDBColumn
                    Caption = 'Pr. venta'
                    DataBinding.FieldName = 'PRECIO_VENTA_SESLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Width = 90
                  end
                  object dbcLinVariacion: TcxGridDBColumn
                    Caption = 'Variación'
                    DataBinding.FieldName = 'CODIGO_VAR_SESLIN'
                    PropertiesClassName = 'TcxImageComboBoxProperties'
                    Properties.Items = <>
                    Properties.OnValidate = ValidarVariacionLinea
                    Width = 150
                  end
                  object dbcLinTallas: TcxGridDBColumn
                    Caption = 'Sistema tallas'
                    DataBinding.FieldName = 'ID_AC_PIVOT_SESLIN'
                    PropertiesClassName = 'TcxLookupComboBoxProperties'
                    Properties.ListColumns = <>
                    Width = 170
                  end
                  object dbcLinTotalTallas: TcxGridDBColumn
                    Caption = 'Total tallas'
                    DataBinding.FieldName = 'TOTAL_UNIDADES_SESLIN'
                    PropertiesClassName = 'TcxSpinEditProperties'
                    Properties.Alignment.Horz = taRightJustify
                    HeaderAlignmentHorz = taRightJustify
                    Options.Editing = False
                    Width = 100
                  end
                  object dbcLinImporteTotal: TcxGridDBColumn
                    Caption = 'Importe s/IVA'
                    DataBinding.FieldName = 'TOTAL_LINEA_SESLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.Alignment.Horz = taRightJustify
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    HeaderAlignmentHorz = taRightJustify
                    Options.Editing = False
                    Width = 110
                  end
                  object dbcLinNumero: TcxGridDBColumn
                    Caption = 'L'#237'nea'
                    DataBinding.FieldName = 'LINEA_SESLIN'
                    PropertiesClassName = 'TcxSpinEditProperties'
                    Properties.Increment = 10.00000000000000000
                    Properties.MinValue = 1.00000000000000000
                    Width = 70
                  end
                  object dbcLinArtReusar: TcxGridDBColumn
                    DataBinding.FieldName = 'CODIGO_ART_REUSAR_SESLIN'
                    Visible = False
                    VisibleForCustomization = False
                  end
                end
                object glLineas: TcxGridLevel
                  GridView = tvLineas
                end
              end
              object pnlLineasTop: TPanel
                Left = 0
                Top = 0
                Width = 1082
                Height = 36
                Align = alTop
                BevelOuter = bvNone
                TabOrder = 1
                object btnAddLinea: TcxButton
                  Left = 4
                  Top = 4
                  Width = 120
                  Height = 28
                  Caption = '+ A'#241'adir l'#237'nea'
                  TabOrder = 0
                  OnClick = btnAddLineaClick
                end
                object btnDelLinea: TcxButton
                  Left = 130
                  Top = 5
                  Width = 112
                  Height = 28
                  Caption = '- Borrar l'#237'nea'
                  TabOrder = 1
                  OnClick = btnDelLineaClick
                end
                object btnNuevoColor: TcxButton
                  Left = 248
                  Top = 5
                  Width = 120
                  Height = 28
                  Caption = 'Otro color'
                  Colors.Default = 14346982
                  Colors.Normal = 14346982
                  LookAndFeel.Kind = lfFlat
                  LookAndFeel.NativeStyle = False
                  TabOrder = 2
                  OnClick = btnNuevoColorClick
                end
                object btnPreciosTalla: TcxButton
                  Left = 374
                  Top = 5
                  Width = 96
                  Height = 28
                  Hint = 'Coste y PVP de cada talla de la l'#237'nea (F1)'
                  Caption = 'Precio talla F1'
                  Colors.Default = 14346982
                  Colors.Normal = 14346982
                  LookAndFeel.Kind = lfFlat
                  LookAndFeel.NativeStyle = False
                  ParentShowHint = False
                  ShowHint = True
                  TabOrder = 3
                  OnClick = btnPreciosTallaClick
                end
                object btnFoto: TcxButton
                  Left = 476
                  Top = 5
                  Width = 90
                  Height = 28
                  Caption = '+ Foto'
                  LookAndFeel.Kind = lfFlat
                  LookAndFeel.NativeStyle = False
                  TabOrder = 4
                end
                object btnArbolFamilias: TcxButton
                  Left = 572
                  Top = 5
                  Width = 150
                  Height = 28
                  Caption = #193'rbol familias (F3)'
                  TabOrder = 5
                  OnClick = btnArbolFamiliasClick
                end
                object btnDescargarFotos: TcxButton
                  Left = 728
                  Top = 5
                  Width = 100
                  Height = 28
                  Caption = 'Bajar fotos'
                  LookAndFeel.Kind = lfFlat
                  LookAndFeel.NativeStyle = False
                  TabOrder = 6
                end
                object btnAplicarKit: TcxButton
                  Left = 834
                  Top = 5
                  Width = 130
                  Height = 28
                  Caption = 'Aplicar kit'
                  Colors.Default = 12579775
                  Colors.Normal = 12579775
                  LookAndFeel.Kind = lfFlat
                  LookAndFeel.NativeStyle = False
                  TabOrder = 7
                  OnClick = btnAplicarKitClick
                end
                object lblHint: TcxLabel
                  Left = 972
                  Top = 7
                  Caption = 'F1 = precio talla. F3 = familias. PVP se propone al teclear el coste.'
                  TabOrder = 8
                  Transparent = True
                end
              end
            end
            object tsTotales: TcxTabSheet
              Caption = '&2. Totales'
              ImageIndex = 3
              object pnlTotales: TcxScrollBox
                Left = 0
                Top = 0
                Width = 1082
                Height = 410
                Align = alClient
                BorderStyle = cxcbsNone
                HorzScrollBar.Margin = 12
                TabOrder = 0
                VertScrollBar.Margin = 12
                VertScrollBar.Tracking = True
                object lblTotalBasesSes: TcxLabel
                  Left = 16
                  Top = 18
                  AutoSize = False
                  Caption = 'Total base imponible'
                  Properties.Alignment.Horz = taRightJustify
                  Properties.Alignment.Vert = taVCenter
                  TabOrder = 0
                  Transparent = True
                  Height = 24
                  Width = 206
                  AnchorX = 222
                  AnchorY = 30
                end
                object curTotalesTOTAL_BASES_SES: TcxDBCurrencyEdit
                  Left = 230
                  Top = 18
                  DataBinding.DataField = 'TOTAL_BASES_SES'
                  DataBinding.DataSource = dsTablaG
                  Properties.DisplayFormat = '#,##0.00 '#8364
                  Properties.ReadOnly = True
                  TabOrder = 1
                  Width = 133
                end
                object lblTotalImpuestosSes: TcxLabel
                  Left = 16
                  Top = 50
                  AutoSize = False
                  Caption = 'Total impuestos'
                  Properties.Alignment.Horz = taRightJustify
                  Properties.Alignment.Vert = taVCenter
                  TabOrder = 2
                  Transparent = True
                  Height = 24
                  Width = 206
                  AnchorX = 222
                  AnchorY = 62
                end
                object curTotalesTOTAL_IMPUESTOS_SES: TcxDBCurrencyEdit
                  Left = 230
                  Top = 50
                  DataBinding.DataField = 'TOTAL_IMPUESTOS_SES'
                  DataBinding.DataSource = dsTablaG
                  Properties.DisplayFormat = '#,##0.00 '#8364
                  Properties.ReadOnly = True
                  TabOrder = 3
                  Width = 133
                end
                object lblPorcRetencionSes: TcxLabel
                  Left = 16
                  Top = 82
                  AutoSize = False
                  Caption = '% Retenci'#243'n'
                  Properties.Alignment.Horz = taRightJustify
                  Properties.Alignment.Vert = taVCenter
                  TabOrder = 4
                  Transparent = True
                  Height = 24
                  Width = 206
                  AnchorX = 222
                  AnchorY = 94
                end
                object spnTotalesPORCENTAJE_RETENCION_SES: TcxDBSpinEdit
                  Left = 230
                  Top = 82
                  DataBinding.DataField = 'PORCENTAJE_RETENCION_SES'
                  DataBinding.DataSource = dsTablaG
                  Properties.AssignedValues.MinValue = True
                  Properties.DisplayFormat = '0.00 %'
                  Properties.EditFormat = '0.00 %'
                  Properties.MaxValue = 100.00000000000000000
                  TabOrder = 5
                  Width = 133
                end
                object lblTotalRetencionSes: TcxLabel
                  Left = 16
                  Top = 114
                  AutoSize = False
                  Caption = 'Total retenci'#243'n'
                  Properties.Alignment.Horz = taRightJustify
                  Properties.Alignment.Vert = taVCenter
                  TabOrder = 6
                  Transparent = True
                  Height = 24
                  Width = 206
                  AnchorX = 222
                  AnchorY = 126
                end
                object curTotalesTOTAL_RETENCION_SES: TcxDBCurrencyEdit
                  Left = 230
                  Top = 114
                  DataBinding.DataField = 'TOTAL_RETENCION_SES'
                  DataBinding.DataSource = dsTablaG
                  Properties.DisplayFormat = '#,##0.00 '#8364
                  Properties.ReadOnly = True
                  TabOrder = 7
                  Width = 133
                end
                object lblTotalLiquidoSes: TcxLabel
                  Left = 16
                  Top = 146
                  AutoSize = False
                  Caption = 'Total a pagar'
                  Properties.Alignment.Horz = taRightJustify
                  Properties.Alignment.Vert = taVCenter
                  TabOrder = 8
                  Transparent = True
                  Height = 24
                  Width = 206
                  AnchorX = 222
                  AnchorY = 158
                end
                object curTotalesTOTAL_LIQUIDO_SES: TcxDBCurrencyEdit
                  Left = 230
                  Top = 146
                  DataBinding.DataField = 'TOTAL_LIQUIDO_SES'
                  DataBinding.DataSource = dsTablaG
                  Properties.DisplayFormat = '#,##0.00 '#8364
                  Properties.ReadOnly = True
                  Properties.UseThousandSeparator = True
                  TabOrder = 9
                  Width = 133
                end
                object lblTotalesFormaPagoSes: TcxLabel
                  Left = 16
                  Top = 178
                  AutoSize = False
                  Caption = 'Forma de Pago'
                  Properties.Alignment.Horz = taRightJustify
                  Properties.Alignment.Vert = taVCenter
                  TabOrder = 10
                  Transparent = True
                  Height = 24
                  Width = 206
                  AnchorX = 222
                  AnchorY = 190
                end
                object cbbTotalesFORMA_PAGO_SES: TcxDBLookupComboBox
                  Left = 230
                  Top = 178
                  DataBinding.DataField = 'FORMA_PAGO_SES'
                  DataBinding.DataSource = dsTablaG
                  Properties.DropDownSizeable = True
                  Properties.KeyFieldNames = 'CODIGO_FP_FP'
                  Properties.ListColumns = <
                    item
                      Caption = 'C'#243'digo'
                      MinWidth = 50
                      Width = 60
                      FieldName = 'CODIGO_FP_FP'
                    end
                    item
                      Caption = 'Descripci'#243'n'
                      MinWidth = 160
                      Width = 220
                      FieldName = 'DESCRIPCION_FORMA_PAGO_FP'
                    end>
                  Properties.ListOptions.CaseInsensitive = True
                  TabOrder = 11
                  Width = 60
                end
                object chkTotalesESIVA_RECARGO_COMPRAS_SES: TcxDBCheckBox
                  Left = 56
                  Top = 210
                  Caption = 'Recargo equivalencia compras'
                  DataBinding.DataField = 'ESIVA_RECARGO_COMPRAS_SES'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  Properties.ValueChecked = 'S'
                  Properties.ValueUnchecked = 'N'
                  Properties.OnChange = chkRecargoComprasPropertiesChange
                  Style.TransparentBorder = False
                  TabOrder = 12
                  Transparent = True
                end
                object lblDtoComercialSes: TcxLabel
                  Left = 16
                  Top = 240
                  AutoSize = False
                  Caption = 'Dto. comercial'
                  Properties.Alignment.Horz = taRightJustify
                  Properties.Alignment.Vert = taVCenter
                  TabOrder = 13
                  Transparent = True
                  Height = 24
                  Width = 162
                  AnchorX = 178
                  AnchorY = 252
                end
                object spnTotalesPORCENTAJE_DTO_COMERCIAL_SES: TcxDBSpinEdit
                  Left = 185
                  Top = 240
                  DataBinding.DataField = 'PORCENTAJE_DTO_COMERCIAL_SES'
                  DataBinding.DataSource = dsTablaG
                  Properties.AssignedValues.MinValue = True
                  Properties.DisplayFormat = '0.00 %'
                  Properties.EditFormat = '0.00 %'
                  Properties.MaxValue = 100.00000000000000000
                  TabOrder = 14
                  Width = 86
                end
                object curTotalesTOTAL_DTO_COMERCIAL_SES: TcxDBCurrencyEdit
                  Left = 272
                  Top = 240
                  DataBinding.DataField = 'TOTAL_DTO_COMERCIAL_SES'
                  DataBinding.DataSource = dsTablaG
                  Properties.DisplayFormat = '#,##0.00 '#8364
                  Properties.ReadOnly = True
                  TabOrder = 15
                  Width = 91
                end
                object lblDtoFinancieroSes: TcxLabel
                  Left = 16
                  Top = 270
                  AutoSize = False
                  Caption = 'Dto. financiero'
                  Properties.Alignment.Horz = taRightJustify
                  Properties.Alignment.Vert = taVCenter
                  TabOrder = 16
                  Transparent = True
                  Height = 24
                  Width = 162
                  AnchorX = 178
                  AnchorY = 282
                end
                object spnTotalesPORCENTAJE_DTO_FINANCIERO_SES: TcxDBSpinEdit
                  Left = 185
                  Top = 270
                  DataBinding.DataField = 'PORCENTAJE_DTO_FINANCIERO_SES'
                  DataBinding.DataSource = dsTablaG
                  Properties.AssignedValues.MinValue = True
                  Properties.DisplayFormat = '0.00 %'
                  Properties.EditFormat = '0.00 %'
                  Properties.MaxValue = 100.00000000000000000
                  TabOrder = 17
                  Width = 86
                end
                object curTotalesTOTAL_DTO_FINANCIERO_SES: TcxDBCurrencyEdit
                  Left = 272
                  Top = 270
                  DataBinding.DataField = 'TOTAL_DTO_FINANCIERO_SES'
                  DataBinding.DataSource = dsTablaG
                  Properties.DisplayFormat = '#,##0.00 '#8364
                  Properties.ReadOnly = True
                  TabOrder = 18
                  Width = 91
                end
                object grpDesgloseIvaSes: TGroupBox
                  Left = 384
                  Top = 10
                  Width = 525
                  Height = 280
                  Caption = 'Desglose IVA'
                  TabOrder = 19
                  object lblTotSesBase: TcxLabel
                    Left = 145
                    Top = 40
                    AutoSize = False
                    Caption = 'Base'
                    Properties.Alignment.Horz = taCenter
                    Properties.Alignment.Vert = taVCenter
                    TabOrder = 0
                    Transparent = True
                    Height = 24
                    Width = 92
                    AnchorX = 191
                    AnchorY = 52
                  end
                  object lblTotSesPorIva: TcxLabel
                    Left = 238
                    Top = 40
                    AutoSize = False
                    Caption = '% IVA'
                    Properties.Alignment.Horz = taCenter
                    Properties.Alignment.Vert = taVCenter
                    TabOrder = 1
                    Transparent = True
                    Height = 24
                    Width = 55
                    AnchorX = 266
                    AnchorY = 52
                  end
                  object lblTotSesTotalIva: TcxLabel
                    Left = 296
                    Top = 40
                    AutoSize = False
                    Caption = 'Total IVA'
                    Properties.Alignment.Horz = taCenter
                    Properties.Alignment.Vert = taVCenter
                    TabOrder = 2
                    Transparent = True
                    Height = 24
                    Width = 86
                    AnchorX = 339
                    AnchorY = 52
                  end
                  object lblTotSesPorRe: TcxLabel
                    Left = 388
                    Top = 40
                    AutoSize = False
                    Caption = '% R.E.'
                    Properties.Alignment.Horz = taCenter
                    Properties.Alignment.Vert = taVCenter
                    TabOrder = 3
                    Transparent = True
                    Height = 24
                    Width = 53
                    AnchorX = 415
                    AnchorY = 52
                  end
                  object lblTotSesTotalRe: TcxLabel
                    Left = 442
                    Top = 40
                    AutoSize = False
                    Caption = 'Total R.E.'
                    Properties.Alignment.Horz = taCenter
                    Properties.Alignment.Vert = taVCenter
                    TabOrder = 4
                    Transparent = True
                    Height = 24
                    Width = 75
                    AnchorX = 480
                    AnchorY = 52
                  end
                  object lblTotSesIVAN: TcxLabel
                    Left = 20
                    Top = 80
                    AutoSize = False
                    Caption = 'Normal'
                    Properties.Alignment.Vert = taVCenter
                    TabOrder = 5
                    Transparent = True
                    Height = 24
                    Width = 120
                    AnchorY = 92
                  end
                  object lblTotSesIVAR: TcxLabel
                    Left = 20
                    Top = 128
                    AutoSize = False
                    Caption = 'Reducido'
                    Properties.Alignment.Vert = taVCenter
                    TabOrder = 6
                    Transparent = True
                    Height = 24
                    Width = 120
                    AnchorY = 140
                  end
                  object lblTotSesIVAS: TcxLabel
                    Left = 20
                    Top = 176
                    AutoSize = False
                    Caption = 'S'#250'per reducido'
                    Properties.Alignment.Vert = taVCenter
                    TabOrder = 7
                    Transparent = True
                    Height = 24
                    Width = 120
                    AnchorY = 188
                  end
                  object lblTotSesIVAE: TcxLabel
                    Left = 20
                    Top = 224
                    AutoSize = False
                    Caption = 'Exento'
                    Properties.Alignment.Vert = taVCenter
                    TabOrder = 8
                    Transparent = True
                    Height = 24
                    Width = 120
                    AnchorY = 236
                  end
                  object curTotSesTOTAL_BASEI_IVAN_SES: TcxDBCurrencyEdit
                    Left = 145
                    Top = 80
                    DataBinding.DataField = 'TOTAL_BASEI_IVAN_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 9
                    Width = 92
                  end
                  object curTotSesTOTAL_BASEI_IVAR_SES: TcxDBCurrencyEdit
                    Left = 145
                    Top = 128
                    DataBinding.DataField = 'TOTAL_BASEI_IVAR_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 10
                    Width = 92
                  end
                  object curTotSesTOTAL_BASEI_IVAS_SES: TcxDBCurrencyEdit
                    Left = 145
                    Top = 176
                    DataBinding.DataField = 'TOTAL_BASEI_IVAS_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 11
                    Width = 92
                  end
                  object curTotSesTOTAL_BASEI_IVAE_SES: TcxDBCurrencyEdit
                    Left = 145
                    Top = 224
                    DataBinding.DataField = 'TOTAL_BASEI_IVAE_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 12
                    Width = 92
                  end
                  object spnTotSesPORCENTAJE_IVAN_SES: TcxDBSpinEdit
                    Left = 238
                    Top = 80
                    DataBinding.DataField = 'PORCENTAJE_IVAN_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '0 %'
                    Properties.EditFormat = '0 %'
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 13
                    Width = 55
                  end
                  object spnTotSesPORCENTAJE_IVAR_SES: TcxDBSpinEdit
                    Left = 238
                    Top = 128
                    DataBinding.DataField = 'PORCENTAJE_IVAR_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '0 %'
                    Properties.EditFormat = '0 %'
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 14
                    Width = 55
                  end
                  object spnTotSesPORCENTAJE_IVAS_SES: TcxDBSpinEdit
                    Left = 238
                    Top = 176
                    DataBinding.DataField = 'PORCENTAJE_IVAS_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '0 %'
                    Properties.EditFormat = '0 %'
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 15
                    Width = 55
                  end
                  object spnTotSesPORCENTAJE_IVAE_SES: TcxDBSpinEdit
                    Left = 238
                    Top = 224
                    DataBinding.DataField = 'PORCENTAJE_IVAE_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '0 %'
                    Properties.EditFormat = '0 %'
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 16
                    Width = 55
                  end
                  object curTotSesTOTAL_IVAN_SES: TcxDBCurrencyEdit
                    Left = 296
                    Top = 80
                    DataBinding.DataField = 'TOTAL_IVAN_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 17
                    Width = 86
                  end
                  object curTotSesTOTAL_IVAR_SES: TcxDBCurrencyEdit
                    Left = 296
                    Top = 128
                    DataBinding.DataField = 'TOTAL_IVAR_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 18
                    Width = 86
                  end
                  object curTotSesTOTAL_IVAS_SES: TcxDBCurrencyEdit
                    Left = 296
                    Top = 176
                    DataBinding.DataField = 'TOTAL_IVAS_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 19
                    Width = 86
                  end
                  object curTotSesTOTAL_IVAE_SES: TcxDBCurrencyEdit
                    Left = 296
                    Top = 224
                    DataBinding.DataField = 'TOTAL_IVAE_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 20
                    Width = 86
                  end
                  object spnTotSesPORCENTAJE_REN_SES: TcxDBSpinEdit
                    Left = 388
                    Top = 80
                    DataBinding.DataField = 'PORCENTAJE_REN_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '0.00 %'
                    Properties.EditFormat = '0.00 %'
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 21
                    Width = 53
                  end
                  object spnTotSesPORCENTAJE_RER_SES: TcxDBSpinEdit
                    Left = 388
                    Top = 128
                    DataBinding.DataField = 'PORCENTAJE_RER_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '0.00 %'
                    Properties.EditFormat = '0.00 %'
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 22
                    Width = 53
                  end
                  object spnTotSesPORCENTAJE_RES_SES: TcxDBSpinEdit
                    Left = 388
                    Top = 176
                    DataBinding.DataField = 'PORCENTAJE_RES_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '0.00 %'
                    Properties.EditFormat = '0.00 %'
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 23
                    Width = 53
                  end
                  object spnTotSesPORCENTAJE_REE_SES: TcxDBSpinEdit
                    Left = 388
                    Top = 224
                    DataBinding.DataField = 'PORCENTAJE_REE_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '0.00 %'
                    Properties.EditFormat = '0.00 %'
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 24
                    Width = 53
                  end
                  object curTotSesTOTAL_REN_SES: TcxDBCurrencyEdit
                    Left = 442
                    Top = 80
                    DataBinding.DataField = 'TOTAL_REN_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 25
                    Width = 75
                  end
                  object curTotSesTOTAL_RER_SES: TcxDBCurrencyEdit
                    Left = 442
                    Top = 128
                    DataBinding.DataField = 'TOTAL_RER_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 26
                    Width = 75
                  end
                  object curTotSesTOTAL_RES_SES: TcxDBCurrencyEdit
                    Left = 442
                    Top = 176
                    DataBinding.DataField = 'TOTAL_RES_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 27
                    Width = 75
                  end
                  object curTotSesTOTAL_REE_SES: TcxDBCurrencyEdit
                    Left = 442
                    Top = 224
                    DataBinding.DataField = 'TOTAL_REE_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 28
                    Width = 75
                  end
                end
              end
            end
            object tsDocumentos: TcxTabSheet
              Caption = '&3. Documentos creados'
              ImageIndex = 1
              object pnlDocsTop: TPanel
                Left = 0
                Top = 0
                Width = 1082
                Height = 40
                Align = alTop
                BevelOuter = bvNone
                TabOrder = 0
                object btnIrADoc: TcxButton
                  Left = 12
                  Top = 6
                  Width = 200
                  Height = 28
                  Caption = 'Ir a documento'
                  LookAndFeel.Kind = lfFlat
                  LookAndFeel.NativeStyle = False
                  TabOrder = 0
                end
                object lblDocsInfo: TcxLabel
                  Left = 224
                  Top = 10
                  Caption = 
                    'Pedidos y albaranes generados al materializar la sesi'#243'n. Doble c' +
                    'lick o el bot'#243'n lateral "Ir a Ped / Alb" navega al documento.'
                  TabOrder = 1
                  Transparent = True
                end
              end
              object cxgrdDocs: TcxGrid
                Left = 0
                Top = 40
                Width = 1082
                Height = 370
                Align = alClient
                TabOrder = 1
                ExplicitHeight = 330
                object tvDocs: TcxGridDBTableView
                  OptionsCustomize.ColumnHiding = True
                  OptionsData.Deleting = False
                  OptionsData.DeletingConfirmation = False
                  OptionsData.Editing = False
                  OptionsData.Inserting = False
                  OptionsView.GroupByBox = False
                  object dbcDocTipo: TcxGridDBColumn
                    Caption = 'Tipo'
                    DataBinding.FieldName = 'TIPO'
                    Width = 80
                  end
                  object dbcDocSerie: TcxGridDBColumn
                    Caption = 'Serie'
                    DataBinding.FieldName = 'SERIE'
                    Width = 80
                  end
                  object dbcDocNumero: TcxGridDBColumn
                    Caption = 'N'#250'mero'
                    DataBinding.FieldName = 'NUMERO'
                    Width = 120
                  end
                  object dbcDocAlmacen: TcxGridDBColumn
                    Caption = 'Almac'#233'n'
                    DataBinding.FieldName = 'ALMACEN'
                    Width = 140
                  end
                  object dbcDocInstante: TcxGridDBColumn
                    Caption = 'Fecha alta'
                    DataBinding.FieldName = 'INSTANTE'
                    Width = 150
                  end
                  object dbcDocUsuario: TcxGridDBColumn
                    Caption = 'Usuario'
                    DataBinding.FieldName = 'USUARIO'
                    Width = 120
                  end
                end
                object glDocs: TcxGridLevel
                  GridView = tvDocs
                end
              end
            end
            object tsProveedor: TcxTabSheet
              Caption = '&4. Proveedor'
              ImageIndex = 2
              object pnlProvIzq: TPanel
                Left = 0
                Top = 0
                Width = 560
                Height = 410
                Align = alLeft
                BevelOuter = bvNone
                TabOrder = 0
                object gbProvFicha: TcxGroupBox
                  Left = 0
                  Top = 0
                  Align = alClient
                  Caption = ' Datos del proveedor '
                  TabOrder = 0
                  Height = 410
                  Width = 560
                  object lblProvCodigo: TcxLabel
                    Left = 12
                    Top = 28
                    Caption = 'C'#243'digo'
                    TabOrder = 0
                    Transparent = True
                  end
                  object txtProvCodigo: TcxDBTextEdit
                    Left = 110
                    Top = 24
                    DataBinding.DataField = 'CODIGO_PRV_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 1
                    Width = 120
                  end
                  object lblProvNif: TcxLabel
                    Left = 292
                    Top = 28
                    Caption = 'NIF'
                    TabOrder = 2
                    Transparent = True
                  end
                  object txtProvNif: TcxDBTextEdit
                    Left = 392
                    Top = 24
                    DataBinding.DataField = 'NIF_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 3
                    Width = 152
                  end
                  object lblProvRazon: TcxLabel
                    Left = 12
                    Top = 56
                    Caption = 'Raz'#243'n social'
                    TabOrder = 4
                    Transparent = True
                  end
                  object txtProvRazon: TcxDBTextEdit
                    Left = 110
                    Top = 52
                    DataBinding.DataField = 'RAZON_SOCIAL_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 5
                    Width = 434
                  end
                  object lblProvNombre: TcxLabel
                    Left = 12
                    Top = 84
                    Caption = 'Nombre com.'
                    TabOrder = 6
                    Transparent = True
                  end
                  object txtProvNombre: TcxDBTextEdit
                    Left = 110
                    Top = 80
                    DataBinding.DataField = 'NOMBRE_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 7
                    Width = 434
                  end
                  object lblProvTelefono: TcxLabel
                    Left = 12
                    Top = 112
                    Caption = 'Tel'#233'fono'
                    TabOrder = 8
                    Transparent = True
                  end
                  object txtProvTelefono: TcxDBTextEdit
                    Left = 110
                    Top = 108
                    DataBinding.DataField = 'TELEFONO_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 9
                    Width = 168
                  end
                  object lblProvMovil: TcxLabel
                    Left = 292
                    Top = 112
                    Caption = 'M'#243'vil'
                    TabOrder = 10
                    Transparent = True
                  end
                  object txtProvMovil: TcxDBTextEdit
                    Left = 392
                    Top = 108
                    DataBinding.DataField = 'MOVIL_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 11
                    Width = 152
                  end
                  object lblProvEmail: TcxLabel
                    Left = 12
                    Top = 140
                    Caption = 'Email'
                    TabOrder = 12
                    Transparent = True
                  end
                  object txtProvEmail: TcxDBTextEdit
                    Left = 110
                    Top = 136
                    DataBinding.DataField = 'EMAIL_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 13
                    Width = 434
                  end
                  object lblProvDireccion: TcxLabel
                    Left = 12
                    Top = 168
                    Caption = 'Direcci'#243'n'
                    TabOrder = 14
                    Transparent = True
                  end
                  object txtProvDireccion: TcxDBTextEdit
                    Left = 110
                    Top = 164
                    DataBinding.DataField = 'DIRECCION1_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 15
                    Width = 434
                  end
                  object lblProvPoblacion: TcxLabel
                    Left = 12
                    Top = 196
                    Caption = 'Poblaci'#243'n'
                    TabOrder = 16
                    Transparent = True
                  end
                  object txtProvPoblacion: TcxDBTextEdit
                    Left = 110
                    Top = 192
                    DataBinding.DataField = 'POBLACION_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 17
                    Width = 168
                  end
                  object lblProvProvincia: TcxLabel
                    Left = 292
                    Top = 196
                    Caption = 'Provincia'
                    TabOrder = 18
                    Transparent = True
                  end
                  object txtProvProvincia: TcxDBTextEdit
                    Left = 392
                    Top = 192
                    DataBinding.DataField = 'PROVINCIA_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 19
                    Width = 152
                  end
                  object lblProvCPostal: TcxLabel
                    Left = 12
                    Top = 224
                    Caption = 'C. Postal'
                    TabOrder = 20
                    Transparent = True
                  end
                  object txtProvCPostal: TcxDBTextEdit
                    Left = 110
                    Top = 220
                    DataBinding.DataField = 'CODIGO_POSTAL_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 21
                    Width = 168
                  end
                  object lblProvPais: TcxLabel
                    Left = 292
                    Top = 224
                    Caption = 'Pa'#237's'
                    TabOrder = 22
                    Transparent = True
                  end
                  object txtProvPais: TcxDBTextEdit
                    Left = 392
                    Top = 220
                    DataBinding.DataField = 'PAIS_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 23
                    Width = 152
                  end
                  object lblProvContacto: TcxLabel
                    Left = 12
                    Top = 252
                    Caption = 'Contacto'
                    TabOrder = 24
                    Transparent = True
                  end
                  object txtProvContacto: TcxDBTextEdit
                    Left = 110
                    Top = 248
                    DataBinding.DataField = 'CONTACTO_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 25
                    Width = 168
                  end
                  object lblProvTelContacto: TcxLabel
                    Left = 292
                    Top = 252
                    Caption = 'Tel. contacto'
                    TabOrder = 26
                    Transparent = True
                  end
                  object txtProvTelContacto: TcxDBTextEdit
                    Left = 392
                    Top = 248
                    DataBinding.DataField = 'TELEFONO_CONTACTO_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 27
                    Width = 152
                  end
                  object lblProvMargen: TcxLabel
                    Left = 12
                    Top = 284
                    Caption = 'Coeficiente PVP %'
                    TabOrder = 28
                    Transparent = True
                  end
                  object txtProvMargen: TcxDBTextEdit
                    Left = 190
                    Top = 280
                    Hint = 'PVP = coste '#215' coeficiente / 100. Ej.: 120 % de 4,50 = 5,40.'
                    DataBinding.DataField = 'PORCENTAJE_MARGEN_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    ParentShowHint = False
                    Properties.ReadOnly = True
                    ShowHint = True
                    TabOrder = 29
                    Width = 90
                  end
                  object btnIrProveedor: TcxButton
                    Left = 110
                    Top = 316
                    Width = 200
                    Height = 28
                    Caption = 'Ir a proveedor (ficha)'
                    LookAndFeel.Kind = lfFlat
                    LookAndFeel.NativeStyle = False
                    TabOrder = 30
                  end
                end
              end
              object gbProvKits: TcxGroupBox
                Left = 560
                Top = 0
                Align = alClient
                Caption = ' Kits de cantidades por talla '
                TabOrder = 1
                Height = 410
                Width = 522
                object pnlProvKitsTop: TPanel
                  Left = 2
                  Top = 23
                  Width = 518
                  Height = 36
                  Align = alTop
                  BevelOuter = bvNone
                  TabOrder = 0
                  object btnAplicarKitProv: TcxButton
                    Left = 8
                    Top = 4
                    Width = 230
                    Height = 28
                    Caption = 'Aplicar kit a la l'#237'nea actual'
                    Colors.Default = 12579775
                    Colors.Normal = 12579775
                    LookAndFeel.Kind = lfFlat
                    LookAndFeel.NativeStyle = False
                    TabOrder = 0
                    OnClick = btnAplicarKitProvClick
                  end
                  object lblProvKitsHint: TcxLabel
                    Left = 246
                    Top = 9
                    Caption = 'Doble click tambi'#233'n aplica. Se definen en Proveedores.'
                    TabOrder = 1
                    Transparent = True
                  end
                end
                object cxgrdPrvKits: TcxGrid
                  Left = 2
                  Top = 59
                  Width = 308
                  Height = 349
                  Align = alClient
                  TabOrder = 1
                  ExplicitHeight = 309
                  object tvPrvKits: TcxGridDBTableView
                    OnDblClick = tvPrvKitsDblClick
                    OptionsData.Deleting = False
                    OptionsData.DeletingConfirmation = False
                    OptionsData.Editing = False
                    OptionsData.Inserting = False
                    OptionsView.GroupByBox = False
                    object dbcPrvKitCodigo: TcxGridDBColumn
                      Caption = 'Kit'
                      DataBinding.FieldName = 'CODIGO_PRVKIT'
                      Width = 90
                    end
                    object dbcPrvKitNombre: TcxGridDBColumn
                      Caption = 'Nombre'
                      DataBinding.FieldName = 'NOMBRE_PRVKIT'
                      Width = 130
                    end
                    object dbcPrvKitSistema: TcxGridDBColumn
                      Caption = 'Sistema tallas'
                      DataBinding.FieldName = 'NOMBRE_TALLAS_PRVKIT'
                      Width = 150
                    end
                  end
                  object glPrvKits: TcxGridLevel
                    GridView = tvPrvKits
                  end
                end
                object cxgrdPrvKitsDet: TcxGrid
                  Left = 310
                  Top = 59
                  Width = 210
                  Height = 349
                  Align = alRight
                  TabOrder = 2
                  ExplicitHeight = 309
                  object tvPrvKitsDet: TcxGridDBTableView
                    OptionsData.Deleting = False
                    OptionsData.DeletingConfirmation = False
                    OptionsData.Editing = False
                    OptionsData.Inserting = False
                    OptionsView.GroupByBox = False
                    object dbcPrvKitDetValor: TcxGridDBColumn
                      Caption = 'Talla'
                      DataBinding.FieldName = 'VALOR_DESTINO_PRVKITD'
                      Width = 80
                    end
                    object dbcPrvKitDetCantidad: TcxGridDBColumn
                      Caption = 'Cantidad'
                      DataBinding.FieldName = 'CANTIDAD_PRVKITD'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Properties.DisplayFormat = '#,##0.##'
                      Width = 80
                    end
                  end
                  object glPrvKitsDet: TcxGridLevel
                    GridView = tvPrvKitsDet
                  end
                end
              end
            end
            object tsFotosProvisionales: TcxTabSheet
              Caption = '&5. Fotos provisionales'
              ImageIndex = 4
              ExplicitLeft = 0
              ExplicitTop = 0
              ExplicitWidth = 0
              ExplicitHeight = 370
              object btnReintentarFotos: TcxButton
                Left = 0
                Top = 0
                Width = 1082
                Height = 30
                Align = alTop
                Caption = 'Reintentar migraci'#243'n de fotos'
                TabOrder = 1
                OnClick = btnReintentarFotosClick
              end
              object cxgrdFotosProvisionales: TcxGrid
                Left = 0
                Top = 30
                Width = 1082
                Height = 380
                Align = alClient
                TabOrder = 0
                ExplicitHeight = 340
                object tvFotosProvisionales: TcxGridDBTableView
                  OptionsBehavior.IncSearch = True
                  OptionsData.Deleting = False
                  OptionsData.DeletingConfirmation = False
                  OptionsData.Editing = False
                  OptionsData.Inserting = False
                  OptionsView.GroupByBox = False
                  object dbcFotoLinea: TcxGridDBColumn
                    Caption = 'L'#237'nea'
                    DataBinding.FieldName = 'LINEA_CSF'
                    Width = 65
                  end
                  object dbcFotoArticulo: TcxGridDBColumn
                    Caption = 'C'#243'd. art'#237'culo'
                    DataBinding.FieldName = 'CODIGO_ART_TENTATIVO_CSF'
                    Width = 125
                  end
                  object dbcFotoModeloProveedor: TcxGridDBColumn
                    Caption = 'Modelo prov.'
                    DataBinding.FieldName = 'REF_PRV_SESLIN'
                    Width = 120
                  end
                  object dbcFotoDescripcion: TcxGridDBColumn
                    Caption = 'Descripci'#243'n'
                    DataBinding.FieldName = 'DESCRIPCION_SESLIN'
                    Width = 230
                  end
                  object dbcFotoColor: TcxGridDBColumn
                    Caption = 'Color'
                    DataBinding.FieldName = 'COLOR_TEXTO_SESLIN'
                    Width = 110
                  end
                  object dbcFotoUnidad: TcxGridDBColumn
                    Caption = 'Asignada a'
                    DataBinding.FieldName = 'ASIGNACION_FOTO'
                    OnGetDisplayText = dbcFotoUnidadGetDisplayText
                    Width = 120
                  end
                  object dbcFotoFichero: TcxGridDBColumn
                    Caption = 'Fichero'
                    DataBinding.FieldName = 'NOMBRE_FOT_CSF'
                    Width = 170
                  end
                  object dbcFotoInstante: TcxGridDBColumn
                    Caption = 'Modificada'
                    DataBinding.FieldName = 'INSTANTE_MODIF'
                    Width = 130
                  end
                  object dbcFotoUsuario: TcxGridDBColumn
                    Caption = 'Usuario'
                    DataBinding.FieldName = 'USUARIO_MODIF'
                    Width = 100
                  end
                end
                object glFotosProvisionales: TcxGridLevel
                  GridView = tvFotosProvisionales
                end
              end
            end
          end
        end
        object splSplitterFicha: TcxSplitter
          Left = 0
          Top = 257
          Width = 1092
          Height = 8
          Cursor = crSizeNS
          Margins.Left = 4
          Margins.Top = 4
          Margins.Right = 4
          Margins.Bottom = 4
          HotZoneClassName = 'TcxMediaPlayer9Style'
          HotZone.SizePercent = 50
          AlignSplitter = salTop
          ExplicitTop = 297
          ExplicitWidth = 8
        end
        object cxPageControl1: TcxPageControl
          Left = 0
          Top = 0
          Width = 1092
          Height = 257
          Align = alTop
          TabOrder = 2
          Properties.ActivePage = cxTabSheet2
          Properties.CustomButtons.Buttons = <>
          OnChange = cxPageControl1Change
          ClientRectBottom = 253
          ClientRectLeft = 4
          ClientRectRight = 1088
          ClientRectTop = 29
          object cxTabSheet2: TcxTabSheet
            Caption = '&1. Datos Cabecera'
            ImageIndex = 0
            object gbCabecera: TcxGroupBox
              Left = 0
              Top = 0
              Align = alTop
              TabOrder = 0
              Height = 241
              Width = 1084
              object lblSerie: TcxLabel
                Left = 12
                Top = 20
                AutoSize = False
                Caption = 'Serie'
                Properties.Alignment.Vert = taVCenter
                TabOrder = 0
                Transparent = True
                Height = 24
                Width = 72
              end
              object cbbSerie: TcxDBComboBox
                Left = 92
                Top = 20
                DataBinding.DataField = 'SERIE_SES'
                DataBinding.DataSource = dsTablaG
                Properties.CharCase = ecUpperCase
                Properties.MaxLength = 12
                TabOrder = 1
                Width = 70
              end
              object lblNumero: TcxLabel
                Left = 176
                Top = 20
                AutoSize = False
                Caption = 'N'#250'mero'
                Properties.Alignment.Vert = taVCenter
                TabOrder = 2
                Transparent = True
                Height = 24
                Width = 64
              end
              object txtNumero: TcxDBTextEdit
                Left = 244
                Top = 20
                DataBinding.DataField = 'NUMERO_SES'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 3
                Width = 58
              end
              object lblFecha: TcxLabel
                Left = 316
                Top = 20
                AutoSize = False
                Caption = 'Fecha'
                Properties.Alignment.Vert = taVCenter
                TabOrder = 4
                Transparent = True
                Height = 24
                Width = 56
              end
              object dteFecha: TcxDBDateEdit
                Left = 380
                Top = 20
                DataBinding.DataField = 'FECHA_SES'
                DataBinding.DataSource = dsTablaG
                TabOrder = 5
                Width = 120
              end
              object lblFechaTopeRecepcion: TcxLabel
                Left = 517
                Top = 20
                AutoSize = False
                Caption = 'F.tope recep.'
                Properties.Alignment.Vert = taVCenter
                TabOrder = 20
                Transparent = True
                Height = 24
                Width = 102
              end
              object dteFechaTopeRecepcion: TcxDBDateEdit
                Left = 627
                Top = 20
                DataBinding.DataField = 'FECHA_TOPE_RECEPCION_SES'
                DataBinding.DataSource = dsTablaG
                TabOrder = 21
                Width = 120
              end
              object lblEstado: TcxLabel
                Left = 316
                Top = 147
                AutoSize = False
                Caption = 'Estado'
                Properties.Alignment.Vert = taVCenter
                TabOrder = 12
                Transparent = True
                Height = 24
                Width = 56
              end
              object txtEstado: TcxDBTextEdit
                Left = 380
                Top = 147
                DataBinding.DataField = 'ESTADO_SES'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 13
                Width = 120
              end
              object lblEmpresa: TcxLabel
                Left = 12
                Top = 63
                AutoSize = False
                Caption = 'Empresa'
                Properties.Alignment.Vert = taVCenter
                TabOrder = 6
                Transparent = True
                Height = 24
                Width = 72
              end
              object cbbEmpresa: TcxDBLookupComboBox
                Left = 92
                Top = 63
                DataBinding.DataField = 'CODIGO_EMP_SES'
                DataBinding.DataSource = dsTablaG
                Properties.KeyFieldNames = 'CODIGO_EMP_EMP'
                Properties.ListColumns = <
                  item
                    Caption = 'C'#243'digo'
                    Width = 60
                    FieldName = 'CODIGO_EMP_EMP'
                  end
                  item
                    Caption = 'Empresa'
                    FieldName = 'RAZON_SOCIAL_EMP'
                  end>
                Properties.ListFieldIndex = 1
                Properties.ListOptions.ShowHeader = False
                TabOrder = 7
                Width = 268
              end
              object lblProveedor: TcxLabel
                Left = 380
                Top = 63
                AutoSize = False
                Caption = 'Proveedor'
                Properties.Alignment.Vert = taVCenter
                TabOrder = 8
                Transparent = True
                Height = 24
                Width = 82
              end
              object cbbProveedor: TcxDBLookupComboBox
                Left = 470
                Top = 63
                DataBinding.DataField = 'CODIGO_PRV_SES'
                DataBinding.DataSource = dsTablaG
                Properties.DropDownListStyle = lsEditList
                Properties.DropDownRows = 15
                Properties.DropDownWidth = 480
                Properties.KeyFieldNames = 'CODIGO_PRV_PRV'
                Properties.IncrementalFilteringOptions = [ifoHighlightSearchText, ifoUseContainsOperator]
                Properties.ListColumns = <
                  item
                    Caption = 'C'#243'digo'
                    Width = 110
                    FieldName = 'CODIGO_PRV_PRV'
                  end
                  item
                    Caption = 'Proveedor'
                    Width = 350
                    FieldName = 'PROVEEDOR_BUSQUEDA'
                  end>
                Properties.ListFieldIndex = 1
                Properties.ListOptions.CaseInsensitive = True
                TabOrder = 9
                Width = 160
              end
              object lblRefPrv: TcxLabel
                Left = 12
                Top = 147
                AutoSize = False
                Caption = 'Ref. prov.'
                Properties.Alignment.Vert = taVCenter
                TabOrder = 10
                Transparent = True
                Height = 24
                Width = 106
              end
              object txtRefPrv: TcxDBTextEdit
                Left = 124
                Top = 147
                DataBinding.DataField = 'REF_PRV_SES'
                DataBinding.DataSource = dsTablaG
                Properties.MaxLength = 100
                TabOrder = 11
                Width = 158
              end
              object lblAlmacen: TcxLabel
                Left = 12
                Top = 107
                AutoSize = False
                Caption = 'Almac'#233'n'
                Properties.Alignment.Vert = taVCenter
                TabOrder = 14
                Transparent = True
                Height = 24
                Width = 72
              end
              object cbbAlmacen: TcxDBLookupComboBox
                Left = 92
                Top = 107
                DataBinding.DataField = 'CODIGO_ALM_SES'
                DataBinding.DataSource = dsTablaG
                Properties.KeyFieldNames = 'CODIGO_ALM_ALM'
                Properties.ListColumns = <
                  item
                    Caption = 'C'#243'digo'
                    Width = 60
                    FieldName = 'CODIGO_ALM_ALM'
                  end
                  item
                    Caption = 'Almac'#233'n'
                    FieldName = 'NOMBRE_ALM_ALM'
                  end>
                Properties.ListOptions.ShowHeader = False
                TabOrder = 15
                Width = 200
              end
              object chkFormatoDistribuido: TcxDBCheckBox
                Left = 380
                Top = 107
                Caption = 'Formato distribuido (por almac'#233'n)'
                DataBinding.DataField = 'ESFORMATO_DISTRIBUIDO_SES'
                DataBinding.DataSource = dsTablaG
                Properties.ValueChecked = 'S'
                Properties.ValueUnchecked = 'N'
                Style.TransparentBorder = False
                TabOrder = 16
                Transparent = True
              end
              object lblProveedorNombre: TcxLabel
                Left = 639
                Top = 63
                AutoSize = False
                Properties.Alignment.Vert = taVCenter
                Height = 24
                Width = 441
                ParentFont = False
                Style.Font.Charset = ANSI_CHARSET
                Style.Font.Color = clWindowText
                Style.Font.Height = -15
                Style.Font.Name = 'Source Sans 3'
                Style.Font.Pitch = fpFixed
                Style.Font.Style = [fsBold]
                Style.Font.Quality = fqClearTypeNatural
                Style.IsFontAssigned = True
                TabOrder = 17
                Transparent = True
              end
              object lblVariacion: TcxLabel
                Left = 517
                Top = 147
                AutoSize = False
                Caption = 'Variación por defecto'
                Properties.Alignment.Vert = taVCenter
                TabOrder = 18
                Transparent = True
                Height = 24
                Width = 175
              end
              object cbbVariacion: TcxDBLookupComboBox
                Left = 700
                Top = 147
                DataBinding.DataField = 'CODIGO_VAR_SES'
                DataBinding.DataSource = dsTablaG
                Properties.DropDownListStyle = lsFixedList
                Properties.DropDownWidth = 500
                Properties.KeyFieldNames = 'CODIGO_VAR'
                Properties.ListColumns = <
                  item
                    Caption = 'C'#243'digo'
                    Width = 60
                    FieldName = 'CODIGO_VAR'
                  end
                  item
                    Caption = 'Variaci'#243'n'
                    FieldName = 'NOMBRE_VAR'
                  end>
                Properties.ListFieldIndex = 1
                Properties.ListOptions.ShowHeader = True
                TabOrder = 19
                Width = 360
              end
            end
          end
          object cxTabSheet3: TcxTabSheet
            Caption = '&2. Ajustes Documento'
            ImageIndex = 1
            object lblTemporada: TcxLabel
              Left = 16
              Top = 24
              Caption = 'Temporada'
              TabOrder = 0
              Transparent = True
            end
            object cbbTemporada: TcxDBLookupComboBox
              Left = 110
              Top = 20
              DataBinding.DataField = 'ID_PV_TEMPORADA_SES'
              DataBinding.DataSource = dsTablaG
              Properties.KeyFieldNames = 'ID_PV_ARTPROP'
              Properties.ListColumns = <
                item
                  Caption = 'Temporada'
                  FieldName = 'PV'
                end>
              Properties.ListOptions.ShowHeader = False
              TabOrder = 1
              Width = 220
            end
            object cbbTarifa: TcxDBLookupComboBox
              Left = 456
              Top = 20
              DataBinding.DataField = 'CODIGO_TAR_SES'
              DataBinding.DataSource = dsTablaG
              Properties.KeyFieldNames = 'CODIGO_TAR_ARTTAR'
              Properties.ListColumns = <
                item
                  Caption = 'Tarifa'
                  FieldName = 'NOMBRE_TAR_TAR'
                end>
              Properties.ListOptions.ShowHeader = False
              TabOrder = 3
              Width = 220
            end
            object lblTarifa: TcxLabel
              Left = 360
              Top = 24
              Caption = 'Tarifa venta'
              TabOrder = 2
              Transparent = True
            end
            object rbCoeficiente: TcxRadioButton
              Left = 16
              Top = 68
              Width = 184
              Height = 17
              Caption = 'Coeficiente PVP %'
              Checked = True
              TabOrder = 4
              TabStop = True
              OnClick = CambiarModoPrecio
            end
            object rbMargenVenta: TcxRadioButton
              Left = 16
              Top = 100
              Width = 184
              Height = 17
              Caption = 'Margen sobre venta %'
              TabOrder = 6
              OnClick = CambiarModoPrecio
            end
            object spnMargenVenta: TcxSpinEdit
              Left = 208
              Top = 100
              Hint = 'PVP = coste / (1 - margen / 100). Ej.: 20 % de 4,50 = 5,625.'
              Enabled = False
              ParentShowHint = False
              Properties.DisplayFormat = '0.00'
              Properties.ImmediatePost = True
              Properties.MaxValue = 99.99000000000000000
              Properties.MinValue = -100000.00000000000000000
              Properties.ValueType = vtFloat
              Properties.OnChange = CambiarMargenVenta
              Properties.OnEditValueChanged = CambiarMargenVenta
              ShowHint = True
              TabOrder = 7
              Width = 92
            end
            object spnMargen: TcxDBSpinEdit
              Left = 208
              Top = 68
              Hint = 'PVP = coste '#215' coeficiente / 100. Ej.: 120 % de 4,50 = 5,40.'
              DataBinding.DataField = 'PORCENTAJE_MARGEN_SES'
              DataBinding.DataSource = dsTablaG
              ParentShowHint = False
              Properties.ValueType = vtFloat
              Properties.OnEditValueChanged = ActualizarMargenVenta
              ShowHint = True
              TabOrder = 5
              Width = 92
            end
            object lblMultiploRedondeo: TcxLabel
              Left = 16
              Top = 144
              Caption = 'Redondeo'
              TabOrder = 8
              Transparent = True
            end
            object spnMultiploRedondeo: TcxDBSpinEdit
              Left = 208
              Top = 140
              DataBinding.DataField = 'MULTIPLO_REDONDEO_SES'
              DataBinding.DataSource = dsTablaG
              Properties.Increment = 0.05000000000000000
              Properties.ValueType = vtFloat
              TabOrder = 9
              Width = 92
            end
            object lblAjusteFinal: TcxLabel
              Left = 16
              Top = 176
              Caption = 'Ajuste final'
              TabOrder = 10
              Transparent = True
            end
            object spnAjusteFinal: TcxDBSpinEdit
              Left = 208
              Top = 172
              DataBinding.DataField = 'AJUSTE_FINAL_SES'
              DataBinding.DataSource = dsTablaG
              Properties.Increment = 0.01000000000000000
              Properties.MaxValue = 10.00000000000000000
              Properties.MinValue = -10.00000000000000000
              Properties.ValueType = vtFloat
              TabOrder = 11
              Width = 92
            end
            object chkVariosTiposIva: TcxDBCheckBox
              Left = 360
              Top = 68
              Caption = 'Varios tipos IVA'
              DataBinding.DataField = 'ESVARIOS_TIPOS_IVA_SES'
              DataBinding.DataSource = dsTablaG
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Properties.OnChange = chkVariosTiposIvaPropertiesChange
              Style.TransparentBorder = False
              TabOrder = 12
              Transparent = True
            end
            object lblTipoIvaDefecto: TcxLabel
              Left = 360
              Top = 104
              Caption = 'IVA defecto'
              TabOrder = 13
              Transparent = True
            end
            object chkESVARIOS_TIPOS_VARIACION_SES: TcxDBCheckBox
              Left = 540
              Top = 68
              Caption = 'Varios tipos de variación por línea'
              DataBinding.DataField = 'ESVARIOS_TIPOS_VARIACION_SES'
              DataBinding.DataSource = dsTablaG
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Style.TransparentBorder = False
              TabOrder = 17
              Transparent = True
              Width = 360
            end
            object cbbTipoIvaDefecto: TcxDBComboBox
              Left = 456
              Top = 100
              DataBinding.DataField = 'TIPO_IVA_SES'
              DataBinding.DataSource = dsTablaG
              Properties.DropDownListStyle = lsFixedList
              Properties.Items.Strings = (
                'N'
                'R'
                'S'
                'E')
              Properties.OnChange = cbbTipoIvaDefectoPropertiesChange
              TabOrder = 14
              Width = 60
            end
            object chkCopiarDescripcionFamilia: TcxDBCheckBox
              Left = 360
              Top = 140
              Caption = 'Copiar descripci'#243'n de la familia al art'#237'culo'
              DataBinding.DataField = 'ESCOPIAR_DESCRIPCION_FAM_SES'
              DataBinding.DataSource = dsTablaG
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Style.TransparentBorder = False
              TabOrder = 15
              Transparent = True
            end
            object chkDescripcionBlanco: TcxDBCheckBox
              Left = 360
              Top = 172
              Caption = 'Dejar descripci'#243'n en blanco'
              DataBinding.DataField = 'ESDESCRIPCION_BLANCO_SES'
              DataBinding.DataSource = dsTablaG
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Style.TransparentBorder = False
              TabOrder = 16
              Transparent = True
            end
          end
          object tsPedidoOriginal: TcxTabSheet
            Caption = '&3. Pedido original'
            ImageIndex = 2
            object scrPedidoOriginal: TScrollBox
              Left = 0
              Top = 40
              Width = 1084
              Height = 184
              HorzScrollBar.Tracking = True
              VertScrollBar.Tracking = True
              Align = alClient
              BorderStyle = bsNone
              Color = clAppWorkSpace
              ParentColor = False
              TabOrder = 0
              ExplicitHeight = 224
              object imgPedidoOriginal: TImage
                Left = 0
                Top = 0
                Width = 32
                Height = 32
                Cursor = crHandPoint
                Proportional = True
                Stretch = True
              end
            end
            object pnlPedidoOriginalTop: TPanel
              Left = 0
              Top = 0
              Width = 1084
              Height = 40
              Align = alTop
              BevelOuter = bvNone
              TabOrder = 1
              object btnPaginaAnteriorPedido: TcxButton
                Left = 4
                Top = 6
                Width = 88
                Height = 28
                Caption = '< Anterior'
                TabOrder = 0
              end
              object btnPaginaSiguientePedido: TcxButton
                Left = 98
                Top = 6
                Width = 88
                Height = 28
                Caption = 'Siguiente >'
                TabOrder = 1
              end
              object btnAlejarPedido: TcxButton
                Left = 202
                Top = 6
                Width = 38
                Height = 28
                Caption = '-'
                TabOrder = 2
              end
              object btnAcercarPedido: TcxButton
                Left = 246
                Top = 6
                Width = 38
                Height = 28
                Caption = '+'
                TabOrder = 3
              end
              object btnAjustarPedido: TcxButton
                Left = 300
                Top = 6
                Width = 138
                Height = 28
                Caption = 'Ajustar ventana'
                TabOrder = 4
              end
              object btnZoomRealPedido: TcxButton
                Left = 444
                Top = 6
                Width = 70
                Height = 28
                Caption = '100 %'
                TabOrder = 5
              end
              object btnFijarZoomPedido: TcxButton
                Left = 520
                Top = 6
                Width = 100
                Height = 28
                Hint = 
                  'Mantiene el zoom actual al cambiar de pedido en lugar de encajar' +
                  ' la imagen'
                Caption = 'Fijar zoom'
                ParentShowHint = False
                ShowHint = True
                SpeedButtonOptions.GroupIndex = 1
                SpeedButtonOptions.AllowAllUp = True
                TabOrder = 6
              end
              object lblPaginaPedido: TcxLabel
                Left = 598
                Top = 9
                Caption = 'Sin p'#225'ginas TIFF importadas'
                TabOrder = 7
                Transparent = True
              end
            end
          end
        end
        object gbFotoProvisional: TcxGroupBox
          Left = 784
          Top = 36
          Anchors = [akTop, akRight]
          Caption = ' Foto de la l'#237'nea '
          TabOrder = 3
          Height = 214
          Width = 296
          object imgFotoProvisional: TImage
            AlignWithMargins = True
            Left = 10
            Top = 31
            Width = 276
            Height = 139
            Margins.Left = 8
            Margins.Top = 8
            Margins.Right = 8
            Margins.Bottom = 4
            Align = alClient
            Center = True
            Proportional = True
            Stretch = True
            ExplicitLeft = 8
            ExplicitTop = 24
            ExplicitWidth = 294
            ExplicitHeight = 184
          end
          object lblFotoProvisionalAsignacion: TcxLabel
            AlignWithMargins = True
            Left = 10
            Top = 174
            Margins.Left = 8
            Margins.Top = 0
            Margins.Right = 8
            Margins.Bottom = 8
            Align = alBottom
            AutoSize = False
            Caption = 'Seleccione una l'#237'nea de la sesi'#243'n.'
            Properties.Alignment.Horz = taCenter
            Properties.WordWrap = True
            TabOrder = 0
            Transparent = True
            Height = 30
            Width = 276
            AnchorX = 148
          end
        end
      end
      inherited tsPerfil: TcxTabSheet
        Caption = '&3. Perfil'
        ExplicitHeight = 485
        inherited pnlPerfilTop: TPanel
          Width = 1092


        end
        inherited pnlPerfilDetail: TPanel
          Width = 1092
          Height = 653
        end
      end
    end
    inherited pnlTopPage: TPanel
      Width = 1100
      inherited pnlTopGrid: TPanel
        Width = 1100


      end
    end
  end
  inherited pButtonRightBar: TPanel
    Left = 1100
    Height = 783
    inherited pButtonGen: TPanel
      Top = 585
    end
    inherited pButtonBDStat: TPanel
      inherited imgIconoPantalla: TcxImage
        Style.Font.Height = -9
        Style.IsFontAssigned = True
      end
      inherited pnStateDataSet: TPanel

      end
      inherited pnlDataSetName: TPanel

      end
    end
    object btnCrear: TcxButton
      Left = 0
      Top = 230
      Width = 137
      Height = 69
      Caption = 'Crear Art. y Docs.'
      Colors.Default = 9101247
      Colors.Normal = 9101247
      LookAndFeel.Kind = lfFlat
      LookAndFeel.NativeStyle = False
      TabOrder = 2
      WordWrap = True
      OnClick = btnCrearClick
    end
    object btnImportarPedido: TcxButton
      Left = 0
      Top = 180
      Width = 137
      Height = 40
      Caption = 'Importar pedido PDF'
      Colors.Default = 16773096
      Colors.Normal = 16773096
      LookAndFeel.Kind = lfFlat
      LookAndFeel.NativeStyle = False
      TabOrder = 6
      WordWrap = True
      OnClick = btnImportarPedidoClick
    end
    object btnRevertir: TcxButton
      Left = 0
      Top = 308
      Width = 137
      Height = 40
      Caption = 'Revertir materializaci'#243'n'
      Colors.Default = 11337471
      Colors.Normal = 11337471
      LookAndFeel.Kind = lfFlat
      LookAndFeel.NativeStyle = False
      TabOrder = 3
      WordWrap = True
      OnClick = btnRevertirClick
    end
    object btnImprimir: TcxButton
      Left = 0
      Top = 358
      Width = 137
      Height = 69
      Caption = 'Imprimir horizontal'
      LookAndFeel.Kind = lfFlat
      LookAndFeel.NativeStyle = False
      TabOrder = 4
      WordWrap = True
      OnClick = btnImprimirClick
    end
    object btnIrPedAlb: TcxButton
      Left = 0
      Top = 437
      Width = 137
      Height = 40
      Caption = 'Ir a Ped / Alb'
      LookAndFeel.Kind = lfFlat
      LookAndFeel.NativeStyle = False
      TabOrder = 5
      WordWrap = True
    end
  end
  inherited Localizer1: TcxLocalizer
    Left = 616
    Top = 656
  end
  inherited dsTablaG: TDataSource
    Left = 392
    Top = 656
  end
  inherited saveDialog: TdxSaveFileDialog
    Left = 808
    Top = 664
  end
  inherited tmrBusqGlobal: TTimer
    Left = 504
    Top = 656
  end
  inherited alMtoGen: TActionList
    Left = 704
    Top = 656
  end
  object dlgFoto: TOpenDialog
    Filter = 
      'Imagenes (*.png;*.jpg;*.jpeg;*.webp;*.avif;*.bmp)|*.png;*.jpg;*.' +
      'jpeg;*.webp;*.avif;*.bmp'
    Options = [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Left = 920
    Top = 8
  end
  object dlgImportarPedido: TOpenDialog
    Filter = 'Documento PDF (*.pdf)|*.pdf'
    Options = [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Left = 952
    Top = 64
  end
  object alNavegacion: TActionList
    Left = 1000
    Top = 8
    object actIrArticulos: TAction
      Caption = 'Ir a Art'#237'culos'
      ShortCut = 16466
    end
    object actIrAlbaranesCompra: TAction
      Caption = 'Ir a Albaranes de Compra'
    end
    object actIrPedidosCompra: TAction
      Caption = 'Ir a Pedidos de Compra'
      ShortCut = 24656
    end
    object actIrProveedor: TAction
      Caption = 'Ir a Proveedor'
      ShortCut = 16464
    end
  end
  object dsPrvFicha: TDataSource
    Left = 1040
    Top = 8
  end
end
