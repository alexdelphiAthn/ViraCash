inherited frmPrintEfectosPago: TfrmPrintEfectosPago
  Caption = 'Listado de efectos de pago'
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
        DataSet = fxdsEfectosPago
        DataSetName = 'EfectosPago'
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
        DataSet = fxdsEfectosPago
        DataSetName = 'EfectosPago'
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
        Height = 34.000000000000000000
        Width = 1046.000000000000000000
        object MemoTitulo: TfrxMemoView
          AllowVectorExport = True
          Top = 2.000000000000000000
          Width = 520.000000000000000000
          Height = 24.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -16
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            'Listado de efectos pago')
          ParentFont = False
        end
        object MemoFechaTitulo: TfrxMemoView
          AllowVectorExport = True
          Left = 620.000000000000000000
          Top = 3.000000000000000000
          Width = 220.000000000000000000
          Height = 22.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGray
          Font.Height = -15
          Font.Name = 'Arial'
          Font.Style = [fsBold, fsItalic]
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            'Fecha vencimiento')
          ParentFont = False
        end
        object MemoImpreso: TfrxMemoView
          AllowVectorExport = True
          Left = 860.000000000000000000
          Top = 8.000000000000000000
          Width = 186.000000000000000000
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
        Height = 22.000000000000000000
        Top = 38.000000000000000000
        Width = 1046.000000000000000000
        object MemoHNro: TfrxMemoView
          AllowVectorExport = True
          Top = 2.000000000000000000
          Width = 128.000000000000000000
          Height = 18.000000000000000000
          Color = 14540253
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Nro.Efecto.')
          ParentFont = False
        end
        object MemoHEfecto: TfrxMemoView
          AllowVectorExport = True
          Left = 130.000000000000000000
          Top = 2.000000000000000000
          Width = 120.000000000000000000
          Height = 18.000000000000000000
          Color = 14540253
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Efecto')
          ParentFont = False
        end
        object MemoHAlm: TfrxMemoView
          AllowVectorExport = True
          Left = 252.000000000000000000
          Top = 2.000000000000000000
          Width = 34.000000000000000000
          Height = 18.000000000000000000
          Color = 14540253
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
        object MemoHPvdor: TfrxMemoView
          AllowVectorExport = True
          Left = 288.000000000000000000
          Top = 2.000000000000000000
          Width = 44.000000000000000000
          Height = 18.000000000000000000
          Color = 14540253
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Pvdo.')
          ParentFont = False
        end
        object MemoHSituacion: TfrxMemoView
          AllowVectorExport = True
          Left = 334.000000000000000000
          Top = 2.000000000000000000
          Width = 76.000000000000000000
          Height = 18.000000000000000000
          Color = 14540253
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Situacion')
          ParentFont = False
        end
        object MemoHFecVto: TfrxMemoView
          AllowVectorExport = True
          Left = 412.000000000000000000
          Top = 2.000000000000000000
          Width = 66.000000000000000000
          Height = 18.000000000000000000
          Color = 14540253
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Fecha vto.')
          ParentFont = False
        end
        object MemoHDias: TfrxMemoView
          AllowVectorExport = True
          Left = 480.000000000000000000
          Top = 2.000000000000000000
          Width = 34.000000000000000000
          Height = 18.000000000000000000
          Color = 14540253
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Dias')
          ParentFont = False
        end
        object MemoHFecDoc: TfrxMemoView
          AllowVectorExport = True
          Left = 516.000000000000000000
          Top = 2.000000000000000000
          Width = 66.000000000000000000
          Height = 18.000000000000000000
          Color = 14540253
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Fecha doc.')
          ParentFont = False
        end
        object MemoHImporte: TfrxMemoView
          AllowVectorExport = True
          Left = 584.000000000000000000
          Top = 2.000000000000000000
          Width = 72.000000000000000000
          Height = 18.000000000000000000
          Color = 14540253
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Importe bruto')
          ParentFont = False
        end
        object MemoHPagado: TfrxMemoView
          AllowVectorExport = True
          Left = 658.000000000000000000
          Top = 2.000000000000000000
          Width = 72.000000000000000000
          Height = 18.000000000000000000
          Color = 14540253
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Pagado')
          ParentFont = False
        end
        object MemoHPendiente: TfrxMemoView
          AllowVectorExport = True
          Left = 732.000000000000000000
          Top = 2.000000000000000000
          Width = 76.000000000000000000
          Height = 18.000000000000000000
          Color = 14540253
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Pendiente')
          ParentFont = False
        end
        object MemoHPendienteCompensado: TfrxMemoView
          AllowVectorExport = True
          Left = 810.000000000000000000
          Top = 2.000000000000000000
          Width = 72.000000000000000000
          Height = 18.000000000000000000
          Color = 14540253
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Compensado')
          ParentFont = False
        end
        object MemoHRemesa: TfrxMemoView
          AllowVectorExport = True
          Left = 884.000000000000000000
          Top = 2.000000000000000000
          Width = 84.000000000000000000
          Height = 18.000000000000000000
          Color = 14540253
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Remesa')
          ParentFont = False
        end
        object MemoHBanco: TfrxMemoView
          AllowVectorExport = True
          Left = 970.000000000000000000
          Top = 2.000000000000000000
          Width = 76.000000000000000000
          Height = 18.000000000000000000
          Color = 14540253
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Banco')
          ParentFont = False
        end
      end
      object GroupHeaderG1: TfrxGroupHeader
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 20.000000000000000000
        Top = 64.000000000000000000
        Width = 1046.000000000000000000
        Condition = 'EfectosPago."GRUPO1_COD"'
        object MemoGrupo1: TfrxMemoView
          AllowVectorExport = True
          Top = 2.000000000000000000
          Width = 1046.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold, fsItalic]
          Frame.Typ = []
          Memo.UTF8W = (
            '[EfectosPago."GRUPO1_ETIQ"]')
          ParentFont = False
        end
      end
      object GroupHeaderG2: TfrxGroupHeader
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 18.000000000000000000
        Top = 88.000000000000000000
        Width = 1046.000000000000000000
        Condition = 'EfectosPago."GRUPO2_COD"'
        object MemoGrupo2: TfrxMemoView
          AllowVectorExport = True
          Top = 2.000000000000000000
          Width = 1046.000000000000000000
          Height = 14.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold, fsItalic]
          Frame.Typ = []
          Memo.UTF8W = (
            '[EfectosPago."GRUPO2_ETIQ"]')
          ParentFont = False
        end
      end
      object GroupHeaderG3: TfrxGroupHeader
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 18.000000000000000000
        Top = 110.000000000000000000
        Width = 1046.000000000000000000
        Condition = 'EfectosPago."GRUPO3_COD"'
        object MemoGrupo3: TfrxMemoView
          AllowVectorExport = True
          Top = 2.000000000000000000
          Width = 1046.000000000000000000
          Height = 14.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold, fsItalic]
          Frame.Typ = []
          Memo.UTF8W = (
            '[EfectosPago."GRUPO3_ETIQ"]')
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
        Top = 132.000000000000000000
        Width = 1046.000000000000000000
        DataSet = fxdsEfectosPago
        DataSetName = 'EfectosPago'
        RowCount = 0
        object MemoNro: TfrxMemoView
          AllowVectorExport = True
          Top = 1.000000000000000000
          Width = 128.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsEfectosPago
          DataSetName = 'EfectosPago'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[EfectosPago."IDENTIFICADOR_EFECTO"]')
          ParentFont = False
        end
        object MemoEfecto: TfrxMemoView
          AllowVectorExport = True
          Left = 130.000000000000000000
          Top = 1.000000000000000000
          Width = 120.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsEfectosPago
          DataSetName = 'EfectosPago'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[EfectosPago."TIPO_EFECTO_EFEC"]')
          ParentFont = False
        end
        object MemoAlm: TfrxMemoView
          AllowVectorExport = True
          Left = 252.000000000000000000
          Top = 1.000000000000000000
          Width = 34.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsEfectosPago
          DataSetName = 'EfectosPago'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[EfectosPago."CODIGO_ALM_EFEC"]')
          ParentFont = False
        end
        object MemoPvdor: TfrxMemoView
          AllowVectorExport = True
          Left = 288.000000000000000000
          Top = 1.000000000000000000
          Width = 44.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsEfectosPago
          DataSetName = 'EfectosPago'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[EfectosPago."CODIGO_PRV_EFEC"]')
          ParentFont = False
        end
        object MemoSituacion: TfrxMemoView
          AllowVectorExport = True
          Left = 334.000000000000000000
          Top = 1.000000000000000000
          Width = 76.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsEfectosPago
          DataSetName = 'EfectosPago'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[EfectosPago."SITUACION_EFEC"]')
          ParentFont = False
        end
        object MemoFecVto: TfrxMemoView
          AllowVectorExport = True
          Left = 412.000000000000000000
          Top = 1.000000000000000000
          Width = 66.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsEfectosPago
          DataSetName = 'EfectosPago'
          DisplayFormat.FormatStr = 'dd/mm/yyyy'
          DisplayFormat.Kind = fkDateTime
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[EfectosPago."FECHA_VENCIMIENTO_EFEC"]')
          ParentFont = False
        end
        object MemoDias: TfrxMemoView
          AllowVectorExport = True
          Left = 480.000000000000000000
          Top = 1.000000000000000000
          Width = 34.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsEfectosPago
          DataSetName = 'EfectosPago'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[EfectosPago."DIAS_EFEC"]')
          ParentFont = False
        end
        object MemoFecDoc: TfrxMemoView
          AllowVectorExport = True
          Left = 516.000000000000000000
          Top = 1.000000000000000000
          Width = 66.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsEfectosPago
          DataSetName = 'EfectosPago'
          DisplayFormat.FormatStr = 'dd/mm/yyyy'
          DisplayFormat.Kind = fkDateTime
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[EfectosPago."FECHA_DOCUMENTO_EFEC"]')
          ParentFont = False
        end
        object MemoImporte: TfrxMemoView
          AllowVectorExport = True
          Left = 584.000000000000000000
          Top = 1.000000000000000000
          Width = 72.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsEfectosPago
          DataSetName = 'EfectosPago'
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
            '[EfectosPago."IMPORTE_EFEC"]')
          ParentFont = False
        end
        object MemoPagado: TfrxMemoView
          AllowVectorExport = True
          Left = 658.000000000000000000
          Top = 1.000000000000000000
          Width = 72.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsEfectosPago
          DataSetName = 'EfectosPago'
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
            '[EfectosPago."IMPORTE_PAGADO_EFEC"]')
          ParentFont = False
        end
        object MemoPendiente: TfrxMemoView
          AllowVectorExport = True
          Left = 732.000000000000000000
          Top = 1.000000000000000000
          Width = 76.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsEfectosPago
          DataSetName = 'EfectosPago'
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
            '[EfectosPago."IMPORTE_PENDIENTE_EFEC"]')
          ParentFont = False
        end
        object MemoPendienteCompensado: TfrxMemoView
          AllowVectorExport = True
          Left = 810.000000000000000000
          Top = 1.000000000000000000
          Width = 72.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsEfectosPago
          DataSetName = 'EfectosPago'
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
            '[EfectosPago."IMPORTE_COMPENSADO_EFEC"]')
          ParentFont = False
        end
        object MemoRemesa: TfrxMemoView
          AllowVectorExport = True
          Left = 884.000000000000000000
          Top = 1.000000000000000000
          Width = 84.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsEfectosPago
          DataSetName = 'EfectosPago'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[EfectosPago."REMESA_EFEC"]')
          ParentFont = False
        end
        object MemoBanco: TfrxMemoView
          AllowVectorExport = True
          Left = 970.000000000000000000
          Top = 1.000000000000000000
          Width = 76.000000000000000000
          Height = 14.000000000000000000
          DataSet = fxdsEfectosPago
          DataSetName = 'EfectosPago'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[EfectosPago."BANCO_REMESA_EFEC"]')
          ParentFont = False
        end
      end
      object GroupFooterG3: TfrxGroupFooter
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 18.000000000000000000
        Top = 152.000000000000000000
        Width = 1046.000000000000000000
        object MemoTotG3: TfrxMemoView
          AllowVectorExport = True
          Top = 2.000000000000000000
          Width = 584.000000000000000000
          Height = 14.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold, fsItalic]
          Frame.Typ = [ftTop]
          Memo.UTF8W = (
            'TOT. [EfectosPago."GRUPO3_ETIQ"]')
          ParentFont = False
        end
        object MemoTotG3Imp: TfrxMemoView
          AllowVectorExport = True
          Left = 584.000000000000000000
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
            '[SUM(<EfectosPago."IMPORTE_BRUTO_EFEC">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotG3Pag: TfrxMemoView
          AllowVectorExport = True
          Left = 658.000000000000000000
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
            '[SUM(<EfectosPago."IMPORTE_PAGADO_EFEC">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotG3Pen: TfrxMemoView
          AllowVectorExport = True
          Left = 732.000000000000000000
          Top = 2.000000000000000000
          Width = 76.000000000000000000
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
            '[SUM(<EfectosPago."IMPORTE_PENDIENTE_BRUTO_EFEC">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotG3PenCompensado: TfrxMemoView
          AllowVectorExport = True
          Left = 810.000000000000000000
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
            '[SUM(<EfectosPago."IMPORTE_COMPENSADO_EFEC">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotG3Resto: TfrxMemoView
          AllowVectorExport = True
          Left = 884.000000000000000000
          Top = 2.000000000000000000
          Width = 162.000000000000000000
          Height = 14.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          ParentFont = False
        end
      end
      object GroupFooterG2: TfrxGroupFooter
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 18.000000000000000000
        Top = 174.000000000000000000
        Width = 1046.000000000000000000
        object MemoTotG2: TfrxMemoView
          AllowVectorExport = True
          Top = 2.000000000000000000
          Width = 584.000000000000000000
          Height = 14.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold, fsItalic]
          Frame.Typ = [ftTop]
          Memo.UTF8W = (
            'TOT. [EfectosPago."GRUPO2_ETIQ"]')
          ParentFont = False
        end
        object MemoTotG2Imp: TfrxMemoView
          AllowVectorExport = True
          Left = 584.000000000000000000
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
            '[SUM(<EfectosPago."IMPORTE_BRUTO_EFEC">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotG2Pag: TfrxMemoView
          AllowVectorExport = True
          Left = 658.000000000000000000
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
            '[SUM(<EfectosPago."IMPORTE_PAGADO_EFEC">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotG2Pen: TfrxMemoView
          AllowVectorExport = True
          Left = 732.000000000000000000
          Top = 2.000000000000000000
          Width = 76.000000000000000000
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
            '[SUM(<EfectosPago."IMPORTE_PENDIENTE_BRUTO_EFEC">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotG2PenCompensado: TfrxMemoView
          AllowVectorExport = True
          Left = 810.000000000000000000
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
            '[SUM(<EfectosPago."IMPORTE_COMPENSADO_EFEC">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotG2Resto: TfrxMemoView
          AllowVectorExport = True
          Left = 884.000000000000000000
          Top = 2.000000000000000000
          Width = 162.000000000000000000
          Height = 14.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          ParentFont = False
        end
      end
      object GroupFooterG1: TfrxGroupFooter
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 20.000000000000000000
        Top = 196.000000000000000000
        Width = 1046.000000000000000000
        object MemoTotG1: TfrxMemoView
          AllowVectorExport = True
          Top = 2.000000000000000000
          Width = 584.000000000000000000
          Height = 16.000000000000000000
          Color = 14540253
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold, fsItalic]
          Frame.Typ = [ftTop, ftBottom]
          Memo.UTF8W = (
            'TOT. [EfectosPago."GRUPO1_ETIQ"]')
          ParentFont = False
        end
        object MemoTotG1Imp: TfrxMemoView
          AllowVectorExport = True
          Left = 584.000000000000000000
          Top = 2.000000000000000000
          Width = 72.000000000000000000
          Height = 16.000000000000000000
          Color = 14540253
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<EfectosPago."IMPORTE_BRUTO_EFEC">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotG1Pag: TfrxMemoView
          AllowVectorExport = True
          Left = 658.000000000000000000
          Top = 2.000000000000000000
          Width = 72.000000000000000000
          Height = 16.000000000000000000
          Color = 14540253
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<EfectosPago."IMPORTE_PAGADO_EFEC">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotG1Pen: TfrxMemoView
          AllowVectorExport = True
          Left = 732.000000000000000000
          Top = 2.000000000000000000
          Width = 76.000000000000000000
          Height = 16.000000000000000000
          Color = 14540253
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<EfectosPago."IMPORTE_PENDIENTE_BRUTO_EFEC">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotG1PenCompensado: TfrxMemoView
          AllowVectorExport = True
          Left = 810.000000000000000000
          Top = 2.000000000000000000
          Width = 72.000000000000000000
          Height = 16.000000000000000000
          Color = 14540253
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<EfectosPago."IMPORTE_COMPENSADO_EFEC">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotG1Resto: TfrxMemoView
          AllowVectorExport = True
          Left = 884.000000000000000000
          Top = 2.000000000000000000
          Width = 162.000000000000000000
          Height = 16.000000000000000000
          Color = 14540253
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
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
        Height = 22.000000000000000000
        Top = 220.000000000000000000
        Width = 1046.000000000000000000
        object MemoTotalGeneral: TfrxMemoView
          AllowVectorExport = True
          Top = 3.000000000000000000
          Width = 584.000000000000000000
          Height = 16.000000000000000000
          Color = 14540253
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold, fsItalic]
          Frame.Typ = [ftTop, ftBottom]
          Memo.UTF8W = (
            'TOTAL GENERAL (abonos aparte)')
          ParentFont = False
        end
        object MemoTotalGeneralImp: TfrxMemoView
          AllowVectorExport = True
          Left = 584.000000000000000000
          Top = 3.000000000000000000
          Width = 72.000000000000000000
          Height = 16.000000000000000000
          Color = 14540253
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<EfectosPago."IMPORTE_BRUTO_EFEC">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotalGeneralPag: TfrxMemoView
          AllowVectorExport = True
          Left = 658.000000000000000000
          Top = 3.000000000000000000
          Width = 72.000000000000000000
          Height = 16.000000000000000000
          Color = 14540253
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<EfectosPago."IMPORTE_PAGADO_EFEC">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotalGeneralPen: TfrxMemoView
          AllowVectorExport = True
          Left = 732.000000000000000000
          Top = 3.000000000000000000
          Width = 76.000000000000000000
          Height = 16.000000000000000000
          Color = 14540253
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<EfectosPago."IMPORTE_PENDIENTE_BRUTO_EFEC">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotalGeneralPenCompensado: TfrxMemoView
          AllowVectorExport = True
          Left = 810.000000000000000000
          Top = 3.000000000000000000
          Width = 72.000000000000000000
          Height = 16.000000000000000000
          Color = 14540253
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<EfectosPago."IMPORTE_COMPENSADO_EFEC">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotalGeneralResto: TfrxMemoView
          AllowVectorExport = True
          Left = 884.000000000000000000
          Top = 3.000000000000000000
          Width = 162.000000000000000000
          Height = 16.000000000000000000
          Color = 14540253
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
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
        Top = 246.000000000000000000
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
  object fxdsEfectosPago: TfrxDBDataset
    UserName = 'EfectosPago'
    CloseDataSource = False
    BCDToCurrency = False
    DataSetOptions = []
    Left = 96
    Top = 128
  end
end
