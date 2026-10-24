{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasProforma                                         }
{    Tipo:       Servicio de aplicación                                        }
{ Versión:       1.2.0                                                         }
{   Fecha:       23/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Valida y dirige la generación VE, TA o TV al repositorio                 }
{    correspondiente. Los traspasos se generan con la valoración por línea     }
{    simulada por el usuario; el repositorio rechaza líneas pendientes que no  }
{    figuren en ella. TV factura sólo lo vendido en la tienda destino.        }
{******************************************************************************}
unit inLibFacturasProforma;

interface

uses
  System.SysUtils,
  inLibFacturasProformaIntf, inLibOpcionesDocumentoIntf;

type
  TFacturadorOperacionesCaja = class
  private
    FRepositorio: IRepositorioFacturasProforma;
    procedure ValidarModalidad(
      AModalidad: TModalidadFacturacionCaja);
    procedure ValidarSolicitud(
      AModalidad: TModalidadFacturacionCaja;
      const ASolicitud: TSolicitudFacturacionCaja);
  public
    constructor Create(
      const ARepositorio: IRepositorioFacturasProforma);
    function Ejecutar(
      AModalidad: TModalidadFacturacionCaja;
      const ASolicitud: TSolicitudFacturacionCaja
    ): TResultadoFacturacionCaja; overload;
    // En modalidad TA las líneas se facturan con los precios de la
    // valoración; en VE la valoración se ignora.
    function Ejecutar(
      AModalidad: TModalidadFacturacionCaja;
      const ASolicitud: TSolicitudFacturacionCaja;
      const AValoracionTraspasos: TValoracionTraspasos
    ): TResultadoFacturacionCaja; overload;
    function ObtenerLineasTraspasoPendientes(
      const ASolicitud: TSolicitudFacturacionCaja
    ): TLineasTraspasoPendientes;
    // Líneas a valorar según la modalidad: el traspaso entero en TA y sólo
    // lo vendido en la tienda destino en TV.
    function ObtenerLineasAValorar(
      AModalidad: TModalidadFacturacionCaja;
      const ASolicitud: TSolicitudFacturacionCaja
    ): TLineasTraspasoPendientes;
    function RevisarPeriodo(
      AModalidad: TModalidadFacturacionCaja;
      const ASolicitud: TSolicitudFacturacionCaja
    ): TRevisionPeriodoFacturacionCaja;
    function PrepararConversionProformaVales(
      AIdProforma: Int64): TOpcionesDocumento;
    function ConvertirProformaVales(
      AIdProforma: Int64;
      const AOpciones: TOpcionesDocumento;
      const AUsuario: string): string;
  end;

resourcestring
  SErrorRepositorioFacturacionCajaNoDisponible =
    'No está disponible el repositorio de facturación de caja.';
  SErrorPeriodoFacturacionCajaObligatorio =
    'Debe indicar las fechas inicial y final del periodo.';
  SErrorPeriodoFacturacionCajaInvalido =
    'La fecha inicial no puede ser posterior a la fecha final.';
  SErrorEmpresaOrigenFacturacionCajaObligatoria =
    'Debe seleccionar una empresa emisora.';
  SErrorEmpresaDestinoFacturacionCajaObligatoria =
    'Debe seleccionar una empresa destino.';
  SErrorEmpresasTraspasoFacturacionCajaIguales =
    'La empresa emisora y la empresa destino deben ser distintas.';
  SErrorUsuarioFacturacionCajaObligatorio =
    'No se ha podido identificar al usuario que genera los documentos.';
  SErrorModalidadFacturacionCajaInvalida =
    'La modalidad de facturación de caja no es válida.';

function EsModalidadTraspaso(
  AModalidad: TModalidadFacturacionCaja): Boolean;

implementation

function EsModalidadTraspaso(
  AModalidad: TModalidadFacturacionCaja): Boolean;
begin
  Result := AModalidad in [mfcTraspaso, mfcTraspasoVendido];
end;

constructor TFacturadorOperacionesCaja.Create(
  const ARepositorio: IRepositorioFacturasProforma);
begin
  inherited Create;
  if ARepositorio = nil then
    raise EArgumentNilException.Create(
      SErrorRepositorioFacturacionCajaNoDisponible);
  FRepositorio := ARepositorio;
end;

procedure TFacturadorOperacionesCaja.ValidarSolicitud(
  AModalidad: TModalidadFacturacionCaja;
  const ASolicitud: TSolicitudFacturacionCaja);
begin
  if (ASolicitud.FechaDesde = 0) or
     (ASolicitud.FechaHasta = 0) then
    raise EArgumentException.Create(
      SErrorPeriodoFacturacionCajaObligatorio);
  if Trunc(ASolicitud.FechaDesde) > Trunc(ASolicitud.FechaHasta) then
    raise EArgumentException.Create(
      SErrorPeriodoFacturacionCajaInvalido);
  if Trim(ASolicitud.CodigoEmpresaOrigen) = '' then
    raise EArgumentException.Create(
      SErrorEmpresaOrigenFacturacionCajaObligatoria);
  if (EsModalidadTraspaso(AModalidad) or
      (AModalidad = mfcValesRecogidos)) and
     (Trim(ASolicitud.CodigoEmpresaDestino) = '') then
    raise EArgumentException.Create(
      SErrorEmpresaDestinoFacturacionCajaObligatoria);
  if (EsModalidadTraspaso(AModalidad) or
      (AModalidad = mfcValesRecogidos)) and
     SameText(
       Trim(ASolicitud.CodigoEmpresaOrigen),
       Trim(ASolicitud.CodigoEmpresaDestino)) then
    raise EArgumentException.Create(
      SErrorEmpresasTraspasoFacturacionCajaIguales);
  if Trim(ASolicitud.Usuario) = '' then
    raise EArgumentException.Create(
      SErrorUsuarioFacturacionCajaObligatorio);
end;

procedure TFacturadorOperacionesCaja.ValidarModalidad(
  AModalidad: TModalidadFacturacionCaja);
begin
  if not (AModalidad in
       [mfcVenta, mfcTraspaso, mfcTraspasoVendido,
        mfcValesRecogidos]) then
    raise EArgumentOutOfRangeException.Create(
      SErrorModalidadFacturacionCajaInvalida);
end;

function TFacturadorOperacionesCaja.Ejecutar(
  AModalidad: TModalidadFacturacionCaja;
  const ASolicitud: TSolicitudFacturacionCaja
): TResultadoFacturacionCaja;
begin
  Result := Ejecutar(AModalidad, ASolicitud, nil);
end;

function TFacturadorOperacionesCaja.Ejecutar(
  AModalidad: TModalidadFacturacionCaja;
  const ASolicitud: TSolicitudFacturacionCaja;
  const AValoracionTraspasos: TValoracionTraspasos
): TResultadoFacturacionCaja;
begin
  ValidarModalidad(AModalidad);
  ValidarSolicitud(AModalidad, ASolicitud);
  case AModalidad of
    mfcVenta:
      Result := FRepositorio.GenerarVenta(ASolicitud);
    mfcTraspaso:
      Result := FRepositorio.GenerarTraspasos(
        ASolicitud, AValoracionTraspasos);
    mfcTraspasoVendido:
      Result := FRepositorio.GenerarTraspasosVendidos(
        ASolicitud, AValoracionTraspasos);
    mfcValesRecogidos:
      Result := FRepositorio.GenerarValesRecogidos(ASolicitud);
  end;
end;

function TFacturadorOperacionesCaja.PrepararConversionProformaVales(
  AIdProforma: Int64): TOpcionesDocumento;
begin
  if AIdProforma <= 0 then
    raise EArgumentOutOfRangeException.Create(
      SErrorModalidadFacturacionCajaInvalida);
  Result := FRepositorio.PrepararConversionProformaVales(AIdProforma);
end;

function TFacturadorOperacionesCaja.ConvertirProformaVales(
  AIdProforma: Int64;
  const AOpciones: TOpcionesDocumento;
  const AUsuario: string): string;
begin
  if AIdProforma <= 0 then
    raise EArgumentOutOfRangeException.Create(
      SErrorModalidadFacturacionCajaInvalida);
  if Trim(AUsuario) = '' then
    raise EArgumentException.Create(
      SErrorUsuarioFacturacionCajaObligatorio);
  Result := FRepositorio.ConvertirProformaVales(AIdProforma, AOpciones,
    AUsuario);
end;

function TFacturadorOperacionesCaja.ObtenerLineasTraspasoPendientes(
  const ASolicitud: TSolicitudFacturacionCaja
): TLineasTraspasoPendientes;
begin
  ValidarSolicitud(mfcTraspaso, ASolicitud);
  Result := FRepositorio.ObtenerLineasTraspasoPendientes(ASolicitud);
end;

function TFacturadorOperacionesCaja.ObtenerLineasAValorar(
  AModalidad: TModalidadFacturacionCaja;
  const ASolicitud: TSolicitudFacturacionCaja
): TLineasTraspasoPendientes;
begin
  ValidarModalidad(AModalidad);
  ValidarSolicitud(AModalidad, ASolicitud);
  SetLength(Result, 0);
  case AModalidad of
    mfcTraspaso:
      Result := FRepositorio.ObtenerLineasTraspasoPendientes(ASolicitud);
    mfcTraspasoVendido:
      Result :=
        FRepositorio.ObtenerLineasTraspasoVendidoPendientes(ASolicitud);
  end;
end;

function TFacturadorOperacionesCaja.RevisarPeriodo(
  AModalidad: TModalidadFacturacionCaja;
  const ASolicitud: TSolicitudFacturacionCaja
): TRevisionPeriodoFacturacionCaja;
begin
  ValidarModalidad(AModalidad);
  ValidarSolicitud(AModalidad, ASolicitud);
  Result := FRepositorio.RevisarPeriodo(AModalidad, ASolicitud);
end;

end.
