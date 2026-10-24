unit inLibDatasetsPersistenciaIntf;

interface

type
  IRepositorioMetadatosDatasets = interface
    ['{BC80B413-D4A4-450B-9DF4-615B60C191A2}']
    function ObtenerColumnasClavePrimaria(
      const ATabla: string): TArray<string>;
  end;

implementation

end.
