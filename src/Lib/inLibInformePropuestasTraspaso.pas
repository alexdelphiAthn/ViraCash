{******************************************************************************}
{                                                                              }
{  Módulo:       inLibInformePropuestasTraspaso                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       21/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Compone los datos del informe de propuestas de traspaso: una hoja por     }
{    propuesta (origen-destino) y una línea por artículo y color con sus       }
{    tallas desglosadas. Sin VCL ni acceso a datos.                            }
{******************************************************************************}
unit inLibInformePropuestasTraspaso;

interface

uses
  inLibDistribucionTiendasIntf;

type
  TLineaInformePropuestaTraspaso = record
    IdPropuesta: Int64;
    CodigoArticulo: string;
    DescripcionArticulo: string;
    Color: string;
    Tallas: string;
    Unidades: Double;
  end;

  THojaInformePropuestaTraspaso = record
    IdPropuesta: Int64;
    Numero: string;
    Origen: string;
    Destino: string;
    Documento: string;
    Estado: string;
    Instante: TDateTime;
    TotalUnidades: Double;
    Lineas: TArray<TLineaInformePropuestaTraspaso>;
  end;
  THojasInformePropuestasTraspaso = TArray<THojaInformePropuestaTraspaso>;

// Unidades que cuentan en el informe: lo realmente traspasado si ya se
// trasladó y lo propuesto en otro caso (pendiente o no aceptado).
function UnidadesInformeLineaPropuesta(
  const APropuesta: TPropuestaTraspaso;
  const ALinea: TLineaPropuestaTraspaso): Double;
function TextoEstadoPropuestaTraspaso(
  const APropuesta: TPropuestaTraspaso): string;
function TextoTraspasoPropuesta(
  const APropuesta: TPropuestaTraspaso): string;
function TextoAlmacenPropuesta(const ACodigo, ANombre: string): string;
function FormatearUnidadesPropuesta(AUnidades: Double): string;
function ComponerInformePropuestasTraspaso(
  const APropuestas: TPropuestasTraspaso): THojasInformePropuestasTraspaso;

implementation

uses
  System.SysUtils,
  inLibMsgDistribucionTiendas;

const
  TOLERANCIA_UNIDADES = 0.000001;
  SEPARADOR_TALLAS = '   ';

function FormatearUnidadesPropuesta(AUnidades: Double): string;
begin
  Result := FormatFloat('0.###', AUnidades);
end;

function UnidadesInformeLineaPropuesta(
  const APropuesta: TPropuestaTraspaso;
  const ALinea: TLineaPropuestaTraspaso): Double;
begin
  if APropuesta.EstaTrasladada or APropuesta.EstaTrasladadaParcial then
    Result := ALinea.CantidadTraspasada
  else
    Result := ALinea.Cantidad;
end;

function TextoEstadoPropuestaTraspaso(
  const APropuesta: TPropuestaTraspaso): string;
begin
  if APropuesta.EstaPendiente then
    Result := STextoEstadoPropuestaPendiente
  else if APropuesta.EstaTrasladada then
    Result := STextoEstadoPropuestaTrasladada
  else if APropuesta.EstaTrasladadaParcial then
    Result := STextoEstadoPropuestaTrasladadaParcial
  else
    Result := STextoEstadoPropuestaNoAceptada;
end;

function TextoTraspasoPropuesta(
  const APropuesta: TPropuestaTraspaso): string;
begin
  Result := '';
  if Trim(APropuesta.NumeroDocumento) <> '' then
    Result := Format(SFormatoTraspasoPropuesta, [
      APropuesta.TipoDocumento,
      APropuesta.SerieDocumento,
      APropuesta.NumeroDocumento]);
end;

function TextoAlmacenPropuesta(const ACodigo, ANombre: string): string;
begin
  if Trim(ANombre) = '' then
    Result := Trim(ACodigo)
  else
    Result := Format(SFormatoAlmacenDistribucion, [
      Trim(ACodigo), Trim(ANombre)]);
end;

function TextoTalla(const ATalla: string; AUnidades: Double): string;
begin
  if Trim(ATalla) = '' then
    Result := FormatearUnidadesPropuesta(AUnidades)
  else
    Result := Format(SFormatoTallaInformePropuesta, [
      Trim(ATalla), FormatearUnidadesPropuesta(AUnidades)]);
end;

// Las líneas de la propuesta ya vienen ordenadas por artículo, color y
// orden de talla: basta cortar cuando cambia el artículo o el color.
procedure ComponerLineasHoja(
  const APropuesta: TPropuestaTraspaso;
  var AHoja: THojaInformePropuestaTraspaso);
var
  i, iLinea: Integer;
  dUnidades: Double;
begin
  iLinea := -1;
  for i := 0 to High(APropuesta.Lineas) do
  begin
    dUnidades := UnidadesInformeLineaPropuesta(
      APropuesta, APropuesta.Lineas[i]);
    if dUnidades > TOLERANCIA_UNIDADES then
    begin
      if (iLinea < 0) or
         not SameText(AHoja.Lineas[iLinea].CodigoArticulo,
           APropuesta.Lineas[i].CodigoArticulo) or
         not SameText(AHoja.Lineas[iLinea].Color,
           APropuesta.Lineas[i].Color) then
      begin
        iLinea := Length(AHoja.Lineas);
        SetLength(AHoja.Lineas, iLinea + 1);
        AHoja.Lineas[iLinea].IdPropuesta := APropuesta.IdPropuesta;
        AHoja.Lineas[iLinea].CodigoArticulo :=
          APropuesta.Lineas[i].CodigoArticulo;
        AHoja.Lineas[iLinea].DescripcionArticulo :=
          APropuesta.Lineas[i].DescripcionArticulo;
        AHoja.Lineas[iLinea].Color := APropuesta.Lineas[i].Color;
      end;
      if AHoja.Lineas[iLinea].Tallas <> '' then
        AHoja.Lineas[iLinea].Tallas :=
          AHoja.Lineas[iLinea].Tallas + SEPARADOR_TALLAS;
      AHoja.Lineas[iLinea].Tallas := AHoja.Lineas[iLinea].Tallas +
        TextoTalla(APropuesta.Lineas[i].Talla, dUnidades);
      AHoja.Lineas[iLinea].Unidades :=
        AHoja.Lineas[iLinea].Unidades + dUnidades;
      AHoja.TotalUnidades := AHoja.TotalUnidades + dUnidades;
    end;
  end;
end;

// Una propuesta sin unidades no ocupa hoja.
function ComponerInformePropuestasTraspaso(
  const APropuestas: TPropuestasTraspaso): THojasInformePropuestasTraspaso;
var
  i, iHoja: Integer;
  Hoja: THojaInformePropuestaTraspaso;
begin
  SetLength(Result, 0);
  for i := 0 to High(APropuestas) do
  begin
    Hoja := Default(THojaInformePropuestaTraspaso);
    Hoja.IdPropuesta := APropuestas[i].IdPropuesta;
    Hoja.Numero := Format(
      SFormatoNumeroInformePropuesta, [APropuestas[i].IdPropuesta]);
    Hoja.Origen := Format(SFormatoOrigenInformePropuesta, [
      TextoAlmacenPropuesta(
        APropuestas[i].AlmacenOrigen,
        APropuestas[i].NombreAlmacenOrigen)]);
    Hoja.Destino := Format(SFormatoDestinoInformePropuesta, [
      TextoAlmacenPropuesta(
        APropuestas[i].AlmacenDestino,
        APropuestas[i].NombreAlmacenDestino)]);
    Hoja.Documento := Format(SFormatoDocumentoInformePropuesta, [
      APropuestas[i].IdDocumento, APropuestas[i].TituloDocumento]);
    Hoja.Estado := Format(SFormatoEstadoInformePropuesta, [
      Trim(TextoEstadoPropuestaTraspaso(APropuestas[i]) + ' ' +
        TextoTraspasoPropuesta(APropuestas[i]) + ' ' +
        Trim(APropuestas[i].MotivoRechazo))]);
    Hoja.Instante := APropuestas[i].Instante;
    ComponerLineasHoja(APropuestas[i], Hoja);
    if Length(Hoja.Lineas) > 0 then
    begin
      iHoja := Length(Result);
      SetLength(Result, iHoja + 1);
      Result[iHoja] := Hoja;
    end;
  end;
end;

end.
