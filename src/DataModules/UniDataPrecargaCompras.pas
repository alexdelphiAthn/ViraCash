{******************************************************************************}
{  Módulo:       UniDataPrecargaCompras                                        }
{    Tipo:       Adaptador de persistencia                                     }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{  Descripción:  Acotado de cabeceras de compra por series, antes de su carga. }
{******************************************************************************}
unit UniDataPrecargaCompras;

interface

uses
  System.SysUtils,
  Uni,
  inLibDocumentoIntf,
  inLibPrecargaComprasIntf;

type
  EPrecargaComprasSqlNoAdmitido = class(Exception);
  EPrecargaComprasEnEdicion = class(Exception);

function CrearRepositorioPrecargaCompras(AConsulta: TUniQuery;
  const AConfiguracion: TConfiguracionDocumento;
  const ARestriccionUsuario: string): IRepositorioPrecargaCompras;

function CualificarRestriccionPrecargaCompras(AConsulta: TUniQuery;
  const AConfiguracion: TConfiguracionDocumento;
  const ARestriccion: string): string;

// Preparación sin Open: permite verificar el contrato SQL sin una conexión.
procedure PrepararConteoPrecargaCompras(AConsulta: TUniQuery;
  const AConfiguracion: TConfiguracionDocumento;
  const ARestriccionUsuario: string; const ASeries: TArray<string>);
procedure PrepararCatalogoPrecargaCompras(AConsulta: TUniQuery;
  const AConfiguracion: TConfiguracionDocumento;
  const ARestriccionUsuario: string);

implementation

uses
  System.Classes, System.StrUtils, System.RegularExpressions,
  System.Generics.Collections,
  Data.DB,
  DBAccess,
  inLibDocumento,
  inLibFiltroUsuario,
  inLibMsgCompras;

const
  ftotal = 'TOTAL_PRECARGA';
  fcodigo = 'CODIGO_SERIE';
  ffecha = 'ULTIMO_DOCUMENTO';
  PREFIJO_PARAMETRO_SERIE = 'PRECARGA_COMPRA_SERIE_';
  PATRON_TOKENS_SQL =
    '(?s)''(?:''''|\\.|[^''\\])*''|"(?:""|\\.|[^"\\])*"|' +
    '`(?:``|[^`])*`|/\*.*?\*/|--(?=[ \t\r\n]|$)[^\r\n]*|' +
    '#[^\r\n]*|:?[A-Za-z_][A-Za-z_0-9]*|[^\s]';
  // Gramática emitida por UniDataGuiasGridRepositorio.AplicarGuia.
  PATRON_INICIO_GUIA =
    '\ASELECT M_GUIA\.\*, EXT_GUIA\.[A-Za-z_0-9]+ AS [A-Za-z_0-9]+' +
    '(?:, EXT_GUIA\.[A-Za-z_0-9]+ AS [A-Za-z_0-9]+)* FROM \(';
  PATRON_FIN_GUIA =
    '\A\) M_GUIA LEFT JOIN [A-Za-z_0-9]+ EXT_GUIA ON ' +
    'EXT_GUIA\.[A-Za-z_0-9]+ = M_GUIA\.[A-Za-z_0-9]+' +
    '(?: AND EXT_GUIA\.[A-Za-z_0-9]+ = M_GUIA\.[A-Za-z_0-9]+)*';

type
  TMetadatosPrecargaCompra = record
    Tabla: string;
    Vista: string;
    Serie: string;
    Fecha: string;
    class function Crear(const AConfiguracion: TConfiguracionDocumento):
      TMetadatosPrecargaCompra; static;
  end;

  TClausulasPrecargaCompra = record
    Calificador: string;
    // TMatch.Index comienza en 1; estos límites son cantidades de texto.
    FinWhere: Integer;
    Corte: Integer;
  end;

  TEnvolturaGuiaPrecarga = record
    Inicio: string;
    Nucleo: string;
    Fin: string;
  end;

  TRepositorioPrecargaComprasUniDAC = class(TInterfacedObject,
    IRepositorioPrecargaCompras)
  private
    FConsulta: TUniQuery;
    FConfiguracion: TConfiguracionDocumento;
    FRestriccionUsuario: string;
    FSqlOriginal: string;
    FSqlAplicado: string;
    FParametrosOriginales: TDAParams;
    FTieneFiltro: Boolean;
    function CrearConsultaAuxiliar: TUniQuery;
    function SqlOriginalVigente: string;
    function ReconocerSqlAplicado(const ASql: string; AEnGuia: Boolean;
      out AOriginal: string): Boolean;
    function RestaurarNucleoReconocido(const ASql: string;
      AEnGuia: Boolean): string;
    procedure CopiarParametrosOriginales(ADestino: TDAParams);
    procedure GuardarOriginal(const ASql: string; AParametros: TDAParams);
    procedure SustituirConsulta(const ASql: string; AParametros: TDAParams);
  public
    constructor Create(AConsulta: TUniQuery;
      const AConfiguracion: TConfiguracionDocumento;
      const ARestriccionUsuario: string);
    destructor Destroy; override;
    function ContarHastaUmbral(const ASeries: TArray<string>): Integer;
    function ListarSeries: TSeriesPrecargaCompra;
    procedure AplicarSeries(const ASeries: TArray<string>);
    procedure QuitarFiltro;
  end;

class function TMetadatosPrecargaCompra.Crear(
  const AConfiguracion: TConfiguracionDocumento):
  TMetadatosPrecargaCompra;
var
  oEsperada: TConfiguracionDocumento;
begin
  if (AConfiguracion.Sentido <> sdCompra) or
     not (AConfiguracion.TipoDocumento in [tdPedido, tdAlbaran]) then
    raise EArgumentException.Create(SErrorDocumentoPrecargaNoAdmitido);
  oEsperada := CrearConfiguracionDocumento(
    AConfiguracion.TipoDocumento, sdCompra);
  if not SameText(AConfiguracion.TablaCabecera,
       oEsperada.TablaCabecera) or
     not SameText(AConfiguracion.CampoSerieCabecera,
       oEsperada.CampoSerieCabecera) or
     not SameText(AConfiguracion.PrefijoCabecera,
       oEsperada.PrefijoCabecera) then
    raise EArgumentException.Create(SErrorDocumentoPrecargaNoAdmitido);
  Result.Tabla := oEsperada.TablaCabecera;
  Result.Vista := 'vi_' + Copy(Result.Tabla, 5, MaxInt);
  Result.Serie := oEsperada.CampoSerieCabecera;
  Result.Fecha := 'FECHA_' + oEsperada.PrefijoCabecera;
end;

procedure ExigirConsultaSinEdicion(AConsulta: TUniQuery);
begin
  if not Assigned(AConsulta) then
    raise EArgumentNilException.Create('AConsulta');
  if AConsulta.State in dsEditModes then
    raise EPrecargaComprasEnEdicion.Create(SErrorPrecargaDuranteEdicion);
end;

procedure ExigirConsultaAuxiliarCerrada(AConsulta: TUniQuery);
begin
  ExigirConsultaSinEdicion(AConsulta);
  if AConsulta.Active then
    raise EDatabaseError.Create(SErrorConsultaAuxiliarActiva);
end;

function EsTextoIgnorable(const AToken: string): Boolean;
begin
  Result := CharInSet(AToken[1], ['''', '"', '#']) or
    StartsStr('--', AToken) or StartsStr('/*', AToken);
  if CharInSet(AToken[1], ['''', '"', '`']) and
     (Length(AToken) < 2) then
    raise EPrecargaComprasSqlNoAdmitido.Create(SErrorSqlPrecargaNoAdmitido);
  // Los comentarios ejecutables de MariaDB no son comentarios de perfil.
  if StartsStr('/*!', AToken) or StartsText('/*M!', AToken) then
    raise EPrecargaComprasSqlNoAdmitido.Create(SErrorSqlPrecargaNoAdmitido);
end;

function TokensSuperiores(const ASql: string): TArray<TMatch>;
var
  oTokens: TList<TMatch>;
  oToken: TMatch;
  iNivel: Integer;
begin
  oTokens := TList<TMatch>.Create;
  try
    iNivel := 0;
    for oToken in TRegEx.Matches(ASql, PATRON_TOKENS_SQL) do
    begin
      if (oToken.Value = '/') and
         (Copy(ASql, oToken.Index, 2) = '/*') then
        raise EPrecargaComprasSqlNoAdmitido.Create(
          SErrorSqlPrecargaNoAdmitido);
      if not EsTextoIgnorable(oToken.Value) then
      begin
        if oToken.Value = ')' then
          Dec(iNivel);
        if iNivel < 0 then
          raise EPrecargaComprasSqlNoAdmitido.Create(
            SErrorSqlPrecargaNoAdmitido);
        if iNivel = 0 then
          oTokens.Add(oToken);
        if oToken.Value = '(' then
          Inc(iNivel);
      end;
    end;
    if iNivel <> 0 then
      raise EPrecargaComprasSqlNoAdmitido.Create(
        SErrorSqlPrecargaNoAdmitido);
    Result := oTokens.ToArray;
  finally
    FreeAndNil(oTokens);
  end;
end;

function Identificador(const AToken: string): string;
begin
  Result := AToken;
  if StartsStr('`', Result) and EndsStr('`', Result) then
    Result := Copy(Result, 2, Length(Result) - 2);
  if not TRegEx.IsMatch(Result, '^[A-Za-z_][A-Za-z_0-9]*$') then
    raise EPrecargaComprasSqlNoAdmitido.Create(
      SErrorSqlPrecargaNoAdmitido);
end;

function EsFinOrigen(const AToken: string): Boolean;
begin
  Result := MatchText(AToken, ['WHERE', 'INNER', 'LEFT', 'RIGHT',
    'FULL', 'CROSS', 'NATURAL', 'JOIN', 'STRAIGHT_JOIN', 'ON', 'USING',
    'GROUP', 'HAVING', 'ORDER', 'LIMIT', ';', ',']);
end;

function LeerCalificador(const ATokens: TArray<TMatch>; AFrom: Integer;
  const AMetadatos: TMetadatosPrecargaCompra): string;
var
  sOrigen: string;
  iAlias: Integer;
begin
  if AFrom + 1 >= Length(ATokens) then
    raise EPrecargaComprasSqlNoAdmitido.Create(
      SErrorSqlPrecargaNoAdmitido);
  sOrigen := Identificador(ATokens[AFrom + 1].Value);
  if not SameText(sOrigen, AMetadatos.Vista) and
     not SameText(sOrigen, AMetadatos.Tabla) then
    raise EPrecargaComprasSqlNoAdmitido.Create(
      SErrorSqlPrecargaNoAdmitido);
  Result := ATokens[AFrom + 1].Value;
  iAlias := AFrom + 2;
  if (iAlias < Length(ATokens)) and
     SameText(ATokens[iAlias].Value, 'AS') then
  begin
    Inc(iAlias);
    if (iAlias >= Length(ATokens)) or
       EsFinOrigen(ATokens[iAlias].Value) then
      raise EPrecargaComprasSqlNoAdmitido.Create(
        SErrorSqlPrecargaNoAdmitido);
  end;
  if (iAlias < Length(ATokens)) and
     not EsFinOrigen(ATokens[iAlias].Value) then
  begin
    Identificador(ATokens[iAlias].Value);
    Result := ATokens[iAlias].Value;
  end;
end;

procedure ExigirOrigenUnico(const ATokens: TArray<TMatch>;
  AFrom: Integer);
var
  iIndice: Integer;
  sOrigen: string;
begin
  sOrigen := Identificador(ATokens[AFrom + 1].Value);
  for iIndice := AFrom + 2 to High(ATokens) - 1 do
    if MatchText(ATokens[iIndice].Value, ['FROM', 'JOIN', 'STRAIGHT_JOIN'])
       and SameText(Identificador(ATokens[iIndice + 1].Value), sOrigen) then
      raise EPrecargaComprasSqlNoAdmitido.Create(
        SErrorSqlPrecargaNoAdmitido);
end;

function LeerClausulas(const ASql: string;
  const AMetadatos: TMetadatosPrecargaCompra): TClausulasPrecargaCompra;
var
  aTokens: TArray<TMatch>;
  iFrom: Integer;
  iIndice: Integer;
  sToken: string;
begin
  Result := Default(TClausulasPrecargaCompra);
  Result.Corte := Length(ASql);
  aTokens := TokensSuperiores(ASql);
  if (Length(aTokens) = 0) or
     not SameText(aTokens[0].Value, 'SELECT') then
    raise EPrecargaComprasSqlNoAdmitido.Create(
      SErrorSqlPrecargaNoAdmitido);
  iFrom := -1;
  for iIndice := 1 to High(aTokens) do
  begin
    sToken := UpperCase(aTokens[iIndice].Value);
    if MatchText(sToken, ['UNION', 'INTERSECT', 'EXCEPT', 'INTO',
         'PROCEDURE', 'FOR', 'LOCK', 'WINDOW']) or
       ((sToken = ';') and (iIndice < High(aTokens))) then
      raise EPrecargaComprasSqlNoAdmitido.Create(
        SErrorSqlPrecargaNoAdmitido);
    if (sToken = 'FROM') and (iFrom < 0) then
      iFrom := iIndice;
    if (sToken = 'WHERE') and (iFrom >= 0) then
      Result.FinWhere := aTokens[iIndice].Index +
        aTokens[iIndice].Length - 1;
    if (iFrom >= 0) and MatchText(sToken,
         ['GROUP', 'HAVING', 'ORDER', 'LIMIT', ';']) and
       (aTokens[iIndice].Index - 1 < Result.Corte) then
      Result.Corte := aTokens[iIndice].Index - 1;
  end;
  if iFrom < 0 then
    raise EPrecargaComprasSqlNoAdmitido.Create(
      SErrorSqlPrecargaNoAdmitido);
  Result.Calificador := LeerCalificador(aTokens, iFrom, AMetadatos);
  ExigirOrigenUnico(aTokens, iFrom);
end;

function CualificarCamposRestriccion(const ARestriccion,
  ACalificador, ASufijo: string): string;
var
  oToken: TMatch;
  iDesde: Integer;
  sAnterior: string;
begin
  Result := '';
  iDesde := 1;
  sAnterior := '';
  for oToken in TRegEx.Matches(ARestriccion, PATRON_TOKENS_SQL) do
  begin
    Result := Result + Copy(ARestriccion, iDesde,
      oToken.Index - iDesde);
    if (sAnterior <> '.') and MatchText(oToken.Value,
         ['CODIGO_EMP_' + ASufijo, 'CODIGO_ALM_' + ASufijo]) then
      Result := Result + ACalificador + '.';
    Result := Result + oToken.Value;
    iDesde := oToken.Index + oToken.Length;
    if not EsTextoIgnorable(oToken.Value) then
      sAnterior := oToken.Value;
  end;
  Result := Result + Copy(ARestriccion, iDesde, MaxInt);
end;

function NormalizarSqlGuia(const ASql: string): string;
begin
  Result := TrimRight(ASql);
  while (Result <> '') and (Result[Length(Result)] = ';') do
    Result := TrimRight(Copy(Result, 1, Length(Result) - 1));
end;

function CoincideSqlPrecarga(const AActual, AEsperado: string;
  AEnGuia: Boolean): Boolean;
begin
  if AEnGuia then
    Result := NormalizarSqlGuia(AActual) = NormalizarSqlGuia(AEsperado)
  else
    Result := TrimRight(AActual) = TrimRight(AEsperado);
end;

function FinGuiaReconocido(const AFin, ASufijo,
  ARestriccion: string): Boolean;
var
  oUnion: TMatch;
  sResto: string;
  sCualificada: string;
begin
  oUnion := TRegEx.Match(AFin, PATRON_FIN_GUIA);
  Result := oUnion.Success;
  if Result then
  begin
    sResto := TrimRight(Copy(AFin, oUnion.Length + 1, MaxInt));
    sCualificada := CualificarCamposRestriccion(
      ARestriccion, 'M_GUIA', ASufijo);
    Result := (sResto = '') or ((ARestriccion <> '') and
      ((sResto = ' WHERE 1 = 1' + ARestriccion) or
       (sResto = ' WHERE 1 = 1' + sCualificada)));
  end;
end;

function SepararGuiaReconocida(const ASql, ASufijo,
  ARestriccion: string; out AGuia: TEnvolturaGuiaPrecarga): Boolean;
var
  oInicio: TMatch;
  oToken: TMatch;
  iCierre: Integer;
  sFin: string;
begin
  Result := False;
  AGuia := Default(TEnvolturaGuiaPrecarga);
  oInicio := TRegEx.Match(ASql, PATRON_INICIO_GUIA);
  if oInicio.Success then
  begin
    iCierre := 0;
    for oToken in TokensSuperiores(ASql) do
      if (oToken.Value = ')') and (iCierre = 0) then
        iCierre := oToken.Index;
    if iCierre > oInicio.Length + 1 then
    begin
      sFin := Copy(ASql, iCierre, MaxInt);
      if FinGuiaReconocido(sFin, ASufijo, ARestriccion) then
      begin
        AGuia.Inicio := Copy(ASql, 1, oInicio.Length);
        AGuia.Nucleo := Copy(ASql, oInicio.Length + 1,
          iCierre - oInicio.Length - 1);
        AGuia.Fin := sFin;
        Result := True;
      end;
    end;
  end;
end;

function CualificarRestriccionSql(const ASql: string;
  const AConfiguracion: TConfiguracionDocumento;
  const ARestriccion: string): string;
var
  oMetadatos: TMetadatosPrecargaCompra;
  oClausulas: TClausulasPrecargaCompra;
  oGuia: TEnvolturaGuiaPrecarga;
begin
  Result := ARestriccion;
  if ARestriccion <> '' then
  begin
    oMetadatos := TMetadatosPrecargaCompra.Crear(AConfiguracion);
    try
      if SepararGuiaReconocida(ASql, AConfiguracion.PrefijoCabecera,
           ARestriccion, oGuia) then
        oClausulas.Calificador := 'M_GUIA'
      else
        oClausulas := LeerClausulas(ASql, oMetadatos);
      Result := CualificarCamposRestriccion(ARestriccion,
        oClausulas.Calificador, AConfiguracion.PrefijoCabecera);
    except
      on E: EPrecargaComprasSqlNoAdmitido do
        // Un sub_busqueda u otro perfil conserva todos sus permisos.
        Result := ARestriccion;
    end;
  end;
end;

function CualificarRestriccionPrecargaCompras(AConsulta: TUniQuery;
  const AConfiguracion: TConfiguracionDocumento;
  const ARestriccion: string): string;
begin
  if not Assigned(AConsulta) then
    raise EArgumentNilException.Create('AConsulta');
  Result := CualificarRestriccionSql(AConsulta.SQL.Text,
    AConfiguracion, ARestriccion);
end;

function PredicadoSeries(const ACampo, APrefijo: string;
  ACantidad: Integer): string;
var
  iIndice: Integer;
begin
  Result := '';
  if ACantidad > 0 then
  begin
    Result := ACampo + ' IN (';
    for iIndice := 0 to ACantidad - 1 do
    begin
      if iIndice > 0 then
        Result := Result + ', ';
      Result := Result + ':' + APrefijo + IntToStr(iIndice);
    end;
    Result := Result + ')';
  end;
end;

procedure AsignarSeries(AParametros: TDAParams;
  const APrefijo: string; const ASeries: TArray<string>);
var
  iIndice: Integer;
  oParametro: TDAParam;
begin
  for iIndice := 0 to High(ASeries) do
  begin
    oParametro := AParametros.FindParam(APrefijo + IntToStr(iIndice));
    if not Assigned(oParametro) then
      oParametro := AParametros.CreateParam(ftWideString,
        APrefijo + IntToStr(iIndice), ptInput);
    oParametro.AsWideString := ASeries[iIndice];
    oParametro.Size := Length(ASeries[iIndice]);
  end;
end;

function SqlConSeries(const ASql: string;
  const AClausulas: TClausulasPrecargaCompra;
  const AMetadatos: TMetadatosPrecargaCompra;
  const APrefijo: string; ACantidad: Integer): string;
var
  sPredicado: string;
begin
  sPredicado := PredicadoSeries(
    AClausulas.Calificador + '.' + AMetadatos.Serie,
    APrefijo, ACantidad);
  if AClausulas.FinWhere > 0 then
    Result := Copy(ASql, 1, AClausulas.FinWhere) + sLineBreak +
      '(' + Copy(ASql, AClausulas.FinWhere + 1,
        AClausulas.Corte - AClausulas.FinWhere) + sLineBreak +
      ') AND ' + sPredicado
  else
    Result := Copy(ASql, 1, AClausulas.Corte) + sLineBreak +
      ' WHERE ' + sPredicado;
  Result := Result + sLineBreak + Copy(ASql, AClausulas.Corte + 1,
    MaxInt);
end;

function SqlConSeriesYGuias(const ASql: string;
  const AMetadatos: TMetadatosPrecargaCompra;
  const ASufijo, ARestriccion, APrefijo: string;
  ACantidad: Integer): string;
var
  oGuia: TEnvolturaGuiaPrecarga;
  oClausulas: TClausulasPrecargaCompra;
begin
  if SepararGuiaReconocida(ASql, ASufijo, ARestriccion, oGuia) then
    Result := oGuia.Inicio + NormalizarSqlGuia(SqlConSeriesYGuias(
      oGuia.Nucleo, AMetadatos, ASufijo, ARestriccion,
      APrefijo, ACantidad)) + oGuia.Fin
  else
  begin
    oClausulas := LeerClausulas(ASql, AMetadatos);
    Result := SqlConSeries(ASql, oClausulas, AMetadatos,
      APrefijo, ACantidad);
  end;
end;

function PrefijoDisponible(AParametros: TDAParams): string;
var
  iIndice: Integer;
  bExiste: Boolean;
begin
  Result := PREFIJO_PARAMETRO_SERIE;
  repeat
    bExiste := False;
    for iIndice := 0 to AParametros.Count - 1 do
      bExiste := bExiste or StartsText(Result, AParametros[iIndice].Name);
    if bExiste then
      Result := Result + 'N_';
  until not bExiste;
end;

procedure PrepararConteoPrecargaCompras(AConsulta: TUniQuery;
  const AConfiguracion: TConfiguracionDocumento;
  const ARestriccionUsuario: string; const ASeries: TArray<string>);
var
  oMetadatos: TMetadatosPrecargaCompra;
  sFiltro: string;
begin
  ExigirConsultaAuxiliarCerrada(AConsulta);
  oMetadatos := TMetadatosPrecargaCompra.Crear(AConfiguracion);
  sFiltro := PredicadoSeries(oMetadatos.Serie,
    PREFIJO_PARAMETRO_SERIE, Length(ASeries));
  if sFiltro <> '' then
    sFiltro := ' AND ' + sFiltro;
  AConsulta.SQL.Text :=
    'SELECT COUNT(1) AS ' + ftotal + sLineBreak +
    '  FROM (SELECT 1 FROM ' + oMetadatos.Tabla + sLineBreak +
    '         WHERE 1 = 1' + ARestriccionUsuario + sFiltro + sLineBreak +
    '         LIMIT ' + IntToStr(UMBRAL_PRECARGA_COMPRAS + 1) +
    ') CABECERAS_PRECARGA';
  AsignarSeries(AConsulta.Params, PREFIJO_PARAMETRO_SERIE, ASeries);
end;

procedure PrepararCatalogoPrecargaCompras(AConsulta: TUniQuery;
  const AConfiguracion: TConfiguracionDocumento;
  const ARestriccionUsuario: string);
var
  oMetadatos: TMetadatosPrecargaCompra;
begin
  ExigirConsultaAuxiliarCerrada(AConsulta);
  oMetadatos := TMetadatosPrecargaCompra.Crear(AConfiguracion);
  AConsulta.SQL.Text :=
    'SELECT ' + oMetadatos.Serie + ' AS ' + fcodigo + ',' + sLineBreak +
    '       MAX(' + oMetadatos.Fecha + ') AS ' + ffecha + sLineBreak +
    '  FROM ' + oMetadatos.Tabla + sLineBreak +
    ' WHERE 1 = 1' + ARestriccionUsuario + sLineBreak +
    ' GROUP BY ' + oMetadatos.Serie + sLineBreak +
    ' ORDER BY ' + ffecha + ' DESC, ' + fcodigo + ' DESC';
end;

constructor TRepositorioPrecargaComprasUniDAC.Create(AConsulta: TUniQuery;
  const AConfiguracion: TConfiguracionDocumento;
  const ARestriccionUsuario: string);
begin
  inherited Create;
  if not Assigned(AConsulta) then
    raise EArgumentNilException.Create('AConsulta');
  TMetadatosPrecargaCompra.Crear(AConfiguracion);
  FConsulta := AConsulta;
  FConfiguracion := AConfiguracion;
  FRestriccionUsuario := ARestriccionUsuario;
  FParametrosOriginales := TDAParams.Create(nil);
end;

destructor TRepositorioPrecargaComprasUniDAC.Destroy;
begin
  FreeAndNil(FParametrosOriginales);
  inherited;
end;

function TRepositorioPrecargaComprasUniDAC.CrearConsultaAuxiliar: TUniQuery;
begin
  if not Assigned(FConsulta.Connection) then
    raise EArgumentNilException.Create('AConsulta.Connection');
  Result := TUniQuery.Create(nil);
  Result.Connection := FConsulta.Connection;
end;

function TRepositorioPrecargaComprasUniDAC.ContarHastaUmbral(
  const ASeries: TArray<string>): Integer;
var
  oConsulta: TUniQuery;
begin
  oConsulta := CrearConsultaAuxiliar;
  try
    PrepararConteoPrecargaCompras(oConsulta, FConfiguracion,
      FRestriccionUsuario, ASeries);
    oConsulta.Open;
    Result := oConsulta.FieldByName(ftotal).AsInteger;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioPrecargaComprasUniDAC.ListarSeries:
  TSeriesPrecargaCompra;
var
  oConsulta: TUniQuery;
  oSeries: TList<TSeriePrecargaCompra>;
  oSerie: TSeriePrecargaCompra;
begin
  oConsulta := CrearConsultaAuxiliar;
  try
    PrepararCatalogoPrecargaCompras(oConsulta, FConfiguracion,
      FRestriccionUsuario);
    oConsulta.Open;
    oSeries := TList<TSeriePrecargaCompra>.Create;
    try
      while not oConsulta.Eof do
      begin
        oSerie.Codigo := oConsulta.FieldByName(fcodigo).AsString;
        oSerie.UltimoDocumento := oConsulta.FieldByName(ffecha).AsDateTime;
        oSeries.Add(oSerie);
        oConsulta.Next;
      end;
      Result := oSeries.ToArray;
    finally
      FreeAndNil(oSeries);
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioPrecargaComprasUniDAC.ReconocerSqlAplicado(
  const ASql: string; AEnGuia: Boolean;
  out AOriginal: string): Boolean;
var
  sConRestriccion: string;
  sRestriccion: string;
begin
  Result := CoincideSqlPrecarga(ASql, FSqlAplicado, AEnGuia);
  if Result then
    AOriginal := FSqlOriginal
  else
  begin
    sRestriccion := CualificarRestriccionSql(FSqlAplicado,
      FConfiguracion, FRestriccionUsuario);
    sConRestriccion := InyectarFiltroSql(FSqlAplicado,
      sRestriccion);
    if not CoincideSqlPrecarga(ASql, sConRestriccion, AEnGuia) then
    begin
      sRestriccion := FRestriccionUsuario;
      sConRestriccion := InyectarFiltroSql(FSqlAplicado, sRestriccion);
    end;
    Result := CoincideSqlPrecarga(ASql, sConRestriccion, AEnGuia);
    // La base puede añadir permisos entre el filtro y el Open. Se conservan.
    if Result then
      AOriginal := InyectarFiltroSql(FSqlOriginal, sRestriccion);
  end;
end;

function TRepositorioPrecargaComprasUniDAC.RestaurarNucleoReconocido(
  const ASql: string; AEnGuia: Boolean): string;
var
  oGuia: TEnvolturaGuiaPrecarga;
begin
  if not ReconocerSqlAplicado(ASql, AEnGuia, Result) then
  begin
    if not SepararGuiaReconocida(ASql,
         FConfiguracion.PrefijoCabecera, FRestriccionUsuario, oGuia) then
      raise EPrecargaComprasSqlNoAdmitido.Create(
        SErrorSqlPrecargaModificado);
    // Solo el núcleo exacto registrado puede perder nuestra selección.
    Result := oGuia.Inicio + NormalizarSqlGuia(
      RestaurarNucleoReconocido(oGuia.Nucleo, True)) + oGuia.Fin;
  end;
end;

function TRepositorioPrecargaComprasUniDAC.SqlOriginalVigente: string;
begin
  if FTieneFiltro then
    Result := RestaurarNucleoReconocido(FConsulta.SQL.Text, False)
  else
    Result := FConsulta.SQL.Text;
end;

procedure TRepositorioPrecargaComprasUniDAC.CopiarParametrosOriginales(
  ADestino: TDAParams);
var
  iIndice: Integer;
  oActual: TParam;
begin
  if not FTieneFiltro then
    ADestino.Assign(FConsulta.Params)
  else
  begin
    ADestino.Assign(FParametrosOriginales);
    for iIndice := 0 to ADestino.Count - 1 do
    begin
      oActual := FConsulta.Params.FindParam(ADestino[iIndice].Name);
      if Assigned(oActual) then
        ADestino[iIndice].Assign(oActual);
    end;
  end;
end;

procedure TRepositorioPrecargaComprasUniDAC.GuardarOriginal(
  const ASql: string; AParametros: TDAParams);
begin
  FSqlOriginal := ASql;
  FParametrosOriginales.Assign(AParametros);
end;

procedure TRepositorioPrecargaComprasUniDAC.SustituirConsulta(
  const ASql: string; AParametros: TDAParams);
begin
  ExigirConsultaSinEdicion(FConsulta);
  if FConsulta.Active then
    FConsulta.Close;
  FConsulta.SQL.Text := ASql;
  FConsulta.Params.Assign(AParametros);
end;

procedure TRepositorioPrecargaComprasUniDAC.AplicarSeries(
  const ASeries: TArray<string>);
var
  oMetadatos: TMetadatosPrecargaCompra;
  oParametros: TDAParams;
  sOriginal: string;
  sFiltrado: string;
  sPrefijo: string;
begin
  if Length(ASeries) = 0 then
    QuitarFiltro
  else
  begin
    ExigirConsultaSinEdicion(FConsulta);
    sOriginal := SqlOriginalVigente;
    oMetadatos := TMetadatosPrecargaCompra.Crear(FConfiguracion);
    oParametros := TDAParams.Create(nil);
    try
      CopiarParametrosOriginales(oParametros);
      sPrefijo := PrefijoDisponible(oParametros);
      sFiltrado := SqlConSeriesYGuias(sOriginal, oMetadatos,
        FConfiguracion.PrefijoCabecera, FRestriccionUsuario,
        sPrefijo, Length(ASeries));
      GuardarOriginal(sOriginal, oParametros);
      AsignarSeries(oParametros, sPrefijo, ASeries);
      SustituirConsulta(sFiltrado, oParametros);
      FSqlAplicado := FConsulta.SQL.Text;
      FTieneFiltro := True;
    finally
      FreeAndNil(oParametros);
    end;
  end;
end;

procedure TRepositorioPrecargaComprasUniDAC.QuitarFiltro;
var
  oParametros: TDAParams;
  sOriginal: string;
begin
  if FTieneFiltro then
  begin
    ExigirConsultaSinEdicion(FConsulta);
    sOriginal := SqlOriginalVigente;
    oParametros := TDAParams.Create(nil);
    try
      CopiarParametrosOriginales(oParametros);
      SustituirConsulta(sOriginal, oParametros);
      FTieneFiltro := False;
      FSqlAplicado := '';
      FSqlOriginal := '';
      FParametrosOriginales.Clear;
    finally
      FreeAndNil(oParametros);
    end;
  end;
end;

function CrearRepositorioPrecargaCompras(AConsulta: TUniQuery;
  const AConfiguracion: TConfiguracionDocumento;
  const ARestriccionUsuario: string): IRepositorioPrecargaCompras;
begin
  Result := TRepositorioPrecargaComprasUniDAC.Create(AConsulta,
    AConfiguracion, ARestriccionUsuario);
end;

end.
