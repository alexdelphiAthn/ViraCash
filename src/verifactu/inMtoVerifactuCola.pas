{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoVerifactuCola                                            }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.1.0                                                         }
{   Fecha:       13/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Cola de envíos Verifactu.                                                 }
{    Consulta del estado de fza_verifactu_cola (pendientes, enviadas y         }
{    errores del envío de registros de facturación a la AEAT). La cola la      }
{    alimenta el sistema (inLibVerifactuCola): aquí solo se edita el estado    }
{    (e intentos / próximo intento) en el grid, sin insertar ni borrar filas   }
{    y sin ficha de detalle. Ctrl+Alt+F / Ctrl+Mayús+F y el botón lateral      }
{    "Ir a Documento" saltan a la factura, normal o simplificada, resuelta     }
{    automáticamente según su TIPO_FAC.                                        }
{******************************************************************************}
unit inMtoVerifactuCola;

interface

uses
  inLibRegistroPantallas,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoGen, dxSkinsCore,
  dxSkinsDefaultPainters, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB, cxDBData,
  cxContainer, Vcl.Menus, dxSkinsForm, cxClasses, cxLocalization, Vcl.StdCtrls,
  cxButtons, cxDBNavigator, Vcl.Buttons, dxBevel, cxLabel, cxTextEdit,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataVerifactuCola,
  cxCheckBox, cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
  dxShellDialogs, System.Actions, Vcl.ActnList,
  System.Generics.Collections;

type
  TfrmMtoVerifactuCola = class(TfrmMtoGen)
    cxGrdDBTabPrinID_VFCOLA: TcxGridDBColumn;
    cxGrdDBTabPrinSERIE_FAC_VFCOLA: TcxGridDBColumn;
    cxGrdDBTabPrinNUMERO_FAC_VFCOLA: TcxGridDBColumn;
    cxGrdDBTabPrinTIPO_OPERACION_VFCOLA: TcxGridDBColumn;
    cxGrdDBTabPrinESTADO_VFCOLA: TcxGridDBColumn;
    cxGrdDBTabPrinCONTADOR_INTENTOS_VFCOLA: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTE_PROXIMO_INTENTO_VFCOLA: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTE_ENVIO_VFCOLA: TcxGridDBColumn;
    cxGrdDBTabPrinMENSAJE_ERROR_VFCOLA: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn;
    btnIrADocumento: TcxButton;
    btnEnviarYa: TcxButton;
    // Salta a la factura de la fila activa (lo dispara el botón lateral y los
    // atajos Ctrl+Alt+F / Ctrl+Mayús+F). ResolverCallFactura mira el TIPO_FAC
    // en fza_facturas y abre Facturas o FacturasSimplif según corresponda, así
    // se llega a la correcta sin saber el tipo de antemano.
    procedure btnIrADocumentoClick(Sender: TObject);
    // FZ-ISSUE-310: reactiva las filas pendientes o con error y despierta
    // al hilo de la cola sin esperar a appVerifactuSegundosCiclo
    procedure btnEnviarYaClick(Sender: TObject);
  private
    FTemporizadorRefresco: TTimer;
    dmmVerifactuCola: TdmVerifactuCola;
    // FZ-ISSUE-293: filas del SII fuera de plazo, en rojo
    FFueraDePlazo: TDictionary<Int64, Boolean>;
    FEstiloFueraDePlazo: TcxStyle;
    FAfterOpenPrevio: TDataSetNotifyEvent;
    FAfterRefreshPrevio: TDataSetNotifyEvent;
    procedure RefrescarColaActiva(Sender: TObject);
    procedure AnadirColumnaSistema;
    procedure CargarFueraDePlazo;
    procedure TablaAfterOpen(DataSet: TDataSet);
    procedure TablaAfterRefresh(DataSet: TDataSet);
    procedure VistaGetContentStyle(Sender: TcxCustomGridTableView;
      ARecord: TcxCustomGridRecord; AItem: TcxCustomGridTableItem;
      var AStyle: TcxStyle);
  public
    destructor Destroy; override;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

implementation

uses
  inLibWin, inLibShowMto, UniDataDestinoFacturaRepositorio,
  inLibMsgVerifactu, inLibColaEnviarYa, inLibColaEnviarYaVcl,
  inLibColasSenal, UniDataColaEnviarYa, inLibVerifactu,
  inLibVerifactuTipos;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoVerifactuCola }

procedure TfrmMtoVerifactuCola.RefrescarColaActiva(Sender: TObject);
begin
  if not (csDestroying in ComponentState) and Visible and Enabled and
     not ContextoSesion.CerrandoAplicacion and
     Assigned(dsTablaG.DataSet) and dsTablaG.DataSet.Active and
     (dsTablaG.DataSet.State = dsBrowse) and
     (ModoVerifactu(ParametrosApp) in [mvVerifactu, mvSii]) then
  begin
    FTemporizadorRefresco.Enabled := False;
    try
      try
        actRefrescarExecute(Self);
      except
        on E: Exception do
          RegistroLog.RegistrarError(
            'No se pudo refrescar la cola de Hacienda: ' +
            E.Message);
      end;
    finally
      FTemporizadorRefresco.Enabled := True;
    end;
  end;
end;

procedure TfrmMtoVerifactuCola.CrearTablaPrincipal;
var
  actDoc: TAction;
begin
  inherited;
  dmmVerifactuCola := tdmDataModule as TdmVerifactuCola;
  pkFieldName := 'ID_VFCOLA';
  // La cola la alimenta el sistema (inLibVerifactuCola.EncolarFactura) y el
  // data module solo define SQLUpdate (estado / intentos / próximo intento):
  // no se permite insertar ni borrar filas a mano, solo editar el estado.
  nvNavegador.Buttons.Insert.Visible := False;
  nvNavegador.Buttons.Append.Visible := False;
  nvNavegador.Buttons.Delete.Visible := False;
  // Anular también los atajos heredados Ins (insertar) y Ctrl+Supr (borrar).
  actInsertarRegistro.ShortCut  := 0;
  actInsertarRegistro.OnExecute := nil;
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
  // FZ-ISSUE-310: «Enviar ya» actúa sobre las filas seleccionadas
  cxGrdDBTabPrin.OptionsSelection.MultiSelect := True;
  // Sistema de cada fila (VERIFACTU / SII) y aviso de plazo del SII
  FFueraDePlazo := TDictionary<Int64, Boolean>.Create;
  FEstiloFueraDePlazo := TcxStyle.Create(Self);
  FEstiloFueraDePlazo.TextColor := clRed;
  cxGrdDBTabPrin.Styles.OnGetContentStyle := VistaGetContentStyle;
  if dsTablaG.DataSet <> nil then
  begin
    FAfterOpenPrevio := dsTablaG.DataSet.AfterOpen;
    FAfterRefreshPrevio := dsTablaG.DataSet.AfterRefresh;
    dsTablaG.DataSet.AfterOpen := TablaAfterOpen;
    dsTablaG.DataSet.AfterRefresh := TablaAfterRefresh;
    if dsTablaG.DataSet.Active then
    begin
      AnadirColumnaSistema;
      CargarFueraDePlazo;
    end;
  end;
  FTemporizadorRefresco := TTimer.Create(Self);
  FTemporizadorRefresco.Enabled := False;
  FTemporizadorRefresco.Interval := 20000;
  FTemporizadorRefresco.OnTimer := RefrescarColaActiva;
  FTemporizadorRefresco.Enabled := True;
end;

destructor TfrmMtoVerifactuCola.Destroy;
begin
  FreeAndNil(FTemporizadorRefresco);
  inherited;
  FreeAndNil(FFueraDePlazo);
end;

procedure TfrmMtoVerifactuCola.AnadirColumnaSistema;
var
  oColumna: TcxGridDBColumn;
begin
  // Sin el script 791 la cola no tiene SISTEMA_VFCOLA: todo es VERI*FACTU
  if (dsTablaG.DataSet.FindField('SISTEMA_VFCOLA') <> nil) and
     (cxGrdDBTabPrin.GetColumnByFieldName('SISTEMA_VFCOLA') = nil) then
  begin
    oColumna := cxGrdDBTabPrin.CreateColumn;
    oColumna.Name := 'cxGrdDBTabPrinSISTEMA_VFCOLA';
    oColumna.DataBinding.FieldName := 'SISTEMA_VFCOLA';
    oColumna.Caption := SCaptionColumnaSistemaColaVerifactu;
    oColumna.HeaderHint := Format(SAvisoColaSiiFueraDePlazo,
      [ParametrosApp.GetInt('appSiiDiasAvisoPlazo', 3)]);
    oColumna.Options.Editing := False;
    oColumna.Width := 90;
    oColumna.Index := cxGrdDBTabPrinTIPO_OPERACION_VFCOLA.Index + 1;
  end;
end;

procedure TfrmMtoVerifactuCola.CargarFueraDePlazo;
var
  iId: Int64;
begin
  // Aviso preventivo por antigüedad en días naturales desde FECHA_FAC.
  // appSiiDiasAvisoPlazo no calcula el vencimiento legal del SII.
  FFueraDePlazo.Clear;
  for iId in dmmVerifactuCola.IdsSiiFueraDePlazo(
    ParametrosApp.GetInt('appSiiDiasAvisoPlazo', 3)) do
    FFueraDePlazo.AddOrSetValue(iId, True);
end;

procedure TfrmMtoVerifactuCola.TablaAfterOpen(DataSet: TDataSet);
begin
  if Assigned(FAfterOpenPrevio) then
    FAfterOpenPrevio(DataSet);
  AnadirColumnaSistema;
  CargarFueraDePlazo;
end;

procedure TfrmMtoVerifactuCola.TablaAfterRefresh(DataSet: TDataSet);
begin
  if Assigned(FAfterRefreshPrevio) then
    FAfterRefreshPrevio(DataSet);
  CargarFueraDePlazo;
end;

procedure TfrmMtoVerifactuCola.VistaGetContentStyle(
  Sender: TcxCustomGridTableView; ARecord: TcxCustomGridRecord;
  AItem: TcxCustomGridTableItem; var AStyle: TcxStyle);
var
  vId: Variant;
begin
  if (ARecord <> nil) and (FFueraDePlazo <> nil) and
     (FFueraDePlazo.Count > 0) then
  begin
    vId := ARecord.Values[cxGrdDBTabPrinID_VFCOLA.Index];
    if (not VarIsNull(vId)) and (not VarIsEmpty(vId)) and
       FFueraDePlazo.ContainsKey(vId) then
      AStyle := FEstiloFueraDePlazo;
  end;
end;

procedure TfrmMtoVerifactuCola.btnIrADocumentoClick(Sender: TObject);
var
  sSerie, sNumero, sCall: string;
  ds: TDataSet;
begin
  inherited;
  ds := dsTablaG.DataSet;
  if (ds <> nil) and ds.Active and (not ds.IsEmpty) then
  begin
    sSerie  := ds.FieldByName('SERIE_FAC_VFCOLA').AsString;
    sNumero := ds.FieldByName('NUMERO_FAC_VFCOLA').AsString;
    sCall := ResolverCallFactura(
      CrearResolutorDestinoFacturaUniDAC(ConexionPrincipal),
      sNumero,
      sSerie);
    ShowMto(Self.Owner, sCall, sNumero + ',' + sSerie);
  end;
end;

procedure TfrmMtoVerifactuCola.btnEnviarYaClick(Sender: TObject);
var
  oDefinicion: TDefinicionColaEnviarYa;
  iMaxIntentos: Integer;
  sUsuario: string;
begin
  // El orden de VERI*FACTU y SII lo sigue imponiendo el procesador: con
  // un registro en vuelo la cola continúa bloqueada
  oDefinicion := DefinicionColaVerifactu;
  iMaxIntentos := ParametrosApp.GetInt(oDefinicion.ParametroMaxIntentos,
    oDefinicion.MaxIntentosDefecto);
  sUsuario := IdentidadSesion.Usuario;
  EnviarYaColaDesdeVista(cxGrdDBTabPrin, oDefinicion, 'VERI*FACTU/SII',
    function(const AIds: TArray<Int64>): Integer
    begin
      Result := EjecutarEnviarYaCola(
        dmmVerifactuCola.unqryTablaG.Connection, oDefinicion, AIds,
        iMaxIntentos, sUsuario);
    end,
    procedure
    begin
      SolicitarProcesadoCola(ccsVerifactu);
    end,
    procedure
    begin
      if dsTablaG.DataSet.Active then
        dsTablaG.DataSet.Refresh;
    end,
    RegistroLog);
end;

procedure TfrmMtoVerifactuCola.ResetForm;
begin
  inherited;
end;

initialization
  RegistrarPantalla(TfrmMtoVerifactuCola);
  ForceReferenceToClass(TfrmMtoVerifactuCola);
end.
