{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPlanEjecucionMariaDB                                    }
{    Tipo:       Utilidad                                                     }
{ Versión:       1.0.0                                                        }
{   Fecha:       24/08/2026                                                   }
{                                                                              }
{  Descripción:                                                                }
{    Interpreta EXPLAIN/ANALYZE FORMAT=JSON de MariaDB y valida las sentencias }
{    SELECT que pueden utilizarse para obtener un plan de ejecución.           }
{******************************************************************************}
unit inLibPlanEjecucionMariaDB;

interface

uses
  System.SysUtils;

type
  TNodoPlanEjecucionMariaDB = record
    Id: Integer;
    PadreId: Integer;
    Nivel: Integer;
    Tipo: string;
    Titulo: string;
    Objeto: string;
    Acceso: string;
    Indice: string;
    Explicacion: string;
    RLoops: Double;
    Rows: Double;
    RRows: Double;
    RTotalTimeMs: Double;
    TieneRLoops: Boolean;
    TieneRows: Boolean;
    TieneRRows: Boolean;
    TieneRTotalTimeMs: Boolean;
  end;

  TPlanEjecucionMariaDB = record
    JsonOriginal: string;
    EsReal: Boolean;
    Nodos: TArray<TNodoPlanEjecucionMariaDB>;
  end;

function InterpretarPlanMariaDB(
  const AJson: string;
  AEsReal: Boolean): TPlanEjecucionMariaDB;

function NormalizarSelectParaPlan(const ASQL: string): string;

function ExtraerPrimeraSelectProcedimiento(
  const ADefinicion: string): string;

implementation

uses
  System.Classes,
  System.Generics.Collections,
  System.JSON;

resourcestring
  SPlanNodoBloqueSelect = 'Bloque SELECT';
  SPlanNodoBucleAnidado = 'Bucle anidado';
  SPlanNodoLecturaTabla = 'Lectura de tabla';
  SPlanNodoOrdenacionFilesort = 'Ordenación (filesort)';
  SPlanNodoTablaTemporal = 'Tabla temporal';
  SPlanNodoMaterializacion = 'Materialización';
  SPlanNodoSubconsultas = 'Subconsultas';
  SPlanNodoResultadoUnion = 'Resultado UNION';
  SPlanNodoUnionBloques = 'Unión por bloques (BNL)';
  SPlanNodoCacheExpresion = 'Caché de expresión';
  SPlanNodoIndicesEvaluadosFila = 'Índices evaluados por fila';
  SPlanNodoRamasUnion = 'Ramas de UNION';
  SPlanNodoLecturaOrdenada = 'Lectura ordenada';
  SPlanNodoEliminacionDuplicados = 'Eliminación de duplicados';
  SPlanNodoAgrupacion = 'Agrupación';
  SPlanNodoOrdenacion = 'Ordenación';
  SPlanNodoFuncionesVentana = 'Funciones de ventana';
  SPlanAccesoFilaConstante = 'MariaDB obtiene una sola fila constante.';
  SPlanAccesoFilaUnicaIndice =
    'Busca una única fila por índice por cada fila del nodo anterior.';
  SPlanAccesoIndiceNoUnico =
    'Busca por un índice no único usando un valor de referencia.';
  SPlanAccesoIntervaloIndice = 'Recorre solamente un intervalo del índice.';
  SPlanAccesoCombinacionIndices =
    'Combina los resultados de varios índices.';
  SPlanAccesoIndiceFulltext =
    'Realiza una búsqueda mediante un índice FULLTEXT.';
  SPlanAccesoIndiceConNulos =
    'Busca por índice y comprueba también las filas con valor NULL.';
  SPlanAccesoSubconsultaUnica =
    'Resuelve la subconsulta mediante una búsqueda única por índice.';
  SPlanAccesoSubconsultaIndice =
    'Resuelve la subconsulta mediante una búsqueda por índice.';
  SPlanAccesoIndiceCompleto = 'Recorre el índice completo.';
  SPlanAccesoTablaCompleta = 'Escanea todas las filas de la tabla.';
  SPlanAccesoTipo = 'MariaDB utiliza el tipo de acceso %s.';
  SPlanAccesoGenerico = 'Lee filas de la tabla para continuar el plan.';
  SPlanExplicacionBloqueSelect =
    'Coordina las operaciones necesarias para producir el resultado de este ' +
    'SELECT.';
  SPlanExplicacionBucleAnidado =
    'Por cada fila obtenida en un nodo se evalúa el siguiente nodo de la ' +
    'unión.';
  SPlanExplicacionOrdenacionFilesort =
    'Ordena las filas fuera del orden natural de un índice; puede usar ' +
    'memoria o disco.';
  SPlanDetalleClaveOrdenacion = 'Clave de ordenación: %s.';
  SPlanExplicacionTablaTemporal =
    'Materializa un resultado intermedio en una tabla temporal.';
  SPlanExplicacionMaterializacion =
    'Ejecuta una subconsulta y conserva su resultado para reutilizarlo.';
  SPlanExplicacionSubconsultas =
    'Agrupa las subconsultas dependientes de este nodo.';
  SPlanExplicacionResultadoUnion =
    'Combina los resultados producidos por las ramas de una UNION.';
  SPlanExplicacionUnionBloques =
    'Guarda filas en un buffer y las compara por bloques con la siguiente ' +
    'entrada.';
  SPlanDetalleTamanoBuffer = 'Tamaño del buffer: %s.';
  SPlanDetalleTipoUnion = 'Tipo de unión: %s.';
  SPlanExplicacionCacheExpresion =
    'Memoriza resultados de una expresión o subconsulta repetida.';
  SPlanDetalleEstado = 'Estado: %s.';
  SPlanExplicacionIndicesEvaluadosFila =
    'No hay un único índice fijado de antemano; MariaDB evalúa los índices ' +
    'disponibles para cada fila anterior.';
  SPlanDetalleIndicesCandidatos = 'Índices candidatos: %s.';
  SPlanExplicacionRamasUnion =
    'Contiene las consultas individuales que forman la UNION.';
  SPlanExplicacionLecturaOrdenada =
    'Lee el resultado producido por una operacion de ordenacion.';
  SPlanExplicacionEliminacionDuplicados =
    'Descarta filas duplicadas del resultado intermedio.';
  SPlanExplicacionAgrupacion =
    'Agrupa filas para calcular agregados o resolver GROUP BY.';
  SPlanExplicacionOrdenacion =
    'Ordena las filas para satisfacer ORDER BY.';
  SPlanExplicacionFuncionesVentana =
    'Calcula funciones de ventana sobre las filas de entrada.';
  SPlanExplicacionNodoGenerico = 'Nodo del plan de ejecución de MariaDB.';
  SPlanDetalleCondicion = 'Condicion: %s.';
  SErrorPlanJsonVacio = 'El plan de ejecución JSON está vacío.';
  SErrorPlanJsonNoDevuelto =
    'MariaDB no ha devuelto un JSON de plan valido.';
  SErrorCadenaSinPlanJson =
    'La cadena devuelta no contiene un plan JSON valido.';
  SErrorPlanJsonSinNodos =
    'El JSON no contiene nodos reconocibles de un plan de MariaDB.';
  SErrorComentarioEjecutableSelect =
    'No se admiten comentarios ejecutables ni pistas /*+ */ en el SELECT.';
  SErrorComentarioSqlSinCerrar = 'El comentario SQL no está cerrado.';
  SErrorLiteralSqlSinCerrar =
    'Hay una cadena o identificador SQL sin cerrar.';
  SErrorSqlCaracterNulo = 'El SQL contiene un carácter nulo no válido.';
  SErrorSqlBarrasInvertidas =
    'No se admiten barras invertidas: su interpretación depende de ' +
    'NO_BACKSLASH_ESCAPES. Use comillas duplicadas en los literales.';
  SErrorSelectIntoPlan =
    'No se admite SELECT INTO, OUTFILE ni DUMPFILE para obtener el plan.';
  SErrorPalabraSelectPlanNoAdmitida =
    'No se admite %s en una SELECT destinada al plan de ejecución.';
  SErrorPlanNoComienzaSelect =
    'El plan solo admite una sentencia que comience por SELECT.';
  SErrorSelectConInstruccionesPosteriores =
    'Solo se admite una sentencia SELECT sin instrucciones posteriores.';
  SErrorContenidoAntesSelect =
    'Antes de SELECT solo puede haber espacios o comentarios.';
  SErrorAsignacionVariablesSelect =
    'No se admiten asignaciones de variables (:=) en la SELECT.';
  SErrorSelectNoEncontrada = 'No se ha encontrado una sentencia SELECT.';
  SErrorSelectVacia = 'La sentencia SELECT está vacía.';

type
  TConstructorPlanMariaDB = class
  private
    FNodos: TList<TNodoPlanEjecucionMariaDB>;
    function AnadirNodo(
      const ATipo: string;
      AValor: TJSONValue;
      APadreId, ANivel: Integer): Integer;
    procedure CompletarNodo(
      var ANodo: TNodoPlanEjecucionMariaDB;
      const ATipo: string;
      AObjeto: TJSONObject);
    procedure ProcesarValor(
      AValor: TJSONValue;
      const AClave: string;
      APadreId, ANivel: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    function Construir(AValor: TJSONValue): TArray<TNodoPlanEjecucionMariaDB>;
  end;

function ValorObjeto(
  AObjeto: TJSONObject;
  const ANombre: string): TJSONValue;
begin
  Result := nil;
  if Assigned(AObjeto) then
    Result := AObjeto.GetValue(ANombre);
end;

function TextoValor(AValor: TJSONValue): string;
var
  i: Integer;
  oArray: TJSONArray;
begin
  Result := '';
  if Assigned(AValor) and not (AValor is TJSONNull) then
  begin
    if AValor is TJSONArray then
    begin
      oArray := TJSONArray(AValor);
      for i := 0 to oArray.Count - 1 do
      begin
        if Result <> '' then
          Result := Result + ', ';
        Result := Result + TextoValor(oArray.Items[i]);
      end;
    end;
    if not (AValor is TJSONObject) and not (AValor is TJSONArray) then
      Result := AValor.Value;
  end;
end;

function TextoObjeto(
  AObjeto: TJSONObject;
  const ANombre: string): string;
begin
  Result := TextoValor(ValorObjeto(AObjeto, ANombre));
end;

function IntentarNumeroValor(
  AValor: TJSONValue;
  out ANumero: Double): Boolean;
var
  oFormato: TFormatSettings;
  sValor: string;
begin
  ANumero := 0;
  Result := Assigned(AValor) and not (AValor is TJSONNull);
  if Result then
  begin
    sValor := Trim(AValor.Value);
    oFormato := TFormatSettings.Create;
    oFormato.DecimalSeparator := '.';
    oFormato.ThousandSeparator := #0;
    Result := TryStrToFloat(sValor, ANumero, oFormato);
  end;
end;

function IntentarNumeroObjeto(
  AObjeto: TJSONObject;
  const ANombre: string;
  out ANumero: Double): Boolean;
begin
  Result := IntentarNumeroValor(ValorObjeto(AObjeto, ANombre), ANumero);
end;

function TipoCanonico(const AClave: string): string;
var
  sClave: string;
begin
  sClave := LowerCase(AClave);
  if (sClave = 'range_checked_for_each_record') or
     (sClave = 'range-checked-for-each-record') or
     (sClave = 'range_checked') or
     (sClave = 'range-checked') then
    Result := 'range-checked'
  else
    Result := sClave;
end;

function EsTipoNodo(const ATipo: string): Boolean;
begin
  Result :=
    (ATipo = 'query_block') or
    (ATipo = 'nested_loop') or
    (ATipo = 'table') or
    (ATipo = 'filesort') or
    (ATipo = 'temporary_table') or
    (ATipo = 'materialized') or
    (ATipo = 'subqueries') or
    (ATipo = 'union_result') or
    (ATipo = 'block-nl-join') or
    (ATipo = 'expression_cache') or
    (ATipo = 'range-checked') or
    (ATipo = 'query_specifications') or
    (ATipo = 'read_sorted_file') or
    (ATipo = 'duplicates_removal') or
    (ATipo = 'grouping_operation') or
    (ATipo = 'ordering_operation') or
    (ATipo = 'window_functions_computation');
end;

function TituloTipo(
  const ATipo: string;
  AObjeto: TJSONObject): string;
var
  sDetalle: string;
begin
  if ATipo = 'query_block' then
  begin
    sDetalle := TextoObjeto(AObjeto, 'select_id');
    Result := SPlanNodoBloqueSelect;
    if sDetalle <> '' then
      Result := Result + ' ' + sDetalle;
  end
  else if ATipo = 'nested_loop' then
    Result := SPlanNodoBucleAnidado
  else if ATipo = 'table' then
  begin
    sDetalle := TextoObjeto(AObjeto, 'table_name');
    Result := SPlanNodoLecturaTabla;
    if sDetalle <> '' then
      Result := Result + ' ' + sDetalle;
  end
  else if ATipo = 'filesort' then
    Result := SPlanNodoOrdenacionFilesort
  else if ATipo = 'temporary_table' then
    Result := SPlanNodoTablaTemporal
  else if ATipo = 'materialized' then
    Result := SPlanNodoMaterializacion
  else if ATipo = 'subqueries' then
    Result := SPlanNodoSubconsultas
  else if ATipo = 'union_result' then
    Result := SPlanNodoResultadoUnion
  else if ATipo = 'block-nl-join' then
    Result := SPlanNodoUnionBloques
  else if ATipo = 'expression_cache' then
    Result := SPlanNodoCacheExpresion
  else if ATipo = 'range-checked' then
    Result := SPlanNodoIndicesEvaluadosFila
  else if ATipo = 'query_specifications' then
    Result := SPlanNodoRamasUnion
  else if ATipo = 'read_sorted_file' then
    Result := SPlanNodoLecturaOrdenada
  else if ATipo = 'duplicates_removal' then
    Result := SPlanNodoEliminacionDuplicados
  else if ATipo = 'grouping_operation' then
    Result := SPlanNodoAgrupacion
  else if ATipo = 'ordering_operation' then
    Result := SPlanNodoOrdenacion
  else if ATipo = 'window_functions_computation' then
    Result := SPlanNodoFuncionesVentana
  else
    Result := ATipo;
end;

function ExplicacionAccesoTabla(const AAcceso: string): string;
begin
  if SameText(AAcceso, 'system') or SameText(AAcceso, 'const') then
    Result := SPlanAccesoFilaConstante
  else if SameText(AAcceso, 'eq_ref') then
    Result := SPlanAccesoFilaUnicaIndice
  else if SameText(AAcceso, 'ref') then
    Result := SPlanAccesoIndiceNoUnico
  else if SameText(AAcceso, 'range') then
    Result := SPlanAccesoIntervaloIndice
  else if SameText(AAcceso, 'index_merge') then
    Result := SPlanAccesoCombinacionIndices
  else if SameText(AAcceso, 'fulltext') then
    Result := SPlanAccesoIndiceFulltext
  else if SameText(AAcceso, 'ref_or_null') then
    Result := SPlanAccesoIndiceConNulos
  else if SameText(AAcceso, 'unique_subquery') then
    Result := SPlanAccesoSubconsultaUnica
  else if SameText(AAcceso, 'index_subquery') then
    Result := SPlanAccesoSubconsultaIndice
  else if SameText(AAcceso, 'index') then
    Result := SPlanAccesoIndiceCompleto
  else if SameText(AAcceso, 'ALL') then
    Result := SPlanAccesoTablaCompleta
  else if AAcceso <> '' then
    Result := Format(SPlanAccesoTipo, [AAcceso])
  else
    Result := SPlanAccesoGenerico;
end;

procedure AnadirDetalle(var ATexto: string; const ADetalle: string);
begin
  if ADetalle <> '' then
  begin
    if ATexto <> '' then
      ATexto := ATexto + ' ';
    ATexto := ATexto + ADetalle;
  end;
end;

function ExplicacionTipo(
  const ATipo: string;
  AObjeto: TJSONObject): string;
var
  sDetalle: string;
begin
  if ATipo = 'query_block' then
    Result := SPlanExplicacionBloqueSelect
  else if ATipo = 'nested_loop' then
    Result := SPlanExplicacionBucleAnidado
  else if ATipo = 'table' then
    Result := ExplicacionAccesoTabla(TextoObjeto(AObjeto, 'access_type'))
  else if ATipo = 'filesort' then
  begin
    Result := SPlanExplicacionOrdenacionFilesort;
    sDetalle := TextoObjeto(AObjeto, 'sort_key');
    if sDetalle <> '' then
      AnadirDetalle(Result, Format(SPlanDetalleClaveOrdenacion, [sDetalle]));
  end
  else if ATipo = 'temporary_table' then
    Result := SPlanExplicacionTablaTemporal
  else if ATipo = 'materialized' then
    Result := SPlanExplicacionMaterializacion
  else if ATipo = 'subqueries' then
    Result := SPlanExplicacionSubconsultas
  else if ATipo = 'union_result' then
    Result := SPlanExplicacionResultadoUnion
  else if ATipo = 'block-nl-join' then
  begin
    Result := SPlanExplicacionUnionBloques;
    sDetalle := TextoObjeto(AObjeto, 'buffer_size');
    if sDetalle <> '' then
      AnadirDetalle(Result, Format(SPlanDetalleTamanoBuffer, [sDetalle]));
    sDetalle := TextoObjeto(AObjeto, 'join_type');
    if sDetalle <> '' then
      AnadirDetalle(Result, Format(SPlanDetalleTipoUnion, [sDetalle]));
  end
  else if ATipo = 'expression_cache' then
  begin
    Result := SPlanExplicacionCacheExpresion;
    sDetalle := TextoObjeto(AObjeto, 'state');
    if sDetalle <> '' then
      AnadirDetalle(Result, Format(SPlanDetalleEstado, [sDetalle]));
  end
  else if ATipo = 'range-checked' then
  begin
    Result := SPlanExplicacionIndicesEvaluadosFila;
    sDetalle := TextoObjeto(AObjeto, 'keys');
    if sDetalle <> '' then
      AnadirDetalle(Result, Format(SPlanDetalleIndicesCandidatos, [sDetalle]));
  end
  else if ATipo = 'query_specifications' then
    Result := SPlanExplicacionRamasUnion
  else if ATipo = 'read_sorted_file' then
    Result := SPlanExplicacionLecturaOrdenada
  else if ATipo = 'duplicates_removal' then
    Result := SPlanExplicacionEliminacionDuplicados
  else if ATipo = 'grouping_operation' then
    Result := SPlanExplicacionAgrupacion
  else if ATipo = 'ordering_operation' then
    Result := SPlanExplicacionOrdenacion
  else if ATipo = 'window_functions_computation' then
    Result := SPlanExplicacionFuncionesVentana
  else
    Result := SPlanExplicacionNodoGenerico;

  sDetalle := TextoObjeto(AObjeto, 'attached_condition');
  if sDetalle <> '' then
    AnadirDetalle(Result, Format(SPlanDetalleCondicion, [sDetalle]));
end;

{ TConstructorPlanMariaDB }

constructor TConstructorPlanMariaDB.Create;
begin
  inherited Create;
  FNodos := TList<TNodoPlanEjecucionMariaDB>.Create;
end;

destructor TConstructorPlanMariaDB.Destroy;
begin
  FNodos.Free;
  inherited Destroy;
end;

function TConstructorPlanMariaDB.AnadirNodo(
  const ATipo: string;
  AValor: TJSONValue;
  APadreId, ANivel: Integer): Integer;
var
  oObjeto: TJSONObject;
  oNodo: TNodoPlanEjecucionMariaDB;
begin
  oNodo := Default(TNodoPlanEjecucionMariaDB);
  oNodo.Id := Integer(FNodos.Count);
  oNodo.PadreId := APadreId;
  oNodo.Nivel := ANivel;
  oNodo.Tipo := ATipo;

  oObjeto := nil;
  if AValor is TJSONObject then
    oObjeto := TJSONObject(AValor);
  CompletarNodo(oNodo, ATipo, oObjeto);

  Result := oNodo.Id;
  FNodos.Add(oNodo);
end;

procedure TConstructorPlanMariaDB.CompletarNodo(
  var ANodo: TNodoPlanEjecucionMariaDB;
  const ATipo: string;
  AObjeto: TJSONObject);
var
  dOtroTiempo: Double;
  dTiempoTabla: Double;
  TieneOtroTiempo: Boolean;
  TieneTiempoTabla: Boolean;
begin
  ANodo.Titulo := TituloTipo(ATipo, AObjeto);
  ANodo.Objeto := TextoObjeto(AObjeto, 'table_name');
  ANodo.Acceso := TextoObjeto(AObjeto, 'access_type');
  if (ANodo.Acceso = '') and (ATipo = 'block-nl-join') then
    ANodo.Acceso := TextoObjeto(AObjeto, 'join_type');
  ANodo.Indice := TextoObjeto(AObjeto, 'key');
  ANodo.Explicacion := ExplicacionTipo(ATipo, AObjeto);

  ANodo.TieneRLoops := IntentarNumeroObjeto(
    AObjeto, 'r_loops', ANodo.RLoops);
  ANodo.TieneRows := IntentarNumeroObjeto(
    AObjeto, 'rows', ANodo.Rows);
  ANodo.TieneRRows := IntentarNumeroObjeto(
    AObjeto, 'r_rows', ANodo.RRows);
  ANodo.TieneRTotalTimeMs := IntentarNumeroObjeto(
    AObjeto, 'r_total_time_ms', ANodo.RTotalTimeMs);

  if not ANodo.TieneRTotalTimeMs then
  begin
    TieneTiempoTabla := IntentarNumeroObjeto(
      AObjeto, 'r_table_time_ms', dTiempoTabla);
    TieneOtroTiempo := IntentarNumeroObjeto(
      AObjeto, 'r_other_time_ms', dOtroTiempo);
    ANodo.TieneRTotalTimeMs := TieneTiempoTabla or TieneOtroTiempo;
    if ANodo.TieneRTotalTimeMs then
    begin
      ANodo.RTotalTimeMs := 0;
      if TieneTiempoTabla then
        ANodo.RTotalTimeMs := ANodo.RTotalTimeMs + dTiempoTabla;
      if TieneOtroTiempo then
        ANodo.RTotalTimeMs := ANodo.RTotalTimeMs + dOtroTiempo;
    end;
  end;
end;

function TConstructorPlanMariaDB.Construir(
  AValor: TJSONValue): TArray<TNodoPlanEjecucionMariaDB>;
begin
  FNodos.Clear;
  ProcesarValor(AValor, '', -1, 0);
  Result := FNodos.ToArray;
end;

procedure TConstructorPlanMariaDB.ProcesarValor(
  AValor: TJSONValue;
  const AClave: string;
  APadreId, ANivel: Integer);
var
  i: Integer;
  iNodoId: Integer;
  oArray: TJSONArray;
  oObjeto: TJSONObject;
  oPar: TJSONPair;
  sTipo: string;
begin
  if Assigned(AValor) then
  begin
    sTipo := TipoCanonico(AClave);
    if EsTipoNodo(sTipo) then
    begin
      iNodoId := AnadirNodo(sTipo, AValor, APadreId, ANivel);
      APadreId := iNodoId;
      Inc(ANivel);
    end;

    if AValor is TJSONObject then
    begin
      oObjeto := TJSONObject(AValor);
      for i := 0 to oObjeto.Count - 1 do
      begin
        oPar := oObjeto.Pairs[i];
        if (oPar.JsonValue is TJSONObject) or
           (oPar.JsonValue is TJSONArray) then
          ProcesarValor(oPar.JsonValue, oPar.JsonString.Value,
            APadreId, ANivel);
      end;
    end
    else if AValor is TJSONArray then
    begin
      oArray := TJSONArray(AValor);
      for i := 0 to oArray.Count - 1 do
        if (oArray.Items[i] is TJSONObject) or
           (oArray.Items[i] is TJSONArray) then
          ProcesarValor(oArray.Items[i], '', APadreId, ANivel);
    end;
  end;
end;

function InterpretarPlanMariaDB(
  const AJson: string;
  AEsReal: Boolean): TPlanEjecucionMariaDB;
var
  oConstructor: TConstructorPlanMariaDB;
  oRaiz: TJSONValue;
  oRaizInterior: TJSONValue;
begin
  Result := Default(TPlanEjecucionMariaDB);
  Result.JsonOriginal := AJson;
  Result.EsReal := AEsReal;

  if Trim(AJson) = '' then
    raise EConvertError.Create(SErrorPlanJsonVacio);

  oRaiz := TJSONObject.ParseJSONValue(AJson);
  if not Assigned(oRaiz) then
    raise EConvertError.Create(SErrorPlanJsonNoDevuelto);
  try
    { Algunos componentes de acceso pueden devolver el JSON como una cadena }
    { JSON. }
    if oRaiz is TJSONString then
    begin
      oRaizInterior := TJSONObject.ParseJSONValue(oRaiz.Value);
      if not Assigned(oRaizInterior) then
        raise EConvertError.Create(SErrorCadenaSinPlanJson);
      try
        oConstructor := TConstructorPlanMariaDB.Create;
        try
          Result.Nodos := oConstructor.Construir(oRaizInterior);
        finally
          oConstructor.Free;
        end;
      finally
        oRaizInterior.Free;
      end;
    end
    else
    begin
      oConstructor := TConstructorPlanMariaDB.Create;
      try
        Result.Nodos := oConstructor.Construir(oRaiz);
      finally
        oConstructor.Free;
      end;
    end;
  finally
    oRaiz.Free;
  end;

  if Length(Result.Nodos) = 0 then
    raise EConvertError.Create(SErrorPlanJsonSinNodos);
end;

function EsInicioPalabraSQL(ACaracter: Char): Boolean;
begin
  Result := CharInSet(ACaracter, ['A'..'Z', 'a'..'z', '_', '$']);
end;

function EsPartePalabraSQL(ACaracter: Char): Boolean;
begin
  Result := EsInicioPalabraSQL(ACaracter) or
    CharInSet(ACaracter, ['0'..'9']);
end;

function EsInicioComentarioGuion(
  const ASQL: string;
  APosicion: Integer): Boolean;
begin
  Result := (APosicion < Length(ASQL)) and
    (ASQL[APosicion] = '-') and
    (ASQL[APosicion + 1] = '-') and
    ((APosicion + 2 > Length(ASQL)) or
     (Ord(ASQL[APosicion + 2]) <= 32));
end;

procedure SaltarComentarioLinea(const ASQL: string; var APosicion: Integer);
begin
  while (APosicion <= Length(ASQL)) and
        not CharInSet(ASQL[APosicion], [#10, #13]) do
    Inc(APosicion);
end;

procedure SaltarComentarioBloque(
  const ASQL: string;
  var APosicion: Integer;
  ARechazarEjecutable: Boolean);
var
  EsEjecutable: Boolean;
begin
  EsEjecutable :=
    ((APosicion + 2 <= Length(ASQL)) and
     CharInSet(ASQL[APosicion + 2], ['!', '+'])) or
    ((APosicion + 3 <= Length(ASQL)) and
     CharInSet(ASQL[APosicion + 2], ['M', 'm']) and
     (ASQL[APosicion + 3] = '!'));
  if ARechazarEjecutable and EsEjecutable then
    raise EArgumentException.Create(SErrorComentarioEjecutableSelect);

  Inc(APosicion, 2);
  while (APosicion + 1 <= Length(ASQL)) and
        not ((ASQL[APosicion] = '*') and (ASQL[APosicion + 1] = '/')) do
    Inc(APosicion);
  if APosicion + 1 > Length(ASQL) then
    raise EArgumentException.Create(SErrorComentarioSqlSinCerrar);
  Inc(APosicion, 2);
end;

procedure SaltarLiteral(
  const ASQL: string;
  var APosicion: Integer;
  ADelimitador: Char);
var
  bCerrado: Boolean;
begin
  bCerrado := False;
  Inc(APosicion);
  while (APosicion <= Length(ASQL)) and not bCerrado do
  begin
    if (ASQL[APosicion] = '\') and (APosicion < Length(ASQL)) then
      Inc(APosicion, 2)
    else if ASQL[APosicion] = ADelimitador then
    begin
      if (APosicion < Length(ASQL)) and
         (ASQL[APosicion + 1] = ADelimitador) then
        Inc(APosicion, 2)
      else
      begin
        Inc(APosicion);
        bCerrado := True;
      end;
    end
    else
      Inc(APosicion);
  end;
  if not bCerrado then
    raise EArgumentException.Create(SErrorLiteralSqlSinCerrar);
end;

procedure ValidarCaracteresSelectParaPlan(const ASQL: string);
begin
  if Pos(#0, ASQL) > 0 then
    raise EArgumentException.Create(SErrorSqlCaracterNulo);
  if Pos('\', ASQL) > 0 then
    raise EArgumentException.Create(SErrorSqlBarrasInvertidas);
end;

function IntentarSaltarSeparadorSQL(
  const ASQL: string;
  var APosicion: Integer): Boolean;
begin
  Result := True;
  if CharInSet(ASQL[APosicion], [' ', #9, #10, #13]) then
    Inc(APosicion)
  else if EsInicioComentarioGuion(ASQL, APosicion) then
  begin
    Inc(APosicion, 2);
    SaltarComentarioLinea(ASQL, APosicion);
  end
  else if ASQL[APosicion] = '#' then
  begin
    Inc(APosicion);
    SaltarComentarioLinea(ASQL, APosicion);
  end
  else if (ASQL[APosicion] = '/') and
          (APosicion < Length(ASQL)) and
          (ASQL[APosicion + 1] = '*') then
    SaltarComentarioBloque(ASQL, APosicion, True)
  else
    Result := False;
end;

function CoincideConAlgunaPalabra(
  const APalabra: string;
  const AAlternativas: array of string): Boolean;
var
  sAlternativa: string;
begin
  Result := False;
  for sAlternativa in AAlternativas do
    Result := Result or SameText(APalabra, sAlternativa);
end;

procedure ValidarPalabraSelectParaPlan(const APalabra: string);
begin
  if CoincideConAlgunaPalabra(
       APalabra,
       ['INTO', 'OUTFILE', 'DUMPFILE']) then
    raise EArgumentException.Create(SErrorSelectIntoPlan);

  if CoincideConAlgunaPalabra(
       APalabra,
       ['UPDATE', 'LOCK', 'GET_LOCK', 'RELEASE_LOCK', 'RELEASE_ALL_LOCKS',
        'SLEEP', 'BENCHMARK', 'LOAD_FILE', 'NEXTVAL', 'SETVAL',
        'LAST_INSERT_ID']) then
    raise EArgumentException.CreateFmt(
      SErrorPalabraSelectPlanNoAdmitida,
      [APalabra]);
end;

procedure ProcesarPalabraSelect(
  const ASQL: string;
  var APosicion: Integer;
  var AEsPrimeraPalabra: Boolean;
  var AInicioSelect: Integer);
var
  iInicio: Integer;
  sPalabra: string;
begin
  iInicio := APosicion;
  Inc(APosicion);
  while (APosicion <= Length(ASQL)) and
        EsPartePalabraSQL(ASQL[APosicion]) do
    Inc(APosicion);
  sPalabra := Copy(ASQL, iInicio, APosicion - iInicio);

  if AEsPrimeraPalabra then
  begin
    if not SameText(sPalabra, 'SELECT') then
      raise EArgumentException.Create(SErrorPlanNoComienzaSelect);
    AInicioSelect := iInicio;
    AEsPrimeraPalabra := False;
  end
  else
    ValidarPalabraSelectParaPlan(sPalabra);
end;

function NormalizarSelectParaPlan(const ASQL: string): string;
var
  EsPrimeraPalabra: Boolean;
  i: Integer;
  iFin: Integer;
  iInicioSelect: Integer;
  iPuntoComa: Integer;
begin
  ValidarCaracteresSelectParaPlan(ASQL);

  i := 1;
  iInicioSelect := 0;
  iPuntoComa := 0;
  EsPrimeraPalabra := True;

  while i <= Length(ASQL) do
  begin
    if not IntentarSaltarSeparadorSQL(ASQL, i) then
    begin
      if iPuntoComa > 0 then
        raise EArgumentException.Create(
          SErrorSelectConInstruccionesPosteriores);

      if CharInSet(ASQL[i], ['''', '"', '`']) then
      begin
        if EsPrimeraPalabra then
          raise EArgumentException.Create(SErrorContenidoAntesSelect);
        SaltarLiteral(ASQL, i, ASQL[i]);
      end
      else if ASQL[i] = ';' then
      begin
        iPuntoComa := i;
        Inc(i);
      end
      else if EsInicioPalabraSQL(ASQL[i]) then
        ProcesarPalabraSelect(
          ASQL,
          i,
          EsPrimeraPalabra,
          iInicioSelect)
      else
      begin
        if EsPrimeraPalabra then
          raise EArgumentException.Create(SErrorContenidoAntesSelect);
        if (ASQL[i] = ':') and (i < Length(ASQL)) and
           (ASQL[i + 1] = '=') then
          raise EArgumentException.Create(SErrorAsignacionVariablesSelect);
        Inc(i);
      end;
    end;
  end;

  if EsPrimeraPalabra or (iInicioSelect = 0) then
    raise EArgumentException.Create(SErrorSelectNoEncontrada);

  if iPuntoComa > 0 then
    iFin := iPuntoComa - 1
  else
    iFin := Length(ASQL);
  Result := Trim(Copy(ASQL, iInicioSelect, iFin - iInicioSelect + 1));
  if Result = '' then
    raise EArgumentException.Create(SErrorSelectVacia);
end;

function BuscarPalabraSelect(
  const ASQL: string;
  var APosicion: Integer;
  out AInicio: Integer): Boolean;
var
  bInicioSentencia: Boolean;
  iInicio: Integer;
  sPalabra: string;
begin
  Result := False;
  AInicio := 0;
  bInicioSentencia := True;
  while (APosicion <= Length(ASQL)) and not Result do
  begin
    if CharInSet(ASQL[APosicion], [' ', #9, #10, #13]) then
      Inc(APosicion)
    else if EsInicioComentarioGuion(ASQL, APosicion) then
    begin
      Inc(APosicion, 2);
      SaltarComentarioLinea(ASQL, APosicion);
    end
    else if ASQL[APosicion] = '#' then
    begin
      Inc(APosicion);
      SaltarComentarioLinea(ASQL, APosicion);
    end
    else if (ASQL[APosicion] = '/') and
            (APosicion < Length(ASQL)) and
            (ASQL[APosicion + 1] = '*') then
    begin
      SaltarComentarioBloque(ASQL, APosicion, False);
    end
    else if CharInSet(ASQL[APosicion], ['''', '"', '`']) then
      SaltarLiteral(ASQL, APosicion, ASQL[APosicion])
    else if EsInicioPalabraSQL(ASQL[APosicion]) then
    begin
      iInicio := APosicion;
      Inc(APosicion);
      while (APosicion <= Length(ASQL)) and
            EsPartePalabraSQL(ASQL[APosicion]) do
        Inc(APosicion);
      sPalabra := Copy(ASQL, iInicio, APosicion - iInicio);
      if SameText(sPalabra, 'SELECT') and bInicioSentencia then
      begin
        AInicio := iInicio;
        Result := True;
      end
      else
      begin
        bInicioSentencia :=
          SameText(sPalabra, 'BEGIN') or
          SameText(sPalabra, 'THEN') or
          SameText(sPalabra, 'ELSE') or
          SameText(sPalabra, 'DO');
      end;
    end
    else
    begin
      if CharInSet(ASQL[APosicion], [';', ':']) then
        bInicioSentencia := True
      else
        bInicioSentencia := False;
      Inc(APosicion);
    end;
  end;
end;

function BuscarFinSentenciaSelect(
  const ASQL: string;
  AInicio: Integer;
  out AFin: Integer): Boolean;
var
  i: Integer;
begin
  Result := False;
  AFin := Length(ASQL);
  i := AInicio;
  while (i <= Length(ASQL)) and not Result do
  begin
    if EsInicioComentarioGuion(ASQL, i) then
    begin
      Inc(i, 2);
      SaltarComentarioLinea(ASQL, i);
    end
    else if ASQL[i] = '#' then
    begin
      Inc(i);
      SaltarComentarioLinea(ASQL, i);
    end
    else if (ASQL[i] = '/') and (i < Length(ASQL)) and
            (ASQL[i + 1] = '*') then
      SaltarComentarioBloque(ASQL, i, False)
    else if CharInSet(ASQL[i], ['''', '"', '`']) then
      SaltarLiteral(ASQL, i, ASQL[i])
    else if ASQL[i] = ';' then
    begin
      AFin := i - 1;
      Result := True;
    end
    else
      Inc(i);
  end;
end;

function ExtraerPrimeraSelectProcedimiento(
  const ADefinicion: string): string;
var
  bFinalizado: Boolean;
  i: Integer;
  iFin: Integer;
  iInicio: Integer;
  sCandidata: string;
begin
  Result := '';
  bFinalizado := False;
  i := 1;
  while not bFinalizado and
        BuscarPalabraSelect(ADefinicion, i, iInicio) do
  begin
    if not BuscarFinSentenciaSelect(ADefinicion, iInicio, iFin) then
      bFinalizado := True
    else
    begin
      sCandidata := Copy(ADefinicion, iInicio, iFin - iInicio + 1);
      try
        Result := NormalizarSelectParaPlan(sCandidata);
        bFinalizado := True;
      except
        on E: EArgumentException do
        begin
          i := iFin + 2;
          Result := '';
        end;
      end;
    end;
  end;
end;

end.
