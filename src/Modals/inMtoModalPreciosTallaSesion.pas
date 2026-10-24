{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalPreciosTallaSesion                                  }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       22/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Coste y PVP de cada color y talla de una línea de sesión de compra,       }
{    además del precio único de la línea (FZ-ISSUE-638). Las celdas sin        }
{    precio propio muestran el de la línea y, si lo conservan o se vacían,     }
{    lo siguen heredando. Al teclear el coste de una talla se                  }
{    propone su PVP con el coeficiente, redondeo y ajuste de la sesión.        }
{******************************************************************************}
unit inMtoModalPreciosTallaSesion;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.Classes, Vcl.Forms, Uni, cxCustomData, cxGridTableView,
  inMtoModalAceptCancel,
  inLibComprasSesionesPreciosTalla;

type
  // Parámetros de la cabecera de la sesión para calcular el PVP desde
  // el coste, los mismos que usa la línea.
  TCalculoPvpSesion = record
    Coeficiente: Double;
    MultiploRedondeo: Double;
    AjusteFinal: Double;
  end;

  TfrmModalPreciosTallaSesion = class(TfrmModalAceptCancel)
  private
    FConexion: TUniConnection;
    FSerie: string;
    FNumero: string;
    FLinea: Integer;
    FUsuario: string;
    FPrecios: TPreciosCeldasSesion;
    FVista: TcxGridTableView;
    FGuardada: Boolean;
    FCalculoPvp: TCalculoPvpSesion;
    FCosteLinea: Double;
    FPvpLinea: Double;
    // PVP propuesto en cada celda; Null si el usuario lo tecleó o no hay.
    FPvpPropuesto: array of Variant;
    FProponiendo: Boolean;
    procedure CrearAviso(ACosteLinea, APvpLinea: Double);
    procedure CrearRejilla;
    procedure MostrarPrecios(Sender: TObject);
    procedure IniciarEdicion(var AMensaje: TMessage); message WM_APP + 651;
    procedure CeldaCambiada(ADataController: TcxCustomDataController;
      ARecordIndex, AItemIndex: Integer);
    procedure ProponerPvp(ACelda: Integer);
    function PrecioPropio(const AValor: Variant;
      APrecioLinea: Double): Boolean;
    procedure Recoger;
    procedure CerrarSinLiberar(Sender: TObject; var Action: TCloseAction);
  public
    constructor CreatePrecios(AOwner: TComponent; AConexion: TUniConnection;
      const ASerie, ANumero: string; ALinea: Integer;
      const APrecios: TPreciosCeldasSesion; ACosteLinea, APvpLinea: Double;
      const ACalculoPvp: TCalculoPvpSesion; const AUsuario: string);
    function CloseQuery: Boolean; override;
    // False si no se grabó nada (cancelado o línea sin tallas).
    class function Editar(AOwner: TComponent; AConexion: TUniConnection;
      const ASerie, ANumero: string; ALinea: Integer;
      ACosteLinea, APvpLinea: Double; const ACalculoPvp: TCalculoPvpSesion;
      const AUsuario: string; APosicion: Integer = 0): Boolean;
  end;

implementation

uses
  System.SysUtils, System.Variants, System.Math, Vcl.Controls, cxGrid,
  cxLabel, cxDataStorage, cxCurrencyEdit,
  inLibMensajesVcl, inLibMsgCompras, inLibComprasSesiones,
  UniDataComprasSesionesPreciosLinea;

const
  COLUMNA_COLOR = 0;
  COLUMNA_TALLA = 1;
  COLUMNA_COSTE = 2;
  COLUMNA_PVP = 3;
  FORMATO_PRECIO = '#,##0.00##';

constructor TfrmModalPreciosTallaSesion.CreatePrecios(AOwner: TComponent;
  AConexion: TUniConnection; const ASerie, ANumero: string;
  ALinea: Integer; const APrecios: TPreciosCeldasSesion;
  ACosteLinea, APvpLinea: Double; const ACalculoPvp: TCalculoPvpSesion;
  const AUsuario: string);
var
  iCelda: Integer;
begin
  inherited Create(AOwner);
  jvntrstb1.EnterAsTab := False;
  FConexion := AConexion;
  FSerie := ASerie;
  FNumero := ANumero;
  FLinea := ALinea;
  FUsuario := AUsuario;
  FPrecios := Copy(APrecios);
  FCalculoPvp := ACalculoPvp;
  FCosteLinea := ACosteLinea;
  FPvpLinea := APvpLinea;
  SetLength(FPvpPropuesto, Length(FPrecios));
  for iCelda := 0 to High(FPvpPropuesto) do
    FPvpPropuesto[iCelda] := Null;
  OnClose := CerrarSinLiberar;
  Caption := Format(STituloPreciosTallaSesion, [ALinea]);
  ClientWidth := ScaleValue(620);
  ClientHeight := ScaleValue(520);
  CrearAviso(ACosteLinea, APvpLinea);
  CrearRejilla;
  OnShow := MostrarPrecios;
end;

procedure TfrmModalPreciosTallaSesion.MostrarPrecios(Sender: TObject);
begin
  // La vista necesita completar su apertura antes de crear el editor.
  PostMessage(Handle, WM_APP + 651, 0, 0);
end;

procedure TfrmModalPreciosTallaSesion.IniciarEdicion(var AMensaje: TMessage);
begin
  if FVista.DataController.RecordCount > 0 then
  begin
    FVista.Controller.FocusedRecordIndex := 0;
    FVista.Controller.FocusedColumn := FVista.Columns[COLUMNA_COSTE];
    ActiveControl := FVista.Site;
    FVista.Controller.EditingController.ShowEdit;
    if Assigned(FVista.Controller.EditingController.Edit) then
      FVista.Controller.EditingController.Edit.SelectAll;
  end;
end;

procedure TfrmModalPreciosTallaSesion.CrearAviso(ACosteLinea,
  APvpLinea: Double);
var
  oAviso: TcxLabel;
begin
  oAviso := TcxLabel.Create(Self);
  oAviso.Parent := pnlBody;
  oAviso.Align := alTop;
  oAviso.Properties.WordWrap := True;
  oAviso.Height := ScaleValue(44);
  oAviso.Caption := Format(SInfoPreciosTallaHereda,
    [FormatFloat(FORMATO_PRECIO, ACosteLinea),
     FormatFloat(FORMATO_PRECIO, APvpLinea)]);
  if FCalculoPvp.Coeficiente > 0 then
    oAviso.Caption := oAviso.Caption + ' ' +
      Format(SInfoPreciosTallaCoeficiente,
        [FormatFloat(FORMATO_PRECIO, FCalculoPvp.Coeficiente)]);
end;

function TituloColumna(AColumna: Integer): string;
begin
  case AColumna of
    COLUMNA_COLOR:
      Result := SColumnaColorPreciosTalla;
    COLUMNA_TALLA:
      Result := SColumnaTallaPreciosTalla;
    COLUMNA_COSTE:
      Result := SColumnaCostePreciosTalla;
  else
    Result := SColumnaPvpPreciosTalla;
  end;
end;

procedure TfrmModalPreciosTallaSesion.CrearRejilla;
var
  oRejilla: TcxGrid;
  oColumna: TcxGridColumn;
  iColumna: Integer;
  iCelda: Integer;
begin
  oRejilla := TcxGrid.Create(Self);
  oRejilla.Parent := pnlBody;
  oRejilla.Align := alClient;
  FVista := oRejilla.CreateView(TcxGridTableView) as TcxGridTableView;
  oRejilla.Levels.Add.GridView := FVista;
  FVista.OptionsView.GroupByBox := False;
  FVista.OptionsView.ColumnAutoWidth := True;
  FVista.OptionsData.Inserting := False;
  FVista.OptionsData.Deleting := False;
  FVista.OptionsBehavior.FocusCellOnTab := True;
  FVista.OptionsBehavior.GoToNextCellOnEnter := True;
  for iColumna := COLUMNA_COLOR to COLUMNA_PVP do
  begin
    oColumna := FVista.CreateColumn;
    oColumna.Caption := TituloColumna(iColumna);
    if iColumna < COLUMNA_COSTE then
    begin
      // Color y talla solo identifican la celda.
      oColumna.DataBinding.ValueTypeClass := TcxStringValueType;
      oColumna.Options.Editing := False;
    end
    else
    begin
      oColumna.DataBinding.ValueTypeClass := TcxFloatValueType;
      oColumna.PropertiesClass := TcxCurrencyEditProperties;
      TcxCurrencyEditProperties(oColumna.Properties).DisplayFormat :=
        FORMATO_PRECIO;
      TcxCurrencyEditProperties(oColumna.Properties).DecimalPlaces := 6;
    end;
  end;
  FVista.DataController.RecordCount := Length(FPrecios);
  for iCelda := 0 to High(FPrecios) do
  begin
    FVista.DataController.Values[iCelda, COLUMNA_COLOR] :=
      FPrecios[iCelda].Color;
    FVista.DataController.Values[iCelda, COLUMNA_TALLA] :=
      FPrecios[iCelda].Talla;
    // Sin precio propio, la talla parte del precio de la línea. El PVP
    // copiado cuenta como propuesto: se recalcula al cambiar el coste.
    if FPrecios[iCelda].TieneCoste then
      FVista.DataController.Values[iCelda, COLUMNA_COSTE] :=
        FPrecios[iCelda].Coste
    else if FCosteLinea <> 0 then
      FVista.DataController.Values[iCelda, COLUMNA_COSTE] := FCosteLinea;
    if FPrecios[iCelda].TienePvp then
      FVista.DataController.Values[iCelda, COLUMNA_PVP] :=
        FPrecios[iCelda].Pvp
    else if FPvpLinea <> 0 then
    begin
      FVista.DataController.Values[iCelda, COLUMNA_PVP] := FPvpLinea;
      FPvpPropuesto[iCelda] := FPvpLinea;
    end;
  end;
  FVista.DataController.OnRecordChanged := CeldaCambiada;
end;

procedure TfrmModalPreciosTallaSesion.CeldaCambiada(
  ADataController: TcxCustomDataController; ARecordIndex,
  AItemIndex: Integer);
var
  vPvp: Variant;
begin
  if FProponiendo or (ARecordIndex < 0) or
     (ARecordIndex > High(FPvpPropuesto)) then
    Exit;
  if AItemIndex = COLUMNA_COSTE then
    ProponerPvp(ARecordIndex)
  else if AItemIndex = COLUMNA_PVP then
  begin
    // Un PVP tecleado deja de ser propuesto y ya no se recalcula.
    vPvp := ADataController.Values[ARecordIndex, COLUMNA_PVP];
    if VarIsNull(FPvpPropuesto[ARecordIndex]) or VarIsNull(vPvp) or
       VarIsEmpty(vPvp) or
       not SameValue(Double(vPvp), Double(FPvpPropuesto[ARecordIndex])) then
      FPvpPropuesto[ARecordIndex] := Null;
  end;
end;

// Como la línea (TBuscadorModeloProveedorSesion.ProponerPrecioVenta): el
// PVP de la talla se calcula con su coste. Solo se rellena una celda vacía
// o que conserva el PVP propuesto antes; el PVP tecleado se respeta.
procedure TfrmModalPreciosTallaSesion.ProponerPvp(ACelda: Integer);
var
  vCoste: Variant;
  vPvp: Variant;
  rPvp: Double;
begin
  vPvp := FVista.DataController.Values[ACelda, COLUMNA_PVP];
  if not (VarIsNull(vPvp) or VarIsEmpty(vPvp) or
          not VarIsNull(FPvpPropuesto[ACelda])) then
    Exit;
  vCoste := FVista.DataController.Values[ACelda, COLUMNA_COSTE];
  rPvp := 0;
  if not (VarIsNull(vCoste) or VarIsEmpty(vCoste)) and
     (FCalculoPvp.Coeficiente > 0) then
    rPvp := CalcularPrecioVenta(vCoste, FCalculoPvp.Coeficiente,
      FCalculoPvp.MultiploRedondeo, FCalculoPvp.AjusteFinal);
  FProponiendo := True;
  try
    if rPvp > 0 then
    begin
      FVista.DataController.Values[ACelda, COLUMNA_PVP] := rPvp;
      FPvpPropuesto[ACelda] := rPvp;
    end
    else if not VarIsNull(FPvpPropuesto[ACelda]) then
    begin
      // Sin PVP calculado vuelve al PVP de la línea.
      if FPvpLinea <> 0 then
      begin
        FVista.DataController.Values[ACelda, COLUMNA_PVP] := FPvpLinea;
        FPvpPropuesto[ACelda] := FPvpLinea;
      end
      else
      begin
        FVista.DataController.Values[ACelda, COLUMNA_PVP] := Null;
        FPvpPropuesto[ACelda] := Null;
      end;
    end;
  finally
    FProponiendo := False;
  end;
end;

// La celda vacía o con el mismo precio que la línea lo hereda: si después
// cambia el precio de la línea, la talla lo sigue.
function TfrmModalPreciosTallaSesion.PrecioPropio(const AValor: Variant;
  APrecioLinea: Double): Boolean;
begin
  Result := not VarIsNull(AValor) and not VarIsEmpty(AValor) and
    not SameValue(Double(AValor), APrecioLinea, 0.00005);
end;

procedure TfrmModalPreciosTallaSesion.Recoger;
var
  iCelda: Integer;
  vCoste: Variant;
  vPvp: Variant;
begin
  FVista.DataController.PostEditingData;
  for iCelda := 0 to High(FPrecios) do
  begin
    vCoste := FVista.DataController.Values[iCelda, COLUMNA_COSTE];
    vPvp := FVista.DataController.Values[iCelda, COLUMNA_PVP];
    FPrecios[iCelda].TieneCoste := PrecioPropio(vCoste, FCosteLinea);
    FPrecios[iCelda].Coste := 0;
    if FPrecios[iCelda].TieneCoste then
      FPrecios[iCelda].Coste := vCoste;
    FPrecios[iCelda].TienePvp := PrecioPropio(vPvp, FPvpLinea);
    FPrecios[iCelda].Pvp := 0;
    if FPrecios[iCelda].TienePvp then
      FPrecios[iCelda].Pvp := vPvp;
  end;
end;

function TfrmModalPreciosTallaSesion.CloseQuery: Boolean;
var
  sError: string;
begin
  Result := inherited CloseQuery;
  if Result and (sFicha = 'S') and not FGuardada then
  begin
    Result := False;
    try
      Recoger;
      sError := ValidarPreciosCeldasSesion(FPrecios);
      if sError <> '' then
        raise Exception.Create(sError);
      GrabarPreciosCeldasLinea(FConexion, FSerie, FNumero, FLinea,
        FPrecios, FUsuario);
      FGuardada := True;
      Result := True;
    except
      on E: Exception do
        ShowMessage_fza(E.Message);
    end;
    if not Result then
      sFicha := 'N';
  end;
end;

procedure TfrmModalPreciosTallaSesion.CerrarSinLiberar(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caHide;
end;

class function TfrmModalPreciosTallaSesion.Editar(AOwner: TComponent;
  AConexion: TUniConnection; const ASerie, ANumero: string;
  ALinea: Integer; ACosteLinea, APvpLinea: Double;
  const ACalculoPvp: TCalculoPvpSesion; const AUsuario: string;
  APosicion: Integer): Boolean;
var
  oPrecios: TPreciosCeldasSesion;
  oFormulario: TfrmModalPreciosTallaSesion;
begin
  Result := False;
  oPrecios := LeerPreciosCeldasLinea(AConexion, ASerie, ANumero, ALinea);
  if Length(oPrecios) = 0 then
    ShowMessage_fza(SErrorPreciosTallaSinCeldas)
  else
  begin
    oFormulario := TfrmModalPreciosTallaSesion.CreatePrecios(AOwner,
      AConexion, ASerie, ANumero, ALinea, oPrecios, ACosteLinea, APvpLinea,
      ACalculoPvp, AUsuario);
    if APosicion > 0 then
      oFormulario.Caption := Format(STituloPreciosTallaSesion, [APosicion]);
    try
      oFormulario.ShowModal;
      Result := oFormulario.FGuardada;
    finally
      FreeAndNil(oFormulario);
    end;
  end;
end;

end.
