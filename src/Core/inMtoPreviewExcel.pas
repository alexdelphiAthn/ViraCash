{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoPreviewExcel                                             }
{    Tipo:       Formulario (Core)                                             }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/02/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Esta unidad proporciona la lógica necesaria para presentar la pantalla    }
{    de previsualización de hoja de cálculo. Sus textos se resuelven mediante  }
{    el catálogo central de traducciones.                                      }
{******************************************************************************}
unit inMtoPreviewExcel;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoFrmBase, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, dxCore, dxCoreClasses, dxHashUtils,
  dxSpreadSheetCore, dxSpreadSheetCoreFormulas, dxSpreadSheetCoreHistory,
  dxSpreadSheetCoreStyles, dxSpreadSheetCoreStrs,
  dxSpreadSheetConditionalFormatting, dxSpreadSheetConditionalFormattingRules,
  dxSpreadSheetClasses, dxSpreadSheetContainers, dxSpreadSheetFormulas,
  dxSpreadSheetHyperlinks, dxSpreadSheetFunctions, dxSpreadSheetStyles,
  dxSpreadSheetGraphics, dxSpreadSheetPrinting, dxSpreadSheetTypes,
  dxSpreadSheetUtils, dxSpreadSheetFormattedTextUtils,
  Vcl.Menus, Vcl.StdCtrls, cxButtons, Vcl.ExtCtrls, dxSpreadSheet,
  JvComponentBase, JvEnterTab, cxClasses, cxLocalization, dxShellDialogs,
  dxSpreadSheetFormulaBar, dxSpreadSheetFunctionsStatistical,
  dxSpreadSheetFunctionsMath, System.Actions, Vcl.ActnList,
  inLibPreviewExcel;

type
  TfrmMtoPreviewExcel = class(TfrmBase)
    dxSpreadSheet1: TdxSpreadSheet;
    Panel1: TPanel;
    btnGuardar: TcxButton;
    btnCerrar: TcxButton;
    DialogoGuardar: TdxSaveFileDialog;
    dxSpreadSheetFormulaBar1: TdxSpreadSheetFormulaBar;
    ActionList1: TActionList;
    actSalir: TAction;
    procedure btnGuardarClick(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
    procedure actSalirExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    procedure MaximizarVentana;
    procedure WmMaximizarPreviewExcel(var Msg: TMessage);
      message WM_USER + 120;
  public
    { Public declarations }
  end;

function CrearProveedorPreviewExcelMto: IProveedorPreviewExcel;

implementation

uses
  inLibFormatoExcel, inLibMsgComun;

type
  TSesionPreviewExcelMto = class(TSesionPreviewExcel)
  private
    FFormulario: TfrmMtoPreviewExcel;
  public
    constructor Create(AOwner: TComponent);
    destructor Destroy; override;
    function HojaCalculo: TdxSpreadSheet; override;
    procedure AsignarPopupParent(APadre: TCustomForm); override;
    procedure AsignarNombreArchivo(const ANombre: string); override;
    procedure Mostrar; override;
  end;

  TProveedorPreviewExcelMto = class(
    TInterfacedObject,
    IProveedorPreviewExcel)
  public
    function Crear(AOwner: TComponent): TSesionPreviewExcel;
  end;

{$R *.dfm}

constructor TSesionPreviewExcelMto.Create(AOwner: TComponent);
begin
  inherited Create;
  FFormulario := TfrmMtoPreviewExcel.Create(AOwner);
end;

destructor TSesionPreviewExcelMto.Destroy;
begin
  FreeAndNil(FFormulario);
  inherited;
end;

function TSesionPreviewExcelMto.HojaCalculo: TdxSpreadSheet;
begin
  Result := FFormulario.dxSpreadSheet1;
end;

procedure TSesionPreviewExcelMto.AsignarPopupParent(
  APadre: TCustomForm);
begin
  FFormulario.PopupParent := APadre;
end;

procedure TSesionPreviewExcelMto.AsignarNombreArchivo(
  const ANombre: string);
begin
  FFormulario.DialogoGuardar.FileName := ANombre;
end;

procedure TSesionPreviewExcelMto.Mostrar;
begin
  FFormulario.ShowModal;
end;

function CrearProveedorPreviewExcelMto: IProveedorPreviewExcel;
begin
  Result := TProveedorPreviewExcelMto.Create;
end;

function TProveedorPreviewExcelMto.Crear(
  AOwner: TComponent): TSesionPreviewExcel;
begin
  Result := TSesionPreviewExcelMto.Create(AOwner);
end;

procedure TfrmMtoPreviewExcel.actSalirExecute(Sender: TObject);
begin
  inherited;
  btnCerrarClick(Sender);
end;

procedure TfrmMtoPreviewExcel.btnCerrarClick(Sender: TObject);
begin
  inherited;
  Close;
end;

procedure TfrmMtoPreviewExcel.btnGuardarClick(Sender: TObject);
var
  oFormato: TFormatoExcel;
  sFormato: string;
  sExt: string;
  oDialogo: TFileSaveDialog;
  oTipoFichero: TFileTypeItem;
begin
  inherited;
  sFormato := VALOR_FORMATO_DEFECTO;
  if Assigned(ParametrosApp) then
    sFormato := ParametrosApp.GetString(CLAVE_FORMATO_EXCEL,
      VALOR_FORMATO_DEFECTO);
  oFormato := FormatoExcelDesde(sFormato);
  sExt := ExtensionFormato(oFormato);
  // Diálogo Vista nativo (TFileSaveDialog) con Execute(Self.Handle) como
  // owner: aparece bien sobre el preview modal, a diferencia del shell de
  // DevExpress. Nombre y carpeta se toman de DialogoGuardar / parámetros.
  oDialogo := TFileSaveDialog.Create(nil);
  try
    oDialogo.Title := STituloGuardarExcel;
    if DialogoGuardar.InitialDir <> '' then
      oDialogo.DefaultFolder := DialogoGuardar.InitialDir
    else if Assigned(ParametrosApp) then
      oDialogo.DefaultFolder := ParametrosApp.GetPath('appDirExcel');
    oDialogo.DefaultExtension := sExt;
    oTipoFichero := oDialogo.FileTypes.Add;
    oTipoFichero.DisplayName :=
      Format(SCaptionFiltroArchivo, [sExt]);
    oTipoFichero.FileMask := '*.' + sExt;
    oDialogo.FileName := DialogoGuardar.FileName;
    if oDialogo.Execute(Self.Handle) then
      dxSpreadSheet1.SaveToFile(oDialogo.FileName);
  finally
    FreeAndNil(oDialogo);
  end;
end;

procedure TfrmMtoPreviewExcel.FormCreate(Sender: TObject);
begin
  inherited;
end;

procedure TfrmMtoPreviewExcel.FormShow(Sender: TObject);
begin
  inherited;
  PostMessage(Handle, WM_USER + 120, 0, 0);
end;

procedure TfrmMtoPreviewExcel.MaximizarVentana;
var
  R :TRect;
begin
  WindowState := wsNormal;
  if Assigned(Monitor) then
    R := Monitor.WorkareaRect
  else
    R := Screen.PrimaryMonitor.WorkareaRect;
  SetBounds(R.Left, R.Top, R.Width, R.Height);
  // El spreadsheet recalcula la tira de hojas al recibir el resize real.
  SendMessage(Handle, WM_SYSCOMMAND, SC_MAXIMIZE, 0);
  dxSpreadSheet1.Invalidate;
end;

procedure TfrmMtoPreviewExcel.WmMaximizarPreviewExcel(var Msg: TMessage);
begin
  MaximizarVentana;
  Msg.Result := 0;
end;

end.
