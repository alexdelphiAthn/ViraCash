unit inLibInformeBalanceSinTallasPersistenciaIntf;

interface

uses
  Data.DB;

type
  TCriteriosInformeBalanceSinTallas = record
    Modo: string;
    FechaDesde: TDateTime;
    FechaHasta: TDateTime;
    Almacenes: string;
    Familias: string;
    Proveedores: string;
    Temporadas: string;
    Articulos: string;
    Tarifa: string;
    Desglosado: string;
    Bandas: string;
    Nivel1: string;
    Nivel2: string;
    Nivel3: string;
    NivelFamilia: Integer;
  end;

  IResultadoInformeBalanceSinTallas = interface
    ['{2DB7E0F2-6117-4215-8066-3C35F990E4D2}']
    function DataSet: TDataSet;
    function UnidadArticulo(const ACodigoArticulo: string): string;
  end;

  IRepositorioInformeBalanceSinTallas = interface
    ['{943FEE2F-4B77-4704-BEBD-E55479DC3D29}']
    function Preparar(
      const ACriterios: TCriteriosInformeBalanceSinTallas
    ): IResultadoInformeBalanceSinTallas;
  end;

implementation

end.
