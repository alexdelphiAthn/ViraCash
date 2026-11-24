{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataCajaOperacionesHistRepositorio                        }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia UniDAC del historico de operaciones de caja.                 }
{******************************************************************************}
unit UniDataCajaOperacionesHistRepositorio;

interface

uses
  Uni, inLibCajaOperacionesHistPersistenciaIntf;

function CrearRepositorioCajaOperacionesHistUniDAC(
  AConsulta: TUniQuery): IRepositorioCajaOperacionesHist;

implementation

uses
  System.SysUtils, Data.DB;

type
  TRepositorioCajaOperacionesHistUniDAC = class(
    TInterfacedObject,
    IRepositorioCajaOperacionesHist)
  private
    FConsulta: TUniQuery;
    function ConstruirRestriccion(
      const ARestriccion: TRestriccionCajaOperacionesHist;
      const AColEmpresa, AColAlmacen, AColCaja: string): string;
    function ConstruirWhere(
      const AFiltros: TFiltrosCajaOperacionesHist): string;
    function ConstruirSql(
      const AFiltros: TFiltrosCajaOperacionesHist): string;
  public
    constructor Create(AConsulta: TUniQuery);
    function ListarAnyos: TCadenasCajaOperacionesHist;
    function ListarAlmacenes(
      const ARestriccion: TRestriccionCajaOperacionesHist
    ): TAlmacenesCajaOperacionesHist;
    function PrepararConsulta(
      const AFiltros: TFiltrosCajaOperacionesHist): Boolean;
    function ContarOperaciones(
      const AFiltros: TFiltrosCajaOperacionesHist): Integer;
    procedure AbrirConsulta(AFilasPorBloque: Integer);
  end;

constructor TRepositorioCajaOperacionesHistUniDAC.Create(
  AConsulta: TUniQuery);
begin
  inherited Create;
  FConsulta := AConsulta;
end;

function TRepositorioCajaOperacionesHistUniDAC.ConstruirRestriccion(
  const ARestriccion: TRestriccionCajaOperacionesHist;
  const AColEmpresa, AColAlmacen, AColCaja: string): string;

  function Fragmento(const AColumna, AValor: string): string;
  begin
    Result := ' AND (' + AColumna + ' = ' + QuotedStr(AValor) +
      ' OR ' + AColumna + ' IS NULL)';
  end;

begin
  Result := '';
  if (AColEmpresa <> '') and (ARestriccion.Empresa <> '') then
  begin
    Result := Result + Fragmento(AColEmpresa, ARestriccion.Empresa);
  end;
  if (AColAlmacen <> '') and (ARestriccion.Almacen <> '') then
  begin
    Result := Result + Fragmento(AColAlmacen, ARestriccion.Almacen);
  end;
  if (AColCaja <> '') and (ARestriccion.Caja <> '') then
  begin
    Result := Result + Fragmento(AColCaja, ARestriccion.Caja);
  end;
end;

function TRepositorioCajaOperacionesHistUniDAC.ConstruirWhere(
  const AFiltros: TFiltrosCajaOperacionesHist): string;
var
  Anyo: string;
  NumeroAnyo: Integer;
  RangoAnyo: string;
  Almacen: string;
  sAnyos: string;
  sAlmacenes: string;
begin
  sAnyos := '';
  for Anyo in AFiltros.Anyos do
  begin
    if not TryStrToInt(Anyo, NumeroAnyo) or
       (NumeroAnyo < 0) or (NumeroAnyo > 9999) then
      raise EArgumentException.CreateFmt('Año de operaciones inválido: %s',
        [Anyo]);
    if NumeroAnyo = 0 then
      RangoAnyo := 'YEAR(o.FECHA_OPERACION_OPCAJA) = 0'
    else
    begin
      RangoAnyo := 'o.FECHA_OPERACION_OPCAJA >= ' +
        QuotedStr(Format('%.4d-01-01', [NumeroAnyo]));
      if NumeroAnyo < 9999 then
        RangoAnyo := '(' + RangoAnyo + ' AND o.FECHA_OPERACION_OPCAJA < ' +
          QuotedStr(Format('%.4d-01-01', [NumeroAnyo + 1])) + ')';
    end;
    if sAnyos <> '' then
    begin
      sAnyos := sAnyos + ' OR ';
    end;
    sAnyos := sAnyos + RangoAnyo;
  end;
  sAlmacenes := '';
  for Almacen in AFiltros.Almacenes do
  begin
    if sAlmacenes <> '' then
    begin
      sAlmacenes := sAlmacenes + ', ';
    end;
    sAlmacenes := sAlmacenes + QuotedStr(Almacen);
  end;
  Result := ' WHERE 1 = 1';
  if sAnyos <> '' then
  begin
    Result := Result + ' AND (' + sAnyos + ')';
  end;
  if sAlmacenes <> '' then
  begin
    Result := Result +
      ' AND o.CODIGO_ALM_OPCAJA IN (' + sAlmacenes + ')';
  end;
  Result := Result + ConstruirRestriccion(
    AFiltros.Restriccion,
    'o.CODIGO_EMP_OPCAJA',
    'o.CODIGO_ALM_OPCAJA',
    'o.CODIGO_CAJA_OPCAJA');
end;

function TRepositorioCajaOperacionesHistUniDAC.ConstruirSql(
  const AFiltros: TFiltrosCajaOperacionesHist): string;
begin
  // UNION conserva cada factura una vez cuando coincide por ambas vías.
  // El LEFT JOIN exterior conserva las líneas que no tienen factura.
  // STRAIGHT_JOIN consulta el índice de factura desde la operación filtrada.
  Result :=
    'WITH operaciones AS ( ' +
    '  SELECT o.ID_OPCAJA, o.CODIGO_EMP_OPCAJA, o.CODIGO_ALM_OPCAJA, ' +
    '         o.CODIGO_CAJA_OPCAJA, o.NUMERO_OPERACION_OPCAJA, ' +
    '         o.FECHA_OPERACION_OPCAJA, o.TIPO_OPERACION_OPCAJA, ' +
    '         o.CONCEPTO_GASTO_INGRESO_OPCAJA, o.IMPORTE_TOTAL_OPCAJA, ' +
    '         o.SERIE_FAC_OPCAJA, o.NUMERO_FAC_OPCAJA, ' +
    '         o.CODIGO_CLI_OPCAJA, o.CODIGO_EMPLEADO_OPCAJA ' +
    '    FROM fza_caja_operaciones o ' + ConstruirWhere(AFiltros) +
    '), facturas_operacion AS ( ' +
    '  SELECT o.ID_OPCAJA, f.SERIE_FAC, f.NUMERO_FAC, ' +
    '         f.TOTAL_LIQUIDO_FAC, f.CODIGO_CLI_FAC ' +
    '    FROM operaciones o ' +
    '    STRAIGHT_JOIN fza_facturas f ' +
    '      ON f.CODIGO_EMP_FAC = o.CODIGO_EMP_OPCAJA ' +
    '     AND f.CODIGO_ALM_FAC = o.CODIGO_ALM_OPCAJA ' +
    '     AND f.CODIGO_CAJA_FAC = o.CODIGO_CAJA_OPCAJA ' +
    '     AND f.NUMERO_OPERACION_FAC = o.NUMERO_OPERACION_OPCAJA ' +
    '  UNION ' +
    '  SELECT o.ID_OPCAJA, f.SERIE_FAC, f.NUMERO_FAC, ' +
    '         f.TOTAL_LIQUIDO_FAC, f.CODIGO_CLI_FAC ' +
    '    FROM operaciones o ' +
    '    JOIN fza_facturas f ' +
    '      ON f.SERIE_FAC = o.SERIE_FAC_OPCAJA ' +
    '     AND f.NUMERO_FAC = o.NUMERO_FAC_OPCAJA ' +
    '   WHERE f.CODIGO_CAJA_FAC = ''99'' ' +
    '     AND o.TIPO_OPERACION_OPCAJA = ''DV'' ' +
    ') ' +
    'SELECT o.CODIGO_EMP_OPCAJA, ' +
    '       o.CODIGO_ALM_OPCAJA, ' +
    '       o.CODIGO_CAJA_OPCAJA, ' +
    '       o.NUMERO_OPERACION_OPCAJA, ' +
    '       MIN(o.FECHA_OPERACION_OPCAJA) AS FECHA_OP, ' +
    '       GROUP_CONCAT(DISTINCT o.TIPO_OPERACION_OPCAJA ' +
    '                    ORDER BY o.TIPO_OPERACION_OPCAJA ' +
    '                    SEPARATOR '','') AS TIPOS_OP, ' +
    '       GROUP_CONCAT(DISTINCT ' +
    '                    NULLIF(o.CONCEPTO_GASTO_INGRESO_OPCAJA, '''') ' +
    '                    SEPARATOR '' | '') AS CONCEPTOS, ' +
    '       COALESCE(MAX(f.TOTAL_LIQUIDO_FAC), ' +
    '                SUM(o.IMPORTE_TOTAL_OPCAJA)) AS IMPORTE_TOTAL, ' +
    '       COALESCE(MAX(f.SERIE_FAC), MAX(o.SERIE_FAC_OPCAJA)) ' +
    '         AS SERIE_FAC, ' +
    '       COALESCE(MAX(f.NUMERO_FAC), MAX(o.NUMERO_FAC_OPCAJA)) ' +
    '         AS NUMERO_FAC, ' +
    '       MAX(COALESCE(f.CODIGO_CLI_FAC, o.CODIGO_CLI_OPCAJA)) ' +
    '         AS CLIENTE, ' +
    '       MAX(cli.RAZON_SOCIAL_CLI) AS RAZON_SOCIAL_CLI, ' +
    '       MAX(o.CODIGO_EMPLEADO_OPCAJA) AS EMPLEADO ' +
    '  FROM operaciones o ' +
    '  LEFT JOIN facturas_operacion f ON f.ID_OPCAJA = o.ID_OPCAJA ' +
    '  LEFT JOIN fza_clientes cli ' +
    '    ON cli.CODIGO_CLI_CLI = COALESCE(f.CODIGO_CLI_FAC, ' +
    '                                     o.CODIGO_CLI_OPCAJA) ' +
    ' GROUP BY o.CODIGO_EMP_OPCAJA, ' +
    '          o.CODIGO_ALM_OPCAJA, ' +
    '          o.CODIGO_CAJA_OPCAJA, ' +
    '          o.NUMERO_OPERACION_OPCAJA ' +
    ' ORDER BY FECHA_OP DESC, ' +
    '          CAST(o.NUMERO_OPERACION_OPCAJA AS UNSIGNED) DESC';
end;

function TRepositorioCajaOperacionesHistUniDAC.ListarAnyos:
  TCadenasCajaOperacionesHist;
var
  oConsulta: TUniQuery;
  iAnyo: Integer;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConsulta.Connection;
    oConsulta.SQL.Text :=
      'SELECT DISTINCT YEAR(FECHA_OPERACION_OPCAJA) AS ANYO ' +
      '  FROM fza_caja_operaciones ' +
      ' WHERE FECHA_OPERACION_OPCAJA IS NOT NULL ' +
      ' ORDER BY ANYO DESC';
    oConsulta.Open;
    SetLength(Result, oConsulta.RecordCount);
    iAnyo := 0;
    while not oConsulta.Eof do
    begin
      Result[iAnyo] := oConsulta.FieldByName('ANYO').AsString;
      Inc(iAnyo);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioCajaOperacionesHistUniDAC.ListarAlmacenes(
  const ARestriccion: TRestriccionCajaOperacionesHist
): TAlmacenesCajaOperacionesHist;
var
  oConsulta: TUniQuery;
  iAlmacen: Integer;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConsulta.Connection;
    oConsulta.SQL.Text :=
      'SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM ' +
      '  FROM fza_almacenes ' +
      ' WHERE ESACTIVO_ALM = ''S'' ' +
      ConstruirRestriccion(
        ARestriccion,
        'CODIGO_EMP_ALM',
        'CODIGO_ALM_ALM',
        '') +
      ' ORDER BY ORDEN_ALM, CODIGO_ALM_ALM';
    oConsulta.Open;
    SetLength(Result, oConsulta.RecordCount);
    iAlmacen := 0;
    while not oConsulta.Eof do
    begin
      Result[iAlmacen].Codigo :=
        oConsulta.FieldByName('CODIGO_ALM_ALM').AsString;
      Result[iAlmacen].Nombre :=
        oConsulta.FieldByName('NOMBRE_ALM_ALM').AsString;
      Inc(iAlmacen);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioCajaOperacionesHistUniDAC.PrepararConsulta(
  const AFiltros: TFiltrosCajaOperacionesHist): Boolean;
var
  sSql: string;
begin
  sSql := ConstruirSql(AFiltros);
  Result := Trim(FConsulta.SQL.Text) <> Trim(sSql);
  if Result then
  begin
    FConsulta.SQL.Text := sSql;
  end;
end;

function TRepositorioCajaOperacionesHistUniDAC.ContarOperaciones(
  const AFiltros: TFiltrosCajaOperacionesHist): Integer;
var
  oConsulta: TUniQuery;
begin
  Result := 0;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConsulta.Connection;
    oConsulta.SQL.Text :=
      'SELECT COUNT(*) AS N FROM ( ' +
      '  SELECT 1 ' +
      '    FROM fza_caja_operaciones o ' +
      ConstruirWhere(AFiltros) +
      '   GROUP BY o.CODIGO_EMP_OPCAJA, ' +
      '            o.CODIGO_ALM_OPCAJA, ' +
      '            o.CODIGO_CAJA_OPCAJA, ' +
      '            o.NUMERO_OPERACION_OPCAJA ' +
      ') q';
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      Result := oConsulta.Fields[0].AsInteger;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioCajaOperacionesHistUniDAC.AbrirConsulta(
  AFilasPorBloque: Integer);
begin
  FConsulta.Close;
  FConsulta.FetchRows := AFilasPorBloque;
  FConsulta.Open;
end;

function CrearRepositorioCajaOperacionesHistUniDAC(
  AConsulta: TUniQuery): IRepositorioCajaOperacionesHist;
begin
  Result := TRepositorioCajaOperacionesHistUniDAC.Create(AConsulta);
end;

end.
