{******************************************************************************}
{                                                                              }
{  Módulo:       inLibComprasSesionesMaterializacionIntf                       }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos de escritura de la materialización de sesiones de compra.       }
{******************************************************************************}
unit inLibComprasSesionesMaterializacionIntf;
interface
uses
  inLibComprasSesionesIntf;
type
  TConfiguracionMaterializacionSesion = record
    GeneraPedido: Boolean;
    GeneraAlbaran: Boolean;
    Empresa: string;
    AlmacenCabecera: string;
  end;
  IUnidadTrabajoMaterializacion = interface
    ['{9E08F774-A694-4F35-AE4A-55E370D150CB}']
    procedure Iniciar;
    procedure Confirmar;
    procedure Revertir;
  end;
  IControlTransaccionMaterializacion = interface
    ['{BA982679-8388-40A1-B1CC-A5A2183DFCB7}']
    function EnTransaccion: Boolean;
    procedure IniciarTransaccion;
    procedure ConfirmarTransaccion;
    procedure RevertirTransaccion;
  end;
  IPersistenciaMaterializacionComprasSesiones = interface
    ['{673F12BB-E724-4C8D-918F-F15380DF44A0}']
    function ValidarMaterializacion(
      out AMensajeError: string): Boolean;
    function CargarConfiguracion:
      TConfiguracionMaterializacionSesion;
    function ConsultarAlmacenes: TArray<string>;
    function ResolverSerieDocumento(
      const AEmpresa, ATipoDocumento, AAlmacen,
      ASerieAlternativa: string): string;
    procedure MigrarFotosConfirmadas(const AUsuario: string);
    procedure MaterializarArticulos(
      const AUsuario: string;
      const AOpcionesTarifa: TOpcionesTarifaSesion);
    function MaterializarPedido(
      const AUsuario, ASerie, AAlmacen: string):
      TDocumentoMaterializado;
    // AHoraMovimiento: hora del movimiento de stock elegida en el
    // diálogo; negativa = la hora actual.
    function MaterializarAlbaran(
      const AUsuario, ASerie, AAlmacen: string;
      AHoraMovimiento: TDateTime):
      TDocumentoMaterializado;
    procedure CerrarSesion(
      const APedido, AAlbaran: TDocumentoMaterializado;
      const AUsuario: string);
    procedure RegistrarError(
      const AUsuario, AMensaje: string);
  end;
  IPersistenciaReversionComprasSesiones = interface
    ['{21314426-B962-4305-8EAC-AEADE45CD2D7}']
    function ValidarReversion(
      out AMensajeError: string): Boolean;
    procedure EjecutarReversion(
      const AUsuario: string);
  end;
implementation
end.
