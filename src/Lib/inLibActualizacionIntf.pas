{******************************************************************************}
{                                                                              }
{  Módulo:       inLibActualizacionIntf                                        }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       18/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Tipos y contrato del servicio de actualizaciones de la aplicación.        }
{******************************************************************************}
unit inLibActualizacionIntf;

interface

const
  cCompresionActualizacionNinguna = 'ninguna';
  cCompresionActualizacionZip = 'zip';
  cTipoActualizacionEjecutable = 'ejecutable';
  cTipoActualizacionAuxiliar = 'auxiliar';
  cTipoActualizacionComprobacion = 'comprobacion';
  cTipoActualizacionScript = 'script';
  cTipoActualizacionRollback = 'rollback';
  cTipoActualizacionModelo = 'modelo';
  cTipoActualizacionComparador = 'comparador';

type
  // Un fichero publicado. El contenido lógico (Nombre, Tamano, Sha256) es
  // lo que acaba en disco; la entrega (Archivo, TamanoDescarga,
  // Sha256Descarga) es lo que viaja y puede venir comprimida.
  TEntradaActualizacion = record
    Nombre: string;
    Archivo: string;
    Compresion: string;
    Tamano: Int64;
    Sha256: string;
    TamanoDescarga: Int64;
    Sha256Descarga: string;
    function Declarada: Boolean;
    function VieneComprimida: Boolean;
  end;

  TScriptActualizacion = record
    Entrada: TEntradaActualizacion;
    Orden: Integer;
    Rollback: TEntradaActualizacion;
    // Scripts que tienen que aplicarse antes que este (la línea
    // «-- @requiere:» de su cabecera). Mandan sobre Orden.
    Requiere: TArray<string>;
  end;

  TManifiestoActualizacion = record
    Ok: Boolean;
    Mensaje: string;
    HayVersion: Boolean;
    HayActualizacion: Boolean;
    Version: string;
    Fecha: string;
    Notas: string;
    Arquitectura: string;
    Ejecutable: TEntradaActualizacion;
    Auxiliares: TArray<TEntradaActualizacion>;
    Comprobacion: TEntradaActualizacion;
    Scripts: TArray<TScriptActualizacion>;
    // Actualización por comparación: el modelo de la versión (volcado de
    // ViraCash) y DBComparer.exe. Opcionales: una versión puede no traerlos.
    Modelo: TEntradaActualizacion;
    Comparador: TEntradaActualizacion;
    function BuscarScript(
      const ANombre: string;
      out AScript: TScriptActualizacion): Boolean;
    function ComparacionDisponible: Boolean;
  end;

  TProgresoActualizacion = reference to procedure(
    const ATexto: string;
    APorcentaje: Integer);

  IServicioActualizaciones = interface
    ['{7B1C4C52-1F1D-4B2E-9E2B-6C9A0D3F5A11}']
    function Configurado: Boolean;
    function ConsultarUltima(
      const AVersionInstalada: string): TManifiestoActualizacion;
    // Descarga la entrada, la descomprime si hace falta y comprueba su
    // huella antes de dejarla en ARutaDestino.
    function DescargarEntrada(
      const AVersion, ATipo: string;
      const AEntrada: TEntradaActualizacion;
      const ARutaDestino: string;
      out AError: string): Boolean;
  end;

function ArquitecturaActualizacionActual: string;

implementation

uses
  System.SysUtils;

function ArquitecturaActualizacionActual: string;
begin
{$IFDEF WIN64}
  Result := 'win64';
{$ELSE}
  Result := 'win32';
{$ENDIF}
end;

{ TEntradaActualizacion }

function TEntradaActualizacion.Declarada: Boolean;
begin
  Result := (Trim(Nombre) <> '') and (Trim(Archivo) <> '') and
    (Length(Trim(Sha256)) = 64) and (Tamano > 0);
end;

function TEntradaActualizacion.VieneComprimida: Boolean;
begin
  Result := SameText(Trim(Compresion), cCompresionActualizacionZip);
end;

{ TManifiestoActualizacion }

function TManifiestoActualizacion.ComparacionDisponible: Boolean;
begin
  Result := Modelo.Declarada and Comparador.Declarada;
end;

function TManifiestoActualizacion.BuscarScript(
  const ANombre: string;
  out AScript: TScriptActualizacion): Boolean;
var
  iIndice: Integer;
begin
  Result := False;
  AScript := Default(TScriptActualizacion);
  for iIndice := Low(Scripts) to High(Scripts) do
  begin
    if not Result and SameText(Scripts[iIndice].Entrada.Nombre, ANombre) then
    begin
      AScript := Scripts[iIndice];
      Result := True;
    end;
  end;
end;

end.
