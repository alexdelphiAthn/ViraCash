{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArchivosPedidoSesion                                     }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       08/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Localiza las páginas TIFF entregadas por el OCR y conserva una copia      }
{    estable del JSON y del pedido original asociada a la sesión de compra.    }
{******************************************************************************}
unit inLibArchivosPedidoSesion;

interface

uses
  inLibPedidoOcr;

function DirectorioArchivosPedidoSesion(const ADirectorioFotos,
  ASerie, ANumero: string): string;
function ResolverPaginasFuentePedido(
  const APedido: TPedidoOcr): TArray<string>;
procedure GuardarArchivosPedidoSesion(const ADirectorioFotos,
  ASerie, ANumero: string; const APedido: TPedidoOcr;
  const APaginas: TArray<string>);
function ListarPaginasPedidoSesion(const ADirectorioFotos,
  ASerie, ANumero: string): TArray<string>;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  System.Generics.Collections;

resourcestring
  SErrorDirectorioFotosPedidoSesionNoConfigurado =
    'El parámetro appDirFotos no está configurado.';

const
  cCarpetaPedidosSesiones = 'pedidos_sesiones';
  cNombreJsonGuardado = 'pedido.json';

function SanearSegmentoRuta(const AValor: string): string;
var
  cCaracter: Char;
  iCaracter: Integer;
begin
  Result := '';
  for iCaracter := 1 to Length(AValor) do
  begin
    cCaracter := AValor[iCaracter];
    if CharInSet(cCaracter,
      ['A'..'Z', 'a'..'z', '0'..'9', '-', '_']) then
      Result := Result + cCaracter
    else
      Result := Result + '_';
  end;
end;

function DirectorioArchivosPedidoSesion(const ADirectorioFotos,
  ASerie, ANumero: string): string;
var
  sClave: string;
begin
  Result := '';
  if Trim(ADirectorioFotos) <> '' then
  begin
    sClave := SanearSegmentoRuta(ASerie) + '_' +
      SanearSegmentoRuta(ANumero);
    Result := TPath.Combine(
      TPath.Combine(ADirectorioFotos, cCarpetaPedidosSesiones),
      sClave);
  end;
end;

procedure AnadirTiffsDirectorio(const ADirectorio: string;
  ALista: TList<string>);
var
  aArchivos: TArray<string>;
  sArchivo: string;
begin
  if TDirectory.Exists(ADirectorio) then
  begin
    aArchivos := TDirectory.GetFiles(ADirectorio, '*.tif');
    TArray.Sort<string>(aArchivos);
    for sArchivo in aArchivos do
      ALista.Add(sArchivo);
    aArchivos := TDirectory.GetFiles(ADirectorio, '*.tiff');
    TArray.Sort<string>(aArchivos);
    for sArchivo in aArchivos do
      ALista.Add(sArchivo);
  end;
end;

function ResolverRutaPagina(const ADirectorioJson,
  ARuta: string): string;
begin
  if TPath.IsPathRooted(ARuta) then
    Result := TPath.GetFullPath(ARuta)
  else
    Result := TPath.GetFullPath(TPath.Combine(ADirectorioJson, ARuta));
end;

function ResolverPaginasFuentePedido(
  const APedido: TPedidoOcr): TArray<string>;
var
  iPagina: Integer;
  oLista: TList<string>;
  sBase: string;
  sDirectorioJson: string;
  sPagina: string;
begin
  oLista := TList<string>.Create;
  try
    sDirectorioJson := TPath.GetDirectoryName(APedido.FicheroJson);
    for iPagina := 0 to High(APedido.PaginasOriginales) do
    begin
      sPagina := ResolverRutaPagina(
        sDirectorioJson,
        APedido.PaginasOriginales[iPagina]);
      if TFile.Exists(sPagina) then
        oLista.Add(sPagina);
    end;
    if oLista.Count = 0 then
    begin
      sBase := TPath.GetFileNameWithoutExtension(APedido.FicheroJson);
      AnadirTiffsDirectorio(
        TPath.Combine(sDirectorioJson, sBase + '.paginas'),
        oLista);
      if sBase.EndsWith('.tesseract.pedido', True) then
      begin
        sBase := Copy(
          sBase,
          1,
          Length(sBase) - Length('.tesseract.pedido'));
        if oLista.Count = 0 then
          AnadirTiffsDirectorio(
            TPath.Combine(sDirectorioJson, sBase + '.paginas'),
            oLista);
        if oLista.Count = 0 then
          AnadirTiffsDirectorio(
            TPath.Combine(sDirectorioJson, sBase + '-debug'),
            oLista);
        if oLista.Count = 0 then
          AnadirTiffsDirectorio(
            TPath.Combine(
              TPath.Combine(sDirectorioJson, 'diagnostico-tesseract'),
              sBase),
            oLista);
      end;
    end;
    Result := oLista.ToArray;
  finally
    oLista.Free;
  end;
end;

procedure GuardarArchivosPedidoSesion(const ADirectorioFotos,
  ASerie, ANumero: string; const APedido: TPedidoOcr;
  const APaginas: TArray<string>);
var
  iPagina: Integer;
  sDestino: string;
  sDirectorio: string;
  sExtension: string;
begin
  sDirectorio := DirectorioArchivosPedidoSesion(
    ADirectorioFotos,
    ASerie,
    ANumero);
  if sDirectorio = '' then
    raise Exception.Create(SErrorDirectorioFotosPedidoSesionNoConfigurado);
  TDirectory.CreateDirectory(sDirectorio);
  TFile.Copy(
    APedido.FicheroJson,
    TPath.Combine(sDirectorio, cNombreJsonGuardado),
    True);
  for iPagina := 0 to High(APaginas) do
  begin
    sExtension := LowerCase(TPath.GetExtension(APaginas[iPagina]));
    if (sExtension <> '.tif') and (sExtension <> '.tiff') then
      sExtension := '.tif';
    sDestino := TPath.Combine(
      sDirectorio,
      Format('pagina-%.3d%s', [iPagina + 1, sExtension]));
    TFile.Copy(APaginas[iPagina], sDestino, True);
  end;
end;

function ListarPaginasPedidoSesion(const ADirectorioFotos,
  ASerie, ANumero: string): TArray<string>;
var
  oLista: TList<string>;
begin
  oLista := TList<string>.Create;
  try
    AnadirTiffsDirectorio(
      DirectorioArchivosPedidoSesion(
        ADirectorioFotos,
        ASerie,
        ANumero),
      oLista);
    Result := oLista.ToArray;
  finally
    oLista.Free;
  end;
end;

end.
