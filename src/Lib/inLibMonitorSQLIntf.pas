{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMonitorSQLIntf                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos para controlar y alimentar el monitor SQL de la aplicación.     }
{******************************************************************************}
unit inLibMonitorSQLIntf;

interface

type
  TEventoMonitorSQL = (
    emsOtro,
    emsEjecutar,
    emsFinalizar,
    emsError
  );

  IServicioMonitorSQL = interface
    ['{FB84226A-A0DB-4051-BC23-60CB9C4F734E}']
    procedure CerrarPendiente;
    procedure EstablecerActivo(AActivo: Boolean);
    procedure Invalidar;
  end;

  IVisorMonitorSQL = interface
    ['{3CB90DEF-166D-43B6-BF7E-A32E75FB04CA}']
    procedure EstablecerVisible(AVisible: Boolean);
    procedure MostrarSQL(const ASQL: string);
  end;

  IReceptorEventosMonitorSQL = interface
    ['{396FC465-A289-4D2D-97B6-3B3DEFF5C5D9}']
    procedure ProcesarEvento(
      const ATexto: string;
      AEvento: TEventoMonitorSQL
    );
  end;

  IRegistroMonitorSQL = interface
    ['{716A1EF6-286A-4A85-B270-30C223DDF33D}']
    function GetMonitorizacionActiva: Boolean;
    procedure EstablecerVisible(AVisible: Boolean);
    procedure Invalidar;
    procedure RegistrarSQL(
      const ASQL: string;
      ATiempoMs: Int64;
      AOk: Boolean;
      const AError: string
    );
    procedure MostrarSQL(const ASQL: string);
    property MonitorizacionActiva: Boolean
      read GetMonitorizacionActiva;
  end;

  IProveedorMonitorSQL = interface
    ['{E12FADDD-FD2B-4C85-A9C5-CE08B87416EC}']
    function GetMonitorSQL: IServicioMonitorSQL;
    property MonitorSQL: IServicioMonitorSQL read GetMonitorSQL;
  end;

implementation

end.
