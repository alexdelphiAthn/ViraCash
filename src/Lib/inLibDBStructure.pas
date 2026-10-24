{******************************************************************************}
{                                                                              }
{  Módulo:       inLibDBStructure                                              }
{    Tipo:       Librería                                                      }
{ Versión:       2.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Comprueba la estructura mínima sin conocer su acceso ni su presentación. }
{******************************************************************************}
unit inLibDBStructure;

interface

uses
  System.SysUtils,
  inLibDBStructurePersistenciaIntf;

type
  TDBStructureStatus = (
    dbsOK,
    dbsDatabaseNotExists,
    dbsMissingObjects,
    dbsConnectionError
  );

  TDBStructureCheckResult = record
    Status: TDBStructureStatus;
    DatabaseName: string;
    MissingObjects: TArray<string>;
    Error: TErrorLecturaEstructura;
    ErrorMessage: string;
    function IsOK: Boolean;
    function FormattedMessage: string;
  end;

  TDBStructureResultFormatter = class
  public
    class function Formatear(
      const AResultado: TDBStructureCheckResult): string;
  end;

  TDBStructureChecker = class
  public
    class function Check(
      const ARepositorio: IRepositorioEstructuraBBDD;
      const ADatabaseName: string): TDBStructureCheckResult;
  end;

const
  REQUIRED_TABLES: array[0..0] of string = (
    'fza_usuarios'
  );

  REQUIRED_VIEWS: array[0..0] of string = (
    'vi_usuarios'
  );

implementation

uses
  System.Classes;

function TDBStructureCheckResult.IsOK: Boolean;
begin
  Result := Status = dbsOK;
end;

function TDBStructureCheckResult.FormattedMessage: string;
begin
  Result := TDBStructureResultFormatter.Formatear(Self);
end;

class function TDBStructureResultFormatter.Formatear(
  const AResultado: TDBStructureCheckResult): string;
var
  sFaltantes: string;
  sObjeto: string;
begin
  case AResultado.Status of
    dbsOK:
      Result := 'Estructura correcta.';
    dbsDatabaseNotExists:
      Result := Format(
        'La base de datos "%s" no existe en el servidor.',
        [AResultado.DatabaseName]);
    dbsMissingObjects:
      begin
        sFaltantes := '';
        for sObjeto in AResultado.MissingObjects do
        begin
          sFaltantes := sFaltantes +
            '  - ' + sObjeto + sLineBreak;
        end;
        Result := Format(
          'La base de datos "%s" existe, pero faltan los ' +
          'siguientes objetos requeridos:' + sLineBreak + '%s',
          [AResultado.DatabaseName, sFaltantes]);
      end;
    dbsConnectionError:
      Result := 'Error de conexión: ' + AResultado.ErrorMessage;
  else
    Result := 'Estado desconocido.';
  end;
end;

class function TDBStructureChecker.Check(
  const ARepositorio: IRepositorioEstructuraBBDD;
  const ADatabaseName: string): TDBStructureCheckResult;
var
  oFaltantes: TStringList;
  sNombre: string;
begin
  Result := Default(TDBStructureCheckResult);
  Result.DatabaseName := ADatabaseName;
  Result.Status := dbsOK;
  Result.Error := eleNinguno;
  if not Assigned(ARepositorio) then
  begin
    Result.Status := dbsConnectionError;
    Result.Error := eleConexionNoDisponible;
    Result.ErrorMessage :=
      'No se ha configurado el lector de estructura.';
  end
  else
  begin
    try
      if not ARepositorio.ExisteEsquema(ADatabaseName) then
      begin
        Result.Status := dbsDatabaseNotExists;
      end
      else
      begin
        oFaltantes := TStringList.Create;
        try
          for sNombre in REQUIRED_TABLES do
          begin
            if not ARepositorio.ExisteTabla(
              ADatabaseName, sNombre) then
            begin
              oFaltantes.Add('Tabla: ' + sNombre);
            end;
          end;
          for sNombre in REQUIRED_VIEWS do
          begin
            if not ARepositorio.ExisteVista(
              ADatabaseName, sNombre) then
            begin
              oFaltantes.Add('Vista: ' + sNombre);
            end;
          end;
          if oFaltantes.Count > 0 then
          begin
            Result.Status := dbsMissingObjects;
            Result.MissingObjects := oFaltantes.ToStringArray;
          end;
        finally
          FreeAndNil(oFaltantes);
        end;
      end;
    except
      on E: ELecturaEstructuraBBDD do
      begin
        Result.Status := dbsConnectionError;
        Result.Error := E.Error;
        Result.ErrorMessage := E.Message;
      end;
      on E: Exception do
      begin
        Result.Status := dbsConnectionError;
        Result.Error := eleConsultaFallida;
        Result.ErrorMessage := E.ClassName + ': ' + E.Message;
      end;
    end;
  end;
end;

end.
