{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataCajaPagosHist                                          }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module del histórico de pagos de caja.                               }
{    Contenedor de consultas sobre fza_caja_pagos para el histórico de cobros. }
{******************************************************************************}
unit UniDataCajaPagosHist;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser, UniDataConn;

type
  TdmCajaPagosHist = class(TdmBase)
  private
    FMaestroPagos: TDataSource;
    procedure CrearConsultasFactura;
    procedure RellenarParamsDesdePago(AConsulta: TUniQuery);
  public
    // Factura asociada al pago y sus lineas. Alimentan la rejilla
    // multinivel de la ficha y se abren al entrar en su pestana.
    unqryFacturaPago: TUniQuery;
    dsFacturaPago: TDataSource;
    unqryLineasFacturaPago: TUniQuery;
    dsLineasFacturaPago: TDataSource;
    // La pantalla pasa su propio origen de datos: de el salen el
    // numero y la serie de factura del pago en curso.
    procedure PrepararConsultasFactura(AMaestro: TDataSource);
    procedure AsegurarFacturaPagoAbierta;
  end;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmCajaPagosHist.CrearConsultasFactura;
begin
  if unqryFacturaPago = nil then
  begin
    unqryFacturaPago := TUniQuery.Create(Self);
    unqryFacturaPago.Connection := ConexionPrincipal;
    unqryFacturaPago.ReadOnly := True;
    unqryFacturaPago.SQL.Text :=
      'SELECT NUMERO_FAC, SERIE_FAC, FECHA_FAC, TIPO_FAC, ' +
      '       FASE_FAC, ESCONSOLIDADA_FAC, CODIGO_CLI_FAC, ' +
      '       RAZON_SOCIAL_CLIENTE_FAC, TOTAL_BASES_FAC, ' +
      '       TOTAL_IMPUESTOS_FAC, TOTAL_LIQUIDO_FAC ' +
      '  FROM fza_facturas ' +
      ' WHERE NUMERO_FAC = :NUMERO_FAC_PAGO ' +
      '   AND SERIE_FAC  = :SERIE_FAC_PAGO';
    dsFacturaPago := TDataSource.Create(Self);
    dsFacturaPago.DataSet := unqryFacturaPago;
  end;
  if unqryLineasFacturaPago = nil then
  begin
    unqryLineasFacturaPago := TUniQuery.Create(Self);
    unqryLineasFacturaPago.Connection := ConexionPrincipal;
    unqryLineasFacturaPago.ReadOnly := True;
    unqryLineasFacturaPago.SQL.Text :=
      'SELECT NUMERO_FAC_FACLIN, SERIE_FAC_FACLIN, ' +
      '       LINEA_FACLIN, CODIGO_ART_FACLIN, ' +
      '       DESCRIPCION_ARTICULO_FACLIN, ' +
      '       DESCRIPCION_VARIACION_FACLIN, ' +
      '       TIPO_CANTIDAD_ARTICULO_FACLIN, CANTIDAD_FACLIN, ' +
      '       PRECIO_SALIDA_FACLIN, ' +
      '       PRECIO_VENTA_CIVA_ARTICULO_FACLIN, TOTAL_FACLIN ' +
      '  FROM fza_facturas_lineas ' +
      ' WHERE NUMERO_FAC_FACLIN = :NUMERO_FAC_PAGO ' +
      '   AND SERIE_FAC_FACLIN  = :SERIE_FAC_PAGO ' +
      ' ORDER BY LINEA_FACLIN';
    dsLineasFacturaPago := TDataSource.Create(Self);
    dsLineasFacturaPago.DataSet := unqryLineasFacturaPago;
  end;
end;

procedure TdmCajaPagosHist.PrepararConsultasFactura(
  AMaestro: TDataSource);
begin
  FMaestroPagos := AMaestro;
  CrearConsultasFactura;
end;

procedure TdmCajaPagosHist.RellenarParamsDesdePago(
  AConsulta: TUniQuery);
var
  oPagos: TDataSet;
  oCampo: TField;
  i: Integer;
begin
  if (FMaestroPagos <> nil) and (FMaestroPagos.DataSet <> nil) then
  begin
    oPagos := FMaestroPagos.DataSet;
    if oPagos.Active and (not oPagos.IsEmpty) then
    begin
      for i := 0 to AConsulta.Params.Count - 1 do
      begin
        oCampo := oPagos.FindField(AConsulta.Params[i].Name);
        if oCampo <> nil then
          AConsulta.Params[i].Value := oCampo.Value;
      end;
    end;
  end;
end;

procedure TdmCajaPagosHist.AsegurarFacturaPagoAbierta;
begin
  CrearConsultasFactura;
  // Al cambiar de pago hay que releer: son consultas por parametro,
  // no un maestro-detalle que se refresque solo.
  unqryFacturaPago.Close;
  RellenarParamsDesdePago(unqryFacturaPago);
  unqryFacturaPago.Open;
  unqryLineasFacturaPago.Close;
  RellenarParamsDesdePago(unqryLineasFacturaPago);
  unqryLineasFacturaPago.Open;
end;

initialization
  RegistrarDataModule(TdmCajaPagosHist);
  ForceReferenceToClass(TdmCajaPagosHist);
end.
