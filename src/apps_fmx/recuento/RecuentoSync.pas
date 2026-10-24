{******************************************************************************}
{                                                                              }
{  Módulo:       RecuentoSync                                                  }
{    Tipo:       Librería (App FMX)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Vacía la cola local de escaneos subiéndolos al servidor por lotes. El     }
{    servidor deduplica por uuid, así que reintentar un lote es seguro.        }
{******************************************************************************}
unit RecuentoSync;

interface

uses
  System.SysUtils,
  RecuentoModelo, RecuentoApi, RecuentoLocal;

const
  // Eventos por petición (límite cómodo en hosting compartido).
  TAM_LOTE = 300;

type
  TRecuentoSync = class
  public
    // Sube todos los pendientes del recuento. Devuelve cuántos confirmó el
    // servidor (aceptados + duplicados ya estaban) y un mensaje de error.
    function Sincronizar(AIdRecuento: Int64; out ASubidos: Integer;
                         out AMensaje: string): Boolean;
  end;

implementation

uses
  TraduccionMovil;

function TRecuentoSync.Sincronizar(AIdRecuento: Int64; out ASubidos: Integer;
  out AMensaje: string): Boolean;
var
  oApi: TRecuentoApi;
  aLote: TArrEvento;
  aUuids: TArray<string>;
  iAceptados, iDuplicados, i: Integer;
  bLoteConfirmado: Boolean;
  bSeguir: Boolean;
begin
  Result := True;
  ASubidos := 0;
  AMensaje := '';
  oApi := TRecuentoApi.Create;
  try
    bSeguir := True;
    while bSeguir do
    begin
      aLote := oLocal.LeerLote(AIdRecuento, TAM_LOTE);
      if Length(aLote) = 0 then
        bSeguir := False
      else
      begin
        bLoteConfirmado := oApi.SubirEventos(
          AIdRecuento, aLote, iAceptados, iDuplicados);
        bLoteConfirmado := bLoteConfirmado and
          (iAceptados + iDuplicados = Length(aLote));
        if bLoteConfirmado then
        begin
          SetLength(aUuids, Length(aLote));
          for i := 0 to High(aLote) do
            aUuids[i] := aLote[i].Uuid;
          oLocal.MarcarSubidos(aUuids);
          Inc(ASubidos, Length(aLote));
        end
        else
        begin
          // Cortamos al primer fallo: la cola se conserva para reintentar.
          Result := False;
          AMensaje := oApi.UltimoError;
          if AMensaje = '' then
            AMensaje := Tr(
              'El servidor no confirmó íntegramente el lote; ' +
              'la cola local se conserva');
          bSeguir := False;
        end;
      end;
    end;
  finally
    FreeAndNil(oApi);
  end;
end;

end.
