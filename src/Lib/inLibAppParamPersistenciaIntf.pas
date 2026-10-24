{******************************************************************************}
{                                                                              }
{  Modulo:       inLibAppParamPersistenciaIntf                                 }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de datos del editor de parametros de aplicacion.                   }
{******************************************************************************}
unit inLibAppParamPersistenciaIntf;

interface

type
  TCadenasAppParam = TArray<string>;

  TValorPerfilAppParam = record
    Subclave: string;
    Valor: string;
  end;

  TValoresPerfilAppParam = TArray<TValorPerfilAppParam>;

  IRepositorioAppParam = interface
    ['{02FBC23B-12C5-43D2-869D-DAA1466EF953}']
    function ListarIdiomas: TCadenasAppParam;
    function ListarTemporadas: TCadenasAppParam;
    function ListarNifsEmpresas: TCadenasAppParam;
    function ListarTarifas: TCadenasAppParam;
    function ListarAmbitos: TCadenasAppParam;
    // Formatos FastReport de AInforme cuyo nombre empieza por APrefijo.
    function ListarFormatosInforme(
      const AInforme, APrefijo: string
    ): TCadenasAppParam;
    function CargarValores(
      const AUsuario, AGrupo, AFormulario: string
    ): TValoresPerfilAppParam;
    procedure GuardarValores(
      const AUsuarioGrupo, AFormulario: string;
      const AValores: TValoresPerfilAppParam);
  end;

implementation

end.
