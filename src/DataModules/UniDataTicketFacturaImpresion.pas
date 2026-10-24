{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataTicketFacturaImpresion                                 }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Datos de caja que un ticket (factura simplificada) muestra además de la   }
{    factura: datasets FastReport 'Ticket' (vendedor, tienda, pie de ticket    }
{    de la empresa, entregado y cambio) y 'Pagos Ticket' (líneas de pago).     }
{    Se crean dentro del data module de impresión de facturas para que         }
{    RebindReportDataSetsByDataModule los publique junto a 'Facturas' y        }
{    'Lineas Facturas', también en el diseñador.                               }
{    El enlace con la operación usa las columnas de caja de la factura, que    }
{    están indexadas (IDX_AGRUPACION_OPCAJA y PK de fza_caja_pagos).           }
{******************************************************************************}
unit UniDataTicketFacturaImpresion;

interface

uses
  System.Classes, Uni;

// Crea una sola vez los datasets del ticket dentro de ADataModule.
procedure AsegurarDatosTicketImpresion(ADataModule: TComponent;
  AConexion: TUniConnection);

// Abre los datasets del ticket para la factura indicada.
procedure AbrirDatosTicketImpresion(ADataModule: TComponent;
  const ASerie, ANumero: string);

implementation

uses
  System.SysUtils, frxDBSet;

const
  cNombreConsultaTicket = 'unqryTicketPrint';
  cNombreConsultaPagos  = 'unqryPagosTicketPrint';
  cNombreDatosTicket    = 'fxdsTicketPrint';
  cNombreDatosPagos     = 'fxdsPagosTicketPrint';

  cSqlTicket =
    'SELECT f.SERIE_FAC, f.NUMERO_FAC, ' +
    '       COALESCE(NULLIF(TRIM(empl.DIMINUTIVO_TICKET_EMPL), ''''), ' +
    '                NULLIF(TRIM(empl.NOMBRE_EMPL), ''''), ' +
    '                o.CODIGO_EMPLEADO_OPCAJA, f.CODIGO_CAJERO_FAC) ' +
    '         AS VENDEDOR_TICKET, ' +
    '       alm.NOMBRE_ALM_ALM, alm.DIRECCION_ALM, alm.POBLACION_ALM, ' +
    '       alm.CODIGO_POSTAL_ALM, alm.TELEFONO_ALM, ' +
    '       emp.TEXTO_PIE_TICKET_CAJA_1_EMP, emp.TEXTO_PIE_TICKET_CAJA_2_EMP, ' +
    '       emp.TEXTO_PIE_TICKET_CAJA_3_EMP, emp.TEXTO_PIE_TICKET_CAJA_4_EMP, ' +
    '       COALESCE((SELECT SUM(p.IMPORTE_ENTREGADO_PAGO) ' +
    '                   FROM fza_caja_pagos p ' +
    '                  WHERE p.CODIGO_EMP_PAGO = f.CODIGO_EMP_FAC ' +
    '                    AND p.CODIGO_ALM_PAGO = f.CODIGO_ALM_FAC ' +
    '                    AND p.CODIGO_CAJA_PAGO = f.CODIGO_CAJA_FAC ' +
    '                    AND p.SERIE_OPERACION_PAGO = f.SERIE_FAC ' +
    '                    AND p.NUMERO_OPERACION_PAGO = ' +
    '                        f.NUMERO_OPERACION_FAC), 0) AS ENTREGADO_TICKET, ' +
    '       COALESCE((SELECT SUM(p.IMPORTE_CAMBIO_PAGO) ' +
    '                   FROM fza_caja_pagos p ' +
    '                  WHERE p.CODIGO_EMP_PAGO = f.CODIGO_EMP_FAC ' +
    '                    AND p.CODIGO_ALM_PAGO = f.CODIGO_ALM_FAC ' +
    '                    AND p.CODIGO_CAJA_PAGO = f.CODIGO_CAJA_FAC ' +
    '                    AND p.SERIE_OPERACION_PAGO = f.SERIE_FAC ' +
    '                    AND p.NUMERO_OPERACION_PAGO = ' +
    '                        f.NUMERO_OPERACION_FAC), 0) AS CAMBIO_TICKET ' +
    '  FROM fza_facturas f ' +
    '  LEFT JOIN fza_caja_operaciones o ' +
    '    ON o.CODIGO_EMP_OPCAJA = f.CODIGO_EMP_FAC ' +
    '   AND o.CODIGO_ALM_OPCAJA = f.CODIGO_ALM_FAC ' +
    '   AND o.CODIGO_CAJA_OPCAJA = f.CODIGO_CAJA_FAC ' +
    '   AND o.NUMERO_OPERACION_OPCAJA = f.NUMERO_OPERACION_FAC ' +
    '   AND o.SERIE_FAC_OPCAJA = f.SERIE_FAC ' +
    '   AND o.NUMERO_FAC_OPCAJA = f.NUMERO_FAC ' +
    '  LEFT JOIN fza_empleados empl ' +
    '    ON empl.CODIGO_EMPL = ' +
    '       COALESCE(o.CODIGO_EMPLEADO_OPCAJA, f.CODIGO_CAJERO_FAC) ' +
    '  LEFT JOIN fza_almacenes alm ON alm.CODIGO_ALM_ALM = f.CODIGO_ALM_FAC ' +
    '  LEFT JOIN fza_empresas emp ON emp.CODIGO_EMP_EMP = f.CODIGO_EMP_FAC ' +
    ' WHERE f.SERIE_FAC = :SERIE AND f.NUMERO_FAC = :NUMERO';

  cSqlPagosTicket =
    'SELECT p.NUMERO_LINEA_PAGO, p.CODIGO_FP_CFP, ' +
    '       COALESCE(NULLIF(TRIM(fp.DESCRIPCION_FORMA_PAGO_CFP), ''''), ' +
    '                p.CODIGO_FP_CFP) AS DESCRIPCION_FORMA_PAGO_CFP, ' +
    '       p.IMPORTE_ENTREGADO_PAGO, p.IMPORTE_CAMBIO_PAGO, ' +
    '       p.IMPORTE_ENTREGADO_PAGO - p.IMPORTE_CAMBIO_PAGO ' +
    '         AS IMPORTE_PAGADO_PAGO ' +
    '  FROM fza_facturas f ' +
    '  JOIN fza_caja_pagos p ' +
    '    ON p.CODIGO_EMP_PAGO = f.CODIGO_EMP_FAC ' +
    '   AND p.CODIGO_ALM_PAGO = f.CODIGO_ALM_FAC ' +
    '   AND p.CODIGO_CAJA_PAGO = f.CODIGO_CAJA_FAC ' +
    '   AND p.SERIE_OPERACION_PAGO = f.SERIE_FAC ' +
    '   AND p.NUMERO_OPERACION_PAGO = f.NUMERO_OPERACION_FAC ' +
    '  LEFT JOIN fza_caja_formas_pago fp ' +
    '    ON fp.CODIGO_FP_CFP = p.CODIGO_FP_CFP ' +
    ' WHERE f.SERIE_FAC = :SERIE AND f.NUMERO_FAC = :NUMERO ' +
    ' ORDER BY p.NUMERO_LINEA_PAGO';

procedure CrearDatos(ADataModule: TComponent; AConexion: TUniConnection;
  const sConsulta, sDatos, sUsuario, sSql: string);
var
  oConsulta: TUniQuery;
  oDatos: TfrxDBDataset;
begin
  oConsulta := TUniQuery.Create(ADataModule);
  oConsulta.Name := sConsulta;
  oConsulta.Connection := AConexion;
  oConsulta.SQL.Text := sSql;
  oDatos := TfrxDBDataset.Create(ADataModule);
  oDatos.Name := sDatos;
  oDatos.UserName := sUsuario;
  oDatos.CloseDataSource := False;
  oDatos.DataSet := oConsulta;
end;

procedure AsegurarDatosTicketImpresion(ADataModule: TComponent;
  AConexion: TUniConnection);
begin
  if (ADataModule = nil) or
     (ADataModule.FindComponent(cNombreDatosTicket) <> nil) then
    Exit;
  CrearDatos(ADataModule, AConexion, cNombreConsultaTicket,
    cNombreDatosTicket, 'Ticket', cSqlTicket);
  CrearDatos(ADataModule, AConexion, cNombreConsultaPagos,
    cNombreDatosPagos, 'Pagos Ticket', cSqlPagosTicket);
end;

procedure AbrirConsulta(ADataModule: TComponent; const sNombre, ASerie,
  ANumero: string);
var
  oComponente: TComponent;
  oConsulta: TUniQuery;
begin
  oComponente := ADataModule.FindComponent(sNombre);
  if not (oComponente is TUniQuery) then
    Exit;
  oConsulta := TUniQuery(oComponente);
  oConsulta.Close;
  oConsulta.ParamByName('SERIE').AsString := ASerie;
  oConsulta.ParamByName('NUMERO').AsString := ANumero;
  oConsulta.Open;
end;

procedure AbrirDatosTicketImpresion(ADataModule: TComponent;
  const ASerie, ANumero: string);
begin
  if ADataModule = nil then
    Exit;
  AbrirConsulta(ADataModule, cNombreConsultaTicket, ASerie, ANumero);
  AbrirConsulta(ADataModule, cNombreConsultaPagos, ASerie, ANumero);
end;

end.
