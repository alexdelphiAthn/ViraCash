inherited frmPrintCaducidades: TfrmPrintCaducidades
  Caption = 'Imprimir lotes y caducidades'
  ClientHeight = 200
  TextHeight = 19
  inherited frxrprt1: TfrxReport
    Datasets = <
      item
        DataSet = fxdsCaducidades
        DataSetName = 'Caducidades'
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
        DataSet = fxdsCaducidades
        DataSetName = 'Caducidades'
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
        Height = 34.000000000000000000
        Top = 0.000000000000000000
        Width = 1047.000000000000000000
        Frame.Typ = []
        object MemoTitulo: TfrxMemoView
          Left = 0.000000000000000000
          Top = 4.000000000000000000
          Width = 1047.000000000000000000
          Height = 26.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -18
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haCenter
          Memo.UTF8W = (
            'LOTES Y CADUCIDADES')
          ParentFont = False
        end
      end
      object PageHeader1: TfrxPageHeader
        Height = 22.000000000000000000
        Top = 38.000000000000000000
        Width = 1047.000000000000000000
        Frame.Typ = []
        object MemoHFamilia: TfrxMemoView
          Left = 0.000000000000000000
          Top = 2.000000000000000000
          Width = 150.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Familia')
          ParentFont = False
        end
        object MemoHArticulo: TfrxMemoView
          Left = 150.000000000000000000
          Top = 2.000000000000000000
          Width = 90.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Art'#237'culo')
          ParentFont = False
        end
        object MemoHDescripcion: TfrxMemoView
          Left = 240.000000000000000000
          Top = 2.000000000000000000
          Width = 230.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Descripci'#243'n')
          ParentFont = False
        end
        object MemoHSku: TfrxMemoView
          Left = 470.000000000000000000
          Top = 2.000000000000000000
          Width = 130.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'SKU')
          ParentFont = False
        end
        object MemoHLote: TfrxMemoView
          Left = 600.000000000000000000
          Top = 2.000000000000000000
          Width = 140.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Lote / serie')
          ParentFont = False
        end
        object MemoHCaducidad: TfrxMemoView
          Left = 740.000000000000000000
          Top = 2.000000000000000000
          Width = 80.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Caducidad')
          ParentFont = False
        end
        object MemoHDias: TfrxMemoView
          Left = 820.000000000000000000
          Top = 2.000000000000000000
          Width = 45.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'D'#237'as')
          ParentFont = False
        end
        object MemoHCantidad: TfrxMemoView
          Left = 865.000000000000000000
          Top = 2.000000000000000000
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
            'Cantidad')
          ParentFont = False
        end
        object MemoHValor: TfrxMemoView
          Left = 940.000000000000000000
          Top = 2.000000000000000000
          Width = 85.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Valor')
          ParentFont = False
        end
      end
      object GroupHeader1: TfrxGroupHeader
        FillType = ftBrush
        Height = 24.000000000000000000
        Top = 64.000000000000000000
        Width = 1047.000000000000000000
        Condition = 'Caducidades."CODIGO_ALM_STK"'
        Frame.Typ = []
        object MemoAlmacen: TfrxMemoView
          Left = 0.000000000000000000
          Top = 4.000000000000000000
          Width = 1047.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsCaducidades
          DataSetName = 'Caducidades'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[Caducidades."CODIGO_ALM_STK"] - [Caducidades."NOMBRE_ALM_ALM"]')
          ParentFont = False
        end
      end
      object MasterData1: TfrxMasterData
        FillType = ftBrush
        Height = 20.000000000000000000
        Top = 92.000000000000000000
        Width = 1047.000000000000000000
        DataSet = fxdsCaducidades
        DataSetName = 'Caducidades'
        RowCount = 0
        Frame.Typ = []
        object MemoFamilia: TfrxMemoView
          Left = 0.000000000000000000
          Top = 1.000000000000000000
          Width = 150.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsCaducidades
          DataSetName = 'Caducidades'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          WordWrap = False
          Memo.UTF8W = (
            '[Caducidades."DESCRIPCION_FAM"]')
          ParentFont = False
        end
        object MemoArticulo: TfrxMemoView
          Left = 150.000000000000000000
          Top = 1.000000000000000000
          Width = 90.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsCaducidades
          DataSetName = 'Caducidades'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          WordWrap = False
          Memo.UTF8W = (
            '[Caducidades."CODIGO_ART_SKU"]')
          ParentFont = False
        end
        object MemoDescripcion: TfrxMemoView
          Left = 240.000000000000000000
          Top = 1.000000000000000000
          Width = 230.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsCaducidades
          DataSetName = 'Caducidades'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          WordWrap = False
          Memo.UTF8W = (
            '[Caducidades."DESCRIPCION_ART"]')
          ParentFont = False
        end
        object MemoSku: TfrxMemoView
          Left = 470.000000000000000000
          Top = 1.000000000000000000
          Width = 130.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsCaducidades
          DataSetName = 'Caducidades'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          WordWrap = False
          Memo.UTF8W = (
            '[Caducidades."CODIGO_UNIDAD_STK"]')
          ParentFont = False
        end
        object MemoLote: TfrxMemoView
          Left = 600.000000000000000000
          Top = 1.000000000000000000
          Width = 140.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsCaducidades
          DataSetName = 'Caducidades'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          WordWrap = False
          Memo.UTF8W = (
            '[Caducidades."LOTE_STK"]')
          ParentFont = False
        end
        object MemoCaducidad: TfrxMemoView
          Left = 740.000000000000000000
          Top = 1.000000000000000000
          Width = 80.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsCaducidades
          DataSetName = 'Caducidades'
          DisplayFormat.FormatStr = 'dd/mm/yyyy'
          DisplayFormat.Kind = fkDateTime
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          WordWrap = False
          Memo.UTF8W = (
            '[Caducidades."FECHA_CADUCIDAD"]')
          ParentFont = False
        end
        object MemoDias: TfrxMemoView
          Left = 820.000000000000000000
          Top = 1.000000000000000000
          Width = 45.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsCaducidades
          DataSetName = 'Caducidades'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          WordWrap = False
          Memo.UTF8W = (
            '[Caducidades."DIAS_PARA_CADUCAR"]')
          ParentFont = False
        end
        object MemoCantidad: TfrxMemoView
          Left = 865.000000000000000000
          Top = 1.000000000000000000
          Width = 75.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsCaducidades
          DataSetName = 'Caducidades'
          DisplayFormat.FormatStr = '%2.3n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          WordWrap = False
          Memo.UTF8W = (
            '[Caducidades."CANTIDAD_STK"]')
          ParentFont = False
        end
        object MemoValor: TfrxMemoView
          Left = 940.000000000000000000
          Top = 1.000000000000000000
          Width = 85.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsCaducidades
          DataSetName = 'Caducidades'
          DisplayFormat.FormatStr = '%2.2n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          WordWrap = False
          Memo.UTF8W = (
            '[Caducidades."VALOR_TOTAL_STK"]')
          ParentFont = False
        end
      end
      object PageFooter1: TfrxPageFooter
        Height = 18.000000000000000000
        Top = 120.000000000000000000
        Width = 1047.000000000000000000
        Frame.Typ = []
        object MemoPie: TfrxMemoView
          Left = 0.000000000000000000
          Top = 2.000000000000000000
          Width = 1047.000000000000000000
          Height = 14.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
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
  object dsCaducidadesPrint: TDataSource
    Left = 96
    Top = 72
  end
  object fxdsCaducidades: TfrxDBDataset
    Description = 'Caducidades'
    UserName = 'Caducidades'
    CloseDataSource = False
    DataSource = dsCaducidadesPrint
    BCDToCurrency = False
    DataSetOptions = []
    Left = 96
    Top = 128
  end
end
