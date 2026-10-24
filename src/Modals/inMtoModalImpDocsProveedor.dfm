inherited frmPrintDocsProveedor: TfrmPrintDocsProveedor
  Caption = 'Listado de documentos proveedor'
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
  end
  inherited frxrprt1: TfrxReport
    Datasets = <
      item
        DataSet = fxdsDocsProveedor
        DataSetName = 'DocsProveedor'
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
        DataSet = fxdsDocsProveedor
        DataSetName = 'DocsProveedor'
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
            'Listado de documentos proveedor')
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
      object PageHeader1: TfrxPageHeader
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 20.000000000000000000
        Top = 36.000000000000000000
        Width = 1046.000000000000000000
        object MemoHTipo: TfrxMemoView
          AllowVectorExport = True
          Top = 2.000000000000000000
          Width = 36.000000000000000000
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
        object MemoHDoc: TfrxMemoView
          AllowVectorExport = True
          Left = 38.000000000000000000
          Top = 2.000000000000000000
          Width = 96.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Documento')
          ParentFont = False
        end
        object MemoHFecha: TfrxMemoView
          AllowVectorExport = True
          Left = 136.000000000000000000
          Top = 2.000000000000000000
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
        object MemoHProv: TfrxMemoView
          AllowVectorExport = True
          Left = 198.000000000000000000
          Top = 2.000000000000000000
          Width = 150.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Proveedor')
          ParentFont = False
        end
        object MemoHRef: TfrxMemoView
          AllowVectorExport = True
          Left = 350.000000000000000000
          Top = 2.000000000000000000
          Width = 100.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Ref. prov.')
          ParentFont = False
        end
        object MemoHAlm: TfrxMemoView
          AllowVectorExport = True
          Left = 452.000000000000000000
          Top = 2.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Alm.')
          ParentFont = False
        end
        object MemoHTmp: TfrxMemoView
          AllowVectorExport = True
          Left = 502.000000000000000000
          Top = 2.000000000000000000
          Width = 86.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Temporada')
          ParentFont = False
        end
        object MemoHCtd: TfrxMemoView
          AllowVectorExport = True
          Left = 590.000000000000000000
          Top = 2.000000000000000000
          Width = 58.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Lin.')
          ParentFont = False
        end
        object MemoHUds: TfrxMemoView
          AllowVectorExport = True
          Left = 650.000000000000000000
          Top = 2.000000000000000000
          Width = 88.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Cantidad')
          ParentFont = False
          WordWrap = False
        end
        object MemoHBase: TfrxMemoView
          AllowVectorExport = True
          Left = 740.000000000000000000
          Top = 2.000000000000000000
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
            'Base')
          ParentFont = False
        end
        object MemoHIva: TfrxMemoView
          AllowVectorExport = True
          Left = 814.000000000000000000
          Top = 2.000000000000000000
          Width = 64.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'IVA')
          ParentFont = False
        end
        object MemoHRe: TfrxMemoView
          AllowVectorExport = True
          Left = 880.000000000000000000
          Top = 2.000000000000000000
          Width = 64.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'RE')
          ParentFont = False
        end
        object MemoHTotal: TfrxMemoView
          AllowVectorExport = True
          Left = 946.000000000000000000
          Top = 2.000000000000000000
          Width = 82.000000000000000000
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
      object GroupHeaderTipo: TfrxGroupHeader
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 20.000000000000000000
        Top = 60.000000000000000000
        Width = 1046.000000000000000000
        Condition = 'DocsProveedor."TIPO_DOC"'
        object MemoTipoGrupo: TfrxMemoView
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
            '[DocsProveedor."TIPO_DOC_NOMBRE"]')
          ParentFont = False
        end
      end
      object GroupHeaderProveedor: TfrxGroupHeader
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 18.000000000000000000
        Top = 84.000000000000000000
        Width = 1046.000000000000000000
        Condition = 'DocsProveedor."CODIGO_PRV"'
        object MemoProvGrupo: TfrxMemoView
          AllowVectorExport = True
          Top = 2.000000000000000000
          Width = 600.000000000000000000
          Height = 14.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            'PVDOR. [DocsProveedor."CODIGO_PRV"] [DocsProveedor."RAZON_SOCIAL_PRV"]')
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
        DataSet = fxdsDocsProveedor
        DataSetName = 'DocsProveedor'
        RowCount = 0
        object MemoTipo: TfrxMemoView
          AllowVectorExport = True
          Top = 1.000000000000000000
          Width = 36.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsDocsProveedor
          DataSetName = 'DocsProveedor'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[DocsProveedor."TIPO_DOC"]')
          ParentFont = False
        end
        object MemoDoc: TfrxMemoView
          AllowVectorExport = True
          Left = 38.000000000000000000
          Top = 1.000000000000000000
          Width = 96.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsDocsProveedor
          DataSetName = 'DocsProveedor'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[DocsProveedor."DOCUMENTO_DOC"]')
          ParentFont = False
        end
        object MemoFecha: TfrxMemoView
          AllowVectorExport = True
          Left = 136.000000000000000000
          Top = 1.000000000000000000
          Width = 60.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsDocsProveedor
          DataSetName = 'DocsProveedor'
          DisplayFormat.FormatStr = 'dd/mm/yyyy'
          DisplayFormat.Kind = fkDateTime
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[DocsProveedor."FECHA_DOC"]')
          ParentFont = False
        end
        object MemoProv: TfrxMemoView
          AllowVectorExport = True
          Left = 198.000000000000000000
          Top = 1.000000000000000000
          Width = 150.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsDocsProveedor
          DataSetName = 'DocsProveedor'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[DocsProveedor."RAZON_SOCIAL_PRV"]')
          ParentFont = False
        end
        object MemoRef: TfrxMemoView
          AllowVectorExport = True
          Left = 350.000000000000000000
          Top = 1.000000000000000000
          Width = 100.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsDocsProveedor
          DataSetName = 'DocsProveedor'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[DocsProveedor."REF_PROVEEDOR_DOC"]')
          ParentFont = False
        end
        object MemoAlm: TfrxMemoView
          AllowVectorExport = True
          Left = 452.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsDocsProveedor
          DataSetName = 'DocsProveedor'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[DocsProveedor."CODIGO_ALM_DOC"]')
          ParentFont = False
        end
        object MemoTmp: TfrxMemoView
          AllowVectorExport = True
          Left = 502.000000000000000000
          Top = 1.000000000000000000
          Width = 86.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsDocsProveedor
          DataSetName = 'DocsProveedor'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[DocsProveedor."TEMPORADA_DOC"]')
          ParentFont = False
        end
        object MemoCtd: TfrxMemoView
          AllowVectorExport = True
          Left = 590.000000000000000000
          Top = 1.000000000000000000
          Width = 58.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsDocsProveedor
          DataSetName = 'DocsProveedor'
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[DocsProveedor."CANTIDAD_DOC"]')
          ParentFont = False
        end
        object MemoUds: TfrxMemoView
          AllowVectorExport = True
          Left = 650.000000000000000000
          Top = 1.000000000000000000
          Width = 88.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsDocsProveedor
          DataSetName = 'DocsProveedor'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[IIF(<DocsProveedor."UNIDAD_MEDIDA_DOC"> = '''', '''', IIF(<DocsProveedor."UNIDAD_MEDIDA_DOC"> = ''Varias'', ''Varias'', FormatFloat(<DocsProveedor."MASCARA_UNIDADES_DOC">, <DocsProveedor."UNIDADES_DOC">) + '' '' + <DocsProveedor."UNIDAD_MEDIDA_DOC">))]')
          ParentFont = False
          WordWrap = False
        end
        object MemoBase: TfrxMemoView
          AllowVectorExport = True
          Left = 740.000000000000000000
          Top = 1.000000000000000000
          Width = 72.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsDocsProveedor
          DataSetName = 'DocsProveedor'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[DocsProveedor."TOTAL_BASES_DOC"]')
          ParentFont = False
        end
        object MemoIva: TfrxMemoView
          AllowVectorExport = True
          Left = 814.000000000000000000
          Top = 1.000000000000000000
          Width = 64.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsDocsProveedor
          DataSetName = 'DocsProveedor'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[DocsProveedor."TOTAL_IVA_DOC"]')
          ParentFont = False
        end
        object MemoRe: TfrxMemoView
          AllowVectorExport = True
          Left = 880.000000000000000000
          Top = 1.000000000000000000
          Width = 64.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsDocsProveedor
          DataSetName = 'DocsProveedor'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[DocsProveedor."TOTAL_RE_DOC"]')
          ParentFont = False
        end
        object MemoTotal: TfrxMemoView
          AllowVectorExport = True
          Left = 946.000000000000000000
          Top = 1.000000000000000000
          Width = 82.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsDocsProveedor
          DataSetName = 'DocsProveedor'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[DocsProveedor."TOTAL_LIQUIDO_DOC"]')
          ParentFont = False
        end
      end
      object GroupFooterProveedor: TfrxGroupFooter
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 18.000000000000000000
        Top = 126.000000000000000000
        Width = 1046.000000000000000000
        object MemoTotProv: TfrxMemoView
          AllowVectorExport = True
          Top = 2.000000000000000000
          Width = 588.000000000000000000
          Height = 14.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          Memo.UTF8W = (
            'TOT.PVDOR.')
          ParentFont = False
        end
        object MemoTotProvCtd: TfrxMemoView
          AllowVectorExport = True
          Left = 590.000000000000000000
          Top = 2.000000000000000000
          Width = 58.000000000000000000
          Height = 14.000000000000000000
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<DocsProveedor."CANTIDAD_DOC">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotProvUds: TfrxMemoView
          AllowVectorExport = True
          Left = 650.000000000000000000
          Top = 2.000000000000000000
          Width = 88.000000000000000000
          Height = 14.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[IIF(<DocsProveedor."UNIDAD_TOT_PRV_DOC"> = '''', '''', IIF(<DocsProveedor."UNIDAD_TOT_PRV_DOC"> = ''Varias'', ''Varias'', FormatFloat(<DocsProveedor."MASCARA_TOT_PRV_DOC">, SUM(<DocsProveedor."UNIDADES_DOC">,MasterData1)) + '' '' + <DocsProveedor."UNIDAD_TOT_PRV_DOC">))]')
          ParentFont = False
          WordWrap = False
        end
        object MemoTotProvBase: TfrxMemoView
          AllowVectorExport = True
          Left = 740.000000000000000000
          Top = 2.000000000000000000
          Width = 72.000000000000000000
          Height = 14.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<DocsProveedor."TOTAL_BASES_DOC">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotProvIva: TfrxMemoView
          AllowVectorExport = True
          Left = 814.000000000000000000
          Top = 2.000000000000000000
          Width = 64.000000000000000000
          Height = 14.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<DocsProveedor."TOTAL_IVA_DOC">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotProvRe: TfrxMemoView
          AllowVectorExport = True
          Left = 880.000000000000000000
          Top = 2.000000000000000000
          Width = 64.000000000000000000
          Height = 14.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<DocsProveedor."TOTAL_RE_DOC">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotProvTotal: TfrxMemoView
          AllowVectorExport = True
          Left = 946.000000000000000000
          Top = 2.000000000000000000
          Width = 82.000000000000000000
          Height = 14.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<DocsProveedor."TOTAL_LIQUIDO_DOC">,MasterData1)]')
          ParentFont = False
        end
      end
      object GroupFooterTipo: TfrxGroupFooter
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 20.000000000000000000
        Top = 150.000000000000000000
        Width = 1046.000000000000000000
        object MemoTotTipo: TfrxMemoView
          AllowVectorExport = True
          Top = 2.000000000000000000
          Width = 588.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          Memo.UTF8W = (
            'TOTAL [DocsProveedor."TIPO_DOC_NOMBRE"]')
          ParentFont = False
        end
        object MemoTotTipoCtd: TfrxMemoView
          AllowVectorExport = True
          Left = 590.000000000000000000
          Top = 2.000000000000000000
          Width = 58.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<DocsProveedor."CANTIDAD_DOC">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotTipoUds: TfrxMemoView
          AllowVectorExport = True
          Left = 650.000000000000000000
          Top = 2.000000000000000000
          Width = 88.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[IIF(<DocsProveedor."UNIDAD_TOT_TIPO_DOC"> = '''', '''', IIF(<DocsProveedor."UNIDAD_TOT_TIPO_DOC"> = ''Varias'', ''Varias'', FormatFloat(<DocsProveedor."MASCARA_TOT_TIPO_DOC">, SUM(<DocsProveedor."UNIDADES_DOC">,MasterData1)) + '' '' + <DocsProveedor."UNIDAD_TOT_TIPO_DOC">))]')
          ParentFont = False
          WordWrap = False
        end
        object MemoTotTipoBase: TfrxMemoView
          AllowVectorExport = True
          Left = 740.000000000000000000
          Top = 2.000000000000000000
          Width = 72.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<DocsProveedor."TOTAL_BASES_DOC">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotTipoIva: TfrxMemoView
          AllowVectorExport = True
          Left = 814.000000000000000000
          Top = 2.000000000000000000
          Width = 64.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<DocsProveedor."TOTAL_IVA_DOC">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotTipoRe: TfrxMemoView
          AllowVectorExport = True
          Left = 880.000000000000000000
          Top = 2.000000000000000000
          Width = 64.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<DocsProveedor."TOTAL_RE_DOC">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotTipoTotal: TfrxMemoView
          AllowVectorExport = True
          Left = 946.000000000000000000
          Top = 2.000000000000000000
          Width = 82.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<DocsProveedor."TOTAL_LIQUIDO_DOC">,MasterData1)]')
          ParentFont = False
        end
      end
      object ReportSummary1: TfrxReportSummary
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 20.000000000000000000
        Top = 174.000000000000000000
        Width = 1046.000000000000000000
        object MemoTotalGeneral: TfrxMemoView
          AllowVectorExport = True
          Top = 2.000000000000000000
          Width = 588.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          Memo.UTF8W = (
            'TOTAL GENERAL')
          ParentFont = False
        end
        object MemoTotGenCtd: TfrxMemoView
          AllowVectorExport = True
          Left = 590.000000000000000000
          Top = 2.000000000000000000
          Width = 58.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<DocsProveedor."CANTIDAD_DOC">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotGenUds: TfrxMemoView
          AllowVectorExport = True
          Left = 650.000000000000000000
          Top = 2.000000000000000000
          Width = 88.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[IIF(<DocsProveedor."UNIDAD_TOT_GEN_DOC"> = '''', '''', IIF(<DocsProveedor."UNIDAD_TOT_GEN_DOC"> = ''Varias'', ''Varias'', FormatFloat(<DocsProveedor."MASCARA_TOT_GEN_DOC">, SUM(<DocsProveedor."UNIDADES_DOC">,MasterData1)) + '' '' + <DocsProveedor."UNIDAD_TOT_GEN_DOC">))]')
          ParentFont = False
          WordWrap = False
        end
        object MemoTotGenBase: TfrxMemoView
          AllowVectorExport = True
          Left = 740.000000000000000000
          Top = 2.000000000000000000
          Width = 72.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<DocsProveedor."TOTAL_BASES_DOC">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotGenIva: TfrxMemoView
          AllowVectorExport = True
          Left = 814.000000000000000000
          Top = 2.000000000000000000
          Width = 64.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<DocsProveedor."TOTAL_IVA_DOC">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotGenRe: TfrxMemoView
          AllowVectorExport = True
          Left = 880.000000000000000000
          Top = 2.000000000000000000
          Width = 64.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<DocsProveedor."TOTAL_RE_DOC">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotGenTotal: TfrxMemoView
          AllowVectorExport = True
          Left = 946.000000000000000000
          Top = 2.000000000000000000
          Width = 82.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<DocsProveedor."TOTAL_LIQUIDO_DOC">,MasterData1)]')
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
        Top = 198.000000000000000000
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
            'Pagina [Page#] de [TotalPages#]')
          ParentFont = False
        end
      end
    end
  end
  object fxdsDocsProveedor: TfrxDBDataset
    UserName = 'DocsProveedor'
    CloseDataSource = False
    BCDToCurrency = False
    DataSetOptions = []
    Left = 96
    Top = 128
  end
end
