{******************************************************************************}
{  Módulo:       inLibComprasDirectasInforme                                   }
{    Tipo:       Presentación de informes                                     }
{   Fecha:       26/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{******************************************************************************}
unit inLibComprasDirectasInforme;

interface

uses
  Data.DB, frxClass, inLibDocCompraExcel;

procedure AdaptarInformeCompraDirecta(AInforme: TfrxReport;
  ACabecera: TDataSet);
procedure AdaptarExcelCompraDirecta(ACabecera: TDataSet;
  var AConfiguracion: TDocCompraCabCfg);
procedure EnlazarTrazabilidadCompra(AInforme: TfrxReport);
procedure AplicarResumenCantidadesCompra(AInforme: TfrxReport;
  ALineas: TDataSet);

implementation

uses
  System.SysUtils, System.Classes, Vcl.Graphics,
  inLibComprasDirectas, inLibVerifactu;

resourcestring
  STituloAutofactura = 'AUTOFACTURA';
  STituloReciboCompensacion = 'RECIBO DE COMPENSACIÓN REAGP';
  SDestinatario = 'DESTINATARIO';
  SEmisorBeneficiario = 'EMISOR / BENEFICIARIO';
  SCompensacionImpresa = 'Compensación REAGP %s%% de %s = %s EUR';

procedure EnlazarTrazabilidadCompra(AInforme: TfrxReport);
var
  Lineas, Trazabilidad: TfrxComponent;
begin
  // El lector del DFM heredado no resuelve esta referencia entre bandas.
  // Reconstruirla tambien al cargar formatos guardados (FZ-ISSUE-847).
  Lineas := AInforme.FindObject('DataBandLineas');
  Trazabilidad := AInforme.FindObject('BandaTrazabilidad');
  if (Lineas is TfrxMasterData) and (Trazabilidad is TfrxChild) then
  begin
    TfrxMasterData(Lineas).Child := TfrxChild(Trazabilidad);
    TfrxMasterData(Lineas).KeepChild := True;
  end;
end;

procedure AplicarResumenCantidadesCompra(AInforme: TfrxReport;
  ALineas: TDataSet);
var
  Objeto: TfrxComponent;
begin
  Objeto := AInforme.FindObject('MemoTotalUds');
  if Objeto is TfrxMemoView then
    TfrxMemoView(Objeto).Text := ResumenCantidadesCompra(ALineas);
end;

function EsCompraDirecta(ACabecera: TDataSet): Boolean;
begin
  Result := Assigned(ACabecera) and ACabecera.Active and
    (not ACabecera.IsEmpty) and
    (ModalidadCompra(ACabecera.FieldByName('MODALIDAD_FACC').AsString) <>
     mcdOrdinaria);
end;

function TituloCompra(ACabecera: TDataSet): string;
begin
  Result := STituloAutofactura;
  if ModalidadCompra(ACabecera.FieldByName('MODALIDAD_FACC').AsString) =
     mcdReagp then
    Result := STituloReciboCompensacion;
  if Trim(ACabecera.FieldByName('ESTADO_FISCAL_FACC').AsString) = '' then
    Result := 'BORRADOR - ' + Result;
end;

function SustituirCampos(const ATexto: string): string;
const
  ORIGEN: array[0..13] of string = (
    'NOMBRE_ALM_FACC', 'DIRECCION_ALM_FACC', 'CODIGO_POSTAL_ALM_FACC',
    'POBLACION_ALM_FACC', 'PROVINCIA_ALM_FACC', 'CIF_EMP',
    'TELEFONO_ALM_FACC', 'RAZON_SOCIAL_PRV', 'DIRECCION1_PRV',
    'CODIGO_POSTAL_PRV', 'POBLACION_PRV', 'PROVINCIA_PRV', 'CIF_PRV',
    'TELEFONO1_PRV');
  DESTINO: array[0..13] of string = (
    'RAZON_SOCIAL_EMPRESA_FACC', 'DIRECCION1_EMPRESA_FACC',
    'CODIGO_POSTAL_EMPRESA_FACC', 'POBLACION_EMPRESA_FACC',
    'PROVINCIA_EMPRESA_FACC', 'NIF_EMPRESA_FACC', 'MOVIL_EMPRESA_FACC',
    'RAZON_SOCIAL_PRV_FACC', 'DIRECCION1_PRV_FACC', 'CODIGO_POSTAL_PRV_FACC',
    'POBLACION_PRV_FACC', 'PROVINCIA_PRV_FACC', 'NIF_PRV_FACC',
    'MOVIL_PRV_FACC');
var
  iIndice: Integer;
begin
  Result := ATexto;
  for iIndice := Low(ORIGEN) to High(ORIGEN) do
    Result := StringReplace(Result, 'Factura."' + ORIGEN[iIndice] + '"',
      'Factura."' + DESTINO[iIndice] + '"', [rfReplaceAll]);
end;

procedure AgregarPieCompra(AInforme: TfrxReport; ABanda: TfrxReportSummary;
  ACabecera: TDataSet);
var
  oTexto: TfrxMemoView;
  oEtiquetaQr: TfrxMemoView;
  oQr: TfrxPictureView;
  oImagen: TBytesStream;
  sTexto, sUrl: string;
  oModalidad: TModalidadCompraDirecta;
  dTop: Extended;
begin
  oModalidad := ModalidadCompra(
    ACabecera.FieldByName('MODALIDAD_FACC').AsString);
  sTexto := ClasificarCompraDirecta(oModalidad).TextoLegal;
  if oModalidad = mcdReagp then
    sTexto := Format(SCompensacionImpresa,
      [FormatFloat('0.##', ACabecera.FieldByName(
        'PORCENTAJE_COMPENSACION_FACC').AsCurrency),
       FormatFloat('#,##0.00', ACabecera.FieldByName(
        'TOTAL_BASES_FACC').AsCurrency),
       FormatFloat('#,##0.00', ACabecera.FieldByName(
        'TOTAL_COMPENSACION_FACC').AsCurrency)]) + sLineBreak + sTexto;
  dTop := ABanda.Height + 8;
  ABanda.Height := dTop + 136;
  oTexto := TfrxMemoView.Create(ABanda);
  oTexto.Name := 'MemoLegalCompraDirecta';
  oTexto.SetBounds(0, dTop, ABanda.Width - 136, 78);
  oTexto.Font.Size := 9;
  oTexto.Text := sTexto;
  sUrl := ACabecera.FieldByName('URL_QR_FISCAL_FACC').AsString;
  if sUrl <> '' then
  begin
    oQr := TfrxPictureView.Create(ABanda);
    oQr.Name := 'QrCompraDirecta';
    oQr.SetBounds(ABanda.Width - 114, dTop, 114, 114);
    oEtiquetaQr := TfrxMemoView.Create(ABanda);
    oEtiquetaQr.SetBounds(ABanda.Width - 114, dTop + 116, 114, 16);
    oEtiquetaQr.Font.Size := 8;
    oEtiquetaQr.Text := 'VERI*FACTU';
    oQr.Stretched := True;
    oImagen := TBytesStream.Create(GenerarQRPngVerifactu(sUrl));
    try
      oQr.Picture.LoadFromStream(oImagen);
    finally
      FreeAndNil(oImagen);
    end;
  end;
end;

procedure AdaptarTextosReagp(AMemo: TfrxMemoView);
begin
  AMemo.Text := StringReplace(string(AMemo.Text), 'Factura:', 'Recibo:',
    [rfReplaceAll]);
  if Trim(string(AMemo.Text)) = 'FACTURA' then
    AMemo.Text := 'RECIBO';
  if SameText(AMemo.Name, 'MemoTotalesFiscales') then
    AMemo.Text := 'Base de compensación: ' +
      '[FormatFloat(''#,##0.00'', <Factura."TOTAL_BASES_FACC">)] EUR' +
      sLineBreak + 'Compensación REAGP ' +
      '[FormatFloat(''0.##'', <Factura."PORCENTAJE_COMPENSACION_FACC">)]%: ' +
      '[FormatFloat(''#,##0.00'', <Factura."TOTAL_COMPENSACION_FACC">)] EUR' +
      sLineBreak + 'Retención IRPF: ' +
      '[FormatFloat(''#,##0.00'', <Factura."TOTAL_RETENCION_FACC">)] EUR' +
      sLineBreak + 'Total a pagar: ' +
      '[FormatFloat(''#,##0.00'', <Factura."TOTAL_LIQUIDO_FACC">)] EUR';
  if SameText(AMemo.Name, 'MemoTotIvaLblV') or
     SameText(AMemo.Name, 'MemoTotIvaLbl') then
    AMemo.Text := 'Compensación REAGP ' +
      '[FormatFloat(''0.##'', <Factura."PORCENTAJE_COMPENSACION_FACC">)]%:';
  if SameText(AMemo.Name, 'MemoTotIvaV') or
     SameText(AMemo.Name, 'MemoTotIva') then
  begin
    AMemo.DataField := 'TOTAL_COMPENSACION_FACC';
    AMemo.Text := '[Factura."TOTAL_COMPENSACION_FACC"]';
  end;
end;

procedure AdaptarInformeCompraDirecta(AInforme: TfrxReport;
  ACabecera: TDataSet);
var
  iIndice: Integer;
  oComponente: TfrxComponent;
  oMemo: TfrxMemoView;
  oResumen: TfrxReportSummary;
begin
  if EsCompraDirecta(ACabecera) then
  begin
    oResumen := nil;
    for iIndice := 0 to AInforme.AllObjects.Count - 1 do
    begin
      oComponente := AInforme.AllObjects[iIndice];
      if oComponente is TfrxReportSummary then
        oResumen := TfrxReportSummary(oComponente);
      if oComponente is TfrxMemoView then
      begin
        oMemo := TfrxMemoView(oComponente);
        if ModalidadCompra(ACabecera.FieldByName('MODALIDAD_FACC').AsString) =
           mcdReagp then
          AdaptarTextosReagp(oMemo);
        oMemo.Text := SustituirCampos(string(oMemo.Text));
        if ACabecera.FieldByName('DOCUMENTO_FISCAL_FACC').AsString <> '' then
          oMemo.Text := StringReplace(string(oMemo.Text),
            'Factura."DOCUMENTO_FORMATO"', 'Factura."DOCUMENTO_FISCAL_FACC"',
            [rfReplaceAll]);
        if SameText(oMemo.Name, 'MemoEmpCif') or
           SameText(oMemo.Name, 'MemoEmpCifV') then
          oMemo.Text := 'NIF: [Factura."NIF_EMPRESA_FACC"]';
        if Pos('FACTURA DE COMPRA', string(oMemo.Text)) > 0 then
          oMemo.Text := TituloCompra(ACabecera);
        if Trim(string(oMemo.Text)) = 'ALMACÉN DESTINO' then
          oMemo.Text := SDestinatario;
        if Trim(string(oMemo.Text)) = 'PROVEEDOR' then
          oMemo.Text := SEmisorBeneficiario;
      end;
    end;
    if Assigned(oResumen) and
       (AInforme.FindObject('MemoLegalCompraDirecta') = nil) then
      AgregarPieCompra(AInforme, oResumen, ACabecera);
  end;
end;

procedure AdaptarExcelCompraDirecta(ACabecera: TDataSet;
  var AConfiguracion: TDocCompraCabCfg);
begin
  if EsCompraDirecta(ACabecera) then
  begin
    AConfiguracion.Titulo := TituloCompra(ACabecera);
    AConfiguracion.EtiquetaIzq := SDestinatario;
    AConfiguracion.FieldRazonIzq := 'RAZON_SOCIAL_EMPRESA_FACC';
    AConfiguracion.FieldDirIzq := 'DIRECCION1_EMPRESA_FACC';
    AConfiguracion.FieldCPIzq := 'CODIGO_POSTAL_EMPRESA_FACC';
    AConfiguracion.FieldPobIzq := 'POBLACION_EMPRESA_FACC';
    AConfiguracion.FieldProvIzq := 'PROVINCIA_EMPRESA_FACC';
    AConfiguracion.FieldCifIzq := 'NIF_EMPRESA_FACC';
    AConfiguracion.FieldTelIzq := 'MOVIL_EMPRESA_FACC';
    AConfiguracion.FieldRazonPrv := 'RAZON_SOCIAL_PRV_FACC';
    AConfiguracion.FieldDirPrv := 'DIRECCION1_PRV_FACC';
    AConfiguracion.FieldCPPrv := 'CODIGO_POSTAL_PRV_FACC';
    AConfiguracion.FieldPobPrv := 'POBLACION_PRV_FACC';
    AConfiguracion.FieldProvPrv := 'PROVINCIA_PRV_FACC';
    AConfiguracion.FieldCifPrv := 'NIF_PRV_FACC';
    AConfiguracion.FieldTelPrv := 'MOVIL_PRV_FACC';
  end;
end;

end.
