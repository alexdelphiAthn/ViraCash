{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataCajaPantallaComposicion                               }
{    Tipo:       Adaptador de composición                                     }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Separa las capacidades de Caja durante la migración del contexto general.}
{******************************************************************************}
unit UniDataCajaPantallaComposicion;

interface

uses
  Data.DB, Uni,
  inLibConexionesIntf,
  inLibContextoSesionIntf,
  UniDataRepositoriosArticulosPantalla,
  UniDataRepositoriosCajaPantalla,
  UniDataRepositoriosConfiguracionPantalla,
  UniDataRepositoriosOperacionesPantalla,
  UniDataRepositoriosTicketsCajaPantalla,
  inLibPerfilesUsuarioIntf,
  inLibConsultaFacturasOperacionesPersistenciaIntf,
  inLibOperacionesCajaSkuPersistenciaIntf,
  inLibVentasCalendarioIntf,
  inLibEmisionFiscalIntf,
  inLibCajasDefectoPersistenciaIntf,
  inLibFaseCobroPersistenciaIntf,
  inLibCajaVentaIntf,
  inLibTraspasoOpePersistenciaIntf,
  inLibArticulosResolverIntf,
  inLibArticulosValidadorIntf,
  inLibArticulosAtributosIntf,
  inLibCajaOperacionesHistPersistenciaIntf,
  inLibCajaPagosHistPersistenciaIntf,
  inLibCajaPantallaHistoricosIntf,
  inLibInformesCajaPersistenciaIntf,
  inLibGastoCajaPersistenciaIntf,
  inLibEntradaCambioPersistenciaIntf,
  inLibGenerarTicketIntf,
  inLibTraspasoTicketIntf,
  inLibTicketsCajaIntf,
  inLibModalArqueoPersistenciaIntf,
  inLibArqueoPersistencia,
  inLibArqueoIntf,
  inLibArqueoTicketIntf,
  inLibTiraCajaTicketIntf,
  inLibCajaArticulosOperacionIntf,
  inLibAppParamPersistenciaIntf;

type
  IComposicionConsultasCajaPantalla = interface
    ['{14274B7D-20BD-4624-B932-1DDABCB19920}']
    function CrearRepositorioConsultasCaja(
      AConexion: TUniConnection = nil): IRepositorioConsultasCaja;
    function CrearRepositorioConsultaFacturas:
      IRepositorioConsultaFacturasOperaciones;
    function CrearRepositorioVentasCalendario:
      IRepositorioVentasCalendario;
    function CrearServicioEmisionFiscal: IServicioEmisionFiscal;
    function CrearRepositorioOperacionesCajaSku(
      AConexion: TUniConnection = nil): IRepositorioOperacionesCajaSku;
    function CrearConsultaArticulosOperacion(
      AConexion: TUniConnection = nil): IConsultaArticulosOperacionCaja;
  end;

  IComposicionOperacionesCajaPantalla = interface
    ['{3BFB71AE-D021-4379-9E63-052559FF8539}']
    function CrearResolverArticulos(
      AConexion: TUniConnection = nil): IArticulosResolver;
    function CrearRepositorioArticulosCaja(
      AConexion: TUniConnection = nil): IRepositorioArticulosCaja;
    function CrearRepositorioCajasDefecto(
      AConexion: TUniConnection = nil): IRepositorioCajasDefecto;
    function CrearRepositorioFaseCobro(
      AConexion: TUniConnection = nil): IRepositorioFaseCobro;
    function CrearRepositorioTraspasoOpe(
      AConexion: TUniConnection = nil): IRepositorioTraspasoOpe;
    function CrearValidadorArticulos(
      AConexion: TUniConnection = nil): IArticulosValidador;
    function CrearLookupAtributosArticulos(
      AConexion: TUniConnection = nil): IArticulosAtributosLookup;
  end;

  IComposicionHistoricosCajaPantalla = interface
    ['{4A3695DF-A9EB-4117-ABCE-F0C6FB81A390}']
    function CrearRepositorioCajaOperacionesHist(
      ADataSet: TDataSet): IRepositorioCajaOperacionesHist;
    function CrearRepositorioCajaPagosHist(
      ADataSet: TDataSet): IRepositorioCajaPagosHist;
    function CrearGrabadorPerfiles(
      const AConexiones: IServicioConexiones;
      const AContexto: IContextoSesionAplicacion;
      const ACache: ICachePerfilesUsuario
    ): IGrabadorPerfilesHistoricoCaja;
  end;

  IComposicionInformesCajaPantalla = interface
    ['{FC1B4EF6-13C6-4FFD-A6A9-48512FB46EE4}']
    function CrearRepositorioInformesCaja(
      AConexion: TUniConnection = nil): IRepositorioInformesCaja;
  end;

  IComposicionTicketsCajaPantalla = interface
    ['{A694808F-BAA7-4DC0-94C7-8D781C7D4BB7}']
    function CrearRepositorioGastoCaja(
      AConexion: TUniConnection = nil): IRepositorioGastoCaja;
    function CrearRepositorioEntradaCambio(
      AConexion: TUniConnection = nil): IRepositorioEntradaCambio;
    function CrearLecturasImpresionTicketCaja(
      AConexion: TUniConnection = nil): ILecturasImpresionTicket;
    function CrearRepositorioTraspasoTicket(
      AConexion: TUniConnection = nil): IRepositorioTraspasoTicket;
    function CrearRepositorioTicketsCaja(
      AConexion: TUniConnection = nil): TRepositoriosTicketsCaja;
  end;

  IComposicionArqueosCajaPantalla = interface
    ['{6CE0E8D1-C70D-4B9D-A08C-2A49AB92C09A}']
    function CrearRepositorioModalArqueo(
      AConexion: TUniConnection = nil): IRepositorioModalArqueo;
    function CrearPersistenciaArqueoCaja(
      AConexion: TUniConnection = nil;
      AEnviarVentasWs: Boolean = False): IArqueoPersistencia;
    function CrearRepositorioArqueoCaja(
      AConexion: TUniConnection = nil): IRepositorioArqueoCaja;
    function CrearRepositorioArqueoTicket(
      AConexion: TUniConnection = nil): IRepositorioArqueoTicket;
    function CrearRepositorioTiraCajaTicket(
      AConexion: TUniConnection = nil): IRepositorioTiraCajaTicket;
  end;

  IComposicionConfiguracionCajaPantalla = interface
    ['{80219972-1D17-41AA-BFD1-8A7DB131DAA5}']
    function CrearRepositorioAppParam(
      AConexion: TUniConnection = nil): IRepositorioAppParam;
  end;

  TComposicionCajaPantalla = record
    Consultas: IComposicionConsultasCajaPantalla;
    Operaciones: IComposicionOperacionesCajaPantalla;
    Historicos: IComposicionHistoricosCajaPantalla;
    Informes: IComposicionInformesCajaPantalla;
    Tickets: IComposicionTicketsCajaPantalla;
    Arqueos: IComposicionArqueosCajaPantalla;
    Configuracion: IComposicionConfiguracionCajaPantalla;
  end;

function ComponerCajaPantalla(
  const AArticulos: IRepositoriosArticulosPantalla;
  const ACaja: IRepositoriosCajaPantalla;
  const AConfiguracion: IRepositoriosConfiguracionPantalla;
  const AOperaciones: IRepositoriosOperacionesPantalla;
  const ATickets: IRepositoriosTicketsCajaPantalla
): TComposicionCajaPantalla;

implementation

uses
  System.SysUtils,
  UniDataCajaPantallaHistoricos;

type
  TComposicionConsultasCajaPantalla = class(
    TInterfacedObject,
    IComposicionConsultasCajaPantalla)
  private
    FCaja: IRepositoriosCajaPantalla;
    FOperaciones: IRepositoriosOperacionesPantalla;
  public
    constructor Create(
      const ACaja: IRepositoriosCajaPantalla;
      const AOperaciones: IRepositoriosOperacionesPantalla);
    destructor Destroy; override;
    function CrearRepositorioConsultasCaja(
      AConexion: TUniConnection = nil): IRepositorioConsultasCaja;
    function CrearRepositorioConsultaFacturas:
      IRepositorioConsultaFacturasOperaciones;
    function CrearRepositorioVentasCalendario:
      IRepositorioVentasCalendario;
    function CrearServicioEmisionFiscal: IServicioEmisionFiscal;
    function CrearRepositorioOperacionesCajaSku(
      AConexion: TUniConnection = nil): IRepositorioOperacionesCajaSku;
    function CrearConsultaArticulosOperacion(
      AConexion: TUniConnection = nil): IConsultaArticulosOperacionCaja;
  end;

  TComposicionOperacionesCajaPantalla = class(
    TInterfacedObject,
    IComposicionOperacionesCajaPantalla)
  private
    FCaja: IRepositoriosCajaPantalla;
    FArticulos: IRepositoriosArticulosPantalla;
  public
    constructor Create(
      const ACaja: IRepositoriosCajaPantalla;
      const AArticulos: IRepositoriosArticulosPantalla);
    destructor Destroy; override;
    function CrearResolverArticulos(
      AConexion: TUniConnection = nil): IArticulosResolver;
    function CrearRepositorioArticulosCaja(
      AConexion: TUniConnection = nil): IRepositorioArticulosCaja;
    function CrearRepositorioCajasDefecto(
      AConexion: TUniConnection = nil): IRepositorioCajasDefecto;
    function CrearRepositorioFaseCobro(
      AConexion: TUniConnection = nil): IRepositorioFaseCobro;
    function CrearRepositorioTraspasoOpe(
      AConexion: TUniConnection = nil): IRepositorioTraspasoOpe;
    function CrearValidadorArticulos(
      AConexion: TUniConnection = nil): IArticulosValidador;
    function CrearLookupAtributosArticulos(
      AConexion: TUniConnection = nil): IArticulosAtributosLookup;
  end;

  TComposicionHistoricosCajaPantalla = class(
    TInterfacedObject,
    IComposicionHistoricosCajaPantalla)
  private
    FCaja: IRepositoriosCajaPantalla;
  public
    constructor Create(const ACaja: IRepositoriosCajaPantalla);
    destructor Destroy; override;
    function CrearRepositorioCajaOperacionesHist(
      ADataSet: TDataSet): IRepositorioCajaOperacionesHist;
    function CrearRepositorioCajaPagosHist(
      ADataSet: TDataSet): IRepositorioCajaPagosHist;
    function CrearGrabadorPerfiles(
      const AConexiones: IServicioConexiones;
      const AContexto: IContextoSesionAplicacion;
      const ACache: ICachePerfilesUsuario
    ): IGrabadorPerfilesHistoricoCaja;
  end;

  TComposicionInformesCajaPantalla = class(
    TInterfacedObject,
    IComposicionInformesCajaPantalla)
  private
    FCaja: IRepositoriosCajaPantalla;
  public
    constructor Create(const ACaja: IRepositoriosCajaPantalla);
    destructor Destroy; override;
    function CrearRepositorioInformesCaja(
      AConexion: TUniConnection = nil): IRepositorioInformesCaja;
  end;

  TComposicionTicketsCajaPantalla = class(
    TInterfacedObject,
    IComposicionTicketsCajaPantalla)
  private
    FTickets: IRepositoriosTicketsCajaPantalla;
  public
    constructor Create(
      const ATickets: IRepositoriosTicketsCajaPantalla);
    destructor Destroy; override;
    function CrearRepositorioGastoCaja(
      AConexion: TUniConnection = nil): IRepositorioGastoCaja;
    function CrearRepositorioEntradaCambio(
      AConexion: TUniConnection = nil): IRepositorioEntradaCambio;
    function CrearLecturasImpresionTicketCaja(
      AConexion: TUniConnection = nil): ILecturasImpresionTicket;
    function CrearRepositorioTraspasoTicket(
      AConexion: TUniConnection = nil): IRepositorioTraspasoTicket;
    function CrearRepositorioTicketsCaja(
      AConexion: TUniConnection = nil): TRepositoriosTicketsCaja;
  end;

  TComposicionArqueosCajaPantalla = class(
    TInterfacedObject,
    IComposicionArqueosCajaPantalla)
  private
    FCaja: IRepositoriosCajaPantalla;
    FTickets: IRepositoriosTicketsCajaPantalla;
  public
    constructor Create(
      const ACaja: IRepositoriosCajaPantalla;
      const ATickets: IRepositoriosTicketsCajaPantalla);
    destructor Destroy; override;
    function CrearRepositorioModalArqueo(
      AConexion: TUniConnection = nil): IRepositorioModalArqueo;
    function CrearPersistenciaArqueoCaja(
      AConexion: TUniConnection = nil;
      AEnviarVentasWs: Boolean = False): IArqueoPersistencia;
    function CrearRepositorioArqueoCaja(
      AConexion: TUniConnection = nil): IRepositorioArqueoCaja;
    function CrearRepositorioArqueoTicket(
      AConexion: TUniConnection = nil): IRepositorioArqueoTicket;
    function CrearRepositorioTiraCajaTicket(
      AConexion: TUniConnection = nil): IRepositorioTiraCajaTicket;
  end;

  TComposicionConfiguracionCajaPantalla = class(
    TInterfacedObject,
    IComposicionConfiguracionCajaPantalla)
  private
    FConfiguracion: IRepositoriosConfiguracionPantalla;
  public
    constructor Create(
      const AConfiguracion: IRepositoriosConfiguracionPantalla);
    destructor Destroy; override;
    function CrearRepositorioAppParam(
      AConexion: TUniConnection = nil): IRepositorioAppParam;
  end;

resourcestring
  SErrorRepositoriosCajaPantallaNoAsignados =
    'Los repositorios para componer las pantallas de Caja son obligatorios.';

procedure ValidarRepositoriosCajaPantalla(
  const ARepositorios: IInterface);
begin
  if not Assigned(ARepositorios) then
    raise EArgumentNilException.Create(
      SErrorRepositoriosCajaPantallaNoAsignados);
end;

constructor TComposicionConsultasCajaPantalla.Create(
  const ACaja: IRepositoriosCajaPantalla;
  const AOperaciones: IRepositoriosOperacionesPantalla);
begin
  inherited Create;
  FCaja := ACaja;
  FOperaciones := AOperaciones;
end;

destructor TComposicionConsultasCajaPantalla.Destroy;
begin
  FOperaciones := nil;
  FCaja := nil;
  inherited;
end;

function TComposicionConsultasCajaPantalla.CrearRepositorioConsultasCaja(
  AConexion: TUniConnection): IRepositorioConsultasCaja;
begin
  Result := FCaja.CrearRepositorioConsultasCaja(AConexion);
end;

function TComposicionConsultasCajaPantalla.CrearConsultaArticulosOperacion(
  AConexion: TUniConnection): IConsultaArticulosOperacionCaja;
begin
  Result := FOperaciones.CrearConsultaArticulosOperacion(AConexion);
end;

function TComposicionConsultasCajaPantalla.CrearRepositorioConsultaFacturas:
  IRepositorioConsultaFacturasOperaciones;
begin
  Result := FOperaciones.CrearRepositorioConsultaFacturas;
end;

function TComposicionConsultasCajaPantalla.CrearRepositorioVentasCalendario:
  IRepositorioVentasCalendario;
begin
  Result := FOperaciones.CrearRepositorioVentasCalendario;
end;

function TComposicionConsultasCajaPantalla.CrearServicioEmisionFiscal:
  IServicioEmisionFiscal;
begin
  Result := FOperaciones.CrearServicioEmisionFiscal;
end;

function TComposicionConsultasCajaPantalla.
  CrearRepositorioOperacionesCajaSku(
  AConexion: TUniConnection): IRepositorioOperacionesCajaSku;
begin
  Result := FOperaciones.CrearRepositorioOperacionesCajaSku(AConexion);
end;

constructor TComposicionOperacionesCajaPantalla.Create(
  const ACaja: IRepositoriosCajaPantalla;
  const AArticulos: IRepositoriosArticulosPantalla);
begin
  inherited Create;
  FCaja := ACaja;
  FArticulos := AArticulos;
end;

destructor TComposicionOperacionesCajaPantalla.Destroy;
begin
  FArticulos := nil;
  FCaja := nil;
  inherited;
end;

function TComposicionOperacionesCajaPantalla.CrearResolverArticulos(
  AConexion: TUniConnection): IArticulosResolver;
begin
  Result := FArticulos.CrearResolverArticulos(AConexion);
end;

function TComposicionOperacionesCajaPantalla.
  CrearRepositorioArticulosCaja(
  AConexion: TUniConnection): IRepositorioArticulosCaja;
begin
  Result := FCaja.CrearRepositorioArticulosCaja(AConexion);
end;

function TComposicionOperacionesCajaPantalla.CrearRepositorioCajasDefecto(
  AConexion: TUniConnection): IRepositorioCajasDefecto;
begin
  Result := FCaja.CrearRepositorioCajasDefecto(AConexion);
end;

function TComposicionOperacionesCajaPantalla.CrearRepositorioFaseCobro(
  AConexion: TUniConnection): IRepositorioFaseCobro;
begin
  Result := FCaja.CrearRepositorioFaseCobro(AConexion);
end;

function TComposicionOperacionesCajaPantalla.CrearRepositorioTraspasoOpe(
  AConexion: TUniConnection): IRepositorioTraspasoOpe;
begin
  Result := FCaja.CrearRepositorioTraspasoOpe(AConexion);
end;

function TComposicionOperacionesCajaPantalla.CrearValidadorArticulos(
  AConexion: TUniConnection): IArticulosValidador;
begin
  Result := FArticulos.CrearValidadorArticulos(AConexion);
end;

function TComposicionOperacionesCajaPantalla.
  CrearLookupAtributosArticulos(
  AConexion: TUniConnection): IArticulosAtributosLookup;
begin
  Result := FArticulos.CrearLookupAtributosArticulos(AConexion);
end;

constructor TComposicionHistoricosCajaPantalla.Create(
  const ACaja: IRepositoriosCajaPantalla);
begin
  inherited Create;
  FCaja := ACaja;
end;

destructor TComposicionHistoricosCajaPantalla.Destroy;
begin
  FCaja := nil;
  inherited;
end;

function TComposicionHistoricosCajaPantalla.
  CrearRepositorioCajaOperacionesHist(
  ADataSet: TDataSet): IRepositorioCajaOperacionesHist;
begin
  Result := FCaja.CrearRepositorioCajaOperacionesHist(ADataSet);
end;

function TComposicionHistoricosCajaPantalla.CrearRepositorioCajaPagosHist(
  ADataSet: TDataSet): IRepositorioCajaPagosHist;
begin
  Result := FCaja.CrearRepositorioCajaPagosHist(ADataSet);
end;

function TComposicionHistoricosCajaPantalla.CrearGrabadorPerfiles(
  const AConexiones: IServicioConexiones;
  const AContexto: IContextoSesionAplicacion;
  const ACache: ICachePerfilesUsuario
): IGrabadorPerfilesHistoricoCaja;
begin
  Result := CrearGrabadorPerfilesHistoricoCaja(
    AConexiones, AContexto, ACache);
end;

constructor TComposicionInformesCajaPantalla.Create(
  const ACaja: IRepositoriosCajaPantalla);
begin
  inherited Create;
  FCaja := ACaja;
end;

destructor TComposicionInformesCajaPantalla.Destroy;
begin
  FCaja := nil;
  inherited;
end;

function TComposicionInformesCajaPantalla.CrearRepositorioInformesCaja(
  AConexion: TUniConnection): IRepositorioInformesCaja;
begin
  Result := FCaja.CrearRepositorioInformesCaja(AConexion);
end;

constructor TComposicionTicketsCajaPantalla.Create(
  const ATickets: IRepositoriosTicketsCajaPantalla);
begin
  inherited Create;
  FTickets := ATickets;
end;

destructor TComposicionTicketsCajaPantalla.Destroy;
begin
  FTickets := nil;
  inherited;
end;

function TComposicionTicketsCajaPantalla.CrearRepositorioGastoCaja(
  AConexion: TUniConnection): IRepositorioGastoCaja;
begin
  Result := FTickets.CrearRepositorioGastoCaja(AConexion);
end;

function TComposicionTicketsCajaPantalla.CrearRepositorioEntradaCambio(
  AConexion: TUniConnection): IRepositorioEntradaCambio;
begin
  Result := FTickets.CrearRepositorioEntradaCambio(AConexion);
end;

function TComposicionTicketsCajaPantalla.CrearLecturasImpresionTicketCaja(
  AConexion: TUniConnection): ILecturasImpresionTicket;
begin
  Result := FTickets.CrearLecturasImpresionTicketCaja(AConexion);
end;

function TComposicionTicketsCajaPantalla.CrearRepositorioTraspasoTicket(
  AConexion: TUniConnection): IRepositorioTraspasoTicket;
begin
  Result := FTickets.CrearRepositorioTraspasoTicket(AConexion);
end;

function TComposicionTicketsCajaPantalla.CrearRepositorioTicketsCaja(
  AConexion: TUniConnection): TRepositoriosTicketsCaja;
begin
  Result := FTickets.CrearRepositorioTicketsCaja(AConexion);
end;

constructor TComposicionArqueosCajaPantalla.Create(
  const ACaja: IRepositoriosCajaPantalla;
  const ATickets: IRepositoriosTicketsCajaPantalla);
begin
  inherited Create;
  FCaja := ACaja;
  FTickets := ATickets;
end;

destructor TComposicionArqueosCajaPantalla.Destroy;
begin
  FTickets := nil;
  FCaja := nil;
  inherited;
end;

function TComposicionArqueosCajaPantalla.CrearRepositorioModalArqueo(
  AConexion: TUniConnection): IRepositorioModalArqueo;
begin
  Result := FCaja.CrearRepositorioModalArqueo(AConexion);
end;

function TComposicionArqueosCajaPantalla.CrearPersistenciaArqueoCaja(
  AConexion: TUniConnection;
  AEnviarVentasWs: Boolean): IArqueoPersistencia;
begin
  Result := FCaja.CrearPersistenciaArqueoCaja(
    AConexion,
    AEnviarVentasWs);
end;

function TComposicionArqueosCajaPantalla.CrearRepositorioArqueoCaja(
  AConexion: TUniConnection): IRepositorioArqueoCaja;
begin
  Result := FTickets.CrearRepositorioArqueoCaja(AConexion);
end;

function TComposicionArqueosCajaPantalla.CrearRepositorioArqueoTicket(
  AConexion: TUniConnection): IRepositorioArqueoTicket;
begin
  Result := FTickets.CrearRepositorioArqueoTicket(AConexion);
end;

function TComposicionArqueosCajaPantalla.CrearRepositorioTiraCajaTicket(
  AConexion: TUniConnection): IRepositorioTiraCajaTicket;
begin
  Result := FTickets.CrearRepositorioTiraCajaTicket(AConexion);
end;

constructor TComposicionConfiguracionCajaPantalla.Create(
  const AConfiguracion: IRepositoriosConfiguracionPantalla);
begin
  inherited Create;
  FConfiguracion := AConfiguracion;
end;

destructor TComposicionConfiguracionCajaPantalla.Destroy;
begin
  FConfiguracion := nil;
  inherited;
end;

function TComposicionConfiguracionCajaPantalla.CrearRepositorioAppParam(
  AConexion: TUniConnection): IRepositorioAppParam;
begin
  Result := FConfiguracion.CrearRepositorioAppParam(AConexion);
end;

function ComponerCajaPantalla(
  const AArticulos: IRepositoriosArticulosPantalla;
  const ACaja: IRepositoriosCajaPantalla;
  const AConfiguracion: IRepositoriosConfiguracionPantalla;
  const AOperaciones: IRepositoriosOperacionesPantalla;
  const ATickets: IRepositoriosTicketsCajaPantalla
): TComposicionCajaPantalla;
begin
  ValidarRepositoriosCajaPantalla(AArticulos);
  ValidarRepositoriosCajaPantalla(ACaja);
  ValidarRepositoriosCajaPantalla(AConfiguracion);
  ValidarRepositoriosCajaPantalla(AOperaciones);
  ValidarRepositoriosCajaPantalla(ATickets);
  Result := Default(TComposicionCajaPantalla);
  Result.Consultas := TComposicionConsultasCajaPantalla.Create(
    ACaja,
    AOperaciones);
  Result.Operaciones := TComposicionOperacionesCajaPantalla.Create(
    ACaja,
    AArticulos);
  Result.Historicos := TComposicionHistoricosCajaPantalla.Create(ACaja);
  Result.Informes := TComposicionInformesCajaPantalla.Create(ACaja);
  Result.Tickets := TComposicionTicketsCajaPantalla.Create(ATickets);
  Result.Arqueos := TComposicionArqueosCajaPantalla.Create(
    ACaja,
    ATickets);
  Result.Configuracion := TComposicionConfiguracionCajaPantalla.Create(
    AConfiguracion);
end;

end.
