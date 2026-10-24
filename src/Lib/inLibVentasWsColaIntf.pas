{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVentasWsColaIntf                                         }
{    Tipo:       Contrato                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       14/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Puerto de persistencia de la cola transaccional de eventos de venta       }
{    para el webservice de respaldo.                                           }
{******************************************************************************}
unit inLibVentasWsColaIntf;

interface

uses
  inLibVentasWsJsonIntf, inLibVentasWsColaHistorialIntf;

type
  TFilaVentasWsCola = record
    IdEvento: string;
    Empresa: string;
    Serie: string;
    Numero: string;
    TipoEvento: string;
    Intentos: Integer;
    Contenido: string;
  end;
  // Alta de eventos en la cola: lo que necesita quien factura,
  // cobra o cierra un arqueo.
  IAltaVentasWsCola = interface
    ['{E373214F-AE19-4914-9B32-E0F42990C337}']
    function Encolar(
      const AIdEvento, ATipoEvento, ASerie, ANumero,
        AUsuario: string): Int64;
    function EncolarEvento(
      const AIdEvento, ATipoEvento, AEmpresa, ASerie,
        ANumero, AUsuario: string): Int64;
    function ActualizarPdfVentaPendiente(
      AEsFactura: Boolean;
      const ASerie, ANumero, ARutaPdf, AUsuario: string): Boolean;
    procedure ActualizarPdfPorId(
      AEsFactura: Boolean;
      AIdCola: Int64;
      const ARutaPdf, AUsuario: string);
  end;
  // Despacho de la cola: lo que necesita el hilo que envia al
  // webservice. Quien despacha tambien puede dar de alta.
  IDespachoVentasWsCola = interface(IAltaVentasWsCola)
    ['{3F278436-0936-47F8-B8DD-D024273A4851}']
    procedure ReencolarProcesandoCaducadas;
    function BuscarPendientes(
      AMaximo: Integer): TArray<Int64>;
    function MarcarProcesando(
      AIdCola: Int64;
      const AUsuario: string): Boolean;
    function LeerFila(
      AIdCola: Int64): TFilaVentasWsCola;
    procedure GuardarContenido(
      AIdCola: Int64;
      const AContenido, AHuella: string);
    procedure MarcarEnviada(
      AIdCola: Int64;
      const AIdPeticion, AUsuario: string);
    procedure GuardarErrorIntento(
      AIdCola: Int64;
      const AEstado: string;
      AEsperaSegundos: Integer;
      const AMensaje, AUsuario: string;
      AConsumirIntento: Boolean = True);
  end;
  ISesionVentasWs = interface
    ['{06E365D5-63CF-48D0-9D6E-165A815DBB77}']
    function GetRepositorio: IDespachoVentasWsCola;
    function GetJson: IVentasWsJson;
    function LeerIncidencia(AHorasIncidencias: Integer): string;
    function GetRegistradorIntentos:
      IRegistradorIntentosVentasWsCola;
    property Repositorio: IDespachoVentasWsCola read GetRepositorio;
    property Json: IVentasWsJson read GetJson;
    property RegistradorIntentos: IRegistradorIntentosVentasWsCola
      read GetRegistradorIntentos;
  end;
  IFabricaSesionVentasWs = interface
    ['{6827FEAE-15F3-41A1-99CC-A1F1341A361F}']
    function CrearSesion: ISesionVentasWs;
  end;

implementation
end.
