{******************************************************************************}
{                                                                              }
{  Módulo:       inLibTraduccionesIntf                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos del catálogo de traducciones de la aplicación.                  }
{******************************************************************************}
unit inLibTraduccionesIntf;

interface

uses
  System.Classes;

const
  IDIOMA_ESPANOL = 'es-ES';
  IDIOMA_INGLES = 'en-GB';
  IDIOMA_CATALAN = 'ca-ES';
  IDIOMA_CHINO_SIMPLIFICADO = 'zh-CN';
  IDIOMA_PSEUDO = 'qps-ploc';

type
  IServicioTraducciones = interface
    ['{5E514224-FA34-4E27-AB9B-367E2B8DA9F1}']
    function GetIdioma: string;
    procedure EstablecerIdioma(const AIdioma: string);
    procedure Recargar;
    function ExisteTraduccion(
      const AClave: string): Boolean;
    function Traducir(
      const AClave, ATextoPredeterminado: string): string;
    function TraducirTextoInforme(
      const ATexto: string): string;
    procedure Aplicar(AComponente: TComponent);
    property Idioma: string read GetIdioma;
  end;

  IProveedorTraducciones = interface
    ['{A1B73167-C65E-4B48-A272-59030A6F73C7}']
    function GetTraducciones: IServicioTraducciones;
    property Traducciones: IServicioTraducciones read GetTraducciones;
  end;

implementation

end.
