{******************************************************************************}
{                                                                              }
{  Módulo:       inLibComprasSesionesMaterializar                              }
{    Tipo:       Librería                                                      }
{ Versión:       2.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Orquesta materialización y reversión sin conocer UniDAC ni la BBDD.       }
{******************************************************************************}
unit inLibComprasSesionesMaterializar;

interface

uses
  inLibComprasSesionesIntf,
  inLibComprasSesionesMaterializacionIntf;

type
  TMaterializadorComprasSesiones = class
  private
    FPersistencia: IPersistenciaMaterializacionComprasSesiones;
    FUnidadTrabajo: IUnidadTrabajoMaterializacion;
    procedure MaterializarDocumentos(
      const AParametros: TParametrosMaterializacionSesion;
      const AConfiguracion: TConfiguracionMaterializacionSesion;
      const AAlmacen, ASeriePedido, ASerieAlbaran: string;
      var AResultado: TResultadoMaterializacionSesion;
      out APedido, AAlbaran: TDocumentoMaterializado);
    procedure MaterializarDocumentoUnico(
      const AParametros: TParametrosMaterializacionSesion;
      const AConfiguracion: TConfiguracionMaterializacionSesion;
      var AResultado: TResultadoMaterializacionSesion;
      out AArticulosMaterializados: Boolean);
    procedure MaterializarDocumentosPorAlmacen(
      const AParametros: TParametrosMaterializacionSesion;
      const AConfiguracion: TConfiguracionMaterializacionSesion;
      var AResultado: TResultadoMaterializacionSesion;
      out AArticulosMaterializados: Boolean);
  public
    constructor Create(
      const APersistencia: IPersistenciaMaterializacionComprasSesiones;
      const AUnidadTrabajo: IUnidadTrabajoMaterializacion);
    function ReintentarFotos(const AUsuario: string;
      out AAviso: string): Boolean;
    function Ejecutar(
      const AParametros: TParametrosMaterializacionSesion;
      out AResultado: TResultadoMaterializacionSesion): Boolean;
    // Antes de Ejecutar y fuera de la transacción: almacenes que, con un
    // documento por almacén, no tienen serie propia para el pedido o el
    // albarán que se va a crear, con la serie que usarán.
    function AlmacenesSinSeriePropia(
      const AParametros: TParametrosMaterializacionSesion;
      const AEmpresa: string;
      AGeneraPedido, AGeneraAlbaran: Boolean): TSeriesAlmacenesSinPropia;
  end;
  TRevertidorComprasSesiones = class
  private
    FPersistencia: IPersistenciaReversionComprasSesiones;
    FUnidadTrabajo: IUnidadTrabajoMaterializacion;
  public
    constructor Create(
      const APersistencia: IPersistenciaReversionComprasSesiones;
      const AUnidadTrabajo: IUnidadTrabajoMaterializacion);
    function Ejecutar(
      const AUsuario: string;
      out AMensajeError: string): Boolean;
  end;

procedure InicializarResultadoMaterializacion(
  out AResultado: TResultadoMaterializacionSesion);
procedure AgregarDocumentoMaterializado(
  var AResultado: TResultadoMaterializacionSesion;
  const ADocumento: TDocumentoMaterializado);

implementation

uses
  System.SysUtils, inLibMsgCompras;

function HoraMovimientoMaterializacion(
  const AParametros: TParametrosMaterializacionSesion): TDateTime;
begin
  Result := -1;
  if AParametros.ConHora then
    Result := Frac(AParametros.Hora);
end;

procedure InicializarResultadoMaterializacion(
  out AResultado: TResultadoMaterializacionSesion);
begin
  AResultado := Default(TResultadoMaterializacionSesion);
  SetLength(AResultado.Documentos, 0);
end;

procedure GuardarPrimerDocumento(
  var AResultado: TResultadoMaterializacionSesion;
  const ADocumento: TDocumentoMaterializado);
begin
  if SameText(ADocumento.Tipo, 'Pedido') and
     (AResultado.NumeroPedido = '') then
  begin
    AResultado.SeriePedido := ADocumento.Serie;
    AResultado.NumeroPedido := ADocumento.Numero;
  end;
  if SameText(ADocumento.Tipo, 'Albaran') and
     (AResultado.NumeroAlbaran = '') then
  begin
    AResultado.SerieAlbaran := ADocumento.Serie;
    AResultado.NumeroAlbaran := ADocumento.Numero;
  end;
end;

procedure AgregarDocumentoMaterializado(
  var AResultado: TResultadoMaterializacionSesion;
  const ADocumento: TDocumentoMaterializado);
var
  iIndice: Integer;
begin
  if ADocumento.Numero <> '' then
  begin
    iIndice := Length(AResultado.Documentos);
    SetLength(AResultado.Documentos, iIndice + 1);
    AResultado.Documentos[iIndice] := ADocumento;
    GuardarPrimerDocumento(AResultado, ADocumento);
  end;
end;

constructor TMaterializadorComprasSesiones.Create(
  const APersistencia: IPersistenciaMaterializacionComprasSesiones;
  const AUnidadTrabajo: IUnidadTrabajoMaterializacion);
begin
  inherited Create;
  if not Assigned(APersistencia) then
    raise EArgumentNilException.Create('APersistencia');
  if not Assigned(AUnidadTrabajo) then
    raise EArgumentNilException.Create('AUnidadTrabajo');
  FPersistencia := APersistencia;
  FUnidadTrabajo := AUnidadTrabajo;
end;

procedure TMaterializadorComprasSesiones.MaterializarDocumentos(
  const AParametros: TParametrosMaterializacionSesion;
  const AConfiguracion: TConfiguracionMaterializacionSesion;
  const AAlmacen, ASeriePedido, ASerieAlbaran: string;
  var AResultado: TResultadoMaterializacionSesion;
  out APedido, AAlbaran: TDocumentoMaterializado);
begin
  APedido := Default(TDocumentoMaterializado);
  AAlbaran := Default(TDocumentoMaterializado);
  if AConfiguracion.GeneraPedido then
    APedido := FPersistencia.MaterializarPedido(
      AParametros.Usuario, ASeriePedido, AAlmacen);
  try
    if AConfiguracion.GeneraAlbaran then
      AAlbaran := FPersistencia.MaterializarAlbaran(
        AParametros.Usuario, ASerieAlbaran, AAlmacen,
        HoraMovimientoMaterializacion(AParametros));
  except
    if AConfiguracion.GeneraPedido then
      AgregarDocumentoMaterializado(AResultado, APedido);
    raise;
  end;
  if AConfiguracion.GeneraAlbaran then
    AgregarDocumentoMaterializado(AResultado, AAlbaran);
  if AConfiguracion.GeneraPedido then
    AgregarDocumentoMaterializado(AResultado, APedido);
end;

procedure TMaterializadorComprasSesiones.MaterializarDocumentoUnico(
  const AParametros: TParametrosMaterializacionSesion;
  const AConfiguracion: TConfiguracionMaterializacionSesion;
  var AResultado: TResultadoMaterializacionSesion;
  out AArticulosMaterializados: Boolean);
var
  oAlbaran: TDocumentoMaterializado;
  oPedido: TDocumentoMaterializado;
begin
  FPersistencia.MaterializarArticulos(AParametros.Usuario,
    AParametros.OpcionesTarifa);
  AArticulosMaterializados := True;
  MaterializarDocumentos(
    AParametros,
    AConfiguracion,
    AConfiguracion.AlmacenCabecera,
    AParametros.SeriePedido,
    AParametros.SerieAlbaran,
    AResultado,
    oPedido,
    oAlbaran);
  FPersistencia.CerrarSesion(
    oPedido,
    oAlbaran,
    AParametros.Usuario);
end;

procedure TMaterializadorComprasSesiones.MaterializarDocumentosPorAlmacen(
  const AParametros: TParametrosMaterializacionSesion;
  const AConfiguracion: TConfiguracionMaterializacionSesion;
  var AResultado: TResultadoMaterializacionSesion;
  out AArticulosMaterializados: Boolean);
var
  aAlmacenes: TArray<string>;
  iAlmacen: Integer;
  oAlbaran: TDocumentoMaterializado;
  oPedido: TDocumentoMaterializado;
  sAlmacen: string;
  sSerieAlbaran: string;
  sSeriePedido: string;
begin
  oPedido := Default(TDocumentoMaterializado);
  oAlbaran := Default(TDocumentoMaterializado);
  aAlmacenes := FPersistencia.ConsultarAlmacenes;
  AArticulosMaterializados := Length(aAlmacenes) > 0;
  if AArticulosMaterializados then
    FPersistencia.MaterializarArticulos(AParametros.Usuario,
      AParametros.OpcionesTarifa);
  for iAlmacen := 0 to High(aAlmacenes) do
  begin
    sAlmacen := aAlmacenes[iAlmacen];
    sSeriePedido := FPersistencia.ResolverSerieDocumento(
      AConfiguracion.Empresa,
      'PC',
      sAlmacen,
      AParametros.SeriePedido);
    sSerieAlbaran := FPersistencia.ResolverSerieDocumento(
      AConfiguracion.Empresa,
      'AB',
      sAlmacen,
      AParametros.SerieAlbaran);
    MaterializarDocumentos(
      AParametros,
      AConfiguracion,
      sAlmacen,
      sSeriePedido,
      sSerieAlbaran,
      AResultado,
      oPedido,
      oAlbaran);
  end;
  if Length(aAlmacenes) > 0 then
    FPersistencia.CerrarSesion(
      oPedido,
      oAlbaran,
      AParametros.Usuario);
end;

function TMaterializadorComprasSesiones.AlmacenesSinSeriePropia(
  const AParametros: TParametrosMaterializacionSesion;
  const AEmpresa: string;
  AGeneraPedido, AGeneraAlbaran: Boolean): TSeriesAlmacenesSinPropia;
var
  aSinSerie: TSeriesAlmacenesSinPropia;

  procedure Comprobar(const AAlmacen, ATipo, ASerie: string);
  var
    Sin: TSerieAlmacenSinPropia;
  begin
    // Sin alternativa, ResolverSerieDocumento solo devuelve la propia.
    if FPersistencia.ResolverSerieDocumento(
      AEmpresa, ATipo, AAlmacen, '') = '' then
    begin
      Sin.Almacen := AAlmacen;
      Sin.TipoDocumento := ATipo;
      Sin.Serie := ASerie;
      aSinSerie := aSinSerie + [Sin];
    end;
  end;

var
  sAlmacen: string;
begin
  aSinSerie := nil;
  if AParametros.UnDocumentoPorAlmacen then
    for sAlmacen in FPersistencia.ConsultarAlmacenes do
    begin
      if AGeneraPedido then
        Comprobar(sAlmacen, 'PC', AParametros.SeriePedido);
      if AGeneraAlbaran then
        Comprobar(sAlmacen, 'AB', AParametros.SerieAlbaran);
    end;
  Result := aSinSerie;
end;

function TMaterializadorComprasSesiones.Ejecutar(
  const AParametros: TParametrosMaterializacionSesion;
  out AResultado: TResultadoMaterializacionSesion): Boolean;
var
  oConfiguracion: TConfiguracionMaterializacionSesion;
  ArticulosMaterializados: Boolean;
  sMensajeError: string;
begin
  Result := False;
  ArticulosMaterializados := False;
  InicializarResultadoMaterializacion(AResultado);
  FUnidadTrabajo.Iniciar;
  try
    if not FPersistencia.ValidarMaterializacion(sMensajeError) then
      raise Exception.Create(sMensajeError);
    oConfiguracion := FPersistencia.CargarConfiguracion;
    if AParametros.UnDocumentoPorAlmacen then
      MaterializarDocumentosPorAlmacen(
        AParametros,
        oConfiguracion,
        AResultado,
        ArticulosMaterializados)
    else
      MaterializarDocumentoUnico(
        AParametros,
        oConfiguracion,
        AResultado,
        ArticulosMaterializados);
    FUnidadTrabajo.Confirmar;
    Result := True;
  except
    on E: Exception do
    begin
      FUnidadTrabajo.Revertir;
      if AResultado.MensajeError = '' then
        AResultado.MensajeError := E.Message;
      FPersistencia.RegistrarError(
        AParametros.Usuario,
        AResultado.MensajeError);
    end;
  end;
  if Result and ArticulosMaterializados then
    ReintentarFotos(AParametros.Usuario, AResultado.AvisoFotos);
end;

function TMaterializadorComprasSesiones.ReintentarFotos(
  const AUsuario: string; out AAviso: string): Boolean;
begin
  Result := False;
  AAviso := '';
  try
    FPersistencia.MigrarFotosConfirmadas(AUsuario);
    Result := True;
  except
    on E: Exception do
      AAviso := Format(SAvisoFotosSesionPendientes, [E.Message]);
  end;
end;

constructor TRevertidorComprasSesiones.Create(
  const APersistencia: IPersistenciaReversionComprasSesiones;
  const AUnidadTrabajo: IUnidadTrabajoMaterializacion);
begin
  inherited Create;
  if not Assigned(APersistencia) then
    raise EArgumentNilException.Create('APersistencia');
  if not Assigned(AUnidadTrabajo) then
    raise EArgumentNilException.Create('AUnidadTrabajo');
  FPersistencia := APersistencia;
  FUnidadTrabajo := AUnidadTrabajo;
end;

function TRevertidorComprasSesiones.Ejecutar(
  const AUsuario: string;
  out AMensajeError: string): Boolean;
begin
  Result := False;
  AMensajeError := '';
  FUnidadTrabajo.Iniciar;
  try
    if not FPersistencia.ValidarReversion(AMensajeError) then
      raise Exception.Create(AMensajeError);
    FPersistencia.EjecutarReversion(AUsuario);
    FUnidadTrabajo.Confirmar;
    Result := True;
  except
    on E: Exception do
    begin
      FUnidadTrabajo.Revertir;
      if AMensajeError = '' then
        AMensajeError := E.Message;
    end;
  end;
end;

end.
