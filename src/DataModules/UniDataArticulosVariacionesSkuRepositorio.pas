{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataArticulosVariacionesSkuRepositorio                    }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Lectura y escritura segregadas del SKU base de un artículo.              }
{******************************************************************************}
unit UniDataArticulosVariacionesSkuRepositorio;

interface

uses
  Uni,
  inLibArticulosVariacionesIntf;

function CrearLecturaSkuArticulosVariacionesUniDAC(
  AConexion: TUniConnection): ILecturaSkuArticulosVariaciones;
function CrearEscrituraSkuArticulosVariacionesUniDAC(
  AConexion: TUniConnection;
  const ALectura: ILecturaSkuArticulosVariaciones):
  IEscrituraSkuArticulosVariaciones;

implementation

uses
  System.SysUtils,
  Data.DB,
  DBAccess,
  inLibArticulosVariaciones,
  UniDataPrestaShopEncolado;

type
  TLecturaSkuArticulosVariacionesUniDAC = class(
    TInterfacedObject,
    ILecturaSkuArticulosVariaciones)
  private
    FConexion: TUniConnection;
    function Existe(
      const ASql, ACodigoArticulo: string): Boolean;
  public
    constructor Create(AConexion: TUniConnection);
    function EsArticuloConVariaciones(
      const ACodigoArticulo: string): Boolean;
    function TieneSku(
      const ACodigoArticulo: string): Boolean;
    function TieneSkuActivo(
      const ACodigoArticulo: string): Boolean;
    function TieneSkuBase(
      const ACodigoArticulo: string): Boolean;
  end;
  TEscrituraSkuArticulosVariacionesUniDAC = class(
    TInterfacedObject,
    IEscrituraSkuArticulosVariaciones)
  private
    FConexion: TUniConnection;
    FLectura: ILecturaSkuArticulosVariaciones;
    procedure InsertarSkuBase(
      const ACodigoArticulo, AUsuario: string);
    procedure ActivarSkuBase(
      const ACodigoArticulo, AUsuario: string);
  public
    constructor Create(
      AConexion: TUniConnection;
      const ALectura: ILecturaSkuArticulosVariaciones);
    procedure AsegurarSkuSinVariaciones(
      const ACodigoArticulo, AUsuario: string);
    procedure AsegurarSkuActivo(
      const ACodigoArticulo, AUsuario: string);
  end;

constructor TLecturaSkuArticulosVariacionesUniDAC.Create(
  AConexion: TUniConnection);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
end;

function TLecturaSkuArticulosVariacionesUniDAC.Existe(
  const ASql, ACodigoArticulo: string): Boolean;
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text := ASql;
    Consulta.ParamByName('codigo').AsString := ACodigoArticulo;
    Consulta.Open;
    Result := not Consulta.IsEmpty;
  finally
    Consulta.Free;
  end;
end;

function TLecturaSkuArticulosVariacionesUniDAC.
  EsArticuloConVariaciones(
  const ACodigoArticulo: string): Boolean;
begin
  Result := Existe(
    'SELECT 1 FROM fza_articulos ' +
    ' WHERE CODIGO_ART_ART = :codigo ' +
    '   AND ESVARIACION_ART = ''S'' ' +
    ' LIMIT 1',
    ACodigoArticulo);
end;

function TLecturaSkuArticulosVariacionesUniDAC.TieneSku(
  const ACodigoArticulo: string): Boolean;
begin
  Result := Existe(
    'SELECT 1 FROM fza_articulos_skus ' +
    ' WHERE CODIGO_ART_SKU = :codigo ' +
    ' LIMIT 1',
    ACodigoArticulo);
end;

function TLecturaSkuArticulosVariacionesUniDAC.TieneSkuActivo(
  const ACodigoArticulo: string): Boolean;
begin
  Result := False;
  if ACodigoArticulo <> '' then
    Result := Existe(
      'SELECT 1 FROM fza_articulos_skus ' +
      ' WHERE CODIGO_ART_SKU = :codigo ' +
      '   AND ESACTIVO_SKU = ''S'' ' +
      ' LIMIT 1',
      ACodigoArticulo);
end;

function TLecturaSkuArticulosVariacionesUniDAC.TieneSkuBase(
  const ACodigoArticulo: string): Boolean;
begin
  Result := Existe(
    'SELECT 1 FROM fza_articulos_skus ' +
    ' WHERE CODIGO_UNIDAD_SKU = :codigo ' +
    ' LIMIT 1',
    ACodigoArticulo);
end;

constructor TEscrituraSkuArticulosVariacionesUniDAC.Create(
  AConexion: TUniConnection;
  const ALectura: ILecturaSkuArticulosVariaciones);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  if not Assigned(ALectura) then
    raise EArgumentNilException.Create('ALectura');
  inherited Create;
  FConexion := AConexion;
  FLectura := ALectura;
end;

procedure TEscrituraSkuArticulosVariacionesUniDAC.InsertarSkuBase(
  const ACodigoArticulo, AUsuario: string);
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text :=
      'INSERT INTO fza_articulos_skus ' +
      '  (CODIGO_UNIDAD_SKU, CODIGO_ART_SKU, CODIGO_VAR_SKU, ' +
      '   ESACTIVO_SKU, INSTANTE_ALTA, USUARIO_ALTA, ' +
      '   USUARIO_MODIF) ' +
      'VALUES (:sku, :art, ''-'', ''S'', ' +
      '        CURRENT_TIMESTAMP, :usuario, :usuario)';
    Consulta.ParamByName('sku').AsString := ACodigoArticulo;
    Consulta.ParamByName('art').AsString := ACodigoArticulo;
    Consulta.ParamByName('usuario').AsString := AUsuario;
    Consulta.ExecSQL;
    EncolarArticuloPrestaShop(
      FConexion,
      ACodigoArticulo,
      AUsuario);
  finally
    FreeAndNil(Consulta);
  end;
end;

procedure TEscrituraSkuArticulosVariacionesUniDAC.ActivarSkuBase(
  const ACodigoArticulo, AUsuario: string);
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text :=
      'UPDATE fza_articulos_skus ' +
      '   SET ESACTIVO_SKU = ''S'', ' +
      '       INSTANTE_MODIF = CURRENT_TIMESTAMP, ' +
      '       USUARIO_MODIF = :usuario ' +
      ' WHERE CODIGO_UNIDAD_SKU = :sku';
    Consulta.ParamByName('sku').AsString := ACodigoArticulo;
    Consulta.ParamByName('usuario').AsString := AUsuario;
    Consulta.ExecSQL;
    EncolarArticuloPrestaShop(
      FConexion,
      ACodigoArticulo,
      AUsuario);
  finally
    FreeAndNil(Consulta);
  end;
end;

procedure TEscrituraSkuArticulosVariacionesUniDAC.
  AsegurarSkuSinVariaciones(
  const ACodigoArticulo, AUsuario: string);
var
  Accion: TAccionAsegurarSku;
  TieneVariaciones: Boolean;
  TieneSku: Boolean;
begin
  TieneVariaciones := False;
  TieneSku := False;
  if ACodigoArticulo <> '' then
  begin
    TieneVariaciones :=
      FLectura.EsArticuloConVariaciones(ACodigoArticulo);
    if not TieneVariaciones then
      TieneSku := FLectura.TieneSku(ACodigoArticulo);
  end;
  Accion := ResolverSkuSinVariaciones(
    ACodigoArticulo <> '',
    TieneVariaciones,
    TieneSku);
  if Accion = aasInsertar then
    InsertarSkuBase(ACodigoArticulo, AUsuario);
end;

procedure TEscrituraSkuArticulosVariacionesUniDAC.AsegurarSkuActivo(
  const ACodigoArticulo, AUsuario: string);
var
  Accion: TAccionAsegurarSku;
  TieneActivo: Boolean;
  TieneBase: Boolean;
begin
  TieneActivo := False;
  TieneBase := False;
  if ACodigoArticulo <> '' then
  begin
    TieneActivo := FLectura.TieneSkuActivo(ACodigoArticulo);
    if not TieneActivo then
      TieneBase := FLectura.TieneSkuBase(ACodigoArticulo);
  end;
  Accion := ResolverSkuActivo(
    ACodigoArticulo <> '',
    TieneActivo,
    TieneBase);
  case Accion of
    aasInsertar:
      InsertarSkuBase(ACodigoArticulo, AUsuario);
    aasActivar:
      ActivarSkuBase(ACodigoArticulo, AUsuario);
  end;
end;

function CrearLecturaSkuArticulosVariacionesUniDAC(
  AConexion: TUniConnection): ILecturaSkuArticulosVariaciones;
begin
  Result := TLecturaSkuArticulosVariacionesUniDAC.Create(AConexion);
end;

function CrearEscrituraSkuArticulosVariacionesUniDAC(
  AConexion: TUniConnection;
  const ALectura: ILecturaSkuArticulosVariaciones):
  IEscrituraSkuArticulosVariaciones;
begin
  Result := TEscrituraSkuArticulosVariacionesUniDAC.Create(
    AConexion, ALectura);
end;

end.
