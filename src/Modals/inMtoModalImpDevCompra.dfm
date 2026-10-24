inherited frmPrintDevCompra: TfrmPrintDevCompra
  Caption = 'Imprimir Devolución de Compra'
  ClientHeight = 220
  ClientWidth = 460
  StyleElements = [seFont, seClient, seBorder]
  ExplicitWidth = 476
  ExplicitHeight = 259
  TextHeight = 17
  inherited pnl1: TPanel
    Left = 316
    Height = 220
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 314
    ExplicitHeight = 212
    inherited btnSalir: TcxButton
      Top = 194
      ExplicitTop = 186
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
        DataSet = dmDevolucionesCompra.fxdsLinDevc
        DataSetName = 'LineasDevolucion'
      end
      item
        DataSet = dmComprasSesiones.fxdsGuiasSesion
        DataSetName = 'GuiasTallas'
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
      object PageHeader1: TfrxPageHeader
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 132.283464570000000000
        Top = 18.897650000000000000
        Width = 1046.929810000000000000
        object MemoTitulo: TfrxMemoView
          AllowVectorExport = True
          Width = 1046.929500000000000000
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
        object MemoEmpLbl: TfrxMemoView
          AllowVectorExport = True
          Top = 30.236240000000000000
          Width = 340.157700000000000000
          Height = 15.118120000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGray
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'ALMACÉN SALIDA')
          ParentFont = False
        end
        object MemoEmpRazon: TfrxMemoView
          AllowVectorExport = True
          Top = 45.354360000000000000
          Width = 340.157700000000000000
          Height = 18.897650000000000000
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
        object MemoEmpDir: TfrxMemoView
          AllowVectorExport = True
          Top = 64.252010000000000000
          Width = 340.157700000000000000
          Height = 15.118120000000000000
          DataSet = dmDevolucionesCompra.fxdsCabDevc
          DataSetName = 'Devolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Devolucion."DIRECCION_ALM_DEVC"]')
          ParentFont = False
        end
        object MemoEmpCpPob: TfrxMemoView
          AllowVectorExport = True
          Top = 79.370130000000000000
          Width = 340.157700000000000000
          Height = 15.118120000000000000
          DataSet = dmDevolucionesCompra.fxdsCabDevc
          DataSetName = 'Devolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Devolucion."CODIGO_POSTAL_ALM_DEVC"] [Devolucion."POBLACION' +
              '_ALM_DEVC"][IIF(<Devolucion."PROVINCIA_ALM_DEVC"> <> '#39#39', '#39' (' +
              #39' + <Devolucion."PROVINCIA_ALM_DEVC"> + '#39')'#39', '#39#39')]')
          ParentFont = False
        end
        object MemoEmpCif: TfrxMemoView
          AllowVectorExport = True
          Top = 94.488250000000000000
          Width = 340.157700000000000000
          Height = 15.118120000000000000
          DataSet = dmDevolucionesCompra.fxdsCabDevc
          DataSetName = 'Devolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
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
        object MemoPrvLbl: TfrxMemoView
          AllowVectorExport = True
          Left = 355.275820000000000000
          Top = 30.236240000000000000
          Width = 340.157700000000000000
          Height = 15.118120000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGray
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'PROVEEDOR')
          ParentFont = False
        end
        object MemoPrvRazon: TfrxMemoView
          AllowVectorExport = True
          Left = 355.275820000000000000
          Top = 45.354360000000000000
          Width = 340.157700000000000000
          Height = 18.897650000000000000
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
        object MemoPrvDir: TfrxMemoView
          AllowVectorExport = True
          Left = 355.275820000000000000
          Top = 64.252010000000000000
          Width = 340.157700000000000000
          Height = 15.118120000000000000
          DataSet = dmDevolucionesCompra.fxdsCabDevc
          DataSetName = 'Devolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Devolucion."DIRECCION1_PRV"]')
          ParentFont = False
        end
        object MemoPrvCpPob: TfrxMemoView
          AllowVectorExport = True
          Left = 355.275820000000000000
          Top = 79.370130000000000000
          Width = 340.157700000000000000
          Height = 15.118120000000000000
          DataSet = dmDevolucionesCompra.fxdsCabDevc
          DataSetName = 'Devolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Devolucion."CODIGO_POSTAL_PRV"] [Devolucion."POBLACION_PRV"' +
              '][IIF(<Devolucion."PROVINCIA_PRV"> <> '#39#39', '#39' ('#39' + <Devolucion' +
              '."PROVINCIA_PRV"> + '#39')'#39', '#39#39')]')
          ParentFont = False
        end
        object MemoPrvCif: TfrxMemoView
          AllowVectorExport = True
          Left = 355.275820000000000000
          Top = 94.488250000000000000
          Width = 340.157700000000000000
          Height = 15.118120000000000000
          DataSet = dmDevolucionesCompra.fxdsCabDevc
          DataSetName = 'Devolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[IIF(<Devolucion."CIF_PRV"> <> '#39#39', '#39'CIF: '#39' + <Devolucion."CI' +
              'F_PRV"> + '#39'   '#39', '#39#39')][IIF(<Devolucion."TELEFONO1_PRV"> <> '#39#39 +
              ', '#39'Tel: '#39' + <Devolucion."TELEFONO1_PRV">, '#39#39')]')
          ParentFont = False
        end
        object MemoSesLbl: TfrxMemoView
          AllowVectorExport = True
          Left = 710.551640000000000000
          Top = 30.236240000000000000
          Width = 336.378170000000000000
          Height = 15.118120000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGray
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'DEVOLUCIÓN')
          ParentFont = False
        end
        object MemoSesNumero: TfrxMemoView
          AllowVectorExport = True
          Left = 710.551640000000000000
          Top = 45.354360000000000000
          Width = 336.378170000000000000
          Height = 22.677180000000000000
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
            '[Devolucion."DOCUMENTO_FORMATO"]')
          ParentFont = False
        end
        object MemoSesFechaLbl: TfrxMemoView
          AllowVectorExport = True
          Left = 710.551640000000000000
          Top = 71.811070000000000000
          Width = 100.157700000000000000
          Height = 15.118120000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGray
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Fecha')
          ParentFont = False
        end
        object MemoSesFecha: TfrxMemoView
          AllowVectorExport = True
          Left = 813.543600000000000000
          Top = 71.811070000000000000
          Width = 233.386210000000000000
          Height = 15.118120000000000000
          DataSet = dmDevolucionesCompra.fxdsCabDevc
          DataSetName = 'Devolucion'
          DisplayFormat.FormatStr = 'dd/mm/yyyy'
          DisplayFormat.Kind = fkDateTime
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Devolucion."FECHA_DEVC"]')
          ParentFont = False
        end
        object MemoSesEstadoLbl: TfrxMemoView
          AllowVectorExport = True
          Left = 710.551640000000000000
          Top = 86.929190000000000000
          Width = 100.157700000000000000
          Height = 15.118120000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGray
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Estado')
          ParentFont = False
        end
        object MemoSesEstado: TfrxMemoView
          AllowVectorExport = True
          Left = 813.543600000000000000
          Top = 86.929190000000000000
          Width = 233.386210000000000000
          Height = 15.118120000000000000
          DataSet = dmDevolucionesCompra.fxdsCabDevc
          DataSetName = 'Devolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Devolucion."ESTADO_DEVC"]')
          ParentFont = False
        end
        object MemoSesRefPrvLbl: TfrxMemoView
          AllowVectorExport = True
          Left = 710.551640000000000000
          Top = 102.047310000000000000
          Width = 100.157700000000000000
          Height = 15.118120000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGray
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Ref. Prov.')
          ParentFont = False
        end
        object MemoSesRefPrv: TfrxMemoView
          AllowVectorExport = True
          Left = 813.543600000000000000
          Top = 102.047310000000000000
          Width = 233.386210000000000000
          Height = 15.118120000000000000
          DataSet = dmDevolucionesCompra.fxdsCabDevc
          DataSetName = 'Devolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Devolucion."REF_PROVEEDOR_DEVC"]')
          ParentFont = False
        end
        object MemoGuiaTitulo: TfrxMemoView
          AllowVectorExport = True
          Top = 117.165430000000000000
          Width = 1046.929500000000000000
          Height = 15.118120000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Fill.BackColor = 6710886
          HAlign = haCenter
          Memo.UTF8W = (
            'GUÍAS DE TALLAS')
          ParentFont = False
        end
      end
      object DataBandGuias: TfrxMasterData
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 18.897650000000000000
        Top = 211.653680000000000000
        Width = 1046.929810000000000000
        DataSet = dmComprasSesiones.fxdsGuiasSesion
        DataSetName = 'GuiasTallas'
        RowCount = 0
        object GuiaSistema: TfrxMemoView
          AllowVectorExport = True
          Width = 60.000000000000000000
          Height = 18.897650000000000000
          DataSet = dmComprasSesiones.fxdsGuiasSesion
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."NOMBRE_CORTO_AC"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaNombre: TfrxMemoView
          AllowVectorExport = True
          Left = 60.000000000000000000
          Width = 344.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmComprasSesiones.fxdsGuiasSesion
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Memo.UTF8W = (
            '[GuiasTallas."NOMBRE_AC"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT01: TfrxMemoView
          AllowVectorExport = True
          Left = 404.500000000000000000
          Width = 25.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmComprasSesiones.fxdsGuiasSesion
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T01"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT02: TfrxMemoView
          AllowVectorExport = True
          Left = 430.000000000000000000
          Width = 25.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmComprasSesiones.fxdsGuiasSesion
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T02"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT03: TfrxMemoView
          AllowVectorExport = True
          Left = 455.500000000000000000
          Width = 25.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmComprasSesiones.fxdsGuiasSesion
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T03"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT04: TfrxMemoView
          AllowVectorExport = True
          Left = 481.000000000000000000
          Width = 25.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmComprasSesiones.fxdsGuiasSesion
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T04"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT05: TfrxMemoView
          AllowVectorExport = True
          Left = 506.500000000000000000
          Width = 25.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmComprasSesiones.fxdsGuiasSesion
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T05"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT06: TfrxMemoView
          AllowVectorExport = True
          Left = 532.000000000000000000
          Width = 25.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmComprasSesiones.fxdsGuiasSesion
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T06"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT07: TfrxMemoView
          AllowVectorExport = True
          Left = 557.500000000000000000
          Width = 25.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmComprasSesiones.fxdsGuiasSesion
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T07"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT08: TfrxMemoView
          AllowVectorExport = True
          Left = 583.000000000000000000
          Width = 25.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmComprasSesiones.fxdsGuiasSesion
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T08"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT09: TfrxMemoView
          AllowVectorExport = True
          Left = 608.500000000000000000
          Width = 25.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmComprasSesiones.fxdsGuiasSesion
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T09"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT10: TfrxMemoView
          AllowVectorExport = True
          Left = 634.000000000000000000
          Width = 25.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmComprasSesiones.fxdsGuiasSesion
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T10"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT11: TfrxMemoView
          AllowVectorExport = True
          Left = 659.500000000000000000
          Width = 25.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmComprasSesiones.fxdsGuiasSesion
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T11"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT12: TfrxMemoView
          AllowVectorExport = True
          Left = 685.000000000000000000
          Width = 25.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmComprasSesiones.fxdsGuiasSesion
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T12"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT13: TfrxMemoView
          AllowVectorExport = True
          Left = 710.500000000000000000
          Width = 25.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmComprasSesiones.fxdsGuiasSesion
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T13"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT14: TfrxMemoView
          AllowVectorExport = True
          Left = 736.000000000000000000
          Width = 25.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmComprasSesiones.fxdsGuiasSesion
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T14"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT15: TfrxMemoView
          AllowVectorExport = True
          Left = 761.500000000000000000
          Width = 25.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmComprasSesiones.fxdsGuiasSesion
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T15"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT16: TfrxMemoView
          AllowVectorExport = True
          Left = 787.000000000000000000
          Width = 25.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmComprasSesiones.fxdsGuiasSesion
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T16"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT17: TfrxMemoView
          AllowVectorExport = True
          Left = 812.500000000000000000
          Width = 25.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmComprasSesiones.fxdsGuiasSesion
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T17"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT18: TfrxMemoView
          AllowVectorExport = True
          Left = 838.000000000000000000
          Width = 25.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmComprasSesiones.fxdsGuiasSesion
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T18"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT19: TfrxMemoView
          AllowVectorExport = True
          Left = 863.500000000000000000
          Width = 25.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmComprasSesiones.fxdsGuiasSesion
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T19"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT20: TfrxMemoView
          AllowVectorExport = True
          Left = 889.000000000000000000
          Width = 25.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmComprasSesiones.fxdsGuiasSesion
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T20"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object GuiaT21: TfrxMemoView
          AllowVectorExport = True
          Left = 914.500000000000000000
          Width = 25.500000000000000000
          Height = 18.897650000000000000
          DataSet = dmComprasSesiones.fxdsGuiasSesion
          DataSetName = 'GuiasTallas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[GuiasTallas."T21"]')
          ParentFont = False
          VAlign = vaCenter
        end
      end
      object HeaderLineas: TfrxHeader
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 22.677180000000000000
        Top = 253.228510000000000000
        Width = 1046.929810000000000000
        object HdrCodArt: TfrxMemoView
          AllowVectorExport = True
          Width = 108.500000000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Fill.BackColor = 6710886
          HAlign = haCenter
          Memo.UTF8W = (
            'Cód. Art.')
          ParentFont = False
          VAlign = vaCenter
          Left = 0.000000000000000000
        end
        object HdrModelo: TfrxMemoView
          AllowVectorExport = True
          Left = 108.500000000000000000
          Width = 66.000000000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Fill.BackColor = 6710886
          HAlign = haCenter
          Memo.UTF8W = (
            'Modelo')
          ParentFont = False
          VAlign = vaCenter
        end
        object HdrDescr: TfrxMemoView
          AllowVectorExport = True
          Left = 174.500000000000000000
          Width = 96.000000000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Fill.BackColor = 6710886
          HAlign = haCenter
          Memo.UTF8W = (
            'Descripción')
          ParentFont = False
          VAlign = vaCenter
        end
        object HdrColor: TfrxMemoView
          AllowVectorExport = True
          Left = 270.500000000000000000
          Width = 88.000000000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Fill.BackColor = 6710886
          HAlign = haCenter
          Memo.UTF8W = (
            'Color')
          ParentFont = False
          VAlign = vaCenter
        end
        object HdrSistema: TfrxMemoView
          AllowVectorExport = True
          Left = 358.500000000000000000
          Width = 46.000000000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Fill.BackColor = 6710886
          HAlign = haCenter
          Memo.UTF8W = (
            'Sis.')
          ParentFont = False
          VAlign = vaCenter
          WordWrap = False
        end
        object HdrTallasBlock: TfrxMemoView
          AllowVectorExport = True
          Left = 404.500000000000000000
          Width = 535.500000000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Fill.BackColor = 6710886
          HAlign = haCenter
          Memo.UTF8W = (
            'Cantidades por talla (T01..T21 - ver guías arriba)')
          ParentFont = False
          VAlign = vaCenter
        end
        object HdrTotal: TfrxMemoView
          AllowVectorExport = True
          Left = 940.000000000000000000
          Width = 45.000000000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Fill.BackColor = 6710886
          HAlign = haCenter
          Memo.UTF8W = (
            'Uds.')
          ParentFont = False
          VAlign = vaCenter
        end
        object HdrImporte: TfrxMemoView
          AllowVectorExport = True
          Left = 985.000000000000000000
          Width = 61.929500000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Fill.BackColor = 6710886
          HAlign = haCenter
          Memo.UTF8W = (
            'Importe')
          ParentFont = False
          VAlign = vaCenter
        end
      end
      object DataBandLineas: TfrxMasterData
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 22.677180000000000000
        Top = 298.582870000000000000
        Width = 1046.929810000000000000
        DataSet = dmDevolucionesCompra.fxdsLinDevc
        DataSetName = 'LineasDevolucion'
        RowCount = 0
        object LinCodArt: TfrxMemoView
          AllowVectorExport = True
          Width = 108.500000000000000000
          Height = 22.677180000000000000
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          DataSet = dmDevolucionesCompra.fxdsLinDevc
          DataSetName = 'LineasDevolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Memo.UTF8W = (
            '[LineasDevolucion."CODIGO_ART"]')
          ParentFont = False
          VAlign = vaCenter
          Left = 0.000000000000000000
        end
        object LinModelo: TfrxMemoView
          AllowVectorExport = True
          Left = 108.500000000000000000
          Width = 66.000000000000000000
          Height = 22.677180000000000000
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          DataSet = dmDevolucionesCompra.fxdsLinDevc
          DataSetName = 'LineasDevolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Memo.UTF8W = (
            '[LineasDevolucion."REF_PRV"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinDescr: TfrxMemoView
          AllowVectorExport = True
          Left = 174.500000000000000000
          Width = 96.000000000000000000
          Height = 22.677180000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevc
          DataSetName = 'LineasDevolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Memo.UTF8W = (
            '[LineasDevolucion."DESCRIPCION"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinColor: TfrxMemoView
          AllowVectorExport = True
          Left = 270.500000000000000000
          Width = 88.000000000000000000
          Height = 22.677180000000000000
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          DataSet = dmDevolucionesCompra.fxdsLinDevc
          DataSetName = 'LineasDevolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Memo.UTF8W = (
            '[LineasDevolucion."COLOR_TEXTO"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinSistema: TfrxMemoView
          AllowVectorExport = True
          Left = 358.500000000000000000
          Width = 46.000000000000000000
          Height = 22.677180000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevc
          DataSetName = 'LineasDevolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[LineasDevolucion."NOMBRE_CORTO_AC"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT01: TfrxMemoView
          AllowVectorExport = True
          Left = 404.500000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevc
          DataSetName = 'LineasDevolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasDevolucion."T01"> > 0, FormatFloat('#39'0'#39', <LineasDevolucion.' +
              '"T01">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT02: TfrxMemoView
          AllowVectorExport = True
          Left = 430.000000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevc
          DataSetName = 'LineasDevolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasDevolucion."T02"> > 0, FormatFloat('#39'0'#39', <LineasDevolucion.' +
              '"T02">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT03: TfrxMemoView
          AllowVectorExport = True
          Left = 455.500000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevc
          DataSetName = 'LineasDevolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasDevolucion."T03"> > 0, FormatFloat('#39'0'#39', <LineasDevolucion.' +
              '"T03">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT04: TfrxMemoView
          AllowVectorExport = True
          Left = 481.000000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevc
          DataSetName = 'LineasDevolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasDevolucion."T04"> > 0, FormatFloat('#39'0'#39', <LineasDevolucion.' +
              '"T04">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT05: TfrxMemoView
          AllowVectorExport = True
          Left = 506.500000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevc
          DataSetName = 'LineasDevolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasDevolucion."T05"> > 0, FormatFloat('#39'0'#39', <LineasDevolucion.' +
              '"T05">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT06: TfrxMemoView
          AllowVectorExport = True
          Left = 532.000000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevc
          DataSetName = 'LineasDevolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasDevolucion."T06"> > 0, FormatFloat('#39'0'#39', <LineasDevolucion.' +
              '"T06">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT07: TfrxMemoView
          AllowVectorExport = True
          Left = 557.500000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevc
          DataSetName = 'LineasDevolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasDevolucion."T07"> > 0, FormatFloat('#39'0'#39', <LineasDevolucion.' +
              '"T07">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT08: TfrxMemoView
          AllowVectorExport = True
          Left = 583.000000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevc
          DataSetName = 'LineasDevolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasDevolucion."T08"> > 0, FormatFloat('#39'0'#39', <LineasDevolucion.' +
              '"T08">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT09: TfrxMemoView
          AllowVectorExport = True
          Left = 608.500000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevc
          DataSetName = 'LineasDevolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasDevolucion."T09"> > 0, FormatFloat('#39'0'#39', <LineasDevolucion.' +
              '"T09">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT10: TfrxMemoView
          AllowVectorExport = True
          Left = 634.000000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevc
          DataSetName = 'LineasDevolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasDevolucion."T10"> > 0, FormatFloat('#39'0'#39', <LineasDevolucion.' +
              '"T10">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT11: TfrxMemoView
          AllowVectorExport = True
          Left = 659.500000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevc
          DataSetName = 'LineasDevolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasDevolucion."T11"> > 0, FormatFloat('#39'0'#39', <LineasDevolucion.' +
              '"T11">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT12: TfrxMemoView
          AllowVectorExport = True
          Left = 685.000000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevc
          DataSetName = 'LineasDevolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasDevolucion."T12"> > 0, FormatFloat('#39'0'#39', <LineasDevolucion.' +
              '"T12">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT13: TfrxMemoView
          AllowVectorExport = True
          Left = 710.500000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevc
          DataSetName = 'LineasDevolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasDevolucion."T13"> > 0, FormatFloat('#39'0'#39', <LineasDevolucion.' +
              '"T13">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT14: TfrxMemoView
          AllowVectorExport = True
          Left = 736.000000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevc
          DataSetName = 'LineasDevolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasDevolucion."T14"> > 0, FormatFloat('#39'0'#39', <LineasDevolucion.' +
              '"T14">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT15: TfrxMemoView
          AllowVectorExport = True
          Left = 761.500000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevc
          DataSetName = 'LineasDevolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasDevolucion."T15"> > 0, FormatFloat('#39'0'#39', <LineasDevolucion.' +
              '"T15">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT16: TfrxMemoView
          AllowVectorExport = True
          Left = 787.000000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevc
          DataSetName = 'LineasDevolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasDevolucion."T16"> > 0, FormatFloat('#39'0'#39', <LineasDevolucion.' +
              '"T16">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT17: TfrxMemoView
          AllowVectorExport = True
          Left = 812.500000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevc
          DataSetName = 'LineasDevolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasDevolucion."T17"> > 0, FormatFloat('#39'0'#39', <LineasDevolucion.' +
              '"T17">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT18: TfrxMemoView
          AllowVectorExport = True
          Left = 838.000000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevc
          DataSetName = 'LineasDevolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasDevolucion."T18"> > 0, FormatFloat('#39'0'#39', <LineasDevolucion.' +
              '"T18">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT19: TfrxMemoView
          AllowVectorExport = True
          Left = 863.500000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevc
          DataSetName = 'LineasDevolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasDevolucion."T19"> > 0, FormatFloat('#39'0'#39', <LineasDevolucion.' +
              '"T19">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT20: TfrxMemoView
          AllowVectorExport = True
          Left = 889.000000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevc
          DataSetName = 'LineasDevolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasDevolucion."T20"> > 0, FormatFloat('#39'0'#39', <LineasDevolucion.' +
              '"T20">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT21: TfrxMemoView
          AllowVectorExport = True
          Left = 914.500000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevc
          DataSetName = 'LineasDevolucion'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasDevolucion."T21"> > 0, FormatFloat('#39'0'#39', <LineasDevolucion.' +
              '"T21">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinTotalUds: TfrxMemoView
          AllowVectorExport = True
          Left = 940.000000000000000000
          Width = 45.000000000000000000
          Height = 22.677180000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevc
          DataSetName = 'LineasDevolucion'
          DisplayFormat.FormatStr = '%2.0n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[LineasDevolucion."TOTAL_UNIDADES"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinImporte: TfrxMemoView
          AllowVectorExport = True
          Left = 985.000000000000000000
          Width = 61.929500000000000000
          Height = 22.677180000000000000
          DataSet = dmDevolucionesCompra.fxdsLinDevc
          DataSetName = 'LineasDevolucion'
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[LineasDevolucion."TOTAL_LINEA"]')
          ParentFont = False
          VAlign = vaCenter
        end
      end
      object ReportSummaryTotalesFiscales: TfrxReportSummary
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 120.944960000000000000
        Top = 381.732530000000000000
        Width = 1046.929810000000000000
        object MemoTotalesFiscales: TfrxMemoView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 7.559060000000000000
          Width = 1046.929500000000000000
          Height = 105.826840000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
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
      end
      object PageFooter1: TfrxPageFooter
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 26.456710000000000000
        Top = 506.457020000000000000
        Width = 1046.929810000000000000
        object MemoTotalUds: TfrxMemoView
          AllowVectorExport = True
          Left = 700.000000000000000000
          Top = 3.779530000000000000
          Width = 240.000000000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            'TOTAL: [Devolucion."TOTAL_UNIDADES_SES"] unidades')
          ParentFont = False
          VAlign = vaCenter
        end
        object MemoTotalImporte: TfrxMemoView
          AllowVectorExport = True
          Left = 940.000000000000000000
          Top = 3.779530000000000000
          Width = 106.929500000000000000
          Height = 18.897650000000000000
          DataSet = dmDevolucionesCompra.fxdsCabDevc
          DataSetName = 'Devolucion'
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[Devolucion."TOTAL_LINEAS_SES"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object MemoPagina: TfrxMemoView
          AllowVectorExport = True
          Top = 3.779530000000000000
          Width = 300.000000000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGray
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Pág. [Page#] / [TotalPages#] - [Date]')
          ParentFont = False
        end
      end
    end
  end
  inherited frxpdfxprtPedWeb: TfrxPDFExport
    Left = 80
    Top = 184
  end
  inherited frxlsxprtExcel: TfrxXLSXExport
    Left = 152
    Top = 184
  end
  inherited frxdsgnr1: TfrxDesigner
    DefaultOrientation = poLandscape
    Left = 288
    Top = 184
  end
  inherited frxReportOrigen: TfrxReport
    ReportOptions.Author = ''
    ReportOptions.LastChange = 46196.500000000000000000
    ScriptText.Strings = (
      'begin'
      'end.')
    Left = 376
    Top = 184
    Datasets = <
      item
        DataSet = dmDevolucionesCompra.fxdsCabDevc
        DataSetName = 'Devolucion'
      end
      item
        DataSet = dmDevolucionesCompra.fxdsLinDevc
        DataSetName = 'LineasDevolucion'
      end
      item
        DataSet = dmComprasSesiones.fxdsGuiasSesion
        DataSetName = 'GuiasTallas'
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
end
