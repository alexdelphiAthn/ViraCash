{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFiltrosGuardadosIntf                                     }
{    Tipo:       Librería                                                      }
{ Versión:       2.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos segregados del servicio de filtros guardados.                   }
{******************************************************************************}
unit inLibFiltrosGuardadosIntf;

interface

uses
  System.Generics.Collections,
  inLibDestinosFiltrosPersistenciaIntf,
  inLibGuiasPersistenciaIntf;

type
  TFiltroGuardadoInfo = record
    Id: Int64;
    Nombre: string;
    Descripcion: string;
    Propietario: string;
    EsPropio: Boolean;
  end;

  TFiltrosGuardadosList = TList<TFiltroGuardadoInfo>;

  TDestinoCompartidoInfo = record
    Id: Int64;
    TipoDestino: string;
    UsuarioGrupo: string;
  end;

  TDestinosCompartidosList = TList<TDestinoCompartidoInfo>;

  ILectorFiltrosGuardados = interface
    ['{B09A610D-80AE-48E0-B311-6F72655F3859}']
    function ListarFiltros(
      const AMto, AVista: string
    ): TFiltrosGuardadosList;
    function BuscarFiltroPropio(
      const AMto, AVista, ANombre: string
    ): Int64;
    function CargarFiltroBase64(AIdFiltro: Int64): string;
  end;

  IEscritorFiltrosGuardados = interface
    ['{E73D46A5-F30F-4ADD-9513-1ABFDAA53984}']
    function GuardarFiltroNuevo(
      const AMto, AVista, ANombre, ADescripcion, AFiltroBase64: string
    ): Int64;
    procedure SobrescribirFiltro(
      AIdFiltro: Int64;
      const ANombre, ADescripcion, AFiltroBase64: string
    );
    procedure RenombrarFiltro(
      AIdFiltro: Int64;
      const ANombre, ADescripcion: string
    );
    procedure BorrarFiltro(AIdFiltro: Int64);
  end;

  ICompartidorFiltrosGuardados = interface
    ['{1B0EE945-5DD4-4EB1-A042-0A0CF7338EA9}']
    function ListarDestinosCompartidos(
      AIdFiltro: Int64
    ): TDestinosCompartidosList;
    procedure CompartirConDestino(
      AIdFiltro: Int64;
      const ATipoDestino, ADestino: string
    );
    procedure QuitarDestinoCompartido(AIdDestino: Int64);
  end;

  TServiciosFiltrosGuardados = record
    Lectura: ILectorFiltrosGuardados;
    Escritura: IEscritorFiltrosGuardados;
    Comparticion: ICompartidorFiltrosGuardados;
    Destinos: IRepositorioDestinosFiltros;
    Guias: IRepositorioGuias;
  end;

  IProveedorFiltrosGuardados = interface
    ['{DAC85C81-8021-4BBF-93D6-05A633D7B99D}']
    function GetServiciosFiltrosGuardados: TServiciosFiltrosGuardados;
    property ServiciosFiltrosGuardados: TServiciosFiltrosGuardados
      read GetServiciosFiltrosGuardados;
  end;

function CrearServiciosFiltrosGuardados(
  const ALectura: ILectorFiltrosGuardados;
  const AEscritura: IEscritorFiltrosGuardados;
  const AComparticion: ICompartidorFiltrosGuardados
): TServiciosFiltrosGuardados; overload;
function CrearServiciosFiltrosGuardados(
  const ALectura: ILectorFiltrosGuardados;
  const AEscritura: IEscritorFiltrosGuardados;
  const AComparticion: ICompartidorFiltrosGuardados;
  const ADestinos: IRepositorioDestinosFiltros
): TServiciosFiltrosGuardados; overload;

implementation

function CrearServiciosFiltrosGuardados(
  const ALectura: ILectorFiltrosGuardados;
  const AEscritura: IEscritorFiltrosGuardados;
  const AComparticion: ICompartidorFiltrosGuardados
): TServiciosFiltrosGuardados;
begin
  Result.Lectura := ALectura;
  Result.Escritura := AEscritura;
  Result.Comparticion := AComparticion;
  Result.Destinos := nil;
  Result.Guias := nil;
end;

function CrearServiciosFiltrosGuardados(
  const ALectura: ILectorFiltrosGuardados;
  const AEscritura: IEscritorFiltrosGuardados;
  const AComparticion: ICompartidorFiltrosGuardados;
  const ADestinos: IRepositorioDestinosFiltros
): TServiciosFiltrosGuardados;
begin
  Result := CrearServiciosFiltrosGuardados(
    ALectura,
    AEscritura,
    AComparticion);
  Result.Destinos := ADestinos;
end;

end.
