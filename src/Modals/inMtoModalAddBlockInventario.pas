{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalAddBlockInventario                                  }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de carga masiva de SKUs en un inventario.                           }
{    Hereda de AddBlockBase y aplica filtros propios de inventario.            }
{******************************************************************************}
unit inMtoModalAddBlockInventario;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.StdCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxClasses, cxContainer, cxEdit,
  cxLabel, cxButtons, cxTextEdit, cxCheckBox, cxRadioGroup,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGrid,
  inMtoModalAddBlockBase, cxLookAndFeelPainters, Vcl.Menus, cxFilter,
  cxCustomData, cxStyles, dxScrollbarAnnotations, cxTL, cxMaskEdit, cxDBData,
  cxCurrencyEdit, Vcl.ComCtrls, dxCore, cxDateUtils, JvComponentBase,
  JvEnterTab, cxLocalization, cxSplitter, cxSpinEdit, cxDropDownEdit,
  cxCalendar, cxCustomListBox, cxCheckListBox, cxGroupBox, cxInplaceContainer,
  cxDBTL, cxTLData, cxPC,
  inLibCargaMasivaArticulosPersistenciaIntf;

type
  TAddBlockInventarioResult = record
    Aceptado          : Boolean;
    NumLineas         : Integer;        // SKUs (lineas) insertadas
    NumArticulos      : Integer;        // articulos distintos cubiertos
    ArticulosCodigos  : TArray<string>;
    Empresa, Almacen, Serie, Nro: string;
    // FZ-ISSUE-306: carga de negativos con su teórico ya puesto; la
    // pantalla no propone recalcular.
    SoloNegativos     : Boolean;
  end;

  TfrmModalAddBlockInventario = class(TfrmModalAddBlockBase)
    lblInventarioInfo: TcxLabel;
    lblNotaCarga: TcxLabel;
    chkSoloNegativos: TcxCheckBox;

    // Columnas extra del preview
    colPrevSkusConStock: TcxGridDBColumn;
    colPrevPMPActual: TcxGridDBColumn;

    procedure FormCreate(Sender: TObject);
    procedure chkSoloNegativosClick(Sender: TObject);

  protected
    FResultadoInv : TAddBlockInventarioResult;
    FEmpresa, FAlmacen, FSerie, FNro: string;
    FSoloConStockAnterior: Boolean;
    FNotaCargaNormal: string;

    function RecogerFiltros: TFiltrosCargaMasivaArticulos; override;

    function  ValidarAntesDePrevisualizar(out AMensaje: string): Boolean;
    override;
    function ContextoCargaMasiva: TContextoCargaMasivaArticulos; override;
    function  TextoConfirmacion(ANumPendientes: Integer): string; override;
    function  TextoExito(ANumInsertados: Integer): string; override;
    function  TextoExcluirYaCargados: string; override;

    function  EjecutarInsercion(out ANumInsertados: Integer;
                                out ACodigos: TArray<string>): Boolean;
                                override;

  public
    class function Ejecutar(
      AOwner: TComponent;
      const AEmpresa, AAlmacen, ASerie,
      ANro: string): TAddBlockInventarioResult; overload;
    class function Ejecutar(
      AOwner: TComponent;
      const AEmpresa, AAlmacen, ASerie, ANro: string;
      const AServicios: TServiciosCargaMasivaArticulos):
      TAddBlockInventarioResult; overload;
    property ResultadoInv: TAddBlockInventarioResult read FResultadoInv;
  end;

implementation

{$R *.dfm}

uses
  inLibMensajesVcl,
  inLibUser, inLibMsgArticulos;

resourcestring
  SNotaCargaNegativos =
    'Se cargarán sólo los SKU y lotes negativos del almacén del ' +
    'inventario, con cantidad física cero para regularizar el stock.';
  SPreviewNegativosPendiente = 'Previsualización pendiente';
  SSkusNegativos = 'SKUs negativos';
  // FZ-ISSUE-306: el inventario queda marcado de solo negativos; al
  // recalcular o regularizar se toma el stock de ese momento y no se
  // añaden los demás lotes del artículo (script 794).
  SPreguntaConfirmarNegativos =
    'Se van a añadir %d artículos al inventario %s/%s/%s/%s.' + sLineBreak +
    'Sólo se cargan sus SKU y lotes negativos en este almacén, con la ' +
    'cantidad teórica de ahora y física cero: al regularizar el ' +
    'inventario quedan a cero.' + sLineBreak +
    'El inventario queda como de solo negativos: no admite cargas ' +
    'normales y no toca los demás lotes de los artículos.' + sLineBreak +
    sLineBreak + '¿Continuar?';
  SInfoLineasNegativos =
    '%d líneas negativas añadidas al inventario, con su cantidad teórica ' +
    'y su coste.' + sLineBreak +
    'No hace falta «Recalcular teórico/PMP»: regulariza el inventario ' +
    'para dejarlas a cero.';
  SSkusConStock = 'SKUs c/ stock';


class function TfrmModalAddBlockInventario.Ejecutar(
  AOwner: TComponent;
  const AEmpresa, AAlmacen, ASerie, ANro: string): TAddBlockInventarioResult;
var
  Servicios: TServiciosCargaMasivaArticulos;
begin
  Servicios := Default(TServiciosCargaMasivaArticulos);
  Result := Ejecutar(
    AOwner, AEmpresa, AAlmacen, ASerie, ANro, Servicios);
end;

class function TfrmModalAddBlockInventario.Ejecutar(
  AOwner: TComponent;
  const AEmpresa, AAlmacen, ASerie, ANro: string;
  const AServicios: TServiciosCargaMasivaArticulos):
  TAddBlockInventarioResult;
var
  frm: TfrmModalAddBlockInventario;
  i  : Integer;
begin
  frm := TfrmModalAddBlockInventario.Create(AOwner, AServicios);
  try
    frm.FEmpresa := AEmpresa;
    frm.FAlmacen := AAlmacen;
    frm.FSerie   := ASerie;
    frm.FNro     := ANro;
    frm.Inicializar;

    // Pre-marcar el almacen del inventario en la pestana de stock.
    // En inventario el filtro de stock se aplica SIEMPRE en el almacen
    // del propio inventario.
    for i := 0 to frm.chkLstAlmacenes.Items.Count - 1 do
      if (frm.chkLstAlmacenes.Items[i].ItemObject is TStringList) and
         (TStringList(frm.chkLstAlmacenes.Items[i].ItemObject).Count > 0) and
         (TStringList(
           frm.chkLstAlmacenes.Items[i].ItemObject)[0] = AAlmacen) then
      begin
        frm.chkLstAlmacenes.Items[i].Checked := True;
        Break;
      end;

    frm.lblInventarioInfo.Caption :=
      Format(SCaptionInventarioDestino,
             [AEmpresa, AAlmacen, ASerie, ANro]);

    frm.ShowModal;
    Result := frm.FResultadoInv;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalAddBlockInventario.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Caption := STituloAnadirBloqueInventario;

  // En inventario el stock importa siempre — lo activamos por defecto
  chkSoloConStock.Checked := True;

  FNotaCargaNormal := lblNotaCarga.Caption;
  FResultadoInv.Aceptado := False;
end;

// ============================================================================
//   Overrides de la base
// ============================================================================

function TfrmModalAddBlockInventario.ValidarAntesDePrevisualizar(
  out AMensaje: string): Boolean;
begin
  Result := True;
  AMensaje := '';
  if (FEmpresa = '') or (FAlmacen = '') or (FSerie = '') or (FNro = '') then
  begin
    Result := False;
    AMensaje := SErrorDestinoInventarioAddBlock;
  end;
end;

procedure TfrmModalAddBlockInventario.chkSoloNegativosClick(
  Sender: TObject);
begin
  if chkSoloNegativos.Checked then
  begin
    FSoloConStockAnterior := chkSoloConStock.Checked;
    chkSoloConStock.Checked := False;
    lblNotaCarga.Caption := SNotaCargaNegativos;
    colPrevSkusConStock.Caption := SSkusNegativos;
  end
  else
  begin
    chkSoloConStock.Checked := FSoloConStockAnterior;
    lblNotaCarga.Caption := FNotaCargaNormal;
    colPrevSkusConStock.Caption := SSkusConStock;
  end;
  chkSoloConStock.Enabled := not chkSoloNegativos.Checked;
  if Assigned(DatosPreview) and DatosPreview.Active then
    DatosPreview.Close;
  lblPreviewInfo.Caption := SPreviewNegativosPendiente;
  lblStockAviso.Caption := '';
end;

function TfrmModalAddBlockInventario.RecogerFiltros:
  TFiltrosCargaMasivaArticulos;
begin
  Result := inherited RecogerFiltros;
  Result.SoloNegativos := chkSoloNegativos.Checked;
  if Result.SoloNegativos then
  begin
    Result.SoloConStock := False;
    Result.CodigosAlmacen := TArray<string>.Create(FAlmacen);
  end;
end;

function TfrmModalAddBlockInventario.ContextoCargaMasiva:
  TContextoCargaMasivaArticulos;
begin
  Result.Modo := mcInventario;
  Result.EmpresaInventario := FEmpresa;
  Result.AlmacenInventario := FAlmacen;
  Result.SerieInventario := FSerie;
  Result.NumeroInventario := FNro;
end;

function TfrmModalAddBlockInventario.TextoConfirmacion(
  ANumPendientes: Integer): string;
begin
  if chkSoloNegativos.Checked then
    Result := Format(SPreguntaConfirmarNegativos,
      [ANumPendientes, FEmpresa, FAlmacen, FSerie, FNro])
  else if chkSoloConStock.Checked then
    Result := Format(SPreguntaConfirmarInventarioAddBlock,
      [ANumPendientes, FEmpresa, FAlmacen, FSerie, FNro])
  else
    // FZ-ISSUE-622: sin la casilla de stock entran todos los SKU.
    Result := Format(SPreguntaConfirmarInventarioAddBlockTodos,
      [ANumPendientes, FEmpresa, FAlmacen, FSerie, FNro]);
end;

function TfrmModalAddBlockInventario.TextoExito(
  ANumInsertados: Integer): string;
begin
  if chkSoloNegativos.Checked then
    Result := Format(SInfoLineasNegativos, [ANumInsertados])
  else
    Result := Format(SInfoLineasInventarioAddBlock, [ANumInsertados]);
end;

function TfrmModalAddBlockInventario.TextoExcluirYaCargados: string;
begin
  Result := SCaptionExcluirArticulosYaEnInventario;
end;

// ============================================================================
//   Insercion real
// ============================================================================

function TfrmModalAddBlockInventario.EjecutarInsercion(
  out ANumInsertados: Integer;
  out ACodigos: TArray<string>): Boolean;
var
  oParametros: TParametrosInsercionInventario;
  oResultado: TResultadoInsercionCargaMasiva;
begin
  Result := False;
  ANumInsertados := 0;
  SetLength(ACodigos, 0);
  if Assigned(DatosPreview) and DatosPreview.Active and
     (DatosPreview.RecordCount > 0) then
  begin
    oParametros.SoloNegativos := chkSoloNegativos.Checked;
    // FZ-ISSUE-622: la previsualización ya filtra los artículos con
    // stock; la inserción debe filtrar también los SKU, o entran todos.
    oParametros.SoloConStock := chkSoloConStock.Checked and
      (not chkSoloNegativos.Checked);
    oParametros.Empresa := FEmpresa;
    oParametros.Almacen := FAlmacen;
    oParametros.Serie := FSerie;
    oParametros.Numero := FNro;
    oParametros.Usuario := IdentidadSesion.Usuario;
    try
      oResultado := InsercionesCargaMasiva.InsertarInventario(
        ConsultaPreview,
        oParametros);
      ANumInsertados := oResultado.NumeroLineas;
      ACodigos := oResultado.CodigosArticulo;
      FResultadoInv.Aceptado := True;
      FResultadoInv.NumLineas := oResultado.NumeroLineas;
      FResultadoInv.NumArticulos := oResultado.NumeroArticulos;
      FResultadoInv.ArticulosCodigos := ACodigos;
      FResultadoInv.Empresa := FEmpresa;
      FResultadoInv.Almacen := FAlmacen;
      FResultadoInv.Serie := FSerie;
      FResultadoInv.Nro := FNro;
      FResultadoInv.SoloNegativos := chkSoloNegativos.Checked;
      Result := True;
    except
      on E: Exception do
      begin
        ShowMessage_fza(SErrorInsertarLineasInventarioAddBlock + E.Message);
      end;
    end;
  end;
end;

end.
