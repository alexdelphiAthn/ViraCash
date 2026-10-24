{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFormatoExcel                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       25/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Formato de guardado de hojas de cálculo elegido por el usuario en         }
{    Parámetros Generales (clave appFormatoHojaCalculo). Lo consumen el        }
{    preview de plantilla (SaveToFile por extensión) y el export de grid       }
{    (ExportGridTo*). Solo xls/xlsx: ambos conservan imágenes y abren en       }
{    Excel y LibreOffice. CSV se descarta (pierde las fotos); DevExpress no    }
{    exporta ODS (solo lo importa). Sin dependencia de DevExpress.             }
{******************************************************************************}
unit inLibFormatoExcel;

interface

type
  TFormatoExcel = (feXlsx, feXls);

const
  CLAVE_FORMATO_EXCEL   = 'appFormatoHojaCalculo';
  VALOR_FORMATO_DEFECTO = 'xlsx';

// Interpreta el valor guardado del parámetro (xlsx / xls).
function FormatoExcelDesde(const AValor: string): TFormatoExcel;
// Extensión sin punto: 'xlsx' / 'xls'.
function ExtensionFormato(AFormato: TFormatoExcel): string;
// Filtro para el diálogo de guardar.
function FiltroGuardar(AFormato: TFormatoExcel): string;

implementation

uses
  System.SysUtils;

function FormatoExcelDesde(const AValor: string): TFormatoExcel;
begin
  if SameText(AValor, 'xls') then
    Result := feXls
  else
    Result := feXlsx;
end;

function ExtensionFormato(AFormato: TFormatoExcel): string;
begin
  if AFormato = feXls then
    Result := 'xls'
  else
    Result := 'xlsx';
end;

function FiltroGuardar(AFormato: TFormatoExcel): string;
begin
  if AFormato = feXls then
    Result := 'Excel 97 (*.xls)|*.xls'
  else
    Result := 'Libro de Excel (*.xlsx)|*.xlsx';
end;

end.
