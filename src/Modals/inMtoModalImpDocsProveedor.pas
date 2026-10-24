{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpDocsProveedor                                   }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       20/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de impresión del "Listado de documentos proveedor". Lista           }
{    cabeceras de pedidos, albaranes, facturas y devoluciones de compra,       }
{    con filtros de fechas, almacén destino, temporada, proveedor, tipo y      }
{    serie de documento. La temporada se toma solo de cabeceras de pedido o    }
{    de la sesión de compra que generó el documento; no se consulta la ficha   }
{    ni las propiedades del artículo.                                          }
{******************************************************************************}
unit inMtoModalImpDocsProveedor;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  inMtoModalImpMultiFiltro, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters,
  Vcl.Menus, frxDesgn, Data.DB, MemDS, DBAccess, Uni,
  frxExportXLSX, frxClass, frxDBSet, frxExportBaseDialog, frxExportPDF,
  Vcl.StdCtrls, cxButtons, Vcl.ExtCtrls, cxControls, cxContainer, cxEdit,
  cxTextEdit, cxMaskEdit, cxDropDownEdit, cxCalendar, cxLabel,
  cxCheckListBox, cxCheckBox, cxCustomListBox, cxClasses, dxSkinsForm,
  System.Actions, Vcl.ActnList, frxSmartMemo, frLocalization,
  frLanguageSpanish, frCoreClasses,
  frxExportBaseImageSettingsDialog, JvComponentBase, JvEnterTab,
  cxLocalization, inLibInformeDocumentosProveedorPersistenciaIntf,
  inLibInformeMultiFiltroPersistenciaIntf,
  inLibResumenSeleccionesInforme;

type
  TfrmPrintDocsProveedor = class(TfrmPrintMultiFiltro)
    fxdsDocsProveedor: TfrxDBDataset;
  private
    FInicializado: Boolean;
    FRepositorioDocumentos: IRepositorioInformeDocumentosProveedor;
    FResultadoDocumentos: IResultadoInformeDocumentosProveedor;
    FclbTipos: TcxCheckListBox;
    FclbSeries: TcxCheckListBox;
    procedure CrearControlesPropios;
    procedure CargarTiposDocumento;
    procedure CargarSeriesDocumento;
    function CSVTipos: string;
    function CSVSeries: string;
  protected
    function FiltrosUsados: TFiltrosReport; override;
    procedure DescribirSelecciones(
      AResumen: TResumenSeleccionesInforme); override;
    function OrigenProveedores:
      TOrigenProveedoresInformeMultiFiltro; override;
    procedure DoShow; override;
  public
    procedure preparar_consulta; override;
    procedure AfterReportLoaded; override;
  end;

implementation

uses
  UniDataDocsProveedor,
  UniDataInformeDocumentosProveedorRepositorio,
  inLibResumenSeleccionesVcl, inLibInformeDocumentosProveedorTotales,
  // FZ-ISSUE-609: los resourcestring solo se traducen desde inLibMsg*.
  inLibMsgCompras;

{$R *.dfm}

{ TfrmPrintDocsProveedor }

function TfrmPrintDocsProveedor.FiltrosUsados: TFiltrosReport;
begin
  Result := [frFechas, frAlmacenes, frProveedores, frTemporadas];
end;

function TfrmPrintDocsProveedor.OrigenProveedores:
  TOrigenProveedoresInformeMultiFiltro;
begin
  Result := opmfDocumentosProveedor;
end;

procedure TfrmPrintDocsProveedor.DoShow;
begin
  inherited;
  if not FInicializado then
  begin
    CrearControlesPropios;
    FInicializado := True;
  end;
end;

procedure TfrmPrintDocsProveedor.CrearControlesPropios;
begin
  FclbTipos := CrearTabChecklist(STituloTiposDocumentoInformeProveedor);
  CargarTiposDocumento;
  FclbSeries := CrearTabChecklist(STituloSeriesDocumentoInformeProveedor);
  CargarSeriesDocumento;
end;

procedure TfrmPrintDocsProveedor.CargarTiposDocumento;

  procedure Agregar(const ACodigo, AEtiqueta: string);
  var
    oElemento: TcxCheckListBoxItem;
  begin
    oElemento := FclbTipos.Items.Add;
    oElemento.Text := ACodigo + ' - ' + AEtiqueta;
    oElemento.State := cbsUnchecked;
  end;

begin
  if FclbTipos <> nil then
  begin
    FclbTipos.Items.Clear;
    Agregar('PED', SCaptionPedidosInformeProveedor);
    Agregar('ALB', SCaptionAlbaranesInformeProveedor);
    Agregar('FAC', SCaptionFacturasInformeProveedor);
    Agregar('DEV', SCaptionDevolucionesInformeProveedor);
  end;
end;

procedure TfrmPrintDocsProveedor.CargarSeriesDocumento;
var
  aSeries: TArray<string>;
  oElemento: TcxCheckListBoxItem;
  sSerie: string;
begin
  if FclbSeries <> nil then
  begin
    FclbSeries.Items.Clear;
    aSeries := ListarSeriesDocumentosCompra(ConexionPrincipal);
    for sSerie in aSeries do
    begin
      oElemento := FclbSeries.Items.Add;
      oElemento.Text := sSerie;
      oElemento.State := cbsUnchecked;
    end;
  end;
end;

function TfrmPrintDocsProveedor.CSVSeries: string;
begin
  Result := SeleccionadosCSV(FclbSeries);
end;

function TfrmPrintDocsProveedor.CSVTipos: string;
begin
  Result := SeleccionadosCSV(FclbTipos);
end;

procedure TfrmPrintDocsProveedor.DescribirSelecciones(
  AResumen: TResumenSeleccionesInforme);
begin
  inherited;
  AnadirMarcados(
    AResumen, STituloTiposDocumentoInformeProveedor, FclbTipos);
  AnadirMarcados(
    AResumen, STituloSeriesDocumentoInformeProveedor, FclbSeries);
end;

procedure TfrmPrintDocsProveedor.preparar_consulta;
var
  criterios: TCriteriosInformeDocumentosProveedor;
begin
  inherited;
  criterios.FechaDesde := FechaDesde;
  criterios.FechaHasta := FechaHasta;
  criterios.Almacenes := CSVAlmacenes;
  criterios.Proveedores := CSVProveedores;
  criterios.Temporadas := CSVTemporadas;
  criterios.Tipos := CSVTipos;
  criterios.Series := CSVSeries;
  if FRepositorioDocumentos = nil then
    FRepositorioDocumentos :=
      CrearRepositorioInformeDocumentosProveedorUniDAC(ConexionPrincipal);
  FResultadoDocumentos := FRepositorioDocumentos.Preparar(criterios);
  fxdsDocsProveedor.UpdateBounds;
end;

procedure TfrmPrintDocsProveedor.AfterReportLoaded;
begin
  inherited;
  fxdsDocsProveedor.DataSet := FResultadoDocumentos.DataSet;
  frxrprt1.DataSets.Clear;
  frxrprt1.DataSets.Add(fxdsDocsProveedor);
  // FZ-ISSUE-247: el total general no suma pedido + albaran + factura de
  // la misma compra.
  AjustarTotalGeneralDocumentosProveedor(frxrprt1,
    fxdsDocsProveedor.UserName, STotalComprasNetasInformeProveedor);
end;

end.
