{******************************************************************************}
{                                                                              }
{  Módulo:       inLibParametrosIntf                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       25/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos puros de lectura y edición de parámetros de ViraCash.           }
{******************************************************************************}
unit inLibParametrosIntf;

interface

uses
  inLibLicenciaAplicacion;

type
  TTipoParametro = (tpString, tpInteger, tpBoolean);

  TParamInfo = record
    Categoria: string;
    Nombre: string;
    Descripcion: string;
    Tipo: TTipoParametro;
    ValorPorDefecto: string;
    ValorActual: string;
  end;

  IParametros = interface
    ['{2DFBBADE-CD7A-41BB-81C4-3C394D969F21}']
    function GetString(
      const AKey: string;
      const ADefault: string = ''
    ): string;
    function GetBool(
      const AKey: string;
      const ADefault: Boolean = False
    ): Boolean;
    function GetInt(
      const AKey: string;
      const ADefault: Integer = 0
    ): Integer;
  end;

  IParametrosAplicacion = interface(IParametros)
    ['{CB15A18C-2433-4955-B98D-DD510E13C73C}']
    function GetPath(const ANombre: string): string;
    // Impresora de documentos resuelta por patrón, con el mismo
    // tratamiento que ImpresoraCaja (vacía mientras no se resuelva).
    function ImpresoraDocumentos: string;
    function Licencia: TResultadoLicenciaAplicacion;
  end;

  IGestorLicenciaAplicacion = interface
    ['{F16F6241-A32D-4817-B058-087526946877}']
    procedure EstablecerLicencia(
      const AResultado: TResultadoLicenciaAplicacion);
  end;

  IParametrosCaja = interface(IParametros)
    ['{0A32C4BB-1E8D-41AC-9EDE-B2189CED5713}']
    function ImpresoraCaja: string;
    function TarifaDefecto: string;
    function NivelesFamiliaArqueo: Integer;
  end;

  IParametrosEdicion = interface
    ['{80BA92CE-4EDB-454E-84B6-B4AB7F388B4A}']
    function ListarDefiniciones: TArray<TParamInfo>;
    procedure Recargar(const AUsuario, AGrupo: string);
  end;

  TServiciosParametrosAplicacion = record
    Lectura: IParametrosAplicacion;
    Edicion: IParametrosEdicion;
    GestorLicencia: IGestorLicenciaAplicacion;
  end;

  TServiciosParametrosCaja = record
    Lectura: IParametrosCaja;
    Edicion: IParametrosEdicion;
  end;

  IProveedorParametros = interface
    ['{A6F5D9A6-89F4-4D2F-B6A4-1B64ECE1DFCD}']
    function GetParametrosApp: IParametrosAplicacion;
    function GetParametrosCaja: IParametrosCaja;
    property ParametrosApp: IParametrosAplicacion
      read GetParametrosApp;
    property ParametrosCaja: IParametrosCaja
      read GetParametrosCaja;
  end;

  IProveedorParametrosEdicion = interface
    ['{71C9F86E-525F-416B-ACAB-506656B47FEE}']
    function GetParametrosAppEdicion: IParametrosEdicion;
    function GetParametrosCajaEdicion: IParametrosEdicion;
    property ParametrosAppEdicion: IParametrosEdicion
      read GetParametrosAppEdicion;
    property ParametrosCajaEdicion: IParametrosEdicion
      read GetParametrosCajaEdicion;
  end;

implementation

end.
