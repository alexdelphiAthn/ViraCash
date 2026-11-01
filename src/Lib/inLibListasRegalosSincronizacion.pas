{******************************************************************************}
{                                                                              }
{  Módulo:       inLibListasRegalosSincronizacion                              }
{    Tipo:       Librería (caso de uso)                                        }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Sincronización de las listas de regalos con una tienda PrestaShop:        }
{    1) recoge los regalos web pendientes y los registra en ViraCash           }
{       (PRC_LRG_REGALO_WEB); los que ViraCash no admite se confirman como     }
{       RECHAZADO; 2) publica las listas cuya versión no tiene la tienda,      }
{       con los regalos web ya registrados, para que no cuenten dos veces.     }
{    Mismo flujo que el prototipo lista_regalos\prototipo\sincronizar_listas.  }
{******************************************************************************}
unit inLibListasRegalosSincronizacion;

interface

uses
  inLibListasRegalos, inLibListasRegalosPrestaShop;

type
  IRepositorioSincronizacionListas = interface
    ['{2D8B5E71-9C34-4A0F-B6E2-71C4A9D03F58}']
    // Códigos de las listas de la empresa que la tienda no tiene al día.
    function ListasPendientes(const AEmpresa, AOrigen: string):
      TArray<string>;
    // Cabecera, líneas y regalos web incluidos de una misma foto.
    function LeerLista(const ACodigo, AOrigen: string): TListaPublicable;
    procedure ConfirmarPublicacion(const ACodigo, AOrigen: string;
      AVersion: Integer);
    // p_RESULTADO de PRC_LRG_REGALO_WEB.
    function RegistrarRegaloWeb(const ARegalo: TRegaloWebPendiente;
      const AOrigen: string): Integer;
  end;

  TInformeSincronizacionListas = record
    Publicadas: Integer;
    Registrados: Integer;
    Rechazados: Integer;
    Detalle: TArray<string>;
    function Vacio: Boolean;
  end;

  TSincronizadorListasRegalos = class
  private
    FRepositorio: IRepositorioSincronizacionListas;
    FApi: IApiListasRegalos;
    procedure RecogerRegalos(const AOrigen: string;
      var AInforme: TInformeSincronizacionListas);
    procedure PublicarListas(const AEmpresa, AOrigen: string;
      var AInforme: TInformeSincronizacionListas);
  public
    constructor Create(const ARepositorio: IRepositorioSincronizacionListas;
      const AApi: IApiListasRegalos);
    function Ejecutar(const AEmpresa, AOrigen: string):
      TInformeSincronizacionListas;
  end;

implementation

uses
  System.SysUtils, inLibMsgListasRegalos;

procedure Anotar(var AInforme: TInformeSincronizacionListas;
  const ATexto: string);
begin
  AInforme.Detalle := AInforme.Detalle + [ATexto];
end;

{ TInformeSincronizacionListas }

function TInformeSincronizacionListas.Vacio: Boolean;
begin
  Result := Length(Detalle) = 0;
end;

{ TSincronizadorListasRegalos }

constructor TSincronizadorListasRegalos.Create(
  const ARepositorio: IRepositorioSincronizacionListas;
  const AApi: IApiListasRegalos);
begin
  inherited Create;
  FRepositorio := ARepositorio;
  FApi := AApi;
end;

function TSincronizadorListasRegalos.Ejecutar(const AEmpresa,
  AOrigen: string): TInformeSincronizacionListas;
begin
  Result := Default(TInformeSincronizacionListas);
  // Primero los regalos: así la publicación ya los cuenta como regalados.
  RecogerRegalos(AOrigen, Result);
  PublicarListas(AEmpresa, AOrigen, Result);
end;

procedure TSincronizadorListasRegalos.RecogerRegalos(const AOrigen: string;
  var AInforme: TInformeSincronizacionListas);
var
  oRegalo: TRegaloWebPendiente;
  aRechazados: TArray<Int64>;
  iResultado: Integer;
begin
  aRechazados := nil;
  for oRegalo in FApi.RegalosPendientes do
  begin
    iResultado := FRepositorio.RegistrarRegaloWeb(oRegalo, AOrigen);
    if EsResultadoListaCorrecto(iResultado) then
    begin
      Inc(AInforme.Registrados);
      Anotar(AInforme, Format(SSincroRegaloRegistrado,
        [oRegalo.Nombre, oRegalo.Lista]));
    end
    else
    begin
      Inc(AInforme.Rechazados);
      aRechazados := aRechazados + [oRegalo.IdLineaPedido];
      Anotar(AInforme, Format(SSincroRegaloRechazado,
        [oRegalo.Nombre, oRegalo.Lista, TextoResultadoLista(iResultado)]));
    end;
  end;
  // Los registrados se confirman al publicar su lista, en la tienda y en
  // la misma transacción que la nueva cantidad regalada.
  FApi.Confirmar(aRechazados, CONFIRMACION_REGALO_RECHAZADO);
end;

procedure TSincronizadorListasRegalos.PublicarListas(const AEmpresa,
  AOrigen: string; var AInforme: TInformeSincronizacionListas);
var
  sCodigo: string;
  oLista: TListaPublicable;
  oRespuesta: TRespuestaPublicacionLista;
begin
  for sCodigo in FRepositorio.ListasPendientes(AEmpresa, AOrigen) do
  begin
    oLista := FRepositorio.LeerLista(sCodigo, AOrigen);
    oRespuesta := FApi.Publicar(oLista);
    FRepositorio.ConfirmarPublicacion(sCodigo, AOrigen, oLista.Version);
    Inc(AInforme.Publicadas);
    if oRespuesta.Ignorada then
      Anotar(AInforme, Format(SSincroListaIgnorada, [sCodigo]))
    else
      Anotar(AInforme, Format(SSincroListaPublicada,
        [sCodigo, oLista.Version]));
    if Length(oRespuesta.SkusSinProducto) > 0 then
      Anotar(AInforme, Format(SSincroSinProducto,
        [sCodigo, string.Join(', ', oRespuesta.SkusSinProducto)]));
  end;
end;

end.
