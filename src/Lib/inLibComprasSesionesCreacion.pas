{******************************************************************************}
{                                                                              }
{  Modulo:       inLibComprasSesionesCreacion                                  }
{    Tipo:       Dominio                                                       }
{ Version:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Decisiones del flujo de creacion de documentos desde una sesion de        }
{    compra: cuando se puede materializar, que valores propone el dialogo      }
{    y como se traducen los ajustes elegidos.                                  }
{                                                                              }
{    Sale de TfrmMtoComprasSesiones.btnCrearClick, donde vivia mezclado        }
{    con la VCL y no se podia probar. No conoce formularios, DevExpress        }
{    ni UniDAC. Las reglas trabajan sobre records; solo la traduccion          }
{    final conoce TDataSet, y se prueba con un TClientDataSet en memoria       }
{    (PLAN_SOLID.md Fase 3; LIBRO_DE_ESTILO_DELPHI.md 14.4).                   }
{******************************************************************************}
unit inLibComprasSesionesCreacion;

interface

uses
  inLibComprasSesionesIntf;

type
  // Estado de la cabecera de sesion que necesitan las reglas. Lo
  // rellena el llamante leyendo su dataset; aqui no se sabe de donde
  // viene.
  TEstadoSesionCreacion = record
    HayCabecera: Boolean;
    Estado: string;
    Serie: string;
    Numero: string;
    Empresa: string;
    Almacen: string;
    Tarifa: string;
    Temporada: Integer;
    TieneTemporada: Boolean;
    GeneraPedido: Boolean;
    GeneraAlbaran: Boolean;
    FormatoDistribuido: Boolean;
    RefProveedor: string;
    FechaSesion: TDateTime;
    FormaPago: string;
  end;

  TMotivoBloqueoCreacion = (
    mbcNinguno,
    mbcSinCabecera,
    mbcYaMaterializada);

  // Lo que el dialogo de creacion debe mostrar de entrada.
  TDefectosDialogoCreacion = record
    SerieAlbaran: string;
    SeriePedido: string;
    Almacen: string;
    Tarifa: string;
    Temporada: Integer;
    GeneraPedido: Boolean;
    GeneraAlbaran: Boolean;
    RefProveedor: string;
    MostrarOpcionAgrupacion: Boolean;
  end;

  // Lo que el usuario confirmo en el dialogo.
  TAjustesCreacionElegidos = record
    SerieAlbaran: string;
    SeriePedido: string;
    Almacen: string;
    Tarifa: string;
    Temporada: Integer;
    GeneraPedido: Boolean;
    GeneraAlbaran: Boolean;
    RefProveedor: string;
    UnDocumentoPorAlmacen: Boolean;
    // Fecha y forma de pago de los documentos (diálogo común); se dejan en
    // la cabecera de la sesión, de donde las toma la materialización.
    Fecha: TDateTime;
    FormaPago: string;
    // Hora del movimiento de los albaranes.
    ConHora: Boolean;
    Hora: TDateTime;
    // Artículos con precio vigente en la tarifa (FZ-ISSUE-638).
    OpcionesTarifa: TOpcionesTarifaSesion;
  end;

  // Valores que hay que dejar en la cabecera antes de materializar. Las
  // series NO viajan aqui: pueden cambiar en cada materializacion y van
  // como parametros del caso de uso.
  TCabeceraSesionActualizada = record
    Almacen: string;
    Tarifa: string;
    Temporada: Integer;
    LimpiarTemporada: Boolean;
    GeneraPedido: Boolean;
    GeneraAlbaran: Boolean;
    RefProveedor: string;
    // 0 / vacía = no se cambian.
    Fecha: TDateTime;
    FormaPago: string;
  end;

// Por que no se puede materializar todavia, si es que no se puede.
function EvaluarBloqueoCreacionSesion(
  const AEstado: TEstadoSesionCreacion): TMotivoBloqueoCreacion;

// Serie que propone el dialogo: la de la empresa por tipo de documento
// y, si no hay, la propia serie de la sesion.
function SerieCreacionPropuesta(
  const ASerieEmpresa, ASerieSesion: string): string;

// Conserva la fecha de la sesión, también al rematerializar tras revertir.
function FechaCreacionPropuesta(
  const AFechaSesion, AFechaActual: TDateTime): TDateTime;

// Valores iniciales del dialogo. ASerieAlbEmpresa / ASeriePedEmpresa
// son las series por defecto que el llamante resolvio contra la BBDD.
function CalcularDefectosDialogoCreacion(
  const AEstado: TEstadoSesionCreacion;
  const ASerieAlbEmpresa, ASeriePedEmpresa: string):
  TDefectosDialogoCreacion;

// Traduce lo elegido a los valores de la cabecera.
function ComponerCabeceraActualizada(
  const AElegidos: TAjustesCreacionElegidos):
  TCabeceraSesionActualizada;

// Traduce lo elegido a los parametros del caso de uso.
function ComponerParametrosMaterializacion(
  const AUsuario: string;
  const AElegidos: TAjustesCreacionElegidos):
  TParametrosMaterializacionSesion;

implementation

uses
  System.SysUtils, System.StrUtils;

const
  cEstadoSesionCerrada = 'CERRADA';

function EvaluarBloqueoCreacionSesion(
  const AEstado: TEstadoSesionCreacion): TMotivoBloqueoCreacion;
begin
  if not AEstado.HayCabecera then
    Result := mbcSinCabecera
  else if SameText(Trim(AEstado.Estado), cEstadoSesionCerrada) then
    Result := mbcYaMaterializada
  else
    Result := mbcNinguno;
end;

function SerieCreacionPropuesta(
  const ASerieEmpresa, ASerieSesion: string): string;
begin
  Result := Trim(ASerieEmpresa);
  if Result = '' then
    Result := Trim(ASerieSesion);
end;

function FechaCreacionPropuesta(
  const AFechaSesion, AFechaActual: TDateTime): TDateTime;
begin
  if AFechaSesion > 0 then
    Result := Trunc(AFechaSesion)
  else
    Result := Trunc(AFechaActual);
end;

function CalcularDefectosDialogoCreacion(
  const AEstado: TEstadoSesionCreacion;
  const ASerieAlbEmpresa, ASeriePedEmpresa: string):
  TDefectosDialogoCreacion;
begin
  Result := Default(TDefectosDialogoCreacion);
  Result.SerieAlbaran :=
    SerieCreacionPropuesta(ASerieAlbEmpresa, AEstado.Serie);
  Result.SeriePedido :=
    SerieCreacionPropuesta(ASeriePedEmpresa, AEstado.Serie);
  Result.Almacen := AEstado.Almacen;
  Result.Tarifa := AEstado.Tarifa;
  if AEstado.TieneTemporada then
    Result.Temporada := AEstado.Temporada
  else
    Result.Temporada := 0;
  Result.GeneraPedido := AEstado.GeneraPedido;
  // Escenario tipico de muestrarios: si la cabecera ya trae almacen se
  // propone generar albaran aunque el flag no este marcado.
  Result.GeneraAlbaran :=
    AEstado.GeneraAlbaran or (Trim(AEstado.Almacen) <> '');
  Result.RefProveedor := AEstado.RefProveedor;
  // Agrupar o un documento por almacen solo tiene sentido con formato
  // distribuido: en modo clasico hay un unico almacen efectivo.
  Result.MostrarOpcionAgrupacion := AEstado.FormatoDistribuido;
end;

function ComponerCabeceraActualizada(
  const AElegidos: TAjustesCreacionElegidos):
  TCabeceraSesionActualizada;
begin
  Result := Default(TCabeceraSesionActualizada);
  Result.Almacen := AElegidos.Almacen;
  Result.Tarifa := AElegidos.Tarifa;
  Result.LimpiarTemporada := AElegidos.Temporada <= 0;
  if not Result.LimpiarTemporada then
    Result.Temporada := AElegidos.Temporada;
  Result.GeneraPedido := AElegidos.GeneraPedido;
  Result.GeneraAlbaran := AElegidos.GeneraAlbaran;
  Result.RefProveedor := AElegidos.RefProveedor;
  Result.Fecha := AElegidos.Fecha;
  Result.FormaPago := AElegidos.FormaPago;
end;

function ComponerParametrosMaterializacion(
  const AUsuario: string;
  const AElegidos: TAjustesCreacionElegidos):
  TParametrosMaterializacionSesion;
begin
  Result := Default(TParametrosMaterializacionSesion);
  Result.Usuario := AUsuario;
  Result.SerieAlbaran := AElegidos.SerieAlbaran;
  Result.SeriePedido := AElegidos.SeriePedido;
  Result.UnDocumentoPorAlmacen := AElegidos.UnDocumentoPorAlmacen;
  Result.ConHora := AElegidos.ConHora;
  Result.Hora := AElegidos.Hora;
  Result.OpcionesTarifa := AElegidos.OpcionesTarifa;
end;

end.
