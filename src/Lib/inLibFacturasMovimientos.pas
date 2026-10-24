{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasMovimientos                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Genera movimientos de salida de stock para facturas de venta.             }
{    La persistencia entra por IRepositorioMovimientosFactura.                 }
{******************************************************************************}
unit inLibFacturasMovimientos;

interface

uses
  Uni, inLibDocumentoIntf, inLibFacturasServiciosIntf,
  inLibFacturasPersistenciaIntf,
  inLibValoresAutomaticosPersistenciaIntf;

type
  TServicioMovimientosFactura = class(
    TInterfacedObject,
    IServicioMovimientosFactura)
  private
    FConexion: TUniConnection;
    FEstrategiaDocumento: IEstrategiaDocumento;
    FRepositorio: IRepositorioMovimientosFactura;
    FValoresAutomaticos: IRepositorioValoresAutomaticos;
  public
    constructor Create(
      AConexion: TUniConnection;
      const ARepositorio: IRepositorioMovimientosFactura;
      const AValoresAutomaticos: IRepositorioValoresAutomaticos);
    function GenerarSalidas(
      const ASolicitud: TSolicitudMovimientosFactura): Integer;
  end;

implementation

uses
  System.SysUtils,
  inLibDocumento,
  inLibMsgFacturas,
  inLibPrestaShopColaSenal,
  inLibValoresAutomaticos;

constructor TServicioMovimientosFactura.Create(
  AConexion: TUniConnection;
  const ARepositorio: IRepositorioMovimientosFactura;
  const AValoresAutomaticos: IRepositorioValoresAutomaticos);
begin
  inherited Create;
  FConexion := AConexion;
  FEstrategiaDocumento := CrearEstrategiaDocumento(
    CrearConfiguracionDocumento(tdFactura, sdVenta));
  FRepositorio := ARepositorio;
  FValoresAutomaticos := AValoresAutomaticos;
end;

function TServicioMovimientosFactura.GenerarSalidas(
  const ASolicitud: TSolicitudMovimientosFactura): Integer;
var
  Datos: TInsercionMovimientoFactura;
  Lineas: TLineasFacturaMovimientos;
  Linea: TLineaFacturaMovimiento;
  NumeroMovimiento: string;
  TransaccionPropia: Boolean;
begin
  Result := 0;
  TransaccionPropia := not FConexion.InTransaction;
  if TransaccionPropia then
    FConexion.StartTransaction;
  try
    Lineas := FRepositorio.CargarLineas(
      ASolicitud.Serie,
      ASolicitud.Numero);
    for Linea in Lineas do
    begin
      if (Linea.Sku <> '') and
         (Linea.Cantidad <> 0) then
      begin
        NumeroMovimiento := FRepositorio.BuscarMovimientoExistente(
          FEstrategiaDocumento.TipoDocumentoMovimientoStock,
          ASolicitud.Serie,
          ASolicitud.Numero,
          Linea.Linea);
        if NumeroMovimiento = '' then
        begin
          if Trim(Linea.Almacen) = '' then
            raise EConsolidacionFactura.CreateFmt(
              SErrorFacturaSinAlmacenStock,
              [ASolicitud.Serie, ASolicitud.Numero, Linea.Linea]);
          NumeroMovimiento := ObtenerSiguienteContador(
            FValoresAutomaticos,
            'MV',
            ASolicitud.Usuario);
          Datos.NumeroMovimiento := NumeroMovimiento;
          Datos.TipoDocumento :=
            FEstrategiaDocumento.TipoDocumentoMovimientoStock;
          // Una cantidad negativa devuelve mercancía al almacén.
          Datos.TipoMovimiento := TipoMovimientoStockLinea(
            FEstrategiaDocumento.TipoMovimientoStock, Linea.Cantidad);
          Datos.Serie := ASolicitud.Serie;
          Datos.Numero := ASolicitud.Numero;
          Datos.Linea := Linea.Linea;
          Datos.Empresa := ASolicitud.Empresa;
          Datos.Almacen := Linea.Almacen;
          Datos.Sku := Linea.Sku;
          Datos.Articulo := Linea.Articulo;
          Datos.Cantidad := Abs(Linea.Cantidad);
          Datos.Fecha := ASolicitud.Fecha;
          Datos.Usuario := ASolicitud.Usuario;
          Datos.NumeroOperacion := ASolicitud.NumeroOperacion;
          Datos.Caja := ASolicitud.Caja;
          Datos.Cliente := ASolicitud.Cliente;
          Datos.Lote := Linea.Lote;
          Datos.FechaCaducidad := Linea.FechaCaducidad;
          FRepositorio.InsertarMovimiento(Datos);
          Inc(Result);
        end;
        if (NumeroMovimiento <> '') and
           (Linea.NumeroMovimiento <> NumeroMovimiento) then
        begin
          FRepositorio.ActualizarLineaMovimiento(
            ASolicitud.Serie,
            ASolicitud.Numero,
            Linea.Linea,
            NumeroMovimiento,
            ASolicitud.Usuario);
        end;
      end;
    end;
    if Result > 0 then
      FRepositorio.RecalcularDocumento(
        FEstrategiaDocumento.TipoDocumentoMovimientoStock,
        ASolicitud.Serie,
        ASolicitud.Numero);
    if TransaccionPropia then
    begin
      FConexion.Commit;
      if Result > 0 then
        SolicitarProcesadoPrestaShop;
    end;
  except
    if TransaccionPropia and FConexion.InTransaction then
      FConexion.Rollback;
    raise;
  end;
end;

end.
