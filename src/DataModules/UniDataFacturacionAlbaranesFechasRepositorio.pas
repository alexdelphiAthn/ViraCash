{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataFacturacionAlbaranesFechasRepositorio                }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia UniDAC de la facturacion de albaranes por fechas.            }
{******************************************************************************}
unit UniDataFacturacionAlbaranesFechasRepositorio;

interface

uses
  Uni, inLibFacturacionAlbaranesFechasPersistenciaIntf;

function CrearRepositorioFacturacionAlbaranesFechasUniDAC(
  AConexion: TUniConnection): IRepositorioFacturacionAlbaranesFechas;

implementation

uses
  System.SysUtils;

const
  SQL_BUSCAR_ALBARANES =
    'SELECT NUMERO_ALB, SERIE_ALB, FECHA_ALB, CODIGO_CLI_ALB, ' +
    'RAZON_SOCIAL_CLIENTE_ALB, TOTAL_LIQUIDO_ALB FROM fza_albaranes ' +
    'WHERE SERIE_ALB = :SERIE AND FECHA_ALB BETWEEN :DESDE AND :HASTA ' +
    'AND IFNULL(ESTADO_ALB, '''') <> ''FACTURADO'' ' +
    'AND IFNULL(ESTADO_ALB, '''') <> ''CANCELADO'' ' +
    'ORDER BY CODIGO_CLI_ALB, FECHA_ALB, NUMERO_ALB';

type
  TRepositorioFacturacionAlbaranesFechasUniDAC = class(
    TInterfacedObject,
    IRepositorioFacturacionAlbaranesFechas)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function Buscar(
      const ASerie: string;
      AFechaDesde: TDateTime;
      AFechaHasta: TDateTime): TAlbaranesFacturacionFechas;
  end;

constructor TRepositorioFacturacionAlbaranesFechasUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioFacturacionAlbaranesFechasUniDAC.Buscar(
  const ASerie: string;
  AFechaDesde: TDateTime;
  AFechaHasta: TDateTime): TAlbaranesFacturacionFechas;
var
  iAlbaran: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_BUSCAR_ALBARANES;
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('DESDE').AsDateTime := AFechaDesde;
    oConsulta.ParamByName('HASTA').AsDateTime := AFechaHasta;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iAlbaran := Length(Result);
      SetLength(Result, iAlbaran + 1);
      Result[iAlbaran].Numero :=
        oConsulta.FieldByName('NUMERO_ALB').AsString;
      Result[iAlbaran].Serie :=
        oConsulta.FieldByName('SERIE_ALB').AsString;
      Result[iAlbaran].Fecha :=
        oConsulta.FieldByName('FECHA_ALB').AsDateTime;
      Result[iAlbaran].CodigoCliente :=
        oConsulta.FieldByName('CODIGO_CLI_ALB').AsString;
      Result[iAlbaran].RazonSocial :=
        oConsulta.FieldByName('RAZON_SOCIAL_CLIENTE_ALB').AsString;
      Result[iAlbaran].Total :=
        oConsulta.FieldByName('TOTAL_LIQUIDO_ALB').AsCurrency;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function CrearRepositorioFacturacionAlbaranesFechasUniDAC(
  AConexion: TUniConnection): IRepositorioFacturacionAlbaranesFechas;
begin
  Result := TRepositorioFacturacionAlbaranesFechasUniDAC.Create(AConexion);
end;

end.
