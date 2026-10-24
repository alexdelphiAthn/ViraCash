{******************************************************************************}
{                                                                              }
{  Módulo:       inLibDialectosSql                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Implementaciones de las primitivas SQL de MariaDB, PostgreSQL y           }
{    SQL Server. Las operaciones de negocio completas se seleccionan desde     }
{    el catálogo SQL; esta unidad solo compone diferencias sintácticas.        }
{******************************************************************************}
unit inLibDialectosSql;

interface

uses
  inLibConexionPerfilIntf,
  inLibDialectoSqlIntf;

function CrearDialectoSql(
  AMotor: TMotorBBDD): IDialectoSql;

implementation

uses
  System.SysUtils,
  System.Classes,
  inLibConexionPerfil,
  inLibMsgConexion,
  inLibMsgSql;

type
  TDialectoSqlBase = class abstract(
    TInterfacedObject,
    IDialectoSql)
  private
    FMotor: TMotorBBDD;
    function TextoSinPuntoYComaFinal(
      const ASql: string): string;
  protected
    function DelimitadorInicial: string; virtual; abstract;
    function DelimitadorFinal: string; virtual; abstract;
    function EscaparIdentificador(
      const AIdentificador: string): string; virtual; abstract;
    function PalabraUnidadIntervalo(
      AUnidad: TUnidadIntervaloSql): string;
  public
    constructor Create(AMotor: TMotorBBDD);
    function GetMotor: TMotorBBDD;
    function DelimitarIdentificador(
      const AIdentificador: string): string;
    function DelimitarNombreCompuesto(
      const ANombre: string): string;
    function AplicarLimiteOrdenado(
      const ASql, AOrdenPor: string;
      ACantidad: Integer;
      ADesplazamiento: Integer = 0): string; virtual; abstract;
    function ExpresionFechaHoraActual: string;
    function ExpresionFechaActual: string; virtual;
    function ExpresionSumarFecha(
      const AFecha, AIncremento: string;
      AUnidad: TUnidadIntervaloSql): string; virtual; abstract;
    function ExpresionPosicionCadena(
      const ABuscado, ATexto: string): string; virtual; abstract;
    function ExpresionRellenarIzquierda(
      const AExpresion: string;
      ALongitud: Integer;
      const ARelleno: string): string; virtual; abstract;
    function ExpresionAgregacionTexto(
      const AExpresion, ASeparador, AOrdenPor: string;
      ADistinct: Boolean): string; virtual; abstract;
    function ExpresionIgualdadNulaSegura(
      const AIzquierda, ADerecha: string): string;
    function ExpresionEntero64(
      const AExpresion: string): string; virtual; abstract;
    function SentenciaLlamarProcedimiento(
      const ANombre, AParametros: string): string; virtual;
    function TablaConBloqueoActualizacion(
      const ATabla: string): string; virtual;
    function ClausulaBloqueoActualizacion: string; virtual;
    function ComandosInicializacionSesion:
      TComandosInicializacionSesionSql; virtual;
  end;

  TDialectoMariaDB = class(TDialectoSqlBase)
  protected
    function DelimitadorInicial: string; override;
    function DelimitadorFinal: string; override;
    function EscaparIdentificador(
      const AIdentificador: string): string; override;
  public
    function AplicarLimiteOrdenado(
      const ASql, AOrdenPor: string;
      ACantidad: Integer;
      ADesplazamiento: Integer = 0): string; override;
    function ExpresionSumarFecha(
      const AFecha, AIncremento: string;
      AUnidad: TUnidadIntervaloSql): string; override;
    function ExpresionPosicionCadena(
      const ABuscado, ATexto: string): string; override;
    function ExpresionRellenarIzquierda(
      const AExpresion: string;
      ALongitud: Integer;
      const ARelleno: string): string; override;
    function ExpresionAgregacionTexto(
      const AExpresion, ASeparador, AOrdenPor: string;
      ADistinct: Boolean): string; override;
    function ExpresionEntero64(
      const AExpresion: string): string; override;
    function ComandosInicializacionSesion:
      TComandosInicializacionSesionSql; override;
  end;

  TDialectoPostgreSQL = class(TDialectoSqlBase)
  protected
    function DelimitadorInicial: string; override;
    function DelimitadorFinal: string; override;
    function EscaparIdentificador(
      const AIdentificador: string): string; override;
  public
    function AplicarLimiteOrdenado(
      const ASql, AOrdenPor: string;
      ACantidad: Integer;
      ADesplazamiento: Integer = 0): string; override;
    function ExpresionSumarFecha(
      const AFecha, AIncremento: string;
      AUnidad: TUnidadIntervaloSql): string; override;
    function ExpresionPosicionCadena(
      const ABuscado, ATexto: string): string; override;
    function ExpresionRellenarIzquierda(
      const AExpresion: string;
      ALongitud: Integer;
      const ARelleno: string): string; override;
    function ExpresionAgregacionTexto(
      const AExpresion, ASeparador, AOrdenPor: string;
      ADistinct: Boolean): string; override;
    function ExpresionEntero64(
      const AExpresion: string): string; override;
  end;

  TDialectoSqlServer = class(TDialectoSqlBase)
  protected
    function DelimitadorInicial: string; override;
    function DelimitadorFinal: string; override;
    function EscaparIdentificador(
      const AIdentificador: string): string; override;
  public
    function AplicarLimiteOrdenado(
      const ASql, AOrdenPor: string;
      ACantidad: Integer;
      ADesplazamiento: Integer = 0): string; override;
    function ExpresionFechaActual: string; override;
    function ExpresionSumarFecha(
      const AFecha, AIncremento: string;
      AUnidad: TUnidadIntervaloSql): string; override;
    function ExpresionPosicionCadena(
      const ABuscado, ATexto: string): string; override;
    function ExpresionRellenarIzquierda(
      const AExpresion: string;
      ALongitud: Integer;
      const ARelleno: string): string; override;
    function ExpresionAgregacionTexto(
      const AExpresion, ASeparador, AOrdenPor: string;
      ADistinct: Boolean): string; override;
    function ExpresionEntero64(
      const AExpresion: string): string; override;
    function SentenciaLlamarProcedimiento(
      const ANombre, AParametros: string): string; override;
    function TablaConBloqueoActualizacion(
      const ATabla: string): string; override;
    function ClausulaBloqueoActualizacion: string; override;
  end;

procedure ValidarLimite(
  const ASql, AOrdenPor: string;
  ACantidad, ADesplazamiento: Integer);
begin
  if Trim(ASql) = '' then
    raise EArgumentException.Create(SErrorTextoSqlVacio);
  if Trim(AOrdenPor) = '' then
    raise EArgumentException.Create(SErrorOrdenSqlVacio);
  if ACantidad <= 0 then
    raise EArgumentOutOfRangeException.Create(
      SErrorCantidadLimiteSql);
  if ADesplazamiento < 0 then
    raise EArgumentOutOfRangeException.Create(
      SErrorDesplazamientoSql);
end;

constructor TDialectoSqlBase.Create(AMotor: TMotorBBDD);
begin
  inherited Create;
  FMotor := AMotor;
end;

function TDialectoSqlBase.GetMotor: TMotorBBDD;
begin
  Result := FMotor;
end;

function TDialectoSqlBase.TextoSinPuntoYComaFinal(
  const ASql: string): string;
begin
  Result := TrimRight(ASql);
  if (Result <> '') and (Result[Length(Result)] = ';') then
    Delete(Result, Length(Result), 1);
end;

function TDialectoSqlBase.DelimitarIdentificador(
  const AIdentificador: string): string;
begin
  if AIdentificador = '' then
    raise EArgumentException.Create(SErrorNombreSqlVacio);
  Result := DelimitadorInicial +
    EscaparIdentificador(AIdentificador) +
    DelimitadorFinal;
end;

function TDialectoSqlBase.DelimitarNombreCompuesto(
  const ANombre: string): string;
var
  i: Integer;
  oPartes: TStringList;
begin
  if Trim(ANombre) = '' then
    raise EArgumentException.Create(SErrorNombreSqlVacio);
  Result := '';
  oPartes := TStringList.Create;
  try
    oPartes.StrictDelimiter := True;
    oPartes.Delimiter := '.';
    oPartes.DelimitedText := ANombre;
    for i := 0 to oPartes.Count - 1 do
    begin
      if Trim(oPartes[i]) = '' then
        raise EArgumentException.Create(SErrorNombreSqlVacio);
      if Result <> '' then
        Result := Result + '.';
      if Trim(oPartes[i]) = '*' then
        Result := Result + '*'
      else
        Result := Result +
          DelimitarIdentificador(Trim(oPartes[i]));
    end;
  finally
    oPartes.Free;
  end;
end;

function TDialectoSqlBase.ExpresionFechaHoraActual: string;
begin
  Result := 'CURRENT_TIMESTAMP';
end;

function TDialectoSqlBase.ExpresionFechaActual: string;
begin
  Result := 'CURRENT_DATE';
end;

function TDialectoSqlBase.PalabraUnidadIntervalo(
  AUnidad: TUnidadIntervaloSql): string;
begin
  case AUnidad of
    uisSegundo: Result := 'second';
    uisMinuto: Result := 'minute';
    uisHora: Result := 'hour';
    uisDia: Result := 'day';
    uisSemana: Result := 'week';
    uisMes: Result := 'month';
    uisAnio: Result := 'year';
  else
    raise EArgumentOutOfRangeException.Create(
      SErrorMotorBBDDNoReconocido);
  end;
end;

function TDialectoSqlBase.ExpresionIgualdadNulaSegura(
  const AIzquierda, ADerecha: string): string;
begin
  Result := Format(
    '((%s = %s) OR (%s IS NULL AND %s IS NULL))',
    [AIzquierda, ADerecha, AIzquierda, ADerecha]);
end;

function TDialectoSqlBase.SentenciaLlamarProcedimiento(
  const ANombre, AParametros: string): string;
begin
  Result := Format(
    'CALL %s(%s)',
    [DelimitarNombreCompuesto(ANombre), AParametros]);
end;

function TDialectoSqlBase.TablaConBloqueoActualizacion(
  const ATabla: string): string;
begin
  Result := ATabla;
end;

function TDialectoSqlBase.ClausulaBloqueoActualizacion: string;
begin
  Result := 'FOR UPDATE';
end;

function TDialectoSqlBase.ComandosInicializacionSesion:
  TComandosInicializacionSesionSql;
begin
  Result := nil;
end;

function TDialectoMariaDB.DelimitadorInicial: string;
begin
  Result := '`';
end;

function TDialectoMariaDB.DelimitadorFinal: string;
begin
  Result := '`';
end;

function TDialectoMariaDB.EscaparIdentificador(
  const AIdentificador: string): string;
begin
  Result := StringReplace(
    AIdentificador, '`', '``', [rfReplaceAll]);
end;

function TDialectoMariaDB.AplicarLimiteOrdenado(
  const ASql, AOrdenPor: string;
  ACantidad, ADesplazamiento: Integer): string;
begin
  ValidarLimite(ASql, AOrdenPor, ACantidad, ADesplazamiento);
  Result := Format(
    '%s ORDER BY %s LIMIT %d',
    [TextoSinPuntoYComaFinal(ASql), AOrdenPor, ACantidad]);
  if ADesplazamiento > 0 then
    Result := Result + Format(
      ' OFFSET %d', [ADesplazamiento]);
end;

function TDialectoMariaDB.ExpresionSumarFecha(
  const AFecha, AIncremento: string;
  AUnidad: TUnidadIntervaloSql): string;
begin
  Result := Format(
    'DATE_ADD(%s, INTERVAL %s %s)',
    [AFecha, AIncremento, PalabraUnidadIntervalo(AUnidad)]);
end;

function TDialectoMariaDB.ExpresionPosicionCadena(
  const ABuscado, ATexto: string): string;
begin
  Result := Format('LOCATE(%s, %s)', [ABuscado, ATexto]);
end;

function TDialectoMariaDB.ExpresionRellenarIzquierda(
  const AExpresion: string;
  ALongitud: Integer;
  const ARelleno: string): string;
begin
  if ALongitud <= 0 then
    raise EArgumentOutOfRangeException.Create(
      SErrorLongitudRellenoSql);
  Result := Format(
    'LPAD(%s, %d, %s)',
    [AExpresion, ALongitud, ARelleno]);
end;

function TDialectoMariaDB.ExpresionAgregacionTexto(
  const AExpresion, ASeparador, AOrdenPor: string;
  ADistinct: Boolean): string;
var
  sDistinct: string;
  sOrden: string;
begin
  sDistinct := '';
  if ADistinct then
    sDistinct := 'DISTINCT ';
  sOrden := '';
  if Trim(AOrdenPor) <> '' then
    sOrden := ' ORDER BY ' + AOrdenPor;
  Result := Format(
    'GROUP_CONCAT(%s%s%s SEPARATOR %s)',
    [sDistinct, AExpresion, sOrden, ASeparador]);
end;

function TDialectoMariaDB.ExpresionEntero64(
  const AExpresion: string): string;
begin
  Result := Format('CAST(%s AS SIGNED)', [AExpresion]);
end;

function TDialectoMariaDB.ComandosInicializacionSesion:
  TComandosInicializacionSesionSql;
begin
  SetLength(Result, 2);
  Result[0].Texto :=
    'SET NAMES utf8mb4 COLLATE utf8mb4_spanish_ci';
  Result[0].Obligatorio := False;
  Result[1].Texto :=
    'SET SESSION wait_timeout = 28800, ' +
    'session interactive_timeout = 28800';
  Result[1].Obligatorio := False;
end;

function TDialectoPostgreSQL.DelimitadorInicial: string;
begin
  Result := '"';
end;

function TDialectoPostgreSQL.DelimitadorFinal: string;
begin
  Result := '"';
end;

function TDialectoPostgreSQL.EscaparIdentificador(
  const AIdentificador: string): string;
begin
  Result := StringReplace(
    AIdentificador, '"', '""', [rfReplaceAll]);
end;

function TDialectoPostgreSQL.AplicarLimiteOrdenado(
  const ASql, AOrdenPor: string;
  ACantidad, ADesplazamiento: Integer): string;
begin
  ValidarLimite(ASql, AOrdenPor, ACantidad, ADesplazamiento);
  Result := Format(
    '%s ORDER BY %s LIMIT %d',
    [TextoSinPuntoYComaFinal(ASql), AOrdenPor, ACantidad]);
  if ADesplazamiento > 0 then
    Result := Result + Format(
      ' OFFSET %d', [ADesplazamiento]);
end;

function TDialectoPostgreSQL.ExpresionSumarFecha(
  const AFecha, AIncremento: string;
  AUnidad: TUnidadIntervaloSql): string;
begin
  Result := Format(
    '(%s + ((%s) * INTERVAL ''1 %s''))',
    [AFecha, AIncremento, PalabraUnidadIntervalo(AUnidad)]);
end;

function TDialectoPostgreSQL.ExpresionPosicionCadena(
  const ABuscado, ATexto: string): string;
begin
  Result := Format('POSITION(%s IN %s)', [ABuscado, ATexto]);
end;

function TDialectoPostgreSQL.ExpresionRellenarIzquierda(
  const AExpresion: string;
  ALongitud: Integer;
  const ARelleno: string): string;
begin
  if ALongitud <= 0 then
    raise EArgumentOutOfRangeException.Create(
      SErrorLongitudRellenoSql);
  Result := Format(
    'LPAD(%s, %d, %s)',
    [AExpresion, ALongitud, ARelleno]);
end;

function TDialectoPostgreSQL.ExpresionAgregacionTexto(
  const AExpresion, ASeparador, AOrdenPor: string;
  ADistinct: Boolean): string;
var
  sDistinct: string;
  sOrden: string;
begin
  sDistinct := '';
  if ADistinct then
    sDistinct := 'DISTINCT ';
  sOrden := '';
  if Trim(AOrdenPor) <> '' then
    sOrden := ' ORDER BY ' + AOrdenPor;
  Result := Format(
    'STRING_AGG(%s%s, %s%s)',
    [sDistinct, AExpresion, ASeparador, sOrden]);
end;

function TDialectoPostgreSQL.ExpresionEntero64(
  const AExpresion: string): string;
begin
  Result := Format('CAST(%s AS BIGINT)', [AExpresion]);
end;

function TDialectoSqlServer.DelimitadorInicial: string;
begin
  Result := '[';
end;

function TDialectoSqlServer.DelimitadorFinal: string;
begin
  Result := ']';
end;

function TDialectoSqlServer.EscaparIdentificador(
  const AIdentificador: string): string;
begin
  Result := StringReplace(
    AIdentificador, ']', ']]', [rfReplaceAll]);
end;

function TDialectoSqlServer.AplicarLimiteOrdenado(
  const ASql, AOrdenPor: string;
  ACantidad, ADesplazamiento: Integer): string;
begin
  ValidarLimite(ASql, AOrdenPor, ACantidad, ADesplazamiento);
  Result := Format(
    '%s ORDER BY %s OFFSET %d ROWS FETCH NEXT %d ROWS ONLY',
    [TextoSinPuntoYComaFinal(ASql), AOrdenPor,
     ADesplazamiento, ACantidad]);
end;

function TDialectoSqlServer.ExpresionFechaActual: string;
begin
  Result := 'CAST(CURRENT_TIMESTAMP AS date)';
end;

function TDialectoSqlServer.ExpresionSumarFecha(
  const AFecha, AIncremento: string;
  AUnidad: TUnidadIntervaloSql): string;
begin
  Result := Format(
    'DATEADD(%s, %s, %s)',
    [PalabraUnidadIntervalo(AUnidad), AIncremento, AFecha]);
end;

function TDialectoSqlServer.ExpresionPosicionCadena(
  const ABuscado, ATexto: string): string;
begin
  Result := Format('CHARINDEX(%s, %s)', [ABuscado, ATexto]);
end;

function TDialectoSqlServer.ExpresionRellenarIzquierda(
  const AExpresion: string;
  ALongitud: Integer;
  const ARelleno: string): string;
begin
  if ALongitud <= 0 then
    raise EArgumentOutOfRangeException.Create(
      SErrorLongitudRellenoSql);
  Result := Format(
    'RIGHT(REPLICATE(%s, %d) + ' +
    'CONVERT(nvarchar(max), %s), %d)',
    [ARelleno, ALongitud, AExpresion, ALongitud]);
end;

function TDialectoSqlServer.ExpresionAgregacionTexto(
  const AExpresion, ASeparador, AOrdenPor: string;
  ADistinct: Boolean): string;
begin
  if ADistinct then
    raise ENotSupportedException.CreateFmt(
      SErrorAgregacionDistinctSqlNoSoportada,
      [NombreMotorBBDD(GetMotor)]);
  Result := Format(
    'STRING_AGG(%s, %s)',
    [AExpresion, ASeparador]);
  if Trim(AOrdenPor) <> '' then
    Result := Result + Format(
      ' WITHIN GROUP (ORDER BY %s)',
      [AOrdenPor]);
end;

function TDialectoSqlServer.ExpresionEntero64(
  const AExpresion: string): string;
begin
  Result := Format('CAST(%s AS BIGINT)', [AExpresion]);
end;

function TDialectoSqlServer.SentenciaLlamarProcedimiento(
  const ANombre, AParametros: string): string;
begin
  Result := 'EXEC ' + DelimitarNombreCompuesto(ANombre);
  if Trim(AParametros) <> '' then
    Result := Result + ' ' + AParametros;
end;

function TDialectoSqlServer.TablaConBloqueoActualizacion(
  const ATabla: string): string;
begin
  Result := ATabla + ' WITH (UPDLOCK, ROWLOCK)';
end;

function TDialectoSqlServer.ClausulaBloqueoActualizacion: string;
begin
  Result := '';
end;

function CrearDialectoSql(
  AMotor: TMotorBBDD): IDialectoSql;
begin
  case AMotor of
    mbMariaDB:
      Result := TDialectoMariaDB.Create(AMotor);
    mbPostgreSQL:
      Result := TDialectoPostgreSQL.Create(AMotor);
    mbSQLServer:
      Result := TDialectoSqlServer.Create(AMotor);
  else
    raise EArgumentOutOfRangeException.Create(
      SErrorMotorBBDDNoReconocido);
  end;
end;

end.
