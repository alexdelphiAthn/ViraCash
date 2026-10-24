{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasComposicion                                      }
{    Tipo:       Factoría                                                      }
{ Versión:       2.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Ensambla los servicios de factura a partir de piezas de dominio.         }
{                                                                              }
{    Los tres adaptadores de persistencia (repositorio de facturas,           }
{    resolutor de artículos y cola VERI*FACTU) llegan YA CONSTRUIDOS          }
{    desde la raíz de composición: esta unidad no conoce UniData*, que        }
{    es la dirección prohibida por LIBRO_DE_ESTILO_DELPHI.md 14.1.            }
{******************************************************************************}
unit inLibFacturasComposicion;

interface

uses
  Uni,
  inLibArticulosResolverIntf,
  inLibFacturasLecturasIntf,
  inLibFacturasPersistenciaIntf,
  inLibFacturasServiciosIntf,
  inLibVerifactuColaIntf;

function CrearServiciosFactura(
  AConexion: TUniConnection;
  const ARepositorio: IRepositorioFacturas;
  const ARepositorioLecturas: IRepositorioLecturasFactura;
  const APersistencia: TPersistenciaFacturas;
  const AArticulosResolver: IArticulosResolver;
  const AVerifactuCola: IServicioVerifactuCola
): TServiciosFactura;

implementation

uses
  inLibFacturasValidacionFiscal,
  inLibFacturasCalculo,
  inLibFacturasBorrado,
  inLibFacturasEfectos;

function CrearServiciosFactura(
  AConexion: TUniConnection;
  const ARepositorio: IRepositorioFacturas;
  const ARepositorioLecturas: IRepositorioLecturasFactura;
  const APersistencia: TPersistenciaFacturas;
  const AArticulosResolver: IArticulosResolver;
  const AVerifactuCola: IServicioVerifactuCola
): TServiciosFactura;
begin
  Result.Repositorio := ARepositorio;
  Result.ArticulosResolver := AArticulosResolver;
  Result.ValidadorFiscal :=
    TValidadorFiscalFactura.Create(ARepositorio);
  Result.Calculador := TCalculadorFactura.Create(
    AConexion, ARepositorioLecturas);
  Result.Borrado := TServicioBorradoFactura.Create(
    AConexion,
    APersistencia.Borrado,
    AVerifactuCola);
  Result.Efectos := TServicioEfectosFactura.Create(
    APersistencia.Efectos);
end;

end.
