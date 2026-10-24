unit uUrlSegura;

{
  Politica comun de URLs para ViraCashControlU.

  - HTTPS se permite con cualquier host y certificado valido.
  - HTTP solo se permite hacia una direccion o un nombre de la red local.
  - Todas las rutas derivadas deben conservar esquema, host y puerto.

  Android necesita permitir tecnicamente el trafico sin cifrar porque la URL
  se configura en tiempo de ejecucion. La restriccion efectiva se aplica aqui
  y, por tanto, tambien protege la compilacion Win32.
}

interface

uses
  System.SysUtils;

function NormalizarUrlBase(const AUrl: string): string;
function ValidarUrlBasePermitida(
  const AUrl: string; out AError: string): Boolean;
function ConstruirUrlMismoOrigen(const ABase, ARuta: string;
  out AUrl, AError: string): Boolean;
function MismoOrigen(const ABase, AUrl: string): Boolean;

implementation

type
  TPartesUrl = record
    Esquema: string;
    Host: string;
    Puerto: Integer;
    PuertoExplicito: Boolean;
    Autoridad: string;
    Origen: string;
    Normalizada: string;
  end;

function TieneCaracterNoPermitido(const ATexto: string): Boolean;
var
  C: Char;
begin
  Result := True;
  for C in ATexto do
    if Ord(C) <= 32 then
      Exit;
  Result := False;
end;

function HostTieneSintaxisValida(
  const AHost: string; AEsIPv6: Boolean): Boolean;
var
  C: Char;
begin
  Result := AHost <> '';
  if not Result then
    Exit;
  for C in AHost do
    if AEsIPv6 then
    begin
      if not CharInSet(C, ['0'..'9', 'a'..'z', 'A'..'Z', ':', '.',
        '%', '-', '_']) then
        Exit(False);
    end
    else if not CharInSet(C, ['0'..'9', 'a'..'z', 'A'..'Z', '.',
      '-', '_']) and (Ord(C) < 128) then
      Exit(False);
end;

function AnalizarUrl(const AUrl: string; AEsBase: Boolean;
  out APartes: TPartesUrl; out AError: string): Boolean;
var
  AutoridadEntrada, HostEntrada, PuertoTexto, Resto, Texto: string;
  Cierre, FinAutoridad, I, InicioAutoridad, Separador, SeparadorPuerto: Integer;
  EsIPv6: Boolean;
begin
  Result := False;
  APartes := Default(TPartesUrl);
  AError := '';
  Texto := Trim(AUrl);
  if Texto = '' then
  begin
    AError := 'Indica la URL del servidor.';
    Exit;
  end;
  if TieneCaracterNoPermitido(Texto) then
  begin
    AError := 'La URL contiene espacios o caracteres de control.';
    Exit;
  end;
  if Pos('#', Texto) > 0 then
  begin
    AError := 'La URL no puede contener un fragmento (#).';
    Exit;
  end;
  if AEsBase and (Pos('?', Texto) > 0) then
  begin
    AError := 'La URL base no puede contener parámetros de consulta.';
    Exit;
  end;

  Separador := Pos('://', Texto);
  if Separador <= 1 then
  begin
    AError := 'La URL debe comenzar por http:// o https://.';
    Exit;
  end;
  APartes.Esquema := LowerCase(Copy(Texto, 1, Separador - 1));
  if (APartes.Esquema <> 'http') and (APartes.Esquema <> 'https') then
  begin
    AError := 'Solo se permiten URLs HTTP o HTTPS.';
    Exit;
  end;

  InicioAutoridad := Separador + 3;
  FinAutoridad := Length(Texto) + 1;
  for I := InicioAutoridad to Length(Texto) do
    if CharInSet(Texto[I], ['/', '?']) then
    begin
      FinAutoridad := I;
      Break;
    end;
  AutoridadEntrada := Copy(Texto, InicioAutoridad,
    FinAutoridad - InicioAutoridad);
  Resto := Copy(Texto, FinAutoridad, MaxInt);
  if AutoridadEntrada = '' then
  begin
    AError := 'La URL no contiene un host.';
    Exit;
  end;
  if Pos('@', AutoridadEntrada) > 0 then
  begin
    AError := 'No incluyas usuario ni contraseña dentro de la URL.';
    Exit;
  end;

  EsIPv6 := AutoridadEntrada.StartsWith('[');
  PuertoTexto := '';
  if EsIPv6 then
  begin
    Cierre := Pos(']', AutoridadEntrada);
    if Cierre <= 2 then
    begin
      AError := 'La dirección IPv6 de la URL no es válida.';
      Exit;
    end;
    HostEntrada := Copy(AutoridadEntrada, 2, Cierre - 2);
    if Cierre < Length(AutoridadEntrada) then
    begin
      if AutoridadEntrada[Cierre + 1] <> ':' then
      begin
        AError := 'La autoridad de la URL no es válida.';
        Exit;
      end;
      PuertoTexto := Copy(AutoridadEntrada, Cierre + 2, MaxInt);
    end;
  end
  else
  begin
    if (Pos('[', AutoridadEntrada) > 0) or
       (Pos(']', AutoridadEntrada) > 0) then
    begin
      AError := 'La autoridad de la URL no es válida.';
      Exit;
    end;
    SeparadorPuerto := Pos(':', AutoridadEntrada);
    if SeparadorPuerto > 0 then
    begin
      if Pos(':', Copy(AutoridadEntrada, SeparadorPuerto + 1,
        MaxInt)) > 0 then
      begin
        AError := 'Las direcciones IPv6 deben escribirse entre corchetes.';
        Exit;
      end;
      HostEntrada := Copy(AutoridadEntrada, 1, SeparadorPuerto - 1);
      PuertoTexto := Copy(AutoridadEntrada, SeparadorPuerto + 1, MaxInt);
    end
    else
      HostEntrada := AutoridadEntrada;
  end;

  if not HostTieneSintaxisValida(HostEntrada, EsIPv6) then
  begin
    AError := 'El host de la URL no es válido.';
    Exit;
  end;
  APartes.Host := LowerCase(HostEntrada);
  while APartes.Host.EndsWith('.') do
    Delete(APartes.Host, Length(APartes.Host), 1);
  if APartes.Host = '' then
  begin
    AError := 'El host de la URL no es válido.';
    Exit;
  end;

  APartes.PuertoExplicito := PuertoTexto <> '';
  if APartes.PuertoExplicito then
  begin
    if (not TryStrToInt(PuertoTexto, APartes.Puerto)) or
       (APartes.Puerto < 1) or (APartes.Puerto > 65535) then
    begin
      AError := 'El puerto de la URL no es válido.';
      Exit;
    end;
  end
  else if APartes.Esquema = 'https' then
    APartes.Puerto := 443
  else
    APartes.Puerto := 80;

  if EsIPv6 then
    APartes.Autoridad := '[' + APartes.Host + ']'
  else
    APartes.Autoridad := APartes.Host;
  if APartes.PuertoExplicito then
    APartes.Autoridad := APartes.Autoridad + ':' +
      IntToStr(APartes.Puerto);
  APartes.Origen := APartes.Esquema + '://' + APartes.Autoridad;
  APartes.Normalizada := APartes.Origen + Resto;
  if AEsBase then
    while APartes.Normalizada.EndsWith('/') do
      Delete(APartes.Normalizada, Length(APartes.Normalizada), 1);
  Result := True;
end;

function LeerOcteto(const ATexto: string; out AValor: Integer): Boolean;
begin
  Result := (ATexto <> '') and (Length(ATexto) <= 3) and
    TryStrToInt(ATexto, AValor) and (AValor >= 0) and (AValor <= 255);
end;

function EsIPv4(const AHost: string;
  out A, B, C, D: Integer): Boolean;
var
  P1, P2, P3: Integer;
  Resto: string;
begin
  Result := False;
  P1 := Pos('.', AHost);
  if P1 = 0 then
    Exit;
  Resto := Copy(AHost, P1 + 1, MaxInt);
  P2 := Pos('.', Resto);
  if P2 = 0 then
    Exit;
  P2 := P1 + P2;
  Resto := Copy(AHost, P2 + 1, MaxInt);
  P3 := Pos('.', Resto);
  if P3 = 0 then
    Exit;
  P3 := P2 + P3;
  if Pos('.', Copy(AHost, P3 + 1, MaxInt)) > 0 then
    Exit;
  Result := LeerOcteto(Copy(AHost, 1, P1 - 1), A) and
    LeerOcteto(Copy(AHost, P1 + 1, P2 - P1 - 1), B) and
    LeerOcteto(Copy(AHost, P2 + 1, P3 - P2 - 1), C) and
    LeerOcteto(Copy(AHost, P3 + 1, MaxInt), D);
end;

function EsIPv4Local(const AHost: string): Boolean;
var
  A, B, C, D: Integer;
begin
  Result := EsIPv4(AHost, A, B, C, D) and
    ((A = 10) or
     ((A = 172) and (B >= 16) and (B <= 31)) or
     ((A = 192) and (B = 168)) or
     (A = 127) or
     ((A = 169) and (B = 254)));
end;

function EsIPv6Local(const AHost: string): Boolean;
var
  C: Char;
  HostSinZona, PrefijoLoopback: string;
  PosZona: Integer;
begin
  HostSinZona := LowerCase(AHost);
  PosZona := Pos('%', HostSinZona);
  if PosZona > 0 then
    HostSinZona := Copy(HostSinZona, 1, PosZona - 1);
  if Pos(':', HostSinZona) = 0 then
    Exit(False);
  for C in HostSinZona do
    if not CharInSet(C, ['0'..'9', 'a'..'f', ':', '.']) then
      Exit(False);
  PrefijoLoopback := '';
  if HostSinZona.EndsWith('1') then
    PrefijoLoopback := Copy(HostSinZona, 1, Length(HostSinZona) - 1);
  if PrefijoLoopback <> '' then
    for C in PrefijoLoopback do
      if not CharInSet(C, ['0', ':']) then
      begin
        PrefijoLoopback := '';
        Break;
      end;
  Result := (PrefijoLoopback <> '') or
    (Copy(HostSinZona, 1, 2) = 'fc') or
    (Copy(HostSinZona, 1, 2) = 'fd') or
    (Copy(HostSinZona, 1, 3) = 'fe8') or
    (Copy(HostSinZona, 1, 3) = 'fe9') or
    (Copy(HostSinZona, 1, 3) = 'fea') or
    (Copy(HostSinZona, 1, 3) = 'feb');
end;

function HostHttpEsLocal(const AHost: string): Boolean;
var
  A, B, C, D: Integer;
  CHost: Char;
  Host: string;
  SoloDigitos: Boolean;
begin
  Host := LowerCase(AHost);
  while Host.EndsWith('.') do
    Delete(Host, Length(Host), 1);
  if EsIPv4(Host, A, B, C, D) then
    Exit(EsIPv4Local(Host));
  if Pos(':', Host) > 0 then
    Exit(EsIPv6Local(Host));
  SoloDigitos := Host <> '';
  for CHost in Host do
    if not CharInSet(CHost, ['0'..'9']) then
    begin
      SoloDigitos := False;
      Break;
    end;
  Result := ((Pos('.', Host) = 0) and not SoloDigitos) or
    Host.EndsWith('.local') or
    Host.EndsWith('.lan') or Host.EndsWith('.internal');
end;

function PoliticaPermitida(const APartes: TPartesUrl;
  out AError: string): Boolean;
begin
  AError := '';
  Result := APartes.Esquema = 'https';
  if Result then
    Exit;
  Result := HostHttpEsLocal(APartes.Host);
  if not Result then
    AError := 'HTTP sin cifrar solo se permite para servidores de la red ' +
      'local. Usa una IP privada o un nombre local, .local, .lan o .internal.';
end;

function NormalizarUrlBase(const AUrl: string): string;
var
  Error: string;
  Partes: TPartesUrl;
begin
  if AnalizarUrl(AUrl, True, Partes, Error) then
    Exit(Partes.Normalizada);
  Result := Trim(AUrl);
  while Result.EndsWith('/') do
    Delete(Result, Length(Result), 1);
end;

function ValidarUrlBasePermitida(
  const AUrl: string; out AError: string): Boolean;
var
  Partes: TPartesUrl;
begin
  Result := AnalizarUrl(AUrl, True, Partes, AError) and
    PoliticaPermitida(Partes, AError);
end;

function ValidarUrlPeticionPermitida(const AUrl: string;
  out APartes: TPartesUrl; out AError: string): Boolean;
begin
  Result := AnalizarUrl(AUrl, False, APartes, AError) and
    PoliticaPermitida(APartes, AError);
end;

function MismoOrigen(const ABase, AUrl: string): Boolean;
var
  Error: string;
  Base, Destino: TPartesUrl;
begin
  Result := AnalizarUrl(ABase, True, Base, Error) and
    AnalizarUrl(AUrl, False, Destino, Error) and
    SameText(Base.Esquema, Destino.Esquema) and
    SameText(Base.Host, Destino.Host) and
    (Base.Puerto = Destino.Puerto);
end;

function ConstruirUrlMismoOrigen(const ABase, ARuta: string;
  out AUrl, AError: string): Boolean;
var
  Base, Destino: TPartesUrl;
  Ruta: string;
begin
  Result := False;
  AUrl := '';
  if not AnalizarUrl(ABase, True, Base, AError) or
     not PoliticaPermitida(Base, AError) then
    Exit;
  Ruta := Trim(ARuta);
  if Ruta = '' then
  begin
    AError := 'La ruta del endpoint está vacía.';
    Exit;
  end;
  if Ruta.StartsWith('//') then
  begin
    AError := 'No se permiten URLs relativas que cambien de servidor.';
    Exit;
  end;
  if Pos('://', Ruta) > 0 then
    AUrl := Ruta
  else if Ruta.StartsWith('/') then
    AUrl := Base.Origen + Ruta
  else
    AUrl := Base.Normalizada + '/' + Ruta;

  if not ValidarUrlPeticionPermitida(AUrl, Destino, AError) then
  begin
    AUrl := '';
    Exit;
  end;
  if not SameText(Base.Esquema, Destino.Esquema) or
     not SameText(Base.Host, Destino.Host) or
     (Base.Puerto <> Destino.Puerto) then
  begin
    AUrl := '';
    AError := 'El endpoint debe pertenecer al mismo servidor configurado.';
    Exit;
  end;
  Result := True;
end;

end.
