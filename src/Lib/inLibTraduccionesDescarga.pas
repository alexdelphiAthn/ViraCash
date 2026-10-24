{******************************************************************************}
{                                                                              }
{  Módulo:       inLibTraduccionesDescarga                                     }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Descarga, valida e instala los paquetes SQL de traducción.                }
{******************************************************************************}
unit inLibTraduccionesDescarga;

interface

uses
  System.SysUtils,
  inLibTraduccionesDescargaPersistenciaIntf;

type
  TInstaladorTraducciones = class
  public
    class function DisponibleLocalmente(
      const APersistencia: IInstaladorTraduccionesPersistencia;
      const AIdioma: string): Boolean; static;
    class procedure DescargarEInstalar(
      const APersistencia: IInstaladorTraduccionesPersistencia;
      const AUrlBase, AToken, AIdioma: string;
      AProgreso: TProgresoDescargaTraduccion); static;
  end;

implementation

uses
  System.Classes, System.Generics.Collections, System.Hash,
  System.IOUtils, System.JSON, System.Zip,
  inLibViraCashApi, inLibMsgIntegraciones;

const
  cRutaDescargaTraduccion = 'traducciones/descargar.php';
  cScriptPreparacionTraduccion = '000_preparar_descarga.sql';
  cVersionContratoTraduccion = 1;

type
  TArchivoPaqueteTraduccion = record
    Nombre: string;
    Tamano: Integer;
    Huella: string;
    Contenido: string;
  end;

  TPaqueteTraduccion = record
    Version: Integer;
    Archivos: TArray<TArchivoPaqueteTraduccion>;
  end;

procedure NotificarProgreso(
  const AProgreso: TProgresoDescargaTraduccion;
  const ATexto: string;
  APosicion: Integer);
begin
  if Assigned(AProgreso) then
    AProgreso(ATexto, APosicion);
end;

procedure ErrorPaquete(const ADetalle: string);
begin
  raise Exception.CreateFmt(
    SErrorPaqueteTraduccionInvalido,
    [ADetalle]);
end;

function LeerCadenaJson(
  AObjeto: TJSONObject;
  const AClave: string): string;
var
  oValor: TJSONValue;
begin
  Result := '';
  if Assigned(AObjeto) then
  begin
    oValor := AObjeto.GetValue(AClave);
    if oValor is TJSONString then
      Result := oValor.Value;
  end;
end;

function LeerEnteroJson(
  AObjeto: TJSONObject;
  const AClave: string): Integer;
var
  oValor: TJSONValue;
begin
  Result := -1;
  if Assigned(AObjeto) then
  begin
    oValor := AObjeto.GetValue(AClave);
    if Assigned(oValor) then
    begin
      if not oValor.TryGetValue<Integer>(Result) then
        Result := -1;
    end;
  end;
end;

function NombreSqlValido(const ANombre: string): Boolean;
begin
  Result :=
    (ANombre <> '') and
    SameText(ExtractFileExt(ANombre), '.sql') and
    SameText(ExtractFileName(ANombre), ANombre) and
    (Pos('..', ANombre) = 0) and
    (Pos('/', ANombre) = 0) and
    (Pos('\', ANombre) = 0);
end;

function HuellaDatos(const ADatos: TBytes): string;
var
  oFlujo: TBytesStream;
begin
  oFlujo := TBytesStream.Create(ADatos);
  try
    Result := LowerCase(THashSHA2.GetHashString(oFlujo));
  finally
    FreeAndNil(oFlujo);
  end;
end;

function CargarPaquete(
  const ARuta, AIdioma: string): TPaqueteTraduccion;
var
  aDatos: TBytes;
  iArchivo: Integer;
  iEntrada: Integer;
  oArchivoJson: TJSONObject;
  oArchivosJson: TJSONArray;
  oJson: TJSONObject;
  oNombres: TStringList;
  oValor: TJSONValue;
  oZip: TZipFile;
  sContenido: string;
  sIdioma: string;
begin
  Result.Version := 0;
  Result.Archivos := nil;
  oZip := TZipFile.Create;
  oJson := nil;
  oNombres := TStringList.Create;
  try
    oNombres.Sorted := True;
    oNombres.Duplicates := dupError;
    oZip.Open(ARuta, zmRead);
    iEntrada := oZip.IndexOf('manifiesto.json');
    if iEntrada < 0 then
      ErrorPaquete('falta manifiesto.json');
    oZip.Read(iEntrada, aDatos);
    sContenido := TEncoding.UTF8.GetString(aDatos);
    oValor := TJSONObject.ParseJSONValue(sContenido);
    if oValor is TJSONObject then
      oJson := TJSONObject(oValor)
    else
    begin
      FreeAndNil(oValor);
      ErrorPaquete('el manifiesto no contiene un objeto JSON');
    end;
    if LeerEnteroJson(oJson, 'version_contrato') <>
       cVersionContratoTraduccion then
      ErrorPaquete('la versión del contrato no es compatible');
    sIdioma := LeerCadenaJson(oJson, 'idioma');
    if not SameText(sIdioma, AIdioma) then
      ErrorPaquete('el idioma del manifiesto no coincide');
    Result.Version := LeerEnteroJson(oJson, 'version');
    if Result.Version < 1 then
      ErrorPaquete('la versión del paquete no es válida');
    oValor := oJson.GetValue('archivos');
    if not (oValor is TJSONArray) then
      ErrorPaquete('falta la lista ordenada de archivos');
    oArchivosJson := TJSONArray(oValor);
    if oArchivosJson.Count = 0 then
      ErrorPaquete('el paquete no contiene archivos SQL');
    if oZip.FileCount <> oArchivosJson.Count + 1 then
      ErrorPaquete('el ZIP contiene archivos no declarados');
    SetLength(Result.Archivos, oArchivosJson.Count);
    for iArchivo := 0 to oArchivosJson.Count - 1 do
    begin
      oValor := oArchivosJson.Items[iArchivo];
      if not (oValor is TJSONObject) then
        ErrorPaquete('hay una entrada de archivo no válida');
      oArchivoJson := TJSONObject(oValor);
      Result.Archivos[iArchivo].Nombre :=
        LeerCadenaJson(oArchivoJson, 'nombre');
      Result.Archivos[iArchivo].Tamano :=
        LeerEnteroJson(oArchivoJson, 'tamano');
      Result.Archivos[iArchivo].Huella := LowerCase(
        LeerCadenaJson(oArchivoJson, 'sha256'));
      if not NombreSqlValido(Result.Archivos[iArchivo].Nombre) then
        ErrorPaquete('hay un nombre de archivo SQL no válido');
      oNombres.Add(Result.Archivos[iArchivo].Nombre);
      iEntrada := oZip.IndexOf(Result.Archivos[iArchivo].Nombre);
      if iEntrada < 0 then
        ErrorPaquete('falta un SQL declarado en el manifiesto');
      oZip.Read(iEntrada, aDatos);
      if Length(aDatos) <> Result.Archivos[iArchivo].Tamano then
        ErrorPaquete('el tamaño de un SQL no coincide');
      if not SameText(
           HuellaDatos(aDatos),
           Result.Archivos[iArchivo].Huella) then
        ErrorPaquete('la huella SHA-256 de un SQL no coincide');
      Result.Archivos[iArchivo].Contenido :=
        TEncoding.UTF8.GetString(aDatos);
    end;
    if not SameText(
         Result.Archivos[0].Nombre,
         cScriptPreparacionTraduccion) then
      ErrorPaquete('falta el script de preparación de descarga');
    oZip.Close;
  finally
    FreeAndNil(oNombres);
    FreeAndNil(oJson);
    FreeAndNil(oZip);
  end;
end;

function PrepararScripts(
  const APaquete: TPaqueteTraduccion):
  TArray<TScriptInstalacionTraduccion>;
var
  iArchivo: Integer;
begin
  SetLength(Result, Length(APaquete.Archivos));
  for iArchivo := 0 to High(APaquete.Archivos) do
  begin
    Result[iArchivo].Nombre := APaquete.Archivos[iArchivo].Nombre;
    Result[iArchivo].Contenido := APaquete.Archivos[iArchivo].Contenido;
  end;
end;

class function TInstaladorTraducciones.DisponibleLocalmente(
  const APersistencia: IInstaladorTraduccionesPersistencia;
  const AIdioma: string): Boolean;
begin
  Result := False;
  if Assigned(APersistencia) then
    Result := APersistencia.DisponibleLocalmente(AIdioma);
end;

class procedure TInstaladorTraducciones.DescargarEInstalar(
  const APersistencia: IInstaladorTraduccionesPersistencia;
  const AUrlBase, AToken, AIdioma: string;
  AProgreso: TProgresoDescargaTraduccion);
var
  aScripts: TArray<TScriptInstalacionTraduccion>;
  oResultado: TResultadoViraCashApi;
  oPaquete: TPaqueteTraduccion;
  sConsulta: string;
  sRutaTemporal: string;
begin
  if not Assigned(APersistencia) then
    raise Exception.Create(SErrorConexionTraduccionNoDisponible);
  APersistencia.ComprobarDisponible;
  NotificarProgreso(
    AProgreso,
    Format(SProgresoTraduccionPreparando, [AIdioma]),
    5);
  sRutaTemporal := TPath.GetTempFileName;
  try
    sConsulta := TClienteViraCashApi.ComponerConsulta(
      ['idioma'],
      [AIdioma]);
    NotificarProgreso(
      AProgreso,
      SProgresoTraduccionDescargando,
      15);
    oResultado := TClienteViraCashApi.DescargarArchivoAutenticado(
      AUrlBase,
      AToken,
      cRutaDescargaTraduccion,
      sConsulta,
      sRutaTemporal);
    if not oResultado.Ok then
      raise Exception.CreateFmt(
        SErrorDescargaTraduccion,
        [oResultado.Mensaje]);
    NotificarProgreso(
      AProgreso,
      SProgresoTraduccionValidando,
      35);
    oPaquete := CargarPaquete(sRutaTemporal, AIdioma);
    aScripts := PrepararScripts(oPaquete);
    APersistencia.Instalar(
      AIdioma,
      aScripts,
      AProgreso);
  finally
    if TFile.Exists(sRutaTemporal) then
      TFile.Delete(sRutaTemporal);
  end;
end;

end.
