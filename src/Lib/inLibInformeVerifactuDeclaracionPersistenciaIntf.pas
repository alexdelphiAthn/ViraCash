unit inLibInformeVerifactuDeclaracionPersistenciaIntf;

interface

type
  TEmpresaInformeVerifactuDeclaracion = record
    Codigo: string;
    RazonSocial: string;
    Nif: string;
    Activa: Boolean;
    NumeroInstalacion: string;
    VersionInstalacion: string;
    CodigoSif: string;
    TieneInstanteInstalacion: Boolean;
    InstanteInstalacion: TDateTime;
  end;

  TEmpresasInformeVerifactuDeclaracion =
    TArray<TEmpresaInformeVerifactuDeclaracion>;

  IRepositorioInformeVerifactuDeclaracion = interface
    ['{77DC8B46-1849-44F9-855F-62467D271F31}']
    function ListarEmpresas: TEmpresasInformeVerifactuDeclaracion;
  end;

implementation

end.
