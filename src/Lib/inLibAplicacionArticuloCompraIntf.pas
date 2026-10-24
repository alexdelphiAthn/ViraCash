{******************************************************************************}
{                                                                              }
{  Módulo:       inLibAplicacionArticuloCompraIntf                            }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos y records para aplicar artículos a documentos de compra.        }
{******************************************************************************}
unit inLibAplicacionArticuloCompraIntf;

interface

uses
  inLibArticulosResolverIntf, inLibArticulosValidadorIntf;

type
  TTipoDocumentoArticuloCompra = (
    tdacPedido,
    tdacFactura,
    tdacAlbaran);

  TAccionPivoteArticuloCompra = (
    apacNinguna,
    apacDesactivar,
    apacActivarYRecargar,
    apacRecargar);

  TConfiguracionCamposArticuloCompra = record
    CampoProveedorCabecera: string;
    CampoAlmacenCabecera: string;
    CampoFechaCabecera: string;
    CampoPreferenciaPivoteCabecera: string;
    CampoCodigoArticulo: string;
    CampoCodigoSku: string;
    CampoReferenciaProveedor: string;
    CampoCodigoFamilia: string;
    CampoNombreFamilia: string;
    CampoDescripcionArticulo: string;
    CampoTipoCantidad: string;
    CampoTipoIva: string;
    CampoAlmacenLinea: string;
    CampoIdConjuntoPivote: string;
    CampoCantidad: string;
    CampoTotalUnidades: string;
    CampoPrecioCompra: string;
    CampoTotal: string;
    SufijoCabecera: string;
    SufijoLinea: string;
    ActualizarTotalUnidadesSiempre: Boolean;
    GestionarPivoteAntiguo: Boolean;
  end;

  TEntradaAplicacionArticuloCompra = record
    CodigoIntroducido: string;
    CodigoProveedor: string;
    CodigoAlmacen: string;
    PreferenciaPivoteHorizontal: string;
    Fecha: TDateTime;
    PivoteActivo: Boolean;
  end;

  // Lo que la línea ya tenía antes de aplicar el artículo.
  TLineaActualArticuloCompra = record
    CodigoArticulo: string;
    CodigoSku: string;
    Cantidad: Double;
    PrecioCompra: Double;
  end;

  TLineaArticuloCompra = record
    CodigoArticulo: string;
    CodigoSku: string;
    ReferenciaProveedor: string;
    CodigoFamilia: string;
    NombreFamilia: string;
    DescripcionArticulo: string;
    TipoCantidad: string;
    TipoIva: string;
    CodigoAlmacen: string;
    IdConjuntoPivote: Integer;
    Cantidad: Double;
    TotalUnidades: Double;
    PrecioCompra: Double;
    Total: Double;
    AsignarAlmacen: Boolean;
    AsignarCantidad: Boolean;
    AsignarTotalUnidades: Boolean;
  end;

  TResultadoAplicacionArticuloCompra = record
    Aplicado: Boolean;
    RequiereSku: Boolean;
    Mensaje: string;
    IdConjuntoPivote: Integer;
    AccionPivote: TAccionPivoteArticuloCompra;
  end;

  IRepositorioLecturasArticuloCompra = interface
    ['{5DB60C9A-EA9E-4A98-9B49-7869E89F4D65}']
    function ResolverEntrada(
      const AEntrada: string): TArtResolucionEntrada;
    function ResolverDatos(
      const ACodigoArticulo, ACodigoSku: string;
      const AFecha: TDateTime;
      const ACodigoAlmacen,
      ACodigoProveedor: string): TArticuloDatos;
    function ResolverUltimoCoste(
      const ACodigoArticulo,
      ACodigoProveedor: string): TArticuloCoste;
    function BuscarConjuntoPivote(
      const ACodigoArticulo: string): Integer;
    function BuscarModeloProveedor(
      const ACodigoArticulo,
      ACodigoProveedor: string): string;
  end;

  IPuertoLineaArticuloCompra = interface
    ['{EFFC91F3-C50C-4736-B046-441F30C24BAA}']
    function PrepararLinea(
      const AConfiguracion: TConfiguracionCamposArticuloCompra;
      out AActual: TLineaActualArticuloCompra): Boolean;
    procedure AplicarLinea(
      const AConfiguracion: TConfiguracionCamposArticuloCompra;
      const ALinea: TLineaArticuloCompra);
  end;

  IAplicacionArticuloCompra = interface
    ['{B5D159EC-34AA-4AE4-A30D-2CF793FD8A42}']
    function Ejecutar(
      const AEntrada: TEntradaAplicacionArticuloCompra;
      ATipoDocumento: TTipoDocumentoArticuloCompra):
      TResultadoAplicacionArticuloCompra;
  end;

function ConfiguracionCamposArticuloCompra(
  ATipoDocumento: TTipoDocumentoArticuloCompra):
  TConfiguracionCamposArticuloCompra;

implementation

function ConfiguracionCamposArticuloCompra(
  ATipoDocumento: TTipoDocumentoArticuloCompra):
  TConfiguracionCamposArticuloCompra;
begin
  Result := Default(TConfiguracionCamposArticuloCompra);
  case ATipoDocumento of
    tdacPedido:
      begin
        Result.SufijoCabecera := 'PEDC';
        Result.SufijoLinea := 'PEDCLIN';
        // Pedidos usa el modo horizontal comun. No debe reactivar el
        // TGridPivoteCompra retirado al resolver un articulo.
        Result.GestionarPivoteAntiguo := False;
      end;
    tdacFactura:
      begin
        Result.SufijoCabecera := 'FACC';
        Result.SufijoLinea := 'FACCLIN';
        Result.ActualizarTotalUnidadesSiempre := True;
      end;
    tdacAlbaran:
      begin
        Result.SufijoCabecera := 'ALBC';
        Result.SufijoLinea := 'ALBCLIN';
      end;
  end;
  Result.CampoProveedorCabecera :=
    'CODIGO_PRV_' + Result.SufijoCabecera;
  Result.CampoAlmacenCabecera :=
    'CODIGO_ALM_' + Result.SufijoCabecera;
  Result.CampoFechaCabecera :=
    'FECHA_' + Result.SufijoCabecera;
  Result.CampoPreferenciaPivoteCabecera :=
    'ESPIVOTE_HORIZONTAL_' + Result.SufijoCabecera;
  Result.CampoCodigoArticulo :=
    'CODIGO_ART_' + Result.SufijoLinea;
  Result.CampoCodigoSku :=
    'CODIGO_UNIDAD_' + Result.SufijoLinea;
  Result.CampoReferenciaProveedor :=
    'REF_PRV_' + Result.SufijoLinea;
  Result.CampoCodigoFamilia :=
    'CODIGO_FAM_' + Result.SufijoLinea;
  if ATipoDocumento = tdacFactura then
    Result.CampoNombreFamilia := 'NOMBRE_FAM_' + Result.SufijoLinea;
  Result.CampoDescripcionArticulo :=
    'DESCRIPCION_ARTICULO_' + Result.SufijoLinea;
  Result.CampoTipoCantidad :=
    'TIPO_CANTIDAD_ARTICULO_' + Result.SufijoLinea;
  Result.CampoTipoIva :=
    'TIPO_IVA_ARTICULO_' + Result.SufijoLinea;
  Result.CampoAlmacenLinea :=
    'CODIGO_ALMACEN_' + Result.SufijoLinea;
  Result.CampoIdConjuntoPivote :=
    'ID_AC_PIVOT_' + Result.SufijoLinea;
  Result.CampoCantidad :=
    'CANTIDAD_' + Result.SufijoLinea;
  Result.CampoTotalUnidades :=
    'TOTAL_UNIDADES_' + Result.SufijoLinea;
  Result.CampoPrecioCompra :=
    'PRECIO_COMPRA_SIVA_ARTICULO_' + Result.SufijoLinea;
  Result.CampoTotal := 'TOTAL_' + Result.SufijoLinea;
end;

end.
