inherited frmMtoFacturasBase: TfrmMtoFacturasBase
  Margins.Left = 0
  Margins.Top = 0
  Margins.Right = 0
  Margins.Bottom = 0
  BorderIcons = []
  Caption = #186
  ClientHeight = 844
  ClientWidth = 1231
  StyleElements = [seFont, seClient, seBorder]
  ExplicitWidth = 1231
  ExplicitHeight = 844
  TextHeight = 17
  object shpSeparador6: TShape [0]
    Left = 76
    Top = 79
    Width = 533
    Height = 50
    Brush.Style = bsClear
  end
  inherited pButtonPage: TPanel
    Width = 1087
    Height = 844
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    TabOrder = 0
    StyleElements = [seFont, seClient, seBorder]
    ExplicitWidth = 1087
    ExplicitHeight = 844
    inherited pcPantalla: TcxPageControl
      Width = 1087
      Height = 804
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      TabOrder = 1
      ExplicitWidth = 1087
      ExplicitHeight = 804
      ClientRectBottom = 800
      ClientRectRight = 1083
      inherited tsLista: TcxTabSheet
        Margins.Left = 5
        Margins.Top = 5
        Margins.Right = 5
        Margins.Bottom = 5
        ExplicitLeft = 4
        ExplicitTop = 28
        ExplicitWidth = 1079
        ExplicitHeight = 772
        inherited cxGrdPrincipal: TcxGrid
          Width = 1079
          Height = 772
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
          ExplicitWidth = 1079
          ExplicitHeight = 772
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            object cxgrdbclmnGrdDBTabPrinCODIGO_EMPRESA_FACTURA: TcxGridDBColumn
              Caption = 'C'#243'digo Empresa'
              DataBinding.FieldName = 'CODIGO_EMP_FAC'
              Width = 171
            end
            object cxgrdbclmnGrdDBTabPrinNRO_FACTURA: TcxGridDBColumn
              Caption = 'Nro Borrador'
              DataBinding.FieldName = 'NUMERO_FAC'
              Width = 113
            end
            object cxgrdbclmnGrdDBTabPrinSERIE_FACTURA: TcxGridDBColumn
              Caption = 'Serie'
              DataBinding.FieldName = 'SERIE_FAC'
              Width = 65
            end
            object cxgrdbclmnGrdDBTabPrinFECHA_FACTURA: TcxGridDBColumn
              Caption = 'Fecha'
              DataBinding.FieldName = 'FECHA_FAC'
              PropertiesClassName = 'TcxDateEditProperties'
              Width = 124
            end
            object cxGrdDBTabPrinFASE_FAC: TcxGridDBColumn
              Caption = 'Fase del borrador'
              DataBinding.FieldName = 'FASE_FAC'
              Options.Editing = False
              Width = 160
            end
            object cxGrdDBTabPrinTIPO_FAC: TcxGridDBColumn
              Caption = 'Tipo de borrador'
              DataBinding.FieldName = 'TIPO_FAC'
              Options.Editing = False
              Width = 150
            end
            object cxGrdDBTabPrinSERIE_RECTIFICADA_FAC: TcxGridDBColumn
              Caption = 'Serie del borrador rectificado'
              DataBinding.FieldName = 'SERIE_RECTIFICADA_FAC'
              Options.Editing = False
              Width = 210
            end
            object cxGrdDBTabPrinNUMERO_RECTIFICADA_FAC: TcxGridDBColumn
              Caption = 'Número del borrador rectificado'
              DataBinding.FieldName = 'NUMERO_RECTIFICADA_FAC'
              Options.Editing = False
              Width = 225
            end
            object cxgrdbclmnGrdDBTabPrinTOTAL_LIQUIDO_FACTURA: TcxGridDBColumn
              Caption = 'Total Liquido'
              DataBinding.FieldName = 'TOTAL_LIQUIDO_FAC'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 157
            end
            object cxgrdbclmnGrdDBTabPrinCODIGO_CLIENTE_FACTURA: TcxGridDBColumn
              Caption = 'C'#243'digo Cliente'
              DataBinding.FieldName = 'CODIGO_CLI_FAC'
              Width = 155
            end
            object cxgrdbclmnGrdDBTabPrinRAZONSOCIAL_CLIENTE_FACTURA: TcxGridDBColumn
              Caption = 'Raz'#243'n Social'
              DataBinding.FieldName = 'RAZON_SOCIAL_CLIENTE_FAC'
              Width = 289
            end
            object cxgrdbclmnGrdDBTabPrinCODIGO_ZONA_IVA_CLIENTE: TcxGridDBColumn
              Caption = 'C'#243'digo IVA'
              DataBinding.FieldName = 'CODIGO_ZONA_IVA_CLIENTE'
              Width = 112
            end
            object cxgrdbclmnGrdDBTabPrinNIF_CLIENTE_FACTURA: TcxGridDBColumn
              Caption = 'Nif'
              DataBinding.FieldName = 'NIF_CLIENTE_FAC'
              Width = 134
            end
            object cxgrdbclmnGrdDBTabPrinMOVIL_CLIENTE_FACTURA: TcxGridDBColumn
              Caption = 'M'#243'vil'
              DataBinding.FieldName = 'MOVIL_CLIENTE_FAC'
              PropertiesClassName = 'TcxTextEditProperties'
              Width = 150
            end
            object cxgrdbclmnGrdDBTabPrinEMAIL_CLIENTE_FACTURA: TcxGridDBColumn
              Caption = 'Email'
              DataBinding.FieldName = 'EMAIL_CLIENTE_FAC'
              Width = 146
            end
            object cxgrdbclmnGrdDBTabPrinDIRECCION1_CLIENTE_FACTURA: TcxGridDBColumn
              Caption = 'Direcci'#243'n 1'
              DataBinding.FieldName = 'DIRECCION1_CLIENTE_FAC'
              Width = 181
            end
            object cxgrdbclmnGrdDBTabPrinDIRECCION2_CLIENTE_FACTURA: TcxGridDBColumn
              Caption = 'Direcci'#243'n 2'
              DataBinding.FieldName = 'DIRECCION2_CLIENTE_FAC'
              Width = 181
            end
            object cxgrdbclmnGrdDBTabPrinCPOSTAL_CLIENTE_FACTURA: TcxGridDBColumn
              Caption = 'C'#243'digo Postal'
              DataBinding.FieldName = 'CODIGO_POSTAL_CLIENTE_FAC'
              Width = 135
            end
            object cxgrdbclmnGrdDBTabPrinPOBLACION_CLIENTE_FACTURA: TcxGridDBColumn
              Caption = 'Poblaci'#243'n'
              DataBinding.FieldName = 'POBLACION_CLIENTE_FAC'
              Width = 177
            end
            object cxgrdbclmnGrdDBTabPrinPROVINCIA_CLIENTE_FACTURA: TcxGridDBColumn
              Caption = 'Provincia'
              DataBinding.FieldName = 'PROVINCIA_CLIENTE_FAC'
              Width = 173
            end
            object dbcGrdDBTabPrinNOMBRE_PAIS_CLIENTE_FACTURA: TcxGridDBColumn
              Caption = 'País del cliente'
              DataBinding.FieldName = 'NOMBRE_PAI_CLIENTE_FAC'
              Width = 150
            end
            object cxgrdbclmnGrdDBTabPrinFORMA_PAGO_FACTURA: TcxGridDBColumn
              Caption = 'Forma Pago'
              DataBinding.FieldName = 'FORMA_PAGO_FAC'
              Width = 143
            end
            object cxgrdbclmnGrdDBTabPrinDESCRIPCION_FORMAPAGO: TcxGridDBColumn
              Caption = 'Descripci'#243'n Forma de Pago'
              DataBinding.FieldName = 'DESCRIPCION_FORMA_PAGO_FP'
              Width = 256
            end
            object cxgrdbclmnGrdDBTabPrinRAZONSOCIAL_EMPRESA_FACTURA: TcxGridDBColumn
              Caption = 'Raz'#243'n Social Empresa'
              DataBinding.FieldName = 'RAZON_SOCIAL_EMPRESA_FAC'
              Width = 187
            end
            object cxgrdbclmnGrdDBTabPrinNIF_EMPRESA_FACTURA: TcxGridDBColumn
              Caption = 'Nif Empresa'
              DataBinding.FieldName = 'NIF_EMPRESA_FAC'
              Width = 121
            end
            object cxgrdbclmnGrdDBTabPrinMOVIL_EMPRESA_FACTURA: TcxGridDBColumn
              Caption = 'Tel'#233'fono Empresa'
              DataBinding.FieldName = 'MOVIL_EMPRESA_FAC'
              Width = 167
            end
            object cxgrdbclmnGrdDBTabPrinEMAIL_EMPRESA_FACTURA: TcxGridDBColumn
              Caption = 'Email Empresa'
              DataBinding.FieldName = 'EMAIL_EMPRESA_FAC'
              Width = 138
            end
            object cxgrdbclmnGrdDBTabPrinDIRECCION1_EMPRESA_FACTURA: TcxGridDBColumn
              Caption = 'Direcci'#243'n Empresa'
              DataBinding.FieldName = 'DIRECCION1_EMPRESA_FAC'
              Width = 161
            end
            object cxgrdbclmnGrdDBTabPrinDIRECCION2_EMPRESA_FACTURA: TcxGridDBColumn
              Caption = 'Direcci'#243'n Secundaria Empresa'
              DataBinding.FieldName = 'DIRECCION2_EMPRESA_FAC'
              Width = 277
            end
            object cxgrdbclmnGrdDBTabPrinPOBLACION_EMPRESA_FACTURA: TcxGridDBColumn
              Caption = 'Poblaci'#243'n Empresa'
              DataBinding.FieldName = 'POBLACION_EMPRESA_FAC'
              Width = 180
            end
            object cxgrdbclmnGrdDBTabPrinPROVINCIA_EMPRESA_FACTURA: TcxGridDBColumn
              Caption = 'Provincia Empresa'
              DataBinding.FieldName = 'PROVINCIA_EMPRESA_FAC'
              Width = 174
            end
            object cxgrdbclmnGrdDBTabPrinCPOSTAL_EMPRESA_FACTURA: TcxGridDBColumn
              Caption = 'C'#243'digo Postal Empresa'
              DataBinding.FieldName = 'CODIGO_POSTAL_EMPRESA_FAC'
              Width = 197
            end
            object cxgrdbclmnGrdDBTabPrinRETENCIONES_EMPRESA_FACTURA: TcxGridDBColumn
              Caption = 'Tiene Retenciones Empresa'
              DataBinding.FieldName = 'ESRETENCIONES_EMPRESA_FAC'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 231
            end
            object cxgrdbclmnGrdDBTabPrinIVA_RECARGO_CLIENTE_FACTURA: TcxGridDBColumn
              Caption = 'Tiene RE cliente'
              DataBinding.FieldName = 'ESIVA_RECARGO_CLIENTE_FAC'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 136
            end
            object cxgrdbclmnGrdDBTabPrinPORCEN_IVAN_FACTURA: TcxGridDBColumn
              Caption = '% IVA Normal'
              DataBinding.FieldName = 'PORCENTAJE_IVAN_FAC'
              PropertiesClassName = 'TcxSpinEditProperties'
              Properties.AssignedValues.MinValue = True
              Properties.DisplayFormat = '0.00 %'
              Properties.EditFormat = '0.00 %'
              Properties.Increment = 0.100000000000000000
              Properties.LargeIncrement = 1.000000000000000000
              Properties.MaxValue = 100.000000000000000000
              Properties.ValueType = vtInt
              Width = 116
            end
            object cxgrdbclmnGrdDBTabPrinTOTAL_IVAN_FACTURA: TcxGridDBColumn
              Caption = 'Total IVA Normal'
              DataBinding.FieldName = 'TOTAL_IVAN_FAC'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 159
            end
            object cxgrdbclmnGrdDBTabPrinPORCEN_REN_FACTURA: TcxGridDBColumn
              Caption = '% RE IVA Normal'
              DataBinding.FieldName = 'PORCENTAJE_REN_FAC'
              PropertiesClassName = 'TcxSpinEditProperties'
              Properties.AssignedValues.MinValue = True
              Properties.DisplayFormat = '0.00 %'
              Properties.EditFormat = '0.00 %'
              Properties.Increment = 0.100000000000000000
              Properties.LargeIncrement = 1.000000000000000000
              Properties.MaxValue = 100.000000000000000000
              Properties.ValueType = vtInt
              Width = 141
            end
            object cxgrdbclmnGrdDBTabPrinTOTAL_REN_FACTURA: TcxGridDBColumn
              Caption = 'Total RE Normal'
              DataBinding.FieldName = 'TOTAL_REN_FAC'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 139
            end
            object cxgrdbclmnGrdDBTabPrinTOTAL_BASEI_IVAN_FACTURA: TcxGridDBColumn
              Caption = 'Total Base Imponible Normal'
              DataBinding.FieldName = 'TOTAL_BASEI_IVAN_FAC'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 264
            end
            object cxgrdbclmnGrdDBTabPrinPORCEN_IVAR_FACTURA: TcxGridDBColumn
              Caption = '% IVA Reducido'
              DataBinding.FieldName = 'PORCENTAJE_IVAR_FAC'
              PropertiesClassName = 'TcxSpinEditProperties'
              Properties.AssignedValues.MinValue = True
              Properties.DisplayFormat = '0.00 %'
              Properties.EditFormat = '0.00 %'
              Properties.Increment = 0.100000000000000000
              Properties.LargeIncrement = 1.000000000000000000
              Properties.MaxValue = 100.000000000000000000
              Properties.ValueType = vtInt
              Width = 145
            end
            object cxgrdbclmnGrdDBTabPrinTOTAL_IVAR_FACTURA: TcxGridDBColumn
              Caption = 'Total IVA Normal'
              DataBinding.FieldName = 'TOTAL_IVAR_FAC'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 164
            end
            object cxgrdbclmnGrdDBTabPrinPORCEN_RER_FACTURA: TcxGridDBColumn
              Caption = '% RE Reducido'
              DataBinding.FieldName = 'PORCENTAJE_RER_FAC'
              PropertiesClassName = 'TcxSpinEditProperties'
              Properties.AssignedValues.MinValue = True
              Properties.DisplayFormat = '0.00 %'
              Properties.EditFormat = '0.00 %'
              Properties.Increment = 0.100000000000000000
              Properties.LargeIncrement = 1.000000000000000000
              Properties.MaxValue = 100.000000000000000000
              Properties.ValueType = vtInt
              Width = 145
            end
            object cxgrdbclmnGrdDBTabPrinTOTAL_RER_FACTURA: TcxGridDBColumn
              Caption = 'Total RE Reducido'
              DataBinding.FieldName = 'TOTAL_RER_FAC'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 172
            end
            object cxgrdbclmnGrdDBTabPrinTOTAL_BASEI_IVAR_FACTURA: TcxGridDBColumn
              Caption = 'Total Base Imponible Reducido'
              DataBinding.FieldName = 'TOTAL_BASEI_IVAR_FAC'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 284
            end
            object cxgrdbclmnGrdDBTabPrinPORCEN_IVAS_FACTURA: TcxGridDBColumn
              Caption = '% IVA SuperReducido'
              DataBinding.FieldName = 'PORCENTAJE_IVAS_FAC'
              PropertiesClassName = 'TcxSpinEditProperties'
              Properties.AssignedValues.MinValue = True
              Properties.DisplayFormat = '0.00 %'
              Properties.EditFormat = '0.00 %'
              Properties.Increment = 0.100000000000000000
              Properties.LargeIncrement = 1.000000000000000000
              Properties.MaxValue = 100.000000000000000000
              Properties.ValueType = vtInt
              Width = 198
            end
            object cxgrdbclmnGrdDBTabPrinTOTAL_IVAS_FACTURA: TcxGridDBColumn
              Caption = 'Total IVA SuperReducido'
              DataBinding.FieldName = 'TOTAL_IVAS_FAC'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 232
            end
            object cxgrdbclmnGrdDBTabPrinPORCEN_RES_FACTURA: TcxGridDBColumn
              Caption = '% RE SuperReducido'
              DataBinding.FieldName = 'PORCENTAJE_RES_FAC'
              PropertiesClassName = 'TcxSpinEditProperties'
              Properties.AssignedValues.MinValue = True
              Properties.DisplayFormat = '0.00 %'
              Properties.EditFormat = '0.00 %'
              Properties.Increment = 0.100000000000000000
              Properties.LargeIncrement = 1.000000000000000000
              Properties.MaxValue = 100.000000000000000000
              Properties.ValueType = vtInt
              Width = 200
            end
            object cxgrdbclmnGrdDBTabPrinTOTAL_RES_FACTURA: TcxGridDBColumn
              Caption = 'Total RE SuperReducido'
              DataBinding.FieldName = 'TOTAL_RES_FAC'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 212
            end
            object cxgrdbclmnGrdDBTabPrinTOTAL_BASEI_IVAS_FACTURA: TcxGridDBColumn
              Caption = 'Total BI SuperReducido'
              DataBinding.FieldName = 'TOTAL_BASEI_IVAS_FAC'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 242
            end
            object cxgrdbclmnGrdDBTabPrinPORCEN_IVAE_FACTURA: TcxGridDBColumn
              Caption = '% IVA Exento'
              DataBinding.FieldName = 'PORCENTAJE_IVAE_FAC'
              PropertiesClassName = 'TcxSpinEditProperties'
              Properties.AssignedValues.MinValue = True
              Properties.DisplayFormat = '0.00 %'
              Properties.EditFormat = '0.00 %'
              Properties.Increment = 0.100000000000000000
              Properties.LargeIncrement = 1.000000000000000000
              Properties.MaxValue = 100.000000000000000000
              Properties.ValueType = vtInt
              Width = 123
            end
            object cxgrdbclmnGrdDBTabPrinTOTAL_IVAE_FACTURA: TcxGridDBColumn
              Caption = 'Total Exento'
              DataBinding.FieldName = 'TOTAL_IVAE_FAC'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 116
            end
            object cxgrdbclmnGrdDBTabPrinPORCEN_REE_FACTURA: TcxGridDBColumn
              Caption = '% RE Exento'
              DataBinding.FieldName = 'PORCENTAJE_REE_FAC'
              PropertiesClassName = 'TcxSpinEditProperties'
              Properties.AssignedValues.MinValue = True
              Properties.DisplayFormat = '0.00 %'
              Properties.EditFormat = '0.00 %'
              Properties.Increment = 0.100000000000000000
              Properties.LargeIncrement = 1.000000000000000000
              Properties.MaxValue = 100.000000000000000000
              Properties.ValueType = vtInt
              Width = 109
            end
            object cxgrdbclmnGrdDBTabPrinTOTAL_REE_FACTURA: TcxGridDBColumn
              Caption = 'Total RE Exento'
              DataBinding.FieldName = 'TOTAL_REE_FAC'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 143
            end
            object cxgrdbclmnGrdDBTabPrinTOTAL_BASEI_IVAE_FACTURA: TcxGridDBColumn
              Caption = 'Total BI Exento'
              DataBinding.FieldName = 'TOTAL_BASEI_IVAE_FAC'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 148
            end
            object cxgrdbclmnGrdDBTabPrinPORCEN_RETENCION_FACTURA: TcxGridDBColumn
              Caption = '% Retenci'#243'n'
              DataBinding.FieldName = 'PORCENTAJE_RETENCION_FAC'
              PropertiesClassName = 'TcxSpinEditProperties'
              Properties.AssignedValues.MinValue = True
              Properties.DisplayFormat = '0.00 %'
              Properties.EditFormat = '0.00 %'
              Properties.Increment = 0.100000000000000000
              Properties.LargeIncrement = 1.000000000000000000
              Properties.MaxValue = 100.000000000000000000
              Properties.ValueType = vtInt
              Width = 115
            end
            object cxgrdbclmnGrdDBTabPrinTOTAL_RETENCION_FACTURA: TcxGridDBColumn
              Caption = 'Total Retenci'#243'n'
              DataBinding.FieldName = 'TOTAL_RETENCION_FAC'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 147
            end
            object cxgrdbclmnGrdDBTabPrinNRO_FACTURA_ABONO_FACTURA: TcxGridDBColumn
              Caption = 'Nro Borrador Abono'
              DataBinding.FieldName = 'NUMERO_FAC_ABONO_FAC'
              Visible = False
              Width = 170
            end
            object cxgrdbclmnGrdDBTabPrinSERIE_FACTURA_ABONO_FACTURA: TcxGridDBColumn
              Caption = 'Serie Borrador Abono'
              DataBinding.FieldName = 'SERIE_FAC_ABONO_FAC'
              Visible = False
              Width = 194
            end
            object cxgrdbclmnGrdDBTabPrinDOCUMENTO_FACTURA: TcxGridDBColumn
              DataBinding.FieldName = 'DOCUMENTO_FAC'
              Visible = False
            end
            object cxgrdbclmnGrdDBTabPrinCOMENTARIOS_FACTURA: TcxGridDBColumn
              Caption = 'Comentarios Borrador'
              DataBinding.FieldName = 'COMENTARIOS_FAC'
              Visible = False
              Width = 213
            end
            object cxgrdbclmnGrdDBTabPrinTEXTO_LEGAL_FACTURA_EMPRESA_FACTURA: TcxGridDBColumn
              Caption = 'Texto Legal Empresa'
              DataBinding.FieldName = 'TEXTO_LEGAL_EMPRESA_FAC'
              Visible = False
              Width = 685
            end
            object cxgrdbclmnGrdDBTabPrinTEXTO_LEGAL_FACTURA_CLIENTE_FACTURA: TcxGridDBColumn
              Caption = 'Texto legal Cliente en Borrador'
              DataBinding.FieldName = 'TEXTO_LEGAL_CLIENTE_FAC'
              Visible = False
              Width = 376
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
            end
            object cxgrdbclmnGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn
              DataBinding.FieldName = 'USUARIO_MODIF'
              Visible = False
              Width = 146
            end
            object cxGrdDBTabPrinGRUPO_IVA_EMPRESA_FACTURA: TcxGridDBColumn
              DataBinding.FieldName = 'GRUPO_IVA_EMPRESA_FACTURA'
              Visible = False
            end
            object cxGrdDBTabPrinESIVA_EXENTO_CLIENTE_FACTURA: TcxGridDBColumn
              Caption = 'Borrador Exento IVA'
              DataBinding.FieldName = 'ESIVA_EXENTO_CLIENTE_FAC'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 163
            end
            object cxGrdDBTabPrinESRETENCIONES_CLIENTE_FACTURA: TcxGridDBColumn
              Caption = 'Cliente tiene IRPF'
              DataBinding.FieldName = 'ESRETENCIONES_CLIENTE_FAC'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 160
            end
            object cxGrdDBTabPrinESINTRACOMUNITARIO_CLIENTE_FACTURA: TcxGridDBColumn
              Caption = 'Intracomunitario'
              DataBinding.FieldName = 'ESINTRACOMUNITARIO_CLIENTE_FAC'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 159
            end
            object cxGrdDBTabPrinTARIFA_ARTICULO_CLIENTE_FACTURA: TcxGridDBColumn
              Caption = 'C'#243'digo Tarifa Art'#237'culos'
              DataBinding.FieldName = 'TARIFA_ARTICULO_CLIENTE_FAC'
              Width = 200
            end
            object cxGrdDBTabPrinPALABRA_REPORTS_ZONA_IVA_FACTURA: TcxGridDBColumn
              Caption = 'Palabra IVA'
              DataBinding.FieldName = 'PALABRA_REPORTS_ZONA_IVA_FAC'
              Visible = False
              Width = 106
            end
            object cxGrdDBTabPrinCODIGO_IVA_FACTURA: TcxGridDBColumn
              Caption = 'C'#243'digo IVA Borrador'
              DataBinding.FieldName = 'CODIGO_IVA_FAC'
              Visible = False
              Width = 186
            end
            object cxGrdDBTabPrinVENTA_ACTIVO_FIJO_FACTURA: TcxGridDBColumn
              Caption = 'Es Venta Activo Fijo (REAGP)'
              DataBinding.FieldName = 'VENTA_ACTIVO_FIJO_FACTURA'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Visible = False
              Width = 265
            end
            object cxGrdDBTabPrinTOTAL_BASES_FACTURA: TcxGridDBColumn
              Caption = 'Total Bases Imponibles'
              DataBinding.FieldName = 'TOTAL_BASES_FAC'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 199
            end
            object cxGrdDBTabPrinTOTAL_IMPUESTOS_FACTURA: TcxGridDBColumn
              Caption = 'Total Impuestos'
              DataBinding.FieldName = 'TOTAL_IMPUESTOS_FAC'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 146
            end
            object cxGrdDBTabPrinCONTADOR_LINEAS_FACTURA: TcxGridDBColumn
              Caption = 'Ult Nro Linea Borrador'
              DataBinding.FieldName = 'CONTADOR_LINEAS_FAC'
              Visible = False
              Width = 183
            end
            object cxgrdbclmnGrdDBTabPrinESRETENCIONES_EMPRESA_FACTURA: TcxGridDBColumn
              Caption = 'Empresa tiene IRPF'
              DataBinding.FieldName = 'ESRETENCIONES_EMPRESA_FAC'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Visible = False
              Width = 172
            end
            object cxgrdbclmnGrdDBTabPrinGRUPO_ZONA_IVA_EMPRESA_FACTURA: TcxGridDBColumn
              Caption = 'Zona IVA Empresa'
              DataBinding.FieldName = 'GRUPO_ZONA_IVA_EMPRESA_FAC'
              Visible = False
              Width = 164
            end
            object cxgrdbclmnGrdDBTabPrinESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA: TcxGridDBColumn
              Caption = 'Empresa es REAGP'
              DataBinding.FieldName = 'ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 166
            end
            object cxgrdbclmnGrdDBTabPrinESIVA_RECARGO_CLIENTE_FACTURA: TcxGridDBColumn
              Caption = 'Cliente tiene RE'
              DataBinding.FieldName = 'ESIVA_RECARGO_CLIENTE_FAC'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 156
            end
            object cxgrdbclmnGrdDBTabPrinESIMP_INCL_TARIFA_CLIENTE_FACTURA: TcxGridDBColumn
              Caption = 'Precios Tarifa con Impuestos'
              DataBinding.FieldName = 'ESIMP_INCL_TARIFA_CLIENTE_FAC'
              Visible = False
              Width = 263
            end
            object cxgrdbclmnGrdDBTabPrinESIRPF_IMP_INCL_ZONA_IVA_FACTURA: TcxGridDBColumn
              Caption = 'IRPF con Imp Incl (REAGP)'
              DataBinding.FieldName = 'ESIRPF_IMP_INCL_ZONA_IVA_FAC'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Visible = False
            end
            object cxgrdbclmnGrdDBTabPrinESAPLICA_RE_ZONA_IVA_FACTURA: TcxGridDBColumn
              Caption = 'Tiene RE'
              DataBinding.FieldName = 'ESAPLICA_RE_ZONA_IVA_FAC'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Visible = False
              Width = 96
            end
            object cxgrdbclmnGrdDBTabPrinESVENTA_ACTIVO_FIJO_FACTURA: TcxGridDBColumn
              Caption = 'Venta Activo Fijo REAGP'
              DataBinding.FieldName = 'ESVENTA_ACTIVO_FIJO_FAC'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 216
            end
            object cxgrdbclmnGrdDBTabPrinESDESCRIPCIONES_AMP_FACTURA: TcxGridDBColumn
              Caption = 'Tiene Descripciones Ampliadas'
              DataBinding.FieldName = 'ESDESCRIPCIONES_AMP_FAC'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Visible = False
              Width = 297
            end
            object cxgrdbclmnGrdDBTabPrinESFECHADEENTREGA_FACTURA: TcxGridDBColumn
              Caption = 'Tiene Fecha de Entrega'
              DataBinding.FieldName = 'ESFECHADEENTREGA_FAC'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Visible = False
              Width = 226
            end
            object cxgrdbclmnGrdDBTabPrinESREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA: TcxGridDBColumn
              Caption = 'Cliente es REAGP'
              DataBinding.FieldName = 'ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Visible = False
              Width = 164
            end
            object cxgrdbclmnGrdDBTabPrinESIVAAGRICOLA_ZONA_IVA_FACTURA: TcxGridDBColumn
              Caption = 'Es IVA Agricola'
              DataBinding.FieldName = 'ESIVAAGRICOLA_ZONA_IVA_FAC'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Visible = False
              Width = 138
            end
            object dbcGrdDBTabPrinESCONSOLIDADA_FACTURA: TcxGridDBColumn
              Caption = 'Consolidada'
              DataBinding.FieldName = 'ESCONSOLIDADA_FAC'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 157
            end
            object dbcGrdDBTabPrinINSTANTECONSO_FACTURA: TcxGridDBColumn
              Caption = 'Instante Consolidaci'#243'n'#13#10
              DataBinding.FieldName = 'INSTANTECONSO_FAC'
              PropertiesClassName = 'TcxDateEditProperties'
            end
            object cxgrdbclmnGrdDBTabPrinESTADO_VERIFACTU: TcxGridDBColumn
              Caption = 'Cola Verifactu'
              DataBinding.FieldName = 'ESTADO_VFCOLA'
              Options.Editing = False
              Width = 120
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        Margins.Left = 5
        Margins.Top = 5
        Margins.Right = 5
        Margins.Bottom = 5
        ExplicitLeft = 4
        ExplicitTop = 28
        ExplicitWidth = 1079
        ExplicitHeight = 772
        object pnlVerifactu: TPanel
          Left = 0
          Top = 345
          Width = 1079
          Height = 427
          Margins.Left = 4
          Margins.Top = 4
          Margins.Right = 4
          Margins.Bottom = 4
          Align = alClient
          BevelOuter = bvNone
          ParentColor = True
          TabOrder = 2
          object pcDetail: TcxPageControl
            Left = 0
            Top = 0
            Width = 1079
            Height = 427
            Margins.Left = 4
            Margins.Top = 4
            Margins.Right = 4
            Margins.Bottom = 4
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsLineasFactura
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 423
            ClientRectLeft = 4
            ClientRectRight = 1075
            ClientRectTop = 28
            object tsLineasFactura: TcxTabSheet
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              Caption = '&1_Lineas de Borrador - '
              ImageIndex = 1
              object pnlBotonesAcciones: TPanel
                Left = 0
                Top = 0
                Width = 1071
                Height = 38
                Align = alTop
                BevelOuter = bvNone
                TabOrder = 2
                object btnAnadirLinea: TcxButton
                  Left = 4
                  Top = 6
                  Width = 110
                  Height = 26
                  Caption = 'A'#241'adir l'#237'nea'
                  TabOrder = 0
                  OnClick = btnAnadirLineaClick
                end
                object btnBorrarLinea: TcxButton
                  Left = 120
                  Top = 6
                  Width = 110
                  Height = 26
                  Caption = 'Borrar l'#237'nea'
                  TabOrder = 1
                  OnClick = btnBorrarLineaClick
                end
              end
              object cxgrdLineasFactura: TcxGrid
                Left = 0
                Top = 38
                Width = 891
                Height = 357
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Align = alClient
                TabOrder = 0
                object tvLineasFactura: TcxGridDBTableView
                  OnKeyDown = tvLineasFacturaKeyDown
                  Navigator.Buttons.ConfirmDelete = True
                  Navigator.Visible = True
                  DataController.DataModeController.SmartRefresh = True
                  DataController.DataSource = dmFacturas.dsLinFac
                  DataController.Options = [dcoCaseInsensitive, dcoAssignGroupingValues, dcoAssignMasterDetailKeys, dcoSaveExpanding, dcoGroupsAlwaysExpanded, dcoInsertOnNewItemRowFocusing]
                  DataController.Summary.FooterSummaryItems = <
                    item
                      Format = '#,##0.00 '#8364
                      Kind = skSum
                      Column = ctbTOTAL_FACTURA_LINEA
                    end
                    item
                      Format = '#,##.00'
                      Kind = skSum
                      Column = ctbCANTIDAD_FACTURA_LINEA
                    end
                    item
                      Format = '#,##0.00 '#8364
                      Kind = skSum
                      Column = ctbTOTAL_FACTURASIVA_LINEA
                    end>
                  FixedDataRows.SeparatorColor = clBlack
                  NewItemRow.InfoText = 'Click aqu'#237' para a'#241'adir fila'
                  NewItemRow.Visible = True
                  OptionsBehavior.FocusCellOnTab = True
                  OptionsBehavior.FocusFirstCellOnNewRecord = True
                  OptionsBehavior.GoToNextCellOnEnter = True
                  OptionsBehavior.FocusCellOnCycle = True
                  OptionsCustomize.ColumnGrouping = False
                  OptionsCustomize.DataRowFixing = True
                  OptionsData.Appending = True
                  OptionsSelection.InvertSelect = False
                  OptionsView.NoDataToDisplayInfoText = '<No hay datos a mostrar>'
                  OptionsView.GroupByBox = False
                  object ctbLINEA_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Nro Linea'
                    DataBinding.FieldName = 'LINEA_FACLIN'
                    PropertiesClassName = 'TcxTextEditProperties'
                    Width = 104
                  end
                  object ctbCODIGO_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'C'#243'digo Art'#237'culo'
                    DataBinding.FieldName = 'CODIGO_ART_FACLIN'
                    PropertiesClassName = 'TcxButtonEditProperties'
                    Properties.Buttons = <
                      item
                        Default = True
                        Kind = bkEllipsis
                      end>
                    Properties.OnButtonClick = cxgrdbclmntv1CODIGO_ARTICULO_FACTURA_LINEAPropertiesButtonClick
                    Properties.OnEditValueChanged = cxgrdbclmntv1CODIGO_ARTICULO_FACTURA_LINEAPropertiesEditValueChanged
                    Width = 152
                  end
                  object ctbCODIGO_UNIDAD_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'SKU'
                    DataBinding.FieldName = 'CODIGO_UNIDAD_FACLIN'
                    PropertiesClassName = 'TcxComboBoxProperties'
                    Properties.OnEditValueChanged = ctbCODIGO_UNIDAD_FACTURA_LINEAPropertiesEditValueChanged
                    Properties.OnInitPopup = ctbCODIGO_UNIDAD_FACTURA_LINEAPropertiesInitPopup
                    Visible = False
                    Width = 180
                  end
                  object ctbDESCRIPCION_VARIACION_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Variaci'#243'n'
                    DataBinding.FieldName = 'DESCRIPCION_VARIACION_FACLIN'
                    PropertiesClassName = 'TcxTextEditProperties'
                    Visible = False
                    Width = 140
                  end
                  object ctbCODIGO_FAMILIA_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'C'#243'digo Familia'
                    DataBinding.FieldName = 'CODIGO_FAM_FACLIN'
                    PropertiesClassName = 'TcxButtonEditProperties'
                    Properties.Buttons = <
                      item
                        Default = True
                        Kind = bkEllipsis
                      end>
                    Visible = False
                    Width = 153
                  end
                  object ctbNOMBRE_FAMILIA_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Nombre Familia'
                    DataBinding.FieldName = 'NOMBRE_FAM_FACLIN'
                    PropertiesClassName = 'TcxTextEditProperties'
                    Visible = False
                    Width = 245
                  end
                  object ctbESPROVEEDORPRINCIPAL_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Proveedor Principal'
                    DataBinding.FieldName = 'ESPROVEEDORPRINCIPAL_FACLIN'
                    PropertiesClassName = 'TcxCheckBoxProperties'
                    Visible = False
                    Width = 172
                  end
                  object ctbCODIGO_PROVEEDOR_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'C'#243'digo Proveedor'
                    DataBinding.FieldName = 'CODIGO_PRV_FACLIN'
                    PropertiesClassName = 'TcxTextEditProperties'
                    Visible = False
                    Width = 163
                  end
                  object ctbRAZONSOCIAL_PROVEEDOR_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Raz'#243'n Social Proveedor'
                    DataBinding.FieldName = 'RAZON_SOCIAL_PROVEEDOR_FACLIN'
                    PropertiesClassName = 'TcxTextEditProperties'
                    Visible = False
                    Width = 200
                  end
                  object ctbPRECIO_ULT_COMPRA_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Precio Coste'
                    DataBinding.FieldName = 'PRECIO_ULT_COMPRA_FACLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Visible = False
                  end
                  object ctbDESCRIPCION_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Descripci'#243'n'
                    DataBinding.FieldName = 'DESCRIPCION_ARTICULO_FACLIN'
                    PropertiesClassName = 'TcxMemoProperties'
                    Properties.MaxLength = 1000
                    Properties.ScrollBars = ssBoth
                    Properties.VisibleLineCount = 3
                    MinWidth = 0
                    VisibleForEditForm = bTrue
                    Width = 300
                  end
                  object ctbTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Tipo Cantidad'
                    DataBinding.FieldName = 'TIPO_CANTIDAD_ARTICULO_FACLIN'
                    Width = 136
                  end
                  object ctbCANTIDAD_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Cantidad'
                    DataBinding.FieldName = 'CANTIDAD_FACLIN'
                    PropertiesClassName = 'TcxSpinEditProperties'
                    Properties.OnEditValueChanged = cxgrdbclmntv1CANTIDAD_FACTURA_LINEAPropertiesEditValueChanged
                    Width = 90
                  end
                  object ctbPRECIOSALIDA_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Precio Salida'
                    DataBinding.FieldName = 'PRECIO_SALIDA_FACLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.OnEditValueChanged = tvLineasFacturaPRECIOSALIDA_FACTURA_LINEAPropertiesEditValueChanged
                  end
                  object ctbPORCEN_DTO_FACTURA_LINEA: TcxGridDBColumn
                    Caption = '% Dto'
                    DataBinding.FieldName = 'PORCENTAJE_DTO_FACLIN'
                    PropertiesClassName = 'TcxSpinEditProperties'
                    Properties.DisplayFormat = '0.00 %'
                    Properties.EditFormat = '0.00 %'
                    Properties.MaxValue = 100.000000000000000000
                    Properties.OnEditValueChanged = tvLineasFacturaPORCEN_DTO_FACTURA_LINEAPropertiesEditValueChanged
                  end
                  object ctbPRECIO_DTO_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Menos Dto'
                    DataBinding.FieldName = 'PRECIO_DTO_FACLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.OnEditValueChanged = tvLineasFacturaPRECIO_DTO_FACTURA_LINEAPropertiesEditValueChanged
                  end
                  object ctbPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Precio Ud. sin IVA'
                    DataBinding.FieldName = 'PRECIO_VENTA_SIVA_ARTICULO_FACLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = False
                    Properties.OnEditValueChanged = cxgrdbclmntv1PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEAPropertiesEditValueChanged
                    Width = 162
                  end
                  object ctbIMP_INCL_TARIFA_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'ImpIncl'
                    DataBinding.FieldName = 'ESIMP_INCL_TARIFA_FACLIN'
                    PropertiesClassName = 'TcxCheckBoxProperties'
                    Properties.ReadOnly = True
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    Visible = False
                    Width = 79
                  end
                  object ctbTIPOIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Tipo de IVA'
                    DataBinding.FieldName = 'TIPO_IVA_ARTICULO_FACLIN'
                    PropertiesClassName = 'TcxLookupComboBoxProperties'
                    Properties.DropDownListStyle = lsFixedList
                    Properties.KeyFieldNames = 'CODIGO_ABREVIATURA_IVA_IVATIP'
                    Properties.ListColumns = <
                      item
                        Caption = 'Tipo de IVA'
                        FieldName = 'NOMBRE_TIPO_IVA_IVATIP'
                      end>
                    Properties.ListOptions.ShowHeader = False
                    Properties.ListSource = dmFacturas.dsIvasTipos
                    Properties.ReadOnly = False
                    Properties.OnChange = cxgrdbclmntv1TIPOIVA_ARTICULO_FACTURA_LINEAPropertiesChange
                    Width = 109
                  end
                  object ctbPORCEN_IVA_FACTURA_LINEA: TcxGridDBColumn
                    Caption = '% IVA'
                    DataBinding.FieldName = 'PORCENTAJE_IVA_FACLIN'
                    PropertiesClassName = 'TcxSpinEditProperties'
                    Properties.DisplayFormat = '0.00 %'
                    Properties.EditFormat = '0.00 %'
                    Properties.ReadOnly = False
                    Width = 79
                  end
                  object ctbPRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Precio Ud. con IVA'
                    DataBinding.FieldName = 'PRECIO_VENTA_CIVA_ARTICULO_FACLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = False
                    Properties.OnEditValueChanged = cxgrdbclmntv1PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEAPropertiesEditValueChanged
                    Width = 166
                  end
                  object ctbTOTAL_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Total con IVA'
                    DataBinding.FieldName = 'TOTAL_FACLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Width = 172
                  end
                  object ctbTOTAL_FACTURASIVA_LINEA: TcxGridDBColumn
                    Caption = 'Total Sin IVA'
                    DataBinding.FieldName = 'TOTAL_FAC_SIVA_FACLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.OnEditValueChanged = ctbTOTAL_FACTURASIVA_LINEAPropertiesEditValueChanged
                    Width = 125
                  end
                  object ctbFECHA_ENTREGA_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Fecha Entrega'
                    DataBinding.FieldName = 'FECHA_ENTREGA_FACLIN'
                    PropertiesClassName = 'TcxDateEditProperties'
                    Properties.DateButtons = [btnClear, btnToday]
                    Properties.DisplayFormat = 'dd/mm/yyyy'
                    Properties.EditFormat = 'dd/mm/yyyy'
                  end
                end
                object tv2: TcxGridDBBandedTableView
                  Navigator.Visible = True
                  DataController.DetailKeyFieldNames = 'AppointmentId'
                  DataController.KeyFieldNames = 'PerId'
                  DataController.MasterKeyFieldNames = 'AppointmentId'
                  OptionsView.GroupByBox = False
                  Bands = <
                    item
                      Width = 958
                    end>
                  object cxgrdbndclmntv2PerId: TcxGridDBBandedColumn
                    DataBinding.FieldName = 'PerId'
                    Width = 37
                    Position.BandIndex = 0
                    Position.ColIndex = 0
                    Position.RowIndex = 0
                  end
                  object cxgrdbndclmntv2AppointmentId: TcxGridDBBandedColumn
                    DataBinding.FieldName = 'AppointmentId'
                    Width = 81
                    Position.BandIndex = 0
                    Position.ColIndex = 1
                    Position.RowIndex = 0
                  end
                  object cxgrdbndclmntv2Linea: TcxGridDBBandedColumn
                    DataBinding.FieldName = 'Linea'
                    Width = 44
                    Position.BandIndex = 0
                    Position.ColIndex = 2
                    Position.RowIndex = 0
                  end
                  object cxgrdbndclmntv2clave: TcxGridDBBandedColumn
                    DataBinding.FieldName = 'clave'
                    Width = 126
                    Position.BandIndex = 0
                    Position.ColIndex = 3
                    Position.RowIndex = 0
                  end
                  object cxgrdbndclmntv2valor: TcxGridDBBandedColumn
                    DataBinding.FieldName = 'valor'
                    Width = 146
                    Position.BandIndex = 0
                    Position.ColIndex = 4
                    Position.RowIndex = 0
                  end
                  object cxgrdbndclmntv2instantemodif: TcxGridDBBandedColumn
                    DataBinding.FieldName = 'instante_modif'
                    Width = 137
                    Position.BandIndex = 0
                    Position.ColIndex = 7
                    Position.RowIndex = 0
                  end
                  object cxgrdbndclmntv2descripcion: TcxGridDBBandedColumn
                    DataBinding.FieldName = 'descripcion'
                    Width = 178
                    Position.BandIndex = 0
                    Position.ColIndex = 5
                    Position.RowIndex = 0
                  end
                  object cxgrdbndclmntv2parte: TcxGridDBBandedColumn
                    DataBinding.FieldName = 'parte'
                    Width = 209
                    Position.BandIndex = 0
                    Position.ColIndex = 6
                    Position.RowIndex = 0
                  end
                end
                object cxgrdlvlLineasFactura: TcxGridLevel
                  GridView = tvLineasFactura
                end
              end
              object pnlRightLineas: TPanel
                Left = 891
                Top = 38
                Width = 180
                Height = 357
                Align = alRight
                BevelOuter = bvNone
                TabOrder = 1
                object chkFechaEntrega: TcxDBCheckBox
                  Left = 10
                  Top = 20
                  Caption = 'Fecha de Entrega'
                  DataBinding.DataField = 'ESFECHADEENTREGA_FAC'
                  DataBinding.DataSource = dsTablaG
                  Properties.ValueChecked = 'S'
                  Properties.ValueUnchecked = 'N'
                  Properties.OnChange = chkFechaEntregaPropertiesChange
                  Style.TransparentBorder = False
                  TabOrder = 0
                  Transparent = True
                end
                object chkDescripcion_ampliada: TcxDBCheckBox
                  Left = 10
                  Top = 49
                  Caption = 'Desc. Ampliada'
                  DataBinding.DataField = 'ESDESCRIPCIONES_AMP_FAC'
                  DataBinding.DataSource = dsTablaG
                  Properties.ValueChecked = 'S'
                  Properties.ValueUnchecked = 'N'
                  Properties.OnChange = chkDescripcion_ampliadaPropertiesChange
                  Style.TransparentBorder = False
                  TabOrder = 1
                  Transparent = True
                end
                object btnExportarLineas: TcxButton
                  Left = 7
                  Top = 120
                  Width = 167
                  Height = 34
                  Caption = 'E&xp Excel'
                  TabOrder = 3
                  OnClick = btnExportarLineasClick
                end
                object btnIraArticulo: TcxButton
                  Left = 7
                  Top = 160
                  Width = 167
                  Height = 34
                  Caption = 'I&r a Art'#237'culo'
                  TabOrder = 4
                  OnClick = btnIraArticuloClick
                end
                object btnCalculator: TcxButton
                  Left = 7
                  Top = 200
                  Width = 24
                  Height = 25
                  Hint = 'Calculadora'
                  OptionsImage.Glyph.SourceDPI = 96
                  OptionsImage.Glyph.Data = {
                    89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
                    610000001974455874536F6674776172650041646F626520496D616765526561
                    647971C9653C0000001F744558745469746C650043616C63756C6174696F6E3B
                    43616C63756C6174696F6E733BF443BC3C000001FE49444154785E9592CF6B13
                    5110C7BF9B6C543C08E2C183D7A48A170F8AE0A569AAA7C67AF32F10515210A1
                    08ED59C49FA752D083770F828762C14BDA18F1EA4D68936AD3BA5643526DD676
                    DB8664C637B3FBB2293988C3BE7DEFB3F366E63BC33A2F5F7F2A2592C92CFED3
                    BADD4EF9E6F5F397DD7ADDCF4E17B26030D418B1290E1A11E3FECCC23080842B
                    C0CC785CAE87011C47D240B80326C6C4C5E312A31F5CD9E5585D6FE1D2991338
                    9C7270249594BB885E7A396877B1BFDFC5C7CF0DB0494064134419BC8D2D548E
                    1D02096BD0807E55E479BEFA285640DAFFABC2B9B01EDB38213B993EBE722A4A
                    4EEA7089C26A73C50AAC5D1B3D8DB985E51E5FCD0DA13E3FD9E393F967205270
                    120CD21E7FFC6C61DC046E985658A47EDFC2782E836FDE6F2DBE59ABE06C7A17
                    CDD52530707088B27C3FC0D31725C0F29F004F9EBF074533DAF177F0EECD52E8
                    EC9F01111900266FD97F8975DDBB1DB123C4B830558C7CCA7AB20A14DF2EC633
                    C88F0C61BED4CF99033C369206132B248859616DFD17F2A6E7D5B54D006CF6A6
                    B998C1D75A53ABADD41A18CBA651FDD290C2FD33606DC1DF0EF06876D10AD419
                    3C9C2D1A94CBC0766B170F6684211CB7200A644D1572B1C3F0F4C428180E4233
                    7C47187014D92A60B7BABC52BE71D71BD68FEAB64E076CCFF2F47291748E4E3B
                    F800A023114701A46C72DDFF6D0CA00D60EF2F70DB422AC97AB57F0000000049
                    454E44AE426082}
                  TabOrder = 5
                  OnClick = btnCalculatorClick
                end
              end
              object splLineasDerecha: TcxSplitter
                Left = 883
                Top = 38
                Width = 8
                Height = 357
                Hint = 'Mostrar u ocultar las opciones de las l'#237'neas'
                HotZoneClassName = 'TcxMediaPlayer9Style'
                HotZone.SizePercent = 50
                AlignSplitter = salRight
                Control = pnlRightLineas
                ParentShowHint = False
                ShowHint = True
              end
            end
            object tsTotales: TcxTabSheet
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              Caption = '&2_Totales'
              ImageIndex = 2
              object scrTotales: TcxScrollBox
                HorzScrollBar.Margin = 12
                VertScrollBar.Tracking = True
                VertScrollBar.Margin = 12
                AutoScroll = True
                Left = 0
                Top = 0
                Width = 1071
                Height = 395
                Align = alClient
                BorderStyle = cxcbsNone
                TabOrder = 0
                object lblVentaDtoComercial: TcxLabel
                  Properties.Alignment.Vert = taVCenter
                  Properties.Alignment.Horz = taRightJustify
                  Width = 206
                  Height = 24
                  AutoSize = False
                  Left = 16
                  Top = 194
                  Caption = 'Dto. comercial'
                  TabOrder = 33
                  Transparent = True
                end
                object spnVentaPORCENTAJE_DTO_COMERCIAL_FAC: TcxDBSpinEdit
                  Left = 230
                  Top = 194
                  DataBinding.DataField = 'PORCENTAJE_DTO_COMERCIAL_FAC'
                  DataBinding.DataSource = dsTablaG
                  Properties.AssignedValues.MinValue = True
                  Properties.DisplayFormat = '0.00 %'
                  Properties.EditFormat = '0.00 %'
                  Properties.ImmediatePost = True
                  Properties.OnEditValueChanged = DescuentosDocumentoCambiados
                  Properties.MaxValue = 100.000000000000000000
                  TabOrder = 34
                  Width = 86
                end
                object curVentaTOTAL_DTO_COMERCIAL_FAC: TcxDBCurrencyEdit
                  Left = 322
                  Top = 194
                  DataBinding.DataField = 'TOTAL_DTO_COMERCIAL_FAC'
                  DataBinding.DataSource = dsTablaG
                  Properties.DisplayFormat = '#,##0.00 '#8364
                  Properties.ReadOnly = True
                  TabOrder = 35
                  Width = 95
                end
                object lblVentaDtoFinanciero: TcxLabel
                  Properties.Alignment.Vert = taVCenter
                  Properties.Alignment.Horz = taRightJustify
                  Width = 206
                  Height = 24
                  AutoSize = False
                  Left = 16
                  Top = 226
                  Caption = 'Dto. financiero'
                  TabOrder = 36
                  Transparent = True
                end
                object spnVentaPORCENTAJE_DTO_FINANCIERO_FAC: TcxDBSpinEdit
                  Left = 230
                  Top = 226
                  DataBinding.DataField = 'PORCENTAJE_DTO_FINANCIERO_FAC'
                  DataBinding.DataSource = dsTablaG
                  Properties.AssignedValues.MinValue = True
                  Properties.DisplayFormat = '0.00 %'
                  Properties.EditFormat = '0.00 %'
                  Properties.ImmediatePost = True
                  Properties.OnEditValueChanged = DescuentosDocumentoCambiados
                  Properties.MaxValue = 100.000000000000000000
                  TabOrder = 37
                  Width = 86
                end
                object curVentaTOTAL_DTO_FINANCIERO_FAC: TcxDBCurrencyEdit
                  Left = 322
                  Top = 226
                  DataBinding.DataField = 'TOTAL_DTO_FINANCIERO_FAC'
                  DataBinding.DataSource = dsTablaG
                  Properties.DisplayFormat = '#,##0.00 '#8364
                  Properties.ReadOnly = True
                  TabOrder = 38
                  Width = 95
                end
                object lblTotalaPagar: TcxLabel
                  Properties.Alignment.Vert = taVCenter
                  Properties.Alignment.Horz = taRightJustify
                  Width = 206
                  Height = 24
                  AutoSize = False
                  Left = 16
                  Top = 146
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Total a pagar'
                  TabOrder = 2
                  Transparent = True
                end
                object curTotalAPagar: TcxDBCurrencyEdit
                  Left = 230
                  Top = 146
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'TOTAL_LIQUIDO_FAC'
                  DataBinding.DataSource = dsTablaG
                  Properties.DisplayFormat = '#,##0.00 '#8364
                  Properties.ReadOnly = True
                  Properties.UseThousandSeparator = True
                  TabOrder = 11
                  Width = 133
                end
                object curTOTAL_LIQUIDO_FACTURA: TcxDBCurrencyEdit
                  Left = 230
                  Top = 114
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'TOTAL_RETENCION_FAC'
                  DataBinding.DataSource = dsTablaG
                  Properties.DisplayFormat = '#,##0.00 '#8364
                  Properties.ReadOnly = True
                  TabOrder = 4
                  Width = 133
                end
                object lblTotalRetencionFactura: TcxLabel
                  Properties.Alignment.Vert = taVCenter
                  Properties.Alignment.Horz = taRightJustify
                  Width = 206
                  Height = 24
                  AutoSize = False
                  Left = 16
                  Top = 114
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Total Retenci'#243'n Borrador'
                  TabOrder = 7
                  Transparent = True
                end
                object lblPorcRetencionFactura: TcxLabel
                  Properties.Alignment.Vert = taVCenter
                  Properties.Alignment.Horz = taRightJustify
                  Width = 206
                  Height = 24
                  AutoSize = False
                  Left = 16
                  Top = 82
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = '% Retenci'#243'n Borrador'
                  TabOrder = 8
                  Transparent = True
                end
                object spnRetencion: TcxDBSpinEdit
                  Left = 230
                  Top = 82
                  DataBinding.DataField = 'PORCENTAJE_RETENCION_FAC'
                  DataBinding.DataSource = dsTablaG
                  Properties.AssignedValues.MinValue = True
                  Properties.DisplayFormat = '0.00 %'
                  Properties.EditFormat = '0.00 %'
                  Properties.MaxValue = 100.000000000000000000
                  Properties.ReadOnly = False
                  TabOrder = 3
                  Width = 133
                end
                object curTOTAL_RETENCION_FACTURA: TcxDBCurrencyEdit
                  Left = 230
                  Top = 18
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'TOTAL_BASES_FAC'
                  DataBinding.DataSource = dsTablaG
                  Properties.DisplayFormat = '#,##0.00 '#8364
                  Properties.DecimalPlaces = 2
                  Properties.ReadOnly = True
                  TabOrder = 0
                  Width = 133
                end
                object lblTotalBaseImponible: TcxLabel
                  Properties.Alignment.Vert = taVCenter
                  Properties.Alignment.Horz = taRightJustify
                  Width = 206
                  Height = 24
                  AutoSize = False
                  Left = 16
                  Top = 18
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Total Base Imponible'
                  TabOrder = 9
                  Transparent = True
                end
                object curTOTAL_BASES_FACTURA: TcxDBCurrencyEdit
                  Left = 230
                  Top = 50
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'TOTAL_IMPUESTOS_FAC'
                  DataBinding.DataSource = dsTablaG
                  Properties.DecimalPlaces = 2
                  Properties.DisplayFormat = '#,##0.00 '#8364
                  Properties.ReadOnly = True
                  TabOrder = 1
                  Width = 133
                end
                object lbl1TotalImpuestos: TcxLabel
                  Properties.Alignment.Vert = taVCenter
                  Properties.Alignment.Horz = taRightJustify
                  Width = 206
                  Height = 24
                  AutoSize = False
                  Left = 16
                  Top = 50
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Total Impuestos'
                  TabOrder = 10
                  Transparent = True
                end
                object lblFormadePago: TcxLabel
                  Properties.Alignment.Vert = taVCenter
                  Properties.Alignment.Horz = taRightJustify
                  Height = 24
                  Width = 206
                  AutoSize = False
                  Left = 16
                  Top = 270
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Forma de Pago'
                  TabOrder = 12
                  Transparent = True
                end
                object cbbFORMAPAGO: TcxDBLookupComboBox
                  Left = 230
                  Top = 270
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'FORMA_PAGO_FAC'
                  DataBinding.DataSource = dsTablaG
                  Properties.DropDownSizeable = True
                  Properties.KeyFieldNames = 'CODIGO_FP_FP'
                  Properties.ListColumns = <
                    item
                      Caption = 'C'#243'digo'
                      MinWidth = 50
                      Width = 50
                      FieldName = 'CODIGO_FP_FP'
                    end
                    item
                      Caption = 'Descripci'#243'n'
                      MinWidth = 100
                      Width = 100
                      FieldName = 'DESCRIPCION_FORMA_PAGO_FP'
                    end>
                  Properties.ListOptions.CaseInsensitive = True
                  TabOrder = 5
                  OnKeyUp = cbbSerieFacturaKeyUp
                  Width = 195
                end
                object btnGenerarRecibos: TcxButton
                  Left = 230
                  Top = 304
                  Width = 195
                  Height = 25
                  Caption = 'Generar &Recibo/s'
                  TabOrder = 6
                  OnClick = btnGenerarRecibosClick
                end
                object lblTotalesTotalPrendas: TcxLabel
                  Properties.Alignment.Vert = taVCenter
                  Properties.Alignment.Horz = taRightJustify
                  Height = 24
                  Width = 206
                  AutoSize = False
                  Left = 16
                  Top = 352
                  Caption = 'N'#186' de prendas'
                  TabOrder = 14
                  Transparent = True
                end
                object lblTotalPrendasFactura: TcxLabel
                  Left = 230
                  Top = 352
                  AutoSize = False
                  Caption = '0'
                  TabOrder = 15
                  Transparent = True
                  Height = 20
                  Width = 133
                end
                object grpDesgloseImpuestos: TcxGroupBox
                  Left = 432
                  Top = 10
                  Width = 617
                  Height = 350
                  Caption = 'Desglose Impuestos'
                  TabOrder = 13
                  object shpSeparador1: TShape
                    Left = 12
                    Top = 32
                    Width = 512
                    Height = 40
                    Brush.Style = bsClear
                  end
                  object shpSeparador2: TShape
                    Left = 12
                    Top = 71
                    Width = 512
                    Height = 50
                    Brush.Style = bsClear
                  end
                  object shpSeparador3: TShape
                    Left = 12
                    Top = 169
                    Width = 512
                    Height = 50
                    Brush.Style = bsClear
                  end
                  object shpSeparador4: TShape
                    Left = 12
                    Top = 120
                    Width = 512
                    Height = 50
                    Brush.Style = bsClear
                  end
                  object shpSeparador5: TShape
                    Left = 12
                    Top = 218
                    Width = 512
                    Height = 50
                    Brush.Style = bsClear
                  end
                  object lblTotRE: TcxLabel
                    Properties.Alignment.Vert = taVCenter
                    Properties.Alignment.Horz = taCenter
                    AutoSize = False
                    Height = 24
                    Width = 75
                    Left = 442
                    Top = 40
                    Caption = 'Total R.E.'
                    TabOrder = 0
                    Transparent = True
                  end
                  object PorRE: TcxLabel
                    Properties.Alignment.Vert = taVCenter
                    Properties.Alignment.Horz = taCenter
                    AutoSize = False
                    Height = 24
                    Width = 53
                    Left = 388
                    Top = 40
                    Caption = '%R.E.'
                    TabOrder = 1
                    Transparent = True
                  end
                  object lblTotIVA: TcxLabel
                    Properties.Alignment.Vert = taVCenter
                    Properties.Alignment.Horz = taCenter
                    AutoSize = False
                    Height = 24
                    Width = 86
                    Left = 296
                    Top = 40
                    Caption = 'Total IVA'
                    TabOrder = 2
                    Transparent = True
                  end
                  object lblPorIVA: TcxLabel
                    Properties.Alignment.Vert = taVCenter
                    Properties.Alignment.Horz = taCenter
                    AutoSize = False
                    Height = 24
                    Width = 55
                    Left = 238
                    Top = 40
                    Caption = '%IVA'
                    TabOrder = 3
                    Transparent = True
                  end
                  object lblBaseNeta: TcxLabel
                    Properties.Alignment.Vert = taVCenter
                    Properties.Alignment.Horz = taCenter
                    AutoSize = False
                    Height = 24
                    Width = 92
                    Left = 145
                    Top = 40
                    Caption = 'BaseNeta'
                    TabOrder = 4
                    Transparent = True
                  end
                  object lblNormal: TcxLabel
                    Properties.Alignment.Vert = taVCenter
                    Properties.Alignment.Horz = taLeftJustify
                    AutoSize = False
                    Height = 24
                    Width = 125
                    Left = 16
                    Top = 80
                    Caption = 'Normal'
                    TabOrder = 5
                    Transparent = True
                  end
                  object lblReducido: TcxLabel
                    Properties.Alignment.Vert = taVCenter
                    Properties.Alignment.Horz = taLeftJustify
                    AutoSize = False
                    Height = 24
                    Width = 125
                    Left = 16
                    Top = 128
                    Caption = 'Reducido'
                    TabOrder = 6
                    Transparent = True
                  end
                  object lblSReducido: TcxLabel
                    Properties.Alignment.Vert = taVCenter
                    Properties.Alignment.Horz = taLeftJustify
                    AutoSize = False
                    Height = 24
                    Width = 125
                    Left = 16
                    Top = 176
                    Caption = 'S'#250'per Reducido'
                    TabOrder = 7
                    Transparent = True
                  end
                  object lblExento: TcxLabel
                    Properties.Alignment.Vert = taVCenter
                    Properties.Alignment.Horz = taLeftJustify
                    AutoSize = False
                    Height = 24
                    Width = 125
                    Left = 16
                    Top = 224
                    Caption = 'Exento'
                    TabOrder = 8
                    Transparent = True
                  end
                  object curTOTAL_BASEI_IVAN_FAC: TcxDBCurrencyEdit
                    Left = 145
                    Top = 80
                    DataBinding.DataField = 'TOTAL_BASEI_IVAN_FAC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 9
                    Width = 92
                  end
                  object curTOTAL_BASEI_IVAR_FAC: TcxDBCurrencyEdit
                    Left = 145
                    Top = 128
                    DataBinding.DataField = 'TOTAL_BASEI_IVAR_FAC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 10
                    Width = 92
                  end
                  object curTOTAL_BASEI_IVAS_FAC: TcxDBCurrencyEdit
                    Left = 145
                    Top = 176
                    DataBinding.DataField = 'TOTAL_BASEI_IVAS_FAC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 11
                    Width = 92
                  end
                  object curTOTAL_BASEI_IVAE_FAC: TcxDBCurrencyEdit
                    Left = 145
                    Top = 224
                    DataBinding.DataField = 'TOTAL_BASEI_IVAE_FAC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 12
                    Width = 92
                  end
                  object curTOTAL_IVAN_FAC: TcxDBCurrencyEdit
                    Left = 296
                    Top = 80
                    DataBinding.DataField = 'TOTAL_IVAN_FAC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 13
                    Width = 86
                  end
                  object curTOTAL_IVAR_FAC: TcxDBCurrencyEdit
                    Left = 296
                    Top = 128
                    DataBinding.DataField = 'TOTAL_IVAR_FAC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 14
                    Width = 86
                  end
                  object curTOTAL_IVAS_FAC: TcxDBCurrencyEdit
                    Left = 296
                    Top = 176
                    DataBinding.DataField = 'TOTAL_IVAS_FAC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 15
                    Width = 86
                  end
                  object curTOTAL_IVAE_FAC: TcxDBCurrencyEdit
                    Left = 296
                    Top = 224
                    DataBinding.DataField = 'TOTAL_IVAE_FAC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 16
                    Width = 86
                  end
                  object curTOTAL_REN_FAC: TcxDBCurrencyEdit
                    Left = 442
                    Top = 80
                    DataBinding.DataField = 'TOTAL_REN_FAC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 17
                    Width = 75
                  end
                  object curTOTAL_RER_FAC: TcxDBCurrencyEdit
                    Left = 442
                    Top = 128
                    DataBinding.DataField = 'TOTAL_RER_FAC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 18
                    Width = 75
                  end
                  object curTOTAL_RES_FAC: TcxDBCurrencyEdit
                    Left = 442
                    Top = 176
                    DataBinding.DataField = 'TOTAL_RES_FAC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 19
                    Width = 75
                  end
                  object curTOTAL_REE_FAC: TcxDBCurrencyEdit
                    Left = 442
                    Top = 224
                    DataBinding.DataField = 'TOTAL_REE_FAC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 20
                    Width = 75
                  end
                  object spnPORCENTAJE_IVAN_FAC: TcxDBSpinEdit
                    Left = 238
                    Top = 80
                    DataBinding.DataField = 'PORCENTAJE_IVAN_FAC'
                    DataBinding.DataSource = dsTablaG
                    Properties.AssignedValues.MinValue = True
                    Properties.DisplayFormat = '0 %'
                    Properties.EditFormat = '0 %'
                    Properties.MaxValue = 100.000000000000000000
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 21
                    Width = 55
                  end
                  object spnPORCENTAJE_IVAR_FAC: TcxDBSpinEdit
                    Left = 238
                    Top = 128
                    DataBinding.DataField = 'PORCENTAJE_IVAR_FAC'
                    DataBinding.DataSource = dsTablaG
                    Properties.AssignedValues.MinValue = True
                    Properties.DisplayFormat = '0 %'
                    Properties.EditFormat = '0 %'
                    Properties.MaxValue = 100.000000000000000000
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 22
                    Width = 55
                  end
                  object spnPORCENTAJE_IVAS_FAC: TcxDBSpinEdit
                    Left = 238
                    Top = 176
                    DataBinding.DataField = 'PORCENTAJE_IVAS_FAC'
                    DataBinding.DataSource = dsTablaG
                    Properties.AssignedValues.MinValue = True
                    Properties.DisplayFormat = '0 %'
                    Properties.EditFormat = '0 %'
                    Properties.MaxValue = 100.000000000000000000
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 23
                    Width = 55
                  end
                  object spnPORCENTAJE_IVAE_FAC: TcxDBSpinEdit
                    Left = 238
                    Top = 224
                    DataBinding.DataField = 'PORCENTAJE_IVAE_FAC'
                    DataBinding.DataSource = dsTablaG
                    Properties.AssignedValues.MinValue = True
                    Properties.DisplayFormat = '0 %'
                    Properties.EditFormat = '0 %'
                    Properties.MaxValue = 100.000000000000000000
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 24
                    Width = 55
                  end
                  object spnPORCENTAJE_RER_FAC: TcxDBSpinEdit
                    Left = 388
                    Top = 128
                    DataBinding.DataField = 'PORCENTAJE_RER_FAC'
                    DataBinding.DataSource = dsTablaG
                    Properties.AssignedValues.MinValue = True
                    Properties.DisplayFormat = '0.00 %'
                    Properties.EditFormat = '0.00 %'
                    Properties.MaxValue = 100.000000000000000000
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 25
                    Width = 53
                  end
                  object spnPORCENTAJE_REN_FAC: TcxDBSpinEdit
                    Left = 388
                    Top = 80
                    DataBinding.DataField = 'PORCENTAJE_REN_FAC'
                    DataBinding.DataSource = dsTablaG
                    Properties.AssignedValues.MinValue = True
                    Properties.DisplayFormat = '0.00 %'
                    Properties.EditFormat = '0.00 %'
                    Properties.MaxValue = 100.000000000000000000
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 26
                    Width = 53
                  end
                  object spnPORCENTAJE_RES_FAC: TcxDBSpinEdit
                    Left = 388
                    Top = 176
                    DataBinding.DataField = 'PORCENTAJE_RES_FAC'
                    DataBinding.DataSource = dsTablaG
                    Properties.AssignedValues.MinValue = True
                    Properties.DisplayFormat = '0.00 %'
                    Properties.EditFormat = '0.00 %'
                    Properties.MaxValue = 100.000000000000000000
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 27
                    Width = 53
                  end
                  object spnPORCENTAJE_REE_FAC: TcxDBSpinEdit
                    Left = 388
                    Top = 224
                    DataBinding.DataField = 'PORCENTAJE_REE_FAC'
                    DataBinding.DataSource = dsTablaG
                    Properties.AssignedValues.MinValue = True
                    Properties.DisplayFormat = '0.00 %'
                    Properties.EditFormat = '0.00 %'
                    Properties.MaxValue = 100.000000000000000000
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 28
                    Width = 53
                  end
                  object chkESIRPF_IMP_INCL_ZONA_IVA_FACTURA: TcxDBCheckBox
                    Left = 16
                    Top = 278
                    Caption = 'C'#225'lculo IRPF con impuestos (S'#243'lo REAGP)'
                    DataBinding.DataField = 'ESIRPF_IMP_INCL_ZONA_IVA_FAC'
                    DataBinding.DataSource = dsTablaG
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    Style.TransparentBorder = False
                    TabOrder = 29
                    Transparent = True
                  end
                  object chkESVENTA_ACTIVO_FIJO_FACTURA: TcxDBCheckBox
                    Left = 16
                    Top = 310
                    Caption = 'Venta de Activo Fijo --Maquinaria, Aperos-- (S'#243'lo REAGP)'
                    DataBinding.DataField = 'ESVENTA_ACTIVO_FIJO_FAC'
                    DataBinding.DataSource = dsTablaG
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    Style.TransparentBorder = False
                    TabOrder = 30
                    Transparent = True
                  end
                end
              end
            end
            object tsRecibos: TcxTabSheet
              Caption = '&3_Recibos'
              ImageIndex = 4
              ExplicitLeft = 0
              ExplicitTop = 0
              ExplicitWidth = 0
              ExplicitHeight = 0
              object pnlRightRecibos: TPanel
                Left = 918
                Top = 0
                Width = 153
                Height = 395
                Align = alRight
                BevelOuter = bvNone
                TabOrder = 1
                object btnReciboDevuelto: TcxButton
                  Left = 27
                  Top = 77
                  Width = 98
                  Height = 25
                  Caption = '&Devuelto'
                  TabOrder = 2
                end
                object btnImprimirRecibo: TcxButton
                  Left = 3
                  Top = 113
                  Width = 146
                  Height = 25
                  Caption = 'Imprimir &Recibo'
                  TabOrder = 3
                  OnClick = btnImprimirReciboClick
                end
                object btnReciboEmitido: TcxButton
                  Left = 27
                  Top = 47
                  Width = 98
                  Height = 25
                  Caption = '&Emitido'
                  TabOrder = 1
                end
                object btnReciboPagado: TcxButton
                  Left = 27
                  Top = 17
                  Width = 98
                  Height = 25
                  Caption = '&Pagado'
                  TabOrder = 0
                  OnClick = btnReciboPagadoClick
                end
                object btnExportarRecibos: TcxButton
                  Left = 3
                  Top = 152
                  Width = 146
                  Height = 32
                  Caption = 'E&xp Excel'
                  TabOrder = 4
                  OnClick = btnExportarRecibosClick
                end
                object btnGenerarRecibos2: TcxButton
                  Left = 3
                  Top = 190
                  Width = 152
                  Height = 25
                  Caption = 'Generar &Recibo/s'
                  TabOrder = 5
                  OnClick = btnGenerarRecibosClick
                end
              end
              object pnlBodyRecibos: TPanel
                Left = 0
                Top = 0
                Width = 918
                Height = 395
                Align = alClient
                BevelOuter = bvNone
                TabOrder = 0
                object cxgrdRecibos: TcxGrid
                  Left = 0
                  Top = 0
                  Width = 918
                  Height = 395
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Align = alClient
                  TabOrder = 0
                  object tvRecibos: TcxGridDBTableView
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
                        Format = '#,##0.00 '#8364
                        Kind = skSum
                        Column = cxgrdbclmnRecibosEUROS_RECIBO
                      end>
                    OptionsBehavior.AlwaysShowEditor = True
                    OptionsBehavior.GoToNextCellOnEnter = True
                    OptionsBehavior.IncSearch = True
                    OptionsCustomize.ColumnHiding = True
                    OptionsData.Appending = True
                    OptionsView.Footer = True
                    OptionsView.GroupByBox = False
                    OptionsView.Indicator = True
                    object cxgrdbclmnRecibosNRO_FACTURA_RECIBO: TcxGridDBColumn
                      Caption = 'Nro Borrador Recibo'
                      DataBinding.FieldName = 'NUMERO_FAC_REC'
                      Visible = False
                      VisibleForCustomization = False
                    end
                    object cxgrdbclmnRecibosSERIE_FACTURA_RECIBO: TcxGridDBColumn
                      Caption = 'Serie Borrador Recibo'
                      DataBinding.FieldName = 'SERIE_FAC_REC'
                      Visible = False
                      VisibleForCustomization = False
                    end
                    object cxgrdbclmnRecibosNRO_PLAZO_RECIBO: TcxGridDBColumn
                      Caption = 'Nro Plazo'
                      DataBinding.FieldName = 'NUMERO_PLAZO_REC'
                      Width = 134
                    end
                    object cxgrdbclmnRecibosFORMA_PAGO_ORIGEN_RECIBO: TcxGridDBColumn
                      Caption = 'Forma de Pago Origen'
                      DataBinding.FieldName = 'FORMA_PAGO_ORIGEN_RECIBO_REC'
                      Width = 265
                    end
                    object cxgrdbclmnRecibosFORMA_PAGO_DESCRIPCION_ORIGEN_RECIBO: TcxGridDBColumn
                      Caption = 'Forma de Pago Actual'
                      DataBinding.FieldName = 'FORMA_PAGO_DESCRIPCION_ORIGEN_RECIBO_REC'
                      Width = 217
                    end
                    object cxgrdbclmnRecibosEUROS_RECIBO: TcxGridDBColumn
                      Caption = 'Total Recibo'
                      DataBinding.FieldName = 'EUROS_RECIBO_REC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Properties.DisplayFormat = '#,##0.00 '#8364
                      Width = 115
                    end
                    object cxgrdbclmnRecibosESTADO_RECIBO: TcxGridDBColumn
                      Caption = 'Estado Recibo'
                      DataBinding.FieldName = 'ESTADO_RECIBO_REC'
                      Width = 134
                    end
                    object cxgrdbclmnRecibosFECHA_EXPEDICION_RECIBO: TcxGridDBColumn
                      Caption = 'Fecha Expedici'#243'n Recibo'
                      DataBinding.FieldName = 'FECHA_EXPEDICION_RECIBO_REC'
                      Width = 213
                    end
                    object cxgrdbclmnRecibosFECHA_VENCIMIENTO_RECIBO: TcxGridDBColumn
                      Caption = 'Fecha Vencimiento'
                      DataBinding.FieldName = 'FECHA_VENCIMIENTO_RECIBO_REC'
                      Width = 163
                    end
                    object cxgrdbclmnRecibosIBAN_CLIENTE_RECIBO: TcxGridDBColumn
                      Caption = 'Nro Cuenta IBAN'
                      DataBinding.FieldName = 'IBAN_CLI_REC'
                      Width = 272
                    end
                    object cxgrdbclmnRecibosFECHA_PAGO_RECIBO: TcxGridDBColumn
                      Caption = 'Fecha Pago Recibo'
                      DataBinding.FieldName = 'FECHA_PAGO_RECIBO_REC'
                      Width = 160
                    end
                    object cxgrdbclmnRecibosLOCALIDAD_EXPEDICION_RECIBO: TcxGridDBColumn
                      Caption = 'Localidad Expedici'#243'n'
                      DataBinding.FieldName = 'LOCALIDAD_EXPEDICION_RECIBO_REC'
                      Width = 184
                    end
                    object cxgrdbclmnRecibosCODIGO_CLIENTE_RECIBO: TcxGridDBColumn
                      Caption = 'C'#243'digo Cliente'
                      DataBinding.FieldName = 'CODIGO_CLI_REC'
                      Width = 131
                    end
                    object cxgrdbclmnRecibosRAZONSOCIAL_CLIENTE_RECIBO: TcxGridDBColumn
                      Caption = 'Raz'#243'n Social Cliente'
                      DataBinding.FieldName = 'RAZON_SOCIAL_CLI_REC'
                      Width = 268
                    end
                    object cxgrdbclmnRecibosDIRECCION1_CLIENTE_RECIBO: TcxGridDBColumn
                      Caption = 'Direcci'#243'n Cliente'
                      DataBinding.FieldName = 'DIRECCION1_CLIENTE_RECIBO_REC'
                      Width = 256
                    end
                    object cxgrdbclmnRecibosPOBLACION_CLIENTE_RECIBO: TcxGridDBColumn
                      Caption = 'Poblaci'#243'n Cliente'
                      DataBinding.FieldName = 'POBLACION_CLI_REC'
                      Width = 246
                    end
                    object cxgrdbclmnRecibosPROVINCIA_CLIENTE_RECIBO: TcxGridDBColumn
                      Caption = 'Provincia Cliente'
                      DataBinding.FieldName = 'PROVINCIA_CLI_REC'
                      Width = 242
                    end
                    object cxgrdbclmnRecibosCPOSTAL_CLIENTE_RECIBO: TcxGridDBColumn
                      Caption = 'C'#243'digo Postal Cliente'
                      DataBinding.FieldName = 'CODIGO_POSTAL_CLI_REC'
                      Width = 186
                    end
                    object cxgrdbclmnRecibosIMPORTE_LETRA_RECIBO: TcxGridDBColumn
                      Caption = 'Importe Letra'
                      DataBinding.FieldName = 'IMPORTE_LETRA_RECIBO_REC'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Properties.DisplayFormat = '#,##0.00 '#8364
                      Width = 366
                    end
                  end
                  object cxgrdlvlRecibos: TcxGridLevel
                    GridView = tvRecibos
                  end
                end
              end
            end
            object tsOtros: TcxTabSheet
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              Caption = '&4_Otros'
              ImageIndex = 4
              ExplicitLeft = 0
              ExplicitTop = 0
              ExplicitWidth = 0
              ExplicitHeight = 0
              object scrOtros: TcxScrollBox
                VertScrollBar.Tracking = True
                LookAndFeel.ScrollbarMode = sbmClassic
                Left = 0
                Top = 0
                Width = 1071
                Height = 395
                Align = alClient
                TabOrder = 0
                object lblComentarios: TcxLabel
                  Left = 32
                  Top = 65
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Comentarios'
                  TabOrder = 0
                  Transparent = True
                end
                object mmodbComentarios: TcxDBMemo
                  Left = 32
                  Top = 92
                  DataBinding.DataField = 'COMENTARIOS_FAC'
                  DataBinding.DataSource = dsTablaG
                  Properties.ScrollBars = ssVertical
                  TabOrder = 1
                  Height = 149
                  Width = 733
                end
                object lblTipoOperVerifactu: TcxLabel
                  Left = 32
                  Top = 250
                  Caption = 'Operaci'#243'n (Verifactu)'
                  TabOrder = 3
                  Transparent = True
                end
                object cbbTipoOperVerifactu: TcxDBLookupComboBox
                  Left = 200
                  Top = 247
                  DataBinding.DataField = 'TIPO_OPER_VFACTU_FAC'
                  DataBinding.DataSource = dsTablaG
                  Properties.KeyFieldNames = 'CODIGO_VFO'
                  Properties.ListColumns = <
                    item
                      Caption = 'Operaci'#243'n'
                      FieldName = 'DESCRIPCION_VFO'
                    end>
                  Properties.ListOptions.CaseInsensitive = True
                  Properties.ListOptions.ShowHeader = False
                  TabOrder = 4
                  Width = 300
                end
                object lblTipoOperVerifactuAyuda: TcxLabel
                  Left = 32
                  Top = 276
                  AutoSize = False
                  Caption =
                    'Calificaci'#243'n de la operaci'#243'n para Verifactu. D'#233'jelo vac'#237'o para v' +
                    'entas interiores normales (la exportaci'#243'n se asigna sola si el c' +
                    'liente no es de la UE). Para clientes de la UE elija servicio, e' +
                    'ntrega de bienes o ISP. Los tipos se gestionan en la tabla fza_v' +
                    'erifactu_operaciones.'
                  Properties.WordWrap = True
                  TabOrder = 5
                  Transparent = True
                  Height = 100
                  Width = 733
                end
                object pnlUserInstantBottom: TcxGroupBox
                  Left = 0
                  Top = 392
                  Width = 765
                  Height = 79
                  TabOrder = 2
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
              end
            end
            object tsVerifactu: TcxTabSheet
              Caption = '&5_Verifactu'
              ImageIndex = 4
              object scrlbxVerifactu: TcxScrollBox
                Left = 0
                Top = 0
                Width = 1071
                Height = 395
                VertScrollBar.Position = 26
                Align = alClient
                TabOrder = 0
                object lblPETICION_COMPLETA: TcxLabel
                  Left = 44
                  Top = 586
                  Width = 157
                  Height = 17
                  Caption = 'PETICION_COMPLETA'
                  Transparent = True
                end
                object lblRESPUESTA_COMPLETA: TcxLabel
                  Left = 43
                  Top = 34
                  Width = 173
                  Height = 17
                  Caption = 'RESPUESTA_COMPLETA'
                  FocusControl = cxdbmRESPUESTA_COMPLETA
                  Transparent = True
                end
                object lblQRCODE_BASE64: TcxLabel
                  Left = 74
                  Top = 517
                  Width = 127
                  Height = 17
                  Caption = 'QRCODE_BASE64'
                  FocusControl = cxdbmQRCODE_BASE64
                  Transparent = True
                end
                object lblVERIFACTU_URL: TcxLabel
                  Left = 80
                  Top = 450
                  Width = 124
                  Height = 17
                  Caption = 'VERIFACTU_URL'
                  FocusControl = cxdbmVERIFACTU_URL
                  Transparent = True
                end
                object lblCHAIN_HASH: TcxLabel
                  Left = 101
                  Top = 384
                  Width = 101
                  Height = 17
                  Caption = 'CHAIN_HASH'
                  FocusControl = txtCHAIN_HASH
                  Transparent = True
                end
                object lblCHAIN_NUMBER: TcxLabel
                  Left = 92
                  Top = 335
                  Width = 123
                  Height = 17
                  Caption = 'CHAIN_NUMBER'
                  FocusControl = txtCHAIN_NUMBER
                  Transparent = True
                end
                object lblISSUED_TIME: TcxLabel
                  Left = 121
                  Top = 287
                  Width = 96
                  Height = 17
                  Caption = 'ISSUED_TIME'
                  FocusControl = dteISSUED_TIME
                  Transparent = True
                end
                object lblISSUER_IRS_ID: TcxLabel
                  Left = 108
                  Top = 238
                  Width = 109
                  Height = 17
                  Caption = 'ISSUER_IRS_ID'
                  FocusControl = txtISSUER_IRS_ID
                  Transparent = True
                end
                object lblQUEUE_ID: TcxLabel
                  Left = 142
                  Top = 190
                  Width = 75
                  Height = 17
                  Caption = 'QUEUE_ID'
                  FocusControl = spQUEUE_ID
                  Transparent = True
                end
                object lblREQUEST_ID: TcxLabel
                  Left = 125
                  Top = 141
                  Width = 92
                  Height = 17
                  Caption = 'REQUEST_ID'
                  FocusControl = txtREQUEST_ID
                  Transparent = True
                end
                object lbl: TcxLabel
                  Left = 61
                  Top = -6
                  Width = 87
                  Height = 17
                  Caption = 'ID_FACCON'
                  FocusControl = spID_CONSOLIDACION
                  Transparent = True
                end
                object lblFECHA_PROCESAMIENTO: TcxLabel
                  Left = 446
                  Top = 198
                  Width = 186
                  Height = 17
                  Caption = 'FECHA_PROCESAMIENTO'
                  FocusControl = dteFECHA_PROCESAMIENTO
                  Transparent = True
                end
                object lblESTADO: TcxLabel
                  Left = 386
                  Top = -6
                  Width = 60
                  Height = 17
                  Caption = 'ESTADO'
                  FocusControl = txtESTADO
                  Transparent = True
                end
                object spQUEUE_ID: TcxDBSpinEdit
                  Left = 240
                  Top = 182
                  DataBinding.DataField = 'QUEUE_ID_CONSOLIDACION_FACCON'
                  DataBinding.DataSource = dmFacturas.dsConsolidacion
                  Properties.ReadOnly = True
                  TabOrder = 0
                  Width = 121
                end
                object cxdbmRESPUESTA_COMPLETA: TcxDBMemo
                  Left = 240
                  Top = 30
                  DataBinding.DataField = 'RESPUESTA_COMPLETA_FACCON'
                  DataBinding.DataSource = dmFacturas.dsConsolidacion
                  Properties.ReadOnly = True
                  TabOrder = 1
                  Height = 89
                  Width = 402
                end
                object cxdbmQRCODE_BASE64: TcxDBMemo
                  Left = 227
                  Top = 491
                  DataBinding.DataField = 'QRCODE_BASE64_FACCON'
                  DataBinding.DataSource = dmFacturas.dsConsolidacion
                  Properties.ReadOnly = True
                  TabOrder = 2
                  Height = 44
                  Width = 665
                end
                object cxdbmVERIFACTU_URL: TcxDBMemo
                  Left = 227
                  Top = 424
                  DataBinding.DataField = 'VERIFACTU_URL_FACCON'
                  Properties.ReadOnly = True
                  TabOrder = 3
                  Height = 44
                  Width = 665
                end
                object txtCHAIN_HASH: TcxDBTextEdit
                  Left = 227
                  Top = 376
                  DataBinding.DataField = 'CHAIN_HASH_FACCON'
                  DataBinding.DataSource = dmFacturas.dsConsolidacion
                  Properties.ReadOnly = True
                  TabOrder = 4
                  Width = 665
                end
                object txtCHAIN_NUMBER: TcxDBTextEdit
                  Left = 240
                  Top = 327
                  DataBinding.DataField = 'CHAIN_NUMBER_FACCON'
                  DataBinding.DataSource = dmFacturas.dsConsolidacion
                  Properties.ReadOnly = True
                  TabOrder = 5
                  Width = 121
                end
                object dteISSUED_TIME: TcxDBDateEdit
                  Left = 240
                  Top = 279
                  DataBinding.DataField = 'ISSUED_TIME_FACCON'
                  DataBinding.DataSource = dmFacturas.dsConsolidacion
                  Properties.ReadOnly = True
                  TabOrder = 6
                  Width = 121
                end
                object txtISSUER_IRS_ID: TcxDBTextEdit
                  Left = 240
                  Top = 230
                  DataBinding.DataField = 'ISSUER_IRS_ID_CONSOLIDACION_FACCON'
                  DataBinding.DataSource = dmFacturas.dsConsolidacion
                  Properties.ReadOnly = True
                  TabOrder = 7
                  Width = 153
                end
                object imgQRCODE_PNG: TcxDBImage
                  Left = 648
                  Top = -9
                  DataBinding.DataField = 'QRCODE_PNG_FACCON'
                  DataBinding.DataSource = dmFacturas.dsConsolidacion
                  Properties.FitMode = ifmProportionalStretch
                  Properties.GraphicClassName = 'TdxPNGImage'
                  Properties.ReadOnly = True
                  TabOrder = 8
                  Height = 176
                  Width = 196
                end
                object txtREQUEST_ID: TcxDBTextEdit
                  Left = 240
                  Top = 133
                  DataBinding.DataField = 'REQUEST_ID_CONSOLIDACION_FACCON'
                  DataBinding.DataSource = dmFacturas.dsConsolidacion
                  Properties.ReadOnly = True
                  TabOrder = 9
                  Width = 402
                end
                object spID_CONSOLIDACION: TcxDBSpinEdit
                  Left = 240
                  Top = -12
                  DataBinding.DataField = 'ID_FACCON'
                  DataBinding.DataSource = dmFacturas.dsConsolidacion
                  Properties.ReadOnly = True
                  TabOrder = 10
                  Width = 121
                end
                object cxdbmPETICION_COMPLETA_FACCON: TcxDBMemo
                  Left = 227
                  Top = 561
                  DataBinding.DataField = 'PETICION_COMPLETA_FACCON'
                  DataBinding.DataSource = dmFacturas.dsConsolidacion
                  Properties.ReadOnly = True
                  TabOrder = 11
                  Height = 44
                  Width = 954
                end
                object dteFECHA_PROCESAMIENTO: TcxDBDateEdit
                  Left = 659
                  Top = 190
                  DataBinding.DataField = 'FECHA_PROCESAMIENTO_FACCON'
                  DataBinding.DataSource = dmFacturas.dsConsolidacion
                  Properties.DisplayFormat = 'dd/mm/yyyy hh:nn:ss'
                  Properties.Kind = ckDateTime
                  Properties.ReadOnly = True
                  TabOrder = 12
                  Width = 185
                end
                object txtESTADO: TcxDBTextEdit
                  Left = 467
                  Top = -12
                  DataBinding.DataField = 'ESTADO_FACCON'
                  DataBinding.DataSource = dmFacturas.dsConsolidacion
                  Properties.ReadOnly = True
                  TabOrder = 13
                  Width = 126
                end
                object btnIrAVerifactu: TcxButton
                  Left = 900
                  Top = 424
                  Width = 130
                  Height = 34
                  Caption = 'Ir a Verifactu'
                  TabOrder = 20
                  OnClick = btnIrAVerifactuClick
                end
                object btnVerifactuAnular: TcxButton
                  Left = 859
                  Top = 53
                  Width = 140
                  Height = 34
                  Caption = 'Anular fiscal'
                  TabOrder = 14
                  OnClick = btnVerifactuAnularClick
                end
                object btnVerifactuFacturar: TcxButton
                  Left = 859
                  Top = 93
                  Width = 175
                  Height = 34
                  Caption = 'Convertir en normal'
                  TabOrder = 15
                  OnClick = btnVerifactuFacturarClick
                end
                object btnVolverBorrador: TcxButton
                  Left = 859
                  Top = 12
                  Width = 148
                  Height = 34
                  Caption = 'Volver a Borrador'
                  TabOrder = 16
                  OnClick = btnVolverBorradorClick
                end
                object btnVerifactuResolverIncidencia: TcxButton
                  Left = 859
                  Top = 133
                  Width = 175
                  Height = 34
                  Caption = 'Resolver incidencia'
                  TabOrder = 17
                  Visible = False
                  OnClick = btnVerifactuResolverIncidenciaClick
                end
                object btnVerifactuSubsanar: TcxButton
                  Left = 859
                  Top = 173
                  Width = 175
                  Height = 34
                  Caption = 'Subsanar registro'
                  TabOrder = 21
                  Visible = False
                  OnClick = btnVerifactuSubsanarClick
                end
                object btnVerifactuCancelarSubsanacion: TcxButton
                  Left = 859
                  Top = 213
                  Width = 175
                  Height = 34
                  Caption = 'Cancelar subsanaci'#243'n'
                  TabOrder = 22
                  Visible = False
                  OnClick = btnVerifactuCancelarSubsanacionClick
                end
              end
            end
            object tsRegistro: TcxTabSheet
              Caption = '&6_Registro Verifactu'
              ImageIndex = 5
              ExplicitLeft = 0
              ExplicitTop = 0
              ExplicitWidth = 0
              ExplicitHeight = 0
              object cxgrdLogVerifactu: TcxGrid
                Left = 0
                Top = 0
                Width = 1071
                Height = 395
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Align = alClient
                TabOrder = 0
                object tvLogVerifactu: TcxGridDBTableView
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
                  DataController.DataSource = dmFacturas.dsErrores
                  DataController.Options = [dcoCaseInsensitive, dcoAssignGroupingValues, dcoAssignMasterDetailKeys, dcoSaveExpanding]
                  DataController.Summary.FooterSummaryItems = <
                    item
                      Format = '#,##0.00 '#8364
                      Kind = skSum
                    end>
                  OptionsBehavior.AlwaysShowEditor = True
                  OptionsBehavior.GoToNextCellOnEnter = True
                  OptionsBehavior.IncSearch = True
                  OptionsCustomize.ColumnHiding = True
                  OptionsData.Appending = True
                  OptionsView.Footer = True
                  OptionsView.GroupByBox = False
                  OptionsView.Indicator = True
                  object tvLogVerifactuTIMESTAMP_LOG: TcxGridDBColumn
                    Caption = 'Fecha Hora'
                    DataBinding.FieldName = 'TIMESTAMP_LOG'
                  end
                  object tvLogVerifactuDESCRIPCION_LOG: TcxGridDBColumn
                    Caption = 'Evento'
                    DataBinding.FieldName = 'DESCRIPCION_LOG'
                    Width = 308
                  end
                  object tvLogVerifactuDATOS_ADICIONALES_LOG: TcxGridDBColumn
                    Caption = 'Datos adicionales'
                    DataBinding.FieldName = 'DATOS_ADICIONALES_LOG'
                    Width = 868
                  end
                  object tvLogVerifactuNRO_FACTURA_LOG: TcxGridDBColumn
                    DataBinding.FieldName = 'NUMERO_FAC_LOG'
                    Visible = False
                  end
                  object tvLogVerifactuSERIE_FACTURA_LOG: TcxGridDBColumn
                    DataBinding.FieldName = 'SERIE_FAC_LOG'
                    Visible = False
                  end
                end
                object cxgrdlvlLogVerifactu: TcxGridLevel
                  GridView = tvLogVerifactu
                end
              end
            end
            object tsMovimientosFac: TcxTabSheet
              Caption = '&7_Movimientos'
              ImageIndex = 5
              ExplicitLeft = 0
              ExplicitTop = 0
              ExplicitWidth = 0
              ExplicitHeight = 0
              object cxGrdMovimientosFac: TcxGrid
                Left = 0
                Top = 0
                Width = 1071
                Height = 395
                Align = alClient
                TabOrder = 0
                object tvMovimientosFac: TcxGridDBTableView
                  OptionsData.Editing = False
                  OptionsView.GroupByBox = False
                  object cxgrdcMovFacNum: TcxGridDBColumn
                    Caption = 'N'#250'mero Mov.'
                    DataBinding.FieldName = 'NUMERO_MOV'
                    Width = 110
                  end
                  object cxgrdcMovFacFec: TcxGridDBColumn
                    Caption = 'Fecha'
                    DataBinding.FieldName = 'FECHA_MOV'
                    Width = 130
                  end
                  object cxgrdcMovFacLin: TcxGridDBColumn
                    Caption = 'L'#237'nea'
                    DataBinding.FieldName = 'LINEA_MOV'
                    Width = 60
                  end
                  object cxgrdcMovFacAlm: TcxGridDBColumn
                    Caption = 'Almac'#233'n'
                    DataBinding.FieldName = 'NOMBRE_ALMACEN_ORIGEN'
                    Width = 140
                  end
                  object cxgrdcMovFacArt: TcxGridDBColumn
                    Caption = 'Art'#237'culo'
                    DataBinding.FieldName = 'CODIGO_ART_MOV'
                    Width = 100
                  end
                  object cxgrdcMovFacSku: TcxGridDBColumn
                    Caption = 'SKU'
                    DataBinding.FieldName = 'CODIGO_UNIDAD_MOV'
                    Width = 140
                  end
                  object cxgrdcMovFacDescr: TcxGridDBColumn
                    Caption = 'Descripci'#243'n'
                    DataBinding.FieldName = 'DESCRIPCION_ARTICULO_MOV'
                    Width = 200
                  end
                  object cxgrdcMovFacTipo: TcxGridDBColumn
                    Caption = 'Tipo'
                    DataBinding.FieldName = 'TIPO_MOV'
                    Width = 50
                  end
                  object cxgrdcMovFacCant: TcxGridDBColumn
                    Caption = 'Cantidad'
                    DataBinding.FieldName = 'CANTIDAD_MOV'
                    Width = 90
                  end
                  object cxgrdcMovFacPMP: TcxGridDBColumn
                    Caption = 'PMP'
                    DataBinding.FieldName = 'PRECIO_MEDIO_MOV'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Width = 90
                  end
                  object cxgrdcMovFacTot: TcxGridDBColumn
                    Caption = 'Total Coste'
                    DataBinding.FieldName = 'TOTAL_COSTE_MOV'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = '#,##0.00 '#8364
                    Width = 100
                  end
                end
                object cxGrdMovimientosFacLevel: TcxGridLevel
                  GridView = tvMovimientosFac
                end
              end
            end
          end
        end
        object pnlTopFicha: TPanel
          Left = 0
          Top = 0
          Width = 1079
          Height = 337
          Margins.Left = 4
          Margins.Top = 4
          Margins.Right = 4
          Margins.Bottom = 4
          Align = alTop
          BevelOuter = bvNone
          ParentColor = True
          TabOrder = 0
          object pnlBodyFicha: TPanel
            Left = 0
            Top = 0
            Width = 1079
            Height = 337
            Margins.Left = 4
            Margins.Top = 4
            Margins.Right = 4
            Margins.Bottom = 4
            Align = alClient
            BevelEdges = []
            BevelOuter = bvNone
            ParentColor = True
            TabOrder = 0
            object pcCab: TcxPageControl
              Left = 0
              Top = 0
              Width = 1079
              Height = 337
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              Align = alClient
              ParentBackground = False
              TabOrder = 0
              Properties.ActivePage = tsCabecera
              Properties.CustomButtons.Buttons = <>
              ClientRectBottom = 333
              ClientRectLeft = 4
              ClientRectRight = 1075
              ClientRectTop = 28
              object tsCabecera: TcxTabSheet
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Caption = '&Cabecera Borrador '
                ImageIndex = 0
                object lblNroFactura: TcxLabel
                  Left = 5
                  Top = 12
                  AutoSize = False
                  Properties.Alignment.Horz = taRightJustify
                  Properties.Alignment.Vert = taVCenter
                  Height = 24
                  Width = 142
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Nro Borrador'
                  TabOrder = 1
                  Transparent = True
                end
                object lblFechaFactura: TcxLabel
                  Left = 5
                  Top = 196
                  AutoSize = False
                  Properties.Alignment.Horz = taRightJustify
                  Properties.Alignment.Vert = taVCenter
                  Height = 24
                  Width = 142
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Fecha'
                  TabOrder = 3
                  Transparent = True
                end
                object dteFECHA_FACTURA: TcxDBDateEdit
                  Left = 155
                  Top = 196
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'FECHA_FAC'
                  DataBinding.DataSource = dsTablaG
                  Properties.DateButtons = [btnClear, btnToday]
                  Properties.OnEditValueChanged = dteFECHA_FACTURAPropertiesEditValueChanged
                  TabOrder = 10
                  OnKeyUp = dteFECHA_FACTURAKeyUp
                  Width = 143
                end
                object lblSerieFactura: TcxLabel
                  Left = 5
                  Top = 150
                  AutoSize = False
                  Properties.Alignment.Horz = taRightJustify
                  Properties.Alignment.Vert = taVCenter
                  Height = 24
                  Width = 142
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Serie Borrador'
                  TabOrder = 6
                  Transparent = True
                end
                object btnCODIGO_CLIENTE: TcxDBButtonEdit
                  Left = 155
                  Top = 105
                  DataBinding.DataField = 'CODIGO_CLI_FAC'
                  DataBinding.DataSource = dsTablaG
                  Properties.Buttons = <
                    item
                      Default = True
                      Kind = bkEllipsis
                    end>
                  Properties.OnButtonClick = btnCODIGO_CLIENTEPropertiesButtonClick
                  Properties.OnChange = btnCODIGO_CLIENTEPropertiesChange
                  Properties.OnEditValueChanged = btnCODIGO_CLIENTEPropertiesEditValueChanged
                  TabOrder = 4
                  OnKeyUp = btnCODIGO_CLIENTEKeyUp
                  Width = 166
                end
                object lblCodigoCliente: TcxLabel
                  Left = 5
                  Top = 105
                  AutoSize = False
                  Properties.Alignment.Horz = taRightJustify
                  Properties.Alignment.Vert = taVCenter
                  Height = 24
                  Width = 142
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'C'#243'digo Cliente'
                  TabOrder = 7
                  Transparent = True
                end
                object lbldbRAZONSOCIAL_EMPRESA_FACTURA: TcxDBLabel
                  Left = 337
                  Top = 59
                  DataBinding.DataField = 'RAZON_SOCIAL_EMPRESA_FAC'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 8
                  Transparent = True
                  Height = 21
                  Width = 332
                end
                object lbldbRAZONSOCIAL_CLIENTE_FACTURA: TcxDBLabel
                  Left = 337
                  Top = 106
                  DataBinding.DataField = 'RAZON_SOCIAL_CLIENTE_FAC'
                  DataBinding.DataSource = dsTablaG
                  ParentFont = False
                  Style.Font.Charset = DEFAULT_CHARSET
                  Style.Font.Color = clWindowText
                  Style.Font.Height = -15
                  Style.Font.Name = 'Source Sans 3'
                  Style.Font.Style = []
                  Style.IsFontAssigned = True
                  TabOrder = 9
                  Transparent = True
                  Height = 21
                  Width = 412
                end
                object btnCODIGO_EMPRESA_FACTURA: TcxDBButtonEdit
                  Left = 155
                  Top = 58
                  DataBinding.DataField = 'CODIGO_EMP_FAC'
                  DataBinding.DataSource = dsTablaG
                  Properties.Buttons = <
                    item
                      Default = True
                      Kind = bkEllipsis
                    end>
                  Properties.OnButtonClick = btnCODIGO_EMPRESA_FACTURAPropertiesButtonClick
                  Properties.OnChange = btnCODIGO_EMPRESA_FACTURAPropertiesChange
                  Properties.OnEditValueChanged = btnCODIGO_EMPRESA_FACTURAPropertiesEditValueChanged
                  TabOrder = 2
                  Width = 166
                end
                object lblCodigoEmpresa: TcxLabel
                  Left = 5
                  Top = 58
                  AutoSize = False
                  Properties.Alignment.Horz = taRightJustify
                  Properties.Alignment.Vert = taVCenter
                  Height = 24
                  Width = 142
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'C'#243'digo Empresa'
                  ParentFont = False
                  Style.Font.Charset = DEFAULT_CHARSET
                  Style.Font.Color = clWindowText
                  Style.Font.Height = -15
                  Style.Font.Name = 'Source Sans 3'
                  Style.Font.Style = []
                  Style.IsFontAssigned = True
                  TabOrder = 11
                  Transparent = True
                end
                object txtNRO_FACTURA: TcxDBTextEdit
                  Left = 155
                  Top = 12
                  DataBinding.DataField = 'NUMERO_FAC'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 0
                  Width = 121
                end
                object cbbSerieFactura: TcxDBLookupComboBox
                  Left = 155
                  Top = 150
                  BeepOnEnter = False
                  DataBinding.DataField = 'SERIE_FAC'
                  DataBinding.DataSource = dsTablaG
                  Properties.DropDownListStyle = lsEditList
                  Properties.ImmediateDropDownWhenKeyPressed = False
                  Properties.IncrementalFiltering = False
                  Properties.KeyFieldNames = 'SERIE_CON'
                  Properties.ListColumns = <
                    item
                      Caption = 'Serie'
                      FieldName = 'SERIE_CON'
                    end>
                  Properties.ListOptions.ColumnSorting = False
                  Properties.ListOptions.ShowHeader = False
                  Properties.ListSource = dmFacturas.dsSeries
                  Properties.ReadOnly = True
                  Properties.OnChange = cbbSerieFacturaPropertiesChange
                  TabOrder = 5
                  Width = 145
                end
                object chkConsolidada: TcxDBCheckBox
                  Left = 36
                  Top = 250
                  Caption = 'El borrador est'#225' cerrado'
                  DataBinding.DataField = 'ESCONSOLIDADA_FAC'
                  DataBinding.DataSource = dsTablaG
                  Enabled = False
                  Properties.ValueChecked = 'S'
                  Properties.ValueUnchecked = 'N'
                  Style.TransparentBorder = False
                  TabOrder = 12
                  Transparent = True
                end
                object chkMueveStock: TcxDBCheckBox
                  Left = 36
                  Top = 275
                  Caption = 'Generar movimientos de stock al consolidar'
                  DataBinding.DataField = 'ESMUEVE_STOCK_FAC'
                  DataBinding.DataSource = dsTablaG
                  Properties.ValueChecked = 'S'
                  Properties.ValueUnchecked = 'N'
                  Style.TransparentBorder = False
                  TabOrder = 20
                  Transparent = True
                end
                object txtINSTANTECONSOLIDACION: TcxDBTextEdit
                  Left = 325
                  Top = 245
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'INSTANTECONSO_FAC'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 13
                  Width = 348
                end
                object lblTipoFactura: TcxLabel
                  Left = 337
                  Top = 150
                  AutoSize = False
                  Properties.Alignment.Horz = taRightJustify
                  Properties.Alignment.Vert = taVCenter
                  Height = 24
                  Width = 150
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Tipo Borrador'
                  TabOrder = 14
                  Transparent = True
                end
                object txtTIPO_FAC: TcxDBTextEdit
                  Left = 495
                  Top = 150
                  DataBinding.DataField = 'TIPO_FAC'
                  DataBinding.DataSource = dsTablaG
                  Enabled = False
                  Properties.ReadOnly = True
                  TabOrder = 15
                  Width = 189
                end
                object lblVendedorFactura: TcxLabel
                  Left = 337
                  Top = 12
                  AutoSize = False
                  Properties.Alignment.Horz = taRightJustify
                  Properties.Alignment.Vert = taVCenter
                  Height = 24
                  Width = 150
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Vendedor Borrador'
                  TabOrder = 16
                  Transparent = True
                end
                object txtCODIGO_CAJERO_FAC: TcxDBTextEdit
                  Left = 495
                  Top = 12
                  DataBinding.DataField = 'CODIGO_CAJERO_FAC'
                  DataBinding.DataSource = dsTablaG
                  Enabled = False
                  Properties.ReadOnly = True
                  TabOrder = 17
                  Width = 178
                end
                object txtFASE_FAC: TcxDBTextEdit
                  Left = 495
                  Top = 196
                  DataBinding.DataField = 'FASE_FAC'
                  DataBinding.DataSource = dsTablaG
                  Enabled = False
                  Properties.ReadOnly = True
                  TabOrder = 18
                  Width = 189
                end
                object lblFaseFactura: TcxLabel
                  Left = 337
                  Top = 196
                  AutoSize = False
                  Properties.Alignment.Horz = taRightJustify
                  Properties.Alignment.Vert = taVCenter
                  Height = 24
                  Width = 150
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Fase Borrador'
                  TabOrder = 19
                  Transparent = True
                end
                object lblAlmacenFactura: TcxLabel
                  Left = 690
                  Top = 58
                  AutoSize = False
                  Properties.Alignment.Horz = taRightJustify
                  Properties.Alignment.Vert = taVCenter
                  Height = 24
                  Width = 92
                  Caption = 'Almac'#233'n'
                  TabOrder = 21
                  Transparent = True
                end
                object cbbAlmacenFactura: TcxDBLookupComboBox
                  Left = 790
                  Top = 58
                  DataBinding.DataField = 'CODIGO_ALM_FAC'
                  DataBinding.DataSource = dsTablaG
                  Properties.DropDownListStyle = lsFixedList
                  Properties.DropDownRows = 15
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
                  TabOrder = 22
                  Width = 250
                end
              end
              object tsEmpresa: TcxTabSheet
                Caption = 'Datos E&mpresa Emisora -'
                Color = clBtnFace
                ImageIndex = 2
                ParentColor = False
                ExplicitLeft = 0
                ExplicitTop = 0
                ExplicitWidth = 0
                ExplicitHeight = 0
                object grpEmpresa: TcxGroupBox
                  Left = 22
                  Top = 13
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Empresa'
                  TabOrder = 0
                  Height = 277
                  Width = 770
                  object txtDIRECCION1_EMPRESA_FACTURA: TcxDBTextEdit
                    Left = 14
                    Top = 55
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    DataBinding.DataField = 'DIRECCION1_EMPRESA_FAC'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 1
                    Width = 328
                  end
                  object txtCPOSTAL_EMPRESA_FACTURA: TcxDBTextEdit
                    Left = 13
                    Top = 115
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    DataBinding.DataField = 'CODIGO_POSTAL_EMPRESA_FAC'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 3
                    Width = 75
                  end
                  object txtPROVINCIA_EMPRESA_FACTURA: TcxDBTextEdit
                    Left = 114
                    Top = 169
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    DataBinding.DataField = 'PROVINCIA_EMPRESA_FAC'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 5
                    Width = 228
                  end
                  object txtPAIS_EMPRESA_FACTURA: TcxDBTextEdit
                    Left = 112
                    Top = 201
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    DataBinding.DataField = 'NOMBRE_PAI_EMPRESA_FAC'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 6
                    Visible = False
                    Width = 155
                  end
                  object txtDIRECCION2_EMPRESA_FACTURA: TcxDBTextEdit
                    Left = 14
                    Top = 79
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    DataBinding.DataField = 'DIRECCION2_EMPRESA_FAC'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 2
                    Width = 328
                  end
                  object lblProvinciaEmpresa: TcxLabel
                    Left = 23
                    Top = 173
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    Caption = 'Provincia'
                    TabOrder = 10
                    Transparent = True
                  end
                  object lblPaisEmpresa: TcxLabel
                    Left = 66
                    Top = 206
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    Caption = 'Pa'#237's'
                    TabOrder = 11
                    Transparent = True
                  end
                  object txtRAZONSOCIAL_EMPRESA_FACTURA: TcxDBTextEdit
                    Left = 14
                    Top = 22
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    DataBinding.DataField = 'RAZON_SOCIAL_EMPRESA_FAC'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 0
                    Width = 328
                  end
                  object txtNIF_EMPRESA_FACTURA: TcxDBTextEdit
                    Left = 505
                    Top = 29
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    DataBinding.DataField = 'NIF_EMPRESA_FAC'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 7
                    Width = 247
                  end
                  object lblNIFEmpresa: TcxLabel
                    Left = 389
                    Top = 33
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    Caption = 'NIF Empresa'
                    ParentFont = False
                    Style.Font.Charset = ANSI_CHARSET
                    Style.Font.Color = clWindowText
                    Style.Font.Height = -15
                    Style.Font.Name = 'Source Sans 3'
                    Style.Font.Style = []
                    Style.IsFontAssigned = True
                    TabOrder = 12
                    Transparent = True
                  end
                  object lblMovilEmpresa: TcxLabel
                    Left = 369
                    Top = 66
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    Caption = 'M'#243'vil Empresa'
                    ParentFont = False
                    Style.Font.Charset = ANSI_CHARSET
                    Style.Font.Color = clWindowText
                    Style.Font.Height = -15
                    Style.Font.Name = 'Source Sans 3'
                    Style.Font.Style = []
                    Style.IsFontAssigned = True
                    TabOrder = 13
                    Transparent = True
                  end
                  object txtMOVIL_EMPRESA_FACTURA: TcxDBTextEdit
                    Left = 505
                    Top = 62
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    DataBinding.DataField = 'MOVIL_EMPRESA_FAC'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 8
                    Width = 247
                  end
                  object txtEMAIL_EMPRESA_FACTURA: TcxDBTextEdit
                    Left = 505
                    Top = 95
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    DataBinding.DataField = 'EMAIL_EMPRESA_FAC'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 9
                    Width = 247
                  end
                  object lblEmailEmpresa: TcxLabel
                    Left = 372
                    Top = 99
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    Caption = 'Email Empresa'
                    ParentFont = False
                    Style.Font.Charset = ANSI_CHARSET
                    Style.Font.Color = clWindowText
                    Style.Font.Height = -15
                    Style.Font.Name = 'Source Sans 3'
                    Style.Font.Style = []
                    Style.IsFontAssigned = True
                    TabOrder = 15
                    Transparent = True
                  end
                  object chkESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA: TcxDBCheckBox
                    Left = 372
                    Top = 167
                    Caption = 'Empresa es agricultor/ganadero/pesca (S'#243'lo REAGP)'
                    DataBinding.DataField = 'ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC'
                    DataBinding.DataSource = dsTablaG
                    Properties.MultiLine = True
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    Properties.OnChange = chkESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURAPropertiesChange
                    TabOrder = 16
                    Transparent = True
                    Width = 261
                  end
                  object chkRETENCION_EMPRESA_FACTURA: TcxDBCheckBox
                    Left = 372
                    Top = 138
                    Caption = 'Empresa practica retenci'#243'n en Borrador'
                    DataBinding.DataField = 'ESRETENCIONES_EMPRESA_FAC'
                    DataBinding.DataSource = dsTablaG
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    TabOrder = 14
                    Transparent = True
                  end
                  object mPOBLACION_EMPRESA_FACTURA: TcxDBMemo
                    Left = 91
                    Top = 115
                    DataBinding.DataField = 'POBLACION_EMPRESA_FAC'
                    DataBinding.DataSource = dsTablaG
                    Properties.ScrollBars = ssVertical
                    TabOrder = 4
                    Height = 49
                    Width = 251
                  end
                  object cbbCanalIVA: TcxDBLookupComboBox
                    Left = 200
                    Top = 233
                    DataBinding.DataField = 'GRUPO_ZONA_IVA_EMPRESA_FAC'
                    DataBinding.DataSource = dsTablaG
                    Properties.KeyFieldNames = 'IVA_IVAGRP'
                    Properties.ListColumns = <
                      item
                        Caption = 'Zona de IVA'
                        FieldName = 'DESCRIPCION_IVA_IVAGRP'
                      end>
                    Properties.ListOptions.ShowHeader = False
                    Properties.ReadOnly = True
                    Properties.OnChange = cbbCanalIVAPropertiesChange
                    TabOrder = 18
                    Width = 275
                  end
                  object lblCanalIVA: TcxLabel
                    Left = 20
                    Top = 237
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    Caption = 'Canal IVA'
                    TabOrder = 17
                    Transparent = True
                  end
                  object lbldbCODIGO_CLIENTE_FACTURA: TcxDBLabel
                    Left = 92
                    Top = -5
                    DataBinding.DataField = 'CODIGO_EMP_FAC'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 19
                    Transparent = True
                    Height = 21
                    Width = 94
                  end
                  object txtNOMBRE_PAIS_EMPRESA_FACTURA: TcxDBTextEdit
                    Left = 324
                    Top = 199
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    DataBinding.DataField = 'CODIGO_PAI_EMPRESA_FAC'
                    DataBinding.DataSource = dsTablaG
                    Enabled = False
                    TabOrder = 20
                    Width = 53
                  end
                  object cbbPaisesEmp: TcxDBLookupComboBox
                    Left = 114
                    Top = 199
                    DataBinding.DataField = 'CODIGO_PAI_EMPRESA_FAC'
                    DataBinding.DataSource = dsTablaG
                    Properties.KeyFieldNames = 'CODIGO'
                    Properties.ListColumns = <
                      item
                        Caption = 'Nombre Pais'
                        FieldName = 'NOMBRE'
                      end>
                    Properties.ListOptions.CaseInsensitive = True
                    Properties.ListOptions.ShowHeader = False
                    Properties.ListSource = dmFacturas.dsPaisesEmp
                    TabOrder = 21
                    Width = 203
                  end
                end
                object btnUpdateEmpresa: TcxButton
                  Left = 799
                  Top = 50
                  Width = 142
                  Height = 122
                  Caption = 'Dar de Alta o &Actualizar Empresa'
                  TabOrder = 1
                  WordWrap = True
                  OnClick = btnUpdateEmpresaClick
                end
                object btnIrAEmpresa: TcxButton
                  Left = 799
                  Top = 200
                  Width = 142
                  Height = 34
                  Caption = 'I&r a Empresa'
                  TabOrder = 2
                  OnClick = btnIrAEmpresaClick
                end
              end
              object tsDatosCliente: TcxTabSheet
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Caption = 'Datos Cli&ente -'
                ImageIndex = 1
                object grpCliente: TcxGroupBox
                  Left = 22
                  Top = 13
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Cliente'
                  TabOrder = 0
                  Height = 277
                  Width = 763
                  object txtDIRECCION1_CLIENTE_FACTURA1: TcxDBTextEdit
                    Left = 13
                    Top = 57
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    DataBinding.DataField = 'DIRECCION1_CLIENTE_FAC'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 1
                    Width = 328
                  end
                  object txtCPOSTAL_CLIENTE_FACTURA1: TcxDBTextEdit
                    Left = 13
                    Top = 115
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    DataBinding.DataField = 'CODIGO_POSTAL_CLIENTE_FAC'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 3
                    Width = 70
                  end
                  object txtPOBLACION_CLIENTE_FACTURA1: TcxDBTextEdit
                    Left = 92
                    Top = 114
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    DataBinding.DataField = 'POBLACION_CLIENTE_FAC'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 4
                    Width = 247
                  end
                  object txtPROVINCIA_CLIENTE_FACTURA1: TcxDBTextEdit
                    Left = 113
                    Top = 147
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    DataBinding.DataField = 'PROVINCIA_CLIENTE_FAC'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 5
                    Width = 228
                  end
                  object txtPAIS_CLIENTE_FACTURA1: TcxDBTextEdit
                    Left = 113
                    Top = 180
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    DataBinding.DataField = 'NOMBRE_PAI_CLIENTE_FAC'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 6
                    Visible = False
                    Width = 151
                  end
                  object txtDIRECCION2_CLIENTE_FACTURA1: TcxDBTextEdit
                    Left = 13
                    Top = 81
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    DataBinding.DataField = 'DIRECCION2_CLIENTE_FAC'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 2
                    Width = 328
                  end
                  object lblExtra6: TcxLabel
                    Left = 26
                    Top = 148
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    Caption = 'Provincia'
                    TabOrder = 10
                    Transparent = True
                  end
                  object lblExtra13: TcxLabel
                    Left = 69
                    Top = 181
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    Caption = 'Pa'#237's'
                    TabOrder = 11
                    Transparent = True
                  end
                  object txtRAZONSOCIAL_CLIENTE_FACTURA: TcxDBTextEdit
                    Left = 13
                    Top = 26
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    DataBinding.DataField = 'RAZON_SOCIAL_CLIENTE_FAC'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 0
                    Width = 328
                  end
                  object txtNIF_CLIENTE_FACTURA: TcxDBTextEdit
                    Left = 464
                    Top = 26
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    DataBinding.DataField = 'NIF_CLIENTE_FAC'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 7
                    Width = 289
                  end
                  object lblNif: TcxLabel
                    Left = 425
                    Top = 27
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    Caption = 'NIF'
                    TabOrder = 12
                    Transparent = True
                  end
                  object lblTelefonoMovil: TcxLabel
                    Left = 359
                    Top = 59
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    Caption = 'Tfno. M'#243'vil'
                    TabOrder = 13
                    Transparent = True
                  end
                  object txtMOVIL_CLIENTE_FACTURA: TcxDBTextEdit
                    Left = 464
                    Top = 58
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    DataBinding.DataField = 'MOVIL_CLIENTE_FAC'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 8
                    Width = 289
                  end
                  object txtEMAIL_CLIENTE_FACTURA: TcxDBTextEdit
                    Left = 464
                    Top = 91
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    DataBinding.DataField = 'EMAIL_CLIENTE_FAC'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 9
                    Width = 289
                  end
                  object lblEmail: TcxLabel
                    Left = 407
                    Top = 92
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    Caption = 'Email'
                    TabOrder = 14
                    Transparent = True
                  end
                  object chkESIVA_RECARGO_CLIENTE_FACTURA: TcxDBCheckBox
                    Left = 378
                    Top = 151
                    Caption = 'Aplicar Recargo de Equivalencia'
                    DataBinding.DataField = 'ESIVA_RECARGO_CLIENTE_FAC'
                    DataBinding.DataSource = dsTablaG
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    TabOrder = 16
                    Transparent = True
                  end
                  object chkREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA: TcxDBCheckBox
                    Left = 378
                    Top = 177
                    Caption = 'Cliente es agricultor/ganadero/pesca'
                    DataBinding.DataField = 'ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC'
                    DataBinding.DataSource = dsTablaG
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    TabOrder = 17
                    Transparent = True
                  end
                  object chkRETENCIONES_EMPRESA_FACTURA3: TcxDBCheckBox
                    Left = 378
                    Top = 124
                    Caption = 'Aplicar IRPF (Es profesional)'
                    DataBinding.DataField = 'ESRETENCIONES_CLIENTE_FAC'
                    DataBinding.DataSource = dsTablaG
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    TabOrder = 15
                    Transparent = True
                  end
                  object chkEXTRANJERO: TcxDBCheckBox
                    Left = 13
                    Top = 217
                    Caption = 'IVA Exento'
                    DataBinding.DataField = 'ESIVA_EXENTO_CLIENTE_FAC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayUnchecked = 'True'
                    Properties.DisplayGrayed = 'False'
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    TabOrder = 18
                    Transparent = True
                  end
                  object cbbTARIFA_ARTICULOS_CLIENTES: TcxDBLookupComboBox
                    Left = 548
                    Top = 211
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    DataBinding.DataField = 'TARIFA_ARTICULO_CLIENTE_FAC'
                    DataBinding.DataSource = dsTablaG
                    Properties.KeyFieldNames = 'CODIGO_TAR_ARTTAR'
                    Properties.ListColumns = <
                      item
                        FieldName = 'NOMBRE_TAR_TAR'
                      end>
                    Properties.ListOptions.ShowHeader = False
                    Properties.ReadOnly = True
                    Properties.OnChange = cbbTARIFA_ARTICULOS_CLIENTESPropertiesChange
                    TabOrder = 21
                    OnKeyUp = cbbSerieFacturaKeyUp
                    Width = 205
                  end
                  object lblTarifaArticulosCliente: TcxLabel
                    Left = 407
                    Top = 215
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    Caption = 'Tarifa Art'#237'culos'
                    Style.BorderStyle = ebsNone
                    TabOrder = 20
                    Transparent = True
                  end
                  object chkIVA_EXENTO_CLIENTE_FACTURA: TcxDBCheckBox
                    Left = 132
                    Top = 217
                    Caption = 'Cliente intracomunitario'
                    DataBinding.DataField = 'ESINTRACOMUNITARIO_CLIENTE_FAC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayUnchecked = 'True'
                    Properties.DisplayGrayed = 'False'
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    TabOrder = 19
                    Transparent = True
                  end
                  object lbldbCODIGO_CLIENTE: TcxDBLabel
                    Left = 81
                    Top = -4
                    DataBinding.DataField = 'CODIGO_CLI_FAC'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 22
                    Transparent = True
                    Height = 21
                    Width = 94
                  end
                  object chkImpIncl: TcxDBCheckBox
                    Left = 407
                    Top = 242
                    Caption = 'Precios Venta con Impuestos Incluidos'
                    DataBinding.DataField = 'ESIMP_INCL_TARIFA_CLIENTE_FAC'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayUnchecked = 'True'
                    Properties.DisplayGrayed = 'False'
                    Properties.ReadOnly = True
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    Style.TransparentBorder = False
                    TabOrder = 23
                    Transparent = True
                  end
                  object txtNOMBRE_PAIS_CLIENTE_FACTURA: TcxDBTextEdit
                    Left = 323
                    Top = 180
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    DataBinding.DataField = 'CODIGO_PAI_CLIENTE_FAC'
                    DataBinding.DataSource = dsTablaG
                    Enabled = False
                    TabOrder = 24
                    Width = 48
                  end
                  object cbbPaisesCli: TcxDBLookupComboBox
                    Left = 113
                    Top = 181
                    DataBinding.DataField = 'CODIGO_PAI_CLIENTE_FAC'
                    DataBinding.DataSource = dsTablaG
                    Properties.KeyFieldNames = 'CODIGO'
                    Properties.ListColumns = <
                      item
                        Caption = 'Nombre Pais'
                        FieldName = 'NOMBRE'
                      end>
                    Properties.ListOptions.CaseInsensitive = True
                    Properties.ListOptions.ShowHeader = False
                    Properties.ListSource = dmFacturas.dsPaisesCli
                    TabOrder = 25
                    Width = 203
                  end
                end
                object btnUpdateCliente: TcxButton
                  Left = 799
                  Top = 50
                  Width = 142
                  Height = 122
                  Caption = 'Dar de Alta o &Actualizar Cliente'
                  TabOrder = 1
                  WordWrap = True
                  OnClick = btnUpdateClienteClick
                end
                object btnIrACliente: TcxButton
                  Left = 799
                  Top = 200
                  Width = 142
                  Height = 34
                  Caption = 'I&r a Cliente'
                  TabOrder = 2
                  OnClick = btnIrAClienteClick
                end
              end
            end
          end
        end
        object splSplitterFicha: TcxSplitter
          Left = 0
          Top = 337
          Width = 1079
          Height = 8
          Cursor = crSizeNS
          Margins.Left = 4
          Margins.Top = 4
          Margins.Right = 4
          Margins.Bottom = 4
          HotZoneClassName = 'TcxMediaPlayer9Style'
          HotZone.SizePercent = 50
          AlignSplitter = salTop
          Control = pnlVerifactu
        end
        object pnlResumenBorrador: TcxGroupBox
          Left = 0
          Top = 656
          Width = 941
          Height = 40
          Align = alBottom
          PanelStyle.Active = True
          Style.BorderStyle = ebsNone
          TabOrder = 3
          object lblResumenBases: TcxLabel
            Left = 16
            Top = 8
            Caption = 'Bases'
            TabOrder = 3
            Transparent = True
          end
          object curResumenBases: TcxDBCurrencyEdit
            Left = 106
            Top = 8
            DataBinding.DataField = 'TOTAL_BASES_FAC'
            DataBinding.DataSource = dsTablaG
            Properties.DisplayFormat = '#,##0.00 '#8364
            Properties.ReadOnly = True
            TabOrder = 0
            Width = 100
          end
          object lblResumenImpuestos: TcxLabel
            Left = 224
            Top = 8
            Caption = 'Impuestos'
            TabOrder = 4
            Transparent = True
          end
          object curResumenImpuestos: TcxDBCurrencyEdit
            Left = 310
            Top = 8
            DataBinding.DataField = 'TOTAL_IMPUESTOS_FAC'
            DataBinding.DataSource = dsTablaG
            Properties.DisplayFormat = '#,##0.00 '#8364
            Properties.ReadOnly = True
            TabOrder = 1
            Width = 100
          end
          object lblResumenLiquido: TcxLabel
            Left = 442
            Top = 8
            Caption = 'TOTAL'
            TabOrder = 5
            Transparent = True
          end
          object curResumenLiquido: TcxDBCurrencyEdit
            Left = 502
            Top = 8
            DataBinding.DataField = 'TOTAL_LIQUIDO_FAC'
            DataBinding.DataSource = dsTablaG
            Properties.DisplayFormat = '#,##0.00 '#8364
            Properties.ReadOnly = True
            TabOrder = 2
            Width = 130
          end
        end
      end
      inherited tsPerfil: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 28
        ExplicitWidth = 1079
        ExplicitHeight = 772
        inherited pnlPerfilTop: TPanel
          Width = 1079
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 1079
          inherited edtPerfilBusq: TcxTextEdit
            ExplicitHeight = 25
          end
        end
        inherited pnlPerfilDetail: TPanel
          Width = 1079
          Height = 715
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 1079
          ExplicitHeight = 715
          inherited cxgrdPerfil: TcxGrid
            Width = 1079
            Height = 715
            ExplicitWidth = 1079
            ExplicitHeight = 715
          end
        end
      end
    end
    inherited pnlTopPage: TPanel
      Width = 1087
      TabOrder = 0
      StyleElements = [seFont, seClient, seBorder]
      ExplicitWidth = 1087
      inherited pnlTopGrid: TPanel
        Width = 1087
        StyleElements = [seFont, seClient, seBorder]
        ExplicitWidth = 1087
        inherited sbExportExcel: TSpeedButton
          ParentFont = True
        end
        inherited edtBusqGlobal: TcxTextEdit
          ExplicitHeight = 25
        end
        inherited nvNavegador: TcxDBNavigator
          Width = 338
          ExplicitWidth = 338
        end
        inherited lblTextoaBuscar: TcxLabel
          Top = 7
          ExplicitTop = 7
        end
      end
    end
  end
  inherited pButtonRightBar: TPanel
    Left = 1087
    Width = 144
    Height = 844
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    TabOrder = 1
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 1087
    ExplicitWidth = 144
    ExplicitHeight = 844
    inherited pButtonGen: TPanel
      Top = 646
      Width = 144
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Constraints.MinHeight = 100
      Constraints.MinWidth = 124
      StyleElements = [seFont, seClient, seBorder]
      ExplicitTop = 646
      ExplicitWidth = 144
      inherited btnGrabar: TcxButton
        Width = 140
        OnClick = sbGrabarClick
        ExplicitWidth = 140
      end
      inherited btnCancelar: TcxButton
        Width = 140
        ExplicitWidth = 140
      end
    end
    inherited pButtonBDStat: TPanel
      Width = 144
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Constraints.MinHeight = 46
      Constraints.MinWidth = 124
      StyleElements = [seFont, seClient, seBorder]
      ExplicitWidth = 144
      inherited pnStateDataSet: TPanel
        Width = 144
        Margins.Left = 5
        Margins.Top = 5
        Margins.Right = 5
        Margins.Bottom = 5
        StyleElements = [seFont, seClient, seBorder]
        ExplicitWidth = 144
        inherited lblEditMode: TcxLabel
          Margins.Left = 5
          Margins.Top = 5
          Margins.Right = 5
          Margins.Bottom = 5
        end
      end
      inherited pnlDataSetName: TPanel
        Width = 144
        StyleElements = [seFont, seClient, seBorder]
        ExplicitWidth = 144
      end
    end
    object btnNuevaFactura: TcxButton
      Left = 1
      Top = 229
      Width = 140
      Height = 34
      Caption = '&Nuevo Borrador'
      TabOrder = 2
      OnClick = sbNuevaFacturaClick
    end
    object btnRectificar: TcxButton
      Left = 1
      Top = 271
      Width = 140
      Height = 34
      Caption = '&Rectificar / Duplicar'
      TabOrder = 3
      OnClick = sbRectificarClick
    end
    object btnImprimir: TcxButton
      Left = 1
      Top = 313
      Width = 140
      Height = 34
      Caption = '&Imprimir'
      TabOrder = 4
      OnClick = sbImprimirClick
    end
    object btnConsolidar: TcxButton
      Left = 1
      Top = 355
      Width = 140
      Height = 34
      Caption = 'Consolida&r'
      TabOrder = 5
      OnClick = btnConsolidarClick
    end
  end
  inherited Localizer1: TcxLocalizer
    Left = 1104
    Top = 587
  end
  inherited jvntrstb1: TJvEnterAsTab
    Left = 1104
    Top = 136
  end
  object ActionListFacturas: TActionList [5]
    Left = 1104
    Top = 528
    object actArticulo: TAction
      Caption = 'actArticulo'
      ShortCut = 16466
      OnExecute = actArticuloExecute
    end
    object actEmpresa: TAction
      Caption = 'actEmpresa'
      ShortCut = 49221
      OnExecute = actEmpresaExecute
    end
    object actCliente: TAction
      Caption = 'actCliente'
      ShortCut = 16459
      OnExecute = actClienteExecute
    end
    object actMovimiento: TAction
      Caption = 'actMovimiento'
      ShortCut = 16461
      OnExecute = actMovimientoExecute
    end
  end
  inherited dsTablaG: TDataSource
    DataSet = dmFacturas.unqryTablaG
    Left = 1108
    Top = 439
  end
  inherited saveDialog: TdxSaveFileDialog
    Left = 1104
    Top = 72
  end
end
