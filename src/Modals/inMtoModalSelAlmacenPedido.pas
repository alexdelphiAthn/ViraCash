{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalSelAlmacenPedido                                    }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       2.0.0                                                         }
{   Fecha:       28/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    «Crear albarán desde pedido de compra» con el diálogo común de creación  }
{    de documentos: almacén destino (el albarán y los movimientos van contra   }
{    él), serie AB del almacén, número, fecha de recepción y forma de pago,    }
{    más referencia del proveedor, temporada y «Añadir a» un albarán abierto   }
{    del pedido (deja sin uso serie, número, fecha y forma de pago). El        }
{    formulario no se muestra: sólo aporta los servicios de TfrmBase.          }
{******************************************************************************}
unit inMtoModalSelAlmacenPedido;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms,
  inMtoFrmBase, inLibOpcionesDocumentoIntf,
  inLibPedidosCompraPresentacionRecepcion;

type
  TfrmModalSelAlmacenPedido = class(TfrmBase)
  private
    FEntrada: TEntradaPresentacionRecepcionPedidoCompra;
    FFormaPago: string;
    function Configurar: TConfiguracionOpcionesDocumento;
    function Temporadas: TElementosOpcionesDocumento;
    function AlbaranesAbiertos: TElementosOpcionesDocumento;
    function CampoTexto(const AClave, AEtiqueta, AValor: string;
      ALongitud: Integer): TCampoAdicionalOpcionesDocumento;
    function CampoLista(const AClave, AEtiqueta, AValor: string;
      const AElementos: TElementosOpcionesDocumento):
      TCampoAdicionalOpcionesDocumento;
  public
    // AFormaPago: la del pedido, que se propone.
    class function Solicitar(AOwner: TComponent;
      const AEntrada: TEntradaPresentacionRecepcionPedidoCompra;
      const AFormaPago: string;
      out ASolicitud: TSolicitudPresentacionRecepcionPedidoCompra):
      Boolean; static;
  end;

implementation

uses
  Data.DB,
  inLibMsgVentas, inLibMsgOpcionesDocumento,
  inLibVentasPantallaIntf, inLibSeleccionAlmacenPersistenciaIntf,
  UniDataVentasPantallaComposicion,
  inMtoModalOpcionesDocumento, UniDataOpcionesDocumentoRepositorio;

{$R *.dfm}

const
  CLAVE_EXISTENTE = 'EXISTENTE';
  CLAVE_REFERENCIA = 'REFERENCIA';
  CLAVE_TEMPORADA = 'TEMPORADA';

class function TfrmModalSelAlmacenPedido.Solicitar(AOwner: TComponent;
  const AEntrada: TEntradaPresentacionRecepcionPedidoCompra;
  const AFormaPago: string;
  out ASolicitud: TSolicitudPresentacionRecepcionPedidoCompra): Boolean;
var
  oFormulario: TfrmModalSelAlmacenPedido;
  oOpciones: TOpcionesDocumento;
  sExistente: string;
begin
  ASolicitud := Default(TSolicitudPresentacionRecepcionPedidoCompra);
  oFormulario := TfrmModalSelAlmacenPedido.Create(AOwner);
  try
    oFormulario.FEntrada := AEntrada;
    oFormulario.FFormaPago := AFormaPago;
    Result := TfrmModalOpcionesDocumento.Solicitar(AOwner,
      CrearLectorOpcionesDocumentoUniDAC(oFormulario.ConexionPrincipal),
      oFormulario.Configurar, oOpciones);
  finally
    FreeAndNil(oFormulario);
  end;
  if Result then
  begin
    ASolicitud.CodigoAlmacen := oOpciones.Almacen;
    ASolicitud.SerieAlbaran := oOpciones.Serie;
    ASolicitud.ReferenciaProveedor := oOpciones.Adicional(CLAVE_REFERENCIA);
    ASolicitud.IdPvTemporada := StrToIntDef(
      oOpciones.Adicional(CLAVE_TEMPORADA), 0);
    ASolicitud.FechaRecepcion := oOpciones.Instante;
    sExistente := oOpciones.Adicional(CLAVE_EXISTENTE);
    ASolicitud.Incorporar := sExistente <> '';
    if ASolicitud.Incorporar then
    begin
      ASolicitud.SerieAlbaranDestino := Copy(sExistente, 1,
        Pos('|', sExistente) - 1);
      ASolicitud.NumeroAlbaranDestino := Copy(sExistente,
        Pos('|', sExistente) + 1, MaxInt);
    end;
    ASolicitud.AlbaranNuevo.NumeroManual := oOpciones.Numero;
    ASolicitud.AlbaranNuevo.FormaPago := oOpciones.FormaPago;
  end;
end;

function TfrmModalSelAlmacenPedido.CampoTexto(const AClave, AEtiqueta,
  AValor: string; ALongitud: Integer): TCampoAdicionalOpcionesDocumento;
begin
  Result := Default(TCampoAdicionalOpcionesDocumento);
  Result.Clave := AClave;
  Result.Etiqueta := AEtiqueta;
  Result.Clase := ccaTexto;
  Result.Valor := AValor;
  Result.LongitudMaxima := ALongitud;
end;

function TfrmModalSelAlmacenPedido.CampoLista(const AClave, AEtiqueta,
  AValor: string; const AElementos: TElementosOpcionesDocumento):
  TCampoAdicionalOpcionesDocumento;
begin
  Result := Default(TCampoAdicionalOpcionesDocumento);
  Result.Clave := AClave;
  Result.Etiqueta := AEtiqueta;
  Result.Clase := ccaLista;
  Result.Valor := AValor;
  Result.ConVacio := True;
  Result.Elementos := AElementos;
end;

function TfrmModalSelAlmacenPedido.Configurar:
  TConfiguracionOpcionesDocumento;
var
  oTipo: TTipoOpcionesDocumento;
  oExistente: TCampoAdicionalOpcionesDocumento;
  sTemporada: string;
begin
  oTipo := Default(TTipoOpcionesDocumento);
  oTipo.Codigo := 'AB';
  oTipo.Nombre := SNombreAlbaranCompraOpcionesDocumento;
  oTipo.AlmacenObligatorio := True;
  Result := Default(TConfiguracionOpcionesDocumento);
  Result.Titulo := STituloAlbaranPedidoCompraOpcionesDocumento;
  Result.Aviso := Format(SAvisoDocumentoOrigenOpcionesDocumento,
    [FEntrada.SeriePedido, FEntrada.NumeroPedido]);
  Result.Tipos := [oTipo];
  Result.Propuesta.Empresa := FEntrada.CodigoEmpresa;
  Result.Propuesta.Almacen := FEntrada.AlmacenSugerido;
  if Result.Propuesta.Almacen = '' then
    Result.Propuesta.Almacen := FEntrada.AlmacenAlternativo;
  Result.Propuesta.Tipo := 'AB';
  Result.Propuesta.Fecha := Date;
  Result.Propuesta.Hora := Time;
  Result.Propuesta.FormaPago := FFormaPago;
  sTemporada := '';
  if FEntrada.IdPvTemporada > 0 then
    sTemporada := IntToStr(FEntrada.IdPvTemporada);
  Result.Propuesta.Adicionales := [
    CampoTexto(CLAVE_REFERENCIA, SCaptionReferenciaProveedorOpcionesDocumento,
      FEntrada.ReferenciaProveedor, 100),
    CampoLista(CLAVE_TEMPORADA, SCaptionTemporadaOpcionesDocumento,
      sTemporada, Temporadas)];
  oExistente := CampoLista(CLAVE_EXISTENTE,
    SCaptionAnadirADocumentoOpcionesDocumento, '', AlbaranesAbiertos);
  oExistente.DeshabilitaConValor := [codSerie, codNumero, codFecha,
    codFormaPago];
  if Length(oExistente.Elementos) > 0 then
    Result.Propuesta.Adicionales := Result.Propuesta.Adicionales +
      [oExistente];
  Result.Visibles := [codEmpresa, codAlmacen, codSerie, codNumero,
    codFecha, codHora, codFormaPago];
  Result.Fijos := [codEmpresa];
  Result.PermiteNumeroManual := True;
end;

function TfrmModalSelAlmacenPedido.Temporadas: TElementosOpcionesDocumento;
var
  oContexto: TContextoSeleccionAlmacenVentasPantalla;
  oConsulta: IConsultaSeleccionAlmacen;
  oDatos: TDataSet;
  oElemento: TElementoOpcionesDocumento;
begin
  Result := nil;
  CrearContextoVentasPantalla(ConexionPrincipal, oContexto);
  oConsulta := oContexto.Repositorio.ConsultarTemporadas;
  oDatos := oConsulta.DataSet;
  while not oDatos.Eof do
  begin
    oElemento.Codigo := oDatos.FieldByName('ID_PV_ARTPROP').AsString;
    oElemento.Nombre := oDatos.FieldByName('PV').AsString;
    Result := Result + [oElemento];
    oDatos.Next;
  end;
end;

// Albaranes del pedido sin facturar ni cancelar. Código = 'SERIE|NUMERO'.
function TfrmModalSelAlmacenPedido.AlbaranesAbiertos:
  TElementosOpcionesDocumento;
var
  oContexto: TContextoSeleccionAlmacenVentasPantalla;
  oConsulta: IConsultaSeleccionAlmacen;
  oDatos: TDataSet;
  oElemento: TElementoOpcionesDocumento;
begin
  Result := nil;
  CrearContextoVentasPantalla(ConexionPrincipal, oContexto);
  oConsulta := oContexto.Repositorio.ConsultarAlbaranesCompra(
    FEntrada.NumeroPedido, FEntrada.SeriePedido);
  oDatos := oConsulta.DataSet;
  while not oDatos.Eof do
  begin
    oElemento.Codigo := oDatos.FieldByName('SERIE_ALBC').AsString + '|' +
      oDatos.FieldByName('NUMERO_ALBC').AsString;
    oElemento.Nombre := Format(SElementoDocumentoExistenteOpcionesDocumento,
      [oDatos.FieldByName('SERIE_ALBC').AsString,
       oDatos.FieldByName('NUMERO_ALBC').AsString,
       FormatDateTime('dd/mm/yyyy',
         oDatos.FieldByName('FECHA_ALBC').AsDateTime),
       oDatos.FieldByName('ESTADO_ALBC').AsString]);
    Result := Result + [oElemento];
    oDatos.Next;
  end;
end;

end.
