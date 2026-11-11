{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalFacturarTicket                                      }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       2.0.0                                                         }
{   Fecha:       28/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Crea una factura NORMAL en sustitución de un ticket. Pide los datos con   }
{    el diálogo común de creación de documentos: cliente (búsqueda y alta      }
{    rápida), serie, número, fecha y forma de pago. El formulario no se        }
{    muestra: sólo aporta la conexión y los servicios heredados de TfrmBase.   }
{******************************************************************************}
unit inMtoModalFacturarTicket;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms, cxMemo, cxButtons,
  inMtoFrmBase, inLibOpcionesDocumentoIntf,
  inLibFacturacionTicketPersistenciaIntf;

type
  TFacturarTicketResult = record
    Aceptado: Boolean;
    SerieNueva: string;
    NumeroNueva: string;
    FormatoDocumento: string;
  end;

  TfrmModalFacturarTicket = class(TfrmBase)
  private
    FSerieTicket: string;
    FNumeroTicket: string;
    FEmpresa: string;
    FServicioFacturacion: IServicioFacturacionTicket;
    FPorPeriodo: Boolean;
    FDesde: TDateTime;
    FHasta: TDateTime;
    FTickets: TTicketsFacturacion;
    FOpcionesRevision: TOpcionesDocumento;
    FMemoRevision: TcxMemo;
    FBotonEmitir: TcxButton;
    function BuscarCliente(var ACodigo, ADescripcion: string): Boolean;
    function AltaRapidaCliente(var ACodigo, ADescripcion: string): Boolean;
    function ResolverCliente(const ACodigo: string;
      out ADescripcion: string): Boolean;
    function ComprobarClienteFacturaNormal(
      const AOpciones: TOpcionesDocumento; out AMensaje: string): Boolean;
    function ComprobarFacturaNormal(
      const AOpciones: TOpcionesDocumento; out AMensaje: string): Boolean;
    function Configurar(
      const AAlmacen: string): TConfiguracionOpcionesDocumento;
    function CrearFacturaNormal(
      const AOpciones: TOpcionesDocumento): TFacturarTicketResult;
    function ConfigurarPeriodo: TConfiguracionOpcionesDocumento;
    function ComprobarPeriodo(const AOpciones: TOpcionesDocumento;
      out AMensaje: string): Boolean;
    procedure CrearBotonesRevision(APadre: TWinControl);
    function CrearRevision(out ATexto: TcxMemo): TfrmBase;
    procedure RefrescarRevision;
    function SeleccionarTicket(const ATickets: TTicketsFacturacion;
      out AIndice: Integer): Boolean;
    function TicketSeleccionado(const ATicket: TTicketFacturacion): Boolean;
    procedure AnadirTicketSinCliente;
    procedure BuscarTicketSinCliente(Sender: TObject);
    procedure RetirarTicket(Sender: TObject);
    function RevisarTickets(const AOpciones: TOpcionesDocumento): Boolean;
  public
    class function EjecutarPeriodo(
      AOwner: TComponent): TFacturarTicketResult;
    class function Ejecutar(
      AOwner: TComponent;
      const ASerieTicket: string;
      const ANumeroTicket: string;
      const AEmpresa: string;
      const AAlmacen: string): TFacturarTicketResult;
  end;

implementation

uses
  inLibFormatoDocumento, UniDataFormatoDocumentoRepositorio,
  Data.DB, Datasnap.DBClient, System.UITypes, System.DateUtils, Vcl.Dialogs,
  Vcl.StdCtrls, cxGroupBox, inLibMensajesVcl,
  UniDataNumeracionDocumentos,
  inMtoGenSearch, inLibDocumentoFiscal, inLibFacturasValidacionCabecera,
  inLibMsgFacturas, inLibMsgVentas, inLibMsgOpcionesDocumento,
  inLibVerifactuTipos,
  inLibVentasPantallaIntf,
  UniDataVentasPantallaComposicion,
  inLibClientesAltaRapida, inMtoModalAltaRapidaCliente,
  UniDataClientesAltaRapida,
  inMtoModalOpcionesDocumento, UniDataOpcionesDocumentoRepositorio;

{$R *.dfm}

const
  CLAVE_CLIENTE = 'CLIENTE';

class function TfrmModalFacturarTicket.EjecutarPeriodo(
  AOwner: TComponent): TFacturarTicketResult;
var
  oContexto: TContextoFacturacionTicketVentasPantalla;
  oFormulario: TfrmModalFacturarTicket;
  oOpciones: TOpcionesDocumento;
begin
  Result := Default(TFacturarTicketResult);
  oFormulario := TfrmModalFacturarTicket.Create(AOwner);
  try
    oFormulario.FPorPeriodo := True;
    CrearContextoVentasPantalla(oFormulario.ConexionPrincipal,
      oFormulario.ParametrosApp, oFormulario.ParametrosCaja,
      oFormulario.RegistroLog, oContexto);
    oFormulario.FServicioFacturacion := oContexto.Facturacion;
    if TfrmModalOpcionesDocumento.Solicitar(AOwner,
      CrearLectorOpcionesDocumentoUniDAC(oFormulario.ConexionPrincipal),
      oFormulario.ConfigurarPeriodo, oOpciones) then
    begin
      oFormulario.FEmpresa := oOpciones.Empresa;
      if oFormulario.RevisarTickets(oOpciones) then
        Result := oFormulario.CrearFacturaNormal(oOpciones);
    end;
  finally
    FreeAndNil(oFormulario);
  end;
end;

function TfrmModalFacturarTicket.ConfigurarPeriodo:
  TConfiguracionOpcionesDocumento;
var
  oPeriodicidad, oMes, oAnyo: TCampoAdicionalOpcionesDocumento;
  iMes: Integer;
  dtPropuesta: TDateTime;
begin
  Result := Configurar('');
  Result.Titulo := SFacturacionSimplificadosTitulo;
  Result.Aviso := SFacturacionSimplificadosAviso;
  Result.Fijos := [];
  Result.Validar := ComprobarPeriodo;
  dtPropuesta := IncMonth(StartOfTheMonth(Date), -1);
  oPeriodicidad := Default(TCampoAdicionalOpcionesDocumento);
  oPeriodicidad.Clave := 'PERIODICIDAD';
  oPeriodicidad.Etiqueta := SFacturacionSimplificadosPeriodicidad;
  oPeriodicidad.Clase := ccaLista;
  oPeriodicidad.Valor := 'M';
  SetLength(oPeriodicidad.Elementos, 2);
  oPeriodicidad.Elementos[0].Codigo := 'M';
  oPeriodicidad.Elementos[0].Nombre := SFacturacionSimplificadosMensual;
  oPeriodicidad.Elementos[1].Codigo := 'T';
  oPeriodicidad.Elementos[1].Nombre := SFacturacionSimplificadosTrimestral;
  oMes := Default(TCampoAdicionalOpcionesDocumento);
  oMes.Clave := 'MES';
  oMes.Etiqueta := SFacturacionSimplificadosMes;
  oMes.Clase := ccaLista;
  oMes.Valor := IntToStr(MonthOf(dtPropuesta));
  SetLength(oMes.Elementos, 12);
  for iMes := 1 to 12 do
  begin
    oMes.Elementos[iMes - 1].Codigo := IntToStr(iMes);
    oMes.Elementos[iMes - 1].Nombre := Format('%.2d', [iMes]);
  end;
  oAnyo := Default(TCampoAdicionalOpcionesDocumento);
  oAnyo.Clave := 'ANYO';
  oAnyo.Etiqueta := SFacturacionSimplificadosAnyo;
  oAnyo.Clase := ccaTexto;
  oAnyo.Valor := IntToStr(YearOf(dtPropuesta));
  oAnyo.LongitudMaxima := 4;
  Result.Propuesta.Adicionales := Result.Propuesta.Adicionales +
    [oPeriodicidad, oMes, oAnyo];
end;

function TfrmModalFacturarTicket.ComprobarPeriodo(
  const AOpciones: TOpcionesDocumento; out AMensaje: string): Boolean;
var
  iMes, iAnyo, iMeses: Integer;
begin
  AMensaje := '';
  iMes := StrToIntDef(AOpciones.Adicional('MES'), 0);
  iAnyo := StrToIntDef(AOpciones.Adicional('ANYO'), 0);
  if (iMes < 1) or (iMes > 12) or (iAnyo < 1900) or
     (iAnyo > 9998) then
    AMensaje := SFacturacionSimplificadosPeriodoInvalido
  else
  begin
    iMeses := 1;
    if AOpciones.Adicional('PERIODICIDAD') = 'T' then
    begin
      iMes := ((iMes - 1) div 3) * 3 + 1;
      iMeses := 3;
    end;
    FDesde := EncodeDate(iAnyo, iMes, 1);
    FHasta := IncMonth(FDesde, iMeses) - 1;
    if FHasta >= Date then
      AMensaje := SFacturacionSimplificadosPeriodoAbierto
    else if (Trunc(AOpciones.Fecha) < FHasta) or
            (Trunc(AOpciones.Fecha) > Date) then
      AMensaje := SFacturacionSimplificadosFechaInvalida
    else
      AMensaje := ErrorFechaFacturaSustitucionTicket(
        AOpciones.Fecha, FHasta, Date);
    if AMensaje = '' then
      AMensaje := ErrorTrimestreFacturaTickets(AOpciones.Fecha, FDesde);
    if AMensaje = '' then
      ComprobarClienteFacturaNormal(AOpciones, AMensaje);
  end;
  Result := AMensaje = '';
end;

procedure TfrmModalFacturarTicket.CrearBotonesRevision(
  APadre: TWinControl);
var
  oEmitir, oCancelar, oBuscar, oRetirar: TcxButton;
begin
  oEmitir := TcxButton.Create(APadre);
  oEmitir.Parent := APadre;
  oEmitir.Align := alRight;
  oEmitir.Width := ScaleValue(180);
  oEmitir.Caption := SFacturacionSimplificadosEmitir;
  oEmitir.ModalResult := mrOk;
  FBotonEmitir := oEmitir;
  oCancelar := TcxButton.Create(APadre);
  oCancelar.Parent := APadre;
  oCancelar.Align := alRight;
  oCancelar.Width := ScaleValue(120);
  oCancelar.Caption := SFacturacionSimplificadosCancelar;
  oCancelar.Cancel := True;
  oCancelar.ModalResult := mrCancel;
  oBuscar := TcxButton.Create(APadre);
  oBuscar.Parent := APadre;
  oBuscar.Align := alLeft;
  oBuscar.Width := ScaleValue(220);
  oBuscar.Caption := SFacturacionSimplificadosBuscar;
  oBuscar.OnClick := BuscarTicketSinCliente;
  oRetirar := TcxButton.Create(APadre);
  oRetirar.Parent := APadre;
  oRetirar.Align := alLeft;
  oRetirar.Width := ScaleValue(140);
  oRetirar.Caption := SFacturacionSimplificadosRetirar;
  oRetirar.OnClick := RetirarTicket;
end;

function TfrmModalFacturarTicket.CrearRevision(
  out ATexto: TcxMemo): TfrmBase;
var
  oPie: TcxGroupBox;
begin
  Result := TfrmBase.Create(Self);
  Result.Caption := SFacturacionSimplificadosRevision;
  Result.Position := poScreenCenter;
  Result.Width := ScaleValue(900);
  Result.Height := ScaleValue(620);
  oPie := TcxGroupBox.Create(Result);
  oPie.PanelStyle.Active := True;
  oPie.Transparent := True;
  oPie.Parent := Result;
  oPie.Align := alBottom;
  oPie.Height := ScaleValue(48);
  CrearBotonesRevision(oPie);
  ATexto := TcxMemo.Create(Result);
  ATexto.Parent := Result;
  ATexto.Align := alClient;
  ATexto.Properties.ReadOnly := True;
  ATexto.Properties.ScrollBars := ssBoth;
  ATexto.Properties.WordWrap := False;
end;

procedure TfrmModalFacturarTicket.RefrescarRevision;
var
  oTexto: TcxMemo;
  oTicket: TTicketFacturacion;
  cTotal: Currency;
begin
  oTexto := FMemoRevision;
  oTexto.Lines.BeginUpdate;
  try
    oTexto.Clear;
    oTexto.Lines.Add(SFacturacionSimplificadosCliente +
      FOpcionesRevision.DescripcionAdicional(CLAVE_CLIENTE));
    oTexto.Lines.Add(Format(SFacturacionSimplificadosPeriodo,
      [DateToStr(FDesde), DateToStr(FHasta)]));
    oTexto.Lines.Add(SFacturacionSimplificadosFecha +
      DateToStr(FOpcionesRevision.Fecha));
    oTexto.Lines.Add('');
    cTotal := 0;
    for oTicket in FTickets do
    begin
      oTexto.Lines.Add(Format(SFacturacionSimplificadosTotalTicket,
        [oTicket.Serie, oTicket.Numero, DateToStr(oTicket.Fecha),
        FormatCurr('#,##0.00', oTicket.Total)]));
      oTexto.Lines.Add(oTicket.Detalle);
      cTotal := cTotal + oTicket.Total;
    end;
    oTexto.Lines.Add(Format(SFacturacionSimplificadosTotal,
      [Length(FTickets), FormatCurr('#,##0.00', cTotal)]));
    FBotonEmitir.Enabled := (Length(FTickets) > 0) and
      (Length(FTickets) <= MAX_TICKETS_FACTURA_F3);
    if Length(FTickets) > MAX_TICKETS_FACTURA_F3 then
      oTexto.Lines.Add(Format(SErrorMaxTicketsFacturaF3,
        [MAX_TICKETS_FACTURA_F3]));
  finally
    oTexto.Lines.EndUpdate;
  end;
end;


function TfrmModalFacturarTicket.RevisarTickets(
  const AOpciones: TOpcionesDocumento): Boolean;
var
  oRevision: TfrmBase;
begin
  FOpcionesRevision := AOpciones;
  FTickets := FServicioFacturacion.ConsultarTicketsPeriodo(
    AOpciones.Empresa, AOpciones.Adicional(CLAVE_CLIENTE), FDesde, FHasta);
  oRevision := CrearRevision(FMemoRevision);
  try
    RefrescarRevision;
    Result := oRevision.ShowModal = mrOk;
  finally
    FMemoRevision := nil;
    FBotonEmitir := nil;
    FreeAndNil(oRevision);
  end;
end;

function TfrmModalFacturarTicket.SeleccionarTicket(
  const ATickets: TTicketsFacturacion; out AIndice: Integer): Boolean;
var
  oDatos: TClientDataSet;
  oBusqueda: TfrmMtoSearch;
  iIndice: Integer;
begin
  AIndice := -1;
  oDatos := TClientDataSet.Create(nil);
  oBusqueda := nil;
  try
    oDatos.FieldDefs.Add('Indice', ftInteger);
    oDatos.FieldDefs.Add('Serie', ftString, 20);
    oDatos.FieldDefs.Add('Numero', ftString, 20);
    oDatos.FieldDefs.Add('Fecha', ftDate);
    oDatos.FieldDefs.Add('Total', ftCurrency);
    oDatos.CreateDataSet;
    oDatos.FieldByName('Indice').Visible := False;
    for iIndice := 0 to High(ATickets) do
      oDatos.AppendRecord([iIndice, ATickets[iIndice].Serie,
        ATickets[iIndice].Numero, ATickets[iIndice].Fecha,
        ATickets[iIndice].Total]);
    oDatos.First;
    oBusqueda := TfrmMtoSearch.Create(Self);
    oBusqueda.Name := 'frmMtoTicketsPeriodoSearch';
    oBusqueda.Caption := SFacturacionSimplificadosBuscar;
    oBusqueda.dsTablaG.DataSet := oDatos;
    oBusqueda.ProcesarPerfiles;
    oBusqueda.ShowModal;
    Result := (oBusqueda.sFicha = 'S') and not oDatos.IsEmpty;
    if Result then
      AIndice := oDatos.FieldByName('Indice').AsInteger;
  finally
    if Assigned(oBusqueda) then
      oBusqueda.dsTablaG.DataSet := nil;
    FreeAndNil(oBusqueda);
    FreeAndNil(oDatos);
  end;
end;

function TfrmModalFacturarTicket.TicketSeleccionado(
  const ATicket: TTicketFacturacion): Boolean;
var
  oTicket: TTicketFacturacion;
begin
  Result := False;
  for oTicket in FTickets do
    if (oTicket.Serie = ATicket.Serie) and
       (oTicket.Numero = ATicket.Numero) then
      Result := True;
end;

procedure TfrmModalFacturarTicket.BuscarTicketSinCliente(Sender: TObject);
begin
  AnadirTicketSinCliente;
end;

procedure TfrmModalFacturarTicket.AnadirTicketSinCliente;
var
  oDisponibles, oCandidatos: TTicketsFacturacion;
  oTicket: TTicketFacturacion;
  iIndice: Integer;
begin
  oDisponibles := FServicioFacturacion.ConsultarTicketsSinCliente(
    FOpcionesRevision.Empresa, FDesde, FHasta);
  oCandidatos := nil;
  for oTicket in oDisponibles do
    if not TicketSeleccionado(oTicket) then
      oCandidatos := oCandidatos + [oTicket];
  if Length(oCandidatos) = 0 then
    ShowMessage_fza(SFacturacionSimplificadosSinCandidatos)
  else if SeleccionarTicket(oCandidatos, iIndice) then
  begin
    FTickets := FTickets + [oCandidatos[iIndice]];
    RefrescarRevision;
  end;
end;

procedure TfrmModalFacturarTicket.RetirarTicket(Sender: TObject);
var
  iIndice, iMover: Integer;
begin
  if (Length(FTickets) > 0) and SeleccionarTicket(FTickets, iIndice) then
  begin
    for iMover := iIndice to High(FTickets) - 1 do
      FTickets[iMover] := FTickets[iMover + 1];
    SetLength(FTickets, Length(FTickets) - 1);
    RefrescarRevision;
  end;
end;

class function TfrmModalFacturarTicket.Ejecutar(
  AOwner: TComponent;
  const ASerieTicket: string;
  const ANumeroTicket: string;
  const AEmpresa: string;
  const AAlmacen: string): TFacturarTicketResult;
var
  oContexto: TContextoFacturacionTicketVentasPantalla;
  oFormulario: TfrmModalFacturarTicket;
  oOpciones: TOpcionesDocumento;
begin
  Result := Default(TFacturarTicketResult);
  oFormulario := TfrmModalFacturarTicket.Create(AOwner);
  try
    oFormulario.FSerieTicket := ASerieTicket;
    oFormulario.FNumeroTicket := ANumeroTicket;
    oFormulario.FEmpresa := AEmpresa;
    CrearContextoVentasPantalla(
      oFormulario.ConexionPrincipal,
      oFormulario.ParametrosApp,
      oFormulario.ParametrosCaja,
      oFormulario.RegistroLog,
      oContexto);
    oFormulario.FServicioFacturacion := oContexto.Facturacion;
    if TfrmModalOpcionesDocumento.Solicitar(AOwner,
         CrearLectorOpcionesDocumentoUniDAC(oFormulario.ConexionPrincipal),
         oFormulario.Configurar(AAlmacen), oOpciones) then
      Result := oFormulario.CrearFacturaNormal(oOpciones);
    Result.FormatoDocumento := CrearFormatoDocumentoLecturas(
      oFormulario.ConexionPrincipal).LeerFormatoEmpresa(AEmpresa);
  finally
    oFormulario.FServicioFacturacion := nil;
    FreeAndNil(oFormulario);
  end;
end;

// Serie de la factura normal: la del almacén del ticket o la primera de la
// empresa; fecha, la de hoy; forma de pago, la del ticket.
function TfrmModalFacturarTicket.Configurar(
  const AAlmacen: string): TConfiguracionOpcionesDocumento;
var
  oTipo: TTipoOpcionesDocumento;
  oCliente: TCampoAdicionalOpcionesDocumento;
begin
  oTipo := Default(TTipoOpcionesDocumento);
  oTipo.Codigo := 'FC';
  oTipo.Nombre := SNombreFacturaVentaOpcionesDocumento;
  oCliente := Default(TCampoAdicionalOpcionesDocumento);
  oCliente.Clave := CLAVE_CLIENTE;
  oCliente.Etiqueta := SCaptionClienteOpcionesDocumento;
  oCliente.Clase := ccaBusqueda;
  oCliente.Obligatorio := True;
  oCliente.MensajeObligatorio := SErrorClienteBorradorNoSeleccionado;
  oCliente.LongitudMaxima := 20;
  oCliente.AlPrincipio := True;
  oCliente.Buscar := BuscarCliente;
  if PuedeAltaRapidaCliente(Permisos) then
    oCliente.Alta := AltaRapidaCliente;
  oCliente.Resolver := ResolverCliente;
  Result := Default(TConfiguracionOpcionesDocumento);
  Result.Titulo := STituloFacturarTicketOpcionesDocumento;
  Result.Aviso := Format(SAvisoFacturarTicketOpcionesDocumento,
    [FormatearDocumento(
      CrearFormatoDocumentoLecturas(ConexionPrincipal).LeerFormatoEmpresa(
        FEmpresa), FSerieTicket, FNumeroTicket)]);
  Result.Tipos := [oTipo];
  Result.Propuesta.Empresa := FEmpresa;
  Result.Propuesta.Almacen := AAlmacen;
  Result.Propuesta.Tipo := 'FC';
  Result.Propuesta.Fecha := Date;
  if not FPorPeriodo then
    Result.Propuesta.FormaPago := FServicioFacturacion.FormaPagoTicket(
      FSerieTicket, FNumeroTicket);
  Result.Propuesta.Adicionales := [oCliente];
  Result.Visibles := [codEmpresa, codSerie, codNumero, codFecha,
    codFormaPago];
  Result.Fijos := [codEmpresa];
  Result.PermiteNumeroManual := True;
  Result.Validar := ComprobarFacturaNormal;
end;

function TfrmModalFacturarTicket.BuscarCliente(var ACodigo,
  ADescripcion: string): Boolean;
var
  oClientes: TDataSet;
  oConsulta: IConsultaClientesFacturacionTicket;
  oFormulario: TfrmMtoSearch;
begin
  oConsulta := FServicioFacturacion.ConsultarClientes;
  oClientes := oConsulta.DataSet;
  oFormulario := TfrmMtoSearch.Create(nil);
  try
    oFormulario.Name := 'frmMtoCliSearch';
    oFormulario.Caption := STituloBusquedaClientes;
    oFormulario.dsTablaG.DataSet := oClientes;
    oFormulario.ProcesarPerfiles;
    oFormulario.ShowModal;
    Result := oFormulario.sFicha = 'S';
    if Result then
    begin
      ACodigo := oClientes.FieldByName('Código').AsString;
      ADescripcion := oClientes.FieldByName('Razón Social').AsString;
    end;
  finally
    oFormulario.dsTablaG.DataSet := nil;
    FreeAndNil(oFormulario);
    oConsulta := nil;
  end;
end;

function TfrmModalFacturarTicket.AltaRapidaCliente(var ACodigo,
  ADescripcion: string): Boolean;
var
  oResultado: TResultadoAltaRapidaCliente;
begin
  oResultado := TfrmModalAltaRapidaCliente.Ejecutar(Self,
    CrearAltaRapidaClientesUniDAC(ConexionPrincipal));
  Result := oResultado.Aceptado;
  if Result then
  begin
    ACodigo := oResultado.Codigo;
    ADescripcion := oResultado.RazonSocial;
  end;
end;

function TfrmModalFacturarTicket.ResolverCliente(const ACodigo: string;
  out ADescripcion: string): Boolean;
var
  oCliente: TClienteFacturacionTicket;
begin
  oCliente := FServicioFacturacion.ConsultarCliente(ACodigo);
  Result := oCliente.Existe;
  ADescripcion := oCliente.RazonSocial;
end;

// La factura normal necesita cliente con razón social y, en España, un
// documento fiscal válido.
function TfrmModalFacturarTicket.ComprobarClienteFacturaNormal(
  const AOpciones: TOpcionesDocumento; out AMensaje: string): Boolean;
var
  oCliente: TClienteFacturacionTicket;
begin
  AMensaje := '';
  oCliente := FServicioFacturacion.ConsultarCliente(
    AOpciones.Adicional(CLAVE_CLIENTE));
  if not oCliente.Existe then
    AMensaje := SErrorClienteFacturarTicketNoExiste
  else if Trim(oCliente.RazonSocial) = '' then
    AMensaje := SErrorRazonSocialFacturarTicketObligatoria
  else if PaisEsEspana(oCliente.CodigoPais, oCliente.NombrePais) and
          (not DocumentoFiscalValido(oCliente.Nif)) then
    AMensaje := SErrorDocumentoFiscalFacturarTicketNoValido +
      MensajeDocumentoFiscalInvalido(oCliente.Nif);
  Result := AMensaje = '';
end;

// La fecha va de la del ticket (y nunca antes del primer día del mismo
// trimestre del ejercicio anterior) a hoy; después, el cliente.
function TfrmModalFacturarTicket.ComprobarFacturaNormal(
  const AOpciones: TOpcionesDocumento; out AMensaje: string): Boolean;
begin
  AMensaje := ErrorFechaFacturaSustitucionTicket(AOpciones.Fecha,
    FServicioFacturacion.FechaTicket(FSerieTicket, FNumeroTicket), Date);
  if AMensaje <> '' then
    Result := False
  else
    Result := ComprobarClienteFacturaNormal(AOpciones, AMensaje);
end;

function TfrmModalFacturarTicket.CrearFacturaNormal(
  const AOpciones: TOpcionesDocumento): TFacturarTicketResult;
var
  oSolicitud: TSolicitudFacturacionTicket;
begin
  oSolicitud := Default(TSolicitudFacturacionTicket);
  oSolicitud.SerieNueva := AOpciones.Serie;
  oSolicitud.Cliente := AOpciones.Adicional(CLAVE_CLIENTE);
  oSolicitud.Fecha := AOpciones.Fecha;
  oSolicitud.Empresa := FEmpresa;
  oSolicitud.SerieTicket := FSerieTicket;
  oSolicitud.NumeroTicket := FNumeroTicket;
  oSolicitud.Usuario := IdentidadSesion.Usuario;
  oSolicitud.NumeroManual := AOpciones.Numero;
  oSolicitud.FormaPago := AOpciones.FormaPago;
  if FPorPeriodo then
  begin
    oSolicitud.Tickets := FTickets;
    oSolicitud.FechaDesde := FDesde;
    oSolicitud.FechaHasta := FHasta;
  end;
  PrepararNumeracionDocumento(ConexionPrincipal, dnFactura,
    FEmpresa, oSolicitud.SerieNueva, oSolicitud.Usuario,
    oSolicitud.NumeroManual, RegistroLog,
    function(AMensaje: string): Boolean
    begin
      Result := MessageDlg_fza(AMensaje, mtConfirmation,
        [mbYes, mbNo], 0) = mrYes;
    end);
  Result.NumeroNueva := FServicioFacturacion.CrearFactura(oSolicitud);
  Result.SerieNueva := AOpciones.Serie;
  Result.Aceptado := True;
end;

end.
