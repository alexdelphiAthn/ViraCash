{******************************************************************************}
{                                                                              }
{  Modulo:       inLibFacturacionAlbaranesFechasPersistenciaIntf             }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de lectura para facturar albaranes por fecha y serie.              }
{******************************************************************************}
unit inLibFacturacionAlbaranesFechasPersistenciaIntf;

interface

uses
  System.SysUtils;

type
  TAlbaranFacturacionFechas = record
    Numero: string;
    Serie: string;
    Fecha: TDateTime;
    CodigoCliente: string;
    RazonSocial: string;
    Total: Currency;
  end;

  TAlbaranesFacturacionFechas = TArray<TAlbaranFacturacionFechas>;

  IRepositorioFacturacionAlbaranesFechas = interface
    ['{0C8B9E7C-42B3-4AD1-AB08-8EF0252C482A}']
    function Buscar(
      const ASerie: string;
      AFechaDesde: TDateTime;
      AFechaHasta: TDateTime): TAlbaranesFacturacionFechas;
  end;

implementation

end.
