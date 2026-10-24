{******************************************************************************}
{                                                                              }
{  Módulo:       inLibColaEnviarYaVcl                                          }
{    Tipo:       Librería (VCL)                                                }
{ Versión:       1.0.0                                                         }
{   Fecha:       07/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Botón «Enviar ya» de las pantallas de cola (FZ-ISSUE-310): recoge las     }
{    filas del grid, pide confirmación, reactiva, despierta al hilo de la      }
{    cola y refresca. Común a VERI*FACTU/SII, PrestaShop y ventas WS.          }
{******************************************************************************}
unit inLibColaEnviarYaVcl;

interface

uses
  System.SysUtils, cxGridDBTableView, inLibColaEnviarYa, inLibLogIntf;

type
  // Reactiva los identificadores y devuelve cuántas filas cambiaron
  TEjecutarEnviarYa = reference to function(
    const AIds: TArray<Int64>): Integer;

// Filas sobre las que actúa: las seleccionadas si hay más de una; si no,
// todas las que muestra la vista (con su filtro).
function FilasColaEnviarYa(AVista: TcxGridDBTableView;
  const ACampoId, ACampoEstado: string): TArray<TFilaColaEnviarYa>;
// Devuelve las filas reactivadas (0 si no había ninguna o se canceló)
function EnviarYaColaDesdeVista(AVista: TcxGridDBTableView;
  const ADefinicion: TDefinicionColaEnviarYa; const ANombreCola: string;
  const AEjecutar: TEjecutarEnviarYa; const ADespertarHilo: TProc;
  const ARefrescar: TProc; const ARegistroLog: IRegistroLog): Integer;

implementation

uses
  System.UITypes, System.Variants, Data.DB, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, cxGridTableView, inLibMensajesVcl, inLibMsgIntegraciones;

function ValorTexto(const AValor: Variant): string;
begin
  if VarIsNull(AValor) or VarIsEmpty(AValor) then
    Result := ''
  else
    Result := VarToStr(AValor);
end;

function ValorId(const AValor: Variant): Int64;
begin
  Result := StrToInt64Def(ValorTexto(AValor), 0);
end;

function FilasColaEnviarYa(AVista: TcxGridDBTableView;
  const ACampoId, ACampoEstado: string): TArray<TFilaColaEnviarYa>;
var
  oColumnaId: TcxGridDBColumn;
  oColumnaEstado: TcxGridDBColumn;
  iFila: Integer;
  iRegistro: Integer;
begin
  SetLength(Result, 0);
  oColumnaId := AVista.GetColumnByFieldName(ACampoId);
  oColumnaEstado := AVista.GetColumnByFieldName(ACampoEstado);
  if (oColumnaId <> nil) and (oColumnaEstado <> nil) then
  begin
    if AVista.Controller.SelectedRecordCount > 1 then
    begin
      SetLength(Result, AVista.Controller.SelectedRecordCount);
      for iFila := 0 to AVista.Controller.SelectedRecordCount - 1 do
      begin
        Result[iFila].Id := ValorId(
          AVista.Controller.SelectedRecords[iFila].Values[oColumnaId.Index]);
        Result[iFila].Estado := ValorTexto(
          AVista.Controller.SelectedRecords[iFila].Values[
            oColumnaEstado.Index]);
      end;
    end
    else
    begin
      SetLength(Result, AVista.DataController.FilteredRecordCount);
      for iFila := 0 to AVista.DataController.FilteredRecordCount - 1 do
      begin
        iRegistro := AVista.DataController.FilteredRecordIndex[iFila];
        Result[iFila].Id := ValorId(
          AVista.DataController.Values[iRegistro, oColumnaId.Index]);
        Result[iFila].Estado := ValorTexto(
          AVista.DataController.Values[iRegistro, oColumnaEstado.Index]);
      end;
    end;
  end;
end;

function EnviarYaColaDesdeVista(AVista: TcxGridDBTableView;
  const ADefinicion: TDefinicionColaEnviarYa; const ANombreCola: string;
  const AEjecutar: TEjecutarEnviarYa; const ADespertarHilo: TProc;
  const ARefrescar: TProc; const ARegistroLog: IRegistroLog): Integer;
var
  aIds: TArray<Int64>;
  oCursorAnterior: TCursor;
  oDataSet: TDataSet;
begin
  Result := 0;
  oDataSet := AVista.DataController.DataSet;
  if (oDataSet <> nil) and (oDataSet.State in dsEditModes) then
    oDataSet.Post;
  aIds := IdsEnviarYa(ADefinicion, FilasColaEnviarYa(AVista,
    ADefinicion.CampoId, ADefinicion.CampoEstado));
  if Length(aIds) = 0 then
    ShowMessage_fza(SInfoEnviarYaColaSinFilas)
  else if MessageDlg_fza(Format(SConfirmarEnviarYaCola, [Length(aIds)]),
            mtConfirmation, [mbYes, mbNo], 0, mbYes) = mrYes then
  begin
    oCursorAnterior := Screen.Cursor;
    Screen.Cursor := crHourGlass;
    try
      Result := AEjecutar(aIds);
      if Assigned(ARegistroLog) then
        ARegistroLog.RegistrarInformacion(Format(
          'Cola %s: Enviar ya sobre %d filas, %d reactivadas',
          [ANombreCola, Length(aIds), Result]));
      // El hilo procesa lo que haya en la tabla: se le despierta aunque
      // otro puesto se hubiera adelantado con alguna fila
      if Assigned(ADespertarHilo) then
        ADespertarHilo();
      if Assigned(ARefrescar) then
        ARefrescar();
    finally
      Screen.Cursor := oCursorAnterior;
    end;
  end;
end;

end.
