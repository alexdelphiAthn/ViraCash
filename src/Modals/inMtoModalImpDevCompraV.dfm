inherited frmPrintDevCompraV: TfrmPrintDevCompraV
  Caption = 'Imprimir Devolución de Compra (Vertical)'
  ClientHeight = 220
  ClientWidth = 460
  StyleElements = [seFont, seClient, seBorder]
  ExplicitWidth = 476
  ExplicitHeight = 259
  TextHeight = 19
  inherited pnl1: TPanel
    Left = 320
    Height = 220
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 320
    ExplicitHeight = 220
    inherited btnSalir: TcxButton
      Top = 194
      ExplicitTop = 194
    end
    inherited btnExcel: TcxButton
      OnClick = btnExcelClick
    end
  end
  object lblSerie: TcxLabel [1]
    Left = 16
    Top = 16
    Caption = 'Serie'
    TabOrder = 1
    Transparent = True
  end
  object edtSerie: TcxTextEdit [2]
    Left = 16
    Top = 40
    Enabled = False
    TabOrder = 2
    Width = 121
  end
  object lblNumero: TcxLabel [3]
    Left = 152
    Top = 16
    Caption = 'Número'
    TabOrder = 3
    Transparent = True
  end
  object edtNumero: TcxTextEdit [4]
    Left = 152
    Top = 40
    Enabled = False
    TabOrder = 4
    Width = 121
  end
  inherited frxrprt1: TfrxReport
    ReportOptions.LastChange = 46196.500000000000000000
    ScriptText.Strings = (
      'begin'
      'end.')
    Left = 8
    Top = 184
    Datasets = <
      item
        DataSet = dmDevolucionesCompra.fxdsCabDevc
        DataSetName = 'Devolucion'
      end
      item
        DataSet = dmDevolucionesCompra.fxdsLinDevcSku
        DataSetName = 'LineasDevolucionSku'
      end>
    Variables = <>
    Style = <>
    inherited Page1: TfrxReportPage
      Orientation = poPortrait
      PaperWidth = 210.000000000000000000
      PaperHeight = 297.000000000000000000
      PaperSize = 9
      LeftMargin = 10.000000000000000000
      RightMargin = 10.000000000000000000
      TopMargin = 10.000000000000000000
      BottomMargin = 10.000000000000000000
      Frame.Typ = []
      MirrorMode = []
      object PageHeader1: TfrxPageHeader
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 146.000000000000000000
        Top = 18.897650000000000000
        Width = 718.110700000000000000
        object MemoTituloV: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 0.000000000000000000
          Width = 718.110700000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            'DEVOLUCIÓN A PROVEEDOR')
          ParentFont = False
        end
        object MemoEmpRazonV: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 30.000000000000000000
          Width = 350.000000000000000000
          Height = 18.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsCabDevc
          DataSetName = 'Devolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[Devolucion."NOMBRE_ALM_DEVC"]')
          ParentFont = False
        end
        object MemoEmpDirV: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 48.000000000000000000
          Width = 350.000000000000000000
          Height = 14.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsCabDevc
          DataSetName = 'Devolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Devolucion."DIRECCION_ALM_DEVC"]')
          ParentFont = False
        end
        object MemoEmpCpPobV: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 62.000000000000000000
          Width = 350.000000000000000000
          Height = 14.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsCabDevc
          DataSetName = 'Devolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Devolucion."CODIGO_POSTAL_ALM_DEVC"] [Devolucion."POBLACION' +
              '_ALM_DEVC"][IIF(<Devolucion."PROVINCIA_ALM_DEVC"> <> '#39#39', '#39' (' +
              #39' + <Devolucion."PROVINCIA_ALM_DEVC"> + '#39')'#39', '#39#39')]')
          ParentFont = False
        end
        object MemoEmpCifV: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 76.000000000000000000
          Width = 350.000000000000000000
          Height = 14.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsCabDevc
          DataSetName = 'Devolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[IIF(<Devolucion."TELEFONO_ALM_DEVC"> <> '#39#39', '#39'Tel: '#39' + <Devo' +
              'lucion."TELEFONO_ALM_DEVC"> + '#39'   '#39', '#39#39')][IIF(<Devolucion."E' +
              'MAIL_ALM_DEVC"> <> '#39#39', '#39'Email: '#39' + <Devolucion."EMAIL_ALM_DE' +
              'VC">, '#39#39')]')
          ParentFont = False
        end
        object MemoPrvLblV: TfrxMemoView
          AllowVectorExport = True
          Left = 360.000000000000000000
          Top = 30.000000000000000000
          Width = 358.000000000000000000
          Height = 14.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGray
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'PROVEEDOR')
          ParentFont = False
        end
        object MemoPrvRazonV: TfrxMemoView
          AllowVectorExport = True
          Left = 360.000000000000000000
          Top = 44.000000000000000000
          Width = 358.000000000000000000
          Height = 18.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsCabDevc
          DataSetName = 'Devolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[Devolucion."RAZON_SOCIAL_PRV"]')
          ParentFont = False
        end
        object MemoPrvDirV: TfrxMemoView
          AllowVectorExport = True
          Left = 360.000000000000000000
          Top = 62.000000000000000000
          Width = 358.000000000000000000
          Height = 14.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsCabDevc
          DataSetName = 'Devolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Devolucion."DIRECCION1_PRV"][IIF((<Devolucion."DIRECCION1_P' +
              'RV"> <> '#39#39') and (<Devolucion."POBLACION_PRV"> <> '#39#39'), '#39', '#39', ' +
              #39#39')][Devolucion."POBLACION_PRV"]')
          ParentFont = False
        end
        object MemoPrvCifV: TfrxMemoView
          AllowVectorExport = True
          Left = 360.000000000000000000
          Top = 76.000000000000000000
          Width = 358.000000000000000000
          Height = 14.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsCabDevc
          DataSetName = 'Devolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[IIF(<Devolucion."CIF_PRV"> <> '#39#39', '#39'CIF: '#39' + <Devolucion."CI' +
              'F_PRV">, '#39#39')]')
          ParentFont = False
        end
        object MemoNumeroV: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 92.000000000000000000
          Width = 360.000000000000000000
          Height = 18.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsCabDevc
          DataSetName = 'Devolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            'Devolución: [Devolucion."DOCUMENTO_FORMATO"]')
          ParentFont = False
        end
        object MemoFechaV: TfrxMemoView
          AllowVectorExport = True
          Left = 360.000000000000000000
          Top = 92.000000000000000000
          Width = 358.000000000000000000
          Height = 18.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsCabDevc
          DataSetName = 'Devolucion'
          DisplayFormat.FormatStr = 'dd/mm/yyyy'
          DisplayFormat.Kind = fkDateTime
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            'Fecha: [Devolucion."FECHA_DEVC"]')
          ParentFont = False
        end
        object MemoRefPrvV: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 112.000000000000000000
          Width = 718.000000000000000000
          Height = 32.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsCabDevc
          DataSetName = 'Devolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haLeft
          VAlign = vaCenter
          Memo.UTF8W = (
            'Ref. prov.: [Devolucion."REF_PROVEEDOR_DEVC"]')
          ParentFont = False
        end
      end
      object HeaderLineasV: TfrxHeader
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 20.000000000000000000
        Top = 140.000000000000000000
        Width = 718.110700000000000000
        ReprintOnNewPage = True
        object HdrLineaV: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 0.000000000000000000
          Width = 40.000000000000000000
          Height = 20.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Fill.BackColor = 6710886
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = (
            'Línea')
          ParentFont = False
          WordWrap = False
        end
        object HdrArtV: TfrxMemoView
          AllowVectorExport = True
          Left = 40.000000000000000000
          Top = 0.000000000000000000
          Width = 116.000000000000000000
          Height = 20.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Fill.BackColor = 6710886
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = ('Artículo')
          ParentFont = False
          WordWrap = False
        end
        object HdrSkuV: TfrxMemoView
          AllowVectorExport = True
          Left = 156.000000000000000000
          Top = 0.000000000000000000
          Width = 196.000000000000000000
          Height = 20.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Fill.BackColor = 6710886
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = ('SKU')
          ParentFont = False
          WordWrap = False
        end
        object HdrRefV: TfrxMemoView
          AllowVectorExport = True
          Left = 352.000000000000000000
          Top = 0.000000000000000000
          Width = 66.000000000000000000
          Height = 20.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Fill.BackColor = 6710886
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = ('Ref. prov.')
          ParentFont = False
          WordWrap = False
        end
        object HdrDescV: TfrxMemoView
          AllowVectorExport = True
          Left = 418.000000000000000000
          Top = 0.000000000000000000
          Width = 132.000000000000000000
          Height = 20.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Fill.BackColor = 6710886
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = ('Descripción')
          ParentFont = False
          WordWrap = False
        end
        object HdrCantV: TfrxMemoView
          AllowVectorExport = True
          Left = 550.000000000000000000
          Top = 0.000000000000000000
          Width = 40.000000000000000000
          Height = 20.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Fill.BackColor = 6710886
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = ('Cant.')
          ParentFont = False
          WordWrap = False
        end
        object HdrPrecV: TfrxMemoView
          AllowVectorExport = True
          Left = 590.000000000000000000
          Top = 0.000000000000000000
          Width = 58.000000000000000000
          Height = 20.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Fill.BackColor = 6710886
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = ('Precio')
          ParentFont = False
          WordWrap = False
        end
        object HdrTotV: TfrxMemoView
          AllowVectorExport = True
          Left = 648.000000000000000000
          Top = 0.000000000000000000
          Width = 70.110700000000000000
          Height = 20.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Fill.BackColor = 6710886
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          Memo.UTF8W = ('Total')
          ParentFont = False
          WordWrap = False
        end
      end
      object DataBandLineasV: TfrxMasterData
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 16.000000000000000000
        Top = 180.000000000000000000
        Width = 718.110700000000000000
        DataSet = dmDevolucionesCompra.fxdsLinDevcSku
        DataSetName = 'LineasDevolucionSku'
        RowCount = 0
        Stretched = True
        object LinLineaV: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 0.000000000000000000
          Width = 40.000000000000000000
          Height = 16.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevcSku
          DataSetName = 'LineasDevolucionSku'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          VAlign = vaCenter
          StretchMode = smMaxHeight
          Memo.UTF8W = ('[LineasDevolucionSku."LINEA_DEVCLIN"]')
          ParentFont = False
          WordWrap = False
        end
        object LinArtV: TfrxMemoView
          AllowVectorExport = True
          Left = 40.000000000000000000
          Top = 0.000000000000000000
          Width = 116.000000000000000000
          Height = 16.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevcSku
          DataSetName = 'LineasDevolucionSku'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haLeft
          VAlign = vaCenter
          StretchMode = smMaxHeight
          Memo.UTF8W = ('[LineasDevolucionSku."CODIGO_ART_DEVCLIN"]')
          ParentFont = False
        end
        object LinSkuV: TfrxMemoView
          AllowVectorExport = True
          Left = 156.000000000000000000
          Top = 0.000000000000000000
          Width = 196.000000000000000000
          Height = 16.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevcSku
          DataSetName = 'LineasDevolucionSku'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haLeft
          VAlign = vaCenter
          StretchMode = smMaxHeight
          Memo.UTF8W = ('[LineasDevolucionSku."CODIGO_UNIDAD_DEVCLIN"]')
          ParentFont = False
        end
        object LinRefV: TfrxMemoView
          AllowVectorExport = True
          Left = 352.000000000000000000
          Top = 0.000000000000000000
          Width = 66.000000000000000000
          Height = 16.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevcSku
          DataSetName = 'LineasDevolucionSku'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haLeft
          VAlign = vaCenter
          StretchMode = smMaxHeight
          Memo.UTF8W = ('[LineasDevolucionSku."REF_PRV_DEVCLIN"]')
          ParentFont = False
        end
        object LinDescV: TfrxMemoView
          AllowVectorExport = True
          Left = 418.000000000000000000
          Top = 0.000000000000000000
          Width = 132.000000000000000000
          Height = 16.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevcSku
          DataSetName = 'LineasDevolucionSku'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haLeft
          VAlign = vaCenter
          StretchMode = smMaxHeight
          Memo.UTF8W = ('[LineasDevolucionSku."DESCRIPCION_ARTICULO_DEVCLIN"]')
          ParentFont = False
        end
        object LinCantV: TfrxMemoView
          AllowVectorExport = True
          Left = 550.000000000000000000
          Top = 0.000000000000000000
          Width = 40.000000000000000000
          Height = 16.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevcSku
          DataSetName = 'LineasDevolucionSku'
          DisplayFormat.FormatStr = '#,##0.##'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haRight
          VAlign = vaCenter
          StretchMode = smMaxHeight
          Memo.UTF8W = (
            '[FormatFloat('#39'0.######'#39', <LineasDevolucionSku."CANTIDAD_DEVCLIN">)]')
          ParentFont = False
          WordWrap = False
        end
        object LinPrecV: TfrxMemoView
          AllowVectorExport = True
          Left = 590.000000000000000000
          Top = 0.000000000000000000
          Width = 58.000000000000000000
          Height = 16.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevcSku
          DataSetName = 'LineasDevolucionSku'
          DisplayFormat.FormatStr = '#,##0.00'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haRight
          VAlign = vaCenter
          StretchMode = smMaxHeight
          Memo.UTF8W = ('[LineasDevolucionSku."PRECIO_COMPRA_SIVA_ARTICULO_DEVCLIN"]')
          ParentFont = False
          WordWrap = False
        end
        object LinTotV: TfrxMemoView
          AllowVectorExport = True
          Left = 648.000000000000000000
          Top = 0.000000000000000000
          Width = 70.110700000000000000
          Height = 16.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevcSku
          DataSetName = 'LineasDevolucionSku'
          DisplayFormat.FormatStr = '#,##0.00'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haRight
          VAlign = vaCenter
          StretchMode = smMaxHeight
          Memo.UTF8W = ('[LineasDevolucionSku."TOTAL_DEVCLIN"]')
          ParentFont = False
          WordWrap = False
        end
      end
      object ReportSummaryTotalesFiscales: TfrxReportSummary
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 134.000000000000000000
        Top = 1010.000000000000000000
        Width = 718.110700000000000000
        object MemoTotalesFiscales: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 6.000000000000000000
          Width = 450.000000000000000000
          Height = 120.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Courier New'
          Font.Style = []
          Frame.Typ = [ftTop, ftBottom]
          Memo.UTF8W = (
            'DESGLOSE IVA / RE[IIF((<Devolucion."PORCENTAJE_IVAN_DEVC"> <' +
              '> 0) or (<Devolucion."TOTAL_BASEI_IVAN_DEVC"> <> 0), Chr(13)' +
              ' + Chr(10) + '#39'Normal       Base '#39' + FormatFloat('#39'#,##0.00'#39', ' +
              '<Devolucion."TOTAL_BASEI_IVAN_DEVC">) + '#39'  IVA '#39' + FormatFlo' +
              'at('#39'0.##'#39', <Devolucion."PORCENTAJE_IVAN_DEVC">) + '#39'% '#39' + For' +
              'matFloat('#39'#,##0.00'#39', <Devolucion."TOTAL_IVAN_DEVC">) + IIF(<' +
              'Devolucion."TOTAL_REN_DEVC"> <> 0, '#39'  RE '#39' + FormatFloat('#39'0.' +
              '##'#39', <Devolucion."PORCENTAJE_REN_DEVC">) + '#39'% '#39' + FormatFloa' +
              't('#39'#,##0.00'#39', <Devolucion."TOTAL_REN_DEVC">), '#39#39'), '#39#39')][IIF(' +
              '(<Devolucion."PORCENTAJE_IVAR_DEVC"> <> 0) or (<Devolucion."' +
              'TOTAL_BASEI_IVAR_DEVC"> <> 0), Chr(13) + Chr(10) + '#39'Reducido' +
              '     Base '#39' + FormatFloat('#39'#,##0.00'#39', <Devolucion."TOTAL_BAS' +
              'EI_IVAR_DEVC">) + '#39'  IVA '#39' + FormatFloat('#39'0.##'#39', <Devolucion' +
              '."PORCENTAJE_IVAR_DEVC">) + '#39'% '#39' + FormatFloat('#39'#,##0.00'#39', <' +
              'Devolucion."TOTAL_IVAR_DEVC">) + IIF(<Devolucion."TOTAL_RER_' +
              'DEVC"> <> 0, '#39'  RE '#39' + FormatFloat('#39'0.##'#39', <Devolucion."PORC' +
              'ENTAJE_RER_DEVC">) + '#39'% '#39' + FormatFloat('#39'#,##0.00'#39', <Devoluc' +
              'ion."TOTAL_RER_DEVC">), '#39#39'), '#39#39')][IIF((<Devolucion."PORCENTA' +
              'JE_IVAS_DEVC"> <> 0) or (<Devolucion."TOTAL_BASEI_IVAS_DEVC"' +
              '> <> 0), Chr(13) + Chr(10) + '#39'Super red.   Base '#39' + FormatFl' +
              'oat('#39'#,##0.00'#39', <Devolucion."TOTAL_BASEI_IVAS_DEVC">) + '#39'  I' +
              'VA '#39' + FormatFloat('#39'0.##'#39', <Devolucion."PORCENTAJE_IVAS_DEVC' +
              '">) + '#39'% '#39' + FormatFloat('#39'#,##0.00'#39', <Devolucion."TOTAL_IVAS' +
              '_DEVC">) + IIF(<Devolucion."TOTAL_RES_DEVC"> <> 0, '#39'  RE '#39' +' +
              ' FormatFloat('#39'0.##'#39', <Devolucion."PORCENTAJE_RES_DEVC">) + '#39 +
              '% '#39' + FormatFloat('#39'#,##0.00'#39', <Devolucion."TOTAL_RES_DEVC">)' +
              ', '#39#39'), '#39#39')]'
            'Exento       Base [FormatFloat('#39'#,##0.00'#39', <Devolucion."TOTA' +
              'L_BASEI_IVAE_DEVC">)]  IVA [FormatFloat('#39'0.##'#39', <Devolucion.' +
              '"PORCENTAJE_IVAE_DEVC">)]% [FormatFloat('#39'#,##0.00'#39', <Devoluc' +
              'ion."TOTAL_IVAE_DEVC">)][IIF(<Devolucion."TOTAL_REE_DEVC"> <' +
              '> 0, '#39'  RE '#39' + FormatFloat('#39'0.##'#39', <Devolucion."PORCENTAJE_R' +
              'EE_DEVC">) + '#39'% '#39' + FormatFloat('#39'#,##0.00'#39', <Devolucion."TOT' +
              'AL_REE_DEVC">), '#39#39')]'
            'Base total [FormatFloat('#39'#,##0.00'#39', <Devolucion."TOTAL_BASES' +
              '_DEVC">)]   Impuestos [FormatFloat('#39'#,##0.00'#39', <Devolucion."' +
              'TOTAL_IMPUESTOS_DEVC">)]'
            '[IIF(<Devolucion."TOTAL_RETENCION_DEVC"> <> 0, '#39'Retencion IR' +
              'PF '#39' + FormatFloat('#39'0.##'#39', <Devolucion."PORCENTAJE_RETENCION' +
              '_DEVC">) + '#39'% -'#39' + FormatFloat('#39'#,##0.00'#39', <Devolucion."TOTA' +
              'L_RETENCION_DEVC">), '#39#39')]'
            'TOTAL LIQUIDO [FormatFloat('#39'#,##0.00'#39', <Devolucion."TOTAL_LI' +
              'QUIDO_DEVC">)] EUR')
          ParentFont = False
        end
        object MemoTotBaseLblV: TfrxMemoView
          AllowVectorExport = True
          Left = 470.000000000000000000
          Top = 6.000000000000000000
          Width = 120.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          VAlign = vaCenter
          Memo.UTF8W = (
            'Total bases:')
          ParentFont = False
          WordWrap = False
        end
        object MemoTotBaseV: TfrxMemoView
          AllowVectorExport = True
          Left = 590.000000000000000000
          Top = 6.000000000000000000
          Width = 128.110700000000000000
          Height = 18.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsCabDevc
          DataSetName = 'Devolucion'
          DisplayFormat.FormatStr = '#,##0.00'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          VAlign = vaCenter
          Memo.UTF8W = (
            '[Devolucion."TOTAL_BASES_DEVC"]')
          ParentFont = False
          WordWrap = False
        end
        object MemoTotIvaLblV: TfrxMemoView
          AllowVectorExport = True
          Left = 470.000000000000000000
          Top = 26.000000000000000000
          Width = 120.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          VAlign = vaCenter
          Memo.UTF8W = (
            'Total IVA:')
          ParentFont = False
          WordWrap = False
        end
        object MemoTotIvaV: TfrxMemoView
          AllowVectorExport = True
          Left = 590.000000000000000000
          Top = 26.000000000000000000
          Width = 128.110700000000000000
          Height = 18.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsCabDevc
          DataSetName = 'Devolucion'
          DisplayFormat.FormatStr = '#,##0.00'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          VAlign = vaCenter
          Memo.UTF8W = (
            '[Devolucion."TOTAL_IMPUESTOS_DEVC"]')
          ParentFont = False
          WordWrap = False
        end
        object MemoTotLiqV: TfrxMemoView
          AllowVectorExport = True
          Left = 470.000000000000000000
          Top = 50.000000000000000000
          Width = 248.110700000000000000
          Height = 26.000000000000000000
          DataSet = dmDevolucionesCompra.fxdsCabDevc
          DataSetName = 'Devolucion'
          DisplayFormat.FormatStr = '#,##0.00'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haRight
          VAlign = vaCenter
          Memo.UTF8W = (
            'TOTAL: [Devolucion."TOTAL_LIQUIDO_DEVC"] '#8364)
          ParentFont = False
          WordWrap = False
        end
      end
      object PageFooter1: TfrxPageFooter
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 22.000000000000000000
        Top = 1148.000000000000000000
        Width = 718.110700000000000000
        object MemoPaginaV: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 4.000000000000000000
          Width = 300.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Pág. [Page#] / [TotalPages#] - [Date]')
          ParentFont = False
          WordWrap = False
        end
      end
    end
  end
end
