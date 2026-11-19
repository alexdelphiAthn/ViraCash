{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataProveedores                                            }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de proveedores.                                               }
{    Mantenimiento de fza_proveedores y consulta de artículos y líneas de      }
{    facturas asociadas.                                                       }
{******************************************************************************}
unit UniDataProveedores;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess,
  Uni, inLibUser, UniDataConn;

type
  TDocumentoCompraProveedor = (dcpPedido, dcpAlbaran, dcpFactura, dcpEfecto);

  TdmProveedores = class(TdmBase)
    unqryArticulos: TUniQuery;
    dsArticulos: TDataSource;
    unqryLinFacturasArticulos: TUniQuery;
    dsLinFacturasArticulos: TDataSource;
    // Pestaña Compras: lookup de sistemas de tallas (conjuntos TAL) y
    // biblioteca de kits del proveedor (cantidades por talla) que las
    // Sesiones de Compra aplican sobre la linea con foco.
    unqryConjuntosTallas: TUniQuery;
    dsConjuntosTallas: TDataSource;
    unqryKits: TUniQuery;
    dsKits: TDataSource;
    unqryKitsDet: TUniQuery;
    dsKitsDet: TDataSource;
    // Pestaña Pagos: lookups de forma de pago y de cuentas bancarias de
    // empresa (defectos de pago por proveedor).
    unqryFormaPago: TUniQuery;
    dsFormasPago: TDataSource;
    unqryEmpresasBancos: TUniQuery;
    dsEmpresasBancos: TDataSource;
    // Combo de pais del domicilio fiscal (vi_paises). Se abre en
    // AbrirDetalles, igual que en Clientes: es una tabla pequena y el
    // combo la necesita desde el primer momento.
    unqryPaises: TUniQuery;
    dsPaises: TDataSource;
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryKitsBeforeInsert(DataSet: TDataSet);
    procedure unqryKitsAfterInsert(DataSet: TDataSet);
    procedure unqryKitsBeforePost(DataSet: TDataSet);
    procedure unqryKitsBeforeDelete(DataSet: TDataSet);
    procedure unqryKitsDetBeforeInsert(DataSet: TDataSet);
    procedure unqryKitsDetAfterInsert(DataSet: TDataSet);
    procedure unqryKitsDetBeforePost(DataSet: TDataSet);
  private
    FDocumentos: array[TDocumentoCompraProveedor] of TDataSource;
    FLineasDocumento: array[TDocumentoCompraProveedor] of TDataSource;
    function ObtenerDocumentos(ATipo: TDocumentoCompraProveedor): TDataSource;
    function ObtenerLineasDocumento(
      ATipo: TDocumentoCompraProveedor): TDataSource;
    procedure ValidarDatosObligatorios;
    function CrearConsultaDocumento: TDataSource;
    procedure PrepararConsultasDocumento(ATipo: TDocumentoCompraProveedor;
      AFacturasOrdinarias, AComprasDirectas: Boolean);
  public
    // Enlaza los detalles con el dsTablaG de SU ventana. Antes el DFM los
    // colgaba de "frmMtoProveedores.dsTablaG": con dos ventanas de
    // Proveedores abiertas, los kits de la segunda seguian a la primera.
    procedure AsignarMaestroCabecera(ADataSource: TDataSource); override;
    procedure GetCodigoAutoProveedor;
    procedure ValidarIbanProveedor;
    procedure ActualizarIvaExentoIntracomunitarioPorPais(
      const APais: string);
    // Override: ya no abre nada en el flujo inicial. Las dos queries
    // detail (Articulos, LinFacturasArticulos) son lazy por sub-pestaña.
    procedure AbrirDetalles; override;
    procedure AsegurarArticulosAbierta;
    procedure AsegurarVentasAbierta;
    procedure AsegurarComprasAbierta;
    // Abre los lookups de la pestaña Pagos (forma de pago y bancos de empresa).
    procedure AsegurarPagosAbierta;
    procedure AbrirDocumentos(ATipo: TDocumentoCompraProveedor;
      AFacturasOrdinarias, AComprasDirectas: Boolean);
    property Documentos[ATipo: TDocumentoCompraProveedor]: TDataSource
      read ObtenerDocumentos;
    property LineasDocumento[ATipo: TDocumentoCompraProveedor]: TDataSource
      read ObtenerLineasDocumento;
    // Genera una fila de detalle (cantidad 0) por cada talla del sistema
    // del kit seleccionado. INSERT IGNORE: no pisa cantidades ya tecleadas.
    procedure GenerarTallasKitActual;
  end;

//var
//  dmmProveedores: TdmProveedores;

implementation

uses
  inLibDocumentoFiscal, inLibErroresBBDD, inLibIBAN,
  UniDataValoresAutomaticosRepositorio, System.Diagnostics,
  UniDataAperturaConsultas, inLibFiltroUsuario, UniDataComprasDirectas,
  inLibMsgCompras;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

const
  fdescripcionblanco = 'ESDESCRIPCION_BLANCO_PRV';

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmProveedores.DataModuleCreate(Sender: TObject);
var
  Tipo: TDocumentoCompraProveedor;
begin
  inherited;
  // Solo Connection. Los .Open se han movido a AbrirDetalles.
  unqryArticulos.Connection := ConexionPrincipal;
  unqryLinFacturasArticulos.Connection := ConexionPrincipal;
  unqryConjuntosTallas.Connection := ConexionPrincipal;
  unqryKits.Connection := ConexionPrincipal;
  unqryKitsDet.Connection := ConexionPrincipal;
  // Lookups de la pestaña Pagos: solo Connection; se abren al activar la
  // pestaña (AsegurarPagosAbierta), igual que el resto de detalles lazy.
  unqryFormaPago.Connection := ConexionPrincipal;
  unqryEmpresasBancos.Connection := ConexionPrincipal;
  unqryPaises.Connection := ConexionPrincipal;
  for Tipo := Low(Tipo) to High(Tipo) do
  begin
    FDocumentos[Tipo] := CrearConsultaDocumento;
    FLineasDocumento[Tipo] := CrearConsultaDocumento;
  end;
end;

procedure TdmProveedores.AsignarMaestroCabecera(
  ADataSource: TDataSource);
var
  Tipo: TDocumentoCompraProveedor;
begin
  inherited;
  unqryArticulos.MasterSource := ADataSource;
  unqryLinFacturasArticulos.MasterSource := ADataSource;
  unqryKits.MasterSource := ADataSource;
  for Tipo := Low(Tipo) to High(Tipo) do
  begin
    TUniQuery(FDocumentos[Tipo].DataSet).MasterSource := ADataSource;
    TUniQuery(FLineasDocumento[Tipo].DataSet).MasterSource := FDocumentos[Tipo];
  end;
end;

function TdmProveedores.CrearConsultaDocumento: TDataSource;
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(Self);
  Consulta.Connection := ConexionPrincipal;
  Consulta.ReadOnly := True;
  Result := TDataSource.Create(Self);
  Result.AutoEdit := False;
  Result.DataSet := Consulta;
end;

function TdmProveedores.ObtenerDocumentos(
  ATipo: TDocumentoCompraProveedor): TDataSource;
begin
  Result := FDocumentos[ATipo];
end;

function TdmProveedores.ObtenerLineasDocumento(
  ATipo: TDocumentoCompraProveedor): TDataSource;
begin
  Result := FLineasDocumento[ATipo];
end;

procedure TdmProveedores.PrepararConsultasDocumento(
  ATipo: TDocumentoCompraProveedor;
  AFacturasOrdinarias, AComprasDirectas: Boolean);
const
  Tabla: array[dcpPedido..dcpFactura] of string =
    ('fza_pedidos_compra', 'fza_albaranes_compra', 'fza_facturas_compra');
  Sufijo: array[dcpPedido..dcpFactura] of string = ('PEDC', 'ALBC', 'FACC');
var
  Cabecera, Lineas: TUniQuery;
  S, L, Modalidad, Filtro: string;
begin
  Cabecera := TUniQuery(FDocumentos[ATipo].DataSet);
  Lineas := TUniQuery(FLineasDocumento[ATipo].DataSet);
  Cabecera.MasterFields := 'CODIGO_PRV_PRV';
  Lineas.MasterFields := 'SERIE;NUMERO';
  if ATipo = dcpEfecto then
  begin
    Cabecera.DetailFields := 'CODIGO_PRV_EFEC';
    Cabecera.SQL.Text :=
      'SELECT SERIE_FACC_EFEC AS SERIE, NUMERO_FACC_EFEC AS NUMERO, ' +
      'NUMERO_EFEC AS EFECTO, FECHA_VENCIMIENTO_EFEC AS FECHA, ' +
      'ESTADO_EFEC AS ESTADO, IMPORTE_EFEC AS IMPORTE, ' +
      'IMPORTE_PAGADO_EFEC AS PAGADO, IMPORTE_PENDIENTE_EFEC AS PENDIENTE, ' +
      'CODIGO_PRV_EFEC FROM fza_efectos_compra ' +
      'WHERE CODIGO_PRV_EFEC = :CODIGO_PRV_PRV' +
      SqlFiltroEmpAlmCaja(ContextoSesion, ParametrosApp,
        'CODIGO_EMP_EFEC', '', '') +
      ' ORDER BY FECHA DESC, SERIE, NUMERO, EFECTO';
    Lineas.MasterFields := 'SERIE;NUMERO;EFECTO';
    Lineas.DetailFields :=
      'SERIE_FACC_EFECPAG;NUMERO_FACC_EFECPAG;NUMERO_EFEC_EFECPAG';
    Lineas.SQL.Text :=
      'SELECT NUMERO_PAGO_EFECPAG AS LINEA, FECHA_EFECPAG AS FECHA, ' +
      'IMPORTE_EFECPAG AS IMPORTE, TIPO_EFECPAG AS TIPO_PAGO, ' +
      'REFERENCIA_EFECPAG AS REFERENCIA, ' +
      'SERIE_FACC_EFECPAG, NUMERO_FACC_EFECPAG, NUMERO_EFEC_EFECPAG ' +
      'FROM fza_efectos_compra_pagos WHERE SERIE_FACC_EFECPAG = :SERIE ' +
      'AND NUMERO_FACC_EFECPAG = :NUMERO AND NUMERO_EFEC_EFECPAG = :EFECTO ' +
      'ORDER BY LINEA';
  end
  else
  begin
    S := Sufijo[ATipo];
    L := S + 'LIN';
    Modalidad := '';
    Filtro := SqlFiltroDocumento(ContextoSesion, ParametrosApp, S);
    if ATipo = dcpFactura then
    begin
      Modalidad := 'MODALIDAD_FACC AS MODALIDAD, ';
      if not (AFacturasOrdinarias and AComprasDirectas) then
        Filtro := Filtro + FiltroModalidadListaCompras(AComprasDirectas);
    end;
    Cabecera.DetailFields := 'CODIGO_PRV_' + S;
    Cabecera.SQL.Text :=
      'SELECT SERIE_' + S + ' AS SERIE, NUMERO_' + S + ' AS NUMERO, ' +
      'FECHA_' + S + ' AS FECHA, ESTADO_' + S + ' AS ESTADO, ' +
      'REF_PROVEEDOR_' + S + ' AS REFERENCIA, ' +
      'TOTAL_LIQUIDO_' + S + ' AS IMPORTE, ' + Modalidad +
      'CODIGO_PRV_' + S + ' FROM ' + Tabla[ATipo] +
      ' WHERE CODIGO_PRV_' + S + ' = :CODIGO_PRV_PRV' + Filtro +
      ' ORDER BY FECHA DESC, SERIE, NUMERO DESC';
    Lineas.DetailFields := 'SERIE_' + S + '_' + L + ';NUMERO_' + S + '_' + L;
    Lineas.SQL.Text :=
      'SELECT LINEA_' + L + ' AS LINEA, ' +
      'CODIGO_ART_' + L + ' AS CODIGO_ART_ART, ' +
      'CODIGO_UNIDAD_' + L + ' AS CODIGO_UNIDAD_SKU, ' +
      'DESCRIPCION_ARTICULO_' + L + ' AS DESCRIPCION, ' +
      'CANTIDAD_' + L + ' AS CANTIDAD, PORCENTAJE_IVA_' + L + ' AS IVA, ' +
      'PRECIO_COMPRA_SIVA_ARTICULO_' + L + ' AS PRECIO, ' +
      'TOTAL_' + L + ' AS IMPORTE, ' +
      'SERIE_' + S + '_' + L + ', NUMERO_' + S + '_' + L +
      ' FROM ' + Tabla[ATipo] + '_lineas' +
      ' WHERE SERIE_' + S + '_' + L + ' = :SERIE' +
      ' AND NUMERO_' + S + '_' + L + ' = :NUMERO ORDER BY LINEA';
  end;
end;

procedure TdmProveedores.AbrirDocumentos(ATipo: TDocumentoCompraProveedor;
  AFacturasOrdinarias, AComprasDirectas: Boolean);
var
  Cabecera, Lineas: TUniQuery;
begin
  Cabecera := TUniQuery(FDocumentos[ATipo].DataSet);
  Lineas := TUniQuery(FLineasDocumento[ATipo].DataSet);
  if Cabecera.SQL.Count = 0 then
    PrepararConsultasDocumento(ATipo, AFacturasOrdinarias, AComprasDirectas);
  if not Cabecera.Active then
    Cabecera.Open;
  if not Lineas.Active then
    Lineas.Open;
end;

procedure TdmProveedores.AbrirDetalles;
const
  TAG = 'Proveedores.AbrirDetalles';
var sw: TStopwatch;
begin
  inherited;
  sw := TStopwatch.StartNew;
  // Articulos/LinFacturasArticulos/Kits/Pagos son lazy. Paises es un
  // lookup pequeno que el combo del domicilio fiscal necesita ya abierto.
  AbrirConsultaConTiempo(
    unqryPaises, TAG, 'unqryPaises', RegistroLog);
  RegistroLog.RegistrarRendimiento(TAG, 'TOTAL', sw.ElapsedMilliseconds);
end;

procedure TdmProveedores.AsegurarArticulosAbierta;
var swQ: TStopwatch;
begin
  if not unqryArticulos.Active then
  begin
  swQ := TStopwatch.StartNew;
  try
    unqryArticulos.Open;
    RegistroLog.RegistrarRendimiento('Proveedores.Lazy', 'unqryArticulos OK',
      swQ.ElapsedMilliseconds);
  except
    on E: Exception do
    begin
      RegistroLog.RegistrarRendimiento('Proveedores.Lazy',
        'unqryArticulos ERROR=' + E.Message, swQ.ElapsedMilliseconds);
      raise;
    end;
  end;
  end;
end;

procedure TdmProveedores.AsegurarVentasAbierta;
var swQ: TStopwatch;
begin
  if not unqryLinFacturasArticulos.Active then
  begin
  swQ := TStopwatch.StartNew;
  try
    unqryLinFacturasArticulos.Open;
    RegistroLog.RegistrarRendimiento(
      'Proveedores.Lazy', 'unqryLinFacturasArticulos OK',
      swQ.ElapsedMilliseconds);
  except
    on E: Exception do
    begin
      RegistroLog.RegistrarRendimiento('Proveedores.Lazy',
        'unqryLinFacturasArticulos ERROR=' + E.Message,
        swQ.ElapsedMilliseconds);
      raise;
    end;
  end;
  end;
end;

procedure TdmProveedores.AsegurarComprasAbierta;
var swQ: TStopwatch;
begin
  if not unqryKits.Active then
  begin
  swQ := TStopwatch.StartNew;
  try
    unqryConjuntosTallas.Open;
    unqryKits.Open;
    unqryKitsDet.Open;
    RegistroLog.RegistrarRendimiento('Proveedores.Lazy', 'unqryKits OK',
      swQ.ElapsedMilliseconds);
  except
    on E: Exception do
    begin
      RegistroLog.RegistrarRendimiento('Proveedores.Lazy',
        'unqryKits ERROR=' + E.Message, swQ.ElapsedMilliseconds);
      raise;
    end;
  end;
  end;
end;

procedure TdmProveedores.AsegurarPagosAbierta;
var swQ: TStopwatch;
begin
  if not (unqryFormaPago.Active and unqryEmpresasBancos.Active) then
  begin
  swQ := TStopwatch.StartNew;
  try
    if not unqryFormaPago.Active then
      unqryFormaPago.Open;
    if not unqryEmpresasBancos.Active then
      unqryEmpresasBancos.Open;
    RegistroLog.RegistrarRendimiento('Proveedores.Lazy', 'unqryPagos OK',
      swQ.ElapsedMilliseconds);
  except
    on E: Exception do
    begin
      RegistroLog.RegistrarRendimiento('Proveedores.Lazy',
        'unqryPagos ERROR=' + E.Message, swQ.ElapsedMilliseconds);
      raise;
    end;
  end;
  end;
end;

// ===========================================================================
//   Kits de cantidades por talla (fza_proveedores_kits / _det)
// ===========================================================================

procedure TdmProveedores.unqryKitsBeforeInsert(DataSet: TDataSet);
begin
  inherited;
  if unqryTablaG.IsEmpty then
    raise EValidacionBBDD.Create(SErrorProveedorKitsNoSeleccionado);
  if unqryTablaG.State = dsInsert then
    raise EValidacionBBDD.Create(SErrorProveedorKitsSinGrabar);
end;

procedure TdmProveedores.unqryKitsAfterInsert(DataSet: TDataSet);
begin
  inherited;
  unqryKits.FieldByName('CODIGO_PRV_PRVKIT').AsString :=
    unqryTablaG.FieldByName('CODIGO_PRV_PRV').AsString;
  unqryKits.FieldByName('ORDEN_PRVKIT').AsInteger := 0;
  unqryKits.FieldByName('USUARIO_ALTA').AsString :=
    IdentidadSesion.Usuario;
  unqryKits.FieldByName('INSTANTE_ALTA').AsDateTime := Now;
end;

// Campo vacío: aviso con el cursor en su control o celda; si se graba desde
// el botón Grabar, la pantalla también le da el foco (FZ-ISSUE-623).
procedure ExigirCampoObligatorio(ACampo: TField; const AMensaje: string);
begin
  if Trim(ACampo.AsString) = '' then
  begin
    ACampo.FocusControl;
    raise ECampoObligatorioBBDD.Create(ACampo.FieldName, AMensaje);
  end;
end;

procedure TdmProveedores.unqryKitsBeforePost(DataSet: TDataSet);
begin
  inherited;
  ExigirCampoObligatorio(unqryKits.FieldByName('CODIGO_PRVKIT'),
    SErrorCodigoKitProveedorObligatorio);
  ExigirCampoObligatorio(unqryKits.FieldByName('NOMBRE_PRVKIT'),
    SErrorNombreKitProveedorObligatorio);
  unqryKits.FieldByName('USUARIO_MODIF').AsString    := IdentidadSesion.Usuario;
  unqryKits.FieldByName('INSTANTE_MODIF').AsDateTime := Now;
end;

procedure TdmProveedores.unqryKitsBeforeDelete(DataSet: TDataSet);
var
  q : TUniQuery;
begin
  inherited;
  // Cascade en aplicación (no hay FK en BBDD): borrar el detalle del kit.
  q := TUniQuery.Create(nil);
  try
    q.Connection := ConexionPrincipal;
    q.SQL.Text :=
      'DELETE FROM fza_proveedores_kits_det ' +
      ' WHERE CODIGO_PRV_PRVKITD = :prv ' +
      '   AND CODIGO_PRVKIT_PRVKITD = :kit';
    q.ParamByName('prv').AsString :=
      unqryKits.FieldByName('CODIGO_PRV_PRVKIT').AsString;
    q.ParamByName('kit').AsString :=
      unqryKits.FieldByName('CODIGO_PRVKIT').AsString;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

procedure TdmProveedores.unqryKitsDetBeforeInsert(DataSet: TDataSet);
begin
  inherited;
  if unqryKits.IsEmpty then
    raise EValidacionBBDD.Create(SErrorKitProveedorNoSeleccionadoParaTallas);
  if unqryKits.State in [dsInsert, dsEdit] then
    unqryKits.Post;
end;

procedure TdmProveedores.unqryKitsDetAfterInsert(DataSet: TDataSet);
var
  q      : TUniQuery;
  iOrden : Integer;
begin
  inherited;
  // Orden siguiente con pasos de 10 (huecos para intercalar).
  q := TUniQuery.Create(nil);
  try
    q.Connection := ConexionPrincipal;
    q.SQL.Text :=
      'SELECT COALESCE(MAX(ORDEN_PRVKITD), 0) + 10 AS NEXT_ORDEN ' +
      '  FROM fza_proveedores_kits_det ' +
      ' WHERE CODIGO_PRV_PRVKITD = :prv ' +
      '   AND CODIGO_PRVKIT_PRVKITD = :kit';
    q.ParamByName('prv').AsString :=
      unqryKits.FieldByName('CODIGO_PRV_PRVKIT').AsString;
    q.ParamByName('kit').AsString :=
      unqryKits.FieldByName('CODIGO_PRVKIT').AsString;
    q.Open;
    iOrden := q.FieldByName('NEXT_ORDEN').AsInteger;
  finally
    FreeAndNil(q);
  end;
  unqryKitsDet.FieldByName('CODIGO_PRV_PRVKITD').AsString :=
    unqryKits.FieldByName('CODIGO_PRV_PRVKIT').AsString;
  unqryKitsDet.FieldByName('CODIGO_PRVKIT_PRVKITD').AsString :=
    unqryKits.FieldByName('CODIGO_PRVKIT').AsString;
  unqryKitsDet.FieldByName('CANTIDAD_PRVKITD').AsFloat := 0;
  unqryKitsDet.FieldByName('ORDEN_PRVKITD').AsInteger := iOrden;
  unqryKitsDet.FieldByName('USUARIO_ALTA').AsString :=
    IdentidadSesion.Usuario;
  unqryKitsDet.FieldByName('INSTANTE_ALTA').AsDateTime := Now;
end;

procedure TdmProveedores.unqryKitsDetBeforePost(DataSet: TDataSet);
begin
  inherited;
  ExigirCampoObligatorio(unqryKitsDet.FieldByName('VALOR_DESTINO_PRVKITD'),
    SErrorTallaDestinoKitProveedorObligatoria);
  unqryKitsDet.FieldByName('USUARIO_MODIF').AsString := IdentidadSesion.Usuario;
  unqryKitsDet.FieldByName('INSTANTE_MODIF').AsDateTime := Now;
end;

procedure TdmProveedores.GenerarTallasKitActual;
var
  q   : TUniQuery;
  iAc : Integer;
begin
  if unqryKits.IsEmpty then
    raise EValidacionBBDD.Create(SErrorKitProveedorNoSeleccionado);
  if unqryKits.State in [dsInsert, dsEdit] then
    unqryKits.Post;
  iAc := unqryKits.FieldByName('ID_AC_TALLAS_PRVKIT').AsInteger;
  if iAc <= 0 then
    raise EValidacionBBDD.Create(SErrorSistemaTallasKitProveedorObligatorio);
  q := TUniQuery.Create(nil);
  try
    q.Connection := ConexionPrincipal;
    q.SQL.Text :=
      'INSERT IGNORE INTO fza_proveedores_kits_det ' +
      '  (CODIGO_PRV_PRVKITD, CODIGO_PRVKIT_PRVKITD, VALOR_DESTINO_PRVKITD, ' +
      '   CANTIDAD_PRVKITD, ORDEN_PRVKITD, INSTANTE_ALTA, USUARIO_ALTA, ' +
      '   INSTANTE_MODIF, USUARIO_MODIF) ' +
      'SELECT :prv, :kit, AV.AV, 0, ACD.ORDEN_ACD, NOW(), :usu, NOW(), :usu ' +
      '  FROM fza_atributos_conjuntos_det ACD ' +
      '  JOIN fza_atributos_valores AV ON AV.ID_AV = ACD.ID_AV_ACD ' +
      ' WHERE ACD.ID_AC_ACD = :ac';
    q.ParamByName('prv').AsString :=
      unqryKits.FieldByName('CODIGO_PRV_PRVKIT').AsString;
    q.ParamByName('kit').AsString :=
      unqryKits.FieldByName('CODIGO_PRVKIT').AsString;
    q.ParamByName('usu').AsString := IdentidadSesion.Usuario;
    q.ParamByName('ac').AsInteger := iAc;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
  unqryKitsDet.Refresh;
end;

procedure TdmProveedores.GetCodigoAutoProveedor;
var
  sContador: string;
begin
  if unqryTablaG.FindField('CODIGO_PRV_PRV').AsString = '0' then
  begin
    sContador := ObtenerSiguienteContador(
      ConexionPrincipal,
      'PV',
      IdentidadSesion.Usuario);
    if Trim(sContador) = '' then
      raise Exception.Create(SErrorCodigoAutomaticoProveedor);
    unqryTablaG.FindField('CODIGO_PRV_PRV').AsString := sContador;
  end;
  if unqryTablaG.FindField('ORDEN_PRV').AsString = '0' then
  begin
    sContador := ObtenerSiguienteContador(
      ConexionPrincipal,
      'PO',
      IdentidadSesion.Usuario);
    if Trim(sContador) = '' then
      raise Exception.Create(SErrorOrdenAutomaticoProveedor);
    unqryTablaG.FindField('ORDEN_PRV').AsString := sContador;
  end;
end;

function PaisIntracomunitarioExento(AConn: TUniConnection;
  const APais: string): Boolean;
var
  q: TUniQuery;
  sPais: string;
begin
  Result := False;
  sPais := UpperCase(Trim(APais));
  if (AConn <> nil) and (sPais <> '') and
     (not PaisEsEspana('', sPais)) then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := AConn;
      q.SQL.Text :=
        'SELECT CODIGO_PAI_PAI, IFNULL(ESMIEMBRO_UE_PAI, ''N'') AS UE ' +
        '  FROM fza_paises ' +
        ' WHERE UPPER(TRIM(CODIGO_PAI_PAI)) = :pais ' +
        '    OR UPPER(TRIM(COD_ALPHA2_PAI)) = :pais ' +
        '    OR UPPER(TRIM(COD_ALPHA3_PAI)) = :pais ' +
        '    OR UPPER(TRIM(NOMBRE_SPA_PAI)) = :pais ' +
        '    OR UPPER(TRIM(NOMBRE_ENG_PAI)) = :pais ' +
        ' LIMIT 1';
      q.ParamByName('pais').AsString := sPais;
      q.Open;
      Result := (not q.Eof) and
        SameText(Trim(q.FieldByName('UE').AsString), 'S') and
        (not PaisEsEspana(q.FieldByName('CODIGO_PAI_PAI').AsString, APais));
    finally
      FreeAndNil(q);
    end;
  end;
end;

procedure TdmProveedores.ActualizarIvaExentoIntracomunitarioPorPais(
  const APais: string);
var
  fExento: TField;
  sExento: string;
begin
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) then
  begin
    fExento := unqryTablaG.FindField('ESIVA_EXENTO_INTRACOMUNITARIO_PRV');
    if fExento <> nil then
    begin
      sExento := 'N';
      if PaisIntracomunitarioExento(ConexionPrincipal, APais) then
        sExento := 'S';
      if fExento.IsNull or (fExento.AsString <> sExento) then
      begin
        if not (unqryTablaG.State in dsEditModes) then
          unqryTablaG.Edit;
        fExento.AsString := sExento;
      end;
    end;
  end;
end;

procedure TdmProveedores.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  unqryTablaG.FindField('CODIGO_PRV_PRV').AsString := '0';
  unqryTablaG.FindField('ORDEN_PRV').AsString := '0';
  unqryTablaG.FieldByName(fdescripcionblanco).AsString := 'N';
  if unqryTablaG.FindField('ESACTIVO_PRV') <> nil then
    unqryTablaG.FieldByName('ESACTIVO_PRV').AsString := 'S';
  unqryTablaG.FieldByName('ESFACTURACION_DIRECTA_PRV').AsString := 'N';
  if unqryTablaG.FindField('ESVARIOS_TIPOS_IVA_PRV') <> nil then
    unqryTablaG.FieldByName(
      'ESVARIOS_TIPOS_IVA_PRV').AsString := 'N';
  if unqryTablaG.FindField('ESIVA_EXENTO_INTRACOMUNITARIO_PRV') <> nil then
    unqryTablaG.FieldByName(
      'ESIVA_EXENTO_INTRACOMUNITARIO_PRV').AsString := 'N';
end;

// Sin razón social, o sin NIF con facturación directa, el proveedor no
// identifica a nadie: aviso con el foco en el campo, antes de pedir el
// código automático (FZ-ISSUE-741).
procedure TdmProveedores.ValidarDatosObligatorios;
var
  fldDirecta: TField;
begin
  ExigirCampoObligatorio(unqryTablaG.FieldByName('RAZON_SOCIAL_PRV'),
    SErrorRazonSocialProveedorObligatoria);
  fldDirecta := unqryTablaG.FindField('ESFACTURACION_DIRECTA_PRV');
  if (fldDirecta <> nil) and (fldDirecta.AsString = 'S') then
    ExigirCampoObligatorio(unqryTablaG.FieldByName('NIF_PRV'),
      SErrorNifProveedorFacturacionDirecta);
end;

// Se valida al grabar, tanto desde la ficha como desde la rejilla.
// El IBAN es opcional; los espanoles deben superar tambien el CCC.
procedure TdmProveedores.ValidarIbanProveedor;
var
  Campo: TField;
  Iban: string;
  Errores: TStringList;
begin
  Campo := unqryTablaG.FieldByName('IBAN_PRV');
  if Trim(Campo.AsString) <> '' then
  begin
    Iban := TIBAN.FormatearElectronico(Campo.AsString);
    Errores := TStringList.Create;
    try
      if (Copy(Iban, 1, 2) = 'ES') and
         not TIBAN.ValidarCCC(Iban, Errores) then
        raise EValidacionBBDD.Create(Trim(Errores.Text));
      if not TIBAN.ValidarIBAN(Iban, Errores) then
        raise EValidacionBBDD.Create(Trim(Errores.Text));
      Campo.AsString := Iban;
    finally
      Errores.Free;
    end;
  end;
end;

procedure TdmProveedores.unqryTablaGBeforePost(DataSet: TDataSet);
var
  sPais: string;
begin
  inherited;
  ValidarDatosObligatorios;
  ValidarIbanProveedor;
  if unqryTablaG.FindField('PAIS_PRV') <> nil then
  begin
    // Preferimos el codigo exacto del combo (CODIGO_PAI_PRV) sobre el
    // texto libre heredado: mismo criterio de fza_paises, mas fiable.
    sPais := unqryTablaG.FieldByName('PAIS_PRV').AsString;
    if unqryTablaG.FindField('CODIGO_PAI_PRV') <> nil then
    begin
      if Trim(unqryTablaG.FieldByName('CODIGO_PAI_PRV').AsString) <> '' then
        sPais := unqryTablaG.FieldByName('CODIGO_PAI_PRV').AsString;
    end;
    ActualizarIvaExentoIntracomunitarioPorPais(sPais);
  end;
  GetCodigoAutoProveedor;
end;

initialization
  RegistrarDataModule(TdmProveedores);
  ForceReferenceToClass(TdmProveedores);
end.
