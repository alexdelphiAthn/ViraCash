inherited frmPrintFac: TfrmPrintFac
  Caption = 'Imprimir Borrador'
  ClientHeight = 249
  ClientWidth = 412
  Position = poMainFormCenter
  ExplicitWidth = 428
  ExplicitHeight = 288
  TextHeight = 17
  inherited pnl1: TPanel
    Left = 258
    Width = 154
    Height = 249
    ExplicitLeft = 256
    ExplicitWidth = 154
    ExplicitHeight = 241
    inherited btnPDF: TcxButton
      Left = 11
      ExplicitLeft = 11
    end
    inherited btnImprimir: TcxButton
      Left = 11
      ExplicitLeft = 11
    end
    inherited btnVistaPreliminar: TcxButton
      Left = 11
      ExplicitLeft = 11
    end
    inherited btnSalir: TcxButton
      Top = 223
      Width = 152
      ExplicitTop = 215
      ExplicitWidth = 152
    end
    inherited btnEditar: TcxButton
      Left = 11
      ExplicitLeft = 11
    end
    inherited btnExcel: TcxButton
      Left = 11
      ExplicitLeft = 11
    end
  end
  object edtNroFac: TcxTextEdit [1]
    Left = 104
    Top = 24
    Enabled = False
    TabOrder = 1
    Width = 105
  end
  object lblcxlbl1: TcxLabel [2]
    Left = 8
    Top = 4
    Caption = 'Borrador N'#250'mero'
    TabOrder = 2
    Transparent = True
  end
  object edtSerie: TcxTextEdit [3]
    Left = 8
    Top = 24
    Enabled = False
    TabOrder = 3
    Width = 90
  end
  object cxrdgrp1: TcxRadioGroup [4]
    Left = 8
    Top = 56
    Caption = 'Opciones'
    Properties.Items = <>
    TabOrder = 4
    Height = 81
    Width = 242
    object rbActual: TcxRadioButton
      Left = 8
      Top = 24
      Width = 223
      Height = 17
      Caption = 'Imprimir Borrador actual'
      Checked = True
      TabOrder = 0
      TabStop = True
      OnClick = rbActualClick
      Transparent = True
    end
    object rbProcesarFiltrados: TcxRadioButton
      Left = 8
      Top = 48
      Width = 223
      Height = 17
      Caption = 'Procesar filtrados'
      TabOrder = 1
      OnClick = rbProcesarFiltradosClick
      Transparent = True
    end
  end
  object chkEnviarEmail: TcxCheckBox [5]
    Left = 8
    Top = 150
    Caption = 'Enviar por email'
    Properties.OnEditValueChanged = chkEnviarEmailPropertiesEditValueChanged
    TabOrder = 5
    Transparent = True
    Visible = False
  end
  inherited Localizer1: TcxLocalizer
    Left = 128
    Top = 144
  end
  inherited frxrprt1: TfrxReport
    ReportOptions.LastChange = 45266.651521481500000000
    ScriptText.Strings = (
      'procedure RetencionTotalOnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  if <Facturas."TOTAL_RETENCION_FAC"> <> 0 then'
      '  begin'
      '    RetencionTotal.Visible := True;'
      '    Retencion.Visible:= True;'
      '  end'
      '  else'
      '  begin'
      '    RetencionTotal.Visible := False;'
      '    Retencion.Visible := False;'
      '  end;'
      'end;'
      ''
      'procedure ImpuestosTotalOnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  if <Facturas."TOTAL_IMPUESTOS_FAC"> <> 0 then'
      '  begin'
      '    ImpuestosTotal.Visible := True;'
      '    Impuestos.Visible:= True;'
      '  end'
      '  else'
      '  begin'
      '    ImpuestosTotal.Visible := False;'
      '    Impuestos.Visible := False;'
      '  end;'
      'end;'
      ''
      'procedure BaseImponibleNOnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  if <Facturas."TOTAL_BASEI_IVAN_FAC"> <> 0 then'
      '  begin'
      '    BaseImponibleN.Visible := True;'
      '    FacturasTOTAL_IVAN_FACTURA.Visible := True;'
      '    FacturasPORCEN_IVAN_FACTURA.Visible:= True;'
      '  end'
      '  else'
      '  begin'
      '    BaseImponibleN.Visible := False;'
      '    FacturasTOTAL_IVAN_FACTURA.Visible := False;'
      '    FacturasPORCEN_IVAN_FACTURA.Visible:= False;'
      '  end;'
      'end;'
      ''
      'procedure BaseImponibleROnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  if <Facturas."TOTAL_BASEI_IVAR_FAC"> <> 0 then'
      '  begin'
      '    BaseImponibleR.Visible := True;'
      '    FacturasTOTAL_IVAR_FACTURA.Visible := True;'
      '    FacturasPORCEN_IVAR_FACTURA.Visible:= True;'
      '  end'
      '  else'
      '  begin'
      '    BaseImponibleR.Visible := False;'
      '    FacturasTOTAL_IVAR_FACTURA.Visible := False;'
      '    FacturasPORCEN_IVAR_FACTURA.Visible:= False;'
      '  end;'
      'end;'
      ''
      'procedure BaseImponibleSOnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  if <Facturas."TOTAL_BASEI_IVAS_FAC"> <> 0 then'
      '  begin'
      '    BaseImponibleS.Visible := True;'
      '    FacturasTOTAL_IVAS_FACTURA.Visible := True;'
      '    FacturasPORCEN_IVAS_FACTURA.Visible:= True;'
      '  end'
      '  else'
      '  begin'
      '    BaseImponibleS.Visible := False;'
      '    FacturasTOTAL_IVAS_FACTURA.Visible := False;'
      '    FacturasPORCEN_IVAS_FACTURA.Visible:= False;'
      '  end;'
      'end;'
      ''
      'procedure BaseImponibleEOnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '    if <Facturas."TOTAL_BASEI_IVAE_FAC"> <> 0 then'
      '  begin'
      '    BaseImponibleE.Visible := True;'
      '    FacturasTOTAL_IVAE_FACTURA.Visible := True;'
      '    FacturasPORCEN_IVAE_FACTURA.Visible:= True;'
      '  end'
      '  else'
      '  begin'
      '    BaseImponibleE.Visible := False;'
      '    FacturasTOTAL_IVAE_FACTURA.Visible := False;'
      '    FacturasPORCEN_IVAE_FACTURA.Visible:= False;'
      '  end;'
      
        '  if (<Facturas."TOTAL_BASEI_IVAE_FAC"> = <Facturas."TOTAL_BASES' +
        '_FAC">) then'
      '  begin'
      '    CajaIVA.Visible := False;'
      '    CajaTitulosIVA.Visible := False;'
      '    BaseImponibleE.Visible := False;'
      '    TituloPorcenCajaIVA.Visible := False;'
      '    FacturasPORCEN_IVAE_FACTURA.Visible := False;'
      '    FacturasTOTAL_IVAE_FACTURA.Visible := False;'
      '    BaseImponibleCajaIVA.Visible := False;'
      '    TituloTotalCajaIVA.Visible := False;'
      '  end;'
      'end;'
      ''
      
        'procedure FacturasTOTAL_REN_FACTURAOnBeforePrint(Sender: TfrxCom' +
        'ponent);'
      'begin'
      '  if <Facturas."TOTAL_REN_FAC"> <> 0 then'
      '  begin'
      '    FacturasPORCEN_REN_FACTURA.Visible := True;'
      '    FacturasTOTAL_REN_FACTURA.Visible := True;'
      '  end'
      '  else'
      '  begin'
      '    FacturasPORCEN_REN_FACTURA.Visible := False;'
      '    FacturasTOTAL_REN_FACTURA.Visible := False;'
      '  end;'
      'end;'
      ''
      
        'procedure FacturasTOTAL_RER_FACTURAOnBeforePrint(Sender: TfrxCom' +
        'ponent);'
      'begin'
      '  if <Facturas."TOTAL_RER_FAC"> <> 0 then'
      '  begin'
      '    FacturasPORCEN_RER_FACTURA.Visible := True;'
      '    FacturasTOTAL_RER_FACTURA.Visible := True;'
      '  end'
      '  else'
      '  begin'
      '    FacturasPORCEN_RER_FACTURA.Visible := False;'
      '    FacturasTOTAL_RER_FACTURA.Visible := False;'
      '  end;'
      ''
      'end;'
      ''
      
        'procedure FacturasTOTAL_RES_FACTURAOnBeforePrint(Sender: TfrxCom' +
        'ponent);'
      'begin'
      '  if <Facturas."TOTAL_RES_FAC"> <> 0 then'
      '  begin'
      '    FacturasPORCEN_RES_FACTURA.Visible := True;'
      '    FacturasTOTAL_RES_FACTURA.Visible := True;'
      '  end'
      '  else'
      '  begin'
      '    FacturasPORCEN_RES_FACTURA.Visible := False;'
      '    FacturasTOTAL_RES_FACTURA.Visible := False;'
      '  end;'
      ''
      'end;'
      ''
      
        'procedure FacturasTOTAL_REE_FACTURAOnBeforePrint(Sender: TfrxCom' +
        'ponent);'
      'begin'
      '    if <Facturas."TOTAL_REE_FAC"> <> 0 then'
      '  begin'
      '    FacturasPORCEN_REE_FACTURA.Visible := True;'
      '    FacturasTOTAL_REE_FACTURA.Visible := True;'
      '  end'
      '  else'
      '  begin'
      '    FacturasPORCEN_REE_FACTURA.Visible := False;'
      '    FacturasTOTAL_REE_FACTURA.Visible := False;'
      '  end;'
      ''
      'end;'
      ''
      'procedure RetencionPorcOnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  If ((<Facturas."TOTAL_REE_FAC"> = 0) and'
      '      (<Facturas."TOTAL_RES_FAC"> = 0) and'
      '      (<Facturas."TOTAL_RER_FAC"> = 0) and'
      '      (<Facturas."TOTAL_REN_FAC"> = 0)) then'
      '  begin'
      '    RetencionPorc.Visible := False;'
      '    RetencionTot.Visible := False;'
      '  end'
      '  else'
      '  begin'
      '    RetencionPorc.Visible := True;'
      '    RetencionTot.Visible := True;'
      '  end;'
      'end;'
      ''
      'procedure PageFooter1OnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  FacturasPORCEN_REN_FACTURA.Visible :='
      '    <Facturas."TOTAL_REN_FAC"> <> 0;'
      '  FacturasTOTAL_REN_FACTURA.Visible :='
      '    <Facturas."TOTAL_REN_FAC"> <> 0;'
      '  FacturasPORCEN_RER_FACTURA.Visible :='
      '    <Facturas."TOTAL_RER_FAC"> <> 0;'
      '  FacturasTOTAL_RER_FACTURA.Visible :='
      '    <Facturas."TOTAL_RER_FAC"> <> 0;'
      '  FacturasPORCEN_RES_FACTURA.Visible :='
      '    <Facturas."TOTAL_RES_FAC"> <> 0;'
      '  FacturasTOTAL_RES_FACTURA.Visible :='
      '    <Facturas."TOTAL_RES_FAC"> <> 0;'
      '  FacturasPORCEN_REE_FACTURA.Visible :='
      '    <Facturas."TOTAL_REE_FAC"> <> 0;'
      '  FacturasTOTAL_REE_FACTURA.Visible :='
      '    <Facturas."TOTAL_REE_FAC"> <> 0;'
      '   Engine.CurY := (20.5 * fr1cm);  '
      'end;'
      ''
      'procedure DetailData1OnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  If (<Facturas."ESFECHADEENTREGA_FAC"> <> '#39'S'#39') then'
      '   begin              '
      
        '    // LineasFacturasDESCRIPCION_ARTICULO_FACTURA_LINEA.Width :=' +
        ' 76;                                                            ' +
        '                        '
      
        '    LineasFacturasFECHA_ENTREGA_FACTURA_LINEA.Visible := False; ' +
        '                                             '
      '  end'
      '  else            '
      '  begin              '
      
        '    // LineasFacturasDESCRIPCION_ARTICULO_FACTURA_LINEA.Width :=' +
        ' 98;        '
      
        '    LineasFacturasFECHA_ENTREGA_FACTURA_LINEA.Visible := True;  ' +
        '                                          '
      '  end;  '
      'end;'
      
        'procedure FechaEntregaTittleOnBeforePrint(Sender: TfrxComponent)' +
        ';'
      'begin'
      '  If (<Facturas."ESFECHADEENTREGA_FAC"> <> '#39'S'#39') then'
      '    FechaEntregaTittle.Visible := False'
      '  else'
      '    FechaEntregaTittle.Visible := True;                 '
      'end;'
      ''
      'begin                          '
      'end.')
    Left = 336
    Top = 176
    Datasets = <
      item
        DataSet = dmFacturas.fxdsPrintFac
        DataSetName = 'Facturas'
      end
      item
        DataSet = dmFacturas.fxdstPrintLinFac
        DataSetName = 'Lineas Facturas'
      end>
    Variables = <>
    Style = <>
    inherited Data: TfrxDataPage
      object FacturasTOTAL_RER_FACTURA: TfrxMemoView
        IndexTag = 1
        AllowVectorExport = True
        Left = 398.409710000000100000
        Top = 504.031540000000000000
        Width = 64.252010000000000000
        Height = 18.897650000000000000
        OnBeforePrint = 'FacturasTOTAL_RER_FACTURAOnBeforePrint'
        DataField = 'TOTAL_RER_FAC'
        DisplayFormat.DecimalSeparator = ','
        DisplayFormat.FormatStr = '%2.3m'
        DisplayFormat.Kind = fkNumeric
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -14
        Font.Name = 'Arial'
        Font.Style = []
        Frame.Typ = []
        HAlign = haRight
        Memo.UTF8W = (
          '[Facturas."TOTAL_RER_FAC"]')
        ParentFont = False
      end
      object FacturasTOTAL_RES_FACTURA: TfrxMemoView
        IndexTag = 1
        AllowVectorExport = True
        Left = 398.409710000000100000
        Top = 530.488250000000000000
        Width = 64.252010000000000000
        Height = 18.897650000000000000
        OnBeforePrint = 'FacturasTOTAL_RES_FACTURAOnBeforePrint'
        DataField = 'TOTAL_RES_FAC'
        DisplayFormat.DecimalSeparator = ','
        DisplayFormat.FormatStr = '%2.3m'
        DisplayFormat.Kind = fkNumeric
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -14
        Font.Name = 'Arial'
        Font.Style = []
        Frame.Typ = []
        HAlign = haRight
        Memo.UTF8W = (
          '[Facturas."TOTAL_RES_FAC"]')
        ParentFont = False
      end
    end
    inherited Page1: TfrxReportPage
    end
  end
  inherited frxpdfxprtPedWeb: TfrxPDFExport
    FileName = 'C:\Users\34667\OneDrive\Escritorio\FACTURA KIOSCO.pdf'
    CreationTime = 45274.521397164350000000
    Author = 'ViraCash Report System'
    Left = 232
    Top = 200
  end
  inherited frxlsxprtExcel: TfrxXLSXExport
    CreationTime = 44864.742612013880000000
    Left = 304
    Top = 160
  end
  inherited frxdsgnr1: TfrxDesigner
    Left = 8
    Top = 128
  end
  inherited frxReportOrigen: TfrxReport
    EngineOptions.DoublePass = True
    PreviewOptions.AllowEdit = False
    PreviewOptions.AllowPreviewEdit = False
    PreviewOptions.Buttons = [pbPrint, pbLoad, pbSave, pbExport, pbZoom, pbFind, pbOutline, pbPageSetup, pbTools, pbNavigator, pbExportQuick]
    ReportOptions.LastChange = 46186.689456250000000000
    ScriptText.Strings = (
      'procedure RetencionTotalOnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  if <Facturas."TOTAL_RETENCION_FAC"> <> 0 then'
      '  begin'
      '    txtRetencionTotal.Visible := True;'
      '    Retencion.Visible:= True;'
      '  end'
      '  else'
      '  begin'
      '    txtRetencionTotal.Visible := False;'
      '    Retencion.Visible := False;'
      '  end;'
      'end;'
      ''
      'procedure ImpuestosTotalOnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  if <Facturas."TOTAL_IMPUESTOS_FAC"> <> 0 then'
      '  begin'
      '    ImpuestosTotal.Visible := True;'
      '    Impuestos.Visible:= True;'
      '  end'
      '  else'
      '  begin'
      '    ImpuestosTotal.Visible := False;'
      '    Impuestos.Visible := False;'
      '  end;'
      'end;'
      ''
      'procedure BaseImponibleNOnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  if <Facturas."TOTAL_BASEI_IVAN_FAC"> <> 0 then'
      '  begin'
      '    BaseImponibleN.Visible := True;'
      '    FacturasTOTAL_IVAN_FACTURA.Visible := True;'
      '    FacturasPORCEN_IVAN_FACTURA.Visible:= True;'
      '  end'
      '  else'
      '  begin'
      '    BaseImponibleN.Visible := False;'
      '    FacturasTOTAL_IVAN_FACTURA.Visible := False;'
      '    FacturasPORCEN_IVAN_FACTURA.Visible:= False;'
      '  end;'
      'end;'
      ''
      'procedure BaseImponibleROnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  if <Facturas."TOTAL_BASEI_IVAR_FAC"> <> 0 then'
      '  begin'
      '    BaseImponibleR.Visible := True;'
      '    FacturasTOTAL_IVAR_FACTURA.Visible := True;'
      '    FacturasPORCEN_IVAR_FACTURA.Visible:= True;'
      '  end'
      '  else'
      '  begin'
      '    BaseImponibleR.Visible := False;'
      '    FacturasTOTAL_IVAR_FACTURA.Visible := False;'
      '    FacturasPORCEN_IVAR_FACTURA.Visible:= False;'
      '  end;'
      'end;'
      ''
      'procedure BaseImponibleSOnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  if <Facturas."TOTAL_BASEI_IVAS_FAC"> <> 0 then'
      '  begin'
      '    BaseImponibleS.Visible := True;'
      '    FacturasTOTAL_IVAS_FACTURA.Visible := True;'
      '    FacturasPORCEN_IVAS_FACTURA.Visible:= True;'
      '  end'
      '  else'
      '  begin'
      '    BaseImponibleS.Visible := False;'
      '    FacturasTOTAL_IVAS_FACTURA.Visible := False;'
      '    FacturasPORCEN_IVAS_FACTURA.Visible:= False;'
      '  end;'
      'end;'
      ''
      'procedure BaseImponibleEOnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '    if <Facturas."TOTAL_BASEI_IVAE_FAC"> <> 0 then'
      '  begin'
      '    BaseImponibleE.Visible := True;'
      '    FacturasTOTAL_IVAE_FACTURA.Visible := True;'
      '    FacturasPORCEN_IVAE_FACTURA.Visible:= True;'
      '  end'
      '  else'
      '  begin'
      '    BaseImponibleE.Visible := False;'
      '    FacturasTOTAL_IVAE_FACTURA.Visible := False;'
      '    FacturasPORCEN_IVAE_FACTURA.Visible:= False;'
      '  end;'
      
        '  if (<Facturas."TOTAL_BASEI_IVAE_FAC"> = <Facturas."TOTAL_BASES' +
        '_FAC">) then'
      '  begin'
      '    CajaIVA.Visible := False;'
      '    CajaTitulosIVA.Visible := False;'
      '    BaseImponibleE.Visible := False;'
      '    TituloPorcenCajaIVA.Visible := False;'
      '    FacturasPORCEN_IVAE_FACTURA.Visible := False;'
      '    FacturasTOTAL_IVAE_FACTURA.Visible := False;'
      '    BaseImponibleCajaIVA.Visible := False;'
      '    TituloTotalCajaIVA.Visible := False;'
      '  end;'
      'end;'
      ''
      
        'procedure FacturasTOTAL_REN_FACTURAOnBeforePrint(Sender: TfrxCom' +
        'ponent);'
      'begin'
      '  if <Facturas."TOTAL_REN_FAC"> <> 0 then'
      '  begin'
      '    FacturasPORCEN_REN_FACTURA.Visible := True;'
      '    FacturasTOTAL_REN_FACTURA.Visible := True;'
      '  end'
      '  else'
      '  begin'
      '    FacturasPORCEN_REN_FACTURA.Visible := False;'
      '    FacturasTOTAL_REN_FACTURA.Visible := False;'
      '  end;'
      'end;'
      ''
      
        'procedure FacturasTOTAL_RER_FACTURAOnBeforePrint(Sender: TfrxCom' +
        'ponent);'
      'begin'
      '  if <Facturas."TOTAL_RER_FAC"> <> 0 then'
      '  begin'
      '    FacturasPORCEN_RER_FACTURA.Visible := True;'
      '    FacturasTOTAL_RER_FACTURA.Visible := True;'
      '  end'
      '  else'
      '  begin'
      '    FacturasPORCEN_RER_FACTURA.Visible := False;'
      '    FacturasTOTAL_RER_FACTURA.Visible := False;'
      '  end;'
      ''
      'end;'
      ''
      
        'procedure FacturasTOTAL_RES_FACTURAOnBeforePrint(Sender: TfrxCom' +
        'ponent);'
      'begin'
      '  if <Facturas."TOTAL_RES_FAC"> <> 0 then'
      '  begin'
      '    FacturasPORCEN_RES_FACTURA.Visible := True;'
      '    FacturasTOTAL_RES_FACTURA.Visible := True;'
      '  end'
      '  else'
      '  begin'
      '    FacturasPORCEN_RES_FACTURA.Visible := False;'
      '    FacturasTOTAL_RES_FACTURA.Visible := False;'
      '  end;'
      ''
      'end;'
      ''
      
        'procedure FacturasTOTAL_REE_FACTURAOnBeforePrint(Sender: TfrxCom' +
        'ponent);'
      'begin'
      '    if <Facturas."TOTAL_REE_FAC"> <> 0 then'
      '  begin'
      '    FacturasPORCEN_REE_FACTURA.Visible := True;'
      '    FacturasTOTAL_REE_FACTURA.Visible := True;'
      '  end'
      '  else'
      '  begin'
      '    FacturasPORCEN_REE_FACTURA.Visible := False;'
      '    FacturasTOTAL_REE_FACTURA.Visible := False;'
      '  end;'
      ''
      'end;'
      ''
      'procedure RetencionPorcOnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  If ((<Facturas."TOTAL_REE_FAC"> = 0) and'
      '      (<Facturas."TOTAL_RES_FAC"> = 0) and'
      '      (<Facturas."TOTAL_RER_FAC"> = 0) and'
      '      (<Facturas."TOTAL_REN_FAC"> = 0)) then'
      '  begin'
      '    RetencionPorc.Visible := False;'
      '    RetencionTot.Visible := False;'
      '  end'
      '  else'
      '  begin'
      '    RetencionPorc.Visible := True;'
      '    RetencionTot.Visible := True;'
      '  end;'
      'end;'
      ''
      'procedure PageFooter1OnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  FacturasPORCEN_REN_FACTURA.Visible :='
      '    <Facturas."TOTAL_REN_FAC"> <> 0;'
      '  FacturasTOTAL_REN_FACTURA.Visible :='
      '    <Facturas."TOTAL_REN_FAC"> <> 0;'
      '  FacturasPORCEN_RER_FACTURA.Visible :='
      '    <Facturas."TOTAL_RER_FAC"> <> 0;'
      '  FacturasTOTAL_RER_FACTURA.Visible :='
      '    <Facturas."TOTAL_RER_FAC"> <> 0;'
      '  FacturasPORCEN_RES_FACTURA.Visible :='
      '    <Facturas."TOTAL_RES_FAC"> <> 0;'
      '  FacturasTOTAL_RES_FACTURA.Visible :='
      '    <Facturas."TOTAL_RES_FAC"> <> 0;'
      '  FacturasPORCEN_REE_FACTURA.Visible :='
      '    <Facturas."TOTAL_REE_FAC"> <> 0;'
      '  FacturasTOTAL_REE_FACTURA.Visible :='
      '    <Facturas."TOTAL_REE_FAC"> <> 0;'
      '  if ((<TotalPages> > 1) and (<Page> <> <TotalPages>)) then'
      '  begin'
      '    CajaTitulosIVA.Visible := False;'
      '    BaseImponibleCajaIVA.Visible := False;'
      '    TituloPorcenCajaIVA.Visible := False;'
      '    TituloTotalCajaIVA.Visible := False;'
      '    TotalBases.Visible := False;'
      '    Impuestos.Font.Color := clWhite;'
      '    ImpuestosTotal.Font.Color := clWhite;'
      '    RetencionTot.Font.Color := clWhite;'
      '    mTotalFactura.Visible := False;'
      '    mTotalFacturaCtd.Visible := False;'
      '    txtRetencionTotal.Font.Color := clWhite;'
      '    Retencion.Font.Color := clWhite;'
      '    RetencionPorc.Font.Color := clWhite;'
      '    CajaIVA.Visible := False;'
      '    FormaPago.Visible := False;'
      '    Continua.Visible := True;'
      '    BaseImponibleN.Font.Color := clWhite;'
      '    BaseImponibleR.Font.Color := clWhite;'
      '    BaseImponibleS.Font.Color := clWhite;'
      '    BaseImponibleE.Font.Color := clWhite;'
      '    TotalBaseImponible.Visible := False;'
      '    FacturasPORCEN_IVAN_FACTURA.Font.Color := clWhite;'
      '    FacturasPORCEN_IVAR_FACTURA.Font.Color := clWhite;'
      '    FacturasPORCEN_IVAS_FACTURA.Font.Color := clWhite;'
      '    FacturasPORCEN_IVAE_FACTURA.Font.Color := clWhite;'
      '    FacturasTOTAL_IVAN_FACTURA.Font.Color := clWhite;'
      '    FacturasTOTAL_IVAR_FACTURA.Font.Color := clWhite;'
      '    FacturasTOTAL_IVAS_FACTURA.Font.Color := clWhite;'
      '    FacturasTOTAL_IVAE_FACTURA.Font.Color := clWhite;'
      '    FacturasPORCEN_REN_FACTURA.Font.Color := clWhite;'
      '    FacturasPORCEN_RER_FACTURA.Font.Color := clWhite;'
      '    FacturasPORCEN_RES_FACTURA.Font.Color := clWhite;'
      '    FacturasPORCEN_REE_FACTURA.Font.Color := clWhite;'
      '    FacturasTOTAL_REN_FACTURA.Font.Color := clWhite;'
      '    FacturasTOTAL_RER_FACTURA.Font.Color := clWhite;'
      '    FacturasTOTAL_RES_FACTURA.Font.Color := clWhite;'
      '    FacturasTOTAL_REE_FACTURA.Font.Color := clWhite;'
      '    FacturasTOTAL_RER_FACTURA.Font.Color := clWhite;'
      '    FacturasTOTAL_RES_FACTURA.Font.Color := clWhite;'
      '  end'
      '  else'
      '  begin'
      '    Continua.Visible := False;'
      '    CajaTitulosIVA.Visible := True;'
      '    BaseImponibleCajaIVA.Visible := True;'
      '    TituloPorcenCajaIVA.Visible := True;'
      '    TituloTotalCajaIVA.Visible := True;'
      '    TotalBases.Visible := True;'
      '    Impuestos.Font.Color := clBlack;'
      '    ImpuestosTotal.Font.Color := clBlack;'
      '    RetencionTot.Font.Color := clBlack;'
      '    mTotalFactura.Visible := True;'
      '    mTotalFacturaCtd.Visible := True;'
      '    CajaIVA.Visible := True;'
      '    txtRetencionTotal.Font.Color := clBlack;'
      '    Retencion.Font.Color := clBlack;'
      '    RetencionPorc.Font.Color := clBlack;'
      '    FormaPago.Visible := True;'
      '    BaseImponibleN.Font.Color := clBlack;'
      '    BaseImponibleR.Font.Color := clBlack;'
      '    BaseImponibleS.Font.Color := clBlack;'
      '    BaseImponibleE.Font.Color := clBlack;'
      '    TotalBaseImponible.Visible := True;'
      '    FacturasPORCEN_IVAN_FACTURA.Font.Color := clBlack;'
      '    FacturasPORCEN_IVAR_FACTURA.Font.Color := clBlack;'
      '    FacturasPORCEN_IVAS_FACTURA.Font.Color := clBlack;'
      '    FacturasPORCEN_IVAE_FACTURA.Font.Color := clBlack;'
      '    FacturasTOTAL_IVAN_FACTURA.Font.Color := clBlack;'
      '    FacturasTOTAL_IVAR_FACTURA.Font.Color := clBlack;'
      '    FacturasTOTAL_IVAS_FACTURA.Font.Color := clBlack;'
      '    FacturasTOTAL_IVAE_FACTURA.Font.Color := clBlack;'
      '    FacturasPORCEN_REN_FACTURA.Font.Color := clBlack;'
      '    FacturasPORCEN_RER_FACTURA.Font.Color := clBlack;'
      '    FacturasPORCEN_RES_FACTURA.Font.Color := clBlack;'
      '    FacturasPORCEN_REE_FACTURA.Font.Color := clBlack;'
      '    FacturasTOTAL_REN_FACTURA.Font.Color := clBlack;'
      '    FacturasTOTAL_RER_FACTURA.Font.Color := clBlack;'
      '    FacturasTOTAL_RES_FACTURA.Font.Color := clBlack;'
      '    FacturasTOTAL_REE_FACTURA.Font.Color := clBlack;'
      '    FacturasTOTAL_RER_FACTURA.Font.Color := clBlack;'
      '    FacturasTOTAL_RES_FACTURA.Font.Color := clBlack;'
      '  end;'
      'end;'
      ''
      'procedure DetailData1OnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  If (<Facturas."ESFECHADEENTREGA_FAC"> <> '#39'S'#39') then'
      '   begin'
      
        '    // LineasFacturasDESCRIPCION_ARTICULO_FACTURA_LINEA.Width :=' +
        ' 76;'
      '    LineasFacturasFECHA_ENTREGA_FACTURA_LINEA.Visible := False;'
      '  end'
      '  else'
      '  begin'
      
        '    // LineasFacturasDESCRIPCION_ARTICULO_FACTURA_LINEA.Width :=' +
        ' 98;'
      '    LineasFacturasFECHA_ENTREGA_FACTURA_LINEA.Visible := True;'
      '  end;'
      'end;'
      
        'procedure FechaEntregaTittleOnBeforePrint(Sender: TfrxComponent)' +
        ';'
      'begin'
      '  If (<Facturas."ESFECHADEENTREGA_FAC"> <> '#39'S'#39') then'
      '    FechaEntregaTittle.Visible := False'
      '  else'
      '    FechaEntregaTittle.Visible := True;'
      'end;'
      ''
      
        'procedure FacturasPROVINCIA_EMPRESA_FACTURAOnBeforePrint(Sender:' +
        ' TfrxComponent);'
      'begin'
      
        '  IF (<Facturas."POBLACION_EMPRESA_FAC"> = <Facturas."PROVINCIA_' +
        'EMPRESA_FAC">) then'
      '    FacturasPROVINCIA_EMPRESA_FACTURA.Visible := False'
      '  else'
      '    FacturasPROVINCIA_EMPRESA_FACTURA.Visible := True;'
      'end;'
      ''
      ''
      
        'procedure FacturasPROVINCIA_CLIENTE_FACTURAOnBeforePrint(Sender:' +
        ' TfrxComponent);'
      'begin'
      
        '  IF (<Facturas."POBLACION_CLIENTE_FAC"> = <Facturas."PROVINCIA_' +
        'CLIENTE_FAC">) then'
      '    FacturasPROVINCIA_CLIENTE_FACTURA.Visible := False'
      '  else'
      '    FacturasPROVINCIA_CLIENTE_FACTURA.Visible := True;'
      'end;'
      ''
      'procedure ImpuestosOnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  If ((<Facturas."TOTAL_REE_FAC"> = 0) and'
      '      (<Facturas."TOTAL_RES_FAC"> = 0) and'
      '      (<Facturas."TOTAL_RER_FAC"> = 0) and'
      '      (<Facturas."TOTAL_REN_FAC"> = 0)) then'
      
        '    Impuestos.Memo.Text := '#39'Total [Facturas."PALABRA_REPORTS_ZON' +
        'A_IVA_FAC"]'#39
      '  else'
      
        '    Impuestos.Memo.Text := '#39'Total [Facturas."PALABRA_REPORTS_ZON' +
        'A_IVA_FAC"] + R.E.'#39
      'end;'
      ''
      'procedure mNumPaginasOnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  if (<TotalPages> > 1) then'
      '    mNumPaginas.Visible := True'
      '  else'
      '    mNumPaginas.Visible := False;'
      'end;'
      ''
      'procedure FormaPagoOnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  if ((<Facturas."ESVERBANCOEMPRESA_FORMA_PAGO_FP"> = '#39'S'#39') and'
      '      (<Facturas."ESCONTADO_FORMA_PAGO_FP"> = '#39'N'#39') and'
      '      (<Facturas."IBAN_EMP"> <> '#39#39'))  then'
      
        '    FormaPago.Memo.Text := Trim(FormaPago.Memo.Text) + '#39'     '#39' +' +
        ' <Facturas."IBAN_EMP">;'
      '  if ((<Facturas."ESVERBANCOEMPRESA_FORMA_PAGO_FP"> = '#39'N'#39') and'
      '      (<Facturas."ESCONTADO_FORMA_PAGO_FP"> = '#39'N'#39') and'
      '      (<Facturas."IBAN_CLI"> <> '#39#39')) then'
      
        '    FormaPago.Memo.Text := Trim(FormaPago.Memo.Text) + '#39'     '#39' +' +
        ' <Facturas."IBAN_CLI">;'
      '  if (<Facturas."VENCIMIENTOS_RECIBOS"> <> '#39#39') then'
      
        '    FormaPago.Memo.Text := FormaPago.Memo.Text + '#39'Vencimiento/s:' +
        ' '#39' + <Facturas."VENCIMIENTOS_RECIBOS">;'
      
        'end;procedure LineasFacturasTOTAL_LINEAOnBeforePrint(Sender: Tfr' +
        'xComponent);'
      'begin'
      '  // Sin IVA aunque la tarifa lo incluya: la factura desglosa'
      '  // la base y el IVA, y la suma de lineas debe dar la base.'
      '  LineasFacturasTOTAL_LINEA.Memo.Text :='
      '    '#39'[<Lineas Facturas."CANTIDAD_FACLIN"> * '#39' +'
      '    '#39'<Lineas Facturas."PRECIO_VENTA_SIVA_ARTICULO_FACLIN">]'#39';'
      'end;'
      ''
      
        'procedure PrecioUnitarioLineasFacturasOnBeforePrint(Sender: Tfrx' +
        'Component);'
      'begin'
      '  // Precio unitario sin IVA, como el total de la linea.'
      '  PrecioUnitarioLineasFacturas.Memo.Text :='
      '    '#39'[<Lineas Facturas."PRECIO_VENTA_SIVA_ARTICULO_FACLIN">]'#39';'
      'end;'
      ''
      'procedure GroupHeaderOperacionCajaOnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  // Solo las lineas de traspasos vendidos (TA) tienen operacion.'
      '  GroupHeaderOperacionCaja.Visible :='
      '    (<Lineas Facturas."ESFACTURA_TA_CAJA"> = '#39'S'#39');'
      '  MemoEtiquetaFechaOperacionCaja.Visible :='
      '    not VarIsNull(<Lineas Facturas."FECHA_OPERACION_CAJA">);'
      '  MemoFechaOperacionCaja.Visible :='
      '    MemoEtiquetaFechaOperacionCaja.Visible;'
      'end;'
      ''
      'begin'
      '  // Reserva espacio para las observaciones antes de paginar.'
      '  FacturasCOMENTARIOS_FACTURA.Memo.Text := Trim('
      '    VarToStr(<Facturas."TEXTO_LEGAL_CLIENTE_FAC">) + '#39'  '#39' +'
      '    VarToStr(<Facturas."TEXTO_LEGAL_EMPRESA_FAC">) + '#39'  '#39' +'
      '    VarToStr(<Facturas."COMENTARIOS_FAC">));'
      '  PageFooter1.Height := 249.44898;'
      '  if FacturasCOMENTARIOS_FACTURA.CalcHeight > 30.23624 then'
      '    PageFooter1.Height := 188.40167 +'
      '      FacturasCOMENTARIOS_FACTURA.CalcHeight + 30.23624;'
      'end.')
    Left = 232
    Top = 144
    Datasets = <
      item
        DataSet = dmFacturas.fxdsPrintFac
        DataSetName = 'Facturas'
      end
      item
        DataSet = dmFacturas.fxdstPrintLinFac
        DataSetName = 'Lineas Facturas'
      end>
    Variables = <>
    Style = <>
    inherited Page1: TfrxReportPage
      LeftMargin = 10.000000000000000000
      object GroupHeaderOperacionCaja: TfrxGroupHeader
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 24.000000000000000000
        Top = 488.000000000000000000
        Width = 737.008350000000000000
        OnBeforePrint = 'GroupHeaderOperacionCajaOnBeforePrint'
        Condition = 'Lineas Facturas."ID_OPERACION_CAJA_FACTURA"'
        ReprintOnNewPage = True
        object MemoFondoOperacionCaja: TfrxMemoView
          AllowVectorExport = True
          Width = 724.000000000000000000
          Height = 22.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Fill.BackColor = 15395562
          GapX = 5.000000000000000000
          Memo.UTF8W = (
            'Operaci'#243'n origen')
          ParentFont = False
        end
        object MemoDocumentoOperacionCaja: TfrxMemoView
          AllowVectorExport = True
          Left = 116.000000000000000000
          Top = 2.000000000000000000
          Width = 430.000000000000000000
          Height = 18.000000000000000000
          DataField = 'DOCUMENTO_OPERACION_CAJA'
          DataSet = dmFacturas.fxdstPrintLinFac
          DataSetName = 'Lineas Facturas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[Lineas Facturas."DOCUMENTO_OPERACION_CAJA"]')
          ParentFont = False
        end
        object MemoEtiquetaFechaOperacionCaja: TfrxMemoView
          AllowVectorExport = True
          Left = 550.000000000000000000
          Top = 2.000000000000000000
          Width = 42.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            'Fecha:')
          ParentFont = False
        end
        object MemoFechaOperacionCaja: TfrxMemoView
          AllowVectorExport = True
          Left = 594.000000000000000000
          Top = 2.000000000000000000
          Width = 120.000000000000000000
          Height = 18.000000000000000000
          DataField = 'FECHA_OPERACION_CAJA'
          DataSet = dmFacturas.fxdstPrintLinFac
          DataSetName = 'Lineas Facturas'
          DisplayFormat.FormatStr = 'dd/mm/yyyy'
          DisplayFormat.Kind = fkDateTime
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[Lineas Facturas."FECHA_OPERACION_CAJA"]')
          ParentFont = False
        end
      end
      object DetailData1: TfrxDetailData
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 26.456710000000000000
        Top = 521.575140000000000000
        Width = 737.008350000000000000
        OnBeforePrint = 'DetailData1OnBeforePrint'
        DataSet = dmFacturas.fxdstPrintLinFac
        DataSetName = 'Lineas Facturas'
        RowCount = 0
        Stretched = True
        object LineasFacturasTOTAL_LINEA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 644.858690000000000000
          Top = 4.338590000000000000
          Width = 79.370130000000000000
          Height = 18.897650000000000000
          OnBeforePrint = 'LineasFacturasTOTAL_LINEAOnBeforePrint'
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
            ''
            
              '[<Lineas Facturas."CANTIDAD_FACLIN">*<Lineas Facturas."PRECIO_VE' +
              'NTA_SIVA_ARTICULO_FACLIN">]')
          ParentFont = False
        end
        object LineasFacturasCANTIDAD_FACTURA_LINEA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 386.055350000000000000
          Top = 3.779530000000000000
          Width = 79.370130000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            
              '[FormatFloat('#39'0.######'#39', <Lineas Facturas."CANTIDAD_FACLIN">)] [' +
              'Lineas Facturas."TIPO_CANTIDAD_ARTICULO_FACLIN"]')
          ParentFont = False
          Formats = <
            item
            end
            item
            end>
        end
        object PrecioUnitarioLineasFacturas: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 479.984540000000000000
          Top = 3.779530000000000000
          Width = 79.370130000000000000
          Height = 18.897650000000000000
          OnBeforePrint = 'PrecioUnitarioLineasFacturasOnBeforePrint'
          DataField = 'PRECIO_VENTA_SIVA_ARTICULO_FACLIN'
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
            '[Lineas Facturas."PRECIO_VENTA_SIVA_ARTICULO_FACLIN"]')
          ParentFont = False
        end
        object LineasFacturasPORCEN_IVA_FACTURA_LINEA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 582.047620000000000000
          Top = 3.779530000000000000
          Width = 56.692950000000000000
          Height = 18.897650000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%g %'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haCenter
          Memo.UTF8W = (
            '[Lineas Facturas."PORCENTAJE_IVA_FACLIN"]')
          ParentFont = False
        end
        object LineasFacturasFECHA_ENTREGA_FACTURA_LINEA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 306.126160000000000000
          Top = 3.779530000000000000
          Width = 79.370130000000000000
          Height = 18.897650000000000000
          DataField = 'FECHA_ENTREGA_FACLIN'
          DataSet = dmFacturas.fxdstPrintLinFac
          DataSetName = 'Lineas Facturas'
          DisplayFormat.FormatStr = 'dd/mm/yyyy'
          DisplayFormat.Kind = fkDateTime
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Lineas Facturas."FECHA_ENTREGA_FACLIN"]')
          ParentFont = False
        end
        object LineasFacturasDESCRIPCION_ARTICULO_FACTURA_LINEA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 22.677180000000000000
          Top = 3.779530000000000000
          Width = 272.126160000000000000
          Height = 18.897650000000000000
          StretchMode = smActualHeight
          DataField = 'DESCRIPCION_PRINT_FACLIN'
          DataSet = dmFacturas.fxdstPrintLinFac
          DataSetName = 'Lineas Facturas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          LineSpacing = 4.000000000000000000
          Memo.UTF8W = (
            '[Lineas Facturas."DESCRIPCION_PRINT_FACLIN"]')
          ParentFont = False
          WordBreak = True
        end
      end
      object PageHeader1: TfrxPageHeader
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 400.630180000000000000
        Top = 18.897650000000000000
        Width = 737.008350000000000000
        object Memo7: TfrxMemoView
          AllowVectorExport = True
          Left = 13.559060000000000000
          Top = 362.834880000000000000
          Width = 710.551640000000000000
          Height = 26.456710000000000000
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
          Left = 218.504175000000000000
          Top = 39.685065000000000000
          Width = 300.000000000000000000
          Height = 34.015770000000000000
          AutoWidth = False
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -24
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haCenter
          Memo.UTF8W = (
            'FACTURA')
          ParentFont = False
        end
        object Memo2: TfrxMemoView
          AllowVectorExport = True
          Left = 7.559060000000000000
          Top = 207.874150000000000000
          Width = 355.275820000000000000
          Height = 136.063080000000000000
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          ParentFont = False
        end
        object Memo3: TfrxMemoView
          AllowVectorExport = True
          Left = 379.512060000000000000
          Top = 207.874150000000000000
          Width = 343.937230000000000000
          Height = 136.063080000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          ParentFont = False
        end
        object FacturasRAZONSOCIAL_EMPRESA_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 20.779530000000000000
          Top = 211.653680000000000000
          Width = 340.157700000000000000
          Height = 18.897650000000000000
          DataField = 'RAZON_SOCIAL_EMPRESA_FAC'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[Facturas."RAZON_SOCIAL_EMPRESA_FAC"]')
          ParentFont = False
        end
        object FacturasDIRECCION1_EMPRESA_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 20.779530000000000000
          Top = 234.330860000000000000
          Width = 340.157700000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            
              '[Facturas."DIRECCION1_EMPRESA_FAC"] [Facturas."DIRECCION2_EMPRES' +
              'A_FAC"]')
          ParentFont = False
          Formats = <
            item
            end
            item
            end>
        end
        object FacturasCPOSTAL_EMPRESA_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 20.779530000000000000
          Top = 256.228510000000000000
          Width = 340.157700000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            
              '[Facturas."CODIGO_POSTAL_EMPRESA_FAC"]   [Facturas."POBLACION_EM' +
              'PRESA_FAC"]')
          ParentFont = False
        end
        object FacturasPROVINCIA_EMPRESA_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 20.779530000000000000
          Top = 278.362400000000000000
          Width = 340.157700000000000000
          Height = 18.897650000000000000
          OnBeforePrint = 'FacturasPROVINCIA_EMPRESA_FACTURAOnBeforePrint'
          OnPreviewClick = 'FacturasPROVINCIA_EMPRESA_FACTURAOnPreviewClick'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Facturas."PROVINCIA_EMPRESA_FAC"]')
          ParentFont = False
        end
        object FacturasMOVIL_EMPRESA_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 20.779530000000000000
          Top = 301.039580000000000000
          Width = 83.149660000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Facturas."MOVIL_EMPRESA_FAC"]')
          ParentFont = False
          Formats = <
            item
            end
            item
            end>
        end
        object Memo4: TfrxMemoView
          AllowVectorExport = True
          Left = 13.559060000000000000
          Top = 173.858380000000000000
          Width = 52.913420000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            'Emisor')
          ParentFont = False
        end
        object Memo5: TfrxMemoView
          AllowVectorExport = True
          Left = 380.173470000000000000
          Top = 173.858380000000000000
          Width = 75.590600000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            'Receptor')
          ParentFont = False
        end
        object FacturasRAZONSOCIAL_CLIENTE_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 392.953000000000000000
          Top = 211.653680000000000000
          Width = 347.716760000000000000
          Height = 18.897650000000000000
          DataField = 'RAZON_SOCIAL_CLIENTE_FAC'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[Facturas."RAZON_SOCIAL_CLIENTE_FAC"]')
          ParentFont = False
        end
        object FacturasDIRECCION1_EMPRESA_FACTURA1: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 392.953000000000000000
          Top = 234.330860000000000000
          Width = 347.716760000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            
              '[Facturas."DIRECCION1_CLIENTE_FAC"] [Facturas."DIRECCION2_CLIENT' +
              'E_FAC"]')
          ParentFont = False
        end
        object FacturasCPOSTAL_CLIENTE_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 392.953000000000000000
          Top = 256.228510000000000000
          Width = 302.362400000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            
              '[Facturas."CODIGO_POSTAL_CLIENTE_FAC"]   [Facturas."POBLACION_CL' +
              'IENTE_FAC"]')
          ParentFont = False
        end
        object FacturasPROVINCIA_CLIENTE_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 392.953000000000000000
          Top = 278.362400000000000000
          Width = 347.716760000000000000
          Height = 18.897650000000000000
          OnBeforePrint = 'FacturasPROVINCIA_CLIENTE_FACTURAOnBeforePrint'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            
              '[Facturas."PROVINCIA_CLIENTE_FAC"]   [Facturas."NOMBRE_PAI_CLIEN' +
              'TE_FAC"]')
          ParentFont = False
          Formats = <
            item
            end
            item
            end>
        end
        object FacturasMOVIL_CLIENTE_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 392.953000000000000000
          Top = 322.464750000000000000
          Width = 264.567100000000000000
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
            'NIF: [Facturas."NIF_CLIENTE_FAC"]')
          ParentFont = False
        end
        object Memo6: TfrxMemoView
          AllowVectorExport = True
          Left = 13.559060000000000000
          Top = 90.708720000000000000
          Width = 340.157700000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Fecha: [Facturas."FECHA_FAC"]')
          ParentFont = False
        end
        object FacturasNRO_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 13.559060000000000000
          Top = 120.944960000000000000
          Width = 340.157700000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'N'#250'mero de Factura: [Facturas."DOCUMENTO_FORMATO"]')
          ParentFont = False
          Formats = <
            item
            end
            item
            end>
        end
        object Memo8: TfrxMemoView
          AllowVectorExport = True
          Left = 17.779530000000000000
          Top = 366.614410000000000000
          Width = 180.000000000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            'Descripci'#243'n')
          ParentFont = False
        end
        object Memo9: TfrxMemoView
          AllowVectorExport = True
          Left = 635.740570000000000000
          Top = 366.614410000000000000
          Width = 79.370130000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            'Total')
          ParentFont = False
        end
        object Memo10: TfrxMemoView
          AllowVectorExport = True
          Left = 389.834880000000000000
          Top = 366.614410000000000000
          Width = 75.590600000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            'Cantidad')
          ParentFont = False
        end
        object Memo11: TfrxMemoView
          AllowVectorExport = True
          Left = 476.205010000000000000
          Top = 366.614410000000000000
          Width = 83.149660000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            'Precio')
          ParentFont = False
        end
        object TituloIvaColumna: TfrxMemoView
          AllowVectorExport = True
          Left = 572.929500000000000000
          Top = 366.614410000000000000
          Width = 75.590600000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haCenter
          Memo.UTF8W = (
            '% [Facturas."PALABRA_REPORTS_ZONA_IVA_FAC"]')
          ParentFont = False
        end
        object FechaEntregaTittle: TfrxMemoView
          AllowVectorExport = True
          Left = 306.126160000000000000
          Top = 366.614410000000000000
          Width = 90.708720000000000000
          Height = 18.897650000000000000
          OnBeforePrint = 'FechaEntregaTittleOnBeforePrint'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            'Fecha Entrega')
          ParentFont = False
        end
        object FacturasMOVIL_CLIENTE_FACTURA1: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 392.953000000000000000
          Top = 301.039580000000000000
          Width = 94.488250000000000000
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
            '[Facturas."MOVIL_CLIENTE_FAC"]')
          ParentFont = False
          Formats = <
            item
            end
            item
            end>
        end
        object FacturasNIF_EMPRESA_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 20.779530000000000000
          Top = 322.464750000000000000
          Width = 272.126160000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Frame.Width = 1.500000000000000000
          Memo.UTF8W = (
            'NIF: [Facturas."NIF_EMPRESA_FAC"]')
          ParentFont = False
        end
        object Memo12: TfrxMemoView
          AllowVectorExport = True
          Left = 468.661720000000000000
          Top = 301.039592200000000000
          Width = 249.448980000000000000
          Height = 18.897637800000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Facturas."EMAIL_CLIENTE_FAC"]')
          ParentFont = False
        end
        object Memo13: TfrxMemoView
          AllowVectorExport = True
          Left = 506.457020000000000000
          Top = 94.488250000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          ParentFont = False
        end
        object Memo14: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 109.606370000000000000
          Top = 301.362400000000000000
          Width = 249.448980000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Facturas."EMAIL_EMPRESA_FAC"]')
          ParentFont = False
        end
        object qr: TfrxPictureView
          AllowVectorExport = True
          Left = 578.268106310000000000
          Top = 56.692953260000000000
          Width = 109.606323240000000000
          Height = 109.606369020000000000
          DataField = 'QRCODE_PNG_FACCON'
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          Frame.Typ = []
          HightQuality = False
          Transparent = False
          TransparentColor = clWhite
        end
      end
      object MasterData1: TfrxMasterData
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 18.897650000000000000
        Top = 480.000310000000000000
        Visible = False
        Width = 737.008350000000000000
        DataSet = dmFacturas.fxdsPrintFac
        DataSetName = 'Facturas'
        RowCount = 0
        object FacturasNRO_FACTURA1: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 64.252010000000000000
          Width = 94.488250000000000000
          Height = 18.897650000000000000
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          DataField = 'DOCUMENTO_FORMATO'
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Facturas."DOCUMENTO_FORMATO"]')
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
        Height = 249.448980000000000000
        Top = 608.504330000000000000
        Width = 737.008350000000000000
        OnBeforePrint = 'PageFooter1OnBeforePrint'
        object CajaIVA: TfrxMemoView
          AllowVectorExport = True
          Left = 18.897650000000000000
          Top = 32.677180000000000000
          Width = 468.661417320000000000
          Height = 113.385900000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          ParentFont = False
        end
        object CajaTitulosIVA: TfrxMemoView
          AllowVectorExport = True
          Left = 18.897650000000000000
          Top = 6.220470000000000000
          Width = 468.661417320000000000
          Height = 26.456710000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          ParentFont = False
        end
        object mTotalFactura: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 507.677504650000000000
          Top = 124.724490000000000000
          Width = 215.433210000000000000
          Height = 22.677180000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Frame.Width = 1.500000000000000000
          Memo.UTF8W = (
            'Total Factura ')
          ParentFont = False
        end
        object BaseImponibleN: TfrxMemoView
          AllowVectorExport = True
          Left = 26.456724650000000000
          Top = 36.456710000000000000
          Width = 113.385900000000000000
          Height = 18.897650000000000000
          OnBeforePrint = 'BaseImponibleNOnBeforePrint'
          DataField = 'TOTAL_BASEI_IVAN_FAC'
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haLeft
          Memo.UTF8W = (
            '[Facturas."TOTAL_BASEI_IVAN_FAC"]')
          ParentFont = False
        end
        object BaseImponibleCajaIVA: TfrxMemoView
          AllowVectorExport = True
          Left = 26.456724650000000000
          Top = 10.000000000000000000
          Width = 102.047310000000000000
          Height = 15.118120000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Base Imponible')
          ParentFont = False
        end
        object BaseImponibleE: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 26.456724650000000000
          Top = 115.826840000000000000
          Width = 113.385900000000000000
          Height = 18.897650000000000000
          OnBeforePrint = 'BaseImponibleEOnBeforePrint'
          DataField = 'TOTAL_BASEI_IVAE_FAC'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haLeft
          Memo.UTF8W = (
            '[Facturas."TOTAL_BASEI_IVAE_FAC"]')
          ParentFont = False
        end
        object TituloPorcenCajaIVA: TfrxMemoView
          AllowVectorExport = True
          Left = 147.401684650000000000
          Top = 10.000000000000000000
          Width = 68.031540000000000000
          Height = 15.118120000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '% [Facturas."PALABRA_REPORTS_ZONA_IVA_FAC"]')
          ParentFont = False
        end
        object TituloTotalCajaIVA: TfrxMemoView
          AllowVectorExport = True
          Left = 222.992284650000000000
          Top = 10.000000000000000000
          Width = 98.267780000000000000
          Height = 15.118120000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Total [Facturas."PALABRA_REPORTS_ZONA_IVA_FAC"]')
          ParentFont = False
        end
        object RetencionPorc: TfrxMemoView
          AllowVectorExport = True
          Left = 325.039594650000000000
          Top = 10.000000000000000000
          Width = 71.811070000000000000
          Height = 15.118120000000000000
          OnBeforePrint = 'RetencionPorcOnBeforePrint'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '% R.E.')
          ParentFont = False
        end
        object RetencionTot: TfrxMemoView
          AllowVectorExport = True
          Left = 394.630194650000000000
          Top = 10.000000000000000000
          Width = 71.811070000000000000
          Height = 15.118120000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Total R.E.')
          ParentFont = False
        end
        object FacturasTOTAL_IVAN_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 222.992284650000000000
          Top = 36.456710000000000000
          Width = 98.267780000000000000
          Height = 18.897650000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.ThousandSeparator = '.'
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haLeft
          Memo.UTF8W = (
            '[Facturas."TOTAL_IVAN_FAC"]')
          ParentFont = False
        end
        object FacturasPORCEN_IVAN_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 147.401684650000000000
          Top = 36.456710000000000000
          Width = 56.692950000000000000
          Height = 18.897650000000000000
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Facturas."PORCENTAJE_IVAN_FAC"]%')
          ParentFont = False
        end
        object FacturasPORCEN_IVAR_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 147.401684650000000000
          Top = 62.913420000000000000
          Width = 56.692950000000000000
          Height = 18.897650000000000000
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Facturas."PORCENTAJE_IVAR_FAC"]%')
          ParentFont = False
        end
        object FacturasPORCEN_IVAS_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 147.401684650000000000
          Top = 89.370130000000000000
          Width = 56.692950000000000000
          Height = 18.897650000000000000
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Facturas."PORCENTAJE_IVAS_FAC"]%')
          ParentFont = False
        end
        object FacturasPORCEN_IVAE_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 147.401684650000000000
          Top = 115.826840000000000000
          Width = 56.692950000000000000
          Height = 18.897650000000000000
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Facturas."PORCENTAJE_IVAE_FAC"]%')
          ParentFont = False
        end
        object FacturasTOTAL_IVAR_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 222.992284650000000000
          Top = 62.913420000000000000
          Width = 98.267780000000000000
          Height = 18.897650000000000000
          DataField = 'TOTAL_IVAR_FAC'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.ThousandSeparator = '.'
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haLeft
          Memo.UTF8W = (
            '[Facturas."TOTAL_IVAR_FAC"]')
          ParentFont = False
        end
        object FacturasTOTAL_IVAS_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 222.992284650000000000
          Top = 89.370130000000000000
          Width = 98.267780000000000000
          Height = 18.897650000000000000
          DataField = 'TOTAL_IVAS_FAC'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.ThousandSeparator = '.'
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haLeft
          Memo.UTF8W = (
            '[Facturas."TOTAL_IVAS_FAC"]')
          ParentFont = False
        end
        object FacturasTOTAL_IVAE_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 222.992284650000000000
          Top = 115.826840000000000000
          Width = 98.267780000000000000
          Height = 18.897650000000000000
          DataField = 'TOTAL_IVAE_FAC'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.ThousandSeparator = '.'
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haLeft
          Memo.UTF8W = (
            '[Facturas."TOTAL_IVAE_FAC"]')
          ParentFont = False
        end
        object FacturasPORCEN_REN_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 325.039594650000000000
          Top = 36.456710000000000000
          Width = 56.692950000000000000
          Height = 18.897650000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Facturas."PORCENTAJE_REN_FAC"]%')
          ParentFont = False
        end
        object FacturasPORCEN_RER_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 325.039594650000000000
          Top = 62.913420000000000000
          Width = 56.692950000000000000
          Height = 18.897650000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Facturas."PORCENTAJE_RER_FAC"]%')
          ParentFont = False
        end
        object FacturasPORCEN_REE_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 325.039594650000000000
          Top = 115.826840000000000000
          Width = 56.692950000000000000
          Height = 18.897650000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Facturas."PORCENTAJE_REE_FAC"]%')
          ParentFont = False
        end
        object FacturasPORCEN_RES_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 325.039594650000000000
          Top = 89.370130000000000000
          Width = 52.913420000000000000
          Height = 18.897650000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Facturas."PORCENTAJE_RES_FAC"]%')
          ParentFont = False
        end
        object FacturasTOTAL_REN_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 394.630194650000000000
          Top = 36.456710000000000000
          Width = 64.252010000000000000
          Height = 18.897650000000000000
          OnBeforePrint = 'FacturasTOTAL_REN_FACTURAOnBeforePrint'
          DataField = 'TOTAL_REN_FAC'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Facturas."TOTAL_REN_FAC"]')
          ParentFont = False
        end
        object FacturasTOTAL_REE_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 394.630194650000000000
          Top = 115.826840000000000000
          Width = 64.252010000000000000
          Height = 18.897650000000000000
          OnBeforePrint = 'FacturasTOTAL_REE_FACTURAOnBeforePrint'
          DataField = 'TOTAL_REE_FAC'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Facturas."TOTAL_REE_FAC"]')
          ParentFont = False
        end
        object BaseImponibleR: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 26.456724650000000000
          Top = 62.913420000000000000
          Width = 113.385900000000000000
          Height = 18.897650000000000000
          OnBeforePrint = 'BaseImponibleROnBeforePrint'
          DataField = 'TOTAL_BASEI_IVAR_FAC'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haLeft
          Memo.UTF8W = (
            '[Facturas."TOTAL_BASEI_IVAR_FAC"]')
          ParentFont = False
        end
        object BaseImponibleS: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 26.456724650000000000
          Top = 89.370130000000000000
          Width = 113.385900000000000000
          Height = 18.897650000000000000
          OnBeforePrint = 'BaseImponibleSOnBeforePrint'
          DataField = 'TOTAL_BASEI_IVAS_FAC'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haLeft
          Memo.UTF8W = (
            '[Facturas."TOTAL_BASEI_IVAS_FAC"]')
          ParentFont = False
        end
        object FacturasTOTAL_RER_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 394.630194650000000000
          Top = 62.913420000000000000
          Width = 68.031540000000000000
          Height = 18.897650000000000000
          OnBeforePrint = 'FacturasTOTAL_RER_FACTURAOnBeforePrint'
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          DataField = 'TOTAL_RER_FAC'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Facturas."TOTAL_RER_FAC"]')
          ParentFont = False
        end
        object FacturasTOTAL_RES_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 394.630194650000000000
          Top = 89.370130000000000000
          Width = 68.031540000000000000
          Height = 18.897650000000000000
          OnBeforePrint = 'FacturasTOTAL_RES_FACTURAOnBeforePrint'
          ContentScaleOptions.Constraints.MaxIterationValue = 0
          ContentScaleOptions.Constraints.MinIterationValue = 0
          DataField = 'TOTAL_RES_FAC'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Facturas."TOTAL_RES_FAC"]')
          ParentFont = False
        end
        object Retencion: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 495.000000000000000000
          Top = 86.929190000000000000
          Width = 125.000000000000000000
          Height = 18.897650000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Retenci'#243'n IRPF [Facturas."PORCENTAJE_RETENCION_FAC"]%')
          ParentFont = False
        end
        object txtRetencionTotal: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 622.197294650000000000
          Top = 86.929190000000000000
          Width = 99.370130000000000000
          Height = 18.897650000000000000
          OnBeforePrint = 'RetencionTotalOnBeforePrint'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.ThousandSeparator = '.'
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[<Facturas."TOTAL_RETENCION_FAC"> * (-1)]')
          ParentFont = False
        end
        object ImpuestosTotal: TfrxMemoView
          AllowVectorExport = True
          Left = 622.197294650000000000
          Top = 58.582715000000000000
          Width = 99.370130000000000000
          Height = 18.897650000000000000
          OnBeforePrint = 'ImpuestosTotalOnBeforePrint'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.ThousandSeparator = '.'
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Facturas."TOTAL_IMPUESTOS_FAC"]')
          ParentFont = False
        end
        object Impuestos: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 495.000000000000000000
          Top = 58.582715000000000000
          Width = 125.000000000000000000
          Height = 18.897650000000000000
          OnBeforePrint = 'ImpuestosOnBeforePrint'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%g'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Total IVA + RE')
          ParentFont = False
        end
        object TotalBases: TfrxMemoView
          AllowVectorExport = True
          Left = 622.197294650000000000
          Top = 30.236240000000000000
          Width = 99.370130000000000000
          Height = 18.897650000000000000
          OnBeforePrint = 'ImpuestosTotalOnBeforePrint'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.ThousandSeparator = '.'
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Facturas."TOTAL_BASES_FAC"]')
          ParentFont = False
        end
        object TotalBaseImponible: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 495.000000000000000000
          Top = 30.236240000000000000
          Width = 125.000000000000000000
          Height = 18.897650000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Total Base Imponible')
          ParentFont = False
        end
        object FacturasCOMENTARIOS_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 22.677194650000000000
          Top = 188.401670000000000000
          Width = 699.213050000000000000
          Height = 30.236240000000000000
          StretchMode = smActualHeight
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Trim(VarToStr(<Facturas."TEXTO_LEGAL_CLIENTE_FAC">)+'#39'  '#39'+'
            ' VarToStr(<Facturas."TEXTO_LEGAL_EMPRESA_FAC">) +'#39'  '#39'+'
            ' VarToStr(<Facturas."COMENTARIOS_FAC">))]')
          ParentFont = False
        end
        object FormaPago: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 22.677194650000000000
          Top = 157.401670000000000000
          Width = 699.213050000000000000
          Height = 37.795300000000000000
          OnBeforePrint = 'FormaPagoOnBeforePrint'
          StretchMode = smActualHeight
          AutoWidth = True
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Forma de Pago: [Facturas."FORMA_PAGO_IMPRESION"]')
          ParentFont = False
        end
        object mNumPaginas: TfrxMemoView
          AllowVectorExport = True
          Left = 616.283860000000000000
          Top = 219.771800000000000000
          Width = 113.385900000000000000
          Height = 22.677180000000000000
          OnBeforePrint = 'mNumPaginasOnBeforePrint'
          ShiftMode = smWhenOverlapped
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            'P'#225'gina [<Page>] de [<TotalPages#>]')
          ParentFont = False
          Formats = <
            item
            end
            item
            end>
        end
        object Continua: TfrxMemoView
          AllowVectorExport = True
          Left = 22.677180000000000000
          Width = 309.921460000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            'Contin'#250'a en la siguiente p'#225'gina ...')
          ParentFont = False
        end
        object mTotalFacturaCtd: TfrxMemoView
          AllowVectorExport = True
          Left = 596.606680000000000000
          Top = 124.724490000000000000
          Width = 124.724490000000000000
          Height = 22.677180000000000000
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -14
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Frame.Width = 1.500000000000000000
          HAlign = haRight
          Memo.UTF8W = (
            '[Facturas."TOTAL_LIQUIDO_FAC"]')
          ParentFont = False
        end
      end
    end
  end
  inherited frLocalizationController1: TfrLocalizationController
    Left = 72
    Top = 136
  end
end
