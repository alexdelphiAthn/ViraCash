{******************************************************************************}
{                                                                              }
{  Módulo:       inLibActualizacionScriptsLectura                              }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       18/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Interpreta la salida de comprobar_scripts_aplicados.sql sin depender      }
{    del driver de base de datos.                                              }
{******************************************************************************}
unit inLibActualizacionScriptsLectura;

interface

uses
  Data.DB;

const
  cEstadoScriptFalta = '>>> FALTA <<<';
  cCampoOrdenScriptComprobacion = 'orden_aplicacion';
  cCampoNombreScriptComprobacion = 'script';
  cCampoEstadoScriptComprobacion = 'estado';
  cCampoObjetoScriptComprobacion = 'objeto';

type
  TScriptFaltante = record
    Nombre: string;
    Orden: Integer;
    Objeto: string;
  end;

// Recorre el resultado de la comprobación y se queda con las filas
// marcadas como pendientes, en el orden de aplicación.
function LeerScriptsFaltantes(ADataSet: TDataSet): TArray<TScriptFaltante>;
// Deja el contenido de un script listo para el cuadro de la ventana del
// proceso: saltos de línea de Windows (un .sql puede traerlos de Unix y
// se vería todo en una línea) y recorte de los muy largos.
function TextoScriptParaVentana(const AContenido: string): string;

implementation

uses
  System.Generics.Collections,
  System.Generics.Defaults,
  System.SysUtils,
  inLibMsgIntegraciones;

const
  // Lo que se enseña del script: el cuadro de texto de Windows no admite
  // cualquier tamaño y tampoco hay nada que leer más allá.
  cMaximoTextoScriptVentana = 20000;

function TextoScriptParaVentana(const AContenido: string): string;
begin
  Result := AdjustLineBreaks(AContenido);
  if Length(Result) > cMaximoTextoScriptVentana then
    Result := Copy(Result, 1, cMaximoTextoScriptVentana) + sLineBreak +
      SAvisoTextoScriptRecortado;
end;

function TextoCampo(ADataSet: TDataSet; const ANombre: string): string;
var
  oCampo: TField;
begin
  Result := '';
  oCampo := ADataSet.FindField(ANombre);
  if Assigned(oCampo) then
    Result := Trim(oCampo.AsString);
end;

function EnteroCampo(ADataSet: TDataSet; const ANombre: string): Integer;
var
  oCampo: TField;
begin
  Result := 0;
  oCampo := ADataSet.FindField(ANombre);
  if Assigned(oCampo) then
    Result := StrToIntDef(Trim(oCampo.AsString), 0);
end;

function LeerScriptsFaltantes(ADataSet: TDataSet): TArray<TScriptFaltante>;
var
  oFaltantes: TList<TScriptFaltante>;
  Faltante: TScriptFaltante;
begin
  oFaltantes := TList<TScriptFaltante>.Create;
  try
    if Assigned(ADataSet) and ADataSet.Active then
    begin
      ADataSet.First;
      while not ADataSet.Eof do
      begin
        if SameText(
             TextoCampo(ADataSet, cCampoEstadoScriptComprobacion),
             cEstadoScriptFalta) then
        begin
          Faltante.Nombre := TextoCampo(
            ADataSet, cCampoNombreScriptComprobacion);
          Faltante.Orden := EnteroCampo(
            ADataSet, cCampoOrdenScriptComprobacion);
          Faltante.Objeto := TextoCampo(
            ADataSet, cCampoObjetoScriptComprobacion);
          if Faltante.Nombre <> '' then
            oFaltantes.Add(Faltante);
        end;
        ADataSet.Next;
      end;
    end;
    oFaltantes.Sort(
      TComparer<TScriptFaltante>.Construct(
        function(const AUno, AOtro: TScriptFaltante): Integer
        begin
          Result := AUno.Orden - AOtro.Orden;
          if Result = 0 then
            Result := CompareText(AUno.Nombre, AOtro.Nombre);
        end));
    Result := oFaltantes.ToArray;
  finally
    oFaltantes.Free;
  end;
end;

end.
