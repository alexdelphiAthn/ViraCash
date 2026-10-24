{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVerifactuTipos                                           }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Tipos fiscales compartidos sin dependencias de infraestructura.           }
{******************************************************************************}
unit inLibVerifactuTipos;

interface

type
  TModoVerifactu = (
    mvSinVerifactu,
    mvVerifactu,
    mvNoVerifactu,
    // Suministro Inmediato de Información: sustituye a VeriFactu (sin
    // huella, cadena, QR ni firma) y usa la misma cola.
    mvSii);

implementation
end.
