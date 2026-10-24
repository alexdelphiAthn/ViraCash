{******************************************************************************}
{                                                                              }
{  Modulo:       inLibDestinoEnvioPersistenciaIntf                            }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de lectura para seleccionar el destino de un documento.            }
{******************************************************************************}
unit inLibDestinoEnvioPersistenciaIntf;

interface

uses
  System.SysUtils;

type
  TValoresDestinoEnvio = TArray<string>;

  IRepositorioDestinoEnvio = interface
    ['{EA0C266E-9993-419E-94E6-E66D9B60A43B}']
    function ListarAlmacenes(
      const AEmpresa: string): TValoresDestinoEnvio;
    function ListarSeries(
      const AEmpresa: string;
      const ATipoDocumento: string): TValoresDestinoEnvio;
  end;

implementation

end.
