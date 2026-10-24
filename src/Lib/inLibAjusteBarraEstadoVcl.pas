{******************************************************************************}
{                                                                              }
{  Módulo:       inLibAjusteBarraEstadoVcl                                     }
{    Tipo:       Librería (VCL)                                                }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Reparte el ancho de una barra de estado entre sus paneles según el texto  }
{    de cada uno y el espacio disponible. Con anchos fijos, si la ventana es   }
{    más estrecha que su suma los paneles se salían por la derecha y el texto  }
{    del último se pintaba encima del anterior.                                }
{    - Hay sitio: cada panel ocupa su ancho preferido o el que pida su texto.  }
{    - Falta sitio: cada panel ocupa justo lo que pide su texto y, si aun así  }
{      no cabe, se recortan los paneles en el orden indicado (los menos        }
{      importantes primero) hasta dejarlos a cero.                             }
{******************************************************************************}
unit inLibAjusteBarraEstadoVcl;

interface

uses
  Vcl.ComCtrls;

// APreferidos: ancho preferido de cada panel a 96 ppp (se escala al de la
// barra). AOrdenRecorte: índices de los paneles que pueden recortarse, del
// primero al último en sacrificarse; los que no aparecen no se recortan.
procedure AjustarPanelesBarraEstado(
  ABarra: TStatusBar;
  const APreferidos: array of Integer;
  const AOrdenRecorte: array of Integer;
  ARellenarUltimo: Boolean = False);

implementation

uses
  System.Math, System.Classes;

const
  // Bisel y márgenes interiores del panel a cada lado del texto (96 ppp).
  MARGEN_TEXTO_PANEL = 14;

function AnchoTextoPanel(ABarra: TStatusBar; AIndice: Integer): Integer;
var
  sTexto: string;
begin
  sTexto := ABarra.Panels[AIndice].Text;
  Result := ABarra.ScaleValue(MARGEN_TEXTO_PANEL);
  if sTexto <> '' then
    Result := Result + ABarra.Canvas.TextWidth(sTexto);
end;

procedure AjustarPanelesBarraEstado(
  ABarra: TStatusBar;
  const APreferidos: array of Integer;
  const AOrdenRecorte: array of Integer;
  ARellenarUltimo: Boolean);
var
  aAnchos: TArray<Integer>;
  aNecesarios: TArray<Integer>;
  i: Integer;
  iDisponible: Integer;
  iExceso: Integer;
  iIndice: Integer;
  iRecorte: Integer;
  iTotal: Integer;
begin
  if Assigned(ABarra) and ABarra.HandleAllocated and
     (ABarra.Panels.Count > 0) then
  begin
    ABarra.Canvas.Font := ABarra.Font;
    SetLength(aAnchos, ABarra.Panels.Count);
    SetLength(aNecesarios, ABarra.Panels.Count);
    iDisponible := ABarra.ClientWidth;
    if ABarra.SizeGrip then
      iDisponible := iDisponible - ABarra.ClientHeight;
    iTotal := 0;
    for i := 0 to ABarra.Panels.Count - 1 do
    begin
      aNecesarios[i] := AnchoTextoPanel(ABarra, i);
      aAnchos[i] := aNecesarios[i];
      if i <= High(APreferidos) then
        aAnchos[i] := Max(aAnchos[i], ABarra.ScaleValue(APreferidos[i]));
      iTotal := iTotal + aAnchos[i];
    end;
    if iTotal > iDisponible then
    begin
      aAnchos := Copy(aNecesarios);
      iTotal := SumInt(aAnchos);
    end;
    iExceso := iTotal - iDisponible;
    i := 0;
    while (iExceso > 0) and (i <= High(AOrdenRecorte)) do
    begin
      iIndice := AOrdenRecorte[i];
      if (iIndice >= 0) and (iIndice < Length(aAnchos)) then
      begin
        iRecorte := Min(aAnchos[iIndice], iExceso);
        aAnchos[iIndice] := aAnchos[iIndice] - iRecorte;
        iExceso := iExceso - iRecorte;
      end;
      Inc(i);
    end;
    if ARellenarUltimo then
    begin
      iTotal := SumInt(aAnchos);
      if iTotal < iDisponible then
        Inc(aAnchos[High(aAnchos)], iDisponible - iTotal);
    end;
    ABarra.Panels.BeginUpdate;
    try
      for i := 0 to ABarra.Panels.Count - 1 do
        if ABarra.Panels[i].Width <> aAnchos[i] then
          ABarra.Panels[i].Width := aAnchos[i];
    finally
      ABarra.Panels.EndUpdate;
    end;
  end;
end;

end.
