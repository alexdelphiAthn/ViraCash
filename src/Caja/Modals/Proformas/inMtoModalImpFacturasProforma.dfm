inherited frmPrintFacturasProforma: TfrmPrintFacturasProforma
  Caption = 'Imprimir factura proforma'
  ClientHeight = 240
  ClientWidth = 341
  TextHeight = 17
  object lblDocumentoNoFiscal: TcxLabel
    Left = 12
    Top = 20
    AutoSize = False
    Caption =
      'Propuesta interna de caja. No es una factura fiscal y no '#13 +
      'declara IVA ni VeriFactu.'
    Properties.WordWrap = True
    TabOrder = 1
    Transparent = True
    Height = 80
    Width = 173
  end
  inherited frxrprt1: TfrxReport
    Datasets = <
      item
        DataSet = fxdsProforma
        DataSetName = 'Proforma'
      end
      item
        DataSet = fxdsLineasProforma
        DataSetName = 'LineasProforma'
      end>
    Variables = <>
    Style = <>
    inherited Page1: TfrxReportPage
      LeftMargin = 10.000000000000000000
      RightMargin = 10.000000000000000000
      TopMargin = 10.000000000000000000
      BottomMargin = 10.000000000000000000
    end
  end
  inherited frxReportOrigen: TfrxReport
    Datasets = <
      item
        DataSet = fxdsProforma
        DataSetName = 'Proforma'
      end
      item
        DataSet = fxdsLineasProforma
        DataSetName = 'LineasProforma'
      end>
    Variables = <>
    Style = <>
    inherited Page1: TfrxReportPage
      LeftMargin = 10.000000000000000000
      RightMargin = 10.000000000000000000
      TopMargin = 10.000000000000000000
      BottomMargin = 10.000000000000000000
      object ReportTitleProforma: TfrxReportTitle
        Height = 150.000000000000000000
        Top = 0.000000000000000000
        Width = 718.110700000000000000
        Frame.Typ = []
        object MemoTituloProforma: TfrxMemoView
          AllowVectorExport = True
          Width = 718.110700000000000000
          Height = 28.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -19
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haCenter
          Memo.UTF8W = (
            'FACTURA PROFORMA INTERNA')
          ParentFont = False
        end
        object MemoAvisoNoFiscal: TfrxMemoView
          AllowVectorExport = True
          Top = 30.000000000000000000
          Width = 718.110700000000000000
          Height = 24.000000000000000000
          Color = 14020607
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 192
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            'DOCUMENTO NO FISCAL - NO DECLARA IVA NI VERIFACTU')
          ParentFont = False
          VAlign = vaCenter
        end
        object MemoEmpresaProforma: TfrxMemoView
          AllowVectorExport = True
          Left = 4.000000000000000000
          Top = 62.000000000000000000
          Width = 350.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsProforma
          DataSetName = 'Proforma'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[Proforma."RAZON_SOCIAL_EMPRESA_PROCAJ"]')
          ParentFont = False
        end
        object MemoNifEmpresaProforma: TfrxMemoView
          AllowVectorExport = True
          Left = 4.000000000000000000
          Top = 82.000000000000000000
          Width = 350.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsProforma
          DataSetName = 'Proforma'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'NIF: [Proforma."NIF_EMPRESA_PROCAJ"]')
          ParentFont = False
        end
        object MemoClienteProforma: TfrxMemoView
          AllowVectorExport = True
          Left = 4.000000000000000000
          Top = 104.000000000000000000
          Width = 350.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsProforma
          DataSetName = 'Proforma'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Cliente: [Proforma."RAZON_SOCIAL_CLIENTE_PROCAJ"]')
          ParentFont = False
        end
        object MemoDocumentoProforma: TfrxMemoView
          AllowVectorExport = True
          Left = 374.000000000000000000
          Top = 62.000000000000000000
          Width = 340.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsProforma
          DataSetName = 'Proforma'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            'Documento: [Proforma."SERIE_PROCAJ"]/' +
            '[Proforma."NUMERO_PROCAJ"]')
          ParentFont = False
        end
        object MemoFechaProforma: TfrxMemoView
          AllowVectorExport = True
          Left = 374.000000000000000000
          Top = 82.000000000000000000
          Width = 340.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsProforma
          DataSetName = 'Proforma'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            'Fecha: [FormatDateTime('#39'dd/mm/yyyy'#39',' +
            '<Proforma."FECHA_PROCAJ">)]')
          ParentFont = False
        end
        object MemoPeriodoProforma: TfrxMemoView
          AllowVectorExport = True
          Left = 354.000000000000000000
          Top = 104.000000000000000000
          Width = 360.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsProforma
          DataSetName = 'Proforma'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            'Periodo: [FormatDateTime('#39'dd/mm/yyyy'#39',' +
            '<Proforma."FECHA_DESDE_PROCAJ">)] - ' +
            '[FormatDateTime('#39'dd/mm/yyyy'#39',' +
            '<Proforma."FECHA_HASTA_PROCAJ">)]')
          ParentFont = False
        end
        object MemoVentaContado: TfrxMemoView
          AllowVectorExport = True
          Left = 4.000000000000000000
          Top = 128.000000000000000000
          Width = 710.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGray
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsItalic]
          Frame.Typ = []
          Memo.UTF8W = (
            'Resumen interno de operaciones de caja entre empresas.')
          ParentFont = False
        end
      end
      object PageHeaderLineas: TfrxPageHeader
        Height = 24.000000000000000000
        Top = 154.000000000000000000
        Width = 718.110700000000000000
        Frame.Typ = []
        object MemoCabArticulo: TfrxMemoView
          AllowVectorExport = True
          Width = 100.000000000000000000
          Height = 22.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Art'#237'culo')
          ParentFont = False
        end
        object MemoCabDescripcion: TfrxMemoView
          AllowVectorExport = True
          Left = 100.000000000000000000
          Width = 278.000000000000000000
          Height = 22.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Descripci'#243'n')
          ParentFont = False
        end
        object MemoCabCantidad: TfrxMemoView
          AllowVectorExport = True
          Left = 378.000000000000000000
          Width = 72.000000000000000000
          Height = 22.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Cantidad')
          ParentFont = False
        end
        object MemoCabPrecio: TfrxMemoView
          AllowVectorExport = True
          Left = 450.000000000000000000
          Width = 86.000000000000000000
          Height = 22.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Precio base')
          ParentFont = False
        end
        object MemoCabIva: TfrxMemoView
          AllowVectorExport = True
          Left = 536.000000000000000000
          Width = 60.000000000000000000
          Height = 22.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'IVA inf.')
          ParentFont = False
        end
        object MemoCabTotal: TfrxMemoView
          AllowVectorExport = True
          Left = 596.000000000000000000
          Width = 118.000000000000000000
          Height = 22.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Total')
          ParentFont = False
        end
      end
      object GroupHeaderOperacion: TfrxGroupHeader
        Height = 28.000000000000000000
        Top = 182.000000000000000000
        Width = 718.110700000000000000
        Condition = 'LineasProforma."ID_OPCAJA_PROCLIN"'
        ReprintOnNewPage = True
        Frame.Typ = []
        object MemoFondoOperacion: TfrxMemoView
          AllowVectorExport = True
          Top = 2.000000000000000000
          Width = 714.000000000000000000
          Height = 24.000000000000000000
          Color = 15395562
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Memo.UTF8W = (
            '[LineasProforma."DESCRIPCION_VINCULO_PROCLIN"] - ' +
            'Operación [LineasProforma."NUMERO_OPERACION_PROCLIN"]')
          GapX = 5.000000000000000000
          ParentFont = False
          VAlign = vaCenter
        end
        object MemoFechaOperacion: TfrxMemoView
          AllowVectorExport = True
          Left = 565.000000000000000000
          Top = 5.000000000000000000
          Width = 140.000000000000000000
          Height = 18.000000000000000000
          DataField = 'FECHA_OPERACION_PROCLIN'
          DataSet = fxdsLineasProforma
          DataSetName = 'LineasProforma'
          DisplayFormat.FormatStr = 'dd/mm/yyyy'
          DisplayFormat.Kind = fkDateTime
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[LineasProforma."FECHA_OPERACION_PROCLIN"]')
          ParentFont = False
        end
      end
      object MasterDataLineas: TfrxMasterData
        Height = 30.000000000000000000
        Top = 214.000000000000000000
        Width = 718.110700000000000000
        DataSet = fxdsLineasProforma
        DataSetName = 'LineasProforma'
        RowCount = 0
        Frame.Typ = []
        object MemoArticulo: TfrxMemoView
          AllowVectorExport = True
          Top = 2.000000000000000000
          Width = 100.000000000000000000
          Height = 26.000000000000000000
          DataField = 'CODIGO_ART_PROCLIN'
          DataSet = fxdsLineasProforma
          DataSetName = 'LineasProforma'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[LineasProforma."CODIGO_ART_PROCLIN"]')
          ParentFont = False
        end
        object MemoDescripcion: TfrxMemoView
          AllowVectorExport = True
          Left = 100.000000000000000000
          Top = 2.000000000000000000
          Width = 278.000000000000000000
          Height = 26.000000000000000000
          DataSet = fxdsLineasProforma
          DataSetName = 'LineasProforma'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[LineasProforma."CODIGO_UNIDAD_PROCLIN"] ' +
            '[LineasProforma."DESCRIPCION_ARTICULO_PROCLIN"]')
          ParentFont = False
          WordWrap = True
        end
        object MemoCantidad: TfrxMemoView
          AllowVectorExport = True
          Left = 378.000000000000000000
          Top = 2.000000000000000000
          Width = 72.000000000000000000
          Height = 18.000000000000000000
          DataField = 'CANTIDAD_PROCLIN'
          DataSet = fxdsLineasProforma
          DataSetName = 'LineasProforma'
          DisplayFormat.FormatStr = '0.######'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[LineasProforma."CANTIDAD_PROCLIN"]')
          ParentFont = False
        end
        object MemoPrecioBase: TfrxMemoView
          AllowVectorExport = True
          Left = 450.000000000000000000
          Top = 2.000000000000000000
          Width = 86.000000000000000000
          Height = 18.000000000000000000
          DataField = 'PRECIO_SIVA_PROCLIN'
          DataSet = fxdsLineasProforma
          DataSetName = 'LineasProforma'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[LineasProforma."PRECIO_SIVA_PROCLIN"]')
          ParentFont = False
        end
        object MemoIvaInformativo: TfrxMemoView
          AllowVectorExport = True
          Left = 536.000000000000000000
          Top = 2.000000000000000000
          Width = 60.000000000000000000
          Height = 18.000000000000000000
          DataField = 'PORCENTAJE_IVA_PROCLIN'
          DataSet = fxdsLineasProforma
          DataSetName = 'LineasProforma'
          DisplayFormat.FormatStr = '%g %%'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[LineasProforma."PORCENTAJE_IVA_PROCLIN"]')
          ParentFont = False
        end
        object MemoTotalLinea: TfrxMemoView
          AllowVectorExport = True
          Left = 596.000000000000000000
          Top = 2.000000000000000000
          Width = 118.000000000000000000
          Height = 18.000000000000000000
          DataField = 'TOTAL_PROCLIN'
          DataSet = fxdsLineasProforma
          DataSetName = 'LineasProforma'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[LineasProforma."TOTAL_PROCLIN"]')
          ParentFont = False
        end
      end
      object ReportSummaryProforma: TfrxReportSummary
        Height = 108.000000000000000000
        Top = 248.000000000000000000
        Width = 718.110700000000000000
        Frame.Typ = []
        object MemoEtiquetaBase: TfrxMemoView
          AllowVectorExport = True
          Left = 476.000000000000000000
          Top = 8.000000000000000000
          Width = 124.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            'Base informativa:')
          ParentFont = False
        end
        object MemoTotalBase: TfrxMemoView
          AllowVectorExport = True
          Left = 604.000000000000000000
          Top = 8.000000000000000000
          Width = 110.000000000000000000
          Height = 18.000000000000000000
          DataField = 'TOTAL_BASE_PROCAJ'
          DataSet = fxdsProforma
          DataSetName = 'Proforma'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Proforma."TOTAL_BASE_PROCAJ"]')
          ParentFont = False
        end
        object MemoEtiquetaIva: TfrxMemoView
          AllowVectorExport = True
          Left = 476.000000000000000000
          Top = 30.000000000000000000
          Width = 124.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            'IVA informativo:')
          ParentFont = False
        end
        object MemoTotalIva: TfrxMemoView
          AllowVectorExport = True
          Left = 604.000000000000000000
          Top = 30.000000000000000000
          Width = 110.000000000000000000
          Height = 18.000000000000000000
          DataField = 'TOTAL_IMPUESTOS_PROCAJ'
          DataSet = fxdsProforma
          DataSetName = 'Proforma'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Proforma."TOTAL_IMPUESTOS_PROCAJ"]')
          ParentFont = False
        end
        object MemoEtiquetaTotal: TfrxMemoView
          AllowVectorExport = True
          Left = 476.000000000000000000
          Top = 52.000000000000000000
          Width = 124.000000000000000000
          Height = 20.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            'TOTAL:')
          ParentFont = False
        end
        object MemoTotalProforma: TfrxMemoView
          AllowVectorExport = True
          Left = 604.000000000000000000
          Top = 52.000000000000000000
          Width = 110.000000000000000000
          Height = 20.000000000000000000
          DataField = 'TOTAL_PROCAJ'
          DataSet = fxdsProforma
          DataSetName = 'Proforma'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[Proforma."TOTAL_PROCAJ"]')
          ParentFont = False
        end
        object MemoPieNoFiscal: TfrxMemoView
          AllowVectorExport = True
          Left = 4.000000000000000000
          Top = 82.000000000000000000
          Width = 710.000000000000000000
          Height = 22.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 192
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haCenter
          Memo.UTF8W = (
            'Documento interno sin efectos fiscales. IVA meramente ' +
            'informativo. No se remite a VeriFactu.')
          ParentFont = False
        end
      end
      object PageFooterProforma: TfrxPageFooter
        Height = 18.000000000000000000
        Top = 360.000000000000000000
        Width = 718.110700000000000000
        Frame.Typ = []
        object MemoPaginaProforma: TfrxMemoView
          AllowVectorExport = True
          Width = 714.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGray
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            'P'#225'gina [Page#]')
          ParentFont = False
        end
      end
    end
  end
  object dsProforma: TDataSource
    Left = 24
    Top = 120
  end
  object dsLineasProforma: TDataSource
    Left = 24
    Top = 168
  end
  object fxdsProforma: TfrxDBDataset
    Description = 'Proforma interna'
    UserName = 'Proforma'
    CloseDataSource = False
    DataSource = dsProforma
    BCDToCurrency = False
    DataSetOptions = []
    Left = 104
    Top = 120
  end
  object fxdsLineasProforma: TfrxDBDataset
    Description = 'L'#237'neas de proforma interna'
    UserName = 'LineasProforma'
    CloseDataSource = False
    DataSource = dsLineasProforma
    BCDToCurrency = False
    DataSetOptions = []
    Left = 104
    Top = 168
  end
end
