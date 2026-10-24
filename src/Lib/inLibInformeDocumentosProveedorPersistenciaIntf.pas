unit inLibInformeDocumentosProveedorPersistenciaIntf;

interface

uses
  Data.DB;

type
  TCriteriosInformeDocumentosProveedor = record
    FechaDesde: TDateTime;
    FechaHasta: TDateTime;
    Almacenes: string;
    Proveedores: string;
    Temporadas: string;
    Tipos: string;
    Series: string;
  end;

  IResultadoInformeDocumentosProveedor = interface
    ['{5C94308E-42F4-490F-AF4D-06FD4CC0F5BD}']
    function DataSet: TDataSet;
  end;

  IRepositorioInformeDocumentosProveedor = interface
    ['{85B0E1AE-A407-4200-9678-87BE79BE9673}']
    function Preparar(
      const ACriterios: TCriteriosInformeDocumentosProveedor
    ): IResultadoInformeDocumentosProveedor;
  end;

implementation

end.
