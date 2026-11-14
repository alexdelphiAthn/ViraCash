{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataFacturasProformaRepositorio                            }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.1.0                                                         }
{   Fecha:       23/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Materializa proformas VE, facturas fiscales por traspasos TA y facturas  }
{    TV por lo que la tienda destino ha vendido de lo traspasado.              }
{******************************************************************************}
unit UniDataFacturasProformaRepositorio;

interface

uses
  Uni,
  inLibParametrosIntf,
  inLibFacturasProformaIntf,
  inLibOpcionesDocumentoIntf,
  inLibTraspasosVendidos;

type
  TRepositorioFacturasProformaUniDAC = class(
    TInterfacedObject,
    IRepositorioFacturasProforma)
  private
    FConexion: TUniConnection;
    FParametrosApp: IParametrosAplicacion;
    procedure ActualizarPeriodo(
      AIdPeriodo: Int64;
      const AEstado: string;
      const AResultado: TResultadoFacturacionCaja;
      const AUsuario: string);
    procedure AsignarSolicitud(
      AConsulta: TUniQuery;
      const ASolicitud: TSolicitudFacturacionCaja);
    function ContarCandidatasVenta(
      const ASolicitud: TSolicitudFacturacionCaja): Integer;
    function ContarValesRecogidos(
      const ASolicitud: TSolicitudFacturacionCaja;
      out ASaldo: Currency): Integer;
    function ContarLineasTraspaso(
      const ASolicitud: TSolicitudFacturacionCaja;
      const AEmpresaOrigen: string;
      const AAlmacenOrigen: string): Integer;
    function ContarLineasFacturaTraspaso(
      const ASerie: string;
      const ANumero: string): Integer;
    function ContarLineasTraspasoSinValorar(
      const ASolicitud: TSolicitudFacturacionCaja): Integer;
    function CrearBorradorFacturaTraspaso(
      const ASolicitud: TSolicitudFacturacionCaja;
      AIdPeriodo: Int64;
      const AEmpresaOrigen: string;
      const AAlmacenOrigen: string;
      const ASerie: string;
      out ANumero: string): Integer;
    procedure CerrarPeriodoParcial(
      AIdPeriodo: Int64;
      const AAlmacen: string;
      const AError: string;
      var AResultado: TResultadoFacturacionCaja;
      const AUsuario: string);
    function CrearPeriodo(
      const AModalidad: string;
      const ASolicitud: TSolicitudFacturacionCaja): Int64;
    procedure DescartarPeriodoSinDocumentos(
      AIdPeriodo: Int64;
      const AResultado: TResultadoFacturacionCaja;
      const AUsuario: string);
    procedure EliminarValoracionTraspasos;
    function GenerarFacturaTraspaso(
      const ASolicitud: TSolicitudFacturacionCaja;
      AIdPeriodo: Int64;
      const AEmpresaOrigen: string;
      const AAlmacenOrigen: string;
      out AFactura: TFacturaCreadaCaja): Integer;
    function GenerarTraspasosValorados(
      const ASolicitud: TSolicitudFacturacionCaja
    ): TResultadoFacturacionCaja;
    function ObtenerTraspasosVendibles(
      const ASolicitud: TSolicitudFacturacionCaja;
      AAjenos: Boolean
    ): TTraspasosVendiblesPendientes;
    function ObtenerVentasDestino(
      const ASolicitud: TSolicitudFacturacionCaja
    ): TVentasDestinoPendientes;
    function ObtenerFacturacionesPrevias(
      const ASolicitud: TSolicitudFacturacionCaja;
      AAjenas: Boolean
    ): TFacturacionesTraspasoPrevias;
    function RepartirVentasEntreTraspasos(
      const ASolicitud: TSolicitudFacturacionCaja;
      out ATraspasos: TTraspasosVendiblesPendientes;
      out APrevias: TFacturacionesTraspasoPrevias
    ): TAsignacionesTraspasoVendido;
    function ObtenerIdentidad: Int64;
    function ObtenerNumeroDocumento(
      const ASerie: string;
      const ATipoDocumento: string;
      const AEmpresa: string;
      const AUsuario: string): string;
    function BuscarSerieFactura(
      const AEmpresa: string;
      const AAlmacen: string;
      const AFecha: TDateTime): string;
    function ObtenerSerieFactura(
      const AEmpresa: string;
      const AAlmacen: string;
      const AFecha: TDateTime): string;
    function SerieFacturaSolicitud(
      const ASolicitud: TSolicitudFacturacionCaja;
      const AEmpresa: string;
      const AAlmacen: string): string;
    function NumeroFacturaManual(
      const ASerie: string;
      const AEmpresa: string;
      const ANumero: string): string;
    procedure PrepararValoracionTraspasos(
      const AValoracion: TValoracionTraspasos);
    procedure InsertarLineasFacturaTraspaso(
      AConsulta: TUniQuery;
      const ASolicitud: TSolicitudFacturacionCaja;
      const AEmpresaOrigen: string;
      const AAlmacenOrigen: string;
      const ASerie: string;
      const ANumero: string);
    function GenerarFacturaTraspasoVendido(
      const ASolicitud: TSolicitudFacturacionCaja;
      AIdPeriodo: Int64;
      const AEmpresaOrigen: string;
      const AAlmacenOrigen: string;
      const AFilas: TFilasTraspasoVendido;
      var AAjustes: Integer;
      out AFactura: TFacturaCreadaCaja): Integer;
    procedure InsertarFilasTraspasoVendido(
      AConsulta: TUniQuery;
      AIdPeriodo: Int64;
      const ASolicitud: TSolicitudFacturacionCaja;
      const ASerie: string;
      const ANumero: string;
      const AFilas: TFilasTraspasoVendido);
    function ContarLineasFacturaTraspasoVendido(
      const ASerie: string;
      const ANumero: string): Integer;
    procedure RecalcularTotalesFactura(
      const ASerie: string;
      const ANumero: string);
    // Sin cliente de traspasos en la empresa destino no hay a quién emitir
    // la factura interna: se avisa antes de valorar nada.
    procedure ComprobarClienteTraspasos(
      const ASolicitud: TSolicitudFacturacionCaja);
    function ReservarOperacionesTraspaso(
      AConsulta: TUniQuery;
      const ASolicitud: TSolicitudFacturacionCaja;
      AIdPeriodo: Int64;
      const AEmpresaOrigen: string;
      const AAlmacenOrigen: string;
      const ASerie: string;
      const ANumero: string): Integer;
  public
    constructor Create(
      AConexion: TUniConnection;
      const AParametrosApp: IParametrosAplicacion);
    destructor Destroy; override;
    function RevisarPeriodo(
      AModalidad: TModalidadFacturacionCaja;
      const ASolicitud: TSolicitudFacturacionCaja
    ): TRevisionPeriodoFacturacionCaja;
    function GenerarVenta(
      const ASolicitud: TSolicitudFacturacionCaja
    ): TResultadoFacturacionCaja;
    function ObtenerLineasTraspasoPendientes(
      const ASolicitud: TSolicitudFacturacionCaja
    ): TLineasTraspasoPendientes;
    function GenerarTraspasos(
      const ASolicitud: TSolicitudFacturacionCaja;
      const AValoracion: TValoracionTraspasos
    ): TResultadoFacturacionCaja;
    function ObtenerLineasTraspasoVendidoPendientes(
      const ASolicitud: TSolicitudFacturacionCaja
    ): TLineasTraspasoPendientes;
    function GenerarTraspasosVendidos(
      const ASolicitud: TSolicitudFacturacionCaja;
      const AValoracion: TValoracionTraspasos
    ): TResultadoFacturacionCaja;
    function GenerarValesRecogidos(
      const ASolicitud: TSolicitudFacturacionCaja
    ): TResultadoFacturacionCaja;
    function PrepararConversionProformaVales(
      AIdProforma: Int64): TOpcionesDocumento;
    function ConvertirProformaVales(
      AIdProforma: Int64;
      const AOpciones: TOpcionesDocumento;
      const AUsuario: string): string;
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  Data.DB,
  inLibFacturas,
  inLibFacturasProformaValoracion,
  inLibVerifactu,
  UniDataFacturasLecturas,
  UniDataFacturasRecalculoTotales,
  UniDataImpuestosRepositorio;

type
  TDatosPropuestaVales = record
    EmpresaA: string;
    EmpresaB: string;
    Serie: string;
    Numero: string;
    Cantidad: Integer;
    Saldo: Currency;
  end;

  TLineaValeFactura = record
    Codigo: string;
    Importe: Currency;
  end;

resourcestring
  SErrorEmpresaSinClienteTraspasos =
    'La empresa %s no tiene cliente de traspasos (o ya no existe). ' +
    'Elíjalo o créelo en su ficha de Empresas, pestaña Más datos, con ' +
    '"Crear cliente de traspaso entre empresas".';
  SErrorTotalesFacturaTraspaso =
    'No se pudieron calcular los totales de la factura %s/%s: %s';
  SErrorGeneracionProformaDuplicada =
    'Ya existe una generación con el mismo periodo y modalidad.';
  SErrorPeriodoGeneracionProformaSolapado =
    'El periodo se solapa con una generación anterior.';
  SErrorSerieFacturaCajaNoDisponible =
    'No existe una serie FC NORMAL activa para la empresa %s.';
  SErrorNumeroFacturaCajaExistente =
    'Ya existe la factura %s/%s.';
  SErrorCabeceraProformaCajaNoCreada =
    'No se pudo crear la cabecera de la proforma de caja.';
  SDescripcionProformaCajaGenerada =
    'Proforma %s/%s generada con %d operaciones y %d ajustes.';
  SErrorFacturaTaDemasiadasLineas =
    'La factura TA de %s/%s tendría %d líneas; el máximo es 9999.';
  SErrorOperacionesTaSinLineas =
    'Las operaciones TA reservadas no tienen líneas activas.';
  SErrorCantidadLineasTaNoCoincide =
    'Se esperaban %d líneas TA y se han generado %d.';
  SErrorFacturaTaNoCreada =
    'No se pudo crear la factura TA de la empresa %s.';
  SDescripcionBorradoresFacturasTaGenerados =
    '%d borradores de facturas TA con %d operaciones.';
  SErrorLineasTaSinValorar =
    'Hay %d líneas de traspasos pendientes sin valorar (traspasos nuevos o ' +
    'modificados desde la simulación). Vuelve a pulsar Generar para ' +
    'valorarlas con las cifras actuales.';
  SErrorLineasTvSinValorar =
    'Hay %d traspasos con unidades vendidas sin valorar (ventas o traspasos ' +
    'nuevos desde la simulación). Vuelve a pulsar Generar para valorarlos ' +
    'con las cifras actuales.';
  SComentarioFacturaTraspaso =
    'Factura interna TA. Periodo %s a %s';
  SComentarioFacturaTraspasoVendido =
    'Factura interna TV: traspasado y vendido en destino. Periodo %s a %s';
  SPrefijoDevolucionFacturaTraspasoVendido =
    'DEVOLUCIÓN: ';
  SDescripcionFacturasTraspasoVendidoGeneradas =
    '%d borradores de facturas TV con %d operaciones de traspaso y %d ' +
    'ajustes por devolución.';
  // FZ-ISSUE-368
  SAvisoGeneracionParcialFacturacionCaja =
    'Generación incompleta: se crearon %d facturas, pero el proceso se ' +
    'detuvo%s:' + sLineBreak + '%s' + sLineBreak + sLineBreak +
    'El periodo queda como PARCIAL. Corrige la causa y vuelve a generar ' +
    'el mismo periodo: sólo se facturará lo que falta.';
  SAlmacenGeneracionParcialFacturacionCaja = ' en el almacén %s';
  SAvisoTvNegativaNoFacturada =
    'Almacén %s: no se crea la factura TV porque en el periodo sólo hay ' +
    'devoluciones de lo ya facturado (neto %s). Amplía el periodo para ' +
    'compensarlas con ventas posteriores o emite una rectificativa de la ' +
    'factura original.';
  SDescripcionProformaValesGenerada =
    'Propuesta de vales %s/%s: %d canjes, %d en sentido inverso. ' +
    'Saldo neto: %s.';
  SErrorProformaValesNoDisponible =
    'La propuesta de vales no existe o ya se convirtió en factura.';
  SErrorProformaValesSinSaldo =
    'El saldo neto es cero. No hay importe que pasar a factura.';
  SErrorFacturaValesDemasiadasLineas =
    'La propuesta contiene más de 9999 vales y no cabe en una factura.';
  SErrorFacturaValesSinCliente =
    'La empresa destinataria no tiene un cliente de traspasos válido.';
  SErrorFacturaValesNoCreada =
    'No se pudo crear el borrador de factura de vales.';
  SErrorFacturaValesLineas =
    'No se han podido trasladar todos los vales a la factura.';
  SErrorTotalesFacturaVales =
    'El total de las líneas no coincide con el saldo neto de los vales. ' +
    'No se ha convertido la propuesta.';
  SComentarioFacturaVales =
    'Compensación de vales entre empresas. Propuesta %s/%s.';

const
  // Una operación de traspaso la factura TA entera o TV a trozos, nunca las
  // dos: el libro mayor TV la deja fuera del circuito TA.
  SQL_EXCLUIR_OPERACION_FACTURADA_TV =
    ' AND NOT EXISTS (SELECT 1 FROM fza_facturas_traspasos_vendidos TV ' +
    ' WHERE TV.ID_OPCAJA_TA_FACTV = O.ID_OPCAJA) ';
  SQL_REVISAR_PERIODO =
    'SELECT COALESCE(SUM(CASE WHEN FECHA_DESDE_FACPER = :DESDE ' +
    'AND FECHA_HASTA_FACPER = :HASTA THEN 1 ELSE 0 END), 0) ' +
    'AS DUPLICADOS, COUNT(*) AS SOLAPADOS ' +
    'FROM fza_facturacion_caja_periodos FP ' +
    'WHERE FP.MODALIDAD_FACPER = :MODALIDAD ' +
    'AND (:MODALIDAD NOT IN (''TA'', ''TV'', ''VR'') ' +
    ' OR FP.CODIGO_EMP_DESTINO_FACPER = :EMPRESA_DESTINO) ' +
    'AND (FP.CODIGO_EMP_ORIGEN_FACPER = :EMPRESA_ORIGEN ' +
    ' OR (:MODALIDAD IN (''TA'', ''TV'', ''VR'') ' +
    ' AND FP.CODIGO_EMP_ORIGEN_FACPER IS NULL ' +
    ' AND (EXISTS (SELECT 1 FROM fza_facturas_operaciones_caja X ' +
    ' WHERE X.ID_FACPER_FACOP = FP.ID_FACPER ' +
    ' AND X.CODIGO_EMP_ORIGEN_FACOP = :EMPRESA_ORIGEN) ' +
    ' OR NOT EXISTS (SELECT 1 FROM fza_facturas_operaciones_caja X ' +
    ' WHERE X.ID_FACPER_FACOP = FP.ID_FACPER)))) ' +
    'AND FP.ESTADO_FACPER <> ''SIN_DOCUMENTOS'' ' +
    'AND FP.FECHA_DESDE_FACPER <= :HASTA ' +
    'AND FP.FECHA_HASTA_FACPER >= :DESDE';
  SQL_INSERTAR_PERIODO =
    'INSERT INTO fza_facturacion_caja_periodos (' +
    'MODALIDAD_FACPER, CODIGO_EMP_ORIGEN_FACPER, ' +
    'CODIGO_EMP_DESTINO_FACPER, ' +
    'FECHA_DESDE_FACPER, FECHA_HASTA_FACPER, ESTADO_FACPER, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:MODALIDAD, :EMPRESA_ORIGEN, :EMPRESA_DESTINO, ' +
    ':DESDE, :HASTA, ''ABIERTO'', ' +
    'NOW(), NOW(), :USUARIO, :USUARIO)';
  SQL_ACTUALIZAR_PERIODO =
    'UPDATE fza_facturacion_caja_periodos SET ESTADO_FACPER = :ESTADO, ' +
    'CANTIDAD_DOCUMENTOS_FACPER = :DOCUMENTOS, ' +
    'CANTIDAD_OPERACIONES_FACPER = :OPERACIONES, ' +
    'CANTIDAD_AJUSTES_FACPER = :AJUSTES, INSTANTE_MODIF = NOW(), ' +
    'USUARIO_MODIF = :USUARIO WHERE ID_FACPER = :ID_PERIODO';
  // Un intento que no genera nada no deja rastro en la lista de periodos
  // (FZ-ISSUE-026). Si algo lo referencia, se queda como SIN_DOCUMENTOS.
  SQL_BORRAR_PERIODO_SIN_DOCUMENTOS =
    'DELETE FROM fza_facturacion_caja_periodos ' +
    'WHERE ID_FACPER = :ID_PERIODO ' +
    'AND NOT EXISTS (SELECT 1 FROM fza_proformas_caja P ' +
    ' WHERE P.ID_FACPER_PROCAJ = :ID_PERIODO) ' +
    'AND NOT EXISTS (SELECT 1 FROM fza_facturas_operaciones_caja M ' +
    ' WHERE M.ID_FACPER_FACOP = :ID_PERIODO) ' +
    'AND NOT EXISTS (SELECT 1 FROM fza_facturas_traspasos_vendidos V ' +
    ' WHERE V.ID_FACPER_FACTV = :ID_PERIODO)';
  // SALDO: a favor de EMPRESA_ORIGEN (canjeó vales de la otra)
  SQL_CONTAR_VALES_RECOGIDOS =
    'SELECT COUNT(*) AS CANTIDAD, ' +
    'COALESCE(SUM(CASE WHEN V.CODIGO_EMP_RED_VL = :EMPRESA_ORIGEN ' +
    ' THEN V.IMPORTE_REDIMIDO_VL ' +
    ' ELSE -V.IMPORTE_REDIMIDO_VL END), 0) AS SALDO ' +
    'FROM fza_caja_vales V ' +
    'WHERE V.ESTADO_VL = ''REDIMIDO'' ' +
    'AND DATE(V.FECHA_REDENCION_VL) BETWEEN :DESDE AND :HASTA ' +
    'AND V.IMPORTE_REDIMIDO_VL > 0 ' +
    'AND ((V.CODIGO_EMP_RED_VL = :EMPRESA_ORIGEN ' +
    ' AND V.CODIGO_EMP_EMI_VL = :EMPRESA_DESTINO) ' +
    ' OR (V.CODIGO_EMP_RED_VL = :EMPRESA_DESTINO ' +
    ' AND V.CODIGO_EMP_EMI_VL = :EMPRESA_ORIGEN)) ' +
    'AND NOT EXISTS (SELECT 1 FROM fza_proformas_caja_vales P ' +
    ' WHERE P.CODIGO_VL_PROCVL = V.CODIGO_VL)';
  SQL_INSERTAR_PROFORMA_VALES =
    'INSERT INTO fza_proformas_caja (' +
    'ID_FACPER_PROCAJ, NUMERO_PROCAJ, SERIE_PROCAJ, FECHA_PROCAJ, ' +
    'FECHA_DESDE_PROCAJ, FECHA_HASTA_PROCAJ, TIPO_PROCAJ, ' +
    'ESTADO_PROCAJ, CODIGO_EMP_PROCAJ, ' +
    'RAZON_SOCIAL_EMPRESA_PROCAJ, NIF_EMPRESA_PROCAJ, ' +
    'DIRECCION1_EMPRESA_PROCAJ, DIRECCION2_EMPRESA_PROCAJ, ' +
    'CODIGO_POSTAL_EMPRESA_PROCAJ, POBLACION_EMPRESA_PROCAJ, ' +
    'PROVINCIA_EMPRESA_PROCAJ, CODIGO_PAI_EMPRESA_PROCAJ, ' +
    'NOMBRE_PAI_EMPRESA_PROCAJ, CODIGO_CLI_PROCAJ, ' +
    'RAZON_SOCIAL_CLIENTE_PROCAJ, INSTANTE_ALTA, INSTANTE_MODIF, ' +
    'USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :ID_PERIODO, :NUMERO, :SERIE, :HASTA, :DESDE, :HASTA, ' +
    '''VR'', ''EMITIDA'', A.CODIGO_EMP_EMP, A.RAZON_SOCIAL_EMP, ' +
    'A.NIF_EMP, A.DIRECCION1_EMP, A.DIRECCION2_EMP, ' +
    'A.CODIGO_POSTAL_EMP, A.POBLACION_EMP, A.PROVINCIA_EMP, ' +
    'A.CODIGO_PAI_EMP, A.NOMBRE_PAI_EMP, ' +
    'COALESCE(B.CODIGO_CLI_TRASPASOS_EMP, ''0''), ' +
    'B.RAZON_SOCIAL_EMP, NOW(), NOW(), :USUARIO, :USUARIO ' +
    'FROM fza_empresas A JOIN fza_empresas B ' +
    ' ON B.CODIGO_EMP_EMP = :EMPRESA_DESTINO ' +
    'WHERE A.CODIGO_EMP_EMP = :EMPRESA_ORIGEN';
  SQL_INSERTAR_VALES_PROPUESTA =
    'INSERT INTO fza_proformas_caja_vales (' +
    'CODIGO_VL_PROCVL, ID_PROCAJ_PROCVL, CODIGO_EMP_EMI_PROCVL, ' +
    'CODIGO_EMP_RED_PROCVL, FECHA_REDENCION_PROCVL, ' +
    'NUMERO_OPERACION_RED_PROCVL, IMPORTE_COMPENSACION_PROCVL, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT V.CODIGO_VL, :ID, V.CODIGO_EMP_EMI_VL, ' +
    'V.CODIGO_EMP_RED_VL, DATE(V.FECHA_REDENCION_VL), ' +
    'V.NUMERO_OPERACION_RED_VL, ' +
    'CASE WHEN V.CODIGO_EMP_RED_VL = :EMPRESA_ORIGEN ' +
    ' THEN V.IMPORTE_REDIMIDO_VL ' +
    ' ELSE -V.IMPORTE_REDIMIDO_VL END, ' +
    'NOW(), NOW(), :USUARIO, :USUARIO ' +
    'FROM fza_caja_vales V ' +
    'WHERE V.ESTADO_VL = ''REDIMIDO'' ' +
    'AND DATE(V.FECHA_REDENCION_VL) BETWEEN :DESDE AND :HASTA ' +
    'AND V.IMPORTE_REDIMIDO_VL > 0 ' +
    'AND ((V.CODIGO_EMP_RED_VL = :EMPRESA_ORIGEN ' +
    ' AND V.CODIGO_EMP_EMI_VL = :EMPRESA_DESTINO) ' +
    ' OR (V.CODIGO_EMP_RED_VL = :EMPRESA_DESTINO ' +
    ' AND V.CODIGO_EMP_EMI_VL = :EMPRESA_ORIGEN)) ' +
    'AND NOT EXISTS (SELECT 1 FROM fza_proformas_caja_vales P ' +
    ' WHERE P.CODIGO_VL_PROCVL = V.CODIGO_VL)';
  SQL_RESUMEN_VALES_PROPUESTA =
    'SELECT COUNT(*) AS CANTIDAD, ' +
    'COALESCE(SUM(CASE WHEN IMPORTE_COMPENSACION_PROCVL < 0 ' +
    ' THEN 1 ELSE 0 END), 0) AS INVERSOS, ' +
    'COALESCE(SUM(IMPORTE_COMPENSACION_PROCVL), 0) AS TOTAL ' +
    'FROM fza_proformas_caja_vales WHERE ID_PROCAJ_PROCVL = :ID';
  SQL_ACTUALIZAR_TOTALES_VALES =
    'UPDATE fza_proformas_caja SET TOTAL_BASE_PROCAJ = :TOTAL, ' +
    'TOTAL_IMPUESTOS_PROCAJ = 0, TOTAL_PROCAJ = :TOTAL, ' +
    'INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO ' +
    'WHERE ID_PROCAJ = :ID';
  SQL_BLOQUEAR_PROFORMA_VALES =
    'SELECT P.ID_PROCAJ, P.SERIE_PROCAJ, P.NUMERO_PROCAJ, ' +
    'P.FECHA_PROCAJ, P.FECHA_DESDE_PROCAJ, P.FECHA_HASTA_PROCAJ, ' +
    'P.CODIGO_EMP_PROCAJ, FP.CODIGO_EMP_DESTINO_FACPER, ' +
    'P.TOTAL_PROCAJ, ' +
    '(SELECT COUNT(*) FROM fza_proformas_caja_vales V ' +
    ' WHERE V.ID_PROCAJ_PROCVL = P.ID_PROCAJ) AS CANTIDAD ' +
    'FROM fza_proformas_caja P ' +
    'JOIN fza_facturacion_caja_periodos FP ' +
    ' ON FP.ID_FACPER = P.ID_FACPER_PROCAJ ' +
    'WHERE P.ID_PROCAJ = :ID AND P.TIPO_PROCAJ = ''VR'' ' +
    'AND P.ESTADO_PROCAJ = ''EMITIDA'' FOR UPDATE';
  SQL_MARCAR_VALES_FACTURADOS =
    'UPDATE fza_proformas_caja_vales SET SERIE_FAC_PROCVL = :SERIE, ' +
    'NUMERO_FAC_PROCVL = :NUMERO, INSTANTE_MODIF = NOW(), ' +
    'USUARIO_MODIF = :USUARIO WHERE ID_PROCAJ_PROCVL = :ID ' +
    'AND SERIE_FAC_PROCVL IS NULL';
  SQL_MARCAR_PROFORMA_VALES_FACTURADA =
    'UPDATE fza_proformas_caja SET ESTADO_PROCAJ = ''FACTURADA'', ' +
    'INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO ' +
    'WHERE ID_PROCAJ = :ID AND ESTADO_PROCAJ = ''EMITIDA''';
  SQL_LEER_VALES_PROPUESTA =
    'SELECT CODIGO_VL_PROCVL, IMPORTE_COMPENSACION_PROCVL ' +
    'FROM fza_proformas_caja_vales WHERE ID_PROCAJ_PROCVL = :ID ' +
    'ORDER BY FECHA_REDENCION_PROCVL, CODIGO_VL_PROCVL';
  SQL_TOTAL_FACTURA_VALES =
    'SELECT COALESCE(SUM(TOTAL_FACLIN), 0) AS TOTAL ' +
    'FROM fza_facturas_lineas WHERE SERIE_FAC_FACLIN = :SERIE ' +
    'AND NUMERO_FAC_FACLIN = :NUMERO';
  SQL_INSERTAR_LINEA_FACTURA_VALES =
    'INSERT INTO fza_facturas_lineas (' +
    'NUMERO_FAC_FACLIN, SERIE_FAC_FACLIN, CODIGO_EMP_FACLIN, ' +
    'LINEA_FACLIN, TIPO_ARTICULO_FACLIN, ' +
    'TIPO_CANTIDAD_ARTICULO_FACLIN, CANTIDAD_FACLIN, ' +
    'DESCRIPCION_ARTICULO_FACLIN, ESIMP_INCL_TARIFA_FACLIN, ' +
    'PRECIO_VENTA_SIVA_ARTICULO_FACLIN, TIPO_IVA_ARTICULO_FACLIN, ' +
    'PORCENTAJE_IVA_FACLIN, PRECIO_VENTA_CIVA_ARTICULO_FACLIN, ' +
    'TOTAL_FACLIN, TOTAL_FAC_SIVA_FACLIN, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:NUMERO, :SERIE, :EMISOR, :LINEA, ''SERVICIO'', ''Uds'', ' +
    '1, :DESCRIPCION, ''N'', :IMPORTE, ''E'', 0, :IMPORTE, ' +
    ':IMPORTE, :IMPORTE, NOW(), NOW(), :USUARIO, :USUARIO)';
  SQL_CONTAR_CANDIDATAS_VENTA =
    'SELECT COUNT(*) AS CANTIDAD FROM (' +
    'SELECT O.ID_OPCAJA FROM fza_caja_operaciones O ' +
    'JOIN fza_facturas F ON F.SERIE_FAC = O.SERIE_FAC_OPCAJA ' +
    ' AND F.NUMERO_FAC = O.NUMERO_FAC_OPCAJA ' +
    'WHERE O.TIPO_OPERACION_OPCAJA = ''VE'' ' +
    ' AND O.CODIGO_EMP_OPCAJA = :EMPRESA_ORIGEN ' +
    ' AND COALESCE(O.FECHA_OP_DIA_OPCAJA, ' +
    ' DATE(O.FECHA_OPERACION_OPCAJA)) BETWEEN :DESDE AND :HASTA ' +
    ' AND F.TIPO_FAC = ''SIMPLIFICADA'' ' +
    ' AND F.ESCONSOLIDADA_FAC = ''S'' ' +
    ' AND COALESCE(NULLIF(TRIM(F.CODIGO_CLI_FAC), ''0''), '''') = '''' ' +
    ' AND COALESCE(TRIM(F.NIF_CLIENTE_FAC), '''') = '''' ' +
    ' AND COALESCE(F.FASE_FAC, '''') NOT IN ' +
    ' (''RECTIFICADA'', ''CANCELADA'', ''SIN_VERIF_ANULADA'', ' +
    ' ''VERIFACTU_ANULADA'', ''NOVERIFACTU_ANULADA'') ' +
    ' AND NOT EXISTS (SELECT 1 FROM fza_verifactu_cola V ' +
    ' WHERE V.SERIE_FAC_VFCOLA = O.SERIE_FAC_OPCAJA ' +
    ' AND V.NUMERO_FAC_VFCOLA = O.NUMERO_FAC_OPCAJA ' +
    ' AND V.TIPO_OPERACION_VFCOLA = ''ANULACION'') ' +
    ' AND NOT EXISTS (SELECT 1 FROM fza_facturas_relaciones R ' +
    ' WHERE R.SERIE_FAC_ORIGEN_FACREL = O.SERIE_FAC_OPCAJA ' +
    ' AND R.NUMERO_FAC_ORIGEN_FACREL = O.NUMERO_FAC_OPCAJA) ' +
    ' AND NOT EXISTS (SELECT 1 FROM fza_proformas_caja_lineas P ' +
    ' WHERE P.ID_OPCAJA_PROCLIN = O.ID_OPCAJA ' +
    ' AND P.TIPO_VINCULO_PROCLIN = ''ORIGEN'') ' +
    'UNION ALL ' +
    'SELECT DISTINCT P.ID_OPCAJA_PROCLIN ' +
    'FROM fza_proformas_caja_lineas P ' +
    'JOIN fza_proformas_caja H ' +
    ' ON H.ID_PROCAJ = P.ID_PROCAJ_PROCLIN ' +
    'LEFT JOIN fza_facturas F ' +
    ' ON F.SERIE_FAC = P.SERIE_FAC_ORIGEN_PROCLIN ' +
    ' AND F.NUMERO_FAC = P.NUMERO_FAC_ORIGEN_PROCLIN ' +
    'WHERE H.CODIGO_EMP_PROCAJ = :EMPRESA_ORIGEN ' +
    ' AND P.TIPO_VINCULO_PROCLIN = ''ORIGEN'' ' +
    ' AND (F.NUMERO_FAC IS NULL ' +
    ' OR F.TIPO_FAC <> ''SIMPLIFICADA'' ' +
    ' OR COALESCE(F.FASE_FAC, '''') IN ' +
    ' (''RECTIFICADA'', ''CANCELADA'', ''SIN_VERIF_ANULADA'', ' +
    ' ''VERIFACTU_ANULADA'', ''NOVERIFACTU_ANULADA'') ' +
    ' OR EXISTS (SELECT 1 FROM fza_verifactu_cola V ' +
    ' WHERE V.SERIE_FAC_VFCOLA = P.SERIE_FAC_ORIGEN_PROCLIN ' +
    ' AND V.NUMERO_FAC_VFCOLA = P.NUMERO_FAC_ORIGEN_PROCLIN ' +
    ' AND V.TIPO_OPERACION_VFCOLA = ''ANULACION'') ' +
    ' OR EXISTS (SELECT 1 FROM fza_facturas_relaciones R ' +
    ' WHERE R.SERIE_FAC_ORIGEN_FACREL = ' +
    ' P.SERIE_FAC_ORIGEN_PROCLIN ' +
    ' AND R.NUMERO_FAC_ORIGEN_FACREL = ' +
    ' P.NUMERO_FAC_ORIGEN_PROCLIN)) ' +
    ' AND NOT EXISTS (SELECT 1 FROM fza_proformas_caja_lineas A ' +
    ' WHERE A.ID_OPCAJA_PROCLIN = P.ID_OPCAJA_PROCLIN ' +
    ' AND A.TIPO_VINCULO_PROCLIN = ''AJUSTE'' ' +
    ' AND A.SERIE_FAC_ORIGEN_PROCLIN = ' +
    ' P.SERIE_FAC_ORIGEN_PROCLIN ' +
    ' AND A.NUMERO_FAC_ORIGEN_PROCLIN = ' +
    ' P.NUMERO_FAC_ORIGEN_PROCLIN ' +
    ' AND A.LINEA_FAC_ORIGEN_PROCLIN = ' +
    ' P.LINEA_FAC_ORIGEN_PROCLIN)) X';
  SQL_INSERTAR_PROFORMA =
    'INSERT INTO fza_proformas_caja (' +
    'ID_FACPER_PROCAJ, NUMERO_PROCAJ, SERIE_PROCAJ, FECHA_PROCAJ, ' +
    'FECHA_DESDE_PROCAJ, FECHA_HASTA_PROCAJ, TIPO_PROCAJ, ' +
    'ESTADO_PROCAJ, CODIGO_EMP_PROCAJ, ' +
    'RAZON_SOCIAL_EMPRESA_PROCAJ, NIF_EMPRESA_PROCAJ, ' +
    'DIRECCION1_EMPRESA_PROCAJ, DIRECCION2_EMPRESA_PROCAJ, ' +
    'CODIGO_POSTAL_EMPRESA_PROCAJ, POBLACION_EMPRESA_PROCAJ, ' +
    'PROVINCIA_EMPRESA_PROCAJ, CODIGO_PAI_EMPRESA_PROCAJ, ' +
    'NOMBRE_PAI_EMPRESA_PROCAJ, CODIGO_CLI_PROCAJ, ' +
    'RAZON_SOCIAL_CLIENTE_PROCAJ, INSTANTE_ALTA, INSTANTE_MODIF, ' +
    'USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :ID_PERIODO, :NUMERO, :SERIE, :HASTA, :DESDE, :HASTA, ''VE'', ' +
    '''EMITIDA'', E.CODIGO_EMP_EMP, E.RAZON_SOCIAL_EMP, E.NIF_EMP, ' +
    'E.DIRECCION1_EMP, E.DIRECCION2_EMP, E.CODIGO_POSTAL_EMP, ' +
    'E.POBLACION_EMP, E.PROVINCIA_EMP, E.CODIGO_PAI_EMP, ' +
    'E.NOMBRE_PAI_EMP, ''0'', ''VENTA CONTADO'', NOW(), NOW(), ' +
    ':USUARIO, :USUARIO FROM fza_empresas E ' +
    'WHERE E.CODIGO_EMP_EMP = :EMPRESA_ORIGEN';
  SQL_INICIAR_LINEA_PROFORMA = 'SET @linea_proforma := 0';
  SQL_CONTINUAR_LINEA_PROFORMA =
    'SET @linea_proforma := (SELECT COALESCE(' +
    'MAX(CAST(LINEA_PROCLIN AS UNSIGNED)), 0) ' +
    'FROM fza_proformas_caja_lineas WHERE ID_PROCAJ_PROCLIN = :ID)';
  SQL_INSERTAR_LINEAS_VENTA =
    'INSERT IGNORE INTO fza_proformas_caja_lineas (' +
    'ID_PROCAJ_PROCLIN, LINEA_PROCLIN, ID_OPCAJA_PROCLIN, ' +
    'TIPO_VINCULO_PROCLIN, SERIE_FAC_ORIGEN_PROCLIN, ' +
    'NUMERO_FAC_ORIGEN_PROCLIN, LINEA_FAC_ORIGEN_PROCLIN, ' +
    'NUMERO_OPERACION_PROCLIN, FECHA_OPERACION_PROCLIN, ' +
    'CODIGO_ART_PROCLIN, CODIGO_UNIDAD_PROCLIN, ' +
    'DESCRIPCION_ARTICULO_PROCLIN, TIPO_IVA_PROCLIN, ' +
    'CANTIDAD_PROCLIN, PRECIO_SIVA_PROCLIN, ' +
    'PORCENTAJE_IVA_PROCLIN, TOTAL_SIVA_PROCLIN, TOTAL_PROCLIN, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :ID, LPAD((@linea_proforma := @linea_proforma + 10), ' +
    '8, ''0''), O.ID_OPCAJA, ''ORIGEN'', F.SERIE_FAC, ' +
    'F.NUMERO_FAC, L.LINEA_FACLIN, O.NUMERO_OPERACION_OPCAJA, ' +
    'COALESCE(O.FECHA_OP_DIA_OPCAJA, DATE(O.FECHA_OPERACION_OPCAJA)), ' +
    'L.CODIGO_ART_FACLIN, L.CODIGO_UNIDAD_FACLIN, ' +
    'L.DESCRIPCION_ARTICULO_FACLIN, L.TIPO_IVA_ARTICULO_FACLIN, ' +
    'L.CANTIDAD_FACLIN, L.PRECIO_VENTA_SIVA_ARTICULO_FACLIN, ' +
    'L.PORCENTAJE_IVA_FACLIN, COALESCE(L.TOTAL_FAC_SIVA_FACLIN, ' +
    'L.CANTIDAD_FACLIN * L.PRECIO_VENTA_SIVA_ARTICULO_FACLIN), ' +
    'L.TOTAL_FACLIN, NOW(), NOW(), :USUARIO, :USUARIO ' +
    'FROM fza_caja_operaciones O ' +
    'JOIN fza_facturas F ON F.SERIE_FAC = O.SERIE_FAC_OPCAJA ' +
    ' AND F.NUMERO_FAC = O.NUMERO_FAC_OPCAJA ' +
    'JOIN fza_facturas_lineas L ' +
    ' ON L.SERIE_FAC_FACLIN = F.SERIE_FAC ' +
    ' AND L.NUMERO_FAC_FACLIN = F.NUMERO_FAC ' +
    'WHERE O.TIPO_OPERACION_OPCAJA = ''VE'' ' +
    ' AND O.CODIGO_EMP_OPCAJA = :EMPRESA_ORIGEN ' +
    ' AND COALESCE(O.FECHA_OP_DIA_OPCAJA, ' +
    ' DATE(O.FECHA_OPERACION_OPCAJA)) BETWEEN :DESDE AND :HASTA ' +
    ' AND F.TIPO_FAC = ''SIMPLIFICADA'' ' +
    ' AND F.ESCONSOLIDADA_FAC = ''S'' ' +
    ' AND COALESCE(NULLIF(TRIM(F.CODIGO_CLI_FAC), ''0''), '''') = '''' ' +
    ' AND COALESCE(TRIM(F.NIF_CLIENTE_FAC), '''') = '''' ' +
    ' AND COALESCE(F.FASE_FAC, '''') NOT IN ' +
    ' (''RECTIFICADA'', ''CANCELADA'', ''SIN_VERIF_ANULADA'', ' +
    ' ''VERIFACTU_ANULADA'', ''NOVERIFACTU_ANULADA'') ' +
    ' AND NOT EXISTS (SELECT 1 FROM fza_verifactu_cola V ' +
    ' WHERE V.SERIE_FAC_VFCOLA = O.SERIE_FAC_OPCAJA ' +
    ' AND V.NUMERO_FAC_VFCOLA = O.NUMERO_FAC_OPCAJA ' +
    ' AND V.TIPO_OPERACION_VFCOLA = ''ANULACION'') ' +
    ' AND NOT EXISTS (SELECT 1 FROM fza_facturas_relaciones R ' +
    ' WHERE R.SERIE_FAC_ORIGEN_FACREL = O.SERIE_FAC_OPCAJA ' +
    ' AND R.NUMERO_FAC_ORIGEN_FACREL = O.NUMERO_FAC_OPCAJA) ' +
    ' AND NOT EXISTS (SELECT 1 FROM fza_proformas_caja_lineas P ' +
    ' WHERE P.ID_OPCAJA_PROCLIN = O.ID_OPCAJA ' +
    ' AND P.TIPO_VINCULO_PROCLIN = ''ORIGEN'') ' +
    'ORDER BY COALESCE(O.FECHA_OP_DIA_OPCAJA, ' +
    'DATE(O.FECHA_OPERACION_OPCAJA)), O.ID_OPCAJA, L.LINEA_FACLIN';
  SQL_INSERTAR_AJUSTES_VENTA =
    'INSERT IGNORE INTO fza_proformas_caja_lineas (' +
    'ID_PROCAJ_PROCLIN, LINEA_PROCLIN, ID_OPCAJA_PROCLIN, ' +
    'TIPO_VINCULO_PROCLIN, ID_PROCAJ_ORIGEN_PROCLIN, ' +
    'LINEA_PROCAJ_ORIGEN_PROCLIN, SERIE_FAC_ORIGEN_PROCLIN, ' +
    'NUMERO_FAC_ORIGEN_PROCLIN, LINEA_FAC_ORIGEN_PROCLIN, ' +
    'NUMERO_OPERACION_PROCLIN, FECHA_OPERACION_PROCLIN, ' +
    'CODIGO_ART_PROCLIN, CODIGO_UNIDAD_PROCLIN, ' +
    'DESCRIPCION_ARTICULO_PROCLIN, TIPO_IVA_PROCLIN, ' +
    'CANTIDAD_PROCLIN, PRECIO_SIVA_PROCLIN, ' +
    'PORCENTAJE_IVA_PROCLIN, TOTAL_SIVA_PROCLIN, TOTAL_PROCLIN, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :ID, LPAD((@linea_proforma := @linea_proforma + 10), ' +
    '8, ''0''), P.ID_OPCAJA_PROCLIN, ''AJUSTE'', ' +
    'P.ID_PROCAJ_PROCLIN, P.LINEA_PROCLIN, ' +
    'P.SERIE_FAC_ORIGEN_PROCLIN, P.NUMERO_FAC_ORIGEN_PROCLIN, ' +
    'P.LINEA_FAC_ORIGEN_PROCLIN, P.NUMERO_OPERACION_PROCLIN, ' +
    'P.FECHA_OPERACION_PROCLIN, P.CODIGO_ART_PROCLIN, ' +
    'P.CODIGO_UNIDAD_PROCLIN, ' +
    'CONCAT(''AJUSTE: '', P.DESCRIPCION_ARTICULO_PROCLIN), ' +
    'P.TIPO_IVA_PROCLIN, -P.CANTIDAD_PROCLIN, ' +
    'P.PRECIO_SIVA_PROCLIN, P.PORCENTAJE_IVA_PROCLIN, ' +
    '-P.TOTAL_SIVA_PROCLIN, -P.TOTAL_PROCLIN, NOW(), NOW(), ' +
    ':USUARIO, :USUARIO FROM fza_proformas_caja_lineas P ' +
    'JOIN fza_proformas_caja H ' +
    ' ON H.ID_PROCAJ = P.ID_PROCAJ_PROCLIN ' +
    'LEFT JOIN fza_facturas F ' +
    ' ON F.SERIE_FAC = P.SERIE_FAC_ORIGEN_PROCLIN ' +
    ' AND F.NUMERO_FAC = P.NUMERO_FAC_ORIGEN_PROCLIN ' +
    'WHERE H.CODIGO_EMP_PROCAJ = :EMPRESA_ORIGEN ' +
    ' AND P.TIPO_VINCULO_PROCLIN = ''ORIGEN'' ' +
    ' AND (F.NUMERO_FAC IS NULL ' +
    ' OR F.TIPO_FAC <> ''SIMPLIFICADA'' ' +
    ' OR COALESCE(F.FASE_FAC, '''') IN ' +
    ' (''RECTIFICADA'', ''CANCELADA'', ''SIN_VERIF_ANULADA'', ' +
    ' ''VERIFACTU_ANULADA'', ''NOVERIFACTU_ANULADA'') ' +
    ' OR EXISTS (SELECT 1 FROM fza_verifactu_cola V ' +
    ' WHERE V.SERIE_FAC_VFCOLA = P.SERIE_FAC_ORIGEN_PROCLIN ' +
    ' AND V.NUMERO_FAC_VFCOLA = P.NUMERO_FAC_ORIGEN_PROCLIN ' +
    ' AND V.TIPO_OPERACION_VFCOLA = ''ANULACION'') ' +
    ' OR EXISTS (SELECT 1 FROM fza_facturas_relaciones R ' +
    ' WHERE R.SERIE_FAC_ORIGEN_FACREL = ' +
    ' P.SERIE_FAC_ORIGEN_PROCLIN ' +
    ' AND R.NUMERO_FAC_ORIGEN_FACREL = ' +
    ' P.NUMERO_FAC_ORIGEN_PROCLIN)) ' +
    ' AND NOT EXISTS (SELECT 1 FROM fza_proformas_caja_lineas A ' +
    ' WHERE A.ID_OPCAJA_PROCLIN = P.ID_OPCAJA_PROCLIN ' +
    ' AND A.TIPO_VINCULO_PROCLIN = ''AJUSTE'' ' +
    ' AND A.SERIE_FAC_ORIGEN_PROCLIN = ' +
    ' P.SERIE_FAC_ORIGEN_PROCLIN ' +
    ' AND A.NUMERO_FAC_ORIGEN_PROCLIN = ' +
    ' P.NUMERO_FAC_ORIGEN_PROCLIN ' +
    ' AND A.LINEA_FAC_ORIGEN_PROCLIN = ' +
    ' P.LINEA_FAC_ORIGEN_PROCLIN) ' +
    'ORDER BY P.FECHA_OPERACION_PROCLIN, P.ID_OPCAJA_PROCLIN, ' +
    'P.LINEA_PROCLIN';
  SQL_ACTUALIZAR_TOTALES_PROFORMA =
    'UPDATE fza_proformas_caja H SET ' +
    'H.TOTAL_BASE_PROCAJ = (SELECT COALESCE(SUM(L.TOTAL_SIVA_PROCLIN), 0) ' +
    ' FROM fza_proformas_caja_lineas L ' +
    ' WHERE L.ID_PROCAJ_PROCLIN = H.ID_PROCAJ), ' +
    'H.TOTAL_PROCAJ = (SELECT COALESCE(SUM(L.TOTAL_PROCLIN), 0) ' +
    ' FROM fza_proformas_caja_lineas L ' +
    ' WHERE L.ID_PROCAJ_PROCLIN = H.ID_PROCAJ), ' +
    'H.TOTAL_IMPUESTOS_PROCAJ = (SELECT COALESCE(' +
    'SUM(L.TOTAL_PROCLIN - L.TOTAL_SIVA_PROCLIN), 0) ' +
    ' FROM fza_proformas_caja_lineas L ' +
    ' WHERE L.ID_PROCAJ_PROCLIN = H.ID_PROCAJ), ' +
    'H.INSTANTE_MODIF = NOW(), H.USUARIO_MODIF = :USUARIO ' +
    'WHERE H.ID_PROCAJ = :ID';
  SQL_CONTAR_PROFORMA =
    'SELECT COUNT(DISTINCT ID_OPCAJA_PROCLIN) AS OPERACIONES, ' +
    'COUNT(DISTINCT CASE WHEN TIPO_VINCULO_PROCLIN = ''AJUSTE'' ' +
    'THEN ID_OPCAJA_PROCLIN END) AS AJUSTES ' +
    'FROM fza_proformas_caja_lineas WHERE ID_PROCAJ_PROCLIN = :ID';
  SQL_GRUPOS_TRASPASO =
    'SELECT O.CODIGO_EMP_OPCAJA AS EMPRESA, ' +
    'O.CODIGO_ALM_OPCAJA AS ALMACEN ' +
    'FROM fza_caja_operaciones O ' +
    'WHERE O.TIPO_OPERACION_OPCAJA = ''TA'' ' +
    ' AND O.ESTRASPASO_OPCAJA = ''S'' ' +
    ' AND O.CODIGO_EMP_OPCAJA = :EMPRESA_ORIGEN ' +
    ' AND O.CODIGO_EMP_CONTRA_OPCAJA = :EMPRESA_DESTINO ' +
    ' AND COALESCE(O.FECHA_OP_DIA_OPCAJA, ' +
    ' DATE(O.FECHA_OPERACION_OPCAJA)) BETWEEN :DESDE AND :HASTA ' +
    ' AND NOT EXISTS (SELECT 1 FROM fza_facturas_operaciones_caja X ' +
    ' WHERE X.ID_OPCAJA_FACOP = O.ID_OPCAJA) ' +
    ' AND EXISTS (SELECT 1 FROM fza_movimientos_almacen M ' +
    ' WHERE M.TIPO_DOC_MOV = ''TA'' AND M.TIPO_MOV = ''S'' ' +
    ' AND M.ESACTIVO_MOV = ''S'' ' +
    ' AND M.CODIGO_EMP_MOV = O.CODIGO_EMP_OPCAJA ' +
    ' AND M.CODIGO_ALM_DOC_MOV = O.CODIGO_ALM_OPCAJA ' +
    ' AND M.CODIGO_CAJA_DOC_MOV = O.CODIGO_CAJA_OPCAJA ' +
    ' AND M.NUMERO_OPERACION_DOC_MOV = O.NUMERO_OPERACION_OPCAJA) ' +
    SQL_EXCLUIR_OPERACION_FACTURADA_TV +
    'GROUP BY O.CODIGO_EMP_OPCAJA, O.CODIGO_ALM_OPCAJA ' +
    'ORDER BY O.CODIGO_EMP_OPCAJA, O.CODIGO_ALM_OPCAJA';
  SQL_CONTAR_LINEAS_TRASPASO =
    'SELECT COUNT(*) AS CANTIDAD FROM fza_caja_operaciones O ' +
    'JOIN fza_movimientos_almacen M ' +
    ' ON M.CODIGO_EMP_MOV = O.CODIGO_EMP_OPCAJA ' +
    ' AND M.CODIGO_ALM_DOC_MOV = O.CODIGO_ALM_OPCAJA ' +
    ' AND M.CODIGO_CAJA_DOC_MOV = O.CODIGO_CAJA_OPCAJA ' +
    ' AND M.NUMERO_OPERACION_DOC_MOV = O.NUMERO_OPERACION_OPCAJA ' +
    'WHERE O.TIPO_OPERACION_OPCAJA = ''TA'' ' +
    ' AND O.ESTRASPASO_OPCAJA = ''S'' ' +
    ' AND O.CODIGO_EMP_OPCAJA = :ORIGEN ' +
    ' AND O.CODIGO_ALM_OPCAJA = :ALMACEN ' +
    ' AND O.CODIGO_EMP_CONTRA_OPCAJA = :EMPRESA_DESTINO ' +
    ' AND COALESCE(O.FECHA_OP_DIA_OPCAJA, ' +
    ' DATE(O.FECHA_OPERACION_OPCAJA)) BETWEEN :DESDE AND :HASTA ' +
    ' AND M.TIPO_DOC_MOV = ''TA'' AND M.TIPO_MOV = ''S'' ' +
    ' AND M.ESACTIVO_MOV = ''S'' ' +
    ' AND NOT EXISTS (SELECT 1 FROM fza_facturas_operaciones_caja X ' +
    ' WHERE X.ID_OPCAJA_FACOP = O.ID_OPCAJA) ' +
    SQL_EXCLUIR_OPERACION_FACTURADA_TV;
  SQL_CONTAR_LINEAS_FACTURA_TA =
    'SELECT COUNT(*) AS CANTIDAD ' +
    'FROM fza_facturas_operaciones_caja X ' +
    'JOIN fza_caja_operaciones O ON O.ID_OPCAJA = X.ID_OPCAJA_FACOP ' +
    'JOIN fza_movimientos_almacen M ' +
    ' ON M.CODIGO_EMP_MOV = O.CODIGO_EMP_OPCAJA ' +
    ' AND M.CODIGO_ALM_DOC_MOV = O.CODIGO_ALM_OPCAJA ' +
    ' AND M.CODIGO_CAJA_DOC_MOV = O.CODIGO_CAJA_OPCAJA ' +
    ' AND M.NUMERO_OPERACION_DOC_MOV = O.NUMERO_OPERACION_OPCAJA ' +
    'WHERE X.SERIE_FAC_FACOP = :SERIE ' +
    ' AND X.NUMERO_FAC_FACOP = :NUMERO ' +
    ' AND M.TIPO_DOC_MOV = ''TA'' AND M.TIPO_MOV = ''S'' ' +
    ' AND M.ESACTIVO_MOV = ''S''';
  SQL_OBTENER_SERIE_FACTURA =
    'SELECT S.EMPSER FROM vi_empresas_series S ' +
    'JOIN fza_contadores C ON C.TIPO_DOC_CON = ''FC'' ' +
    ' AND C.EMPRESA_CON = S.CODIGO_EMP_EMPSER ' +
    ' AND C.SERIE_CON = S.EMPSER AND C.ESACTIVO_CON = ''S'' ' +
    'WHERE S.CODIGO_EMP_EMPSER = :ORIGEN ' +
    ' AND S.TIPO_DOC_EMPSER = ''FC'' ' +
    ' AND S.SUBTIPO_EMPSER = ''NORMAL'' ' +
    ' AND (S.CODIGO_ALM_EMPSER = :ALMACEN ' +
    ' OR S.CODIGO_ALM_EMPSER IS NULL OR S.CODIGO_ALM_EMPSER = '''') ' +
    ' AND (S.FECHA_DESDE_EMPSER IS NULL ' +
    ' OR S.FECHA_DESDE_EMPSER <= :FECHA) ' +
    ' AND (S.FECHA_HASTA_EMPSER IS NULL ' +
    ' OR S.FECHA_HASTA_EMPSER >= :FECHA) ' +
    'ORDER BY (S.CODIGO_ALM_EMPSER = :ALMACEN) DESC, ' +
    'S.ESDEFECTO_EMPSER DESC, S.FECHA_DESDE_EMPSER DESC LIMIT 1';
  SQL_OBTENER_SERIE_CONTADOR =
    'SELECT S.EMPSER FROM vi_empresas_series S ' +
    'JOIN fza_contadores C ON C.TIPO_DOC_CON = ''FC'' ' +
    ' AND C.EMPRESA_CON = S.CODIGO_EMP_EMPSER ' +
    ' AND C.SERIE_CON = S.EMPSER AND C.ESACTIVO_CON = ''S'' ' +
    'WHERE S.CODIGO_EMP_EMPSER = :ORIGEN ' +
    ' AND S.TIPO_DOC_EMPSER = ''FC'' ' +
    ' AND S.SUBTIPO_EMPSER = ''NORMAL'' ' +
    ' AND (S.FECHA_DESDE_EMPSER IS NULL ' +
    ' OR S.FECHA_DESDE_EMPSER <= :FECHA) ' +
    ' AND (S.FECHA_HASTA_EMPSER IS NULL ' +
    ' OR S.FECHA_HASTA_EMPSER >= :FECHA) ' +
    'ORDER BY (C.DEFAULT_CON = ''S'') DESC, S.ESDEFECTO_EMPSER DESC, ' +
    'S.FECHA_DESDE_EMPSER DESC, S.EMPSER LIMIT 1';
  SQL_DIGITOS_CONTADOR_FACTURA =
    'SELECT COALESCE(MAX(NUM_DIGITOS_CON), 0) AS DIGITOS ' +
    '  FROM fza_contadores ' +
    ' WHERE TIPO_DOC_CON = ''FC'' ' +
    '   AND EMPRESA_CON IN (:EMPRESA, ''-'') ' +
    '   AND SERIE_CON = :SERIE';
  SQL_EXISTE_FACTURA =
    'SELECT 1 FROM fza_facturas ' +
    ' WHERE SERIE_FAC = :SERIE AND NUMERO_FAC = :NUMERO';
  SQL_ORIGEN_TRASPASOS_PENDIENTES =
    'FROM fza_caja_operaciones O ' +
    'JOIN fza_movimientos_almacen M ' +
    ' ON M.CODIGO_EMP_MOV = O.CODIGO_EMP_OPCAJA ' +
    ' AND M.CODIGO_ALM_DOC_MOV = O.CODIGO_ALM_OPCAJA ' +
    ' AND M.CODIGO_CAJA_DOC_MOV = O.CODIGO_CAJA_OPCAJA ' +
    ' AND M.NUMERO_OPERACION_DOC_MOV = O.NUMERO_OPERACION_OPCAJA ' +
    'LEFT JOIN fza_articulos A ON A.CODIGO_ART_ART = M.CODIGO_ART_MOV ';
  SQL_FILTRO_TRASPASOS_PENDIENTES =
    'WHERE O.TIPO_OPERACION_OPCAJA = ''TA'' ' +
    ' AND O.ESTRASPASO_OPCAJA = ''S'' ' +
    ' AND O.CODIGO_EMP_OPCAJA = :EMPRESA_ORIGEN ' +
    ' AND O.CODIGO_EMP_CONTRA_OPCAJA = :EMPRESA_DESTINO ' +
    ' AND COALESCE(O.FECHA_OP_DIA_OPCAJA, ' +
    ' DATE(O.FECHA_OPERACION_OPCAJA)) BETWEEN :DESDE AND :HASTA ' +
    ' AND M.TIPO_DOC_MOV = ''TA'' AND M.TIPO_MOV = ''S'' ' +
    ' AND M.ESACTIVO_MOV = ''S'' ' +
    ' AND NOT EXISTS (SELECT 1 FROM fza_facturas_operaciones_caja X ' +
    ' WHERE X.ID_OPCAJA_FACOP = O.ID_OPCAJA) ' +
    SQL_EXCLUIR_OPERACION_FACTURADA_TV;
  // PMP de la empresa emisora: media ponderada del stock de todos sus
  // almacenes (igual que TdmTraspaso.ObtenerCosteMedio, pero por empresa).
  // Última compra: coste del SKU y, si no consta, el del proveedor principal.
  // Se guarda sin impuestos (FZ-ISSUE-381): a la empresa emisora en recargo
  // se le suman el IVA y el recargo, que no deduce, como en su PMP.
  SQL_PRECIOS_REFERENCIA_TRASPASO =
    'COALESCE((SELECT CASE WHEN SUM(S.CANTIDAD_STK) > 0 ' +
    ' THEN SUM(S.PRECIO_MEDIO_STK * S.CANTIDAD_STK) / SUM(S.CANTIDAD_STK) ' +
    ' ELSE MAX(S.PRECIO_MEDIO_STK) END ' +
    ' FROM fza_articulos_stockactual S ' +
    ' JOIN fza_almacenes AL ON AL.CODIGO_ALM_ALM = S.CODIGO_ALM_STK ' +
    ' WHERE AL.CODIGO_EMP_ALM = O.CODIGO_EMP_OPCAJA ' +
    ' AND S.CODIGO_UNIDAD_STK = M.CODIGO_UNIDAD_MOV), 0) ' +
    'AS PRECIO_MEDIO_EMPRESA, ' +
    'COALESCE((SELECT C.PRECIO_ULT_COMPRA_SKUC ' +
    ' FROM fza_articulos_skus_costes C ' +
    ' WHERE C.CODIGO_UNIDAD_SKU_SKUC = M.CODIGO_UNIDAD_MOV), ' +
    '(SELECT MAX(AP.PRECIO_ULT_COMPRA_AP) ' +
    ' FROM fza_articulos_proveedores AP ' +
    ' WHERE AP.CODIGO_ART_AP = M.CODIGO_ART_MOV ' +
    ' AND AP.ESPROVEEDORPRINCIPAL_AP = ''S''), 0) * ' +
    SQL_FACTOR_COSTE_COMPRA_EMPRESA_INI + 'M.CODIGO_ART_MOV' +
    SQL_FACTOR_COSTE_COMPRA_EMPRESA_MED + 'O.CODIGO_EMP_OPCAJA' +
    SQL_FACTOR_COSTE_COMPRA_EMPRESA_FIN + ' ' +
    'AS PRECIO_ULTIMA_COMPRA, ' +
    'COALESCE(TIMESTAMPDIFF(MONTH, (SELECT C2.FECHA_ULT_COMPRA_SKUC ' +
    ' FROM fza_articulos_skus_costes C2 ' +
    ' WHERE C2.CODIGO_UNIDAD_SKU_SKUC = M.CODIGO_UNIDAD_MOV), ' +
    ':HASTA), 0) AS ANTIGUEDAD_MESES ';
  SQL_LINEAS_TRASPASO_PENDIENTES =
    'SELECT M.NUMERO_MOV, O.NUMERO_OPERACION_OPCAJA, ' +
    'COALESCE(O.FECHA_OP_DIA_OPCAJA, DATE(O.FECHA_OPERACION_OPCAJA)) ' +
    'AS FECHA_OPERACION, M.LINEA_MOV, M.CODIGO_ART_MOV, ' +
    'M.CODIGO_UNIDAD_MOV, ' +
    'LEFT(COALESCE(M.DESCRIPCION_ARTICULO_MOV, A.DESCRIPCION_ART, ''''), ' +
    '100) AS DESCRIPCION, M.CANTIDAD_MOV, ' +
    'COALESCE(M.PRECIO_COSTE_UNITARIO_MOV, 0) AS COSTE_MOVIMIENTO, ' +
    SQL_PRECIOS_REFERENCIA_TRASPASO +
    SQL_ORIGEN_TRASPASOS_PENDIENTES +
    SQL_FILTRO_TRASPASOS_PENDIENTES +
    'ORDER BY O.CODIGO_EMP_OPCAJA, O.CODIGO_ALM_OPCAJA, ' +
    'COALESCE(O.FECHA_OP_DIA_OPCAJA, DATE(O.FECHA_OPERACION_OPCAJA)), ' +
    'O.ID_OPCAJA, M.LINEA_MOV';
  // Tabla temporal por conexión con el precio valorado de cada movimiento.
  // Se crea desde las columnas reales para heredar tipo y colación y que el
  // JOIN con NUMERO_MOV no mezcle colaciones.
  SQL_ELIMINAR_VALORACION_TA =
    'DROP TEMPORARY TABLE IF EXISTS tmp_fza_valoracion_ta';
  SQL_CREAR_VALORACION_TA =
    'CREATE TEMPORARY TABLE tmp_fza_valoracion_ta AS ' +
    'SELECT M.NUMERO_MOV AS NUMERO_MOV_VTA, ' +
    'M.PRECIO_COSTE_UNITARIO_MOV AS PRECIO_VALORADO_VTA ' +
    'FROM fza_movimientos_almacen M WHERE 1 = 0';
  SQL_CLAVE_VALORACION_TA =
    'ALTER TABLE tmp_fza_valoracion_ta ADD PRIMARY KEY (NUMERO_MOV_VTA)';
  SQL_INSERTAR_VALORACION_TA =
    'INSERT INTO tmp_fza_valoracion_ta ' +
    '(NUMERO_MOV_VTA, PRECIO_VALORADO_VTA) VALUES (:NUMERO_MOV, :PRECIO)';
  SQL_CONTAR_LINEAS_TRASPASO_SIN_VALORAR =
    'SELECT COUNT(*) AS CANTIDAD ' +
    SQL_ORIGEN_TRASPASOS_PENDIENTES +
    'LEFT JOIN tmp_fza_valoracion_ta V ' +
    ' ON V.NUMERO_MOV_VTA = M.NUMERO_MOV ' +
    SQL_FILTRO_TRASPASOS_PENDIENTES +
    ' AND V.NUMERO_MOV_VTA IS NULL';
  // La factura interna va al cliente de traspasos de la empresa destino
  // (fza_empresas.CODIGO_CLI_TRASPASOS_EMP) con sus datos. FZ-ISSUE-355:
  // TA/TV/VR nunca llevan retención de IRPF (venta de mercancía o
  // compensación de vales), sea cual sea la casilla del cliente.
  SQL_INSERTAR_FACTURA_TA =
    'INSERT INTO fza_facturas (' +
    'NUMERO_FAC, SERIE_FAC, FECHA_FAC, ESCONSOLIDADA_FAC, ' +
    'TIPO_FAC, ESMUEVE_STOCK_FAC, FASE_FAC, CODIGO_EMP_FAC, ' +
    'RAZON_SOCIAL_EMPRESA_FAC, NIF_EMPRESA_FAC, ' +
    'MOVIL_EMPRESA_FAC, EMAIL_EMPRESA_FAC, DIRECCION1_EMPRESA_FAC, ' +
    'DIRECCION2_EMPRESA_FAC, POBLACION_EMPRESA_FAC, ' +
    'PROVINCIA_EMPRESA_FAC, CODIGO_PAI_EMPRESA_FAC, ' +
    'NOMBRE_PAI_EMPRESA_FAC, CODIGO_POSTAL_EMPRESA_FAC, ' +
    'ESRETENCIONES_EMPRESA_FAC, GRUPO_ZONA_IVA_EMPRESA_FAC, ' +
    'ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC, CODIGO_CLI_FAC, ' +
    'RAZON_SOCIAL_CLIENTE_FAC, NIF_CLIENTE_FAC, MOVIL_CLIENTE_FAC, ' +
    'EMAIL_CLIENTE_FAC, DIRECCION1_CLIENTE_FAC, ' +
    'DIRECCION2_CLIENTE_FAC, POBLACION_CLIENTE_FAC, ' +
    'PROVINCIA_CLIENTE_FAC, CODIGO_POSTAL_CLIENTE_FAC, ' +
    'CODIGO_PAI_CLIENTE_FAC, NOMBRE_PAI_CLIENTE_FAC, ' +
    'CODIGO_IVA_FAC, ESIVA_RECARGO_CLIENTE_FAC, ' +
    'ESIVA_EXENTO_CLIENTE_FAC, ' +
    'ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC, ' +
    'ESRETENCIONES_CLIENTE_FAC, ESIMP_INCL_TARIFA_CLIENTE_FAC, ' +
    'ESINTRACOMUNITARIO_CLIENTE_FAC, ESIRPF_IMP_INCL_ZONA_IVA_FAC, ' +
    'ESAPLICA_RE_ZONA_IVA_FAC, ESIVAAGRICOLA_ZONA_IVA_FAC, ' +
    'PALABRA_REPORTS_ZONA_IVA_FAC, PORCENTAJE_IVAN_FAC, ' +
    'PORCENTAJE_REN_FAC, PORCENTAJE_IVAR_FAC, PORCENTAJE_RER_FAC, ' +
    'PORCENTAJE_IVAS_FAC, PORCENTAJE_RES_FAC, PORCENTAJE_IVAE_FAC, ' +
    'PORCENTAJE_REE_FAC, FORMA_PAGO_FAC, TEXTO_LEGAL_EMPRESA_FAC, ' +
    'COMENTARIOS_FAC, CONTADOR_LINEAS_FAC, ESCREARARTICULOS_FAC, ' +
    'ESDESCRIPCIONES_AMP_FAC, ESFECHADEENTREGA_FAC, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :NUMERO, :SERIE, :FECHA_FACTURA, ''N'', ''NORMAL'', ''N'', ' +
    '''BORRADOR'', E.CODIGO_EMP_EMP, E.RAZON_SOCIAL_EMP, E.NIF_EMP, ' +
    'E.MOVIL_EMP, E.EMAIL_EMP, E.DIRECCION1_EMP, E.DIRECCION2_EMP, ' +
    'E.POBLACION_EMP, E.PROVINCIA_EMP, E.CODIGO_PAI_EMP, ' +
    'E.NOMBRE_PAI_EMP, E.CODIGO_POSTAL_EMP, E.ESRETENCIONES_EMP, ' +
    'E.GRUPO_ZONA_IVA_EMP, E.ESREGIMENESPECIALAGRICOLA_EMP, ' +
    'C.CODIGO_CLI_CLI, C.RAZON_SOCIAL_CLI, ' +
    'C.NIF_CLI, C.MOVIL_CLI, C.EMAIL_CLI, C.DIRECCION1_CLI, ' +
    'C.DIRECCION2_CLI, C.POBLACION_CLI, C.PROVINCIA_CLI, ' +
    'C.CODIGO_POSTAL_CLI, C.CODIGO_PAI_CLI, C.NOMBRE_PAI_CLI, ' +
    'I.CODIGO_IVA, COALESCE(C.ESIVA_RECARGO_CLI, ''N''), ' +
    'COALESCE(C.ESIVA_EXENTO_CLI, ''N''), ' +
    'COALESCE(C.ESREGIMENESPECIALAGRICOLA_CLI, ''N''), ' +
    '''N'', ''N'', ' +
    'COALESCE(C.ESINTRACOMUNITARIO_CLI, ''N''), ' +
    'COALESCE(G.ESIRPF_IMP_INCL_IVA_IVAGRP, ''N''), ' +
    'COALESCE(G.ESAPLICA_RE_IVA_IVAGRP, ''S''), ' +
    'COALESCE(G.ESIVAAGRICOLA_IVA_IVAGRP, ''N''), ' +
    'COALESCE(G.PALABRA_REPORTS_IVA_IVAGRP, ''IVA''), ' +
    'I.PORCENTAJE_NORMAL_IVA, I.PORCENTAJE_NORMAL_RE_IVA, ' +
    'I.PORCENTAJE_REDUCIDO_IVA, I.PORCENTAJE_REDUCIDO_RE_IVA, ' +
    'I.PORCENTAJE_SUPERREDUCIDO_IVA, ' +
    'I.PORCENTAJE_SUPERREDUCIDO_RE_IVA, I.PORCENTAJE_EXENTO_IVA, ' +
    'I.PORCENTAJE_EXENTO_RE_IVA, :FORMA_PAGO, ' +
    'E.TEXTO_LEGAL_FACTURA_EMP, ' +
    ':COMENTARIO, ' +
    // Descripciones ampliadas a N, como los borradores de ticket
    // (FZ-ISSUE-738).
    '''0000'', ''N'', ''N'', ''N'', NOW(), NOW(), :USUARIO, :USUARIO ' +
    'FROM fza_empresas E JOIN fza_empresas D ' +
    ' ON D.CODIGO_EMP_EMP = :EMPRESA_DESTINO ' +
    'JOIN fza_clientes C ' +
    ' ON C.CODIGO_CLI_CLI = D.CODIGO_CLI_TRASPASOS_EMP ' +
    // Tipos vigentes a la fecha de la factura, no al fin del periodo
    // (FZ-366)
    'JOIN fza_ivas I ON I.IVA_IVAGRP = E.GRUPO_ZONA_IVA_EMP ' +
    ' AND I.FECHA_DESDE_IVA <= :FECHA_FACTURA ' +
    ' AND (I.FECHA_HASTA_IVA IS NULL ' +
    '      OR I.FECHA_HASTA_IVA >= :FECHA_FACTURA) ' +
    'LEFT JOIN fza_ivas_grupos G ON G.IVA_IVAGRP = I.IVA_IVAGRP ' +
    'WHERE E.CODIGO_EMP_EMP = :ORIGEN ' +
    'ORDER BY I.FECHA_DESDE_IVA DESC LIMIT 1';
  SQL_INICIAR_LINEA_FACTURA = 'SET @linea_factura_ta := 0';
  SQL_INSERTAR_LINEAS_TA =
    'INSERT INTO fza_facturas_lineas (' +
    'NUMERO_FAC_FACLIN, SERIE_FAC_FACLIN, CODIGO_EMP_FACLIN, ' +
    'LINEA_FACLIN, CODIGO_ART_FACLIN, CODIGO_UNIDAD_FACLIN, ' +
    'CODIGO_FAM_FACLIN, TIPO_ARTICULO_FACLIN, ' +
    'TIPO_CANTIDAD_ARTICULO_FACLIN, CANTIDAD_FACLIN, ' +
    'DESCRIPCION_ARTICULO_FACLIN, ESIMP_INCL_TARIFA_FACLIN, ' +
    'PRECIO_VENTA_SIVA_ARTICULO_FACLIN, TIPO_IVA_ARTICULO_FACLIN, ' +
    'PORCENTAJE_IVA_FACLIN, PRECIO_VENTA_CIVA_ARTICULO_FACLIN, ' +
    'TOTAL_FACLIN, TOTAL_FAC_SIVA_FACLIN, INSTANTE_ALTA, ' +
    'INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF, CODIGO_ALM_FACLIN, ' +
    'CODIGO_CAJA_FACLIN, NUMERO_OPERACION_FACLIN, NUMERO_MOV_FACLIN) ' +
    'SELECT :NUMERO, :SERIE, :ORIGEN, ' +
    'LPAD((@linea_factura_ta := @linea_factura_ta + 1), 4, ''0''), ' +
    'M.CODIGO_ART_MOV, M.CODIGO_UNIDAD_MOV, A.CODIGO_FAM_ART, ' +
    'COALESCE(A.TIPO_ART, ''ESTANDAR''), ' +
    'COALESCE(A.TIPO_CANTIDAD_ART, ''Uds''), M.CANTIDAD_MOV, ' +
    'LEFT(COALESCE(M.DESCRIPCION_ARTICULO_MOV, A.DESCRIPCION_ART), ' +
    '100), ''N'', ' +
    'COALESCE(V.PRECIO_VALORADO_VTA, M.PRECIO_COSTE_UNITARIO_MOV, 0), ' +
    'COALESCE(A.TIPO_IVA_ART, ''N''), ' +
    'CASE COALESCE(A.TIPO_IVA_ART, ''N'') ' +
    ' WHEN ''R'' THEN I.PORCENTAJE_REDUCIDO_IVA ' +
    ' WHEN ''S'' THEN I.PORCENTAJE_SUPERREDUCIDO_IVA ' +
    ' WHEN ''E'' THEN I.PORCENTAJE_EXENTO_IVA ' +
    ' ELSE I.PORCENTAJE_NORMAL_IVA END, ' +
    'COALESCE(V.PRECIO_VALORADO_VTA, M.PRECIO_COSTE_UNITARIO_MOV, 0) ' +
    '* (1 + (CASE ' +
    'COALESCE(A.TIPO_IVA_ART, ''N'') ' +
    ' WHEN ''R'' THEN I.PORCENTAJE_REDUCIDO_IVA ' +
    ' WHEN ''S'' THEN I.PORCENTAJE_SUPERREDUCIDO_IVA ' +
    ' WHEN ''E'' THEN I.PORCENTAJE_EXENTO_IVA ' +
    ' ELSE I.PORCENTAJE_NORMAL_IVA END) / 100), ' +
    // Importes de linea a centimos, como la cabecera (ver TV).
    'ROUND(ROUND(CASE WHEN V.PRECIO_VALORADO_VTA IS NULL THEN ' +
    'COALESCE(M.TOTAL_COSTE_MOV, M.CANTIDAD_MOV * ' +
    'M.PRECIO_COSTE_UNITARIO_MOV, 0) ' +
    'ELSE M.CANTIDAD_MOV * V.PRECIO_VALORADO_VTA END, 2) * (1 + (CASE ' +
    'COALESCE(A.TIPO_IVA_ART, ''N'') ' +
    ' WHEN ''R'' THEN I.PORCENTAJE_REDUCIDO_IVA ' +
    ' WHEN ''S'' THEN I.PORCENTAJE_SUPERREDUCIDO_IVA ' +
    ' WHEN ''E'' THEN I.PORCENTAJE_EXENTO_IVA ' +
    ' ELSE I.PORCENTAJE_NORMAL_IVA END) / 100), 2), ' +
    'ROUND(CASE WHEN V.PRECIO_VALORADO_VTA IS NULL THEN ' +
    'COALESCE(M.TOTAL_COSTE_MOV, M.CANTIDAD_MOV * ' +
    'M.PRECIO_COSTE_UNITARIO_MOV, 0) ' +
    'ELSE M.CANTIDAD_MOV * V.PRECIO_VALORADO_VTA END, 2), NOW(), NOW(), ' +
    ':USUARIO, :USUARIO, ' +
    'O.CODIGO_ALM_OPCAJA, O.CODIGO_CAJA_OPCAJA, ' +
    'O.NUMERO_OPERACION_OPCAJA, M.NUMERO_MOV ' +
    'FROM fza_facturas_operaciones_caja X ' +
    'JOIN fza_caja_operaciones O ON O.ID_OPCAJA = X.ID_OPCAJA_FACOP ' +
    'JOIN fza_movimientos_almacen M ' +
    ' ON M.CODIGO_EMP_MOV = O.CODIGO_EMP_OPCAJA ' +
    ' AND M.CODIGO_ALM_DOC_MOV = O.CODIGO_ALM_OPCAJA ' +
    ' AND M.CODIGO_CAJA_DOC_MOV = O.CODIGO_CAJA_OPCAJA ' +
    ' AND M.NUMERO_OPERACION_DOC_MOV = O.NUMERO_OPERACION_OPCAJA ' +
    'LEFT JOIN fza_articulos A ON A.CODIGO_ART_ART = M.CODIGO_ART_MOV ' +
    'LEFT JOIN tmp_fza_valoracion_ta V ' +
    ' ON V.NUMERO_MOV_VTA = M.NUMERO_MOV ' +
    'JOIN fza_facturas F ON F.SERIE_FAC = :SERIE ' +
    ' AND F.NUMERO_FAC = :NUMERO ' +
    'JOIN fza_ivas I ON I.CODIGO_IVA = F.CODIGO_IVA_FAC ' +
    'WHERE X.SERIE_FAC_FACOP = :SERIE ' +
    ' AND X.NUMERO_FAC_FACOP = :NUMERO ' +
    ' AND O.CODIGO_EMP_OPCAJA = :ORIGEN ' +
    ' AND O.CODIGO_ALM_OPCAJA = :ALMACEN ' +
    ' AND O.CODIGO_EMP_CONTRA_OPCAJA = :EMPRESA_DESTINO ' +
    ' AND M.TIPO_DOC_MOV = ''TA'' AND M.TIPO_MOV = ''S'' ' +
    ' AND M.ESACTIVO_MOV = ''S'' ' +
    'ORDER BY COALESCE(O.FECHA_OP_DIA_OPCAJA, ' +
    'DATE(O.FECHA_OPERACION_OPCAJA)), O.ID_OPCAJA, M.LINEA_MOV';
  SQL_ENLAZAR_OPERACIONES_TA =
    'INSERT IGNORE INTO fza_facturas_operaciones_caja (' +
    'ID_FACPER_FACOP, ID_OPCAJA_FACOP, SERIE_FAC_FACOP, ' +
    'NUMERO_FAC_FACOP, ' +
    'CODIGO_EMP_ORIGEN_FACOP, CODIGO_EMP_DESTINO_FACOP, ' +
    'NUMERO_OPERACION_FACOP, FECHA_OPERACION_FACOP, ' +
    'IMPORTE_OPERACION_FACOP, ESTADO_FACOP, INSTANTE_ALTA, ' +
    'INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :ID_PERIODO, O.ID_OPCAJA, :SERIE, :NUMERO, ' +
    'O.CODIGO_EMP_OPCAJA, ' +
    'O.CODIGO_EMP_CONTRA_OPCAJA, O.NUMERO_OPERACION_OPCAJA, ' +
    'COALESCE(O.FECHA_OP_DIA_OPCAJA, DATE(O.FECHA_OPERACION_OPCAJA)), ' +
    'O.IMPORTE_TOTAL_OPCAJA, ''FACTURADA'', NOW(), NOW(), ' +
    ':USUARIO, :USUARIO FROM fza_caja_operaciones O ' +
    'WHERE O.TIPO_OPERACION_OPCAJA = ''TA'' ' +
    ' AND O.ESTRASPASO_OPCAJA = ''S'' ' +
    ' AND O.CODIGO_EMP_OPCAJA = :ORIGEN ' +
    ' AND O.CODIGO_ALM_OPCAJA = :ALMACEN ' +
    ' AND O.CODIGO_EMP_CONTRA_OPCAJA = :EMPRESA_DESTINO ' +
    ' AND COALESCE(O.FECHA_OP_DIA_OPCAJA, ' +
    ' DATE(O.FECHA_OPERACION_OPCAJA)) BETWEEN :DESDE AND :HASTA ' +
    ' AND NOT EXISTS (SELECT 1 FROM fza_facturas_operaciones_caja X ' +
    ' WHERE X.ID_OPCAJA_FACOP = O.ID_OPCAJA) ' +
    ' AND EXISTS (SELECT 1 FROM fza_movimientos_almacen M ' +
    ' WHERE M.TIPO_DOC_MOV = ''TA'' AND M.TIPO_MOV = ''S'' ' +
    ' AND M.ESACTIVO_MOV = ''S'' ' +
    ' AND M.CODIGO_EMP_MOV = O.CODIGO_EMP_OPCAJA ' +
    ' AND M.CODIGO_ALM_DOC_MOV = O.CODIGO_ALM_OPCAJA ' +
    ' AND M.CODIGO_CAJA_DOC_MOV = O.CODIGO_CAJA_OPCAJA ' +
    ' AND M.NUMERO_OPERACION_DOC_MOV = O.NUMERO_OPERACION_OPCAJA) ' +
    SQL_EXCLUIR_OPERACION_FACTURADA_TV;
  SQL_CLIENTE_TRASPASOS_DESTINO =
    'SELECT C.CODIGO_CLI_CLI FROM fza_empresas D ' +
    'JOIN fza_clientes C ON C.CODIGO_CLI_CLI = D.CODIGO_CLI_TRASPASOS_EMP ' +
    'WHERE D.CODIGO_EMP_EMP = :EMPRESA_DESTINO';
  SQL_CONTAR_OPERACIONES_FACTURA =
    'SELECT COUNT(*) AS CANTIDAD FROM fza_facturas_operaciones_caja ' +
    'WHERE SERIE_FAC_FACOP = :SERIE AND NUMERO_FAC_FACOP = :NUMERO';
  SQL_ACTUALIZAR_CONTADOR_LINEAS_FACTURA =
    'UPDATE fza_facturas SET CONTADOR_LINEAS_FAC = LPAD(:LINEAS, 4, ''0'') ' +
    'WHERE SERIE_FAC = :SERIE AND NUMERO_FAC = :NUMERO';

  // --- Traspasado y vendido (TV) ------------------------------------------
  // Traspasos TA que pueden cubrir ventas del periodo: sin fecha inicial,
  // porque lo vendido ahora consume traspasos por antiguos que sean.
  SQL_ORIGEN_TRASPASOS_VENDIBLES =
    'FROM fza_caja_operaciones O ' +
    'JOIN fza_movimientos_almacen M ' +
    ' ON M.CODIGO_EMP_MOV = O.CODIGO_EMP_OPCAJA ' +
    ' AND M.CODIGO_ALM_DOC_MOV = O.CODIGO_ALM_OPCAJA ' +
    ' AND M.CODIGO_CAJA_DOC_MOV = O.CODIGO_CAJA_OPCAJA ' +
    ' AND M.NUMERO_OPERACION_DOC_MOV = O.NUMERO_OPERACION_OPCAJA ' +
    'LEFT JOIN fza_articulos A ON A.CODIGO_ART_ART = M.CODIGO_ART_MOV ';
  SQL_FILTRO_TRASPASOS_VENDIBLES =
    'WHERE O.TIPO_OPERACION_OPCAJA = ''TA'' ' +
    ' AND O.ESTRASPASO_OPCAJA = ''S'' ' +
    // FZ-ISSUE-357: con AJENAS = 'S', los de las otras emisoras al mismo
    // destino (no los de la propia destino entre sus almacenes).
    ' AND ((:AJENAS = ''N'' AND O.CODIGO_EMP_OPCAJA = :EMPRESA_ORIGEN) ' +
    '  OR (:AJENAS = ''S'' AND O.CODIGO_EMP_OPCAJA <> :EMPRESA_ORIGEN ' +
    '  AND O.CODIGO_EMP_OPCAJA <> :EMPRESA_DESTINO)) ' +
    ' AND O.CODIGO_EMP_CONTRA_OPCAJA = :EMPRESA_DESTINO ' +
    ' AND COALESCE(O.FECHA_OP_DIA_OPCAJA, ' +
    ' DATE(O.FECHA_OPERACION_OPCAJA)) <= :HASTA ' +
    ' AND M.TIPO_DOC_MOV = ''TA'' AND M.TIPO_MOV = ''S'' ' +
    ' AND M.ESACTIVO_MOV = ''S'' ' +
    ' AND NOT EXISTS (SELECT 1 FROM fza_facturas_operaciones_caja X ' +
    ' WHERE X.ID_OPCAJA_FACOP = O.ID_OPCAJA) ';
  SQL_TRASPASOS_VENDIBLES =
    'SELECT M.NUMERO_MOV, O.ID_OPCAJA, O.NUMERO_OPERACION_OPCAJA, ' +
    'M.LINEA_MOV, COALESCE(O.FECHA_OP_DIA_OPCAJA, ' +
    'DATE(O.FECHA_OPERACION_OPCAJA)) AS FECHA_OPERACION, ' +
    'O.CODIGO_ALM_OPCAJA AS ALMACEN_ORIGEN, ' +
    'COALESCE(NULLIF(M.CODIGO_ALM_CONTRA_MOV, ''''), ' +
    'O.CODIGO_ALM_CONTRA_OPCAJA, '''') AS ALMACEN_DESTINO, ' +
    'M.CODIGO_ART_MOV, M.CODIGO_UNIDAD_MOV, ' +
    'LEFT(COALESCE(M.DESCRIPCION_ARTICULO_MOV, A.DESCRIPCION_ART, ''''), ' +
    '100) AS DESCRIPCION, M.CANTIDAD_MOV, ' +
    'COALESCE((SELECT SUM(V.CANTIDAD_FACTV) ' +
    ' FROM fza_facturas_traspasos_vendidos V ' +
    ' WHERE V.NUMERO_MOV_TA_FACTV = M.NUMERO_MOV), 0) ' +
    'AS CANTIDAD_FACTURADA, ' +
    'COALESCE(M.PRECIO_COSTE_UNITARIO_MOV, 0) AS COSTE_MOVIMIENTO, ' +
    SQL_PRECIOS_REFERENCIA_TRASPASO +
    ', COALESCE((SELECT SUM(L.TOTAL_FAC_SIVA_FACLIN) / ' +
    ' NULLIF(SUM(L.CANTIDAD_FACLIN), 0) ' +
    ' FROM fza_movimientos_almacen VM ' +
    ' JOIN fza_facturas_lineas L ON L.NUMERO_MOV_FACLIN = VM.NUMERO_MOV ' +
    ' WHERE VM.TIPO_DOC_MOV = ''VE'' AND VM.TIPO_MOV = ''S'' ' +
    ' AND VM.ESACTIVO_MOV = ''S'' ' +
    ' AND VM.CODIGO_ALM_MOV = COALESCE(' +
    ' NULLIF(M.CODIGO_ALM_CONTRA_MOV, ''''), ' +
    ' O.CODIGO_ALM_CONTRA_OPCAJA) ' +
    ' AND VM.CODIGO_UNIDAD_MOV = M.CODIGO_UNIDAD_MOV ' +
    ' AND DATE(VM.FECHA_MOV) BETWEEN :DESDE AND :HASTA), 0) ' +
    'AS PRECIO_VENTA_DESTINO ' +
    SQL_ORIGEN_TRASPASOS_VENDIBLES +
    SQL_FILTRO_TRASPASOS_VENDIBLES +
    'ORDER BY COALESCE(O.FECHA_OP_DIA_OPCAJA, ' +
    'DATE(O.FECHA_OPERACION_OPCAJA)), O.ID_OPCAJA, M.LINEA_MOV';
  // Factura o ticket de un movimiento VE (alias M), como 'SERIE/NUMERO'.
  SQL_DOCUMENTO_MOVIMIENTO_VENTA =
    'CONCAT(COALESCE(M.SERIE_DOC_MOV, ''''), ''/'', ' +
    'COALESCE(M.NUMERO_DOC_MOV, ''''))';
  // Documento que rectifica la devolución VE/E de alias M: el origen que
  // anota la operación de caja y, si no, la factura que la señala como su
  // rectificativa. Vacío si no consta.
  SQL_DOCUMENTO_ORIGEN_DEVOLUCION =
    'COALESCE((SELECT CONCAT(OD.SERIE_REF_ORIGEN_OPCAJA, ''/'', ' +
    ' OD.NUMERO_REF_ORIGEN_OPCAJA) FROM fza_caja_operaciones OD ' +
    ' WHERE OD.CODIGO_EMP_OPCAJA = M.CODIGO_EMP_MOV ' +
    ' AND OD.CODIGO_ALM_OPCAJA = M.CODIGO_ALM_DOC_MOV ' +
    ' AND OD.CODIGO_CAJA_OPCAJA = M.CODIGO_CAJA_DOC_MOV ' +
    ' AND OD.NUMERO_OPERACION_OPCAJA = M.NUMERO_OPERACION_DOC_MOV ' +
    ' AND OD.SERIE_REF_ORIGEN_OPCAJA <> '''' ' +
    ' AND OD.NUMERO_REF_ORIGEN_OPCAJA <> '''' LIMIT 1), ' +
    '(SELECT CONCAT(FO.SERIE_FAC, ''/'', FO.NUMERO_FAC) ' +
    ' FROM fza_facturas FO ' +
    ' WHERE FO.SERIE_FAC_ABONO_FAC = M.SERIE_DOC_MOV ' +
    ' AND FO.NUMERO_FAC_ABONO_FAC = M.NUMERO_DOC_MOV ' +
    ' AND FO.CODIGO_EMP_FAC = M.CODIGO_EMP_MOV LIMIT 1), '''')';
  // Ventas y devoluciones de la tienda destino dentro del periodo, sólo de
  // SKU que alguna vez le llegaron por traspaso desde la empresa emisora.
  SQL_VENTAS_DESTINO =
    'SELECT M.NUMERO_MOV, M.FECHA_MOV, M.CODIGO_ALM_MOV, ' +
    'M.CODIGO_UNIDAD_MOV, M.CANTIDAD_MOV, M.TIPO_MOV, ' +
    SQL_DOCUMENTO_MOVIMIENTO_VENTA + ' AS DOCUMENTO, ' +
    'CASE WHEN M.TIPO_MOV = ''E'' THEN ' +
    SQL_DOCUMENTO_ORIGEN_DEVOLUCION + ' ELSE '''' END ' +
    'AS DOCUMENTO_ORIGEN, ' +
    'COALESCE((SELECT SUM(ABS(V.CANTIDAD_FACTV)) ' +
    ' FROM fza_facturas_traspasos_vendidos V ' +
    ' WHERE V.NUMERO_MOV_VE_FACTV = M.NUMERO_MOV), 0) ' +
    'AS CANTIDAD_ASIGNADA, ' +
    'COALESCE((SELECT L.TOTAL_FAC_SIVA_FACLIN / ' +
    ' NULLIF(L.CANTIDAD_FACLIN, 0) FROM fza_facturas_lineas L ' +
    ' WHERE L.NUMERO_MOV_FACLIN = M.NUMERO_MOV LIMIT 1), 0) ' +
    'AS PRECIO_VENTA, ' +
    // FZ-ISSUE-367: sin línea, el 0 de PRECIO_VENTA es «desconocido».
    'CASE WHEN EXISTS (SELECT 1 FROM fza_facturas_lineas L2 ' +
    ' WHERE L2.NUMERO_MOV_FACLIN = M.NUMERO_MOV) ' +
    ' THEN ''N'' ELSE ''S'' END AS SIN_LINEA_FACTURA ' +
    'FROM fza_movimientos_almacen M ' +
    'JOIN fza_almacenes AL ON AL.CODIGO_ALM_ALM = M.CODIGO_ALM_MOV ' +
    ' AND AL.CODIGO_EMP_ALM = :EMPRESA_DESTINO ' +
    'WHERE M.TIPO_DOC_MOV = ''VE'' AND M.ESACTIVO_MOV = ''S'' ' +
    ' AND DATE(M.FECHA_MOV) BETWEEN :DESDE AND :HASTA ' +
    ' AND M.CANTIDAD_MOV > 0 ' +
    ' AND EXISTS (SELECT 1 FROM fza_movimientos_almacen T ' +
    ' WHERE T.TIPO_DOC_MOV = ''TA'' AND T.TIPO_MOV = ''S'' ' +
    ' AND T.ESACTIVO_MOV = ''S'' ' +
    ' AND T.CODIGO_EMP_MOV = :EMPRESA_ORIGEN ' +
    ' AND T.CODIGO_ALM_CONTRA_MOV = M.CODIGO_ALM_MOV ' +
    ' AND T.CODIGO_UNIDAD_MOV = M.CODIGO_UNIDAD_MOV) ' +
    'ORDER BY M.FECHA_MOV, M.NUMERO_MOV';
  // Lo ya facturado por traspaso, precio y venta: es lo que una devolución
  // puede deshacer, y al precio al que se cobró. Cada devolución cuenta
  // contra la venta que rectifica; las que no dicen cuál quedan con
  // documento vacío y en negativo, y sólo restan del neto de la línea.
  SQL_FACTURACIONES_TRASPASO_PREVIAS =
    'SELECT V.NUMERO_MOV_TA_FACTV, ' +
    'MIN(V.ID_OPCAJA_TA_FACTV) AS ID_OPCAJA, ' +
    'V.CODIGO_ALM_ORIGEN_FACTV, V.CODIGO_ALM_DESTINO_FACTV, ' +
    'MAX(V.CODIGO_ART_FACTV) AS CODIGO_ART, V.CODIGO_UNIDAD_FACTV, ' +
    'LEFT(COALESCE(MAX(MT.DESCRIPCION_ARTICULO_MOV), ' +
    'MAX(A.DESCRIPCION_ART), ''''), 100) AS DESCRIPCION, ' +
    'V.PRECIO_FACTV, SUM(V.CANTIDAD_FACTV) AS CANTIDAD, ' +
    'MAX(V.FECHA_VENTA_FACTV) AS FECHA_VENTA, ' +
    'MIN(V.FECHA_TRASPASO_FACTV) AS FECHA_TRASPASO, ' +
    'V.DOCUMENTO_VENTA ' +
    'FROM (SELECT F.NUMERO_MOV_TA_FACTV, F.ID_OPCAJA_TA_FACTV, ' +
    ' F.CODIGO_ALM_ORIGEN_FACTV, F.CODIGO_ALM_DESTINO_FACTV, ' +
    ' F.CODIGO_ART_FACTV, F.CODIGO_UNIDAD_FACTV, F.PRECIO_FACTV, ' +
    ' F.CANTIDAD_FACTV, F.FECHA_VENTA_FACTV, F.FECHA_TRASPASO_FACTV, ' +
    ' CASE WHEN F.TIPO_FACTV = ''DEVOLUCION'' THEN ' +
    SQL_DOCUMENTO_ORIGEN_DEVOLUCION + ' ELSE ' +
    SQL_DOCUMENTO_MOVIMIENTO_VENTA + ' END AS DOCUMENTO_VENTA ' +
    ' FROM fza_facturas_traspasos_vendidos F ' +
    ' LEFT JOIN fza_movimientos_almacen M ' +
    '  ON M.NUMERO_MOV = F.NUMERO_MOV_VE_FACTV ' +
    ' WHERE ((:AJENAS = ''N'' ' +
    '   AND F.CODIGO_EMP_ORIGEN_FACTV = :EMPRESA_ORIGEN) ' +
    '  OR (:AJENAS = ''S'' ' +
    '   AND F.CODIGO_EMP_ORIGEN_FACTV <> :EMPRESA_ORIGEN)) ' +
    ' AND F.CODIGO_EMP_DESTINO_FACTV = :EMPRESA_DESTINO) V ' +
    'LEFT JOIN fza_movimientos_almacen MT ' +
    ' ON MT.NUMERO_MOV = V.NUMERO_MOV_TA_FACTV ' +
    'LEFT JOIN fza_articulos A ' +
    ' ON A.CODIGO_ART_ART = V.CODIGO_ART_FACTV ' +
    'GROUP BY V.NUMERO_MOV_TA_FACTV, V.CODIGO_ALM_ORIGEN_FACTV, ' +
    ' V.CODIGO_ALM_DESTINO_FACTV, V.CODIGO_UNIDAD_FACTV, V.PRECIO_FACTV, ' +
    ' V.DOCUMENTO_VENTA ' +
    'HAVING SUM(V.CANTIDAD_FACTV) <> 0 ' +
    'ORDER BY MAX(V.FECHA_VENTA_FACTV), V.NUMERO_MOV_TA_FACTV';
  SQL_INSERTAR_TRASPASO_VENDIDO =
    'INSERT INTO fza_facturas_traspasos_vendidos (' +
    'ID_FACPER_FACTV, SERIE_FAC_FACTV, NUMERO_FAC_FACTV, ' +
    'NUMERO_MOV_TA_FACTV, NUMERO_MOV_VE_FACTV, ID_OPCAJA_TA_FACTV, ' +
    'TIPO_FACTV, CODIGO_EMP_ORIGEN_FACTV, CODIGO_EMP_DESTINO_FACTV, ' +
    'CODIGO_ALM_ORIGEN_FACTV, CODIGO_ALM_DESTINO_FACTV, ' +
    'CODIGO_ART_FACTV, CODIGO_UNIDAD_FACTV, CANTIDAD_FACTV, ' +
    'PRECIO_FACTV, FECHA_VENTA_FACTV, FECHA_TRASPASO_FACTV, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:ID_PERIODO, :SERIE, :NUMERO, :NUMERO_MOV_TA, ' +
    ':NUMERO_MOV_VE, :ID_OPCAJA, :TIPO, :EMPRESA_ORIGEN, ' +
    ':EMPRESA_DESTINO, :ALMACEN_ORIGEN, :ALMACEN_DESTINO, ' +
    ':ARTICULO, :UNIDAD, :CANTIDAD, :PRECIO, :FECHA_VENTA, ' +
    ':FECHA_TRASPASO, NOW(), NOW(), :USUARIO, :USUARIO)';
  // Una línea de factura por traspaso y precio; lo vendido y devuelto en la
  // misma pasada se compensa y no llega a imprimirse.
  SQL_LINEAS_TRASPASO_VENDIDO_FACTURA =
    'SELECT V.NUMERO_MOV_TA_FACTV AS NUMERO_MOV, ' +
    ' V.PRECIO_FACTV AS PRECIO, SUM(V.CANTIDAD_FACTV) AS CANTIDAD ' +
    ' FROM fza_facturas_traspasos_vendidos V ' +
    ' WHERE V.SERIE_FAC_FACTV = :SERIE ' +
    ' AND V.NUMERO_FAC_FACTV = :NUMERO ' +
    ' GROUP BY V.NUMERO_MOV_TA_FACTV, V.PRECIO_FACTV ' +
    ' HAVING SUM(V.CANTIDAD_FACTV) <> 0';
  SQL_CONTAR_LINEAS_FACTURA_TV =
    'SELECT COUNT(*) AS CANTIDAD FROM (' +
    SQL_LINEAS_TRASPASO_VENDIDO_FACTURA + ') X';
  SQL_INICIAR_LINEA_FACTURA_TV = 'SET @linea_factura_tv := 0';
  SQL_PORCENTAJE_IVA_ARTICULO =
    'CASE COALESCE(A.TIPO_IVA_ART, ''N'') ' +
    ' WHEN ''R'' THEN I.PORCENTAJE_REDUCIDO_IVA ' +
    ' WHEN ''S'' THEN I.PORCENTAJE_SUPERREDUCIDO_IVA ' +
    ' WHEN ''E'' THEN I.PORCENTAJE_EXENTO_IVA ' +
    ' ELSE I.PORCENTAJE_NORMAL_IVA END';
  SQL_INSERTAR_LINEAS_TV =
    'INSERT INTO fza_facturas_lineas (' +
    'NUMERO_FAC_FACLIN, SERIE_FAC_FACLIN, CODIGO_EMP_FACLIN, ' +
    'LINEA_FACLIN, CODIGO_ART_FACLIN, CODIGO_UNIDAD_FACLIN, ' +
    'CODIGO_FAM_FACLIN, TIPO_ARTICULO_FACLIN, ' +
    'TIPO_CANTIDAD_ARTICULO_FACLIN, CANTIDAD_FACLIN, ' +
    'DESCRIPCION_ARTICULO_FACLIN, ESIMP_INCL_TARIFA_FACLIN, ' +
    'PRECIO_VENTA_SIVA_ARTICULO_FACLIN, TIPO_IVA_ARTICULO_FACLIN, ' +
    'PORCENTAJE_IVA_FACLIN, PRECIO_VENTA_CIVA_ARTICULO_FACLIN, ' +
    'TOTAL_FACLIN, TOTAL_FAC_SIVA_FACLIN, INSTANTE_ALTA, ' +
    'INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF, CODIGO_ALM_FACLIN, ' +
    'CODIGO_CAJA_FACLIN, NUMERO_OPERACION_FACLIN, NUMERO_MOV_FACLIN) ' +
    'SELECT :NUMERO, :SERIE, :ORIGEN, ' +
    'LPAD((@linea_factura_tv := @linea_factura_tv + 1), 4, ''0''), ' +
    'M.CODIGO_ART_MOV, M.CODIGO_UNIDAD_MOV, A.CODIGO_FAM_ART, ' +
    'COALESCE(A.TIPO_ART, ''ESTANDAR''), ' +
    'COALESCE(A.TIPO_CANTIDAD_ART, ''Uds''), T.CANTIDAD, ' +
    'LEFT(CASE WHEN T.CANTIDAD < 0 THEN CONCAT(:PREFIJO_DEVOLUCION, ' +
    'COALESCE(M.DESCRIPCION_ARTICULO_MOV, A.DESCRIPCION_ART, '''')) ' +
    'ELSE COALESCE(M.DESCRIPCION_ARTICULO_MOV, A.DESCRIPCION_ART, '''') ' +
    'END, 100), ''N'', T.PRECIO, COALESCE(A.TIPO_IVA_ART, ''N''), ' +
    SQL_PORCENTAJE_IVA_ARTICULO + ', ' +
    'T.PRECIO * (1 + (' + SQL_PORCENTAJE_IVA_ARTICULO + ') / 100), ' +
    // El precio valorado conserva 4 decimales; los importes de la linea
    // van a centimos, como la cabecera, para que las lineas sumen igual.
    'ROUND(ROUND(T.CANTIDAD * T.PRECIO, 2) * ' +
    '(1 + (' + SQL_PORCENTAJE_IVA_ARTICULO + ') / 100), 2), ' +
    'ROUND(T.CANTIDAD * T.PRECIO, 2), NOW(), NOW(), :USUARIO, :USUARIO, ' +
    'O.CODIGO_ALM_OPCAJA, O.CODIGO_CAJA_OPCAJA, ' +
    'O.NUMERO_OPERACION_OPCAJA, M.NUMERO_MOV ' +
    'FROM (' + SQL_LINEAS_TRASPASO_VENDIDO_FACTURA + ') T ' +
    'JOIN fza_movimientos_almacen M ON M.NUMERO_MOV = T.NUMERO_MOV ' +
    'JOIN fza_caja_operaciones O ' +
    ' ON O.CODIGO_EMP_OPCAJA = M.CODIGO_EMP_MOV ' +
    ' AND O.CODIGO_ALM_OPCAJA = M.CODIGO_ALM_DOC_MOV ' +
    ' AND O.CODIGO_CAJA_OPCAJA = M.CODIGO_CAJA_DOC_MOV ' +
    ' AND O.NUMERO_OPERACION_OPCAJA = M.NUMERO_OPERACION_DOC_MOV ' +
    ' AND O.TIPO_OPERACION_OPCAJA = ''TA'' ' +
    'LEFT JOIN fza_articulos A ON A.CODIGO_ART_ART = M.CODIGO_ART_MOV ' +
    'JOIN fza_facturas F ON F.SERIE_FAC = :SERIE ' +
    ' AND F.NUMERO_FAC = :NUMERO ' +
    'JOIN fza_ivas I ON I.CODIGO_IVA = F.CODIGO_IVA_FAC ' +
    'ORDER BY M.FECHA_MOV, M.NUMERO_MOV, T.PRECIO';

type
  TGrupoTraspaso = record
    Empresa: string;
    Almacen: string;
  end;

function FechaFacturaSolicitud(
  const ASolicitud: TSolicitudFacturacionCaja): TDateTime;
begin
  Result := ASolicitud.FechaFactura;
  if Result <= 0 then
    Result := ASolicitud.FechaHasta;
end;

function FormaPagoSolicitud(
  const ASolicitud: TSolicitudFacturacionCaja): string;
begin
  Result := Trim(ASolicitud.FormaPago);
  if Result = '' then
    Result := FORMA_PAGO_FACTURA_CAJA;
end;

function EsNumeroSinSigno(const ATexto: string): Boolean;
var
  cCaracter: Char;
begin
  Result := ATexto <> '';
  for cCaracter in ATexto do
  begin
    if not CharInSet(cCaracter, ['0'..'9']) then
      Result := False;
  end;
end;

// Emite la empresa con saldo a favor; la otra recibe la factura.
function PrepararSolicitudVales(
  const ADatos: TDatosPropuestaVales;
  const AUsuario: string): TSolicitudFacturacionCaja;
begin
  if ADatos.Cantidad = 0 then
    raise Exception.Create(SErrorProformaValesNoDisponible);
  if ADatos.Cantidad > 9999 then
    raise Exception.Create(SErrorFacturaValesDemasiadasLineas);
  if ADatos.Saldo = 0 then
    raise Exception.Create(SErrorProformaValesSinSaldo);
  Result := Default(TSolicitudFacturacionCaja);
  Result.FechaDesde := Date;
  Result.FechaHasta := Date;
  Result.Usuario := AUsuario;
  if ADatos.Saldo < 0 then
  begin
    Result.CodigoEmpresaOrigen := ADatos.EmpresaB;
    Result.CodigoEmpresaDestino := ADatos.EmpresaA;
  end
  else
  begin
    Result.CodigoEmpresaOrigen := ADatos.EmpresaA;
    Result.CodigoEmpresaDestino := ADatos.EmpresaB;
  end;
end;

function LeerPropuestaVales(
  AConexion: TUniConnection;
  AIdProforma: Int64): TDatosPropuestaVales;
var
  oConsulta: TUniQuery;
begin
  Result := Default(TDatosPropuestaVales);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := SQL_BLOQUEAR_PROFORMA_VALES;
    oConsulta.ParamByName('ID').AsLargeInt := AIdProforma;
    oConsulta.Open;
    if oConsulta.IsEmpty then
      raise Exception.Create(SErrorProformaValesNoDisponible);
    Result.EmpresaA := oConsulta.FieldByName(
      'CODIGO_EMP_PROCAJ').AsString;
    Result.EmpresaB := oConsulta.FieldByName(
      'CODIGO_EMP_DESTINO_FACPER').AsString;
    Result.Serie := oConsulta.FieldByName('SERIE_PROCAJ').AsString;
    Result.Numero := oConsulta.FieldByName('NUMERO_PROCAJ').AsString;
    Result.Cantidad := oConsulta.FieldByName('CANTIDAD').AsInteger;
    Result.Saldo := oConsulta.FieldByName('TOTAL_PROCAJ').AsCurrency;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function LeerLineasVales(
  AConexion: TUniConnection;
  AIdProforma: Int64;
  ACantidad: Integer): TArray<TLineaValeFactura>;
var
  iLinea: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, ACantidad);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := SQL_LEER_VALES_PROPUESTA;
    oConsulta.ParamByName('ID').AsLargeInt := AIdProforma;
    oConsulta.Open;
    iLinea := 0;
    while not oConsulta.Eof do
    begin
      if iLinea >= ACantidad then
        raise Exception.Create(SErrorFacturaValesLineas);
      Result[iLinea].Codigo := oConsulta.FieldByName(
        'CODIGO_VL_PROCVL').AsString;
      Result[iLinea].Importe := oConsulta.FieldByName(
        'IMPORTE_COMPENSACION_PROCVL').AsCurrency;
      Inc(iLinea);
      oConsulta.Next;
    end;
    if iLinea <> ACantidad then
      raise Exception.Create(SErrorFacturaValesLineas);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure InsertarLineasFacturaVales(
  AConexion: TUniConnection;
  const ALineas: TArray<TLineaValeFactura>;
  const AEmisor, ASerie, ANumero, AUsuario: string;
  AInvertir: Boolean);
var
  iLinea: Integer;
  oConsulta: TUniQuery;
  vImporte: Currency;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := SQL_INSERTAR_LINEA_FACTURA_VALES;
    for iLinea := 0 to High(ALineas) do
    begin
      vImporte := ALineas[iLinea].Importe;
      if AInvertir then
        vImporte := -vImporte;
      oConsulta.ParamByName('NUMERO').AsString := ANumero;
      oConsulta.ParamByName('SERIE').AsString := ASerie;
      oConsulta.ParamByName('EMISOR').AsString := AEmisor;
      oConsulta.ParamByName('LINEA').AsString :=
        Format('%.4d', [iLinea + 1]);
      oConsulta.ParamByName('DESCRIPCION').AsString := Copy(
        'Compensación vale ' + ALineas[iLinea].Codigo, 1, 100);
      oConsulta.ParamByName('IMPORTE').AsCurrency := vImporte;
      oConsulta.ParamByName('USUARIO').AsString := AUsuario;
      oConsulta.Execute;
      if oConsulta.RowsAffected <> 1 then
        raise Exception.Create(SErrorFacturaValesLineas);
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

constructor TRepositorioFacturasProformaUniDAC.Create(
  AConexion: TUniConnection;
  const AParametrosApp: IParametrosAplicacion);
begin
  inherited Create;
  if not Assigned(AConexion) then
  begin
    raise EArgumentNilException.Create('AConexion');
  end;
  if not Assigned(AParametrosApp) then
  begin
    raise EArgumentNilException.Create('AParametrosApp');
  end;
  FConexion := AConexion;
  FParametrosApp := AParametrosApp;
end;

destructor TRepositorioFacturasProformaUniDAC.Destroy;
begin
  FParametrosApp := nil;
  inherited;
end;

procedure TRepositorioFacturasProformaUniDAC.ActualizarPeriodo(
  AIdPeriodo: Int64;
  const AEstado: string;
  const AResultado: TResultadoFacturacionCaja;
  const AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_ACTUALIZAR_PERIODO;
    oConsulta.ParamByName('ID_PERIODO').AsLargeInt := AIdPeriodo;
    oConsulta.ParamByName('ESTADO').AsString := AEstado;
    oConsulta.ParamByName('DOCUMENTOS').AsInteger :=
      AResultado.CantidadDocumentos;
    oConsulta.ParamByName('OPERACIONES').AsInteger :=
      AResultado.CantidadOperaciones;
    oConsulta.ParamByName('AJUSTES').AsInteger :=
      AResultado.CantidadAjustes;
    oConsulta.ParamByName('USUARIO').AsString := AUsuario;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioFacturasProformaUniDAC.AsignarSolicitud(
  AConsulta: TUniQuery;
  const ASolicitud: TSolicitudFacturacionCaja);
begin
  if AConsulta.Params.FindParam('DESDE') <> nil then
  begin
    AConsulta.ParamByName('DESDE').AsDate := Trunc(ASolicitud.FechaDesde);
  end;
  if AConsulta.Params.FindParam('HASTA') <> nil then
  begin
    AConsulta.ParamByName('HASTA').AsDate := Trunc(ASolicitud.FechaHasta);
  end;
  if AConsulta.Params.FindParam('EMPRESA_ORIGEN') <> nil then
  begin
    AConsulta.ParamByName('EMPRESA_ORIGEN').AsString :=
      ASolicitud.CodigoEmpresaOrigen;
  end;
  if AConsulta.Params.FindParam('EMPRESA_DESTINO') <> nil then
  begin
    AConsulta.ParamByName('EMPRESA_DESTINO').AsString :=
      ASolicitud.CodigoEmpresaDestino;
  end;
  if AConsulta.Params.FindParam('USUARIO') <> nil then
  begin
    AConsulta.ParamByName('USUARIO').AsString := ASolicitud.Usuario;
  end;
  if AConsulta.Params.FindParam('FECHA_FACTURA') <> nil then
  begin
    AConsulta.ParamByName('FECHA_FACTURA').AsDate :=
      Trunc(FechaFacturaSolicitud(ASolicitud));
  end;
  if AConsulta.Params.FindParam('FORMA_PAGO') <> nil then
  begin
    AConsulta.ParamByName('FORMA_PAGO').AsString :=
      FormaPagoSolicitud(ASolicitud);
  end;
end;

function TRepositorioFacturasProformaUniDAC.ContarCandidatasVenta(
  const ASolicitud: TSolicitudFacturacionCaja): Integer;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_CONTAR_CANDIDATAS_VENTA;
    AsignarSolicitud(oConsulta, ASolicitud);
    oConsulta.Open;
    Result := oConsulta.FieldByName('CANTIDAD').AsInteger;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioFacturasProformaUniDAC.ContarValesRecogidos(
  const ASolicitud: TSolicitudFacturacionCaja;
  out ASaldo: Currency): Integer;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_CONTAR_VALES_RECOGIDOS;
    AsignarSolicitud(oConsulta, ASolicitud);
    oConsulta.Open;
    Result := oConsulta.FieldByName('CANTIDAD').AsInteger;
    ASaldo := oConsulta.FieldByName('SALDO').AsCurrency;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioFacturasProformaUniDAC.CrearPeriodo(
  const AModalidad: string;
  const ASolicitud: TSolicitudFacturacionCaja): Int64;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_INSERTAR_PERIODO;
    AsignarSolicitud(oConsulta, ASolicitud);
    oConsulta.ParamByName('MODALIDAD').AsString := AModalidad;
    oConsulta.Execute;
    Result := ObtenerIdentidad;
  finally
    FreeAndNil(oConsulta);
  end;
end;

// FZ-ISSUE-368: cada almacén de origen se factura en su propia transacción.
// Si uno falla cuando otros ya tienen factura, el periodo queda PARCIAL y
// se devuelven las facturas creadas con el error; volver a generar el
// periodo completa lo que falta (es idempotente por movimiento).
procedure TRepositorioFacturasProformaUniDAC.CerrarPeriodoParcial(
  AIdPeriodo: Int64;
  const AAlmacen: string;
  const AError: string;
  var AResultado: TResultadoFacturacionCaja;
  const AUsuario: string);
var
  sAlmacen: string;
begin
  sAlmacen := '';
  if Trim(AAlmacen) <> '' then
    sAlmacen := Format(SAlmacenGeneracionParcialFacturacionCaja,
      [AAlmacen]);
  AResultado.Descripcion := Format(SAvisoGeneracionParcialFacturacionCaja,
    [AResultado.CantidadDocumentos, sAlmacen, AError]);
  ActualizarPeriodo(
    AIdPeriodo,
    'PARCIAL',
    AResultado,
    AUsuario);
end;

procedure TRepositorioFacturasProformaUniDAC.DescartarPeriodoSinDocumentos(
  AIdPeriodo: Int64;
  const AResultado: TResultadoFacturacionCaja;
  const AUsuario: string);
var
  iBorrados: Integer;
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_BORRAR_PERIODO_SIN_DOCUMENTOS;
    oConsulta.ParamByName('ID_PERIODO').AsLargeInt := AIdPeriodo;
    oConsulta.Execute;
    iBorrados := oConsulta.RowsAffected;
  finally
    FreeAndNil(oConsulta);
  end;
  if iBorrados = 0 then
  begin
    ActualizarPeriodo(
      AIdPeriodo,
      'SIN_DOCUMENTOS',
      AResultado,
      AUsuario);
  end;
end;

function TRepositorioFacturasProformaUniDAC.RevisarPeriodo(
  AModalidad: TModalidadFacturacionCaja;
  const ASolicitud: TSolicitudFacturacionCaja
): TRevisionPeriodoFacturacionCaja;
var
  sModalidad: string;
  iDuplicados: Integer;
  iSolapados: Integer;
  oConsulta: TUniQuery;
begin
  Result := Default(TRevisionPeriodoFacturacionCaja);
  case AModalidad of
    mfcVenta:
      sModalidad := 'VE';
    mfcTraspasoVendido:
      sModalidad := 'TV';
    mfcValesRecogidos:
      sModalidad := 'VR';
  else
    sModalidad := 'TA';
  end;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_REVISAR_PERIODO;
    AsignarSolicitud(oConsulta, ASolicitud);
    oConsulta.ParamByName('MODALIDAD').AsString := sModalidad;
    oConsulta.Open;
    iDuplicados := oConsulta.FieldByName('DUPLICADOS').AsInteger;
    iSolapados := oConsulta.FieldByName('SOLAPADOS').AsInteger;
  finally
    FreeAndNil(oConsulta);
  end;
  Result.EsDuplicado := iDuplicados > 0;
  Result.EsSolapado := iSolapados > iDuplicados;
  if Result.EsDuplicado then
  begin
    Result.Descripcion := SErrorGeneracionProformaDuplicada;
  end
  else if Result.EsSolapado then
  begin
    Result.Descripcion := SErrorPeriodoGeneracionProformaSolapado;
  end;
end;

function TRepositorioFacturasProformaUniDAC.ContarLineasTraspaso(
  const ASolicitud: TSolicitudFacturacionCaja;
  const AEmpresaOrigen: string;
  const AAlmacenOrigen: string): Integer;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_CONTAR_LINEAS_TRASPASO;
    AsignarSolicitud(oConsulta, ASolicitud);
    oConsulta.ParamByName('ORIGEN').AsString := AEmpresaOrigen;
    oConsulta.ParamByName('ALMACEN').AsString := AAlmacenOrigen;
    oConsulta.Open;
    Result := oConsulta.FieldByName('CANTIDAD').AsInteger;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioFacturasProformaUniDAC.ContarLineasFacturaTraspaso(
  const ASerie: string;
  const ANumero: string): Integer;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_CONTAR_LINEAS_FACTURA_TA;
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.Open;
    Result := oConsulta.FieldByName('CANTIDAD').AsInteger;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioFacturasProformaUniDAC.ObtenerIdentidad: Int64;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := 'SELECT LAST_INSERT_ID() AS ID';
    oConsulta.Open;
    Result := oConsulta.FieldByName('ID').AsLargeInt;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioFacturasProformaUniDAC.ObtenerNumeroDocumento(
  const ASerie: string;
  const ATipoDocumento: string;
  const AEmpresa: string;
  const AUsuario: string): string;
var
  oConsulta: TUniQuery;
  oProcedimiento: TUniStoredProc;
  sEmpresa: string;
begin
  if not FConexion.InTransaction then
    raise Exception.Create(
      'La numeración del documento requiere una transacción activa.');
  sEmpresa := Trim(AEmpresa);
  if sEmpresa = '' then
    sEmpresa := '-';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    // El alta del contador también se deshace si falla el documento.
    oConsulta.SQL.Text :=
      'INSERT INTO fza_contadores ' +
      '(TIPO_DOC_CON, EMPRESA_CON, SERIE_CON, CON, NUM_DIGITOS_CON, ' +
      'ESACTIVO_CON, DEFAULT_CON, INSTANTE_ALTA, USUARIO_ALTA, ' +
      'USUARIO_MODIF) VALUES (:TIPO, :EMPRESA, :SERIE, 1, 6, ' +
      '''S'', ''N'', NOW(), :USUARIO, :USUARIO) ' +
      'ON DUPLICATE KEY UPDATE CON = CON';
    oConsulta.ParamByName('TIPO').AsString := ATipoDocumento;
    oConsulta.ParamByName('EMPRESA').AsString := sEmpresa;
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('USUARIO').AsString := AUsuario;
    oConsulta.ExecSQL;
  finally
    FreeAndNil(oConsulta);
  end;
  oProcedimiento := TUniStoredProc.Create(nil);
  try
    oProcedimiento.Connection := FConexion;
    oProcedimiento.StoredProcName := 'PRC_GET_NEXT_CONTADOR';
    oProcedimiento.Prepare;
    oProcedimiento.ParamByName('pserie').AsString := ASerie;
    oProcedimiento.ParamByName('pTipoDoc').AsString := ATipoDocumento;
    oProcedimiento.ParamByName('pEmpresa').AsString := sEmpresa;
    oProcedimiento.ParamByName('pUsuario').AsString := AUsuario;
    oProcedimiento.Execute;
    Result := oProcedimiento.ParamByName('pContador').AsString;
  finally
    FreeAndNil(oProcedimiento);
  end;
end;

function TRepositorioFacturasProformaUniDAC.BuscarSerieFactura(
  const AEmpresa: string;
  const AAlmacen: string;
  const AFecha: TDateTime): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_OBTENER_SERIE_FACTURA;
    oConsulta.ParamByName('ORIGEN').AsString := AEmpresa;
    oConsulta.ParamByName('ALMACEN').AsString := AAlmacen;
    oConsulta.ParamByName('FECHA').AsDate := Trunc(AFecha);
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      Result := oConsulta.FieldByName('EMPSER').AsString;
    end;
    oConsulta.Close;
    if Result = '' then
    begin
      oConsulta.SQL.Text := SQL_OBTENER_SERIE_CONTADOR;
      oConsulta.ParamByName('ORIGEN').AsString := AEmpresa;
      oConsulta.ParamByName('FECHA').AsDate := Trunc(AFecha);
      oConsulta.Open;
      if not oConsulta.IsEmpty then
      begin
        Result := oConsulta.FieldByName('EMPSER').AsString;
      end;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioFacturasProformaUniDAC.ObtenerSerieFactura(
  const AEmpresa: string;
  const AAlmacen: string;
  const AFecha: TDateTime): string;
begin
  Result := BuscarSerieFactura(AEmpresa, AAlmacen, AFecha);
  if Result = '' then
  begin
    raise Exception.CreateFmt(
      SErrorSerieFacturaCajaNoDisponible,
      [AEmpresa]);
  end;
end;

// La serie elegida en el diálogo común manda; sin ella, la del almacén.
function TRepositorioFacturasProformaUniDAC.SerieFacturaSolicitud(
  const ASolicitud: TSolicitudFacturacionCaja;
  const AEmpresa: string;
  const AAlmacen: string): string;
begin
  Result := Trim(ASolicitud.SerieFactura);
  if Result = '' then
    Result := ObtenerSerieFactura(AEmpresa, AAlmacen,
      FechaFacturaSolicitud(ASolicitud));
end;

// Número escrito a mano: con ceros hasta los dígitos del contador si es
// numérico y sin repetir uno que ya exista en la serie.
function TRepositorioFacturasProformaUniDAC.NumeroFacturaManual(
  const ASerie: string;
  const AEmpresa: string;
  const ANumero: string): string;
var
  oConsulta: TUniQuery;
  iDigitos: Integer;
begin
  Result := Trim(ANumero);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_DIGITOS_CONTADOR_FACTURA;
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('EMPRESA').AsString := AEmpresa;
    oConsulta.Open;
    iDigitos := oConsulta.FieldByName('DIGITOS').AsInteger;
    oConsulta.Close;
    if EsNumeroSinSigno(Result) and (iDigitos > Length(Result)) then
      Result := StringOfChar('0', iDigitos - Length(Result)) + Result;
    oConsulta.SQL.Text := SQL_EXISTE_FACTURA;
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := Result;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      raise Exception.CreateFmt(SErrorNumeroFacturaCajaExistente,
        [ASerie, Result]);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioFacturasProformaUniDAC.GenerarVenta(
  const ASolicitud: TSolicitudFacturacionCaja
): TResultadoFacturacionCaja;
var
  iIdPeriodo: Int64;
  iIdProforma: Int64;
  sNumero: string;
  sSerie: string;
  oConsulta: TUniQuery;
begin
  Result := Default(TResultadoFacturacionCaja);
  iIdPeriodo := CrearPeriodo('VE', ASolicitud);
  try
    if ContarCandidatasVenta(ASolicitud) > 0 then
    begin
      sSerie := 'PVE-' + FormatDateTime('yyyy', ASolicitud.FechaHasta);
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        FConexion.StartTransaction;
        try
          sNumero := ObtenerNumeroDocumento(
            sSerie, 'PF', ASolicitud.CodigoEmpresaOrigen,
            ASolicitud.Usuario);
          oConsulta.SQL.Text := SQL_INSERTAR_PROFORMA;
          AsignarSolicitud(oConsulta, ASolicitud);
          oConsulta.ParamByName('ID_PERIODO').AsLargeInt := iIdPeriodo;
          oConsulta.ParamByName('SERIE').AsString := sSerie;
          oConsulta.ParamByName('NUMERO').AsString := sNumero;
          oConsulta.Execute;
          if oConsulta.RowsAffected = 0 then
          begin
            raise Exception.Create(SErrorCabeceraProformaCajaNoCreada);
          end;
          iIdProforma := ObtenerIdentidad;
          oConsulta.SQL.Text := SQL_INICIAR_LINEA_PROFORMA;
          oConsulta.Execute;
          oConsulta.SQL.Text := SQL_INSERTAR_LINEAS_VENTA;
          AsignarSolicitud(oConsulta, ASolicitud);
          oConsulta.ParamByName('ID').AsLargeInt := iIdProforma;
          oConsulta.Execute;
          oConsulta.SQL.Text := SQL_CONTINUAR_LINEA_PROFORMA;
          oConsulta.ParamByName('ID').AsLargeInt := iIdProforma;
          oConsulta.Execute;
          oConsulta.SQL.Text := SQL_INSERTAR_AJUSTES_VENTA;
          AsignarSolicitud(oConsulta, ASolicitud);
          oConsulta.ParamByName('ID').AsLargeInt := iIdProforma;
          oConsulta.Execute;
          oConsulta.SQL.Text := SQL_ACTUALIZAR_TOTALES_PROFORMA;
          AsignarSolicitud(oConsulta, ASolicitud);
          oConsulta.ParamByName('ID').AsLargeInt := iIdProforma;
          oConsulta.Execute;
          oConsulta.SQL.Text := SQL_CONTAR_PROFORMA;
          oConsulta.ParamByName('ID').AsLargeInt := iIdProforma;
          oConsulta.Open;
          Result.CantidadOperaciones :=
            oConsulta.FieldByName('OPERACIONES').AsInteger;
          Result.CantidadAjustes :=
            oConsulta.FieldByName('AJUSTES').AsInteger;
          oConsulta.Close;
          if Result.CantidadOperaciones > 0 then
          begin
            Result.CantidadDocumentos := 1;
            Result.Descripcion := Format(SDescripcionProformaCajaGenerada,
              [sSerie, sNumero, Result.CantidadOperaciones,
               Result.CantidadAjustes]);
            ActualizarPeriodo(
              iIdPeriodo,
              'CERRADO',
              Result,
              ASolicitud.Usuario);
            FConexion.Commit;
          end
          else
          begin
            FConexion.Rollback;
          end;
        except
          if FConexion.InTransaction then
          begin
            FConexion.Rollback;
          end;
          raise;
        end;
      except
        FreeAndNil(oConsulta);
        raise;
      end;
      FreeAndNil(oConsulta);
    end;
    if Result.CantidadDocumentos = 0 then
    begin
      DescartarPeriodoSinDocumentos(
        iIdPeriodo,
        Result,
        ASolicitud.Usuario);
    end;
  except
    ActualizarPeriodo(
      iIdPeriodo,
      'ERROR',
      Result,
      ASolicitud.Usuario);
    raise;
  end;
end;

function TRepositorioFacturasProformaUniDAC.GenerarValesRecogidos(
  const ASolicitud: TSolicitudFacturacionCaja
): TResultadoFacturacionCaja;
var
  iIdPeriodo: Int64;
  iIdProforma: Int64;
  iInversos: Integer;
  oConsulta: TUniQuery;
  oSolicitud: TSolicitudFacturacionCaja;
  sNumero: string;
  sSerie: string;
  vSaldo: Currency;
  vTotal: Currency;
begin
  Result := Default(TResultadoFacturacionCaja);
  oSolicitud := ASolicitud;
  if ContarValesRecogidos(ASolicitud, vSaldo) > 0 then
  begin
    // La propuesta se graba ya orientada: emite la empresa con saldo a
    // favor y el total queda positivo, como la factura (FZ-365)
    if vSaldo < 0 then
    begin
      oSolicitud.CodigoEmpresaOrigen := ASolicitud.CodigoEmpresaDestino;
      oSolicitud.CodigoEmpresaDestino := ASolicitud.CodigoEmpresaOrigen;
    end;
    sSerie := 'PVR-' + FormatDateTime('yyyy', oSolicitud.FechaHasta);
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      FConexion.StartTransaction;
      try
        sNumero := ObtenerNumeroDocumento(
          sSerie, 'PF', oSolicitud.CodigoEmpresaOrigen,
          oSolicitud.Usuario);
        iIdPeriodo := CrearPeriodo('VR', oSolicitud);
        oConsulta.SQL.Text := SQL_INSERTAR_PROFORMA_VALES;
        AsignarSolicitud(oConsulta, oSolicitud);
        oConsulta.ParamByName('ID_PERIODO').AsLargeInt := iIdPeriodo;
        oConsulta.ParamByName('SERIE').AsString := sSerie;
        oConsulta.ParamByName('NUMERO').AsString := sNumero;
        oConsulta.Execute;
        if oConsulta.RowsAffected <> 1 then
          raise Exception.Create(SErrorCabeceraProformaCajaNoCreada);
        iIdProforma := ObtenerIdentidad;
        oConsulta.SQL.Text := SQL_INSERTAR_VALES_PROPUESTA;
        AsignarSolicitud(oConsulta, oSolicitud);
        oConsulta.ParamByName('ID').AsLargeInt := iIdProforma;
        oConsulta.Execute;
        if oConsulta.RowsAffected > 0 then
        begin
          oConsulta.SQL.Text := SQL_RESUMEN_VALES_PROPUESTA;
          oConsulta.ParamByName('ID').AsLargeInt := iIdProforma;
          oConsulta.Open;
          Result.CantidadOperaciones :=
            oConsulta.FieldByName('CANTIDAD').AsInteger;
          iInversos := oConsulta.FieldByName('INVERSOS').AsInteger;
          vTotal := oConsulta.FieldByName('TOTAL').AsCurrency;
          oConsulta.Close;
          Result.CantidadDocumentos := 1;
          Result.CantidadAjustes := iInversos;
          oConsulta.SQL.Text := SQL_ACTUALIZAR_TOTALES_VALES;
          oConsulta.ParamByName('ID').AsLargeInt := iIdProforma;
          oConsulta.ParamByName('TOTAL').AsCurrency := vTotal;
          oConsulta.ParamByName('USUARIO').AsString := oSolicitud.Usuario;
          oConsulta.Execute;
          ActualizarPeriodo(
            iIdPeriodo, 'CERRADO', Result, oSolicitud.Usuario);
          Result.Descripcion := Format(
            SDescripcionProformaValesGenerada,
            [sSerie, sNumero, Result.CantidadOperaciones,
             iInversos, FormatCurr('#,##0.00', vTotal)]);
          FConexion.Commit;
        end
        else
          FConexion.Rollback;
      except
        if FConexion.InTransaction then
          FConexion.Rollback;
        raise;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TRepositorioFacturasProformaUniDAC.PrepararConversionProformaVales(
  AIdProforma: Int64): TOpcionesDocumento;
var
  oSolicitud: TSolicitudFacturacionCaja;
begin
  oSolicitud := PrepararSolicitudVales(
    LeerPropuestaVales(FConexion, AIdProforma), '');
  ComprobarClienteTraspasos(oSolicitud);
  Result := Default(TOpcionesDocumento);
  Result.Empresa := oSolicitud.CodigoEmpresaOrigen;
  Result.Tipo := 'FC';
  Result.Serie := BuscarSerieFactura(oSolicitud.CodigoEmpresaOrigen, '',
    Date);
  Result.Fecha := Date;
  Result.FormaPago := FORMA_PAGO_FACTURA_CAJA;
end;

function TRepositorioFacturasProformaUniDAC.ConvertirProformaVales(
  AIdProforma: Int64;
  const AOpciones: TOpcionesDocumento;
  const AUsuario: string): string;
var
  aLineas: TArray<TLineaValeFactura>;
  bInvertir: Boolean;
  Datos: TDatosPropuestaVales;
  DatosBloqueados: TDatosPropuestaVales;
  oConsulta: TUniQuery;
  oSolicitud: TSolicitudFacturacionCaja;
  sNumero: string;
  sSerie: string;
begin
  Datos := LeerPropuestaVales(FConexion, AIdProforma);
  oSolicitud := PrepararSolicitudVales(Datos, AUsuario);
  bInvertir := Datos.Saldo < 0;
  if AOpciones.Fecha > 0 then
  begin
    oSolicitud.FechaDesde := AOpciones.Fecha;
    oSolicitud.FechaHasta := AOpciones.Fecha;
  end;
  oSolicitud.SerieFactura := AOpciones.Serie;
  oSolicitud.FormaPago := AOpciones.FormaPago;
  ComprobarClienteTraspasos(oSolicitud);
  sSerie := SerieFacturaSolicitud(oSolicitud,
    oSolicitud.CodigoEmpresaOrigen, '');
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    FConexion.StartTransaction;
    try
      DatosBloqueados := LeerPropuestaVales(FConexion, AIdProforma);
      if (DatosBloqueados.Cantidad <> Datos.Cantidad) or
         (DatosBloqueados.Saldo <> Datos.Saldo) then
        raise Exception.Create(SErrorProformaValesNoDisponible);
      aLineas := LeerLineasVales(
        FConexion, AIdProforma, Datos.Cantidad);
      if AOpciones.NumeroAutomatico then
        sNumero := ObtenerNumeroDocumento(
          sSerie, 'FC', oSolicitud.CodigoEmpresaOrigen, AUsuario)
      else
        sNumero := NumeroFacturaManual(sSerie,
          oSolicitud.CodigoEmpresaOrigen, AOpciones.Numero);
      oConsulta.SQL.Text := SQL_INSERTAR_FACTURA_TA;
      AsignarSolicitud(oConsulta, oSolicitud);
      oConsulta.ParamByName('ORIGEN').AsString :=
        oSolicitud.CodigoEmpresaOrigen;
      oConsulta.ParamByName('SERIE').AsString := sSerie;
      oConsulta.ParamByName('NUMERO').AsString := sNumero;
      oConsulta.ParamByName('COMENTARIO').AsString := Format(
        SComentarioFacturaVales, [Datos.Serie, Datos.Numero]);
      oConsulta.Execute;
      if oConsulta.RowsAffected <> 1 then
        raise Exception.Create(SErrorFacturaValesNoCreada);
      InsertarLineasFacturaVales(
        FConexion, aLineas, oSolicitud.CodigoEmpresaOrigen,
        sSerie, sNumero, AUsuario, bInvertir);
      oConsulta.SQL.Text := SQL_ACTUALIZAR_CONTADOR_LINEAS_FACTURA;
      oConsulta.ParamByName('LINEAS').AsInteger := Datos.Cantidad;
      oConsulta.ParamByName('SERIE').AsString := sSerie;
      oConsulta.ParamByName('NUMERO').AsString := sNumero;
      oConsulta.Execute;
      RecalcularTotalesFactura(sSerie, sNumero);
      oConsulta.SQL.Text := SQL_TOTAL_FACTURA_VALES;
      oConsulta.ParamByName('SERIE').AsString := sSerie;
      oConsulta.ParamByName('NUMERO').AsString := sNumero;
      oConsulta.Open;
      if oConsulta.IsEmpty or
         (Abs(oConsulta.FieldByName('TOTAL').AsCurrency -
           Abs(Datos.Saldo)) > 0.0001) then
        raise Exception.Create(SErrorTotalesFacturaVales);
      oConsulta.Close;
      ValidarRequisitosFiscalesEmision(
        FParametrosApp, FConexion, sSerie, sNumero);
      oConsulta.SQL.Text := SQL_MARCAR_VALES_FACTURADOS;
      oConsulta.ParamByName('ID').AsLargeInt := AIdProforma;
      oConsulta.ParamByName('SERIE').AsString := sSerie;
      oConsulta.ParamByName('NUMERO').AsString := sNumero;
      oConsulta.ParamByName('USUARIO').AsString := AUsuario;
      oConsulta.Execute;
      if oConsulta.RowsAffected <> Datos.Cantidad then
        raise Exception.Create(SErrorFacturaValesLineas);
      oConsulta.SQL.Text := SQL_MARCAR_PROFORMA_VALES_FACTURADA;
      oConsulta.ParamByName('ID').AsLargeInt := AIdProforma;
      oConsulta.ParamByName('USUARIO').AsString := AUsuario;
      oConsulta.Execute;
      if oConsulta.RowsAffected <> 1 then
        raise Exception.Create(SErrorProformaValesNoDisponible);
      FConexion.Commit;
      Result := sSerie + '/' + sNumero;
    except
      if FConexion.InTransaction then
        FConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioFacturasProformaUniDAC.ReservarOperacionesTraspaso(
  AConsulta: TUniQuery;
  const ASolicitud: TSolicitudFacturacionCaja;
  AIdPeriodo: Int64;
  const AEmpresaOrigen: string;
  const AAlmacenOrigen: string;
  const ASerie: string;
  const ANumero: string): Integer;
begin
  AConsulta.SQL.Text := SQL_ENLAZAR_OPERACIONES_TA;
  AsignarSolicitud(AConsulta, ASolicitud);
  AConsulta.ParamByName('ID_PERIODO').AsLargeInt := AIdPeriodo;
  AConsulta.ParamByName('ORIGEN').AsString := AEmpresaOrigen;
  AConsulta.ParamByName('ALMACEN').AsString := AAlmacenOrigen;
  AConsulta.ParamByName('SERIE').AsString := ASerie;
  AConsulta.ParamByName('NUMERO').AsString := ANumero;
  AConsulta.Execute;
  AConsulta.SQL.Text := SQL_CONTAR_OPERACIONES_FACTURA;
  AConsulta.ParamByName('SERIE').AsString := ASerie;
  AConsulta.ParamByName('NUMERO').AsString := ANumero;
  AConsulta.Open;
  Result := AConsulta.FieldByName('CANTIDAD').AsInteger;
  AConsulta.Close;
end;

procedure TRepositorioFacturasProformaUniDAC.InsertarLineasFacturaTraspaso(
  AConsulta: TUniQuery;
  const ASolicitud: TSolicitudFacturacionCaja;
  const AEmpresaOrigen: string;
  const AAlmacenOrigen: string;
  const ASerie: string;
  const ANumero: string);
var
  iLineas: Integer;
begin
  iLineas := ContarLineasFacturaTraspaso(ASerie, ANumero);
  if iLineas > 9999 then
  begin
    raise Exception.CreateFmt(
      SErrorFacturaTaDemasiadasLineas,
      [AEmpresaOrigen, AAlmacenOrigen, iLineas]);
  end;
  if iLineas = 0 then
  begin
    raise Exception.Create(SErrorOperacionesTaSinLineas);
  end;
  AConsulta.SQL.Text := SQL_INICIAR_LINEA_FACTURA;
  AConsulta.Execute;
  AConsulta.SQL.Text := SQL_INSERTAR_LINEAS_TA;
  AsignarSolicitud(AConsulta, ASolicitud);
  AConsulta.ParamByName('ORIGEN').AsString := AEmpresaOrigen;
  AConsulta.ParamByName('ALMACEN').AsString := AAlmacenOrigen;
  AConsulta.ParamByName('SERIE').AsString := ASerie;
  AConsulta.ParamByName('NUMERO').AsString := ANumero;
  AConsulta.Execute;
  if AConsulta.RowsAffected <> iLineas then
  begin
    raise Exception.CreateFmt(
      SErrorCantidadLineasTaNoCoincide,
      [iLineas, AConsulta.RowsAffected]);
  end;
  AConsulta.SQL.Text := SQL_ACTUALIZAR_CONTADOR_LINEAS_FACTURA;
  AConsulta.ParamByName('LINEAS').AsInteger := iLineas;
  AConsulta.ParamByName('SERIE').AsString := ASerie;
  AConsulta.ParamByName('NUMERO').AsString := ANumero;
  AConsulta.Execute;
  RecalcularTotalesFactura(ASerie, ANumero);
  ValidarRequisitosFiscalesEmision(
    FParametrosApp,
    FConexion,
    ASerie,
    ANumero);
end;

function TRepositorioFacturasProformaUniDAC.CrearBorradorFacturaTraspaso(
  const ASolicitud: TSolicitudFacturacionCaja;
  AIdPeriodo: Int64;
  const AEmpresaOrigen: string;
  const AAlmacenOrigen: string;
  const ASerie: string;
  out ANumero: string): Integer;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    FConexion.StartTransaction;
    try
      ANumero := ObtenerNumeroDocumento(
        ASerie, 'FC', AEmpresaOrigen, ASolicitud.Usuario);
      oConsulta.SQL.Text := SQL_INSERTAR_FACTURA_TA;
      AsignarSolicitud(oConsulta, ASolicitud);
      oConsulta.ParamByName('ORIGEN').AsString := AEmpresaOrigen;
      oConsulta.ParamByName('SERIE').AsString := ASerie;
      oConsulta.ParamByName('NUMERO').AsString := ANumero;
      oConsulta.ParamByName('COMENTARIO').AsString := Format(
        SComentarioFacturaTraspaso,
        [FormatDateTime('dd/mm/yyyy', ASolicitud.FechaDesde),
         FormatDateTime('dd/mm/yyyy', ASolicitud.FechaHasta)]);
      oConsulta.Execute;
      if oConsulta.RowsAffected = 0 then
      begin
        raise Exception.CreateFmt(
          SErrorFacturaTaNoCreada,
          [AEmpresaOrigen]);
      end;
      Result := ReservarOperacionesTraspaso(
        oConsulta,
        ASolicitud,
        AIdPeriodo,
        AEmpresaOrigen,
        AAlmacenOrigen,
        ASerie,
        ANumero);
      if Result > 0 then
      begin
        InsertarLineasFacturaTraspaso(
          oConsulta,
          ASolicitud,
          AEmpresaOrigen,
          AAlmacenOrigen,
          ASerie,
          ANumero);
        FConexion.Commit;
      end
      else
      begin
        FConexion.Rollback;
      end;
    except
      if FConexion.InTransaction then
      begin
        FConexion.Rollback;
      end;
      raise;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioFacturasProformaUniDAC.GenerarFacturaTraspaso(
  const ASolicitud: TSolicitudFacturacionCaja;
  AIdPeriodo: Int64;
  const AEmpresaOrigen: string;
  const AAlmacenOrigen: string;
  out AFactura: TFacturaCreadaCaja): Integer;
var
  iLineas: Integer;
  sNumero: string;
  sSerie: string;
begin
  Result := 0;
  AFactura := Default(TFacturaCreadaCaja);
  iLineas := ContarLineasTraspaso(ASolicitud, AEmpresaOrigen,
    AAlmacenOrigen);
  if iLineas > 9999 then
  begin
    raise Exception.CreateFmt(
      SErrorFacturaTaDemasiadasLineas,
      [AEmpresaOrigen, AAlmacenOrigen, iLineas]);
  end;
  if iLineas > 0 then
  begin
    ComprobarClienteTraspasos(ASolicitud);
    sSerie := SerieFacturaSolicitud(ASolicitud, AEmpresaOrigen,
      AAlmacenOrigen);
    Result := CrearBorradorFacturaTraspaso(
      ASolicitud,
      AIdPeriodo,
      AEmpresaOrigen,
      AAlmacenOrigen,
      sSerie,
      sNumero);
    AFactura.Serie := sSerie;
    AFactura.Numero := sNumero;
    AFactura.Almacen := AAlmacenOrigen;
  end;
end;

function TRepositorioFacturasProformaUniDAC.ObtenerLineasTraspasoPendientes(
  const ASolicitud: TSolicitudFacturacionCaja
): TLineasTraspasoPendientes;
var
  oConsulta: TUniQuery;
  iLinea: Integer;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_LINEAS_TRASPASO_PENDIENTES;
    AsignarSolicitud(oConsulta, ASolicitud);
    oConsulta.Open;
    iLinea := 0;
    while not oConsulta.Eof do
    begin
      SetLength(Result, iLinea + 1);
      Result[iLinea].NumeroMovimiento :=
        oConsulta.FieldByName('NUMERO_MOV').AsString;
      Result[iLinea].NumeroOperacion :=
        oConsulta.FieldByName('NUMERO_OPERACION_OPCAJA').AsString;
      Result[iLinea].FechaOperacion :=
        oConsulta.FieldByName('FECHA_OPERACION').AsDateTime;
      Result[iLinea].Linea :=
        oConsulta.FieldByName('LINEA_MOV').AsString;
      Result[iLinea].CodigoArticulo :=
        oConsulta.FieldByName('CODIGO_ART_MOV').AsString;
      Result[iLinea].CodigoUnidad :=
        oConsulta.FieldByName('CODIGO_UNIDAD_MOV').AsString;
      Result[iLinea].Descripcion :=
        oConsulta.FieldByName('DESCRIPCION').AsString;
      Result[iLinea].Cantidad :=
        oConsulta.FieldByName('CANTIDAD_MOV').AsCurrency;
      Result[iLinea].CosteMovimiento :=
        oConsulta.FieldByName('COSTE_MOVIMIENTO').AsCurrency;
      Result[iLinea].PrecioMedioEmpresa :=
        oConsulta.FieldByName('PRECIO_MEDIO_EMPRESA').AsCurrency;
      Result[iLinea].PrecioUltimaCompra :=
        oConsulta.FieldByName('PRECIO_ULTIMA_COMPRA').AsCurrency;
      Result[iLinea].AntiguedadMeses :=
        oConsulta.FieldByName('ANTIGUEDAD_MESES').AsInteger;
      Inc(iLinea);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
  if Length(Result) > 0 then
    ComprobarClienteTraspasos(ASolicitud);
end;

procedure TRepositorioFacturasProformaUniDAC.PrepararValoracionTraspasos(
  const AValoracion: TValoracionTraspasos);
var
  oConsulta: TUniQuery;
  iLinea: Integer;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_ELIMINAR_VALORACION_TA;
    oConsulta.Execute;
    oConsulta.SQL.Text := SQL_CREAR_VALORACION_TA;
    oConsulta.Execute;
    oConsulta.SQL.Text := SQL_CLAVE_VALORACION_TA;
    oConsulta.Execute;
    if Length(AValoracion) > 0 then
    begin
      oConsulta.SQL.Text := SQL_INSERTAR_VALORACION_TA;
      oConsulta.Prepare;
      for iLinea := 0 to High(AValoracion) do
      begin
        oConsulta.ParamByName('NUMERO_MOV').AsString :=
          AValoracion[iLinea].NumeroMovimiento;
        oConsulta.ParamByName('PRECIO').AsCurrency :=
          AValoracion[iLinea].Precio;
        oConsulta.Execute;
      end;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioFacturasProformaUniDAC.EliminarValoracionTraspasos;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_ELIMINAR_VALORACION_TA;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioFacturasProformaUniDAC.ContarLineasTraspasoSinValorar(
  const ASolicitud: TSolicitudFacturacionCaja): Integer;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_CONTAR_LINEAS_TRASPASO_SIN_VALORAR;
    AsignarSolicitud(oConsulta, ASolicitud);
    oConsulta.Open;
    Result := oConsulta.FieldByName('CANTIDAD').AsInteger;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioFacturasProformaUniDAC.GenerarTraspasos(
  const ASolicitud: TSolicitudFacturacionCaja;
  const AValoracion: TValoracionTraspasos
): TResultadoFacturacionCaja;
var
  iSinValorar: Integer;
begin
  Result := Default(TResultadoFacturacionCaja);
  PrepararValoracionTraspasos(AValoracion);
  try
    iSinValorar := ContarLineasTraspasoSinValorar(ASolicitud);
    if iSinValorar > 0 then
    begin
      raise Exception.CreateFmt(SErrorLineasTaSinValorar, [iSinValorar]);
    end;
    Result := GenerarTraspasosValorados(ASolicitud);
  finally
    EliminarValoracionTraspasos;
  end;
end;

function TRepositorioFacturasProformaUniDAC.GenerarTraspasosValorados(
  const ASolicitud: TSolicitudFacturacionCaja
): TResultadoFacturacionCaja;
var
  iIdPeriodo: Int64;
  iIndice: Integer;
  iOperaciones: Integer;
  aGrupos: TArray<TGrupoTraspaso>;
  oConsulta: TUniQuery;
  oFactura: TFacturaCreadaCaja;
  sAlmacenEnCurso: string;
begin
  Result := Default(TResultadoFacturacionCaja);
  sAlmacenEnCurso := '';
  iIdPeriodo := CrearPeriodo('TA', ASolicitud);
  try
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text := SQL_GRUPOS_TRASPASO;
      AsignarSolicitud(oConsulta, ASolicitud);
      oConsulta.Open;
      while not oConsulta.Eof do
      begin
        SetLength(aGrupos, Length(aGrupos) + 1);
        aGrupos[High(aGrupos)].Empresa :=
          oConsulta.FieldByName('EMPRESA').AsString;
        aGrupos[High(aGrupos)].Almacen :=
          oConsulta.FieldByName('ALMACEN').AsString;
        oConsulta.Next;
      end;
      oConsulta.Close;
    finally
      FreeAndNil(oConsulta);
    end;
    for iIndice := 0 to High(aGrupos) do
    begin
      sAlmacenEnCurso := aGrupos[iIndice].Almacen;
      iOperaciones := GenerarFacturaTraspaso(
        ASolicitud,
        iIdPeriodo,
        aGrupos[iIndice].Empresa,
        aGrupos[iIndice].Almacen,
        oFactura);
      if iOperaciones > 0 then
      begin
        Inc(Result.CantidadDocumentos);
        Inc(Result.CantidadOperaciones, iOperaciones);
        Result.Facturas := Result.Facturas + [oFactura];
      end;
    end;
    sAlmacenEnCurso := '';
    if Result.CantidadDocumentos > 0 then
    begin
      Result.Descripcion := Format(SDescripcionBorradoresFacturasTaGenerados,
        [Result.CantidadDocumentos, Result.CantidadOperaciones]);
      ActualizarPeriodo(
        iIdPeriodo,
        'CERRADO',
        Result,
        ASolicitud.Usuario);
    end
    else
    begin
      DescartarPeriodoSinDocumentos(
        iIdPeriodo,
        Result,
        ASolicitud.Usuario);
    end;
  except
    on E: Exception do
    begin
      if Result.CantidadDocumentos = 0 then
      begin
        ActualizarPeriodo(
          iIdPeriodo,
          'ERROR',
          Result,
          ASolicitud.Usuario);
        raise;
      end;
      CerrarPeriodoParcial(
        iIdPeriodo,
        sAlmacenEnCurso,
        E.Message,
        Result,
        ASolicitud.Usuario);
    end;
  end;
end;

function SiNoAjenas(AAjenas: Boolean): string;
begin
  if AAjenas then
    Result := 'S'
  else
    Result := 'N';
end;

function TRepositorioFacturasProformaUniDAC.ObtenerTraspasosVendibles(
  const ASolicitud: TSolicitudFacturacionCaja;
  AAjenos: Boolean
): TTraspasosVendiblesPendientes;
var
  oConsulta: TUniQuery;
  iLinea   : Integer;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_TRASPASOS_VENDIBLES;
    AsignarSolicitud(oConsulta, ASolicitud);
    oConsulta.ParamByName('AJENAS').AsString := SiNoAjenas(AAjenos);
    oConsulta.Open;
    iLinea := 0;
    while not oConsulta.Eof do
    begin
      SetLength(Result, iLinea + 1);
      Result[iLinea] := Default(TTraspasoVendiblePendiente);
      Result[iLinea].NumeroMovimiento :=
        oConsulta.FieldByName('NUMERO_MOV').AsString;
      Result[iLinea].IdOperacion :=
        oConsulta.FieldByName('ID_OPCAJA').AsLargeInt;
      Result[iLinea].NumeroOperacion :=
        oConsulta.FieldByName('NUMERO_OPERACION_OPCAJA').AsString;
      Result[iLinea].Linea :=
        oConsulta.FieldByName('LINEA_MOV').AsString;
      Result[iLinea].Fecha :=
        oConsulta.FieldByName('FECHA_OPERACION').AsDateTime;
      Result[iLinea].AlmacenOrigen :=
        oConsulta.FieldByName('ALMACEN_ORIGEN').AsString;
      Result[iLinea].AlmacenDestino :=
        oConsulta.FieldByName('ALMACEN_DESTINO').AsString;
      Result[iLinea].CodigoArticulo :=
        oConsulta.FieldByName('CODIGO_ART_MOV').AsString;
      Result[iLinea].CodigoUnidad :=
        oConsulta.FieldByName('CODIGO_UNIDAD_MOV').AsString;
      Result[iLinea].Descripcion :=
        oConsulta.FieldByName('DESCRIPCION').AsString;
      Result[iLinea].Cantidad :=
        oConsulta.FieldByName('CANTIDAD_MOV').AsCurrency;
      Result[iLinea].CantidadFacturada :=
        oConsulta.FieldByName('CANTIDAD_FACTURADA').AsCurrency;
      Result[iLinea].CosteMovimiento :=
        oConsulta.FieldByName('COSTE_MOVIMIENTO').AsCurrency;
      Result[iLinea].PrecioMedioEmpresa :=
        oConsulta.FieldByName('PRECIO_MEDIO_EMPRESA').AsCurrency;
      Result[iLinea].PrecioUltimaCompra :=
        oConsulta.FieldByName('PRECIO_ULTIMA_COMPRA').AsCurrency;
      Result[iLinea].AntiguedadMeses :=
        oConsulta.FieldByName('ANTIGUEDAD_MESES').AsInteger;
      Result[iLinea].PrecioVentaDestino :=
        oConsulta.FieldByName('PRECIO_VENTA_DESTINO').AsCurrency;
      Result[iLinea].EsDeOtraEmisora := AAjenos;
      Inc(iLinea);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioFacturasProformaUniDAC.ObtenerVentasDestino(
  const ASolicitud: TSolicitudFacturacionCaja
): TVentasDestinoPendientes;
var
  oConsulta: TUniQuery;
  iLinea   : Integer;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_VENTAS_DESTINO;
    AsignarSolicitud(oConsulta, ASolicitud);
    oConsulta.Open;
    iLinea := 0;
    while not oConsulta.Eof do
    begin
      SetLength(Result, iLinea + 1);
      Result[iLinea] := Default(TVentaDestinoPendiente);
      Result[iLinea].NumeroMovimiento :=
        oConsulta.FieldByName('NUMERO_MOV').AsString;
      Result[iLinea].Fecha :=
        oConsulta.FieldByName('FECHA_MOV').AsDateTime;
      Result[iLinea].Almacen :=
        oConsulta.FieldByName('CODIGO_ALM_MOV').AsString;
      Result[iLinea].CodigoUnidad :=
        oConsulta.FieldByName('CODIGO_UNIDAD_MOV').AsString;
      Result[iLinea].Cantidad :=
        oConsulta.FieldByName('CANTIDAD_MOV').AsCurrency;
      Result[iLinea].CantidadAsignada :=
        oConsulta.FieldByName('CANTIDAD_ASIGNADA').AsCurrency;
      Result[iLinea].EsDevolucion := SameText(
        Trim(oConsulta.FieldByName('TIPO_MOV').AsString), 'E');
      Result[iLinea].PrecioVenta :=
        oConsulta.FieldByName('PRECIO_VENTA').AsCurrency;
      Result[iLinea].SinLineaFactura := SameText(
        oConsulta.FieldByName('SIN_LINEA_FACTURA').AsString, 'S');
      Result[iLinea].Documento :=
        oConsulta.FieldByName('DOCUMENTO').AsString;
      Result[iLinea].DocumentoOrigen :=
        oConsulta.FieldByName('DOCUMENTO_ORIGEN').AsString;
      Inc(iLinea);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioFacturasProformaUniDAC.ObtenerFacturacionesPrevias(
  const ASolicitud: TSolicitudFacturacionCaja;
  AAjenas: Boolean
): TFacturacionesTraspasoPrevias;
var
  oConsulta: TUniQuery;
  iLinea   : Integer;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_FACTURACIONES_TRASPASO_PREVIAS;
    AsignarSolicitud(oConsulta, ASolicitud);
    oConsulta.ParamByName('AJENAS').AsString := SiNoAjenas(AAjenas);
    oConsulta.Open;
    iLinea := 0;
    while not oConsulta.Eof do
    begin
      SetLength(Result, iLinea + 1);
      Result[iLinea] := Default(TFacturacionTraspasoPrevia);
      Result[iLinea].NumeroMovimientoTraspaso :=
        oConsulta.FieldByName('NUMERO_MOV_TA_FACTV').AsString;
      Result[iLinea].IdOperacion :=
        oConsulta.FieldByName('ID_OPCAJA').AsLargeInt;
      Result[iLinea].AlmacenOrigen :=
        oConsulta.FieldByName('CODIGO_ALM_ORIGEN_FACTV').AsString;
      Result[iLinea].AlmacenDestino :=
        oConsulta.FieldByName('CODIGO_ALM_DESTINO_FACTV').AsString;
      Result[iLinea].CodigoArticulo :=
        oConsulta.FieldByName('CODIGO_ART').AsString;
      Result[iLinea].CodigoUnidad :=
        oConsulta.FieldByName('CODIGO_UNIDAD_FACTV').AsString;
      Result[iLinea].Descripcion :=
        oConsulta.FieldByName('DESCRIPCION').AsString;
      Result[iLinea].Precio :=
        oConsulta.FieldByName('PRECIO_FACTV').AsCurrency;
      Result[iLinea].Cantidad :=
        oConsulta.FieldByName('CANTIDAD').AsCurrency;
      Result[iLinea].Fecha :=
        oConsulta.FieldByName('FECHA_VENTA').AsDateTime;
      Result[iLinea].FechaTraspaso :=
        oConsulta.FieldByName('FECHA_TRASPASO').AsDateTime;
      Result[iLinea].DocumentoVenta :=
        oConsulta.FieldByName('DOCUMENTO_VENTA').AsString;
      Result[iLinea].EsDeOtraEmisora := AAjenas;
      Inc(iLinea);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioFacturasProformaUniDAC.RepartirVentasEntreTraspasos(
  const ASolicitud: TSolicitudFacturacionCaja;
  out ATraspasos: TTraspasosVendiblesPendientes;
  out APrevias: TFacturacionesTraspasoPrevias
): TAsignacionesTraspasoVendido;
begin
  // FZ-ISSUE-357: lo de las otras emisoras va detrás; sólo sirve para que
  // el FIFO sea global y AsignarVentasATraspasos lo descarta al final.
  ATraspasos := ObtenerTraspasosVendibles(ASolicitud, False) +
    ObtenerTraspasosVendibles(ASolicitud, True);
  APrevias := ObtenerFacturacionesPrevias(ASolicitud, False) +
    ObtenerFacturacionesPrevias(ASolicitud, True);
  Result := AsignarVentasATraspasos(
    ATraspasos, ObtenerVentasDestino(ASolicitud), APrevias);
end;

function TRepositorioFacturasProformaUniDAC.
  ObtenerLineasTraspasoVendidoPendientes(
  const ASolicitud: TSolicitudFacturacionCaja
): TLineasTraspasoPendientes;
var
  aTraspasos   : TTraspasosVendiblesPendientes;
  aPrevias     : TFacturacionesTraspasoPrevias;
  aAsignaciones: TAsignacionesTraspasoVendido;
begin
  aAsignaciones := RepartirVentasEntreTraspasos(
    ASolicitud, aTraspasos, aPrevias);
  Result := ResumirTraspasosVendidos(aTraspasos, aAsignaciones);
  if Length(Result) > 0 then
    ComprobarClienteTraspasos(ASolicitud);
end;

procedure TRepositorioFacturasProformaUniDAC.InsertarFilasTraspasoVendido(
  AConsulta: TUniQuery;
  AIdPeriodo: Int64;
  const ASolicitud: TSolicitudFacturacionCaja;
  const ASerie: string;
  const ANumero: string;
  const AFilas: TFilasTraspasoVendido);
var
  iFila: Integer;
begin
  AConsulta.SQL.Text := SQL_INSERTAR_TRASPASO_VENDIDO;
  AConsulta.Prepare;
  AsignarSolicitud(AConsulta, ASolicitud);
  for iFila := 0 to High(AFilas) do
  begin
    AConsulta.ParamByName('ID_PERIODO').AsLargeInt := AIdPeriodo;
    AConsulta.ParamByName('SERIE').AsString := ASerie;
    AConsulta.ParamByName('NUMERO').AsString := ANumero;
    AConsulta.ParamByName('NUMERO_MOV_TA').AsString :=
      AFilas[iFila].NumeroMovimientoTraspaso;
    AConsulta.ParamByName('NUMERO_MOV_VE').AsString :=
      AFilas[iFila].NumeroMovimientoVenta;
    AConsulta.ParamByName('ID_OPCAJA').AsLargeInt :=
      AFilas[iFila].IdOperacion;
    if AFilas[iFila].EsDevolucion then
      AConsulta.ParamByName('TIPO').AsString := 'DEVOLUCION'
    else
      AConsulta.ParamByName('TIPO').AsString := 'VENTA';
    AConsulta.ParamByName('ALMACEN_ORIGEN').AsString :=
      AFilas[iFila].AlmacenOrigen;
    AConsulta.ParamByName('ALMACEN_DESTINO').AsString :=
      AFilas[iFila].AlmacenDestino;
    AConsulta.ParamByName('ARTICULO').AsString :=
      AFilas[iFila].CodigoArticulo;
    AConsulta.ParamByName('UNIDAD').AsString := AFilas[iFila].CodigoUnidad;
    AConsulta.ParamByName('CANTIDAD').AsCurrency := AFilas[iFila].Cantidad;
    AConsulta.ParamByName('PRECIO').AsCurrency := AFilas[iFila].Precio;
    AConsulta.ParamByName('FECHA_VENTA').AsDate :=
      Trunc(AFilas[iFila].FechaVenta);
    if AFilas[iFila].FechaTraspaso > 0 then
      AConsulta.ParamByName('FECHA_TRASPASO').AsDate :=
        Trunc(AFilas[iFila].FechaTraspaso)
    else
      AConsulta.ParamByName('FECHA_TRASPASO').Clear;
    AConsulta.Execute;
  end;
end;

function TRepositorioFacturasProformaUniDAC.
  ContarLineasFacturaTraspasoVendido(
  const ASerie: string;
  const ANumero: string): Integer;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_CONTAR_LINEAS_FACTURA_TV;
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.Open;
    Result := oConsulta.FieldByName('CANTIDAD').AsInteger;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioFacturasProformaUniDAC.ComprobarClienteTraspasos(
  const ASolicitud: TSolicitudFacturacionCaja);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_CLIENTE_TRASPASOS_DESTINO;
    oConsulta.ParamByName('EMPRESA_DESTINO').AsString :=
      ASolicitud.CodigoEmpresaDestino;
    oConsulta.Open;
    if oConsulta.IsEmpty then
    begin
      raise Exception.CreateFmt(
        SErrorEmpresaSinClienteTraspasos,
        [ASolicitud.CodigoEmpresaDestino]);
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioFacturasProformaUniDAC.RecalcularTotalesFactura(
  const ASerie: string;
  const ANumero: string);
var
  sMensaje: string;
begin
  if not RecalcularTotalesFacturaVenta(FConexion, ASerie, ANumero,
       sMensaje) then
    raise Exception.CreateFmt(
      SErrorTotalesFacturaTraspaso,
      [ASerie, ANumero, sMensaje]);
end;

function TRepositorioFacturasProformaUniDAC.GenerarFacturaTraspasoVendido(
  const ASolicitud: TSolicitudFacturacionCaja;
  AIdPeriodo: Int64;
  const AEmpresaOrigen: string;
  const AAlmacenOrigen: string;
  const AFilas: TFilasTraspasoVendido;
  var AAjustes: Integer;
  out AFactura: TFacturaCreadaCaja): Integer;
var
  oConsulta: TUniQuery;
  iLineas  : Integer;
  sNumero  : string;
  sSerie   : string;
begin
  Result := 0;
  AFactura := Default(TFacturaCreadaCaja);
  ComprobarClienteTraspasos(ASolicitud);
  sSerie := SerieFacturaSolicitud(
    ASolicitud, AEmpresaOrigen, AAlmacenOrigen);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    FConexion.StartTransaction;
    try
      sNumero := ObtenerNumeroDocumento(
        sSerie, 'FC', AEmpresaOrigen, ASolicitud.Usuario);
      oConsulta.SQL.Text := SQL_INSERTAR_FACTURA_TA;
      AsignarSolicitud(oConsulta, ASolicitud);
      oConsulta.ParamByName('ORIGEN').AsString := AEmpresaOrigen;
      oConsulta.ParamByName('SERIE').AsString := sSerie;
      oConsulta.ParamByName('NUMERO').AsString := sNumero;
      oConsulta.ParamByName('COMENTARIO').AsString := Format(
        SComentarioFacturaTraspasoVendido,
        [FormatDateTime('dd/mm/yyyy', ASolicitud.FechaDesde),
         FormatDateTime('dd/mm/yyyy', ASolicitud.FechaHasta)]);
      oConsulta.Execute;
      if oConsulta.RowsAffected = 0 then
      begin
        raise Exception.CreateFmt(
          SErrorFacturaTaNoCreada,
          [AEmpresaOrigen]);
      end;
      InsertarFilasTraspasoVendido(
        oConsulta, AIdPeriodo, ASolicitud, sSerie, sNumero, AFilas);
      iLineas := ContarLineasFacturaTraspasoVendido(sSerie, sNumero);
      if iLineas > 9999 then
      begin
        raise Exception.CreateFmt(
          SErrorFacturaTaDemasiadasLineas,
          [AEmpresaOrigen, AAlmacenOrigen, iLineas]);
      end;
      if iLineas = 0 then
      begin
        FConexion.Rollback;
      end
      else
      begin
        oConsulta.SQL.Text := SQL_INICIAR_LINEA_FACTURA_TV;
        oConsulta.Execute;
        oConsulta.SQL.Text := SQL_INSERTAR_LINEAS_TV;
        AsignarSolicitud(oConsulta, ASolicitud);
        oConsulta.ParamByName('ORIGEN').AsString := AEmpresaOrigen;
        oConsulta.ParamByName('SERIE').AsString := sSerie;
        oConsulta.ParamByName('NUMERO').AsString := sNumero;
        oConsulta.ParamByName('PREFIJO_DEVOLUCION').AsString :=
          SPrefijoDevolucionFacturaTraspasoVendido;
        oConsulta.Execute;
        if oConsulta.RowsAffected <> iLineas then
        begin
          raise Exception.CreateFmt(
            SErrorCantidadLineasTaNoCoincide,
            [iLineas, oConsulta.RowsAffected]);
        end;
        oConsulta.SQL.Text := SQL_ACTUALIZAR_CONTADOR_LINEAS_FACTURA;
        oConsulta.ParamByName('LINEAS').AsInteger := iLineas;
        oConsulta.ParamByName('SERIE').AsString := sSerie;
        oConsulta.ParamByName('NUMERO').AsString := sNumero;
        oConsulta.Execute;
        RecalcularTotalesFactura(sSerie, sNumero);
        ValidarRequisitosFiscalesEmision(
          FParametrosApp,
          FConexion,
          sSerie,
          sNumero);
        FConexion.Commit;
        Result := ContarOperacionesTraspasoVendido(AFilas);
        AAjustes := AAjustes + ContarDevolucionesTraspasoVendido(AFilas);
        AFactura.Serie := sSerie;
        AFactura.Numero := sNumero;
        AFactura.Almacen := AAlmacenOrigen;
      end;
    except
      if FConexion.InTransaction then
      begin
        FConexion.Rollback;
      end;
      raise;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioFacturasProformaUniDAC.GenerarTraspasosVendidos(
  const ASolicitud: TSolicitudFacturacionCaja;
  const AValoracion: TValoracionTraspasos
): TResultadoFacturacionCaja;
var
  aTraspasos   : TTraspasosVendiblesPendientes;
  aPrevias     : TFacturacionesTraspasoPrevias;
  aAsignaciones: TAsignacionesTraspasoVendido;
  aFilas       : TFilasTraspasoVendido;
  aAlmacenes   : TArray<string>;
  aGrupo       : TFilasTraspasoVendido;
  iIdPeriodo   : Int64;
  iSinValorar  : Integer;
  iIndice      : Integer;
  iOperaciones : Integer;
  oFactura     : TFacturaCreadaCaja;
  sNegativas   : string;
  sAlmacenEnCurso: string;
begin
  Result := Default(TResultadoFacturacionCaja);
  sNegativas := '';
  sAlmacenEnCurso := '';
  aAsignaciones := RepartirVentasEntreTraspasos(
    ASolicitud, aTraspasos, aPrevias);
  iSinValorar := ContarTraspasosVendidosSinValorar(
    aTraspasos, aAsignaciones, AValoracion);
  if iSinValorar > 0 then
  begin
    raise Exception.CreateFmt(SErrorLineasTvSinValorar, [iSinValorar]);
  end;
  aFilas := ConstruirFilasTraspasoVendido(
    aTraspasos, aPrevias, aAsignaciones, AValoracion);
  iIdPeriodo := CrearPeriodo('TV', ASolicitud);
  try
    aAlmacenes := AlmacenesOrigenTraspasoVendido(aFilas);
    for iIndice := 0 to High(aAlmacenes) do
    begin
      sAlmacenEnCurso := aAlmacenes[iIndice];
      aGrupo := FilasTraspasoVendidoDeAlmacen(aFilas, aAlmacenes[iIndice]);
      // Una factura NORMAL no puede salir negativa (FZ-356)
      if HayImporteFacturableTraspasoVendido(aGrupo) and
         (ImporteNetoTraspasoVendido(aGrupo) < 0) then
        sNegativas := sNegativas + sLineBreak + Format(
          SAvisoTvNegativaNoFacturada,
          [aAlmacenes[iIndice],
           FormatCurr('#,##0.00', ImporteNetoTraspasoVendido(aGrupo))])
      else if HayImporteFacturableTraspasoVendido(aGrupo) then
      begin
        iOperaciones := GenerarFacturaTraspasoVendido(
          ASolicitud,
          iIdPeriodo,
          ASolicitud.CodigoEmpresaOrigen,
          aAlmacenes[iIndice],
          aGrupo,
          Result.CantidadAjustes,
          oFactura);
        if iOperaciones > 0 then
        begin
          Inc(Result.CantidadDocumentos);
          Inc(Result.CantidadOperaciones, iOperaciones);
          Result.Facturas := Result.Facturas + [oFactura];
        end;
      end;
    end;
    sAlmacenEnCurso := '';
    Result.Descripcion := Trim(sNegativas);
    if Result.CantidadDocumentos > 0 then
    begin
      Result.Descripcion := Format(
        SDescripcionFacturasTraspasoVendidoGeneradas,
        [Result.CantidadDocumentos, Result.CantidadOperaciones,
         Result.CantidadAjustes]) + sNegativas;
      ActualizarPeriodo(
        iIdPeriodo,
        'CERRADO',
        Result,
        ASolicitud.Usuario);
    end
    else
    begin
      DescartarPeriodoSinDocumentos(
        iIdPeriodo,
        Result,
        ASolicitud.Usuario);
    end;
  except
    on E: Exception do
    begin
      if Result.CantidadDocumentos = 0 then
      begin
        ActualizarPeriodo(
          iIdPeriodo,
          'ERROR',
          Result,
          ASolicitud.Usuario);
        raise;
      end;
      CerrarPeriodoParcial(
        iIdPeriodo,
        sAlmacenEnCurso,
        E.Message,
        Result,
        ASolicitud.Usuario);
    end;
  end;
end;

end.
