{******************************************************************************}
{                                                                              }
{  Módulo:       inLibReparacionesDocumentos                                   }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Hojas de las reparaciones: entrega al externo (lo que se lleva),          }
{    liquidación de un pago y cargo al fabricante. Texto en FastReport, en     }
{    ticket (80 mm) o A4, como el resguardo de garantía.                       }
{******************************************************************************}
unit inLibReparacionesDocumentos;

interface

uses
  frxClass, inLibPreviewTicket;

type
  TFormatoHojaReparacion = (fhrTicket, fhrA4);

  TTiendaHojaReparacion = record
    Empresa: string;
    Nif: string;
    Tienda: string;
    Direccion: string;
    Poblacion: string;
    Telefono: string;
  end;

  TLineaHojaReparacion = record
    Reparacion: Int64;
    Referencia: string;
    Fecha: TDateTime;
    Objeto: string;
    Trabajo: string;
    Detalles: string;
    Importe: Currency;
  end;

  THojaReparaciones = record
    Tienda: TTiendaHojaReparacion;
    Titulo: string;
    Proveedor: string;
    Fecha: TDateTime;
    Liquidacion: Int64;
    // Las hojas de liquidación y de cargo suman importes; la de entrega no.
    EsImporte: Boolean;
    Lineas: TArray<TLineaHojaReparacion>;
  end;

function TextoHojaReparaciones(const AHoja: THojaReparaciones): string;
procedure CrearInformeHojaReparaciones(AInforme: TfrxReport;
  const AHoja: THojaReparaciones; AFormato: TFormatoHojaReparacion);
procedure ImprimirHojaReparacionesTicket(AInforme: TfrxReport;
  const ATitulo: string; const APreview: IPreviewTicket;
  const AImpresora, ARutaPdf: string);

implementation

uses
  System.SysUtils, System.Classes, System.Math, Vcl.Graphics,
  frBaseGraphicsTypes,
  inLibMsgReparaciones, inLibMsgComun, inLibFTicket, inLibTicketTextoFR;

function FechaHoja(AFecha: TDateTime): string;
begin
  Result := '';
  if AFecha > 0 then
    Result := FormatDateTime('dd/mm/yyyy', AFecha);
end;

procedure AgregarDato(ALineas: TStrings; const ARotulo, AValor: string);
begin
  if Trim(AValor) <> '' then
    ALineas.Add(ARotulo + ' ' + Trim(AValor));
end;

procedure AgregarTienda(ALineas: TStrings;
  const ATienda: TTiendaHojaReparacion);
begin
  ALineas.Add(ATienda.Empresa);
  ALineas.Add(ATienda.Nif);
  ALineas.Add(ATienda.Tienda);
  ALineas.Add(ATienda.Direccion);
  ALineas.Add(ATienda.Poblacion);
  AgregarDato(ALineas, SRotuloTelefonoHoja, ATienda.Telefono);
  ALineas.Add('');
end;

function ReferenciaLineaHoja(const ALinea: TLineaHojaReparacion): string;
begin
  Result := Trim(ALinea.Referencia);
  if Result = '' then
    Result := IntToStr(ALinea.Reparacion);
end;

procedure AgregarLinea(ALineas: TStrings; const ALinea: TLineaHojaReparacion;
  AEsImporte: Boolean);
var
  sLinea: string;
begin
  sLinea := Format('%s  %s  %s', [ReferenciaLineaHoja(ALinea),
    FechaHoja(ALinea.Fecha), ALinea.Trabajo]);
  if AEsImporte then
    sLinea := sLinea + '  ' + FormatFloat('#,##0.00', ALinea.Importe);
  ALineas.Add(sLinea);
  AgregarDato(ALineas, '   ', ALinea.Objeto);
  AgregarDato(ALineas, '   ', ALinea.Detalles);
end;

function TextoHojaReparaciones(const AHoja: THojaReparaciones): string;
var
  stLineas: TStringList;
  Linea: TLineaHojaReparacion;
  dTotal: Currency;
begin
  stLineas := TStringList.Create;
  try
    AgregarTienda(stLineas, AHoja.Tienda);
    AgregarDato(stLineas, SRotuloProveedorHoja, AHoja.Proveedor);
    AgregarDato(stLineas, SRotuloFechaHoja, FechaHoja(AHoja.Fecha));
    if AHoja.Liquidacion > 0 then
      AgregarDato(stLineas, SRotuloLiquidacionHoja,
        IntToStr(AHoja.Liquidacion));
    stLineas.Add('');
    dTotal := 0;
    for Linea in AHoja.Lineas do
    begin
      AgregarLinea(stLineas, Linea, AHoja.EsImporte);
      dTotal := dTotal + Linea.Importe;
    end;
    stLineas.Add('');
    stLineas.Add(Format(SHojaReparacionesLineas, [Length(AHoja.Lineas)]));
    if AHoja.EsImporte then
      stLineas.Add(Format(SHojaReparacionesTotal,
        [FormatFloat('#,##0.00', dTotal)]));
    stLineas.Add('');
    stLineas.Add(SHojaReparacionesFirma);
    stLineas.Add('');
    stLineas.Add('____________________________');
    Result := stLineas.Text;
  finally
    FreeAndNil(stLineas);
  end;
end;

function CrearPagina(AInforme: TfrxReport;
  AFormato: TFormatoHojaReparacion): TfrxReportPage;
begin
  Result := TfrxReportPage.Create(AInforme);
  Result.CreateUniqueName;
  Result.SetDefaults;
  Result.PaperWidth := 210;
  Result.PaperHeight := 297;
  Result.LeftMargin := 15;
  Result.RightMargin := 15;
  Result.TopMargin := 12;
  Result.BottomMargin := 12;
  if AFormato = fhrTicket then
  begin
    Result.PaperWidth := 80;
    Result.LeftMargin := 4;
    Result.RightMargin := 4;
    Result.TopMargin := 4;
    Result.BottomMargin := 4;
    Result.EndlessHeight := True;
  end;
end;

function CrearMemo(ABanda: TfrxBand; AArriba, AAncho: Extended;
  ATamano: Integer): TfrxMemoView;
begin
  Result := TfrxMemoView.Create(ABanda);
  Result.CreateUniqueName;
  Result.SetBounds(0, AArriba, AAncho, 20);
  Result.Font.Name := 'Arial';
  Result.Font.Size := ATamano;
  Result.WordWrap := True;
  Result.StretchMode := smActualHeight;
  // Los corchetes de una descripción son datos, nunca expresiones.
  Result.AllowExpressions := False;
end;

function TextoA4(ABanda: TfrxBand; const ATexto: string;
  AX, AY, AAncho: Extended; ATamano: Integer;
  ANegrita: Boolean = False): TfrxMemoView;
begin
  Result := CrearMemo(ABanda, AY, AAncho, ATamano);
  Result.Left := AX;
  Result.GapX := 6;
  Result.GapY := 4;
  if ANegrita then
    Result.Font.Style := [fsBold];
  Result.Text := ATexto;
  Result.Height := Max(24, Result.CalcHeight + 2);
end;

function DatosTiendaA4(const ATienda: TTiendaHojaReparacion): string;
var
  oTexto: TStringList;
begin
  oTexto := TStringList.Create;
  try
    AgregarDato(oTexto, '', ATienda.Nif);
    AgregarDato(oTexto, '', ATienda.Tienda);
    AgregarDato(oTexto, '', ATienda.Direccion);
    AgregarDato(oTexto, '', ATienda.Poblacion);
    AgregarDato(oTexto, SRotuloTelefonoHoja, ATienda.Telefono);
    Result := Trim(oTexto.Text);
  finally
    oTexto.Free;
  end;
end;

procedure CabeceraA4(APagina: TfrxReportPage;
  const AHoja: THojaReparaciones; AAncho: Extended);
var
  oBanda: TfrxReportTitle;
  oTexto: TfrxMemoView;
  dY, dAlto: Extended;
begin
  oBanda := TfrxReportTitle.Create(APagina);
  oBanda.CreateUniqueName;
  oTexto := TextoA4(oBanda, AHoja.Titulo, 0, 0, AAncho, 20, True);
  oTexto.Frame.Typ := [ftBottom];
  oTexto.Frame.Color := $00B0B0B0;
  oTexto.Height := oTexto.Height + 12;
  dY := oTexto.Height + 14;
  oTexto := TextoA4(oBanda, AHoja.Tienda.Empresa, 0, dY,
    AAncho * 0.62, 11, True);
  dAlto := oTexto.Height;
  TextoA4(oBanda, SRotuloFechaHoja + ' ' + FechaHoja(AHoja.Fecha),
    AAncho * 0.66, dY, AAncho * 0.34, 10).HAlign := haRight;
  dY := dY + dAlto;
  oTexto := TextoA4(oBanda, DatosTiendaA4(AHoja.Tienda),
    0, dY, AAncho * 0.62, 9);
  oTexto.Font.Color := $00555555;
  dAlto := oTexto.Height;
  if AHoja.Liquidacion > 0 then
  begin
    oTexto := TextoA4(oBanda, SRotuloLiquidacionHoja + ' ' +
      IntToStr(AHoja.Liquidacion), AAncho * 0.66, dY,
      AAncho * 0.34, 11, True);
    oTexto.HAlign := haRight;
    dAlto := Max(dAlto, oTexto.Height);
  end;
  dY := dY + dAlto + 16;
  oTexto := TextoA4(oBanda,
    SRotuloProveedorHoja + ' ' + AHoja.Proveedor,
    0, dY, AAncho, 11, True);
  oTexto.Color := $00F0F0F0;
  oTexto.GapX := 10;
  oTexto.GapY := 8;
  oTexto.Height := oTexto.CalcHeight + 8;
  oBanda.Height := dY + oTexto.Height + 20;
end;

procedure ColumnasA4(APagina: TfrxReportPage; AAncho: Extended;
  AEsImporte: Boolean);
var
  oBanda: TfrxPageHeader;
  oTexto: TfrxMemoView;
  dDescripcion: Extended;
begin
  oBanda := TfrxPageHeader.Create(APagina);
  oBanda.CreateUniqueName;
  oBanda.Height := 30;
  oBanda.PrintOnFirstPage := True;
  dDescripcion := AAncho - 200;
  if AEsImporte then
    dDescripcion := dDescripcion - 100;
  TextoA4(oBanda, SColLiquidacion, 0, 0, 105, 9, True);
  TextoA4(oBanda, SColFechaLiquidacion, 105, 0, 95, 9, True);
  TextoA4(oBanda, SImpresoDescripcion, 200, 0,
    dDescripcion, 9, True);
  if AEsImporte then
    TextoA4(oBanda, SImpresoImporteColumna,
      AAncho - 100, 0, 100, 9, True).HAlign := haRight;
  oTexto := TextoA4(oBanda, '', 0, 26, AAncho, 1);
  oTexto.Height := 1;
  oTexto.Frame.Typ := [ftBottom];
  oTexto.Frame.Color := $00B0B0B0;
end;

procedure LineaA4(APagina: TfrxReportPage;
  const ALinea: TLineaHojaReparacion; AIndice: Integer;
  AAncho: Extended; AEsImporte: Boolean);
var
  oBanda: TfrxMasterData;
  oTexto: TfrxMemoView;
  dDescripcion, dY: Extended;
  sDetalle: string;
begin
  oBanda := TfrxMasterData.Create(APagina);
  oBanda.CreateUniqueName;
  oBanda.Top := 1000 + AIndice * 1000;
  oBanda.RowCount := 1;
  dDescripcion := AAncho - 200;
  if AEsImporte then
    dDescripcion := dDescripcion - 100;
  TextoA4(oBanda, ReferenciaLineaHoja(ALinea), 0, 6, 105, 9);
  TextoA4(oBanda, FechaHoja(ALinea.Fecha), 105, 6, 95, 9);
  oTexto := TextoA4(oBanda, ALinea.Trabajo, 200, 6,
    dDescripcion, 10, True);
  dY := 6 + oTexto.Height;
  if AEsImporte then
    TextoA4(oBanda, FormatFloat('#,##0.00', ALinea.Importe),
      AAncho - 100, 6, 100, 10, True).HAlign := haRight;
  sDetalle := Trim(ALinea.Objeto);
  if (Trim(ALinea.Detalles) <> '') and
     not SameText(Trim(ALinea.Detalles), sDetalle) then
  begin
    if sDetalle <> '' then
      sDetalle := sDetalle + sLineBreak;
    sDetalle := sDetalle + Trim(ALinea.Detalles);
  end;
  if sDetalle <> '' then
  begin
    oTexto := TextoA4(oBanda, sDetalle, 200, dY,
      dDescripcion, 9);
    oTexto.Font.Color := $00555555;
    dY := dY + oTexto.Height;
  end;
  oTexto := TextoA4(oBanda, '', 0, dY + 10, AAncho, 1);
  oTexto.Height := 1;
  oTexto.Frame.Typ := [ftBottom];
  oTexto.Frame.Color := $00DDDDDD;
  oBanda.Height := dY + 18;
  // Mantener cada trabajo junto, salvo textos mayores que una página.
  oBanda.AllowSplit := oBanda.Height >
    (APagina.PaperHeight - APagina.TopMargin - APagina.BottomMargin) *
    3.77953 - 60;
end;

procedure ResumenA4(APagina: TfrxReportPage;
  const AHoja: THojaReparaciones; AAncho: Extended);
var
  oBanda: TfrxReportSummary;
  oTexto: TfrxMemoView;
  Linea: TLineaHojaReparacion;
  dTotal, dY: Extended;
begin
  dTotal := 0;
  for Linea in AHoja.Lineas do
    dTotal := dTotal + Linea.Importe;
  oBanda := TfrxReportSummary.Create(APagina);
  oBanda.CreateUniqueName;
  oBanda.AllowSplit := False;
  oTexto := TextoA4(oBanda, Format(SHojaReparacionesLineas,
    [Length(AHoja.Lineas)]), 0, 16, AAncho * 0.32, 10);
  dY := 16 + oTexto.Height;
  if AHoja.EsImporte then
  begin
    oTexto := TextoA4(oBanda, Format(SHojaReparacionesTotal,
      [FormatFloat('#,##0.00', dTotal)]), AAncho * 0.32,
      16, AAncho * 0.68, 13, True);
    oTexto.HAlign := haRight;
    oTexto.Color := $00F0F0F0;
    oTexto.GapY := 8;
    oTexto.Height := oTexto.CalcHeight + 8;
    dY := Max(dY, 16 + oTexto.Height);
  end;
  oTexto := TextoA4(oBanda, SHojaReparacionesFirma,
    0, dY + 30, 220, 9);
  oTexto.Font.Color := $00555555;
  oTexto := TextoA4(oBanda, '', 0, dY + 100, 220, 1);
  oTexto.Height := 1;
  oTexto.Frame.Typ := [ftBottom];
  oTexto.Frame.Color := $00999999;
  oBanda.Height := dY + 112;
end;

procedure CrearHojaA4(AInforme: TfrxReport;
  const AHoja: THojaReparaciones);
var
  oPagina: TfrxReportPage;
  oPie: TfrxPageFooter;
  oTexto: TfrxMemoView;
  dAncho: Extended;
  i: Integer;
begin
  oPagina := CrearPagina(AInforme, fhrA4);
  oPagina.TitleBeforeHeader := True;
  dAncho := (oPagina.PaperWidth - oPagina.LeftMargin -
    oPagina.RightMargin) * 3.77953;
  CabeceraA4(oPagina, AHoja, dAncho);
  ColumnasA4(oPagina, dAncho, AHoja.EsImporte);
  for i := 0 to High(AHoja.Lineas) do
    LineaA4(oPagina, AHoja.Lineas[i], i, dAncho, AHoja.EsImporte);
  ResumenA4(oPagina, AHoja, dAncho);
  oPie := TfrxPageFooter.Create(oPagina);
  oPie.CreateUniqueName;
  oPie.Height := 24;
  oTexto := TextoA4(oPie, '[Page#]', 0, 0, dAncho, 8);
  oTexto.AllowExpressions := True;
  oTexto.HAlign := haRight;
  oTexto.Font.Color := $00777777;
end;

procedure CrearInformeHojaReparaciones(AInforme: TfrxReport;
  const AHoja: THojaReparaciones; AFormato: TFormatoHojaReparacion);
var
  oPagina: TfrxReportPage;
  oBanda: TfrxReportTitle;
  oTitulo: TfrxMemoView;
  dAncho: Extended;
begin
  AInforme.Clear;
  AInforme.ReportOptions.Name := AHoja.Titulo;
  AInforme.PreviewOptions.Modal := True;
  if AFormato = fhrA4 then
    CrearHojaA4(AInforme, AHoja)
  else
  begin
    oPagina := CrearPagina(AInforme, AFormato);
    dAncho := (oPagina.PaperWidth - oPagina.LeftMargin -
      oPagina.RightMargin) * 3.77953;
    oBanda := TfrxReportTitle.Create(oPagina);
    oBanda.CreateUniqueName;
    oBanda.Height := 60;
    oBanda.Stretched := True;
    oBanda.AllowSplit := True;
    oTitulo := CrearMemo(oBanda, 0, dAncho, 12);
    oTitulo.Height := 35;
    oTitulo.Font.Style := [fsBold];
    oTitulo.Text := AHoja.Titulo;
    CrearMemo(oBanda, 40, dAncho, 10).Text := TextoHojaReparaciones(AHoja);
  end;
end;

procedure ImprimirHojaReparacionesTicket(AInforme: TfrxReport;
  const ATitulo: string; const APreview: IPreviewTicket;
  const AImpresora, ARutaPdf: string);
var
  oTicket: TTicketTermico;
begin
  if not AInforme.PrepareReport then
    raise Exception.CreateFmt(SErrorImprimir, [ATitulo]);
  oTicket := TTicketTermico.Create(AImpresora);
  try
    ComponerTicketTextoDesdeInforme(AInforme, oTicket);
    ImprimirOPrevisualizarTicket(APreview, oTicket,
      oTicket.ObtenerComandos, ARutaPdf, AImpresora);
  finally
    FreeAndNil(oTicket);
  end;
end;

end.
