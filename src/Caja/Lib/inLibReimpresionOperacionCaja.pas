{******************************************************************************}
{                                                                              }
{  Módulo:       inLibReimpresionOperacionCaja                                 }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Reimpresión de los tickets de una operación de caja ya grabada: el de     }
{    traspaso, el de venta (factura simplificada, con sus vales), el           }
{    resguardo de depósitos, el de entradas/gastos de caja y el recordatorio   }
{    del cliente. Común a Buscar/Modificar operaciones y a los históricos      }
{    de operaciones y de vales. Con la impresora 'DEBUG' sale en vista         }
{    previa.                                                                   }
{******************************************************************************}
unit inLibReimpresionOperacionCaja;

interface

uses
  System.Classes,
  inLibParametrosIntf,
  inLibPreviewTicket,
  inLibUnidadesMedida,
  inLibGenerarTicketIntf,
  inLibTraspasoTicketIntf,
  inLibTicketsCajaIntf;

type
  // Ticket de venta con el formato FastReport del parámetro
  // vgerFormatoTicket, el mismo del cobro (FZ-ISSUE-757).
  ITicketFormatoCaja = interface
    ['{6F0B8C1E-3D2A-4B7F-9E51-2C8A4D7B90F3}']
    function TieneFormato: Boolean;
    // False si no se pudo emitir: el llamador saca el ticket de texto.
    function Imprimir(
      const ASerie, ANumero, ANombreImpresora: string;
      ARutasPdf: TStrings): Boolean;
  end;

  TDependenciasReimpresionCaja = record
    TraspasoTicket: IRepositorioTraspasoTicket;
    Tickets: TRepositoriosTicketsCaja;
    LecturasTicket: ILecturasImpresionTicket;
  end;

  TEntornoReimpresionCaja = record
    ParametrosApp: IParametrosAplicacion;
    ParametrosCaja: IParametrosCaja;
    Preview: IPreviewTicket;
    Unidades: TUnidadesMedida;
    // Empresa de la sesión: la del recordatorio del cliente.
    EmpresaSesion: string;
    // Opcional: sin él, la venta sale siempre con el ticket de texto.
    TicketFormato: ITicketFormatoCaja;
  end;

  TOperacionReimpresionCaja = record
    Empresa: string;
    Almacen: string;
    Caja: string;
    NumeroOperacion: string;
    // TIPOS_OP de la operación (VE,DV,TR,TA,EC,GC...).
    Tipos: string;
    // Vacío = sin recordatorio.
    Cliente: string;
    TieneFactura: Boolean;
    TieneDepositos: Boolean;
  end;

function EsTiposTraspasoCaja(const ATipos: string): Boolean;
function EsTiposOperacionCaja(const ATipos: string): Boolean;

// False si la operación no tiene ningún ticket que reimprimir.
function ReimprimirOperacionCaja(
  const AEntorno: TEntornoReimpresionCaja;
  const ADependencias: TDependenciasReimpresionCaja;
  const AOperacion: TOperacionReimpresionCaja;
  const ANombreImpresora: string): Boolean;

implementation

uses
  System.SysUtils,
  inLibGenerarTicketBD, inLibTicketLotes,
  inLibGenerarTicketCaja,
  inLibTraspasoTicket;

function EsTiposTraspasoCaja(const ATipos: string): Boolean;
begin
  Result := (Pos('TR', ATipos) > 0) or (Pos('TA', ATipos) > 0) or
    (Pos('TP', ATipos) > 0);
end;

function EsTiposOperacionCaja(const ATipos: string): Boolean;
begin
  Result := (Pos('EC', ATipos) > 0) or (Pos('GC', ATipos) > 0);
end;

// El ticket de venta con el formato del cobro, si hay uno elegido.
function ImprimirVentaConFormato(
  const AEntorno: TEntornoReimpresionCaja;
  const ADependencias: TDependenciasReimpresionCaja;
  const AOperacion: TOperacionReimpresionCaja;
  const ANombreImpresora: string): Boolean;
var
  rContexto: TContextoOperacionTicketCaja;
  rCabecera: TCabeceraTicketCaja;
begin
  Result := False;
  if Assigned(AEntorno.TicketFormato) and
     Assigned(ADependencias.Tickets.Tickets) and
     AEntorno.TicketFormato.TieneFormato then
  begin
    rContexto.Empresa := AOperacion.Empresa;
    rContexto.Almacen := AOperacion.Almacen;
    rContexto.Caja := AOperacion.Caja;
    rContexto.Operacion := AOperacion.NumeroOperacion;
    rCabecera :=
      ADependencias.Tickets.Tickets.ObtenerCabeceraTicket(rContexto);
    if rCabecera.Encontrada and
       (Trim(rCabecera.NumeroFactura) <> '') then
      Result := AEntorno.TicketFormato.Imprimir(
        rCabecera.SerieFactura,
        rCabecera.NumeroFactura,
        ANombreImpresora,
        nil);
  end;
end;

function ReimprimirOperacionCaja(
  const AEntorno: TEntornoReimpresionCaja;
  const ADependencias: TDependenciasReimpresionCaja;
  const AOperacion: TOperacionReimpresionCaja;
  const ANombreImpresora: string): Boolean;
var
  bOperacionCaja, ImprimirLotes: Boolean;
begin
  Result := True;
  ImprimirLotes := True;
  if Assigned(AEntorno.ParametrosCaja) then
    ImprimirLotes := AEntorno.ParametrosCaja.GetBool(
      PARAMETRO_IMPRIMIR_LOTES_TICKET, True);
  // Los traspasos usan su ticket específico con stock origen/destino.
  if EsTiposTraspasoCaja(AOperacion.Tipos) then
    TTraspasoTicket.ImprimirTraspasoDesdeBD(
      AEntorno.Preview,
      ADependencias.TraspasoTicket,
      AOperacion.Empresa,
      AOperacion.Almacen,
      AOperacion.Caja,
      AOperacion.NumeroOperacion,
      ANombreImpresora)
  else
  begin
    bOperacionCaja := EsTiposOperacionCaja(AOperacion.Tipos);
    if AOperacion.TieneFactura and
       (not ImprimirVentaConFormato(
         AEntorno, ADependencias, AOperacion, ANombreImpresora)) then
      ImprimirTicketDesdeBD(
        AEntorno.ParametrosApp,
        AEntorno.Preview,
        AEntorno.Unidades,
        ADependencias.Tickets.Tickets,
        AOperacion.Empresa,
        AOperacion.Almacen,
        AOperacion.Caja,
        AOperacion.NumeroOperacion,
        ANombreImpresora, nil, False, False, ImprimirLotes);
    if AOperacion.TieneDepositos then
      ImprimirResguardoDeposito(
        AEntorno.Preview,
        ADependencias.Tickets.Resguardos,
        AOperacion.Empresa,
        AOperacion.Almacen,
        AOperacion.Caja,
        AOperacion.NumeroOperacion,
        ANombreImpresora);
    if bOperacionCaja then
      ImprimirTicketOperacionCaja(
        AEntorno.Preview,
        ADependencias.LecturasTicket,
        AOperacion.Empresa,
        AOperacion.Almacen,
        AOperacion.Caja,
        AOperacion.NumeroOperacion,
        ANombreImpresora);
    Result := AOperacion.TieneFactura or AOperacion.TieneDepositos or
      bOperacionCaja;
    if Result and (Trim(AOperacion.Cliente) <> '') then
      ImprimirRecordatorio(
        AEntorno.Preview,
        ADependencias.Tickets.Recordatorios,
        AEntorno.EmpresaSesion,
        AOperacion.Cliente,
        ANombreImpresora);
  end;
end;

end.
