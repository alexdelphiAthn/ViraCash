{******************************************************************************}
{                                                                              }
{  Módulo:       inLibLecturaGs1Pendiente                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       07/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    F-LOTEC-012: lote, serie y caducidad del último GS1 resuelto. Un GS1      }
{    tecleado o leído sin la trama del lector entra por la rejilla, que solo   }
{    aplica el artículo; al grabar esa línea (mismo SKU, sin lote) los         }
{    documentos y la caja toman de aquí lo leído en vez de decidir el lote.    }
{    Se consume una vez y caduca a los SEGUNDOS_VIGENCIA_GS1 segundos.         }
{******************************************************************************}
unit inLibLecturaGs1Pendiente;

interface

const
  SEGUNDOS_VIGENCIA_GS1 = 30;

type
  TLecturaGs1Pendiente = record
    CodigoSku: string;
    Lote: string;
    Serie: string;
    FechaCaducidad: TDate;
    Instante: TDateTime;
  end;

// La anota el validador de artículos al resolver un GS1 con lote o serie.
procedure AnotarLecturaGs1(const ACodigoSku, ALote, ASerie: string;
  AFechaCaducidad: TDate);
// Si la última lectura es de ASku y sigue vigente, la devuelve y la
// consume. AAhora se inyecta en las pruebas.
function TomarLecturaGs1(const ACodigoSku: string;
  out ALectura: TLecturaGs1Pendiente): Boolean; overload;
function TomarLecturaGs1(const ACodigoSku: string; AAhora: TDateTime;
  out ALectura: TLecturaGs1Pendiente): Boolean; overload;
procedure DescartarLecturaGs1;

implementation

uses
  System.SysUtils, System.DateUtils;

var
  GLectura: TLecturaGs1Pendiente;

procedure AnotarLecturaGs1(const ACodigoSku, ALote, ASerie: string;
  AFechaCaducidad: TDate);
begin
  GLectura := Default(TLecturaGs1Pendiente);
  if (Trim(ACodigoSku) <> '') and
     ((Trim(ALote) <> '') or (Trim(ASerie) <> '')) then
  begin
    GLectura.CodigoSku := Trim(ACodigoSku);
    GLectura.Lote := Trim(ALote);
    GLectura.Serie := Trim(ASerie);
    GLectura.FechaCaducidad := AFechaCaducidad;
    GLectura.Instante := Now;
  end;
end;

function TomarLecturaGs1(const ACodigoSku: string; AAhora: TDateTime;
  out ALectura: TLecturaGs1Pendiente): Boolean;
begin
  ALectura := Default(TLecturaGs1Pendiente);
  Result := (GLectura.CodigoSku <> '') and
    SameText(GLectura.CodigoSku, Trim(ACodigoSku)) and
    (AAhora >= GLectura.Instante) and
    (SecondsBetween(AAhora, GLectura.Instante) <= SEGUNDOS_VIGENCIA_GS1);
  if Result then
  begin
    ALectura := GLectura;
    DescartarLecturaGs1;
  end;
end;

function TomarLecturaGs1(const ACodigoSku: string;
  out ALectura: TLecturaGs1Pendiente): Boolean;
begin
  Result := TomarLecturaGs1(ACodigoSku, Now, ALectura);
end;

procedure DescartarLecturaGs1;
begin
  GLectura := Default(TLecturaGs1Pendiente);
end;

end.
