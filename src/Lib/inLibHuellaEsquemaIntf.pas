{******************************************************************************}
{                                                                              }
{  Módulo:       inLibHuellaEsquemaIntf                                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Tipos y contrato de la huella del esquema (Ayuda > Comprobar              }
{    integridad): elementos del catálogo por apartado y lector que los saca    }
{    de la base conectada.                                                     }
{******************************************************************************}
unit inLibHuellaEsquemaIntf;

interface

type
  // Mismo orden y nombres que PRC_FZA_HUELLA_ESQUEMA. Los cuatro primeros
  // forman la huella global; CODIGO depende del motor e INDICES es solo
  // informativo (ajustes de índices de cada cliente).
  TApartadoHuella = (
    ahEstructura,
    ahVistas,
    ahRutinas,
    ahDefinidores,
    ahCodigo,
    ahIndices);

  TElementoHuella = record
    Apartado: TApartadoHuella;
    Objeto: string;
    Firma: string;
  end;

  TElementosHuella = TArray<TElementoHuella>;

  THuellasEsquema = record
    Global: string;
    Apartados: array[TApartadoHuella] of string;
  end;

  THuellasProcedimiento = record
    Existe: Boolean;
    Version: Integer;
    Huellas: THuellasEsquema;
    // Mensaje del servidor si existe pero falla al llamarlo.
    Error: string;
  end;

  TContextoCatalogo = record
    BaseDatos: string;
    VersionServidor: string;
    Usuario: string;
  end;

  // Lee el catálogo de la base conectada con los permisos del usuario. Las
  // consultas son las mismas que las de PRC_FZA_HUELLA_ESQUEMA, pero van en
  // el programa: así la comprobación no depende de lo que haya en la base.
  ILectorCatalogoEsquema = interface
    ['{6B0E5D52-6E0B-4C41-9C2D-3F3F1E7A8C11}']
    function LeerContexto: TContextoCatalogo;
    function LeerElementos: TElementosHuella;
    function LeerHuellasProcedimiento: THuellasProcedimiento;
  end;

const
  cFirmaSinPermiso = 'SIN_PERMISO';

function TextoApartadoHuella(AApartado: TApartadoHuella): string;
function EsApartadoGlobal(AApartado: TApartadoHuella): Boolean;

implementation

function TextoApartadoHuella(AApartado: TApartadoHuella): string;
const
  cTextos: array[TApartadoHuella] of string = (
    'ESTRUCTURA',
    'VISTAS',
    'RUTINAS',
    'DEFINIDORES',
    'CODIGO',
    'INDICES');
begin
  Result := cTextos[AApartado];
end;

function EsApartadoGlobal(AApartado: TApartadoHuella): Boolean;
begin
  Result := AApartado in [ahEstructura, ahVistas, ahRutinas, ahDefinidores];
end;

end.
