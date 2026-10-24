unit inLibValoresAutomaticosPersistenciaIntf;

interface

uses
  System.Classes, System.SysUtils;

type
  TErrorValoresAutomaticos = (
    evaNinguno,
    evaConexionNoDisponible,
    evaLecturaFallida,
    evaGeneracionContadorFallida
  );

  EValoresAutomaticosPersistencia = class(Exception)
  private
    FError: TErrorValoresAutomaticos;
  public
    constructor Create(AError: TErrorValoresAutomaticos;
      const ADetalle: string);
    property Error: TErrorValoresAutomaticos read FError;
  end;

  TResultadoContadorAutomatico = record
    Exito: Boolean;
    Valor: string;
    Error: TErrorValoresAutomaticos;
    Detalle: string;
    class function Correcto(const AValor: string):
      TResultadoContadorAutomatico; static;
    class function Fallido(AError: TErrorValoresAutomaticos;
      const ADetalle: string): TResultadoContadorAutomatico; static;
  end;

  TValorPorDefectoPersistido = record
    Campo: string;
    Valor: string;
    TipoDato: string;
  end;

  IRepositorioValoresAutomaticos = interface
    ['{8E4DC833-5789-4D9B-9A42-78AA0C0775AB}']
    function ObtenerSeriePropiaAlmacen(const AEmpresa,
      ATipoDocumento, AAlmacen: string): string;
    function ObtenerSerieDefecto(const AEmpresa, ATipoDocumento,
      AAlmacen: string): string;
    procedure CargarSeriesEmpresa(const AEmpresa,
      ATipoDocumento: string; AElementos: TStrings);
    function ObtenerSiguienteContador(const ATipoDocumento,
      AUsuario: string): TResultadoContadorAutomatico;
    function ObtenerValorPorDefecto(const ATabla, ACampo,
      ACampoCondicion: string): string;
    function CargarValoresPorDefecto(const ANombreTabla: string):
      TArray<TValorPorDefectoPersistido>;
  end;

implementation

constructor EValoresAutomaticosPersistencia.Create(
  AError: TErrorValoresAutomaticos; const ADetalle: string);
begin
  inherited Create(ADetalle);
  FError := AError;
end;

class function TResultadoContadorAutomatico.Correcto(
  const AValor: string): TResultadoContadorAutomatico;
begin
  Result.Exito := True;
  Result.Valor := AValor;
  Result.Error := evaNinguno;
  Result.Detalle := '';
end;

class function TResultadoContadorAutomatico.Fallido(
  AError: TErrorValoresAutomaticos;
  const ADetalle: string): TResultadoContadorAutomatico;
begin
  Result.Exito := False;
  Result.Valor := '';
  Result.Error := AError;
  Result.Detalle := ADetalle;
end;

end.
