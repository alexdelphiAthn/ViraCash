{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturaePersistenciaIntf                                 }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Puerto de persistencia para generar documentos Facturae.                  }
{******************************************************************************}
unit inLibFacturaePersistenciaIntf;

interface

uses
  System.SysUtils, Data.DB;

type
  // Los TDataSet devueltos pertenecen al llamador.
  IRepositorioFacturae = interface
    ['{638FC93B-8CA4-4BA6-9E08-AE53F94795D2}']
    procedure CargarCertificadoEmpresa(
      const ACodigoEmpresa: string;
      out ASerial, ATitular: string);
    function BuscarCabecera(
      const ASerie, ANumero: string): TDataSet;
    function BuscarLineas(
      const ASerie, ANumero: string): TDataSet;
    procedure GuardarXml(
      const ASerie, ANumero, AUsuario, AXml: string);
  end;
implementation
end.
