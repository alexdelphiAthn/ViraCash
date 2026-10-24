{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataRegistroPantallasRepositorio                           }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptador UniDAC para leer el registro de pantallas.                      }
{******************************************************************************}
unit UniDataRegistroPantallasRepositorio;

interface

uses
  Uni,
  inLibRegistroPantallasPersistenciaIntf;

function CrearLectorRegistroPantallasUniDAC(
  AConexion: TUniConnection): ILectorRegistroPantallas;

implementation

uses
  System.SysUtils,
  Data.DB;

type
  TLectorRegistroPantallasUniDAC = class(TInterfacedObject,
    ILectorRegistroPantallas)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function Cargar: TArray<TPantallaRegistrada>;
  end;

constructor TLectorRegistroPantallasUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TLectorRegistroPantallasUniDAC.Cargar:
  TArray<TPantallaRegistrada>;
var
  iIndice: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT CALL_WINF, CAPTION_WINF, MENUITEM_WINF, UNITF_WINF, ' +
      '       SHORTCUT_WINF, DATAMODULE_WINF, NUM_VENTANAS_WINF ' +
      '  FROM fza_winforms';
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iIndice := Length(Result);
      SetLength(Result, iIndice + 1);
      Result[iIndice].Llamada :=
        oConsulta.FieldByName('CALL_WINF').AsString;
      Result[iIndice].Titulo :=
        oConsulta.FieldByName('CAPTION_WINF').AsString;
      Result[iIndice].ElementoMenu :=
        oConsulta.FieldByName('MENUITEM_WINF').AsString;
      Result[iIndice].UnidadFormulario :=
        oConsulta.FieldByName('UNITF_WINF').AsString;
      Result[iIndice].Atajo :=
        oConsulta.FieldByName('SHORTCUT_WINF').AsString;
      Result[iIndice].UnidadDatos :=
        oConsulta.FieldByName('DATAMODULE_WINF').AsString;
      Result[iIndice].NumeroVentanas :=
        oConsulta.FieldByName('NUM_VENTANAS_WINF').AsInteger;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function CrearLectorRegistroPantallasUniDAC(
  AConexion: TUniConnection): ILectorRegistroPantallas;
begin
  Result := TLectorRegistroPantallasUniDAC.Create(AConexion);
end;

end.
