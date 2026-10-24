inherited frmPrintPagos: TfrmPrintPagos
  Caption = 'Imprimir Hist'#243'rico de Pagos'
  ClientHeight = 320
  ClientWidth = 640
  TextHeight = 19
  object lblFechas: TcxLabel
    Left = 12
    Top = 10
    Caption = 'Rango de fechas:'
    TabOrder = 6
    Transparent = True
  end
  object lblDesde: TcxLabel
    Left = 12
    Top = 34
    Caption = 'Fecha inicio:'
    TabOrder = 7
    Transparent = True
  end
  object dteDesde: TcxDateEdit
    Left = 12
    Top = 52
    Properties.OnEditValueChanged = dtFechasPropertiesEditValueChanged
    TabOrder = 1
    Width = 172
  end
  object lblHasta: TcxLabel
    Left = 12
    Top = 80
    Caption = 'Fecha fin:'
    TabOrder = 8
    Transparent = True
  end
  object dteHasta: TcxDateEdit
    Left = 12
    Top = 98
    Properties.OnEditValueChanged = dtFechasPropertiesEditValueChanged
    TabOrder = 2
    Width = 172
  end
  object lblCajaTit: TcxLabel
    Left = 12
    Top = 130
    Caption = 'Caja a imprimir:'
    TabOrder = 9
    Transparent = True
  end
  object lblEmpresa: TcxLabel
    Left = 12
    Top = 154
    Caption = 'Empresa:'
    TabOrder = 10
    Transparent = True
  end
  object edtEmpresa: TcxTextEdit
    Left = 12
    Top = 172
    Properties.ReadOnly = True
    TabOrder = 3
    Width = 172
  end
  object lblAlmacen: TcxLabel
    Left = 12
    Top = 200
    Caption = 'Almac'#233'n:'
    TabOrder = 11
    Transparent = True
  end
  object bedAlmacen: TcxButtonEdit
    Left = 12
    Top = 218
    Properties.Buttons = <
      item
        Default = True
        Kind = bkEllipsis
      end>
    Properties.OnButtonClick = bedAlmacenPropertiesButtonClick
    TabOrder = 4
    Width = 172
  end
  object lblCaja: TcxLabel
    Left = 12
    Top = 246
    Caption = 'Caja:'
    TabOrder = 12
    Transparent = True
  end
  object bedCaja: TcxButtonEdit
    Left = 12
    Top = 264
    Properties.Buttons = <
      item
        Default = True
        Kind = bkEllipsis
      end>
    Properties.OnButtonClick = bedCajaPropertiesButtonClick
    TabOrder = 5
    Width = 172
  end
  object lblFormasPago: TcxLabel
    Left = 200
    Top = 10
    Caption = 'Formas de pago (en el periodo):'
    TabOrder = 14
    Transparent = True
  end
  object clbFormasPago: TcxCheckListBox
    Left = 200
    Top = 34
    Width = 270
    Height = 272
    Items = <>
    TabOrder = 13
  end
  inherited frxrprt1: TfrxReport
    Datasets = <
      item
        DataSet = fxdsPagos
        DataSetName = 'Pagos'
      end
      item
        DataSet = fxdsTotalesPagos
        DataSetName = 'TotalesPagos'
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
        DataSet = fxdsPagos
        DataSetName = 'Pagos'
      end
      item
        DataSet = fxdsTotalesPagos
        DataSetName = 'TotalesPagos'
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
        Height = 54.000000000000000000
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
            'PAGOS DE CAJA')
          ParentFont = False
        end
        object MemoSubtitulo: TfrxMemoView
          Left = 0.000000000000000000
          Top = 32.000000000000000000
          Width = 1047.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haCenter
          Memo.UTF8W = (
            'Listado de pagos de caja del [Pagos."FECHA_DESDE_INF"] al [P' +
            'agos."FECHA_HASTA_INF"]')
          ParentFont = False
        end
      end
      object PageHeader1: TfrxPageHeader
        Height = 22.000000000000000000
        Top = 58.000000000000000000
        Width = 1047.000000000000000000
        Frame.Typ = []
        object MemoHOperacion: TfrxMemoView
          Left = 0.000000000000000000
          Top = 2.000000000000000000
          Width = 95.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Operaci'#243'n')
          ParentFont = False
        end
        object MemoHLinea: TfrxMemoView
          Left = 95.000000000000000000
          Top = 2.000000000000000000
          Width = 32.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'L'#237'n.')
          ParentFont = False
        end
        object MemoHFecha: TfrxMemoView
          Left = 135.000000000000000000
          Top = 2.000000000000000000
          Width = 120.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Fecha')
          ParentFont = False
        end
        object MemoHSerieFac: TfrxMemoView
          Left = 255.000000000000000000
          Top = 2.000000000000000000
          Width = 85.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Serie Fac.')
          ParentFont = False
        end
        object MemoHFactura: TfrxMemoView
          Left = 340.000000000000000000
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
            'N'#186' Factura')
          ParentFont = False
        end
        object MemoHFormaPago: TfrxMemoView
          Left = 430.000000000000000000
          Top = 2.000000000000000000
          Width = 85.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Forma pago')
          ParentFont = False
        end
        object MemoHDivisa: TfrxMemoView
          Left = 515.000000000000000000
          Top = 2.000000000000000000
          Width = 60.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Divisa')
          ParentFont = False
        end
        object MemoHEntregado: TfrxMemoView
          Left = 575.000000000000000000
          Top = 2.000000000000000000
          Width = 120.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Entregado')
          ParentFont = False
        end
        object MemoHCambio: TfrxMemoView
          Left = 695.000000000000000000
          Top = 2.000000000000000000
          Width = 100.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Cambio')
          ParentFont = False
        end
        object MemoHReferencia: TfrxMemoView
          Left = 815.000000000000000000
          Top = 2.000000000000000000
          Width = 232.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Referencia')
          ParentFont = False
        end
      end
      object MasterData1: TfrxMasterData
        FillType = ftBrush
        Height = 20.000000000000000000
        Top = 84.000000000000000000
        Width = 1047.000000000000000000
        DataSet = fxdsPagos
        DataSetName = 'Pagos'
        RowCount = 0
        Frame.Typ = []
        object MemoOperacion: TfrxMemoView
          Left = 0.000000000000000000
          Top = 1.000000000000000000
          Width = 95.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsPagos
          DataSetName = 'Pagos'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Pagos."NUMERO_OPERACION_PAGO"]')
          ParentFont = False
        end
        object MemoLinea: TfrxMemoView
          Left = 95.000000000000000000
          Top = 1.000000000000000000
          Width = 32.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsPagos
          DataSetName = 'Pagos'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Pagos."NUMERO_LINEA_PAGO"]')
          ParentFont = False
        end
        object MemoFecha: TfrxMemoView
          Left = 135.000000000000000000
          Top = 1.000000000000000000
          Width = 120.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsPagos
          DataSetName = 'Pagos'
          DisplayFormat.FormatStr = 'dd/mm/yyyy hh:nn'
          DisplayFormat.Kind = fkDateTime
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Pagos."FECHA_PAGO"]')
          ParentFont = False
        end
        object MemoSerieFac: TfrxMemoView
          Left = 255.000000000000000000
          Top = 1.000000000000000000
          Width = 85.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsPagos
          DataSetName = 'Pagos'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Pagos."SERIE_FAC_PAGO"]')
          ParentFont = False
        end
        object MemoFactura: TfrxMemoView
          Left = 340.000000000000000000
          Top = 1.000000000000000000
          Width = 90.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsPagos
          DataSetName = 'Pagos'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Pagos."NUMERO_FAC_PAGO"]')
          ParentFont = False
        end
        object MemoFormaPago: TfrxMemoView
          Left = 430.000000000000000000
          Top = 1.000000000000000000
          Width = 85.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsPagos
          DataSetName = 'Pagos'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Pagos."CODIGO_FP_CFP"]')
          ParentFont = False
        end
        object MemoDivisa: TfrxMemoView
          Left = 515.000000000000000000
          Top = 1.000000000000000000
          Width = 60.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsPagos
          DataSetName = 'Pagos'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Pagos."CODIGO_DIVISA_PAGO"]')
          ParentFont = False
        end
        object MemoEntregado: TfrxMemoView
          Left = 575.000000000000000000
          Top = 1.000000000000000000
          Width = 120.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsPagos
          DataSetName = 'Pagos'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Pagos."IMPORTE_ENTREGADO_PAGO"]')
          ParentFont = False
        end
        object MemoCambio: TfrxMemoView
          Left = 695.000000000000000000
          Top = 1.000000000000000000
          Width = 100.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsPagos
          DataSetName = 'Pagos'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Pagos."IMPORTE_CAMBIO_PAGO"]')
          ParentFont = False
        end
        object MemoReferencia: TfrxMemoView
          Left = 815.000000000000000000
          Top = 1.000000000000000000
          Width = 232.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsPagos
          DataSetName = 'Pagos'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Pagos."REFERENCIA_FACPAG"]')
          ParentFont = False
        end
      end
      object HeaderTotalesPagos: TfrxHeader
        FillType = ftBrush
        Height = 50.000000000000000000
        Top = 130.000000000000000000
        Width = 1047.000000000000000000
        Frame.Typ = []
        object MemoTitTotalesPagos: TfrxMemoView
          Left = 0.000000000000000000
          Top = 10.000000000000000000
          Width = 1047.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            'Totales por forma de pago')
          ParentFont = False
        end
        object MemoHTFormaPago: TfrxMemoView
          Left = 0.000000000000000000
          Top = 30.000000000000000000
          Width = 95.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Forma pago')
          ParentFont = False
        end
        object MemoHTDescripcion: TfrxMemoView
          Left = 95.000000000000000000
          Top = 30.000000000000000000
          Width = 335.000000000000000000
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
        object MemoHTNumPagos: TfrxMemoView
          Left = 430.000000000000000000
          Top = 30.000000000000000000
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
            'Pagos')
          ParentFont = False
        end
        object MemoHTHueco: TfrxMemoView
          Left = 515.000000000000000000
          Top = 30.000000000000000000
          Width = 60.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            '')
          ParentFont = False
        end
        object MemoHTEntregado: TfrxMemoView
          Left = 575.000000000000000000
          Top = 30.000000000000000000
          Width = 120.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Entregado')
          ParentFont = False
        end
        object MemoHTCambio: TfrxMemoView
          Left = 695.000000000000000000
          Top = 30.000000000000000000
          Width = 100.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Cambio')
          ParentFont = False
        end
        object MemoHTNeto: TfrxMemoView
          Left = 795.000000000000000000
          Top = 30.000000000000000000
          Width = 120.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Neto')
          ParentFont = False
        end
      end
      object MasterDataTotalesPagos: TfrxMasterData
        FillType = ftBrush
        Height = 20.000000000000000000
        Top = 200.000000000000000000
        Width = 1047.000000000000000000
        DataSet = fxdsTotalesPagos
        DataSetName = 'TotalesPagos'
        KeepTogether = True
        RowCount = 0
        Frame.Typ = []
        object MemoTFormaPago: TfrxMemoView
          Left = 0.000000000000000000
          Top = 1.000000000000000000
          Width = 95.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsTotalesPagos
          DataSetName = 'TotalesPagos'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[TotalesPagos."CODIGO_FP_CFP"]')
          ParentFont = False
        end
        object MemoTDescripcion: TfrxMemoView
          Left = 95.000000000000000000
          Top = 1.000000000000000000
          Width = 335.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsTotalesPagos
          DataSetName = 'TotalesPagos'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[TotalesPagos."DESCRIPCION_FP_PAGO"]')
          ParentFont = False
        end
        object MemoTNumPagos: TfrxMemoView
          Left = 430.000000000000000000
          Top = 1.000000000000000000
          Width = 85.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsTotalesPagos
          DataSetName = 'TotalesPagos'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[TotalesPagos."NUMERO_PAGOS_INF"]')
          ParentFont = False
        end
        object MemoTEntregado: TfrxMemoView
          Left = 575.000000000000000000
          Top = 1.000000000000000000
          Width = 120.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsTotalesPagos
          DataSetName = 'TotalesPagos'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[TotalesPagos."ENTREGADO_INF"]')
          ParentFont = False
        end
        object MemoTCambio: TfrxMemoView
          Left = 695.000000000000000000
          Top = 1.000000000000000000
          Width = 100.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsTotalesPagos
          DataSetName = 'TotalesPagos'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[TotalesPagos."CAMBIO_INF"]')
          ParentFont = False
        end
        object MemoTNeto: TfrxMemoView
          Left = 795.000000000000000000
          Top = 1.000000000000000000
          Width = 120.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsTotalesPagos
          DataSetName = 'TotalesPagos'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[TotalesPagos."NETO_INF"]')
          ParentFont = False
        end
      end
      object FooterTotalesPagos: TfrxFooter
        FillType = ftBrush
        Height = 24.000000000000000000
        Top = 240.000000000000000000
        Width = 1047.000000000000000000
        Frame.Typ = []
        object MemoTotGeneral: TfrxMemoView
          Left = 0.000000000000000000
          Top = 3.000000000000000000
          Width = 430.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          Memo.UTF8W = (
            'Total general')
          ParentFont = False
        end
        object MemoTotNumPagos: TfrxMemoView
          Left = 430.000000000000000000
          Top = 3.000000000000000000
          Width = 85.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<TotalesPagos."NUMERO_PAGOS_INF">,MasterDataTotalesPa' +
            'gos)]')
          ParentFont = False
        end
        object MemoTotHueco: TfrxMemoView
          Left = 515.000000000000000000
          Top = 3.000000000000000000
          Width = 60.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          Memo.UTF8W = (
            '')
          ParentFont = False
        end
        object MemoTotEntregado: TfrxMemoView
          Left = 575.000000000000000000
          Top = 3.000000000000000000
          Width = 120.000000000000000000
          Height = 18.000000000000000000
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
            '[SUM(<TotalesPagos."ENTREGADO_INF">,MasterDataTotalesPagos)]')
          ParentFont = False
        end
        object MemoTotCambio: TfrxMemoView
          Left = 695.000000000000000000
          Top = 3.000000000000000000
          Width = 100.000000000000000000
          Height = 18.000000000000000000
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
            '[SUM(<TotalesPagos."CAMBIO_INF">,MasterDataTotalesPagos)]')
          ParentFont = False
        end
        object MemoTotNeto: TfrxMemoView
          Left = 795.000000000000000000
          Top = 3.000000000000000000
          Width = 120.000000000000000000
          Height = 18.000000000000000000
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
            '[SUM(<TotalesPagos."NETO_INF">,MasterDataTotalesPagos)]')
          ParentFont = False
        end
      end
      object PageFooter1: TfrxPageFooter
        Height = 18.000000000000000000
        Top = 290.000000000000000000
        Width = 1047.000000000000000000
        Frame.Typ = []
        object MemoFooter: TfrxMemoView
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
  object dsPagosPrint: TDataSource
    Left = 408
    Top = 72
  end
  object fxdsPagos: TfrxDBDataset
    Description = 'Pagos'
    UserName = 'Pagos'
    CloseDataSource = False
    DataSource = dsPagosPrint
    BCDToCurrency = False
    DataSetOptions = []
    Left = 408
    Top = 128
  end
  object dsTotalesPagosPrint: TDataSource
    Left = 520
    Top = 72
  end
  object fxdsTotalesPagos: TfrxDBDataset
    Description = 'TotalesPagos'
    UserName = 'TotalesPagos'
    CloseDataSource = False
    DataSource = dsTotalesPagosPrint
    BCDToCurrency = False
    DataSetOptions = []
    Left = 520
    Top = 128
  end
end
