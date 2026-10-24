{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPrestaShopColaMonitor                                  }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       14/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Consultas de la cola de PrestaShop y de su historial HTTP.                }
{    Los cuerpos de petición y respuesta se cargan solo al elegir un evento.   }
{******************************************************************************}
unit UniDataPrestaShopColaMonitor;

interface

uses
  System.SysUtils, System.Classes, Data.DB, MemDS, DBAccess, Uni,
  UniDataGen, inLibRegistroPantallas;

type
  TdmPrestaShopColaMonitor = class(TdmBase)
    unqryEventos: TUniQuery;
    dsEventos: TDataSource;
    unqryContenidoEvento: TUniQuery;
  public
    procedure ActualizarCola;
    procedure CargarEventos(AIdCola: Int64);
    procedure LeerContenidoEvento(AIdEvento: Int64;
      out APeticion, ARespuesta, AError: string);
  end;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass);
begin
end;

procedure TdmPrestaShopColaMonitor.ActualizarCola;
begin
  if unqryTablaG.Active then
    unqryTablaG.Refresh
  else
    unqryTablaG.Open;
end;

procedure TdmPrestaShopColaMonitor.CargarEventos(AIdCola: Int64);
begin
  unqryEventos.Close;
  if AIdCola > 0 then
  begin
    unqryEventos.ParamByName('ID_COLA').AsLargeInt := AIdCola;
    unqryEventos.Open;
  end;
end;

procedure TdmPrestaShopColaMonitor.LeerContenidoEvento(
  AIdEvento: Int64;
  out APeticion, ARespuesta, AError: string);
begin
  APeticion := '';
  ARespuesta := '';
  AError := '';
  unqryContenidoEvento.Close;
  if AIdEvento > 0 then
  begin
    unqryContenidoEvento.ParamByName('ID_EVENTO').AsLargeInt := AIdEvento;
    unqryContenidoEvento.Open;
    if not unqryContenidoEvento.IsEmpty then
    begin
      APeticion := unqryContenidoEvento.FieldByName(
        'PETICION_PSCEV').AsString;
      ARespuesta := unqryContenidoEvento.FieldByName(
        'RESPUESTA_PSCEV').AsString;
      AError := unqryContenidoEvento.FieldByName(
        'MENSAJE_PSCEV').AsString;
    end;
    unqryContenidoEvento.Close;
  end;
end;

initialization
  RegistrarDataModule(TdmPrestaShopColaMonitor);
  ForceReferenceToClass(TdmPrestaShopColaMonitor);
end.
