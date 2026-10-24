program GeneradorEsquemaIdeal;

{ Esquema ideal de Ayuda > Comprobar integridad.

  GeneradorEsquemaIdeal <salida.json> --modelo <modelo.sql>
    [--res <HuellaEsquema.res>] [--scripts <a.sql> <b.sql> ...]
    [--comparador <DBComparer.exe>] [--mariadb12 <bin>] [--mariadb10 <bin>]
    [--mariadb10-msi <msi>] [--mysql8 <bin>] [--si-cambia | --comprobar]

  Sin modo, regenera siempre. --si-cambia solo regenera si el JSON no es
  del modelo y scripts de ahora (y recompila el .res si hace falta).
  --comprobar no genera nada: sale con 0 si está al día y con 3 si no.
  Salida 1: error. Lo llama el Publicador al compilar y al preparar. }

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Threading,
  inLibRecursoRcdata in 'inLibRecursoRcdata.pas',
  inLibServidorDesechable in 'inLibServidorDesechable.pas',
  inLibGeneradorEsquemaIdeal in 'inLibGeneradorEsquemaIdeal.pas';

type
  TModoGenerador = (mgSiempre, mgSiCambia, mgComprobar);

const
  cWeb = 'C:\DISCO_DURO\proyectos\factuzam_web\';

function OpcionesPorDefecto: TOpcionesGenerador;
begin
  Result := Default(TOpcionesGenerador);
  Result.Comparador := 'C:\DISCO_DURO\proyectos\dbcomparer\DBComparer.exe';
  Result.Binarios[mdMariaDB12] := 'C:\Program Files\MariaDB 12.3\bin';
  Result.Binarios[mdMySQL8] := cWeb +
    'build\mysql841_local\mysql-8.0.41-winx64\bin';
  Result.InstaladorMariaDB10 := cWeb +
    'empaquetador\mariadb-10.4.12-winx64.msi';
end;

procedure LeerArgumentos(
  out AOpciones: TOpcionesGenerador;
  out AModo: TModoGenerador);
var
  iArgumento: Integer;
  sArgumento: string;
  bScripts: Boolean;

  function Siguiente: string;
  begin
    Inc(iArgumento);
    if iArgumento > ParamCount then
      raise Exception.Create('Falta el valor de ' + sArgumento);
    Result := ParamStr(iArgumento);
  end;

begin
  AOpciones := OpcionesPorDefecto;
  AModo := mgSiempre;
  if ParamCount < 1 then
    raise Exception.Create('Uso: GeneradorEsquemaIdeal <salida.json> ' +
                           '--modelo <modelo.sql> [opciones]');
  AOpciones.Json := ParamStr(1);
  bScripts := False;
  iArgumento := 1;
  while iArgumento < ParamCount do
  begin
    Inc(iArgumento);
    sArgumento := ParamStr(iArgumento);
    bScripts := bScripts and not sArgumento.StartsWith('--');
    if bScripts then
      AOpciones.Scripts := AOpciones.Scripts + [sArgumento]
    else if sArgumento = '--modelo' then
      AOpciones.Modelo := Siguiente
    else if sArgumento = '--res' then
      AOpciones.Recurso := Siguiente
    else if sArgumento = '--comparador' then
      AOpciones.Comparador := Siguiente
    else if sArgumento = '--mariadb12' then
      AOpciones.Binarios[mdMariaDB12] := Siguiente
    else if sArgumento = '--mariadb10' then
      AOpciones.Binarios[mdMariaDB10] := Siguiente
    else if sArgumento = '--mariadb10-msi' then
      AOpciones.InstaladorMariaDB10 := Siguiente
    else if sArgumento = '--mysql8' then
      AOpciones.Binarios[mdMySQL8] := Siguiente
    else if sArgumento = '--scripts' then
      bScripts := True
    else if sArgumento = '--si-cambia' then
      AModo := mgSiCambia
    else if sArgumento = '--comprobar' then
      AModo := mgComprobar
    else
      raise Exception.Create('Argumento desconocido: ' + sArgumento);
  end;
  if not FileExists(AOpciones.Modelo) then
    raise Exception.Create('No existe el modelo: ' + AOpciones.Modelo);
end;

procedure Ejecutar;
var
  oOpciones: TOpcionesGenerador;
  eModo: TModoGenerador;
  sMotivo: string;
begin
  LeerArgumentos(oOpciones, eModo);
  sMotivo := MotivoDesfaseEsquemaIdeal(oOpciones);
  if eModo = mgComprobar then
  begin
    if sMotivo = '' then
      Writeln('Esquema ideal al día con ', oOpciones.Modelo)
    else
    begin
      Writeln('Esquema ideal desfasado: ', sMotivo);
      ExitCode := cSalidaDesfasado;
    end;
  end
  else if (eModo = mgSiCambia) and (sMotivo = '') then
    Writeln('Esquema ideal al día con ', oOpciones.Modelo,
            ': no se regenera')
  else if (eModo = mgSiCambia) and (sMotivo = cMotivoSoloRecurso) then
  begin
    CompilarRecursoEsquemaIdeal(oOpciones);
    Writeln('Recurso ', cRecursoHuellaEsquemaGenerado, ' -> ',
            oOpciones.Recurso);
  end
  else
  begin
    if sMotivo <> '' then
      Writeln('Se regenera el esquema ideal: ', sMotivo);
    GenerarEsquemaIdeal(
      oOpciones,
      procedure(const ATexto: string)
      begin
        Writeln(ATexto);
      end);
  end;
end;

var
  oError: Exception;

begin
  try
    Ejecutar;
  except
    // Los tres motores van en paralelo: sus errores llegan agrupados.
    on E: EAggregateException do
    begin
      for oError in E do
        Writeln('ERROR: ', oError.ClassName, ': ', oError.Message);
      ExitCode := 1;
    end;
    on E: Exception do
    begin
      Writeln('ERROR: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
