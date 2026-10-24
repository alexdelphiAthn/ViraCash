{******************************************************************************}
{                                                                              }
{  Módulo:       inLibReagpVcl                                                 }
{    Tipo:       Librería (VCL)                                                }
{ Versión:       1.0.0                                                         }
{   Fecha:       10/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Régimen especial de agricultura, ganadería y pesca (REAGP). Con el        }
{    parámetro appUsarReagp apagado, las pantallas no enseñan nada del         }
{    régimen: casillas de la ficha y columnas de las rejillas ligadas a sus    }
{    campos (régimen agrícola de empresa y cliente, IVA agrícola, IRPF con     }
{    impuestos incluidos y activo fijo). Solo se oculta: los datos y los       }
{    cálculos no cambian.                                                      }
{******************************************************************************}
unit inLibReagpVcl;

interface

uses
  System.Classes, inLibParametrosIntf;

const
  PARAMETRO_USAR_REAGP = 'appUsarReagp';

// True si la instalación trabaja con el REAGP.
function ReagpEnUso(const AParametros: IParametrosAplicacion): Boolean;
// True si el campo solo tiene sentido con el REAGP.
function EsCampoReagp(const ACampo: string): Boolean;
// Oculta las casillas y columnas de AFormulario ligadas a campos del REAGP
// y las quita del selector de columnas.
procedure OcultarControlesReagp(AFormulario: TComponent);

implementation

uses
  System.SysUtils, cxEdit, cxDBEdit, cxGridCustomTableView,
  cxGridTableView, cxGridDBDataDefinitions;

type
  TcxCustomEditAcceso = class(TcxCustomEdit);

const
  FRAGMENTOS_CAMPO_REAGP: array[0..3] of string = (
    'REGIMENESPECIALAGRICOLA', 'IVAAGRICOLA', 'IRPF_IMP_INCL',
    'ACTIVO_FIJO');

function ReagpEnUso(const AParametros: IParametrosAplicacion): Boolean;
begin
  // Sin parámetros (pruebas, pantallas sueltas) no se oculta nada.
  Result := (not Assigned(AParametros)) or
    AParametros.GetBool(PARAMETRO_USAR_REAGP, False);
end;

function EsCampoReagp(const ACampo: string): Boolean;
var
  sFragmento: string;
  sCampo: string;
begin
  Result := False;
  sCampo := UpperCase(ACampo);
  for sFragmento in FRAGMENTOS_CAMPO_REAGP do
  begin
    if Pos(sFragmento, sCampo) > 0 then
      Result := True;
  end;
end;

function CampoDeEditor(AEditor: TcxCustomEdit): string;
var
  oEnlace: TcxEditDataBinding;
begin
  Result := '';
  oEnlace := TcxCustomEditAcceso(AEditor).DataBinding;
  if oEnlace is TcxDBEditDataBinding then
    Result := TcxDBEditDataBinding(oEnlace).DataField;
end;

function CampoDeColumna(AColumna: TcxCustomGridTableItem): string;
begin
  Result := '';
  if AColumna.DataBinding is TcxGridItemDBDataBinding then
    Result := TcxGridItemDBDataBinding(AColumna.DataBinding).FieldName;
end;

procedure OcultarControlesReagp(AFormulario: TComponent);
var
  iComponente: Integer;
  oComponente: TComponent;
begin
  if Assigned(AFormulario) then
  begin
    for iComponente := 0 to AFormulario.ComponentCount - 1 do
    begin
      oComponente := AFormulario.Components[iComponente];
      if oComponente is TcxGridColumn then
      begin
        if EsCampoReagp(CampoDeColumna(TcxGridColumn(oComponente))) then
        begin
          TcxGridColumn(oComponente).Visible := False;
          TcxGridColumn(oComponente).VisibleForCustomization := False;
        end;
      end
      else if oComponente is TcxCustomEdit then
      begin
        if EsCampoReagp(CampoDeEditor(TcxCustomEdit(oComponente))) then
          TcxCustomEdit(oComponente).Visible := False;
      end;
    end;
  end;
end;

end.
