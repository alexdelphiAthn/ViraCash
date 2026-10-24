{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataColumnasDocumentoRepositorio                          }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Adaptador UniDAC de nombres de atributos globales de documentos.          }
{******************************************************************************}
unit UniDataColumnasDocumentoRepositorio;

interface

uses
  Uni, inLibColumnasDocumentoLecturasIntf;

function CrearColumnasDocumentoLecturas(
  AConexion: TUniConnection): IColumnasDocumentoLecturas;
// Rótulo de una columna por eje F (fila) o P (pivote)
// cuando la rejilla mezcla artículos de variaciones distintas: los
// nombres que dan a ese atributo las variaciones activas, unidos («Color
// / Aroma»). Sin conexión o sin nombres, ADefecto (FZ-ISSUE-439).
function RotuloGlobalEje(AConexion: TUniConnection;
  const AEje, ADefecto: string): string;
// Nombre del eje F o P de la variación de un artículo concreto
// («Aroma» para la fila de «Aroma y medida»). ADefecto si el
// artículo no tiene variación o esta no lleva ese atributo.
function RotuloEjeArticulo(AConexion: TUniConnection;
  const ACodigoArticulo, AEje, ADefecto: string): string;

implementation

uses
  System.SysUtils, inLibVariacionesRotulos;

const
  MAXIMO_ATRIBUTOS_GLOBALES = 5;

// FZ-ISSUE-436: el nombre de cada atributo con su posición dentro de su
// variación (por orden y código), primero las variaciones de menor orden.
// Antes se agrupaba solo por nombre y dos variaciones con los mismos
// códigos de atributo (Color/Talla y Aroma/Medida) daban «Aroma» y
// «Color» como primer y segundo eje.
function SqlNombresAtributosGlobales: string;
begin
  Result :=
    'SELECT COALESCE(NULLIF(VA.NOMBRE_VA, ''''), VA.ID_ATB_VA) AS NOMBRE,' +
    '       (SELECT COUNT(*) FROM fza_variaciones_atributos X' +
    '         WHERE X.ID_VAR_VA = VA.ID_VAR_VA' +
    '           AND (COALESCE(X.ORDEN_VA, 0) < COALESCE(VA.ORDEN_VA, 0)' +
    '            OR (COALESCE(X.ORDEN_VA, 0) = COALESCE(VA.ORDEN_VA, 0)' +
    '                AND X.ID_ATB_VA < VA.ID_ATB_VA))) + 1 AS POSICION' +
    '  FROM fza_variaciones_atributos VA' +
    '  LEFT JOIN fza_variaciones V ON V.CODIGO_VAR = VA.ID_VAR_VA' +
    ' WHERE COALESCE(V.ESACTIVO_VAR, ''S'') <> ''N''' +
    ' ORDER BY POSICION, COALESCE(V.ORDEN_VAR, 0), VA.ID_VAR_VA';
end;

function RotuloGlobalEje(AConexion: TUniConnection;
  const AEje, ADefecto: string): string;
var
  aNombres: TArray<string>;
  aPosiciones: TArray<Integer>;
  aRotulos: TArray<string>;
  oConsulta: TUniQuery;
begin
  Result := ADefecto;
  if Assigned(AConexion) and AConexion.Connected then
  begin
    aNombres := [];
    aPosiciones := [];
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      oConsulta.SQL.Text :=
        'SELECT COALESCE(NULLIF(VA.NOMBRE_VA, ''''), VA.ID_ATB_VA) ' +
        '       AS NOMBRE' +
        '  FROM fza_variaciones_atributos VA' +
        '  LEFT JOIN fza_variaciones V ON V.CODIGO_VAR = VA.ID_VAR_VA' +
        '  JOIN VI_VARIACIONES_EJES EJ' +
        '    ON EJ.ID_VAR_VA = VA.ID_VAR_VA' +
        '   AND EJ.ID_ATB_VA = VA.ID_ATB_VA' +
        ' WHERE EJ.EJE_VA = :atributo' +
        '   AND COALESCE(V.ESACTIVO_VAR, ''S'') <> ''N''' +
        ' ORDER BY COALESCE(V.ORDEN_VAR, 0), VA.ID_VAR_VA';
      oConsulta.ParamByName('atributo').AsString := AEje;
      oConsulta.Open;
      while not oConsulta.Eof do
      begin
        aNombres := aNombres + [oConsulta.FieldByName('NOMBRE').AsString];
        aPosiciones := aPosiciones + [1];
        oConsulta.Next;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
    aRotulos := ComponerRotulosEjesGlobales(aPosiciones, aNombres, 1);
    if (Length(aRotulos) > 0) and (aRotulos[0] <> '') then
      Result := aRotulos[0];
  end;
end;

function RotuloEjeArticulo(AConexion: TUniConnection;
  const ACodigoArticulo, AEje, ADefecto: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := ADefecto;
  if Assigned(AConexion) and AConexion.Connected and
     (Trim(ACodigoArticulo) <> '') then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      oConsulta.SQL.Text :=
        'SELECT COALESCE(NULLIF(VA.NOMBRE_VA, ''''), VA.ID_ATB_VA) ' +
        '       AS NOMBRE' +
        '  FROM fza_articulos A' +
        '  JOIN fza_variaciones_atributos VA' +
        '    ON VA.ID_VAR_VA = A.TIPO_VARIACION_ART' +
        ' WHERE A.CODIGO_ART_ART = :articulo' +
        '   AND EXISTS (SELECT 1 FROM VI_VARIACIONES_EJES EJ' +
        '     WHERE EJ.ID_VAR_VA = VA.ID_VAR_VA' +
        '       AND EJ.ID_ATB_VA = VA.ID_ATB_VA' +
        '       AND EJ.EJE_VA = :atributo)' +
        ' LIMIT 1';
      oConsulta.ParamByName('articulo').AsString := ACodigoArticulo;
      oConsulta.ParamByName('atributo').AsString := AEje;
      oConsulta.Open;
      if (not oConsulta.Eof) and
         (Trim(oConsulta.FieldByName('NOMBRE').AsString) <> '') then
        Result := Trim(oConsulta.FieldByName('NOMBRE').AsString);
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

type
  TColumnasDocumentoLecturas = class(
    TInterfacedObject,
    IColumnasDocumentoLecturas)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function ListarNombresAtributosGlobales: TArray<string>;
  end;

function CrearColumnasDocumentoLecturas(
  AConexion: TUniConnection): IColumnasDocumentoLecturas;
begin
  Result := TColumnasDocumentoLecturas.Create(AConexion);
end;

constructor TColumnasDocumentoLecturas.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TColumnasDocumentoLecturas.
  ListarNombresAtributosGlobales: TArray<string>;
var
  aNombres: TArray<string>;
  aPosiciones: TArray<Integer>;
  oConsulta: TUniQuery;
begin
  aNombres := [];
  aPosiciones := [];
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SqlNombresAtributosGlobales;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      aNombres := aNombres + [oConsulta.FieldByName('NOMBRE').AsString];
      aPosiciones := aPosiciones +
        [oConsulta.FieldByName('POSICION').AsInteger];
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
  Result := ComponerRotulosEjesGlobales(aPosiciones, aNombres,
    MAXIMO_ATRIBUTOS_GLOBALES);
end;

end.
