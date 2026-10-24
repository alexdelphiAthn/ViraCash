{******************************************************************************}
{                                                                              }
{  Módulo:       inLibTraduccionesFastReport                                   }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adapta las etiquetas de idioma de ViraCash a los recursos de FastReport.  }
{******************************************************************************}
unit inLibTraduccionesFastReport;

interface

procedure AplicarIdiomaFastReport(const AIdioma: string);
function ResolverIdiomaFastReport(const AIdioma: string): string;

implementation

uses
  System.SysUtils, frResources, frLanguageCatalon, frLanguageEnglish,
  frLanguageSpanish, frLanguageChinese;

function CodigoBaseIdioma(const AIdioma: string): string;
var
  PosicionGuion: Integer;
begin
  Result := LowerCase(Trim(AIdioma));
  Result := StringReplace(Result, '_', '-', [rfReplaceAll]);
  PosicionGuion := Pos('-', Result);
  if PosicionGuion > 0 then
    Result := Copy(Result, 1, PosicionGuion - 1);
end;

function ResolverIdiomaFastReport(const AIdioma: string): string;
var
  CodigoIdioma: string;
begin
  CodigoIdioma := CodigoBaseIdioma(AIdioma);
  Result := 'Spanish';
  // FastReport denomina internamente "Catalon" al paquete catalán.
  if CodigoIdioma = 'ca' then
    Result := 'Catalon'
  else if CodigoIdioma = 'en' then
    Result := 'English'
  else if CodigoIdioma = 'zh' then
    Result := 'Chinese';
end;

procedure AplicarIdiomaFastReport(const AIdioma: string);
var
  IdiomaFastReport: string;
begin
  IdiomaFastReport := ResolverIdiomaFastReport(AIdioma);
  // Evita conservar literales del usuario anterior si cambia el idioma.
  if not SameText(frStringResources.Language, 'English') then
    frStringResources.Language := 'English';
  frStringResources.Language := IdiomaFastReport;
end;

end.
