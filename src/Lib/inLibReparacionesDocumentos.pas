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
  System.SysUtils, System.Classes, Vcl.Graphics,
  inLibMsgReparaciones, inLibMsgComun, inLibFTicket, inLibTicketImagenFR;

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

procedure AgregarLinea(ALineas: TStrings; const ALinea: TLineaHojaReparacion;
  AEsImporte: Boolean);
var
  sLinea: string;
begin
  sLinea := Format('%d  %s  %s', [ALinea.Reparacion,
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
    oTicket.Inicializar;
    // Mismo circuito raster y salida de caja, sin abrir el cajón.
    if not ComponerTicketDesdeInforme(AInforme, oTicket, False) then
      raise Exception.CreateFmt(SErrorImprimir, [ATitulo]);
    ImprimirOPrevisualizarTicket(APreview, oTicket,
      oTicket.ObtenerComandos, ARutaPdf, AImpresora);
  finally
    FreeAndNil(oTicket);
  end;
end;

end.
