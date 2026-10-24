{******************************************************************************}
{  Modulo:       inLibPrecargaComprasIntf                                      }
{  Tipo:         Contratos de aplicacion                                       }
{  Version:      1.0.0                                                         }
{  Fecha:        27/08/2026                                                    }
{  Autor:        Alejandro Laorden Hidalgo                                     }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{  Descripcion:  Precarga de compras por series, sin dependencias de UI o SQL. }
{******************************************************************************}
unit inLibPrecargaComprasIntf;

interface

uses
  inLibPrecargaMantenimientos;

const
  // Mismo umbral que el acotado historico del mantenimiento de Articulos.
  UMBRAL_PRECARGA_COMPRAS = UMBRAL_PRECARGA_MANTENIMIENTOS;

type
  TSeriePrecargaCompra = record
    Codigo: string;
    UltimoDocumento: TDateTime;
  end;

  TSeriesPrecargaCompra = TArray<TSeriePrecargaCompra>;

  IRepositorioPrecargaCompras = interface
    ['{FEF72E35-E3EC-449D-8F24-623A0BD8D132}']
    // Devuelve como maximo umbral + 1, sin descargar las cabeceras.
    // Un array vacio significa todas las series autorizadas.
    function ContarHastaUmbral(const ASeries: TArray<string>): Integer;
    // Orden: fecha del ultimo documento descendente y codigo descendente.
    function ListarSeries: TSeriesPrecargaCompra;
    // Deja la consulta cerrada; nunca abre, carga ni guarda ediciones.
    procedure AplicarSeries(const ASeries: TArray<string>);
    procedure QuitarFiltro;
  end;

  TSeleccionarSeriesPrecarga = reference to function(
    const ACatalogo: TSeriesPrecargaCompra;
    const ASeleccion: TArray<string>;
    out ANuevaSeleccion: TArray<string>): Boolean;

implementation

end.
