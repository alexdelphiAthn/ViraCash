{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataRepositoriosGeneralesPantalla                         }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Base compartida de los adaptadores de repositorios de pantalla.           }
{******************************************************************************}
unit UniDataRepositoriosGeneralesPantalla;

interface

uses
  Uni, inLibCatalogoSqlIntf;

type
  TAdaptadorRepositoriosPantallaUniDAC = class(TInterfacedObject)
  protected
    FConexionPrincipal: TUniConnection;
    FCatalogoSql: ICatalogoSql;
    FIncidenciasSql: IRegistroIncidenciasSql;
    function Conexion(AConexion: TUniConnection): TUniConnection;
  public
    constructor Create(
      AConexionPrincipal: TUniConnection;
      const ACatalogoSql: ICatalogoSql;
      const AIncidenciasSql: IRegistroIncidenciasSql);
    destructor Destroy; override;
  end;

implementation

constructor TAdaptadorRepositoriosPantallaUniDAC.Create(
  AConexionPrincipal: TUniConnection;
  const ACatalogoSql: ICatalogoSql;
  const AIncidenciasSql: IRegistroIncidenciasSql);
begin
  inherited Create;
  FConexionPrincipal := AConexionPrincipal;
  FCatalogoSql := ACatalogoSql;
  FIncidenciasSql := AIncidenciasSql;
end;

destructor TAdaptadorRepositoriosPantallaUniDAC.Destroy;
begin
  FIncidenciasSql := nil;
  FCatalogoSql := nil;
  FConexionPrincipal := nil;
  inherited;
end;

function TAdaptadorRepositoriosPantallaUniDAC.Conexion(
  AConexion: TUniConnection): TUniConnection;
begin
  Result := AConexion;
  if not Assigned(Result) then
    Result := FConexionPrincipal;
end;

end.
