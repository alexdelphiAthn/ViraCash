{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFormatoMonetario                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       20/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Formato visual común para importes monetarios declarados expresamente.    }
{    No modifica el tipo, la escala ni el valor almacenado en los datasets.    }
{******************************************************************************}
unit inLibFormatoMonetario;

interface

uses
  cxCurrencyEdit, cxGridDBTableView;

const
  FORMATO_MONEDA_EURO =
    '#,##0.00 "€";-#,##0.00 "€";0.00 "€"';

procedure FormatearPropiedadesMonetarias(
  APropiedades: TcxCurrencyEditProperties);
procedure FormatearColumnaMonetaria(AColumna: TcxGridDBColumn);

implementation

procedure FormatearPropiedadesMonetarias(
  APropiedades: TcxCurrencyEditProperties);
begin
  if Assigned(APropiedades) then
    APropiedades.DisplayFormat := FORMATO_MONEDA_EURO;
end;

procedure FormatearColumnaMonetaria(AColumna: TcxGridDBColumn);
begin
  if Assigned(AColumna) then
  begin
    if not (AColumna.Properties is TcxCurrencyEditProperties) then
      AColumna.PropertiesClass := TcxCurrencyEditProperties;
    FormatearPropiedadesMonetarias(
      TcxCurrencyEditProperties(AColumna.Properties));
  end;
end;

end.
