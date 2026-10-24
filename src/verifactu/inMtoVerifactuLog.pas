{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoVerifactuLog                                             }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.1.0                                                         }
{   Fecha:       13/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Log Verifactu.                                                            }
{    Consulta del registro de eventos del subsistema Verifactu                 }
{    (fza_verifactu_eventos): envíos, errores y cadena de hashes.              }
{******************************************************************************}
unit inMtoVerifactuLog;

interface

uses
  inLibRegistroPantallas,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.UITypes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoGen, dxSkinsCore,
  dxSkinsDefaultPainters, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB, cxDBData,
  cxContainer, Vcl.Menus, dxSkinsForm, cxClasses, cxLocalization, Vcl.StdCtrls,
  cxButtons, cxDBNavigator, Vcl.Buttons, dxBevel, cxLabel, cxTextEdit,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataVerifactuLog,
  cxCheckBox, cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
  dxShellDialogs, System.Actions, Vcl.ActnList, System.IOUtils;

type
  TfrmMtoVerifactuLog = class(TfrmMtoGen)
    cxGrdDBTabPrinID_LOG: TcxGridDBColumn;
    cxGrdDBTabPrinTIMESTAMP_LOG: TcxGridDBColumn;
    cxGrdDBTabPrinTIPO_EVENTO_LOG: TcxGridDBColumn;
    cxGrdDBTabPrinDESCRIPCION_LOG: TcxGridDBColumn;
    cxGrdDBTabPrinDATOS_ADICIONALES_LOG: TcxGridDBColumn;
    cxGrdDBTabPrinSERIE_FAC_LOG: TcxGridDBColumn;
    cxGrdDBTabPrinNUMERO_FAC_LOG: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIO_LOG: TcxGridDBColumn;
    cxGrdDBTabPrinVERSION_LOG: TcxGridDBColumn;
    cxGrdDBTabPrinHASH_ANTERIOR_LOG: TcxGridDBColumn;
    cxGrdDBTabPrinHASH_PROPIO_LOG: TcxGridDBColumn;
    cxGrdDBTabPrinFIRMA_DIGITAL_LOG: TcxGridDBColumn;
    btnIrADocumento: TcxButton;
    btnExportarNoVerifactu: TcxButton;
    btnVerificarNoVerifactu: TcxButton;
    // Salta a la factura de la fila activa (lo dispara el botón lateral y los
    // atajos Ctrl+Alt+F / Ctrl+Mayús+F). ResolverCallFactura mira el TIPO_FAC
    // en fza_facturas y abre Facturas o FacturasSimplif según corresponda, así
    // se llega a la correcta sin saber el tipo de antemano.
    procedure btnIrADocumentoClick(Sender: TObject);
    procedure btnExportarNoVerifactuClick(Sender: TObject);
    procedure btnVerificarNoVerifactuClick(Sender: TObject);
  private
    dmmVerifactuLog: TdmVerifactuLog;
  public
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

implementation

uses
  inLibMensajesVcl,
  inLibWin, inLibShowMto, UniDataDestinoFacturaRepositorio,
  inLibMsgVerifactu, inLibVerifactuNoVerifactuExport,
  inLibVerifactuNoVerifactuVerify,
  UniDataVerifactuNoVerifactuExport;

{$R *.dfm}

resourcestring
  SFiltroArchivoXmlNoVerifactu =
    'Archivo XML|*.xml';
  SFiltroArchivosXmlNoVerifactu =
    'Archivos XML|*.xml|Todos los archivos|*.*';
  SNombreArchivoExportacionNoVerifactu =
    'NoVerifactu_%s.xml';

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoVerifactuLog }

procedure TfrmMtoVerifactuLog.CrearTablaPrincipal;
var
  actDoc: TAction;
begin
  inherited;
  dmmVerifactuLog := tdmDataModule as TdmVerifactuLog;
  pkFieldName := 'ID_LOG';
  // El log es un registro inalterable (solo consulta): ni alta, ni edición,
  // ni borrado. Se ocultan los botones del navegador y se anulan los atajos
  // heredados Ins (insertar), F2 (editar) y Ctrl+Supr (borrar).
  nvNavegador.Buttons.Insert.Visible := False;
  nvNavegador.Buttons.Append.Visible := False;
  nvNavegador.Buttons.Edit.Visible   := False;
  nvNavegador.Buttons.Post.Visible   := False;
  nvNavegador.Buttons.Delete.Visible := False;
  actInsertarRegistro.ShortCut  := 0;
  actInsertarRegistro.OnExecute := nil;
  actEditarRegistro.ShortCut    := 0;
  actEditarRegistro.OnExecute   := nil;
  actEliminarRegistro.ShortCut  := 0;
  actEliminarRegistro.OnExecute := nil;
  // Atajos "Ir a Documento" creados en código y colgados de alMtoGen (lo
  // recorre inMtoPrincipal.IsShortCut). Dos acciones para los dos atajos:
  // Ctrl+Alt+F y Ctrl+Mayús+F. Ambas reusan el handler del botón lateral.
  actDoc := TAction.Create(Self);
  actDoc.ActionList := alMtoGen;
  actDoc.ShortCut   := ShortCut(Ord('F'), [ssCtrl, ssAlt]);
  actDoc.OnExecute  := btnIrADocumentoClick;
  actDoc := TAction.Create(Self);
  actDoc.ActionList := alMtoGen;
  actDoc.ShortCut   := ShortCut(Ord('F'), [ssCtrl, ssShift]);
  actDoc.OnExecute  := btnIrADocumentoClick;
end;

procedure TfrmMtoVerifactuLog.btnIrADocumentoClick(Sender: TObject);
var
  sSerie, sNumero, sCall: string;
  ds: TDataSet;
begin
  inherited;
  ds := dsTablaG.DataSet;
  if (ds <> nil) and ds.Active and (not ds.IsEmpty) then
  begin
    sSerie  := ds.FieldByName('SERIE_FAC_LOG').AsString;
    sNumero := ds.FieldByName('NUMERO_FAC_LOG').AsString;
    // Muchos eventos (info, errores de cola) no llevan factura: solo se
    // navega cuando la línea tiene serie y número.
    if (Trim(sSerie) <> '') and (Trim(sNumero) <> '') then
    begin
      sCall := ResolverCallFactura(
        CrearResolutorDestinoFacturaUniDAC(ConexionPrincipal),
        sNumero,
        sSerie);
      ShowMto(Self.Owner, sCall, sNumero + ',' + sSerie);
    end;
  end;
end;

procedure TfrmMtoVerifactuLog.btnExportarNoVerifactuClick(Sender: TObject);
var
  oDialogo: TSaveDialog;
  oResultado: TResultadoExportacionNoVerifactu;
begin
  inherited;
  if not PuedeExportar then
    Abort;
  oDialogo := TSaveDialog.Create(Self);
  try
    oDialogo.Title := STituloGuardarExportacionNoVerifactu;
    oDialogo.InitialDir := TPath.GetDocumentsPath;
    oDialogo.Filter := SFiltroArchivoXmlNoVerifactu;
    oDialogo.DefaultExt := 'xml';
    oDialogo.FileName := Format(
      SNombreArchivoExportacionNoVerifactu,
      [FormatDateTime('yyyymmdd_hhnnss', Now)]);
    if oDialogo.Execute then
    begin
      oResultado := ExportarRegistrosNoVerifactu(ParametrosApp,
        CrearRepositorioExportacionNoVerifactuUniDAC(ConexionPrincipal),
        ConexionPrincipal,
        IdentidadSesion.Usuario, oDialogo.FileName, RegistroLog);
      MessageDlg_fza(Format(SInfoExportacionNoVerifactuGenerada,
        [oResultado.ArchivoEventos, oResultado.ArchivoFacturacion,
         oResultado.Eventos, oResultado.RegistrosFactura]),
        mtInformation, [mbOK], 0);
    end;
  finally
    FreeAndNil(oDialogo);
  end;
end;

procedure TfrmMtoVerifactuLog.btnVerificarNoVerifactuClick(Sender: TObject);
var
  oDialogo: TOpenDialog;
  oResultado: TResultadoVerificacionNoVerifactu;
  sEventos: string;
  sFacturacion: string;
  sInforme: string;
  sResumen: string;
begin
  inherited;
  oDialogo := TOpenDialog.Create(Self);
  try
    oDialogo.Title := STituloVerificarFicherosNoVerifactu;
    oDialogo.InitialDir := TPath.GetDocumentsPath;
    oDialogo.Filter := SFiltroArchivosXmlNoVerifactu;
    if oDialogo.Execute then
    begin
      InferirFicherosNoVerifactu(oDialogo.FileName, sEventos, sFacturacion);
      oResultado := VerificarFicherosNoVerifactu(ParametrosApp, sEventos,
        sFacturacion);
      sResumen := ResumenVerificacionNoVerifactu(ParametrosApp, oResultado);
      sInforme := NombreInformeErroresNoVerifactu(oDialogo.FileName);
      TFile.WriteAllText(sInforme, sResumen + sLineBreak + sLineBreak +
        oResultado.Detalle, TEncoding.UTF8);
      if oResultado.Errores = 0 then
        MessageDlg_fza(Format(SInfoVerificacionNoVerifactuCorrecta,
          [sResumen, sInforme]), mtInformation, [mbOK], 0)
      else
        MessageDlg_fza(Format(SErrorVerificacionNoVerifactu,
          [sResumen, sInforme]), mtError, [mbOK], 0);
    end;
  finally
    FreeAndNil(oDialogo);
  end;
end;

procedure TfrmMtoVerifactuLog.ResetForm;
begin
  inherited;
end;

initialization
  RegistrarPantalla(TfrmMtoVerifactuLog);
  ForceReferenceToClass(TfrmMtoVerifactuLog);
end.
