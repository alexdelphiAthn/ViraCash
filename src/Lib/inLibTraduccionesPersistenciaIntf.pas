{******************************************************************************}
{                                                                              }
{  Módulo:       inLibTraduccionesPersistenciaIntf                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos de lectura para el catálogo y el idioma configurado.            }
{******************************************************************************}
unit inLibTraduccionesPersistenciaIntf;

interface

type
  TEntradaCatalogoTraduccion = record
    Clave: string;
    Texto: string;
  end;

  TEntradaInformeTraduccion = record
    TextoBase: string;
    TextoIdioma: string;
  end;

  TCatalogoTraducciones = record
    Textos: TArray<TEntradaCatalogoTraduccion>;
    TextosInforme: TArray<TEntradaInformeTraduccion>;
  end;

  ILectorCatalogoTraducciones = interface
    ['{96B711CF-6F58-4E21-80D7-AA1A3F7641A0}']
    function Cargar(
      const AIdioma, AIdiomaBase: string): TCatalogoTraducciones;
  end;

  ILectorIdiomaConfigurado = interface
    ['{5F589D0A-9D1E-4CC9-9349-18D066017613}']
    function Leer(const AUsuario: string): string;
  end;

implementation

end.
