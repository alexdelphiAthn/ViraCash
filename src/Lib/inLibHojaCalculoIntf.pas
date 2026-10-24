{******************************************************************************}
{                                                                              }
{  Módulo:       inLibHojaCalculoIntf                                          }
{    Tipo:       Librería (interfaces)                                         }
{ Versión:       2.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Puertos de contenido, formato, guardado y lectura de hojas de cálculo,    }
{    independientes del motor concreto. Cada consumidor recibe solo las       }
{    operaciones que usa.                                                      }
{******************************************************************************}
unit inLibHojaCalculoIntf;

interface

uses
  System.Variants;

type
  // Alineación horizontal neutra (el adaptador la mapea a ssah*).
  TAlineacionCelda = (acIzquierda, acCentro, acDerecha);
  // Grosor de borde neutro (el adaptador lo mapea a
  // TdxSpreadSheetCellBorderStyle).
  TEstiloBorde = (ebNinguno, ebFino, ebMedio, ebGrueso);
  // Lado de una celda para bordes sueltos (el adaptador lo mapea a TcxBorder).
  TLadoBorde = (lbSuperior, lbInferior, lbIzquierdo, lbDerecho);
  // Escritura de contenido y estructura. Índices en base 0.
  IEscritorHojaCalculo = interface
    ['{4584B695-CCB6-4AE2-A94B-33F28A5D8EDD}']
    // Limpia el libro y crea una hoja nueva con ese nombre; queda activa.
    procedure NuevaHoja(const ANombre: string);
    procedure IniciarLote;
    procedure FinalizarLote;
    procedure Escribir(AFila, ACol: Integer; const AValor: Variant);
    procedure EscribirFormula(
      AFila, ACol: Integer;
      const AFormula: string);
    procedure Combinar(AFila, ACol, ANumFilas, ANumCols: Integer);
    function CeldaExiste(AFila, ACol: Integer): Boolean;
  end;
  // Capacidad opcional para escribir y formatear una celda de una vez.
  IEscritorHojaCalculoConFormato = interface
    ['{06D55DC5-2D65-4866-9CB5-7EB65196A6BA}']
    procedure EscribirConFormato(
      AFila, ACol: Integer;
      const AValor: Variant;
      ANegrita: Boolean;
      AAlineacion: TAlineacionCelda;
      const AFormato: string);
  end;
  // Capacidad opcional para incrustar la imagen de un archivo en una celda.
  IImagenesHojaCalculo = interface
    ['{5B0C2E8A-7D41-4F6B-9E3A-2C8D1F4A6B57}']
    // Encaja la imagen en AAnchoMaximo x AAltoMaximo píxeles, centrada y
    // anclada a la celda, y deja la fila con alto suficiente. Falso si el
    // archivo no existe o no se puede cargar.
    function InsertarImagen(AFila, ACol: Integer; const ARuta: string;
      AAnchoMaximo, AAltoMaximo: Integer): Boolean;
  end;
  // Formato visual. El color es un TColor codificado como Cardinal
  // ($00BBGGRR) para no depender de la VCL.
  IFormateadorHojaCalculo = interface
    ['{7A671706-776A-4E5A-A16D-A05E62811C9F}']
    procedure DibujarCuadro(AF1, AC1, AF2, AC2: Integer;
                            AEstilo: TEstiloBorde);
    procedure BordeCelda(AFila, ACol: Integer; ALado: TLadoBorde;
                         AEstilo: TEstiloBorde);
    procedure FondoCelda(AFila, ACol: Integer; AColor: Cardinal);
    procedure Negrita(AFila, ACol: Integer; AActivar: Boolean = True);
    procedure TamanoFuente(AFila, ACol: Integer; ATamano: Integer);
    procedure AnchoColumna(ACol: Integer; AAncho: Integer);
    procedure Alinear(
      AFila, ACol: Integer;
      AAlineacion: TAlineacionCelda);
    procedure AplicarFormato(
      AFila, ACol: Integer;
      const AFormato: string);
  end;
  IGuardadorHojaCalculo = interface
    ['{35A0166C-A008-4BF7-A245-8006A38C1C07}']
    procedure Guardar(const ARuta: string);
  end;
  TServiciosHojaCalculo = record
    Escritor: IEscritorHojaCalculo;
    Formateador: IFormateadorHojaCalculo;
    Guardador: IGuardadorHojaCalculo;
  end;
  // Puerto de lectura: ruta de importación (leer celdas por índice, base 0).
  ILectorHojaCalculo = interface
    ['{3AB967F2-9117-45FE-B256-D36FDC2F1ACB}']
    function LeerCelda(AFila, ACol: Integer): Variant;
    function LeerFormatoCelda(AFila, ACol: Integer): string;
    function UltimaFila: Integer;
    function UltimaColumna: Integer;
  end;

implementation

end.
