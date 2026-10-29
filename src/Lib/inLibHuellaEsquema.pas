{******************************************************************************}
{                                                                              }
{  Módulo:       inLibHuellaEsquema                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Huella del esquema calculada por el programa: JSON canónico por           }
{    apartado y SHA-256, igual que PRC_FZA_HUELLA_ESQUEMA. Compara la base     }
{    con el esquema ideal embebido y con lo que devuelve el procedimiento.     }
{******************************************************************************}
unit inLibHuellaEsquema;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  inLibHuellaEsquemaIntf;

type
  EEsquemaIdealInvalido = class(Exception);

  TTipoDiferenciaHuella = (tdhFalta, tdhSobra, tdhDistinta);

  TDiferenciaHuella = record
    Apartado: TApartadoHuella;
    Tipo: TTipoDiferenciaHuella;
    Objeto: string;
    FirmaIdeal: string;
    FirmaReal: string;
  end;

  TEstadoIntegridad = (
    eiIntegra,
    eiObjetosDeMas,
    eiConDiferencias);

  TEstadoProcedimientoHuella = (
    ephNoInstalado,
    ephCoherente,
    ephVersionDistinta,
    ephDistinto,
    ephConError,
    // Distinto, pero el usuario no ve todo el catálogo y el procedimiento
    // (SQL SECURITY DEFINER) sí: no se puede concluir nada.
    ephNoComparable);

  TResultadoIntegridad = record
    Estado: TEstadoIntegridad;
    Huellas: THuellasEsquema;
    HuellasIdeal: THuellasEsquema;
    CodigoComprobado: Boolean;
    ElementosSinPermiso: Integer;
    Diferencias: TArray<TDiferenciaHuella>;
    Procedimiento: TEstadoProcedimientoHuella;
    VersionProcedimiento: Integer;
    ErrorProcedimiento: string;
    ApartadosProcedimientoDistintos: set of TApartadoHuella;
    function HayAjustesIndices: Boolean;
  end;

  // Esquema ideal: el modelo de esta versión, generado al publicar con
  // src\utlEsquemaIdeal\GeneradorEsquemaIdeal.exe y embebido como recurso.
  TEsquemaIdeal = class
  private
    FVersionHuella: Integer;
    FModelo: string;
    FGenerado: string;
    FHuellas: THuellasEsquema;
    FElementos: TElementosHuella;
    FCodigo: TDictionary<string, TElementosHuella>;
    FHuellasCodigo: TDictionary<string, string>;
    procedure LeerJson(const AJson: string);
  public
    constructor Create(const AJson: string);
    destructor Destroy; override;
    // Elementos ideales para un motor ('mariadb1213', 'mariadb1014',
    // 'mysql8041'); sin CODIGO si no hay referencia para ese motor.
    function ElementosPara(
      const AMotor: string;
      out ATieneCodigo: Boolean): TElementosHuella;
    function HuellasPara(const AMotor: string): THuellasEsquema;
    // El recurso no se ha tocado: sus huellas salen de sus elementos.
    function EsCoherente: Boolean;
    property VersionHuella: Integer read FVersionHuella;
    property Modelo: string read FModelo;
    property Generado: string read FGenerado;
  end;

  TComprobacionIntegridad = record
    Contexto: TContextoCatalogo;
    // Motor del servidor ('mariadb1213'...); vacío si no es uno admitido.
    Motor: string;
    Modelo: string;
    Generado: string;
    EsquemaIdealCoherente: Boolean;
    Resultado: TResultadoIntegridad;
    // Firma digital del ejecutable: la rellena quien conoce la ruta del
    // programa ('' = no se ha mirado).
    TextoFirma: string;
    FirmaPreocupante: Boolean;
  end;

const
  // Contrato de PRC_FZA_HUELLA_ESQUEMA (columna VERSION_HUELLA).
  cVersionHuella = 1;
  // Formato del esquema ideal embebido. 2: el código de las rutinas se
  // compara sin comentarios ni líneas vacías. 3: ni '\r' en literales.
  cVersionEsquemaIdeal = 3;

function CitarJson(const ATexto: string): string;
function JsonCanonicoApartado(
  const AElementos: TElementosHuella;
  AApartado: TApartadoHuella): string;
function Sha256Hex(const ATexto: string): string;
// El cliente mariadb/mysql quita los comentarios al cargar un script y
// UniDAC los conserva: el mismo procedimiento quedaría distinto según cómo
// se instaló. Se compara sin comentarios (fuera de literales), sin
// espacios al final de línea y sin líneas vacías.
function NormalizarCuerpoRutina(const ACuerpo: string): string;
function HuellaCuerpoRutina(const ACuerpo: string): string;
function CalcularHuellas(const AElementos: TElementosHuella):
  THuellasEsquema;
function CompararEsquema(
  AIdeal: TEsquemaIdeal;
  const AReales: TElementosHuella;
  const AMotor: string): TResultadoIntegridad;
procedure CompararProcedimiento(
  const AProcedimiento: THuellasProcedimiento;
  var AResultado: TResultadoIntegridad);
// Texto del motor de un SELECT VERSION(); vacío si no es uno admitido.
function MotorDeVersionServidor(const AVersion: string): string;
function ComprobarIntegridadEsquema(
  const ALector: ILectorCatalogoEsquema;
  AIdeal: TEsquemaIdeal): TComprobacionIntegridad;
function IntegridadPermiteArranque(
  const AComprobacion: TComprobacionIntegridad): Boolean;

implementation

uses
  System.Hash,
  System.JSON,
  System.Generics.Defaults,
  inLibMotorBaseDatos;

function IntegridadPermiteArranque(
  const AComprobacion: TComprobacionIntegridad): Boolean;
begin
  // Los objetos propios y ajustes de índices conservan el criterio del
  // comprobador. Una validación parcial nunca autoriza el arranque.
  Result := AComprobacion.EsquemaIdealCoherente and
    (Length(AComprobacion.Contexto.IncidenciasIntercalacion) = 0) and
    (AComprobacion.Resultado.Estado in [eiIntegra, eiObjetosDeMas]) and
    AComprobacion.Resultado.CodigoComprobado and
    (AComprobacion.Resultado.ElementosSinPermiso = 0) and
    (AComprobacion.Resultado.Procedimiento in
      [ephNoInstalado, ephCoherente]);
end;

function CitarJson(const ATexto: string): string;
var
  oTexto: TStringBuilder;
  cCaracter: Char;
begin
  // Igual que JSON_QUOTE de MariaDB y MySQL: comillas, barra invertida y
  // caracteres de control; el resto tal cual.
  oTexto := TStringBuilder.Create(Length(ATexto) + 2);
  try
    oTexto.Append('"');
    for cCaracter in ATexto do
    begin
      case cCaracter of
        '"':
          oTexto.Append('\"');
        '\':
          oTexto.Append('\\');
        #8:
          oTexto.Append('\b');
        #9:
          oTexto.Append('\t');
        #10:
          oTexto.Append('\n');
        #12:
          oTexto.Append('\f');
        #13:
          oTexto.Append('\r');
        #0..#7, #11, #14..#31:
          oTexto.Append('\u' + IntToHex(Ord(cCaracter), 4).ToLower);
      else
        oTexto.Append(cCaracter);
      end;
    end;
    oTexto.Append('"');
    Result := oTexto.ToString;
  finally
    oTexto.Free;
  end;
end;

function ElementosDeApartado(
  const AElementos: TElementosHuella;
  AApartado: TApartadoHuella): TElementosHuella;
var
  oLista: TList<TElementoHuella>;
  oElemento: TElementoHuella;
begin
  oLista := TList<TElementoHuella>.Create;
  try
    for oElemento in AElementos do
    begin
      if oElemento.Apartado = AApartado then
        oLista.Add(oElemento);
    end;
    // Orden binario del objeto, como la temporal utf8mb4_bin del
    // procedimiento (los nombres del esquema son ASCII).
    oLista.Sort(TComparer<TElementoHuella>.Construct(
      function(const A, B: TElementoHuella): Integer
      begin
        Result := CompareStr(A.Objeto, B.Objeto);
      end));
    Result := oLista.ToArray;
  finally
    oLista.Free;
  end;
end;

function JsonCanonicoApartado(
  const AElementos: TElementosHuella;
  AApartado: TApartadoHuella): string;
var
  aOrdenados: TElementosHuella;
  oTexto: TStringBuilder;
  iElemento: Integer;
begin
  aOrdenados := ElementosDeApartado(AElementos, AApartado);
  oTexto := TStringBuilder.Create;
  try
    oTexto.Append('{');
    for iElemento := 0 to High(aOrdenados) do
    begin
      if iElemento > 0 then
        oTexto.Append(',');
      oTexto.Append(CitarJson(aOrdenados[iElemento].Objeto));
      oTexto.Append(':');
      oTexto.Append(CitarJson(aOrdenados[iElemento].Firma));
    end;
    oTexto.Append('}');
    Result := oTexto.ToString;
  finally
    oTexto.Free;
  end;
end;

function Sha256Hex(const ATexto: string): string;
begin
  // THashSHA2 cifra los bytes UTF-8 del texto, como SHA2() del servidor
  // con la conexión en utf8mb4, y devuelve el hexadecimal en minúsculas.
  Result := THashSHA2.GetHashString(ATexto,
                                    THashSHA2.TSHA2Version.SHA256);
end;

function FinDeLinea(const ATexto: string; ADesde: Integer): Integer;
begin
  Result := ADesde;
  while (Result <= Length(ATexto)) and (ATexto[Result] <> #10) do
    Inc(Result);
end;

function EmpiezaComentario(const ATexto: string; APosicion: Integer):
  Boolean;
begin
  // '-- ' necesita espacio, tabulador o fin de línea detrás, como MySQL.
  Result := (ATexto[APosicion] = '#') or
    ((ATexto[APosicion] = '-') and (APosicion < Length(ATexto)) and
     (ATexto[APosicion + 1] = '-') and
     ((APosicion + 1 = Length(ATexto)) or
      CharInSet(ATexto[APosicion + 2], [' ', #9, #10])));
end;

procedure CopiarDentroDeLiteral(
  const ATexto: string;
  ATextoLimpio: TStringBuilder;
  var APosicion: Integer;
  var AComilla: Char);
begin
  if (ATexto[APosicion] = '\') and (AComilla <> '`') and
     (APosicion < Length(ATexto)) then
  begin
    // Un salto de línea dentro de un literal se guarda escrito: '\n' si
    // el script llegó con LF (cliente mariadb) y '\r\n' si llegó con CRLF
    // (TUniScript del actualizador). El '\r' no cuenta.
    if ATexto[APosicion + 1] <> 'r' then
    begin
      ATextoLimpio.Append(ATexto[APosicion]);
      ATextoLimpio.Append(ATexto[APosicion + 1]);
    end;
    Inc(APosicion, 2);
  end
  else
  begin
    ATextoLimpio.Append(ATexto[APosicion]);
    if ATexto[APosicion] = AComilla then
      AComilla := #0;
    Inc(APosicion);
  end;
end;

function QuitarComentarios(const ATexto: string): string;
var
  oTexto: TStringBuilder;
  iPosicion, iFin: Integer;
  cComilla: Char;
begin
  oTexto := TStringBuilder.Create(Length(ATexto));
  try
    cComilla := #0;
    iPosicion := 1;
    while iPosicion <= Length(ATexto) do
    begin
      if cComilla <> #0 then
        CopiarDentroDeLiteral(ATexto, oTexto, iPosicion, cComilla)
      else if CharInSet(ATexto[iPosicion], ['''', '"', '`']) then
      begin
        cComilla := ATexto[iPosicion];
        oTexto.Append(cComilla);
        Inc(iPosicion);
      end
      else if EmpiezaComentario(ATexto, iPosicion) then
        iPosicion := FinDeLinea(ATexto, iPosicion)
      else if (ATexto[iPosicion] = '/') and (iPosicion < Length(ATexto)) and
              (ATexto[iPosicion + 1] = '*') then
      begin
        iFin := Pos('*/', ATexto, iPosicion + 2);
        if iFin = 0 then
          iPosicion := Length(ATexto) + 1
        else
          iPosicion := iFin + 2;
      end
      else
      begin
        oTexto.Append(ATexto[iPosicion]);
        Inc(iPosicion);
      end;
    end;
    Result := oTexto.ToString;
  finally
    oTexto.Free;
  end;
end;

function NormalizarCuerpoRutina(const ACuerpo: string): string;
var
  sLinea: string;
  oLineas: TStringBuilder;
begin
  // Una comilla doblada ('') cierra y vuelve a abrir el literal: el
  // recorrido de QuitarComentarios la trata bien sin caso aparte.
  oLineas := TStringBuilder.Create;
  try
    for sLinea in QuitarComentarios(
                    StringReplace(ACuerpo, #13, '', [rfReplaceAll]))
                    .Split([#10]) do
    begin
      if Trim(sLinea) <> '' then
      begin
        if oLineas.Length > 0 then
          oLineas.Append(#10);
        oLineas.Append(TrimRight(sLinea));
      end;
    end;
    Result := oLineas.ToString;
  finally
    oLineas.Free;
  end;
end;

function HuellaCuerpoRutina(const ACuerpo: string): string;
begin
  Result := THashMD5.GetHashString(NormalizarCuerpoRutina(ACuerpo));
end;

function CalcularHuellas(const AElementos: TElementosHuella):
  THuellasEsquema;
var
  eApartado: TApartadoHuella;
begin
  Result := Default(THuellasEsquema);
  for eApartado := Low(TApartadoHuella) to High(TApartadoHuella) do
  begin
    Result.Apartados[eApartado] := Sha256Hex(
      JsonCanonicoApartado(AElementos, eApartado));
  end;
  Result.Global := Sha256Hex(
    Result.Apartados[ahEstructura] +
    Result.Apartados[ahVistas] +
    Result.Apartados[ahRutinas] +
    Result.Apartados[ahDefinidores]);
end;

{ TResultadoIntegridad }

function TResultadoIntegridad.HayAjustesIndices: Boolean;
begin
  Result := Huellas.Apartados[ahIndices] <>
    HuellasIdeal.Apartados[ahIndices];
end;

{ TEsquemaIdeal }

constructor TEsquemaIdeal.Create(const AJson: string);
begin
  inherited Create;
  FCodigo := TDictionary<string, TElementosHuella>.Create;
  FHuellasCodigo := TDictionary<string, string>.Create;
  LeerJson(AJson);
end;

destructor TEsquemaIdeal.Destroy;
begin
  FreeAndNil(FHuellasCodigo);
  FreeAndNil(FCodigo);
  inherited;
end;

function ApartadoDesdeTexto(const ATexto: string): TApartadoHuella;
var
  eApartado: TApartadoHuella;
  bEncontrado: Boolean;
begin
  Result := Low(TApartadoHuella);
  bEncontrado := False;
  for eApartado := Low(TApartadoHuella) to High(TApartadoHuella) do
  begin
    if TextoApartadoHuella(eApartado) = ATexto then
    begin
      Result := eApartado;
      bEncontrado := True;
    end;
  end;
  if not bEncontrado then
    raise EEsquemaIdealInvalido.CreateFmt('Apartado desconocido: %s',
                                          [ATexto]);
end;

function LeerElementosJson(
  AObjeto: TJSONObject;
  AApartado: TApartadoHuella): TElementosHuella;
var
  oPar: TJSONPair;
  oLista: TList<TElementoHuella>;
  oElemento: TElementoHuella;
begin
  oLista := TList<TElementoHuella>.Create;
  try
    for oPar in AObjeto do
    begin
      oElemento.Apartado := AApartado;
      oElemento.Objeto := oPar.JsonString.Value;
      oElemento.Firma := oPar.JsonValue.Value;
      oLista.Add(oElemento);
    end;
    Result := oLista.ToArray;
  finally
    oLista.Free;
  end;
end;

function ObjetoJson(AObjeto: TJSONObject; const ANombre: string):
  TJSONObject;
begin
  if not (AObjeto.GetValue(ANombre) is TJSONObject) then
    raise EEsquemaIdealInvalido.CreateFmt('Falta el objeto "%s"',
                                          [ANombre]);
  Result := TJSONObject(AObjeto.GetValue(ANombre));
end;

procedure TEsquemaIdeal.LeerJson(const AJson: string);
var
  oRaiz: TJSONValue;
  oDatos, oHuellas, oElementos, oCodigo, oMotor: TJSONObject;
  oPar: TJSONPair;
  eApartado: TApartadoHuella;
begin
  oRaiz := TJSONObject.ParseJSONValue(AJson);
  try
    if not (oRaiz is TJSONObject) then
      raise EEsquemaIdealInvalido.Create('El esquema ideal no es JSON');
    oDatos := TJSONObject(oRaiz);
    FVersionHuella := oDatos.GetValue<Integer>('version_huella');
    FModelo := oDatos.GetValue<string>('modelo');
    FGenerado := oDatos.GetValue<string>('generado');
    oHuellas := ObjetoJson(oDatos, 'huellas');
    FHuellas.Global := oHuellas.GetValue<string>('GLOBAL');
    oElementos := ObjetoJson(oDatos, 'elementos');
    for oPar in oElementos do
    begin
      eApartado := ApartadoDesdeTexto(oPar.JsonString.Value);
      FHuellas.Apartados[eApartado] := oHuellas.GetValue<string>(
        oPar.JsonString.Value);
      FElementos := FElementos + LeerElementosJson(
        oPar.JsonValue as TJSONObject, eApartado);
    end;
    oCodigo := ObjetoJson(oDatos, 'codigo');
    for oPar in oCodigo do
    begin
      oMotor := oPar.JsonValue as TJSONObject;
      FHuellasCodigo.AddOrSetValue(oPar.JsonString.Value,
                                   oMotor.GetValue<string>('huella'));
      FCodigo.AddOrSetValue(oPar.JsonString.Value,
                            LeerElementosJson(ObjetoJson(oMotor,
                                                         'elementos'),
                                              ahCodigo));
    end;
  finally
    oRaiz.Free;
  end;
end;

function TEsquemaIdeal.ElementosPara(
  const AMotor: string;
  out ATieneCodigo: Boolean): TElementosHuella;
var
  aCodigo: TElementosHuella;
begin
  ATieneCodigo := FCodigo.TryGetValue(AMotor, aCodigo);
  Result := FElementos + aCodigo;
end;

function TEsquemaIdeal.HuellasPara(const AMotor: string): THuellasEsquema;
var
  sCodigo: string;
begin
  Result := FHuellas;
  if FHuellasCodigo.TryGetValue(AMotor, sCodigo) then
    Result.Apartados[ahCodigo] := sCodigo;
end;

function TEsquemaIdeal.EsCoherente: Boolean;
var
  oHuellas: THuellasEsquema;
  oMotor: TPair<string, TElementosHuella>;
  eApartado: TApartadoHuella;
begin
  oHuellas := CalcularHuellas(FElementos);
  Result := oHuellas.Global = FHuellas.Global;
  for eApartado := Low(TApartadoHuella) to High(TApartadoHuella) do
  begin
    if eApartado <> ahCodigo then
      Result := Result and
        (oHuellas.Apartados[eApartado] = FHuellas.Apartados[eApartado]);
  end;
  for oMotor in FCodigo do
  begin
    Result := Result and
      (CalcularHuellas(oMotor.Value).Apartados[ahCodigo] =
       FHuellasCodigo[oMotor.Key]);
  end;
end;

{ Comparación }

function Clave(const AElemento: TElementoHuella): string;
begin
  Result := TextoApartadoHuella(AElemento.Apartado) + #9 + AElemento.Objeto;
end;

function Diccionario(const AElementos: TElementosHuella):
  TDictionary<string, TElementoHuella>;
var
  oElemento: TElementoHuella;
begin
  Result := TDictionary<string, TElementoHuella>.Create;
  for oElemento in AElementos do
    Result.AddOrSetValue(Clave(oElemento), oElemento);
end;

function NuevaDiferencia(
  const AElemento: TElementoHuella;
  ATipo: TTipoDiferenciaHuella;
  const AIdeal, AReal: string): TDiferenciaHuella;
begin
  Result.Apartado := AElemento.Apartado;
  Result.Tipo := ATipo;
  Result.Objeto := AElemento.Objeto;
  Result.FirmaIdeal := AIdeal;
  Result.FirmaReal := AReal;
end;

function CalcularDiferencias(
  const AIdeales, AReales: TElementosHuella;
  out ASinPermiso: Integer): TArray<TDiferenciaHuella>;
var
  oIdeales, oReales: TDictionary<string, TElementoHuella>;
  oLista: TList<TDiferenciaHuella>;
  oElemento, oOtro: TElementoHuella;
begin
  ASinPermiso := 0;
  oIdeales := Diccionario(AIdeales);
  oReales := Diccionario(AReales);
  oLista := TList<TDiferenciaHuella>.Create;
  try
    for oElemento in AIdeales do
    begin
      if not oReales.TryGetValue(Clave(oElemento), oOtro) then
        oLista.Add(NuevaDiferencia(oElemento, tdhFalta, oElemento.Firma,
                                   ''))
      else if oOtro.Firma = cFirmaSinPermiso then
        Inc(ASinPermiso)
      else if oOtro.Firma <> oElemento.Firma then
        oLista.Add(NuevaDiferencia(oElemento, tdhDistinta, oElemento.Firma,
                                   oOtro.Firma));
    end;
    for oElemento in AReales do
    begin
      if not oIdeales.ContainsKey(Clave(oElemento)) then
        oLista.Add(NuevaDiferencia(oElemento, tdhSobra, '',
                                   oElemento.Firma));
    end;
    Result := oLista.ToArray;
  finally
    oLista.Free;
    oReales.Free;
    oIdeales.Free;
  end;
end;

function EstadoSegunDiferencias(
  const ADiferencias: TArray<TDiferenciaHuella>): TEstadoIntegridad;
var
  oDiferencia: TDiferenciaHuella;
begin
  Result := eiIntegra;
  for oDiferencia in ADiferencias do
  begin
    // Los índices secundarios son ajustes de cada cliente: no cuentan.
    if oDiferencia.Apartado <> ahIndices then
    begin
      if oDiferencia.Tipo <> tdhSobra then
        Result := eiConDiferencias
      else if Result = eiIntegra then
        Result := eiObjetosDeMas;
    end;
  end;
end;

function SinCodigo(const AElementos: TElementosHuella): TElementosHuella;
var
  oLista: TList<TElementoHuella>;
  oElemento: TElementoHuella;
begin
  oLista := TList<TElementoHuella>.Create;
  try
    for oElemento in AElementos do
    begin
      if oElemento.Apartado <> ahCodigo then
        oLista.Add(oElemento);
    end;
    Result := oLista.ToArray;
  finally
    oLista.Free;
  end;
end;

function CompararEsquema(
  AIdeal: TEsquemaIdeal;
  const AReales: TElementosHuella;
  const AMotor: string): TResultadoIntegridad;
var
  aIdeales, aComparables: TElementosHuella;
begin
  Result := Default(TResultadoIntegridad);
  Result.Huellas := CalcularHuellas(AReales);
  Result.HuellasIdeal := AIdeal.HuellasPara(AMotor);
  aIdeales := AIdeal.ElementosPara(AMotor, Result.CodigoComprobado);
  aComparables := AReales;
  if not Result.CodigoComprobado then
    aComparables := SinCodigo(AReales);
  Result.Diferencias := CalcularDiferencias(aIdeales, aComparables,
                                            Result.ElementosSinPermiso);
  Result.Estado := EstadoSegunDiferencias(Result.Diferencias);
end;

procedure CompararProcedimiento(
  const AProcedimiento: THuellasProcedimiento;
  var AResultado: TResultadoIntegridad);
var
  eApartado: TApartadoHuella;
begin
  AResultado.ApartadosProcedimientoDistintos := [];
  AResultado.VersionProcedimiento := AProcedimiento.Version;
  AResultado.ErrorProcedimiento := AProcedimiento.Error;
  if not AProcedimiento.Existe then
    AResultado.Procedimiento := ephNoInstalado
  else if AProcedimiento.Error <> '' then
    AResultado.Procedimiento := ephConError
  else if AProcedimiento.Version <> cVersionHuella then
    AResultado.Procedimiento := ephVersionDistinta
  else
  begin
    // CODIGO no se contrasta: el procedimiento hace el MD5 del cuerpo tal
    // cual y el programa sin comentarios (ver NormalizarCuerpoRutina).
    for eApartado := Low(TApartadoHuella) to High(TApartadoHuella) do
    begin
      if (eApartado <> ahCodigo) and
         (AProcedimiento.Huellas.Apartados[eApartado] <>
          AResultado.Huellas.Apartados[eApartado]) then
        Include(AResultado.ApartadosProcedimientoDistintos, eApartado);
    end;
    if AResultado.ApartadosProcedimientoDistintos = [] then
      AResultado.Procedimiento := ephCoherente
    else if AResultado.ElementosSinPermiso > 0 then
      AResultado.Procedimiento := ephNoComparable
    else
      AResultado.Procedimiento := ephDistinto;
  end;
end;

function MotorDeVersionServidor(const AVersion: string): string;
var
  eMotorServidor: TMotorBaseDatos;
begin
  case CompararMotorConServidor(mbdMariaDB1213, AVersion,
                                eMotorServidor) of
    cmsCoincide:
      Result := TextoMotorBaseDatos(mbdMariaDB1213);
    cmsOtroMotor:
      Result := TextoMotorBaseDatos(eMotorServidor);
  else
    Result := '';
  end;
end;

function ComprobarIntegridadEsquema(
  const ALector: ILectorCatalogoEsquema;
  AIdeal: TEsquemaIdeal): TComprobacionIntegridad;
begin
  Result := Default(TComprobacionIntegridad);
  Result.Contexto := ALector.LeerContexto;
  Result.Motor := MotorDeVersionServidor(Result.Contexto.VersionServidor);
  Result.Modelo := AIdeal.Modelo;
  Result.Generado := AIdeal.Generado;
  Result.EsquemaIdealCoherente := AIdeal.EsCoherente;
  Result.Resultado := CompararEsquema(AIdeal, ALector.LeerElementos,
                                      Result.Motor);
  CompararProcedimiento(ALector.LeerHuellasProcedimiento,
                        Result.Resultado);
  // Las firmas históricas no contienen COLLATE. La comprobación adicional
  // también debe afectar al estado, aunque esas huellas coincidan.
  if Length(Result.Contexto.IncidenciasIntercalacion) > 0 then
    Result.Resultado.Estado := eiConDiferencias;
end;

end.
