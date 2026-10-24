{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalEtiqPed                                             }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       1.0.0                                                         }
{   Fecha:       01/07/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Modal de impresion de etiquetas de un PEDIDO DE COMPRA. Reutiliza la      }
{    misma base de etiquetas de articulos y el mismo informe que albaranes,    }
{    pero filtra los SKUs por las lineas del pedido.                           }
{******************************************************************************}
unit inMtoModalEtiqPed;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  inMtoModalGenImp, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters,
  Vcl.Menus, frxDesgn, Data.DB, MemDS, DBAccess, Uni, frxExportXLSX,
  frxClass, frxExportBaseDialog, frxExportPDF, cxClasses, cxLocalization,
  Vcl.StdCtrls, cxButtons, Vcl.ExtCtrls, dxSkinsCore, dxSkinBlue,
  cxControls, cxContainer, cxEdit, cxTextEdit, cxMaskEdit, cxSpinEdit,
  cxLabel, cxGroupBox, cxRadioGroup, cxDropDownEdit, cxDateUtils,
  cxCalendar, cxListView, cxCheckBox, ComCtrls,
  UniDataArticulos, UniDataPedidosCompra, inLibLayoutForm,
  JvComponentBase, JvEnterTab, frxSmartMemo, frLocalization,
  frLanguageSpanish, dxCore, System.Actions, Vcl.ActnList,
  frxExportBaseImageSettingsDialog, frCoreClasses, System.Rtti;

type
  TfrmPrintEtiqPed = class(TfrmPrint)
    pnlOpciones: TPanel;
    cxlblTarifa: TcxLabel;
    cbbTarifa: TcxComboBox;
    cxlblFecha: TcxLabel;
    dtFechaAplicacion: TcxDateEdit;
    cxlblAlmacenes: TcxLabel;
    lvAlmacenes: TcxListView;
    cxlblPedido: TcxLabel;
    edtPedido: TcxTextEdit;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FCodigosTarifa: TStringList;
    // FZ-ISSUE-118: el usuario omitió los SKU sin precio en la tarifa.
    FOmitirSinPrecio: Boolean;
    FLayout: TLayoutLoader;
    function ObtenerCodigoTarifa: string;
    function ObtenerAlmacenesCsv: string;
    procedure ReportBeforePrintEtiquetas(
      Component: TfrxReportComponent);
  public
    DMArt:  TdmArticulos;
    DMPedc: TdmPedidosCompra;
    Serie:  string;
    Numero: string;
    procedure preparar_consulta; override;
    procedure AfterReportLoaded; override;
    function  RelacionarClientDataSetConQuery(aCDS: TDataSet):
              TDataSet; override;
    procedure OnGuiasAplicadas; override;
  end;

implementation

{$R *.dfm}

uses
  inLibMensajesVcl,
  inLibMsgArticulos,
  inLibEtiquetasImpresion;

procedure TfrmPrintEtiqPed.FormCreate(Sender: TObject);
begin
  // Comparte Name con etiquetas de articulo para reutilizar formatos y guias.
  inherited;
  frxReportOrigen.AssignAll(frxrprt1);
  FCodigosTarifa := TStringList.Create;
  FLayout := TLayoutLoader.Create(
    Self.Name, ContextoSesion, PerfilesLectura);
  dtFechaAplicacion.Date := Date;
end;

procedure TfrmPrintEtiqPed.FormShow(Sender: TObject);
var
  Idx: Integer;
begin
  inherited;
  edtPedido.Text := Serie + ' / ' + Numero;
  if Assigned(DMArt) then
  begin
    Idx := -1;
    DMArt.CargarTarifasEtiquetas(cbbTarifa.Properties.Items, FCodigosTarifa,
                                 Idx);
    if Idx >= 0 then
      cbbTarifa.ItemIndex := Idx;
  end;
  if Assigned(DMPedc) then
    DMPedc.CargarAlmacenesDelPedido(Serie, Numero, lvAlmacenes);
  if FLayout.Disponible then
    FLayout.RestaurarGeometria(Self);
end;

procedure TfrmPrintEtiqPed.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FLayout);
  FreeAndNil(FCodigosTarifa);
  inherited;
end;

function TfrmPrintEtiqPed.ObtenerCodigoTarifa: string;
begin
  Result := '';
  if (cbbTarifa.ItemIndex >= 0) and
     (cbbTarifa.ItemIndex < FCodigosTarifa.Count) then
    Result := FCodigosTarifa[cbbTarifa.ItemIndex];
end;

function TfrmPrintEtiqPed.ObtenerAlmacenesCsv: string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to lvAlmacenes.Items.Count - 1 do
    if lvAlmacenes.Items[i].Checked then
    begin
      if Result <> '' then
        Result := Result + ',';
      Result := Result + lvAlmacenes.Items[i].Caption;
    end;
end;

procedure TfrmPrintEtiqPed.preparar_consulta;
begin
  if ObtenerCodigoTarifa = '' then
  begin
    ShowMessage_fza(SErrorTarifaEtiquetasNoSeleccionada);
    Abort;
  end;
  DMPedc.CrearDataSetEtiquetasPed(
    DMArt, Serie, Numero,
    ObtenerCodigoTarifa, ObtenerAlmacenesCsv,
    dtFechaAplicacion.Date);
  // Las preguntas de la comprobación no deben quedar tapadas por la
  // ventana de espera de la consulta (FZ-ISSUE-300).
  OcultarEspera;
  FOmitirSinPrecio :=
    ComprobarEtiquetasAntesDeImprimir(DMArt.cdsEtiquetasArt);
end;

procedure TfrmPrintEtiqPed.ReportBeforePrintEtiquetas(
  Component: TfrxReportComponent);
begin
  ReportBeforePrintConQR(Component);
  OcultarCodigoBarrasVacio(Component);
end;

procedure TfrmPrintEtiqPed.AfterReportLoaded;
var
  i: Integer;
  obj: TfrxComponent;
  ctx: TRttiContext;
  rType: TRttiType;
  propDs, propName: TRttiProperty;
  dsName: string;
begin
  inherited;
  if Assigned(DMArt) then
  begin
    if not DMArt.cdsEtiquetasArt.Active then
      DMArt.CrearDataSetEtiquetasArt('DUMMY_DISENO', '', '', Date);
    DMArt.fxdsEtiquetasArt.DataSet := nil;
    DMArt.fxdsEtiquetasArt.DataSet := DMArt.cdsEtiquetasArt;
    DMArt.fxdsEtiquetasArt.FieldAliases.Clear;
    frxrprt1.DataSets.Clear;
    frxrprt1.DataSets.Add(DMArt.fxdsEtiquetasArt);
    ctx := TRttiContext.Create;
    try
      for i := 0 to frxrprt1.AllObjects.Count - 1 do
      begin
        obj := TfrxComponent(frxrprt1.AllObjects[i]);
        rType := ctx.GetType(obj.ClassType);
        propDs   := rType.GetProperty('DataSet');
        propName := rType.GetProperty('DataSetName');
        if (propDs <> nil) and (propName <> nil) and propName.IsReadable and
           propDs.IsWritable then
        begin
          dsName := propName.GetValue(obj).AsString;
          if SameText(dsName, 'EtiquetasArt') then
            propDs.SetValue(obj, DMArt.fxdsEtiquetasArt);
        end;
      end;
    finally
      ctx.Free;
    end;
  end;
  frxrprt1.OnBeforePrint := ReportBeforePrintEtiquetas;
end;

function TfrmPrintEtiqPed.RelacionarClientDataSetConQuery(
                                                 aCDS: TDataSet): TDataSet;
begin
  if Assigned(DMArt) then
    Result := DMArt.unqryArtPrint
  else
    Result := inherited RelacionarClientDataSetConQuery(aCDS);
end;

procedure TfrmPrintEtiqPed.OnGuiasAplicadas;
begin
  inherited;
  if Assigned(DMArt) and Assigned(DMPedc) and DMArt.unqryArtPrint.Active then
  begin
    DMArt.PoblarCdsEtiquetasArtDesdeUniQuery;
    DMPedc.ExpandirEtiquetasPorCantidadPed(
      DMArt, Serie, Numero, ObtenerAlmacenesCsv);
    if FOmitirSinPrecio then
      QuitarEtiquetasSinPrecio(DMArt.cdsEtiquetasArt);
    DMArt.cdsEtiquetasArt.First;
    DMArt.fxdsEtiquetasArt.DataSet := nil;
    DMArt.fxdsEtiquetasArt.DataSet := DMArt.cdsEtiquetasArt;
    DMArt.fxdsEtiquetasArt.FieldAliases.Clear;
  end;
end;

end.
