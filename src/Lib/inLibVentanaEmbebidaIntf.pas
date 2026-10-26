{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVentanaEmbebidaIntf                                      }
{    Tipo:       Librería (interfaces)                                         }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos entre el marco (inLibFormManager / inLibShowMto) y los         }
{    mantenimientos embebidos. TfrmMtoGen los implementa; las librerías       }
{    hablan con las interfaces y dejan de conocer la clase concreta.          }
{******************************************************************************}
unit inLibVentanaEmbebidaIntf;

interface

uses
  System.SysUtils;

type
  IBorradoContextualVentana = interface
    ['{F8B1F60D-1E74-4403-8DB9-F6B56C20AFD8}']
    // True consume el atajo, incluso si el contexto sólo permite consultar.
    function ProcesarBorradoContextual: Boolean;
  end;

  TConfiguracionVentanaGestionada = record
    Separada: Boolean;
    Grupo: string;
    RecursoIcono: string;
    Cerrar: TProc;
    Volver: TProc;
    MostrarMenu: TProc<Integer, Integer>;
  end;

  IVentanaSeparable = interface
    ['{189FBC33-D91D-470B-A9B9-8D632F2D3710}']
    procedure ConfigurarVentanaGestionada(
      const AConfiguracion: TConfiguracionVentanaGestionada);
    procedure CambiarContenedor(ACambiando: Boolean);
  end;

  TRolAperturaMantenimiento = (
    ramBusqueda,
    ramPrimeraLista,
    ramListaAdicional
  );

  // Ventana embebida en el marco principal.
  IVentanaEmbebida = interface
    ['{782AB710-5D2A-4C5D-9523-A686807D5078}']
    // True si la ventana intercepta el cierre y NO debe cerrarse aún
    // (p.ej. TfrmMtoGen vuelve de la ficha a la lista con el primer
    // cierre y solo cierra de verdad desde la lista).
    function InterceptarCierre: Boolean;
  end;

  // Mantenimiento genérico abierto por inLibShowMto.
  IMantenimientoEmbebido = interface(IVentanaEmbebida)
    ['{DAA11BD0-4933-4F32-B1F9-B567B2CBC200}']
    // Marca la instancia como "de búsqueda" (Ctrl+R). Con
    // AAplicarLayout recorta la UI (instancia 1 reservada); sin él la
    // marca es temporal solo durante el embebido.
    procedure ActivarModoBusqueda(AAplicarLayout: Boolean);
    procedure DesactivarModoBusqueda;
    // Filtra la lista a la clave recibida antes del Open (búsqueda
    // lanzada desde otra pantalla).
    procedure PrepararBusquedaExterna(const ABusq: string);
    // Abre la tabla principal: síncrono para búsquedas (el Locate
    // necesita la query activa al volver), asíncrono en aperturas
    // normales.
    procedure AbrirTablaPrincipal(ASincrono: Boolean);
    // Localiza ABusq por la clave primaria y pasa a la ficha. False
    // SOLO si se buscó y no se encontró (el llamante avisa entonces);
    // True si se encontró o si no procedía buscar.
    function LocalizarYEnfocar(const ABusq: string): Boolean;
    // Se consulta antes del primer Open, ya embebido. Devolver
    // False cancela la apertura (lista sin el filtro elegido).
    function PrepararPrecarga(
      ARol: TRolAperturaMantenimiento): Boolean;
  end;

// La instancia 1 se reserva a busqueda; las listas empiezan por la 2.
// Cero identifica los mantenimientos configurados con una sola ventana.
function RolAperturaMantenimiento(
  ABusqueda: Boolean;
  ANumeroInstancia: Integer): TRolAperturaMantenimiento;

function ConsumirBorradoContextual(AReceptor: TObject): Boolean;

implementation

function ConsumirBorradoContextual(AReceptor: TObject): Boolean;
var
  Receptor: IBorradoContextualVentana;
begin
  Result := Supports(AReceptor, IBorradoContextualVentana, Receptor);
  if Result then
    Result := Receptor.ProcesarBorradoContextual;
end;

function RolAperturaMantenimiento(
  ABusqueda: Boolean;
  ANumeroInstancia: Integer): TRolAperturaMantenimiento;
begin
  if ABusqueda then
    Result := ramBusqueda
  else if ANumeroInstancia > 2 then
    Result := ramListaAdicional
  else
    Result := ramPrimeraLista;
end;

end.
