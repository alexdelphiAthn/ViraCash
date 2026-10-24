{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGeneradorEsquemaIdeal                                    }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Esquema ideal de Ayuda > Comprobar integridad: carga el modelo en         }
{    MariaDB 12, MariaDB 10 y MySQL 8 de usar y tirar, lee el catálogo con     }
{    el mismo lector que ViraCash (UniDataHuellaEsquema) y deja el JSON y      }
{    el recurso HUELLA_ESQUEMA que enlaza inLibHuellaEsquemaRecurso.           }
{******************************************************************************}
unit inLibGeneradorEsquemaIdeal;

interface

uses
  System.SysUtils,
  inLibHuellaEsquemaIntf,
  inLibServidorDesechable;

type
  TBinariosMotores = array[TMotorDesechable] of string;

  TOpcionesGenerador = record
    Json: string;
    Recurso: string;
    Modelo: string;
    Scripts: TArray<string>;
    Comparador: string;
    Binarios: TBinariosMotores;
    // MSI de MariaDB 10 que se desempaqueta (msiexec /a) si no hay
    // binarios de MariaDB 10.
    InstaladorMariaDB10: string;
  end;

  TRegistroGenerador = reference to procedure(const ATexto: string);

const
  cRecursoHuellaEsquemaGenerado = 'HUELLA_ESQUEMA';
  cSalidaDesfasado = 3;

// '' si el JSON (y el recurso) son del modelo y los scripts de ahora y de
// esta versión de la huella; si no, el porqué.
function MotivoDesfaseEsquemaIdeal(
  const AOpciones: TOpcionesGenerador): string;
procedure GenerarEsquemaIdeal(
  const AOpciones: TOpcionesGenerador;
  const ARegistrar: TRegistroGenerador);
// Recompila solo el recurso a partir del JSON que ya hay.
procedure CompilarRecursoEsquemaIdeal(const AOpciones: TOpcionesGenerador);
function JsonEsquemaIdeal(
  const AOpciones: TOpcionesGenerador;
  const AComunes: TElementosHuella;
  const ACodigo: array of TElementosHuella): string;
function Sha256Fichero(const ARuta: string): string;

const
  cMotivoSoloRecurso = 'falta compilar el recurso';

implementation

uses
  System.Classes,
  System.IOUtils,
  System.Hash,
  System.JSON,
  System.Threading,
  System.DateUtils,
  Uni,
  inLibHuellaEsquema,
  inLibMotorBaseDatos,
  inLibRecursoRcdata,
  UniDataHuellaEsquema;

const
  cBaseModelo = 'fza_esquema_ideal';
  cDestinoComparador: array[TMotorDesechable] of string = (
    '',
    'mariadb10',
    'mysql841');
  cMotorBaseDatos: array[TMotorDesechable] of TMotorBaseDatos = (
    mbdMariaDB1213,
    mbdMariaDB1014,
    mbdMySQL8041);

function Sha256Fichero(const ARuta: string): string;
begin
  Result := THashSHA2.GetHashStringFromFile(ARuta,
                                            THashSHA2.TSHA2Version.SHA256);
end;

function ShaScripts(const AScripts: TArray<string>): TArray<string>;
var
  sScript: string;
begin
  Result := nil;
  for sScript in AScripts do
    Result := Result + [Sha256Fichero(sScript)];
end;

function TextoLista(const AValores: TArray<string>): string;
begin
  Result := string.Join(#1, AValores);
end;

function LeerListaJson(ADatos: TJSONObject; const ANombre: string):
  TArray<string>;
var
  oValor: TJSONValue;
begin
  Result := nil;
  if ADatos.GetValue(ANombre) is TJSONArray then
  begin
    for oValor in TJSONArray(ADatos.GetValue(ANombre)) do
      Result := Result + [oValor.Value];
  end;
end;

function MotivoDesfaseJson(
  ADatos: TJSONObject;
  const AOpciones: TOpcionesGenerador): string;
begin
  Result := '';
  if ADatos.GetValue<Integer>('version_huella', 0) <>
     cVersionEsquemaIdeal then
    Result := 'es de otra versión de la huella'
  else if ADatos.GetValue<string>('sha256_modelo', '') <>
          Sha256Fichero(AOpciones.Modelo) then
    Result := 'el modelo ' + AOpciones.Modelo + ' ha cambiado'
  else if TextoLista(LeerListaJson(ADatos, 'sha256_scripts')) <>
          TextoLista(ShaScripts(AOpciones.Scripts)) then
    Result := 'han cambiado los scripts aplicados sobre el modelo';
end;

function MotivoDesfaseEsquemaIdeal(
  const AOpciones: TOpcionesGenerador): string;
var
  oDatos: TJSONValue;
begin
  if not FileExists(AOpciones.Json) then
    Result := 'no existe ' + AOpciones.Json
  else
  begin
    oDatos := TJSONObject.ParseJSONValue(
      TFile.ReadAllText(AOpciones.Json, TEncoding.UTF8));
    try
      if not (oDatos is TJSONObject) then
        Result := AOpciones.Json + ' no es un JSON válido'
      else
        Result := MotivoDesfaseJson(TJSONObject(oDatos), AOpciones);
    finally
      oDatos.Free;
    end;
  end;
  if (Result = '') and (AOpciones.Recurso <> '') and
     (not FileExists(AOpciones.Recurso) or
      (TFile.GetLastWriteTime(AOpciones.Recurso) <
       TFile.GetLastWriteTime(AOpciones.Json))) then
    Result := cMotivoSoloRecurso;
end;

procedure CompilarRecursoEsquemaIdeal(const AOpciones: TOpcionesGenerador);
begin
  EscribirRecursoRcdata(AOpciones.Recurso, cRecursoHuellaEsquemaGenerado,
                        TFile.ReadAllBytes(AOpciones.Json));
end;

function ListaJsonTexto(const AValores: TArray<string>): string;
var
  sValor: string;
begin
  Result := '';
  for sValor in AValores do
  begin
    if Result <> '' then
      Result := Result + ',';
    Result := Result + CitarJson(sValor);
  end;
  Result := '[' + Result + ']';
end;

function NombresScripts(const AScripts: TArray<string>): TArray<string>;
var
  sScript: string;
begin
  Result := nil;
  for sScript in AScripts do
    Result := Result + [ExtractFileName(sScript)];
end;

function JsonEsquemaIdeal(
  const AOpciones: TOpcionesGenerador;
  const AComunes: TElementosHuella;
  const ACodigo: array of TElementosHuella): string;
var
  oTexto: TStringBuilder;
  oHuellas: THuellasEsquema;
  eApartado: TApartadoHuella;
  eMotor: TMotorDesechable;
begin
  oHuellas := CalcularHuellas(AComunes);
  oTexto := TStringBuilder.Create;
  try
    oTexto.Append('{"version_huella":').Append(cVersionEsquemaIdeal);
    oTexto.Append(',"modelo":').Append(
      CitarJson(ExtractFileName(AOpciones.Modelo)));
    oTexto.Append(',"sha256_modelo":').Append(
      CitarJson(Sha256Fichero(AOpciones.Modelo)));
    oTexto.Append(',"scripts":').Append(
      ListaJsonTexto(NombresScripts(AOpciones.Scripts)));
    oTexto.Append(',"sha256_scripts":').Append(
      ListaJsonTexto(ShaScripts(AOpciones.Scripts)));
    oTexto.Append(',"generado":').Append(
      CitarJson(FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss', Now)));
    oTexto.Append(',"huellas":{"GLOBAL":').Append(CitarJson(oHuellas.Global));
    for eApartado := Low(TApartadoHuella) to High(TApartadoHuella) do
    begin
      if eApartado <> ahCodigo then
        oTexto.Append(',').Append(CitarJson(TextoApartadoHuella(eApartado)))
          .Append(':').Append(CitarJson(oHuellas.Apartados[eApartado]));
    end;
    oTexto.Append('},"elementos":{');
    for eApartado := Low(TApartadoHuella) to High(TApartadoHuella) do
    begin
      if eApartado <> ahCodigo then
      begin
        if eApartado <> Low(TApartadoHuella) then
          oTexto.Append(',');
        oTexto.Append(CitarJson(TextoApartadoHuella(eApartado))).Append(':')
          .Append(JsonCanonicoApartado(AComunes, eApartado));
      end;
    end;
    oTexto.Append('},"codigo":{');
    for eMotor := Low(TMotorDesechable) to High(TMotorDesechable) do
    begin
      if eMotor <> Low(TMotorDesechable) then
        oTexto.Append(',');
      oTexto.Append(CitarJson(TextoMotorBaseDatos(cMotorBaseDatos[eMotor])))
        .Append(':{"huella":')
        .Append(CitarJson(CalcularHuellas(ACodigo[Ord(eMotor)])
                  .Apartados[ahCodigo]))
        .Append(',"elementos":')
        .Append(JsonCanonicoApartado(ACodigo[Ord(eMotor)], ahCodigo))
        .Append('}');
    end;
    oTexto.Append('}}');
    Result := oTexto.ToString;
  finally
    oTexto.Free;
  end;
end;

{ Generación }

function BinariosMariaDB10(
  const AOpciones: TOpcionesGenerador;
  const ARaiz: string): string;
var
  sDestino, sPrograma: string;
begin
  Result := AOpciones.Binarios[mdMariaDB10];
  if (Result = '') or not DirectoryExists(Result) then
  begin
    if not FileExists(AOpciones.InstaladorMariaDB10) then
      raise EServidorDesechable.Create('No hay binarios de MariaDB 10 ni ' +
        'instalador que desempaquetar: ' + AOpciones.InstaladorMariaDB10);
    // msiexec /a solo desempaqueta: ni instala ni toca el registro.
    sDestino := TPath.Combine(ARaiz, 'mariadb10_bin');
    if EjecutarProceso(Format('msiexec /a "%s" /qn TARGETDIR="%s"',
                              [AOpciones.InstaladorMariaDB10, sDestino]),
                       ARaiz, '', TPath.Combine(ARaiz, 'msiexec.log')) <> 0 then
      raise EServidorDesechable.Create('No se pudo desempaquetar ' +
                                       AOpciones.InstaladorMariaDB10);
    Result := '';
    for sPrograma in TDirectory.GetFiles(sDestino, 'mysqld.exe',
                                         TSearchOption.soAllDirectories) do
      Result := ExtractFilePath(sPrograma);
    if Result = '' then
      raise EServidorDesechable.Create('El instalador de MariaDB 10 no ' +
                                       'trae mysqld.exe');
  end;
end;

function Convertir(
  const AOpciones: TOpcionesGenerador;
  AMotor: TMotorDesechable;
  const AOrigen, ACarpeta: string): string;
var
  sSalida: string;
begin
  // El modelo y los scripts son de MariaDB 12; para los otros motores los
  // convierte DBComparer, como hace el actualizador.
  Result := AOrigen;
  if cDestinoComparador[AMotor] <> '' then
  begin
    Result := TPath.Combine(ACarpeta, ExtractFileName(AOrigen));
    sSalida := TPath.Combine(ACarpeta, 'convertir_' +
                             ExtractFileName(AOrigen) + '.log');
    if EjecutarProceso(
         Format('"%s" --convertir "%s" "%s" --destino=%s',
                [AOpciones.Comparador, AOrigen, Result,
                 cDestinoComparador[AMotor]]),
         ACarpeta, '', sSalida) <> 0 then
      raise EServidorDesechable.CreateFmt(
        'DBComparer no pudo convertir %s a %s (ver %s)',
        [ExtractFileName(AOrigen), cDestinoComparador[AMotor], sSalida]);
  end;
end;

function LeerMotor(
  const AOpciones: TOpcionesGenerador;
  AMotor: TMotorDesechable;
  const ABinarios, ARaiz: string): TElementosHuella;
var
  oServidor: TServidorDesechable;
  oConexion: TUniConnection;
  sScript: string;
begin
  oServidor := TServidorDesechable.Create(AMotor, ABinarios, ARaiz);
  try
    oServidor.Arrancar;
    oServidor.CrearBase(cBaseModelo);
    oServidor.CargarScript(Convertir(AOpciones, AMotor, AOpciones.Modelo,
                                     ARaiz), cBaseModelo);
    for sScript in AOpciones.Scripts do
      oServidor.CargarScript(Convertir(AOpciones, AMotor, sScript, ARaiz),
                             cBaseModelo);
    oConexion := oServidor.Conectar(cBaseModelo);
    try
      Result := CrearLectorCatalogoEsquemaUniDAC(oConexion).LeerElementos;
    finally
      oConexion.Free;
    end;
  finally
    oServidor.Free;
  end;
end;

type
  TElementosMotores = array[TMotorDesechable] of TElementosHuella;

  // Lo que deja cada tarea; cada una escribe solo en su motor.
  TLeidosMotores = class
  public
    Elementos: TElementosMotores;
  end;

function LanzarMotor(
  const AOpciones: TOpcionesGenerador;
  AMotor: TMotorDesechable;
  const ABinarios, ARaiz: string;
  ALeidos: TLeidosMotores): ITask;
var
  oOpciones: TOpcionesGenerador;
  sBinarios, sRaiz: string;
begin
  // Copias locales: la tarea no puede capturar parámetros const.
  oOpciones := AOpciones;
  sBinarios := ABinarios;
  sRaiz := ARaiz;
  Result := TTask.Run(
    procedure
    begin
      ALeidos.Elementos[AMotor] := LeerMotor(oOpciones, AMotor, sBinarios,
                                             sRaiz);
    end);
end;

function SinApartado(
  const AElementos: TElementosHuella;
  AApartado: TApartadoHuella;
  ASoloEse: Boolean): TElementosHuella;
var
  oElemento: TElementoHuella;
  oLista: TArray<TElementoHuella>;
begin
  oLista := nil;
  for oElemento in AElementos do
  begin
    if (oElemento.Apartado = AApartado) = ASoloEse then
      oLista := oLista + [oElemento];
  end;
  Result := oLista;
end;

procedure ComprobarComunes(const AElementos: array of TElementosHuella);
var
  eMotor: TMotorDesechable;
  sGlobal: string;
begin
  // La parte común tiene que ser la misma en los tres motores: si no, el
  // programa daría diferencias falsas según dónde esté la base.
  sGlobal := CalcularHuellas(AElementos[0]).Global;
  for eMotor := Succ(Low(TMotorDesechable)) to High(TMotorDesechable) do
  begin
    if CalcularHuellas(AElementos[Ord(eMotor)]).Global <> sGlobal then
      raise EServidorDesechable.CreateFmt(
        '%s no da la misma huella común que MariaDB 12',
        [TextoMotorDesechable(eMotor)]);
  end;
end;

procedure GenerarEsquemaIdeal(
  const AOpciones: TOpcionesGenerador;
  const ARegistrar: TRegistroGenerador);
var
  sRaiz, sJson: string;
  aBinarios: TBinariosMotores;
  aLeidos: TElementosMotores;
  aCodigo: TElementosMotores;
  aTareas: array[TMotorDesechable] of ITask;
  eMotor: TMotorDesechable;
  oLeidos: TLeidosMotores;
begin
  sRaiz := TPath.Combine(TPath.GetTempPath,
                         'viracash-esquema-ideal-' +
                         TGUID.NewGuid.ToString.Substring(1, 8));
  TDirectory.CreateDirectory(sRaiz);
  try
    aBinarios := AOpciones.Binarios;
    aBinarios[mdMariaDB10] := BinariosMariaDB10(AOpciones, sRaiz);
    oLeidos := TLeidosMotores.Create;
    try
      for eMotor := Low(TMotorDesechable) to High(TMotorDesechable) do
      begin
        ARegistrar('Cargando el modelo en ' + TextoMotorDesechable(eMotor) +
                   '...');
        aTareas[eMotor] := LanzarMotor(
          AOpciones, eMotor, aBinarios[eMotor],
          TPath.Combine(sRaiz,
                        TextoMotorDesechable(eMotor).Replace(' ', '')),
          oLeidos);
      end;
      TTask.WaitForAll(aTareas);
      aLeidos := oLeidos.Elementos;
    finally
      oLeidos.Free;
    end;
    for eMotor := Low(TMotorDesechable) to High(TMotorDesechable) do
      aCodigo[eMotor] := SinApartado(aLeidos[eMotor], ahCodigo, True);
    ComprobarComunes([SinApartado(aLeidos[mdMariaDB12], ahCodigo, False),
                      SinApartado(aLeidos[mdMariaDB10], ahCodigo, False),
                      SinApartado(aLeidos[mdMySQL8], ahCodigo, False)]);
    sJson := JsonEsquemaIdeal(
      AOpciones, SinApartado(aLeidos[mdMariaDB12], ahCodigo, False),
      [aCodigo[mdMariaDB12], aCodigo[mdMariaDB10], aCodigo[mdMySQL8]]);
    // Sin BOM: es lo que lee TEsquemaIdeal desde el recurso.
    TFile.WriteAllBytes(AOpciones.Json, TEncoding.UTF8.GetBytes(sJson));
    ARegistrar(Format('Esquema ideal: %d elementos, GLOBAL %s -> %s',
      [Length(aLeidos[mdMariaDB12]) - Length(aCodigo[mdMariaDB12]),
       Copy(CalcularHuellas(aLeidos[mdMariaDB12]).Global, 1, 12),
       AOpciones.Json]));
    if AOpciones.Recurso <> '' then
    begin
      CompilarRecursoEsquemaIdeal(AOpciones);
      ARegistrar('Recurso ' + cRecursoHuellaEsquemaGenerado + ' -> ' +
                 AOpciones.Recurso);
    end;
  except
    // Si algo falla, los registros de los servidores se quedan para verlos.
    ARegistrar('Registros de los servidores en ' + sRaiz);
    raise;
  end;
  TDirectory.Delete(sRaiz, True);
end;

end.
