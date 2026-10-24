{******************************************************************************}
{                                                                              }
{  Módulo:       inLibTrazabilidadDocumento                                    }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Une la trazabilidad de un documento con líneas (F-LOTEC-013 y            }
{    siguientes): con lo que el formulario sabe (puertos, sufijo y tabla de    }
{    líneas, documento actual, lector) arma la configuración del módulo de     }
{    datos (TLotesLineasDocumento) y la del lector de código de barras         }
{    (TTrazabilidadLectorDocumento), para que cada pantalla no la repita.      }
{******************************************************************************}
unit inLibTrazabilidadDocumento;

interface

uses
  System.SysUtils, Data.DB, cxGridDBTableView, inLibTrazabilidad,
  inLibLotesPersistenciaIntf,
  inLibLotesVisualIntf, inLibAsignacionLoteLectura, inLibLotesLineaDocumento,
  inLibLectorDocumento;

type
  TDocumentoActualFunc = reference to function: TDocumentoLineaLote;
  TLineasDocumentoFunc = reference to function: TDataSet;
  TLectorDocumentoFunc = reference to function: TLectorDocumento;

  TDocumentoTrazabilidad = record
    Activacion: TActivacionTrazabilidad;
    Lectura: ILecturaTrazabilidadArticulo;
    Repositorio: IRepositorioLotes;
    Selector: ISelectorLotesVisual;
    Sentido: TSentidoLoteLectura;
    // Sufijo de las columnas de línea (ALBCLIN...) y clave de la tabla.
    Sufijo: string;
    // Campos de línea sin el patrón <campo>_<sufijo> (traspasos, en
    // memoria). Si Campos.Lote está vacío se usan los del sufijo.
    Campos: TCamposLoteLinea;
    Tabla: string;
    CampoSerie: string;
    CampoNumero: string;
    AsignarFefo: Boolean;
    ExigirSerieEnVenta: Boolean;
    DiasAvisoGeneral: Integer;
    Documento: TDocumentoActualFunc;
    Lineas: TLineasDocumentoFunc;
    Lector: TLectorDocumentoFunc;
    Avisar: TAvisoLineaLoteEvent;
    // FZ-ISSUE-327: opcional (ver TConfiguracionLotesLineas)
    ConfirmarMenosUnidades: TConfirmarLineaLoteEvent;
    procedure Validar;
  end;

function ConfiguracionLotesLineasDocumento(
  const ADocumento: TDocumentoTrazabilidad): TConfiguracionLotesLineas;
function TrazabilidadLectorDocumento(
  const ADocumento: TDocumentoTrazabilidad): TTrazabilidadLectorDocumento;
// Columnas Lote / F. caducidad de la rejilla de líneas (LOTE_<sufijo>,
// FECHA_CADUCIDAD_<sufijo>; sin sufijo, LOTE y FECHA_CADUCIDAD). Solo con
// algún modo activo; no las duplica si el modo de entrada se reconstruye
// (si ya existen, las muestra). Con AElegir, la columna Lote lleva un
// botón «…» que lo llama (tras cerrar el editor de la celda).
procedure CrearColumnasLoteDocumento(AVista: TcxGridDBTableView;
  const ASufijo: string; const AActivacion: TActivacionTrazabilidad;
  const AElegir: TProc = nil);

implementation

uses
  System.Classes, cxCalendar, cxEdit, cxButtonEdit,
  inLibArticulosValidadorIntf, inLibMsgTrazabilidad;

const
  // Medidas a 96 ppp.
  ANCHO_COLUMNA_LOTE = 110;
  ANCHO_COLUMNA_CADUCIDAD = 95;

type
  // Atiende el botón «…» de la columna Lote; la columna es su dueña.
  TBotonElegirLote = class(TComponent)
  private
    FVista: TcxGridDBTableView;
    FElegir: TProc;
    procedure Pulsado(Sender: TObject; AButtonIndex: Integer);
  end;

procedure TBotonElegirLote.Pulsado(Sender: TObject; AButtonIndex: Integer);
begin
  // Lo tecleado en la celda se descarta: el lote se vuelve a decidir.
  FVista.Controller.EditingController.HideEdit(False);
  FElegir();
end;

procedure PonerBotonElegir(AVista: TcxGridDBTableView;
  AColumna: TcxGridDBColumn; const AElegir: TProc);
var
  oBoton: TBotonElegirLote;
begin
  oBoton := TBotonElegirLote.Create(AColumna);
  oBoton.FVista := AVista;
  oBoton.FElegir := AElegir;
  AColumna.PropertiesClass := TcxButtonEditProperties;
  TcxButtonEditProperties(AColumna.Properties).OnButtonClick :=
    oBoton.Pulsado;
end;

function CampoConSufijo(const ACampo, ASufijo: string): string;
begin
  Result := ACampo;
  if ASufijo <> '' then
    Result := ACampo + '_' + ASufijo;
end;

procedure CrearColumnasLoteDocumento(AVista: TcxGridDBTableView;
  const ASufijo: string; const AActivacion: TActivacionTrazabilidad;
  const AElegir: TProc);
var
  oColumna: TcxGridDBColumn;
begin
  if AActivacion.AlgunModoActivo and Assigned(AVista) then
  begin
    oColumna := AVista.GetColumnByFieldName(CampoConSufijo('LOTE', ASufijo));
    if oColumna = nil then
    begin
      oColumna := AVista.CreateColumn;
      oColumna.DataBinding.FieldName := CampoConSufijo('LOTE', ASufijo);
      oColumna.Width := AVista.Control.ScaleValue(ANCHO_COLUMNA_LOTE);
    end;
    oColumna.Caption := SCaptionColumnaLoteSerie;
    oColumna.Visible := True;
    if Assigned(AElegir) then
      PonerBotonElegir(AVista, oColumna, AElegir);
    if AActivacion.Lotes then
    begin
      oColumna := AVista.GetColumnByFieldName(
        CampoConSufijo('FECHA_CADUCIDAD', ASufijo));
      if oColumna = nil then
      begin
        oColumna := AVista.CreateColumn;
        oColumna.DataBinding.FieldName :=
          CampoConSufijo('FECHA_CADUCIDAD', ASufijo);
        oColumna.PropertiesClass := TcxDateEditProperties;
        oColumna.Width :=
          AVista.Control.ScaleValue(ANCHO_COLUMNA_CADUCIDAD);
      end;
      oColumna.Caption := SCaptionColumnaCaducidad;
      oColumna.Visible := True;
    end;
  end;
end;

function CamposDocumento(
  const ADocumento: TDocumentoTrazabilidad): TCamposLoteLinea;
begin
  Result := ADocumento.Campos;
  if Result.Lote = '' then
    Result := CamposLoteLinea(ADocumento.Sufijo);
end;

procedure TDocumentoTrazabilidad.Validar;
begin
  if not Assigned(Lectura) then
    raise EArgumentNilException.Create('Lectura');
  if not Assigned(Repositorio) then
    raise EArgumentNilException.Create('Repositorio');
  if not Assigned(Selector) then
    raise EArgumentNilException.Create('Selector');
  if not Assigned(Documento) then
    raise EArgumentNilException.Create('Documento');
  if not Assigned(Lineas) then
    raise EArgumentNilException.Create('Lineas');
  if not Assigned(Avisar) then
    raise EArgumentNilException.Create('Avisar');
end;

function ConfiguracionLotesLineasDocumento(
  const ADocumento: TDocumentoTrazabilidad): TConfiguracionLotesLineas;
var
  oLector: TLectorDocumentoFunc;
begin
  ADocumento.Validar;
  Result := Default(TConfiguracionLotesLineas);
  Result.Activacion := ADocumento.Activacion;
  Result.Lectura := ADocumento.Lectura;
  Result.Repositorio := ADocumento.Repositorio;
  Result.Selector := ADocumento.Selector;
  Result.Sentido := ADocumento.Sentido;
  Result.Campos := CamposDocumento(ADocumento);
  Result.Tabla := ADocumento.Tabla;
  Result.CampoSerie := ADocumento.CampoSerie;
  Result.CampoNumero := ADocumento.CampoNumero;
  Result.AsignarFefo := ADocumento.AsignarFefo;
  Result.ExigirSerieEnVenta := ADocumento.ExigirSerieEnVenta;
  Result.DiasAvisoGeneral := ADocumento.DiasAvisoGeneral;
  Result.Avisar := ADocumento.Avisar;
  Result.ConfirmarMenosUnidades := ADocumento.ConfirmarMenosUnidades;
  oLector := ADocumento.Lector;
  // Las series o lotes de más entran como líneas nuevas por el lector,
  // que ya sabe resolver el artículo en el modo de entrada del grid.
  Result.AnadirLineas :=
    procedure(const ACodigo: string;
      const AAsignaciones: TArray<TAsignacionLote>)
    var
      oInstancia: TLectorDocumento;
    begin
      oInstancia := nil;
      if Assigned(oLector) then
        oInstancia := oLector();
      if Assigned(oInstancia) then
        oInstancia.DarDeAltaConAsignaciones(ACodigo, AAsignaciones);
    end;
end;

function TrazabilidadLectorDocumento(
  const ADocumento: TDocumentoTrazabilidad): TTrazabilidadLectorDocumento;
var
  rDocumento: TDocumentoTrazabilidad;
  rCampos: TCamposLoteLinea;
begin
  ADocumento.Validar;
  rDocumento := ADocumento;
  rCampos := CamposDocumento(ADocumento);
  Result.AsignarLote := CrearAsignarLoteLectura(rDocumento.Repositorio,
    rDocumento.Selector,
    function(const AResolucion: TArtResolucionEntrada): TContextoLoteLectura
    var
      rActual: TDocumentoLineaLote;
      rTrazabilidad: TTrazabilidadArticulo;
    begin
      rTrazabilidad := rDocumento.Lectura.Leer(AResolucion.CodigoArticulo);
      rActual := rDocumento.Documento();
      Result := Default(TContextoLoteLectura);
      Result.Activacion := rDocumento.Activacion;
      Result.Modo := rTrazabilidad.Modo;
      Result.EsCaducidadObligatoria := rTrazabilidad.EsCaducidadObligatoria;
      Result.Sentido := rDocumento.Sentido;
      Result.CodigoAlmacen := rActual.CodigoAlmacen;
      Result.DescripcionArticulo := AResolucion.DescripcionArticulo;
      Result.Cantidad := 1;
      Result.AsignarFefo := rDocumento.AsignarFefo;
      Result.ExigirSerieEnVenta := rDocumento.ExigirSerieEnVenta;
      Result.DiasAviso := DiasAvisoEfectivos(rTrazabilidad.DiasAviso,
                                             rDocumento.DiasAvisoGeneral);
      Result.Hoy := Date;
      Result.SeriesDocumento := rDocumento.Lectura.LotesOtrasLineas(
        rDocumento.Tabla, rDocumento.CampoSerie, rDocumento.CampoNumero,
        rCampos.Linea, rCampos.Lote, rActual.Serie, rActual.Numero, '');
    end,
    procedure(const AMensaje: string)
    begin
      rDocumento.Avisar(AMensaje);
    end);
  Result.EscribirLote :=
    procedure(const AAsignacion: TAsignacionLote)
    begin
      EscribirLoteEnLinea(rDocumento.Lineas(), rCampos.Lote,
        rCampos.Caducidad, rCampos.Cantidad, AAsignacion);
    end;
end;

end.
