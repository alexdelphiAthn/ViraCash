{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoColoresBasicos                                           }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Edición sencilla de colores básicos y su paleta.                          }
{******************************************************************************}
unit inMtoColoresBasicos;

interface

uses
  System.Classes, Data.DB, Vcl.Controls, Vcl.ExtCtrls,
  cxGraphics, cxControls, cxContainer, cxEdit, cxTextEdit,
  cxMaskEdit, cxButtonEdit, cxDBEdit, cxLabel, cxGroupBox,
  cxCheckBox, cxSpinEdit, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, inMtoGen;

type
  TfrmMtoColoresBasicos = class(TfrmMtoGen)
    cxGrdDBTabPrinCODIGO_ATB: TcxGridDBColumn;
    cxGrdDBTabPrinNOMBRE_ATB: TcxGridDBColumn;
    cxGrdDBTabPrinHEX_ATB: TcxGridDBColumn;
    cxGrdDBTabPrinORDEN_ATB: TcxGridDBColumn;
    cxGrdDBTabPrinESACTIVO_ATB: TcxGridDBColumn;
    pnlColor: TcxGroupBox;
    lblCodigo: TcxLabel;
    lblNombre: TcxLabel;
    lblPaleta: TcxLabel;
    lblOrden: TcxLabel;
    lblAyuda: TcxLabel;
    txtCODIGO_ATB: TcxDBTextEdit;
    txtNOMBRE_ATB: TcxDBTextEdit;
    btnHEX_ATB: TcxDBButtonEdit;
    spnORDEN_ATB: TcxDBSpinEdit;
    chkESACTIVO_ATB: TcxDBCheckBox;
    procedure dsTablaGStateChange(Sender: TObject);
    procedure CambiarPaleta(Sender: TObject; AButtonIndex: Integer);
    procedure PintarPaleta(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
  private
    procedure ElegirPaleta;
    procedure RefrescarPaleta(DataSet: TDataSet);
  public
    procedure CrearTablaPrincipal; override;
  end;

implementation

uses
  Winapi.Windows, System.SysUtils, Vcl.Graphics, Vcl.Dialogs,
  inLibRegistroPantallas, inLibAtributosPaleta;

{$R *.dfm}

procedure TfrmMtoColoresBasicos.CrearTablaPrincipal;
begin
  inherited;
  Self.pkFieldName := 'ID_ATB';
  dsTablaG.DataSet.AfterPost := RefrescarPaleta;
  dsTablaG.DataSet.AfterDelete := RefrescarPaleta;
  dsTablaGStateChange(dsTablaG);
end;

procedure TfrmMtoColoresBasicos.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  txtCODIGO_ATB.Properties.ReadOnly := dsTablaG.State <> dsInsert;
  cxGrdDBTabPrinCODIGO_ATB.Options.Editing := dsTablaG.State = dsInsert;
end;

procedure TfrmMtoColoresBasicos.RefrescarPaleta(DataSet: TDataSet);
begin
  InvalidarCachePaleta;
  cxGrdDBTabPrin.Invalidate;
end;

procedure TfrmMtoColoresBasicos.CambiarPaleta(Sender: TObject;
  AButtonIndex: Integer);
begin
  if Assigned(dsTablaG.DataSet) and dsTablaG.DataSet.Active and
     ((dsTablaG.State = dsInsert) or not dsTablaG.DataSet.IsEmpty) then
    ElegirPaleta;
end;

procedure TfrmMtoColoresBasicos.ElegirPaleta;
var
  oDialogo: TColorDialog;
  oCampo: TField;
  iColor: TColor;
begin
  oCampo := dsTablaG.DataSet.FieldByName('HEX_ATB');
  oDialogo := TColorDialog.Create(Self);
  try
    oDialogo.Options := [cdFullOpen, cdAnyColor];
    iColor := HexToColor(oCampo.AsString);
    if iColor = clNone then
      iColor := clWhite;
    oDialogo.Color := iColor;
    if oDialogo.Execute then
    begin
      if not (dsTablaG.State in [dsEdit, dsInsert]) then
        dsTablaG.DataSet.Edit;
      iColor := ColorToRGB(oDialogo.Color);
      oCampo.AsString := Format('#%.2X%.2X%.2X',
        [GetRValue(iColor), GetGValue(iColor), GetBValue(iColor)]);
    end;
  finally
    FreeAndNil(oDialogo);
  end;
end;

procedure TfrmMtoColoresBasicos.PintarPaleta(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  oInfo: TInfoBasico;
begin
  oInfo := Default(TInfoBasico);
  oInfo.HexColor := AViewInfo.GridRecord.DisplayTexts[AViewInfo.Item.Index];
  oInfo.Color := HexToColor(oInfo.HexColor);
  oInfo.EsValido := oInfo.Color <> clNone;
  ADone := PintarCeldaConCuadradoColor(ACanvas, AViewInfo, oInfo);
end;

initialization
  RegistrarPantalla(TfrmMtoColoresBasicos);

end.
