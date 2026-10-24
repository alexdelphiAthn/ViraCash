{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalResolverIncidenciaVerifactu                         }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       2.0.0                                                         }
{   Fecha:       28/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Resuelve una incidencia aceptada con errores por subsanación o R4 con     }
{    el diálogo común de creación de documentos: casilla «emitir               }
{    rectificativa R4» (activa serie y fecha), motivo y destinatario           }
{    correcto. La resolución se ejecuta al aceptar; si falla, el diálogo       }
{    sigue abierto con el error. El formulario no se muestra.                  }
{******************************************************************************}
unit inMtoModalResolverIncidenciaVerifactu;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms,
  inMtoFrmBase, inLibOpcionesDocumentoIntf,
  inLibFacturasIncidenciaFiscalIntf;

type
  TfrmModalResolverIncidenciaVerifactu = class(TfrmBase)
  private
    FDatos: TDatosIncidenciaFiscal;
    FResultado: TResultadoResolucionIncidenciaFiscal;
    FServicio: IServicioIncidenciaFiscalFactura;
    function Configurar: TConfiguracionOpcionesDocumento;
    function ResolverCliente(const ACodigo: string;
      out ADescripcion: string): Boolean;
    function Resolver(const AOpciones: TOpcionesDocumento;
      out AMensaje: string): Boolean;
    function CrearSolicitud(const AOpciones: TOpcionesDocumento):
      TSolicitudResolucionIncidenciaFiscal;
  public
    class function Ejecutar(
      AOwner: TComponent;
      const AServicio: IServicioIncidenciaFiscalFactura;
      const ASerie, ANumero: string):
      TResultadoResolucionIncidenciaFiscal;
  end;

implementation

uses
  inLibFormatoDocumento, UniDataFormatoDocumentoRepositorio,
  System.SysUtils,
  inLibMsgVerifactu, inLibMsgOpcionesDocumento,
  inMtoModalOpcionesDocumento, UniDataOpcionesDocumentoRepositorio;

{$R *.dfm}

const
  CLAVE_RECTIFICAR = 'RECTIFICAR';
  CLAVE_MOTIVO = 'MOTIVO';
  CLAVE_CLIENTE = 'CLIENTE';

function DescribirCliente(const ACliente: TDatosClienteIncidenciaFiscal):
  string;
begin
  Result := ACliente.RazonSocial + ' (' + ACliente.Nif + ')';
end;

class function TfrmModalResolverIncidenciaVerifactu.Ejecutar(
  AOwner: TComponent;
  const AServicio: IServicioIncidenciaFiscalFactura;
  const ASerie, ANumero: string): TResultadoResolucionIncidenciaFiscal;
var
  oFormulario: TfrmModalResolverIncidenciaVerifactu;
  oOpciones: TOpcionesDocumento;
begin
  if not Assigned(AServicio) then
    raise EArgumentNilException.Create('AServicio');
  oFormulario := TfrmModalResolverIncidenciaVerifactu.Create(AOwner);
  try
    oFormulario.FServicio := AServicio;
    oFormulario.FResultado :=
      Default(TResultadoResolucionIncidenciaFiscal);
    oFormulario.FDatos := AServicio.CargarIncidencia(ASerie, ANumero);
    TfrmModalOpcionesDocumento.Solicitar(AOwner,
      CrearLectorOpcionesDocumentoUniDAC(oFormulario.ConexionPrincipal),
      oFormulario.Configurar, oOpciones);
    Result := oFormulario.FResultado;
  finally
    FreeAndNil(oFormulario);
  end;
end;

// Sin marcar la casilla se subsana el registro enviado: serie y fecha no
// se piden. Con ella se emite la R4 al destinatario correcto.
function TfrmModalResolverIncidenciaVerifactu.Configurar:
  TConfiguracionOpcionesDocumento;
var
  oTipo: TTipoOpcionesDocumento;
  oRectificar, oMotivo, oCliente: TCampoAdicionalOpcionesDocumento;
begin
  oTipo := Default(TTipoOpcionesDocumento);
  oTipo.Codigo := 'R4';
  oTipo.Contador := 'FC';
  oTipo.Subtipo := 'RECTIFICATIVA';
  oTipo.Nombre := SNombreRectificativaR4OpcionesDocumento;
  oRectificar := Default(TCampoAdicionalOpcionesDocumento);
  oRectificar.Clave := CLAVE_RECTIFICAR;
  oRectificar.Etiqueta := SCaptionEmitirR4OpcionesDocumento;
  oRectificar.Clase := ccaCasilla;
  oRectificar.Valor := 'N';
  oRectificar.AlPrincipio := True;
  oRectificar.DeshabilitaSinValor := [codSerie, codFecha];
  oMotivo := Default(TCampoAdicionalOpcionesDocumento);
  oMotivo.Clave := CLAVE_MOTIVO;
  oMotivo.Etiqueta := STextoIncidenciaMotivo;
  oMotivo.Clase := ccaTexto;
  oMotivo.Obligatorio := True;
  oMotivo.MensajeObligatorio := SErrorIncidenciaMotivoObligatorio;
  oMotivo.AlPrincipio := True;
  oCliente := Default(TCampoAdicionalOpcionesDocumento);
  oCliente.Clave := CLAVE_CLIENTE;
  oCliente.Etiqueta := STextoIncidenciaClienteCorrecto;
  oCliente.Clase := ccaBusqueda;
  oCliente.Valor := FDatos.Cliente.Codigo;
  oCliente.Descripcion := DescribirCliente(FDatos.Cliente);
  oCliente.LongitudMaxima := 20;
  oCliente.Resolver := ResolverCliente;
  Result := Default(TConfiguracionOpcionesDocumento);
  Result.Titulo := STituloResolverIncidenciaVerifactu;
  Result.Aviso := Format(SAvisoIncidenciaVerifactuOpcionesDocumento,
    [FormatearDocumento(
      CrearFormatoDocumentoLecturas(ConexionPrincipal).LeerFormatoEmpresa(
        FDatos.CodigoEmpresa), FDatos.Serie, FDatos.Numero),
     Trim(FDatos.CodigoError + ' ' + FDatos.DescripcionError),
     FDatos.Cliente.Codigo + ' - ' + DescribirCliente(FDatos.Cliente)]);
  Result.Tipos := [oTipo];
  Result.Propuesta.Empresa := FDatos.CodigoEmpresa;
  Result.Propuesta.Tipo := 'R4';
  Result.Propuesta.Fecha := Date;
  Result.Propuesta.Adicionales := [oRectificar, oMotivo, oCliente];
  Result.Visibles := [codEmpresa, codSerie, codFecha];
  Result.Fijos := [codEmpresa];
  Result.Validar := Resolver;
end;

// Un código inexistente o sin NIF no se acepta como destinatario: el
// nombre queda en blanco y el servicio dará el error al resolver.
function TfrmModalResolverIncidenciaVerifactu.ResolverCliente(
  const ACodigo: string; out ADescripcion: string): Boolean;
begin
  ADescripcion := '';
  try
    ADescripcion := DescribirCliente(FServicio.CargarCliente(ACodigo));
    Result := True;
  except
    on E: Exception do
    begin
      if Assigned(RegistroLog) then
        RegistroLog.RegistrarError(
          'Destinatario de la incidencia VERI*FACTU: ' + E.Message);
      Result := False;
    end;
  end;
end;

function TfrmModalResolverIncidenciaVerifactu.CrearSolicitud(
  const AOpciones: TOpcionesDocumento): TSolicitudResolucionIncidenciaFiscal;
begin
  Result := Default(TSolicitudResolucionIncidenciaFiscal);
  Result.Serie := FDatos.Serie;
  Result.Numero := FDatos.Numero;
  if AOpciones.Adicional(CLAVE_RECTIFICAR) = 'S' then
    Result.TipoResolucion := trifRectificarFactura
  else
    Result.TipoResolucion := trifSubsanarRegistro;
  Result.Motivo := AOpciones.Adicional(CLAVE_MOTIVO);
  Result.CodigoClienteCorrecto := AOpciones.Adicional(CLAVE_CLIENTE);
  Result.SerieRectificativa := AOpciones.Serie;
  Result.FechaRectificativa := AOpciones.Fecha;
end;

// Se resuelve al aceptar: si el servicio rechaza la resolución el diálogo
// sigue abierto con su mensaje.
function TfrmModalResolverIncidenciaVerifactu.Resolver(
  const AOpciones: TOpcionesDocumento; out AMensaje: string): Boolean;
begin
  AMensaje := '';
  try
    FResultado := FServicio.Resolver(CrearSolicitud(AOpciones));
    Result := FResultado.EsCorrecto;
    if not Result then
      AMensaje := FResultado.Mensaje;
  except
    on E: Exception do
    begin
      if Assigned(RegistroLog) then
        RegistroLog.RegistrarError(
          'Resolver incidencia VERI*FACTU: ' + E.Message);
      AMensaje := E.Message;
      Result := False;
    end;
  end;
end;

end.
