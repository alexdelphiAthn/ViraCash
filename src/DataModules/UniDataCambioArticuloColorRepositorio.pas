{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataCambioArticuloColorRepositorio                         }
{    Tipo:       Repositorio UniDAC                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       21/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Recodifica artículos o colores y todas sus referencias lógicas.           }
{    Cualquier referencia en líneas de factura veta la operación.              }
{******************************************************************************}
unit UniDataCambioArticuloColorRepositorio;

interface

uses
  Uni,
  inLibCambioArticuloColorIntf,
  UniDataCambioArticuloColorHistorico;

function CrearRepositorioCambioArticuloColorUniDAC(
  AConexion: TUniConnection): IRepositorioCambioArticuloColor;

implementation

uses
  System.SysUtils,
  System.Classes,
  Data.DB;

resourcestring
  SErrorIdentidadArticuloOrigenDestinoCoincidente =
    'Origen y destino son la misma identidad para la base de datos.';
  SErrorArticuloDestinoFusionNoExiste =
    'El artículo destino de la fusión no existe.';
  SErrorCodigoArticuloDestinoReservadoHistorico =
    'El código de artículo destino está reservado por un histórico.';
  SErrorSkuArticuloNoComienzaCodigoAntiguo =
    'Hay SKU que no comienzan por el código de artículo antiguo.';
  SErrorUnidadesArticuloFueraMapaCambio =
    'Hay unidades del artículo antiguo fuera del mapa de cambio.';
  SErrorDatosMaestrosArticulosIncompatibles =
    'Los artículos tienen datos maestros incompatibles.';
  SErrorIdentidadColorOrigenDestinoCoincidente =
    'Origen y destino son el mismo color para la base de datos.';
  SErrorColorOrigenIdentidadesActivas =
    'El color origen tiene más de una identidad activa.';
  SErrorColorDestinoFusionNoExiste =
    'El color destino de la fusión no existe.';
  SErrorColorDestinoIdentidadesActivas =
    'El color destino tiene más de una identidad activa.';
  SErrorColorDestinoReservadoHistorico =
    'El color destino está reservado por un histórico.';
  SErrorReferenciaParcialMultiplesDestinosColor =
    'Una referencia parcial admite más de un destino de color.';
  SErrorSkuSegmentoColorFueraCatalogo =
    'Hay SKU cuyo segmento de color no coincide con el catálogo.';
  SErrorUnidadesDocumentosColorFueraMapaCambio =
    'Hay unidades o documentos de color fuera del mapa de cambio.';
  SErrorInstantaneasColorAmbiguas =
    'Hay instantáneas cuyo atributo de color es ambiguo.';
  SErrorDatosSkuColoresIncompatibles =
    'Los SKU de los colores tienen datos incompatibles.';
  SErrorProcedimientoRecalcularPmpNoDisponible =
    'No está instalado PRC_FZA_FUSION_RECALCULAR_PMP con la firma requerida.';
  SErrorTransaccionCambioArticuloColorActiva =
    'Ya existe una transacción activa en la conexión.';
  SErrorReferenciasCodigoArticuloAntiguoPersisten =
    'Persisten referencias al código de artículo antiguo.';
  SDetalleCambioArticuloColorCompletado =
    'SKU origen inactivos; costes conservados; tarifa más reciente y PMP ' +
    'histórico recalculado.';
  SErrorReferenciasColorAntiguoPersisten =
    'Persisten referencias al color antiguo.';

const
  TABLA_TEMPORAL = 'tmp_fza_cambio_unidades';
  REFERENCIA_SKU_MAESTRO =
    'fza_articulos_skus|CODIGO_UNIDAD_SKU';
  REFERENCIA_ATRIBUTOS_SKU =
    'fza_atributos_sku|CODIGO_UNIDAD_SKU_SA';
  REFERENCIA_COSTES_SKU =
    'fza_articulos_skus_costes|CODIGO_UNIDAD_SKU_SKUC';
  REFERENCIA_STOCK =
    'fza_articulos_stockactual|CODIGO_UNIDAD_STK';
  REFERENCIA_TARIFAS =
    'fza_articulos_tarifas|CODIGO_UNIDAD_ARTTAR';
  REFERENCIA_BARRAS =
    'fza_codigos_barras|CODIGO_UNIDAD_CB';
  REFERENCIA_BLOQUEOS =
    'fza_stock_bloqueos|CODIGO_UNIDAD_STKBLQ';
  REFERENCIA_ARTICULO_SKU =
    'fza_articulos_skus|CODIGO_ART_SKU';
  REFERENCIA_ARTICULO_PROVEEDOR =
    'fza_articulos_proveedores|CODIGO_ART_AP';

  REFERENCIAS_ARTICULO: array[0..30] of string = (
    'fza_articulos_atributos_basicos|CODIGO_ART_AAB',
    'fza_articulos_conjuntos_asign|CODIGO_ART_ACA',
    'fza_articulos_fotos|CODIGO_ART_FOT',
    'fza_articulos_pdte_recibir|CODIGO_ART_PDR',
    'fza_articulos_propiedades|CODIGO_ART_ART',
    'fza_articulos_proveedores|CODIGO_ART_AP',
    'fza_articulos_skus|CODIGO_ART_SKU',
    'fza_articulos_tarifas|CODIGO_ART_ARTTAR',
    'fza_articulos_vinculos|CODIGO_ART_PADRE_ARTVIN',
    'fza_articulos_vinculos|CODIGO_ART_HIJO_ARTVIN',
    'fza_atributos_valores|CODIGO_ART_EXTRA_AV',
    'fza_compras_sesiones_fotos|CODIGO_ART_TENTATIVO_CSF',
    'fza_compras_sesiones_lineas|CODIGO_ART_TENTATIVO_SESLIN',
    'fza_compras_sesiones_lineas|CODIGO_ART_REUSAR_SESLIN',
    'fza_depositos_cliente|CODIGO_ART_DEP',
    'fza_documentos_trabajo_lineas|CODIGO_ART_DTL',
    'fza_inventarios_lineas|CODIGO_ART_INVLIN',
    'fza_inventarios_recuentos|CODIGO_ART_INVREC',
    'fza_movimientos_almacen|CODIGO_ART_MOV',
    'fza_pedidos_compra_lineas|CODIGO_ART_PEDCLIN',
    'fza_albaranes_compra_lineas|CODIGO_ART_ALBCLIN',
    'fza_devoluciones_compra_lineas|CODIGO_ART_DEVCLIN',
    'fza_facturas_compra_lineas|CODIGO_ART_FACCLIN',
    'fza_pedidos_lineas|CODIGO_ART_PEDLIN',
    'fza_albaranes_lineas|CODIGO_ART_ALBLIN',
    'fza_proformas_caja_lineas|CODIGO_ART_PROCLIN',
    'fza_tarifas_cambios_lineas|CODIGO_ART_TARCLIN',
    'fza_traspasos_propuestas_lineas|CODIGO_ART_TRPROLIN',
    'fza_traspasos_solicitudes_lineas|CODIGO_ART_TRSOLLIN',
    'inv_catalogo|codigo_articulo',
    'inv_eventos|codigo_articulo'
  );

  REFERENCIAS_UNIDAD: array[0..27] of string = (
    'fza_articulos_fotos|CODIGO_UNIDAD_FOT',
    'fza_articulos_pdte_recibir|CODIGO_UNIDAD_PDR',
    'fza_articulos_propiedades|CODIGO_UNIDAD_ARTPROP',
    'fza_articulos_skus|CODIGO_UNIDAD_SKU',
    'fza_articulos_skus_costes|CODIGO_UNIDAD_SKU_SKUC',
    'fza_stock_bloqueos|CODIGO_UNIDAD_STKBLQ',
    'fza_articulos_stockactual|CODIGO_UNIDAD_STK',
    'fza_articulos_tarifas|CODIGO_UNIDAD_ARTTAR',
    'fza_atributos_sku|CODIGO_UNIDAD_SKU_SA',
    'fza_codigos_barras|CODIGO_UNIDAD_CB',
    'fza_compras_sesiones_fotos|CODIGO_UNIDAD_CSF',
    'fza_depositos_cliente|CODIGO_UNIDAD_DEP',
    'fza_documentos_trabajo_lineas|CODIGO_UNIDAD_DTL',
    'fza_inventarios_lineas|CODIGO_UNIDAD_INVLIN',
    'fza_inventarios_recuentos|CODIGO_UNIDAD_INVREC',
    'fza_movimientos_almacen|CODIGO_UNIDAD_MOV',
    'fza_pedidos_compra_lineas|CODIGO_UNIDAD_PEDCLIN',
    'fza_albaranes_compra_lineas|CODIGO_UNIDAD_ALBCLIN',
    'fza_devoluciones_compra_lineas|CODIGO_UNIDAD_DEVCLIN',
    'fza_facturas_compra_lineas|CODIGO_UNIDAD_FACCLIN',
    'fza_pedidos_lineas|CODIGO_UNIDAD_PEDLIN',
    'fza_albaranes_lineas|CODIGO_UNIDAD_ALBLIN',
    'fza_proformas_caja_lineas|CODIGO_UNIDAD_PROCLIN',
    'fza_tarifas_cambios_lineas|CODIGO_UNIDAD_SKU_TARCLIN',
    'fza_traspasos_propuestas_lineas|CODIGO_UNIDAD_TRPROLIN',
    'fza_traspasos_solicitudes_lineas|CODIGO_UNIDAD_TRSOLLIN',
    'inv_catalogo|codigo_unidad',
    'inv_eventos|codigo_unidad'
  );

  REFERENCIAS_ATRIBUTOS: array[0..6] of string = (
    'fza_albaranes_compra_lineas|CODIGO_UNIDAD_ALBCLIN|ALBCLIN',
    'fza_albaranes_lineas|CODIGO_UNIDAD_ALBLIN|ALBLIN',
    'fza_devoluciones_compra_lineas|CODIGO_UNIDAD_DEVCLIN|DEVCLIN',
    'fza_documentos_trabajo_lineas|CODIGO_UNIDAD_DTL|DTL',
    'fza_facturas_compra_lineas|CODIGO_UNIDAD_FACCLIN|FACCLIN',
    'fza_pedidos_compra_lineas|CODIGO_UNIDAD_PEDCLIN|PEDCLIN',
    'fza_pedidos_lineas|CODIGO_UNIDAD_PEDLIN|PEDLIN'
  );

type
  TDestinoPmp = record
    Empresa: string;
    Almacen: string;
    Sku: string;
  end;

  TDestinosPmp = array of TDestinoPmp;

  TAccesoCambioArticuloColorUniDAC = class(TInterfacedObject)
  protected
    FConexion: TUniConnection;
    procedure Ejecutar(
      const ASql: string;
      const ANombres, AValores: array of string);
    function Existe(
      const ASql: string;
      const ANombres, AValores: array of string): Boolean;
    function EscalarEntero(
      const ASql: string;
      const ANombres, AValores: array of string): Integer;
    function CampoExiste(
      const ATabla, ACampo: string): Boolean;
    procedure SepararReferencia(
      const AReferencia: string;
      out ATabla, ACampo: string);
    procedure SepararReferenciaAtributos(
      const AReferencia: string;
      out ATabla, ACampoUnidad, ASufijo: string);
    function CondicionInstantaneaColor(
      const AAlias, ACampoValor, ACampoNombre, AParametro: string): string;
    function ExpresionConteoValoresAtributos(
      const ATabla, AAlias, ASufijo, AParametro: string): string;
    function CondicionInstantaneaColorSegura(
      const AAlias, ACampoValor, ACampoNombre, AParametro: string;
      APosicion: Integer): string;
  public
    constructor Create(AConexion: TUniConnection);
  end;

  TValidadorCambioArticuloColorUniDAC = class(
    TAccesoCambioArticuloColorUniDAC)
  private
    procedure BloquearArticulos(
      const AArticuloAntiguo, AArticuloNuevo: string);
    procedure BloquearColores(
      const AColorAntiguo, AColorNuevo: string);
    function ExisteArticulo(const AArticulo: string): Boolean;
    function ExisteColor(const AColor: string): Boolean;
    function NumeroColoresActivos(const AColor: string): Integer;
    function ArticuloRegistrado(const AArticulo: string): Boolean;
    function ColorRegistrado(const AColor: string): Boolean;
    function ArticulosCoincidenEnBaseDatos(
      const AAnterior, ANuevo: string): Boolean;
    function ColoresCoincidenEnBaseDatos(
      const AAnterior, ANuevo: string): Boolean;
    function SqlSkusConPosicionColor: string;
    procedure ConstruirMapaArticulo(
      const AArticuloAntiguo, AArticuloNuevo: string);
    procedure AgregarMapaArticuloReferencias(
      const AArticuloAntiguo, AArticuloNuevo: string);
    procedure ConstruirMapaColor(
      const AColorAntiguo, AColorNuevo: string);
    function SqlCandidatosColorReferencia(
      const ATabla, ACampo: string): string;
    procedure AgregarMapaColorReferencias(
      const AColorAntiguo, AColorNuevo: string);
    function HayMapaColorReferenciasAmbiguo(
      const AColorAntiguo, AColorNuevo: string): Boolean;
    function NumeroSkuMapa: Integer;
    function MapaArticuloEsCompleto(
      const AArticuloAntiguo: string): Boolean;
    function MapaColorEsCompleto(
      const AColorAntiguo: string): Boolean;
    function MapaTieneCodigosLargos: Boolean;
    function MapaTieneDestinosDuplicados: Boolean;
    function FusionUnidadesEsSegura(
      const AColorDestino, AArticuloDestino: string;
      AEsFusionArticulo: Boolean): Boolean;
    function HayColisionUnidadesNoConsolidable(
      const AArticuloDestino: string;
      AEsFusionArticulo: Boolean): Boolean;
    function HayVentasArticulo(
      const AArticuloAntiguo: string): Boolean;
    function HayVentasColor(const AColorAntiguo: string): Boolean;
    function HayDestinoEnVentasArticulo(
      const AArticuloNuevo: string): Boolean;
    function HayDestinoEnVentasColor(
      const AColorNuevo: string): Boolean;
    function HayDestinoMapaEnVentas: Boolean;
    function HayPrestaShopArticulo(
      const AArticuloAntiguo: string): Boolean;
    function HayPrestaShopColor(
      const AColorAntiguo: string): Boolean;
    function HayDestinoEnReferencias(
      const AReferencias: array of string): Boolean;
    function HayOrigenEnReferencias(
      const AReferencias: array of string): Boolean;
    function HayUnidadesArticuloSinMapa(
      const AArticuloAntiguo: string): Boolean;
    function HayUnidadesColorSinMapa(
      const AColorAntiguo: string): Boolean;
    function FusionColorEsSegura(
      const AAnterior, ANuevo: string): Boolean;
    function FusionArticuloEsSegura(
      const AAnterior, ANuevo: string): Boolean;
    function HayInstantaneasColorAntiguo(
      const AColorAntiguo: string): Boolean;
    function HayInstantaneasColorSinMapa(
      const AColorAntiguo: string): Boolean;
    function HayInstantaneasColorAmbiguas(
      const AColorAntiguo: string): Boolean;
    function HayDescripcionesColorAmbiguas(
      const AColorAntiguo, AColorNuevo: string): Boolean;
  public
    function ValidarCambioArticulo(
      const AAnterior, ANuevo: string;
      AFusionar: Boolean): TResultadoCambioArticuloColor;
    function ValidarCambioColor(
      const AAnterior, ANuevo: string;
      AFusionar: Boolean): TResultadoCambioArticuloColor;
    function VerificarCambioArticulo(
      const AArticuloAntiguo: string): Boolean;
    function VerificarCambioColor(
      const AColorAntiguo: string): Boolean;
  end;

  TRepositorioCambioArticuloColorUniDAC = class(
    TAccesoCambioArticuloColorUniDAC,
    IRepositorioCambioArticuloColor)
  private
    FValidador: TValidadorCambioArticuloColorUniDAC;
    function LiteralTextoHistorico(const AValor: string): string;
    function ListaUnidadesHistorico: string;
    procedure CapturarHistorico(
      AHistorico: THistoricoCambioArticuloColor;
      const AOrigen, ADestino: string;
      AEsArticulo: Boolean);
    procedure PrepararTablaTemporal;
    procedure EliminarTablaTemporal;
    procedure IniciarTransaccion;
    procedure FinalizarTransaccion(
      const AResultado: TResultadoCambioArticuloColor);
    procedure ActualizarCampoPorValor(
      const ATabla, ACampo, AAnterior, ANuevo, AUsuario: string);
    procedure ActualizarCampoPorMapa(
      const ATabla, ACampo, AUsuario: string);
    procedure ActualizarReferenciasArticulo(
      const AAnterior, ANuevo, AUsuario: string);
    procedure ActualizarReferenciasUnidad(const AUsuario: string);
    procedure CrearArticuloDestino(
      const AAnterior, ANuevo, AUsuario: string);
    procedure CrearSkuDestino(
      const AArticuloDestino, AUsuario: string;
      AEsCambioArticulo: Boolean);
    procedure PrepararAtributosSkuDestino(
      const AColorDestino, AUsuario: string;
      AEsFusionColor: Boolean);
    procedure ConsolidarStock;
    procedure ConsolidarCostes(const AUsuario: string);
    procedure ConsolidarTarifas(
      const AArticuloOrigen, AArticuloDestino, AUsuario: string;
      AEsCambioArticulo: Boolean);
    procedure ConsolidarProveedoresArticulo(
      const AArticuloOrigen, AArticuloDestino, AUsuario: string);
    procedure ConsolidarCodigosBarras(const AUsuario: string);
    procedure ConsolidarBloqueos(const AUsuario: string);
    function ProcedimientoPmpFusionDisponible: Boolean;
    procedure RecalcularPmpDestinos;
    procedure ConsolidarReferenciasUnidad(const AUsuario: string);
    procedure DesactivarSkuOrigen(const AUsuario: string);
    procedure EliminarAtributosSkuOrigen;
    procedure DesactivarArticuloMaestro(
      const AArticuloAntiguo, AUsuario: string);
    procedure ActualizarColorMaestro(
      const AAnterior, ANuevo, AUsuario: string;
      AFusionar: Boolean);
    procedure LimpiarBasicosColorFusion(
      const AColorAntiguo, AColorDestino, AUsuario: string);
    procedure ConsolidarCatalogoColor(
      const AColorAntiguo, AColorDestino, AUsuario: string);
    procedure PrepararFusionArticulo(
      const AAnterior, ANuevo: string);
    function SqlActualizacionAtributos(
      const ATabla, ACampoUnidad, ASufijo: string): string;
    function SqlActualizacionDescripcion(
      const ATabla, ACampoUnidad, ASufijo: string): string;
    procedure ActualizarInstantaneasColor(
      const AAnterior, ANuevo, AUsuario: string);
    function EjecutarCambioArticulo(
      const AArticuloAntiguo, AArticuloNuevo, AUsuario: string;
      AFusionar: Boolean): TResultadoCambioArticuloColor;
    function EjecutarCambioColor(
      const AColorAntiguo, AColorNuevo, AUsuario: string;
      AFusionar: Boolean): TResultadoCambioArticuloColor;
  public
    constructor Create(AConexion: TUniConnection);
    destructor Destroy; override;
    function CambiarArticulo(
      const AArticuloAntiguo, AArticuloNuevo, AUsuario: string):
      TResultadoCambioArticuloColor;
    function FusionarArticulo(
      const AArticuloAntiguo, AArticuloDestino, AUsuario: string):
      TResultadoCambioArticuloColor;
    function CambiarColor(
      const AColorAntiguo, AColorNuevo, AUsuario: string):
      TResultadoCambioArticuloColor;
    function FusionarColor(
      const AColorAntiguo, AColorDestino, AUsuario: string):
      TResultadoCambioArticuloColor;
    function RevertirOperacion(
      const AIdOperacion, AUsuario: string):
      TResultadoReversionHistorico;
  end;

constructor TAccesoCambioArticuloColorUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

constructor TRepositorioCambioArticuloColorUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create(AConexion);
  FValidador := TValidadorCambioArticuloColorUniDAC.Create(AConexion);
end;

destructor TRepositorioCambioArticuloColorUniDAC.Destroy;
begin
  FValidador.Free;
  inherited Destroy;
end;

procedure TAccesoCambioArticuloColorUniDAC.Ejecutar(
  const ASql: string;
  const ANombres, AValores: array of string);
var
  i: Integer;
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    for i := Low(ANombres) to High(ANombres) do
      if oConsulta.Params.FindParam(ANombres[i]) <> nil then
      begin
        oConsulta.ParamByName(ANombres[i]).AsString := AValores[i];
      end;
    oConsulta.ExecSQL;
  finally
    oConsulta.Free;
  end;
end;

function TAccesoCambioArticuloColorUniDAC.Existe(
  const ASql: string;
  const ANombres, AValores: array of string): Boolean;
var
  i: Integer;
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    for i := Low(ANombres) to High(ANombres) do
      if oConsulta.Params.FindParam(ANombres[i]) <> nil then
      begin
        oConsulta.ParamByName(ANombres[i]).AsString := AValores[i];
      end;
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
  finally
    oConsulta.Free;
  end;
end;

function TAccesoCambioArticuloColorUniDAC.EscalarEntero(
  const ASql: string;
  const ANombres, AValores: array of string): Integer;
var
  i: Integer;
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    for i := Low(ANombres) to High(ANombres) do
      if oConsulta.Params.FindParam(ANombres[i]) <> nil then
      begin
        oConsulta.ParamByName(ANombres[i]).AsString := AValores[i];
      end;
    oConsulta.Open;
    Result := oConsulta.Fields[0].AsInteger;
  finally
    oConsulta.Free;
  end;
end;

function TAccesoCambioArticuloColorUniDAC.CampoExiste(
  const ATabla, ACampo: string): Boolean;
const
  SQL_CAMPO_EXISTE =
    'SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS ' +
    'WHERE TABLE_SCHEMA = DATABASE() ' +
    'AND TABLE_NAME = :TABLA AND COLUMN_NAME = :CAMPO LIMIT 1';
begin
  Result := Existe(
    SQL_CAMPO_EXISTE,
    ['TABLA', 'CAMPO'],
    [ATabla, ACampo]);
end;

procedure TAccesoCambioArticuloColorUniDAC.SepararReferencia(
  const AReferencia: string;
  out ATabla, ACampo: string);
var
  iSeparador: Integer;
begin
  iSeparador := Pos('|', AReferencia);
  ATabla := Copy(AReferencia, 1, iSeparador - 1);
  ACampo := Copy(AReferencia, iSeparador + 1, MaxInt);
end;

procedure TAccesoCambioArticuloColorUniDAC.
  SepararReferenciaAtributos(
    const AReferencia: string;
    out ATabla, ACampoUnidad, ASufijo: string);
var
  iPrimerSeparador: Integer;
  iSegundoSeparador: Integer;
begin
  iPrimerSeparador := Pos('|', AReferencia);
  iSegundoSeparador := Pos(
    '|',
    AReferencia,
    iPrimerSeparador + 1);
  ATabla := Copy(AReferencia, 1, iPrimerSeparador - 1);
  ACampoUnidad := Copy(
    AReferencia,
    iPrimerSeparador + 1,
    iSegundoSeparador - iPrimerSeparador - 1);
  ASufijo := Copy(AReferencia, iSegundoSeparador + 1, MaxInt);
end;

function TAccesoCambioArticuloColorUniDAC.
  CondicionInstantaneaColor(
    const AAlias, ACampoValor, ACampoNombre, AParametro: string): string;
begin
  Result := '(TRIM(' + AAlias + '.`' + ACampoValor + '`) = TRIM(:' +
    AParametro + ') AND (UPPER(TRIM(' + AAlias + '.`' +
    ACampoNombre + '`)) IN (''COLOR'', ''CO'') OR EXISTS (' +
    'SELECT 1 FROM `fza_variaciones_atributos` va ' +
    'WHERE va.`ID_ATB_VA` = ''CO'' AND UPPER(TRIM(va.`NOMBRE_VA`)) = ' +
    'UPPER(TRIM(' + AAlias + '.`' + ACampoNombre + '`)))))';
end;

function TAccesoCambioArticuloColorUniDAC.
  ExpresionConteoValoresAtributos(
    const ATabla, AAlias, ASufijo, AParametro: string): string;
var
  i: Integer;
  sCampo: string;
  sExpresion: string;
  sSeparador: string;
begin
  sExpresion := '';
  sSeparador := '';
  for i := 1 to 5 do
  begin
    sCampo := 'ATTR' + IntToStr(i) + '_VALOR_' + ASufijo;
    if CampoExiste(ATabla, sCampo) then
    begin
      sExpresion := sExpresion + sSeparador +
        'CASE WHEN TRIM(' + AAlias + '.`' + sCampo + '`) = TRIM(:' +
        AParametro + ') THEN 1 ELSE 0 END';
      sSeparador := ' + ';
    end;
  end;
  if sExpresion = '' then
    sExpresion := '0';
  Result := '(' + sExpresion + ')';
end;

function TAccesoCambioArticuloColorUniDAC.
  CondicionInstantaneaColorSegura(
    const AAlias, ACampoValor, ACampoNombre, AParametro: string;
    APosicion: Integer): string;
begin
  Result := '(TRIM(' + AAlias + '.`' + ACampoValor + '`) = TRIM(:' +
    AParametro + ') AND mapa.`POSICION_COLOR` = ' +
    IntToStr(APosicion) + ' AND (TRIM(COALESCE(' + AAlias + '.`' +
    ACampoNombre + '`, '''')) = '''' OR UPPER(TRIM(' + AAlias + '.`' +
    ACampoNombre + '`)) IN (''COLOR'', ''CO'') OR EXISTS (' +
    'SELECT 1 FROM `fza_variaciones_atributos` va ' +
    'WHERE va.`ID_ATB_VA` = ''CO'' AND UPPER(TRIM(va.`NOMBRE_VA`)) = ' +
    'UPPER(TRIM(' + AAlias + '.`' + ACampoNombre + '`)))))';
end;

function TRepositorioCambioArticuloColorUniDAC.LiteralTextoHistorico(
  const AValor: string): string;
var
  byValor: TBytes;
  i: Integer;
  sHexadecimal: string;
begin
  byValor := TEncoding.UTF8.GetBytes(AValor);
  sHexadecimal := '';
  for i := 0 to Length(byValor) - 1 do
    sHexadecimal := sHexadecimal + IntToHex(byValor[i], 2);
  Result := 'CONVERT(UNHEX(''' + sHexadecimal +
    ''') USING utf8mb4)';
end;

function TRepositorioCambioArticuloColorUniDAC.
  ListaUnidadesHistorico: string;
var
  oConsulta: TUniQuery;
  sSeparador: string;
begin
  Result := '';
  sSeparador := '';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT DISTINCT `CODIGO` FROM (SELECT HEX(`ORIGEN`) `CODIGO` ' +
      'FROM `' + TABLA_TEMPORAL + '` UNION SELECT HEX(`DESTINO`) ' +
      '`CODIGO` FROM `' + TABLA_TEMPORAL + '`) unidades ' +
      'ORDER BY `CODIGO`';
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      Result := Result + sSeparador + 'CONVERT(UNHEX(''' +
        oConsulta.FieldByName('CODIGO').AsString +
        ''') USING utf8mb4)';
      sSeparador := ', ';
      oConsulta.Next;
    end;
  finally
    oConsulta.Free;
  end;
  if Result = '' then
    Result := 'NULL';
end;

procedure TRepositorioCambioArticuloColorUniDAC.CapturarHistorico(
  AHistorico: THistoricoCambioArticuloColor;
  const AOrigen, ADestino: string;
  AEsArticulo: Boolean);
var
  i: Integer;
  iPosicion: Integer;
  sCampo: string;
  sCondicion: string;
  sDestinoSql: string;
  sListaUnidades: string;
  sOrigenSql: string;
  sTabla: string;
  stCondiciones: TStringList;

  procedure AgregarCondicion(
    const ATabla, ACondicion: string);
  var
    iIndice: Integer;
  begin
    iIndice := stCondiciones.IndexOfName(ATabla);
    if iIndice < 0 then
      stCondiciones.Add(ATabla + '=' + ACondicion)
    else
      stCondiciones.ValueFromIndex[iIndice] :=
        '(' + stCondiciones.ValueFromIndex[iIndice] + ') OR (' +
        ACondicion + ')';
  end;

  procedure AgregarReferenciaArticulo(const AReferencia: string);
  begin
    SepararReferencia(AReferencia, sTabla, sCampo);
    if CampoExiste(sTabla, sCampo) then
    begin
      AgregarCondicion(
        sTabla,
        '`' + sCampo + '` IN (' + sOrigenSql + ', ' +
        sDestinoSql + ')');
    end;
  end;

  procedure AgregarReferenciaUnidad(const AReferencia: string);
  begin
    SepararReferencia(AReferencia, sTabla, sCampo);
    if CampoExiste(sTabla, sCampo) then
    begin
      AgregarCondicion(
        sTabla,
        '`' + sCampo + '` IN (' + sListaUnidades + ')');
    end;
  end;

begin
  if not Assigned(AHistorico) then
    raise EArgumentNilException.Create('AHistorico');
  sOrigenSql := LiteralTextoHistorico(AOrigen);
  sDestinoSql := LiteralTextoHistorico(ADestino);
  sListaUnidades := ListaUnidadesHistorico;
  stCondiciones := TStringList.Create;
  try
    stCondiciones.CaseSensitive := False;
    stCondiciones.NameValueSeparator := '=';
    if AEsArticulo then
    begin
      AgregarCondicion(
        'fza_articulos',
        '`CODIGO_ART_ART` IN (' + sOrigenSql + ', ' +
        sDestinoSql + ')');
      AgregarCondicion(
        'fza_articulos_skus',
        '`CODIGO_ART_SKU` IN (' + sOrigenSql + ', ' +
        sDestinoSql + ')');
    end
    else
    begin
      AgregarCondicion(
        'fza_atributos_valores',
        '`ID_VA_AV` = ''CO'' AND (TRIM(`AV`) = TRIM(' +
        sOrigenSql + ') OR TRIM(`AV`) = TRIM(' + sDestinoSql + '))');
    end;
    AgregarReferenciaUnidad(REFERENCIA_SKU_MAESTRO);
    AgregarReferenciaUnidad(REFERENCIA_ATRIBUTOS_SKU);
    if AEsArticulo then
    begin
      for i := Low(REFERENCIAS_ARTICULO) to
        High(REFERENCIAS_ARTICULO) do
      begin
        AgregarReferenciaArticulo(REFERENCIAS_ARTICULO[i]);
      end;
    end;
    for i := Low(REFERENCIAS_UNIDAD) to High(REFERENCIAS_UNIDAD) do
      AgregarReferenciaUnidad(REFERENCIAS_UNIDAD[i]);
    if not AEsArticulo then
    begin
      sCondicion :=
        '`ID_AV_AAB` IN (SELECT `ID_AV` FROM ' +
        '`fza_atributos_valores` WHERE `ID_VA_AV` = ''CO'' AND (' +
        'TRIM(`AV`) = TRIM(' + sOrigenSql + ') OR ' +
        'TRIM(`AV`) = TRIM(' + sDestinoSql + ')))';
      AgregarCondicion(
        'fza_articulos_atributos_basicos',
        sCondicion);
      sCondicion :=
        '`ID_AV_ACD` IN (SELECT `ID_AV` FROM ' +
        '`fza_atributos_valores` WHERE `ID_VA_AV` = ''CO'' AND (' +
        'TRIM(`AV`) = TRIM(' + sOrigenSql + ') OR ' +
        'TRIM(`AV`) = TRIM(' + sDestinoSql + ')))';
      AgregarCondicion(
        'fza_atributos_conjuntos_det',
        sCondicion);
    end;
    for i := 0 to stCondiciones.Count - 1 do
    begin
      iPosicion := Pos('=', stCondiciones[i]);
      sTabla := Copy(stCondiciones[i], 1, iPosicion - 1);
      sCondicion := Copy(
        stCondiciones[i],
        iPosicion + 1,
        MaxInt);
      AHistorico.CapturarAntes(sTabla, sCondicion, [], []);
    end;
  finally
    stCondiciones.Free;
  end;
end;

procedure TRepositorioCambioArticuloColorUniDAC.PrepararTablaTemporal;
begin
  EliminarTablaTemporal;
  Ejecutar(
    'CREATE TEMPORARY TABLE `' + TABLA_TEMPORAL + '` (' +
    '`ORIGEN` varchar(255) NOT NULL, ' +
    '`DESTINO` varchar(255) NOT NULL, ' +
    '`ES_SKU` char(1) NOT NULL DEFAULT ''S'', ' +
    '`DESTINO_EXISTIA` char(1) NOT NULL DEFAULT ''N'', ' +
    '`POSICION_COLOR` smallint NULL, ' +
    'PRIMARY KEY (`ORIGEN`), KEY `IDX_DESTINO` (`DESTINO`)' +
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ' +
    'COLLATE=utf8mb4_spanish_ci',
    [],
    []);
end;

procedure TRepositorioCambioArticuloColorUniDAC.EliminarTablaTemporal;
begin
  Ejecutar(
    'DROP TEMPORARY TABLE IF EXISTS `' + TABLA_TEMPORAL + '`',
    [],
    []);
end;

procedure TRepositorioCambioArticuloColorUniDAC.IniciarTransaccion;
begin
  Ejecutar(
    'SET TRANSACTION ISOLATION LEVEL SERIALIZABLE',
    [],
    []);
  FConexion.StartTransaction;
end;

procedure TRepositorioCambioArticuloColorUniDAC.FinalizarTransaccion(
  const AResultado: TResultadoCambioArticuloColor);
begin
  if AResultado.EsCorrecto then
    FConexion.Commit
  else
    FConexion.Rollback;
end;

procedure TValidadorCambioArticuloColorUniDAC.BloquearArticulos(
  const AArticuloAntiguo, AArticuloNuevo: string);
begin
  Existe(
    'SELECT `CODIGO_ART_ART` FROM `fza_articulos` ' +
    'WHERE `CODIGO_ART_ART` IN (:ANTERIOR, :NUEVO) FOR UPDATE',
    ['ANTERIOR', 'NUEVO'],
    [AArticuloAntiguo, AArticuloNuevo]);
end;

procedure TValidadorCambioArticuloColorUniDAC.BloquearColores(
  const AColorAntiguo, AColorNuevo: string);
begin
  Existe(
    'SELECT `ID_AV` FROM `fza_atributos_valores` ' +
    'WHERE `ID_VA_AV` = ''CO'' ' +
    'AND TRIM(`AV`) IN (TRIM(:ANTERIOR), TRIM(:NUEVO)) FOR UPDATE',
    ['ANTERIOR', 'NUEVO'],
    [AColorAntiguo, AColorNuevo]);
end;

function TValidadorCambioArticuloColorUniDAC.ExisteArticulo(
  const AArticulo: string): Boolean;
begin
  Result := Existe(
    'SELECT 1 FROM `fza_articulos` ' +
    'WHERE `CODIGO_ART_ART` = :ARTICULO ' +
    'AND UPPER(TRIM(COALESCE(`ESACTIVO_ART`, ''N''))) = ''S'' LIMIT 1',
    ['ARTICULO'],
    [AArticulo]);
end;

function TValidadorCambioArticuloColorUniDAC.ExisteColor(
  const AColor: string): Boolean;
begin
  Result := Existe(
    'SELECT 1 FROM `fza_atributos_valores` ' +
    'WHERE `ID_VA_AV` = ''CO'' AND TRIM(`AV`) = TRIM(:COLOR) ' +
    'AND UPPER(TRIM(COALESCE(`ESACTIVO_AV`, ''N''))) = ''S'' LIMIT 1',
    ['COLOR'],
    [AColor]);
end;

function TValidadorCambioArticuloColorUniDAC.NumeroColoresActivos(
  const AColor: string): Integer;
begin
  Result := EscalarEntero(
    'SELECT COUNT(*) FROM `fza_atributos_valores` ' +
    'WHERE `ID_VA_AV` = ''CO'' AND TRIM(`AV`) = TRIM(:COLOR) ' +
    'AND UPPER(TRIM(COALESCE(`ESACTIVO_AV`, ''N''))) = ''S''',
    ['COLOR'],
    [AColor]);
end;

function TValidadorCambioArticuloColorUniDAC.ArticuloRegistrado(
  const AArticulo: string): Boolean;
begin
  Result := Existe(
    'SELECT 1 FROM `fza_articulos` WHERE ' +
    '`CODIGO_ART_ART` = :ARTICULO LIMIT 1',
    ['ARTICULO'],
    [AArticulo]);
end;

function TValidadorCambioArticuloColorUniDAC.ColorRegistrado(
  const AColor: string): Boolean;
begin
  Result := Existe(
    'SELECT 1 FROM `fza_atributos_valores` WHERE ' +
    '`ID_VA_AV` = ''CO'' AND TRIM(`AV`) = TRIM(:COLOR) LIMIT 1',
    ['COLOR'],
    [AColor]);
end;

function TValidadorCambioArticuloColorUniDAC.
  ArticulosCoincidenEnBaseDatos(
    const AAnterior, ANuevo: string): Boolean;
begin
  Result := Existe(
    'SELECT 1 FROM `fza_articulos` WHERE ' +
    '`CODIGO_ART_ART` = :ANTERIOR AND ' +
    '`CODIGO_ART_ART` = :NUEVO LIMIT 1',
    ['ANTERIOR', 'NUEVO'],
    [AAnterior, ANuevo]);
end;

function TValidadorCambioArticuloColorUniDAC.
  ColoresCoincidenEnBaseDatos(
    const AAnterior, ANuevo: string): Boolean;
begin
  Result := Existe(
    'SELECT 1 FROM `fza_atributos_valores` WHERE ' +
    '`ID_VA_AV` = ''CO'' AND TRIM(`AV`) = TRIM(:ANTERIOR) AND ' +
    'TRIM(`AV`) = TRIM(:NUEVO) LIMIT 1',
    ['ANTERIOR', 'NUEVO'],
    [AAnterior, ANuevo]);
end;

function TValidadorCambioArticuloColorUniDAC.SqlSkusConPosicionColor:
  string;
var
  sOrdenColor: string;
  sOrdenEmpate: string;
  sOrdenPrevio: string;
begin
  sOrdenColor := '(CASE WHEN color.`ORDEN_ACA` = 0 THEN ' +
    'COALESCE(va_color.`ORDEN_VA`, -2147483648) ELSE ' +
    'color.`ORDEN_ACA` END)';
  sOrdenEmpate := '(CASE WHEN empate.`ORDEN_ACA` = 0 THEN ' +
    'COALESCE(va_empate.`ORDEN_VA`, -2147483648) ELSE ' +
    'empate.`ORDEN_ACA` END)';
  sOrdenPrevio := '(CASE WHEN orden.`ORDEN_ACA` = 0 THEN ' +
    'COALESCE(va_orden.`ORDEN_VA`, -2147483648) ELSE ' +
    'orden.`ORDEN_ACA` END)';
  Result := 'SELECT sku.`CODIGO_UNIDAD_SKU` `CODIGO_UNIDAD`, ' +
    'sku.`CODIGO_ART_SKU` `CODIGO_ARTICULO`, ' +
    '(1 + (SELECT COUNT(*) FROM ' +
    '`fza_articulos_conjuntos_asign` orden ' +
    'JOIN `fza_variaciones_atributos` va_orden ON ' +
    'va_orden.`ID_ATB_VA` = orden.`ID_VA_ACA` AND ' +
    'va_orden.`ID_VAR_VA` = sku.`CODIGO_VAR_SKU` ' +
    'WHERE orden.`CODIGO_ART_ACA` = sku.`CODIGO_ART_SKU` AND ' +
    '(' + sOrdenPrevio + ' < ' + sOrdenColor + ' OR (' +
    sOrdenPrevio + ' = ' + sOrdenColor + ' AND ' +
    'COALESCE(va_orden.`ORDEN_VA`, -2147483648) < ' +
    'COALESCE(va_color.`ORDEN_VA`, -2147483648))))) ' +
    '`POSICION_COLOR`, (SELECT COUNT(*) FROM ' +
    '`fza_articulos_conjuntos_asign` dimensiones ' +
    'JOIN `fza_variaciones_atributos` va_dimension ON ' +
    'va_dimension.`ID_ATB_VA` = dimensiones.`ID_VA_ACA` AND ' +
    'va_dimension.`ID_VAR_VA` = sku.`CODIGO_VAR_SKU` ' +
    'WHERE dimensiones.`CODIGO_ART_ACA` = sku.`CODIGO_ART_SKU`) ' +
    '`NUM_ATRIBUTOS`, (SELECT COUNT(*) FROM ' +
    '`fza_articulos_conjuntos_asign` empate ' +
    'JOIN `fza_variaciones_atributos` va_empate ON ' +
    'va_empate.`ID_ATB_VA` = empate.`ID_VA_ACA` AND ' +
    'va_empate.`ID_VAR_VA` = sku.`CODIGO_VAR_SKU` ' +
    'WHERE empate.`CODIGO_ART_ACA` = sku.`CODIGO_ART_SKU` AND ' +
    'empate.`ID_VA_ACA` <> ''CO'' AND ' +
    sOrdenEmpate + ' = ' + sOrdenColor + ' AND ' +
    'COALESCE(va_empate.`ORDEN_VA`, -2147483648) = ' +
    'COALESCE(va_color.`ORDEN_VA`, -2147483648)) `ORDEN_AMBIGUO` ' +
    'FROM `fza_articulos_skus` sku ' +
    'JOIN `fza_articulos_conjuntos_asign` color ON ' +
    'color.`CODIGO_ART_ACA` = sku.`CODIGO_ART_SKU` AND ' +
    'color.`ID_VA_ACA` = ''CO'' ' +
    'JOIN `fza_variaciones_atributos` va_color ON ' +
    'va_color.`ID_VAR_VA` = sku.`CODIGO_VAR_SKU` AND ' +
    'va_color.`ID_ATB_VA` = ''CO''';
end;

procedure TValidadorCambioArticuloColorUniDAC.ConstruirMapaArticulo(
  const AArticuloAntiguo, AArticuloNuevo: string);
begin
  Ejecutar(
    'INSERT INTO `' + TABLA_TEMPORAL + '` ' +
    '(`ORIGEN`, `DESTINO`, `ES_SKU`) ' +
    'SELECT `CODIGO_UNIDAD_SKU`, ' +
    'CONCAT(:NUEVO, SUBSTRING(`CODIGO_UNIDAD_SKU`, ' +
    'CHAR_LENGTH(:ANTERIOR) + 1)), ''S'' ' +
    'FROM `fza_articulos_skus` ' +
    'WHERE `CODIGO_ART_SKU` = :ANTERIOR ' +
    'AND (`CODIGO_UNIDAD_SKU` = :ANTERIOR ' +
    'OR LEFT(`CODIGO_UNIDAD_SKU`, CHAR_LENGTH(:ANTERIOR) + 1) = ' +
    'CONCAT(:ANTERIOR, ''/''))',
    ['ANTERIOR', 'NUEVO'],
    [AArticuloAntiguo, AArticuloNuevo]);
  Ejecutar(
    'INSERT IGNORE INTO `' + TABLA_TEMPORAL + '` ' +
    '(`ORIGEN`, `DESTINO`, `ES_SKU`) ' +
    'VALUES (:ANTERIOR, :NUEVO, ''N'')',
    ['ANTERIOR', 'NUEVO'],
    [AArticuloAntiguo, AArticuloNuevo]);
end;

procedure TValidadorCambioArticuloColorUniDAC.
  AgregarMapaArticuloReferencias(
    const AArticuloAntiguo, AArticuloNuevo: string);
var
  i: Integer;
  sCampo: string;
  sSql: string;
  sTabla: string;
begin
  for i := Low(REFERENCIAS_UNIDAD) to High(REFERENCIAS_UNIDAD) do
  begin
    SepararReferencia(REFERENCIAS_UNIDAD[i], sTabla, sCampo);
    if CampoExiste(sTabla, sCampo) then
    begin
      sSql := 'INSERT IGNORE INTO `' + TABLA_TEMPORAL + '` ' +
        '(`ORIGEN`, `DESTINO`, `ES_SKU`) ' +
        'SELECT DISTINCT dato.`' + sCampo + '`, ' +
        'CONCAT(:NUEVO, SUBSTRING(dato.`' + sCampo + '`, ' +
        'CHAR_LENGTH(:ANTERIOR) + 1)), ''N'' FROM `' + sTabla +
        '` dato WHERE dato.`' + sCampo + '` = :ANTERIOR OR ' +
        'LEFT(dato.`' + sCampo + '`, CHAR_LENGTH(:ANTERIOR) + 1) = ' +
        'CONCAT(:ANTERIOR, ''/'')';
      Ejecutar(
        sSql,
        ['ANTERIOR', 'NUEVO'],
        [AArticuloAntiguo, AArticuloNuevo]);
    end;
  end;
end;

procedure TValidadorCambioArticuloColorUniDAC.ConstruirMapaColor(
  const AColorAntiguo, AColorNuevo: string);
begin
  Ejecutar(
    'INSERT INTO `' + TABLA_TEMPORAL + '` ' +
    '(`ORIGEN`, `DESTINO`, `ES_SKU`, `POSICION_COLOR`) ' +
    'SELECT origen.`CODIGO_UNIDAD`, CONCAT(' +
    'SUBSTRING_INDEX(origen.`CODIGO_UNIDAD`, ''/'', ' +
    'origen.`POSICION_COLOR`), ''/'', :NUEVO, ' +
    'SUBSTRING(origen.`CODIGO_UNIDAD`, CHAR_LENGTH(' +
    'SUBSTRING_INDEX(origen.`CODIGO_UNIDAD`, ''/'', ' +
    'origen.`POSICION_COLOR` + 1)) + 1)), ''S'', ' +
    'origen.`POSICION_COLOR` FROM (' +
    SqlSkusConPosicionColor + ') origen WHERE ' +
    'origen.`ORDEN_AMBIGUO` = 0 AND ' +
    '(CHAR_LENGTH(origen.`CODIGO_UNIDAD`) - CHAR_LENGTH(' +
    'REPLACE(origen.`CODIGO_UNIDAD`, ''/'', ''''))) = ' +
    'origen.`NUM_ATRIBUTOS` AND ' +
    'TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(origen.`CODIGO_UNIDAD`, ' +
    '''/'', origen.`POSICION_COLOR` + 1), ''/'', -1)) = ' +
    'TRIM(:ANTERIOR) AND EXISTS (SELECT 1 FROM ' +
    '`fza_atributos_sku` sa JOIN `fza_atributos_valores` av ON ' +
    'av.`ID_AV` = sa.`ID_AV_SA` WHERE ' +
    'sa.`CODIGO_UNIDAD_SKU_SA` = origen.`CODIGO_UNIDAD` AND ' +
    'av.`ID_VA_AV` = ''CO'' AND TRIM(av.`AV`) = TRIM(:ANTERIOR))',
    ['ANTERIOR', 'NUEVO'],
    [AColorAntiguo, AColorNuevo]);
end;

function TValidadorCambioArticuloColorUniDAC.
  SqlCandidatosColorReferencia(
    const ATabla, ACampo: string): string;
begin
  Result := 'SELECT DISTINCT dato.`' + ACampo + '` `ORIGEN`, ' +
    'CONCAT(SUBSTRING_INDEX(dato.`' + ACampo + '`, ''/'', ' +
    'posicion.`POSICION_COLOR`), ''/'', :NUEVO, SUBSTRING(dato.`' +
    ACampo + '`, CHAR_LENGTH(SUBSTRING_INDEX(dato.`' + ACampo +
    '`, ''/'', posicion.`POSICION_COLOR` + 1)) + 1)) `DESTINO`, ' +
    'posicion.`POSICION_COLOR` `POSICION_COLOR` ' +
    'FROM `' + ATabla + '` dato JOIN (' + SqlSkusConPosicionColor +
    ') posicion ON posicion.`CODIGO_UNIDAD` = dato.`' + ACampo +
    '` OR LEFT(posicion.`CODIGO_UNIDAD`, CHAR_LENGTH(dato.`' +
    ACampo + '`) + 1) = CONCAT(dato.`' + ACampo + '`, ''/'') WHERE ' +
    'posicion.`ORDEN_AMBIGUO` = 0 AND ' +
    '(CHAR_LENGTH(posicion.`CODIGO_UNIDAD`) - CHAR_LENGTH(REPLACE(' +
    'posicion.`CODIGO_UNIDAD`, ''/'', ''''))) = ' +
    'posicion.`NUM_ATRIBUTOS` AND ' +
    'TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(' +
    'posicion.`CODIGO_UNIDAD`, ''/'', ' +
    'posicion.`POSICION_COLOR` + 1), ''/'', -1)) = TRIM(:ANTERIOR) ' +
    'AND EXISTS (SELECT 1 FROM `fza_atributos_sku` sa ' +
    'JOIN `fza_atributos_valores` av ON av.`ID_AV` = sa.`ID_AV_SA` ' +
    'WHERE sa.`CODIGO_UNIDAD_SKU_SA` = ' +
    'posicion.`CODIGO_UNIDAD` AND av.`ID_VA_AV` = ''CO'' AND ' +
    'TRIM(av.`AV`) = TRIM(:ANTERIOR)) AND ' +
    '(CHAR_LENGTH(dato.`' + ACampo + '`) - CHAR_LENGTH(REPLACE(' +
    'dato.`' + ACampo + '`, ''/'', ''''))) >= ' +
    'posicion.`POSICION_COLOR` AND ' +
    'TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(dato.`' + ACampo +
    '`, ''/'', posicion.`POSICION_COLOR` + 1), ''/'', -1)) = ' +
    'TRIM(:ANTERIOR)';
end;

procedure TValidadorCambioArticuloColorUniDAC.
  AgregarMapaColorReferencias(
    const AColorAntiguo, AColorNuevo: string);
var
  i: Integer;
  sCampo: string;
  sSql: string;
  sTabla: string;
begin
  for i := Low(REFERENCIAS_UNIDAD) to High(REFERENCIAS_UNIDAD) do
  begin
    if REFERENCIAS_UNIDAD[i] <> REFERENCIA_SKU_MAESTRO then
    begin
      SepararReferencia(REFERENCIAS_UNIDAD[i], sTabla, sCampo);
      if CampoExiste(sTabla, sCampo) then
      begin
        sSql := 'INSERT IGNORE INTO `' + TABLA_TEMPORAL + '` ' +
          '(`ORIGEN`, `DESTINO`, `ES_SKU`, `POSICION_COLOR`) SELECT ' +
          'candidatos.`ORIGEN`, MIN(candidatos.`DESTINO`), ''N'', ' +
          'MIN(candidatos.`POSICION_COLOR`) FROM (' +
          SqlCandidatosColorReferencia(sTabla, sCampo) +
          ') candidatos GROUP BY candidatos.`ORIGEN` ' +
          'HAVING COUNT(DISTINCT candidatos.`DESTINO`, ' +
          'candidatos.`POSICION_COLOR`) = 1';
        Ejecutar(
          sSql,
          ['ANTERIOR', 'NUEVO'],
          [AColorAntiguo, AColorNuevo]);
      end;
    end;
  end;
end;

function TValidadorCambioArticuloColorUniDAC.
  HayMapaColorReferenciasAmbiguo(
    const AColorAntiguo, AColorNuevo: string): Boolean;
var
  i: Integer;
  sCampo: string;
  sSql: string;
  sTabla: string;
begin
  Result := False;
  i := Low(REFERENCIAS_UNIDAD);
  while (i <= High(REFERENCIAS_UNIDAD)) and not Result do
  begin
    if REFERENCIAS_UNIDAD[i] <> REFERENCIA_SKU_MAESTRO then
    begin
      SepararReferencia(REFERENCIAS_UNIDAD[i], sTabla, sCampo);
      if CampoExiste(sTabla, sCampo) then
      begin
        sSql := 'SELECT candidatos.`ORIGEN` FROM (' +
          SqlCandidatosColorReferencia(sTabla, sCampo) +
          ') candidatos GROUP BY candidatos.`ORIGEN` ' +
          'HAVING COUNT(DISTINCT candidatos.`DESTINO`, ' +
          'candidatos.`POSICION_COLOR`) > 1 LIMIT 1';
        Result := Existe(
          sSql,
          ['ANTERIOR', 'NUEVO'],
          [AColorAntiguo, AColorNuevo]);
      end;
    end;
    Inc(i);
  end;
end;

function TValidadorCambioArticuloColorUniDAC.NumeroSkuMapa: Integer;
begin
  Result := EscalarEntero(
    'SELECT COUNT(*) FROM `' + TABLA_TEMPORAL + '` ' +
    'WHERE `ES_SKU` = ''S''',
    [],
    []);
end;

function TValidadorCambioArticuloColorUniDAC.MapaArticuloEsCompleto(
  const AArticuloAntiguo: string): Boolean;
var
  iNumeroSkuOrigen: Integer;
begin
  iNumeroSkuOrigen := EscalarEntero(
    'SELECT COUNT(*) FROM `fza_articulos_skus` ' +
    'WHERE `CODIGO_ART_SKU` = :ARTICULO',
    ['ARTICULO'],
    [AArticuloAntiguo]);
  Result := iNumeroSkuOrigen = NumeroSkuMapa;
end;

function TValidadorCambioArticuloColorUniDAC.MapaColorEsCompleto(
  const AColorAntiguo: string): Boolean;
var
  iNumeroSkuOrigen: Integer;
  bHaySegmentoSinAtributo: Boolean;
begin
  iNumeroSkuOrigen := EscalarEntero(
    'SELECT COUNT(DISTINCT sku.`CODIGO_UNIDAD_SKU`) ' +
    'FROM `fza_articulos_skus` sku ' +
    'JOIN `fza_atributos_sku` sa ON ' +
    'sa.`CODIGO_UNIDAD_SKU_SA` = sku.`CODIGO_UNIDAD_SKU` ' +
    'JOIN `fza_atributos_valores` av ON av.`ID_AV` = sa.`ID_AV_SA` ' +
    'WHERE av.`ID_VA_AV` = ''CO'' ' +
    'AND TRIM(av.`AV`) = TRIM(:COLOR)',
    ['COLOR'],
    [AColorAntiguo]);
  bHaySegmentoSinAtributo := Existe(
    'SELECT 1 FROM (' + SqlSkusConPosicionColor + ') origen WHERE ' +
    'origen.`ORDEN_AMBIGUO` = 0 AND ' +
    '(CHAR_LENGTH(origen.`CODIGO_UNIDAD`) - CHAR_LENGTH(' +
    'REPLACE(origen.`CODIGO_UNIDAD`, ''/'', ''''))) = ' +
    'origen.`NUM_ATRIBUTOS` AND ' +
    'TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(origen.`CODIGO_UNIDAD`, ' +
    '''/'', origen.`POSICION_COLOR` + 1), ''/'', -1)) = ' +
    'TRIM(:COLOR) AND NOT EXISTS (SELECT 1 FROM ' +
    '`fza_atributos_sku` sa ' +
    'JOIN `fza_atributos_valores` av ON av.`ID_AV` = sa.`ID_AV_SA` ' +
    'WHERE sa.`CODIGO_UNIDAD_SKU_SA` = origen.`CODIGO_UNIDAD` ' +
    'AND av.`ID_VA_AV` = ''CO'' AND ' +
    'TRIM(av.`AV`) = TRIM(:COLOR)) LIMIT 1',
    ['COLOR'],
    [AColorAntiguo]);
  Result := (iNumeroSkuOrigen = NumeroSkuMapa) and
            (not bHaySegmentoSinAtributo);
end;

function TValidadorCambioArticuloColorUniDAC.MapaTieneCodigosLargos:
  Boolean;
begin
  Result := Existe(
    'SELECT 1 FROM `' + TABLA_TEMPORAL + '` ' +
    'WHERE CHAR_LENGTH(`DESTINO`) > 50 LIMIT 1',
    [],
    []);
end;

function TValidadorCambioArticuloColorUniDAC.
  MapaTieneDestinosDuplicados: Boolean;
begin
  Result := Existe(
    'SELECT `DESTINO` FROM `' + TABLA_TEMPORAL + '` ' +
    'GROUP BY `DESTINO` HAVING COUNT(*) > 1 LIMIT 1',
    [],
    []);
end;

function TValidadorCambioArticuloColorUniDAC.
  FusionUnidadesEsSegura(
    const AColorDestino, AArticuloDestino: string;
    AEsFusionArticulo: Boolean): Boolean;
var
  sArticuloEsperado: string;
  sCondicionAtributos: string;
begin
  if AEsFusionArticulo then
    sArticuloEsperado := ':ARTICULO'
  else
    sArticuloEsperado := 'origen.`CODIGO_ART_SKU`';
  Result := not Existe(
    'SELECT 1 FROM `' + TABLA_TEMPORAL + '` mapa ' +
    'JOIN `fza_articulos_skus` origen ON ' +
    'origen.`CODIGO_UNIDAD_SKU` = mapa.`ORIGEN` ' +
    'JOIN `fza_articulos_skus` destino ON ' +
    'destino.`CODIGO_UNIDAD_SKU` = mapa.`DESTINO` ' +
    'WHERE mapa.`ES_SKU` = ''S'' AND (' +
    '(UPPER(TRIM(COALESCE(origen.`ESACTIVO_SKU`, ''N''))) = ''S'' ' +
    'AND UPPER(TRIM(COALESCE(' +
    'destino.`ESACTIVO_SKU`, ''N''))) <> ''S'') OR ' +
    'destino.`CODIGO_ART_SKU` <> ' + sArticuloEsperado + ' OR NOT (' +
    'destino.`CODIGO_VAR_SKU` <=> origen.`CODIGO_VAR_SKU`)) LIMIT 1',
    ['ARTICULO'],
    [AArticuloDestino]);
  if Result then
  begin
    if AEsFusionArticulo then
    begin
      sCondicionAtributos :=
        'EXISTS (SELECT 1 FROM `fza_atributos_sku` sa WHERE ' +
        'sa.`CODIGO_UNIDAD_SKU_SA` = mapa.`ORIGEN` AND NOT EXISTS (' +
        'SELECT 1 FROM `fza_atributos_sku` sd WHERE ' +
        'sd.`CODIGO_UNIDAD_SKU_SA` = mapa.`DESTINO` AND ' +
        'sd.`ID_AV_SA` = sa.`ID_AV_SA`)) OR EXISTS (SELECT 1 FROM ' +
        '`fza_atributos_sku` sd WHERE sd.`CODIGO_UNIDAD_SKU_SA` = ' +
        'mapa.`DESTINO` AND NOT EXISTS (SELECT 1 FROM ' +
        '`fza_atributos_sku` sa WHERE sa.`CODIGO_UNIDAD_SKU_SA` = ' +
        'mapa.`ORIGEN` AND sa.`ID_AV_SA` = sd.`ID_AV_SA`))';
    end
    else
    begin
      sCondicionAtributos :=
        'EXISTS (SELECT 1 FROM `fza_atributos_sku` sa JOIN ' +
        '`fza_atributos_valores` av ON av.`ID_AV` = sa.`ID_AV_SA` ' +
        'WHERE sa.`CODIGO_UNIDAD_SKU_SA` = mapa.`ORIGEN` AND ' +
        'av.`ID_VA_AV` <> ''CO'' AND NOT EXISTS (SELECT 1 FROM ' +
        '`fza_atributos_sku` sd WHERE sd.`CODIGO_UNIDAD_SKU_SA` = ' +
        'mapa.`DESTINO` AND sd.`ID_AV_SA` = sa.`ID_AV_SA`)) OR ' +
        'EXISTS (SELECT 1 FROM `fza_atributos_sku` sd JOIN ' +
        '`fza_atributos_valores` av ON av.`ID_AV` = sd.`ID_AV_SA` ' +
        'WHERE sd.`CODIGO_UNIDAD_SKU_SA` = mapa.`DESTINO` AND ' +
        'av.`ID_VA_AV` <> ''CO'' AND NOT EXISTS (SELECT 1 FROM ' +
        '`fza_atributos_sku` sa WHERE sa.`CODIGO_UNIDAD_SKU_SA` = ' +
        'mapa.`ORIGEN` AND sa.`ID_AV_SA` = sd.`ID_AV_SA`)) OR ' +
        '(SELECT COUNT(*) FROM `fza_atributos_sku` sd JOIN ' +
        '`fza_atributos_valores` av ON av.`ID_AV` = sd.`ID_AV_SA` ' +
        'WHERE sd.`CODIGO_UNIDAD_SKU_SA` = mapa.`DESTINO` AND ' +
        'av.`ID_VA_AV` = ''CO'' AND TRIM(av.`AV`) = ' +
        'TRIM(:COLOR)) <> 1';
    end;
    Result := not Existe(
      'SELECT 1 FROM `' + TABLA_TEMPORAL + '` mapa ' +
      'JOIN `fza_articulos_skus` destino ON ' +
      'destino.`CODIGO_UNIDAD_SKU` = mapa.`DESTINO` WHERE ' +
      'mapa.`ES_SKU` = ''S'' AND (' + sCondicionAtributos + ') LIMIT 1',
      ['COLOR'],
      [AColorDestino]);
  end;
  if Result then
  begin
    Result := not Existe(
      'SELECT 1 FROM `' + TABLA_TEMPORAL + '` mapa JOIN ' +
      '`fza_articulos_stockactual` origen ON ' +
      'origen.`CODIGO_UNIDAD_STK` = mapa.`ORIGEN` JOIN ' +
      '`fza_articulos_stockactual` destino ON ' +
      'destino.`CODIGO_UNIDAD_STK` = mapa.`DESTINO` AND ' +
      'destino.`CODIGO_ALM_STK` = origen.`CODIGO_ALM_STK` AND ' +
      'destino.`LOTE_STK` = origen.`LOTE_STK` WHERE ' +
      'mapa.`ES_SKU` = ''S'' AND NOT (' +
      'destino.`FECHA_CADUCIDAD_STK` <=> ' +
      'origen.`FECHA_CADUCIDAD_STK`) LIMIT 1',
      [],
      []);
  end;
end;

function TValidadorCambioArticuloColorUniDAC.
  HayColisionUnidadesNoConsolidable(
    const AArticuloDestino: string;
    AEsFusionArticulo: Boolean): Boolean;
var
  sArticuloDestino: string;
begin
  if AEsFusionArticulo then
    sArticuloDestino := ':ARTICULO'
  else
    sArticuloDestino := 'origen.`CODIGO_ART_FOT`';
  Result := False;
  if CampoExiste('fza_articulos_fotos', 'CODIGO_UNIDAD_FOT') then
  begin
    Result := Existe(
      'SELECT 1 FROM `fza_articulos_fotos` origen JOIN `' +
      TABLA_TEMPORAL + '` mapa ON mapa.`ORIGEN` = ' +
      'origen.`CODIGO_UNIDAD_FOT` JOIN `fza_articulos_fotos` destino ' +
      'ON destino.`CODIGO_UNIDAD_FOT` = mapa.`DESTINO` AND ' +
      'destino.`CODIGO_ART_FOT` = ' + sArticuloDestino + ' AND ' +
      'destino.`ORDEN_FOT` = origen.`ORDEN_FOT` LIMIT 1',
      ['ARTICULO'],
      [AArticuloDestino]);
  end;
  if (not Result) and
     CampoExiste('fza_articulos_propiedades',
       'CODIGO_UNIDAD_ARTPROP') then
  begin
    if AEsFusionArticulo then
      sArticuloDestino := ':ARTICULO'
    else
      sArticuloDestino := 'origen.`CODIGO_ART_ART`';
    Result := Existe(
      'SELECT 1 FROM `fza_articulos_propiedades` origen JOIN `' +
      TABLA_TEMPORAL + '` mapa ON mapa.`ORIGEN` = ' +
      'origen.`CODIGO_UNIDAD_ARTPROP` JOIN ' +
      '`fza_articulos_propiedades` destino ON ' +
      'destino.`CODIGO_UNIDAD_ARTPROP` = mapa.`DESTINO` AND ' +
      'destino.`CODIGO_ART_ART` = ' + sArticuloDestino + ' AND ' +
      'destino.`CODIGO_PROP_ARTPROP` = ' +
      'origen.`CODIGO_PROP_ARTPROP` LIMIT 1',
      ['ARTICULO'],
      [AArticuloDestino]);
  end;
  if (not Result) and
     CampoExiste('fza_articulos_pdte_recibir', 'CODIGO_UNIDAD_PDR') then
  begin
    Result := Existe(
      'SELECT 1 FROM `fza_articulos_pdte_recibir` origen JOIN `' +
      TABLA_TEMPORAL + '` mapa ON mapa.`ORIGEN` = ' +
      'origen.`CODIGO_UNIDAD_PDR` JOIN ' +
      '`fza_articulos_pdte_recibir` destino ON ' +
      'destino.`CODIGO_UNIDAD_PDR` = mapa.`DESTINO` AND ' +
      'destino.`CODIGO_ALM_PDR` = origen.`CODIGO_ALM_PDR` AND ' +
      'destino.`SERIE_DOC_PDR` = origen.`SERIE_DOC_PDR` AND ' +
      'destino.`NUMERO_DOC_PDR` = origen.`NUMERO_DOC_PDR` AND ' +
      'destino.`LINEA_PDR` = origen.`LINEA_PDR` LIMIT 1',
      [],
      []);
  end;
  if (not Result) and
     CampoExiste('fza_compras_sesiones_fotos', 'CODIGO_UNIDAD_CSF') then
  begin
    Result := Existe(
      'SELECT 1 FROM `fza_compras_sesiones_fotos` origen JOIN `' +
      TABLA_TEMPORAL + '` mapa ON mapa.`ORIGEN` = ' +
      'origen.`CODIGO_UNIDAD_CSF` JOIN ' +
      '`fza_compras_sesiones_fotos` destino ON ' +
      'destino.`CODIGO_UNIDAD_CSF` = mapa.`DESTINO` AND ' +
      'destino.`SERIE_SES_CSF` = origen.`SERIE_SES_CSF` AND ' +
      'destino.`NUMERO_SES_CSF` = origen.`NUMERO_SES_CSF` AND ' +
      'destino.`LINEA_CSF` = origen.`LINEA_CSF` LIMIT 1',
      [],
      []);
  end;
end;

function TValidadorCambioArticuloColorUniDAC.HayVentasArticulo(
  const AArticuloAntiguo: string): Boolean;
begin
  Result := Existe(
    'SELECT fl.`CODIGO_ART_FACLIN` ' +
    'FROM `fza_facturas_lineas` fl ' +
    'LEFT JOIN `' + TABLA_TEMPORAL + '` mapa ON ' +
    'mapa.`ORIGEN` = fl.`CODIGO_UNIDAD_FACLIN` ' +
    'WHERE fl.`CODIGO_ART_FACLIN` = :ARTICULO ' +
    'OR fl.`CODIGO_UNIDAD_FACLIN` = :ARTICULO ' +
    'OR LEFT(fl.`CODIGO_UNIDAD_FACLIN`, ' +
    'CHAR_LENGTH(:ARTICULO) + 1) = CONCAT(:ARTICULO, ''/'') ' +
    'OR mapa.`ORIGEN` IS NOT NULL LIMIT 1 FOR UPDATE',
    ['ARTICULO'],
    [AArticuloAntiguo]);
end;

function TValidadorCambioArticuloColorUniDAC.HayVentasColor(
  const AColorAntiguo: string): Boolean;
var
  i: Integer;
  sCampoNombre: string;
  sCampoValor: string;
  sCondiciones: string;
  sSql: string;
begin
  sCondiciones := 'mapa.`ORIGEN` IS NOT NULL OR ' +
    '((sku_actual.`CODIGO_UNIDAD_SKU` IS NULL OR ' +
    'UPPER(TRIM(COALESCE(' +
    'sku_actual.`ESACTIVO_SKU`, ''N''))) <> ''S'') AND ' +
    'LOCATE(''/'', fl.`CODIGO_UNIDAD_FACLIN`) > 0 AND ' +
    'LOCATE(CONCAT(''/'', TRIM(:COLOR), ''/''), ' +
    'CONCAT(''/'', SUBSTRING(fl.`CODIGO_UNIDAD_FACLIN`, ' +
    'LOCATE(''/'', fl.`CODIGO_UNIDAD_FACLIN`) + 1), ''/'')) > 0)';
  for i := 1 to 5 do
  begin
    sCampoValor := 'ATTR' + IntToStr(i) + '_VALOR_FACLIN';
    sCampoNombre := 'ATTR' + IntToStr(i) + '_NOMBRE_FACLIN';
    sCondiciones := sCondiciones + ' OR ' + CondicionInstantaneaColor(
      'fl',
      sCampoValor,
      sCampoNombre,
      'COLOR');
    sCondiciones := sCondiciones + ' OR ' +
      '(posicion_actual.`CODIGO_UNIDAD` IS NULL AND TRIM(fl.`' +
      sCampoValor + '`) = TRIM(:COLOR))';
    sCondiciones := sCondiciones + ' OR ' +
      '(posicion_actual.`POSICION_COLOR` = ' + IntToStr(i) + ' AND ' +
      'TRIM(COALESCE(fl.`' + sCampoNombre + '`, '''')) = '''' AND ' +
      'TRIM(fl.`' + sCampoValor + '`) = TRIM(:COLOR))';
  end;
  sSql := 'SELECT fl.`CODIGO_UNIDAD_FACLIN` ' +
    'FROM `fza_facturas_lineas` fl ' +
    'LEFT JOIN `' + TABLA_TEMPORAL + '` mapa ON ' +
    'mapa.`ORIGEN` = fl.`CODIGO_UNIDAD_FACLIN` ' +
    'LEFT JOIN `fza_articulos_skus` sku_actual ON ' +
    'sku_actual.`CODIGO_UNIDAD_SKU` = fl.`CODIGO_UNIDAD_FACLIN` ' +
    'LEFT JOIN (' + SqlSkusConPosicionColor + ') posicion_actual ON ' +
    'posicion_actual.`CODIGO_UNIDAD` = fl.`CODIGO_UNIDAD_FACLIN` AND ' +
    'posicion_actual.`ORDEN_AMBIGUO` = 0 AND ' +
    '(CHAR_LENGTH(posicion_actual.`CODIGO_UNIDAD`) - CHAR_LENGTH(' +
    'REPLACE(posicion_actual.`CODIGO_UNIDAD`, ''/'', ''''))) = ' +
    'posicion_actual.`NUM_ATRIBUTOS` WHERE ' +
    sCondiciones + ' LIMIT 1 FOR UPDATE';
  Result := Existe(
    sSql,
    ['COLOR'],
    [AColorAntiguo]);
end;

function TValidadorCambioArticuloColorUniDAC.
  HayDestinoEnVentasArticulo(const AArticuloNuevo: string): Boolean;
begin
  Result := Existe(
    'SELECT 1 FROM `fza_facturas_lineas` fl ' +
    'LEFT JOIN `' + TABLA_TEMPORAL + '` mapa ON ' +
    'mapa.`DESTINO` = fl.`CODIGO_UNIDAD_FACLIN` ' +
    'WHERE fl.`CODIGO_ART_FACLIN` = :ARTICULO ' +
    'OR fl.`CODIGO_UNIDAD_FACLIN` = :ARTICULO ' +
    'OR LEFT(fl.`CODIGO_UNIDAD_FACLIN`, ' +
    'CHAR_LENGTH(:ARTICULO) + 1) = CONCAT(:ARTICULO, ''/'') ' +
    'OR mapa.`DESTINO` IS NOT NULL LIMIT 1 FOR UPDATE',
    ['ARTICULO'],
    [AArticuloNuevo]);
end;

function TValidadorCambioArticuloColorUniDAC.
  HayDestinoEnVentasColor(const AColorNuevo: string): Boolean;
var
  i: Integer;
  sCampoNombre: string;
  sCampoValor: string;
  sCondiciones: string;
  sSql: string;
begin
  sCondiciones := 'mapa.`DESTINO` IS NOT NULL OR ' +
    'EXISTS (SELECT 1 FROM `fza_atributos_sku` sa_destino ' +
    'JOIN `fza_atributos_valores` av_destino ON ' +
    'av_destino.`ID_AV` = sa_destino.`ID_AV_SA` ' +
    'WHERE sa_destino.`CODIGO_UNIDAD_SKU_SA` = ' +
    'fl.`CODIGO_UNIDAD_FACLIN` AND ' +
    'av_destino.`ID_VA_AV` = ''CO'' AND ' +
    'TRIM(av_destino.`AV`) = TRIM(:COLOR)) OR ' +
    '((sku_actual.`CODIGO_UNIDAD_SKU` IS NULL OR ' +
    'UPPER(TRIM(COALESCE(' +
    'sku_actual.`ESACTIVO_SKU`, ''N''))) <> ''S'') AND ' +
    'LOCATE(''/'', fl.`CODIGO_UNIDAD_FACLIN`) > 0 AND ' +
    'LOCATE(CONCAT(''/'', TRIM(:COLOR), ''/''), ' +
    'CONCAT(''/'', SUBSTRING(fl.`CODIGO_UNIDAD_FACLIN`, ' +
    'LOCATE(''/'', fl.`CODIGO_UNIDAD_FACLIN`) + 1), ''/'')) > 0)';
  for i := 1 to 5 do
  begin
    sCampoValor := 'ATTR' + IntToStr(i) + '_VALOR_FACLIN';
    sCampoNombre := 'ATTR' + IntToStr(i) + '_NOMBRE_FACLIN';
    sCondiciones := sCondiciones + ' OR ' + CondicionInstantaneaColor(
      'fl',
      sCampoValor,
      sCampoNombre,
      'COLOR');
    sCondiciones := sCondiciones + ' OR ' +
      '(posicion_actual.`CODIGO_UNIDAD` IS NULL AND TRIM(fl.`' +
      sCampoValor + '`) = TRIM(:COLOR))';
    sCondiciones := sCondiciones + ' OR ' +
      '(posicion_actual.`POSICION_COLOR` = ' + IntToStr(i) + ' AND ' +
      'TRIM(COALESCE(fl.`' + sCampoNombre + '`, '''')) = '''' AND ' +
      'TRIM(fl.`' + sCampoValor + '`) = TRIM(:COLOR))';
  end;
  sSql := 'SELECT 1 FROM `fza_facturas_lineas` fl ' +
    'LEFT JOIN `' + TABLA_TEMPORAL + '` mapa ON ' +
    'mapa.`DESTINO` = fl.`CODIGO_UNIDAD_FACLIN` ' +
    'LEFT JOIN `fza_articulos_skus` sku_actual ON ' +
    'sku_actual.`CODIGO_UNIDAD_SKU` = fl.`CODIGO_UNIDAD_FACLIN` ' +
    'LEFT JOIN (' + SqlSkusConPosicionColor + ') posicion_actual ON ' +
    'posicion_actual.`CODIGO_UNIDAD` = fl.`CODIGO_UNIDAD_FACLIN` AND ' +
    'posicion_actual.`ORDEN_AMBIGUO` = 0 AND ' +
    '(CHAR_LENGTH(posicion_actual.`CODIGO_UNIDAD`) - CHAR_LENGTH(' +
    'REPLACE(posicion_actual.`CODIGO_UNIDAD`, ''/'', ''''))) = ' +
    'posicion_actual.`NUM_ATRIBUTOS` WHERE ' +
    sCondiciones + ' LIMIT 1 FOR UPDATE';
  Result := Existe(sSql, ['COLOR'], [AColorNuevo]);
end;

function TValidadorCambioArticuloColorUniDAC.HayDestinoMapaEnVentas:
  Boolean;
begin
  Result := Existe(
    'SELECT 1 FROM `fza_facturas_lineas` fl ' +
    'JOIN `' + TABLA_TEMPORAL + '` mapa ON ' +
    'mapa.`DESTINO` = fl.`CODIGO_UNIDAD_FACLIN` ' +
    'LIMIT 1 FOR UPDATE',
    [],
    []);
end;

function TValidadorCambioArticuloColorUniDAC.HayPrestaShopArticulo(
  const AArticuloAntiguo: string): Boolean;
begin
  Result := False;
  if CampoExiste('fza_articulos', 'ESWEB_ART') then
  begin
    Result := Existe(
      'SELECT 1 FROM `fza_articulos` ' +
      'WHERE `CODIGO_ART_ART` = :ARTICULO ' +
      'AND UPPER(TRIM(COALESCE(`ESWEB_ART`, ''N''))) = ''S'' ' +
      'LIMIT 1 FOR UPDATE',
      ['ARTICULO'],
      [AArticuloAntiguo]);
  end;
  if (not Result) and
     CampoExiste('fza_prestashop_cola', 'CODIGO_ART_PSCOLA') then
  begin
    Result := Existe(
      'SELECT 1 FROM `fza_prestashop_cola` ' +
      'WHERE `CODIGO_ART_PSCOLA` = :ARTICULO LIMIT 1 FOR UPDATE',
      ['ARTICULO'],
      [AArticuloAntiguo]);
  end;
end;

function TValidadorCambioArticuloColorUniDAC.HayPrestaShopColor(
  const AColorAntiguo: string): Boolean;
begin
  Result := False;
  if CampoExiste('fza_articulos', 'ESWEB_ART') then
  begin
    Result := Existe(
      'SELECT 1 FROM `fza_articulos` art JOIN (' +
      'SELECT DISTINCT SUBSTRING_INDEX(`ORIGEN`, ''/'', 1) `ARTICULO` ' +
      'FROM `' + TABLA_TEMPORAL + '`) afectados ON ' +
      'afectados.`ARTICULO` = art.`CODIGO_ART_ART` ' +
      'WHERE UPPER(TRIM(COALESCE(art.`ESWEB_ART`, ''N''))) = ''S'' ' +
      'LIMIT 1 FOR UPDATE',
      [],
      []);
  end;
  if (not Result) and
     CampoExiste('fza_articulos', 'ESWEB_ART') then
  begin
    Result := Existe(
      'SELECT 1 FROM `fza_articulos` art ' +
      'JOIN `fza_articulos_atributos_basicos` aab ON ' +
      'aab.`CODIGO_ART_AAB` = art.`CODIGO_ART_ART` ' +
      'JOIN `fza_atributos_valores` av ON ' +
      'av.`ID_AV` = aab.`ID_AV_AAB` ' +
      'WHERE av.`ID_VA_AV` = ''CO'' AND ' +
      'TRIM(av.`AV`) = TRIM(:COLOR) AND ' +
      'UPPER(TRIM(COALESCE(art.`ESWEB_ART`, ''N''))) = ''S'' ' +
      'LIMIT 1 FOR UPDATE',
      ['COLOR'],
      [AColorAntiguo]);
  end;
  if (not Result) and
     CampoExiste('fza_articulos', 'ESWEB_ART') then
  begin
    Result := Existe(
      'SELECT 1 FROM `fza_articulos` art ' +
      'JOIN `fza_articulos_conjuntos_asign` aca ON ' +
      'aca.`CODIGO_ART_ACA` = art.`CODIGO_ART_ART` ' +
      'JOIN `fza_atributos_conjuntos_det` acd ON ' +
      'acd.`ID_AC_ACD` = aca.`ID_AC_ACA` ' +
      'JOIN `fza_atributos_valores` av ON ' +
      'av.`ID_AV` = acd.`ID_AV_ACD` ' +
      'WHERE av.`ID_VA_AV` = ''CO'' AND ' +
      'TRIM(av.`AV`) = TRIM(:COLOR) AND ' +
      'UPPER(TRIM(COALESCE(art.`ESWEB_ART`, ''N''))) = ''S'' ' +
      'LIMIT 1 FOR UPDATE',
      ['COLOR'],
      [AColorAntiguo]);
  end;
  if (not Result) and
     CampoExiste('fza_prestashop_cola', 'CODIGO_ART_PSCOLA') then
  begin
    Result := Existe(
      'SELECT 1 FROM `fza_prestashop_cola` cola JOIN (' +
      'SELECT DISTINCT SUBSTRING_INDEX(`ORIGEN`, ''/'', 1) `ARTICULO` ' +
      'FROM `' + TABLA_TEMPORAL + '`) afectados ON ' +
      'afectados.`ARTICULO` = cola.`CODIGO_ART_PSCOLA` ' +
      'LIMIT 1 FOR UPDATE',
      [],
      []);
  end;
  if (not Result) and
     CampoExiste('fza_prestashop_cola', 'CODIGO_ART_PSCOLA') then
  begin
    Result := Existe(
      'SELECT 1 FROM `fza_prestashop_cola` cola ' +
      'JOIN `fza_articulos_atributos_basicos` aab ON ' +
      'aab.`CODIGO_ART_AAB` = cola.`CODIGO_ART_PSCOLA` ' +
      'JOIN `fza_atributos_valores` av ON ' +
      'av.`ID_AV` = aab.`ID_AV_AAB` ' +
      'WHERE av.`ID_VA_AV` = ''CO'' AND ' +
      'TRIM(av.`AV`) = TRIM(:COLOR) LIMIT 1 FOR UPDATE',
      ['COLOR'],
      [AColorAntiguo]);
  end;
  if (not Result) and
     CampoExiste('fza_prestashop_cola', 'CODIGO_ART_PSCOLA') then
  begin
    Result := Existe(
      'SELECT 1 FROM `fza_prestashop_cola` cola ' +
      'JOIN `fza_articulos_conjuntos_asign` aca ON ' +
      'aca.`CODIGO_ART_ACA` = cola.`CODIGO_ART_PSCOLA` ' +
      'JOIN `fza_atributos_conjuntos_det` acd ON ' +
      'acd.`ID_AC_ACD` = aca.`ID_AC_ACA` ' +
      'JOIN `fza_atributos_valores` av ON ' +
      'av.`ID_AV` = acd.`ID_AV_ACD` ' +
      'WHERE av.`ID_VA_AV` = ''CO'' AND ' +
      'TRIM(av.`AV`) = TRIM(:COLOR) LIMIT 1 FOR UPDATE',
      ['COLOR'],
      [AColorAntiguo]);
  end;
end;

function TValidadorCambioArticuloColorUniDAC.HayDestinoEnReferencias(
  const AReferencias: array of string): Boolean;
var
  i: Integer;
  sCampo: string;
  sSql: string;
  sTabla: string;
begin
  Result := False;
  i := Low(AReferencias);
  while (i <= High(AReferencias)) and not Result do
  begin
    SepararReferencia(AReferencias[i], sTabla, sCampo);
    if CampoExiste(sTabla, sCampo) then
    begin
      sSql := 'SELECT 1 FROM `' + sTabla + '` dato ' +
        'JOIN `' + TABLA_TEMPORAL + '` mapa ON ' +
        'mapa.`DESTINO` = dato.`' + sCampo + '` LIMIT 1';
      Result := Existe(sSql, [], []);
    end;
    Inc(i);
  end;
end;

function TValidadorCambioArticuloColorUniDAC.HayOrigenEnReferencias(
  const AReferencias: array of string): Boolean;
var
  i: Integer;
  sCampo: string;
  sSql: string;
  sTabla: string;
begin
  Result := False;
  i := Low(AReferencias);
  while (i <= High(AReferencias)) and not Result do
  begin
    if (AReferencias[i] <> REFERENCIA_SKU_MAESTRO) and
       (AReferencias[i] <> REFERENCIA_COSTES_SKU) and
       (AReferencias[i] <> REFERENCIA_ARTICULO_SKU) and
       (AReferencias[i] <> REFERENCIA_ARTICULO_PROVEEDOR) then
    begin
      SepararReferencia(AReferencias[i], sTabla, sCampo);
      if CampoExiste(sTabla, sCampo) then
      begin
        sSql := 'SELECT 1 FROM `' + sTabla + '` dato ' +
          'JOIN `' + TABLA_TEMPORAL + '` mapa ON ' +
          'mapa.`ORIGEN` = dato.`' + sCampo + '` LIMIT 1';
        Result := Existe(sSql, [], []);
      end;
    end;
    Inc(i);
  end;
end;

function TValidadorCambioArticuloColorUniDAC.
  HayUnidadesArticuloSinMapa(
    const AArticuloAntiguo: string): Boolean;
var
  i: Integer;
  sCampo: string;
  sSql: string;
  sTabla: string;
begin
  Result := False;
  i := Low(REFERENCIAS_UNIDAD);
  while (i <= High(REFERENCIAS_UNIDAD)) and not Result do
  begin
    SepararReferencia(REFERENCIAS_UNIDAD[i], sTabla, sCampo);
    if CampoExiste(sTabla, sCampo) then
    begin
      sSql := 'SELECT 1 FROM `' + sTabla + '` dato ' +
        'LEFT JOIN `' + TABLA_TEMPORAL + '` mapa ON ' +
        'mapa.`ORIGEN` = dato.`' + sCampo + '` ' +
        'WHERE mapa.`ORIGEN` IS NULL AND ' +
        '(dato.`' + sCampo + '` = :ANTERIOR OR ' +
        'LEFT(dato.`' + sCampo + '`, CHAR_LENGTH(:ANTERIOR) + 1) = ' +
        'CONCAT(:ANTERIOR, ''/'')) LIMIT 1';
      Result := Existe(sSql, ['ANTERIOR'], [AArticuloAntiguo]);
    end;
    Inc(i);
  end;
end;

function TValidadorCambioArticuloColorUniDAC.
  HayUnidadesColorSinMapa(const AColorAntiguo: string): Boolean;
var
  i: Integer;
  sCampo: string;
  sSql: string;
  sTabla: string;
begin
  Result := False;
  i := Low(REFERENCIAS_UNIDAD);
  while (i <= High(REFERENCIAS_UNIDAD)) and not Result do
  begin
    SepararReferencia(REFERENCIAS_UNIDAD[i], sTabla, sCampo);
    if CampoExiste(sTabla, sCampo) then
    begin
      sSql := 'SELECT 1 FROM `' + sTabla + '` dato LEFT JOIN `' +
        TABLA_TEMPORAL + '` mapa ON ' +
        'mapa.`ORIGEN` = dato.`' + sCampo + '` ' +
        'LEFT JOIN `fza_articulos_skus` sku_actual ON ' +
        'sku_actual.`CODIGO_UNIDAD_SKU` = dato.`' + sCampo + '` ' +
        'WHERE mapa.`ORIGEN` IS NULL ' +
        'AND sku_actual.`CODIGO_UNIDAD_SKU` IS NULL ' +
        'AND LOCATE(''/'', dato.`' + sCampo + '`) > 0 ' +
        'AND LOCATE(CONCAT(''/'', TRIM(:ANTERIOR), ''/''), ' +
        'CONCAT(''/'', SUBSTRING(dato.`' + sCampo + '`, ' +
        'LOCATE(''/'', dato.`' + sCampo + '`) + 1), ''/'')) > 0 ' +
        'LIMIT 1';
      Result := Existe(sSql, ['ANTERIOR'], [AColorAntiguo]);
    end;
    Inc(i);
  end;
end;

procedure TRepositorioCambioArticuloColorUniDAC.ActualizarCampoPorValor(
  const ATabla, ACampo, AAnterior, ANuevo, AUsuario: string);
var
  sAuditoria: string;
  sSql: string;
begin
  sAuditoria := '';
  if CampoExiste(ATabla, 'INSTANTE_MODIF') then
    sAuditoria := ', `INSTANTE_MODIF` = CURRENT_TIMESTAMP';
  if CampoExiste(ATabla, 'USUARIO_MODIF') then
    sAuditoria := sAuditoria + ', `USUARIO_MODIF` = :USUARIO';
  sSql := 'UPDATE `' + ATabla + '` SET `' + ACampo + '` = :NUEVO' +
    sAuditoria + ' WHERE `' + ACampo + '` = :ANTERIOR';
  Ejecutar(
    sSql,
    ['ANTERIOR', 'NUEVO', 'USUARIO'],
    [AAnterior, ANuevo, AUsuario]);
end;

procedure TRepositorioCambioArticuloColorUniDAC.ActualizarCampoPorMapa(
  const ATabla, ACampo, AUsuario: string);
var
  sAuditoria: string;
  sSql: string;
begin
  sAuditoria := '';
  if CampoExiste(ATabla, 'INSTANTE_MODIF') then
    sAuditoria := ', dato.`INSTANTE_MODIF` = CURRENT_TIMESTAMP';
  if CampoExiste(ATabla, 'USUARIO_MODIF') then
    sAuditoria := sAuditoria + ', dato.`USUARIO_MODIF` = :USUARIO';
  sSql := 'UPDATE `' + ATabla + '` dato ' +
    'JOIN `' + TABLA_TEMPORAL + '` mapa ON ' +
    'mapa.`ORIGEN` = dato.`' + ACampo + '` ' +
    'SET dato.`' + ACampo + '` = mapa.`DESTINO`' + sAuditoria;
  Ejecutar(sSql, ['USUARIO'], [AUsuario]);
end;

procedure TRepositorioCambioArticuloColorUniDAC.
  ActualizarReferenciasArticulo(
    const AAnterior, ANuevo, AUsuario: string);
var
  i: Integer;
  sCampo: string;
  sTabla: string;
begin
  for i := Low(REFERENCIAS_ARTICULO) to High(REFERENCIAS_ARTICULO) do
  begin
    if (REFERENCIAS_ARTICULO[i] <> REFERENCIA_ARTICULO_SKU) and
       (REFERENCIAS_ARTICULO[i] <> REFERENCIA_ARTICULO_PROVEEDOR) then
    begin
      SepararReferencia(REFERENCIAS_ARTICULO[i], sTabla, sCampo);
      if CampoExiste(sTabla, sCampo) then
      begin
        ActualizarCampoPorValor(
          sTabla,
          sCampo,
          AAnterior,
          ANuevo,
          AUsuario);
      end;
    end;
  end;
end;

procedure TRepositorioCambioArticuloColorUniDAC.
  ActualizarReferenciasUnidad(const AUsuario: string);
var
  i: Integer;
  sCampo: string;
  sTabla: string;
begin
  for i := Low(REFERENCIAS_UNIDAD) to High(REFERENCIAS_UNIDAD) do
  begin
    if (REFERENCIAS_UNIDAD[i] <> REFERENCIA_SKU_MAESTRO) and
       (REFERENCIAS_UNIDAD[i] <> REFERENCIA_ATRIBUTOS_SKU) and
       (REFERENCIAS_UNIDAD[i] <> REFERENCIA_COSTES_SKU) and
       (REFERENCIAS_UNIDAD[i] <> REFERENCIA_STOCK) and
       (REFERENCIAS_UNIDAD[i] <> REFERENCIA_TARIFAS) and
       (REFERENCIAS_UNIDAD[i] <> REFERENCIA_BARRAS) and
       (REFERENCIAS_UNIDAD[i] <> REFERENCIA_BLOQUEOS) then
    begin
      SepararReferencia(REFERENCIAS_UNIDAD[i], sTabla, sCampo);
      if CampoExiste(sTabla, sCampo) then
        ActualizarCampoPorMapa(sTabla, sCampo, AUsuario);
    end;
  end;
end;

procedure TRepositorioCambioArticuloColorUniDAC.CrearArticuloDestino(
  const AAnterior, ANuevo, AUsuario: string);
begin
  Ejecutar(
    'INSERT INTO `fza_articulos` (`CODIGO_ART_ART`, `ESACTIVO_ART`, ' +
    '`ESWEB_ART`, `TIPO_ART`, `DESCRIPCION_ART`, `CODIGO_FAM_ART`, ' +
    '`TIPO_IVA_ART`, `ESACTIVO_FIJO_ART`, `TIPO_CANTIDAD_ART`, ' +
    '`ESVARIACION_ART`, `ESTRAZABLE_ART`, `ORDEN_ART`, ' +
    '`INSTANTE_MODIF`, `INSTANTE_ALTA`, `USUARIO_ALTA`, ' +
    '`USUARIO_MODIF`, `TIPO_VARIACION_ART`) SELECT :NUEVO, ''S'', ' +
    '`ESWEB_ART`, `TIPO_ART`, `DESCRIPCION_ART`, `CODIGO_FAM_ART`, ' +
    '`TIPO_IVA_ART`, `ESACTIVO_FIJO_ART`, `TIPO_CANTIDAD_ART`, ' +
    '`ESVARIACION_ART`, `ESTRAZABLE_ART`, `ORDEN_ART`, ' +
    'CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, :USUARIO, :USUARIO, ' +
    '`TIPO_VARIACION_ART` FROM `fza_articulos` WHERE ' +
    '`CODIGO_ART_ART` = :ANTERIOR',
    ['ANTERIOR', 'NUEVO', 'USUARIO'],
    [AAnterior, ANuevo, AUsuario]);
end;

procedure TRepositorioCambioArticuloColorUniDAC.CrearSkuDestino(
  const AArticuloDestino, AUsuario: string;
  AEsCambioArticulo: Boolean);
var
  sArticulo: string;
begin
  Ejecutar(
    'UPDATE `' + TABLA_TEMPORAL + '` mapa LEFT JOIN ' +
    '`fza_articulos_skus` destino ON destino.`CODIGO_UNIDAD_SKU` = ' +
    'mapa.`DESTINO` SET mapa.`DESTINO_EXISTIA` = CASE WHEN ' +
    'destino.`CODIGO_UNIDAD_SKU` IS NULL THEN ''N'' ELSE ''S'' END ' +
    'WHERE mapa.`ES_SKU` = ''S''',
    [],
    []);
  if AEsCambioArticulo then
    sArticulo := ':ARTICULO'
  else
    sArticulo := 'origen.`CODIGO_ART_SKU`';
  Ejecutar(
    'INSERT INTO `fza_articulos_skus` (`CODIGO_UNIDAD_SKU`, ' +
    '`CODIGO_ART_SKU`, `CODIGO_VAR_SKU`, `ESACTIVO_SKU`, ' +
    '`INSTANTE_MODIF`, `INSTANTE_ALTA`, `USUARIO_ALTA`, ' +
    '`USUARIO_MODIF`) SELECT mapa.`DESTINO`, ' + sArticulo + ', ' +
    'origen.`CODIGO_VAR_SKU`, CASE WHEN UPPER(TRIM(COALESCE(' +
    'origen.`ESACTIVO_SKU`, ''N''))) = ''S'' THEN ''S'' ELSE ''N'' END, ' +
    'CURRENT_TIMESTAMP, ' +
    'CURRENT_TIMESTAMP, :USUARIO, :USUARIO FROM ' +
    '`fza_articulos_skus` origen JOIN `' + TABLA_TEMPORAL + '` mapa ' +
    'ON mapa.`ORIGEN` = origen.`CODIGO_UNIDAD_SKU` LEFT JOIN ' +
    '`fza_articulos_skus` destino ON destino.`CODIGO_UNIDAD_SKU` = ' +
    'mapa.`DESTINO` WHERE mapa.`ES_SKU` = ''S'' AND ' +
    'destino.`CODIGO_UNIDAD_SKU` IS NULL',
    ['ARTICULO', 'USUARIO'],
    [AArticuloDestino, AUsuario]);
  Ejecutar(
    'UPDATE `fza_articulos_skus` destino JOIN `' + TABLA_TEMPORAL +
    '` mapa ON mapa.`DESTINO` = destino.`CODIGO_UNIDAD_SKU` JOIN ' +
    '`fza_articulos_skus` origen ON origen.`CODIGO_UNIDAD_SKU` = ' +
    'mapa.`ORIGEN` SET destino.`ESACTIVO_SKU` = CASE WHEN ' +
    'UPPER(TRIM(COALESCE(origen.`ESACTIVO_SKU`, ''N''))) = ''S'' ' +
    'THEN ''S'' ELSE destino.`ESACTIVO_SKU` END, ' +
    'destino.`INSTANTE_MODIF` = CURRENT_TIMESTAMP, ' +
    'destino.`USUARIO_MODIF` = :USUARIO WHERE mapa.`ES_SKU` = ''S''',
    ['USUARIO'],
    [AUsuario]);
end;

procedure TRepositorioCambioArticuloColorUniDAC.
  PrepararAtributosSkuDestino(
    const AColorDestino, AUsuario: string;
    AEsFusionColor: Boolean);
var
  sFiltro: string;
begin
  sFiltro := '';
  if AEsFusionColor then
    sFiltro := 'AND av.`ID_VA_AV` <> ''CO'' ';
  Ejecutar(
    'INSERT IGNORE INTO `fza_atributos_sku` ' +
    '(`CODIGO_UNIDAD_SKU_SA`, `ID_AV_SA`, `INSTANTE_MODIF`, ' +
    '`INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`) SELECT ' +
    'mapa.`DESTINO`, sa.`ID_AV_SA`, CURRENT_TIMESTAMP, ' +
    'CURRENT_TIMESTAMP, :USUARIO, :USUARIO FROM ' +
    '`fza_atributos_sku` sa JOIN `fza_atributos_valores` av ON ' +
    'av.`ID_AV` = sa.`ID_AV_SA` JOIN `' + TABLA_TEMPORAL + '` mapa ' +
    'ON mapa.`ORIGEN` = sa.`CODIGO_UNIDAD_SKU_SA` WHERE ' +
    'mapa.`ES_SKU` = ''S'' ' + sFiltro,
    ['USUARIO'],
    [AUsuario]);
  if AEsFusionColor then
  begin
    Ejecutar(
      'INSERT IGNORE INTO `fza_atributos_sku` ' +
      '(`CODIGO_UNIDAD_SKU_SA`, `ID_AV_SA`, `INSTANTE_MODIF`, ' +
      '`INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`) SELECT ' +
      'mapa.`DESTINO`, COALESCE((SELECT MIN(sa.`ID_AV_SA`) FROM ' +
      '`fza_atributos_sku` sa JOIN `fza_atributos_valores` av ON ' +
      'av.`ID_AV` = sa.`ID_AV_SA` WHERE ' +
      'sa.`CODIGO_UNIDAD_SKU_SA` = mapa.`DESTINO` AND ' +
      'av.`ID_VA_AV` = ''CO'' AND TRIM(av.`AV`) = TRIM(:COLOR) AND ' +
      'UPPER(TRIM(COALESCE(av.`ESACTIVO_AV`, ''N''))) = ''S''), ' +
      '(SELECT av.`ID_AV` FROM `fza_atributos_valores` av WHERE ' +
      'av.`ID_VA_AV` = ''CO'' AND TRIM(av.`AV`) = TRIM(:COLOR) AND ' +
      'UPPER(TRIM(COALESCE(av.`ESACTIVO_AV`, ''N''))) = ''S'' ' +
      'ORDER BY av.`ID_ATB_AV` IS NULL, av.`ID_AV` LIMIT 1)), ' +
      'CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, :USUARIO, :USUARIO ' +
      'FROM `' + TABLA_TEMPORAL + '` mapa WHERE mapa.`ES_SKU` = ''S''',
      ['COLOR', 'USUARIO'],
      [AColorDestino, AUsuario]);
  end;
end;

procedure TRepositorioCambioArticuloColorUniDAC.ConsolidarStock;
const
  CAMPOS =
    '`CANTIDAD_STK`, `VALOR_TOTAL_STK`, ' +
    '`CANTIDAD_PTE_RECIBIR_STK`, `CANTIDAD_PTE_SERVIR_STK`, ' +
    '`CANTIDAD_ENT_COMPRA_STK`, ' +
    '`CANTIDAD_ENT_TRASPASO_STK`, `CANTIDAD_SAL_TRASPASO_STK`, ' +
    '`CANTIDAD_ENT_DEPOSITO_STK`, `CANTIDAD_SAL_DEPOSITO_STK`, ' +
    '`CANTIDAD_SAL_VENTA_STK`, `CANTIDAD_ENT_REGULAR_STK`, ' +
    '`CANTIDAD_SAL_ALBVENTA_STK`, `CANTIDAD_ENT_ALBENTRADA_STK`';
  VALORES =
    'origen.`CANTIDAD_STK`, origen.`VALOR_TOTAL_STK`, ' +
    'origen.`CANTIDAD_PTE_RECIBIR_STK`, ' +
    'origen.`CANTIDAD_PTE_SERVIR_STK`, ' +
    'origen.`CANTIDAD_ENT_COMPRA_STK`, ' +
    'origen.`CANTIDAD_ENT_TRASPASO_STK`, ' +
    'origen.`CANTIDAD_SAL_TRASPASO_STK`, ' +
    'origen.`CANTIDAD_ENT_DEPOSITO_STK`, ' +
    'origen.`CANTIDAD_SAL_DEPOSITO_STK`, ' +
    'origen.`CANTIDAD_SAL_VENTA_STK`, ' +
    'origen.`CANTIDAD_ENT_REGULAR_STK`, ' +
    'origen.`CANTIDAD_SAL_ALBVENTA_STK`, ' +
    'origen.`CANTIDAD_ENT_ALBENTRADA_STK`';
  ACUMULAR =
    '`CANTIDAD_STK` = COALESCE(' +
    '`fza_articulos_stockactual`.`CANTIDAD_STK`, 0) + ' +
    'COALESCE(VALUES(`CANTIDAD_STK`), 0), ' +
    '`VALOR_TOTAL_STK` = COALESCE(' +
    '`fza_articulos_stockactual`.`VALOR_TOTAL_STK`, 0) + ' +
    'COALESCE(VALUES(`VALOR_TOTAL_STK`), 0), ' +
    '`CANTIDAD_PTE_RECIBIR_STK` = COALESCE(' +
    '`fza_articulos_stockactual`.`CANTIDAD_PTE_RECIBIR_STK`, 0) + ' +
    'COALESCE(VALUES(`CANTIDAD_PTE_RECIBIR_STK`), 0), ' +
    '`CANTIDAD_PTE_SERVIR_STK` = COALESCE(' +
    '`fza_articulos_stockactual`.`CANTIDAD_PTE_SERVIR_STK`, 0) + ' +
    'COALESCE(VALUES(`CANTIDAD_PTE_SERVIR_STK`), 0), ' +
    '`CANTIDAD_ENT_COMPRA_STK` = COALESCE(' +
    '`fza_articulos_stockactual`.`CANTIDAD_ENT_COMPRA_STK`, 0) + ' +
    'COALESCE(VALUES(`CANTIDAD_ENT_COMPRA_STK`), 0), ' +
    '`CANTIDAD_ENT_TRASPASO_STK` = COALESCE(' +
    '`fza_articulos_stockactual`.`CANTIDAD_ENT_TRASPASO_STK`, 0) + ' +
    'COALESCE(VALUES(`CANTIDAD_ENT_TRASPASO_STK`), 0), ' +
    '`CANTIDAD_SAL_TRASPASO_STK` = COALESCE(' +
    '`fza_articulos_stockactual`.`CANTIDAD_SAL_TRASPASO_STK`, 0) + ' +
    'COALESCE(VALUES(`CANTIDAD_SAL_TRASPASO_STK`), 0), ' +
    '`CANTIDAD_ENT_DEPOSITO_STK` = COALESCE(' +
    '`fza_articulos_stockactual`.`CANTIDAD_ENT_DEPOSITO_STK`, 0) + ' +
    'COALESCE(VALUES(`CANTIDAD_ENT_DEPOSITO_STK`), 0), ' +
    '`CANTIDAD_SAL_DEPOSITO_STK` = COALESCE(' +
    '`fza_articulos_stockactual`.`CANTIDAD_SAL_DEPOSITO_STK`, 0) + ' +
    'COALESCE(VALUES(`CANTIDAD_SAL_DEPOSITO_STK`), 0), ' +
    '`CANTIDAD_SAL_VENTA_STK` = COALESCE(' +
    '`fza_articulos_stockactual`.`CANTIDAD_SAL_VENTA_STK`, 0) + ' +
    'COALESCE(VALUES(`CANTIDAD_SAL_VENTA_STK`), 0), ' +
    '`CANTIDAD_ENT_REGULAR_STK` = COALESCE(' +
    '`fza_articulos_stockactual`.`CANTIDAD_ENT_REGULAR_STK`, 0) + ' +
    'COALESCE(VALUES(`CANTIDAD_ENT_REGULAR_STK`), 0), ' +
    '`CANTIDAD_SAL_ALBVENTA_STK` = COALESCE(' +
    '`fza_articulos_stockactual`.`CANTIDAD_SAL_ALBVENTA_STK`, 0) + ' +
    'COALESCE(VALUES(`CANTIDAD_SAL_ALBVENTA_STK`), 0), ' +
    '`CANTIDAD_ENT_ALBENTRADA_STK` = COALESCE(' +
    '`fza_articulos_stockactual`.`CANTIDAD_ENT_ALBENTRADA_STK`, 0) + ' +
    'COALESCE(VALUES(`CANTIDAD_ENT_ALBENTRADA_STK`), 0)';
begin
  Ejecutar(
    'INSERT INTO `fza_articulos_stockactual` (`CODIGO_ALM_STK`, ' +
    '`CODIGO_UNIDAD_STK`, `LOTE_STK`, `FECHA_CADUCIDAD_STK`, ' +
    CAMPOS + ', `PRECIO_MEDIO_STK`) SELECT origen.`CODIGO_ALM_STK`, ' +
    'mapa.`DESTINO`, origen.`LOTE_STK`, ' +
    'origen.`FECHA_CADUCIDAD_STK`, ' + VALORES + ', ' +
    'origen.`PRECIO_MEDIO_STK` FROM `fza_articulos_stockactual` origen ' +
    'JOIN `' + TABLA_TEMPORAL + '` mapa ON mapa.`ORIGEN` = ' +
    'origen.`CODIGO_UNIDAD_STK` WHERE mapa.`ES_SKU` = ''S'' ' +
    'ON DUPLICATE KEY UPDATE ' + ACUMULAR + ', `PRECIO_MEDIO_STK` = ' +
    'IF(`fza_articulos_stockactual`.`CANTIDAD_STK` > 0, ' +
    '`fza_articulos_stockactual`.`VALOR_TOTAL_STK` / ' +
    '`fza_articulos_stockactual`.`CANTIDAD_STK`, 0)',
    [],
    []);
  Ejecutar(
    'DELETE origen FROM `fza_articulos_stockactual` origen JOIN `' +
    TABLA_TEMPORAL + '` mapa ON mapa.`ORIGEN` = ' +
    'origen.`CODIGO_UNIDAD_STK` WHERE mapa.`ES_SKU` = ''S''',
    [],
    []);
end;

procedure TRepositorioCambioArticuloColorUniDAC.ConsolidarCostes(
  const AUsuario: string);
begin
  Ejecutar(
    'INSERT INTO `fza_articulos_skus_costes` ' +
    '(`CODIGO_UNIDAD_SKU_SKUC`, `PRECIO_ULT_COMPRA_SKUC`, ' +
    '`FECHA_ULT_COMPRA_SKUC`, `INSTANTE_MODIF`, `INSTANTE_ALTA`, ' +
    '`USUARIO_ALTA`, `USUARIO_MODIF`) SELECT mapa.`DESTINO`, ' +
    'origen.`PRECIO_ULT_COMPRA_SKUC`, ' +
    'origen.`FECHA_ULT_COMPRA_SKUC`, CURRENT_TIMESTAMP, ' +
    'CURRENT_TIMESTAMP, :USUARIO, :USUARIO FROM ' +
    '`fza_articulos_skus_costes` origen JOIN `' + TABLA_TEMPORAL +
    '` mapa ON mapa.`ORIGEN` = origen.`CODIGO_UNIDAD_SKU_SKUC` ' +
    'LEFT JOIN `fza_articulos_skus_costes` destino ON ' +
    'destino.`CODIGO_UNIDAD_SKU_SKUC` = mapa.`DESTINO` WHERE ' +
    'mapa.`ES_SKU` = ''S'' AND ' +
    'destino.`CODIGO_UNIDAD_SKU_SKUC` IS NULL',
    ['USUARIO'],
    [AUsuario]);
end;

procedure TRepositorioCambioArticuloColorUniDAC.ConsolidarTarifas(
  const AArticuloOrigen, AArticuloDestino, AUsuario: string;
  AEsCambioArticulo: Boolean);
var
  sAmbitoDestino: string;
  sMasAntigua: string;
  sSolapan: string;
begin
  if AEsCambioArticulo then
  begin
    Ejecutar(
      'UPDATE `fza_articulos_tarifas` dato LEFT JOIN `' +
      TABLA_TEMPORAL + '` mapa ON mapa.`ORIGEN` = ' +
      'dato.`CODIGO_UNIDAD_ARTTAR` SET dato.`CODIGO_UNIDAD_ARTTAR` = ' +
      'COALESCE(mapa.`DESTINO`, dato.`CODIGO_UNIDAD_ARTTAR`), ' +
      'dato.`CODIGO_ART_ARTTAR` = :ARTICULO, ' +
      'dato.`INSTANTE_MODIF` = dato.`INSTANTE_MODIF`, ' +
      'dato.`USUARIO_MODIF` = :USUARIO WHERE ' +
      'dato.`CODIGO_ART_ARTTAR` = :ORIGEN',
      ['ORIGEN', 'ARTICULO', 'USUARIO'],
      [AArticuloOrigen, AArticuloDestino, AUsuario]);
    sAmbitoDestino :=
      'antigua.`CODIGO_ART_ARTTAR` = :ARTICULO';
  end
  else
  begin
    Ejecutar(
      'UPDATE `fza_articulos_tarifas` dato JOIN `' + TABLA_TEMPORAL +
      '` mapa ON mapa.`ORIGEN` = dato.`CODIGO_UNIDAD_ARTTAR` SET ' +
      'dato.`CODIGO_UNIDAD_ARTTAR` = mapa.`DESTINO`, ' +
      'dato.`INSTANTE_MODIF` = dato.`INSTANTE_MODIF`, ' +
      'dato.`USUARIO_MODIF` = :USUARIO WHERE mapa.`ES_SKU` = ''S''',
      ['USUARIO'],
      [AUsuario]);
    sAmbitoDestino :=
      'EXISTS (SELECT 1 FROM `' + TABLA_TEMPORAL + '` mapa WHERE ' +
      'mapa.`ES_SKU` = ''S'' AND mapa.`DESTINO` = ' +
      'antigua.`CODIGO_UNIDAD_ARTTAR`)';
  end;
  sSolapan :=
    'COALESCE(antigua.`FECHA_DESDE_ARTTAR`, ''1000-01-01'') <= ' +
    'COALESCE(reciente.`FECHA_HASTA_ARTTAR`, ''9999-12-31'') AND ' +
    'COALESCE(reciente.`FECHA_DESDE_ARTTAR`, ''1000-01-01'') <= ' +
    'COALESCE(antigua.`FECHA_HASTA_ARTTAR`, ''9999-12-31'')';
  sMasAntigua :=
    '(COALESCE(antigua.`FECHA_DESDE_ARTTAR`, ''1000-01-01'') < ' +
    'COALESCE(reciente.`FECHA_DESDE_ARTTAR`, ''1000-01-01'') OR (' +
    'antigua.`FECHA_DESDE_ARTTAR` <=> ' +
    'reciente.`FECHA_DESDE_ARTTAR`) AND (' +
    'COALESCE(antigua.`INSTANTE_MODIF`, antigua.`INSTANTE_ALTA`) < ' +
    'COALESCE(reciente.`INSTANTE_MODIF`, reciente.`INSTANTE_ALTA`) ' +
    'OR (COALESCE(antigua.`INSTANTE_MODIF`, ' +
    'antigua.`INSTANTE_ALTA`) <=> ' +
    'COALESCE(reciente.`INSTANTE_MODIF`, reciente.`INSTANTE_ALTA`)) ' +
    'AND antigua.`CODIGO_UNICO_ARTTAR` < ' +
    'reciente.`CODIGO_UNICO_ARTTAR`))';
  Ejecutar(
    'DELETE antigua FROM `fza_articulos_tarifas` antigua JOIN ' +
    '`fza_articulos_tarifas` reciente ON ' +
    'reciente.`CODIGO_ART_ARTTAR` = antigua.`CODIGO_ART_ARTTAR` AND ' +
    'reciente.`CODIGO_UNIDAD_ARTTAR` = ' +
    'antigua.`CODIGO_UNIDAD_ARTTAR` AND ' +
    'reciente.`CODIGO_TAR_ARTTAR` <=> ' +
    'antigua.`CODIGO_TAR_ARTTAR` AND ' +
    'reciente.`CODIGO_UNICO_ARTTAR` <> ' +
    'antigua.`CODIGO_UNICO_ARTTAR` WHERE ' + sSolapan + ' AND ' +
    sMasAntigua + ' AND ' + sAmbitoDestino,
    ['ARTICULO'],
    [AArticuloDestino]);
end;

procedure TRepositorioCambioArticuloColorUniDAC.
  ConsolidarProveedoresArticulo(
    const AArticuloOrigen, AArticuloDestino, AUsuario: string);
begin
  Ejecutar(
    'INSERT INTO `fza_articulos_proveedores` (`CODIGO_PRV_AP`, ' +
    '`CODIGO_ART_AP`, `REF_PROVEEDOR_AP`, `PRECIO_ULT_COMPRA_AP`, ' +
    '`FECHA_VALIDEZ_AP`, `ESPROVEEDORPRINCIPAL_AP`, ' +
    '`INSTANTE_MODIF`, `INSTANTE_ALTA`, `USUARIO_ALTA`, ' +
    '`USUARIO_MODIF`) SELECT origen.`CODIGO_PRV_AP`, :DESTINO, ' +
    'origen.`REF_PROVEEDOR_AP`, origen.`PRECIO_ULT_COMPRA_AP`, ' +
    'origen.`FECHA_VALIDEZ_AP`, CASE WHEN EXISTS (SELECT 1 FROM ' +
    '`fza_articulos_proveedores` principal WHERE ' +
    'principal.`CODIGO_ART_AP` = :DESTINO AND ' +
    'principal.`ESPROVEEDORPRINCIPAL_AP` = ''S'') THEN ''N'' ELSE ' +
    'origen.`ESPROVEEDORPRINCIPAL_AP` END, CURRENT_TIMESTAMP, ' +
    'CURRENT_TIMESTAMP, :USUARIO, :USUARIO FROM ' +
    '`fza_articulos_proveedores` origen LEFT JOIN ' +
    '`fza_articulos_proveedores` destino ON ' +
    'destino.`CODIGO_PRV_AP` = origen.`CODIGO_PRV_AP` AND ' +
    'destino.`CODIGO_ART_AP` = :DESTINO WHERE ' +
    'origen.`CODIGO_ART_AP` = :ORIGEN AND ' +
    'destino.`CODIGO_PRV_AP` IS NULL',
    ['ORIGEN', 'DESTINO', 'USUARIO'],
    [AArticuloOrigen, AArticuloDestino, AUsuario]);
  Ejecutar(
    'UPDATE `fza_articulos_proveedores` dato JOIN (SELECT ' +
    '`CODIGO_ART_AP`, COALESCE(MIN(CASE WHEN ' +
    '`ESPROVEEDORPRINCIPAL_AP` = ''S'' THEN `CODIGO_PRV_AP` END), ' +
    'MIN(`CODIGO_PRV_AP`)) `PROVEEDOR_PRINCIPAL` FROM ' +
    '`fza_articulos_proveedores` WHERE `CODIGO_ART_AP` = :DESTINO ' +
    'GROUP BY `CODIGO_ART_AP`) elegido ON elegido.`CODIGO_ART_AP` = ' +
    'dato.`CODIGO_ART_AP` SET dato.`ESPROVEEDORPRINCIPAL_AP` = ' +
    'CASE WHEN dato.`CODIGO_PRV_AP` = elegido.`PROVEEDOR_PRINCIPAL` ' +
    'THEN ''S'' ELSE ''N'' END, dato.`INSTANTE_MODIF` = ' +
    'CURRENT_TIMESTAMP, dato.`USUARIO_MODIF` = :USUARIO WHERE ' +
    'dato.`CODIGO_ART_AP` = :DESTINO',
    ['DESTINO', 'USUARIO'],
    [AArticuloDestino, AUsuario]);
end;

procedure TRepositorioCambioArticuloColorUniDAC.ConsolidarCodigosBarras(
  const AUsuario: string);
begin
  Ejecutar(
    'DELETE origen FROM `fza_codigos_barras` origen JOIN `' +
    TABLA_TEMPORAL + '` mapa ON mapa.`ORIGEN` = ' +
    'origen.`CODIGO_UNIDAD_CB` JOIN `fza_codigos_barras` destino ON ' +
    'destino.`CODIGO_UNIDAD_CB` = mapa.`DESTINO` AND ' +
    'destino.`CODIGO_BARRAS_CB` = origen.`CODIGO_BARRAS_CB` AND ' +
    'destino.`TIPO_CODIGO_CB` <=> origen.`TIPO_CODIGO_CB` WHERE ' +
    'mapa.`ES_SKU` = ''S''',
    [],
    []);
  Ejecutar(
    'UPDATE `fza_codigos_barras` origen JOIN `' + TABLA_TEMPORAL +
    '` mapa ON mapa.`ORIGEN` = origen.`CODIGO_UNIDAD_CB` SET ' +
    'origen.`ESPRINCIPAL_CB` = ''N'' WHERE mapa.`ES_SKU` = ''S'' AND ' +
    'EXISTS (SELECT 1 FROM `fza_codigos_barras` destino WHERE ' +
    'destino.`CODIGO_UNIDAD_CB` = mapa.`DESTINO` AND ' +
    'destino.`ESPRINCIPAL_CB` = ''S'')',
    [],
    []);
  Ejecutar(
    'UPDATE `fza_codigos_barras` dato JOIN `' + TABLA_TEMPORAL +
    '` mapa ON mapa.`ORIGEN` = dato.`CODIGO_UNIDAD_CB` SET ' +
    'dato.`CODIGO_UNIDAD_CB` = mapa.`DESTINO`, ' +
    'dato.`INSTANTE_MODIF` = CURRENT_TIMESTAMP, ' +
    'dato.`USUARIO_MODIF` = :USUARIO WHERE mapa.`ES_SKU` = ''S''',
    ['USUARIO'],
    [AUsuario]);
  Ejecutar(
    'UPDATE `fza_codigos_barras` dato JOIN `' + TABLA_TEMPORAL +
    '` mapa ON mapa.`DESTINO` = dato.`CODIGO_UNIDAD_CB` JOIN (' +
    'SELECT `CODIGO_UNIDAD_CB`, COALESCE(MIN(CASE WHEN ' +
    '`ESPRINCIPAL_CB` = ''S'' THEN `ID_CB` END), MIN(`ID_CB`)) ' +
    '`ID_PRINCIPAL` FROM `fza_codigos_barras` GROUP BY ' +
    '`CODIGO_UNIDAD_CB`) elegido ON elegido.`CODIGO_UNIDAD_CB` = ' +
    'dato.`CODIGO_UNIDAD_CB` SET dato.`ESPRINCIPAL_CB` = CASE WHEN ' +
    'dato.`ID_CB` = elegido.`ID_PRINCIPAL` THEN ''S'' ELSE ''N'' END, ' +
    'dato.`INSTANTE_MODIF` = CURRENT_TIMESTAMP, ' +
    'dato.`USUARIO_MODIF` = :USUARIO WHERE mapa.`ES_SKU` = ''S''',
    ['USUARIO'],
    [AUsuario]);
end;

procedure TRepositorioCambioArticuloColorUniDAC.ConsolidarBloqueos(
  const AUsuario: string);
begin
  Ejecutar(
    'DELETE origen FROM `fza_stock_bloqueos` origen JOIN `' +
    TABLA_TEMPORAL + '` mapa ON mapa.`ORIGEN` = ' +
    'origen.`CODIGO_UNIDAD_STKBLQ` JOIN `fza_stock_bloqueos` destino ' +
    'ON destino.`CODIGO_UNIDAD_STKBLQ` = mapa.`DESTINO` AND ' +
    'destino.`CODIGO_ALM_STKBLQ` = origen.`CODIGO_ALM_STKBLQ` WHERE ' +
    'mapa.`ES_SKU` = ''S''',
    [],
    []);
  Ejecutar(
    'UPDATE `fza_stock_bloqueos` dato JOIN `' + TABLA_TEMPORAL +
    '` mapa ON mapa.`ORIGEN` = dato.`CODIGO_UNIDAD_STKBLQ` SET ' +
    'dato.`CODIGO_UNIDAD_STKBLQ` = mapa.`DESTINO`, ' +
    'dato.`INSTANTE_MODIF` = CURRENT_TIMESTAMP, ' +
    'dato.`USUARIO_MODIF` = :USUARIO WHERE mapa.`ES_SKU` = ''S''',
    ['USUARIO'],
    [AUsuario]);
end;

function TRepositorioCambioArticuloColorUniDAC.
  ProcedimientoPmpFusionDisponible: Boolean;
begin
  Result := Existe(
    'SELECT 1 FROM `INFORMATION_SCHEMA`.`ROUTINES` rutina WHERE ' +
    'rutina.`ROUTINE_SCHEMA` = DATABASE() AND ' +
    'rutina.`ROUTINE_TYPE` = ''PROCEDURE'' AND ' +
    'rutina.`ROUTINE_NAME` = ''PRC_FZA_FUSION_RECALCULAR_PMP'' AND ' +
    '(SELECT COUNT(*) FROM `INFORMATION_SCHEMA`.`PARAMETERS` parametro ' +
    'WHERE parametro.`SPECIFIC_SCHEMA` = rutina.`ROUTINE_SCHEMA` AND ' +
    'parametro.`SPECIFIC_NAME` = rutina.`ROUTINE_NAME` AND ' +
    'parametro.`PARAMETER_MODE` = ''IN'' AND (' +
    '(parametro.`ORDINAL_POSITION` = 1 AND ' +
    'UPPER(parametro.`PARAMETER_NAME`) = ''P_EMPRESA'') OR ' +
    '(parametro.`ORDINAL_POSITION` = 2 AND ' +
    'UPPER(parametro.`PARAMETER_NAME`) = ''P_ALMACEN'') OR ' +
    '(parametro.`ORDINAL_POSITION` = 3 AND ' +
    'UPPER(parametro.`PARAMETER_NAME`) = ''P_SKU''))) = 3 AND ' +
    '(SELECT COUNT(*) FROM `INFORMATION_SCHEMA`.`PARAMETERS` parametro ' +
    'WHERE parametro.`SPECIFIC_SCHEMA` = rutina.`ROUTINE_SCHEMA` AND ' +
    'parametro.`SPECIFIC_NAME` = rutina.`ROUTINE_NAME` AND ' +
    'parametro.`ORDINAL_POSITION` > 0) = 3 LIMIT 1',
    [],
    []);
end;

procedure TRepositorioCambioArticuloColorUniDAC.RecalcularPmpDestinos;
var
  aDestinos: TDestinosPmp;
  i: Integer;
  oConsulta: TUniQuery;
  oProcedimiento: TUniStoredProc;
begin
  oConsulta := TUniQuery.Create(nil);
  oProcedimiento := TUniStoredProc.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT DISTINCT COALESCE(ambito.`CODIGO_EMP`, ' +
      'almacen.`CODIGO_EMP_ALM`, '''') ' +
      '`CODIGO_EMP_MOV`, ambito.`CODIGO_ALM` `CODIGO_ALM_MOV`, ' +
      'ambito.`DESTINO` FROM (SELECT ' +
      'mapa.`DESTINO`, movimiento.`CODIGO_EMP_MOV` `CODIGO_EMP`, ' +
      'movimiento.`CODIGO_ALM_MOV` `CODIGO_ALM` FROM ' +
      '`fza_movimientos_almacen` movimiento JOIN `' + TABLA_TEMPORAL +
      '` mapa ON mapa.`DESTINO` = movimiento.`CODIGO_UNIDAD_MOV` ' +
      'WHERE mapa.`ES_SKU` = ''S'' AND ' +
      'movimiento.`ESACTIVO_MOV` = ''S'' UNION SELECT mapa.`DESTINO`, ' +
      'NULL, stock.`CODIGO_ALM_STK` FROM ' +
      '`fza_articulos_stockactual` stock ' +
      'JOIN `' + TABLA_TEMPORAL + '` mapa ON mapa.`DESTINO` = ' +
      'stock.`CODIGO_UNIDAD_STK` WHERE mapa.`ES_SKU` = ''S'' UNION ' +
      'SELECT mapa.`DESTINO`, linea.`CODIGO_EMP_INVLIN`, ' +
      'linea.`CODIGO_ALM_INVLIN` FROM ' +
      '`fza_inventarios_lineas` linea JOIN `fza_inventarios` inventario ' +
      'ON inventario.`CODIGO_EMP_INV` = linea.`CODIGO_EMP_INVLIN` AND ' +
      'inventario.`CODIGO_ALM_INV` = linea.`CODIGO_ALM_INVLIN` AND ' +
      'inventario.`SERIE_INV` = linea.`SERIE_INV_INVLIN` AND ' +
      'inventario.`NUMERO_INV` = linea.`NUMERO_INV_INVLIN` JOIN `' +
      TABLA_TEMPORAL + '` mapa ON mapa.`DESTINO` = ' +
      'linea.`CODIGO_UNIDAD_INVLIN` WHERE mapa.`ES_SKU` = ''S'' AND ' +
      'inventario.`ESTADO_INV` = ''APLICADO'') ambito ' +
      'LEFT JOIN `fza_almacenes` almacen ON ' +
      'almacen.`CODIGO_ALM_ALM` = ambito.`CODIGO_ALM` ORDER BY ' +
      'ambito.`DESTINO`, `CODIGO_EMP_MOV`, `CODIGO_ALM_MOV`';
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      SetLength(aDestinos, Length(aDestinos) + 1);
      aDestinos[High(aDestinos)].Empresa :=
        oConsulta.FieldByName('CODIGO_EMP_MOV').AsString;
      aDestinos[High(aDestinos)].Almacen :=
        oConsulta.FieldByName('CODIGO_ALM_MOV').AsString;
      aDestinos[High(aDestinos)].Sku :=
        oConsulta.FieldByName('DESTINO').AsString;
      oConsulta.Next;
    end;
    oConsulta.Close;
    if Length(aDestinos) > 0 then
    begin
      if not ProcedimientoPmpFusionDisponible then
      begin
        raise Exception.Create(SErrorProcedimientoRecalcularPmpNoDisponible);
      end;
      oProcedimiento.Connection := FConexion;
      oProcedimiento.StoredProcName :=
        'PRC_FZA_FUSION_RECALCULAR_PMP';
      oProcedimiento.Params.Clear;
      oProcedimiento.Params.CreateParam(
        ftString,
        'p_EMPRESA',
        ptInput);
      oProcedimiento.Params.CreateParam(
        ftString,
        'p_ALMACEN',
        ptInput);
      oProcedimiento.Params.CreateParam(
        ftString,
        'p_SKU',
        ptInput);
      for i := Low(aDestinos) to High(aDestinos) do
      begin
        oProcedimiento.ParamByName('p_EMPRESA').AsString :=
          aDestinos[i].Empresa;
        oProcedimiento.ParamByName('p_ALMACEN').AsString :=
          aDestinos[i].Almacen;
        oProcedimiento.ParamByName('p_SKU').AsString :=
          aDestinos[i].Sku;
        oProcedimiento.ExecProc;
      end;
    end;
  finally
    oProcedimiento.Free;
    oConsulta.Free;
  end;
end;

procedure TRepositorioCambioArticuloColorUniDAC.
  ConsolidarReferenciasUnidad(const AUsuario: string);
begin
  ConsolidarStock;
  ConsolidarCostes(AUsuario);
  ConsolidarCodigosBarras(AUsuario);
  ConsolidarBloqueos(AUsuario);
  ActualizarReferenciasUnidad(AUsuario);
  RecalcularPmpDestinos;
end;

procedure TRepositorioCambioArticuloColorUniDAC.DesactivarSkuOrigen(
  const AUsuario: string);
begin
  Ejecutar(
    'UPDATE `fza_articulos_skus` origen JOIN `' + TABLA_TEMPORAL +
    '` mapa ON mapa.`ORIGEN` = origen.`CODIGO_UNIDAD_SKU` SET ' +
    'origen.`ESACTIVO_SKU` = ''N'', ' +
    'origen.`INSTANTE_MODIF` = CURRENT_TIMESTAMP, ' +
    'origen.`USUARIO_MODIF` = :USUARIO WHERE mapa.`ES_SKU` = ''S''',
    ['USUARIO'],
    [AUsuario]);
end;

procedure TRepositorioCambioArticuloColorUniDAC.EliminarAtributosSkuOrigen;
begin
  Ejecutar(
    'DELETE sa FROM `fza_atributos_sku` sa JOIN `' + TABLA_TEMPORAL +
    '` mapa ON mapa.`ORIGEN` = sa.`CODIGO_UNIDAD_SKU_SA` WHERE ' +
    'mapa.`ES_SKU` = ''S''',
    [],
    []);
end;

procedure TRepositorioCambioArticuloColorUniDAC.LimpiarBasicosColorFusion(
  const AColorAntiguo, AColorDestino, AUsuario: string);
begin
  Ejecutar(
    'UPDATE `fza_articulos_atributos_basicos` aab ' +
    'JOIN `fza_atributos_valores` av ON av.`ID_AV` = aab.`ID_AV_AAB` ' +
    'SET aab.`ID_ATB_AAB` = NULL, ' +
    'aab.`DESCRIPCION_AAB` = NULL, ' +
    'aab.`USUARIO_MODIF` = :USUARIO ' +
    'WHERE av.`ID_VA_AV` = ''CO'' AND (' +
    'TRIM(av.`AV`) = TRIM(:ANTERIOR) OR ' +
    'TRIM(av.`AV`) = TRIM(:DESTINO))',
    ['ANTERIOR', 'DESTINO', 'USUARIO'],
    [AColorAntiguo, AColorDestino, AUsuario]);
  Ejecutar(
    'UPDATE `fza_atributos_conjuntos_det` acd ' +
    'JOIN `fza_atributos_valores` av ON av.`ID_AV` = acd.`ID_AV_ACD` ' +
    'SET acd.`ID_ATB_ACD` = NULL, ' +
    'acd.`USUARIO_MODIF` = :USUARIO ' +
    'WHERE av.`ID_VA_AV` = ''CO'' AND (' +
    'TRIM(av.`AV`) = TRIM(:ANTERIOR) OR ' +
    'TRIM(av.`AV`) = TRIM(:DESTINO))',
    ['ANTERIOR', 'DESTINO', 'USUARIO'],
    [AColorAntiguo, AColorDestino, AUsuario]);
  Ejecutar(
    'UPDATE `fza_atributos_valores` SET `ID_ATB_AV` = NULL, ' +
    '`DESCRIPCION_AV` = NULL, ' +
    '`USUARIO_MODIF` = :USUARIO WHERE `ID_VA_AV` = ''CO'' ' +
    'AND (TRIM(`AV`) = TRIM(:ANTERIOR) OR ' +
    'TRIM(`AV`) = TRIM(:DESTINO))',
    ['ANTERIOR', 'DESTINO', 'USUARIO'],
    [AColorAntiguo, AColorDestino, AUsuario]);
end;

procedure TRepositorioCambioArticuloColorUniDAC.DesactivarArticuloMaestro(
  const AArticuloAntiguo, AUsuario: string);
begin
  Ejecutar(
    'UPDATE `fza_articulos` SET `ESACTIVO_ART` = ''N'', ' +
    '`INSTANTE_MODIF` = CURRENT_TIMESTAMP, `USUARIO_MODIF` = :USUARIO ' +
    'WHERE `CODIGO_ART_ART` = :ARTICULO',
    ['ARTICULO', 'USUARIO'],
    [AArticuloAntiguo, AUsuario]);
end;

procedure TRepositorioCambioArticuloColorUniDAC.ConsolidarCatalogoColor(
  const AColorAntiguo, AColorDestino, AUsuario: string);
const
  SQL_ID_DESTINO =
    '(SELECT destino.`ID_AV` FROM `fza_atributos_valores` destino ' +
    'WHERE destino.`ID_VA_AV` = ''CO'' AND ' +
    'TRIM(destino.`AV`) = TRIM(:DESTINO) AND ' +
    'UPPER(TRIM(COALESCE(destino.`ESACTIVO_AV`, ''N''))) = ''S'' ' +
    'ORDER BY destino.`ID_ATB_AV` IS NULL, destino.`ID_AV` LIMIT 1)';
begin
  Ejecutar(
    'DELETE origen FROM `fza_articulos_atributos_basicos` origen ' +
    'JOIN `fza_atributos_valores` av_origen ON ' +
    'av_origen.`ID_AV` = origen.`ID_AV_AAB` AND ' +
    'av_origen.`ID_VA_AV` = ''CO'' AND ' +
    'TRIM(av_origen.`AV`) = TRIM(:ANTERIOR) WHERE EXISTS (' +
    'SELECT 1 FROM `fza_articulos_atributos_basicos` dato JOIN ' +
    '`fza_atributos_valores` av_destino ON ' +
    'av_destino.`ID_AV` = dato.`ID_AV_AAB` WHERE ' +
    'dato.`CODIGO_ART_AAB` = origen.`CODIGO_ART_AAB` AND ' +
    'av_destino.`ID_VA_AV` = ''CO'' AND ' +
    'TRIM(av_destino.`AV`) = TRIM(:DESTINO))',
    ['ANTERIOR', 'DESTINO'],
    [AColorAntiguo, AColorDestino]);
  Ejecutar(
    'UPDATE `fza_articulos_atributos_basicos` origen JOIN ' +
    '`fza_atributos_valores` av_origen ON ' +
    'av_origen.`ID_AV` = origen.`ID_AV_AAB` SET ' +
    'origen.`ID_AV_AAB` = ' + SQL_ID_DESTINO + ', ' +
    'origen.`ID_ATB_AAB` = NULL, origen.`DESCRIPCION_AAB` = NULL, ' +
    'origen.`USUARIO_MODIF` = :USUARIO WHERE ' +
    'av_origen.`ID_VA_AV` = ''CO'' AND ' +
    'TRIM(av_origen.`AV`) = TRIM(:ANTERIOR)',
    ['ANTERIOR', 'DESTINO', 'USUARIO'],
    [AColorAntiguo, AColorDestino, AUsuario]);
  Ejecutar(
    'DELETE origen FROM `fza_atributos_conjuntos_det` origen JOIN ' +
    '`fza_atributos_valores` av_origen ON ' +
    'av_origen.`ID_AV` = origen.`ID_AV_ACD` AND ' +
    'av_origen.`ID_VA_AV` = ''CO'' AND ' +
    'TRIM(av_origen.`AV`) = TRIM(:ANTERIOR) WHERE EXISTS (' +
    'SELECT 1 FROM `fza_atributos_conjuntos_det` dato JOIN ' +
    '`fza_atributos_valores` av_destino ON ' +
    'av_destino.`ID_AV` = dato.`ID_AV_ACD` WHERE ' +
    'dato.`ID_AC_ACD` = origen.`ID_AC_ACD` AND ' +
    'av_destino.`ID_VA_AV` = ''CO'' AND ' +
    'TRIM(av_destino.`AV`) = TRIM(:DESTINO))',
    ['ANTERIOR', 'DESTINO'],
    [AColorAntiguo, AColorDestino]);
  Ejecutar(
    'UPDATE `fza_atributos_conjuntos_det` origen JOIN ' +
    '`fza_atributos_valores` av_origen ON ' +
    'av_origen.`ID_AV` = origen.`ID_AV_ACD` SET ' +
    'origen.`ID_AV_ACD` = ' + SQL_ID_DESTINO + ', ' +
    'origen.`ID_ATB_ACD` = NULL, origen.`USUARIO_MODIF` = :USUARIO ' +
    'WHERE av_origen.`ID_VA_AV` = ''CO'' AND ' +
    'TRIM(av_origen.`AV`) = TRIM(:ANTERIOR)',
    ['ANTERIOR', 'DESTINO', 'USUARIO'],
    [AColorAntiguo, AColorDestino, AUsuario]);
  LimpiarBasicosColorFusion(
    AColorAntiguo,
    AColorDestino,
    AUsuario);
end;

procedure TRepositorioCambioArticuloColorUniDAC.ActualizarColorMaestro(
  const AAnterior, ANuevo, AUsuario: string;
  AFusionar: Boolean);
var
  sAuditoria: string;
begin
  if AFusionar then
  begin
    ConsolidarCatalogoColor(AAnterior, ANuevo, AUsuario);
    Ejecutar(
      'UPDATE `fza_atributos_valores` SET `ESACTIVO_AV` = ''N'', ' +
      '`ID_ATB_AV` = NULL, `DESCRIPCION_AV` = NULL, ' +
      '`INSTANTE_MODIF` = CURRENT_TIMESTAMP, ' +
      '`USUARIO_MODIF` = :USUARIO WHERE `ID_VA_AV` = ''CO'' AND ' +
      'TRIM(`AV`) = TRIM(:ANTERIOR)',
      ['ANTERIOR', 'USUARIO'],
      [AAnterior, AUsuario]);
  end
  else
  begin
    Ejecutar(
      'UPDATE `fza_articulos_atributos_basicos` aab ' +
      'JOIN `fza_atributos_valores` av ON ' +
      'av.`ID_AV` = aab.`ID_AV_AAB` ' +
      'SET aab.`DESCRIPCION_AAB` = NULL, ' +
      'aab.`USUARIO_MODIF` = :USUARIO ' +
      'WHERE av.`ID_VA_AV` = ''CO'' AND ' +
      'TRIM(av.`AV`) = TRIM(:ANTERIOR)',
      ['ANTERIOR', 'USUARIO'],
      [AAnterior, AUsuario]);
  end;
  if not AFusionar then
  begin
    sAuditoria := '';
    if CampoExiste('fza_atributos_valores', 'INSTANTE_MODIF') then
      sAuditoria := ', `INSTANTE_MODIF` = CURRENT_TIMESTAMP';
    if CampoExiste('fza_atributos_valores', 'USUARIO_MODIF') then
      sAuditoria := sAuditoria + ', `USUARIO_MODIF` = :USUARIO';
    Ejecutar(
      'UPDATE `fza_atributos_valores` SET `AV` = :NUEVO, ' +
      '`DESCRIPCION_AV` = NULL' + sAuditoria + ' WHERE ' +
      '`ID_VA_AV` = ''CO'' AND TRIM(`AV`) = TRIM(:ANTERIOR)',
      ['ANTERIOR', 'NUEVO', 'USUARIO'],
      [AAnterior, ANuevo, AUsuario]);
  end;
end;

function TValidadorCambioArticuloColorUniDAC.FusionColorEsSegura(
  const AAnterior, ANuevo: string): Boolean;
begin
  Result := not Existe(
    'SELECT 1 FROM `fza_atributos_sku` sa ' +
    'JOIN `fza_atributos_valores` origen ON ' +
    'origen.`ID_AV` = sa.`ID_AV_SA` AND ' +
    'origen.`ID_VA_AV` = ''CO'' AND ' +
    'TRIM(origen.`AV`) = TRIM(:ANTERIOR) ' +
    'JOIN `fza_atributos_sku` sa_destino ON ' +
    'sa_destino.`CODIGO_UNIDAD_SKU_SA` = ' +
    'sa.`CODIGO_UNIDAD_SKU_SA` ' +
    'JOIN `fza_atributos_valores` destino ON ' +
    'destino.`ID_AV` = sa_destino.`ID_AV_SA` AND ' +
    'destino.`ID_VA_AV` = ''CO'' AND ' +
    'TRIM(destino.`AV`) = TRIM(:NUEVO) LIMIT 1',
    ['ANTERIOR', 'NUEVO'],
    [AAnterior, ANuevo]);
  if Result then
  begin
    Result := not Existe(
      'SELECT afectados.`CODIGO_UNIDAD` FROM (SELECT DISTINCT ' +
      'sa.`CODIGO_UNIDAD_SKU_SA` `CODIGO_UNIDAD` FROM ' +
      '`fza_atributos_sku` sa JOIN `fza_atributos_valores` av ON ' +
      'av.`ID_AV` = sa.`ID_AV_SA` WHERE av.`ID_VA_AV` = ''CO'' AND ' +
      'TRIM(av.`AV`) = TRIM(:ANTERIOR)) afectados ' +
      'JOIN `fza_atributos_sku` todos ON ' +
      'todos.`CODIGO_UNIDAD_SKU_SA` = afectados.`CODIGO_UNIDAD` ' +
      'JOIN `fza_atributos_valores` av_todos ON ' +
      'av_todos.`ID_AV` = todos.`ID_AV_SA` ' +
      'WHERE av_todos.`ID_VA_AV` = ''CO'' ' +
      'GROUP BY afectados.`CODIGO_UNIDAD` ' +
      'HAVING COUNT(*) <> 1 LIMIT 1',
      ['ANTERIOR'],
      [AAnterior]);
  end;
  if Result then
    Result := FusionUnidadesEsSegura(ANuevo, '', False);
  if Result then
    Result := not HayColisionUnidadesNoConsolidable('', False);
end;

function TValidadorCambioArticuloColorUniDAC.FusionArticuloEsSegura(
  const AAnterior, ANuevo: string): Boolean;
begin
  Result := not Existe(
    'SELECT 1 FROM `fza_articulos` origen ' +
    'JOIN `fza_articulos` destino ON ' +
    'destino.`CODIGO_ART_ART` = :NUEVO ' +
    'WHERE origen.`CODIGO_ART_ART` = :ANTERIOR AND NOT (' +
    'origen.`TIPO_ART` <=> destino.`TIPO_ART` AND ' +
    'origen.`TIPO_CANTIDAD_ART` <=> destino.`TIPO_CANTIDAD_ART` AND ' +
    'origen.`ESTRAZABLE_ART` <=> destino.`ESTRAZABLE_ART` AND ' +
    'origen.`ESVARIACION_ART` <=> destino.`ESVARIACION_ART` AND ' +
    'origen.`TIPO_VARIACION_ART` <=> ' +
    'destino.`TIPO_VARIACION_ART`) LIMIT 1',
    ['ANTERIOR', 'NUEVO'],
    [AAnterior, ANuevo]);
  if Result then
  begin
    Result := not Existe(
      'SELECT 1 FROM `fza_articulos_skus` sku ' +
      'JOIN `fza_articulos` destino ON ' +
      'destino.`CODIGO_ART_ART` = :NUEVO ' +
      'WHERE sku.`CODIGO_ART_SKU` = :ANTERIOR AND NOT (' +
      '(destino.`ESVARIACION_ART` = ''N'' AND COALESCE(NULLIF(' +
      'TRIM(sku.`CODIGO_VAR_SKU`), ''''), ''-'') = ''-'') OR ' +
      '(destino.`ESVARIACION_ART` = ''S'' AND ' +
      'sku.`CODIGO_VAR_SKU` <=> destino.`TIPO_VARIACION_ART`)) LIMIT 1',
      ['ANTERIOR', 'NUEVO'],
      [AAnterior, ANuevo]);
  end;
  if Result then
  begin
    Result := not Existe(
      'SELECT 1 FROM `fza_articulos_atributos_basicos` origen ' +
      'JOIN `fza_atributos_valores` av_origen ON ' +
      'av_origen.`ID_AV` = origen.`ID_AV_AAB` ' +
      'JOIN `fza_articulos_atributos_basicos` destino ON ' +
      'destino.`CODIGO_ART_AAB` = :NUEVO ' +
      'JOIN `fza_atributos_valores` av_destino ON ' +
      'av_destino.`ID_AV` = destino.`ID_AV_AAB` AND ' +
      'av_destino.`ID_VA_AV` = av_origen.`ID_VA_AV` AND ' +
      'TRIM(av_destino.`AV`) = TRIM(av_origen.`AV`) ' +
      'WHERE origen.`CODIGO_ART_AAB` = :ANTERIOR AND NOT (' +
      'origen.`ID_AV_AAB` = destino.`ID_AV_AAB` AND ' +
      'origen.`ID_ATB_AAB` <=> destino.`ID_ATB_AAB` AND ' +
      'origen.`DESCRIPCION_AAB` <=> destino.`DESCRIPCION_AAB` AND ' +
      'origen.`ORDEN_AAB` <=> destino.`ORDEN_AAB`) LIMIT 1',
      ['ANTERIOR', 'NUEVO'],
      [AAnterior, ANuevo]);
  end;
  if Result then
  begin
    Result := not Existe(
      'SELECT 1 FROM `fza_articulos_conjuntos_asign` dato WHERE (' +
      'dato.`CODIGO_ART_ACA` = :ANTERIOR AND NOT EXISTS (SELECT 1 ' +
      'FROM `fza_articulos_conjuntos_asign` otro WHERE ' +
      'otro.`CODIGO_ART_ACA` = :NUEVO AND ' +
      'otro.`ID_VA_ACA` = dato.`ID_VA_ACA` AND ' +
      'otro.`ID_AC_ACA` <=> dato.`ID_AC_ACA` AND ' +
      'otro.`ORDEN_ACA` <=> dato.`ORDEN_ACA` AND ' +
      'otro.`ESGENERACION_AUTO_ACA` <=> ' +
      'dato.`ESGENERACION_AUTO_ACA`)) OR (' +
      'dato.`CODIGO_ART_ACA` = :NUEVO AND NOT EXISTS (SELECT 1 ' +
      'FROM `fza_articulos_conjuntos_asign` otro WHERE ' +
      'otro.`CODIGO_ART_ACA` = :ANTERIOR AND ' +
      'otro.`ID_VA_ACA` = dato.`ID_VA_ACA` AND ' +
      'otro.`ID_AC_ACA` <=> dato.`ID_AC_ACA` AND ' +
      'otro.`ORDEN_ACA` <=> dato.`ORDEN_ACA` AND ' +
      'otro.`ESGENERACION_AUTO_ACA` <=> ' +
      'dato.`ESGENERACION_AUTO_ACA`)) LIMIT 1',
      ['ANTERIOR', 'NUEVO'],
      [AAnterior, ANuevo]);
  end;
  if Result then
  begin
    Result := not Existe(
      'SELECT 1 FROM `fza_articulos_fotos` origen LEFT JOIN `' +
      TABLA_TEMPORAL + '` mapa ON mapa.`ORIGEN` = ' +
      'origen.`CODIGO_UNIDAD_FOT` JOIN `fza_articulos_fotos` destino ' +
      'ON destino.`CODIGO_ART_FOT` = :NUEVO AND ' +
      'destino.`CODIGO_UNIDAD_FOT` = COALESCE(' +
      'mapa.`DESTINO`, origen.`CODIGO_UNIDAD_FOT`) AND ' +
      'destino.`ORDEN_FOT` = origen.`ORDEN_FOT` ' +
      'WHERE origen.`CODIGO_ART_FOT` = :ANTERIOR LIMIT 1',
      ['ANTERIOR', 'NUEVO'],
      [AAnterior, ANuevo]);
  end;
  if Result then
  begin
    Result := not Existe(
      'SELECT 1 FROM `fza_articulos_propiedades` origen LEFT JOIN `' +
      TABLA_TEMPORAL + '` mapa ON mapa.`ORIGEN` = ' +
      'origen.`CODIGO_UNIDAD_ARTPROP` ' +
      'JOIN `fza_articulos_propiedades` destino ON ' +
      'destino.`CODIGO_ART_ART` = :NUEVO AND ' +
      'destino.`CODIGO_PROP_ARTPROP` = ' +
      'origen.`CODIGO_PROP_ARTPROP` AND ' +
      'destino.`CODIGO_UNIDAD_ARTPROP` = COALESCE(' +
      'mapa.`DESTINO`, origen.`CODIGO_UNIDAD_ARTPROP`) ' +
      'WHERE origen.`CODIGO_ART_ART` = :ANTERIOR LIMIT 1',
      ['ANTERIOR', 'NUEVO'],
      [AAnterior, ANuevo]);
  end;
  if Result then
  begin
    Result := not Existe(
      'SELECT 1 FROM `fza_tarifas_cambios_lineas` origen LEFT JOIN `' +
      TABLA_TEMPORAL + '` mapa ON mapa.`ORIGEN` = ' +
      'origen.`CODIGO_UNIDAD_SKU_TARCLIN` ' +
      'JOIN `fza_tarifas_cambios_lineas` destino ON ' +
      'destino.`CODIGO_ART_TARCLIN` = :NUEVO AND ' +
      'destino.`CODIGO_TARC_TARCLIN` = ' +
      'origen.`CODIGO_TARC_TARCLIN` AND ' +
      'destino.`CODIGO_UNIDAD_SKU_TARCLIN` = COALESCE(' +
      'mapa.`DESTINO`, origen.`CODIGO_UNIDAD_SKU_TARCLIN`) ' +
      'WHERE origen.`CODIGO_ART_TARCLIN` = :ANTERIOR LIMIT 1',
      ['ANTERIOR', 'NUEVO'],
      [AAnterior, ANuevo]);
  end;
  if Result then
  begin
    Result := not Existe(
      'SELECT 1 FROM `fza_articulos_vinculos` origen WHERE ' +
      '(origen.`CODIGO_ART_PADRE_ARTVIN` = :ANTERIOR OR ' +
      'origen.`CODIGO_ART_HIJO_ARTVIN` = :ANTERIOR) AND (' +
      'CASE WHEN origen.`CODIGO_ART_PADRE_ARTVIN` = :ANTERIOR ' +
      'THEN :NUEVO ELSE origen.`CODIGO_ART_PADRE_ARTVIN` END = ' +
      'CASE WHEN origen.`CODIGO_ART_HIJO_ARTVIN` = :ANTERIOR ' +
      'THEN :NUEVO ELSE origen.`CODIGO_ART_HIJO_ARTVIN` END OR ' +
      'EXISTS (SELECT 1 FROM `fza_articulos_vinculos` destino ' +
      'WHERE destino.`ID_ARTVIN` <> origen.`ID_ARTVIN` AND ' +
      'destino.`CODIGO_ART_PADRE_ARTVIN` = CASE WHEN ' +
      'origen.`CODIGO_ART_PADRE_ARTVIN` = :ANTERIOR THEN :NUEVO ' +
      'ELSE origen.`CODIGO_ART_PADRE_ARTVIN` END AND ' +
      'destino.`CODIGO_ART_HIJO_ARTVIN` = CASE WHEN ' +
      'origen.`CODIGO_ART_HIJO_ARTVIN` = :ANTERIOR THEN :NUEVO ' +
      'ELSE origen.`CODIGO_ART_HIJO_ARTVIN` END)) LIMIT 1',
      ['ANTERIOR', 'NUEVO'],
      [AAnterior, ANuevo]);
  end;
  if Result then
    Result := FusionUnidadesEsSegura('', ANuevo, True);
  if Result then
    Result := not HayColisionUnidadesNoConsolidable(ANuevo, True);
end;

procedure TRepositorioCambioArticuloColorUniDAC.PrepararFusionArticulo(
  const AAnterior, ANuevo: string);
begin
  Ejecutar(
    'DELETE origen FROM `fza_articulos_atributos_basicos` origen ' +
    'JOIN `fza_articulos_atributos_basicos` destino ON ' +
    'destino.`CODIGO_ART_AAB` = :NUEVO AND ' +
    'destino.`ID_AV_AAB` = origen.`ID_AV_AAB` ' +
    'WHERE origen.`CODIGO_ART_AAB` = :ANTERIOR',
    ['ANTERIOR', 'NUEVO'],
    [AAnterior, ANuevo]);
  Ejecutar(
    'DELETE origen FROM `fza_articulos_conjuntos_asign` origen ' +
    'JOIN `fza_articulos_conjuntos_asign` destino ON ' +
    'destino.`CODIGO_ART_ACA` = :NUEVO AND ' +
    'destino.`ID_VA_ACA` = origen.`ID_VA_ACA` ' +
    'WHERE origen.`CODIGO_ART_ACA` = :ANTERIOR',
    ['ANTERIOR', 'NUEVO'],
    [AAnterior, ANuevo]);
end;

function TRepositorioCambioArticuloColorUniDAC.SqlActualizacionAtributos(
  const ATabla, ACampoUnidad, ASufijo: string): string;
var
  i: Integer;
  sCampo: string;
  sCampoNombre: string;
  sCondicion: string;
  sCondiciones: string;
  sSeparadorCondiciones: string;
  sSeparadorValores: string;
  sValores: string;
begin
  sCondiciones := '';
  sValores := '';
  sSeparadorCondiciones := '';
  sSeparadorValores := '';
  for i := 1 to 5 do
  begin
    sCampo := 'ATTR' + IntToStr(i) + '_VALOR_' + ASufijo;
    sCampoNombre := 'ATTR' + IntToStr(i) + '_NOMBRE_' + ASufijo;
    if CampoExiste(ATabla, sCampo) and
       CampoExiste(ATabla, sCampoNombre) then
    begin
      sCondicion := CondicionInstantaneaColorSegura(
        'dato',
        sCampo,
        sCampoNombre,
        'ANTERIOR',
        i);
      sValores := sValores + sSeparadorValores + 'dato.`' + sCampo +
        '` = CASE WHEN ' + sCondicion + ' THEN :NUEVO ELSE dato.`' +
        sCampo + '` END';
      sCondiciones := sCondiciones + sSeparadorCondiciones + sCondicion;
      sSeparadorValores := ', ';
      sSeparadorCondiciones := ' OR ';
    end;
  end;
  if (sValores <> '') and CampoExiste(ATabla, 'INSTANTE_MODIF') then
  begin
    sValores := sValores + sSeparadorValores +
      'dato.`INSTANTE_MODIF` = CURRENT_TIMESTAMP';
    sSeparadorValores := ', ';
  end;
  if (sValores <> '') and CampoExiste(ATabla, 'USUARIO_MODIF') then
    sValores := sValores + sSeparadorValores +
      'dato.`USUARIO_MODIF` = :USUARIO';
  Result := '';
  if sValores <> '' then
  begin
    Result := 'UPDATE `' + ATabla + '` dato ' +
      'JOIN `' + TABLA_TEMPORAL + '` mapa ON ' +
      'mapa.`ORIGEN` = dato.`' + ACampoUnidad + '` SET ' + sValores +
      ' WHERE ' + sCondiciones;
  end;
end;

function TRepositorioCambioArticuloColorUniDAC.SqlActualizacionDescripcion(
  const ATabla, ACampoUnidad, ASufijo: string): string;
var
  i: Integer;
  sCampo: string;
  sCampoNombre: string;
  sCampoDescripcion: string;
  sCasos: string;
  sCondicion: string;
  sCondiciones: string;
  sDescripcionEnvuelta: string;
  sRepeticiones: string;
  sReemplazada: string;
  sToken: string;
begin
  if SameText(ASufijo, 'DTL') then
    sCampoDescripcion := 'DESCRIPCION_UNIDAD_DTL'
  else
    sCampoDescripcion := 'DESCRIPCION_VARIACION_' + ASufijo;
  sCasos := '';
  sCondiciones := '';
  if CampoExiste(ATabla, sCampoDescripcion) then
  begin
    for i := 1 to 5 do
    begin
      sCampo := 'ATTR' + IntToStr(i) + '_VALOR_' + ASufijo;
      sCampoNombre := 'ATTR' + IntToStr(i) + '_NOMBRE_' + ASufijo;
      if CampoExiste(ATabla, sCampo) and
         CampoExiste(ATabla, sCampoNombre) then
      begin
        sCondicion := CondicionInstantaneaColorSegura(
          'dato',
          sCampo,
          sCampoNombre,
          'ANTERIOR',
          i);
        sDescripcionEnvuelta := 'CONCAT('' / '', dato.`' +
          sCampoDescripcion + '`, '' / '')';
        sToken := 'CONCAT('' / '', TRIM(dato.`' + sCampo +
          '`), '' / '')';
        sRepeticiones := '((CHAR_LENGTH(' + sDescripcionEnvuelta +
          ') - CHAR_LENGTH(REPLACE(' + sDescripcionEnvuelta + ', ' +
          sToken + ', ''''))) / NULLIF(CHAR_LENGTH(' + sToken + '), 0))';
        sReemplazada := 'REPLACE(' + sDescripcionEnvuelta + ', ' +
          sToken + ', CONCAT('' / '', :NUEVO, '' / ''))';
        sCasos := sCasos + ' WHEN ' + sCondicion + ' AND ' +
          sRepeticiones + ' = 1 THEN SUBSTRING(' + sReemplazada +
          ', 4, CHAR_LENGTH(' + sReemplazada + ') - 6)';
        if sCondiciones <> '' then
          sCondiciones := sCondiciones + ' OR ';
        sCondiciones := sCondiciones + '(' + sCondicion + ' AND ' +
          sRepeticiones + ' = 1)';
      end;
    end;
  end;
  Result := '';
  if sCasos <> '' then
  begin
    Result := 'UPDATE `' + ATabla + '` dato ' +
      'JOIN `' + TABLA_TEMPORAL + '` mapa ON ' +
      'mapa.`ORIGEN` = dato.`' + ACampoUnidad + '` SET dato.`' +
      sCampoDescripcion + '` = CASE' + sCasos + ' ELSE dato.`' +
      sCampoDescripcion + '` END WHERE dato.`' + sCampoDescripcion +
      '` IS NOT NULL AND TRIM(dato.`' + sCampoDescripcion +
      '`) <> '''' AND (' + sCondiciones + ')';
  end;
end;

procedure TRepositorioCambioArticuloColorUniDAC.
  ActualizarInstantaneasColor(
    const AAnterior, ANuevo, AUsuario: string);
var
  i: Integer;
  sCampoUnidad: string;
  sSql: string;
  sSufijo: string;
  sTabla: string;
begin
  for i := Low(REFERENCIAS_ATRIBUTOS) to High(REFERENCIAS_ATRIBUTOS) do
  begin
    SepararReferenciaAtributos(
      REFERENCIAS_ATRIBUTOS[i],
      sTabla,
      sCampoUnidad,
      sSufijo);
    if CampoExiste(sTabla, sCampoUnidad) and
       CampoExiste(sTabla, 'ATTR1_VALOR_' + sSufijo) then
    begin
      sSql := SqlActualizacionDescripcion(
        sTabla,
        sCampoUnidad,
        sSufijo);
      if sSql <> '' then
      begin
        Ejecutar(
          sSql,
          ['ANTERIOR', 'NUEVO'],
          [AAnterior, ANuevo]);
      end;
      sSql := SqlActualizacionAtributos(
        sTabla,
        sCampoUnidad,
        sSufijo);
      if sSql <> '' then
      begin
        Ejecutar(
          sSql,
          ['ANTERIOR', 'NUEVO', 'USUARIO'],
          [AAnterior, ANuevo, AUsuario]);
      end;
    end;
  end;
end;

function TValidadorCambioArticuloColorUniDAC.
  HayInstantaneasColorAntiguo(const AColorAntiguo: string): Boolean;
var
  i: Integer;
  j: Integer;
  sCampo: string;
  sCampoNombre: string;
  sCampoUnidad: string;
  sCondiciones: string;
  sSufijo: string;
  sTabla: string;
begin
  Result := False;
  i := Low(REFERENCIAS_ATRIBUTOS);
  while (i <= High(REFERENCIAS_ATRIBUTOS)) and not Result do
  begin
    SepararReferenciaAtributos(
      REFERENCIAS_ATRIBUTOS[i],
      sTabla,
      sCampoUnidad,
      sSufijo);
    if CampoExiste(sTabla, sCampoUnidad) then
    begin
      sCondiciones := '';
      for j := 1 to 5 do
      begin
        sCampo := 'ATTR' + IntToStr(j) + '_VALOR_' + sSufijo;
        sCampoNombre := 'ATTR' + IntToStr(j) + '_NOMBRE_' + sSufijo;
        if CampoExiste(sTabla, sCampo) and
           CampoExiste(sTabla, sCampoNombre) then
        begin
          if sCondiciones <> '' then
            sCondiciones := sCondiciones + ' OR ';
          sCondiciones := sCondiciones + CondicionInstantaneaColorSegura(
            'dato',
            sCampo,
            sCampoNombre,
            'COLOR',
            j);
        end;
      end;
      if sCondiciones <> '' then
      begin
        Result := Existe(
          'SELECT 1 FROM `' + sTabla + '` dato JOIN `' +
          TABLA_TEMPORAL + '` mapa ON mapa.`ORIGEN` = dato.`' +
          sCampoUnidad + '` WHERE ' + sCondiciones + ' LIMIT 1',
          ['COLOR'],
          [AColorAntiguo]);
      end;
    end;
    Inc(i);
  end;
end;

function TValidadorCambioArticuloColorUniDAC.
  HayInstantaneasColorSinMapa(
    const AColorAntiguo: string): Boolean;
var
  i: Integer;
  j: Integer;
  sCampoNombre: string;
  sCampoUnidad: string;
  sCampoValor: string;
  sPosicionales: string;
  sReconocidas: string;
  sSufijo: string;
  sTabla: string;
  sValores: string;
begin
  Result := False;
  i := Low(REFERENCIAS_ATRIBUTOS);
  while (i <= High(REFERENCIAS_ATRIBUTOS)) and not Result do
  begin
    SepararReferenciaAtributos(
      REFERENCIAS_ATRIBUTOS[i],
      sTabla,
      sCampoUnidad,
      sSufijo);
    if CampoExiste(sTabla, sCampoUnidad) then
    begin
      sPosicionales := '';
      sReconocidas := '';
      sValores := '';
      for j := 1 to 5 do
      begin
        sCampoValor := 'ATTR' + IntToStr(j) + '_VALOR_' + sSufijo;
        sCampoNombre := 'ATTR' + IntToStr(j) + '_NOMBRE_' + sSufijo;
        if CampoExiste(sTabla, sCampoValor) and
           CampoExiste(sTabla, sCampoNombre) then
        begin
          if sReconocidas <> '' then
            sReconocidas := sReconocidas + ' OR ';
          sReconocidas := sReconocidas + CondicionInstantaneaColor(
            'dato',
            sCampoValor,
            sCampoNombre,
            'COLOR');
          if sValores <> '' then
            sValores := sValores + ' OR ';
          sValores := sValores + 'TRIM(dato.`' + sCampoValor +
            '`) = TRIM(:COLOR)';
          if sPosicionales <> '' then
            sPosicionales := sPosicionales + ' OR ';
          sPosicionales := sPosicionales +
            '(posicion_actual.`POSICION_COLOR` = ' + IntToStr(j) +
            ' AND TRIM(COALESCE(dato.`' + sCampoNombre +
            '`, '''')) = '''' AND TRIM(dato.`' + sCampoValor +
            '`) = TRIM(:COLOR))';
        end;
      end;
      if sReconocidas <> '' then
      begin
        Result := Existe(
          'SELECT 1 FROM `' + sTabla + '` dato LEFT JOIN `' +
          TABLA_TEMPORAL + '` mapa ON mapa.`ORIGEN` = dato.`' +
          sCampoUnidad + '` LEFT JOIN (' + SqlSkusConPosicionColor +
          ') posicion_actual ON posicion_actual.`CODIGO_UNIDAD` = ' +
          'dato.`' + sCampoUnidad + '` AND ' +
          'posicion_actual.`ORDEN_AMBIGUO` = 0 AND ' +
          '(CHAR_LENGTH(posicion_actual.`CODIGO_UNIDAD`) - ' +
          'CHAR_LENGTH(REPLACE(posicion_actual.`CODIGO_UNIDAD`, ' +
          '''/'', ''''))) = posicion_actual.`NUM_ATRIBUTOS` ' +
          'WHERE mapa.`ORIGEN` IS NULL AND ((' + sReconocidas +
          ') OR (' + sPosicionales + ') OR ' +
          '(posicion_actual.`CODIGO_UNIDAD` IS NULL AND (' + sValores +
          '))) LIMIT 1',
          ['COLOR'],
          [AColorAntiguo]);
      end;
    end;
    Inc(i);
  end;
end;

function TValidadorCambioArticuloColorUniDAC.
  HayInstantaneasColorAmbiguas(
    const AColorAntiguo: string): Boolean;
var
  i: Integer;
  j: Integer;
  sCampoNombre: string;
  sCampoUnidad: string;
  sCampoValor: string;
  sCondicionesSeguras: string;
  sConteoValores: string;
  sSufijo: string;
  sTabla: string;
begin
  Result := False;
  i := Low(REFERENCIAS_ATRIBUTOS);
  while (i <= High(REFERENCIAS_ATRIBUTOS)) and not Result do
  begin
    SepararReferenciaAtributos(
      REFERENCIAS_ATRIBUTOS[i],
      sTabla,
      sCampoUnidad,
      sSufijo);
    if CampoExiste(sTabla, sCampoUnidad) then
    begin
      sConteoValores := ExpresionConteoValoresAtributos(
        sTabla,
        'dato',
        sSufijo,
        'COLOR');
      sCondicionesSeguras := '';
      for j := 1 to 5 do
      begin
        sCampoValor := 'ATTR' + IntToStr(j) + '_VALOR_' + sSufijo;
        sCampoNombre := 'ATTR' + IntToStr(j) + '_NOMBRE_' + sSufijo;
        if CampoExiste(sTabla, sCampoValor) and
           CampoExiste(sTabla, sCampoNombre) then
        begin
          if sCondicionesSeguras <> '' then
            sCondicionesSeguras := sCondicionesSeguras + ' OR ';
          sCondicionesSeguras := sCondicionesSeguras +
            CondicionInstantaneaColorSegura(
              'dato',
              sCampoValor,
              sCampoNombre,
              'COLOR',
              j);
        end;
      end;
      if sCondicionesSeguras <> '' then
      begin
        Result := Existe(
          'SELECT 1 FROM `' + sTabla + '` dato JOIN `' +
          TABLA_TEMPORAL + '` mapa ON mapa.`ORIGEN` = dato.`' +
          sCampoUnidad + '` WHERE ' + sConteoValores + ' > 0 AND NOT (' +
          sCondicionesSeguras + ') LIMIT 1',
          ['COLOR'],
          [AColorAntiguo]);
      end;
    end;
    Inc(i);
  end;
end;

function TValidadorCambioArticuloColorUniDAC.
  HayDescripcionesColorAmbiguas(
    const AColorAntiguo, AColorNuevo: string): Boolean;
var
  i: Integer;
  j: Integer;
  sCampoDescripcion: string;
  sCampoNombre: string;
  sCampoUnidad: string;
  sCampoValor: string;
  sCondicion: string;
  sCondiciones: string;
  sCondicionesSeguras: string;
  sConteoValores: string;
  sDescripcionEnvuelta: string;
  sRepeticiones: string;
  sRepeticionesSinMayusculas: string;
  sSufijo: string;
  sTabla: string;
  sTextoAntiguoEnDescripcion: string;
  sToken: string;
begin
  Result := False;
  i := Low(REFERENCIAS_ATRIBUTOS);
  while (i <= High(REFERENCIAS_ATRIBUTOS)) and not Result do
  begin
    SepararReferenciaAtributos(
      REFERENCIAS_ATRIBUTOS[i],
      sTabla,
      sCampoUnidad,
      sSufijo);
    if SameText(sSufijo, 'DTL') then
      sCampoDescripcion := 'DESCRIPCION_UNIDAD_DTL'
    else
      sCampoDescripcion := 'DESCRIPCION_VARIACION_' + sSufijo;
    if CampoExiste(sTabla, sCampoUnidad) and
       CampoExiste(sTabla, sCampoDescripcion) then
    begin
      sCondiciones := '';
      sCondicionesSeguras := '';
      sConteoValores := ExpresionConteoValoresAtributos(
        sTabla,
        'dato',
        sSufijo,
        'COLOR');
      sTextoAntiguoEnDescripcion :=
        'LOCATE(LOWER(TRIM(:COLOR)), LOWER(dato.`' +
        sCampoDescripcion + '`)) > 0';
      for j := 1 to 5 do
      begin
        sCampoValor := 'ATTR' + IntToStr(j) + '_VALOR_' + sSufijo;
        sCampoNombre := 'ATTR' + IntToStr(j) + '_NOMBRE_' + sSufijo;
        if CampoExiste(sTabla, sCampoValor) and
           CampoExiste(sTabla, sCampoNombre) then
        begin
          sCondicion := CondicionInstantaneaColorSegura(
            'dato',
            sCampoValor,
            sCampoNombre,
            'COLOR',
            j);
          if sCondicionesSeguras <> '' then
            sCondicionesSeguras := sCondicionesSeguras + ' OR ';
          sCondicionesSeguras := sCondicionesSeguras + sCondicion;
          sDescripcionEnvuelta := 'CONCAT('' / '', dato.`' +
            sCampoDescripcion + '`, '' / '')';
          sToken := 'CONCAT('' / '', TRIM(dato.`' + sCampoValor +
            '`), '' / '')';
          sRepeticiones := '((CHAR_LENGTH(' + sDescripcionEnvuelta +
            ') - CHAR_LENGTH(REPLACE(' + sDescripcionEnvuelta + ', ' +
            sToken + ', ''''))) / NULLIF(CHAR_LENGTH(' + sToken +
            '), 0))';
          sRepeticionesSinMayusculas := '((CHAR_LENGTH(LOWER(' +
            sDescripcionEnvuelta + ')) - CHAR_LENGTH(REPLACE(LOWER(' +
            sDescripcionEnvuelta + '), LOWER(' + sToken +
            '), ''''))) / NULLIF(CHAR_LENGTH(' + sToken + '), 0))';
          if sCondiciones <> '' then
            sCondiciones := sCondiciones + ' OR ';
          sCondiciones := sCondiciones + '(' + sCondicion + ' AND (' +
            sRepeticionesSinMayusculas + ' > 1 OR (' +
            sRepeticionesSinMayusculas + ' = 1 AND ' + sRepeticiones +
            ' <> 1) OR (' + sRepeticionesSinMayusculas + ' = 0 AND ' +
            'LOCATE(LOWER(TRIM(dato.`' + sCampoValor + '`)), LOWER(' +
            'dato.`' + sCampoDescripcion + '`)) > 0) OR (' +
            sRepeticiones + ' = 1 AND CHAR_LENGTH(dato.`' +
            sCampoDescripcion + '`) - CHAR_LENGTH(TRIM(dato.`' +
            sCampoValor + '`)) + CHAR_LENGTH(:NUEVO) > COALESCE((' +
            'SELECT col.`CHARACTER_MAXIMUM_LENGTH` FROM ' +
            '`INFORMATION_SCHEMA`.`COLUMNS` col WHERE ' +
            'col.`TABLE_SCHEMA` = DATABASE() AND col.`TABLE_NAME` = ''' +
            sTabla + ''' AND col.`COLUMN_NAME` = ''' + sCampoDescripcion +
            ''' LIMIT 1), 65535))))';
        end;
      end;
      if sCondicionesSeguras = '' then
        sCondicionesSeguras := '0 = 1';
      if sCondiciones <> '' then
        sCondiciones := sCondiciones + ' OR ';
      sCondiciones := sCondiciones + '(' +
        sTextoAntiguoEnDescripcion + ' AND COALESCE((' +
        sCondicionesSeguras + '), 0) = 0)';
      sCondiciones := sCondiciones + ' OR (' + sConteoValores +
        ' > 1 AND ' + sTextoAntiguoEnDescripcion + ')';
      if sCondiciones <> '' then
      begin
        Result := Existe(
          'SELECT 1 FROM `' + sTabla + '` dato JOIN `' +
          TABLA_TEMPORAL + '` mapa ON mapa.`ORIGEN` = dato.`' +
          sCampoUnidad + '` WHERE dato.`' + sCampoDescripcion +
          '` IS NOT NULL AND TRIM(dato.`' + sCampoDescripcion +
          '`) <> '''' AND (' + sCondiciones + ') LIMIT 1',
          ['COLOR', 'NUEVO'],
          [AColorAntiguo, AColorNuevo]);
      end;
    end;
    Inc(i);
  end;
end;

function TValidadorCambioArticuloColorUniDAC.ValidarCambioArticulo(
  const AAnterior, ANuevo: string;
  AFusionar: Boolean): TResultadoCambioArticuloColor;
begin
  Result := TResultadoCambioArticuloColor.Correcto(0);
  BloquearArticulos(AAnterior, ANuevo);
  if ArticulosCoincidenEnBaseDatos(AAnterior, ANuevo) then
  begin
    Result := TResultadoCambioArticuloColor.Error(
      mcacDatosInvalidos,
      SErrorIdentidadArticuloOrigenDestinoCoincidente);
  end
  else if not ExisteArticulo(AAnterior) then
    Result := TResultadoCambioArticuloColor.Error(mcacOrigenNoExiste)
  else if AFusionar and (not ExisteArticulo(ANuevo)) then
  begin
    Result := TResultadoCambioArticuloColor.Error(
      mcacDatosInconsistentes,
      SErrorArticuloDestinoFusionNoExiste);
  end
  else if (not AFusionar) and ExisteArticulo(ANuevo) then
    Result := TResultadoCambioArticuloColor.Error(mcacDestinoYaExiste)
  else if (not AFusionar) and ArticuloRegistrado(ANuevo) then
  begin
    Result := TResultadoCambioArticuloColor.Error(
      mcacDatosInconsistentes,
      SErrorCodigoArticuloDestinoReservadoHistorico);
  end
  else
  begin
    ConstruirMapaArticulo(AAnterior, ANuevo);
    AgregarMapaArticuloReferencias(AAnterior, ANuevo);
    if not MapaArticuloEsCompleto(AAnterior) then
    begin
      Result := TResultadoCambioArticuloColor.Error(
        mcacDatosInconsistentes,
        SErrorSkuArticuloNoComienzaCodigoAntiguo);
    end
    else if HayUnidadesArticuloSinMapa(AAnterior) then
    begin
      Result := TResultadoCambioArticuloColor.Error(
        mcacDatosInconsistentes,
        SErrorUnidadesArticuloFueraMapaCambio);
    end
    else if MapaTieneCodigosLargos or MapaTieneDestinosDuplicados then
      Result := TResultadoCambioArticuloColor.Error(mcacColisionUnidades)
    else if HayVentasArticulo(AAnterior) then
      Result := TResultadoCambioArticuloColor.Error(mcacExistenVentas)
    else if HayPrestaShopArticulo(AAnterior) or
            HayPrestaShopArticulo(ANuevo) then
      Result := TResultadoCambioArticuloColor.Error(mcacIntegracionExterna)
    else if HayDestinoEnVentasArticulo(ANuevo) or
            HayDestinoMapaEnVentas then
      Result := TResultadoCambioArticuloColor.Error(mcacExistenVentas)
    else if AFusionar and
            (not FusionArticuloEsSegura(AAnterior, ANuevo)) then
    begin
      Result := TResultadoCambioArticuloColor.Error(
        mcacDatosInconsistentes,
        SErrorDatosMaestrosArticulosIncompatibles);
    end
    else if (not AFusionar) and
            (HayDestinoEnReferencias(REFERENCIAS_ARTICULO) or
             HayDestinoEnReferencias(REFERENCIAS_UNIDAD)) then
      Result := TResultadoCambioArticuloColor.Error(mcacColisionUnidades)
    else
      Result := TResultadoCambioArticuloColor.Correcto(NumeroSkuMapa);
  end;
end;

function TValidadorCambioArticuloColorUniDAC.ValidarCambioColor(
  const AAnterior, ANuevo: string;
  AFusionar: Boolean): TResultadoCambioArticuloColor;
begin
  Result := TResultadoCambioArticuloColor.Correcto(0);
  BloquearColores(AAnterior, ANuevo);
  if ColoresCoincidenEnBaseDatos(AAnterior, ANuevo) then
  begin
    Result := TResultadoCambioArticuloColor.Error(
      mcacDatosInvalidos,
      SErrorIdentidadColorOrigenDestinoCoincidente);
  end
  else if not ExisteColor(AAnterior) then
    Result := TResultadoCambioArticuloColor.Error(mcacOrigenNoExiste)
  else if NumeroColoresActivos(AAnterior) <> 1 then
  begin
    Result := TResultadoCambioArticuloColor.Error(
      mcacDatosInconsistentes,
      SErrorColorOrigenIdentidadesActivas);
  end
  else if AFusionar and (not ExisteColor(ANuevo)) then
  begin
    Result := TResultadoCambioArticuloColor.Error(
      mcacDatosInconsistentes,
      SErrorColorDestinoFusionNoExiste);
  end
  else if AFusionar and (NumeroColoresActivos(ANuevo) <> 1) then
  begin
    Result := TResultadoCambioArticuloColor.Error(
      mcacDatosInconsistentes,
      SErrorColorDestinoIdentidadesActivas);
  end
  else if (not AFusionar) and ExisteColor(ANuevo) then
    Result := TResultadoCambioArticuloColor.Error(mcacDestinoYaExiste)
  else if (not AFusionar) and ColorRegistrado(ANuevo) then
  begin
    Result := TResultadoCambioArticuloColor.Error(
      mcacDatosInconsistentes,
      SErrorColorDestinoReservadoHistorico);
  end
  else
  begin
    ConstruirMapaColor(AAnterior, ANuevo);
    AgregarMapaColorReferencias(AAnterior, ANuevo);
    if HayMapaColorReferenciasAmbiguo(AAnterior, ANuevo) then
    begin
      Result := TResultadoCambioArticuloColor.Error(
        mcacDatosInconsistentes,
        SErrorReferenciaParcialMultiplesDestinosColor);
    end
    else if not MapaColorEsCompleto(AAnterior) then
    begin
      Result := TResultadoCambioArticuloColor.Error(
        mcacDatosInconsistentes,
        SErrorSkuSegmentoColorFueraCatalogo);
    end
    else if HayUnidadesColorSinMapa(AAnterior) or
            HayInstantaneasColorSinMapa(AAnterior) then
    begin
      Result := TResultadoCambioArticuloColor.Error(
        mcacDatosInconsistentes,
        SErrorUnidadesDocumentosColorFueraMapaCambio);
    end
    else if HayInstantaneasColorAmbiguas(AAnterior) or
            HayDescripcionesColorAmbiguas(AAnterior, ANuevo) then
    begin
      Result := TResultadoCambioArticuloColor.Error(
        mcacDatosInconsistentes,
        SErrorInstantaneasColorAmbiguas);
    end
    else if AFusionar and (not FusionColorEsSegura(AAnterior, ANuevo)) then
    begin
      Result := TResultadoCambioArticuloColor.Error(
        mcacDatosInconsistentes,
        SErrorDatosSkuColoresIncompatibles);
    end
    else if MapaTieneCodigosLargos or MapaTieneDestinosDuplicados then
      Result := TResultadoCambioArticuloColor.Error(mcacColisionUnidades)
    else if HayVentasColor(AAnterior) then
      Result := TResultadoCambioArticuloColor.Error(mcacExistenVentas)
    else if HayPrestaShopColor(AAnterior) or
            (AFusionar and HayPrestaShopColor(ANuevo)) then
      Result := TResultadoCambioArticuloColor.Error(mcacIntegracionExterna)
    else if HayDestinoEnVentasColor(ANuevo) or
            HayDestinoMapaEnVentas then
      Result := TResultadoCambioArticuloColor.Error(mcacExistenVentas)
    else if (not AFusionar) and
            HayDestinoEnReferencias(REFERENCIAS_UNIDAD) then
      Result := TResultadoCambioArticuloColor.Error(mcacColisionUnidades)
    else
      Result := TResultadoCambioArticuloColor.Correcto(NumeroSkuMapa);
  end;
end;

function TValidadorCambioArticuloColorUniDAC.VerificarCambioArticulo(
  const AArticuloAntiguo: string): Boolean;
begin
  Result := (not ExisteArticulo(AArticuloAntiguo)) and
            (not HayOrigenEnReferencias(REFERENCIAS_ARTICULO)) and
            (not HayOrigenEnReferencias(REFERENCIAS_UNIDAD)) and
            (not HayUnidadesArticuloSinMapa(AArticuloAntiguo));
end;

function TValidadorCambioArticuloColorUniDAC.VerificarCambioColor(
  const AColorAntiguo: string): Boolean;
begin
  Result := (not ExisteColor(AColorAntiguo)) and
            (not HayOrigenEnReferencias(REFERENCIAS_UNIDAD)) and
            (not HayUnidadesColorSinMapa(AColorAntiguo)) and
            (not HayInstantaneasColorSinMapa(AColorAntiguo)) and
            (not HayInstantaneasColorAntiguo(AColorAntiguo));
end;

function TRepositorioCambioArticuloColorUniDAC.CambiarArticulo(
  const AArticuloAntiguo, AArticuloNuevo, AUsuario: string):
  TResultadoCambioArticuloColor;
begin
  Result := EjecutarCambioArticulo(
    AArticuloAntiguo,
    AArticuloNuevo,
    AUsuario,
    False);
end;

function TRepositorioCambioArticuloColorUniDAC.FusionarArticulo(
  const AArticuloAntiguo, AArticuloDestino, AUsuario: string):
  TResultadoCambioArticuloColor;
begin
  Result := EjecutarCambioArticulo(
    AArticuloAntiguo,
    AArticuloDestino,
    AUsuario,
    True);
end;

function TRepositorioCambioArticuloColorUniDAC.EjecutarCambioArticulo(
  const AArticuloAntiguo, AArticuloNuevo, AUsuario: string;
  AFusionar: Boolean): TResultadoCambioArticuloColor;
var
  oHistorico: THistoricoCambioArticuloColor;
  sTipoOperacion: string;
begin
  oHistorico := nil;
  if FConexion.InTransaction then
  begin
    Result := TResultadoCambioArticuloColor.Error(
      mcacDatosInconsistentes,
      SErrorTransaccionCambioArticuloColorActiva);
  end
  else
  begin
    PrepararTablaTemporal;
    try
      IniciarTransaccion;
      try
        Result := FValidador.ValidarCambioArticulo(
          AArticuloAntiguo,
          AArticuloNuevo,
          AFusionar);
        if Result.EsCorrecto then
        begin
          oHistorico := THistoricoCambioArticuloColor.Create(FConexion);
          if AFusionar then
            sTipoOperacion := TIPO_FUSION_ARTICULO
          else
            sTipoOperacion := TIPO_CAMBIO_ARTICULO;
          oHistorico.IniciarOperacion(
            sTipoOperacion,
            OBJETO_ARTICULO,
            AArticuloAntiguo,
            AArticuloNuevo,
            AUsuario);
          CapturarHistorico(
            oHistorico,
            AArticuloAntiguo,
            AArticuloNuevo,
            True);
          if not AFusionar then
          begin
            CrearArticuloDestino(
              AArticuloAntiguo,
              AArticuloNuevo,
              AUsuario);
          end;
          if AFusionar then
            PrepararFusionArticulo(
              AArticuloAntiguo,
              AArticuloNuevo);
          CrearSkuDestino(AArticuloNuevo, AUsuario, True);
          PrepararAtributosSkuDestino('', AUsuario, False);
          ConsolidarTarifas(
            AArticuloAntiguo,
            AArticuloNuevo,
            AUsuario,
            True);
          ConsolidarReferenciasUnidad(AUsuario);
          EliminarAtributosSkuOrigen;
          DesactivarSkuOrigen(AUsuario);
          ConsolidarProveedoresArticulo(
            AArticuloAntiguo,
            AArticuloNuevo,
            AUsuario);
          ActualizarReferenciasArticulo(
            AArticuloAntiguo,
            AArticuloNuevo,
            AUsuario);
          DesactivarArticuloMaestro(AArticuloAntiguo, AUsuario);
          if not FValidador.VerificarCambioArticulo(AArticuloAntiguo) then
          begin
            Result := TResultadoCambioArticuloColor.Error(
              mcacDatosInconsistentes,
              SErrorReferenciasCodigoArticuloAntiguoPersisten);
          end;
          if Result.EsCorrecto then
          begin
            oHistorico.CompletarOperacion(
              Result.UnidadesAfectadas,
              SDetalleCambioArticuloColorCompletado);
            Result.IdOperacion := oHistorico.IdOperacion;
          end;
        end;
        FinalizarTransaccion(Result);
      except
        if FConexion.InTransaction then
          FConexion.Rollback;
        raise;
      end;
    finally
      oHistorico.Free;
      EliminarTablaTemporal;
    end;
  end;
end;

function TRepositorioCambioArticuloColorUniDAC.CambiarColor(
  const AColorAntiguo, AColorNuevo, AUsuario: string):
  TResultadoCambioArticuloColor;
begin
  Result := EjecutarCambioColor(
    AColorAntiguo,
    AColorNuevo,
    AUsuario,
    False);
end;

function TRepositorioCambioArticuloColorUniDAC.FusionarColor(
  const AColorAntiguo, AColorDestino, AUsuario: string):
  TResultadoCambioArticuloColor;
begin
  Result := EjecutarCambioColor(
    AColorAntiguo,
    AColorDestino,
    AUsuario,
    True);
end;

function TRepositorioCambioArticuloColorUniDAC.EjecutarCambioColor(
  const AColorAntiguo, AColorNuevo, AUsuario: string;
  AFusionar: Boolean): TResultadoCambioArticuloColor;
var
  oHistorico: THistoricoCambioArticuloColor;
  sTipoOperacion: string;
begin
  oHistorico := nil;
  if FConexion.InTransaction then
  begin
    Result := TResultadoCambioArticuloColor.Error(
      mcacDatosInconsistentes,
      SErrorTransaccionCambioArticuloColorActiva);
  end
  else
  begin
    PrepararTablaTemporal;
    try
      IniciarTransaccion;
      try
        Result := FValidador.ValidarCambioColor(
          AColorAntiguo,
          AColorNuevo,
          AFusionar);
        if Result.EsCorrecto then
        begin
          oHistorico := THistoricoCambioArticuloColor.Create(FConexion);
          if AFusionar then
            sTipoOperacion := TIPO_FUSION_COLOR
          else
            sTipoOperacion := TIPO_CAMBIO_COLOR;
          oHistorico.IniciarOperacion(
            sTipoOperacion,
            OBJETO_COLOR,
            AColorAntiguo,
            AColorNuevo,
            AUsuario);
          CapturarHistorico(
            oHistorico,
            AColorAntiguo,
            AColorNuevo,
            False);
          ActualizarInstantaneasColor(
            AColorAntiguo,
            AColorNuevo,
            AUsuario);
          CrearSkuDestino('', AUsuario, False);
          PrepararAtributosSkuDestino(
            AColorNuevo,
            AUsuario,
            AFusionar);
          ConsolidarTarifas('', '', AUsuario, False);
          ConsolidarReferenciasUnidad(AUsuario);
          EliminarAtributosSkuOrigen;
          DesactivarSkuOrigen(AUsuario);
          ActualizarColorMaestro(
            AColorAntiguo,
            AColorNuevo,
            AUsuario,
            AFusionar);
          if not FValidador.VerificarCambioColor(AColorAntiguo) then
          begin
            Result := TResultadoCambioArticuloColor.Error(
              mcacDatosInconsistentes,
              SErrorReferenciasColorAntiguoPersisten);
          end;
          if Result.EsCorrecto then
          begin
            oHistorico.CompletarOperacion(
              Result.UnidadesAfectadas,
              SDetalleCambioArticuloColorCompletado);
            Result.IdOperacion := oHistorico.IdOperacion;
          end;
        end;
        FinalizarTransaccion(Result);
      except
        if FConexion.InTransaction then
          FConexion.Rollback;
        raise;
      end;
    finally
      oHistorico.Free;
      EliminarTablaTemporal;
    end;
  end;
end;

function TRepositorioCambioArticuloColorUniDAC.RevertirOperacion(
  const AIdOperacion, AUsuario: string): TResultadoReversionHistorico;
var
  oHistorico: THistoricoCambioArticuloColor;
begin
  oHistorico := THistoricoCambioArticuloColor.Create(FConexion);
  try
    Result := oHistorico.Revertir(AIdOperacion, AUsuario);
  finally
    oHistorico.Free;
  end;
end;

function CrearRepositorioCambioArticuloColorUniDAC(
  AConexion: TUniConnection): IRepositorioCambioArticuloColor;
begin
  Result := TRepositorioCambioArticuloColorUniDAC.Create(AConexion);
end;

end.
