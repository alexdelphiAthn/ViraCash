unit inLibLicenciaAplicacionPersistenciaIntf;

interface

type
  TErrorPersistenciaLicencia = (
    eplNinguno,
    eplConexionNoDisponible,
    eplConsultaFallida
  );

  TResultadoNifsLicencia = record
    Exito: Boolean;
    Nifs: TArray<string>;
    Error: TErrorPersistenciaLicencia;
    Detalle: string;
    class function Correcto(const ANifs: TArray<string>):
      TResultadoNifsLicencia; static;
    class function Fallido(AError: TErrorPersistenciaLicencia;
      const ADetalle: string): TResultadoNifsLicencia; static;
  end;

  TResultadoConteoFacturas = record
    Exito: Boolean;
    Total: Integer;
    Error: TErrorPersistenciaLicencia;
    Detalle: string;
    class function Correcto(ATotal: Integer):
      TResultadoConteoFacturas; static;
    class function Fallido(AError: TErrorPersistenciaLicencia;
      const ADetalle: string): TResultadoConteoFacturas; static;
  end;

  IRepositorioLicenciaAplicacion = interface
    ['{0EF2016F-E9CD-456A-B429-503FDB50FC40}']
    function CargarNifsEmpresas: TResultadoNifsLicencia;
    function ContarFacturasDia(AFecha: TDateTime):
      TResultadoConteoFacturas;
  end;

implementation

class function TResultadoNifsLicencia.Correcto(
  const ANifs: TArray<string>): TResultadoNifsLicencia;
begin
  Result.Exito := True;
  Result.Nifs := ANifs;
  Result.Error := eplNinguno;
  Result.Detalle := '';
end;

class function TResultadoNifsLicencia.Fallido(
  AError: TErrorPersistenciaLicencia;
  const ADetalle: string): TResultadoNifsLicencia;
begin
  Result.Exito := False;
  SetLength(Result.Nifs, 0);
  Result.Error := AError;
  Result.Detalle := ADetalle;
end;

class function TResultadoConteoFacturas.Correcto(
  ATotal: Integer): TResultadoConteoFacturas;
begin
  Result.Exito := True;
  Result.Total := ATotal;
  Result.Error := eplNinguno;
  Result.Detalle := '';
end;

class function TResultadoConteoFacturas.Fallido(
  AError: TErrorPersistenciaLicencia;
  const ADetalle: string): TResultadoConteoFacturas;
begin
  Result.Exito := False;
  Result.Total := 0;
  Result.Error := AError;
  Result.Detalle := ADetalle;
end;

end.
