{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataInventarios                                            }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de inventarios.                                               }
{    Cabeceras y líneas de fza_inventarios, regularizaciones de stock y        }
{    movimientos generados.                                                    }
{******************************************************************************}
unit UniDataInventarios;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, Winapi.Windows, Data.DB, MemDS, DBAccess,
  Uni, Datasnap.DBClient, Datasnap.Provider,
  UniDataGen, Vcl.Controls, System.UITypes, System.Generics.Collections,
  inLibInventariosRevalorizacion, inLibInventariosAplicacionIntf,
  inLibTrazabilidad;

type
  // Cabecera (heredado de TdmBase)
  TdmInventarios = class(TdmBase)

    // === LÍNEAS DEL INVENTARIO (Detalle pestaña 2) ===
    unqryLineas: TUniQuery;                    // Líneas físicas en BD
    udspLineas: TDataSetProvider;
    cdsLineas: TClientDataSet;                 // Buffer cliente para edición
    dsLineas: TDataSource;

    // === CAMPOS CALCULADOS DE cdsLineas ===
    cdsLineasCODIGO_EMPRESA_INVENTARIO_LINEA: TWideStringField;
    cdsLineasCODIGO_ALMACEN_INVENTARIO_LINEA: TWideStringField;
    cdsLineasSERIE_INVENTARIO_LINEA: TWideStringField;
    cdsLineasNRO_INVENTARIO_LINEA: TWideStringField;
    cdsLineasLINEA_INVENTARIO_LINEA: TWideStringField;
    cdsLineasCODIGO_ARTICULO_INVENTARIO_LINEA: TWideStringField;
    cdsLineasCODIGO_UNIDAD_INVENTARIO_LINEA: TWideStringField;
    cdsLineasLOTE_INVENTARIO_LINEA: TWideStringField;
    cdsLineasFECHA_CADUCIDAD_INVENTARIO_LINEA: TDateField;
    cdsLineasDESCRIPCION_ARTICULO_INVENTARIO_LINEA: TWideStringField;
    cdsLineasCANTIDAD_TEORICA_INVENTARIO_LINEA: TFloatField;
    cdsLineasCANTIDAD_FISICA_INVENTARIO_LINEA: TFloatField;
    cdsLineasCANTIDAD_DIFERENCIA_INVENTARIO_LINEA: TFloatField;
    cdsLineasPRECIO_MEDIO_INVENTARIO_LINEA: TFloatField;
    cdsLineasPRECIO_MEDIO_NUEVO_INVENTARIO_LINEA: TFloatField;
    cdsLineasESPRECIO_MEDIO_CORREGIDO_INVLIN: TWideStringField;
    cdsLineasTOTAL_COSTE_DIFERENCIA_LINEA: TFloatField;
    cdsLineasFECHA_RECUENTO_INVENTARIO_LINEA: TDateTimeField;
    // Conjunto pivotado en tallas horizontal (0 = sin pivote); columna
    // nueva de inventarios_tallas_horizontal.sql (ColumnSKUcxGrid).
    cdsLineasID_AC_PIVOT_INV_LINEA: TIntegerField;

    // === Campos in-memory para SKUs dinámicos (1 a 5 atributos) ===
    cdsLineasNUM_ATRIBUTOS_REQ_INV_LINEA: TIntegerField;
    cdsLineasATTR1_NOMBRE: TWideStringField;
    cdsLineasATTR1_VALOR: TWideStringField;
    cdsLineasATTR2_NOMBRE: TWideStringField;
    cdsLineasATTR2_VALOR: TWideStringField;
    cdsLineasATTR3_NOMBRE: TWideStringField;
    cdsLineasATTR3_VALOR: TWideStringField;
    cdsLineasATTR4_NOMBRE: TWideStringField;
    cdsLineasATTR4_VALOR: TWideStringField;
    cdsLineasATTR5_NOMBRE: TWideStringField;
    cdsLineasATTR5_VALOR: TWideStringField;
    cdsLineasTIPO_CANTIDAD_INV_LINEA: TWideStringField;
    // Unidades regularizadas (calculado: 0 si ABIERTO, =DIFERENCIA si APLICADO)
    cdsLineasUDS_REGULARIZADAS: TFloatField;

    // === MOVIMIENTOS DE ALMACÉN GENERADOS POR ESTE INVENTARIO (Pestaña 3) ===
    unqryMovsRegul: TUniQuery;
    dsMovsRegul: TDataSource;

    // === CONSULTAS AUXILIARES ===
    unqryArticulo: TUniQuery;                  // Buscar artículo por código
    unqryDefinicionArticulo: TUniQuery;        // Definición atributos del SKU
    unqryStockActual: TUniQuery;               // Lectura PMP/Stock actual
    unqryFamilias: TUniQuery;                  // Lookup familias
    dsFamilias: TDataSource;
    unqryProveedores: TUniQuery;               // Lookup proveedores
    dsProveedores: TDataSource;
    unqryAlmacenes: TUniQuery;
    dsAlmacenes: TDataSource;
    unqryEmpresas: TUniQuery;
    dsEmpresas: TDataSource;
    unqrySeries: TUniQuery;
    dsSeries: TDataSource;

    // === STORED PROCEDURES ===
    // PRC_FZA_INVENTARIOS_ACTUALIZAR_TEORICO
    unspActualizarTeorico: TUniStoredProc;
    unspAplicar: TUniStoredProc;               // PRC_FZA_INVENTARIOS_APLICAR
    unspEliminarRegul: TUniStoredProc;
    cdsLineasINSTANTE_ALTA: TDateTimeField;
    cdsLineasUSUARIO_ALTA: TWideStringField;
    cdsLineasUSUARIO_MODIF: TWideStringField;
    // PRC_FZA_INVENTARIOS_ELIMINAR_REGUL (nuevo)
    cdsLineasINSTANTE_MODIF: TDateTimeField;

    // === EVENTOS DE DATASET ===
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryTablaGAfterScroll(DataSet: TDataSet);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
    procedure cdsLineasAfterPost(DataSet: TDataSet);
    procedure cdsLineasBeforePost(DataSet: TDataSet);
    procedure cdsLineasBeforeDelete(DataSet: TDataSet);
    procedure cdsLineasBeforeInsert(DataSet: TDataSet);
    procedure cdsLineasAfterDelete(DataSet: TDataSet);
    procedure cdsLineasCalcFields(DataSet: TDataSet);
    procedure cdsLineasNewRecord(DataSet: TDataSet);
    procedure cdsLineasAfterEdit(DataSet: TDataSet);
    procedure cdsLineasAfterCancel(DataSet: TDataSet);
  private
    FCodigoEmpresa: string;
    FCodigoAlmacen: string;
    FSerie: string;
    FNumero: string;
    FUsuario: string;
    // Clave (empresa|almacen|serie|numero) de las lineas que hay en
    // cdsLineas: permite saltar las recargas repetidas del mismo
    // inventario que llegan por AfterScroll y por DataChange.
    FClaveLineasCargada: string;
    FMaximaLineaPersistida: Integer;
    FMaximaLineaConsultada: Boolean;
    // True mientras Midas, al calcular los fkInternalCalc de cada registro
    // (State = dsInternalCalc), debe rellenar ATTR1..5/NUM desde el SKU.
    FCalcularAtributosAlLeer: Boolean;
    // True entre Edit/Insert y Post/Cancel: Midas recalcula los
    // fkInternalCalc al cambiar cualquier campo de datos y no debe pisar
    // los atributos que el usuario esta tecleando.
    FLineaEnEdicion: Boolean;
    // FZ-ISSUE-244: unidad (TIPO_CANTIDAD_ART) por articulo, para que el
    // recuento use los decimales de la unidad. Se precarga al abrir.
    FUnidadesArticulo: TDictionary<string, string>;
    FAlEmpezarCargaLineas: TProc<Integer>;
    FAlTerminarCargaLineas: TProc;
    FColumnasRecuentoRemoto: Boolean;
    FColumnaContadorLineas: Boolean;
    FAplicacionLineasDiferida: Boolean;
    FTransaccionImportacionLineas: Boolean;
    // Flag idempotente: True cuando ATTR1..ATTR5_VALOR ya estan rellenos
    // a partir del SKU para las lineas actualmente cargadas en cdsLineas.
    // Se resetea a False cada vez que CargarLineasInventario reabre cds.
    FLineasDesempaquetadas: Boolean;
    // True mientras el modo TALLAS EN HORIZONTAL (ColumnSKUcxGrid)
    // esta activo o convirtiendo lineas (pivote/des-pivote): el
    // backstop de atributos y la validacion de SKU de BeforePost no
    // aplican a sus Posts intermedios.
    FModoPivoteActivo: Boolean;
    // True cuando el modo de entrada del contrato ensenya atributos
    // (desglose): CADA recarga de lineas desempaqueta SKU->ATTR aqui
    // mismo. Las recargas llegan por varios caminos (AfterScroll de
    // cabecera, cargas masivas...) y si alguna se salta el form, los
    // ATTR in-memory quedaban en blanco hasta reconstruir a mano.
    FDesempaquetarAlCargar: Boolean;
    // True mientras se relee la cabecera activa para mostrar los totales
    // recalculados: no es un cambio de inventario y no debe recargar nada.
    FRefrescandoTotalesCabecera: Boolean;
    procedure ValidarAlmacenNoTransito(DataSet: TDataSet);
    procedure BloquearInventarioParaRevalorizacion;
    procedure CargarUnidadesArticulosInventario;
    function UnidadArticulo(const ACodigoArticulo: string): string;
    procedure CodigoArticuloLineaChange(Sender: TField);
    function ExisteColumnaInventarios(const ACampo: string): Boolean;
    procedure GetCodigoAutoInventario;
    procedure PrepararSqlCabecera;
    function ContarLineasInventario: Integer;
    // Reabre cdsLineas desde unqryLineas (ya abierto: sin SQL) para que
    // Midas vuelva a calcular los fkInternalCalc de cada registro.
    procedure RecargarCdsLineas;
    procedure CalcularAtributosLinea(ADataSet: TDataSet);
    procedure RellenarAtributosLineaDesdeSku(ADataSet: TDataSet);
    // Quita Required=True de todos los persistent fields de cdsLineas. La
    // herencia via udspLineas + poIncFieldProps hacia que el cds rechazara
    // el Post antes de cdsLineasBeforePost.
    procedure ForzarRequiredFalseEnCdsLineas;
    procedure DesactivarRequeridosLinea(ADataSet: TDataSet);
    function ConstruirSnapshotLinea(ADataSet: TDataSet): string;
    procedure RegistrarSnapshotLinea(ADataSet: TDataSet);
    procedure ValidarClavesLinea(ADataSet: TDataSet);
    procedure DescartarLineaSinArticulo(ADataSet: TDataSet);
    procedure CompletarUnidadLinea(ADataSet: TDataSet);
    function RequiereValidarSkuLinea(ADataSet: TDataSet): Boolean;
    procedure ReconstruirSkuLinea(
      ADataSet: TDataSet;
      const ACodigoArticulo: string);
    procedure ValidarSkusRecuentoMovil(ALista: TStringList);
    procedure CargarSkuDesdeLista(
      const ASku: string;
      ACantidad: Currency;
      const ALote: string;
      AFechaCaducidad: TDateTime;
      AFechaRecuento: TDateTime;
      AReemplazarCantidad: Boolean;
      AConsulta: TUniQuery);
    function LocalizarLineaRecuento(const ASku, ALote: string): Boolean;
    procedure AsignarLoteLineaCarga(AConsulta: TDataSet);
    function CantidadTeoricaLote(const ASku, ALote: string;
      ACantidadSku: Currency): Currency;
  public
    // Teorico del lote de la linea actual (sin lote, ACantidadSku).
    function CantidadTeoricaLoteLinea(const ASku: string;
      ACantidadSku: Currency): Currency;
    function ModoTrazabilidadEfectivo(
      const ACodigoArticulo: string): TModoTrazabilidad;
    procedure EscribirLoteLeidoLinea(
      const ASku, ALote: string;
      AFechaCaducidad: TDate;
      AEsSerie: Boolean);
  private
    procedure ValidarOCrearSkuLinea(
      ADataSet: TDataSet;
      const ACodigoArticulo: string);
    // Tras cada ApplyUpdates de lineas: la cabecera guarda la suma de
    // diferencias (unidades y euros) y solo la recalculaban el teorico y
    // el aplicar (FZ-ISSUE-015).
    procedure cdsLineasAfterApplyUpdates(Sender: TObject;
      var OwnerData: OleVariant);
    procedure ActualizarTotalesCabecera;
    procedure RefrescarTotalesCabeceraActiva;
  public
    destructor Destroy; override;
    // === CONFIGURACIÓN ===
    procedure SetClavesActivas(const AEmpresa,
                               AAlmacen,
                               ASerie,
                               ANumero: string);
    // Ver FModoPivoteActivo: lo gobierna inMtoInventarios al
    // construir/desmontar el modo de tallas en horizontal.
    property ModoPivoteActivo: Boolean read FModoPivoteActivo
                                       write FModoPivoteActivo;
    // Ver FDesempaquetarAlCargar: lo gobierna inMtoInventarios segun
    // el modo de entrada activo (True en desglose).
    property DesempaquetarAlCargar: Boolean
      read FDesempaquetarAlCargar write FDesempaquetarAlCargar;
    // Ver FRefrescandoTotalesCabecera: el DataChange de la cabecera en el
    // form no debe reconstruir la rejilla de lineas por esta relectura.
    property RefrescandoTotalesCabecera: Boolean
      read FRefrescandoTotalesCabecera;

    // === CARGA DE LÍNEAS ===
    // Con ASoloSiCambiaClave=True no recarga si cdsLineas ya tiene las
    // lineas del inventario activo (navegacion); las rutas que modifican
    // la BBDD (aplicar, importar, recalcular...) usan el valor por defecto.
    procedure CargarLineasInventario(ASoloSiCambiaClave: Boolean = False);
    procedure CargarMovimientosRegularizacion;

    // === GESTIÓN DE LÍNEAS ===
    function GenerarSiguienteLinea: string;
    function FechaRecuentoPorDefecto: TDateTime;
    procedure AsegurarFechaRecuentoLinea;
    procedure ArrastrarFechaCabeceraALineas(AAnterior, ANueva: TDateTime);
    function GenerarSkuFinal(const AArticuloBase: string): string;
    procedure RellenarDatosArticulo(const ACodigoArticulo: string;
                                    out ADescripcion: string;
                                    out ANumAtributos: Integer;
                                    out ATipoArticulo: string);
    procedure RellenarDatosSku(const ASku: string;
                               out ACantidadTeorica: Currency;
                               out APMPActual: Currency);

    // === CARGAS MASIVAS ===
    procedure CargarPorFamilia(const ACodigoFamilia: string);
    procedure CargarPorProveedor(const ACodigoProveedor: string);
    procedure CargarTodosArticulosConStock;
    procedure CompletarUnidadesNoLeidas;
    function ImportarArticulosInventario(
      const AOrigen: TClaveInventario): Integer;
    procedure IniciarImportacionLineas;
    procedure MarcarRecuentoRecogido(const AClave: TClaveInventario);
    procedure ConfirmarImportacionLineas;
    procedure CancelarImportacionLineas;
    // Recuento móvil: deja en ALista solo SKUs de ViraCash. Un código de
    // barras se traduce a su SKU (fza_codigos_barras) y suma con él; lo que
    // no se puede asignar sale de la lista y se anota en ANoAsignados.
    // CODIGO=NOMBRE de los almacenes activos de la empresa (sin tránsito),
    // los mismos que ofrece la ficha del inventario.
    procedure ListarAlmacenesRecuento(const AEmpresa: string;
      ALista: TStrings);
    procedure NormalizarSkusRecuentoMovil(
      ALista: TStringList;
      AInstantesRecuento: TStrings;
      ANoAsignados: TStrings);
    procedure CargarDesdeListaSkus(
      ALista: TStringList;
      AReemplazarCantidad: Boolean = False;
      AInstantesRecuento: TStrings = nil;
      AAplicarCambios: Boolean = True);
    procedure PrepararLineaParaCargarSkus;
    function  CargarSkusConMovimientosArticulo(
      const ACodigoArticulo: string): Integer;
    function  SkuExiste(const ASku: string): Boolean;
    function  CrearSkuDesdeLinea(const ACodigoArticulo, ASku: string;
                                 const AAtributos: array of string): Boolean;

    // === ACCIONES SOBRE INVENTARIO ===
    function GetEstadoInventario: string;
    procedure AbrirDetalles; override;
    // Post + ApplyUpdates de la linea en edicion y de los cambios del
    // cdsLineas aun no aplicados (FZ-ISSUE-079).
    procedure GrabarLineasPendientes;
    procedure AplicarLineasPendientes;
    procedure AplicarCambiosDiferidos; override;
    // Devuelve las líneas con sobrante sin PMP en el almacén a las que se
    // ha propuesto el coste conocido del SKU (FZ-ISSUE-619).
    function RecalcularTeorico: Integer;
    // FZ-ISSUE-619: líneas guardadas con sobrante (física > teórica) cuyo
    // PMP nuevo es 0: entrarían al almacén a coste 0.
    function ContarSobrantesSinCoste: Integer;
    // FZ-ISSUE-621: serie propia del almacén del inventario (o la general
    // de la empresa, nunca la de otra tienda); solo en altas.
    procedure ProponerSerieNuevoInventario;
    function PrepararLineasRevalorizacion:
      TLineasBaseRevalorizacionInventario;
    procedure AplicarRevalorizacion(
      const ASimulacion: TSimulacionRevalorizacionInventario);
    // Camino sincrono original. Tiene instrumentacion [PERF:Aplicar] y
    // bloquea la UI hasta terminar. Util para llamadas batch o pruebas.
    procedure AplicarInventario;
    // Camino partido en 3 para Fase 2 (background). El llamador (el form)
    // ejecuta Pre y Refrescar en el main thread (tocan grids) y deja el
    // SP en TfrmMtoGen.EjecutarEnBackground. Ver
    // TfrmMtoInventarios.btnAplicarClick.
    procedure PreAplicarValidaciones;
    function HayMovimientosPosterioresAlRecuento: Boolean;
    procedure EjecutarSPAplicar;
    procedure RefrescarTrasAplicar;
    procedure EliminarRegularizacion;

    // === PROPIEDADES ===
    property CodigoEmpresa: string read FCodigoEmpresa;
    property CodigoAlmacen: string read FCodigoAlmacen;
    property Serie: string read FSerie;
    property Numero: string read FNumero;
    property ColumnasRecuentoRemoto: Boolean read FColumnasRecuentoRemoto;
    // True una vez que DesempaquetarAtributosDesdeSku ha rellenado los
    // ATTR1..ATTR5_VALOR de las lineas actuales. El form consulta este
    // flag para no relanzar el desempaquetado si ya esta hecho.
    property LineasDesempaquetadas: Boolean read FLineasDesempaquetadas;
    // Avisos de CargarLineasInventario para que la pantalla ensene un
    // letrero de espera: antes (con el numero de lineas del inventario)
    // y despues de la carga, tambien si falla.
    property AlEmpezarCargaLineas: TProc<Integer>
      read FAlEmpezarCargaLineas write FAlEmpezarCargaLineas;
    property AlTerminarCargaLineas: TProc
      read FAlTerminarCargaLineas write FAlTerminarCargaLineas;

    procedure CargarAlmacenesPorEmpresa(const ACodigoEmpresa: string);
    procedure CargarSeriesPorEmpresa(const ACodigoEmpresa: string);
    // Recorre cdsLineas rellenando ATTR1..ATTR5_VALOR a partir de
    // CODIGO_UNIDAD_INVLIN (SKU). Es idempotente: si FLineasDesempaquetadas
    // ya esta a True, sale sin hacer nada. El form lo invoca via
    // AsegurarDesempaquetadoAtributos cuando el toggle "Ver atributos en
    // columnas" esta activo (con barra de progreso si hay >150 lineas).
    procedure DesempaquetarAtributosDesdeSku;
  private
    // Conexion por la que salen la transaccion, los bloqueos y las
    // lecturas de la operacion: la misma que usan los datasets.
    function ConexionEscritura: TUniConnection;
    procedure EjecutarSPActualizarTeorico;
    function ProponerCosteSobrantesSinPmp: Integer;
  end;

implementation

uses
  System.Diagnostics,   // TStopwatch para instrumentacion de rendimiento
  System.StrUtils,      // IfThen(Boolean, string, string) para snapshot
  System.Variants,      // VarToStr de OldValue
  inLibUser,            // Usuario logueado
               // RegistroLog.RegistrarInformacion para metricas
  UniDataAlmacenesEmpresaRepositorio,
  UniDataConn,
  inLibInventarioNube,
  inLibPrestaShopColaSenal,
  inLibInventariosEntradaDataSet,
  inLibInventariosPresentacion,  // AtributosDesdeSkuInventario
  inLibMsgArticulos, UniDataInventariosBusquedas, inLibErroresBBDD,
  inLibInventarioRecuentoLote,
  inLibRecuentoSkuNormalizacion,
  UniDataResolutorSkuRecuento,
  UniDataValoresAutomaticosRepositorio,  // ObtenerSerieDefecto por almacén
  UniDataImpuestosRepositorio;  // factor de coste de la empresa en recargo

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TdmInventarios }

function TdmInventarios.ConexionEscritura: TUniConnection;
begin
  // Cada ventana de mantenimiento crea su propia conexion y reasigna a
  // ella los datasets (TdmBase.ReasignarConexion). La transaccion, los
  // SELECT ... FOR UPDATE y las lecturas de la operacion tienen que ir
  // por esa misma conexion: si salen por la conexion compartida, el
  // UPDATE del dataset acaba esperando un bloqueo que retiene el propio
  // programa desde otra conexion (MariaDB 1205, lock wait timeout).
  Result := nil;
  if Assigned(unqryTablaG) then
    Result := unqryTablaG.Connection;
  if not Assigned(Result) then
    Result := ConexionPrincipal;
end;

procedure TdmInventarios.CargarLineasInventario(
  ASoloSiCambiaClave: Boolean);
var
  sClave: string;
begin
  // FNumero='0' es el marcador de "cabecera todavia sin numero asignado":
  // unqryTablaGAfterInsert lo pone, y BeforePost lo sustituye por el numero
  // real via GetCodigoAutoInventario. Si consultamos lineas con '0', traemos
  // cualquier linea huerfana persistida con esa clave de una insercion
  // previa que se cancelo despues de grabar lineas (registro fantasma).
  if (FCodigoEmpresa = '') or (FNumero = '') or (FNumero = '0') then
  begin
    FClaveLineasCargada := '';
    if cdsLineas.Active then
      cdsLineas.EmptyDataSet;
  end
  else if not (cdsLineas.Active and
              (cdsLineas.State in [dsInsert, dsEdit])) then
  begin
    // No se recarga durante un Insert o Edit para evitar reentradas.
    sClave := FCodigoEmpresa + '|' + FCodigoAlmacen + '|' + FSerie + '|' +
      FNumero;
    // Con la misma clave ya cargada no hace falta releer las lineas.
    if not (ASoloSiCambiaClave and cdsLineas.Active and
            (FClaveLineasCargada = sClave)) then
    begin
      FClaveLineasCargada := '';
      if Assigned(FAlEmpezarCargaLineas) then
        FAlEmpezarCargaLineas(ContarLineasInventario);
      try
        unqryLineas.Close;
        unqryLineas.ParamByName('EMPRESA').AsString := FCodigoEmpresa;
        unqryLineas.ParamByName('ALMACEN').AsString := FCodigoAlmacen;
        unqryLineas.ParamByName('SERIE').AsString   := FSerie;
        unqryLineas.ParamByName('NUMERO').AsString  := FNumero;
        unqryLineas.Open;
        CargarUnidadesArticulosInventario;
        if cdsLineas.Active then
          cdsLineas.Close;
        // Los atributos (ATTR1..5/NUM) los calcula Midas registro a
        // registro al leerlo (cdsLineasCalcFields con dsInternalCalc):
        // ninguna pasada extra sobre las lineas.
        FCalcularAtributosAlLeer := FDesempaquetarAlCargar;
        RecargarCdsLineas;
        FLineasDesempaquetadas := FCalcularAtributosAlLeer;
        FClaveLineasCargada := sClave;
      finally
        if Assigned(FAlTerminarCargaLineas) then
          FAlTerminarCargaLineas();
      end;
    end;
  end;
end;

function TdmInventarios.ContarLineasInventario: Integer;
var
  qry: TUniQuery;
begin
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := unqryLineas.Connection;
    qry.SQL.Text :=
      'SELECT COUNT(*) AS N FROM fza_inventarios_lineas' + sLineBreak +
      ' WHERE CODIGO_EMP_INVLIN = :EMPRESA' + sLineBreak +
      '   AND CODIGO_ALM_INVLIN = :ALMACEN' + sLineBreak +
      '   AND SERIE_INV_INVLIN = :SERIE' + sLineBreak +
      '   AND NUMERO_INV_INVLIN = :NUMERO';
    qry.ParamByName('EMPRESA').AsString := FCodigoEmpresa;
    qry.ParamByName('ALMACEN').AsString := FCodigoAlmacen;
    qry.ParamByName('SERIE').AsString   := FSerie;
    qry.ParamByName('NUMERO').AsString  := FNumero;
    qry.Open;
    Result := qry.FieldByName('N').AsInteger;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TdmInventarios.RecargarCdsLineas;
var
  iRecNo: Integer;
begin
  iRecNo := 0;
  if cdsLineas.Active then
  begin
    if not cdsLineas.IsEmpty then
      iRecNo := cdsLineas.RecNo;
    cdsLineas.Close;
  end;
  FLineaEnEdicion := False;
  FMaximaLineaConsultada := False;
  cdsLineas.Open;
  ForzarRequiredFalseEnCdsLineas;
  if (iRecNo > 0) and (iRecNo <= cdsLineas.RecordCount) then
    cdsLineas.RecNo := iRecNo;
end;

procedure TdmInventarios.DesempaquetarAtributosDesdeSku;
begin
  // Antes se recorrian las lineas con Edit/Post por cada una: con
  // 80.000 lineas el change log de Midas lo hacia cuadratico (mas de un
  // minuto por inventario). Ahora basta con reabrir el buffer con el
  // calculo activado: Midas pide cdsLineasCalcFields por registro.
  if cdsLineas.Active and (not cdsLineas.IsEmpty) and
     (not FLineasDesempaquetadas) and unqryLineas.Active then
  begin
    FCalcularAtributosAlLeer := True;
    RecargarCdsLineas;
    FLineasDesempaquetadas := True;
  end;
end;

procedure TdmInventarios.CalcularAtributosLinea(ADataSet: TDataSet);
begin
  if FCalcularAtributosAlLeer and (not FLineaEnEdicion) then
    RellenarAtributosLineaDesdeSku(ADataSet);
end;

procedure TdmInventarios.RellenarAtributosLineaDesdeSku(ADataSet: TDataSet);
var
  Partes: TArray<string>;
  i: Integer;
begin
  Partes := AtributosDesdeSkuInventario(
    ADataSet.FieldByName('CODIGO_ART_INVLIN').AsString,
    ADataSet.FieldByName('CODIGO_UNIDAD_INVLIN').AsString);
  if Length(Partes) > 0 then
  begin
    ADataSet.FieldByName('NUM_ATRIBUTOS_REQ_INV_LINEA').AsInteger :=
      Length(Partes);
    for i := 1 to 5 do
    begin
      if i <= Length(Partes) then
        ADataSet.FieldByName('ATTR' + IntToStr(i) + '_VALOR').AsString :=
          Partes[i - 1]
      else
        ADataSet.FieldByName('ATTR' + IntToStr(i) + '_VALOR').AsString :=
          '';
    end;
  end;
end;


procedure TdmInventarios.cdsLineasAfterEdit(DataSet: TDataSet);
begin
  FLineaEnEdicion := True;
end;

procedure TdmInventarios.cdsLineasAfterCancel(DataSet: TDataSet);
begin
  FLineaEnEdicion := False;
end;

procedure TdmInventarios.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryTablaG.Connection           := ConexionPrincipal;
  unqryLineas.Connection           := ConexionPrincipal;
  unqryMovsRegul.Connection        := ConexionPrincipal;
  unqryArticulo.Connection         := ConexionPrincipal;
  unqryDefinicionArticulo.Connection := ConexionPrincipal;
  unqryStockActual.Connection      := ConexionPrincipal;
  unqryFamilias.Connection         := ConexionPrincipal;
  unqryProveedores.Connection      := ConexionPrincipal;
  unqryAlmacenes.Connection        := ConexionPrincipal;
  unqryEmpresas.Connection         := ConexionPrincipal;
  unqrySeries.Connection           := ConexionPrincipal;
  unspActualizarTeorico.Connection := ConexionPrincipal;
  unspAplicar.Connection           := ConexionPrincipal;
  unspEliminarRegul.Connection     := ConexionPrincipal;
  PrepararSqlCabecera;
  cdsLineasCODIGO_ARTICULO_INVENTARIO_LINEA.OnChange :=
    CodigoArticuloLineaChange;

  unqryLineas.SQLUpdate.Text :=
    'UPDATE fza_inventarios_lineas SET ' + sLineBreak +
    '  CODIGO_ART_INVLIN              = :CODIGO_ART_INVLIN,' + sLineBreak +
    '  CODIGO_UNIDAD_INVLIN           = :CODIGO_UNIDAD_INVLIN,' + sLineBreak +
    '  LOTE_INVLIN                    = :LOTE_INVLIN,' + sLineBreak +
    '  FECHA_CADUCIDAD_INVLIN         = :FECHA_CADUCIDAD_INVLIN,' + sLineBreak +
    '  DESCRIPCION_ARTICULO_INVLIN    = :DESCRIPCION_ARTICULO_INVLIN,'
      + sLineBreak +
    '  CANTIDAD_TEORICA_INVLIN        = :CANTIDAD_TEORICA_INVLIN,'
      + sLineBreak +
    '  CANTIDAD_FISICA_INVLIN         = :CANTIDAD_FISICA_INVLIN,' + sLineBreak +
    '  CANTIDAD_DIFERENCIA_INVLIN     = :CANTIDAD_DIFERENCIA_INVLIN,'
      + sLineBreak +
    '  PRECIO_MEDIO_INVLIN            = :PRECIO_MEDIO_INVLIN,' + sLineBreak +
    '  PRECIO_MEDIO_NUEVO_INVLIN      = :PRECIO_MEDIO_NUEVO_INVLIN,'
      + sLineBreak +
    '  ESPRECIO_MEDIO_CORREGIDO_INVLIN = ' +
    ':ESPRECIO_MEDIO_CORREGIDO_INVLIN,' + sLineBreak +
    '  TOTAL_COSTE_DIFERENCIA_INVLIN  = :TOTAL_COSTE_DIFERENCIA_INVLIN,'
      + sLineBreak +
    '  FECHA_RECUENTO_INVLIN          = :FECHA_RECUENTO_INVLIN,' + sLineBreak +
    '  ID_AC_PIVOT_INVLIN             = :ID_AC_PIVOT_INVLIN,' + sLineBreak +
    '  USUARIO_MODIF                  = :USUARIO_MODIF ' + sLineBreak +
    'WHERE CODIGO_EMP_INVLIN          = :OLD_CODIGO_EMP_INVLIN ' + sLineBreak +
    '  AND CODIGO_ALM_INVLIN          = :OLD_CODIGO_ALM_INVLIN ' + sLineBreak +
    '  AND SERIE_INV_INVLIN           = :OLD_SERIE_INV_INVLIN ' + sLineBreak +
    '  AND NUMERO_INV_INVLIN          = :OLD_NUMERO_INV_INVLIN ' + sLineBreak +
    '  AND LINEA_INVLIN               = :OLD_LINEA_INVLIN ';

  unqryLineas.SQLDelete.Text :=
    'DELETE FROM fza_inventarios_lineas ' + sLineBreak +
    'WHERE CODIGO_EMP_INVLIN          = :OLD_CODIGO_EMP_INVLIN ' + sLineBreak +
    '  AND CODIGO_ALM_INVLIN          = :OLD_CODIGO_ALM_INVLIN ' + sLineBreak +
    '  AND SERIE_INV_INVLIN           = :OLD_SERIE_INV_INVLIN ' + sLineBreak +
    '  AND NUMERO_INV_INVLIN          = :OLD_NUMERO_INV_INVLIN ' + sLineBreak +
    '  AND LINEA_INVLIN               = :OLD_LINEA_INVLIN ';

  // Apertura de los lookups
  if not unqryEmpresas.Active   then unqryEmpresas.Open;
  if not unqryAlmacenes.Active  then unqryAlmacenes.Open;
  if not unqrySeries.Active     then unqrySeries.Open;
  if not unqryFamilias.Active   then unqryFamilias.Open;
  if not unqryProveedores.Active then unqryProveedores.Open;

  // Desactivamos Required en todos los persistent fields de cdsLineas. Con
  // poIncFieldProps a True (default de udspLineas), el TClientDataSet
  // hereda Required=True desde el esquema NOT NULL de la BBDD y rechaza
  // el Post con "Field value required" antes incluso de llegar a
  // cdsLineasBeforePost (que es donde damos mensajes claros y rellenamos
  // CODIGO_UNIDAD_INVLIN si llega vacio). NewRecord, BeforePost y la BBDD
  // siguen siendo los responsables reales de la integridad — la BBDD
  // rechazara cualquier INSERT NULL con un error 1048 que UniDataConn
  // ya traduce a "Hay campos obligatorios sin rellenar".
  ForzarRequiredFalseEnCdsLineas;
  cdsLineas.AfterApplyUpdates := cdsLineasAfterApplyUpdates;

  FUsuario := IdentidadSesion.Usuario;
end;

procedure TdmInventarios.ForzarRequiredFalseEnCdsLineas;
var
  i: Integer;
begin
  if cdsLineas <> nil then
  begin
    for i := 0 to cdsLineas.FieldCount - 1 do
      cdsLineas.Fields[i].Required := False;
    for i := 0 to cdsLineas.FieldDefs.Count - 1 do
      cdsLineas.FieldDefs[i].Required := False;
  end;
end;

function TdmInventarios.ExisteColumnaInventarios(const ACampo: string): Boolean;
var
  qry: TUniQuery;
begin
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := unqryTablaG.Connection;
    qry.SQL.Text :=
      'SELECT COUNT(*) AS N' + sLineBreak +
      '  FROM INFORMATION_SCHEMA.COLUMNS' + sLineBreak +
      ' WHERE TABLE_SCHEMA = DATABASE()' + sLineBreak +
      '   AND TABLE_NAME = ''fza_inventarios''' + sLineBreak +
      '   AND COLUMN_NAME = :campo';
    qry.ParamByName('campo').AsString := ACampo;
    qry.Open;
    Result := qry.FieldByName('N').AsInteger > 0;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TdmInventarios.PrepararSqlCabecera;
var
  sColumnas: string;
begin
  FColumnaContadorLineas := ExisteColumnaInventarios('CONTADOR_LINEAS_INV');
  FColumnasRecuentoRemoto :=
    ExisteColumnaInventarios('ESRECUENTO_REMOTO_INV') and
    ExisteColumnaInventarios('INSTANTE_ENVIO_RECUENTO_INV') and
    ExisteColumnaInventarios('INSTANTE_RECOGIDA_RECUENTO_INV') and
    ExisteColumnaInventarios('ID_RECUENTO_REMOTO_INV');
  sColumnas :=
    '   CODIGO_EMP_INV,' + sLineBreak +
    '   CODIGO_ALM_INV,' + sLineBreak +
    '   SERIE_INV,' + sLineBreak +
    '   NUMERO_INV,' + sLineBreak +
    '   TIPO_DOC_INV,' + sLineBreak +
    '   FECHA_INV,' + sLineBreak +
    '   ESTADO_INV,' + sLineBreak +
    '   DESCRIPCION_INV,' + sLineBreak +
    '   OBSERVACIONES_INV,' + sLineBreak +
    '   TOTAL_UNIDADES_DIFERENCIA_INV,' + sLineBreak +
    '   TOTAL_EUROS_DIFERENCIA_INV,' + sLineBreak;
  if not FColumnaContadorLineas then
    RegistroLog.RegistrarAviso(
      'Inventarios: falta CONTADOR_LINEAS_INV. Ejecutar ' +
      'DESARROLLOS EN CURSO\inventarios_contador_lineas.sql antes de ' +
      'anadir lineas manuales.');
  if FColumnasRecuentoRemoto then
    sColumnas := sColumnas +
      '   ESRECUENTO_REMOTO_INV,' + sLineBreak +
      '   INSTANTE_ENVIO_RECUENTO_INV,' + sLineBreak +
      '   INSTANTE_RECOGIDA_RECUENTO_INV,' + sLineBreak +
      '   ID_RECUENTO_REMOTO_INV,' + sLineBreak
  else
    RegistroLog.RegistrarAviso(
      'Inventarios: faltan columnas de recuento remoto. ' +
      'La lista se abrira sin esos campos; ejecutar ' +
      'DESARROLLOS EN CURSO\recuento_inventarios_factuzam.sql.');
  sColumnas := sColumnas +
    '   INSTANTE_ALTA, INSTANTE_MODIF,' + sLineBreak +
    '   USUARIO_ALTA,  USUARIO_MODIF' + sLineBreak;
  unqryTablaG.Close;
  unqryTablaG.SQL.Text :=
    'SELECT' + sLineBreak + sColumnas +
    'FROM fza_inventarios' + sLineBreak +
    'ORDER BY FECHA_INV DESC';
  // Relectura de la cabecera activa (RefreshRecord) sin recargar la lista:
  // un Refresh dispara AfterScroll y recarga las lineas en plena edicion.
  unqryTablaG.SQLRefresh.Text :=
    'SELECT' + sLineBreak + sColumnas +
    'FROM fza_inventarios' + sLineBreak +
    'WHERE CODIGO_EMP_INV = :CODIGO_EMP_INV' + sLineBreak +
    '  AND CODIGO_ALM_INV = :CODIGO_ALM_INV' + sLineBreak +
    '  AND SERIE_INV      = :SERIE_INV' + sLineBreak +
    '  AND NUMERO_INV     = :NUMERO_INV';
end;

procedure TdmInventarios.SetClavesActivas(const AEmpresa, AAlmacen, ASerie,
  ANumero: string);
begin
  if (FCodigoEmpresa <> AEmpresa) or (FCodigoAlmacen <> AAlmacen) or
     (FSerie <> ASerie) or (FNumero <> ANumero) then
    FMaximaLineaConsultada := False;
  FCodigoEmpresa := AEmpresa;
  FCodigoAlmacen := AAlmacen;
  FSerie         := ASerie;
  FNumero        := ANumero;
end;

procedure TdmInventarios.unqryTablaGAfterScroll(DataSet: TDataSet);
begin
  // La apertura async dispara AfterScroll desde un thread. Las lineas y
  // movimientos se abren en AbrirDetalles, ya en el hilo principal.
  if (not DataSet.IsEmpty) and
     (not DataSet.ControlsDisabled) and
     (not FRefrescandoTotalesCabecera) and
     (GetCurrentThreadId = MainThreadID) then
  begin
    // OJO: aqui SI hay que resincronizar incluso durante dsInsert.
    // Al pulsar "+" desde una cabecera cargada, AfterInsert pone NUMERO='0'
    // y CargarLineasInventario vacia el detalle sin consultar la BD.
    SetClavesActivas(DataSet.FieldByName('CODIGO_EMP_INV').AsString,
                     DataSet.FieldByName('CODIGO_ALM_INV').AsString,
                     DataSet.FieldByName('SERIE_INV').AsString,
                     DataSet.FieldByName('NUMERO_INV').AsString);
    CargarLineasInventario(True);
    CargarMovimientosRegularizacion;
  end;
end;

procedure TdmInventarios.AbrirDetalles;
begin
  inherited;
  if (unqryTablaG <> nil) and unqryTablaG.Active and
     (not unqryTablaG.IsEmpty) then
    unqryTablaGAfterScroll(unqryTablaG);
end;

procedure TdmInventarios.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  // Pre-rellenamos los datos por defecto del usuario logueado al crear un
  // inventario nuevo, igual que hace facturas:
  // - empresa/almacen del usuario
  // (UbicacionSesion.Empresa/UbicacionSesion.Almacen, cargados en login)
  //   - serie por defecto de la empresa para tipo IN
  //   - NUMERO_INV='0' como marcador para que BeforePost asigne el contador
  //     real desde fza_contadores via PRC_GET_NEXT_CONT_FACT_SERIE.
  if Trim(UbicacionSesion.Empresa) <> '' then
    DataSet.FieldByName('CODIGO_EMP_INV').AsString := UbicacionSesion.Empresa;
  if Trim(UbicacionSesion.Almacen) <> '' then
    DataSet.FieldByName('CODIGO_ALM_INV').AsString := UbicacionSesion.Almacen;
  DataSet.FieldByName('TIPO_DOC_INV').AsString := 'IN';
  DataSet.FieldByName('FECHA_INV').AsDateTime  := Now;
  DataSet.FieldByName('ESTADO_INV').AsString   := 'ABIERTO';
  DataSet.FieldByName('NUMERO_INV').AsString   := '0';
  CargarAlmacenesPorEmpresa(
    DataSet.FieldByName('CODIGO_EMP_INV').AsString);
  // FZ-ISSUE-621: la serie depende del almacén ya ajustado a la empresa.
  ProponerSerieNuevoInventario;
end;

procedure TdmInventarios.ProponerSerieNuevoInventario;
begin
  // Un inventario guardado conserva su clave. En altas, la empresa o el
  // almacén pueden cambiar después del prerrelleno con la ubicación.
  if unqryTablaG.Active and (unqryTablaG.State = dsInsert) and
     (Trim(unqryTablaG.FieldByName('CODIGO_EMP_INV').AsString) <> '') then
    unqryTablaG.FieldByName('SERIE_INV').AsString := ObtenerSerieDefecto(
      unqryTablaG.Connection,
      unqryTablaG.FieldByName('CODIGO_EMP_INV').AsString,
      'IN',
      unqryTablaG.FieldByName('CODIGO_ALM_INV').AsString);
end;

procedure TdmInventarios.unqryTablaGBeforeDelete(DataSet: TDataSet);
begin
//
end;

procedure TdmInventarios.unqryTablaGBeforePost(DataSet: TDataSet);
var
  campoRecuento: TField;
begin
  inherited;
  // ESRECUENTO_REMOTO_INV es char(1) NOT NULL en BBDD (default 'N'). Al
  // anadirse al SELECT de la cabecera es un campo Required del dataset, asi
  // que una cabecera nueva (que no se ha enviado a recuento) llegaria al Post
  // con el valor sin asignar y reventaria con "Field 'ESRECUENTO_REMOTO_INV'
  // must have a value". Garantizamos el valor por defecto antes del Post.
  campoRecuento := DataSet.FindField('ESRECUENTO_REMOTO_INV');
  if campoRecuento <> nil then
    if Trim(campoRecuento.AsString) = '' then
      campoRecuento.AsString := 'N';
  // Validacion explicita: la serie es parte de la PK de las lineas y
  // varchar(20) NOT NULL en BBDD. Si llega vacia (porque la empresa no
  // tiene una serie por defecto en fza_empresas_series para tipo IN),
  // la cabecera se grabaria con SERIE_INV='' y las lineas heredarian
  // ese vacio, que despues hace reventar el TClientDataSet en Post con
  // un cryptico "Field value required" desde DSBase / MidasLib.
  if Trim(DataSet.FieldByName('SERIE_INV').AsString) = '' then
    raise Exception.Create(SErrorSerieInventarioObligatoria);
  ValidarAlmacenNoTransito(DataSet);
  // Forzamos campos de auditoría
  if DataSet.State = dsInsert then
  begin
    DataSet.FieldByName('USUARIO_ALTA').AsString := FUsuario;
    if DataSet.FieldByName('FECHA_INV').IsNull then
      DataSet.FieldByName('FECHA_INV').AsDateTime := Now;
    if DataSet.FieldByName('ESTADO_INV').AsString = '' then
      DataSet.FieldByName('ESTADO_INV').AsString := 'ABIERTO';
    if DataSet.FieldByName('TIPO_DOC_INV').AsString = '' then
      DataSet.FieldByName('TIPO_DOC_INV').AsString := 'IN';
    // Si el numero viene a '0' (recien insertado), tomamos el contador real
    // de fza_contadores. El SP esta nombrado como FACT_SERIE pero es generico
    // y acepta cualquier tipo de documento + serie + empresa.
    if DataSet.FieldByName('NUMERO_INV').AsString = '0' then
      GetCodigoAutoInventario;
  end;
  if (DataSet.State = dsEdit) and
     (DataSet.FieldByName('ESTADO_INV').AsString = 'ABIERTO') and
     (not DataSet.FieldByName('FECHA_INV').IsNull) and
     (not VarIsNull(DataSet.FieldByName('FECHA_INV').OldValue)) then
    ArrastrarFechaCabeceraALineas(
      VarToDateTime(DataSet.FieldByName('FECHA_INV').OldValue),
      DataSet.FieldByName('FECHA_INV').AsDateTime);
  DataSet.FieldByName('USUARIO_MODIF').AsString := FUsuario;
end;

// FZ-ISSUE-240: un almacén de tránsito solo es contenedor de traspasos.
// Solo al dar de alta o cambiar el almacén: lo ya grabado se puede tocar.
procedure TdmInventarios.ValidarAlmacenNoTransito(DataSet: TDataSet);
var
  oConsulta: TUniQuery;
  sAlmacen: string;
begin
  sAlmacen := Trim(DataSet.FieldByName('CODIGO_ALM_INV').AsString);
  if (sAlmacen = '') or
     ((DataSet.State = dsEdit) and
      SameText(sAlmacen, Trim(VarToStr(
        DataSet.FieldByName('CODIGO_ALM_INV').OldValue)))) then
    Exit;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := TUniQuery(DataSet).Connection;
    oConsulta.SQL.Text :=
      'SELECT 1 FROM fza_almacenes ' +
      ' WHERE CODIGO_ALM_ALM = :ALMACEN ' +
      '   AND TIPO_USO_ALM IN (''TR' + #$C1 + 'NSITO'', ''TRANSITO'')';
    oConsulta.ParamByName('ALMACEN').AsString := sAlmacen;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      raise EValidacionBBDD.CreateFmt(SErrorInventarioAlmacenTransito,
        [sAlmacen]);
  finally
    oConsulta.Free;
  end;
end;

procedure TdmInventarios.GetCodigoAutoInventario;
var
  sp: TUniStoredProc;
begin
  if unqryTablaG.FindField('NUMERO_INV').AsString = '0' then
  begin
    sp := TUniStoredProc.Create(nil);
    try
      sp.Connection := ConexionEscritura;
      sp.StoredProcName := 'PRC_GET_NEXT_CONT_FACT_SERIE';
      sp.Params.Clear;
      sp.Params.CreateParam(ftString, 'pserie', ptInput);
      sp.Params.CreateParam(ftString, 'ptipodoc', ptInput);
      sp.Params.CreateParam(ftString, 'pEMPRESA_CONTADOR', ptInput);
      sp.Params.CreateParam(ftString, 'pUSUARIOMODIF', ptInput);
      sp.Params.CreateParam(ftString, 'pcont', ptOutput);
      sp.ParamByName('pserie').AsString :=
        unqryTablaG.FindField('SERIE_INV').AsString;
      sp.ParamByName('ptipodoc').AsString := 'IN';
      sp.ParamByName('pEMPRESA_CONTADOR').AsString :=
        unqryTablaG.FindField('CODIGO_EMP_INV').AsString;
      sp.ParamByName('pUSUARIOMODIF').AsString :=
        IdentidadSesion.Usuario;
      sp.ExecProc;
      unqryTablaG.FindField('NUMERO_INV').AsString :=
        sp.ParamByName('pcont').AsString;
    finally
      FreeAndNil(sp);
    end;
  end;
end;

procedure TdmInventarios.CargarMovimientosRegularizacion;
begin
  unqryMovsRegul.Close;
  if (FCodigoEmpresa <> '') and (FCodigoAlmacen <> '') and
     (FSerie <> '') and (FNumero <> '') and
     (GetEstadoInventario = 'APLICADO') then
  begin
    unqryMovsRegul.ParamByName('EMPRESA').AsString := FCodigoEmpresa;
    unqryMovsRegul.ParamByName('ALMACEN').AsString := FCodigoAlmacen;
    unqryMovsRegul.ParamByName('SERIE').AsString   := FSerie;
    unqryMovsRegul.ParamByName('NUMERO').AsString  := FNumero;
    unqryMovsRegul.Open;
  end;
end;

function TdmInventarios.GenerarSiguienteLinea: string;
var
  bTransPropia: Boolean;
  iNuevaLinea: Integer;
  qry: TUniQuery;
begin
  Result := '';
  if not FColumnaContadorLineas then
    raise Exception.Create(SErrorContadorLineasInventarioNoInstalado);
  if (Trim(FCodigoEmpresa) = '') or (Trim(FCodigoAlmacen) = '') or
     (Trim(FSerie) = '') or (Trim(FNumero) = '') or
     (Trim(FNumero) = '0') then
    raise Exception.Create(SErrorCabeceraInventarioSinGrabarParaReserva);
  bTransPropia := not ConexionEscritura.InTransaction;
  if bTransPropia then
    ConexionEscritura.StartTransaction;
  qry := TUniQuery.Create(nil);
  try
    try
      qry.Connection := ConexionEscritura;
      qry.SQL.Text :=
        'SELECT IFNULL(CAST(NULLIF(CAST(CONTADOR_LINEAS_INV ' +
        'AS CHAR), '''') AS UNSIGNED), 0) AS NV ' +
        '  FROM fza_inventarios ' +
        ' WHERE CODIGO_EMP_INV = :EMPRESA ' +
        '   AND CODIGO_ALM_INV = :ALMACEN ' +
        '   AND SERIE_INV = :SERIE ' +
        '   AND NUMERO_INV = :NUMERO ' +
        ' FOR UPDATE';
      qry.ParamByName('EMPRESA').AsString := FCodigoEmpresa;
      qry.ParamByName('ALMACEN').AsString := FCodigoAlmacen;
      qry.ParamByName('SERIE').AsString := FSerie;
      qry.ParamByName('NUMERO').AsString := FNumero;
      qry.Open;
      if qry.Eof then
        raise Exception.Create(SErrorCabeceraInventarioNoEncontrada);
      iNuevaLinea := qry.FieldByName('NV').AsInteger + 1;
      qry.Close;
      // Una consulta por carga, no por alta: evita recorrer todas las
      // líneas en cada inserción de una importación grande. El contador
      // de cabecera continúa reservándose con FOR UPDATE en cada alta.
      if not FMaximaLineaConsultada then
      begin
        qry.SQL.Text :=
          'SELECT COALESCE(MAX(CAST(LINEA_INVLIN AS UNSIGNED)), 0) ' +
          'AS ULTIMA FROM fza_inventarios_lineas ' +
          'WHERE CODIGO_EMP_INVLIN = :EMPRESA ' +
          'AND CODIGO_ALM_INVLIN = :ALMACEN ' +
          'AND SERIE_INV_INVLIN = :SERIE ' +
          'AND NUMERO_INV_INVLIN = :NUMERO';
        qry.ParamByName('EMPRESA').AsString := FCodigoEmpresa;
        qry.ParamByName('ALMACEN').AsString := FCodigoAlmacen;
        qry.ParamByName('SERIE').AsString := FSerie;
        qry.ParamByName('NUMERO').AsString := FNumero;
        qry.Open;
        FMaximaLineaPersistida := qry.FieldByName('ULTIMA').AsInteger;
        FMaximaLineaConsultada := True;
        qry.Close;
      end;
      if iNuevaLinea <= FMaximaLineaPersistida then
        iNuevaLinea := FMaximaLineaPersistida + 1;
      qry.SQL.Text :=
        'UPDATE fza_inventarios ' +
        '   SET CONTADOR_LINEAS_INV = :NUEVO ' +
        ' WHERE CODIGO_EMP_INV = :EMPRESA ' +
        '   AND CODIGO_ALM_INV = :ALMACEN ' +
        '   AND SERIE_INV = :SERIE ' +
        '   AND NUMERO_INV = :NUMERO';
      qry.ParamByName('NUEVO').AsString := Format('%.8d', [iNuevaLinea]);
      qry.ParamByName('EMPRESA').AsString := FCodigoEmpresa;
      qry.ParamByName('ALMACEN').AsString := FCodigoAlmacen;
      qry.ParamByName('SERIE').AsString := FSerie;
      qry.ParamByName('NUMERO').AsString := FNumero;
      qry.ExecSQL;
      if qry.RowsAffected = 0 then
        raise Exception.Create(SErrorActualizarContadorLineasInventario);
      if bTransPropia and ConexionEscritura.InTransaction then
        ConexionEscritura.Commit;
      Result := Format('%.4d', [iNuevaLinea]);
    except
      if bTransPropia and ConexionEscritura.InTransaction then
        ConexionEscritura.Rollback;
      raise;
    end;
  finally
    FreeAndNil(qry);
  end;
end;

// FZ-ISSUE-423: la línea nace con la fecha y hora de la cabecera (se puede
// cambiar en cada línea, columna «Hora recuento»); nunca en el futuro.
function TdmInventarios.FechaRecuentoPorDefecto: TDateTime;
var
  CampoFecha: TField;
begin
  Result := Now;
  if (unqryTablaG <> nil) and unqryTablaG.Active and
     (not unqryTablaG.IsEmpty) then
  begin
    CampoFecha := unqryTablaG.FindField('FECHA_INV');
    if (CampoFecha <> nil) and (not CampoFecha.IsNull) and
       (CampoFecha.AsDateTime < Result) then
      Result := CampoFecha.AsDateTime;
  end;
end;

// FZ-ISSUE-423: las líneas que llevaban la fecha de la cabecera la siguen
// cuando esta cambia; las fechadas a mano se respetan.
procedure TdmInventarios.ArrastrarFechaCabeceraALineas(
  AAnterior, ANueva: TDateTime);
const
  TOLERANCIA = 1.5 / SecsPerDay;
var
  CampoFecha: TField;
  Marca: TBookmark;
begin
  if ANueva > Now then
    ANueva := Now;
  if cdsLineas.Active and (not cdsLineas.IsEmpty) and
     (Abs(AAnterior - ANueva) > TOLERANCIA) then
  begin
    CampoFecha := cdsLineas.FieldByName('FECHA_RECUENTO_INVLIN');
    Marca := cdsLineas.Bookmark;
    cdsLineas.DisableControls;
    try
      IniciarImportacionLineas;
      try
        cdsLineas.First;
        while not cdsLineas.Eof do
        begin
          if Abs(CampoFecha.AsDateTime - AAnterior) <= TOLERANCIA then
          begin
            cdsLineas.Edit;
            CampoFecha.AsDateTime := ANueva;
            cdsLineas.Post;
          end;
          cdsLineas.Next;
        end;
        ConfirmarImportacionLineas;
      except
        CancelarImportacionLineas;
        raise;
      end;
      if cdsLineas.BookmarkValid(Marca) then
        cdsLineas.Bookmark := Marca;
    finally
      cdsLineas.EnableControls;
    end;
  end;
end;

procedure TdmInventarios.AsegurarFechaRecuentoLinea;
var
  CampoFecha: TField;
begin
  CampoFecha := nil;
  if (cdsLineas <> nil) and cdsLineas.Active then
    CampoFecha := cdsLineas.FindField('FECHA_RECUENTO_INVLIN');
  if (CampoFecha <> nil) and CampoFecha.IsNull then
    CampoFecha.AsDateTime := FechaRecuentoPorDefecto;
end;

function TdmInventarios.GenerarSkuFinal(const AArticuloBase: string): string;
var
  i, NumAttr: Integer;
  ValorAttr: string;
begin
  // Construye el SKU concatenando ARTICULO/ATTR1/ATTR2/... con los valores
  // que haya rellenados en cdsLineas. Si algun valor falta, se omite (el SKU
  // queda incompleto, lo que el llamante interpreta para decidir si ya hay
  // que recalcular teoricas/PMP).
  Result := AArticuloBase;
  if cdsLineas.Active and
     (cdsLineas.FindField('NUM_ATRIBUTOS_REQ_INV_LINEA') <> nil) then
  begin
    NumAttr := cdsLineas.FieldByName(
      'NUM_ATRIBUTOS_REQ_INV_LINEA').AsInteger;
    for i := 1 to NumAttr do
    begin
      ValorAttr :=
        cdsLineas.FieldByName('ATTR' + IntToStr(i) + '_VALOR').AsString;
      if Trim(ValorAttr) <> '' then
        Result := Result + '/' + ValorAttr;
    end;
  end;
end;

procedure TdmInventarios.RellenarDatosArticulo(const ACodigoArticulo: string;
  out ADescripcion: string; out ANumAtributos: Integer;
  out ATipoArticulo: string);
var
  swTotal, swQry1, swQry2: TStopwatch;
  msArt, msDef: Int64;
begin
  ADescripcion  := '';
  ANumAtributos := 0;
  ATipoArticulo := 'ESTANDAR';
  msDef := 0;
  swTotal := TStopwatch.StartNew;

  swQry1 := TStopwatch.StartNew;
  unqryArticulo.Close;
  unqryArticulo.ParamByName('CODIGO').AsString := ACodigoArticulo;
  unqryArticulo.Open;
  msArt := swQry1.ElapsedMilliseconds;

  if not unqryArticulo.IsEmpty then
  begin
    ADescripcion  := unqryArticulo.FieldByName('DESCRIPCION_ART').AsString;
    ATipoArticulo := unqryArticulo.FieldByName('TIPO_ART').AsString;
    // Conteo de atributos del artículo padre
    swQry2 := TStopwatch.StartNew;
    unqryDefinicionArticulo.Close;
    unqryDefinicionArticulo.ParamByName('ARTICULO').AsString := ACodigoArticulo;
    unqryDefinicionArticulo.Open;
    ANumAtributos := unqryDefinicionArticulo.RecordCount;
    msDef := swQry2.ElapsedMilliseconds;
  end;

  RegistroLog.RegistrarRendimiento('RellenarDatosArticulo',
    Format('articulo=%s NumAtr=%d | unqryArticulo=%d ' +
           'unqryDefinicionArticulo=%d',
           [ACodigoArticulo, ANumAtributos, msArt, msDef]),
    swTotal.ElapsedMilliseconds);
end;

procedure TdmInventarios.RellenarDatosSku(const ASku: string;
  out ACantidadTeorica: Currency; out APMPActual: Currency);
var
  swTotal: TStopwatch;
begin
  ACantidadTeorica := 0;
  APMPActual       := 0;
  swTotal := TStopwatch.StartNew;

  unqryStockActual.Close;
  unqryStockActual.ParamByName('ALMACEN').AsString := FCodigoAlmacen;
  unqryStockActual.ParamByName('SKU').AsString     := ASku;
  unqryStockActual.Open;

  if not unqryStockActual.IsEmpty then
  begin
    ACantidadTeorica := unqryStockActual.FieldByName('CANTIDAD_STK').AsCurrency;
    APMPActual := unqryStockActual.FieldByName('PRECIO_MEDIO_STK').AsCurrency;
  end;

  RegistroLog.RegistrarRendimiento('RellenarDatosSku',
    Format('sku=%s almacen=%s teo=%.2f pmp=%.4f',
           [ASku, FCodigoAlmacen, ACantidadTeorica, APMPActual]),
    swTotal.ElapsedMilliseconds);
end;

procedure TdmInventarios.cdsLineasNewRecord(DataSet: TDataSet);
begin
  // Defaults al insertar una línea nueva.
  // Inicializamos a '' los campos NOT NULL del BD (CODIGO_ART_INVLIN,
  // CODIGO_UNIDAD_INVLIN) en vez de dejarlos NULL: asi al pulsar Grabar el
  // TClientDataSet.Post no falla con "Field value required" antes de que
  // cdsLineasBeforePost pueda dar un mensaje claro.
  DataSet.FieldByName('CODIGO_EMP_INVLIN').AsString := FCodigoEmpresa;
  DataSet.FieldByName('CODIGO_ALM_INVLIN').AsString := FCodigoAlmacen;
  DataSet.FieldByName('SERIE_INV_INVLIN').AsString  := FSerie;
  DataSet.FieldByName('NUMERO_INV_INVLIN').AsString := FNumero;
  DataSet.FieldByName('LINEA_INVLIN').AsString      := GenerarSiguienteLinea;
  AsegurarIdPivoteLineaInventario(DataSet);
  DataSet.FieldByName('CODIGO_ART_INVLIN').AsString    := '';
  DataSet.FieldByName('CODIGO_UNIDAD_INVLIN').AsString := '';
  DataSet.FieldByName('CANTIDAD_TEORICA_INVLIN').AsCurrency    := 0;
  DataSet.FieldByName('CANTIDAD_FISICA_INVLIN').AsCurrency     := 0;
  DataSet.FieldByName('CANTIDAD_DIFERENCIA_INVLIN').AsCurrency := 0;
  DataSet.FieldByName('PRECIO_MEDIO_INVLIN').AsCurrency        := 0;
  DataSet.FieldByName('PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency  := 0;
  DataSet.FieldByName(
    'ESPRECIO_MEDIO_CORREGIDO_INVLIN').AsString := 'N';
  DataSet.FieldByName('FECHA_RECUENTO_INVLIN').AsDateTime      :=
    FechaRecuentoPorDefecto;
  DataSet.FieldByName('NUM_ATRIBUTOS_REQ_INV_LINEA').AsInteger        := 0;
  DataSet.FieldByName('USUARIO_ALTA').AsString := FUsuario;
  DataSet.FieldByName('USUARIO_MODIF').AsString := FUsuario;
  // INSTANTE_ALTA / INSTANTE_MODIF son NOT NULL en BBDD con DEFAULT. El
  // TClientDataSet propaga Required=True por poIncFieldProps y, si los
  // dejamos NULL en el buffer, el Post de cdsLineas revienta con
  // "Field value required" antes incluso de llegar al provider. La BBDD
  // sobrescribira INSTANTE_MODIF en su ON UPDATE; aqui solo necesitamos
  // un valor inicial valido.
  DataSet.FieldByName('INSTANTE_ALTA').AsDateTime  := Now;
  DataSet.FieldByName('INSTANTE_MODIF').AsDateTime := Now;
end;

procedure TdmInventarios.cdsLineasCalcFields(DataSet: TDataSet);
var
  Estado: string;
  Diferencia: Currency;
begin
  // Midas llama con dsInternalCalc al leer cada registro: ahi se rellenan
  // los fkInternalCalc ATTR1..5/NUM a partir del SKU.
  if DataSet.State = dsInternalCalc then
  begin
    CalcularAtributosLinea(DataSet);
    DataSet.FieldByName('TIPO_CANTIDAD_INV_LINEA').AsString :=
      UnidadArticulo(DataSet.FieldByName('CODIGO_ART_INVLIN').AsString);
  end;
  // El cálculo de uds regularizadas: si el inventario está APLICADO,
  // entonces es la propia diferencia. Si está ABIERTO/CANCELADO es 0.
  Estado := GetEstadoInventario;
  Diferencia := DataSet.FieldByName('CANTIDAD_DIFERENCIA_INVLIN').AsCurrency;

  if Estado = 'APLICADO' then
    DataSet.FieldByName('UDS_REGULARIZADAS').AsCurrency := Diferencia
  else
    DataSet.FieldByName('UDS_REGULARIZADAS').AsCurrency := 0;
end;

destructor TdmInventarios.Destroy;
begin
  FreeAndNil(FUnidadesArticulo);
  inherited;
end;

procedure TdmInventarios.CargarUnidadesArticulosInventario;
var
  q: TUniQuery;
begin
  if FUnidadesArticulo = nil then
    FUnidadesArticulo := TDictionary<string, string>.Create;
  FUnidadesArticulo.Clear;
  q := TUniQuery.Create(nil);
  try
    q.Connection := unqryLineas.Connection;
    q.SQL.Text :=
      'SELECT DISTINCT A.CODIGO_ART_ART, A.TIPO_CANTIDAD_ART ' +
      '  FROM fza_inventarios_lineas L ' +
      '  JOIN fza_articulos A ON A.CODIGO_ART_ART = L.CODIGO_ART_INVLIN ' +
      ' WHERE L.CODIGO_EMP_INVLIN = :EMPRESA ' +
      '   AND L.CODIGO_ALM_INVLIN = :ALMACEN ' +
      '   AND L.SERIE_INV_INVLIN  = :SERIE ' +
      '   AND L.NUMERO_INV_INVLIN = :NUMERO';
    q.ParamByName('EMPRESA').AsString := FCodigoEmpresa;
    q.ParamByName('ALMACEN').AsString := FCodigoAlmacen;
    q.ParamByName('SERIE').AsString := FSerie;
    q.ParamByName('NUMERO').AsString := FNumero;
    q.Open;
    while not q.Eof do
    begin
      FUnidadesArticulo.AddOrSetValue(
        UpperCase(q.FieldByName('CODIGO_ART_ART').AsString),
        q.FieldByName('TIPO_CANTIDAD_ART').AsString);
      q.Next;
    end;
  finally
    q.Free;
  end;
end;

// FZ-ISSUE-244: la unidad de una linea nueva o con el articulo cambiado
// hace falta antes del Post (la rejilla valida y formatea el recuento con
// ella); cdsLineasCalcFields solo la pone al leer el registro.
procedure TdmInventarios.CodigoArticuloLineaChange(Sender: TField);
begin
  if Sender.DataSet.State in [dsInsert, dsEdit] then
    Sender.DataSet.FieldByName('TIPO_CANTIDAD_INV_LINEA').AsString :=
      UnidadArticulo(Sender.AsString);
end;

// Articulo que no estaba al abrir (linea nueva): una consulta y a la cache.
function TdmInventarios.UnidadArticulo(
  const ACodigoArticulo: string): string;
var
  q: TUniQuery;
  sClave: string;
begin
  Result := '';
  sClave := UpperCase(Trim(ACodigoArticulo));
  if sClave <> '' then
  begin
    if FUnidadesArticulo = nil then
      FUnidadesArticulo := TDictionary<string, string>.Create;
    if not FUnidadesArticulo.TryGetValue(sClave, Result) then
    begin
      q := TUniQuery.Create(nil);
      try
        q.Connection := unqryLineas.Connection;
        q.SQL.Text :=
          'SELECT TIPO_CANTIDAD_ART FROM fza_articulos ' +
          ' WHERE CODIGO_ART_ART = :ART';
        q.ParamByName('ART').AsString := Trim(ACodigoArticulo);
        q.Open;
        if not q.IsEmpty then
          Result := q.FieldByName('TIPO_CANTIDAD_ART').AsString;
      finally
        q.Free;
      end;
      FUnidadesArticulo.AddOrSetValue(sClave, Result);
    end;
  end;
end;

procedure TdmInventarios.DesactivarRequeridosLinea(ADataSet: TDataSet);
var
  iCampo: Integer;
begin
  for iCampo := 0 to ADataSet.FieldCount - 1 do
    ADataSet.Fields[iCampo].Required := False;
end;

function TdmInventarios.ConstruirSnapshotLinea(
  ADataSet: TDataSet): string;
var
  oCampo: TField;
  iCampo: Integer;
begin
  Result := '';
  for iCampo := 0 to ADataSet.FieldCount - 1 do
  begin
    oCampo := ADataSet.Fields[iCampo];
    if Result <> '' then
      Result := Result + ' | ';
    if oCampo.IsNull then
      Result := Result + oCampo.FieldName + '=<NULL>' +
        IfThen(oCampo.Required, '(REQ)', '')
    else
      Result := Result + oCampo.FieldName + '=' + oCampo.AsString +
        IfThen(oCampo.Required, '(REQ)', '');
  end;
end;

procedure TdmInventarios.RegistrarSnapshotLinea(ADataSet: TDataSet);
begin
  RegistroLog.RegistrarInformacion('[cdsLineasBeforePost] state=' +
    IntToStr(Ord(ADataSet.State)) + ' | ' +
    ConstruirSnapshotLinea(ADataSet));
end;

procedure TdmInventarios.ValidarClavesLinea(ADataSet: TDataSet);
begin
  if Trim(ADataSet.FieldByName('CODIGO_EMP_INVLIN').AsString) = '' then
    raise Exception.Create(SErrorEmpresaCabeceraInventarioObligatoria);
  if Trim(ADataSet.FieldByName('CODIGO_ALM_INVLIN').AsString) = '' then
    raise Exception.Create(SErrorAlmacenCabeceraInventarioObligatorio);
  if Trim(ADataSet.FieldByName('SERIE_INV_INVLIN').AsString) = '' then
    raise Exception.Create(SErrorSerieCabeceraInventarioObligatoria);
  if Trim(ADataSet.FieldByName('NUMERO_INV_INVLIN').AsString) = '' then
    raise Exception.Create(SErrorNumeroCabeceraInventarioObligatorio);
end;

procedure TdmInventarios.DescartarLineaSinArticulo(ADataSet: TDataSet);
begin
  if Trim(ADataSet.FieldByName('CODIGO_ART_INVLIN').AsString) = '' then
  begin
    TThread.ForceQueue(nil,
      procedure
      begin
        if cdsLineas.Active and
           (cdsLineas.State in [dsEdit, dsInsert]) then
          cdsLineas.Cancel;
      end);
    Abort;
  end;
end;

procedure TdmInventarios.CompletarUnidadLinea(ADataSet: TDataSet);
begin
  if Trim(ADataSet.FieldByName('CODIGO_UNIDAD_INVLIN').AsString) = '' then
    ADataSet.FieldByName('CODIGO_UNIDAD_INVLIN').AsString :=
      ADataSet.FieldByName('CODIGO_ART_INVLIN').AsString;
end;

function TdmInventarios.RequiereValidarSkuLinea(
  ADataSet: TDataSet): Boolean;
begin
  Result := (not FModoPivoteActivo) and
    ((ADataSet.FindField('ID_AC_PIVOT_INVLIN') = nil) or
     (ADataSet.FieldByName('ID_AC_PIVOT_INVLIN').AsInteger <= 0));
end;

procedure TdmInventarios.ReconstruirSkuLinea(
  ADataSet: TDataSet;
  const ACodigoArticulo: string);
var
  sSku: string;
  sValor: string;
  iAtributo: Integer;
  iNumeroAtributos: Integer;
begin
  iNumeroAtributos := ADataSet.FieldByName(
    'NUM_ATRIBUTOS_REQ_INV_LINEA').AsInteger;
  if iNumeroAtributos > 0 then
  begin
    sSku := ACodigoArticulo;
    for iAtributo := 1 to iNumeroAtributos do
    begin
      sValor := Trim(ADataSet.FieldByName('ATTR' +
        IntToStr(iAtributo) + '_VALOR').AsString);
      if sValor = '' then
        raise Exception.CreateFmt(SErrorAtributoLineaInventarioObligatorio,
          [ADataSet.FieldByName('LINEA_INVLIN').AsString,
           ACodigoArticulo, iNumeroAtributos, iAtributo]);
      sSku := sSku + '/' + sValor;
    end;
    if ADataSet.FieldByName('CODIGO_UNIDAD_INVLIN').AsString <> sSku then
      ADataSet.FieldByName('CODIGO_UNIDAD_INVLIN').AsString := sSku;
  end;
end;

procedure TdmInventarios.ValidarOCrearSkuLinea(
  ADataSet: TDataSet;
  const ACodigoArticulo: string);
var
  Atributos: array[0..4] of string;
  sSku: string;
  iAtributo: Integer;
begin
  sSku := ADataSet.FieldByName('CODIGO_UNIDAD_INVLIN').AsString;
  if (sSku <> ACodigoArticulo) and (not SkuExiste(sSku)) then
  begin
    if not SolicitarConfirmacion(
      Format(SPreguntaCrearSkuInventario, [sSku])) then
      raise Exception.CreateFmt(SErrorSkuInventarioNoExiste, [sSku]);
    for iAtributo := 0 to 4 do
      Atributos[iAtributo] := ADataSet.FieldByName('ATTR' +
        IntToStr(iAtributo + 1) + '_VALOR').AsString;
    CrearSkuDesdeLinea(ACodigoArticulo, sSku, Atributos);
  end;
end;

procedure TdmInventarios.cdsLineasBeforePost(DataSet: TDataSet);
var
  sCodigoArticulo: string;
begin
  DesactivarRequeridosLinea(DataSet);
  AsegurarIdPivoteLineaInventario(DataSet);
  RegistrarSnapshotLinea(DataSet);
  AsegurarFechaRecuentoLinea;
  // FZ-ISSUE-423: la hora de recuento es editable; no admite el futuro.
  if DataSet.FieldByName('FECHA_RECUENTO_INVLIN').AsDateTime >
     Now + EncodeTime(0, 5, 0, 0) then
    raise Exception.Create(SErrorFechaHoraRecuentoInventarioNoIndicada);
  ValidarClavesLinea(DataSet);
  DescartarLineaSinArticulo(DataSet);
  CompletarUnidadLinea(DataSet);
  sCodigoArticulo := DataSet.FieldByName(
    'CODIGO_ART_INVLIN').AsString;
  if RequiereValidarSkuLinea(DataSet) then
  begin
    ReconstruirSkuLinea(DataSet, sCodigoArticulo);
    ValidarOCrearSkuLinea(DataSet, sCodigoArticulo);
  end;
end;
procedure TdmInventarios.cdsLineasAfterPost(DataSet: TDataSet);
begin
  FLineaEnEdicion := False;
  if not FAplicacionLineasDiferida then
  begin
    if cdsLineas.ChangeCount > 0 then
      AplicarLineasPendientes;
  end;
end;

procedure TdmInventarios.cdsLineasBeforeDelete(DataSet: TDataSet);
begin
  if GetEstadoInventario <> 'ABIERTO' then
    raise Exception.Create(SErrorEliminarLineasInventarioNoAbierto);
end;

procedure TdmInventarios.cdsLineasBeforeInsert(DataSet: TDataSet);
begin
  // Si la linea actual es un placeholder sin articulo (p.ej. el usuario
  // pulso Insert pero no relleno nada), cancelar antes de que
  // CheckBrowseMode intente Post (que fallaria en BeforePost con
  // 'No se puede grabar una linea sin articulo').
  if DataSet.State in [dsEdit, dsInsert] then
  begin
    if Trim(DataSet.FieldByName('CODIGO_ART_INVLIN').AsString) = '' then
      DataSet.Cancel;
  end;
  // Exigimos que la cabecera tenga un NUMERO_INV definitivo. Si sigue
  // en dsInsert con NUMERO_INV='0' (marcador), cdsLineasNewRecord
  // copiaria ese '0' y la linea quedaria huerfana.
  if (unqryTablaG <> nil) and unqryTablaG.Active then
  begin
    if unqryTablaG.State in [dsInsert, dsEdit] then
    begin
      try
        unqryTablaG.Post;
      except
        on E: Exception do
        begin
          raise Exception.Create(Format(
            SErrorAnadirLineaCabeceraInventario, [E.Message]));
        end;
      end;
      SetClavesActivas(
        unqryTablaG.FieldByName('CODIGO_EMP_INV').AsString,
        unqryTablaG.FieldByName('CODIGO_ALM_INV').AsString,
        unqryTablaG.FieldByName('SERIE_INV').AsString,
        unqryTablaG.FieldByName('NUMERO_INV').AsString
      );
    end;
  end;
  // El form reasigna AfterInsert (cdsLineasAfterInsertHook): el estado de
  // edicion de la linea nueva se marca aqui, ya cancelado el placeholder.
  FLineaEnEdicion := True;
end;

procedure TdmInventarios.cdsLineasAfterDelete(DataSet: TDataSet);
begin
  // Persistir la eliminacion en BBDD (mismo patron que AfterPost).
  if cdsLineas.ChangeCount > 0 then
    AplicarLineasPendientes;
end;

procedure TdmInventarios.cdsLineasAfterApplyUpdates(Sender: TObject;
  var OwnerData: OleVariant);
begin
  // Punto comun de todas las grabaciones de lineas (AfterPost, borrado,
  // importaciones y cargas masivas). Dentro de la transaccion de una
  // importacion el UPDATE va en ella y se deshace con ella.
  ActualizarTotalesCabecera;
  RefrescarTotalesCabeceraActiva;
end;

procedure TdmInventarios.ActualizarTotalesCabecera;
var
  qry: TUniQuery;
begin
  // Mismo calculo que PRC_FZA_INVENTARIOS_ACTUALIZAR_TEORICO y _APLICAR.
  if (Trim(FNumero) <> '') and (FNumero <> '0') then
  begin
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := ConexionEscritura;
      qry.SQL.Text :=
        'UPDATE fza_inventarios i' + sLineBreak +
        '   SET i.TOTAL_UNIDADES_DIFERENCIA_INV = (' + sLineBreak +
        '         SELECT IFNULL(SUM(l.CANTIDAD_DIFERENCIA_INVLIN), 0)' +
        sLineBreak +
        '           FROM fza_inventarios_lineas l' + sLineBreak +
        '          WHERE l.CODIGO_EMP_INVLIN = i.CODIGO_EMP_INV' +
        sLineBreak +
        '            AND l.CODIGO_ALM_INVLIN = i.CODIGO_ALM_INV' +
        sLineBreak +
        '            AND l.SERIE_INV_INVLIN  = i.SERIE_INV' + sLineBreak +
        '            AND l.NUMERO_INV_INVLIN = i.NUMERO_INV),' +
        sLineBreak +
        '       i.TOTAL_EUROS_DIFERENCIA_INV = (' + sLineBreak +
        '         SELECT IFNULL(SUM(l.TOTAL_COSTE_DIFERENCIA_INVLIN), 0)' +
        sLineBreak +
        '           FROM fza_inventarios_lineas l' + sLineBreak +
        '          WHERE l.CODIGO_EMP_INVLIN = i.CODIGO_EMP_INV' +
        sLineBreak +
        '            AND l.CODIGO_ALM_INVLIN = i.CODIGO_ALM_INV' +
        sLineBreak +
        '            AND l.SERIE_INV_INVLIN  = i.SERIE_INV' + sLineBreak +
        '            AND l.NUMERO_INV_INVLIN = i.NUMERO_INV)' +
        sLineBreak +
        ' WHERE i.CODIGO_EMP_INV = :EMPRESA' + sLineBreak +
        '   AND i.CODIGO_ALM_INV = :ALMACEN' + sLineBreak +
        '   AND i.SERIE_INV      = :SERIE' + sLineBreak +
        '   AND i.NUMERO_INV     = :NUMERO';
      qry.ParamByName('EMPRESA').AsString := FCodigoEmpresa;
      qry.ParamByName('ALMACEN').AsString := FCodigoAlmacen;
      qry.ParamByName('SERIE').AsString := FSerie;
      qry.ParamByName('NUMERO').AsString := FNumero;
      qry.Execute;
    finally
      FreeAndNil(qry);
    end;
  end;
end;

procedure TdmInventarios.RefrescarTotalesCabeceraActiva;
begin
  // Solo si la cabecera visible es la de las lineas y no se esta editando:
  // en edicion, el UPDATE de UniDAC no lleva los totales (no modificados)
  // y la siguiente relectura ya los trae bien.
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) and
     (unqryTablaG.State = dsBrowse) and
     (unqryTablaG.FieldByName('CODIGO_EMP_INV').AsString =
       FCodigoEmpresa) and
     (unqryTablaG.FieldByName('CODIGO_ALM_INV').AsString =
       FCodigoAlmacen) and
     (unqryTablaG.FieldByName('SERIE_INV').AsString = FSerie) and
     (unqryTablaG.FieldByName('NUMERO_INV').AsString = FNumero) then
  begin
    FRefrescandoTotalesCabecera := True;
    try
      unqryTablaG.RefreshRecord;
    finally
      FRefrescandoTotalesCabecera := False;
    end;
  end;
end;

function TdmInventarios.GetEstadoInventario: string;
begin
  Result := '';
  if unqryTablaG.Active and not unqryTablaG.IsEmpty then
    Result := unqryTablaG.FieldByName('ESTADO_INV').AsString;
end;

function LineaCoincideConSimulacion(
  ADataSet: TDataSet;
  const ALinea: TLineaBaseRevalorizacionInventario): Boolean;
begin
  Result :=
    (ADataSet.FieldByName('CODIGO_ART_INVLIN').AsString =
      ALinea.CodigoArticulo) and
    (ADataSet.FieldByName('CODIGO_UNIDAD_INVLIN').AsString =
      ALinea.CodigoUnidad) and
    (ADataSet.FieldByName('CANTIDAD_TEORICA_INVLIN').AsCurrency =
      ALinea.CantidadTeorica) and
    (ADataSet.FieldByName('CANTIDAD_FISICA_INVLIN').AsCurrency =
      ALinea.CantidadFisica) and
    (ADataSet.FieldByName('PRECIO_MEDIO_INVLIN').AsCurrency =
      ALinea.PrecioMedioActual) and
    (ADataSet.FieldByName('PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency =
      ALinea.PrecioMedioNuevoAnterior) and
    (SameText(
      ADataSet.FieldByName(
        'ESPRECIO_MEDIO_CORREGIDO_INVLIN').AsString,
      'S') = ALinea.EsPrecioMedioCorregido);
end;

procedure IndexarLineasRevalorizacion(
  const ASimulacion: TSimulacionRevalorizacionInventario;
  AIndice: TDictionary<string, Integer>);
var
  iLinea: Integer;
  NumeroLinea: string;
begin
  for iLinea := 0 to High(ASimulacion.Lineas) do
  begin
    NumeroLinea := ASimulacion.Lineas[iLinea].Base.Linea;
    if AIndice.ContainsKey(NumeroLinea) then
      raise Exception.CreateFmt(
        SErrorDatosRevalorizacionInventarioCambiados,
        [NumeroLinea]);
    AIndice.Add(NumeroLinea, iLinea);
  end;
end;

procedure ValidarLineasRevalorizacion(
  ADataSet: TDataSet;
  const ASimulacion: TSimulacionRevalorizacionInventario;
  AIndice: TDictionary<string, Integer>);
var
  Encontradas: TArray<Boolean>;
  iLinea: Integer;
  NumeroLinea: string;
begin
  SetLength(Encontradas, Length(ASimulacion.Lineas));
  ADataSet.First;
  while not ADataSet.Eof do
  begin
    NumeroLinea := ADataSet.FieldByName('LINEA_INVLIN').AsString;
    if AIndice.TryGetValue(NumeroLinea, iLinea) then
    begin
      if not LineaCoincideConSimulacion(
           ADataSet,
           ASimulacion.Lineas[iLinea].Base) then
        raise Exception.CreateFmt(
          SErrorDatosRevalorizacionInventarioCambiados,
          [NumeroLinea]);
      Encontradas[iLinea] := True;
    end;
    ADataSet.Next;
  end;
  for iLinea := 0 to High(ASimulacion.Lineas) do
  begin
    if not Encontradas[iLinea] then
      raise Exception.CreateFmt(
        SErrorLineaRevalorizacionInventarioNoEncontrada,
        [ASimulacion.Lineas[iLinea].Base.Linea]);
  end;
end;

procedure GrabarLineasRevalorizacion(
  ADataSet: TDataSet;
  const ASimulacion: TSimulacionRevalorizacionInventario;
  AIndice: TDictionary<string, Integer>;
  const AUsuario: string);
var
  iLinea: Integer;
begin
  ADataSet.First;
  while not ADataSet.Eof do
  begin
    if AIndice.TryGetValue(
         ADataSet.FieldByName('LINEA_INVLIN').AsString,
         iLinea) then
    begin
      ADataSet.Edit;
      ADataSet.FieldByName(
        'PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency :=
        ASimulacion.Lineas[iLinea].PrecioMedioNuevo;
      ADataSet.FieldByName(
        'ESPRECIO_MEDIO_CORREGIDO_INVLIN').AsString := 'S';
      ADataSet.FieldByName(
        'TOTAL_COSTE_DIFERENCIA_INVLIN').AsCurrency :=
        ASimulacion.Lineas[iLinea].DiferenciaValor;
      ADataSet.FieldByName('USUARIO_MODIF').AsString := AUsuario;
      ADataSet.Post;
    end;
    ADataSet.Next;
  end;
end;

procedure TdmInventarios.BloquearInventarioParaRevalorizacion;
var
  oConsulta: TUniQuery;
  sEstado: string;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := ConexionEscritura;
    oConsulta.SQL.Text :=
      'SELECT ESTADO_INV ' +
      '  FROM fza_inventarios ' +
      ' WHERE CODIGO_EMP_INV = :EMPRESA ' +
      '   AND CODIGO_ALM_INV = :ALMACEN ' +
      '   AND SERIE_INV = :SERIE ' +
      '   AND NUMERO_INV = :NUMERO ' +
      ' FOR UPDATE';
    oConsulta.ParamByName('EMPRESA').AsString := FCodigoEmpresa;
    oConsulta.ParamByName('ALMACEN').AsString := FCodigoAlmacen;
    oConsulta.ParamByName('SERIE').AsString := FSerie;
    oConsulta.ParamByName('NUMERO').AsString := FNumero;
    oConsulta.Open;
    if oConsulta.IsEmpty then
      raise Exception.Create(SErrorInventarioNoAbiertoEditar);
    sEstado := oConsulta.FieldByName('ESTADO_INV').AsString;
    if sEstado <> 'ABIERTO' then
      raise Exception.Create(SErrorInventarioNoAbiertoEditar);

    oConsulta.Close;
    oConsulta.SQL.Text :=
      'SELECT LINEA_INVLIN ' +
      '  FROM fza_inventarios_lineas ' +
      ' WHERE CODIGO_EMP_INVLIN = :EMPRESA ' +
      '   AND CODIGO_ALM_INVLIN = :ALMACEN ' +
      '   AND SERIE_INV_INVLIN = :SERIE ' +
      '   AND NUMERO_INV_INVLIN = :NUMERO ' +
      ' FOR UPDATE';
    oConsulta.ParamByName('EMPRESA').AsString := FCodigoEmpresa;
    oConsulta.ParamByName('ALMACEN').AsString := FCodigoAlmacen;
    oConsulta.ParamByName('SERIE').AsString := FSerie;
    oConsulta.ParamByName('NUMERO').AsString := FNumero;
    oConsulta.Open;
    while not oConsulta.Eof do
      oConsulta.Next;
  finally
    FreeAndNil(oConsulta);
  end;
end;

// Última compra por SKU (y por artículo como respaldo) de las líneas
// guardadas del inventario: coste del SKU y, si no consta, el del proveedor
// principal. Las claves son 'S:' + SKU y 'A:' + artículo.
// El último precio de compra se guarda sin impuestos (FZ-ISSUE-381): para
// valorar el stock de una empresa en recargo se le suman el IVA y el
// recargo, que no deduce, igual que hace su PMP.
function CargarUltimasComprasInventario(
  AConexion: TUniConnection;
  const AEmpresa, AAlmacen, ASerie, ANumero: string):
  TDictionary<string, Currency>;
const
  SQL_FACTOR_COSTE_INVENTARIO =
    SQL_FACTOR_COSTE_COMPRA_EMPRESA_INI + 'L.CODIGO_ART_INVLIN' +
    SQL_FACTOR_COSTE_COMPRA_EMPRESA_MED + 'L.CODIGO_EMP_INVLIN' +
    SQL_FACTOR_COSTE_COMPRA_EMPRESA_FIN;
var
  oConsulta: TUniQuery;
begin
  Result := TDictionary<string, Currency>.Create;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'SELECT DISTINCT L.CODIGO_UNIDAD_INVLIN AS SKU, ' +
      '       L.CODIGO_ART_INVLIN AS ARTICULO, ' +
      '       (SELECT C.PRECIO_ULT_COMPRA_SKUC ' +
      '          FROM fza_articulos_skus_costes C ' +
      '         WHERE C.CODIGO_UNIDAD_SKU_SKUC = L.CODIGO_UNIDAD_INVLIN) ' +
      '         * ' + SQL_FACTOR_COSTE_INVENTARIO +
      '         AS ULTIMA_COMPRA_SKU, ' +
      '       (SELECT MAX(AP.PRECIO_ULT_COMPRA_AP) ' +
      '          FROM fza_articulos_proveedores AP ' +
      '         WHERE AP.CODIGO_ART_AP = L.CODIGO_ART_INVLIN ' +
      '           AND AP.ESPROVEEDORPRINCIPAL_AP = ''S'') ' +
      '         * ' + SQL_FACTOR_COSTE_INVENTARIO +
      '         AS ULTIMA_COMPRA_ARTICULO ' +
      '  FROM fza_inventarios_lineas L ' +
      ' WHERE L.CODIGO_EMP_INVLIN = :EMPRESA ' +
      '   AND L.CODIGO_ALM_INVLIN = :ALMACEN ' +
      '   AND L.SERIE_INV_INVLIN = :SERIE ' +
      '   AND L.NUMERO_INV_INVLIN = :NUMERO';
    oConsulta.ParamByName('EMPRESA').AsString := AEmpresa;
    oConsulta.ParamByName('ALMACEN').AsString := AAlmacen;
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      if not oConsulta.FieldByName('ULTIMA_COMPRA_SKU').IsNull then
        Result.AddOrSetValue(
          'S:' + oConsulta.FieldByName('SKU').AsString,
          oConsulta.FieldByName('ULTIMA_COMPRA_SKU').AsCurrency);
      if not oConsulta.FieldByName('ULTIMA_COMPRA_ARTICULO').IsNull then
        Result.AddOrSetValue(
          'A:' + oConsulta.FieldByName('ARTICULO').AsString,
          oConsulta.FieldByName('ULTIMA_COMPRA_ARTICULO').AsCurrency);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function UltimaCompraLinea(
  AUltimasCompras: TDictionary<string, Currency>;
  const ASku, AArticulo: string): Currency;
begin
  if not AUltimasCompras.TryGetValue('S:' + ASku, Result) then
    if not AUltimasCompras.TryGetValue('A:' + AArticulo, Result) then
      Result := 0;
end;

function TdmInventarios.PrepararLineasRevalorizacion:
  TLineasBaseRevalorizacionInventario;
var
  iLinea: Integer;
  Marcador: TBookmark;
  UltimasCompras: TDictionary<string, Currency>;
begin
  SetLength(Result, 0);
  if GetEstadoInventario <> 'ABIERTO' then
    raise Exception.Create(SErrorInventarioNoAbiertoEditar);
  if not cdsLineas.Active then
    raise Exception.Create(SErrorLineasInventarioNoAbiertas);
  if cdsLineas.IsEmpty then
    raise Exception.Create(SErrorLineasInventarioNoAbiertas);

  UltimasCompras := CargarUltimasComprasInventario(
    ConexionEscritura, FCodigoEmpresa, FCodigoAlmacen, FSerie, FNumero);
  Marcador := cdsLineas.GetBookmark;
  cdsLineas.DisableControls;
  try
    SetLength(Result, cdsLineas.RecordCount);
    iLinea := 0;
    cdsLineas.First;
    while not cdsLineas.Eof do
    begin
      Result[iLinea].Linea :=
        cdsLineas.FieldByName('LINEA_INVLIN').AsString;
      Result[iLinea].Clave := Result[iLinea].Linea;
      Result[iLinea].PrecioUltimaCompra := UltimaCompraLinea(
        UltimasCompras,
        cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString,
        cdsLineas.FieldByName('CODIGO_ART_INVLIN').AsString);
      Result[iLinea].CodigoArticulo :=
        cdsLineas.FieldByName('CODIGO_ART_INVLIN').AsString;
      Result[iLinea].CodigoUnidad :=
        cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString;
      Result[iLinea].Descripcion :=
        cdsLineas.FieldByName('DESCRIPCION_ARTICULO_INVLIN').AsString;
      Result[iLinea].CantidadTeorica :=
        cdsLineas.FieldByName('CANTIDAD_TEORICA_INVLIN').AsCurrency;
      Result[iLinea].CantidadFisica :=
        cdsLineas.FieldByName('CANTIDAD_FISICA_INVLIN').AsCurrency;
      Result[iLinea].PrecioMedioActual :=
        cdsLineas.FieldByName('PRECIO_MEDIO_INVLIN').AsCurrency;
      Result[iLinea].PrecioMedioNuevoAnterior :=
        cdsLineas.FieldByName(
          'PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency;
      Result[iLinea].EsPrecioMedioCorregido := SameText(
        cdsLineas.FieldByName(
          'ESPRECIO_MEDIO_CORREGIDO_INVLIN').AsString,
        'S');
      Inc(iLinea);
      cdsLineas.Next;
    end;
    SetLength(Result, iLinea);
  finally
    if cdsLineas.BookmarkValid(Marcador) then
      cdsLineas.GotoBookmark(Marcador);
    cdsLineas.FreeBookmark(Marcador);
    cdsLineas.EnableControls;
    FreeAndNil(UltimasCompras);
  end;
end;

procedure TdmInventarios.AplicarRevalorizacion(
  const ASimulacion: TSimulacionRevalorizacionInventario);
var
  AplicacionIniciada: Boolean;
  IndiceLineas: TDictionary<string, Integer>;
  Marcador: TBookmark;
begin
  if unqryTablaG.Active and not unqryTablaG.IsEmpty then
    unqryTablaG.Refresh;
  if GetEstadoInventario <> 'ABIERTO' then
    raise Exception.Create(SErrorInventarioNoAbiertoEditar);
  if Length(ASimulacion.Lineas) = 0 then
    raise Exception.Create(SErrorSeleccionRevalorizacionInventario);

  // Repetir el refresco cierra la ventana de cambios mientras estuvo abierto
  // el modal. Si varió el Kardex, la comparación posterior pide simular otra
  // vez en lugar de aplicar un objetivo calculado con una base obsoleta.
  RecalcularTeorico;
  IndiceLineas := TDictionary<string, Integer>.Create;
  try
    IndexarLineasRevalorizacion(ASimulacion, IndiceLineas);
    AplicacionIniciada := False;
    try
      IniciarImportacionLineas;
      AplicacionIniciada := True;
      BloquearInventarioParaRevalorizacion;
      CargarLineasInventario;
      if (not cdsLineas.Active) or cdsLineas.IsEmpty then
        raise Exception.CreateFmt(
          SErrorLineaRevalorizacionInventarioNoEncontrada,
          [ASimulacion.Lineas[0].Base.Linea]);
      Marcador := cdsLineas.GetBookmark;
      cdsLineas.DisableControls;
      try
        ValidarLineasRevalorizacion(
          cdsLineas, ASimulacion, IndiceLineas);
        GrabarLineasRevalorizacion(
          cdsLineas, ASimulacion, IndiceLineas, FUsuario);
        ConfirmarImportacionLineas;
        AplicacionIniciada := False;
      finally
        if cdsLineas.BookmarkValid(Marcador) then
          cdsLineas.GotoBookmark(Marcador);
        cdsLineas.FreeBookmark(Marcador);
        cdsLineas.EnableControls;
      end;
    except
      if AplicacionIniciada then
        CancelarImportacionLineas;
      raise;
    end;
  finally
    FreeAndNil(IndiceLineas);
  end;
end;

procedure TdmInventarios.GrabarLineasPendientes;
begin
  // Una linea recien insertada sin articulo o sin unidad se cancela: su
  // Post daria "Field value required".
  if cdsLineas.Active then
  begin
    if cdsLineas.State in [dsInsert, dsEdit] then
    begin
      if (Trim(cdsLineas.FieldByName('CODIGO_ART_INVLIN').AsString) = '') and
         (Trim(cdsLineas.FieldByName(
           'CODIGO_UNIDAD_INVLIN').AsString) = '') then
        cdsLineas.Cancel
      else
        cdsLineas.Post;
    end;
    if cdsLineas.ChangeCount > 0 then
      AplicarLineasPendientes;
  end;
end;

procedure TdmInventarios.AplicarCambiosDiferidos;
begin
  inherited;
  GrabarLineasPendientes;
end;

procedure TdmInventarios.EjecutarSPActualizarTeorico;
begin
  unspActualizarTeorico.Close;
  unspActualizarTeorico.ParamByName('p_EMPRESA').AsString := FCodigoEmpresa;
  unspActualizarTeorico.ParamByName('p_ALMACEN').AsString := FCodigoAlmacen;
  unspActualizarTeorico.ParamByName('p_SERIE').AsString   := FSerie;
  unspActualizarTeorico.ParamByName('p_NRO').AsString     := FNumero;
  unspActualizarTeorico.ParamByName('p_USUARIO').AsString := FUsuario;
  unspActualizarTeorico.ExecProc;
end;

// FZ-ISSUE-619: el SP toma como PMP el del último movimiento del SKU en el
// almacén del inventario; sin movimientos es 0 y un sobrante entraba a
// coste 0, bajando el valor del stock. A esas líneas (física > teórica, sin
// PMP en el almacén ni PMP nuevo indicado) se les propone el coste conocido
// del SKU, por este orden: PMP de la empresa (media de sus almacenes, como
// la valoración de traspasos), última compra (la del SKU o, si no consta,
// la del proveedor principal, con el factor de recargo de la empresa) y
// precio de coste de la tarifa del artículo. Se graba como PMP corregido
// para que el SP lo respete al recalcular y al regularizar; el usuario
// puede cambiarlo en «PMP nuevo». Las líneas deben estar ya recalculadas.
function TdmInventarios.ProponerCosteSobrantesSinPmp: Integer;
const
  SQL_FACTOR_COSTE_LINEA =
    SQL_FACTOR_COSTE_COMPRA_EMPRESA_INI + 'L.CODIGO_ART_INVLIN' +
    SQL_FACTOR_COSTE_COMPRA_EMPRESA_MED + 'L.CODIGO_EMP_INVLIN' +
    SQL_FACTOR_COSTE_COMPRA_EMPRESA_FIN;
  SQL_SOBRANTES_SIN_PMP =
    'SELECT L.LINEA_INVLIN, L.CODIGO_ART_INVLIN, ' +
    '       L.CODIGO_UNIDAD_INVLIN, ' +
    '       COALESCE((SELECT CASE ' +
    '         WHEN SUM(CASE WHEN S.CANTIDAD_STK > 0 ' +
    '                  THEN S.CANTIDAD_STK ELSE 0 END) > 0 ' +
    '         THEN SUM(CASE WHEN S.CANTIDAD_STK > 0 ' +
    '                  THEN S.PRECIO_MEDIO_STK * S.CANTIDAD_STK ' +
    '                  ELSE 0 END) / ' +
    '              SUM(CASE WHEN S.CANTIDAD_STK > 0 ' +
    '                  THEN S.CANTIDAD_STK ELSE 0 END) ' +
    '         ELSE MAX(S.PRECIO_MEDIO_STK) END ' +
    '          FROM fza_articulos_stockactual S ' +
    '          JOIN fza_almacenes AL ' +
    '            ON AL.CODIGO_ALM_ALM = S.CODIGO_ALM_STK ' +
    '         WHERE AL.CODIGO_EMP_ALM = L.CODIGO_EMP_INVLIN ' +
    '           AND S.CODIGO_UNIDAD_STK = L.CODIGO_UNIDAD_INVLIN), 0) ' +
    '         AS PMP_EMPRESA, ' +
    '       COALESCE((SELECT T.PRECIO_COSTE_ARTTAR ' +
    '          FROM fza_articulos_tarifas T ' +
    '         WHERE T.CODIGO_ART_ARTTAR = L.CODIGO_ART_INVLIN ' +
    '           AND (T.CODIGO_UNIDAD_ARTTAR = L.CODIGO_UNIDAD_INVLIN ' +
    '                OR IFNULL(T.CODIGO_UNIDAD_ARTTAR, '''') = '''') ' +
    '           AND T.ESACTIVO_ARTTAR = ''S'' ' +
    '           AND IFNULL(T.PRECIO_COSTE_ARTTAR, 0) > 0 ' +
    '           AND (T.FECHA_HASTA_ARTTAR IS NULL ' +
    '                OR T.FECHA_HASTA_ARTTAR >= CURRENT_DATE) ' +
    '         ORDER BY CASE WHEN T.CODIGO_UNIDAD_ARTTAR = ' +
    '                  L.CODIGO_UNIDAD_INVLIN THEN 0 ELSE 1 END, ' +
    '                  T.FECHA_DESDE_ARTTAR DESC, ' +
    '                  T.CODIGO_UNICO_ARTTAR DESC ' +
    '         LIMIT 1), 0) * ' + SQL_FACTOR_COSTE_LINEA +
    '         AS COSTE_ARTICULO ' +
    '  FROM fza_inventarios_lineas L ' +
    ' WHERE L.CODIGO_EMP_INVLIN = :EMPRESA ' +
    '   AND L.CODIGO_ALM_INVLIN = :ALMACEN ' +
    '   AND L.SERIE_INV_INVLIN = :SERIE ' +
    '   AND L.NUMERO_INV_INVLIN = :NUMERO ' +
    '   AND L.CANTIDAD_FISICA_INVLIN > 0 ' +
    '   AND L.CANTIDAD_FISICA_INVLIN > L.CANTIDAD_TEORICA_INVLIN ' +
    '   AND IFNULL(L.PRECIO_MEDIO_INVLIN, 0) = 0 ' +
    '   AND IFNULL(L.PRECIO_MEDIO_NUEVO_INVLIN, 0) = 0 ' +
    '   AND IFNULL(L.ESPRECIO_MEDIO_CORREGIDO_INVLIN, ''N'') <> ''S''';
  SQL_GRABAR_COSTE_SOBRANTE =
    'UPDATE fza_inventarios_lineas ' +
    '   SET PRECIO_MEDIO_NUEVO_INVLIN = :PMP_NUEVO, ' +
    '       ESPRECIO_MEDIO_CORREGIDO_INVLIN = ''S'', ' +
    '       TOTAL_COSTE_DIFERENCIA_INVLIN = ROUND(' +
    '         CANTIDAD_FISICA_INVLIN * :PMP_NUEVO_COSTE - ' +
    '         CANTIDAD_TEORICA_INVLIN * IFNULL(PRECIO_MEDIO_INVLIN, 0), 2), ' +
    '       USUARIO_MODIF = :USUARIO ' +
    ' WHERE CODIGO_EMP_INVLIN = :EMPRESA ' +
    '   AND CODIGO_ALM_INVLIN = :ALMACEN ' +
    '   AND SERIE_INV_INVLIN = :SERIE ' +
    '   AND NUMERO_INV_INVLIN = :NUMERO ' +
    '   AND LINEA_INVLIN = :LINEA ' +
    '   AND IFNULL(ESPRECIO_MEDIO_CORREGIDO_INVLIN, ''N'') <> ''S''';
var
  oConsulta: TUniQuery;
  oUltimasCompras: TDictionary<string, Currency>;
  aLineas: TArray<string>;
  aCostes: TArray<Currency>;
  iLinea: Integer;
  dCoste: Currency;
  bTransaccionPropia: Boolean;
begin
  Result := 0;
  SetLength(aLineas, 0);
  SetLength(aCostes, 0);
  oUltimasCompras := nil;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := ConexionEscritura;
    oConsulta.SQL.Text := SQL_SOBRANTES_SIN_PMP;
    oConsulta.ParamByName('EMPRESA').AsString := FCodigoEmpresa;
    oConsulta.ParamByName('ALMACEN').AsString := FCodigoAlmacen;
    oConsulta.ParamByName('SERIE').AsString := FSerie;
    oConsulta.ParamByName('NUMERO').AsString := FNumero;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      dCoste := oConsulta.FieldByName('PMP_EMPRESA').AsCurrency;
      if dCoste <= 0 then
      begin
        if oUltimasCompras = nil then
          oUltimasCompras := CargarUltimasComprasInventario(
            ConexionEscritura, FCodigoEmpresa, FCodigoAlmacen, FSerie,
            FNumero);
        dCoste := UltimaCompraLinea(
          oUltimasCompras,
          oConsulta.FieldByName('CODIGO_UNIDAD_INVLIN').AsString,
          oConsulta.FieldByName('CODIGO_ART_INVLIN').AsString);
      end;
      if dCoste <= 0 then
        dCoste := oConsulta.FieldByName('COSTE_ARTICULO').AsCurrency;
      if dCoste > 0 then
      begin
        aLineas := aLineas +
          [oConsulta.FieldByName('LINEA_INVLIN').AsString];
        aCostes := aCostes + [dCoste];
      end;
      oConsulta.Next;
    end;
    oConsulta.Close;

    if Length(aLineas) > 0 then
    begin
      oConsulta.SQL.Text := SQL_GRABAR_COSTE_SOBRANTE;
      bTransaccionPropia := not ConexionEscritura.InTransaction;
      if bTransaccionPropia then
        ConexionEscritura.StartTransaction;
      try
        for iLinea := 0 to High(aLineas) do
        begin
          oConsulta.ParamByName('PMP_NUEVO').AsCurrency := aCostes[iLinea];
          oConsulta.ParamByName('PMP_NUEVO_COSTE').AsCurrency :=
            aCostes[iLinea];
          oConsulta.ParamByName('USUARIO').AsString := FUsuario;
          oConsulta.ParamByName('EMPRESA').AsString := FCodigoEmpresa;
          oConsulta.ParamByName('ALMACEN').AsString := FCodigoAlmacen;
          oConsulta.ParamByName('SERIE').AsString := FSerie;
          oConsulta.ParamByName('NUMERO').AsString := FNumero;
          oConsulta.ParamByName('LINEA').AsString := aLineas[iLinea];
          oConsulta.Execute;
          Inc(Result, oConsulta.RowsAffected);
        end;
        if bTransaccionPropia then
          ConexionEscritura.Commit;
      except
        if bTransaccionPropia then
          ConexionEscritura.Rollback;
        raise;
      end;
    end;
  finally
    FreeAndNil(oUltimasCompras);
    FreeAndNil(oConsulta);
  end;
end;

function TdmInventarios.ContarSobrantesSinCoste: Integer;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := ConexionEscritura;
    oConsulta.SQL.Text :=
      'SELECT COUNT(*) AS NUM_LINEAS ' +
      '  FROM fza_inventarios_lineas ' +
      ' WHERE CODIGO_EMP_INVLIN = :EMPRESA ' +
      '   AND CODIGO_ALM_INVLIN = :ALMACEN ' +
      '   AND SERIE_INV_INVLIN = :SERIE ' +
      '   AND NUMERO_INV_INVLIN = :NUMERO ' +
      '   AND CANTIDAD_FISICA_INVLIN > 0 ' +
      '   AND CANTIDAD_FISICA_INVLIN > CANTIDAD_TEORICA_INVLIN ' +
      '   AND IFNULL(PRECIO_MEDIO_NUEVO_INVLIN, 0) = 0';
    oConsulta.ParamByName('EMPRESA').AsString := FCodigoEmpresa;
    oConsulta.ParamByName('ALMACEN').AsString := FCodigoAlmacen;
    oConsulta.ParamByName('SERIE').AsString := FSerie;
    oConsulta.ParamByName('NUMERO').AsString := FNumero;
    oConsulta.Open;
    Result := oConsulta.FieldByName('NUM_LINEAS').AsInteger;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TdmInventarios.RecalcularTeorico: Integer;
begin
  if GetEstadoInventario <> 'ABIERTO' then
    raise Exception.Create(SErrorRecalcularInventarioNoAbierto);

  // Aseguramos que cualquier cambio pendiente se persiste antes de llamar al
  // SP. Si la linea recien insertada esta incompleta (sin articulo picado)
  // hacer Post da "Field value required". Cancelamos en ese caso.
  GrabarLineasPendientes;

  EjecutarSPActualizarTeorico;
  // FZ-ISSUE-619: coste conocido para los sobrantes sin PMP en el almacén.
  // El SP respeta el PMP corregido; se repite para dejar las diferencias y
  // los totales de la cabecera con ese coste.
  Result := ProponerCosteSobrantesSinPmp;
  if Result > 0 then
    EjecutarSPActualizarTeorico;

  // Refrescamos las líneas
  CargarLineasInventario;
  unqryTablaG.Refresh;
end;

procedure TdmInventarios.PreAplicarValidaciones;
begin
  if GetEstadoInventario <> 'ABIERTO' then
    raise Exception.Create(SErrorAplicarInventarioNoAbierto);

  // Post defensivo + ApplyUpdates: vuelca cambios pendientes del cdsLineas
  // (buffer cliente) a BBDD via el provider. Debe correr en main thread
  // porque cdsLineas esta vinculado al grid tvLineas y Post/ApplyUpdates
  // disparan eventos UI (cdsLineasAfterPost, repintado de filas, etc).
  GrabarLineasPendientes;

  // Salvaguarda: no aplicar un inventario sin líneas. Sin esto, la SP
  // PRC_FZA_INVENTARIOS_APLICAR cambia el estado a APLICADO sin generar
  // ningún movimiento, y cualquier línea con diferencia 0 se purga al
  // entrar en la SP, dejando un inventario vacío y aplicado.
  if (not cdsLineas.Active) or cdsLineas.IsEmpty then
    raise Exception.Create(SErrorAplicarInventarioSinLineas);
end;

function TdmInventarios.HayMovimientosPosterioresAlRecuento: Boolean;
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := ConexionEscritura;
    // Se comprueba el SKU completo: aplicar también completa los lotes
    // no contados. Solo negativos conserva su corte dinámico propio.
    Consulta.SQL.Text :=
      'SELECT 1 FROM fza_inventarios I ' +
      'JOIN fza_inventarios_lineas L ' +
      'ON L.CODIGO_EMP_INVLIN = I.CODIGO_EMP_INV ' +
      'AND L.CODIGO_ALM_INVLIN = I.CODIGO_ALM_INV ' +
      'AND L.SERIE_INV_INVLIN = I.SERIE_INV ' +
      'AND L.NUMERO_INV_INVLIN = I.NUMERO_INV ' +
      'JOIN fza_movimientos_almacen M ' +
      'ON M.CODIGO_ALM_MOV = L.CODIGO_ALM_INVLIN ' +
      'AND M.CODIGO_UNIDAD_MOV = L.CODIGO_UNIDAD_INVLIN ' +
      'WHERE I.CODIGO_EMP_INV = :EMPRESA ' +
      'AND I.CODIGO_ALM_INV = :ALMACEN ' +
      'AND I.SERIE_INV = :SERIE AND I.NUMERO_INV = :NUMERO ' +
      'AND IFNULL(I.ESSOLONEGATIVOS_INV, ''N'') <> ''S'' ' +
      'AND M.ESACTIVO_MOV = ''S'' ' +
      'AND M.FECHA_MOV > IFNULL(L.FECHA_RECUENTO_INVLIN, I.FECHA_INV) ' +
      'LIMIT 1';
    Consulta.ParamByName('EMPRESA').AsString := FCodigoEmpresa;
    Consulta.ParamByName('ALMACEN').AsString := FCodigoAlmacen;
    Consulta.ParamByName('SERIE').AsString := FSerie;
    Consulta.ParamByName('NUMERO').AsString := FNumero;
    Consulta.Open;
    Result := not Consulta.IsEmpty;
  finally
    FreeAndNil(Consulta);
  end;
end;

procedure TdmInventarios.EjecutarSPAplicar;
var
  MensajeValidacion: string;
begin
  // Repetir la comprobación tras la confirmación y cubrir el camino
  // síncrono. El SP vuelve a validarlo antes de escribir movimientos.
  if HayMovimientosPosterioresAlRecuento then
    raise EValidacionBBDD.Create(
      SAvisoMovimientosPosterioresRecuentoInventario);
  // Solo el ExecProc. Es la pieza apta para background: no toca grids,
  // solo BBDD a traves de unspAplicar (que apunta a FConn del Mto desde
  // Fase 1). Mientras corre, otros tabs siguen interactivos.
  unspAplicar.Close;
  unspAplicar.ParamByName('p_EMPRESA').AsString := FCodigoEmpresa;
  unspAplicar.ParamByName('p_ALMACEN').AsString := FCodigoAlmacen;
  unspAplicar.ParamByName('p_SERIE').AsString   := FSerie;
  unspAplicar.ParamByName('p_NRO').AsString     := FNumero;
  unspAplicar.ParamByName('p_USUARIO').AsString := FUsuario;
  try
    unspAplicar.ExecProc;
  except
    on E: EDAError do
    begin
      if ObtenerMensajeValidacionBBDD(E.ErrorCode, E.Message,
        MensajeValidacion) then
        raise EValidacionBBDD.Create(MensajeValidacion);
      raise;
    end;
  end;
  if not unspAplicar.Connection.InTransaction then
    SolicitarProcesadoPrestaShop;
end;

procedure TdmInventarios.RefrescarTrasAplicar;
begin
  // Recarga de queries vinculadas a grids (tvLineas, tvMovsRegul) y la
  // lista principal. Debe correr en main thread.
  CargarLineasInventario;
  CargarMovimientosRegularizacion;
  unqryTablaG.Refresh;
end;

procedure TdmInventarios.AplicarInventario;
var
  swTotal, swTramo: TStopwatch;
  msApply, msExecProc, msRecargas, msRefresh: Int64;
begin
  // [PERF:Aplicar] Camino sincrono instrumentado. Mide los 4 tramos para
  // tener una base de comparacion con el camino background (Fase 2).
  swTotal := TStopwatch.StartNew;

  swTramo := TStopwatch.StartNew;
  PreAplicarValidaciones;
  // FZ-ISSUE-619: coste conocido para los sobrantes sin PMP en el almacén.
  if ContarSobrantesSinCoste > 0 then
    RecalcularTeorico;
  msApply := swTramo.ElapsedMilliseconds;

  swTramo := TStopwatch.StartNew;
  EjecutarSPAplicar;
  msExecProc := swTramo.ElapsedMilliseconds;

  swTramo := TStopwatch.StartNew;
  CargarLineasInventario;
  CargarMovimientosRegularizacion;
  msRecargas := swTramo.ElapsedMilliseconds;

  swTramo := TStopwatch.StartNew;
  unqryTablaG.Refresh;
  msRefresh := swTramo.ElapsedMilliseconds;

  RegistroLog.RegistrarInformacion(Format(
    '[PERF:Aplicar] total=%d ms | ApplyUpdates=%d | ExecProc=%d | ' +
    'Recargas=%d | Refresh=%d (emp=%s alm=%s ser=%s nro=%s)',
    [swTotal.ElapsedMilliseconds, msApply, msExecProc, msRecargas, msRefresh,
     FCodigoEmpresa, FCodigoAlmacen, FSerie, FNumero]));
end;

procedure TdmInventarios.EliminarRegularizacion;
begin
  if GetEstadoInventario <> 'APLICADO' then
    raise Exception.Create(SErrorEliminarRegularizacionInventarioNoAplicado);

  unspEliminarRegul.Close;
  unspEliminarRegul.ParamByName('p_EMPRESA').AsString := FCodigoEmpresa;
  unspEliminarRegul.ParamByName('p_ALMACEN').AsString := FCodigoAlmacen;
  unspEliminarRegul.ParamByName('p_SERIE').AsString   := FSerie;
  unspEliminarRegul.ParamByName('p_NRO').AsString     := FNumero;
  unspEliminarRegul.ParamByName('p_USUARIO').AsString := FUsuario;
  unspEliminarRegul.ExecProc;
  if not unspEliminarRegul.Connection.InTransaction then
    SolicitarProcesadoPrestaShop;

  CargarLineasInventario;
  CargarMovimientosRegularizacion;
  unqryTablaG.Refresh;
end;

procedure TdmInventarios.CargarPorFamilia(const ACodigoFamilia: string);
var
  qry: TUniQuery;
begin
  if GetEstadoInventario <> 'ABIERTO' then
    raise Exception.Create(SErrorCargarArticulosInventarioNoAbierto);

  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionEscritura;
    qry.SQL.Text :=
      'SELECT s.CODIGO_UNIDAD_SKU, s.CODIGO_ART_SKU, ' +
      '       a.DESCRIPCION_ART, ' +
      '       IFNULL(stk.CANTIDAD_STK, 0)        AS CANTIDAD, ' +
      '       COALESCE(stk.LOTE_STK, '''') AS LOTE, ' +
      '       lot.FECHA_CADUCIDAD_LOT AS CADUCIDAD, ' +
      '       IFNULL(stk.PRECIO_MEDIO_STK, 0)    AS PMP ' +
      '  FROM fza_articulos_skus s ' +
      '  JOIN fza_articulos a ' +
      '    ON a.CODIGO_ART_ART = s.CODIGO_ART_SKU ' +
      '  LEFT JOIN fza_articulos_stockactual stk ' +
      '    ON stk.CODIGO_UNIDAD_STK   = s.CODIGO_UNIDAD_SKU ' +
      '   AND stk.CODIGO_ALM_STK = :ALMACEN ' +
      '  LEFT JOIN fza_articulos_lotes lot ' +
      '    ON lot.CODIGO_UNIDAD_LOT = stk.CODIGO_UNIDAD_STK ' +
      '   AND lot.LOTE_LOT = stk.LOTE_STK ' +
      ' WHERE a.CODIGO_FAM_ART = :FAMILIA ' +
      '   AND a.TIPO_ART = ''ESTANDAR'' ' +
      ' ORDER BY a.CODIGO_ART_ART, s.CODIGO_UNIDAD_SKU';
    qry.ParamByName('ALMACEN').AsString := FCodigoAlmacen;
    qry.ParamByName('FAMILIA').AsString := ACodigoFamilia;
    qry.Open;

    cdsLineas.DisableControls;
    try
      while not qry.Eof do
      begin
        // Saltar duplicados
        if not LocalizarLineaRecuento(
          qry.FieldByName('CODIGO_UNIDAD_SKU').AsString,
          qry.FieldByName('LOTE').AsString) then
        begin
          cdsLineas.Append;
          cdsLineas.FieldByName('CODIGO_ART_INVLIN').AsString :=
            qry.FieldByName('CODIGO_ART_SKU').AsString;
          cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString   :=
            qry.FieldByName('CODIGO_UNIDAD_SKU').AsString;
          cdsLineas.FieldByName('DESCRIPCION_ARTICULO_INVLIN').AsString :=
            qry.FieldByName('DESCRIPCION_ART').AsString;
          cdsLineas.FieldByName('CANTIDAD_TEORICA_INVLIN').AsCurrency   :=
            qry.FieldByName('CANTIDAD').AsCurrency;
          // por defecto = teórica
          cdsLineas.FieldByName('CANTIDAD_FISICA_INVLIN').AsCurrency    :=
            qry.FieldByName('CANTIDAD').AsCurrency;
          cdsLineas.FieldByName('PRECIO_MEDIO_INVLIN').AsCurrency       :=
            qry.FieldByName('PMP').AsCurrency;
          // por defecto = anterior
          cdsLineas.FieldByName('PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency :=
            qry.FieldByName('PMP').AsCurrency;
          AsignarLoteLineaCarga(qry);
          cdsLineas.Post;
        end;
        qry.Next;
      end;
      AplicarLineasPendientes;
    finally
      cdsLineas.EnableControls;
    end;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TdmInventarios.CargarPorProveedor(const ACodigoProveedor: string);
var
  qry: TUniQuery;
begin
  if GetEstadoInventario <> 'ABIERTO' then
    raise Exception.Create(SErrorCargarArticulosInventarioNoAbierto);

  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionEscritura;
    qry.SQL.Text :=
      'SELECT s.CODIGO_UNIDAD_SKU, s.CODIGO_ART_SKU, ' +
      '       a.DESCRIPCION_ART, ' +
      '       IFNULL(stk.CANTIDAD_STK, 0)     AS CANTIDAD, ' +
      '       COALESCE(stk.LOTE_STK, '''') AS LOTE, ' +
      '       lot.FECHA_CADUCIDAD_LOT AS CADUCIDAD, ' +
      '       IFNULL(stk.PRECIO_MEDIO_STK, 0) AS PMP ' +
      '  FROM fza_articulos_proveedores ap ' +
      '  JOIN fza_articulos a ' +
      '    ON a.CODIGO_ART_ART = ap.CODIGO_ART_AP ' +
      '  JOIN fza_articulos_skus s ' +
      '    ON s.CODIGO_ART_SKU = a.CODIGO_ART_ART ' +
      '  LEFT JOIN fza_articulos_stockactual stk ' +
      '    ON stk.CODIGO_UNIDAD_STK   = s.CODIGO_UNIDAD_SKU ' +
      '   AND stk.CODIGO_ALM_STK = :ALMACEN ' +
      '  LEFT JOIN fza_articulos_lotes lot ' +
      '    ON lot.CODIGO_UNIDAD_LOT = stk.CODIGO_UNIDAD_STK ' +
      '   AND lot.LOTE_LOT = stk.LOTE_STK ' +
      ' WHERE ap.CODIGO_PRV_AP = :PROVEEDOR ' +
      '   AND a.TIPO_ART = ''ESTANDAR'' ' +
      ' ORDER BY a.CODIGO_ART_ART, s.CODIGO_UNIDAD_SKU';
    qry.ParamByName('ALMACEN').AsString   := FCodigoAlmacen;
    qry.ParamByName('PROVEEDOR').AsString := ACodigoProveedor;
    qry.Open;

    cdsLineas.DisableControls;
    try
      while not qry.Eof do
      begin
        if not LocalizarLineaRecuento(
          qry.FieldByName('CODIGO_UNIDAD_SKU').AsString,
          qry.FieldByName('LOTE').AsString) then
        begin
          cdsLineas.Append;
          cdsLineas.FieldByName('CODIGO_ART_INVLIN').AsString :=
            qry.FieldByName('CODIGO_ART_SKU').AsString;
          cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString   :=
            qry.FieldByName('CODIGO_UNIDAD_SKU').AsString;
          cdsLineas.FieldByName('DESCRIPCION_ARTICULO_INVLIN').AsString :=
            qry.FieldByName('DESCRIPCION_ART').AsString;
          cdsLineas.FieldByName('CANTIDAD_TEORICA_INVLIN').AsCurrency   :=
            qry.FieldByName('CANTIDAD').AsCurrency;
          cdsLineas.FieldByName('CANTIDAD_FISICA_INVLIN').AsCurrency    :=
            qry.FieldByName('CANTIDAD').AsCurrency;
          cdsLineas.FieldByName('PRECIO_MEDIO_INVLIN').AsCurrency       :=
            qry.FieldByName('PMP').AsCurrency;
          cdsLineas.FieldByName('PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency :=
            qry.FieldByName('PMP').AsCurrency;
          AsignarLoteLineaCarga(qry);
          cdsLineas.Post;
        end;
        qry.Next;
      end;
      AplicarLineasPendientes;
    finally
      cdsLineas.EnableControls;
    end;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TdmInventarios.CargarTodosArticulosConStock;
var
  qry: TUniQuery;
begin
  if GetEstadoInventario <> 'ABIERTO' then
    raise Exception.Create(SErrorCargarArticulosInventarioNoAbierto);

  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionEscritura;
    qry.SQL.Text :=
      'SELECT s.CODIGO_UNIDAD_SKU, s.CODIGO_ART_SKU, ' +
      '       a.DESCRIPCION_ART, ' +
      '       stk.CANTIDAD_STK     AS CANTIDAD, ' +
      '       COALESCE(stk.LOTE_STK, '''') AS LOTE, ' +
      '       lot.FECHA_CADUCIDAD_LOT AS CADUCIDAD, ' +
      '       stk.PRECIO_MEDIO_STK AS PMP ' +
      '  FROM fza_articulos_skus s ' +
      '  JOIN fza_articulos a ' +
      '    ON a.CODIGO_ART_ART = s.CODIGO_ART_SKU ' +
      '  JOIN fza_articulos_stockactual stk ' +
      '    ON stk.CODIGO_UNIDAD_STK   = s.CODIGO_UNIDAD_SKU ' +
      '   AND stk.CODIGO_ALM_STK = :ALMACEN ' +
      '  LEFT JOIN fza_articulos_lotes lot ' +
      '    ON lot.CODIGO_UNIDAD_LOT = stk.CODIGO_UNIDAD_STK ' +
      '   AND lot.LOTE_LOT = stk.LOTE_STK ' +
      ' WHERE a.TIPO_ART = ''ESTANDAR'' ' +
      '   AND stk.CANTIDAD_STK <> 0 ' +
      ' ORDER BY a.CODIGO_ART_ART, s.CODIGO_UNIDAD_SKU';
    qry.ParamByName('ALMACEN').AsString := FCodigoAlmacen;
    qry.Open;

    cdsLineas.DisableControls;
    try
      while not qry.Eof do
      begin
        if not LocalizarLineaRecuento(
          qry.FieldByName('CODIGO_UNIDAD_SKU').AsString,
          qry.FieldByName('LOTE').AsString) then
        begin
          cdsLineas.Append;
          cdsLineas.FieldByName('CODIGO_ART_INVLIN').AsString :=
            qry.FieldByName('CODIGO_ART_SKU').AsString;
          cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString   :=
            qry.FieldByName('CODIGO_UNIDAD_SKU').AsString;
          cdsLineas.FieldByName('DESCRIPCION_ARTICULO_INVLIN').AsString :=
            qry.FieldByName('DESCRIPCION_ART').AsString;
          cdsLineas.FieldByName('CANTIDAD_TEORICA_INVLIN').AsCurrency   :=
            qry.FieldByName('CANTIDAD').AsCurrency;
          cdsLineas.FieldByName('CANTIDAD_FISICA_INVLIN').AsCurrency    :=
            qry.FieldByName('CANTIDAD').AsCurrency;
          cdsLineas.FieldByName('PRECIO_MEDIO_INVLIN').AsCurrency       :=
            qry.FieldByName('PMP').AsCurrency;
          cdsLineas.FieldByName('PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency :=
            qry.FieldByName('PMP').AsCurrency;
          AsignarLoteLineaCarga(qry);
          cdsLineas.Post;
        end;
        qry.Next;
      end;
      AplicarLineasPendientes;
    finally
      cdsLineas.EnableControls;
    end;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TdmInventarios.CompletarUnidadesNoLeidas;
var
  qry: TUniQuery;
begin
  // "Completar" significa: traer al inventario todos los SKUs con stock que NO
  // estén ya en el inventario actual, asignándoles cantidad física = 0
  // (porque NO se han contado / son los que faltan).
  if GetEstadoInventario <> 'ABIERTO' then
    raise Exception.Create(SErrorCompletarInventarioNoAbierto);

  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionEscritura;
    qry.SQL.Text :=
      'SELECT s.CODIGO_UNIDAD_SKU, s.CODIGO_ART_SKU, ' +
      '       a.DESCRIPCION_ART, ' +
      '       stk.CANTIDAD_STK     AS CANTIDAD, ' +
      '       COALESCE(stk.LOTE_STK, '''') AS LOTE, ' +
      '       lot.FECHA_CADUCIDAD_LOT AS CADUCIDAD, ' +
      '       stk.PRECIO_MEDIO_STK AS PMP ' +
      '  FROM fza_articulos_skus s ' +
      '  JOIN fza_articulos a ' +
      '    ON a.CODIGO_ART_ART = s.CODIGO_ART_SKU ' +
      '  JOIN fza_articulos_stockactual stk ' +
      '    ON stk.CODIGO_UNIDAD_STK   = s.CODIGO_UNIDAD_SKU ' +
      '   AND stk.CODIGO_ALM_STK = :ALMACEN ' +
      '  LEFT JOIN fza_articulos_lotes lot ' +
      '    ON lot.CODIGO_UNIDAD_LOT = stk.CODIGO_UNIDAD_STK ' +
      '   AND lot.LOTE_LOT = stk.LOTE_STK ' +
      ' WHERE a.TIPO_ART = ''ESTANDAR'' ' +
      '   AND stk.CANTIDAD_STK <> 0 ' +
      '   AND NOT EXISTS ( ' +
      '         SELECT 1 FROM fza_inventarios_lineas l ' +
      '          WHERE l.CODIGO_EMP_INVLIN = :EMPRESA ' +
      '            AND l.CODIGO_ALM_INVLIN = :ALMACEN ' +
      '            AND l.SERIE_INV_INVLIN          = :SERIE ' +
      '            AND l.NUMERO_INV_INVLIN            = :NUMERO ' +
      '            AND l.CODIGO_UNIDAD_INVLIN  = s.CODIGO_UNIDAD_SKU ' +
      '            AND COALESCE(l.LOTE_INVLIN, '''') = ' +
      '                COALESCE(stk.LOTE_STK, '''')) ' +
      ' ORDER BY a.CODIGO_ART_ART, s.CODIGO_UNIDAD_SKU';
    qry.ParamByName('ALMACEN').AsString := FCodigoAlmacen;
    qry.ParamByName('EMPRESA').AsString := FCodigoEmpresa;
    qry.ParamByName('SERIE').AsString   := FSerie;
    qry.ParamByName('NUMERO').AsString  := FNumero;
    qry.Open;

    cdsLineas.DisableControls;
    try
      while not qry.Eof do
      begin
        cdsLineas.Append;
        cdsLineas.FieldByName('CODIGO_ART_INVLIN').AsString :=
          qry.FieldByName('CODIGO_ART_SKU').AsString;
        cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString   :=
          qry.FieldByName('CODIGO_UNIDAD_SKU').AsString;
        cdsLineas.FieldByName('DESCRIPCION_ARTICULO_INVLIN').AsString :=
          qry.FieldByName('DESCRIPCION_ART').AsString;
        cdsLineas.FieldByName('CANTIDAD_TEORICA_INVLIN').AsCurrency   :=
          qry.FieldByName('CANTIDAD').AsCurrency;
        // OJO: en COMPLETAR, la cantidad física es 0 — porque por
        // definición no se ha contado
        cdsLineas.FieldByName('CANTIDAD_FISICA_INVLIN').AsCurrency    := 0;
        cdsLineas.FieldByName('PRECIO_MEDIO_INVLIN').AsCurrency       :=
          qry.FieldByName('PMP').AsCurrency;
        cdsLineas.FieldByName('PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency :=
          qry.FieldByName('PMP').AsCurrency;
        AsignarLoteLineaCarga(qry);
        cdsLineas.Post;
        qry.Next;
      end;
      AplicarLineasPendientes;
    finally
      cdsLineas.EnableControls;
    end;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TdmInventarios.PrepararLineaParaCargarSkus;
begin
  if cdsLineas.State in [dsEdit, dsInsert] then
  begin
    // La fila solo sirve para elegir el articulo hasta completar su SKU.
    // Cancelar una edicion recupera la fila previa; una insercion se descarta.
    if (cdsLineas.FieldByName('NUM_ATRIBUTOS_REQ_INV_LINEA').AsInteger > 0)
      and (not EsSkuCompletoInventario(
        cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString,
        cdsLineas.FieldByName('NUM_ATRIBUTOS_REQ_INV_LINEA').AsInteger,
        cdsLineas.FieldByName('CODIGO_ART_INVLIN').AsString)) then
      cdsLineas.Cancel
    else
      cdsLineas.Post;
  end;
end;

function TdmInventarios.CargarSkusConMovimientosArticulo(
  const ACodigoArticulo: string): Integer;
var
  qry: TUniQuery;
  Sku: string;
begin
  // Inserta una línea de inventario por cada SKU distinto del artículo
  // ACodigoArticulo que tenga al menos un movimiento en el almacén actual.
  // Salta SKUs que ya estén presentes en este inventario.
  // Devuelve el número de líneas insertadas.
  Result := 0;
  if Trim(ACodigoArticulo) = '' then
    raise Exception.Create(SErrorArticuloLineaInventarioObligatorio);
  if GetEstadoInventario <> 'ABIERTO' then
    raise Exception.Create(SErrorAnadirSkusInventarioNoAbierto);

  PrepararLineaParaCargarSkus;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionEscritura;
    qry.SQL.Text :=
      'SELECT DISTINCT m.CODIGO_UNIDAD_MOV AS CODIGO_UNIDAD_SKU, ' +
      '       m.CODIGO_ART_MOV    AS CODIGO_ART_SKU, ' +
      '       a.DESCRIPCION_ART, ' +
      '       COALESCE(stk.CANTIDAD_STK, 0)     AS CANTIDAD_TEORICA, ' +
      '       COALESCE(stk.LOTE_STK, '''') AS LOTE, ' +
      '       lot.FECHA_CADUCIDAD_LOT AS CADUCIDAD, ' +
      '       COALESCE(stk.PRECIO_MEDIO_STK, 0) AS PMP ' +
      '  FROM fza_movimientos_almacen m ' +
      '  JOIN fza_articulos a ' +
      '    ON a.CODIGO_ART_ART = m.CODIGO_ART_MOV ' +
      '  LEFT JOIN fza_articulos_stockactual stk ' +
      '    ON stk.CODIGO_UNIDAD_STK = m.CODIGO_UNIDAD_MOV ' +
      '   AND stk.CODIGO_ALM_STK    = :ALMACEN ' +
      '  LEFT JOIN fza_articulos_lotes lot ' +
      '    ON lot.CODIGO_UNIDAD_LOT = stk.CODIGO_UNIDAD_STK ' +
      '   AND lot.LOTE_LOT = stk.LOTE_STK ' +
      ' WHERE m.CODIGO_ART_MOV = :ARTICULO ' +
      '   AND m.CODIGO_ALM_MOV = :ALMACEN ' +
      ' ORDER BY m.CODIGO_UNIDAD_MOV';
    qry.ParamByName('ARTICULO').AsString := ACodigoArticulo;
    qry.ParamByName('ALMACEN').AsString  := FCodigoAlmacen;
    qry.Open;

    if not qry.IsEmpty then
    begin
      cdsLineas.DisableControls;
      try
        while not qry.Eof do
        begin
          Sku := qry.FieldByName('CODIGO_UNIDAD_SKU').AsString;
          if (Sku <> '') and (not LocalizarLineaRecuento(Sku,
               qry.FieldByName('LOTE').AsString)) then
          begin
            cdsLineas.Append;
            cdsLineas.FieldByName('CODIGO_ART_INVLIN').AsString :=
              qry.FieldByName('CODIGO_ART_SKU').AsString;
            cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString := Sku;
            cdsLineas.FieldByName(
              'DESCRIPCION_ARTICULO_INVLIN').AsString :=
              qry.FieldByName('DESCRIPCION_ART').AsString;
            cdsLineas.FieldByName(
              'CANTIDAD_TEORICA_INVLIN').AsCurrency :=
              qry.FieldByName('CANTIDAD_TEORICA').AsCurrency;
            // El recuento parte de la cantidad teorica.
            cdsLineas.FieldByName(
              'CANTIDAD_FISICA_INVLIN').AsCurrency :=
              qry.FieldByName('CANTIDAD_TEORICA').AsCurrency;
            cdsLineas.FieldByName('PRECIO_MEDIO_INVLIN').AsCurrency :=
              qry.FieldByName('PMP').AsCurrency;
            cdsLineas.FieldByName(
              'PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency :=
              qry.FieldByName('PMP').AsCurrency;
            AsignarLoteLineaCarga(qry);
            RellenarAtributosLineaDesdeSku(cdsLineas);
            cdsLineas.Post;
            Inc(Result);
          end;
          qry.Next;
        end;
        if Result > 0 then
        begin
          AplicarLineasPendientes;
        end;
      finally
        cdsLineas.EnableControls;
      end;
    end;
  finally
    FreeAndNil(qry);
  end;
end;

function TdmInventarios.SkuExiste(const ASku: string): Boolean;
var
  qry: TUniQuery;
begin
  Result := False;
  if Trim(ASku) <> '' then
  begin
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := ConexionEscritura;
      qry.SQL.Text := 'SELECT 1 FROM fza_articulos_skus ' +
                      ' WHERE CODIGO_UNIDAD_SKU = :SKU LIMIT 1';
      qry.ParamByName('SKU').AsString := ASku;
      qry.Open;
      Result := not qry.IsEmpty;
      qry.Close;
    finally
      FreeAndNil(qry);
    end;
  end;
end;

function TdmInventarios.CrearSkuDesdeLinea(const ACodigoArticulo, ASku: string;
  const AAtributos: array of string): Boolean;
var
  qry: TUniQuery;
  i, IdAv: Integer;
  ValorAtrib: string;
begin
  // Crea fza_articulos_skus + fza_atributos_sku para un SKU que no existía,
  // a partir del artículo padre y los valores de atributo de la línea.
  // CODIGO_VAR_SKU se hereda del primer SKU existente del artículo o, si no
  // hay ninguno, de fza_articulos.TIPO_VARIACION_ART.
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionEscritura;

    // 1) Insertar la cabecera del SKU.
    qry.SQL.Text :=
      'INSERT IGNORE INTO fza_articulos_skus ' +
      '  (CODIGO_UNIDAD_SKU, CODIGO_ART_SKU, CODIGO_VAR_SKU, ' +
      '   ESACTIVO_SKU, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
      'SELECT :SKU, :ART, ' +
      '       COALESCE( ' +
      '         (SELECT s.CODIGO_VAR_SKU FROM fza_articulos_skus s ' +
      '           WHERE s.CODIGO_ART_SKU = :ART LIMIT 1), ' +
      '         (SELECT a.TIPO_VARIACION_ART FROM fza_articulos a ' +
      '           WHERE a.CODIGO_ART_ART = :ART) ' +
      '       ), ''S'', NOW(), :USR, :USR';
    qry.ParamByName('SKU').AsString := ASku;
    qry.ParamByName('ART').AsString := ACodigoArticulo;
    qry.ParamByName('USR').AsString := FUsuario;
    qry.ExecSQL;

    // 2) Insertar la relación con cada valor de atributo. La posición i+1
    //    corresponde al ORDEN_VISUAL_ATRIBUTO de vi_atributos_nombres.
    for i := 0 to High(AAtributos) do
    begin
      ValorAtrib := Trim(AAtributos[i]);
      if ValorAtrib <> '' then
      begin
      qry.SQL.Text :=
        'SELECT v.ID_AV ' +
        '  FROM fza_atributos_valores v ' +
        '  JOIN vi_atributos_nombres n ON v.ID_VA_AV = n.ID_ATRIBUTO ' +
        ' WHERE n.CODIGO_ART_PADRE_ARTVIN = :ART ' +
        '   AND n.ORDEN_VISUAL_ATRIBUTO = :ORDEN ' +
        '   AND v.AV = :VALOR ' +
        '   AND COALESCE(v.ESACTIVO_AV, ''S'') = ''S'' ' +
        ' LIMIT 1';
      qry.ParamByName('ART').AsString    := ACodigoArticulo;
      qry.ParamByName('ORDEN').AsInteger := i + 1;
      qry.ParamByName('VALOR').AsString  := ValorAtrib;
      qry.Open;
      if qry.IsEmpty then
      begin
        qry.Close;
        raise Exception.CreateFmt(
          SErrorValorAtributoSkuInventarioNoEncontrado,
          [ValorAtrib, i + 1, ACodigoArticulo, ASku]);
      end;
      IdAv := qry.FieldByName('ID_AV').AsInteger;
      qry.Close;

      qry.SQL.Text :=
        'INSERT IGNORE INTO fza_atributos_sku ' +
        '  (CODIGO_UNIDAD_SKU_SA, ID_AV_SA, ' +
        '   INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
        'VALUES (:SKU, :IDAV, NOW(), :USR, :USR)';
      qry.ParamByName('SKU').AsString   := ASku;
      qry.ParamByName('IDAV').AsInteger := IdAv;
      qry.ParamByName('USR').AsString   := FUsuario;
      qry.ExecSQL;
      end;
    end;

    Result := True;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TdmInventarios.CargarAlmacenesPorEmpresa(
  const ACodigoEmpresa: string);
begin
  if ACodigoEmpresa = '' then
  begin
    if unqryAlmacenes.Active then
      unqryAlmacenes.Close;
  end
  else if not (unqryAlmacenes.Active and
               SameText(unqryAlmacenes.ParamByName('EMPRESA').AsString,
                        ACodigoEmpresa)) then
  begin
    unqryAlmacenes.Close;
    unqryAlmacenes.ParamByName('EMPRESA').AsString := ACodigoEmpresa;
    unqryAlmacenes.Open;
  end;
  if unqryTablaG.Active and
     (unqryTablaG.State in [dsInsert, dsEdit]) then
    AjustarEmpresaAlmacenDataSet(unqryTablaG.Connection, unqryTablaG,
      'CODIGO_EMP_INV', 'CODIGO_ALM_INV');
end;

procedure TdmInventarios.CargarSeriesPorEmpresa(const ACodigoEmpresa: string);
begin
  // Solo aplicable si la SQL de unqrySeries declara el parámetro :EMPRESA
  // (ver dfm: tabla fza_empresas_series filtrada por CODIGO_EMP_EMPSER).
  unqrySeries.Close;
  if ACodigoEmpresa = '' then
    unqrySeries.Open
  else
  begin
    if unqrySeries.Params.FindParam('EMPRESA') <> nil then
      unqrySeries.ParamByName('EMPRESA').AsString := ACodigoEmpresa;
    unqrySeries.Open;
  end;
end;

procedure ComprobarErroresAplicacionLineas(AErrores: Integer);
begin
  if AErrores > 0 then
    raise EDatabaseError.CreateFmt(
      SErrorAplicarImportacionInventario,
      [AErrores]);
end;

procedure TdmInventarios.AplicarLineasPendientes;
begin
  if cdsLineas.Active and (cdsLineas.ChangeCount > 0) then
  begin
    ComprobarErroresAplicacionLineas(cdsLineas.ApplyUpdates(0));
    // Ningún llamador puede anunciar éxito ni regularizar con un delta
    // que el proveedor no haya confirmado.
    ComprobarErroresAplicacionLineas(cdsLineas.ChangeCount);
  end;
end;

procedure TdmInventarios.ListarAlmacenesRecuento(const AEmpresa: string;
  ALista: TStrings);
var
  qry: TUniQuery;
begin
  ALista.Clear;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionEscritura;
    qry.SQL.Text := unqryAlmacenes.SQL.Text;
    qry.ParamByName('EMPRESA').AsString := AEmpresa;
    qry.Open;
    while not qry.Eof do
    begin
      ALista.Add(qry.FieldByName('CODIGO_ALMACEN').AsString + '=' +
        qry.FieldByName('DESCRIPCION_ALMACEN').AsString);
      qry.Next;
    end;
    qry.Close;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TdmInventarios.NormalizarSkusRecuentoMovil(
  ALista: TStringList;
  AInstantesRecuento: TStrings;
  ANoAsignados: TStrings);
begin
  // FZ-ISSUE-351: la traducción EAN -> SKU es común con los traspasos
  // hechos con la app (inLibRecuentoSkuNormalizacion).
  inLibRecuentoSkuNormalizacion.NormalizarSkusRecuentoMovil(
    CrearResolutorSkuRecuentoUniDAC(ConexionEscritura),
    ALista,
    AInstantesRecuento,
    ANoAsignados);
end;

procedure TdmInventarios.ValidarSkusRecuentoMovil(
  ALista: TStringList);
var
  i: Integer;
  Sku: string;
begin
  for i := 0 to ALista.Count - 1 do
  begin
    Sku := ObtenerSkuRecuento(ALista, i);
    // Dato del móvil, no fallo del programa: EValidacionBBDD se muestra
    // como aviso, sin pila ni «Salir de la aplicación».
    if (Sku <> '') and (not SkuExiste(Sku)) then
      raise EValidacionBBDD.CreateFmt(
        SErrorSkuRecuentoInventarioNoExiste,
        [Sku]);
  end;
end;

function TdmInventarios.ImportarArticulosInventario(
  const AOrigen: TClaveInventario): Integer;
var
  Consulta: TUniQuery;
  Lista: TStringList;
  NumeroOrigen: string;
  Sku: string;
  Lote: string;
  LineasAntes: Integer;
begin
  if (Trim(AOrigen.Empresa) = '') or
     (Trim(AOrigen.Almacen) = '') or
     (Trim(AOrigen.Serie) = '') or (Trim(AOrigen.Numero) = '') then
    raise EValidacionBBDD.Create(SErrorClaveImportarInventario);
  if GetEstadoInventario <> 'ABIERTO' then
    raise EValidacionBBDD.Create(SErrorInventarioDebeEstarAbierto);
  Consulta := TUniQuery.Create(nil);
  Lista := TStringList.Create;
  try
    Consulta.Connection := ConexionEscritura;
    Consulta.SQL.Text :=
      'SELECT NUMERO_INV FROM fza_inventarios ' +
      ' WHERE CODIGO_EMP_INV = :EMPRESA ' +
      '   AND CODIGO_ALM_INV = :ALMACEN ' +
      '   AND SERIE_INV = :SERIE ' +
      '   AND TRIM(LEADING ''0'' FROM NUMERO_INV) = ' +
      '       TRIM(LEADING ''0'' FROM :NUMERO)';
    Consulta.ParamByName('EMPRESA').AsString := AOrigen.Empresa;
    Consulta.ParamByName('ALMACEN').AsString := AOrigen.Almacen;
    Consulta.ParamByName('SERIE').AsString := AOrigen.Serie;
    Consulta.ParamByName('NUMERO').AsString := AOrigen.Numero;
    Consulta.Open;
    if Consulta.IsEmpty then
      raise EValidacionBBDD.Create(SErrorOrigenImportarInventario);
    NumeroOrigen := Consulta.FieldByName('NUMERO_INV').AsString;
    Consulta.Next;
    if not Consulta.Eof then
      raise EValidacionBBDD.Create(SErrorOrigenImportarInventario);
    if SameText(AOrigen.Empresa, FCodigoEmpresa) and
       SameText(AOrigen.Almacen, FCodigoAlmacen) and
       SameText(AOrigen.Serie, FSerie) and
       SameText(NumeroOrigen, FNumero) then
      raise EValidacionBBDD.Create(SErrorMismoImportarInventario);
    Consulta.Close;
    Consulta.SQL.Text :=
      'SELECT CODIGO_ART_INVLIN, CODIGO_UNIDAD_INVLIN, ' +
      '       CANTIDAD_FISICA_INVLIN, ' +
      '       LOTE_INVLIN, FECHA_CADUCIDAD_INVLIN ' +
      '  FROM fza_inventarios_lineas ' +
      ' WHERE CODIGO_EMP_INVLIN = :EMPRESA ' +
      '   AND CODIGO_ALM_INVLIN = :ALMACEN ' +
      '   AND SERIE_INV_INVLIN = :SERIE ' +
      '   AND NUMERO_INV_INVLIN = :NUMERO ' +
      ' ORDER BY LINEA_INVLIN';
    Consulta.ParamByName('EMPRESA').AsString := AOrigen.Empresa;
    Consulta.ParamByName('ALMACEN').AsString := AOrigen.Almacen;
    Consulta.ParamByName('SERIE').AsString := AOrigen.Serie;
    Consulta.ParamByName('NUMERO').AsString := NumeroOrigen;
    Consulta.Open;
    if Consulta.IsEmpty then
      raise EValidacionBBDD.Create(SErrorSinArticulosImportarInventario);
    IniciarImportacionLineas;
    try
      BloquearInventarioParaRevalorizacion;
      CargarLineasInventario;
      LineasAntes := cdsLineas.RecordCount;
      while not Consulta.Eof do
      begin
        Sku := Consulta.FieldByName('CODIGO_UNIDAD_INVLIN').AsString;
        Lote := Consulta.FieldByName('LOTE_INVLIN').AsString;
        if not RequiereLote(ModoTrazabilidadEfectivo(
          Consulta.FieldByName('CODIGO_ART_INVLIN').AsString)) then
          Lote := '';
        if not LocalizarLineaRecuento(Sku, Lote) then
          Lista.Add(Sku + '=' + ValorRecuentoLote(
            Consulta.FieldByName('CANTIDAD_FISICA_INVLIN').AsCurrency,
            Lote,
            Consulta.FieldByName('FECHA_CADUCIDAD_INVLIN').AsDateTime));
        Consulta.Next;
      end;
      ValidarSkusRecuentoMovil(Lista);
      CargarDesdeListaSkus(Lista, False, nil, False);
      Result := cdsLineas.RecordCount - LineasAntes;
      ConfirmarImportacionLineas;
    except
      CancelarImportacionLineas;
      raise;
    end;
  finally
    Lista.Free;
    Consulta.Free;
  end;
end;

procedure TdmInventarios.IniciarImportacionLineas;
begin
  if FAplicacionLineasDiferida then
    raise EInvalidOpException.Create(
      SErrorImportacionInventarioYaIniciada);
  FTransaccionImportacionLineas :=
    not ConexionEscritura.InTransaction;
  if FTransaccionImportacionLineas then
    ConexionEscritura.StartTransaction;
  FAplicacionLineasDiferida := True;
end;

procedure TdmInventarios.MarcarRecuentoRecogido(
  const AClave: TClaveInventario);
begin
  if not FAplicacionLineasDiferida or
     not ConexionEscritura.InTransaction then
    raise EInvalidOpException.Create(
      SErrorMarcaRecuentoSinImportacion);
  CrearRepositorioRecuentoRemotoInventarioUniDAC(
    ConexionEscritura).MarcarRecogido(AClave);
end;

procedure TdmInventarios.ConfirmarImportacionLineas;
begin
  try
    AplicarLineasPendientes;
    if FTransaccionImportacionLineas and
       ConexionEscritura.InTransaction then
      ConexionEscritura.Commit;
  except
    if FTransaccionImportacionLineas and
       ConexionEscritura.InTransaction then
      ConexionEscritura.Rollback;
    FAplicacionLineasDiferida := False;
    FTransaccionImportacionLineas := False;
    raise;
  end;
  FAplicacionLineasDiferida := False;
  FTransaccionImportacionLineas := False;
end;

procedure TdmInventarios.CancelarImportacionLineas;
begin
  try
    if cdsLineas.State in [dsEdit, dsInsert] then
      cdsLineas.Cancel;
    cdsLineas.CancelUpdates;
    if FTransaccionImportacionLineas and
       ConexionEscritura.InTransaction then
      ConexionEscritura.Rollback;
  finally
    FAplicacionLineasDiferida := False;
    FTransaccionImportacionLineas := False;
  end;
end;

// F-LOTEC-014: la línea del recuento es la del SKU con el mismo lote; sin
// lote, la del SKU sin lote (en inventarios sin lotes, la de siempre).
function TdmInventarios.LocalizarLineaRecuento(
  const ASku, ALote: string): Boolean;
var
  oCampoLote: TField;
begin
  Result := False;
  oCampoLote := cdsLineas.FindField('LOTE_INVLIN');
  if oCampoLote = nil then
    Result := cdsLineas.Locate('CODIGO_UNIDAD_INVLIN', ASku,
      [loCaseInsensitive])
  else
  begin
    cdsLineas.First;
    while (not Result) and (not cdsLineas.Eof) do
    begin
      Result := SameText(
          cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString, ASku) and
        MismoLoteRecuento(oCampoLote.AsString, ALote);
      if not Result then
        cdsLineas.Next;
    end;
  end;
end;

// Cargas masivas: una línea por fila de stock (SKU y lote); el lote y su
// caducidad vienen en LOTE y CADUCIDAD de la consulta.
procedure TdmInventarios.AsignarLoteLineaCarga(AConsulta: TDataSet);
begin
  if AConsulta.FieldByName('LOTE').AsString <> '' then
  begin
    cdsLineas.FieldByName('LOTE_INVLIN').AsString :=
      AConsulta.FieldByName('LOTE').AsString;
    if not AConsulta.FieldByName('CADUCIDAD').IsNull then
      cdsLineas.FieldByName('FECHA_CADUCIDAD_INVLIN').AsDateTime :=
        AConsulta.FieldByName('CADUCIDAD').AsDateTime;
  end;
end;

// Teórico del lote en el almacén (su fila de stock); sin lote, el del SKU.
function TdmInventarios.CantidadTeoricaLote(const ASku, ALote: string;
  ACantidadSku: Currency): Currency;
var
  qry: TUniQuery;
begin
  Result := ACantidadSku;
  if ALote <> '' then
  begin
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := ConexionEscritura;
      qry.SQL.Text :=
        'SELECT COALESCE(SUM(CANTIDAD_STK), 0) AS CANTIDAD_STK ' +
        '  FROM fza_articulos_stockactual ' +
        ' WHERE CODIGO_ALM_STK = :ALMACEN ' +
        '   AND CODIGO_UNIDAD_STK = :SKU ' +
        '   AND LOTE_STK = :LOTE';
      qry.ParamByName('ALMACEN').AsString := FCodigoAlmacen;
      qry.ParamByName('SKU').AsString := ASku;
      qry.ParamByName('LOTE').AsString := ALote;
      qry.Open;
      Result := qry.FieldByName('CANTIDAD_STK').AsCurrency;
    finally
      FreeAndNil(qry);
    end;
  end;
end;

function TdmInventarios.CantidadTeoricaLoteLinea(const ASku: string;
  ACantidadSku: Currency): Currency;
var
  oCampoLote: TField;
begin
  Result := ACantidadSku;
  oCampoLote := cdsLineas.FindField('LOTE_INVLIN');
  if (oCampoLote <> nil) and (Trim(oCampoLote.AsString) <> '') then
    Result := CantidadTeoricaLote(ASku, Trim(oCampoLote.AsString),
      ACantidadSku);
end;

function TdmInventarios.ModoTrazabilidadEfectivo(
  const ACodigoArticulo: string): TModoTrazabilidad;
var
  qry: TUniQuery;
begin
  Result := mtNinguna;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionEscritura;
    qry.SQL.Text :=
      'SELECT TIPO_TRAZABILIDAD_ART FROM fza_articulos ' +
      ' WHERE CODIGO_ART_ART = :ARTICULO';
    qry.ParamByName('ARTICULO').AsString := ACodigoArticulo;
    qry.Open;
    if not qry.IsEmpty then
      Result := ActivacionVigente.ModoEfectivo(ModoDesdeCadena(
        qry.FieldByName('TIPO_TRAZABILIDAD_ART').AsString));
  finally
    FreeAndNil(qry);
  end;
end;

// FZ-ISSUE-341: lote o serie leídos en la celda Artículo. El teórico pasa
// a ser el de ese lote; el recuento, 1 si es una serie (la unidad está en
// la mano aunque no conste en stock) o el teórico del lote.
procedure TdmInventarios.EscribirLoteLeidoLinea(
  const ASku, ALote: string;
  AFechaCaducidad: TDate;
  AEsSerie: Boolean);
var
  Teorica, Fisica: Currency;
begin
  if not (cdsLineas.State in [dsEdit, dsInsert]) then
    cdsLineas.Edit;
  cdsLineas.FieldByName('LOTE_INVLIN').AsString := ALote;
  if AFechaCaducidad > SIN_FECHA then
    cdsLineas.FieldByName('FECHA_CADUCIDAD_INVLIN').AsDateTime :=
      AFechaCaducidad;
  Teorica := CantidadTeoricaLote(ASku, ALote,
    cdsLineas.FieldByName('CANTIDAD_TEORICA_INVLIN').AsCurrency);
  if AEsSerie then
    Fisica := 1
  else
    Fisica := Teorica;
  cdsLineas.FieldByName('CANTIDAD_TEORICA_INVLIN').AsCurrency := Teorica;
  cdsLineas.FieldByName('CANTIDAD_FISICA_INVLIN').AsCurrency := Fisica;
  cdsLineas.FieldByName('CANTIDAD_DIFERENCIA_INVLIN').AsCurrency :=
    DiferenciaUnidadesInventario(Fisica, Teorica);
  cdsLineas.FieldByName('TOTAL_COSTE_DIFERENCIA_INVLIN').AsCurrency :=
    DiferenciaCosteInventario(Fisica, Teorica,
      cdsLineas.FieldByName('PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency,
      cdsLineas.FieldByName('PRECIO_MEDIO_INVLIN').AsCurrency);
end;

procedure TdmInventarios.CargarSkuDesdeLista(
  const ASku: string;
  ACantidad: Currency;
  const ALote: string;
  AFechaCaducidad: TDateTime;
  AFechaRecuento: TDateTime;
  AReemplazarCantidad: Boolean;
  AConsulta: TUniQuery);
var
  ArticuloPadre: string;
  Lote: string;
begin
  AConsulta.Close;
  AConsulta.ParamByName('SKU').AsString := ASku;
  AConsulta.Open;
  // Ignorar SKUs que no existen en las cargas generales.
  if not AConsulta.IsEmpty then
  begin
    ArticuloPadre := AConsulta.FieldByName(
      'CODIGO_ART_SKU').AsString;
    // Solo se guarda el lote si el modo efectivo del artículo lo pide con
    // los interruptores vigentes: un lote leído (GS1) de un artículo sin
    // trazabilidad, o con su modo apagado, no parte la línea.
    Lote := '';
    if RequiereLote(ActivacionVigente.ModoEfectivo(ModoDesdeCadena(
         AConsulta.FieldByName('TIPO_TRAZABILIDAD_ART').AsString))) then
      Lote := Trim(ALote);
    unqryStockActual.Close;
    unqryStockActual.ParamByName(
      'ALMACEN').AsString := FCodigoAlmacen;
    unqryStockActual.ParamByName('SKU').AsString := ASku;
    unqryStockActual.Open;

    // En cargas generales se suma; el móvil reemplaza el total.
    if LocalizarLineaRecuento(ASku, Lote) then
    begin
      cdsLineas.Edit;
      if AReemplazarCantidad then
        cdsLineas.FieldByName(
          'CANTIDAD_FISICA_INVLIN').AsCurrency := ACantidad
      else
        cdsLineas.FieldByName(
          'CANTIDAD_FISICA_INVLIN').AsCurrency :=
          cdsLineas.FieldByName(
            'CANTIDAD_FISICA_INVLIN').AsCurrency + ACantidad;
      if AFechaRecuento > 0 then
        cdsLineas.FieldByName(
          'FECHA_RECUENTO_INVLIN').AsDateTime := AFechaRecuento;
      if (Lote <> '') and (AFechaCaducidad > 0) then
        cdsLineas.FieldByName(
          'FECHA_CADUCIDAD_INVLIN').AsDateTime := AFechaCaducidad;
      cdsLineas.Post;
    end
    else
    begin
      cdsLineas.Append;
      cdsLineas.FieldByName(
        'CODIGO_ART_INVLIN').AsString := ArticuloPadre;
      cdsLineas.FieldByName(
        'CODIGO_UNIDAD_INVLIN').AsString := ASku;
      cdsLineas.FieldByName(
        'DESCRIPCION_ARTICULO_INVLIN').AsString :=
        AConsulta.FieldByName('DESCRIPCION_ART').AsString;
      cdsLineas.FieldByName(
        'CANTIDAD_TEORICA_INVLIN').AsCurrency :=
        CantidadTeoricaLote(ASku, Lote,
          unqryStockActual.FieldByName('CANTIDAD_STK').AsCurrency);
      cdsLineas.FieldByName(
        'CANTIDAD_FISICA_INVLIN').AsCurrency := ACantidad;
      cdsLineas.FieldByName(
        'PRECIO_MEDIO_INVLIN').AsCurrency :=
        unqryStockActual.FieldByName('PRECIO_MEDIO_STK').AsCurrency;
      cdsLineas.FieldByName(
        'PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency :=
        unqryStockActual.FieldByName('PRECIO_MEDIO_STK').AsCurrency;
      if Lote <> '' then
      begin
        cdsLineas.FieldByName('LOTE_INVLIN').AsString := Lote;
        if AFechaCaducidad > 0 then
          cdsLineas.FieldByName(
            'FECHA_CADUCIDAD_INVLIN').AsDateTime := AFechaCaducidad;
      end;
      if AFechaRecuento > 0 then
        cdsLineas.FieldByName(
          'FECHA_RECUENTO_INVLIN').AsDateTime := AFechaRecuento
      else
        AsegurarFechaRecuentoLinea;
      cdsLineas.Post;
    end;
  end;
end;

procedure TdmInventarios.CargarDesdeListaSkus(
  ALista: TStringList;
  AReemplazarCantidad: Boolean;
  AInstantesRecuento: TStrings;
  AAplicarCambios: Boolean);
var
  Cantidad: Currency;
  i: Integer;
  Sku: string;
  FechaRecuento: TDateTime;
  Valor: TValorRecuentoLote;
  qry: TUniQuery;
begin
  // Cada línea de la lista: SKU=CANTIDAD[;LOTE[;CADUCIDAD]] (F-LOTEC-014)
  // o bien solo el SKU (cantidad física = 1).
  if GetEstadoInventario <> 'ABIERTO' then
    raise Exception.Create(SErrorCargarArticulosInventarioNoAbierto);

  if Assigned(AInstantesRecuento) then
  begin
    ValidarInstantesRecuentoMovil(ALista, AInstantesRecuento);
    ValidarSkusRecuentoMovil(ALista);
  end;

  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionEscritura;
    qry.SQL.Text :=
      'SELECT s.CODIGO_ART_SKU, a.DESCRIPCION_ART, ' +
      '       a.TIPO_TRAZABILIDAD_ART ' +
      '  FROM fza_articulos_skus s ' +
      '  JOIN fza_articulos a ON a.CODIGO_ART_ART = s.CODIGO_ART_SKU ' +
      ' WHERE s.CODIGO_UNIDAD_SKU = :SKU';

    cdsLineas.DisableControls;
    try
      for i := 0 to ALista.Count - 1 do
      begin
        Sku := ObtenerSkuRecuento(ALista, i);
        if Sku <> '' then
        begin
          Valor := LeerValorRecuentoLote(ALista.ValueFromIndex[i]);
          Cantidad := 1;
          if Valor.TieneCantidad then
            Cantidad := Valor.Cantidad;
          FechaRecuento := 0;
          if Assigned(AInstantesRecuento) then
            if not TryFechaHoraRecuentoNegocio(
                 AInstantesRecuento.Values[Sku],
                 FechaRecuento) then
              FechaRecuento := 0;

          CargarSkuDesdeLista(
            Sku,
            Cantidad,
            Valor.Lote,
            Valor.FechaCaducidad,
            FechaRecuento,
            AReemplazarCantidad,
            qry);
        end;
      end;
      if AAplicarCambios then
        AplicarLineasPendientes;
    finally
      cdsLineas.EnableControls;
    end;
  finally
    FreeAndNil(qry);
  end;
end;


initialization
  RegistrarDataModule(TdmInventarios);
  ForceReferenceToClass(TdmInventarios);
end.
