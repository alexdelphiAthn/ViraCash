{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataFotosEdicionRepositorio                               }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Escritura UniDAC de metadatos de fotografías de artículos y SKU.          }
{******************************************************************************}
unit UniDataFotosEdicionRepositorio;

interface

uses
  Uni, inLibFotosPersistenciaIntf;

function CrearRepositorioEdicionFotosUniDAC(
  AConexion: TUniConnection): IRepositorioEdicionFotos;

implementation

uses
  Winapi.Windows, System.SysUtils, System.Hash,
  inLibMsgFotos;

const
  fcodartfot = 'CODIGO_ART_FOT';
  fcodunidadfot = 'CODIGO_UNIDAD_FOT';
  fordenfot = 'ORDEN_FOT';
  fnomfot = 'NOMBRE_FOT_FOT';
  fextfot = 'EXTENSION_ORIGEN_FOT';

type
  TRepositorioEdicionFotosUniDAC = class(
    TInterfacedObject,
    IRepositorioEdicionFotos)
  private
    FConexion: TUniConnection;
    function NuevaConsulta: TUniQuery;
    function ClaveBloqueoColeccion(const ACodigoArticulo,
      ACodigoUnidad: string): string;
    procedure AdquirirBloqueoColeccion(AConsulta: TUniQuery;
      const AClave: string);
    procedure LiberarBloqueoColeccion(AConsulta: TUniQuery;
      const AClave: string);
    procedure ComprobarSinTransaccionExterna;
    function BloquearFilasYObtenerOrdenTemporal(
      AConsulta: TUniQuery;
      const ACodigoArticulo, ACodigoUnidad: string;
      AOrdenEsperado: Integer;
      const ANombreEsperado: string): Integer;
    procedure CambiarOrdenFoto(
      AConsulta: TUniQuery;
      const ACodigoArticulo, ACodigoUnidad: string;
      AOrdenOrigen, AOrdenDestino: Integer;
      const ANombreEsperado, AUsuario: string);
    procedure DesplazarFotosAnteriores(
      AConsulta: TUniQuery;
      const ACodigoArticulo, ACodigoUnidad: string;
      AOrdenEsperado: Integer;
      const AUsuario: string);
  public
    constructor Create(AConexion: TUniConnection);
    function BuscarFotoEditable(
      const ACodigoArticulo, ACodigoUnidad: string;
      out AMetadatos: TMetadatosFotoPersistida): Boolean; overload;
    function BuscarFotoEditable(
      const ACodigoArticulo, ACodigoUnidad: string;
      AOrden: Integer;
      out AMetadatos: TMetadatosFotoPersistida): Boolean; overload;
    function BuscarFotosEditables(
      const ACodigoArticulo, ACodigoUnidad: string):
      TArray<TMetadatosFotoPersistida>;
    procedure GuardarFoto(
      const AMetadatos: TMetadatosFotoPersistida;
      const ANombreAnterior, AUsuario: string);
    procedure AnadirFoto(
      var AMetadatos: TMetadatosFotoPersistida;
      const AUsuario: string);
    procedure ActualizarNombreFoto(
      const ACodigoArticulo, ACodigoUnidad: string;
      AOrden: Integer;
      const ANombreAnterior, ANombre, AUsuario: string);
    procedure EliminarFoto(
      const ACodigoArticulo, ACodigoUnidad: string;
      AOrden: Integer;
      const ANombreEsperado: string);
    procedure MarcarFotoPredeterminada(
      const ACodigoArticulo, ACodigoUnidad: string;
      AOrdenEsperado: Integer;
      const ANombreEsperado, AUsuario: string);
  end;

function LeerMetadatosFoto(
  AConsulta: TUniQuery): TMetadatosFotoPersistida;
begin
  Result := Default(TMetadatosFotoPersistida);
  Result.CodigoArticulo :=
    AConsulta.FieldByName(fcodartfot).AsString;
  Result.CodigoUnidad :=
    AConsulta.FieldByName(fcodunidadfot).AsString;
  Result.Orden := AConsulta.FieldByName(fordenfot).AsInteger;
  Result.Nombre := AConsulta.FieldByName(fnomfot).AsString;
  Result.Extension := AConsulta.FieldByName(fextfot).AsString;
end;

constructor TRepositorioEdicionFotosUniDAC.Create(
  AConexion: TUniConnection);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioEdicionFotosUniDAC.NuevaConsulta: TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

function TRepositorioEdicionFotosUniDAC.ClaveBloqueoColeccion(
  const ACodigoArticulo, ACodigoUnidad: string): string;
begin
  Result := 'fza_fotos_' + THashMD5.GetHashString(
    UpperCase(Trim(ACodigoArticulo)) + #31 +
    UpperCase(Trim(ACodigoUnidad)));
end;

procedure TRepositorioEdicionFotosUniDAC.AdquirirBloqueoColeccion(
  AConsulta: TUniQuery; const AClave: string);
begin
  AConsulta.Close;
  AConsulta.SQL.Text :=
    'SELECT GET_LOCK(:CLAVE_BLOQUEO, 10) AS ADQUIRIDO';
  AConsulta.ParamByName('CLAVE_BLOQUEO').AsString := AClave;
  AConsulta.Open;
  if AConsulta.FieldByName('ADQUIRIDO').AsInteger <> 1 then
    raise Exception.Create(
      'No se pudo bloquear la galería para modificarla. Inténtalo de nuevo.');
  AConsulta.Close;
end;

procedure TRepositorioEdicionFotosUniDAC.LiberarBloqueoColeccion(
  AConsulta: TUniQuery; const AClave: string);
var
  iIntento : Integer;
  bLiberada: Boolean;
begin
  // La mutación ya puede estar confirmada, por lo que un fallo al liberar no
  // se propaga al llamador. Se reintenta; si se perdió la conexión, el propio
  // servidor libera automáticamente sus bloqueos de sesión.
  iIntento := 0;
  bLiberada := False;
  while (iIntento < 3) and not bLiberada do
  begin
    Inc(iIntento);
    try
      AConsulta.Close;
      AConsulta.SQL.Text :=
        'SELECT RELEASE_LOCK(:CLAVE_BLOQUEO) AS LIBERADO';
      AConsulta.ParamByName('CLAVE_BLOQUEO').AsString := AClave;
      AConsulta.Open;
      AConsulta.Close;
      bLiberada := True;
    except
      on E: Exception do
        OutputDebugString(PChar(Format(
          'No se pudo liberar el bloqueo de fotos (intento %d): %s',
          [iIntento, E.Message])));
    end;
  end;
end;

procedure TRepositorioEdicionFotosUniDAC.ComprobarSinTransaccionExterna;
begin
  if FConexion.InTransaction then
    raise Exception.Create(
      'No se pueden modificar fotos dentro de una transacción externa.');
end;

function TRepositorioEdicionFotosUniDAC.
  BloquearFilasYObtenerOrdenTemporal(
  AConsulta: TUniQuery;
  const ACodigoArticulo, ACodigoUnidad: string;
  AOrdenEsperado: Integer;
  const ANombreEsperado: string): Integer;
var
  bSeleccionEncontrada: Boolean;
  iOrdenActual         : Integer;
  iOrdenSiguiente      : Integer;
begin
  bSeleccionEncontrada := False;
  iOrdenSiguiente := 1;
  AConsulta.Close;
  AConsulta.SQL.Text :=
    ' SELECT ORDEN_FOT, NOMBRE_FOT_FOT ' +
    '   FROM fza_articulos_fotos ' +
    '  WHERE CODIGO_ART_FOT    = :CODIGO_ART ' +
    '    AND CODIGO_UNIDAD_FOT = :CODIGO_UNIDAD ' +
    '  ORDER BY ORDEN_FOT ' +
    '  FOR UPDATE';
  AConsulta.ParamByName('CODIGO_ART').AsString :=
    ACodigoArticulo;
  AConsulta.ParamByName('CODIGO_UNIDAD').AsString :=
    ACodigoUnidad;
  AConsulta.Open;
  while not AConsulta.Eof do
  begin
    iOrdenActual := AConsulta.FieldByName(fordenfot).AsInteger;
    if iOrdenActual <> iOrdenSiguiente then
      raise Exception.Create(SErrorGaleriaFotosCambio);
    if (iOrdenActual = AOrdenEsperado) and
       SameText(AConsulta.FieldByName(fnomfot).AsString,
         ANombreEsperado) then
      bSeleccionEncontrada := True;
    if iOrdenSiguiente = MaxInt then
      raise Exception.Create(SErrorGaleriaFotosCambio);
    Inc(iOrdenSiguiente);
    AConsulta.Next;
  end;
  AConsulta.Close;
  if not bSeleccionEncontrada then
    raise Exception.Create(SErrorFotoSeleccionadaCambio);
  Result := iOrdenSiguiente;
end;

procedure TRepositorioEdicionFotosUniDAC.CambiarOrdenFoto(
  AConsulta: TUniQuery;
  const ACodigoArticulo, ACodigoUnidad: string;
  AOrdenOrigen, AOrdenDestino: Integer;
  const ANombreEsperado, AUsuario: string);
begin
  AConsulta.Close;
  AConsulta.SQL.Text :=
    ' UPDATE fza_articulos_fotos ' +
    '    SET ORDEN_FOT      = :ORDEN_DESTINO, ' +
    '        INSTANTE_MODIF = NOW(), ' +
    '        USUARIO_MODIF  = :USUARIO ' +
    '  WHERE CODIGO_ART_FOT    = :CODIGO_ART ' +
    '    AND CODIGO_UNIDAD_FOT = :CODIGO_UNIDAD ' +
    '    AND ORDEN_FOT         = :ORDEN_ORIGEN ' +
    '    AND NOMBRE_FOT_FOT    = :NOMBRE_ESPERADO';
  AConsulta.ParamByName('ORDEN_DESTINO').AsInteger :=
    AOrdenDestino;
  AConsulta.ParamByName('USUARIO').AsString := AUsuario;
  AConsulta.ParamByName('CODIGO_ART').AsString :=
    ACodigoArticulo;
  AConsulta.ParamByName('CODIGO_UNIDAD').AsString :=
    ACodigoUnidad;
  AConsulta.ParamByName('ORDEN_ORIGEN').AsInteger :=
    AOrdenOrigen;
  AConsulta.ParamByName('NOMBRE_ESPERADO').AsString :=
    ANombreEsperado;
  AConsulta.Execute;
  if AConsulta.RowsAffected <> 1 then
    raise Exception.Create(SErrorFotoSeleccionadaCambio);
end;

procedure TRepositorioEdicionFotosUniDAC.DesplazarFotosAnteriores(
  AConsulta: TUniQuery;
  const ACodigoArticulo, ACodigoUnidad: string;
  AOrdenEsperado: Integer;
  const AUsuario: string);
begin
  AConsulta.Close;
  AConsulta.SQL.Text :=
    ' UPDATE fza_articulos_fotos ' +
    '    SET ORDEN_FOT      = ORDEN_FOT + 1, ' +
    '        INSTANTE_MODIF = NOW(), ' +
    '        USUARIO_MODIF  = :USUARIO ' +
    '  WHERE CODIGO_ART_FOT    = :CODIGO_ART ' +
    '    AND CODIGO_UNIDAD_FOT = :CODIGO_UNIDAD ' +
    '    AND ORDEN_FOT        >= 1 ' +
    '    AND ORDEN_FOT         < :ORDEN_ESPERADO ' +
    '  ORDER BY ORDEN_FOT DESC';
  AConsulta.ParamByName('USUARIO').AsString := AUsuario;
  AConsulta.ParamByName('CODIGO_ART').AsString :=
    ACodigoArticulo;
  AConsulta.ParamByName('CODIGO_UNIDAD').AsString :=
    ACodigoUnidad;
  AConsulta.ParamByName('ORDEN_ESPERADO').AsInteger :=
    AOrdenEsperado;
  AConsulta.Execute;
  if AConsulta.RowsAffected <> AOrdenEsperado - 1 then
    raise Exception.Create(SErrorGaleriaFotosCambio);
end;

function TRepositorioEdicionFotosUniDAC.BuscarFotoEditable(
  const ACodigoArticulo, ACodigoUnidad: string;
  out AMetadatos: TMetadatosFotoPersistida): Boolean;
begin
  Result := BuscarFotoEditable(
    ACodigoArticulo, ACodigoUnidad, 1, AMetadatos);
end;

function TRepositorioEdicionFotosUniDAC.BuscarFotoEditable(
  const ACodigoArticulo, ACodigoUnidad: string;
  AOrden: Integer;
  out AMetadatos: TMetadatosFotoPersistida): Boolean;
var
  oConsulta: TUniQuery;
begin
  AMetadatos := Default(TMetadatosFotoPersistida);
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      ' SELECT CODIGO_ART_FOT, CODIGO_UNIDAD_FOT, ORDEN_FOT, ' +
      '        NOMBRE_FOT_FOT, EXTENSION_ORIGEN_FOT ' +
      '   FROM fza_articulos_fotos ' +
      '  WHERE CODIGO_ART_FOT    = :CODIGO_ART ' +
      '    AND CODIGO_UNIDAD_FOT = :CODIGO_UNIDAD ' +
      '    AND ORDEN_FOT         = :ORDEN ' +
      '  ORDER BY NOMBRE_FOT_FOT ' +
      '  LIMIT 1';
    oConsulta.ParamByName('CODIGO_ART').AsString :=
      ACodigoArticulo;
    oConsulta.ParamByName('CODIGO_UNIDAD').AsString :=
      ACodigoUnidad;
    oConsulta.ParamByName('ORDEN').AsInteger := AOrden;
    oConsulta.Open;
    Result := not oConsulta.Eof;
    if Result then
      AMetadatos := LeerMetadatosFoto(oConsulta);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioEdicionFotosUniDAC.BuscarFotosEditables(
  const ACodigoArticulo, ACodigoUnidad: string):
  TArray<TMetadatosFotoPersistida>;
var
  oConsulta: TUniQuery;
  iFoto: Integer;
begin
  SetLength(Result, 0);
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      ' SELECT CODIGO_ART_FOT, CODIGO_UNIDAD_FOT, ORDEN_FOT, ' +
      '        NOMBRE_FOT_FOT, EXTENSION_ORIGEN_FOT ' +
      '   FROM fza_articulos_fotos ' +
      '  WHERE CODIGO_ART_FOT    = :CODIGO_ART ' +
      '    AND CODIGO_UNIDAD_FOT = :CODIGO_UNIDAD ' +
      '  ORDER BY ORDEN_FOT, NOMBRE_FOT_FOT';
    oConsulta.ParamByName('CODIGO_ART').AsString :=
      ACodigoArticulo;
    oConsulta.ParamByName('CODIGO_UNIDAD').AsString :=
      ACodigoUnidad;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iFoto := Length(Result);
      SetLength(Result, iFoto + 1);
      Result[iFoto] := LeerMetadatosFoto(oConsulta);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioEdicionFotosUniDAC.GuardarFoto(
  const AMetadatos: TMetadatosFotoPersistida;
  const ANombreAnterior, AUsuario: string);
var
  oConsulta     : TUniQuery;
  sClaveBloqueo: string;
  bBloqueada   : Boolean;
begin
  ComprobarSinTransaccionExterna;
  sClaveBloqueo := ClaveBloqueoColeccion(
    AMetadatos.CodigoArticulo, AMetadatos.CodigoUnidad);
  bBloqueada := False;
  oConsulta := NuevaConsulta;
  try
    AdquirirBloqueoColeccion(oConsulta, sClaveBloqueo);
    bBloqueada := True;
    FConexion.StartTransaction;
    try
      if ANombreAnterior = '' then
        oConsulta.SQL.Text :=
          'INSERT INTO fza_articulos_fotos ' +
          '  (CODIGO_ART_FOT, CODIGO_UNIDAD_FOT, ORDEN_FOT, ' +
          '   NOMBRE_FOT_FOT, EXTENSION_ORIGEN_FOT, INSTANTE_ALTA, ' +
          '   USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
          'VALUES (:a, :u, :orden, :nom, :ext, NOW(), :usr, ' +
          '        NOW(), :usr)'
      else
        oConsulta.SQL.Text :=
          ' UPDATE fza_articulos_fotos ' +
          '    SET NOMBRE_FOT_FOT       = :nom, ' +
          '        EXTENSION_ORIGEN_FOT = :ext, ' +
          '        INSTANTE_MODIF       = NOW(), ' +
          '        USUARIO_MODIF        = :usr ' +
          '  WHERE CODIGO_ART_FOT    = :a ' +
          '    AND CODIGO_UNIDAD_FOT = :u ' +
          '    AND ORDEN_FOT         = :orden ' +
          '    AND NOMBRE_FOT_FOT    = :nombre_anterior';
      oConsulta.ParamByName('a').AsString :=
        AMetadatos.CodigoArticulo;
      oConsulta.ParamByName('u').AsString :=
        AMetadatos.CodigoUnidad;
      oConsulta.ParamByName('orden').AsInteger := AMetadatos.Orden;
      oConsulta.ParamByName('nom').AsString := AMetadatos.Nombre;
      oConsulta.ParamByName('ext').AsString := AMetadatos.Extension;
      oConsulta.ParamByName('usr').AsString := AUsuario;
      if ANombreAnterior <> '' then
        oConsulta.ParamByName('nombre_anterior').AsString :=
          ANombreAnterior;
      oConsulta.ExecSQL;
      if (ANombreAnterior <> '') and
         (oConsulta.RowsAffected <> 1) then
        raise Exception.Create(SErrorFotoSeleccionadaCambio);
      FConexion.Commit;
    except
      if FConexion.InTransaction then
        FConexion.Rollback;
      raise;
    end;
  finally
    if bBloqueada then
      LiberarBloqueoColeccion(oConsulta, sClaveBloqueo);
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioEdicionFotosUniDAC.AnadirFoto(
  var AMetadatos: TMetadatosFotoPersistida;
  const AUsuario: string);
var
  oConsulta     : TUniQuery;
  sClaveBloqueo: string;
  bBloqueada   : Boolean;
begin
  ComprobarSinTransaccionExterna;
  sClaveBloqueo := ClaveBloqueoColeccion(
    AMetadatos.CodigoArticulo, AMetadatos.CodigoUnidad);
  bBloqueada := False;
  oConsulta := NuevaConsulta;
  try
    AdquirirBloqueoColeccion(oConsulta, sClaveBloqueo);
    bBloqueada := True;
    FConexion.StartTransaction;
    try
      oConsulta.SQL.Text :=
        ' SELECT COALESCE(MAX(ORDEN_FOT), 0) + 1 AS SIGUIENTE ' +
        '   FROM fza_articulos_fotos ' +
        '  WHERE CODIGO_ART_FOT    = :a ' +
        '    AND CODIGO_UNIDAD_FOT = :u';
      oConsulta.ParamByName('a').AsString :=
        AMetadatos.CodigoArticulo;
      oConsulta.ParamByName('u').AsString :=
        AMetadatos.CodigoUnidad;
      oConsulta.Open;
      AMetadatos.Orden :=
        oConsulta.FieldByName('SIGUIENTE').AsInteger;
      oConsulta.Close;

      oConsulta.SQL.Text :=
        'INSERT INTO fza_articulos_fotos ' +
        '  (CODIGO_ART_FOT, CODIGO_UNIDAD_FOT, ORDEN_FOT, ' +
        '   NOMBRE_FOT_FOT, EXTENSION_ORIGEN_FOT, INSTANTE_ALTA, ' +
        '   USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
        'VALUES (:a, :u, :orden, :nom, :ext, NOW(), :usr, ' +
        '        NOW(), :usr)';
      oConsulta.ParamByName('a').AsString :=
        AMetadatos.CodigoArticulo;
      oConsulta.ParamByName('u').AsString :=
        AMetadatos.CodigoUnidad;
      oConsulta.ParamByName('orden').AsInteger := AMetadatos.Orden;
      oConsulta.ParamByName('nom').AsString := AMetadatos.Nombre;
      oConsulta.ParamByName('ext').AsString := AMetadatos.Extension;
      oConsulta.ParamByName('usr').AsString := AUsuario;
      oConsulta.ExecSQL;
      FConexion.Commit;
    except
      if FConexion.InTransaction then
        FConexion.Rollback;
      raise;
    end;
  finally
    if bBloqueada then
      LiberarBloqueoColeccion(oConsulta, sClaveBloqueo);
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioEdicionFotosUniDAC.ActualizarNombreFoto(
  const ACodigoArticulo, ACodigoUnidad: string;
  AOrden: Integer; const ANombreAnterior, ANombre,
  AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  ComprobarSinTransaccionExterna;
  oConsulta := NuevaConsulta;
  try
    FConexion.StartTransaction;
    try
      oConsulta.SQL.Text :=
        ' UPDATE fza_articulos_fotos ' +
        '    SET NOMBRE_FOT_FOT = :NOMBRE, ' +
        '        USUARIO_MODIF  = :USUARIO ' +
        '  WHERE CODIGO_ART_FOT    = :CODIGO_ART ' +
        '    AND CODIGO_UNIDAD_FOT = :CODIGO_UNIDAD ' +
        '    AND ORDEN_FOT         = :ORDEN ' +
        '    AND NOMBRE_FOT_FOT    = :NOMBRE_ANTERIOR';
      oConsulta.ParamByName('NOMBRE').AsString := ANombre;
      oConsulta.ParamByName('USUARIO').AsString := AUsuario;
      oConsulta.ParamByName('CODIGO_ART').AsString :=
        ACodigoArticulo;
      oConsulta.ParamByName('CODIGO_UNIDAD').AsString :=
        ACodigoUnidad;
      oConsulta.ParamByName('ORDEN').AsInteger := AOrden;
      oConsulta.ParamByName('NOMBRE_ANTERIOR').AsString :=
        ANombreAnterior;
      oConsulta.Execute;
      if oConsulta.RowsAffected <> 1 then
        raise Exception.Create(SErrorFotoSeleccionadaCambio);
      FConexion.Commit;
    except
      if FConexion.InTransaction then
        FConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioEdicionFotosUniDAC.EliminarFoto(
  const ACodigoArticulo, ACodigoUnidad: string;
  AOrden: Integer; const ANombreEsperado: string);
var
  oConsulta     : TUniQuery;
  sClaveBloqueo: string;
  bBloqueada   : Boolean;
begin
  if AOrden < 1 then
    raise EArgumentOutOfRangeException.Create(
      'El orden de la foto debe ser mayor que cero.');
  ComprobarSinTransaccionExterna;
  sClaveBloqueo := ClaveBloqueoColeccion(
    ACodigoArticulo, ACodigoUnidad);
  bBloqueada := False;
  oConsulta := NuevaConsulta;
  try
    AdquirirBloqueoColeccion(oConsulta, sClaveBloqueo);
    bBloqueada := True;
    FConexion.StartTransaction;
    try
      oConsulta.SQL.Text :=
        ' DELETE FROM fza_articulos_fotos ' +
        '  WHERE CODIGO_ART_FOT    = :CODIGO_ART ' +
        '    AND CODIGO_UNIDAD_FOT = :CODIGO_UNIDAD ' +
        '    AND ORDEN_FOT         = :ORDEN ' +
        '    AND NOMBRE_FOT_FOT    = :NOMBRE_ESPERADO';
      oConsulta.ParamByName('CODIGO_ART').AsString :=
        ACodigoArticulo;
      oConsulta.ParamByName('CODIGO_UNIDAD').AsString :=
        ACodigoUnidad;
      oConsulta.ParamByName('ORDEN').AsInteger := AOrden;
      oConsulta.ParamByName('NOMBRE_ESPERADO').AsString :=
        ANombreEsperado;
      oConsulta.Execute;
      if oConsulta.RowsAffected <> 1 then
        raise Exception.Create(SErrorFotoSeleccionadaCambio);

      oConsulta.SQL.Text :=
        ' UPDATE fza_articulos_fotos ' +
        '    SET ORDEN_FOT = ORDEN_FOT - 1 ' +
        '  WHERE CODIGO_ART_FOT    = :CODIGO_ART ' +
        '    AND CODIGO_UNIDAD_FOT = :CODIGO_UNIDAD ' +
        '    AND ORDEN_FOT         > :ORDEN ' +
        '  ORDER BY ORDEN_FOT';
      oConsulta.ParamByName('CODIGO_ART').AsString :=
        ACodigoArticulo;
      oConsulta.ParamByName('CODIGO_UNIDAD').AsString :=
        ACodigoUnidad;
      oConsulta.ParamByName('ORDEN').AsInteger := AOrden;
      oConsulta.Execute;
      FConexion.Commit;
    except
      if FConexion.InTransaction then
        FConexion.Rollback;
      raise;
    end;
  finally
    if bBloqueada then
      LiberarBloqueoColeccion(oConsulta, sClaveBloqueo);
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioEdicionFotosUniDAC.MarcarFotoPredeterminada(
  const ACodigoArticulo, ACodigoUnidad: string;
  AOrdenEsperado: Integer;
  const ANombreEsperado, AUsuario: string);
var
  bBloqueada    : Boolean;
  iOrdenTemporal: Integer;
  oConsulta     : TUniQuery;
  sClaveBloqueo: string;
begin
  if (ACodigoArticulo = '') or (AOrdenEsperado < 1) or
     (ANombreEsperado = '') then
    raise Exception.Create(
      SErrorFotoNoRegistradaParaPredeterminar);
  ComprobarSinTransaccionExterna;
  sClaveBloqueo := ClaveBloqueoColeccion(
    ACodigoArticulo, ACodigoUnidad);
  bBloqueada := False;
  oConsulta := NuevaConsulta;
  try
    AdquirirBloqueoColeccion(oConsulta, sClaveBloqueo);
    bBloqueada := True;
    FConexion.StartTransaction;
    try
      iOrdenTemporal := BloquearFilasYObtenerOrdenTemporal(
        oConsulta,
        ACodigoArticulo,
        ACodigoUnidad,
        AOrdenEsperado,
        ANombreEsperado);
      if AOrdenEsperado > 1 then
      begin
        CambiarOrdenFoto(
          oConsulta,
          ACodigoArticulo,
          ACodigoUnidad,
          AOrdenEsperado,
          iOrdenTemporal,
          ANombreEsperado,
          AUsuario);
        DesplazarFotosAnteriores(
          oConsulta,
          ACodigoArticulo,
          ACodigoUnidad,
          AOrdenEsperado,
          AUsuario);
        CambiarOrdenFoto(
          oConsulta,
          ACodigoArticulo,
          ACodigoUnidad,
          iOrdenTemporal,
          1,
          ANombreEsperado,
          AUsuario);
      end;
      FConexion.Commit;
    except
      if FConexion.InTransaction then
        FConexion.Rollback;
      raise;
    end;
  finally
    if bBloqueada then
      LiberarBloqueoColeccion(oConsulta, sClaveBloqueo);
    FreeAndNil(oConsulta);
  end;
end;

function CrearRepositorioEdicionFotosUniDAC(
  AConexion: TUniConnection): IRepositorioEdicionFotos;
begin
  Result := TRepositorioEdicionFotosUniDAC.Create(AConexion);
end;

end.
