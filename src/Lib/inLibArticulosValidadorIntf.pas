{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArticulosValidadorIntf                                   }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contrato de validación y resolución de entradas de artículo.              }
{******************************************************************************}
unit inLibArticulosValidadorIntf;

interface

type
  TArtTipoCoincidencia = (
    atcDesconocido,
    atcCodigoArt,
    atcCodigoSku,
    atcCodigoBarras,
    atcRefProveedor,
    // F-LOTEC: código por unidad o lote (fza_codigos_barras.LOTE_CB) o
    // serie del catálogo leída tal cual.
    atcSerie,
    atcLote
  );

  TArtResolucionEntrada = record
    EntradaOriginal: string;
    Tipo: TArtTipoCoincidencia;
    Encontrado: Boolean;
    NumCoincidencias: Integer;
    CodigoArticulo: string;
    CodigoSku: string;
    DescripcionArticulo: string;
    TipoArticulo: string;
    EsActivoArticulo: Boolean;
    EsVariacion: Boolean;
    TieneSku: Boolean;
    NumAtributosReq: Integer;
    RequiereSku: Boolean;
    SkuActivo: Boolean;
    CodigoBarrasMatch: string;
    RefProveedorMatch: string;
    CodigoProveedorMatch: string;
    // F-LOTEC: lote, serie y caducidad que trae la propia lectura (código
    // por unidad o lote, o GS1 con IA 10 / 21 / 17). Vacíos si no trae.
    Lote: string;
    Serie: string;
    FechaCaducidad: TDate;
    // La lectura era un GS1-128 / DataMatrix y se ha resuelto por su GTIN.
    EsGs1: Boolean;
    Mensaje: string;
    procedure Clear;
    function ToReadable: string;
    // La lectura trae su propio lote o serie (IMEI, GS1 con IA 10 / 21).
    function TraeLote: Boolean;
  end;

  // FZ-ISSUE-341: lectura resuelta que trae lote o serie, para el documento
  // que los guarda en la línea (inventarios). ACodigoUnidad es la unidad
  // escrita en la línea (el SKU o, sin SKU, el propio artículo).
  TArtLoteLeidoEvent = procedure(const ACodigoArticulo, ACodigoUnidad: string;
    const AResolucion: TArtResolucionEntrada) of object;

  IArticulosValidador = interface
    ['{4507912B-3135-4EC7-B073-39B28233664D}']
    function Resolver(
      const AEntrada: string): TArtResolucionEntrada;
    function ResolverCodigoBarras(
      const AEntrada: string): TArtResolucionEntrada;
    function ResolverConSku(
      const AEntrada, ACodigoSkuPreferido: string):
      TArtResolucionEntrada;
    function EsValido(const AEntrada: string): Boolean;
    function TieneSkuActivo(
      const ACodigoArticulo: string): Boolean;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils;

const
  TIPOS_LEGIBLES: array[TArtTipoCoincidencia] of string = (
    'Desconocido',
    'CodigoArt',
    'CodigoSku',
    'CodigoBarras',
    'RefProveedor',
    'Serie',
    'Lote'
  );

function TArtResolucionEntrada.TraeLote: Boolean;
begin
  Result := (Trim(Lote) <> '') or (Trim(Serie) <> '');
end;

procedure TArtResolucionEntrada.Clear;
begin
  EntradaOriginal := '';
  Tipo := atcDesconocido;
  Encontrado := False;
  NumCoincidencias := 0;
  CodigoArticulo := '';
  CodigoSku := '';
  DescripcionArticulo := '';
  TipoArticulo := '';
  EsActivoArticulo := False;
  EsVariacion := False;
  TieneSku := False;
  NumAtributosReq := 0;
  RequiereSku := False;
  SkuActivo := False;
  CodigoBarrasMatch := '';
  RefProveedorMatch := '';
  CodigoProveedorMatch := '';
  Lote := '';
  Serie := '';
  FechaCaducidad := 0;
  EsGs1 := False;
  Mensaje := '';
end;

function TArtResolucionEntrada.ToReadable: string;
begin
  if Encontrado then
    Result := Format(
      '[%s "%s" → ART=%s SKU=%s%s]',
      [
        TIPOS_LEGIBLES[Tipo],
        EntradaOriginal,
        CodigoArticulo,
        CodigoSku,
        IfThen(RequiereSku, ' (requiere SKU)', '')
      ])
  else
    Result := '[no encontrado: "' + EntradaOriginal + '"]';
end;

end.
