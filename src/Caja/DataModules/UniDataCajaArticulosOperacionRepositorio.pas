{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataCajaArticulosOperacionRepositorio                      }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       18/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Artículos de una operación de caja leídos con UniDAC.                     }
{******************************************************************************}
unit UniDataCajaArticulosOperacionRepositorio;

interface

uses
  Uni, inLibCajaArticulosOperacionIntf;

function CrearConsultaArticulosOperacionCajaUniDAC(
  AConexion: TUniConnection): IConsultaArticulosOperacionCaja;

implementation

uses
  System.SysUtils;

type
  TConsultaArticulosOperacionCajaUniDAC = class(
    TInterfacedObject,
    IConsultaArticulosOperacionCaja)
  private
    FConexion: TUniConnection;
    function ConstruirSql(AMaximo: Integer): string;
  public
    constructor Create(AConexion: TUniConnection);
    function ListarArticulosOperacion(
      const AOperacion: TClaveOperacionCaja;
      AMaximo: Integer): TArticulosOperacionCaja;
  end;

constructor TConsultaArticulosOperacionCajaUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

// Las tres procedencias de artículo de una operación de caja, unidas en
// una sola consulta: los movimientos de almacén (venta, devolución y
// traspaso), los depósitos y préstamos, y las líneas del borrador. Las
// tres van por índice: IDX_MOV_OP_CAJA, la clave de operación de la vista
// de depósitos y la clave de fza_facturas_lineas.
function TConsultaArticulosOperacionCajaUniDAC.ConstruirSql(
  AMaximo: Integer): string;
begin
  Result :=
    'SELECT t.ART AS CODIGO_ART, ' +
    '       t.SKU AS CODIGO_UNIDAD, ' +
    '       MIN(t.ORDEN) AS ORDEN ' +
    '  FROM ( ' +
    '        SELECT m.CODIGO_ART_MOV AS ART, ' +
    '               COALESCE(m.CODIGO_UNIDAD_MOV, '''') AS SKU, ' +
    '               COALESCE(m.LINEA_MOV, 0) AS ORDEN ' +
    '          FROM fza_movimientos_almacen m ' +
    '         WHERE m.CODIGO_EMP_MOV = :PEMP ' +
    '           AND m.CODIGO_ALM_DOC_MOV = :PALM ' +
    '           AND m.CODIGO_CAJA_DOC_MOV = :PCAJA ' +
    '           AND m.NUMERO_OPERACION_DOC_MOV = :PNUMOP ' +
    '           AND COALESCE(m.CODIGO_ART_MOV, '''') <> '''' ' +
    '        UNION ALL ' +
    '        SELECT d.CODIGO_ART_DEP, ' +
    '               COALESCE(d.CODIGO_UNIDAD_DEP, ''''), ' +
    '               1000 ' +
    '          FROM fza_caja_depositos_view d ' +
    '         WHERE d.CODIGO_EMPRESA_OP = :PEMP ' +
    '           AND d.CODIGO_ALMACEN_OP = :PALM ' +
    '           AND d.CODIGO_CAJA_OP = :PCAJA ' +
    '           AND d.NUMERO_OPERACION_OP = :PNUMOP ' +
    '           AND COALESCE(d.CODIGO_ART_DEP, '''') <> '''' ' +
    '        UNION ALL ' +
    '        SELECT l.CODIGO_ART_FACLIN, ' +
    '               COALESCE(l.CODIGO_UNIDAD_FACLIN, ''''), ' +
    '               2000 + COALESCE(l.LINEA_FACLIN, 0) ' +
    '          FROM fza_facturas_lineas l ' +
    '         WHERE TRIM(COALESCE(:PSERIE, '''')) <> '''' ' +
    '           AND TRIM(COALESCE(:PNROFAC, '''')) <> '''' ' +
    '           AND l.SERIE_FAC_FACLIN = :PSERIE ' +
    '           AND l.NUMERO_FAC_FACLIN = :PNROFAC ' +
    '           AND COALESCE(l.CODIGO_ART_FACLIN, '''') <> '''' ' +
    '       ) t ' +
    ' GROUP BY t.ART, t.SKU ' +
    ' ORDER BY ORDEN, t.ART, t.SKU ' +
    ' LIMIT ' + IntToStr(AMaximo);
end;

function TConsultaArticulosOperacionCajaUniDAC.ListarArticulosOperacion(
  const AOperacion: TClaveOperacionCaja;
  AMaximo: Integer): TArticulosOperacionCaja;
var
  oConsulta: TUniQuery;
  iArticulo: Integer;
begin
  SetLength(Result, 0);
  if (FConexion <> nil) and (AOperacion.Empresa <> '') and
     (AOperacion.Operacion <> '') and (AMaximo > 0) then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text := ConstruirSql(AMaximo);
      oConsulta.ParamByName('PEMP').AsString := AOperacion.Empresa;
      oConsulta.ParamByName('PALM').AsString := AOperacion.Almacen;
      oConsulta.ParamByName('PCAJA').AsString := AOperacion.Caja;
      oConsulta.ParamByName('PNUMOP').AsString := AOperacion.Operacion;
      oConsulta.ParamByName('PSERIE').AsString := AOperacion.SerieFactura;
      oConsulta.ParamByName('PNROFAC').AsString :=
        AOperacion.NumeroFactura;
      oConsulta.Open;
      SetLength(Result, oConsulta.RecordCount);
      iArticulo := 0;
      while not oConsulta.Eof do
      begin
        Result[iArticulo].Articulo :=
          oConsulta.FieldByName('CODIGO_ART').AsString;
        Result[iArticulo].Sku :=
          oConsulta.FieldByName('CODIGO_UNIDAD').AsString;
        Inc(iArticulo);
        oConsulta.Next;
      end;
      SetLength(Result, iArticulo);
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function CrearConsultaArticulosOperacionCajaUniDAC(
  AConexion: TUniConnection): IConsultaArticulosOperacionCaja;
begin
  Result := TConsultaArticulosOperacionCajaUniDAC.Create(AConexion);
end;

end.
