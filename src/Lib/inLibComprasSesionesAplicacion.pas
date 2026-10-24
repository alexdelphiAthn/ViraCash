{******************************************************************************}
{                                                                              }
{  Modulo:       inLibComprasSesionesAplicacion                                }
{    Tipo:       Aplicacion                                                    }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Orquesta la materializacion de sesiones de compra mediante puertos        }
{    independientes de VCL y de la persistencia.                               }
{******************************************************************************}
unit inLibComprasSesionesAplicacion;

interface

uses
  inLibComprasSesionesAplicacionIntf;

function CrearAplicacionMaterializacionCompraSesion(
  const AOperaciones: IOperacionesMaterializacionCompraSesion;
  const AVista: IVistaMaterializacionCompraSesion):
  IAplicacionMaterializacionCompraSesion;

implementation

uses
  System.SysUtils,
  inLibComprasSesionesCreacion,
  inLibComprasSesionesIntf, inLibComprasSesionesPreciosTalla,
  inLibMsgTrazabilidad;

type
  TAplicacionMaterializacionCompraSesion = class(
    TInterfacedObject,
    IAplicacionMaterializacionCompraSesion)
  private
    FOperaciones: IOperacionesMaterializacionCompraSesion;
    FVista: IVistaMaterializacionCompraSesion;
    function ConfirmarPreciosTarifa(
      var AAjustes: TAjustesCreacionElegidos): Boolean;
  public
    constructor Create(
      const AOperaciones: IOperacionesMaterializacionCompraSesion;
      const AVista: IVistaMaterializacionCompraSesion);
    procedure Ejecutar;
  end;

constructor TAplicacionMaterializacionCompraSesion.Create(
  const AOperaciones: IOperacionesMaterializacionCompraSesion;
  const AVista: IVistaMaterializacionCompraSesion);
begin
  inherited Create;
  if not Assigned(AOperaciones) then
    raise EArgumentNilException.Create('AOperaciones');
  if not Assigned(AVista) then
    raise EArgumentNilException.Create('AVista');
  FOperaciones := AOperaciones;
  FVista := AVista;
end;

function TAplicacionMaterializacionCompraSesion.ConfirmarPreciosTarifa(
  var AAjustes: TAjustesCreacionElegidos): Boolean;
var
  Opciones: TOpcionesTarifaSesion;
  Precios: TArticulosPreciosTarifa;
begin
  Opciones := Default(TOpcionesTarifaSesion);
  Opciones.FechaDesde := Date;
  Precios := FOperaciones.CalcularPreciosTarifa(AAjustes);
  Result := True;
  if Length(Precios) > 0 then
    Result := FVista.ConfirmarPreciosTarifa(AAjustes.Tarifa, Precios,
      Opciones);
  AAjustes.OpcionesTarifa := Opciones;
end;

procedure TAplicacionMaterializacionCompraSesion.Ejecutar;
var
  bContinuar: Boolean;
  bMaterializada: Boolean;
  Estado: TEstadoSesionCreacion;
  Motivo: TMotivoBloqueoCreacion;
  Defectos: TDefectosDialogoCreacion;
  Ajustes: TAjustesCreacionElegidos;
  SinSerie: TSeriesAlmacenesSinPropia;
  Incidencias: TIncidenciasMaterializacionSesion;
  ResultadoMaterializacion: TResultadoMaterializacionSesion;
  Documento: TDocumentoMaterializado;
begin
  FVista.Registrar('MaterializacionCompraSesion INICIO');
  Estado := FOperaciones.LeerEstado;
  Motivo := EvaluarBloqueoCreacionSesion(Estado);
  bContinuar := Motivo = mbcNinguno;
  if not bContinuar then
    FVista.MostrarBloqueo(Motivo);
  if bContinuar then
  begin
    FOperaciones.GuardarEdicion;
    // Los repetidos pendientes bloquean; no se convierten en REUSAR.
    bContinuar := FOperaciones.Validar(Incidencias);
    if not bContinuar then
      FVista.MostrarIncidencias(Incidencias);
  end;
  if bContinuar then
  begin
    Defectos := FOperaciones.CalcularDefectos(Estado);
    bContinuar := FVista.SolicitarAjustes(
      Estado,
      Defectos,
      Ajustes);
  end;
  if bContinuar and Ajustes.UnDocumentoPorAlmacen then
  begin
    // Antes de tocar la cabecera: cancelar aquí no deja nada a medias.
    SinSerie := FOperaciones.SeriesSinPropia(Estado, Ajustes);
    if Length(SinSerie) > 0 then
      bContinuar := FVista.ConfirmarSeriesSinPropia(SinSerie);
  end;
  // También antes de tocar la cabecera: cancelar no deja nada a medias.
  if bContinuar then
    bContinuar := ConfirmarPreciosTarifa(Ajustes);
  if bContinuar then
  begin
    FOperaciones.ActualizarCabecera(Ajustes);
    bMaterializada := FOperaciones.Materializar(
      Ajustes,
      ResultadoMaterializacion);
    if bMaterializada then
    begin
      FOperaciones.Refrescar;
      FVista.MostrarResultado(ResultadoMaterializacion);
      if ResultadoMaterializacion.AvisoFotos <> '' then
        FVista.MostrarError(ResultadoMaterializacion.AvisoFotos);
      for Documento in ResultadoMaterializacion.Documentos do
      begin
        if Documento.LineasSinLote > 0 then
          FVista.MostrarAviso(Format(SAvisoAlbaranSesionLineasSinLote,
            [Documento.Serie, Documento.Numero, Documento.LineasSinLote]));
      end;
    end
    else
      FVista.MostrarError(ResultadoMaterializacion.MensajeError);
  end;
  FVista.Registrar('MaterializacionCompraSesion FIN');
end;

function CrearAplicacionMaterializacionCompraSesion(
  const AOperaciones: IOperacionesMaterializacionCompraSesion;
  const AVista: IVistaMaterializacionCompraSesion):
  IAplicacionMaterializacionCompraSesion;
begin
  Result := TAplicacionMaterializacionCompraSesion.Create(
    AOperaciones,
    AVista);
end;

end.
