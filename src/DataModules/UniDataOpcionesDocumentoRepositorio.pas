{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataOpcionesDocumentoRepositorio                           }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Datos maestros del diálogo común de creación de documentos: empresas,     }
{    almacenes activos de una empresa, series de una empresa y tipo            }
{    (Empresas > Series vigentes más contadores activos), serie propia de      }
{    un almacén y formas de pago activas.                                      }
{******************************************************************************}
unit UniDataOpcionesDocumentoRepositorio;

interface

uses
  Uni, inLibOpcionesDocumentoIntf;

function CrearLectorOpcionesDocumentoUniDAC(
  AConexion: TUniConnection): ILectorOpcionesDocumento;

implementation

uses
  System.SysUtils, System.Generics.Collections, Data.DB;

const
  SQL_LISTAR_EMPRESAS =
    'SELECT CODIGO_EMP_EMP AS CODIGO, ' +
    '       RAZON_SOCIAL_EMP AS NOMBRE ' +
    '  FROM fza_empresas ' +
    ' WHERE IFNULL(ESACTIVO_EMP, ''S'') = ''S'' ' +
    ' ORDER BY ORDEN_EMP, CODIGO_EMP_EMP';
  SQL_ORDEN_ALMACENES =
    ' ORDER BY ORDEN_ALM IS NULL, ORDEN_ALM, CODIGO_ALM_ALM ';
  SQL_LISTAR_ALMACENES =
    'SELECT CODIGO_ALM_ALM AS CODIGO, ' +
    '       NOMBRE_ALM_ALM AS NOMBRE ' +
    '  FROM fza_almacenes ' +
    ' WHERE CODIGO_EMP_ALM = :EMP ' +
    '   AND IFNULL(ESACTIVO_ALM, ''S'') = ''S'' ' +
    SQL_ORDEN_ALMACENES;
  SQL_LISTAR_FORMAS_PAGO =
    'SELECT CODIGO_FP_FP AS CODIGO, ' +
    '       DESCRIPCION_FORMA_PAGO_FP AS NOMBRE ' +
    '  FROM fza_formas_pago ' +
    ' WHERE IFNULL(ESACTIVO_FORMA_PAGO_FP, ''S'') = ''S'' ' +
    ' ORDER BY ORDEN_FORMA_PAGO_FP, CODIGO_FP_FP';
  SQL_VIGENCIA_SERIE =
    '   AND (FECHA_DESDE_EMPSER IS NULL ' +
    '        OR FECHA_DESDE_EMPSER <= CURDATE()) ' +
    '   AND (FECHA_HASTA_EMPSER IS NULL ' +
    '        OR FECHA_HASTA_EMPSER >= CURDATE()) ';
  // Sin subtipo pedido valen las series normales y las que no lo indican.
  SQL_SUBTIPO_SERIE =
    '   AND ((:SUB = '''' ' +
    '         AND IFNULL(SUBTIPO_EMPSER, '''') IN ('''', ''NORMAL'')) ' +
    '        OR SUBTIPO_EMPSER = :SUB) ';
  // Los contadores no tienen subtipo: con un subtipo pedido (p. ej.
  // RECTIFICATIVA) van detrás de las series de ese subtipo. Orden: contador
  // por defecto, series generales de la empresa y después las propias de
  // almacén. Una serie marcada como no por defecto en todos sus ámbitos va
  // al final (el contador no opina: SECUNDARIA nula). El contador genérico
  // '-' (sin serie) va el último: el diálogo propone el primero de la lista
  // y creaba albaranes y facturas de compra con serie '-' aunque la empresa
  // tuviera series propias (FZ-ISSUE-209).
  SQL_LISTAR_SERIES =
    'SELECT SERIES.SERIE, MIN(SERIES.ORDEN) AS ORDEN ' +
    '  FROM (SELECT SERIE_CON AS SERIE, ' +
    '               CASE WHEN SERIE_CON = ''-'' THEN 5 ' +
    '                    WHEN :SUB <> '''' THEN 4 ' +
    '                    WHEN DEFAULT_CON = ''S'' THEN 0 ELSE 2 END ' +
    '                 AS ORDEN, ' +
    '               NULL AS SECUNDARIA ' +
    '          FROM fza_contadores ' +
    '         WHERE TIPO_DOC_CON = :TIP ' +
    '           AND ESACTIVO_CON = ''S'' ' +
    '           AND EMPRESA_CON IN (:EMP, ''-'') ' +
    '         UNION ALL ' +
    '        SELECT EMPSER AS SERIE, ' +
    '               CASE WHEN IFNULL(CODIGO_ALM_EMPSER, '''') = '''' ' +
    '                    THEN 1 ELSE 3 END AS ORDEN, ' +
    '               CASE WHEN ESDEFECTO_EMPSER = ''N'' THEN 1 ELSE 0 END ' +
    '                 AS SECUNDARIA ' +
    '          FROM vi_empresas_series ' +
    '         WHERE CODIGO_EMP_EMPSER = :EMP ' +
    '           AND TIPO_DOC_EMPSER = :TIP ' +
    SQL_SUBTIPO_SERIE +
    SQL_VIGENCIA_SERIE +
    '       ) SERIES ' +
    ' WHERE IFNULL(SERIES.SERIE, '''') <> '''' ' +
    ' GROUP BY SERIES.SERIE ' +
    ' ORDER BY IFNULL(MIN(SERIES.SECUNDARIA), 0), ORDEN, SERIES.SERIE';
  // La factura normal usa primero la serie general de su empresa.
  SQL_SERIE_GENERAL_FACTURA =
    'SELECT EMPSER FROM vi_empresas_series ' +
    ' WHERE CODIGO_EMP_EMPSER = :EMP ' +
    '   AND TIPO_DOC_EMPSER = ''FC'' ' +
    '   AND SUBTIPO_EMPSER = ''NORMAL'' ' +
    '   AND IFNULL(CODIGO_ALM_EMPSER, '''') = '''' ' +
    SQL_VIGENCIA_SERIE +
    '   AND IFNULL(EMPSER, '''') <> '''' ' +
    ' ORDER BY ESDEFECTO_EMPSER DESC, EMPSER LIMIT 1';
  SQL_OBTENER_SERIE_ALMACEN =
    'SELECT EMPSER ' +
    '  FROM vi_empresas_series ' +
    ' WHERE CODIGO_EMP_EMPSER = :EMP ' +
    '   AND TIPO_DOC_EMPSER = :TIP ' +
    '   AND CODIGO_ALM_EMPSER = :ALM ' +
    SQL_SUBTIPO_SERIE +
    SQL_VIGENCIA_SERIE +
    ' ORDER BY ESDEFECTO_EMPSER DESC, EMPSER ' +
    ' LIMIT 1';

type
  TLectorOpcionesDocumentoUniDAC = class(
    TInterfacedObject,
    ILectorOpcionesDocumento)
  private
    FConexion: TUniConnection;
    function CrearConsulta(const ASql: string): TUniQuery;
    function LeerElementos(
      AConsulta: TUniQuery): TElementosOpcionesDocumento;
  public
    constructor Create(AConexion: TUniConnection);
    function ListarEmpresas: TElementosOpcionesDocumento;
    function ListarAlmacenes(
      const AEmpresa: string): TElementosOpcionesDocumento;
    function PrimerAlmacenEstandar(
      const AEmpresa: string): string;
    function ListarSeries(const AEmpresa, ATipo,
      ASubtipo: string): TArray<string>;
    function ObtenerSerieGeneralFactura(const AEmpresa: string): string;
    function ObtenerSerieAlmacen(const AEmpresa, ATipo, ASubtipo,
      AAlmacen: string): string;
    function ListarFormasPago: TElementosOpcionesDocumento;
  end;

function CrearLectorOpcionesDocumentoUniDAC(
  AConexion: TUniConnection): ILectorOpcionesDocumento;
begin
  Result := TLectorOpcionesDocumentoUniDAC.Create(AConexion);
end;

constructor TLectorOpcionesDocumentoUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TLectorOpcionesDocumentoUniDAC.CrearConsulta(
  const ASql: string): TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
  Result.SQL.Text := ASql;
end;

function TLectorOpcionesDocumentoUniDAC.LeerElementos(
  AConsulta: TUniQuery): TElementosOpcionesDocumento;
var
  oElemento: TElementoOpcionesDocumento;
  oElementos: TList<TElementoOpcionesDocumento>;
begin
  oElementos := TList<TElementoOpcionesDocumento>.Create;
  try
    AConsulta.Open;
    while not AConsulta.Eof do
    begin
      oElemento.Codigo := AConsulta.FieldByName('CODIGO').AsString;
      oElemento.Nombre := AConsulta.FieldByName('NOMBRE').AsString;
      oElementos.Add(oElemento);
      AConsulta.Next;
    end;
    Result := oElementos.ToArray;
  finally
    FreeAndNil(oElementos);
  end;
end;

function TLectorOpcionesDocumentoUniDAC.ListarEmpresas:
  TElementosOpcionesDocumento;
var
  oConsulta: TUniQuery;
begin
  oConsulta := CrearConsulta(SQL_LISTAR_EMPRESAS);
  try
    Result := LeerElementos(oConsulta);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TLectorOpcionesDocumentoUniDAC.ListarAlmacenes(
  const AEmpresa: string): TElementosOpcionesDocumento;
var
  oConsulta: TUniQuery;
begin
  oConsulta := CrearConsulta(SQL_LISTAR_ALMACENES);
  try
    oConsulta.ParamByName('EMP').AsString := AEmpresa;
    Result := LeerElementos(oConsulta);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TLectorOpcionesDocumentoUniDAC.PrimerAlmacenEstandar(
  const AEmpresa: string): string;
var
  oConsulta: TUniQuery;
begin
  oConsulta := CrearConsulta(
    'SELECT CODIGO_ALM_ALM FROM fza_almacenes ' +
    'WHERE CODIGO_EMP_ALM = :EMP ' +
    'AND IFNULL(ESACTIVO_ALM, ''S'') = ''S'' ' +
    'AND UPPER(TRIM(TIPO_USO_ALM)) IN (''ESTANDAR'', ''ESTANDARD'') ' +
    SQL_ORDEN_ALMACENES + 'LIMIT 1');
  try
    oConsulta.ParamByName('EMP').AsString := AEmpresa;
    oConsulta.Open;
    Result := '';
    if not oConsulta.IsEmpty then
      Result := oConsulta.FieldByName('CODIGO_ALM_ALM').AsString;
  finally
    oConsulta.Free;
  end;
end;

function TLectorOpcionesDocumentoUniDAC.ListarSeries(const AEmpresa,
  ATipo, ASubtipo: string): TArray<string>;
var
  oConsulta: TUniQuery;
  oSeries: TList<string>;
begin
  oSeries := TList<string>.Create;
  try
    oConsulta := CrearConsulta(SQL_LISTAR_SERIES);
    try
      oConsulta.ParamByName('EMP').AsString := AEmpresa;
      oConsulta.ParamByName('TIP').AsString := ATipo;
      oConsulta.ParamByName('SUB').AsString := ASubtipo;
      oConsulta.Open;
      while not oConsulta.Eof do
      begin
        oSeries.Add(oConsulta.FieldByName('SERIE').AsString);
        oConsulta.Next;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
    Result := oSeries.ToArray;
  finally
    FreeAndNil(oSeries);
  end;
end;

function TLectorOpcionesDocumentoUniDAC.ObtenerSerieGeneralFactura(
  const AEmpresa: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  oConsulta := CrearConsulta(SQL_SERIE_GENERAL_FACTURA);
  try
    oConsulta.ParamByName('EMP').AsString := AEmpresa;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      Result := oConsulta.FieldByName('EMPSER').AsString;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TLectorOpcionesDocumentoUniDAC.ObtenerSerieAlmacen(
  const AEmpresa, ATipo, ASubtipo, AAlmacen: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  if Trim(AAlmacen) <> '' then
  begin
    oConsulta := CrearConsulta(SQL_OBTENER_SERIE_ALMACEN);
    try
      oConsulta.ParamByName('EMP').AsString := AEmpresa;
      oConsulta.ParamByName('TIP').AsString := ATipo;
      oConsulta.ParamByName('SUB').AsString := ASubtipo;
      oConsulta.ParamByName('ALM').AsString := AAlmacen;
      oConsulta.Open;
      if not oConsulta.IsEmpty then
        Result := oConsulta.FieldByName('EMPSER').AsString;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TLectorOpcionesDocumentoUniDAC.ListarFormasPago:
  TElementosOpcionesDocumento;
var
  oConsulta: TUniQuery;
begin
  oConsulta := CrearConsulta(SQL_LISTAR_FORMAS_PAGO);
  try
    Result := LeerElementos(oConsulta);
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.
