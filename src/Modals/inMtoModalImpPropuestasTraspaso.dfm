inherited frmPrintPropuestasTraspaso: TfrmPrintPropuestasTraspaso
  Caption = 'Imprimir propuestas de traspaso'
  ClientHeight = 240
  ClientWidth = 341
  TextHeight = 17
  object lblDescripcion: TcxLabel
    Left = 12
    Top = 20
    AutoSize = False
    Caption =
      'Una hoja por cada origen y destino, con los art'#237'culos por color ' +
      'y sus tallas.'
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
      object GroupHeaderPropuesta: TfrxGroupHeader
        Height = 134.000000000000000000
        Top = 18.000000000000000000
        Width = 718.110700000000000000
        Condition = 'Lineas."ID_PROPUESTA"'
        ReprintOnNewPage = True
        StartNewPage = True
        Frame.Typ = []
        object MemoTituloPropuesta: TfrxMemoView
          AllowVectorExport = True
          Width = 470.000000000000000000
          Height = 28.000000000000000000
          DataSet = fxdsCabecera
          DataSetName = 'Cabecera'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -19
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[Cabecera."TITULO"]')
          ParentFont = False
        end
        object MemoNumeroPropuesta: TfrxMemoView
          AllowVectorExport = True
          Left = 474.000000000000000000
          Top = 4.000000000000000000
          Width = 240.000000000000000000
          Height = 22.000000000000000000
          DataSet = fxdsLineas
          DataSetName = 'Lineas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -15
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Lineas."NUMERO"]')
          ParentFont = False
        end
        object MemoOrigenPropuesta: TfrxMemoView
          AllowVectorExport = True
          Left = 4.000000000000000000
          Top = 34.000000000000000000
          Width = 352.000000000000000000
          Height = 24.000000000000000000
          DataSet = fxdsLineas
          DataSetName = 'Lineas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -16
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[Lineas."ORIGEN"]')
          ParentFont = False
        end
        object MemoDestinoPropuesta: TfrxMemoView
          AllowVectorExport = True
          Left = 360.000000000000000000
          Top = 34.000000000000000000
          Width = 354.000000000000000000
          Height = 24.000000000000000000
          DataSet = fxdsLineas
          DataSetName = 'Lineas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -16
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[Lineas."DESTINO"]')
          ParentFont = False
        end
        object MemoDocumentoPropuesta: TfrxMemoView
          AllowVectorExport = True
          Left = 4.000000000000000000
          Top = 64.000000000000000000
          Width = 470.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsLineas
          DataSetName = 'Lineas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Lineas."DOCUMENTO"]')
          ParentFont = False
        end
        object MemoFechaPropuesta: TfrxMemoView
          AllowVectorExport = True
          Left = 474.000000000000000000
          Top = 64.000000000000000000
          Width = 240.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsLineas
          DataSetName = 'Lineas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[FormatDateTime('#39'dd/mm/yyyy hh:nn'#39',<Lineas."FECHA">)]')
          ParentFont = False
        end
        object MemoEstadoPropuesta: TfrxMemoView
          AllowVectorExport = True
          Left = 4.000000000000000000
          Top = 84.000000000000000000
          Width = 710.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsLineas
          DataSetName = 'Lineas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Lineas."ESTADO"]')
          ParentFont = False
        end
        object MemoCabArticulo: TfrxMemoView
          AllowVectorExport = True
          Top = 110.000000000000000000
          Width = 104.000000000000000000
          Height = 22.000000000000000000
          DataSet = fxdsCabecera
          DataSetName = 'Cabecera'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            '[Cabecera."CAP_ARTICULO"]')
          ParentFont = False
        end
        object MemoCabDescripcion: TfrxMemoView
          AllowVectorExport = True
          Left = 104.000000000000000000
          Top = 110.000000000000000000
          Width = 206.000000000000000000
          Height = 22.000000000000000000
          DataSet = fxdsCabecera
          DataSetName = 'Cabecera'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            '[Cabecera."CAP_DESCRIPCION"]')
          ParentFont = False
        end
        object MemoCabColor: TfrxMemoView
          AllowVectorExport = True
          Left = 310.000000000000000000
          Top = 110.000000000000000000
          Width = 110.000000000000000000
          Height = 22.000000000000000000
          DataSet = fxdsCabecera
          DataSetName = 'Cabecera'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            '[Cabecera."CAP_COLOR"]')
          ParentFont = False
        end
        object MemoCabTallas: TfrxMemoView
          AllowVectorExport = True
          Left = 420.000000000000000000
          Top = 110.000000000000000000
          Width = 230.000000000000000000
          Height = 22.000000000000000000
          DataSet = fxdsCabecera
          DataSetName = 'Cabecera'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            '[Cabecera."CAP_TALLAS"]')
          ParentFont = False
        end
        object MemoCabUnidades: TfrxMemoView
          AllowVectorExport = True
          Left = 650.000000000000000000
          Top = 110.000000000000000000
          Width = 64.000000000000000000
          Height = 22.000000000000000000
          DataSet = fxdsCabecera
          DataSetName = 'Cabecera'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[Cabecera."CAP_UNIDADES"]')
          ParentFont = False
        end
      end
      object MasterDataLineas: TfrxMasterData
        Height = 20.000000000000000000
        Top = 156.000000000000000000
        Width = 718.110700000000000000
        DataSet = fxdsLineas
        DataSetName = 'Lineas'
        RowCount = 0
        Stretched = True
        Frame.Typ = []
        object MemoArticulo: TfrxMemoView
          AllowVectorExport = True
          Top = 2.000000000000000000
          Width = 104.000000000000000000
          Height = 16.000000000000000000
          DataField = 'ARTICULO'
          DataSet = fxdsLineas
          DataSetName = 'Lineas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Lineas."ARTICULO"]')
          ParentFont = False
        end
        object MemoDescripcion: TfrxMemoView
          AllowVectorExport = True
          Left = 104.000000000000000000
          Top = 2.000000000000000000
          Width = 206.000000000000000000
          Height = 16.000000000000000000
          DataField = 'DESCRIPCION'
          DataSet = fxdsLineas
          DataSetName = 'Lineas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Lineas."DESCRIPCION"]')
          ParentFont = False
          StretchMode = smActualHeight
          WordWrap = True
        end
        object MemoColor: TfrxMemoView
          AllowVectorExport = True
          Left = 310.000000000000000000
          Top = 2.000000000000000000
          Width = 110.000000000000000000
          Height = 16.000000000000000000
          DataField = 'COLOR'
          DataSet = fxdsLineas
          DataSetName = 'Lineas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Lineas."COLOR"]')
          ParentFont = False
        end
        object MemoTallas: TfrxMemoView
          AllowVectorExport = True
          Left = 420.000000000000000000
          Top = 2.000000000000000000
          Width = 230.000000000000000000
          Height = 16.000000000000000000
          DataField = 'TALLAS'
          DataSet = fxdsLineas
          DataSetName = 'Lineas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[Lineas."TALLAS"]')
          ParentFont = False
          StretchMode = smActualHeight
          WordWrap = True
        end
        object MemoUnidades: TfrxMemoView
          AllowVectorExport = True
          Left = 650.000000000000000000
          Top = 2.000000000000000000
          Width = 64.000000000000000000
          Height = 16.000000000000000000
          DataField = 'UNIDADES'
          DataSet = fxdsLineas
          DataSetName = 'Lineas'
          DisplayFormat.FormatStr = '#,##0.###'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Lineas."UNIDADES"]')
          ParentFont = False
        end
      end
      object GroupFooterPropuesta: TfrxGroupFooter
        Height = 34.000000000000000000
        Top = 180.000000000000000000
        Width = 718.110700000000000000
        Frame.Typ = []
        object MemoEtiquetaTotal: TfrxMemoView
          AllowVectorExport = True
          Left = 420.000000000000000000
          Top = 8.000000000000000000
          Width = 230.000000000000000000
          Height = 20.000000000000000000
          DataSet = fxdsCabecera
          DataSetName = 'Cabecera'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[Cabecera."CAP_TOTAL"]')
          ParentFont = False
        end
        object MemoTotalUnidades: TfrxMemoView
          AllowVectorExport = True
          Left = 650.000000000000000000
          Top = 8.000000000000000000
          Width = 64.000000000000000000
          Height = 20.000000000000000000
          DisplayFormat.FormatStr = '#,##0.###'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<Lineas."UNIDADES">,MasterDataLineas)]')
          ParentFont = False
        end
      end
      object PageFooterPropuesta: TfrxPageFooter
        Height = 18.000000000000000000
        Top = 218.000000000000000000
        Width = 718.110700000000000000
        Frame.Typ = []
        object MemoPaginaPropuesta: TfrxMemoView
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
    Description = 'Textos del informe de propuestas'
    UserName = 'Cabecera'
    CloseDataSource = False
    DataSource = dsCabecera
    BCDToCurrency = False
    DataSetOptions = []
    Left = 104
    Top = 120
  end
  object fxdsLineas: TfrxDBDataset
    Description = 'L'#237'neas de las propuestas de traspaso'
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
