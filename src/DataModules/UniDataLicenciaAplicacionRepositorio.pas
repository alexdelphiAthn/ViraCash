unit UniDataLicenciaAplicacionRepositorio;

interface

uses
  Uni,
  inLibLicenciaAplicacion, inLibLicenciaAplicacionPersistenciaIntf;

type
  TRepositorioLicenciaAplicacionUniDAC = class(
    TInterfacedObject, IRepositorioLicenciaAplicacion)
  private
    FConexion: TUniConnection;
    function PrepararConexion(out AMensaje: string): Boolean;
  public
    constructor Create(AConexion: TUniConnection);
    function CargarNifsEmpresas: TResultadoNifsLicencia;
    function ContarFacturasDia(AFecha: TDateTime):
      TResultadoConteoFacturas;
  end;

function RegistrarLicenciaAplicacion(AConexion: TUniConnection;
  out ACodigo: string; out ANumeroNifs: Integer;
  out ADetalleNifs: string; out ARutaIni: string): Boolean;
function ComprobarLicenciaAplicacion(AConexion: TUniConnection;
  out AEstado: TEstadoLicenciaAplicacion;
  out AMensaje: string; out ACodigoEsperado: string;
  out ACodigoGuardado: string): Boolean;
function ContarFacturasDemoDia(AConexion: TUniConnection;
  AFecha: TDateTime): Integer;
procedure ValidarLimiteDemoFacturas(AConexion: TUniConnection;
  AEstado: TEstadoLicenciaAplicacion; AFecha: TDateTime);

implementation

uses
  System.SysUtils, System.Generics.Collections;

constructor TRepositorioLicenciaAplicacionUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioLicenciaAplicacionUniDAC.PrepararConexion(
  out AMensaje: string): Boolean;
begin
  Result := False;
  AMensaje := 'La conexión de licencia no está activa.';
  if Assigned(FConexion) then
  begin
    try
      // Reconectar antes de una consulta nueva, sin repetir operaciones.
      if not FConexion.Connected then
        FConexion.Connect;
      Result := FConexion.Connected;
    except
      on E: Exception do
        AMensaje := E.Message;
    end;
  end;
end;

function TRepositorioLicenciaAplicacionUniDAC.CargarNifsEmpresas:
  TResultadoNifsLicencia;
var
  oConsulta: TUniQuery;
  oNifs: TList<string>;
  sNif: string;
  sErrorConexion: string;
begin
  if not PrepararConexion(sErrorConexion) then
  begin
    Result := TResultadoNifsLicencia.Fallido(
      eplConexionNoDisponible, sErrorConexion);
  end
  else
  begin
    oNifs := TList<string>.Create;
    try
      oConsulta := TUniQuery.Create(nil);
      try
        try
          oConsulta.Connection := FConexion;
          oConsulta.SQL.Text :=
            'SELECT DISTINCT TRIM(NIF_EMP) AS NIF_EMP ' +
            '  FROM fza_empresas ' +
            ' WHERE IFNULL(TRIM(NIF_EMP), '''') <> '''' ' +
            ' ORDER BY NIF_EMP';
          oConsulta.Open;
          while not oConsulta.Eof do
          begin
            sNif := Trim(
              oConsulta.FieldByName('NIF_EMP').AsString);
            if sNif <> '' then
              oNifs.Add(sNif);
            oConsulta.Next;
          end;
          Result := TResultadoNifsLicencia.Correcto(
            oNifs.ToArray);
        except
          on E: Exception do
          begin
            Result := TResultadoNifsLicencia.Fallido(
              eplConsultaFallida, E.Message);
          end;
        end;
      finally
        FreeAndNil(oConsulta);
      end;
    finally
      FreeAndNil(oNifs);
    end;
  end;
end;

function TRepositorioLicenciaAplicacionUniDAC.ContarFacturasDia(
  AFecha: TDateTime): TResultadoConteoFacturas;
var
  oConsulta: TUniQuery;
  sErrorConexion: string;
begin
  if not PrepararConexion(sErrorConexion) then
  begin
    Result := TResultadoConteoFacturas.Fallido(
      eplConexionNoDisponible, sErrorConexion);
  end
  else
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text :=
          'SELECT COUNT(*) AS TOTAL ' +
          '  FROM fza_facturas ' +
          ' WHERE FECHA_FAC = :FECHA';
        oConsulta.ParamByName('FECHA').AsDate := Trunc(AFecha);
        oConsulta.Open;
        Result := TResultadoConteoFacturas.Correcto(
          oConsulta.FieldByName('TOTAL').AsInteger);
      except
        on E: Exception do
        begin
          Result := TResultadoConteoFacturas.Fallido(
            eplConsultaFallida, E.Message);
        end;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function CrearRepositorio(AConexion: TUniConnection):
  IRepositorioLicenciaAplicacion;
begin
  Result := TRepositorioLicenciaAplicacionUniDAC.Create(AConexion);
end;

function RegistrarLicenciaAplicacion(AConexion: TUniConnection;
  out ACodigo: string; out ANumeroNifs: Integer;
  out ADetalleNifs: string; out ARutaIni: string): Boolean;
begin
  Result := inLibLicenciaAplicacion.RegistrarLicenciaAplicacion(
    CrearRepositorio(AConexion), ACodigo, ANumeroNifs,
    ADetalleNifs, ARutaIni);
end;

function ComprobarLicenciaAplicacion(AConexion: TUniConnection;
  out AEstado: TEstadoLicenciaAplicacion;
  out AMensaje: string; out ACodigoEsperado: string;
  out ACodigoGuardado: string): Boolean;
begin
  Result := inLibLicenciaAplicacion.ComprobarLicenciaAplicacion(
    CrearRepositorio(AConexion), AEstado, AMensaje,
    ACodigoEsperado, ACodigoGuardado);
end;

function ContarFacturasDemoDia(AConexion: TUniConnection;
  AFecha: TDateTime): Integer;
begin
  Result := inLibLicenciaAplicacion.ContarFacturasDemoDia(
    CrearRepositorio(AConexion), AFecha);
end;

procedure ValidarLimiteDemoFacturas(AConexion: TUniConnection;
  AEstado: TEstadoLicenciaAplicacion; AFecha: TDateTime);
begin
  inLibLicenciaAplicacion.ValidarLimiteDemoFacturas(
    CrearRepositorio(AConexion), AEstado, AFecha);
end;

end.
