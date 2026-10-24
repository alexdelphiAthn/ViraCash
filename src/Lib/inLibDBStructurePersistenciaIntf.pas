unit inLibDBStructurePersistenciaIntf;

interface

uses
  System.SysUtils;

type
  TErrorLecturaEstructura = (
    eleNinguno,
    eleConexionNoDisponible,
    eleConsultaFallida
  );

  ELecturaEstructuraBBDD = class(Exception)
  private
    FError: TErrorLecturaEstructura;
  public
    constructor Create(AError: TErrorLecturaEstructura;
      const ADetalle: string);
    property Error: TErrorLecturaEstructura read FError;
  end;

  IRepositorioEstructuraBBDD = interface
    ['{45CFB0C0-A2D1-475E-8117-D7D8F93B9E95}']
    function ExisteEsquema(const AEsquema: string): Boolean;
    function ExisteTabla(const AEsquema, ATabla: string): Boolean;
    function ExisteVista(const AEsquema, AVista: string): Boolean;
  end;

implementation

constructor ELecturaEstructuraBBDD.Create(
  AError: TErrorLecturaEstructura; const ADetalle: string);
begin
  inherited Create(ADetalle);
  FError := AError;
end;

end.
