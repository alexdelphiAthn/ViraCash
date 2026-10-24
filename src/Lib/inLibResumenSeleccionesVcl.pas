{******************************************************************************}
{                                                                              }
{  Módulo:       inLibResumenSeleccionesVcl                                    }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Ayudantes para describir en el resumen de selecciones los controles       }
{    DevExpress de los modales de impresión. Los controles deshabilitados no   }
{    se describen: no intervienen en la consulta.                              }
{******************************************************************************}
unit inLibResumenSeleccionesVcl;

interface

uses
  System.Classes, cxRadioGroup, cxCheckBox, cxCheckListBox,
  inLibResumenSeleccionesInforme;

procedure AnadirOpcionRadio(
  AResumen: TResumenSeleccionesInforme;
  ARadio: TcxRadioGroup);
procedure AnadirCasilla(
  AResumen: TResumenSeleccionesInforme;
  ACasilla: TcxCheckBox);
procedure CopiarTextosMarcados(
  ALista: TcxCheckListBox;
  ADestino: TStrings);
// Ninguno marcado = sin filtro: se describe con ATextoTodos (Todos si no
// se indica). Todos marcados solo se resume así cuando la consulta lo
// trata igual (ATodosEsSinFiltro); si no, se listan.
procedure AnadirMarcados(
  AResumen: TResumenSeleccionesInforme;
  const AEtiqueta: string;
  ALista: TcxCheckListBox;
  const ATextoTodos: string = '';
  ATodosEsSinFiltro: Boolean = False);

implementation

uses
  System.SysUtils, Vcl.Menus, cxLookAndFeelPainters;

procedure AnadirOpcionRadio(
  AResumen: TResumenSeleccionesInforme;
  ARadio: TcxRadioGroup);
begin
  if (ARadio <> nil) and ARadio.Enabled and (ARadio.ItemIndex >= 0) then
    AResumen.Anadir(
      StripHotkey(ARadio.Caption),
      StripHotkey(ARadio.Properties.Items[ARadio.ItemIndex].Caption));
end;

procedure AnadirCasilla(
  AResumen: TResumenSeleccionesInforme;
  ACasilla: TcxCheckBox);
begin
  if (ACasilla <> nil) and ACasilla.Enabled then
    AResumen.AnadirSiNo(StripHotkey(ACasilla.Caption), ACasilla.Checked);
end;

procedure CopiarTextosMarcados(
  ALista: TcxCheckListBox;
  ADestino: TStrings);
var
  i: Integer;
begin
  ADestino.Clear;
  if ALista <> nil then
    for i := 0 to ALista.Items.Count - 1 do
      if ALista.Items[i].State = cbsChecked then
        ADestino.Add(ALista.Items[i].Text);
end;

procedure AnadirMarcados(
  AResumen: TResumenSeleccionesInforme;
  const AEtiqueta: string;
  ALista: TcxCheckListBox;
  const ATextoTodos: string;
  ATodosEsSinFiltro: Boolean);
var
  oMarcados: TStringList;
begin
  oMarcados := TStringList.Create;
  try
    CopiarTextosMarcados(ALista, oMarcados);
    if ATodosEsSinFiltro and (ALista <> nil) and
       (oMarcados.Count = ALista.Items.Count) then
      oMarcados.Clear;
    AResumen.AnadirLista(AEtiqueta, oMarcados, ATextoTodos);
  finally
    FreeAndNil(oMarcados);
  end;
end;

end.
