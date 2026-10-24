{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGarantiasResguardo                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       19/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Resguardo de depósito de garantías en ticket o A4, con FastReport.       }
{******************************************************************************}
unit inLibGarantiasResguardo;

interface

uses
  frxClass, inLibPreviewTicket;

type
  TFormatoResguardoGarantia = (frgTicket, frgA4);
  TResguardoGarantia = record
    Numero: Int64;
    Fecha: TDateTime;
    Recepcion: TDateTime;
    Empresa: string;
    Nif: string;
    Tienda: string;
    DireccionTienda: string;
    PoblacionTienda: string;
    TelefonoTienda: string;
    Cliente: string;
    TelefonoCliente: string;
    Articulo: string;
    Descripcion: string;
    Modelo: string;
    Serie: string;
    Motivo: string;
    Observaciones: string;
    Medio: string;
    DocumentoVenta: string;
    FechaVenta: TDateTime;
    FinGarantia: TDateTime;
    EnGarantia: Boolean;
  end;

function TextoResguardoGarantia(const ADatos: TResguardoGarantia): string;
function FormatoResguardoGarantia(const ATipoImpresion: string):
  TFormatoResguardoGarantia;
procedure CrearInformeResguardoGarantia(AInforme: TfrxReport;
  const ADatos: TResguardoGarantia; AFormato: TFormatoResguardoGarantia);

procedure ImprimirResguardoGarantiaTicket(AInforme: TfrxReport;
  const APreview: IPreviewTicket; const AImpresora, ARutaPdf: string);

implementation

uses
  System.SysUtils, System.Classes, Vcl.Graphics,
  inLibGarantias, inLibMsgGarantias, inLibMsgComun,
  inLibFTicket, inLibTicketImagenFR;

function FechaResguardo(AFecha: TDateTime): string;
begin
  Result := '';
  if AFecha > 0 then
    Result := FormatDateTime('dd/mm/yyyy', AFecha);
end;

procedure AgregarDato(ALineas: TStrings;
  const ARotulo, AValor: string);
begin
  if Trim(AValor) <> '' then
    ALineas.Add(ARotulo + ' ' + Trim(AValor));
end;

procedure AgregarTienda(ALineas: TStrings;
  const ADatos: TResguardoGarantia);
begin
  ALineas.Add(ADatos.Empresa);
  ALineas.Add(ADatos.Nif);
  ALineas.Add(ADatos.Tienda);
  ALineas.Add(ADatos.DireccionTienda);
  ALineas.Add(ADatos.PoblacionTienda);
  AgregarDato(ALineas, SCaptionGarantiaTelefonoFicha,
    ADatos.TelefonoTienda);
  ALineas.Add('');
end;

procedure AgregarGarantia(ALineas: TStrings;
  const ADatos: TResguardoGarantia);
var
  sCobertura: string;
begin
  sCobertura := SResguardoFueraGarantia;
  if ADatos.EnGarantia then
    sCobertura := SCaptionColGarantiaEnGarantia;
  ALineas.Add(sCobertura);
  AgregarDato(ALineas, SCaptionGarantiaVentaFicha, ADatos.DocumentoVenta);
  AgregarDato(ALineas, SCaptionGarantiaFechaVentaFicha,
    FechaResguardo(ADatos.FechaVenta));
  AgregarDato(ALineas, SCaptionGarantiaFinGarantiaFicha,
    FechaResguardo(ADatos.FinGarantia));
end;

function TextoResguardoGarantia(const ADatos: TResguardoGarantia): string;
var
  stLineas: TStringList;
begin
  stLineas := TStringList.Create;
  try
    AgregarTienda(stLineas, ADatos);
    AgregarDato(stLineas, SCaptionGrupoReclamacion + ':',
      IntToStr(ADatos.Numero));
    AgregarDato(stLineas, SCaptionGarantiaFechaReclamacion,
      FechaResguardo(ADatos.Fecha));
    AgregarDato(stLineas, SCaptionGarantiaFechaRecepcion,
      FechaResguardo(ADatos.Recepcion));
    AgregarDato(stLineas, SCaptionGarantiaClienteFicha, ADatos.Cliente);
    AgregarDato(stLineas, SCaptionGarantiaTelefonoFicha,
      ADatos.TelefonoCliente);
    stLineas.Add('');
    AgregarDato(stLineas, SCaptionGarantiaArticuloFicha, ADatos.Articulo);
    stLineas.Add(ADatos.Descripcion);
    AgregarDato(stLineas, SCaptionGarantiaModeloFicha, ADatos.Modelo);
    AgregarDato(stLineas, SCaptionGarantiaSerieFicha, ADatos.Serie);
    AgregarDato(stLineas, SCaptionGarantiaMotivoFicha, ADatos.Motivo);
    AgregarDato(stLineas, SCaptionGarantiaObservacionesFicha,
      ADatos.Observaciones);
    AgregarDato(stLineas, SCaptionGarantiaMedio,
      TextoMedioGarantia(ADatos.Medio));
    stLineas.Add('');
    AgregarGarantia(stLineas, ADatos);
    stLineas.Add('');
    stLineas.Add(SResguardoConservar);
    stLineas.Add('');
    stLineas.Add('');
    stLineas.Add(SResguardoFirmaCliente);
    stLineas.Add('');
    stLineas.Add('____________________________');
    Result := stLineas.Text;
  finally
    FreeAndNil(stLineas);
  end;
end;

function FormatoResguardoGarantia(const ATipoImpresion: string):
  TFormatoResguardoGarantia;
begin
  Result := frgTicket;
  if SameText(Trim(ATipoImpresion), 'EDITOR') or
     SameText(Trim(ATipoImpresion), 'A4') then
    Result := frgA4;
end;

function CrearPaginaResguardo(AInforme: TfrxReport;
  AFormato: TFormatoResguardoGarantia): TfrxReportPage;
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
  if AFormato = frgTicket then
  begin
    Result.PaperWidth := 80;
    Result.LeftMargin := 4;
    Result.RightMargin := 4;
    Result.TopMargin := 4;
    Result.BottomMargin := 4;
    Result.EndlessHeight := True;
  end;
end;

procedure CrearInformeResguardoGarantia(AInforme: TfrxReport;
  const ADatos: TResguardoGarantia; AFormato: TFormatoResguardoGarantia);
var
  oPagina: TfrxReportPage;
  oBanda: TfrxReportTitle;
  oTitulo, oTexto: TfrxMemoView;
  dAncho: Extended;
begin
  AInforme.Clear;
  AInforme.ReportOptions.Name := SCaptionResguardoGarantia;
  AInforme.PreviewOptions.Modal := True;
  oPagina := CrearPaginaResguardo(AInforme, AFormato);
  dAncho := (oPagina.PaperWidth - oPagina.LeftMargin -
    oPagina.RightMargin) * 3.77953;
  oBanda := TfrxReportTitle.Create(oPagina);
  oBanda.CreateUniqueName;
  oBanda.Height := 60;
  oBanda.Stretched := True;
  oBanda.AllowSplit := True;
  oTitulo := TfrxMemoView.Create(oBanda);
  oTitulo.CreateUniqueName;
  oTitulo.SetBounds(0, 0, dAncho, 35);
  oTitulo.Font.Name := 'Arial';
  oTitulo.Font.Size := 12;
  oTitulo.Font.Style := [fsBold];
  oTitulo.AllowExpressions := False;
  oTitulo.Text := SCaptionResguardoGarantia;
  oTexto := TfrxMemoView.Create(oBanda);
  oTexto.CreateUniqueName;
  oTexto.SetBounds(0, 40, dAncho, 20);
  oTexto.Font.Name := 'Arial';
  oTexto.Font.Size := 10;
  oTexto.WordWrap := True;
  oTexto.StretchMode := smActualHeight;
  // Los corchetes del motivo o del nombre son datos, nunca expresiones.
  oTexto.AllowExpressions := False;
  oTexto.Text := TextoResguardoGarantia(ADatos);
end;

procedure ImprimirResguardoGarantiaTicket(AInforme: TfrxReport;
  const APreview: IPreviewTicket; const AImpresora, ARutaPdf: string);
var
  oTicket: TTicketTermico;
begin
  if not AInforme.PrepareReport then
    raise Exception.CreateFmt(SErrorImprimir, [SCaptionResguardoGarantia]);
  oTicket := TTicketTermico.Create(AImpresora);
  try
    oTicket.Inicializar;
    // Mismo circuito raster y salida de caja, sin abrir el cajon.
    if not ComponerTicketDesdeInforme(AInforme, oTicket, False) then
      raise Exception.CreateFmt(SErrorImprimir,
        [SCaptionResguardoGarantia]);
    ImprimirOPrevisualizarTicket(APreview, oTicket,
      oTicket.ObtenerComandos, ARutaPdf, AImpresora);
  finally
    FreeAndNil(oTicket);
  end;
end;

end.
