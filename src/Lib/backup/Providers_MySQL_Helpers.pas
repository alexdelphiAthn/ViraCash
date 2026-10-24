unit Providers_MySQL_Helpers;

interface
uses Core_Helpers, Core_Interfaces, Backup.Types, System.SysUtils,
  System.StrUtils, System.Classes, Data.DB, Uni;
type
  TMySQLHelpers = class(TDBHelpers)
  private
    function GenerarColumnasIndice(
      const AIndice: TIndexInfo): string;
    function GenerarClausulaIndiceSecundario(
      const AIndice: TIndexInfo): string;
  public
    function QuoteIdentifier(const Identifier: string): string; override;
    function GenerateColumnDefinition(const Col: TColumnInfo): string; override;
    function GenerateIndexDefinition(const TableName: string;
                                     const Idx: TIndexInfo): string; override;
    function GenerarIndicesSecundarios(
      const ANombreTabla: string;
      const AIndices: TArray<TIndexInfo>): string; override;
    function NormalizeType(const AType: string): string; override;
    function TriggersAreEqual(const Trg1, Trg2: TTriggerInfo): Boolean;
    override;
    function GenerateCreateTableSQL(const Table: TTableInfo;
                                    const Indexes: TArray<TIndexInfo>): string;
                                    override;
    function GenerateAddColumnSQL(const TableName:string;
                                  const ColumnInfo:TColumnInfo): string;
                                  override;
    function GenerateDropColumnSQL(const TableName, ColumnName:string): string;
    override;
    function GenerateModifyColumnSQL(const TableName:string;
                                     const ColumnInfo:TColumnInfo): string;
                                     override;
    function GenerateUpdateSQL(const TableName: string;
                                  const SetClause,
                                  WhereClause: string): string; override;
    function GenerateDropIndexSQL(const TableName,
                                        IndexName:string): string; override;
    function GenerateDropTableSQL(const TableName:String): string; override;
    function GenerateDropTrigger(const Trigger:string):string; override;
    function GenerateDropProcedure(const Proc:string):string; override;
    function GenerateDropFunction(const FuncName: string): string; override;
    function GenerateDropView(const View:string):string; override;
    function ValueToSQL(const Field: TField): string; override;
    function GenerateCreateProcedureSQL(const Body: string): string; override;
    function GenerateCreateFunctionSQL(const Body: string): string; override;
    function GenerateCreateViewSQL(const Body: string): string; override;
    function GenerateCreateTriggerSQL(const Body: string): string; override;
    function GenerateDeleteSQL(const TableName, WhereClause: string): string;
    override;
    function GenerateInsertSQL(const TableName: string;
                           Fields, Values: TStringList;
                           const HasIdentity: Boolean = False): string;
                           override;
    // MySQL no usa sequences clasicas (depende de AUTO_INCREMENT). Estos
    // helpers existen por compatibilidad con motores con sequences (Oracle,
    // PostgreSQL); el backup MySQL los devuelve vacios.
    function GenerateCreateSequence(const SeqName: string): string; override;
    function GenerateDropSequence(const SeqName: string): string; override;
  end;

// Raíz de composición: entrega juntas las vistas del helper MySQL
function CrearServiciosSqlMySQL: TServiciosSqlBBDD;

implementation

function CrearServiciosSqlMySQL: TServiciosSqlBBDD;
var
  oHelpers: TMySQLHelpers;
begin
  oHelpers := TMySQLHelpers.Create;
  // Tras la primera asignación el objeto vive por conteo de referencias
  Result.Comparador := oHelpers;
  Result.Valores := oHelpers;
  Result.Creacion := oHelpers;
  Result.Eliminacion := oHelpers;
  Result.Modificacion := oHelpers;
end;

// Añadir en uses: Data.DB, System.SysUtils, System.Classes, System.StrUtils

function TMySQLHelpers.ValueToSQL(const Field: TField): string;
  function BytesToHex(const Bytes: TBytes): string;
  var
    i: Integer;
    oHex: TStringBuilder;
  begin
    oHex := TStringBuilder.Create(Length(Bytes) * 2);
    try
      for i := Low(Bytes) to High(Bytes) do
        oHex.Append(IntToHex(Bytes[i], 2));
      Result := oHex.ToString;
    finally
      FreeAndNil(oHex);
    end;
  end;
var
  InvariantFmt: TFormatSettings;
  sTextoSeguro: string;
begin
  if Field.IsNull then
    Result := 'NULL'
  else
  begin
    // Configuración invariante: punto decimal, sin separador de miles
    InvariantFmt := TFormatSettings.Invariant;
    case Field.DataType of
      ftString, ftWideString, ftMemo, ftWideMemo, ftFmtMemo:
        begin
          sTextoSeguro := StringReplace(Field.AsString, '\', '\\',
                                        [rfReplaceAll]);
          Result := QuotedStr(sTextoSeguro);
        end;
      ftDate, ftTime, ftDateTime, ftTimeStamp:
        Result := QuotedStr(FormatDateTime('yyyy-mm-dd hh:nn:ss',
                                           Field.AsDateTime));
      ftBoolean:
        Result := IntToStr(Ord(Field.AsBoolean));
      ftBlob, ftGraphic, ftVarBytes, ftBytes:
        Result := '0x' + BytesToHex(Field.AsBytes);
      ftSmallint, ftInteger, ftWord, ftLargeint, ftAutoInc:
        Result := Field.AsString;
      ftFloat, ftCurrency, ftBCD, ftFMTBcd, ftExtended, ftSingle:
        Result := FloatToStr(Field.AsFloat, InvariantFmt);
      else
        begin
          try
            Result := FloatToStr(Field.AsFloat, InvariantFmt);
          except
            Result := StringReplace(Field.AsString, ',', '.',
                                    [rfReplaceAll]);
          end;
        end;
    end;
  end;
end;

function TMySQLHelpers.GenerateInsertSQL(const TableName: string;
                           Fields, Values: TStringList;
                           const HasIdentity: Boolean = False): string;
var
  i: Integer;
  FieldList, ValueList: string;
begin
  // Unimos manualmente para evitar que CommaText escape cosas que no debe
  FieldList := '';
  ValueList := '';
  for i := 0 to Fields.Count - 1 do
  begin
    if i > 0 then FieldList := FieldList + ', ';
    FieldList := FieldList + Fields[i];
  end;
  for i := 0 to Values.Count - 1 do
  begin
    if i > 0 then ValueList := ValueList + ', ';
    ValueList := ValueList + Values[i];
  end;
  Result := 'INSERT INTO ' + QuoteIdentifier(TableName) + ' (' +
            FieldList + ') VALUES (' + ValueList + ');';
end;

function TMySQLHelpers.GenerateUpdateSQL(const TableName: string;
  const SetClause, WhereClause: string): string;
begin
  Result := 'UPDATE ' + QuoteIdentifier(TableName) + ' SET ' + SetClause +
            ' WHERE ' + WhereClause + ';';
end;

function TMySQLHelpers.TriggersAreEqual(const Trg1,
                                                   Trg2: TTriggerInfo): Boolean;
begin
  Result := SameText(Trg1.TriggerName, Trg2.TriggerName) and
            (Trg1.EventManipulation = Trg2.EventManipulation) and
            (Trg1.ActionTiming = Trg2.ActionTiming) and
            (Trim(Trg1.ActionStatement) = Trim(Trg2.ActionStatement));
end;

function TMySQLHelpers.QuoteIdentifier(const Identifier: string): string;
begin
  Result := '`' + Identifier + '`';
end;

function TMySQLHelpers.NormalizeType(const AType: string): string;
var
  S: string;
  PStart, PEnd: Integer;
begin
  S := LowerCase(Trim(AType));
  // ESPECÍFICO MYSQL: Eliminar display width de INT(11)
  if StartsText('int', S) or StartsText('tinyint', S) then
  begin
    PStart := Pos('(', S);
    PEnd := Pos(')', S);
    if (PStart > 0) and (PEnd > PStart) then
      S := Copy(S, 1, PStart - 1) + Copy(S, PEnd + 1, MaxInt);
  end;
  Result := StringReplace(S, ' ', '', [rfReplaceAll]);
end;

function TMySQLHelpers.GenerateAddColumnSQL(const TableName: string;
  const ColumnInfo: TColumnInfo): string;
begin
  Result := 'ALTER TABLE ' + QuoteIdentifier(TableName) +
            ' ADD COLUMN ' + GenerateColumnDefinition(ColumnInfo) + ';';
end;

function TMySQLHelpers.GenerateColumnDefinition(const Col: TColumnInfo): string;
var
  DefVal: string;
begin
  // 1. Definición básica: `Nombre` Tipo
  Result := '`' + Col.ColumnName + '` ' + Col.DataType;
  // 2. Definir NULL o NOT NULL
  if SameText(Col.IsNullable, 'NO') then
    Result := Result + ' NOT NULL'
  else
    Result := Result + ' NULL';
  if Col.ColumnDefault = '<NULL>' then
  begin
    if not SameText(Col.IsNullable, 'NO') then
      Result := Result + ' DEFAULT NULL';
  end
  else if (Col.ColumnDefault <> '') then
  begin
    if SameText(Col.ColumnDefault, 'NULL') then
    begin
       Result := Result + ' DEFAULT NULL';
    end
    else if (Pos('CURRENT_TIMESTAMP', UpperCase(Col.ColumnDefault)) > 0) or
            (Pos('NOW()', UpperCase(Col.ColumnDefault)) > 0) then
    begin
      Result := Result + ' DEFAULT ' + Col.ColumnDefault;
    end
    else
    begin
      DefVal := Col.ColumnDefault;
      if (Length(DefVal) >= 2) and (DefVal[1] = '''') and
         (DefVal[Length(DefVal)] = '''') then
        DefVal := Copy(DefVal, 2, Length(DefVal) - 2);
      Result := Result + ' DEFAULT ' + QuotedStr(DefVal);
    end;
  end;
  if Pos('auto_increment', LowerCase(Col.Extra)) > 0 then
    Result := Result + ' AUTO_INCREMENT';
  if Pos('on update', LowerCase(Col.Extra)) > 0 then
    Result := Result + ' ON UPDATE CURRENT_TIMESTAMP';
  if not SameText(Col.ColumnComment, '') then
    Result := Result + ' COMMENT ' + QuotedStr(Col.ColumnComment);
end;
function TMySQLHelpers.GenerateCreateProcedureSQL(const Body: string): string;
begin
  Result := 'DELIMITER ;;' + sLineBreak +
            TrimRight(Body) + ' ;;' + sLineBreak +
            'DELIMITER ;';
end;

function TMySQLHelpers.GenerateCreateFunctionSQL(const Body: string): string;
begin
  Result := 'DELIMITER ;;' + sLineBreak +
            TrimRight(Body) + ' ;;' + sLineBreak +
            'DELIMITER ;';
end;

function TMySQLHelpers.GenerateCreateTriggerSQL(const Body: string): string;
begin
  Result := 'DELIMITER ;;' + sLineBreak +
            TrimRight(Body) + ' ;;' + sLineBreak +
            'DELIMITER ;';
end;

function TMySQLHelpers.GenerateCreateViewSQL(const Body: string): string;
begin
  // Las vistas no necesitan cambiar el delimitador
  Result := Body + ';';
end;

function TMySQLHelpers.GenerateCreateTableSQL(const Table: TTableInfo;
  const Indexes: TArray<TIndexInfo>): string;
var
  i: Integer;
  PKList: TStringList;
  ColDef: string;
  IsLastColumn: Boolean;
begin
  Result :=
    'CREATE TABLE ' + QuoteIdentifier(Table.TableName) + ' (' + sLineBreak;
  PKList := TStringList.Create;
  try
    // 1. Recorremos todas las columnas
    for i := 0 to Table.Columns.Count - 1 do
    begin
      ColDef := '  ' + GenerateColumnDefinition(Table.Columns[i]);
      // Detectamos si es PK y la guardamos
      if SameText(Table.Columns[i].ColumnKey, 'PRI') then
        PKList.Add(QuoteIdentifier(Table.Columns[i].ColumnName));
      // Determinamos si es la última columna de la lista
      IsLastColumn := (i = Table.Columns.Count - 1);
      // --- CORRECCIÓN DE LA COMA ---
      // Ponemos coma si NO es la última columna...
      // ...O si SIENDO la última, tenemos una PK que agregar después.
      if (not IsLastColumn) or (PKList.Count > 0) then
      begin
        ColDef := ColDef + ',';
      end;
      Result := Result + ColDef + sLineBreak;
    end;
    // 2. Agregar PK inline (Ahora la sintaxis será correcta)
    if PKList.Count > 0 then
      Result :=
        Result + '  PRIMARY KEY (' + PKList.CommaText + ')' + sLineBreak;
    Result := Result +
      ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ' +
      'COLLATE=utf8mb4_spanish_ci;';
  finally
    PKList.Free;
  end;
end;

function TMySQLHelpers.GenerateDeleteSQL(const TableName,
  WhereClause: string): string;
begin
  Result := 'DELETE FROM ' + QuoteIdentifier(TableName) +
            ' WHERE ' + WhereClause + ';';
end;

function TMySQLHelpers.GenerateDropColumnSQL(const TableName,
  ColumnName: string): string;
begin
  Result := 'ALTER TABLE ' + QuoteIdentifier(TableName) +
            ' DROP COLUMN ' + QuoteIdentifier(ColumnName) + ';';
end;

function TMySQLHelpers.GenerateDropFunction(const FuncName: string): string;
begin
  Result:= 'DROP FUNCTION IF EXISTS ' + QuoteIdentifier(FuncName) + ';';
end;

function TMySQLHelpers.GenerateDropTableSQL(const TableName:String): string;
begin
  Result := 'DROP TABLE IF EXISTS ' + QuoteIdentifier(TableName) + ';';
end;

function TMySQLHelpers.GenerateDropTrigger(const Trigger: string): string;
begin
  Result := 'DROP TRIGGER IF EXISTS ' + QuoteIdentifier(Trigger) + ';';
end;

function TMySQLHelpers.GenerateDropView(const View: string): string;
begin
  Result := 'DROP VIEW IF EXISTS ' + QuoteIdentifier(View) + ';';
end;

function TMySQLHelpers.GenerateDropIndexSQL(const TableName,
                                            IndexName: string): string;
begin
  if SameText(IndexName, 'PRIMARY') then
  begin
    Result :=
      'SET @pk_exists := (SELECT COUNT(*) FROM ' +
      'information_schema.table_constraints ' +
      'WHERE table_schema = DATABASE() AND table_name = ' + QuotedStr(TableName)
        +
      ' AND constraint_type = ''PRIMARY KEY'');' + sLineBreak +
      'SET @sql_drop := IF(@pk_exists > 0, ' +
      '''ALTER TABLE ' + QuoteIdentifier(TableName) + ' DROP PRIMARY KEY'', ' +
      '''SELECT "No Primary Key to drop"'');' + sLineBreak +
      'PREPARE stmt FROM @sql_drop;' + sLineBreak +
      'EXECUTE stmt;' + sLineBreak +
      'DEALLOCATE PREPARE stmt;';
  end
  else
  begin
    Result := 'ALTER TABLE ' + QuoteIdentifier(TableName) +
              ' DROP INDEX ' + QuoteIdentifier(IndexName) + ';';
  end;
end;

function TMySQLHelpers.GenerateDropProcedure(const Proc: string): string;
begin
  Result:= 'DROP PROCEDURE IF EXISTS ' + QuoteIdentifier(Proc) + ';';
end;

function TMySQLHelpers.GenerarColumnasIndice(
  const AIndice: TIndexInfo): string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to High(AIndice.Columns) do
  begin
    if i > 0 then
      Result := Result + ', ';
    Result := Result +
      QuoteIdentifier(AIndice.Columns[i].ColumnName);
  end;
end;

function TMySQLHelpers.GenerarClausulaIndiceSecundario(
  const AIndice: TIndexInfo): string;
var
  sColumnas: string;
begin
  Result := '';
  if not AIndice.IsPrimary then
  begin
    sColumnas := GenerarColumnasIndice(AIndice);
    if AIndice.IsUnique then
    begin
      Result :=
        'ADD UNIQUE INDEX ' + QuoteIdentifier(AIndice.IndexName) +
        ' (' + sColumnas + ')';
    end
    else
    begin
      Result :=
        'ADD INDEX ' + QuoteIdentifier(AIndice.IndexName) +
        ' (' + sColumnas + ')';
    end;
  end;
end;

function TMySQLHelpers.GenerateIndexDefinition(const TableName: string;
  const Idx: TIndexInfo): string;
var
  ColNames: string;
begin
  ColNames := GenerarColumnasIndice(Idx);
  if Idx.IsPrimary then
  begin
    Result :=
      '-- Descomenta para limpieza de duplicados previa a la creación de PK'
        + sLineBreak +
      '-- DELETE FROM ' + QuoteIdentifier(TableName) + ' WHERE ' +
      '-- (' + ColNames + ') IN (' +
        '-- SELECT ' + ColNames + ' FROM (' +
          '-- SELECT ' + ColNames +
          '-- FROM ' + QuoteIdentifier(TableName) +
          '-- GROUP BY ' + ColNames +
          '-- HAVING COUNT(*) > 1' +
        '-- ) AS c' +
      '-- );' + sLineBreak + sLineBreak +
      'ALTER TABLE ' + QuoteIdentifier(TableName) +
      ' ADD PRIMARY KEY (' + ColNames + ');';
  end
  else
  begin
    Result := 'ALTER TABLE ' + QuoteIdentifier(TableName) +
      ' ' + GenerarClausulaIndiceSecundario(Idx) + ';';
  end;
end;

function TMySQLHelpers.GenerarIndicesSecundarios(
  const ANombreTabla: string;
  const AIndices: TArray<TIndexInfo>): string;
var
  iIndice: Integer;
  sClausula: string;
begin
  Result := '';
  for iIndice := Low(AIndices) to High(AIndices) do
  begin
    sClausula := GenerarClausulaIndiceSecundario(AIndices[iIndice]);
    if sClausula <> '' then
    begin
      if Result = '' then
      begin
        Result := 'ALTER TABLE ' + QuoteIdentifier(ANombreTabla) +
          ' ' + sClausula;
      end
      else
      begin
        Result := Result + ',' + sLineBreak + '  ' + sClausula;
      end;
    end;
  end;
  if Result <> '' then
    Result := Result + ';';
end;

function TMySQLHelpers.GenerateModifyColumnSQL(const TableName: string;
  const ColumnInfo: TColumnInfo): string;
var
  SanitizeSQL: string;
  MaxLen: Integer;
begin
  SanitizeSQL := '';
  MaxLen := StrToIntDef(ColumnInfo.CharMaxLength, 0);
  if (MaxLen > 0) and
     (ContainsText(ColumnInfo.DataType, 'char') or
      ContainsText(ColumnInfo.DataType, 'text')) then
  begin
     SanitizeSQL := SanitizeSQL +
       'UPDATE ' + QuoteIdentifier(TableName) +
       ' SET ' + QuoteIdentifier(ColumnInfo.ColumnName) +
       ' = LEFT(' + QuoteIdentifier(ColumnInfo.ColumnName) + ', ' +
                    IntToStr(MaxLen) + ')' +
       ' WHERE LENGTH(' + QuoteIdentifier(ColumnInfo.ColumnName) + ') > ' +
                          IntToStr(MaxLen) + ';' +
       sLineBreak;
  end;
  if SameText(ColumnInfo.IsNullable, 'NO') then
  begin
     SanitizeSQL := SanitizeSQL +
       'UPDATE ' + QuoteIdentifier(TableName) +
       ' SET ' + QuoteIdentifier(ColumnInfo.ColumnName) + ' = ''''' +
       ' WHERE ' + QuoteIdentifier(ColumnInfo.ColumnName) + ' IS NULL;' +
       sLineBreak;
  end;
  Result := SanitizeSQL +
            'ALTER TABLE ' + QuoteIdentifier(TableName) +
            ' MODIFY COLUMN ' + GenerateColumnDefinition(ColumnInfo) + ';';
end;

function TMySQLHelpers.GenerateCreateSequence(const SeqName: string): string;
begin
  Result := '';
end;

function TMySQLHelpers.GenerateDropSequence(const SeqName: string): string;
begin
  Result := '';
end;

end.
