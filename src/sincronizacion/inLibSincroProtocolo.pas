{******************************************************************************}
{                                                                              }
{  Módulo:       inLibSincroProtocolo                                          }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/11/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mensajes y contrato del servicio de sincronización cliente-servidor.      }
{    Subida: el terminal envía lotes de ventas y recibe un acuse por venta.    }
{    Bajada: el terminal pide novedades a partir de su cursor y confirma       }
{    hasta qué versión las ha aplicado.                                        }
{                                                                              }
{    Toda llamada puede fallar con ETransporteSincro antes o después de que    }
{    el servidor la procese. Por eso las tres operaciones son idempotentes.    }
{******************************************************************************}
unit inLibSincroProtocolo;

{$IFDEF FPC}{$MODE DELPHI}{$H+}{$ENDIF}

interface

uses
  {$IFDEF FPC}SysUtils{$ELSE}System.SysUtils{$ENDIF};

type
  // Fallo de comunicación: siempre reintentable. Un error de negocio
  // nunca se comunica así, sino con un acuse rvRechazada.
  ETransporteSincro = class(Exception);

  TResultadoVenta = (
    rvAceptada,   // primera recepción: el servidor la ha guardado
    rvRepetida,   // ya se había recibido: es un reenvío, no se duplica
    rvRechazada); // error de negocio permanente: no se debe reintentar

  TVentaSincro = record
    IdEvento: string;   // clave de idempotencia, generada en el terminal
    Terminal: string;
    Secuencia: Int64;   // correlativo local del terminal (control de huecos)
    Serie: string;
    Numero: Integer;
    Importe: Currency;
    Instante: Int64;
  end;
  TVentasSincro = array of TVentaSincro;

  TAckVenta = record
    IdEvento: string;
    Resultado: TResultadoVenta;
    Motivo: string;
  end;
  TAcksVenta = array of TAckVenta;

  TRespuestaVentas = record
    Acks: TAcksVenta;
  end;

  TTipoNovedad = (tnPrecio, tnBajaArticulo);

  TNovedadSincro = record
    Version: Int64;     // posición global y creciente en el registro
    Tipo: TTipoNovedad;
    Clave: string;      // código de artículo
    Valor: string;      // precio nuevo (vacío en una baja)
  end;
  TNovedadesSincro = array of TNovedadSincro;

  TRespuestaNovedades = record
    Novedades: TNovedadesSincro; // ordenadas por Version ascendente
    HayMas: Boolean;             // quedan más páginas por pedir
    UltimaVersion: Int64;        // última versión publicada en el servidor
  end;

  // Contrato del servicio. Correspondencia HTTP prevista:
  //   EnviarVentas       -> POST sincro/ventas.php
  //   PedirNovedades     -> GET  sincro/novedades.php?desde=N&maximo=M
  //   ConfirmarNovedades -> POST sincro/novedades_ack.php
  IServicioSincro = interface
    ['{8B0E4C55-3E1A-4F7B-9C55-2B7F1D6A4E10}']
    function EnviarVentas(const ATerminal: string;
      const AVentas: TVentasSincro): TRespuestaVentas;
    function PedirNovedades(const ATerminal: string;
      ADesdeVersion: Int64; AMaximo: Integer): TRespuestaNovedades;
    procedure ConfirmarNovedades(const ATerminal: string;
      AHastaVersion: Int64);
  end;

function ResultadoVentaTexto(AResultado: TResultadoVenta): string;
function TipoNovedadTexto(ATipo: TTipoNovedad): string;

implementation

function ResultadoVentaTexto(AResultado: TResultadoVenta): string;
begin
  case AResultado of
    rvAceptada: Result := 'ACEPTADA';
    rvRepetida: Result := 'REPETIDA';
  else
    Result := 'RECHAZADA';
  end;
end;

function TipoNovedadTexto(ATipo: TTipoNovedad): string;
begin
  case ATipo of
    tnPrecio: Result := 'PRECIO';
  else
    Result := 'BAJA_ARTICULO';
  end;
end;

end.
