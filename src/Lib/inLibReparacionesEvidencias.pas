{******************************************************************************}
{                                                                              }
{  Módulo:       inLibReparacionesEvidencias                                   }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Seguimiento de reparaciones y conservación de evidencias.                 }
{******************************************************************************}
unit inLibReparacionesEvidencias;

interface

type
  TEvidenciaReparacion = record
    Recibo: string;
    Revision: string;
    Nombre: string;
    Fase: string;
    Comentario: string;
    Instante: string;
    Archivo: string;
  end;

type
  TEntradaEvidenciaReparacion = record
    Fase: string;
    Comentario: string;
    Archivo: string;
    Instante: TDateTime;
  end;

function ValidarEvidenciaReparacion(
  const AEntrada: TEntradaEvidenciaReparacion): string;
procedure GuardarEvidenciaReparacion(const ACarpeta: string;
  const AEntrada: TEntradaEvidenciaReparacion);
procedure EditarEvidenciaReparacion(const AOriginal: TEvidenciaReparacion;
  const AEntrada: TEntradaEvidenciaReparacion);
function FechaEvidenciaReparacion(const AInstante: string): string;

function LeerEvidenciasReparacion(const ACarpeta: string):
  TArray<TEvidenciaReparacion>;

implementation

uses
  System.SysUtils, System.IOUtils, System.JSON,
  System.Generics.Collections, System.Generics.Defaults,
  System.DateUtils, System.Hash, Vcl.Graphics, Vcl.Imaging.pngimage,
  Vcl.Imaging.jpeg, inLibMsgReparaciones;

function ValidarEvidenciaReparacion(
  const AEntrada: TEntradaEvidenciaReparacion): string;
begin
  Result := '';
  if Trim(AEntrada.Fase) = '' then
    Result := SFotosIndicarFase
  else if (Trim(AEntrada.Comentario) = '') and
          (AEntrada.Archivo = '') then
    Result := SFotosIndicarContenido
  else if AEntrada.Instante <= 0 then
    Result := SFotosIndicarFecha
  else if (AEntrada.Archivo <> '') and
          not TFile.Exists(AEntrada.Archivo) then
    Result := SFotosArchivoInexistente;
end;

function FechaEvidenciaReparacion(const AInstante: string): string;
var
  dtInstante: TDateTime;
begin
  Result := AInstante;
  if TryISO8601ToDate(AInstante, dtInstante, False) then
    Result := FormatDateTime('dd/mm/yyyy hh:nn:ss', dtInstante);
end;

procedure GuardarImagenEvidencia(const AOrigen, ADestino: string);
var
  oImagen: TPicture;
  oPng: TPngImage;
  oBitmap: TBitmap;
begin
  oImagen := TPicture.Create;
  oPng := TPngImage.Create;
  oBitmap := TBitmap.Create;
  try
    oImagen.LoadFromFile(AOrigen);
    if oImagen.Graphic is TPngImage then
      oPng.Assign(oImagen.Graphic)
    else
    begin
      oBitmap.PixelFormat := pf24bit;
      oBitmap.SetSize(oImagen.Width, oImagen.Height);
      oBitmap.Canvas.Draw(0, 0, oImagen.Graphic);
      oPng.Assign(oBitmap);
    end;
    oPng.SaveToFile(ADestino);
  finally
    FreeAndNil(oBitmap);
    FreeAndNil(oPng);
    FreeAndNil(oImagen);
  end;
end;

function CrearReciboEvidencia(const ANombre: string;
  const AEntrada: TEntradaEvidenciaReparacion): string;
var
  oRecibo, oDatos: TJSONObject;
begin
  oRecibo := TJSONObject.Create;
  try
    oDatos := TJSONObject.Create;
    oRecibo.AddPair('datos', oDatos);
    oDatos.AddPair('nombre', ANombre);
    oDatos.AddPair('fase', Trim(AEntrada.Fase));
    oDatos.AddPair('comentario', AEntrada.Comentario);
    oDatos.AddPair('recibida_utc', DateToISO8601(
      TTimeZone.Local.ToUniversalTime(AEntrada.Instante), True));
    oDatos.AddPair('solo_comentario',
      TJSONBool.Create(AEntrada.Archivo = ''));
    oDatos.AddPair('completa', TJSONBool.Create(True));
    oDatos.AddPair('origen', 'ESCRITORIO');
    Result := oRecibo.ToJSON;
  finally
    FreeAndNil(oRecibo);
  end;
end;

procedure GuardarEvidenciaReparacion(const ACarpeta: string;
  const AEntrada: TEntradaEvidenciaReparacion);
var
  sError, sNombre, sImagen, sRecibo, sTemporal: string;
  rId: TGUID;
begin
  sError := ValidarEvidenciaReparacion(AEntrada);
  if sError <> '' then
    raise EArgumentException.Create(sError);
  if Trim(ACarpeta) = '' then
    raise EArgumentException.Create(SFotosConfigurarCarpeta);
  CreateGUID(rId);
  sNombre := 'LOCAL_' + GUIDToString(rId);
  ForceDirectories(ACarpeta);
  sImagen := TPath.Combine(ACarpeta, sNombre + '_real.png');
  sRecibo := TPath.Combine(ACarpeta, 'captura_' + sNombre + '.json');
  sTemporal := sRecibo + '.tmp';
  try
    if AEntrada.Archivo <> '' then
      GuardarImagenEvidencia(AEntrada.Archivo, sImagen);
    TFile.WriteAllText(sTemporal, CrearReciboEvidencia(sNombre, AEntrada),
      TEncoding.UTF8);
    TFile.Move(sTemporal, sRecibo);
  finally
    if TFile.Exists(sTemporal) then
      TFile.Delete(sTemporal);
    if not TFile.Exists(sRecibo) and TFile.Exists(sImagen) then
      TFile.Delete(sImagen);
  end;
end;

function RutaEdicionEvidencia(const ARecibo: string): string;
begin
  Result := TPath.Combine(ExtractFilePath(ARecibo),
    'edicion_' + ExtractFileName(ARecibo));
end;

function RevisionEvidencia(const ARecibo: string): string;
var
  sRuta: string;
begin
  sRuta := RutaEdicionEvidencia(ARecibo);
  if not TFile.Exists(sRuta) then
    sRuta := ARecibo;
  Result := THashSHA2.GetHashStringFromFile(sRuta);
end;

function CrearEdicionEvidencia(const ANombre, AImagen: string;
  const AEntrada: TEntradaEvidenciaReparacion): string;
var
  oRecibo: TJSONObject;
begin
  oRecibo := TJSONObject.ParseJSONValue(
    CrearReciboEvidencia(ANombre, AEntrada)) as TJSONObject;
  try
    oRecibo.GetValue<TJSONObject>('datos').AddPair('archivo_local',
      ExtractFileName(AImagen));
    Result := oRecibo.ToJSON;
  finally
    FreeAndNil(oRecibo);
  end;
end;

procedure EditarEvidenciaReparacion(const AOriginal: TEvidenciaReparacion;
  const AEntrada: TEntradaEvidenciaReparacion);
var
  sError, sImagen, sEdicion, sTemporal: string;
  rId: TGUID;
  bNuevaImagen, bPublicado: Boolean;
begin
  sError := ValidarEvidenciaReparacion(AEntrada);
  if sError <> '' then
    raise EArgumentException.Create(sError);
  if not TFile.Exists(AOriginal.Recibo) then
    raise EArgumentException.Create(SFotosSeleccionar);
  if RevisionEvidencia(AOriginal.Recibo) <> AOriginal.Revision then
    raise EArgumentException.Create(SFotosEdicionConflicto);
  CreateGUID(rId);
  sImagen := AEntrada.Archivo;
  bNuevaImagen := (sImagen <> '') and (sImagen <> AOriginal.Archivo);
  if bNuevaImagen then
    sImagen := TPath.Combine(ExtractFilePath(AOriginal.Recibo),
      'LOCAL_' + GUIDToString(rId) + '_real.png');
  sEdicion := RutaEdicionEvidencia(AOriginal.Recibo);
  sTemporal := sEdicion + GUIDToString(rId) + '.tmp';
  bPublicado := False;
  try
    if bNuevaImagen then
      GuardarImagenEvidencia(AEntrada.Archivo, sImagen);
    TFile.WriteAllText(sTemporal, CrearEdicionEvidencia(AOriginal.Nombre,
      sImagen, AEntrada), TEncoding.UTF8);
    if TFile.Exists(sEdicion) then
      TFile.Replace(sTemporal, sEdicion, sTemporal + '.bak')
    else
      TFile.Move(sTemporal, sEdicion);
    bPublicado := True;
  finally
    if TFile.Exists(sTemporal) then
      TFile.Delete(sTemporal);
    if not bPublicado and bNuevaImagen and TFile.Exists(sImagen) then
      TFile.Delete(sImagen);
  end;
end;

function LeerEvidencia(const ARuta, ACarpeta: string): TEvidenciaReparacion;
var
  oJson: TJSONValue;
  oDatos: TJSONObject;
  sRuta, sImagen: string;
begin
  Result := Default(TEvidenciaReparacion);
  Result.Recibo := ARuta;
  Result.Revision := RevisionEvidencia(ARuta);
  sRuta := RutaEdicionEvidencia(ARuta);
  if not TFile.Exists(sRuta) then
    sRuta := ARuta;
  oJson := TJSONObject.ParseJSONValue(TFile.ReadAllText(sRuta,
    TEncoding.UTF8));
  try
    if not Assigned(oJson) then
      raise EArgumentException.Create('Recibo de evidencia inválido.');
    oDatos := oJson.GetValue<TJSONObject>('datos');
    Result.Nombre := oDatos.GetValue<string>('nombre');
    Result.Fase := oDatos.GetValue<string>('fase');
    Result.Comentario := oDatos.GetValue<string>('comentario', '');
    Result.Instante := oDatos.GetValue<string>('recibida_utc');
    if not oDatos.GetValue<Boolean>('solo_comentario', False) then
    begin
      if (ExtractFileName(Result.Nombre) <> Result.Nombre) or
         (Pos('..', Result.Nombre) > 0) or (Pos(':', Result.Nombre) > 0) then
        raise EArgumentException.Create('Nombre de evidencia inválido.');
      sImagen := oDatos.GetValue<string>('archivo_local',
        Result.Nombre + '_real.png');
      if (sImagen = '') or (ExtractFileName(sImagen) <> sImagen) or
         (Pos('..', sImagen) > 0) or (Pos(':', sImagen) > 0) then
        raise EArgumentException.Create(SFotosNombreInvalido);
      Result.Archivo := TPath.Combine(ACarpeta, sImagen);
    end;
  finally
    FreeAndNil(oJson);
  end;
end;

function LeerEvidenciasReparacion(const ACarpeta: string):
  TArray<TEvidenciaReparacion>;
var
  sRuta: string;
begin
  Result := nil;
  if TDirectory.Exists(ACarpeta) then
    for sRuta in TDirectory.GetFiles(ACarpeta, 'captura_*.json') do
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := LeerEvidencia(sRuta, ACarpeta);
    end;
  TArray.Sort<TEvidenciaReparacion>(Result,
    TComparer<TEvidenciaReparacion>.Construct(
      function(const AIzquierda, ADerecha: TEvidenciaReparacion): Integer
      begin
        Result := CompareStr(AIzquierda.Instante + AIzquierda.Nombre,
          ADerecha.Instante + ADerecha.Nombre);
      end));
end;

end.
