{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaOpeComposicion                                       }
{    Tipo:       Factoría                                                      }
{ Versión:       2.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Ensambla los servicios de la ventana de operación de caja.              }
{                                                                              }
{    El repositorio de consultas llega YA CONSTRUIDO desde la raíz de         }
{    composición: esta unidad no conoce UniData*, que es la dirección         }
{    prohibida por LIBRO_DE_ESTILO_DELPHI.md 14.1.                            }
{******************************************************************************}
unit inLibCajaOpeComposicion;

interface

uses
  inLibParametrosIntf,
  inLibContextoSesionIntf,
  inLibCajaVentaIntf,
  inLibCajaStockPersistenciaIntf,
  inLibFacturasPersistenciaIntf, inLibVentasWsColaIntf,
  inLibLogIntf, inLibFormatoDocumentoLecturasIntf;

function CrearServiciosOperacionCaja(
  const AParametrosCaja: IParametrosCaja;
  const ACajaStockPersistencia: ICajaStockPersistencia;
  const AContextoSesion: IContextoSesionAplicacion;
  const AImpresor: IImpresorVenta;
  const AUnidadTrabajo: IUnidadTrabajoVentaCaja;
  const ARepositorioConsultas: IRepositorioConsultasCaja;
  const ARepositorioPdf: IRepositorioPdfFactura;
  const ARepositorioVentasWs: IAltaVentasWsCola;
  const ARegistroLog: IRegistroLog;
  const AFormatoDocumentos: IFormatoDocumentoLecturas = nil
): TContextoDependenciasOperacionCaja;

implementation

uses
  inLibCajaStock,
  inLibCajaDescuentos,
  inLibCajaRectificacion,
  inLibCajaCierreVenta;

function CrearServiciosOperacionCaja(
  const AParametrosCaja: IParametrosCaja;
  const ACajaStockPersistencia: ICajaStockPersistencia;
  const AContextoSesion: IContextoSesionAplicacion;
  const AImpresor: IImpresorVenta;
  const AUnidadTrabajo: IUnidadTrabajoVentaCaja;
  const ARepositorioConsultas: IRepositorioConsultasCaja;
  const ARepositorioPdf: IRepositorioPdfFactura;
  const ARepositorioVentasWs: IAltaVentasWsCola;
  const ARegistroLog: IRegistroLog;
  const AFormatoDocumentos: IFormatoDocumentoLecturas
): TContextoDependenciasOperacionCaja;
begin
  Result.RepositorioConsultas := ARepositorioConsultas;
  Result.ServicioRectificacion :=
    TServicioRectificacionCaja.Create(
      Result.RepositorioConsultas);
  Result.PoliticaStock :=
    TPoliticaStockVenta.Create(
      ACajaStockPersistencia,
      AParametrosCaja);
  Result.RepartidorDescuento :=
    TRepartidorDescuento.Create;
  Result.CasoUsoCierre :=
    TCasoUsoCierreVentaCaja.Create(
      AUnidadTrabajo,
      AImpresor,
      AParametrosCaja,
      AContextoSesion,
      ARepositorioPdf,
      ARepositorioVentasWs,
      ARegistroLog, AFormatoDocumentos);
end;

end.
