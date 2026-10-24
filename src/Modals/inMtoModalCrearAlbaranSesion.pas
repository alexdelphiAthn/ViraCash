{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalCrearAlbaranSesion                                  }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       2.0.0                                                         }
{   Fecha:       28/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Ajustes finales antes de materializar una sesión de compra, con el        }
{    diálogo común de creación de documentos: tipo (albarán o pedido de        }
{    compra), almacén destino, serie del almacén para ese tipo, fecha y        }
{    forma de pago, más tarifa de venta, temporada, referencia del proveedor   }
{    y, en formato distribuido, «un documento por almacén». El número sale     }
{    del contador (puede haber varios documentos). El formulario no se         }
{    muestra: sólo aporta los servicios de TfrmBase.                           }
{******************************************************************************}
unit inMtoModalCrearAlbaranSesion;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms, Data.DB,
  inMtoFrmBase, inLibOpcionesDocumentoIntf, inLibComprasSesionesCreacion;

type
  TfrmModalCrearAlbaranSesion = class(TfrmBase)
  private
    class function Elementos(ADataSource: TDataSource;
      const ACampoCodigo, ACampoNombre: string):
      TElementosOpcionesDocumento; static;
    class function Configurar(
      ADsTarifas, ADsTemporadas: TDataSource;
      const AEstado: TEstadoSesionCreacion;
      const ADefectos: TDefectosDialogoCreacion):
      TConfiguracionOpcionesDocumento; static;
  public
    class function Solicitar(
      AOwner: TComponent;
      ADsAlmacenes, ADsTarifas, ADsTemporadas: TDataSource;
      const AEstado: TEstadoSesionCreacion;
      const ADefectos: TDefectosDialogoCreacion;
      out AAjustes: TAjustesCreacionElegidos): Boolean; static;
  end;

implementation

uses
  inLibMsgOpcionesDocumento,
  inMtoModalOpcionesDocumento, UniDataOpcionesDocumentoRepositorio;

{$R *.dfm}

const
  TIPO_ALBARAN = 'AB';
  TIPO_PEDIDO = 'PC';
  CLAVE_TARIFA = 'TARIFA';
  CLAVE_TEMPORADA = 'TEMPORADA';
  CLAVE_REFERENCIA = 'REFERENCIA';
  CLAVE_POR_ALMACEN = 'POR_ALMACEN';

function Campo(const AClave, AEtiqueta: string;
  AClase: TClaseCampoAdicional; const AValor: string):
  TCampoAdicionalOpcionesDocumento;
begin
  Result := Default(TCampoAdicionalOpcionesDocumento);
  Result.Clave := AClave;
  Result.Etiqueta := AEtiqueta;
  Result.Clase := AClase;
  Result.Valor := AValor;
  Result.ConVacio := True;
end;

class function TfrmModalCrearAlbaranSesion.Elementos(
  ADataSource: TDataSource; const ACampoCodigo, ACampoNombre: string):
  TElementosOpcionesDocumento;
var
  oDatos: TDataSet;
  oElemento: TElementoOpcionesDocumento;
begin
  Result := nil;
  oDatos := nil;
  if Assigned(ADataSource) then
    oDatos := ADataSource.DataSet;
  if Assigned(oDatos) and oDatos.Active then
  begin
    oDatos.DisableControls;
    try
      oDatos.First;
      while not oDatos.Eof do
      begin
        oElemento.Codigo := oDatos.FieldByName(ACampoCodigo).AsString;
        oElemento.Nombre := oDatos.FieldByName(ACampoNombre).AsString;
        Result := Result + [oElemento];
        oDatos.Next;
      end;
      oDatos.First;
    finally
      oDatos.EnableControls;
    end;
  end;
end;

class function TfrmModalCrearAlbaranSesion.Configurar(
  ADsTarifas, ADsTemporadas: TDataSource;
  const AEstado: TEstadoSesionCreacion;
  const ADefectos: TDefectosDialogoCreacion):
  TConfiguracionOpcionesDocumento;
var
  oAlbaran, oPedido: TTipoOpcionesDocumento;
  oTarifa, oTemporada: TCampoAdicionalOpcionesDocumento;
  sTemporada: string;
begin
  oAlbaran := Default(TTipoOpcionesDocumento);
  oAlbaran.Codigo := TIPO_ALBARAN;
  oAlbaran.Nombre := SNombreAlbaranCompraOpcionesDocumento;
  oAlbaran.AlmacenObligatorio := True;
  oPedido := oAlbaran;
  oPedido.Codigo := TIPO_PEDIDO;
  oPedido.Nombre := SNombrePedidoCompraOpcionesDocumento;
  Result := Default(TConfiguracionOpcionesDocumento);
  Result.Titulo := STituloSesionCompraOpcionesDocumento;
  Result.Tipos := [oAlbaran, oPedido];
  Result.Propuesta.Empresa := AEstado.Empresa;
  Result.Propuesta.Almacen := ADefectos.Almacen;
  Result.Propuesta.Tipo := TIPO_ALBARAN;
  if ADefectos.GeneraPedido and (not ADefectos.GeneraAlbaran) then
    Result.Propuesta.Tipo := TIPO_PEDIDO;
  Result.Propuesta.Fecha := FechaCreacionPropuesta(AEstado.FechaSesion, Date);
  Result.Propuesta.Hora := Time;
  Result.Propuesta.FormaPago := AEstado.FormaPago;
  oTarifa := Campo(CLAVE_TARIFA, SCaptionTarifaOpcionesDocumento,
    ccaLista, ADefectos.Tarifa);
  oTarifa.Elementos := Elementos(ADsTarifas, 'CODIGO_TAR_ARTTAR',
    'NOMBRE_TAR_TAR');
  sTemporada := '';
  if ADefectos.Temporada > 0 then
    sTemporada := IntToStr(ADefectos.Temporada);
  oTemporada := Campo(CLAVE_TEMPORADA, SCaptionTemporadaOpcionesDocumento,
    ccaLista, sTemporada);
  oTemporada.Elementos := Elementos(ADsTemporadas, 'ID_PV_ARTPROP', 'PV');
  Result.Propuesta.Adicionales := [oTarifa, oTemporada,
    Campo(CLAVE_REFERENCIA, SCaptionReferenciaProveedorOpcionesDocumento,
      ccaTexto, ADefectos.RefProveedor)];
  if ADefectos.MostrarOpcionAgrupacion then
    Result.Propuesta.Adicionales := Result.Propuesta.Adicionales +
      [Campo(CLAVE_POR_ALMACEN, SCaptionUnDocumentoPorAlmacenOpcionesDocumento,
        ccaCasilla, 'N')];
  Result.Propuesta.Adicionales[2].LongitudMaxima := 100;
  // La hora sólo se usa en los albaranes (movimientos de entrada).
  Result.Visibles := [codEmpresa, codAlmacen, codTipo, codSerie, codFecha,
    codHora, codFormaPago];
  Result.Fijos := [codEmpresa];
end;

class function TfrmModalCrearAlbaranSesion.Solicitar(
  AOwner: TComponent;
  ADsAlmacenes, ADsTarifas, ADsTemporadas: TDataSource;
  const AEstado: TEstadoSesionCreacion;
  const ADefectos: TDefectosDialogoCreacion;
  out AAjustes: TAjustesCreacionElegidos): Boolean;
var
  oFormulario: TfrmModalCrearAlbaranSesion;
  oOpciones: TOpcionesDocumento;
begin
  AAjustes := Default(TAjustesCreacionElegidos);
  oFormulario := TfrmModalCrearAlbaranSesion.Create(AOwner);
  try
    Result := TfrmModalOpcionesDocumento.Solicitar(AOwner,
      CrearLectorOpcionesDocumentoUniDAC(oFormulario.ConexionPrincipal),
      Configurar(ADsTarifas, ADsTemporadas, AEstado, ADefectos),
      oOpciones);
  finally
    FreeAndNil(oFormulario);
  end;
  if Result then
  begin
    AAjustes.GeneraAlbaran := oOpciones.Tipo = TIPO_ALBARAN;
    AAjustes.GeneraPedido := oOpciones.Tipo = TIPO_PEDIDO;
    AAjustes.SerieAlbaran := ADefectos.SerieAlbaran;
    AAjustes.SeriePedido := ADefectos.SeriePedido;
    if AAjustes.GeneraAlbaran then
      AAjustes.SerieAlbaran := oOpciones.Serie
    else
      AAjustes.SeriePedido := oOpciones.Serie;
    AAjustes.Almacen := oOpciones.Almacen;
    AAjustes.Tarifa := oOpciones.Adicional(CLAVE_TARIFA);
    AAjustes.Temporada := StrToIntDef(
      oOpciones.Adicional(CLAVE_TEMPORADA), 0);
    AAjustes.RefProveedor := oOpciones.Adicional(CLAVE_REFERENCIA);
    AAjustes.UnDocumentoPorAlmacen :=
      oOpciones.Adicional(CLAVE_POR_ALMACEN) = 'S';
    AAjustes.Fecha := oOpciones.Fecha;
    AAjustes.ConHora := oOpciones.ConHora;
    AAjustes.Hora := oOpciones.Hora;
    AAjustes.FormaPago := oOpciones.FormaPago;
  end;
end;

end.
