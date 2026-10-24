{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoInventariosPresentacionBusquedas                         }
{    Tipo:       Presentacion (sin formulario)                                 }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Dialogos de busqueda de articulo y SKU del mantenimiento de               }
{    inventarios. Recibe el puerto de datos ya abierto: no crea consultas,     }
{    no escribe SQL y no conserva el formulario.                               }
{******************************************************************************}
unit inMtoInventariosPresentacionBusquedas;

interface

uses
  inLibMsgArticulos,
  Vcl.Forms,
  inLibGenBusq,
  inLibInventariosAplicacionIntf;

function BuscarArticuloInventario(
  const ABusquedas: IBusquedasInventario;
  const ABusquedaVisual: IBusquedaVisual;
  AFormularioPadre: TCustomForm): string;
function BuscarSkuInventario(
  const ABusquedas: IBusquedasInventario;
  const ABusquedaVisual: IBusquedaVisual;
  const ACodigoAlmacen: string;
  AFormularioPadre: TCustomForm): string;

implementation

uses
  Data.DB;


// Fija DisplayLabel y formato de un campo para que la grilla generica
// muestre cabeceras legibles sin layout guardado.
procedure ConfigurarCampoBusqueda(
  ACampo: TField; const AEtiqueta, AFormato: string);
begin
  if ACampo <> nil then
  begin
    ACampo.DisplayLabel := AEtiqueta;
    if AFormato <> '' then
    begin
      if ACampo is TFloatField then
        TFloatField(ACampo).DisplayFormat := AFormato
      else if ACampo is TBCDField then
        TBCDField(ACampo).DisplayFormat := AFormato
      else if ACampo is TSQLTimeStampField then
        TSQLTimeStampField(ACampo).DisplayFormat := AFormato;
    end;
  end;
end;

function BuscarArticuloInventario(
  const ABusquedas: IBusquedasInventario;
  const ABusquedaVisual: IBusquedaVisual;
  AFormularioPadre: TCustomForm): string;
var
  oResultado: IResultadoConsultaInventario;
  oDatos: TDataSet;
begin
  Result := '';
  oResultado := ABusquedas.ConsultarArticulos;
  oDatos := oResultado.DataSet;
  ConfigurarCampoBusqueda(oDatos.FindField('CODIGO_ART_ART'),
    SCaptionCodigoBusquedaInventario, '');
  ConfigurarCampoBusqueda(oDatos.FindField('DESCRIPCION_ART'),
    SCaptionDescripcionBusquedaInventario, '');
  ConfigurarCampoBusqueda(oDatos.FindField('DESCRIPCION_FAM'),
    SCaptionFamiliaBusquedaInventario, '');
  ConfigurarCampoBusqueda(oDatos.FindField('TEMPORADA'),
    SCaptionTemporadaBusquedaInventario, '');
  ConfigurarCampoBusqueda(oDatos.FindField('RAZON_SOCIAL_PROVEEDOR'),
    SCaptionProveedorBusquedaInventario, '');
  ConfigurarCampoBusqueda(oDatos.FindField('REF_PROVEEDOR'),
    SCaptionReferenciaProveedorBusquedaInventario, '');
  ConfigurarCampoBusqueda(oDatos.FindField('PRECIO_ULT_COMPRA'),
    SCaptionPrecioCompraBusquedaInventario, '#,##0.00 €');
  ConfigurarCampoBusqueda(oDatos.FindField('PRECIO_FINAL_ARTTAR'),
    SCaptionPrecioVentaBusquedaInventario, '#,##0.00 €');
  ConfigurarCampoBusqueda(oDatos.FindField('TIPO_CANTIDAD_ART'),
    SCaptionTipoCantidadBusquedaInventario, '');
  if ABusquedaVisual.EjecutarBusquedaDataSet(
       STituloBuscarArticulosInventario, oDatos, 'frmMtoArtInvSearch',
       AFormularioPadre) then
    Result := oDatos.FieldByName('CODIGO_ART_ART').AsString;
end;

function BuscarSkuInventario(
  const ABusquedas: IBusquedasInventario;
  const ABusquedaVisual: IBusquedaVisual;
  const ACodigoAlmacen: string;
  AFormularioPadre: TCustomForm): string;
var
  oResultado: IResultadoConsultaInventario;
  oDatos: TDataSet;
begin
  Result := '';
  oResultado := ABusquedas.ConsultarSkus(ACodigoAlmacen);
  oDatos := oResultado.DataSet;
  ConfigurarCampoBusqueda(oDatos.FindField('CODIGO_UNIDAD_SKU'),
    SCaptionSkuBusquedaInventario, '');
  ConfigurarCampoBusqueda(oDatos.FindField('CODIGO_ART_SKU'),
    SCaptionArticuloBusquedaInventario, '');
  ConfigurarCampoBusqueda(oDatos.FindField('DESCRIPCION_ART'),
    SCaptionDescripcionBusquedaInventario, '');
  ConfigurarCampoBusqueda(oDatos.FindField('ATRIBUTOS'),
    SCaptionAtributosBusquedaInventario, '');
  ConfigurarCampoBusqueda(oDatos.FindField('CANTIDAD_STK'),
    SCaptionStockBusquedaInventario, '#,##0.00');
  ConfigurarCampoBusqueda(oDatos.FindField('PRECIO_MEDIO_STK'),
    SCaptionPrecioMedioBusquedaInventario, '#,##0.0000');
  if ABusquedaVisual.EjecutarBusquedaDataSet(
       STituloBuscarSkusInventario, oDatos, 'frmMtoInvSkuSearch',
       AFormularioPadre) then
    Result := oDatos.FieldByName('CODIGO_UNIDAD_SKU').AsString;
end;

end.
