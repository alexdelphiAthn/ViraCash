{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPreviewExcel                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contrato neutral para preparar y mostrar una hoja de cálculo.             }
{    La implementación visual se recibe desde la raíz de composición.          }
{******************************************************************************}
unit inLibPreviewExcel;

interface

uses
  System.Classes, Vcl.Forms, dxSpreadSheet;

type
  TSesionPreviewExcel = class
  public
    function HojaCalculo: TdxSpreadSheet; virtual; abstract;
    procedure AsignarPopupParent(APadre: TCustomForm); virtual; abstract;
    procedure AsignarNombreArchivo(const ANombre: string); virtual; abstract;
    procedure Mostrar; virtual; abstract;
  end;

  IProveedorPreviewExcel = interface
    ['{B6B9601C-1F3E-465A-8E1A-6265F1E944F4}']
    function Crear(AOwner: TComponent): TSesionPreviewExcel;
  end;
  IContenedorProveedorPreviewExcel = interface
    ['{EB1C2E9E-C719-49FF-AB7F-D6224C283837}']
    function GetProveedorPreviewExcel: IProveedorPreviewExcel;
    property ProveedorPreviewExcel: IProveedorPreviewExcel
      read GetProveedorPreviewExcel;
  end;

implementation

end.
