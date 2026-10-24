{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataRetiradaLotesLecturas                                  }
{    Tipo:       Persistencia                                                  }
{ Versión:       1.0.0                                                         }
{   Fecha:       13/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:  Lectura de existencias y almacenes de retirada.               }
{******************************************************************************}
unit UniDataRetiradaLotesLecturas;

interface

uses
  Uni, inLibRetiradaLotesIntf;

type
  TLecturasRetiradaLotes = class
  private
    FConexion: TUniConnection;
    function SqlStock: string;
    function FamiliaRaiz(const ACodigo: string): string;
  public
    constructor Create(AConexion: TUniConnection);
    function Consulta(const ASql: string): TUniQuery;
    function LeerFila(AConsulta: TUniQuery): TLineaRetiradaLote;
    procedure Completar(const AEmpresa: string;
      var ALinea: TLineaRetiradaLote; out ACoste: Double);
    procedure ValidarAlmacen(const AEmpresa, AAlmacen: string;
      AExigirTaras: Boolean);
    function AlmacenesTaras(const AEmpresa: string):
      TArray<TAlmacenRetiradaLotes>;
    function Urgentes(const AOrden: TOrdenRetiradaLotes):
      TArray<TLineaRetiradaLote>;
  end;

implementation

uses
  System.SysUtils, System.Classes, Data.DB, inLibMsgRetiradaLotes;

constructor TLecturasRetiradaLotes.Create(AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TLecturasRetiradaLotes.Consulta(const ASql: string): TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
  Result.SQL.Text := ASql;
end;

function TLecturasRetiradaLotes.SqlStock: string;
begin
  Result :=
    'SELECT S.CODIGO_UNIDAD_STK, S.CODIGO_ALM_STK, S.LOTE_STK, ' +
    'S.CANTIDAD_STK, S.PRECIO_MEDIO_STK, K.CODIGO_ART_SKU, ' +
    'A.DESCRIPCION_ART, A.CODIGO_FAM_ART, ' +
    'COALESCE(L.FECHA_CADUCIDAD_LOT, ' +
    'S.FECHA_CADUCIDAD_STK) AS FECHA_CADUCIDAD, ' +
    'COALESCE(NULLIF(TRIM(P.VALOR_PV), ''''), ' +
    'NULLIF(TRIM(P.VALOR_LIBRE_ARTPROP), ''''), ' +
    ''' '') AS UBICACION ' +
    'FROM fza_articulos_stockactual S JOIN fza_almacenes M ' +
    'ON M.CODIGO_ALM_ALM = S.CODIGO_ALM_STK ' +
    'JOIN fza_articulos_skus K ' +
    'ON K.CODIGO_UNIDAD_SKU = S.CODIGO_UNIDAD_STK ' +
    'JOIN fza_articulos A ON A.CODIGO_ART_ART = K.CODIGO_ART_SKU ' +
    'LEFT JOIN fza_articulos_lotes L ' +
    'ON L.CODIGO_UNIDAD_LOT = S.CODIGO_UNIDAD_STK ' +
    'AND L.LOTE_LOT = S.LOTE_STK ' +
    'LEFT JOIN vi_articulos_propiedades_efectivas P ' +
    'ON P.CODIGO_ART = K.CODIGO_ART_SKU ' +
    'AND P.CODIGO_UNIDAD_SKU = K.CODIGO_UNIDAD_SKU ' +
    'AND P.CODIGO_PROP_ARTPROP = ''UBICACION'' ' +
    'WHERE M.CODIGO_EMP_ALM = :EMP AND M.ESACTIVO_ALM = ''S'' ';
end;

function TLecturasRetiradaLotes.LeerFila(AConsulta: TUniQuery):
  TLineaRetiradaLote;
begin
  Result := Default(TLineaRetiradaLote);
  Result.CodigoSku := AConsulta.FieldByName('CODIGO_UNIDAD_STK').AsString;
  Result.CodigoAlmacen := AConsulta.FieldByName('CODIGO_ALM_STK').AsString;
  Result.Lote := AConsulta.FieldByName('LOTE_STK').AsString;
  Result.CodigoArticulo := AConsulta.FieldByName('CODIGO_ART_SKU').AsString;
  Result.Descripcion := AConsulta.FieldByName('DESCRIPCION_ART').AsString;
  Result.Cantidad := AConsulta.FieldByName('CANTIDAD_STK').AsFloat;
  Result.FechaCaducidad :=
    AConsulta.FieldByName('FECHA_CADUCIDAD').AsDateTime;
  Result.Ubicacion := Trim(AConsulta.FieldByName('UBICACION').AsString);
  if Result.Ubicacion = '' then
    Result.Ubicacion := FamiliaRaiz(
      AConsulta.FieldByName('CODIGO_FAM_ART').AsString);
end;

function TLecturasRetiradaLotes.FamiliaRaiz(const ACodigo: string): string;
var
  Datos: TUniQuery;
  Codigo, Visitadas, Padre: string;
  Nivel: Integer;
begin
  Result := 'Entrada';
  Codigo := ACodigo;
  Visitadas := '|';
  Datos := Consulta('SELECT NOMBRE_FAM_FAM, COALESCE(' +
    'NULLIF(CODIGO_PADRE_FAM, ''''), CODIGO_SUBFAMILIA_FAM) AS PADRE ' +
    'FROM fza_articulos_familias WHERE CODIGO_FAM_FAM = :FAM');
  try
    Nivel := 0;
    while (Codigo <> '') and (Nivel < 20) and
          (Pos('|' + UpperCase(Codigo) + '|', Visitadas) = 0) do
    begin
      Visitadas := Visitadas + UpperCase(Codigo) + '|';
      Datos.Close;
      Datos.ParamByName('FAM').AsString := Codigo;
      Datos.Open;
      Padre := '';
      if not Datos.IsEmpty then
      begin
        if Trim(Datos.FieldByName('NOMBRE_FAM_FAM').AsString) <> '' then
          Result := Datos.FieldByName('NOMBRE_FAM_FAM').AsString;
        Padre := Trim(Datos.FieldByName('PADRE').AsString);
      end;
      Codigo := Padre;
      Inc(Nivel);
    end;
  finally
    Datos.Free;
  end;
end;

procedure TLecturasRetiradaLotes.Completar(const AEmpresa: string;
  var ALinea: TLineaRetiradaLote; out ACoste: Double);
var
  ConsultaStock: TUniQuery;
  Cantidad: Double;
begin
  Cantidad := ALinea.Cantidad;
  ConsultaStock := Consulta(SqlStock +
    'AND S.CODIGO_ALM_STK = :ALM AND S.CODIGO_UNIDAD_STK = :SKU ' +
    'AND S.LOTE_STK = :LOTE FOR UPDATE');
  try
    ConsultaStock.ParamByName('EMP').AsString := AEmpresa;
    ConsultaStock.ParamByName('ALM').AsString := ALinea.CodigoAlmacen;
    ConsultaStock.ParamByName('SKU').AsString := ALinea.CodigoSku;
    ConsultaStock.ParamByName('LOTE').AsString := ALinea.Lote;
    ConsultaStock.Open;
    if ConsultaStock.IsEmpty or
       (Cantidad > ConsultaStock.FieldByName('CANTIDAD_STK').AsFloat) then
      raise Exception.CreateFmt(SErrorRetiradaStock,
        [ALinea.CodigoSku, ALinea.Lote]);
    ACoste := ConsultaStock.FieldByName('PRECIO_MEDIO_STK').AsFloat;
    ALinea := LeerFila(ConsultaStock);
    ALinea.Cantidad := Cantidad;
  finally
    ConsultaStock.Free;
  end;
end;

procedure TLecturasRetiradaLotes.ValidarAlmacen(const AEmpresa,
  AAlmacen: string; AExigirTaras: Boolean);
var
  Datos: TUniQuery;
begin
  Datos := Consulta('SELECT TIPO_USO_ALM FROM fza_almacenes ' +
    'WHERE CODIGO_EMP_ALM = :EMP AND CODIGO_ALM_ALM = :ALM ' +
    'AND ESACTIVO_ALM = ''S''');
  try
    Datos.ParamByName('EMP').AsString := AEmpresa;
    Datos.ParamByName('ALM').AsString := AAlmacen;
    Datos.Open;
    if Datos.IsEmpty then
      raise Exception.Create(SErrorRetiradaAlmacen);
    if AExigirTaras and
       (Datos.FieldByName('TIPO_USO_ALM').AsString <> 'TARAS') then
      raise Exception.Create(SErrorRetiradaDestino);
  finally
    Datos.Free;
  end;
end;

function TLecturasRetiradaLotes.AlmacenesTaras(const AEmpresa: string):
  TArray<TAlmacenRetiradaLotes>;
var
  Datos: TUniQuery;
  Almacen: TAlmacenRetiradaLotes;
begin
  Result := [];
  Datos := Consulta('SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM ' +
    'FROM fza_almacenes WHERE CODIGO_EMP_ALM = :EMP ' +
    'AND ESACTIVO_ALM = ''S'' AND TIPO_USO_ALM = ''TARAS'' ' +
    'ORDER BY CODIGO_ALM_ALM');
  try
    Datos.ParamByName('EMP').AsString := AEmpresa;
    Datos.Open;
    while not Datos.Eof do
    begin
      Almacen.Codigo := Datos.FieldByName('CODIGO_ALM_ALM').AsString;
      Almacen.Nombre := Datos.FieldByName('NOMBRE_ALM_ALM').AsString;
      Result := Result + [Almacen];
      Datos.Next;
    end;
  finally
    Datos.Free;
  end;
end;

function TLecturasRetiradaLotes.Urgentes(const AOrden: TOrdenRetiradaLotes):
  TArray<TLineaRetiradaLote>;
var
  Datos: TUniQuery;
begin
  Result := [];
  Datos := Consulta(SqlStock + 'AND S.CANTIDAD_STK > 0 ' +
    'AND TRIM(S.LOTE_STK) <> '''' ' +
    'AND COALESCE(L.FECHA_CADUCIDAD_LOT, S.FECHA_CADUCIDAD_STK) <= :HOY ' +
    'AND EXISTS (SELECT 1 FROM fza_lotes_retiradas R ' +
    'WHERE R.ID_LRET = :ID AND R.ESADICIONAL_LRET = ''N'' ' +
    'AND R.CODIGO_ALM_LRET = S.CODIGO_ALM_STK) ' +
    'AND NOT EXISTS (SELECT 1 FROM fza_lotes_retiradas R ' +
    'WHERE R.ID_LRET = :ID AND R.ESADICIONAL_LRET = ''N'' ' +
    'AND R.CODIGO_ALM_LRET = S.CODIGO_ALM_STK ' +
    'AND R.CODIGO_UNIDAD_LRET = S.CODIGO_UNIDAD_STK ' +
    'AND R.LOTE_LRET = S.LOTE_STK) ' +
    'ORDER BY FECHA_CADUCIDAD, S.CODIGO_UNIDAD_STK, S.LOTE_STK');
  try
    Datos.ParamByName('EMP').AsString := AOrden.Empresa;
    Datos.ParamByName('ID').AsString := AOrden.Id;
    Datos.ParamByName('HOY').AsDate := Trunc(AOrden.Instante);
    Datos.Open;
    while not Datos.Eof do
    begin
      Result := Result + [LeerFila(Datos)];
      Datos.Next;
    end;
  finally
    Datos.Free;
  end;
end;

end.
