{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataVerifactuResultadosEnvioOperacion                     }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Coordina la persistencia atómica del resultado de un envío Verifactu.     }
{******************************************************************************}
unit UniDataVerifactuResultadosEnvioOperacion;

interface

uses
  inLibVerifactuEnvio;

type
  TTipoResultadoEnvioVerifactu = (
    trevAlta,
    trevAnulacion,
    trevSubsanacion);
  TEntradaResultadoEnvioVerifactu = record
    IdCola: Int64;
    Serie: string;
    Numero: string;
    TipoOperacion: string;
    Usuario: string;
    Resultado: TResultadoEnvioVerifactu;
  end;
  // Alta aceptada cuando la factura ya tiene consolidación (FZ-ISSUE-319):
  // un reenvío que la AEAT contesta como duplicado conserva la original
  // (CSV, QR, huella); un alta nueva aceptada la actualiza.
  TAccionAltaConsolidacion = (aacInsertar, aacActualizar, aacConservar);

  TPlanResultadoEnvioVerifactu = record
    TipoResultado: TTipoResultadoEnvioVerifactu;
    FaseFactura: string;
    EstadoConsolidacion: string;
  end;
  TEntradaErrorEnvioVerifactu = record
    IdCola: Int64;
    Serie: string;
    Numero: string;
    Mensaje: string;
    Usuario: string;
    Intentos: Integer;
    MaximoIntentos: Integer;
    NoConsumirIntento: Boolean;
    EsperaSinIntentoSegundos: Integer;
    // Rechazo de la AEAT por los datos del registro: no se reintenta
    RechazoDefinitivo: Boolean;
  end;
  TPlanErrorEnvioVerifactu = record
    EstadoCola: string;
    EsperaSegundos: Integer;
    ActualizarFactura: Boolean;
    IncrementarIntentos: Boolean;
    // Rechazo definitivo: el contador queda en el máximo para que el
    // reproceso de filas en ERROR no la reenvíe en cada ciclo (FZ-ISSUE-321).
    AgotarIntentos: Boolean;
  end;
  IPersistenciaResultadoEnvioVerifactu = interface
    ['{F7CC65B6-8C40-4FB9-A1A3-4E124C6AFB09}']
    procedure ActualizarCadena(
      const AEntrada: TEntradaResultadoEnvioVerifactu);
    procedure GuardarResultado(
      const AEntrada: TEntradaResultadoEnvioVerifactu;
      const APlan: TPlanResultadoEnvioVerifactu);
  end;
  IPersistenciaEstadoEnvioVerifactu = interface
    ['{5A1CAC97-8941-47B5-BD85-0FA45E00F2A3}']
    function EstaColaEnviada(AIdCola: Int64): Boolean;
    procedure ActualizarFactura(
      const AEntrada: TEntradaResultadoEnvioVerifactu;
      const APlan: TPlanResultadoEnvioVerifactu);
    procedure MarcarColaEnviada(
      const AEntrada: TEntradaResultadoEnvioVerifactu);
    procedure GuardarError(
      const AEntrada: TEntradaErrorEnvioVerifactu;
      const APlan: TPlanErrorEnvioVerifactu);
  end;
  TOperacionResultadosEnvioVerifactu = class
  private
    FResultados: IPersistenciaResultadoEnvioVerifactu;
    FEstados: IPersistenciaEstadoEnvioVerifactu;
  public
    constructor Create(
      const AResultados: IPersistenciaResultadoEnvioVerifactu;
      const AEstados: IPersistenciaEstadoEnvioVerifactu);
    function GuardarEnvioOk(
      const AEntrada: TEntradaResultadoEnvioVerifactu): Boolean;
    procedure GuardarEnvioError(
      const AEntrada: TEntradaErrorEnvioVerifactu);
  end;

function CrearPlanResultadoEnvioVerifactu(
  const AEntrada: TEntradaResultadoEnvioVerifactu):
  TPlanResultadoEnvioVerifactu;
function CrearPlanErrorEnvioVerifactu(
  const AEntrada: TEntradaErrorEnvioVerifactu):
  TPlanErrorEnvioVerifactu;

function DecidirAltaConsolidacion(AExiste: Boolean;
  const AEstadoRegistro: string): TAccionAltaConsolidacion;

implementation

uses
  System.SysUtils, inLibVerifactu, inLibVerifactuReintentos;

function CrearPlanResultadoEnvioVerifactu(
  const AEntrada: TEntradaResultadoEnvioVerifactu):
  TPlanResultadoEnvioVerifactu;
begin
  Result := Default(TPlanResultadoEnvioVerifactu);
  Result.TipoResultado := trevAlta;
  Result.FaseFactura := cFaseFacturaVerifactuOk;
  if AEntrada.TipoOperacion = 'ANULACION' then
  begin
    Result.TipoResultado := trevAnulacion;
    Result.FaseFactura := cFaseFacturaVerifactuAnulada;
  end
  else if AEntrada.TipoOperacion = 'SUBSANACION' then
    Result.TipoResultado := trevSubsanacion;
  if SameText(AEntrada.Resultado.Sistema, cSistemaColaSii) then
  begin
    // SII: misma fase de la factura; el estado distingue el sistema
    if Result.TipoResultado = trevAnulacion then
      Result.EstadoConsolidacion := 'SII_ANULADO'
    else if SameText(AEntrada.Resultado.EstadoRegistro,
                'AceptadoConErrores') then
      Result.EstadoConsolidacion := 'SII_ACEPT_ERR'
    else if AEntrada.TipoOperacion = 'SUBSANACION' then
      Result.EstadoConsolidacion := 'SII_MODIFICADO'
    else if SameText(AEntrada.Resultado.EstadoRegistro, 'Duplicado') then
      Result.EstadoConsolidacion := 'SII_DUPLICADO'
    else
      Result.EstadoConsolidacion := 'SII_PROCESADO';
  end
  else if Result.TipoResultado = trevAnulacion then
    Result.EstadoConsolidacion := 'VERIFACTU_ANULADO'
  else if SameText(AEntrada.Resultado.EstadoRegistro,
              'AceptadoConErrores') then
    Result.EstadoConsolidacion := 'VERIFACTU_ACEPT_ERR'
  else if AEntrada.TipoOperacion = 'SUBSANACION' then
    Result.EstadoConsolidacion := 'VERIFACTU_SUBSANADO'
  else if SameText(AEntrada.Resultado.EstadoRegistro, 'Duplicado') then
    Result.EstadoConsolidacion := 'VERIFACTU_DUPLICADO'
  else
    Result.EstadoConsolidacion := 'VERIFACTU_PROCESADO';
end;

function DecidirAltaConsolidacion(AExiste: Boolean;
  const AEstadoRegistro: string): TAccionAltaConsolidacion;
begin
  if not AExiste then
    Result := aacInsertar
  else if SameText(AEstadoRegistro, 'Duplicado') then
    Result := aacConservar
  else
    Result := aacActualizar;
end;

function CrearPlanErrorEnvioVerifactu(
  const AEntrada: TEntradaErrorEnvioVerifactu):
  TPlanErrorEnvioVerifactu;
begin
  Result := Default(TPlanErrorEnvioVerifactu);
  if AEntrada.NoConsumirIntento then
  begin
    Result.EstadoCola := 'PENDIENTE';
    Result.EsperaSegundos := AEntrada.EsperaSinIntentoSegundos;
    if Result.EsperaSegundos < 1 then
      Result.EsperaSegundos := 60;
    Result.ActualizarFactura := False;
    Result.IncrementarIntentos := False;
  end
  else if AEntrada.RechazoDefinitivo then
  begin
    Result.EstadoCola := 'ERROR';
    Result.EsperaSegundos := 0;
    Result.ActualizarFactura := True;
    Result.IncrementarIntentos := True;
    Result.AgotarIntentos := True;
  end
  else
  begin
    Result.EstadoCola := CalcularEstadoReintentoVerifactu(
      AEntrada.Intentos,
      AEntrada.MaximoIntentos);
    Result.EsperaSegundos := CalcularEsperaReintentoVerifactu(
      AEntrada.Intentos);
    Result.ActualizarFactura := Result.EstadoCola = 'ERROR';
    Result.IncrementarIntentos := True;
  end;
end;

constructor TOperacionResultadosEnvioVerifactu.Create(
  const AResultados: IPersistenciaResultadoEnvioVerifactu;
  const AEstados: IPersistenciaEstadoEnvioVerifactu);
begin
  if not Assigned(AResultados) then
    raise EArgumentNilException.Create('AResultados');
  if not Assigned(AEstados) then
    raise EArgumentNilException.Create('AEstados');
  inherited Create;
  FResultados := AResultados;
  FEstados := AEstados;
end;

function TOperacionResultadosEnvioVerifactu.GuardarEnvioOk(
  const AEntrada: TEntradaResultadoEnvioVerifactu): Boolean;
var
  oPlan: TPlanResultadoEnvioVerifactu;
begin
  // El procesador conserva la transacción que agrupa todos estos pasos.
  Result := not FEstados.EstaColaEnviada(AEntrada.IdCola);
  if Result then
  begin
    oPlan := CrearPlanResultadoEnvioVerifactu(AEntrada);
    // El SII no encadena: fza_verifactu_cadena no cambia
    if not SameText(AEntrada.Resultado.Sistema, cSistemaColaSii) then
      FResultados.ActualizarCadena(AEntrada);
    FResultados.GuardarResultado(AEntrada, oPlan);
    FEstados.ActualizarFactura(AEntrada, oPlan);
    FEstados.MarcarColaEnviada(AEntrada);
  end;
end;

procedure TOperacionResultadosEnvioVerifactu.GuardarEnvioError(
  const AEntrada: TEntradaErrorEnvioVerifactu);
var
  oPlan: TPlanErrorEnvioVerifactu;
begin
  oPlan := CrearPlanErrorEnvioVerifactu(AEntrada);
  FEstados.GuardarError(AEntrada, oPlan);
end;

end.
