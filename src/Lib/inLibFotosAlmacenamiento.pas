{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFotosAlmacenamiento                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Almacenamiento físico, conversión, tamaño y rotación de fotografías.      }
{******************************************************************************}
unit inLibFotosAlmacenamiento;

interface

uses
  System.SysUtils,
  Vcl.Graphics,
  inLibParametrosIntf, inLibFotosTipos;

type
  TAlmacenamientoFotos = class
  private
    FParametrosApp: IParametrosAplicacion;
    function DirectorioBase: string;
    function Subdirectorio(AResolucion: TFotoResolucion): string;
    function CargarGraficoDeFichero(const ARuta: string): TGraphic;
    procedure GuardarComoPng(const AOriginal: TGraphic;
      const ARutaPng: string);
    procedure GuardarRedimensionado(const AOriginal: TGraphic;
      const ARutaPng: string; ALadoMayor: Integer);
    procedure RotarBitmap90(ABitmap: Vcl.Graphics.TBitmap;
      AHorario: Boolean);
    procedure RotarFicheroPng(const ARuta: string; AHorario: Boolean);
    procedure RenombrarSiExiste(const ARutaOrigen,
      ARutaDestino: string);
  public
    procedure AsignarParametros(
      const AParametrosApp: IParametrosAplicacion);
    procedure LiberarServicios;
    function ClaveNombre(const ACodigoArticulo,
      ACodigoSku: string): string;
    function ComponerNombre(const AClave: string;
      AIndice: Integer): string;
    function ExtraerIndice(const ANombre: string): Integer;
    function ExtensionOrigen(const ARuta: string): string;
    function RutaDeNombre(const ANombre: string;
      AResolucion: TFotoResolucion): string;
    function RutaFoto(const AInfo: TFotoInfo;
      AResolucion: TFotoResolucion): string;
    procedure GuardarCopias(const AFicheroOrigen,
      ANombre: string);
    procedure RotarCopias(const ANombreAnterior,
      ANombreNuevo: string; AHorario: Boolean);
    procedure RenombrarCopias(const ANombreAnterior,
      ANombreNuevo: string);
    procedure BorrarCopias(const ANombre: string);
  end;

implementation

uses
  Winapi.Windows, Winapi.GDIPOBJ, Winapi.GDIPAPI,
  Vcl.Imaging.PngImage, Vcl.Imaging.Jpeg, Vcl.Imaging.GIFImg,
  inLibMsgArticulos;

function SanearNombre(const AOriginal: string): string;
var
  cCaracter: Char;
  iCaracter: Integer;
begin
  Result := '';
  for iCaracter := 1 to Length(AOriginal) do
  begin
    cCaracter := AOriginal[iCaracter];
    case cCaracter of
      '/', '\', ':', '*', '?', '"', '<', '>', '|':
        Result := Result + '_';
    else
      Result := Result + cCaracter;
    end;
  end;
end;

procedure TAlmacenamientoFotos.AsignarParametros(
  const AParametrosApp: IParametrosAplicacion);
begin
  FParametrosApp := AParametrosApp;
end;

procedure TAlmacenamientoFotos.LiberarServicios;
begin
  FParametrosApp := nil;
end;

function TAlmacenamientoFotos.DirectorioBase: string;
begin
  Result := '';
  if Assigned(FParametrosApp) then
  begin
    Result := FParametrosApp.GetPath('appDirFotos');
    if Result <> '' then
      Result := IncludeTrailingPathDelimiter(Result);
  end;
end;

function TAlmacenamientoFotos.Subdirectorio(
  AResolucion: TFotoResolucion): string;
var
  sBase: string;
begin
  Result := '';
  sBase := DirectorioBase;
  if sBase <> '' then
  begin
    case AResolucion of
      frPx300:
        Result := sBase + cSubdir300;
      frPx600:
        Result := sBase + cSubdir600;
      frReal:
        Result := sBase + cSubdirReal;
    end;
    Result := IncludeTrailingPathDelimiter(Result);
  end;
end;

function TAlmacenamientoFotos.ClaveNombre(const ACodigoArticulo,
  ACodigoSku: string): string;
begin
  if ACodigoSku = '' then
    Result := SanearNombre(ACodigoArticulo)
  else
    Result := SanearNombre(ACodigoSku);
end;

function TAlmacenamientoFotos.ComponerNombre(const AClave: string;
  AIndice: Integer): string;
begin
  Result := AClave + '_' + Format('%.3d', [AIndice]);
end;

function TAlmacenamientoFotos.ExtraerIndice(
  const ANombre: string): Integer;
var
  iPosicion: Integer;
  sNumero  : string;
begin
  Result := 0;
  iPosicion := LastDelimiter('_', ANombre);
  if iPosicion > 0 then
  begin
    sNumero := Copy(ANombre, iPosicion + 1, MaxInt);
    if not TryStrToInt(sNumero, Result) then
      Result := 0;
  end;
end;

function TAlmacenamientoFotos.ExtensionOrigen(
  const ARuta: string): string;
begin
  Result := LowerCase(ExtractFileExt(ARuta));
  if Length(Result) > 0 then
    Result := Copy(Result, 2, MaxInt);
  if Result = '' then
    Result := 'png';
end;

function TAlmacenamientoFotos.RutaDeNombre(const ANombre: string;
  AResolucion: TFotoResolucion): string;
begin
  Result := '';
  if ANombre <> '' then
  begin
    Result := Subdirectorio(AResolucion);
    if Result <> '' then
      Result := Result + ANombre + '.png';
  end;
end;

function TAlmacenamientoFotos.RutaFoto(const AInfo: TFotoInfo;
  AResolucion: TFotoResolucion): string;
begin
  Result := '';
  if AInfo.Encontrada then
  begin
    Result := RutaDeNombre(AInfo.NombreBase, AResolucion);
    if (Result <> '') and (not FileExists(Result)) then
      Result := '';
  end;
end;

function TAlmacenamientoFotos.CargarGraficoDeFichero(
  const ARuta: string): TGraphic;
var
  oBitmap: Vcl.Graphics.TBitmap;
  oGif   : TGIFImage;
  oJpeg  : TJPEGImage;
  oPng   : TPngImage;
  oWic   : TWICImage;
  sCodec : string;
  sExt   : string;
begin
  sExt := LowerCase(ExtractFileExt(ARuta));
  if sExt = '.png' then
  begin
    oPng := TPngImage.Create;
    try
      oPng.LoadFromFile(ARuta);
      Result := oPng;
    except
      FreeAndNil(oPng);
      raise;
    end;
  end
  else if (sExt = '.jpg') or (sExt = '.jpeg') then
  begin
    oJpeg := TJPEGImage.Create;
    try
      oJpeg.LoadFromFile(ARuta);
      Result := oJpeg;
    except
      FreeAndNil(oJpeg);
      raise;
    end;
  end
  else if sExt = '.gif' then
  begin
    oGif := TGIFImage.Create;
    try
      oGif.LoadFromFile(ARuta);
      Result := oGif;
    except
      FreeAndNil(oGif);
      raise;
    end;
  end
  else if (sExt = '.webp') or (sExt = '.avif') or
          (sExt = '.heic') or (sExt = '.heif') then
  begin
    oWic := TWICImage.Create;
    try
      try
        oWic.LoadFromFile(ARuta);
      except
        on E: Exception do
        begin
          if sExt = '.webp' then
            sCodec := 'WebP Imaging Extensions'
          else if sExt = '.avif' then
            sCodec := 'AV1 Video Extension'
          else
            sCodec := 'HEIF Image Extensions';
          raise EInvalidGraphic.Create(Format(
            SErrorImportarImagenCodec,
            [UpperCase(Copy(sExt, 2, MaxInt)), sCodec, E.Message]));
        end;
      end;
      Result := oWic;
    except
      FreeAndNil(oWic);
      raise;
    end;
  end
  else
  begin
    oBitmap := Vcl.Graphics.TBitmap.Create;
    try
      oBitmap.LoadFromFile(ARuta);
      Result := oBitmap;
    except
      FreeAndNil(oBitmap);
      raise;
    end;
  end;
end;

procedure TAlmacenamientoFotos.GuardarComoPng(
  const AOriginal: TGraphic; const ARutaPng: string);
var
  oBitmap: Vcl.Graphics.TBitmap;
  oPng   : TPngImage;
begin
  if (AOriginal <> nil) and (AOriginal.Width > 0) and
     (AOriginal.Height > 0) then
  begin
    if AOriginal is TPngImage then
      TPngImage(AOriginal).SaveToFile(ARutaPng)
    else
    begin
      oBitmap := Vcl.Graphics.TBitmap.Create;
      try
        oBitmap.PixelFormat := pf32bit;
        oBitmap.SetSize(AOriginal.Width, AOriginal.Height);
        oBitmap.Canvas.Draw(0, 0, AOriginal);
        oPng := TPngImage.Create;
        try
          oPng.Assign(oBitmap);
          oPng.SaveToFile(ARutaPng);
        finally
          FreeAndNil(oPng);
        end;
      finally
        FreeAndNil(oBitmap);
      end;
    end;
  end;
end;

procedure TAlmacenamientoFotos.GuardarRedimensionado(
  const AOriginal: TGraphic; const ARutaPng: string;
  ALadoMayor: Integer);
var
  oBitmap: Vcl.Graphics.TBitmap;
  oOrigen: Vcl.Graphics.TBitmap;
  oPng   : TPngImage;
  oGdi   : TGPGraphics;
  oGdiSrc: TGPBitmap;
  dEscala: Double;
  iAlto  : Integer;
  iAncho : Integer;
begin
  if (AOriginal <> nil) and (AOriginal.Width > 0) and
     (AOriginal.Height > 0) then
  begin
    if AOriginal.Width >= AOriginal.Height then
    begin
      dEscala := ALadoMayor / AOriginal.Width;
      iAncho := ALadoMayor;
      iAlto := Round(AOriginal.Height * dEscala);
    end
    else
    begin
      dEscala := ALadoMayor / AOriginal.Height;
      iAlto := ALadoMayor;
      iAncho := Round(AOriginal.Width * dEscala);
    end;
    if iAncho < 1 then
      iAncho := 1;
    if iAlto < 1 then
      iAlto := 1;
    oBitmap := Vcl.Graphics.TBitmap.Create;
    oOrigen := Vcl.Graphics.TBitmap.Create;
    try
      oOrigen.PixelFormat := pf32bit;
      oOrigen.SetSize(AOriginal.Width, AOriginal.Height);
      oOrigen.Canvas.Draw(0, 0, AOriginal);
      oBitmap.PixelFormat := pf32bit;
      oBitmap.SetSize(iAncho, iAlto);
      oGdiSrc := TGPBitmap.Create(oOrigen.Handle, 0);
      try
        oGdi := TGPGraphics.Create(oBitmap.Canvas.Handle);
        try
          oGdi.SetInterpolationMode(
            InterpolationModeHighQualityBicubic);
          oGdi.SetPixelOffsetMode(PixelOffsetModeHighQuality);
          oGdi.SetSmoothingMode(SmoothingModeHighQuality);
          oGdi.DrawImage(oGdiSrc, 0, 0, iAncho, iAlto);
        finally
          FreeAndNil(oGdi);
        end;
      finally
        FreeAndNil(oGdiSrc);
      end;
      oPng := TPngImage.Create;
      try
        oPng.Assign(oBitmap);
        oPng.SaveToFile(ARutaPng);
      finally
        FreeAndNil(oPng);
      end;
    finally
      FreeAndNil(oOrigen);
      FreeAndNil(oBitmap);
    end;
  end;
end;

procedure TAlmacenamientoFotos.RotarBitmap90(
  ABitmap: Vcl.Graphics.TBitmap; AHorario: Boolean);
var
  oRotado: Vcl.Graphics.TBitmap;
  pFuente: PRGBQuad;
  pDestino: PRGBQuad;
  iAlto  : Integer;
  iAncho : Integer;
  iX     : Integer;
  iY     : Integer;
begin
  if (ABitmap <> nil) and (ABitmap.Width > 0) and
     (ABitmap.Height > 0) then
  begin
    ABitmap.PixelFormat := pf32bit;
    iAncho := ABitmap.Width;
    iAlto := ABitmap.Height;
    oRotado := Vcl.Graphics.TBitmap.Create;
    try
      oRotado.PixelFormat := pf32bit;
      oRotado.SetSize(iAlto, iAncho);
      for iY := 0 to iAlto - 1 do
      begin
        pFuente := PRGBQuad(ABitmap.ScanLine[iY]);
        for iX := 0 to iAncho - 1 do
        begin
          if AHorario then
          begin
            pDestino := PRGBQuad(oRotado.ScanLine[iX]);
            Inc(pDestino, iAlto - 1 - iY);
          end
          else
          begin
            pDestino := PRGBQuad(oRotado.ScanLine[iAncho - 1 - iX]);
            Inc(pDestino, iY);
          end;
          pDestino^ := pFuente^;
          Inc(pFuente);
        end;
      end;
      ABitmap.Assign(oRotado);
    finally
      FreeAndNil(oRotado);
    end;
  end;
end;

procedure TAlmacenamientoFotos.RotarFicheroPng(const ARuta: string;
  AHorario: Boolean);
var
  oBitmap: Vcl.Graphics.TBitmap;
  oPng   : TPngImage;
  oSalida: TPngImage;
begin
  if FileExists(ARuta) then
  begin
    oPng := TPngImage.Create;
    oBitmap := Vcl.Graphics.TBitmap.Create;
    try
      oPng.LoadFromFile(ARuta);
      oBitmap.PixelFormat := pf32bit;
      oBitmap.SetSize(oPng.Width, oPng.Height);
      oBitmap.Canvas.Draw(0, 0, oPng);
      RotarBitmap90(oBitmap, AHorario);
      oSalida := TPngImage.Create;
      try
        oSalida.Assign(oBitmap);
        oSalida.SaveToFile(ARuta);
      finally
        FreeAndNil(oSalida);
      end;
    finally
      FreeAndNil(oBitmap);
      FreeAndNil(oPng);
    end;
  end;
end;

procedure TAlmacenamientoFotos.GuardarCopias(
  const AFicheroOrigen, ANombre: string);
var
  oGrafico: TGraphic;
  sBase   : string;
begin
  if not FileExists(AFicheroOrigen) then
    raise Exception.Create(Format(SErrorFicheroOrigenFotoNoExiste,
      [AFicheroOrigen]));
  sBase := DirectorioBase;
  if sBase = '' then
    raise Exception.Create(SErrorDirectorioFotosNoConfigurado);
  ForceDirectories(sBase + cSubdir300);
  ForceDirectories(sBase + cSubdir600);
  ForceDirectories(sBase + cSubdirReal);
  oGrafico := CargarGraficoDeFichero(AFicheroOrigen);
  try
    GuardarComoPng(oGrafico, RutaDeNombre(ANombre, frReal));
    GuardarRedimensionado(oGrafico,
      RutaDeNombre(ANombre, frPx300), cLado300);
    GuardarRedimensionado(oGrafico,
      RutaDeNombre(ANombre, frPx600), cLado600);
  finally
    FreeAndNil(oGrafico);
  end;
end;

procedure TAlmacenamientoFotos.RenombrarSiExiste(
  const ARutaOrigen, ARutaDestino: string);
begin
  if FileExists(ARutaOrigen) then
    RenameFile(ARutaOrigen, ARutaDestino);
end;

procedure TAlmacenamientoFotos.RenombrarCopias(
  const ANombreAnterior, ANombreNuevo: string);
begin
  RenombrarSiExiste(RutaDeNombre(ANombreAnterior, frPx300),
    RutaDeNombre(ANombreNuevo, frPx300));
  RenombrarSiExiste(RutaDeNombre(ANombreAnterior, frPx600),
    RutaDeNombre(ANombreNuevo, frPx600));
  RenombrarSiExiste(RutaDeNombre(ANombreAnterior, frReal),
    RutaDeNombre(ANombreNuevo, frReal));
end;

procedure TAlmacenamientoFotos.RotarCopias(
  const ANombreAnterior, ANombreNuevo: string; AHorario: Boolean);
begin
  RotarFicheroPng(RutaDeNombre(ANombreAnterior, frPx300), AHorario);
  RotarFicheroPng(RutaDeNombre(ANombreAnterior, frPx600), AHorario);
  RotarFicheroPng(RutaDeNombre(ANombreAnterior, frReal), AHorario);
  RenombrarCopias(ANombreAnterior, ANombreNuevo);
end;

procedure TAlmacenamientoFotos.BorrarCopias(const ANombre: string);
var
  sRuta: string;
begin
  if ANombre <> '' then
  begin
    sRuta := RutaDeNombre(ANombre, frPx300);
    if (sRuta <> '') and FileExists(sRuta) then
      DeleteFile(PChar(sRuta));
    sRuta := RutaDeNombre(ANombre, frPx600);
    if (sRuta <> '') and FileExists(sRuta) then
      DeleteFile(PChar(sRuta));
    sRuta := RutaDeNombre(ANombre, frReal);
    if (sRuta <> '') and FileExists(sRuta) then
      DeleteFile(PChar(sRuta));
  end;
end;

end.
