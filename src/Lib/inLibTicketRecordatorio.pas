{******************************************************************************}
{                                                                              }
{  Módulo:       inLibTicketRecordatorio                                      }
{    Tipo:       Servicio de aplicación                                       }
{ Versión:       1.0.0                                                        }
{   Fecha:       06/08/2026                                                   }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Compone e imprime el recordatorio de depósitos pendientes de caja.       }
{******************************************************************************}
unit inLibTicketRecordatorio;

interface

uses
  System.Classes,
  inLibPreviewTicket,
  inLibTicketsCajaIntf;

function CalcularTotalDepositoRecordatorio(
  const ADeposito: TDepositoPendienteTicketCaja): Currency;
function CalcularPendienteDepositoRecordatorio(
  const ADeposito: TDepositoPendienteTicketCaja): Currency;
function ConstruirOrigenRecordatorio(
  const AEmpresa, AAlmacen, ACaja: string): string;
function ConceptoAnticipoRecordatorio(
  const ATipoOperacion: string): string;
procedure ImprimirRecordatorioTicket(
  const APreview: IPreviewTicket;
  const ARepositorio: IRepositorioRecordatoriosCaja;
  const ACodigoEmpresa, ACodigoCliente: string;
  const ANombreImpresora: string;
  ARutasPDF: TStrings;
  ASoloPDF: Boolean);

implementation

uses
  System.SysUtils,
  inLibDir,
  inLibFTicket,
  inLibMsgTickets;

type
  TGeneradorRecordatorioTicket = class
  private
    FPreview: IPreviewTicket;
    FRepositorio: IRepositorioRecordatoriosCaja;
    FCodigoEmpresa: string;
    FCodigoCliente: string;
    FNombreImpresora: string;
    FRutasPDF: TStrings;
    FSoloPDF: Boolean;
    FDepositos: TArray<TDepositoPendienteTicketCaja>;
    FEmpresa: TEmpresaRecordatorioTicketCaja;
    FTicket: TTicketTermico;
    FTotalPendiente: Currency;
    function CargarDatos: Boolean;
    procedure EscribirCabecera;
    procedure EscribirAnticipo(
      const AAnticipo: TAnticipoRecordatorioTicketCaja);
    procedure EscribirDeposito(
      const ADeposito: TDepositoPendienteTicketCaja);
    procedure EscribirDepositos;
    procedure EscribirResumen;
    procedure GenerarSalida;
  public
    constructor Create(
      const APreview: IPreviewTicket;
      const ARepositorio: IRepositorioRecordatoriosCaja;
      const ACodigoEmpresa, ACodigoCliente: string;
      const ANombreImpresora: string;
      ARutasPDF: TStrings;
      ASoloPDF: Boolean);
    procedure Ejecutar;
  end;

function CalcularTotalDepositoRecordatorio(
  const ADeposito: TDepositoPendienteTicketCaja): Currency;
var
  dCantidad: Double;
begin
  dCantidad := ADeposito.CantidadPendiente;
  if dCantidad = 0 then
    dCantidad := 1;
  Result := ADeposito.PrecioVenta * dCantidad;
end;

function CalcularPendienteDepositoRecordatorio(
  const ADeposito: TDepositoPendienteTicketCaja): Currency;
begin
  Result := CalcularTotalDepositoRecordatorio(ADeposito) -
    ADeposito.ImporteAnticipo;
end;

function ConstruirOrigenRecordatorio(
  const AEmpresa, AAlmacen, ACaja: string): string;
begin
  Result := AEmpresa;
  if AAlmacen <> '' then
    Result := Result + '/' + AAlmacen;
  if ACaja <> '' then
    Result := Result + '/' + ACaja;
end;

function ConceptoAnticipoRecordatorio(
  const ATipoOperacion: string): string;
begin
  Result := '';
  if ATipoOperacion = 'DE' then
    Result := STicketEntregaInicial
  else if ATipoOperacion = 'CB' then
    Result := STicketACuenta;
end;

constructor TGeneradorRecordatorioTicket.Create(
  const APreview: IPreviewTicket;
  const ARepositorio: IRepositorioRecordatoriosCaja;
  const ACodigoEmpresa, ACodigoCliente: string;
  const ANombreImpresora: string;
  ARutasPDF: TStrings;
  ASoloPDF: Boolean);
begin
  inherited Create;
  FPreview := APreview;
  FRepositorio := ARepositorio;
  FCodigoEmpresa := ACodigoEmpresa;
  FCodigoCliente := ACodigoCliente;
  FNombreImpresora := ANombreImpresora;
  FRutasPDF := ARutasPDF;
  FSoloPDF := ASoloPDF;
end;

function TGeneradorRecordatorioTicket.CargarDatos: Boolean;
begin
  Result := (Trim(FCodigoCliente) <> '') and Assigned(FRepositorio);
  if Result then
  begin
    FDepositos :=
      FRepositorio.ListarDepositosPendientesRecordatorio(
        FCodigoCliente);
    Result := Length(FDepositos) > 0;
  end;
  if Result then
    FEmpresa := FRepositorio.ObtenerEmpresaRecordatorio(FCodigoEmpresa);
end;

procedure TGeneradorRecordatorioTicket.EscribirCabecera;
begin
  FTicket.Inicializar;
  FTicket.Alinear(alCentro);
  FTicket.Negrita(True);
  FTicket.SaltarLineas(3);
  FTicket.EscribirLinea(STicketEstadoCuentaDepositos);
  FTicket.EscribirLinea(
    FormatDateTime(STicketFormatoFechaLarga, Now));
  FTicket.Negrita(False);
  FTicket.LineaSeparadora('-');
  FTicket.Alinear(alIzquierda);
  FTicket.Negrita(True);
  FTicket.EscribirLinea(STicketEmpresa);
  FTicket.Negrita(False);
  FTicket.EscribirLinea(
    Format('%-4s %s',
      [FEmpresa.Codigo, Copy(FEmpresa.RazonSocial, 1, 36)]));
  FTicket.Negrita(True);
  FTicket.EscribirLinea(STicketCliente);
  FTicket.Negrita(False);
  FTicket.EscribirLinea(
    Format('%-4s %s',
      [FDepositos[0].CodigoCliente,
       Copy(FDepositos[0].RazonSocialCliente, 1, 36)]));
  FTicket.LineaSeparadora('-');
  FTicket.EscribirLinea(
    Format('%-14s %13s %13s',
      [STicketFechaHora, STicketTotal, STicketPendiente]));
  FTicket.LineaSeparadora('-');
end;

procedure TGeneradorRecordatorioTicket.EscribirAnticipo(
  const AAnticipo: TAnticipoRecordatorioTicketCaja);
var
  sConcepto: string;
  sOrigen: string;
begin
  sConcepto := ConceptoAnticipoRecordatorio(
    AAnticipo.TipoOperacion);
  sOrigen := ConstruirOrigenRecordatorio(
    AAnticipo.Empresa,
    AAnticipo.Almacen,
    AAnticipo.Caja);
  FTicket.Alinear(alIzquierda);
  FTicket.EscribirLinea(
    sConcepto + '  ' +
    FormatDateTime('dd/mm/yy HH:nn', AAnticipo.FechaOperacion));
  FTicket.EscribirLinea(
    Format('   %-10s %13s',
      ['(' + sOrigen + ')',
       '-' + FormatFloat('#,##0.00', AAnticipo.Importe) + ' €']));
  FTicket.Alinear(alDerecha);
end;

procedure TGeneradorRecordatorioTicket.EscribirDeposito(
  const ADeposito: TDepositoPendienteTicketCaja);
var
  dPendiente: Currency;
  dTotal: Currency;
  i: Integer;
  oAnticipos: TArray<TAnticipoRecordatorioTicketCaja>;
  sOrigen: string;
begin
  dTotal := CalcularTotalDepositoRecordatorio(ADeposito);
  dPendiente := CalcularPendienteDepositoRecordatorio(ADeposito);
  FTotalPendiente := FTotalPendiente + dPendiente;
  sOrigen := ConstruirOrigenRecordatorio(
    ADeposito.Empresa,
    ADeposito.Almacen,
    ADeposito.Caja);
  FTicket.Alinear(alIzquierda);
  FTicket.EscribirLinea(
    Format('%-14s %13s %13s',
      [FormatDateTime('dd/mm/yy HH:nn', ADeposito.FechaCreacion),
       FormatFloat('#,##0.00 €', dTotal),
       FormatFloat('#,##0.00 €', dPendiente)]));
  FTicket.EscribirLinea(
    '  ' + Copy(ADeposito.CodigoUnidad, 1, 40));
  FTicket.EscribirLinea(
    '  ' + Copy(ADeposito.Descripcion, 1, 40));
  FTicket.EscribirLinea(Format(STicketRetiradoEn, [sOrigen]));
  oAnticipos := FRepositorio.ListarAnticiposRecordatorio(
    ADeposito.IdDeposito);
  for i := 0 to High(oAnticipos) do
    EscribirAnticipo(oAnticipos[i]);
  FTicket.SaltarLineas(1);
end;

procedure TGeneradorRecordatorioTicket.EscribirDepositos;
var
  i: Integer;
begin
  FTotalPendiente := 0;
  for i := 0 to High(FDepositos) do
    EscribirDeposito(FDepositos[i]);
end;

procedure TGeneradorRecordatorioTicket.EscribirResumen;
begin
  FTicket.Alinear(alIzquierda);
  FTicket.LineaSeparadora('-');
  FTicket.Negrita(True);
  FTicket.TextoColumnas(
    STicketTotalPendientePago,
    FormatFloat('#,##0.00', FTotalPendiente) + ' €');
  FTicket.Negrita(False);
end;

procedure TGeneradorRecordatorioTicket.GenerarSalida;
var
  sComandosEsc: string;
  sRutaFicheroPdf: string;
begin
  sComandosEsc := FTicket.ObtenerComandos;
  sRutaFicheroPdf :=
    GetUserFolderTickets + 'Recordatorio_' +
    FormatDateTime('yyyy_mm_dd_hh_nn_ss', Now) + '.pdf';
  ImprimirOPrevisualizarTicket(
    FPreview,
    FTicket,
    sComandosEsc,
    sRutaFicheroPdf,
    FNombreImpresora,
    FSoloPDF);
  if (FRutasPDF <> nil) and FileExists(sRutaFicheroPdf) then
    FRutasPDF.Add(sRutaFicheroPdf);
end;

procedure TGeneradorRecordatorioTicket.Ejecutar;
begin
  if CargarDatos then
  begin
    FTicket := TTicketTermico.Create(FNombreImpresora);
    try
      EscribirCabecera;
      EscribirDepositos;
      EscribirResumen;
      GenerarSalida;
    finally
      FreeAndNil(FTicket);
    end;
  end;
end;

procedure ImprimirRecordatorioTicket(
  const APreview: IPreviewTicket;
  const ARepositorio: IRepositorioRecordatoriosCaja;
  const ACodigoEmpresa, ACodigoCliente: string;
  const ANombreImpresora: string;
  ARutasPDF: TStrings;
  ASoloPDF: Boolean);
var
  oGenerador: TGeneradorRecordatorioTicket;
begin
  oGenerador := TGeneradorRecordatorioTicket.Create(
    APreview,
    ARepositorio,
    ACodigoEmpresa,
    ACodigoCliente,
    ANombreImpresora,
    ARutasPDF,
    ASoloPDF);
  try
    oGenerador.Ejecutar;
  finally
    FreeAndNil(oGenerador);
  end;
end;

end.
