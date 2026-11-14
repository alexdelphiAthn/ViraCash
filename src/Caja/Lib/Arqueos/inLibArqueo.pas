{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArqueo                                                   }
{    Tipo:       Fachada                                                       }
{ Versión:       1.2.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Alias compatibles del contrato de cálculo de arqueo.                     }
{******************************************************************************}
unit inLibArqueo;

interface

uses
  inLibArqueoIntf;

const
  TipoOpVenta = inLibArqueoIntf.TipoOpVenta;
  TipoOpDevolucion = inLibArqueoIntf.TipoOpDevolucion;
  TipoOpCobroCuenta = inLibArqueoIntf.TipoOpCobroCuenta;
  TipoOpEntradaCambio = inLibArqueoIntf.TipoOpEntradaCambio;
  TipoOpGastoCaja = inLibArqueoIntf.TipoOpGastoCaja;
  TipoOpDeposito = inLibArqueoIntf.TipoOpDeposito;
  TipoOpValeRedimido = inLibArqueoIntf.TipoOpValeRedimido;
  EstadoDepositoAbierto = inLibArqueoIntf.EstadoDepositoAbierto;

type
  TArqueoPagoForma = inLibArqueoIntf.TArqueoPagoForma;
  TArqueoCaja = inLibArqueoIntf.TArqueoCaja;

implementation

end.
