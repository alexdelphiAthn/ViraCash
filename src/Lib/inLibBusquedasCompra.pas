{******************************************************************************}
{                                                                              }
{  Módulo:       inLibBusquedasCompra                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Consultas y ejecución común de las búsquedas de artículos de proveedor   }
{    y SKUs usadas por los documentos de compra.                              }
{******************************************************************************}
unit inLibBusquedasCompra;

interface

uses
  Data.DB, Vcl.Forms, inLibGenBusq,
  inLibBusquedasCompraPersistenciaIntf;

function ValorTextoDataSetCompra(ADataSet: TDataSet;
  const ACampo: string): string;
function BuscarArticuloProveedorCompra(
  const APersistencia: IBusquedasCompraPersistencia;
  const ABusquedaVisual: IBusquedaVisual;
  const ACodigoProveedor, ACaption,
  ANombreFormulario: string;
  AFormularioPadre: TCustomForm): string;
function BuscarSkuArticuloCompra(
  const APersistencia: IBusquedasCompraPersistencia;
  const ABusquedaVisual: IBusquedaVisual;
  const ACodigoArticulo, ACaption,
  ANombreFormulario: string;
  AFormularioPadre: TCustomForm): string;

implementation

uses
  System.SysUtils;

function ValorTextoDataSetCompra(ADataSet: TDataSet;
  const ACampo: string): string;
var
  oCampo: TField;
begin
  Result := '';
  if Assigned(ADataSet) and ADataSet.Active and
     not ADataSet.IsEmpty then
  begin
    oCampo := ADataSet.FindField(ACampo);
    if Assigned(oCampo) then
      Result := Trim(oCampo.AsString);
  end;
end;

function BuscarArticuloProveedorCompra(
  const APersistencia: IBusquedasCompraPersistencia;
  const ABusquedaVisual: IBusquedaVisual;
  const ACodigoProveedor, ACaption,
  ANombreFormulario: string;
  AFormularioPadre: TCustomForm): string;
var
  oConsulta: IConsultaBusquedaCompra;
  sProveedor: string;
begin
  Result := '';
  sProveedor := Trim(ACodigoProveedor);
  if Assigned(APersistencia) and Assigned(ABusquedaVisual) and
     (sProveedor <> '') then
  begin
    oConsulta := APersistencia.ConsultarArticulosProveedor(sProveedor);
    if Assigned(oConsulta) and
       ABusquedaVisual.EjecutarBusquedaDataSet(
         ACaption, oConsulta.DataSet, ANombreFormulario,
         AFormularioPadre) then
      Result := ValorTextoDataSetCompra(
        oConsulta.DataSet, 'CODIGO_ART_ART');
  end;
end;

function BuscarSkuArticuloCompra(
  const APersistencia: IBusquedasCompraPersistencia;
  const ABusquedaVisual: IBusquedaVisual;
  const ACodigoArticulo, ACaption,
  ANombreFormulario: string;
  AFormularioPadre: TCustomForm): string;
var
  oConsulta: IConsultaBusquedaCompra;
  sArticulo: string;
begin
  Result := '';
  sArticulo := Trim(ACodigoArticulo);
  if Assigned(APersistencia) and Assigned(ABusquedaVisual) and
     (sArticulo <> '') then
  begin
    oConsulta := APersistencia.ConsultarSkusArticulo(sArticulo);
    if Assigned(oConsulta) and
       ABusquedaVisual.EjecutarBusquedaDataSet(
         ACaption, oConsulta.DataSet, ANombreFormulario,
         AFormularioPadre) then
      Result := ValorTextoDataSetCompra(
        oConsulta.DataSet, 'CODIGO_UNIDAD_SKU');
  end;
end;

end.
