{******************************************************************************}
{                                                                              }
{  Módulo:       inLibRetiradaLotesTicket                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       13/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:  Ticket térmico de retirada y otros lotes urgentes.            }
{******************************************************************************}
unit inLibRetiradaLotesTicket;

interface

uses
  inLibRetiradaLotesIntf, inLibPreviewTicket;

function TextoTicketRetirada(const AOrden: TOrdenRetiradaLotes;
  const AFormato: string): TArray<string>;
procedure ImprimirTicketRetirada(const APreview: IPreviewTicket;
  const AOrden: TOrdenRetiradaLotes; const AImpresora, AFormato: string);

implementation

uses
  System.SysUtils, System.Classes, inLibFTicket, inLibDir,
  inLibRetiradaLotes, inLibMsgRetiradaLotes;

function AnchoFormato(const AFormato: string): Integer;
begin
  if SameText(AFormato, 'TEXTO32') then
    Result := 32
  else if (Trim(AFormato) = '') or SameText(AFormato, 'TEXTO42') then
    Result := 42
  else
    raise EArgumentException.CreateFmt(SErrorFormatoTicketRetirada,
      [AFormato]);
end;

procedure AnadirTexto(ALineas: TStrings; const ATexto: string;
  AAncho: Integer);
var
  sPendiente: string;
  iCorte, Indice: Integer;
begin
  sPendiente := ATexto;
  for Indice := 1 to Length(sPendiente) do
    if Ord(sPendiente[Indice]) < 32 then
      sPendiente[Indice] := ' ';
  while Length(sPendiente) > AAncho do
  begin
    iCorte := AAncho;
    while (iCorte > 1) and (sPendiente[iCorte] <> ' ') do
      Dec(iCorte);
    if iCorte = 1 then
      iCorte := AAncho;
    ALineas.Add(TrimRight(Copy(sPendiente, 1, iCorte)));
    sPendiente := TrimLeft(Copy(sPendiente, iCorte + 1, MaxInt));
  end;
  ALineas.Add(sPendiente);
end;

procedure AnadirLineaLote(ALineas: TStrings;
  const ALinea: TLineaRetiradaLote; AAncho: Integer);
begin
  AnadirTexto(ALineas, ALinea.CodigoArticulo + ' - ' +
    ALinea.Descripcion, AAncho);
  AnadirTexto(ALineas, ALinea.CodigoSku, AAncho);
  AnadirTexto(ALineas, SAlmacenTicketRetirada +
    ALinea.CodigoAlmacen, AAncho);
  AnadirTexto(ALineas, SLoteTicketRetirada + ALinea.Lote, AAncho);
  if ALinea.FechaCaducidad > 0 then
    AnadirTexto(ALineas, SFechaTicketRetirada +
      FormatDateTime('dd/mm/yyyy', ALinea.FechaCaducidad), AAncho);
  AnadirTexto(ALineas, SCantidadTicketRetirada +
    FormatFloat('0.######', ALinea.Cantidad), AAncho);
  AnadirTexto(ALineas, SUbicacionTicketRetirada + ALinea.Ubicacion, AAncho);
  if ALinea.NumeroMovimiento <> '' then
    AnadirTexto(ALineas, SMovimientoTicketRetirada +
      ALinea.NumeroMovimiento + ' / ' + ALinea.NumeroMovimientoDestino,
      AAncho);
  ALineas.Add(StringOfChar('-', AAncho));
end;

procedure AnadirCabecera(ALineas: TStrings;
  const AOrden: TOrdenRetiradaLotes; AAncho: Integer);
begin
  if AOrden.EsUrgente then
    AnadirTexto(ALineas, STituloOrdenRetiradaUrgente, AAncho)
  else
    AnadirTexto(ALineas, STituloOrdenRetirada, AAncho);
  AnadirTexto(ALineas, AOrden.Id, AAncho);
  AnadirTexto(ALineas,
    FormatDateTime('dd/mm/yyyy hh:nn:ss', AOrden.Instante), AAncho);
  AnadirTexto(ALineas, SEmpresaTicketRetirada + AOrden.Empresa, AAncho);
  AnadirTexto(ALineas, SEmpleadoTicketRetirada + AOrden.Empleado, AAncho);
  AnadirTexto(ALineas, SMotivoTicketRetirada +
    TextoMotivoRetirada(AOrden.Motivo), AAncho);
  AnadirTexto(ALineas, SDestinoTicketRetirada +
    AOrden.AlmacenDestino, AAncho);
  ALineas.Add(StringOfChar('=', AAncho));
end;

function TextoTicketRetirada(const AOrden: TOrdenRetiradaLotes;
  const AFormato: string): TArray<string>;
var
  stLineas: TStringList;
  rLinea: TLineaRetiradaLote;
  iAncho: Integer;
begin
  iAncho := AnchoFormato(AFormato);
  stLineas := TStringList.Create;
  try
    AnadirCabecera(stLineas, AOrden, iAncho);
    for rLinea in AOrden.Lineas do
      AnadirLineaLote(stLineas, rLinea, iAncho);
    AnadirTexto(stLineas, SUnidadesRealesRetirada, iAncho);
    AnadirTexto(stLineas, SFirmaRetirada, iAncho);
    if Length(AOrden.Urgentes) > 0 then
    begin
      stLineas.Add('');
      AnadirTexto(stLineas, SOtrosUrgentesTicketRetirada, iAncho);
      AnadirTexto(stLineas, SNotaUrgentesTicketRetirada, iAncho);
      for rLinea in AOrden.Urgentes do
        AnadirLineaLote(stLineas, rLinea, iAncho);
    end;
    Result := stLineas.ToStringArray;
  finally
    FreeAndNil(stLineas);
  end;
end;

procedure ImprimirTicketRetirada(const APreview: IPreviewTicket;
  const AOrden: TOrdenRetiradaLotes; const AImpresora, AFormato: string);
var
  oTicket: TTicketTermico;
  sLinea: string;
begin
  if not Assigned(APreview) then
    raise EArgumentNilException.Create('APreview');
  oTicket := TTicketTermico.Create(AImpresora);
  try
    oTicket.Inicializar;
    oTicket.ConfigurarEspanol;
    oTicket.SeleccionarFuente(ftRasterA);
    for sLinea in TextoTicketRetirada(AOrden, AFormato) do
      oTicket.EscribirLinea(sLinea);
    oTicket.AvanzarYCortarPapel(4);
    ImprimirOPrevisualizarTicket(APreview, oTicket,
      oTicket.ObtenerComandos,
      GetUserFolderTickets + 'Retirada_' + AOrden.Id + '.pdf', AImpresora);
  finally
    FreeAndNil(oTicket);
  end;
end;

end.
