{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataVentasWsColaMonitor                                    }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       14/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Consultas de la cola de ventas WS y de sus intentos HTTP.                 }
{    Los cuerpos de petición y respuesta se cargan solo al elegir un intento.  }
{******************************************************************************}
unit UniDataVentasWsColaMonitor;

interface

uses
  System.SysUtils, System.Classes, Data.DB, MemDS, DBAccess, Uni,
  UniDataGen, inLibRegistroPantallas;

type
  TdmVentasWsColaMonitor = class(TdmBase)
    unqryIntentos: TUniQuery;
    dsIntentos: TDataSource;
    unqryContenidoIntento: TUniQuery;
  public
    procedure ActualizarCola;
    procedure CargarIntentos(AIdCola: Int64);
    procedure LeerContenidoIntento(AIdIntento: Int64;
      out APeticion, ARespuesta, AError: string);
  end;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass);
begin
end;

procedure TdmVentasWsColaMonitor.ActualizarCola;
begin
  if unqryTablaG.Active then
    unqryTablaG.Refresh
  else
    unqryTablaG.Open;
end;

procedure TdmVentasWsColaMonitor.CargarIntentos(AIdCola: Int64);
begin
  unqryIntentos.Close;
  if AIdCola > 0 then
  begin
    unqryIntentos.ParamByName('ID_COLA').AsLargeInt := AIdCola;
    unqryIntentos.Open;
  end;
end;

procedure TdmVentasWsColaMonitor.LeerContenidoIntento(
  AIdIntento: Int64;
  out APeticion, ARespuesta, AError: string);
begin
  APeticion := '';
  ARespuesta := '';
  AError := '';
  unqryContenidoIntento.Close;
  if AIdIntento > 0 then
  begin
    unqryContenidoIntento.ParamByName('ID_INTENTO').AsLargeInt :=
      AIdIntento;
    unqryContenidoIntento.Open;
    if not unqryContenidoIntento.IsEmpty then
    begin
      APeticion := unqryContenidoIntento.FieldByName(
        'PETICION_VWSCI').AsString;
      ARespuesta := unqryContenidoIntento.FieldByName(
        'RESPUESTA_VWSCI').AsString;
      AError := unqryContenidoIntento.FieldByName(
        'MENSAJE_VWSCI').AsString;
    end;
    unqryContenidoIntento.Close;
  end;
end;

initialization
  RegistrarDataModule(TdmVentasWsColaMonitor);
  ForceReferenceToClass(TdmVentasWsColaMonitor);
end.
