{******************************************************************************}
{                                                                              }
{  Modulo:       inLibInformesCajaPersistenciaIntf                            }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de datos de los informes historicos de caja.                       }
{******************************************************************************}
unit inLibInformesCajaPersistenciaIntf;

interface

uses
  Data.DB;

type
  TSolicitudInformeCaja = record
    Empresa: string;
    Almacen: string;
    Caja: string;
    FechaDesde: TDateTime;
    FechaHasta: TDateTime;
  end;

  TFormaPagoInformeCaja = record
    Codigo: string;
    Descripcion: string;
  end;

  TFormasPagoInformeCaja = TArray<TFormaPagoInformeCaja>;
  TCodigosFormaPagoInformeCaja = TArray<string>;

  TUbicacionInformeCaja = record
    Empresa: string;
    NombreEmpresa: string;
    Almacen: string;
    NombreAlmacen: string;
    Caja: string;
    NombreCaja: string;
  end;

  TUbicacionesInformeCaja = TArray<TUbicacionInformeCaja>;

  TSolicitudOperacionesVentaCaja = record
    FechaDesde: TDateTime;
    FechaHasta: TDateTime;
    Ubicaciones: TUbicacionesInformeCaja;
  end;

  TEstadosSolicitudTraspasoCaja = TArray<string>;

  TSolicitudTraspasosInformeCaja = record
    FechaDesde: TDateTime;
    FechaHasta: TDateTime;
    Ubicaciones: TUbicacionesInformeCaja;
    Estados: TEstadosSolicitudTraspasoCaja;
  end;

  IResultadoInformeCaja = interface
    ['{3074F219-3940-43AE-81B2-EA6A0ED3F167}']
    function DataSet: TDataSet;
  end;

  IRepositorioCuentaClientes = interface
    ['{5833951C-B4D3-4E2C-8D54-6E8C6BEAF726}']
    function ConsultarCuentaClientes(const ACliente: string;
      AResumen: Boolean): IResultadoInformeCaja;
  end;

  IRepositorioValesCaja = interface
    ['{9C40657A-CC5F-45F8-A066-A2C81A04736E}']
    function ConsultarValesPendientes(
      const AFiltro, APin: string
    ): IResultadoInformeCaja;
  end;

  IRepositorioInformesCaja = interface(IRepositorioValesCaja)
    ['{6302BC37-4503-4E4D-8D80-FF18D36A10C2}']
    function ConsultarArqueos(
      const ASolicitud: TSolicitudInformeCaja
    ): IResultadoInformeCaja;
    function ConsultarDepositos(
      const ASolicitud: TSolicitudInformeCaja
    ): IResultadoInformeCaja;
    function ConsultarOperaciones(
      const ASolicitud: TSolicitudInformeCaja
    ): IResultadoInformeCaja;
    // Una fila por tipo de operacion: NUMERO_OPERACIONES_INF y
    // IMPORTE_TOTAL_INF (informe A4 del historico de operaciones).
    function ConsultarTotalesOperaciones(
      const ASolicitud: TSolicitudInformeCaja
    ): IResultadoInformeCaja;
    function ListarFormasPago(
      const ASolicitud: TSolicitudInformeCaja
    ): TFormasPagoInformeCaja;
    function ConsultarPagos(
      const ASolicitud: TSolicitudInformeCaja;
      const ACodigosFormaPago: TCodigosFormaPagoInformeCaja
    ): IResultadoInformeCaja;
    // Una fila por forma de pago con los mismos filtros que ConsultarPagos:
    // NUMERO_PAGOS_INF, ENTREGADO_INF, CAMBIO_INF y NETO_INF.
    function ConsultarTotalesPagos(
      const ASolicitud: TSolicitudInformeCaja;
      const ACodigosFormaPago: TCodigosFormaPagoInformeCaja
    ): IResultadoInformeCaja;
    function ListarUbicaciones: TUbicacionesInformeCaja;
    function ConsultarOperacionesVenta(
      const ASolicitud: TSolicitudOperacionesVentaCaja
    ): IResultadoInformeCaja;
    function ListarEstadosSolicitudesTraspaso:
      TEstadosSolicitudTraspasoCaja;
    function ConsultarSolicitudesTraspaso(
      const ASolicitud: TSolicitudTraspasosInformeCaja
    ): IResultadoInformeCaja;
    function ConsultarArqueosHistorico(
      const AEmpresa, AAlmacen, ACaja: string
    ): IResultadoInformeCaja;
  end;

implementation

end.
