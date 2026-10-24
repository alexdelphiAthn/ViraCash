{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFotosSesion                                              }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Fotografías temporales y materialización de sesiones de compra.           }
{******************************************************************************}
unit inLibFotosSesion;

interface

uses
  inLibFotosPersistenciaIntf,
  inLibFotosSesionPersistenciaIntf, inLibFotosTipos,
  inLibFotosAlmacenamiento;

type
  TSolicitudFotoSesion = record
    Linea: Integer;
    CodigoArticuloTentativo: string;
    CodigoUnidad: string;
    FicheroOrigen: string;
  end;
  TSolicitudesFotosSesion = TArray<TSolicitudFotoSesion>;
  TSesionFotos = class
  private
    FRepositorioSesion : IRepositorioSesionFotos;
    FRepositorioEdicion: IRepositorioEdicionFotos;
    FAlmacenamiento    : TAlmacenamientoFotos;
    function BuscarFoto(const ASerieSesion,
      ANumeroSesion: string; ALinea: Integer;
      const ACodigoUnidad, ACodigoSolicitado: string;
      AOrigen: TFotoOrigen): TFotoInfo;
    function ClaveNombreSesion(const ASerieSesion,
      ANumeroSesion: string; ALinea: Integer;
      const ACodigoUnidad: string): string;
  public
    constructor Create(AAlmacenamiento: TAlmacenamientoFotos);
    procedure AsignarRepositorios(
      const ARepositorioSesion: IRepositorioSesionFotos;
      const ARepositorioEdicion: IRepositorioEdicionFotos);
    procedure LiberarServicios;
    function Guardar(const ASerieSesion, ANumeroSesion: string;
      ALinea: Integer; const ACodigoArticuloTentativo,
      ACodigoUnidad, AFicheroOrigen, AUsuario: string): TFotoInfo;
    procedure GuardarNuevasLote(const ASerieSesion,
      ANumeroSesion: string;
      const ASolicitudes: TSolicitudesFotosSesion;
      const AUsuario: string);
    function Resolver(const ASerieSesion, ANumeroSesion: string;
      ALinea: Integer; const ACodigoUnidad: string = ''): TFotoInfo;
    function Rotar(const ASerieSesion, ANumeroSesion: string;
      ALinea: Integer; const ACodigoUnidad: string;
      AHorario: Boolean; const AUsuario: string): TFotoInfo;
    procedure Eliminar(const ASerieSesion, ANumeroSesion: string;
      ALinea: Integer; const ACodigoUnidad: string);
    procedure Migrar(const ASerieSesion, ANumeroSesion: string;
      ALinea: Integer; const ACodigoArticulo, AUsuario: string);
  end;

implementation

uses
  System.SysUtils,
  inLibFotosConsulta, inLibMsgArticulos;

constructor TSesionFotos.Create(
  AAlmacenamiento: TAlmacenamientoFotos);
begin
  inherited Create;
  FAlmacenamiento := AAlmacenamiento;
end;

procedure TSesionFotos.AsignarRepositorios(
  const ARepositorioSesion: IRepositorioSesionFotos;
  const ARepositorioEdicion: IRepositorioEdicionFotos);
begin
  FRepositorioSesion := ARepositorioSesion;
  FRepositorioEdicion := ARepositorioEdicion;
end;

procedure TSesionFotos.LiberarServicios;
begin
  FRepositorioSesion := nil;
  FRepositorioEdicion := nil;
end;

function TSesionFotos.ClaveNombreSesion(const ASerieSesion,
  ANumeroSesion: string; ALinea: Integer;
  const ACodigoUnidad: string): string;
var
  sUnidad  : string;
  iCaracter: Integer;
begin
  Result := 'ses_' + ASerieSesion + '_' + ANumeroSesion + '_' +
    Format('%.4d', [ALinea]);
  sUnidad := ACodigoUnidad;
  if sUnidad <> '' then
  begin
    for iCaracter := 1 to Length(sUnidad) do
    begin
      if not CharInSet(sUnidad[iCaracter],
        ['A'..'Z', 'a'..'z', '0'..'9', '-', '_']) then
        sUnidad[iCaracter] := '_';
    end;
    Result := Result + '_' + sUnidad;
  end;
end;

function TSesionFotos.Guardar(const ASerieSesion,
  ANumeroSesion: string; ALinea: Integer;
  const ACodigoArticuloTentativo, ACodigoUnidad,
  AFicheroOrigen, AUsuario: string): TFotoInfo;
var
  oMetadatos     : TMetadatosFotoSesion;
  sClave         : string;
  sExtension     : string;
  sNombreAnterior: string;
  sNombreNuevo   : string;
  iIndice        : Integer;
begin
  Result.Clear;
  if ASerieSesion = '' then
    raise Exception.Create(SErrorFotoSesionSinSerie);
  if ANumeroSesion = '' then
    raise Exception.Create(SErrorFotoSesionSinNumero);
  if ALinea <= 0 then
    raise Exception.Create(SErrorFotoSesionLineaInvalida);
  if not FileExists(AFicheroOrigen) then
    raise Exception.Create(Format(SErrorFicheroOrigenFotoNoExiste,
      [AFicheroOrigen]));
  sClave := ClaveNombreSesion(ASerieSesion, ANumeroSesion,
    ALinea, ACodigoUnidad);
  sExtension := FAlmacenamiento.ExtensionOrigen(AFicheroOrigen);
  sNombreAnterior := '';
  iIndice := 1;
  if FRepositorioSesion.BuscarFotoSesion(
    ASerieSesion, ANumeroSesion, ALinea, ACodigoUnidad,
    oMetadatos) then
  begin
    sNombreAnterior := oMetadatos.Nombre;
    iIndice := FAlmacenamiento.ExtraerIndice(
      sNombreAnterior) + 1;
    if iIndice < 1 then
      iIndice := 1;
  end;
  sNombreNuevo := FAlmacenamiento.ComponerNombre(
    sClave, iIndice);
  FAlmacenamiento.GuardarCopias(AFicheroOrigen, sNombreNuevo);
  FRepositorioSesion.GuardarFotoSesion(
    ASerieSesion,
    ANumeroSesion,
    ALinea,
    ACodigoUnidad,
    ACodigoArticuloTentativo,
    sNombreNuevo,
    sExtension,
    AUsuario);
  if (sNombreAnterior <> '') and
     (sNombreAnterior <> sNombreNuevo) then
    FAlmacenamiento.BorrarCopias(sNombreAnterior);
  Result.Encontrada := True;
  Result.Origen := foSku;
  Result.CodigoArt := ACodigoArticuloTentativo;
  Result.CodigoSku := ACodigoUnidad;
  Result.ClaveResuelta := ACodigoUnidad;
  Result.Orden := 1;
  Result.NombreBase := sNombreNuevo;
  Result.ExtensionOrigen := sExtension;
end;

procedure TSesionFotos.GuardarNuevasLote(
  const ASerieSesion, ANumeroSesion: string;
  const ASolicitudes: TSolicitudesFotosSesion;
  const AUsuario: string);
var
  aMetadatos: TMetadatosFotosSesionLote;
  iCopiaCreada: Integer;
  iFoto: Integer;
  sClave: string;
begin
  if ASerieSesion = '' then
    raise Exception.Create(SErrorFotoSesionSinSerie);
  if ANumeroSesion = '' then
    raise Exception.Create(SErrorFotoSesionSinNumero);
  SetLength(aMetadatos, Length(ASolicitudes));
  iCopiaCreada := -1;
  try
    for iFoto := 0 to High(ASolicitudes) do
    begin
      if ASolicitudes[iFoto].Linea <= 0 then
        raise Exception.Create(SErrorFotoSesionLineaInvalida);
      if not FileExists(ASolicitudes[iFoto].FicheroOrigen) then
        raise Exception.Create(Format(
          SErrorFicheroOrigenFotoNoExiste,
          [ASolicitudes[iFoto].FicheroOrigen]));
      sClave := ClaveNombreSesion(
        ASerieSesion,
        ANumeroSesion,
        ASolicitudes[iFoto].Linea,
        ASolicitudes[iFoto].CodigoUnidad);
      aMetadatos[iFoto].Linea := ASolicitudes[iFoto].Linea;
      aMetadatos[iFoto].CodigoArticuloTentativo :=
        ASolicitudes[iFoto].CodigoArticuloTentativo;
      aMetadatos[iFoto].CodigoUnidad :=
        ASolicitudes[iFoto].CodigoUnidad;
      aMetadatos[iFoto].Nombre :=
        FAlmacenamiento.ComponerNombre(sClave, 1);
      aMetadatos[iFoto].Extension :=
        FAlmacenamiento.ExtensionOrigen(
          ASolicitudes[iFoto].FicheroOrigen);
      FAlmacenamiento.GuardarCopias(
        ASolicitudes[iFoto].FicheroOrigen,
        aMetadatos[iFoto].Nombre);
      iCopiaCreada := iFoto;
    end;
    FRepositorioSesion.GuardarFotosSesionLote(
      ASerieSesion,
      ANumeroSesion,
      aMetadatos,
      AUsuario);
  except
    for iFoto := 0 to iCopiaCreada do
      FAlmacenamiento.BorrarCopias(aMetadatos[iFoto].Nombre);
    raise;
  end;
end;

function TSesionFotos.BuscarFoto(const ASerieSesion,
  ANumeroSesion: string; ALinea: Integer;
  const ACodigoUnidad, ACodigoSolicitado: string;
  AOrigen: TFotoOrigen): TFotoInfo;
var
  oMetadatos: TMetadatosFotoSesion;
begin
  Result.Clear;
  if FRepositorioSesion.BuscarFotoSesion(
    ASerieSesion, ANumeroSesion, ALinea, ACodigoUnidad,
    oMetadatos) then
  begin
    Result.Encontrada := True;
    Result.Origen := AOrigen;
    Result.CodigoArt := oMetadatos.CodigoArticuloTentativo;
    Result.CodigoSku := ACodigoSolicitado;
    Result.ClaveResuelta := ACodigoUnidad;
    Result.Orden := 1;
    Result.NombreBase := oMetadatos.Nombre;
    Result.ExtensionOrigen := oMetadatos.Extension;
  end;
end;

function TSesionFotos.Resolver(const ASerieSesion,
  ANumeroSesion: string; ALinea: Integer;
  const ACodigoUnidad: string): TFotoInfo;
var
  aPrefijos: TArray<string>;
  iPrefijo : Integer;
  eOrigen  : TFotoOrigen;
begin
  Result.Clear;
  if (ASerieSesion <> '') and (ANumeroSesion <> '') and
     (ALinea > 0) then
  begin
    if ACodigoUnidad = '' then
      eOrigen := foArticulo
    else
      eOrigen := foSku;
    Result := BuscarFoto(ASerieSesion, ANumeroSesion, ALinea,
      ACodigoUnidad, ACodigoUnidad, eOrigen);
    if (not Result.Encontrada) and (ACodigoUnidad <> '') then
    begin
      aPrefijos := GenerarPrefijosSku(ACodigoUnidad);
      iPrefijo := 0;
      while (iPrefijo <= High(aPrefijos)) and
            (not Result.Encontrada) do
      begin
        if aPrefijos[iPrefijo] <> ACodigoUnidad then
          Result := BuscarFoto(ASerieSesion, ANumeroSesion,
            ALinea, aPrefijos[iPrefijo], ACodigoUnidad,
            foSkuPrefijo);
        Inc(iPrefijo);
      end;
    end;
    if (not Result.Encontrada) and (ACodigoUnidad <> '') then
      Result := BuscarFoto(ASerieSesion, ANumeroSesion, ALinea,
        '', ACodigoUnidad, foArticulo);
  end;
end;

function TSesionFotos.Rotar(const ASerieSesion,
  ANumeroSesion: string; ALinea: Integer;
  const ACodigoUnidad: string; AHorario: Boolean;
  const AUsuario: string): TFotoInfo;
var
  oMetadatos     : TMetadatosFotoSesion;
  sClave         : string;
  sNombreAnterior: string;
  sNombreNuevo   : string;
  iIndice        : Integer;
begin
  Result.Clear;
  if not FRepositorioSesion.BuscarFotoSesion(
    ASerieSesion, ANumeroSesion, ALinea, ACodigoUnidad,
    oMetadatos) then
    raise Exception.Create(SErrorFotoNoRegistradaParaRotar);
  sClave := ClaveNombreSesion(
    ASerieSesion, ANumeroSesion, ALinea, ACodigoUnidad);
  sNombreAnterior := oMetadatos.Nombre;
  iIndice := FAlmacenamiento.ExtraerIndice(sNombreAnterior) + 1;
  if iIndice < 1 then
    iIndice := 1;
  sNombreNuevo := FAlmacenamiento.ComponerNombre(sClave, iIndice);
  FAlmacenamiento.RotarCopias(
    sNombreAnterior, sNombreNuevo, AHorario);
  FRepositorioSesion.GuardarFotoSesion(
    ASerieSesion,
    ANumeroSesion,
    ALinea,
    ACodigoUnidad,
    oMetadatos.CodigoArticuloTentativo,
    sNombreNuevo,
    oMetadatos.Extension,
    AUsuario);
  Result.Encontrada := True;
  if ACodigoUnidad = '' then
    Result.Origen := foArticulo
  else
    Result.Origen := foSku;
  Result.CodigoArt := oMetadatos.CodigoArticuloTentativo;
  Result.CodigoSku := ACodigoUnidad;
  Result.ClaveResuelta := ACodigoUnidad;
  Result.Orden := 1;
  Result.NombreBase := sNombreNuevo;
  Result.ExtensionOrigen := oMetadatos.Extension;
end;

procedure TSesionFotos.Eliminar(const ASerieSesion,
  ANumeroSesion: string; ALinea: Integer;
  const ACodigoUnidad: string);
var
  oMetadatos: TMetadatosFotoSesion;
  sNombre: string;
begin
  if (ASerieSesion <> '') and (ANumeroSesion <> '') and
     (ALinea > 0) then
  begin
    sNombre := '';
    if FRepositorioSesion.BuscarFotoSesion(
      ASerieSesion, ANumeroSesion, ALinea, ACodigoUnidad,
      oMetadatos) then
      sNombre := oMetadatos.Nombre;
    if sNombre <> '' then
    begin
      FRepositorioSesion.EliminarFotoSesion(
        ASerieSesion, ANumeroSesion, ALinea, ACodigoUnidad);
      FAlmacenamiento.BorrarCopias(sNombre);
    end;
  end;
end;

procedure TSesionFotos.Migrar(const ASerieSesion,
  ANumeroSesion: string; ALinea: Integer;
  const ACodigoArticulo, AUsuario: string);
var
  aOrigen      : TArray<TMetadatosFotoSesion>;
  oDestino     : TMetadatosFotoPersistida;
  sClave       : string;
  sCodigoUnidad: string;
  sExtension   : string;
  sNombreOrigen: string;
  sNombreNuevo : string;
  iIndice      : Integer;
  iFoto        : Integer;
begin
  if (ASerieSesion <> '') and (ANumeroSesion <> '') and
     (ALinea > 0) and (Trim(ACodigoArticulo) <> '') then
  begin
    aOrigen := FRepositorioSesion.BuscarFotosSesionLinea(
      ASerieSesion, ANumeroSesion, ALinea);
    for iFoto := 0 to High(aOrigen) do
    begin
      sCodigoUnidad := aOrigen[iFoto].CodigoUnidad;
      sNombreOrigen := aOrigen[iFoto].Nombre;
      sExtension := aOrigen[iFoto].Extension;
      if not FRepositorioEdicion.BuscarFotoEditable(
        ACodigoArticulo, sCodigoUnidad, oDestino) then
      begin
        sClave := FAlmacenamiento.ClaveNombre(
          ACodigoArticulo, sCodigoUnidad);
        iIndice := 1;
        sNombreNuevo := FAlmacenamiento.ComponerNombre(
          sClave, iIndice);
        // Conservar el original hasta confirmar los metadatos permite
        // reintentar si falla el guardado de la foto o de su asignación.
        FAlmacenamiento.GuardarCopias(
          FAlmacenamiento.RutaDeNombre(sNombreOrigen, frReal),
          sNombreNuevo);
        FRepositorioSesion.GuardarFotoMigrada(
          ACodigoArticulo,
          sCodigoUnidad,
          sNombreNuevo,
          sExtension,
          AUsuario);
      end;
      FRepositorioSesion.EliminarFotoSesion(
        ASerieSesion, ANumeroSesion, ALinea, sCodigoUnidad);
      FAlmacenamiento.BorrarCopias(sNombreOrigen);
    end;
  end;
end;

end.
