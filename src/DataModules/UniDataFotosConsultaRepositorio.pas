{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataFotosConsultaRepositorio                              }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Lectura UniDAC de metadatos de fotografías de artículos y SKU.            }
{******************************************************************************}
unit UniDataFotosConsultaRepositorio;

interface

uses
  Uni, inLibFotosPersistenciaIntf;

function CrearRepositorioConsultaFotosUniDAC(
  AConexion: TUniConnection): IRepositorioConsultaFotos;

implementation

uses
  System.SysUtils;

const
  fcodartfot = 'CODIGO_ART_FOT';
  fcodunidadfot = 'CODIGO_UNIDAD_FOT';
  fordenfot = 'ORDEN_FOT';
  fnomfot = 'NOMBRE_FOT_FOT';
  fextfot = 'EXTENSION_ORIGEN_FOT';

type
  TRepositorioConsultaFotosUniDAC = class(
    TInterfacedObject,
    IRepositorioConsultaFotos)
  private
    FConexion: TUniConnection;
    function NuevaConsulta: TUniQuery;
  public
    constructor Create(AConexion: TUniConnection);
    function BuscarFotoPorUnidades(
      const ACodigoArticulo: string;
      const AUnidades: TArray<string>;
      out AMetadatos: TMetadatosFotoPersistida): Boolean;
    function BuscarFotoArticulo(
      const ACodigoArticulo: string;
      out AMetadatos: TMetadatosFotoPersistida): Boolean;
    function BuscarPrimeraFotoUnidad(
      const ACodigoArticulo: string;
      out AMetadatos: TMetadatosFotoPersistida): Boolean;
    function BuscarFotosArticulos(
      const ACodigosArticulo: TArray<string>):
      TArray<TMetadatosFotoPersistida>;
    function BuscarFotosColeccion(
      const ACodigoArticulo, ACodigoUnidad: string):
      TArray<TMetadatosFotoPersistida>;
    function BuscarFotosVariaciones(
      const ACodigoArticulo: string):
      TArray<TMetadatosFotoPersistida>;
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

constructor TRepositorioConsultaFotosUniDAC.Create(
  AConexion: TUniConnection);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioConsultaFotosUniDAC.NuevaConsulta: TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

function TRepositorioConsultaFotosUniDAC.BuscarFotoPorUnidades(
  const ACodigoArticulo: string;
  const AUnidades: TArray<string>;
  out AMetadatos: TMetadatosFotoPersistida): Boolean;
var
  oConsulta: TUniQuery;
  iUnidad: Integer;
  sParametros: string;
begin
  Result := False;
  AMetadatos := Default(TMetadatosFotoPersistida);
  if Length(AUnidades) > 0 then
  begin
    oConsulta := NuevaConsulta;
    try
      sParametros := '';
      for iUnidad := 0 to High(AUnidades) do
      begin
        if sParametros <> '' then
          sParametros := sParametros + ', ';
        sParametros := sParametros + ':P' + IntToStr(iUnidad);
      end;
      oConsulta.SQL.Text :=
        ' SELECT CODIGO_ART_FOT, CODIGO_UNIDAD_FOT, ORDEN_FOT, ' +
        '        NOMBRE_FOT_FOT, EXTENSION_ORIGEN_FOT ' +
        '   FROM fza_articulos_fotos ' +
        '  WHERE CODIGO_ART_FOT    = :CODIGO_ART ' +
        '    AND CODIGO_UNIDAD_FOT IN (' + sParametros + ') ' +
        '    AND ORDEN_FOT = 1 ' +
        '  ORDER BY LENGTH(CODIGO_UNIDAD_FOT) DESC, ' +
        '           CODIGO_UNIDAD_FOT DESC, NOMBRE_FOT_FOT ' +
        '  LIMIT 1';
      oConsulta.ParamByName('CODIGO_ART').AsString :=
        ACodigoArticulo;
      for iUnidad := 0 to High(AUnidades) do
        oConsulta.ParamByName('P' + IntToStr(iUnidad)).AsString :=
          AUnidades[iUnidad];
      oConsulta.Open;
      Result := not oConsulta.Eof;
      if Result then
        AMetadatos := LeerMetadatosFoto(oConsulta);
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TRepositorioConsultaFotosUniDAC.BuscarFotoArticulo(
  const ACodigoArticulo: string;
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
      '    AND CODIGO_UNIDAD_FOT = '''' ' +
      '    AND ORDEN_FOT = 1 ' +
      '  ORDER BY NOMBRE_FOT_FOT ' +
      '  LIMIT 1';
    oConsulta.ParamByName('CODIGO_ART').AsString :=
      ACodigoArticulo;
    oConsulta.Open;
    Result := not oConsulta.Eof;
    if Result then
      AMetadatos := LeerMetadatosFoto(oConsulta);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioConsultaFotosUniDAC.BuscarPrimeraFotoUnidad(
  const ACodigoArticulo: string;
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
      '  WHERE CODIGO_ART_FOT = :CODIGO_ART ' +
      '    AND CODIGO_UNIDAD_FOT <> '''' ' +
      '    AND ORDEN_FOT = 1 ' +
      '  ORDER BY CODIGO_UNIDAD_FOT, NOMBRE_FOT_FOT ' +
      '  LIMIT 1';
    oConsulta.ParamByName('CODIGO_ART').AsString :=
      ACodigoArticulo;
    oConsulta.Open;
    Result := not oConsulta.Eof;
    if Result then
      AMetadatos := LeerMetadatosFoto(oConsulta);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioConsultaFotosUniDAC.BuscarFotosArticulos(
  const ACodigosArticulo: TArray<string>):
  TArray<TMetadatosFotoPersistida>;
var
  oConsulta: TUniQuery;
  iArticulo: Integer;
  iFoto: Integer;
  sParametros: string;
begin
  SetLength(Result, 0);
  if Length(ACodigosArticulo) > 0 then
  begin
    oConsulta := NuevaConsulta;
    try
      sParametros := '';
      for iArticulo := 0 to High(ACodigosArticulo) do
      begin
        if sParametros <> '' then
          sParametros := sParametros + ', ';
        sParametros := sParametros + ':A' + IntToStr(iArticulo);
      end;
      oConsulta.SQL.Text :=
        ' SELECT CODIGO_ART_FOT, CODIGO_UNIDAD_FOT, ORDEN_FOT, ' +
        '        NOMBRE_FOT_FOT, EXTENSION_ORIGEN_FOT ' +
        '   FROM fza_articulos_fotos ' +
        '  WHERE CODIGO_ART_FOT IN (' + sParametros + ') ' +
        '    AND ORDEN_FOT = 1 ' +
        '  ORDER BY CODIGO_ART_FOT, CODIGO_UNIDAD_FOT, ' +
        '           ORDEN_FOT, NOMBRE_FOT_FOT';
      for iArticulo := 0 to High(ACodigosArticulo) do
        oConsulta.ParamByName('A' + IntToStr(iArticulo)).AsString :=
          ACodigosArticulo[iArticulo];
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
end;

function TRepositorioConsultaFotosUniDAC.BuscarFotosColeccion(
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

function TRepositorioConsultaFotosUniDAC.BuscarFotosVariaciones(
  const ACodigoArticulo: string):
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
      '  WHERE CODIGO_ART_FOT = :CODIGO_ART ' +
      '    AND CODIGO_UNIDAD_FOT <> '''' ' +
      '  ORDER BY CODIGO_UNIDAD_FOT, ORDEN_FOT, NOMBRE_FOT_FOT';
    oConsulta.ParamByName('CODIGO_ART').AsString :=
      ACodigoArticulo;
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

function CrearRepositorioConsultaFotosUniDAC(
  AConexion: TUniConnection): IRepositorioConsultaFotos;
begin
  Result := TRepositorioConsultaFotosUniDAC.Create(AConexion);
end;

end.
