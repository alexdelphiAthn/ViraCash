inherited frmPrintArqueos: TfrmPrintArqueos
  Caption = 'Imprimir Hist'#243'rico de Arqueos'
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
        DataSet = fxdsArqueos
        DataSetName = 'Arqueos'
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
        DataSet = fxdsArqueos
        DataSetName = 'Arqueos'
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
            'HIST'#211'RICO DE ARQUEOS DE CAJA')
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
            'Listado de arqueos grabados del [Arqueos."FECHA_DESDE_INF"] al' +
            ' [Arqueos."FECHA_HASTA_INF"]')
          ParentFont = False
        end
      end
      object PageHeader1: TfrxPageHeader
        Height = 22.000000000000000000
        Top = 58.000000000000000000
        Width = 1047.000000000000000000
        Frame.Typ = []
        object MemoHCodigo: TfrxMemoView
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
            'C'#243'digo')
          ParentFont = False
        end
        object MemoHDesde: TfrxMemoView
          Left = 150.000000000000000000
          Top = 2.000000000000000000
          Width = 110.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Desde')
          ParentFont = False
        end
        object MemoHHasta: TfrxMemoView
          Left = 260.000000000000000000
          Top = 2.000000000000000000
          Width = 110.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Hasta')
          ParentFont = False
        end
        object MemoHVentas: TfrxMemoView
          Left = 370.000000000000000000
          Top = 2.000000000000000000
          Width = 165.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Total Ventas')
          ParentFont = False
        end
        object MemoHEfectivo: TfrxMemoView
          Left = 535.000000000000000000
          Top = 2.000000000000000000
          Width = 170.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Efectivo Caja')
          ParentFont = False
        end
        object MemoHRecuento: TfrxMemoView
          Left = 705.000000000000000000
          Top = 2.000000000000000000
          Width = 170.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Recuento')
          ParentFont = False
        end
        object MemoHDiferencia: TfrxMemoView
          Left = 875.000000000000000000
          Top = 2.000000000000000000
          Width = 172.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Diferencia')
          ParentFont = False
        end
      end
      object MasterData1: TfrxMasterData
        FillType = ftBrush
        Height = 20.000000000000000000
        Top = 84.000000000000000000
        Width = 1047.000000000000000000
        DataSet = fxdsArqueos
        DataSetName = 'Arqueos'
        RowCount = 0
        Frame.Typ = []
        object MemoCodigo: TfrxMemoView
          Left = 0.000000000000000000
          Top = 1.000000000000000000
          Width = 150.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsArqueos
          DataSetName = 'Arqueos'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Arqueos."CODIGO_ARQ"]')
          ParentFont = False
        end
        object MemoDesde: TfrxMemoView
          Left = 150.000000000000000000
          Top = 1.000000000000000000
          Width = 110.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsArqueos
          DataSetName = 'Arqueos'
          DisplayFormat.FormatStr = 'dd/mm/yyyy hh:nn'
          DisplayFormat.Kind = fkDateTime
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Arqueos."FECHA_DESDE_ARQ"]')
          ParentFont = False
        end
        object MemoHasta: TfrxMemoView
          Left = 260.000000000000000000
          Top = 1.000000000000000000
          Width = 110.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsArqueos
          DataSetName = 'Arqueos'
          DisplayFormat.FormatStr = 'dd/mm/yyyy hh:nn'
          DisplayFormat.Kind = fkDateTime
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Arqueos."FECHA_HASTA_ARQ"]')
          ParentFont = False
        end
        object MemoTotalVentas: TfrxMemoView
          Left = 370.000000000000000000
          Top = 1.000000000000000000
          Width = 165.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsArqueos
          DataSetName = 'Arqueos'
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
            '[Arqueos."TOTAL_VENTAS_ARQ"]')
          ParentFont = False
        end
        object MemoEfectivo: TfrxMemoView
          Left = 535.000000000000000000
          Top = 1.000000000000000000
          Width = 170.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsArqueos
          DataSetName = 'Arqueos'
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
            '[Arqueos."TOTAL_EFECTIVO_CAJA_ARQ"]')
          ParentFont = False
        end
        object MemoRecuento: TfrxMemoView
          Left = 705.000000000000000000
          Top = 1.000000000000000000
          Width = 170.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsArqueos
          DataSetName = 'Arqueos'
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
            '[Arqueos."TOTAL_RECUENTO_ARQ"]')
          ParentFont = False
        end
        object MemoDiferencia: TfrxMemoView
          Left = 875.000000000000000000
          Top = 1.000000000000000000
          Width = 172.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsArqueos
          DataSetName = 'Arqueos'
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
            '[Arqueos."DIFERENCIA_TOTAL_ARQ"]')
          ParentFont = False
        end
      end
      object PageFooter1: TfrxPageFooter
        Height = 18.000000000000000000
        Top = 110.000000000000000000
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
  object dsArqueosPrint: TDataSource
    Left = 96
    Top = 72
  end
  object fxdsArqueos: TfrxDBDataset
    Description = 'Arqueos'
    UserName = 'Arqueos'
    CloseDataSource = False
    DataSource = dsArqueosPrint
    BCDToCurrency = False
    DataSetOptions = []
    Left = 96
    Top = 128
  end
end
