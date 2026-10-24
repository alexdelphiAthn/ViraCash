unit inLibInformeBalanceTallasPersistenciaIntf;

interface

uses
  Data.DB;

type
  TCriteriosInformeBalanceTallas = record
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

  IResultadoInformeBalanceTallas = interface
    ['{42676F31-7F00-498A-A4BD-B5FB86F28CBD}']
    function DataSet: TDataSet;
    function UnidadArticulo(const ACodigoArticulo: string): string;
  end;

  IRepositorioInformeBalanceTallas = interface
    ['{BE52F173-A6B7-4165-BE42-708A2A9CC46A}']
    function Preparar(
      const ACriterios: TCriteriosInformeBalanceTallas
    ): IResultadoInformeBalanceTallas;
  end;

implementation

end.
