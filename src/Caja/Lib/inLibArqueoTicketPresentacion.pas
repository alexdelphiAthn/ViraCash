{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArqueoTicketPresentacion                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Construye la presentación pura del justificante de cierre de caja.       }
{******************************************************************************}
unit inLibArqueoTicketPresentacion;

interface

uses
  inLibArqueoIntf,
  inLibArqueoPersistencia;

type
  TAlineacionPresentacionTicket = (
    aptIzquierda,
    aptCentro,
    aptDerecha);
  TTipoComandoPresentacionTicket = (
    tcptAlinear,
    tcptNegrita,
    tcptLinea,
    tcptColumnas,
    tcptSeparador,
    tcptSalto,
    tcptCorte);
  TComandoPresentacionTicket = record
    Tipo: TTipoComandoPresentacionTicket;
    Texto: string;
    TextoDerecha: string;
    Alineacion: TAlineacionPresentacionTicket;
    Caracter: Char;
    Cantidad: Integer;
    Activar: Boolean;
  end;
  TPresentacionTicketArqueo = TArray<TComandoPresentacionTicket>;
  TDatosPresentacionCierreArqueo = record
    Arqueo: TArqueoCaja;
    Lineas: TArray<TArqueoRecuentoLinea>;
    TotalSistema: Currency;
    TotalRecuento: Currency;
    Diferencia: Currency;
    Retirada: Currency;
    ConceptoRetirada: string;
    EfectivoDejado: Currency;
    DesgloseBilletes: string;
    Observaciones: string;
    Vendedor: string;
    Usuario: string;
    InstanteEmision: TDateTime;
    Duplicado: Boolean;
  end;

function FormatearImportePresentacion(AValor: Currency): string;
function FormatearImportesRecuentoPresentacion(
  ASistema: Currency;
  ARecuento: Currency;
  ADiferencia: Currency): string;
function ConstruirPresentacionCierreArqueo(
  const ADatos: TDatosPresentacionCierreArqueo):
  TPresentacionTicketArqueo;

implementation

uses
  System.SysUtils,
  inLibArqueoDesglose,
  inLibMsgTickets;

procedure AgregarComando(
  var APresentacion: TPresentacionTicketArqueo;
  const AComando: TComandoPresentacionTicket);
var
  iIndice: Integer;
begin
  iIndice := Length(APresentacion);
  SetLength(APresentacion, iIndice + 1);
  APresentacion[iIndice] := AComando;
end;

function NuevoComando(
  ATipo: TTipoComandoPresentacionTicket): TComandoPresentacionTicket;
begin
  Result := Default(TComandoPresentacionTicket);
  Result.Tipo := ATipo;
end;

procedure AgregarAlineacion(
  var APresentacion: TPresentacionTicketArqueo;
  AAlineacion: TAlineacionPresentacionTicket);
var
  oComando: TComandoPresentacionTicket;
begin
  oComando := NuevoComando(tcptAlinear);
  oComando.Alineacion := AAlineacion;
  AgregarComando(APresentacion, oComando);
end;

procedure AgregarNegrita(
  var APresentacion: TPresentacionTicketArqueo;
  AActivar: Boolean);
var
  oComando: TComandoPresentacionTicket;
begin
  oComando := NuevoComando(tcptNegrita);
  oComando.Activar := AActivar;
  AgregarComando(APresentacion, oComando);
end;

procedure AgregarLinea(
  var APresentacion: TPresentacionTicketArqueo;
  const ATexto: string);
var
  oComando: TComandoPresentacionTicket;
begin
  oComando := NuevoComando(tcptLinea);
  oComando.Texto := ATexto;
  AgregarComando(APresentacion, oComando);
end;

procedure AgregarColumnas(
  var APresentacion: TPresentacionTicketArqueo;
  const AIzquierda: string;
  const ADerecha: string);
var
  oComando: TComandoPresentacionTicket;
begin
  oComando := NuevoComando(tcptColumnas);
  oComando.Texto := AIzquierda;
  oComando.TextoDerecha := ADerecha;
  AgregarComando(APresentacion, oComando);
end;

procedure AgregarSeparador(
  var APresentacion: TPresentacionTicketArqueo;
  ACaracter: Char = '-');
var
  oComando: TComandoPresentacionTicket;
begin
  oComando := NuevoComando(tcptSeparador);
  oComando.Caracter := ACaracter;
  AgregarComando(APresentacion, oComando);
end;

procedure AgregarSalto(
  var APresentacion: TPresentacionTicketArqueo;
  ACantidad: Integer);
var
  oComando: TComandoPresentacionTicket;
begin
  oComando := NuevoComando(tcptSalto);
  oComando.Cantidad := ACantidad;
  AgregarComando(APresentacion, oComando);
end;

procedure AgregarCorte(
  var APresentacion: TPresentacionTicketArqueo);
begin
  AgregarComando(
    APresentacion,
    NuevoComando(tcptCorte));
end;

function FormatearImportePresentacion(AValor: Currency): string;
begin
  Result := FormatFloat(',0.00', AValor);
end;

function FormatearImportesRecuentoPresentacion(
  ASistema: Currency;
  ARecuento: Currency;
  ADiferencia: Currency): string;
begin
  Result := Format(
    '%14s%14s%14s',
    [FormatearImportePresentacion(ASistema),
     FormatearImportePresentacion(ARecuento),
     FormatearImportePresentacion(ADiferencia)]);
end;

procedure AgregarTituloCierre(
  var APresentacion: TPresentacionTicketArqueo;
  const ADatos: TDatosPresentacionCierreArqueo);
begin
  AgregarSalto(APresentacion, 1);
  AgregarAlineacion(APresentacion, aptCentro);
  AgregarNegrita(APresentacion, True);
  AgregarLinea(
    APresentacion,
    Format(STicketCierreCaja, [ADatos.Arqueo.Caja]));
  AgregarNegrita(APresentacion, False);
  if ADatos.Duplicado then
  begin
    AgregarNegrita(APresentacion, True);
    AgregarLinea(APresentacion, STicketDuplicado);
    AgregarNegrita(APresentacion, False);
  end;
end;

procedure AgregarDatosCierre(
  var APresentacion: TPresentacionTicketArqueo;
  const ADatos: TDatosPresentacionCierreArqueo);
begin
  AgregarAlineacion(APresentacion, aptIzquierda);
  AgregarLinea(APresentacion, STicketPeriodoCerrado);
  AgregarColumnas(
    APresentacion,
    STicketInicio,
    FormatDateTime('dd/mm/yyyy hh:nn:ss', ADatos.Arqueo.FechaDesde));
  AgregarColumnas(
    APresentacion,
    STicketFin,
    FormatDateTime('dd/mm/yyyy hh:nn:ss', ADatos.Arqueo.FechaHasta));
  AgregarColumnas(
    APresentacion,
    STicketVentas,
    IntToStr(ADatos.Arqueo.CantidadVentas));
  AgregarColumnas(APresentacion, STicketCierrePor, ADatos.Usuario);
  if ADatos.Vendedor <> '' then
    AgregarColumnas(APresentacion, STicketVendedor, ADatos.Vendedor);
  AgregarSeparador(APresentacion, '=');
end;

procedure AgregarParBilletes(
  var APresentacion: TPresentacionTicketArqueo;
  const ADenominacion: TDenominacionArqueo);
begin
  AgregarColumnas(
    APresentacion,
    '  ' + FormatearImportePresentacion(ADenominacion.Valor) +
      ' EUR x ' + IntToStr(ADenominacion.Unidades),
    FormatearImportePresentacion(ADenominacion.Importe));
end;

procedure AgregarDesgloseBilletes(
  var APresentacion: TPresentacionTicketArqueo;
  const ADesglose: string);
var
  aDenominaciones: TDesgloseArqueo;
  iLinea: Integer;
begin
  { El texto persistido llega como "denominacion:unidades;..." con punto
    decimal; el dominio descarta los pares no válidos o sin unidades. }
  aDenominaciones := AnalizarDesgloseArqueo(ADesglose);
  if Length(aDenominaciones) > 0 then
  begin
    AgregarNegrita(APresentacion, True);
    AgregarLinea(APresentacion, STicketBilletesMonedas);
    AgregarNegrita(APresentacion, False);
    for iLinea := 0 to High(aDenominaciones) do
      AgregarParBilletes(APresentacion, aDenominaciones[iLinea]);
    AgregarColumnas(
      APresentacion,
      STicketTotalContado,
      FormatearImportePresentacion(
        TotalDesgloseArqueo(aDenominaciones)));
    AgregarSeparador(APresentacion);
  end;
end;

procedure AgregarEfectivoSistema(
  var APresentacion: TPresentacionTicketArqueo;
  const AArqueo: TArqueoCaja);
begin
  AgregarNegrita(APresentacion, True);
  AgregarLinea(APresentacion, STicketEfectivoSistema);
  AgregarNegrita(APresentacion, False);
  AgregarColumnas(
    APresentacion,
    STicketVentasSangrado,
    FormatearImportePresentacion(AArqueo.EfectivoIngresos));
  AgregarColumnas(
    APresentacion,
    STicketEntradasSangrado,
    FormatearImportePresentacion(AArqueo.EfectivoEntradas));
  AgregarColumnas(
    APresentacion,
    STicketGastosSangrado,
    FormatearImportePresentacion(AArqueo.EfectivoSalidas));
  AgregarColumnas(
    APresentacion,
    STicketAnteriorSangrado,
    FormatearImportePresentacion(AArqueo.EfectivoAnterior));
  AgregarColumnas(
    APresentacion,
    STicketTotalSangrado,
    FormatearImportePresentacion(AArqueo.EfectivoCaja));
  AgregarSeparador(APresentacion);
end;

procedure AgregarRecuento(
  var APresentacion: TPresentacionTicketArqueo;
  const ALineas: TArray<TArqueoRecuentoLinea>);
var
  iLinea: Integer;
begin
  AgregarNegrita(APresentacion, True);
  AgregarLinea(APresentacion, STicketRecuento);
  AgregarNegrita(APresentacion, False);
  AgregarLinea(
    APresentacion,
    Format(
      '%14s%14s%14s',
      [STicketSistemaAbreviado,
       STicketRecuentoAbreviado,
       STicketDiferenciaAbreviada]));
  iLinea := 0;
  while iLinea < Length(ALineas) do
  begin
    AgregarLinea(APresentacion, ALineas[iLinea].Descripcion);
    AgregarLinea(
      APresentacion,
      FormatearImportesRecuentoPresentacion(
        ALineas[iLinea].Sistema,
        ALineas[iLinea].Recuento,
        ALineas[iLinea].Diferencia));
    Inc(iLinea);
  end;
  AgregarSeparador(APresentacion, '=');
end;

procedure AgregarTotales(
  var APresentacion: TPresentacionTicketArqueo;
  const ADatos: TDatosPresentacionCierreArqueo);
begin
  AgregarNegrita(APresentacion, True);
  AgregarColumnas(
    APresentacion,
    STicketTotalSistema,
    FormatearImportePresentacion(ADatos.TotalSistema));
  AgregarColumnas(
    APresentacion,
    STicketTotalRecontado,
    FormatearImportePresentacion(ADatos.TotalRecuento));
  AgregarColumnas(
    APresentacion,
    STicketDiferencia,
    FormatearImportePresentacion(ADatos.Diferencia));
  AgregarNegrita(APresentacion, False);
  AgregarSeparador(APresentacion);
end;

procedure AgregarRetiradaYObservaciones(
  var APresentacion: TPresentacionTicketArqueo;
  const ADatos: TDatosPresentacionCierreArqueo);
begin
  if ADatos.Retirada > 0 then
  begin
    AgregarColumnas(
      APresentacion,
      STicketRetirada,
      FormatearImportePresentacion(ADatos.Retirada));
    AgregarColumnas(
      APresentacion,
      STicketDestinoSangrado,
      ADatos.ConceptoRetirada);
  end;
  AgregarNegrita(APresentacion, True);
  AgregarColumnas(
    APresentacion,
    STicketDejoCaja,
    FormatearImportePresentacion(ADatos.EfectivoDejado));
  AgregarNegrita(APresentacion, False);
  if ADatos.Observaciones <> '' then
  begin
    AgregarSeparador(APresentacion);
    AgregarLinea(
      APresentacion,
      Format(STicketObservaciones, [ADatos.Observaciones]));
  end;
end;

procedure AgregarPie(
  var APresentacion: TPresentacionTicketArqueo;
  AInstanteEmision: TDateTime);
begin
  AgregarSeparador(APresentacion);
  AgregarAlineacion(APresentacion, aptCentro);
  AgregarLinea(
    APresentacion,
    FormatDateTime('dd/mm/yyyy hh:nn:ss', AInstanteEmision));
  AgregarLinea(APresentacion, STicketFirma);
  AgregarSalto(APresentacion, 2);
  AgregarSeparador(APresentacion, '.');
  AgregarSalto(APresentacion, 1);
  AgregarCorte(APresentacion);
end;

function ConstruirPresentacionCierreArqueo(
  const ADatos: TDatosPresentacionCierreArqueo):
  TPresentacionTicketArqueo;
begin
  Result := nil;
  AgregarTituloCierre(Result, ADatos);
  AgregarDatosCierre(Result, ADatos);
  AgregarDesgloseBilletes(Result, ADatos.DesgloseBilletes);
  AgregarEfectivoSistema(Result, ADatos.Arqueo);
  AgregarRecuento(Result, ADatos.Lineas);
  AgregarTotales(Result, ADatos);
  AgregarRetiradaYObservaciones(Result, ADatos);
  AgregarPie(Result, ADatos.InstanteEmision);
end;

end.
