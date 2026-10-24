inherited frmPrintLibrosIva: TfrmPrintLibrosIva
  Caption = 'Libros de IVA'
  ClientWidth = 1040
  StyleElements = [seFont, seClient, seBorder]
  ExplicitWidth = 1056
  ExplicitHeight = 509
  TextHeight = 17
  inherited pnl1: TPanel
    Left = 896
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 896
    ExplicitHeight = 470
    inherited btnExcel: TcxButton
      Caption = 'E&xcel (nativo)'
      OnClick = btnExcelNativoClick
    end
  end
  inherited frxrprt1: TfrxReport
    Datasets = <
      item
        DataSet = fxdsLibrosIva
        DataSetName = 'LibrosIva'
      end
      item
        DataSet = fxdsResumenIva
        DataSetName = 'ResumenIva'
      end
      item
        DataSet = fxdsLiquidacionIva
        DataSetName = 'LiquidacionIva'
      end>
    Variables = <>
    Style = <>
    inherited Page1: TfrxReportPage
      Orientation = poLandscape
      PaperWidth = 297.000000000000000000
      PaperHeight = 210.000000000000000000
      PaperSize = 256
      LeftMargin = 10.000000000000000000
      RightMargin = 10.000000000000000000
      TopMargin = 10.000000000000000000
      BottomMargin = 10.000000000000000000
    end
  end
  inherited frxReportOrigen: TfrxReport
    Datasets = <
      item
        DataSet = fxdsLibrosIva
        DataSetName = 'LibrosIva'
      end
      item
        DataSet = fxdsResumenIva
        DataSetName = 'ResumenIva'
      end
      item
        DataSet = fxdsLiquidacionIva
        DataSetName = 'LiquidacionIva'
      end>
    Variables = <>
    Style = <>
    inherited Page1: TfrxReportPage
      Orientation = poLandscape
      PaperWidth = 297.000000000000000000
      PaperHeight = 210.000000000000000000
      PaperSize = 256
      LeftMargin = 10.000000000000000000
      RightMargin = 10.000000000000000000
      TopMargin = 10.000000000000000000
      BottomMargin = 10.000000000000000000
      object ReportTitle1: TfrxReportTitle
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 32.000000000000000000
        Width = 1046.000000000000000000
        object MemoTitulo: TfrxMemoView
          AllowVectorExport = True
          Top = 2.000000000000000000
          Width = 620.000000000000000000
          Height = 22.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -16
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            'Libros de IVA')
          ParentFont = False
        end
        object MemoImpreso: TfrxMemoView
          AllowVectorExport = True
          Left = 700.000000000000000000
          Top = 8.000000000000000000
          Width = 346.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            'Impreso el [Date]')
          ParentFont = False
        end
      end
      object GroupHeaderEmpresa: TfrxGroupHeader
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 22.000000000000000000
        Top = 36.000000000000000000
        Width = 1046.000000000000000000
        Condition = 'LibrosIva."EMPRESA"'
        object MemoEmpresa: TfrxMemoView
          AllowVectorExport = True
          Top = 2.000000000000000000
          Width = 1046.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            'Empresa [LibrosIva."EMPRESA"] - [LibrosIva."RAZON_SOCIAL_EMPRESA"]')
          ParentFont = False
        end
      end
      object GroupHeaderLibro: TfrxGroupHeader
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 40.000000000000000000
        Top = 62.000000000000000000
        Width = 1046.000000000000000000
        Condition = 'LibrosIva."LIBRO"'
        ReprintOnNewPage = True
        object MemoLibro: TfrxMemoView
          AllowVectorExport = True
          Top = 2.000000000000000000
          Width = 1046.000000000000000000
          Height = 16.000000000000000000
          Color = 14540253
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          Memo.UTF8W = (
            '[IIF(<LibrosIva."LIBRO"> = ''REP'', ''IVA REPERCUTIDO (ventas)'', ''IVA SOPORTADO (compras)'')]')
          ParentFont = False
        end
        object MemoHFecha: TfrxMemoView
          AllowVectorExport = True
          Top = 22.000000000000000000
          Width = 60.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Fecha')
          ParentFont = False
        end
        object MemoHDoc: TfrxMemoView
          AllowVectorExport = True
          Left = 62.000000000000000000
          Top = 22.000000000000000000
          Width = 100.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Factura')
          ParentFont = False
        end
        object MemoHTipoDoc: TfrxMemoView
          AllowVectorExport = True
          Left = 164.000000000000000000
          Top = 22.000000000000000000
          Width = 70.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Tipo')
          ParentFont = False
        end
        object MemoHNif: TfrxMemoView
          AllowVectorExport = True
          Left = 236.000000000000000000
          Top = 22.000000000000000000
          Width = 80.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'NIF')
          ParentFont = False
        end
        object MemoHNombre: TfrxMemoView
          AllowVectorExport = True
          Left = 318.000000000000000000
          Top = 22.000000000000000000
          Width = 250.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Cliente / proveedor')
          ParentFont = False
        end
        object MemoHDocExt: TfrxMemoView
          AllowVectorExport = True
          Left = 570.000000000000000000
          Top = 22.000000000000000000
          Width = 108.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'N'#186' fra. proveedor')
          ParentFont = False
        end
        object MemoHPorcIva: TfrxMemoView
          AllowVectorExport = True
          Left = 680.000000000000000000
          Top = 22.000000000000000000
          Width = 46.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '% IVA')
          ParentFont = False
        end
        object MemoHBase: TfrxMemoView
          AllowVectorExport = True
          Left = 728.000000000000000000
          Top = 22.000000000000000000
          Width = 80.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Base imponible')
          ParentFont = False
        end
        object MemoHCuotaIva: TfrxMemoView
          AllowVectorExport = True
          Left = 810.000000000000000000
          Top = 22.000000000000000000
          Width = 72.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Cuota IVA')
          ParentFont = False
        end
        object MemoHPorcRe: TfrxMemoView
          AllowVectorExport = True
          Left = 884.000000000000000000
          Top = 22.000000000000000000
          Width = 40.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '% RE')
          ParentFont = False
        end
        object MemoHCuotaRe: TfrxMemoView
          AllowVectorExport = True
          Left = 926.000000000000000000
          Top = 22.000000000000000000
          Width = 56.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Cuota RE')
          ParentFont = False
        end
        object MemoHTotal: TfrxMemoView
          AllowVectorExport = True
          Left = 984.000000000000000000
          Top = 22.000000000000000000
          Width = 62.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Total')
          ParentFont = False
        end
      end
      object MasterData1: TfrxMasterData
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 16.000000000000000000
        Top = 106.000000000000000000
        Width = 1046.000000000000000000
        DataSet = fxdsLibrosIva
        DataSetName = 'LibrosIva'
        RowCount = 0
        object MemoFecha: TfrxMemoView
          AllowVectorExport = True
          Top = 1.000000000000000000
          Width = 60.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsLibrosIva
          DataSetName = 'LibrosIva'
          DisplayFormat.FormatStr = 'dd/mm/yyyy'
          DisplayFormat.Kind = fkDateTime
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[LibrosIva."FECHA"]')
          ParentFont = False
        end
        object MemoDoc: TfrxMemoView
          AllowVectorExport = True
          Left = 62.000000000000000000
          Top = 1.000000000000000000
          Width = 100.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsLibrosIva
          DataSetName = 'LibrosIva'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[LibrosIva."DOCUMENTO"]')
          ParentFont = False
        end
        object MemoTipoDoc: TfrxMemoView
          AllowVectorExport = True
          Left = 164.000000000000000000
          Top = 1.000000000000000000
          Width = 70.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsLibrosIva
          DataSetName = 'LibrosIva'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[LibrosIva."TIPO_DOC"]')
          ParentFont = False
        end
        object MemoNif: TfrxMemoView
          AllowVectorExport = True
          Left = 236.000000000000000000
          Top = 1.000000000000000000
          Width = 80.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsLibrosIva
          DataSetName = 'LibrosIva'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[LibrosIva."NIF"]')
          ParentFont = False
        end
        object MemoNombre: TfrxMemoView
          AllowVectorExport = True
          Left = 318.000000000000000000
          Top = 1.000000000000000000
          Width = 250.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsLibrosIva
          DataSetName = 'LibrosIva'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[LibrosIva."NOMBRE"]')
          ParentFont = False
        end
        object MemoDocExt: TfrxMemoView
          AllowVectorExport = True
          Left = 570.000000000000000000
          Top = 1.000000000000000000
          Width = 108.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsLibrosIva
          DataSetName = 'LibrosIva'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[LibrosIva."DOC_EXTERNO"]')
          ParentFont = False
        end
        object MemoPorcIva: TfrxMemoView
          AllowVectorExport = True
          Left = 680.000000000000000000
          Top = 1.000000000000000000
          Width = 46.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsLibrosIva
          DataSetName = 'LibrosIva'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[LibrosIva."PORC_IVA"]')
          ParentFont = False
        end
        object MemoBase: TfrxMemoView
          AllowVectorExport = True
          Left = 728.000000000000000000
          Top = 1.000000000000000000
          Width = 80.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsLibrosIva
          DataSetName = 'LibrosIva'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[LibrosIva."BASE"]')
          ParentFont = False
        end
        object MemoCuotaIva: TfrxMemoView
          AllowVectorExport = True
          Left = 810.000000000000000000
          Top = 1.000000000000000000
          Width = 72.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsLibrosIva
          DataSetName = 'LibrosIva'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[LibrosIva."CUOTA_IVA"]')
          ParentFont = False
        end
        object MemoPorcRe: TfrxMemoView
          AllowVectorExport = True
          Left = 884.000000000000000000
          Top = 1.000000000000000000
          Width = 40.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsLibrosIva
          DataSetName = 'LibrosIva'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[LibrosIva."PORC_RE"]')
          ParentFont = False
        end
        object MemoCuotaRe: TfrxMemoView
          AllowVectorExport = True
          Left = 926.000000000000000000
          Top = 1.000000000000000000
          Width = 56.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsLibrosIva
          DataSetName = 'LibrosIva'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[LibrosIva."CUOTA_RE"]')
          ParentFont = False
        end
        object MemoTotal: TfrxMemoView
          AllowVectorExport = True
          Left = 984.000000000000000000
          Top = 1.000000000000000000
          Width = 62.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsLibrosIva
          DataSetName = 'LibrosIva'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[LibrosIva."TOTAL"]')
          ParentFont = False
        end
      end
      object GroupFooterLibro: TfrxGroupFooter
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 26.000000000000000000
        Top = 126.000000000000000000
        Width = 1046.000000000000000000
        object MemoTotLibro: TfrxMemoView
          AllowVectorExport = True
          Top = 2.000000000000000000
          Width = 678.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          Memo.UTF8W = (
            'TOTAL [IIF(<LibrosIva."LIBRO"> = ''REP'', ''IVA REPERCUTIDO (ventas)'', ''IVA SOPORTADO (compras)'')]')
          ParentFont = False
        end
        object MemoTotBase: TfrxMemoView
          AllowVectorExport = True
          Left = 728.000000000000000000
          Top = 2.000000000000000000
          Width = 80.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<LibrosIva."BASE">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotCuotaIva: TfrxMemoView
          AllowVectorExport = True
          Left = 810.000000000000000000
          Top = 2.000000000000000000
          Width = 72.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<LibrosIva."CUOTA_IVA">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotCuotaRe: TfrxMemoView
          AllowVectorExport = True
          Left = 926.000000000000000000
          Top = 2.000000000000000000
          Width = 56.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<LibrosIva."CUOTA_RE">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotTotal: TfrxMemoView
          AllowVectorExport = True
          Left = 984.000000000000000000
          Top = 2.000000000000000000
          Width = 62.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<LibrosIva."TOTAL">,MasterData1)]')
          ParentFont = False
        end
      end
      object HeaderResumen: TfrxHeader
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 44.000000000000000000
        Top = 156.000000000000000000
        Width = 1046.000000000000000000
        object MemoTituloResumen: TfrxMemoView
          AllowVectorExport = True
          Top = 6.000000000000000000
          Width = 1046.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            'Resumen por tipo de IVA')
          ParentFont = False
        end
        object MemoHRLibro: TfrxMemoView
          AllowVectorExport = True
          Top = 26.000000000000000000
          Width = 400.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Libro')
          ParentFont = False
        end
        object MemoHRDocs: TfrxMemoView
          AllowVectorExport = True
          Left = 570.000000000000000000
          Top = 26.000000000000000000
          Width = 108.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Facturas')
          ParentFont = False
        end
        object MemoHRPorcIva: TfrxMemoView
          AllowVectorExport = True
          Left = 680.000000000000000000
          Top = 26.000000000000000000
          Width = 46.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '% IVA')
          ParentFont = False
        end
        object MemoHRBase: TfrxMemoView
          AllowVectorExport = True
          Left = 728.000000000000000000
          Top = 26.000000000000000000
          Width = 80.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Base imponible')
          ParentFont = False
        end
        object MemoHRCuotaIva: TfrxMemoView
          AllowVectorExport = True
          Left = 810.000000000000000000
          Top = 26.000000000000000000
          Width = 72.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Cuota IVA')
          ParentFont = False
        end
        object MemoHRPorcRe: TfrxMemoView
          AllowVectorExport = True
          Left = 884.000000000000000000
          Top = 26.000000000000000000
          Width = 40.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '% RE')
          ParentFont = False
        end
        object MemoHRCuotaRe: TfrxMemoView
          AllowVectorExport = True
          Left = 926.000000000000000000
          Top = 26.000000000000000000
          Width = 56.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Cuota RE')
          ParentFont = False
        end
        object MemoHRTotal: TfrxMemoView
          AllowVectorExport = True
          Left = 984.000000000000000000
          Top = 26.000000000000000000
          Width = 62.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Total')
          ParentFont = False
        end
      end
      object GroupHeaderResumen: TfrxGroupHeader
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 18.000000000000000000
        Top = 204.000000000000000000
        Width = 1046.000000000000000000
        Condition = '<ResumenIva."EMPRESA"> + <ResumenIva."LIBRO">'
        object MemoResumenLibro: TfrxMemoView
          AllowVectorExport = True
          Top = 2.000000000000000000
          Width = 678.000000000000000000
          Height = 14.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[ResumenIva."EMPRESA"] - [IIF(<ResumenIva."LIBRO"> = ''REP'', ''IVA REPERCUTIDO (ventas)'', ''IVA SOPORTADO (compras)'')]')
          ParentFont = False
        end
      end
      object MasterData2: TfrxMasterData
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 16.000000000000000000
        Top = 226.000000000000000000
        Width = 1046.000000000000000000
        DataSet = fxdsResumenIva
        DataSetName = 'ResumenIva'
        RowCount = 0
        object MemoRDocs: TfrxMemoView
          AllowVectorExport = True
          Left = 570.000000000000000000
          Top = 1.000000000000000000
          Width = 108.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsResumenIva
          DataSetName = 'ResumenIva'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[ResumenIva."DOCUMENTOS"]')
          ParentFont = False
        end
        object MemoRPorcIva: TfrxMemoView
          AllowVectorExport = True
          Left = 680.000000000000000000
          Top = 1.000000000000000000
          Width = 46.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsResumenIva
          DataSetName = 'ResumenIva'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[ResumenIva."PORC_IVA"]')
          ParentFont = False
        end
        object MemoRBase: TfrxMemoView
          AllowVectorExport = True
          Left = 728.000000000000000000
          Top = 1.000000000000000000
          Width = 80.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsResumenIva
          DataSetName = 'ResumenIva'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[ResumenIva."BASE"]')
          ParentFont = False
        end
        object MemoRCuotaIva: TfrxMemoView
          AllowVectorExport = True
          Left = 810.000000000000000000
          Top = 1.000000000000000000
          Width = 72.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsResumenIva
          DataSetName = 'ResumenIva'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[ResumenIva."CUOTA_IVA"]')
          ParentFont = False
        end
        object MemoRPorcRe: TfrxMemoView
          AllowVectorExport = True
          Left = 884.000000000000000000
          Top = 1.000000000000000000
          Width = 40.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsResumenIva
          DataSetName = 'ResumenIva'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[ResumenIva."PORC_RE"]')
          ParentFont = False
        end
        object MemoRCuotaRe: TfrxMemoView
          AllowVectorExport = True
          Left = 926.000000000000000000
          Top = 1.000000000000000000
          Width = 56.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsResumenIva
          DataSetName = 'ResumenIva'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[ResumenIva."CUOTA_RE"]')
          ParentFont = False
        end
        object MemoRTotal: TfrxMemoView
          AllowVectorExport = True
          Left = 984.000000000000000000
          Top = 1.000000000000000000
          Width = 62.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsResumenIva
          DataSetName = 'ResumenIva'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[ResumenIva."TOTAL"]')
          ParentFont = False
        end
      end
      object GroupFooterResumen: TfrxGroupFooter
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 22.000000000000000000
        Top = 246.000000000000000000
        Width = 1046.000000000000000000
        object MemoTotResumen: TfrxMemoView
          AllowVectorExport = True
          Top = 2.000000000000000000
          Width = 678.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          Memo.UTF8W = (
            'TOTAL')
          ParentFont = False
        end
        object MemoTotRBase: TfrxMemoView
          AllowVectorExport = True
          Left = 728.000000000000000000
          Top = 2.000000000000000000
          Width = 80.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<ResumenIva."BASE">,MasterData2)]')
          ParentFont = False
        end
        object MemoTotRCuotaIva: TfrxMemoView
          AllowVectorExport = True
          Left = 810.000000000000000000
          Top = 2.000000000000000000
          Width = 72.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<ResumenIva."CUOTA_IVA">,MasterData2)]')
          ParentFont = False
        end
        object MemoTotRCuotaRe: TfrxMemoView
          AllowVectorExport = True
          Left = 926.000000000000000000
          Top = 2.000000000000000000
          Width = 56.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<ResumenIva."CUOTA_RE">,MasterData2)]')
          ParentFont = False
        end
        object MemoTotRTotal: TfrxMemoView
          AllowVectorExport = True
          Left = 984.000000000000000000
          Top = 2.000000000000000000
          Width = 62.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<ResumenIva."TOTAL">,MasterData2)]')
          ParentFont = False
        end
      end
      object HeaderLiquidacion: TfrxHeader
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 44.000000000000000000
        Top = 290.000000000000000000
        Width = 1046.000000000000000000
        object MemoTituloLiquidacion: TfrxMemoView
          AllowVectorExport = True
          Top = 6.000000000000000000
          Width = 1046.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            'Liquidaci'#243'n del periodo')
          ParentFont = False
        end
        object MemoHLEmpresa: TfrxMemoView
          AllowVectorExport = True
          Top = 26.000000000000000000
          Width = 400.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Empresa')
          ParentFont = False
        end
        object MemoHLIvaRep: TfrxMemoView
          AllowVectorExport = True
          Left = 410.000000000000000000
          Top = 26.000000000000000000
          Width = 90.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'IVA repercutido')
          ParentFont = False
        end
        object MemoHLReRep: TfrxMemoView
          AllowVectorExport = True
          Left = 505.000000000000000000
          Top = 26.000000000000000000
          Width = 80.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'RE repercutido')
          ParentFont = False
        end
        object MemoHLIvaSop: TfrxMemoView
          AllowVectorExport = True
          Left = 590.000000000000000000
          Top = 26.000000000000000000
          Width = 90.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'IVA soportado')
          ParentFont = False
        end
        object MemoHLReSop: TfrxMemoView
          AllowVectorExport = True
          Left = 685.000000000000000000
          Top = 26.000000000000000000
          Width = 80.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'RE soportado')
          ParentFont = False
        end
        object MemoHLIvaDed: TfrxMemoView
          AllowVectorExport = True
          Left = 770.000000000000000000
          Top = 26.000000000000000000
          Width = 90.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'IVA deducible')
          ParentFont = False
        end
        object MemoHLResultado: TfrxMemoView
          AllowVectorExport = True
          Left = 865.000000000000000000
          Top = 26.000000000000000000
          Width = 90.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Resultado')
          ParentFont = False
        end
        object MemoHLObservacion: TfrxMemoView
          AllowVectorExport = True
          Left = 960.000000000000000000
          Top = 26.000000000000000000
          Width = 86.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Observaciones')
          ParentFont = False
        end
      end
      object MasterData3: TfrxMasterData
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 16.000000000000000000
        Top = 338.000000000000000000
        Width = 1046.000000000000000000
        DataSet = fxdsLiquidacionIva
        DataSetName = 'LiquidacionIva'
        RowCount = 0
        object MemoLEmpresa: TfrxMemoView
          AllowVectorExport = True
          Top = 1.000000000000000000
          Width = 400.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsLiquidacionIva
          DataSetName = 'LiquidacionIva'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[LiquidacionIva."EMPRESA"] - [LiquidacionIva."RAZON_SOCIAL_EMPRESA"]')
          ParentFont = False
        end
        object MemoLIvaRep: TfrxMemoView
          AllowVectorExport = True
          Left = 410.000000000000000000
          Top = 1.000000000000000000
          Width = 90.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsLiquidacionIva
          DataSetName = 'LiquidacionIva'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[LiquidacionIva."IVA_REPERCUTIDO"]')
          ParentFont = False
        end
        object MemoLReRep: TfrxMemoView
          AllowVectorExport = True
          Left = 505.000000000000000000
          Top = 1.000000000000000000
          Width = 80.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsLiquidacionIva
          DataSetName = 'LiquidacionIva'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[LiquidacionIva."RE_REPERCUTIDO"]')
          ParentFont = False
        end
        object MemoLIvaSop: TfrxMemoView
          AllowVectorExport = True
          Left = 590.000000000000000000
          Top = 1.000000000000000000
          Width = 90.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsLiquidacionIva
          DataSetName = 'LiquidacionIva'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[LiquidacionIva."IVA_SOPORTADO"]')
          ParentFont = False
        end
        object MemoLReSop: TfrxMemoView
          AllowVectorExport = True
          Left = 685.000000000000000000
          Top = 1.000000000000000000
          Width = 80.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsLiquidacionIva
          DataSetName = 'LiquidacionIva'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[LiquidacionIva."RE_SOPORTADO"]')
          ParentFont = False
        end
        object MemoLIvaDed: TfrxMemoView
          AllowVectorExport = True
          Left = 770.000000000000000000
          Top = 1.000000000000000000
          Width = 90.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsLiquidacionIva
          DataSetName = 'LiquidacionIva'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[LiquidacionIva."IVA_DEDUCIBLE"]')
          ParentFont = False
        end
        object MemoLResultado: TfrxMemoView
          AllowVectorExport = True
          Left = 865.000000000000000000
          Top = 1.000000000000000000
          Width = 90.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsLiquidacionIva
          DataSetName = 'LiquidacionIva'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[LiquidacionIva."RESULTADO"]')
          ParentFont = False
        end
        object MemoLObservacion: TfrxMemoView
          AllowVectorExport = True
          Left = 960.000000000000000000
          Top = 1.000000000000000000
          Width = 86.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsLiquidacionIva
          DataSetName = 'LiquidacionIva'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -7
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[IIF(<LiquidacionIva."ESRECARGO"> = ''S'', ''Recargo eq.: sin liquidaci'#243'n'', IIF(<LiquidacionIva."RESULTADO"> >= 0, ''A ingresar'', ''A compensar''))]')
          ParentFont = False
        end
      end
      object PageFooter1: TfrxPageFooter
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 16.000000000000000000
        Top = 472.000000000000000000
        Width = 1046.000000000000000000
        object MemoPagina: TfrxMemoView
          AllowVectorExport = True
          Left = 900.000000000000000000
          Top = 1.000000000000000000
          Width = 146.000000000000000000
          Height = 14.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            'P'#225'gina [Page#] de [TotalPages#]')
          ParentFont = False
        end
      end
    end
  end
  object fxdsLibrosIva: TfrxDBDataset
    UserName = 'LibrosIva'
    CloseDataSource = False
    BCDToCurrency = False
    DataSetOptions = []
    Left = 96
    Top = 128
  end
  object fxdsResumenIva: TfrxDBDataset
    UserName = 'ResumenIva'
    CloseDataSource = False
    BCDToCurrency = False
    DataSetOptions = []
    Left = 136
    Top = 128
  end
  object fxdsLiquidacionIva: TfrxDBDataset
    UserName = 'LiquidacionIva'
    CloseDataSource = False
    BCDToCurrency = False
    DataSetOptions = []
    Left = 176
    Top = 128
  end
end
