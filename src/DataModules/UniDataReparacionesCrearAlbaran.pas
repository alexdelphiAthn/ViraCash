{******************************************************************************}
{  Módulo: UniDataReparacionesCrearAlbaran. Tipo: Persistencia                 }
{  Fecha: 01/11/2026. Autor: Alejandro Laorden Hidalgo                         }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción: Albaranes reales desde importes pendientes de la orden.        }
{******************************************************************************}
unit UniDataReparacionesCrearAlbaran;

interface

uses
  Uni, Data.DB, Datasnap.DBClient, UniDataReparacionesDocumentoMemoria;

type
  TGeneradorAlbaranOrden = class(TDocumentoMemoriaOrden)
  private
    function TieneCobroImputado(AOrden: Int64): Boolean;
    function DatosOrden(const ASolicitud: TDocumentoOrdenNuevo): TUniQuery;
    procedure PrepararCabecera(ACabecera: TDataSet; AOrden: TUniQuery;
      const ASolicitud: TDocumentoOrdenNuevo);
    procedure PrepararLinea(ALinea, ACabecera: TDataSet; AOrden: TUniQuery;
      const ASolicitud: TDocumentoOrdenNuevo);
    procedure GuardarDocumento(ACabecera, ALinea: TDataSet;
      const ASolicitudes: TArray<TDocumentoOrdenNuevo>);
    function CrearLoteInterno(const ASolicitudes: TArray<TDocumentoOrdenNuevo>):
      TDocumentoOrdenCreado;
    function PrepararPendientes(const APlantilla: TDocumentoOrdenNuevo):
      TArray<TDocumentoOrdenNuevo>;
    function CrearInterno(const ASolicitud: TDocumentoOrdenNuevo):
      TDocumentoOrdenCreado;
  public
    function CrearPendientes(const APlantilla: TDocumentoOrdenNuevo):
      TDocumentoOrdenCreado;
    function Crear(const ASolicitud: TDocumentoOrdenNuevo):
      TDocumentoOrdenCreado;
  end;

implementation

uses
  System.SysUtils, System.StrUtils, System.Math,
  UniDataReparacionesCobertura, UniDataReparacionesImputaciones,
  inLibReparacionesCircuito, UniDataImpuestosRepositorio,
  inLibVentasImpuestos, inLibComprasImpuestos,
  inLibMsgReparacionesCircuito;

function Sufijo(const ATipo: string): string;
begin
  Result := IfThen(ATipo = 'PR', 'ALBC', 'ALB');
end;

function Tabla(const ATipo: string): string;
begin
  Result := IfThen(ATipo = 'PR', 'fza_albaranes_compra', 'fza_albaranes');
end;

function TGeneradorAlbaranOrden.TieneCobroImputado(AOrden: Int64): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta('SELECT 1 FROM fza_reparaciones_imputaciones ' +
    'WHERE ID_GAR_RCI=:ORDEN AND TIPO_RCI=''TC'' LIMIT 1');
  try
    oConsulta.ParamByName('ORDEN').AsLargeInt := AOrden;
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TGeneradorAlbaranOrden.DatosOrden(
  const ASolicitud: TDocumentoOrdenNuevo): TUniQuery;
begin
  Result := Consulta('SELECT G.CODIGO_CLI_GAR,G.CODIGO_CLI_PAGADOR_GAR,' +
    'G.SERIE_COBRO_GAR,G.NUMERO_COBRO_GAR,G.ESCOBRADO_GAR,' +
    'O.CODIGO_EMP_ALM AS EMPRESA,' +
    'COALESCE(T.CODIGO_ALM_ALM,O.CODIGO_ALM_ALM) AS TALLER,' +
    'L.DESCRIPCION_GARLIN,L.TIPO_LINEA_GARLIN,L.CODIGO_UNIDAD_GARLIN,' +
    'L.CODIGO_PRV_GARLIN ' +
    'FROM fza_garantias_reclamaciones G ' +
    'JOIN fza_almacenes O ON O.CODIGO_ALM_ALM=G.CODIGO_ALM_GAR ' +
    // Sin almacén TALLER, la tienda documenta desde el almacén de la orden:
    // las piezas manuales no mueven existencias.
    'LEFT JOIN fza_almacenes T ON T.TIPO_USO_ALM=''TALLER'' ' +
    'AND T.ESACTIVO_ALM=''S'' AND T.CODIGO_EMP_ALM=O.CODIGO_EMP_ALM ' +
    'AND (T.CODIGO_PADRE_ALM=G.CODIGO_ALM_GAR OR T.ESCOMPARTIDO_ALM=''S'') ' +
    'AND (:ALMACEN='''' OR T.CODIGO_ALM_ALM=:ALMACEN) ' +
    'JOIN fza_garantias_lineas L ON L.ID_GAR_GARLIN=G.ID_GAR ' +
    'WHERE G.ID_GAR=:ORDEN AND L.ID_GARLIN=:LINEA ' +
    'AND (T.CODIGO_ALM_ALM IS NOT NULL OR ' +
    '(O.ESACTIVO_ALM=''S'' AND (:ALMACEN='''' OR ' +
    'O.CODIGO_ALM_ALM=:ALMACEN) AND NOT EXISTS (SELECT 1 FROM ' +
    'fza_almacenes X WHERE X.TIPO_USO_ALM=''TALLER'' ' +
    'AND X.ESACTIVO_ALM=''S'' AND X.CODIGO_EMP_ALM=O.CODIGO_EMP_ALM ' +
    'AND (X.CODIGO_PADRE_ALM=G.CODIGO_ALM_GAR OR ' +
    'X.ESCOMPARTIDO_ALM=''S'')))) ' +
    'ORDER BY T.CODIGO_ALM_ALM LIMIT 1');
  try
    Result.ParamByName('ORDEN').AsLargeInt := ASolicitud.Orden;
    Result.ParamByName('LINEA').AsLargeInt := ASolicitud.Linea;
    Result.ParamByName('ALMACEN').AsString := ASolicitud.Almacen;
    Result.Open;
    if Result.IsEmpty then
      raise EArgumentException.Create(SCircuitoAlmacenDocumento);
    if (ASolicitud.Tipo <> 'PR') and
       ((Result.FieldByName('ESCOBRADO_GAR').AsString = 'S') or
        (Trim(Result.FieldByName('NUMERO_COBRO_GAR').AsString) <> '')) and
       not TieneCobroImputado(ASolicitud.Orden) then
      raise EArgumentException.Create(SCircuitoCobroExistente);
  except
    FreeAndNil(Result);
    raise;
  end;
end;

procedure TGeneradorAlbaranOrden.PrepararCabecera(ACabecera: TDataSet;
  AOrden: TUniQuery; const ASolicitud: TDocumentoOrdenNuevo);
var
  sSufijo, sTercero, sEmpresa: string;
begin
  sSufijo := Sufijo(ASolicitud.Tipo);
  sEmpresa := AOrden.FieldByName('EMPRESA').AsString;
  ACabecera.FieldByName('SERIE_' + sSufijo).AsString := ASolicitud.Serie;
  ACabecera.FieldByName('NUMERO_' + sSufijo).AsString := Numerar(sEmpresa,
    ASolicitud.Serie, IfThen(ASolicitud.Tipo = 'PR', 'AB', 'AV'));
  ACabecera.FieldByName('FECHA_' + sSufijo).AsDateTime := ASolicitud.Fecha;
  ACabecera.FieldByName('INSTANTE_MOVIMIENTO_' + sSufijo).AsDateTime :=
    ASolicitud.Fecha + Frac(Now);
  ACabecera.FieldByName('ESTADO_' + sSufijo).AsString := 'ABIERTO';
  ACabecera.FieldByName('CODIGO_EMP_' + sSufijo).AsString := sEmpresa;
  ACabecera.FieldByName('CODIGO_ALM_' + sSufijo).AsString :=
    AOrden.FieldByName('TALLER').AsString;
  ACabecera.FieldByName('CONTADOR_LINEAS_' + sSufijo).AsString := '1';
  ACabecera.FieldByName('OBSERVACIONES_' + sSufijo).AsString :=
    Format('OT %d. %s', [ASolicitud.Orden, ASolicitud.Referencia]);
  CopiarFicha(ACabecera, 'fza_empresas', sEmpresa, 'EMP',
    'EMPRESA_' + sSufijo);
  if ASolicitud.Tipo = 'PR' then
  begin
    ACabecera.FieldByName('CODIGO_PRV_ALBC').AsString := ASolicitud.Proveedor;
    ACabecera.FieldByName('REF_PROVEEDOR_ALBC').AsString :=
      Copy(ASolicitud.Referencia, 1, 50);
    CopiarFicha(ACabecera, 'fza_proveedores', ASolicitud.Proveedor,
      'PRV', 'PRV_ALBC');
    SincronizarRecargoComprasEmpresa(CrearLecturasImpuestos(FConexion),
      ACabecera, 'ALBC');
    AplicarIvaExentoIntracomunitarioProveedor(
      CrearLecturasImpuestos(FConexion), ACabecera,
      'CODIGO_PRV_ALBC', 'ESIVA_EXENTO_INTRACOMUNITARIO_ALBC');
    AplicarPorcentajesIvaCompra(CrearLecturasImpuestos(FConexion),
      ACabecera, 'ALBC');
  end
  else
  begin
    sTercero := AOrden.FieldByName('CODIGO_CLI_GAR').AsString;
    if ASolicitud.Tipo = 'AS' then
      sTercero := AOrden.FieldByName('CODIGO_CLI_PAGADOR_GAR').AsString;
    ACabecera.FieldByName('CODIGO_CLI_ALB').AsString := sTercero;
    CopiarFicha(ACabecera, 'fza_clientes', sTercero, 'CLI', 'CLIENTE_ALB');
    ACabecera.FieldByName('ESIMP_INCL_TARIFA_CLIENTE_ALB').AsString := 'S';
    AplicarPorcentajesIvaVenta(CrearLecturasImpuestos(FConexion),
      ACabecera, 'ALB');
  end;
end;

procedure TGeneradorAlbaranOrden.PrepararLinea(ALinea,
  ACabecera: TDataSet; AOrden: TUniQuery;
  const ASolicitud: TDocumentoOrdenNuevo);
var
  sSufijo, sLinea, sTipoIva: string;
begin
  sSufijo := Sufijo(ASolicitud.Tipo);
  sLinea := sSufijo + 'LIN';
  sTipoIva := UpperCase(Trim(ASolicitud.TipoIva));
  if sTipoIva = '' then
    sTipoIva := 'N';
  if (sTipoIva <> 'N') and (sTipoIva <> 'R') and
     (sTipoIva <> 'S') and (sTipoIva <> 'E') then
    raise EArgumentException.Create(SCircuitoRepartoInvalido);
  // El concepto se documenta libremente, sin identificar una pieza de stock.
  ALinea.FieldByName('SERIE_' + sSufijo + '_' + sLinea).AsString :=
    ACabecera.FieldByName('SERIE_' + sSufijo).AsString;
  ALinea.FieldByName('NUMERO_' + sSufijo + '_' + sLinea).AsString :=
    ACabecera.FieldByName('NUMERO_' + sSufijo).AsString;
  ALinea.FieldByName('LINEA_' + sLinea).AsString :=
    Format('%.4d',[Max(1,ASolicitud.NumeroLinea)]);
  ALinea.FieldByName('CODIGO_ART_' + sLinea).Clear;
  ALinea.FieldByName('DESCRIPCION_ARTICULO_' + sLinea).AsString :=
    Copy(Format('OT %d · %s · %s', [ASolicitud.Orden,
      AOrden.FieldByName('DESCRIPCION_GARLIN').AsString,
      AOrden.FieldByName('CODIGO_UNIDAD_GARLIN').AsString]), 1, 100);
  ALinea.FieldByName('TIPO_CANTIDAD_ARTICULO_' + sLinea).AsString := 'Uds';
  ALinea.FieldByName('CANTIDAD_' + sLinea).AsFloat := ASolicitud.Cantidad;
  ALinea.FieldByName('CODIGO_ALMACEN_' + sLinea).AsString :=
    ACabecera.FieldByName('CODIGO_ALM_' + sSufijo).AsString;
  ALinea.FieldByName('TIPO_IVA_ARTICULO_' + sLinea).AsString := sTipoIva;
  if ASolicitud.Tipo = 'PR' then
  begin
    ALinea.FieldByName('PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN').AsFloat :=
      ASolicitud.Importe / ASolicitud.Cantidad;
    PrepararLineaFiscalCompra(CrearLecturasImpuestos(FConexion),
      ACabecera, ALinea, 'ALBC', 'ALBCLIN', 'TOTAL_ALBCLIN');
  end
  else
  begin
    ALinea.FieldByName('ESIMP_INCL_TARIFA_ALBLIN').AsString := 'S';
    ALinea.FieldByName('PRECIO_VENTA_CIVA_ARTICULO_ALBLIN').AsFloat :=
      ASolicitud.Importe / ASolicitud.Cantidad;
    PrepararLineaFiscalVenta(CrearLecturasImpuestos(FConexion),
      ACabecera, ALinea, 'ALB', 'ALBLIN', 'TOTAL_ALBLIN');
  end;
  ALinea.Post;
end;

procedure TGeneradorAlbaranOrden.GuardarDocumento(ACabecera,
  ALinea: TDataSet; const ASolicitudes: TArray<TDocumentoOrdenNuevo>);
var
  sSufijo: string;
  rImputacion: TImputacionOrden;
  oImputaciones: TRepositorioImputacionesOrden;
  rSolicitud: TDocumentoOrdenNuevo;
begin
  rSolicitud := ASolicitudes[0];
  sSufijo := Sufijo(rSolicitud.Tipo);
  if rSolicitud.Tipo = 'PR' then
    CalcularTotalesDocumentoCompra(CrearLecturasImpuestos(FConexion),
      ACabecera, ALinea, 'ALBC', 'TOTAL_ALBCLIN',
      'TIPO_IVA_ARTICULO_ALBCLIN', 'PORCENTAJE_IVA_ALBCLIN')
  else
    CalcularTotalesDocumentoVenta(CrearLecturasImpuestos(FConexion),
      ACabecera, ALinea, 'ALB', 'TOTAL_ALBLIN',
      'TIPO_IVA_ARTICULO_ALBLIN', 'PORCENTAJE_IVA_ALBLIN');
  ACabecera.Post;
  InsertarRegistro(Tabla(rSolicitud.Tipo), ACabecera);
  oImputaciones := TRepositorioImputacionesOrden.Create(FConexion,FUsuario);
  try
    ALinea.First;
    for rSolicitud in ASolicitudes do
    begin
      InsertarRegistro(Tabla(rSolicitud.Tipo) + '_lineas', ALinea);
      rImputacion := Default(TImputacionOrden);
      rImputacion.Orden := rSolicitud.Orden;
      rImputacion.Linea := rSolicitud.Linea;
      rImputacion.Tipo := rSolicitud.Tipo;
      rImputacion.Importe := rSolicitud.Importe;
      rImputacion.Cantidad := rSolicitud.Cantidad;
      rImputacion.Serie := ACabecera.FieldByName('SERIE_' + sSufijo).AsString;
      rImputacion.Numero := ACabecera.FieldByName('NUMERO_' + sSufijo).AsString;
      rImputacion.LineaDocumento :=
        ALinea.FieldByName('LINEA_' + sSufijo + 'LIN').AsString;
      oImputaciones.Imputar(rImputacion);
      ALinea.Next;
    end;
  finally
    FreeAndNil(oImputaciones);
  end;
end;

function TGeneradorAlbaranOrden.CrearLoteInterno(
  const ASolicitudes: TArray<TDocumentoOrdenNuevo>): TDocumentoOrdenCreado;
var
  oOrden: TUniQuery;
  oCabecera, oLineas: TClientDataSet;
  rSolicitud: TDocumentoOrdenNuevo;
  i: Integer;
begin
  if Length(ASolicitudes)=0 then
    raise EArgumentException.Create(SCircuitoSinPendientes);
  oCabecera := nil;
  oLineas := nil;
  oOrden := DatosOrden(ASolicitudes[0]);
  try
    oCabecera := TablaMemoria(Tabla(ASolicitudes[0].Tipo));
    oLineas := TablaMemoria(Tabla(ASolicitudes[0].Tipo) + '_lineas');
    PrepararCabecera(oCabecera,oOrden,ASolicitudes[0]);
    FreeAndNil(oOrden);
    for i := 0 to High(ASolicitudes) do
    begin
      rSolicitud := ASolicitudes[i];
      rSolicitud.NumeroLinea := i+1;
      oOrden := DatosOrden(rSolicitud);
      if i>0 then
        Inicializar(oLineas);
      PrepararLinea(oLineas,oCabecera,oOrden,rSolicitud);
      FreeAndNil(oOrden);
    end;
    oCabecera.FieldByName('CONTADOR_LINEAS_' +
      Sufijo(ASolicitudes[0].Tipo)).AsString := IntToStr(Length(ASolicitudes));
    GuardarDocumento(oCabecera,oLineas,ASolicitudes);
    Result.Serie := ASolicitudes[0].Serie;
    Result.Numero := oCabecera.FieldByName(
      'NUMERO_' + Sufijo(ASolicitudes[0].Tipo)).AsString;
  finally
    FreeAndNil(oOrden);
    FreeAndNil(oLineas);
    FreeAndNil(oCabecera);
  end;
end;

function TGeneradorAlbaranOrden.CrearInterno(
  const ASolicitud: TDocumentoOrdenNuevo): TDocumentoOrdenCreado;
begin
  Result := CrearLoteInterno([ASolicitud]);
end;

function TGeneradorAlbaranOrden.PrepararPendientes(
  const APlantilla: TDocumentoOrdenNuevo): TArray<TDocumentoOrdenNuevo>;
var
  oCobertura: TRepositorioCoberturaOrden;
  oImputaciones: TRepositorioImputacionesOrden;
  rConcepto: TConceptoOrden;
  rSolicitud: TDocumentoOrdenNuevo;
begin
  Result := nil;
  if (APlantilla.Tipo<>'CL') and (APlantilla.Tipo<>'AS') then
    raise EArgumentException.Create(SCircuitoRepartoInvalido);
  oCobertura := TRepositorioCoberturaOrden.Create(FConexion,FUsuario);
  oImputaciones := TRepositorioImputacionesOrden.Create(FConexion,FUsuario);
  try
    for rConcepto in oCobertura.Conceptos(APlantilla.Orden) do
    begin
      rSolicitud := APlantilla;
      rSolicitud.Linea := rConcepto.Linea;
      rSolicitud.Cantidad := 1;
      rSolicitud.Importe := oImputaciones.Pendiente(APlantilla.Orden,
        rConcepto.Linea,APlantilla.Tipo);
      if rSolicitud.Importe>0 then
      begin
        SetLength(Result,Length(Result)+1);
        Result[High(Result)] := rSolicitud;
      end;
    end;
  finally
    FreeAndNil(oImputaciones);
    FreeAndNil(oCobertura);
  end;
end;

function TGeneradorAlbaranOrden.CrearPendientes(
  const APlantilla: TDocumentoOrdenNuevo): TDocumentoOrdenCreado;
var
  rCreado: TDocumentoOrdenCreado;
begin
  if (APlantilla.Serie='') or (APlantilla.Fecha<=0) then
    raise EArgumentException.Create(SCircuitoRepartoInvalido);
  Transaccion(
    procedure
    begin
      BloquearOrden(APlantilla.Orden,False);
      rCreado := CrearLoteInterno(PrepararPendientes(APlantilla));
    end);
  Result := rCreado;
end;

function TGeneradorAlbaranOrden.Crear(
  const ASolicitud: TDocumentoOrdenNuevo): TDocumentoOrdenCreado;
var
  rCreado: TDocumentoOrdenCreado;
begin
  if ((ASolicitud.Tipo <> 'CL') and (ASolicitud.Tipo <> 'AS') and
      (ASolicitud.Tipo <> 'PR')) or
     (ASolicitud.Importe <= 0) or (ASolicitud.Cantidad <= 0) or
     (Trim(ASolicitud.Serie) = '') or (ASolicitud.Fecha <= 0) then
    raise EArgumentException.Create(SCircuitoRepartoInvalido);
  Transaccion(
    procedure
    begin
      BloquearOrden(ASolicitud.Orden, False);
      rCreado := CrearInterno(ASolicitud);
    end);
  Result := rCreado;
end;

end.
