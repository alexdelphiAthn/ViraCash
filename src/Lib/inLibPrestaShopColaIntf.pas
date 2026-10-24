{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPrestaShopColaIntf                                      }
{    Tipo:       Contrato                                                      }
{ Versión:       2.1.0                                                         }
{   Fecha:       14/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Contratos de la cola de cambios de catálogo por artículo.                 }
{******************************************************************************}
unit inLibPrestaShopColaIntf;

interface

uses
  System.SysUtils, inLibPrestaShopAltaArticuloIntf,
  inLibPrestaShopColaHistorialIntf;

const
  CMarcaReanudacionAltaPrestaShop = '[ALTA_PRESTASHOP] ';

type
  TAccionVisibilidadPrestaShop = (
    avpNinguna,
    avpActivar,
    avpDesactivar);

  TConfiguracionPrestaShopCola = record
    ClaveInstalacion: string;
    CodigoEmpresa: string;
    CodigoTarifa: string;
    IdTienda: Integer;
    IdIdioma: Integer;
    IdCategoriaRaiz: Integer;
    IdReglaIvaNormal: Integer;
    IdReglaIvaReducido: Integer;
    IdReglaIvaSuperreducido: Integer;
    IdReglaIvaExento: Integer;
    NivelesFamiliaAlta: Integer;
    StockActivo: Boolean;
  end;

  TConfiguracionGlobalPrestaShop = record
    Activo: Boolean;
    SincronizarStockPrecios: Boolean;
    CrearArticulos: Boolean;
    HacerBarridoPeriodico: Boolean;
    UrlApi: string;
    ClaveApi: string;
    SegundosCiclo: Integer;
    HorasBarrido: Integer;
    MaxIntentos: Integer;
    Cola: TConfiguracionPrestaShopCola;
  end;

  TLineaArticuloPrestaShop = record
    CodigoSku: string;
    EstaActiva: Boolean;
    EsCombinacion: Boolean;
    TienePrecio: Boolean;
    TieneStock: Boolean;
    Precio: Double;
    Cantidad: Integer;
  end;

  TTrabajoArticuloPrestaShop = record
    IdCola: Int64;
    IdTienda: Integer;
    Intentos: Integer;
    VersionReclamada: Int64;
    CodigoArticulo: string;
    Token: string;
    AccionVisibilidad: TAccionVisibilidadPrestaShop;
    EstaEnWeb: Boolean;
    EsServicio: Boolean;
    TienePrecio: Boolean;
    TieneStock: Boolean;
    TienePrecioProducto: Boolean;
    TieneProximoCambioPrecio: Boolean;
    ReanudarAlta: Boolean;
    PrecioProducto: Double;
    ProximoCambioPrecio: TDateTime;
    Lineas: TArray<TLineaArticuloPrestaShop>;
  end;

  IRepositorioPreparacionPrestaShopCola = interface
    ['{D4D79B02-D8A0-455A-9CFC-C8CF25B260DF}']
    procedure EncolarCambio(
      const ACodigoArticulo, ACodigoUnidad: string;
      AEsPrecio, AEsStock: Boolean;
      const AUsuario: string);
    procedure EncolarVisibilidad(
      const ACodigoArticulo: string;
      AAccion: TAccionVisibilidadPrestaShop;
      const AUsuario: string);
    function LeerConfiguracionPerfil(
      const AUsuario, AGrupo: string): TConfiguracionGlobalPrestaShop;
    function DestinoSinConflictos(
      const AConfiguracion: TConfiguracionGlobalPrestaShop;
      const AUsuario: string): Boolean;
    procedure ReconciliarSiProcede(
      const AConfiguracion: TConfiguracionPrestaShopCola;
      AHoras: Integer;
      const AUsuario: string);
    procedure ReencolarProcesandoCaducadas(
      const AClaveInstalacion: string;
      AIdTienda: Integer;
      AMinutos: Integer);
    function ReclamarRecuperacion(
      const AClaveInstalacion: string;
      AIdTienda, ASegundos: Integer;
      const AUsuario: string): Boolean;
    function BuscarPendientes(
      const AClaveInstalacion: string;
      AIdTienda: Integer;
      AMaximo: Integer): TArray<Int64>;
    function TieneVisibilidadPendiente(
      const AClaveInstalacion: string;
      AIdTienda: Integer): Boolean;
  end;

  IRepositorioPrestaShopCola = interface(
    IRepositorioPreparacionPrestaShopCola)
    ['{D9C3F838-66D9-4B94-89F2-0BB742AD065E}']
    function MarcarProcesando(
      AIdCola: Int64;
      const AClaveInstalacion: string;
      AIdTienda: Integer;
      const AUsuario: string;
      out AToken: string): Boolean;
    // La cabecera queda disponible aunque falle el cálculo de precio o stock.
    procedure LeerTrabajo(
      AIdCola: Int64;
      const AToken: string;
      const AConfiguracion: TConfiguracionPrestaShopCola;
      out ATrabajo: TTrabajoArticuloPrestaShop);
    function RenovarReclamacion(
      AIdCola: Int64;
      const AToken: string): Boolean;
    function LiberarReclamacionSinIntento(
      AIdCola: Int64;
      const AToken, AUsuario: string): Boolean;
    function MarcarAltaEnCurso(
      AIdCola: Int64;
      const AToken: string): Boolean;
    procedure MarcarEnviada(
      AIdCola: Int64;
      const AToken, AUsuario: string;
      ATieneProximoPrecio: Boolean;
      AProximoPrecio: TDateTime);
    procedure GuardarErrorIntento(
      AIdCola: Int64;
      const AToken, AEstado: string;
      AEsperaSegundos: Integer;
      const AMensaje, AUsuario: string;
      AConsumirIntento: Boolean = True);
  end;

  ISesionPrestaShopCola = interface
    ['{9C7B7C1A-40BB-420E-B396-F675E4D12B53}']
    function LeerIncidencia(const AInstalacion: string;
      ATienda, AHorasIncidencias: Integer): string;
    function GetRepositorio: IRepositorioPrestaShopCola;
    function GetRepositorioAlta: IRepositorioAltaArticuloPresta;
    function GetRegistradorEventos:
      IRegistradorEventosPrestaShopCola;
    property Repositorio: IRepositorioPrestaShopCola read GetRepositorio;
    property RepositorioAlta: IRepositorioAltaArticuloPresta
      read GetRepositorioAlta;
    property RegistradorEventos: IRegistradorEventosPrestaShopCola
      read GetRegistradorEventos;
  end;

  IFabricaSesionPrestaShopCola = interface
    ['{29CD2B79-0B12-49E6-B48C-39FA4506A230}']
    function CrearSesion: ISesionPrestaShopCola;
  end;

implementation

end.
