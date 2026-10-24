inherited frmPrintTraspasoSolicitudes: TfrmPrintTraspasoSolicitudes
  Caption = 'Listado de solicitudes de traspaso'
  ClientHeight = 350
  ClientWidth = 920
  ExplicitWidth = 936
  ExplicitHeight = 389
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
  object lblContexto: TcxLabel
    Left = 12
    Top = 130
    Caption = 'Ubicaci'#243'n activa:'
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
    Width = 576
    Height = 350
    TabOrder = 13
    Properties.ActivePage = tsUbicaciones
    Properties.CustomButtons.Buttons = <>
    ClientRectBottom = 346
    ClientRectLeft = 4
    ClientRectRight = 572
    ClientRectTop = 28
    object tsUbicaciones: TcxTabSheet
      Caption = 'Empresas / almacenes / cajas'
      object lblUbicaciones: TcxLabel
        Left = 12
        Top = 8
        AutoSize = False
        Caption =
          'Marque las ubicaciones solicitantes que desea incluir.'
        TabOrder = 0
        Transparent = True
        Height = 23
        Width = 540
      end
      object clbUbicaciones: TcxCheckListBox
        Left = 12
        Top = 37
        Width = 540
        Height = 222
        EditValueFormat = cvfStatesString
        Items = <>
        TabOrder = 1
      end
      object btnMarcarUbicaciones: TcxButton
        Left = 12
        Top = 271
        Width = 130
        Height = 25
        Caption = 'Marcar todas'
        TabOrder = 2
        OnClick = btnMarcarUbicacionesClick
      end
      object btnDesmarcarUbicaciones: TcxButton
        Left = 154
        Top = 271
        Width = 138
        Height = 25
        Caption = 'Desmarcar todas'
        TabOrder = 3
        OnClick = btnDesmarcarUbicacionesClick
      end
    end
    object tsEstados: TcxTabSheet
      Caption = 'Estados'
      ImageIndex = 1
      object lblEstados: TcxLabel
        Left = 12
        Top = 8
        AutoSize = False
        Caption = 'Marque los estados que desea incluir en el listado.'
        TabOrder = 0
        Transparent = True
        Height = 23
        Width = 540
      end
      object clbEstados: TcxCheckListBox
        Left = 12
        Top = 37
        Width = 540
        Height = 222
        EditValueFormat = cvfStatesString
        Items = <>
        TabOrder = 1
      end
      object btnMarcarEstados: TcxButton
        Left = 12
        Top = 271
        Width = 130
        Height = 25
        Caption = 'Marcar todos'
        TabOrder = 2
        OnClick = btnMarcarEstadosClick
      end
      object btnDesmarcarEstados: TcxButton
        Left = 154
        Top = 271
        Width = 138
        Height = 25
        Caption = 'Desmarcar todos'
        TabOrder = 3
        OnClick = btnDesmarcarEstadosClick
      end
    end
  end
  inherited pnl1: TPanel
    Left = 776
    Height = 350
    inherited btnEditar: TcxButton
      OnClick = btnEditarSolicitudesClick
    end
    inherited btnExcel: TcxButton
      Caption = 'E&xcel (nativo)'
      OnClick = btnExcelNativoClick
    end
    inherited btnSalir: TcxButton
      Top = 324
    end
  end
  inherited frxrprt1: TfrxReport
    Datasets = <
      item
        DataSet = fxdsSolicitudes
        DataSetName = 'Solicitudes'
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
        DataSet = fxdsSolicitudes
        DataSetName = 'Solicitudes'
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
        Height = 40.000000000000000000
        Top = 0.000000000000000000
        Width = 1047.000000000000000000
        Frame.Typ = []
        object MemoTitulo: TfrxMemoView
          Left = 0.000000000000000000
          Top = 2.000000000000000000
          Width = 610.000000000000000000
          Height = 25.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -18
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            'Solicitudes de traspaso')
          ParentFont = False
        end
        object MemoPeriodo: TfrxMemoView
          Left = 610.000000000000000000
          Top = 6.000000000000000000
          Width = 437.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            'Periodo: [FormatDateTime('#39'dd/mm/yyyy'#39', <Solicitudes.' +
            '"FECHA_DESDE">)] a [FormatDateTime('#39'dd/mm/yyyy'#39', <Soli' +
            'citudes."FECHA_HASTA">)]')
          ParentFont = False
        end
      end
      object GroupHeaderSolicitud: TfrxGroupHeader
        Height = 96.000000000000000000
        Top = 44.000000000000000000
        Width = 1047.000000000000000000
        Condition = 'Solicitudes."CLAVE_SOLICITUD"'
        KeepTogether = True
        ReprintOnNewPage = True
        Stretched = True
        Frame.Typ = []
        object MemoSolicitud: TfrxMemoView
          Left = 0.000000000000000000
          Top = 0.000000000000000000
          Width = 470.000000000000000000
          Height = 20.000000000000000000
          Color = 15259849
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          Memo.UTF8W = (
            'SOLICITUD  [Solicitudes."SERIE_TRSOL"]/[Solicitudes."NUMERO_TR' +
            'SOL"]')
          ParentFont = False
        end
        object MemoAlta: TfrxMemoView
          Left = 470.000000000000000000
          Top = 0.000000000000000000
          Width = 250.000000000000000000
          Height = 20.000000000000000000
          Color = 15259849
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -10
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[FormatDateTime('#39'dd/mm/yyyy hh:nn'#39', <Solicitudes."INSTANT' +
            'E_ALTA">)]')
          ParentFont = False
        end
        object MemoEstado: TfrxMemoView
          Left = 720.000000000000000000
          Top = 0.000000000000000000
          Width = 327.000000000000000000
          Height = 20.000000000000000000
          Color = 15259849
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop, ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Estado: [Solicitudes."ESTADO_TRSOL"]')
          ParentFont = False
        end
        object MemoSolicitante: TfrxMemoView
          Left = 0.000000000000000000
          Top = 22.000000000000000000
          Width = 523.000000000000000000
          Height = 17.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Solicitante: [Solicitudes."CODIGO_EMP_TRSOL"] - [Solicitudes.' +
            '"NOMBRE_EMPRESA_TRSOL"] / [Solicitudes."CODIGO_ALM_DESTINO_TR' +
            'SOL"] - [Solicitudes."NOMBRE_ALMACEN_DESTINO_TRSOL"]')
          ParentFont = False
        end
        object MemoSolicitada: TfrxMemoView
          Left = 523.000000000000000000
          Top = 22.000000000000000000
          Width = 524.000000000000000000
          Height = 17.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Solicitada: [Solicitudes."CODIGO_EMP_CONTRA_TRSOL"] - [Solici' +
            'tudes."NOMBRE_EMPRESA_CONTRA_TRSOL"] / [Solicitudes."CODIGO_A' +
            'LM_ORIGEN_TRSOL"] - [Solicitudes."NOMBRE_ALMACEN_ORIGEN_TRSOL' +
            '"]')
          ParentFont = False
        end
        object MemoCajaEmpleado: TfrxMemoView
          Left = 0.000000000000000000
          Top = 40.000000000000000000
          Width = 1047.000000000000000000
          Height = 17.000000000000000000
          StretchMode = smActualHeight
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Caja: [Solicitudes."CODIGO_CAJA_TRSOL"] - [Solicitudes."NOMBR' +
            'E_CAJA_TRSOL"]     Empleado: [Solicitudes."CODIGO_EMPLEADO_TRS' +
            'OL"] - [Solicitudes."NOMBRE_EMPLEADO_TRSOL"]')
          ParentFont = False
        end
        object MemoObservaciones: TfrxMemoView
          Left = 0.000000000000000000
          Top = 57.000000000000000000
          Width = 1047.000000000000000000
          Height = 17.000000000000000000
          StretchMode = smActualHeight
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsItalic]
          Frame.Typ = []
          Memo.UTF8W = (
            'Observaciones: [Solicitudes."OBSERVACIONES_TRSOL"]')
          ParentFont = False
        end
        object HFoto: TfrxMemoView
          Left = 0.000000000000000000
          Top = 76.000000000000000000
          Width = 50.000000000000000000
          Height = 18.000000000000000000
          ShiftMode = smWhenOverlapped
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            'Foto')
          ParentFont = False
        end
        object HLinea: TfrxMemoView
          Left = 52.000000000000000000
          Top = 76.000000000000000000
          Width = 35.000000000000000000
          Height = 18.000000000000000000
          ShiftMode = smWhenOverlapped
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            'L'#237'n.')
          ParentFont = False
        end
        object HArticulo: TfrxMemoView
          Left = 89.000000000000000000
          Top = 76.000000000000000000
          Width = 90.000000000000000000
          Height = 18.000000000000000000
          ShiftMode = smWhenOverlapped
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
        object HSku: TfrxMemoView
          Left = 181.000000000000000000
          Top = 76.000000000000000000
          Width = 135.000000000000000000
          Height = 18.000000000000000000
          ShiftMode = smWhenOverlapped
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'SKU / unidad')
          ParentFont = False
        end
        object HDescripcion: TfrxMemoView
          Left = 318.000000000000000000
          Top = 76.000000000000000000
          Width = 300.000000000000000000
          Height = 18.000000000000000000
          ShiftMode = smWhenOverlapped
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
        object HPedida: TfrxMemoView
          Left = 620.000000000000000000
          Top = 76.000000000000000000
          Width = 70.000000000000000000
          Height = 18.000000000000000000
          ShiftMode = smWhenOverlapped
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Pedida')
          ParentFont = False
        end
        object HServida: TfrxMemoView
          Left = 692.000000000000000000
          Top = 76.000000000000000000
          Width = 70.000000000000000000
          Height = 18.000000000000000000
          ShiftMode = smWhenOverlapped
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Servida')
          ParentFont = False
        end
        object HPendiente: TfrxMemoView
          Left = 764.000000000000000000
          Top = 76.000000000000000000
          Width = 70.000000000000000000
          Height = 18.000000000000000000
          ShiftMode = smWhenOverlapped
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haRight
          Memo.UTF8W = (
            'Pendiente')
          ParentFont = False
        end
        object HAtendida: TfrxMemoView
          Left = 836.000000000000000000
          Top = 76.000000000000000000
          Width = 70.000000000000000000
          Height = 18.000000000000000000
          ShiftMode = smWhenOverlapped
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            'Atendida')
          ParentFont = False
        end
        object HMotivo: TfrxMemoView
          Left = 908.000000000000000000
          Top = 76.000000000000000000
          Width = 139.000000000000000000
          Height = 18.000000000000000000
          ShiftMode = smWhenOverlapped
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftBottom]
          Memo.UTF8W = (
            'Motivo rechazo')
          ParentFont = False
        end
      end
      object MasterData1: TfrxMasterData
        Height = 52.000000000000000000
        Top = 144.000000000000000000
        Width = 1047.000000000000000000
        DataSet = fxdsSolicitudes
        DataSetName = 'Solicitudes'
        RowCount = 0
        Stretched = True
        Frame.Typ = []
        object foto300: TfrxPictureView
          AllowVectorExport = True
          Left = 0.000000000000000000
          Top = 1.000000000000000000
          Width = 50.000000000000000000
          Height = 50.000000000000000000
          Frame.Typ = []
          HightQuality = True
          Transparent = False
          TransparentColor = clWhite
        end
        object DLinea: TfrxMemoView
          Left = 52.000000000000000000
          Top = 2.000000000000000000
          Width = 35.000000000000000000
          Height = 48.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haCenter
          Memo.UTF8W = (
            '[Solicitudes."LINEA_TRSOLLIN"]')
          ParentFont = False
        end
        object DArticulo: TfrxMemoView
          Left = 89.000000000000000000
          Top = 2.000000000000000000
          Width = 90.000000000000000000
          Height = 48.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Solicitudes."CODIGO_ART"]')
          ParentFont = False
        end
        object DSku: TfrxMemoView
          Left = 181.000000000000000000
          Top = 2.000000000000000000
          Width = 135.000000000000000000
          Height = 48.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Solicitudes."SKU_UNIDAD"]')
          ParentFont = False
        end
        object DDescripcion: TfrxMemoView
          Left = 318.000000000000000000
          Top = 2.000000000000000000
          Width = 300.000000000000000000
          Height = 48.000000000000000000
          StretchMode = smActualHeight
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Solicitudes."DESCRIPCION_ART"]')
          ParentFont = False
        end
        object DPedida: TfrxMemoView
          Left = 620.000000000000000000
          Top = 2.000000000000000000
          Width = 70.000000000000000000
          Height = 48.000000000000000000
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Solicitudes."CANTIDAD_PEDIDA_TRSOLLIN"]')
          ParentFont = False
        end
        object DServida: TfrxMemoView
          Left = 692.000000000000000000
          Top = 2.000000000000000000
          Width = 70.000000000000000000
          Height = 48.000000000000000000
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Solicitudes."CANTIDAD_SERVIDA_TRSOLLIN"]')
          ParentFont = False
        end
        object DPendiente: TfrxMemoView
          Left = 764.000000000000000000
          Top = 2.000000000000000000
          Width = 70.000000000000000000
          Height = 48.000000000000000000
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Solicitudes."CANTIDAD_PENDIENTE_TRSOLLIN"]')
          ParentFont = False
        end
        object DAtendida: TfrxMemoView
          Left = 836.000000000000000000
          Top = 2.000000000000000000
          Width = 70.000000000000000000
          Height = 48.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haCenter
          Memo.UTF8W = (
            '[Solicitudes."ATENDIDA_TRSOLLIN"]')
          ParentFont = False
        end
        object DMotivo: TfrxMemoView
          Left = 908.000000000000000000
          Top = 2.000000000000000000
          Width = 139.000000000000000000
          Height = 48.000000000000000000
          StretchMode = smActualHeight
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -8
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Solicitudes."MOTIVO_RECHAZO_TRSOLLIN"]')
          ParentFont = False
        end
      end
      object GroupFooterSolicitud: TfrxGroupFooter
        Height = 20.000000000000000000
        Top = 200.000000000000000000
        Width = 1047.000000000000000000
        Frame.Typ = []
        object MemoTotalSolicitud: TfrxMemoView
          Left = 318.000000000000000000
          Top = 1.000000000000000000
          Width = 300.000000000000000000
          Height = 17.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftTop]
          HAlign = haRight
          Memo.UTF8W = (
            'TOTAL SOLICITUD')
          ParentFont = False
        end
        object MemoTotalPedida: TfrxMemoView
          Left = 620.000000000000000000
          Top = 1.000000000000000000
          Width = 70.000000000000000000
          Height = 17.000000000000000000
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
            '[SUM(<Solicitudes."CANTIDAD_PEDIDA_TRSOLLIN">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotalServida: TfrxMemoView
          Left = 692.000000000000000000
          Top = 1.000000000000000000
          Width = 70.000000000000000000
          Height = 17.000000000000000000
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
            '[SUM(<Solicitudes."CANTIDAD_SERVIDA_TRSOLLIN">,MasterData1)]')
          ParentFont = False
        end
        object MemoTotalPendiente: TfrxMemoView
          Left = 764.000000000000000000
          Top = 1.000000000000000000
          Width = 70.000000000000000000
          Height = 17.000000000000000000
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
            '[SUM(<Solicitudes."CANTIDAD_PENDIENTE_TRSOLLIN">,MasterData1)]')
          ParentFont = False
        end
      end
      object PageFooter1: TfrxPageFooter
        Height = 18.000000000000000000
        Top = 224.000000000000000000
        Width = 1047.000000000000000000
        Frame.Typ = []
        object MemoPagina: TfrxMemoView
          Left = 0.000000000000000000
          Top = 2.000000000000000000
          Width = 400.000000000000000000
          Height = 14.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'P'#225'gina [Page#] de [TotalPages#]')
          ParentFont = False
        end
        object MemoImpreso: TfrxMemoView
          Left = 647.000000000000000000
          Top = 2.000000000000000000
          Width = 400.000000000000000000
          Height = 14.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            'Impreso el [Date]')
          ParentFont = False
        end
      end
    end
  end
  object dsSolicitudesPrint: TDataSource
    Left = 232
    Top = 152
  end
  object fxdsSolicitudes: TfrxDBDataset
    Description = 'Solicitudes de traspaso'
    UserName = 'Solicitudes'
    CloseDataSource = False
    DataSource = dsSolicitudesPrint
    BCDToCurrency = False
    DataSetOptions = []
    Left = 304
    Top = 152
  end
end
