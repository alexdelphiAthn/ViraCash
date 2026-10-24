{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMenuColumnasRejillaVcl                                   }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       17/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Menú del botón derecho de una rejilla de detalle con sus columnas         }
{    marcadas según estén visibles; pulsar una la muestra u oculta.            }
{******************************************************************************}
unit inLibMenuColumnasRejillaVcl;

interface

uses
  System.Classes, Vcl.Menus, cxGrid, cxGridTableView;

type
  // Mismo comportamiento que el menú de columnas de la lista principal
  // (TGestorGuiasGridMto), sin guías. Solo ofrece las columnas con
  // VisibleForCustomization: las automáticas o sin sentido para el usuario
  // se ocultan del menú en el DFM. Lo elegido se conserva al grabar el
  // diseño de las rejillas. El propietario libera el menú.
  TMenuColumnasRejilla = class(TComponent)
  private
    FVista: TcxGridTableView;
    FMenu: TPopupMenu;
    procedure MenuPopup(ASender: TObject);
    procedure ColumnaClick(ASender: TObject);
  public
    constructor Create(
      AOwner: TComponent;
      AGrid: TcxGrid;
      AVista: TcxGridTableView); reintroduce;
  end;

implementation

uses
  System.SysUtils;

constructor TMenuColumnasRejilla.Create(
  AOwner: TComponent;
  AGrid: TcxGrid;
  AVista: TcxGridTableView);
begin
  inherited Create(AOwner);
  if not Assigned(AGrid) then
    raise EArgumentNilException.Create('AGrid');
  if not Assigned(AVista) then
    raise EArgumentNilException.Create('AVista');
  FVista := AVista;
  FMenu := TPopupMenu.Create(Self);
  // Sin aceleradores automáticos: el menú muestra los títulos tal cual.
  FMenu.AutoHotkeys := maManual;
  FMenu.OnPopup := MenuPopup;
  AGrid.PopupMenu := FMenu;
end;

procedure TMenuColumnasRejilla.MenuPopup(ASender: TObject);
var
  iColumna: Integer;
  oColumna: TcxGridColumn;
  oOpcion: TMenuItem;
begin
  FMenu.Items.Clear;
  for iColumna := 0 to FVista.ColumnCount - 1 do
  begin
    oColumna := FVista.Columns[iColumna];
    if oColumna.VisibleForCustomization then
    begin
      oOpcion := TMenuItem.Create(FMenu);
      oOpcion.Caption := StringReplace(
        oColumna.GetAlternateCaption, '&', '&&', [rfReplaceAll]);
      oOpcion.Checked := oColumna.Visible;
      // La última columna visible no se oculta: la rejilla se quedaría
      // en blanco.
      oOpcion.Enabled :=
        not (oColumna.Visible and (FVista.VisibleItemCount = 1));
      oOpcion.Tag := oColumna.Index;
      oOpcion.OnClick := ColumnaClick;
      FMenu.Items.Add(oOpcion);
    end;
  end;
end;

procedure TMenuColumnasRejilla.ColumnaClick(ASender: TObject);
var
  oColumna: TcxGridColumn;
begin
  oColumna := FVista.Columns[(ASender as TMenuItem).Tag];
  oColumna.Visible := not oColumna.Visible;
  if oColumna.Visible then
    FVista.Controller.MakeItemVisible(oColumna);
end;

end.
