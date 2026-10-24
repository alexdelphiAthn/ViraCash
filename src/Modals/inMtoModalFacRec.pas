{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalFacRec                                              }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       3.0.0                                                         }
{   Fecha:       02/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Rectificativa (por diferencias o por sustitución) o duplicado de la       }
{    factura actual con el diálogo común de creación de documentos: tipo,      }
{    serie, fecha, forma de pago, tipo VERI*FACTU (R1..R5), motivo,            }
{    tratamiento de movimientos y «emitir al crear». La creación se ejecuta    }
{    al aceptar; si falla, el diálogo sigue abierto con el error. El           }
{    formulario no se muestra: sólo aporta los servicios de TfrmBase.          }
{******************************************************************************}
unit inMtoModalFacRec;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms,
  inMtoFrmBase, inLibOpcionesDocumentoIntf,
  inLibFacturasRectificativaIntf, UniDataFacturas;

type
  TfrmGenFacRec = class(TfrmBase)
  private
    FFacturas: TdmFacturas;
    FServicio: IServicioRectificativaFactura;
    FOrigen: TDatosOrigenRectificativa;
    FResultado: TResultadoRectificativaFactura;
    FCreada: Boolean;
    function Configurar: TConfiguracionOpcionesDocumento;
    function CrearSolicitud(
      const AOpciones: TOpcionesDocumento): TSolicitudRectificativaFactura;
    function Crear(const AOpciones: TOpcionesDocumento;
      out AMensaje: string): Boolean;
  public
    class procedure Ejecutar(AOwner: TComponent;
      AFacturas: TdmFacturas;
      const AServicio: IServicioRectificativaFactura); static;
  end;

implementation

uses
  inLibMensajesVcl, inLibMsgFacturas, inLibMsgOpcionesDocumento,
  inLibFacturasRectificativa, inLibFacturasServiciosIntf,
  inMtoModalOpcionesDocumento, UniDataOpcionesDocumentoRepositorio;

{$R *.dfm}

const
  TIPO_DIFERENCIAS = 'RECT_DIFERENCIAS';
  TIPO_SUSTITUCION = 'RECT_SUSTITUCION';
  TIPO_DUPLICADO = 'DUPLICADO';
  CLAVE_TIPO_VERIFACTU = 'TIPO_VERIFACTU';
  CLAVE_MOTIVO = 'MOTIVO';
  CLAVE_MOVIMIENTOS = 'MOVIMIENTOS';
  MOVIMIENTOS_MANTENER = 'M';
  MOVIMIENTOS_REEMPLAZAR = 'R';
  LONGITUD_MOTIVO = 500;

resourcestring
  SErrorModuloFacturasNoAsignado =
    'Data module de facturas no asignado.';
  SErrorServicioRectificativaNoAsignado =
    'Servicio de rectificativas no asignado.';

function NuevoElemento(
  const ACodigo, ANombre: string): TElementoOpcionesDocumento;
begin
  Result.Codigo := ACodigo;
  Result.Nombre := ANombre;
end;

class procedure TfrmGenFacRec.Ejecutar(AOwner: TComponent;
  AFacturas: TdmFacturas;
  const AServicio: IServicioRectificativaFactura);
var
  oFormulario: TfrmGenFacRec;
  oOpciones: TOpcionesDocumento;
begin
  if not Assigned(AFacturas) then
    raise EArgumentNilException.Create(SErrorModuloFacturasNoAsignado);
  if not Assigned(AServicio) then
    raise EArgumentNilException.Create(
      SErrorServicioRectificativaNoAsignado);
  oFormulario := TfrmGenFacRec.Create(AOwner);
  try
    oFormulario.FFacturas := AFacturas;
    oFormulario.FServicio := AServicio;
    oFormulario.FOrigen := AServicio.CargarOrigen(
      AFacturas.unqryTablaG.FieldByName('SERIE_FAC').AsString,
      AFacturas.unqryTablaG.FieldByName('NUMERO_FAC').AsString);
    if not oFormulario.FOrigen.Encontrada then
      ShowMessage_fza(SErrorBorradorListaNoSeleccionado)
    else
    begin
      // Se crea al aceptar: si el servicio rechaza la solicitud el
      // diálogo sigue abierto con su mensaje.
      TfrmModalOpcionesDocumento.Solicitar(AOwner,
        CrearLectorOpcionesDocumentoUniDAC(oFormulario.ConexionPrincipal),
        oFormulario.Configurar, oOpciones);
      if oFormulario.FCreada then
      begin
        AFacturas.unqryTablaG.Refresh;
        ShowMessage_fza(oFormulario.FResultado.Mensaje);
      end;
    end;
  finally
    FreeAndNil(oFormulario);
  end;
end;

// Tipo VERI*FACTU de la rectificativa: R1..R4, o sólo R5 cuando la
// original es simplificada. No se pide en el duplicado.
function CampoTipoVerifactuFacRec(
  ASimplificada: Boolean): TCampoAdicionalOpcionesDocumento;
var
  oTipo: TTipoFacturaVerifactuRectificativa;
begin
  Result := Default(TCampoAdicionalOpcionesDocumento);
  Result.Clave := CLAVE_TIPO_VERIFACTU;
  Result.Etiqueta := SCaptionTipoVerifactuRectificativaOpcionesDocumento;
  Result.Clase := ccaLista;
  for oTipo in TiposFacturaVerifactuRectificativa(ASimplificada) do
    Result.Elementos := Result.Elementos +
      [NuevoElemento(oTipo.Codigo, oTipo.Nombre)];
  Result.Valor := TipoFacturaVerifactuRectificativaDefecto(ASimplificada);
  Result.SoloTipos := [TIPO_DIFERENCIAS, TIPO_SUSTITUCION];
end;

function CampoMotivoFacRec: TCampoAdicionalOpcionesDocumento;
begin
  Result := Default(TCampoAdicionalOpcionesDocumento);
  Result.Clave := CLAVE_MOTIVO;
  Result.Etiqueta := SCaptionMotivoRectificativaOpcionesDocumento;
  Result.Clase := ccaTexto;
  Result.LongitudMaxima := LONGITUD_MOTIVO;
  Result.SoloTipos := [TIPO_DIFERENCIAS, TIPO_SUSTITUCION];
end;

// Qué hacer con los movimientos de la original: solo en la sustitución.
function CampoMovimientosFacRec: TCampoAdicionalOpcionesDocumento;
begin
  Result := Default(TCampoAdicionalOpcionesDocumento);
  Result.Clave := CLAVE_MOVIMIENTOS;
  Result.Etiqueta := SCaptionMovimientosRectificativaOpcionesDocumento;
  Result.Clase := ccaLista;
  Result.Elementos := [
    NuevoElemento(MOVIMIENTOS_MANTENER,
      SElementoMovimientosMantenerOpcionesDocumento),
    NuevoElemento(MOVIMIENTOS_REEMPLAZAR,
      SElementoMovimientosReemplazarOpcionesDocumento)];
  Result.Valor := MOVIMIENTOS_MANTENER;
  Result.SoloTipos := [TIPO_SUSTITUCION];
end;

// Rectificativas en las series rectificativas de la empresa de la
// factura; el duplicado en las de su clase (FZ-ISSUE-299: el de una
// simplificada sigue siendo simplificada). Forma de pago propuesta: la de
// la original.
function TfrmGenFacRec.Configurar: TConfiguracionOpcionesDocumento;
var
  oDiferencias, oSustitucion, oDuplicado: TTipoOpcionesDocumento;
  bSimplificada: Boolean;
begin
  bSimplificada := OrigenRectificativaEsSimplificado(FOrigen.TipoFactura);
  oDiferencias := Default(TTipoOpcionesDocumento);
  oDiferencias.Codigo := TIPO_DIFERENCIAS;
  oDiferencias.Contador := 'FC';
  oDiferencias.Subtipo := 'RECTIFICATIVA';
  oDiferencias.Nombre := SNombreRectificativaDiferenciasOpcionesDocumento;
  oSustitucion := Default(TTipoOpcionesDocumento);
  oSustitucion.Codigo := TIPO_SUSTITUCION;
  oSustitucion.Contador := 'FC';
  oSustitucion.Subtipo := 'RECTIFICATIVA';
  oSustitucion.Nombre := SNombreRectificativaSustitucionOpcionesDocumento;
  oDuplicado := Default(TTipoOpcionesDocumento);
  oDuplicado.Codigo := TIPO_DUPLICADO;
  oDuplicado.Contador := 'FC';
  if bSimplificada then
    oDuplicado.Subtipo := 'SIMPLIFICADA';
  oDuplicado.Nombre := SNombreDuplicadoOpcionesDocumento;
  Result := Default(TConfiguracionOpcionesDocumento);
  Result.Titulo := STituloRectificarDuplicarOpcionesDocumento;
  Result.Aviso := Format(SAvisoFacturaOrigenOpcionesDocumento,
    [FOrigen.Serie, FOrigen.Numero]);
  Result.TextoConsolidar := SCaptionEmitirAlCrearOpcionesDocumento;
  Result.Tipos := [oDiferencias, oSustitucion, oDuplicado];
  Result.Propuesta.Empresa := FOrigen.CodigoEmpresa;
  Result.Propuesta.Almacen := FOrigen.CodigoAlmacen;
  Result.Propuesta.Tipo := TIPO_DIFERENCIAS;
  Result.Propuesta.Fecha := Date;
  Result.Propuesta.FormaPago := FOrigen.FormaPago;
  Result.Propuesta.Adicionales := [CampoTipoVerifactuFacRec(bSimplificada),
    CampoMotivoFacRec, CampoMovimientosFacRec];
  Result.Visibles := [codEmpresa, codTipo, codSerie, codNumero, codFecha,
    codFormaPago, codConsolidar];
  Result.Fijos := [codEmpresa];
  Result.Validar := Crear;
end;

function TfrmGenFacRec.CrearSolicitud(
  const AOpciones: TOpcionesDocumento): TSolicitudRectificativaFactura;
begin
  Result := Default(TSolicitudRectificativaFactura);
  Result.SerieOriginal := FOrigen.Serie;
  Result.NumeroOriginal := FOrigen.Numero;
  if SameText(AOpciones.Tipo, TIPO_SUSTITUCION) then
    Result.Operacion := orfSustitucion
  else if SameText(AOpciones.Tipo, TIPO_DUPLICADO) then
    Result.Operacion := orfDuplicado
  else
    Result.Operacion := orfDiferencias;
  Result.TipoFacturaVerifactu :=
    Trim(AOpciones.Adicional(CLAVE_TIPO_VERIFACTU));
  Result.Serie := AOpciones.Serie;
  Result.Fecha := AOpciones.Fecha;
  Result.FormaPago := AOpciones.FormaPago;
  Result.Motivo := Trim(AOpciones.Adicional(CLAVE_MOTIVO));
  if SameText(AOpciones.Adicional(CLAVE_MOVIMIENTOS),
       MOVIMIENTOS_REEMPLAZAR) then
    Result.Movimientos := mrfReemplazarOriginales
  else
    Result.Movimientos := mrfMantenerOriginales;
  Result.EmitirAlCrear := AOpciones.ConsolidarAlCrear;
end;

// Validación y creación al aceptar: con False el diálogo muestra el
// mensaje y sigue abierto.
function TfrmGenFacRec.Crear(const AOpciones: TOpcionesDocumento;
  out AMensaje: string): Boolean;
var
  oSolicitud: TSolicitudRectificativaFactura;
  oValidacion: TResultadoOperacionFactura;
begin
  AMensaje := '';
  Result := False;
  oSolicitud := CrearSolicitud(AOpciones);
  try
    oValidacion := FServicio.Validar(oSolicitud);
    if not oValidacion.Exito then
      AMensaje := oValidacion.Mensaje
    else
    begin
      Screen.Cursor := crHourGlass;
      try
        FResultado := FServicio.Crear(oSolicitud);
      finally
        Screen.Cursor := crDefault;
      end;
      FCreada := True;
      Result := True;
    end;
  except
    on E: Exception do
    begin
      if Assigned(RegistroLog) then
        RegistroLog.RegistrarError(
          'Rectificar o duplicar factura: ' + E.Message);
      AMensaje := E.Message;
      Result := False;
    end;
  end;
end;

end.
