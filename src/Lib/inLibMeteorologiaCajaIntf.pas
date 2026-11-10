{******************************************************************************}
{                                                                              }
{  Módulo: inLibMeteorologiaCajaIntf                                           }
{  Tipo: Librería                                                              }
{  Versión: 1.0.0                                                              }
{  Fecha: 12/11/2026                                                           }
{  Autor: Alejandro Laorden Hidalgo                                            }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción: Consulta y presentación del tiempo diario de la tienda.        }
{******************************************************************************}
unit inLibMeteorologiaCajaIntf;

interface

uses
  System.SysUtils;

type
  TValorMeteorologiaCaja = record
    TieneValor: Boolean;
    Valor: Double;
  end;

  TUbicacionMeteorologiaCaja = record
    Empresa: string;
    Almacen: string;
    Ciudad: string;
    CodigoPostal: string;
  end;

  TParteMeteorologiaCaja = record
    Fecha: TDateTime;
    InstanteConsultaUtc: TDateTime;
    Ciudad: string;
    ZonaHoraria: string;
    Latitud: Double;
    Longitud: Double;
    Temperatura: TValorMeteorologiaCaja;
    Minima: TValorMeteorologiaCaja;
    Maxima: TValorMeteorologiaCaja;
    Nubes: TValorMeteorologiaCaja;
    Lluvia: TValorMeteorologiaCaja;
    CodigoTiempo: TValorMeteorologiaCaja;
    RespuestaJson: string;
    TipoDato: string;
  end;
  TPartesMeteorologiaCaja = TArray<TParteMeteorologiaCaja>;

  IRepositorioMeteorologiaCaja = interface
    ['{C74C370C-F015-448D-A51F-9BAC5891F517}']
    function LeerUbicacion(const AEmpresa, AAlmacen: string):
      TUbicacionMeteorologiaCaja;
    procedure Guardar(const AUbicacion: TUbicacionMeteorologiaCaja;
      const AParte: TParteMeteorologiaCaja);
  end;

  IRepositorioObservacionesCaja = interface
    ['{B2B18022-6510-450B-B057-672DB34B9520}']
    function LeerObservaciones(const AEmpresa, AAlmacen: string;
      AFecha: TDateTime): string;
    procedure GuardarObservaciones(const AEmpresa, AAlmacen: string;
      AFecha: TDateTime; const ATexto, AUsuario: string);
  end;

  IServicioMeteorologiaCaja = interface
    ['{F645B331-1DC5-47CE-B255-3E820059F092}']
    function ConsultarHoy(const AUbicacion: TUbicacionMeteorologiaCaja):
      TParteMeteorologiaCaja;
    function ConsultarHistorico(const AUbicacion: TUbicacionMeteorologiaCaja;
      ADesde, AHasta: TDateTime; const ACancelar: TFunc<Boolean> = nil):
      TPartesMeteorologiaCaja;
  end;

implementation

end.
