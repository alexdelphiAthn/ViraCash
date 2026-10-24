inherited frmPrintEtiqArt: TfrmPrintEtiqAlb
  Caption = 'Impresi'#243'n de Etiquetas de Albar'#225'n'
  ClientHeight = 426
  ClientWidth = 536
  StyleElements = [seFont, seClient, seBorder]
  OnDestroy = FormDestroy
  OnShow = FormShow
  ExplicitWidth = 552
  ExplicitHeight = 465
  TextHeight = 19
  inherited pnl1: TPanel
    Left = 392
    Height = 426
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 390
    ExplicitHeight = 418
    inherited btnSalir: TcxButton
      Top = 400
      ExplicitTop = 392
    end
  end
  object pnlOpciones: TPanel [1]
    Left = 0
    Top = 0
    Width = 392
    Height = 426
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    ExplicitWidth = 390
    ExplicitHeight = 418
    object cxlblAlbaran: TcxLabel
      Left = 12
      Top = 12
      Caption = 'Albar'#225'n:'
      TabOrder = 5
      Transparent = True
    end
    object edtAlbaran: TcxTextEdit
      Left = 156
      Top = 8
      Properties.ReadOnly = True
      TabOrder = 0
      Width = 220
    end
    object cxlblTarifa: TcxLabel
      Left = 12
      Top = 44
      Caption = 'Tarifa:'
      TabOrder = 6
      Transparent = True
    end
    object cbbTarifa: TcxComboBox
      Left = 156
      Top = 40
      Properties.DropDownListStyle = lsFixedList
      TabOrder = 1
      Width = 220
    end
    object cxlblFecha: TcxLabel
      Left = 12
      Top = 76
      Caption = 'Fecha de aplicaci'#243'n:'
      TabOrder = 7
      Transparent = True
    end
    object dtFechaAplicacion: TcxDateEdit
      Left = 193
      Top = 72
      TabOrder = 2
      Width = 183
    end
    object cxlblAlmacenes: TcxLabel
      Left = 12
      Top = 108
      Caption = 'Almacenes del albar'#225'n (marque uno o varios):'
      TabOrder = 8
      Transparent = True
    end
    object lvAlmacenes: TcxListView
      Left = 12
      Top = 132
      Width = 364
      Height = 280
      Checkboxes = True
      Columns = <
        item
          Caption = 'C'#243'digo'
          Width = 100
        end
        item
          Caption = 'Almac'#233'n'
          Width = 240
        end>
      RowSelect = True
      TabOrder = 3
      ViewStyle = vsReport
    end
  end
  inherited frxrprt1: TfrxReport
    ReportOptions.Author = ''
    ReportOptions.LastChange = 46164.719528437500000000
    ScriptText.Strings = (
      'function HexNibble(c: Char): Integer;'
      'begin'
      '  if (c >= '#39'0'#39') and (c <= '#39'9'#39') then'
      '    Result := Ord(c) - Ord('#39'0'#39')'
      '  else if (c >= '#39'A'#39') and (c <= '#39'F'#39') then'
      '    Result := Ord(c) - Ord('#39'A'#39') + 10'
      '  else if (c >= '#39'a'#39') and (c <= '#39'f'#39') then'
      '    Result := Ord(c) - Ord('#39'a'#39') + 10'
      '  else'
      '    Result := -1;'
      'end;'
      ''
      'function HexToColor(sHex: String): Integer;'
      'var'
      '  iOff, R, G, B, n0, n1, n2, n3, n4, n5: Integer;'
      'begin'
      '  Result := -1;'
      '  sHex := Trim(sHex);'
      '  if Length(sHex) < 6 then Exit;'
      '  if Copy(sHex, 1, 1) = '#39'#'#39' then iOff := 1 else iOff := 0;'
      '  if Length(sHex) < 6 + iOff then Exit;'
      '  n0 := HexNibble(sHex[iOff + 1]);'
      '  n1 := HexNibble(sHex[iOff + 2]);'
      '  n2 := HexNibble(sHex[iOff + 3]);'
      '  n3 := HexNibble(sHex[iOff + 4]);'
      '  n4 := HexNibble(sHex[iOff + 5]);'
      '  n5 := HexNibble(sHex[iOff + 6]);'
      
        '  if (n0 < 0) or (n1 < 0) or (n2 < 0) or (n3 < 0) or (n4 < 0) or' +
        ' (n5 < 0) then Exit;'
      '  R := n0 * 16 + n1;'
      '  G := n2 * 16 + n3;'
      '  B := n4 * 16 + n5;'
      '  Result := (B shl 16) or (G shl 8) or R;'
      'end;'
      ''
      'procedure EtiqColorOnBeforePrint(Sender: TfrxComponent);'
      'var'
      '  sHex: String;'
      '  c, R, G, B, Y: Integer;'
      '  m: TfrxMemoView;'
      'begin'
      '  m := TfrxMemoView(Sender);'
      '  sHex := <EtiquetasArt."HEX_ATR_CO">;'
      '  c := HexToColor(sHex);'
      '  if c < 0 then begin'
      '    m.Color := $00FFFFFF;'
      '    m.Font.Color := $00000000;'
      '    Exit;'
      '  end;'
      '  m.Color := c;'
      '  R := c and $FF;'
      '  G := (c shr 8) and $FF;'
      '  B := (c shr 16) and $FF;'
      '  Y := (R * 299 + G * 587 + B * 114) div 1000;'
      '  if Y < 140 then'
      '    m.Font.Color := $00FFFFFF'
      '  else'
      '    m.Font.Color := $00000000;'
      'end;'
      ''
      'procedure MasterData1OnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  // FZ-ISSUE-603: con lote, serie o temporada del lote, ese texto'
      '  // ocupa el sitio de la temporada del art'#237'culo.'
      '  EtiqLote.Visible :='
      '    VarToStr(<EtiquetasArt."TEXTO_LOTE_ETI">) <> '#39#39';'
      '  EtiqTemporada.Visible := not EtiqLote.Visible;'
      'end;'
      ''
      'begin'
      'end.')
    Left = 8
    Top = 8
    Datasets = <
      item
        DataSet = dmArticulos.fxdsEtiquetasArt
        DataSetName = 'EtiquetasArt'
      end>
    Variables = <>
    Style = <>
    inherited Page1: TfrxReportPage
      LeftMargin = 0.000000000000000000
      RightMargin = 0.000000000000000000
      TopMargin = 4.500000000000000000
      BottomMargin = 4.500000000000000000
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
        Height = 181.417440000000000000
        Top = 18.897650000000000000
        Width = 396.850650000000000000
        DataSet = dmArticulos.fxdsEtiquetasArt
        DataSetName = 'EtiquetasArt'
        RowCount = 0
        OnBeforePrint = 'MasterData1OnBeforePrint'
        object EtiqRefProv: TfrxMemoView
          AllowVectorExport = True
          Left = 210.000000000000000000
          Top = 4.000000000000000000
          Width = 180.000000000000000000
          Height = 18.000000000000000000
          DataField = 'REF_PROVEEDOR'
          DataSet = dmArticulos.fxdsEtiquetasArt
          DataSetName = 'EtiquetasArt'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[EtiquetasArt."REF_PROVEEDOR"]')
          ParentFont = False
        end
        object EtiqLblPrecio: TfrxMemoView
          AllowVectorExport = True
          Left = 8.000000000000000000
          Top = 34.000000000000000000
          Width = 55.000000000000000000
          Height = 16.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            'P.V.P')
          ParentFont = False
        end
        object EtiqPrecio: TfrxMemoView
          AllowVectorExport = True
          Left = 62.000000000000000000
          Top = 24.000000000000000000
          Width = 205.000000000000000000
          Height = 26.000000000000000000
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          DataField = 'PRECIO_FINAL_ARTTAR'
          DataSet = dmArticulos.fxdsEtiquetasArt
          DataSetName = 'EtiquetasArt'
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[EtiquetasArt."PRECIO_FINAL_ARTTAR"]')
          ParentFont = False
        end
        object EtiqPrecioUnidad: TfrxMemoView
          Left = 8.000000000000000000
          Top = 50.000000000000000000
          Width = 255.000000000000000000
          Height = 13.000000000000000000
          GapY = 0.000000000000000000
          DataField = 'PRECIO_UNIDAD_TEXTO'
          DataSet = dmArticulos.fxdsEtiquetasArt
          DataSetName = 'EtiquetasArt'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[EtiquetasArt."PRECIO_UNIDAD_TEXTO"]')
          ParentFont = False
        end
        object EtiqPestana: TfrxMemoView
          AllowVectorExport = True
          Left = 169.173160000000000000
          Top = 63.574830000000000000
          Width = 32.000000000000000000
          Height = 40.000000000000000000
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          DataField = 'ATR_PESTANA'
          DataSet = dmArticulos.fxdsEtiquetasArt
          DataSetName = 'EtiquetasArt'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Frame.Width = 1.500000000000000000
          HAlign = haCenter
          Memo.UTF8W = (
            '[EtiquetasArt."ATR_PESTANA"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object EtiqTalla: TfrxMemoView
          AllowVectorExport = True
          Left = 203.173160000000000000
          Top = 63.574830000000000000
          Width = 62.102350000000000000
          Height = 40.000000000000000000
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          DataField = 'ATR_TAL'
          DataSet = dmArticulos.fxdsEtiquetasArt
          DataSetName = 'EtiquetasArt'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Frame.Width = 1.500000000000000000
          HAlign = haCenter
          Memo.UTF8W = (
            '[EtiquetasArt."ATR_TAL"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object EtiqBarcode: TfrxBarCodeView
          AllowVectorExport = True
          Left = 8.000000000000000000
          Top = 66.000000000000000000
          Width = 149.763760000000000000
          Height = 42.000000000000000000
          AutoSize = False
          BarType = bcCode128A
          Expression = '<EtiquetasArt."CODIGO_BARRAS_CB">'
          Frame.Typ = []
          Rotation = 0
          TestLine = False
          Text = '0000000000000'
          WideBarRatio = 2.500000000000000000
          Zoom = 0.832020888888888900
          ColorBar = clBlack
          BarcodeText.TextSettings.BarTextPos = btpBottom
          BarcodeText.SupSettings.BarTextPos = btpTop
        end
        object EtiqCodArt: TfrxMemoView
          AllowVectorExport = True
          Left = 218.779530000000000000
          Top = 118.913420000000000000
          Width = 175.000000000000000000
          Height = 18.000000000000000000
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          DataField = 'CODIGO_ART_ART'
          DataSet = dmArticulos.fxdsEtiquetasArt
          DataSetName = 'EtiquetasArt'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[EtiquetasArt."CODIGO_ART_ART"]')
          ParentFont = False
        end
        object EtiqColor: TfrxMemoView
          AllowVectorExport = True
          Left = 8.000000000000000000
          Top = 116.000000000000000000
          Width = 204.362090000000000000
          Height = 22.000000000000000000
          OnBeforePrint = 'EtiqColorOnBeforePrint'
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          DataField = 'ATR_CO'
          DataSet = dmArticulos.fxdsEtiquetasArt
          DataSetName = 'EtiquetasArt'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            '[EtiquetasArt."ATR_CO"]')
          ParentFont = False
          VAlign = vaCenter
        end
        object EtiqDescArt: TfrxMemoView
          AllowVectorExport = True
          Left = 8.000000000000000000
          Top = 144.000000000000000000
          Width = 382.000000000000000000
          Height = 18.000000000000000000
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          DataField = 'DESCRIPCION_ART'
          DataSet = dmArticulos.fxdsEtiquetasArt
          DataSetName = 'EtiquetasArt'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[EtiquetasArt."DESCRIPCION_ART"]')
          ParentFont = False
        end
        object EtiqLote: TfrxMemoView
          AllowVectorExport = True
          Left = 8.000000000000000000
          Top = 163.500000000000000000
          Width = 150.000000000000000000
          Height = 15.000000000000000000
          DataField = 'TEXTO_LOTE_ETI'
          DataSet = dmArticulos.fxdsEtiquetasArt
          DataSetName = 'EtiquetasArt'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[EtiquetasArt."TEXTO_LOTE_ETI"]')
          ParentFont = False
          WordWrap = False
        end
        object EtiqTemporada: TfrxMemoView
          AllowVectorExport = True
          Left = 8.000000000000000000
          Top = 163.500000000000000000
          Width = 150.000000000000000000
          Height = 15.000000000000000000
          DataField = 'COD_TEMPORADA'
          DataSet = dmArticulos.fxdsEtiquetasArt
          DataSetName = 'EtiquetasArt'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[EtiquetasArt."COD_TEMPORADA"]')
          ParentFont = False
        end
        object foto300: TfrxPictureView
          AllowVectorExport = True
          Left = 272.346631460000000000
          Top = 26.456708240000000000
          Width = 117.165422250000000000
          Height = 86.929189920000000000
          Frame.Typ = []
          HightQuality = False
          Transparent = False
          TransparentColor = clWhite
        end
        object Memo1: TfrxMemoView
          AllowVectorExport = True
          Left = 2.015749359130859000
          Top = 1.259843082682292000
          Width = 201.574940745035800000
          Height = 20.157493082682290000
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          ParentFont = False
        end
      end
    end
  end
end
