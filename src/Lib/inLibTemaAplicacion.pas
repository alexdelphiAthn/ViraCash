{******************************************************************************}
{                                                                              }
{  Módulo:       inLibTemaAplicacion                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       17/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Aplica el skin DevExpress y su paleta (appTema / appPaleta) al arrancar   }
{    y en caliente al guardar los parámetros. TdxSkinController y              }
{    TcxLookAndFeelController delegan en RootLookAndFeel, así que basta con    }
{    cambiarlo ahí para que lo sigan todas las ventanas abiertas.              }
{******************************************************************************}
unit inLibTemaAplicacion;

interface

const
  TEMA_DEFECTO_OSCURO = 'MetropolisDark';
  TEMA_DEFECTO_CLARO = 'Office2007Pink';

/// Tema efectivo: el configurado o, si está vacío, el de defecto según el
/// modo claro u oscuro de Windows.
function ResolverTemaAplicacion(const ATema: string): string;

/// True si el tema o la paleta difieren de los activos.
function TemaAplicacionCambia(const ATema, APaleta: string): Boolean;

/// Aplica tema y paleta a RootLookAndFeel. Una paleta vacía conserva la
/// del skin. Las excepciones de DevExpress (skin inexistente) se propagan.
procedure AplicarTemaAplicacion(const ATema, APaleta: string);

implementation

uses
  System.SysUtils, cxLookAndFeels, inLibWin;

function ResolverTemaAplicacion(const ATema: string): string;
begin
  Result := Trim(ATema);
  if Result = '' then
  begin
    if DarkModeIsEnabled then
      Result := TEMA_DEFECTO_OSCURO
    else
      Result := TEMA_DEFECTO_CLARO;
  end;
end;

function TemaAplicacionCambia(const ATema, APaleta: string): Boolean;
begin
  Result := not SameText(ResolverTemaAplicacion(ATema),
    RootLookAndFeel.SkinName) or
    ((Trim(APaleta) <> '') and
     not SameText(Trim(APaleta), TcxRootLookAndFeel.Instance.SkinPaletteName));
end;

procedure AplicarTemaAplicacion(const ATema, APaleta: string);
var
  sTema: string;
begin
  sTema := ResolverTemaAplicacion(ATema);
  RootLookAndFeel.SkinName := sTema;
  if Trim(APaleta) <> '' then
    TcxRootLookAndFeel.Instance.SkinPaletteName := Trim(APaleta);
end;

end.
