{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaFotosOperacionGridVcl                                }
{    Tipo:       Presentador VCL                                               }
{ Versión:       1.0.0                                                         }
{   Fecha:       18/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Columna "Fotos" para una rejilla de operaciones de caja: la tira de       }
{    miniaturas de los artículos de cada operación (venta, devolución y        }
{    traspaso, depósito o préstamo, y líneas del borrador).                    }
{    La usan Buscar operaciones y el histórico de operaciones de caja, y       }
{    sirve para cualquier otra rejilla cuyas filas sean operaciones.           }
{******************************************************************************}
unit inLibCajaFotosOperacionGridVcl;

interface

uses
  cxGridCustomTableView, cxGridDBTableView,
  inLibCajaArticulosOperacionIntf, inLibFotos,
  inLibFotosMiniaturasGridVcl;

type
  // Empresa, almacén y caja de la pantalla, para las rejillas que no los
  // traen como columnas (Buscar operaciones trabaja con una caja fija).
  // Se pregunta al pintar, no al montar la columna: el contexto puede
  // llegar después, y lo que traiga la fila manda sobre él.
  TContextoOperacionFotos = reference to function: TClaveOperacionCaja;

// Añade la columna al final de AVista y devuelve la tira, que es de quien
// la llama: al liberarla suelta los eventos y las cachés.
function CrearColumnaFotosOperacionCaja(
  AVista: TcxGridDBTableView;
  AFotos: TFotosArticulos;
  AArticulos: IConsultaArticulosOperacionCaja;
  const ANombreColumna, ATituloColumna: string;
  AContexto: TContextoOperacionFotos = nil): TTiraMiniaturasFotosGrid;

implementation

uses
  System.SysUtils, System.Variants;

// Valor de un campo en la fila, o vacío si la rejilla no tiene esa
// columna: no todas las pantallas muestran las cuatro claves.
function ValorDeFila(AVista: TcxGridDBTableView;
  ARegistro: TcxCustomGridRecord; const ACampo: string): string;
var
  oColumna: TcxGridDBColumn;
begin
  Result := '';
  oColumna := AVista.GetColumnByFieldName(ACampo);
  if Assigned(oColumna) then
    Result := Trim(VarToStr(ARegistro.Values[oColumna.Index]));
end;

// Clave de la operación de la fila. Devuelve la clave de caché de fotos,
// o cadena vacía si la fila no identifica una operación. No consulta
// nada: la tira la usa para mirar su caché antes de pedir los artículos.
function ClaveDeFila(AVista: TcxGridDBTableView;
  ARegistro: TcxCustomGridRecord;
  AContexto: TContextoOperacionFotos;
  out AOperacion: TClaveOperacionCaja): string;

  procedure DeLaFila(const ACampo: string; var ADestino: string);
  var
    sValor: string;
  begin
    sValor := ValorDeFila(AVista, ARegistro, ACampo);
    if sValor <> '' then
      ADestino := sValor;
  end;

begin
  Result := '';
  if Assigned(AContexto) then
    AOperacion := AContexto()
  else
    AOperacion := Default(TClaveOperacionCaja);
  if Assigned(ARegistro) then
  begin
    // Lo que traiga la rejilla manda sobre el contexto de la pantalla.
    DeLaFila('CODIGO_EMP_OPCAJA', AOperacion.Empresa);
    DeLaFila('CODIGO_ALM_OPCAJA', AOperacion.Almacen);
    DeLaFila('CODIGO_CAJA_OPCAJA', AOperacion.Caja);
    DeLaFila('NUMERO_OPERACION_OPCAJA', AOperacion.Operacion);
    DeLaFila('SERIE_FAC', AOperacion.SerieFactura);
    DeLaFila('NUMERO_FAC', AOperacion.NumeroFactura);
    if (AOperacion.Empresa <> '') and (AOperacion.Operacion <> '') then
      Result := AOperacion.Empresa + '|' + AOperacion.Almacen + '|' +
        AOperacion.Caja + '|' + AOperacion.Operacion;
  end;
end;

function CrearColumnaFotosOperacionCaja(
  AVista: TcxGridDBTableView;
  AFotos: TFotosArticulos;
  AArticulos: IConsultaArticulosOperacionCaja;
  const ANombreColumna, ATituloColumna: string;
  AContexto: TContextoOperacionFotos): TTiraMiniaturasFotosGrid;
begin
  Result := TTiraMiniaturasFotosGrid.Create(
    AVista,
    AFotos,
    ANombreColumna,
    ATituloColumna,
    // Artículos de la fila: solo llega aquí la que no está en la caché
    // de la tira, o sea una consulta por operación, no por repintado.
    function(ARegistro: TcxCustomGridRecord;
      out AClave: string): TArticulosFotoFila
    var
      // Ojo con el nombre: Delphi no distingue mayusculas, asi que una
      // local "aArticulos" taparia el parametro AArticulos.
      aLista: TArticulosOperacionCaja;
      oOperacion: TClaveOperacionCaja;
      iArticulo: Integer;
    begin
      SetLength(Result, 0);
      AClave := ClaveDeFila(AVista, ARegistro, AContexto, oOperacion);
      if (AClave <> '') and Assigned(AArticulos) then
      begin
        aLista := AArticulos.ListarArticulosOperacion(
          oOperacion, cMaximoFotosPorFila);
        SetLength(Result, Length(aLista));
        for iArticulo := 0 to High(aLista) do
          Result[iArticulo] := TArticuloFotoFila.Crear(
            aLista[iArticulo].Articulo,
            aLista[iArticulo].Sku);
      end;
    end,
    function(ARegistro: TcxCustomGridRecord): string
    var
      oOperacion: TClaveOperacionCaja;
    begin
      Result := ClaveDeFila(AVista, ARegistro, AContexto, oOperacion);
    end);
end;

end.
