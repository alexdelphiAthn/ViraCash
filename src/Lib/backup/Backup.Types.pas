{******************************************************************************}
{                                                                              }
{  Módulo:       Backup.Types                                                  }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Tipos compartidos por la generación y restauración de copias.             }
{******************************************************************************}
unit Backup.Types;

interface


uses
  System.Classes, System.Generics.Collections, System.SysUtils;

type
  TConfiguracionConexionBackup = record
    Host: string;
    Puerto: Integer;
    BaseDatos: string;
    Usuario: string;
    Contrasena: string;
    TimeoutConexionSeg: Integer;
    TimeoutComandoSeg: Integer;
  end;

  TBackupOptions = record
    WithData: Boolean;              // Incluir datos o solo estructura
    WithTriggers: Boolean;          // Incluir triggers
    WithProcedures: Boolean;        // Incluir procedimientos
    WithFunctions: Boolean;         // Incluir funciones
    WithViews: Boolean;             // Incluir vistas
    DropTablesFirst: Boolean;       // Incluir DROP TABLE antes de CREATE
    UseTransactions: Boolean;       // Envolver en BEGIN/COMMIT
    ExtendedInsert: Boolean;      // << NUEVO: un INSERT con todos los VALUES
    ExtendedInsertRows: Integer;
  end;

  TColumnInfo = record  // O class, según tu implementación actual
    ColumnName: string;
    DataType: string;
    IsNullable: string;
    ColumnKey: string;
    Extra: string;
    ColumnDefault: string;
    CharMaxLength: string;
    ColumnComment: string;
  end;

  TTableInfo = class
    TableName: string;
    Columns: TList<TColumnInfo>;
    constructor Create;
    destructor Destroy; override;
  end;

  // Información de una columna dentro de un índice
  TIndexColumn = record
    ColumnName: string;
    SeqInIndex: Integer;
  end;

  // Información de un índice completo (contiene un array de TIndexColumn)
  TIndexInfo = record
    IndexName: string;
    IsPrimary: Boolean;
    IsUnique: Boolean;
    Columns: TArray<TIndexColumn>;
  end;

  // Información de un trigger
  TTriggerInfo = record
    TriggerName: string;
    EventManipulation: string; // ej. INSERT, UPDATE, DELETE
    ActionTiming: string;      // ej. BEFORE, AFTER
    ActionStatement: string;   // El cuerpo del trigger
    EventObjectTable: string;  // La tabla a la que pertenece
  end;

implementation

{ TTableInfo }

constructor TTableInfo.Create;
begin
  inherited Create;
  Columns := TList<TColumnInfo>.Create;
end;

destructor TTableInfo.Destroy;
begin
  FreeAndNil(Columns);
  inherited Destroy;
end;

end.
