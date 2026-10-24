{******************************************************************************}
{                                                                              }
{  Modulo:       inLibProteccionDatosFacturacion                               }
{    Tipo:       Libreria de dominio                                           }
{ Version:       1.0.0                                                         }
{   Fecha:       24/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Proteccion comun frente a modificaciones SQL directas de las tablas de    }
{    facturacion. No depende de VCL, UniDAC ni del modo VERI*FACTU activo.     }
{******************************************************************************}
unit inLibProteccionDatosFacturacion;

interface

uses
  System.SysUtils;

type
  EModificacionTablaFacturacionProtegida = class(Exception)
  private
    FOperacion: string;
    FTabla: string;
  public
    constructor Create(const AOperacion, ATabla: string);
    property Operacion: string read FOperacion;
    property Tabla: string read FTabla;
  end;

resourcestring
  SErrorModificacionTablaFacturacionProtegida =
    'Operación %s bloqueada sobre %s.' + sLineBreak + sLineBreak +
    'El artículo 29.2.j de la Ley 58/2003, General Tributaria, y el ' +
    'artículo 8 del Real Decreto 1007/2023 exigen que los sistemas de ' +
    'facturación garanticen la integridad, conservación, accesibilidad, ' +
    'legibilidad, trazabilidad e inalterabilidad de los registros de ' +
    'facturación. Los artículos 6 y 7 de la Orden HAC/1177/2024 ' +
    'desarrollan estos requisitos.' + sLineBreak + sLineBreak +
    'Esta protección se aplica con independencia del modo VERI*FACTU o ' +
    'NO VERI*FACTU configurado. Las rectificaciones y anulaciones deben ' +
    'realizarse mediante los procedimientos de la aplicación, conservando ' +
    'el registro original y generando el registro posterior que corresponda.';

function EsTablaFacturacionProtegida(
  const ANombreTabla: string): Boolean;
function SqlReferenciaTablaFacturacionProtegida(
  const ASql: string): Boolean; overload;
function SqlReferenciaTablaFacturacionProtegida(
  const ASql: string;
  out ATabla: string): Boolean; overload;
function DetectarModificacionTablaFacturacion(
  const ASql: string;
  out AOperacion, ATabla: string): Boolean;
procedure ValidarSqlSinModificacionesFacturacion(const ASql: string);

implementation

uses
  System.Classes,
  System.Generics.Collections,
  System.StrUtils;

const
  NOMBRE_TABLA_FACTURAS = 'fza_facturas';
  NOMBRE_TABLA_FACTURAS_LINEAS = 'fza_facturas_lineas';

type
  TTipoTokenSql = (
    ttsIdentificador,
    ttsSimbolo
  );

  TTokenSql = record
    Tipo: TTipoTokenSql;
    Texto: string;
  end;

  TTokensSql = TArray<TTokenSql>;

function EsInicioIdentificador(const ACaracter: Char): Boolean;
begin
  Result := CharInSet(ACaracter, ['A'..'Z', 'a'..'z', '_', '$']) or
    (Ord(ACaracter) > 127);
end;

function EsCaracterIdentificador(const ACaracter: Char): Boolean;
begin
  Result := EsInicioIdentificador(ACaracter) or
    CharInSet(ACaracter, ['0'..'9']);
end;

function EsCaracterEtiquetaDollar(const ACaracter: Char): Boolean;
begin
  Result := CharInSet(
    ACaracter,
    ['A'..'Z', 'a'..'z', '0'..'9', '_']);
end;

procedure AgregarToken(
  ALista: TList<TTokenSql>;
  ATipo: TTipoTokenSql;
  const ATexto: string);
var
  oToken: TTokenSql;
begin
  oToken.Tipo := ATipo;
  oToken.Texto := ATexto;
  ALista.Add(oToken);
end;

procedure SaltarCadenaSimple(const ASql: string; var APosicion: Integer);
var
  bTerminada: Boolean;
  cDelimitador: Char;
begin
  cDelimitador := ASql[APosicion];
  Inc(APosicion);
  bTerminada := False;
  while (APosicion <= Length(ASql)) and not bTerminada do
  begin
    if ASql[APosicion] = '\' then
      Inc(APosicion, 2)
    else if ASql[APosicion] = cDelimitador then
    begin
      if (APosicion < Length(ASql)) and
         (ASql[APosicion + 1] = cDelimitador) then
        Inc(APosicion, 2)
      else
      begin
        Inc(APosicion);
        bTerminada := True;
      end;
    end
    else
      Inc(APosicion);
  end;
end;

function LeerIdentificadorDelimitado(
  const ASql: string;
  var APosicion: Integer;
  ACierre: Char): string;
var
  bTerminado: Boolean;
  cApertura: Char;
begin
  Result := '';
  cApertura := ASql[APosicion];
  Inc(APosicion);
  bTerminado := False;
  while (APosicion <= Length(ASql)) and not bTerminado do
  begin
    if ASql[APosicion] = ACierre then
    begin
      if (APosicion < Length(ASql)) and
         (ASql[APosicion + 1] = ACierre) and
         (cApertura <> '[') then
      begin
        Result := Result + ACierre;
        Inc(APosicion, 2);
      end
      else
      begin
        Inc(APosicion);
        bTerminado := True;
      end;
    end
    else
    begin
      Result := Result + ASql[APosicion];
      Inc(APosicion);
    end;
  end;
end;

procedure SaltarComentarioBloque(const ASql: string; var APosicion: Integer);
var
  iNivel: Integer;
begin
  iNivel := 1;
  Inc(APosicion, 2);
  while (APosicion <= Length(ASql)) and (iNivel > 0) do
  begin
    if (APosicion < Length(ASql)) and
       (ASql[APosicion] = '/') and
       (ASql[APosicion + 1] = '*') then
    begin
      Inc(iNivel);
      Inc(APosicion, 2);
    end
    else if (APosicion < Length(ASql)) and
            (ASql[APosicion] = '*') and
            (ASql[APosicion + 1] = '/') then
    begin
      Dec(iNivel);
      Inc(APosicion, 2);
    end
    else
      Inc(APosicion);
  end;
end;

procedure SaltarComentarioLinea(const ASql: string; var APosicion: Integer);
begin
  while (APosicion <= Length(ASql)) and
        not CharInSet(ASql[APosicion], [#10, #13]) do
    Inc(APosicion);
end;

function EsComentarioLineaGuiones(
  const ASql: string;
  APosicion: Integer): Boolean;
begin
  Result := (APosicion < Length(ASql)) and
    (ASql[APosicion] = '-') and
    (ASql[APosicion + 1] = '-') and
    ((APosicion + 1 = Length(ASql)) or
     (Ord(ASql[APosicion + 2]) <= 32));
end;

function EsComentarioEjecutableMySql(
  const ASql: string;
  APosicion: Integer;
  out AInicioContenido: Integer): Boolean;
begin
  AInicioContenido := 0;
  Result := (APosicion + 2 <= Length(ASql)) and
    (ASql[APosicion] = '/') and
    (ASql[APosicion + 1] = '*') and
    (ASql[APosicion + 2] = '!');
  if Result then
    AInicioContenido := APosicion + 3;
  if not Result then
  begin
    Result := (APosicion + 3 <= Length(ASql)) and
      (ASql[APosicion] = '/') and
      (ASql[APosicion + 1] = '*') and
      (UpCase(ASql[APosicion + 2]) = 'M') and
      (ASql[APosicion + 3] = '!');
    if Result then
      AInicioContenido := APosicion + 4;
  end;
end;

function ExtraerComentarioEjecutableMySql(
  const ASql: string;
  var APosicion: Integer;
  AInicioContenido: Integer): string;
var
  iFin: Integer;
  iInicioSql: Integer;
begin
  iFin := PosEx('*/', ASql, AInicioContenido);
  if iFin = 0 then
    iFin := Length(ASql) + 1;
  iInicioSql := AInicioContenido;
  while (iInicioSql < iFin) and
        (Ord(ASql[iInicioSql]) <= 32) do
    Inc(iInicioSql);
  while (iInicioSql < iFin) and
        CharInSet(ASql[iInicioSql], ['0'..'9']) do
    Inc(iInicioSql);
  while (iInicioSql < iFin) and
        (Ord(ASql[iInicioSql]) <= 32) do
    Inc(iInicioSql);
  Result := Copy(ASql, iInicioSql, iFin - iInicioSql);
  if iFin <= Length(ASql) then
    APosicion := iFin + 2
  else
    APosicion := iFin;
end;

function IntentarSaltarCadenaDollar(
  const ASql: string;
  var APosicion: Integer): Boolean;
var
  iCierre: Integer;
  iFinEtiqueta: Integer;
  sDelimitador: string;
begin
  Result := False;
  iFinEtiqueta := APosicion + 1;
  while (iFinEtiqueta <= Length(ASql)) and
        EsCaracterEtiquetaDollar(ASql[iFinEtiqueta]) do
    Inc(iFinEtiqueta);
  if (iFinEtiqueta <= Length(ASql)) and
     (ASql[iFinEtiqueta] = '$') then
  begin
    sDelimitador := Copy(
      ASql,
      APosicion,
      iFinEtiqueta - APosicion + 1);
    iCierre := PosEx(sDelimitador, ASql, iFinEtiqueta + 1);
    Result := iCierre > 0;
    if Result then
      APosicion := iCierre + Length(sDelimitador);
  end;
end;

function TokenizarSql(const ASql: string): TTokensSql;
var
  bDelimitadorDollarMySql: Boolean;
  iInicio: Integer;
  iInicioComentarioEjecutable: Integer;
  iPosicion: Integer;
  iToken: Integer;
  oTokens: TList<TTokenSql>;
  oTokensComentario: TTokensSql;
  sComentarioEjecutable: string;
  sIdentificador: string;
begin
  oTokens := TList<TTokenSql>.Create;
  try
    bDelimitadorDollarMySql := False;
    iPosicion := 1;
    while iPosicion <= Length(ASql) do
    begin
      if (ASql[iPosicion] = '$') and
         (oTokens.Count > 0) and
         (oTokens[oTokens.Count - 1].Tipo = ttsIdentificador) and
         SameText(oTokens[oTokens.Count - 1].Texto, 'DELIMITER') then
        bDelimitadorDollarMySql := True
      else if (ASql[iPosicion] = ';') and
              (oTokens.Count > 0) and
              (oTokens[oTokens.Count - 1].Tipo = ttsIdentificador) and
              SameText(oTokens[oTokens.Count - 1].Texto, 'DELIMITER') then
        bDelimitadorDollarMySql := False;
      if CharInSet(ASql[iPosicion], [#9, #10, #13, ' ']) then
        Inc(iPosicion)
      else if EsComentarioLineaGuiones(ASql, iPosicion) then
        SaltarComentarioLinea(ASql, iPosicion)
      else if ASql[iPosicion] = '#' then
        SaltarComentarioLinea(ASql, iPosicion)
      else if EsComentarioEjecutableMySql(
                ASql,
                iPosicion,
                iInicioComentarioEjecutable) then
      begin
        sComentarioEjecutable := ExtraerComentarioEjecutableMySql(
          ASql,
          iPosicion,
          iInicioComentarioEjecutable);
        oTokensComentario := TokenizarSql(sComentarioEjecutable);
        for iToken := 0 to Length(oTokensComentario) - 1 do
          oTokens.Add(oTokensComentario[iToken]);
      end
      else if (iPosicion < Length(ASql)) and
              (ASql[iPosicion] = '/') and
              (ASql[iPosicion + 1] = '*') then
        SaltarComentarioBloque(ASql, iPosicion)
      else if ASql[iPosicion] = '''' then
        SaltarCadenaSimple(ASql, iPosicion)
      else if (not bDelimitadorDollarMySql) and
              (ASql[iPosicion] = '$') and
              IntentarSaltarCadenaDollar(ASql, iPosicion) then
      begin
        // El cuerpo dollar-quoted es un literal de PostgreSQL.
      end
      else if ASql[iPosicion] = '`' then
      begin
        sIdentificador := LeerIdentificadorDelimitado(
          ASql,
          iPosicion,
          '`');
        AgregarToken(oTokens, ttsIdentificador, sIdentificador);
      end
      else if ASql[iPosicion] = '"' then
      begin
        // En SQL estandar y PostgreSQL las comillas dobles delimitan nombres.
        sIdentificador := LeerIdentificadorDelimitado(
          ASql,
          iPosicion,
          '"');
        AgregarToken(oTokens, ttsIdentificador, sIdentificador);
      end
      else if ASql[iPosicion] = '[' then
      begin
        sIdentificador := LeerIdentificadorDelimitado(
          ASql,
          iPosicion,
          ']');
        AgregarToken(oTokens, ttsIdentificador, sIdentificador);
      end
      else if EsInicioIdentificador(ASql[iPosicion]) then
      begin
        iInicio := iPosicion;
        Inc(iPosicion);
        while (iPosicion <= Length(ASql)) and
              EsCaracterIdentificador(ASql[iPosicion]) do
          Inc(iPosicion);
        AgregarToken(
          oTokens,
          ttsIdentificador,
          Copy(ASql, iInicio, iPosicion - iInicio));
      end
      else
      begin
        AgregarToken(oTokens, ttsSimbolo, ASql[iPosicion]);
        Inc(iPosicion);
      end;
    end;
    Result := oTokens.ToArray;
  finally
    oTokens.Free;
  end;
end;

function QuitarDelimitadoresIdentificador(const AValor: string): string;
begin
  Result := Trim(AValor);
  if Length(Result) >= 2 then
  begin
    if ((Result[1] = '`') and (Result[Length(Result)] = '`')) or
       ((Result[1] = '"') and (Result[Length(Result)] = '"')) or
       ((Result[1] = '[') and (Result[Length(Result)] = ']')) then
      Result := Copy(Result, 2, Length(Result) - 2);
  end;
end;

function NormalizarNombreTabla(const ANombreTabla: string): string;
var
  iPunto: Integer;
begin
  Result := Trim(ANombreTabla);
  while (Result <> '') and
        CharInSet(Result[Length(Result)], [',', ';']) do
    Delete(Result, Length(Result), 1);
  iPunto := LastDelimiter('.', Result);
  if iPunto > 0 then
    Result := Copy(Result, iPunto + 1, MaxInt);
  Result := LowerCase(QuitarDelimitadoresIdentificador(Result));
end;

function EsTablaFacturacionProtegida(
  const ANombreTabla: string): Boolean;
var
  sNombre: string;
begin
  sNombre := NormalizarNombreTabla(ANombreTabla);
  Result := (sNombre = NOMBRE_TABLA_FACTURAS) or
    (sNombre = NOMBRE_TABLA_FACTURAS_LINEAS);
end;

function TokenEs(
  const ATokens: TTokensSql;
  AIndice: Integer;
  const ATexto: string): Boolean;
begin
  Result := (AIndice >= 0) and (AIndice < Length(ATokens)) and
    (ATokens[AIndice].Tipo = ttsIdentificador) and
    SameText(ATokens[AIndice].Texto, ATexto);
end;

function SimboloEs(
  const ATokens: TTokensSql;
  AIndice: Integer;
  const ATexto: string): Boolean;
begin
  Result := (AIndice >= 0) and (AIndice < Length(ATokens)) and
    (ATokens[AIndice].Tipo = ttsSimbolo) and
    (ATokens[AIndice].Texto = ATexto);
end;

function LeerNombreCalificado(
  const ATokens: TTokensSql;
  var AIndice: Integer;
  out ANombre: string): Boolean;
begin
  ANombre := '';
  Result := (AIndice >= 0) and (AIndice < Length(ATokens)) and
    (ATokens[AIndice].Tipo = ttsIdentificador);
  if Result then
  begin
    ANombre := ATokens[AIndice].Texto;
    Inc(AIndice);
    while SimboloEs(ATokens, AIndice, '.') and
          (AIndice + 1 < Length(ATokens)) and
          (ATokens[AIndice + 1].Tipo = ttsIdentificador) do
    begin
      ANombre := ATokens[AIndice + 1].Texto;
      Inc(AIndice, 2);
    end;
    ANombre := NormalizarNombreTabla(ANombre);
  end;
end;

procedure SaltarPalabras(
  const ATokens: TTokensSql;
  var AIndice: Integer;
  const APalabras: array of string);
var
  I: Integer;
  bEncontrada: Boolean;
begin
  repeat
    bEncontrada := False;
    for I := Low(APalabras) to High(APalabras) do
    begin
      if TokenEs(ATokens, AIndice, APalabras[I]) then
      begin
        Inc(AIndice);
        bEncontrada := True;
        Break;
      end;
    end;
  until not bEncontrada;
end;

function DetectarObjetivoInsertReplace(
  const ATokens: TTokensSql;
  AIndiceOperacion: Integer;
  out ATabla: string): Boolean;
var
  iIndice: Integer;
begin
  ATabla := '';
  iIndice := AIndiceOperacion + 1;
  SaltarPalabras(
    ATokens,
    iIndice,
    ['LOW_PRIORITY', 'DELAYED', 'HIGH_PRIORITY', 'IGNORE']);
  if TokenEs(ATokens, iIndice, 'INTO') then
    Inc(iIndice);
  SaltarPalabras(ATokens, iIndice, ['ONLY']);
  Result := LeerNombreCalificado(ATokens, iIndice, ATabla) and
    EsTablaFacturacionProtegida(ATabla);
  if not Result then
    ATabla := '';
end;

function DetectarObjetivoUpdate(
  const ATokens: TTokensSql;
  AIndiceOperacion: Integer;
  out ATabla: string): Boolean;
var
  bEsperandoTabla: Boolean;
  bFinalizado: Boolean;
  iIndice: Integer;
  iNivel: Integer;
  sNombre: string;
begin
  Result := False;
  ATabla := '';
  iIndice := AIndiceOperacion + 1;
  SaltarPalabras(ATokens, iIndice, ['LOW_PRIORITY', 'IGNORE', 'ONLY']);
  bEsperandoTabla := True;
  bFinalizado := False;
  iNivel := 0;
  while (iIndice < Length(ATokens)) and
        not bFinalizado and not Result do
  begin
    if SimboloEs(ATokens, iIndice, '(') then
    begin
      Inc(iNivel);
      Inc(iIndice);
    end
    else if SimboloEs(ATokens, iIndice, ')') then
    begin
      if iNivel = 0 then
        bFinalizado := True
      else
      begin
        Dec(iNivel);
        Inc(iIndice);
      end;
    end
    else if (iNivel = 0) and TokenEs(ATokens, iIndice, 'SET') then
      bFinalizado := True
    else if (iNivel = 0) and bEsperandoTabla then
    begin
      if TokenEs(ATokens, iIndice, 'ONLY') then
        Inc(iIndice)
      else if LeerNombreCalificado(ATokens, iIndice, sNombre) then
      begin
        if EsTablaFacturacionProtegida(sNombre) then
        begin
          ATabla := sNombre;
          Result := True;
        end;
        bEsperandoTabla := False;
      end
      else
        Inc(iIndice);
    end
    else if (iNivel = 0) and
            (TokenEs(ATokens, iIndice, 'JOIN') or
             TokenEs(ATokens, iIndice, 'STRAIGHT_JOIN') or
             SimboloEs(ATokens, iIndice, ',')) then
    begin
      bEsperandoTabla := True;
      Inc(iIndice);
    end
    else
      Inc(iIndice);
  end;
end;

function EsPalabraReservadaAlias(const AToken: TTokenSql): Boolean;
const
  PALABRAS: array[0..28] of string = (
    'AS', 'ON', 'USING', 'WHERE', 'ORDER', 'LIMIT', 'RETURNING',
    'JOIN', 'LEFT', 'RIGHT', 'INNER', 'OUTER', 'FULL', 'CROSS',
    'NATURAL', 'STRAIGHT_JOIN', 'GROUP', 'HAVING', 'SET', 'PARTITION',
    'FORCE', 'USE', 'IGNORE', 'INDEX', 'KEY', 'UNION', 'OFFSET',
    'FETCH', 'FOR');
var
  I: Integer;
begin
  Result := AToken.Tipo <> ttsIdentificador;
  I := Low(PALABRAS);
  while not Result and (I <= High(PALABRAS)) do
  begin
    Result := SameText(AToken.Texto, PALABRAS[I]);
    Inc(I);
  end;
end;

function ListaContiene(
  ALista: TStringList;
  const AValor: string): Boolean;
begin
  Result := ALista.IndexOf(AValor) >= 0;
end;

procedure AgregarObjetivoDelete(
  AObjetivos: TStringList;
  const AObjetivo: string);
var
  sObjetivo: string;
begin
  sObjetivo := NormalizarNombreTabla(AObjetivo);
  if (sObjetivo <> '') and not ListaContiene(AObjetivos, sObjetivo) then
    AObjetivos.Add(sObjetivo);
end;

function BuscarPalabraNivelCero(
  const ATokens: TTokensSql;
  AInicio: Integer;
  const APalabra: string): Integer;
var
  bFinalizado: Boolean;
  I: Integer;
  iNivel: Integer;
begin
  Result := -1;
  bFinalizado := False;
  iNivel := 0;
  I := AInicio;
  while (I < Length(ATokens)) and
        not bFinalizado and (Result < 0) do
  begin
    if SimboloEs(ATokens, I, '(') then
      Inc(iNivel)
    else if SimboloEs(ATokens, I, ')') then
    begin
      if iNivel > 0 then
        Dec(iNivel);
    end
    else if (iNivel = 0) and TokenEs(ATokens, I, APalabra) then
      Result := I
    else if (iNivel = 0) and SimboloEs(ATokens, I, ';') then
      bFinalizado := True;
    Inc(I);
  end;
end;

function ReferenciaDeleteProtegidaEsObjetivo(
  const ATokens: TTokensSql;
  AInicioReferencias: Integer;
  AObjetivos: TStringList;
  out ATabla: string): Boolean;
var
  bEsperandoTabla: Boolean;
  bFinalizado: Boolean;
  iIndice: Integer;
  iNivel: Integer;
  sAlias: string;
  sNombre: string;
begin
  Result := False;
  ATabla := '';
  bEsperandoTabla := True;
  bFinalizado := False;
  iIndice := AInicioReferencias;
  iNivel := 0;
  while (iIndice < Length(ATokens)) and
        not bFinalizado and not Result do
  begin
    if SimboloEs(ATokens, iIndice, ';') and (iNivel = 0) then
      bFinalizado := True
    else if SimboloEs(ATokens, iIndice, '(') then
    begin
      Inc(iNivel);
      Inc(iIndice);
    end
    else if SimboloEs(ATokens, iIndice, ')') then
    begin
      if iNivel = 0 then
        bFinalizado := True
      else
      begin
        Dec(iNivel);
        Inc(iIndice);
      end;
    end
    else if (iNivel = 0) and
            (TokenEs(ATokens, iIndice, 'WHERE') or
             TokenEs(ATokens, iIndice, 'ORDER') or
             TokenEs(ATokens, iIndice, 'LIMIT') or
             TokenEs(ATokens, iIndice, 'RETURNING')) then
      bFinalizado := True
    else if (iNivel = 0) and bEsperandoTabla then
    begin
      if TokenEs(ATokens, iIndice, 'ONLY') then
        Inc(iIndice)
      else if LeerNombreCalificado(ATokens, iIndice, sNombre) then
      begin
        sAlias := '';
        if TokenEs(ATokens, iIndice, 'AS') then
        begin
          Inc(iIndice);
          if (iIndice < Length(ATokens)) and
             (ATokens[iIndice].Tipo = ttsIdentificador) then
          begin
            sAlias := NormalizarNombreTabla(ATokens[iIndice].Texto);
            Inc(iIndice);
          end;
        end
        else if (iIndice < Length(ATokens)) and
                not EsPalabraReservadaAlias(ATokens[iIndice]) then
        begin
          sAlias := NormalizarNombreTabla(ATokens[iIndice].Texto);
          Inc(iIndice);
        end;
        if EsTablaFacturacionProtegida(sNombre) and
           (ListaContiene(AObjetivos, sNombre) or
            ((sAlias <> '') and ListaContiene(AObjetivos, sAlias))) then
        begin
          ATabla := sNombre;
          Result := True;
        end;
        bEsperandoTabla := False;
      end
      else
        Inc(iIndice);
    end
    else if (iNivel = 0) and
            (TokenEs(ATokens, iIndice, 'JOIN') or
             TokenEs(ATokens, iIndice, 'STRAIGHT_JOIN') or
             TokenEs(ATokens, iIndice, 'USING') or
             SimboloEs(ATokens, iIndice, ',')) then
    begin
      bEsperandoTabla := True;
      Inc(iIndice);
    end
    else
      Inc(iIndice);
  end;
end;

function DetectarObjetivoDelete(
  const ATokens: TTokensSql;
  AIndiceOperacion: Integer;
  out ATabla: string): Boolean;
var
  bFormaFromDirecta: Boolean;
  iDesde: Integer;
  iIndice: Integer;
  iUsing: Integer;
  oObjetivos: TStringList;
  sObjetivo: string;
begin
  Result := False;
  ATabla := '';
  oObjetivos := TStringList.Create;
  try
    oObjetivos.CaseSensitive := False;
    iIndice := AIndiceOperacion + 1;
    SaltarPalabras(ATokens, iIndice, ['LOW_PRIORITY', 'QUICK', 'IGNORE']);
    bFormaFromDirecta := TokenEs(ATokens, iIndice, 'FROM');
    if bFormaFromDirecta then
      Inc(iIndice);
    SaltarPalabras(ATokens, iIndice, ['ONLY']);

    while (iIndice < Length(ATokens)) and not Result do
    begin
      if (not bFormaFromDirecta) and
         (TokenEs(ATokens, iIndice, 'FROM') or
          TokenEs(ATokens, iIndice, 'USING')) then
        Break;
      if not LeerNombreCalificado(ATokens, iIndice, sObjetivo) then
        Break;
      AgregarObjetivoDelete(oObjetivos, sObjetivo);
      if EsTablaFacturacionProtegida(sObjetivo) then
      begin
        ATabla := sObjetivo;
        Result := True;
      end;
      if not Result then
      begin
        if SimboloEs(ATokens, iIndice, '.') and
           SimboloEs(ATokens, iIndice + 1, '*') then
          Inc(iIndice, 2);
        if not SimboloEs(ATokens, iIndice, ',') then
          Break;
        Inc(iIndice);
      end;
    end;

    if not Result then
    begin
      if bFormaFromDirecta then
      begin
        iUsing := BuscarPalabraNivelCero(ATokens, iIndice, 'USING');
        if iUsing >= 0 then
          iDesde := iUsing + 1
        else
          iDesde := AIndiceOperacion + 2;
      end
      else
      begin
        iDesde := BuscarPalabraNivelCero(ATokens, iIndice, 'FROM');
        if iDesde < 0 then
          iDesde := BuscarPalabraNivelCero(ATokens, iIndice, 'USING');
        if iDesde >= 0 then
          Inc(iDesde);
      end;
      if iDesde >= 0 then
        Result := ReferenciaDeleteProtegidaEsObjetivo(
          ATokens,
          iDesde,
          oObjetivos,
          ATabla);
    end;
  finally
    oObjetivos.Free;
  end;
end;

function DetectarObjetivoTruncate(
  const ATokens: TTokensSql;
  AIndiceOperacion: Integer;
  out ATabla: string): Boolean;
var
  bFinalizado: Boolean;
  iIndice: Integer;
  sNombre: string;
begin
  Result := False;
  ATabla := '';
  bFinalizado := False;
  iIndice := AIndiceOperacion + 1;
  SaltarPalabras(ATokens, iIndice, ['TABLE', 'ONLY']);
  while (iIndice < Length(ATokens)) and
        not bFinalizado and not Result do
  begin
    if not LeerNombreCalificado(ATokens, iIndice, sNombre) then
      bFinalizado := True
    else if EsTablaFacturacionProtegida(sNombre) then
    begin
      ATabla := sNombre;
      Result := True;
    end;
    if not Result and not bFinalizado then
    begin
      if SimboloEs(ATokens, iIndice, '*') then
        Inc(iIndice);
      if not SimboloEs(ATokens, iIndice, ',') then
        bFinalizado := True
      else
      begin
        Inc(iIndice);
        SaltarPalabras(ATokens, iIndice, ['ONLY']);
      end;
    end;
  end;
end;

function DetectarObjetivoDropTable(
  const ATokens: TTokensSql;
  AIndiceOperacion: Integer;
  out ATabla: string): Boolean;
var
  bFinalizado: Boolean;
  iIndice: Integer;
  sNombre: string;
begin
  Result := False;
  ATabla := '';
  bFinalizado := False;
  iIndice := AIndiceOperacion + 1;
  SaltarPalabras(ATokens, iIndice, ['TEMPORARY']);
  if TokenEs(ATokens, iIndice, 'TABLE') then
  begin
    Inc(iIndice);
    SaltarPalabras(ATokens, iIndice, ['IF', 'EXISTS', 'ONLY']);
    while (iIndice < Length(ATokens)) and
          not bFinalizado and not Result do
    begin
      if not LeerNombreCalificado(ATokens, iIndice, sNombre) then
        bFinalizado := True
      else if EsTablaFacturacionProtegida(sNombre) then
      begin
        ATabla := sNombre;
        Result := True;
      end;
      if not Result and not bFinalizado then
      begin
        if not SimboloEs(ATokens, iIndice, ',') then
          bFinalizado := True
        else
        begin
          Inc(iIndice);
          SaltarPalabras(ATokens, iIndice, ['ONLY']);
        end;
      end;
    end;
  end;
end;

function DetectarObjetivoAlterTable(
  const ATokens: TTokensSql;
  AIndiceOperacion: Integer;
  out ATabla: string): Boolean;
var
  iIndice: Integer;
begin
  Result := False;
  ATabla := '';
  iIndice := AIndiceOperacion + 1;
  SaltarPalabras(ATokens, iIndice, ['ONLINE', 'OFFLINE', 'IGNORE']);
  if TokenEs(ATokens, iIndice, 'TABLE') then
  begin
    Inc(iIndice);
    SaltarPalabras(ATokens, iIndice, ['IF', 'EXISTS', 'ONLY']);
    Result := LeerNombreCalificado(ATokens, iIndice, ATabla) and
      EsTablaFacturacionProtegida(ATabla);
  end;
  if not Result then
    ATabla := '';
end;

function DetectarObjetivoRenameTable(
  const ATokens: TTokensSql;
  AIndiceOperacion: Integer;
  out ATabla: string): Boolean;
var
  bFinalizado: Boolean;
  iIndice: Integer;
  sNombre: string;
begin
  Result := False;
  ATabla := '';
  bFinalizado := False;
  iIndice := AIndiceOperacion + 1;
  if TokenEs(ATokens, iIndice, 'TABLE') then
  begin
    Inc(iIndice);
    while (iIndice < Length(ATokens)) and
          not bFinalizado and not Result do
    begin
      if not LeerNombreCalificado(ATokens, iIndice, sNombre) then
        bFinalizado := True
      else if EsTablaFacturacionProtegida(sNombre) then
      begin
        ATabla := sNombre;
        Result := True;
      end
      else if not TokenEs(ATokens, iIndice, 'TO') then
        bFinalizado := True
      else
      begin
        Inc(iIndice);
        if not LeerNombreCalificado(ATokens, iIndice, sNombre) then
          bFinalizado := True
        else if EsTablaFacturacionProtegida(sNombre) then
        begin
          ATabla := sNombre;
          Result := True;
        end
        else if not SimboloEs(ATokens, iIndice, ',') then
          bFinalizado := True
        else
          Inc(iIndice);
      end;
    end;
  end;
end;

function DetectarObjetivoCreateOrReplaceTable(
  const ATokens: TTokensSql;
  AIndiceOperacion: Integer;
  out ATabla: string): Boolean;
var
  bCabeceraValida: Boolean;
  iIndice: Integer;
begin
  Result := False;
  ATabla := '';
  iIndice := AIndiceOperacion + 1;
  bCabeceraValida := TokenEs(ATokens, iIndice, 'OR');
  if bCabeceraValida then
  begin
    Inc(iIndice);
    bCabeceraValida := TokenEs(ATokens, iIndice, 'REPLACE');
  end;
  if bCabeceraValida then
  begin
    Inc(iIndice);
    SaltarPalabras(ATokens, iIndice, ['TEMPORARY']);
    bCabeceraValida := TokenEs(ATokens, iIndice, 'TABLE');
  end;
  if bCabeceraValida then
  begin
    Inc(iIndice);
    Result := LeerNombreCalificado(ATokens, iIndice, ATabla) and
      EsTablaFacturacionProtegida(ATabla);
  end;
  if not Result then
    ATabla := '';
end;

function DetectarObjetivoTrasInto(
  const ATokens: TTokensSql;
  AIndiceOperacion: Integer;
  out ATabla: string): Boolean;
var
  iIndice: Integer;
begin
  ATabla := '';
  iIndice := BuscarPalabraNivelCero(
    ATokens,
    AIndiceOperacion + 1,
    'INTO');
  Result := iIndice >= 0;
  if Result then
  begin
    Inc(iIndice);
    SaltarPalabras(ATokens, iIndice, ['TABLE', 'ONLY']);
    Result := LeerNombreCalificado(ATokens, iIndice, ATabla) and
      EsTablaFacturacionProtegida(ATabla);
  end;
  if not Result then
    ATabla := '';
end;

function DetectarObjetivoCopyFrom(
  const ATokens: TTokensSql;
  AIndiceOperacion: Integer;
  out ATabla: string): Boolean;
var
  iDesde: Integer;
  iHasta: Integer;
  iIndice: Integer;
begin
  ATabla := '';
  iIndice := AIndiceOperacion + 1;
  Result := LeerNombreCalificado(ATokens, iIndice, ATabla) and
    EsTablaFacturacionProtegida(ATabla);
  if Result then
  begin
    iDesde := BuscarPalabraNivelCero(ATokens, iIndice, 'FROM');
    iHasta := BuscarPalabraNivelCero(ATokens, iIndice, 'TO');
    Result := (iDesde >= 0) and ((iHasta < 0) or (iDesde < iHasta));
  end;
  if not Result then
    ATabla := '';
end;

function SqlReferenciaTablaFacturacionProtegida(
  const ASql: string;
  out ATabla: string): Boolean;
var
  I: Integer;
  oTokens: TTokensSql;
begin
  Result := False;
  ATabla := '';
  oTokens := TokenizarSql(ASql);
  I := 0;
  while (I < Length(oTokens)) and not Result do
  begin
    Result := (oTokens[I].Tipo = ttsIdentificador) and
      EsTablaFacturacionProtegida(oTokens[I].Texto);
    if Result then
      ATabla := NormalizarNombreTabla(oTokens[I].Texto)
    else
      Inc(I);
  end;
end;

function SqlReferenciaTablaFacturacionProtegida(
  const ASql: string): Boolean;
var
  sTabla: string;
begin
  Result := SqlReferenciaTablaFacturacionProtegida(ASql, sTabla);
end;

function DetectarModificacionTablaFacturacion(
  const ASql: string;
  out AOperacion, ATabla: string): Boolean;
var
  I: Integer;
  oTokens: TTokensSql;
begin
  AOperacion := '';
  ATabla := '';
  oTokens := TokenizarSql(ASql);
  I := 0;
  while (I < Length(oTokens)) and (AOperacion = '') do
  begin
    if TokenEs(oTokens, I, 'INSERT') and
       DetectarObjetivoInsertReplace(oTokens, I, ATabla) then
      AOperacion := 'INSERT'
    else if TokenEs(oTokens, I, 'UPDATE') and
            DetectarObjetivoUpdate(oTokens, I, ATabla) then
      AOperacion := 'UPDATE'
    else if TokenEs(oTokens, I, 'DELETE') and
            DetectarObjetivoDelete(oTokens, I, ATabla) then
      AOperacion := 'DELETE'
    else if TokenEs(oTokens, I, 'REPLACE') and
            DetectarObjetivoInsertReplace(oTokens, I, ATabla) then
      AOperacion := 'REPLACE'
    else if TokenEs(oTokens, I, 'TRUNCATE') and
            DetectarObjetivoTruncate(oTokens, I, ATabla) then
      AOperacion := 'TRUNCATE'
    else if TokenEs(oTokens, I, 'DROP') and
            DetectarObjetivoDropTable(oTokens, I, ATabla) then
      AOperacion := 'DROP'
    else if TokenEs(oTokens, I, 'ALTER') and
            DetectarObjetivoAlterTable(oTokens, I, ATabla) then
      AOperacion := 'ALTER'
    else if TokenEs(oTokens, I, 'RENAME') and
            DetectarObjetivoRenameTable(oTokens, I, ATabla) then
      AOperacion := 'RENAME'
    else if TokenEs(oTokens, I, 'CREATE') and
            DetectarObjetivoCreateOrReplaceTable(oTokens, I, ATabla) then
      AOperacion := 'CREATE OR REPLACE'
    else if TokenEs(oTokens, I, 'LOAD') and
            DetectarObjetivoTrasInto(oTokens, I, ATabla) then
      AOperacion := 'LOAD'
    else if TokenEs(oTokens, I, 'MERGE') and
            DetectarObjetivoTrasInto(oTokens, I, ATabla) then
      AOperacion := 'MERGE'
    else if TokenEs(oTokens, I, 'COPY') and
            DetectarObjetivoCopyFrom(oTokens, I, ATabla) then
      AOperacion := 'COPY';
    Inc(I);
  end;
  Result := AOperacion <> '';
end;

procedure ValidarSqlSinModificacionesFacturacion(const ASql: string);
var
  sOperacion: string;
  sTabla: string;
begin
  if DetectarModificacionTablaFacturacion(
       ASql,
       sOperacion,
       sTabla) then
    raise EModificacionTablaFacturacionProtegida.Create(
      sOperacion,
      sTabla);
end;

constructor EModificacionTablaFacturacionProtegida.Create(
  const AOperacion, ATabla: string);
begin
  FOperacion := UpperCase(Trim(AOperacion));
  FTabla := NormalizarNombreTabla(ATabla);
  inherited CreateFmt(
    SErrorModificacionTablaFacturacionProtegida,
    [FOperacion, FTabla]);
end;

end.
