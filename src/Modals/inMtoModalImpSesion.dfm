inherited frmPrintSesion: TfrmPrintSesion
  Caption = 'Imprimir Sesión de Compra'
  ClientHeight = 249
  ClientWidth = 460
  StyleElements = [seFont, seClient, seBorder]
  ExplicitWidth = 476
  ExplicitHeight = 288
  TextHeight = 17
  inherited pnl1: TPanel
    Left = 316
    Height = 249
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 314
    ExplicitHeight = 241
    inherited btnSalir: TcxButton
      Top = 223
      ExplicitTop = 215
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
        DataSet = dmComprasSesiones.fxdsCabSesion
        DataSetName = 'Sesiones'
      end
      item
        DataSet = dmComprasSesiones.fxdsLinSesion
        DataSetName = 'LineasSesiones'
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
      PaperSize = 256
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
            'SESIÓN DE COMPRA')
          ParentFont = False
        end
        object MemoEmpLbl: TfrxMemoView
          AllowVectorExport = True
          Top = 27.236240000000000000
          Width = 340.157700000000000000
          Height = 15.118120000000000000
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGray
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'EMPRESA')
          ParentFont = False
        end
        object MemoEmpRazon: TfrxMemoView
          AllowVectorExport = True
          Top = 45.354360000000000000
          Width = 340.157700000000000000
          Height = 18.897650000000000000
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          DataSet = dmComprasSesiones.fxdsCabSesion
          DataSetName = 'Sesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[Sesiones."RAZON_SOCIAL_EMP"]')
          ParentFont = False
        end
        object MemoEmpDir: TfrxMemoView
          AllowVectorExport = True
          Top = 64.252010000000000000
          Width = 340.157700000000000000
          Height = 15.118120000000000000
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          DataSet = dmComprasSesiones.fxdsCabSesion
          DataSetName = 'Sesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Sesiones."DIRECCION1_EMP"]')
          ParentFont = False
        end
        object MemoEmpCpPob: TfrxMemoView
          AllowVectorExport = True
          Top = 79.370130000000000000
          Width = 340.157700000000000000
          Height = 15.118120000000000000
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          DataSet = dmComprasSesiones.fxdsCabSesion
          DataSetName = 'Sesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Sesiones."CODIGO_POSTAL_EMP"] [Sesiones."POBLACION_EMP"][II' +
              'F(<Sesiones."PROVINCIA_EMP"> <> '#39#39', '#39' ('#39' + <Sesiones."PROVIN' +
              'CIA_EMP"> + '#39')'#39', '#39#39')]')
          ParentFont = False
        end
        object MemoEmpCif: TfrxMemoView
          AllowVectorExport = True
          Top = 94.488250000000000000
          Width = 340.157700000000000000
          Height = 15.118120000000000000
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          DataSet = dmComprasSesiones.fxdsCabSesion
          DataSetName = 'Sesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[IIF(<Sesiones."CIF_EMP"> <> '#39#39', '#39'CIF: '#39' + <Sesiones."CIF_EM' +
              'P"> + '#39'   '#39', '#39#39')][IIF(<Sesiones."TELEFONO1_EMP"> <> '#39#39', '#39'Tel' +
              ': '#39' + <Sesiones."TELEFONO1_EMP">, '#39#39')]')
          ParentFont = False
        end
        object MemoPrvLbl: TfrxMemoView
          AllowVectorExport = True
          Left = 355.275820000000000000
          Top = 27.236240000000000000
          Width = 340.157700000000000000
          Height = 15.118120000000000000
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGray
          Font.Height = -13
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
          DataSet = dmComprasSesiones.fxdsCabSesion
          DataSetName = 'Sesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[Sesiones."RAZON_SOCIAL_PRV"]')
          ParentFont = False
        end
        object MemoPrvDir: TfrxMemoView
          AllowVectorExport = True
          Left = 355.275820000000000000
          Top = 64.252010000000000000
          Width = 340.157700000000000000
          Height = 15.118120000000000000
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          DataSet = dmComprasSesiones.fxdsCabSesion
          DataSetName = 'Sesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Sesiones."DIRECCION1_PRV"]')
          ParentFont = False
        end
        object MemoPrvCpPob: TfrxMemoView
          AllowVectorExport = True
          Left = 355.275820000000000000
          Top = 79.370130000000000000
          Width = 340.157700000000000000
          Height = 15.118120000000000000
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          DataSet = dmComprasSesiones.fxdsCabSesion
          DataSetName = 'Sesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Sesiones."CODIGO_POSTAL_PRV"] [Sesiones."POBLACION_PRV"][II' +
              'F(<Sesiones."PROVINCIA_PRV"> <> '#39#39', '#39' ('#39' + <Sesiones."PROVIN' +
              'CIA_PRV"> + '#39')'#39', '#39#39')]')
          ParentFont = False
        end
        object MemoPrvCif: TfrxMemoView
          AllowVectorExport = True
          Left = 355.275820000000000000
          Top = 94.488250000000000000
          Width = 340.157700000000000000
          Height = 15.118120000000000000
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          DataSet = dmComprasSesiones.fxdsCabSesion
          DataSetName = 'Sesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[IIF(<Sesiones."CIF_PRV"> <> '#39#39', '#39'CIF: '#39' + <Sesiones."CIF_PR' +
              'V"> + '#39'   '#39', '#39#39')][IIF(<Sesiones."TELEFONO1_PRV"> <> '#39#39', '#39'Tel' +
              ': '#39' + <Sesiones."TELEFONO1_PRV">, '#39#39')]')
          ParentFont = False
        end
        object MemoSesLbl: TfrxMemoView
          AllowVectorExport = True
          Left = 710.551640000000000000
          Top = 27.236240000000000000
          Width = 336.378170000000000000
          Height = 15.118120000000000000
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGray
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'SESIÓN')
          ParentFont = False
        end
        object MemoSesNumero: TfrxMemoView
          AllowVectorExport = True
          Left = 710.551640000000000000
          Top = 45.354360000000000000
          Width = 336.378170000000000000
          Height = 22.677180000000000000
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          DataSet = dmComprasSesiones.fxdsCabSesion
          DataSetName = 'Sesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[Sesiones."DOCUMENTO_FORMATO"]')
          ParentFont = False
        end
        object MemoSesFechaLbl: TfrxMemoView
          AllowVectorExport = True
          Left = 710.551640000000000000
          Top = 71.811070000000000000
          Width = 100.157700000000000000
          Height = 15.118120000000000000
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGray
          Font.Height = -13
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
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          DataSet = dmComprasSesiones.fxdsCabSesion
          DataSetName = 'Sesiones'
          DisplayFormat.FormatStr = 'dd/mm/yyyy'
          DisplayFormat.Kind = fkDateTime
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Sesiones."FECHA_SES"]')
          ParentFont = False
        end
        object MemoSesEstadoLbl: TfrxMemoView
          AllowVectorExport = True
          Left = 710.551640000000000000
          Top = 86.929190000000000000
          Width = 100.157700000000000000
          Height = 15.118120000000000000
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGray
          Font.Height = -13
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
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          DataSet = dmComprasSesiones.fxdsCabSesion
          DataSetName = 'Sesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Sesiones."ESTADO_SES"]')
          ParentFont = False
        end
        object MemoSesRefPrvLbl: TfrxMemoView
          AllowVectorExport = True
          Left = 710.551640000000000000
          Top = 102.047310000000000000
          Width = 100.157700000000000000
          Height = 15.118120000000000000
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGray
          Font.Height = -13
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
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          DataSet = dmComprasSesiones.fxdsCabSesion
          DataSetName = 'Sesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Sesiones."REF_PRV_SES"]')
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
          Font.Height = -13
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
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Fill.BackColor = 6710886
          HAlign = haCenter
          Memo.UTF8W = (
            'Mod. / Alm.')
          ParentFont = False
          VAlign = vaCenter
          WordWrap = False
        end
        object HdrDescr: TfrxMemoView
          AllowVectorExport = True
          Left = 174.500000000000000000
          Width = 96.000000000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -14
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
          Font.Height = -14
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
          Font.Height = -14
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
          Font.Height = -14
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
          Font.Height = -13
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
          Font.Height = -13
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
        DataSet = dmComprasSesiones.fxdsLinSesion
        DataSetName = 'LineasSesiones'
        RowCount = 0
        object LinCodArt: TfrxMemoView
          AllowVectorExport = True
          Width = 108.500000000000000000
          Height = 22.677180000000000000
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          DataSet = dmComprasSesiones.fxdsLinSesion
          DataSetName = 'LineasSesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Memo.UTF8W = (
            '[LineasSesiones."CODIGO_ART"]')
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
          DataSet = dmComprasSesiones.fxdsLinSesion
          DataSetName = 'LineasSesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Memo.UTF8W = (

              '[IIF(<Sesiones."ESFORMATO_DISTRIBUIDO_SES"> = '#39'S'#39', <LineasSesion' +
              'es."REF_PRV"> + '#39' / '#39' + <LineasSesiones."CODIGO_ALM">, <LineasSe' +
              'siones."REF_PRV">)]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinDescr: TfrxMemoView
          AllowVectorExport = True
          Left = 174.500000000000000000
          Width = 96.000000000000000000
          Height = 22.677180000000000000
          DataSet = dmComprasSesiones.fxdsLinSesion
          DataSetName = 'LineasSesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Memo.UTF8W = (
            '[LineasSesiones."DESCRIPCION"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinColor: TfrxMemoView
          AllowVectorExport = True
          Left = 270.500000000000000000
          Width = 88.000000000000000000
          Height = 22.677180000000000000
          DataSet = dmComprasSesiones.fxdsLinSesion
          DataSetName = 'LineasSesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Memo.UTF8W = (
            '[LineasSesiones."COLOR_TEXTO"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinSistema: TfrxMemoView
          AllowVectorExport = True
          Left = 358.500000000000000000
          Width = 46.000000000000000000
          Height = 22.677180000000000000
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          DataSet = dmComprasSesiones.fxdsLinSesion
          DataSetName = 'LineasSesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[LineasSesiones."NOMBRE_CORTO_AC"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT01: TfrxMemoView
          AllowVectorExport = True
          Left = 404.500000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmComprasSesiones.fxdsLinSesion
          DataSetName = 'LineasSesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasSesiones."T01"> > 0, FormatFloat('#39'0'#39', <LineasSesione' +
              's."T01">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT02: TfrxMemoView
          AllowVectorExport = True
          Left = 430.000000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmComprasSesiones.fxdsLinSesion
          DataSetName = 'LineasSesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasSesiones."T02"> > 0, FormatFloat('#39'0'#39', <LineasSesione' +
              's."T02">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT03: TfrxMemoView
          AllowVectorExport = True
          Left = 455.500000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmComprasSesiones.fxdsLinSesion
          DataSetName = 'LineasSesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasSesiones."T03"> > 0, FormatFloat('#39'0'#39', <LineasSesione' +
              's."T03">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT04: TfrxMemoView
          AllowVectorExport = True
          Left = 481.000000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmComprasSesiones.fxdsLinSesion
          DataSetName = 'LineasSesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasSesiones."T04"> > 0, FormatFloat('#39'0'#39', <LineasSesione' +
              's."T04">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT05: TfrxMemoView
          AllowVectorExport = True
          Left = 506.500000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmComprasSesiones.fxdsLinSesion
          DataSetName = 'LineasSesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasSesiones."T05"> > 0, FormatFloat('#39'0'#39', <LineasSesione' +
              's."T05">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT06: TfrxMemoView
          AllowVectorExport = True
          Left = 532.000000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmComprasSesiones.fxdsLinSesion
          DataSetName = 'LineasSesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasSesiones."T06"> > 0, FormatFloat('#39'0'#39', <LineasSesione' +
              's."T06">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT07: TfrxMemoView
          AllowVectorExport = True
          Left = 557.500000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmComprasSesiones.fxdsLinSesion
          DataSetName = 'LineasSesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasSesiones."T07"> > 0, FormatFloat('#39'0'#39', <LineasSesione' +
              's."T07">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT08: TfrxMemoView
          AllowVectorExport = True
          Left = 583.000000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmComprasSesiones.fxdsLinSesion
          DataSetName = 'LineasSesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasSesiones."T08"> > 0, FormatFloat('#39'0'#39', <LineasSesione' +
              's."T08">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT09: TfrxMemoView
          AllowVectorExport = True
          Left = 608.500000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmComprasSesiones.fxdsLinSesion
          DataSetName = 'LineasSesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasSesiones."T09"> > 0, FormatFloat('#39'0'#39', <LineasSesione' +
              's."T09">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT10: TfrxMemoView
          AllowVectorExport = True
          Left = 634.000000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmComprasSesiones.fxdsLinSesion
          DataSetName = 'LineasSesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasSesiones."T10"> > 0, FormatFloat('#39'0'#39', <LineasSesione' +
              's."T10">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT11: TfrxMemoView
          AllowVectorExport = True
          Left = 659.500000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmComprasSesiones.fxdsLinSesion
          DataSetName = 'LineasSesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasSesiones."T11"> > 0, FormatFloat('#39'0'#39', <LineasSesione' +
              's."T11">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT12: TfrxMemoView
          AllowVectorExport = True
          Left = 685.000000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmComprasSesiones.fxdsLinSesion
          DataSetName = 'LineasSesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasSesiones."T12"> > 0, FormatFloat('#39'0'#39', <LineasSesione' +
              's."T12">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT13: TfrxMemoView
          AllowVectorExport = True
          Left = 710.500000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmComprasSesiones.fxdsLinSesion
          DataSetName = 'LineasSesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasSesiones."T13"> > 0, FormatFloat('#39'0'#39', <LineasSesione' +
              's."T13">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT14: TfrxMemoView
          AllowVectorExport = True
          Left = 736.000000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmComprasSesiones.fxdsLinSesion
          DataSetName = 'LineasSesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasSesiones."T14"> > 0, FormatFloat('#39'0'#39', <LineasSesione' +
              's."T14">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT15: TfrxMemoView
          AllowVectorExport = True
          Left = 761.500000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmComprasSesiones.fxdsLinSesion
          DataSetName = 'LineasSesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasSesiones."T15"> > 0, FormatFloat('#39'0'#39', <LineasSesione' +
              's."T15">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT16: TfrxMemoView
          AllowVectorExport = True
          Left = 787.000000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmComprasSesiones.fxdsLinSesion
          DataSetName = 'LineasSesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasSesiones."T16"> > 0, FormatFloat('#39'0'#39', <LineasSesione' +
              's."T16">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT17: TfrxMemoView
          AllowVectorExport = True
          Left = 812.500000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmComprasSesiones.fxdsLinSesion
          DataSetName = 'LineasSesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasSesiones."T17"> > 0, FormatFloat('#39'0'#39', <LineasSesione' +
              's."T17">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT18: TfrxMemoView
          AllowVectorExport = True
          Left = 838.000000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmComprasSesiones.fxdsLinSesion
          DataSetName = 'LineasSesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasSesiones."T18"> > 0, FormatFloat('#39'0'#39', <LineasSesione' +
              's."T18">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT19: TfrxMemoView
          AllowVectorExport = True
          Left = 863.500000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmComprasSesiones.fxdsLinSesion
          DataSetName = 'LineasSesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasSesiones."T19"> > 0, FormatFloat('#39'0'#39', <LineasSesione' +
              's."T19">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT20: TfrxMemoView
          AllowVectorExport = True
          Left = 889.000000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmComprasSesiones.fxdsLinSesion
          DataSetName = 'LineasSesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasSesiones."T20"> > 0, FormatFloat('#39'0'#39', <LineasSesione' +
              's."T20">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinT21: TfrxMemoView
          AllowVectorExport = True
          Left = 914.500000000000000000
          Width = 25.500000000000000000
          Height = 22.677180000000000000
          DataSet = dmComprasSesiones.fxdsLinSesion
          DataSetName = 'LineasSesiones'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (

              '[IIF(<LineasSesiones."T21"> > 0, FormatFloat('#39'0'#39', <LineasSesione' +
              's."T21">), '#39#39')]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinTotalUds: TfrxMemoView
          AllowVectorExport = True
          Left = 940.000000000000000000
          Width = 45.000000000000000000
          Height = 22.677180000000000000
          DataSet = dmComprasSesiones.fxdsLinSesion
          DataSetName = 'LineasSesiones'
          DisplayFormat.FormatStr = '%2.0n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[LineasSesiones."TOTAL_UNIDADES"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object LinImporte: TfrxMemoView
          AllowVectorExport = True
          Left = 985.000000000000000000
          Width = 61.929500000000000000
          Height = 22.677180000000000000
          DataSet = dmComprasSesiones.fxdsLinSesion
          DataSetName = 'LineasSesiones'
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '[LineasSesiones."TOTAL_LINEA"]')
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
            'DESGLOSE IVA / RE[IIF((<Sesiones."PORCENTAJE_IVAN_SES"> <> 0' +
              ') or (<Sesiones."TOTAL_BASEI_IVAN_SES"> <> 0), Chr(13) + Chr' +
              '(10) + '#39'Normal       Base '#39' + FormatFloat('#39'#,##0.00'#39', <Sesio' +
              'nes."TOTAL_BASEI_IVAN_SES">) + '#39'  IVA '#39' + FormatFloat('#39'0.##'#39 +
              ', <Sesiones."PORCENTAJE_IVAN_SES">) + '#39'% '#39' + FormatFloat('#39'#,' +
              '##0.00'#39', <Sesiones."TOTAL_IVAN_SES">) + IIF(<Sesiones."TOTAL' +
              '_REN_SES"> <> 0, '#39'  RE '#39' + FormatFloat('#39'0.##'#39', <Sesiones."PO' +
              'RCENTAJE_REN_SES">) + '#39'% '#39' + FormatFloat('#39'#,##0.00'#39', <Sesion' +
              'es."TOTAL_REN_SES">), '#39#39'), '#39#39')][IIF((<Sesiones."PORCENTAJE_I' +
              'VAR_SES"> <> 0) or (<Sesiones."TOTAL_BASEI_IVAR_SES"> <> 0),' +
              ' Chr(13) + Chr(10) + '#39'Reducido     Base '#39' + FormatFloat('#39'#,#' +
              '#0.00'#39', <Sesiones."TOTAL_BASEI_IVAR_SES">) + '#39'  IVA '#39' + Form' +
              'atFloat('#39'0.##'#39', <Sesiones."PORCENTAJE_IVAR_SES">) + '#39'% '#39' + F' +
              'ormatFloat('#39'#,##0.00'#39', <Sesiones."TOTAL_IVAR_SES">) + IIF(<S' +
              'esiones."TOTAL_RER_SES"> <> 0, '#39'  RE '#39' + FormatFloat('#39'0.##'#39',' +
              ' <Sesiones."PORCENTAJE_RER_SES">) + '#39'% '#39' + FormatFloat('#39'#,##' +
              '0.00'#39', <Sesiones."TOTAL_RER_SES">), '#39#39'), '#39#39')][IIF((<Sesiones' +
              '."PORCENTAJE_IVAS_SES"> <> 0) or (<Sesiones."TOTAL_BASEI_IVA' +
              'S_SES"> <> 0), Chr(13) + Chr(10) + '#39'Super red.   Base '#39' + Fo' +
              'rmatFloat('#39'#,##0.00'#39', <Sesiones."TOTAL_BASEI_IVAS_SES">) + '#39 +
              '  IVA '#39' + FormatFloat('#39'0.##'#39', <Sesiones."PORCENTAJE_IVAS_SES' +
              '">) + '#39'% '#39' + FormatFloat('#39'#,##0.00'#39', <Sesiones."TOTAL_IVAS_S' +
              'ES">) + IIF(<Sesiones."TOTAL_RES_SES"> <> 0, '#39'  RE '#39' + Forma' +
              'tFloat('#39'0.##'#39', <Sesiones."PORCENTAJE_RES_SES">) + '#39'% '#39' + For' +
              'matFloat('#39'#,##0.00'#39', <Sesiones."TOTAL_RES_SES">), '#39#39'), '#39#39')]'
            'Exento       Base [FormatFloat('#39'#,##0.00'#39', <Sesiones."TOTAL_' +
              'BASEI_IVAE_SES">)]  IVA [FormatFloat('#39'0.##'#39', <Sesiones."PORC' +
              'ENTAJE_IVAE_SES">)]% [FormatFloat('#39'#,##0.00'#39', <Sesiones."TOT' +
              'AL_IVAE_SES">)][IIF(<Sesiones."TOTAL_REE_SES"> <> 0, '#39'  RE '#39 +
              ' + FormatFloat('#39'0.##'#39', <Sesiones."PORCENTAJE_REE_SES">) + '#39'%' +
              ' '#39' + FormatFloat('#39'#,##0.00'#39', <Sesiones."TOTAL_REE_SES">), '#39#39 +
              ')]'
            'Base total [FormatFloat('#39'#,##0.00'#39', <Sesiones."TOTAL_BASES_S' +
              'ES">)]   Impuestos [FormatFloat('#39'#,##0.00'#39', <Sesiones."TOTAL' +
              '_IMPUESTOS_SES">)]'
            '[IIF(<Sesiones."TOTAL_RETENCION_SES"> <> 0, '#39'Retencion IRPF ' +
              #39' + FormatFloat('#39'0.##'#39', <Sesiones."PORCENTAJE_RETENCION_SES"' +
              '>) + '#39'% -'#39' + FormatFloat('#39'#,##0.00'#39', <Sesiones."TOTAL_RETENC' +
              'ION_SES">), '#39#39')]'
            'TOTAL LIQUIDO [FormatFloat('#39'#,##0.00'#39', <Sesiones."TOTAL_LIQU' +
              'IDO_SES">)] EUR')
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
            'TOTAL: [Sesiones."TOTAL_UNIDADES_SES"] unidades')
          ParentFont = False
          VAlign = vaCenter
        end
        object MemoTotalImporte: TfrxMemoView
          AllowVectorExport = True
          Left = 940.000000000000000000
          Top = 3.779530000000000000
          Width = 106.929500000000000000
          Height = 18.897650000000000000
          DataSet = dmComprasSesiones.fxdsCabSesion
          DataSetName = 'Sesiones'
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
            '[Sesiones."TOTAL_LINEAS_SES"]')
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
        DataSet = dmComprasSesiones.fxdsCabSesion
        DataSetName = 'Sesiones'
      end
      item
        DataSet = dmComprasSesiones.fxdsLinSesion
        DataSetName = 'LineasSesiones'
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
      PaperSize = 256
      LeftMargin = 10.000000000000000000
      RightMargin = 10.000000000000000000
      TopMargin = 10.000000000000000000
      BottomMargin = 10.000000000000000000
    end
  end
end
