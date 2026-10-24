{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataVerifactuCola                                          }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       12/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de la cola de envíos Verifactu.                               }
{    Consulta de fza_verifactu_cola para el mantenimiento de la cola.          }
{******************************************************************************}
unit UniDataVerifactuCola;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser, UniDataConn;

type
  TdmVerifactuCola = class(TdmBase)
  private
    { Private declarations }
  public
    // ID de las filas del SII PENDIENTE o ERROR con más de ADias días
    // desde FECHA_FAC (plazo del SII: 4 días naturales). Vacío sin
    // SISTEMA_VFCOLA (script 791). FZ-ISSUE-293.
    function IdsSiiFueraDePlazo(ADias: Integer): TArray<Int64>;
  end;

implementation

uses
  inLibVerifactu;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

function TdmVerifactuCola.IdsSiiFueraDePlazo(
  ADias: Integer): TArray<Int64>;
var
  Qry: TUniQuery;
  iFila: Integer;
begin
  SetLength(Result, 0);
  if unqryTablaG.Active and
     (unqryTablaG.FindField('SISTEMA_VFCOLA') <> nil) then
  begin
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := unqryTablaG.Connection;
      Qry.SQL.Text :=
        ' SELECT c.ID_VFCOLA ' +
        '   FROM fza_verifactu_cola c ' +
        '   JOIN fza_facturas f ' +
        '     ON f.SERIE_FAC = c.SERIE_FAC_VFCOLA ' +
        '    AND f.NUMERO_FAC = c.NUMERO_FAC_VFCOLA ' +
        '  WHERE c.SISTEMA_VFCOLA = :SISTEMA ' +
        '    AND c.ESTADO_VFCOLA IN (''PENDIENTE'', ''ERROR'') ' +
        '    AND f.FECHA_FAC < CURDATE() - INTERVAL :DIAS DAY';
      Qry.ParamByName('SISTEMA').AsString := cSistemaColaSii;
      Qry.ParamByName('DIAS').AsInteger := ADias;
      Qry.Open;
      SetLength(Result, Qry.RecordCount);
      iFila := 0;
      while not Qry.Eof do
      begin
        Result[iFila] := Qry.Fields[0].AsLargeInt;
        Inc(iFila);
        Qry.Next;
      end;
      SetLength(Result, iFila);
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

initialization
  RegistrarDataModule(TdmVerifactuCola);
  ForceReferenceToClass(TdmVerifactuCola);
end.
