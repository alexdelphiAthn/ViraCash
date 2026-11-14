{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataInformeFacturasProforma                               }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Prepara los datos del informe de proformas internas de caja.              }
{******************************************************************************}
unit UniDataInformeFacturasProforma;

interface

uses
  System.Classes, Data.DB, MemDS, DBAccess, Uni, UniDataGen;

type
  TdmInformeFacturasProforma = class(TdmBase)
    unqryProforma: TUniQuery;
    unqryLineas: TUniQuery;
  private
    FSqlLineasVenta: string;
  public
    procedure Cargar(AIdProforma: Int64);
  end;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

const
  SQL_LINEAS_VALES =
    'SELECT V.CODIGO_VL_PROCVL AS ID_OPCAJA_PROCLIN, ' +
    'V.CODIGO_VL_PROCVL AS LINEA_PROCLIN, ' +
    'V.CODIGO_VL_PROCVL AS CODIGO_ART_PROCLIN, ' +
    'SPACE(0) AS CODIGO_UNIDAD_PROCLIN, ' +
    'CONCAT(''VALE '', V.CODIGO_VL_PROCVL) ' +
    'AS DESCRIPCION_VINCULO_PROCLIN, ' +
    'V.NUMERO_OPERACION_RED_PROCVL AS NUMERO_OPERACION_PROCLIN, ' +
    'V.FECHA_REDENCION_PROCVL AS FECHA_OPERACION_PROCLIN, ' +
    'CONCAT(''Emitido por '', V.CODIGO_EMP_EMI_PROCVL, ' +
    ''', recogido por '', V.CODIGO_EMP_RED_PROCVL) ' +
    'AS DESCRIPCION_ARTICULO_PROCLIN, ' +
    '1 AS CANTIDAD_PROCLIN, ' +
    'V.IMPORTE_COMPENSACION_PROCVL AS PRECIO_SIVA_PROCLIN, ' +
    '0 AS PORCENTAJE_IVA_PROCLIN, ' +
    'V.IMPORTE_COMPENSACION_PROCVL AS TOTAL_PROCLIN ' +
    'FROM fza_proformas_caja_vales V ' +
    'WHERE V.ID_PROCAJ_PROCVL = :id_proforma ' +
    'ORDER BY V.FECHA_REDENCION_PROCVL, V.CODIGO_VL_PROCVL';

procedure TdmInformeFacturasProforma.Cargar(AIdProforma: Int64);
begin
  unqryProforma.Close;
  unqryLineas.Close;
  unqryProforma.Connection := ConexionPrincipal;
  unqryLineas.Connection := ConexionPrincipal;
  unqryProforma.ParamByName('id_proforma').AsLargeInt := AIdProforma;
  unqryProforma.Open;
  if FSqlLineasVenta = '' then
    FSqlLineasVenta := unqryLineas.SQL.Text;
  if unqryProforma.FieldByName('TIPO_PROCAJ').AsString = 'VR' then
    unqryLineas.SQL.Text := SQL_LINEAS_VALES
  else
    unqryLineas.SQL.Text := FSqlLineasVenta;
  unqryLineas.ParamByName('id_proforma').AsLargeInt := AIdProforma;
  unqryLineas.Open;
end;

end.
