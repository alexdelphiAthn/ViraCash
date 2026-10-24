unit inLibUnidadesMedidaPersistenciaIntf;

interface

type
  TUnidadMedidaPersistida = record
    Codigo: string;
    Descripcion: string;
    Decimales: Integer;
    Magnitud: string;
    EsBase: Boolean;
    FactorBase: Double;
  end;

  IRepositorioUnidadesMedida = interface
    ['{84202393-CF3E-48BD-AAD6-EAA5EDB3EC7A}']
    function CargarUnidades:
      TArray<TUnidadMedidaPersistida>;
  end;

implementation

end.
