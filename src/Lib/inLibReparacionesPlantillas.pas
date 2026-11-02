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
  inLibGarantiasResguardo, inLibReparacionesDocumentos;

type
  TDatosPlantillaReparacion = class(TComponent)
  private
    FValores: TStringList;
    FVisibles: TDictionary<string, Boolean>;
    FCabecera: TfrxUserDataSet;
    FTrabajos: TfrxUserDataSet;
    FLineas: TArray<TTrabajoResguardo>;
    FTicket: Boolean;
    FEsHoja: Boolean;
    FHoja: THojaReparaciones;
    procedure ValorCabecera(const ACampo: string; var AValor: Variant);
    procedure ValorTrabajo(const ACampo: string; var AValor: Variant);
    procedure VincularMemo(AMemo: TfrxMemoView);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Preparar(AInforme: TfrxReport;
      const ADatos: TResguardoGarantia; ATipo: TDocumentoReparacion;
      AFormato: TFormatoResguardoGarantia);
    procedure PrepararHoja(AInforme: TfrxReport;
      const AHoja: THojaReparaciones; AFormato: TFormatoHojaReparacion);
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
  if FEsHoja and (i >= 0) and (i < Length(FHoja.Lineas)) then
  begin
    if ACampo = 'Referencia' then
    begin
      AValor := FHoja.Lineas[i].Referencia;
      if FHoja.Lineas[i].Referencia = '' then
        AValor := IntToStr(FHoja.Lineas[i].Reparacion);
    end
    else if ACampo = 'Fecha' then
    begin
      if FHoja.Lineas[i].Fecha > 0 then
        AValor := FormatDateTime('dd/mm/yyyy', FHoja.Lineas[i].Fecha);
    end
    else if ACampo = 'Trabajo' then
      AValor := FHoja.Lineas[i].Trabajo
    else if ACampo = 'Detalles' then
      AValor := DetalleLineaHoja(FHoja.Lineas[i])
    else if ACampo = 'Plazo' then
      AValor := PlazoLineaHoja(FHoja.Lineas[i])
    else if ACampo = 'Cantidad' then
      AValor := Format(SImpresoCantidad,
        [FormatFloat('0.###', FHoja.Lineas[i].Cantidad)])
    else if ACampo = 'Importe' then
      AValor := FormatFloat('#,##0.00', FHoja.Lineas[i].Importe);
  end;
  if not FEsHoja then
  begin
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
  FEsHoja := False;
  FTrabajos.Fields.Text := 'Descripcion'#13#10'Cantidad'#13#10'Importe';
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

procedure TDatosPlantillaReparacion.PrepararHoja(AInforme: TfrxReport;
  const AHoja: THojaReparaciones; AFormato: TFormatoHojaReparacion);
var
  rModelo: THojaReparaciones;
  oObjeto: TfrxComponent;
  oMemo: TfrxMemoView;
  i: Integer;
begin
  FEsHoja := True;
  FHoja := AHoja;
  FValores.Clear;
  FVisibles.Clear;
  FCabecera.Fields.Clear;
  FTrabajos.Fields.Text := 'Referencia'#13#10'Fecha'#13#10'Trabajo'#13#10 +
    'Detalles'#13#10'Plazo'#13#10'Cantidad'#13#10'Importe';
  FTrabajos.RangeEndCount := Length(AHoja.Lineas);
  rModelo := AHoja;
  if Length(AHoja.Lineas) = 0 then
  begin
    SetLength(rModelo.Lineas, 1);
    rModelo.Lineas[0] := Default(TLineaHojaReparacion);
  end;
  CrearInformeHojaReparaciones(AInforme, rModelo, AFormato);
  // El formato conserva una banda repetible y el resumen de todas las filas.
  for i := AInforme.AllObjects.Count - 1 downto 0 do
  begin
    oObjeto := TfrxComponent(AInforme.AllObjects[i]);
    if (oObjeto is TfrxMasterData) and
       string(oObjeto.Name).StartsWith('HojaLinea') and
       (oObjeto.Name <> 'HojaLinea0000') then
      oObjeto.Free;
  end;
  for i := 0 to AInforme.AllObjects.Count - 1 do
  begin
    oObjeto := TfrxComponent(AInforme.AllObjects[i]);
    if oObjeto is TfrxMemoView then
    begin
      oMemo := TfrxMemoView(oObjeto);
      if (Length(AHoja.Lineas) = 0) and
         (oMemo.Text = Format(SHojaReparacionesLineas, [1])) then
        oMemo.Text := Format(SHojaReparacionesLineas, [0]);
      if not oMemo.AllowExpressions then
      begin
        if string(oMemo.Name).StartsWith('HojaLinea0000_') and
           (FTrabajos.Fields.IndexOf(Copy(oMemo.Name, 15, MaxInt)) >= 0) then
        begin
          oMemo.DataSet := FTrabajos;
          oMemo.DataField := Copy(oMemo.Name, 15, MaxInt);
        end
        else
        begin
          FValores.Values[oMemo.Name] := oMemo.Text;
          FCabecera.Fields.Add(oMemo.Name);
          oMemo.DataSet := FCabecera;
          oMemo.DataField := oMemo.Name;
        end;
        oMemo.Text := '';
        oMemo.ShiftMode := smAlways;
      end;
    end;
    if oObjeto is TfrxMasterData then
    begin
      if oObjeto.Name = 'HojaLinea0000' then
      begin
        TfrxMasterData(oObjeto).RowCount := 0;
        TfrxMasterData(oObjeto).DataSet := FTrabajos;
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
