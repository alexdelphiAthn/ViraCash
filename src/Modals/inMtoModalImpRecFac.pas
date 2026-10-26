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
  inLibInformeRecibosFacturaPersistenciaIntf, frxDBSet;

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
    FConsultaPagos: TUniQuery;
    FDatasetPagos: TfrxDBDataset;
  protected
    procedure PrepararDatosEdicion; override;
  public
    procedure preparar_consulta; override;
    procedure AfterReportLoaded; override;
    // FZ-ISSUE-102.14: recibos de efectos de cobro de venta mayor.
    // AEfectos = CSV de NUMERO_EFV seleccionados (opción «actual»).
    procedure PrepararEfectosVenta(const AEfectos: string);
    procedure PrepararEfectosCompra(AConexion: TUniConnection;
      const AEfectos: string);
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
  iIndice: Integer;
  oVista: TfrxView;
begin
  inherited;
  if dmFac <> nil then
    RebindReportDataSetsByDataModule(frxrprt1, dmFac);
  if Assigned(FDatasetPagos) then
  begin
    frxrprt1.DataSets.Clear;
    frxrprt1.DataSets.Add(FDatasetPagos);
    for iIndice := 0 to frxrprt1.AllObjects.Count - 1 do
    begin
      Banda := frxrprt1.AllObjects[iIndice];
      if Banda is TfrxDataBand then
        TfrxDataBand(Banda).DataSet := FDatasetPagos;
      if Banda is TfrxView then
      begin
        oVista := TfrxView(Banda);
        if (oVista.DataSetName = 'Facturas') or
           (oVista.DataSetName = 'Recibos') then
          oVista.DataSet := FDatasetPagos;
      end;
      if Banda is TfrxMemoView then
      begin
        if Pos('DOMICILIO Y NOMBRE', string(TfrxMemoView(Banda).Text)) > 0 then
          TfrxMemoView(Banda).Text := 'BENEFICIARIO DEL PAGO:';
        if Pos('CONFORME, EL LIBRADO', string(TfrxMemoView(Banda).Text)) > 0 then
          TfrxMemoView(Banda).Text := 'RECIBÍ, EL BENEFICIARIO';
      end;
    end;
  end;
  AjustarRotulosReciboFactura(frxrprt1);
  // Efectos: un recibo por página (el diseño admite varios por hoja).
  Banda := frxrprt1.FindObject('MasterData1');
  if (FEsEfectosVenta or Assigned(FDatasetPagos)) and
     (Banda is TfrxDataBand) then
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

procedure TfrmPrintRecFac.PrepararEfectosCompra(AConexion: TUniConnection;
  const AEfectos: string);
begin
  PrepararEfectosVenta(AEfectos);
  FEsEfectosVenta := False;
  FConsultaPagos := TUniQuery.Create(Self);
  FConsultaPagos.Connection := AConexion;
  FDatasetPagos := TfrxDBDataset.Create(Self);
  FDatasetPagos.UserName := 'Recibos';
  FDatasetPagos.DataSet := FConsultaPagos;
  FPreparadorInforme := CrearPreparadorInformeRecibosFacturaUniDAC(
    FConsultaPagos);
end;

procedure TfrmPrintRecFac.PrepararDatosEdicion;
begin
  preparar_consulta;
end;

procedure TfrmPrintRecFac.preparar_consulta;
var
  criterios: TCriteriosInformeRecibosFactura;
begin
  criterios := Default(TCriteriosInformeRecibosFactura);
  criterios.EsEfectosCompra := Assigned(FConsultaPagos);
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
  if Assigned(FDatasetPagos) then
    FDatasetPagos.UpdateBounds
  else
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
