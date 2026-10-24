{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasValidacionUniDAC                                 }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Adaptador UniDAC para consultas de validación fiscal de facturas.         }
{******************************************************************************}
unit inLibFacturasValidacionUniDAC;

interface

uses
  System.Classes,
  Data.DB,
  DBAccess,
  Uni;

procedure CargarConfiguracionIvaFactura(
  AOwner: TComponent;
  AConexion: TUniConnection;
  const AGrupo: string;
  AFecha: TDateTime;
  ADestino: TDataSet);
procedure AplicarRetencionEmpresaFactura(
  AOwner: TComponent;
  AConexion: TUniConnection;
  AFactura: TDataSet);

implementation

uses
  inLibFacturasValidacionDatos;

procedure CargarConfiguracionIvaFactura(
  AOwner: TComponent;
  AConexion: TUniConnection;
  const AGrupo: string;
  AFecha: TDateTime;
  ADestino: TDataSet);
var
  Consulta: TUniQuery;
begin
  if AGrupo <> '' then
  begin
    Consulta := TUniQuery.Create(AOwner);
    try
      Consulta.Connection := AConexion;
      Consulta.SQL.Text :=
        'SELECT * FROM vi_ivas ' +
        'WHERE IVA_IVAGRP = :grupo ' +
        'AND FECHA_DESDE_IVA <= :fecha_ini ' +
        'AND (FECHA_HASTA_IVA >= :fecha_fin ' +
        'OR FECHA_HASTA_IVA IS NULL)';
      Consulta.ParamByName('grupo').AsString := AGrupo;
      Consulta.ParamByName('fecha_ini').AsDateTime := AFecha;
      Consulta.ParamByName('fecha_fin').AsDateTime := AFecha;
      Consulta.Open;
      if not Consulta.IsEmpty then
        CopiarConfiguracionIvaFactura(Consulta, ADestino);
    finally
      Consulta.Free;
    end;
  end;
end;

procedure AplicarRetencionEmpresaFactura(
  AOwner: TComponent;
  AConexion: TUniConnection;
  AFactura: TDataSet);
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(AOwner);
  try
    Consulta.Connection := AConexion;
    Consulta.SQL.Text :=
      'SELECT * FROM fza_empresas_retenciones ' +
      'WHERE CODIGO_EMP_EMPRET = :empresa ' +
      'AND FECHA_DESDE_EMPRET <= :fecha ' +
      'AND (FECHA_HASTA_EMPRET >= :fecha ' +
      'OR FECHA_HASTA_EMPRET IS NULL) LIMIT 1';
    Consulta.ParamByName('empresa').AsString :=
      AFactura.FieldByName('CODIGO_EMP_FAC').AsString;
    Consulta.ParamByName('fecha').AsDateTime :=
      AFactura.FieldByName('FECHA_FAC').AsDateTime;
    Consulta.Open;
    if not Consulta.IsEmpty and
       (AFactura.FieldByName(
         'PORCENTAJE_RETENCION_FAC').AsFloat = 0) then
    begin
      AFactura.FieldByName('PORCENTAJE_RETENCION_FAC').AsFloat :=
        Consulta.FieldByName('PORCENTAJE_EMPRET').AsFloat;
    end;
  finally
    Consulta.Free;
  end;
end;

end.
