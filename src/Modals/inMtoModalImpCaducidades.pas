{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpCaducidades                                      }
{    Tipo:       Formulario modal (impresión)                                  }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Informe «Lotes y caducidades» (F-LOTEC-022): el stock por lote, serie o   }
{    temporada de la pantalla «Lotes y caducidades» con sus mismos filtros,    }
{    agrupado por almacén y ordenado por familia y caducidad. A4 horizontal.   }
{******************************************************************************}
unit inMtoModalImpCaducidades;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  inMtoModalGenImp, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters,
  Vcl.Menus, frxDesgn, Data.DB,
  frxExportXLSX, frxClass, frxDBSet, frxExportBaseDialog, frxExportPDF,
  Vcl.StdCtrls, cxButtons, Vcl.ExtCtrls, cxControls, cxContainer, cxEdit,
  cxLabel, Vcl.ComCtrls, dxCore, cxStyles, dxSkinsForm, cxClasses,
  cxLocalization, JvComponentBase, JvEnterTab, System.Actions,
  Vcl.ActnList, frxSmartMemo, frLocalization, frLanguageSpanish,
  frxExportBaseImageSettingsDialog, frCoreClasses,
  inLibResumenSeleccionesInforme, UniDataLotesConsultas;

type
  TfrmPrintCaducidades = class(TfrmPrint)
    dsCaducidadesPrint: TDataSource;
    fxdsCaducidades: TfrxDBDataset;
  private
    FDatos: TdmLotesConsultas;
    FFiltros: TFiltrosLotes;
    FSelecciones: TArray<string>;
  protected
    procedure DescribirSelecciones(
      AResumen: TResumenSeleccionesInforme); override;
  public
    // ADatos: el data module de la pantalla (su conexión). ASelecciones:
    // pares «título», «valor» de los filtros aplicados, para el resumen.
    constructor CreateInforme(AOwner: TComponent;
      ADatos: TdmLotesConsultas; const AFiltros: TFiltrosLotes;
      const ASelecciones: TArray<string>);
    procedure preparar_consulta; override;
  end;

implementation

{$R *.dfm}

constructor TfrmPrintCaducidades.CreateInforme(AOwner: TComponent;
  ADatos: TdmLotesConsultas; const AFiltros: TFiltrosLotes;
  const ASelecciones: TArray<string>);
begin
  if not Assigned(ADatos) then
    raise EArgumentNilException.Create('ADatos');
  FDatos := ADatos;
  FFiltros := AFiltros;
  FSelecciones := ASelecciones;
  inherited Create(AOwner);
end;

procedure TfrmPrintCaducidades.preparar_consulta;
begin
  inherited;
  dsCaducidadesPrint.DataSet := nil;
  dsCaducidadesPrint.DataSet := FDatos.AbrirInforme(FFiltros);
  fxdsCaducidades.UpdateBounds;
end;

procedure TfrmPrintCaducidades.DescribirSelecciones(
  AResumen: TResumenSeleccionesInforme);
var
  iSeleccion: Integer;
begin
  inherited;
  iSeleccion := 0;
  while iSeleccion + 1 <= High(FSelecciones) do
  begin
    AResumen.Anadir(FSelecciones[iSeleccion], FSelecciones[iSeleccion + 1]);
    Inc(iSeleccion, 2);
  end;
end;

end.
