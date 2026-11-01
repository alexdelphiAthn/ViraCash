{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGarantias                                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Dominio de las garantías por número de serie (F-LOTEC-021): estados y     }
{    resoluciones de una reclamación, sus fases (recepción, envío al          }
{    fabricante, recepción del fabricante y entrega), el medio de transporte  }
{    y lo que se sabe de una serie vendida.                                   }
{    Sin VCL ni SQL.                                                           }
{******************************************************************************}
unit inLibGarantias;

interface

const
  // Valores de ESTADO_GAR.
  ESTADO_GARANTIA_ABIERTA = 'ABIERTA';
  ESTADO_GARANTIA_EN_SAT = 'EN_SAT';
  ESTADO_GARANTIA_RESUELTA = 'RESUELTA';
  ESTADO_GARANTIA_RECHAZADA = 'RECHAZADA';
  // Filtro de la pantalla: abiertas y en SAT.
  FILTRO_GARANTIA_PENDIENTES = 'PENDIENTES';

  // Valores de RESOLUCION_GAR.
  RESOLUCION_GARANTIA_REPARADA = 'REPARADA';
  RESOLUCION_GARANTIA_SUSTITUIDA = 'SUSTITUIDA';
  RESOLUCION_GARANTIA_ABONADA = 'ABONADA';

  // Fases de la reclamación (FASE_GAR calculada: la última con fecha);
  // '' = aún sin recepción anotada.
  FASE_GARANTIA_RECEPCION = 'RECEPCION';
  FASE_GARANTIA_ENVIO_FAB = 'ENVIO_FAB';
  FASE_GARANTIA_RECEPCION_FAB = 'RECEPCION_FAB';
  FASE_GARANTIA_ENTREGA_CLI = 'ENTREGA_CLI';

  // Valores de MEDIO_RECEPCION_GAR y MEDIO_ENTREGA_CLI_GAR: el aparato
  // va y viene en mano por la tienda o por agencia de transporte.
  MEDIO_GARANTIA_TIENDA = 'TIENDA';
  MEDIO_GARANTIA_AGENCIA = 'AGENCIA';

type
  // Una serie según PRC_FZA_GARANTIAS_DATOS_SERIE.
  TDatosSerieGarantia = record
    Encontrada: Boolean;
    Sku: string;
    Serie: string;
    Articulo: string;
    Descripcion: string;
    MesesGarantia: Integer;
    TieneMeses: Boolean;
    Vendida: Boolean;
    TipoDocVenta: string;
    SerieDocVenta: string;
    NumeroDocVenta: string;
    FechaVenta: TDateTime;
    Cliente: string;
    RazonSocialCliente: string;
    FechaFinGarantia: TDateTime;
    EnGarantia: Boolean;
    Devuelta: Boolean;
    AlmacenStock: string;
    AlmacenVenta: string;
    ReclamacionesAbiertas: Integer;
    function DocumentoVenta: string;
  end;

function EstadoGarantiaAbierto(const AEstado: string): Boolean;
function AlmacenRecepcionGarantia(const ADatos: TDatosSerieGarantia;
  const AAlmacenSesion: string): string;
// Texto traducido de ESTADO_GAR y RESOLUCION_GAR para las rejillas; un
// código desconocido se devuelve tal cual.
function TextoEstadoGarantia(const AEstado: string): string;
function TextoResolucionGarantia(const AResolucion: string): string;
function TextoFaseGarantia(const AFase: string): string;
function TextoMedioGarantia(const AMedio: string): string;
// Razón social del cliente o, en una venta sin cliente, «cliente de contado».
function ClienteVentaGarantia(const ARazonSocial: string): string;

implementation

uses
  System.SysUtils, inLibMsgGarantias;

function TDatosSerieGarantia.DocumentoVenta: string;
begin
  Result := Trim(TipoDocVenta + ' ' + SerieDocVenta);
  if NumeroDocVenta <> '' then
    Result := Result + '/' + NumeroDocVenta;
end;

function AlmacenRecepcionGarantia(const ADatos: TDatosSerieGarantia;
  const AAlmacenSesion: string): string;
begin
  Result := Trim(AAlmacenSesion);
  if (Result = '') and ADatos.Vendida and
     (Trim(ADatos.AlmacenVenta) <> '') then
    Result := Trim(ADatos.AlmacenVenta);
end;

function EstadoGarantiaAbierto(const AEstado: string): Boolean;
begin
  Result := (AEstado = ESTADO_GARANTIA_ABIERTA) or
    (AEstado = ESTADO_GARANTIA_EN_SAT);
end;

function TextoEstadoGarantia(const AEstado: string): string;
begin
  if AEstado = ESTADO_GARANTIA_ABIERTA then
    Result := SCaptionGarantiaAbierta
  else if AEstado = ESTADO_GARANTIA_EN_SAT then
    Result := SCaptionGarantiaEnSat
  else if AEstado = ESTADO_GARANTIA_RESUELTA then
    Result := SCaptionGarantiaResuelta
  else if AEstado = ESTADO_GARANTIA_RECHAZADA then
    Result := SCaptionGarantiaRechazada
  else
    Result := AEstado;
end;

function TextoResolucionGarantia(const AResolucion: string): string;
begin
  if AResolucion = RESOLUCION_GARANTIA_REPARADA then
    Result := SCaptionGarantiaReparada
  else if AResolucion = RESOLUCION_GARANTIA_SUSTITUIDA then
    Result := SCaptionGarantiaSustituida
  else if AResolucion = RESOLUCION_GARANTIA_ABONADA then
    Result := SCaptionGarantiaAbonada
  else
    Result := AResolucion;
end;

function TextoFaseGarantia(const AFase: string): string;
begin
  if AFase = FASE_GARANTIA_RECEPCION then
    Result := SCaptionFaseRecepcion
  else if AFase = FASE_GARANTIA_ENVIO_FAB then
    Result := SCaptionFaseEnvioFabricante
  else if AFase = FASE_GARANTIA_RECEPCION_FAB then
    Result := SCaptionFaseRecepcionFabricante
  else if AFase = FASE_GARANTIA_ENTREGA_CLI then
    Result := SCaptionFaseEntregaCliente
  else
    Result := AFase;
end;

function TextoMedioGarantia(const AMedio: string): string;
begin
  if AMedio = MEDIO_GARANTIA_TIENDA then
    Result := SCaptionMedioGarantiaTienda
  else if AMedio = MEDIO_GARANTIA_AGENCIA then
    Result := SCaptionMedioGarantiaAgencia
  else
    Result := AMedio;
end;

function ClienteVentaGarantia(const ARazonSocial: string): string;
begin
  Result := Trim(ARazonSocial);
  if Result = '' then
    Result := SClienteContadoGarantia;
end;

end.
