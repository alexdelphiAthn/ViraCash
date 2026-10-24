{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataRepositoriosRemesasPantalla                           }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptadores de remesas requeridos por las pantallas.                      }
{******************************************************************************}
unit UniDataRepositoriosRemesasPantalla;

interface

uses
  Uni,
  inLibCargaEfectosRemesaPersistenciaIntf,
  UniDataRepositoriosGeneralesPantalla;

type
  IRepositoriosRemesasPantalla = interface
    ['{24B93D18-5C59-4DC4-B9C2-911F88A849A5}']
    function CrearRepositorioCargaEfectosRemesa(
      AConexion: TUniConnection = nil): IRepositorioCargaEfectosRemesa;
  end;

  TRepositoriosRemesasPantallaUniDAC = class(
    TAdaptadorRepositoriosPantallaUniDAC,
    IRepositoriosRemesasPantalla)
  public
    function CrearRepositorioCargaEfectosRemesa(
      AConexion: TUniConnection = nil): IRepositorioCargaEfectosRemesa;
  end;

implementation

uses
  UniDataCargaEfectosRemesaRepositorio;

function TRepositoriosRemesasPantallaUniDAC.
  CrearRepositorioCargaEfectosRemesa(
  AConexion: TUniConnection): IRepositorioCargaEfectosRemesa;
begin
  Result := CrearRepositorioCargaEfectosRemesaUniDAC(
    Conexion(AConexion));
end;

end.
