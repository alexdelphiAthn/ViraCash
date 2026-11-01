{******************************************************************************}
{  Módulo: inLibReparacionesCircuito                                           }
{  Tipo: Librería. Fecha: 01/11/2026. Versión: 1.0.0                           }
{  Autor: Alejandro Laorden Hidalgo. SPDX-License-Identifier: MPL-2.0          }
{  Descripción: Cobertura por conceptos y validación de tiempos y consumos.    }
{******************************************************************************}
unit inLibReparacionesCircuito;

interface

type
  TAcuerdoOrden = record
    Referencia, Autorizacion: string;
    PorcentajeManoObra, PorcentajeMaterial: Currency;
    Limite: Currency;
    TieneLimite, Autorizado, ClienteAcepta: Boolean;
    Franquicia: Currency;
    Revision: Integer;
  end;

  TConceptoOrden = record
    Linea: Int64;
    EsMaterial: Boolean;
    Total, Taller: Currency;
    CoberturaPropia: Boolean;
    Porcentaje, Limite: Currency;
    TieneLimite, ClienteAcepta: Boolean;
  end;

  TRepartoConceptoOrden = record
    Linea: Int64;
    Cliente, Aseguradora, Taller, Pendiente: Currency;
  end;

  TParteTiempoOrden = record
    Id, Linea: Int64;
    Operario, Tarea, Motivo: string;
    Inicio, Fin: TDateTime;
  end;

  TDetalleConceptoOrden = record
    Concepto: TConceptoOrden;
    HorasPrevistas, HorasFacturables: Double;
    PorHoras: Boolean;
    Revision: Integer;
  end;

  TMaterialOrden = record
    Linea: Int64;
    Procedencia, Unidad, Referencia: string;
    Previsto, Utilizado, Devuelto: Double;
    Revision: Integer;
  end;

function RepartirConceptosOrden(const AAcuerdo: TAcuerdoOrden;
  const AConceptos: TArray<TConceptoOrden>): TArray<TRepartoConceptoOrden>;
procedure ValidarAcuerdoOrden(const AAcuerdo: TAcuerdoOrden);
procedure ValidarTiempoOrden(const AParte: TParteTiempoOrden);
procedure ValidarMaterialOrden(const AMaterial: TMaterialOrden);

implementation

uses
  System.SysUtils, System.Math, inLibMsgReparacionesCircuito;

function Centimos(AImporte: Currency): Currency;
begin
  Result := SimpleRoundTo(AImporte, -2);
end;

procedure ValidarAcuerdoOrden(const AAcuerdo: TAcuerdoOrden);
begin
  if (AAcuerdo.PorcentajeManoObra < 0) or
     (AAcuerdo.PorcentajeManoObra > 100) or
     (AAcuerdo.PorcentajeMaterial < 0) or
     (AAcuerdo.PorcentajeMaterial > 100) or
     (AAcuerdo.Limite < 0) or (AAcuerdo.Franquicia < 0) then
    raise EArgumentException.Create(SCircuitoAcuerdoInvalido);
  if AAcuerdo.Autorizado and (Trim(AAcuerdo.Autorizacion) = '') then
    raise EArgumentException.Create(SCircuitoFaltaAutorizacion);
end;

function CoberturaConcepto(const AAcuerdo: TAcuerdoOrden;
  const AConcepto: TConceptoOrden): Currency;
var
  dPorcentaje: Currency;
begin
  dPorcentaje := AAcuerdo.PorcentajeManoObra;
  if AConcepto.EsMaterial then
    dPorcentaje := AAcuerdo.PorcentajeMaterial;
  if AConcepto.CoberturaPropia then
    dPorcentaje := AConcepto.Porcentaje;
  if (AConcepto.Total < 0) or (AConcepto.Taller < 0) or
     (AConcepto.Taller > AConcepto.Total) or (dPorcentaje < 0) or
     (dPorcentaje > 100) or (AConcepto.Limite < 0) then
    raise EArgumentException.Create(SCircuitoRepartoInvalido);
  Result := Centimos((Centimos(AConcepto.Total) -
    Centimos(AConcepto.Taller)) * dPorcentaje / 100);
  if AConcepto.TieneLimite then
    Result := Min(Result, Centimos(AConcepto.Limite));
end;

function RepartirConceptosOrden(const AAcuerdo: TAcuerdoOrden;
  const AConceptos: TArray<TConceptoOrden>): TArray<TRepartoConceptoOrden>;
var
  i: Integer;
  dLimite, dFranquicia, dCubierto, dResto, dDescuento: Currency;
begin
  ValidarAcuerdoOrden(AAcuerdo);
  SetLength(Result, Length(AConceptos));
  dLimite := Centimos(AAcuerdo.Limite);
  dFranquicia := Centimos(AAcuerdo.Franquicia);
  for i := 0 to High(AConceptos) do
  begin
    Result[i] := Default(TRepartoConceptoOrden);
    Result[i].Linea := AConceptos[i].Linea;
    Result[i].Taller := Centimos(AConceptos[i].Taller);
    dCubierto := CoberturaConcepto(AAcuerdo, AConceptos[i]);
    if AAcuerdo.TieneLimite then
    begin
      dCubierto := Min(dCubierto, dLimite);
      dLimite := dLimite - dCubierto;
    end;
    // La franquicia se consume una sola vez sobre la cobertura bruta.
    dDescuento := Min(dCubierto, dFranquicia);
    dFranquicia := dFranquicia - dDescuento;
    dCubierto := dCubierto - dDescuento;
    if AAcuerdo.Autorizado then
      Result[i].Aseguradora := dCubierto
    else
      Result[i].Pendiente := dCubierto;
    dResto := Centimos(AConceptos[i].Total) - Result[i].Taller - dCubierto;
    if AAcuerdo.ClienteAcepta or AConceptos[i].ClienteAcepta then
      Result[i].Cliente := dResto
    else
      Result[i].Pendiente := Result[i].Pendiente + dResto;
  end;
end;

procedure ValidarTiempoOrden(const AParte: TParteTiempoOrden);
begin
  if (AParte.Linea <= 0) or (Trim(AParte.Operario) = '') or
     (Trim(AParte.Tarea) = '') or (AParte.Inicio <= 0) or
     ((AParte.Fin > 0) and (AParte.Fin <= AParte.Inicio)) or
     (AParte.Inicio > Now) or (AParte.Fin > Now) then
    raise EArgumentException.Create(SCircuitoTiempoInvalido);
  if (AParte.Id > 0) and (Trim(AParte.Motivo) = '') then
    raise EArgumentException.Create(SCircuitoMotivoCorreccion);
end;

procedure ValidarMaterialOrden(const AMaterial: TMaterialOrden);
begin
  if (AMaterial.Linea <= 0) or (AMaterial.Previsto < 0) or
     (AMaterial.Utilizado < 0) or
     (AMaterial.Devuelto < 0) or
     (Trim(AMaterial.Unidad) = '') then
    raise EArgumentException.Create(SCircuitoMaterialInvalido);
  if AMaterial.Devuelto > AMaterial.Utilizado then
    raise EArgumentException.Create(SCircuitoDevueltoSupera);
  if (AMaterial.Procedencia <> 'ALMACEN') and
     (AMaterial.Procedencia <> 'COMPRA') and
     (AMaterial.Procedencia <> 'CLIENTE') and
     (AMaterial.Procedencia <> 'EXTERNO') then
    raise EArgumentException.Create(SCircuitoMaterialInvalido);

end;

end.
