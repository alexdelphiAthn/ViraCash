unit inLibConfigCamposPersistenciaIntf;

interface

type
  TErrorLecturaConfigCampos = (
    elcNinguno,
    elcConexionNoDisponible,
    elcConsultaFallida
  );

  TConfigCampoPersistido = record
    Tabla: string;
    Campo: string;
    TituloVisual: string;
    AnchoColumna: Integer;
    OrdenVisual: Integer;
    Visible: Boolean;
  end;

  TResultadoConfigCampos = record
    Exito: Boolean;
    Elementos: TArray<TConfigCampoPersistido>;
    Error: TErrorLecturaConfigCampos;
    Detalle: string;
    class function Correcto(
      const AElementos: TArray<TConfigCampoPersistido>):
      TResultadoConfigCampos; static;
    class function Fallido(AError: TErrorLecturaConfigCampos;
      const ADetalle: string): TResultadoConfigCampos; static;
  end;

  IRepositorioConfigCampos = interface
    ['{338F14BF-4306-4D7F-A1B5-08A697095B17}']
    function CargarCampos: TResultadoConfigCampos;
  end;

implementation

class function TResultadoConfigCampos.Correcto(
  const AElementos: TArray<TConfigCampoPersistido>):
  TResultadoConfigCampos;
begin
  Result.Exito := True;
  Result.Elementos := AElementos;
  Result.Error := elcNinguno;
  Result.Detalle := '';
end;

class function TResultadoConfigCampos.Fallido(
  AError: TErrorLecturaConfigCampos;
  const ADetalle: string): TResultadoConfigCampos;
begin
  Result.Exito := False;
  SetLength(Result.Elementos, 0);
  Result.Error := AError;
  Result.Detalle := ADetalle;
end;

end.
