{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalAddBlockDocumentoTrabajo                            }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       1.0.0                                                         }
{   Fecha:       23/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Modal de carga masiva de articulos en Documento de Trabajo.               }
{    Hereda de AddBlockBase y reutiliza los filtros de Inventarios/Tarifas.    }
{******************************************************************************}
unit inMtoModalAddBlockDocumentoTrabajo;

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
  TAddBlockDocumentoTrabajoResult = record
    Aceptado: Boolean;
    NumLineas: Integer;
    NumArticulos: Integer;
    ArticulosCodigos: TArray<string>;
    IdDocumento: Int64;
  end;

  TfrmModalAddBlockDocumentoTrabajo = class(TfrmModalAddBlockBase)
    lblDocumentoInfo: TcxLabel;
    lblNotaCarga: TcxLabel;
    procedure FormCreate(Sender: TObject);
  protected
    FResultadoDoc: TAddBlockDocumentoTrabajoResult;
    FIdDtr: Int64;
    FAlmacen: string;
    FTitulo: string;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    function ValidarAntesDePrevisualizar(out AMensaje: string): Boolean;
      override;
    function ContextoCargaMasiva: TContextoCargaMasivaArticulos; override;
    function TextoConfirmacion(ANumPendientes: Integer): string; override;
    function TextoExito(ANumInsertados: Integer): string; override;
    function TextoExcluirYaCargados: string; override;
    procedure ConfigurarPreviewExtra; override;
    function TextoResumenPreview(ANumeroRegistros: Integer): string; override;
    function EjecutarInsercion(out ANumInsertados: Integer;
                               out ACodigos: TArray<string>): Boolean;
      override;
  private
    procedure AjustarAPantalla;
    procedure PreseleccionarAlmacen;
    function AlmacenOrigenQueEsDeVenta(out AAlmacen: string): Boolean;
  public
    class function Ejecutar(
      AOwner: TComponent;
      AIdDtr: Int64;
      const AAlmacen, ATitulo: string): TAddBlockDocumentoTrabajoResult;
      overload;
    class function Ejecutar(
      AOwner: TComponent;
      AIdDtr: Int64;
      const AAlmacen, ATitulo: string;
      const AServicios: TServiciosCargaMasivaArticulos):
      TAddBlockDocumentoTrabajoResult; overload;
    property ResultadoDoc: TAddBlockDocumentoTrabajoResult read FResultadoDoc;
  end;

implementation

{$R *.dfm}

uses
  inLibMensajesVcl,
  inLibCargaMasivaArticulosReglas, inLibUser, inLibMsgArticulos,
  inLibMsgComun, inLibMsgVentas;

class function TfrmModalAddBlockDocumentoTrabajo.Ejecutar(
  AOwner: TComponent;
  AIdDtr: Int64;
  const AAlmacen, ATitulo: string): TAddBlockDocumentoTrabajoResult;
var
  Servicios: TServiciosCargaMasivaArticulos;
begin
  Servicios := Default(TServiciosCargaMasivaArticulos);
  Result := Ejecutar(AOwner, AIdDtr, AAlmacen, ATitulo, Servicios);
end;

class function TfrmModalAddBlockDocumentoTrabajo.Ejecutar(
  AOwner: TComponent;
  AIdDtr: Int64;
  const AAlmacen, ATitulo: string;
  const AServicios: TServiciosCargaMasivaArticulos):
  TAddBlockDocumentoTrabajoResult;
var
  frm: TfrmModalAddBlockDocumentoTrabajo;
begin
  frm := TfrmModalAddBlockDocumentoTrabajo.Create(AOwner, AServicios);
  try
    frm.FIdDtr := AIdDtr;
    frm.FAlmacen := AAlmacen;
    frm.FTitulo := ATitulo;
    frm.Inicializar;
    frm.PreseleccionarAlmacen;
    frm.lblDocumentoInfo.Caption :=
      Format(SCaptionDocumentoDestino, [AIdDtr, ATitulo]);
    frm.ShowModal;
    Result := frm.FResultadoDoc;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalAddBlockDocumentoTrabajo.FormCreate(Sender: TObject);
begin
  inherited;
  AjustarAPantalla;
  Self.Caption := STituloAnadirBloqueDTR;
  btnAceptar.Caption := SCaptionAceptarF12;
  btnCancelar.Caption := SCaptionCancelarEsc;
  chkSoloConStock.Checked := True;
  chkSoloConStock.Enabled := False;
  ConfigurarValoresReposicionDefecto(
    RESERVA_STOCK_ORIGEN_DEFECTO_DTR,
    MAXIMO_SERVIR_POR_SKU_DEFECTO_DTR,
    True,
    STOCK_MAXIMO_ALMACEN_VENTA_DEFECTO_DTR);
  FResultadoDoc.Aceptado := False;
end;

procedure TfrmModalAddBlockDocumentoTrabajo.KeyDown(var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_F12) and (Shift = []) then
  begin
    Key := 0;
    btnAceptarClick(btnAceptar);
  end
  else if (Key = VK_ESCAPE) and (Shift = []) then
  begin
    Key := 0;
    btnCancelarClick(btnCancelar);
  end
  else
  begin
    inherited KeyDown(Key, Shift);
  end;
end;

procedure TfrmModalAddBlockDocumentoTrabajo.AjustarAPantalla;
var
  rArea: TRect;
begin
  if Assigned(Application.MainForm) then
  begin
    rArea := Application.MainForm.Monitor.WorkareaRect;
  end
  else
  begin
    rArea := Screen.PrimaryMonitor.WorkareaRect;
  end;
  if Height > rArea.Height then
  begin
    Height := rArea.Height;
  end;
end;

procedure TfrmModalAddBlockDocumentoTrabajo.PreseleccionarAlmacen;
var
  i: Integer;
begin
  if FAlmacen <> '' then
  begin
    for i := 0 to chkLstAlmacenes.Items.Count - 1 do
    begin
      if (chkLstAlmacenes.Items[i].ItemObject is TStringList) and
         (TStringList(chkLstAlmacenes.Items[i].ItemObject).Count > 0) then
      begin
        if TStringList(chkLstAlmacenes.Items[i].ItemObject)[0] = FAlmacen then
        begin
          chkLstAlmacenes.Items[i].Checked := True;
        end;
      end;
    end;
    // El almacen del documento es el origen del reparto: si la sesion esta
    // en ese mismo almacen no puede quedar tambien como almacen de ventas.
    for i := 0 to chkLstAlmacenesVentas.Items.Count - 1 do
    begin
      if (i < FCodigosAlmacenesVentas.Count) and
         SameText(FCodigosAlmacenesVentas[i], FAlmacen) then
      begin
        chkLstAlmacenesVentas.Items[i].Checked := False;
      end;
    end;
  end;
end;

function TfrmModalAddBlockDocumentoTrabajo.AlmacenOrigenQueEsDeVenta(
  out AAlmacen: string): Boolean;
var
  sOrigen: string;
  sVenta: string;
begin
  Result := False;
  AAlmacen := '';
  if chkFiltrarStockAlmacenVenta.Checked then
  begin
    for sVenta in RecogerCodigosAlmacenesVentasSeleccionados do
    begin
      for sOrigen in RecogerCodigosAlmacenesSeleccionados do
      begin
        if (not Result) and SameText(sOrigen, sVenta) then
        begin
          AAlmacen := sVenta;
          Result := True;
        end;
      end;
    end;
  end;
end;

function TfrmModalAddBlockDocumentoTrabajo.ValidarAntesDePrevisualizar(
  out AMensaje: string): Boolean;
var
  sAlmacen: string;
begin
  Result := False;
  AMensaje := '';
  chkSoloConStock.Checked := True;
  chkSoloConStock.Enabled := False;
  if Length(RecogerCodigosAlmacenesSeleccionados) = 0 then
  begin
    PreseleccionarAlmacen;
  end;
  if FIdDtr <= 0 then
  begin
    AMensaje := SErrorDestinoDocumentoTrabajoAddBlock;
  end
  else if Length(RecogerCodigosAlmacenesSeleccionados) = 0 then
  begin
    AMensaje := SErrorAlmacenesDocumentoTrabajoAddBlock;
  end
  else if AlmacenOrigenQueEsDeVenta(sAlmacen) then
  begin
    AMensaje := Format(
      SErrorAlmacenOrigenYVentaDocumentoTrabajoAddBlock, [sAlmacen]);
    pcFiltros.ActivePage := tsVentas;
  end
  else
  begin
    Result := True;
  end;
end;

function TfrmModalAddBlockDocumentoTrabajo.ContextoCargaMasiva:
  TContextoCargaMasivaArticulos;
begin
  Result.Modo := mcDocumentoTrabajo;
  Result.IdDocumentoTrabajo := FIdDtr;
end;

function TfrmModalAddBlockDocumentoTrabajo.TextoConfirmacion(
  ANumPendientes: Integer): string;
begin
  Result := Format(SPreguntaConfirmarDocumentoTrabajoAddBlock,
    [ANumPendientes, FTitulo]);
end;

function TfrmModalAddBlockDocumentoTrabajo.TextoExito(
  ANumInsertados: Integer): string;
begin
  Result := Format(SInfoLineasDocumentoTrabajoAddBlock,
                   [ANumInsertados]);
end;

function TfrmModalAddBlockDocumentoTrabajo.TextoExcluirYaCargados: string;
begin
  Result := SCaptionExcluirSkuDocumentoTrabajoAddBlock;
end;

procedure TfrmModalAddBlockDocumentoTrabajo.ConfigurarPreviewExtra;
begin
  inherited;
  colPrevCodigo.Caption := SCaptionColSku;
  colPrevCodigo.DataBinding.FieldName := 'CODIGO_UNIDAD_SKU';
end;

function TfrmModalAddBlockDocumentoTrabajo.TextoResumenPreview(
  ANumeroRegistros: Integer): string;
begin
  Result := Format(
    SCaptionSkuEncontrados,
    [IntToStr(ANumeroRegistros)]);
end;

function TfrmModalAddBlockDocumentoTrabajo.EjecutarInsercion(
  out ANumInsertados: Integer;
  out ACodigos: TArray<string>): Boolean;
var
  oParametros: TParametrosInsercionDocumentoTrabajo;
  oResultado: TResultadoInsercionCargaMasiva;
begin
  Result := False;
  ANumInsertados := 0;
  SetLength(ACodigos, 0);
  if Assigned(DatosPreview) and DatosPreview.Active and
     (DatosPreview.RecordCount > 0) then
  begin
    oParametros.IdDocumento := FIdDtr;
    oParametros.CodigosAlmacen := RecogerCodigosAlmacenesSeleccionados;
    oParametros.ReservaStockOrigen := spnReservaStockOrigen.Value;
    oParametros.MaximoServirPorSku := spnMaximoServirPorSku.Value;
    oParametros.Usuario := IdentidadSesion.Usuario;
    try
      oResultado := InsercionesCargaMasiva.InsertarDocumentoTrabajo(
        ConsultaPreview,
        oParametros);
      ANumInsertados := oResultado.NumeroLineas;
      ACodigos := oResultado.CodigosArticulo;
      FResultadoDoc.Aceptado := True;
      FResultadoDoc.NumLineas := oResultado.NumeroLineas;
      FResultadoDoc.NumArticulos := oResultado.NumeroArticulos;
      FResultadoDoc.ArticulosCodigos := ACodigos;
      FResultadoDoc.IdDocumento := FIdDtr;
      Result := True;
    except
      on E: Exception do
      begin
        ShowMessage_fza(SErrorInsertarLineasDocumentoTrabajoAddBlock +
                    E.Message);
      end;
    end;
  end;
end;

end.
