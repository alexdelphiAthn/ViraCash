inherited frmPrintOperacionesVenta: TfrmPrintOperacionesVenta
  Caption = 'Listado de operaciones de venta'
  ClientHeight = 320
  ClientWidth = 900
  ExplicitWidth = 916
  ExplicitHeight = 359
  TextHeight = 19
  inherited pnl1: TPanel
    inherited btnPDF: TcxButton
      OnClick = EjecutarAccionInforme
    end
    inherited btnImprimir: TcxButton
      OnClick = EjecutarAccionInforme
    end
    inherited btnVistaPreliminar: TcxButton
      OnClick = EjecutarAccionInforme
    end
    inherited btnEditar: TcxButton
      OnClick = EjecutarAccionInforme
    end
    inherited btnExcel: TcxButton
      OnClick = EjecutarAccionInforme
    end
  end
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
  object lblContexto: TcxLabel
    Left = 12
    Top = 130
    Caption = 'TPV activo:'
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
  object edtAlmacen: TcxTextEdit
    Left = 12
    Top = 218
    Properties.ReadOnly = True
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
  object edtCaja: TcxTextEdit
    Left = 12
    Top = 264
    Properties.ReadOnly = True
    TabOrder = 5
    Width = 172
  end
  object pcOpciones: TcxPageControl
    Left = 200
    Top = 0
    Width = 556
    Height = 320
    TabOrder = 13
    Properties.ActivePage = tsUbicaciones
    Properties.CustomButtons.Buttons = <>
    ClientRectBottom = 316
    ClientRectLeft = 4
    ClientRectRight = 552
    ClientRectTop = 28
    object tsUbicaciones: TcxTabSheet
      Caption = 'Empresas / almacenes / cajas'
      object lblUbicaciones: TcxLabel
        Left = 12
        Top = 8
        AutoSize = False
        Caption =
          'Marque las ubicaciones que desea acumular en el listado.'
        TabOrder = 0
        Transparent = True
        Height = 23
        Width = 520
      end
      object clbUbicaciones: TcxCheckListBox
        Left = 12
        Top = 37
        Width = 520
        Height = 202
        AllowDblClickToggle = False
        EditValueFormat = cvfStatesString
        Items = <>
        ReadOnly = False
        OnMouseUp = clbUbicacionesMouseUp
        TabOrder = 1
      end
      object btnMarcarTodas: TcxButton
        Left = 12
        Top = 251
        Width = 130
        Height = 25
        Caption = 'Marcar todas'
        TabOrder = 2
        OnClick = btnMarcarTodasClick
      end
      object btnDesmarcarTodas: TcxButton
        Left = 154
        Top = 251
        Width = 138
        Height = 25
        Caption = 'Desmarcar todas'
        TabOrder = 3
        OnClick = btnDesmarcarTodasClick
      end
    end
  end
  inherited frxrprt1: TfrxReport
    Datasets = <
      item
        DataSet = fxdsVentas
        DataSetName = 'Ventas'
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
        DataSet = fxdsVentas
        DataSetName = 'Ventas'
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
        Height = 38.000000000000000000
        Top = 0.000000000000000000
        Width = 1047.000000000000000000
        Frame.Typ = []
        object MemoTitulo: TfrxMemoView
          Left = 0.000000000000000000
          Top = 3.000000000000000000
          Width = 500.000000000000000000
          Height = 27.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -18
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            'Listado de operaciones de venta')
          ParentFont = False
        end
        object MemoDesde: TfrxMemoView
          Left = 520.000000000000000000
          Top = 10.000000000000000000
          Width = 245.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            'Desde fecha  [FormatDateTime(''dd/mm/yyyy'', ' +
            '<Ventas."FECHA_DESDE">)]')
          ParentFont = False
        end
        object MemoHasta: TfrxMemoView
          Left = 775.000000000000000000
          Top = 10.000000000000000000
          Width = 272.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            'Hasta fecha  [FormatDateTime(''dd/mm/yyyy'', ' +
            '<Ventas."FECHA_HASTA">)]')
          ParentFont = False
        end
      end
      object PageHeader1: TfrxPageHeader
        Height = 21.000000000000000000
        Top = 42.000000000000000000
        Width = 1047.000000000000000000
        Frame.Typ = []
        object MemoHArticulo: TfrxMemoView
          Left = 0.000000000000000000
          Top = 2.000000000000000000
          Width = 80.000000000000000000
          Height = 17.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Art'#237'culo')
          ParentFont = False
        end
        object MemoHColor: TfrxMemoView
          Left = 80.000000000000000000
          Top = 2.000000000000000000
          Width = 55.000000000000000000
          Height = 17.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Color')
          ParentFont = False
        end
        object MemoHCopa: TfrxMemoView
          Left = 135.000000000000000000
          Top = 2.000000000000000000
          Width = 30.000000000000000000
          Height = 17.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Copa')
          ParentFont = False
        end
        object MemoHTalla: TfrxMemoView
          Left = 165.000000000000000000
          Top = 2.000000000000000000
          Width = 42.000000000000000000
          Height = 17.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Talla')
          ParentFont = False
        end
        object MemoHProveedor: TfrxMemoView
          Left = 207.000000000000000000
          Top = 2.000000000000000000
          Width = 45.000000000000000000
          Height = 17.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Pvdr.')
          ParentFont = False
        end
        object MemoHModelo: TfrxMemoView
          Left = 252.000000000000000000
          Top = 2.000000000000000000
          Width = 55.000000000000000000
          Height = 17.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Modelo')
          ParentFont = False
        end
        object MemoHDescripcion: TfrxMemoView
          Left = 307.000000000000000000
          Top = 2.000000000000000000
          Width = 160.000000000000000000
          Height = 17.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Descripci'#243'n')
          ParentFont = False
        end
        object MemoHCantidad: TfrxMemoView
          Left = 467.000000000000000000
          Top = 2.000000000000000000
          Width = 45.000000000000000000
          Height = 17.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Ctd.')
          ParentFont = False
        end
        object MemoHBruto: TfrxMemoView
          Left = 512.000000000000000000
          Top = 2.000000000000000000
          Width = 65.000000000000000000
          Height = 17.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Bruto')
          ParentFont = False
        end
        object MemoHDto: TfrxMemoView
          Left = 577.000000000000000000
          Top = 2.000000000000000000
          Width = 48.000000000000000000
          Height = 17.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            '% Dto.')
          ParentFont = False
        end
        object MemoHNeto: TfrxMemoView
          Left = 625.000000000000000000
          Top = 2.000000000000000000
          Width = 65.000000000000000000
          Height = 17.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Neto art.')
          ParentFont = False
        end
        object MemoHIngresos: TfrxMemoView
          Left = 690.000000000000000000
          Top = 2.000000000000000000
          Width = 65.000000000000000000
          Height = 17.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Ingresos')
          ParentFont = False
        end
        object MemoHVendedor: TfrxMemoView
          Left = 755.000000000000000000
          Top = 2.000000000000000000
          Width = 42.000000000000000000
          Height = 17.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Vdor.')
          ParentFont = False
        end
        object MemoHFormaPago: TfrxMemoView
          Left = 797.000000000000000000
          Top = 2.000000000000000000
          Width = 85.000000000000000000
          Height = 17.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Forma Pago')
          ParentFont = False
        end
        object MemoHDocumento: TfrxMemoView
          Left = 882.000000000000000000
          Top = 2.000000000000000000
          Width = 165.000000000000000000
          Height = 17.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Documento')
          ParentFont = False
        end
      end
      object GroupHeaderFecha: TfrxGroupHeader
        Height = 0.100000000000000000
        Top = 67.000000000000000000
        Width = 1047.000000000000000000
        Condition = 'Ventas."FECHA_DIA"'
        Frame.Typ = []
      end
      object GroupHeaderCaja: TfrxGroupHeader
        Height = 0.100000000000000000
        Top = 71.000000000000000000
        Width = 1047.000000000000000000
        Condition = 'Ventas."CLAVE_CAJA"'
        Frame.Typ = []
      end
      object MasterData1: TfrxMasterData
        FillType = ftBrush
        Height = 16.000000000000000000
        Top = 75.000000000000000000
        Width = 1047.000000000000000000
        DataSet = fxdsVentas
        DataSetName = 'Ventas'
        RowCount = 0
        Frame.Typ = []
        object MemoArticulo: TfrxMemoView
          Left = 0.000000000000000000
          Width = 80.000000000000000000
          Height = 16.000000000000000000
          DataField = 'ARTICULO'
          DataSet = fxdsVentas
          DataSetName = 'Ventas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Ventas."ARTICULO"]')
          ParentFont = False
          WordWrap = False
          Clipped = True
        end
        object MemoColor: TfrxMemoView
          Left = 95.000000000000000000
          Width = 40.000000000000000000
          Height = 16.000000000000000000
          DataField = 'COLOR'
          DataSet = fxdsVentas
          DataSetName = 'Ventas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Ventas."COLOR"]')
          ParentFont = False
          WordWrap = False
          Clipped = True
        end
        object MemoColorBasico: TfrxMemoView
          AllowVectorExport = True
          Left = 81.000000000000000000
          Top = 2.000000000000000000
          Width = 11.000000000000000000
          Height = 11.000000000000000000
          Color = clWhite
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
        end
        object MemoCopa: TfrxMemoView
          Left = 135.000000000000000000
          Width = 30.000000000000000000
          Height = 16.000000000000000000
          DataField = 'COPA'
          DataSet = fxdsVentas
          DataSetName = 'Ventas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Ventas."COPA"]')
          ParentFont = False
          WordWrap = False
          Clipped = True
        end
        object MemoTalla: TfrxMemoView
          Left = 165.000000000000000000
          Width = 42.000000000000000000
          Height = 16.000000000000000000
          DataField = 'TALLA'
          DataSet = fxdsVentas
          DataSetName = 'Ventas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Ventas."TALLA"]')
          ParentFont = False
          WordWrap = False
          Clipped = True
        end
        object MemoProveedor: TfrxMemoView
          Left = 207.000000000000000000
          Width = 45.000000000000000000
          Height = 16.000000000000000000
          DataField = 'PROVEEDOR'
          DataSet = fxdsVentas
          DataSetName = 'Ventas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Ventas."PROVEEDOR"]')
          ParentFont = False
          WordWrap = False
          Clipped = True
        end
        object MemoModelo: TfrxMemoView
          Left = 252.000000000000000000
          Width = 55.000000000000000000
          Height = 16.000000000000000000
          DataField = 'MODELO'
          DataSet = fxdsVentas
          DataSetName = 'Ventas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Ventas."MODELO"]')
          ParentFont = False
          WordWrap = False
          Clipped = True
        end
        object MemoDescripcion: TfrxMemoView
          Left = 307.000000000000000000
          Width = 160.000000000000000000
          Height = 16.000000000000000000
          DataField = 'DESCRIPCION'
          DataSet = fxdsVentas
          DataSetName = 'Ventas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Ventas."DESCRIPCION"]')
          ParentFont = False
          WordWrap = False
          Clipped = True
        end
        object MemoCantidad: TfrxMemoView
          Left = 467.000000000000000000
          Width = 45.000000000000000000
          Height = 16.000000000000000000
          DataField = 'CANTIDAD'
          DataSet = fxdsVentas
          DataSetName = 'Ventas'
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Ventas."CANTIDAD"]')
          ParentFont = False
          WordWrap = False
          Clipped = True
        end
        object MemoBruto: TfrxMemoView
          Left = 512.000000000000000000
          Width = 65.000000000000000000
          Height = 16.000000000000000000
          DataField = 'BRUTO'
          DataSet = fxdsVentas
          DataSetName = 'Ventas'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Ventas."BRUTO"]')
          ParentFont = False
          WordWrap = False
          Clipped = True
        end
        object MemoDto: TfrxMemoView
          Left = 577.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          DataField = 'PORCENTAJE_DTO'
          DataSet = fxdsVentas
          DataSetName = 'Ventas'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          HideZeros = True
          Memo.UTF8W = (
            '[Ventas."PORCENTAJE_DTO"]')
          ParentFont = False
          WordWrap = False
          Clipped = True
        end
        object MemoNeto: TfrxMemoView
          Left = 625.000000000000000000
          Width = 65.000000000000000000
          Height = 16.000000000000000000
          DataField = 'NETO_ARTICULO'
          DataSet = fxdsVentas
          DataSetName = 'Ventas'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Ventas."NETO_ARTICULO"]')
          ParentFont = False
          WordWrap = False
          Clipped = True
        end
        object MemoIngresos: TfrxMemoView
          Left = 690.000000000000000000
          Width = 65.000000000000000000
          Height = 16.000000000000000000
          DataField = 'INGRESOS'
          DataSet = fxdsVentas
          DataSetName = 'Ventas'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Ventas."INGRESOS"]')
          ParentFont = False
          WordWrap = False
          Clipped = True
        end
        object MemoVendedor: TfrxMemoView
          Left = 755.000000000000000000
          Width = 42.000000000000000000
          Height = 16.000000000000000000
          DataField = 'VENDEDOR'
          DataSet = fxdsVentas
          DataSetName = 'Ventas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Ventas."VENDEDOR"]')
          ParentFont = False
          WordWrap = False
          Clipped = True
        end
        object MemoFormaPago: TfrxMemoView
          Left = 797.000000000000000000
          Width = 85.000000000000000000
          Height = 16.000000000000000000
          DataField = 'FORMA_PAGO'
          DataSet = fxdsVentas
          DataSetName = 'Ventas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Ventas."FORMA_PAGO"]')
          ParentFont = False
          WordWrap = False
          Clipped = True
        end
        object MemoDocumento: TfrxMemoView
          Left = 882.000000000000000000
          Width = 165.000000000000000000
          Height = 16.000000000000000000
          DataField = 'DOCUMENTO'
          DataSet = fxdsVentas
          DataSetName = 'Ventas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Ventas."DOCUMENTO"]')
          ParentFont = False
          WordWrap = False
          Clipped = True
        end
      end
      object GroupFooterCaja: TfrxGroupFooter
        Height = 18.000000000000000000
        Top = 95.000000000000000000
        Width = 1047.000000000000000000
        Frame.Typ = []
        object MemoTotalCaja: TfrxMemoView
          Left = 0.000000000000000000
          Top = 1.000000000000000000
          Width = 467.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          Memo.UTF8W = (
            'TOT.CAJA  [Ventas."CLAVE_CAJA"]')
          ParentFont = False
        end
        object MemoTotalCajaCantidad: TfrxMemoView
          Left = 467.000000000000000000
          Top = 1.000000000000000000
          Width = 45.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<Ventas."CANTIDAD">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotalCajaBruto: TfrxMemoView
          Left = 512.000000000000000000
          Top = 1.000000000000000000
          Width = 65.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<Ventas."BRUTO">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotalCajaDto: TfrxMemoView
          Left = 577.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[IIF(SUM(<Ventas."BRUTO">,MasterData1) = 0, 0,'
            ' (SUM(<Ventas."BRUTO">,MasterData1) -'
            ' SUM(<Ventas."NETO_ARTICULO">,MasterData1)) * 100 /'
            ' SUM(<Ventas."BRUTO">,MasterData1))]')
          ParentFont = False
        end
        object MemoTotalCajaNeto: TfrxMemoView
          Left = 625.000000000000000000
          Top = 1.000000000000000000
          Width = 65.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<Ventas."NETO_ARTICULO">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotalCajaIngresos: TfrxMemoView
          Left = 690.000000000000000000
          Top = 1.000000000000000000
          Width = 65.000000000000000000
          Height = 16.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<Ventas."INGRESOS">,MasterData1)]')
          ParentFont = False
        end
      end
      object GroupFooterFecha: TfrxGroupFooter
        Height = 19.000000000000000000
        Top = 117.000000000000000000
        Width = 1047.000000000000000000
        Frame.Typ = []
        object MemoTotalFecha: TfrxMemoView
          Left = 0.000000000000000000
          Top = 1.000000000000000000
          Width = 467.000000000000000000
          Height = 17.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold, fsItalic]
          Frame.Typ = []
          Memo.UTF8W = (
            'TOT.FECHA  [FormatDateTime(''dd/mm/yyyy'', ' +
            '<Ventas."FECHA_DIA">)]')
          ParentFont = False
        end
        object MemoTotalFechaCantidad: TfrxMemoView
          Left = 467.000000000000000000
          Top = 1.000000000000000000
          Width = 45.000000000000000000
          Height = 17.000000000000000000
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<Ventas."CANTIDAD">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotalFechaBruto: TfrxMemoView
          Left = 512.000000000000000000
          Top = 1.000000000000000000
          Width = 65.000000000000000000
          Height = 17.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<Ventas."BRUTO">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotalFechaDto: TfrxMemoView
          Left = 577.000000000000000000
          Top = 1.000000000000000000
          Width = 48.000000000000000000
          Height = 17.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[IIF(SUM(<Ventas."BRUTO">,MasterData1) = 0, 0,'
            ' (SUM(<Ventas."BRUTO">,MasterData1) -'
            ' SUM(<Ventas."NETO_ARTICULO">,MasterData1)) * 100 /'
            ' SUM(<Ventas."BRUTO">,MasterData1))]')
          ParentFont = False
        end
        object MemoTotalFechaNeto: TfrxMemoView
          Left = 625.000000000000000000
          Top = 1.000000000000000000
          Width = 65.000000000000000000
          Height = 17.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<Ventas."NETO_ARTICULO">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotalFechaIngresos: TfrxMemoView
          Left = 690.000000000000000000
          Top = 1.000000000000000000
          Width = 65.000000000000000000
          Height = 17.000000000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[SUM(<Ventas."INGRESOS">,MasterData1)]')
          ParentFont = False
        end
      end
      object PageFooter1: TfrxPageFooter
        Height = 18.000000000000000000
        Top = 140.000000000000000000
        Width = 1047.000000000000000000
        Frame.Typ = []
        object MemoPie: TfrxMemoView
          Left = 0.000000000000000000
          Top = 2.000000000000000000
          Width = 1047.000000000000000000
          Height = 14.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
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
  object dsVentasPrint: TDataSource
    Left = 216
    Top = 72
  end
  object fxdsVentas: TfrxDBDataset
    Description = 'Ventas'
    UserName = 'Ventas'
    CloseDataSource = False
    DataSource = dsVentasPrint
    BCDToCurrency = False
    DataSetOptions = []
    Left = 216
    Top = 128
  end
end
