{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataConsultaOpe                                            }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de consulta de operaciones de caja (F10).                     }
{    Maestro y pestañas (operación, pagos, vales, movimientos, cliente,        }
{    depósitos, factura).                                                      }
{******************************************************************************}
unit UniDataConsultaOpe;

// =============================================================================
// Modulo de datos para la consulta de operaciones de caja (F10
// Buscar/Modificar).
//
//  Expone 8 queries (1 maestro + 7 para pestañas) que se refrescan al
//  cambiar la fila del maestro. TODO ES SOLO LECTURA.
//
//  El filtrado del maestro es por:
//    - Fecha + empresa/almacen/caja (contexto fijo heredado del menu)
//    - Texto libre (numero operacion, nº factura, cliente, concepto,
//                   descripcion/codigo/SKU de articulos en lineas de factura)
//
//  Pestañas:
//    - Operacion    : filas crudas de fza_caja_operaciones.
//    - Pagos        : lineas de fza_caja_pagos. SOLO pagos, sin vales.
//    - Vales        : vales emitidos y/o redimidos en esta operacion (NUEVO).
//    - Movimientos  : kardex (fza_movimientos_almacen).
//    - Cliente      : ficha cliente.
//    - Depositos    : depositos tocados, agrupados por ID_DEPOSITO_DEP
//                     para evitar duplicados (alta + cobro_inicial juntos).
//    - Factura      : cabecera + lineas (fza_facturas / fza_facturas_lineas).
// =============================================================================

interface

uses
  System.SysUtils, System.Classes, Data.DB, Uni, MemDS, DBAccess,
  inLibInteraccionDatosIntf, inLibLogIntf;

type
  TdmConsultaOpe = class(TDataModule)
    qryMaestro:      TUniQuery;
    qryOperacion:    TUniQuery;
    qryPagos:        TUniQuery;
    qryVales:        TUniQuery;
    qryMovimientos:  TUniQuery;
    qryCliente:      TUniQuery;
    qryDepositos:    TUniQuery;
    qryFactura:      TUniQuery;
    qryFacturaLin:   TUniQuery;
    dsMaestro:       TDataSource;
    dsOperacion:     TDataSource;
    dsPagos:         TDataSource;
    dsVales:         TDataSource;
    dsMovimientos:   TDataSource;
    dsCliente:       TDataSource;
    dsDepositos:     TDataSource;
    dsFactura:       TDataSource;
    dsFacturaLin:    TDataSource;
    procedure DataModuleCreate(Sender: TObject);
  private
    FConexion: TUniConnection;
    FRegistroLog: IRegistroLog;
    FCargando: Boolean;
    // Clave (Emp|Alm|Caja|NumOp) de la ultima operacion para la que se
    // refrescaron las pestanas hijas. Si una nueva llamada a
    // RefrescarPestanasHijas trae la misma clave, salimos sin tocar BBDD:
    // el grid suele disparar OnDataChange varias veces por la misma fila
    // (al abrir el form, al aplicar el layout, al cambiar visibilidad de
    // pestanas, etc.) y antes recargabamos 3-4 veces lo mismo.
    FUltimaClaveHijas: string;
    // Clave (Fecha|Emp|Alm|Caja|Txt) de la ultima carga del maestro. Si
    // CargarMaestro entra con la misma combinacion, salimos sin tocar
    // BBDD ni resetear FUltimaClaveHijas, evitando la cascada completa.
    // Caso tipico: al abrir el form, dtpFecha.Date := AFecha dispara
    // OnEditValueChanged y luego FormShow llama tambien a RecargarMaestro:
    // antes salian 2-3 cargas identicas.
    FUltimaClaveMaestro: string;
    // True si alguna operacion del maestro cargado va a un cliente
    // distinto del generico de caja.
    FHayClienteIdentificado: Boolean;
    FOnNotificarMensaje: TNotificarMensajeDatosEvent;
    procedure ConectarConsultas;
    procedure ConfigurarConsultaMaestro;
    function SqlFiltroTextoMaestro: string;
    function SqlFormasPagoMaestro: string;
    function SqlVendedoresMaestro: string;
    procedure EvaluarClienteIdentificado;
    procedure ConfigurarConsultasCaja;
    procedure ConfigurarConsultasMovimientoCliente;
    procedure ConfigurarConsultasDepositoFactura;
    procedure AbrirSeguro(q: TUniQuery; const sNombre: string);
    procedure NotificarError(const AMensaje: string);
  public
    constructor Create(
      AOwner: TComponent;
      AConexion: TUniConnection;
      const ARegistroLog: IRegistroLog); reintroduce;
    procedure CargarMaestro(AFecha:     TDate;
                            const AEmp,
                                  AAlm,
                                  ACaja,
                                  ATextoLibre: string;
                            AVerTodos: Boolean = False);
    procedure CerrarPestanasHijas;
    procedure CargarDetalleOperacion(const AEmp,
                                           AAlm,
                                           ACaja,
                                           ANumOp,
                                           ACliente,
                                           ASerie,
                                           ANroFac: string);
    procedure RefrescarPestanasHijas;
    procedure InvalidarCacheMaestro;
    function  TienePagos:       Boolean;
    function  TieneVales:       Boolean;
    function  TieneMovimientos: Boolean;
    function  TieneCliente:     Boolean;
    function  HayClienteIdentificado: Boolean;
    function  TieneDepositos:   Boolean;
    function  TieneFactura:     Boolean;
    function  EsOperacionCaja: Boolean;
    // True si la operacion seleccionada es un traspaso (TR misma empresa /
    // TA entre empresas). Usado para reimprimir su ticket especifico.
    function  EsTraspaso: Boolean;
    property OnNotificarMensaje: TNotificarMensajeDatosEvent
      read FOnNotificarMensaje write FOnNotificarMensaje;
  end;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses inLibMsgComun, UniDataRectificativasSql, inLibReimpresionOperacionCaja;

const
  // Cliente de mostrador con el que se emiten las ventas anonimas.
  SClienteGenericoCaja = '0';

{$R *.dfm}

// -----------------------------------------------------------------------------
constructor TdmConsultaOpe.Create(
  AOwner: TComponent;
  AConexion: TUniConnection;
  const ARegistroLog: IRegistroLog);
begin
  if not Assigned(ARegistroLog) then
    raise EArgumentNilException.Create('ARegistroLog');
  FConexion := AConexion;
  FRegistroLog := ARegistroLog;
  inherited Create(AOwner);
end;

procedure TdmConsultaOpe.ConectarConsultas;
begin
  qryMaestro.Connection     := FConexion;
  qryOperacion.Connection   := FConexion;
  qryPagos.Connection       := FConexion;
  qryVales.Connection       := FConexion;
  qryMovimientos.Connection := FConexion;
  qryCliente.Connection     := FConexion;
  qryDepositos.Connection   := FConexion;
  qryFactura.Connection     := FConexion;
  qryFacturaLin.Connection  := FConexion;
end;

// Filtro de texto libre del maestro: numero de operacion, numero de
// factura, razon social del cliente, concepto de caja y lineas de la
// factura asociada.
function TdmConsultaOpe.SqlFiltroTextoMaestro: string;
begin
  Result :=
    '   AND ( :PTXT = '''' '                                              +
    '         OR o.NUMERO_OPERACION_OPCAJA LIKE CONCAT(''%'', :PTXT, ''%'') ' +
    '         OR COALESCE(fd.NUMERO_FAC, fo.NUMERO_FAC) '             +
    '            LIKE CONCAT(''%'', :PTXT, ''%'') '                   +
    '         OR cli.RAZON_SOCIAL_CLI LIKE CONCAT(''%'', :PTXT, ''%'') ' +
    '         OR o.CONCEPTO_GASTO_INGRESO_OPCAJA LIKE CONCAT(''%'', :PTXT, ' +
    '''%'') ' +
    '         OR EXISTS ( '                                                +
    '               SELECT 1 FROM fza_facturas_lineas l '                  +
    '                WHERE l.CODIGO_EMP_FACLIN   = o.CODIGO_EMP_OPCAJA ' +
    '                  AND l.CODIGO_ALM_FACLIN   = o.CODIGO_ALM_OPCAJA ' +
    '                  AND l.CODIGO_CAJA_FACLIN      = o.CODIGO_CAJA_OPCAJA ' +
    '                  AND l.NUMERO_OPERACION_FACLIN = ' +
    'o.NUMERO_OPERACION_OPCAJA ' +
    '                  AND ( l.DESCRIPCION_ARTICULO_FACLIN LIKE ' +
    'CONCAT(''%'', :PTXT, ''%'') ' +
    '                     OR l.CODIGO_ART_FACLIN      LIKE CONCAT(''%'', ' +
    ':PTXT, ''%'') ' +
    '                     OR l.CODIGO_UNIDAD_FACLIN        LIKE ' +
    'CONCAT(''%'', :PTXT, ''%'') ' +
    '                      ) '                                             +
    '                   ) '                                                +
    '       ) ';
end;

// Codigos de las formas de pago usadas en la operacion, sin repetir y
// separados por comas (por ejemplo 'EFE, TARJ'). La subconsulta se
// correlaciona con las cuatro columnas de agrupacion del maestro, asi
// que devuelve un unico valor por fila del grid.
function TdmConsultaOpe.SqlFormasPagoMaestro: string;
begin
  Result :=
    '       (SELECT GROUP_CONCAT(DISTINCT p.CODIGO_FP_CFP '           +
    '                            ORDER BY p.CODIGO_FP_CFP '           +
    '                            SEPARATOR '', '') '                  +
    '          FROM fza_caja_pagos p '                                +
    '         WHERE p.CODIGO_EMP_PAGO  = o.CODIGO_EMP_OPCAJA '        +
    '           AND p.CODIGO_ALM_PAGO  = o.CODIGO_ALM_OPCAJA '        +
    '           AND p.CODIGO_CAJA_PAGO = o.CODIGO_CAJA_OPCAJA '       +
    '           AND p.NUMERO_OPERACION_PAGO = '                       +
    '               o.NUMERO_OPERACION_OPCAJA) AS FORMAS_PAGO, ';
end;

// Vendedor o vendedores de la operacion, sin repetir. Se toman de las
// lineas de la factura, donde cada linea lleva el suyo, y solo si
// ninguna lo trae se recurre al empleado de la propia operacion. Nunca
// es el usuario del programa. Se muestra el diminutivo de ticket, que
// es el nombre con el que la caja identifica al vendedor ('ALEX'), no
// la razon social del empleado.
function TdmConsultaOpe.SqlVendedoresMaestro: string;
const
  SNombreVendedor = 'COALESCE(ev.DIMINUTIVO_TICKET_EMPL, ' +
                    'ev.NOMBRE_EMPL, ' +
                    'l.CODIGO_VENDEDOR_FACLIN)';
begin
  Result :=
    '       COALESCE( '                                              +
    '         (SELECT GROUP_CONCAT(DISTINCT ' + SNombreVendedor      +
    '                     ORDER BY ' + SNombreVendedor               +
    '                     SEPARATOR '', '') '                        +
    '            FROM fza_facturas_lineas l '                        +
    '            LEFT JOIN fza_empleados ev '                        +
    '              ON ev.CODIGO_EMPL = l.CODIGO_VENDEDOR_FACLIN '    +
    '           WHERE l.CODIGO_EMP_FACLIN  = o.CODIGO_EMP_OPCAJA '   +
    '             AND l.CODIGO_ALM_FACLIN  = o.CODIGO_ALM_OPCAJA '   +
    '             AND l.CODIGO_CAJA_FACLIN = o.CODIGO_CAJA_OPCAJA '  +
    '             AND l.NUMERO_OPERACION_FACLIN = '                  +
    '                 o.NUMERO_OPERACION_OPCAJA '                    +
    '             AND TRIM(COALESCE(l.CODIGO_VENDEDOR_FACLIN, '''')) '+
    '                 <> ''''), '                                    +
    '         MAX(COALESCE(eo.DIMINUTIVO_TICKET_EMPL, '              +
    '                      eo.NOMBRE_EMPL, '                         +
    '                      o.CODIGO_EMPLEADO_OPCAJA))) AS EMPLEADO ';
end;

procedure TdmConsultaOpe.ConfigurarConsultaMaestro;
begin
  // Una fila por numero, agrupando todos sus tipos de operacion.
  qryMaestro.SQL.Text :=
    'SELECT o.CODIGO_EMP_OPCAJA, '                                    +
    '       o.CODIGO_ALM_OPCAJA, '                                    +
    '       o.CODIGO_CAJA_OPCAJA, '                                       +
    '       o.NUMERO_OPERACION_OPCAJA, '                                  +
    '       MIN(o.FECHA_OPERACION_OPCAJA)            AS FECHA_OP, '       +
    '       GROUP_CONCAT(DISTINCT o.TIPO_OPERACION_OPCAJA '               +
    '                    ORDER BY o.TIPO_OPERACION_OPCAJA '               +
    '                    SEPARATOR '','')            AS TIPOS_OP, '       +
    '       GROUP_CONCAT(DISTINCT NULLIF(o.CONCEPTO_GASTO_INGRESO_OPCAJA,'''') '
      +
    '                    SEPARATOR '' | '')          AS CONCEPTOS, '      +
    '       COALESCE('                                                +
    '         MAX(COALESCE(fd.TOTAL_LIQUIDO_FAC, '                   +
    '                      fo.TOTAL_LIQUIDO_FAC)), '                  +
    '         SUM(o.IMPORTE_TOTAL_OPCAJA)) AS IMPORTE_TOTAL, '        +
    '       COALESCE('                                                +
    '         MAX(COALESCE(fd.SERIE_FAC, fo.SERIE_FAC)), '           +
    '         MAX(o.SERIE_FAC_OPCAJA)) AS SERIE_FAC, '                +
    '       COALESCE('                                                +
    '         MAX(COALESCE(fd.NUMERO_FAC, fo.NUMERO_FAC)), '         +
    '         MAX(o.NUMERO_FAC_OPCAJA)) AS NUMERO_FAC, '              +
    '       MAX(COALESCE(fd.FASE_FAC, fo.FASE_FAC)) AS FASE_FAC, '     +
    '       MAX(COALESCE(fd.CODIGO_CLI_FAC, '                         +
    '                    fo.CODIGO_CLI_FAC, '                         +
    '                    o.CODIGO_CLI_OPCAJA)) AS CLIENTE, '          +
    '       MAX(cli.RAZON_SOCIAL_CLI)             AS RAZON_SOCIAL_CLI,'+
    SqlFormasPagoMaestro                                              +
    SqlVendedoresMaestro                                              +
    '  FROM fza_caja_operaciones o '                                      +
    // Las rutas son excluyentes para que MariaDB use sus indices.
    '  LEFT JOIN fza_facturas fd '                                    +
    '    ON TRIM(COALESCE(o.SERIE_FAC_OPCAJA, '''')) <> '''' '       +
    '   AND TRIM(COALESCE(o.NUMERO_FAC_OPCAJA, '''')) <> '''' '      +
    '   AND fd.CODIGO_EMP_FAC = o.CODIGO_EMP_OPCAJA '                +
    '   AND fd.SERIE_FAC = o.SERIE_FAC_OPCAJA '                      +
    '   AND fd.NUMERO_FAC = o.NUMERO_FAC_OPCAJA '                    +
    '  LEFT JOIN fza_facturas fo '                                   +
    '    ON (TRIM(COALESCE(o.SERIE_FAC_OPCAJA, '''')) = '''' '       +
    '        OR TRIM(COALESCE(o.NUMERO_FAC_OPCAJA, '''')) = '''') '  +
    '   AND fo.CODIGO_EMP_FAC = o.CODIGO_EMP_OPCAJA '                +
    '   AND fo.CODIGO_ALM_FAC = o.CODIGO_ALM_OPCAJA '                +
    '   AND fo.CODIGO_CAJA_FAC = o.CODIGO_CAJA_OPCAJA '              +
    '   AND fo.NUMERO_OPERACION_FAC = '                              +
    '       o.NUMERO_OPERACION_OPCAJA '                              +
    '  LEFT JOIN fza_clientes cli '                                       +
    '    ON cli.CODIGO_CLI_CLI = '                                   +
    '       COALESCE(fd.CODIGO_CLI_FAC, '                            +
    '                fo.CODIGO_CLI_FAC, '                            +
    '                o.CODIGO_CLI_OPCAJA) '                          +
    '  LEFT JOIN fza_empleados eo '                                   +
    '    ON eo.CODIGO_EMPL = o.CODIGO_EMPLEADO_OPCAJA '             +
    ' WHERE o.FECHA_OP_DIA_OPCAJA = :PFECHA '                             +
    '   AND o.CODIGO_EMP_OPCAJA = :PEMP '                             +
    '   AND o.CODIGO_ALM_OPCAJA = :PALM '                             +
    '   AND o.CODIGO_CAJA_OPCAJA    = :PCAJA '                            +
    // "Ver todos" muestra también canceladas, anuladas y rectificadas por
    // sustitución.
    '   AND (:PVERTODOS = 1 OR ('                                        +
    '        COALESCE(fd.FASE_FAC, fo.FASE_FAC, '''') '                  +
    '          NOT IN (''CANCELADA'', ''ANULADA'') '                     +
    SQLExcluirVentaRetirada(
      'o.CODIGO_EMP_OPCAJA',
      'o.SERIE_FAC_OPCAJA',
      'o.NUMERO_FAC_OPCAJA') +
    ')) ' +
    SqlFiltroTextoMaestro +
    ' GROUP BY o.CODIGO_EMP_OPCAJA, '                                 +
    '          o.CODIGO_ALM_OPCAJA, '                                 +
    '          o.CODIGO_CAJA_OPCAJA, '                                    +
    '          o.NUMERO_OPERACION_OPCAJA '                                +
    // Ultima operacion abajo: si varias comparten FECHA_OP (empate),
    // desempatamos por numero de operacion en numerico, no como texto.
    ' ORDER BY FECHA_OP, '                                                 +
    '          CAST(o.NUMERO_OPERACION_OPCAJA AS UNSIGNED) ';
end;

procedure TdmConsultaOpe.ConfigurarConsultasCaja;
begin
  // Filas crudas: una numeracion puede tener VENTA, DEV y CB.
  qryOperacion.SQL.Text :=
    'SELECT FECHA_OPERACION_OPCAJA, '                                     +
    '       TIPO_OPERACION_OPCAJA, '                                      +
    '       IMPORTE_TOTAL_OPCAJA, '                                       +
    '       CONCEPTO_GASTO_INGRESO_OPCAJA, '                              +
    '       ID_DEPOSITO_OPCAJA, '                                         +
    '       SERIE_REF_ORIGEN_OPCAJA, '                                    +
    '       NUMERO_REF_ORIGEN_OPCAJA, '                                   +
    '       MOTIVO_DEVOLUCION_OPCAJA, '                                   +
    '       ESTADO_DEVOLUCION_OPCAJA '                                    +
    '  FROM fza_caja_operaciones '                                        +
    ' WHERE CODIGO_EMP_OPCAJA   = :PEMP '                             +
    '   AND CODIGO_ALM_OPCAJA   = :PALM '                             +
    '   AND CODIGO_CAJA_OPCAJA      = :PCAJA '                            +
    '   AND NUMERO_OPERACION_OPCAJA = :PNUMOP '                           +
    ' ORDER BY FECHA_OPERACION_OPCAJA, TIPO_OPERACION_OPCAJA ';

  // Los vales emitidos o redimidos no se mezclan con los pagos.
  qryPagos.SQL.Text :=
    'SELECT p.CODIGO_EMP_PAGO, '                                      +
    '       p.CODIGO_ALM_PAGO, '                                      +
    '       p.CODIGO_CAJA_PAGO, '                                     +
    '       p.SERIE_OPERACION_PAGO, '                                 +
    '       p.NUMERO_OPERACION_PAGO, '                                +
    '       p.NUMERO_LINEA_PAGO, '                                    +
    '       p.CODIGO_FP_CFP, '                                        +
    '       fp.DESCRIPCION_FORMA_PAGO_CFP, '                          +
    '       p.IMPORTE_ENTREGADO_PAGO, '                               +
    '       p.IMPORTE_CAMBIO_PAGO, '                                  +
    '       (p.IMPORTE_ENTREGADO_PAGO - p.IMPORTE_CAMBIO_PAGO) '      +
    '                                AS IMPORTE_NETO_PAGO, '          +
    '       p.CODIGO_DIVISA_PAGO, '                                   +
    '       p.RED_BLOCKCHAIN_PAGO, '                                  +
    '       p.FACTOR_CAMBIO_PAGO, '                                   +
    '       p.IMPORTE_DIVISA_PAGO, '                                  +
    '       p.REFERENCIA_FACPAG, '                                    +
    '       p.OBSERVACIONES_PAGO '                                    +
    '  FROM fza_caja_pagos p '                                        +
    '  LEFT JOIN fza_caja_formas_pago fp '                            +
    '    ON fp.CODIGO_FP_CFP = p.CODIGO_FP_CFP '                      +
    ' WHERE p.CODIGO_EMP_PAGO        = :PEMP '                        +
    '   AND p.CODIGO_ALM_PAGO        = :PALM '                        +
    '   AND p.CODIGO_CAJA_PAGO       = :PCAJA '                       +
    '   AND p.NUMERO_OPERACION_PAGO  = :PNUMOP '                      +
    ' ORDER BY p.NUMERO_LINEA_PAGO ';

  // Un vale emitido y redimido en la misma operacion aparece por cada rol.
  qryVales.SQL.Text :=
    '(SELECT ''EMI''                AS ROL_VL, '                      +
    '        v.CODIGO_VL, '                                           +
    '        v.CODIGO_PADRE_VL, '                                     +
    '        v.PIN_SEGURIDAD_VL, '                                    +
    '        v.ESTADO_VL, '                                           +
    '        v.IMPORTE_NOMINAL_VL, '                                  +
    '        v.IMPORTE_REDIMIDO_VL, '                                 +
    '        v.FECHA_EMISION_VL, '                                    +
    '        v.FECHA_CADUCIDAD_VL, '                                  +
    '        v.FECHA_REDENCION_VL, '                                  +
    '        v.OBSERVACIONES_VL '                                     +
    '   FROM fza_caja_vales v '                                       +
    '  WHERE v.CODIGO_EMP_EMI_VL        = :PEMP '                     +
    '    AND v.CODIGO_ALM_EMI_VL        = :PALM '                     +
    '    AND v.CODIGO_CAJA_EMI_VL       = :PCAJA '                    +
    '    AND v.NUMERO_OPERACION_EMI_VL  = :PNUMOP) '                  +
    'UNION ALL '                                                      +
    '(SELECT ''RED''                AS ROL_VL, '                      +
    '        v.CODIGO_VL, '                                           +
    '        v.CODIGO_PADRE_VL, '                                     +
    '        v.PIN_SEGURIDAD_VL, '                                    +
    '        v.ESTADO_VL, '                                           +
    '        v.IMPORTE_NOMINAL_VL, '                                  +
    '        v.IMPORTE_REDIMIDO_VL, '                                 +
    '        v.FECHA_EMISION_VL, '                                    +
    '        v.FECHA_CADUCIDAD_VL, '                                  +
    '        v.FECHA_REDENCION_VL, '                                  +
    '        v.OBSERVACIONES_VL '                                     +
    '   FROM fza_caja_vales v '                                       +
    '  WHERE v.CODIGO_EMP_RED_VL        = :PEMP '                     +
    '    AND v.CODIGO_ALM_RED_VL        = :PALM '                     +
    '    AND v.CODIGO_CAJA_RED_VL       = :PCAJA '                    +
    '    AND v.NUMERO_OPERACION_RED_VL  = :PNUMOP) '                  +
    'ORDER BY ROL_VL, CODIGO_VL ';
end;

procedure TdmConsultaOpe.ConfigurarConsultasMovimientoCliente;
begin
  qryMovimientos.SQL.Text :=
    'SELECT m.NUMERO_MOV, '                                               +
    '       m.TIPO_DOC_MOV, '                                             +
    '       m.LINEA_MOV, '                                                +
    '       m.CODIGO_ALM_MOV, '                                       +
    '       m.CODIGO_ALM_CONTRA_MOV, '                                +
    '       m.CODIGO_ART_MOV, '                                      +
    '       m.CODIGO_UNIDAD_MOV, '                                        +
    '       atr.COLOR_AV, '                                                +
    '       atr.TALLA_AV, '                                                +
    '       a.DESCRIPCION_ART, '                                     +
    '       m.TIPO_MOV, '                                      +
    '       m.CANTIDAD_MOV, '                                             +
    '       m.PRECIO_MEDIO_MOV, '                                         +
    '       m.TOTAL_COSTE_MOV '                                           +
    '  FROM fza_movimientos_almacen m '                                   +
    '  LEFT JOIN fza_articulos a '                                        +
    '    ON a.CODIGO_ART_ART = m.CODIGO_ART_MOV '                   +
    '  LEFT JOIN ( '                                                       +
    '       SELECT sa.CODIGO_UNIDAD_SKU_SA, '                              +
    '              MAX(CASE WHEN av.ID_VA_AV = (SELECT ' +
    'EJ452.ID_ATB_VA FROM VI_VARIACIONES_EJES EJ452 WHERE ' +
    'EJ452.ID_VAR_VA = (SELECT SK452.CODIGO_VAR_SKU FROM ' +
    'fza_articulos_skus SK452 WHERE SK452.CODIGO_UNIDAD_SKU = ' +
    'sa.CODIGO_UNIDAD_SKU_SA) AND EJ452.EJE_VA = ''F'') '                    +
    '                       THEN av.AV END) AS COLOR_AV, '                  +
    '              MAX(CASE WHEN av.ID_VA_AV = (SELECT ' +
    'EJ452.ID_ATB_VA FROM VI_VARIACIONES_EJES EJ452 WHERE ' +
    'EJ452.ID_VAR_VA = (SELECT SK452.CODIGO_VAR_SKU FROM ' +
    'fza_articulos_skus SK452 WHERE SK452.CODIGO_UNIDAD_SKU = ' +
    'sa.CODIGO_UNIDAD_SKU_SA) AND EJ452.EJE_VA = ''P'') '                   +
    '                       THEN av.AV END) AS TALLA_AV '                   +
    '         FROM fza_atributos_sku sa '                                  +
    '         JOIN fza_atributos_valores av '                              +
    '           ON av.ID_AV = sa.ID_AV_SA '                                +
    '        GROUP BY sa.CODIGO_UNIDAD_SKU_SA '                            +
    '       ) atr '                                                        +
    '    ON atr.CODIGO_UNIDAD_SKU_SA = m.CODIGO_UNIDAD_MOV '              +
    ' WHERE m.CODIGO_EMP_MOV          = :PEMP '                       +
    '   AND m.CODIGO_ALM_DOC_MOV      = :PALM '                       +
    '   AND m.CODIGO_CAJA_DOC_MOV         = :PCAJA '                      +
    '   AND m.NUMERO_OPERACION_DOC_MOV    = :PNUMOP '                     +
    ' ORDER BY m.NUMERO_MOV, m.LINEA_MOV ';

  qryCliente.SQL.Text :=
    'SELECT c.CODIGO_CLI_CLI, '                                           +
    '       c.RAZON_SOCIAL_CLI, '                                      +
    '       c.NIF_CLI, '                                              +
    '       c.MOVIL_CLI, '                                            +
    '       c.EMAIL_CLI, '                                            +
    '       c.DIRECCION1_CLI, '                                       +
    '       c.POBLACION_CLI, '                                        +
    '       c.PROVINCIA_CLI, '                                        +
    '       c.CODIGO_POSTAL_CLI, '                                          +
    '       c.TOTAL_DEUDA_CLI '                                       +
    '  FROM fza_clientes c '                                              +
    ' WHERE c.CODIGO_CLI_CLI = :PCLI ';
end;

procedure TdmConsultaOpe.ConfigurarConsultasDepositoFactura;
begin
  // La vista puede dar tres roles; se colapsan por deposito.
  qryDepositos.SQL.Text :=
    'SELECT d.ID_DEPOSITO_DEP, '                                      +
    '       MAX(d.CODIGO_CLI_DEP)            AS CODIGO_CLI_DEP, '     +
    '       MAX(d.CODIGO_ART_DEP)            AS CODIGO_ART_DEP, '     +
    '       MAX(d.CODIGO_UNIDAD_DEP)         AS CODIGO_UNIDAD_DEP, '  +
    '       MAX(d.CODIGO_ALM_DEP)            AS CODIGO_ALM_DEP, '     +
    '       MAX(d.CANTIDAD_PENDIENTE_DEP)    AS CANTIDAD_PENDIENTE_DEP, ' +
    '       MAX(d.PRECIO_VENTA_DEP)          AS PRECIO_VENTA_DEP, '   +
    '       MAX(d.PORCENTAJE_IVA_DEP)        AS PORCENTAJE_IVA_DEP, ' +
    '       MAX(d.IMPORTE_ANTICIPO_DEP)      AS IMPORTE_ANTICIPO_DEP, ' +
    '       MAX(d.IMPORTE_PENDIENTE_DEP)     AS IMPORTE_PENDIENTE_DEP, ' +
    '       MAX(d.ESTADO_DEP)                AS ESTADO_DEP, '         +
    '       MIN(d.FECHA_CREACION_DEP)        AS FECHA_CREACION_DEP, ' +
    '       MAX(d.FECHA_ENTREGA_DEP)         AS FECHA_ENTREGA_DEP, '  +
    '       MAX(d.EMPRESA_CANCEL_DEP)        AS EMPRESA_CANCEL_DEP, ' +
    '       MAX(d.ALMACEN_CANCEL_DEP)        AS ALMACEN_CANCEL_DEP, ' +
    '       MAX(d.CAJA_CANCEL_DEP)           AS CAJA_CANCEL_DEP, '    +
    '       MAX(d.NUMERO_OPERACION_CANCEL_DEP) AS NUMERO_OPERACION_CANCEL_DEP, '
      +
    '       GROUP_CONCAT(DISTINCT d.ROL_EN_OPERACION '                +
    '                    ORDER BY d.ROL_EN_OPERACION '                +
    '                    SEPARATOR '','')      AS ROL_EN_OPERACION '  +
    '  FROM vi_caja_depositos d '                               +
    ' WHERE d.CODIGO_EMPRESA_OP   = :PEMP '                           +
    '   AND d.CODIGO_ALMACEN_OP   = :PALM '                           +
    '   AND d.CODIGO_CAJA_OP      = :PCAJA '                          +
    '   AND d.NUMERO_OPERACION_OP = :PNUMOP '                         +
    ' GROUP BY d.ID_DEPOSITO_DEP '                                    +
    ' ORDER BY d.ID_DEPOSITO_DEP ';

  qryFactura.SQL.Text :=
    'SELECT f.SERIE_FAC, '                                            +
    '       f.NUMERO_FAC, '                                              +
    '       f.FECHA_FAC, '                                            +
    '       f.TIPO_FAC, '                                             +
    '       f.CODIGO_CLI_FAC, '                                   +
    '       f.RAZON_SOCIAL_CLIENTE_FAC, '                              +
    '       f.TOTAL_BASES_FAC, '                                      +
    '       f.TOTAL_IMPUESTOS_FAC, '                                  +
    '       f.TOTAL_LIQUIDO_FAC '                                     +
    '  FROM fza_facturas f '                                              +
    ' WHERE f.CODIGO_EMP_FAC = :PEMP '                                +
    '   AND ( '                                                        +
    '        (TRIM(COALESCE(:PSERIE, '''')) <> '''' '                 +
    '         AND TRIM(COALESCE(:PNROFAC, '''')) <> '''' '            +
    '         AND f.SERIE_FAC = :PSERIE '                             +
    '         AND f.NUMERO_FAC = :PNROFAC) '                          +
    '        OR '                                                      +
    '        ((TRIM(COALESCE(:PSERIE, '''')) = '''' '                 +
    '          OR TRIM(COALESCE(:PNROFAC, '''')) = '''') '            +
    '         AND f.CODIGO_ALM_FAC = :PALM '                          +
    '         AND f.CODIGO_CAJA_FAC = :PCAJA '                        +
    '         AND f.NUMERO_OPERACION_FAC = :PNUMOP) '                 +
    '       ) ';

  qryFacturaLin.SQL.Text :=
    'SELECT l.LINEA_FACLIN, '                                      +
    '       l.CODIGO_ART_FACLIN, '                            +
    '       l.CODIGO_UNIDAD_FACLIN, '                              +
    '       l.DESCRIPCION_ARTICULO_FACLIN, '                       +
    '       l.CANTIDAD_FACLIN, '                                   +
    '       l.PRECIO_VENTA_SIVA_ARTICULO_FACLIN, '                  +
    '       l.PRECIO_VENTA_CIVA_ARTICULO_FACLIN, '                  +
    '       l.PORCENTAJE_DTO_FACLIN, '                                 +
    '       l.TIPO_IVA_ARTICULO_FACLIN, '                           +
    '       l.PORCENTAJE_IVA_FACLIN, '                                 +
    '       l.TOTAL_FAC_SIVA_FACLIN, '                                  +
    '       l.TOTAL_FACLIN '                                       +
    '  FROM fza_facturas_lineas l '                                       +
    ' WHERE l.SERIE_FAC_FACLIN            = :PSERIE '                  +
    '   AND l.NUMERO_FAC_FACLIN              = :PNROFAC '                 +
    ' ORDER BY l.LINEA_FACLIN ';
end;

procedure TdmConsultaOpe.DataModuleCreate(Sender: TObject);
begin
  ConectarConsultas;
  ConfigurarConsultaMaestro;
  ConfigurarConsultasCaja;
  ConfigurarConsultasMovimientoCliente;
  ConfigurarConsultasDepositoFactura;
end;

procedure TdmConsultaOpe.CerrarPestanasHijas;
begin
  qryOperacion.Close;
  qryPagos.Close;
  qryVales.Close;
  qryMovimientos.Close;
  qryCliente.Close;
  qryDepositos.Close;
  qryFactura.Close;
  qryFacturaLin.Close;
  FUltimaClaveHijas := '';
end;

procedure TdmConsultaOpe.CargarDetalleOperacion(const AEmp,
                                                     AAlm,
                                                     ACaja,
                                                     ANumOp,
                                                     ACliente,
                                                     ASerie,
                                                     ANroFac: string);
var
  sClave: string;
begin
  // Escudo anti-recarga redundante: si la fila activa del maestro no ha
  // cambiado, no relanzamos las 8 queries hijas.
  sClave := AEmp + '|' + AAlm + '|' + ACaja + '|' + ANumOp;
  if sClave = FUltimaClaveHijas then
  begin
    FRegistroLog.RegistrarInformacion(
      Format('CargarDetalleOperacion: SKIP (misma op "%s")',
                       [sClave]));
  end
  else
  begin
  FRegistroLog.RegistrarInformacion(
    Format('CargarDetalleOperacion: cargando op "%s" (prev="%s")',
                     [sClave, FUltimaClaveHijas]));
  // --- Operacion ---
  qryOperacion.Close;
  qryOperacion.ParamByName('PEMP').AsString    := AEmp;
  qryOperacion.ParamByName('PALM').AsString    := AAlm;
  qryOperacion.ParamByName('PCAJA').AsString   := ACaja;
  qryOperacion.ParamByName('PNUMOP').AsString  := ANumOp;
  AbrirSeguro(qryOperacion, 'Operaciones');

  // --- Pagos ---
  qryPagos.Close;
  qryPagos.ParamByName('PEMP').AsString    := AEmp;
  qryPagos.ParamByName('PALM').AsString    := AAlm;
  qryPagos.ParamByName('PCAJA').AsString   := ACaja;
  qryPagos.ParamByName('PNUMOP').AsString  := ANumOp;
  AbrirSeguro(qryPagos, 'Pagos');

  // --- Vales ---
  qryVales.Close;
  qryVales.ParamByName('PEMP').AsString    := AEmp;
  qryVales.ParamByName('PALM').AsString    := AAlm;
  qryVales.ParamByName('PCAJA').AsString   := ACaja;
  qryVales.ParamByName('PNUMOP').AsString  := ANumOp;
  AbrirSeguro(qryVales, 'Vales');

  // --- Movimientos ---
  qryMovimientos.Close;
  qryMovimientos.ParamByName('PEMP').AsString    := AEmp;
  qryMovimientos.ParamByName('PALM').AsString    := AAlm;
  qryMovimientos.ParamByName('PCAJA').AsString   := ACaja;
  qryMovimientos.ParamByName('PNUMOP').AsString  := ANumOp;
  AbrirSeguro(qryMovimientos, 'Movimientos');

  // --- Cliente ---
  qryCliente.Close;
  if Trim(ACliente) <> '' then
  begin
    qryCliente.ParamByName('PCLI').AsString := ACliente;
    AbrirSeguro(qryCliente, 'Clientes');
  end;

  // --- Depositos ---
  qryDepositos.Close;
  qryDepositos.ParamByName('PEMP').AsString    := AEmp;
  qryDepositos.ParamByName('PALM').AsString    := AAlm;
  qryDepositos.ParamByName('PCAJA').AsString   := ACaja;
  qryDepositos.ParamByName('PNUMOP').AsString  := ANumOp;
  AbrirSeguro(qryDepositos, 'Depositos');

  // --- Factura (cabecera + lineas) ---
  qryFactura.Close;
  qryFacturaLin.Close;
  qryFactura.ParamByName('PEMP').AsString    := AEmp;
  qryFactura.ParamByName('PALM').AsString    := AAlm;
  qryFactura.ParamByName('PCAJA').AsString   := ACaja;
  qryFactura.ParamByName('PNUMOP').AsString  := ANumOp;
  qryFactura.ParamByName('PSERIE').AsString  := ASerie;
  qryFactura.ParamByName('PNROFAC').AsString := ANroFac;
  AbrirSeguro(qryFactura, 'Facturas');
  if (not qryFactura.IsEmpty) and (Trim(ASerie) <> '')
     and (Trim(ANroFac) <> '') then
  begin
    qryFacturaLin.ParamByName('PSERIE').AsString  := ASerie;
    qryFacturaLin.ParamByName('PNROFAC').AsString := ANroFac;
    AbrirSeguro(qryFacturaLin, 'Lineas de Facturas');
  end;
  FUltimaClaveHijas := sClave;
  end;
end;

procedure TdmConsultaOpe.RefrescarPestanasHijas;
var
  sEmp, sAlm, sCaja, sNumOp, sCli, sSerie, sNroFac: string;
begin
  if FCargando then
  begin
    FRegistroLog.RegistrarInformacion(
      'RefrescarPestanasHijas: BLOQUEADA por FCargando=True');
  end;
  if (not FCargando) and qryMaestro.IsEmpty then
  begin
    if FUltimaClaveHijas <> '' then
    begin
      FRegistroLog.RegistrarInformacion(
        'RefrescarPestanasHijas: maestro vacio, cerrando hijas');
      CerrarPestanasHijas;
    end
    else
      FRegistroLog.RegistrarInformacion(
        'RefrescarPestanasHijas: maestro vacio (no-op, ya cerradas)');
  end;
  if (not FCargando) and (not qryMaestro.IsEmpty) then
  begin
    sEmp    := qryMaestro.FieldByName('CODIGO_EMP_OPCAJA').AsString;
    sAlm    := qryMaestro.FieldByName('CODIGO_ALM_OPCAJA').AsString;
    sCaja   := qryMaestro.FieldByName('CODIGO_CAJA_OPCAJA').AsString;
    sNumOp  := qryMaestro.FieldByName('NUMERO_OPERACION_OPCAJA').AsString;
    sCli    := qryMaestro.FieldByName('CLIENTE').AsString;
    sSerie  := qryMaestro.FieldByName('SERIE_FAC').AsString;
    sNroFac := qryMaestro.FieldByName('NUMERO_FAC').AsString;
    CargarDetalleOperacion(sEmp, sAlm, sCaja, sNumOp,
                           sCli, sSerie, sNroFac);
  end;
end;

// -----------------------------------------------------------------------------
// En caja casi todo se cobra al cliente generico ('0'), asi que las dos
// columnas de cliente solo ocupan sitio. Se recorre el maestro recien
// abierto buscando uno real; el recorrido va con FCargando activo y
// deja el cursor donde estaba.
procedure TdmConsultaOpe.EvaluarClienteIdentificado;
var
  Marcador: TBookmark;
  sCliente: string;
begin
  FHayClienteIdentificado := False;
  if qryMaestro.Active and (not qryMaestro.IsEmpty) then
  begin
    qryMaestro.DisableControls;
    try
      Marcador := qryMaestro.GetBookmark;
      try
        qryMaestro.First;
        while (not qryMaestro.Eof) and
              (not FHayClienteIdentificado) do
        begin
          sCliente := Trim(qryMaestro.FieldByName('CLIENTE').AsString);
          if (sCliente <> '') and (sCliente <> SClienteGenericoCaja) then
            FHayClienteIdentificado := True
          else
            qryMaestro.Next;
        end;
        if qryMaestro.BookmarkValid(Marcador) then
          qryMaestro.GotoBookmark(Marcador);
      finally
        qryMaestro.FreeBookmark(Marcador);
      end;
    finally
      qryMaestro.EnableControls;
    end;
  end;
end;

function TdmConsultaOpe.HayClienteIdentificado: Boolean;
begin
  Result := FHayClienteIdentificado;
end;

procedure TdmConsultaOpe.CargarMaestro(AFecha:     TDate;
                                       const AEmp,
                                             AAlm,
                                             ACaja,
                                             ATextoLibre: string;
                                       AVerTodos: Boolean);
var
  sClaveMaestro: string;
begin
  // Escudo anti-recarga del maestro: si los parametros no han cambiado,
  // no relanzamos ni el SELECT del maestro ni las 8 queries hijas. Al
  // abrir el form, PrepararValores + FormShow encadenaban hasta 3
  // CargarMaestro identicos (uno por handler de dtpFecha y otro por
  // FormShow); ahora la 2a y 3a salen sin tocar BBDD.
  sClaveMaestro := DateToStr(AFecha) + '|' + AEmp + '|' + AAlm + '|' + ACaja +
                   '|' + ATextoLibre + '|' + BoolToStr(AVerTodos, True);
  if sClaveMaestro = FUltimaClaveMaestro then
  begin
    FRegistroLog.RegistrarInformacion(
      Format('CargarMaestro: SKIP (mismos params "%s")',
                       [sClaveMaestro]));
  end
  else
  begin
  FRegistroLog.RegistrarInformacion(
    Format('CargarMaestro: fecha=%s emp="%s" alm="%s" caja="%s" ' +
                     'txt="%s" (prev="%s")',
                     [DateToStr(AFecha), AEmp, AAlm, ACaja, ATextoLibre,
                      FUltimaClaveMaestro]));
  // Cerramos todas las queries hijas primero para que OnDataChange no
  // dispare mientras recargamos el maestro.
  FCargando := True;
  try
    qryOperacion.Close;
    qryPagos.Close;
    qryVales.Close;
    qryMovimientos.Close;
    qryCliente.Close;
    qryDepositos.Close;
    qryFactura.Close;
    qryFacturaLin.Close;
    qryMaestro.Close;
    qryMaestro.ParamByName('PFECHA').AsDate    := AFecha;
    qryMaestro.ParamByName('PEMP').AsString    := AEmp;
    qryMaestro.ParamByName('PALM').AsString    := AAlm;
    qryMaestro.ParamByName('PCAJA').AsString   := ACaja;
    qryMaestro.ParamByName('PTXT').AsString    := ATextoLibre;
    qryMaestro.ParamByName('PVERTODOS').AsInteger := Ord(AVerTodos);
    qryMaestro.Open;
    EvaluarClienteIdentificado;
    // Reset del cache de clave de hijas: forzamos que la siguiente
    // RefrescarPestanasHijas SI recargue (puede ser la misma op pero con
    // datos del maestro recien releidos).
    FUltimaClaveHijas  := '';
    FUltimaClaveMaestro := sClaveMaestro;
  finally
    FCargando := False;
  end;
  // Una vez cargado el maestro, refrescamos las pestañas hijas con la
  // primera fila (si hay).
  RefrescarPestanasHijas;
  end;
end;

procedure TdmConsultaOpe.InvalidarCacheMaestro;
begin
  FUltimaClaveMaestro := '';
  FUltimaClaveHijas := '';
end;

// -----------------------------------------------------------------------------
procedure TdmConsultaOpe.NotificarError(const AMensaje: string);
begin
  if Assigned(FOnNotificarMensaje) then
  begin
    FOnNotificarMensaje(Self, AMensaje, smdError);
  end
  else
  begin
    FRegistroLog.RegistrarError(AMensaje);
  end;
end;

// -----------------------------------------------------------------------------
procedure TdmConsultaOpe.AbrirSeguro(q: TUniQuery; const sNombre: string);
begin
  try
    q.Open;
  except
    on E: Exception do
    begin
      q.Close;
      // Registramos pero no propagamos: un fallo en una pestaña no debe
      // tirar el maestro ni las demas pestañas.
      NotificarError(Format(SErrorAbrirConsultaOpe,
        [sNombre, E.Message]));
    end;
  end;
end;

// -----------------------------------------------------------------------------
function TdmConsultaOpe.TienePagos: Boolean;
begin
  Result := qryPagos.Active and (not qryPagos.IsEmpty);
end;

function TdmConsultaOpe.TieneVales: Boolean;
begin
  Result := qryVales.Active and (not qryVales.IsEmpty);
end;

function TdmConsultaOpe.TieneMovimientos: Boolean;
begin
  Result := qryMovimientos.Active and (not qryMovimientos.IsEmpty);
end;

function TdmConsultaOpe.TieneCliente: Boolean;
begin
  Result := qryCliente.Active and (not qryCliente.IsEmpty);
end;

function TdmConsultaOpe.TieneDepositos: Boolean;
begin
  Result := qryDepositos.Active and (not qryDepositos.IsEmpty);
end;

function TdmConsultaOpe.TieneFactura: Boolean;
begin
  Result := qryFactura.Active and (not qryFactura.IsEmpty);
end;

function TdmConsultaOpe.EsOperacionCaja: Boolean;
var
  sTipos: string;
begin
  Result := False;
  if not qryMaestro.IsEmpty then
  begin
    sTipos := qryMaestro.FieldByName('TIPOS_OP').AsString;
    Result := EsTiposOperacionCaja(sTipos);
  end;
end;

function TdmConsultaOpe.EsTraspaso: Boolean;
var
  sTipos: string;
begin
  Result := False;
  if not qryMaestro.IsEmpty then
  begin
    sTipos := qryMaestro.FieldByName('TIPOS_OP').AsString;
    Result := EsTiposTraspasoCaja(sTipos);
  end;
end;

end.
