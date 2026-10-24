{******************************************************************************}
{                                                                              }
{                        Módulo: UniDataPresupuestosSql                        }
{                                Versión: 1.0.0                                }
{                              Fecha: 15/09/2026                               }
{                       Autor: Alejandro Laorden Hidalgo                       }
{                                                                              }
{             Presupuestos e impresión de documentos comerciales.              }
{******************************************************************************}
unit UniDataPresupuestosSql;

interface

uses
  inLibMsgPresupuestos,
  System.Classes, Uni;

procedure ConfigurarConsultasPresupuesto(AOwner: TComponent;
  AConexion: TUniConnection);
procedure ComprobarPresupuestoEditable(AConexion: TUniConnection;
  const ASerie, ANumero: string);
procedure EliminarDetallePresupuesto(AConexion: TUniConnection;
  const ASerie, ANumero: string);

implementation

uses
  System.SysUtils, Data.DB, inLibErroresBBDD;

const
  COLUMNAS_CABECERA =
    'NUMERO_PRE, ' +
    'SERIE_PRE, ' +
    'FECHA_PRE, ' +
    'INSTANTE_MOVIMIENTO_PRE, ' +
    'ESCONSOLIDADO_PRE, ' +
    'ESTADO_PRE, ' +
    'NUMERO_PED_PRE, ' +
    'SERIE_PED_PRE, ' +
    'NUMERO_FAC_PRE, ' +
    'SERIE_FAC_PRE, ' +
    'CODIGO_EMP_PRE, ' +
    'CODIGO_ALM_PRE, ' +
    'RAZON_SOCIAL_EMPRESA_PRE, ' +
    'NIF_EMPRESA_PRE, ' +
    'MOVIL_EMPRESA_PRE, ' +
    'EMAIL_EMPRESA_PRE, ' +
    'DIRECCION1_EMPRESA_PRE, ' +
    'DIRECCION2_EMPRESA_PRE, ' +
    'POBLACION_EMPRESA_PRE, ' +
    'PROVINCIA_EMPRESA_PRE, ' +
    'CODIGO_PAI_EMPRESA_PRE, ' +
    'NOMBRE_PAI_EMPRESA_PRE, ' +
    'CODIGO_POSTAL_EMPRESA_PRE, ' +
    'GRUPO_ZONA_IVA_EMPRESA_PRE, ' +
    'ESRETENCIONES_EMPRESA_PRE, ' +
    'ESREGIMENESPECIALAGRICOLA_EMPRESA_PRE, ' +
    'CODIGO_CLI_PRE, ' +
    'RAZON_SOCIAL_CLIENTE_PRE, ' +
    'NIF_CLIENTE_PRE, ' +
    'MOVIL_CLIENTE_PRE, ' +
    'EMAIL_CLIENTE_PRE, ' +
    'DIRECCION1_CLIENTE_PRE, ' +
    'DIRECCION2_CLIENTE_PRE, ' +
    'POBLACION_CLIENTE_PRE, ' +
    'PROVINCIA_CLIENTE_PRE, ' +
    'CODIGO_POSTAL_CLIENTE_PRE, ' +
    'CODIGO_PAI_CLIENTE_PRE, ' +
    'NOMBRE_PAI_CLIENTE_PRE, ' +
    'NOMBRE_CLI_ENVIO_PRE, ' +
    'MOVIL_CLIENTE_ENVIO_PRE, ' +
    'DIRECCION1_CLIENTE_ENVIO_PRE, ' +
    'DIRECCION2_CLIENTE_ENVIO_PRE, ' +
    'POBLACION_CLIENTE_ENVIO_PRE, ' +
    'PROVINCIA_CLIENTE_ENVIO_PRE, ' +
    'CODIGO_POSTAL_CLIENTE_ENVIO_PRE, ' +
    'CODIGO_PAI_CLIENTE_ENVIO_PRE, ' +
    'NOMBRE_PAI_CLIENTE_ENVIO_PRE, ' +
    'TRANSPORTISTA_PRE, ' +
    'CODIGO_IVA_PRE, ' +
    'ESIVA_RECARGO_CLIENTE_PRE, ' +
    'ESIVA_EXENTO_CLIENTE_PRE, ' +
    'ESINTRACOMUNITARIO_CLIENTE_PRE, ' +
    'ESRETENCIONES_CLIENTE_PRE, ' +
    'ESREGIMENESPECIALAGRICOLA_CLIENTE_PRE, ' +
    'TARIFA_ARTICULO_CLIENTE_PRE, ' +
    'ESIMP_INCL_TARIFA_CLIENTE_PRE, ' +
    'ESAPLICA_RE_ZONA_IVA_PRE, ' +
    'PORCENTAJE_REN_PRE, ' +
    'TOTAL_REN_PRE, ' +
    'PORCENTAJE_RER_PRE, ' +
    'TOTAL_RER_PRE, ' +
    'PORCENTAJE_RES_PRE, ' +
    'TOTAL_RES_PRE, ' +
    'PORCENTAJE_REE_PRE, ' +
    'TOTAL_REE_PRE, ' +
    'TOTAL_BASEI_IVAN_PRE, ' +
    'TOTAL_BASEI_IVAR_PRE, ' +
    'TOTAL_BASEI_IVAS_PRE, ' +
    'TOTAL_BASEI_IVAE_PRE, ' +
    'PORCENTAJE_IVAN_PRE, ' +
    'TOTAL_IVAN_PRE, ' +
    'PORCENTAJE_IVAR_PRE, ' +
    'TOTAL_IVAR_PRE, ' +
    'PORCENTAJE_IVAS_PRE, ' +
    'TOTAL_IVAS_PRE, ' +
    'PORCENTAJE_IVAE_PRE, ' +
    'TOTAL_IVAE_PRE, ' +
    'TOTAL_BASES_PRE, ' +
    'TOTAL_IMPUESTOS_PRE, ' +
    'PORCENTAJE_RETENCION_PRE, ' +
    'TOTAL_RETENCION_PRE, ' +
    'TOTAL_LIQUIDO_PRE, ' +
    'FORMA_PAGO_PRE, ' +
    'CONTADOR_LINEAS_PRE, ' +
    'COMENTARIOS_PRE, ' +
    'OBSERVACIONES_PRE, ' +
    'INSTANTE_MODIF, ' +
    'INSTANTE_ALTA, ' +
    'USUARIO_ALTA, ' +
    'USUARIO_MODIF, ' +
    'TIPO_DESTINO_PRE, ' +
    'SERIE_DESTINO_PRE, ' +
    'NUMERO_DESTINO_PRE, ' +
    'FECHA_VALIDEZ_PRE';
  COLUMNAS_LINEAS =
    'NUMERO_PRE_PRELIN, ' +
    'SERIE_PRE_PRELIN, ' +
    'LINEA_PRELIN, ' +
    'NUMERO_PED_PRELIN, ' +
    'SERIE_PED_PRELIN, ' +
    'LINEA_PED_PRELIN, ' +
    'CODIGO_ART_PRELIN, ' +
    'CODIGO_FAM_PRELIN, ' +
    'NOMBRE_FAM_PRELIN, ' +
    'DESCRIPCION_ARTICULO_PRELIN, ' +
    'TIPO_CANTIDAD_ARTICULO_PRELIN, ' +
    'CANTIDAD_PRELIN, ' +
    'CODIGO_TAR_PRELIN, ' +
    'ESIMP_INCL_TARIFA_PRELIN, ' +
    'TIPO_IVA_ARTICULO_PRELIN, ' +
    'PORCENTAJE_IVA_PRELIN, ' +
    'PRECIO_VENTA_SIVA_ARTICULO_PRELIN, ' +
    'PRECIO_VENTA_CIVA_ARTICULO_PRELIN, ' +
    'TOTAL_PRELIN, ' +
    'CODIGO_ALMACEN_PRELIN, ' +
    'INSTANTE_MODIF, ' +
    'INSTANTE_ALTA, ' +
    'USUARIO_ALTA, ' +
    'USUARIO_MODIF, ' +
    'ESFACTURADA_PRELIN, ' +
    'NUMERO_FAC_PRELIN, ' +
    'SERIE_FAC_PRELIN, ' +
    'LINEA_FAC_PRELIN, ' +
    'CODIGO_UNIDAD_PRELIN, ' +
    'LOTE_PRELIN, ' +
    'FECHA_CADUCIDAD_PRELIN, ' +
    'DESCRIPCION_VARIACION_PRELIN, ' +
    'ATTR1_VALOR_PRELIN, ' +
    'ATTR1_NOMBRE_PRELIN, ' +
    'ATTR2_VALOR_PRELIN, ' +
    'ATTR2_NOMBRE_PRELIN, ' +
    'ATTR3_VALOR_PRELIN, ' +
    'ATTR3_NOMBRE_PRELIN, ' +
    'ATTR4_VALOR_PRELIN, ' +
    'ATTR4_NOMBRE_PRELIN, ' +
    'ATTR5_VALOR_PRELIN, ' +
    'ATTR5_NOMBRE_PRELIN, ' +
    'NUM_ATRIBUTOS_PRELIN, ' +
    'ID_AC_PIVOT_PRELIN';
  COLUMNAS_EMPRESAS =
    'CODIGO_EMP_EMP, ' +
    'ORDEN_EMP, ' +
    'ESACTIVO_EMP, ' +
    'RAZON_SOCIAL_EMP, ' +
    'NIF_EMP, ' +
    'MOVIL_EMP, ' +
    'EMAIL_EMP, ' +
    'DIRECCION1_EMP, ' +
    'DIRECCION2_EMP, ' +
    'CODIGO_POSTAL_EMP, ' +
    'POBLACION_EMP, ' +
    'PROVINCIA_EMP, ' +
    'CODIGO_PAI_EMP, ' +
    'NOMBRE_PAI_EMP, ' +
    'SERIE_CON_EMP, ' +
    'IBAN_EMP, ' +
    'GRUPO_ZONA_IVA_EMP, ' +
    'ESRETENCIONES_EMP, ' +
    'ESIVA_RECARGO_COMPRAS_EMP, ' +
    'ESREGIMENESPECIALAGRICOLA_EMP, ' +
    'CODIGO_CERTIFICADO_EMP, ' +
    'TITULAR_CERTIFICADO_EMP, ' +
    'TIPO_CERTIFICADO_EMP, ' +
    'FECHA_DESDE_CERTIFICADO_EMP, ' +
    'FECHA_HASTA_CERTIFICADO_EMP, ' +
    'NUMERO_INSTALACION_EMP, ' +
    'VERSION_INSTALACION_EMP, ' +
    'CODIGO_SIF_INSTALACION_EMP, ' +
    'INSTANTE_INSTALACION_EMP, ' +
    'TEXTO_LEGAL_FACTURA_EMP, ' +
    'TEXTO_PIE_TICKET_CAJA_1_EMP, ' +
    'TEXTO_PIE_TICKET_CAJA_2_EMP, ' +
    'TEXTO_PIE_TICKET_CAJA_3_EMP, ' +
    'TEXTO_PIE_TICKET_CAJA_4_EMP, ' +
    'FORMATO_DOCUMENTO_EMP, ' +
    'INSTANTE_MODIF, ' +
    'INSTANTE_ALTA, ' +
    'USUARIO_ALTA, ' +
    'USUARIO_MODIF, ' +
    'ESTOKENS_CALENDARIO_NATURAL_EMP';
  COLUMNAS_CLIENTES =
    'CODIGO_CLI_CLI, ' +
    'ESACTIVO_CLI, ' +
    'ORDEN_CLI, ' +
    'RAZON_SOCIAL_CLI, ' +
    'NIF_CLI, ' +
    'MOVIL_CLI, ' +
    'EMAIL_CLI, ' +
    'DIRECCION1_CLI, ' +
    'DIRECCION2_CLI, ' +
    'POBLACION_CLI, ' +
    'PROVINCIA_CLI, ' +
    'CODIGO_POSTAL_CLI, ' +
    'CODIGO_PAI_CLI, ' +
    'NOMBRE_PAI_CLI, ' +
    'NOMBRE_PERSONA_CLIENTE_CLI, ' +
    'APELLIDOS_PERSONA_CLIENTE_CLI, ' +
    'CODIGO_OFICINA_CONTABLE_CLI, ' +
    'CODIGO_ORGANO_GESTOR_CLI, ' +
    'CODIGO_UNIDAD_TRAMITADORA_CLI, ' +
    'OBSERVACIONES_CLI, ' +
    'REFERENCIA_CLI, ' +
    'CONTACTO_CLI, ' +
    'TELEFONO_CONTACTO_CLI, ' +
    'TELEFONO_CLI, ' +
    'IBAN_CLI, ' +
    'ID_MANDATO_SEPA_CLI, ' +
    'FECHA_FIRMA_MANDATO_SEPA_CLI, ' +
    'ESIVA_RECARGO_CLI, ' +
    'ESRETENCIONES_CLI, ' +
    'TOTAL_LIMITE_CREDITO_CLI, ' +
    'ESPERMITE_DEUDA_CLI, ' +
    'TOTAL_DEUDA_CLI, ' +
    'ESIVA_EXENTO_CLI, ' +
    'ESINTRACOMUNITARIO_CLI, ' +
    'ESREGIMENESPECIALAGRICOLA_CLI, ' +
    'CODIGO_FP_CLI, ' +
    'CODIGO_EMPBAN_CLI, ' +
    'TARIFA_ARTICULO_CLI, ' +
    'SERIE_CON_CLI, ' +
    'TEXTO_LEGAL_FACTURA_CLI, ' +
    'INSTANTE_MODIF, ' +
    'INSTANTE_ALTA, ' +
    'USUARIO_ALTA, ' +
    'USUARIO_MODIF';
  COLUMNAS_ARTICULOS =
    'CODIGO_ART_ART, ' +
    'ESACTIVO_ART, ' +
    'ESWEB_ART, ' +
    'TIPO_ART, ' +
    'DESCRIPCION_ART, ' +
    'CODIGO_FAM_ART, ' +
    'TIPO_IVA_ART, ' +
    'ESACTIVO_FIJO_ART, ' +
    'TIPO_CANTIDAD_ART, ' +
    'ESVARIACION_ART, ' +
    'ESTRAZABLE_ART, ' +
    'ORDEN_ART, ' +
    'INSTANTE_MODIF, ' +
    'INSTANTE_ALTA, ' +
    'USUARIO_ALTA, ' +
    'USUARIO_MODIF, ' +
    'TIPO_VARIACION_ART';

function Consulta(AOwner: TComponent; const ANombre: string): TUniQuery;
begin
  Result := AOwner.FindComponent(ANombre) as TUniQuery;
  if Result = nil then
    raise Exception.CreateFmt(SErrorConsultaPresupuestoNoDisponible, [ANombre]);
end;

procedure ConfigurarCabecera(AConsulta: TUniQuery);
var
  oColumnas, oValores, oAsignaciones: TStringList;
  sColumna: string;
begin
  oColumnas := TStringList.Create;
  oValores := TStringList.Create;
  oAsignaciones := TStringList.Create;
  try
    oColumnas.CommaText := COLUMNAS_CABECERA;
    for sColumna in oColumnas do
    begin
      oValores.Add(':' + sColumna);
      if (Pos('DESTINO_PRE', sColumna) = 0) and
         (sColumna <> 'NUMERO_PRE') and (sColumna <> 'SERIE_PRE') then
        oAsignaciones.Add(sColumna + ' = :' + sColumna);
    end;
    AConsulta.SQL.Text := 'SELECT ' + COLUMNAS_CABECERA +
      ' FROM fza_presupuestos ORDER BY FECHA_PRE DESC, NUMERO_PRE DESC';
    AConsulta.KeyFields := 'NUMERO_PRE;SERIE_PRE';
    AConsulta.SQLInsert.Text := 'INSERT INTO fza_presupuestos (' +
      COLUMNAS_CABECERA + ') VALUES (' +
      string.Join(', ', oValores.ToStringArray) + ')';
    AConsulta.SQLUpdate.Text := 'UPDATE fza_presupuestos SET ' +
      string.Join(', ', oAsignaciones.ToStringArray) +
      ' WHERE NUMERO_PRE = :Old_NUMERO_PRE AND SERIE_PRE = :Old_SERIE_PRE' +
      ' AND COALESCE(NUMERO_DESTINO_PRE, '''') = ''''';
    AConsulta.SQLDelete.Text := 'DELETE FROM fza_presupuestos ' +
      'WHERE NUMERO_PRE = :Old_NUMERO_PRE AND SERIE_PRE = :Old_SERIE_PRE' +
      ' AND COALESCE(NUMERO_DESTINO_PRE, '''') = ''''';
    AConsulta.SQLRefresh.Text := 'SELECT ' + COLUMNAS_CABECERA +
      ' FROM fza_presupuestos WHERE NUMERO_PRE = :NUMERO_PRE ' +
      'AND SERIE_PRE = :SERIE_PRE';
  finally
    FreeAndNil(oAsignaciones);
    FreeAndNil(oValores);
    FreeAndNil(oColumnas);
  end;
end;

procedure ConfigurarConsultasPresupuesto(AOwner: TComponent;
  AConexion: TUniConnection);
var
  oComponente: TComponent;
  iComponente: Integer;
begin
  for iComponente := 0 to AOwner.ComponentCount - 1 do
  begin
    oComponente := AOwner.Components[iComponente];
    if oComponente is TUniQuery then
      TUniQuery(oComponente).Connection := AConexion;
    if oComponente is TUniStoredProc then
      TUniStoredProc(oComponente).Connection := AConexion;
  end;
  ConfigurarCabecera(Consulta(AOwner, 'unqryTablaG'));
  Consulta(AOwner, 'unqryAlbaranesLineas').SQL.Text :=
    'SELECT ' + COLUMNAS_LINEAS + ' FROM fza_presupuestos_lineas';
  Consulta(AOwner, 'unqryEmpDataAlb').SQL.Text :=
    'SELECT ' + COLUMNAS_EMPRESAS + ' FROM fza_empresas';
  Consulta(AOwner, 'unqryCliDataAlb').SQL.Text :=
    'SELECT ' + COLUMNAS_CLIENTES + ' FROM fza_clientes';
  Consulta(AOwner, 'unqryArtDataLinAlb').SQL.Text :=
    'SELECT ' + COLUMNAS_ARTICULOS + ' FROM fza_articulos';
  Consulta(AOwner, 'unqryFormasPago').SQL.Text :=
    'SELECT CODIGO_FP_FP, DESCRIPCION_FORMA_PAGO_FP FROM fza_formas_pago';
end;

procedure ComprobarPresupuestoEditable(AConexion: TUniConnection;
  const ASerie, ANumero: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'SELECT NUMERO_DESTINO_PRE FROM fza_presupuestos ' +
      'WHERE SERIE_PRE = :SERIE AND NUMERO_PRE = :NUMERO FOR UPDATE';
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.Open;
    if not oConsulta.IsEmpty and
       (oConsulta.FieldByName('NUMERO_DESTINO_PRE').AsString <> '') then
      // Rechazo de negocio: el gestor global lo presenta como aviso.
      raise EValidacionBBDD.Create(
        SErrorPresupuestoConvertidoSoloLectura);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure EliminarDetallePresupuesto(AConexion: TUniConnection;
  const ASerie, ANumero: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'DELETE FROM fza_presupuestos_celdas ' +
      'WHERE SERIE_PRE_PRECEL = :SERIE AND NUMERO_PRE_PRECEL = :NUMERO';
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.Execute;
    oConsulta.SQL.Text :=
      'DELETE FROM fza_presupuestos_lineas ' +
      'WHERE SERIE_PRE_PRELIN = :SERIE AND NUMERO_PRE_PRELIN = :NUMERO';
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.
