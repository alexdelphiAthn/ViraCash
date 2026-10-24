inherited frmPrintBalanceTallas: TfrmPrintBalanceTallas
  Caption = 'Balance de almac'#233'n por tallas'
  ClientHeight = 470
  ClientWidth = 1040
  TextHeight = 19
  inherited frxrprt1: TfrxReport
    Datasets = <
      item
        DataSet = fxdsBalance
        DataSetName = 'Balance'
      end>
    Variables = <>
    Style = <>
    inherited Page1: TfrxReportPage
      Orientation = poLandscape
      PaperWidth = 297.000000000000000000
      PaperHeight = 210.000000000000000000
      LeftMargin = 10.000000000000000000
      RightMargin = 10.000000000000000000
      TopMargin = 10.000000000000000000
      BottomMargin = 10.000000000000000000
    end
  end
  inherited frxReportOrigen: TfrxReport
    Datasets = <
      item
        DataSet = fxdsBalance
        DataSetName = 'Balance'
      end>
    Variables = <>
    Style = <>
    inherited Page1: TfrxReportPage
      Orientation = poLandscape
      PaperWidth = 297.000000000000000000
      PaperHeight = 210.000000000000000000
      LeftMargin = 10.000000000000000000
      RightMargin = 10.000000000000000000
      TopMargin = 10.000000000000000000
      BottomMargin = 10.000000000000000000
      object ReportTitle1: TfrxReportTitle
        Height = 44.000000000000000000
        Top = 0.000000000000000000
        Width = 1047.000000000000000000
        Frame.Typ = []
        object MemoTitulo: TfrxMemoView
          Left = 0.000000000000000000
          Top = 2.000000000000000000
          Width = 700.000000000000000000
          Height = 24.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -18
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            'Balance de almac'#233'n por tallas')
          ParentFont = False
        end
        object MemoSubtitulo: TfrxMemoView
          Left = 700.000000000000000000
          Top = 8.000000000000000000
          Width = 347.000000000000000000
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
      object GroupHeaderG1: TfrxGroupHeader
        Height = 20.000000000000000000
        Top = 46.000000000000000000
        Width = 1047.000000000000000000
        Condition = 'Balance."GRUPO1_COD"'
        Frame.Typ = []
        object MemoGrupo1: TfrxMemoView
          Left = 0.000000000000000000
          Top = 2.000000000000000000
          Width = 1047.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            '[Balance."GRUPO1_ETIQ"]')
          ParentFont = False
        end
      end
      object GroupHeaderG2: TfrxGroupHeader
        Height = 20.000000000000000000
        Top = 68.000000000000000000
        Width = 1047.000000000000000000
        Condition = 'Balance."GRUPO2_COD"'
        Frame.Typ = []
        object MemoGrupo2: TfrxMemoView
          Left = 14.000000000000000000
          Top = 2.000000000000000000
          Width = 1033.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            '[Balance."GRUPO2_ETIQ"]')
          ParentFont = False
        end
      end
      object GroupHeaderG3: TfrxGroupHeader
        Height = 20.000000000000000000
        Top = 90.000000000000000000
        Width = 1047.000000000000000000
        Condition = 'Balance."GRUPO3_COD"'
        Frame.Typ = []
        object MemoGrupo3: TfrxMemoView
          Left = 28.000000000000000000
          Top = 2.000000000000000000
          Width = 1019.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            '[Balance."GRUPO3_ETIQ"]')
          ParentFont = False
        end
      end
      object GroupHeaderFam: TfrxGroupHeader
        Height = 22.000000000000000000
        Top = 112.000000000000000000
        Width = 1047.000000000000000000
        Condition = 'Balance."CODIGO_FAM"'
        Frame.Typ = []
        object MemoFamilia: TfrxMemoView
          Left = 0.000000000000000000
          Top = 3.000000000000000000
          Width = 800.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'FAMILIA   [Balance."CODIGO_FAM"]   [Balance."DESCRIPCION_FAM"]')
          ParentFont = False
        end
      end
      object GroupHeaderArt: TfrxGroupHeader
        Height = 74.000000000000000000
        Top = 136.000000000000000000
        Width = 1047.000000000000000000
        Condition = 'Balance."CODIGO_ART_ART"'
        Frame.Typ = []
        object MemoArtLabel: TfrxMemoView
          Left = 0.000000000000000000
          Top = 4.000000000000000000
          Width = 64.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            'ART'#205'CULO')
          ParentFont = False
        end
        object MemoArtCod: TfrxMemoView
          Left = 64.000000000000000000
          Top = 4.000000000000000000
          Width = 152.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[Balance."CODIGO_ART_ART"]')
          ParentFont = False
          WordWrap = False
        end
        object MemoArtDesc: TfrxMemoView
          Left = 218.000000000000000000
          Top = 4.000000000000000000
          Width = 458.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Balance."DESCRIPCION_ART"]')
          ParentFont = False
        end
        object MemoArtRef: TfrxMemoView
          Left = 680.000000000000000000
          Top = 4.000000000000000000
          Width = 160.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Balance."REF_PRV"]')
          ParentFont = False
        end
        object foto300: TfrxPictureView
          AllowVectorExport = True
          Left = 983.000000000000000000
          Top = 2.000000000000000000
          Width = 64.000000000000000000
          Height = 48.000000000000000000
          Frame.Typ = []
          HightQuality = False
          Transparent = False
          TransparentColor = clWhite
        end
        object MemoColHdr: TfrxMemoView
          Left = 80.000000000000000000
          Top = 52.000000000000000000
          Width = 80.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Color')
          ParentFont = False
        end
        object MemoTH01: TfrxMemoView
          Left = 160.000000000000000000
          Top = 52.000000000000000000
          Width = 48.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[Balance."ETIQ_T01"]')
          ParentFont = False
        end
        object MemoTH02: TfrxMemoView
          Left = 208.000000000000000000
          Top = 52.000000000000000000
          Width = 48.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[Balance."ETIQ_T02"]')
          ParentFont = False
        end
        object MemoTH03: TfrxMemoView
          Left = 256.000000000000000000
          Top = 52.000000000000000000
          Width = 48.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[Balance."ETIQ_T03"]')
          ParentFont = False
        end
        object MemoTH04: TfrxMemoView
          Left = 304.000000000000000000
          Top = 52.000000000000000000
          Width = 48.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[Balance."ETIQ_T04"]')
          ParentFont = False
        end
        object MemoTH05: TfrxMemoView
          Left = 352.000000000000000000
          Top = 52.000000000000000000
          Width = 48.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[Balance."ETIQ_T05"]')
          ParentFont = False
        end
        object MemoTH06: TfrxMemoView
          Left = 400.000000000000000000
          Top = 52.000000000000000000
          Width = 48.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[Balance."ETIQ_T06"]')
          ParentFont = False
        end
        object MemoTH07: TfrxMemoView
          Left = 448.000000000000000000
          Top = 52.000000000000000000
          Width = 48.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[Balance."ETIQ_T07"]')
          ParentFont = False
        end
        object MemoTH08: TfrxMemoView
          Left = 496.000000000000000000
          Top = 52.000000000000000000
          Width = 48.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[Balance."ETIQ_T08"]')
          ParentFont = False
        end
        object MemoTH09: TfrxMemoView
          Left = 544.000000000000000000
          Top = 52.000000000000000000
          Width = 48.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[Balance."ETIQ_T09"]')
          ParentFont = False
        end
        object MemoTH10: TfrxMemoView
          Left = 592.000000000000000000
          Top = 52.000000000000000000
          Width = 48.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[Balance."ETIQ_T10"]')
          ParentFont = False
        end
        object MemoTH11: TfrxMemoView
          Left = 640.000000000000000000
          Top = 52.000000000000000000
          Width = 48.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[Balance."ETIQ_T11"]')
          ParentFont = False
        end
        object MemoTH12: TfrxMemoView
          Left = 688.000000000000000000
          Top = 52.000000000000000000
          Width = 48.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[Balance."ETIQ_T12"]')
          ParentFont = False
        end
        object MemoTH13: TfrxMemoView
          Left = 736.000000000000000000
          Top = 52.000000000000000000
          Width = 48.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[Balance."ETIQ_T13"]')
          ParentFont = False
        end
        object MemoTH14: TfrxMemoView
          Left = 784.000000000000000000
          Top = 52.000000000000000000
          Width = 48.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[Balance."ETIQ_T14"]')
          ParentFont = False
        end
        object MemoCdadHdr: TfrxMemoView
          Left = 834.000000000000000000
          Top = 52.000000000000000000
          Width = 64.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Cdad.')
          ParentFont = False
        end
        object MemoPrecioHdr: TfrxMemoView
          Left = 900.000000000000000000
          Top = 52.000000000000000000
          Width = 70.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Precio')
          ParentFont = False
        end
        object MemoImpHdr: TfrxMemoView
          Left = 972.000000000000000000
          Top = 52.000000000000000000
          Width = 75.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Importe')
          ParentFont = False
        end
      end
      object MasterData1: TfrxMasterData
        FillType = ftBrush
        Height = 18.000000000000000000
        Top = 212.000000000000000000
        Width = 1047.000000000000000000
        DataSet = fxdsBalance
        DataSetName = 'Balance'
        RowCount = 0
        Frame.Typ = []
        object MemoBanda: TfrxMemoView
          Left = 0.000000000000000000
          Top = 1.000000000000000000
          Width = 80.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsItalic]
          Frame.Typ = []
          Memo.UTF8W = (
            '[Balance."ETIQUETA_BANDA"]')
          ParentFont = False
        end
        object MemoColor: TfrxMemoView
          Left = 80.000000000000000000
          Top = 1.000000000000000000
          Width = 80.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Balance."COLOR"]')
          ParentFont = False
          WordWrap = False
        end
        object MemoT01: TfrxMemoView
          Left = 160.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          DataSet = fxdsBalance
          DataSetName = 'Balance'
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haCenter
          HideZeros = True
          Memo.UTF8W = (
            '[Balance."T01"]')
          ParentFont = False
        end
        object MemoT02: TfrxMemoView
          Left = 208.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          DataSet = fxdsBalance
          DataSetName = 'Balance'
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haCenter
          HideZeros = True
          Memo.UTF8W = (
            '[Balance."T02"]')
          ParentFont = False
        end
        object MemoT03: TfrxMemoView
          Left = 256.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          DataSet = fxdsBalance
          DataSetName = 'Balance'
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haCenter
          HideZeros = True
          Memo.UTF8W = (
            '[Balance."T03"]')
          ParentFont = False
        end
        object MemoT04: TfrxMemoView
          Left = 304.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          DataSet = fxdsBalance
          DataSetName = 'Balance'
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haCenter
          HideZeros = True
          Memo.UTF8W = (
            '[Balance."T04"]')
          ParentFont = False
        end
        object MemoT05: TfrxMemoView
          Left = 352.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          DataSet = fxdsBalance
          DataSetName = 'Balance'
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haCenter
          HideZeros = True
          Memo.UTF8W = (
            '[Balance."T05"]')
          ParentFont = False
        end
        object MemoT06: TfrxMemoView
          Left = 400.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          DataSet = fxdsBalance
          DataSetName = 'Balance'
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haCenter
          HideZeros = True
          Memo.UTF8W = (
            '[Balance."T06"]')
          ParentFont = False
        end
        object MemoT07: TfrxMemoView
          Left = 448.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          DataSet = fxdsBalance
          DataSetName = 'Balance'
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haCenter
          HideZeros = True
          Memo.UTF8W = (
            '[Balance."T07"]')
          ParentFont = False
        end
        object MemoT08: TfrxMemoView
          Left = 496.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          DataSet = fxdsBalance
          DataSetName = 'Balance'
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haCenter
          HideZeros = True
          Memo.UTF8W = (
            '[Balance."T08"]')
          ParentFont = False
        end
        object MemoT09: TfrxMemoView
          Left = 544.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          DataSet = fxdsBalance
          DataSetName = 'Balance'
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haCenter
          HideZeros = True
          Memo.UTF8W = (
            '[Balance."T09"]')
          ParentFont = False
        end
        object MemoT10: TfrxMemoView
          Left = 592.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          DataSet = fxdsBalance
          DataSetName = 'Balance'
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haCenter
          HideZeros = True
          Memo.UTF8W = (
            '[Balance."T10"]')
          ParentFont = False
        end
        object MemoT11: TfrxMemoView
          Left = 640.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          DataSet = fxdsBalance
          DataSetName = 'Balance'
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haCenter
          HideZeros = True
          Memo.UTF8W = (
            '[Balance."T11"]')
          ParentFont = False
        end
        object MemoT12: TfrxMemoView
          Left = 688.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          DataSet = fxdsBalance
          DataSetName = 'Balance'
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haCenter
          HideZeros = True
          Memo.UTF8W = (
            '[Balance."T12"]')
          ParentFont = False
        end
        object MemoT13: TfrxMemoView
          Left = 736.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          DataSet = fxdsBalance
          DataSetName = 'Balance'
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haCenter
          HideZeros = True
          Memo.UTF8W = (
            '[Balance."T13"]')
          ParentFont = False
        end
        object MemoT14: TfrxMemoView
          Left = 784.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          DataSet = fxdsBalance
          DataSetName = 'Balance'
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haCenter
          HideZeros = True
          Memo.UTF8W = (
            '[Balance."T14"]')
          ParentFont = False
        end
        object MemoCdad: TfrxMemoView
          Left = 834.000000000000000000
          Top = 1.000000000000000000
          Width = 64.000000000000000000
          Height = 16.000000000000000000
          DataSet = fxdsBalance
          DataSetName = 'Balance'
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haRight
          HideZeros = True
          Memo.UTF8W = (
            '[Balance."CANTIDAD"]')
          ParentFont = False
        end
        object MemoPrecio: TfrxMemoView
          Left = 900.000000000000000000
          Top = 1.000000000000000000
          Width = 70.000000000000000000
          Height = 16.000000000000000000
          DataSet = fxdsBalance
          DataSetName = 'Balance'
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
          HideZeros = True
          Memo.UTF8W = (
            '[Balance."PRECIO"]')
          ParentFont = False
        end
        object MemoImporte: TfrxMemoView
          Left = 972.000000000000000000
          Top = 1.000000000000000000
          Width = 75.000000000000000000
          Height = 16.000000000000000000
          DataSet = fxdsBalance
          DataSetName = 'Balance'
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
          HideZeros = True
          Memo.UTF8W = (
            '[Balance."IMPORTE"]')
          ParentFont = False
        end
      end
      object GroupFooterArt: TfrxGroupFooter
        Height = 2.000000000000000000
        Top = 226.000000000000000000
        Width = 1047.000000000000000000
        Frame.Typ = []
      end
      object GroupFooterFam: TfrxGroupFooter
        Height = 2.000000000000000000
        Top = 230.000000000000000000
        Width = 1047.000000000000000000
        Frame.Typ = []
      end
      object GroupFooterG3: TfrxGroupFooter
        Height = 18.000000000000000000
        Top = 240.000000000000000000
        Width = 1047.000000000000000000
        Frame.Typ = []
        object MemoGF3Lbl: TfrxMemoView
          Left = 28.000000000000000000
          Top = 1.000000000000000000
          Width = 806.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          Memo.UTF8W = (
            'TOTAL [Balance."GRUPO3_ETIQ"]    Ventas: [SUM(<Balance."VENTAS">,' +
            'MasterData1)]')
          ParentFont = False
        end
        object MemoGF3Cdad: TfrxMemoView
          Left = 834.000000000000000000
          Top = 1.000000000000000000
          Width = 64.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          HideZeros = True
          Memo.UTF8W = (
            '[SUM(<Balance."EXIFIN_CANT">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF3Imp: TfrxMemoView
          Left = 972.000000000000000000
          Top = 1.000000000000000000
          Width = 75.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          HideZeros = True
          Memo.UTF8W = (
            '[SUM(<Balance."EXIFIN_IMP">,MasterData1)]')
          ParentFont = False
        end
      end
      object GroupFooterG2: TfrxGroupFooter
        Height = 18.000000000000000000
        Top = 262.000000000000000000
        Width = 1047.000000000000000000
        Frame.Typ = []
        object MemoGF2Lbl: TfrxMemoView
          Left = 14.000000000000000000
          Top = 1.000000000000000000
          Width = 820.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          Memo.UTF8W = (
            'TOTAL [Balance."GRUPO2_ETIQ"]    Ventas: [SUM(<Balance."VENTAS">,' +
            'MasterData1)]')
          ParentFont = False
        end
        object MemoGF2Cdad: TfrxMemoView
          Left = 834.000000000000000000
          Top = 1.000000000000000000
          Width = 64.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          HideZeros = True
          Memo.UTF8W = (
            '[SUM(<Balance."EXIFIN_CANT">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF2Imp: TfrxMemoView
          Left = 972.000000000000000000
          Top = 1.000000000000000000
          Width = 75.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          HideZeros = True
          Memo.UTF8W = (
            '[SUM(<Balance."EXIFIN_IMP">,MasterData1)]')
          ParentFont = False
        end
      end
      object GroupFooterG1: TfrxGroupFooter
        Height = 20.000000000000000000
        Top = 284.000000000000000000
        Width = 1047.000000000000000000
        Frame.Typ = []
        object MemoGF1Lbl: TfrxMemoView
          Left = 0.000000000000000000
          Top = 2.000000000000000000
          Width = 834.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          Memo.UTF8W = (
            'TOTAL [Balance."GRUPO1_ETIQ"]    Ventas: [SUM(<Balance."VENTAS">,' +
            'MasterData1)]')
          ParentFont = False
        end
        object MemoGF1Cdad: TfrxMemoView
          Left = 834.000000000000000000
          Top = 2.000000000000000000
          Width = 64.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          HideZeros = True
          Memo.UTF8W = (
            '[SUM(<Balance."EXIFIN_CANT">,MasterData1)]')
          ParentFont = False
        end
        object MemoGF1Imp: TfrxMemoView
          Left = 972.000000000000000000
          Top = 2.000000000000000000
          Width = 75.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          HideZeros = True
          Memo.UTF8W = (
            '[SUM(<Balance."EXIFIN_IMP">,MasterData1)]')
          ParentFont = False
        end
      end
      object ReportSummary1: TfrxReportSummary
        Height = 20.000000000000000000
        Top = 306.000000000000000000
        Width = 1047.000000000000000000
        Frame.Typ = []
        object MemoRSLbl: TfrxMemoView
          Left = 0.000000000000000000
          Top = 2.000000000000000000
          Width = 834.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          Memo.UTF8W = (
            'TOTAL GENERAL    Ventas: [SUM(<Balance."VENTAS">,MasterData1)]')
          ParentFont = False
        end
        object MemoRSCdad: TfrxMemoView
          Left = 834.000000000000000000
          Top = 2.000000000000000000
          Width = 64.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          HideZeros = True
          Memo.UTF8W = (
            '[SUM(<Balance."EXIFIN_CANT">,MasterData1)]')
          ParentFont = False
        end
        object MemoRSImp: TfrxMemoView
          Left = 972.000000000000000000
          Top = 2.000000000000000000
          Width = 75.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          HideZeros = True
          Memo.UTF8W = (
            '[SUM(<Balance."EXIFIN_IMP">,MasterData1)]')
          ParentFont = False
        end
      end
      object PageFooter1: TfrxPageFooter
        Height = 18.000000000000000000
        Top = 332.000000000000000000
        Width = 1047.000000000000000000
        Frame.Typ = []
        object MemoPag: TfrxMemoView
          Left = 0.000000000000000000
          Top = 2.000000000000000000
          Width = 400.000000000000000000
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
        object MemoImpreso: TfrxMemoView
          Left = 647.000000000000000000
          Top = 2.000000000000000000
          Width = 400.000000000000000000
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
  object fxdsBalance: TfrxDBDataset
    Description = 'Balance'
    UserName = 'Balance'
    CloseDataSource = False
    BCDToCurrency = False
    DataSetOptions = []
    Left = 96
    Top = 128
  end
end
