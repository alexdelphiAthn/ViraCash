{******************************************************************************}
{                                                                              }
{  Módulo:       VentasViraCash                                                    }
{    Tipo:       Proyecto (App FMX móvil)                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       26/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    App de consulta de ventas del día. Lee de ventas/lineas.php y enseña      }
{    cada línea con su foto, más el total del día. Solo lectura: no envía      }
{    nada a ViraCash. Notas de uso en LEEME.md.                                }
{******************************************************************************}
program VentasViraCash;

uses
  System.StartUpCopy,
  FMX.Forms,
  SesionClienteMovil in '..\SesionClienteMovil.pas',
  ConfiguracionClienteMovil in '..\ConfiguracionClienteMovil.pas',
  VentasModelo in 'VentasModelo.pas',
  VentasConfig in 'VentasConfig.pas',
  VentasApi in 'VentasApi.pas',
  VentasTicket in 'VentasTicket.pas',
  VentasVisor in 'VentasVisor.pas',
  fVentasListado in 'fVentasListado.pas',
  fVentasFicha in 'fVentasFicha.pas',
  fVentasCierre in 'fVentasCierre.pas',
  fVentasFiltros in 'fVentasFiltros.pas',
  fVentasConfig in 'fVentasConfig.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmListado, frmListado);
  Application.Run;
end.
