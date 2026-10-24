{******************************************************************************}
{                                                                              }
{  Módulo:       inLibComandoCopiaSeguridad                                   }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       23/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Interpreta y valida el comando de copia de seguridad no interactiva.      }
{    Solo crea copias; la restauración nunca obtiene la clave desde el nombre. }
{******************************************************************************}
unit inLibComandoCopiaSeguridad;

interface

uses
  System.SysUtils;

type
  TErrorComandoCopiaSeguridad = (
    eccsNinguno,
    eccsSintaxis,
    eccsRuta,
    eccsExtension,
    eccsClave
  );
  TClavesPredeterminadasCopiaSeguridad = record
    ClaveCifrada: string;
    Contrasena: string;
  end;
  TSolicitudComandoCopiaSeguridad = record
    EsComando: Boolean;
    EsValida: Boolean;
    Error: TErrorComandoCopiaSeguridad;
    RutaDestino: string;
    RutaRegistro: string;
    Contrasena: string;
  end;

function EsComandoCopiaSeguridad(
  const AParametros: TArray<string>
): Boolean;
function EsSintaxisComandoCopiaSeguridadValida(
  const AParametros: TArray<string>
): Boolean;
function ResolverPlantillaCopiaSeguridad(
  const APlantilla: string;
  AInstante: TDateTime
): string;
function CodificarClaveCifradaParaRuta(
  const AClaveCifrada: string
): string;
function ValidarRutaDestinoCopia(
  const ARuta: string
): TErrorComandoCopiaSeguridad;
function InterpretarComandoCopiaSeguridad(
  const AParametros: TArray<string>;
  AInstante: TDateTime;
  const AClavesPredeterminadas:
    TClavesPredeterminadasCopiaSeguridad
): TSolicitudComandoCopiaSeguridad;

implementation

uses
  System.Character,
  System.StrUtils,
  inLibLineaComandos;

const
  CONMUTADOR_COPIA_SEGURIDAD = 'copiaseguridad';
  MARCADOR_CLAVE = 'CLAVE';
  MAXIMA_LONGITUD_RUTA = 259;
  DIAS_SEMANA: array[1..7] of string = (
    'domingo',
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado'
  );

function EsParametroComandoCopiaSeguridad(
  const AParametro: string): Boolean;
begin
  Result := SameText(
    NormalizarConmutador(AParametro),
    CONMUTADOR_COPIA_SEGURIDAD);
end;

function IndiceComandoCopiaSeguridad(
  const AParametros: TArray<string>): Integer;
begin
  Result := -1;
  if (Length(AParametros) > 0) and
     EsParametroComandoCopiaSeguridad(AParametros[0]) then
  begin
    Result := 0;
  end
  else if (Length(AParametros) > 1) and
          EsParametroComandoCopiaSeguridad(AParametros[1]) then
  begin
    Result := 1;
  end;
end;

function ObtenerParametrosComandoCopiaSeguridad(
  const AParametros: TArray<string>): TArray<string>;
var
  iIndice: Integer;
  iIndiceComando: Integer;
begin
  iIndiceComando := IndiceComandoCopiaSeguridad(AParametros);
  if iIndiceComando >= 0 then
  begin
    SetLength(Result, Length(AParametros) - iIndiceComando);
    for iIndice := iIndiceComando to High(AParametros) do
    begin
      Result[iIndice - iIndiceComando] := AParametros[iIndice];
    end;
  end;
end;

function EsComandoCopiaSeguridad(
  const AParametros: TArray<string>): Boolean;
begin
  Result := IndiceComandoCopiaSeguridad(AParametros) >= 0;
end;

function EsSintaxisParametrosComandoValida(
  const AParametros: TArray<string>): Boolean;
begin
  Result := (Length(AParametros) = 2) and
            EsParametroComandoCopiaSeguridad(AParametros[0]);
  if Result then
    Result := Trim(AParametros[1]) <> '';
end;

function EsSintaxisComandoCopiaSeguridadValida(
  const AParametros: TArray<string>): Boolean;
var
  aParametrosComando: TArray<string>;
  iIndiceComando: Integer;
begin
  iIndiceComando := IndiceComandoCopiaSeguridad(AParametros);
  aParametrosComando := ObtenerParametrosComandoCopiaSeguridad(
    AParametros);
  Result := (iIndiceComando >= 0) and
            ((iIndiceComando = 0) or
             EsParametroPerfilValido(AParametros[0]));
  if Result then
  begin
    Result := EsSintaxisParametrosComandoValida(
      aParametrosComando);
  end;
end;

function EsCaracterIdentificador(ACaracter: Char): Boolean;
begin
  Result := ACaracter.IsLetterOrDigit;
end;

function ReemplazarTokenDelimitado(
  const ATexto, AToken, AValor: string): string;
var
  bDelimitadoDespues: Boolean;
  bDelimitadoAntes: Boolean;
  iPosicion: Integer;
  iSiguiente: Integer;
begin
  Result := ATexto;
  iSiguiente := 1;
  iPosicion := PosEx(AToken, Result, iSiguiente);
  while iPosicion > 0 do
  begin
    bDelimitadoAntes := (iPosicion = 1) or
      not EsCaracterIdentificador(Result[iPosicion - 1]);
    bDelimitadoDespues :=
      (iPosicion + Length(AToken) > Length(Result)) or
      not EsCaracterIdentificador(
        Result[iPosicion + Length(AToken)]);
    if bDelimitadoAntes and bDelimitadoDespues then
    begin
      Delete(Result, iPosicion, Length(AToken));
      Insert(AValor, Result, iPosicion);
      iSiguiente := iPosicion + Length(AValor);
    end
    else
      iSiguiente := iPosicion + Length(AToken);
    iPosicion := PosEx(AToken, Result, iSiguiente);
  end;
end;

function ReemplazarToken(
  const ATexto, AToken, AValor: string): string;
begin
  Result := StringReplace(
    ATexto,
    '{' + AToken + '}',
    AValor,
    [rfReplaceAll]);
  Result := ReemplazarTokenDelimitado(
    Result,
    AToken,
    AValor);
end;

function ResolverPlantillaCopiaSeguridad(
  const APlantilla: string;
  AInstante: TDateTime): string;
var
  iAnio: Word;
  iDia: Word;
  iMes: Word;
  sAnio: string;
  sDia: string;
  sDiaSemana: string;
  sMes: string;
begin
  DecodeDate(AInstante, iAnio, iMes, iDia);
  sDiaSemana := DIAS_SEMANA[DayOfWeek(AInstante)];
  sDia := Format('%.2d', [iDia]);
  sMes := Format('%.2d', [iMes]);
  sAnio := Format('%.4d', [iAnio]);
  Result := ReemplazarToken(
    APlantilla,
    'DIASEMANA',
    sDiaSemana);
  Result := ReemplazarToken(Result, 'DIAMES', sDia);
  Result := ReemplazarToken(Result, 'AÑO', sAnio);
  Result := StringReplace(
    Result,
    '{ANO}',
    sAnio,
    [rfReplaceAll]);
  Result := ReemplazarToken(Result, 'MES', sMes);
end;

function CodificarClaveCifradaParaRuta(
  const AClaveCifrada: string): string;
begin
  Result := StringReplace(
    AClaveCifrada,
    '%',
    '%25',
    [rfReplaceAll]);
  Result := StringReplace(Result, '+', '%2B', [rfReplaceAll]);
  Result := StringReplace(Result, '/', '%2F', [rfReplaceAll]);
  Result := StringReplace(Result, '=', '%3D', [rfReplaceAll]);
end;

function DecodificarClaveCifradaDeRuta(
  const AClaveCifrada: string): string;
begin
  Result := ReplaceText(AClaveCifrada, '%3D', '=');
  Result := ReplaceText(Result, '%2F', '/');
  Result := ReplaceText(Result, '%2B', '+');
  Result := ReplaceText(Result, '%25', '%');
end;

function EsCaracterBase64(ACaracter: Char): Boolean;
begin
  Result := CharInSet(
    ACaracter,
    ['A'..'Z', 'a'..'z', '0'..'9', '+', '/', '=']);
end;

function TieneFormatoClaveCifradaRuta(
  const AClaveCifrada: string): Boolean;
var
  bEnRelleno: Boolean;
  cCaracter: Char;
  iIndice: Integer;
  iRelleno: Integer;
  sClaveDecodificada: string;
begin
  sClaveDecodificada := DecodificarClaveCifradaDeRuta(
    AClaveCifrada);
  Result := (Length(sClaveDecodificada) >= 24) and
            (Length(sClaveDecodificada) mod 4 = 0);
  bEnRelleno := False;
  iIndice := 1;
  iRelleno := 0;
  while Result and (iIndice <= Length(sClaveDecodificada)) do
  begin
    cCaracter := sClaveDecodificada[iIndice];
    Result := EsCaracterBase64(cCaracter);
    if Result then
    begin
      if cCaracter = '=' then
      begin
        bEnRelleno := True;
        Inc(iRelleno);
        Result := iRelleno <= 2;
      end
      else if bEnRelleno then
        Result := False;
    end;
    Inc(iIndice);
  end;
end;

function IntentarExtraerMarcadorClave(
  const ARuta: string;
  out ARutaRegistro: string): Boolean;
var
  iFinMarcador: Integer;
  sMarcador: string;
  sNombre: string;
  sNombreRegistro: string;
begin
  sMarcador := '';
  ARutaRegistro := ARuta;
  Result := False;
  sNombre := ExtractFileName(ARuta);
  if (sNombre <> '') and (sNombre[1] = '_') then
  begin
    iFinMarcador := PosEx('_', sNombre, 2);
    Result := iFinMarcador > 2;
    if Result then
    begin
      sMarcador := Copy(sNombre, 2, iFinMarcador - 2);
      Result := TieneFormatoClaveCifradaRuta(sMarcador);
      if Result then
      begin
        sNombreRegistro := '_***_' +
          Copy(sNombre, iFinMarcador + 1, MaxInt);
        ARutaRegistro := ExtractFilePath(ARuta) +
          sNombreRegistro;
      end
    end;
  end;
end;

function SustituirMarcadorClave(
  const ARuta, AClaveCifrada: string): string;
var
  iFinMarcador: Integer;
  sNombre: string;
begin
  sNombre := ExtractFileName(ARuta);
  iFinMarcador := PosEx('_', sNombre, 2);
  Result := ExtractFilePath(ARuta) + '_' +
    CodificarClaveCifradaParaRuta(AClaveCifrada) + '_' +
    Copy(sNombre, iFinMarcador + 1, MaxInt);
end;

function ContieneCaracterRutaNoValido(const ARuta: string): Boolean;
var
  cCaracter: Char;
  iIndice: Integer;
begin
  Result := False;
  for iIndice := 1 to Length(ARuta) do
  begin
    cCaracter := ARuta[iIndice];
    if (Ord(cCaracter) < 32) or
       CharInSet(cCaracter, ['<', '>', '"', '|', '?', '*', '/']) then
    begin
      Result := True;
    end;
  end;
end;

function EsRutaAbsolutaWindows(const ARuta: string): Boolean;
var
  bRutaUnidad: Boolean;
  bRutaUnc: Boolean;
  iFinRecurso: Integer;
  iFinServidor: Integer;
  sRutaUnc: string;
begin
  bRutaUnidad := (Length(ARuta) >= 3) and
    CharInSet(UpCase(ARuta[1]), ['A'..'Z']) and
    (ARuta[2] = ':') and IsPathDelimiter(ARuta, 3);
  bRutaUnc := StartsText('\\', ARuta) and
    not StartsText('\\?\', ARuta) and
    not StartsText('\\.\', ARuta);
  if bRutaUnc then
  begin
    sRutaUnc := Copy(ARuta, 3, MaxInt);
    iFinServidor := Pos('\', sRutaUnc);
    bRutaUnc := iFinServidor > 1;
    if bRutaUnc then
    begin
      Delete(sRutaUnc, 1, iFinServidor);
      iFinRecurso := Pos('\', sRutaUnc);
      bRutaUnc := (iFinRecurso > 1) and
                  (iFinRecurso < Length(sRutaUnc));
    end;
  end;
  Result := bRutaUnidad or bRutaUnc;
end;

function ContieneFlujoAlternativo(const ARuta: string): Boolean;
var
  sRutaSinUnidad: string;
begin
  sRutaSinUnidad := ARuta;
  if (Length(sRutaSinUnidad) >= 2) and
     (sRutaSinUnidad[2] = ':') then
  begin
    Delete(sRutaSinUnidad, 1, 2);
  end;
  Result := Pos(':', sRutaSinUnidad) > 0;
end;

function ValidarRutaDestinoCopia(
  const ARuta: string): TErrorComandoCopiaSeguridad;
var
  sDirectorio: string;
  sNombre: string;
begin
  Result := eccsNinguno;
  sDirectorio := ExtractFilePath(ARuta);
  sNombre := ExtractFileName(ARuta);
  if (ARuta = '') or
     (sDirectorio = '') or
     (sNombre = '') or
     (Length(ARuta) > MAXIMA_LONGITUD_RUTA) or
     (Length(sNombre) > 255) or
     not EsRutaAbsolutaWindows(ARuta) or
     ContieneCaracterRutaNoValido(ARuta) or
     ContieneFlujoAlternativo(ARuta) then
  begin
    Result := eccsRuta;
  end
  else if not SameText(ExtractFileExt(ARuta), '.crypt') then
    Result := eccsExtension;
end;

procedure AplicarMarcadorLiteral(
  const AClavePredeterminada: string;
  var ASolicitud: TSolicitudComandoCopiaSeguridad;
  out AClaveCifrada: string);
begin
  AClaveCifrada := AClavePredeterminada;
  if (ASolicitud.Contrasena <> '') and
     (AClaveCifrada <> '') then
  begin
    ASolicitud.RutaDestino := ReemplazarToken(
      ASolicitud.RutaDestino,
      MARCADOR_CLAVE,
      CodificarClaveCifradaParaRuta(AClaveCifrada));
  end;
end;

procedure AplicarMarcadorCifrado(
  const AClavePredeterminada: string;
  var ASolicitud: TSolicitudComandoCopiaSeguridad;
  out AClaveCifrada: string);
begin
  AClaveCifrada := AClavePredeterminada;
  if (ASolicitud.Contrasena <> '') and
     (AClaveCifrada <> '') then
  begin
    ASolicitud.RutaDestino := SustituirMarcadorClave(
      ASolicitud.RutaDestino,
      AClaveCifrada);
  end;
end;

procedure ResolverClaveSolicitud(
  const AClavesPredeterminadas:
    TClavesPredeterminadasCopiaSeguridad;
  var ASolicitud: TSolicitudComandoCopiaSeguridad);
var
  bMarcadorLiteral: Boolean;
  bTieneMarcador: Boolean;
  sClaveCifrada: string;
  sRutaRegistroLiteral: string;
begin
  ASolicitud.Contrasena := AClavesPredeterminadas.Contrasena;
  sRutaRegistroLiteral := ReemplazarToken(
    ASolicitud.RutaDestino,
    MARCADOR_CLAVE,
    '***');
  bMarcadorLiteral :=
    sRutaRegistroLiteral <> ASolicitud.RutaDestino;
  bTieneMarcador := False;
  if bMarcadorLiteral then
    ASolicitud.RutaRegistro := sRutaRegistroLiteral
  else
  begin
    bTieneMarcador := IntentarExtraerMarcadorClave(
      ASolicitud.RutaDestino,
      ASolicitud.RutaRegistro);
  end;
  sClaveCifrada := '';
  if bMarcadorLiteral then
  begin
    AplicarMarcadorLiteral(
      AClavesPredeterminadas.ClaveCifrada,
      ASolicitud,
      sClaveCifrada);
  end
  else if bTieneMarcador then
  begin
    AplicarMarcadorCifrado(
      AClavesPredeterminadas.ClaveCifrada,
      ASolicitud,
      sClaveCifrada);
  end;
  if ASolicitud.Contrasena = '' then
    ASolicitud.Error := eccsClave;
  if (bMarcadorLiteral or bTieneMarcador) and
     (sClaveCifrada = '') then
    ASolicitud.Error := eccsClave;
end;

function InterpretarComandoCopiaSeguridad(
  const AParametros: TArray<string>;
  AInstante: TDateTime;
  const AClavesPredeterminadas:
    TClavesPredeterminadasCopiaSeguridad
): TSolicitudComandoCopiaSeguridad;
var
  aParametrosComando: TArray<string>;
begin
  Result := Default(TSolicitudComandoCopiaSeguridad);
  Result.EsComando := EsComandoCopiaSeguridad(AParametros);
  if Result.EsComando then
  begin
    aParametrosComando := ObtenerParametrosComandoCopiaSeguridad(
      AParametros);
    if EsSintaxisComandoCopiaSeguridadValida(AParametros) then
    begin
      Result.RutaDestino := ResolverPlantillaCopiaSeguridad(
        Trim(aParametrosComando[1]),
        AInstante);
      Result.RutaRegistro := Result.RutaDestino;
      ResolverClaveSolicitud(
        AClavesPredeterminadas,
        Result);
      if Result.Error = eccsNinguno then
        Result.Error := ValidarRutaDestinoCopia(Result.RutaDestino);
      Result.EsValida := Result.Error = eccsNinguno;
    end
    else
      Result.Error := eccsSintaxis;
  end;
end;

end.
