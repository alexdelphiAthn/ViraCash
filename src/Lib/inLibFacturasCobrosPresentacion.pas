{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasCobrosPresentacion                               }
{    Tipo:       Colaborador de presentación                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Configura la vista compartida de efectos y recibos de facturas.           }
{******************************************************************************}
unit inLibFacturasCobrosPresentacion;

interface

uses
  Data.DB, cxButtons, cxGridDBTableView, cxPC;

type
  TCampoCobroFactura = (
    ccfNumeroFactura,
    ccfSerieFactura,
    ccfNumeroPlazo,
    ccfFormaPago,
    ccfDescripcionFormaPago,
    ccfImporte,
    ccfEstado,
    ccfFechaExpedicion,
    ccfFechaVencimiento,
    ccfIban,
    ccfFechaPago,
    ccfLocalidad,
    ccfCodigoCliente,
    ccfRazonSocialCliente,
    ccfDireccionCliente,
    ccfPoblacionCliente,
    ccfProvinciaCliente,
    ccfCodigoPostalCliente,
    ccfImporteLetra);
  TCamposCobroFactura = set of TCampoCobroFactura;
  TConfiguracionCobrosFactura = record
    EsEfectosVenta: Boolean;
    PermiteEdicion: Boolean;
    MostrarImprimir: Boolean;
    // Varios efectos a la vez en la rejilla (un recibo por efecto).
    PermiteSeleccionMultiple: Boolean;
    TextoPlural: string;
    PrefijoExportacion: string;
    CaptionPestana: string;
    CaptionGenerar: string;
    CaptionImprimir: string;
    CaptionPendiente: string;
    CaptionCobrado: string;
    CaptionDevuelto: string;
    Campos: array[TCampoCobroFactura] of string;
    Captions: array[TCampoCobroFactura] of string;
    ColumnasDetalleVisibles: TCamposCobroFactura;
  end;
  TControlesCobrosFactura = record
    AplicarOrigenDatos: Boolean;
    Vista: TcxGridDBTableView;
    DataSourceRecibos: TDataSource;
    DataSourceEfectos: TDataSource;
    Pestana: TcxTabSheet;
    BotonGenerar: TcxButton;
    BotonGenerarSecundario: TcxButton;
    BotonImprimir: TcxButton;
    BotonPendiente: TcxButton;
    BotonCobrado: TcxButton;
    BotonDevuelto: TcxButton;
    Columnas: array[TCampoCobroFactura] of TcxGridDBColumn;
  end;
  TPresentacionCobrosFactura = class
  public
    class procedure Aplicar(
      const AConfiguracion: TConfiguracionCobrosFactura;
      const AControles: TControlesCobrosFactura); static;
  end;

function CrearConfiguracionCobrosFactura(
  const ATipoFactura: string): TConfiguracionCobrosFactura;

implementation

uses
  System.SysUtils, inLibMsgFacturas;

const
  CAMPOS_VISIBILIDAD_DETALLE: TCamposCobroFactura = [
    ccfLocalidad,
    ccfDireccionCliente,
    ccfPoblacionCliente,
    ccfProvinciaCliente,
    ccfCodigoPostalCliente,
    ccfImporteLetra];

procedure ConfigurarCamposRecibos(
  var AConfiguracion: TConfiguracionCobrosFactura);
begin
  AConfiguracion.Campos[ccfNumeroFactura] := 'NUMERO_FAC_REC';
  AConfiguracion.Campos[ccfSerieFactura] := 'SERIE_FAC_REC';
  AConfiguracion.Campos[ccfNumeroPlazo] := 'NUMERO_PLAZO_REC';
  AConfiguracion.Campos[ccfFormaPago] :=
    'FORMA_PAGO_ORIGEN_RECIBO_REC';
  AConfiguracion.Campos[ccfDescripcionFormaPago] :=
    'FORMA_PAGO_DESCRIPCION_ORIGEN_RECIBO_REC';
  AConfiguracion.Campos[ccfImporte] := 'EUROS_RECIBO_REC';
  AConfiguracion.Campos[ccfEstado] := 'ESTADO_RECIBO_REC';
  AConfiguracion.Campos[ccfFechaExpedicion] :=
    'FECHA_EXPEDICION_RECIBO_REC';
  AConfiguracion.Campos[ccfFechaVencimiento] :=
    'FECHA_VENCIMIENTO_RECIBO_REC';
  AConfiguracion.Campos[ccfIban] := 'IBAN_CLI_REC';
  AConfiguracion.Campos[ccfFechaPago] := 'FECHA_PAGO_RECIBO_REC';
  AConfiguracion.Campos[ccfLocalidad] :=
    'LOCALIDAD_EXPEDICION_RECIBO_REC';
  AConfiguracion.Campos[ccfCodigoCliente] := 'CODIGO_CLI_REC';
  AConfiguracion.Campos[ccfRazonSocialCliente] := 'RAZON_SOCIAL_CLI_REC';
  AConfiguracion.Campos[ccfDireccionCliente] :=
    'DIRECCION1_CLIENTE_RECIBO_REC';
  AConfiguracion.Campos[ccfPoblacionCliente] := 'POBLACION_CLI_REC';
  AConfiguracion.Campos[ccfProvinciaCliente] := 'PROVINCIA_CLI_REC';
  AConfiguracion.Campos[ccfCodigoPostalCliente] :=
    'CODIGO_POSTAL_CLI_REC';
  AConfiguracion.Campos[ccfImporteLetra] := 'IMPORTE_LETRA_RECIBO_REC';
end;

procedure ConfigurarCamposEfectos(
  var AConfiguracion: TConfiguracionCobrosFactura);
begin
  AConfiguracion.Campos[ccfNumeroFactura] := 'NUMERO_FAC_EFV';
  AConfiguracion.Campos[ccfSerieFactura] := 'SERIE_FAC_EFV';
  AConfiguracion.Campos[ccfNumeroPlazo] := 'NUMERO_EFV';
  AConfiguracion.Campos[ccfFormaPago] := 'CODIGO_TEFE_EFV';
  AConfiguracion.Campos[ccfDescripcionFormaPago] :=
    'DESCRIPCION_TEFE_VIEW_EFV';
  AConfiguracion.Campos[ccfImporte] := 'IMPORTE_EFV';
  AConfiguracion.Campos[ccfEstado] := 'ESTADO_EFV';
  AConfiguracion.Campos[ccfFechaExpedicion] := 'FECHA_EMISION_EFV';
  AConfiguracion.Campos[ccfFechaVencimiento] :=
    'FECHA_VENCIMIENTO_EFV';
  AConfiguracion.Campos[ccfIban] := 'IBAN_EFV';
  AConfiguracion.Campos[ccfFechaPago] := 'FECHA_COBRO_EFV';
  AConfiguracion.Campos[ccfLocalidad] := 'REFERENCIA_DOCUMENTO_EFV';
  AConfiguracion.Campos[ccfCodigoCliente] := 'CODIGO_CLI_EFV';
  AConfiguracion.Campos[ccfRazonSocialCliente] :=
    'RAZON_SOCIAL_CLI_EFV';
  AConfiguracion.Campos[ccfDireccionCliente] := 'OBSERVACIONES_EFV';
  AConfiguracion.Campos[ccfPoblacionCliente] := 'OBSERVACIONES_EFV';
  AConfiguracion.Campos[ccfProvinciaCliente] := 'OBSERVACIONES_EFV';
  AConfiguracion.Campos[ccfCodigoPostalCliente] := 'OBSERVACIONES_EFV';
  AConfiguracion.Campos[ccfImporteLetra] := 'OBSERVACIONES_EFV';
end;

procedure ConfigurarTextosRecibos(
  var AConfiguracion: TConfiguracionCobrosFactura);
begin
  AConfiguracion.TextoPlural := SCaptionRecibosPlural;
  AConfiguracion.PrefijoExportacion := 'Recibos_Borrador_';
  AConfiguracion.CaptionPestana := SCaptionTabRecibos;
  AConfiguracion.CaptionGenerar := SCaptionGenerarRecibos;
  AConfiguracion.CaptionImprimir := SCaptionImprimirRecibo;
  AConfiguracion.CaptionPendiente := SCaptionReciboEmitido;
  AConfiguracion.CaptionCobrado := SCaptionReciboPagado;
  AConfiguracion.CaptionDevuelto := SCaptionReciboDevuelto;
  AConfiguracion.Captions[ccfNumeroFactura] :=
    SCaptionColNroBorradorRecibo;
  AConfiguracion.Captions[ccfSerieFactura] :=
    SCaptionColSerieBorradorRecibo;
  AConfiguracion.Captions[ccfNumeroPlazo] := SCaptionColNroPlazo;
  AConfiguracion.Captions[ccfImporte] := SCaptionColTotalRecibo;
  AConfiguracion.Captions[ccfEstado] := SCaptionColEstadoRecibo;
  AConfiguracion.Captions[ccfFechaExpedicion] :=
    SCaptionColFechaExpedicionRecibo;
  AConfiguracion.Captions[ccfFechaPago] := SCaptionColFechaPagoRecibo;
  AConfiguracion.Captions[ccfLocalidad] :=
    SCaptionColLocalidadExpedicionRecibo;
end;

procedure ConfigurarTextosEfectos(
  var AConfiguracion: TConfiguracionCobrosFactura);
begin
  AConfiguracion.TextoPlural := SCaptionEfectosCobroPlural;
  AConfiguracion.PrefijoExportacion := 'EfectosCobro_Borrador_';
  AConfiguracion.CaptionPestana := SCaptionTabEfectos;
  AConfiguracion.CaptionGenerar := SCaptionGenerarEfectos;
  AConfiguracion.CaptionImprimir := SCaptionImprimirEfecto;
  AConfiguracion.CaptionPendiente := SCaptionEfectoPendiente;
  AConfiguracion.CaptionCobrado := SCaptionEfectoCobrado;
  AConfiguracion.CaptionDevuelto := SCaptionEfectoDevuelto;
  AConfiguracion.Captions[ccfNumeroFactura] :=
    SCaptionColNroBorradorEfecto;
  AConfiguracion.Captions[ccfSerieFactura] :=
    SCaptionColSerieBorradorEfecto;
  AConfiguracion.Captions[ccfNumeroPlazo] := SCaptionColEfecto;
  AConfiguracion.Captions[ccfImporte] := SCaptionColTotalEfecto;
  AConfiguracion.Captions[ccfEstado] := SCaptionColEstadoEfecto;
  AConfiguracion.Captions[ccfFechaExpedicion] :=
    SCaptionColFechaEmisionEfecto;
  AConfiguracion.Captions[ccfFechaPago] := SCaptionColFechaCobroEfecto;
  AConfiguracion.Captions[ccfLocalidad] :=
    SCaptionColReferenciaEfecto;
end;

function CrearConfiguracionCobrosFactura(
  const ATipoFactura: string): TConfiguracionCobrosFactura;
begin
  Result := Default(TConfiguracionCobrosFactura);
  Result.EsEfectosVenta := SameText(ATipoFactura, 'NORMAL');
  Result.PermiteEdicion := not Result.EsEfectosVenta;
  // FZ-ISSUE-102.14: los efectos de venta mayor también imprimen recibo.
  Result.MostrarImprimir := True;
  Result.PermiteSeleccionMultiple := Result.EsEfectosVenta;
  Result.ColumnasDetalleVisibles := CAMPOS_VISIBILIDAD_DETALLE;
  if Result.EsEfectosVenta then
  begin
    ConfigurarCamposEfectos(Result);
    ConfigurarTextosEfectos(Result);
    Result.ColumnasDetalleVisibles := [ccfLocalidad];
  end
  else
  begin
    ConfigurarCamposRecibos(Result);
    ConfigurarTextosRecibos(Result);
  end;
end;

class procedure TPresentacionCobrosFactura.Aplicar(
  const AConfiguracion: TConfiguracionCobrosFactura;
  const AControles: TControlesCobrosFactura);
var
  Campo: TCampoCobroFactura;
begin
  if AControles.AplicarOrigenDatos and Assigned(AControles.Vista) then
  begin
    if AConfiguracion.EsEfectosVenta then
      AControles.Vista.DataController.DataSource :=
        AControles.DataSourceEfectos
    else
      AControles.Vista.DataController.DataSource :=
        AControles.DataSourceRecibos;
    AControles.Vista.OptionsData.Appending :=
      AConfiguracion.PermiteEdicion;
    AControles.Vista.OptionsData.Deleting :=
      AConfiguracion.PermiteEdicion;
    AControles.Vista.OptionsData.Editing :=
      AConfiguracion.PermiteEdicion;
    AControles.Vista.OptionsData.Inserting :=
      AConfiguracion.PermiteEdicion;
    AControles.Vista.Navigator.Buttons.Insert.Visible :=
      AConfiguracion.PermiteEdicion;
    AControles.Vista.Navigator.Buttons.Delete.Visible :=
      AConfiguracion.PermiteEdicion;
    AControles.Vista.Navigator.Buttons.Post.Visible :=
      AConfiguracion.PermiteEdicion;
    AControles.Vista.Navigator.Buttons.Cancel.Visible :=
      AConfiguracion.PermiteEdicion;
    AControles.Vista.OptionsSelection.MultiSelect :=
      AConfiguracion.PermiteSeleccionMultiple;
    for Campo := Low(TCampoCobroFactura) to
      High(TCampoCobroFactura) do
    begin
      if Assigned(AControles.Columnas[Campo]) then
        AControles.Columnas[Campo].DataBinding.FieldName :=
          AConfiguracion.Campos[Campo];
    end;
    for Campo := Low(TCampoCobroFactura) to
      High(TCampoCobroFactura) do
    begin
      if (Campo in CAMPOS_VISIBILIDAD_DETALLE) and
         Assigned(AControles.Columnas[Campo]) then
        AControles.Columnas[Campo].Visible :=
          Campo in AConfiguracion.ColumnasDetalleVisibles;
    end;
  end;
  if Assigned(AControles.Pestana) then
    AControles.Pestana.Caption := AConfiguracion.CaptionPestana;
  if Assigned(AControles.BotonGenerar) then
    AControles.BotonGenerar.Caption := AConfiguracion.CaptionGenerar;
  if Assigned(AControles.BotonGenerarSecundario) then
    AControles.BotonGenerarSecundario.Caption :=
      AConfiguracion.CaptionGenerar;
  if Assigned(AControles.BotonImprimir) then
  begin
    AControles.BotonImprimir.Caption := AConfiguracion.CaptionImprimir;
    AControles.BotonImprimir.Visible := AConfiguracion.MostrarImprimir;
  end;
  if Assigned(AControles.BotonPendiente) then
    AControles.BotonPendiente.Caption := AConfiguracion.CaptionPendiente;
  if Assigned(AControles.BotonCobrado) then
    AControles.BotonCobrado.Caption := AConfiguracion.CaptionCobrado;
  if Assigned(AControles.BotonDevuelto) then
    AControles.BotonDevuelto.Caption := AConfiguracion.CaptionDevuelto;
  for Campo := Low(TCampoCobroFactura) to
    High(TCampoCobroFactura) do
  begin
    if Assigned(AControles.Columnas[Campo]) and
       (AConfiguracion.Captions[Campo] <> '') then
      AControles.Columnas[Campo].Caption :=
        AConfiguracion.Captions[Campo];
  end;
end;

end.
