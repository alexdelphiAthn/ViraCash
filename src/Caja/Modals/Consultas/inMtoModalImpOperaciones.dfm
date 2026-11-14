inherited frmPrintOperaciones: TfrmPrintOperaciones
  Caption = 'Imprimir Hist'#243'rico de Operaciones'
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
  inherited pnl1: TPanel
    inherited btnExcel: TcxButton
      Caption = 'E&xcel (nativo)'
      OnClick = btnExcelNativoClick
    end
  end
  inherited frxrprt1: TfrxReport
    Datasets = <
      item
        DataSet = fxdsOperaciones
        DataSetName = 'Operaciones'
      end
      item
        DataSet = fxdsTotalesOperaciones
        DataSetName = 'TotalesOperaciones'
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
        DataSet = fxdsOperaciones
        DataSetName = 'Operaciones'
      end
      item
        DataSet = fxdsTotalesOperaciones
        DataSetName = 'TotalesOperaciones'
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
            'OPERACIONES DE CAJA')
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
            'Listado de operaciones de caja del [Operaciones."FECHA_DESDE_I' +
            'NF"] al [Operaciones."FECHA_HASTA_INF"]')
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
          Width = 110.000000000000000000
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
        object MemoHFecha: TfrxMemoView
          Left = 110.000000000000000000
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
            'Fecha')
          ParentFont = False
        end
        object MemoHTipo: TfrxMemoView
          Left = 240.000000000000000000
          Top = 2.000000000000000000
          Width = 55.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Tipo')
          ParentFont = False
        end
        object MemoHCliente: TfrxMemoView
          Left = 295.000000000000000000
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
            'Cliente')
          ParentFont = False
        end
        object MemoHSerie: TfrxMemoView
          Left = 390.000000000000000000
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
            'Serie')
          ParentFont = False
        end
        object MemoHFactura: TfrxMemoView
          Left = 475.000000000000000000
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
            'Factura')
          ParentFont = False
        end
        object MemoHConcepto: TfrxMemoView
          Left = 570.000000000000000000
          Top = 2.000000000000000000
          Width = 330.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Concepto')
          ParentFont = False
        end
        object MemoHImporte: TfrxMemoView
          Left = 900.000000000000000000
          Top = 2.000000000000000000
          Width = 147.000000000000000000
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
        Height = 20.000000000000000000
        Top = 84.000000000000000000
        Width = 1047.000000000000000000
        DataSet = fxdsOperaciones
        DataSetName = 'Operaciones'
        RowCount = 0
        Frame.Typ = []
        object MemoOperacion: TfrxMemoView
          Left = 0.000000000000000000
          Top = 1.000000000000000000
          Width = 110.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsOperaciones
          DataSetName = 'Operaciones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Operaciones."NUMERO_OPERACION_OPCAJA"]')
          ParentFont = False
        end
        object MemoFecha: TfrxMemoView
          Left = 110.000000000000000000
          Top = 1.000000000000000000
          Width = 130.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsOperaciones
          DataSetName = 'Operaciones'
          DisplayFormat.FormatStr = 'dd/mm/yyyy hh:nn'
          DisplayFormat.Kind = fkDateTime
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Operaciones."FECHA_OPERACION_OPCAJA"]')
          ParentFont = False
        end
        object MemoTipo: TfrxMemoView
          Left = 240.000000000000000000
          Top = 1.000000000000000000
          Width = 55.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsOperaciones
          DataSetName = 'Operaciones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Operaciones."TIPO_OPERACION_OPCAJA"]')
          ParentFont = False
        end
        object MemoCliente: TfrxMemoView
          Left = 295.000000000000000000
          Top = 1.000000000000000000
          Width = 95.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsOperaciones
          DataSetName = 'Operaciones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Operaciones."CODIGO_CLI_OPCAJA"]')
          ParentFont = False
        end
        object MemoSerie: TfrxMemoView
          Left = 390.000000000000000000
          Top = 1.000000000000000000
          Width = 85.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsOperaciones
          DataSetName = 'Operaciones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Operaciones."SERIE_FAC_OPCAJA"]')
          ParentFont = False
        end
        object MemoFactura: TfrxMemoView
          Left = 475.000000000000000000
          Top = 1.000000000000000000
          Width = 95.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsOperaciones
          DataSetName = 'Operaciones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Operaciones."NUMERO_FAC_INF"]')
          ParentFont = False
        end
        object MemoConcepto: TfrxMemoView
          Left = 570.000000000000000000
          Top = 1.000000000000000000
          Width = 330.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsOperaciones
          DataSetName = 'Operaciones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Operaciones."CONCEPTO_GASTO_INGRESO_OPCAJA"]')
          ParentFont = False
        end
        object MemoImporte: TfrxMemoView
          Left = 900.000000000000000000
          Top = 1.000000000000000000
          Width = 147.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsOperaciones
          DataSetName = 'Operaciones'
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
            '[Operaciones."IMPORTE_TOTAL_OPCAJA"]')
          ParentFont = False
        end
      end
      object HeaderTotalesOperaciones: TfrxHeader
        FillType = ftBrush
        Height = 50.000000000000000000
        Top = 130.000000000000000000
        Width = 1047.000000000000000000
        Frame.Typ = []
        object MemoTitTotalesOperaciones: TfrxMemoView
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
            'Totales por tipo de operaci'#243'n')
          ParentFont = False
        end
        object MemoHTTipo: TfrxMemoView
          Left = 0.000000000000000000
          Top = 30.000000000000000000
          Width = 240.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Tipo')
          ParentFont = False
        end
        object MemoHTNumOperaciones: TfrxMemoView
          Left = 240.000000000000000000
          Top = 30.000000000000000000
          Width = 150.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Operaciones')
          ParentFont = False
        end
        object MemoHTHueco: TfrxMemoView
          Left = 390.000000000000000000
          Top = 30.000000000000000000
          Width = 510.000000000000000000
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
        object MemoHTImporte: TfrxMemoView
          Left = 900.000000000000000000
          Top = 30.000000000000000000
          Width = 147.000000000000000000
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
      object MasterDataTotalesOperaciones: TfrxMasterData
        FillType = ftBrush
        Height = 20.000000000000000000
        Top = 200.000000000000000000
        Width = 1047.000000000000000000
        DataSet = fxdsTotalesOperaciones
        DataSetName = 'TotalesOperaciones'
        KeepTogether = True
        RowCount = 0
        Frame.Typ = []
        object MemoTTipo: TfrxMemoView
          Left = 0.000000000000000000
          Top = 1.000000000000000000
          Width = 240.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsTotalesOperaciones
          DataSetName = 'TotalesOperaciones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[TotalesOperaciones."TIPO_OPERACION_OPCAJA"]')
          ParentFont = False
        end
        object MemoTNumOperaciones: TfrxMemoView
          Left = 240.000000000000000000
          Top = 1.000000000000000000
          Width = 150.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsTotalesOperaciones
          DataSetName = 'TotalesOperaciones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[TotalesOperaciones."NUMERO_OPERACIONES_INF"]')
          ParentFont = False
        end
        object MemoTImporte: TfrxMemoView
          Left = 900.000000000000000000
          Top = 1.000000000000000000
          Width = 147.000000000000000000
          Height = 18.000000000000000000
          DataSet = fxdsTotalesOperaciones
          DataSetName = 'TotalesOperaciones'
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
            '[TotalesOperaciones."IMPORTE_TOTAL_INF"]')
          ParentFont = False
        end
      end
      object FooterTotalesOperaciones: TfrxFooter
        FillType = ftBrush
        Height = 24.000000000000000000
        Top = 240.000000000000000000
        Width = 1047.000000000000000000
        Frame.Typ = []
        object MemoTotGeneral: TfrxMemoView
          Left = 0.000000000000000000
          Top = 3.000000000000000000
          Width = 240.000000000000000000
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
        object MemoTotNumOperaciones: TfrxMemoView
          Left = 240.000000000000000000
          Top = 3.000000000000000000
          Width = 150.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<TotalesOperaciones."NUMERO_OPERACIONES_INF">,MasterDat' +
            'aTotalesOperaciones)]')
          ParentFont = False
        end
        object MemoTotHueco: TfrxMemoView
          Left = 390.000000000000000000
          Top = 3.000000000000000000
          Width = 510.000000000000000000
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
        object MemoTotImporte: TfrxMemoView
          Left = 900.000000000000000000
          Top = 3.000000000000000000
          Width = 147.000000000000000000
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
            '[SUM(<TotalesOperaciones."IMPORTE_TOTAL_INF">,MasterDataTota' +
            'lesOperaciones)]')
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
  object dsOperacionesPrint: TDataSource
    Left = 96
    Top = 72
  end
  object fxdsOperaciones: TfrxDBDataset
    Description = 'Operaciones'
    UserName = 'Operaciones'
    CloseDataSource = False
    DataSource = dsOperacionesPrint
    BCDToCurrency = False
    DataSetOptions = []
    Left = 96
    Top = 128
  end
  object dsTotalesOperacionesPrint: TDataSource
    Left = 208
    Top = 72
  end
  object fxdsTotalesOperaciones: TfrxDBDataset
    Description = 'TotalesOperaciones'
    UserName = 'TotalesOperaciones'
    CloseDataSource = False
    DataSource = dsTotalesOperacionesPrint
    BCDToCurrency = False
    DataSetOptions = []
    Left = 208
    Top = 128
  end
end
