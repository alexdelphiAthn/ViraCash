{******************************************************************************}
{ Propiedades de familia en el borrador de una sesion de compra.               }
{ Adapta el editor de Articulos sin escribir articulos antes de materializar.  }
{******************************************************************************}
unit UniDataComprasSesionesPropiedades;

interface

uses
  System.Classes, Uni, inLibArticulosPropiedadesPersistenciaIntf;

function CrearServiciosPropiedadesSesion(AConexion: TUniConnection;
  const ASerie, ANumero: string; ALinea: Integer):
  TServiciosPropiedadesArticulo;
procedure ValidarPropiedadesFamiliaSesion(AConexion: TUniConnection;
  const ASerie, ANumero: string; AIncidencias: TStrings);
procedure BorrarPropiedadesLineaSesion(AConexion: TUniConnection;
  const ASerie, ANumero: string; ALinea: Integer);
procedure MaterializarPropiedadesLineaSesion(AConexion: TUniConnection;
  const ASerie, ANumero: string; ALinea: Integer;
  const AArticulo, AUsuario: string);
function TemporadaPropiedadesLineaSesion(AConexion: TUniConnection;
  const ASerie, ANumero: string; ALinea, ADefecto: Integer): Integer;

implementation

uses
  System.SysUtils, Data.DB,
  UniDataArticulosPropiedadesRepositorio, inLibMsgCompras;

type
  TPropiedadesSesion = class(TInterfacedObject,
    ILectorPropiedadesArticulo, IEscritorPropiedadesArticulo)
  private
    FConexion: TUniConnection;
    FBase: TServiciosPropiedadesArticulo;
    FSerie, FNumero, FFamilia, FArticulo: string;
    FLinea: Integer;
    FExiste, FReusar: Boolean;
    function Consulta: TUniQuery;
    procedure Parametros(AConsulta: TUniQuery);
    function Indice(const ALista: TArray<TDefinicionPropiedadArticulo>;
      const ACodigo: string): Integer;
  public
    constructor Create(AConexion: TUniConnection;
      const ASerie, ANumero: string; ALinea: Integer);
    function ListarDisponibles: TArray<TDefinicionPropiedadArticulo>;
    function ListarAsignadas(const ACodigoArticulo: string):
      TArray<TDefinicionPropiedadArticulo>;
    function ListarFamilia(const ACodigoFamilia: string):
      TArray<TDefinicionPropiedadArticulo>;
    function Buscar(const ACodigoPropiedad: string;
      out APropiedad: TDefinicionPropiedadArticulo): Boolean;
    function ListarOpciones(const ACodigoPropiedad: string):
      TArray<TOpcionPropiedadArticulo>;
    function ListarUnidades(const ACodigoArticulo, ANivel: string):
      TArray<TUnidadPropiedadArticulo>;
    function ListarValoresUnidades(
      const ACodigoArticulo, ACodigoPropiedad: string):
      TArray<TValorUnidadPropiedadArticulo>;
    procedure GuardarValor(
      const ACodigoArticulo, ACodigoPropiedad, ACodigoUnidad: string;
      AIdValor: Integer; const AValorLibre, AUsuario: string);
    procedure EliminarPropiedad(
      const ACodigoArticulo, ACodigoPropiedad, AUsuario: string);
    procedure EliminarValorUnidad(const ACodigoArticulo,
      ACodigoPropiedad, ACodigoUnidad, AUsuario: string);
  end;

const
  // Las filas de distintos colores del mismo articulo comparten propiedades.
  SQL_DESTINO = 'CASE WHEN L.ACCION_DUPLICADO_SESLIN = ''REUSAR'' ' +
    'THEN L.CODIGO_ART_REUSAR_SESLIN ' +
    'ELSE L.CODIGO_ART_TENTATIVO_SESLIN END';
  SQL_AMBITO = ' L.SERIE_SES_SESLIN = :SERIE AND ' +
    'L.NUMERO_SES_SESLIN = :NUMERO AND ((:ARTICULO = '''' AND ' +
    'L.LINEA_SESLIN = :LINEA) OR (:ARTICULO <> '''' AND ' +
    SQL_DESTINO + ' = :ARTICULO))';

constructor TPropiedadesSesion.Create(AConexion: TUniConnection;
  const ASerie, ANumero: string; ALinea: Integer);
var
  Q: TUniQuery;
begin
  inherited Create;
  FConexion := AConexion;
  FSerie := ASerie;
  FNumero := ANumero;
  FLinea := ALinea;
  FBase := CrearServiciosPropiedadesArticuloUniDAC(AConexion);
  Q := Consulta;
  try
    Q.SQL.Text := 'SELECT COALESCE(NULLIF(L.CODIGO_FAM_SESLIN, ''''),' +
      ' S.CODIGO_FAM_SES) AS FAMILIA, ' + SQL_DESTINO + ' AS ARTICULO,' +
      ' L.ACCION_DUPLICADO_SESLIN FROM fza_compras_sesiones_lineas L' +
      ' JOIN fza_compras_sesiones S ON S.SERIE_SES=L.SERIE_SES_SESLIN' +
      ' AND S.NUMERO_SES=L.NUMERO_SES_SESLIN' +
      ' WHERE L.SERIE_SES_SESLIN=:SERIE AND L.NUMERO_SES_SESLIN=:NUMERO' +
      ' AND L.LINEA_SESLIN=:LINEA';
    Parametros(Q);
    Q.Open;
    FExiste := not Q.IsEmpty;
    if FExiste then
    begin
      FFamilia := Q.FieldByName('FAMILIA').AsString;
      FArticulo := Q.FieldByName('ARTICULO').AsString;
      FReusar := Q.FieldByName('ACCION_DUPLICADO_SESLIN').AsString = 'REUSAR';
    end;
  finally
    Q.Free;
  end;
end;

function TPropiedadesSesion.Consulta: TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

procedure TPropiedadesSesion.Parametros(AConsulta: TUniQuery);
begin
  if AConsulta.Params.FindParam('SERIE') <> nil then
    AConsulta.ParamByName('SERIE').AsString := FSerie;
  if AConsulta.Params.FindParam('NUMERO') <> nil then
    AConsulta.ParamByName('NUMERO').AsString := FNumero;
  if AConsulta.Params.FindParam('LINEA') <> nil then
    AConsulta.ParamByName('LINEA').AsInteger := FLinea;
  if AConsulta.Params.FindParam('ARTICULO') <> nil then
    AConsulta.ParamByName('ARTICULO').AsString := FArticulo;
end;

function TPropiedadesSesion.Indice(
  const ALista: TArray<TDefinicionPropiedadArticulo>;
  const ACodigo: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(ALista) do
    if SameText(ALista[I].Codigo, ACodigo) then
      Result := I;
end;

function TPropiedadesSesion.ListarAsignadas(const ACodigoArticulo: string):
  TArray<TDefinicionPropiedadArticulo>;
var
  Q: TUniQuery;
  P, DefinicionExtra: TDefinicionPropiedadArticulo;
  Valores: TArray<TDefinicionPropiedadArticulo>;
  I, Posicion: Integer;
  procedure Aplicar(const ACodigo: string; AId: Integer;
    const AValor: string);
  begin
    Posicion := Indice(Result, ACodigo);
    if (Posicion < 0) and FBase.Lectura.Buscar(ACodigo, DefinicionExtra) then
    begin
      Posicion := Length(Result);
      SetLength(Result, Posicion + 1);
      Result[Posicion] := DefinicionExtra;
    end;
    if Posicion >= 0 then
    begin
      Result[Posicion].IdValor := AId;
      Result[Posicion].ValorLibre := AValor;
    end;
  end;
begin
  Result := nil;
  if FExiste then
  begin
    Result := FBase.Lectura.ListarFamilia(FFamilia);
    if FReusar and (FArticulo <> '') then
    begin
      Valores := FBase.Lectura.ListarAsignadas(FArticulo);
      for P in Valores do
        Aplicar(P.Codigo, P.IdValor, P.ValorLibre);
    end;
    Q := Consulta;
    try
      Q.SQL.Text := 'SELECT CODIGO_PROP_SESPROP AS CODIGO,' +
        ' ID_PV_DEFECTO_SESPROP AS ID_VALOR,' +
        ' VALOR_DEFECTO_SESPROP AS VALOR FROM fza_compras_sesiones_props' +
        ' WHERE SERIE_SES_SESPROP=:SERIE AND NUMERO_SES_SESPROP=:NUMERO';
      Parametros(Q);
      Q.Open;
      while not Q.Eof do
      begin
        Posicion := Indice(Result, Q.FieldByName('CODIGO').AsString);
        // El valor ya informado de un articulo reutilizado tiene prioridad.
        if (Posicion < 0) or ((Result[Posicion].IdValor <= 0) and
          (Trim(Result[Posicion].ValorLibre) = '')) then
          Aplicar(Q.FieldByName('CODIGO').AsString,
            Q.FieldByName('ID_VALOR').AsInteger,
            Q.FieldByName('VALOR').AsString);
        Q.Next;
      end;
      Q.Close;
      Q.SQL.Text := 'SELECT ID_PV_TEMPORADA_SES FROM fza_compras_sesiones' +
        ' WHERE SERIE_SES=:SERIE AND NUMERO_SES=:NUMERO';
      Parametros(Q);
      Q.Open;
      Posicion := Indice(Result, 'TEMPORADA');
      if (not Q.IsEmpty) and (not Q.Fields[0].IsNull) and
        ((Posicion < 0) or (Result[Posicion].IdValor <= 0)) then
        Aplicar('TEMPORADA', Q.Fields[0].AsInteger, '');
      Q.Close;
      Q.SQL.Text := 'SELECT P.CODIGO_PROP_SESLPROP AS CODIGO,' +
        ' P.ID_PV_SESLPROP AS ID_VALOR, P.VALOR_LIBRE_SESLPROP AS VALOR' +
        ' FROM fza_compras_sesiones_lineas_props P' +
        ' JOIN fza_compras_sesiones_lineas L' +
        ' ON L.SERIE_SES_SESLIN=P.SERIE_SES_SESLPROP' +
        ' AND L.NUMERO_SES_SESLIN=P.NUMERO_SES_SESLPROP' +
        ' AND L.LINEA_SESLIN=P.LINEA_SES_SESLPROP WHERE ' + SQL_AMBITO +
        ' ORDER BY L.LINEA_SESLIN';
      Parametros(Q);
      Q.Open;
      while not Q.Eof do
      begin
        Aplicar(Q.FieldByName('CODIGO').AsString,
          Q.FieldByName('ID_VALOR').AsInteger,
          Q.FieldByName('VALOR').AsString);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
    // Valor comun de articulo; los SKU heredan ese valor al crearse.
    for I := 0 to High(Result) do
    begin
      Result[I].Nivel := 'ARTICULO';
      if SameText(Result[I].TipoValor, 'BOOLEANO') and
        (Trim(Result[I].ValorLibre) = '') then
        Result[I].ValorLibre := 'N';
    end;
  end;
end;

function TPropiedadesSesion.ListarDisponibles:
  TArray<TDefinicionPropiedadArticulo>;
begin
  Result := FBase.Lectura.ListarDisponibles;
end;
function TPropiedadesSesion.ListarFamilia(const ACodigoFamilia: string):
  TArray<TDefinicionPropiedadArticulo>;
begin
  Result := FBase.Lectura.ListarFamilia(ACodigoFamilia);
end;
function TPropiedadesSesion.Buscar(const ACodigoPropiedad: string;
  out APropiedad: TDefinicionPropiedadArticulo): Boolean;
begin
  Result := FBase.Lectura.Buscar(ACodigoPropiedad, APropiedad);
  APropiedad.Nivel := 'ARTICULO';
end;
function TPropiedadesSesion.ListarOpciones(const ACodigoPropiedad: string):
  TArray<TOpcionPropiedadArticulo>;
begin
  Result := FBase.Lectura.ListarOpciones(ACodigoPropiedad);
end;
function TPropiedadesSesion.ListarUnidades(
  const ACodigoArticulo, ANivel: string): TArray<TUnidadPropiedadArticulo>;
begin
  Result := nil;
end;
function TPropiedadesSesion.ListarValoresUnidades(
  const ACodigoArticulo, ACodigoPropiedad: string):
  TArray<TValorUnidadPropiedadArticulo>;
begin
  Result := nil;
end;

procedure TPropiedadesSesion.GuardarValor(const ACodigoArticulo,
  ACodigoPropiedad, ACodigoUnidad: string; AIdValor: Integer;
  const AValorLibre, AUsuario: string);
var
  Q: TUniQuery;
begin
  Q := Consulta;
  try
    Q.SQL.Text := 'INSERT INTO fza_compras_sesiones_lineas_props' +
      ' (SERIE_SES_SESLPROP,NUMERO_SES_SESLPROP,LINEA_SES_SESLPROP,' +
      ' CODIGO_PROP_SESLPROP,ID_PV_SESLPROP,VALOR_LIBRE_SESLPROP,' +
      ' INSTANTE_ALTA,USUARIO_ALTA)' +
      ' SELECT L.SERIE_SES_SESLIN,L.NUMERO_SES_SESLIN,L.LINEA_SESLIN,' +
      ' :PROP, :ID_VALOR, :VALOR, NOW(), :USUARIO' +
      ' FROM fza_compras_sesiones_lineas L JOIN fza_compras_sesiones S' +
      ' ON S.SERIE_SES=L.SERIE_SES_SESLIN' +
      ' AND S.NUMERO_SES=L.NUMERO_SES_SESLIN WHERE ' + SQL_AMBITO +
      ' AND S.ESTADO_SES <> ''CERRADA''' +
      ' ON DUPLICATE KEY UPDATE ID_PV_SESLPROP=VALUES(ID_PV_SESLPROP),' +
      ' VALOR_LIBRE_SESLPROP=VALUES(VALOR_LIBRE_SESLPROP)';
    Parametros(Q);
    Q.ParamByName('PROP').AsString := ACodigoPropiedad;
    if AIdValor > 0 then
      Q.ParamByName('ID_VALOR').AsInteger := AIdValor
    else
      Q.ParamByName('ID_VALOR').Clear;
    if Trim(AValorLibre) <> '' then
      Q.ParamByName('VALOR').AsString := AValorLibre
    else
      Q.ParamByName('VALOR').Clear;
    Q.ParamByName('USUARIO').AsString := AUsuario;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

procedure TPropiedadesSesion.EliminarPropiedad(
  const ACodigoArticulo, ACodigoPropiedad, AUsuario: string);
begin
  // Una fila vacia suprime tambien la propuesta de cabecera al reabrir.
  GuardarValor(ACodigoArticulo, ACodigoPropiedad, '', 0, '', AUsuario);
end;
procedure TPropiedadesSesion.EliminarValorUnidad(const ACodigoArticulo,
  ACodigoPropiedad, ACodigoUnidad, AUsuario: string);
begin
  EliminarPropiedad(ACodigoArticulo, ACodigoPropiedad, AUsuario);
end;

function CrearServiciosPropiedadesSesion(AConexion: TUniConnection;
  const ASerie, ANumero: string; ALinea: Integer):
  TServiciosPropiedadesArticulo;
var
  Repositorio: TPropiedadesSesion;
begin
  Repositorio := TPropiedadesSesion.Create(AConexion, ASerie, ANumero, ALinea);
  Result.Lectura := Repositorio;
  Result.Escritura := Repositorio;
end;

function PropiedadInformada(const P: TDefinicionPropiedadArticulo): Boolean;
begin
  if SameText(P.TipoValor, 'LISTA') then
    Result := P.IdValor > 0
  else
    Result := Trim(P.ValorLibre) <> '';
end;

procedure ValidarPropiedadesFamiliaSesion(AConexion: TUniConnection;
  const ASerie, ANumero: string; AIncidencias: TStrings);
var
  Q: TUniQuery;
  Servicios: TServiciosPropiedadesArticulo;
  P: TDefinicionPropiedadArticulo;
  Opcion: TOpcionPropiedadArticulo;
  TieneValor: Boolean;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConexion;
    Q.SQL.Text := 'SELECT LINEA_SESLIN FROM fza_compras_sesiones_lineas' +
      ' WHERE SERIE_SES_SESLIN=:SERIE AND NUMERO_SES_SESLIN=:NUMERO' +
      ' ORDER BY LINEA_SESLIN';
    Q.ParamByName('SERIE').AsString := ASerie;
    Q.ParamByName('NUMERO').AsString := ANumero;
    Q.Open;
    while not Q.Eof do
    begin
      Servicios := CrearServiciosPropiedadesSesion(AConexion,
        ASerie, ANumero, Q.Fields[0].AsInteger);
      for P in Servicios.Lectura.ListarAsignadas('') do
      begin
        TieneValor := PropiedadInformada(P);
        if TieneValor and SameText(P.TipoValor, 'LISTA') then
        begin
          TieneValor := False;
          for Opcion in Servicios.Lectura.ListarOpciones(P.Codigo) do
            TieneValor := TieneValor or (Opcion.IdValor = P.IdValor);
        end;
        if P.EsRequerido and (not TieneValor) then
          AIncidencias.Add(Format(SErrorPropiedadObligatoriaSesion,
            [Q.Fields[0].AsInteger, P.Nombre]));
      end;
      Q.Next;
    end;
    Q.Close;
    Q.SQL.Text := 'SELECT MIN(L.LINEA_SESLIN) AS LINEA,' +
      ' P.CODIGO_PROP_SESLPROP AS PROPIEDAD' +
      ' FROM fza_compras_sesiones_lineas_props P' +
      ' JOIN fza_compras_sesiones_lineas L' +
      ' ON L.SERIE_SES_SESLIN=P.SERIE_SES_SESLPROP' +
      ' AND L.NUMERO_SES_SESLIN=P.NUMERO_SES_SESLPROP' +
      ' AND L.LINEA_SESLIN=P.LINEA_SES_SESLPROP' +
      ' WHERE L.SERIE_SES_SESLIN=:SERIE AND L.NUMERO_SES_SESLIN=:NUMERO' +
      ' AND COALESCE(' + SQL_DESTINO + ', '''') <> ''''' +
      ' GROUP BY ' + SQL_DESTINO + ', P.CODIGO_PROP_SESLPROP' +
      ' HAVING COUNT(DISTINCT CONCAT(COALESCE(P.ID_PV_SESLPROP, ''''),' +
      ' CHAR(31),COALESCE(P.VALOR_LIBRE_SESLPROP, ''''))) > 1';
    Q.ParamByName('SERIE').AsString := ASerie;
    Q.ParamByName('NUMERO').AsString := ANumero;
    Q.Open;
    while not Q.Eof do
    begin
      AIncidencias.Add(Format(SErrorPropiedadesArticuloSesionDiferentes,
        [Q.FieldByName('LINEA').AsInteger,
         Q.FieldByName('PROPIEDAD').AsString]));
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

procedure BorrarPropiedadesLineaSesion(AConexion: TUniConnection;
  const ASerie, ANumero: string; ALinea: Integer);
var
  Q: TUniQuery;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConexion;
    Q.SQL.Text := 'DELETE FROM fza_compras_sesiones_lineas_props' +
      ' WHERE SERIE_SES_SESLPROP=:SERIE AND NUMERO_SES_SESLPROP=:NUMERO' +
      ' AND LINEA_SES_SESLPROP=:LINEA';
    Q.ParamByName('SERIE').AsString := ASerie;
    Q.ParamByName('NUMERO').AsString := ANumero;
    Q.ParamByName('LINEA').AsInteger := ALinea;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

procedure MaterializarPropiedadesLineaSesion(AConexion: TUniConnection;
  const ASerie, ANumero: string; ALinea: Integer;
  const AArticulo, AUsuario: string);
var
  Servicios, Articulo: TServiciosPropiedadesArticulo;
  P: TDefinicionPropiedadArticulo;
begin
  Servicios := CrearServiciosPropiedadesSesion(AConexion,
    ASerie, ANumero, ALinea);
  Articulo := CrearServiciosPropiedadesArticuloUniDAC(AConexion);
  for P in Servicios.Lectura.ListarAsignadas('') do
    if PropiedadInformada(P) then
      Articulo.Escritura.GuardarValor(AArticulo, P.Codigo, '',
        P.IdValor, P.ValorLibre, AUsuario)
    else
      Articulo.Escritura.EliminarValorUnidad(
        AArticulo, P.Codigo, '', AUsuario);
end;

function TemporadaPropiedadesLineaSesion(AConexion: TUniConnection;
  const ASerie, ANumero: string; ALinea, ADefecto: Integer): Integer;
var
  Servicios: TServiciosPropiedadesArticulo;
  P: TDefinicionPropiedadArticulo;
begin
  Result := ADefecto;
  Servicios := CrearServiciosPropiedadesSesion(AConexion,
    ASerie, ANumero, ALinea);
  for P in Servicios.Lectura.ListarAsignadas('') do
    if SameText(P.Codigo, 'TEMPORADA') then
      Result := P.IdValor;
end;

end.
