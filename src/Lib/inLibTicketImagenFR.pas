{******************************************************************************}
{                                                                              }
{  Módulo:       inLibTicketImagenFR                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Ticket de caja diseñado en FastReport e impreso como imagen: las páginas  }
{    preparadas se dibujan al ancho de la impresora térmica (576 puntos,       }
{    80 mm a 203 ppp), se recorta el blanco final y se envían como raster      }
{    ESC/POS (GS v 0), seguidas de corte y apertura de cajón.                  }
{                                                                              }
{    Los formatos de ticket son formatos de factura (frmPrintFac) cuyo nombre  }
{    empieza por cPrefijoFormatoTicket (inLibCajaParam).                       }
{******************************************************************************}
unit inLibTicketImagenFR;

interface

uses
  frxClass, inLibFTicket;

const
  cAnchoPuntosTicket = 576;

// Añade al ticket las páginas preparadas de AInforme como imagen, el avance
// con corte. El cajón es opcional para documentos ajenos a un cobro.
// False si el informe no tiene páginas.
function ComponerTicketDesdeInforme(AInforme: TfrxReport;
  ATicket: TTicketTermico; AAbrirCajon: Boolean = True): Boolean;

implementation

uses
  System.SysUtils, System.Types, Vcl.Graphics;

// Última fila con algún punto oscuro; -1 si la imagen está en blanco.
function UltimaFilaConTinta(ABitmap: TBitmap): Integer;
var
  y, x: Integer;
  pFila: PByte;
begin
  Result := -1;
  for y := ABitmap.Height - 1 downto 0 do
  begin
    pFila := ABitmap.ScanLine[y];
    for x := 0 to ABitmap.Width - 1 do
    begin
      if (pFila[0] < 200) or (pFila[1] < 200) or (pFila[2] < 200) then
        Exit(y);
      Inc(pFila, 3);
    end;
  end;
end;

function ComponerTicketDesdeInforme(AInforme: TfrxReport;
  ATicket: TTicketTermico; AAbrirCajon: Boolean): Boolean;
const
  cMargenFinalPuntos = 16;
var
  oPagina: TBitmap;
  rTamano: TPoint;
  dEscala: Double;
  iPagina, iUltima: Integer;
begin
  Result := (AInforme <> nil) and (AInforme.PreviewPages.Count > 0);
  if not Result then
    Exit;
  for iPagina := 0 to AInforme.PreviewPages.Count - 1 do
  begin
    rTamano := AInforme.PreviewPages.PageSize[iPagina];
    if rTamano.X <= 0 then
      Continue;
    dEscala := cAnchoPuntosTicket / rTamano.X;
    oPagina := TBitmap.Create;
    try
      oPagina.PixelFormat := pf24bit;
      oPagina.SetSize(cAnchoPuntosTicket, Round(rTamano.Y * dEscala));
      oPagina.Canvas.Brush.Color := clWhite;
      oPagina.Canvas.FillRect(Rect(0, 0, oPagina.Width, oPagina.Height));
      AInforme.PreviewPages.DrawPage(iPagina, oPagina.Canvas,
        dEscala, dEscala, 0, 0);
      // El papel es continuo: fuera el blanco sobrante de la página.
      iUltima := UltimaFilaConTinta(oPagina);
      if iUltima < 0 then
        Continue;
      if iUltima + cMargenFinalPuntos < oPagina.Height then
        oPagina.Height := iUltima + cMargenFinalPuntos;
      ATicket.ImprimirImagenRaster(oPagina);
    finally
      FreeAndNil(oPagina);
    end;
  end;
  ATicket.AvanzarYCortarPapel(4);
  if AAbrirCajon then
    ATicket.AbrirCajon;
end;

end.
