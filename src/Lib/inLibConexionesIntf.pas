{******************************************************************************}
{                                                                              }
{  Módulo:       inLibConexionesIntf                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos para obtener y crear conexiones de la aplicación.               }
{******************************************************************************}
unit inLibConexionesIntf;

interface

uses
  System.Classes,
  Uni,
  inLibConexionPerfilIntf,
  inLibDialectoSqlIntf;

type
  TUsoConexionTrabajo = (
    uctMantenimiento,
    uctPrecarga,
    uctSegundoPlano
  );

  IConfiguradorConexionesUniDAC = interface
    ['{DB12E7C0-73F9-4413-8574-84818B5EEA2B}']
    procedure ConfigurarConexion(AConexion: TUniConnection);
    procedure ConfigurarConexionTemporal(
      AConexion: TUniConnection;
      const APerfil: TPerfilConexion;
      const ACredencial: string);
    procedure Conectar(AConexion: TUniConnection);
    procedure ConectarTemporal(
      AConexion: TUniConnection;
      const APerfil: TPerfilConexion;
      const ACredencial: string);
    procedure InicializarSesion(AConexion: TUniConnection);
    procedure InicializarSesionTemporal(
      AConexion: TUniConnection;
      const APerfil: TPerfilConexion);
    procedure ActualizarConfiguracion(
      const APerfil: TPerfilConexion;
      const ACredencial: string);
    procedure GuardarConfiguracion;
  end;

  IFabricaConexionesUniDAC = interface(IConfiguradorConexionesUniDAC)
    ['{C1A49483-4701-4B86-96E6-D608928DA9B3}']
    function GetPerfil: TPerfilConexion;
    function GetCapacidades: TCapacidadesMotorBBDD;
    function GetDialectoSql: IDialectoSql;
    function CrearConexion(AOwner: TComponent): TUniConnection;
    function CrearPerfilAdministrativo(
      const APerfilBase: TPerfilConexion): TPerfilConexion;
    function FormatearError(
      ACodigo: Integer;
      const AMensaje: string;
      AIncluirDetalle: Boolean): string;
    function EtiquetaMotor: string;
    property Perfil: TPerfilConexion read GetPerfil;
    property Capacidades: TCapacidadesMotorBBDD read GetCapacidades;
    property DialectoSql: IDialectoSql read GetDialectoSql;
  end;

  // Si el perfil configurado trae contraseña de base de datos; para
  // explicar un fallo de conexión con la contraseña vacía.
  IEstadoCredencialConexion = interface
    ['{B55AB4C8-ACB4-4306-B631-3EA83750210D}']
    function TieneCredencial: Boolean;
  end;

  IServicioConexiones = interface
    ['{BB7D3E06-AD0C-4C73-B7A1-D8E19EE1D994}']
    function GetConexionPrincipal: TUniConnection;
    function GetDisponible: Boolean;
    function CrearConexion(
      AOwner: TComponent;
      AUso: TUsoConexionTrabajo
    ): TUniConnection;
    procedure Invalidar;
    property ConexionPrincipal: TUniConnection
      read GetConexionPrincipal;
    property Disponible: Boolean read GetDisponible;
  end;

  IProveedorConexiones = interface
    ['{A2B6D464-97AE-4ED4-9791-9ED38808770A}']
    function GetConexiones: IServicioConexiones;
    property Conexiones: IServicioConexiones read GetConexiones;
  end;

implementation

end.
