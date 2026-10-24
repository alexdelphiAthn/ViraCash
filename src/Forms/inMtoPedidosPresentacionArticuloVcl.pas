{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoPedidosPresentacionArticuloVcl                          }
{    Tipo:       Servicio VCL                                                 }
{ Versión:       1.0.0                                                        }
{   Fecha:       06/08/2026                                                   }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Aplica un artículo resuelto a una línea de pedido de venta.               }
{******************************************************************************}
unit inMtoPedidosPresentacionArticuloVcl;

interface

uses
  Data.DB,
  Uni,
  cxGridDBTableView,
  inLibArticulosResolverIntf,
  inLibArticulosValidadorIntf;

type
  TAccionArticuloPedidoVcl = reference to procedure;

  TContextoArticuloPedidoVcl = record
    Cabecera: TDataSet;
    Lineas: TDataSet;
    Conexion: TUniConnection;
    VistaLineas: TcxGridDBTableView;
    Resolver: IArticulosResolver;
    Validador: IArticulosValidador;
    AbrirBusquedaSku: TAccionArticuloPedidoVcl;
    procedure Validar;
  end;

procedure AplicarArticuloPedidoVcl(
  const AContexto: TContextoArticuloPedidoVcl;
  const ACodigoArticulo: string);

implementation

uses
  inLibMensajesVcl,
  System.Classes,
  System.SysUtils,
  System.UITypes,
  Vcl.Dialogs,
  UniDataImpuestosRepositorio,
  inLibVentasImpuestos;

procedure TContextoArticuloPedidoVcl.Validar;
begin
  if not Assigned(Cabecera) then
    raise EArgumentNilException.Create('Cabecera');
  if not Assigned(Lineas) then
    raise EArgumentNilException.Create('Lineas');
  if not Assigned(VistaLineas) then
    raise EArgumentNilException.Create('VistaLineas');
  if not Assigned(Resolver) then
    raise EArgumentNilException.Create('Resolver');
  if not Assigned(Validador) then
    raise EArgumentNilException.Create('Validador');
end;

procedure PrepararDataSetLineaPedido(ADataSet: TDataSet);
begin
  if ADataSet.IsEmpty then
    ADataSet.Append;
  if not (ADataSet.State in dsEditModes) then
    ADataSet.Edit;
end;

procedure ObtenerTarifaFechaPedido(
  const AContexto: TContextoArticuloPedidoVcl;
  out ATarifa: string;
  out AFecha: TDateTime);
begin
  ATarifa := AContexto.Cabecera.
    FieldByName('TARIFA_ARTICULO_CLIENTE_PED').AsString;
  AFecha := Date;
  if not AContexto.Cabecera.FieldByName('FECHA_PED').IsNull then
    AFecha := AContexto.Cabecera.
      FieldByName('FECHA_PED').AsDateTime;
end;

function ResolverPrecioArticuloPedido(
  const AContexto: TContextoArticuloPedidoVcl;
  const ADatos: TArticuloDatos;
  const ATarifa: string;
  AFecha: TDateTime): TArticuloPrecio;
begin
  if ADatos.RequiereSku then
  begin
    Result := AContexto.Resolver.ResolverPrecio(
      ADatos.CodigoArticulo,
      '',
      ATarifa,
      AFecha);
  end
  else
    Result := ADatos.PrecioPedido;
end;

procedure AsignarTextoLineaPedido(
  ADataSet: TDataSet;
  const ACampo, AValor: string);
var
  oCampo: TField;
begin
  oCampo := ADataSet.FindField(ACampo);
  if oCampo <> nil then
    oCampo.AsString := AValor;
end;

procedure AsignarNumeroLineaPedido(
  ADataSet: TDataSet;
  const ACampo: string;
  AValor: Double);
var
  oCampo: TField;
begin
  oCampo := ADataSet.FindField(ACampo);
  if oCampo <> nil then
    oCampo.AsFloat := AValor;
end;

procedure AplicarPrecioArticuloPedido(
  ADataSet: TDataSet;
  const ADatos: TArticuloDatos;
  const APrecio: TArticuloPrecio);
begin
  if ADatos.RequiereSku then
  begin
    AsignarNumeroLineaPedido(
      ADataSet, 'PRECIO_VENTA_SIVA_ARTICULO_PEDLIN', 0);
    AsignarNumeroLineaPedido(
      ADataSet, 'PRECIO_VENTA_CIVA_ARTICULO_PEDLIN', 0);
  end
  else if APrecio.EsImpIncl then
  begin
    AsignarNumeroLineaPedido(
      ADataSet,
      'PRECIO_VENTA_CIVA_ARTICULO_PEDLIN',
      APrecio.PrecioFinal);
    AsignarNumeroLineaPedido(
      ADataSet, 'PRECIO_VENTA_SIVA_ARTICULO_PEDLIN', 0);
  end
  else
  begin
    AsignarNumeroLineaPedido(
      ADataSet,
      'PRECIO_VENTA_SIVA_ARTICULO_PEDLIN',
      APrecio.PrecioFinal);
    AsignarNumeroLineaPedido(
      ADataSet, 'PRECIO_VENTA_CIVA_ARTICULO_PEDLIN', 0);
  end;
end;

procedure AplicarDatosArticuloPedido(
  ADataSet: TDataSet;
  const AResolucion: TArtResolucionEntrada;
  const ADatos: TArticuloDatos;
  const APrecio: TArticuloPrecio;
  const ATarifa: string);
begin
  AsignarTextoLineaPedido(
    ADataSet, 'CODIGO_ART_PEDLIN', ADatos.CodigoArticulo);
  AsignarTextoLineaPedido(
    ADataSet, 'CODIGOPRODPS_PEDLIN', ADatos.CodigoSku);
  if AResolucion.CodigoBarrasMatch <> '' then
  begin
    AsignarTextoLineaPedido(
      ADataSet, 'CODBAR_ART_PEDLIN', AResolucion.CodigoBarrasMatch);
  end;
  AsignarTextoLineaPedido(
    ADataSet, 'CODIGO_FAM_PEDLIN', ADatos.CodigoFamilia);
  AsignarTextoLineaPedido(
    ADataSet, 'NOMBRE_FAM_PEDLIN', ADatos.DescripcionFamilia);
  AsignarTextoLineaPedido(
    ADataSet,
    'DESCRIPCION_ARTICULO_PEDLIN',
    ADatos.DescripcionArticulo);
  AsignarTextoLineaPedido(
    ADataSet, 'TIPO_CANTIDAD_ARTICULO_PEDLIN', ADatos.TipoCantidad);
  AsignarTextoLineaPedido(
    ADataSet, 'TIPO_IVA_ARTICULO_PEDLIN', ADatos.TipoIVA);
  AsignarTextoLineaPedido(ADataSet, 'CODIGO_TAR_PEDLIN', ATarifa);
  if APrecio.EsImpIncl then
    AsignarTextoLineaPedido(ADataSet, 'ESIMP_INCL_TARIFA_PEDLIN', 'S')
  else
    AsignarTextoLineaPedido(ADataSet, 'ESIMP_INCL_TARIFA_PEDLIN', 'N');
  AplicarPrecioArticuloPedido(ADataSet, ADatos, APrecio);
end;

procedure PrepararFiscalidadLineaPedido(
  const AContexto: TContextoArticuloPedidoVcl);
begin
  PrepararLineaFiscalVenta(
    CrearLecturasImpuestos(AContexto.Conexion),
    AContexto.Cabecera,
    AContexto.Lineas,
    'PED',
    'PEDLIN',
    'TOTAL_PEDLIN');
end;

procedure EnfocarSkuPedido(
  const AContexto: TContextoArticuloPedidoVcl);
var
  oAbrirBusqueda: TAccionArticuloPedidoVcl;
  oColumnaSku: TcxGridDBColumn;
  oVista: TcxGridDBTableView;
begin
  oVista := AContexto.VistaLineas;
  oAbrirBusqueda := AContexto.AbrirBusquedaSku;
  oColumnaSku := oVista.GetColumnByFieldName('CODIGOPRODPS_PEDLIN');
  if oColumnaSku <> nil then
  begin
    oColumnaSku.Visible := True;
    TThread.ForceQueue(nil,
      procedure
      begin
        oVista.Controller.FocusedColumn := oColumnaSku;
        oVista.Controller.EditingController.ShowEdit;
        if Assigned(oAbrirBusqueda) then
          oAbrirBusqueda();
      end);
  end;
end;

procedure MostrarAvisoResolucion(const AMensaje: string);
begin
  if AMensaje <> '' then
    MessageDlg_fza(AMensaje, mtWarning, [mbOk], 0);
end;

procedure AplicarArticuloPedidoVcl(
  const AContexto: TContextoArticuloPedidoVcl;
  const ACodigoArticulo: string);
var
  dFecha: TDateTime;
  oDatos: TArticuloDatos;
  oPrecio: TArticuloPrecio;
  oResolucion: TArtResolucionEntrada;
  sTarifa: string;
begin
  AContexto.Validar;
  PrepararDataSetLineaPedido(AContexto.Lineas);
  ObtenerTarifaFechaPedido(AContexto, sTarifa, dFecha);
  oResolucion := AContexto.Validador.Resolver(ACodigoArticulo);
  if oResolucion.Encontrado then
  begin
    oDatos := AContexto.Resolver.ResolverDatos(
      oResolucion.CodigoArticulo,
      oResolucion.CodigoSku,
      sTarifa,
      dFecha);
    if oDatos.Encontrado then
    begin
      oPrecio := ResolverPrecioArticuloPedido(
        AContexto, oDatos, sTarifa, dFecha);
      AplicarDatosArticuloPedido(
        AContexto.Lineas, oResolucion, oDatos, oPrecio, sTarifa);
      PrepararFiscalidadLineaPedido(AContexto);
      if oDatos.RequiereSku then
        EnfocarSkuPedido(AContexto);
    end
    else
      MostrarAvisoResolucion(oDatos.Mensaje);
  end
  else
    MostrarAvisoResolucion(oResolucion.Mensaje);
end;

end.
