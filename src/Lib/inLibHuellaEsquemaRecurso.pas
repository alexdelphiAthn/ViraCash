{******************************************************************************}
{                                                                              }
{  Módulo:       inLibHuellaEsquemaRecurso                                     }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Esquema ideal embebido (recurso RCDATA HUELLA_ESQUEMA). Lo genera         }
{    src\utlEsquemaIdeal\GeneradorEsquemaIdeal.exe a partir del modelo de      }
{    esta versión y lo compila en HuellaEsquema.res.                           }
{******************************************************************************}
unit inLibHuellaEsquemaRecurso;

interface

uses
  inLibHuellaEsquema;

const
  cRecursoHuellaEsquema = 'HUELLA_ESQUEMA';

// nil si el ejecutable no lleva el recurso.
function CargarEsquemaIdeal: TEsquemaIdeal;

implementation

{$R '..\..\HuellaEsquema.res'}

uses
  Winapi.Windows,
  System.Classes,
  System.SysUtils;

function CargarEsquemaIdeal: TEsquemaIdeal;
var
  oRecurso: TResourceStream;
  aBytes: TBytes;
begin
  Result := nil;
  if FindResource(HInstance, cRecursoHuellaEsquema, RT_RCDATA) <> 0 then
  begin
    oRecurso := TResourceStream.Create(HInstance, cRecursoHuellaEsquema,
                                       RT_RCDATA);
    try
      SetLength(aBytes, oRecurso.Size);
      oRecurso.ReadBuffer(aBytes, Length(aBytes));
    finally
      oRecurso.Free;
    end;
    Result := TEsquemaIdeal.Create(TEncoding.UTF8.GetString(aBytes));
  end;
end;

end.
