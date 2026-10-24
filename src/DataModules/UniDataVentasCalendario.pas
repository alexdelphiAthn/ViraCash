{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataVentasCalendario                                       }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Implementa la lectura de operaciones de caja agrupadas por día para       }
{    el calendario de ventas (fza_caja_operaciones).                           }
{******************************************************************************}
unit UniDataVentasCalendario;

interface

uses
  Uni, inLibVentasCalendarioIntf;

function CrearRepositorioVentasCalendarioUniDAC(
  AConexion: TUniConnection): IRepositorioVentasCalendario;

implementation

uses
  System.SysUtils, UniDataRectificativasSql;

type
  TRepositorioVentasCalendarioUniDAC = class(
    TInterfacedObject,
    IRepositorioVentasCalendario)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function CargarDiasConVentas(
      const AEmpresa, AAlmacen, ACaja: string;
      AFechaInicio, AFechaFin: TDateTime): TVentasDiasResumen;
  end;

constructor TRepositorioVentasCalendarioUniDAC.Create(
  AConexion: TUniConnection);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioVentasCalendarioUniDAC.CargarDiasConVentas(
  const AEmpresa, AAlmacen, ACaja: string;
  AFechaInicio, AFechaFin: TDateTime): TVentasDiasResumen;
var
  iDia: Integer;
  Qry: TUniQuery;
begin
  SetLength(Result, 0);
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConexion;
    Qry.SQL.Text :=
      ' SELECT o.FECHA_OP_DIA_OPCAJA                AS FECHA,         ' +
      '        COUNT(*)                      AS TOTAL_VENTAS,  ' +
      '        COALESCE(SUM(CASE                               ' +
      '                       WHEN o.TIPO_OPERACION_OPCAJA = ''VE'' ' +
      '                       THEN o.IMPORTE_TOTAL_OPCAJA      ' +
      '                       ELSE 0                           ' +
      '                     END), 0)         AS TOTAL_COBRADO  ' +
      '   FROM fza_caja_operaciones o                          ' +
      '  WHERE o.FECHA_OP_DIA_OPCAJA         >= :fecha_inicio ' +
      '    AND o.FECHA_OP_DIA_OPCAJA         <  :fecha_fin    ' +
      '    AND o.CODIGO_EMP_OPCAJA = :empresa                 ' +
      '    AND o.CODIGO_ALM_OPCAJA = :almacen                 ' +
      '    AND o.CODIGO_CAJA_OPCAJA = :caja                   ' +
      SQLExcluirVentaRetirada(
        'o.CODIGO_EMP_OPCAJA',
        'o.SERIE_FAC_OPCAJA',
        'o.NUMERO_FAC_OPCAJA') +
      '  GROUP BY o.FECHA_OP_DIA_OPCAJA                       ';
    Qry.ParamByName('fecha_inicio').AsDate := AFechaInicio;
    Qry.ParamByName('fecha_fin').AsDate := AFechaFin;
    Qry.ParamByName('empresa').AsString := AEmpresa;
    Qry.ParamByName('almacen').AsString := AAlmacen;
    Qry.ParamByName('caja').AsString := ACaja;
    Qry.Open;
    SetLength(Result, Qry.RecordCount);
    iDia := 0;
    while not Qry.Eof do
    begin
      Result[iDia].Fecha :=
        Qry.FieldByName('FECHA').AsDateTime;
      Result[iDia].TotalVentas :=
        Qry.FieldByName('TOTAL_VENTAS').AsInteger;
      Result[iDia].TotalCobrado :=
        Qry.FieldByName('TOTAL_COBRADO').AsCurrency;
      Inc(iDia);
      Qry.Next;
    end;
    SetLength(Result, iDia);
  finally
    FreeAndNil(Qry);
  end;
end;

function CrearRepositorioVentasCalendarioUniDAC(
  AConexion: TUniConnection): IRepositorioVentasCalendario;
begin
  Result := TRepositorioVentasCalendarioUniDAC.Create(AConexion);
end;

end.
