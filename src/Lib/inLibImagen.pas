{******************************************************************************}
{                                                                              }
{  Módulo:       inLibImagen                                                   }
{    Tipo:       Utilidad (Lib)                                                }
{ Versión:       1.0.0                                                         }
{   Fecha:       14/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Utilidades de imagen para la interfaz. EscalarSuavizado redimensiona un   }
{    TGraphic (PNG con alfa incluido) con interpolación bicúbica de alta       }
{    calidad vía GDI+, evitando el pixelado del StretchBlt nativo de la VCL.   }
{******************************************************************************}
unit inLibImagen;

interface

uses
  Vcl.Graphics;

// Redimensiona AOrigen para encajar dentro de una caja AAnchoCaja x
// AAltoCaja manteniendo la proporción del original, con interpolación
// bicúbica de alta calidad (GDI+) y conservando el canal alfa. Devuelve un
// TBitmap de 32 bits con alfa premultiplicado del tamaño ya ajustado (no de
// la caja): el llamante lo asigna a un TImage con Stretch:=False para que lo
// pinte 1:1, sin el pixelado del StretchBlt. La propiedad del TBitmap pasa
// al llamante, que debe liberarlo. Devuelve nil si no se pudo escalar.
function EscalarSuavizado(const AOrigen: TGraphic;
  AAnchoCaja, AAltoCaja: Integer): Vcl.Graphics.TBitmap;

implementation

uses
  Winapi.Windows, System.Classes, Winapi.ActiveX,
  Winapi.GDIPAPI, Winapi.GDIPOBJ;

function EscalarSuavizado(const AOrigen: TGraphic;
  AAnchoCaja, AAltoCaja: Integer): Vcl.Graphics.TBitmap;
var
  oMem      : TMemoryStream;
  oStream   : IStream;
  gpOrigen  : TGPBitmap;
  gpDestino : TGPBitmap;
  gpGfx     : TGPGraphics;
  hBmp      : HBITMAP;
  iAnchoOrg : Integer;
  iAltoOrg  : Integer;
  iAncho    : Integer;
  iAlto     : Integer;
  dEscala   : Double;
begin
  Result := nil;
  // Validamos entradas; si algo no cuadra devolvemos nil y el llamante
  // mantiene su comportamiento previo (mostrar el PNG sin escalar).
  if (AOrigen <> nil) and (not AOrigen.Empty) and
     (AAnchoCaja >= 1) and (AAltoCaja >= 1) then
  begin
    oMem := TMemoryStream.Create;
    try
      // Serializamos el TGraphic a su formato nativo (PNG con alfa para
      // TPngImage) y se lo damos a GDI+ como IStream: así conserva el canal
      // alfa, que un HBITMAP plano perdería.
      AOrigen.SaveToStream(oMem);
      oMem.Position := 0;
      oStream := TStreamAdapter.Create(oMem, soReference);
      gpOrigen := TGPBitmap.Create(oStream);
      try
        iAnchoOrg := Integer(gpOrigen.GetWidth);
        iAltoOrg  := Integer(gpOrigen.GetHeight);
        if (iAnchoOrg >= 1) and (iAltoOrg >= 1) then
        begin
          // Encaje proporcional dentro de la caja (manda el lado que
          // primero toca el borde).
          dEscala := AAnchoCaja / iAnchoOrg;
          if (AAltoCaja / iAltoOrg) < dEscala then
            dEscala := AAltoCaja / iAltoOrg;
          iAncho := Round(iAnchoOrg * dEscala);
          iAlto  := Round(iAltoOrg * dEscala);
          if iAncho < 1 then
            iAncho := 1;
          if iAlto < 1 then
            iAlto := 1;
          // Lienzo destino ARGB premultiplicado, limpio a transparente:
          // pintamos el origen escalado con calidad alta para conservar los
          // bordes suaves y el fondo transparente del logo.
          gpDestino := TGPBitmap.Create(iAncho, iAlto,
                                        PixelFormat32bppPARGB);
          try
            gpGfx := TGPGraphics.Create(gpDestino);
            try
              gpGfx.SetInterpolationMode(
                InterpolationModeHighQualityBicubic);
              gpGfx.SetPixelOffsetMode(PixelOffsetModeHighQuality);
              gpGfx.SetSmoothingMode(SmoothingModeHighQuality);
              gpGfx.Clear(MakeColor(0, 0, 0, 0));
              gpGfx.DrawImage(gpOrigen, 0, 0, iAncho, iAlto);
            finally
              gpGfx.Free;
            end;
            // Volcamos a HBITMAP sobre fondo transparente: el DIB queda con
            // alfa premultiplicado, listo para que el TImage lo mezcle
            // (AlphaBlend) sobre el panel.
            if gpDestino.GetHBITMAP(MakeColor(0, 0, 0, 0), hBmp) = Ok then
            begin
              Result := Vcl.Graphics.TBitmap.Create;
              Result.Handle := hBmp;
              Result.AlphaFormat := afPremultiplied;
            end;
          finally
            gpDestino.Free;
          end;
        end;
      finally
        gpOrigen.Free;
      end;
    finally
      // TStreamAdapter(soReference) no posee oMem; soltamos la referencia
      // COM y liberamos el stream nosotros.
      oStream := nil;
      oMem.Free;
    end;
  end;
end;

end.
