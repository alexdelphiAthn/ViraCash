unit inLibFuenteInterfaz;

interface

// La fuente se valida con GDI antes de utilizarla para medir o escalar UI.
function FuenteInterfazValida(const ANombre: string): Boolean;
function NombreFuenteInterfaz(
  const APreferida: string = 'Source Sans 3'): string;

implementation

uses
  Winapi.Windows,
  System.Types,
  System.SysUtils;

function FuenteInterfazValida(const ANombre: string): Boolean;
var
  hContexto: HDC;
  hFuente: HFONT;
  hAnterior: HGDIOBJ;
  oFuente: TLogFont;
  oTamano: TSize;
begin
  Result := False;
  oFuente := Default(TLogFont);
  oFuente.lfHeight := -15;
  oFuente.lfWeight := FW_NORMAL;
  oFuente.lfCharSet := DEFAULT_CHARSET;
  StrPLCopy(oFuente.lfFaceName, ANombre, LF_FACESIZE - 1);
  hContexto := CreateCompatibleDC(0);
  if hContexto <> 0 then
  begin
    try
      hFuente := CreateFontIndirect(oFuente);
      if hFuente <> 0 then
      begin
        try
          hAnterior := SelectObject(hContexto, hFuente);
          try
            oTamano := Default(TSize);
            Result := GetTextExtentPoint32(hContexto, 'Ag', 2, oTamano)
              and (oTamano.cx > 0) and (oTamano.cy > 0);
          finally
            SelectObject(hContexto, hAnterior);
          end;
        finally
          DeleteObject(hFuente);
        end;
      end;
    finally
      DeleteDC(hContexto);
    end;
  end;
end;

function NombreFuenteInterfaz(const APreferida: string): string;
begin
  Result := APreferida;
  if not FuenteInterfazValida(Result) then
    Result := 'Segoe UI';
end;

end.
