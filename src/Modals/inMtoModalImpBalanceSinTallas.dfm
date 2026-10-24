inherited frmPrintBalanceSinTallas: TfrmPrintBalanceSinTallas
  Caption = 'Balance de almac'#233'n sin tallas'
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
      Orientation = poPortrait
      PaperWidth = 210.000000000000000000
      PaperHeight = 297.000000000000000000
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
      Orientation = poPortrait
      PaperWidth = 210.000000000000000000
      PaperHeight = 297.000000000000000000
      LeftMargin = 10.000000000000000000
      RightMargin = 10.000000000000000000
      TopMargin = 10.000000000000000000
      BottomMargin = 10.000000000000000000
      object ReportTitle1: TfrxReportTitle
        Height = 40.000000000000000000
        Top = 0.000000000000000000
        Width = 718.000000000000000000
        Frame.Typ = []
        object MemoTitulo: TfrxMemoView
          Left = 0.000000000000000000
          Top = 2.000000000000000000
          Width = 460.000000000000000000
          Height = 24.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -16
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            'Balance de almac'#233'n sin tallas')
          ParentFont = False
        end
        object MemoSubtitulo: TfrxMemoView
          Left = 460.000000000000000000
          Top = 8.000000000000000000
          Width = 258.000000000000000000
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
        Top = 44.000000000000000000
        Width = 718.000000000000000000
        Condition = 'Balance."GRUPO1_COD"'
        Frame.Typ = []
        object MemoGrupo1: TfrxMemoView
          Left = 0.000000000000000000
          Top = 2.000000000000000000
          Width = 718.000000000000000000
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
        Top = 66.000000000000000000
        Width = 718.000000000000000000
        Condition = 'Balance."GRUPO2_COD"'
        Frame.Typ = []
        object MemoGrupo2: TfrxMemoView
          Left = 14.000000000000000000
          Top = 2.000000000000000000
          Width = 704.000000000000000000
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
        Top = 88.000000000000000000
        Width = 718.000000000000000000
        Condition = 'Balance."GRUPO3_COD"'
        Frame.Typ = []
        object MemoGrupo3: TfrxMemoView
          Left = 28.000000000000000000
          Top = 2.000000000000000000
          Width = 690.000000000000000000
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
        Width = 718.000000000000000000
        Condition = 'Balance."CODIGO_FAM"'
        Frame.Typ = []
        object MemoFamilia: TfrxMemoView
          Left = 0.000000000000000000
          Top = 3.000000000000000000
          Width = 640.000000000000000000
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
        Height = 46.000000000000000000
        Top = 136.000000000000000000
        Width = 718.000000000000000000
        Condition = 'Balance."CODIGO_ART_ART"'
        Frame.Typ = []
        object MemoArtLabel: TfrxMemoView
          Left = 0.000000000000000000
          Top = 4.000000000000000000
          Width = 66.000000000000000000
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
          Left = 66.000000000000000000
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
          Left = 220.000000000000000000
          Top = 4.000000000000000000
          Width = 268.000000000000000000
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
          Left = 490.000000000000000000
          Top = 4.000000000000000000
          Width = 150.000000000000000000
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
          Left = 650.000000000000000000
          Top = 2.000000000000000000
          Width = 64.000000000000000000
          Height = 42.000000000000000000
          Frame.Typ = []
          HightQuality = False
          Transparent = False
          TransparentColor = clWhite
        end
        object MemoConHdr: TfrxMemoView
          Left = 0.000000000000000000
          Top = 26.000000000000000000
          Width = 110.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Concepto')
          ParentFont = False
        end
        object MemoColHdr: TfrxMemoView
          Left = 110.000000000000000000
          Top = 26.000000000000000000
          Width = 120.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Color')
          ParentFont = False
        end
        object MemoCdadHdr: TfrxMemoView
          Left = 380.000000000000000000
          Top = 26.000000000000000000
          Width = 80.000000000000000000
          Height = 18.000000000000000000
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
        object MemoPrecioHdr: TfrxMemoView
          Left = 462.000000000000000000
          Top = 26.000000000000000000
          Width = 80.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Precio')
          ParentFont = False
        end
        object MemoImpHdr: TfrxMemoView
          Left = 544.000000000000000000
          Top = 26.000000000000000000
          Width = 90.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
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
        Top = 232.000000000000000000
        Width = 718.000000000000000000
        DataSet = fxdsBalance
        DataSetName = 'Balance'
        RowCount = 0
        Frame.Typ = []
        object MemoBanda: TfrxMemoView
          Left = 0.000000000000000000
          Top = 1.000000000000000000
          Width = 110.000000000000000000
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
          Left = 110.000000000000000000
          Top = 1.000000000000000000
          Width = 120.000000000000000000
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
        object MemoCdad: TfrxMemoView
          Left = 380.000000000000000000
          Top = 1.000000000000000000
          Width = 80.000000000000000000
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
          Left = 462.000000000000000000
          Top = 1.000000000000000000
          Width = 80.000000000000000000
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
          Left = 544.000000000000000000
          Top = 1.000000000000000000
          Width = 90.000000000000000000
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
        Top = 254.000000000000000000
        Width = 718.000000000000000000
        Frame.Typ = []
      end
      object GroupFooterFam: TfrxGroupFooter
        Height = 2.000000000000000000
        Top = 258.000000000000000000
        Width = 718.000000000000000000
        Frame.Typ = []
      end
      object GroupFooterG3: TfrxGroupFooter
        Height = 18.000000000000000000
        Top = 268.000000000000000000
        Width = 718.000000000000000000
        Frame.Typ = []
        object MemoGF3Lbl: TfrxMemoView
          Left = 28.000000000000000000
          Top = 1.000000000000000000
          Width = 352.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          Memo.UTF8W = (
            'TOTAL [Balance."GRUPO3_ETIQ"]   Ventas: [SUM(<Balance."VENTAS">,M' +
            'asterData1)]')
          ParentFont = False
        end
        object MemoGF3Cdad: TfrxMemoView
          Left = 380.000000000000000000
          Top = 1.000000000000000000
          Width = 80.000000000000000000
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
          Left = 544.000000000000000000
          Top = 1.000000000000000000
          Width = 90.000000000000000000
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
        Top = 290.000000000000000000
        Width = 718.000000000000000000
        Frame.Typ = []
        object MemoGF2Lbl: TfrxMemoView
          Left = 14.000000000000000000
          Top = 1.000000000000000000
          Width = 366.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          Memo.UTF8W = (
            'TOTAL [Balance."GRUPO2_ETIQ"]   Ventas: [SUM(<Balance."VENTAS">,M' +
            'asterData1)]')
          ParentFont = False
        end
        object MemoGF2Cdad: TfrxMemoView
          Left = 380.000000000000000000
          Top = 1.000000000000000000
          Width = 80.000000000000000000
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
          Left = 544.000000000000000000
          Top = 1.000000000000000000
          Width = 90.000000000000000000
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
        Top = 312.000000000000000000
        Width = 718.000000000000000000
        Frame.Typ = []
        object MemoGF1Lbl: TfrxMemoView
          Left = 0.000000000000000000
          Top = 2.000000000000000000
          Width = 380.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          Memo.UTF8W = (
            'TOTAL [Balance."GRUPO1_ETIQ"]   Ventas: [SUM(<Balance."VENTAS">,M' +
            'asterData1)]')
          ParentFont = False
        end
        object MemoGF1Cdad: TfrxMemoView
          Left = 380.000000000000000000
          Top = 2.000000000000000000
          Width = 80.000000000000000000
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
          Left = 544.000000000000000000
          Top = 2.000000000000000000
          Width = 90.000000000000000000
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
        Top = 334.000000000000000000
        Width = 718.000000000000000000
        Frame.Typ = []
        object MemoRSLbl: TfrxMemoView
          Left = 0.000000000000000000
          Top = 2.000000000000000000
          Width = 380.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          Memo.UTF8W = (
            'TOTAL GENERAL   Ventas: [SUM(<Balance."VENTAS">,MasterData1)]')
          ParentFont = False
        end
        object MemoRSCdad: TfrxMemoView
          Left = 380.000000000000000000
          Top = 2.000000000000000000
          Width = 80.000000000000000000
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
          Left = 544.000000000000000000
          Top = 2.000000000000000000
          Width = 90.000000000000000000
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
        Top = 358.000000000000000000
        Width = 718.000000000000000000
        Frame.Typ = []
        object MemoPag: TfrxMemoView
          Left = 0.000000000000000000
          Top = 2.000000000000000000
          Width = 360.000000000000000000
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
          Left = 318.000000000000000000
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
