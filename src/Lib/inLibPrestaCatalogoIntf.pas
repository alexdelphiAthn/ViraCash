{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPrestaCatalogoIntf                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       13/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Contratos y errores tipados del catálogo remoto de PrestaShop.            }
{******************************************************************************}
unit inLibPrestaCatalogoIntf;

interface

uses
  System.SysUtils;

type
  TRespuestaHttpPresta = record
    EstadoHttp: Integer;
    TextoEstado: string;
    Contenido: string;
  end;

  TStockDisponiblePresta = record
    Id: Integer;
    IdProducto: Integer;
    IdAtributo: Integer;
    IdTienda: Integer;
    IdGrupoTiendas: Integer;
    Cantidad: Integer;
  end;

  TCombinacionPresta = record
    Id: Integer;
    IdProducto: Integer;
    Referencia: string;
    ImpactoPrecio: Double;
  end;

  EErrorCatalogoPresta = class(Exception);

  EErrorHttpPresta = class(EErrorCatalogoPresta)
  private
    FEstadoHttp: Integer;
    FMetodo: string;
    FRecurso: string;
  public
    constructor Create(AEstadoHttp: Integer;
      const AMetodo, ARecurso: string);
    property EstadoHttp: Integer read FEstadoHttp;
    property Metodo: string read FMetodo;
    property Recurso: string read FRecurso;
  end;

  ERecursoPrestaNoEncontrado = class(EErrorCatalogoPresta)
  private
    FTipoRecurso: string;
    FIdentificacion: string;
  public
    constructor Create(const ATipoRecurso, AIdentificacion: string);
    property TipoRecurso: string read FTipoRecurso;
    property Identificacion: string read FIdentificacion;
  end;

  ERecursoPrestaAmbiguo = class(EErrorCatalogoPresta)
  private
    FTipoRecurso: string;
    FIdentificacion: string;
    FCantidad: Integer;
  public
    constructor Create(const ATipoRecurso, AIdentificacion: string;
      ACantidad: Integer);
    property TipoRecurso: string read FTipoRecurso;
    property Identificacion: string read FIdentificacion;
    property Cantidad: Integer read FCantidad;
  end;

  ERespuestaPrestaInvalida = class(EErrorCatalogoPresta)
  private
    FRecurso: string;
  public
    constructor Create(const ARecurso, ADetalle: string);
    property Recurso: string read FRecurso;
  end;

  EConfiguracionPrestaInvalida = class(EErrorCatalogoPresta);
  ETransportePresta = class(EErrorCatalogoPresta);

  ITransportePresta = interface
    ['{D56C6518-624B-4DAB-9A29-A0D2A74210D4}']
    function EjecutarGet(
      const ARecurso: string): TRespuestaHttpPresta;
    function EjecutarPatch(const ARecurso, AXml: string):
      TRespuestaHttpPresta;
  end;

  // Se separa del contrato de lectura/parche para no romper dobles
  // existentes que solo prueban la sincronización de precio y stock.
  ITransporteAltaPresta = interface(ITransportePresta)
    ['{C505838C-4636-4301-906F-B36893D4841D}']
    function EjecutarPostXml(const ARecurso, AXml: string):
      TRespuestaHttpPresta;
    function EjecutarPostImagen(const ARecurso, ARutaImagen: string):
      TRespuestaHttpPresta;
  end;

  IClienteCatalogoPresta = interface
    ['{F286E7FB-953B-4CA4-84BA-8A5BD82FE039}']
    // Las búsquedas exigen una única coincidencia de referencia.
    function BuscarProductoUnico(const AReferencia: string;
      AIdTienda: Integer): Integer;
    function BuscarCombinacionUnica(const AReferencia: string;
      AIdProducto, AIdTienda: Integer): Integer;
    // Solo acepta el stock de la tienda exacta. Un id_shop=0 requiere
    // validar share_stock fuera de este contrato y nunca es un fallback.
    function ResolverStockDisponible(AIdProducto, AIdAtributo,
      AIdTienda: Integer): TStockDisponiblePresta;
    function LeerPrecioProducto(AIdProducto,
      AIdTienda: Integer): Double;
    function LeerImpactoPrecioCombinacion(AIdCombinacion,
      AIdTienda: Integer): Double;
    function LeerCantidadStock(AIdStockDisponible,
      AIdTienda: Integer): Integer;
    procedure ActualizarPrecioProducto(AIdProducto, AIdTienda: Integer;
      APrecio: Double);
    procedure ActualizarImpactoPrecioCombinacion(AIdCombinacion,
      AIdTienda: Integer; AImpacto: Double);
    procedure ActualizarCantidadStock(AIdStockDisponible,
      AIdTienda, ACantidad: Integer);
    // Garantiza el estado visible del producto mediante GET/PATCH/GET.
    procedure AsegurarEstadoActivoProducto(
      AIdProducto, AIdTienda: Integer;
      AActivo: Boolean);
  end;

  IClienteCatalogoPrestaInstantanea = interface(IClienteCatalogoPresta)
    ['{682A9867-F99A-4E85-AC5B-2267213B317D}']
    function CargarCombinacionesProducto(AIdProducto,
      AIdTienda: Integer): TArray<TCombinacionPresta>;
    function CargarStocksProducto(AIdProducto,
      AIdTienda: Integer): TArray<TStockDisponiblePresta>;
  end;

implementation

resourcestring
  SErrorHttpPresta =
    'PrestaShop devolvió HTTP %d al ejecutar %s sobre %s.';
  SRecursoPrestaNoEncontrado =
    'No se encontró un recurso %s para %s.';
  SRecursoPrestaAmbiguo =
    'Se encontraron %d recursos %s para %s.';
  SRespuestaPrestaInvalida =
    'La respuesta de PrestaShop para %s no es válida: %s.';

{ EErrorHttpPresta }

constructor EErrorHttpPresta.Create(AEstadoHttp: Integer;
  const AMetodo, ARecurso: string);
begin
  FEstadoHttp := AEstadoHttp;
  FMetodo := AMetodo;
  FRecurso := ARecurso;
  inherited CreateFmt(SErrorHttpPresta,
    [AEstadoHttp, AMetodo, ARecurso]);
end;

{ ERecursoPrestaNoEncontrado }

constructor ERecursoPrestaNoEncontrado.Create(
  const ATipoRecurso, AIdentificacion: string);
begin
  FTipoRecurso := ATipoRecurso;
  FIdentificacion := AIdentificacion;
  inherited CreateFmt(SRecursoPrestaNoEncontrado,
    [ATipoRecurso, AIdentificacion]);
end;

{ ERecursoPrestaAmbiguo }

constructor ERecursoPrestaAmbiguo.Create(
  const ATipoRecurso, AIdentificacion: string; ACantidad: Integer);
begin
  FTipoRecurso := ATipoRecurso;
  FIdentificacion := AIdentificacion;
  FCantidad := ACantidad;
  inherited CreateFmt(SRecursoPrestaAmbiguo,
    [ACantidad, ATipoRecurso, AIdentificacion]);
end;

{ ERespuestaPrestaInvalida }

constructor ERespuestaPrestaInvalida.Create(
  const ARecurso, ADetalle: string);
begin
  FRecurso := ARecurso;
  inherited CreateFmt(SRespuestaPrestaInvalida,
    [ARecurso, ADetalle]);
end;

end.
