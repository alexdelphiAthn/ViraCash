unit inLibWizardEditarPersistenciaIntf;

interface

uses
  Data.DB;

type
  TCadenasWizardEditar = TArray<string>;

  TCampoTablaWizardEditar = record
    Nombre: string;
    EsClavePrimaria: Boolean;
  end;

  TCamposTablaWizardEditar = TArray<TCampoTablaWizardEditar>;

  IResultadoGuiasWizardEditar = interface
    ['{A0734CF6-7DB9-4273-87D3-6C7093AB4C83}']
    function DataSet: TDataSet;
  end;

  IRepositorioWizardEditar = interface
    ['{AC9F76EE-F0A5-4237-960B-42BCC8538DA5}']
    function ListarFormatos(
      const AInforme, AUsuario, AGrupo, ATodos: string): TCadenasWizardEditar;
    function PrepararGuias(
      const AInforme: string): IResultadoGuiasWizardEditar;
    function ListarTablas: TCadenasWizardEditar;
    function ListarCamposTabla(
      const ATabla: string): TCamposTablaWizardEditar;
    function ResolverCamposDataSet(
      ADataSet: TDataSet): TCadenasWizardEditar;
  end;

implementation

end.
