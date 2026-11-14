{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoCajaOperacionVclInyeccion                              }
{    Tipo:       Composicion UniDAC/VCL                                        }
{ Version:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Compone los servicios internos de una ventana de operacion de caja.      }
{******************************************************************************}
unit inMtoCajaOperacionVclInyeccion;

interface

uses
  System.Classes,
  Uni,
  inLibCajaVentaIntf,
  inLibCatalogoSqlIntf,
  inLibContextoSesionIntf,
  inLibLogIntf,
  inLibParametrosIntf,
  inLibPerfilesUsuarioIntf,
  inLibPermisosIntf,
  inLibPreviewTicket,
  inLibTicketsCajaIntf,
  inLibUnidadesMedida,
  UniDataCaja;

function CrearDependenciasOperacionCajaVclUniDAC(
  APropietario: TComponent;
  const AParametrosApp: IParametrosAplicacion;
  const APreviewTicket: IPreviewTicket;
  AUnidades: TUnidadesMedida;
  AConexion: TUniConnection;
  const AParametrosCaja: IParametrosCaja;
  const APermisos: IPermisosAplicacion;
  const AContextoSesion: IContextoSesionAplicacion;
  const APerfilesLectura: ILectorPerfilesUsuario;
  const APerfilesEscritura: IEscritorPerfilesUsuario;
  const ARegistroLog: IRegistroLog;
  const ARepositoriosTickets: TRepositoriosTicketsCaja;
  const ANombreFormulario: string;
  ADatosCaja: TdmCajaOpe;
  out AIncidenciasSql: IRegistroIncidenciasSql
): TContextoDependenciasOperacionCaja;

implementation

uses
  UniDataFormatoDocumentoRepositorio,
  System.SysUtils,
  inLibCajaOpeComposicion,
  inLibFacturasPersistenciaIntf,
  inMtoCajaImpresorVenta,
  UniDataCajaConsultasRepositorio,
  UniDataCajaStockRepositorio,
  UniDataCajaUnidadTrabajo,
  UniDataCatalogoSqlAplicacion,
  UniDataFacturasOperaciones,
  UniDataVentasWsCola;

function CrearDependenciasOperacionCajaVclUniDAC(
  APropietario: TComponent;
  const AParametrosApp: IParametrosAplicacion;
  const APreviewTicket: IPreviewTicket;
  AUnidades: TUnidadesMedida;
  AConexion: TUniConnection;
  const AParametrosCaja: IParametrosCaja;
  const APermisos: IPermisosAplicacion;
  const AContextoSesion: IContextoSesionAplicacion;
  const APerfilesLectura: ILectorPerfilesUsuario;
  const APerfilesEscritura: IEscritorPerfilesUsuario;
  const ARegistroLog: IRegistroLog;
  const ARepositoriosTickets: TRepositoriosTicketsCaja;
  const ANombreFormulario: string;
  ADatosCaja: TdmCajaOpe;
  out AIncidenciasSql: IRegistroIncidenciasSql
): TContextoDependenciasOperacionCaja;
var
  CatalogoSqlActivo: Boolean;
  CatalogoSql: ICatalogoSql;
  UnidadTrabajo: IUnidadTrabajoVentaCaja;
  Impresor: IImpresorVenta;
  PersistenciaFacturas: TPersistenciaFacturas;
begin
  CatalogoSqlActivo := False;
  if Assigned(APerfilesLectura) then
  begin
    CatalogoSqlActivo := SameText(
      APerfilesLectura.ObtenerValorPerfil(
        ANombreFormulario,
        'oGetSQLFromDB',
        'False'),
      'True');
  end;
  CrearCatalogoSqlAplicacion(
    APerfilesLectura,
    APerfilesEscritura,
    CatalogoSqlActivo,
    CatalogoSql,
    AIncidenciasSql,
    ARegistroLog);
  ADatosCaja.AsignarRepositorioTicketsCaja(ARepositoriosTickets);
  Impresor := TImpresorVentaVcl.Create(
    APropietario,
    AParametrosApp,
    AConexion,
    AParametrosCaja,
    APermisos,
    ARepositoriosTickets.Tickets,
    AUnidades,
    APreviewTicket);
  UnidadTrabajo := TUnidadTrabajoVentaCajaUniDAC.Create(ADatosCaja);
  PersistenciaFacturas := CrearPersistenciaFacturasUniDAC(AConexion);
  Result := CrearServiciosOperacionCaja(
    AParametrosCaja,
    CrearCajaStockRepositorio(AConexion),
    AContextoSesion,
    Impresor,
    UnidadTrabajo,
    TRepositorioConsultasCaja.Create(
      AConexion,
      CatalogoSql,
      AIncidenciasSql),
    PersistenciaFacturas.Pdf,
    CrearRepositorioVentasWsColaUniDAC(AConexion),
    ARegistroLog, CrearFormatoDocumentoLecturas(AConexion));
end;

end.
