unit Core_Engine;

interface

uses Backup.Types, System.Classes, Core_Interfaces,
     Generics.Collections, Data.DB;

type
  TRes = class
  public
    const
      MsgHeaderSequences = '-- Secuencias --';
      MsgSeqCreate = 'Crear secuencia: ';
      MsgSeqDrop = 'Eliminar secuencia: ';
      MsgNewTable = 'Nueva tabla: ';
      MsgAddIndex = 'Añadir índice: ';
      GeneratedHeader = 'Script generado el: %s';
      MsgTableDeleted = 'Eliminar tabla: ';
      MsgAddColumn = 'Añadir columna: ';
      MsgModColumn = 'Modificar columna: ';
      MsgDelColumn = 'Eliminar columna: ';
      MsgHeaderTrig = '-- Triggers --';
      MsgTriggerDel = 'Eliminar trigger: ';
      MsgTriggerMod = 'Modificar trigger: ';
      MsgTriggerNew = 'Nuevo trigger: ';
      MsgHeaderViews = '-- Vistas --';
      MsgRecreateView = 'Recrear vista: ';
      MsgCopyAllData = 'Copiar datos de: ';
      MsgWarnNoPK = 'ADVERTENCIA: No hay Primary Key en la tabla %s. No se ' +
                    'compararán datos.';
      MsgSyncData = 'Sincronizar datos de: ';
      MsgWithIdentity = ' (Contiene Autoincremental)';
      MsgInsertNew = 'Insertar registro (PK: %s)';
      MsgUpdateDiff = 'Actualizar registro (PK: %s)';
      MsgDeleteObs = 'Eliminar registro obsoleto (PK: %s)';
      MsgHeaderProcs = '-- Procedimientos Almacenados --';
      MsgRecreateProc = 'Recrear procedimiento: ';
      MsgHeaderFunc = '-- Funciones --';
      MsgRecreateFunc = 'Recrear función: ';
      MsgDelIndex = 'Eliminar índice: ';
      MsgModIndex = 'Modificar índice: ';
  end;

  TComparerOptions = record
    IncludeTables: TStringList;
    ExcludeTables: TStringList;
    WithData: Boolean;
    WithDataDiff: Boolean;
    NoDelete: Boolean;
    WithTriggers: Boolean;
  end;

  TDBComparerEngine = class
  private
    // Vistas de lectura de cada lado y helpers SQL segregados (§14.2)
    FOrigen: TServiciosLecturaBBDD;
    FDestino: TServiciosLecturaBBDD;
    FWriter: IScriptWriter;
    FOptions: TComparerOptions;
    FSql: TServiciosSqlBBDD;
    FComprobarCancelacion: TThreadMethod;
    procedure CompareTableStructure(const TableName: string);
    procedure CompareTableIndexes(const TableName: string);
    procedure CompareTables;
    procedure CompareViews;
    procedure CompareTriggers;
    procedure CompareProcedures;
    procedure CompareFunctions;
    procedure CreateNewTable(const TableName: string);
    procedure CompareData(const TableName: string);
    procedure CopyAllData(const TableName: string);
  public
    constructor Create(const AOrigen,
                       ADestino: TServiciosLecturaBBDD;
                       Writer: IScriptWriter;
                       const ASql: TServiciosSqlBBDD;
                       Options: TComparerOptions);
    procedure GenerateScript;
    property OnComprobarCancelacion: TThreadMethod
      read FComprobarCancelacion write FComprobarCancelacion;
  end;

implementation

uses
  System.SysUtils,
  Backup.ComparacionDatos;

constructor TDBComparerEngine.Create(const AOrigen,
                                     ADestino: TServiciosLecturaBBDD;
                                     Writer: IScriptWriter;
                                     const ASql: TServiciosSqlBBDD;
                                     Options: TComparerOptions);
begin
  FOrigen := AOrigen;
  FDestino := ADestino;
  FWriter := Writer;
  FOptions := Options;
  FSql := ASql;
end;

procedure TDBComparerEngine.CreateNewTable(const TableName: string);
var
  Table: TTableInfo;
  Indexes: TArray<TIndexInfo>;
  Idx: TIndexInfo;
  // Variables eliminadas: i, PKList, ColDef (ya no hacen falta aquí)
begin
  FWriter.AddComment(TRes.MsgNewTable + TableName);
  // 1. Obtener la estructura y los índices desde el Origen
  Table := FOrigen.Esquema.GetTableStructure(TableName);
  Indexes := FOrigen.Esquema.GetTableIndexes(TableName);
  try
    // -----------------------------------------------------------------------
    // CORRECCIÓN: Delegar al Provider (MySQL, Firebird, etc)
    // -----------------------------------------------------------------------
    // En lugar de construir el string manualmente aquí, llamamos a la interfaz.
    // Esto ejecutará TMySQLHelpers.GenerateCreateTableSQL
    FWriter.AddCommand(FSql.Creacion.GenerateCreateTableSQL(Table, Indexes));
    // -----------------------------------------------------------------------
    // 3. Crear índices secundarios (No Primary Key)
    // -----------------------------------------------------------------------
    // Nota: GenerateCreateTableSQL (en MySQL Helper) incluye la Primary Key,
    // pero habitualmente los índices secundarios se agregan después
    // o el helper de creación de tabla solo devuelve el 'CREATE TABLE'.
    // Mantenemos este bucle para asegurar que se crean los índices UNIQUE/KEY.
    for Idx in Indexes do
    begin
      if not Idx.IsPrimary then
      begin
        FWriter.AddComment(TRes.MsgAddIndex + TableName + '.' + Idx.IndexName);
        FWriter.AddCommand(
          FSql.Creacion.GenerateIndexDefinition(TableName, Idx));
      end;
    end;
  finally
    Table.Free;
    // Indexes es un array dinámico gestionado automáticamente por el
    // compilador,
    // pero si TIndexInfo contuviera objetos habría que liberarlos.
    // Al ser Records, no es necesario liberar el array explícitamente.
  end;
end;

procedure TDBComparerEngine.GenerateScript;
begin
  FWriter.AddComment('========================================');
  FWriter.AddComment(Format(TRes.GeneratedHeader, [DateTimeToStr(Now)]));
  FWriter.AddComment('========================================');
  FWriter.AddCommand('');
  CompareTables;
  CompareViews;
  CompareProcedures;
  CompareFunctions;
  if FOptions.WithTriggers then
    CompareTriggers;
end;

procedure TDBComparerEngine.CompareTables;
var
  SourceTables, TargetTables: TStringList;
  i: Integer;
  SkipTable: Boolean;
begin
  SourceTables := FOrigen.Esquema.GetTables;
  TargetTables := FDestino.Esquema.GetTables;
  try
    // 1. Tablas eliminadas (si no está --nodelete)
    if not FOptions.NoDelete then
    begin
      for i := 0 to TargetTables.Count - 1 do
      begin
        if SourceTables.IndexOf(TargetTables[i]) = -1 then
        begin
          FWriter.AddComment(TRes.MsgTableDeleted + TargetTables[i]);
          FWriter.AddCommand(
            FSql.Eliminacion.GenerateDropTableSQL(TargetTables[i]));
        end;
      end;
    end;
    // 2. Tablas nuevas o modificadas
    for i := 0 to SourceTables.Count - 1 do
    begin
      SkipTable := False;
      if (FOptions.IncludeTables.Count > 0) and
         (FOptions.IncludeTables.IndexOf(SourceTables[i]) = -1) then
        SkipTable := True;
      if (FOptions.ExcludeTables.IndexOf(SourceTables[i]) >= 0) then
        SkipTable := True;
      if not SkipTable then
      begin
      if TargetTables.IndexOf(SourceTables[i]) = -1 then
      begin
        // Tabla nueva - Crear completa
        CreateNewTable(SourceTables[i]);
        // Si hay opción de copiar datos, lo hacemos inmediatamente
        if FOptions.WithData or FOptions.WithDataDiff then
          CopyAllData(SourceTables[i]);
      end
      else
      begin
        // Tabla existente - Comparar estructura
        CompareTableStructure(SourceTables[i]);
      end;
      end;
    end;
    // --- INTEGRACIÓN DE DATOS ---
    if FOptions.WithData or FOptions.WithDataDiff then
    begin
       for i := 0 to SourceTables.Count - 1 do
       begin
         // Lógica de Filtro (Include/Exclude Tables)
         var SkipData := False;
         if (FOptions.IncludeTables.Count > 0) and
            (FOptions.IncludeTables.IndexOf(SourceTables[i]) = -1) then
           SkipData := True;
         if (FOptions.ExcludeTables.IndexOf(SourceTables[i]) >= 0) then
           SkipData := True;
         if not SkipData then
         begin
           // Solo procesamos aquí las tablas que ya existían en ambos lados
           if TargetTables.IndexOf(SourceTables[i]) > -1 then
           begin
             if FOptions.WithData then
               CopyAllData(SourceTables[i])
             else if FOptions.WithDataDiff then
               CompareData(SourceTables[i]);
           end;
           // Las tablas nuevas ya se procesaron arriba, junto con
           // CreateNewTable
         end;
       end;
    end;
  finally
    SourceTables.Free;
    TargetTables.Free;
  end;
end;

procedure TDBComparerEngine.CompareTableStructure(const TableName: string);
var
  Table1, Table2: TTableInfo;
  Col1, Col2: TColumnInfo;
  FoundIdx: Integer;

  function FindColumn(List: TList<TColumnInfo>; const Name: string): Integer;
  var
    k: Integer;
  begin
    Result := -1;
    for k := 0 to List.Count - 1 do
      if (Result < 0) and SameText(List[k].ColumnName, Name) then
        Result := k;
  end;

begin
  Table1 := FOrigen.Esquema.GetTableStructure(TableName);
  Table2 := FDestino.Esquema.GetTableStructure(TableName);
  try
    // ---------------------------------------------------------
    // 1. Recorrer Origen (Table1) para buscar NUEVAS o MODIFICADAS
    // ---------------------------------------------------------
    for var i := 0 to Table1.Columns.Count - 1 do
    begin
      Col1 := Table1.Columns[i];
      FoundIdx := FindColumn(Table2.Columns, Col1.ColumnName);
      if FoundIdx = -1 then
      begin
        // CASO A: La columna no existe en Destino -> CREAR
        FWriter.AddComment(TRes.MsgAddColumn + TableName + '.' +
                           Col1.ColumnName);
        // El Helper se encarga del dialecto SQL (ADD COLUMN vs ADD ...)
        FWriter.AddCommand(
          FSql.Modificacion.GenerateAddColumnSQL(TableName, Col1));
      end
      else
      begin
        // CASO B: La columna existe -> COMPARAR
        Col2 := Table2.Columns[FoundIdx];
        // Usamos la lógica universal del Helper abstracto
        if not FSql.Comparador.ColumnsAreEqual(Col1, Col2) then
        begin
          FWriter.AddComment(TRes.MsgModColumn + TableName + '.' +
                              Col1.ColumnName);
          FWriter.AddCommand(
            FSql.Modificacion.GenerateModifyColumnSQL(TableName, Col1));
        end;
      end;
    end;
    // ---------------------------------------------------------
    // 2. Recorrer Destino (Table2) para buscar ELIMINADAS
    // ---------------------------------------------------------
    if not FOptions.NoDelete then
    begin
      for var i := 0 to Table2.Columns.Count - 1 do
      begin
        Col2 := Table2.Columns[i];
        FoundIdx := FindColumn(Table1.Columns, Col2.ColumnName);
        if FoundIdx = -1 then
        begin
          // CASO C: La columna sobra en destino -> BORRAR
          FWriter.AddComment(TRes.MsgDelColumn + TableName + '.' +
                             Col2.ColumnName);
          // El Helper sabe cómo borrar (DROP COLUMN)
          FWriter.AddCommand(FSql.Eliminacion.GenerateDropColumnSQL(TableName,
                                                            Col2.ColumnName));
        end;
      end;
    end;
    // ---------------------------------------------------------
    // 3. Comparar Índices (Llamada separada)
    // ---------------------------------------------------------
    CompareTableIndexes(TableName);
  finally
    Table1.Free;
    Table2.Free;
  end;
end;

procedure TDBComparerEngine.CompareTriggers;
var
  SourceTriggers, TargetTriggers: TArray<TTriggerInfo>;
  i, j: Integer;
  Found: Boolean;
  TriggerDef: string;
begin
  // Obtener los arrays de triggers (Records)
  SourceTriggers := FOrigen.Objetos.GetTriggers;
  TargetTriggers := FDestino.Objetos.GetTriggers;
  FWriter.AddComment(TRes.MsgHeaderTrig);
  FWriter.AddCommand('');
  // 1. TRIGGERS ELIMINADOS (Existen en Destino, pero no en Origen)
  if not FOptions.NoDelete then
  begin
    for i := Low(TargetTriggers) to High(TargetTriggers) do
    begin
      Found := False;
      // Buscar si el trigger de destino existe en el origen
      for j := Low(SourceTriggers) to High(SourceTriggers) do
      begin
        if SameText(SourceTriggers[j].TriggerName,
                    TargetTriggers[i].TriggerName) then
        begin
          Found := True;
          Break;
        end;
      end;
      if not Found then
      begin
        FWriter.AddComment(TRes.MsgTriggerDel + TargetTriggers[i].TriggerName);
        FWriter.AddCommand(FSql.Eliminacion.GenerateDropTrigger(
          TargetTriggers[i].TriggerName));
      end;
    end;
  end;
  // 2. TRIGGERS NUEVOS O MODIFICADOS
  for i := Low(SourceTriggers) to High(SourceTriggers) do
  begin
    Found := False;
    for j := Low(TargetTriggers) to High(TargetTriggers) do
    begin
      // Comparamos por nombre
      if SameText(SourceTriggers[i].TriggerName,
                  TargetTriggers[j].TriggerName) then
      begin
        Found := True;
        // Si existen en ambos, comparamos su contenido usando el Helper
        if not FSql.Comparador.TriggersAreEqual(SourceTriggers[i],
                                         TargetTriggers[j]) then
        begin
          FWriter.AddComment(
            TRes.MsgTriggerMod + SourceTriggers[i].TriggerName);
          // Para modificar un trigger, generalmente se borra y se crea de nuevo
          FWriter.AddCommand(FSql.Eliminacion.GenerateDropTrigger(
                                                SourceTriggers[i].TriggerName));
          // Obtenemos el SQL completo del trigger desde la BD origen
          TriggerDef := FOrigen.Objetos.GetTriggerDefinition(
                                                 SourceTriggers[i].TriggerName);
          // OJO: En algunos clientes MySQL se necesita 'DELIMITER $$',
          // pero UniDAC/ScriptWriter suelen manejar comandos individuales.
          // Si vas a ejecutar esto en Workbench, podrías necesitar añadir
          // delimitadores.
          FWriter.AddCommand(TriggerDef);
        end;
        Break;
      end;
    end;
    // Si no se encontró en destino, es NUEVO
    if not Found then
    begin
      FWriter.AddComment(TRes.MsgTriggerNew + SourceTriggers[i].TriggerName);
      TriggerDef := FOrigen.Objetos.GetTriggerDefinition(
                                                 SourceTriggers[i].TriggerName);
      FWriter.AddCommand(TriggerDef);
    end;
  end;
end;

procedure TDBComparerEngine.CompareViews;
var
  SourceViews: TStringList;
  i: Integer;
begin
  SourceViews := FOrigen.Objetos.GetViews;
  try
    FWriter.AddComment(TRes.MsgHeaderViews);
    FWriter.AddCommand('');
    for i := SourceViews.Count - 1 downto 0 do
      FWriter.AddCommand(FSql.Eliminacion.GenerateDropView(SourceViews[i]));
    FWriter.AddCommand('');
    for i := 0 to SourceViews.Count - 1 do
    begin
      FWriter.AddComment(TRes.MsgRecreateView + SourceViews[i]);
      FWriter.AddCommand(FOrigen.Objetos.GetViewDefinition(SourceViews[i]));
    end;
  finally
    SourceViews.Free;
  end;
end;

// En uses añadir: Data.DB

procedure TDBComparerEngine.CopyAllData(const TableName: string);
var
  SourceData: TDataSet;
  Fields, Values: TStringList;
  i: Integer;
begin
  FWriter.AddComment(TRes.MsgCopyAllData + TableName);
  SourceData := FOrigen.Datos.GetData(TableName);
  Fields := TStringList.Create;
  Values := TStringList.Create;
  try
    // Preparamos lista de campos una vez (asumiendo coincidencia por nombre)
    // Nota: En una versión robusta, verificaríamos que campos existen en
    // destino
    // pero para CopyData asumimos estructura idéntica recién creada o validada.
    while not SourceData.Eof do
    begin
      Fields.Clear;
      Values.Clear;
      for i := 0 to SourceData.FieldCount - 1 do
      begin
        Fields.Add(
          FSql.Valores.QuoteIdentifier(SourceData.Fields[i].FieldName));
        Values.Add(FSql.Valores.ValueToSQL(SourceData.Fields[i]));
      end;
      // Usamos INSERT IGNORE o similar si fuera necesario, aquí INSERT estándar
      FWriter.AddCommand(
        FSql.Valores.GenerateInsertSQL(TableName, Fields, Values));
      SourceData.Next;
    end;
  finally
    // El provider nos dio el dataset, pero somos dueños de liberarlo
    SourceData.Free;
    Fields.Free;
    Values.Free;
  end;
end;

procedure TDBComparerEngine.CompareData(const TableName: string);
var
  oComparador: TComparadorDatosBBDD;
  oEstructura: TTableInfo;
  oServicios: TServiciosComparacionDatos;
begin
  oEstructura := FOrigen.Esquema.GetTableStructure(TableName);
  try
    oServicios := Default(TServiciosComparacionDatos);
    oServicios.Origen := FOrigen.Datos;
    oServicios.Destino := FDestino.Datos;
    oServicios.Writer := FWriter;
    oServicios.Valores := FSql.Valores;
    oServicios.Modificacion := FSql.Modificacion;
    oServicios.Textos.AvisoSinClave := TRes.MsgWarnNoPK;
    oServicios.Textos.Sincronizar := TRes.MsgSyncData;
    oServicios.Textos.ConIdentidad := TRes.MsgWithIdentity;
    oServicios.Textos.Insertar := TRes.MsgInsertNew;
    oServicios.Textos.Actualizar := TRes.MsgUpdateDiff;
    oServicios.Textos.Eliminar := TRes.MsgDeleteObs;
    oComparador := TComparadorDatosBBDD.Create(
      oServicios,
      FComprobarCancelacion);
    try
      oComparador.Comparar(
        TableName,
        oEstructura,
        FOptions.NoDelete);
    finally
      FreeAndNil(oComparador);
    end;
  finally
    FreeAndNil(oEstructura);
  end;
end;

procedure TDBComparerEngine.CompareProcedures;
var
  SourceProcs: TStringList;
  i: Integer;
begin
  SourceProcs := FOrigen.Objetos.GetProcedures;
  try
    FWriter.AddComment(TRes.MsgHeaderProcs);
    for i := 0 to SourceProcs.Count - 1 do
    begin
      FWriter.AddComment(TRes.MsgRecreateProc + SourceProcs[i]);
      FWriter.AddCommand(
        FSql.Eliminacion.GenerateDropProcedure(SourceProcs[i]));
      var strProc := FOrigen.Objetos.GetProcedureDefinition(SourceProcs[i]);
      FWriter.AddCommand(FSql.Creacion.GenerateCreateProcedureSQL(strProc));
    end;
  finally
    SourceProcs.Free;
  end;
end;

procedure TDBComparerEngine.CompareFunctions;
var
  SourceFuncs: TStringList;
  i: Integer;
begin
  SourceFuncs := FOrigen.Objetos.GetFunctions;
  try
    FWriter.AddComment(TRes.MsgHeaderFunc);
    for i := 0 to SourceFuncs.Count - 1 do
    begin
      FWriter.AddComment(TRes.MsgRecreateFunc + SourceFuncs[i]);
      // Borrar y crear
      FWriter.AddCommand(FSql.Eliminacion.GenerateDropFunction(SourceFuncs[i]));
      var strFunc := FOrigen.Objetos.GetFunctionDefinition(SourceFuncs[i]);
      FWriter.AddCommand(FSql.Creacion.GenerateCreateFunctionSQL(strFunc));
    end;
  finally
    SourceFuncs.Free;
  end;
end;

procedure TDBComparerEngine.CompareTableIndexes(const TableName: string);
var
  SourceIndexes, TargetIndexes: TArray<TIndexInfo>;
  Found: Boolean;
begin
  SourceIndexes := FOrigen.Esquema.GetTableIndexes(TableName);
  TargetIndexes := FDestino.Esquema.GetTableIndexes(TableName);
  // 1. Eliminar índices que ya no existen
  if not FOptions.NoDelete then
  begin
    for var i := 0 to High(TargetIndexes) do
    begin
      // No borrar PRIMARY KEY aquí (se maneja diferente)
      if not TargetIndexes[i].IsPrimary then
      begin
      Found := False;
      for var j := 0 to High(SourceIndexes) do
      begin
        if SameText(SourceIndexes[j].IndexName, TargetIndexes[i].IndexName) then
        begin
          Found := True;
          Break;
        end;
      end;
      if not Found then
      begin
        FWriter.AddComment(TRes.MsgDelIndex + TableName + '.' +
                          TargetIndexes[i].IndexName);
        FWriter.AddCommand(FSql.Eliminacion.GenerateDropIndexSQL(TableName,
                          TargetIndexes[i].IndexName));
      end;
      end;
    end;
  end;
  // 2. Crear o modificar índices
  for var i := 0 to High(SourceIndexes) do
  begin
    Found := False;
    for var j := 0 to High(TargetIndexes) do
    begin
      if SameText(SourceIndexes[i].IndexName, TargetIndexes[j].IndexName) then
      begin
        Found := True;
        // Si son diferentes, recrear
        if not FSql.Comparador.IndexesAreEqual(SourceIndexes[i],
                                               TargetIndexes[j]) then
        begin
          FWriter.AddComment(TRes.MsgModIndex + TableName + '.' +
                            SourceIndexes[i].IndexName);
          FWriter.AddCommand(FSql.Eliminacion.GenerateDropIndexSQL(
            TableName, SourceIndexes[i].IndexName));
          FWriter.AddCommand(FSql.Creacion.GenerateIndexDefinition(
            TableName, SourceIndexes[i]));
        end;
        Break;
      end;
    end;
    // Índice nuevo
    if not Found then
    begin
      FWriter.AddComment(TRes.MsgAddIndex + TableName + '.' +
                        SourceIndexes[i].IndexName);
      FWriter.AddCommand(FSql.Creacion.GenerateIndexDefinition(TableName,
                                                          SourceIndexes[i]));
    end;
  end;
end;

end.
