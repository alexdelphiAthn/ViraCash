{******************************************************************************}
{                                                                              }
{  Módulo:       RecuentoModelo                                                }
{    Tipo:       Librería (App FMX)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Tipos de datos del subsistema de recuento: modos del menú y los registros }
{    que viajan entre la app, el servidor y la cola local.                     }
{******************************************************************************}
unit RecuentoModelo;

interface

type
  // Los tres modos del menú principal (ver diseño §7.1).
  TModoRecuento = (mrCodigos,           // 1: cada escaneo suma +1
                   mrCodigosCantidad,    // 2: escaneo + cantidad tecleada
                   mrPlantilla);         // 3: recuento contra plantilla

  TAlmacenRec = record
    CodigoEmp : string;
    CodigoAlm : string;
    Nombre    : string;
  end;

  TPlantillaRec = record
    IdRecuento  : Int64;
    CodigoEmp   : string;
    CodigoAlm   : string;
    Serie       : string;
    Numero      : string;
    Descripcion : string;
    Estado      : string;   // PENDIENTE, EN_RECUENTO o RECONTADO
  end;

  TItemCatalogoRec = record
    CodigoArticulo  : string;
    CodigoUnidad    : string;   // SKU
    Descripcion     : string;
    CodigoBarras    : string;
    CantidadTeorica : Double;
    EsTrazable      : Boolean;
  end;

  // Una lectura. Uuid e InstanteRecuento los pone la app al escanear.
  TEventoRec = record
    Uuid             : string;
    CodigoBarras     : string;
    CodigoArticulo   : string;
    CodigoUnidad     : string;
    Cantidad         : Double;
    Lote             : string;
    FechaCaducidad   : string;   // 'YYYY-MM-DD' o vacío
    InstanteRecuento : string;   // 'YYYY-MM-DD HH:NN:SS'
    Zona             : string;
  end;

  TArrAlmacen   = TArray<TAlmacenRec>;
  TArrPlantilla = TArray<TPlantillaRec>;
  TArrCatalogo  = TArray<TItemCatalogoRec>;
  TArrEvento    = TArray<TEventoRec>;

implementation

end.
