{******************************************************************************}
{                                                                              }
{  Módulo:       inLibConfigCamposIntf                                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contrato de consulta de metadatos visuales de campos.                    }
{******************************************************************************}
unit inLibConfigCamposIntf;

interface

function ClaveTituloVisualConfigCampo(
  const ATabla, ACampo: string): string;

type
  IConfiguracionCampos = interface
    ['{6621783C-C7F9-4D80-8B14-3F922E5D5BA2}']
    function GetCargada: Boolean;
    function Existe(
      const ACampo: string;
      const ATabla: string = ''): Boolean;
    function ObtenerTitulo(
      const ACampo: string;
      const ATabla: string = ''): string;
    function ObtenerAncho(
      const ACampo: string;
      const ATabla: string = ''): Integer;
    property Cargada: Boolean read GetCargada;
  end;

  IProveedorConfiguracionCampos = interface
    ['{B47725D5-D059-41F9-A5DF-721280C30229}']
    function GetConfiguracionCampos: IConfiguracionCampos;
    property ConfiguracionCampos: IConfiguracionCampos
      read GetConfiguracionCampos;
  end;

implementation

uses
  System.SysUtils;

function ClaveTituloVisualConfigCampo(
  const ATabla, ACampo: string): string;
begin
  Result := 'fza_config_campos.' +
    LowerCase(Trim(ATabla)) + '.' +
    LowerCase(Trim(ACampo)) + '.TITULO_VISUAL_CC';
end;

end.
