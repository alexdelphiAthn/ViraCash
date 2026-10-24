{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataTraspasosPendientesConsulta                            }
{    Tipo:       Repositorio                                                   }
{ Version:       1.0.0                                                         }
{   Fecha:       05/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Lee vi_traspasos_pendientes (script 766) de un articulo, filtrado por     }
{    SKU y por almacen (origen o destino) si se indican (FZ-ISSUE-251).        }
{******************************************************************************}
unit UniDataTraspasosPendientesConsulta;

interface

uses
  Uni, inLibTraspasosPendientesTexto;

function SqlTraspasosPendientesArticulo: string;

// AAlmacen y ASku vacios = sin ese filtro.
function ConsultarTraspasosPendientes(AConexion: TUniConnection;
  const AArticulo, AAlmacen, ASku: string): TTraspasosPendientes;

implementation

uses
  System.SysUtils, System.Generics.Collections;

function SqlTraspasosPendientesArticulo: string;
begin
  Result :=
    'SELECT P.TIPO_PENDIENTE, P.DOCUMENTO_PENDIENTE, ' +
    '       P.CODIGO_ALM_ORIGEN, P.CODIGO_ALM_DESTINO, ' +
    '       P.CODIGO_UNIDAD_SKU, P.CANTIDAD_PENDIENTE ' +
    '  FROM vi_traspasos_pendientes P ' +
    '  JOIN fza_articulos_skus S ' +
    '    ON S.CODIGO_UNIDAD_SKU = P.CODIGO_UNIDAD_SKU ' +
    ' WHERE S.CODIGO_ART_SKU = :ARTICULO ' +
    '   AND (:SKU = '''' OR P.CODIGO_UNIDAD_SKU = :SKU) ' +
    '   AND (:ALMACEN = '''' ' +
    '        OR P.CODIGO_ALM_ORIGEN = :ALMACEN ' +
    '        OR P.CODIGO_ALM_DESTINO = :ALMACEN) ' +
    ' ORDER BY P.TIPO_PENDIENTE, P.DOCUMENTO_PENDIENTE, ' +
    '          P.CODIGO_UNIDAD_SKU';
end;

function ConsultarTraspasosPendientes(AConexion: TUniConnection;
  const AArticulo, AAlmacen, ASku: string): TTraspasosPendientes;
var
  oConsulta: TUniQuery;
  oLista: TList<TTraspasoPendiente>;
  rFila: TTraspasoPendiente;
begin
  oConsulta := TUniQuery.Create(nil);
  oLista := TList<TTraspasoPendiente>.Create;
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := SqlTraspasosPendientesArticulo;
    oConsulta.ParamByName('ARTICULO').AsString := AArticulo;
    oConsulta.ParamByName('SKU').AsString := ASku;
    oConsulta.ParamByName('ALMACEN').AsString := AAlmacen;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      rFila.Tipo := oConsulta.FieldByName('TIPO_PENDIENTE').AsString;
      rFila.Documento :=
        oConsulta.FieldByName('DOCUMENTO_PENDIENTE').AsString;
      rFila.Origen := oConsulta.FieldByName('CODIGO_ALM_ORIGEN').AsString;
      rFila.Destino := oConsulta.FieldByName('CODIGO_ALM_DESTINO').AsString;
      rFila.Sku := oConsulta.FieldByName('CODIGO_UNIDAD_SKU').AsString;
      rFila.Cantidad := oConsulta.FieldByName('CANTIDAD_PENDIENTE').AsFloat;
      oLista.Add(rFila);
      oConsulta.Next;
    end;
    Result := oLista.ToArray;
  finally
    oLista.Free;
    oConsulta.Free;
  end;
end;

end.
