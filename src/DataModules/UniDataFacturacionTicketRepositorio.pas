{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataFacturacionTicketRepositorio                         }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia UniDAC para sustituir tickets por facturas normales.         }
{******************************************************************************}
unit UniDataFacturacionTicketRepositorio;

interface

uses
  Uni, inLibParametrosIntf, inLibEmisionFiscalIntf,
  inLibVerifactuColaIntf, inLibFacturacionTicketPersistenciaIntf;

function CrearServicioFacturacionTicketUniDAC(
  AConexion: TUniConnection;
  const AParametrosApp: IParametrosAplicacion;
  const AServicioEmision: IServicioEmisionFiscal;
  const AServicioCola: IServicioVerifactuCola
): IServicioFacturacionTicket;

implementation

uses
  System.SysUtils, System.Classes, Data.DB, inLibVerifactu, inLibMsgFacturas,
  inLibFacturasValidacionCabecera, inLibFormatoDocumento,
  UniDataFormatoDocumentoRepositorio, inLibTrazabilidad,
  inLibVerifactuTipos, inLibFacturasPersistenciaIntf,
  inLibFacturasServiciosIntf, inLibFacturasMovimientos,
  UniDataFacturasOperaciones, UniDataFacturasRecalculoTotales,
  UniDataAlmacenesEmpresaRepositorio, inLibAlmacenesEmpresaPersistenciaIntf,
  UniDataValoresAutomaticosRepositorio;

resourcestring
  SErrorNumeroFacturaTicketExistente =
    'Ya existe la factura %s/%s.';

const
  SQL_TICKET_PENDIENTE =
    ' AND t.TIPO_FAC = ''SIMPLIFICADA'' ' +
    ' AND t.ESCONSOLIDADA_FAC = ''S'' ' +
    ' AND COALESCE(t.FASE_FAC, '''') NOT IN ' +
    '(''CANCELADA'', ''VERIFACTU_ANULADA'', ''SIN_VERIF_ANULADA'', ' +
    '''NOVERIFACTU_ANULADA'', ''RECTIFICADA'', ''SUBSANACION'', ' +
    '''BORRADOR'') ' +
    ' AND COALESCE(t.NUMERO_FAC_ABONO_FAC, '''') = '''' ' +
    ' AND NOT EXISTS (SELECT 1 FROM fza_facturas_relaciones r ' +
    ' WHERE r.SERIE_FAC_ORIGEN_FACREL = t.SERIE_FAC ' +
    ' AND r.NUMERO_FAC_ORIGEN_FACREL = t.NUMERO_FAC ' +
    ' AND r.TIPO_RELACION_FACREL IN (''SUSTITUYE'', ''RECTIFICA'')) ';
  SQL_TICKET_SIN_CLIENTE =
    '(COALESCE(TRIM(t.CODIGO_CLI_FAC), '''') = '''' ' +
    'OR EXISTS (SELECT 1 FROM fza_clientes c ' +
    'WHERE c.CODIGO_CLI_CLI = t.CODIGO_CLI_FAC ' +
    'AND c.ESVARIOS_CLI = ''S''))';
  CAMPOS_COMPATIBILIDAD_TICKETS =
    'NIF_EMPRESA_FAC, GRUPO_ZONA_IVA_EMPRESA_FAC, ' +
    'ESRETENCIONES_EMPRESA_FAC, ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC, ' +
    'ESIVA_RECARGO_CLIENTE_FAC, ESIVA_EXENTO_CLIENTE_FAC, ' +
    'ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC, ESRETENCIONES_CLIENTE_FAC, ' +
    'ESINTRACOMUNITARIO_CLIENTE_FAC, ESIRPF_IMP_INCL_ZONA_IVA_FAC, ' +
    'ESAPLICA_RE_ZONA_IVA_FAC, ESIVAAGRICOLA_ZONA_IVA_FAC, ' +
    'CODIGO_IVA_FAC, TIPO_OPER_VFACTU_FAC, ESVENTA_ACTIVO_FIJO_FAC, ' +
    'PORCENTAJE_IVAN_FAC, ' +
    'PORCENTAJE_IVAR_FAC, PORCENTAJE_IVAS_FAC, PORCENTAJE_IVAE_FAC, ' +
    'PORCENTAJE_REN_FAC, PORCENTAJE_RER_FAC, PORCENTAJE_RES_FAC, ' +
    'PORCENTAJE_REE_FAC, PORCENTAJE_RETENCION_FAC, ' +
    'PORCENTAJE_DTO_COMERCIAL_FAC, PORCENTAJE_DTO_FINANCIERO_FAC';
  CAMPOS_IMPORTES_TICKETS =
    'TOTAL_IVAN_FAC, TOTAL_REN_FAC, TOTAL_BASEI_IVAN_FAC, ' +
    'TOTAL_IVAR_FAC, TOTAL_RER_FAC, TOTAL_BASEI_IVAR_FAC, ' +
    'TOTAL_IVAS_FAC, TOTAL_RES_FAC, TOTAL_BASEI_IVAS_FAC, ' +
    'TOTAL_IVAE_FAC, TOTAL_REE_FAC, TOTAL_BASEI_IVAE_FAC, ' +
    'TOTAL_BASES_FAC, TOTAL_IMPUESTOS_FAC, TOTAL_RETENCION_FAC, ' +
    'TOTAL_LIQUIDO_FAC, TOTAL_DTO_COMERCIAL_FAC, TOTAL_DTO_FINANCIERO_FAC';
  SQL_CONSULTAR_CLIENTES =
    'SELECT CODIGO_CLI_CLI AS `Código`, ' +
    'RAZON_SOCIAL_CLI AS `Razón Social`, NIF_CLI AS `NIF Cliente`, ' +
    'MOVIL_CLI AS `Teléfono Cliente`, POBLACION_CLI AS `Población` ' +
    'FROM fza_clientes WHERE ESACTIVO_CLI = ''S'' ' +
    'ORDER BY RAZON_SOCIAL_CLI';
  SQL_CONSULTAR_CLIENTE =
    'SELECT RAZON_SOCIAL_CLI, NIF_CLI, CODIGO_PAI_CLI, NOMBRE_PAI_CLI ' +
    'FROM fza_clientes WHERE CODIGO_CLI_CLI = :CLIENTE';
  SQL_INSERTAR_CABECERA =
    'INSERT INTO fza_facturas ' +
    '(NUMERO_FAC, SERIE_FAC, FECHA_FAC, TIPO_FAC, FASE_FAC, ' +
    'ESCONSOLIDADA_FAC, CODIGO_EMP_FAC, RAZON_SOCIAL_EMPRESA_FAC, ' +
    'NIF_EMPRESA_FAC, MOVIL_EMPRESA_FAC, EMAIL_EMPRESA_FAC, ' +
    'DIRECCION1_EMPRESA_FAC, DIRECCION2_EMPRESA_FAC, ' +
    'POBLACION_EMPRESA_FAC, PROVINCIA_EMPRESA_FAC, ' +
    'NOMBRE_PAI_EMPRESA_FAC, CODIGO_PAI_EMPRESA_FAC, ' +
    'CODIGO_POSTAL_EMPRESA_FAC, ESRETENCIONES_EMPRESA_FAC, ' +
    'GRUPO_ZONA_IVA_EMPRESA_FAC, ' +
    'ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC, ' +
    'CODIGO_CLI_FAC, RAZON_SOCIAL_CLIENTE_FAC, NIF_CLIENTE_FAC, ' +
    'MOVIL_CLIENTE_FAC, EMAIL_CLIENTE_FAC, ' +
    'DIRECCION1_CLIENTE_FAC, DIRECCION2_CLIENTE_FAC, ' +
    'POBLACION_CLIENTE_FAC, PROVINCIA_CLIENTE_FAC, ' +
    'CODIGO_POSTAL_CLIENTE_FAC, NOMBRE_PAI_CLIENTE_FAC, ' +
    'CODIGO_PAI_CLIENTE_FAC, CODIGO_OFICINA_CONTABLE_FAC, ' +
    'CODIGO_ORGANO_GESTOR_FAC, CODIGO_UNIDAD_TRAMITADORA_FAC, ' +
    'ESIVA_RECARGO_CLIENTE_FAC, ESIVA_EXENTO_CLIENTE_FAC, ' +
    'ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC, ' +
    'ESRETENCIONES_CLIENTE_FAC, TARIFA_ARTICULO_CLIENTE_FAC, ' +
    'ESIMP_INCL_TARIFA_CLIENTE_FAC, ESINTRACOMUNITARIO_CLIENTE_FAC, ' +
    'ESIRPF_IMP_INCL_ZONA_IVA_FAC, ESAPLICA_RE_ZONA_IVA_FAC, ' +
    'ESIVAAGRICOLA_ZONA_IVA_FAC, PALABRA_REPORTS_ZONA_IVA_FAC, ' +
    'CODIGO_IVA_FAC, TIPO_OPER_VFACTU_FAC, ESVENTA_ACTIVO_FIJO_FAC, ' +
    'PORCENTAJE_IVAN_FAC, TOTAL_IVAN_FAC, PORCENTAJE_REN_FAC, ' +
    'TOTAL_REN_FAC, TOTAL_BASEI_IVAN_FAC, ' +
    'PORCENTAJE_IVAR_FAC, TOTAL_IVAR_FAC, PORCENTAJE_RER_FAC, ' +
    'TOTAL_RER_FAC, TOTAL_BASEI_IVAR_FAC, ' +
    'PORCENTAJE_IVAS_FAC, TOTAL_IVAS_FAC, PORCENTAJE_RES_FAC, ' +
    'TOTAL_RES_FAC, TOTAL_BASEI_IVAS_FAC, ' +
    'PORCENTAJE_IVAE_FAC, TOTAL_IVAE_FAC, PORCENTAJE_REE_FAC, ' +
    'TOTAL_REE_FAC, TOTAL_BASEI_IVAE_FAC, ' +
    'TOTAL_BASES_FAC, TOTAL_IMPUESTOS_FAC, FORMA_PAGO_FAC, ' +
    'PORCENTAJE_RETENCION_FAC, TOTAL_RETENCION_FAC, TOTAL_LIQUIDO_FAC, ' +
    'TEXTO_LEGAL_CLIENTE_FAC, TEXTO_LEGAL_EMPRESA_FAC, ' +
    'COMENTARIOS_FAC, CONTADOR_LINEAS_FAC, ESCREARARTICULOS_FAC, ' +
    'PORCENTAJE_DTO_COMERCIAL_FAC, TOTAL_DTO_COMERCIAL_FAC, ' +
    'PORCENTAJE_DTO_FINANCIERO_FAC, TOTAL_DTO_FINANCIERO_FAC, ' +
    'ESDESCRIPCIONES_AMP_FAC, ESFECHADEENTREGA_FAC, ' +
    'INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :NUMERO, :SERIE, :FECHA, ''NORMAL'', ''BORRADOR'', ''N'', ' +
    't.CODIGO_EMP_FAC, t.RAZON_SOCIAL_EMPRESA_FAC, t.NIF_EMPRESA_FAC, ' +
    't.MOVIL_EMPRESA_FAC, t.EMAIL_EMPRESA_FAC, ' +
    't.DIRECCION1_EMPRESA_FAC, t.DIRECCION2_EMPRESA_FAC, ' +
    't.POBLACION_EMPRESA_FAC, t.PROVINCIA_EMPRESA_FAC, ' +
    't.NOMBRE_PAI_EMPRESA_FAC, t.CODIGO_PAI_EMPRESA_FAC, ' +
    't.CODIGO_POSTAL_EMPRESA_FAC, t.ESRETENCIONES_EMPRESA_FAC, ' +
    't.GRUPO_ZONA_IVA_EMPRESA_FAC, ' +
    't.ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC, ' +
    'c.CODIGO_CLI_CLI, c.RAZON_SOCIAL_CLI, c.NIF_CLI, c.MOVIL_CLI, ' +
    'c.EMAIL_CLI, c.DIRECCION1_CLI, c.DIRECCION2_CLI, ' +
    'c.POBLACION_CLI, c.PROVINCIA_CLI, c.CODIGO_POSTAL_CLI, ' +
    'c.NOMBRE_PAI_CLI, c.CODIGO_PAI_CLI, ' +
    'c.CODIGO_OFICINA_CONTABLE_CLI, c.CODIGO_ORGANO_GESTOR_CLI, ' +
    'c.CODIGO_UNIDAD_TRAMITADORA_CLI, ' +
    't.ESIVA_RECARGO_CLIENTE_FAC, t.ESIVA_EXENTO_CLIENTE_FAC, ' +
    't.ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC, ' +
    't.ESRETENCIONES_CLIENTE_FAC, t.TARIFA_ARTICULO_CLIENTE_FAC, ' +
    't.ESIMP_INCL_TARIFA_CLIENTE_FAC, ' +
    't.ESINTRACOMUNITARIO_CLIENTE_FAC, ' +
    't.ESIRPF_IMP_INCL_ZONA_IVA_FAC, t.ESAPLICA_RE_ZONA_IVA_FAC, ' +
    't.ESIVAAGRICOLA_ZONA_IVA_FAC, t.PALABRA_REPORTS_ZONA_IVA_FAC, ' +
    't.CODIGO_IVA_FAC, t.TIPO_OPER_VFACTU_FAC, t.ESVENTA_ACTIVO_FIJO_FAC, ' +
    't.PORCENTAJE_IVAN_FAC, t.TOTAL_IVAN_FAC, ' +
    't.PORCENTAJE_REN_FAC, t.TOTAL_REN_FAC, t.TOTAL_BASEI_IVAN_FAC, ' +
    't.PORCENTAJE_IVAR_FAC, t.TOTAL_IVAR_FAC, ' +
    't.PORCENTAJE_RER_FAC, t.TOTAL_RER_FAC, t.TOTAL_BASEI_IVAR_FAC, ' +
    't.PORCENTAJE_IVAS_FAC, t.TOTAL_IVAS_FAC, ' +
    't.PORCENTAJE_RES_FAC, t.TOTAL_RES_FAC, t.TOTAL_BASEI_IVAS_FAC, ' +
    't.PORCENTAJE_IVAE_FAC, t.TOTAL_IVAE_FAC, ' +
    't.PORCENTAJE_REE_FAC, t.TOTAL_REE_FAC, t.TOTAL_BASEI_IVAE_FAC, ' +
    't.TOTAL_BASES_FAC, t.TOTAL_IMPUESTOS_FAC, ' +
    'COALESCE(NULLIF(:FORMA_PAGO, ''''), t.FORMA_PAGO_FAC), ' +
    't.PORCENTAJE_RETENCION_FAC, t.TOTAL_RETENCION_FAC, ' +
    't.TOTAL_LIQUIDO_FAC, t.TEXTO_LEGAL_CLIENTE_FAC, ' +
    't.TEXTO_LEGAL_EMPRESA_FAC, ' +
    'TRIM(CONCAT(IFNULL(t.COMENTARIOS_FAC, ''''), :COMENTARIO)), ' +
    't.CONTADOR_LINEAS_FAC, t.ESCREARARTICULOS_FAC, ' +
    't.PORCENTAJE_DTO_COMERCIAL_FAC, t.TOTAL_DTO_COMERCIAL_FAC, ' +
    't.PORCENTAJE_DTO_FINANCIERO_FAC, t.TOTAL_DTO_FINANCIERO_FAC, ' +
    't.ESDESCRIPCIONES_AMP_FAC, t.ESFECHADEENTREGA_FAC, ' +
    'NOW(), NOW(), :USUARIO, :USUARIO FROM fza_facturas t ' +
    'JOIN fza_clientes c ON c.CODIGO_CLI_CLI = :CLIENTE ' +
    'WHERE t.SERIE_FAC = :STICKET AND t.NUMERO_FAC = :NTICKET';
  SQL_FORMA_PAGO_TICKET =
    'SELECT FORMA_PAGO_FAC FROM fza_facturas ' +
    ' WHERE SERIE_FAC = :SERIE AND NUMERO_FAC = :NUMERO';
  SQL_FECHA_TICKET =
    'SELECT FECHA_FAC FROM fza_facturas ' +
    ' WHERE SERIE_FAC = :SERIE AND NUMERO_FAC = :NUMERO';
  SQL_DIGITOS_CONTADOR =
    'SELECT COALESCE(MAX(NUM_DIGITOS_CON), 0) AS DIGITOS ' +
    '  FROM fza_contadores ' +
    ' WHERE TIPO_DOC_CON = ''FC'' AND EMPRESA_CON IN (:EMPRESA, ''-'') ' +
    '   AND SERIE_CON = :SERIE';
  SQL_EXISTE_FACTURA =
    'SELECT 1 FROM fza_facturas ' +
    ' WHERE SERIE_FAC = :SERIE AND NUMERO_FAC = :NUMERO';
  // Copia también el SKU, la variación y los atributos de la línea del
  // ticket: sin ellos la factura sustitutiva no dice qué color o talla se
  // vendió (FZ-ISSUE-124). No se copian almacén, caja, operación ni
  // movimiento: la factura sustitutiva no mueve stock.
  SQL_INSERTAR_LINEAS =
    'INSERT INTO fza_facturas_lineas ' +
    '(NUMERO_FAC_FACLIN, SERIE_FAC_FACLIN, LINEA_FACLIN, ' +
    'CODIGO_ART_FACLIN, CODIGO_UNIDAD_FACLIN, ' +
    'TIPO_CANTIDAD_ARTICULO_FACLIN, ' +
    'ESIMP_INCL_TARIFA_FACLIN, TIPO_IVA_ARTICULO_FACLIN, ' +
    'DESCRIPCION_ARTICULO_FACLIN, DESCRIPCION_VARIACION_FACLIN, ' +
    'CANTIDAD_FACLIN, ' +
    'PRECIO_SALIDA_FACLIN, PORCENTAJE_DTO_FACLIN, PRECIO_DTO_FACLIN, ' +
    'PRECIO_VENTA_SIVA_ARTICULO_FACLIN, PORCENTAJE_IVA_FACLIN, ' +
    'PRECIO_VENTA_CIVA_ARTICULO_FACLIN, TOTAL_FACLIN, ' +
    'TOTAL_FAC_SIVA_FACLIN, ' +
    'ATTR1_VALOR_FACLIN, ATTR1_NOMBRE_FACLIN, ' +
    'ATTR2_VALOR_FACLIN, ATTR2_NOMBRE_FACLIN, ' +
    'ATTR3_VALOR_FACLIN, ATTR3_NOMBRE_FACLIN, ' +
    'ATTR4_VALOR_FACLIN, ATTR4_NOMBRE_FACLIN, ' +
    'ATTR5_VALOR_FACLIN, ATTR5_NOMBRE_FACLIN, ' +
    'NUM_ATRIBUTOS_FACLIN, ' +
    'INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :NUMERO, :SERIE, LINEA_FACLIN, CODIGO_ART_FACLIN, ' +
    'CODIGO_UNIDAD_FACLIN, ' +
    'TIPO_CANTIDAD_ARTICULO_FACLIN, ESIMP_INCL_TARIFA_FACLIN, ' +
    'TIPO_IVA_ARTICULO_FACLIN, DESCRIPCION_ARTICULO_FACLIN, ' +
    'DESCRIPCION_VARIACION_FACLIN, ' +
    'CANTIDAD_FACLIN, ' +
    'PRECIO_SALIDA_FACLIN, PORCENTAJE_DTO_FACLIN, PRECIO_DTO_FACLIN, ' +
    'PRECIO_VENTA_SIVA_ARTICULO_FACLIN, ' +
    'PORCENTAJE_IVA_FACLIN, PRECIO_VENTA_CIVA_ARTICULO_FACLIN, ' +
    'TOTAL_FACLIN, TOTAL_FAC_SIVA_FACLIN, ' +
    'ATTR1_VALOR_FACLIN, ATTR1_NOMBRE_FACLIN, ' +
    'ATTR2_VALOR_FACLIN, ATTR2_NOMBRE_FACLIN, ' +
    'ATTR3_VALOR_FACLIN, ATTR3_NOMBRE_FACLIN, ' +
    'ATTR4_VALOR_FACLIN, ATTR4_NOMBRE_FACLIN, ' +
    'ATTR5_VALOR_FACLIN, ATTR5_NOMBRE_FACLIN, ' +
    'NUM_ATRIBUTOS_FACLIN, ' +
    'NOW(), NOW(), :USUARIO, :USUARIO ' +
    'FROM fza_facturas_lineas WHERE SERIE_FAC_FACLIN = :STICKET ' +
    'AND NUMERO_FAC_FACLIN = :NTICKET';
  // F-LOTEC: el lote o el número de serie (IMEI) viajan con la línea: la
  // factura nominativa es la que respalda la garantía (FZ-ISSUE-333). Sin
  // los interruptores de trazabilidad las columnas pueden no existir.
  CAMPOS_LOTE_LINEA_TICKET = 'LOTE_FACLIN, FECHA_CADUCIDAD_FACLIN, ';
  ANCLA_CAMPOS_LOTE_TICKET = 'NUM_ATRIBUTOS_FACLIN, ';
  SQL_ENLAZAR_TICKET =
    'UPDATE fza_facturas SET SERIE_FAC_ABONO_FAC = :SERIE, ' +
    'NUMERO_FAC_ABONO_FAC = :NUMERO, INSTANTE_MODIF = NOW(), ' +
    'USUARIO_MODIF = :USUARIO WHERE SERIE_FAC = :STICKET ' +
    'AND NUMERO_FAC = :NTICKET';
  // Préstamos: depósitos PENDIENTES (no apartados) del cliente prestados en
  // el período. El precio del depósito lleva IVA, como en la caja.
  SQL_PRESTAMOS_PERIODO =
    'SELECT D.ID_DEPOSITO_DEP, D.FECHA_CREACION_DEP, D.CODIGO_ART_DEP, ' +
    'D.CODIGO_UNIDAD_DEP, ' +
    'COALESCE(A.DESCRIPCION_ART, D.CODIGO_ART_DEP) AS DESCRIPCION, ' +
    'COALESCE(D.CANTIDAD_PENDIENTE_DEP, 1) AS CANTIDAD, ' +
    'COALESCE(D.PRECIO_VENTA_DEP, 0) AS PRECIO, ' +
    'COALESCE(D.IMPORTE_ANTICIPO_DEP, 0) AS ANTICIPO, D.INSTANTE_MODIF ' +
    'FROM fza_depositos_cliente D ' +
    'LEFT JOIN fza_articulos A ON A.CODIGO_ART_ART = D.CODIGO_ART_DEP ' +
    'WHERE D.CODIGO_EMP_DEP = :EMPRESA AND D.CODIGO_CLI_DEP = :CLIENTE ' +
    'AND D.ESTADO_DEP = ''PENDIENTE'' ' +
    'AND COALESCE(D.ESAPARTADO_DEP, ''N'') <> ''S'' ' +
    'AND D.FECHA_CREACION_DEP >= :DESDE AND D.FECHA_CREACION_DEP < :HASTA ';
  SQL_ORDEN_PRESTAMOS =
    'ORDER BY D.FECHA_CREACION_DEP, D.ID_DEPOSITO_DEP';
  // Cabecera F1 desde empresa y cliente, con los tipos de IVA vigentes en
  // la fecha de la factura (como la factura interna TA). Sin retención: es
  // venta de mercancía, igual que los tickets que sustituye la F3.
  SQL_INSERTAR_CABECERA_PRESTAMOS =
    'INSERT INTO fza_facturas (' +
    'NUMERO_FAC, SERIE_FAC, FECHA_FAC, ESCONSOLIDADA_FAC, ' +
    'TIPO_FAC, ESMUEVE_STOCK_FAC, FASE_FAC, CODIGO_EMP_FAC, ' +
    'CODIGO_ALM_FAC, RAZON_SOCIAL_EMPRESA_FAC, NIF_EMPRESA_FAC, ' +
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
    'CODIGO_OFICINA_CONTABLE_FAC, CODIGO_ORGANO_GESTOR_FAC, ' +
    'CODIGO_UNIDAD_TRAMITADORA_FAC, ' +
    'CODIGO_IVA_FAC, ESIVA_RECARGO_CLIENTE_FAC, ' +
    'ESIVA_EXENTO_CLIENTE_FAC, ' +
    'ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC, ' +
    'ESRETENCIONES_CLIENTE_FAC, ESIMP_INCL_TARIFA_CLIENTE_FAC, ' +
    'ESINTRACOMUNITARIO_CLIENTE_FAC, ESIRPF_IMP_INCL_ZONA_IVA_FAC, ' +
    'ESAPLICA_RE_ZONA_IVA_FAC, ESIVAAGRICOLA_ZONA_IVA_FAC, ' +
    'PALABRA_REPORTS_ZONA_IVA_FAC, PORCENTAJE_IVAN_FAC, ' +
    'PORCENTAJE_REN_FAC, PORCENTAJE_IVAR_FAC, PORCENTAJE_RER_FAC, ' +
    'PORCENTAJE_IVAS_FAC, PORCENTAJE_RES_FAC, PORCENTAJE_IVAE_FAC, ' +
    'PORCENTAJE_REE_FAC, PORCENTAJE_RETENCION_FAC, FORMA_PAGO_FAC, ' +
    'TEXTO_LEGAL_EMPRESA_FAC, COMENTARIOS_FAC, CONTADOR_LINEAS_FAC, ' +
    'ESCREARARTICULOS_FAC, ESDESCRIPCIONES_AMP_FAC, ' +
    'ESFECHADEENTREGA_FAC, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :NUMERO, :SERIE, :FECHA_FACTURA, ''N'', ''NORMAL'', ''S'', ' +
    '''BORRADOR'', E.CODIGO_EMP_EMP, :ALMACEN, E.RAZON_SOCIAL_EMP, ' +
    'E.NIF_EMP, E.MOVIL_EMP, E.EMAIL_EMP, E.DIRECCION1_EMP, ' +
    'E.DIRECCION2_EMP, E.POBLACION_EMP, E.PROVINCIA_EMP, ' +
    'E.CODIGO_PAI_EMP, E.NOMBRE_PAI_EMP, E.CODIGO_POSTAL_EMP, ' +
    'E.ESRETENCIONES_EMP, E.GRUPO_ZONA_IVA_EMP, ' +
    'E.ESREGIMENESPECIALAGRICOLA_EMP, ' +
    'C.CODIGO_CLI_CLI, C.RAZON_SOCIAL_CLI, ' +
    'C.NIF_CLI, C.MOVIL_CLI, C.EMAIL_CLI, C.DIRECCION1_CLI, ' +
    'C.DIRECCION2_CLI, C.POBLACION_CLI, C.PROVINCIA_CLI, ' +
    'C.CODIGO_POSTAL_CLI, C.CODIGO_PAI_CLI, C.NOMBRE_PAI_CLI, ' +
    'C.CODIGO_OFICINA_CONTABLE_CLI, C.CODIGO_ORGANO_GESTOR_CLI, ' +
    'C.CODIGO_UNIDAD_TRAMITADORA_CLI, ' +
    'I.CODIGO_IVA, COALESCE(C.ESIVA_RECARGO_CLI, ''N''), ' +
    'COALESCE(C.ESIVA_EXENTO_CLI, ''N''), ' +
    'COALESCE(C.ESREGIMENESPECIALAGRICOLA_CLI, ''N''), ' +
    '''N'', ''S'', ' +
    'COALESCE(C.ESINTRACOMUNITARIO_CLI, ''N''), ' +
    'COALESCE(G.ESIRPF_IMP_INCL_IVA_IVAGRP, ''N''), ' +
    'COALESCE(G.ESAPLICA_RE_IVA_IVAGRP, ''S''), ' +
    'COALESCE(G.ESIVAAGRICOLA_IVA_IVAGRP, ''N''), ' +
    'COALESCE(G.PALABRA_REPORTS_IVA_IVAGRP, ''IVA''), ' +
    'I.PORCENTAJE_NORMAL_IVA, I.PORCENTAJE_NORMAL_RE_IVA, ' +
    'I.PORCENTAJE_REDUCIDO_IVA, I.PORCENTAJE_REDUCIDO_RE_IVA, ' +
    'I.PORCENTAJE_SUPERREDUCIDO_IVA, ' +
    'I.PORCENTAJE_SUPERREDUCIDO_RE_IVA, I.PORCENTAJE_EXENTO_IVA, ' +
    'I.PORCENTAJE_EXENTO_RE_IVA, 0, ' +
    'COALESCE(NULLIF(:FORMA_PAGO, ''''), C.CODIGO_FP_CLI), ' +
    'E.TEXTO_LEGAL_FACTURA_EMP, :COMENTARIO, ' +
    '''0000'', ''N'', ''N'', ''N'', NOW(), NOW(), :USUARIO, :USUARIO ' +
    'FROM fza_empresas E ' +
    'JOIN fza_clientes C ON C.CODIGO_CLI_CLI = :CLIENTE ' +
    'JOIN fza_ivas I ON I.IVA_IVAGRP = E.GRUPO_ZONA_IVA_EMP ' +
    ' AND I.FECHA_DESDE_IVA <= :FECHA_FACTURA ' +
    ' AND (I.FECHA_HASTA_IVA IS NULL ' +
    '      OR I.FECHA_HASTA_IVA >= :FECHA_FACTURA) ' +
    'LEFT JOIN fza_ivas_grupos G ON G.IVA_IVAGRP = I.IVA_IVAGRP ' +
    'WHERE E.CODIGO_EMP_EMP = :EMPRESA ' +
    'ORDER BY I.FECHA_DESDE_IVA DESC LIMIT 1';
  // Línea de la prenda prestada con el mismo reparto que la caja al cobrar
  // el depósito (IncorporarPrendaDeposito). El almacén es el de depósitos:
  // de ahí sale el stock al consolidar.
  SQL_INSERTAR_LINEA_PRESTAMO =
    'INSERT INTO fza_facturas_lineas (' +
    'NUMERO_FAC_FACLIN, SERIE_FAC_FACLIN, CODIGO_EMP_FACLIN, ' +
    'LINEA_FACLIN, CODIGO_ART_FACLIN, CODIGO_UNIDAD_FACLIN, ' +
    'CODIGO_FAM_FACLIN, TIPO_ARTICULO_FACLIN, ' +
    'TIPO_CANTIDAD_ARTICULO_FACLIN, CANTIDAD_FACLIN, ' +
    'DESCRIPCION_ARTICULO_FACLIN, DESCRIPCION_VARIACION_FACLIN, ' +
    'ESIMP_INCL_TARIFA_FACLIN, PRECIO_SALIDA_FACLIN, ' +
    'PORCENTAJE_DTO_FACLIN, PRECIO_DTO_FACLIN, ' +
    'PRECIO_VENTA_SIVA_ARTICULO_FACLIN, TIPO_IVA_ARTICULO_FACLIN, ' +
    'PORCENTAJE_IVA_FACLIN, PRECIO_VENTA_CIVA_ARTICULO_FACLIN, ' +
    'TOTAL_FACLIN, TOTAL_FAC_SIVA_FACLIN, CODIGO_ALM_FACLIN, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :NUMERO, :SERIE, D.CODIGO_EMP_DEP, LPAD(:LINEA, 4, ''0''), ' +
    'D.CODIGO_ART_DEP, D.CODIGO_UNIDAD_DEP, A.CODIGO_FAM_ART, ' +
    'COALESCE(NULLIF(A.TIPO_ART, ''''), ''ESTANDAR''), ' +
    'COALESCE(A.TIPO_CANTIDAD_ART, ''Uds''), ' +
    'COALESCE(D.CANTIDAD_PENDIENTE_DEP, 1), ' +
    'LEFT(COALESCE(A.DESCRIPCION_ART, D.CODIGO_ART_DEP), 100), ' +
    'CASE WHEN D.CODIGO_UNIDAD_DEP LIKE CONCAT(D.CODIGO_ART_DEP, ''/%'') ' +
    ' THEN SUBSTRING(D.CODIGO_UNIDAD_DEP, ' +
    '  CHAR_LENGTH(D.CODIGO_ART_DEP) + 2) END, ' +
    '''S'', D.PRECIO_VENTA_DEP, 0, 0, ' +
    'D.PRECIO_VENTA_DEP / (1 + COALESCE(D.PORCENTAJE_IVA_DEP, 0) / 100), ' +
    'COALESCE(D.TIPO_IVA_DEP, ''N''), COALESCE(D.PORCENTAJE_IVA_DEP, 0), ' +
    'D.PRECIO_VENTA_DEP, ' +
    'ROUND(D.PRECIO_VENTA_DEP * COALESCE(D.CANTIDAD_PENDIENTE_DEP, 1), 2), ' +
    'ROUND(D.PRECIO_VENTA_DEP * COALESCE(D.CANTIDAD_PENDIENTE_DEP, 1) / ' +
    ' (1 + COALESCE(D.PORCENTAJE_IVA_DEP, 0) / 100), 2), :ALMACEN, ' +
    'NOW(), NOW(), :USUARIO, :USUARIO ' +
    'FROM fza_depositos_cliente D ' +
    'LEFT JOIN fza_articulos A ON A.CODIGO_ART_ART = D.CODIGO_ART_DEP ' +
    'WHERE D.ID_DEPOSITO_DEP = :ID';
  // El anticipo ya se facturó al prestar: se descuenta como la caja
  // ('Abono a cuenta'). Sin SKU, para que no genere movimiento de stock.
  SQL_INSERTAR_LINEA_ANTICIPO_PRESTAMO =
    'INSERT INTO fza_facturas_lineas (' +
    'NUMERO_FAC_FACLIN, SERIE_FAC_FACLIN, CODIGO_EMP_FACLIN, ' +
    'LINEA_FACLIN, TIPO_ARTICULO_FACLIN, CANTIDAD_FACLIN, ' +
    'DESCRIPCION_ARTICULO_FACLIN, ESIMP_INCL_TARIFA_FACLIN, ' +
    'PRECIO_SALIDA_FACLIN, PORCENTAJE_DTO_FACLIN, PRECIO_DTO_FACLIN, ' +
    'PRECIO_VENTA_SIVA_ARTICULO_FACLIN, TIPO_IVA_ARTICULO_FACLIN, ' +
    'PORCENTAJE_IVA_FACLIN, PRECIO_VENTA_CIVA_ARTICULO_FACLIN, ' +
    'TOTAL_FACLIN, TOTAL_FAC_SIVA_FACLIN, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :NUMERO, :SERIE, D.CODIGO_EMP_DEP, LPAD(:LINEA, 4, ''0''), ' +
    '''SERVICIO'', -1, ' +
    'LEFT(CONCAT(''Abono a cuenta '', D.CODIGO_UNIDAD_DEP), 100), ' +
    '''S'', D.IMPORTE_ANTICIPO_DEP, 0, 0, ' +
    'D.IMPORTE_ANTICIPO_DEP / ' +
    ' (1 + COALESCE(D.PORCENTAJE_IVA_DEP, 0) / 100), ' +
    'COALESCE(D.TIPO_IVA_DEP, ''N''), COALESCE(D.PORCENTAJE_IVA_DEP, 0), ' +
    'D.IMPORTE_ANTICIPO_DEP, -ROUND(D.IMPORTE_ANTICIPO_DEP, 2), ' +
    '-ROUND(D.IMPORTE_ANTICIPO_DEP / ' +
    ' (1 + COALESCE(D.PORCENTAJE_IVA_DEP, 0) / 100), 2), ' +
    'NOW(), NOW(), :USUARIO, :USUARIO ' +
    'FROM fza_depositos_cliente D WHERE D.ID_DEPOSITO_DEP = :ID';
  // Cierre como en la caja (CerrarDepositoCliente): la cantidad no se toca;
  // la entrega es la fecha de la factura.
  SQL_CERRAR_PRESTAMO =
    'UPDATE fza_depositos_cliente SET ESTADO_DEP = ''CERRADO'', ' +
    'FECHA_ENTREGA_DEP = :FECHA, USUARIO_MODIF = :USUARIO, ' +
    'INSTANTE_MODIF = NOW() ' +
    'WHERE ID_DEPOSITO_DEP = :ID AND ESTADO_DEP = ''PENDIENTE''';
  // Lo mismo que sumó PRC_FZA_DEPOSITOS_INSERT al prestar.
  SQL_DESCONTAR_DEUDA_PRESTAMO =
    'UPDATE fza_clientes c JOIN fza_depositos_cliente d ' +
    'ON d.ID_DEPOSITO_DEP = :ID ' +
    'SET c.TOTAL_DEUDA_CLI = COALESCE(c.TOTAL_DEUDA_CLI, 0) - ' +
    '(COALESCE(d.PRECIO_VENTA_DEP, 0) * ' +
    'COALESCE(d.CANTIDAD_PENDIENTE_DEP, 1) - ' +
    'COALESCE(d.IMPORTE_ANTICIPO_DEP, 0)) ' +
    'WHERE c.CODIGO_CLI_CLI = d.CODIGO_CLI_DEP';
  SQL_EFECTOS_PENDIENTES =
    'SELECT NUMERO_EFV, IMPORTE_PENDIENTE_EFV FROM fza_efectos_venta ' +
    'WHERE SERIE_FAC_EFV = :SERIE AND NUMERO_FAC_EFV = :NUMERO ' +
    'AND ABS(COALESCE(IMPORTE_PENDIENTE_EFV, 0)) > 0 ORDER BY NUMERO_EFV';

function SqlInsertarLineasTicket(AConLotes: Boolean): string;
begin
  Result := SQL_INSERTAR_LINEAS;
  // La lista de columnas y la del SELECT llevan la misma ancla.
  if AConLotes then
    Result := StringReplace(Result, ANCLA_CAMPOS_LOTE_TICKET,
      ANCLA_CAMPOS_LOTE_TICKET + CAMPOS_LOTE_LINEA_TICKET, [rfReplaceAll]);
end;

type
  TConsultaClientesFacturacionTicketUniDAC = class(
    TInterfacedObject,
    IConsultaClientesFacturacionTicket)
  private
    FConsulta: TUniQuery;
  public
    constructor Create(AConsulta: TUniQuery);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;

  TServicioFacturacionTicketUniDAC = class(
    TInterfacedObject,
    IServicioFacturacionTicket)
  private
    FConexion: TUniConnection;
    FParametrosApp: IParametrosAplicacion;
    FServicioEmision: IServicioEmisionFiscal;
    FServicioCola: IServicioVerifactuCola;
    function LeerCabeceraTicketRevision(
      AConsulta: TUniQuery): TTicketFacturacion;
    function DescribirLineaTicketRevision(AConsulta: TUniQuery): string;
    function LeerTicketsPeriodo(const AEmpresa, ACliente: string;
      ADesde, AHasta: TDateTime; ASinCliente: Boolean): TTicketsFacturacion;
    function ObtenerNumero(
      const ASolicitud: TSolicitudFacturacionTicket): string;
    function NumeroManual(
      const ASolicitud: TSolicitudFacturacionTicket): string;
    function ReservarNumeroContador(
      const ASolicitud: TSolicitudFacturacionTicket): string;
    procedure EjecutarSqlFactura(
      AConsulta: TUniQuery;
      const ASql: string;
      const ASolicitud: TSolicitudFacturacionTicket;
      const ANumero: string);
    procedure CargarTicketPeriodo(AConsulta: TUniQuery;
      const ASolicitud: TSolicitudFacturacionTicket;
      const ATicket: TTicketFacturacion);
    procedure ValidarTicketPeriodo(AConsulta: TUniQuery;
      const ASolicitud: TSolicitudFacturacionTicket;
      const ATicket: TTicketFacturacion);
    procedure BloquearTickets(const ASolicitud: TSolicitudFacturacionTicket);
    procedure ComprobarEsquemaPeriodo;
    procedure BloquearTicketIndividual(
      const ASolicitud: TSolicitudFacturacionTicket);
    procedure AcumularImportesTicket(AConsulta: TUniQuery;
      const ASolicitud: TSolicitudFacturacionTicket; const ANumero: string);
    procedure InsertarRotuloTicket(AConsulta: TUniQuery;
      const ASolicitud: TSolicitudFacturacionTicket; const ANumero: string;
      const ATicket: TTicketFacturacion; ALinea: Integer);
    procedure CopiarLineasTicketPeriodo(AConsulta: TUniQuery;
      const ASolicitud: TSolicitudFacturacionTicket; const ANumero: string;
      ADesplazamiento: Integer);
    function UltimaLineaFactura(const ASerie, ANumero: string): Integer;
    procedure CopiarTickets(const ASolicitud: TSolicitudFacturacionTicket;
      const ANumero: string);
    function LeerPrestamo(AConsulta: TUniQuery): TPrestamoFacturacion;
    procedure ValidarFechasPrestamos(
      const ASolicitud: TSolicitudFacturacionTicket);
    procedure BloquearPrestamos(
      const ASolicitud: TSolicitudFacturacionTicket);
    function AlmacenDepositos(const AEmpresa: string): string;
    procedure EjecutarSqlPrestamo(AConsulta: TUniQuery; const ASql: string;
      const ASolicitud: TSolicitudFacturacionTicket; const ANumero,
      AAlmacen, AIdDeposito: string; ALinea: Integer);
    procedure InsertarCabeceraPrestamos(AConsulta: TUniQuery;
      const ASolicitud: TSolicitudFacturacionTicket;
      const ANumero, AAlmacen: string);
    function InsertarLineasPrestamos(AConsulta: TUniQuery;
      const ASolicitud: TSolicitudFacturacionTicket;
      const ANumero, AAlmacen: string): Integer;
    procedure CerrarPrestamos(AConsulta: TUniQuery;
      const ASolicitud: TSolicitudFacturacionTicket);
    procedure GenerarMovimientosPrestamos(
      const ASolicitud: TSolicitudFacturacionTicket; const ANumero: string);
    procedure CobrarFacturaPrestamos(AConsulta: TUniQuery;
      const ASolicitud: TSolicitudFacturacionTicket; const ANumero: string);
  public
    constructor Create(
      AConexion: TUniConnection;
      const AParametrosApp: IParametrosAplicacion;
      const AServicioEmision: IServicioEmisionFiscal;
      const AServicioCola: IServicioVerifactuCola);
    destructor Destroy; override;
    function ConsultarClientes: IConsultaClientesFacturacionTicket;
    function ConsultarCliente(
      const ACodigoCliente: string): TClienteFacturacionTicket;
    function CrearFactura(
      const ASolicitud: TSolicitudFacturacionTicket): string;
    function FormaPagoTicket(const ASerie, ANumero: string): string;
    function FechaTicket(const ASerie, ANumero: string): TDateTime;
    function ConsultarTicketsPeriodo(const AEmpresa, ACliente: string;
      ADesde, AHasta: TDateTime): TTicketsFacturacion;
    function ConsultarTicketsSinCliente(const AEmpresa: string;
      ADesde, AHasta: TDateTime): TTicketsFacturacion;
    function ConsultarPrestamosPeriodo(const AEmpresa, ACliente: string;
      ADesde, AHasta: TDateTime): TPrestamosFacturacion;
    function CrearFacturaPrestamos(
      const ASolicitud: TSolicitudFacturacionTicket): string;
  end;

constructor TConsultaClientesFacturacionTicketUniDAC.Create(
  AConsulta: TUniQuery);
begin
  inherited Create;
  FConsulta := AConsulta;
end;

destructor TConsultaClientesFacturacionTicketUniDAC.Destroy;
begin
  FreeAndNil(FConsulta);
  inherited;
end;

function TConsultaClientesFacturacionTicketUniDAC.DataSet: TDataSet;
begin
  Result := FConsulta;
end;

constructor TServicioFacturacionTicketUniDAC.Create(
  AConexion: TUniConnection;
  const AParametrosApp: IParametrosAplicacion;
  const AServicioEmision: IServicioEmisionFiscal;
  const AServicioCola: IServicioVerifactuCola);
begin
  inherited Create;
  FConexion := AConexion;
  FParametrosApp := AParametrosApp;
  FServicioEmision := AServicioEmision;
  FServicioCola := AServicioCola;
end;

destructor TServicioFacturacionTicketUniDAC.Destroy;
begin
  FServicioCola := nil;
  FServicioEmision := nil;
  FParametrosApp := nil;
  inherited;
end;

function TServicioFacturacionTicketUniDAC.ConsultarClientes:
  IConsultaClientesFacturacionTicket;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_CONSULTAR_CLIENTES;
    oConsulta.Open;
    Result := TConsultaClientesFacturacionTicketUniDAC.Create(oConsulta);
  except
    FreeAndNil(oConsulta);
    raise;
  end;
end;

function TServicioFacturacionTicketUniDAC.ConsultarCliente(
  const ACodigoCliente: string): TClienteFacturacionTicket;
var
  oConsulta: TUniQuery;
begin
  Result := Default(TClienteFacturacionTicket);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_CONSULTAR_CLIENTE;
    oConsulta.ParamByName('CLIENTE').AsString := ACodigoCliente;
    oConsulta.Open;
    Result.Existe := not oConsulta.IsEmpty;
    if Result.Existe then
    begin
      Result.RazonSocial :=
        oConsulta.FieldByName('RAZON_SOCIAL_CLI').AsString;
      Result.Nif := oConsulta.FieldByName('NIF_CLI').AsString;
      Result.CodigoPais :=
        oConsulta.FieldByName('CODIGO_PAI_CLI').AsString;
      Result.NombrePais :=
        oConsulta.FieldByName('NOMBRE_PAI_CLI').AsString;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TServicioFacturacionTicketUniDAC.FormaPagoTicket(const ASerie,
  ANumero: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_FORMA_PAGO_TICKET;
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      Result := oConsulta.FieldByName('FORMA_PAGO_FAC').AsString;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TServicioFacturacionTicketUniDAC.FechaTicket(const ASerie,
  ANumero: string): TDateTime;
var
  oConsulta: TUniQuery;
begin
  Result := 0;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_FECHA_TICKET;
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      Result := Trunc(oConsulta.FieldByName('FECHA_FAC').AsDateTime);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TServicioFacturacionTicketUniDAC.ConsultarTicketsPeriodo(
  const AEmpresa, ACliente: string;
  ADesde, AHasta: TDateTime): TTicketsFacturacion;
begin
  Result := LeerTicketsPeriodo(AEmpresa, ACliente, ADesde, AHasta, False);
end;

function TServicioFacturacionTicketUniDAC.ConsultarTicketsSinCliente(
  const AEmpresa: string; ADesde, AHasta: TDateTime): TTicketsFacturacion;
begin
  Result := LeerTicketsPeriodo(AEmpresa, '', ADesde, AHasta, True);
end;

function TServicioFacturacionTicketUniDAC.LeerCabeceraTicketRevision(
  AConsulta: TUniQuery): TTicketFacturacion;
begin
  Result := Default(TTicketFacturacion);
  Result.Serie := AConsulta.FieldByName('SERIE_FAC').AsString;
  Result.Numero := AConsulta.FieldByName('NUMERO_FAC').AsString;
  Result.Fecha := AConsulta.FieldByName('FECHA_FAC').AsDateTime;
  Result.Total := AConsulta.FieldByName('TOTAL_LIQUIDO_FAC').AsCurrency;
  Result.InstanteModificacion :=
    AConsulta.FieldByName('INSTANTE_MODIF').AsDateTime;
end;

function TServicioFacturacionTicketUniDAC.DescribirLineaTicketRevision(
  AConsulta: TUniQuery): string;
begin
  Result := '    ' + AConsulta.FieldByName('CANTIDAD_FACLIN').AsString +
    ' x ' + AConsulta.FieldByName('DESCRIPCION_ARTICULO_FACLIN').AsString +
    '    ' + FormatCurr('#,##0.00',
      AConsulta.FieldByName('TOTAL_FACLIN').AsCurrency) + sLineBreak;
end;

function TServicioFacturacionTicketUniDAC.LeerTicketsPeriodo(
  const AEmpresa, ACliente: string; ADesde, AHasta: TDateTime;
  ASinCliente: Boolean): TTicketsFacturacion;
var
  oConsulta: TUniQuery;
  oTicket: TTicketFacturacion;
  iTicket: Integer;
  bNuevo: Boolean;
begin
  Result := nil;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT t.SERIE_FAC, t.NUMERO_FAC, t.FECHA_FAC, ' +
      't.TOTAL_LIQUIDO_FAC, t.INSTANTE_MODIF, l.LINEA_FACLIN, ' +
      'l.DESCRIPCION_ARTICULO_FACLIN, l.CANTIDAD_FACLIN, l.TOTAL_FACLIN ' +
      'FROM fza_facturas t LEFT JOIN fza_facturas_lineas l ' +
      'ON l.SERIE_FAC_FACLIN = t.SERIE_FAC ' +
      'AND l.NUMERO_FAC_FACLIN = t.NUMERO_FAC ' +
      'WHERE t.CODIGO_EMP_FAC = :EMPRESA ' +
      'AND t.FECHA_FAC >= :DESDE AND t.FECHA_FAC < :HASTA ' +
      SQL_TICKET_PENDIENTE;
    if ASinCliente then
      oConsulta.SQL.Add('AND ' + SQL_TICKET_SIN_CLIENTE)
    else
      oConsulta.SQL.Add('AND t.CODIGO_CLI_FAC = :CLIENTE');
    oConsulta.SQL.Add('ORDER BY t.FECHA_FAC, t.SERIE_FAC, ' +
      't.NUMERO_FAC, l.LINEA_FACLIN');
    if not ASinCliente then
      oConsulta.ParamByName('CLIENTE').AsString := ACliente;
    oConsulta.ParamByName('EMPRESA').AsString := AEmpresa;
    oConsulta.ParamByName('DESDE').AsDate := Trunc(ADesde);
    oConsulta.ParamByName('HASTA').AsDate := Trunc(AHasta) + 1;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iTicket := High(Result);
      bNuevo := iTicket < 0;
      if not bNuevo then
        bNuevo := (Result[iTicket].Serie <>
          oConsulta.FieldByName('SERIE_FAC').AsString) or
          (Result[iTicket].Numero <>
          oConsulta.FieldByName('NUMERO_FAC').AsString);
      if bNuevo then
      begin
        oTicket := LeerCabeceraTicketRevision(oConsulta);
        Result := Result + [oTicket];
        iTicket := High(Result);
      end;
      if not oConsulta.FieldByName('LINEA_FACLIN').IsNull then
        Result[iTicket].Detalle := Result[iTicket].Detalle +
          DescribirLineaTicketRevision(oConsulta);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TServicioFacturacionTicketUniDAC.ComprobarEsquemaPeriodo;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT SUM(INDEX_NAME = ''UQ_FACREL_FACTURA_TIPO'') AS ANTERIOR, ' +
      'SUM(INDEX_NAME = ''UQ_FACREL_FACTURA_ORIGEN_TIPO'') AS NUEVO ' +
      'FROM INFORMATION_SCHEMA.STATISTICS ' +
      'WHERE TABLE_SCHEMA = DATABASE() ' +
      'AND TABLE_NAME = ''fza_facturas_relaciones''';
    oConsulta.Open;
    if (oConsulta.FieldByName('ANTERIOR').AsInteger > 0) or
       (oConsulta.FieldByName('NUEVO').AsInteger <> 5) then
      raise Exception.Create(SErrorEsquemaFacturacionSimplificados);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TServicioFacturacionTicketUniDAC.BloquearTicketIndividual(
  const ASolicitud: TSolicitudFacturacionTicket);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := 'SELECT SERIE_FAC FROM fza_facturas ' +
      'WHERE SERIE_FAC = :SERIE AND NUMERO_FAC = :NUMERO FOR UPDATE';
    oConsulta.ParamByName('SERIE').AsString := ASolicitud.SerieTicket;
    oConsulta.ParamByName('NUMERO').AsString := ASolicitud.NumeroTicket;
    oConsulta.Open;
    oConsulta.Close;
    oConsulta.SQL.Text := 'SELECT t.SERIE_FAC FROM fza_facturas t ' +
      'WHERE t.SERIE_FAC = :SERIE AND t.NUMERO_FAC = :NUMERO ' +
      'AND t.CODIGO_EMP_FAC = :EMPRESA ' + SQL_TICKET_PENDIENTE +
      'FOR UPDATE';
    oConsulta.ParamByName('SERIE').AsString := ASolicitud.SerieTicket;
    oConsulta.ParamByName('NUMERO').AsString := ASolicitud.NumeroTicket;
    oConsulta.ParamByName('EMPRESA').AsString := ASolicitud.Empresa;
    oConsulta.Open;
    if oConsulta.IsEmpty then
      raise Exception.CreateFmt(SErrorTicketPeriodo,
        [ASolicitud.SerieTicket, ASolicitud.NumeroTicket]);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TServicioFacturacionTicketUniDAC.CargarTicketPeriodo(
  AConsulta: TUniQuery; const ASolicitud: TSolicitudFacturacionTicket;
  const ATicket: TTicketFacturacion);
begin
  AConsulta.Close;
  AConsulta.SQL.Text := 'SELECT SERIE_FAC FROM fza_facturas ' +
    'WHERE SERIE_FAC = :SERIE AND NUMERO_FAC = :NUMERO FOR UPDATE';
  AConsulta.ParamByName('SERIE').AsString := ATicket.Serie;
  AConsulta.ParamByName('NUMERO').AsString := ATicket.Numero;
  AConsulta.Open;
  AConsulta.Close;
  AConsulta.SQL.Text := 'SELECT ' + CAMPOS_COMPATIBILIDAD_TICKETS +
    ', t.FECHA_FAC, t.TOTAL_LIQUIDO_FAC, t.INSTANTE_MODIF ' +
    'FROM fza_facturas t ' +
    'WHERE t.SERIE_FAC = :SERIE AND t.NUMERO_FAC = :NUMERO ' +
    'AND t.CODIGO_EMP_FAC = :EMPRESA ' +
    'AND (t.CODIGO_CLI_FAC = :CLIENTE OR ' +
    SQL_TICKET_SIN_CLIENTE + ') ' + SQL_TICKET_PENDIENTE +
    ' FOR UPDATE';
  AConsulta.ParamByName('SERIE').AsString := ATicket.Serie;
  AConsulta.ParamByName('NUMERO').AsString := ATicket.Numero;
  AConsulta.ParamByName('EMPRESA').AsString := ASolicitud.Empresa;
  AConsulta.ParamByName('CLIENTE').AsString := ASolicitud.Cliente;
  AConsulta.Open;
end;

procedure TServicioFacturacionTicketUniDAC.ValidarTicketPeriodo(
  AConsulta: TUniQuery; const ASolicitud: TSolicitudFacturacionTicket;
  const ATicket: TTicketFacturacion);
var
  sError: string;
begin
  if AConsulta.IsEmpty then
    raise Exception.CreateFmt(SErrorTicketPeriodo,
      [ATicket.Serie, ATicket.Numero]);
  if (AConsulta.FieldByName('TOTAL_LIQUIDO_FAC').AsCurrency <>
      ATicket.Total) or
     (AConsulta.FieldByName('FECHA_FAC').AsDateTime <> ATicket.Fecha) or
     (AConsulta.FieldByName('INSTANTE_MODIF').AsDateTime <>
      ATicket.InstanteModificacion) or
     (Trunc(ATicket.Fecha) < Trunc(ASolicitud.FechaDesde)) or
     (Trunc(ATicket.Fecha) > Trunc(ASolicitud.FechaHasta)) then
    raise Exception.CreateFmt(SErrorTicketPeriodo,
      [ATicket.Serie, ATicket.Numero]);
  sError := ErrorFechaFacturaSustitucionTicket(ASolicitud.Fecha,
    ATicket.Fecha, Date);
  if sError = '' then
    sError := ErrorTrimestreFacturaTickets(
      ASolicitud.Fecha, ATicket.Fecha);
  if sError <> '' then
    raise Exception.Create(sError);
end;

procedure TServicioFacturacionTicketUniDAC.BloquearTickets(
  const ASolicitud: TSolicitudFacturacionTicket);
var
  oConsulta: TUniQuery;
  oCampos, oValores, oClaves: TStringList;
  oTicket: TTicketFacturacion;
  sCampo: string;
begin
  if Length(ASolicitud.Tickets) > MAX_TICKETS_FACTURA_F3 then
    raise Exception.CreateFmt(SErrorMaxTicketsFacturaF3,
      [MAX_TICKETS_FACTURA_F3]);
  if Length(ASolicitud.Tickets) > 1 then
    ComprobarEsquemaPeriodo;
  oConsulta := TUniQuery.Create(nil);
  oCampos := TStringList.Create;
  oValores := TStringList.Create;
  oClaves := TStringList.Create;
  try
    oCampos.CommaText := CAMPOS_COMPATIBILIDAD_TICKETS;
    oConsulta.Connection := FConexion;
    // El bloqueo se toma sobre la cabecera antes de consultar relaciones:
    // dos cierres concurrentes no pueden sustituir el mismo ticket.
    for oTicket in ASolicitud.Tickets do
    begin
      if oClaves.IndexOf(oTicket.Serie + #9 + oTicket.Numero) >= 0 then
        raise Exception.CreateFmt(SErrorTicketPeriodo,
          [oTicket.Serie, oTicket.Numero]);
      oClaves.Add(oTicket.Serie + #9 + oTicket.Numero);
      CargarTicketPeriodo(oConsulta, ASolicitud, oTicket);
      ValidarTicketPeriodo(oConsulta, ASolicitud, oTicket);
      for sCampo in oCampos do
      begin
        if oClaves.Count = 1 then
          oValores.Values[sCampo] := oConsulta.FieldByName(sCampo).AsString
        else if oValores.Values[sCampo] <>
                oConsulta.FieldByName(sCampo).AsString then
          raise Exception.Create(SErrorTicketsIncompatibles);
      end;
    end;
  finally
    FreeAndNil(oClaves);
    FreeAndNil(oValores);
    FreeAndNil(oCampos);
    FreeAndNil(oConsulta);
  end;
end;

procedure TServicioFacturacionTicketUniDAC.AcumularImportesTicket(
  AConsulta: TUniQuery; const ASolicitud: TSolicitudFacturacionTicket;
  const ANumero: string);
var
  oCampos: TStringList;
  sSql, sCampo, sSeparador: string;
begin
  oCampos := TStringList.Create;
  try
    oCampos.CommaText := CAMPOS_IMPORTES_TICKETS;
    sSql := 'UPDATE fza_facturas f JOIN fza_facturas t ' +
      'ON t.SERIE_FAC = :STICKET AND t.NUMERO_FAC = :NTICKET SET ';
    sSeparador := '';
    for sCampo in oCampos do
    begin
      sSql := sSql + sSeparador + 'f.' + sCampo +
        ' = COALESCE(f.' + sCampo + ', 0) + COALESCE(t.' +
        sCampo + ', 0)';
      sSeparador := ', ';
    end;
    sSql := sSql + ' WHERE f.SERIE_FAC = :SERIE ' +
      'AND f.NUMERO_FAC = :NUMERO';
    EjecutarSqlFactura(AConsulta, sSql, ASolicitud, ANumero);
  finally
    FreeAndNil(oCampos);
  end;
end;

procedure TServicioFacturacionTicketUniDAC.InsertarRotuloTicket(
  AConsulta: TUniQuery; const ASolicitud: TSolicitudFacturacionTicket;
  const ANumero: string; const ATicket: TTicketFacturacion;
  ALinea: Integer);
begin
  AConsulta.SQL.Text :=
    'INSERT INTO fza_facturas_lineas (SERIE_FAC_FACLIN, ' +
    'NUMERO_FAC_FACLIN, LINEA_FACLIN, DESCRIPCION_ARTICULO_FACLIN, ' +
    'CANTIDAD_FACLIN, TOTAL_FACLIN, TOTAL_FAC_SIVA_FACLIN, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:SERIE, :NUMERO, LPAD(:LINEA, 4, ''0''), ' +
    ':TEXTO, 0, 0, 0, ' +
    'NOW(), NOW(), :USUARIO, :USUARIO)';
  AConsulta.ParamByName('LINEA').AsInteger := ALinea;
  AConsulta.ParamByName('TEXTO').AsString :=
    Format(SFacturacionSimplificadosTicket,
    [ATicket.Serie, ATicket.Numero, DateToStr(ATicket.Fecha)]);
  EjecutarSqlFactura(AConsulta, AConsulta.SQL.Text,
    ASolicitud, ANumero);
end;

procedure TServicioFacturacionTicketUniDAC.CopiarLineasTicketPeriodo(
  AConsulta: TUniQuery; const ASolicitud: TSolicitudFacturacionTicket;
  const ANumero: string; ADesplazamiento: Integer);
var
  sSql: string;
begin
  sSql := StringReplace(
    SqlInsertarLineasTicket(ActivacionVigente.AlgunModoActivo),
    'SELECT :NUMERO, :SERIE, LINEA_FACLIN,',
    'SELECT :NUMERO, :SERIE, LPAD(CAST(LINEA_FACLIN AS UNSIGNED) ' +
    '+ :DESPLAZAMIENTO, 4, ''0''),', []);
  AConsulta.SQL.Text := sSql;
  AConsulta.ParamByName('DESPLAZAMIENTO').AsInteger :=
    ADesplazamiento;
  EjecutarSqlFactura(AConsulta, sSql, ASolicitud, ANumero);
  if AConsulta.RowsAffected = 0 then
    raise Exception.CreateFmt(SErrorTicketPeriodo,
      [ASolicitud.SerieTicket, ASolicitud.NumeroTicket]);
end;

function TServicioFacturacionTicketUniDAC.UltimaLineaFactura(
  const ASerie, ANumero: string): Integer;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT MAX(CAST(LINEA_FACLIN AS UNSIGNED)) AS ULTIMA ' +
      'FROM fza_facturas_lineas WHERE SERIE_FAC_FACLIN = :SERIE ' +
      'AND NUMERO_FAC_FACLIN = :NUMERO';
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.Open;
    Result := oConsulta.FieldByName('ULTIMA').AsInteger;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TServicioFacturacionTicketUniDAC.CopiarTickets(
  const ASolicitud: TSolicitudFacturacionTicket; const ANumero: string);
var
  oConsulta: TUniQuery;
  oSolicitud: TSolicitudFacturacionTicket;
  oTicket: TTicketFacturacion;
  iDesplazamiento, iIndice: Integer;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oSolicitud := ASolicitud;
    iDesplazamiento := 0;
    for iIndice := 0 to High(ASolicitud.Tickets) do
    begin
      oTicket := ASolicitud.Tickets[iIndice];
      oSolicitud.SerieTicket := oTicket.Serie;
      oSolicitud.NumeroTicket := oTicket.Numero;
      if iIndice = 0 then
        EjecutarSqlFactura(oConsulta, SQL_INSERTAR_CABECERA,
          oSolicitud, ANumero)
      else
        AcumularImportesTicket(oConsulta, oSolicitud, ANumero);
      if iDesplazamiento + 1 + UltimaLineaFactura(
        oTicket.Serie, oTicket.Numero) > 9999 then
        raise Exception.Create(SErrorLineasFacturacionSimplificados);
      Inc(iDesplazamiento);
      InsertarRotuloTicket(oConsulta, oSolicitud, ANumero,
        oTicket, iDesplazamiento);
      CopiarLineasTicketPeriodo(oConsulta, oSolicitud, ANumero,
        iDesplazamiento);
      EjecutarSqlFactura(oConsulta, SQL_ENLAZAR_TICKET,
        oSolicitud, ANumero);
      FServicioCola.RegistrarRelacionFactura(ASolicitud.Usuario,
        ASolicitud.SerieNueva, ANumero, oTicket.Serie,
        oTicket.Numero, 'SUSTITUYE');
      iDesplazamiento := UltimaLineaFactura(
        ASolicitud.SerieNueva, ANumero);
    end;
    oConsulta.SQL.Text := 'UPDATE fza_facturas SET ' +
      'CONTADOR_LINEAS_FAC = :LINEAS, COMENTARIOS_FAC = :COMENTARIO ' +
      'WHERE SERIE_FAC = :SERIE AND NUMERO_FAC = :NUMERO';
    oConsulta.ParamByName('LINEAS').AsInteger := iDesplazamiento;
    oConsulta.ParamByName('COMENTARIO').AsString :=
      Format(SComentarioFacturacionSimplificados,
      [Length(ASolicitud.Tickets), DateToStr(ASolicitud.FechaDesde),
      DateToStr(ASolicitud.FechaHasta)]);
    oConsulta.ParamByName('SERIE').AsString := ASolicitud.SerieNueva;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

// Número escrito a mano: con ceros hasta los dígitos del contador si es
// numérico y sin repetir uno que ya exista en la serie.
function TServicioFacturacionTicketUniDAC.NumeroManual(
  const ASolicitud: TSolicitudFacturacionTicket): string;
var
  oConsulta: TUniQuery;
  iDigitos: Integer;
begin
  Result := Trim(ASolicitud.NumeroManual);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_DIGITOS_CONTADOR;
    oConsulta.ParamByName('EMPRESA').AsString := ASolicitud.Empresa;
    oConsulta.ParamByName('SERIE').AsString := ASolicitud.SerieNueva;
    oConsulta.Open;
    iDigitos := oConsulta.FieldByName('DIGITOS').AsInteger;
    oConsulta.Close;
    if (StrToInt64Def(Result, -1) >= 0) and (iDigitos > Length(Result)) then
      Result := StringOfChar('0', iDigitos - Length(Result)) + Result;
    oConsulta.SQL.Text := SQL_EXISTE_FACTURA;
    oConsulta.ParamByName('SERIE').AsString := ASolicitud.SerieNueva;
    oConsulta.ParamByName('NUMERO').AsString := Result;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      raise Exception.CreateFmt(SErrorNumeroFacturaTicketExistente,
        [ASolicitud.SerieNueva, Result]);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TServicioFacturacionTicketUniDAC.ObtenerNumero(
  const ASolicitud: TSolicitudFacturacionTicket): string;
begin
  if Trim(ASolicitud.NumeroManual) <> '' then
    Result := NumeroManual(ASolicitud)
  else
    Result := ReservarNumeroContador(ASolicitud);
end;

function TServicioFacturacionTicketUniDAC.ReservarNumeroContador(
  const ASolicitud: TSolicitudFacturacionTicket): string;
var
  oProcedimiento: TUniStoredProc;
begin
  oProcedimiento := TUniStoredProc.Create(nil);
  try
    oProcedimiento.Connection := FConexion;
    oProcedimiento.StoredProcName := 'PRC_GET_NEXT_CONT_FACT_SERIE';
    oProcedimiento.Prepare;
    oProcedimiento.ParamByName('pserie').AsString := ASolicitud.SerieNueva;
    oProcedimiento.ParamByName('pTipoDoc').AsString := 'FC';
    oProcedimiento.ParamByName('pEMPRESA_CONTADOR').AsString :=
      ASolicitud.Empresa;
    oProcedimiento.ParamByName('pUSUARIOMODIF').AsString :=
      ASolicitud.Usuario;
    oProcedimiento.Execute;
    Result := oProcedimiento.ParamByName('pcont').AsString;
  finally
    FreeAndNil(oProcedimiento);
  end;
end;

procedure TServicioFacturacionTicketUniDAC.EjecutarSqlFactura(
  AConsulta: TUniQuery;
  const ASql: string;
  const ASolicitud: TSolicitudFacturacionTicket;
  const ANumero: string);
begin
  if Trim(AConsulta.SQL.Text) <> Trim(ASql) then
    AConsulta.SQL.Text := ASql;
  if AConsulta.Params.FindParam('NUMERO') <> nil then
  begin
    AConsulta.ParamByName('NUMERO').AsString := ANumero;
  end;
  if AConsulta.Params.FindParam('SERIE') <> nil then
  begin
    AConsulta.ParamByName('SERIE').AsString := ASolicitud.SerieNueva;
  end;
  if AConsulta.Params.FindParam('FECHA') <> nil then
  begin
    AConsulta.ParamByName('FECHA').AsDate := ASolicitud.Fecha;
  end;
  if AConsulta.Params.FindParam('USUARIO') <> nil then
  begin
    AConsulta.ParamByName('USUARIO').AsString := ASolicitud.Usuario;
  end;
  if AConsulta.Params.FindParam('CLIENTE') <> nil then
  begin
    AConsulta.ParamByName('CLIENTE').AsString := ASolicitud.Cliente;
  end;
  if AConsulta.Params.FindParam('STICKET') <> nil then
  begin
    AConsulta.ParamByName('STICKET').AsString := ASolicitud.SerieTicket;
  end;
  if AConsulta.Params.FindParam('NTICKET') <> nil then
  begin
    AConsulta.ParamByName('NTICKET').AsString := ASolicitud.NumeroTicket;
  end;
  if AConsulta.Params.FindParam('FORMA_PAGO') <> nil then
  begin
    AConsulta.ParamByName('FORMA_PAGO').AsString :=
      Trim(ASolicitud.FormaPago);
  end;
  if AConsulta.Params.FindParam('COMENTARIO') <> nil then
  begin
    AConsulta.ParamByName('COMENTARIO').AsString :=
      ' ESTA FACTURA SE EMITE EN SUSTITUCIÓN DE LA FACTURA SIMPLIFICADA ' +
      FormatearDocumento(
        CrearFormatoDocumentoLecturas(FConexion).LeerFormatoEmpresa(
          ASolicitud.Empresa),
        ASolicitud.SerieTicket, ASolicitud.NumeroTicket);
  end;
  AConsulta.Execute;
end;

function TServicioFacturacionTicketUniDAC.CrearFactura(
  const ASolicitud: TSolicitudFacturacionTicket): string;
var
  oConsulta: TUniQuery;
  oSolicitudEmision: TSolicitudEmisionFiscal;
  sErrorFecha: string;
begin
  sErrorFecha := '';
  if Length(ASolicitud.Tickets) = 0 then
    sErrorFecha := ErrorFechaFacturaSustitucionTicket(ASolicitud.Fecha,
      FechaTicket(ASolicitud.SerieTicket, ASolicitud.NumeroTicket), Date)
  else if (ASolicitud.FechaDesde > ASolicitud.FechaHasta) or
          (Trunc(ASolicitud.FechaHasta) >= Date) or
          (Trunc(ASolicitud.Fecha) < Trunc(ASolicitud.FechaHasta)) or
          (Trunc(ASolicitud.Fecha) > Date) then
    sErrorFecha := SFacturacionSimplificadosFechaInvalida;
  if sErrorFecha <> '' then
    raise Exception.Create(sErrorFecha);
  FConexion.StartTransaction;
  oConsulta := TUniQuery.Create(nil);
  try
    try
      if Length(ASolicitud.Tickets) > 0 then
        BloquearTickets(ASolicitud)
      else
        BloquearTicketIndividual(ASolicitud);
      Result := ObtenerNumero(ASolicitud);
      oConsulta.Connection := FConexion;
      if Length(ASolicitud.Tickets) > 0 then
        CopiarTickets(ASolicitud, Result)
      else
      begin
        EjecutarSqlFactura(
          oConsulta,
          SQL_INSERTAR_CABECERA,
          ASolicitud,
          Result);
        if oConsulta.RowsAffected = 0 then
        begin
          raise Exception.Create(SErrorCrearBorradorFacturarTicket);
      end;
      EjecutarSqlFactura(
        oConsulta,
        SqlInsertarLineasTicket(ActivacionVigente.AlgunModoActivo),
        ASolicitud,
        Result);
      EjecutarSqlFactura(
        oConsulta,
        SQL_ENLAZAR_TICKET,
        ASolicitud,
        Result);
      end;
      // La sustitucion conserva exactamente los importes del ticket. La
      // cabecera y las lineas ya copian el desglose economico original.
      ValidarRequisitosFiscalesEmision(
        FParametrosApp,
        FConexion,
        ASolicitud.SerieNueva,
        Result);
      if Length(ASolicitud.Tickets) = 0 then
        FServicioCola.RegistrarRelacionFactura(
        ASolicitud.Usuario,
        ASolicitud.SerieNueva,
        Result,
        ASolicitud.SerieTicket,
        ASolicitud.NumeroTicket,
        'SUSTITUYE');
      // La emision entra en la misma transaccion: si falla no queda la
      // factura creada con el ticket enlazado y sin emitir (FZ-ISSUE-147).
      // PRC_GET_NEXT_CONT_FACT_SERIE respeta esta transaccion desde
      // FZ-ISSUE-143, asi que el Rollback devuelve tambien el numero FC.
      oSolicitudEmision := TSolicitudEmisionFiscal.ParaAlta(
        ASolicitud.SerieNueva,
        Result,
        ASolicitud.Usuario,
        'Borrador en sustitución del ticket ' +
        FormatearDocumento(
          CrearFormatoDocumentoLecturas(FConexion).LeerFormatoEmpresa(
            ASolicitud.Empresa),
          ASolicitud.SerieTicket, ASolicitud.NumeroTicket) + ' encolada');
      if Length(ASolicitud.Tickets) > 0 then
        oSolicitudEmision.DescripcionEvento :=
          Format(SEventoFacturacionSimplificados,
          [Length(ASolicitud.Tickets), DateToStr(ASolicitud.FechaDesde),
          DateToStr(ASolicitud.FechaHasta)]);
      FServicioEmision.Emitir(oSolicitudEmision);
      FConexion.Commit;
    except
      FConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

{ Préstamos }

function TServicioFacturacionTicketUniDAC.LeerPrestamo(
  AConsulta: TUniQuery): TPrestamoFacturacion;
begin
  Result := Default(TPrestamoFacturacion);
  Result.IdDeposito := AConsulta.FieldByName('ID_DEPOSITO_DEP').AsString;
  Result.Fecha := AConsulta.FieldByName('FECHA_CREACION_DEP').AsDateTime;
  Result.Articulo := AConsulta.FieldByName('CODIGO_ART_DEP').AsString;
  Result.Sku := AConsulta.FieldByName('CODIGO_UNIDAD_DEP').AsString;
  Result.Descripcion := AConsulta.FieldByName('DESCRIPCION').AsString;
  Result.Cantidad := AConsulta.FieldByName('CANTIDAD').AsFloat;
  Result.Precio := AConsulta.FieldByName('PRECIO').AsCurrency;
  Result.Anticipo := AConsulta.FieldByName('ANTICIPO').AsCurrency;
  // Lo que se factura ahora: el anticipo ya se facturó al prestar.
  Result.Total := Result.Precio * Result.Cantidad - Result.Anticipo;
  Result.InstanteModificacion :=
    AConsulta.FieldByName('INSTANTE_MODIF').AsDateTime;
end;

function TServicioFacturacionTicketUniDAC.ConsultarPrestamosPeriodo(
  const AEmpresa, ACliente: string;
  ADesde, AHasta: TDateTime): TPrestamosFacturacion;
var
  oConsulta: TUniQuery;
begin
  Result := nil;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_PRESTAMOS_PERIODO + SQL_ORDEN_PRESTAMOS;
    oConsulta.ParamByName('EMPRESA').AsString := AEmpresa;
    oConsulta.ParamByName('CLIENTE').AsString := ACliente;
    oConsulta.ParamByName('DESDE').AsDate := Trunc(ADesde);
    oConsulta.ParamByName('HASTA').AsDate := Trunc(AHasta) + 1;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      Result := Result + [LeerPrestamo(oConsulta)];
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

// Mismas reglas de fecha que la F3 del período: período cerrado, factura
// entre su cierre y hoy, y en el mismo trimestre que cada préstamo.
procedure TServicioFacturacionTicketUniDAC.ValidarFechasPrestamos(
  const ASolicitud: TSolicitudFacturacionTicket);
var
  oPrestamo: TPrestamoFacturacion;
  sError: string;
begin
  if (Length(ASolicitud.Prestamos) = 0) or
     (ASolicitud.FechaDesde > ASolicitud.FechaHasta) or
     (Trunc(ASolicitud.FechaHasta) >= Date) or
     (Trunc(ASolicitud.Fecha) < Trunc(ASolicitud.FechaHasta)) or
     (Trunc(ASolicitud.Fecha) > Date) then
    raise Exception.Create(SFacturacionSimplificadosFechaInvalida);
  for oPrestamo in ASolicitud.Prestamos do
  begin
    sError := ErrorTrimestreFacturaTickets(ASolicitud.Fecha,
      oPrestamo.Fecha);
    if sError <> '' then
      raise Exception.Create(sError);
  end;
end;

// Bloquea cada préstamo y comprueba que sigue como se revisó: pendiente,
// del cliente, en el período y sin cambios desde la revisión.
procedure TServicioFacturacionTicketUniDAC.BloquearPrestamos(
  const ASolicitud: TSolicitudFacturacionTicket);
var
  oConsulta: TUniQuery;
  oPrestamo, oActual: TPrestamoFacturacion;
  oClaves: TStringList;
begin
  oConsulta := TUniQuery.Create(nil);
  oClaves := TStringList.Create;
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_PRESTAMOS_PERIODO +
      'AND D.ID_DEPOSITO_DEP = :ID FOR UPDATE';
    for oPrestamo in ASolicitud.Prestamos do
    begin
      if oClaves.IndexOf(oPrestamo.IdDeposito) >= 0 then
        raise Exception.CreateFmt(SErrorPrestamoPeriodo,
          [oPrestamo.IdDeposito]);
      oClaves.Add(oPrestamo.IdDeposito);
      oConsulta.Close;
      oConsulta.ParamByName('EMPRESA').AsString := ASolicitud.Empresa;
      oConsulta.ParamByName('CLIENTE').AsString := ASolicitud.Cliente;
      oConsulta.ParamByName('DESDE').AsDate := Trunc(ASolicitud.FechaDesde);
      oConsulta.ParamByName('HASTA').AsDate :=
        Trunc(ASolicitud.FechaHasta) + 1;
      oConsulta.ParamByName('ID').AsString := oPrestamo.IdDeposito;
      oConsulta.Open;
      if oConsulta.IsEmpty then
        raise Exception.CreateFmt(SErrorPrestamoPeriodo,
          [oPrestamo.IdDeposito]);
      oActual := LeerPrestamo(oConsulta);
      if (oActual.Total <> oPrestamo.Total) or
         (oActual.InstanteModificacion <>
          oPrestamo.InstanteModificacion) then
        raise Exception.CreateFmt(SErrorPrestamoPeriodo,
          [oPrestamo.IdDeposito]);
    end;
  finally
    FreeAndNil(oClaves);
    FreeAndNil(oConsulta);
  end;
end;

// La prenda prestada está en el almacén de depósitos de la empresa (el
// CODIGO_ALM_DEP del depósito es el de la tienda que prestó).
function TServicioFacturacionTicketUniDAC.AlmacenDepositos(
  const AEmpresa: string): string;
var
  oAlmacenes: IRepositorioAlmacenesEmpresa;
begin
  oAlmacenes := TRepositorioAlmacenesEmpresaUniDAC.Create(FConexion);
  Result := Trim(oAlmacenes.ObtenerAlmacenDepositoEmpresa(AEmpresa));
  if Result = '' then
    raise Exception.CreateFmt(SErrorPrestamosSinAlmacenDeposito,
      [AEmpresa]);
end;

procedure TServicioFacturacionTicketUniDAC.EjecutarSqlPrestamo(
  AConsulta: TUniQuery; const ASql: string;
  const ASolicitud: TSolicitudFacturacionTicket; const ANumero,
  AAlmacen, AIdDeposito: string; ALinea: Integer);
var
  oParametro: TParam;
begin
  AConsulta.SQL.Text := ASql;
  oParametro := AConsulta.Params.FindParam('NUMERO');
  if oParametro <> nil then
    oParametro.AsString := ANumero;
  oParametro := AConsulta.Params.FindParam('SERIE');
  if oParametro <> nil then
    oParametro.AsString := ASolicitud.SerieNueva;
  oParametro := AConsulta.Params.FindParam('USUARIO');
  if oParametro <> nil then
    oParametro.AsString := ASolicitud.Usuario;
  oParametro := AConsulta.Params.FindParam('ALMACEN');
  if oParametro <> nil then
    oParametro.AsString := AAlmacen;
  oParametro := AConsulta.Params.FindParam('ID');
  if oParametro <> nil then
    oParametro.AsString := AIdDeposito;
  oParametro := AConsulta.Params.FindParam('LINEA');
  if oParametro <> nil then
    oParametro.AsInteger := ALinea;
  oParametro := AConsulta.Params.FindParam('FECHA');
  if oParametro <> nil then
    oParametro.AsDate := Trunc(ASolicitud.Fecha);
  AConsulta.Execute;
end;

procedure TServicioFacturacionTicketUniDAC.InsertarCabeceraPrestamos(
  AConsulta: TUniQuery; const ASolicitud: TSolicitudFacturacionTicket;
  const ANumero, AAlmacen: string);
begin
  AConsulta.SQL.Text := SQL_INSERTAR_CABECERA_PRESTAMOS;
  AConsulta.ParamByName('NUMERO').AsString := ANumero;
  AConsulta.ParamByName('SERIE').AsString := ASolicitud.SerieNueva;
  AConsulta.ParamByName('FECHA_FACTURA').AsDate := Trunc(ASolicitud.Fecha);
  AConsulta.ParamByName('ALMACEN').AsString := AAlmacen;
  AConsulta.ParamByName('FORMA_PAGO').AsString := Trim(ASolicitud.FormaPago);
  AConsulta.ParamByName('COMENTARIO').AsString :=
    Format(SComentarioFacturacionPrestamos,
    [Length(ASolicitud.Prestamos), DateToStr(ASolicitud.FechaDesde),
    DateToStr(ASolicitud.FechaHasta)]);
  AConsulta.ParamByName('USUARIO').AsString := ASolicitud.Usuario;
  AConsulta.ParamByName('CLIENTE').AsString := ASolicitud.Cliente;
  AConsulta.ParamByName('EMPRESA').AsString := ASolicitud.Empresa;
  AConsulta.Execute;
  // Sin fila: la empresa no tiene tipos de IVA vigentes en esa fecha.
  if AConsulta.RowsAffected <> 1 then
    raise Exception.Create(SErrorCrearBorradorFacturarTicket);
end;

function TServicioFacturacionTicketUniDAC.InsertarLineasPrestamos(
  AConsulta: TUniQuery; const ASolicitud: TSolicitudFacturacionTicket;
  const ANumero, AAlmacen: string): Integer;
var
  oPrestamo: TPrestamoFacturacion;
begin
  Result := 0;
  for oPrestamo in ASolicitud.Prestamos do
  begin
    Inc(Result);
    EjecutarSqlPrestamo(AConsulta, SQL_INSERTAR_LINEA_PRESTAMO,
      ASolicitud, ANumero, AAlmacen, oPrestamo.IdDeposito, Result);
    if AConsulta.RowsAffected <> 1 then
      raise Exception.CreateFmt(SErrorPrestamoPeriodo,
        [oPrestamo.IdDeposito]);
    if oPrestamo.Anticipo <> 0 then
    begin
      Inc(Result);
      EjecutarSqlPrestamo(AConsulta, SQL_INSERTAR_LINEA_ANTICIPO_PRESTAMO,
        ASolicitud, ANumero, AAlmacen, oPrestamo.IdDeposito, Result);
    end;
  end;
  if Result > 9999 then
    raise Exception.Create(SErrorLineasFacturacionSimplificados);
  AConsulta.SQL.Text := 'UPDATE fza_facturas SET ' +
    'CONTADOR_LINEAS_FAC = :LINEAS ' +
    'WHERE SERIE_FAC = :SERIE AND NUMERO_FAC = :NUMERO';
  AConsulta.ParamByName('LINEAS').AsInteger := Result;
  AConsulta.ParamByName('SERIE').AsString := ASolicitud.SerieNueva;
  AConsulta.ParamByName('NUMERO').AsString := ANumero;
  AConsulta.Execute;
end;

procedure TServicioFacturacionTicketUniDAC.CerrarPrestamos(
  AConsulta: TUniQuery; const ASolicitud: TSolicitudFacturacionTicket);
var
  oPrestamo: TPrestamoFacturacion;
begin
  for oPrestamo in ASolicitud.Prestamos do
  begin
    // La deuda se descuenta antes de cerrar: lee el depósito tal cual.
    EjecutarSqlPrestamo(AConsulta, SQL_DESCONTAR_DEUDA_PRESTAMO,
      ASolicitud, '', '', oPrestamo.IdDeposito, 0);
    EjecutarSqlPrestamo(AConsulta, SQL_CERRAR_PRESTAMO,
      ASolicitud, '', '', oPrestamo.IdDeposito, 0);
    if AConsulta.RowsAffected <> 1 then
      raise Exception.CreateFmt(SErrorPrestamoPeriodo,
        [oPrestamo.IdDeposito]);
  end;
end;

// Mismo servicio que la consolidación de borradores: sale del almacén de
// cada línea (el de depósitos) y no toca las líneas de servicio.
procedure TServicioFacturacionTicketUniDAC.GenerarMovimientosPrestamos(
  const ASolicitud: TSolicitudFacturacionTicket; const ANumero: string);
var
  oMovimientos: IServicioMovimientosFactura;
  oSolicitud: TSolicitudMovimientosFactura;
begin
  oMovimientos := TServicioMovimientosFactura.Create(FConexion,
    CrearPersistenciaFacturasUniDAC(FConexion).Movimientos,
    TRepositorioValoresAutomaticosUniDAC.Create(FConexion));
  oSolicitud := Default(TSolicitudMovimientosFactura);
  oSolicitud.Serie := ASolicitud.SerieNueva;
  oSolicitud.Numero := ANumero;
  oSolicitud.Empresa := ASolicitud.Empresa;
  oSolicitud.Cliente := ASolicitud.Cliente;
  oSolicitud.Fecha := Trunc(ASolicitud.Fecha);
  oSolicitud.Usuario := ASolicitud.Usuario;
  oMovimientos.GenerarSalidas(oSolicitud);
end;

// Cobrada sin pasar por caja: efectos según la forma de pago y todos
// cobrados en la fecha de la factura.
procedure TServicioFacturacionTicketUniDAC.CobrarFacturaPrestamos(
  AConsulta: TUniQuery; const ASolicitud: TSolicitudFacturacionTicket;
  const ANumero: string);
var
  oEfectos: IRepositorioEfectosFactura;
  sFormaPago: string;
begin
  oEfectos := CrearPersistenciaFacturasUniDAC(FConexion).Efectos;
  if oEfectos.GenerarDesdeFactura(ASolicitud.SerieNueva, ANumero,
       ASolicitud.Usuario, '', '') < 0 then
    raise Exception.Create(SErrorCrearBorradorFacturarTicket);
  AConsulta.SQL.Text := 'SELECT FORMA_PAGO_FAC FROM fza_facturas ' +
    'WHERE SERIE_FAC = :SERIE AND NUMERO_FAC = :NUMERO';
  AConsulta.ParamByName('SERIE').AsString := ASolicitud.SerieNueva;
  AConsulta.ParamByName('NUMERO').AsString := ANumero;
  AConsulta.Open;
  sFormaPago := AConsulta.FieldByName('FORMA_PAGO_FAC').AsString;
  AConsulta.Close;
  AConsulta.SQL.Text := SQL_EFECTOS_PENDIENTES;
  AConsulta.ParamByName('SERIE').AsString := ASolicitud.SerieNueva;
  AConsulta.ParamByName('NUMERO').AsString := ANumero;
  AConsulta.Open;
  while not AConsulta.Eof do
  begin
    if oEfectos.RegistrarCobro(ASolicitud.SerieNueva, ANumero,
         ASolicitud.Usuario,
         AConsulta.FieldByName('NUMERO_EFV').AsInteger,
         Trunc(ASolicitud.Fecha),
         AConsulta.FieldByName('IMPORTE_PENDIENTE_EFV').AsFloat,
         sFormaPago, '') < 1 then
      raise Exception.Create(SErrorCrearBorradorFacturarTicket);
    AConsulta.Next;
  end;
  AConsulta.Close;
end;

function TServicioFacturacionTicketUniDAC.CrearFacturaPrestamos(
  const ASolicitud: TSolicitudFacturacionTicket): string;
var
  oConsulta: TUniQuery;
  oSolicitudEmision: TSolicitudEmisionFiscal;
  sAlmacen, sMensaje: string;
begin
  ValidarFechasPrestamos(ASolicitud);
  sAlmacen := AlmacenDepositos(ASolicitud.Empresa);
  FConexion.StartTransaction;
  oConsulta := TUniQuery.Create(nil);
  try
    try
      oConsulta.Connection := FConexion;
      BloquearPrestamos(ASolicitud);
      Result := ObtenerNumero(ASolicitud);
      InsertarCabeceraPrestamos(oConsulta, ASolicitud, Result, sAlmacen);
      InsertarLineasPrestamos(oConsulta, ASolicitud, Result, sAlmacen);
      if not RecalcularTotalesFacturaVenta(FConexion,
           ASolicitud.SerieNueva, Result, sMensaje) then
        raise Exception.Create(sMensaje);
      ValidarRequisitosFiscalesEmision(FParametrosApp, FConexion,
        ASolicitud.SerieNueva, Result);
      GenerarMovimientosPrestamos(ASolicitud, Result);
      CerrarPrestamos(oConsulta, ASolicitud);
      // Igual que la F3: la emisión va en la misma transacción y, si
      // falla, no queda ni la factura ni los préstamos cerrados.
      oSolicitudEmision := TSolicitudEmisionFiscal.ParaAlta(
        ASolicitud.SerieNueva, Result, ASolicitud.Usuario,
        Format(SEventoFacturacionPrestamos,
        [Length(ASolicitud.Prestamos), DateToStr(ASolicitud.FechaDesde),
        DateToStr(ASolicitud.FechaHasta)]));
      FServicioEmision.Emitir(oSolicitudEmision);
      CobrarFacturaPrestamos(oConsulta, ASolicitud, Result);
      FConexion.Commit;
    except
      FConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function CrearServicioFacturacionTicketUniDAC(
  AConexion: TUniConnection;
  const AParametrosApp: IParametrosAplicacion;
  const AServicioEmision: IServicioEmisionFiscal;
  const AServicioCola: IServicioVerifactuCola
): IServicioFacturacionTicket;
begin
  Result := TServicioFacturacionTicketUniDAC.Create(
    AConexion,
    AParametrosApp,
    AServicioEmision,
    AServicioCola);
end;

end.
