{******************************************************************************}
{                                                                              }
{  Modulo:       inLibClientesPersistenciaIntf                                }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de persistencia para operaciones propias de clientes.             }
{******************************************************************************}
unit inLibClientesPersistenciaIntf;

interface

type
  TPaisAltaRapidaCliente = record
    Codigo: string;
    Nombre: string;
  end;

  TDatosAltaRapidaCliente = record
    RazonSocial: string;
    Nif: string;
    Direccion: string;
    CodigoPostal: string;
    Poblacion: string;
    Provincia: string;
    Pais: TPaisAltaRapidaCliente;
    ComprobarNif: Boolean;
  end;

  IAltaRapidaClientes = interface
    ['{B4DA5643-4EB2-46D4-85A9-B42C136D09AF}']
    function ConsultarPaises: TArray<TPaisAltaRapidaCliente>;
    function CrearCliente(const ADatos: TDatosAltaRapidaCliente;
      const AUsuario, ATarifa: string): string;
  end;

  IRepositorioClientes = interface
    ['{1F2BA840-C1E2-4353-B5FF-712B3ECF1BBB}']
    function ContarDocumentos(const ACodigoCliente: string): Integer;
  end;

implementation

end.
