{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataCajaUnidadTrabajo                                      }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adapta la transacción UniDAC de caja a la unidad de trabajo de venta.     }
{******************************************************************************}
unit UniDataCajaUnidadTrabajo;

interface

uses
  Data.DB, System.Variants, UniDataCaja, inLibCajaVentaIntf;

type
  TUnidadTrabajoVentaCajaUniDAC = class(
    TInterfacedObject,
    IUnidadTrabajoVentaCaja)
  private
    FDatosCaja: TdmCajaOpe;
    procedure ReactivarControles(ADataSet: TDataSet);
    procedure RestaurarVenta(const ACabecera, ALineas: OleVariant);
    procedure RecuperarConexion;
    function GrabarSolicitud(const ASolicitud: TSolicitudGrabacionVenta
      ): TResultadoPersistenciaVentaCaja;
    procedure CompletarResultado(var AResultado:
      TResultadoPersistenciaVentaCaja);
  public
    constructor Create(ADatosCaja: TdmCajaOpe);
    function Ejecutar(
      const ASolicitud: TSolicitudGrabacionVenta
    ): TResultadoPersistenciaVentaCaja;
  end;

implementation

uses
  System.SysUtils, inLibErroresBBDD, inLibMsgCaja,
  UniDataNumeracionDocumentos;

constructor TUnidadTrabajoVentaCajaUniDAC.Create(
  ADatosCaja: TdmCajaOpe);
begin
  inherited Create;
  if not Assigned(ADatosCaja) then
    raise EArgumentNilException.Create('Falta el data module de caja.');
  FDatosCaja := ADatosCaja;
end;

procedure TUnidadTrabajoVentaCajaUniDAC.ReactivarControles(
  ADataSet: TDataSet);
begin
  try
    ADataSet.EnableControls;
  except
    on E: EErrorBBDD do
      // La venta ya está restaurada. Un refresco que consulte el servidor
      // caído no debe sustituir el aviso del cobro ni impedir la reactivación.
      FDatosCaja.RegistroLog.RegistrarError(
        'No se pudo refrescar la venta restaurada: ' + E.Message);
  end;
end;

procedure TUnidadTrabajoVentaCajaUniDAC.RestaurarVenta(
  const ACabecera, ALineas: OleVariant);
begin
  FDatosCaja.cdsCabecera.DisableControls;
  FDatosCaja.cdsLineas.DisableControls;
  try
    // No publicar una cabecera restaurada junto a líneas a medio restaurar.
    // Los eventos de rejilla pueden consultar BBDD mientras se notifican.
    FDatosCaja.cdsCabecera.Data := ACabecera;
    FDatosCaja.cdsLineas.Data := ALineas;
  finally
    try
      ReactivarControles(FDatosCaja.cdsLineas);
    finally
      ReactivarControles(FDatosCaja.cdsCabecera);
    end;
  end;
end;

procedure TUnidadTrabajoVentaCajaUniDAC.RecuperarConexion;
begin
  // Eliminar la sesión muerta antes de Disconnect evita devolverla al pool.
  try
    FDatosCaja.Conexion.RemoveFromPool;
    FDatosCaja.Conexion.Disconnect;
    FDatosCaja.Conexion.Connect;
  except
    on E: Exception do
      FDatosCaja.RegistroLog.RegistrarError(
        'No se pudo recuperar la conexión de caja: ' + E.Message);
  end;
end;

function TUnidadTrabajoVentaCajaUniDAC.GrabarSolicitud(
  const ASolicitud: TSolicitudGrabacionVenta
): TResultadoPersistenciaVentaCaja;
begin
  Result := Default(TResultadoPersistenciaVentaCaja);
  Result.Grabada := FDatosCaja.GrabarFacturaSimplificada(
    ASolicitud.CodigoEmpresa,
    ASolicitud.CodigoAlmacen,
    ASolicitud.CodigoCaja,
    ASolicitud.SerieDocumento,
    ASolicitud.DatosCobro,
    ASolicitud.SerieDocumento,
    Result.NumeroOperacion,
    Result.CodigoValeGenerado,
    ASolicitud.TipoFactura,
    ASolicitud.FechaFactura,
    ASolicitud.FechaOperacion,
    ASolicitud.NumeroManual,
    ASolicitud.TipoRectificativa,
    ASolicitud.SerieRectificada,
    ASolicitud.NumeroRectificado,
    ASolicitud.TratamientoMovimientos,
    ASolicitud.MotivoDevolucion,
    ASolicitud.SerieOrigenDevolucion,
    ASolicitud.NumeroOrigenDevolucion,
    ASolicitud.EmpresaOrigenDevolucion,
    ASolicitud.AlmacenOrigenDevolucion, ASolicitud.ArqueosConfirmados,
    ASolicitud.PresupuestoEmpresa, ASolicitud.PresupuestoSerie,
    ASolicitud.PresupuestoNumero);
end;

procedure TUnidadTrabajoVentaCajaUniDAC.CompletarResultado(
  var AResultado: TResultadoPersistenciaVentaCaja);
begin
  AResultado.UltimaSerieFactura :=
    FDatosCaja.UltSerieFacturaGrabada;
  AResultado.UltimoNumeroFactura :=
    FDatosCaja.UltNumeroFacturaGrabada;
  AResultado.AvisoTrasGrabacion := FDatosCaja.AvisoTrasGrabacion;
  if FDatosCaja.cdsCabecera.Active and
     (not FDatosCaja.cdsCabecera.IsEmpty) then
  begin
    AResultado.SerieFacturaImpresion :=
      FDatosCaja.cdsCabecera.FieldByName('SERIE_FAC').AsString;
    AResultado.NumeroFacturaImpresion :=
      FDatosCaja.cdsCabecera.FieldByName('NUMERO_FAC').AsString;
  end;
end;

function TUnidadTrabajoVentaCajaUniDAC.Ejecutar(
  const ASolicitud: TSolicitudGrabacionVenta
): TResultadoPersistenciaVentaCaja;
var
  CabeceraOriginal: OleVariant;
  LineasOriginales: OleVariant;
  bFailoverOriginal: Boolean;
  RequiereFacturaOriginal: Boolean;
  Persistida: TResultadoPersistenciaVentaCaja;
begin
  if FDatosCaja.cdsCabecera.State in dsEditModes then
    FDatosCaja.cdsCabecera.Post;
  if FDatosCaja.cdsLineas.State in dsEditModes then
    FDatosCaja.cdsLineas.Post;
  RequiereFacturaOriginal := ASolicitud.DatosCobro.FRequiereFactura;
  CabeceraOriginal := FDatosCaja.cdsCabecera.Data;
  LineasOriginales := FDatosCaja.cdsLineas.Data;
  Result := Default(TResultadoPersistenciaVentaCaja);
  bFailoverOriginal := FDatosCaja.Conexion.Options.LocalFailover;
  // El cobro debe repetir toda su transacción, nunca solo la consulta que
  // falló. La recuperación ocurre después de abandonar la grabación.
  FDatosCaja.Conexion.Options.LocalFailover := False;
  try
    try
      EjecutarConEsperaBloqueoCorta(FDatosCaja.Conexion,
        procedure
        begin
          Persistida := GrabarSolicitud(ASolicitud);
        end, FDatosCaja.RegistroLog);
      Result := Persistida;
    except
      on E: EConexionPerdidaBBDD do
      begin
        try
          RecuperarConexion;
        finally
          try
            RestaurarVenta(CabeceraOriginal, LineasOriginales);
          finally
            ASolicitud.DatosCobro.FRequiereFactura := RequiereFacturaOriginal;
          end;
        end;
        if E.ConfirmacionIncierta then
          raise EGrabacionVentaCaja.Create(
            SErrorConfirmacionVentaCaja, False);
        raise EGrabacionVentaCaja.Create(
          Format(SErrorGuardarTicketCaja, [E.Message]));
      end;
      on E: Exception do
      begin
        try
          RestaurarVenta(CabeceraOriginal, LineasOriginales);
        finally
          ASolicitud.DatosCobro.FRequiereFactura := RequiereFacturaOriginal;
        end;
        if (E is EErrorBBDD) or (E is EValidacionBBDD) then
          raise EGrabacionVentaCaja.Create(
            Format(SErrorGuardarTicketCaja, [E.Message]));
        raise;
      end;
    end;
  finally
    FDatosCaja.Conexion.Options.LocalFailover := bFailoverOriginal;
  end;
  if Result.Grabada then
    CompletarResultado(Result);
end;

end.
