{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataVerifactuEsquema                                      }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptador UniDAC para consultar capacidades del esquema Verifactu.        }
{******************************************************************************}
unit UniDataVerifactuEsquema;

interface

uses
  Uni, inLibVerifactuEsquemaIntf;

type
  TRepositorioEsquemaVerifactuUniDAC = class(
    TInterfacedObject,
    IRepositorioEsquemaVerifactu)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    class function SqlComprobarCola: string; static;
    function ColaDisponible(out AMensaje: string): Boolean;
  end;

function CrearRepositorioEsquemaVerifactuUniDAC(
  AConexion: TUniConnection): IRepositorioEsquemaVerifactu;

implementation

uses
  System.SysUtils;

function CrearRepositorioEsquemaVerifactuUniDAC(
  AConexion: TUniConnection): IRepositorioEsquemaVerifactu;
begin
  Result := TRepositorioEsquemaVerifactuUniDAC.Create(AConexion);
end;

constructor TRepositorioEsquemaVerifactuUniDAC.Create(
  AConexion: TUniConnection);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
end;

class function TRepositorioEsquemaVerifactuUniDAC.SqlComprobarCola: string;
begin
  Result :=
    ' SELECT COUNT(*) AS N ' +
    '   FROM INFORMATION_SCHEMA.COLUMNS ' +
    '  WHERE TABLE_SCHEMA = DATABASE() ' +
    '    AND TABLE_NAME = ''fza_verifactu_cola'' ' +
    '    AND COLUMN_NAME IN (''ID_VFCOLA'', ' +
    '                        ''SERIE_FAC_VFCOLA'', ' +
    '                        ''NUMERO_FAC_VFCOLA'', ' +
    '                        ''ESTADO_VFCOLA'', ' +
    // SII (script 791): sin el sistema de cada fila no hay cola mixta.
    '                        ''SISTEMA_VFCOLA'')';
end;

function TRepositorioEsquemaVerifactuUniDAC.ColaDisponible(
  out AMensaje: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  Result := False;
  AMensaje := '';
  oConsulta := TUniQuery.Create(nil);
  try
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text := SqlComprobarCola;
      oConsulta.Open;
      Result := oConsulta.FieldByName('N').AsInteger = 5;
      if not Result then
        AMensaje := 'Facturas: esquema de cola Verifactu incompleto; ' +
          'se abre listado sin estado de cola.';
    except
      on E: Exception do
        AMensaje := 'Facturas: no se pudo comprobar cola Verifactu; ' +
          'se abre listado sin estado de cola. ' + E.Message;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.
