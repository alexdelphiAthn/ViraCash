{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCatalogoSqlEjecucion                                     }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Coordina lecturas de perfil y su fallback al SQL base.                    }
{******************************************************************************}
unit inLibCatalogoSqlEjecucion;

interface

uses
  inLibCatalogoSqlIntf;

procedure EjecutarLecturaSqlConFallback(
  const ADefinicion: TDefinicionSql;
  const ACatalogo: ICatalogoSql;
  const AEjecutar: TProcedimientoEjecutarSql;
  const AIncidencias: IRegistroIncidenciasSql = nil);

implementation

uses
  System.SysUtils;

resourcestring
  SErrorEjecutorSqlNoConfigurado =
    'El ejecutor de la operación SQL no está configurado.';
  SErrorPoliticaLecturaSql =
    'La operación %s no tiene política de lectura con fallback.';
  SLogFallbackSql =
    'Fallback SQL. Clave=%s. Motivo=%s';

procedure RegistrarIncidencia(
  const AClavePerfil, ACausa: string;
  const AIncidencias: IRegistroIncidenciasSql);
begin
  if Assigned(AIncidencias) then
    AIncidencias.Registrar(
      AClavePerfil,
      ACausa);
end;

procedure EjecutarLecturaSqlConFallback(
  const ADefinicion: TDefinicionSql;
  const ACatalogo: ICatalogoSql;
  const AEjecutar: TProcedimientoEjecutarSql;
  const AIncidencias: IRegistroIncidenciasSql);
var
  oSql: TSqlResuelto;
begin
  if not Assigned(AEjecutar) then
    raise Exception.Create(
      SErrorEjecutorSqlNoConfigurado);
  if ADefinicion.Politica <>
     pesPerfilLecturaConFallback then
    raise Exception.CreateFmt(
      SErrorPoliticaLecturaSql,
      [ClavePerfilSql(ADefinicion)]);
  oSql := ResolverSqlBase(ADefinicion);
  if Assigned(ACatalogo) then
  begin
    try
      oSql := ACatalogo.Resolver(ADefinicion);
    except
      on E: EVarianteSqlMotorNoDisponible do
        raise;
      on E: Exception do
      begin
        oSql := ResolverSqlBaseMotor(
          ADefinicion,
          ACatalogo.Motor,
          E.Message);
      end;
    end;
  end;
  if oSql.MotivoSqlBase <> '' then
    RegistrarIncidencia(
      oSql.ClavePerfil,
      oSql.MotivoSqlBase,
      AIncidencias);
  try
    AEjecutar(oSql.Texto);
  except
    on E: Exception do
    begin
      if oSql.Origen = osPerfil then
      begin
        RegistrarIncidencia(
          oSql.ClavePerfil,
          E.Message,
          AIncidencias);
        AEjecutar(oSql.TextoBase);
      end
      else
        raise;
    end;
  end;
end;

end.
