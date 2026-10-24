{******************************************************************************}
{                                                                              }
{                         Módulo: UniDataPresupuestos                          }
{                                Versión: 1.0.0                                }
{                              Fecha: 15/09/2026                               }
{                       Autor: Alejandro Laorden Hidalgo                       }
{                                                                              }
{             Presupuestos e impresión de documentos comerciales.              }
{******************************************************************************}
unit UniDataPresupuestos;

interface

uses
  inLibRegistroPantallas, inLibMsgPresupuestos,
  System.SysUtils, System.Classes, 
  Data.DB, MemDS, DBAccess, Uni,
  UniDataGen, inLibUser,
  frxClass, frxDBSet, frCoreClasses,
  inLibPresupuestosIntf, inLibCajaVentanasIntf, inLibLotesLineaDocumento;

type
  TdmPresupuestos = class(TdmBase)
    unqryAlbaranesLineas: TUniQuery;
    dsAlbaranesLineas:    TDataSource;
    unqryEmpDataAlb:      TUniQuery;
    unqryCliDataAlb:      TUniQuery;
    unqryArtDataLinAlb:   TUniQuery;
    unqrySkusAlb:         TUniQuery;
    unqryFormasPago:      TUniQuery;
    dsFormasPago:         TDataSource;
    unqryAlmacenesAlb:    TUniQuery;
    dsAlmacenesAlb:       TDataSource;
    unqryTarifas:         TUniQuery;
    dsTarifas:            TDataSource;
    unstrdprcGetContadorAlbaran: TUniStoredProc;
    fxdsPrintAlb:    TfrxDBDataset;
    fxdstPrintLinAlb:TfrxDBDataset;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryTablaGAfterPost(DataSet: TDataSet);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
    procedure unqryAlbaranesLineasAfterInsert(DataSet: TDataSet);
    procedure unqryAlbaranesLineasBeforePost(DataSet: TDataSet);
    procedure unqryAlbaranesLineasAfterPost(DataSet: TDataSet);
    procedure unqryAlbaranesLineasAfterDelete(DataSet: TDataSet);
  public
    procedure GuardarDocumento;
    // F-LOTEC-016: lote y serie de las líneas (solo con interruptores).
    procedure ConfigurarLotesLineas(const AConfig: TConfiguracionLotesLineas);
    function DocumentoLotes: TDocumentoLineaLote;
    // Botón de la columna Lote: vuelve a elegir el de la línea actual.
    procedure ElegirLoteLinea;
    function Convertir(ADestino: TDestinoPresupuesto):
      TResultadoConversionPresupuesto;
    function ConvertirConOpciones(ADestino: TDestinoPresupuesto;
      const AOpciones: TOpcionesConversionPresupuesto):
      TResultadoConversionPresupuesto;
    // Lineas del presupuesto activo como SKU y cantidad (las tallas
    // del pivote, una por celda) para volcarlas en una venta de caja.
    function LineasVentaCaja: TLineasVentaCajaExterna;
    procedure DesempaquetarAtributosLineas;
    procedure GetCodigoAutoAlbaran;
    procedure CalcularTotalesAlbaran;
    function TotalPrendasAlbaran: Double;
    procedure CopiarEmpresaaAlbaran(DataSet: TDataSet);
    procedure CopiarClienteaAlbaran(DataSet: TDataSet);
    function BuscarEmpresa(const ACodigo: string): Boolean;
    function BuscarAlmacen(const ACodigo: string): Boolean;
    function BuscarCliente(const ACodigo: string): Boolean;
    procedure OpenTables;
    procedure RefrescarAlmacenes(const ACodigoEmpresa: string);
    procedure ActualizarImpuestosTarifaCabecera(
      const ACodigoTarifa: string);
    procedure AbrirDetalles; override;

  private
    FOperacion: TDataSet;
    FCalculandoTotales: Boolean;
    FDesempaquetandoAtributos: Boolean;
    FLotesLineas: TLotesLineasDocumento;
    procedure LineasPresupuestoDataChange(Sender: TObject; Field: TField);
    // Conexion por la que salen la transaccion, los bloqueos y las
    // lecturas de la operacion: la misma que usan los datasets.
    function ConexionEscritura: TUniConnection;
    procedure ValidarEditable(DataSet: TDataSet);
    procedure IniciarEscritura(DataSet: TDataSet);
    procedure ConfirmarEscritura(DataSet: TDataSet);
    procedure CancelarEscritura(DataSet: TDataSet);
    procedure ErrorEscritura(DataSet: TDataSet; E: EDatabaseError;
      var Action: TDataAction);
    procedure ProcesarCabeceraPosteada;
    procedure ProcesarLineasPosteadas;
    procedure AsignarNumeroLineaAlbaran(DataSet: TDataSet);
    procedure NormalizarCamposOpcionalesLinea(DataSet: TDataSet);
    procedure SincronizarAlmacenLinea(DataSet: TDataSet);
    procedure SincronizarAlmacenLineasCabecera;
    procedure ValidarAlmacenCabecera;
    procedure ValidarClienteCabecera;
    procedure ValidarClienteConversion(ADestino: TDestinoPresupuesto);
    procedure ProponerSerieEmpresa(const AEmpresa: string);
  end;

implementation

uses
  inLibLineaSku,
  inLibValoresAutomaticos, UniDataValoresAutomaticosRepositorio,
  System.Diagnostics,
  UniDataAperturaConsultas,
  System.UITypes, inLibArticulosValidadorIntf,
  UniDataArticulosValidadorRepositorio,
  inLibVentasImpuestos, UniDataImpuestosRepositorio,
  inLibContadorLineas,
  UniDataContadorLineasRepositorio, inLibData,
  UniDataAlmacenesEmpresaRepositorio,
  inLibMsgArticulos, inLibMsgFacturas, inLibMsgVentas,
  inLibDocumento, inLibDocumentoIntf,
  UniDataPresupuestosConversion, UniDataPresupuestosSql,
  inLibDocumentosTrabajo, UniDataDocumentosTrabajoCargaOrigenSql,
  UniDataClientesRepositorio, System.Variants, inLibErroresBBDD;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TdmPresupuestos.DataModuleCreate(Sender: TObject);
begin
  inherited;
  ConfigurarConsultasPresupuesto(Self, ConexionPrincipal);
  unqryTablaG.BeforeEdit := ValidarEditable;
  unqryAlbaranesLineas.BeforeEdit := ValidarEditable;
  unqryAlbaranesLineas.BeforeInsert := ValidarEditable;
  unqryAlbaranesLineas.BeforeDelete := IniciarEscritura;
  unqryTablaG.AfterDelete := ConfirmarEscritura;
  unqryTablaG.OnPostError := ErrorEscritura;
  unqryTablaG.OnDeleteError := ErrorEscritura;
  unqryAlbaranesLineas.OnPostError := ErrorEscritura;
  unqryAlbaranesLineas.OnDeleteError := ErrorEscritura;
  // El formulario encadena este manejador (FOldLineasDataChange).
  dsAlbaranesLineas.OnDataChange := LineasPresupuestoDataChange;
  VigilarTotalMaximoLinea(unqryAlbaranesLineas, 'TOTAL_PRELIN');
end;

// FZ-ISSUE-219: el Total de la linea se refresca al aceptar la cantidad
// o el precio, no solo al grabar (como FZ-202 en albaranes).
procedure TdmPresupuestos.LineasPresupuestoDataChange(Sender: TObject;
  Field: TField);
begin
  if (not FDesempaquetandoAtributos) and
     EsCampoImporteLineaVenta(Field, 'PRELIN') then
    RecalcularTotalLineaVenta(unqryAlbaranesLineas, 'PRELIN',
      'TOTAL_PRELIN');
end;

procedure TdmPresupuestos.DataModuleDestroy(Sender: TObject);
begin
  FreeAndNil(FLotesLineas);
  inherited;
end;

procedure TdmPresupuestos.OpenTables;
begin
  AbrirDetalles;
end;

procedure TdmPresupuestos.AbrirDetalles;
const
  TAG = 'Presupuestos.AbrirDetalles';
var
  sw: TStopwatch;
begin
  inherited;
  sw := TStopwatch.StartNew;
  RefrescarAlmacenes(UbicacionSesion.Empresa);
  AbrirConsultaConTiempo(
    unqryAlbaranesLineas, TAG, 'unqryPresupuestosLineas', RegistroLog);
  AbrirConsultaConTiempo(
    unqryFormasPago, TAG, 'unqryFormasPago', RegistroLog);
  AbrirConsultaConTiempo(
    unqryTarifas, TAG, 'unqryTarifas', RegistroLog);
  RegistroLog.RegistrarRendimiento(TAG, 'TOTAL', sw.ElapsedMilliseconds);
end;

procedure TdmPresupuestos.RefrescarAlmacenes(const ACodigoEmpresa: string);
var
  sEmpresa: string;
begin
  sEmpresa := Trim(ACodigoEmpresa);
  if (sEmpresa = '') and unqryTablaG.Active and
     (not unqryTablaG.IsEmpty) then
    sEmpresa := Trim(unqryTablaG.FieldByName('CODIGO_EMP_PRE').AsString);
  if sEmpresa = '' then
    sEmpresa := Trim(UbicacionSesion.Empresa);
  if (not unqryAlmacenesAlb.Active) or
     (not SameText(unqryAlmacenesAlb.ParamByName('EMPRESA').AsString,
                   sEmpresa)) then
  begin
    unqryAlmacenesAlb.Close;
    unqryAlmacenesAlb.ParamByName('EMPRESA').AsString := sEmpresa;
    unqryAlmacenesAlb.Open;
  end;
  if unqryTablaG.Active and
     (unqryTablaG.State in [dsInsert, dsEdit]) then
    AjustarEmpresaAlmacenDataSet(unqryTablaG.Connection, unqryTablaG,
      'CODIGO_EMP_PRE', 'CODIGO_ALM_PRE');
end;

procedure TdmPresupuestos.unqryTablaGAfterInsert(DataSet: TDataSet);
var
  sSerie: string;
  function FieldByName(const ANombre: string): TField;
  begin
    Result := unqryTablaG.FieldByName(ANombre);
  end;
  function FindField(const ANombre: string): TField;
  begin
    Result := unqryTablaG.FindField(ANombre);
  end;
begin
  inherited;
  FieldByName('NUMERO_PRE').AsString := '0';
    sSerie := ObtenerSerieDefecto(
      ConexionEscritura,
      UbicacionSesion.Empresa,
      CrearConfiguracionDocumento(
        tdPresupuesto, sdVenta).TipoContador);
    if sSerie = '' then
      sSerie := 'PR' + Trim(UbicacionSesion.Empresa);
    if FindField('SERIE_PRE') <> nil then
      FieldByName('SERIE_PRE').AsString := sSerie;
    FieldByName('INSTANTE_MOVIMIENTO_PRE').AsDateTime := Now;
    FieldByName('FECHA_PRE').AsDateTime :=
      Trunc(FieldByName('INSTANTE_MOVIMIENTO_PRE').AsDateTime);
    if FindField('ESTADO_PRE') <> nil then
      FieldByName('ESTADO_PRE').AsString := 'ABIERTO';
    if FindField('ESCONSOLIDADO_PRE') <> nil then
      FieldByName('ESCONSOLIDADO_PRE').AsString := 'N';
    if Trim(UbicacionSesion.Empresa) <> '' then
      FieldByName('CODIGO_EMP_PRE').AsString := UbicacionSesion.Empresa
    else
      FieldByName('CODIGO_EMP_PRE').AsString := '0';
    if FindField('CODIGO_ALM_PRE') <> nil then
      FieldByName('CODIGO_ALM_PRE').AsString := UbicacionSesion.Almacen;
    FieldByName('CODIGO_CLI_PRE').AsString := '0';
    FieldByName('TARIFA_ARTICULO_CLIENTE_PRE').Clear;
    FieldByName('ESIMP_INCL_TARIFA_CLIENTE_PRE').Clear;
    if Trim(UbicacionSesion.Empresa) <> '' then
      BuscarEmpresa(UbicacionSesion.Empresa);
  if FindField('CODIGO_ALM_PRE') <> nil then
    FieldByName('CODIGO_ALM_PRE').AsString := UbicacionSesion.Almacen;
  RefrescarAlmacenes(
    DataSet.FieldByName('CODIGO_EMP_PRE').AsString);
end;

procedure TdmPresupuestos.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
  SincronizarInstanteMovimientoDocumento(
    DataSet, 'FECHA_PRE', 'INSTANTE_MOVIMIENTO_PRE');
  ValidarEditable(DataSet);
  ValidarAlmacenCabecera;
  ValidarClienteCabecera;
  if (unqryTablaG.FieldByName('NUMERO_PRE').AsString = '0') or
     (unqryTablaG.FieldByName('NUMERO_PRE').AsString = '') then
    GetCodigoAutoAlbaran;
  AplicarPorcentajesIvaVenta(
    CrearLecturasImpuestos(ConexionEscritura), unqryTablaG, 'PRE');
  CalcularTotalesAlbaran;
  IniciarEscritura(DataSet);
end;

procedure TdmPresupuestos.unqryTablaGAfterPost(DataSet: TDataSet);
begin
  inherited;
  try
    ProcesarCabeceraPosteada;
    ConfirmarEscritura(DataSet);
  except
    CancelarEscritura(DataSet);
    raise;
  end;
end;

procedure TdmPresupuestos.unqryTablaGBeforeDelete(DataSet: TDataSet);
begin
  inherited;
  IniciarEscritura(DataSet);
  try
    EliminarDetallePresupuesto(ConexionEscritura,
      DataSet.FieldByName('SERIE_PRE').AsString,
      DataSet.FieldByName('NUMERO_PRE').AsString);
  except
    CancelarEscritura(DataSet);
    raise;
  end;
end;

procedure InicializarColumnasSkuLinea(ADataSet: TDataSet);
var
  i: Integer;
begin
  if ADataSet.FindField('NUM_ATRIBUTOS_PRELIN') <> nil then
    ADataSet.FieldByName('NUM_ATRIBUTOS_PRELIN').AsInteger := 0;
  if ADataSet.FindField('ID_AC_PIVOT_PRELIN') <> nil then
    ADataSet.FieldByName('ID_AC_PIVOT_PRELIN').AsInteger := 0;
  for i := 1 to 5 do
  begin
    if ADataSet.FindField('ATTR' + IntToStr(i) + '_VALOR_PRELIN') <> nil
    then
      ADataSet.FieldByName(
        'ATTR' + IntToStr(i) + '_VALOR_PRELIN').AsString := '';
    if ADataSet.FindField('ATTR' + IntToStr(i) + '_NOMBRE_PRELIN') <> nil
    then
      ADataSet.FieldByName(
        'ATTR' + IntToStr(i) + '_NOMBRE_PRELIN').AsString := '';
  end;
end;
function LineaAlbaranVacia(ADataSet: TDataSet): Boolean;
  function CampoVacio(const ANombre: string): Boolean;
  var
    Campo: TField;
  begin
    Result := True;
    Campo := ADataSet.FindField(ANombre);
    if Campo <> nil then
      Result := Trim(Campo.AsString) = '';
  end;
begin
  Result := CampoVacio('CODIGO_ART_PRELIN') and
            CampoVacio('CODIGO_UNIDAD_PRELIN');
end;

procedure TdmPresupuestos.unqryAlbaranesLineasAfterInsert(DataSet: TDataSet);
  function FieldByName(const ANombre: string): TField;
  begin
    Result := unqryAlbaranesLineas.FieldByName(ANombre);
  end;
  function FindField(const ANombre: string): TField;
  begin
    Result := unqryAlbaranesLineas.FindField(ANombre);
  end;
begin
  inherited;
  // Sin numero hasta grabar: el BeforePost asigna el definitivo con
  // el contador de lineas. Un 0000 parecia un error (FZ-ISSUE-224).
  FieldByName('LINEA_PRELIN').Clear;
    FieldByName('NUMERO_PRE_PRELIN').AsString :=
                                  unqryTablaG.FieldByName(
                                    'NUMERO_PRE').AsString;
    FieldByName('SERIE_PRE_PRELIN').AsString  :=
                                  unqryTablaG.FieldByName('SERIE_PRE').AsString;
    if (FindField('CODIGO_ALMACEN_PRELIN') <> nil) and
       (unqryTablaG.FindField('CODIGO_ALM_PRE') <> nil) then
      FieldByName('CODIGO_ALMACEN_PRELIN').AsString :=
        unqryTablaG.FieldByName('CODIGO_ALM_PRE').AsString;
    FieldByName('CANTIDAD_PRELIN').AsFloat := 1;
    if FindField('ESFACTURADA_PRELIN') <> nil then
      FieldByName('ESFACTURADA_PRELIN').AsString := 'N';
    if FindField('CODIGO_TAR_PRELIN') <> nil then
      FieldByName('CODIGO_TAR_PRELIN').AsString :=
        unqryTablaG.FieldByName(
          'TARIFA_ARTICULO_CLIENTE_PRE').AsString;
    if FindField('ESIMP_INCL_TARIFA_PRELIN') <> nil then
      FieldByName('ESIMP_INCL_TARIFA_PRELIN').AsString :=
        unqryTablaG.FieldByName(
          'ESIMP_INCL_TARIFA_CLIENTE_PRE').AsString;
    InicializarColumnasSkuLinea(unqryAlbaranesLineas);
    if FindField('USUARIO_ALTA') <> nil then
      FieldByName('USUARIO_ALTA').AsString := IdentidadSesion.Usuario;
    if FindField('INSTANTE_ALTA') <> nil then
      FieldByName('INSTANTE_ALTA').AsDateTime := Now;
    if FindField('USUARIO_MODIF') <> nil then
      FieldByName('USUARIO_MODIF').AsString := IdentidadSesion.Usuario;
  if FindField('INSTANTE_MODIF') <> nil then
    FieldByName('INSTANTE_MODIF').AsDateTime := Now;
end;

procedure TdmPresupuestos.NormalizarCamposOpcionalesLinea(DataSet: TDataSet);
var
  q: TUniQuery;
  sArticulo: string;
  bTrazable: Boolean;
  bVariacion: Boolean;
  iSkus: Integer;
begin
  sArticulo := '';
  bTrazable := False;
  bVariacion := False;
  iSkus := 0;
  if (DataSet <> nil) and DataSet.Active and
     (DataSet.FindField('CODIGO_ART_PRELIN') <> nil) then
    sArticulo := Trim(DataSet.FieldByName('CODIGO_ART_PRELIN').AsString);
  if sArticulo <> '' then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := unqryTablaG.Connection;
      q.SQL.Text :=
        'SELECT a.ESTRAZABLE_ART, a.ESVARIACION_ART, ' +
        '       (SELECT COUNT(*) ' +
        '          FROM fza_articulos_skus sk ' +
        '         WHERE sk.CODIGO_ART_SKU = a.CODIGO_ART_ART ' +
        '           AND COALESCE(sk.ESACTIVO_SKU, ''S'') = ''S'') AS NUM_SKUS '
          +
        '  FROM fza_articulos a ' +
        ' WHERE a.CODIGO_ART_ART = :art';
      q.ParamByName('art').AsString := sArticulo;
      q.Open;
      if not q.IsEmpty then
      begin
        bTrazable := q.FieldByName('ESTRAZABLE_ART').AsString = 'S';
        bVariacion := q.FieldByName('ESVARIACION_ART').AsString = 'S';
        iSkus := q.FieldByName('NUM_SKUS').AsInteger;
      end;
    finally
      FreeAndNil(q);
    end;
  end;
  if not bTrazable then
  begin
    if DataSet.FindField('LOTE_PRELIN') <> nil then
      DataSet.FieldByName('LOTE_PRELIN').Clear;
    if DataSet.FindField('FECHA_CADUCIDAD_PRELIN') <> nil then
      DataSet.FieldByName('FECHA_CADUCIDAD_PRELIN').Clear;
  end;
  if (not bVariacion) and (iSkus <= 1) and
     (DataSet.FindField('DESCRIPCION_VARIACION_PRELIN') <> nil) then
    DataSet.FieldByName('DESCRIPCION_VARIACION_PRELIN').Clear;
  if (iSkus = 0) and
     (DataSet.FindField('CODIGO_UNIDAD_PRELIN') <> nil) then
    DataSet.FieldByName('CODIGO_UNIDAD_PRELIN').Clear;
end;

procedure TdmPresupuestos.SincronizarAlmacenLinea(DataSet: TDataSet);
var
  sAlmacen: string;
begin
  if (DataSet <> nil) and (DataSet.FindField('CODIGO_ALMACEN_PRELIN') <> nil)
     and
     (unqryTablaG.FindField('CODIGO_ALM_PRE') <> nil) then
  begin
    sAlmacen := Trim(unqryTablaG.FieldByName('CODIGO_ALM_PRE').AsString);
    DataSet.FieldByName('CODIGO_ALMACEN_PRELIN').AsString := sAlmacen;
  end;
end;

procedure TdmPresupuestos.ValidarAlmacenCabecera;
begin
  if (unqryTablaG.FindField('CODIGO_ALM_PRE') <> nil) and
     (Trim(unqryTablaG.FieldByName('CODIGO_ALM_PRE').AsString) = '') then
  begin
    NotificarAdvertencia(SAvisoAlmacenSalidaPresupuestoObligatorio);
    Abort;
  end;
end;

// Sin cliente («0» o vacío) se admite: se presupuesta a quien aún no tiene
// ficha. Un código que no existe no (FZ-ISSUE-301). Solo al crearlo o al
// cambiar el cliente.
procedure TdmPresupuestos.ValidarClienteCabecera;
var
  oCampo: TField;
  sCliente: string;
  bValidar: Boolean;
begin
  sCliente := '';
  oCampo := unqryTablaG.FindField('CODIGO_CLI_PRE');
  bValidar := oCampo <> nil;
  if bValidar then
  begin
    sCliente := Trim(oCampo.AsString);
    bValidar := (sCliente <> '') and (sCliente <> '0') and
      ((unqryTablaG.State <> dsEdit) or
       (sCliente <> Trim(VarToStr(oCampo.OldValue))));
  end;
  if bValidar and
     not ExisteClienteCodigo(unqryTablaG.Connection, sCliente) then
  begin
    NotificarAdvertencia(
      Format(SAvisoClientePresupuestoNoExiste, [sCliente]));
    Abort;
  end;
end;

// El albarán exige cliente (FZ-ISSUE-301): la conversión no lo crea sin él.
// Reabrir el destino de un presupuesto ya convertido (Convertir) no pasa
// por aquí.
procedure TdmPresupuestos.ValidarClienteConversion(
  ADestino: TDestinoPresupuesto);
begin
  if (ADestino = dpAlbaran) and
     (not ExisteClienteCodigo(unqryTablaG.Connection,
       unqryTablaG.FieldByName('CODIGO_CLI_PRE').AsString)) then
  begin
    NotificarAdvertencia(SAvisoClientePresupuestoAlbaran);
    Abort;
  end;
end;

procedure TdmPresupuestos.SincronizarAlmacenLineasCabecera;
var
  q: TUniQuery;
  sAlmacen: string;
  sNumero: string;
  sSerie: string;
begin
  if unqryTablaG.FindField('CODIGO_ALM_PRE') <> nil then
  begin
    sAlmacen := Trim(unqryTablaG.FieldByName('CODIGO_ALM_PRE').AsString);
    sNumero := Trim(unqryTablaG.FieldByName('NUMERO_PRE').AsString);
    sSerie := Trim(unqryTablaG.FieldByName('SERIE_PRE').AsString);
    if (sAlmacen <> '') and (sNumero <> '') and (sNumero <> '0') and
       (sSerie <> '') then
    begin
      q := TUniQuery.Create(nil);
      try
        q.Connection := unqryTablaG.Connection;
        q.SQL.Text :=
          'UPDATE fza_presupuestos_lineas ' +
          '   SET CODIGO_ALMACEN_PRELIN = :alm ' +
          ' WHERE NUMERO_PRE_PRELIN = :num ' +
          '   AND SERIE_PRE_PRELIN  = :ser ' +
          '   AND COALESCE(CODIGO_ALMACEN_PRELIN, '''') <> :alm';
        q.ParamByName('alm').AsString := sAlmacen;
        q.ParamByName('num').AsString := sNumero;
        q.ParamByName('ser').AsString := sSerie;
        q.ExecSQL;
      finally
        FreeAndNil(q);
      end;
      if unqryAlbaranesLineas.Active then
      begin
        if unqryAlbaranesLineas.State in dsEditModes then
          SincronizarAlmacenLinea(unqryAlbaranesLineas)
        else
        begin
          unqryAlbaranesLineas.Close;
          unqryAlbaranesLineas.Open;
        end;
      end;
    end;
  end;
end;

procedure TdmPresupuestos.unqryAlbaranesLineasBeforePost(DataSet: TDataSet);
var
  sSku, sArt: string;
  function FieldByName(const ANombre: string): TField;
  begin
    Result := unqryAlbaranesLineas.FieldByName(ANombre);
  end;
  function FindField(const ANombre: string): TField;
  begin
    Result := unqryAlbaranesLineas.FindField(ANombre);
  end;
begin
  inherited;
  if not FDesempaquetandoAtributos then
  begin
  ValidarEditable(DataSet);
  // FZ-ISSUE-422: es una validacion esperada (aviso normal), no un
  // fallo del programa con pila y envio al soporte.
  if LineaAlbaranVacia(DataSet) then
    raise EValidacionBBDD.Create(SErrorLineaPresupuestoSinArticulo);
  AsignarNumeroLineaAlbaran(DataSet);
  SincronizarAlmacenLinea(DataSet);
  NormalizarArticuloSkuEnDataSet(ConexionEscritura,
      unqryAlbaranesLineas, 'CODIGO_ART_PRELIN',
      'CODIGO_UNIDAD_PRELIN');
  ExigirSkuCompletoEnDataSet(ConexionEscritura, unqryAlbaranesLineas,
    'CODIGO_ART_PRELIN', 'CODIGO_UNIDAD_PRELIN', 'ID_AC_PIVOT_PRELIN');
    NormalizarCamposOpcionalesLinea(DataSet);
    // F-LOTEC-016: antes de los totales (una serie deja la línea en 1).
    if Assigned(FLotesLineas) then
      FLotesLineas.AntesDePostLinea(unqryAlbaranesLineas, DocumentoLotes);
    if (FindField('CANTIDAD_PRELIN') <> nil) and
       (FindField('PRECIO_VENTA_SIVA_ARTICULO_PRELIN') <> nil) and
       (FindField('TOTAL_PRELIN') <> nil) then
      PrepararLineaFiscalVenta(CrearLecturasImpuestos(ConexionEscritura),
        unqryTablaG,
        unqryAlbaranesLineas, 'PRE', 'PRELIN', 'TOTAL_PRELIN');
    if (FindField('CODIGO_UNIDAD_PRELIN') <> nil) and
       (FindField('CODIGO_ART_PRELIN') <> nil) then
    begin
      sSku := Trim(FieldByName('CODIGO_UNIDAD_PRELIN').AsString);
      sArt := Trim(FieldByName('CODIGO_ART_PRELIN').AsString);
      if (sSku <> '') and (sArt = '') then
      begin
        unqrySkusAlb.Close;
        unqrySkusAlb.ParamByName('pSKU').AsString := sSku;
        unqrySkusAlb.Open;
        if not unqrySkusAlb.Eof then
          FieldByName('CODIGO_ART_PRELIN').AsString :=
                                  unqrySkusAlb.FieldByName(
                                    'CODIGO_ART_SKU').AsString;
        unqrySkusAlb.Close;
      end;
    end;
    if FindField('USUARIO_MODIF') <> nil then
      FieldByName('USUARIO_MODIF').AsString := IdentidadSesion.Usuario;
    if FindField('INSTANTE_MODIF') <> nil then
      FieldByName('INSTANTE_MODIF').AsDateTime := Now;
  if DataSet.State = dsInsert then
  begin
    if (FindField('USUARIO_ALTA') <> nil) and
       (FieldByName('USUARIO_ALTA').AsString = '') then
      FieldByName('USUARIO_ALTA').AsString := IdentidadSesion.Usuario;
    if (FindField('INSTANTE_ALTA') <> nil) and
       FieldByName('INSTANTE_ALTA').IsNull then
      FieldByName('INSTANTE_ALTA').AsDateTime := Now;
  end;
  end;
  IniciarEscritura(DataSet);
end;

procedure TdmPresupuestos.AsignarNumeroLineaAlbaran(DataSet: TDataSet);
var
  iNuevaLinea: Integer;
  sLinea: string;
  sNumero: string;
  sSerie: string;
begin
  if DataSet.FindField('LINEA_PRELIN') <> nil then
  begin
    sLinea := Trim(DataSet.FieldByName('LINEA_PRELIN').AsString);
    sNumero := Trim(unqryTablaG.FieldByName('NUMERO_PRE').AsString);
    sSerie  := Trim(unqryTablaG.FieldByName('SERIE_PRE').AsString);
    if (sLinea = '') or (StrToIntDef(sLinea, 0) = 0) or
       ((DataSet.State = dsInsert) and
        LineaDocExiste(CrearContadorLineasDocumento(ConexionEscritura),
          LIN_PRESUPUESTOS, sSerie, sNumero,
          sLinea)) then
    begin
      if (sNumero = '') or (sNumero = '0') or (sSerie = '') then
        raise Exception.Create(SErrorCabeceraPresupuestoSinGrabar);
      if DataSet.FindField('NUMERO_PRE_PRELIN') <> nil then
        DataSet.FieldByName('NUMERO_PRE_PRELIN').AsString := sNumero;
      if DataSet.FindField('SERIE_PRE_PRELIN') <> nil then
        DataSet.FieldByName('SERIE_PRE_PRELIN').AsString := sSerie;
      iNuevaLinea := GetSiguienteLineaDocLibre(
        CrearContadorLineasDocumento(ConexionEscritura),
        CONT_PRESUPUESTOS, LIN_PRESUPUESTOS, sSerie, sNumero);
      if iNuevaLinea = 0 then
        raise Exception.Create(Format(SErrorAsignarLineaPresupuesto,
                                      [sSerie, sNumero]));
      DataSet.FieldByName('LINEA_PRELIN').AsString :=
        Format('%.4d', [iNuevaLinea]);
    end;
  end;
end;

procedure TdmPresupuestos.DesempaquetarAtributosLineas;
begin
  if unqryAlbaranesLineas.Active and
     (unqryTablaG.FieldByName('NUMERO_DESTINO_PRE').AsString = '') and
     (not unqryAlbaranesLineas.IsEmpty) and
     (unqryAlbaranesLineas.FindField('ATTR1_VALOR_PRELIN') <> nil) then
  begin
    // Evita recálculos fiscales y movimientos durante los Post descriptivos.
    FDesempaquetandoAtributos := True;
    try
      DesempaquetarAtributosLineasSku(unqryAlbaranesLineas, 'PRELIN');
    finally
      FDesempaquetandoAtributos := False;
    end;
  end;
end;

procedure TdmPresupuestos.unqryAlbaranesLineasAfterPost(DataSet: TDataSet);
begin
  inherited;
  try
    if not FDesempaquetandoAtributos then
      ProcesarLineasPosteadas;
    if Assigned(FLotesLineas) and not FDesempaquetandoAtributos then
      FLotesLineas.DespuesDePostLinea;
    ConfirmarEscritura(DataSet);
  except
    CancelarEscritura(DataSet);
    raise;
  end;
end;

procedure TdmPresupuestos.ConfigurarLotesLineas(
  const AConfig: TConfiguracionLotesLineas);
begin
  FreeAndNil(FLotesLineas);
  if AConfig.Activacion.AlgunModoActivo then
    FLotesLineas := TLotesLineasDocumento.Create(AConfig);
end;

function TdmPresupuestos.DocumentoLotes: TDocumentoLineaLote;
begin
  Result.TipoDocumento := 'PR';
  Result.Serie := Trim(unqryTablaG.FieldByName('SERIE_PRE').AsString);
  Result.Numero := Trim(unqryTablaG.FieldByName('NUMERO_PRE').AsString);
  Result.CodigoAlmacen :=
    Trim(unqryTablaG.FieldByName('CODIGO_ALM_PRE').AsString);
end;

procedure TdmPresupuestos.ElegirLoteLinea;
begin
  if Assigned(FLotesLineas) and unqryAlbaranesLineas.Active and
     not unqryAlbaranesLineas.IsEmpty then
    FLotesLineas.ElegirLote(unqryAlbaranesLineas, DocumentoLotes);
end;

procedure TdmPresupuestos.unqryAlbaranesLineasAfterDelete(DataSet: TDataSet);
begin
  inherited;
  try
    ProcesarLineasPosteadas;
    ConfirmarEscritura(DataSet);
  except
    CancelarEscritura(DataSet);
    raise;
  end;
end;

function TdmPresupuestos.TotalPrendasAlbaran: Double;
begin
  Result := TotalPrendasLineasVenta(unqryAlbaranesLineas,
    'TIPO_IVA_ARTICULO_PRELIN');
end;

procedure TdmPresupuestos.GetCodigoAutoAlbaran;
var
  iNumero: Int64;
  sNumero: string;
begin
  unstrdprcGetContadorAlbaran.Params.Clear;
  unstrdprcGetContadorAlbaran.Params.CreateParam(
    ftString, 'pserie', ptInput);
  unstrdprcGetContadorAlbaran.Params.CreateParam(
    ftString, 'ptipodoc', ptInput);
  unstrdprcGetContadorAlbaran.Params.CreateParam(
    ftString, 'pEMPRESA_CONTADOR', ptInput);
  unstrdprcGetContadorAlbaran.Params.CreateParam(
    ftString, 'pUSUARIOMODIF', ptInput);
  unstrdprcGetContadorAlbaran.Params.CreateParam(
    ftString, 'pcont', ptOutput);
  unstrdprcGetContadorAlbaran.ParamByName('pserie').AsString :=
    unqryTablaG.FieldByName('SERIE_PRE').AsString;
  unstrdprcGetContadorAlbaran.ParamByName('ptipodoc').AsString :=
    CrearConfiguracionDocumento(tdPresupuesto, sdVenta).TipoContador;
  unstrdprcGetContadorAlbaran.ParamByName('pUSUARIOMODIF').AsString :=
    IdentidadSesion.Usuario;
  unstrdprcGetContadorAlbaran.ParamByName(
    'pEMPRESA_CONTADOR').AsString :=
    unqryTablaG.FieldByName('CODIGO_EMP_PRE').AsString;
  EjecutarContadorDocumento(unstrdprcGetContadorAlbaran);
  sNumero := Trim(
    unstrdprcGetContadorAlbaran.ParamByName('pcont').AsString);
  if (sNumero = '') or (not TryStrToInt64(sNumero, iNumero)) or
     (iNumero <= 0) then
    raise Exception.Create(Format(SErrorContadorPresupuesto,
      [unqryTablaG.FieldByName('SERIE_PRE').AsString,
       unqryTablaG.FieldByName('CODIGO_EMP_PRE').AsString]));
  unqryTablaG.FieldByName('NUMERO_PRE').AsString := sNumero;
end;

procedure TdmPresupuestos.CalcularTotalesAlbaran;
begin
  if not FCalculandoTotales then
  begin
    FCalculandoTotales := True;
    try
      CalcularTotalesDocumentoVenta(
        CrearLecturasImpuestos(unqryTablaG.Connection), unqryTablaG,
        unqryAlbaranesLineas, 'PRE', 'TOTAL_PRELIN',
        'TIPO_IVA_ARTICULO_PRELIN', 'PORCENTAJE_IVA_PRELIN');
    finally
      FCalculandoTotales := False;
    end;
  end;
end;

procedure TdmPresupuestos.ProcesarCabeceraPosteada;
begin
  SincronizarAlmacenLineasCabecera;
end;

procedure TdmPresupuestos.ProcesarLineasPosteadas;
begin
  CalcularTotalesAlbaran;
  if unqryTablaG.State in dsEditModes then
    unqryTablaG.Post;
end;

function TdmPresupuestos.BuscarEmpresa(const ACodigo: string): Boolean;
var
  q: TUniQuery;
  sCodigo: string;
begin
  Result := False;
  sCodigo := Trim(ACodigo);
  if (sCodigo <> '') and (sCodigo <> '0') then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := unqryTablaG.Connection;
      q.SQL.Text :=
      'SELECT ' + 'CODIGO_EMP_EMP, CODIGO_PAI_EMP, ' +
      '' + 'CODIGO_POSTAL_EMP, DIRECCION1_EMP, ' +
      '' + 'DIRECCION2_EMP, EMAIL_EMP, ' +
      '' + 'GRUPO_ZONA_IVA_EMP, MOVIL_EMP, ' +
      '' + 'NIF_EMP, NOMBRE_PAI_EMP, ' +
      '' + 'POBLACION_EMP, PROVINCIA_EMP, ' +
      '' + 'RAZON_SOCIAL_EMP, ESRETENCIONES_EMP, ' +
      '' + 'ESREGIMENESPECIALAGRICOLA_EMP ' +
                    '  FROM fza_empresas ' +
                    ' WHERE CODIGO_EMP_EMP = :empresa';
      q.ParamByName('empresa').AsString := sCodigo;
      q.Open;
      if not q.IsEmpty then
      begin
        CopiarEmpresaaAlbaran(q);
        Result := True;
      end;
    finally
      FreeAndNil(q);
    end;
  end;
end;

function TdmPresupuestos.BuscarAlmacen(const ACodigo: string): Boolean;
var
  qAlm: TUniQuery;
  qEmp: TUniQuery;
  sCodigo: string;
  sEmpresa: string;
begin
  Result := False;
  sCodigo := Trim(ACodigo);
  if sCodigo <> '' then
  begin
    qAlm := TUniQuery.Create(nil);
    qEmp := TUniQuery.Create(nil);
    try
      qAlm.Connection := unqryTablaG.Connection;
      qAlm.SQL.Text :=
        'SELECT CODIGO_ALM_ALM, CODIGO_EMP_ALM ' +
        '  FROM fza_almacenes ' +
        ' WHERE CODIGO_ALM_ALM = :alm ' +
        '   AND COALESCE(ESACTIVO_ALM, ''S'') = ''S''';
      qAlm.ParamByName('alm').AsString := sCodigo;
      qAlm.Open;
      if not qAlm.IsEmpty then
      begin
        if not (unqryTablaG.State in [dsEdit, dsInsert]) then
          unqryTablaG.Edit;
        if unqryTablaG.FindField('CODIGO_ALM_PRE') <> nil then
          unqryTablaG.FieldByName('CODIGO_ALM_PRE').AsString := sCodigo;
        sEmpresa := qAlm.FieldByName('CODIGO_EMP_ALM').AsString;
        qEmp.Connection := unqryTablaG.Connection;
        qEmp.SQL.Text :=
      'SELECT ' + 'CODIGO_EMP_EMP, CODIGO_PAI_EMP, ' +
      '' + 'CODIGO_POSTAL_EMP, DIRECCION1_EMP, ' +
      '' + 'DIRECCION2_EMP, EMAIL_EMP, ' +
      '' + 'GRUPO_ZONA_IVA_EMP, MOVIL_EMP, ' +
      '' + 'NIF_EMP, NOMBRE_PAI_EMP, ' +
      '' + 'POBLACION_EMP, PROVINCIA_EMP, ' +
      '' + 'RAZON_SOCIAL_EMP, ESRETENCIONES_EMP, ' +
      '' + 'ESREGIMENESPECIALAGRICOLA_EMP ' +
          '  FROM fza_empresas ' +
          ' WHERE CODIGO_EMP_EMP = :empresa';
        qEmp.ParamByName('empresa').AsString := sEmpresa;
        qEmp.Open;
        if not qEmp.IsEmpty then
          CopiarEmpresaaAlbaran(qEmp);
        if unqryTablaG.FindField('CODIGO_ALM_PRE') <> nil then
          unqryTablaG.FieldByName('CODIGO_ALM_PRE').AsString := sCodigo;
        Result := True;
      end;
    finally
      FreeAndNil(qEmp);
      FreeAndNil(qAlm);
    end;
  end;
end;

procedure TdmPresupuestos.ProponerSerieEmpresa(const AEmpresa: string);
var
  sSerie: string;
  sNumero: string;
begin
  if (unqryTablaG.State in [dsInsert, dsEdit]) then
  begin
    sNumero := Trim(unqryTablaG.FieldByName('NUMERO_PRE').AsString);
    if (sNumero = '') or (sNumero = '0') then
    begin
      sSerie := ObtenerSerieDefecto(
        ConexionEscritura,
        AEmpresa,
        CrearConfiguracionDocumento(
          tdPresupuesto, sdVenta).TipoContador);
      if sSerie = '' then
        sSerie := 'PR' + Trim(AEmpresa);
      unqryTablaG.FieldByName('SERIE_PRE').AsString := sSerie;
    end;
  end;
end;

function TdmPresupuestos.BuscarCliente(const ACodigo: string): Boolean;
var
  q: TUniQuery;
  sCodigo: string;
begin
  Result := False;
  sCodigo := Trim(ACodigo);
  if (sCodigo <> '') and (sCodigo <> '0') then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := unqryTablaG.Connection;
      q.SQL.Text :=
      'SELECT ' + 'CODIGO_CLI_CLI, CODIGO_PAI_CLI, ' +
      '' + 'CODIGO_POSTAL_CLI, DIRECCION1_CLI, ' +
      '' + 'DIRECCION2_CLI, EMAIL_CLI, ' +
      '' + 'ESINTRACOMUNITARIO_CLI, ESIVA_EXENTO_CLI, ' +
      '' + 'ESIVA_RECARGO_CLI, MOVIL_CLI, ' +
      '' + 'NIF_CLI, NOMBRE_PAI_CLI, ' +
      '' + 'POBLACION_CLI, PROVINCIA_CLI, ' +
      '' + 'RAZON_SOCIAL_CLI, TARIFA_ARTICULO_CLI, ' +
      '' + 'ESRETENCIONES_CLI, ESREGIMENESPECIALAGRICOLA_CLI ' +
                    '  FROM fza_clientes ' +
                    ' WHERE CODIGO_CLI_CLI = :cliente';
      q.ParamByName('cliente').AsString := sCodigo;
      q.Open;
      if not q.IsEmpty then
      begin
        CopiarClienteaAlbaran(q);
        Result := True;
      end;
    finally
      FreeAndNil(q);
    end;
  end;
end;

procedure TdmPresupuestos.CopiarEmpresaaAlbaran(DataSet: TDataSet);
var
  sAlmacen: string;
  function FindField(const ANombre: string): TField;
  begin
    Result := unqryTablaG.FindField(ANombre);
  end;
  function FieldByName(const ANombre: string): TField;
  begin
    Result := unqryTablaG.FieldByName(ANombre);
  end;
begin
  if (unqryTablaG.State <> dsEdit) and
     (unqryTablaG.State <> dsInsert) then
    unqryTablaG.Edit;
    FindField('CODIGO_EMP_PRE').AsString             :=
      DataSet.FindField('CODIGO_EMP_EMP').AsString;
    FindField('RAZON_SOCIAL_EMPRESA_PRE').AsString   :=
      DataSet.FindField('RAZON_SOCIAL_EMP').AsString;
    FindField('NIF_EMPRESA_PRE').AsString            :=
      DataSet.FindField('NIF_EMP').AsString;
    FindField('MOVIL_EMPRESA_PRE').AsString          :=
      DataSet.FindField('MOVIL_EMP').AsString;
    FindField('EMAIL_EMPRESA_PRE').AsString          :=
      DataSet.FindField('EMAIL_EMP').AsString;
    FindField('DIRECCION1_EMPRESA_PRE').AsString     :=
      DataSet.FindField('DIRECCION1_EMP').AsString;
    FindField('DIRECCION2_EMPRESA_PRE').AsString     :=
      DataSet.FindField('DIRECCION2_EMP').AsString;
    FindField('POBLACION_EMPRESA_PRE').AsString      :=
      DataSet.FindField('POBLACION_EMP').AsString;
    FindField('PROVINCIA_EMPRESA_PRE').AsString      :=
      DataSet.FindField('PROVINCIA_EMP').AsString;
    FindField('CODIGO_POSTAL_EMPRESA_PRE').AsString  :=
      DataSet.FindField('CODIGO_POSTAL_EMP').AsString;
    FindField('NOMBRE_PAI_EMPRESA_PRE').AsString     :=
      DataSet.FindField('NOMBRE_PAI_EMP').AsString;
    FindField('CODIGO_PAI_EMPRESA_PRE').AsString     :=
      DataSet.FindField('CODIGO_PAI_EMP').AsString;
    FindField('GRUPO_ZONA_IVA_EMPRESA_PRE').AsString :=
      DataSet.FindField('GRUPO_ZONA_IVA_EMP').AsString;
    // El motor fiscal decide la retencion con estos indicadores.
    FindField('ESRETENCIONES_EMPRESA_PRE').AsString  :=
      DataSet.FindField('ESRETENCIONES_EMP').AsString;
    FindField('ESREGIMENESPECIALAGRICOLA_EMPRESA_PRE').AsString :=
      DataSet.FindField('ESREGIMENESPECIALAGRICOLA_EMP').AsString;
  if FindField('CODIGO_ALM_PRE') <> nil then
  begin
    RefrescarAlmacenes(DataSet.FindField('CODIGO_EMP_EMP').AsString);
    sAlmacen := Trim(FieldByName('CODIGO_ALM_PRE').AsString);
    if (sAlmacen <> '') and
       unqryAlmacenesAlb.Locate('CODIGO_ALM_ALM', sAlmacen, []) then
      FieldByName('CODIGO_ALM_PRE').AsString := sAlmacen
    else if (Trim(UbicacionSesion.Almacen) <> '') and
            unqryAlmacenesAlb.Locate('CODIGO_ALM_ALM',
                                     UbicacionSesion.Almacen,
                                     []) then
      FieldByName('CODIGO_ALM_PRE').AsString := UbicacionSesion.Almacen
    else
      FieldByName('CODIGO_ALM_PRE').Clear;
  end;
  ProponerSerieEmpresa(DataSet.FindField('CODIGO_EMP_EMP').AsString);
  AplicarPorcentajesIvaVenta(
    CrearLecturasImpuestos(ConexionEscritura), unqryTablaG, 'PRE');
end;

procedure TdmPresupuestos.ActualizarImpuestosTarifaCabecera(
  const ACodigoTarifa: string);
var
  sTarifa: string;
begin
  sTarifa := Trim(ACodigoTarifa);
  if unqryTablaG.Active and (unqryTablaG.State in dsEditModes) then
  begin
    if sTarifa = '' then
      unqryTablaG.FieldByName(
        'ESIMP_INCL_TARIFA_CLIENTE_PRE').Clear
    else
    begin
      if not unqryTarifas.Active then
        unqryTarifas.Open;
      if unqryTarifas.Locate('CODIGO_TAR_ARTTAR', sTarifa, []) then
        unqryTablaG.FieldByName(
          'ESIMP_INCL_TARIFA_CLIENTE_PRE').AsString :=
          unqryTarifas.FieldByName('ESIMP_INCL_TAR').AsString
      else
        unqryTablaG.FieldByName(
          'ESIMP_INCL_TARIFA_CLIENTE_PRE').Clear;
    end;
  end;
end;

procedure TdmPresupuestos.CopiarClienteaAlbaran(DataSet: TDataSet);
var
  sTarifa: string;
  function FindField(const ANombre: string): TField;
  begin
    Result := unqryTablaG.FindField(ANombre);
  end;
begin
  if (unqryTablaG.State <> dsEdit) and
     (unqryTablaG.State <> dsInsert) then
    unqryTablaG.Edit;
    FindField('CODIGO_CLI_PRE').AsString          :=
      DataSet.FindField('CODIGO_CLI_CLI').AsString;
    FindField('RAZON_SOCIAL_CLIENTE_PRE').AsString:=
      DataSet.FindField('RAZON_SOCIAL_CLI').AsString;
    FindField('NIF_CLIENTE_PRE').AsString         :=
      DataSet.FindField('NIF_CLI').AsString;
    FindField('MOVIL_CLIENTE_PRE').AsString       :=
      DataSet.FindField('MOVIL_CLI').AsString;
    FindField('EMAIL_CLIENTE_PRE').AsString       :=
      DataSet.FindField('EMAIL_CLI').AsString;
    FindField('DIRECCION1_CLIENTE_PRE').AsString  :=
      DataSet.FindField('DIRECCION1_CLI').AsString;
    FindField('DIRECCION2_CLIENTE_PRE').AsString  :=
      DataSet.FindField('DIRECCION2_CLI').AsString;
    FindField('POBLACION_CLIENTE_PRE').AsString   :=
      DataSet.FindField('POBLACION_CLI').AsString;
    FindField('PROVINCIA_CLIENTE_PRE').AsString   :=
      DataSet.FindField('PROVINCIA_CLI').AsString;
    FindField('CODIGO_POSTAL_CLIENTE_PRE').AsString :=
      DataSet.FindField('CODIGO_POSTAL_CLI').AsString;
    FindField('NOMBRE_PAI_CLIENTE_PRE').AsString  :=
      DataSet.FindField('NOMBRE_PAI_CLI').AsString;
    FindField('CODIGO_PAI_CLIENTE_PRE').AsString  :=
      DataSet.FindField('CODIGO_PAI_CLI').AsString;
    FindField('ESIVA_RECARGO_CLIENTE_PRE').AsString:=
      DataSet.FindField('ESIVA_RECARGO_CLI').AsString;
    FindField('ESIVA_EXENTO_CLIENTE_PRE').AsString:=
      DataSet.FindField('ESIVA_EXENTO_CLI').AsString;
    FindField('ESINTRACOMUNITARIO_CLIENTE_PRE').AsString :=
                            DataSet.FindField(
                              'ESINTRACOMUNITARIO_CLI').AsString;
    FindField('ESRETENCIONES_CLIENTE_PRE').AsString :=
      DataSet.FindField('ESRETENCIONES_CLI').AsString;
    FindField('ESREGIMENESPECIALAGRICOLA_CLIENTE_PRE').AsString :=
      DataSet.FindField('ESREGIMENESPECIALAGRICOLA_CLI').AsString;
    sTarifa := Trim(DataSet.FindField('TARIFA_ARTICULO_CLI').AsString);
    if sTarifa = '' then
      sTarifa := ParametrosCaja.TarifaDefecto;
  FindField('TARIFA_ARTICULO_CLIENTE_PRE').AsString := sTarifa;
  ActualizarImpuestosTarifaCabecera(sTarifa);
  AplicarPorcentajesIvaVenta(
    CrearLecturasImpuestos(ConexionEscritura), unqryTablaG, 'PRE');
end;

function TdmPresupuestos.ConexionEscritura: TUniConnection;
begin
  // Cada ventana de mantenimiento crea su propia conexion y reasigna a
  // ella los datasets (TdmBase.ReasignarConexion). La transaccion, los
  // SELECT ... FOR UPDATE y las lecturas de la operacion tienen que ir
  // por esa misma conexion: si salen por ConexionPrincipal, el UPDATE
  // del dataset acaba esperando un bloqueo que retiene el propio
  // programa desde otra conexion (MariaDB 1205, lock wait timeout).
  Result := nil;
  if Assigned(unqryTablaG) then
    Result := unqryTablaG.Connection;
  if not Assigned(Result) then
    Result := ConexionPrincipal;
end;

procedure TdmPresupuestos.IniciarEscritura(DataSet: TDataSet);
begin
  if not ConexionEscritura.InTransaction then
  begin
    ConexionEscritura.StartTransaction;
    FOperacion := DataSet;
  end;
  try
    ValidarEditable(DataSet);
  except
    CancelarEscritura(DataSet);
    raise;
  end;
end;

procedure TdmPresupuestos.ConfirmarEscritura(DataSet: TDataSet);
begin
  if FOperacion = DataSet then
  begin
    ConexionEscritura.Commit;
    FOperacion := nil;
  end;
end;

procedure TdmPresupuestos.CancelarEscritura(DataSet: TDataSet);
begin
  if FOperacion = DataSet then
  begin
    if ConexionEscritura.InTransaction then
      ConexionEscritura.Rollback;
    FOperacion := nil;
  end;
end;

procedure TdmPresupuestos.ErrorEscritura(DataSet: TDataSet;
  E: EDatabaseError; var Action: TDataAction);
begin
  CancelarEscritura(DataSet);
  Action := daFail;
end;

procedure TdmPresupuestos.ValidarEditable(DataSet: TDataSet);
begin
  if unqryTablaG.Active and (unqryTablaG.State <> dsInsert) and
     (not unqryTablaG.IsEmpty) then
    ComprobarPresupuestoEditable(ConexionEscritura,
      unqryTablaG.FieldByName('SERIE_PRE').AsString,
      unqryTablaG.FieldByName('NUMERO_PRE').AsString);
end;

procedure TdmPresupuestos.GuardarDocumento;
begin
  if unqryAlbaranesLineas.State in dsEditModes then
  begin
    if LineaAlbaranVacia(unqryAlbaranesLineas) then
      unqryAlbaranesLineas.Cancel
    else
      unqryAlbaranesLineas.Post;
  end;
  if unqryTablaG.State in dsEditModes then
    unqryTablaG.Post;
  if unqryTablaG.IsEmpty then
    raise Exception.Create(SErrorSeleccionePresupuesto);
end;

function TdmPresupuestos.Convertir(ADestino: TDestinoPresupuesto):
  TResultadoConversionPresupuesto;
begin
  GuardarDocumento;
  Result := ConvertirPresupuestoUniDAC(Self, ConexionEscritura,
    CrearSolicitudConversionPresupuesto(ADestino,
      unqryTablaG.FieldByName('SERIE_PRE').AsString,
      unqryTablaG.FieldByName('NUMERO_PRE').AsString,
      IdentidadSesion.Usuario));
  unqryTablaG.Refresh;
end;

function TdmPresupuestos.ConvertirConOpciones(
  ADestino: TDestinoPresupuesto;
  const AOpciones: TOpcionesConversionPresupuesto):
  TResultadoConversionPresupuesto;
begin
  GuardarDocumento;
  ValidarClienteConversion(ADestino);
  Result := ConvertirPresupuestoUniDAC(Self, ConexionEscritura,
    CrearSolicitudConversionPresupuestoOpciones(ADestino,
      unqryTablaG.FieldByName('SERIE_PRE').AsString,
      unqryTablaG.FieldByName('NUMERO_PRE').AsString,
      IdentidadSesion.Usuario, AOpciones));
  unqryTablaG.Refresh;
end;

function TdmPresupuestos.LineasVentaCaja: TLineasVentaCajaExterna;
var
  q: TUniQuery;
  iLinea: Integer;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := unqryTablaG.Connection;
    q.SQL.Text := SqlPrevisualizarLineasDocumentoOrigen(
      TIPO_DOCUMENTO_ORIGEN_PRESUPUESTO_VENTA);
    q.ParamByName('EMPRESA').AsString :=
      unqryTablaG.FieldByName('CODIGO_EMP_PRE').AsString;
    q.ParamByName('SERIE').AsString :=
      unqryTablaG.FieldByName('SERIE_PRE').AsString;
    q.ParamByName('NUMERO').AsString :=
      unqryTablaG.FieldByName('NUMERO_PRE').AsString;
    q.Open;
    SetLength(Result, q.RecordCount);
    iLinea := 0;
    while not q.Eof do
    begin
      Result[iLinea].CodigoSku := q.FieldByName('CODIGO_SKU').AsString;
      Result[iLinea].Cantidad := q.FieldByName('CANTIDAD').AsFloat;
      Inc(iLinea);
      q.Next;
    end;
    SetLength(Result, iLinea);
  finally
    FreeAndNil(q);
  end;
end;

initialization
  RegistrarDataModule(TdmPresupuestos);
end.
