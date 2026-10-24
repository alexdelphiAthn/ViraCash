{******************************************************************************}
{                                                                              }
{  Módulo:       inLibBuscarImpresora                                          }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Búsqueda y selección de impresoras de caja.                               }
{    Localiza la impresora por patrón y sesión, con caché por usuario.         }
{******************************************************************************}
unit inLibBuscarImpresora;

interface

uses
  Classes, Windows, WinSpool, SysUtils, StrUtils,
  inLibContextoSesionIntf, inLibParametrosIntf;

const
  // Parámetro de aplicación con la impresora de documentos (informes).
  cParametroImpresoraDocumentos = 'appImpresoraInformes';

// Impresora de documentos que debe usar la impresión: la resuelta por
// la detección diferida o, mientras no haya resultado, el valor
// configurado tal cual (un nombre exacto sigue sirviendo; un patrón sin
// resolver provoca el aviso de impresora no disponible en los lotes).
function ImpresoraDocumentosConfigurada(
  const AParametros: IParametrosAplicacion): string;
function ObtenerSesionImpresora(const NombreImpresora: string): string;
function EsImpresoraRedireccionada(const NombreImpresora: string): Boolean;
function BuscarImpresoraPorPatrones(const Patrones: string): string;
// FZ-ISSUE-099: resuelve un nombre exacto o un patrón (subcadenas
// separadas por ';', todas presentes) contra la lista dada (p. ej. la de
// FastReport). Cadena vacía si no hay coincidencia o el valor es DEBUG.
function BuscarImpresoraEnLista(
  const APatrones: string;
  AImpresoras: TStrings): string;
function ObtenerListaImpresoras: TStringList;
function SepararSubcadenas(const Cadena: string): TStringList;
function ObtenerNombreImpresoraPorCaja(Empresa, Almacen, Caja: Integer;
                                       ArchivoINI: string;
                                       const AContextoSesion:
                                       IContextoSesionAplicacion;
                                       out ModoImpresion: string): string;
function ExtraerSesionDeImpresora(const NombreImpresora: string): string;
function EsImpresoraRed(const NombreImpresora: string): Boolean;
function ObtenerImpresoraPorPatronCached(const PatronBusqueda,
                                               ArchivoCache: string): string;
function GetImpresoraCaja(
  const AParametrosCaja: IParametrosCaja;
  const AContextoSesion: IContextoSesionAplicacion): string;

implementation

function ImpresoraDocumentosConfigurada(
  const AParametros: IParametrosAplicacion): string;
begin
  Result := '';
  if Assigned(AParametros) then
  begin
    Result := Trim(AParametros.ImpresoraDocumentos);
    if Result = '' then
      Result := Trim(
        AParametros.GetString(cParametroImpresoraDocumentos, ''));
  end;
end;

function EstaImpresoraDisponible(const ANombreImpresora: string): Boolean;
var
  oImpresoras: TStringList;
begin
  Result := not SameText(ANombreImpresora, 'DEBUG');
  if Result then
  begin
    oImpresoras := ObtenerListaImpresoras;
    try
      Result := oImpresoras.IndexOf(ANombreImpresora) >= 0;
    finally
      FreeAndNil(oImpresoras);
    end;
  end;
end;

function GetImpresoraCaja(
  const AParametrosCaja: IParametrosCaja;
  const AContextoSesion: IContextoSesionAplicacion): string;
var
  sPatronNombreImpresora: string;
  sArchivoCache: string;
begin
  sPatronNombreImpresora :=
    AParametrosCaja.GetString('vgerDefPrinter', 'DEBUG');
  sArchivoCache := Format('Caja_%s.cache',
    [AContextoSesion.Identidad.Usuario]);
  Result := ObtenerImpresoraPorPatronCached(sPatronNombreImpresora,
                                            sArchivoCache);
end;

function ObtenerImpresoraPorPatronCached(const PatronBusqueda,
                                               ArchivoCache: string): string;
var
  Linea, SesionCache, ImpresoraCache, ModoCache: string;
  ArchivoCacheLectura: TFileStream;
  LineasCache: TStringList;
  Partes: TStringList;
  CacheValida: Boolean;
begin
  Result := '';
  CacheValida := False;
  ArchivoCacheLectura := nil;
  LineasCache := TStringList.Create;
  Partes := TStringList.Create;
  Partes.Delimiter := ',';
  Partes.StrictDelimiter := True;
  try
    // 1. Intentar leer e identificar si la caché es válida
    if FileExists(ArchivoCache) then
    begin
      ArchivoCacheLectura := TFileStream.Create(
        ArchivoCache,
        fmOpenRead or fmShareDenyNone);
      try
        LineasCache.LoadFromStream(ArchivoCacheLectura);
        if LineasCache.Count > 0 then
        begin
          Linea := LineasCache[0];
          Partes.DelimitedText := Linea;
          if Partes.Count >= 3 then
          begin
            SesionCache := Trim(Partes[0]);
            ModoCache := Trim(Partes[1]);
            ImpresoraCache := Trim(Partes[2]);
            // Una cache 'DEBUG' solo es valida si el patron actual sigue
            // siendo DEBUG: si parametros (vgerDefPrinter) ya apunta a una
            // impresora real, se ignora y se reevalua el patron. Evita que
            // una cache antigua deje pegado el modo DEBUG.
            CacheValida := (ImpresoraCache <> '') and
                           ((SameText(ImpresoraCache, 'DEBUG') and
                             SameText(PatronBusqueda, 'DEBUG')) or
                            EstaImpresoraDisponible(ImpresoraCache));
            if CacheValida then
              Result := ImpresoraCache;
          end;
        end;
      finally
        FreeAndNil(ArchivoCacheLectura);
      end;
    end;
    // 2. Si la caché no existe o no es válida, buscar la impresora
    if not CacheValida then
    begin
      if SameText(PatronBusqueda, 'DEBUG') then
        Result := 'DEBUG'
      else
        Result := BuscarImpresoraPorPatrones(PatronBusqueda);
    end;
  finally
    FreeAndNil(LineasCache);
    FreeAndNil(Partes);
  end;
end;

function SepararSubcadenas(const Cadena: string): TStringList;
var
  i, Start: Integer;
  Subcadena: string;
begin
  Result := TStringList.Create;
  Start := 1;
  for i := 1 to Length(Cadena) do
  begin
    if Cadena[i] = ';' then
    begin
      Subcadena := Trim(Copy(Cadena, Start, i - Start));
      if Subcadena <> '' then
        Result.Add(Subcadena);
      Start := i + 1;
    end;
  end;
  // Agregar la última subcadena
  Subcadena := Trim(Copy(Cadena, Start, Length(Cadena)));
  if Subcadena <> '' then
    Result.Add(Subcadena);
end;

function BuscarImpresoraPorPatrones(const Patrones: string): string;
var
  ListaSubcadenas: TStringList;
  ListaImpresoras: TStringList;
  i, j: Integer;
  NombreImpresora, Subcadena: string;
  CoincideConTodos: Boolean;
begin
  Result := '';
  ListaSubcadenas := nil;
  ListaImpresoras := nil;
  try
    // Separar los patrones de búsqueda
    ListaSubcadenas := SepararSubcadenas(Patrones);
    if ListaSubcadenas.Count > 0 then
    begin
      // Obtener lista de impresoras instaladas
      ListaImpresoras := ObtenerListaImpresoras;
      if ListaImpresoras.Count > 0 then
      begin
        for i := 0 to ListaImpresoras.Count - 1 do
        begin
          if Result = '' then
          begin
            NombreImpresora := ListaImpresoras[i];
            CoincideConTodos := True;
            for j := 0 to ListaSubcadenas.Count - 1 do
            begin
              Subcadena := ListaSubcadenas[j];
              if not ContainsText(NombreImpresora, Subcadena) then
              begin
                CoincideConTodos := False;
                Break;
              end;
            end;
            if CoincideConTodos then
              Result := NombreImpresora;
          end;
        end;
      end;
    end;
  finally
    FreeAndNil(ListaSubcadenas);
    FreeAndNil(ListaImpresoras);
  end;
end;

function BuscarImpresoraEnLista(
  const APatrones: string;
  AImpresoras: TStrings): string;
var
  oSubcadenas: TStringList;
  i, j: Integer;
  bCoincide: Boolean;
begin
  Result := '';
  if (Trim(APatrones) <> '') and (not SameText(Trim(APatrones), 'DEBUG'))
     and Assigned(AImpresoras) then
  begin
    // Primero el nombre exacto (sin distinguir mayúsculas).
    i := 0;
    while (Result = '') and (i < AImpresoras.Count) do
    begin
      if SameText(AImpresoras[i], Trim(APatrones)) then
        Result := AImpresoras[i];
      Inc(i);
    end;
    if Result = '' then
    begin
      oSubcadenas := SepararSubcadenas(APatrones);
      try
        i := 0;
        while (Result = '') and (oSubcadenas.Count > 0) and
              (i < AImpresoras.Count) do
        begin
          bCoincide := True;
          j := 0;
          while bCoincide and (j < oSubcadenas.Count) do
          begin
            bCoincide := ContainsText(AImpresoras[i], oSubcadenas[j]);
            Inc(j);
          end;
          if bCoincide then
            Result := AImpresoras[i];
          Inc(i);
        end;
      finally
        FreeAndNil(oSubcadenas);
      end;
    end;
  end;
end;

function ObtenerListaImpresoras: TStringList;
const
  MAX_PRINTERS = 200;
  procedure EnumerarYAgregar(Flags: Cardinal;
                             const Descripcion: string;
                             var TotalCompartidas: Integer);
  var
    BytesNeeded, NumPrinters: DWORD;
    PrinterInfo: PPrinterInfo2;
    InfoArray: Pointer;
    BufferSize: DWORD;
    i: Integer;
  begin
    BufferSize := MAX_PRINTERS * SizeOf(TPrinterInfo2);
    GetMem(InfoArray, BufferSize);
    try
      if EnumPrinters(Flags, nil, 2, InfoArray, BufferSize,
                                                  BytesNeeded, NumPrinters) then
      begin
        if NumPrinters > 0 then
        begin
          PrinterInfo := PPrinterInfo2(InfoArray);
// EscribirLog(Format('%s: %d impresoras', [Descripcion, NumPrinters]));
          for i := 0 to NumPrinters - 1 do
          begin
            // Evitar duplicados
            if Result.IndexOf(PrinterInfo^.pPrinterName) = -1 then
            begin
              Result.Add(PrinterInfo^.pPrinterName);
              if (PrinterInfo^.Attributes and
                  PRINTER_ATTRIBUTE_SHARED) <> 0 then
              begin
                Inc(TotalCompartidas);
//                EscribirLog(Format('  [COMPARTIDA] %s',
//                                   [PrinterInfo^.pPrinterName]));
              end
              else
//                EscribirLog(Format('  %s', [PrinterInfo^.pPrinterName]));
            end;
            Inc(PrinterInfo);
          end;
        end;
      end
      else
      begin
        if GetLastError = ERROR_INSUFFICIENT_BUFFER then
        begin
          // Realocar con el tamaño correcto
          FreeMem(InfoArray);
          InfoArray := nil;
          GetMem(InfoArray, BytesNeeded);
          if EnumPrinters(Flags, nil, 2, InfoArray, BytesNeeded,
                          BytesNeeded, NumPrinters) then
          begin
            PrinterInfo := PPrinterInfo2(InfoArray);
//            EscribirLog(Format('%s: %d impresoras (buffer realocado)',
//                        [Descripcion, NumPrinters]));
            for i := 0 to NumPrinters - 1 do
            begin
              if Result.IndexOf(PrinterInfo^.pPrinterName) = -1 then
              begin
                Result.Add(PrinterInfo^.pPrinterName);

                if (PrinterInfo^.Attributes and
                    PRINTER_ATTRIBUTE_SHARED) <> 0 then
                  Inc(TotalCompartidas);
              end;
              Inc(PrinterInfo);
            end;
          end;
        end;
//        else
//          if GetLastError <> ERROR_FILE_NOT_FOUND then
//            raise.Create('Fichero no encontrado');
            // No es error si no hay impresoras de este tipo
// EscribirLog(Format('Error en %s: %d', [Descripcion, GetLastError]));
      end;
    finally
      FreeMem(InfoArray);
    end;
  end;
var
  ImpresoresCompartidas: Integer;
begin
  Result := TStringList.Create;
  try
    Result.Duplicates := dupIgnore;
    Result.Sorted := True;
    ImpresoresCompartidas := 0;
//    EscribirLog('=== Enumerando todas las impresoras ===');
    // 1. Impresoras locales
    EnumerarYAgregar(PRINTER_ENUM_LOCAL,
                     'Impresoras locales',
                     ImpresoresCompartidas);
    // 2. Conexiones de red (REDIRECCIONADAS - Terminal Server, RDP, etc.)
    EnumerarYAgregar(PRINTER_ENUM_CONNECTIONS,
                     'Impresoras redireccionadas/conexiones',
                     ImpresoresCompartidas);
    // 3. Impresoras de red compartidas
    EnumerarYAgregar(PRINTER_ENUM_NETWORK,
                     'Impresoras de red disponibles',
                     ImpresoresCompartidas);
    Result.Add('DEBUG');
//    EscribirLog('========================================');
//    EscribirLog(Format('Total impresoras únicas: %d', [Result.Count - 1]));
//    EscribirLog(Format('Total impresoras compartidas: %d',
//                       [ImpresoresCompartidas]));
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function ObtenerSesionImpresora(const NombreImpresora: string): string;
begin
  if EsImpresoraRedireccionada(NombreImpresora) then
    Result := ExtraerSesionDeImpresora(NombreImpresora)
  else if EsImpresoraRed(NombreImpresora) then
    Result := '1'
  else
    Result := '0';
end;

function EsImpresoraRed(const NombreImpresora: string): Boolean;
begin
  Result := Pos('\\', NombreImpresora) = 1;
end;


function ExtraerSesionDeImpresora(const NombreImpresora: string): string;
var
  i: Integer;
  PosCierra, PosAbre: Integer;
  Contenido, SoloNumeros: string;
  NombreUpper, ContenidoUpper: string;
  PosSession: Integer;
  Encontrada: Boolean;
begin
  Result := '0';
  Encontrada := False;
  NombreUpper := UpperCase(NombreImpresora);
  PosSession := Pos(' EN SESI', NombreUpper); // Cubre "EN SESIÓN"
  if PosSession = 0 then
    PosSession := Pos(' IN SESSI', NombreUpper); // Cubre "IN SESSION" (Inglés)
  if PosSession > 0 then
  begin
    Contenido := Copy(NombreImpresora, PosSession, Length(NombreImpresora));
    SoloNumeros := '';
    for i := 1 to Length(Contenido) do
    begin
      if CharInSet(Contenido[i], ['0'..'9']) then
        SoloNumeros := SoloNumeros + Contenido[i];
    end;
    if SoloNumeros <> '' then
    begin
      Result := SoloNumeros;
      Encontrada := True;
    end;
  end;
  if not Encontrada then
  begin
    PosCierra := 0;
    PosAbre := 0;
    for i := Length(NombreImpresora) downto 1 do
    begin
      if NombreImpresora[i] = ')' then
      begin
        PosCierra := i;
        Break;
      end;
    end;
    if PosCierra > 0 then
    begin
      for i := PosCierra - 1 downto 1 do
      begin
        if NombreImpresora[i] = '(' then
        begin
          PosAbre := i;
          Break;
        end;
      end;
    end;
    if (PosAbre > 0) and (PosCierra > PosAbre) then
    begin
      Contenido := Copy(NombreImpresora, PosAbre + 1,
        PosCierra - PosAbre - 1);
      ContenidoUpper := UpperCase(Contenido);
      if not ((Pos('COPIA', ContenidoUpper) > 0) or
              (Pos('COPY', ContenidoUpper) > 0)) then
      begin
        SoloNumeros := '';
        for i := 1 to Length(Contenido) do
        begin
          if CharInSet(Contenido[i], ['0'..'9']) then
            SoloNumeros := SoloNumeros + Contenido[i];
        end;
        if SoloNumeros <> '' then
          Result := SoloNumeros;
      end;
    end;
  end;
end;

function EsImpresoraRedireccionada(const NombreImpresora: string): Boolean;
begin
  Result := (Pos('redireccionado', LowerCase(NombreImpresora)) > 0) or
            (Pos('redirected', LowerCase(NombreImpresora)) > 0);
end;

function ObtenerNombreImpresoraPorCaja(Empresa, Almacen, Caja: Integer;
                                              ArchivoINI: string;
                                             const AContextoSesion:
                                             IContextoSesionAplicacion;
                                             out ModoImpresion: string): string;
var
  F, FCache: TextFile;
  Linea, ClaveCaja, Sesion: string;
  Partes: TStringList;
  SesionCache, ImpresoraCache: string;
  ArchivoCache: string;
  CacheValida, Encontrado: Boolean;
  PatronBusqueda: string;
begin
  Result := '';
  ModoImpresion := 'N';
  CacheValida := False;
  Encontrado := False;
//  ClaveCaja := Format('Caja_%d_%d_%d=', [Empresa, Almacen, Caja]);
//  if ArchivoINI = '' then
//    ArchivoINI := Fconfig.IniImprimirFile;
  // Archivo cache: ImpresorasVerifactu_1_2_3.cache
  ArchivoCache := Format('Caja_%s.cache',
    [AContextoSesion.Identidad.Usuario]);
  if not FileExists(ArchivoINI) then
//  begin
//    EscribirLog('Archivo INI no encontrado: ' + ArchivoINI);
//  end
//  else
  begin
    Partes := TStringList.Create;
    Partes.Delimiter := ',';
    Partes.StrictDelimiter := True;
    try
      if FileExists(ArchivoCache) then
      begin
        AssignFile(FCache, ArchivoCache);
        FileMode := fmOpenRead or fmShareDenyNone;
        Reset(FCache);
        try
          if not Eof(FCache) then
          begin
            Readln(FCache, Linea);
            Partes.DelimitedText := Linea;
            if Partes.Count >= 3 then
            begin
              SesionCache := Trim(Partes[0]);
              ModoImpresion := Trim(Partes[1]);
              ImpresoraCache := Trim(Partes[2]);
              CacheValida := (ImpresoraCache <> '') and
                             ((SameText(ImpresoraCache, 'DEBUG')) or
                              EstaImpresoraDisponible(ImpresoraCache));
              if CacheValida then
              begin
//                EscribirLog('Cache [Sesion' + SesionCache + ']: ' +
// ImpresoraCache);
                Result := ImpresoraCache;
              end;
            end;
          end;
        finally
          CloseFile(FCache);
        end;
      end;
      if not CacheValida then
      begin
        AssignFile(F, ArchivoINI);
        FileMode := fmOpenRead or fmShareDenyNone;
        Reset(F);
        try
          while not Eof(F) and not Encontrado do
          begin
            Readln(F, Linea);
            Linea := Trim(Linea);
            if Pos(ClaveCaja, Linea) = 1 then
            begin
              Encontrado := True;
              Linea := Copy(Linea, Length(ClaveCaja) + 1, Length(Linea));
              Partes.DelimitedText := Linea;
              if Partes.Count >= 2 then
                ModoImpresion := Trim(Partes[1]);
              PatronBusqueda := Trim(Partes[0]);
//              EscribirLog('Buscando: ' + PatronBusqueda);
              if SameText(PatronBusqueda, 'DEBUG') then
              begin
                Result := 'DEBUG';
// EscribirLog('Modo DEBUG: omitiendo enumeración de impresoras');
              end
              else
                Result := BuscarImpresoraPorPatrones(PatronBusqueda);
              if (Result <> '') and (Result <> 'DEBUG') then
              begin
                Sesion := ObtenerSesionImpresora(Result);
// EscribirLog('Cache guardada [Sesion' + Sesion + ']: ' + Result);
                AssignFile(FCache, ArchivoCache);
                Rewrite(FCache);
                try
                  Writeln(FCache, Sesion + ',' + ModoImpresion + ',' + Result);
                finally
                  CloseFile(FCache);
                end;
              end
              else if Result = 'DEBUG' then
              begin
                AssignFile(FCache, ArchivoCache);
                Rewrite(FCache);
                try
                  Writeln(FCache, '0,' + ModoImpresion + ',DEBUG');
                finally
                  CloseFile(FCache);
                end;
              end;
            end;
          end;
        finally
          CloseFile(F);
        end;
//        if not Encontrado then
//          EscribirLog('No existe configuración para ' + ClaveCaja);
      end;
    finally
      FreeAndNil(Partes);
    end;
  end;
end;

end.
