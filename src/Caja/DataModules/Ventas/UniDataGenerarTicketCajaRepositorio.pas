{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataGenerarTicketCajaRepositorio                           }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptador UniDAC para leer operaciones de tickets no fiscales de Caja.    }
{******************************************************************************}
unit UniDataGenerarTicketCajaRepositorio;

interface

uses
  Uni,
  inLibGenerarTicketCajaPersistenciaIntf;

function CrearGenerarTicketCajaRepositorio(
  AConexion: TUniConnection): IGenerarTicketCajaPersistencia;

implementation

uses
  System.SysUtils,
  Data.DB;

type
  TGenerarTicketCajaRepositorio = class(
    TInterfacedObject,
    IGenerarTicketCajaPersistencia)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function ObtenerOperacion(
      const AClave: TClaveOperacionTicketCaja):
      TDatosOperacionTicketCaja;
  end;

function CrearGenerarTicketCajaRepositorio(
  AConexion: TUniConnection): IGenerarTicketCajaPersistencia;
begin
  Result := TGenerarTicketCajaRepositorio.Create(AConexion);
end;

constructor TGenerarTicketCajaRepositorio.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TGenerarTicketCajaRepositorio.ObtenerOperacion(
  const AClave: TClaveOperacionTicketCaja):
  TDatosOperacionTicketCaja;
var
  oConsulta: TUniQuery;
begin
  Result := Default(TDatosOperacionTicketCaja);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT TIPO_OPERACION_OPCAJA, FECHA_OPERACION_OPCAJA, ' +
      '       CODIGO_EMPLEADO_OPCAJA, ' +
      '       CONCEPTO_GASTO_INGRESO_OPCAJA, ' +
      '       IMPORTE_TOTAL_OPCAJA ' +
      '  FROM fza_caja_operaciones ' +
      ' WHERE CODIGO_EMP_OPCAJA = :EMPRESA ' +
      '   AND CODIGO_ALM_OPCAJA = :ALMACEN ' +
      '   AND CODIGO_CAJA_OPCAJA = :CAJA ' +
      '   AND NUMERO_OPERACION_OPCAJA = :OPERACION ' +
      ' LIMIT 1';
    oConsulta.ParamByName('EMPRESA').AsString := AClave.Empresa;
    oConsulta.ParamByName('ALMACEN').AsString := AClave.Almacen;
    oConsulta.ParamByName('CAJA').AsString := AClave.Caja;
    oConsulta.ParamByName('OPERACION').AsString :=
      AClave.NumeroOperacion;
    oConsulta.Open;
    Result.Encontrada := not oConsulta.IsEmpty;
    if Result.Encontrada then
    begin
      Result.TipoOperacion :=
        oConsulta.FieldByName('TIPO_OPERACION_OPCAJA').AsString;
      Result.FechaOperacion :=
        oConsulta.FieldByName('FECHA_OPERACION_OPCAJA').AsDateTime;
      Result.CodigoEmpleado :=
        oConsulta.FieldByName('CODIGO_EMPLEADO_OPCAJA').AsString;
      Result.Concepto :=
        oConsulta.FieldByName(
          'CONCEPTO_GASTO_INGRESO_OPCAJA').AsString;
      Result.Importe :=
        oConsulta.FieldByName('IMPORTE_TOTAL_OPCAJA').AsCurrency;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.
