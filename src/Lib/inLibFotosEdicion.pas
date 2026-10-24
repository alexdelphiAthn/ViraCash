{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFotosEdicion                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Altas, sustituciones, rotaciones y bajas de fotografías de artículos.    }
{******************************************************************************}
unit inLibFotosEdicion;

interface

uses
  inLibFotosPersistenciaIntf, inLibFotosTipos,
  inLibFotosConsulta, inLibFotosAlmacenamiento;

type
  TEdicionFotos = class
  private
    FRepositorio   : IRepositorioEdicionFotos;
    FConsulta      : TConsultaFotos;
    FAlmacenamiento: TAlmacenamientoFotos;
    function ExisteAlgunaCopia(const ANombre: string): Boolean;
    function RutaReservaNombre(const ANombre: string): string;
    function ReservarSiguienteNombre(const AClave: string;
      const AMetadatos: TArray<TMetadatosFotoPersistida>): string;
    procedure LiberarReservaNombre(const ANombre: string);
    procedure CopiarCopias(const ANombreOrigen,
      ANombreDestino: string);
  public
    constructor Create(AConsulta: TConsultaFotos;
      AAlmacenamiento: TAlmacenamientoFotos);
    procedure AsignarRepositorio(
      const ARepositorio: IRepositorioEdicionFotos);
    procedure LiberarServicios;
    function Guardar(const ACodigoArticulo, ACodigoSku,
      AFicheroOrigen, AUsuario: string): TFotoInfo;
    function Anadir(const ACodigoArticulo, ACodigoSku,
      AFicheroOrigen, AUsuario: string): TFotoInfo;
    function Rotar(const ACodigoArticulo, ACodigoSku: string;
      AHorario: Boolean; const AUsuario: string): TFotoInfo; overload;
    function Rotar(const AInfo: TFotoInfo;
      AHorario: Boolean; const AUsuario: string): TFotoInfo; overload;
    procedure Eliminar(const ACodigoArticulo,
      ACodigoUnidad: string); overload;
    procedure Eliminar(const AInfo: TFotoInfo); overload;
    function MarcarPredeterminada(const AInfo: TFotoInfo;
      const AUsuario: string): TFotoInfo;
  end;

implementation

uses
  Winapi.Windows, System.SysUtils, System.IOUtils,
  inLibMsgArticulos, inLibMsgFotos;

constructor TEdicionFotos.Create(AConsulta: TConsultaFotos;
  AAlmacenamiento: TAlmacenamientoFotos);
begin
  inherited Create;
  FConsulta := AConsulta;
  FAlmacenamiento := AAlmacenamiento;
end;

procedure TEdicionFotos.AsignarRepositorio(
  const ARepositorio: IRepositorioEdicionFotos);
begin
  FRepositorio := ARepositorio;
end;

procedure TEdicionFotos.LiberarServicios;
begin
  FRepositorio := nil;
end;

function TEdicionFotos.ExisteAlgunaCopia(
  const ANombre: string): Boolean;
begin
  Result :=
    FileExists(FAlmacenamiento.RutaDeNombre(ANombre, frPx300)) or
    FileExists(FAlmacenamiento.RutaDeNombre(ANombre, frPx600)) or
    FileExists(FAlmacenamiento.RutaDeNombre(ANombre, frReal)) or
    FileExists(RutaReservaNombre(ANombre));
end;

function TEdicionFotos.RutaReservaNombre(
  const ANombre: string): string;
begin
  Result := FAlmacenamiento.RutaDeNombre(ANombre, frReal);
  if Result <> '' then
    Result := Result + '.reserva';
end;

function TEdicionFotos.ReservarSiguienteNombre(const AClave: string;
  const AMetadatos: TArray<TMetadatosFotoPersistida>): string;
var
  iFoto: Integer;
  iIndice: Integer;
  iIndiceFoto: Integer;
  iError: Cardinal;
  hReserva: THandle;
  sRutaReserva: string;
  bReservado: Boolean;
begin
  iIndice := 0;
  for iFoto := 0 to High(AMetadatos) do
  begin
    iIndiceFoto := FAlmacenamiento.ExtraerIndice(
      AMetadatos[iFoto].Nombre);
    if iIndiceFoto > iIndice then
      iIndice := iIndiceFoto;
  end;
  bReservado := False;
  while not bReservado do
  begin
    Inc(iIndice);
    Result := FAlmacenamiento.ComponerNombre(AClave, iIndice);
    // Si el nombre ya esta ocupado se prueba con el indice siguiente.
    if not ExisteAlgunaCopia(Result) then
    begin
      sRutaReserva := RutaReservaNombre(Result);
      if sRutaReserva = '' then
        raise Exception.Create(SErrorDirectorioFotosNoConfigurado);
      if not ForceDirectories(ExtractFilePath(sRutaReserva)) then
        RaiseLastOSError;
      hReserva := Winapi.Windows.CreateFile(
        PChar(sRutaReserva), GENERIC_WRITE, 0, nil, CREATE_NEW,
        FILE_ATTRIBUTE_TEMPORARY, 0);
      if hReserva <> INVALID_HANDLE_VALUE then
      begin
        CloseHandle(hReserva);
        bReservado := True;
      end
      else
      begin
        iError := GetLastError;
        if (iError <> ERROR_FILE_EXISTS) and
           (iError <> ERROR_ALREADY_EXISTS) then
          RaiseLastOSError(iError);
      end;
    end;
  end;
end;

procedure TEdicionFotos.LiberarReservaNombre(
  const ANombre: string);
var
  sRutaReserva: string;
begin
  sRutaReserva := RutaReservaNombre(ANombre);
  if (sRutaReserva <> '') and FileExists(sRutaReserva) then
    System.SysUtils.DeleteFile(sRutaReserva);
end;

procedure TEdicionFotos.CopiarCopias(const ANombreOrigen,
  ANombreDestino: string);
var
  eResolucion: TFotoResolucion;
  sOrigen: string;
begin
  for eResolucion := Low(TFotoResolucion) to High(TFotoResolucion) do
  begin
    sOrigen := FAlmacenamiento.RutaDeNombre(
      ANombreOrigen, eResolucion);
    if FileExists(sOrigen) then
      TFile.Copy(sOrigen, FAlmacenamiento.RutaDeNombre(
        ANombreDestino, eResolucion), False);
  end;
end;

function TEdicionFotos.Guardar(const ACodigoArticulo, ACodigoSku,
  AFicheroOrigen, AUsuario: string): TFotoInfo;
var
  aMetadatos     : TArray<TMetadatosFotoPersistida>;
  oMetadatos     : TMetadatosFotoPersistida;
  sClave         : string;
  sExtension     : string;
  sNombreAnterior: string;
  sNombreNuevo   : string;
  iFoto          : Integer;
begin
  Result.Clear;
  if ACodigoArticulo = '' then
    raise Exception.Create(SErrorGuardarFotoSinCodigoArticulo);
  if not FileExists(AFicheroOrigen) then
    raise Exception.Create(Format(SErrorFicheroOrigenFotoNoExiste,
      [AFicheroOrigen]));
  sClave := FAlmacenamiento.ClaveNombre(
    ACodigoArticulo, ACodigoSku);
  sExtension := FAlmacenamiento.ExtensionOrigen(AFicheroOrigen);
  sNombreAnterior := '';
  aMetadatos := FRepositorio.BuscarFotosEditables(
    ACodigoArticulo, ACodigoSku);
  for iFoto := 0 to High(aMetadatos) do
    if aMetadatos[iFoto].Orden = 1 then
      sNombreAnterior := aMetadatos[iFoto].Nombre;
  sNombreNuevo := ReservarSiguienteNombre(sClave, aMetadatos);
  try
    try
      FAlmacenamiento.GuardarCopias(AFicheroOrigen, sNombreNuevo);
    except
      FAlmacenamiento.BorrarCopias(sNombreNuevo);
      raise;
    end;
    try
      oMetadatos := Default(TMetadatosFotoPersistida);
      oMetadatos.CodigoArticulo := ACodigoArticulo;
      oMetadatos.CodigoUnidad := ACodigoSku;
      oMetadatos.Orden := 1;
      oMetadatos.Nombre := sNombreNuevo;
      oMetadatos.Extension := sExtension;
      FRepositorio.GuardarFoto(
        oMetadatos, sNombreAnterior, AUsuario);
    except
      FAlmacenamiento.BorrarCopias(sNombreNuevo);
      raise;
    end;
    if (sNombreAnterior <> '') and
       (sNombreAnterior <> sNombreNuevo) then
      FAlmacenamiento.BorrarCopias(sNombreAnterior);
    FConsulta.LimpiarPrecargaFotos;
    Result.Encontrada := True;
    if ACodigoSku = '' then
      Result.Origen := foArticulo
    else
      Result.Origen := foSku;
    Result.CodigoArt := ACodigoArticulo;
    Result.CodigoSku := ACodigoSku;
    Result.ClaveResuelta := ACodigoSku;
    Result.Orden := 1;
    Result.NombreBase := sNombreNuevo;
    Result.ExtensionOrigen := sExtension;
  finally
    LiberarReservaNombre(sNombreNuevo);
  end;
end;

function TEdicionFotos.Anadir(const ACodigoArticulo, ACodigoSku,
  AFicheroOrigen, AUsuario: string): TFotoInfo;
var
  aMetadatos : TArray<TMetadatosFotoPersistida>;
  oMetadatos : TMetadatosFotoPersistida;
  sClave     : string;
  sExtension : string;
  sNombreNuevo: string;
begin
  Result.Clear;
  if ACodigoArticulo = '' then
    raise Exception.Create(SErrorGuardarFotoSinCodigoArticulo);
  if not FileExists(AFicheroOrigen) then
    raise Exception.Create(Format(SErrorFicheroOrigenFotoNoExiste,
      [AFicheroOrigen]));
  sClave := FAlmacenamiento.ClaveNombre(
    ACodigoArticulo, ACodigoSku);
  sExtension := FAlmacenamiento.ExtensionOrigen(AFicheroOrigen);
  aMetadatos := FRepositorio.BuscarFotosEditables(
    ACodigoArticulo, ACodigoSku);
  sNombreNuevo := ReservarSiguienteNombre(sClave, aMetadatos);
  try
    try
      FAlmacenamiento.GuardarCopias(AFicheroOrigen, sNombreNuevo);
    except
      FAlmacenamiento.BorrarCopias(sNombreNuevo);
      raise;
    end;
    try
      oMetadatos := Default(TMetadatosFotoPersistida);
      oMetadatos.CodigoArticulo := ACodigoArticulo;
      oMetadatos.CodigoUnidad := ACodigoSku;
      oMetadatos.Nombre := sNombreNuevo;
      oMetadatos.Extension := sExtension;
      FRepositorio.AnadirFoto(oMetadatos, AUsuario);
    except
      FAlmacenamiento.BorrarCopias(sNombreNuevo);
      raise;
    end;
    FConsulta.LimpiarPrecargaFotos;
    Result.Encontrada := True;
    if ACodigoSku = '' then
      Result.Origen := foArticulo
    else
      Result.Origen := foSku;
    Result.CodigoArt := ACodigoArticulo;
    Result.CodigoSku := ACodigoSku;
    Result.ClaveResuelta := ACodigoSku;
    Result.Orden := oMetadatos.Orden;
    Result.NombreBase := sNombreNuevo;
    Result.ExtensionOrigen := sExtension;
  finally
    LiberarReservaNombre(sNombreNuevo);
  end;
end;

function TEdicionFotos.Rotar(const ACodigoArticulo,
  ACodigoSku: string; AHorario: Boolean;
  const AUsuario: string): TFotoInfo;
var
  oInfo: TFotoInfo;
begin
  oInfo := FConsulta.Resolver(ACodigoArticulo, ACodigoSku);
  Result := Rotar(oInfo, AHorario, AUsuario);
end;

function TEdicionFotos.Rotar(const AInfo: TFotoInfo;
  AHorario: Boolean; const AUsuario: string): TFotoInfo;
var
  aMetadatos     : TArray<TMetadatosFotoPersistida>;
  oMetadatos     : TMetadatosFotoPersistida;
  sClave         : string;
  sNombreAnterior: string;
  sNombreNuevo   : string;
  sNombreTemporal: string;
  bTemporalOcupado: Boolean;
begin
  Result.Clear;
  if (not AInfo.Encontrada) or (AInfo.CodigoArt = '') or
     (AInfo.Orden < 1) or
     (not FRepositorio.BuscarFotoEditable(
       AInfo.CodigoArt, AInfo.ClaveResuelta, AInfo.Orden,
       oMetadatos)) then
    raise Exception.Create(SErrorFotoNoRegistradaParaRotar);
  if not SameText(oMetadatos.Nombre, AInfo.NombreBase) then
    raise Exception.Create(SErrorFotoSeleccionadaCambio);
  sClave := FAlmacenamiento.ClaveNombre(
    AInfo.CodigoArt, AInfo.ClaveResuelta);
  sNombreAnterior := oMetadatos.Nombre;
  aMetadatos := FRepositorio.BuscarFotosEditables(
    AInfo.CodigoArt, AInfo.ClaveResuelta);
  repeat
    sNombreNuevo := ReservarSiguienteNombre(sClave, aMetadatos);
    sNombreTemporal := sNombreNuevo + '_rotando';
    bTemporalOcupado := ExisteAlgunaCopia(sNombreTemporal);
    if bTemporalOcupado then
    begin
      LiberarReservaNombre(sNombreNuevo);
      oMetadatos.Nombre := sNombreNuevo;
      aMetadatos := aMetadatos + [oMetadatos];
    end;
  until not bTemporalOcupado;
  try
    try
      CopiarCopias(sNombreAnterior, sNombreTemporal);
      FAlmacenamiento.RotarCopias(
        sNombreTemporal, sNombreNuevo, AHorario);
    except
      FAlmacenamiento.BorrarCopias(sNombreTemporal);
      FAlmacenamiento.BorrarCopias(sNombreNuevo);
      raise;
    end;
    try
      FRepositorio.ActualizarNombreFoto(
        AInfo.CodigoArt, AInfo.ClaveResuelta, AInfo.Orden,
        sNombreAnterior, sNombreNuevo, AUsuario);
    except
      FAlmacenamiento.BorrarCopias(sNombreTemporal);
      FAlmacenamiento.BorrarCopias(sNombreNuevo);
      raise;
    end;
    FAlmacenamiento.BorrarCopias(sNombreAnterior);
    FConsulta.LimpiarPrecargaFotos;
    Result.Encontrada := True;
    Result.Origen := AInfo.Origen;
    Result.CodigoArt := AInfo.CodigoArt;
    Result.CodigoSku := AInfo.CodigoSku;
    Result.ClaveResuelta := AInfo.ClaveResuelta;
    Result.Orden := AInfo.Orden;
    Result.NombreBase := sNombreNuevo;
    Result.ExtensionOrigen := oMetadatos.Extension;
  finally
    LiberarReservaNombre(sNombreNuevo);
  end;
end;

procedure TEdicionFotos.Eliminar(const ACodigoArticulo,
  ACodigoUnidad: string);
var
  oMetadatos: TMetadatosFotoPersistida;
  oInfo: TFotoInfo;
begin
  if FRepositorio.BuscarFotoEditable(
    ACodigoArticulo, ACodigoUnidad, 1, oMetadatos) then
  begin
    oInfo.Clear;
    oInfo.Encontrada := True;
    oInfo.CodigoArt := ACodigoArticulo;
    oInfo.ClaveResuelta := ACodigoUnidad;
    oInfo.Orden := 1;
    oInfo.NombreBase := oMetadatos.Nombre;
    Eliminar(oInfo);
  end;
end;

procedure TEdicionFotos.Eliminar(const AInfo: TFotoInfo);
var
  oMetadatos: TMetadatosFotoPersistida;
begin
  if AInfo.Encontrada and (AInfo.CodigoArt <> '') and
     (AInfo.Orden > 0) and
     FRepositorio.BuscarFotoEditable(
       AInfo.CodigoArt, AInfo.ClaveResuelta, AInfo.Orden,
       oMetadatos) then
  begin
    if not SameText(oMetadatos.Nombre, AInfo.NombreBase) then
      raise Exception.Create(SErrorFotoSeleccionadaCambio);
    FRepositorio.EliminarFoto(
      AInfo.CodigoArt, AInfo.ClaveResuelta, AInfo.Orden,
      oMetadatos.Nombre);
    FAlmacenamiento.BorrarCopias(oMetadatos.Nombre);
    FConsulta.LimpiarPrecargaFotos;
  end;
end;

function TEdicionFotos.MarcarPredeterminada(
  const AInfo: TFotoInfo;
  const AUsuario: string): TFotoInfo;
begin
  if (not AInfo.Encontrada) or (AInfo.CodigoArt = '') or
     (AInfo.Orden < 1) or (AInfo.NombreBase = '') then
    raise Exception.Create(
      SErrorFotoNoRegistradaParaPredeterminar);
  try
    FRepositorio.MarcarFotoPredeterminada(
      AInfo.CodigoArt,
      AInfo.ClaveResuelta,
      AInfo.Orden,
      AInfo.NombreBase,
      AUsuario);
  finally
    FConsulta.LimpiarPrecargaFotos;
  end;
  Result := AInfo;
  Result.Orden := 1;
end;

end.
