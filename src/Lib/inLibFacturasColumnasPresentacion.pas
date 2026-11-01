{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasColumnasPresentacion                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Construcción de las columnas propias del detalle de una factura.          }
{******************************************************************************}
unit inLibFacturasColumnasPresentacion;

interface

uses
  Data.DB, cxGridDBTableView, inLibUnidadesMedida;

type
  TConfiguracionColumnasFactura = record
    Vista: TcxGridDBTableView;
    DataSourceIvas: TDataSource;
    // Con origen de vendedores la columna Vendedor es un desplegable
    // editable (facturas normales); sin él, solo en simplificadas y fija.
    DataSourceVendedores: TDataSource;
    Tallas: Boolean;
    Simplificada: Boolean;
    DescripcionAmpliada: Boolean;
    MostrarFechaEntrega: Boolean;
    UnidadesMedida: TUnidadesMedida;
  end;

  TColumnasFactura = record
    Linea: TcxGridDBColumn;
    Articulo: TcxGridDBColumn;
    Sku: TcxGridDBColumn;
    DescripcionVariacion: TcxGridDBColumn;
    CodigoFamilia: TcxGridDBColumn;
    NombreFamilia: TcxGridDBColumn;
    EsProveedorPrincipal: TcxGridDBColumn;
    CodigoProveedor: TcxGridDBColumn;
    RazonSocialProveedor: TcxGridDBColumn;
    PrecioUltimaCompra: TcxGridDBColumn;
    DescripcionArticulo: TcxGridDBColumn;
    TipoCantidad: TcxGridDBColumn;
    Cantidad: TcxGridDBColumn;
    PrecioSalida: TcxGridDBColumn;
    PorcentajeDescuento: TcxGridDBColumn;
    PrecioDescuento: TcxGridDBColumn;
    PrecioVentaSinIva: TcxGridDBColumn;
    ImpuestosIncluidos: TcxGridDBColumn;
    TipoIva: TcxGridDBColumn;
    PorcentajeIva: TcxGridDBColumn;
    PrecioVentaConIva: TcxGridDBColumn;
    TotalConIva: TcxGridDBColumn;
    TotalSinIva: TcxGridDBColumn;
    FechaEntrega: TcxGridDBColumn;
  end;

function CrearColumnasFactura(
  const AConfiguracion: TConfiguracionColumnasFactura
): TColumnasFactura;

implementation

uses
  inLibMsgVentas,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, cxButtons, cxButtonEdit,
  cxCalendar, cxCheckBox, cxCurrencyEdit, cxCustomData, cxData,
  cxDataStorage, cxDropDownEdit, cxEdit,
  cxGridCustomTableView, cxGridTableView, cxGridDBDataDefinitions,
  cxLookupEdit, cxDBLookupComboBox, cxLookupDBGrid, cxMemo, cxSpinEdit,
  inLibGridCantidad, inLibFormatoMonetario, inLibMsgArticulos,
  inLibMsgFacturas;

function NuevaColumna(
  AVista: TcxGridDBTableView;
  const ATitulo, ACampo: string;
  AAncho: Integer;
  AEditable: Boolean): TcxGridDBColumn;
begin
  Result := AVista.CreateColumn as TcxGridDBColumn;
  Result.Caption := ATitulo;
  Result.DataBinding.FieldName := ACampo;
  Result.Width := AAncho;
  Result.Options.Editing := AEditable;
end;

// Familia, proveedor y coste son datos internos de la linea: se crean
// ocultos y el detalle los mantiene asi por encima del perfil.
procedure OcultarColumnasCatalogo(var AColumnas: TColumnasFactura);
begin
  AColumnas.CodigoFamilia.Visible := False;
  AColumnas.NombreFamilia.Visible := False;
  AColumnas.EsProveedorPrincipal.Visible := False;
  AColumnas.CodigoProveedor.Visible := False;
  AColumnas.RazonSocialProveedor.Visible := False;
  AColumnas.PrecioUltimaCompra.Visible := False;
end;

// Vendedor de la línea, opcional: Supr lo deja sin asignar.
procedure ConfigurarDesplegableVendedor(
  AColumna: TcxGridDBColumn;
  AOrigen: TDataSource);
const
  cTeclaSuprimir = 46;
var
  Propiedades: TcxLookupComboBoxProperties;
  ColumnaLista: TcxLookupDBGridColumn;
begin
  AColumna.PropertiesClass := TcxLookupComboBoxProperties;
  Propiedades := TcxLookupComboBoxProperties(AColumna.Properties);
  Propiedades.DropDownListStyle := lsFixedList;
  Propiedades.ClearKey := cTeclaSuprimir;
  Propiedades.KeyFieldNames := 'CODIGO_EMPL';
  ColumnaLista := Propiedades.ListColumns.Add;
  ColumnaLista.Caption := SCaptionColumnaFacturaCodigo;
  ColumnaLista.FieldName := 'CODIGO_EMPL';
  ColumnaLista.Width := 80;
  ColumnaLista := Propiedades.ListColumns.Add;
  ColumnaLista.Caption := SCaptionColumnaFacturaVendedor;
  ColumnaLista.FieldName := 'NOMBRE_VENDEDOR';
  ColumnaLista.Width := 220;
  Propiedades.ListFieldIndex := 1;
  Propiedades.ListSource := AOrigen;
end;

procedure CrearColumnasIdentidad(
  const AConfiguracion: TConfiguracionColumnasFactura;
  var AColumnas: TColumnasFactura;
  out AVendedor: TcxGridDBColumn);
begin
  AColumnas.Linea := NuevaColumna(
    AConfiguracion.Vista,
    SCaptionColumnaFacturaNumero,
    'LINEA_FACLIN',
    60,
    False);
  AVendedor := nil;
  if AConfiguracion.Simplificada then
    AVendedor := NuevaColumna(
      AConfiguracion.Vista,
      SCaptionColumnaFacturaVendedor,
      'CODIGO_VENDEDOR_FACLIN',
      90,
      False)
  else if Assigned(AConfiguracion.DataSourceVendedores) then
  begin
    AVendedor := NuevaColumna(
      AConfiguracion.Vista,
      SCaptionColumnaFacturaVendedor,
      'CODIGO_VENDEDOR_FACLIN',
      120,
      True);
    ConfigurarDesplegableVendedor(
      AVendedor, AConfiguracion.DataSourceVendedores);
  end;
  AColumnas.DescripcionVariacion := NuevaColumna(
    AConfiguracion.Vista,
    SCaptionColumnaFacturaVariacion,
    'DESCRIPCION_VARIACION_FACLIN',
    140,
    False);
  AColumnas.DescripcionVariacion.Visible := False;
end;

procedure CrearColumnasCatalogo(
  const AConfiguracion: TConfiguracionColumnasFactura;
  var AColumnas: TColumnasFactura);
begin
  AColumnas.CodigoFamilia := NuevaColumna(
    AConfiguracion.Vista,
    SCaptionColumnaFacturaCodigoFamilia,
    'CODIGO_FAM_FACLIN',
    153,
    True);
  AColumnas.NombreFamilia := NuevaColumna(
    AConfiguracion.Vista,
    SCaptionColumnaFacturaNombreFamilia,
    'NOMBRE_FAM_FACLIN',
    245,
    True);
  AColumnas.EsProveedorPrincipal := NuevaColumna(
    AConfiguracion.Vista,
    SCaptionColumnaFacturaProveedorPrincipal,
    'ESPROVEEDORPRINCIPAL_FACLIN',
    172,
    True);
  AColumnas.EsProveedorPrincipal.PropertiesClass :=
    TcxCheckBoxProperties;
  AColumnas.CodigoProveedor := NuevaColumna(
    AConfiguracion.Vista,
    SCaptionColumnaFacturaCodigoProveedor,
    'CODIGO_PRV_FACLIN',
    163,
    True);
  AColumnas.RazonSocialProveedor := NuevaColumna(
    AConfiguracion.Vista,
    SCaptionColumnaFacturaNombreProveedor,
    'RAZON_SOCIAL_PROVEEDOR_FACLIN',
    200,
    True);
  AColumnas.PrecioUltimaCompra := NuevaColumna(
    AConfiguracion.Vista,
    SCaptionColumnaFacturaCoste,
    'PRECIO_ULT_COMPRA_FACLIN',
    100,
    True);
  AColumnas.PrecioUltimaCompra.PropertiesClass :=
    TcxCurrencyEditProperties;
  OcultarColumnasCatalogo(AColumnas);
end;

procedure CrearColumnasDescripcionCantidad(
  const AConfiguracion: TConfiguracionColumnasFactura;
  var AColumnas: TColumnasFactura);
var
  PropiedadesDescripcion: TcxMemoProperties;
begin
  AColumnas.DescripcionArticulo := NuevaColumna(
    AConfiguracion.Vista,
    SCaptionColumnaFacturaDescripcion,
    'DESCRIPCION_ARTICULO_FACLIN',
    300,
    True);
  NuevaColumna(AConfiguracion.Vista,
    SCaptionPropiedadesArticuloDocumento, 'PROPIEDADES_ARTICULO',
    300, False);
  if AConfiguracion.DescripcionAmpliada then
  begin
    AColumnas.DescripcionArticulo.PropertiesClass := TcxMemoProperties;
    PropiedadesDescripcion := TcxMemoProperties(
      AColumnas.DescripcionArticulo.Properties);
    PropiedadesDescripcion.VisibleLineCount := 3;
    PropiedadesDescripcion.MaxLength := 1000;
    PropiedadesDescripcion.ScrollBars := ssBoth;
  end;
  if not AConfiguracion.Tallas then
  begin
    AColumnas.TipoCantidad := NuevaColumna(
      AConfiguracion.Vista,
      SCaptionColTipoCantidad,
      'TIPO_CANTIDAD_ARTICULO_FACLIN',
      20,
      False);
    AColumnas.TipoCantidad.Visible := False;
    AColumnas.TipoCantidad.VisibleForCustomization := False;
    AColumnas.Cantidad := NuevaColumna(
      AConfiguracion.Vista,
      SCaptionColumnaFacturaCantidad,
      'CANTIDAD_FACLIN',
      90,
      True);
    AColumnas.Cantidad.PropertiesClass := TcxSpinEditProperties;
    VincularCantidadGrid(
      AColumnas.Cantidad,
      AColumnas.TipoCantidad,
      AConfiguracion.UnidadesMedida);
  end;
end;

procedure CrearColumnasPrecios(
  const AConfiguracion: TConfiguracionColumnasFactura;
  var AColumnas: TColumnasFactura);
var
  PropiedadesDescuento: TcxSpinEditProperties;
  PropiedadesImpuestos: TcxCheckBoxProperties;
begin
  AColumnas.PrecioSalida := NuevaColumna(
    AConfiguracion.Vista,
    SCaptionColumnaFacturaPrecioSalida,
    'PRECIO_SALIDA_FACLIN',
    100,
    True);
  AColumnas.PrecioSalida.PropertiesClass := TcxCurrencyEditProperties;
  AColumnas.PorcentajeDescuento := NuevaColumna(
    AConfiguracion.Vista,
    SCaptionColumnaFacturaPorcentajeDto,
    'PORCENTAJE_DTO_FACLIN',
    80,
    True);
  AColumnas.PorcentajeDescuento.PropertiesClass :=
    TcxSpinEditProperties;
  PropiedadesDescuento := TcxSpinEditProperties(
    AColumnas.PorcentajeDescuento.Properties);
  PropiedadesDescuento.DisplayFormat := '0.00 %';
  PropiedadesDescuento.EditFormat := '0.00 %';
  PropiedadesDescuento.MaxValue := 100;
  AColumnas.PrecioDescuento := NuevaColumna(
    AConfiguracion.Vista,
    SCaptionColumnaFacturaImporteDto,
    'PRECIO_DTO_FACLIN',
    90,
    True);
  AColumnas.PrecioDescuento.PropertiesClass :=
    TcxCurrencyEditProperties;
  AColumnas.PrecioVentaSinIva := NuevaColumna(
    AConfiguracion.Vista,
    SCaptionColumnaFacturaPrecioSinIva,
    'PRECIO_VENTA_SIVA_ARTICULO_FACLIN',
    120,
    True);
  AColumnas.PrecioVentaSinIva.PropertiesClass :=
    TcxCurrencyEditProperties;
  AColumnas.ImpuestosIncluidos := NuevaColumna(
    AConfiguracion.Vista,
    SCaptionColumnaFacturaImpuestosIncluidos,
    'ESIMP_INCL_TARIFA_FACLIN',
    79,
    True);
  AColumnas.ImpuestosIncluidos.Visible := False;
  AColumnas.ImpuestosIncluidos.PropertiesClass :=
    TcxCheckBoxProperties;
  PropiedadesImpuestos := TcxCheckBoxProperties(
    AColumnas.ImpuestosIncluidos.Properties);
  PropiedadesImpuestos.ReadOnly := True;
  PropiedadesImpuestos.ValueChecked := 'S';
  PropiedadesImpuestos.ValueUnchecked := 'N';
end;

procedure CrearColumnasImpuestos(
  const AConfiguracion: TConfiguracionColumnasFactura;
  var AColumnas: TColumnasFactura);
var
  PropiedadesTipoIva: TcxLookupComboBoxProperties;
  ColumnaTipoIva: TcxLookupDBGridColumn;
  PropiedadesPorcentaje: TcxSpinEditProperties;
begin
  AColumnas.TipoIva := NuevaColumna(
    AConfiguracion.Vista,
    SCaptionColumnaFacturaTipoIva,
    'TIPO_IVA_ARTICULO_FACLIN',
    109,
    True);
  AColumnas.TipoIva.PropertiesClass := TcxLookupComboBoxProperties;
  PropiedadesTipoIva :=
    TcxLookupComboBoxProperties(AColumnas.TipoIva.Properties);
  PropiedadesTipoIva.DropDownListStyle := lsFixedList;
  PropiedadesTipoIva.KeyFieldNames := 'CODIGO_ABREVIATURA_IVA_IVATIP';
  ColumnaTipoIva := PropiedadesTipoIva.ListColumns.Add;
  ColumnaTipoIva.Caption := SCaptionColumnaFacturaTipoIva;
  ColumnaTipoIva.FieldName := 'NOMBRE_TIPO_IVA_IVATIP';
  PropiedadesTipoIva.ListOptions.ShowHeader := False;
  PropiedadesTipoIva.ListSource := AConfiguracion.DataSourceIvas;
  AColumnas.PorcentajeIva := NuevaColumna(
    AConfiguracion.Vista,
    SCaptionColumnaFacturaPorcentajeIva,
    'PORCENTAJE_IVA_FACLIN',
    79,
    True);
  AColumnas.PorcentajeIva.PropertiesClass := TcxSpinEditProperties;
  PropiedadesPorcentaje :=
    TcxSpinEditProperties(AColumnas.PorcentajeIva.Properties);
  PropiedadesPorcentaje.DisplayFormat := '0.00 %';
  PropiedadesPorcentaje.EditFormat := '0.00 %';
  AColumnas.PrecioVentaConIva := NuevaColumna(
    AConfiguracion.Vista,
    SCaptionColumnaFacturaPrecioConIva,
    'PRECIO_VENTA_CIVA_ARTICULO_FACLIN',
    120,
    True);
  AColumnas.PrecioVentaConIva.PropertiesClass :=
    TcxCurrencyEditProperties;
  AColumnas.TotalConIva := NuevaColumna(
    AConfiguracion.Vista,
    SCaptionColumnaFacturaTotalConIva,
    'TOTAL_FACLIN',
    120,
    False);
  AColumnas.TotalConIva.PropertiesClass := TcxCurrencyEditProperties;
  AColumnas.TotalSinIva := NuevaColumna(
    AConfiguracion.Vista,
    SCaptionColumnaFacturaTotalSinIva,
    'TOTAL_FAC_SIVA_FACLIN',
    125,
    True);
  AColumnas.TotalSinIva.PropertiesClass := TcxCurrencyEditProperties;
end;

procedure CrearColumnaFecha(
  const AConfiguracion: TConfiguracionColumnasFactura;
  var AColumnas: TColumnasFactura);
var
  PropiedadesFecha: TcxDateEditProperties;
begin
  AColumnas.FechaEntrega := NuevaColumna(
    AConfiguracion.Vista,
    SCaptionColumnaFacturaFechaEntrega,
    'FECHA_ENTREGA_FACLIN',
    100,
    True);
  AColumnas.FechaEntrega.PropertiesClass := TcxDateEditProperties;
  PropiedadesFecha :=
    TcxDateEditProperties(AColumnas.FechaEntrega.Properties);
  PropiedadesFecha.DateButtons := [btnClear, btnToday];
  PropiedadesFecha.DisplayFormat := 'dd/mm/yyyy';
  PropiedadesFecha.EditFormat := 'dd/mm/yyyy';
  AColumnas.FechaEntrega.Visible :=
    AConfiguracion.MostrarFechaEntrega;
end;

procedure CrearSumarios(
  const AConfiguracion: TConfiguracionColumnasFactura;
  const AColumnas: TColumnasFactura);
var
  Resumen: TcxDataSummary;
  Sumario: TcxGridDBTableSummaryItem;
begin
  Resumen := AConfiguracion.Vista.DataController.Summary;
  Resumen.BeginUpdate;
  try
    Resumen.FooterSummaryItems.Clear;
    Sumario := TcxGridDBTableSummaryItem(
      Resumen.FooterSummaryItems.Add);
    Sumario.Kind := skSum;
    Sumario.Format := '##,##.00 ' + #8364;
    Sumario.Column := AColumnas.TotalConIva;
    if AColumnas.Cantidad <> nil then
    begin
      Sumario := TcxGridDBTableSummaryItem(
        Resumen.FooterSummaryItems.Add);
      Sumario.Kind := skSum;
      Sumario.Format := '#,##.00';
      Sumario.Column := AColumnas.Cantidad;
    end;
    Sumario := TcxGridDBTableSummaryItem(
      Resumen.FooterSummaryItems.Add);
    Sumario.Kind := skSum;
    Sumario.Format := '##,##.00 ' + #8364;
    Sumario.Column := AColumnas.TotalSinIva;
  finally
    Resumen.EndUpdate;
  end;
end;

function CrearColumnasFactura(
  const AConfiguracion: TConfiguracionColumnasFactura
): TColumnasFactura;
var
  Vendedor: TcxGridDBColumn;
begin
  Result := Default(TColumnasFactura);
  CrearColumnasIdentidad(AConfiguracion, Result, Vendedor);
  CrearColumnasCatalogo(AConfiguracion, Result);
  CrearColumnasDescripcionCantidad(AConfiguracion, Result);
  CrearColumnasPrecios(AConfiguracion, Result);
  CrearColumnasImpuestos(AConfiguracion, Result);
  CrearColumnaFecha(AConfiguracion, Result);
  CrearSumarios(AConfiguracion, Result);
  Result.Linea.Index := 0;
  // En simplificadas va junto al número de línea; en normales es un dato
  // opcional y queda al final.
  if Assigned(Vendedor) then
  begin
    if AConfiguracion.Simplificada then
      Vendedor.Index := 1
    else
      Vendedor.Index := AConfiguracion.Vista.ColumnCount - 1;
  end;
  FormatearColumnaMonetaria(Result.PrecioUltimaCompra);
  FormatearColumnaMonetaria(Result.PrecioSalida);
  FormatearColumnaMonetaria(Result.PrecioDescuento);
  FormatearColumnaMonetaria(Result.PrecioVentaSinIva);
  FormatearColumnaMonetaria(Result.PrecioVentaConIva);
  FormatearColumnaMonetaria(Result.TotalConIva);
  FormatearColumnaMonetaria(Result.TotalSinIva);
end;

end.
