{******************************************************************************}
{                                                                              }
{  Módulo:       inLibReparacionesPlantillas                                   }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Campos dinámicos y trabajos repetibles para el diseñador de informes.     }
{******************************************************************************}
unit inLibReparacionesPlantillas;

interface

uses
  System.Classes, System.Generics.Collections, frxClass,
  inLibGarantiasResguardo;

type
  TDatosPlantillaReparacion = class(TComponent)
  private
    FValores: TStringList;
    FVisibles: TDictionary<string, Boolean>;
    FCabecera: TfrxUserDataSet;
    FTrabajos: TfrxUserDataSet;
    FLineas: TArray<TTrabajoResguardo>;
    FTicket: Boolean;
    procedure ValorCabecera(const ACampo: string; var AValor: Variant);
    procedure ValorTrabajo(const ACampo: string; var AValor: Variant);
    procedure VincularMemo(AMemo: TfrxMemoView);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Preparar(AInforme: TfrxReport;
      const ADatos: TResguardoGarantia; ATipo: TDocumentoReparacion;
      AFormato: TFormatoResguardoGarantia);
    procedure Enlazar(AInforme: TfrxReport);
    procedure AntesImprimir(AComponente: TfrxReportComponent);
  end;

implementation

uses
  System.SysUtils, inLibMsgReparaciones;

constructor TDatosPlantillaReparacion.Create(AOwner: TComponent);
begin
  inherited;
  FValores := TStringList.Create;
  FVisibles := TDictionary<string, Boolean>.Create;
  FCabecera := TfrxUserDataSet.Create(Self);
  FCabecera.UserName := 'Reparacion';
  FCabecera.RangeEnd := reCount;
  FCabecera.RangeEndCount := 1;
  FCabecera.OnGetValue := ValorCabecera;
  FTrabajos := TfrxUserDataSet.Create(Self);
  FTrabajos.UserName := 'Trabajos';
  FTrabajos.Fields.Text := 'Descripcion'#13#10'Cantidad'#13#10'Importe';
  FTrabajos.RangeEnd := reCount;
  FTrabajos.OnGetValue := ValorTrabajo;
end;

destructor TDatosPlantillaReparacion.Destroy;
begin
  FVisibles.Free;
  FValores.Free;
  inherited;
end;

procedure TDatosPlantillaReparacion.ValorCabecera(const ACampo: string;
  var AValor: Variant);
begin
  AValor := FValores.Values[ACampo];
end;

procedure TDatosPlantillaReparacion.ValorTrabajo(const ACampo: string;
  var AValor: Variant);
var
  i: Integer;
  sTexto: string;
begin
  AValor := '';
  i := FTrabajos.RecNo;
  if (i >= 0) and (i < Length(FLineas)) then
  begin
    if ACampo = 'Descripcion' then
    begin
      sTexto := FLineas[i].Descripcion;
      if not FLineas[i].Terminado then
        sTexto := sTexto + ' (' + SImpresoPendiente + ')';
      AValor := sTexto;
    end
    else if ACampo = 'Cantidad' then
    begin
      sTexto := FormatFloat('0.###', FLineas[i].Cantidad);
      if FTicket then
        sTexto := Format(SImpresoCantidad, [sTexto]);
      AValor := sTexto;
    end
    else if ACampo = 'Importe' then
      AValor := FormatFloat('#,##0.00', FLineas[i].Importe);
  end;
end;

procedure TDatosPlantillaReparacion.VincularMemo(AMemo: TfrxMemoView);
const
  CAMPOS: array[0..2] of string = ('Descripcion', 'Cantidad', 'Importe');
var
  i: Integer;
begin
  if not AMemo.AllowExpressions and
     not string(AMemo.Name).EndsWith('_Espacio') then
  begin
    if string(AMemo.Name).StartsWith('Rep_Trabajo0000_Texto') then
    begin
      i := StrToInt(Copy(AMemo.Name, Length('Rep_Trabajo0000_Texto') + 1,
        MaxInt));
      AMemo.DataSet := FTrabajos;
      AMemo.DataField := CAMPOS[i];
    end
    else
    begin
      FValores.Values[AMemo.Name] := AMemo.Text;
      FCabecera.Fields.Add(AMemo.Name);
      AMemo.DataSet := FCabecera;
      AMemo.DataField := AMemo.Name;
    end;
    // La plantilla solo guarda el campo, nunca la identidad del cliente.
    AMemo.Text := '';
  end;
end;

procedure TDatosPlantillaReparacion.Preparar(AInforme: TfrxReport;
  const ADatos: TResguardoGarantia; ATipo: TDocumentoReparacion;
  AFormato: TFormatoResguardoGarantia);
var
  i: Integer;
  oObjeto: TfrxComponent;
  oBanda: TfrxMasterData;
begin
  FValores.Clear;
  FVisibles.Clear;
  FCabecera.Fields.Clear;
  FLineas := Copy(ADatos.Trabajos);
  FTicket := AFormato = frgTicket;
  FTrabajos.RangeEndCount := Length(FLineas);
  CrearInformeDocumentoReparacion(AInforme, ADatos, ATipo, AFormato);
  // Una única banda de detalle se repite tantas veces como trabajos haya.
  for i := AInforme.AllObjects.Count - 1 downto 0 do
  begin
    oObjeto := TfrxComponent(AInforme.AllObjects[i]);
    if (oObjeto is TfrxMasterData) and
       string(oObjeto.Name).StartsWith('Rep_Trabajo') and
       (oObjeto.Name <> 'Rep_Trabajo0000') then
      oObjeto.Free;
  end;
  for i := 0 to AInforme.AllObjects.Count - 1 do
  begin
    oObjeto := TfrxComponent(AInforme.AllObjects[i]);
    if oObjeto is TfrxMemoView then
      VincularMemo(TfrxMemoView(oObjeto));
    if oObjeto is TfrxMasterData then
    begin
      oBanda := TfrxMasterData(oObjeto);
      FVisibles.AddOrSetValue(oBanda.Name, oBanda.Visible);
      oBanda.Visible := True;
      if oBanda.Name = 'Rep_Trabajo0000' then
      begin
        oBanda.RowCount := 0;
        oBanda.DataSet := FTrabajos;
      end;
    end;
  end;
  Enlazar(AInforme);
end;

procedure TDatosPlantillaReparacion.Enlazar(AInforme: TfrxReport);
var
  i: Integer;
  oObjeto: TfrxComponent;
  oMemo: TfrxMemoView;
begin
  AInforme.EnabledDataSets.Clear;
  AInforme.EnabledDataSets.Add(FCabecera);
  AInforme.EnabledDataSets.Add(FTrabajos);
  AInforme.DataSets.Clear;
  AInforme.DataSets.Add(FCabecera);
  AInforme.DataSets.Add(FTrabajos);
  for i := 0 to AInforme.AllObjects.Count - 1 do
  begin
    oObjeto := TfrxComponent(AInforme.AllObjects[i]);
    if oObjeto is TfrxMemoView then
    begin
      oMemo := TfrxMemoView(oObjeto);
      if SameText(oMemo.DataSetName, 'Reparacion') then
        oMemo.DataSet := FCabecera
      else if SameText(oMemo.DataSetName, 'Trabajos') then
        oMemo.DataSet := FTrabajos;
    end;
    if (oObjeto is TfrxDataBand) and
       SameText(TfrxDataBand(oObjeto).DataSetName, 'Trabajos') then
      TfrxDataBand(oObjeto).DataSet := FTrabajos;
    if oObjeto is TfrxMasterData then
    begin
      TfrxMasterData(oObjeto).Stretched := True;
      if FVisibles.ContainsKey(oObjeto.Name) then
        TfrxMasterData(oObjeto).Visible := True;
    end;
  end;
end;

procedure TDatosPlantillaReparacion.AntesImprimir(
  AComponente: TfrxReportComponent);
var
  bVisible: Boolean;
begin
  if (AComponente is TfrxBand) and
     FVisibles.TryGetValue(AComponente.Name, bVisible) then
    TfrxBand(AComponente).Visible := bVisible;
end;

end.
