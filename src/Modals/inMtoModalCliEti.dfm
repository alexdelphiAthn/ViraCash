inherited frmPrintCliEti: TfrmPrintCliEti
  Caption = 'Impresi'#243'n de Etiquetas'
  ClientHeight = 296
  ClientWidth = 389
  StyleElements = [seFont, seClient, seBorder]
  ExplicitWidth = 405
  ExplicitHeight = 335
  TextHeight = 19
  inherited pnl1: TPanel
    Left = 245
    Height = 296
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 243
    ExplicitHeight = 288
    inherited btnSalir: TcxButton
      Top = 270
      ExplicitTop = 262
    end
  end
  object cxRadioGroup1: TcxRadioGroup [1]
    Left = 8
    Top = 136
    Caption = 'Opciones'
    Properties.Items = <>
    TabOrder = 1
    Height = 137
    Width = 219
    object cxlbl2: TcxLabel
      Left = 16
      Top = 22
      Caption = 'Dejar espacios en blanco antes de imprimir etiqueta'
      Properties.WordWrap = True
      TabOrder = 0
      Width = 154
      Transparent = True
    end
  end
  object speDejarBlancos: TcxSpinEdit [2]
    Left = 24
    Top = 225
    TabOrder = 2
    Width = 121
  end
  object edtCodCli: TcxTextEdit [3]
    Left = 106
    Top = 71
    TabOrder = 3
    Width = 121
  end
  object cxLabel1: TcxLabel [4]
    Left = 21
    Top = 48
    Caption = 'C'#243'digo de Cliente: '
    TabOrder = 4
    Transparent = True
  end
  inherited frxrprt1: TfrxReport
    Left = 8
    Top = 256
    Datasets = <>
    Variables = <>
    Style = <>
  end
  inherited frxlsxprtExcel: TfrxXLSXExport
    Left = 160
    Top = 256
  end
  inherited frxReportOrigen: TfrxReport
    ReportOptions.Author = ''
    ReportOptions.LastChange = 45280.511098078700000000
    ScriptText.Strings = (
      'begin'
      'end.')
    Left = 64
    Top = 256
    Datasets = <
      item
        DataSet = dmClientes.fxdsEtiquetas
        DataSetName = 'Etiquetas'
      end>
    Variables = <>
    Style = <>
    inherited Page1: TfrxReportPage
      LeftMargin = 0.000000000000000000
      RightMargin = 0.000000000000000000
      TopMargin = 3.400000000000000000
      BottomMargin = 3.400000000000000000
      Columns = 2
      ColumnWidth = 105.000000000000000000
      ColumnPositions.Strings = (
        '0'
        '105')
      object MasterData1: TfrxMasterData
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 109.606299210000000000
        Top = 18.897650000000000000
        Width = 396.850650000000000000
        DataSet = dmClientes.fxdsEtiquetas
        DataSetName = 'Etiquetas'
        RowCount = 0
        object FacturasRAZONSOCIAL_CLIENTE: TfrxMemoView
          AllowVectorExport = True
          Left = 26.456710000000000000
          Top = 15.118120000000000000
          Width = 362.834880000000000000
          Height = 18.897650000000000000
          DataField = 'RAZON_SOCIAL_CLI'
          DataSet = dmClientes.fxdsEtiquetas
          DataSetName = 'Etiquetas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Etiquetas."RAZON_SOCIAL_CLI"]')
          ParentFont = False
        end
        object FacturasDIRECCION1_CLIENTE_FACTURA: TfrxMemoView
          AllowVectorExport = True
          Left = 26.456710000000000000
          Top = 35.015770000000000000
          Width = 366.614410000000000000
          Height = 18.897650000000000000
          DataField = 'DIRECCION1_CLI'
          DataSet = dmClientes.fxdsEtiquetas
          DataSetName = 'Etiquetas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Etiquetas."DIRECCION1_CLI"]')
          ParentFont = False
        end
        object FacturasCPOSTAL_CLIENTE_FACTURA: TfrxMemoView
          AllowVectorExport = True
          Left = 26.456710000000000000
          Top = 53.913420000000000000
          Width = 79.370130000000000000
          Height = 18.897650000000000000
          DataField = 'CODIGO_POSTAL_CLI'
          DataSet = dmClientes.fxdsEtiquetas
          DataSetName = 'Etiquetas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Etiquetas."CODIGO_POSTAL_CLI"]')
          ParentFont = False
        end
        object POBLACION_CLIENTE_FAC: TfrxMemoView
          AllowVectorExport = True
          Left = 79.149660000000000000
          Top = 53.913420000000000000
          Width = 279.685220000000000000
          Height = 18.897650000000000000
          DataField = 'POBLACION_CLI'
          DataSet = dmClientes.fxdsEtiquetas
          DataSetName = 'Etiquetas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Etiquetas."POBLACION_CLI"]')
          ParentFont = False
        end
        object PROVINCIA_CLI: TfrxMemoView
          AllowVectorExport = True
          Left = 26.456710000000000000
          Top = 76.590600000000000000
          Width = 366.614410000000000000
          Height = 18.897650000000000000
          DataField = 'PROVINCIA_CLI'
          DataSet = dmClientes.fxdsEtiquetas
          DataSetName = 'Etiquetas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Etiquetas."PROVINCIA_CLI"]')
          ParentFont = False
        end
      end
    end
  end
end
