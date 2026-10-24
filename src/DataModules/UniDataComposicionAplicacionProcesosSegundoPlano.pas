{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataComposicionAplicacionProcesosSegundoPlano             }
{    Tipo:       Composición                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       25/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Subraíz de composición que coordina el ciclo de vida de los procesos      }
{    Verifactu, VentasWs y PrestaShop ejecutados en segundo plano.             }
{******************************************************************************}
unit UniDataComposicionAplicacionProcesosSegundoPlano;

interface

uses
  inLibConexionesIntf,
  inLibContextoSesionIntf,
  inLibParametrosIntf,
  inLibLogIntf,
  inLibPrestaShopCierre, inLibEstadoColasIntf;

type
  TProcesosSegundoPlanoAplicacion = class
  private
    FConexiones: IServicioConexiones;
    FContextoSesion: IContextoSesionAplicacion;
    FParametrosApp: IParametrosAplicacion;
    FParametrosCaja: IParametrosCaja;
    FRegistroLog: IRegistroLog;
    FVentasWsCola: TObject;
    FPrestaShopCola: TObject;
    FIniciados: Boolean;
    FEstados: array[TTipoColaEstado] of IEstadoCola;
  public
    constructor Create(
      const AConexiones: IServicioConexiones;
      const AContextoSesion: IContextoSesionAplicacion;
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const ARegistroLog: IRegistroLog);
    destructor Destroy; override;
    function LeerEstadosColas: TEstadosColas;
    procedure Iniciar;
    function PrepararCierrePrestaShop(
      const AConsultarDecision:
        TConsultarDecisionCierrePrestaShop): Boolean;
    procedure Detener;
  end;

implementation

uses
  System.SysUtils, inLibEstadoColas, inLibVerifactu,
  inLibVerifactuTipos,
  inLibVentasWsCola,
  inLibPrestaShopCola,
  inLibVerifactuCola,
  UniDataVerifactuColaProcesador,
  UniDataVentasWsSesion,
  UniDataPrestaShopSesion;

type
  TCierreColaPrestaShopAdaptador = class(
    TInterfacedObject,
    ICierreColaPrestaShop)
  private
    FCola: TPrestaShopCola;
  public
    constructor Create(ACola: TPrestaShopCola);
    function BloquearNuevasReclamaciones: Boolean;
    procedure CancelarCierre;
    procedure DetenerTrasTrabajoActual;
    procedure DetenerLiberandoTrabajoActual;
  end;

constructor TCierreColaPrestaShopAdaptador.Create(ACola: TPrestaShopCola);
begin
  inherited Create;
  if not Assigned(ACola) then
    raise EArgumentNilException.Create('ACola');
  FCola := ACola;
end;

function TCierreColaPrestaShopAdaptador.BloquearNuevasReclamaciones:
  Boolean;
begin
  Result := FCola.BloquearNuevasReclamaciones;
end;

procedure TCierreColaPrestaShopAdaptador.CancelarCierre;
begin
  FCola.CancelarCierre;
end;

procedure TCierreColaPrestaShopAdaptador.DetenerTrasTrabajoActual;
begin
  FCola.DetenerTrasTrabajoActual;
end;

procedure TCierreColaPrestaShopAdaptador.DetenerLiberandoTrabajoActual;
begin
  FCola.DetenerLiberandoTrabajoActual;
end;

constructor TProcesosSegundoPlanoAplicacion.Create(
  const AConexiones: IServicioConexiones;
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const ARegistroLog: IRegistroLog);
var
  eCola: TTipoColaEstado;
begin
  inherited Create;
  for eCola := Low(TTipoColaEstado) to High(TTipoColaEstado) do
    FEstados[eCola] := CrearEstadoCola;
  if not Assigned(AConexiones) then
    raise EArgumentNilException.Create('AConexiones');
  if not Assigned(AContextoSesion) then
    raise EArgumentNilException.Create('AContextoSesion');
  if not Assigned(AParametrosApp) then
    raise EArgumentNilException.Create('AParametrosApp');
  if not Assigned(AParametrosCaja) then
    raise EArgumentNilException.Create('AParametrosCaja');
  if not Assigned(ARegistroLog) then
    raise EArgumentNilException.Create('ARegistroLog');
  FConexiones := AConexiones;
  FContextoSesion := AContextoSesion;
  FParametrosApp := AParametrosApp;
  FParametrosCaja := AParametrosCaja;
  FRegistroLog := ARegistroLog;
end;

destructor TProcesosSegundoPlanoAplicacion.Destroy;
begin
  Detener;
  FRegistroLog := nil;
  FParametrosCaja := nil;
  FParametrosApp := nil;
  FContextoSesion := nil;
  FConexiones := nil;
  inherited;
end;

function TProcesosSegundoPlanoAplicacion.LeerEstadosColas: TEstadosColas;
var
  eCola: TTipoColaEstado;
  sPrestaShop: string;
begin
  Result := Default(TEstadosColas);
  if FIniciados and not FContextoSesion.CerrandoAplicacion then
  begin
    for eCola := Low(TTipoColaEstado) to High(TTipoColaEstado) do
      Result[eCola] := FEstados[eCola].Leer;
    Result[tceWs].Activa :=
      FParametrosCaja.GetBool('vgerEnviarVentasWS', False);
    // En SII la cola también envía a Hacienda (FZ-ISSUE-293)
    Result[tceHacienda].Activa :=
      ModoVerifactu(FParametrosApp) in [mvVerifactu, mvSii];
    sPrestaShop := Trim(FParametrosApp.GetString(
      'appPrestaShopSincronizarStockPrecios', 'False'));
    Result[tcePrestaShop].Activa := SameText(sPrestaShop, 'True') or
      (sPrestaShop = '1') or SameText(sPrestaShop, 'S');
  end;
end;

procedure TProcesosSegundoPlanoAplicacion.Iniciar;
var
  oPrestaShopCola: TPrestaShopCola;
  oVentasWsCola: TVentasWsCola;
begin
  if not FIniciados then
  begin
    oPrestaShopCola := nil;
    oVentasWsCola := nil;
    try
      TVerifactuCola.IniciarHilo(
        CrearProcesadorVerifactuColaUniDAC(
          FConexiones,
          FContextoSesion,
          FParametrosApp,
          FParametrosCaja,
          FContextoSesion.Identidad.Usuario,
          FRegistroLog, FEstados[tceHacienda]));
      oVentasWsCola := TVentasWsCola.Create(FRegistroLog, FEstados[tceWs]);
      oVentasWsCola.IniciarHilo(
        FContextoSesion,
        FParametrosApp,
        FParametrosCaja,
        CrearFabricaSesionVentasWsUniDAC(FConexiones),
        FContextoSesion.Identidad.Usuario);
      oPrestaShopCola := TPrestaShopCola.Create(
        FRegistroLog, FEstados[tcePrestaShop]);
      oPrestaShopCola.IniciarHilo(
        FContextoSesion,
        FParametrosApp,
        CrearFabricaSesionPrestaShopColaUniDAC(FConexiones),
        FContextoSesion.Identidad.Usuario);
      FVentasWsCola := oVentasWsCola;
      oVentasWsCola := nil;
      FPrestaShopCola := oPrestaShopCola;
      oPrestaShopCola := nil;
      FIniciados := True;
    except
      FreeAndNil(oPrestaShopCola);
      FreeAndNil(oVentasWsCola);
      FreeAndNil(FPrestaShopCola);
      FreeAndNil(FVentasWsCola);
      try
        TVerifactuCola.DetenerHilo;
      finally
        FIniciados := False;
      end;
      raise;
    end;
  end;
end;

function TProcesosSegundoPlanoAplicacion.PrepararCierrePrestaShop(
  const AConsultarDecision:
    TConsultarDecisionCierrePrestaShop): Boolean;
var
  oCierre: ICierreColaPrestaShop;
begin
  Result := True;
  if Assigned(FPrestaShopCola) then
  begin
    oCierre := TCierreColaPrestaShopAdaptador.Create(
      TPrestaShopCola(FPrestaShopCola));
    Result := IntentarCerrarColaPrestaShop(
      oCierre,
      AConsultarDecision);
  end;
end;

procedure TProcesosSegundoPlanoAplicacion.Detener;
begin
  if FIniciados then
  begin
    FreeAndNil(FPrestaShopCola);
    FreeAndNil(FVentasWsCola);
    TVerifactuCola.DetenerHilo;
    FIniciados := False;
  end;
end;

end.
