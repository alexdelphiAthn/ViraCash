unit inLibPermisosPersistenciaIntf;

interface

uses
  inLibPermisosIntf;

type
  TErrorLecturaPermisos = (
    elpNinguno,
    elpConexionNoDisponible,
    elpConsultaFallida
  );

  TReglaPermisoPersistida = record
    Sujeto: string;
    Codigo: string;
    Permitido: Boolean;
  end;

  TResultadoLecturaPermisos = record
    Exito: Boolean;
    Reglas: TArray<TReglaPermisoPersistida>;
    Error: TErrorLecturaPermisos;
    Detalle: string;
    class function Correcto(
      const AReglas: TArray<TReglaPermisoPersistida>):
      TResultadoLecturaPermisos; static;
    class function Fallido(AError: TErrorLecturaPermisos;
      const ADetalle: string): TResultadoLecturaPermisos; static;
  end;

  IRepositorioPermisos = interface
    ['{9D2246FB-DB92-41E7-9DCA-D43D8FCAB94C}']
    function CargarReglas(const AIdentidad: TIdentidadPermisos):
      TResultadoLecturaPermisos;
  end;

implementation

class function TResultadoLecturaPermisos.Correcto(
  const AReglas: TArray<TReglaPermisoPersistida>):
  TResultadoLecturaPermisos;
begin
  Result.Exito := True;
  Result.Reglas := AReglas;
  Result.Error := elpNinguno;
  Result.Detalle := '';
end;

class function TResultadoLecturaPermisos.Fallido(
  AError: TErrorLecturaPermisos;
  const ADetalle: string): TResultadoLecturaPermisos;
begin
  Result.Exito := False;
  SetLength(Result.Reglas, 0);
  Result.Error := AError;
  Result.Detalle := ADetalle;
end;

end.
