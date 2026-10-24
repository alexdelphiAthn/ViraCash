{******************************************************************************}
{                                                                              }
{  Modulo:       inLibStockCeldaDocumento                                      }
{    Tipo:       Dominio                                                       }
{ Version:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Reglas para convertir la celda enfocada de la consulta de stock en        }
{    una linea de documento de trabajo: guardas del flujo, talla segun         }
{    la columna, almacen y color segun el modo del pivote y composicion        }
{    de la linea resultante.                                                   }
{                                                                              }
{    Sale de TfrmStockConsulta.ResolverCeldaDocumentoTrabajo, donde            }
{    vivia mezclado con el grid y no se podia probar. No conoce                }
{    formularios, DevExpress ni UniDAC: el llamante lee el grid, rellena       }
{    el estado y traduce el motivo a mensaje                                   }
{    (PLAN_SOLID.md Fase 3; LIBRO_DE_ESTILO_DELPHI.md 14.4).                   }
{******************************************************************************}
unit inLibStockCeldaDocumento;

interface

type
  // Por que no se puede enviar la celda al documento, si es que no se
  // puede. El formulario traduce cada motivo a su resourcestring.
  TMotivoCeldaDocumento = (
    mcdNinguno,
    mcdSinArticulo,
    mcdEstadoNoExistencias,
    mcdSinFila,
    mcdSinColumnaCantidad,
    mcdFilaNoExistencias,
    mcdColumnaNoValida,
    mcdGrupoNoLeido,
    mcdAlmacenNoUnico,
    mcdColorNoUnico);

  // Estado de la celda enfocada que necesitan las reglas. Lo rellena el
  // llamante leyendo su grid; aqui no se sabe de donde viene.
  TEstadoCeldaStock = record
    CodigoArticulo: string;
    EsModoTodo: Boolean;
    EsModoColor: Boolean;
    EstadoEsExistencias: Boolean;  // estado del combo (modo normal)
    FilaEsExistencias: Boolean;    // ESTADO_NUM de la fila (modo todo)
    HayFila: Boolean;
    HayColumnaDeDatos: Boolean;
    HayColumnaGrupo: Boolean;
    NombreCampo: string;
    Tallas: TArray<string>;        // codigos de las columnas T0..Tn
    Grupo: string;                 // valor de la columna GRUPO
    AlmacenesSeleccionados: TArray<string>;
    ColoresSeleccionados: TArray<string>;
    HayColoresEnLista: Boolean;
  end;

  // Resultado de las reglas: o un motivo de bloqueo o la celda resuelta.
  TCeldaDocumentoResuelta = record
    Motivo: TMotivoCeldaDocumento;
    Talla: string;
    Almacen: string;
    Color: string;
  end;

  // Linea que hay que enviar al documento de trabajo. El llamante la
  // copia a TDocTrabajoLineaOrigen; aqui no se depende de esa unidad
  // para que las pruebas no arrastren UniDAC.
  TLineaCeldaStock = record
    CodigoArticulo: string;
    CodigoSku: string;
    CodigoAlmacen: string;
    DescripcionSku: string;
    Origen: string;
    CantidadStock: Double;
    Cantidad: Double;
  end;

// Aplica las guardas y resuelve talla, almacen y color de la celda.
// La talla sale de la columna T<n> (indice sobre Tallas) o de TOTAL
// cuando el articulo no tiene desglose; el almacen y el color, del
// grupo de la fila y de la seleccion segun el modo del pivote.
function ResolverCeldaStockParaDocumento(
  const AEstado: TEstadoCeldaStock): TCeldaDocumentoResuelta;

// Compone la linea del documento. La cantidad nula de un LEFT JOIN sin
// stock viaja como cero; la descripcion del SKU solo se rellena si hay
// color o talla.
function ComponerLineaCeldaStock(
  const ACodigoArticulo, ACodigoAlmacen, ACodigoSku: string;
  const AColor, ATalla: string;
  ACantidad: Double;
  ACantidadNula: Boolean): TLineaCeldaStock;

implementation

uses
  System.SysUtils, System.StrUtils;

function ResolverCeldaStockParaDocumento(
  const AEstado: TEstadoCeldaStock): TCeldaDocumentoResuelta;
var
  iTalla: Integer;
begin
  Result := Default(TCeldaDocumentoResuelta);
  Result.Motivo := mcdNinguno;
  // Guardas, en el mismo orden que el flujo original del formulario.
  if Trim(AEstado.CodigoArticulo) = '' then
    Result.Motivo := mcdSinArticulo;
  if (Result.Motivo = mcdNinguno) and (not AEstado.EsModoTodo) and
     (not AEstado.EstadoEsExistencias) then
    Result.Motivo := mcdEstadoNoExistencias;
  if (Result.Motivo = mcdNinguno) and (not AEstado.HayFila) then
    Result.Motivo := mcdSinFila;
  if (Result.Motivo = mcdNinguno) and
     (not AEstado.HayColumnaDeDatos) then
    Result.Motivo := mcdSinColumnaCantidad;
  // En modo "Todo a la vez" solo valen las filas de existencias.
  if (Result.Motivo = mcdNinguno) and AEstado.EsModoTodo and
     (not AEstado.FilaEsExistencias) then
    Result.Motivo := mcdFilaNoExistencias;
  if Result.Motivo = mcdNinguno then
  begin
    // Columna de talla T<n> (indice sobre Tallas) o TOTAL cuando el
    // articulo no tiene desglose por tallas.
    if StartsText('T', AEstado.NombreCampo) and
       TryStrToInt(Copy(AEstado.NombreCampo, 2, MaxInt), iTalla) and
       (iTalla >= 0) and (iTalla <= High(AEstado.Tallas)) then
      Result.Talla := AEstado.Tallas[iTalla]
    else if SameText(AEstado.NombreCampo, 'TOTAL') and
            (Length(AEstado.Tallas) = 0) then
      Result.Talla := ''
    else
      Result.Motivo := mcdColumnaNoValida;
  end;
  if (Result.Motivo = mcdNinguno) and
     (not AEstado.HayColumnaGrupo) then
    Result.Motivo := mcdGrupoNoLeido;
  if Result.Motivo = mcdNinguno then
  begin
    if AEstado.EsModoColor then
    begin
      // Filas por color: el almacen tiene que ser unico.
      Result.Color := AEstado.Grupo;
      if Length(AEstado.AlmacenesSeleccionados) = 1 then
        Result.Almacen := AEstado.AlmacenesSeleccionados[0]
      else
        Result.Motivo := mcdAlmacenNoUnico;
    end
    else
    begin
      // Filas por almacen: el color tiene que ser unico, salvo que el
      // articulo no tenga colores en absoluto.
      Result.Almacen := AEstado.Grupo;
      if Length(AEstado.ColoresSeleccionados) = 1 then
        Result.Color := AEstado.ColoresSeleccionados[0]
      else if (Length(AEstado.ColoresSeleccionados) = 0) and
              (not AEstado.HayColoresEnLista) then
        Result.Color := ''
      else
        Result.Motivo := mcdColorNoUnico;
    end;
  end;
end;

function ComponerLineaCeldaStock(
  const ACodigoArticulo, ACodigoAlmacen, ACodigoSku: string;
  const AColor, ATalla: string;
  ACantidad: Double;
  ACantidadNula: Boolean): TLineaCeldaStock;
begin
  Result := Default(TLineaCeldaStock);
  // Celda de un LEFT JOIN sin stock: NULL viaja como cero.
  if ACantidadNula then
    Result.CantidadStock := 0
  else
    Result.CantidadStock := ACantidad;
  Result.CodigoArticulo := ACodigoArticulo;
  Result.CodigoAlmacen := ACodigoAlmacen;
  Result.CodigoSku := ACodigoSku;
  Result.Cantidad := Result.CantidadStock;
  Result.Origen := 'CTRL_U';
  if Trim(AColor + ATalla) <> '' then
    Result.DescripcionSku := Trim(AColor + ' ' + ATalla);
end;

end.
