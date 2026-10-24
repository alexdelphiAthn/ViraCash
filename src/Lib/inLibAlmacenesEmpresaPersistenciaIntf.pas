unit inLibAlmacenesEmpresaPersistenciaIntf;

interface

type
  IRepositorioAlmacenesEmpresa = interface
    ['{0EB0CB34-D63C-4747-9BF7-C08923220878}']
    function AlmacenPerteneceEmpresa(const AEmpresa,
      AAlmacen: string): Boolean;
    function PrimerAlmacenEmpresa(const AEmpresa: string): string;
    function ObtenerAlmacenDepositoEmpresa(
      const AEmpresa: string): string;
  end;

implementation

end.
