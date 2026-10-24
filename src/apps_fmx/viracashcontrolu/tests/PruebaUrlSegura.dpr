program PruebaUrlSegura;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  uUrlSegura in '..\uUrlSegura.pas';

var
  Fallos: Integer;

procedure Comprobar(ACondicion: Boolean; const ANombre: string);
begin
  if ACondicion then
    Writeln('OK  ', ANombre)
  else
  begin
    Inc(Fallos);
    Writeln('ERROR  ', ANombre);
  end;
end;

function Permitida(const AUrl: string): Boolean;
var
  Error: string;
begin
  Result := ValidarUrlBasePermitida(AUrl, Error);
end;

procedure ProbarComposicion;
var
  Error, Url: string;
begin
  Comprobar(ConstruirUrlMismoOrigen(
    'http://192.168.1.20/fzamcontrolu/api', 'foto.php?id=1', Url,
    Error) and (Url =
    'http://192.168.1.20/fzamcontrolu/api/foto.php?id=1'),
    'ruta relativa a la base');
  Comprobar(ConstruirUrlMismoOrigen(
    'http://192.168.1.20/fzamcontrolu/api', '/foto.php?id=1', Url,
    Error) and (Url = 'http://192.168.1.20/foto.php?id=1'),
    'ruta desde la raiz');
  Comprobar(ConstruirUrlMismoOrigen(
    'http://192.168.1.20/fzamcontrolu/api',
    'http://192.168.1.20/otra/foto.php', Url, Error),
    'URL absoluta del mismo origen');
  Comprobar(not ConstruirUrlMismoOrigen(
    'http://192.168.1.20/fzamcontrolu/api',
    'http://192.168.1.21/foto.php', Url, Error),
    'rechazo de otro host');
  Comprobar(not ConstruirUrlMismoOrigen(
    'http://192.168.1.20/fzamcontrolu/api',
    'https://192.168.1.20/foto.php', Url, Error),
    'rechazo de otro esquema');
end;

begin
  Fallos := 0;
  Comprobar(Permitida('https://api.example.com/app'),
    'HTTPS publico');
  Comprobar(Permitida('http://10.1.2.3/api'), 'IPv4 10/8');
  Comprobar(Permitida('http://172.31.255.254/api'), 'IPv4 172.16/12');
  Comprobar(Permitida('http://192.168.1.20/api'), 'IPv4 192.168/16');
  Comprobar(Permitida('http://127.0.0.1/api'), 'IPv4 loopback');
  Comprobar(Permitida('http://169.254.20.1/api'), 'IPv4 link-local');
  Comprobar(not Permitida('http://8.8.8.8/api'), 'rechazo IPv4 publica');
  Comprobar(not Permitida('http://172.32.0.1/api'),
    'rechazo fuera de 172.16/12');
  Comprobar(Permitida('http://servidor/api'), 'nombre sin punto');
  Comprobar(Permitida('http://factuzam.local/api'), 'nombre .local');
  Comprobar(Permitida('http://factuzam.lan/api'), 'nombre .lan');
  Comprobar(Permitida('http://factuzam.internal/api'),
    'nombre .internal');
  Comprobar(not Permitida('http://example.com/api'),
    'rechazo DNS publico por HTTP');
  Comprobar(Permitida('http://[fd00::1]/api'), 'IPv6 ULA');
  Comprobar(Permitida('http://[fe80::1%25wlan0]/api'),
    'IPv6 link-local con zona');
  Comprobar(Permitida('http://[::1]/api'), 'IPv6 loopback abreviada');
  Comprobar(Permitida('http://[0:0:0:0:0:0::1]/api'),
    'IPv6 loopback alternativa');
  Comprobar(not Permitida('http://[2001:4860:4860::8888]/api'),
    'rechazo IPv6 publica');
  ProbarComposicion;
  if Fallos <> 0 then
    Halt(1);
end.
