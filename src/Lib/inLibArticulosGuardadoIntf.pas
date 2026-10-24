{******************************************************************************}
{                                                                              }
{  Modulo:       inLibArticulosGuardadoIntf                                    }
{    Tipo:       Contrato                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Puertos del guardado coordinado de articulo, propiedades y variaciones.   }
{******************************************************************************}
unit inLibArticulosGuardadoIntf;

interface

uses
  System.SysUtils;

type
  TCampoValidacionArticulo = (cvaNombre, cvaFamilia, cvaTrazabilidad);

  EValidacionDatosArticulo = class(Exception)
  private
    FCampo: TCampoValidacionArticulo;
  public
    constructor Create(ACampo: TCampoValidacionArticulo;
      const AMensaje: string);
    property Campo: TCampoValidacionArticulo read FCampo;
  end;

  TNotificarValidacionArticulo = procedure(const AMensaje: string;
    ACampo: TCampoValidacionArticulo) of object;

  TErrorGuardadoArticulo = (
    egaNinguno,
    egaRevisionPropiedades,
    egaGuardadoPropiedades,
    egaGuardadoVariaciones);

  TResultadoGuardadoArticulo = record
    Error: TErrorGuardadoArticulo;
    Mensaje: string;
  end;

  IOperacionesGuardadoArticulo = interface
    ['{CD72F0BF-B2DC-446D-A9C0-F87FB5D45353}']
    function ValidarPropiedades: string;
    function GuardarPropiedades(out AMensajeError: string): Boolean;
    procedure GuardarEdicionesPendientes;
    function GuardarVariaciones(out AMensajeError: string): Boolean;
  end;

  IAplicacionGuardadoArticulo = interface
    ['{65043F31-790D-4640-9CC9-4CE62250920A}']
    function Ejecutar: TResultadoGuardadoArticulo;
  end;

implementation

constructor EValidacionDatosArticulo.Create(ACampo: TCampoValidacionArticulo;
  const AMensaje: string);
begin
  inherited Create(AMensaje);
  FCampo := ACampo;
end;

end.
