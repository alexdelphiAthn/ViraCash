{******************************************************************************}
{                                                                              }
{  Módulo:       inLibTraducValidacion                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Comprueba los marcadores de Format de los textos traducidos.              }
{******************************************************************************}
unit inLibTraducValidacion;

interface

function FirmaMarcadoresFormato(const ATexto: string): string;
function MarcadoresFormatoCompatibles(
  const ATextoOrigen, ATextoDestino: string): Boolean;

implementation

uses
  System.Classes, System.SysUtils;

function EsModificadorMarcador(ACaracter: Char): Boolean;
begin
  Result :=
    CharInSet(ACaracter, ['0'..'9']) or
    CharInSet(ACaracter, [':', '-', '.']);
end;

function EsTipoMarcador(ACaracter: Char): Boolean;
begin
  Result := CharInSet(
    UpCase(ACaracter),
    ['D', 'U', 'E', 'F', 'G', 'N', 'M', 'P', 'S', 'X']);
end;

function FirmaMarcadoresFormato(const ATexto: string): string;
var
  Caracter: Char;
  Indice: Integer;
  IndiceArgumento: Integer;
  IndiceExplicito: Integer;
  InicioIndice: Integer;
  PosicionTipo: Integer;
  SiguienteArgumento: Integer;
  Firma: TStringList;
begin
  Result := '';
  Indice := 1;
  SiguienteArgumento := 0;
  Firma := TStringList.Create;
  try
    Firma.Sorted := True;
    while Indice <= Length(ATexto) do
    begin
      if ATexto[Indice] = '%' then
      begin
        if (Indice < Length(ATexto)) and
           (ATexto[Indice + 1] = '%') then
          Inc(Indice, 2)
        else
        begin
          PosicionTipo := Indice + 1;
          while (PosicionTipo <= Length(ATexto)) and
                EsModificadorMarcador(ATexto[PosicionTipo]) do
            Inc(PosicionTipo);
          if (PosicionTipo <= Length(ATexto)) and
             EsTipoMarcador(ATexto[PosicionTipo]) then
          begin
            IndiceArgumento := SiguienteArgumento;
            InicioIndice := Indice + 1;
            IndiceExplicito := InicioIndice;
            while (IndiceExplicito < PosicionTipo) and
                  CharInSet(
                    ATexto[IndiceExplicito],
                    ['0'..'9']) do
              Inc(IndiceExplicito);
            if (IndiceExplicito < PosicionTipo) and
               (ATexto[IndiceExplicito] = ':') and
               TryStrToInt(
                 Copy(
                   ATexto,
                   InicioIndice,
                   IndiceExplicito - InicioIndice),
                 IndiceArgumento) then
              SiguienteArgumento := IndiceArgumento + 1
            else
              Inc(SiguienteArgumento);
            Caracter := UpCase(ATexto[PosicionTipo]);
            Firma.Add(
              Format(
                '%.8d:%s',
                [IndiceArgumento, string(Caracter)]));
            Indice := PosicionTipo + 1;
          end
          else
            Inc(Indice);
        end
      end
      else
        Inc(Indice);
    end;
    Result := StringReplace(
      Firma.Text,
      sLineBreak,
      ';',
      [rfReplaceAll]);
  finally
    Firma.Free;
  end;
end;

function MarcadoresFormatoCompatibles(
  const ATextoOrigen, ATextoDestino: string): Boolean;
begin
  Result :=
    FirmaMarcadoresFormato(ATextoOrigen) =
    FirmaMarcadoresFormato(ATextoDestino);
end;

end.
