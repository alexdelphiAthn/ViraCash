{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoAlmacenes                                                }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/02/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de almacenes.                                               }
{    CRUD sobre fza_almacenes por empresa.                                     }
{******************************************************************************}
unit inMtoAlmacenes;

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
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataAlmacenes, cxCheckBox,
  cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore, cxRadioGroup,
  Vcl.AppEvnts, JvComponentBase, JvEnterTab, dxShellDialogs,
  cxSplitter, cxMaskEdit, cxDBEdit, cxDropDownEdit, cxLookupEdit,
  cxDBLookupEdit, cxDBLookupComboBox;

type
  TfrmMtoAlmacenes = class(TfrmMtoGen)
    dbcGrdDBTabPrinCODIGO_ALMACEN_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinCODIGO_EMPRESA_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinNOMBRE_ALMACEN_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinESACTIVO_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinESWEB_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinCODIGO_PADRE_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinESFISICO_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinTIPO_USO_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinDIRECCION_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinPOBLACION_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinCODIGO_POSTAL_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinTELEFONO_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinEMAIL_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinCODIGO_CLIENTE_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinALMACEN_DESTINO_ACTUAL_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinALMACEN_ORIGEN_ACTUAL_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinORDEN_ALM: TcxGridDBColumn;
    pnlTopFicha: TPanel;
    pnlBodyFicha: TPanel;
    lblCodigo: TcxLabel;
    txtCODIGO_ALMACEN_ALM: TcxDBTextEdit;
    lblCodigoEmpresa: TcxLabel;
    txtCODIGO_EMPRESA_ALM: TcxDBTextEdit;
    lblNombre: TcxLabel;
    txtNOMBRE_ALMACEN_ALM: TcxDBTextEdit;
    chkESACTIVO_ALM: TcxDBCheckBox;
    chkESWEB_ALM: TcxDBCheckBox;
    chkESFISICO_ALM: TcxDBCheckBox;
    lblOrden: TcxLabel;
    spnORDEN_ALM: TcxDBSpinEdit;
    pnlButtonFicha: TPanel;
    pcDetail: TcxPageControl;
    tsAuditoria: TcxTabSheet;
    pnlAuditoria: TPanel;
    lblUsuarioAlta: TcxLabel;
    txtUSUARIOALTA: TcxDBTextEdit;
    lblInstanteAlta: TcxLabel;
    txtINSTANTEALTA: TcxDBTextEdit;
    lblUsuarioModif: TcxLabel;
    txtUSUARIOMODIF: TcxDBTextEdit;
    lblInstanteModif: TcxLabel;
    txtINSTANTEMODIF: TcxDBTextEdit;
    splSplitterFicha: TcxSplitter;
    tsCajas: TcxTabSheet;
    pnlSeriesCli: TPanel;
    cxgrdAlmacenCajas: TcxGrid;
    tvAlmacenesCajas: TcxGridDBTableView;
    lvAlmacenCajas: TcxGridLevel;
    tsUsosAlmacen: TcxTabSheet;
    lblAlmacenDestino: TcxLabel;
    lblAlmacenOrigen: TcxLabel;
    cxdbtxtdtALMACEN_ORIGEN_ACTUAL_ALM: TcxDBLookupComboBox;
    cxdbtxtdtALMACEN_DESTINO_ACTUAL_ALM: TcxDBLookupComboBox;
    lblTipoUso: TcxLabel;
    cxdbtxtdtTIPO_USO_ALM: TcxDBComboBox;
    lblCodigoPadre: TcxLabel;
    cxdbtxtdtCODIGO_PADRE_ALM: TcxDBLookupComboBox;
    tsDireccion: TcxTabSheet;
    lblTelefono: TcxLabel;
    cxdbtxtdtTELEFONO_ALM: TcxDBTextEdit;
    lblEmail: TcxLabel;
    cxdbtxtdtEMAIL_ALM: TcxDBTextEdit;
    lblPoblacion: TcxLabel;
    cxdbtxtdtCODPOSTAL: TcxDBTextEdit;
    cxdbtxtdtPOBLACION_ALM: TcxDBTextEdit;
    lblDireccion: TcxLabel;
    cxdbtxtdtDIRECCION_ALM: TcxDBTextEdit;
    lblProvincia: TcxLabel;
    cxdbtxtdtPROVINCIA_ALM: TcxDBTextEdit;
    lblCodigoCliente: TcxLabel;
    cxdbtxtdtCODIGO_CLIENTE_ALM: TcxDBTextEdit;
    chkESCOMPARTIDO_ALM: TcxDBCheckBox;
    dbmAlmacenesCajasCODIGO_ALMACEN_ALMCAJ: TcxGridDBColumn;
    dbmAlmacenesCajasCODIGO_CAJA_ALMCAJ: TcxGridDBColumn;
    dbmAlmacenesCajasDESCRIPCION_ALMCAJ: TcxGridDBColumn;
  private
    procedure tvAlmacenesCajasNavigatorButtonClick(Sender: TObject;
      AButtonIndex: Integer; var ADone: Boolean);
    procedure InsertarCaja;
    function ConfirmarBorradoCaja: Boolean;
  public
    dmmAlmacenes: TdmAlmacenes;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

implementation

uses
  inLibBotonesDetalle,
  inLibMensajesVcl,
  inLibMsgConfiguracion,
  inLibWin;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoAlmacenes }

procedure TfrmMtoAlmacenes.CrearTablaPrincipal;
begin
  inherited;
  dmmAlmacenes := tdmDataModule as TdmAlmacenes;
  pkFieldName := 'CODIGO_ALM_ALM';
  // Origen, destino y padre se eligen de la lista de almacenes en vez
  // de teclear el código a ciegas (FZ-ISSUE-212). Supr los vacía.
  cxdbtxtdtALMACEN_ORIGEN_ACTUAL_ALM.Properties.ListSource :=
    dmmAlmacenes.dsAlmacenesLookup;
  cxdbtxtdtALMACEN_DESTINO_ACTUAL_ALM.Properties.ListSource :=
    dmmAlmacenes.dsAlmacenesLookup;
  cxdbtxtdtCODIGO_PADRE_ALM.Properties.ListSource :=
    dmmAlmacenes.dsAlmacenesLookup;
  tvAlmacenesCajas.Navigator.Buttons.OnButtonClick :=
    tvAlmacenesCajasNavigatorButtonClick;
  // Botones «Añadir» y «Borrar» sobre las rejillas de detalle, además
  // de los «+» y «-» del navegador.
  AnadirBotonesDetalle(tvAlmacenesCajas);
end;

procedure TfrmMtoAlmacenes.tvAlmacenesCajasNavigatorButtonClick(
  Sender: TObject; AButtonIndex: Integer; var ADone: Boolean);
begin
  if AButtonIndex = NBDI_INSERT then
  begin
    ADone := True;
    InsertarCaja;
  end
  else if AButtonIndex = NBDI_DELETE then
    ADone := not Self.ConfirmarBorradoCaja;
end;

// Una caja con operaciones grabadas (ventas, cobros, arqueos...) no se
// borra sin avisar: esas operaciones quedarían con una caja que ya no
// existe. Una caja recién añadida y sin grabar no tiene operaciones.
function TfrmMtoAlmacenes.ConfirmarBorradoCaja: Boolean;
var
  oCajas: TDataSet;
  sCaja: string;
  iOperaciones: Integer;
begin
  Result := True;
  oCajas := dmmAlmacenes.qryAlmacenesCajas;
  if (oCajas.State <> dsInsert) and (not oCajas.IsEmpty) then
  begin
    sCaja := oCajas.FieldByName('CODIGO_CAJA_ALMCAJ').AsString;
    iOperaciones := dmmAlmacenes.OperacionesDeCaja(
      dsTablaG.DataSet.FieldByName('CODIGO_EMP_ALM').AsString,
      dsTablaG.DataSet.FieldByName('CODIGO_ALM_ALM').AsString, sCaja);
    if iOperaciones > 0 then
      Result := MessageDlg_fza(Format(SAvisoBorrarCajaConOperaciones,
        [sCaja, dsTablaG.DataSet.FieldByName('CODIGO_ALM_ALM').AsString,
        iOperaciones]), mtWarning, [mbYes, mbNo], 0, mbNo) = mrYes;
  end;
end;

// «+» con la ficha en Navegando: la cabecera pasa a edición antes de crear
// la caja (editarla después refrescaba el detalle y la fila nueva se
// perdía) y la fila queda en edición en el código (FZ-ISSUE-624).
// El foco va a la rejilla ANTES del alta: al salir del sitio de la vista
// (también al enfocar el TcxGrid que lo contiene) la rejilla cancela una
// fila nueva sin tocar (CancelOnExit) y el «+» no dejaba ninguna.
procedure TfrmMtoAlmacenes.InsertarCaja;
var
  oSitio: TWinControl;
begin
  oSitio := tvAlmacenesCajas.Site;
  if (not oSitio.Focused) and oSitio.CanFocus then
    oSitio.SetFocus;
  try
    dmmAlmacenes.PrepararCambioCajas;
    tvAlmacenesCajas.DataController.Append;
  except
    on E: Exception do
    begin
      AvisarSiCampoObligatorio(E);
      raise;
    end;
  end;
  tvAlmacenesCajas.Controller.FocusedColumn :=
    dbmAlmacenesCajasCODIGO_CAJA_ALMCAJ;
  if tvAlmacenesCajas.Controller.EditingController <> nil then
    tvAlmacenesCajas.Controller.EditingController.ShowEdit;
end;

procedure TfrmMtoAlmacenes.ResetForm;
begin
  inherited;
end;

initialization
  RegistrarPantalla(TfrmMtoAlmacenes);
  ForceReferenceToClass(TfrmMtoAlmacenes);
end.
