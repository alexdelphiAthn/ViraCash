{******************************************************************************}
{                                                                              }
{  Modulo:       inLibDocumentosTrabajo                                        }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       21/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Operaciones compartidas para Documentos de Trabajo.                       }
{    Permite agregar articulos/SKUs desde stock o desde formularios que ya     }
{    resuelven el articulo activo igual que Ctrl+U / Ctrl+F.                   }
{******************************************************************************}
unit inLibDocumentosTrabajo;

interface

uses
  System.SysUtils, System.Classes, Data.DB, DBAccess, Uni,
  inLibContextoSesionIntf, inLibParametrosIntf,
  inLibArticulosResolverIntf, inLibGenBusq,
  inLibOpcionesDocumentoIntf;

const
  TIPO_DOCUMENTO_ORIGEN_ALBARAN_VENTA = 'AV';
  TIPO_DOCUMENTO_ORIGEN_ALBARAN_COMPRA = 'AB';
  TIPO_DOCUMENTO_ORIGEN_PEDIDO_VENTA = 'PE';
  TIPO_DOCUMENTO_ORIGEN_PEDIDO_COMPRA = 'PC';
  TIPO_DOCUMENTO_ORIGEN_FACTURA_VENTA = 'FC';
  TIPO_DOCUMENTO_ORIGEN_FACTURA_COMPRA = 'FP';
  TIPO_DOCUMENTO_ORIGEN_DEVOLUCION_COMPRA = 'DC';
  TIPO_DOCUMENTO_ORIGEN_VENTA_TPV = 'VE';
  TIPO_DOCUMENTO_ORIGEN_TRASPASO = 'TR';
  TIPO_DOCUMENTO_ORIGEN_PETICION_TRASPASO = 'TS';
  TIPO_DOCUMENTO_ORIGEN_SESION_COMPRA = 'SE';
  TIPO_DOCUMENTO_ORIGEN_INVENTARIO = 'IN';
  TIPO_DOCUMENTO_ORIGEN_SESION_TARIFAS = 'TARC';
  TIPO_DOCUMENTO_ORIGEN_PRESUPUESTO_VENTA = 'PR';
  // Propuesta de la distribución entre tiendas: serie fija y, como
  // número, su identificador.
  TIPO_DOCUMENTO_ORIGEN_PROPUESTA_TRASPASO = 'PT';
  SERIE_DOCUMENTO_ORIGEN_PROPUESTA_TRASPASO = 'PT';
  LIMITE_DOCUMENTOS_ORIGEN_DEFECTO = 100;
  LIMITE_DOCUMENTOS_ORIGEN_MAXIMO = 1000;

type
  TTipoDocumentoTrabajoOrigen = record
    Codigo: string;
    Descripcion: string;
  end;

  TTiposDocumentoTrabajoOrigen = TArray<TTipoDocumentoTrabajoOrigen>;

  TResolverDocTrabajoArtSku = procedure(out ACodArt, ACodSku: string) of object;

  TNombresAtributosDocumentoTrabajo = TArray<string>;

  TDocumentoTrabajoOrigen = record
    Empresa: string;
    TipoDocumento: string;
    Serie: string;
    Numero: string;
    SerieVisible: string;
    NumeroVisible: string;
    function SerieParaMostrar: string;
    function NumeroParaMostrar: string;
    procedure Clear;
  end;

  TResultadoCargaOrigenDocumentoTrabajo = record
    LineasEncontradas: Integer;
    LineasInsertadas: Integer;
    LineasOmitidas: Integer;
    TotalUnidades: Double;
    procedure Clear;
  end;

  TDocTrabajoLineaOrigen = record
    CodigoArticulo: string;
    CodigoSku: string;
    CodigoAlmacen: string;
    Lote: string;
    DescripcionArticulo: string;
    DescripcionSku: string;
    Origen: string;
    FechaCaducidad: TDateTime;
    CantidadStock: Double;
    Cantidad: Double;
    procedure Clear;
  end;

  IConsultaDocumentoTrabajo = interface
    ['{73E0E3AF-F935-4853-802A-39ACF5326677}']
    function DataSet: TDataSet;
  end;

  ICargaOrigenDocumentosTrabajo = interface
    ['{D69E07FD-C7F0-4BB7-925D-81A3760D3DC1}']
    function ConsultarUltimos(
      const AEmpresa, ATipoDocumento: string;
      ALimite: Integer): IConsultaDocumentoTrabajo;
    function PrevisualizarLineas(
      const AOrigen: TDocumentoTrabajoOrigen): IConsultaDocumentoTrabajo;
    function CargarLineas(AIdDocumento: Int64;
      const AOrigen: TDocumentoTrabajoOrigen;
      const AUsuario: string): TResultadoCargaOrigenDocumentoTrabajo;
  end;

  ILecturasDocumentosTrabajo = interface
    ['{F3A03012-91E0-4BDA-B47F-53CE11A624B8}']
    function ConsultaDocumentosAbiertos(
      const AUsuario: string): string;
    procedure CompletarDatosArticulo(
      var ALinea: TDocTrabajoLineaOrigen);
    function ConsultarTercerosEnvio(ACompra: Boolean):
      IConsultaDocumentoTrabajo;
    function TerceroDefectoEnvio(AIdDocumento: Int64;
      ACompra: Boolean): string;
    function ConsultarDestinosCompartir: IConsultaDocumentoTrabajo;
    function ListarNombresAtributos:
      TNombresAtributosDocumentoTrabajo;
  end;

  IEscrituraDocumentosTrabajo = interface
    ['{B911B05D-E00B-41FC-9B22-C0BB317A3201}']
    function CrearDocumento(const ATitulo, AEmpresa, AAlmacen,
      AUsuario: string): Int64;
    procedure InsertarLinea(AIdDocumento: Int64;
      const ALinea: TDocTrabajoLineaOrigen;
      const AUsuario: string);
  end;

  IMaterializacionDocumentosTrabajo = interface
    ['{6C6E17B1-1C0C-4EF7-92B4-8365FB52B506}']
    function SiguienteContador(
      const ASerie, ATipoDocumento, AEmpresa,
      AUsuario: string): string;
    function CrearAlbaran(
      AIdDocumento: Int64;
      const ADestino: TOpcionesDocumento;
      const AUsuario: string): Integer;
    function CrearFacturaVenta(
      AIdDocumento: Int64;
      const ADestino: TOpcionesDocumento;
      const AUsuario: string): Integer;
    function CrearPedidoCompra(
      AIdDocumento: Int64;
      const ADestino: TOpcionesDocumento;
      const AUsuario: string): Integer;
    function CrearAlbaranCompra(
      AIdDocumento: Int64;
      const ADestino: TOpcionesDocumento;
      const AUsuario: string): Integer;
    function CrearDevolucionCompra(
      AIdDocumento: Int64;
      const ADestino: TOpcionesDocumento;
      const AUsuario: string): Integer;
    function CrearInventario(
      AIdDocumento: Int64;
      const ADestino: TOpcionesDocumento;
      const AUsuario: string): Integer;
    function CrearSesionTarifa(
      AIdDocumento: Int64;
      const AUsuario: string): Int64;
  end;
  TRepositoriosDocumentosTrabajo = record
    Lecturas: ILecturasDocumentosTrabajo;
    Escritura: IEscrituraDocumentosTrabajo;
    Materializacion: IMaterializacionDocumentosTrabajo;
    CargaOrigen: ICargaOrigenDocumentosTrabajo;
  end;
  TAccionDocumentoTrabajo = (
    adtCancelar,
    adtCrear,
    adtSeleccionar
  );
  IInteraccionDocumentosTrabajo = interface
    ['{6B74E0A2-0AA6-4E5B-9818-F706FB8F2A40}']
    function ElegirDestino: TAccionDocumentoTrabajo;
    function SolicitarTitulo(
      const ATituloPropuesto: string;
      out ATitulo: string): Boolean;
    procedure InformarUnidadAgregada;
  end;

function TiposDocumentoTrabajoOrigen: TTiposDocumentoTrabajoOrigen;
function EsTipoDocumentoOrigenSoportado(
  const ATipoDocumento: string): Boolean;
function DescripcionTipoDocumentoOrigen(
  const ATipoDocumento: string): string;
function AgregarUnidadADocumentoTrabajo(AOwner: TComponent;
                                        AConexion: TUniConnection;
                                        const ARepositorios:
                                        TRepositoriosDocumentosTrabajo;
                                        const AInteraccion:
                                        IInteraccionDocumentosTrabajo;
                                        const ABusquedaVisual:
                                        IBusquedaVisual;
                                        const AContextoSesion:
                                        IContextoSesionAplicacion;
                                        const AParametrosCaja:
                                        IParametrosCaja;
                                        const ALinea: TDocTrabajoLineaOrigen;
                                        const AResolverArticulos:
                                        IArticulosResolver):
                                        Boolean;
function AgregarArticuloActivoADocumentoTrabajo(AOwner: TComponent;
                                                AConexion: TUniConnection;
                                                const ARepositorios:
                                                TRepositoriosDocumentosTrabajo;
                                                const AInteraccion:
                                                IInteraccionDocumentosTrabajo;
                                                const ABusquedaVisual:
                                                IBusquedaVisual;
                                                const AContextoSesion:
                                                IContextoSesionAplicacion;
                                                const AParametrosCaja:
                                                IParametrosCaja;
                                                AResolver:
                                                TResolverDocTrabajoArtSku;
                                                const AResolverArticulos:
                                                IArticulosResolver):
                                                Boolean;

implementation

uses
  Vcl.Forms,
  inLibMsgArticulos, inLibMsgVentas;

resourcestring
  STituloBusquedaDocumentosTrabajoAbiertos =
    'Documentos de Trabajo abiertos';

procedure AsignarTipoDocumentoOrigen(
  var ATipo: TTipoDocumentoTrabajoOrigen;
  const ACodigo, ADescripcion: string);
begin
  ATipo.Codigo := ACodigo;
  ATipo.Descripcion := ADescripcion;
end;

function TiposDocumentoTrabajoOrigen: TTiposDocumentoTrabajoOrigen;
begin
  SetLength(Result, 15);
  AsignarTipoDocumentoOrigen(Result[0],
    TIPO_DOCUMENTO_ORIGEN_ALBARAN_VENTA,
    SDescripcionTipoOrigenAlbaranVentaDocumentoTrabajo);
  AsignarTipoDocumentoOrigen(Result[1],
    TIPO_DOCUMENTO_ORIGEN_ALBARAN_COMPRA,
    SDescripcionTipoOrigenAlbaranCompraDocumentoTrabajo);
  AsignarTipoDocumentoOrigen(Result[2],
    TIPO_DOCUMENTO_ORIGEN_PEDIDO_VENTA,
    SDescripcionTipoOrigenPedidoVentaDocumentoTrabajo);
  AsignarTipoDocumentoOrigen(Result[3],
    TIPO_DOCUMENTO_ORIGEN_PEDIDO_COMPRA,
    SDescripcionTipoOrigenPedidoCompraDocumentoTrabajo);
  AsignarTipoDocumentoOrigen(Result[4],
    TIPO_DOCUMENTO_ORIGEN_FACTURA_VENTA,
    SDescripcionTipoOrigenFacturaVentaDocumentoTrabajo);
  AsignarTipoDocumentoOrigen(Result[5],
    TIPO_DOCUMENTO_ORIGEN_FACTURA_COMPRA,
    SDescripcionTipoOrigenFacturaCompraDocumentoTrabajo);
  AsignarTipoDocumentoOrigen(Result[6],
    TIPO_DOCUMENTO_ORIGEN_DEVOLUCION_COMPRA,
    SDescripcionTipoOrigenDevolucionCompraDocumentoTrabajo);
  AsignarTipoDocumentoOrigen(Result[7],
    TIPO_DOCUMENTO_ORIGEN_VENTA_TPV,
    SDescripcionTipoOrigenVentaTpvDocumentoTrabajo);
  AsignarTipoDocumentoOrigen(Result[8],
    TIPO_DOCUMENTO_ORIGEN_TRASPASO,
    SDescripcionTipoOrigenTraspasoDocumentoTrabajo);
  AsignarTipoDocumentoOrigen(Result[9],
    TIPO_DOCUMENTO_ORIGEN_PETICION_TRASPASO,
    SDescripcionTipoOrigenPeticionTraspasoDocumentoTrabajo);
  AsignarTipoDocumentoOrigen(Result[10],
    TIPO_DOCUMENTO_ORIGEN_SESION_COMPRA,
    SDescripcionTipoOrigenSesionCompraDocumentoTrabajo);
  AsignarTipoDocumentoOrigen(Result[11],
    TIPO_DOCUMENTO_ORIGEN_INVENTARIO,
    SDescripcionTipoOrigenInventarioDocumentoTrabajo);
  AsignarTipoDocumentoOrigen(Result[12],
    TIPO_DOCUMENTO_ORIGEN_SESION_TARIFAS,
    SDescripcionTipoOrigenSesionTarifasDocumentoTrabajo);
  AsignarTipoDocumentoOrigen(Result[13],
    TIPO_DOCUMENTO_ORIGEN_PROPUESTA_TRASPASO,
    SDescripcionTipoOrigenPropuestaTraspasoDocumentoTrabajo);
  AsignarTipoDocumentoOrigen(Result[14],
    TIPO_DOCUMENTO_ORIGEN_PRESUPUESTO_VENTA,
    SDescripcionTipoOrigenPresupuestoVentaDocumentoTrabajo);
end;

function EsTipoDocumentoOrigenSoportado(
  const ATipoDocumento: string): Boolean;
var
  Tipos: TTiposDocumentoTrabajoOrigen;
  I: Integer;
begin
  Result := False;
  Tipos := TiposDocumentoTrabajoOrigen;
  for I := Low(Tipos) to High(Tipos) do
  begin
    if SameText(Tipos[I].Codigo, Trim(ATipoDocumento)) then
      Result := True;
  end;
end;

function DescripcionTipoDocumentoOrigen(
  const ATipoDocumento: string): string;
var
  Tipos: TTiposDocumentoTrabajoOrigen;
  I: Integer;
begin
  Result := '';
  Tipos := TiposDocumentoTrabajoOrigen;
  for I := Low(Tipos) to High(Tipos) do
  begin
    if SameText(Tipos[I].Codigo, Trim(ATipoDocumento)) then
      Result := Tipos[I].Descripcion;
  end;
end;

function TDocumentoTrabajoOrigen.SerieParaMostrar: string;
begin
  Result := Trim(SerieVisible);
  if Result = '' then
    Result := Trim(Serie);
end;

function TDocumentoTrabajoOrigen.NumeroParaMostrar: string;
begin
  Result := Trim(NumeroVisible);
  if Result = '' then
    Result := Trim(Numero);
end;

procedure TDocumentoTrabajoOrigen.Clear;
begin
  Empresa := '';
  TipoDocumento := '';
  Serie := '';
  Numero := '';
  SerieVisible := '';
  NumeroVisible := '';
end;

procedure TResultadoCargaOrigenDocumentoTrabajo.Clear;
begin
  LineasEncontradas := 0;
  LineasInsertadas := 0;
  LineasOmitidas := 0;
  TotalUnidades := 0;
end;

procedure TDocTrabajoLineaOrigen.Clear;
begin
  CodigoArticulo := '';
  CodigoSku := '';
  CodigoAlmacen := '';
  Lote := '';
  DescripcionArticulo := '';
  DescripcionSku := '';
  Origen := '';
  FechaCaducidad := 0;
  CantidadStock := 0;
  Cantidad := 0;
end;

function CrearDocumentoTrabajo(
                               const ARepositorio:
                               IEscrituraDocumentosTrabajo;
                               const AContextoSesion:
                               IContextoSesionAplicacion;
                               const ATitulo: string): Int64;
var
  Identidad: TIdentidadSesion;
  Ubicacion: TUbicacionSesion;
begin
  Result := 0;
  Identidad := AContextoSesion.Identidad;
  Ubicacion := AContextoSesion.Ubicacion;
  if ARepositorio <> nil then
    Result := ARepositorio.CrearDocumento(
      ATitulo,
      Ubicacion.Empresa,
      Ubicacion.Almacen,
      Identidad.Usuario);
end;

function SeleccionarDocumentoTrabajo(AOwner: TComponent;
                                     AConexion: TUniConnection;
                                     const ARepositorios:
                                     TRepositoriosDocumentosTrabajo;
                                     const AInteraccion:
                                     IInteraccionDocumentosTrabajo;
                                     const ABusquedaVisual:
                                     IBusquedaVisual;
                                     const AContextoSesion:
                                     IContextoSesionAplicacion;
                                     out AIdDtr: Int64): Boolean;
var
  Accion: TAccionDocumentoTrabajo;
  sTituloPropuesto: string;
  sTitulo: string;
  sId: string;
  sConsulta: string;
  frmParent: TCustomForm;
begin
  Result := False;
  AIdDtr := 0;
  frmParent := nil;
  if AOwner is TCustomForm then
  begin
    frmParent := TCustomForm(AOwner);
  end;
  Accion := adtCancelar;
  if Assigned(AInteraccion) then
  begin
    Accion := AInteraccion.ElegirDestino;
  end;
  if Accion = adtCrear then
  begin
    sTituloPropuesto := 'Documento de trabajo ' +
      FormatDateTime('dd/mm/yyyy hh:nn', Now);
    if Assigned(AInteraccion) and
       AInteraccion.SolicitarTitulo(sTituloPropuesto, sTitulo) then
    begin
      if Trim(sTitulo) <> '' then
      begin
        AIdDtr := CrearDocumentoTrabajo(
          ARepositorios.Escritura,
          AContextoSesion,
          Trim(sTitulo));
        Result := AIdDtr > 0;
      end;
    end;
  end
  else if Accion = adtSeleccionar then
  begin
    sConsulta := '';
    if ARepositorios.Lecturas <> nil then
      sConsulta := ARepositorios.Lecturas.ConsultaDocumentosAbiertos(
        AContextoSesion.Identidad.Usuario);
    if ABusquedaVisual.EjecutarBusqueda(AConexion,
                                       STituloBusquedaDocumentosTrabajoAbiertos,
                                       sConsulta, 'ID_DTR', sId,
                                       'frmBuscarDocumentosTrabajo',
                                       frmParent) then
    begin
      AIdDtr := StrToInt64Def(sId, 0);
      Result := AIdDtr > 0;
    end;
  end;
end;

procedure CompletarDatosArticulo(
                                 const ARepositorio:
                                 ILecturasDocumentosTrabajo;
                                 var ALinea: TDocTrabajoLineaOrigen);
begin
  if ARepositorio <> nil then
    ARepositorio.CompletarDatosArticulo(ALinea);
end;

procedure ResolverSkuSiEsUnico(
  const AResolverArticulos: IArticulosResolver;
  var ALinea: TDocTrabajoLineaOrigen);
var
  oDatos: TArticuloDatos;
begin
  if Assigned(AResolverArticulos) and
     (Trim(ALinea.CodigoArticulo) <> '') and
     (Trim(ALinea.CodigoSku) = '') then
  begin
    oDatos := AResolverArticulos.ResolverDatos(
      ALinea.CodigoArticulo,
      '',
      '',
      Date,
      ALinea.CodigoAlmacen);
    if oDatos.Encontrado and
       (not oDatos.RequiereSku) then
    begin
      ALinea.CodigoSku := oDatos.CodigoSku;
      if Trim(ALinea.DescripcionArticulo) = '' then
      begin
        ALinea.DescripcionArticulo :=
          oDatos.DescripcionArticulo;
      end;
      if Trim(ALinea.DescripcionSku) = '' then
      begin
        ALinea.DescripcionSku :=
          oDatos.DescripcionSku;
      end;
    end;
  end;
end;

procedure InsertarLineaDocumentoTrabajo(
                                        const ARepositorio:
                                        IEscrituraDocumentosTrabajo;
                                        const AContextoSesion:
                                        IContextoSesionAplicacion;
                                        AIdDtr: Int64;
                                        const ALinea:
                                        TDocTrabajoLineaOrigen);
begin
  if ARepositorio <> nil then
    ARepositorio.InsertarLinea(
      AIdDtr,
      ALinea,
      AContextoSesion.Identidad.Usuario);
end;

function AgregarUnidadADocumentoTrabajo(AOwner: TComponent;
                                        AConexion: TUniConnection;
                                        const ARepositorios:
                                        TRepositoriosDocumentosTrabajo;
                                        const AInteraccion:
                                        IInteraccionDocumentosTrabajo;
                                        const ABusquedaVisual:
                                        IBusquedaVisual;
                                        const AContextoSesion:
                                        IContextoSesionAplicacion;
                                        const AParametrosCaja:
                                        IParametrosCaja;
                                        const ALinea: TDocTrabajoLineaOrigen;
                                        const AResolverArticulos:
                                        IArticulosResolver):
                                        Boolean;
var
  rLinea: TDocTrabajoLineaOrigen;
  iIdDtr: Int64;
begin
  Result := False;
  rLinea := ALinea;
  ResolverSkuSiEsUnico(
    AResolverArticulos,
    rLinea);
  if Trim(rLinea.CodigoArticulo) = '' then
  begin
    raise Exception.Create(SErrorArticuloDocumentoTrabajoNoActivo);
  end;
  if Trim(rLinea.CodigoSku) = '' then
  begin
    raise Exception.Create(SErrorArticuloDocumentoTrabajoVariosSkus);
  end;
  CompletarDatosArticulo(ARepositorios.Lecturas, rLinea);
  if Trim(rLinea.Origen) = '' then
  begin
    rLinea.Origen := 'MANUAL';
  end;
  if SeleccionarDocumentoTrabajo(
    AOwner, AConexion, ARepositorios, AInteraccion, ABusquedaVisual,
    AContextoSesion, iIdDtr) then
  begin
    InsertarLineaDocumentoTrabajo(
      ARepositorios.Escritura,
      AContextoSesion,
      iIdDtr,
      rLinea);
    if Assigned(AInteraccion) then
    begin
      AInteraccion.InformarUnidadAgregada;
    end;
    Result := True;
  end;
end;

function AgregarArticuloActivoADocumentoTrabajo(AOwner: TComponent;
                                                AConexion: TUniConnection;
                                                const ARepositorios:
                                                TRepositoriosDocumentosTrabajo;
                                                const AInteraccion:
                                                IInteraccionDocumentosTrabajo;
                                                const ABusquedaVisual:
                                                IBusquedaVisual;
                                                const AContextoSesion:
                                                IContextoSesionAplicacion;
                                                const AParametrosCaja:
                                                IParametrosCaja;
                                                AResolver:
                                                TResolverDocTrabajoArtSku;
                                                const AResolverArticulos:
                                                IArticulosResolver):
                                                Boolean;
var
  rLinea: TDocTrabajoLineaOrigen;
begin
  rLinea.Clear;
  if Assigned(AResolver) then
  begin
    AResolver(rLinea.CodigoArticulo, rLinea.CodigoSku);
  end;
  rLinea.CodigoAlmacen := AContextoSesion.Ubicacion.Almacen;
  rLinea.CantidadStock := 0;
  rLinea.Cantidad := 1;
  rLinea.Origen := 'MTO';
  Result := AgregarUnidadADocumentoTrabajo(AOwner, AConexion,
    ARepositorios, AInteraccion,
    ABusquedaVisual, AContextoSesion, AParametrosCaja, rLinea,
    AResolverArticulos);
end;

end.
