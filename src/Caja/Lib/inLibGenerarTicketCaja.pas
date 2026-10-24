{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGenerarTicketCaja                                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Generación de tickets no fiscales y apertura manual del cajón de Caja.    }
{******************************************************************************}
unit inLibGenerarTicketCaja;

interface

uses
  System.Classes,
  Uni,
  inLibGenerarTicketCajaPersistenciaIntf,
  inLibGenerarTicketIntf,
  inLibParametrosIntf,
  inLibPermisosIntf,
  inLibPreviewTicket;

type
  TEstadoAperturaCajon = (
    eacAbierto,
    eacSimulada,
    eacSinPermiso,
    eacSinImpresora
  );
  TResultadoAperturaCajon = record
    Estado: TEstadoAperturaCajon;
    Mensaje: string;
    function Correcto: Boolean;
  end;
  TModeloTicketOperacionCaja = record
    Encontrada: Boolean;
    Titulo: string;
    FechaTexto: string;
    CodigoEmpleado: string;
    Concepto: string;
    Importe: Currency;
  end;

function PrepararModeloTicketOperacionCaja(
  const ALecturasTicket: ILecturasImpresionTicket;
  const AClave: TClaveOperacionTicketCaja):
  TModeloTicketOperacionCaja;

procedure ImprimirTicketOperacionCaja(
  const APreview: IPreviewTicket;
  const ALecturasTicket: ILecturasImpresionTicket;
  const AEmpresa, AAlmacen, ACaja, ANumOperacion: string;
  const ANombreImpresora: string = 'DEBUG';
  ARutasPDF: TStrings = nil;
  ASoloPDF: Boolean = False); overload;

procedure ImprimirTicketOperacionCaja(
  const APreview: IPreviewTicket;
  AConexion: TUniConnection;
  const ALecturasTicket: ILecturasImpresionTicket;
  const AEmpresa, AAlmacen, ACaja, ANumOperacion: string;
  const ANombreImpresora: string = 'DEBUG';
  ARutasPDF: TStrings = nil;
  ASoloPDF: Boolean = False); overload;

function AbrirCajonSinVenta(
  const APermisos: IPermisosAplicacion;
  const AParametrosCaja: IParametrosCaja): TResultadoAperturaCajon;

// FZ-ISSUE-395: apertura que acompaña a un cobro. No pasa por el permiso
// caja.abrirCajon, que es solo el de abrir el cajón sin venta (F9).
function AbrirCajonTrasVenta(
  const AParametrosCaja: IParametrosCaja): TResultadoAperturaCajon;

function ImpresoraCajaAsignada(
  const AParametrosCaja: IParametrosCaja): Boolean;

implementation

uses
  System.SysUtils,
  inLibDir,
  inLibFTicket,
  inLibMsgCaja,
  inLibMsgConfiguracion,
  inLibMsgTickets;

type
  TContextoImpresionTicketOperacionCaja = record
    Preview: IPreviewTicket;
    Clave: TClaveOperacionTicketCaja;
    NombreImpresora: string;
    RutasPdf: TStrings;
    SoloPdf: Boolean;
  end;

function TResultadoAperturaCajon.Correcto: Boolean;
begin
  Result := Estado in [eacAbierto, eacSimulada];
end;

function PrepararModeloTicketOperacionCaja(
  const ALecturasTicket: ILecturasImpresionTicket;
  const AClave: TClaveOperacionTicketCaja):
  TModeloTicketOperacionCaja;
var
  oDatos: TDatosOperacionTicketCaja;
begin
  Result := Default(TModeloTicketOperacionCaja);
  if Assigned(ALecturasTicket) then
  begin
    oDatos := ALecturasTicket.ObtenerOperacion(AClave);
    Result.Encontrada := oDatos.Encontrada;
    if Result.Encontrada then
    begin
      Result.FechaTexto := FormatDateTime(
        'dd/mm/yyyy hh:nn',
        oDatos.FechaOperacion);
      Result.CodigoEmpleado := oDatos.CodigoEmpleado;
      Result.Concepto := oDatos.Concepto;
      Result.Importe := oDatos.Importe;
      if oDatos.TipoOperacion = 'EC' then
        Result.Titulo := STicketEntradaCambio
      else
        Result.Titulo := STicketGastoRetiradaCaja;
    end;
  end;
end;

procedure EscribirConceptoTicket(
  ATicket: TTicketTermico;
  const AConcepto: string);
var
  iCorte: Integer;
  sPendiente: string;
begin
  sPendiente := Trim(STicketConcepto + ' ' + AConcepto);
  while Length(sPendiente) > N_CHAR_LIN do
  begin
    iCorte := LastDelimiter(' ', Copy(sPendiente, 1, N_CHAR_LIN + 1));
    if iCorte > 1 then
    begin
      ATicket.EscribirLinea(Copy(sPendiente, 1, iCorte - 1));
      Delete(sPendiente, 1, iCorte);
    end
    else
    begin
      ATicket.EscribirLinea(Copy(sPendiente, 1, N_CHAR_LIN));
      Delete(sPendiente, 1, N_CHAR_LIN);
    end;
    sPendiente := TrimLeft(sPendiente);
  end;
  ATicket.EscribirLinea(sPendiente);
end;

procedure EscribirContenidoTicketOperacionCaja(
  ATicket: TTicketTermico;
  const AContexto: TContextoImpresionTicketOperacionCaja;
  const AModelo: TModeloTicketOperacionCaja);
begin
  ATicket.Inicializar;
  ATicket.Alinear(alCentro);
  ATicket.Negrita(True);
  ATicket.EscribirLinea(AModelo.Titulo);
  ATicket.Negrita(False);
  ATicket.LineaSeparadora;
  ATicket.Alinear(alIzquierda);
  ATicket.TextoColumnas(STicketFecha, AModelo.FechaTexto);
  ATicket.TextoColumnas(STicketCaja, AContexto.Clave.Caja);
  ATicket.TextoColumnas(
    STicketEmpleado,
    AModelo.CodigoEmpleado);
  ATicket.TextoColumnas(
    STicketOperacionAbreviada,
    AContexto.Clave.NumeroOperacion);
  if AModelo.Concepto <> '' then
  begin
    EscribirConceptoTicket(ATicket, AModelo.Concepto);
  end;
  ATicket.LineaSeparadora;
  ATicket.Negrita(True);
  ATicket.TextoColumnas(
    STicketImporte,
    FormatFloat(',0.00', AModelo.Importe) + ' EUR');
  ATicket.Negrita(False);
  ATicket.LineaSeparadora;
  ATicket.Alinear(alCentro);
  ATicket.EscribirLinea(STicketFirma);
  ATicket.SaltarLineas(2);
  ATicket.LineaSeparadora('.');
  // Justificante interno de caja: sin el pie comercial de los tickets de
  // venta, que habla de compras y devoluciones (FZ-ISSUE-313).
  ATicket.SaltarLineas(1);
  ATicket.CortarPapel;
end;

procedure ImprimirModeloTicketOperacionCaja(
  const AContexto: TContextoImpresionTicketOperacionCaja;
  const AModelo: TModeloTicketOperacionCaja);
var
  oTicket: TTicketTermico;
  sComandosEsc: string;
  sRutaFicheroPdf: string;
begin
  oTicket := TTicketTermico.Create(AContexto.NombreImpresora);
  try
    EscribirContenidoTicketOperacionCaja(
      oTicket,
      AContexto,
      AModelo);
    sComandosEsc := oTicket.ObtenerComandos;
    sRutaFicheroPdf := GetUserFolderTickets + 'ticket_caja_' +
      AContexto.Clave.NumeroOperacion + '.pdf';
    ImprimirOPrevisualizarTicket(
      AContexto.Preview,
      oTicket,
      sComandosEsc,
      sRutaFicheroPdf,
      AContexto.NombreImpresora,
      AContexto.SoloPdf);
    if Assigned(AContexto.RutasPdf) and
       FileExists(sRutaFicheroPdf) then
    begin
      AContexto.RutasPdf.Add(sRutaFicheroPdf);
    end;
  finally
    FreeAndNil(oTicket);
  end;
end;

procedure ImprimirTicketOperacionCaja(
  const APreview: IPreviewTicket;
  const ALecturasTicket: ILecturasImpresionTicket;
  const AEmpresa, AAlmacen, ACaja, ANumOperacion: string;
  const ANombreImpresora: string;
  ARutasPDF: TStrings;
  ASoloPDF: Boolean); overload;
var
  oClave: TClaveOperacionTicketCaja;
  oContexto: TContextoImpresionTicketOperacionCaja;
  oModelo: TModeloTicketOperacionCaja;
begin
  oClave := Default(TClaveOperacionTicketCaja);
  oClave.Empresa := AEmpresa;
  oClave.Almacen := AAlmacen;
  oClave.Caja := ACaja;
  oClave.NumeroOperacion := ANumOperacion;
  oModelo := PrepararModeloTicketOperacionCaja(
    ALecturasTicket,
    oClave);
  if oModelo.Encontrada then
  begin
    oContexto := Default(TContextoImpresionTicketOperacionCaja);
    oContexto.Preview := APreview;
    oContexto.Clave := oClave;
    oContexto.NombreImpresora := ANombreImpresora;
    oContexto.RutasPdf := ARutasPDF;
    oContexto.SoloPdf := ASoloPDF;
    ImprimirModeloTicketOperacionCaja(
      oContexto,
      oModelo);
  end;
end;

procedure ImprimirTicketOperacionCaja(
  const APreview: IPreviewTicket;
  AConexion: TUniConnection;
  const ALecturasTicket: ILecturasImpresionTicket;
  const AEmpresa, AAlmacen, ACaja, ANumOperacion: string;
  const ANombreImpresora: string;
  ARutasPDF: TStrings;
  ASoloPDF: Boolean); overload;
begin
  ImprimirTicketOperacionCaja(
    APreview,
    ALecturasTicket,
    AEmpresa,
    AAlmacen,
    ACaja,
    ANumOperacion,
    ANombreImpresora,
    ARutasPDF,
    ASoloPDF);
end;

function ImpresoraCajaAsignada(
  const AParametrosCaja: IParametrosCaja): Boolean;
var
  sImpresora: string;
begin
  Result := Assigned(AParametrosCaja);
  if Result then
  begin
    sImpresora := Trim(AParametrosCaja.ImpresoraCaja);
    Result := (sImpresora <> '') and
              (UpperCase(sImpresora) <> 'DEBUG');
  end;
end;

function AbrirCajonSinVenta(
  const APermisos: IPermisosAplicacion;
  const AParametrosCaja: IParametrosCaja): TResultadoAperturaCajon;
begin
  if (not Assigned(APermisos)) or
     (not APermisos.TienePermiso(
       PERMISO_CAJA_ABRIR_CAJON,
       paPermitir)) then
  begin
    Result.Estado := eacSinPermiso;
    Result.Mensaje := SErrorPermisoAbrirCajon;
  end
  else
    Result := AbrirCajonTrasVenta(AParametrosCaja);
end;

function AbrirCajonTrasVenta(
  const AParametrosCaja: IParametrosCaja): TResultadoAperturaCajon;
var
  oTicket: TTicketTermico;
begin
  if Assigned(AParametrosCaja) and
     SameText(Trim(AParametrosCaja.ImpresoraCaja), 'DEBUG') then
  begin
    Result.Estado := eacSimulada;
    Result.Mensaje := '';
  end
  else if not ImpresoraCajaAsignada(AParametrosCaja) then
  begin
    Result.Estado := eacSinImpresora;
    Result.Mensaje := SErrorImpresoraTicketsCajaNoConfigurada;
  end
  else
  begin
    oTicket := TTicketTermico.Create(AParametrosCaja.ImpresoraCaja);
    try
      oTicket.AbrirCajon;
      oTicket.Imprimir;
    finally
      FreeAndNil(oTicket);
    end;
    Result.Estado := eacAbierto;
    Result.Mensaje := '';
  end;
end;

end.
