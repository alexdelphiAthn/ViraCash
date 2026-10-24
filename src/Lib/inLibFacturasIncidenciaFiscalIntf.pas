{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasIncidenciaFiscalIntf                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos para resolver registros VERI*FACTU aceptados con errores.       }
{******************************************************************************}
unit inLibFacturasIncidenciaFiscalIntf;

interface

type
  TTipoResolucionIncidenciaFiscal = (
    trifSubsanarRegistro,
    trifRectificarFactura);
  TDatosClienteIncidenciaFiscal = record
    Codigo: string;
    RazonSocial: string;
    Nif: string;
  end;
  TDatosIncidenciaFiscal = record
    FormatoDocumento: string;
    Serie: string;
    Numero: string;
    TipoFactura: string;
    CodigoEmpresa: string;
    EstadoRegistro: string;
    EstadoSubsanacion: string;
    CodigoError: string;
    DescripcionError: string;
    Cliente: TDatosClienteIncidenciaFiscal;
  end;
  TSolicitudResolucionIncidenciaFiscal = record
    Serie: string;
    Numero: string;
    TipoResolucion: TTipoResolucionIncidenciaFiscal;
    Motivo: string;
    CodigoClienteCorrecto: string;
    SerieRectificativa: string;
    FechaRectificativa: TDateTime;
  end;
  TResultadoResolucionIncidenciaFiscal = record
    EsCorrecto: Boolean;
    Mensaje: string;
    SerieRectificativa: string;
    NumeroRectificativa: string;
  end;
  IRepositorioIncidenciaFiscalFactura = interface
    ['{86CBE18C-A65E-42D5-847A-B89BD1FB7745}']
    function CargarIncidencia(
      const ASerie, ANumero: string): TDatosIncidenciaFiscal;
    function CargarCliente(
      const ACodigoCliente: string): TDatosClienteIncidenciaFiscal;
    function CrearRectificativaR4(
      const ASolicitud: TSolicitudResolucionIncidenciaFiscal;
      const AUsuario: string): string;
  end;
  IServicioIncidenciaFiscalFactura = interface
    ['{A52E1139-A7CE-42FB-80D5-A4DF81AF1E66}']
    function CargarIncidencia(
      const ASerie, ANumero: string): TDatosIncidenciaFiscal;
    function CargarCliente(
      const ACodigoCliente: string): TDatosClienteIncidenciaFiscal;
    function Resolver(
      const ASolicitud: TSolicitudResolucionIncidenciaFiscal):
      TResultadoResolucionIncidenciaFiscal;
  end;

implementation

end.
