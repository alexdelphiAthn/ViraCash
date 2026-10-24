{******************************************************************************}
{                                                                              }
{  Módulo:       inLibRecursoRcdata                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Escribe un fichero .res de 32 bits con un único recurso RCDATA, el        }
{    mismo formato que deja brcc32, para enlazarlo con la directiva $R.        }
{******************************************************************************}
unit inLibRecursoRcdata;

interface

uses
  System.SysUtils;

// Formato .res: una entrada vacía de 32 bytes y después, por recurso,
// cabecera (tamaños, tipo, nombre en UTF-16, atributos) y datos, todo
// alineado a 4 bytes.
function BytesRecursoRcdata(
  const ANombre: string;
  const ADatos: TBytes): TBytes;
procedure EscribirRecursoRcdata(
  const ARuta, ANombre: string;
  const ADatos: TBytes);

implementation

uses
  System.Classes,
  System.IOUtils;

const
  cTipoRcdata = 10;
  // MOVEABLE | PURE, como brcc32.
  cMemoriaRecurso = $0030;

procedure EscribirPalabra(AFlujo: TStream; AValor: Word);
begin
  AFlujo.WriteBuffer(AValor, SizeOf(AValor));
end;

procedure EscribirDoble(AFlujo: TStream; AValor: Cardinal);
begin
  AFlujo.WriteBuffer(AValor, SizeOf(AValor));
end;

procedure Alinear(AFlujo: TStream);
const
  cCero: Byte = 0;
begin
  while AFlujo.Position mod 4 <> 0 do
    AFlujo.WriteBuffer(cCero, 1);
end;

procedure EscribirEntradaVacia(AFlujo: TStream);
begin
  EscribirDoble(AFlujo, 0);
  EscribirDoble(AFlujo, 32);
  EscribirPalabra(AFlujo, $FFFF);
  EscribirPalabra(AFlujo, 0);
  EscribirPalabra(AFlujo, $FFFF);
  EscribirPalabra(AFlujo, 0);
  EscribirDoble(AFlujo, 0);
  EscribirPalabra(AFlujo, 0);
  EscribirPalabra(AFlujo, 0);
  EscribirDoble(AFlujo, 0);
  EscribirDoble(AFlujo, 0);
end;

function BytesRecursoRcdata(
  const ANombre: string;
  const ADatos: TBytes): TBytes;
var
  oFlujo: TBytesStream;
  aBytesNombre: TBytes;
  iCabecera: Integer;
begin
  // Nombre en mayúsculas y UTF-16 con su cero final, alineado a 4.
  aBytesNombre := TEncoding.Unicode.GetBytes(UpperCase(ANombre) + #0);
  // SetLength rellena con ceros.
  SetLength(aBytesNombre, (Length(aBytesNombre) + 3) div 4 * 4);
  iCabecera := 8 + 4 + Length(aBytesNombre) + 16;
  oFlujo := TBytesStream.Create;
  try
    EscribirEntradaVacia(oFlujo);
    EscribirDoble(oFlujo, Length(ADatos));
    EscribirDoble(oFlujo, iCabecera);
    EscribirPalabra(oFlujo, $FFFF);
    EscribirPalabra(oFlujo, cTipoRcdata);
    oFlujo.WriteBuffer(aBytesNombre, Length(aBytesNombre));
    EscribirDoble(oFlujo, 0);
    EscribirPalabra(oFlujo, cMemoriaRecurso);
    EscribirPalabra(oFlujo, 0);
    EscribirDoble(oFlujo, 0);
    EscribirDoble(oFlujo, 0);
    if Length(ADatos) > 0 then
      oFlujo.WriteBuffer(ADatos, Length(ADatos));
    Alinear(oFlujo);
    Result := Copy(oFlujo.Bytes, 0, oFlujo.Size);
  finally
    oFlujo.Free;
  end;
end;

procedure EscribirRecursoRcdata(
  const ARuta, ANombre: string;
  const ADatos: TBytes);
begin
  TFile.WriteAllBytes(ARuta, BytesRecursoRcdata(ANombre, ADatos));
end;

end.
