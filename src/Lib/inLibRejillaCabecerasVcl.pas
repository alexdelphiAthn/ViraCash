{******************************************************************************}
{                                                                              }
{  Módulo:       inLibRejillaCabecerasVcl                                      }
{    Tipo:       Librería (VCL)                                                }
{ Versión:       1.0.0                                                         }
{   Fecha:       10/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    El título de cada columna de una rejilla se alinea como su contenido:     }
{    DevExpress deja los títulos a la izquierda aunque el editor de la         }
{    columna (numérico, casilla...) alinee las celdas de otra forma.           }
{    La pasada recorre solo las rejillas que se están viendo, así que sirve    }
{    para el reposo de la aplicación y alcanza también a las columnas que se   }
{    crean en código o cambian de editor después de abrir la pantalla.         }
{    Las celdas pintadas a mano (OnCustomDrawCell) quedan fuera: ahí el título }
{    lo alinea la propia pantalla con HeaderAlignmentHorz.                     }
{******************************************************************************}
unit inLibRejillaCabecerasVcl;

interface

uses
  System.Classes, cxGridTableView;

// Alineación horizontal con la que la columna pinta sus celdas.
function AlineacionContenidoColumna(AColumna: TcxGridColumn): TAlignment;
// Iguala el título de las columnas visibles de AVista con su contenido.
procedure AlinearCabecerasVista(AVista: TcxGridTableView);
// Lo mismo en todas las rejillas que se están viendo en la aplicación.
procedure AlinearCabecerasRejillasVisibles;

implementation

uses
  Vcl.Controls, Vcl.Forms, cxEdit, cxCheckBox, cxGrid, cxGridCustomView;

function AlineacionContenidoColumna(AColumna: TcxGridColumn): TAlignment;
var
  oPropiedades: TcxCustomEditProperties;
begin
  Result := taLeftJustify;
  oPropiedades := AColumna.GetProperties;
  if oPropiedades is TcxCustomCheckBoxProperties then
  begin
    // Dentro de una celda la casilla va centrada salvo que se pida lo
    // contrario.
    if TcxCustomCheckBoxProperties(oPropiedades).UseAlignmentWhenInplace then
      Result := TcxCustomCheckBoxProperties(oPropiedades).Alignment
    else
      Result := taCenter;
  end
  else if Assigned(oPropiedades) then
    Result := oPropiedades.Alignment.Horz;
end;

// Una columna que pinta sus celdas a mano no dice cómo las alinea: su
// título se queda como lo dejó la pantalla. Lo mismo si es la vista la
// que pinta a mano y la pantalla ya eligió una alineación para el título.
function TituloDecididoPorLaPantalla(AVista: TcxGridTableView;
  AColumna: TcxGridColumn): Boolean;
begin
  Result := Assigned(AColumna.OnCustomDrawCell) or
    (Assigned(AVista.OnCustomDrawCell) and
     (AColumna.HeaderAlignmentHorz <> taLeftJustify));
end;

procedure AlinearCabecerasVista(AVista: TcxGridTableView);
var
  iColumna: Integer;
  oColumna: TcxGridColumn;
  eAlineacion: TAlignment;
begin
  if Assigned(AVista) and (not AVista.IsDestroying) and
     (not AVista.IsLoading) then
  begin
    for iColumna := 0 to AVista.ColumnCount - 1 do
    begin
      oColumna := AVista.Columns[iColumna];
      if oColumna.Visible and
         (not TituloDecididoPorLaPantalla(AVista, oColumna)) then
      begin
        eAlineacion := AlineacionContenidoColumna(oColumna);
        if oColumna.HeaderAlignmentHorz <> eAlineacion then
          oColumna.HeaderAlignmentHorz := eAlineacion;
      end;
    end;
  end;
end;

procedure AlinearCabecerasRejilla(ARejilla: TcxCustomGrid);
var
  iVista: Integer;
begin
  for iVista := 0 to ARejilla.ViewCount - 1 do
  begin
    if ARejilla.Views[iVista] is TcxGridTableView then
      AlinearCabecerasVista(TcxGridTableView(ARejilla.Views[iVista]));
  end;
end;

// Solo baja por lo que se está viendo: las pestañas ocultas y las
// pantallas embebidas que no están delante no se recorren.
procedure AlinearCabecerasControl(AControl: TWinControl);
var
  iControl: Integer;
  oHijo: TControl;
begin
  for iControl := 0 to AControl.ControlCount - 1 do
  begin
    oHijo := AControl.Controls[iControl];
    if (oHijo is TWinControl) and TWinControl(oHijo).Showing then
    begin
      if oHijo is TcxCustomGrid then
        AlinearCabecerasRejilla(TcxCustomGrid(oHijo))
      else
        AlinearCabecerasControl(TWinControl(oHijo));
    end;
  end;
end;

procedure AlinearCabecerasRejillasVisibles;
var
  iFormulario: Integer;
  oFormulario: TCustomForm;
begin
  for iFormulario := 0 to Screen.CustomFormCount - 1 do
  begin
    oFormulario := Screen.CustomForms[iFormulario];
    // Las pantallas embebidas se alcanzan desde su ventana contenedora.
    if (oFormulario.Parent = nil) and oFormulario.Showing and
       (not (csDestroying in oFormulario.ComponentState)) then
      AlinearCabecerasControl(oFormulario);
  end;
end;

end.
