{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGuiasGridPersistenciaIntf                               }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Contrato de persistencia para enriquecer y guardar guías de grid.         }
{******************************************************************************}
unit inLibGuiasGridPersistenciaIntf;

interface

uses
  System.Variants, inLibInformesGuiasCache;

type
  TParametroConsultaGuia = record
    Nombre: string;
    Valor: Variant;
  end;

  TResultadoEnriquecimientoGuias = record
    Exito: Boolean;
    SqlEnriquecido: string;
    CamposNuevos: TArray<string>;
    CamposTabla: TArray<string>;
    ColumnasVisibles: TArray<string>;
  end;

  IPersistenciaGuiasGrid = interface
    ['{B6A464EC-9B84-433D-A1EE-EFBE409B42D0}']
    function Enriquecer(
      const ASqlOriginal: string;
      const AParametros: TArray<TParametroConsultaGuia>;
      const AGuias: TArray<TInformeGuiaItem>
    ): TResultadoEnriquecimientoGuias;
    procedure Borrar(const AInforme: string);
    procedure GuardarColumnasVisibles(
      const AInforme, AColumnas: string);
  end;

resourcestring
  SErrorPersistenciaGuiasNoConfigurada =
    'La persistencia de guías de grid no está configurada.';

implementation

end.
