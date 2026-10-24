{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaOpePresentacionIntf                                  }
{    Tipo:       Librería (interfaces)                                         }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos de la entrada por teclado de la línea de venta de caja.        }
{    Sin VCL, sin UniDAC y sin códigos de tecla de Windows: la traducción     }
{    de VK_* a TTeclaOperacionCaja vive en el adaptador de presentación.      }
{******************************************************************************}
unit inLibCajaOpePresentacionIntf;

interface

type
  // Teclas que gobiernan la entrada de una línea de caja. El resto de
  // pulsaciones (dígitos, letras, borrado) llegan como tocOtra porque
  // solo alimentan la búsqueda incremental de artículos.
  TTeclaOperacionCaja = (
    tocOtra,
    tocIntro,
    tocArriba,
    tocNavegacion);
  // Papel de la columna que se está editando. Solo la de artículo
  // participa en la confirmación de la línea.
  TRolColumnaLineaCaja = (
    rclOtra,
    rclArticulo);
  // Celda a la que salta el foco cuando la línea queda resuelta.
  TDestinoFocoLineaCaja = (
    dflArticulo,
    dflDescripcion,
    dflPrimerAtributo);
  // Qué toca después de confirmar el valor de un atributo (Color,
  // Talla, ...): abrir el siguiente o cerrar la línea.
  TPasoAtributoLineaCaja = (
    palAvanzar,
    palFinalizar);
  IRejillaLineaCaja = interface
    ['{4E1B9B4E-6E6A-4B67-8B93-9C7A2F0C51B1}']
    function RolColumnaActiva: TRolColumnaLineaCaja;
    function TextoEditor: string;
    procedure EscribirEditor(const AValor: string);
    procedure CerrarDesplegable;
    procedure PublicarValorEditor;
    procedure ReactivarBusquedaIncremental;
    procedure DetenerBusquedaIncremental;
    // False cuando el destino no existe (por ejemplo, la primera
    // columna de atributo todavía no está creada).
    function EnfocarYEditar(
      ADestino: TDestinoFocoLineaCaja): Boolean;
  end;
  ILineaVentaCaja = interface
    ['{0A3D0F2C-1D0E-45A5-9C1B-2E4C8B7A6D30}']
    function EstaInsertando: Boolean;
    function CodigoArticulo: string;
    procedure EscribirCodigoArticulo(const ACodigo: string);
    function CodigoSku: string;
    procedure AsegurarEdicion;
    procedure CancelarLinea;
    procedure GrabarYAnadirLinea;
    procedure DescartarLineaRechazada;
  end;
  IArticuloLineaCaja = interface
    ['{7B2F5C61-3A44-4E0C-9F1D-5D6E8A2B44C7}']
    function BuscarArticulo: string;
    function CargarArticulo(const ACodigo: string): Boolean;
    function MotivoRechazo: string;
    function ArticuloResuelto: string;
    procedure OlvidarArticuloResuelto;
    // Ajusta las columnas dinámicas al artículo y devuelve cuántos
    // atributos exige (Color, Talla, ...).
    function PrepararColumnasAtributos(
      const AArticulo: string): Integer;
    function SkuVendible(const ACodigoSku: string): Boolean;
    procedure VolcarAtributosDeSku(const ACodigoSku: string);
    // Parámetro de caja vgerMoverLineaIdentif: al cerrar una línea se
    // abre otra o se permanece en la actual.
    function AvanzarDeLinea: Boolean;
  end;
  IAvisosOperacionCaja = interface
    ['{C2A1D7E8-9B54-4F72-A3B6-0E5F1C8D2A94}']
    procedure Avisar(const AMensaje: string);
  end;
  IProcesadorTeclaLineaCaja = interface
    ['{1F6D3B90-5C27-4A18-B0E4-7A9C6D3E5F82}']
    // True cuando la pulsación queda consumida y la presentación debe
    // anularla (Key := 0).
    function Procesar(ATecla: TTeclaOperacionCaja): Boolean;
  end;

implementation

end.
