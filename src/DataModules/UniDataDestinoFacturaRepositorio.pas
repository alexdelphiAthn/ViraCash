{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataDestinoFacturaRepositorio                             }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptador UniDAC para resolver la pantalla de una factura.                }
{******************************************************************************}
unit UniDataDestinoFacturaRepositorio;

interface

uses
  Uni,
  inLibDestinoFacturaPersistenciaIntf;

function CrearResolutorDestinoFacturaUniDAC(
  AConexion: TUniConnection): IResolutorDestinoFactura;

implementation

uses
  System.SysUtils,
  Data.DB;

type
  TResolutorDestinoFacturaUniDAC = class(TInterfacedObject,
    IResolutorDestinoFactura)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function Resolver(const ANumero, ASerie: string): string;
  end;

constructor TResolutorDestinoFacturaUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TResolutorDestinoFacturaUniDAC.Resolver(
  const ANumero, ASerie: string): string;
var
  oConsulta: TUniQuery;
  sTipo: string;
begin
  Result := 'Facturas';
  if Assigned(FConexion) and FConexion.Connected then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text :=
        'SELECT TIPO_FAC ' +
        '  FROM fza_facturas ' +
        ' WHERE NUMERO_FAC = :NUM ' +
        '   AND SERIE_FAC = :SER';
      oConsulta.ParamByName('NUM').AsString := ANumero;
      oConsulta.ParamByName('SER').AsString := ASerie;
      oConsulta.Open;
      if not oConsulta.IsEmpty then
      begin
        sTipo := oConsulta.FieldByName('TIPO_FAC').AsString;
        if SameText(sTipo, 'SIMPLIFICADA') then
          Result := 'FacturasSimplif';
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function CrearResolutorDestinoFacturaUniDAC(
  AConexion: TUniConnection): IResolutorDestinoFactura;
begin
  Result := TResolutorDestinoFacturaUniDAC.Create(AConexion);
end;

end.
