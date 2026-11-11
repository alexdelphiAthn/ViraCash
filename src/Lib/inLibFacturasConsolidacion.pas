{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasConsolidacion                                    }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Consolida factura y coordina fiscalidad, stock y transacción.             }
{    La persistencia entra por IRepositorioConsolidacionFactura.               }
{******************************************************************************}
unit inLibFacturasConsolidacion;

interface

uses
  inLibFacturasServiciosIntf, inLibEmisionFiscalIntf,
  inLibFacturasPersistenciaIntf, inLibFacturasRectificativaIntf;

// ARectificativa cierra el vínculo de las rectificativas creadas sin
// emitir (la original pasa a RECTIFICADA al consolidar).
function CrearCasoUsoConsolidacionFactura(
  const AUnidadTrabajo: IUnidadTrabajoFacturas;
  const ARepositorio: IRepositorioConsolidacionFactura;
  const AServicioEmision: IServicioEmisionFiscal;
  const AServicioMovimientos: IServicioMovimientosFactura;
  const ARectificativa: IServicioRectificativaFactura = nil;
  const AValidadorFiscal: IValidadorFiscalFactura = nil;
  const AFacturaRecibida: IServicioFacturaRecibidaInterna = nil
): ICasoUsoConsolidacionFactura;

implementation

uses
  inLibFormatoDocumentoLecturasIntf,
  System.SysUtils,
  inLibMsgFacturas, inLibMsgVentas,
  inLibPrestaShopColaSenal;

type
  TCasoUsoConsolidacionFactura = class(
    TInterfacedObject,
    ICasoUsoConsolidacionFactura)
  private
    FUnidadTrabajo: IUnidadTrabajoFacturas;
    FRepositorio: IRepositorioConsolidacionFactura;
    FServicioEmision: IServicioEmisionFiscal;
    FServicioMovimientos: IServicioMovimientosFactura;
    FRectificativa: IServicioRectificativaFactura;
    FValidadorFiscal: IValidadorFiscalFactura;
    FFacturaRecibida: IServicioFacturaRecibidaInterna;
    function RegistrarRecibida(
      const ASerie, ANumero, AUsuario: string): string;
    function EvaluarFiscal(
      const ADatos: TDatosFacturaConsolidacion
    ): TResultadoOperacionFactura;
    function Evaluar(
      const ASerie, ANumero: string;
      const ADatos: TDatosFacturaConsolidacion
    ): TResultadoOperacionFactura;
    function CrearSolicitudMovimientos(
      const ASerie, ANumero, AUsuario: string;
      const ADatos: TDatosFacturaConsolidacion
    ): TSolicitudMovimientosFactura;
  public
    constructor Create(
      const AUnidadTrabajo: IUnidadTrabajoFacturas;
      const ARepositorio: IRepositorioConsolidacionFactura;
      const AServicioEmision: IServicioEmisionFiscal;
      const AServicioMovimientos: IServicioMovimientosFactura;
      const ARectificativa: IServicioRectificativaFactura;
      const AValidadorFiscal: IValidadorFiscalFactura;
      const AFacturaRecibida: IServicioFacturaRecibidaInterna);
    function Validar(
      const ASerie, ANumero: string
    ): TResultadoOperacionFactura;
    function Consolidar(
      const ASerie, ANumero, AUsuario: string
    ): TResultadoConsolidacionFactura;
  end;

constructor TCasoUsoConsolidacionFactura.Create(
  const AUnidadTrabajo: IUnidadTrabajoFacturas;
  const ARepositorio: IRepositorioConsolidacionFactura;
  const AServicioEmision: IServicioEmisionFiscal;
  const AServicioMovimientos: IServicioMovimientosFactura;
  const ARectificativa: IServicioRectificativaFactura;
  const AValidadorFiscal: IValidadorFiscalFactura;
  const AFacturaRecibida: IServicioFacturaRecibidaInterna);
begin
  inherited Create;
  FFacturaRecibida := AFacturaRecibida;
  if not Assigned(AUnidadTrabajo) then
    raise EArgumentNilException.Create('AUnidadTrabajo');
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('ARepositorio');
  if not Assigned(AServicioEmision) then
    raise EArgumentNilException.Create('AServicioEmision');
  if not Assigned(AServicioMovimientos) then
    raise EArgumentNilException.Create('AServicioMovimientos');
  FUnidadTrabajo := AUnidadTrabajo;
  FRepositorio := ARepositorio;
  FServicioEmision := AServicioEmision;
  FServicioMovimientos := AServicioMovimientos;
  FRectificativa := ARectificativa;
  FValidadorFiscal := AValidadorFiscal;
end;

// FZ-ISSUE-322: la cuota de IVA de una operación que no lo repercute
// (exportación, intracomunitaria, ISP) solo se comprobaba al grabar la
// cabecera, y desde que se aplaza durante la edición de líneas una factura
// así llegaba a emitirse. Aquí se repite con los totales ya grabados.
function TCasoUsoConsolidacionFactura.EvaluarFiscal(
  const ADatos: TDatosFacturaConsolidacion
): TResultadoOperacionFactura;
var
  Solicitud: TSolicitudValidacionFiscalFactura;
begin
  Result := TResultadoOperacionFactura.Correcto;
  // FZ-ISSUE-859: las copias desde otros documentos pueden llegar sin
  // pasar por BeforePost. Consolidar exige el mismo pais que la edicion.
  if not SameText(Trim(ADatos.TipoFactura), 'SIMPLIFICADA') and
     (Trim(ADatos.CodigoPaisCliente) = '') then
    Result := TResultadoOperacionFactura.Error(
      SErrorPaisClienteEmpresaBorrador)
  else if Assigned(FValidadorFiscal) then
  begin
    Solicitud.TipoOperacion := ADatos.TipoOperacion;
    Solicitud.CodigoPaisCliente := ADatos.CodigoPaisCliente;
    Solicitud.NifCliente := ADatos.NifCliente;
    Solicitud.TotalImpuestos := ADatos.TotalImpuestos;
    try
      FValidadorFiscal.Validar(Solicitud);
    except
      on E: EValidacionFactura do
        Result := TResultadoOperacionFactura.Error(E.Message);
    end;
  end;
end;

function TCasoUsoConsolidacionFactura.Evaluar(
  const ASerie, ANumero: string;
  const ADatos: TDatosFacturaConsolidacion
): TResultadoOperacionFactura;
var
  ResultadoFiscal: TResultadoOperacionFactura;
  ValidadorRecibida: IPreparacionFacturaRecibidaInterna;
begin
  if not ADatos.Encontrada then
  begin
    Result := TResultadoOperacionFactura.Error(
      SErrorBorradorListaNoSeleccionado);
  end
  else
  begin
    Result := EvaluarConsolidacionFactura(
      ASerie,
      ANumero,
      ADatos.Fase,
      ADatos.TipoFactura,
      ADatos.NifCliente,
      ADatos.NumeroLineas,
      FormatoDocumentoFacturaDelProveedor(
        FRepositorio, ASerie, ANumero));
    if Result.Exito then
    begin
      ResultadoFiscal := EvaluarFiscal(ADatos);
      if not ResultadoFiscal.Exito then
        Result := ResultadoFiscal;
      if Result.Exito and Supports(FFacturaRecibida,
           IPreparacionFacturaRecibidaInterna, ValidadorRecibida) then
      begin
        try
          ValidadorRecibida.PrepararAntesDeEmitir(ASerie, ANumero);
        except
          on E: EConsolidacionFactura do
            Result := TResultadoOperacionFactura.Error(E.Message);
        end;
      end;
    end;
  end;
end;

function TCasoUsoConsolidacionFactura.CrearSolicitudMovimientos(
  const ASerie, ANumero, AUsuario: string;
  const ADatos: TDatosFacturaConsolidacion
): TSolicitudMovimientosFactura;
begin
  Result.Serie := ASerie;
  Result.Numero := ANumero;
  Result.Empresa := ADatos.Empresa;
  Result.Cliente := ADatos.Cliente;
  Result.Caja := ADatos.Caja;
  Result.NumeroOperacion := ADatos.NumeroOperacion;
  Result.Fecha := ADatos.Fecha;
  Result.Usuario := AUsuario;
end;

function TCasoUsoConsolidacionFactura.Validar(
  const ASerie, ANumero: string
): TResultadoOperacionFactura;
var
  Datos: TDatosFacturaConsolidacion;
begin
  Datos := FRepositorio.CargarDatosConsolidacion(
    ASerie,
    ANumero,
    False);
  Result := Evaluar(ASerie, ANumero, Datos);
end;

function TCasoUsoConsolidacionFactura.Consolidar(
  const ASerie, ANumero, AUsuario: string
): TResultadoConsolidacionFactura;
var
  Datos: TDatosFacturaConsolidacion;
  ResultadoValidacion: TResultadoOperacionFactura;
  ResultadoFiscal: TResultadoEmisionFiscal;
  Resultado: TResultadoConsolidacionFactura;
  SolicitudFiscal: TSolicitudEmisionFiscal;
  SolicitudMovimientos: TSolicitudMovimientosFactura;
begin
  Resultado := Default(TResultadoConsolidacionFactura);
  FUnidadTrabajo.Ejecutar(
    procedure
    begin
      Datos := FRepositorio.CargarDatosConsolidacion(
        ASerie,
        ANumero,
        True);
      ResultadoValidacion := Evaluar(ASerie, ANumero, Datos);
      if not ResultadoValidacion.Exito then
        raise EConsolidacionFactura.Create(
          ResultadoValidacion.Mensaje);
      SolicitudFiscal := TSolicitudEmisionFiscal.ParaConsolidacion(
        ASerie,
        ANumero,
        AUsuario);
      ResultadoFiscal := FServicioEmision.Emitir(SolicitudFiscal);
      Resultado.MensajeFiscal := ResultadoFiscal.Mensaje;
      // Una rectificativa creada sin emitir cierra ahora su vínculo: la
      // original pasa a RECTIFICADA y, en sustitución con reemplazo,
      // pierde sus movimientos antes de que se generen los nuevos.
      if Assigned(FRectificativa) and
         SameText(Datos.TipoFactura, 'RECTIFICATIVA') then
        FRectificativa.CompletarEmision(ASerie, ANumero, AUsuario);
      if FacturaDebeGenerarMovimientos(
           Datos.TipoFactura,
           Datos.MueveStock) then
      begin
        SolicitudMovimientos := CrearSolicitudMovimientos(
          ASerie,
          ANumero,
          AUsuario,
          Datos);
        Resultado.MovimientosGenerados :=
          FServicioMovimientos.GenerarSalidas(SolicitudMovimientos);
      end;
    end);
  if Resultado.MovimientosGenerados > 0 then
    SolicitarProcesadoPrestaShop;
  Resultado.MensajeRecibida := RegistrarRecibida(ASerie, ANumero, AUsuario);
  Result := Resultado;
end;

// FZ-ISSUE-358: fuera de la unidad de trabajo de la consolidación. La
// factura emitida ya es definitiva; si la recibida falla, se avisa y se
// puede registrar a mano (el cuadre de facturas internas la señala).
function TCasoUsoConsolidacionFactura.RegistrarRecibida(
  const ASerie, ANumero, AUsuario: string): string;
begin
  Result := '';
  if Assigned(FFacturaRecibida) then
  try
    Result := FFacturaRecibida.Registrar(ASerie, ANumero, AUsuario);
  except
    on E: Exception do
      Result := Format(SAvisoRecibidaInternaNoRegistrada, [E.Message]);
  end;
end;

function CrearCasoUsoConsolidacionFactura(
  const AUnidadTrabajo: IUnidadTrabajoFacturas;
  const ARepositorio: IRepositorioConsolidacionFactura;
  const AServicioEmision: IServicioEmisionFiscal;
  const AServicioMovimientos: IServicioMovimientosFactura;
  const ARectificativa: IServicioRectificativaFactura;
  const AValidadorFiscal: IValidadorFiscalFactura;
  const AFacturaRecibida: IServicioFacturaRecibidaInterna
): ICasoUsoConsolidacionFactura;
begin
  Result := TCasoUsoConsolidacionFactura.Create(
    AUnidadTrabajo,
    ARepositorio,
    AServicioEmision,
    AServicioMovimientos,
    ARectificativa,
    AValidadorFiscal,
    AFacturaRecibida);
end;

end.
