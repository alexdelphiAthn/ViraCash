{******************************************************************************}
{                                                                              }
{  Módulo:       inLibInformeLibrosIvaPersistenciaIntf                         }
{    Tipo:       Contrato de persistencia                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{                                                                              }
{  Descripción:                                                                }
{    Contrato del listado «Libros de IVA» (FZ-ISSUE-262): IVA repercutido      }
{    de facturas de venta y simplificadas, e IVA soportado de facturas de      }
{    compra, por factura y tramo de IVA, más su resumen por porcentaje.        }
{******************************************************************************}
unit inLibInformeLibrosIvaPersistenciaIntf;

interface

uses
  Data.DB;

const
  CLibroIvaRepercutido = 'REP';
  CLibroIvaSoportado = 'SOP';

type
  TCriteriosInformeLibrosIva = record
    FechaDesde: TDateTime;
    FechaHasta: TDateTime;
    // Códigos de empresa separados por comas; vacío = todas.
    Empresas: string;
    // REP, SOP o ambos separados por comas; vacío = los dos libros.
    Libros: string;
    // Ventas sin fase (FASE_FAC vacía): solo cuentan con el SIF sin
    // activar (modo SIN); con VERIFACTU o NO_VERIFACTU son borradores.
    IncluirSinFase: Boolean;
  end;

  TEmpresaInformeLibrosIva = record
    Codigo: string;
    RazonSocial: string;
  end;

  TEmpresasInformeLibrosIva = TArray<TEmpresaInformeLibrosIva>;

  // FZ-ISSUE-632: factura del libro de IVA soportado sin n.º de factura
  // del proveedor (DOC_EXTERNO_FACC y REF_PROVEEDOR_FACC vacíos).
  TFacturaSinNumeroProveedorLibrosIva = record
    Empresa: string;
    Serie: string;
    Numero: string;
    Fecha: TDateTime;
    Proveedor: string;
  end;

  TFacturasSinNumeroProveedorLibrosIva =
    TArray<TFacturaSinNumeroProveedorLibrosIva>;
  // FZ-ISSUE-733: misma forma para las facturas aún ABIERTAS (borradores).
  TFacturasAbiertasLibrosIva = TFacturasSinNumeroProveedorLibrosIva;

  IResultadoInformeLibrosIva = interface
    ['{3E0B7D52-61C4-4B8A-9C1F-8A2D5E7F4B10}']
    function Detalle: TDataSet;
    function Resumen: TDataSet;
    // FZ-ISSUE-372: una fila por empresa (SqlLiquidacionLibrosIva).
    function Liquidacion: TDataSet;
  end;

  IRepositorioInformeLibrosIva = interface
    ['{A4C2E9F1-7B35-4D60-8E2A-1F9C3B6D5E27}']
    function ListarEmpresas: TEmpresasInformeLibrosIva;
    function Preparar(
      const ACriterios: TCriteriosInformeLibrosIva
    ): IResultadoInformeLibrosIva;
    // FZ-ISSUE-632: facturas de compra del libro soportado (mismos
    // criterios que Preparar) sin n.º de factura del proveedor.
    function ListarFacturasSinNumeroProveedor(
      const ACriterios: TCriteriosInformeLibrosIva
    ): TFacturasSinNumeroProveedorLibrosIva;
    // FZ-ISSUE-733: facturas de compra del libro soportado que siguen
    // ABIERTAS (borradores sin cerrar). Entran en el libro igualmente.
    function ListarFacturasAbiertas(
      const ACriterios: TCriteriosInformeLibrosIva
    ): TFacturasAbiertasLibrosIva;
  end;

implementation

end.
