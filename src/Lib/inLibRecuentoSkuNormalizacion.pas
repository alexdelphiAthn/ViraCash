{******************************************************************************}
{                                                                              }
{  Módulo:       inLibRecuentoSkuNormalizacion                                 }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       08/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Lecturas del móvil que no son un SKU (FZ-ISSUE-351): los EAN se          }
{    traducen a su SKU y lo que no se puede asignar se aparta. Lo usan el      }
{    recuento de inventarios y los traspasos hechos con la app.                }
{******************************************************************************}
unit inLibRecuentoSkuNormalizacion;

interface

uses
  System.Classes;

type
  // Consultas que necesita la normalización; la implementación UniDAC está
  // en UniDataResolutorSkuRecuento.
  IResolutorSkuRecuento = interface
    ['{6E0C2B7D-4F53-4C11-9A55-2D7F3B8E91A4}']
    function SkuExiste(const ASku: string): Boolean;
    // SKU del código de barras; vacío si no está asignado.
    function SkuDeCodigoBarras(const ACodigo: string): string;
  end;

// ALista: «SKU=valor» (ver inLibInventarioRecuentoLote). Las entradas que
// no son un SKU pasan a su SKU por código de barras; las que no se pueden
// asignar se quitan y se anotan en ANoAsignados como «CÓDIGO (valor)».
// AInstantesRecuento (opcional) hereda el instante del código leído.
procedure NormalizarSkusRecuentoMovil(
  const AResolutor: IResolutorSkuRecuento;
  ALista: TStringList;
  AInstantesRecuento: TStrings;
  ANoAsignados: TStrings);

implementation

uses
  System.SysUtils,
  inLibInventarioNube,
  inLibInventarioRecuentoLote;

// Mismo SKU leído por código y por EAN, ambos sin lote: se suman.
function SumarSinLote(
  ALista: TStringList;
  AOrigen, ADestino: Integer): Boolean;
var
  ValorOrigen: TValorRecuentoLote;
  ValorDestino: TValorRecuentoLote;
begin
  ValorOrigen := LeerValorRecuentoLote(ALista.ValueFromIndex[AOrigen]);
  ValorDestino := LeerValorRecuentoLote(ALista.ValueFromIndex[ADestino]);
  Result := ValorOrigen.TieneCantidad and ValorDestino.TieneCantidad and
    (ValorOrigen.Lote = '') and (ValorDestino.Lote = '');
  if Result then
    ALista.ValueFromIndex[ADestino] :=
      FloatToStr(ValorOrigen.Cantidad + ValorDestino.Cantidad);
end;

procedure NormalizarEntrada(
  const AResolutor: IResolutorSkuRecuento;
  ALista: TStringList;
  AIndice: Integer;
  AInstantesRecuento: TStrings;
  ANoAsignados: TStrings);
var
  iDestino: Integer;
  sSku: string;
  sSkuReal: string;
  sValor: string;
begin
  sSku := ObtenerSkuRecuento(ALista, AIndice);
  if (sSku <> '') and not AResolutor.SkuExiste(sSku) then
  begin
    sValor := ALista.ValueFromIndex[AIndice];
    sSkuReal := AResolutor.SkuDeCodigoBarras(sSku);
    if sSkuReal = '' then
    begin
      if Assigned(ANoAsignados) then
        ANoAsignados.Insert(0, sSku + ' (' + sValor + ')');
      ALista.Delete(AIndice);
    end
    else
    begin
      if Assigned(AInstantesRecuento) and
         (AInstantesRecuento.Values[sSkuReal] = '') then
        AInstantesRecuento.Values[sSkuReal] :=
          AInstantesRecuento.Values[sSku];
      iDestino := ALista.IndexOfName(sSkuReal);
      if (iDestino >= 0) and SumarSinLote(ALista, AIndice, iDestino) then
        ALista.Delete(AIndice)
      else
        ALista[AIndice] := sSkuReal + '=' + sValor;
    end;
  end;
end;

procedure NormalizarSkusRecuentoMovil(
  const AResolutor: IResolutorSkuRecuento;
  ALista: TStringList;
  AInstantesRecuento: TStrings;
  ANoAsignados: TStrings);
var
  i: Integer;
begin
  if not Assigned(AResolutor) then
    raise EArgumentNilException.Create('AResolutor');
  // Hacia atrás: se borran entradas de la lista mientras se recorre.
  for i := ALista.Count - 1 downto 0 do
    NormalizarEntrada(
      AResolutor, ALista, i, AInstantesRecuento, ANoAsignados);
end;

end.
