{
  Copyright (C) 2013-2023 Tim Sinaeve tim.sinaeve@gmail.com

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
}
// Codigo third-party - suprimir warnings/hints sin modificar fuentes externas.
{$WARN NO_RETVAL OFF}
{$WARN USE_BEFORE_DEF OFF}
{$HINTS OFF}
unit ts.Core.SQLParser;

//{$MODE DELPHI}

interface

uses
  Classes, SysUtils, System.Contnrs,

  ts.Core.SQLScanner, ts.Core.SQLTree;

type
  TParseTypeFlag = (
    ptfAllowDomainName,
    ptfAlterDomain,
    ptfAllowConstraint,
    ptProcedureParam,
    ptfTableFieldDef,
    ptfCast,
    ptfExternalFunction,
    ptfExternalFunctionResult
  );
  TParseTypeFlags = set of TParseTypeFlag;

  TExpressionOption = (
    eoCheckConstraint,
    eoTableConstraint,
    eoComputedBy,
    eoOnlyNull,
    eoFieldValue,
    eoSelectvalue,
    eoParamValue,
    eoWhereClause,
    eoJoin,
    eoHaving,
    eoListValue,
    eoIF
  );
  TExpressionOptions = set of TExpressionOption;
  TSelectFlag        = (sfSingleTon, sfUnion, sfInto);
  TSelectFlags       = set of TSelectFlag;

  { TSQLParser }

  TSQLParser = class(TObject)
  private
    FInput          : TStream;
    FScanner        : TSQLScanner;
    FCurrent        : TSQLToken;
    FCurrentString  : string;
    FPrevious       : TSQLToken;
    FFreeScanner    : Boolean;
    FPeekToken      : TSQLToken;
    FPeekTokenString: string;

    procedure CheckEOF;

  protected
    procedure UnexpectedToken; overload;
    procedure UnexpectedToken(AExpected : TSQLTokens); overload;
    // All elements must be created with this factory function
    function CreateElement(AElementClass : TSQLElementClass;
      AParent : TSQLElement) : TSQLElement; virtual;
    function CreateLiteral(AParent: TSQLElement): TSQLLiteral;
    function CreateIdentifier(AParent : TSQLElement;
      const AName : TSQLStringType) : TSQLIdentifierName;
    procedure Expect(aToken: TSQLToken); overload;
    procedure Expect(aTokens: TSQLTokens); overload;
    procedure Consume(aToken: TSQLToken);
    procedure Error(Msg : string); overload;
    procedure Error(Fmt : string; Args : array of const); overload;
    // Expression support
    function ParseExprLevel1(AParent: TSQLElement; EO : TExpressionOptions)
      : TSQLExpression;
    function ParseExprLevel2(AParent: TSQLElement; EO : TExpressionOptions)
      : TSQLExpression;
    function ParseExprLevel3(AParent: TSQLElement; EO : TExpressionOptions)
      : TSQLExpression;
    function ParseExprLevel4(AParent: TSQLElement; EO : TExpressionOptions)
      : TSQLExpression;
    function ParseExprLevel5(AParent: TSQLElement; EO : TExpressionOptions)
      : TSQLExpression;
    function ParseExprLevel6(AParent: TSQLElement; EO : TExpressionOptions)
      : TSQLExpression;
    function ParseExprPrimitive(AParent: TSQLElement; EO : TExpressionOptions)
      : TSQLExpression;
    function ParseInoperand(AParent: TSQLElement): TSQLExpression;
    // Lists, primitives
    function ParseIdentifierList(AParent: TSQLElement;
      AList: TSQLelementList): Integer;
    function ParseValueList(AParent: TSQLElement; EO : TExpressionOptions)
      : TSQLelementList;
    function ParseSQLValue(AParent: TSQLElement): TSQLExpression;
    function ParseCheckConstraint(AParent: TSQLElement;
      TableConstraint : Boolean = False): TSQLExpression;
    // Create/Alter statements
    function ParseAddTableElement(AParent: TSQLElement)
      : TSQLAlterTableAddElementOperation;
    function ParseAlterTableElement(AParent: TSQLElement)
      : TSQLAlterTableOperation;
    function ParseDropTableElement(AParent: TSQLElement)
      : TSQLDropTableElementOperation;
    function ParseFieldConstraint(AParent: TSQLElement): TSQLFieldConstraint;
    function ParseForeignKeyDefinition(AParent: TSQLElement)
      : TSQLForeignKeyDefinition;
    procedure ParseCharTypeDefinition(out DT: TSQLDataType; out Len: Integer;
      Out ACharset : TSQLStringType);
    procedure ParseBlobDefinition(var ASegmentSize, ABlobType: Integer;
      var ACharset : TSQLStringType);
    function ParseTypeDefinition(AParent: TSQLElement; Flags: TParseTypeFlags)
      : TSQLTypeDefinition;
    function ParseTableFieldDef(AParent: TSQLElement): TSQLTableFieldDef;
    function ParseTableKeyConstraint(AParent: TSQLElement)
      : TSQLTableConstraintDef;
    function ParseTableConstraint(AParent: TSQLElement): TSQLTableConstraintDef;
    function ParseCreateDomainStatement(AParent: TSQLElement; IsAlter: Boolean)
      : TSQLCreateOrAlterStatement;
    function ParseCreateExceptionStatement(AParent: TSQLElement;
      IsAlter: Boolean): TSQLCreateOrAlterStatement;
    function ParseCreateGeneratorStatement(AParent: TSQLElement;
      IsAlter: Boolean): TSQLCreateOrAlterStatement;
    function ParseCreateRoleStatement(AParent: TSQLElement; IsAlter: Boolean)
      : TSQLCreateOrAlterStatement;
    function ParseCreateIndexStatement(AParent: TSQLElement; IsAlter: Boolean)
      : TSQLCreateOrAlterStatement;
    function ParseCreateProcedureStatement(AParent: TSQLElement;
      IsAlter: Boolean): TSQLCreateOrAlterStatement;
    function ParseCreateTableStatement(AParent: TSQLElement)
      : TSQLCreateOrAlterStatement;
    function ParseAlterTableStatement(AParent: TSQLElement)
      : TSQLAlterTableStatement;
    function ParseCreateViewStatement(AParent: TSQLElement; IsAlter: Boolean)
      : TSQLCreateOrAlterStatement;
    function ParseCreateTriggerStatement(AParent: TSQLElement; IsAlter: Boolean)
      : TSQLCreateOrAlterStatement;
    function ParseSetGeneratorStatement(AParent: TSQLElement)
      : TSQLSetGeneratorStatement;
    function ParseCreateDatabaseStatement(AParent: TSQLElement;
      IsAlter: Boolean): TSQLCreateDatabaseStatement;
    function ParseCreateShadowStatement(AParent: TSQLElement; IsAlter: Boolean)
      : TSQLCreateShadowStatement;
    function ParseAlterDatabaseStatement(AParent: TSQLElement; IsAlter: Boolean)
      : TSQLAlterDatabaseStatement;
    function ParseSecondaryFile(AParent: TSQLElement): TSQLDatabaseFileInfo;
    function ParseDeclareFunctionStatement(AParent: TSQLElement)
      : TSQLDeclareExternalFunctionStatement;
    function ParseDeclareStatement(AParent: TSQLElement): TSQLStatement;
    // GRANT parsing
    procedure ParseGranteeList(AParent: TSQLElement; List: TSQLelementList;
      AllowObject, AllowGroup, AllowPublic : Boolean;
      IsRevoke: Boolean = False);
    function ParseGrantExecuteStatement(AParent: TSQLElement)
      : TSQLProcedureGrantStatement;
    function ParseGrantRoleStatement(AParent: TSQLElement)
      : TSQLRoleGrantStatement;
    function ParseGrantTableStatement(AParent: TSQLElement)
      : TSQLTableGrantStatement;
    // REVOKE parsing
    function ParseRevokeExecuteStatement(AParent: TSQLElement)
      : TSQLProcedureRevokeStatement;
    function ParseRevokeRoleStatement(AParent: TSQLElement)
      : TSQLRoleRevokeStatement;
    function ParseRevokeTableStatement(AParent: TSQLElement)
      : TSQLTableRevokeStatement;
    // SELECT parsing
    function ParseExprAggregate(AParent: TSQLElement; EO: TExpressionOptions)
      : TSQLAggregateFunctionExpression;
    function ParseOverClause(AParent: TSQLElement; AFunc: TSQLExpression)
      : TSQLWindowFunctionExpression;
    function ParseRawFunctionCall(AParent: TSQLElement; const AName: string)
      : TSQLExpression;
    procedure ParseFromClause(AParent: TSQLSelectStatement;
      AList: TSQLelementList);
    procedure ParseGroupBy(AParent: TSQLSelectStatement;
      AList: TSQLelementList);
    procedure ParseOrderBy(AParent: TSQLSelectStatement;
      AList: TSQLelementList);
    procedure ParseSelectFieldList(AParent: TSQLSelectStatement;
      AList: TSQLelementList; Singleton : Boolean);
    function ParseForUpdate(AParent: TSQLSelectStatement): TSQLelementList;
    function ParseSelectPlan(AParent: TSQLElement): TSQLSelectPlan;
    function ParseTableRef(AParent: TSQLSelectStatement): TSQLTableReference;
    procedure ParseIntoList(AParent: TSQLElement; List: TSQLelementList);
    // EXECUTE parsing
    function ParseExecuteProcedureStatement(AParent: TSQLElement)
      : TSQLExecuteProcedureStatement;
    function ParseCallStatement(AParent: TSQLElement): TSQLStatement;
    // Stored procedure parsing
    function ParseAssignStatement(AParent: TSQLElement): TSQLAssignStatement;
    function ParseExceptionStatement(AParent: TSQLElement)
      : TSQLExceptionStatement;
    function ParseForStatement(AParent: TSQLElement): TSQLForStatement;
    function ParseIfStatement(AParent: TSQLElement): TSQLIFStatement;
    function ParsePostEventStatement(AParent: TSQLElement)
      : TSQLPostEventStatement;
    procedure ParseProcedureParamList(AParent: TSQLElement;
      AList: TSQLelementList);
    procedure ParseCreateProcedureVariableList(AParent: TSQLElement;
      AList: TSQLelementList);
    function ParseProcedureStatement(AParent: TSQLElement): TSQLStatement;
    procedure ParseStatementBlock(AParent: TSQLElement;
      Statements: TSQLelementList);
    function ParseWhenStatement(AParent: TSQLElement): TSQLWhenStatement;
    function ParseWhileStatement(AParent: TSQLElement): TSQLWhileStatement;
    // SOPORTE MARIADB: parsea y formatea un bloque DELIMITER...DELIMITER ;
    procedure ParseDelimiterBlock(AElement: TSQLElement);
    // SOPORTE MARIADB: captura el cuerpo BEGIN..END de un PROCEDURE como
    // texto formateado (preservando saltos de línea + indent estructural).
    function ParseProcedureBodyAsRaw: string;

  public
    constructor Create(AInput: TStream); overload;
    constructor Create(AScanner : TSQLScanner); overload;
    destructor Destroy; override;
    function ParseSelectStatement(AParent : TSQLElement;
      Flags : TSelectFlags = []) : TSQLSelectStatement;
    function ParseUpdateStatement(AParent : TSQLElement) : TSQLUpdateStatement;
    function ParseInsertStatement(AParent : TSQLElement) : TSQLInsertStatement;
    function ParseDeleteStatement(AParent : TSQLElement) : TSQLDeleteStatement;
    function ParseCreateStatement(AParent : TSQLElement;
      IsAlter : Boolean = False) : TSQLCreateOrAlterStatement;
    function ParseDropStatement(AParent : TSQLElement) : TSQLDropStatement;
    function ParseRollbackStatement(AParent : TSQLElement)
      : TSQLRollbackStatement;
    function ParseCommitStatement(AParent : TSQLElement) : TSQLCommitStatement;
    function ParseSetStatement(AParent : TSQLElement) : TSQLStatement;
    function ParseConnectStatement(AParent : TSQLElement)
      : TSQLConnectStatement;
    function ParseGrantStatement(AParent: TSQLElement): TSQLGrantStatement;
    function ParseRevokeStatement(AParent: TSQLElement): TSQLGrantStatement;
    function Parse : TSQLElement;
    function ParseScript(AllowPartial : Boolean = False) : TSQLelementList;
    // Auxiliary stuff
    function CurrentToken : TSQLToken;
    function CurrentTokenString : string;
    function GetNextToken : TSQLToken;
    function PeekNextToken : TSQLToken;
    function PreviousToken : TSQLToken;
    function IsEndOfLine : Boolean;
    function CurSource: string;
    function CurLine : Integer;
    function CurPos : Integer;
  end;

  { ESQLParser }

  ESQLParser = class(Exception)
  private
    FCol     : Integer;
    FFileName: string;
    FLine    : Integer;

  public
    property Line     : Integer read FLine write FLine;
    property Col      : Integer read FCol write FCol;
    property FileName : string read FFileName write FFileName;
  end;

function StringToSQLExtractElement(const S : TSQLStringType;
  Out Res : TSQLExtractElement) : Boolean;

implementation

uses
  TypInfo;

type
  TSQLStartTransactionStatement = class(TSQLElement)
  public
    Modifiers: string;
    function GetAsSQL(Options: TSQLFormatOptions;
                      AIndent: Integer = 0): TSQLStringType; override;
  end;

  TSQLMariaDBInsertStatement = class(TSQLInsertStatement)
  public
    ExtraValues: string;
    OnDuplicateKey: string;
    IsReplace: Boolean;
    function GetAsSQL(Options: TSQLFormatOptions;
                      AIndent: Integer = 0): TSQLStringType; override;
  end;

  TSQLMariaDBCreateTableStatement = class(TSQLCreateTableStatement)
  public
    TableOptions: string;
    function GetAsSQL(Options: TSQLFormatOptions; AIndent: Integer = 0): TSQLStringType; override;
  end;

  TSQLAlterTableRawOperation = class(TSQLAlterTableOperation)
  public
    RawText: string;
    function GetAsSQL(Options: TSQLFormatOptions; AIndent: Integer = 0): TSQLStringType; override;
  end;

  TSQLRawStatement = class(TSQLStatement)
  public
    RawText: string;
    function GetAsSQL(Options: TSQLFormatOptions; AIndent: Integer = 0): TSQLStringType; override;
  end;

  TSQLMariaDBCallStatement = class(TSQLStatement)
  private
    FCallExpression: TSQLExpression;
  public
    destructor Destroy; override;
    function GetAsSQL(Options: TSQLFormatOptions;
      AIndent: Integer = 0): TSQLStringType; override;
    property CallExpression: TSQLExpression
      read FCallExpression write FCallExpression;
  end;

  TSQLMariaDBTableFieldDef = class(TSQLTableFieldDef)
  public
    RawModifiers: string;
    function GetAsSQL(Options: TSQLFormatOptions; AIndent: Integer = 0): TSQLStringType; override;
  end;

  TSQLMariaDBKeyConstraintDef = class(TSQLTableFieldsConstraintDef)
  private
    FIndexName: TSQLIdentifierName;
  public
    destructor Destroy; override;
    function GetAsSQL(Options: TSQLFormatOptions;
      AIndent: Integer = 0): TSQLStringType; override;
    property IndexName: TSQLIdentifierName
      read FIndexName write FIndexName;
  end;

function TSQLStartTransactionStatement.GetAsSQL(Options: TSQLFormatOptions; AIndent: Integer = 0): TSQLStringType;
begin
  Result := 'START TRANSACTION';
  if Modifiers <> '' then
    Result := Result + ' ' + Modifiers;
end;

function TSQLMariaDBTableFieldDef.GetAsSQL(Options: TSQLFormatOptions; AIndent: Integer = 0): TSQLStringType;
begin
  Result := inherited GetAsSQL(Options, AIndent);
  if RawModifiers <> '' then
    Result := Result + ' ' + Trim(RawModifiers);
end;

destructor TSQLMariaDBKeyConstraintDef.Destroy;
begin
  FreeAndNil(FIndexName);
  inherited Destroy;
end;

function TSQLMariaDBKeyConstraintDef.GetAsSQL(Options: TSQLFormatOptions;
  AIndent: Integer): TSQLStringType;
begin
  Result := SQLKeyWord('KEY', Options);
  if Assigned(FIndexName) then
    Result := Result + ' ' + FIndexName.GetAsSQL(Options, AIndent);
  Result := Result + ' ' + FieldListSQL(Options, AIndent);
end;

destructor TSQLMariaDBCallStatement.Destroy;
begin
  FreeAndNil(FCallExpression);
  inherited Destroy;
end;

function TSQLMariaDBCallStatement.GetAsSQL(Options: TSQLFormatOptions;
  AIndent: Integer): TSQLStringType;
begin
  Result := SQLKeyWord('CALL ', Options);
  if Assigned(FCallExpression) then
    Result := Result + FCallExpression.GetAsSQL(Options, AIndent);
end;

Resourcestring
  SerrUnmatchedBrace = 'Expected ).';
  SErrUnexpectedToken = 'Unexpected token: %s';
  SErrUnexpectedTokenOf = 'Unexpected token: %s, expected one of %s';
  SErrTokenMismatch = 'Unexpected token: ''%s'', expected: ''%s''';
  SErrExpectedDBObject = 'Expected database object type. Got: ''%s''';
  SErrDomainNotAllowed = 'Domain name not allowed in typ definition.';
  SERRVaryingNotAllowed = 'VARYING not allowed at this point.';
  SErrUnknownBooleanOp = 'Unknown boolean operation';
  SErrUnknownComparison = 'unknown Comparison operation';
  SErrIntegerExpected = 'Integer expression expected';
  SErrInvalidUseOfCollate = 'Invalid use of COLLATE';
  SErrCannotAlterGenerator = 'Alter generator statement unknown';
  SErrInvalidLiteral = 'Invalid literal: "%s"';
  SErrNoAggregateAllowed = 'Aggregate function not allowed.';
  SErrAsteriskOnlyInCount = '* allowed only in COUNT aggregate';
  SErrUpperOneArgument = 'Only one argument for UPPER allowed';
  SErrHavingWithoutGroupBy = 'HAVING without GROUP BY clause not allowed';
  SErrNoAsteriskInSingleTon = '* not allowed in singleton select';
  SErrUnionFieldCountMatch = 'Field count mismatch in select union : %d <> %d';
  SErrInvalidExtract = 'Invalid element for extract: %s';

function StringToSQLExtractElement(const S : TSQLStringType;
  out Res : TSQLExtractElement) : Boolean;
var
  I  : TSQLExtractElement;
begin
  Result := False;
  For I := Low(TSQLExtractElement) to High(TSQLExtractElement) do
    if SameText(ExtractElementNames[I], S) then
    begin
      Res := I;
      Exit(True);
    end;
end;

{ TSQLParser }

procedure TSQLParser.Expect(aToken: TSQLToken);
begin

{$IFDEF debugparser} Writeln('Expecting : ', GetEnumName(TypeInfo(TSQLToken), Ord(aToken)), ' As string: ', TokenInfos[aToken]); {$ENDIF debugparser}

  if (CurrentToken <> aToken) then
    Error(SErrTokenMismatch, [CurrentTokenString, TokenInfos[aToken]]);
end;

procedure TSQLParser.Expect(aTokens: TSQLTokens);
begin
  if not(CurrentToken in aTokens) then
    UnexpectedToken(aTokens);
end;

procedure TSQLParser.Consume(aToken: TSQLToken);
begin
  Expect(aToken);
  GetNextToken;
end;

function TSQLParser.CurSource: string;
begin
  Result := FScanner.CurFilename;
end;

function TSQLParser.CurLine: Integer;
begin
  Result := FScanner.CurRow;
end;

function TSQLParser.CurPos: Integer;
begin
  Result := FScanner.CurColumn;
end;

procedure TSQLParser.Error(Msg: string);
var
  ErrAt : string;
  E     : ESQLParser;
begin
  if Assigned(FScanner) then
    if FScanner.CurFilename <> '' then
      ErrAt := Format('Error: file "%s" line %d, pos %d: ',
        [FScanner.CurFilename, FScanner.CurRow, FScanner.CurColumn])
    else
      ErrAt := Format('Error: line %d, pos %d: ',
        [FScanner.CurRow, FScanner.CurColumn]);

  E := ESQLParser.Create(ErrAt + Msg);
  if Assigned(FScanner) then
  begin
    E.Line := FScanner.CurRow;
    E.Col := FScanner.CurColumn;
    E.FileName := FScanner.CurFilename;
  end;
  raise E;
end;

procedure TSQLParser.Error(Fmt: string; Args: array of const );
begin
  Error(Format(Fmt, Args));
end;

function TSQLParser.CreateElement(AElementClass: TSQLElementClass;
  AParent: TSQLElement): TSQLElement;
begin
  Result := AElementClass.Create(AParent);
  Result.Source := CurSource;
  Result.SourceLine := CurLine;
  Result.SourcePos := CurPos;
end;

function TSQLParser.ParseTableRef(AParent : TSQLSelectStatement)
  : TSQLTableReference;
var
  T : TSQLSimpleTablereference;
  J : TSQLJoinTableReference;
  PCount: Integer;
  SubQueryStr: string;
  TableName: string;
begin
  if (CurrentToken = tsqlBraceOpen) then
  begin
    GetNextToken;

    // --- INICIO SOPORTE PARA DERIVED TABLES (Subconsultas en FROM/JOIN) ---
    if (CurrentToken = tsqlSelect) then
    begin
      SubQueryStr := '(';
      PCount := 1;

      // Capturar de forma segura todos los tokens de la subconsulta respetando paréntesis anidados
      while (PCount > 0) and (CurrentToken <> tsqlEOF) do
      begin
        SubQueryStr := SubQueryStr + ' ' + CurrentTokenString;
        GetNextToken;
        if CurrentToken = tsqlBraceOpen then
          Inc(PCount)
        else if CurrentToken = tsqlBraceClose then
          Dec(PCount);
      end;
      SubQueryStr := SubQueryStr + ' )';
      GetNextToken; // Consumir el tsqlBraceClose final

      // Engañamos al AST encapsulando la subconsulta como si fuera un nombre de tabla
      T := TSQLSimpleTablereference(CreateElement(TSQLSimpleTablereference, AParent));
      Result := T;
      T.ObjectName := CreateIdentifier(T, SubQueryStr);

      // Capturar la palabra reservada "AS" si la base de datos la usa (ej: AS cb)
      if (CurrentToken = tsqlAs) then
        GetNextToken;

      // Capturar el Alias de la subconsulta (ej: cb o stk)
      if (CurrentToken = tsqlIdentifier) then
      begin
        T.AliasName := CreateIdentifier(T, CurrentTokenString);
        GetNextToken;
      end;
    end
    // --- FIN SOPORTE PARA DERIVED TABLES ---
    else
    begin
      // Flujo original para paréntesis de anidación de Joins normales
      Result := ParseTableRef(AParent);
      Consume(tsqlBraceClose);
    end;
  end
  else
  begin
    // Flujo original para tablas simples
    Expect(tsqlIdentifier);
    T := TSQLSimpleTablereference(CreateElement(TSQLSimpleTablereference, AParent));
    Result := T;
    TableName := CurrentTokenString;
    GetNextToken;
    while CurrentToken = tsqlDot do
    begin
      GetNextToken;
      Expect(tsqlIdentifier);
      TableName := TableName + '.' + CurrentTokenString;
      GetNextToken;
    end;
    T.ObjectName := CreateIdentifier(T, TableName);
    if CurrentToken = tsqlBraceOpen then
    begin
      T.Params := ParseValueList(AParent, [eoParamValue]);
      GetNextToken;
    end;

    // Soporte para palabra "AS" en tablas simples
    if (CurrentToken = tsqlAs) then
      GetNextToken;

    if (CurrentToken = tsqlIdentifier) then
    begin
      T.AliasName := CreateIdentifier(T, CurrentTokenString);
      GetNextToken;
    end;
  end;

  // Procesamiento estándar de los JOINs
  Repeat
    if CurrentToken in [tsqlInner, tsqlJoin, tsqlOuter, tsqlLeft, tsqlRight] then
    begin
      J := TSQLJoinTableReference(CreateElement(TSQLJoinTableReference, AParent));
      J.Left := Result;
      Result := J;
      case CurrentToken of
        tsqlInner : J.JoinType := jtInner;
        tsqlJoin  : J.JoinType := jtNone;
        tsqlOuter : J.JoinType := jtOuter;
        tsqlLeft  : J.JoinType := jtLeft;
        tsqlRight : J.JoinType := jtRight;
      end;

      if CurrentToken <> tsqlJoin then
        GetNextToken;

      Consume(tsqlJoin);
      J.Right := ParseTableRef(AParent); // Aquí puede volver a llamar recursivamente a nuestra subconsulta
      Consume(tsqlOn);
      J.JoinClause := ParseExprLevel1(J, [eoJoin]);
    end;
  until Not(CurrentToken in [tsqlInner, tsqlJoin, tsqlOuter, tsqlLeft, tsqlRight]);
end;

procedure TSQLParser.ParseFromClause(AParent : TSQLSelectStatement;
  AList : TSQLelementList);
var
  T    : TSQLTableReference;
  Done : Boolean;
begin
  // On entry, we are on the FROM keyword.
  Consume(tsqlFrom);
  Repeat
    T := ParseTableRef(AParent);
    AList.Add(T);
    Done := (CurrentToken <> tsqlComma);
    if not Done then
      GetNextToken;
  until Done;
end;

procedure TSQLParser.ParseSelectFieldList(AParent : TSQLSelectStatement;
  AList : TSQLelementList; Singleton : Boolean);
var
  F : TSQLSelectField;
  B : Boolean;
begin
  // On entry, we're on the token preceding the field list.
  B := True;
  Repeat
    GetNextToken;
    if B then
    begin
      if (CurrentToken = tsqlDistinct) then
      begin
        AParent.Distinct := True;
        GetNextToken;
      end
      else if (CurrentToken = tsqlAll) then
      begin
        AParent.All := True;
        GetNextToken;
      end;
      B := False;
    end;
    if (CurrentToken = tsqlMul) then
    begin
      if Singleton then
        Error(SErrNoAsteriskInSingleTon);
      AList.Add(CreateElement(TSQLSelectAsterisk, AParent));
      GetNextToken;
    end
    else
    begin
      F := TSQLSelectField(CreateElement(TSQLSelectField, AParent));
      AList.Add(F);
      F.Expression := ParseExprLevel1(AParent, [eoSelectvalue]);
      if CurrentToken in [tsqlAs, tsqlIdentifier, tsqlString, tsqlNull] then
      begin
        if CurrentToken = tsqlAs then
          GetNextToken;
        if not (CurrentToken in [tsqlIdentifier, tsqlString, tsqlNull]) then
          Expect(tsqlIdentifier);
        F.AliasName := CreateIdentifier(F, CurrentTokenString);
        GetNextToken;
      end;
    end;
    Expect([tsqlComma, tsqlFrom, tsqlWhere, tsqlGroup, tsqlHaving,
      tsqlUnion, tsqlPlan, tsqlOrder, tsqlFor, tsqlInto, tsqlSemicolon,
      tsqlEOF, tsqlBraceClose]);
  until (CurrentToken <> tsqlComma);
end;

procedure TSQLParser.ParseGroupBy(AParent : TSQLSelectStatement;
  AList : TSQLelementList);
begin
  Consume(tsqlGroup);
  Expect(tsqlBy);
  Repeat
    GetNextToken;
    AList.Add(ParseExprLevel1(AParent, []));
  until (CurrentToken <> tsqlComma);
end;

function TSQLParser.ParseForUpdate(AParent : TSQLSelectStatement)
  : TSQLelementList;
begin
  // On entry we're on the FOR token.
  Consume(tsqlFor);
  Expect(tsqlUpdate);
  Result := TSQLelementList.Create(True);
  try
    Repeat
      GetNextToken;
      Expect(tsqlIdentifier);
      Result.Add(CreateIdentifier(AParent, CurrentTokenString));
    until (CurrentToken <> tsqlComma);
  except
    FreeAndNil(Result);
    raise;
  end;
end;

procedure TSQLParser.ParseOrderBy(AParent : TSQLSelectStatement;
  AList : TSQLelementList);
var
  O : TSQLOrderByElement;
begin
  // Al entrar, estamos en el token ORDER
  Consume(tsqlOrder);
  Expect(tsqlBy);
  Repeat
    GetNextToken; // Avanzamos al primer token del campo

    O := TSQLOrderByElement(CreateElement(TSQLOrderByElement, AParent));
    AList.Add(O);

    // Novedad: Usar el parseador de expresiones para soportar "tabla.campo"
    O.Field := ParseExprLevel1(O, []);

    // OJO: Ya no hacemos GetNextToken aquí porque ParseExprLevel1 ya se encargó
    // de consumir todos los puntos e identificadores y avanzar el escáner.

    if (CurrentToken = tsqlCollate) then
    begin
      GetNextToken;
      Expect(tsqlIdentifier);
      O.Collation := CreateIdentifier(O, CurrentTokenString);
      GetNextToken;
    end;

    if (CurrentToken in [tsqlDesc, tsqlAsc, tsqlDescending, tsqlAscending]) then
    begin
      if (CurrentToken in [tsqlDesc, tsqlDescending]) then
        O.OrderBy := obDescending
      else
        O.OrderBy := obAscending;
      GetNextToken;
    end;

  until (CurrentToken <> tsqlComma);
end;

function TSQLParser.ParseSelectPlan(AParent : TSQLElement) : TSQLSelectPlan;
var
  E : TSQLSelectPlanExpr;
  I : TSQLSelectPlanItem;
  L : TSQLelementList;
  N : TSQLStringType;
begin
  Result := nil;
  try
    case CurrentToken of
      tsqlIdentifier :
        begin
          if Not(AParent is TSQLSelectPlanExpr) then
            UnexpectedToken([tsqlJoin, tsqlmerge, tsqlSort]);
          N := CurrentTokenString;
          case GetNextToken of
            tsqlNatural:
              begin
                I := TSQLSelectNaturalPlan(CreateElement(TSQLSelectNaturalPlan,
                  AParent));
                Result := I;
              end;
            tsqlIndex :
              begin
                I := TSQLSelectIndexedPlan(CreateElement(TSQLSelectIndexedPlan,
                  AParent));
                Result := I;
                L := TSQLSelectIndexedPlan(I).Indexes;
                GetNextToken;
                Expect(tsqlBraceOpen);
                Repeat
                  GetNextToken;
                  Expect(tsqlIdentifier);
                  L.Add(CreateIdentifier(Result, CurrentTokenString));
                  GetNextToken;
                  Expect([tsqlComma, tsqlBraceClose]);
                until (CurrentToken = tsqlBraceClose);
              end;
            tsqlOrder:
              begin
                GetNextToken;
                Expect(tsqlIdentifier);
                I := TSQLSelectOrderedPlan(CreateElement(TSQLSelectOrderedPlan,
                  AParent));
                Result := I;
                TSQLSelectOrderedPlan(I).OrderIndex :=
                  CreateIdentifier(I, CurrentTokenString);
              end;
          else
            UnexpectedToken([tsqlNatural, tsqlIndex, tsqlOrder]);
          end;
          I.TableName := CreateIdentifier(I, N);
        end;
      tsqlJoin,
        tsqlmerge,
        tsqlSort,
        tsqlBraceOpen:
        begin
          E := TSQLSelectPlanExpr(CreateElement(TSQLSelectPlanExpr, AParent));
          Result := E;
          case CurrentToken of
            tsqlJoin,
              tsqlBraceOpen :
              E.JoinType := pjtJoin;
            tsqlSort :
              E.JoinType := pjtSort;
            tsqlmerge :
              E.JoinType := pjtMerge;
          end;
          if (CurrentToken <> tsqlBraceOpen) then
            GetNextToken;
          Expect(tsqlBraceOpen);
          repeat
            GetNextToken;
            E.Items.Add(ParseSelectPlan(E));
            Expect([tsqlComma, tsqlBraceClose]);
          until (CurrentToken = tsqlBraceClose);
        end;
    else
      UnexpectedToken([tsqlIdentifier, tsqlJoin, tsqlmerge, tsqlSort]);
    end;
    GetNextToken;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseSelectStatement(AParent: TSQLElement;
  Flags : TSelectFlags = []): TSQLSelectStatement;
var
  CTE: TSQLCommonTableExpression;
begin
  // On entry, we're on the SELECT keyword
  Expect([tsqlSelect, tsqlWith]);
  Result := TSQLSelectStatement(CreateElement(TSQLSelectStatement, AParent));
  try
    if CurrentToken = tsqlWith then
    begin
      GetNextToken;
      repeat
        CTE := TSQLCommonTableExpression(CreateElement(TSQLCommonTableExpression, Result));
        Result.WithClause.Add(CTE);
        Expect(tsqlIdentifier);
        CTE.Name := CreateIdentifier(CTE, CurrentTokenString);
        GetNextToken;
        if CurrentToken = tsqlBraceOpen then
        begin
          GetNextToken;
          ParseIdentifierList(CTE, CTE.Fields);
        end;
        Consume(tsqlAs);
        Consume(tsqlBraceOpen);
        CTE.Select := ParseSelectStatement(CTE, [sfSingleTon]);
        Consume(tsqlBraceClose);
        if CurrentToken = tsqlComma then
          GetNextToken
        else
          Break;
      until False;
    end;
    if (PeekNextToken = tsqlTransaction) then
    begin
      Consume(tsqlSelect);
      GetNextToken;
      Expect(tsqlIdentifier);
      Result.TransactionName := CreateIdentifier(Result, CurrentTokenString);
    end;
    ParseSelectFieldList(Result, Result.Fields, sfSingleTon in Flags);
    if CurrentToken = tsqlFrom then
      ParseFromClause(Result, Result.Tables);
    if CurrentToken = tsqlWhere then
    begin
      GetNextToken;
      Result.Where := ParseExprLevel1(Result, [eoWhereClause]);
    end;
    if CurrentToken = tsqlGroup then
      ParseGroupBy(Result, Result.GroupBy);
    if CurrentToken = tsqlHaving then
    begin
      if (Result.GroupBy.Count = 0) then
        Error(SErrHavingWithoutGroupBy);
      GetNextToken;
      Result.Having := ParseExprLevel1(Result, [eoHaving]);
    end;
    if (CurrentToken = tsqlUnion) then
    begin
      GetNextToken;
      if (CurrentToken = tsqlAll) then
      begin
        Result.UnionAll := True;
        GetNextToken;
      end;
      Result.Union := ParseSelectStatement(Result, Flags + [sfUnion]);
      if (Result.Fields.Count <> Result.Union.Fields.Count) then
        Error(SErrUnionFieldCountMatch, [Result.Fields.Count,
          Result.Union.Fields.Count])
    end;
    if (CurrentToken = tsqlPlan) then
    begin
      GetNextToken;
      Result.Plan := ParseSelectPlan(Result);
    end;
    if not(sfUnion in Flags) then
    begin
      if (CurrentToken = tsqlOrder) then
        ParseOrderBy(Result, Result.OrderBy);
      if (CurrentToken = tsqlFor) then
        Result.ForUpdate := ParseForUpdate(Result);
    end;
    if (CurrentToken = tsqlIdentifier) and
       SameText(CurrentTokenString, 'LIMIT') then
    begin
      GetNextToken;
      Result.Limit := ParseExprLevel1(Result, []);
    end;
    if (sfInto in Flags) then
    begin
      if (CurrentToken = tsqlInto) then
      begin
        Result.Into := TSQLelementList.Create(True);
        ParseIntoList(Result, Result.Into);
      end;
    end;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseUpdateStatement(AParent: TSQLElement
  ): TSQLUpdateStatement;
var
  P : TSQLUpdatePair;
  N : string;
begin
  // On entry, we're on the UPDATE keyword
  Consume(tsqlUpdate);
  Expect(tsqlIdentifier);
  Result := TSQLUpdateStatement(CreateElement(TSQLUpdateStatement, AParent));
  try
    Result.TableName := CreateIdentifier(Result, CurrentTokenString);
    GetNextToken;
    Expect(tsqlSet);
    Repeat
      GetNextToken;
      Expect(tsqlIdentifier);
      P := TSQLUpdatePair(CreateElement(TSQLUpdatePair, Result));
      Result.Values.Add(P);
      N := CurrentTokenString;
      GetNextToken;
      if (CurrentToken = tsqlDot) then
      begin
        GetNextToken;
        Expect(tsqlIdentifier);
        N := N + '.' + CurrentTokenString;
        GetNextToken;
      end;
      Consume(tsqlEq);
      P.FieldName := CreateIdentifier(P, N);
      P.Value := ParseExprLevel1(P, [eoFieldValue]);
    until (CurrentToken <> tsqlComma);
    if (CurrentToken = tsqlWhere) then
    begin
      GetNextToken;
      Result.WhereClause := ParseExprLevel1(P, [eoWhereClause]);
    end;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseInsertStatement(AParent: TSQLElement): TSQLInsertStatement;
var
  MDBInsert: TSQLMariaDBInsertStatement;
  PCount: Integer;
  IsReplaceStmt: Boolean;
begin
  IsReplaceStmt := False;
  if SameText(CurrentTokenString, 'REPLACE') then
  begin
    IsReplaceStmt := True;
    GetNextToken;
  end
  else
    Consume(tsqlInsert);
  if (CurrentToken = tsqlIdentifier) and SameText(CurrentTokenString, 'IGNORE') then
    GetNextToken;
  Consume(tsqlInto);
  Expect(tsqlIdentifier);
  MDBInsert := TSQLMariaDBInsertStatement(CreateElement(TSQLMariaDBInsertStatement, AParent));
  MDBInsert.IsReplace := IsReplaceStmt; // Guardamos si era un REPLACE
  Result := MDBInsert;
  try
    Result.TableName := CreateIdentifier(Result, CurrentTokenString);
    GetNextToken;
    if CurrentToken = tsqlBraceOpen then
    begin
      Result.Fields := TSQLelementList.Create(True);
      Repeat
        GetNextToken;
        Expect(tsqlIdentifier);
        Result.Fields.Add(CreateIdentifier(Result, CurrentTokenString));
        GetNextToken;
        Expect([tsqlBraceClose, tsqlComma]);
      Until (CurrentToken = tsqlBraceClose);
      GetNextToken;
    end;
    case CurrentToken of
      tsqlSelect :
        Result.Select := ParseSelectStatement(Result);
      tsqlValues :
        begin
          GetNextToken;
          Result.Values := ParseValueList(Result, [eoFieldValue]);
          GetNextToken; // consume el primer ')'
          while CurrentToken = tsqlComma do
          begin
            MDBInsert.ExtraValues := MDBInsert.ExtraValues + ',' + sLineBreak + '  (';
            GetNextToken; // Consumimos la coma
            Expect(tsqlBraceOpen);
            PCount := 1;
            GetNextToken; // Consumimos el '('
            while (PCount > 0) and (CurrentToken <> tsqlEOF) do
            begin
              if CurrentToken = tsqlBraceOpen then Inc(PCount)
              else if CurrentToken = tsqlBraceClose then Dec(PCount);
              if PCount > 0 then
              begin
                if CurrentToken = tsqlString then
                  MDBInsert.ExtraValues := MDBInsert.ExtraValues +
                    SQLFormatString(CurrentTokenString, [])
                else
                  MDBInsert.ExtraValues := MDBInsert.ExtraValues + CurrentTokenString;
                GetNextToken;
                if not (CurrentToken in [tsqlComma, tsqlBraceClose, tsqlBraceOpen, tsqlDot]) and
                   not (PreviousToken in [tsqlDot]) then
                  MDBInsert.ExtraValues := MDBInsert.ExtraValues + ' ';
              end;
            end;
            MDBInsert.ExtraValues := TrimRight(MDBInsert.ExtraValues) + ')';
            if CurrentToken = tsqlBraceClose then GetNextToken;
          end;
        end;
    else
      UnexpectedToken([tsqlSelect, tsqlValues]);
    end;
    if (CurrentToken = tsqlOn) then
    begin
      MDBInsert.OnDuplicateKey := 'ON ';
      GetNextToken;
      if (CurrentToken = tsqlIdentifier) and SameText(CurrentTokenString, 'DUPLICATE') then
      begin
        MDBInsert.OnDuplicateKey := MDBInsert.OnDuplicateKey + 'DUPLICATE ';
        GetNextToken;
      end;
      if (CurrentToken = tsqlKey) then
      begin
        MDBInsert.OnDuplicateKey := MDBInsert.OnDuplicateKey + 'KEY ';
        GetNextToken;
      end;
      if (CurrentToken = tsqlUpdate) then
      begin
        MDBInsert.OnDuplicateKey := MDBInsert.OnDuplicateKey + 'UPDATE ';
        GetNextToken;
      end;
      while not (CurrentToken in [tsqlEOF, tsqlSemicolon]) do
      begin
        if CurrentToken = tsqlString then
          MDBInsert.OnDuplicateKey := MDBInsert.OnDuplicateKey +
            SQLFormatString(CurrentTokenString, [])
        else
          MDBInsert.OnDuplicateKey := MDBInsert.OnDuplicateKey + CurrentTokenString;

        GetNextToken;

        if not (CurrentToken in [tsqlComma, tsqlBraceClose, tsqlBraceOpen, tsqlDot, tsqlSemicolon]) and
           not (PreviousToken in [tsqlDot]) then
          MDBInsert.OnDuplicateKey := MDBInsert.OnDuplicateKey + ' ';
      end;
    end;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseDeleteStatement(AParent: TSQLElement
  ): TSQLDeleteStatement;
begin
  // On entry, we're on the DELETE token.
  Consume(tsqlDelete);
  Consume(tsqlFrom);
  Expect(tsqlIdentifier);
  Result := TSQLDeleteStatement(CreateElement(TSQLDeleteStatement, AParent));
  try
    Result.TableName := CreateIdentifier(Result, CurrentTokenString);
    GetNextToken;
    if CurrentToken = tsqlIdentifier then
    begin
      Result.AliasName := CreateIdentifier(Result, CurrentTokenString);
      GetNextToken;
    end;
    if CurrentToken = tsqlWhere then
    begin
      Consume(tsqlWhere);
      Result.WhereClause := ParseExprLevel1(Result, [eoWhereClause]);
    end;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseTableFieldDef(AParent : TSQLElement): TSQLTableFieldDef;
var
  MDBField: TSQLMariaDBTableFieldDef;
  PCount: Integer;
begin
  MDBField := TSQLMariaDBTableFieldDef(CreateElement(TSQLMariaDBTableFieldDef, AParent));
  Result := MDBField;
  try
    Result.FieldName := CreateIdentifier(Result, CurrentTokenString);
    if PeekNextToken = tsqlComputed then
    begin
      GetNextToken;
      Consume(tsqlComputed);
      if CurrentToken = tsqlBy then GetNextToken;
      Consume(tsqlBraceOpen);
      Result.ComputedBy := ParseExprLevel1(Result, [eoComputedBy]);
      Consume(tsqlBraceClose);
    end
    else
    begin
      Result.FieldType := ParseTypeDefinition(Result,
        [ptfAllowDomainName, ptfAllowConstraint, ptfTableFieldDef]);

      // --- INICIO SOPORTE MARIADB ---
      // Consumimos modificadores (DEFAULT, NOT NULL, AUTO_INCREMENT, COMMENT...)
      // y todo lo demás hasta chocar con la coma o paréntesis final
      PCount := 0;
      while not (CurrentToken in [tsqlEOF]) do
      begin
        if CurrentToken = tsqlBraceOpen then
          Inc(PCount)
        else if CurrentToken = tsqlBraceClose then
        begin
          if PCount = 0 then Break; // Es el ')' que cierra el CREATE TABLE
          Dec(PCount);
        end
        else if (CurrentToken = tsqlComma) and (PCount = 0) then
          Break; // Es la ',' que separa el siguiente campo

        // Acomodar espacios de forma inteligente
        if MDBField.RawModifiers <> '' then
        begin
          if not (PreviousToken in [tsqlDot, tsqlBraceOpen]) and
             not (CurrentToken in [tsqlBraceClose, tsqlComma, tsqlDot, tsqlSemicolon]) then
          begin
            // Evitar meter un espacio extra antes del '(' en funciones como current_timestamp()
            if not ((CurrentToken = tsqlBraceOpen) and (PreviousToken = tsqlIdentifier)) then
              MDBField.RawModifiers := MDBField.RawModifiers + ' ';
          end;
        end;

        // Reconstruir literales o cadenas
        if CurrentToken = tsqlString then
          MDBField.RawModifiers := MDBField.RawModifiers +
            SQLFormatString(CurrentTokenString, [])
        else
          MDBField.RawModifiers := MDBField.RawModifiers + CurrentTokenString;

        GetNextToken;
      end;
      // --- FIN SOPORTE MARIADB ---
    end;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseTableConstraint(AParent: TSQLElement
  ): TSQLTableConstraintDef;

  procedure ParseFieldList(R : TSQLTableFieldsConstraintDef);

  begin
    GetNextToken;
    Consume(tsqlBraceOpen);
    ParseIdentifierList(AParent, R.FieldList);
//    Consume(tsqlBraceClose);
  end;

var
  N : TSQLStringType;
  K : TSQLTableForeignKeyConstraintDef;

begin
  if CurrentToken = tsqlConstraint then
  begin
    GetNextToken;
    Expect(tsqlIdentifier);
    N := CurrentTokenString;
    GetNextToken
  end;
  Result := nil;
  try
    case CurrentToken of
      tsqlUnique :
        begin
          Result := TSQLTableUniqueConstraintDef
            (CreateElement(TSQLTableUniqueConstraintDef, AParent));
          ParseFieldList(TSQLTableFieldsConstraintDef(Result));
        end;
      tsqlPrimary :
        begin
          GetNextToken;
          Expect(tsqlKey);
          Result := TSQLTablePrimaryKeyConstraintDef
            (CreateElement(TSQLTablePrimaryKeyConstraintDef, AParent));
          ParseFieldList(TSQLTableFieldsConstraintDef(Result));
        end;
      tsqlForeign :
        begin
          GetNextToken;
          Expect(tsqlKey);
          K := TSQLTableForeignKeyConstraintDef
            (CreateElement(TSQLTableForeignKeyConstraintDef, AParent));
          Result := K;
          ParseFieldList(TSQLTableFieldsConstraintDef(Result));
          Expect(tsqlReferences);
          K.Definition := ParseForeignKeyDefinition(K);
        end;
      tsqlCheck:
        begin
          Result := TSQLTableCheckConstraintDef
            (CreateElement(TSQLTableCheckConstraintDef, AParent));
          TSQLTableCheckConstraintDef(Result).Check :=
            ParseCheckConstraint(Result, True);
        end
    else
      UnexpectedToken([tsqlUnique, tsqlPrimary, tsqlForeign, tsqlCheck]);
    end;
    if (N <> '') then
      Result.ConstraintName := CreateIdentifier(Result, N);
  //  GetNextToken;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseTableKeyConstraint(AParent: TSQLElement)
  : TSQLTableConstraintDef;
var
  K: TSQLMariaDBKeyConstraintDef;
begin
  Expect([tsqlKey, tsqlIndex]);
  K := TSQLMariaDBKeyConstraintDef(
    CreateElement(TSQLMariaDBKeyConstraintDef, AParent));
  Result := K;
  try
    GetNextToken;
    if CurrentToken = tsqlIdentifier then
    begin
      K.IndexName := CreateIdentifier(K, CurrentTokenString);
      GetNextToken;
    end;
    Consume(tsqlBraceOpen);
    ParseIdentifierList(K, K.FieldList);
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseCreateTableStatement(AParent: TSQLElement): TSQLCreateOrAlterStatement;
var
  C  : TSQLMariaDBCreateTableStatement; // CAMBIO: Usamos nuestra clase custom
  HC : Boolean;
begin
  Consume(tsqlTable);
  if CurrentToken = tsqlIf then
  begin
    GetNextToken;
    if CurrentToken = tsqlNot then GetNextToken;
    if CurrentToken = tsqlExists then GetNextToken;
  end;
  C := TSQLMariaDBCreateTableStatement(CreateElement(TSQLMariaDBCreateTableStatement, AParent));
  try
    Expect(tsqlIdentifier);
    C.ObjectName := CreateIdentifier(C, CurrentTokenString);
    GetNextToken;
    if (CurrentToken = tsqlExternal) then
    begin
      GetNextToken;
      if (CurrentToken = tsqlFile) then GetNextToken;
      Expect(tsqlString);
      C.ExternalFileName := CreateLiteral(C) as TSQLStringLiteral;
      GetNextToken;
    end;
    Expect(tsqlBraceOpen);
    HC := False;
    Repeat
      GetNextToken;
      case CurrentToken of
        tsqlIdentifier :
          begin
            if HC then UnexpectedToken;
            C.FieldDefs.Add(ParseTableFieldDef(C));
          end;
        tsqlCheck, tsqlConstraint, tsqlForeign, tsqlPrimary, tsqlUnique:
          begin
            C.Constraints.Add(ParseTableConstraint(C));
            HC := True;
          end;
        tsqlKey, tsqlIndex:
          begin
            C.Constraints.Add(ParseTableKeyConstraint(C));
            HC := True;
          end
      else
        UnexpectedToken([tsqlIdentifier, tsqlCheck, tsqlConstraint,
          tsqlForeign, tsqlPrimary, tsqlUnique, tsqlKey, tsqlIndex]);
      end;
      Expect([tsqlBraceClose, tsqlComma]);
    until (CurrentToken = tsqlBraceClose);
    GetNextToken; // Consume ')'
    while not (CurrentToken in [tsqlEOF, tsqlSemicolon]) do
    begin
      if CurrentToken = tsqlString then
        C.TableOptions := C.TableOptions +
          SQLFormatString(CurrentTokenString, []) + ' '
      else
        C.TableOptions := C.TableOptions + CurrentTokenString + ' ';
      GetNextToken;
    end;
    Result := C;
  except
    FreeAndNil(C);
    raise;
  end;
end;

function TSQLParser.ParseDropTableElement(AParent : TSQLElement)
  : TSQLDropTableElementOperation;
var
  C : Boolean;
begin
  // On entry, we are on DROP token
  C := (GetNextToken = tsqlConstraint);
  if C then
    GetNextToken
  else if CurrentToken = tsqlColumn then
    GetNextToken;
  Expect(tsqlIdentifier);
  if C then
    Result := TSQLDropTableConstraintOperation
      (CreateElement(TSQLDropTableConstraintOperation, AParent))
  else
    Result := TSQLDropTableFieldOperation
      (CreateElement(TSQLDropTableFieldOperation, AParent));
  Result.ObjectName := CreateIdentifier(Result, CurrentTokenString);
  GetNextToken;
end;

function TSQLParser.ParseAddTableElement(AParent : TSQLElement)
                                            : TSQLAlterTableAddElementOperation;
var
  Tk: TSQLToken;
begin
  Result := nil;
  try
    Tk := GetNextToken;

    // SOPORTE MARIADB: Bypass opcional "COLUMN"
    if Tk = tsqlColumn then
      Tk := GetNextToken;

    case Tk of
      tsqlIdentifier :
        begin
          Result := TSQLAlterTableAddElementOperation
            (CreateElement(TSQLAlterTableAddFieldOPeration, AParent));
          Result.Element := ParseTableFieldDef(Result);
        end;
      tsqlCheck,
        tsqlConstraint,
        tsqlForeign,
        tsqlPrimary,
        tsqlUnique:
        begin
          Result := TSQLAlterTableAddElementOperation
            (CreateElement(TSQLAlterTableAddConstraintOperation, AParent));
          Result.Element := ParseTableConstraint(Result);
        end
    else
      UnexpectedToken([tsqlIdentifier, tsqlCheck, tsqlConstraint, tsqlForeign,
        tsqlPrimary, tsqlUnique]);
    end;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseAlterTableElement(AParent : TSQLElement)
  : TSQLAlterTableOperation;
var
  N : TSQLStringType;
begin
  Result := nil;
  if GetNextToken = tsqlColumn then
    GetNextToken;
  Expect(tsqlIdentifier);
  N := CurrentTokenString;
  try
    case GetNextToken of
      tsqlTo :
        begin
          GetNextToken;
          Result := TSQLAlterTableOperation
            (CreateElement(TSQLAlterTableFieldNameOperation, AParent));
          TSQLAlterTableFieldNameOperation(Result).NewName :=
            CreateIdentifier(Result, CurrentTokenString);
          GetNextToken;
        end;
      tsqltype:
        begin
          Result := TSQLAlterTableOperation
            (CreateElement(TSQLAlterTableFieldTypeOperation, AParent));
          TSQLAlterTableFieldTypeOperation(Result).NewType :=
            ParseTypeDefinition(Result, [ptfAllowDomainName, ptfAllowConstraint,
            ptfTableFieldDef]);
        end;
      tsqlPosition:
        begin
          GetNextToken;
          Expect(tsqlIntegerNumber);
          Result := TSQLAlterTableOperation
            (CreateElement(TSQLAlterTableFieldPositionOperation, AParent));
          TSQLAlterTableFieldPositionOperation(Result).NewPosition :=
            StrToInt(CurrentTokenString);
          GetNextToken;
        end
    else
      UnexpectedToken([tsqlTo, tsqltype, tsqlPosition]);
    end;
    Result.ObjectName := CreateIdentifier(Result, N);
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseAlterTableStatement(AParent: TSQLElement): TSQLAlterTableStatement;
var
  RawOp: TSQLAlterTableRawOperation;
begin
  Consume(tsqlTable);
  Result := TSQLAlterTableStatement(CreateElement(TSQLAlterTableStatement, AParent));
  try
    Expect(tsqlIdentifier);
    Result.ObjectName := CreateIdentifier(Result, CurrentTokenString);
    Repeat
      GetNextToken;
      if (CurrentToken = tsqlIdentifier) and SameText(CurrentTokenString, 'CONVERT') then
      begin
        RawOp := TSQLAlterTableRawOperation(CreateElement(TSQLAlterTableRawOperation, Result));
        RawOp.RawText := 'CONVERT';
        GetNextToken;
        while not (CurrentToken in [tsqlEOF, tsqlSemicolon, tsqlComma]) do
        begin
          if CurrentToken = tsqlString then
            RawOp.RawText := RawOp.RawText + ' ' +
              SQLFormatString(CurrentTokenString, [])
          else
            RawOp.RawText := RawOp.RawText + ' ' + CurrentTokenString;
          GetNextToken;
        end;
        Result.Operations.Add(RawOp);
        if CurrentToken = tsqlSemicolon then Break;
        Continue;
      end;
      case CurrentToken of
        tsqlAdd: Result.Operations.Add(ParseAddTableElement(Result));
        tsqlAlter: Result.Operations.Add(ParseAlterTableElement(Result));
        tsqlDrop: Result.Operations.Add(ParseDropTableElement(Result));
      else
        UnexpectedToken([tsqlAdd, tsqlAlter, tsqlDrop]);
      end;
    until (CurrentToken <> tsqlComma);
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseCreateIndexStatement(AParent: TSQLElement; IsAlter: Boolean
  ): TSQLCreateOrAlterStatement;
var
  O : TIndexOptions;
  C : TSQLCreateIndexStatement;
  A : TSQLAlterIndexStatement;
begin
  O := [];
  // On enter, we're on the UNIQUE, ASCENDING, DESCENDING or INDEX token
  if IsAlter then
  begin
    Expect(tsqlIndex);
    Consume(tsqlIndex);
    A := TSQLAlterIndexStatement(CreateElement(TSQLAlterIndexStatement,
      AParent));
    try
      Expect(tsqlIdentifier);
      A.ObjectName := CreateIdentifier(A, CurrentTokenString);
      GetNextToken;
      Expect([tsqlActive, tsqlInactive]);
      A.Inactive := CurrentToken = tsqlInactive;
      GetNextToken; // Token after ) or (in)Active
      Result := A;
    except
      FreeAndNil(A);
      raise;
    end;
  end
  else
  begin
    C := TSQLCreateIndexStatement(CreateElement(TSQLCreateIndexStatement,
      AParent));
    try
      if (CurrentToken = tsqlUnique) then
      begin
        GetNextToken;
        Include(O, ioUnique);
      end;
      if (CurrentToken = tsqlAscending) then
      begin
        GetNextToken;
        Include(O, ioAscending);
      end
      else if (CurrentToken = tsqlDescending) then
      begin
        GetNextToken;
        Include(O, ioDescending);
      end;
      C.Options := O;
      Consume(tsqlIndex);
      Expect(tsqlIdentifier);
      C.ObjectName := CreateIdentifier(C, CurrentTokenString);
      GetNextToken;
      Consume(tsqlOn);
      Expect(tsqlIdentifier);
      C.TableName := CreateIdentifier(C, CurrentTokenString); // name of table
      GetNextToken;
      Consume(tsqlBraceOpen);
      ParseIdentifierList(C, C.FieldNames);
      Result := C;
    except
      FreeAndNil(C);
      raise;
    end;
  end;
end;

function TSQLParser.ParseCreateViewStatement(AParent: TSQLElement; IsAlter: Boolean
  ): TSQLCreateOrAlterStatement;
var
  V : TSQLCreateViewStatement;
begin
  // on entry, we're on the VIEW token.
  if IsAlter then
    UnexpectedToken;
  Result := nil;
  Consume(tsqlView);
  Expect(tsqlIdentifier);
  V := TSQLCreateViewStatement(CreateElement(TSQLCreateViewStatement, AParent));
  Result := V;
  try
    V.ObjectName := CreateIdentifier(V, CurrentTokenString);
    GetNextToken;
    if (CurrentToken = tsqlBraceOpen) then
    begin
      GetNextToken;
      ParseIdentifierList(Result, V.Fields);
    end;
    Consume(tsqlAs);
    V.Select := ParseSelectStatement(V, []);
    if (CurrentToken = tsqlWith) then
    begin
      GetNextToken;
      Consume(tsqlCheck);
      Consume(tsqlOption);
      V.WithCheckOption := True;
    end;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

procedure TSQLParser.ParseProcedureParamList(AParent: TSQLElement;
  AList : TSQLelementList);

var
  P : TSQLProcedureParamDef;
  Dir : string;

begin
  // On Entry, we're on the ( token
  GetNextToken; // primer token tras '(' (o ')' si la lista esta vacia)
  // Lista de parametros vacia: PROCEDURE nombre()
  if CurrentToken <> tsqlBraceClose then
  begin
    Repeat
      // En la 2a y siguientes vueltas venimos sobre ',': saltamos al
      // primer token del parametro.
      if CurrentToken = tsqlComma then
        GetNextToken;
      // --- SOPORTE MARIADB: opcional IN / OUT / INOUT ---
      Dir := '';
      if CurrentToken = tsqlIN then
      begin
        Dir := 'IN';
        GetNextToken;
      end
      else if (CurrentToken = tsqlIdentifier) and
              (SameText(CurrentTokenString, 'OUT') or
               SameText(CurrentTokenString, 'INOUT')) then
      begin
        Dir := UpperCase(CurrentTokenString);
        GetNextToken;
      end;
      Expect(tsqlIdentifier);
      P := TSQLProcedureParamDef(CreateElement(TSQLProcedureParamDef, AParent));
      try
        AList.Add(P);
      except
        P.free;
        raise;
      end;
      P.Direction := Dir;
      P.ParamName := CreateIdentifier(P, CurrentTokenString);
      // Typedefinition will go to next token
      P.ParamType := ParseTypeDefinition(P, [ptProcedureParam]);
    Until (CurrentToken <> tsqlComma);
  end;
  Consume(tsqlBraceClose);
end;

procedure TSQLParser.ParseCreateProcedureVariableList(AParent: TSQLElement;
  AList : TSQLelementList);

var
  P : TSQLProcedureParamDef;

begin
  // On Entry, we're on the DECLARE token
  Repeat
    Consume(tsqlDeclare);
    Consume(tsqlVariable);
    Expect(tsqlIdentifier);
    P := TSQLProcedureParamDef(CreateElement(TSQLProcedureParamDef, AParent));
    Try
      AList.Add(P);
    except
      P.free;
      raise;
    end;
    P.ParamName := CreateIdentifier(P, CurrentTokenString);
    // Typedefinition will go to next token
    P.ParamType := ParseTypeDefinition(P, [ptProcedureParam]);
    Consume(tsqlSemicolon);
  Until (CurrentToken <> tsqlDeclare);
end;

function TSQLParser.ParseIfStatement(AParent : TSQLElement) : TSQLIFStatement;
var
  HasBrace: Boolean;
  Block: TSQLStatementBlock;
begin
  Consume(tsqlIf);
  HasBrace := (CurrentToken = tsqlBraceOpen);
  if HasBrace then Consume(tsqlBraceOpen);
  Result := TSQLIFStatement(CreateElement(TSQLIFStatement, AParent));
  try
    Result.Condition := ParseExprLevel1(AParent, [eoIF]);
    if HasBrace then Consume(tsqlBraceClose);
    Consume(tsqlThen);
    if CurrentToken <> tsqlBegin then
    begin
      Block := TSQLStatementBlock(CreateElement(TSQLStatementBlock, Result));
      while not (CurrentToken in [tsqlElse, tsqlEnd, tsqlEOF]) do
      begin
         Block.Statements.Add(ParseProcedureStatement(Block));
         if CurrentToken = tsqlSemicolon then Consume(tsqlSemicolon);
      end;
      Result.TrueBranch := Block;
    end
    else
      Result.TrueBranch := ParseProcedureStatement(Result);
    if (CurrentToken = tsqlElse) then
    begin
      GetNextToken;
      if CurrentToken <> tsqlBegin then
      begin
        Block := TSQLStatementBlock(CreateElement(TSQLStatementBlock, Result));
        while not (CurrentToken in [tsqlEnd, tsqlEOF]) do
        begin
           Block.Statements.Add(ParseProcedureStatement(Block));
           if CurrentToken = tsqlSemicolon then Consume(tsqlSemicolon);
        end;
        Result.FalseBranch := Block;
      end
      else
        Result.FalseBranch := ParseProcedureStatement(Result);
    end;
    if (CurrentToken = tsqlEnd) then
    begin
      if (PeekNextToken = tsqlIf) then
      begin
        GetNextToken; // Consume END
        GetNextToken; // Consume IF
      end;
    end;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

procedure TSQLParser.ParseIntoList(AParent : TSQLElement;
  List : TSQLelementList);

begin
  // On Entry, we're on the INTO token
  Repeat
    GetNextToken;
    if (CurrentToken = tsqlColon) then
      Consume(tsqlColon);
    Expect(tsqlIdentifier);
    List.Add(CreateIdentifier(AParent, CurrentTokenString));
    GetNextToken;
  Until (CurrentToken <> tsqlComma);
end;

function TSQLParser.ParseForStatement(AParent : TSQLElement) : TSQLForStatement;

begin
  // On Entry, we're on the FOR token
  Consume(tsqlFor);
  Expect(tsqlSelect);
  Result := TSQLForStatement(CreateElement(TSQLForStatement, AParent));
  try
    Result.Select := ParseSelectStatement(Result, []);
    Expect(tsqlInto);
    ParseIntoList(Result, Result.FieldList);
    Consume(tsqlDo);
    Result.Statement := ParseProcedureStatement(Result);
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseExceptionStatement(AParent : TSQLElement)
  : TSQLExceptionStatement;

begin
  // On Entry, we're on the EXCEPTION token
  Consume(tsqlException);
  Expect(tsqlIdentifier);
  Result := TSQLExceptionStatement(CreateElement(TSQLExceptionStatement,
    AParent));
  try
    Result.ExceptionName := CreateIdentifier(Result, CurrentTokenString);
    GetNextToken;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseAssignStatement(AParent : TSQLElement)
  : TSQLAssignStatement;

var
  N : TSQLStringType;

begin
  // On entry, we're on the identifier token;
  Expect(tsqlIdentifier);
  Result := TSQLAssignStatement(CreateElement(TSQLAssignStatement, AParent));
  try
    N := CurrentTokenString;
    GetNextToken;
    if (CurrentToken = tsqlDot) and (Uppercase(N) = 'NEW') then
    begin
      GetNextToken;
      Expect(tsqlIdentifier);
      N := N + '.' + CurrentTokenString;
      GetNextToken;
    end;
    Result.Variable := CreateIdentifier(Result, N);
    Consume(tsqlEq);
    Result.Expression := ParseExprLevel1(Result, []);
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParsePostEventStatement(AParent : TSQLElement)
  : TSQLPostEventStatement;

begin
  // On Entry, we're on the POST_EVENT token
  Consume(tsqlPostEvent);
  Result := TSQLPostEventStatement(CreateElement(TSQLPostEventStatement,
    AParent));
  try
    case CurrentToken of
      tsqlIdentifier :
        Result.ColName := CreateIdentifier(Result, CurrentTokenString);
      tsqlString :
        Result.EventName := CurrentTokenString;
    else
      UnexpectedToken([tsqlIdentifier, tsqlString]);
    end;
    GetNextToken;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseWhileStatement(AParent : TSQLElement)
  : TSQLWhileStatement;

begin
  // On entry, we're on the while Token
  Consume(tsqlWhile);
  Consume(tsqlBraceOpen);
  Result := TSQLWhileStatement(CreateElement(TSQLWhileStatement, AParent));
  try
    Result.Condition := ParseExprLevel1(Result, [eoIF]);
    Consume(tsqlBraceClose);
    Consume(tsqlDo);
    Result.Statement := ParseProcedureStatement(Result);
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseWhenStatement(AParent : TSQLElement)
  : TSQLWhenStatement;

var
  E : TSQLWhenException;
  S : TSQLWhenSQLError;
  G : TSQLWhenGDSError;

begin
  Consume(tsqlWhen);
  Result := TSQLWhenStatement(CreateElement(TSQLWhenStatement, AParent));
  try
    if (CurrentToken = tsqlAny) then
    begin
      Result.AnyError := True;
      GetNextToken
    end
    else
      Repeat
        if (Result.Errors.Count > 0) then
          GetNextToken;
        case CurrentToken of
          tsqlException:
            begin
              GetNextToken;
              Expect(tsqlIdentifier);
              E := TSQLWhenException(CreateElement(TSQLWhenException, AParent));
              E.ExceptionName := CreateIdentifier(E, CurrentTokenString);
              Result.Errors.Add(E);
            end;
          tsqlSQLCode:
            begin
              GetNextToken;
              Expect(tsqlIntegerNumber);
              S := TSQLWhenSQLError(CreateElement(TSQLWhenSQLError, AParent));
              S.ErrorCode := StrToInt(CurrentTokenString);
              Result.Errors.Add(S);
            end;
          tsqlGDSCODE:
            begin
              GetNextToken;
              Expect(tsqlIntegerNumber);
              G := TSQLWhenGDSError(CreateElement(TSQLWhenGDSError, AParent));
              G.GDSErrorNumber := StrToInt(CurrentTokenString);
              Result.Errors.Add(G);
            end;
        else
          UnexpectedToken([tsqlException, tsqlSQLCode, tsqlGDSCODE]);
        end;
        GetNextToken;
      until (CurrentToken <> tsqlComma);
    Consume(tsqlDo);
    Result.Statement := ParseProcedureStatement(Result);
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseProcedureStatement(AParent : TSQLElement)
  : TSQLStatement;

begin
  Result := nil;
  case CurrentToken of
    tsqlBegin :
      begin
        Result := TSQLStatementBlock(CreateElement(TSQLStatementBlock,
          AParent));
        ParseStatementBlock(Result, TSQLStatementBlock(Result).Statements);
      end;
    tsqlIf :
      Result := ParseIfStatement(AParent);
    tsqlFor :
      Result := ParseForStatement(AParent);
    tsqlException :
      Result := ParseExceptionStatement(AParent);
    tsqlIdentifier :
      Result := ParseAssignStatement(AParent);
    tsqlExecute :
      Result := ParseExecuteProcedureStatement(AParent);
    tsqlExit :
      begin
        Result := TSQLExitStatement(CreateElement(TSQLExitStatement, AParent));
        GetNextToken;
      end;
    tsqlSuspend :
      begin
        Result := TSQLSuspendStatement(CreateElement(TSQLSuspendStatement,
          AParent));
        GetNextToken;
      end;
    tsqlPostEvent :
      Result := ParsePostEventStatement(AParent);
    tsqlWhile :
      Result := ParseWhileStatement(AParent);
    tsqlWhen :
      Result := ParseWhenStatement(AParent);
    tsqlSelect :
      Result := ParseSelectStatement(AParent, [sfInto]);
    tsqlInsert :
      Result := ParseInsertStatement(AParent);
    tsqlDelete :
      Result := ParseDeleteStatement(AParent);
    tsqlUpdate :
      Result := ParseUpdateStatement(AParent);
  else
    UnexpectedToken;
  end;
end;

procedure TSQLParser.ParseStatementBlock(AParent: TSQLElement;
  Statements : TSQLelementList);

var
  S: TSQLStatement;

begin
  Consume(tsqlBegin);
  while (CurrentToken <> tsqlEnd) do
  begin
    S := ParseProcedureStatement(AParent);
    Statements.Add(S);
    if not(PreviousToken = tsqlEnd) then
      Consume(tsqlSemicolon);
  end;
  Consume(tsqlEnd);
end;

function TSQLParser.ParseCreateProcedureStatement(AParent: TSQLElement; IsAlter: Boolean
  ): TSQLCreateOrAlterStatement;

var
  P : TSQLAlterCreateProcedureStatement;

begin
  // On entry, we're on the procedure statement.
  Consume(tsqlProcedure);
  Expect(tsqlIdentifier);
  if IsAlter then
    P := TSQLAlterProcedureStatement
      (CreateElement(TSQLAlterProcedureStatement, AParent))
  else
    P := TSQLCreateProcedureStatement
      (CreateElement(TSQLCreateProcedureStatement, AParent));
  Result := P;
  try
    Result.ObjectName := CreateIdentifier(P, CurrentTokenString);
    GetNextToken;
    if (CurrentToken = tsqlBraceOpen) then
      ParseProcedureParamList(Result, P.InputVariables);
    if (CurrentToken = tsqlReturns) then
    begin
      GetNextToken;
      Expect(tsqlBraceOpen);
      ParseProcedureParamList(Result, P.OutputVariables);
    end;

    // --- SOPORTE MARIADB: 'AS' es opcional ---
    if CurrentToken = tsqlAs then
      GetNextToken;

    if CurrentToken = tsqlDeclare then
    begin
      // Estilo Firebird: DECLARE VARIABLE ... antes de BEGIN
      ParseCreateProcedureVariableList(Result, P.LocalVariables);
      Expect(tsqlBegin);
      ParseStatementBlock(Result, P.Statements);
    end
    else if (CurrentToken = tsqlBegin) or
            // SOPORTE MARIADB: bloque etiquetado "label: BEGIN ... END label;"
            ((CurrentToken = tsqlIdentifier) and (PeekNextToken = tsqlColon)) then
    begin
      // Estilo MariaDB: captura el cuerpo (con etiqueta opcional) como texto
      P.MariaDBBodyText := ParseProcedureBodyAsRaw;
    end
    else
      UnexpectedToken;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseCreateGeneratorStatement(AParent: TSQLElement; IsAlter: Boolean
  ): TSQLCreateOrAlterStatement;
begin
  GetNextToken;
  Expect(tsqlIdentifier);
  if IsAlter then
    Error(SErrCannotAlterGenerator);
  Result := TSQLCreateOrAlterStatement
    (CreateElement(TSQLCreateGeneratorStatement, AParent));
  try
    Result.ObjectName := CreateIdentifier(Result, CurrentTokenString);
  except
    FreeAndNil(Result);
    raise;
  end;
  GetNextToken; // Comma;
end;

function TSQLParser.ParseCreateRoleStatement(AParent: TSQLElement;
  IsAlter: Boolean): TSQLCreateOrAlterStatement;
begin
  if IsAlter then
    UnexpectedToken; // no ALTER ROLE
  GetNextToken;
  Expect(tsqlIdentifier);
  Result := TSQLCreateOrAlterStatement(CreateElement(TSQLCreateRoleStatement,
    AParent));
  Result.ObjectName := CreateIdentifier(Result, CurrentTokenString);
  GetNextToken; // Comma;
end;

procedure TSQLParser.ParseCharTypeDefinition(Out DT : TSQLDataType;
  Out Len : Integer; Out ACharset : TSQLStringType);

begin
  Len := 0;
  case CurrentToken of
    tsqlNCHAR :
      DT := sdtNchar;
    tsqlVarChar :
      DT := sdtVarChar;
    tsqlCharacter,
      tsqlChar :
      DT := sdtChar;
    tsqlCString :
      DT := sdtCstring;
    tsqlNational :
      begin
        DT := sdtNchar;
        GetNextToken;
        Expect([tsqlCharacter, tsqlChar]);
      end;
  end;
  GetNextToken; // VARYING, Start of size, CHARACTER set or end
  if (CurrentToken = tsqlVarying) then // CHAR VARYING or CHARACTER VARYING;
  begin
    if (DT in [sdtNchar, sdtChar]) then
    begin
      if DT = sdtNchar then
        DT := sdtNVARCHAR
      else
        DT := sdtVarChar;
      GetNextToken
    end
    else
      Error(SERRVaryingNotAllowed);
  end;
  if (CurrentToken = tsqlBraceOpen) then // (LEN)
  begin
    GetNextToken;
    Expect(tsqlIntegerNumber);
    Len := StrToInt(CurrentTokenString);
    GetNextToken;
    Expect(tsqlBraceClose);
    GetNextToken;
  end
  else if (DT = sdtCstring) then
    UnexpectedToken;
  if (CurrentToken = tsqlCharacter) or
     ((CurrentToken = tsqlIdentifier) and
      SameText(CurrentTokenString, 'CHARSET')) then
  begin
    if (DT = sdtCstring) then
      UnexpectedToken;
    if CurrentToken = tsqlCharacter then
    begin
      GetNextToken;
      Consume(tsqlSet);
    end
    else
      GetNextToken;
    Expect(tsqlIdentifier);
    ACharset := CurrentTokenString;
    GetNextToken;
  end;
end;

procedure TSQLParser.ParseBlobDefinition(var ASegmentSize, ABlobType : Integer;
  var ACharset : TSQLStringType);

begin
  // On entry, we are on the blob token.
  GetNextToken;
  if (CurrentToken = tsqlBraceOpen) then // (segment[,subtype])
  begin
    GetNextToken;
    Expect(tsqlIntegerNumber);
    ASegmentSize := StrToInt(CurrentTokenString);
    GetNextToken;
    if (CurrentToken = tsqlComma) then
    begin
      GetNextToken;
      Expect(tsqlIntegerNumber);
      ABlobType := StrToInt(CurrentTokenString);
      GetNextToken;
    end;
    Consume(tsqlBraceClose);
    if CurrentToken in [tsqlSubtype, tsqlSegment] then
      Error(SErrUnexpectedToken, [CurrentTokenString]);
  end
  else
  begin
    if CurrentToken = tsqlSubtype then // SUB_TYPE T
    begin
      GetNextToken;
      Expect(tsqlIntegerNumber);
      ABlobType := StrToInt(CurrentTokenString);
      GetNextToken;
    end;
    if (CurrentToken = tsqlSegment) then // SEGMENT SIZE S
    begin
      GetNextToken;
      Consume(tsqlSize);
      Expect(tsqlIntegerNumber);
      ASegmentSize := StrToInt(CurrentTokenString);
      GetNextToken;
    end;
  end;
  if (CurrentToken = tsqlCharacter) then // CHARACTER set NNN
  begin
    GetNextToken;
    Consume(tsqlSet);
    Expect(tsqlIdentifier);
    ACharset := CurrentTokenString;
    GetNextToken;
  end;
end;

function TSQLParser.ParseForeignKeyDefinition(AParent : TSQLElement)
  : TSQLForeignKeyDefinition;

  // On entry, we're on ON Return true if On delete
  function ParseForeignKeyAction(Out Res : TForeignKeyAction) : Boolean;

  begin
    GetNextToken;
    case CurrentToken of
      tsqlDelete,
        tsqlUpdate:
        Result := CurrentToken = tsqlDelete;
    else
      UnexpectedToken([tsqlDelete, tsqlUpdate]);
    end;
    case GetNextToken of
      tsqlNo :
        begin
          GetNextToken;
          Expect(tsqlAction);
          Res := fkaNoAction;
        end;
      tsqlCascade :
        Res := fkaCascade;
      tsqlSet:
        begin
          case GetNextToken of
            tsqlDefault :
              Res := fkaSetDefault;
            tsqlNull:
              Res := fkaSetNull;
          else
            UnexpectedToken([tsqlDefault, tsqlNull]);
          end;
        end
    else
      UnexpectedToken([tsqlNo, tsqlCascade, tsqlSet]);
    end;
    GetNextToken;
  end;

var
  FKA : TForeignKeyAction;

begin
  Result := nil;
  // on entry, we are on the 'REFERENCES' token
  GetNextToken;
  Expect(tsqlIdentifier);
  Result := TSQLForeignKeyDefinition(CreateElement(TSQLForeignKeyDefinition,
    AParent));
  try
    Result.TableName := CreateIdentifier(Result, CurrentTokenString);
    GetNextToken;
    if (CurrentToken = tsqlBraceOpen) then
    begin
      GetNextToken;
      ParseIdentifierList(Result, Result.FieldList);
    end;
    if (CurrentToken = tsqlOn) then
    begin
      if ParseForeignKeyAction(FKA) then
        Result.OnDelete := FKA
      else
        Result.OnUpdate := FKA;
    end;
    if (CurrentToken = tsqlOn) then
    begin
      if ParseForeignKeyAction(FKA) then
        Result.OnDelete := FKA
      else
        Result.OnUpdate := FKA;
    end;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseFieldConstraint(AParent : TSQLElement)
  : TSQLFieldConstraint;

var
  N : TSQLStringType;
  K : TSQLForeignKeyFieldConstraint;
  C : TSQLCheckFieldConstraint;
  L : TSQLFieldConstraintList;
  P : Boolean;
begin
  Result := nil;
  L := nil;
  P := False;
  try
    Repeat
      if (Result <> nil) then
      begin
        L := TSQLFieldConstraintList.Create(AParent);
        L.List.Add(Result);
        Result := nil;
      end;
      if CurrentToken = tsqlConstraint then
      begin
        GetNextToken;
        Expect(tsqlIdentifier);
        N := CurrentTokenString;
        GetNextToken
      end;
      case CurrentToken of
        tsqlUnique :
          begin
            if P then
              Error('Only one primary/unique field constraint allowed');
            Result := TSQLFieldConstraint
              (CreateElement(TSQLUniqueFieldConstraint, AParent));
            GetNextToken;
            P := True;
          end;
        tsqlPrimary :
          begin
            if P then
              Error('Only one primary/unique field constraint allowed');
            GetNextToken;
            Expect(tsqlKey);
            Result := TSQLFieldConstraint
              (CreateElement(TSQLPrimaryKeyFieldConstraint, AParent));
            GetNextToken;
            P := True;
          end;
        tsqlReferences :
          begin
            K := TSQLForeignKeyFieldConstraint
              (CreateElement(TSQLForeignKeyFieldConstraint, AParent));
            Result := K;
            K.Definition := ParseForeignKeyDefinition(K);
          end;
        tsqlCheck :
          begin
            C := TSQLCheckFieldConstraint
              (CreateElement(TSQLCheckFieldConstraint, AParent));
            Result := C;
            C.Expression := ParseCheckConstraint(K, True);
          end
      else
        UnexpectedToken([tsqlUnique, tsqlPrimary, tsqlReferences, tsqlCheck]);
      end;
      if (N <> '') then
        Result.ConstraintName := CreateIdentifier(Result, N);
    Until Not(CurrentToken in [tsqlUnique, tsqlPrimary, tsqlReferences,
      tsqlCheck, tsqlConstraint]);
    if Assigned(L) then
    begin
      L.List.Add(Result);
      Result := L;
    end;
  except
    if (L <> Result) then
      FreeAndNil(L);
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseTypeDefinition(AParent : TSQLElement;
  Flags : TParseTypeFlags) : TSQLTypeDefinition;
var
  TN       : string;
  AD       : Integer;
  DT       : TSQLDataType;
  GN       : Boolean; // Do GetNextToken ?
  sc, prec : Integer;
  bt       : Integer;
  D        : TSQLTypeDefinition;
  cs       : TSQLStringType;
  Coll     : TSQLCollation;
  C        : TSQLFieldConstraint;
begin
 // We are positioned on the token prior to the type definition.
  GN := True;
  prec := 0;
  sc := 0;
  bt := 0;
  Coll := nil;
  case GetNextToken of
    tsqlIdentifier :
      begin
        // MariaDB: tipos no tokenizados (TINYINT, MEDIUMINT, BIGINT, TEXT,
        // TINYTEXT, MEDIUMTEXT, LONGTEXT, DATETIME, ENUM, SET, JSON, BOOL,
        // DOUBLE...) o nombres de dominio. Llegan como identificador; los
        // aceptamos como nombre de tipo y capturamos un posible (n) / (n,m) /
        // ('a','b') como parte del nombre, para reproducirlo tal cual.
        DT := sdtDomain;
        TN := CurrentTokenString;
        if PeekNextToken = tsqlBraceOpen then
        begin
          GetNextToken; // sobre '('
          TN := TN + '(';
          GetNextToken;
          while not (CurrentToken in [tsqlBraceClose, tsqlEOF]) do
          begin
            if CurrentToken = tsqlString then
              TN := TN + SQLFormatString(CurrentTokenString, [])
            else if CurrentToken = tsqlComma then
              TN := TN + ', '
            else
              TN := TN + CurrentTokenString;
            GetNextToken;
          end;
          TN := TN + ')';
          GN := False; // ya gestionamos el avance tras ')'
          GetNextToken; // token siguiente al ')'
        end;
      end;
    tsqlInt,
      tsqlInteger :
      DT := sdtInteger;
    tsqlSmallInt :
      DT := sdtSmallInt;
    tsqlDate:
      DT := sdtDate;
    tsqlTimeStamp:
      DT := sdtDateTime;
    tsqlFloat:
      DT := sdtFloat;
    tsqlTime:
      DT := sdtTime;
    tsqlDecimal,
      tsqlNumeric:
      begin
        if CurrentToken = tsqlDecimal then
          DT := sdtDecimal
        else
          DT := sdtNumeric;
        GetNextToken;
        GN := False;
        if (CurrentToken = tsqlBraceOpen) then
        begin
          GetNextToken;
          Expect(tsqlIntegerNumber);
          prec := StrToInt(CurrentTokenString);
          if (GetNextToken = tsqlBraceClose) then
            sc := 0
          else
          begin
            GetNextToken;
            Expect(tsqlIntegerNumber);
            sc := StrToInt(CurrentTokenString);
            GetNextToken;
            Expect(tsqlBraceClose);
          end;
          GetNextToken;
          // position on first token after closing brace. GN=False !
        end;
      end;
    tsqlCString,
      tsqlChar,
      tsqlNCHAR,
      tsqlVarChar,
      tsqlCharacter,
      tsqlNational :
      begin
        if (CurrentToken = tsqlCString) and
          Not(([ptfExternalFunction, ptfExternalFunctionResult] * Flags)
          <> []) then
          UnexpectedToken;
        GN := False;
        ParseCharTypeDefinition(DT, prec, cs);
      end;
    tsqlBlob :
      begin
        DT := sdtBlob;
        GN := False;
        ParseBlobDefinition(prec, bt, cs);
      end;
  else
    UnexpectedToken;
  end;
  if GN then
    GetNextToken;
  // We are now on array or rest of type.
  if (CurrentToken = tsqlSquareBraceOpen) then
  begin
    GetNextToken;
    Expect(tsqlIntegerNumber);
    AD := StrToInt(CurrentTokenString);
    GetNextToken;
    Expect(tsqlSquareBraceClose);
    GetNextToken;
  end
  else
    AD := 0;

  // --- INICIO MODIFICACION MARIADB: Bypass estricto para tablas ---
  if not (ptfTableFieldDef in Flags) then
  begin
    if (CurrentToken = tsqlCollate) then
    begin
      if not(DT in [sdtChar, sdtVarChar, sdtNchar, sdtNVARCHAR, sdtBlob]) then
        Error(SErrInvalidUseOfCollate);
      GetNextToken;
      Expect(tsqlIdentifier);
      Coll := TSQLCollation(CreateElement(TSQLCollation, AParent));
      Coll.Name := CurrentTokenString;
      GetNextToken;
    end
    else
      Coll := nil;
  end
  else
    Coll := nil;
  // --- FIN MODIFICACION MARIADB ---

  C := nil;
  D := TSQLTypeDefinition(CreateElement(TSQLTypeDefinition, AParent));
  try
    D.DataType := DT;
    D.TypeName := TN;
    D.Len := prec;
    D.Scale := sc;
    D.BlobType := bt;
    D.ArrayDim := AD;
    D.Charset := cs;
    D.Collation := Coll;
    D.Constraint := C;

    // --- INICIO MODIFICACION MARIADB ---
    // Si NO es un campo de tabla, seguimos parseando normalmente
    if (not(ptfAlterDomain in Flags)) and (not(ptfTableFieldDef in Flags)) then
    begin
      if CurrentToken = tsqlNull then GetNextToken; // Tolerancia a "NULL DEFAULT..."

      if (CurrentToken = tsqlDefault) then
      begin
        GetNextToken;
        D.DefaultValue := CreateLiteral(D);
        GetNextToken;
      end;

      if CurrentToken = tsqlNull then GetNextToken;

      if (CurrentToken = tsqlNot) then
      begin
        GetNextToken;
        Expect(tsqlNull);
        D.NotNull := True;
        GetNextToken;
      end;
      if (CurrentToken = tsqlCheck) and not(ptfTableFieldDef in Flags) then
      begin
        D.Check := ParseCheckConstraint(D, False);
      end;
      if CurrentToken in [tsqlConstraint, tsqlCheck, tsqlUnique, tsqlPrimary, tsqlReferences] then
      begin
        if Not(ptfAllowConstraint in Flags) then UnexpectedToken;
        D.Constraint := ParseFieldConstraint(AParent);
      end;
      if (CurrentToken = tsqlCheck) and (ptfTableFieldDef in Flags) then
      begin
        D.Check := ParseCheckConstraint(D, False);
      end;
      if (CurrentToken = tsqlCollate) then
      begin
        if not(DT in [sdtChar, sdtVarChar, sdtNchar, sdtNVARCHAR, sdtBlob]) then
          Error(SErrInvalidUseOfCollate);
        GetNextToken;
        Expect(tsqlIdentifier);
        Coll := TSQLCollation(CreateElement(TSQLCollation, AParent));
        Coll.Name := CurrentTokenString;
        GetNextToken;
      end
      else
        Coll := nil;
      if (CurrentToken = tsqlBy) and (ptfExternalFunctionResult in Flags) then
      begin
        GetNextToken;
        Consume(tsqlValue);
        D.ByValue := True;
      end;
    end;
    // --- FIN MODIFICACION MARIADB ---

    Result := D;
  except
    FreeAndNil(D);
    raise;
  end;
end;

function TSQLParser.CreateLiteral(AParent : TSQLElement) : TSQLLiteral;

begin
  Result := nil;
  case CurrentToken of
    tsqlIntegerNumber:
      begin
        Result := TSQLLiteral(CreateElement(TSQLIntegerLiteral, AParent));
        TSQLIntegerLiteral(Result).Value := StrToInt(CurrentTokenString);
      end;
    tsqlString:
      begin
        Result := TSQLLiteral(CreateElement(TSQLStringLiteral, AParent));
        TSQLStringLiteral(Result).Value := CurrentTokenString;
      end;
    tsqlFloatNumber:
      begin
        Result := TSQLLiteral(CreateElement(TSQLFloatLiteral, AParent));
        TSQLFloatLiteral(Result).Value := StrToFloat(
          CurrentTokenString, TFormatSettings.Invariant);
      end;
    tsqlNull :
      Result := TSQLLiteral(CreateElement(TSQLNullLiteral, AParent));
    tsqlValue :
      Result := TSQLLiteral(CreateElement(TSQLValueLiteral, AParent));
    tsqlUSER :
      Result := TSQLLiteral(CreateElement(TSQLUserLiteral, AParent));
  else
    Error(SErrInvalidLiteral, [CurrentTokenString]);
  end;
end;

procedure TSQLParser.CheckEOF;

begin
  if CurrentToken = tsqlEOF then
    Error('Unexpected end of command');
end;

function TSQLParser.ParseExprLevel1(AParent : TSQLElement;
  EO : TExpressionOptions) : TSQLExpression;
var
  tt   : TSQLToken;
  B    : TSQLBinaryExpression;
  L    : TSQLLiteralExpression;
begin
  Result := ParseExprLevel2(AParent, EO);
  Try
    while (CurrentToken in [tsqlAnd, tsqlOr{,tsqlIs}]) do
    begin
      tt := CurrentToken;
      GetNextToken;
      CheckEOF;
      B := TSQLBinaryExpression(CreateElement(TSQLBinaryExpression, AParent));
      B.Left := TSQLExpression(Result);
      Result := B;
      if tt = tsqlIs then
      begin
        if CurrentToken = tsqlNot then
        begin
//           B.Operation:=boIsNot;
          GetNextToken;
        end
        else
          B.Operation := boIs;
        if (CurrentToken = tsqlNull) or
           ((CurrentToken = tsqlIdentifier) and SameText(CurrentTokenString, 'NULL')) then
          GetNextToken
        else
          Expect(tsqlNull);
        L := TSQLLiteralExpression(CreateElement(TSQLLiteralExpression,
          AParent));
        L.Literal := CreateLiteral(AParent);
        B.Right := L;
        GetNextToken;
      end
      else
      begin
        case tt of
          tsqlOr :
            B.Operation := boOr;
          tsqlAnd :
            B.Operation := boAnd;
        Else
          Error(SErrUnknownBooleanOp)
        end;
        B.Right := ParseExprLevel2(AParent, EO);
      end;
    end;
  Except
    Result.free;
    raise;
  end;
end;

function TSQLParser.ParseInoperand(AParent : TSQLElement) : TSQLExpression;

var
  S    : TSQLSelectExpression;
  L    : TSQLListExpression;
  Done : Boolean;

begin
  // On entry, we're on the first token after IN token, which is the ( token.
  Consume(tsqlBraceOpen);
  try
    if (CurrentToken = tsqlSelect) then
    begin
      S := TSQLSelectExpression(CreateElement(TSQLSelectExpression, AParent));
      Result := S;
      S.Select := ParseSelectStatement(AParent, [sfSingleTon]);
      Consume(tsqlBraceClose);
    end
    else
    begin
      L := TSQLListExpression(CreateElement(TSQLListExpression, AParent));
      Result := L;
      Repeat
        L.List.Add(ParseExprLevel1(L, [eoListValue]));
        Expect([tsqlBraceClose, tsqlComma]);
        Done := (CurrentToken = tsqlBraceClose);
        GetNextToken;
      until Done;

    end;
  except
    FreeAndNil(Result);
  end;
end;

function TSQLParser.ParseExprLevel2(AParent : TSQLElement;
  EO : TExpressionOptions) : TSQLExpression;
var
  tt          : TSQLToken;
  Right       : TSQLExpression;
  B           : TSQLBinaryExpression;
  T           : TSQLTernaryExpression;
  O           : TSQLBinaryOperation;
  U           : TSQLUnaryExpression;
  I, bw, doin : Boolean;

begin

{$IFDEF debugexpr} Writeln('Level 2 ', TokenInfos[CurrentToken], ': ', CurrentTokenString); {$ENDIF debugexpr}

  Result := ParseExprLevel3(AParent, EO);
  try
    if (CurrentToken in sqlComparisons) then
    begin
      tt := CurrentToken;
      I := CurrentToken = tsqlNot;
      CheckEOF;
      GetNextToken;
      CheckEOF;
      if I then
      begin
        tt := CurrentToken;
        if Not(tt in sqlInvertableComparisons) then
          Error(SErrUnexpectedToken, [CurrentTokenString]);
        GetNextToken;
        if (tt = tsqlStarting) and (CurrentToken = tsqlWith) then
          GetNextToken;
      end
      else
        if (CurrentToken = tsqlNot) then
        begin
          GetNextToken;
          if not(tt = tsqlIs) then
            UnexpectedToken;
          I := True;
        end;
      bw := False;
      doin := False;
      case tt of
        tsqlLT :
          O := boLT;
        tsqlLE :
          O := boLE;
        tsqlGT :
          O := boGT;
        tsqlGE :
          O := boGE;
        tsqlEq :
          O := boEq;
        tsqlNE :
          O := boNE;
        tsqlLike :
          O := boLike;
        tsqlIn :
          doin := True;
        tsqlIs :
          O := boIs;
        tsqlContaining :
          O := boContaining;
        tsqlStarting :
          O := boStarting;
        tsqlBetween :
          bw := True;
      Else
        Error(SErrUnknownComparison)
      end;
      if doin then
      begin
        Right := ParseInoperand(AParent);
        B := TSQLBinaryExpression(CreateElement(TSQLBinaryExpression, AParent));
        B.Operation := boIn;
        B.Left := Result;
        Result := B;
        B.Right := Right;
      end
      else
      begin
        Right := ParseExprLevel3(AParent, EO);
        if (O = boLike) and (CurrentToken = tsqlEscape) then
        begin
          GetNextToken;
          T := TSQLTernaryExpression(CreateElement(TSQLTernaryExpression,
            AParent));
          T.Left := Result;
          Result := T;
          T.Middle := Right;
          T.Right := ParseExprLevel3(AParent, EO);
          T.Operation := toLikeEscape
        end
        else if bw then
        begin
          Consume(tsqlAnd);
          T := TSQLTernaryExpression(CreateElement(TSQLTernaryExpression,
            AParent));
          T.Left := Result;
          Result := T;
          T.Middle := Right;
          T.Right := ParseExprLevel3(AParent, EO);
          T.Operation := toBetween;
        end
        else
        begin
          B := TSQLBinaryExpression(CreateElement(TSQLBinaryExpression,
            AParent));
          B.Operation := O;
          B.Left := Result;
          Result := B;
          B.Right := Right;
        end;
      end;
      if I then
        if B.Operation = boIs then
          B.Operation := boIsNot
        else
        begin
          U := TSQLUnaryExpression(CreateElement(TSQLUnaryExpression, AParent));
          U.Operand := Result;
          U.Operation := uoNot;
          Result := U;
        end;
    end;
  Except
    Result.free;
    raise;
  end;
end;

function TSQLParser.ParseExprLevel3(AParent : TSQLElement;
  EO : TExpressionOptions) : TSQLExpression;

  function NegativeNumber : Boolean; //inline;

  begin
    Result := (CurrentToken in [tsqlIntegerNumber, tsqlFloatNumber]) and
      (StrToInt(CurrentTokenString) < 0)
  end;

var
  tt    : TSQLToken;
  Right : TSQLExpression;
  B     : TSQLBinaryExpression;

begin

{$IFDEF debugexpr} Writeln('Level 3 ', TokenInfos[CurrentToken], ': ', CurrentTokenString); {$ENDIF debugexpr}

  Result := ParseExprLevel4(AParent, EO);
  try

{$IFDEF debugexpr} Writeln('Level 3 continues ', TokenInfos[CurrentToken], ': ', CurrentTokenString); {$ENDIF debugexpr}

// Scanner returns -N as an negative number, not as - (positive number)
    // NegativeNumber is for the case A-1 or so: convert to A + -1
    while (CurrentToken in [tsqlConcatenate, tsqlPlus, tsqlMinus]) or
      NegativeNumber do
    begin
      tt := CurrentToken;
      if NegativeNumber then
        tt := tsqlPlus // Pretend we've eaten +
      else
      begin
        GetNextToken;
        CheckEOF;
      end;
      Right := ParseExprLevel4(AParent, EO);
      B := TSQLBinaryExpression(CreateElement(TSQLBinaryExpression, AParent));
      B.Left := Result;
      Result := B;
      B.Right := Right;
      case tt of
        tsqlPlus :
          B.Operation := boAdd;
        tsqlMinus :
          B.Operation := boSubtract;
        tsqlConcatenate :
          B.Operation := boConcat;
      end;
    end;
  Except
    Result.free;
    raise;
  end;
end;

function TSQLParser.ParseExprLevel4(AParent : TSQLElement;
  EO : TExpressionOptions) : TSQLExpression;

var
  tt    : TSQLToken;
  Right : TSQLExpression;
  B     : TSQLBinaryExpression;

begin

{$IFDEF debugexpr} Writeln('Level 4 ', TokenInfos[CurrentToken], ': ', CurrentTokenString); {$ENDIF debugexpr}

  Result := ParseExprLevel5(AParent, EO);
  try
    while (CurrentToken in [tsqlMul, tsqlDiv]) do
    begin
      tt := CurrentToken;
      GetNextToken;
      CheckEOF;
      Right := ParseExprLevel5(AParent, EO);
      B := TSQLBinaryExpression(CreateElement(TSQLBinaryExpression, AParent));
      B.Left := Result;
      B.Right := Right;
      case tt of
        tsqlMul :
          B.Operation := boMultiply;
        tsqlDiv :
          B.Operation := boDivide;
      end;
    end;
  Except
    Result.free;
    raise;
  end;
end;

function TSQLParser.ParseExprLevel5(AParent : TSQLElement;
  EO : TExpressionOptions) : TSQLExpression;

var
  tt : TSQLToken;
  U  : TSQLUnaryExpression;
begin

{$IFDEF debugexpr} Writeln('Level 5 ', TokenInfos[CurrentToken], ': ', CurrentTokenString); {$ENDIF debugexpr}

  tt := tsqlunknown;
  if (CurrentToken in [tsqlNot, tsqlPlus, tsqlMinus]) then
  begin
    tt := CurrentToken;
    GetNextToken;
    CheckEOF;
  end;
  Result := ParseExprLevel6(AParent, EO);
  try
    if tt <> tsqlunknown then
    begin
      U := TSQLUnaryExpression(CreateElement(TSQLUnaryExpression, AParent));
      if tt = tsqlNot then
        U.Operation := uoNot
      else
        U.Operation := uoMinus;
      U.Operand := Result;
      Result := U;
    end;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseExprLevel6(AParent : TSQLElement;
  EO : TExpressionOptions) : TSQLExpression;
var
  oBinaria: TSQLBinaryExpression;
  oIntercalacion: TSQLIdentifierExpression;
begin
  if (CurrentToken = tsqlBraceOpen) then
  begin
    GetNextToken;
    if (CurrentToken <> tsqlSelect) then
      Result := ParseExprLevel1(AParent, EO)
    else
    begin
      Result := TSQLExpression(CreateElement(TSQLSelectExpression, AParent));
      try
        TSQLSelectExpression(Result).Select := ParseSelectStatement(Result, [sfSingleTon]);
      except
        FreeAndNil(Result);
        raise;
      end;
    end;
    try
      if (CurrentToken = tsqlBraceClose) then
        GetNextToken
      else if not (CurrentToken in [tsqlEOF, tsqlSemicolon, tsqlUnion]) then
        Error(SerrUnmatchedBrace);
    except
      Result.free;
      raise;
    end;
  end
  else
    Result := ParseExprPrimitive(AParent, EO);
  while CurrentToken = tsqlCollate do
  begin
    GetNextToken;
    Expect(tsqlIdentifier);
    oBinaria := TSQLBinaryExpression(
      CreateElement(TSQLBinaryExpression, AParent));
    oBinaria.Left := Result;
    oBinaria.Operation := boCollate;
    oIntercalacion := TSQLIdentifierExpression(
      CreateElement(TSQLIdentifierExpression, oBinaria));
    oIntercalacion.Identifier := CreateIdentifier(
      oIntercalacion, CurrentTokenString);
    oBinaria.Right := oIntercalacion;
    Result := oBinaria;
    GetNextToken;
  end;
end;

function TSQLParser.ParseIdentifierList(AParent : TSQLElement;
  AList : TSQLelementList) : Integer;

begin
  // on entry, we're on first identifier
  Expect(tsqlIdentifier);
  Result := 0;
  repeat
    if CurrentToken = tsqlComma then
      GetNextToken;
    Expect(tsqlIdentifier);
    AList.Add(CreateIdentifier(AParent, CurrentTokenString));
    Inc(Result);
  until (GetNextToken <> tsqlComma);
  Expect(tsqlBraceClose);
  GetNextToken;
end;

function TSQLParser.ParseValueList(AParent : TSQLElement;
  EO : TExpressionOptions) : TSQLelementList;

var
  E : TSQLExpression;

begin
  Result := nil;
  E := nil;
  // First token is (
  Expect(tsqlBraceOpen);
  Repeat
    GetNextToken;
    if (CurrentToken <> tsqlBraceClose) then
      E := ParseExprLevel1(AParent, EO);
    if (E <> nil) then
    begin
      if Result = nil then
        Result := TSQLelementList.Create(True);
      Result.Add(E);
    end;
    Expect([tsqlComma, tsqlBraceClose]);
  Until CurrentToken = tsqlBraceClose;
end;

procedure TSQLParser.UnexpectedToken;
begin
  Error(SErrUnexpectedToken, [CurrentTokenString]);
end;

procedure TSQLParser.UnexpectedToken(AExpected: TSQLTokens);

var
  S : string;
  I : TSQLToken;

begin
  S := '';
  For I := Low(TSQLToken) to High(TSQLToken) do
    if I in AExpected then
    begin
      if (S <> '') then
        S := S + ',';
      S := S + TokenInfos[I];
    end;
  Error(SErrUnexpectedTokenOf, [CurrentTokenString, S]);
end;

function TSQLParser.CreateIdentifier(AParent : TSQLElement; const AName: TSQLStringType
  ): TSQLIdentifierName;
begin
  Result := TSQLIdentifierName(CreateElement(TSQLIdentifierName, AParent));
  Result.Name := AName;
end;

function TSQLParser.ParseExprAggregate(AParent : TSQLElement;
  EO : TExpressionOptions) : TSQLAggregateFunctionExpression;
begin
  Result := TSQLAggregateFunctionExpression
    (CreateElement(TSQLAggregateFunctionExpression, AParent));
  try
    case CurrentToken of
      tsqlCount :
        Result.Aggregate := afCount;
      tsqlSum :
        Result.Aggregate := afSum;
      tsqlAvg :
        Result.Aggregate := afAvg;
      tsqlMax :
        Result.Aggregate := afMax;
      tsqlMin :
        Result.Aggregate := afMin;
    end;
    GetNextToken;
    Consume(tsqlBraceOpen);
    if CurrentToken = tsqlMul then
    begin
      if Result.Aggregate <> afCount then
        Error(SErrAsteriskOnlyInCount);
      Result.OPtion := aoAsterisk;
      GetNextToken;
    end
    else
    begin
      if (CurrentToken in [tsqlAll, tsqlDistinct]) then
      begin
        if CurrentToken = tsqlAll then
          Result.OPtion := aoAll
        else
          Result.OPtion := aoDistinct;
        GetNextToken;
      end;
      Result.Expression := ParseExprLevel1(Result, EO);
    end;
    Consume(tsqlBraceClose);
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseOverClause(AParent : TSQLElement;
  AFunc : TSQLExpression) : TSQLWindowFunctionExpression;
var
  O : TSQLOrderByElement;
begin
  // Al entrar estamos en el identificador OVER. AFunc es la llamada a
  // funcion / agregado sobre la que actua la clausula ventana.
  Result := TSQLWindowFunctionExpression
    (CreateElement(TSQLWindowFunctionExpression, AParent));
  try
    Result.FunctionExpr := AFunc;
    GetNextToken;
    Consume(tsqlBraceOpen);
    // PARTITION BY (opcional)
    if (CurrentToken = tsqlIdentifier) and
       SameText(CurrentTokenString, 'PARTITION') then
    begin
      GetNextToken;
      Expect(tsqlBy);
      Repeat
        GetNextToken;
        Result.PartitionBy.Add(ParseExprLevel1(Result, []));
      until (CurrentToken <> tsqlComma);
    end;
    // ORDER BY (opcional)
    if (CurrentToken = tsqlOrder) then
    begin
      GetNextToken;
      Expect(tsqlBy);
      Repeat
        GetNextToken;
        O := TSQLOrderByElement(CreateElement(TSQLOrderByElement, Result));
        Result.OrderBy.Add(O);
        O.Field := ParseExprLevel1(O, []);
        if (CurrentToken in [tsqlDesc, tsqlAsc, tsqlDescending,
          tsqlAscending]) then
        begin
          if (CurrentToken in [tsqlDesc, tsqlDescending]) then
            O.OrderBy := obDescending
          else
            O.OrderBy := obAscending;
          GetNextToken;
        end;
      until (CurrentToken <> tsqlComma);
    end;
    Consume(tsqlBraceClose);
  except
    // El caller sigue siendo dueño de AFunc; evitamos el doble free
    Result.FunctionExpr := nil;
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseRawFunctionCall(AParent : TSQLElement;
  const AName : string) : TSQLExpression;
var
  N : string;
  PCount : Integer;
begin
  // Captura cruda del contenido de funciones MySQL con sintaxis no estandar
  // (GROUP_CONCAT, TRIM ... FROM ...). Reproduce el texto tal cual, ya que el
  // arbol no modela estas variantes. Al entrar estamos en el '(' inicial.
  N := AName + '(';
  PCount := 1;
  GetNextToken;
  while (PCount > 0) and (CurrentToken <> tsqlEOF) do
  begin
    if CurrentToken = tsqlBraceOpen then
      Inc(PCount)
    else if CurrentToken = tsqlBraceClose then
      Dec(PCount);
    if PCount > 0 then
    begin
      // No separar el '(' del token previo ni romper rutas tabla.campo
      if (N[Length(N)] <> '(') and
         (CurrentToken <> tsqlDot) and
         (CurrentToken <> tsqlBraceOpen) and
         (PreviousToken <> tsqlDot) then
        N := N + ' ';
      if CurrentToken = tsqlString then
        N := N + SQLFormatString(CurrentTokenString, [])
      else
        N := N + CurrentTokenString;
      GetNextToken;
    end;
  end;
  N := N + ')';
  if CurrentToken = tsqlBraceClose then
    GetNextToken;
  Result := TSQLIdentifierExpression
    (CreateElement(TSQLIdentifierExpression, AParent));
  TSQLIdentifierExpression(Result).Identifier := CreateIdentifier(Result, N);
end;

function TSQLParser.ParseExprPrimitive(AParent : TSQLElement;
  EO : TExpressionOptions) : TSQLExpression;
var
  L : TSQLelementList;
  N : string;
  C : TSQLElementClass;
  E : TSQLExtractElement;
  WhenNode: TSQLCaseWhenNode;
  LiteralJuegoCaracteres: TSQLCharsetStringLiteral;
begin
  Result := nil;
  try

{$IFDEF debugexpr} Writeln('Primitive ', TokenInfos[CurrentToken], ': ', CurrentTokenString); {$ENDIF debugexpr}

    case CurrentToken of
      tsqlIntegerNumber,
        tsqlString,
        tsqlFloatNumber,
        tsqlNull, // True and False belong here
      tsqlValue,
        tsqlUSER:
        begin
          Result := TSQLLiteralExpression(CreateElement(TSQLLiteralExpression,
            AParent));
          TSQLLiteralExpression(Result).Literal := CreateLiteral(AParent);
          GetNextToken;
        end;
      tsqlCast:
        begin
          GetNextToken;
          Consume(tsqlBraceOpen);
          Result := TSQLCastExpression(CreateElement(TSQLCastExpression,
            AParent));
          TSQLCastExpression(Result).Value := ParseExprLevel1(Result, EO);
          Expect(tsqlAs);
          TSQLCastExpression(Result).NewType :=
            ParseTypeDefinition(Result, [ptfCast]);
          Consume(tsqlBraceClose);
        end;
      tsqlExtract:
        begin
          GetNextToken;
          Consume(tsqlBraceOpen);
          Expect(tsqlIdentifier);
          if not StringToSQLExtractElement(CurrentTokenString, E) then
            Error(SErrInvalidExtract, [CurrentTokenString]);
          Consume(tsqlIdentifier);
          Consume(tsqlFrom);
          Result := TSQLExtractExpression(CreateElement(TSQLExtractExpression,
            AParent));
          TSQLExtractExpression(Result).Element := E;
          TSQLExtractExpression(Result).Value := ParseExprLevel1(Result, EO);
          Consume(tsqlBraceClose);
        end;
      tsqlExists,
        tsqlAll,
        tsqlAny,
        tsqlSome,
        tsqlSingular:
        begin
          case CurrentToken of
            tsqlExists : C := TSQLexistsExpression;
            tsqlAll : C := TSQLAllExpression;
            tsqlAny : C := TSQLAnyExpression;
            tsqlSome : C := TSQLSomeExpression;
            tsqlSingular : C := TSQLSingularExpression;
          end;
          GetNextToken;
          Consume(tsqlBraceOpen);
          Result := TSQLSelectionExpression(CreateElement(C, AParent));
          TSQLSelectionExpression(Result).Select :=
            ParseSelectStatement(Result, []);
          Consume(tsqlBraceClose);
        end;
      tsqlCount,
        tsqlSum,
        tsqlAvg,
        tsqlMax,
        tsqlMin :
        begin
          if not([eoSelectvalue, eoHaving] * EO <> []) then
            Error(SErrNoAggregateAllowed);
          Result := ParseExprAggregate(AParent, EO);
        end;
      tsqlUpper :
        begin
          GetNextToken;
          L := ParseValueList(AParent, EO);
          if L.Count <> 1 then
          begin
            FreeAndNil(L);
            Error(SErrUpperOneArgument);
          end;

          // CORRECCIÓN: Comprobación segura para no comerse el siguiente token
          if CurrentToken = tsqlBraceClose then
            GetNextToken;

          Result := TSQLFunctionCallExpression
            (CreateElement(TSQLFunctionCallExpression, AParent));
          TSQLFunctionCallExpression(Result).IDentifier := 'UPPER';
          TSQLFunctionCallExpression(Result).Arguments := L;
        end;
      tsqlCase:
        begin
          GetNextToken; // Consumimos la palabra 'CASE'
          Result := TSQLCaseExpression(CreateElement(TSQLCaseExpression, AParent));

          // Verificamos si es un CASE con operando base (ej. CASE MIVARIABLE WHEN...)
          if CurrentToken <> tsqlWhen then
            TSQLCaseExpression(Result).CaseOperand := ParseExprLevel1(Result, EO);

          // Procesamos todos los bloques WHEN ... THEN
          while CurrentToken = tsqlWhen do
          begin
            GetNextToken; // Consumimos 'WHEN'
            WhenNode := TSQLCaseWhenNode(CreateElement(TSQLCaseWhenNode, Result));
            TSQLCaseExpression(Result).WhenList.Add(WhenNode);

            // Parseamos la condición del WHEN
            WhenNode.WhenExpr := ParseExprLevel1(WhenNode, EO);

            Expect(tsqlThen);
            GetNextToken; // Consumimos 'THEN'

            // Parseamos el resultado del THEN
            WhenNode.ThenExpr := ParseExprLevel1(WhenNode, EO);
          end;

          // Procesamos el ELSE opcional
          if CurrentToken = tsqlElse then
          begin
            GetNextToken; // Consumimos 'ELSE'
            TSQLCaseExpression(Result).ElseExpr := ParseExprLevel1(Result, EO);
          end;

          Expect(tsqlEnd);
          GetNextToken; // Consumimos 'END'
        end;
      tsqlGenID :
        begin
          GetNextToken;
          Consume(tsqlBraceOpen);
          Expect(tsqlIdentifier);
          N := CurrentTokenString;
          GetNextToken;
          Consume(tsqlComma);
          Result := TSQLGenIDExpression(CreateElement(TSQLGenIDExpression,
            AParent));
          TSQLGenIDExpression(Result).Generator := CreateIdentifier(Result, N);
          TSQLGenIDExpression(Result).Value := ParseExprLevel1(AParent, EO);
          Consume(tsqlBraceClose);
        end;
      tsqlColon:
        begin
          if (([eoCheckConstraint, eoTableConstraint, eoComputedBy] * EO)
            <> []) then
            Error(SErrUnexpectedToken, [CurrentTokenString]);
          GetNextToken;
          Expect(tsqlIdentifier);
          N := CurrentTokenString;
          Result := TSQLParameterExpression
            (CreateElement(TSQLParameterExpression, AParent));
          TSQLParameterExpression(Result).IDentifier :=
            CreateIdentifier(Result, N);
          Consume(tsqlIdentifier);
        end;
      // tsqlLeft / tsqlRight son palabras reservadas (LEFT/RIGHT JOIN) pero
      // tambien funciones de cadena MySQL LEFT(str,n) / RIGHT(str,n). En una
      // expresion solo pueden ser la funcion, asi que las tratamos como tal.
      tsqlIdentifier, tsqlIf, tsqlLeft, tsqlRight, tsqlDate,
        tsqlDatabase:
        begin
          if CurrentToken = tsqlIf then
            N := 'IF'
          else
            N := CurrentTokenString;
          GetNextToken;
          if (N <> '') and (N[1] = '_') and
             (CurrentToken = tsqlString) then
          begin
            Result := TSQLLiteralExpression(
              CreateElement(TSQLLiteralExpression, AParent));
            LiteralJuegoCaracteres := TSQLCharsetStringLiteral(
              CreateElement(TSQLCharsetStringLiteral, Result));
            LiteralJuegoCaracteres.Charset := N;
            LiteralJuegoCaracteres.Value := CurrentTokenString;
            TSQLLiteralExpression(Result).Literal := LiteralJuegoCaracteres;
            GetNextToken;
          end
          else if CurrentToken <> tsqlBraceOpen then
          begin
            if (eoCheckConstraint in EO) and not(eoTableConstraint in EO) then
              Error(SErrUnexpectedToken, [CurrentTokenString]);

            // CORRECCIÓN: Bucle "while" para soportar múltiples puntos anidados (esquema.tabla.campo)
            while (CurrentToken = tsqlDot) do
            begin
              GetNextToken;
              Expect(tsqlIdentifier);
              N := N + '.' + CurrentTokenString;
              GetNextToken;
            end;

          // plain identifier
            Result := TSQLIdentifierExpression
              (CreateElement(TSQLIdentifierExpression, AParent));
            TSQLIdentifierExpression(Result).IDentifier :=
              CreateIdentifier(Result, N);

          // array access ?
            if (CurrentToken = tsqlSquareBraceOpen) then
            begin
              if (GetNextToken <> tsqlIntegerNumber) then
                Error(SErrIntegerExpected);
              TSQLIdentifierExpression(Result).ElementIndex :=
                StrToInt(CurrentTokenString);
              GetNextToken;
              Consume(tsqlSquareBraceClose);
            end;
          end
          else
          begin
            if SameText(N, 'GROUP_CONCAT') or SameText(N, 'TRIM') then
              Result := ParseRawFunctionCall(AParent, N)
            else
            begin
              L := ParseValueList(AParent, EO);
              if CurrentToken = tsqlBraceClose then
                GetNextToken;
              Result := TSQLFunctionCallExpression(CreateElement(TSQLFunctionCallExpression, AParent));
              TSQLFunctionCallExpression(Result).IDentifier := N;
              TSQLFunctionCallExpression(Result).Arguments := L;
            end;
          end;
        end;
    else
      UnexpectedToken;
    end;
    // Funcion ventana: detectamos OVER tras una llamada a funcion o agregado
    if (CurrentToken = tsqlIdentifier) and
       SameText(CurrentTokenString, 'OVER') and
       ((Result is TSQLFunctionCallExpression) or
        (Result is TSQLAggregateFunctionExpression)) then
      Result := ParseOverClause(AParent, Result);
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseSQLValue(AParent : TSQLElement) : TSQLExpression;

var
  E : TSQLExpression;
begin
  E := ParseExprLevel1(AParent, []);
  Result := E;
end;

function TSQLParser.ParseCheckConstraint(AParent : TSQLElement;
  TableConstraint : Boolean = False) : TSQLExpression;

var
  EO : TExpressionOptions;

begin
  // We are on the 'CHECK' token.
  GetNextToken;
  Consume(tsqlBraceOpen);
  EO := [eoCheckConstraint];
  if TableConstraint then
    EO := EO + [eoTableConstraint];
  Result := ParseExprLevel1(AParent, EO);
  Consume(tsqlBraceClose);
end;

function TSQLParser.ParseCreateDomainStatement(AParent: TSQLElement; IsAlter: Boolean
  ): TSQLCreateOrAlterStatement;

var
  D  : TSQLCreateDomainStatement;
  A  : TSQLAlterDomainStatement;
  N  : TSQLStringType;
  NN : Boolean;

begin
  Result := nil;
  GetNextToken;
  Expect(tsqlIdentifier);
  N := CurrentTokenString;
  if not IsAlter then
  begin
    D := TSQLCreateDomainStatement(CreateElement(TSQLCreateDomainStatement,
      AParent));
    try
      D.ObjectName := CreateIdentifier(D, N);
      if (PeekNextToken = tsqlAs) then
        GetNextToken;
      D.TypeDefinition := ParseTypeDefinition(D, [])
    except
      FreeAndNil(D);
      raise;
    end;
    Result := D;
  end
  else
  begin
    A := nil;
    NN := False;
    try
      case GetNextToken of
        tsqlSet:
          begin
            GetNextToken;
            Expect(tsqlDefault);
            GetNextToken;
            A := TSQLAlterDomainSetDefaultStatement
              (CreateElement(TSQLAlterDomainSetDefaultStatement, AParent));
            TSQLAlterDomainSetDefaultStatement(A).DefaultValue :=
              CreateLiteral(A);
          end;
        tsqlDrop:
          begin
            case GetNextToken of
              tsqlDefault :
                A := TSQLAlterDomainDropDefaultStatement
                  (CreateElement(TSQLAlterDomainDropDefaultStatement, AParent));
              tsqlConstraint :
                A := TSQLAlterDomainDropCheckStatement
                  (CreateElement(TSQLAlterDomainDropCheckStatement, AParent));
            else
              Error(SErrUnexpectedToken, [CurrentTokenString]);
            end;
          end;
        tsqlAdd:
          begin
            if (GetNextToken = tsqlConstraint) then
              GetNextToken;
            Expect(tsqlCheck);
            A := TSQLAlterDomainAddCheckStatement
              (CreateElement(TSQLAlterDomainAddCheckStatement, AParent));
            TSQLAlterDomainAddCheckStatement(A).Check :=
              ParseCheckConstraint(A);
            NN := True;
          end;
        tsqltype:
          begin
            A := TSQLAlterDomainTypeStatement
              (CreateElement(TSQLAlterDomainTypeStatement, AParent));
            TSQLAlterDomainTypeStatement(A).NewType :=
              ParseTypeDefinition(A, [ptfAlterDomain]);
            NN := True;
          end;
        tsqlIdentifier:
          begin
            A := TSQLAlterDomainRenameStatement
              (CreateElement(TSQLAlterDomainRenameStatement, AParent));
            TSQLAlterDomainRenameStatement(A).NewName :=
              CreateIdentifier(A, CurrentTokenString);
          end;
      else
        UnexpectedToken([tsqlSet, tsqlIdentifier, tsqlAdd, tsqltype, tsqlDrop]);
      end;
      A.ObjectName := CreateIdentifier(A, N);
      Result := A;
      if not NN then
        GetNextToken;
    except
      FreeAndNil(A);
      raise;
    end;
  end;
end;

function TSQLParser.ParseCreateExceptionStatement(AParent: TSQLElement;
  IsAlter: Boolean): TSQLCreateOrAlterStatement;

var
  E : TSQLCreateExceptionStatement;
  N : TSQLStringType;

begin
  GetNextToken;
  Expect(tsqlIdentifier);
  N := CurrentTokenString;
  try
    if IsAlter then
      E := TSQLCreateExceptionStatement
        (CreateElement(TSQLAlterExceptionStatement, AParent))
    else
      E := TSQLCreateExceptionStatement
        (CreateElement(TSQLCreateExceptionStatement, AParent));
    E.ObjectName := CreateIdentifier(E, N);
    GetNextToken;
    Expect(tsqlString);
    E.ExceptionMessage := TSQLStringLiteral
      (CreateElement(TSQLStringLiteral, E));
    E.ExceptionMessage.Value := CurrentTokenString;
    GetNextToken;
  except
    FreeAndNil(E);
    raise;
  end;
  Result := E;
end;

function TSQLParser.ParseCreateTriggerStatement(AParent: TSQLElement; IsAlter: Boolean
  ): TSQLCreateOrAlterStatement;

var
  T : TSQLAlterCreateTriggerStatement;

begin
  // On entry, we're on the 'TRIGGER' token.
  Consume(tsqlTrigger);
  if IsAlter then
    T := TSQLAlterTriggerStatement
      (CreateElement(TSQLAlterTriggerStatement, AParent))
  else
    T := TSQLCreateTriggerStatement(CreateElement(TSQLCreateTriggerStatement,
      AParent));
  Result := T;
  try
    Expect(tsqlIdentifier);
    Result.ObjectName := CreateIdentifier(Result, CurrentTokenString);
    GetNextToken;
    if Not IsAlter then
    begin
      Consume(tsqlFor);
      Expect(tsqlIdentifier);
      T.TableName := CreateIdentifier(Result, CurrentTokenString);
      GetNextToken;
    end;
    if (CurrentToken in [tsqlActive, tsqlInactive]) then
    begin
      if CurrentToken = tsqlActive then
        T.State := tsActive
      else
        T.State := tsInactive;
      GetNextToken;
    end;
    Expect([tsqlBefore, tsqlAfter]);
    if CurrentToken = tsqlBefore then
      T.Moment := tmBefore
    else
      T.Moment := tmAfter;
    Repeat
      GetNextToken;
      Expect([tsqlDelete, tsqlInsert, tsqlUpdate]);
      case CurrentToken of
        tsqlDelete :
          T.Operations := T.Operations + [toDelete];
        tsqlUpdate :
          T.Operations := T.Operations + [toUpdate];
        tsqlInsert :
          T.Operations := T.Operations + [toInsert];
      end;
      GetNextToken;
    Until (CurrentToken <> tsqlOr);
    if CurrentToken = tsqlPosition then
    begin
      GetNextToken;
      Expect(tsqlIntegerNumber);
      T.Position := StrToInt(CurrentTokenString);
      GetNextToken;
    end;
    Consume(tsqlAs);
    if (CurrentToken = tsqlDeclare) then
      ParseCreateProcedureVariableList(Result, T.LocalVariables);
    Expect(tsqlBegin);
    ParseStatementBlock(Result, T.Statements);
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseSetGeneratorStatement(AParent: TSQLElement
  ): TSQLSetGeneratorStatement;
begin
  // On entry, we're on the 'GENERATOR' token
  Consume(tsqlGenerator);
  try
    Result := TSQLSetGeneratorStatement(CreateElement(TSQLSetGeneratorStatement,
      AParent));
    Expect(tsqlIdentifier);
    Result.ObjectName := CreateIdentifier(Result, CurrentTokenString);
    GetNextToken;
    Consume(tsqlTo);
    Expect(tsqlIntegerNumber);
    Result.NewValue := StrToInt(CurrentTokenString);
    GetNextToken;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseSecondaryFile(AParent: TSQLElement)
  : TSQLDatabaseFileInfo;

var
  I    : Integer;
  Last : TSQLToken;

begin
  // On entry, we're on the FILE token
  Consume(tsqlFile);
  Result := TSQLDatabaseFileInfo(CreateElement(TSQLDatabaseFileInfo, AParent));
  try
    Expect(tsqlString);
    Result.FileName := CurrentTokenString;
    GetNextToken;
    I := 0;
    Last := tsqlEOF;
    while (I < 2) and (CurrentToken in [tsqlLength, tsqlStarting]) do
    begin
      Inc(I);
      if (CurrentToken = tsqlLength) then
      begin
        if Last = tsqlLength then
          UnexpectedToken;
        Last := tsqlLength;
        GetNextToken;
        if (CurrentToken = tsqlEq) then
          GetNextToken;
        Expect(tsqlIntegerNumber);
        Result.Length := StrToInt(CurrentTokenString);
        GetNextToken;
        if CurrentToken in [tsqlPage, tsqlPages] then
          GetNextToken;
      end
      else if (CurrentToken = tsqlStarting) then
      begin
        if Last = tsqlStarting then
          UnexpectedToken;
        Last := tsqlStarting;
        GetNextToken;
        if (CurrentToken = tsqlAt) then
        begin
          GetNextToken;
          if CurrentToken = tsqlPage then
            GetNextToken;
        end;
        Expect(tsqlIntegerNumber);
        Result.StartPage := StrToInt(CurrentTokenString);
        GetNextToken;
      end;
    end;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseCreateDatabaseStatement(AParent: TSQLElement;
  IsAlter: Boolean) : TSQLCreateDatabaseStatement;

begin
  // On entry, we're on the DATABASE or SCHEMA token
  Result := TSQLCreateDatabaseStatement
    (CreateElement(TSQLCreateDatabaseStatement, AParent));
  try
    Result.UseSchema := (CurrentToken = tsqlSchema);
    GetNextToken;
    Expect(tsqlString);
    Result.FileName := CurrentTokenString;
    GetNextToken;
    if (CurrentToken = tsqlUSER) then
    begin
      GetNextToken;
      Expect(tsqlString);
      Result.UserName := CurrentTokenString;
      GetNextToken;
    end;
    if (CurrentToken = tsqlPassword) then
    begin
      GetNextToken;
      Expect(tsqlString);
      Result.Password := CurrentTokenString;
      GetNextToken;
    end;
    if (CurrentToken = tsqlPageSize) then
    begin
      GetNextToken;
      if CurrentToken = tsqlEq then
        GetNextToken;
      Expect(tsqlIntegerNumber);
      Result.Pagesize := StrtoIntDef(CurrentTokenString, 0);
      GetNextToken;
    end;
    if (CurrentToken = tsqlLength) then
    begin
      GetNextToken;
      if (CurrentToken = tsqlEq) then
        GetNextToken;
      Expect(tsqlIntegerNumber);
      Result.Length := StrtoIntDef(CurrentTokenString, 0);
      GetNextToken;
      if CurrentToken in [tsqlPage, tsqlPages] then
        GetNextToken;
    end;
    if (CurrentToken = tsqlDefault) then
    begin
      GetNextToken;
      Consume(tsqlCharacter);
      Consume(tsqlSet);
      Expect(tsqlIdentifier);
      Result.Charset := CreateIdentifier(Result, CurrentTokenString);
      GetNextToken;
    end;
    while (CurrentToken = tsqlFile) do
      Result.SecondaryFiles.Add(ParseSecondaryFile(Result));
  except
    FreeAndNil(Result);
    raise
  end;
end;

function TSQLParser.ParseCreateShadowStatement(AParent: TSQLElement;
  IsAlter: Boolean): TSQLCreateShadowStatement;
begin
  // On entry, we're on the SHADOW token.
  if IsAlter then
    UnexpectedToken;
  Consume(tsqlShadow);
  Result := TSQLCreateShadowStatement(CreateElement(TSQLCreateShadowStatement,
    AParent));
  try
    Expect(tsqlIntegerNumber);
    Result.Number := StrToInt(CurrentTokenString);
    GetNextToken;
    if (CurrentToken = tsqlManual) then
    begin
      Result.Manual := True;
      GetNextToken;
    end
    else if (CurrentToken = tsqlAuto) then
      GetNextToken;
    if (CurrentToken = tsqlConditional) then
    begin
      Result.Conditional := True;
      GetNextToken;
    end;
    Expect(tsqlString);
    Result.FileName := CurrentTokenString;
    GetNextToken;
    if (CurrentToken = tsqlLength) then
    begin
      GetNextToken;
      if (CurrentToken = tsqlEq) then
        GetNextToken;
      Expect(tsqlIntegerNumber);
      Result.Length := StrtoIntDef(CurrentTokenString, 0);
      GetNextToken;
      if CurrentToken in [tsqlPage, tsqlPages] then
        GetNextToken;
    end;
    while (CurrentToken = tsqlFile) do
      Result.SecondaryFiles.Add(ParseSecondaryFile(Result));
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseAlterDatabaseStatement(AParent: TSQLElement;
  IsAlter: Boolean): TSQLAlterDatabaseStatement;
begin
  // On entry, we're on the DATABASE or SCHEMA token.
  Result := TSQLAlterDatabaseStatement(CreateElement(TSQLAlterDatabaseStatement,
    AParent));
  try
    Result.UseSchema := CurrentToken = tsqlSchema;
    GetNextToken;
    Expect(tsqlAdd);
    while (CurrentToken in [tsqlAdd, tsqlFile]) do
    begin
      if CurrentToken = tsqlAdd then
        GetNextToken;
      Expect(tsqlFile);
      Result.Operations.Add(ParseSecondaryFile(Result));
    end;
    if Result.Operations.Count = 0 then
      UnexpectedToken([tsqlAdd]);
  except
    FreeAndNil(Result);
    raise;
  end;

end;

function TSQLParser.ParseCreateStatement(AParent: TSQLElement; IsAlter: Boolean
  ): TSQLCreateOrAlterStatement;
var
  Tk: TSQLToken;
  IsOrReplace: Boolean;
begin
  IsOrReplace := False;
  Tk := GetNextToken;
  if Tk = tsqlOr then
  begin
    IsOrReplace := True;
    GetNextToken;
    Tk := GetNextToken;
  end;
  if (Tk = tsqlIdentifier) and
     (SameText(CurrentTokenString, 'ALGORITHM') or
      SameText(CurrentTokenString, 'DEFINER') or
      SameText(CurrentTokenString, 'SQL')) then
  begin
    while not (PeekNextToken in [tsqlTable, tsqlView, tsqlProcedure,
                                 tsqlTrigger, tsqlIndex, tsqlDomain, tsqlRole,
                                 tsqlDatabase, tsqlEOF]) do
    begin
      GetNextToken;
    end;
    Tk := GetNextToken;
  end;
  case Tk of
    tsqlTable :
      if IsAlter then
        Result := ParseAlterTableStatement(AParent)
      else
        Result := ParseCreateTableStatement(AParent);
    tsqlUnique,
      tsqlAscending,
      tsqlDescending,
      tsqlIndex :
      Result := ParseCreateIndexStatement(AParent, IsAlter);
    tsqlView :
      Result := ParseCreateViewStatement(AParent, IsAlter);
    tsqlProcedure :
      begin
        Result := ParseCreateProcedureStatement(AParent, IsAlter);
        if Assigned(Result) and (Result is TSQLAlterCreateProcedureStatement) then
          TSQLAlterCreateProcedureStatement(Result).IsOrReplace := IsOrReplace;
      end;
    tsqlDomain :
      Result := ParseCreateDomainStatement(AParent, IsAlter);
    tsqlGenerator :
      Result := ParseCreateGeneratorStatement(AParent, IsAlter);
    tsqlException :
      Result := ParseCreateExceptionStatement(AParent, IsAlter);
    tsqlTrigger :
      Result := ParseCreateTriggerStatement(AParent, IsAlter);
    tsqlRole :
      Result := ParseCreateRoleStatement(AParent, IsAlter);
    tsqlSchema,
      tsqlDatabase :
      if IsAlter then
        Result := ParseAlterDatabaseStatement(AParent, IsAlter)
      else
        Result := ParseCreateDatabaseStatement(AParent, IsAlter);
    tsqlShadow :
      Result := ParseCreateShadowStatement(AParent, IsAlter);
  else
    Error(SErrExpectedDBObject, [CurrentTokenString]);
  end;
end;

function TSQLParser.ParseDropStatement(AParent: TSQLElement
  ): TSQLDropStatement;

var
  C : TSQLElementClass;

begin
  // We're positioned on the DROP token.
  C := nil;
  case GetNextToken of
    {
    Filter,
    }
    tsqlExternal :
      begin
        GetNextToken;
        Expect(tsqlFunction);
        C := TSQLDropExternalFunctionStatement;
      end;
    tsqlShadow :
      C := TSQLDropShadowStatement;
    tsqlRole :
      C := TSQLDropRoleStatement;
    tsqlDatabase :
      C := TSQLDropDatabaseStatement;
    tsqlException :
      C := TSQLDropExceptionStatement;
    tsqlTable :
      C := TSQLDropTableStatement;
    tsqlIndex :
      C := TSQLDropIndexStatement;
    tsqlView :
      C := TSQLDropViewStatement;
    tsqlProcedure :
      C := TSQLDropProcedureStatement;
    tsqlDomain :
      C := TSQLDropDomainStatement;
    tsqlGenerator :
      C := TSQLDropGeneratorStatement;
    tsqlTrigger :
      C := TSQLDropTriggerStatement;
  else
    Error(SErrExpectedDBObject, [CurrentTokenString]);
  end;
  GetNextToken;
  if CurrentToken = tsqlIf then
  begin
    GetNextToken;
    if CurrentToken = tsqlExists then
      GetNextToken;
  end;
  if C = TSQLDropShadowStatement then
    Expect(tsqlIntegerNumber)
  else
    Expect(tsqlIdentifier);
  Result := TSQLDropStatement(CreateElement(C, AParent));
  Result.ObjectName := CreateIdentifier(Result, CurrentTokenString);
  GetNextToken; // Comma
end;

function TSQLParser.ParseRollbackStatement(AParent: TSQLElement
  ): TSQLRollbackStatement;

begin
  // On entry, we're on the ROLLBACK statement
  Consume(tsqlRollBack);
  Result := TSQLRollbackStatement(CreateElement(TSQLRollbackStatement,
    AParent));
  try
    if (CurrentToken = tsqlTransaction) then
    begin
      GetNextToken;
      Expect(tsqlIdentifier);
      Result.TransactionName := CreateIdentifier(Result, CurrentTokenString);
      GetNextToken;
    end;
    Result.Work := (CurrentToken = tsqlWork);
    if Result.Work then
      GetNextToken;
    Result.Release := (CurrentToken = tsqlRelease);
    if Result.Release then
      GetNextToken;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseCommitStatement(AParent: TSQLElement
  ): TSQLCommitStatement;
begin
  Consume(tsqlCommit);
  Result := TSQLCommitStatement(CreateElement(TSQLCommitStatement, AParent));
  try
    Result.Work := (CurrentToken = tsqlWork);
    if Result.Work then
      GetNextToken;
    if (CurrentToken = tsqlTransaction) then
    begin
      GetNextToken;
      Expect(tsqlIdentifier);
      Result.TransactionName := CreateIdentifier(Result, CurrentTokenString);
      GetNextToken;
    end;
    Result.Release := (CurrentToken = tsqlRelease);
    if Result.Release then
      GetNextToken;
    Result.Retain := (CurrentToken = tsqlRetain);
    if Result.Retain then
    begin
      GetNextToken;
      if CurrentToken = tsqlSnapshot then
        GetNextToken;
    end;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseExecuteProcedureStatement(AParent: TSQLElement)
  : TSQLExecuteProcedureStatement;

var
  NeedClose,
    Done : Boolean;
  TN     : TSQLStringType;

begin
  Result := nil;
  // On Entry, we're on the EXECUTE statement
  Consume(tsqlExecute);
  Consume(tsqlProcedure);
  if (CurrentToken = tsqlTransaction) then
  begin
    GetNextToken;
    Expect(tsqlIdentifier);
    TN := CurrentTokenString;
    GetNextToken;
  end;
  Expect(tsqlIdentifier);
  Result := TSQLExecuteProcedureStatement
    (CreateElement(TSQLExecuteProcedureStatement, AParent));
  try
    Result.ProcedureName := CreateIdentifier(Result, CurrentTokenString);
    if (TN <> '') then
      Result.TransactionName := CreateIdentifier(Result, TN);
    GetNextToken;
    // ( is optional. It CAN be part of a (SELECT, and then it is NOT part of the brackets around the params.
    NeedClose := (CurrentToken = tsqlBraceOpen) and
      (PeekNextToken <> tsqlSelect);
    if NeedClose then
      GetNextToken;
    Done := False;
    if Not(CurrentToken in [tsqlSemicolon, tsqlEOF, tsqlReturningValues]) then
      Repeat
        Result.Params.Add(ParseExprLevel1(Result, [eoFieldValue]));
        if CurrentToken = tsqlComma then
          GetNextToken
        else if (CurrentToken = tsqlBraceClose) then
        begin
          if Not NeedClose then
            UnexpectedToken;
          Done := True;
          GetNextToken;
        end
        else
        begin
          if NeedClose then
            UnexpectedToken([tsqlBraceClose]);
          Expect([tsqlEOF, tsqlSemicolon, tsqlReturningValues]);
          Done := True;
        end;
      until Done;
    if (CurrentToken = tsqlReturningValues) then
    begin
      GetNextToken;
      NeedClose := (CurrentToken = tsqlBraceOpen);
      if NeedClose then
        Consume(tsqlBraceOpen);
      Repeat
        if CurrentToken = tsqlComma then
          GetNextToken;
        if CurrentToken = tsqlColon then
          GetNextToken;
        Expect(tsqlIdentifier);
        Result.Returning.Add(CreateIdentifier(Result, CurrentTokenString));
        GetNextToken;
      until (CurrentToken <> tsqlComma);
      if NeedClose then
        Consume(tsqlBraceClose);
    end;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseCallStatement(AParent: TSQLElement): TSQLStatement;
var
  C: TSQLMariaDBCallStatement;
  N: string;
begin
  C := TSQLMariaDBCallStatement(
    CreateElement(TSQLMariaDBCallStatement, AParent));
  Result := C;
  try
    GetNextToken;
    Expect(tsqlIdentifier);
    N := CurrentTokenString;
    GetNextToken;
    Expect(tsqlBraceOpen);
    C.CallExpression := ParseRawFunctionCall(C, N);
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseSetStatement(AParent: TSQLElement): TSQLStatement;
var
  Raw: TSQLRawStatement;
begin
  Consume(tsqlSet);
  if CurrentToken = tsqlGenerator then
    Result := ParseSetGeneratorStatement(AParent)
  else
  begin
    Raw := TSQLRawStatement(CreateElement(TSQLRawStatement, AParent));
    Result := Raw;
    Raw.RawText := 'SET';
    while not (CurrentToken in [tsqlEOF, tsqlSemicolon]) do
    begin
      if CurrentToken = tsqlString then
        Raw.RawText := Raw.RawText + ' ' +
          SQLFormatString(CurrentTokenString, [])
      else
        Raw.RawText := Raw.RawText + ' ' + CurrentTokenString;
      GetNextToken;
    end;
  end;
end;

function TSQLParser.ParseConnectStatement(AParent: TSQLElement
  ): TSQLConnectStatement;
begin
  // On entry, we're on CONNECT
  Consume(tsqlConnect);
  Expect(tsqlString);
  Result := TSQLConnectStatement(CreateElement(TSQLConnectStatement, AParent));
  try
    Result.DatabaseName := CurrentTokenString;
    GetNextToken;
    if CurrentToken = tsqlUSER then
    begin
      GetNextToken;
      Expect(tsqlString);
      Result.UserName := CurrentTokenString;
      GetNextToken;
    end;
    if CurrentToken = tsqlPassword then
    begin
      GetNextToken;
      Expect(tsqlString);
      Result.Password := CurrentTokenString;
      GetNextToken;
    end;
    if CurrentToken = tsqlRole then
    begin
      GetNextToken;
      Expect(tsqlString);
      Result.Role := CurrentTokenString;
      GetNextToken;
    end;
    if CurrentToken = tsqlCache then
    begin
      GetNextToken;
      Expect(tsqlIntegerNumber);
      Result.Cache := StrtoIntDef(CurrentTokenString, 0);
      GetNextToken;
    end;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

constructor TSQLParser.Create(AInput: TStream);
begin
  FInput := AInput;
  FCurrent := tsqlunknown;
  FScanner := TSQLScanner.Create(FInput);
  FFreeScanner := True;
end;

constructor TSQLParser.Create(AScanner: TSQLScanner);
begin
  FCurrent := tsqlunknown;
  FScanner := AScanner;
  FFreeScanner := False;
end;

destructor TSQLParser.Destroy;
begin
  if FFreeScanner then
    FreeAndNil(FScanner);
  inherited Destroy;
end;

function TSQLParser.ParseDeclareFunctionStatement(AParent : TSQLElement)
  : TSQLDeclareExternalFunctionStatement;

begin
  // On entry, we're on the EXTERNAL token
  Consume(tsqlExternal);
  Consume(tsqlFunction);
  Expect(tsqlIdentifier);
  Result := TSQLDeclareExternalFunctionStatement
    (CreateElement(TSQLDeclareExternalFunctionStatement, AParent));
  try
    Result.ObjectName := CreateIdentifier(Result, CurrentTokenString);
    if (PeekNextToken = tsqlReturns) then
      GetNextToken
    else
      Repeat
        Result.Arguments.Add(Self.ParseTypeDefinition(Result,
          [ptfExternalFunction]));
      Until (CurrentToken <> tsqlComma);
    Expect(tsqlReturns);
    Result.ReturnType := ParseTypeDefinition(Result,
      [ptfExternalFunctionResult]);
    Result.FreeIt := (CurrentToken = tsqlFreeIt);
    if Result.FreeIt then
      GetNextToken;
    Consume(tsqlEntryPoint);
    Expect(tsqlString);
    Result.EntryPoint := CurrentTokenString;
    GetNextToken;
    Consume(tsqlModuleName);
    Expect(tsqlString);
    Result.ModuleName := CurrentTokenString;
    GetNextToken;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseDeclareStatement(AParent : TSQLElement)
  : TSQLStatement;

begin
  // On entry, we're on the DECLARE statement
  Consume(tsqlDeclare);
  // For the moment, only 'DECLARE EXTERNAL function' is supported
  case CurrentToken of
    tsqlExternal :
      Result := ParseDeclareFunctionStatement(AParent);
  else
    UnexpectedToken([tsqlExternal]);
  end;

end;

procedure TSQLParser.ParseGranteeList(AParent: TSQLElement;
  List: TSQLelementList; AllowObject, AllowGroup, AllowPublic: Boolean;
  IsRevoke: Boolean = False);

type
  TSQLGranteeClass = class of TSQLGrantee;

  function CreateGrantee(NextIdentifier : Boolean; AClass : TSQLGranteeClass)
    : TSQLGrantee;
  begin
    if NextIdentifier then
    begin
      GetNextToken;
      Expect(tsqlIdentifier);
    end;
    Result := TSQLGrantee(CreateElement(AClass, AParent));
    Result.Name := CurrentTokenString;
    List.Add(Result);
  end;

var
  E : TSQLTokens;

begin
  if IsRevoke then
    Consume(tsqlFrom)
  else
    Consume(tsqlTo);
  E := [tsqlIdentifier, tsqlUSER];
  if AllowObject then
    E := E + [tsqlProcedure, tsqlView, tsqlTrigger, tsqlPublic]
  else if AllowPublic then
    E := E + [tsqlPublic];
  if AllowGroup then
    E := E + [tsqlGroup];
  Expect(E);
  Repeat
    if CurrentToken = tsqlComma then
      GetNextToken;
    case CurrentToken of
      tsqlUSER,
        tsqlIdentifier :
        CreateGrantee(CurrentToken = tsqlUSER, TSQLUserGrantee);
      tsqlGroup :
        begin
          if Not AllowGroup then
            UnexpectedToken;
          CreateGrantee(True, TSQLGroupGrantee);
        end;
      tsqlPublic :
        begin
          if Not(AllowPublic or AllowObject) then
            UnexpectedToken;
          CreateGrantee(False, TSQLPublicGrantee);
        end;
      tsqlTrigger:
        begin
          if Not AllowObject then
            UnexpectedToken;
          CreateGrantee(True, TSQLTriggerGrantee);
        end;
      tsqlView:
        begin
          if Not AllowObject then
            UnexpectedToken;
          CreateGrantee(True, TSQLViewGrantee);
        end;
      tsqlProcedure:
        begin
          if Not AllowObject then
            UnexpectedToken;
          CreateGrantee(True, TSQLProcedureGrantee);
        end;
    end;
  Until (GetNextToken <> tsqlComma);

end;

function TSQLParser.ParseGrantTableStatement(AParent: TSQLElement)
  : TSQLTableGrantStatement;

var
  C : TSQLColumnPrivilege;
  P : TSQLPrivilege;

begin
  Result := TSQLTableGrantStatement(CreateElement(TSQLTableGrantStatement,
    AParent));
  try
    // On entry, we're on the first ALL/SELECT/UPDATE/INSERT/DELETE/REFERENCE etc. token.
    if CurrentToken = tsqlAll then
    begin
      Result.Privileges.Add(CreateElement(TSQLAllPrivilege, Result));
      if GetNextToken = tsqlPrivileges then
        GetNextToken;
    end
    else
      Repeat
        P := nil;
        C := nil;
        if CurrentToken = tsqlComma then
          GetNextToken;
        case CurrentToken of
          tsqlSelect :
            P := TSQLSelectPrivilege(CreateElement(TSQLSelectPrivilege,
              Result));
          tsqlInsert :
            P := TSQLInsertPrivilege(CreateElement(TSQLInsertPrivilege,
              Result));
          tsqlDelete :
            P := TSQLDeletePrivilege(CreateElement(TSQLDeletePrivilege,
              Result));
          tsqlUpdate,
            tsqlReferences :
            begin
              if CurrentToken = tsqlUpdate then
                C := TSQLUpdatePrivilege
                  (CreateElement(TSQLUpdatePrivilege, AParent))
              else
                C := TSQLReferencePrivilege
                  (CreateElement(TSQLReferencePrivilege, AParent));
              P := C;
              GetNextToken;
              if (CurrentToken = tsqlBraceOpen) then
              begin
                GetNextToken;
                C.Columns := TSQLelementList.Create(True);
                ParseIdentifierList(C, C.Columns);
              end;
            end;
        else
          UnexpectedToken([tsqlSelect, tsqlInsert, tsqlDelete, tsqlUpdate,
            tsqlReferences]);
        end;
        Result.Privileges.Add(P);
        if C = nil then
          GetNextToken;
      Until (CurrentToken <> tsqlComma);
    Consume(tsqlOn);
    Expect(tsqlIdentifier);
    Result.TableName := CreateIdentifier(Result, CurrentTokenString);
    GetNextToken;
    ParseGranteeList(Result, Result.Grantees, True, True, True);
    if (CurrentToken = tsqlWith) then
    begin
      Consume(tsqlWith);
      Consume(tsqlGrant);
      Consume(tsqlOption);
      Result.GrantOption := True;
    end;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseRevokeExecuteStatement(AParent: TSQLElement
  ): TSQLProcedureRevokeStatement;
BEGIN
  // On entry, we're on the EXECUTE token
  Consume(tsqlExecute);
  Consume(tsqlOn);
  Consume(tsqlProcedure);
  Expect(tsqlIdentifier);
  Result := TSQLProcedureRevokeStatement
    (CreateElement(TSQLProcedureRevokeStatement, AParent));
  try
    Result.ProcedureName := CreateIdentifier(Result, CurrentTokenString);
    GetNextToken;
    ParseGranteeList(Result, Result.Grantees, True, False, True, True);
    if (CurrentToken = tsqlWith) then
    begin
      Consume(tsqlWith);
      Consume(tsqlGrant);
      Consume(tsqlOption);
      Result.GrantOption := True;
    end;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseRevokeRoleStatement(AParent: TSQLElement
  ): TSQLRoleRevokeStatement;
begin
  Result := nil;
  // On entry, we're on the identifier token
  Expect(tsqlIdentifier);
  Result := TSQLRoleRevokeStatement(CreateElement(TSQLRoleRevokeStatement,
    AParent));
  try
    Repeat
      if CurrentToken = tsqlComma then
        GetNextToken;
      Expect(tsqlIdentifier);
      Result.Roles.Add(CreateIdentifier(AParent, CurrentTokenString));
    Until (GetNextToken <> tsqlComma);
    Expect(tsqlFrom);
    ParseGranteeList(Result, Result.Grantees, False, False, True, True);
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseRevokeTableStatement(AParent: TSQLElement
  ): TSQLTableRevokeStatement;
var
  C : TSQLColumnPrivilege;
  P : TSQLPrivilege;

begin
  Result := TSQLTableRevokeStatement(CreateElement(TSQLTableRevokeStatement,
    AParent));
  try
    // On entry, we're on the first GRANT,ALL/SELECT/UPDATE/INSERT/DELETE/REFERENCE etc. token.
    if (CurrentToken = tsqlGrant) then
    begin
      Consume(tsqlGrant);
      Consume(tsqlOption);
      Consume(tsqlFor);
      Result.GrantOption := True;
    end;
    if CurrentToken = tsqlAll then
    begin
      Result.Privileges.Add(CreateElement(TSQLAllPrivilege, Result));
      if GetNextToken = tsqlPrivileges then
        GetNextToken;
    end
    else
      Repeat
        P := nil;
        C := nil;
        if CurrentToken = tsqlComma then
          GetNextToken;
        case CurrentToken of
          tsqlSelect :
            P := TSQLSelectPrivilege(CreateElement(TSQLSelectPrivilege,
              Result));
          tsqlInsert :
            P := TSQLInsertPrivilege(CreateElement(TSQLInsertPrivilege,
              Result));
          tsqlDelete :
            P := TSQLDeletePrivilege(CreateElement(TSQLDeletePrivilege,
              Result));
          tsqlUpdate,
            tsqlReferences :
            begin
              if CurrentToken = tsqlUpdate then
                C := TSQLUpdatePrivilege
                  (CreateElement(TSQLUpdatePrivilege, AParent))
              else
                C := TSQLReferencePrivilege
                  (CreateElement(TSQLReferencePrivilege, AParent));
              P := C;
              GetNextToken;
              if (CurrentToken = tsqlBraceOpen) then
              begin
                GetNextToken;
                C.Columns := TSQLelementList.Create(True);
                ParseIdentifierList(C, C.Columns);
              end;
            end;
        else
          UnexpectedToken([tsqlSelect, tsqlInsert, tsqlDelete, tsqlUpdate,
            tsqlReferences]);
        end;
        Result.Privileges.Add(P);
        if C = nil then
          GetNextToken;
      Until (CurrentToken <> tsqlComma);
    Consume(tsqlOn);
    Expect(tsqlIdentifier);
    Result.TableName := CreateIdentifier(Result, CurrentTokenString);
    GetNextToken;
    ParseGranteeList(Result, Result.Grantees, True, True, True, True);
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseGrantExecuteStatement(AParent: TSQLElement)
  : TSQLProcedureGrantStatement;

begin
  // On entry, we're on the EXECUTE token
  Consume(tsqlExecute);
  Consume(tsqlOn);
  Consume(tsqlProcedure);
  Expect(tsqlIdentifier);
  Result := TSQLProcedureGrantStatement
    (CreateElement(TSQLProcedureGrantStatement, AParent));
  try
    Result.ProcedureName := CreateIdentifier(Result, CurrentTokenString);
    GetNextToken;
    ParseGranteeList(Result, Result.Grantees, True, False, True);
    if (CurrentToken = tsqlWith) then
    begin
      Consume(tsqlWith);
      Consume(tsqlGrant);
      Consume(tsqlOption);
      Result.GrantOption := True;
    end;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseGrantRoleStatement(AParent: TSQLElement)
  : TSQLRoleGrantStatement;

begin
  Result := nil;
  // On entry, we're on the identifier token
  Expect(tsqlIdentifier);
  Result := TSQLRoleGrantStatement(CreateElement(TSQLRoleGrantStatement,
    AParent));
  try
    Repeat
      if CurrentToken = tsqlComma then
        GetNextToken;
      Expect(tsqlIdentifier);
      Result.Roles.Add(CreateIdentifier(AParent, CurrentTokenString));
    Until (GetNextToken <> tsqlComma);
    Expect(tsqlTo);
    ParseGranteeList(Result, Result.Grantees, False, False, True);
    if (CurrentToken = tsqlWith) then
    begin
      Consume(tsqlWith);
      Consume(tsqlAdmin);
      Consume(tsqlOption);
      Result.AdminOption := True;
    end;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseGrantStatement(AParent: TSQLElement)
  : TSQLGrantStatement;

begin
  // On entry, we're on the GRANT token
  Result := nil;
  try
    Consume(tsqlGrant);
    case CurrentToken of
      tsqlExecute:
        Result := ParseGrantExecuteStatement(AParent);
      tsqlAll,
        tsqlUpdate,
        tsqlReferences,
        tsqlInsert,
        tsqlDelete,
        tsqlSelect :
        Result := ParseGrantTableStatement(AParent);
      tsqlIdentifier :
        Result := ParseGrantRoleStatement(AParent);
    else
      UnexpectedToken([tsqlIdentifier, tsqlExecute, tsqlAll,
        tsqlUpdate, tsqlDelete, tsqlReferences, tsqlInsert, tsqlSelect]);
    end;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSQLParser.ParseRevokeStatement(AParent: TSQLElement
  ): TSQLGrantStatement;
begin
  // On entry, we're on the GRANT token
  Result := nil;
  try
    Consume(tsqlRevoke);
    case CurrentToken of
      tsqlExecute:
        Result := ParseRevokeExecuteStatement(AParent);
      tsqlGrant,
        tsqlAll,
        tsqlUpdate,
        tsqlReferences,
        tsqlInsert,
        tsqlDelete,
        tsqlSelect :
        Result := ParseRevokeTableStatement(AParent);
      tsqlIdentifier :
        Result := ParseRevokeRoleStatement(AParent);
    else
      UnexpectedToken([tsqlIdentifier, tsqlExecute, tsqlGrant, tsqlAll,
        tsqlUpdate, tsqlDelete, tsqlReferences, tsqlInsert, tsqlSelect]);
    end;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

procedure TSQLParser.ParseDelimiterBlock(AElement: TSQLElement);
// Captura como texto crudo todo desde "DELIMITER xxx" hasta el siguiente
// "DELIMITER yyy" o EOF, aplicando:
//  - Saltos de línea originales (basados en la fila del scanner).
//  - Indentación estructural por BEGIN/END y IF/THEN/ELSE/END IF.
//  - Espaciado "tight" alrededor de paréntesis, puntos, comas y ;.
// Al salir, CurrentToken queda en ';' o EOF para que el tail de Parse() funcione.
// NO incluye el ';' final del DELIMITER de cierre en el RawText, para que el
// formateador externo (que añade ';' al final de cada sentencia) no duplique.
var
  R         : TSQLRawStatement;
  Indent    : Integer;
  PrevRow   : Integer;
  NeedSpace : Boolean;
  Upper     : string;

  procedure AppendCurrentToken;
  var
    NewRow : Integer;
  begin
    NewRow := FScanner.CurRow;
    if (R.RawText <> '') and (NewRow > PrevRow) then
    begin
      R.RawText := R.RawText + sLineBreak;
      if Indent > 0 then
        R.RawText := R.RawText + StringOfChar(' ', Indent * 2);
      NeedSpace := False;
    end
    else if NeedSpace and
       not (CurrentToken in [tsqlComma, tsqlSemicolon, tsqlDot,
                             tsqlBraceClose, tsqlSquareBraceClose]) then
      R.RawText := R.RawText + ' ';

    if CurrentToken = tsqlString then
      R.RawText := R.RawText + SQLFormatString(CurrentTokenString, [])
    else
      R.RawText := R.RawText + CurrentTokenString;

    NeedSpace := not (CurrentToken in [tsqlBraceOpen, tsqlSquareBraceOpen, tsqlDot]);
    PrevRow := NewRow;
  end;

begin
  R := AElement as TSQLRawStatement;
  R.RawText := '';
  Indent := 0;
  PrevRow := FScanner.CurRow;
  NeedSpace := False;

  // "DELIMITER"
  AppendCurrentToken;
  GetNextToken;
  // Símbolo del nuevo delimitador (p. ej. $$). Tras éste forzamos newline.
  if CurrentToken <> tsqlEOF then
  begin
    AppendCurrentToken;
    GetNextToken;
  end;

  while CurrentToken <> tsqlEOF do
  begin
    Upper := UpperCase(CurrentTokenString);

    // Dedent ANTES de emitir END / ELSE / ELSEIF
    if ((CurrentToken = tsqlEnd) or SameText(Upper, 'END') or
        SameText(Upper, 'ELSE') or SameText(Upper, 'ELSEIF')) and (Indent > 0) then
      Dec(Indent);

    // DELIMITER de cierre — emite el token, después su símbolo si no es ';'
    if (CurrentToken = tsqlIdentifier) and SameText(Upper, 'DELIMITER') then
    begin
      AppendCurrentToken;
      GetNextToken;
      if (CurrentToken <> tsqlEOF) and (CurrentToken <> tsqlSemicolon) then
      begin
        AppendCurrentToken;
        GetNextToken;
      end;
      // Si el símbolo de cierre es ';' lo dejamos sin consumir y sin añadir
      // al RawText. El formateador externo añadirá su ';' final.
      Break;
    end;

    AppendCurrentToken;

    // Indent DESPUÉS de emitir BEGIN / THEN / ELSE / LOOP / REPEAT
    if (CurrentToken = tsqlBegin) or SameText(Upper, 'BEGIN') or
       SameText(Upper, 'THEN') or SameText(Upper, 'ELSE') or
       SameText(Upper, 'LOOP') or SameText(Upper, 'REPEAT') then
      Inc(Indent);

    GetNextToken;
  end;
end;

function TSQLParser.ParseProcedureBodyAsRaw: string;
// Captura como texto crudo formateado el bloque BEGIN..END de un PROCEDURE
// MariaDB. Al entrar, CurrentToken debe ser tsqlBegin. Al salir, CurrentToken
// queda en el token posterior al END exterior (típicamente ';').
//
// Reglas de formato:
//  - Indentación estructural (2 espacios por nivel):
//      Inc tras BEGIN/THEN/ELSE/LOOP/REPEAT/DO; Dec antes de END/ELSE/ELSEIF.
//  - Saltos de línea estructurales: antes de END/ELSE/ELSEIF, tras
//    BEGIN/THEN/ELSE/';', y antes de SELECT/INSERT/UPDATE/DELETE en depth 0.
//  - Saltos de línea por cláusulas SQL: antes de FROM/WHERE/INTO/SET/VALUES/
//    GROUP/ORDER/HAVING/LIMIT/JOIN/INNER/LEFT/RIGHT/ON/UNION (en depth 0,
//    sólo cuando ya estamos dentro de una sentencia DML), a indent + 1.
//    Excepción: INTO inmediatamente tras INSERT NO rompe (queda
//    "INSERT INTO" en la misma línea).
//  - Saltos antes de AND/OR sólo dentro de WHERE/HAVING/ON.
//  - Saltos tras ',' (depth 0) sólo dentro de SELECT-fields / SET / VALUES.
//  - Saltos tras ',' en la lista de columnas de un INSERT (un campo por
//    línea).
//  - Espaciado "tight" alrededor de paréntesis, puntos, comas y ';'.
//  - Sin espacio antes de '(' si el token anterior es identificador,
//    keyword de función agregada o keyword de tipo (call style).
//
// Seguimiento de profundidad: cuenta BEGIN/END pero ignora END seguido de
// IF/WHILE/CASE/LOOP/REPEAT (cierres de sub-bloques, no del BEGIN exterior).
const
  // Tokens tras los que '(' no lleva espacio (estilo llamada a función)
  FunctionCallPrev : TSQLTokens = [
    tsqlIdentifier, tsqlSum, tsqlCount, tsqlAvg, tsqlMax, tsqlMin,
    tsqlCast, tsqlExtract, tsqlUpper,
    tsqlChar, tsqlVarchar, tsqlNChar, tsqlCharacter,
    tsqlInt, tsqlInteger, tsqlSmallInt, tsqlDecimal, tsqlNumeric,
    tsqlFloat, tsqlDate, tsqlTime, tsqlTimeStamp, tsqlBlob,
    tsqlBraceClose, tsqlSquareBraceClose
  ];
  // Keywords de inicio de sentencia DML (fuerzan salto al depth 0)
  StmtStartKw : TSQLTokens = [tsqlSelect, tsqlInsert, tsqlUpdate, tsqlDelete];
var
  BlockStack        : string;
  ParenDepth        : Integer;
  Indent            : Integer;
  ClauseIndent      : Integer;
  PrevRow           : Integer;
  CurRow            : Integer;
  NeedSpace         : Boolean;
  ForceNewline      : Boolean;
  Done              : Boolean;
  InStatement       : Boolean;
  InWhereLike       : Boolean;
  AllowCommaBreak   : Boolean;
  PendingInsertInto : Boolean;  // True desde INSERT hasta el INTO siguiente
  AfterInsertInto   : Boolean;  // True desde INTO (post-INSERT) hasta el '(' de columnas
  InColumnList      : Boolean;  // estamos dentro de (col1, col2, ...) tras INSERT INTO
  ColumnListDepth   : Integer;  // ParenDepth al abrir la lista de columnas
  Upper             : string;
  PeekTok           : TSQLToken;
  PeekStr           : string;

  function IsClauseKeyword: Boolean;
  begin
    if ParenDepth <> 0 then Exit(False);
    if not InStatement then Exit(False);
    // INTO es cláusula sólo en SELECT...INTO; tras INSERT forma parte del
    // propio "INSERT INTO" y no debe romper.
    if SameText(Upper, 'INTO') then
      Exit(not PendingInsertInto);
    // "JOIN" no rompe linea si va precedido de su prefijo (LEFT/RIGHT/INNER/
    // OUTER): asi "LEFT JOIN" queda junto, partiendo solo antes de LEFT.
    if SameText(Upper, 'JOIN') then
      Exit(not (PreviousToken in [tsqlLeft, tsqlRight, tsqlInner, tsqlOuter]));
    Result := SameText(Upper, 'FROM') or SameText(Upper, 'WHERE') or
              SameText(Upper, 'SET') or SameText(Upper, 'VALUES') or
              SameText(Upper, 'ORDER') or SameText(Upper, 'GROUP') or
              SameText(Upper, 'HAVING') or SameText(Upper, 'LIMIT') or
              SameText(Upper, 'JOIN') or SameText(Upper, 'INNER') or
              SameText(Upper, 'LEFT') or SameText(Upper, 'RIGHT') or
              SameText(Upper, 'CROSS') or SameText(Upper, 'ON') or
              SameText(Upper, 'UNION');
  end;

  function IsAndOrInWhere: Boolean;
  begin
    Result := (ParenDepth = 0) and InWhereLike and
      (SameText(Upper, 'AND') or SameText(Upper, 'OR'));
  end;

  procedure AppendCurrent(ARow: Integer);
  var
    EffIndent : Integer;
  begin
    if (Result <> '') and ((ARow > PrevRow) or ForceNewline) then
    begin
      Result := Result + sLineBreak;
      EffIndent := Indent + ClauseIndent;
      if EffIndent > 0 then
        Result := Result + StringOfChar(' ', EffIndent * 2);
      NeedSpace := False;
    end
    else if NeedSpace then
    begin
      if not (CurrentToken in [tsqlComma, tsqlSemicolon, tsqlDot, tsqlColon,
                               tsqlBraceClose, tsqlSquareBraceClose]) then
      begin
        // Sin espacio antes de '(' si previo es identifier-like (función), ni
        // entre ':' y '=' para no romper el operador de asignacion ':=' de
        // MariaDB (SET var := valor).
        if (not ((CurrentToken = tsqlBraceOpen) and
                 (PreviousToken in FunctionCallPrev))) and
           (not ((CurrentToken = tsqlEQ) and (PreviousToken = tsqlColon))) then
          Result := Result + ' ';
      end;
    end;

    if CurrentToken = tsqlString then
      Result := Result + SQLFormatString(CurrentTokenString, [])
    else
      Result := Result + CurrentTokenString;

    NeedSpace := not (CurrentToken in [tsqlBraceOpen, tsqlSquareBraceOpen, tsqlDot]);
    PrevRow := ARow;
    ForceNewline := False;
  end;

begin
  Result := '';
  BlockStack := '';
  ParenDepth := 0;
  Indent := 0;
  ClauseIndent := 0;
  PrevRow := FScanner.CurRow;
  NeedSpace := False;
  ForceNewline := False;
  Done := False;
  InStatement := False;
  InWhereLike := False;
  AllowCommaBreak := False;
  PendingInsertInto := False;
  AfterInsertInto := False;
  InColumnList := False;
  ColumnListDepth := 0;

  while (not Done) and (CurrentToken <> tsqlEOF) do
  begin
    // Capturamos la fila ANTES de cualquier PeekNextToken, ya que éste
    // adelanta el scanner y FScanner.CurRow dejaría de apuntar al token
    // actual.
    CurRow := FScanner.CurRow;
    Upper := UpperCase(CurrentTokenString);

    // Tracking de bloques mediante pila (BlockStack). Un 'END' simple puede
    // cerrar tanto un bloque BEGIN..END como una expresion CASE..END, asi que
    // necesitamos saber cual es el bloque abierto mas interno. 'B' = BEGIN,
    // 'C' = CASE. Los subbloques IF/WHILE/LOOP/REPEAT no se apilan: se cierran
    // con 'END IF/WHILE/LOOP/REPEAT' y no afectan a la profundidad.
    if CurrentToken = tsqlBegin then
      BlockStack := BlockStack + 'B'
    else if CurrentToken = tsqlCase then
      BlockStack := BlockStack + 'C'
    else if CurrentToken = tsqlEnd then
    begin
      PeekTok := PeekNextToken;
      PeekStr := UpperCase(FPeekTokenString);
      if (PeekTok = tsqlCase) then
      begin
        // 'END CASE': cierre de un CASE de sentencia.
        if (BlockStack <> '') and (BlockStack[Length(BlockStack)] = 'C') then
          Delete(BlockStack, Length(BlockStack), 1);
      end
      else if (PeekTok = tsqlIf) or (PeekTok = tsqlWhile) or
              ((PeekTok = tsqlIdentifier) and
               (SameText(PeekStr, 'LOOP') or SameText(PeekStr, 'REPEAT'))) then
      begin
        // 'END IF/WHILE/LOOP/REPEAT': subbloque no apilado, no toca la pila.
      end
      else
      begin
        // 'END' simple: cierra el bloque mas interno.
        if (BlockStack <> '') and (BlockStack[Length(BlockStack)] = 'C') then
          // Cierre de una expresion CASE..END: no cierra ningun BEGIN.
          Delete(BlockStack, Length(BlockStack), 1)
        else
        begin
          if BlockStack <> '' then
            Delete(BlockStack, Length(BlockStack), 1);
          // Pila vacia => era el END del BEGIN exterior del procedure.
          if BlockStack = '' then
            Done := True;
        end;
      end;
    end;

    // ParenDepth: increment ANTES de emitir '('
    if CurrentToken = tsqlBraceOpen then
      Inc(ParenDepth);

    // Pre-emit: forzar salto antes de SELECT/INSERT/UPDATE/DELETE en depth 0
    // (cubre INSERT...SELECT en la misma línea: el SELECT pasa a su propia línea).
    if (CurrentToken in StmtStartKw) and (ParenDepth = 0) then
    begin
      ForceNewline := True;
      ClauseIndent := 0;
    end;

    // Saltos por cláusula SQL / AND-OR en WHERE-like
    if IsClauseKeyword or IsAndOrInWhere then
    begin
      ForceNewline := True;
      ClauseIndent := 1;
    end;

    // Saltos estructurales: END / ELSE / ELSEIF
    if (CurrentToken = tsqlEnd) or SameText(Upper, 'ELSE') or
       SameText(Upper, 'ELSEIF') then
    begin
      ForceNewline := True;
      ClauseIndent := 0;
      InStatement := False;
      InWhereLike := False;
      AllowCommaBreak := False;
      PendingInsertInto := False;
      AfterInsertInto := False;
      InColumnList := False;
      if Indent > 0 then
        Dec(Indent);
    end;

    AppendCurrent(CurRow);

    // ParenDepth: tras emitir ')' detecta cierre de lista de columnas y decrementa
    if CurrentToken = tsqlBraceClose then
    begin
      if InColumnList and (ParenDepth = ColumnListDepth) then
        InColumnList := False;
      if ParenDepth > 0 then
        Dec(ParenDepth);
    end;

    // Tras emitir '(': si esperábamos la lista de columnas de un INSERT, entramos
    if (CurrentToken = tsqlBraceOpen) and AfterInsertInto then
    begin
      InColumnList := True;
      ColumnListDepth := ParenDepth;  // ya está incrementado
      AfterInsertInto := False;
    end
    else if (CurrentToken = tsqlBraceOpen) then
    begin
      // Cualquier otro '(' después de INSERT INTO también invalida la espera
      // (raro: INSERT INTO sin nombre de tabla). No hacemos nada extra.
    end;

    // Inc Indent tras BEGIN / THEN / ELSE / LOOP / REPEAT / DO
    if (CurrentToken = tsqlBegin) or SameText(Upper, 'THEN') or
       SameText(Upper, 'ELSE') or SameText(Upper, 'LOOP') or
       SameText(Upper, 'REPEAT') or (CurrentToken = tsqlDo) then
      Inc(Indent);

    // Detección de inicio de sentencia SQL
    if CurrentToken in StmtStartKw then
    begin
      InStatement := True;
      // SELECT permite romper su lista de campos por ','
      AllowCommaBreak := (CurrentToken = tsqlSelect);
    end;
    if CurrentToken = tsqlInsert then
      PendingInsertInto := True;
    if (CurrentToken = tsqlInto) then
    begin
      if PendingInsertInto then
        AfterInsertInto := True;
      PendingInsertInto := False;
    end;

    // Tracking de la cláusula actual para AND/OR breaks y comma breaks
    if SameText(Upper, 'WHERE') or SameText(Upper, 'HAVING') or SameText(Upper, 'ON') then
    begin
      InWhereLike := True;
      AllowCommaBreak := False;
    end
    else if SameText(Upper, 'SET') then
    begin
      // SET sólo cuenta como cláusula si estamos dentro de un UPDATE.
      // SET de asignación top-level (SET var = expr;) no debe romper.
      if InStatement then
      begin
        InWhereLike := False;
        AllowCommaBreak := True;
      end;
    end
    else if SameText(Upper, 'VALUES') then
    begin
      InWhereLike := False;
      AllowCommaBreak := True;
    end
    else if SameText(Upper, 'FROM') or SameText(Upper, 'INTO') or
            SameText(Upper, 'ORDER') or SameText(Upper, 'GROUP') or
            SameText(Upper, 'LIMIT') or SameText(Upper, 'JOIN') or
            SameText(Upper, 'UNION') then
    begin
      InWhereLike := False;
      AllowCommaBreak := False;
    end;

    // Estructurales: salto tras BEGIN/THEN/ELSE devuelve al nivel de bloque
    if (CurrentToken = tsqlBegin) or SameText(Upper, 'THEN') or
       SameText(Upper, 'ELSE') then
    begin
      ForceNewline := True;
      ClauseIndent := 0;
    end;

    // Tras ';' reseteamos estado de sentencia SQL
    if CurrentToken = tsqlSemicolon then
    begin
      ForceNewline := True;
      ClauseIndent := 0;
      InStatement := False;
      InWhereLike := False;
      AllowCommaBreak := False;
      PendingInsertInto := False;
      AfterInsertInto := False;
      InColumnList := False;
    end;

    // Tras ',' en depth 0 dentro de SELECT/SET/VALUES: forzar salto
    if (CurrentToken = tsqlComma) and (ParenDepth = 0) and
       InStatement and AllowCommaBreak then
    begin
      ForceNewline := True;
      ClauseIndent := 1;
    end;

    // Tras ',' en la lista de columnas de INSERT INTO t(...): un campo por línea
    // (la ',' queda pegada al identificador anterior, el siguiente campo en
    // nueva línea).
    if (CurrentToken = tsqlComma) and InColumnList and
       (ParenDepth = ColumnListDepth) then
    begin
      ForceNewline := True;
      ClauseIndent := 1;
    end;

    GetNextToken;
  end;

  // SOPORTE MARIADB: tras el END del bloque etiquetado puede venir el label
  // de cierre ("END PRC;"). Lo emitimos en la misma línea que END antes de
  // dejar el control al outer Parse (que espera ';' o EOF).
  // OJO: NO consumir si el identifier es un marcador '$$' del cliente MySQL
  // ni la directiva DELIMITER siguiente; ambos los gestiona el outer Parse
  // como "ruido" al inicio de la siguiente sentencia.
  if (CurrentToken = tsqlIdentifier) and
     (CurrentTokenString <> '') and
     (CurrentTokenString[1] <> '$') and
     not SameText(CurrentTokenString, 'DELIMITER') then
  begin
    AppendCurrent(FScanner.CurRow);
    GetNextToken;
  end;
end;

function TSQLParser.Parse: TSQLElement;

  function IsDollarMarker(const S: string): Boolean;
  // Devuelve True si la cadena está compuesta sólo por '$' (p. ej. '$$', '$$$').
  // Esos marcadores son los delimitadores propios del cliente MySQL/MariaDB.
  var
    I : Integer;
  begin
    Result := S <> '';
    for I := 1 to Length(S) do
      if S[I] <> '$' then
        Exit(False);
  end;

begin
  GetNextToken;
  // --- Bucle de "ruido" inicial: saltamos ';', whitespace, comentarios,
  // directivas DELIMITER y marcadores '$$'. Cualquiera de éstos no inicia
  // una sentencia SQL real. ---
  while True do
  begin
    if CurrentToken in [tsqlSemicolon, tsqlWhiteSpace, tsqlComment, tsqlUnknown] then
    begin
      GetNextToken;
      Continue;
    end;
    // Marcador '$$' / '$$$' del cliente MySQL.
    if (CurrentToken = tsqlIdentifier) and IsDollarMarker(CurrentTokenString) then
    begin
      GetNextToken;
      Continue;
    end;
    // Directiva DELIMITER xxx (DELIMITER $$, DELIMITER ;): la engullimos.
    // El procedure de dentro se parsea nativamente porque su BEGIN..END
    // tiene un terminador propio (END;).
    if (CurrentToken = tsqlIdentifier) and SameText(CurrentTokenString, 'DELIMITER') then
    begin
      GetNextToken;
      if not (CurrentToken in [tsqlEOF]) then
        GetNextToken; // consume el símbolo del delimitador (p. ej. $$ o ;)
      Continue;
    end;
    Break;
  end;
  if CurrentToken = tsqlEOF then
    Exit(nil);
  if SameText(CurrentTokenString, 'REPLACE') then
  begin
    Result := ParseInsertStatement(nil);
  end
  else
  case CurrentToken of
    tsqlSelect, tsqlWith :
      Result := ParseSelectStatement(nil, []);
    tsqlUpdate :
      Result := ParseUpdateStatement(nil);
    tsqlInsert :
      Result := ParseInsertStatement(nil);
    tsqlDelete :
      Result := ParseDeleteStatement(nil);
    tsqlCreate,
      tsqlAlter :
      Result := ParseCreateStatement(nil, (tsqlAlter = CurrentToken));
    tsqlDrop :
      Result := ParseDropStatement(nil);
    tsqlSet :
      Result := ParseSetStatement(nil);
    tsqlRollBack :
      Result := ParseRollbackStatement(nil);
    tsqlCommit :
      Result := ParseCommitStatement(nil);
    tsqlExecute :
      begin
        // EXECUTE PROCEDURE name (Firebird) vs EXECUTE stmt (MariaDB
        // prepared statement). Si tras EXECUTE viene PROCEDURE, llamada
        // a stored procedure; en otro caso lo tratamos como sentencia
        // cruda hasta el ';' (sintaxis de prepared statements MySQL).
        if PeekNextToken = tsqlProcedure then
          Result := ParseExecuteProcedureStatement(nil)
        else
        begin
          Result := TSQLRawStatement(CreateElement(TSQLRawStatement, nil));
          TSQLRawStatement(Result).RawText := CurrentTokenString;
          GetNextToken;
          while not (CurrentToken in [tsqlEOF, tsqlSemicolon]) do
          begin
            if CurrentToken = tsqlString then
              TSQLRawStatement(Result).RawText :=
                TSQLRawStatement(Result).RawText + ' ' +
                SQLFormatString(CurrentTokenString, [])
            else
              TSQLRawStatement(Result).RawText :=
                TSQLRawStatement(Result).RawText + ' ' + CurrentTokenString;
            GetNextToken;
          end;
        end;
      end;
    tsqlConnect :
      Result := ParseConnectStatement(nil);
    tsqlDeclare :
      Result := ParseDeclareStatement(nil);
    tsqlGrant :
      Result := ParseGrantStatement(nil);
    tsqlRevoke :
      Result := ParseRevokeStatement(nil);
    tsqlIdentifier:
      begin
        if SameText(CurrentTokenString, 'CALL') then
          Result := ParseCallStatement(nil)
        else if SameText(CurrentTokenString, 'START') then
        begin
          GetNextToken; // Pasamos el token 'START'
          if (CurrentToken = tsqlTransaction) or
             SameText(CurrentTokenString, 'TRANSACTION') then
          begin
            Result := TSQLStartTransactionStatement(CreateElement(
                                           TSQLStartTransactionStatement, nil));
            GetNextToken; // Pasamos 'TRANSACTION'
            while not (CurrentToken in [tsqlEOF, tsqlSemicolon]) do
            begin
              if TSQLStartTransactionStatement(Result).Modifiers <> '' then
                TSQLStartTransactionStatement(Result).Modifiers :=
                          TSQLStartTransactionStatement(Result).Modifiers + ' ';

              TSQLStartTransactionStatement(Result).Modifiers :=
                               TSQLStartTransactionStatement(Result).Modifiers +
                                                             CurrentTokenString;
              GetNextToken;
            end;
          end
          else
            UnexpectedToken;
        end
        else if SameText(CurrentTokenString, 'PREPARE') or
                SameText(CurrentTokenString, 'EXECUTE') or
                SameText(CurrentTokenString, 'DEALLOCATE') then
        begin
          Result := TSQLRawStatement(CreateElement(TSQLRawStatement, nil));
          TSQLRawStatement(Result).RawText := CurrentTokenString;
          GetNextToken;
          while not (CurrentToken in [tsqlEOF, tsqlSemicolon]) do
          begin
            if CurrentToken = tsqlString then
              TSQLRawStatement(Result).RawText :=
                TSQLRawStatement(Result).RawText + ' ' +
                SQLFormatString(CurrentTokenString, [])
            else
              TSQLRawStatement(Result).RawText := TSQLRawStatement(Result).RawText + ' ' + CurrentTokenString;
            GetNextToken;
          end;
        end
        else
          UnexpectedToken;
      end;
  else
    UnexpectedToken;
  end;
  // Aceptamos también como terminador válido los marcadores '$$' del cliente
  // MySQL y la palabra DELIMITER: cuando un PROCEDURE acaba "END $$\nDELIMITER ;"
  // el body parser deja CurrentToken en '$$', y la siguiente llamada a
  // Parse() los gestionará como "ruido" inicial.
  if Not(CurrentToken in [tsqlEOF, tsqlSemicolon]) then
  begin
    if (CurrentToken = tsqlIdentifier) and
       ((CurrentTokenString <> '') and
        ((CurrentTokenString[1] = '$') or
         SameText(CurrentTokenString, 'DELIMITER'))) then
      Exit;
    FreeAndNil(Result);
    if (CurrentToken = tsqlBraceClose) then
      Error(SerrUnmatchedBrace);
    Error(SErrUnexpectedToken, [CurrentTokenString]);
  end;
end;

function TSQLParser.ParseScript(AllowPartial : Boolean = False)
  : TSQLelementList;
var
  E : TSQLElement;
begin
  Result := TSQLelementList.Create(True);
  try
    E := Parse;
    while (E <> nil) do
    begin
      Result.Add(E);
      E := Parse;
    end;
  except
    if Not AllowPartial then
    begin
      FreeAndNil(Result);
      raise;
    end;
  end;
end;

function TSQLParser.CurrentToken: TSQLToken;
begin
  Result := FCurrent;
end;

function TSQLParser.CurrentTokenString: string;
begin
  Result := FCurrentString;
end;

function TSQLParser.GetNextToken: TSQLToken;
begin
  FPrevious := FCurrent;
  if (FPeekToken <> tsqlunknown) then
  begin
    FCurrent := FPeekToken;
    FCurrentString := FPeekTokenString;
    FPeekToken := tsqlunknown;
    FPeekTokenString := '';
  end
  else
  begin
    FCurrent := FScanner.FetchToken;
    FCurrentString := FScanner.CurTokenString;
  end;
  Result := FCurrent;

{$IFDEF debugparser}Writeln('GetNextToken : ', GetEnumName(TypeInfo(TSQLToken), Ord(FCurrent)), ' As string: ', FCurrentString); {$ENDIF debugparser}

end;

function TSQLParser.PeekNextToken: TSQLToken;
begin
  if (FPeekToken = tsqlunknown) then
  begin
    FPeekToken := FScanner.FetchToken;
    FPeekTokenString := FScanner.CurTokenString;
  end;

{$IFDEF debugparser}Writeln('PeekNextToken : ', GetEnumName(TypeInfo(TSQLToken), Ord(FPeekToken)), ' As string: ', FPeekTokenString); {$ENDIF debugparser}

  Result := FPeekToken;
end;

function TSQLParser.PreviousToken: TSQLToken;
begin
  Result := FPrevious;
end;

function TSQLParser.IsEndOfLine: Boolean;
begin
  Result := FScanner.IsEndOfLine;
end;

{ TSQLMariaDBInsertStatement }

function TSQLMariaDBInsertStatement.GetAsSQL(Options: TSQLFormatOptions;
                                             AIndent: Integer = 0): TSQLStringType;
begin
  Result := inherited GetAsSQL(Options, AIndent);
  if IsReplace then
    Result := StringReplace(Result, 'INSERT', 'REPLACE', [rfIgnoreCase]);
  if ExtraValues <> '' then
    Result := Result + ExtraValues;
  if OnDuplicateKey <> '' then
    Result := Result + sLineBreak + '  ' + Trim(OnDuplicateKey);
end;

function TSQLMariaDBCreateTableStatement.GetAsSQL(Options: TSQLFormatOptions; AIndent: Integer = 0): TSQLStringType;
begin
  Result := inherited GetAsSQL(Options, AIndent);
  if TableOptions <> '' then
    Result := Result + ' ' + Trim(TableOptions);
end;

function TSQLAlterTableRawOperation.GetAsSQL(Options: TSQLFormatOptions; AIndent: Integer = 0): TSQLStringType;
begin
  Result := RawText;
end;

function TSQLRawStatement.GetAsSQL(Options: TSQLFormatOptions; AIndent: Integer = 0): TSQLStringType;
begin
  Result := RawText;
end;

end.
