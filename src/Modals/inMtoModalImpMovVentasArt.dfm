inherited frmPrintMovVentasArt: TfrmPrintMovVentasArt
  Caption = 'Movimientos de ventas por art'#237'culos y fechas'
  StyleElements = [seFont, seClient, seBorder]
  ExplicitWidth = 1056
  ExplicitHeight = 509
  TextHeight = 17
  inherited pnl1: TPanel
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 896
    ExplicitHeight = 462
    inherited btnSalir: TcxButton
      Top = 444
      ExplicitTop = 436
    end
  end
  inherited frxrprt1: TfrxReport
    Datasets = <
      item
        DataSet = fxdsMovVentas
        DataSetName = 'MovVentas'
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
        DataSet = fxdsMovVentas
        DataSetName = 'MovVentas'
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
          Width = 600.000000000000000000
          Height = 22.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -16
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            'Movimientos de ventas por art'#237'culos y fechas')
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
        Top = 38.000000000000000000
        Width = 1046.000000000000000000
        object MemoHDesc: TfrxMemoView
          AllowVectorExport = True
          Left = 46.000000000000000000
          Top = 2.000000000000000000
          Width = 178.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Art'#237'culo')
          ParentFont = False
        end
        object MemoHUniEnt: TfrxMemoView
          AllowVectorExport = True
          Left = 224.000000000000000000
          Top = 2.000000000000000000
          Width = 50.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Uni.Ent.')
          ParentFont = False
        end
        object MemoHImpEnt: TfrxMemoView
          AllowVectorExport = True
          Left = 274.000000000000000000
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
            'Imp.Ent.')
          ParentFont = False
        end
        object MemoHUdsVta: TfrxMemoView
          AllowVectorExport = True
          Left = 338.000000000000000000
          Top = 2.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Uds Vta')
          ParentFont = False
        end
        object MemoHImpVta: TfrxMemoView
          AllowVectorExport = True
          Left = 482.000000000000000000
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
            'Imp Venta')
          ParentFont = False
        end
        object MemoHPSalida: TfrxMemoView
          AllowVectorExport = True
          Left = 386.000000000000000000
          Top = 2.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'P. Salida')
          ParentFont = False
        end
        object MemoHPvp: TfrxMemoView
          AllowVectorExport = True
          Left = 434.000000000000000000
          Top = 2.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'P. Final')
          ParentFont = False
        end
        object MemoHImpCos: TfrxMemoView
          AllowVectorExport = True
          Left = 546.000000000000000000
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
            'Imp Coste')
          ParentFont = False
        end
        object MemoHBenef: TfrxMemoView
          AllowVectorExport = True
          Left = 610.000000000000000000
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
            'Beneficio')
          ParentFont = False
        end
        object MemoHPctBnf: TfrxMemoView
          AllowVectorExport = True
          Left = 674.000000000000000000
          Top = 2.000000000000000000
          Width = 44.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '% Bnf')
          ParentFont = False
        end
        object MemoHVtaEnt: TfrxMemoView
          AllowVectorExport = True
          Left = 718.000000000000000000
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
            'Venta-Ent')
          ParentFont = False
        end
        object MemoHVentEnt: TfrxMemoView
          AllowVectorExport = True
          Left = 782.000000000000000000
          Top = 2.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'VentEnt%')
          ParentFont = False
        end
        object MemoHMarg1: TfrxMemoView
          AllowVectorExport = True
          Left = 834.000000000000000000
          Top = 2.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Margen 1')
          ParentFont = False
        end
        object MemoHMarg2: TfrxMemoView
          AllowVectorExport = True
          Left = 886.000000000000000000
          Top = 2.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Margen 2')
          ParentFont = False
        end
        object MemoHPctVdto: TfrxMemoView
          AllowVectorExport = True
          Left = 938.000000000000000000
          Top = 2.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '% Vdo')
          ParentFont = False
        end
        object MemoHPctVlast: TfrxMemoView
          AllowVectorExport = True
          Left = 990.000000000000000000
          Top = 2.000000000000000000
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
            '% Vtas')
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
        Top = 62.000000000000000000
        Width = 1046.000000000000000000
        Condition = 'MovVentas."GRUPO1_COD"'
        object MemoGrupo1: TfrxMemoView
          AllowVectorExport = True
          Top = 2.000000000000000000
          Width = 1046.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            '[MovVentas."GRUPO1_ETIQ"]')
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
        Height = 20.000000000000000000
        Top = 84.000000000000000000
        Width = 1046.000000000000000000
        Condition = 'MovVentas."GRUPO2_COD"'
        object MemoGrupo2: TfrxMemoView
          AllowVectorExport = True
          Left = 14.000000000000000000
          Top = 2.000000000000000000
          Width = 1032.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            '[MovVentas."GRUPO2_ETIQ"]')
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
        Height = 20.000000000000000000
        Top = 106.000000000000000000
        Width = 1046.000000000000000000
        Condition = 'MovVentas."GRUPO3_COD"'
        object MemoGrupo3: TfrxMemoView
          AllowVectorExport = True
          Left = 28.000000000000000000
          Top = 2.000000000000000000
          Width = 1018.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            '[MovVentas."GRUPO3_ETIQ"]')
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
        Height = 34.000000000000000000
        Top = 130.000000000000000000
        Width = 1046.000000000000000000
        DataSet = fxdsMovVentas
        DataSetName = 'MovVentas'
        RowCount = 0
        object foto300: TfrxPictureView
          AllowVectorExport = True
          Top = 1.000000000000000000
          Width = 44.000000000000000000
          Height = 32.000000000000000000
          Frame.Typ = []
          HightQuality = False
          Transparent = False
          TransparentColor = clWhite
        end
        object MemoArtDesc: TfrxMemoView
          AllowVectorExport = True
          Left = 46.000000000000000000
          Top = 1.000000000000000000
          Width = 178.000000000000000000
          Height = 32.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[MovVentas."CODIGO_ART_ART"]  [MovVentas."COLOR_ETIQUETA"]  ' +
            'Talla: [MovVentas."TALLA_ETIQUETA"]'
            '[MovVentas."DESCRIPCION_ART"]')
          ParentFont = False
        end
        object MemoUniEnt: TfrxMemoView
          AllowVectorExport = True
          Left = 224.000000000000000000
          Top = 1.000000000000000000
          Width = 50.000000000000000000
          Height = 32.000000000000000000
          DataSet = fxdsMovVentas
          DataSetName = 'MovVentas'
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[MovVentas."UNI_ENT_TOT"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object MemoImpEnt: TfrxMemoView
          AllowVectorExport = True
          Left = 274.000000000000000000
          Top = 1.000000000000000000
          Width = 64.000000000000000000
          Height = 32.000000000000000000
          DataSet = fxdsMovVentas
          DataSetName = 'MovVentas'
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
            '[MovVentas."IMP_ENT_TOT"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object MemoUdsVta: TfrxMemoView
          AllowVectorExport = True
          Left = 338.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 32.000000000000000000
          DataSet = fxdsMovVentas
          DataSetName = 'MovVentas'
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[MovVentas."UDS_VENTA"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object MemoImpVta: TfrxMemoView
          AllowVectorExport = True
          Left = 482.000000000000000000
          Top = 1.000000000000000000
          Width = 64.000000000000000000
          Height = 32.000000000000000000
          DataSet = fxdsMovVentas
          DataSetName = 'MovVentas'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[MovVentas."IMP_VENTA"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object MemoPSalida: TfrxMemoView
          AllowVectorExport = True
          Left = 386.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 32.000000000000000000
          DataSet = fxdsMovVentas
          DataSetName = 'MovVentas'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haRight
          HideZeros = True
          Memo.UTF8W = (
            '[MovVentas."PRECIO_SALIDA_ART"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object MemoPvp: TfrxMemoView
          AllowVectorExport = True
          Left = 434.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 32.000000000000000000
          DataSet = fxdsMovVentas
          DataSetName = 'MovVentas'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haRight
          HideZeros = True
          Memo.UTF8W = (
            '[MovVentas."PVP_ART"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object MemoImpCos: TfrxMemoView
          AllowVectorExport = True
          Left = 546.000000000000000000
          Top = 1.000000000000000000
          Width = 64.000000000000000000
          Height = 32.000000000000000000
          DataSet = fxdsMovVentas
          DataSetName = 'MovVentas'
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
            '[MovVentas."IMP_COSTE"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object MemoBenef: TfrxMemoView
          AllowVectorExport = True
          Left = 610.000000000000000000
          Top = 1.000000000000000000
          Width = 64.000000000000000000
          Height = 32.000000000000000000
          DataSet = fxdsMovVentas
          DataSetName = 'MovVentas'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[MovVentas."BENEFICIO"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object MemoPctBnf: TfrxMemoView
          AllowVectorExport = True
          Left = 674.000000000000000000
          Top = 1.000000000000000000
          Width = 44.000000000000000000
          Height = 32.000000000000000000
          DataSet = fxdsMovVentas
          DataSetName = 'MovVentas'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[MovVentas."PCT_BNFCO"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object MemoVtaEnt: TfrxMemoView
          AllowVectorExport = True
          Left = 718.000000000000000000
          Top = 1.000000000000000000
          Width = 64.000000000000000000
          Height = 32.000000000000000000
          DataSet = fxdsMovVentas
          DataSetName = 'MovVentas'
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
            '[MovVentas."VENTA_ENT"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object MemoVentEnt: TfrxMemoView
          AllowVectorExport = True
          Left = 782.000000000000000000
          Top = 1.000000000000000000
          Width = 52.000000000000000000
          Height = 32.000000000000000000
          DataSet = fxdsMovVentas
          DataSetName = 'MovVentas'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[MovVentas."VENT_ENT"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object MemoMarg1: TfrxMemoView
          AllowVectorExport = True
          Left = 834.000000000000000000
          Top = 1.000000000000000000
          Width = 52.000000000000000000
          Height = 32.000000000000000000
          DataSet = fxdsMovVentas
          DataSetName = 'MovVentas'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[MovVentas."MARGEN1"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object MemoMarg2: TfrxMemoView
          AllowVectorExport = True
          Left = 886.000000000000000000
          Top = 1.000000000000000000
          Width = 52.000000000000000000
          Height = 32.000000000000000000
          DataSet = fxdsMovVentas
          DataSetName = 'MovVentas'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[MovVentas."MARGEN2"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object MemoPctVdto: TfrxMemoView
          AllowVectorExport = True
          Left = 938.000000000000000000
          Top = 1.000000000000000000
          Width = 52.000000000000000000
          Height = 32.000000000000000000
          DataSet = fxdsMovVentas
          DataSetName = 'MovVentas'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[MovVentas."PCT_VDTO"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object MemoPctVlast: TfrxMemoView
          AllowVectorExport = True
          Left = 990.000000000000000000
          Top = 1.000000000000000000
          Width = 56.000000000000000000
          Height = 32.000000000000000000
          DataSet = fxdsMovVentas
          DataSetName = 'MovVentas'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[MovVentas."PCT_VLAST"]')
          ParentFont = False
          VAlign = vaCenter
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
        Top = 172.000000000000000000
        Width = 1046.000000000000000000
        object MemoGF3Lbl: TfrxMemoView
          AllowVectorExport = True
          Left = 28.000000000000000000
          Top = 1.000000000000000000
          Width = 196.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          Memo.UTF8W = (
            'TOTAL [MovVentas."GRUPO3_ETIQ"]')
          ParentFont = False
        end
        object MemoGF3UniEnt: TfrxMemoView
          AllowVectorExport = True
          Left = 224.000000000000000000
          Top = 1.000000000000000000
          Width = 50.000000000000000000
          Height = 16.000000000000000000
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
            '[SUM(<MovVentas."UNI_ENT_TOT">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF3ImpEnt: TfrxMemoView
          AllowVectorExport = True
          Left = 274.000000000000000000
          Top = 1.000000000000000000
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
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<MovVentas."IMP_ENT_TOT">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF3UdsVta: TfrxMemoView
          AllowVectorExport = True
          Left = 338.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
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
            '[SUM(<MovVentas."UDS_VENTA">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF3ImpVta: TfrxMemoView
          AllowVectorExport = True
          Left = 482.000000000000000000
          Top = 1.000000000000000000
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
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<MovVentas."IMP_VENTA">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF3ImpCos: TfrxMemoView
          AllowVectorExport = True
          Left = 546.000000000000000000
          Top = 1.000000000000000000
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
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<MovVentas."IMP_COSTE">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF3Benef: TfrxMemoView
          AllowVectorExport = True
          Left = 610.000000000000000000
          Top = 1.000000000000000000
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
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<MovVentas."BENEFICIO">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF3PctBnf: TfrxMemoView
          AllowVectorExport = True
          Left = 674.000000000000000000
          Top = 1.000000000000000000
          Width = 44.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            
              '[IIF(SUM(<MovVentas."IMP_VENTA">,MasterData1)<>0,SUM(<MovVentas.' +
              '"BENEFICIO">,MasterData1)/SUM(<MovVentas."IMP_VENTA">,MasterData' +
              '1)*100,0)]')
          ParentFont = False
        end
        object MemoGF3VtaEnt: TfrxMemoView
          AllowVectorExport = True
          Left = 718.000000000000000000
          Top = 1.000000000000000000
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
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<MovVentas."VENTA_ENT">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF3VentEnt: TfrxMemoView
          AllowVectorExport = True
          Left = 782.000000000000000000
          Top = 1.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            
              '[IIF(SUM(<MovVentas."IMP_ENT_TOT">,MasterData1)<>0,SUM(<MovVenta' +
              's."IMP_VENTA">,MasterData1)/SUM(<MovVentas."IMP_ENT_TOT">,Master' +
              'Data1)*100,0)]')
          ParentFont = False
        end
        object MemoGF3Marg1: TfrxMemoView
          AllowVectorExport = True
          Left = 834.000000000000000000
          Top = 1.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            
              '[IIF(SUM(<MovVentas."IMP_COSTE">,MasterData1)<>0,SUM(<MovVentas.' +
              '"BENEFICIO">,MasterData1)/SUM(<MovVentas."IMP_COSTE">,MasterData' +
              '1)*100,0)]')
          ParentFont = False
        end
        object MemoGF3Marg2: TfrxMemoView
          AllowVectorExport = True
          Left = 886.000000000000000000
          Top = 1.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            
              '[IIF(SUM(<MovVentas."IMP_ENT_TOT">,MasterData1)<>0,SUM(<MovVenta' +
              's."VENTA_ENT">,MasterData1)/SUM(<MovVentas."IMP_ENT_TOT">,Master' +
              'Data1)*100,0)]')
          ParentFont = False
        end
        object MemoGF3PctVdto: TfrxMemoView
          AllowVectorExport = True
          Left = 938.000000000000000000
          Top = 1.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            
              '[IIF(SUM(<MovVentas."UNI_ENT_TOT">,MasterData1)<>0,SUM(<MovVenta' +
              's."UDS_VENTA">,MasterData1)/SUM(<MovVentas."UNI_ENT_TOT">,Master' +
              'Data1)*100,0)]')
          ParentFont = False
        end
        object MemoGF3PctVlast: TfrxMemoView
          AllowVectorExport = True
          Left = 990.000000000000000000
          Top = 1.000000000000000000
          Width = 56.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            
              '[IIF(MAX(<MovVentas."UDS_VENTA_G2">,MasterData1)<>0,SUM(<MovVent' +
              'as."UDS_VENTA">,MasterData1)/MAX(<MovVentas."UDS_VENTA_G2">,Mast' +
              'erData1)*100,0)]')
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
        Top = 194.000000000000000000
        Width = 1046.000000000000000000
        object MemoGF2Lbl: TfrxMemoView
          AllowVectorExport = True
          Left = 14.000000000000000000
          Top = 1.000000000000000000
          Width = 210.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          Memo.UTF8W = (
            'TOTAL [MovVentas."GRUPO2_ETIQ"]')
          ParentFont = False
        end
        object MemoGF2ImpEnt: TfrxMemoView
          AllowVectorExport = True
          Left = 274.000000000000000000
          Top = 1.000000000000000000
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
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<MovVentas."IMP_ENT_TOT">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF2ImpVta: TfrxMemoView
          AllowVectorExport = True
          Left = 482.000000000000000000
          Top = 1.000000000000000000
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
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<MovVentas."IMP_VENTA">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF2Benef: TfrxMemoView
          AllowVectorExport = True
          Left = 610.000000000000000000
          Top = 1.000000000000000000
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
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<MovVentas."BENEFICIO">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF2VtaEnt: TfrxMemoView
          AllowVectorExport = True
          Left = 718.000000000000000000
          Top = 1.000000000000000000
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
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<MovVentas."VENTA_ENT">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF2Marg1: TfrxMemoView
          AllowVectorExport = True
          Left = 834.000000000000000000
          Top = 1.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            
              '[IIF(SUM(<MovVentas."IMP_COSTE">,MasterData1)<>0,SUM(<MovVentas.' +
              '"BENEFICIO">,MasterData1)/SUM(<MovVentas."IMP_COSTE">,MasterData' +
              '1)*100,0)]')
          ParentFont = False
        end
        object MemoGF2Marg2: TfrxMemoView
          AllowVectorExport = True
          Left = 886.000000000000000000
          Top = 1.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            
              '[IIF(SUM(<MovVentas."IMP_ENT_TOT">,MasterData1)<>0,SUM(<MovVenta' +
              's."VENTA_ENT">,MasterData1)/SUM(<MovVentas."IMP_ENT_TOT">,Master' +
              'Data1)*100,0)]')
          ParentFont = False
        end
        object MemoGF2UniEnt: TfrxMemoView
          AllowVectorExport = True
          Left = 224.000000000000000000
          Top = 1.000000000000000000
          Width = 50.000000000000000000
          Height = 16.000000000000000000
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
            '[SUM(<MovVentas."UNI_ENT_TOT">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF2UdsVta: TfrxMemoView
          AllowVectorExport = True
          Left = 338.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
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
            '[SUM(<MovVentas."UDS_VENTA">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF2ImpCos: TfrxMemoView
          AllowVectorExport = True
          Left = 546.000000000000000000
          Top = 1.000000000000000000
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
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<MovVentas."IMP_COSTE">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF2PctBnf: TfrxMemoView
          AllowVectorExport = True
          Left = 674.000000000000000000
          Top = 1.000000000000000000
          Width = 44.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            
              '[IIF(SUM(<MovVentas."IMP_VENTA">,MasterData1)<>0,SUM(<MovVentas.' +
              '"BENEFICIO">,MasterData1)/SUM(<MovVentas."IMP_VENTA">,MasterData' +
              '1)*100,0)]')
          ParentFont = False
        end
        object MemoGF2VentEnt: TfrxMemoView
          AllowVectorExport = True
          Left = 782.000000000000000000
          Top = 1.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            
              '[IIF(SUM(<MovVentas."IMP_ENT_TOT">,MasterData1)<>0,SUM(<MovVenta' +
              's."IMP_VENTA">,MasterData1)/SUM(<MovVentas."IMP_ENT_TOT">,Master' +
              'Data1)*100,0)]')
          ParentFont = False
        end
        object MemoGF2PctVdto: TfrxMemoView
          AllowVectorExport = True
          Left = 938.000000000000000000
          Top = 1.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            
              '[IIF(SUM(<MovVentas."UNI_ENT_TOT">,MasterData1)<>0,SUM(<MovVenta' +
              's."UDS_VENTA">,MasterData1)/SUM(<MovVentas."UNI_ENT_TOT">,Master' +
              'Data1)*100,0)]')
          ParentFont = False
        end
        object MemoGF2PctVlast: TfrxMemoView
          AllowVectorExport = True
          Left = 990.000000000000000000
          Top = 1.000000000000000000
          Width = 56.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            
              '[IIF(MAX(<MovVentas."UDS_VENTA_G1">,MasterData1)<>0,SUM(<MovVent' +
              'as."UDS_VENTA">,MasterData1)/MAX(<MovVentas."UDS_VENTA_G1">,Mast' +
              'erData1)*100,0)]')
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
        Top = 216.000000000000000000
        Width = 1046.000000000000000000
        object MemoGF1Lbl: TfrxMemoView
          AllowVectorExport = True
          Top = 2.000000000000000000
          Width = 224.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          Memo.UTF8W = (
            'TOTAL [MovVentas."GRUPO1_ETIQ"]')
          ParentFont = False
        end
        object MemoGF1ImpEnt: TfrxMemoView
          AllowVectorExport = True
          Left = 274.000000000000000000
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
            '[SUM(<MovVentas."IMP_ENT_TOT">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF1ImpVta: TfrxMemoView
          AllowVectorExport = True
          Left = 482.000000000000000000
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
            '[SUM(<MovVentas."IMP_VENTA">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF1Benef: TfrxMemoView
          AllowVectorExport = True
          Left = 610.000000000000000000
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
            '[SUM(<MovVentas."BENEFICIO">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF1VtaEnt: TfrxMemoView
          AllowVectorExport = True
          Left = 718.000000000000000000
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
            '[SUM(<MovVentas."VENTA_ENT">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF1Marg1: TfrxMemoView
          AllowVectorExport = True
          Left = 834.000000000000000000
          Top = 2.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            
              '[IIF(SUM(<MovVentas."IMP_COSTE">,MasterData1)<>0,SUM(<MovVentas.' +
              '"BENEFICIO">,MasterData1)/SUM(<MovVentas."IMP_COSTE">,MasterData' +
              '1)*100,0)]')
          ParentFont = False
        end
        object MemoGF1Marg2: TfrxMemoView
          AllowVectorExport = True
          Left = 886.000000000000000000
          Top = 2.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            
              '[IIF(SUM(<MovVentas."IMP_ENT_TOT">,MasterData1)<>0,SUM(<MovVenta' +
              's."VENTA_ENT">,MasterData1)/SUM(<MovVentas."IMP_ENT_TOT">,Master' +
              'Data1)*100,0)]')
          ParentFont = False
        end
        object MemoGF1UniEnt: TfrxMemoView
          AllowVectorExport = True
          Left = 224.000000000000000000
          Top = 2.000000000000000000
          Width = 50.000000000000000000
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
            '[SUM(<MovVentas."UNI_ENT_TOT">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF1UdsVta: TfrxMemoView
          AllowVectorExport = True
          Left = 338.000000000000000000
          Top = 2.000000000000000000
          Width = 48.000000000000000000
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
            '[SUM(<MovVentas."UDS_VENTA">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF1ImpCos: TfrxMemoView
          AllowVectorExport = True
          Left = 546.000000000000000000
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
            '[SUM(<MovVentas."IMP_COSTE">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF1PctBnf: TfrxMemoView
          AllowVectorExport = True
          Left = 674.000000000000000000
          Top = 2.000000000000000000
          Width = 44.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            
              '[IIF(SUM(<MovVentas."IMP_VENTA">,MasterData1)<>0,SUM(<MovVentas.' +
              '"BENEFICIO">,MasterData1)/SUM(<MovVentas."IMP_VENTA">,MasterData' +
              '1)*100,0)]')
          ParentFont = False
        end
        object MemoGF1VentEnt: TfrxMemoView
          AllowVectorExport = True
          Left = 782.000000000000000000
          Top = 2.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            
              '[IIF(SUM(<MovVentas."IMP_ENT_TOT">,MasterData1)<>0,SUM(<MovVenta' +
              's."IMP_VENTA">,MasterData1)/SUM(<MovVentas."IMP_ENT_TOT">,Master' +
              'Data1)*100,0)]')
          ParentFont = False
        end
        object MemoGF1PctVdto: TfrxMemoView
          AllowVectorExport = True
          Left = 938.000000000000000000
          Top = 2.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            
              '[IIF(SUM(<MovVentas."UNI_ENT_TOT">,MasterData1)<>0,SUM(<MovVenta' +
              's."UDS_VENTA">,MasterData1)/SUM(<MovVentas."UNI_ENT_TOT">,Master' +
              'Data1)*100,0)]')
          ParentFont = False
        end
        object MemoGF1PctVlast: TfrxMemoView
          AllowVectorExport = True
          Left = 990.000000000000000000
          Top = 2.000000000000000000
          Width = 56.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            
              '[IIF(MAX(<MovVentas."UDS_VENTA_GLOBAL">,MasterData1)<>0,SUM(<Mov' +
              'Ventas."UDS_VENTA">,MasterData1)/MAX(<MovVentas."UDS_VENTA_GLOBA' +
              'L">,MasterData1)*100,0)]')
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
        Top = 238.000000000000000000
        Width = 1046.000000000000000000
        object MemoRSLbl: TfrxMemoView
          AllowVectorExport = True
          Top = 2.000000000000000000
          Width = 224.000000000000000000
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
        object MemoRSUniEnt: TfrxMemoView
          AllowVectorExport = True
          Left = 224.000000000000000000
          Top = 2.000000000000000000
          Width = 50.000000000000000000
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
            '[SUM(<MovVentas."UNI_ENT_TOT">,MasterData1)]')
          ParentFont = False
        end
        object MemoRSImpEnt: TfrxMemoView
          AllowVectorExport = True
          Left = 274.000000000000000000
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
            '[SUM(<MovVentas."IMP_ENT_TOT">,MasterData1)]')
          ParentFont = False
        end
        object MemoRSUdsVta: TfrxMemoView
          AllowVectorExport = True
          Left = 338.000000000000000000
          Top = 2.000000000000000000
          Width = 48.000000000000000000
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
            '[SUM(<MovVentas."UDS_VENTA">,MasterData1)]')
          ParentFont = False
        end
        object MemoRSImpVta: TfrxMemoView
          AllowVectorExport = True
          Left = 482.000000000000000000
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
            '[SUM(<MovVentas."IMP_VENTA">,MasterData1)]')
          ParentFont = False
        end
        object MemoRSImpCos: TfrxMemoView
          AllowVectorExport = True
          Left = 546.000000000000000000
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
            '[SUM(<MovVentas."IMP_COSTE">,MasterData1)]')
          ParentFont = False
        end
        object MemoRSBenef: TfrxMemoView
          AllowVectorExport = True
          Left = 610.000000000000000000
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
            '[SUM(<MovVentas."BENEFICIO">,MasterData1)]')
          ParentFont = False
        end
        object MemoRSPctBnf: TfrxMemoView
          AllowVectorExport = True
          Left = 674.000000000000000000
          Top = 2.000000000000000000
          Width = 44.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            
              '[IIF(SUM(<MovVentas."IMP_VENTA">,MasterData1)<>0,SUM(<MovVentas.' +
              '"BENEFICIO">,MasterData1)/SUM(<MovVentas."IMP_VENTA">,MasterData' +
              '1)*100,0)]')
          ParentFont = False
        end
        object MemoRSVtaEnt: TfrxMemoView
          AllowVectorExport = True
          Left = 718.000000000000000000
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
            '[SUM(<MovVentas."VENTA_ENT">,MasterData1)]')
          ParentFont = False
        end
        object MemoRSVentEnt: TfrxMemoView
          AllowVectorExport = True
          Left = 782.000000000000000000
          Top = 2.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            
              '[IIF(SUM(<MovVentas."IMP_ENT_TOT">,MasterData1)<>0,SUM(<MovVenta' +
              's."IMP_VENTA">,MasterData1)/SUM(<MovVentas."IMP_ENT_TOT">,Master' +
              'Data1)*100,0)]')
          ParentFont = False
        end
        object MemoRSMarg1: TfrxMemoView
          AllowVectorExport = True
          Left = 834.000000000000000000
          Top = 2.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            
              '[IIF(SUM(<MovVentas."IMP_COSTE">,MasterData1)<>0,SUM(<MovVentas.' +
              '"BENEFICIO">,MasterData1)/SUM(<MovVentas."IMP_COSTE">,MasterData' +
              '1)*100,0)]')
          ParentFont = False
        end
        object MemoRSMarg2: TfrxMemoView
          AllowVectorExport = True
          Left = 886.000000000000000000
          Top = 2.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            
              '[IIF(SUM(<MovVentas."IMP_ENT_TOT">,MasterData1)<>0,SUM(<MovVenta' +
              's."VENTA_ENT">,MasterData1)/SUM(<MovVentas."IMP_ENT_TOT">,Master' +
              'Data1)*100,0)]')
          ParentFont = False
        end
        object MemoRSPctVdto: TfrxMemoView
          AllowVectorExport = True
          Left = 938.000000000000000000
          Top = 2.000000000000000000
          Width = 52.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            
              '[IIF(SUM(<MovVentas."UNI_ENT_TOT">,MasterData1)<>0,SUM(<MovVenta' +
              's."UDS_VENTA">,MasterData1)/SUM(<MovVentas."UNI_ENT_TOT">,Master' +
              'Data1)*100,0)]')
          ParentFont = False
        end
        object MemoRSPctVlast: TfrxMemoView
          AllowVectorExport = True
          Left = 990.000000000000000000
          Top = 2.000000000000000000
          Width = 56.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.1f'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[IIF(SUM(<MovVentas."UDS_VENTA">,MasterData1)<>0,100,0)]')
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
        Height = 18.000000000000000000
        Top = 260.000000000000000000
        Width = 1046.000000000000000000
        object MemoPag: TfrxMemoView
          AllowVectorExport = True
          Top = 2.000000000000000000
          Width = 520.000000000000000000
          Height = 14.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'P'#225'gina [Page#] de [TotalPages#]')
          ParentFont = False
        end
        object MemoPie: TfrxMemoView
          AllowVectorExport = True
          Left = 526.000000000000000000
          Top = 2.000000000000000000
          Width = 520.000000000000000000
          Height = 14.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            'Impreso el [Date]')
          ParentFont = False
        end
      end
    end
  end
  object fxdsMovVentas: TfrxDBDataset
    Description = 'MovVentas'
    UserName = 'MovVentas'
    CloseDataSource = False
    BCDToCurrency = False
    DataSetOptions = []
    Left = 96
    Top = 128
  end
end
