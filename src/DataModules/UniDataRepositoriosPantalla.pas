{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataRepositoriosPantalla                                  }
{    Tipo:       Composición                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Construcción de adaptadores de pantalla por capacidad independiente.      }
{******************************************************************************}
unit UniDataRepositoriosPantalla;

interface

uses
  Uni, inLibRepositoriosPantallaIntf, inLibParametrosIntf,
  inLibConexionPerfilIntf,
  inLibContextoSesionIntf, inLibPerfilesUsuarioIntf,
  inLibLogIntf, inLibPreviewTicket,
  UniDataRepositoriosArticulosPantalla,
  UniDataRepositoriosConfiguracionPantalla,
  UniDataRepositoriosDocumentosPantalla,
  UniDataRepositoriosRemesasPantalla,
  UniDataRepositoriosOperacionesPantalla,
  UniDataRepositoriosVentasPantalla,
  UniDataRepositoriosCajaPantalla,
  UniDataRepositoriosTicketsCajaPantalla;

function CrearServiciosSqlPantallaUniDAC(
  const ANombrePantalla: string;
  const APerfilesLectura: ILectorPerfilesUsuario;
  const APerfilesEscritura: IEscritorPerfilesUsuario;
  const ARegistroLog: IRegistroLog;
  AMotor: TMotorBBDD = mbMariaDB): TServiciosSqlPantalla;
function CrearRepositoriosArticulosPantallaUniDAC(
  AConexion: TUniConnection;
  const AParametrosCaja: IParametrosCaja;
  const AServiciosSql: TServiciosSqlPantalla):
  IRepositoriosArticulosPantalla;
function CrearRepositoriosConfiguracionPantallaUniDAC(
  AConexion: TUniConnection;
  const AServiciosSql: TServiciosSqlPantalla):
  IRepositoriosConfiguracionPantalla;
function CrearRepositoriosDocumentosPantallaUniDAC(
  AConexion: TUniConnection;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const ARegistroLog: IRegistroLog;
  const AServiciosSql: TServiciosSqlPantalla):
  IRepositoriosDocumentosPantalla;
function CrearRepositoriosRemesasPantallaUniDAC(
  AConexion: TUniConnection;
  const AServiciosSql: TServiciosSqlPantalla): IRepositoriosRemesasPantalla;
function CrearRepositoriosOperacionesPantallaUniDAC(
  AConexion: TUniConnection;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const ARegistroLog: IRegistroLog;
  const AServiciosSql: TServiciosSqlPantalla):
  IRepositoriosOperacionesPantalla;
function CrearRepositoriosVentasPantallaUniDAC(
  AConexion: TUniConnection;
  const AServiciosSql: TServiciosSqlPantalla): IRepositoriosVentasPantalla;
function CrearRepositoriosCajaPantallaUniDAC(
  AConexion: TUniConnection;
  const AServiciosSql: TServiciosSqlPantalla): IRepositoriosCajaPantalla;
function CrearRepositoriosTicketsCajaPantallaUniDAC(
  AConexion: TUniConnection;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AContextoSesion: IContextoSesionAplicacion;
  const APreviewTicket: IPreviewTicket;
  const AServiciosSql: TServiciosSqlPantalla):
  IRepositoriosTicketsCajaPantalla;

implementation

uses
  System.SysUtils, UniDataCatalogoSqlAplicacion;

function CrearServiciosSqlPantallaUniDAC(
  const ANombrePantalla: string;
  const APerfilesLectura: ILectorPerfilesUsuario;
  const APerfilesEscritura: IEscritorPerfilesUsuario;
  const ARegistroLog: IRegistroLog;
  AMotor: TMotorBBDD): TServiciosSqlPantalla;
var
  bCatalogoActivo: Boolean;
begin
  Result := Default(TServiciosSqlPantalla);
  bCatalogoActivo := False;
  if Assigned(APerfilesLectura) then
  begin
    try
      bCatalogoActivo := SameText(
        APerfilesLectura.ObtenerValorPerfil(
          ANombrePantalla, 'oGetSQLFromDB', 'False'),
        'True');
    except
      on E: Exception do
        if Assigned(ARegistroLog) then
          ARegistroLog.RegistrarAviso(
            'No se pudo leer oGetSQLFromDB de ' +
            ANombrePantalla + ': ' + E.Message);
    end;
  end;
  CrearCatalogoSqlAplicacion(
    APerfilesLectura,
    APerfilesEscritura,
    bCatalogoActivo,
    Result.Catalogo,
    Result.Incidencias,
    ARegistroLog,
    AMotor);
end;

function CrearRepositoriosArticulosPantallaUniDAC(
  AConexion: TUniConnection;
  const AParametrosCaja: IParametrosCaja;
  const AServiciosSql: TServiciosSqlPantalla):
  IRepositoriosArticulosPantalla;
begin
  Result := TRepositoriosArticulosPantallaUniDAC.Create(
    AConexion,
    AParametrosCaja,
    AServiciosSql.Catalogo,
    AServiciosSql.Incidencias);
end;

function CrearRepositoriosConfiguracionPantallaUniDAC(
  AConexion: TUniConnection;
  const AServiciosSql: TServiciosSqlPantalla):
  IRepositoriosConfiguracionPantalla;
begin
  Result := TRepositoriosConfiguracionPantallaUniDAC.Create(
    AConexion,
    AServiciosSql.Catalogo,
    AServiciosSql.Incidencias);
end;

function CrearRepositoriosDocumentosPantallaUniDAC(
  AConexion: TUniConnection;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const ARegistroLog: IRegistroLog;
  const AServiciosSql: TServiciosSqlPantalla):
  IRepositoriosDocumentosPantalla;
begin
  Result := TRepositoriosDocumentosPantallaUniDAC.Create(
    AConexion,
    AParametrosApp,
    AParametrosCaja,
    ARegistroLog,
    AServiciosSql.Catalogo,
    AServiciosSql.Incidencias);
end;

function CrearRepositoriosRemesasPantallaUniDAC(
  AConexion: TUniConnection;
  const AServiciosSql: TServiciosSqlPantalla): IRepositoriosRemesasPantalla;
begin
  Result := TRepositoriosRemesasPantallaUniDAC.Create(
    AConexion,
    AServiciosSql.Catalogo,
    AServiciosSql.Incidencias);
end;

function CrearRepositoriosOperacionesPantallaUniDAC(
  AConexion: TUniConnection;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const ARegistroLog: IRegistroLog;
  const AServiciosSql: TServiciosSqlPantalla):
  IRepositoriosOperacionesPantalla;
begin
  Result := TRepositoriosOperacionesPantallaUniDAC.Create(
    AConexion,
    AParametrosApp,
    AParametrosCaja,
    ARegistroLog,
    AServiciosSql.Catalogo,
    AServiciosSql.Incidencias);
end;

function CrearRepositoriosVentasPantallaUniDAC(
  AConexion: TUniConnection;
  const AServiciosSql: TServiciosSqlPantalla): IRepositoriosVentasPantalla;
begin
  Result := TRepositoriosVentasPantallaUniDAC.Create(
    AConexion,
    AServiciosSql.Catalogo,
    AServiciosSql.Incidencias);
end;

function CrearRepositoriosCajaPantallaUniDAC(
  AConexion: TUniConnection;
  const AServiciosSql: TServiciosSqlPantalla): IRepositoriosCajaPantalla;
begin
  Result := TRepositoriosCajaPantallaUniDAC.Create(
    AConexion,
    AServiciosSql.Catalogo,
    AServiciosSql.Incidencias);
end;

function CrearRepositoriosTicketsCajaPantallaUniDAC(
  AConexion: TUniConnection;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AContextoSesion: IContextoSesionAplicacion;
  const APreviewTicket: IPreviewTicket;
  const AServiciosSql: TServiciosSqlPantalla):
  IRepositoriosTicketsCajaPantalla;
begin
  Result := TRepositoriosTicketsCajaPantallaUniDAC.Create(
    AConexion,
    AParametrosApp,
    AParametrosCaja,
    AContextoSesion,
    APreviewTicket,
    AServiciosSql.Catalogo,
    AServiciosSql.Incidencias);
end;

end.
