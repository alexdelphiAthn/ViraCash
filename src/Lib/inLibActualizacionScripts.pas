{******************************************************************************}
{                                                                              }
{  Módulo:       inLibActualizacionScripts                                     }
{    Tipo:       Servicio                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       18/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Averigua qué scripts de esquema faltan en esta base y los aplica.         }
{******************************************************************************}
unit inLibActualizacionScripts;

interface

uses
  Uni,
  inLibActualizacionScriptsLectura;

type
  TScriptFaltante = inLibActualizacionScriptsLectura.TScriptFaltante;

  // La comprobación recorre INFORMATION_SCHEMA entero y en una base grande
  // son minutos: corre en un hilo y otro la corta. Ejecutar se llama desde
  // el hilo de trabajo; Cancelar, desde el que mira el botón.
  IConsultaScriptsFaltantes = interface
    ['{5E0B1F0A-6C0D-4B7E-8E55-3B0C6B1D9A42}']
    function Ejecutar(
      out AFaltantes: TArray<TScriptFaltante>;
      out AError: string): Boolean;
    // Se puede llamar las veces que haga falta: corta la sentencia en
    // curso y, si todavía no había empezado, lo reintenta más tarde.
    procedure Cancelar;
    function Cancelada: Boolean;
    function Aplicados: TArray<string>;
  end;

// Lee un .sql sin dar por hecho que viene en UTF-8: los scripts antiguos
// pueden estar en la pagina de codigos del equipo.
function LeerTextoScriptSql(const ARuta: string): string;
function CrearConsultaScriptsFaltantes(
  AConexion: TUniConnection;
  const ASqlComprobacion: string): IConsultaScriptsFaltantes;
// Ejecuta el contenido de ARutaSql comprobando antes su huella SHA-256.
function EjecutarScriptActualizacion(
  AConexion: TUniConnection;
  const ARutaSql, ASha256: string;
  out AError: string): Boolean;

implementation

uses
  System.Classes,
  System.Hash,
  System.IOUtils,
  System.SyncObjs,
  System.SysUtils,
  Data.DB,
  inLibMsgIntegraciones;

const
  // Entre dos intentos de cortar la sentencia: el primero puede llegar
  // antes de que el servidor haya empezado a ejecutarla.
  cEsperaReintentoCancelacionMs = 1000;

type
  TConsultaScriptsFaltantes = class(
    TInterfacedObject,
    IConsultaScriptsFaltantes)
  private
    FCancelada: Integer;
    FAplicados: TArray<string>;
    FConexion: TUniConnection;
    FConsulta: TUniQuery;
    FSeccion: TCriticalSection;
    FSql: string;
    FUltimoCorte: UInt64;
    procedure AnotarConsulta(AConsulta: TUniQuery);
    function ComprobarDatos(const ASql: string): Boolean;
  public
    constructor Create(
      AConexion: TUniConnection;
      const ASqlComprobacion: string);
    destructor Destroy; override;
    function Ejecutar(
      out AFaltantes: TArray<TScriptFaltante>;
      out AError: string): Boolean;
    procedure Cancelar;
    function Cancelada: Boolean;
    function Aplicados: TArray<string>;
  end;

function LeerTextoScriptSql(const ARuta: string): string;
var
  aDatos: TBytes;
  iPreambulo: Integer;
  oCodificacion: TEncoding;
begin
  aDatos := TFile.ReadAllBytes(ARuta);
  oCodificacion := nil;
  iPreambulo := TEncoding.GetBufferEncoding(
    aDatos,
    oCodificacion,
    TEncoding.UTF8);
  try
    Result := oCodificacion.GetString(
      aDatos,
      iPreambulo,
      Length(aDatos) - iPreambulo);
  except
    on E: EEncodingError do
      Result := TEncoding.ANSI.GetString(aDatos);
  end;
end;

{ TConsultaScriptsFaltantes }

constructor TConsultaScriptsFaltantes.Create(
  AConexion: TUniConnection;
  const ASqlComprobacion: string);
begin
  inherited Create;
  FConexion := AConexion;
  FSql := ASqlComprobacion;
  FSeccion := TCriticalSection.Create;
end;

destructor TConsultaScriptsFaltantes.Destroy;
begin
  FSeccion.Free;
  inherited Destroy;
end;

// El hilo que cancela usa la consulta dentro de la misma sección, así que
// el de trabajo no puede liberarla mientras la están cortando.
procedure TConsultaScriptsFaltantes.AnotarConsulta(AConsulta: TUniQuery);
begin
  FSeccion.Enter;
  try
    FConsulta := AConsulta;
  finally
    FSeccion.Leave;
  end;
end;

function TConsultaScriptsFaltantes.ComprobarDatos(
  const ASql: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  if Cancelada then
    raise EAbort.Create(SInfoComprobacionScriptsCancelada);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    AnotarConsulta(oConsulta);
    oConsulta.Open;
    Result := not oConsulta.IsEmpty and
      not oConsulta.Fields[0].IsNull and
      (oConsulta.Fields[0].AsInteger = 1);
  finally
    AnotarConsulta(nil);
    oConsulta.Free;
  end;
end;

function TConsultaScriptsFaltantes.Ejecutar(
  out AFaltantes: TArray<TScriptFaltante>;
  out AError: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  Result := False;
  AFaltantes := nil;
  FAplicados := nil;
  AError := '';
  if not Assigned(FConexion) then
    AError := SErrorConexionActualizacionNoDisponible
  else if Trim(FSql) = '' then
    AError := SErrorComprobacionScriptsVacia
  else if not Cancelada then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text := FSql;
        AnotarConsulta(oConsulta);
        oConsulta.Open;
        // Materializar las filas antes de abrir consultas de datos en
        // la misma conexion. El lector vuelve a la primera fila.
        oConsulta.Last;
        AnotarConsulta(nil);
        AFaltantes := LeerScriptsFaltantes(oConsulta,
          function(ASql: string): Boolean
          begin
            Result := ComprobarDatos(ASql);
          end,
          procedure(ANombre: string)
          begin
            FAplicados := FAplicados + [ANombre];
          end);
        Result := not Cancelada;
      except
        on E: Exception do
          AError := E.ClassName + ': ' + E.Message;
      end;
    finally
      AnotarConsulta(nil);
      oConsulta.Free;
    end;
  end;
end;

procedure TConsultaScriptsFaltantes.Cancelar;
var
  iAhora: UInt64;
begin
  AtomicExchange(FCancelada, 1);
  iAhora := TThread.GetTickCount64;
  FSeccion.Enter;
  try
    if Assigned(FConsulta) and
       ((FUltimoCorte = 0) or
        (iAhora - FUltimoCorte >= cEsperaReintentoCancelacionMs)) then
    begin
      FUltimoCorte := iAhora;
      try
        FConsulta.BreakExec;
      except
        // No se ha podido cortar ahora: se reintenta en la siguiente
        // llamada. Quien espera no puede quedarse sin su bucle por esto.
        on E: Exception do
          FUltimoCorte := iAhora;
      end;
    end;
  finally
    FSeccion.Leave;
  end;
end;

function TConsultaScriptsFaltantes.Aplicados: TArray<string>;
begin
  Result := Copy(FAplicados);
end;

function TConsultaScriptsFaltantes.Cancelada: Boolean;
begin
  Result := AtomicCmpExchange(FCancelada, 0, 0) <> 0;
end;

function CrearConsultaScriptsFaltantes(
  AConexion: TUniConnection;
  const ASqlComprobacion: string): IConsultaScriptsFaltantes;
begin
  Result := TConsultaScriptsFaltantes.Create(AConexion, ASqlComprobacion);
end;

procedure ActualizarEstadoLineaSql(const ALinea: string;
  var AComilla: Char; var AComentarioBloque: Boolean);
var
  iPosicion: Integer;
  cActual: Char;
  cSiguiente: Char;
begin
  iPosicion := 1;
  while iPosicion <= Length(ALinea) do
  begin
    cActual := ALinea[iPosicion];
    cSiguiente := #0;
    if iPosicion < Length(ALinea) then
      cSiguiente := ALinea[iPosicion + 1];
    if AComentarioBloque then
    begin
      if (cActual = '*') and (cSiguiente = '/') then
      begin
        AComentarioBloque := False;
        Inc(iPosicion);
      end;
    end
    else if AComilla <> #0 then
    begin
      if (cActual = '\') and (AComilla <> '`') then
        Inc(iPosicion)
      else if cActual = AComilla then
      begin
        if cSiguiente = AComilla then
          Inc(iPosicion)
        else
          AComilla := #0;
      end;
    end
    else if CharInSet(cActual, ['''', '"', '`']) then
      AComilla := cActual
    else if (cActual = '/') and (cSiguiente = '*') then
    begin
      AComentarioBloque := True;
      Inc(iPosicion);
    end
    else if (cActual = '#') or
      ((cActual = '-') and (cSiguiente = '-') and
       ((iPosicion + 1 = Length(ALinea)) or
        CharInSet(ALinea[iPosicion + 2], [' ', #9]))) then
      iPosicion := Length(ALinea);
    Inc(iPosicion);
  end;
end;

// Enviar las sentencias completas evita que UniScript vuelva a interpretar
// BEGIN/END y recorte los procedimientos. Los errores llegan al proceso
// sin abrir cuadros de mensaje desde el hilo trabajador.
procedure EjecutarSentenciasSql(AConexion: TUniConnection;
  const AContenido, ADelimitador: string);
var
  oConsulta: TUniQuery;
  oSentencia: TStringBuilder;
  iPosicion: Integer;
  cActual, cSiguiente, cComilla: Char;
  bComentarioLinea, bComentarioBloque, bTieneCodigo: Boolean;

  procedure EnviarSentencia;
  begin
    if bTieneCodigo then
    begin
      oConsulta.SQL.Text := oSentencia.ToString;
      oConsulta.ExecSQL;
    end;
    oSentencia.Clear;
    bTieneCodigo := False;
  end;

begin
  oConsulta := TUniQuery.Create(nil);
  oSentencia := TStringBuilder.Create;
  try
    oConsulta.Connection := AConexion;
    oConsulta.ParamCheck := False;
    iPosicion := 1;
    cComilla := #0;
    bComentarioLinea := False;
    bComentarioBloque := False;
    bTieneCodigo := False;
    while iPosicion <= Length(AContenido) do
    begin
      cActual := AContenido[iPosicion];
      cSiguiente := #0;
      if iPosicion < Length(AContenido) then
        cSiguiente := AContenido[iPosicion + 1];
      if bComentarioLinea then
      begin
        oSentencia.Append(cActual);
        if CharInSet(cActual, [#10, #13]) then
          bComentarioLinea := False;
      end
      else if bComentarioBloque then
      begin
        oSentencia.Append(cActual);
        if (cActual = '*') and (cSiguiente = '/') then
        begin
          oSentencia.Append(cSiguiente);
          Inc(iPosicion);
          bComentarioBloque := False;
        end;
      end
      else if cComilla <> #0 then
      begin
        oSentencia.Append(cActual);
        if ((cActual = '\') and (cComilla <> '`')) or
           ((cActual = cComilla) and (cSiguiente = cComilla)) then
        begin
          oSentencia.Append(cSiguiente);
          Inc(iPosicion);
        end
        else if cActual = cComilla then
          cComilla := #0;
      end
      else if Copy(AContenido, iPosicion,
        Length(ADelimitador)) = ADelimitador then
      begin
        EnviarSentencia;
        Inc(iPosicion, Length(ADelimitador) - 1);
      end
      else
      begin
        oSentencia.Append(cActual);
        if (cActual = '#') or
           ((cActual = '-') and (cSiguiente = '-') and
            ((iPosicion + 1 = Length(AContenido)) or
             CharInSet(AContenido[iPosicion + 2], [#9, #10, #13, ' ']))) then
          bComentarioLinea := True
        else if (cActual = '/') and (cSiguiente = '*') then
        begin
          oSentencia.Append(cSiguiente);
          Inc(iPosicion);
          bComentarioBloque := True;
          // Los comentarios de versión pueden contener SQL ejecutable.
          if (iPosicion < Length(AContenido)) and
             CharInSet(AContenido[iPosicion + 1], ['!', 'M']) then
            bTieneCodigo := True;
        end
        else
        begin
          if CharInSet(cActual, ['''', '"', '`']) then
            cComilla := cActual;
          if not CharInSet(cActual, [#9, #10, #13, ' ']) then
            bTieneCodigo := True;
        end;
      end;
      Inc(iPosicion);
    end;
    EnviarSentencia;
  finally
    oSentencia.Free;
    oConsulta.Free;
  end;
end;

procedure EjecutarContenidoScript(AConexion: TUniConnection;
  const AContenido: string);
var
  oLineas: TStringList;
  oBloque: TStringBuilder;
  sLinea: string;
  sDirectiva: string;
  sDelimitador: string;
  cComilla: Char;
  bComentarioBloque: Boolean;

  procedure EjecutarBloque;
  begin
    if Trim(oBloque.ToString) <> '' then
    begin
      EjecutarSentenciasSql(AConexion, oBloque.ToString, sDelimitador);
    end;
    oBloque.Clear;
  end;

begin
  oLineas := TStringList.Create;
  oBloque := TStringBuilder.Create;
  try
    oLineas.Text := AContenido;
    sDelimitador := ';';
    cComilla := #0;
    bComentarioBloque := False;
    for sLinea in oLineas do
    begin
      sDirectiva := Trim(sLinea);
      // DELIMITER es una orden del cliente, no una sentencia del servidor.
      // Los literales y comentarios pueden contener esa misma palabra.
      if (cComilla = #0) and not bComentarioBloque and
         (Length(sDirectiva) > 9) and
         SameText(Copy(sDirectiva, 1, 9), 'DELIMITER') and
         CharInSet(sDirectiva[10], [' ', #9]) then
      begin
        EjecutarBloque;
        sDelimitador := Trim(Copy(sDirectiva, 11, MaxInt));
        if sDelimitador = '' then
          raise EArgumentException.Create('DELIMITER sin separador.');
      end
      else
      begin
        oBloque.AppendLine(sLinea);
        ActualizarEstadoLineaSql(sLinea, cComilla, bComentarioBloque);
      end;
    end;
    EjecutarBloque;
  finally
    oBloque.Free;
    oLineas.Free;
  end;
end;

function EjecutarScriptActualizacion(
  AConexion: TUniConnection;
  const ARutaSql, ASha256: string;
  out AError: string): Boolean;
var
  sContenido: string;
  sHuella: string;
begin
  Result := False;
  AError := '';
  if not Assigned(AConexion) then
    AError := SErrorConexionActualizacionNoDisponible
  else if not TFile.Exists(ARutaSql) then
    AError := Format(SErrorScriptActualizacionAusente, [ARutaSql])
  else
  begin
    try
      sHuella := LowerCase(THashSHA2.GetHashStringFromFile(ARutaSql));
      if (Trim(ASha256) <> '') and not SameText(sHuella, Trim(ASha256)) then
        AError := SErrorHuellaScriptActualizacionNoCoincide
      else
      begin
        sContenido := LeerTextoScriptSql(ARutaSql);
        if Trim(sContenido) = '' then
          AError := Format(SErrorScriptActualizacionVacio, [ARutaSql])
        else
        begin
          EjecutarContenidoScript(AConexion, sContenido);
          Result := True;
        end;
      end;
    except
      on E: Exception do
        AError := E.ClassName + ': ' + E.Message;
    end;
  end;
end;

end.
