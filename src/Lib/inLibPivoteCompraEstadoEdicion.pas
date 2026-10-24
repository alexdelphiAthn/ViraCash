{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPivoteCompraEstadoEdicion                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Estado mutable compartido por la edición y el pintado del pivote.        }
{******************************************************************************}
unit inLibPivoteCompraEstadoEdicion;

interface

uses
  System.Generics.Collections;

type
  TEstadoEdicionPivoteCompra = class
  private
    FCantidadesPendientes: TDictionary<Int64, Double>;
    FARecibir            : TDictionary<Int64, Double>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Limpiar;
    property CantidadesPendientes: TDictionary<Int64, Double>
      read FCantidadesPendientes;
    property ARecibir: TDictionary<Int64, Double> read FARecibir;
  end;

implementation

uses
  System.SysUtils;

constructor TEstadoEdicionPivoteCompra.Create;
begin
  inherited Create;
  FCantidadesPendientes := TDictionary<Int64, Double>.Create;
  FARecibir := TDictionary<Int64, Double>.Create;
end;

destructor TEstadoEdicionPivoteCompra.Destroy;
begin
  FreeAndNil(FARecibir);
  FreeAndNil(FCantidadesPendientes);
  inherited;
end;

procedure TEstadoEdicionPivoteCompra.Limpiar;
begin
  FCantidadesPendientes.Clear;
  FARecibir.Clear;
end;

end.
