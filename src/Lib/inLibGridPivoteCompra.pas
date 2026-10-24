{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGridPivoteCompra                                         }
{    Tipo:       Librería                                                      }
{ Versión:       2.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Fachada coordinadora del pivote de tallas de documentos de compra.       }
{    Delega correspondencia, validación, presentación y edición.              }
{******************************************************************************}
unit inLibGridPivoteCompra;

interface

uses
  System.Variants,
  Vcl.Graphics,
  cxGraphics, cxEdit, cxGridCustomTableView, cxGridTableView,
  inLibGridPivoteCompraTipos,
  inLibGridPivoteCompraPersistenciaIntf,
  inLibPivoteCompraCorrespondencia,
  inLibPivoteCompraEstadoEdicion,
  inLibPivoteCompraValidacion,
  inLibGridPivoteCompraPresentacion,
  inLibGridPivoteCompraEdicion;

type
  TGridPivoteCompraConfig =
    inLibGridPivoteCompraTipos.TGridPivoteCompraConfig;
  TCeldaARecibir = inLibGridPivoteCompraTipos.TCeldaARecibir;
  TEstadoFilaRecibida =
    inLibGridPivoteCompraTipos.TEstadoFilaRecibida;

const
  efrIndefinido = inLibGridPivoteCompraTipos.efrIndefinido;
  efrNada = inLibGridPivoteCompraTipos.efrNada;
  efrParcial = inLibGridPivoteCompraTipos.efrParcial;
  efrTotal = inLibGridPivoteCompraTipos.efrTotal;
  ID_AV_SIN_TALLA = inLibGridPivoteCompraTipos.ID_AV_SIN_TALLA;
  COL_REC_NADA: TColor = $0099FFFF;
  COL_REC_PARCIAL: TColor = $0099FF99;
  COL_REC_TOTAL: TColor = $00FFCC99;
  ALTURA_FILA_EXPANDIDA =
    inLibGridPivoteCompraTipos.ALTURA_FILA_EXPANDIDA;

type
  TGridPivoteCompra = class
  private
    FCorrespondencia: TCorrespondenciaPivoteCompra;
    FEstadoEdicion  : TEstadoEdicionPivoteCompra;
    FValidador      : TValidadorPivoteCompra;
    FPresentacion   : TPresentacionPivoteCompra;
    FEdicion        : TEdicionPivoteCompra;
    function GetActivo: Boolean;
    function GetExpandido: Boolean;
  public
    constructor Create(const ACfg: TGridPivoteCompraConfig;
      const ARepositorio: TRepositoriosGridPivoteCompra);
    destructor Destroy; override;
    function ValidarPivotePosible(var AMensaje: string): Boolean;
    procedure Activar;
    procedure Desactivar;
    procedure RecargarYRepublicar;
    function PuedeExpandir: Boolean;
    procedure Expandir;
    procedure Contraer;
    function IterarARecibirPorAlmacen(const ACodigoAlm: string)
      : TArray<TCeldaARecibir>;
    procedure LimpiarARecibirParaAlmacen(const ACodigoAlm: string);
    procedure CustomDrawCellTalla(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
    procedure EditingCeldaTalla(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; var AAllow: Boolean);
    procedure CustomDrawColorCell(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
    function ProcesarTeclaCeldaTalla(AKey: Word): Boolean;
    function GetInfoCeldaTallaActiva(out ATallaCaption: string;
      out APedido, ARecibida: Double): Boolean;
    function RecibirFilaEntera: Integer;
    function RecibirTodo: Integer;
    procedure CapturarARecibirEditValueChanged(ASender: TObject);
    procedure CapturarCantidadEditValueChanged(ASender: TObject);
    // AValorEditado vuelve con la cantidad anterior si el total de la
    // línea no se confirma (FZ-ISSUE-255).
    procedure PersistirCantidadEditValueChanged(ASender: TObject;
      var AValorEditado: Variant);
    function PersistirCantidadesPendientes: Integer;
    function ColorCodigoLineaActiva: string;
    function CambiarColorLineaActiva(const ACodigoAtbColor: string;
      out AMensaje: string): Boolean;
    function PrimerAlmacenARecibir: string;
    function TotalARecibir: Double;
    procedure InitEditCeldaTalla(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit);
    property Activo: Boolean read GetActivo;
    property Expandido: Boolean read GetExpandido;
  end;

implementation

uses
  System.SysUtils;

constructor TGridPivoteCompra.Create(
  const ACfg: TGridPivoteCompraConfig;
  const ARepositorio: TRepositoriosGridPivoteCompra);
begin
  inherited Create;
  ARepositorio.Configuracion.Configurar(
    ACfg.TablaLineas,
    ACfg.FieldSerieLin,
    ACfg.FieldNumeroLin,
    ACfg.FieldLinea,
    ACfg.FieldArt,
    ACfg.FieldSku,
    ACfg.FieldCantidad,
    ACfg.FieldCantidadRecibida,
    ACfg.FieldIdAcPivot,
    ACfg.FieldAlmacen,
    ACfg.FieldColorTexto,
    ACfg.MaxColumnasTallas);
  FCorrespondencia := TCorrespondenciaPivoteCompra.Create(
    ACfg, ARepositorio);
  FEstadoEdicion := TEstadoEdicionPivoteCompra.Create;
  FValidador := TValidadorPivoteCompra.Create(
    ACfg, ARepositorio, FCorrespondencia);
  FPresentacion := TPresentacionPivoteCompra.Create(
    ACfg, FCorrespondencia, FEstadoEdicion);
  FEdicion := TEdicionPivoteCompra.Create(
    ACfg, ARepositorio, FCorrespondencia, FEstadoEdicion,
    FValidador, FPresentacion);
end;

destructor TGridPivoteCompra.Destroy;
begin
  FreeAndNil(FEdicion);
  FreeAndNil(FPresentacion);
  FreeAndNil(FValidador);
  FreeAndNil(FEstadoEdicion);
  FreeAndNil(FCorrespondencia);
  inherited;
end;

function TGridPivoteCompra.GetActivo: Boolean;
begin
  Result := FPresentacion.Activo;
end;

function TGridPivoteCompra.GetExpandido: Boolean;
begin
  Result := FPresentacion.Expandido;
end;

function TGridPivoteCompra.ValidarPivotePosible(
  var AMensaje: string): Boolean;
begin
  Result := FValidador.Validar(AMensaje);
end;

procedure TGridPivoteCompra.Activar;
begin
  FCorrespondencia.Cargar;
  FPresentacion.Activar;
end;

procedure TGridPivoteCompra.Desactivar;
begin
  FPresentacion.Desactivar;
  FEdicion.Limpiar;
  FCorrespondencia.Limpiar;
end;

procedure TGridPivoteCompra.RecargarYRepublicar;
var
  sSerie  : string;
  sNumero : string;
  sMensaje: string;
begin
  if FPresentacion.Activo then
  begin
    if not FValidador.Validar(sMensaje) then
      Desactivar
    else if FCorrespondencia.ObtenerSerieNumero(sSerie, sNumero) then
      FPresentacion.Recargar;
  end;
end;

function TGridPivoteCompra.PuedeExpandir: Boolean;
begin
  Result := FPresentacion.PuedeExpandir;
end;

procedure TGridPivoteCompra.Expandir;
begin
  FPresentacion.Expandir;
end;

procedure TGridPivoteCompra.Contraer;
begin
  FPresentacion.Contraer;
end;

function TGridPivoteCompra.IterarARecibirPorAlmacen(
  const ACodigoAlm: string): TArray<TCeldaARecibir>;
begin
  Result := FEdicion.IterarARecibirPorAlmacen(ACodigoAlm);
end;

procedure TGridPivoteCompra.LimpiarARecibirParaAlmacen(
  const ACodigoAlm: string);
begin
  FEdicion.LimpiarARecibirParaAlmacen(ACodigoAlm);
end;

procedure TGridPivoteCompra.CustomDrawCellTalla(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
begin
  FPresentacion.CustomDrawCellTalla(Sender, ACanvas, AViewInfo, ADone);
end;

procedure TGridPivoteCompra.EditingCeldaTalla(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  var AAllow: Boolean);
begin
  FPresentacion.EditingCeldaTalla(Sender, AItem, AAllow);
end;

procedure TGridPivoteCompra.CustomDrawColorCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
begin
  FPresentacion.CustomDrawColorCell(Sender, ACanvas, AViewInfo, ADone);
end;

function TGridPivoteCompra.ProcesarTeclaCeldaTalla(
  AKey: Word): Boolean;
begin
  Result := FEdicion.ProcesarTeclaCeldaTalla(AKey);
end;

function TGridPivoteCompra.GetInfoCeldaTallaActiva(
  out ATallaCaption: string; out APedido, ARecibida: Double): Boolean;
begin
  Result := FEdicion.GetInfoCeldaTallaActiva(
    ATallaCaption, APedido, ARecibida);
end;

function TGridPivoteCompra.RecibirFilaEntera: Integer;
begin
  Result := FEdicion.RecibirFilaEntera;
end;

function TGridPivoteCompra.RecibirTodo: Integer;
begin
  Result := FEdicion.RecibirTodo;
end;

procedure TGridPivoteCompra.CapturarARecibirEditValueChanged(
  ASender: TObject);
begin
  FEdicion.CapturarARecibirEditValueChanged(ASender);
end;

procedure TGridPivoteCompra.CapturarCantidadEditValueChanged(
  ASender: TObject);
begin
  FEdicion.CapturarCantidadEditValueChanged(ASender);
end;

procedure TGridPivoteCompra.PersistirCantidadEditValueChanged(
  ASender: TObject; var AValorEditado: Variant);
begin
  FEdicion.PersistirCantidadEditValueChanged(ASender, AValorEditado);
end;

function TGridPivoteCompra.PersistirCantidadesPendientes: Integer;
begin
  Result := FEdicion.PersistirCantidadesPendientes;
end;

function TGridPivoteCompra.ColorCodigoLineaActiva: string;
begin
  Result := FEdicion.ColorCodigoLineaActiva;
end;

function TGridPivoteCompra.CambiarColorLineaActiva(
  const ACodigoAtbColor: string; out AMensaje: string): Boolean;
begin
  Result := FEdicion.CambiarColorLineaActiva(
    ACodigoAtbColor, AMensaje);
end;

function TGridPivoteCompra.PrimerAlmacenARecibir: string;
begin
  Result := FEdicion.PrimerAlmacenARecibir;
end;

function TGridPivoteCompra.TotalARecibir: Double;
begin
  Result := FEdicion.TotalARecibir;
end;

procedure TGridPivoteCompra.InitEditCeldaTalla(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit);
begin
  FPresentacion.InitEditCeldaTalla(Sender, AItem, AEdit);
end;

end.
