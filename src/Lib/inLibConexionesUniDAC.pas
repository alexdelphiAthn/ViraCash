{******************************************************************************}
{                                                                              }
{  Módulo:       inLibConexionesUniDAC                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       24/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Servicio UniDAC que crea conexiones de trabajo mediante la fábrica        }
{    configurada en la raíz de composición.                                    }
{******************************************************************************}
unit inLibConexionesUniDAC;

interface

uses
  System.Classes,
  Uni,
  inLibConexionesIntf;

type
  TServicioConexionesUniDAC = class(
    TInterfacedObject,
    IServicioConexiones
  )
  private
    FConexionPrincipal: TUniConnection;
    FFabrica: IFabricaConexionesUniDAC;
    function GetConexionPrincipal: TUniConnection;
    function GetDisponible: Boolean;
    procedure CopiarManejadorErrorConexionPrincipal(
      AConexion: TUniConnection);
  public
    constructor Create(
      AConexionPrincipal: TUniConnection;
      const AFabrica: IFabricaConexionesUniDAC);
    function CrearConexion(
      AOwner: TComponent;
      AUso: TUsoConexionTrabajo
    ): TUniConnection;
    procedure Invalidar;
  end;

implementation

uses
  System.SysUtils,
  inLibMsgConexion;

constructor TServicioConexionesUniDAC.Create(
  AConexionPrincipal: TUniConnection;
  const AFabrica: IFabricaConexionesUniDAC);
begin
  inherited Create;
  if not Assigned(AConexionPrincipal) then
    raise EArgumentException.Create(
      SErrorConexionPrincipalNoAsignada);
  if not Assigned(AFabrica) then
    raise EArgumentException.Create(
      SErrorFabricaConexionesNoAsignada);
  FConexionPrincipal := AConexionPrincipal;
  FFabrica := AFabrica;
end;

function TServicioConexionesUniDAC.GetConexionPrincipal: TUniConnection;
begin
  Result := FConexionPrincipal;
end;

function TServicioConexionesUniDAC.GetDisponible: Boolean;
begin
  Result := Assigned(FConexionPrincipal) and
            Assigned(FFabrica) and
            FConexionPrincipal.Connected;
end;

procedure TServicioConexionesUniDAC.CopiarManejadorErrorConexionPrincipal(
  AConexion: TUniConnection);
begin
  if not Assigned(AConexion) then
    raise EArgumentException.Create(
      SErrorConexionNoAsignada);
  AConexion.OnError := FConexionPrincipal.OnError;
end;

function TServicioConexionesUniDAC.CrearConexion(
  AOwner: TComponent;
  AUso: TUsoConexionTrabajo): TUniConnection;
begin
  if not Assigned(FConexionPrincipal) then
    raise EInvalidOpException.Create(
      SErrorConexionPrincipalNoAsignada);
  if not Assigned(FFabrica) then
    raise EInvalidOpException.Create(
      SErrorFabricaConexionesNoAsignada);
  Result := FFabrica.CrearConexion(AOwner);
  try
    CopiarManejadorErrorConexionPrincipal(Result);
    FFabrica.Conectar(Result);
    Result.AfterConnect := FConexionPrincipal.AfterConnect;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

procedure TServicioConexionesUniDAC.Invalidar;
begin
  FConexionPrincipal := nil;
  FFabrica := nil;
end;

end.
