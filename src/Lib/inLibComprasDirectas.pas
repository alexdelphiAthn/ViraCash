{******************************************************************************}
{  Módulo:       inLibComprasDirectas                                          }
{    Tipo:       Librería                                                      }
{   Fecha:       26/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{******************************************************************************}
unit inLibComprasDirectas;

interface

type
  TModalidadCompraDirecta = (mcdOrdinaria, mcdAutofactura, mcdReagp);
  TClasificacionFiscalCompraDirecta = record
    TipoFacturaSii: string;
    RegimenSii: string;
    EmitidaPorDestinatario: string;
    EsFactura: Boolean;
    TextoLegal: string;
  end;

function CodigoModalidadCompra(AModalidad: TModalidadCompraDirecta): string;
function ModalidadCompra(const ACodigo: string): TModalidadCompraDirecta;
function ClasificarCompraDirecta(AModalidad: TModalidadCompraDirecta):
  TClasificacionFiscalCompraDirecta;
function SerieCompraDirectaDefecto(const AEmpresa, AProveedor: string;
  AModalidad: TModalidadCompraDirecta): string;
function CalcularCompensacionAgricola(ABase, APorcentaje: Currency): Currency;

implementation

uses
  System.SysUtils, System.Hash, inLibRedondeo;

resourcestring
  SModalidadCompraDesconocida = 'Modalidad de compra desconocida: %s.';
  SCompensacionAgricolaInvalida =
    'El porcentaje de compensación debe estar entre 0 y 100.';
  STextoAutofactura = 'Facturación por el destinatario';
  STextoReciboAgricola =
    'Recibo de compensación del régimen especial de agricultura, ' +
    'ganadería y pesca. Firma del proveedor: ____________________';

function CodigoModalidadCompra(AModalidad: TModalidadCompraDirecta): string;
begin
  case AModalidad of
    mcdAutofactura: Result := 'AUTOFAC';
    mcdReagp: Result := 'REAGP';
  else
    Result := 'ORDINARIA';
  end;
end;

function ModalidadCompra(const ACodigo: string): TModalidadCompraDirecta;
begin
  if SameText(Trim(ACodigo), 'AUTOFAC') then
    Result := mcdAutofactura
  else if SameText(Trim(ACodigo), 'REAGP') then
    Result := mcdReagp
  else if (Trim(ACodigo) = '') or SameText(Trim(ACodigo), 'ORDINARIA') then
    Result := mcdOrdinaria
  else
    raise EArgumentException.CreateFmt(SModalidadCompraDesconocida,
      [ACodigo]);
end;

function ClasificarCompraDirecta(AModalidad: TModalidadCompraDirecta):
  TClasificacionFiscalCompraDirecta;
begin
  Result := Default(TClasificacionFiscalCompraDirecta);
  Result.TipoFacturaSii := 'F1';
  Result.RegimenSii := '01';
  Result.EsFactura := True;
  if AModalidad = mcdAutofactura then
  begin
    Result.EmitidaPorDestinatario := 'D';
    Result.TextoLegal := STextoAutofactura;
  end
  else if AModalidad = mcdReagp then
  begin
    Result.TipoFacturaSii := 'F6';
    Result.RegimenSii := '02';
    Result.EsFactura := False;
    Result.TextoLegal := STextoReciboAgricola;
  end;
end;

function SerieCompraDirectaDefecto(const AEmpresa, AProveedor: string;
  AModalidad: TModalidadCompraDirecta): string;
begin
  Result := 'AD' + Copy(UpperCase(THashSHA2.GetHashString(
    AEmpresa + #0 + AProveedor)), 1, 10);
  if AModalidad = mcdReagp then
    Result := 'RA' + UpperCase(AEmpresa);
end;

function CalcularCompensacionAgricola(ABase, APorcentaje: Currency): Currency;
begin
  if (APorcentaje < 0) or (APorcentaje > 100) then
    raise EArgumentException.Create(SCompensacionAgricolaInvalida);
  Result := RedondearACentimos(ABase * APorcentaje / 100);
end;

end.
