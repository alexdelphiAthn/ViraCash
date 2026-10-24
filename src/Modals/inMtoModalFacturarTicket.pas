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
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms,
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
  public
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
  Data.DB, System.UITypes, Vcl.Dialogs, inLibMensajesVcl,
  UniDataNumeracionDocumentos,
  inMtoGenSearch, inLibDocumentoFiscal, inLibFacturasValidacionCabecera,
  inLibMsgFacturas, inLibMsgVentas, inLibMsgOpcionesDocumento,
  inLibVentasPantallaIntf,
  UniDataVentasPantallaComposicion,
  inLibClientesAltaRapida, inMtoModalAltaRapidaCliente,
  UniDataClientesAltaRapida,
  inMtoModalOpcionesDocumento, UniDataOpcionesDocumentoRepositorio;

{$R *.dfm}

const
  CLAVE_CLIENTE = 'CLIENTE';

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
