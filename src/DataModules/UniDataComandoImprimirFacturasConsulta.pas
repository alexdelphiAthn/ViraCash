{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataComandoImprimirFacturasConsulta                        }
{    Tipo:       Fabrica de consultas UniDAC                                   }
{ Version:       1.0.0                                                         }
{   Fecha:       25/08/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Centraliza la consulta de autorizacion usada al imprimir facturas.        }
{******************************************************************************}
unit UniDataComandoImprimirFacturasConsulta;

interface

uses
  Uni;

function CrearConsultaAutorizacionImpresionFacturas(
  AConexion: TUniConnection): TUniQuery;

implementation

function CrearConsultaAutorizacionImpresionFacturas(
  AConexion: TUniConnection): TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  try
    Result.Connection := AConexion;
    Result.SQL.Text :=
      'SELECT TIPO_FAC, ESCONSOLIDADA_FAC, CODIGO_EMP_FAC, ' +
      'CODIGO_ALM_FAC, CODIGO_CAJA_FAC ' +
      'FROM fza_facturas ' +
      'WHERE SERIE_FAC = :SERIE AND NUMERO_FAC = :NUMERO ' +
      'LIMIT 1';
  except
    Result.Free;
    raise;
  end;
end;

end.
