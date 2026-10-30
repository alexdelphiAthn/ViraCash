{******************************************************************************}
{                                                                              }
{  Módulo:       inLibEmisionFiscal                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Selecciona y ejecuta la estrategia de emisión del modo fiscal activo.     }
{******************************************************************************}
unit inLibEmisionFiscal;

interface

uses
  Uni, inLibParametrosIntf, inLibVerifactu, inLibVerifactuTipos,
  inLibEmisionFiscalIntf, inLibVerifactuColaIntf;

function CrearServicioEmisionFiscal(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  AConexion: TUniConnection;
  const AServicioCola: IServicioVerifactuCola = nil
): IServicioEmisionFiscal;

function CrearServicioEmisionFiscalPorModo(
  AModo: TModoVerifactu;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  AConexion: TUniConnection;
  const AServicioCola: IServicioVerifactuCola = nil
): IServicioEmisionFiscal;

implementation

uses
  inLibFormatoDocumento, inLibFormatoDocumentoLecturasIntf,
  System.SysUtils, inLibVerifactuCola, inLibMsgVerifactu;

type
  IEstrategiaEmisionFiscal = interface
    ['{08790CDF-5958-45D5-A3E7-15D11F100B29}']
    function Emitir(
      const ASolicitud: TSolicitudEmisionFiscal
    ): TResultadoEmisionFiscal;
    function Modo: TModoVerifactu;
  end;
  TEstrategiaEmisionFiscalBase = class abstract(
    TInterfacedObject,
    IEstrategiaEmisionFiscal)
  private
    FParametrosApp: IParametrosAplicacion;
    FParametrosCaja: IParametrosCaja;
    FConexion: TUniConnection;
    FServicioCola: IServicioVerifactuCola;
    function CrearMensaje(
      const ASolicitud: TSolicitudEmisionFiscal): string;
  protected
    procedure Ejecutar(
      const ASolicitud: TSolicitudEmisionFiscal); virtual; abstract;
    procedure RegistrarEvento(
      const ASolicitud: TSolicitudEmisionFiscal); virtual;
    function MensajeOperacion(
      const ASolicitud: TSolicitudEmisionFiscal): string;
      virtual; abstract;
    function MensajeConsolidacion(
      const ASolicitud: TSolicitudEmisionFiscal): string;
      virtual; abstract;
    property ParametrosApp: IParametrosAplicacion
      read FParametrosApp;
    property ParametrosCaja: IParametrosCaja
      read FParametrosCaja;
    property Conexion: TUniConnection
      read FConexion;
    property ServicioCola: IServicioVerifactuCola
      read FServicioCola;
  public
    constructor Create(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      AConexion: TUniConnection;
      const AServicioCola: IServicioVerifactuCola);
    function Emitir(
      const ASolicitud: TSolicitudEmisionFiscal
    ): TResultadoEmisionFiscal;
    function Modo: TModoVerifactu; virtual; abstract;
  end;
  TEstrategiaEmisionVerifactu = class(
    TEstrategiaEmisionFiscalBase)
  protected
    procedure Ejecutar(
      const ASolicitud: TSolicitudEmisionFiscal); override;
    procedure RegistrarEvento(
      const ASolicitud: TSolicitudEmisionFiscal); override;
    function MensajeOperacion(
      const ASolicitud: TSolicitudEmisionFiscal): string; override;
    function MensajeConsolidacion(
      const ASolicitud: TSolicitudEmisionFiscal): string; override;
  public
    function Modo: TModoVerifactu; override;
  end;
  // SII: encola y registra el evento igual que VERIFACTU; el envío
  // decide el sistema por la fila de la cola.
  TEstrategiaEmisionSii = class(TEstrategiaEmisionVerifactu)
  protected
    procedure RegistrarEvento(
      const ASolicitud: TSolicitudEmisionFiscal); override;
    // Sin QR: el aviso de VERI*FACTU dice que ya puede imprimirse
    function MensajeConsolidacion(
      const ASolicitud: TSolicitudEmisionFiscal): string; override;
  public
    function Modo: TModoVerifactu; override;
  end;
  TEstrategiaEmisionNoVerifactu = class(
    TEstrategiaEmisionFiscalBase)
  protected
    procedure Ejecutar(
      const ASolicitud: TSolicitudEmisionFiscal); override;
    function MensajeOperacion(
      const ASolicitud: TSolicitudEmisionFiscal): string; override;
    function MensajeConsolidacion(
      const ASolicitud: TSolicitudEmisionFiscal): string; override;
  public
    function Modo: TModoVerifactu; override;
  end;
  TEstrategiaEmisionSinVerifactu = class(
    TEstrategiaEmisionFiscalBase)
  protected
    procedure Ejecutar(
      const ASolicitud: TSolicitudEmisionFiscal); override;
    function MensajeOperacion(
      const ASolicitud: TSolicitudEmisionFiscal): string; override;
    function MensajeConsolidacion(
      const ASolicitud: TSolicitudEmisionFiscal): string; override;
  public
    function Modo: TModoVerifactu; override;
  end;
  TServicioEmisionFiscal = class(
    TInterfacedObject,
    IServicioEmisionFiscal)
  private
    FEstrategia: IEstrategiaEmisionFiscal;
    FParametrosApp: IParametrosAplicacion;
    FParametrosCaja: IParametrosCaja;
    FConexion: TUniConnection;
    FServicioCola: IServicioVerifactuCola;
  public
    constructor Create(
      const AEstrategia: IEstrategiaEmisionFiscal); overload;
    constructor Create(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      AConexion: TUniConnection;
      const AServicioCola: IServicioVerifactuCola); overload;
    function Emitir(
      const ASolicitud: TSolicitudEmisionFiscal
    ): TResultadoEmisionFiscal;
    function Modo: TModoVerifactu;
  end;

constructor TEstrategiaEmisionFiscalBase.Create(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  AConexion: TUniConnection;
  const AServicioCola: IServicioVerifactuCola);
begin
  inherited Create;
  FParametrosApp := AParametrosApp;
  FParametrosCaja := AParametrosCaja;
  FConexion := AConexion;
  FServicioCola := AServicioCola;
end;

procedure TEstrategiaEmisionFiscalBase.RegistrarEvento(
  const ASolicitud: TSolicitudEmisionFiscal);
begin
end;

function TEstrategiaEmisionFiscalBase.CrearMensaje(
  const ASolicitud: TSolicitudEmisionFiscal): string;
begin
  case ASolicitud.Flujo of
    fefOperacion:
      Result := MensajeOperacion(ASolicitud);
    fefConsolidacion:
      Result := MensajeConsolidacion(ASolicitud);
    fefAlta:
      Result := '';
  else
    raise EArgumentOutOfRangeException.Create(
      'Flujo de emisión fiscal no soportado.');
  end;
end;

function TEstrategiaEmisionFiscalBase.Emitir(
  const ASolicitud: TSolicitudEmisionFiscal
): TResultadoEmisionFiscal;
var
  oSolicitud: TSolicitudEmisionFiscal;
begin
  oSolicitud := ASolicitud;
  oSolicitud.FormatoDocumento := FormatoDocumentoFacturaDelProveedor(
    FServicioCola, ASolicitud.Serie, ASolicitud.Numero);
  Ejecutar(oSolicitud);
  if oSolicitud.RegistrarEvento then
    RegistrarEvento(oSolicitud);
  Result.Modo := Modo;
  Result.Mensaje := CrearMensaje(oSolicitud);
end;

procedure TEstrategiaEmisionVerifactu.Ejecutar(
  const ASolicitud: TSolicitudEmisionFiscal);
begin
  TVerifactuCola.EncolarFactura(
    ParametrosApp,
    ParametrosCaja,
    ServicioCola,
    ASolicitud.Usuario,
    ASolicitud.Serie,
    ASolicitud.Numero,
    ASolicitud.TipoOperacion,
    ASolicitud.BorrarMovimientos);
end;

procedure TEstrategiaEmisionVerifactu.RegistrarEvento(
  const ASolicitud: TSolicitudEmisionFiscal);
begin
  RegistrarEventoVerifactu(
    ParametrosApp,
    Conexion,
    ASolicitud.Usuario,
    cEventoVerifactuEncolado,
    ASolicitud.DescripcionEvento,
    '',
    ASolicitud.Serie,
    ASolicitud.Numero);
end;

function TEstrategiaEmisionVerifactu.MensajeOperacion(
  const ASolicitud: TSolicitudEmisionFiscal): string;
begin
  Result := Format(
    SInfoAccionFiscalEncolada,
    [ASolicitud.Accion]);
end;

function TEstrategiaEmisionVerifactu.MensajeConsolidacion(
  const ASolicitud: TSolicitudEmisionFiscal): string;
begin
  Result := FormatearMensajeDocumentos(
    ASolicitud.FormatoDocumento,
    SInfoBorradorVerifactuPendiente,
    [ASolicitud.Serie, ASolicitud.Numero]);
end;

function TEstrategiaEmisionVerifactu.Modo: TModoVerifactu;
begin
  Result := mvVerifactu;
end;

function TEstrategiaEmisionSii.Modo: TModoVerifactu;
begin
  Result := mvSii;
end;

function TEstrategiaEmisionSii.MensajeConsolidacion(
  const ASolicitud: TSolicitudEmisionFiscal): string;
begin
  Result := FormatearMensajeDocumentos(
    ASolicitud.FormatoDocumento,
    SInfoBorradorSiiPendiente,
    [ASolicitud.Serie, ASolicitud.Numero]);
end;

procedure TEstrategiaEmisionSii.RegistrarEvento(
  const ASolicitud: TSolicitudEmisionFiscal);
begin
  // El SII no es un SIF: sin productor del software configurado el
  // evento de encolado no se anota, pero la factura se emite.
  try
    inherited RegistrarEvento(ASolicitud);
  except
    on Exception do
      ;
  end;
end;

procedure TEstrategiaEmisionNoVerifactu.Ejecutar(
  const ASolicitud: TSolicitudEmisionFiscal);
begin
  TVerifactuCola.RegistrarFacturaNoVerifactu(
    ParametrosApp,
    ParametrosCaja,
    ServicioCola,
    ASolicitud.Usuario,
    ASolicitud.Serie,
    ASolicitud.Numero,
    ASolicitud.TipoOperacion,
    ASolicitud.BorrarMovimientos);
end;

function TEstrategiaEmisionNoVerifactu.MensajeOperacion(
  const ASolicitud: TSolicitudEmisionFiscal): string;
begin
  Result := Format(
    SInfoAccionFiscalNoVerifactu,
    [ASolicitud.Accion]);
end;

function TEstrategiaEmisionNoVerifactu.MensajeConsolidacion(
  const ASolicitud: TSolicitudEmisionFiscal): string;
begin
  Result := FormatearMensajeDocumentos(
    ASolicitud.FormatoDocumento,
    SInfoBorradorNoVerifactuRegistrado,
    [ASolicitud.Serie, ASolicitud.Numero]);
end;

function TEstrategiaEmisionNoVerifactu.Modo: TModoVerifactu;
begin
  Result := mvNoVerifactu;
end;

procedure TEstrategiaEmisionSinVerifactu.Ejecutar(
  const ASolicitud: TSolicitudEmisionFiscal);
begin
  TVerifactuCola.MarcarFacturaSinVerifactu(
    ParametrosApp,
    ParametrosCaja,
    ServicioCola,
    ASolicitud.Usuario,
    ASolicitud.Serie,
    ASolicitud.Numero,
    ASolicitud.TipoOperacion,
    ASolicitud.BorrarMovimientos);
end;

function TEstrategiaEmisionSinVerifactu.MensajeOperacion(
  const ASolicitud: TSolicitudEmisionFiscal): string;
begin
  Result := Format(
    SInfoAccionFiscalSinVerifactu,
    [ASolicitud.Accion]);
end;

function TEstrategiaEmisionSinVerifactu.MensajeConsolidacion(
  const ASolicitud: TSolicitudEmisionFiscal): string;
begin
  Result := FormatearMensajeDocumentos(
    ASolicitud.FormatoDocumento,
    SInfoBorradorSinVerifactuEmitido,
    [ASolicitud.Serie, ASolicitud.Numero]);
end;

function TEstrategiaEmisionSinVerifactu.Modo: TModoVerifactu;
begin
  Result := mvSinVerifactu;
end;

constructor TServicioEmisionFiscal.Create(
  const AEstrategia: IEstrategiaEmisionFiscal);
begin
  inherited Create;
  FEstrategia := AEstrategia;
end;

constructor TServicioEmisionFiscal.Create(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  AConexion: TUniConnection;
  const AServicioCola: IServicioVerifactuCola);
begin
  inherited Create;
  FParametrosApp := AParametrosApp;
  FParametrosCaja := AParametrosCaja;
  FConexion := AConexion;
  FServicioCola := AServicioCola;
end;

function TServicioEmisionFiscal.Emitir(
  const ASolicitud: TSolicitudEmisionFiscal
): TResultadoEmisionFiscal;
begin
  // Los parámetros pueden cambiar mientras la ficha sigue abierta.
  if Assigned(FParametrosApp) then
    Result := CrearServicioEmisionFiscalPorModo(
      Modo, FParametrosApp, FParametrosCaja, FConexion,
      FServicioCola).Emitir(ASolicitud)
  else
    Result := FEstrategia.Emitir(ASolicitud);
end;

function TServicioEmisionFiscal.Modo: TModoVerifactu;
begin
  if Assigned(FParametrosApp) then
    Result := ModoVerifactu(FParametrosApp)
  else
    Result := FEstrategia.Modo;
end;

function CrearServicioEmisionFiscalPorModo(
  AModo: TModoVerifactu;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  AConexion: TUniConnection;
  const AServicioCola: IServicioVerifactuCola
): IServicioEmisionFiscal;
var
  Estrategia: IEstrategiaEmisionFiscal;
begin
  case AModo of
    mvVerifactu:
      Estrategia := TEstrategiaEmisionVerifactu.Create(
        AParametrosApp,
        AParametrosCaja,
        AConexion,
        AServicioCola);
    mvSii:
      Estrategia := TEstrategiaEmisionSii.Create(
        AParametrosApp,
        AParametrosCaja,
        AConexion,
        AServicioCola);
    mvNoVerifactu:
      Estrategia := TEstrategiaEmisionNoVerifactu.Create(
        AParametrosApp,
        AParametrosCaja,
        AConexion,
        AServicioCola);
    mvSinVerifactu:
      Estrategia := TEstrategiaEmisionSinVerifactu.Create(
        AParametrosApp,
        AParametrosCaja,
        AConexion,
        AServicioCola);
  else
    raise EArgumentOutOfRangeException.Create(
      'Modo de emisión fiscal no soportado.');
  end;
  Result := TServicioEmisionFiscal.Create(Estrategia);
end;

function CrearServicioEmisionFiscal(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  AConexion: TUniConnection;
  const AServicioCola: IServicioVerifactuCola
): IServicioEmisionFiscal;
begin
  Result := TServicioEmisionFiscal.Create(
    AParametrosApp,
    AParametrosCaja,
    AConexion,
    AServicioCola);
end;

end.
