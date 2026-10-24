{******************************************************************************}
{                                                                              }
{  Modulo:       inLibComprasSesionesAplicacionIntf                            }
{    Tipo:       Contrato                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Puertos minimos del flujo de materializacion de una sesion de compra.     }
{    No conocen formularios, datasets, UniDAC ni controles visuales.           }
{******************************************************************************}
unit inLibComprasSesionesAplicacionIntf;

interface

uses
  inLibComprasSesionesCreacion,
  inLibComprasSesionesIntf,
  inLibComprasSesionesPreciosTalla;

type
  TIncidenciasMaterializacionSesion = TArray<string>;

  IOperacionesMaterializacionCompraSesion = interface
    ['{C4647D25-CED5-40B7-B61C-6A354F6073F7}']
    function LeerEstado: TEstadoSesionCreacion;
    procedure GuardarEdicion;
    function NormalizarDuplicados(
      const AEstado: TEstadoSesionCreacion): Integer;
    function Validar(
      out AIncidencias: TIncidenciasMaterializacionSesion): Boolean;
    function CalcularDefectos(
      const AEstado: TEstadoSesionCreacion): TDefectosDialogoCreacion;
    procedure ActualizarCabecera(
      const AAjustes: TAjustesCreacionElegidos);
    // Con un documento por almacén: los almacenes sin serie propia.
    function SeriesSinPropia(
      const AEstado: TEstadoSesionCreacion;
      const AAjustes: TAjustesCreacionElegidos): TSeriesAlmacenesSinPropia;
    function Materializar(
      const AAjustes: TAjustesCreacionElegidos;
      out AResultado: TResultadoMaterializacionSesion): Boolean;
    procedure Refrescar;
    // Antes de grabar: artículos con precios por talla, color o SKU, o
    // con filas vigentes en la tarifa elegida (FZ-ISSUE-638).
    function CalcularPreciosTarifa(
      const AAjustes: TAjustesCreacionElegidos): TArticulosPreciosTarifa;
  end;

  IVistaMaterializacionCompraSesion = interface
    ['{5866836E-9552-4C01-A621-5152E3930AB4}']
    procedure Registrar(const ATexto: string);
    procedure MostrarBloqueo(AMotivo: TMotivoBloqueoCreacion);
    procedure InformarDuplicados(ACantidad: Integer);
    procedure MostrarIncidencias(
      const AIncidencias: TIncidenciasMaterializacionSesion);
    function SolicitarAjustes(
      const AEstado: TEstadoSesionCreacion;
      const ADefectos: TDefectosDialogoCreacion;
      out AAjustes: TAjustesCreacionElegidos): Boolean;
    // Avisa antes de grabar; False = no crear los documentos.
    function ConfirmarSeriesSinPropia(
      const ASeries: TSeriesAlmacenesSinPropia): Boolean;
    procedure MostrarResultado(
      const AResultado: TResultadoMaterializacionSesion);
    procedure MostrarError(const AMensaje: string);
    // Aviso tras una materialización correcta (no es un error).
    procedure MostrarAviso(const AMensaje: string);
    // Resumen de las filas de tarifa y, si hay artículos con precio
    // vigente, si se modifica o se crea una tarifa nueva desde una fecha.
    // False = no materializar.
    function ConfirmarPreciosTarifa(const ATarifa: string;
      const APrecios: TArticulosPreciosTarifa;
      var AOpciones: TOpcionesTarifaSesion): Boolean;
  end;

  IAplicacionMaterializacionCompraSesion = interface
    ['{28997231-E8B7-4DCA-A30C-EA3A570C1D21}']
    procedure Ejecutar;
  end;

implementation

end.
