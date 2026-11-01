{******************************************************************************}
{                                                                              }
{  Módulo:       inLibReparacionesIntf                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Contratos de persistencia de las reparaciones: catálogo (tipos de         }
{    servicio y ejecutores), expediente (alta, líneas, presupuesto, entrega    }
{    y anulación) y liquidaciones (pago a externos y cargo al fabricante).     }
{******************************************************************************}
unit inLibReparacionesIntf;

interface

uses
  System.SysUtils, inLibReparaciones;

type
  // La operación no cabe en la situación actual del expediente o de la
  // línea (otro puesto lo cambió o la pantalla estaba desfasada).
  EFaseReparacion = class(Exception);

  ICatalogoReparaciones = interface
    ['{3E7A9C21-5B84-4D0F-A6C3-81F2D4B7E590}']
    function Tipos(const ACategoria: string): TArray<TTipoServicio>;
    // Operarios activos y proveedores externos activos con su modo de
    // liquidación.
    function Ejecutores: TArray<TEjecutorServicio>;
  end;

  IRepositorioReparaciones = interface
    ['{9B1D7E46-2C35-4A8F-B0E9-5F6A3C2D8E17}']
    // Expediente y, si trae trabajo con ejecutor o precio, su primera
    // línea de mano de obra. Devuelve el número (ID_GAR).
    function Alta(const AReparacion: TReparacionNueva): Int64;
    // Alta (Id = 0) o cambio de una línea no empezada ni liquidada.
    function GuardarLinea(const ALinea: TLineaReparacion): Int64;
    procedure BorrarLinea(ALinea: Int64; const AUsuario: string);
    procedure EmpezarLinea(ALinea: Int64; AFecha: TDateTime;
      const AUsuario: string);
    // Conserva el resultado numérico por compatibilidad (0). Los costes
    // del externo se tramitan mediante albaranes de proveedor TALLER.
    function TerminarLinea(ALinea: Int64; AFecha: TDateTime;
      const AUsuario: string): Int64;
    // El externo se la vuelve a llevar: incidencia y nueva fecha de inicio.
    procedure DevolverLinea(ALinea: Int64; AFecha: TDateTime;
      const AIncidencia, AUsuario: string);
    procedure Presupuestar(AReparacion: Int64; ATotal: Currency;
      AFecha: TDateTime; const AUsuario: string);
    procedure ResponderPresupuesto(AReparacion: Int64; AAceptado: Boolean;
      AFecha: TDateTime; const AUsuario: string);
    procedure Entregar(AReparacion: Int64; AFecha: TDateTime;
      AEsCobrado: Boolean; const ASerieCobro, ANumeroCobro,
      AUsuario: string);
    procedure Anular(AReparacion: Int64; const AMotivo, AUsuario: string);
  end;

  ILiquidacionesReparaciones = interface
    ['{C4F2A86B-7D19-4E53-9A0C-2B8E6F1D3A75}']
    // PAGO: líneas del externo terminadas hasta AHasta y sin liquidar.
    // CARGO: costes de las reparaciones en garantía del fabricante
    // terminadas hasta AHasta y sin cargar. Id = 0 si no hay ninguna.
    function Liquidar(const ASentido, AEmpresa, AProveedor: string;
      AHasta: TDateTime; const AUsuario: string): TLiquidacionReparaciones;
    // Documento que la salda: FP (factura o autofactura de compra) para un
    // pago, FA (factura de venta) para un cargo.
    procedure EnlazarDocumento(ALiquidacion: Int64;
      const ATipoDoc, ASerie, ANumero, AUsuario: string);
    // Un cargo queda abonado cuando el fabricante lo paga.
    procedure AnotarAbono(ALiquidacion: Int64; AFecha: TDateTime;
      const AUsuario: string);
  end;

implementation

end.
