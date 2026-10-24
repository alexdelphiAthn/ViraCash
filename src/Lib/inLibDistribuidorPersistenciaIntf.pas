{******************************************************************************}
{                                                                              }
{  Modulo:       inLibDistribuidorPersistenciaIntf                            }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de datos del distribuidor de cantidades por almacen y talla.       }
{******************************************************************************}
unit inLibDistribuidorPersistenciaIntf;

interface

type
  TConfiguracionCeldasDistribuidor = record
    Tabla: string;
    CampoSerie: string;
    CampoNumero: string;
    CampoLinea: string;
    CampoFila: string;
    CampoAlmacen: string;
    CampoAtributoValor: string;
    CampoCantidad: string;
  end;

  TDocumentoDistribuidor = record
    Serie: string;
    Numero: string;
    Linea: Integer;
  end;

  TAlmacenDistribuidor = record
    Codigo: string;
    Nombre: string;
  end;

  TAlmacenesDistribuidor = TArray<TAlmacenDistribuidor>;

  TCeldaDistribuidor = record
    CodigoAlmacen: string;
    IdAtributoValor: Integer;
    Cantidad: Double;
  end;

  TCeldasDistribuidor = TArray<TCeldaDistribuidor>;

  TValorKitDistribuidor = record
    ValorDestino: string;
    Cantidad: Double;
  end;

  TValoresKitDistribuidor = TArray<TValorKitDistribuidor>;

  TCambioCeldaDistribuidor = record
    CodigoAlmacen: string;
    IdAtributoValor: Integer;
    Cantidad: Double;
  end;

  TCambiosCeldasDistribuidor = TArray<TCambioCeldaDistribuidor>;

  IRepositorioDistribuidor = interface
    ['{23CEED78-321B-48B6-8393-D467982423B1}']
    function ListarAlmacenes: TAlmacenesDistribuidor;
    function ListarCeldas(
      const AConfiguracion: TConfiguracionCeldasDistribuidor;
      const ADocumento: TDocumentoDistribuidor
    ): TCeldasDistribuidor;
    function ListarValoresKit(
      const ACodigoProveedor: string;
      const ACodigoKit: string
    ): TValoresKitDistribuidor;
    procedure GuardarCambios(
      const AConfiguracion: TConfiguracionCeldasDistribuidor;
      const ADocumento: TDocumentoDistribuidor;
      const AUsuario: string;
      const ACambios: TCambiosCeldasDistribuidor);
  end;

implementation

end.
