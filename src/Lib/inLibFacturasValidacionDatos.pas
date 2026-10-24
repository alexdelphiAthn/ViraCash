{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasValidacionDatos                                 }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Adapta datasets a valores de edición y validación de facturas.            }
{******************************************************************************}
unit inLibFacturasValidacionDatos;

interface

uses
  Data.DB,
  inLibFacturasValidacionCabecera,
  inLibFacturasServiciosIntf;

type
  TResultadoCopiaClienteFactura = record
    RequiereFormaPagoDefecto: Boolean;
    RequiereTarifaDefecto: Boolean;
    NotificarSeries: Boolean;
  end;
  TResultadoCopiaEmpresaFactura = record
    CalcularRetenciones: Boolean;
    NotificarSeries: Boolean;
  end;

procedure CopiarArticuloSeleccionadoFactura(
  AOrigen, ALineas, ACabecera: TDataSet;
  ADescuentoVigente: Boolean);
function CopiarClienteSeleccionadoFactura(
  AOrigen, AFactura: TDataSet): TResultadoCopiaClienteFactura;
procedure CompletarIdentidadClienteBorrador(AOrigen, AFactura: TDataSet);
function CopiarEmpresaSeleccionadaFactura(
  AOrigen, AFactura: TDataSet): TResultadoCopiaEmpresaFactura;
function CrearSolicitudClienteDesdeFactura(
  AFactura: TDataSet;
  const AUsuario: string): TSolicitudClienteFactura;
function CrearSolicitudEmpresaDesdeFactura(
  AFactura: TDataSet;
  const AUsuario: string): TSolicitudEmpresaFactura;
procedure CopiarConfiguracionIvaFactura(
  AOrigen, ADestino: TDataSet);
function CrearDatosValidacionCabeceraFactura(
  AFactura: TDataSet): TDatosValidacionCabeceraFactura;

implementation

uses
  System.SysUtils,
  System.StrUtils;

procedure AsegurarEdicion(ADataSet: TDataSet);
begin
  if not (ADataSet.State in dsEditModes) then
    ADataSet.Edit;
end;

procedure CopiarCadena(
  AOrigen, ADestino: TDataSet;
  const ACampoOrigen, ACampoDestino: string);
begin
  ADestino.FieldByName(ACampoDestino).AsString :=
    AOrigen.FieldByName(ACampoOrigen).AsString;
end;

procedure CopiarCadenaOpcional(
  AOrigen, ADestino: TDataSet;
  const ACampoOrigen, ACampoDestino: string);
begin
  if (AOrigen.FindField(ACampoOrigen) <> nil) and
     (ADestino.FindField(ACampoDestino) <> nil) then
  begin
    CopiarCadena(
      AOrigen, ADestino, ACampoOrigen, ACampoDestino);
  end;
end;

function PorcentajeIvaArticulo(
  ACabecera: TDataSet;
  const ATipoIva: string): Currency;
var
  iPorcentaje: Integer;
begin
  iPorcentaje := 0;
  case IndexStr(ATipoIva, ['N', 'R', 'S', 'E']) of
    0: iPorcentaje := ACabecera.FieldByName(
      'PORCENTAJE_IVAN_FAC').AsInteger;
    1: iPorcentaje := ACabecera.FieldByName(
      'PORCENTAJE_IVAR_FAC').AsInteger;
    2: iPorcentaje := ACabecera.FieldByName(
      'PORCENTAJE_IVAS_FAC').AsInteger;
    3: iPorcentaje := ACabecera.FieldByName(
      'PORCENTAJE_IVAE_FAC').AsInteger;
  end;
  Result := iPorcentaje / 100;
end;

function PrecioFinalArticulo(
  AOrigen, ALineas: TDataSet;
  ADescuentoVigente: Boolean): Double;
begin
  if ADescuentoVigente then
  begin
    CopiarCadena(AOrigen, ALineas,
      'PORCENTAJE_DTO_ARTTAR', 'PORCENTAJE_DTO_FACLIN');
    CopiarCadena(AOrigen, ALineas,
      'PRECIO_DTO_ARTTAR', 'PRECIO_DTO_FACLIN');
    Result := AOrigen.FieldByName('PRECIO_FINAL_ARTTAR').AsFloat;
  end
  else
  begin
    ALineas.FieldByName('PORCENTAJE_DTO_FACLIN').AsFloat := 0;
    ALineas.FieldByName('PRECIO_DTO_FACLIN').AsCurrency := 0;
    Result := AOrigen.FieldByName('PRECIO_SALIDA_ARTTAR').AsFloat;
  end;
end;

procedure AplicarPrecioArticulo(
  AOrigen, ALineas, ACabecera: TDataSet;
  ADescuentoVigente: Boolean);
var
  dPrecioFinal: Double;
  rPorcentaje: Currency;
begin
  rPorcentaje := PorcentajeIvaArticulo(
    ACabecera,
    AOrigen.FieldByName('TIPO_IVA_ART').AsString);
  dPrecioFinal := PrecioFinalArticulo(
    AOrigen, ALineas, ADescuentoVigente);
  if AOrigen.FieldByName('ESIMP_INCL_TAR').AsString = 'S' then
  begin
    ALineas.FieldByName(
      'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsCurrency := dPrecioFinal;
    ALineas.FieldByName(
      'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsFloat :=
      dPrecioFinal / (1 + rPorcentaje);
  end
  else
  begin
    ALineas.FieldByName(
      'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency := dPrecioFinal;
    ALineas.FieldByName(
      'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsFloat :=
      dPrecioFinal * (1 + rPorcentaje);
  end;
end;

procedure CopiarArticuloSeleccionadoFactura(
  AOrigen, ALineas, ACabecera: TDataSet;
  ADescuentoVigente: Boolean);
begin
  AsegurarEdicion(ALineas);
  CopiarCadena(AOrigen, ALineas,
    'CODIGO_ART_ART', 'CODIGO_ART_FACLIN');
  CopiarCadena(AOrigen, ALineas,
    'TIPO_CANTIDAD_ART', 'TIPO_CANTIDAD_ARTICULO_FACLIN');
  CopiarCadena(AOrigen, ALineas,
    'DESCRIPCION_ART', 'DESCRIPCION_ARTICULO_FACLIN');
  CopiarCadena(AOrigen, ALineas,
    'TIPO_IVA_ART', 'TIPO_IVA_ARTICULO_FACLIN');
  CopiarCadena(ACabecera, ALineas,
    'TARIFA_ARTICULO_CLIENTE_FAC', 'CODIGO_TAR_FACLIN');
  CopiarCadena(ACabecera, ALineas,
    'ESIMP_INCL_TARIFA_CLIENTE_FAC', 'ESIMP_INCL_TARIFA_FACLIN');
  CopiarCadena(AOrigen, ALineas,
    'CODIGO_FAM_ART', 'CODIGO_FAM_FACLIN');
  CopiarCadena(AOrigen, ALineas,
    'DESCRIPCION_FAM', 'NOMBRE_FAM_FACLIN');
  CopiarCadena(AOrigen, ALineas,
    'ESPROVEEDORPRINCIPAL', 'ESPROVEEDORPRINCIPAL_FACLIN');
  CopiarCadena(AOrigen, ALineas,
    'CODIGO_PRV_PRV', 'CODIGO_PRV_FACLIN');
  CopiarCadena(AOrigen, ALineas,
    'RAZON_SOCIAL_PROVEEDOR', 'RAZON_SOCIAL_PROVEEDOR_FACLIN');
  CopiarCadena(AOrigen, ALineas,
    'PRECIO_ULT_COMPRA', 'PRECIO_ULT_COMPRA_FACLIN');
  CopiarCadena(AOrigen, ALineas,
    'PRECIO_SALIDA_ARTTAR', 'PRECIO_SALIDA_FACLIN');
  AplicarPrecioArticulo(
    AOrigen, ALineas, ACabecera, ADescuentoVigente);
  if ALineas.FindField('CANTIDAD_FACLIN') <> nil then
    ALineas.FieldByName('CANTIDAD_FACLIN').AsCurrency := 1;
end;

procedure CopiarIdentidadCliente(
  AOrigen, AFactura: TDataSet);
begin
  CopiarCadena(AOrigen, AFactura, 'CODIGO_CLI_CLI', 'CODIGO_CLI_FAC');
  CopiarCadena(AOrigen, AFactura,
    'RAZON_SOCIAL_CLI', 'RAZON_SOCIAL_CLIENTE_FAC');
  CopiarCadena(AOrigen, AFactura, 'NIF_CLI', 'NIF_CLIENTE_FAC');
  CopiarCadena(AOrigen, AFactura, 'MOVIL_CLI', 'MOVIL_CLIENTE_FAC');
  CopiarCadena(AOrigen, AFactura, 'EMAIL_CLI', 'EMAIL_CLIENTE_FAC');
  CopiarCadena(AOrigen, AFactura,
    'DIRECCION1_CLI', 'DIRECCION1_CLIENTE_FAC');
  CopiarCadena(AOrigen, AFactura,
    'DIRECCION2_CLI', 'DIRECCION2_CLIENTE_FAC');
  CopiarCadena(AOrigen, AFactura,
    'POBLACION_CLI', 'POBLACION_CLIENTE_FAC');
  CopiarCadena(AOrigen, AFactura,
    'PROVINCIA_CLI', 'PROVINCIA_CLIENTE_FAC');
  CopiarCadena(AOrigen, AFactura,
    'CODIGO_POSTAL_CLI', 'CODIGO_POSTAL_CLIENTE_FAC');
  CopiarCadena(AOrigen, AFactura,
    'NOMBRE_PAI_CLI', 'NOMBRE_PAI_CLIENTE_FAC');
  CopiarCadena(AOrigen, AFactura,
    'CODIGO_PAI_CLI', 'CODIGO_PAI_CLIENTE_FAC');
end;

procedure CompletarIdentidadClienteBorrador(AOrigen, AFactura: TDataSet);
const
  Campos: array[0..9] of string = (
    'RAZON_SOCIAL', 'NIF', 'DIRECCION1', 'DIRECCION2', 'POBLACION',
    'PROVINCIA', 'CODIGO_POSTAL', 'NOMBRE_PAI', 'CODIGO_PAI', 'EMAIL');
var
  Nombre: string;
  Origen, Destino: TField;
begin
  if SameText(AFactura.FieldByName('FASE_FAC').AsString, 'BORRADOR') and
     SameText(AFactura.FieldByName('CODIGO_CLI_FAC').AsString,
       AOrigen.FieldByName('CODIGO_CLI_CLI').AsString) then
    for Nombre in Campos do
    begin
      Origen := AOrigen.FindField(Nombre + '_CLI');
      Destino := AFactura.FindField(Nombre + '_CLIENTE_FAC');
      if Assigned(Origen) and Assigned(Destino) and
         (Trim(Destino.AsString) = '') and (Trim(Origen.AsString) <> '')
      then
      begin
        AsegurarEdicion(AFactura);
        Destino.Value := Origen.Value;
      end;
    end;
end;

procedure CopiarFiscalidadCliente(
  AOrigen, AFactura: TDataSet);
begin
  CopiarCadena(AOrigen, AFactura,
    'ESIVA_RECARGO_CLI', 'ESIVA_RECARGO_CLIENTE_FAC');
  CopiarCadena(AOrigen, AFactura,
    'ESIVA_EXENTO_CLI', 'ESIVA_EXENTO_CLIENTE_FAC');
  CopiarCadena(AOrigen, AFactura,
    'ESREGIMENESPECIALAGRICOLA_CLI',
    'ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC');
  CopiarCadena(AOrigen, AFactura,
    'ESRETENCIONES_CLI', 'ESRETENCIONES_CLIENTE_FAC');
  CopiarCadena(AOrigen, AFactura,
    'ESINTRACOMUNITARIO_CLI', 'ESINTRACOMUNITARIO_CLIENTE_FAC');
  CopiarCadenaOpcional(AOrigen, AFactura,
    'CODIGO_OFICINA_CONTABLE_CLI', 'CODIGO_OFICINA_CONTABLE_FAC');
  CopiarCadenaOpcional(AOrigen, AFactura,
    'CODIGO_ORGANO_GESTOR_CLI', 'CODIGO_ORGANO_GESTOR_FAC');
  CopiarCadenaOpcional(AOrigen, AFactura,
    'CODIGO_UNIDAD_TRAMITADORA_CLI',
    'CODIGO_UNIDAD_TRAMITADORA_FAC');
  CopiarCadenaOpcional(AOrigen, AFactura,
    'NOMBRE_PERSONA_CLIENTE_CLI', 'NOMBRE_PERSONA_CLIENTE_FAC');
  CopiarCadenaOpcional(AOrigen, AFactura,
    'APELLIDOS_PERSONA_CLIENTE_CLI',
    'APELLIDOS_PERSONA_CLIENTE_FAC');
end;

function CopiarClienteSeleccionadoFactura(
  AOrigen, AFactura: TDataSet): TResultadoCopiaClienteFactura;
begin
  Result := Default(TResultadoCopiaClienteFactura);
  AsegurarEdicion(AFactura);
  CopiarIdentidadCliente(AOrigen, AFactura);
  CopiarFiscalidadCliente(AOrigen, AFactura);
  Result.RequiereFormaPagoDefecto :=
    AOrigen.FieldByName('CODIGO_FP_CLI').AsString = '';
  if not Result.RequiereFormaPagoDefecto then
  begin
    CopiarCadena(
      AOrigen, AFactura, 'CODIGO_FP_CLI', 'FORMA_PAGO_FAC');
  end;
  if AFactura.State = dsInsert then
  begin
    Result.RequiereTarifaDefecto :=
      AOrigen.FieldByName('TARIFA_ARTICULO_CLI').AsString = '';
    if AOrigen.FieldByName('TARIFA_ARTICULO_CLI').IsNull or
       not Result.RequiereTarifaDefecto then
    begin
      CopiarCadena(AOrigen, AFactura,
        'TARIFA_ARTICULO_CLI', 'TARIFA_ARTICULO_CLIENTE_FAC');
      Result.RequiereTarifaDefecto := False;
    end;
    Result.NotificarSeries := True;
  end;
  if AFactura.FieldByName(
       'ESRETENCIONES_CLIENTE_FAC').AsString <> 'S' then
  begin
    AFactura.FieldByName('PORCENTAJE_RETENCION_FAC').AsFloat := 0;
  end;
end;

procedure CopiarIdentidadEmpresa(
  AOrigen, AFactura: TDataSet);
begin
  CopiarCadena(AOrigen, AFactura, 'CODIGO_EMP_EMP', 'CODIGO_EMP_FAC');
  CopiarCadena(AOrigen, AFactura,
    'RAZON_SOCIAL_EMP', 'RAZON_SOCIAL_EMPRESA_FAC');
  CopiarCadena(AOrigen, AFactura, 'NIF_EMP', 'NIF_EMPRESA_FAC');
  CopiarCadena(AOrigen, AFactura, 'MOVIL_EMP', 'MOVIL_EMPRESA_FAC');
  CopiarCadena(AOrigen, AFactura, 'EMAIL_EMP', 'EMAIL_EMPRESA_FAC');
  CopiarCadena(AOrigen, AFactura,
    'DIRECCION1_EMP', 'DIRECCION1_EMPRESA_FAC');
  CopiarCadena(AOrigen, AFactura,
    'DIRECCION2_EMP', 'DIRECCION2_EMPRESA_FAC');
  CopiarCadena(AOrigen, AFactura,
    'POBLACION_EMP', 'POBLACION_EMPRESA_FAC');
  CopiarCadena(AOrigen, AFactura,
    'PROVINCIA_EMP', 'PROVINCIA_EMPRESA_FAC');
  CopiarCadena(AOrigen, AFactura,
    'CODIGO_POSTAL_EMP', 'CODIGO_POSTAL_EMPRESA_FAC');
  CopiarCadena(AOrigen, AFactura,
    'NOMBRE_PAI_EMP', 'NOMBRE_PAI_EMPRESA_FAC');
  CopiarCadena(AOrigen, AFactura,
    'CODIGO_PAI_EMP', 'CODIGO_PAI_EMPRESA_FAC');
end;

function CopiarEmpresaSeleccionadaFactura(
  AOrigen, AFactura: TDataSet): TResultadoCopiaEmpresaFactura;
begin
  Result := Default(TResultadoCopiaEmpresaFactura);
  AsegurarEdicion(AFactura);
  CopiarIdentidadEmpresa(AOrigen, AFactura);
  CopiarCadena(AOrigen, AFactura,
    'GRUPO_ZONA_IVA_EMP', 'GRUPO_ZONA_IVA_EMPRESA_FAC');
  CopiarCadena(AOrigen, AFactura,
    'ESRETENCIONES_EMP', 'ESRETENCIONES_EMPRESA_FAC');
  CopiarCadena(AOrigen, AFactura,
    'ESREGIMENESPECIALAGRICOLA_EMP',
    'ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC');
  CopiarCadena(AOrigen, AFactura,
    'TEXTO_LEGAL_FACTURA_EMP', 'TEXTO_LEGAL_EMPRESA_FAC');
  Result.CalcularRetenciones :=
    AOrigen.FieldByName('ESRETENCIONES_EMP').AsString = 'S';
  Result.NotificarSeries := AFactura.State = dsInsert;
end;

function CrearSolicitudClienteDesdeFactura(
  AFactura: TDataSet;
  const AUsuario: string): TSolicitudClienteFactura;
begin
  Result := Default(TSolicitudClienteFactura);
  Result.Codigo := AFactura.FieldByName('CODIGO_CLI_FAC').AsString;
  Result.RazonSocial := AFactura.FieldByName(
    'RAZON_SOCIAL_CLIENTE_FAC').AsString;
  Result.Nif := AFactura.FieldByName('NIF_CLIENTE_FAC').AsString;
  Result.Movil := AFactura.FieldByName('MOVIL_CLIENTE_FAC').AsString;
  Result.Email := AFactura.FieldByName('EMAIL_CLIENTE_FAC').AsString;
  Result.Direccion1 := AFactura.FieldByName(
    'DIRECCION1_CLIENTE_FAC').AsString;
  Result.Direccion2 := AFactura.FieldByName(
    'DIRECCION2_CLIENTE_FAC').AsString;
  Result.Poblacion := AFactura.FieldByName(
    'POBLACION_CLIENTE_FAC').AsString;
  Result.Provincia := AFactura.FieldByName(
    'PROVINCIA_CLIENTE_FAC').AsString;
  Result.CodigoPostal := AFactura.FieldByName(
    'CODIGO_POSTAL_CLIENTE_FAC').AsString;
  Result.NombrePais := AFactura.FieldByName(
    'NOMBRE_PAI_CLIENTE_FAC').AsString;
  Result.CodigoPais := AFactura.FieldByName(
    'CODIGO_PAI_CLIENTE_FAC').AsString;
  Result.EsIntracomunitario := AFactura.FieldByName(
    'ESINTRACOMUNITARIO_CLIENTE_FAC').AsString;
  Result.EsIvaExento := AFactura.FieldByName(
    'ESIVA_EXENTO_CLIENTE_FAC').AsString;
  Result.EsRetenciones := AFactura.FieldByName(
    'ESRETENCIONES_CLIENTE_FAC').AsString;
  Result.EsIvaRecargo := AFactura.FieldByName(
    'ESIVA_RECARGO_CLIENTE_FAC').AsString;
  Result.EsRegimenEspecialAgricola := AFactura.FieldByName(
    'ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC').AsString;
  Result.TarifaArticulo := AFactura.FieldByName(
    'TARIFA_ARTICULO_CLIENTE_FAC').AsString;
  Result.Usuario := AUsuario;
end;

function CrearSolicitudEmpresaDesdeFactura(
  AFactura: TDataSet;
  const AUsuario: string): TSolicitudEmpresaFactura;
begin
  Result := Default(TSolicitudEmpresaFactura);
  Result.Codigo := AFactura.FieldByName('CODIGO_EMP_FAC').AsString;
  Result.RazonSocial := AFactura.FieldByName(
    'RAZON_SOCIAL_EMPRESA_FAC').AsString;
  Result.Nif := AFactura.FieldByName('NIF_EMPRESA_FAC').AsString;
  Result.Movil := AFactura.FieldByName('MOVIL_EMPRESA_FAC').AsString;
  Result.Email := AFactura.FieldByName('EMAIL_EMPRESA_FAC').AsString;
  Result.Direccion1 := AFactura.FieldByName(
    'DIRECCION1_EMPRESA_FAC').AsString;
  Result.Direccion2 := AFactura.FieldByName(
    'DIRECCION2_EMPRESA_FAC').AsString;
  Result.Poblacion := AFactura.FieldByName(
    'POBLACION_EMPRESA_FAC').AsString;
  Result.Provincia := AFactura.FieldByName(
    'PROVINCIA_EMPRESA_FAC').AsString;
  Result.CodigoPostal := AFactura.FieldByName(
    'CODIGO_POSTAL_EMPRESA_FAC').AsString;
  Result.NombrePais := AFactura.FieldByName(
    'NOMBRE_PAI_EMPRESA_FAC').AsString;
  Result.CodigoPais := AFactura.FieldByName(
    'CODIGO_PAI_EMPRESA_FAC').AsString;
  Result.EsRetenciones := AFactura.FieldByName(
    'ESRETENCIONES_EMPRESA_FAC').AsString;
  Result.EsIvaRecargo := '';
  Result.EsRegimenEspecialAgricola := AFactura.FieldByName(
    'ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC').AsString;
  Result.GrupoZonaIva := AFactura.FieldByName(
    'GRUPO_ZONA_IVA_EMPRESA_FAC').AsString;
  Result.Usuario := AUsuario;
end;

procedure CopiarConfiguracionIvaFactura(
  AOrigen, ADestino: TDataSet);
begin
  CopiarCadena(AOrigen, ADestino,
    'PORCENTAJE_NORMAL_IVA', 'PORCENTAJE_IVAN_FAC');
  CopiarCadena(AOrigen, ADestino,
    'PORCENTAJE_NORMAL_RE_IVA', 'PORCENTAJE_REN_FAC');
  CopiarCadena(AOrigen, ADestino,
    'PORCENTAJE_REDUCIDO_IVA', 'PORCENTAJE_IVAR_FAC');
  CopiarCadena(AOrigen, ADestino,
    'PORCENTAJE_REDUCIDO_RE_IVA', 'PORCENTAJE_RER_FAC');
  CopiarCadena(AOrigen, ADestino,
    'PORCENTAJE_SUPERREDUCIDO_IVA', 'PORCENTAJE_IVAS_FAC');
  CopiarCadena(AOrigen, ADestino,
    'PORCENTAJE_SUPERREDUCIDO_RE_IVA', 'PORCENTAJE_RES_FAC');
  CopiarCadena(AOrigen, ADestino,
    'PORCENTAJE_EXENTO_IVA', 'PORCENTAJE_IVAE_FAC');
  CopiarCadena(AOrigen, ADestino,
    'PORCENTAJE_EXENTO_RE_IVA', 'PORCENTAJE_REE_FAC');
  CopiarCadena(AOrigen, ADestino,
    'ESIRPF_IMP_INCL_IVA_IVAGRP', 'ESIRPF_IMP_INCL_ZONA_IVA_FAC');
  CopiarCadena(AOrigen, ADestino,
    'ESAPLICA_RE_IVA_IVAGRP', 'ESAPLICA_RE_ZONA_IVA_FAC');
  CopiarCadena(AOrigen, ADestino,
    'CODIGO_IVA', 'CODIGO_IVA_FAC');
  CopiarCadena(AOrigen, ADestino,
    'ESIVAAGRICOLA_IVA_IVAGRP', 'ESIVAAGRICOLA_ZONA_IVA_FAC');
  CopiarCadena(AOrigen, ADestino,
    'PALABRA_REPORTS_IVA_IVAGRP', 'PALABRA_REPORTS_ZONA_IVA_FAC');
end;

function CrearDatosValidacionCabeceraFactura(
  AFactura: TDataSet): TDatosValidacionCabeceraFactura;
begin
  Result := Default(TDatosValidacionCabeceraFactura);
  Result.Serie := AFactura.FieldByName('SERIE_FAC').AsString;
  Result.Numero := AFactura.FieldByName('NUMERO_FAC').AsString;
  Result.TipoFactura := AFactura.FieldByName('TIPO_FAC').AsString;
  Result.Fase := AFactura.FieldByName('FASE_FAC').AsString;
  Result.RazonSocialCliente := AFactura.FieldByName(
    'RAZON_SOCIAL_CLIENTE_FAC').AsString;
  Result.RazonSocialEmpresa := AFactura.FieldByName(
    'RAZON_SOCIAL_EMPRESA_FAC').AsString;
  Result.CodigoPaisCliente := AFactura.FieldByName(
    'CODIGO_PAI_CLIENTE_FAC').AsString;
  Result.NombrePaisCliente := AFactura.FieldByName(
    'NOMBRE_PAI_CLIENTE_FAC').AsString;
  Result.CodigoPaisEmpresa := AFactura.FieldByName(
    'CODIGO_PAI_EMPRESA_FAC').AsString;
  Result.NombrePaisEmpresa := AFactura.FieldByName(
    'NOMBRE_PAI_EMPRESA_FAC').AsString;
  Result.NifCliente := AFactura.FieldByName(
    'NIF_CLIENTE_FAC').AsString;
  Result.NifEmpresa := AFactura.FieldByName(
    'NIF_EMPRESA_FAC').AsString;
  Result.TieneFecha := not AFactura.FieldByName('FECHA_FAC').IsNull;
  if Result.TieneFecha then
    Result.Fecha := AFactura.FieldByName('FECHA_FAC').AsDateTime;
end;

end.
