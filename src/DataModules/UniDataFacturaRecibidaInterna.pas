{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataFacturaRecibidaInterna                                 }
{    Tipo:       Repositorio UniDAC                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    FZ-ISSUE-358. Al consolidar una factura interna (su cliente es el         }
{    cliente de traspasos de otra empresa: TA, TV, VR o tecleada a mano)       }
{    graba la factura recibida en la empresa destino, con la emisora como      }
{    proveedor P_<código>. No mueve stock: la mercancía llegó con el traspaso. }
{******************************************************************************}
unit UniDataFacturaRecibidaInterna;

interface

uses
  Uni,
  inLibFacturasServiciosIntf;

type
  // Una factura interna consolidada y su recibida en la empresa destino.
  TLineaCuadreFacturaInterna = record
    Emisora       : string;
    Destino       : string;
    SerieEmitida  : string;
    NumeroEmitida : string;
    Fecha         : TDateTime;
    Emitido       : Currency;
    TieneRecibida : Boolean;
    SerieRecibida : string;
    NumeroRecibida: string;
    Recibido      : Currency;
  end;

  TLineasCuadreFacturasInternas = TArray<TLineaCuadreFacturaInterna>;

const
  // Prefijo del proveedor que representa a una empresa del grupo.
  PREFIJO_PROVEEDOR_EMPRESA = 'P_';

  // Factura interna: el cliente es el cliente de traspasos de otra empresa.
  SQL_FACTURA_INTERNA =
    'SELECT F.CODIGO_EMP_FAC AS EMISORA, D.CODIGO_EMP_EMP AS DESTINO ' +
    '  FROM fza_facturas F ' +
    '  JOIN fza_empresas D ' +
    '    ON D.CODIGO_CLI_TRASPASOS_EMP = F.CODIGO_CLI_FAC ' +
    '   AND D.CODIGO_EMP_EMP <> F.CODIGO_EMP_FAC ' +
    ' WHERE F.SERIE_FAC = :SERIE_EMITIDA ' +
    '   AND F.NUMERO_FAC = :NUMERO_EMITIDA ' +
    ' LIMIT 1';

  // Número de la factura del proveedor en una recibida C: el documento
  // externo o, vacío, la referencia del proveedor, que es lo único que la
  // pantalla deja teclear (FZ-ISSUE-389, mismo criterio que FZ-ISSUE-168).
  SQL_DOCUMENTO_PROVEEDOR_RECIBIDA =
    'COALESCE(NULLIF(TRIM(C.DOC_EXTERNO_FACC), ''''), ' +
    'TRIM(C.REF_PROVEEDOR_FACC))';

  // Vale también la registrada a mano. Una cancelada no cuenta.
  SQL_RECIBIDA_EXISTENTE =
    'SELECT C.SERIE_FACC, C.NUMERO_FACC ' +
    '  FROM fza_facturas_compra C ' +
    ' WHERE C.CODIGO_EMP_FACC = :DESTINO ' +
    '   AND C.CODIGO_PRV_FACC = :PROVEEDOR ' +
    '   AND ' + SQL_DOCUMENTO_PROVEEDOR_RECIBIDA + ' = :DOCUMENTO ' +
    '   AND COALESCE(C.ESTADO_FACC, '''') <> ''CANCELADA'' ' +
    ' LIMIT 1';

  // La empresa guarda el país como 'ES' o como '724'; el proveedor, con el
  // código de fza_paises (como el cliente de traspasos).
  SQL_INSERTAR_PROVEEDOR_EMPRESA =
    'INSERT INTO fza_proveedores (' +
    'CODIGO_PRV_PRV, ESACTIVO_PRV, RAZON_SOCIAL_PRV, NOMBRE_PRV, NIF_PRV, ' +
    'MOVIL_PRV, EMAIL_PRV, DIRECCION1_PRV, DIRECCION2_PRV, ' +
    'POBLACION_PRV, PROVINCIA_PRV, CODIGO_POSTAL_PRV, CODIGO_PAI_PRV, ' +
    'PAIS_PRV, ESIVA_EXENTO_INTRACOMUNITARIO_PRV, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :PROVEEDOR, ''S'', E.RAZON_SOCIAL_EMP, E.RAZON_SOCIAL_EMP, ' +
    'E.NIF_EMP, E.MOVIL_EMP, E.EMAIL_EMP, E.DIRECCION1_EMP, ' +
    'E.DIRECCION2_EMP, E.POBLACION_EMP, E.PROVINCIA_EMP, ' +
    'E.CODIGO_POSTAL_EMP, ' +
    'COALESCE((SELECT P.CODIGO_PAI_PAI FROM fza_paises P ' +
    '  WHERE P.CODIGO_PAI_PAI = E.CODIGO_PAI_EMP ' +
    '     OR P.COD_ALPHA2_PAI = E.CODIGO_PAI_EMP LIMIT 1), ' +
    '  NULLIF(E.CODIGO_PAI_EMP, '''')), E.NOMBRE_PAI_EMP, ''N'', ' +
    'NOW(), NOW(), :USUARIO, :USUARIO ' +
    'FROM fza_empresas E ' +
    'WHERE E.CODIGO_EMP_EMP = :EMISORA ' +
    '  AND NOT EXISTS (SELECT 1 FROM fza_proveedores X ' +
    '    WHERE X.CODIGO_PRV_PRV = :PROVEEDOR)';

  // Mismos importes que la emitida: la recibida es su espejo.
  SQL_INSERTAR_RECIBIDA =
    'INSERT INTO fza_facturas_compra (' +
    'NUMERO_FACC, SERIE_FACC, FECHA_FACC, FECHA_VALOR_FACC, ESTADO_FACC, ' +
    'DOC_EXTERNO_FACC, REF_PROVEEDOR_FACC, CODIGO_EMP_FACC, ' +
    'RAZON_SOCIAL_EMPRESA_FACC, NIF_EMPRESA_FACC, MOVIL_EMPRESA_FACC, ' +
    'EMAIL_EMPRESA_FACC, DIRECCION1_EMPRESA_FACC, ' +
    'DIRECCION2_EMPRESA_FACC, POBLACION_EMPRESA_FACC, ' +
    'PROVINCIA_EMPRESA_FACC, CODIGO_PAI_EMPRESA_FACC, ' +
    'NOMBRE_PAI_EMPRESA_FACC, CODIGO_POSTAL_EMPRESA_FACC, ' +
    'CODIGO_PRV_FACC, RAZON_SOCIAL_PRV_FACC, NIF_PRV_FACC, ' +
    'MOVIL_PRV_FACC, EMAIL_PRV_FACC, DIRECCION1_PRV_FACC, ' +
    'DIRECCION2_PRV_FACC, POBLACION_PRV_FACC, PROVINCIA_PRV_FACC, ' +
    'CODIGO_PAI_PRV_FACC, NOMBRE_PAI_PRV_FACC, CODIGO_POSTAL_PRV_FACC, ' +
    'CODIGO_IVA_FACC, ESIVA_RECARGO_COMPRAS_FACC, ' +
    'ESIVA_EXENTO_INTRACOMUNITARIO_FACC, ' +
    'PORCENTAJE_IVAN_FACC, TOTAL_BASEI_IVAN_FACC, TOTAL_IVAN_FACC, ' +
    'PORCENTAJE_REN_FACC, TOTAL_REN_FACC, ' +
    'PORCENTAJE_IVAR_FACC, TOTAL_BASEI_IVAR_FACC, TOTAL_IVAR_FACC, ' +
    'PORCENTAJE_RER_FACC, TOTAL_RER_FACC, ' +
    'PORCENTAJE_IVAS_FACC, TOTAL_BASEI_IVAS_FACC, TOTAL_IVAS_FACC, ' +
    'PORCENTAJE_RES_FACC, TOTAL_RES_FACC, ' +
    'PORCENTAJE_IVAE_FACC, TOTAL_BASEI_IVAE_FACC, TOTAL_IVAE_FACC, ' +
    'PORCENTAJE_REE_FACC, TOTAL_REE_FACC, ' +
    'PORCENTAJE_RETENCION_FACC, TOTAL_RETENCION_FACC, ' +
    'TOTAL_BRUTO_FACC, TOTAL_BASES_FACC, TOTAL_IMPUESTOS_FACC, ' +
    'TOTAL_FACC, TOTAL_LIQUIDO_FACC, FORMA_PAGO_FACC, ' +
    'CONTADOR_LINEAS_FACC, COMENTARIOS_FACC, ESPIVOTE_HORIZONTAL_FACC, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :NUMERO, :SERIE, F.FECHA_FAC, F.FECHA_FAC, ''CERRADA'', ' +
    ':DOCUMENTO, :DOCUMENTO, D.CODIGO_EMP_EMP, ' +
    'D.RAZON_SOCIAL_EMP, D.NIF_EMP, D.MOVIL_EMP, D.EMAIL_EMP, ' +
    'D.DIRECCION1_EMP, D.DIRECCION2_EMP, D.POBLACION_EMP, ' +
    'D.PROVINCIA_EMP, D.CODIGO_PAI_EMP, D.NOMBRE_PAI_EMP, ' +
    'D.CODIGO_POSTAL_EMP, ' +
    'P.CODIGO_PRV_PRV, P.RAZON_SOCIAL_PRV, P.NIF_PRV, P.MOVIL_PRV, ' +
    'P.EMAIL_PRV, P.DIRECCION1_PRV, P.DIRECCION2_PRV, P.POBLACION_PRV, ' +
    'P.PROVINCIA_PRV, P.CODIGO_PAI_PRV, P.PAIS_PRV, ' +
    'P.CODIGO_POSTAL_PRV, F.CODIGO_IVA_FAC, ' +
    'IF(COALESCE(F.TOTAL_REN_FAC, 0) + COALESCE(F.TOTAL_RER_FAC, 0) + ' +
    '   COALESCE(F.TOTAL_RES_FAC, 0) + COALESCE(F.TOTAL_REE_FAC, 0) ' +
    '   <> 0, ''S'', ''N''), ' +
    'COALESCE(F.ESINTRACOMUNITARIO_CLIENTE_FAC, ''N''), ' +
    'F.PORCENTAJE_IVAN_FAC, F.TOTAL_BASEI_IVAN_FAC, F.TOTAL_IVAN_FAC, ' +
    'F.PORCENTAJE_REN_FAC, F.TOTAL_REN_FAC, ' +
    'F.PORCENTAJE_IVAR_FAC, F.TOTAL_BASEI_IVAR_FAC, F.TOTAL_IVAR_FAC, ' +
    'F.PORCENTAJE_RER_FAC, F.TOTAL_RER_FAC, ' +
    'F.PORCENTAJE_IVAS_FAC, F.TOTAL_BASEI_IVAS_FAC, F.TOTAL_IVAS_FAC, ' +
    'F.PORCENTAJE_RES_FAC, F.TOTAL_RES_FAC, ' +
    'F.PORCENTAJE_IVAE_FAC, F.TOTAL_BASEI_IVAE_FAC, F.TOTAL_IVAE_FAC, ' +
    'F.PORCENTAJE_REE_FAC, F.TOTAL_REE_FAC, ' +
    'F.PORCENTAJE_RETENCION_FAC, F.TOTAL_RETENCION_FAC, ' +
    'F.TOTAL_BASES_FAC, F.TOTAL_BASES_FAC, F.TOTAL_IMPUESTOS_FAC, ' +
    'COALESCE(F.TOTAL_BASES_FAC, 0) + COALESCE(F.TOTAL_IMPUESTOS_FAC, 0), ' +
    'F.TOTAL_LIQUIDO_FAC, F.FORMA_PAGO_FAC, F.CONTADOR_LINEAS_FAC, ' +
    ':COMENTARIO, ''N'', NOW(), NOW(), :USUARIO, :USUARIO ' +
    'FROM fza_facturas F ' +
    'JOIN fza_empresas D ON D.CODIGO_EMP_EMP = :DESTINO ' +
    'JOIN fza_proveedores P ON P.CODIGO_PRV_PRV = :PROVEEDOR ' +
    'WHERE F.SERIE_FAC = :SERIE_EMITIDA AND F.NUMERO_FAC = :NUMERO_EMITIDA';

  SQL_INSERTAR_LINEAS_RECIBIDA =
    'INSERT INTO fza_facturas_compra_lineas (' +
    'NUMERO_FACC_FACCLIN, SERIE_FACC_FACCLIN, LINEA_FACCLIN, ' +
    'CODIGO_ART_FACCLIN, CODIGO_UNIDAD_FACCLIN, ' +
    'DESCRIPCION_ARTICULO_FACCLIN, TIPO_CANTIDAD_ARTICULO_FACCLIN, ' +
    'CANTIDAD_FACCLIN, TOTAL_UNIDADES_FACCLIN, ' +
    'TIPO_IVA_ARTICULO_FACCLIN, PORCENTAJE_IVA_FACCLIN, ' +
    'PRECIO_COMPRA_SIVA_ARTICULO_FACCLIN, ' +
    'PRECIO_COMPRA_CIVA_ARTICULO_FACCLIN, TOTAL_FACCLIN, ' +
    'ATTR1_VALOR_FACCLIN, ATTR1_NOMBRE_FACCLIN, ' +
    'ATTR2_VALOR_FACCLIN, ATTR2_NOMBRE_FACCLIN, ' +
    'ATTR3_VALOR_FACCLIN, ATTR3_NOMBRE_FACCLIN, ' +
    'ATTR4_VALOR_FACCLIN, ATTR4_NOMBRE_FACCLIN, ' +
    'ATTR5_VALOR_FACCLIN, ATTR5_NOMBRE_FACCLIN, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :NUMERO, :SERIE, L.LINEA_FACLIN, ' +
    'L.CODIGO_ART_FACLIN, L.CODIGO_UNIDAD_FACLIN, ' +
    'L.DESCRIPCION_ARTICULO_FACLIN, L.TIPO_CANTIDAD_ARTICULO_FACLIN, ' +
    'L.CANTIDAD_FACLIN, L.CANTIDAD_FACLIN, ' +
    'L.TIPO_IVA_ARTICULO_FACLIN, L.PORCENTAJE_IVA_FACLIN, ' +
    'COALESCE(L.TOTAL_FAC_SIVA_FACLIN / NULLIF(L.CANTIDAD_FACLIN, 0), ' +
    '  L.PRECIO_VENTA_SIVA_ARTICULO_FACLIN), ' +
    'L.PRECIO_VENTA_CIVA_ARTICULO_FACLIN, L.TOTAL_FAC_SIVA_FACLIN, ' +
    'L.ATTR1_VALOR_FACLIN, L.ATTR1_NOMBRE_FACLIN, ' +
    'L.ATTR2_VALOR_FACLIN, L.ATTR2_NOMBRE_FACLIN, ' +
    'L.ATTR3_VALOR_FACLIN, L.ATTR3_NOMBRE_FACLIN, ' +
    'L.ATTR4_VALOR_FACLIN, L.ATTR4_NOMBRE_FACLIN, ' +
    'L.ATTR5_VALOR_FACLIN, L.ATTR5_NOMBRE_FACLIN, ' +
    'NOW(), NOW(), :USUARIO, :USUARIO ' +
    'FROM fza_facturas_lineas L ' +
    'WHERE L.SERIE_FAC_FACLIN = :SERIE_EMITIDA ' +
    '  AND L.NUMERO_FAC_FACLIN = :NUMERO_EMITIDA';

  // Cuadre: cada factura interna consolidada del periodo frente a la
  // recibida de su empresa destino: la del proveedor P_<emisora> cuyo
  // número de factura del proveedor es SERIE/NUMERO, la grabe la
  // consolidación o se registre a mano (FZ-ISSUE-389).
  SQL_CUADRE_FACTURAS_INTERNAS =
    'SELECT F.CODIGO_EMP_FAC AS EMISORA, D.CODIGO_EMP_EMP AS DESTINO, ' +
    'F.SERIE_FAC, F.NUMERO_FAC, F.FECHA_FAC, ' +
    'COALESCE(F.TOTAL_LIQUIDO_FAC, 0) AS EMITIDO, ' +
    'C.SERIE_FACC, C.NUMERO_FACC, ' +
    'COALESCE(C.TOTAL_LIQUIDO_FACC, 0) AS RECIBIDO ' +
    'FROM fza_facturas F ' +
    'JOIN fza_empresas D ' +
    '  ON D.CODIGO_CLI_TRASPASOS_EMP = F.CODIGO_CLI_FAC ' +
    ' AND D.CODIGO_EMP_EMP <> F.CODIGO_EMP_FAC ' +
    'LEFT JOIN fza_facturas_compra C ' +
    '  ON C.CODIGO_EMP_FACC = D.CODIGO_EMP_EMP ' +
    ' AND C.CODIGO_PRV_FACC = CONCAT(''' + PREFIJO_PROVEEDOR_EMPRESA +
    ''', TRIM(F.CODIGO_EMP_FAC)) ' +
    ' AND ' + SQL_DOCUMENTO_PROVEEDOR_RECIBIDA +
    ' = CONCAT(TRIM(F.SERIE_FAC), ''/'', TRIM(F.NUMERO_FAC)) ' +
    ' AND COALESCE(C.ESTADO_FACC, '''') <> ''CANCELADA'' ' +
    'WHERE F.ESCONSOLIDADA_FAC = ''S'' ' +
    '  AND F.FECHA_FAC BETWEEN :DESDE AND :HASTA ' +
    'ORDER BY F.CODIGO_EMP_FAC, D.CODIGO_EMP_EMP, F.FECHA_FAC, ' +
    '  F.SERIE_FAC, F.NUMERO_FAC';

// Servicio que la consolidación llama tras emitir la factura.
function CrearServicioFacturaRecibidaInternaUniDAC(
  AConexion: TUniConnection): IServicioFacturaRecibidaInterna;

// 'P_' + código de la empresa emisora.
function CodigoProveedorEmpresa(const ACodigoEmpresa: string): string;

function CargarCuadreFacturasInternas(
  AConexion: TUniConnection;
  ADesde, AHasta: TDateTime): TLineasCuadreFacturasInternas;

// Facturas del cuadre que no tienen recibida.
function ContarSinRecibida(
  const ALineas: TLineasCuadreFacturasInternas): Integer;

// Registra la recibida de cada factura del cuadre que no la tiene, con el
// mismo servicio que la consolidación. Devuelve una línea por factura con
// el resultado o el motivo por el que no se pudo (FZ-ISSUE-389).
function RegistrarRecibidasPendientes(
  AConexion: TUniConnection;
  const ALineas: TLineasCuadreFacturasInternas;
  const AUsuario: string): string;

// Texto del informe: una línea por factura con su estado (OK, SIN
// RECIBIDA o DIFERENCIA) y los totales de cada pareja emisora-destino.
function TextoCuadreFacturasInternas(
  const ALineas: TLineasCuadreFacturasInternas;
  ADesde, AHasta: TDateTime): string;

implementation

uses
  System.SysUtils,
  System.Classes,
  Data.DB,
  inLibDocumento,
  inLibDocumentoIntf,
  inLibMsgFacturas,
  UniDataValoresAutomaticosRepositorio,
  UniDataClienteTraspasosEmpresaRepositorio;

type
  TServicioFacturaRecibidaInternaUniDAC = class(TInterfacedObject,
    IServicioFacturaRecibidaInterna, IPreparacionFacturaRecibidaInterna)
  private
    FConexion: TUniConnection;
    function CrearConsulta(const ASql: string): TUniQuery;
    function SiguienteNumero(
      const ASerie, AEmpresa, AUsuario: string): string;
    function Grabar(
      const ASerie, ANumero, AEmisora, ADestino, AUsuario: string): string;
  public
    constructor Create(AConexion: TUniConnection);
    procedure PrepararAntesDeEmitir(const ASerie, ANumero: string);
    function Registrar(const ASerie, ANumero, AUsuario: string): string;
  end;

function CodigoProveedorEmpresa(const ACodigoEmpresa: string): string;
begin
  Result := PREFIJO_PROVEEDOR_EMPRESA + Trim(ACodigoEmpresa);
end;

function DocumentoEmitido(const ASerie, ANumero: string): string;
begin
  Result := Trim(ASerie) + '/' + Trim(ANumero);
end;

constructor TServicioFacturaRecibidaInternaUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TServicioFacturaRecibidaInternaUniDAC.CrearConsulta(
  const ASql: string): TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
  Result.SQL.Text := ASql;
end;

procedure TServicioFacturaRecibidaInternaUniDAC.PrepararAntesDeEmitir(
  const ASerie, ANumero: string);
var
  oConsulta: TUniQuery;
  sDestino: string;
  sSerie: string;
begin
  oConsulta := CrearConsulta(SQL_FACTURA_INTERNA);
  try
    oConsulta.ParamByName('SERIE_EMITIDA').AsString := ASerie;
    oConsulta.ParamByName('NUMERO_EMITIDA').AsString := ANumero;
    oConsulta.Open;
    sDestino := oConsulta.FieldByName('DESTINO').AsString;
    if sDestino <> '' then
    begin
      AsegurarContadorCompraEmpresa(FConexion, sDestino, 'SISTEMA');
      sSerie := ObtenerSerieDefecto(FConexion, sDestino, 'FA');
      oConsulta.Close;
      oConsulta.SQL.Text :=
        'SELECT CON FROM fza_contadores ' +
        'WHERE TIPO_DOC_CON = ''FP'' AND EMPRESA_CON = :EMPRESA ' +
        'AND SERIE_CON = :SERIE AND ESACTIVO_CON = ''S'' ' +
        'AND NUM_DIGITOS_CON BETWEEN 1 AND 12 ' +
        'AND CON BETWEEN 0 AND 999999999999';
      oConsulta.ParamByName('EMPRESA').AsString := sDestino;
      oConsulta.ParamByName('SERIE').AsString := sSerie;
      oConsulta.Open;
      if (sSerie = '') or oConsulta.IsEmpty then
        raise EConsolidacionFactura.CreateFmt(
          SErrorConfiguracionRecibidaInterna, [sDestino, sSerie]);
    end;
  finally
    oConsulta.Free;
  end;
end;

function TServicioFacturaRecibidaInternaUniDAC.SiguienteNumero(
  const ASerie, AEmpresa, AUsuario: string): string;
var
  oContador: TUniStoredProc;
begin
  oContador := TUniStoredProc.Create(nil);
  try
    oContador.Connection := FConexion;
    oContador.StoredProcName := 'PRC_GET_NEXT_CONT_FACT_SERIE';
    oContador.Params.CreateParam(ftString, 'pserie', ptInput);
    oContador.Params.CreateParam(ftString, 'ptipodoc', ptInput);
    oContador.Params.CreateParam(ftString, 'pEMPRESA_CONTADOR', ptInput);
    oContador.Params.CreateParam(ftString, 'pUSUARIOMODIF', ptInput);
    oContador.Params.CreateParam(ftString, 'pcont', ptOutput);
    oContador.ParamByName('pserie').AsString := ASerie;
    oContador.ParamByName('ptipodoc').AsString :=
      CrearConfiguracionDocumento(tdFactura, sdCompra).TipoContador;
    oContador.ParamByName('pEMPRESA_CONTADOR').AsString := AEmpresa;
    oContador.ParamByName('pUSUARIOMODIF').AsString := AUsuario;
    // Sin preguntar: si el contador necesita reparación se avisa con el
    // error y la consolidación no se deshace.
    EjecutarContadorDocumentoUniDAC(oContador, False,
      function(AMensaje: string): Boolean
      begin
        Result := False;
      end);
    Result := Trim(oContador.ParamByName('pcont').AsString);
  finally
    FreeAndNil(oContador);
  end;
  if (Result = '') or (StrToInt64Def(Result, 0) <= 0) then
    raise Exception.CreateFmt(SErrorContadorRecibidaInterna,
      [ASerie, AEmpresa]);
end;

function TServicioFacturaRecibidaInternaUniDAC.Grabar(
  const ASerie, ANumero, AEmisora, ADestino, AUsuario: string): string;
var
  oConsulta : TUniQuery;
  sProveedor: string;
  sDocumento: string;
  sSerie    : string;
  sNumero   : string;
begin
  sProveedor := CodigoProveedorEmpresa(AEmisora);
  sDocumento := DocumentoEmitido(ASerie, ANumero);
  oConsulta := CrearConsulta(SQL_RECIBIDA_EXISTENTE);
  try
    oConsulta.ParamByName('DESTINO').AsString := ADestino;
    oConsulta.ParamByName('PROVEEDOR').AsString := sProveedor;
    oConsulta.ParamByName('DOCUMENTO').AsString := sDocumento;
    oConsulta.Open;
    sSerie := oConsulta.FieldByName('SERIE_FACC').AsString;
    sNumero := oConsulta.FieldByName('NUMERO_FACC').AsString;
  finally
    FreeAndNil(oConsulta);
  end;
  if sNumero <> '' then
    Result := Format(SInfoRecibidaInternaYaExistia,
      [ADestino, sSerie, sNumero])
  else
  begin
    AsegurarContadorCompraEmpresa(FConexion, ADestino, AUsuario);
    oConsulta := CrearConsulta(SQL_INSERTAR_PROVEEDOR_EMPRESA);
    try
      oConsulta.ParamByName('PROVEEDOR').AsString := sProveedor;
      oConsulta.ParamByName('EMISORA').AsString := AEmisora;
      oConsulta.ParamByName('USUARIO').AsString := AUsuario;
      oConsulta.Execute;
    finally
      FreeAndNil(oConsulta);
    end;
    sSerie := ObtenerSerieDefecto(FConexion, ADestino,
      CrearConfiguracionDocumento(tdFactura, sdCompra).TipoContador);
    if sSerie = '' then
      sSerie := 'C1';
    sNumero := SiguienteNumero(sSerie, ADestino, AUsuario);
    oConsulta := CrearConsulta(SQL_INSERTAR_RECIBIDA);
    try
      oConsulta.ParamByName('NUMERO').AsString := sNumero;
      oConsulta.ParamByName('SERIE').AsString := sSerie;
      oConsulta.ParamByName('DOCUMENTO').AsString := sDocumento;
      oConsulta.ParamByName('DESTINO').AsString := ADestino;
      oConsulta.ParamByName('PROVEEDOR').AsString := sProveedor;
      oConsulta.ParamByName('SERIE_EMITIDA').AsString := ASerie;
      oConsulta.ParamByName('NUMERO_EMITIDA').AsString := ANumero;
      oConsulta.ParamByName('COMENTARIO').AsString := Format(
        SComentarioRecibidaInterna, [AEmisora, sDocumento]);
      oConsulta.ParamByName('USUARIO').AsString := AUsuario;
      oConsulta.Execute;
      oConsulta.SQL.Text := SQL_INSERTAR_LINEAS_RECIBIDA;
      oConsulta.ParamByName('NUMERO').AsString := sNumero;
      oConsulta.ParamByName('SERIE').AsString := sSerie;
      oConsulta.ParamByName('SERIE_EMITIDA').AsString := ASerie;
      oConsulta.ParamByName('NUMERO_EMITIDA').AsString := ANumero;
      oConsulta.ParamByName('USUARIO').AsString := AUsuario;
      oConsulta.Execute;
    finally
      FreeAndNil(oConsulta);
    end;
    Result := Format(SInfoRecibidaInternaRegistrada,
      [ADestino, sSerie, sNumero]);
  end;
end;

function TServicioFacturaRecibidaInternaUniDAC.Registrar(
  const ASerie, ANumero, AUsuario: string): string;
var
  oConsulta: TUniQuery;
  sEmisora : string;
  sDestino : string;
  bPropia  : Boolean;
begin
  Result := '';
  oConsulta := CrearConsulta(SQL_FACTURA_INTERNA);
  try
    oConsulta.ParamByName('SERIE_EMITIDA').AsString := ASerie;
    oConsulta.ParamByName('NUMERO_EMITIDA').AsString := ANumero;
    oConsulta.Open;
    sEmisora := oConsulta.FieldByName('EMISORA').AsString;
    sDestino := oConsulta.FieldByName('DESTINO').AsString;
  finally
    FreeAndNil(oConsulta);
  end;
  if sDestino <> '' then
  begin
    bPropia := not FConexion.InTransaction;
    if bPropia then
      FConexion.StartTransaction;
    try
      Result := Grabar(ASerie, ANumero, sEmisora, sDestino, AUsuario);
      if bPropia then
        FConexion.Commit;
    except
      if bPropia then
        FConexion.Rollback;
      raise;
    end;
  end;
end;

function CrearServicioFacturaRecibidaInternaUniDAC(
  AConexion: TUniConnection): IServicioFacturaRecibidaInterna;
begin
  Result := TServicioFacturaRecibidaInternaUniDAC.Create(AConexion);
end;

function CargarCuadreFacturasInternas(
  AConexion: TUniConnection;
  ADesde, AHasta: TDateTime): TLineasCuadreFacturasInternas;
var
  oConsulta: TUniQuery;
  oLinea   : TLineaCuadreFacturaInterna;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := SQL_CUADRE_FACTURAS_INTERNAS;
    oConsulta.ParamByName('DESDE').AsDate := Trunc(ADesde);
    oConsulta.ParamByName('HASTA').AsDate := Trunc(AHasta);
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      oLinea := Default(TLineaCuadreFacturaInterna);
      oLinea.Emisora := oConsulta.FieldByName('EMISORA').AsString;
      oLinea.Destino := oConsulta.FieldByName('DESTINO').AsString;
      oLinea.SerieEmitida := oConsulta.FieldByName('SERIE_FAC').AsString;
      oLinea.NumeroEmitida := oConsulta.FieldByName('NUMERO_FAC').AsString;
      oLinea.Fecha := oConsulta.FieldByName('FECHA_FAC').AsDateTime;
      oLinea.Emitido := oConsulta.FieldByName('EMITIDO').AsCurrency;
      oLinea.TieneRecibida :=
        not oConsulta.FieldByName('NUMERO_FACC').IsNull;
      oLinea.SerieRecibida := oConsulta.FieldByName('SERIE_FACC').AsString;
      oLinea.NumeroRecibida :=
        oConsulta.FieldByName('NUMERO_FACC').AsString;
      oLinea.Recibido := oConsulta.FieldByName('RECIBIDO').AsCurrency;
      Result := Result + [oLinea];
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function ContarSinRecibida(
  const ALineas: TLineasCuadreFacturasInternas): Integer;
var
  iIndice: Integer;
begin
  Result := 0;
  for iIndice := 0 to High(ALineas) do
    if not ALineas[iIndice].TieneRecibida then
      Inc(Result);
end;

function RegistrarRecibidasPendientes(
  AConexion: TUniConnection;
  const ALineas: TLineasCuadreFacturasInternas;
  const AUsuario: string): string;
var
  oServicio: IServicioFacturaRecibidaInterna;
  oTexto   : TStringList;
  iIndice  : Integer;
  sFactura : string;
begin
  oServicio := CrearServicioFacturaRecibidaInternaUniDAC(AConexion);
  oTexto := TStringList.Create;
  try
    for iIndice := 0 to High(ALineas) do
      if not ALineas[iIndice].TieneRecibida then
      begin
        sFactura := DocumentoEmitido(ALineas[iIndice].SerieEmitida,
          ALineas[iIndice].NumeroEmitida);
        try
          oTexto.Add(sFactura + ': ' + oServicio.Registrar(
            ALineas[iIndice].SerieEmitida,
            ALineas[iIndice].NumeroEmitida, AUsuario));
        except
          // Una que falle (sin serie de compras, contador...) no impide
          // registrar las demás: el motivo va al resultado.
          on E: Exception do
            oTexto.Add(sFactura + ': ' + E.Message);
        end;
      end;
    Result := TrimRight(oTexto.Text);
  finally
    FreeAndNil(oTexto);
  end;
end;

function Importe(AValor: Currency): string;
begin
  Result := FormatCurr('#,##0.00', AValor);
end;

function EstadoCuadre(const ALinea: TLineaCuadreFacturaInterna): string;
begin
  if not ALinea.TieneRecibida then
    Result := SEstadoCuadreSinRecibida
  else if ALinea.Emitido <> ALinea.Recibido then
    Result := Format(SEstadoCuadreDiferencia,
      [Importe(ALinea.Emitido - ALinea.Recibido)])
  else
    Result := SEstadoCuadreOk;
end;

function TextoCuadreFacturasInternas(
  const ALineas: TLineasCuadreFacturasInternas;
  ADesde, AHasta: TDateTime): string;
var
  oTexto   : TStringList;
  iIndice  : Integer;
  sPareja  : string;
  sRecibida: string;
  cEmitido : Currency;
  cRecibido: Currency;
  iPendientes: Integer;

  procedure CerrarPareja;
  begin
    if sPareja <> '' then
    begin
      oTexto.Add(Format(STotalCuadrePareja,
        [sPareja, Importe(cEmitido), Importe(cRecibido),
         Importe(cEmitido - cRecibido)]));
      oTexto.Add('');
    end;
  end;

begin
  oTexto := TStringList.Create;
  try
    oTexto.Add(Format(SCabeceraCuadreFacturasInternas,
      [DateToStr(ADesde), DateToStr(AHasta)]));
    oTexto.Add('');
    sPareja := '';
    cEmitido := 0;
    cRecibido := 0;
    iPendientes := 0;
    for iIndice := 0 to High(ALineas) do
    begin
      if ALineas[iIndice].Emisora + ' -> ' + ALineas[iIndice].Destino <>
         sPareja then
      begin
        CerrarPareja;
        sPareja := ALineas[iIndice].Emisora + ' -> ' +
          ALineas[iIndice].Destino;
        cEmitido := 0;
        cRecibido := 0;
      end;
      sRecibida := '-';
      if ALineas[iIndice].TieneRecibida then
        sRecibida := ALineas[iIndice].SerieRecibida + '/' +
          ALineas[iIndice].NumeroRecibida + ' ' +
          Importe(ALineas[iIndice].Recibido);
      oTexto.Add(Format(SLineaCuadreFacturaInterna,
        [sPareja, ALineas[iIndice].SerieEmitida,
         ALineas[iIndice].NumeroEmitida,
         DateToStr(ALineas[iIndice].Fecha),
         Importe(ALineas[iIndice].Emitido), sRecibida,
         EstadoCuadre(ALineas[iIndice])]));
      cEmitido := cEmitido + ALineas[iIndice].Emitido;
      cRecibido := cRecibido + ALineas[iIndice].Recibido;
      if EstadoCuadre(ALineas[iIndice]) <> SEstadoCuadreOk then
        Inc(iPendientes);
    end;
    CerrarPareja;
    if Length(ALineas) = 0 then
      oTexto.Add(SInfoCuadreSinFacturasInternas)
    else
      oTexto.Add(Format(SResumenCuadreFacturasInternas,
        [Length(ALineas), iPendientes]));
    Result := TrimRight(oTexto.Text);
  finally
    FreeAndNil(oTexto);
  end;
end;

end.
