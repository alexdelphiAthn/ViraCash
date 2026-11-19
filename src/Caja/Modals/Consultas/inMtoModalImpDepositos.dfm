inherited frmPrintDepositos: TfrmPrintDepositos
  Caption = 'Imprimir Hist'#243'rico de Dep'#243'sitos'
  ClientHeight = 320
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
  inherited frxrprt1: TfrxReport
    Datasets = <
      item
        DataSet = fxdsDepositos
        DataSetName = 'Depositos'
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
        DataSet = fxdsDepositos
        DataSetName = 'Depositos'
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
            'DEP'#211'SITOS DE CLIENTES')
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
            'Listado de dep'#243'sitos de clientes del [Depositos."FECHA_DESDE' +
            '_INF"] al [Depositos."FECHA_HASTA_INF"]')
          ParentFont = False
        end
      end
      object PageHeader1: TfrxPageHeader
        Height = 22.000000000000000000
        Top = 58.000000000000000000
        Width = 1047.000000000000000000
        Frame.Typ = []
        object MemoHId: TfrxMemoView
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
            'ID Dep'#243'sito')
          ParentFont = False
        end
        object MemoHFecha: TfrxMemoView
          Left = 150.000000000000000000
          Top = 2.000000000000000000
          Width = 115.000000000000000000
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
        object MemoHCliente: TfrxMemoView
          Left = 265.000000000000000000
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
            'Cliente')
          ParentFont = False
        end
        object MemoHArticulo: TfrxMemoView
          Left = 345.000000000000000000
          Top = 2.000000000000000000
          Width = 185.000000000000000000
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
        object MemoHPrecio: TfrxMemoView
          Left = 530.000000000000000000
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
            'Precio venta')
          ParentFont = False
        end
        object MemoHCantidad: TfrxMemoView
          Left = 615.000000000000000000
          Top = 2.000000000000000000
          Width = 55.000000000000000000
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
        object MemoHImporte: TfrxMemoView
          Left = 670.000000000000000000
          Top = 2.000000000000000000
          Width = 90.000000000000000000
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
        object MemoHAnticipo: TfrxMemoView
          Left = 760.000000000000000000
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
            'Anticipo')
          ParentFont = False
        end
        object MemoHEstado: TfrxMemoView
          Left = 845.000000000000000000
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
            'Estado')
          ParentFont = False
        end
        object MemoHOperacion: TfrxMemoView
          Left = 940.000000000000000000
          Top = 2.000000000000000000
          Width = 107.000000000000000000
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
      end
      object MasterData1: TfrxMasterData
        FillType = ftBrush
        Height = 20.000000000000000000
        Top = 84.000000000000000000
        Width = 1047.000000000000000000
        DataSet = fxdsDepositos
        DataSetName = 'Depositos'
        RowCount = 0
        Frame.Typ = []
        object MemoId: TfrxMemoView
          Left = 0.000000000000000000
          Top = 1.000000000000000000
          Width = 150.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsDepositos
          DataSetName = 'Depositos'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Depositos."ID_DEPOSITO_DEP"]')
          ParentFont = False
        end
        object MemoFecha: TfrxMemoView
          Left = 150.000000000000000000
          Top = 1.000000000000000000
          Width = 115.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsDepositos
          DataSetName = 'Depositos'
          DisplayFormat.FormatStr = 'dd/mm/yyyy hh:nn'
          DisplayFormat.Kind = fkDateTime
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Depositos."FECHA_CREACION_DEP"]')
          ParentFont = False
        end
        object MemoCliente: TfrxMemoView
          Left = 265.000000000000000000
          Top = 1.000000000000000000
          Width = 80.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsDepositos
          DataSetName = 'Depositos'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Depositos."CODIGO_CLI_DEP"]')
          ParentFont = False
        end
        object MemoArticulo: TfrxMemoView
          Left = 345.000000000000000000
          Top = 1.000000000000000000
          Width = 185.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsDepositos
          DataSetName = 'Depositos'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Depositos."CODIGO_UNIDAD_DEP"]')
          ParentFont = False
        end
        object MemoPrecio: TfrxMemoView
          Left = 530.000000000000000000
          Top = 1.000000000000000000
          Width = 85.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsDepositos
          DataSetName = 'Depositos'
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
            '[Depositos."PRECIO_VENTA_DEP"]')
          ParentFont = False
        end
        object MemoCantidad: TfrxMemoView
          Left = 615.000000000000000000
          Top = 1.000000000000000000
          Width = 55.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsDepositos
          DataSetName = 'Depositos'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          HAlign = haRight
          Memo.UTF8W = (
            '[Depositos."CANTIDAD_INF"]')
          ParentFont = False
        end
        object MemoImporte: TfrxMemoView
          Left = 670.000000000000000000
          Top = 1.000000000000000000
          Width = 90.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsDepositos
          DataSetName = 'Depositos'
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
            '[Depositos."IMPORTE_INF"]')
          ParentFont = False
        end
        object MemoAnticipo: TfrxMemoView
          Left = 760.000000000000000000
          Top = 1.000000000000000000
          Width = 85.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsDepositos
          DataSetName = 'Depositos'
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
            '[Depositos."IMPORTE_ANTICIPO_DEP"]')
          ParentFont = False
        end
        object MemoEstado: TfrxMemoView
          Left = 845.000000000000000000
          Top = 1.000000000000000000
          Width = 95.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsDepositos
          DataSetName = 'Depositos'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Depositos."ESTADO_DEP"]')
          ParentFont = False
        end
        object MemoOperacion: TfrxMemoView
          Left = 940.000000000000000000
          Top = 1.000000000000000000
          Width = 107.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsDepositos
          DataSetName = 'Depositos'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Depositos."NUMERO_OPERACION_DEP"]')
          ParentFont = False
        end
      end
      object FooterDepositos: TfrxFooter
        FillType = ftBrush
        Height = 44.000000000000000000
        Top = 128.000000000000000000
        Width = 1047.000000000000000000
        Frame.Typ = []
        object MemoTotTitulo: TfrxMemoView
          Left = 0.000000000000000000
          Top = 2.000000000000000000
          Width = 615.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haLeft
          Memo.UTF8W = (
            'Total')
          ParentFont = False
        end
        object MemoTotCantidad: TfrxMemoView
          Left = 615.000000000000000000
          Top = 2.000000000000000000
          Width = 55.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<Depositos."CANTIDAD_INF">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotImporte: TfrxMemoView
          Left = 670.000000000000000000
          Top = 2.000000000000000000
          Width = 90.000000000000000000
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
            '[SUM(<Depositos."IMPORTE_INF">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotAnticipo: TfrxMemoView
          Left = 760.000000000000000000
          Top = 2.000000000000000000
          Width = 85.000000000000000000
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
            '[SUM(<Depositos."IMPORTE_ANTICIPO_DEP">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotHueco: TfrxMemoView
          Left = 845.000000000000000000
          Top = 2.000000000000000000
          Width = 202.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '')
          ParentFont = False
        end
        object MemoTotPendiente: TfrxMemoView
          Left = 0.000000000000000000
          Top = 24.000000000000000000
          Width = 1047.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            'Pendiente de cobro de los dep'#243'sitos en estado PENDIENTE (importe - anticipo): [SUM(IIF(<Depositos."ESTADO_DEP"> = ''PENDIENTE'', <Depositos."IMPORTE_INF"> - <Depositos."IMPORTE_ANTICIPO_DEP">, 0),MasterData1) #n%2,2m]')
          ParentFont = False
        end
      end
      object PageFooter1: TfrxPageFooter
        Height = 18.000000000000000000
        Top = 190.000000000000000000
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
  object dsDepositosPrint: TDataSource
    Left = 96
    Top = 72
  end
  object fxdsDepositos: TfrxDBDataset
    Description = 'Depositos'
    UserName = 'Depositos'
    CloseDataSource = False
    DataSource = dsDepositosPrint
    BCDToCurrency = False
    DataSetOptions = []
    Left = 96
    Top = 128
  end
end
