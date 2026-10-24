{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasCalculo                                          }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Orquesta el cálculo de una factura y traduce sus errores a resultados.    }
{******************************************************************************}
unit inLibFacturasCalculo;

interface

uses
  Data.DB, Uni, inLibFacturasServiciosIntf,
  inLibFacturasLecturasIntf;

type
  TCalculadorFactura = class(
    TInterfacedObject,
    ICalculadorFactura)
  private
    FConexion: TUniConnection;
    FRepositorioLecturas: IRepositorioLecturasFactura;
  public
    constructor Create(
      AConexion: TUniConnection;
      const ARepositorioLecturas: IRepositorioLecturasFactura);
    function Calcular(
      ACabecera, ALineas: TDataSet;
      APermiteRecalcular: Boolean): TResultadoOperacionFactura;
  end;

implementation

uses
  System.SysUtils, inLibFacturas, inLibMsgFacturas;

constructor TCalculadorFactura.Create(
  AConexion: TUniConnection;
  const ARepositorioLecturas: IRepositorioLecturasFactura);
begin
  inherited Create;
  FConexion := AConexion;
  FRepositorioLecturas := ARepositorioLecturas;
end;

function TCalculadorFactura.Calcular(
  ACabecera, ALineas: TDataSet;
  APermiteRecalcular: Boolean): TResultadoOperacionFactura;
var
  Totales: TFacturaTotales;
begin
  Result := TResultadoOperacionFactura.Correcto;
  if Assigned(ACabecera) and
     ACabecera.Active and
     Assigned(ALineas) and
     ALineas.Active and
     APermiteRecalcular then
  begin
    try
      Totales := TFacturaTotales.Create(
        FConexion,
        FRepositorioLecturas,
        ACabecera,
        ALineas);
      try
        if (not Totales.ProcesarFacturaCompleta) and
           (Totales.MensajeError <> '') then
        begin
          Result := TResultadoOperacionFactura.Error(
            Format(
              SErrorCalcularBorradorDetalle,
              [Totales.MensajeError]));
        end;
      finally
        Totales.Free;
      end;
    except
      on E: Exception do
      begin
        Result := TResultadoOperacionFactura.Error(
          Format(
            SErrorCalculoBorrador,
            [E.Message]));
      end;
    end;
  end;
end;

end.
