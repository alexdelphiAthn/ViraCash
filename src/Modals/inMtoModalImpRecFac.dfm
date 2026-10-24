inherited frmPrintRecFac: TfrmPrintRecFac
  Caption = 'Imprimir Recibos'
  ClientHeight = 253
  ClientWidth = 434
  StyleElements = [seFont, seClient, seBorder]
  ExplicitWidth = 450
  ExplicitHeight = 292
  TextHeight = 19
  inherited pnl1: TPanel
    Left = 290
    Height = 253
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 288
    ExplicitHeight = 245
    inherited btnSalir: TcxButton
      Top = 227
      ExplicitTop = 219
    end
  end
  object lblcxlbl1: TcxLabel [1]
    Left = 8
    Top = 4
    Caption = 'Recibo Número'
    TabOrder = 1
    Transparent = True
  end
  object edtSerie: TcxTextEdit [2]
    Left = 8
    Top = 24
    Enabled = False
    TabOrder = 2
    Width = 41
  end
  object edtNroFac: TcxTextEdit [3]
    Left = 72
    Top = 24
    Enabled = False
    TabOrder = 3
    Width = 137
  end
  object cxrdgrp1: TcxRadioGroup [4]
    Left = 8
    Top = 71
    Caption = 'Opciones'
    Properties.Items = <>
    TabOrder = 4
    Height = 177
    Width = 281
    object rbActual: TcxRadioButton
      Left = 14
      Top = 28
      Width = 223
      Height = 17
      Caption = 'Imprimir recibo actual'
      Checked = True
      TabOrder = 0
      TabStop = True
      OnClick = rbActualClick
    end
    object rbRangoFechas: TcxRadioButton
      Left = 14
      Top = 55
      Width = 258
      Height = 36
      Caption = 'Imprimir todos los recibos de este borrador'
      TabOrder = 1
      WordWrap = True
      OnClick = rbRangoFechasClick
    end
  end
  object edtPlazoRecFac: TcxTextEdit [5]
    Left = 227
    Top = 23
    Enabled = False
    TabOrder = 5
    Width = 62
  end
  inherited frxrprt1: TfrxReport
    ReportOptions.LastChange = 45037.556420706000000000
    ScriptText.Strings = (
      'begin'
      ''
      'end.')
    Left = 376
    Top = 184
    Datasets = <
      item
        DataSet = dmFacturas.fxdsRecibos
        DataSetName = 'Recibos'
      end>
    Variables = <>
    Style = <>
    inherited Page1: TfrxReportPage
      object MasterData1: TfrxMasterData
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 343.937230000000000000
        Top = 18.897650000000000000
        Width = 755.906000000000000000
        DataSet = dmFacturas.fxdsRecibos
        DataSetName = 'Recibos'
        RowCount = 0
        object Memo10: TfrxMemoView
          AllowVectorExport = True
          Left = 20.236240000000000000
          Top = 59.252010000000000000
          Width = 343.937230000000000000
          Height = 49.133890000000000000
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          ParentFont = False
        end
        object Memo1: TfrxMemoView
          AllowVectorExport = True
          Left = 20.236240000000000000
          Top = 9.897650000000000000
          Width = 158.740260000000000000
          Height = 49.133890000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          ParentFont = False
        end
        object Memo2: TfrxMemoView
          AllowVectorExport = True
          Left = 35.354360000000000000
          Top = 36.354360000000000000
          Width = 124.724490000000000000
          Height = 15.118120000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haCenter
          Memo.UTF8W = (
            
              '[Recibos."DOCUMENTO_FACTURA_FORMATO"]\[IntToStr(<Recibos."NUMERO' +
              '_PLAZO_REC">)]')
          ParentFont = False
          Formats = <
            item
            end
            item
            end
            item
            end>
        end
        object Memo3: TfrxMemoView
          AllowVectorExport = True
          Left = 27.795300000000000000
          Top = 13.677180000000000000
          Width = 113.385900000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'RECIBO NRO')
          ParentFont = False
        end
        object Memo4: TfrxMemoView
          AllowVectorExport = True
          Left = 178.976500000000000000
          Top = 9.897650000000000000
          Width = 321.260050000000000000
          Height = 49.133890000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          ParentFont = False
        end
        object Memo5: TfrxMemoView
          AllowVectorExport = True
          Left = 220.551330000000000000
          Top = 36.354360000000000000
          Width = 226.771800000000000000
          Height = 15.118120000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Recibos."LOCALIDAD_EXPEDICION_RECIBO_REC"]')
          ParentFont = False
        end
        object Memo6: TfrxMemoView
          AllowVectorExport = True
          Left = 190.315090000000000000
          Top = 13.677180000000000000
          Width = 300.000000000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'LOCALIDAD DE EXPEDICIÓN')
          ParentFont = False
        end
        object Memo7: TfrxMemoView
          AllowVectorExport = True
          Left = 500.236550000000000000
          Top = 9.897650000000000000
          Width = 222.992270000000000000
          Height = 49.133890000000000000
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          ParentFont = False
        end
        object Memo8: TfrxMemoView
          AllowVectorExport = True
          Left = 522.913730000000000000
          Top = 13.677180000000000000
          Width = 173.858380000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'IMPORTE RECIBO')
          ParentFont = False
        end
        object Memo12: TfrxMemoView
          AllowVectorExport = True
          Left = 27.795300000000000000
          Top = 66.590600000000000000
          Width = 181.417440000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'FECHA DE EXPEDICIÓN')
          ParentFont = False
        end
        object Memo11: TfrxMemoView
          AllowVectorExport = True
          Left = 364.173470000000000000
          Top = 59.031540000000000000
          Width = 359.055350000000000000
          Height = 49.133890000000000000
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          ParentFont = False
        end
        object Memo13: TfrxMemoView
          AllowVectorExport = True
          Left = 379.291590000000000000
          Top = 66.370130000000000000
          Width = 330.000000000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'FECHA DE VENCIMIENTO')
          ParentFont = False
        end
        object Memo14: TfrxMemoView
          AllowVectorExport = True
          Left = 35.354360000000000000
          Top = 113.385900000000000000
          Width = 79.370130000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            'SON EU:')
          ParentFont = False
        end
        object Memo15: TfrxMemoView
          AllowVectorExport = True
          Left = 20.236240000000000000
          Top = 158.212740000000000000
          Width = 702.992580000000000000
          Height = 30.236240000000000000
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          ParentFont = False
        end
        object Memo16: TfrxMemoView
          AllowVectorExport = True
          Left = 27.795300000000000000
          Top = 162.771800000000000000
          Width = 181.417440000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'PAGADERO EN   <IBAN>  :')
          ParentFont = False
        end
        object Memo18: TfrxMemoView
          AllowVectorExport = True
          Left = 20.236240000000000000
          Top = 195.023810000000000000
          Width = 468.661720000000000000
          Height = 124.724490000000000000
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          ParentFont = False
        end
        object Memo19: TfrxMemoView
          AllowVectorExport = True
          Left = 27.795300000000000000
          Top = 202.362400000000000000
          Width = 370.000000000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'DOMICILIO Y NOMBRE DEL LIBRADO:')
          ParentFont = False
        end
        object FacturasRAZONSOCIAL_CLIENTE: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 27.795300000000000000
          Top = 225.260050000000000000
          Width = 400.630180000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[Recibos."RAZON_SOCIAL_CLI_REC"]')
          ParentFont = False
        end
        object FacturasDIRECCION1_CLIENTE: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 27.795300000000000000
          Top = 247.937230000000000000
          Width = 400.630180000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          Frame.Typ = []
          Memo.UTF8W = (
            '[Recibos."DIRECCION1_CLIENTE_RECIBO_REC"]')
        end
        object FacturasCPOSTAL_CLIENTE: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 27.795300000000000000
          Top = 266.834880000000000000
          Width = 120.944960000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          Frame.Typ = []
          Memo.UTF8W = (
            '[Recibos."CODIGO_POSTAL_CLI_REC"]')
        end
        object FacturasPOBLACION_CLIENTE: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 156.299320000000000000
          Top = 266.834880000000000000
          Width = 272.126160000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          Frame.Typ = []
          Memo.UTF8W = (
            '[Recibos."POBLACION_CLI_REC"]')
        end
        object FacturasPROVINCIA_CLIENTE: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 27.795300000000000000
          Top = 289.512060000000000000
          Width = 328.819110000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Recibos."PROVINCIA_CLI_REC"]')
          ParentFont = False
        end
        object FacturasCODIGO_CLIENTE: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 405.748300000000000000
          Top = 198.803340000000000000
          Width = 79.370130000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Recibos."CODIGO_CLI_REC"]')
          ParentFont = False
        end
        object Memo20: TfrxMemoView
          AllowVectorExport = True
          Left = 506.457020000000000000
          Top = 198.433210000000000000
          Width = 188.976500000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'CONFORME, EL LIBRADO')
          ParentFont = False
        end
        object FacturasIMPORTE_LETRA1: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 120.944960000000000000
          Top = 113.385900000000000000
          Width = 514.016080000000000000
          Height = 37.795300000000000000
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          Frame.Typ = []
          Memo.UTF8W = (
            '[Recibos."IMPORTE_LETRA_RECIBO_REC"]')
        end
        object FacturasIBAN: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 222.992270000000000000
          Top = 162.771800000000000000
          Width = 272.126160000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          Frame.Typ = []
          Memo.UTF8W = (
            '[Recibos."IBAN_CLI_REC"]')
        end
        object FacturasFECHA_EXPEDICION: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 222.992270000000000000
          Top = 81.590600000000000000
          Width = 109.606370000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          DisplayFormat.FormatStr = 'dd/mm/yyyy'
          DisplayFormat.Kind = fkDateTime
          Frame.Typ = []
          Memo.UTF8W = (
            '[Recibos."FECHA_EXPEDICION_RECIBO_REC"]')
        end
        object FacturasFECHA_VENCIMIENTO: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 574.488560000000000000
          Top = 81.590600000000000000
          Width = 102.047310000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          DisplayFormat.FormatStr = 'dd/mm/yyyy'
          DisplayFormat.Kind = fkDateTime
          Frame.Typ = []
          Memo.UTF8W = (
            '[Recibos."FECHA_VENCIMIENTO_RECIBO_REC"]')
        end
        object FacturasEUROS_RECIBO: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 521.575140000000000000
          Top = 32.456710000000000000
          Width = 173.858380000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Recibos."EUROS_RECIBO_REC"]')
          ParentFont = False
        end
        object Line1: TfrxLineView
          AllowVectorExport = True
          Top = 334.819110000000000000
          Width = 759.685530000000000000
          Color = clBlack
          Frame.Style = fsDash
          Frame.Typ = [ftTop]
        end
      end
    end
  end
  inherited frxpdfxprtPedWeb: TfrxPDFExport
    Left = 376
    Top = 128
  end
  inherited frxlsxprtExcel: TfrxXLSXExport
    Left = 472
    Top = 240
  end
  inherited frxdsgnr1: TfrxDesigner
    Left = 312
    Top = 240
  end
  inherited frxReportOrigen: TfrxReport
    ReportOptions.LastChange = 45037.556420706000000000
    ScriptText.Strings = (
      'begin'
      ''
      'end.')
    Left = 256
    Top = 184
    Datasets = <
      item
        DataSet = dmFacturas.fxdsRecibos
        DataSetName = 'Recibos'
      end>
    Variables = <>
    Style = <>
    inherited Page1: TfrxReportPage
      object MasterData1: TfrxMasterData
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 343.937230000000000000
        Top = 16.000000000000000000
        Width = 755.906000000000000000
        DataSet = dmFacturas.fxdsRecibos
        DataSetName = 'Recibos'
        RowCount = 0
        object Memo10: TfrxMemoView
          AllowVectorExport = True
          Left = 20.236240000000000000
          Top = 59.252010000000000000
          Width = 343.937230000000000000
          Height = 49.133890000000000000
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          ParentFont = False
        end
        object Memo1: TfrxMemoView
          AllowVectorExport = True
          Left = 20.236240000000000000
          Top = 9.897650000000000000
          Width = 158.740260000000000000
          Height = 49.133890000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          ParentFont = False
        end
        object Memo2: TfrxMemoView
          AllowVectorExport = True
          Left = 35.354360000000000000
          Top = 36.354360000000000000
          Width = 124.724490000000000000
          Height = 15.118120000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haCenter
          Memo.UTF8W = (
            
              '[Recibos."DOCUMENTO_FACTURA_FORMATO"]\[IntToStr(<Recibos."NUMERO' +
              '_PLAZO_REC">)]')
          ParentFont = False
          Formats = <
            item
            end
            item
            end
            item
            end>
        end
        object Memo3: TfrxMemoView
          AllowVectorExport = True
          Left = 27.795300000000000000
          Top = 13.677180000000000000
          Width = 113.385900000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'RECIBO NRO')
          ParentFont = False
        end
        object Memo4: TfrxMemoView
          AllowVectorExport = True
          Left = 178.976500000000000000
          Top = 9.897650000000000000
          Width = 321.260050000000000000
          Height = 49.133890000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          ParentFont = False
        end
        object Memo5: TfrxMemoView
          AllowVectorExport = True
          Left = 220.551330000000000000
          Top = 36.354360000000000000
          Width = 226.771800000000000000
          Height = 15.118120000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Recibos."LOCALIDAD_EXPEDICION_RECIBO_REC"]')
          ParentFont = False
        end
        object Memo6: TfrxMemoView
          AllowVectorExport = True
          Left = 190.315090000000000000
          Top = 13.677180000000000000
          Width = 300.000000000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'LOCALIDAD DE EXPEDICIÓN')
          ParentFont = False
        end
        object Memo7: TfrxMemoView
          AllowVectorExport = True
          Left = 500.236550000000000000
          Top = 9.897650000000000000
          Width = 222.992270000000000000
          Height = 49.133890000000000000
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          ParentFont = False
        end
        object Memo8: TfrxMemoView
          AllowVectorExport = True
          Left = 522.913730000000000000
          Top = 13.677180000000000000
          Width = 173.858380000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'IMPORTE RECIBO')
          ParentFont = False
        end
        object Memo12: TfrxMemoView
          AllowVectorExport = True
          Left = 27.795300000000000000
          Top = 66.590600000000000000
          Width = 181.417440000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'FECHA DE EXPEDICIÓN')
          ParentFont = False
        end
        object Memo11: TfrxMemoView
          AllowVectorExport = True
          Left = 364.173470000000000000
          Top = 59.031540000000000000
          Width = 359.055350000000000000
          Height = 49.133890000000000000
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          ParentFont = False
        end
        object Memo13: TfrxMemoView
          AllowVectorExport = True
          Left = 379.291590000000000000
          Top = 66.370130000000000000
          Width = 330.000000000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'FECHA DE VENCIMIENTO')
          ParentFont = False
        end
        object Memo14: TfrxMemoView
          AllowVectorExport = True
          Left = 35.354360000000000000
          Top = 113.385900000000000000
          Width = 79.370130000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            'SON EU:')
          ParentFont = False
        end
        object Memo15: TfrxMemoView
          AllowVectorExport = True
          Left = 20.236240000000000000
          Top = 158.212740000000000000
          Width = 702.992580000000000000
          Height = 30.236240000000000000
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          ParentFont = False
        end
        object Memo16: TfrxMemoView
          AllowVectorExport = True
          Left = 27.795300000000000000
          Top = 162.771800000000000000
          Width = 181.417440000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'PAGADERO EN   <IBAN>  :')
          ParentFont = False
        end
        object Memo18: TfrxMemoView
          AllowVectorExport = True
          Left = 20.236240000000000000
          Top = 195.023810000000000000
          Width = 468.661720000000000000
          Height = 124.724490000000000000
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          ParentFont = False
        end
        object Memo19: TfrxMemoView
          AllowVectorExport = True
          Left = 27.795300000000000000
          Top = 202.362400000000000000
          Width = 370.000000000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'DOMICILIO Y NOMBRE DEL LIBRADO:')
          ParentFont = False
        end
        object FacturasRAZONSOCIAL_CLIENTE: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 27.795300000000000000
          Top = 225.260050000000000000
          Width = 400.630180000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[Recibos."RAZON_SOCIAL_CLI_REC"]')
          ParentFont = False
        end
        object FacturasDIRECCION1_CLIENTE: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 27.795300000000000000
          Top = 247.937230000000000000
          Width = 400.630180000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          Frame.Typ = []
          Memo.UTF8W = (
            '[Recibos."DIRECCION1_CLIENTE_RECIBO_REC"]')
        end
        object FacturasCPOSTAL_CLIENTE: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 27.795300000000000000
          Top = 266.834880000000000000
          Width = 120.944960000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          Frame.Typ = []
          Memo.UTF8W = (
            '[Recibos."CODIGO_POSTAL_CLI_REC"]')
        end
        object FacturasPOBLACION_CLIENTE: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 156.299320000000000000
          Top = 266.834880000000000000
          Width = 272.126160000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          Frame.Typ = []
          Memo.UTF8W = (
            '[Recibos."POBLACION_CLI_REC"]')
        end
        object FacturasPROVINCIA_CLIENTE: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 27.795300000000000000
          Top = 289.512060000000000000
          Width = 328.819110000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Recibos."PROVINCIA_CLI_REC"]')
          ParentFont = False
        end
        object FacturasCODIGO_CLIENTE: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 405.748300000000000000
          Top = 198.803340000000000000
          Width = 79.370130000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Recibos."CODIGO_CLI_REC"]')
          ParentFont = False
        end
        object Memo20: TfrxMemoView
          AllowVectorExport = True
          Left = 506.457020000000000000
          Top = 198.433210000000000000
          Width = 188.976500000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'CONFORME, EL LIBRADO')
          ParentFont = False
        end
        object FacturasIMPORTE_LETRA1: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 120.944960000000000000
          Top = 113.385900000000000000
          Width = 514.016080000000000000
          Height = 37.795300000000000000
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          Frame.Typ = []
          Memo.UTF8W = (
            '[Recibos."IMPORTE_LETRA_RECIBO_REC"]')
        end
        object FacturasIBAN: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 222.992270000000000000
          Top = 162.771800000000000000
          Width = 272.126160000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          Frame.Typ = []
          Memo.UTF8W = (
            '[Recibos."IBAN_CLI_REC"]')
        end
        object FacturasFECHA_EXPEDICION: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 222.992270000000000000
          Top = 81.590600000000000000
          Width = 109.606370000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          DisplayFormat.FormatStr = 'dd/mm/yyyy'
          DisplayFormat.Kind = fkDateTime
          Frame.Typ = []
          Memo.UTF8W = (
            '[Recibos."FECHA_EXPEDICION_RECIBO_REC"]')
        end
        object FacturasFECHA_VENCIMIENTO: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 574.488560000000000000
          Top = 81.590600000000000000
          Width = 102.047310000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          DisplayFormat.FormatStr = 'dd/mm/yyyy'
          DisplayFormat.Kind = fkDateTime
          Frame.Typ = []
          Memo.UTF8W = (
            '[Recibos."FECHA_VENCIMIENTO_RECIBO_REC"]')
        end
        object FacturasEUROS_RECIBO: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 521.575140000000000000
          Top = 32.456710000000000000
          Width = 173.858380000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Recibos."EUROS_RECIBO_REC"]')
          ParentFont = False
        end
        object Line1: TfrxLineView
          AllowVectorExport = True
          Top = 334.819110000000000000
          Width = 759.685530000000000000
          Color = clBlack
          Frame.Style = fsDash
          Frame.Typ = [ftTop]
        end
      end
    end
  end
end
