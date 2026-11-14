{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCajaOpeEntradaVcl                                       }
{    Tipo:       Servicio VCL                                                 }
{ Versión:       1.0.0                                                        }
{   Fecha:       06/08/2026                                                   }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Compone los puertos de entrada de caja con dependencias explícitas.      }
{******************************************************************************}
unit inMtoCajaOpeEntradaVcl;

interface

uses
  Data.DB,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Uni,
  cxGridDBTableView,
  inLibArticulosValidadorIntf,
  inLibCajaEntradaIntf,
  inLibFacturas,
  inLibFacturasLecturasIntf,
  inMtoCajaEntradaVcl;

type
  TAccionEstadoEntradaCajaVcl = reference to procedure(
    AEstado: Boolean);
  TAccionCodigoEntradaCajaOpeVcl = reference to procedure(
    const ACodigo: string);
  TConsultaCodigoEntradaCajaOpeVcl = reference to function(
    const ACodigo: string): Boolean;

  TContextoEntradaCajaOpeVcl = record
    Cabecera: TDataSet;
    Lineas: TDataSet;
    VistaLineas: TcxGridDBTableView;
    TemporizadorBusqueda: TTimer;
    BotonVendedor: TWinControl;
    Conexion: TUniConnection;
    RepositorioFacturas: IRepositorioLecturasFactura;
    ValidadorArticulos: IArticulosValidador;
    PermitirSku: TConsultaSkuEntradaCajaVcl;
    ConsolidarSku: TConsultaSkuEntradaCajaVcl;
    RellenarArticulo: TConsultaCodigoEntradaCajaOpeVcl;
    RellenarAtributos: TAccionCodigoEntradaCajaOpeVcl;
    CambiarResolviendo: TAccionEstadoEntradaCajaVcl;
    CambiarProcesando: TAccionEstadoEntradaCajaVcl;
    AsegurarLinea: TAccionEntradaCajaVcl;
    ActualizarTotal: TActualizarTotalFacturaEvent;
    // F-LOTEC-015: nil con los interruptores apagados.
    Trazabilidad: ITrazabilidadEntradaCaja;
    procedure Validar;
  end;

function CrearAplicacionEntradaCajaOpeVcl(
  const AContexto: TContextoEntradaCajaOpeVcl):
  IAplicacionEntradaCaja;

implementation

uses
  inLibMensajesVcl,
  System.SysUtils,
  Vcl.Dialogs,
  inLibCajaEntrada,
  inLibDevExp;

procedure TContextoEntradaCajaOpeVcl.Validar;
begin
  if not Assigned(Cabecera) then
    raise EArgumentNilException.Create('Cabecera');
  if not Assigned(Lineas) then
    raise EArgumentNilException.Create('Lineas');
  if not Assigned(VistaLineas) then
    raise EArgumentNilException.Create('VistaLineas');
  if not Assigned(TemporizadorBusqueda) then
    raise EArgumentNilException.Create('TemporizadorBusqueda');
  if not Assigned(BotonVendedor) then
    raise EArgumentNilException.Create('BotonVendedor');
  if not Assigned(ValidadorArticulos) then
    raise EArgumentNilException.Create('ValidadorArticulos');
end;

procedure PrepararLineaEntradaCaja(ADataSet: TDataSet);
begin
  if ADataSet.State = dsInsert then
  begin
    if Trim(ADataSet.FieldByName(
       'CODIGO_ART_FACLIN').AsString) <> '' then
    begin
      ADataSet.Post;
      ADataSet.Append;
    end;
  end
  else
  begin
    if ADataSet.State = dsEdit then
      ADataSet.Post;
    ADataSet.Append;
  end;
end;

procedure AplicarCodigoEntradaCaja(
  const AContexto: TContextoEntradaCajaOpeVcl;
  const ACodigo, ACodigoSku, ACodigoArticulo: string);
begin
  AContexto.CambiarResolviendo(True);
  try
    AContexto.RellenarArticulo(ACodigo);
  finally
    AContexto.CambiarResolviendo(False);
  end;
  if (Trim(ACodigoSku) <> '') and
     (ACodigoSku <> ACodigoArticulo) then
    AContexto.RellenarAtributos(ACodigoSku);
  if AContexto.Lineas.State in [dsInsert, dsEdit] then
    AContexto.Lineas.Post;
  GridRecalc(
    AContexto.Conexion,
    AContexto.RepositorioFacturas,
    nil,
    AContexto.VistaLineas,
    AContexto.Lineas,
    AContexto.Cabecera,
    AContexto.ActualizarTotal);
end;

procedure ConfigurarDisponibilidadEntrada(
  const AContexto: TContextoEntradaCajaOpeVcl;
  var AOperaciones: TOperacionesEntradaCajaVcl);
begin
  AOperaciones.Disponible :=
    function: Boolean
    begin
      Result := AContexto.Lineas.Active;
    end;
  AOperaciones.VendedorAsignado :=
    function: Boolean
    begin
      Result := Trim(AContexto.Cabecera.FieldByName(
        'CODIGO_CAJERO_FAC').AsString) <> '';
    end;
  AOperaciones.PermitirSku := AContexto.PermitirSku;
  AOperaciones.PrepararLinea :=
    procedure
    begin
      PrepararLineaEntradaCaja(AContexto.Lineas);
    end;
  AOperaciones.ConsolidarSku := AContexto.ConsolidarSku;
  AOperaciones.AplicarCodigo :=
    procedure(const ACodigo, ACodigoSku, ACodigoArticulo: string)
    begin
      AplicarCodigoEntradaCaja(
        AContexto,
        ACodigo,
        ACodigoSku,
        ACodigoArticulo);
    end;
end;

procedure ConfigurarCicloEntrada(
  const AContexto: TContextoEntradaCajaOpeVcl;
  var AOperaciones: TOperacionesEntradaCajaVcl);
begin
  AOperaciones.Iniciar :=
    procedure
    begin
      AContexto.CambiarProcesando(True);
    end;
  AOperaciones.Finalizar :=
    procedure
    begin
      AContexto.CambiarProcesando(False);
    end;
  AOperaciones.MostrarError :=
    procedure(const AMensaje: string)
    begin
      ShowMessage_fza(AMensaje);
    end;
  AOperaciones.EnfocarVendedor :=
    procedure
    begin
      if AContexto.BotonVendedor.CanFocus then
        AContexto.BotonVendedor.SetFocus;
    end;
end;

procedure ConfigurarVistaEntrada(
  const AContexto: TContextoEntradaCajaOpeVcl;
  var AOperaciones: TOperacionesEntradaCajaVcl);
begin
  AOperaciones.PrepararLectura :=
    procedure
    begin
      AContexto.TemporizadorBusqueda.Enabled := False;
      if AContexto.VistaLineas.Controller.
         EditingController.IsEditing then
      begin
        AContexto.VistaLineas.Controller.
          EditingController.HideEdit(False);
      end;
    end;
  AOperaciones.RefrescarConsolidacion :=
    procedure
    begin
      AContexto.VistaLineas.DataController.UpdateItems(True);
    end;
  AOperaciones.PrepararSiguiente :=
    procedure
    begin
      AContexto.AsegurarLinea();
      AContexto.VistaLineas.Controller.EditingController.ShowEdit;
    end;
end;

function CrearAplicacionEntradaCajaOpeVcl(
  const AContexto: TContextoEntradaCajaOpeVcl):
  IAplicacionEntradaCaja;
var
  oOperaciones: TOperacionesEntradaCajaVcl;
  oPuertoOperaciones: IOperacionesEntradaCaja;
  oVista: IVistaEntradaCaja;
begin
  AContexto.Validar;
  oOperaciones := Default(TOperacionesEntradaCajaVcl);
  ConfigurarDisponibilidadEntrada(AContexto, oOperaciones);
  ConfigurarCicloEntrada(AContexto, oOperaciones);
  ConfigurarVistaEntrada(AContexto, oOperaciones);
  CrearPuertosEntradaCajaVcl(
    oOperaciones,
    oPuertoOperaciones,
    oVista);
  Result := CrearAplicacionEntradaCaja(
    AContexto.ValidadorArticulos,
    oPuertoOperaciones,
    oVista,
    AContexto.Trazabilidad);
end;

end.
