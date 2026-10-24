unit inLibInformeMovimientosVentasArticuloPersistenciaIntf;

interface

uses
  Data.DB;

type
  TOrdenMovVentasArt = (
    omvaArticuloDescripcion,
    omvaUnidadesEntrada,
    omvaImporteEntrada,
    omvaUnidadesVenta,
    omvaImporteVenta,
    omvaImporteCoste,
    omvaBeneficio,
    omvaPorcentajeBeneficio,
    omvaVentaEntrada,
    omvaPorcentajeVentaEntrada,
    omvaMargen1,
    omvaMargen2,
    omvaPorcentajeVendido,
    omvaPorcentajeVentas
  );

  TCriteriosInformeMovimientosVentasArticulo = record
    FechaDesde: TDateTime;
    FechaHasta: TDateTime;
    UsarInicioCompras: Boolean;
    InicioCompras: TDateTime;
    EntradasGlobales: Boolean;
    Almacenes: string;
    Familias: string;
    Proveedores: string;
    Temporadas: string;
    Articulos: string;
    Nivel1: string;
    Nivel2: string;
    Nivel3: string;
    NivelFamilia: Integer;
    SoloVentas: Boolean;
    ConImpuestos: Boolean;
    UsarOrden: Boolean;
    Orden: TOrdenMovVentasArt;
    OrdenDescendente: Boolean;
    // Tarifa por defecto de caja y empresa de la sesión: PVP y precio de
    // salida con IVA (script 744).
    Tarifa: string;
    Empresa: string;
  end;

  IResultadoInformeMovimientosVentasArticulo = interface
    ['{24EDBA9F-6521-4BFB-8028-30EDE48CDE81}']
    function DataSet: TDataSet;
  end;

  IRepositorioInformeMovimientosVentasArticulo = interface
    ['{16CF59D7-5FD5-4A2E-AFD8-06FF2F541A82}']
    function Preparar(
      const ACriterios: TCriteriosInformeMovimientosVentasArticulo
    ): IResultadoInformeMovimientosVentasArticulo;
  end;

implementation

end.
