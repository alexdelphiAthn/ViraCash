{******************************************************************************}
{                                                                              }
{  Modulo:       inLibImpresionPersistenciaIntf                                }
{    Tipo:       Contratos de persistencia                                     }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Contratos neutrales para formatos y guias de impresion.                   }
{******************************************************************************}
unit inLibImpresionPersistenciaIntf;

interface

uses
  System.Classes, Data.DB, inLibInformesGuiasCache;

type
  TContextoFormatosImpresion = record
    Informe: string;
    Usuario: string;
    Grupo: string;
    Todos: string;
  end;

  TFormatoImpresion = record
    Descripcion: string;
    Propietario: string;
  end;

  TFormatosImpresion = TArray<TFormatoImpresion>;

  TSolicitudGuardarFormato = record
    Contexto: TContextoFormatosImpresion;
    UsuarioGrupo: string;
    Subclave: string;
    Descripcion: string;
    Insertar: Boolean;
  end;

  IRepositorioFormatosImpresion = interface
    ['{E3D923B8-59BA-4330-B926-3D8941998AA9}']
    function Listar(
      const AContexto: TContextoFormatosImpresion
    ): TFormatosImpresion;
    function Existe(
      const AContexto: TContextoFormatosImpresion;
      const ADescripcion: string
    ): Boolean;
    function Leer(
      const AContexto: TContextoFormatosImpresion;
      const ADescripcion: string;
      AStream: TStream
    ): Boolean;
    procedure Guardar(
      const ASolicitud: TSolicitudGuardarFormato;
      AStream: TStream);
    function ObtenerPropietario(
      const AInforme, ADescripcion: string
    ): string;
    procedure Eliminar(
      const AInforme, ADescripcion: string);
  end;

  IRepositorioGuiasFormatoImpresion = interface
    ['{A2C25F89-A097-4602-A679-B9B167C63DB9}']
    procedure Consolidar(
      const AInforme, AFormato, AUsuario, AContenidoInforme: string);
  end;

  IRestauracionDatasetInforme = interface
    ['{22A61307-4B43-4352-993A-7114EBFB785B}']
    procedure Restaurar;
  end;

  IEnriquecedorGuiasImpresion = interface
    ['{7EC90C87-4EC6-4F66-9619-55BEC70CBF06}']
    function Enriquecer(
      ADataSet: TDataSet;
      const AGuia: TInformeGuiaItem;
      out AError: string
    ): IRestauracionDatasetInforme;
  end;

  TServiciosPersistenciaImpresion = record
    Formatos: IRepositorioFormatosImpresion;
    Guias: IRepositorioGuiasFormatoImpresion;
    Enriquecedor: IEnriquecedorGuiasImpresion;
  end;

implementation

end.
