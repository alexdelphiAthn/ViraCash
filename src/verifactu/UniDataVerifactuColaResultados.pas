{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataVerifactuColaResultados                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Persistencia UniDAC de resultados, consolidación y reintentos Verifactu.  }
{******************************************************************************}
unit UniDataVerifactuColaResultados;

interface

uses
  Uni, inLibParametrosIntf, inLibVerifactuEnvio, inLibLogIntf;
type
  TResultadosVerifactuColaUniDAC = class
  public
    class procedure GuardarEnvioOk(
      AConexion: TUniConnection; const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja; const AUsuario: string;
      AIdCola: Int64; const ASerie, ANumero, ATipoOperacion: string;
      const AResultado: TResultadoEnvioVerifactu;
      const ARegistroLog: IRegistroLog); static;
    class procedure GuardarEnvioError(
      AConexion: TUniConnection; const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja; const AUsuario: string;
      AIdCola: Int64; const ASerie, ANumero, AMensaje: string;
      AIntentos: Integer;
      const ARegistroLog: IRegistroLog;
      ANoConsumirIntento: Boolean = False;
      AEsperaSinIntentoSegundos: Integer = 0;
      ARechazoDefinitivo: Boolean = False); static;
  end;
implementation
uses
  System.SysUtils, inLibVerifactu, inLibVentasWsCola,
  UniDataVentasWsCola, UniDataVerifactuResultadosEnvioOperacion,
  UniDataVerifactuResultadosEnvioPersistencia;

// FZ-ISSUE-311: el SII queda fuera del reglamento de SIF y no tiene
// registro de eventos. Con el modo SII, o con una fila del SII aunque el
// modo ya sea otro, el resultado va al log de la aplicación como INFO.
procedure RegistrarEventoCola(
  const AParametrosApp: IParametrosAplicacion; AConexion: TUniConnection;
  const ARegistroLog: IRegistroLog; AFilaSii: Boolean;
  const AUsuario: string; ATipoEvento: Integer;
  const ADescripcion, ADatosAdicionales, ASerie, ANumero: string);
begin
  if AFilaSii or SiiActivo(AParametrosApp) then
  begin
    if Assigned(ARegistroLog) then
      ARegistroLog.RegistrarInformacion(TextoSucesoColaSii(
        ADescripcion, ADatosAdicionales, ASerie, ANumero));
  end
  else
    RegistrarEventoVerifactu(AParametrosApp, AConexion, AUsuario,
      ATipoEvento, ADescripcion, ADatosAdicionales, ASerie, ANumero);
end;

class procedure TResultadosVerifactuColaUniDAC.GuardarEnvioOk(
  AConexion: TUniConnection; const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja; const AUsuario: string;
  AIdCola: Int64; const ASerie, ANumero, ATipoOperacion: string;
  const AResultado: TResultadoEnvioVerifactu;
  const ARegistroLog: IRegistroLog);
var
  bAplicado: Boolean;
  oEntrada: TEntradaResultadoEnvioVerifactu;
  oOperacion: TOperacionResultadosEnvioVerifactu;
begin
  oEntrada := Default(TEntradaResultadoEnvioVerifactu);
  oEntrada.IdCola := AIdCola;
  oEntrada.Serie := ASerie;
  oEntrada.Numero := ANumero;
  oEntrada.TipoOperacion := ATipoOperacion;
  oEntrada.Usuario := AUsuario;
  oEntrada.Resultado := AResultado;
  oOperacion := CrearOperacionResultadosEnvioVerifactuUniDAC(AConexion);
  try
    bAplicado := oOperacion.GuardarEnvioOk(oEntrada);
  finally
    FreeAndNil(oOperacion);
  end;
  if bAplicado then
  begin
    RegistrarEventoCola(AParametrosApp, AConexion, ARegistroLog,
      SameText(AResultado.Sistema, cSistemaColaSii), AUsuario,
      cEventoVerifactuEnvioOk,
      'Registro de facturación (' + ATipoOperacion + ') aceptado por la ' +
      'AEAT (' + AResultado.EstadoRegistro + ')',
      'CSV: ' + AResultado.RequestId, ASerie, ANumero);
    TVentasWsCola.RegistrarEventoSeguro(
      AParametrosCaja,
      CrearRepositorioVentasWsColaUniDAC(AConexion),
      AUsuario,
      'FISCAL_ACTUALIZADO', ASerie, ANumero, ARegistroLog);
  end;
end;

class procedure TResultadosVerifactuColaUniDAC.GuardarEnvioError(
  AConexion: TUniConnection; const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja; const AUsuario: string;
  AIdCola: Int64; const ASerie, ANumero, AMensaje: string;
  AIntentos: Integer;
  const ARegistroLog: IRegistroLog;
  ANoConsumirIntento: Boolean;
  AEsperaSinIntentoSegundos: Integer;
  ARechazoDefinitivo: Boolean);
var
  oEntrada: TEntradaErrorEnvioVerifactu;
  oOperacion: TOperacionResultadosEnvioVerifactu;
begin
  oEntrada := Default(TEntradaErrorEnvioVerifactu);
  oEntrada.IdCola := AIdCola;
  oEntrada.Serie := ASerie;
  oEntrada.Numero := ANumero;
  oEntrada.Mensaje := AMensaje;
  oEntrada.Usuario := AUsuario;
  oEntrada.Intentos := AIntentos;
  oEntrada.MaximoIntentos := AParametrosApp.GetInt(
    'appVerifactuMaxIntentos',
    10);
  oEntrada.NoConsumirIntento := ANoConsumirIntento;
  oEntrada.EsperaSinIntentoSegundos := AEsperaSinIntentoSegundos;
  oEntrada.RechazoDefinitivo := ARechazoDefinitivo;
  oOperacion := CrearOperacionResultadosEnvioVerifactuUniDAC(AConexion);
  try
    oOperacion.GuardarEnvioError(oEntrada);
  finally
    FreeAndNil(oOperacion);
  end;
  if ANoConsumirIntento then
    RegistrarEventoCola(AParametrosApp, AConexion, ARegistroLog, False,
      AUsuario,
      cEventoVerifactuInfo,
      'Envío Verifactu aplazado por falta de conexión; ' +
      'el intento no se contabiliza: ' + AMensaje,
      '', ASerie, ANumero)
  else
  begin
    if ARechazoDefinitivo then
      RegistrarEventoCola(AParametrosApp, AConexion, ARegistroLog, False,
        AUsuario,
        cEventoVerifactuEnvioError,
        'Registro rechazado por la AEAT; no se reintenta. Corrija los ' +
        'datos y relance la factura: ' + AMensaje, '', ASerie, ANumero)
    else
      RegistrarEventoCola(AParametrosApp, AConexion, ARegistroLog, False,
        AUsuario,
        cEventoVerifactuEnvioError,
        'Error de envío Verifactu (intento ' + IntToStr(AIntentos + 1) +
        '): ' + AMensaje, '', ASerie, ANumero);
    // Lo que ve el servidor solo cambia cuando el error es definitivo
    // (FASE_FAC pasa a error): los reintentos no generan evento
    if CrearPlanErrorEnvioVerifactu(oEntrada).ActualizarFactura then
      TVentasWsCola.RegistrarEventoSeguro(
        AParametrosCaja,
        CrearRepositorioVentasWsColaUniDAC(AConexion),
        AUsuario,
        'FISCAL_ACTUALIZADO', ASerie, ANumero, ARegistroLog);
  end;
end;
end.
