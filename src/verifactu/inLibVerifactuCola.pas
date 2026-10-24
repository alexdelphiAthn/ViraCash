{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVerifactuCola                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.2.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Fachada de dominio de la cola fiscal Verifactu. Delega la persistencia    }
{    y el worker en contratos inyectados, sin conocer la BBDD ni SQL.          }
{******************************************************************************}
unit inLibVerifactuCola;

interface

uses
  inLibParametrosIntf, inLibEmisionFiscalIntf,
  inLibVerifactuColaIntf;

type
  TVerifactuCola = class
  public
    class procedure EncolarFactura(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AServicioCola: IServicioVerifactuCola;
      const AUsuario, ASerie, ANumero: string;
      const ATipoOperacion: string = 'ALTA';
      ABorrarMovimientos: Boolean = True); static;
    class procedure RegistrarFacturaNoVerifactu(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AServicioCola: IServicioVerifactuCola;
      const AUsuario, ASerie, ANumero: string;
      const ATipoOperacion: string = 'ALTA';
      ABorrarMovimientos: Boolean = True); static;
    class procedure MarcarFacturaSinVerifactu(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AServicioCola: IServicioVerifactuCola;
      const AUsuario, ASerie, ANumero: string;
      const ATipoOperacion: string = 'ALTA';
      ABorrarMovimientos: Boolean = True); static;
    class procedure BorrarMovimientosFactura(
      const AServicioCola: IServicioVerifactuCola;
      const ASerie, ANumero: string); static;
    class procedure EncolarRectificativa(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AServicioCola: IServicioVerifactuCola;
      const AServicioEmision: IServicioEmisionFiscal;
      const AUsuario, ASerieOriginal, ANumeroOriginal,
      ASerieRect, ANumeroRect: string;
      const ATipoRectificativa: string = 'I';
      ABorrarMovimientosOriginales: Boolean = False); static;
    class procedure VincularRectificativa(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AServicioCola: IServicioVerifactuCola;
      const AServicioEmision: IServicioEmisionFiscal;
      const ASolicitud: TSolicitudVinculoRectificativa); static;
    class procedure CompletarRectificativa(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AServicioCola: IServicioVerifactuCola;
      const AUsuario, ASerieRect, ANumeroRect: string); static;
    class procedure DesvincularRectificativa(
      const AServicioCola: IServicioVerifactuCola;
      const AUsuario, ASerieRect, ANumeroRect: string); static;
    class procedure RegistrarRelacionFactura(
      const AServicioCola: IServicioVerifactuCola;
      const AUsuario, ASerie, ANumero, ASerieOrigen,
      ANumeroOrigen, ATipoRelacion: string); static;
    class procedure IniciarHilo(
      const AProcesador: IProcesadorVerifactuCola); static;
    class procedure DetenerHilo; static;
  end;

implementation

uses
  System.SysUtils;

var
  oProcesadorCola: IProcesadorVerifactuCola;

procedure ExigirServicioCola(
  const AServicioCola: IServicioVerifactuCola);
begin
  if not Assigned(AServicioCola) then
    raise EArgumentNilException.Create('AServicioCola');
end;

class procedure TVerifactuCola.EncolarFactura(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AServicioCola: IServicioVerifactuCola;
  const AUsuario, ASerie, ANumero, ATipoOperacion: string;
  ABorrarMovimientos: Boolean);
begin
  ExigirServicioCola(AServicioCola);
  AServicioCola.EncolarFactura(
    AParametrosApp,
    AParametrosCaja,
    AUsuario,
    ASerie,
    ANumero,
    ATipoOperacion,
    ABorrarMovimientos);
end;

class procedure TVerifactuCola.RegistrarFacturaNoVerifactu(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AServicioCola: IServicioVerifactuCola;
  const AUsuario, ASerie, ANumero, ATipoOperacion: string;
  ABorrarMovimientos: Boolean);
begin
  ExigirServicioCola(AServicioCola);
  AServicioCola.RegistrarFacturaNoVerifactu(
    AParametrosApp,
    AParametrosCaja,
    AUsuario,
    ASerie,
    ANumero,
    ATipoOperacion,
    ABorrarMovimientos);
end;

class procedure TVerifactuCola.MarcarFacturaSinVerifactu(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AServicioCola: IServicioVerifactuCola;
  const AUsuario, ASerie, ANumero, ATipoOperacion: string;
  ABorrarMovimientos: Boolean);
begin
  ExigirServicioCola(AServicioCola);
  AServicioCola.MarcarFacturaSinVerifactu(
    AParametrosApp,
    AParametrosCaja,
    AUsuario,
    ASerie,
    ANumero,
    ATipoOperacion,
    ABorrarMovimientos);
end;

class procedure TVerifactuCola.BorrarMovimientosFactura(
  const AServicioCola: IServicioVerifactuCola;
  const ASerie, ANumero: string);
begin
  ExigirServicioCola(AServicioCola);
  AServicioCola.BorrarMovimientosFactura(ASerie, ANumero);
end;

class procedure TVerifactuCola.EncolarRectificativa(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AServicioCola: IServicioVerifactuCola;
  const AServicioEmision: IServicioEmisionFiscal;
  const AUsuario, ASerieOriginal, ANumeroOriginal,
  ASerieRect, ANumeroRect, ATipoRectificativa: string;
  ABorrarMovimientosOriginales: Boolean);
begin
  ExigirServicioCola(AServicioCola);
  AServicioCola.EncolarRectificativa(
    AParametrosApp,
    AParametrosCaja,
    AServicioEmision,
    AUsuario,
    ASerieOriginal,
    ANumeroOriginal,
    ASerieRect,
    ANumeroRect,
    ATipoRectificativa,
    ABorrarMovimientosOriginales);
end;

class procedure TVerifactuCola.VincularRectificativa(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AServicioCola: IServicioVerifactuCola;
  const AServicioEmision: IServicioEmisionFiscal;
  const ASolicitud: TSolicitudVinculoRectificativa);
begin
  ExigirServicioCola(AServicioCola);
  AServicioCola.VincularRectificativa(
    AParametrosApp,
    AParametrosCaja,
    AServicioEmision,
    ASolicitud);
end;

class procedure TVerifactuCola.CompletarRectificativa(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AServicioCola: IServicioVerifactuCola;
  const AUsuario, ASerieRect, ANumeroRect: string);
begin
  ExigirServicioCola(AServicioCola);
  AServicioCola.CompletarRectificativa(
    AParametrosApp,
    AParametrosCaja,
    AUsuario,
    ASerieRect,
    ANumeroRect);
end;

class procedure TVerifactuCola.DesvincularRectificativa(
  const AServicioCola: IServicioVerifactuCola;
  const AUsuario, ASerieRect, ANumeroRect: string);
begin
  ExigirServicioCola(AServicioCola);
  AServicioCola.DesvincularRectificativa(
    AUsuario,
    ASerieRect,
    ANumeroRect);
end;

class procedure TVerifactuCola.RegistrarRelacionFactura(
  const AServicioCola: IServicioVerifactuCola;
  const AUsuario, ASerie, ANumero, ASerieOrigen,
  ANumeroOrigen, ATipoRelacion: string);
begin
  ExigirServicioCola(AServicioCola);
  AServicioCola.RegistrarRelacionFactura(
    AUsuario,
    ASerie,
    ANumero,
    ASerieOrigen,
    ANumeroOrigen,
    ATipoRelacion);
end;

class procedure TVerifactuCola.IniciarHilo(
  const AProcesador: IProcesadorVerifactuCola);
begin
  if not Assigned(AProcesador) then
    raise EArgumentNilException.Create('AProcesador');
  if not Assigned(oProcesadorCola) then
  begin
    AProcesador.Iniciar;
    oProcesadorCola := AProcesador;
  end;
end;

class procedure TVerifactuCola.DetenerHilo;
begin
  if Assigned(oProcesadorCola) then
  begin
    oProcesadorCola.Detener;
    oProcesadorCola := nil;
  end;
end;

end.
