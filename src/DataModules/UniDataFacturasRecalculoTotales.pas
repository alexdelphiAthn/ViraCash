{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataFacturasRecalculoTotales                               }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Recalcula y graba líneas y totales de una factura de venta ya creada      }
{    con TFacturaTotales (el motor de la pantalla de facturas). Lo usan las    }
{    facturas generadas en BBDD (proformas, albaranes): los procedimientos     }
{    copian importes sin el redondeo actual (FZ-ISSUE-242).                    }
{******************************************************************************}
unit UniDataFacturasRecalculoTotales;

interface

uses
  Uni;

// Recalcula la factura ASerie/ANumero por la conexion (y transaccion)
// AConexion. False con AMensajeError si TFacturaTotales no puede.
function RecalcularTotalesFacturaVenta(AConexion: TUniConnection;
  const ASerie, ANumero: string; out AMensajeError: string): Boolean;

implementation

uses
  System.SysUtils, Data.DB, inLibFacturas, UniDataFacturasLecturas;

const
  // Lo que TFacturaTotales lee o puede escribir de la factura: los totales
  // se calculan con el mismo motor que la pantalla de facturas. No se usa
  // PRC_CALCULAR_FACTURA_NETOS: en el modelo le falta el recorrido de las
  // líneas (deja la cabecera a cero) y hace START TRANSACTION/COMMIT, que
  // confirmaría a medias la transacción del borrador.
  SQL_CABECERA_FACTURA_TOTALES =
    'SELECT PORCENTAJE_DTO_COMERCIAL_FAC, ' +
    'TOTAL_DTO_COMERCIAL_FAC, ' +
    'PORCENTAJE_DTO_FINANCIERO_FAC, ' +
    'TOTAL_DTO_FINANCIERO_FAC, ' +
    'NUMERO_FAC, SERIE_FAC, FECHA_FAC, TIPO_FAC, CODIGO_EMP_FAC, ' +
    'CODIGO_CLI_FAC, RAZON_SOCIAL_EMPRESA_FAC, NIF_EMPRESA_FAC, ' +
    'MOVIL_EMPRESA_FAC, EMAIL_EMPRESA_FAC, DIRECCION1_EMPRESA_FAC, ' +
    'DIRECCION2_EMPRESA_FAC, POBLACION_EMPRESA_FAC, ' +
    'PROVINCIA_EMPRESA_FAC, CODIGO_POSTAL_EMPRESA_FAC, ' +
    'NOMBRE_PAI_EMPRESA_FAC, CODIGO_PAI_EMPRESA_FAC, ' +
    'GRUPO_ZONA_IVA_EMPRESA_FAC, ESRETENCIONES_EMPRESA_FAC, ' +
    'ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC, TEXTO_LEGAL_EMPRESA_FAC, ' +
    'RAZON_SOCIAL_CLIENTE_FAC, NIF_CLIENTE_FAC, MOVIL_CLIENTE_FAC, ' +
    'EMAIL_CLIENTE_FAC, DIRECCION1_CLIENTE_FAC, DIRECCION2_CLIENTE_FAC, ' +
    'POBLACION_CLIENTE_FAC, PROVINCIA_CLIENTE_FAC, ' +
    'CODIGO_POSTAL_CLIENTE_FAC, NOMBRE_PAI_CLIENTE_FAC, ' +
    'CODIGO_PAI_CLIENTE_FAC, ESIVA_RECARGO_CLIENTE_FAC, ' +
    'ESIVA_EXENTO_CLIENTE_FAC, ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC, ' +
    'ESRETENCIONES_CLIENTE_FAC, ESINTRACOMUNITARIO_CLIENTE_FAC, ' +
    'ESIMP_INCL_TARIFA_CLIENTE_FAC, TARIFA_ARTICULO_CLIENTE_FAC, ' +
    'FORMA_PAGO_FAC, ESVENTA_ACTIVO_FIJO_FAC, CODIGO_IVA_FAC, ' +
    'ESIRPF_IMP_INCL_ZONA_IVA_FAC, ESAPLICA_RE_ZONA_IVA_FAC, ' +
    'ESIVAAGRICOLA_ZONA_IVA_FAC, PORCENTAJE_IVAN_FAC, ' +
    'PORCENTAJE_IVAR_FAC, PORCENTAJE_IVAS_FAC, PORCENTAJE_IVAE_FAC, ' +
    'PORCENTAJE_REN_FAC, PORCENTAJE_RER_FAC, PORCENTAJE_RES_FAC, ' +
    'PORCENTAJE_REE_FAC, PORCENTAJE_RETENCION_FAC, ' +
    'TOTAL_BASEI_IVAN_FAC, TOTAL_BASEI_IVAR_FAC, TOTAL_BASEI_IVAS_FAC, ' +
    'TOTAL_BASEI_IVAE_FAC, TOTAL_IVAN_FAC, TOTAL_IVAR_FAC, ' +
    'TOTAL_IVAS_FAC, TOTAL_IVAE_FAC, TOTAL_REN_FAC, TOTAL_RER_FAC, ' +
    'TOTAL_RES_FAC, TOTAL_REE_FAC, TOTAL_BASES_FAC, ' +
    'TOTAL_IMPUESTOS_FAC, TOTAL_RETENCION_FAC, TOTAL_LIQUIDO_FAC ' +
    'FROM fza_facturas WHERE SERIE_FAC = :SERIE AND NUMERO_FAC = :NUMERO';
  SQL_LINEAS_FACTURA_TOTALES =
    'SELECT NUMERO_FAC_FACLIN, SERIE_FAC_FACLIN, LINEA_FACLIN, ' +
    'CODIGO_ART_FACLIN, DESCRIPCION_ARTICULO_FACLIN, ' +
    'CODIGO_UNIDAD_FACLIN, CANTIDAD_FACLIN, ESIMP_INCL_TARIFA_FACLIN, ' +
    'TIPO_IVA_ARTICULO_FACLIN, PORCENTAJE_IVA_FACLIN, ' +
    'PRECIO_SALIDA_FACLIN, PORCENTAJE_DTO_FACLIN, PRECIO_DTO_FACLIN, ' +
    'PRECIO_VENTA_SIVA_ARTICULO_FACLIN, ' +
    'PRECIO_VENTA_CIVA_ARTICULO_FACLIN, TOTAL_FACLIN, ' +
    'TOTAL_FAC_SIVA_FACLIN FROM fza_facturas_lineas ' +
    'WHERE SERIE_FAC_FACLIN = :SERIE AND NUMERO_FAC_FACLIN = :NUMERO ' +
    'ORDER BY LINEA_FACLIN';

function RecalcularTotalesFacturaVenta(AConexion: TUniConnection;
  const ASerie, ANumero: string; out AMensajeError: string): Boolean;
var
  oCabecera: TUniQuery;
  oLineas: TUniQuery;
  oTotales: TFacturaTotales;
begin
  AMensajeError := '';
  oCabecera := TUniQuery.Create(nil);
  oLineas := TUniQuery.Create(nil);
  oTotales := nil;
  try
    oCabecera.Connection := AConexion;
    oCabecera.SQL.Text := SQL_CABECERA_FACTURA_TOTALES;
    oCabecera.UpdatingTable := 'fza_facturas';
    oCabecera.KeyFields := 'NUMERO_FAC;SERIE_FAC';
    oCabecera.ParamByName('SERIE').AsString := ASerie;
    oCabecera.ParamByName('NUMERO').AsString := ANumero;
    oCabecera.Open;
    oLineas.Connection := AConexion;
    oLineas.SQL.Text := SQL_LINEAS_FACTURA_TOTALES;
    oLineas.UpdatingTable := 'fza_facturas_lineas';
    oLineas.KeyFields := 'NUMERO_FAC_FACLIN;SERIE_FAC_FACLIN;LINEA_FACLIN';
    oLineas.ParamByName('SERIE').AsString := ASerie;
    oLineas.ParamByName('NUMERO').AsString := ANumero;
    oLineas.Open;
    oTotales := TFacturaTotales.Create(AConexion,
      CrearRepositorioLecturasFacturaUniDAC(AConexion), oCabecera, oLineas);
    Result := oTotales.ProcesarFacturaCompleta;
    if Result then
    begin
      if oLineas.State in dsEditModes then
        oLineas.Post;
      if oCabecera.State in dsEditModes then
        oCabecera.Post;
    end
    else
      AMensajeError := oTotales.MensajeError;
  finally
    FreeAndNil(oTotales);
    FreeAndNil(oLineas);
    FreeAndNil(oCabecera);
  end;
end;

end.
