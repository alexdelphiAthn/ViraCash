{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalEtiqAlb                                             }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       1.0.0                                                         }
{   Fecha:       23/05/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Modal de impresion de etiquetas de un ALBARAN DE COMPRA. Clon             }
{    simplificado de inMtoModalEtiqArt: misma estructura de TfrmPrint y        }
{    mismo dataset de etiquetas (cdsEtiquetasArt en TdmArticulos), pero        }
{    los SKUs vienen filtrados por las lineas del albaran. El listado          }
{    de almacenes que se pinta esta limitado a los almacenes que aparecen      }
{    en las lineas (no toda la red), porque un albaran puede tener varios.     }
{                                                                              }
{    El .fr3 se diseña a mano en el modal una vez; si se quiere compartir      }
{    plantilla con el modal de articulos, basta con copiar el contenido        }
{    de frxrprt1 entre los .dfm (mismo nombre de datasets y aliases).          }
{******************************************************************************}
unit inMtoModalEtiqAlb;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  inMtoModalGenImp, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters,
  Vcl.Menus, frxDesgn, Data.DB, MemDS, DBAccess, Uni, frxExportXLSX, frxClass,
  frxExportBaseDialog, frxExportPDF, cxClasses, cxLocalization, Vcl.StdCtrls,
  cxButtons, Vcl.ExtCtrls, dxSkinsCore, dxSkinBlue, cxControls, cxContainer,
  cxEdit, cxTextEdit, cxMaskEdit, cxSpinEdit, cxLabel, cxGroupBox,
  cxRadioGroup, cxDropDownEdit, cxDateUtils, cxCalendar, cxListView,
  cxCheckBox, ComCtrls,
  UniDataArticulos, UniDataAlbaranesCompra, inLibLayoutForm,
  JvComponentBase, JvEnterTab, frxSmartMemo, frLocalization, frLanguageSpanish,
  dxCore, System.Actions, Vcl.ActnList, frxExportBaseImageSettingsDialog,
  frCoreClasses, System.Rtti, UniDataEtiquetasDocumentosCompra;

type
  TfrmPrintEtiqAlb = class(TfrmPrint)
    pnlOpciones: TPanel;
    cxlblTarifa: TcxLabel;
    cbbTarifa: TcxComboBox;
    cxlblFecha: TcxLabel;
    dtFechaAplicacion: TcxDateEdit;
    cxlblAlmacenes: TcxLabel;
    lvAlmacenes: TcxListView;
    cxlblAlbaran: TcxLabel;
    edtAlbaran: TcxTextEdit;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FCodigosTarifa: TStringList;
    // FZ-ISSUE-118: el usuario omitió los SKU sin precio en la tarifa.
    FOmitirSinPrecio: Boolean;
    FLayout: TLayoutLoader;
    FEtiquetas: TEtiquetasDocumentoCompra;
    function ObtenerCodigoTarifa: string;
    function Etiquetas: TEtiquetasDocumentoCompra;
    procedure ReportBeforePrintEtiquetas(
      Component: TfrxReportComponent);
    function ObtenerAlmacenesCsv: string;
  public
    DMArt:    TdmArticulos;        // datasets fxds / cdsEtiquetasArt
    DMAlbc:   TdmAlbaranesCompra;  // queries del albaran
    Serie:    string;
    Numero:   string;
    procedure preparar_consulta; override;
    procedure AfterReportLoaded; override;
    function  RelacionarClientDataSetConQuery(aCDS: TDataSet): TDataSet;
    override;
    procedure OnGuiasAplicadas; override;
  end;

implementation

{$R *.dfm}

uses
  inLibMensajesVcl,
  inLibMsgArticulos,
  inLibEtiquetasImpresion;

procedure TfrmPrintEtiqAlb.FormCreate(Sender: TObject);
begin
  // El Name del form coincide con el del modal de etiquetas de
  // articulos ('frmPrintEtiqArt') — esta fijado en el .dfm para que
  // TfrmPrint.FormCreate (que se ejecuta ANTES por herencia) ya lea
  // ese Name al cargar perfiles. Asi compartimos formatos guardados
  // y guias entre los dos modales sin duplicar el diseno.
  inherited;
  // Snapshot del diseno embebido en frxrprt1 para que la opcion
  // 'Predeterminado' del selector de formatos (Consultar_Formularios)
  // pueda restaurarlo via frxrprt1.AssignAll(frxReportOrigen). Sin
  // este AssignAll la primera vez, frxReportOrigen queda vacio y
  // 'Predeterminado' pinta un report en blanco.
  frxReportOrigen.AssignAll(frxrprt1);
  FCodigosTarifa := TStringList.Create;
  FLayout := TLayoutLoader.Create(
    Self.Name, ContextoSesion, PerfilesLectura);
  dtFechaAplicacion.Date := Date;
end;

procedure TfrmPrintEtiqAlb.FormShow(Sender: TObject);
var
  Idx: Integer;
begin
  inherited;
  edtAlbaran.Text := Serie + ' / ' + Numero;
  // Tarifas: reutilizamos las del DM de articulos (mismas que en Mto
  // Articulos).
  if Assigned(DMArt) then
  begin
    Idx := -1;
    DMArt.CargarTarifasEtiquetas(cbbTarifa.Properties.Items,
                                 FCodigosTarifa,
                                 Idx);
    if Idx >= 0 then cbbTarifa.ItemIndex := Idx;
  end;
  // Almacenes: solo los que aparecen en las lineas del albaran. Usamos
  // el helper del DM de albaranes (a anadir en commit conjunto).
  if Assigned(DMAlbc) then
    Etiquetas.CargarAlmacenes(lvAlmacenes);
  if FLayout.Disponible then FLayout.RestaurarGeometria(Self);
end;

procedure TfrmPrintEtiqAlb.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FEtiquetas);
  FreeAndNil(FLayout);
  FreeAndNil(FCodigosTarifa);
  inherited;
end;

function TfrmPrintEtiqAlb.ObtenerCodigoTarifa: string;
begin
  Result := '';
  if (cbbTarifa.ItemIndex >= 0) and
     (cbbTarifa.ItemIndex < FCodigosTarifa.Count) then
    Result := FCodigosTarifa[cbbTarifa.ItemIndex];
end;

// Una etiqueta por unidad del documento (FZ-ISSUE-093). Lee por la
// conexion de la ventana del documento.
function TfrmPrintEtiqAlb.Etiquetas: TEtiquetasDocumentoCompra;
begin
  if not Assigned(FEtiquetas) then
    FEtiquetas := TEtiquetasDocumentoCompra.Create(
      DMAlbc.unqryTablaG.Connection, dceAlbaran, Serie, Numero);
  Result := FEtiquetas;
end;

procedure TfrmPrintEtiqAlb.ReportBeforePrintEtiquetas(
  Component: TfrxReportComponent);
begin
  ReportBeforePrintConQR(Component);
  OcultarCodigoBarrasVacio(Component);
end;

function TfrmPrintEtiqAlb.ObtenerAlmacenesCsv: string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to lvAlmacenes.Items.Count - 1 do
    if lvAlmacenes.Items[i].Checked then
    begin
      if Result <> '' then Result := Result + ',';
      Result := Result + lvAlmacenes.Items[i].Caption;
    end;
end;

procedure TfrmPrintEtiqAlb.preparar_consulta;
begin
  if ObtenerCodigoTarifa = '' then
  begin
    ShowMessage_fza(SErrorTarifaEtiquetasNoSeleccionada);
    Abort;
  end;
  // Los almacenes marcados filtran las lineas del documento; no se
  // expande por stock (FZ-ISSUE-093).
  Etiquetas.CrearDataSet(DMArt, ObtenerCodigoTarifa,
    ObtenerAlmacenesCsv, dtFechaAplicacion.Date);
  // Las preguntas de la comprobación no deben quedar tapadas por la
  // ventana de espera de la consulta (FZ-ISSUE-300).
  OcultarEspera;
  FOmitirSinPrecio :=
    ComprobarEtiquetasAntesDeImprimir(DMArt.cdsEtiquetasArt);
end;

procedure TfrmPrintEtiqAlb.AfterReportLoaded;
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

function TfrmPrintEtiqAlb.RelacionarClientDataSetConQuery(
                                                 aCDS: TDataSet): TDataSet;
begin
  if Assigned(DMArt) then
    Result := DMArt.unqryArtPrint
  else
    Result := inherited RelacionarClientDataSetConQuery(aCDS);
end;

procedure TfrmPrintEtiqAlb.OnGuiasAplicadas;
begin
  inherited;
  if Assigned(DMArt) and Assigned(DMAlbc) and
     DMArt.unqryArtPrint.Active then
  begin
    DMArt.PoblarCdsEtiquetasArtDesdeUniQuery;
    Etiquetas.ExpandirDataSet(DMArt, ObtenerAlmacenesCsv);
    if FOmitirSinPrecio then
      QuitarEtiquetasSinPrecio(DMArt.cdsEtiquetasArt);
    DMArt.cdsEtiquetasArt.First;
    DMArt.fxdsEtiquetasArt.DataSet := nil;
    DMArt.fxdsEtiquetasArt.DataSet := DMArt.cdsEtiquetasArt;
    DMArt.fxdsEtiquetasArt.FieldAliases.Clear;
  end;
end;

end.
