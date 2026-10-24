{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFusionEfectos                                           }
{    Tipo:       Caso de uso                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Valida y ejecuta la fusión transaccional de efectos.                      }
{******************************************************************************}
unit inLibFusionEfectos;

interface

uses
  inLibFusionEfectosIntf;

function CrearCasoUsoFusionEfectos(
  const ARepositorio: IRepositorioFusionEfectos
): ICasoUsoFusionEfectos;

implementation

uses
  System.SysUtils;

type
  TCasoUsoFusionEfectos = class(
    TInterfacedObject,
    ICasoUsoFusionEfectos)
  private
    FRepositorio: IRepositorioFusionEfectos;
  public
    constructor Create(
      const ARepositorio: IRepositorioFusionEfectos);
    function Ejecutar(
      const AClaves: TClavesFusionEfectos
    ): TResultadoFusionEfectos;
  end;

constructor TCasoUsoFusionEfectos.Create(
  const ARepositorio: IRepositorioFusionEfectos);
begin
  inherited Create;
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('ARepositorio');
  FRepositorio := ARepositorio;
end;

function TCasoUsoFusionEfectos.Ejecutar(
  const AClaves: TClavesFusionEfectos
): TResultadoFusionEfectos;
begin
  if Length(AClaves) < 2 then
    raise EArgumentException.Create(
      'Se necesitan al menos dos efectos para fusionar.');
  Result := FRepositorio.Fusionar(AClaves);
end;

function CrearCasoUsoFusionEfectos(
  const ARepositorio: IRepositorioFusionEfectos
): ICasoUsoFusionEfectos;
begin
  Result := TCasoUsoFusionEfectos.Create(ARepositorio);
end;

end.
