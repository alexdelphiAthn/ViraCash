inherited frmPrintSimulacionValoracion: TfrmPrintSimulacionValoracion
  Caption = 'Imprimir valoraci'#243'n simulada'
  ClientHeight = 240
  ClientWidth = 341
  TextHeight = 17
  object lblDescripcion: TcxLabel
    Left = 12
    Top = 20
    AutoSize = False
    Caption =
      'Listado de las l'#237'neas con su precio de '#250'ltima compra, su PMP y el '#13 +
      'precio simulado. Excel genera la hoja nativa.'
    Properties.WordWrap = True
    TabOrder = 1
    Transparent = True
    Height = 80
    Width = 173
  end
  inherited frxrprt1: TfrxReport
    Datasets = <
      item
        DataSet = fxdsCabecera
        DataSetName = 'Cabecera'
      end
      item
        DataSet = fxdsLineas
        DataSetName = 'Lineas'
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
        DataSet = fxdsCabecera
        DataSetName = 'Cabecera'
      end
      item
        DataSet = fxdsLineas
        DataSetName = 'Lineas'
      end>
    Variables = <>
    Style = <>
    inherited Page1: TfrxReportPage
      LeftMargin = 10.000000000000000000
      RightMargin = 10.000000000000000000
      TopMargin = 10.000000000000000000
      BottomMargin = 10.000000000000000000
      object ReportTitleValoracion: TfrxReportTitle
        Height = 96.000000000000000000
        Top = 0.000000000000000000
        Width = 718.110700000000000000
        Frame.Typ = []
        object MemoTituloValoracion: TfrxMemoView
          AllowVectorExport = True
          Width = 718.110700000000000000
          Height = 28.000000000000000000
          DataSet = fxdsCabecera
          DataSetName = 'Cabecera'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -19
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haCenter
          Memo.UTF8W = (
            '[Cabecera."TITULO"]')
          ParentFont = False
        end
        object MemoIdentificacionValoracion: TfrxMemoView
          AllowVectorExport = True
          Left = 4.000000000000000000
          Top = 34.000000000000000000
          Width = 710.000000000000000000
          Height = 20.000000000000000000
          DataSet = fxdsCabecera
          DataSetName = 'Cabecera'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[Cabecera."IDENTIFICACION"]')
          ParentFont = False
        end
        object MemoOperacionValoracion: TfrxMemoView
          AllowVectorExport = True
          Left = 4.000000000000000000
          Top = 56.000000000000000000
          Width = 420.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsCabecera
          DataSetName = 'Cabecera'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Cabecera."OPERACION"]')
          ParentFont = False
        end
        object MemoFechaValoracion: TfrxMemoView
          AllowVectorExport = True
          Left = 434.000000000000000000
          Top = 56.000000000000000000
          Width = 280.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsCabecera
          DataSetName = 'Cabecera'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Cabecera."CAP_FECHA"] [FormatDateTime('#39'dd/mm/yyyy hh:nn'#39',' +
            '<Cabecera."FECHA">)]')
          ParentFont = False
        end
      end
      object PageHeaderLineas: TfrxPageHeader
        Height = 28.000000000000000000
        Top = 100.000000000000000000
        Width = 718.110700000000000000
        Frame.Typ = []
        object MemoCabLinea: TfrxMemoView
          AllowVectorExport = True
          Width = 46.000000000000000000
          Height = 26.000000000000000000
          DataSet = fxdsCabecera
          DataSetName = 'Cabecera'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            '[Cabecera."CAP_LINEA"]')
          ParentFont = False
        end
        object MemoCabArticulo: TfrxMemoView
          AllowVectorExport = True
          Left = 46.000000000000000000
          Width = 84.000000000000000000
          Height = 26.000000000000000000
          DataSet = fxdsCabecera
          DataSetName = 'Cabecera'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            '[Cabecera."CAP_ARTICULO"]')
          ParentFont = False
        end
        object MemoCabSku: TfrxMemoView
          AllowVectorExport = True
          Left = 130.000000000000000000
          Width = 150.000000000000000000
          Height = 26.000000000000000000
          DataSet = fxdsCabecera
          DataSetName = 'Cabecera'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            '[Cabecera."CAP_SKU"]')
          ParentFont = False
        end
        object MemoCabDescripcion: TfrxMemoView
          AllowVectorExport = True
          Left = 280.000000000000000000
          Width = 150.000000000000000000
          Height = 26.000000000000000000
          DataSet = fxdsCabecera
          DataSetName = 'Cabecera'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            '[Cabecera."CAP_DESCRIPCION"]')
          ParentFont = False
        end
        object MemoCabUnidades: TfrxMemoView
          AllowVectorExport = True
          Left = 430.000000000000000000
          Width = 52.000000000000000000
          Height = 26.000000000000000000
          DataSet = fxdsCabecera
          DataSetName = 'Cabecera'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[Cabecera."CAP_UNIDADES"]')
          ParentFont = False
        end
        object MemoCabUltimaCompra: TfrxMemoView
          AllowVectorExport = True
          Left = 482.000000000000000000
          Width = 84.000000000000000000
          Height = 26.000000000000000000
          DataSet = fxdsCabecera
          DataSetName = 'Cabecera'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[Cabecera."CAP_ULTIMA_COMPRA"]')
          ParentFont = False
        end
        object MemoCabPrecioMedio: TfrxMemoView
          AllowVectorExport = True
          Left = 566.000000000000000000
          Width = 74.000000000000000000
          Height = 26.000000000000000000
          DataSet = fxdsCabecera
          DataSetName = 'Cabecera'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[Cabecera."CAP_PRECIO_MEDIO"]')
          ParentFont = False
        end
        object MemoCabPrecioSimulado: TfrxMemoView
          AllowVectorExport = True
          Left = 640.000000000000000000
          Width = 74.000000000000000000
          Height = 26.000000000000000000
          DataSet = fxdsCabecera
          DataSetName = 'Cabecera'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[Cabecera."CAP_PRECIO_SIMULADO"]')
          ParentFont = False
        end
      end
      object MasterDataLineas: TfrxMasterData
        Height = 18.000000000000000000
        Top = 132.000000000000000000
        Width = 718.110700000000000000
        DataSet = fxdsLineas
        DataSetName = 'Lineas'
        RowCount = 0
        Stretched = True
        Frame.Typ = []
        object MemoLinea: TfrxMemoView
          AllowVectorExport = True
          Top = 1.000000000000000000
          Width = 46.000000000000000000
          Height = 16.000000000000000000
          DataField = 'LINEA'
          DataSet = fxdsLineas
          DataSetName = 'Lineas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Lineas."LINEA"]')
          ParentFont = False
        end
        object MemoArticulo: TfrxMemoView
          AllowVectorExport = True
          Left = 46.000000000000000000
          Top = 1.000000000000000000
          Width = 84.000000000000000000
          Height = 16.000000000000000000
          DataField = 'ARTICULO'
          DataSet = fxdsLineas
          DataSetName = 'Lineas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Lineas."ARTICULO"]')
          ParentFont = False
          StretchMode = smActualHeight
        end
        object MemoSku: TfrxMemoView
          AllowVectorExport = True
          Left = 130.000000000000000000
          Top = 1.000000000000000000
          Width = 150.000000000000000000
          Height = 16.000000000000000000
          DataField = 'SKU'
          DataSet = fxdsLineas
          DataSetName = 'Lineas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Lineas."SKU"]')
          ParentFont = False
          StretchMode = smActualHeight
        end
        object MemoDescripcion: TfrxMemoView
          AllowVectorExport = True
          Left = 280.000000000000000000
          Top = 1.000000000000000000
          Width = 150.000000000000000000
          Height = 16.000000000000000000
          DataField = 'DESCRIPCION'
          DataSet = fxdsLineas
          DataSetName = 'Lineas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Lineas."DESCRIPCION"]')
          ParentFont = False
          StretchMode = smActualHeight
          WordWrap = True
        end
        object MemoUnidades: TfrxMemoView
          AllowVectorExport = True
          Left = 430.000000000000000000
          Top = 1.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          DataField = 'UNIDADES'
          DataSet = fxdsLineas
          DataSetName = 'Lineas'
          DisplayFormat.FormatStr = '#,##0.####'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Lineas."UNIDADES"]')
          ParentFont = False
        end
        object MemoUltimaCompra: TfrxMemoView
          AllowVectorExport = True
          Left = 482.000000000000000000
          Top = 1.000000000000000000
          Width = 84.000000000000000000
          Height = 16.000000000000000000
          DataField = 'PRECIO_ULTIMA_COMPRA'
          DataSet = fxdsLineas
          DataSetName = 'Lineas'
          DisplayFormat.FormatStr = '#,##0.0000'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Lineas."PRECIO_ULTIMA_COMPRA"]')
          ParentFont = False
        end
        object MemoPrecioMedio: TfrxMemoView
          AllowVectorExport = True
          Left = 566.000000000000000000
          Top = 1.000000000000000000
          Width = 74.000000000000000000
          Height = 16.000000000000000000
          DataField = 'PRECIO_MEDIO'
          DataSet = fxdsLineas
          DataSetName = 'Lineas'
          DisplayFormat.FormatStr = '#,##0.0000'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Lineas."PRECIO_MEDIO"]')
          ParentFont = False
        end
        object MemoPrecioSimulado: TfrxMemoView
          AllowVectorExport = True
          Left = 640.000000000000000000
          Top = 1.000000000000000000
          Width = 74.000000000000000000
          Height = 16.000000000000000000
          DataField = 'PRECIO_SIMULADO'
          DataSet = fxdsLineas
          DataSetName = 'Lineas'
          DisplayFormat.FormatStr = '#,##0.0000'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Lineas."PRECIO_SIMULADO"]')
          ParentFont = False
        end
      end
      object ReportSummaryValoracion: TfrxReportSummary
        Height = 100.000000000000000000
        Top = 154.000000000000000000
        Width = 718.110700000000000000
        Frame.Typ = []
        object MemoEtiquetaLineas: TfrxMemoView
          AllowVectorExport = True
          Left = 430.000000000000000000
          Top = 8.000000000000000000
          Width = 170.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsCabecera
          DataSetName = 'Cabecera'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Cabecera."CAP_LINEAS_SIMULADAS"]')
          ParentFont = False
        end
        object MemoTotalLineas: TfrxMemoView
          AllowVectorExport = True
          Left = 604.000000000000000000
          Top = 8.000000000000000000
          Width = 110.000000000000000000
          Height = 18.000000000000000000
          DataField = 'NUMERO_LINEAS'
          DataSet = fxdsCabecera
          DataSetName = 'Cabecera'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Cabecera."NUMERO_LINEAS"]')
          ParentFont = False
        end
        object MemoEtiquetaValorAnterior: TfrxMemoView
          AllowVectorExport = True
          Left = 430.000000000000000000
          Top = 30.000000000000000000
          Width = 170.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsCabecera
          DataSetName = 'Cabecera'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Cabecera."CAP_VALOR_ANTERIOR"]')
          ParentFont = False
        end
        object MemoTotalValorAnterior: TfrxMemoView
          AllowVectorExport = True
          Left = 604.000000000000000000
          Top = 30.000000000000000000
          Width = 110.000000000000000000
          Height = 18.000000000000000000
          DataField = 'VALOR_ANTERIOR'
          DataSet = fxdsCabecera
          DataSetName = 'Cabecera'
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
            '[Cabecera."VALOR_ANTERIOR"]')
          ParentFont = False
        end
        object MemoEtiquetaValorSimulado: TfrxMemoView
          AllowVectorExport = True
          Left = 430.000000000000000000
          Top = 52.000000000000000000
          Width = 170.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsCabecera
          DataSetName = 'Cabecera'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Cabecera."CAP_VALOR_SIMULADO"]')
          ParentFont = False
        end
        object MemoTotalValorSimulado: TfrxMemoView
          AllowVectorExport = True
          Left = 604.000000000000000000
          Top = 52.000000000000000000
          Width = 110.000000000000000000
          Height = 18.000000000000000000
          DataField = 'VALOR_SIMULADO'
          DataSet = fxdsCabecera
          DataSetName = 'Cabecera'
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
            '[Cabecera."VALOR_SIMULADO"]')
          ParentFont = False
        end
        object MemoEtiquetaDiferencia: TfrxMemoView
          AllowVectorExport = True
          Left = 430.000000000000000000
          Top = 74.000000000000000000
          Width = 170.000000000000000000
          Height = 20.000000000000000000
          DataSet = fxdsCabecera
          DataSetName = 'Cabecera'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[Cabecera."CAP_DIFERENCIA"]')
          ParentFont = False
        end
        object MemoTotalDiferencia: TfrxMemoView
          AllowVectorExport = True
          Left = 604.000000000000000000
          Top = 74.000000000000000000
          Width = 110.000000000000000000
          Height = 20.000000000000000000
          DataField = 'DIFERENCIA'
          DataSet = fxdsCabecera
          DataSetName = 'Cabecera'
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
            '[Cabecera."DIFERENCIA"]')
          ParentFont = False
        end
      end
      object PageFooterValoracion: TfrxPageFooter
        Height = 18.000000000000000000
        Top = 258.000000000000000000
        Width = 718.110700000000000000
        Frame.Typ = []
        object MemoPaginaValoracion: TfrxMemoView
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
  object dsCabecera: TDataSource
    Left = 24
    Top = 120
  end
  object dsLineas: TDataSource
    Left = 24
    Top = 168
  end
  object fxdsCabecera: TfrxDBDataset
    Description = 'Cabecera de la valoraci'#243'n'
    UserName = 'Cabecera'
    CloseDataSource = False
    DataSource = dsCabecera
    BCDToCurrency = False
    DataSetOptions = []
    Left = 104
    Top = 120
  end
  object fxdsLineas: TfrxDBDataset
    Description = 'L'#237'neas de la valoraci'#243'n'
    UserName = 'Lineas'
    CloseDataSource = False
    DataSource = dsLineas
    BCDToCurrency = False
    DataSetOptions = []
    Left = 104
    Top = 168
  end
  object cdsCabecera: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 184
    Top = 120
  end
  object cdsLineas: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 184
    Top = 168
  end
end
