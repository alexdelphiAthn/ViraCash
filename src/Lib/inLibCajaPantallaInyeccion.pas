{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaPantallaInyeccion                                   }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Define y valida los contextos mínimos de las pantallas de Caja.           }
{******************************************************************************}
unit inLibCajaPantallaInyeccion;

interface

uses
  System.SysUtils, Data.DB, Uni,
  inLibParametrosIntf, inLibEstadoColasIntf,
  inLibMeteorologiaCajaIntf,
  inLibCajaSubsanacionIntf,
  inLibConsultaFacturasOperacionesPersistenciaIntf,
  inLibVentasCalendarioIntf,
  inLibEmisionFiscalIntf,
  inLibCajasDefectoPersistenciaIntf,
  inLibFaseCobroPersistenciaIntf,
  inLibCajaVentaIntf,
  inLibTraspasoOpePersistenciaIntf,
  inLibArticulosResolverIntf,
  inLibArticulosValidadorIntf,
  inLibArticulosAtributosIntf,
  inLibCajaArticulosOperacionIntf,
  inLibCajaOperacionesHistPersistenciaIntf,
  inLibCajaPagosHistPersistenciaIntf,
  inLibPerfilesUsuarioIntf,
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
  inLibAppParamPersistenciaIntf,
  inLibReimpresionOperacionCaja;

type
  TCrearOperacionesHistoricasCaja = reference to function(
    ADataSet: TDataSet): IRepositorioCajaOperacionesHist;
  TCrearPagosHistoricosCaja = reference to function(
    ADataSet: TDataSet): IRepositorioCajaPagosHist;
  TCrearPerfilesHistoricosCaja = reference to function:
    IGrabadorPerfilesHistoricoCaja;

  TDependenciasInformeCaja = record
    Repositorio: IRepositorioInformesCaja;
    CajasDefecto: IRepositorioCajasDefecto;
    procedure Validar;
  end;

  TDependenciasConsultaOperacionesCaja = record
    Subsanacion: IServicioSubsanacionCaja;
    Facturas: IRepositorioConsultaFacturasOperaciones;
    VentasCalendario: IRepositorioVentasCalendario;
    EmisionFiscal: IServicioEmisionFiscal;
    TraspasoTicket: IRepositorioTraspasoTicket;
    Tickets: TRepositoriosTicketsCaja;
    LecturasTicket: ILecturasImpresionTicket;
    // Fotos de la rejilla principal: puede venir sin asignar (el
    // parametro de caja las apaga) y entonces no hay columna.
    ArticulosOperacion: IConsultaArticulosOperacionCaja;
    procedure Validar;
  end;

  TDependenciasGastoCaja = record
    Consultas: IRepositorioConsultasCaja;
    Persistencia: IRepositorioGastoCaja;
    LecturasTicket: ILecturasImpresionTicket;
    procedure Validar;
  end;

  TDependenciasEntradaCambio = record
    Consultas: IRepositorioConsultasCaja;
    Persistencia: IRepositorioEntradaCambio;
    LecturasTicket: ILecturasImpresionTicket;
    procedure Validar;
  end;

  TDependenciasArqueosHistoricosCaja = record
    Informes: IRepositorioInformesCaja;
    Arqueo: IRepositorioArqueoCaja;
    Ticket: IRepositorioArqueoTicket;
    procedure Validar;
  end;

  TDependenciasArqueoCaja = record
    Consultas: IRepositorioConsultasCaja;
    VentasCalendario: IRepositorioVentasCalendario;
    Modal: IRepositorioModalArqueo;
    Persistencia: IArqueoPersistencia;
    Arqueo: IRepositorioArqueoCaja;
    Ticket: IRepositorioArqueoTicket;
    Tira: IRepositorioTiraCajaTicket;
    Informes: IRepositorioInformesCaja;
    procedure Validar;
  end;

  TDependenciasTraspasoCaja = record
    Consultas: IRepositorioConsultasCaja;
    Persistencia: IRepositorioTraspasoOpe;
    ValidadorArticulos: IArticulosValidador;
    AtributosArticulos: IArticulosAtributosLookup;
    Ticket: IRepositorioTraspasoTicket;
    procedure Validar;
  end;

  TDependenciasOperacionesHistoricasCaja = record
    CrearPersistencia: TCrearOperacionesHistoricasCaja;
    CrearPerfiles: TCrearPerfilesHistoricosCaja;
    Informe: TDependenciasInformeCaja;
    // Fotos de la rejilla principal: puede venir sin asignar (el
    // parametro de caja las apaga) y entonces no hay columna.
    ArticulosOperacion: IConsultaArticulosOperacionCaja;
    // Imprimir duplicado del ticket de la operacion.
    Reimpresion: TDependenciasReimpresionCaja;
    procedure Validar;
  end;

  TDependenciasPagosHistoricosCaja = record
    CrearPersistencia: TCrearPagosHistoricosCaja;
    CrearPerfiles: TCrearPerfilesHistoricosCaja;
    Informe: TDependenciasInformeCaja;
    procedure Validar;
  end;

  TDependenciasParametrosCaja = record
    Edicion: IParametrosEdicion;
    Persistencia: IRepositorioAppParam;
    // Opcional: abre el diseñador de los formatos FastReport del ticket.
    EditarFormatosTicket: TProc;
    procedure Validar;
  end;

  TDependenciasFaseCobro = record
    Persistencia: IRepositorioFaseCobro;
    Vales: IRepositorioInformesCaja;
    procedure Validar;
  end;

  TDependenciasOperacionCaja = record
    ConsultarEstadosColas: TConsultarEstadosColas;
    ResolverArticulos: IArticulosResolver;
    ValidadorArticulos: IArticulosValidador;
    AtributosArticulos: IArticulosAtributosLookup;
    Articulos: IRepositorioArticulosCaja;
    TraspasoTicket: IRepositorioTraspasoTicket;
    Tickets: TRepositoriosTicketsCaja;
    FaseCobro: TDependenciasFaseCobro;
    procedure Validar;
  end;

  TDependenciasMenuCaja = record
    Meteorologia: IServicioMeteorologiaCaja;
    PartesMeteorologia: IRepositorioMeteorologiaCaja;
    ConsultarEstadosColas: TConsultarEstadosColas;
    VentasCalendario: IRepositorioVentasCalendario;
    CajasDefecto: IRepositorioCajasDefecto;
    EntradaCambio: TDependenciasEntradaCambio;
    Gasto: TDependenciasGastoCaja;
    Arqueo: TDependenciasArqueoCaja;
    Traspaso: TDependenciasTraspasoCaja;
    procedure Validar;
  end;

procedure ValidarDependenciaCaja(
  const ADependencia: IInterface;
  const ANombre: string);
procedure ValidarRepositoriosTicketsCaja(
  const ARepositorios: TRepositoriosTicketsCaja);
procedure ValidarDependenciasReimpresionCaja(
  const ADependencias: TDependenciasReimpresionCaja);

implementation

resourcestring
  SErrorDependenciaCajaAusente =
    'Falta la dependencia obligatoria de Caja: %s';

procedure ValidarDependenciaCaja(
  const ADependencia: IInterface;
  const ANombre: string);
begin
  if not Assigned(ADependencia) then
    raise EArgumentNilException.CreateFmt(
      SErrorDependenciaCajaAusente,
      [ANombre]);
end;

procedure ValidarRepositoriosTicketsCaja(
  const ARepositorios: TRepositoriosTicketsCaja);
begin
  ValidarDependenciaCaja(ARepositorios.Impresion, 'impresión de tickets');
  ValidarDependenciaCaja(
    ARepositorios.Recordatorios,
    'recordatorios de tickets');
  ValidarDependenciaCaja(ARepositorios.Tickets, 'lectura de tickets');
  ValidarDependenciaCaja(ARepositorios.Resguardos, 'resguardos de tickets');
end;

procedure ValidarDependenciasReimpresionCaja(
  const ADependencias: TDependenciasReimpresionCaja);
begin
  ValidarDependenciaCaja(ADependencias.TraspasoTicket, 'traspaso de tickets');
  ValidarRepositoriosTicketsCaja(ADependencias.Tickets);
  ValidarDependenciaCaja(
    ADependencias.LecturasTicket,
    'impresión de tickets');
end;

procedure TDependenciasInformeCaja.Validar;
begin
  ValidarDependenciaCaja(Repositorio, 'informes de Caja');
  ValidarDependenciaCaja(CajasDefecto, 'selección de cajas');
end;

procedure TDependenciasConsultaOperacionesCaja.Validar;
begin
  ValidarDependenciaCaja(Subsanacion, 'subsanación de operaciones');
  ValidarDependenciaCaja(Facturas, 'facturas de operaciones');
  ValidarDependenciaCaja(VentasCalendario, 'calendario de ventas');
  ValidarDependenciaCaja(EmisionFiscal, 'emisión fiscal');
  ValidarDependenciaCaja(TraspasoTicket, 'traspaso de tickets');
  ValidarRepositoriosTicketsCaja(Tickets);
  ValidarDependenciaCaja(LecturasTicket, 'impresión de tickets');
end;

procedure TDependenciasGastoCaja.Validar;
begin
  ValidarDependenciaCaja(Consultas, 'consultas de Caja');
  ValidarDependenciaCaja(Persistencia, 'persistencia de gastos de Caja');
  ValidarDependenciaCaja(LecturasTicket, 'impresión de tickets');
end;

procedure TDependenciasEntradaCambio.Validar;
begin
  ValidarDependenciaCaja(Consultas, 'consultas de Caja');
  ValidarDependenciaCaja(
    Persistencia,
    'persistencia de entradas de cambio');
  ValidarDependenciaCaja(LecturasTicket, 'impresión de tickets');
end;

procedure TDependenciasArqueosHistoricosCaja.Validar;
begin
  ValidarDependenciaCaja(Informes, 'informes de Caja');
  ValidarDependenciaCaja(Arqueo, 'lectura de arqueos');
  ValidarDependenciaCaja(Ticket, 'tickets de arqueo');
end;

procedure TDependenciasArqueoCaja.Validar;
begin
  ValidarDependenciaCaja(Consultas, 'consultas de Caja');
  ValidarDependenciaCaja(VentasCalendario, 'calendario de ventas');
  ValidarDependenciaCaja(Modal, 'persistencia del modal de arqueo');
  ValidarDependenciaCaja(Persistencia, 'persistencia de arqueos');
  ValidarDependenciaCaja(Arqueo, 'lectura de arqueos');
  ValidarDependenciaCaja(Ticket, 'tickets de arqueo');
  ValidarDependenciaCaja(Tira, 'tira de Caja');
  ValidarDependenciaCaja(Informes, 'histórico de arqueos');
end;

procedure TDependenciasTraspasoCaja.Validar;
begin
  ValidarDependenciaCaja(Consultas, 'consultas de Caja');
  ValidarDependenciaCaja(Persistencia, 'persistencia de traspasos');
  ValidarDependenciaCaja(ValidadorArticulos, 'validación de artículos');
  ValidarDependenciaCaja(AtributosArticulos, 'atributos de artículos');
  ValidarDependenciaCaja(Ticket, 'ticket de traspaso');
end;

procedure TDependenciasOperacionesHistoricasCaja.Validar;
begin
  if not Assigned(CrearPersistencia) then
    raise EArgumentNilException.CreateFmt(
      SErrorDependenciaCajaAusente,
      ['creación del histórico de operaciones']);
  if not Assigned(CrearPerfiles) then
    raise EArgumentNilException.CreateFmt(
      SErrorDependenciaCajaAusente,
      ['creación de perfiles del histórico de operaciones']);
  Informe.Validar;
  ValidarDependenciasReimpresionCaja(Reimpresion);
end;

procedure TDependenciasPagosHistoricosCaja.Validar;
begin
  if not Assigned(CrearPersistencia) then
    raise EArgumentNilException.CreateFmt(
      SErrorDependenciaCajaAusente,
      ['creación del histórico de pagos']);
  if not Assigned(CrearPerfiles) then
    raise EArgumentNilException.CreateFmt(
      SErrorDependenciaCajaAusente,
      ['creación de perfiles del histórico de pagos']);
  Informe.Validar;
end;

procedure TDependenciasParametrosCaja.Validar;
begin
  ValidarDependenciaCaja(Edicion, 'edición de parámetros de Caja');
  ValidarDependenciaCaja(Persistencia, 'persistencia de parámetros de Caja');
end;

procedure TDependenciasFaseCobro.Validar;
begin
  ValidarDependenciaCaja(Persistencia, 'persistencia de la fase de cobro');
  ValidarDependenciaCaja(Vales, 'selección de vales');
end;

procedure TDependenciasOperacionCaja.Validar;
begin
  ValidarDependenciaCaja(ResolverArticulos, 'resolución de artículos');
  ValidarDependenciaCaja(ValidadorArticulos, 'validación de artículos');
  ValidarDependenciaCaja(AtributosArticulos, 'atributos de artículos');
  ValidarDependenciaCaja(Articulos, 'stock y búsqueda de artículos');
  ValidarDependenciaCaja(TraspasoTicket, 'traspaso de tickets');
  ValidarRepositoriosTicketsCaja(Tickets);
  FaseCobro.Validar;
end;

procedure TDependenciasMenuCaja.Validar;
begin
  ValidarDependenciaCaja(VentasCalendario, 'calendario de ventas');
  ValidarDependenciaCaja(CajasDefecto, 'selección de cajas');
  EntradaCambio.Validar;
  Gasto.Validar;
  Arqueo.Validar;
  Traspaso.Validar;
end;

end.
