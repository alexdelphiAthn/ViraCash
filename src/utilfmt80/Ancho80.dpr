{******************************************************************************}
{                                                                              }
{  Módulo:       Ancho80                                                       }
{    Tipo:       Utilidad de consola                                           }
{ Versión:       1.0.0                                                         }
{   Fecha:       12/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    CLI sobre el motor UFmt80. Reformatea ficheros .pas para que ninguna      }
{    línea pase de 80 columnas, aplicando reglas Pascal-aware (comentarios,    }
{    listas, paréntesis, strings).                                             }
{                                                                              }
{    Uso:                                                                      }
{      Ancho80 [-n] <fichero.pas> [<fichero2.pas> ...]                         }
{      Ancho80 [-n] -r <directorio>                                            }
{                                                                              }
{      -n : modo simulación (no escribe)                                       }
{      -r : recursivo sobre directorio                                         }
{                                                                              }
{    Compilable con Delphi y con Free Pascal (`fpc Ancho80.dpr`).              }
{******************************************************************************}

program Ancho80;

{$APPTYPE CONSOLE}
{$IFDEF FPC}
  {$mode Delphi}{$H+}
{$ENDIF}

uses
  SysUtils,
  Classes,
  UFmt80 in 'UFmt80.pas';

var
  GTotalCambios   : Integer = 0;
  GTotalPendientes: Integer = 0;
  GFicheros       : Integer = 0;
  GSimulacion     : Boolean = False;
  GRecursivo      : Boolean = False;


procedure ProcesarFichero(const ARuta: AnsiString);
var
  c, p: Integer;
begin
  ReformatearPas(ARuta, c, p, GSimulacion);
  if (c > 0) or (p > 0) then
    WriteLn(Format('%s : cambios=%d  pendientes=%d', [ARuta, c, p]));
  Inc(GTotalCambios, c);
  Inc(GTotalPendientes, p);
  Inc(GFicheros);
end;


procedure ProcesarDirectorio(const ADir: AnsiString);
var
  sr: TSearchRec;
  ruta: AnsiString;
begin
  // Subdirectorios
  if FindFirst(IncludeTrailingPathDelimiter(string(ADir)) + '*',
               faDirectory, sr) = 0 then
  begin
    repeat
      if ((sr.Attr and faDirectory) <> 0)
         and (sr.Name <> '.') and (sr.Name <> '..') then
      begin
        ruta := IncludeTrailingPathDelimiter(string(ADir))
                + AnsiString(sr.Name);
        ProcesarDirectorio(ruta);
      end;
    until FindNext(sr) <> 0;
    FindClose(sr);
  end;
  // Ficheros .pas
  if FindFirst(IncludeTrailingPathDelimiter(string(ADir)) + '*.pas',
               faAnyFile, sr) = 0 then
  begin
    repeat
      if (sr.Attr and faDirectory) = 0 then
      begin
        ruta := IncludeTrailingPathDelimiter(string(ADir))
                + AnsiString(sr.Name);
        ProcesarFichero(ruta);
      end;
    until FindNext(sr) <> 0;
    FindClose(sr);
  end;
end;


procedure MostrarAyuda;
begin
  WriteLn('Ancho80 1.0.0 - reformatea .pas a 80 columnas');
  WriteLn;
  WriteLn('Uso:');
  WriteLn('  Ancho80 [-n] <fichero.pas> [<fichero2.pas> ...]');
  WriteLn('  Ancho80 [-n] -r <directorio>');
  WriteLn;
  WriteLn('Opciones:');
  WriteLn('  -n  Simulación (no escribe nada)');
  WriteLn('  -r  Recursivo sobre el directorio');
end;


var
  i: Integer;
  arg: AnsiString;
  args: array of AnsiString;
begin
  if ParamCount = 0 then
  begin
    MostrarAyuda;
    Halt(1);
  end;
  SetLength(args, 0);
  for i := 1 to ParamCount do
  begin
    arg := AnsiString(ParamStr(i));
    if arg = '-n' then GSimulacion := True
    else if arg = '-r' then GRecursivo := True
    else if (arg = '-h') or (arg = '--help') then
    begin
      MostrarAyuda;
      Halt(0);
    end
    else
    begin
      SetLength(args, Length(args) + 1);
      args[High(args)] := arg;
    end;
  end;

  if GRecursivo then
  begin
    for i := 0 to High(args) do
      if DirectoryExists(string(args[i])) then
        ProcesarDirectorio(args[i])
      else
        WriteLn('Ignorado (no es directorio): ', args[i]);
  end
  else
  begin
    for i := 0 to High(args) do
      if FileExists(string(args[i])) then
        ProcesarFichero(args[i])
      else
        WriteLn('Ignorado (no existe): ', args[i]);
  end;

  WriteLn;
  WriteLn(Format('TOTAL : ficheros=%d  cambios=%d  pendientes=%d',
                 [GFicheros, GTotalCambios, GTotalPendientes]));
end.
