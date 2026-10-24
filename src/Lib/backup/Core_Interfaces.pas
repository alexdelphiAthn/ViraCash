unit Core_Interfaces;

interface

uses System.Classes, Backup.Types, Data.DB;

type
  // Contratos del subsistema de copias segregados por consumidor real:
  // TDBBackupEngine (volcado) y TDBComparerEngine (comparación). Un mismo
  // proveedor implementa varios contratos y cada motor recibe y conserva
  // solo los que usa (libro de estilo §14.2).

  // Lectura de la estructura de la BBDD: identidad, tablas e índices
  ILectorEsquemaBBDD = interface
    ['{3845371E-05F4-4D25-9148-B4E762F1CE02}']
    function GetDatabaseName: string;
    function GetTables: TStringList;
    function GetTableStructure(const TableName: string): TTableInfo;
    function GetTableIndexes(const TableName: string): TArray<TIndexInfo>;
  end;

  // Lectura de objetos programables: vistas, triggers y rutinas
  ILectorObjetosBBDD = interface
    ['{03FF8B8A-4EB4-4473-B18F-BC6AF59B78CE}']
    function GetViews: TStringList;
    function GetViewDefinition(const ViewName: string): string;
    function GetTriggers: TArray<TTriggerInfo>;
    function GetTriggerDefinition(const TriggerName: string): string;
    function GetProcedures: TStringList;
    function GetProcedureDefinition(const ProcedureName: string): string;
    function GetFunctions: TStringList;
    function GetFunctionDefinition(const FunctionName: string): string;
  end;

  // Lectura de datos de tabla para volcado y sincronización
  ILectorDatosBBDD = interface
    ['{DEECC7EE-84D3-41DF-8285-BA7539C28648}']
    function GetData(const TableName: string;
                     const Filter: string = ''): TDataSet;
    function GetRowCount(const TableName: string;
                         const Filter: string = ''): Integer;
  end;

  // Vistas de un mismo proveedor de lectura, inyectadas juntas
  TServiciosLecturaBBDD = record
    Esquema: ILectorEsquemaBBDD;
    Objetos: ILectorObjetosBBDD;
    Datos: ILectorDatosBBDD;
  end;

  // Contrato para escribir el script
  IScriptWriter = interface
    ['{638AC4C1-4AF7-48CF-ACD9-602E3BAC1228}']
    procedure AddComment(const Text: string);
    procedure AddCommand(const SQL: string);
    function GetScript: string;
  end;

  // Comparación de estructuras (lógica mayormente universal)
  IComparadorEsquemaBBDD = interface
    ['{A1224F5C-B3B8-4FDC-9B7B-5FD10E83C3EC}']
    function ColumnsAreEqual(const Col1, Col2: TColumnInfo): Boolean;
    function IndexesAreEqual(const Idx1, Idx2: TIndexInfo): Boolean;
    function TriggersAreEqual(const Trg1, Trg2: TTriggerInfo): Boolean;
  end;

  // Generación SQL de identificadores, valores e inserciones
  IGeneradorSqlValores = interface
    ['{5396E6D4-349A-4EA7-9050-D8395E40067A}']
    function QuoteIdentifier(const Identifier: string): string;
    function ValueToSQL(const Field: TField): string;
    function GenerateInsertSQL(const TableName: string;
                               Fields, Values: TStringList;
                               const HasIdentity: Boolean = False): string;
  end;

  // Generación SQL de creación de objetos (específico de cada motor)
  IGeneradorSqlCreacion = interface
    ['{CBED7ECF-C409-4C43-8541-FF47119B415C}']
    function GenerateCreateTableSQL(const Table: TTableInfo;
                                    const Indexes: TArray<TIndexInfo>):
                                    string;
    function GenerateIndexDefinition(const TableName: string;
                                     const Idx: TIndexInfo): string;
    function GenerarIndicesSecundarios(
      const ANombreTabla: string;
      const AIndices: TArray<TIndexInfo>): string;
    function GenerateCreateViewSQL(const Body: string): string;
    function GenerateCreateTriggerSQL(const Body: string): string;
    function GenerateCreateProcedureSQL(const Body: string): string;
    function GenerateCreateFunctionSQL(const Body: string): string;
  end;

  // Generación SQL de eliminación de objetos
  IGeneradorSqlEliminacion = interface
    ['{4C080460-B459-43E4-9AE9-9C9AF8C09E9A}']
    function GenerateDropTableSQL(const TableName: string): string;
    function GenerateDropColumnSQL(const TableName,
                                   ColumnName: string): string;
    function GenerateDropIndexSQL(const TableName,
                                  IndexName: string): string;
    function GenerateDropTrigger(const Trigger: string): string;
    function GenerateDropView(const View: string): string;
    function GenerateDropProcedure(const Proc: string): string;
    function GenerateDropFunction(const FuncName: string): string;
  end;

  // Generación SQL de modificación de columnas y sincronización de filas
  IGeneradorSqlModificacion = interface
    ['{31B9BBCA-B29F-40A4-988A-6190222ED809}']
    function GenerateAddColumnSQL(const TableName: string;
                                  const ColumnInfo: TColumnInfo): string;
    function GenerateModifyColumnSQL(const TableName: string;
                                     const ColumnInfo: TColumnInfo): string;
    function GenerateUpdateSQL(const TableName: string;
                               const SetClause,
                               WhereClause: string): string;
    function GenerateDeleteSQL(const TableName,
                               WhereClause: string): string;
  end;

  // Vistas de un mismo juego de helpers SQL, inyectadas juntas
  TServiciosSqlBBDD = record
    Comparador: IComparadorEsquemaBBDD;
    Valores: IGeneradorSqlValores;
    Creacion: IGeneradorSqlCreacion;
    Eliminacion: IGeneradorSqlEliminacion;
    Modificacion: IGeneradorSqlModificacion;
  end;

implementation

end.
