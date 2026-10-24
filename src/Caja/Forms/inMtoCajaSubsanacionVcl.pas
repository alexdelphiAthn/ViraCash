{******************************************************************************}
{  Módulo: inMtoCajaSubsanacionVcl                                             }
{  Tipo: Presentación de Caja                                                  }
{  Fecha: 16/09/2026                                                           }
{  Descripción: Edición limitada de unidades, importes y cobro de una venta.  }
{******************************************************************************}
unit inMtoCajaSubsanacionVcl;

interface

uses
  System.Classes, System.SysUtils, Data.DB, Datasnap.DBClient,
  Vcl.Controls, cxGridDBTableView, inLibCajaSubsanacion;

type
  TControlesSubsanacionCaja = record
    Propietario: TComponent;
    Contenedor: TWinControl;
    Lineas: TClientDataSet;
    Vista: TcxGridDBTableView;
    // Unidades, precio, descuento, "menos" y total, como en el ticket
    // original; nunca el artículo ni el SKU.
    ColumnasEditables: TArray<TcxGridDBColumn>;
    // Columna de unidades: bloqueada en las prendas de depósito.
    ColumnaCantidad: TcxGridDBColumn;
    Recalcular: TProc;
  end;

  TModoSubsanacionCajaVcl = class
  private
    FControles: TControlesSubsanacionCaja;
    FOriginales: TLineasSubsanacionCaja;
    FAntesInsertar: TDataSetNotifyEvent;
    FAntesEliminar: TDataSetNotifyEvent;
    FDespuesGuardar: TDataSetNotifyEvent;
    FGuardada: Boolean;
    procedure ActualizarTotal(ADataSet: TDataSet);
    procedure BloquearEstructura(ADataSet: TDataSet);
    function EsColumnaEditable(AColumna: TObject): Boolean;
    function LineaActual(out ALinea: TLineaSubsanacionCaja): Boolean;
    function EsLineaActualFija: Boolean;
    function EsLineaActualConCantidadFija: Boolean;
    procedure ConfirmarEdicion;
    function LeerLineas: TLineasSubsanacionCaja;
  public
    // Forma de pago y descuento global se editan en la pantalla de Cobro.
    constructor Create(const AControles: TControlesSubsanacionCaja;
      const AOriginales: TLineasSubsanacionCaja);
    destructor Destroy; override;
    function LineasCorregidas: TLineasSubsanacionCaja;
    // Columna editable en la línea actual: los abonos a cuenta y anticipos
    // (líneas fijas) no se pueden corregir y las prendas de depósito
    // conservan sus unidades.
    function PermiteEditar(AColumna: TObject): Boolean;
    // Unidades tecleadas admisibles en la línea actual; si no, AMensaje
    // explica el motivo.
    function CantidadValida(const AValor: Variant;
      out AMensaje: string): Boolean;
    // Pide el motivo al grabar; False si el usuario cancela.
    function PedirMotivo(out AMotivo: string): Boolean;
    procedure MarcarGuardada;
    property Guardada: Boolean read FGuardada;
  end;

implementation

uses
  System.Variants, Vcl.Dialogs, cxEdit, inLibMensajesVcl,
  inLibMsgSubsanacionCaja, inLibFacturas, UniDataCajaSubsanacionImportes;

const
  LONGITUD_MOTIVO = 500;

constructor TModoSubsanacionCajaVcl.Create(
  const AControles: TControlesSubsanacionCaja;
  const AOriginales: TLineasSubsanacionCaja);
var
  i: Integer;
begin
  inherited Create;
  FControles := AControles;
  FOriginales := Copy(AOriginales);
  FAntesInsertar := FControles.Lineas.BeforeInsert;
  FAntesEliminar := FControles.Lineas.BeforeDelete;
  FDespuesGuardar := FControles.Lineas.AfterPost;
  FControles.Lineas.AfterPost := ActualizarTotal;
  FControles.Lineas.BeforeInsert := BloquearEstructura;
  FControles.Lineas.BeforeDelete := BloquearEstructura;
  FControles.Vista.OptionsData.Appending := False;
  FControles.Vista.OptionsData.Inserting := False;
  FControles.Vista.OptionsData.Deleting := False;
  FControles.Vista.OptionsView.NewItemRow := False;
  for i := 0 to FControles.Vista.ColumnCount - 1 do
    FControles.Vista.Columns[i].Options.Editing :=
      EsColumnaEditable(FControles.Vista.Columns[i]);
end;

function TModoSubsanacionCajaVcl.EsColumnaEditable(
  AColumna: TObject): Boolean;
var
  oColumna: TcxGridDBColumn;
begin
  Result := False;
  if not FGuardada then
    for oColumna in FControles.ColumnasEditables do
      Result := Result or (oColumna = AColumna);
end;

function TModoSubsanacionCajaVcl.LineaActual(
  out ALinea: TLineaSubsanacionCaja): Boolean;
var
  sNumero: string;
  oLinea: TLineaSubsanacionCaja;
begin
  Result := False;
  ALinea := Default(TLineaSubsanacionCaja);
  if FControles.Lineas.Active and not FControles.Lineas.IsEmpty then
  begin
    sNumero := FControles.Lineas.FieldByName(fnrolin).AsString;
    for oLinea in FOriginales do
      if not Result and (oLinea.Numero = sNumero) then
      begin
        ALinea := oLinea;
        Result := True;
      end;
  end;
end;

function TModoSubsanacionCajaVcl.EsLineaActualFija: Boolean;
var
  oLinea: TLineaSubsanacionCaja;
begin
  Result := LineaActual(oLinea) and oLinea.Fija;
end;

function TModoSubsanacionCajaVcl.EsLineaActualConCantidadFija: Boolean;
var
  oLinea: TLineaSubsanacionCaja;
begin
  Result := LineaActual(oLinea) and oLinea.CantidadFija;
end;

function TModoSubsanacionCajaVcl.PermiteEditar(AColumna: TObject): Boolean;
begin
  Result := EsColumnaEditable(AColumna) and not EsLineaActualFija and
    ((AColumna <> FControles.ColumnaCantidad) or
     not EsLineaActualConCantidadFija);
end;

function TModoSubsanacionCajaVcl.CantidadValida(const AValor: Variant;
  out AMensaje: string): Boolean;
var
  oLinea: TLineaSubsanacionCaja;
  dCantidad: Double;
begin
  // Mismas reglas que el dominio (ValidarImportesSubsanacion), aplicadas
  // al salir de la celda para avisar antes de recalcular la línea.
  AMensaje := '';
  if not LineaActual(oLinea) then
    AMensaje := SSubsanacionLineasDistintas
  else if oLinea.Fija then
    AMensaje := Format(SSubsanacionLineaNoCorregible, [oLinea.Numero])
  else if oLinea.CantidadFija then
    AMensaje := Format(SSubsanacionCantidadFija, [oLinea.Numero])
  else
  begin
    dCantidad := StrToFloatDef(VarToStrDef(AValor, '0'), 0);
    if dCantidad <= 0 then
      AMensaje := Format(SSubsanacionCantidadNoPositiva, [oLinea.Numero]);
  end;
  Result := AMensaje = '';
end;

destructor TModoSubsanacionCajaVcl.Destroy;
begin
  if Assigned(FControles.Lineas) then
  begin
    FControles.Lineas.AfterPost := FDespuesGuardar;
    FControles.Lineas.BeforeInsert := FAntesInsertar;
    FControles.Lineas.BeforeDelete := FAntesEliminar;
  end;
  inherited;
end;

procedure TModoSubsanacionCajaVcl.BloquearEstructura(ADataSet: TDataSet);
begin
  raise EcxEditValidationError.Create(SSubsanacionLineasFijas);
end;

procedure TModoSubsanacionCajaVcl.ActualizarTotal(ADataSet: TDataSet);
begin
  FControles.Recalcular();
end;

procedure TModoSubsanacionCajaVcl.ConfirmarEdicion;
begin
  FControles.Vista.Controller.EditingController.HideEdit(True);
  FControles.Lineas.CheckBrowseMode;
end;

function TModoSubsanacionCajaVcl.LeerLineas: TLineasSubsanacionCaja;
var
  i, j: Integer;
  bEncontrada: Boolean;
  oActuales: TLineasSubsanacionCaja;
begin
  oActuales := LeerImportesSubsanacion(FControles.Lineas);
  if Length(oActuales) <> Length(FOriginales) then
    raise EArgumentException.Create(SSubsanacionLineasFijas);
  Result := Copy(FOriginales);
  for i := 0 to High(Result) do
  begin
    bEncontrada := False;
    for j := 0 to High(oActuales) do
    begin
      if Result[i].Numero = oActuales[j].Numero then
      begin
        // Las unidades tecleadas; las originales vienen de la operación.
        Result[i].Cantidad := oActuales[j].Cantidad;
        Result[i].Importe := oActuales[j].Importe;
        Result[i].PrecioSalida := oActuales[j].PrecioSalida;
        bEncontrada := True;
      end;
    end;
    if not bEncontrada then
      raise EArgumentException.Create(SSubsanacionLineasFijas);
  end;
end;

function TModoSubsanacionCajaVcl.LineasCorregidas:
  TLineasSubsanacionCaja;
begin
  ConfirmarEdicion;
  Result := LeerLineas;
  ValidarImportesSubsanacion(Result);
end;

function TModoSubsanacionCajaVcl.PedirMotivo(out AMotivo: string): Boolean;
var
  oValores: array of string;
begin
  SetLength(oValores, 1);
  Result := InputQuery_fza(SSubsanacionBoton, [SSubsanacionMotivo], oValores,
    function(const AValores: array of string): Boolean
    begin
      Result := (Trim(AValores[0]) <> '') and
        (Length(Trim(AValores[0])) <= LONGITUD_MOTIVO);
      if not Result then
        ShowMessage_fza(SSubsanacionMotivoObligatorio);
    end);
  AMotivo := '';
  if Result then
    AMotivo := Trim(oValores[0]);
end;

procedure TModoSubsanacionCajaVcl.MarcarGuardada;
begin
  FGuardada := True;
  FControles.Vista.OptionsData.Editing := False;
end;

end.
