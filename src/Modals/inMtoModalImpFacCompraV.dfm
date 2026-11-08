inherited frmPrintFacCompraV: TfrmPrintFacCompraV
  Caption = 'Imprimir Factura de Compra (Vertical)'
  ClientHeight = 220
  ClientWidth = 460
  StyleElements = [seFont, seClient, seBorder]
  ExplicitWidth = 476
  ExplicitHeight = 259
  TextHeight = 19
  inherited pnl1: TPanel
    Left = 320
    Height = 220
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 320
    ExplicitHeight = 220
    inherited btnSalir: TcxButton
      Top = 194
      ExplicitTop = 194
    end
    inherited btnExcel: TcxButton
      OnClick = btnExcelClick
    end
  end
  object lblSerie: TcxLabel [1]
    Left = 16
    Top = 16
    Caption = 'Serie'
    TabOrder = 1
    Transparent = True
  end
  object edtSerie: TcxTextEdit [2]
    Left = 16
    Top = 40
    Enabled = False
    TabOrder = 2
    Width = 121
  end
  object lblNumero: TcxLabel [3]
    Left = 152
    Top = 16
    Caption = 'Número'
    TabOrder = 3
    Transparent = True
  end
  object edtNumero: TcxTextEdit [4]
    Left = 152
    Top = 40
    Enabled = False
    TabOrder = 4
    Width = 121
  end
  inherited frxrprt1: TfrxReport
    ReportOptions.LastChange = 46196.500000000000000000
    ScriptText.Strings = (
      'begin'
      'end.')
    Left = 8
    Top = 184
    Datasets = <
      item
        DataSet = dmFacturasCompra.fxdsCabFacc
        DataSetName = 'Factura'
      end
      item
        DataSet = dmFacturasCompra.fxdsLinFaccSku
        DataSetName = 'LineasFacturaSku'
      end>
    Variables = <>
    Style = <>
    inherited Page1: TfrxReportPage
      Orientation = poPortrait
      PaperWidth = 210.000000000000000000
      PaperHeight = 297.000000000000000000
      PaperSize = 9
      LeftMargin = 10.000000000000000000
      RightMargin = 10.000000000000000000
      TopMargin = 10.000000000000000000
      BottomMargin = 10.000000000000000000
      Frame.Typ = []
      MirrorMode = []
      object PageHeader1: TfrxPageHeader
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 110.000000000000000000
        Top = 18.897650000000000000
        Width = 718.110700000000000000
        object MemoTituloV: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 0.000000000000000000
          Width = 718.110700000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            'FACTURA DE COMPRA')
          ParentFont = False
        end
        object MemoEmpRazonV: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 30.000000000000000000
          Width = 350.000000000000000000
          Height = 18.000000000000000000
          DataSet = dmFacturasCompra.fxdsCabFacc
          DataSetName = 'Factura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[Factura."NOMBRE_ALM_FACC"]')
          ParentFont = False
        end
        object MemoEmpDirV: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 48.000000000000000000
          Width = 350.000000000000000000
          Height = 14.000000000000000000
          DataSet = dmFacturasCompra.fxdsCabFacc
          DataSetName = 'Factura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Factura."DIRECCION_ALM_FACC"]')
          ParentFont = False
        end
        object MemoEmpCpPobV: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 62.000000000000000000
          Width = 350.000000000000000000
          Height = 14.000000000000000000
          DataSet = dmFacturasCompra.fxdsCabFacc
          DataSetName = 'Factura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Factura."CODIGO_POSTAL_ALM_FACC"] [Factura."POBLACION_ALM_F' +
              'ACC"][IIF(<Factura."PROVINCIA_ALM_FACC"> <> '#39#39', '#39' ('#39' + <Fact' +
              'ura."PROVINCIA_ALM_FACC"> + '#39')'#39', '#39#39')]')
          ParentFont = False
        end
        object MemoEmpCifV: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 76.000000000000000000
          Width = 350.000000000000000000
          Height = 14.000000000000000000
          DataSet = dmFacturasCompra.fxdsCabFacc
          DataSetName = 'Factura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[IIF(<Factura."TELEFONO_ALM_FACC"> <> '#39#39', '#39'Tel: '#39' + <Factura' +
              '."TELEFONO_ALM_FACC"> + '#39'   '#39', '#39#39')][IIF(<Factura."EMAIL_ALM_' +
              'FACC"> <> '#39#39', '#39'Email: '#39' + <Factura."EMAIL_ALM_FACC">, '#39#39')]')
          ParentFont = False
        end
        object MemoPrvLblV: TfrxMemoView
          AllowVectorExport = True
          Left = 360.000000000000000000
          Top = 30.000000000000000000
          Width = 358.000000000000000000
          Height = 14.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGray
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'PROVEEDOR')
          ParentFont = False
        end
        object MemoPrvRazonV: TfrxMemoView
          AllowVectorExport = True
          Left = 360.000000000000000000
          Top = 44.000000000000000000
          Width = 358.000000000000000000
          Height = 18.000000000000000000
          DataSet = dmFacturasCompra.fxdsCabFacc
          DataSetName = 'Factura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[Factura."RAZON_SOCIAL_PRV"]')
          ParentFont = False
        end
        object MemoPrvDirV: TfrxMemoView
          AllowVectorExport = True
          Left = 360.000000000000000000
          Top = 62.000000000000000000
          Width = 358.000000000000000000
          Height = 14.000000000000000000
          DataSet = dmFacturasCompra.fxdsCabFacc
          DataSetName = 'Factura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Factura."DIRECCION1_PRV"][IIF((<Factura."DIRECCION1_PRV"> <' +
              '> '#39#39') and (<Factura."POBLACION_PRV"> <> '#39#39'), '#39', '#39', '#39#39')][Fact' +
              'ura."POBLACION_PRV"]')
          ParentFont = False
        end
        object MemoPrvCifV: TfrxMemoView
          AllowVectorExport = True
          Left = 360.000000000000000000
          Top = 76.000000000000000000
          Width = 358.000000000000000000
          Height = 14.000000000000000000
          DataSet = dmFacturasCompra.fxdsCabFacc
          DataSetName = 'Factura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[IIF(<Factura."CIF_PRV"> <> '#39#39', '#39'CIF: '#39' + <Factura."CIF_PRV"' +
              '>, '#39#39')]')
          ParentFont = False
        end
        object MemoNumeroV: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 92.000000000000000000
          Width = 360.000000000000000000
          Height = 18.000000000000000000
          DataSet = dmFacturasCompra.fxdsCabFacc
          DataSetName = 'Factura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            'Factura: [Factura."DOCUMENTO_FORMATO"]')
          ParentFont = False
        end
        object MemoFechaV: TfrxMemoView
          AllowVectorExport = True
          Left = 360.000000000000000000
          Top = 92.000000000000000000
          Width = 200.000000000000000000
          Height = 18.000000000000000000
          DataSet = dmFacturasCompra.fxdsCabFacc
          DataSetName = 'Factura'
          DisplayFormat.FormatStr = 'dd/mm/yyyy'
          DisplayFormat.Kind = fkDateTime
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            'Fecha: [Factura."FECHA_FACC"]')
          ParentFont = False
        end
        object MemoRefPrvV: TfrxMemoView
          AllowVectorExport = True
          Left = 560.000000000000000000
          Top = 92.000000000000000000
          Width = 158.000000000000000000
          Height = 18.000000000000000000
          DataSet = dmFacturasCompra.fxdsCabFacc
          DataSetName = 'Factura'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            'Ref. prov.: [Factura."REF_PROVEEDOR_FACC"]')
          ParentFont = False
        end
      end
      object HeaderLineasV: TfrxHeader
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 20.000000000000000000
        Top = 140.000000000000000000
        Width = 718.110700000000000000
        ReprintOnNewPage = True
        object HdrLineaV: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 0.000000000000000000
          Width = 40.000000000000000000
          Height = 20.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Fill.BackColor = 6710886
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            'Línea')
          ParentFont = False
          WordWrap = False
        end
        object HdrArtV: TfrxMemoView
          AllowVectorExport = True
          Left = 40.000000000000000000
          Top = 0.000000000000000000
          Width = 116.000000000000000000
          Height = 20.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Fill.BackColor = 6710886
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = ('Artículo')
          ParentFont = False
          WordWrap = False
        end
        object HdrSkuV: TfrxMemoView
          AllowVectorExport = True
          Left = 156.000000000000000000
          Top = 0.000000000000000000
          Width = 196.000000000000000000
          Height = 20.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Fill.BackColor = 6710886
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = ('SKU')
          ParentFont = False
          WordWrap = False
        end
        object HdrRefV: TfrxMemoView
          AllowVectorExport = True
          Left = 352.000000000000000000
          Top = 0.000000000000000000
          Width = 66.000000000000000000
          Height = 20.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Fill.BackColor = 6710886
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = ('Ref. prov.')
          ParentFont = False
          WordWrap = False
        end
        object HdrDescV: TfrxMemoView
          AllowVectorExport = True
          Left = 418.000000000000000000
          Top = 0.000000000000000000
          Width = 132.000000000000000000
          Height = 20.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Fill.BackColor = 6710886
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = ('Descripción')
          ParentFont = False
          WordWrap = False
        end
        object HdrCantV: TfrxMemoView
          AllowVectorExport = True
          Left = 550.000000000000000000
          Top = 0.000000000000000000
          Width = 40.000000000000000000
          Height = 20.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Fill.BackColor = 6710886
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = ('Cant.')
          ParentFont = False
          WordWrap = False
        end
        object HdrPrecV: TfrxMemoView
          AllowVectorExport = True
          Left = 590.000000000000000000
          Top = 0.000000000000000000
          Width = 58.000000000000000000
          Height = 20.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Fill.BackColor = 6710886
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = ('Precio')
          ParentFont = False
          WordWrap = False
        end
        object HdrTotV: TfrxMemoView
          AllowVectorExport = True
          Left = 648.000000000000000000
          Top = 0.000000000000000000
          Width = 70.110700000000000000
          Height = 20.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Fill.BackColor = 6710886
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = ('Total')
          ParentFont = False
          WordWrap = False
        end
      end
      object DataBandLineasV: TfrxMasterData
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 16.000000000000000000
        Top = 180.000000000000000000
        Width = 718.110700000000000000
        DataSet = dmFacturasCompra.fxdsLinFaccSku
        DataSetName = 'LineasFacturaSku'
        RowCount = 0
        Stretched = True
        object LinLineaV: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 0.000000000000000000
          Width = 40.000000000000000000
          Height = 16.000000000000000000
          DataSet = dmFacturasCompra.fxdsLinFaccSku
          DataSetName = 'LineasFacturaSku'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          StretchMode = smMaxHeight
          Memo.UTF8W = ('[LineasFacturaSku."LINEA_FACCLIN"]')
          ParentFont = False
          WordWrap = False
        end
        object LinArtV: TfrxMemoView
          AllowVectorExport = True
          Left = 40.000000000000000000
          Top = 0.000000000000000000
          Width = 116.000000000000000000
          Height = 16.000000000000000000
          DataSet = dmFacturasCompra.fxdsLinFaccSku
          DataSetName = 'LineasFacturaSku'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haLeft
          VAlign = vaCenter
          StretchMode = smMaxHeight
          Memo.UTF8W = ('[LineasFacturaSku."CODIGO_ART_FACCLIN"]')
          ParentFont = False
        end
        object LinSkuV: TfrxMemoView
          AllowVectorExport = True
          Left = 156.000000000000000000
          Top = 0.000000000000000000
          Width = 196.000000000000000000
          Height = 16.000000000000000000
          DataSet = dmFacturasCompra.fxdsLinFaccSku
          DataSetName = 'LineasFacturaSku'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haLeft
          VAlign = vaCenter
          StretchMode = smMaxHeight
          Memo.UTF8W = ('[LineasFacturaSku."CODIGO_UNIDAD_FACCLIN"]')
          ParentFont = False
        end
        object LinRefV: TfrxMemoView
          AllowVectorExport = True
          Left = 352.000000000000000000
          Top = 0.000000000000000000
          Width = 66.000000000000000000
          Height = 16.000000000000000000
          DataSet = dmFacturasCompra.fxdsLinFaccSku
          DataSetName = 'LineasFacturaSku'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haLeft
          VAlign = vaCenter
          StretchMode = smMaxHeight
          Memo.UTF8W = ('[LineasFacturaSku."REF_PRV_FACCLIN"]')
          ParentFont = False
        end
        object LinDescV: TfrxMemoView
          AllowVectorExport = True
          Left = 418.000000000000000000
          Top = 0.000000000000000000
          Width = 132.000000000000000000
          Height = 16.000000000000000000
          DataSet = dmFacturasCompra.fxdsLinFaccSku
          DataSetName = 'LineasFacturaSku'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haLeft
          VAlign = vaCenter
          StretchMode = smActualHeight
          Memo.UTF8W = ('[LineasFacturaSku."DESCRIPCION_ARTICULO_FACCLIN"][IIF(<LineasFacturaSku."LOTE_FACCLIN"> <> '''', '' Lote: '' + <LineasFacturaSku."LOTE_FACCLIN">, '''')][IIF(<LineasFacturaSku."FECHA_CADUCIDAD_FACCLIN"> > 0, '' Cad.: '' + FormatDateTime(''dd/mm/yyyy'', <LineasFacturaSku."FECHA_CADUCIDAD_FACCLIN">), '''')]')
          ParentFont = False
        end
        object LinCantV: TfrxMemoView
          AllowVectorExport = True
          Left = 550.000000000000000000
          Top = 0.000000000000000000
          Width = 40.000000000000000000
          Height = 16.000000000000000000
          DataSet = dmFacturasCompra.fxdsLinFaccSku
          DataSetName = 'LineasFacturaSku'
          DisplayFormat.FormatStr = '#,##0.##'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haRight
          VAlign = vaCenter
          StretchMode = smMaxHeight
          Memo.UTF8W = (
            '[FormatFloat('#39'0.######'#39', <LineasFacturaSku."CANTIDAD_FACCLIN">)]')
          ParentFont = False
          WordWrap = False
        end
        object LinPrecV: TfrxMemoView
          AllowVectorExport = True
          Left = 590.000000000000000000
          Top = 0.000000000000000000
          Width = 58.000000000000000000
          Height = 16.000000000000000000
          DataSet = dmFacturasCompra.fxdsLinFaccSku
          DataSetName = 'LineasFacturaSku'
          DisplayFormat.FormatStr = '#,##0.00'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haRight
          VAlign = vaCenter
          StretchMode = smMaxHeight
          Memo.UTF8W = ('[LineasFacturaSku."PRECIO_COMPRA_SIVA_ARTICULO_FACCLIN"]')
          ParentFont = False
          WordWrap = False
        end
        object LinTotV: TfrxMemoView
          AllowVectorExport = True
          Left = 648.000000000000000000
          Top = 0.000000000000000000
          Width = 70.110700000000000000
          Height = 16.000000000000000000
          DataSet = dmFacturasCompra.fxdsLinFaccSku
          DataSetName = 'LineasFacturaSku'
          DisplayFormat.FormatStr = '#,##0.00'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haRight
          VAlign = vaCenter
          StretchMode = smMaxHeight
          Memo.UTF8W = ('[LineasFacturaSku."TOTAL_FACCLIN"]')
          ParentFont = False
          WordWrap = False
        end
      end
      object ReportSummaryTotalesFiscales: TfrxReportSummary
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 134.000000000000000000
        Top = 1010.000000000000000000
        Width = 718.110700000000000000
        object MemoTotalesFiscales: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 6.000000000000000000
          Width = 450.000000000000000000
          Height = 120.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Courier New'
          Font.Style = []
          Frame.Typ = [ftTop, ftBottom]
          Memo.UTF8W = (
            'DESGLOSE IVA / RE[IIF((<Factura."PORCENTAJE_IVAN_FACC"> <> 0' +
              ') or (<Factura."TOTAL_BASEI_IVAN_FACC"> <> 0), Chr(13) + Chr' +
              '(10) + '#39'Normal       Base '#39' + FormatFloat('#39'#,##0.00'#39', <Factu' +
              'ra."TOTAL_BASEI_IVAN_FACC">) + '#39'  IVA '#39' + FormatFloat('#39'0.##'#39 +
              ', <Factura."PORCENTAJE_IVAN_FACC">) + '#39'% '#39' + FormatFloat('#39'#,' +
              '##0.00'#39', <Factura."TOTAL_IVAN_FACC">) + IIF(<Factura."TOTAL_' +
              'REN_FACC"> <> 0, '#39'  RE '#39' + FormatFloat('#39'0.##'#39', <Factura."POR' +
              'CENTAJE_REN_FACC">) + '#39'% '#39' + FormatFloat('#39'#,##0.00'#39', <Factur' +
              'a."TOTAL_REN_FACC">), '#39#39'), '#39#39')][IIF((<Factura."PORCENTAJE_IV' +
              'AR_FACC"> <> 0) or (<Factura."TOTAL_BASEI_IVAR_FACC"> <> 0),' +
              ' Chr(13) + Chr(10) + '#39'Reducido     Base '#39' + FormatFloat('#39'#,#' +
              '#0.00'#39', <Factura."TOTAL_BASEI_IVAR_FACC">) + '#39'  IVA '#39' + Form' +
              'atFloat('#39'0.##'#39', <Factura."PORCENTAJE_IVAR_FACC">) + '#39'% '#39' + F' +
              'ormatFloat('#39'#,##0.00'#39', <Factura."TOTAL_IVAR_FACC">) + IIF(<F' +
              'actura."TOTAL_RER_FACC"> <> 0, '#39'  RE '#39' + FormatFloat('#39'0.##'#39',' +
              ' <Factura."PORCENTAJE_RER_FACC">) + '#39'% '#39' + FormatFloat('#39'#,##' +
              '0.00'#39', <Factura."TOTAL_RER_FACC">), '#39#39'), '#39#39')][IIF((<Factura.' +
              '"PORCENTAJE_IVAS_FACC"> <> 0) or (<Factura."TOTAL_BASEI_IVAS' +
              '_FACC"> <> 0), Chr(13) + Chr(10) + '#39'Super red.   Base '#39' + Fo' +
              'rmatFloat('#39'#,##0.00'#39', <Factura."TOTAL_BASEI_IVAS_FACC">) + '#39 +
              '  IVA '#39' + FormatFloat('#39'0.##'#39', <Factura."PORCENTAJE_IVAS_FACC' +
              '">) + '#39'% '#39' + FormatFloat('#39'#,##0.00'#39', <Factura."TOTAL_IVAS_FA' +
              'CC">) + IIF(<Factura."TOTAL_RES_FACC"> <> 0, '#39'  RE '#39' + Forma' +
              'tFloat('#39'0.##'#39', <Factura."PORCENTAJE_RES_FACC">) + '#39'% '#39' + For' +
              'matFloat('#39'#,##0.00'#39', <Factura."TOTAL_RES_FACC">), '#39#39'), '#39#39')]'
            'Exento       Base [FormatFloat('#39'#,##0.00'#39', <Factura."TOTAL_B' +
              'ASEI_IVAE_FACC">)]  IVA [FormatFloat('#39'0.##'#39', <Factura."PORCE' +
              'NTAJE_IVAE_FACC">)]% [FormatFloat('#39'#,##0.00'#39', <Factura."TOTA' +
              'L_IVAE_FACC">)][IIF(<Factura."TOTAL_REE_FACC"> <> 0, '#39'  RE '#39 +
              ' + FormatFloat('#39'0.##'#39', <Factura."PORCENTAJE_REE_FACC">) + '#39'%' +
              ' '#39' + FormatFloat('#39'#,##0.00'#39', <Factura."TOTAL_REE_FACC">), '#39#39 +
              ')]'
            'Base total [FormatFloat('#39'#,##0.00'#39', <Factura."TOTAL_BASES_FA' +
              'CC">)]   Impuestos [FormatFloat('#39'#,##0.00'#39', <Factura."TOTAL_' +
              'IMPUESTOS_FACC">)]'
            '[IIF(<Factura."TOTAL_RETENCION_FACC"> <> 0, '#39'Retencion IRPF ' +
              #39' + FormatFloat('#39'0.##'#39', <Factura."PORCENTAJE_RETENCION_FACC"' +
              '>) + '#39'% -'#39' + FormatFloat('#39'#,##0.00'#39', <Factura."TOTAL_RETENCI' +
              'ON_FACC">), '#39#39')]'
            'TOTAL LIQUIDO [FormatFloat('#39'#,##0.00'#39', <Factura."TOTAL_LIQUI' +
              'DO_FACC">)] EUR')
          ParentFont = False
        end
        object MemoTotBaseLblV: TfrxMemoView
          AllowVectorExport = True
          Left = 470.000000000000000000
          Top = 6.000000000000000000
          Width = 120.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          VAlign = vaCenter
          Memo.UTF8W = (
            'Total bases:')
          ParentFont = False
          WordWrap = False
        end
        object MemoTotBaseV: TfrxMemoView
          AllowVectorExport = True
          Left = 590.000000000000000000
          Top = 6.000000000000000000
          Width = 128.110700000000000000
          Height = 18.000000000000000000
          DataSet = dmFacturasCompra.fxdsCabFacc
          DataSetName = 'Factura'
          DisplayFormat.FormatStr = '#,##0.00'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          VAlign = vaCenter
          Memo.UTF8W = (
            '[Factura."TOTAL_BASES_FACC"]')
          ParentFont = False
          WordWrap = False
        end
        object MemoTotIvaLblV: TfrxMemoView
          AllowVectorExport = True
          Left = 470.000000000000000000
          Top = 26.000000000000000000
          Width = 120.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          VAlign = vaCenter
          Memo.UTF8W = (
            'Total IVA:')
          ParentFont = False
          WordWrap = False
        end
        object MemoTotIvaV: TfrxMemoView
          AllowVectorExport = True
          Left = 590.000000000000000000
          Top = 26.000000000000000000
          Width = 128.110700000000000000
          Height = 18.000000000000000000
          DataSet = dmFacturasCompra.fxdsCabFacc
          DataSetName = 'Factura'
          DisplayFormat.FormatStr = '#,##0.00'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          VAlign = vaCenter
          Memo.UTF8W = (
            '[Factura."TOTAL_IMPUESTOS_FACC"]')
          ParentFont = False
          WordWrap = False
        end
        object MemoTotLiqV: TfrxMemoView
          AllowVectorExport = True
          Left = 470.000000000000000000
          Top = 50.000000000000000000
          Width = 248.110700000000000000
          Height = 26.000000000000000000
          DataSet = dmFacturasCompra.fxdsCabFacc
          DataSetName = 'Factura'
          DisplayFormat.FormatStr = '#,##0.00'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haRight
          VAlign = vaCenter
          Memo.UTF8W = (
            'TOTAL: [Factura."TOTAL_LIQUIDO_FACC"] '#8364)
          ParentFont = False
          WordWrap = False
        end
      end
      object PageFooter1: TfrxPageFooter
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 22.000000000000000000
        Top = 1148.000000000000000000
        Width = 718.110700000000000000
        object MemoPaginaV: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 4.000000000000000000
          Width = 300.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Pág. [Page#] / [TotalPages#] - [Date]')
          ParentFont = False
          WordWrap = False
        end
      end
    end
  end
end
