{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasReapertura                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Reabre un borrador fiscal pendiente y aparca su alta en la cola.          }
{    La persistencia entra por IRepositorioReaperturaFactura.                  }
{******************************************************************************}
unit inLibFacturasReapertura;

interface

uses
  Uni, inLibParametrosIntf, inLibFacturasServiciosIntf,
  inLibFacturasPersistenciaIntf, inLibVentasWsColaIntf, inLibLogIntf;

function CrearServicioReaperturaBorrador(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  AConexion: TUniConnection;
  const ARepositorio: IRepositorioReaperturaFactura;
  const ARepositorioVentasWs: IAltaVentasWsCola;
  const ARegistroLog: IRegistroLog
): IServicioReaperturaBorrador;

implementation

uses
  inLibFormatoDocumentoLecturasIntf,
  System.SysUtils, inLibMsgFacturas,
  inLibVerifactu, inLibVentasWsCola;

type
  TServicioReaperturaBorrador = class(
    TInterfacedObject,
    IServicioReaperturaBorrador)
  private
    FParametrosApp: IParametrosAplicacion;
    FParametrosCaja: IParametrosCaja;
    FConexion: TUniConnection;
    FRepositorio: IRepositorioReaperturaFactura;
    FRepositorioVentasWs: IAltaVentasWsCola;
    FRegistroLog: IRegistroLog;
    function Evaluar(
      const ASerie, ANumero: string;
      const ADatos: TDatosFacturaReapertura
    ): TResultadoOperacionFactura;
    procedure RegistrarEventos(
      const ASerie, ANumero, AUsuario: string);
  public
    constructor Create(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      AConexion: TUniConnection;
      const ARepositorio: IRepositorioReaperturaFactura;
      const ARepositorioVentasWs: IAltaVentasWsCola;
      const ARegistroLog: IRegistroLog);
    function Validar(
      const ASerie, ANumero: string
    ): TResultadoOperacionFactura;
    procedure Reabrir(
      const ASerie, ANumero, AUsuario: string);
  end;

constructor TServicioReaperturaBorrador.Create(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  AConexion: TUniConnection;
  const ARepositorio: IRepositorioReaperturaFactura;
  const ARepositorioVentasWs: IAltaVentasWsCola;
  const ARegistroLog: IRegistroLog);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('ARepositorio');
  FParametrosApp := AParametrosApp;
  FParametrosCaja := AParametrosCaja;
  FConexion := AConexion;
  FRepositorio := ARepositorio;
  FRepositorioVentasWs := ARepositorioVentasWs;
  FRegistroLog := ARegistroLog;
end;

function TServicioReaperturaBorrador.Evaluar(
  const ASerie, ANumero: string;
  const ADatos: TDatosFacturaReapertura
): TResultadoOperacionFactura;
begin
  if not ADatos.Encontrada then
  begin
    Result := TResultadoOperacionFactura.Error(
      SErrorBorradorListaNoSeleccionado);
  end
  else
  begin
    Result := EvaluarReaperturaBorrador(
      ASerie,
      ANumero,
      ADatos.Fase,
      ADatos.EstadoCola,
      ADatos.Consolidada,
      FormatoDocumentoFacturaDelProveedor(
        FRepositorio, ASerie, ANumero));
  end;
end;

procedure TServicioReaperturaBorrador.RegistrarEventos(
  const ASerie, ANumero, AUsuario: string);
begin
  RegistrarEventoVerifactu(
    FParametrosApp,
    FConexion,
    AUsuario,
    cEventoVerifactuInfo,
    'Lanzamiento anulado: borrador devuelto a BORRADOR',
    '',
    ASerie,
    ANumero);
  TVentasWsCola.RegistrarEventoSeguro(
    FParametrosCaja,
    FRepositorioVentasWs,
    AUsuario,
    'VENTA_REABIERTA',
    ASerie,
    ANumero,
    FRegistroLog);
end;

function TServicioReaperturaBorrador.Validar(
  const ASerie, ANumero: string
): TResultadoOperacionFactura;
var
  Datos: TDatosFacturaReapertura;
begin
  Datos := FRepositorio.CargarDatosReapertura(ASerie, ANumero, False);
  Result := Evaluar(ASerie, ANumero, Datos);
end;

procedure TServicioReaperturaBorrador.Reabrir(
  const ASerie, ANumero, AUsuario: string);
var
  Datos: TDatosFacturaReapertura;
  ResultadoValidacion: TResultadoOperacionFactura;
  TransaccionPropia: Boolean;
begin
  TransaccionPropia := not FConexion.InTransaction;
  if TransaccionPropia then
    FConexion.StartTransaction;
  try
    Datos := FRepositorio.CargarDatosReapertura(ASerie, ANumero, True);
    ResultadoValidacion := Evaluar(ASerie, ANumero, Datos);
    if not ResultadoValidacion.Exito then
    begin
      raise EReaperturaBorrador.Create(
        ResultadoValidacion.Mensaje);
    end;
    if Datos.EstadoCola <> '' then
      FRepositorio.AparcarAltaEnCola(ASerie, ANumero, AUsuario);
    FRepositorio.MarcarComoBorrador(ASerie, ANumero, AUsuario);
    if TransaccionPropia and FConexion.InTransaction then
      FConexion.Commit;
  except
    if TransaccionPropia and FConexion.InTransaction then
      FConexion.Rollback;
    raise;
  end;
  RegistrarEventos(ASerie, ANumero, AUsuario);
end;

function CrearServicioReaperturaBorrador(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  AConexion: TUniConnection;
  const ARepositorio: IRepositorioReaperturaFactura;
  const ARepositorioVentasWs: IAltaVentasWsCola;
  const ARegistroLog: IRegistroLog
): IServicioReaperturaBorrador;
begin
  Result := TServicioReaperturaBorrador.Create(
    AParametrosApp,
    AParametrosCaja,
    AConexion,
    ARepositorio,
    ARepositorioVentasWs,
    ARegistroLog);
end;

end.
