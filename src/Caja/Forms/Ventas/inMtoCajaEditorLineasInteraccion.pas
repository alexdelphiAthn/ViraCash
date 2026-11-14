{******************************************************************************}
{                                                                              }
{  Interaccion VCL del editor de lineas de caja.                               }
{                                                                              }
{******************************************************************************}
unit inMtoCajaEditorLineasInteraccion;

interface

uses
  System.Variants, Vcl.ExtCtrls, cxEdit, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxEditRepositoryItems,
  cxDBExtLookupComboBox, inMtoCajaOpePresentacionVcl;

type
  TContextoInteraccionEditorLineasCajaVcl = record
    VistaLineas: TcxGridDBTableView;
    RepositorioSoloTexto: TcxEditRepositoryTextItem;
    RepositorioCombo: TcxEditRepositoryExtLookupComboBoxItem;
    TemporizadorBusqueda: TTimer;
    LectorLeyendoTrama: TConsultaBooleanaCajaVcl;
  end;
  TInteraccionEditorLineasCajaVcl = class
  private
    FContexto: TContextoInteraccionEditorLineasCajaVcl;
    function EsCeldaEnfocada(
      AItem: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord): Boolean;
  public
    constructor Create(
      const AContexto: TContextoInteraccionEditorLineasCajaVcl);
    procedure CambiarArticulo(Sender: TObject);
    procedure CerrarBusquedaArticulo(Sender: TObject);
    procedure ObtenerPropiedadesArticulo(
      Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord;
      var AProperties: TcxCustomEditProperties);
  end;

implementation

uses
  inMtoCajaEditorLineasDecisiones;

constructor TInteraccionEditorLineasCajaVcl.Create(
  const AContexto: TContextoInteraccionEditorLineasCajaVcl);
begin
  inherited Create;
  FContexto := AContexto;
end;

function TInteraccionEditorLineasCajaVcl.EsCeldaEnfocada(
  AItem: TcxCustomGridTableItem;
  ARecord: TcxCustomGridRecord): Boolean;
begin
  Result := Assigned(FContexto.VistaLineas.Controller) and
    (FContexto.VistaLineas.Controller.FocusedRecord = ARecord) and
    (FContexto.VistaLineas.Controller.FocusedItem = AItem);
end;

procedure TInteraccionEditorLineasCajaVcl.CambiarArticulo(
  Sender: TObject);
begin
  if not FContexto.LectorLeyendoTrama() then
  begin
    FContexto.TemporizadorBusqueda.Enabled := False;
    FContexto.TemporizadorBusqueda.Enabled := True;
  end;
end;

procedure TInteraccionEditorLineasCajaVcl.CerrarBusquedaArticulo(
  Sender: TObject);
var
  Combo: TcxExtLookupComboBox;
  Vista: TcxGridDBTableView;
begin
  if Sender is TcxExtLookupComboBox then
  begin
    Combo := TcxExtLookupComboBox(Sender);
    if Combo.Properties.View is TcxGridDBTableView then
    begin
      Vista := TcxGridDBTableView(Combo.Properties.View);
      Vista.BeginUpdate;
      try
        Vista.Controller.IncSearchingText := '';
        Vista.DataController.Filter.Clear;
        Vista.DataController.Filter.Active := False;
      finally
        Vista.EndUpdate;
      end;
    end;
  end;
end;

procedure TInteraccionEditorLineasCajaVcl.ObtenerPropiedadesArticulo(
  Sender: TcxCustomGridTableItem;
  ARecord: TcxCustomGridRecord;
  var AProperties: TcxCustomEditProperties);
var
  ValorActual: Variant;
begin
  if Assigned(ARecord) then
  begin
    ValorActual := ARecord.Values[Sender.Index];
    if DebeUsarSoloTexto(
         ValorActual,
         EsCeldaEnfocada(Sender, ARecord)) then
      AProperties := FContexto.RepositorioSoloTexto.Properties
    else
      AProperties := FContexto.RepositorioCombo.Properties;
  end;
end;

end.
