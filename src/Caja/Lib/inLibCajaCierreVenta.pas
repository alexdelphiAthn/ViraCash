{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaCierreVenta                                          }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Coordina grabación, impresión y archivado del cierre de una venta.        }
{******************************************************************************}
unit inLibCajaCierreVenta;

interface

uses
  inLibParametrosIntf, inLibContextoSesionIntf,
  inLibCajaVentaIntf, inLibFacturasPersistenciaIntf,
  inLibVentasWsColaIntf, inLibLogIntf, inLibFormatoDocumentoLecturasIntf;

type
  TCasoUsoCierreVentaCaja = class(
    TInterfacedObject,
    ICasoUsoCierreVentaCaja)
  private
    FUnidadTrabajo: IUnidadTrabajoVentaCaja;
    FImpresor: IImpresorVenta;
    FParametrosCaja: IParametrosCaja;
    FContextoSesion: IContextoSesionAplicacion;
    FRepositorioPdf: IRepositorioPdfFactura;
    FRepositorioVentasWs: IAltaVentasWsCola;
    FRegistroLog: IRegistroLog;
    FFormatoDocumentos: IFormatoDocumentoLecturas;
    procedure ArchivarPdf(
      const ARutaPdf: string;
      const APersistencia: TResultadoPersistenciaVentaCaja);
    function PrepararImpresion(
      const ASolicitud: TSolicitudCierreVenta;
      const APersistencia: TResultadoPersistenciaVentaCaja
    ): TSolicitudImpresionVenta;
    procedure ImprimirYArchivar(
      const ASolicitud: TSolicitudCierreVenta;
      const APersistencia: TResultadoPersistenciaVentaCaja;
      var AResultado: TResultadoCierreVenta;
      const AFormatoDocumento: string);
    class procedure AnyadirAviso(var AResultado: TResultadoCierreVenta;
      const AAviso: string); static;
  public
    constructor Create(
      const AUnidadTrabajo: IUnidadTrabajoVentaCaja;
      const AImpresor: IImpresorVenta;
      const AParametrosCaja: IParametrosCaja;
      const AContextoSesion: IContextoSesionAplicacion;
      const ARepositorioPdf: IRepositorioPdfFactura;
      const ARepositorioVentasWs: IAltaVentasWsCola;
      const ARegistroLog: IRegistroLog = nil;
      const AFormatoDocumentos: IFormatoDocumentoLecturas = nil);
    function Ejecutar(
      const ASolicitud: TSolicitudCierreVenta
    ): TResultadoCierreVenta;
  end;

implementation

uses
  inLibFormatoDocumento,
  System.SysUtils, System.Classes, inLibVentasWsCola,
  inLibFacturaPdfBlob, inLibRegistroLogNulo, inLibMsgCaja;

constructor TCasoUsoCierreVentaCaja.Create(
  const AUnidadTrabajo: IUnidadTrabajoVentaCaja;
  const AImpresor: IImpresorVenta;
  const AParametrosCaja: IParametrosCaja;
  const AContextoSesion: IContextoSesionAplicacion;
  const ARepositorioPdf: IRepositorioPdfFactura;
  const ARepositorioVentasWs: IAltaVentasWsCola;
  const ARegistroLog: IRegistroLog;
  const AFormatoDocumentos: IFormatoDocumentoLecturas);
begin
  inherited Create;
  FUnidadTrabajo := AUnidadTrabajo;
  FImpresor := AImpresor;
  FParametrosCaja := AParametrosCaja;
  FContextoSesion := AContextoSesion;
  FRepositorioPdf := ARepositorioPdf;
  FRepositorioVentasWs := ARepositorioVentasWs;
  FRegistroLog := ARegistroLog;
  FFormatoDocumentos := AFormatoDocumentos;
  if not Assigned(FRegistroLog) then
    FRegistroLog := CrearRegistroLogNulo;
end;

procedure TCasoUsoCierreVentaCaja.ArchivarPdf(
  const ARutaPdf: string;
  const APersistencia: TResultadoPersistenciaVentaCaja);
var
  sUsuario: string;
begin
  sUsuario := '';
  if Assigned(FContextoSesion) then
    sUsuario := FContextoSesion.Identidad.Usuario;
  TVentasWsCola.AdjuntarTicketPdfSeguro(
    FParametrosCaja,
    FRepositorioVentasWs,
    sUsuario,
    APersistencia.UltimaSerieFactura,
    APersistencia.UltimoNumeroFactura,
    ARutaPdf,
    FRegistroLog);
  GuardarPdfFacturaEnBlob(
    FRepositorioPdf,
    FContextoSesion,
    APersistencia.UltimaSerieFactura,
    APersistencia.UltimoNumeroFactura,
    ARutaPdf,
    'TicketTermico',
    FRegistroLog);
end;

function TCasoUsoCierreVentaCaja.PrepararImpresion(
  const ASolicitud: TSolicitudCierreVenta;
  const APersistencia: TResultadoPersistenciaVentaCaja
): TSolicitudImpresionVenta;
begin
  Result.TipoImpresion := ASolicitud.TipoImpresion;
  Result.CodigoEmpresa := ASolicitud.Grabacion.CodigoEmpresa;
  Result.CodigoAlmacen := ASolicitud.Grabacion.CodigoAlmacen;
  Result.CodigoCaja := ASolicitud.Grabacion.CodigoCaja;
  Result.NumeroOperacion := APersistencia.NumeroOperacion;
  Result.SerieFactura := APersistencia.SerieFacturaImpresion;
  Result.NumeroFactura := APersistencia.NumeroFacturaImpresion;
  Result.FechaOperacion := ASolicitud.Grabacion.FechaOperacion;
  Result.DatosCobro := ASolicitud.Grabacion.DatosCobro;
end;

function TCasoUsoCierreVentaCaja.Ejecutar(
  const ASolicitud: TSolicitudCierreVenta
): TResultadoCierreVenta;
var
  Persistencia: TResultadoPersistenciaVentaCaja;
  sFormatoDocumento: string;
begin
  Result := Default(TResultadoCierreVenta);
  sFormatoDocumento := FORMATO_DOCUMENTO_DEFECTO;
  if Assigned(FFormatoDocumentos) then
    sFormatoDocumento := FFormatoDocumentos.LeerFormatoEmpresa(
      ASolicitud.Grabacion.CodigoEmpresa);
  Persistencia := FUnidadTrabajo.Ejecutar(
    ASolicitud.Grabacion);
  Result.Grabada := Persistencia.Grabada;
  Result.NumeroGenerado := Persistencia.NumeroOperacion;
  Result.CodigoValeGenerado :=
    Persistencia.CodigoValeGenerado;
  Result.AvisoTrasGrabacion := Persistencia.AvisoTrasGrabacion;
  if Result.Grabada then
  begin
    if Assigned(ASolicitud.Grabacion.DatosCobro) then
    begin
      ASolicitud.Grabacion.DatosCobro.CodigoValeEmitido :=
        Result.CodigoValeGenerado;
    end;
    ImprimirYArchivar(ASolicitud, Persistencia, Result, sFormatoDocumento);
  end;
end;

class procedure TCasoUsoCierreVentaCaja.AnyadirAviso(
  var AResultado: TResultadoCierreVenta; const AAviso: string);
begin
  if AResultado.AvisoTrasGrabacion <> '' then
    AResultado.AvisoTrasGrabacion :=
      AResultado.AvisoTrasGrabacion + sLineBreak;
  AResultado.AvisoTrasGrabacion := AResultado.AvisoTrasGrabacion + AAviso;
end;

// La venta ya está confirmada: un fallo de impresión o de archivado no
// puede propagarse, o la pantalla la trataría como no grabada y se
// cobraría dos veces (FZ-ISSUE-145).
procedure TCasoUsoCierreVentaCaja.ImprimirYArchivar(
  const ASolicitud: TSolicitudCierreVenta;
  const APersistencia: TResultadoPersistenciaVentaCaja;
  var AResultado: TResultadoCierreVenta;
  const AFormatoDocumento: string);
var
  Impresion: TSolicitudImpresionVenta;
  RutasPdf: TStringList;
begin
  RutasPdf := TStringList.Create;
  try
    Impresion := PrepararImpresion(
      ASolicitud,
      APersistencia);
    try
      FImpresor.Imprimir(Impresion, RutasPdf);
    except
      on E: Exception do
      begin
        FRegistroLog.RegistrarError(
          'No se pudo imprimir la operación de caja ' +
          APersistencia.NumeroOperacion + ' ya grabada: ' + E.Message);
        AnyadirAviso(AResultado,
          Format(SAvisoImpresionTicketCaja, [E.Message]));
      end;
    end;
    if RutasPdf.Count = 0 then
    begin
      try
        FImpresor.GenerarPdfRespaldo(Impresion, RutasPdf);
      except
        on E: Exception do
        begin
          FRegistroLog.RegistrarError(
            'No se pudo generar el PDF de respaldo del ticket ' +
            FormatearDocumento(AFormatoDocumento,
              APersistencia.UltimaSerieFactura,
              APersistencia.UltimoNumeroFactura) + ': ' +
            E.Message);
          // Sin PDF no queda copia archivada del ticket (FZ-ISSUE-158).
          AnyadirAviso(AResultado,
            Format(SAvisoPdfTicketCaja, [E.Message]));
        end;
      end;
    end;
    if RutasPdf.Count > 0 then
    begin
      try
        ArchivarPdf(
          RutasPdf[RutasPdf.Count - 1],
          APersistencia);
      except
        on E: Exception do
        begin
          FRegistroLog.RegistrarError(
            'No se pudo archivar el PDF del ticket ' +
            FormatearDocumento(AFormatoDocumento,
              APersistencia.UltimaSerieFactura,
              APersistencia.UltimoNumeroFactura) + ': ' +
            E.Message);
          AnyadirAviso(AResultado,
            Format(SAvisoPdfTicketCaja, [E.Message]));
        end;
      end;
    end;
  finally
    FreeAndNil(RutasPdf);
  end;
end;

end.
