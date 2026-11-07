{******************************************************************************}
{                                                                              }
{  Módulo: inLibBalanceResumenInforme                                          }
{    Tipo: Informe de gestión                                                  }
{   Fecha: 07/11/2026                                                          }
{   Autor: Alejandro Laorden Hidalgo                                           }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{                                                                              }
{******************************************************************************}
unit inLibBalanceResumenInforme;

interface

uses
  Data.DB, Datasnap.DBClient, inLibBalanceCantidades, inLibInformeTabular;

procedure CargarResumenBalance(AOrigen: TDataSet; ADestino: TClientDataSet;
  const AUnidad: TUnidadArticuloBalance);
function ColumnasResumenBalance: TColumnasInformeTabular;

implementation

uses
  inLibMsgInformesCliente,
  System.SysUtils, System.Classes, System.Generics.Collections;

type
  TTotalResumenBalance = record
    Descripcion: string;
    Cantidades: array[0..3] of Double;
    Importes: array[0..3] of Currency;
    Compatibilidad: TCompatibilidadCantidadBalance;
    Pendiente: Double;
    CosteSalidas: Currency;
    TieneComplementos: Boolean;
  end;

const
  BANDAS: array[0..3] of string = ('EXIINI', 'ENT', 'VEN', 'EXIFIN');
  CAMPOS_CANTIDAD: array[0..3] of string =
    ('INI_UDS', 'ENT_UDS', 'VEN_UDS', 'FIN_UDS');
  CAMPOS_IMPORTE: array[0..3] of string =
    ('INI_IMP', 'ENT_IMP', 'VEN_IMP', 'FIN_IMP');

function ColumnasResumenBalance: TColumnasInformeTabular;
begin
  Result := [
    ColumnaInforme('GRUPO', SInformeAgrupacionTotal, 3.7),
    ColumnaInforme('INI_UDS', SInformeInicialUnidades, 0.8, '%g'),
    ColumnaInforme('INI_IMP', SInformeInicialImporte, 1.1, '%2.2n'),
    ColumnaInforme('PTE_RECIBIR', SInformePendienteRecibir, 0.9, '%g'),
    ColumnaInforme('ENT_UDS', SInformeEntradasUnidades, 0.8, '%g'),
    ColumnaInforme('ENT_IMP', SInformeEntradasImporte, 1.1, '%2.2n'),
    ColumnaInforme('VEN_UDS', SInformeVentasUnidades, 0.8, '%g'),
    ColumnaInforme('VEN_IMP', SInformeVentasImporte, 1.1, '%2.2n'),
    ColumnaInforme('COSTE_SALIDAS', SInformeCosteSalidas, 1.1, '%2.2n'),
    ColumnaInforme('RESULTADO', SInformeResultado, 1.1, '%2.2n'),
    ColumnaInforme('FIN_UDS', SInformeFinalUnidades, 0.8, '%g'),
    ColumnaInforme('FIN_MEDIO', SInformeFinalPrecio, 1.1, '%2.2n'),
    ColumnaInforme('FIN_IMP', SInformeFinalImporte, 1.1, '%2.2n')];
end;

procedure CrearCamposResumen(ADatos: TClientDataSet);
var
  oColumna: TColumnaInformeTabular;
begin
  ADatos.Close;
  ADatos.FieldDefs.Clear;
  for oColumna in ColumnasResumenBalance do
    if oColumna.Numerica then
      ADatos.FieldDefs.Add(oColumna.Campo, ftFloat)
    else
      ADatos.FieldDefs.Add(oColumna.Campo, ftString, 500);
  ADatos.CreateDataSet;
end;

procedure AcumularResumen(AOrigen: TDataSet;
  AGrupos: TDictionary<string, TTotalResumenBalance>;
  const AUnidad: string; ABanda: Integer);
var
  i: Integer;
  sClave, sDescripcion, sCodigo, sEtiqueta: string;
  oTotal: TTotalResumenBalance;
begin
  sClave := '';
  sDescripcion := SInformeTotalGeneral;
  sCodigo := '';
  sEtiqueta := '';
  for i := 0 to 3 do
  begin
    if i > 0 then
    begin
      sCodigo := AOrigen.FieldByName(
        Format('GRUPO%d_COD', [i])).AsString;
      sEtiqueta := AOrigen.FieldByName(
        Format('GRUPO%d_ETIQ', [i])).AsString;
      if sEtiqueta <> '' then
      begin
        sClave := sClave + IntToStr(i) + ':' +
          IntToStr(Length(sCodigo)) + ':' + sCodigo;
        if i = 1 then
          sDescripcion := '';
        if sDescripcion <> '' then
          sDescripcion := sDescripcion + ' / ';
        sDescripcion := sDescripcion + Trim(sCodigo + ' ' + sEtiqueta);
      end;
    end;
    if (i = 0) or (sEtiqueta <> '') then
    begin
      if not AGrupos.TryGetValue(sClave, oTotal) then
        oTotal := Default(TTotalResumenBalance);
      oTotal.Descripcion := sDescripcion;
      if ABanda >= 0 then
      begin
        oTotal.Cantidades[ABanda] := oTotal.Cantidades[ABanda] +
          AOrigen.FieldByName('CANTIDAD').AsFloat;
        oTotal.Importes[ABanda] := oTotal.Importes[ABanda] +
          AOrigen.FieldByName('IMPORTE').AsCurrency;
      end;
      if AOrigen.FindField('PTE_RECIBIR_RESUMEN') <> nil then
      begin
        oTotal.TieneComplementos := True;
        oTotal.Pendiente := oTotal.Pendiente +
          AOrigen.FieldByName('PTE_RECIBIR_RESUMEN').AsFloat;
        oTotal.CosteSalidas := oTotal.CosteSalidas +
          AOrigen.FieldByName('COSTE_SALIDAS_RESUMEN').AsCurrency;
      end;
      oTotal.Compatibilidad.Agregar(AUnidad);
      AGrupos.AddOrSetValue(sClave, oTotal);
    end;
  end;
end;

procedure AnadirTotalResumen(ADatos: TDataSet;
  const ATotal: TTotalResumenBalance);
var
  i: Integer;
begin
  ADatos.Append;
  ADatos.FieldByName('GRUPO').AsString := ATotal.Descripcion;
  for i := 0 to 3 do
  begin
    if ATotal.Compatibilidad.Sumable then
      ADatos.FieldByName(CAMPOS_CANTIDAD[i]).AsFloat :=
        ATotal.Cantidades[i];
    ADatos.FieldByName(CAMPOS_IMPORTE[i]).AsCurrency := ATotal.Importes[i];
  end;
  if ATotal.Compatibilidad.Sumable and (ATotal.Cantidades[3] <> 0) then
    ADatos.FieldByName('FIN_MEDIO').AsCurrency :=
      ATotal.Importes[3] / ATotal.Cantidades[3];
  if ATotal.TieneComplementos then
  begin
    if ATotal.Compatibilidad.Sumable then
      ADatos.FieldByName('PTE_RECIBIR').AsFloat := ATotal.Pendiente;
    ADatos.FieldByName('COSTE_SALIDAS').AsCurrency := ATotal.CosteSalidas;
    ADatos.FieldByName('RESULTADO').AsCurrency :=
      ATotal.Importes[2] - ATotal.CosteSalidas;
  end;
  ADatos.Post;
end;

procedure CargarResumenBalance(AOrigen: TDataSet; ADestino: TClientDataSet;
  const AUnidad: TUnidadArticuloBalance);
var
  oGrupos: TDictionary<string, TTotalResumenBalance>;
  oClaves, oAvisos: TStringList;
  sClave, sBanda: string;
  oMarca: TBookmark;
  i: Integer;
begin
  CrearCamposResumen(ADestino);
  oGrupos := TDictionary<string, TTotalResumenBalance>.Create;
  oClaves := TStringList.Create;
  oAvisos := TStringList.Create;
  oAvisos.Sorted := True;
  oAvisos.Duplicates := dupIgnore;
  oMarca := AOrigen.Bookmark;
  AOrigen.DisableControls;
  try
    AOrigen.First;
    while not AOrigen.Eof do
    begin
      sBanda := AOrigen.FieldByName('BANDA').AsString;
      for i := 0 to 3 do
        if sBanda = BANDAS[i] then
          AcumularResumen(AOrigen, oGrupos,
            AUnidad(AOrigen.FieldByName('CODIGO_ART_ART').AsString), i);
      if sBanda = 'COMPLEMENTO' then
        AcumularResumen(AOrigen, oGrupos,
          AUnidad(AOrigen.FieldByName('CODIGO_ART_ART').AsString), -1);
      if (sBanda = 'AVIFAC') or (sBanda = 'SINMOV') then
        oAvisos.Add(SInformeAviso +
          AOrigen.FieldByName('ETIQUETA_BANDA').AsString);
      AOrigen.Next;
    end;
    for sClave in oGrupos.Keys do
      if sClave <> '' then
        oClaves.Add(sClave);
    oClaves.Sort;
    for sClave in oClaves do
      AnadirTotalResumen(ADestino, oGrupos[sClave]);
    if oGrupos.ContainsKey('') then
      AnadirTotalResumen(ADestino, oGrupos['']);
    for sClave in oAvisos do
    begin
      ADestino.Append;
      ADestino.FieldByName('GRUPO').AsString := sClave;
      ADestino.Post;
    end;
    ADestino.First;
  finally
    if AOrigen.BookmarkValid(oMarca) then
      AOrigen.Bookmark := oMarca;
    AOrigen.EnableControls;
    oAvisos.Free;
    oClaves.Free;
    oGrupos.Free;
  end;
end;

end.
