{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpRecFac                                           }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de impresion de recibos de facturas.                                }
{    Soporta seleccion por factura actual o por rango de fechas.               }
{******************************************************************************}
unit inMtoModalImpRecFac;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoModalGenImp, cxGraphics,
  cxLookAndFeels, cxLookAndFeelPainters, Vcl.Menus, frxDesgn, Data.DB, MemDS,
  DBAccess, Uni, frxExportXLSX, frxClass, frxExportBaseDialog, frxExportPDF,
  Vcl.StdCtrls, cxButtons, Vcl.ExtCtrls, cxControls, cxContainer, cxEdit,
  Vcl.ComCtrls, dxCore, cxDateUtils, cxMaskEdit, cxDropDownEdit, cxCalendar,
  cxRadioGroup, cxGroupBox, cxTextEdit, cxLabel, UniDataFacturas,
  cxStyles, dxSkinsForm, cxClasses, cxLocalization, JvComponentBase, JvEnterTab,
  System.Actions, Vcl.ActnList, frxSmartMemo, frLocalization, frLanguageSpanish,
  frxExportBaseImageSettingsDialog, frCoreClasses,
  inLibInformeRecibosFacturaPersistenciaIntf;

type
  TfrmPrintRecFac = class(TfrmPrint)
    lblcxlbl1: TcxLabel;
    edtSerie: TcxTextEdit;
    edtNroFac: TcxTextEdit;
    cxrdgrp1: TcxRadioGroup;
    rbActual: TcxRadioButton;
    rbRangoFechas: TcxRadioButton;
    edtPlazoRecFac: TcxTextEdit;
    procedure rbActualClick(Sender: TObject);
    procedure rbRangoFechasClick(Sender: TObject);
  private
    FPreparadorInforme: IPreparadorInformeRecibosFactura;
    FEsEfectosVenta: Boolean;
    FEfectos: string;
  protected
    procedure PrepararDatosEdicion; override;
  public
    procedure preparar_consulta; override;
    procedure AfterReportLoaded; override;
    // FZ-ISSUE-102.14: recibos de efectos de cobro de venta mayor.
    // AEfectos = CSV de NUMERO_EFV seleccionados (opción «actual»).
    procedure PrepararEfectosVenta(const AEfectos: string);
    { Private declarations }
  public
    dmFac: TdmFacturas;
    { Public declarations }
  end;

implementation

uses
  UniDataInformeRecibosFacturaRepositorio, inLibMsgFacturas,
  inLibInformeDocumento;

{$R *.dfm}

{ TfrmPrintRecFac }

procedure TfrmPrintRecFac.AfterReportLoaded;
var
  Banda: TfrxComponent;
begin
  inherited;
  if dmFac <> nil then
    RebindReportDataSetsByDataModule(frxrprt1, dmFac);
  AjustarRotulosReciboFactura(frxrprt1);
  // Efectos: un recibo por página (el diseño admite varios por hoja).
  Banda := frxrprt1.FindObject('MasterData1');
  if FEsEfectosVenta and (Banda is TfrxDataBand) then
    TfrxDataBand(Banda).StartNewPage := True;
end;

procedure TfrmPrintRecFac.PrepararEfectosVenta(const AEfectos: string);
begin
  FEsEfectosVenta := True;
  FEfectos := AEfectos;
  lblcxlbl1.Caption := SCaptionEfectoReciboEfectos;
  edtPlazoRecFac.Text := AEfectos;
  rbActual.Caption := SCaptionEfectosSeleccionadosReciboEfectos;
  rbRangoFechas.Caption := SCaptionTodosEfectosReciboEfectos;
end;

procedure TfrmPrintRecFac.PrepararDatosEdicion;
begin
  preparar_consulta;
end;

procedure TfrmPrintRecFac.preparar_consulta;
var
  criterios: TCriteriosInformeRecibosFactura;
begin
  criterios.ReciboActual := rbActual.Checked;
  criterios.Serie := edtSerie.Text;
  criterios.NumeroFactura := edtNroFac.Text;
  criterios.NumeroRecibo := edtPlazoRecFac.Text;
  criterios.EsEfectosVenta := FEsEfectosVenta;
  criterios.Efectos := FEfectos;
  if FPreparadorInforme = nil then
    FPreparadorInforme := CrearPreparadorInformeRecibosFacturaUniDAC(
      dmFac.unqryRecibosPrint);
  FPreparadorInforme.Preparar(criterios);
  dmFac.fxdsRecibos.UpdateBounds;
end;

procedure TfrmPrintRecFac.rbActualClick(Sender: TObject);
begin
   inherited;
//   dedDesde.Enabled := false;
//   dedHasta.Enabled := false;
end;

procedure TfrmPrintRecFac.rbRangoFechasClick(Sender: TObject);
begin
  inherited;
  //dedDesde.Enabled := true;
  //dedHasta.Enabled := true;
end;

end.
