unit inLibInformeEfectosPagoPersistenciaIntf;

interface

uses
  Data.DB;

type
  TOpcionInformeEfectosPago = record
    Codigo: string;
    Nombre: string;
  end;

  TOpcionesInformeEfectosPago = TArray<TOpcionInformeEfectosPago>;

  TCriteriosInformeEfectosPago = record
    FechaDesde: TDateTime;
    FechaHasta: TDateTime;
    Almacenes: string;
    Proveedores: string;
    Tipos: string;
    Situaciones: string;
    Bancos: string;
    NumeroDesde: string;
    NumeroHasta: string;
    TipoFecha: Integer;
    ModoSituacion: Integer;
    Niveles: TArray<string>;
  end;

  IResultadoInformeEfectosPago = interface
    ['{4772FB45-FBBF-44B9-B94E-39ED96D4E39E}']
    function DataSet: TDataSet;
  end;

  IRepositorioInformeEfectosPago = interface
    ['{E5B54E5D-B602-4E51-909F-C3202E29EE7E}']
    function ListarTipos: TOpcionesInformeEfectosPago;
    function ListarSituaciones: TOpcionesInformeEfectosPago;
    function ListarBancos: TOpcionesInformeEfectosPago;
    function Preparar(
      const ACriterios: TCriteriosInformeEfectosPago
    ): IResultadoInformeEfectosPago;
  end;

implementation

end.
