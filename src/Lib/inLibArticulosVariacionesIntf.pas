{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArticulosVariacionesIntf                                 }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Puerto de variaciones y SKU de artículos.                                }
{******************************************************************************}
unit inLibArticulosVariacionesIntf;

interface

uses
  Vcl.Forms;

type
  ILecturaSkuArticulosVariaciones = interface
    ['{F2E5D165-676C-4E8D-B136-273BF1AA1EBE}']
    function EsArticuloConVariaciones(
      const ACodigoArticulo: string): Boolean;
    function TieneSku(
      const ACodigoArticulo: string): Boolean;
    function TieneSkuActivo(
      const ACodigoArticulo: string): Boolean;
    function TieneSkuBase(
      const ACodigoArticulo: string): Boolean;
  end;
  IEscrituraSkuArticulosVariaciones = interface
    ['{B64A36F4-C11B-40D4-9DF1-5D5509409DFC}']
    procedure AsegurarSkuSinVariaciones(
      const ACodigoArticulo, AUsuario: string);
    procedure AsegurarSkuActivo(
      const ACodigoArticulo, AUsuario: string);
  end;
  IGestorArticulosVariaciones = interface
    ['{BBF0B749-B893-423C-A356-D0C5F8AC705E}']
    procedure CargarVariaciones(const ACodigoArticulo: string);
    // Pinta los selectores de tallaje del tipo de variación que tiene la
    // ficha en pantalla, aunque el artículo aún no esté grabado (alta) o
    // el tipo se acabe de cambiar. Conserva lo elegido en cada atributo.
    procedure MostrarTipoVariacion(
      const ACodigoArticulo, ATipoVariacion: string);
    // Código con el que se graban las asignaciones (en un alta no se
    // conoce hasta hacer Post de la ficha).
    procedure AsignarCodigoArticulo(const ACodigoArticulo: string);
    function GuardarVariaciones: Boolean;
    function Validar: string;
    function ObtenerCodigoArticulo: string;
    function EstaModificado: Boolean;
    procedure ActualizarIdioma;
  end;
  IArticulosVariaciones = interface
    ['{2E1F381A-45D1-4206-BF82-111CFDE2999B}']
    procedure AsegurarSkuSinVariaciones(
      const ACodigoArticulo, AUsuario: string);
    procedure AsegurarSkuActivo(
      const ACodigoArticulo, AUsuario: string);
    function TieneSkuActivo(
      const ACodigoArticulo: string): Boolean;
    function CrearGestor(
      APanelAtributos: TScrollBox;
      const AUsuario: string): IGestorArticulosVariaciones;
  end;

implementation
end.
