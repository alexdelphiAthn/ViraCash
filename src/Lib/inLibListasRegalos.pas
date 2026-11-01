{******************************************************************************}
{                                                                              }
{  Módulo:       inLibListasRegalos                                            }
{    Tipo:       Librería (dominio)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Listas de regalos (nacimiento, bautizo...): códigos de estado, tipo,      }
{    canal y resultado de los procedimientos PRC_LRG_*, sus textos y los       }
{    records que viajan entre ViraCash y el módulo vcashlistaregalos de        }
{    PrestaShop. Diseño completo en ViraCash\lista_regalos\README.md.          }
{******************************************************************************}
unit inLibListasRegalos;

interface

const
  PARAMETRO_LISTAS_REGALOS = 'appListasRegalos';
  PARAMETRO_CLAVE_LISTAS_REGALOS = 'appPrestaShopClaveListasRegalos';

  ESTADO_LISTA_ABIERTA = 'ABIERTA';
  ESTADO_LISTA_CERRADA = 'CERRADA';
  ESTADO_LISTA_ANULADA = 'ANULADA';

  TIPOS_LISTA: array[0..5] of string = ('NACIMIENTO', 'BAUTIZO', 'COMUNION',
    'CUMPLEANOS', 'BODA', 'OTRO');
  ENTREGAS_LISTA: array[0..1] of string = ('TIENDA', 'DOMICILIO');

  CANAL_REGALO_CAJA = 'CAJA';
  CANAL_REGALO_WEB = 'WEB';
  ESTADO_REGALO_CONFIRMADO = 'CONFIRMADO';

  // p_RESULTADO de los procedimientos PRC_LRG_*.
  RESULTADO_LRG_CORRECTO = 1;
  RESULTADO_LRG_CON_MATIZ = 2;
  RESULTADO_LRG_YA_REGISTRADO = 3;
  RESULTADO_LRG_NADA = 0;
  RESULTADO_LRG_NO_ABIERTA = -1;
  RESULTADO_LRG_LINEA = -2;
  RESULTADO_LRG_SKU = -3;
  RESULTADO_LRG_CANTIDAD = -4;
  RESULTADO_LRG_PENDIENTE = -5;
  RESULTADO_LRG_ESTADO = -6;

  // Estados con los que ViraCash confirma los regalos web a la tienda.
  CONFIRMACION_REGALO_RECHAZADO = 'RECHAZADO';

type
  TLineaListaPublicable = record
    Linea: Integer;
    Orden: Integer;
    Sku: string;
    Articulo: string;
    Descripcion: string;
    CantidadDeseada: Integer;
    CantidadRegalada: Integer;
    Imprescindible: Boolean;
    AdmiteOtraVariante: Boolean;
    Observaciones: string;
  end;

  // Lo que se publica de una lista en una tienda: la foto de una versión.
  TListaPublicable = record
    Codigo: string;
    ClavePublica: string;
    Tipo: string;
    Titulo: string;
    Homenajeado: string;
    Titulares: string;
    Mensaje: string;
    FechaEvento: TDateTime;
    TieneFechaEvento: Boolean;
    TipoEntrega: string;
    Visible: Boolean;
    Buscable: Boolean;
    Version: Integer;
    Lineas: TArray<TLineaListaPublicable>;
    // Líneas de pedido web ya registradas en ViraCash: la tienda deja de
    // restarlas aparte al recibir esta versión.
    RegalosWebIncluidos: TArray<Int64>;
  end;

  TRespuestaPublicacionLista = record
    Ignorada: Boolean;
    SkusSinProducto: TArray<string>;
  end;

  // Regalo comprado en la web que ViraCash aún no ha recogido.
  TRegaloWebPendiente = record
    Lista: string;
    Linea: Integer;
    Sku: string;
    Cantidad: Integer;
    Importe: Currency;
    IdPedido: string;
    IdLineaPedido: Int64;
    Nombre: string;
    Email: string;
    Mensaje: string;
  end;

  TResultadoCierreLista = record
    Resultado: Integer;
    TotalRegalado: Currency;
    Bonificacion: Currency;
  end;

function EsResultadoListaCorrecto(AResultado: Integer): Boolean;
// Texto para el usuario de un p_RESULTADO; '' si es un éxito sin matiz.
function TextoResultadoLista(AResultado: Integer): string;
function TextoEstadoLista(const AEstado: string): string;
function TextoTipoLista(const ATipo: string): string;
function TextoEntregaLista(const AEntrega: string): string;
function TextoCanalRegalo(const ACanal: string): string;
function TextoEstadoRegalo(const AEstado: string): string;
// Origen de una tienda en ORIGENPS_*: la URL de su API normalizada, igual
// que NormalizarOrigenPedidos (inLibImportacionPedidos).
function OrigenListasPrestaShop(const AUrlApi: string): string;
// Raíz pública de la tienda a partir de la URL de su API (quita «/api»).
function RaizTiendaPrestaShop(const AUrlApi: string): string;

implementation

uses
  System.SysUtils, System.StrUtils, inLibMsgListasRegalos;

function EsResultadoListaCorrecto(AResultado: Integer): Boolean;
begin
  Result := AResultado in [RESULTADO_LRG_CORRECTO, RESULTADO_LRG_CON_MATIZ,
    RESULTADO_LRG_YA_REGISTRADO];
end;

function TextoResultadoLista(AResultado: Integer): string;
begin
  case AResultado of
    RESULTADO_LRG_CORRECTO: Result := '';
    RESULTADO_LRG_CON_MATIZ: Result := SResultadoListaSumada;
    RESULTADO_LRG_YA_REGISTRADO: Result := SResultadoListaYaRegistrado;
    RESULTADO_LRG_NADA: Result := SResultadoListaNadaQueHacer;
    RESULTADO_LRG_NO_ABIERTA: Result := SResultadoListaNoAbierta;
    RESULTADO_LRG_LINEA: Result := SResultadoListaLineaNoValida;
    RESULTADO_LRG_SKU: Result := SResultadoListaSkuNoValido;
    RESULTADO_LRG_CANTIDAD: Result := SResultadoListaCantidadNoValida;
    RESULTADO_LRG_PENDIENTE: Result := SResultadoListaSuperaPendiente;
    RESULTADO_LRG_ESTADO: Result := SResultadoListaEstadoNoPermite;
  else
    Result := Format(SResultadoListaDesconocido, [AResultado]);
  end;
end;

function TextoEstadoLista(const AEstado: string): string;
begin
  case IndexText(AEstado, [ESTADO_LISTA_ABIERTA, ESTADO_LISTA_CERRADA,
    ESTADO_LISTA_ANULADA]) of
    0: Result := SEstadoListaAbierta;
    1: Result := SEstadoListaCerrada;
    2: Result := SEstadoListaAnulada;
  else
    Result := AEstado;
  end;
end;

function TextoTipoLista(const ATipo: string): string;
begin
  case IndexText(ATipo, TIPOS_LISTA) of
    0: Result := STipoListaNacimiento;
    1: Result := STipoListaBautizo;
    2: Result := STipoListaComunion;
    3: Result := STipoListaCumpleanos;
    4: Result := STipoListaBoda;
    5: Result := STipoListaOtra;
  else
    Result := ATipo;
  end;
end;

function TextoEntregaLista(const AEntrega: string): string;
begin
  case IndexText(AEntrega, ENTREGAS_LISTA) of
    0: Result := SEntregaListaTienda;
    1: Result := SEntregaListaDomicilio;
  else
    Result := AEntrega;
  end;
end;

function TextoCanalRegalo(const ACanal: string): string;
begin
  case IndexText(ACanal, [CANAL_REGALO_CAJA, CANAL_REGALO_WEB, 'MANUAL']) of
    0: Result := SCanalRegaloCaja;
    1: Result := SCanalRegaloWeb;
    2: Result := SCanalRegaloManual;
  else
    Result := ACanal;
  end;
end;

function TextoEstadoRegalo(const AEstado: string): string;
begin
  if SameText(AEstado, ESTADO_REGALO_CONFIRMADO) then
    Result := SEstadoRegaloConfirmado
  else
    Result := SEstadoRegaloAnulado;
end;

function OrigenListasPrestaShop(const AUrlApi: string): string;
begin
  Result := LowerCase(Trim(AUrlApi));
  while EndsStr('/', Result) do
    Delete(Result, Length(Result), 1);
end;

function RaizTiendaPrestaShop(const AUrlApi: string): string;
begin
  // Sin pasar a minúsculas: la ruta de la tienda puede distinguirlas.
  Result := Trim(AUrlApi);
  while EndsStr('/', Result) do
    Delete(Result, Length(Result), 1);
  if EndsText('/api', Result) then
    Delete(Result, Length(Result) - 3, 4);
end;

end.
