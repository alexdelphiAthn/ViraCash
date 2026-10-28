{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoRemesasCompra                                            }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       10/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Remesas de pago que agrupan efectos (consulta).                          }
{******************************************************************************}
unit inMtoRemesasCompra;

interface

uses
  inLibRegistroPantallas,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.UITypes, inMtoGen, dxSkinsCore,
  dxSkinsDefaultPainters, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB, cxDBData,
  cxContainer, Vcl.Menus, dxSkinsForm, cxClasses, cxLocalization, Vcl.StdCtrls,
  cxButtons, cxDBNavigator, Vcl.Buttons, dxBevel, cxLabel, cxTextEdit,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataRemesasCompra,
  cxCheckBox, cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, Vcl.AppEvnts, JvComponentBase, JvEnterTab, dxShellDialogs,
  cxDBEdit, cxMaskEdit, cxDropDownEdit, cxCalendar, cxCurrencyEdit, cxMemo,
  cxLookupEdit, cxDBLookupEdit, cxDBLookupComboBox,
  inLibPermisosIntf,
  inLibCargaEfectosRemesaPersistenciaIntf, inLibSepaRemesasCompra;

type
  TfrmMtoRemesasCompra = class(TfrmMtoGen)
    dbcGrdDBTabPrinNUMERO_REMC: TcxGridDBColumn;
    dbcGrdDBTabPrinSERIE_REMC: TcxGridDBColumn;
    dbcGrdDBTabPrinFECHA_REMC: TcxGridDBColumn;
    dbcGrdDBTabPrinESTADO_REMC: TcxGridDBColumn;
    dbcGrdDBTabPrinCODIGO_EMP_REMC: TcxGridDBColumn;
    dbcGrdDBTabPrinRAZON_SOCIAL_EMPRESA_VIEW_REMC: TcxGridDBColumn;
    dbcGrdDBTabPrinCONTADOR_EFECTOS_REMC: TcxGridDBColumn;
    dbcGrdDBTabPrinTOTAL_REMC: TcxGridDBColumn;
    dbcGrdDBTabPrinFECHA_CARGO_REMC: TcxGridDBColumn;
    dbcGrdDBTabPrinIBAN_REMC: TcxGridDBColumn;
    pnlFichaCabecera: TPanel;
    lblNumero: TcxLabel;
    txtNUMERO_REMC: TcxDBTextEdit;
    lblSerie: TcxLabel;
    txtSERIE_REMC: TcxDBTextEdit;
    lblFecha: TcxLabel;
    dteFECHA_REMC: TcxDBDateEdit;
    lblEstado: TcxLabel;
    txtESTADO_REMC: TcxDBTextEdit;
    lblEmpresa: TcxLabel;
    txtCODIGO_EMP_REMC: TcxDBTextEdit;
    lblRazonSocial: TcxLabel;
    txtRAZON_SOCIAL_EMPRESA_VIEW_REMC: TcxDBTextEdit;
    lblTotal: TcxLabel;
    curTOTAL_REMC: TcxDBCurrencyEdit;
    lblContadorEfectos: TcxLabel;
    txtCONTADOR_EFECTOS_REMC: TcxDBTextEdit;
    lblFechaCargo: TcxLabel;
    dteFECHA_CARGO_REMC: TcxDBDateEdit;
    lblIBAN: TcxLabel;
    txtIBAN_REMC: TcxDBTextEdit;
    lblCargoRealizado: TcxLabel;
    curTOTAL_CARGADO_REMC: TcxDBCurrencyEdit;
    lblPendienteCargo: TcxLabel;
    curTOTAL_PENDIENTE_REMC: TcxDBCurrencyEdit;
    lblBancoPago: TcxLabel;
    cbbBancoPagoRemesa: TcxLookupComboBox;
    lblObservaciones: TcxLabel;
    memOBSERVACIONES_REMC: TcxDBMemo;
    pnlFichaDetalle: TPanel;
    pnlEfectosTitulo: TPanel;
    lblEfectosRemesa: TcxLabel;
    cxgrdEfectosRemesa: TcxGrid;
    tvEfectosRemesa: TcxGridDBTableView;
    tvEfectosRemesaNUMERO_FACC_EFEC: TcxGridDBColumn;
    tvEfectosRemesaSERIE_FACC_EFEC: TcxGridDBColumn;
    tvEfectosRemesaNUMERO_EFEC: TcxGridDBColumn;
    tvEfectosRemesaPROVEEDOR_VIEW_EFEC: TcxGridDBColumn;
    tvEfectosRemesaDESCRIPCION_TEFE_VIEW_EFEC: TcxGridDBColumn;
    tvEfectosRemesaFECHA_VENCIMIENTO_EFEC: TcxGridDBColumn;
    tvEfectosRemesaIMPORTE_EFEC: TcxGridDBColumn;
    tvEfectosRemesaIMPORTE_PAGADO_EFEC: TcxGridDBColumn;
    tvEfectosRemesaIMPORTE_PENDIENTE_EFEC: TcxGridDBColumn;
    tvEfectosRemesaESTADO_EFEC: TcxGridDBColumn;
    tvEfectosRemesaREFERENCIA_DOCUMENTO_EFEC: TcxGridDBColumn;
    tvEfectosRemesaFECHA_PAGO_EFEC: TcxGridDBColumn;
    tvEfectosRemesaDOC_EXTERNO_EFEC: TcxGridDBColumn;
    lvlEfectosRemesa: TcxGridLevel;
    btnAnadirEfecto: TcxButton;
    btnQuitarEfecto: TcxButton;
    btnPagarEfecto: TcxButton;
    btnPagarRemesa: TcxButton;
    btnAsignarBanco: TcxButton;
    btnFechaCargo: TcxButton;
    dbcGrdDBTabPrinTOTAL_CARGADO_REMC: TcxGridDBColumn;
    dbcGrdDBTabPrinTOTAL_PENDIENTE_REMC: TcxGridDBColumn;
    btnGenerarSepa: TcxButton;
    btnReabrirRemesa: TcxButton;
    procedure btnAnadirEfectoClick(Sender: TObject);
    procedure btnQuitarEfectoClick(Sender: TObject);
    procedure btnPagarEfectoClick(Sender: TObject);
    procedure btnPagarRemesaClick(Sender: TObject);
    procedure btnAsignarBancoClick(Sender: TObject);
    procedure btnFechaCargoClick(Sender: TObject);
    procedure btnGenerarSepaClick(Sender: TObject);
    procedure btnReabrirRemesaClick(Sender: TObject);
  private
    FRepositorioCargaEfectos: IRepositorioCargaEfectosRemesa;
    procedure ActualizarBancoPago;
    procedure actEliminarRemesaExecute(Sender: TObject);
    procedure dsTablaGDataChangeHook(Sender: TObject; Field: TField);
    procedure nvNavegadorButtonsButtonClick(Sender: TObject;
      AButtonIndex: Integer; var ADone: Boolean);
    function BancoRemesaAsignado: Boolean;
    function ConfirmarAvisosSepa(
      const ARemesa: TRemesaSepaCompraValidada): Boolean;
    function ConfirmarRegeneracionSepa(
      const AFichero: TFicheroSepaRemesaCompra): Boolean;
    function EliminarRemesaActual: Boolean;
    function ElegirFormatoSepa(const AFichero: TFicheroSepaRemesaCompra;
      out AFormato: TFormatoSepaTransferencia): Boolean;
    function ElegirArchivoSepa(out AArchivo: string): Boolean;
    procedure GenerarSepaRemesa;
    function RemesaSeleccionada: Boolean;
  public
    dmmRemesasCompra: TdmRemesasCompra;
    constructor Create(
      AOwner: TComponent;
      const AContexto: TContextoAutorizacionPantalla;
      const ARepositorio: IRepositorioCargaEfectosRemesa); reintroduce;
      overload;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

implementation

uses
  inLibMensajesVcl,
  inLibWin, inMtoModalCargarEfectosRemesa,
  inMtoModalRegistrarPago, inLibMsgCompras, inLibMsgVentas;

{$R *.dfm}

constructor TfrmMtoRemesasCompra.Create(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const ARepositorio: IRepositorioCargaEfectosRemesa);
begin
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('ARepositorio');
  FRepositorioCargaEfectos := ARepositorio;
  inherited Create(AOwner, AContexto);
end;

procedure ForceReferenceToClass(C: TClass); begin end;

function LimpiarNombreArchivoSepa(const AValor: string): string;
var
  i: Integer;
begin
  Result := Trim(AValor);
  for i := 1 to Length(Result) do
  begin
    if CharInSet(Result[i],
       ['\', '/', ':', '*', '?', '"', '<', '>', '|']) then
      Result[i] := '_';
  end;
end;

procedure TfrmMtoRemesasCompra.CrearTablaPrincipal;
begin
  inherited;
  dmmRemesasCompra := tdmDataModule as TdmRemesasCompra;
  tvEfectosRemesa.DataController.DataSource :=
    dmmRemesasCompra.dsEfectosRemesa;
  dmmRemesasCompra.unqryEfectosRemesa.MasterSource := dsTablaG;
  dmmRemesasCompra.unqryBancosEmpresa.MasterSource := dsTablaG;
  cbbBancoPagoRemesa.Properties.ListSource :=
    dmmRemesasCompra.dsBancosEmpresa;
  cbbBancoPagoRemesa.Properties.KeyFieldNames := 'CODIGO_EMPBAN';
  cbbBancoPagoRemesa.Properties.ListFieldNames := 'BANCO_VIEW_EMPBAN';
  dsTablaG.OnDataChange := dsTablaGDataChangeHook;
  // La tabla principal es la vista vi_remesas_compra (JOIN, solo lectura): el
  // DELETE estandar del dataset falla, asi que el borrado se hace a mano.
  actEliminarRegistro.OnExecute := actEliminarRemesaExecute;
  nvNavegador.Buttons.OnButtonClick := nvNavegadorButtonsButtonClick;
  pkFieldName := 'NUMERO_REMC;SERIE_REMC';
end;

procedure TfrmMtoRemesasCompra.ResetForm;
begin
  inherited;
end;

function TfrmMtoRemesasCompra.RemesaSeleccionada: Boolean;
begin
  Result := Assigned(dmmRemesasCompra) and
            dmmRemesasCompra.unqryTablaG.Active and
            (not dmmRemesasCompra.unqryTablaG.IsEmpty);
end;

function TfrmMtoRemesasCompra.BancoRemesaAsignado: Boolean;
begin
  Result := RemesaSeleccionada and
            (Trim(dmmRemesasCompra.unqryTablaG.FieldByName('IBAN_REMC')
              .AsString) <> '');
end;

procedure TfrmMtoRemesasCompra.nvNavegadorButtonsButtonClick(Sender: TObject;
  AButtonIndex: Integer; var ADone: Boolean);
begin
  if AButtonIndex = NBDI_DELETE then
  begin
    ADone := True;
    EliminarRemesaActual;
  end;
end;

procedure TfrmMtoRemesasCompra.actEliminarRemesaExecute(Sender: TObject);
begin
  EliminarRemesaActual;
end;

function TfrmMtoRemesasCompra.EliminarRemesaActual: Boolean;
begin
  Result := False;
  if not RemesaSeleccionada then
    ShowMessage_fza(SErrorRemesaCompraNoSeleccionada)
  else if dmmRemesasCompra.RemesaTieneCargo then
    ShowMessage_fza(SErrorEliminarRemesaCompraConCargo)
  else if dmmRemesasCompra.RemesaGenerada then
    ShowMessage_fza(SErrorRemesaCompraGenerada)
  else if MessageDlg_fza(SPreguntaEliminarRemesaCompra,
          mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    if dmmRemesasCompra.EliminarRemesa then
    begin
      ShowMessage_fza(SInfoRemesaCompraEliminada);
      ActualizarBancoPago;
      Result := True;
    end
    else
      ShowMessage_fza(SErrorEliminarRemesaCompra);
  end;
end;

procedure TfrmMtoRemesasCompra.ActualizarBancoPago;
var
  sIban: string;
begin
  cbbBancoPagoRemesa.EditValue := Null;
  if Assigned(dmmRemesasCompra) and dmmRemesasCompra.unqryBancosEmpresa.Active
     and RemesaSeleccionada then
  begin
    sIban := Trim(dmmRemesasCompra.unqryTablaG.FieldByName('IBAN_REMC')
      .AsString);
    if (sIban <> '') and
       dmmRemesasCompra.unqryBancosEmpresa.Locate('IBAN_EMPBAN', sIban, []) then
      cbbBancoPagoRemesa.EditValue :=
        dmmRemesasCompra.unqryBancosEmpresa.FieldByName('CODIGO_EMPBAN')
          .AsString
    else if (sIban = '') and
            (not dmmRemesasCompra.unqryBancosEmpresa.IsEmpty) then
    begin
      dmmRemesasCompra.unqryBancosEmpresa.First;
      cbbBancoPagoRemesa.EditValue :=
        dmmRemesasCompra.unqryBancosEmpresa.FieldByName('CODIGO_EMPBAN')
          .AsString;
    end;
  end;
end;

procedure TfrmMtoRemesasCompra.dsTablaGDataChangeHook(Sender: TObject;
  Field: TField);
begin
  if Field = nil then
    ActualizarBancoPago;
end;

procedure TfrmMtoRemesasCompra.btnAnadirEfectoClick(Sender: TObject);
var
  frm: TfrmModalCargarEfectosRemesa;
  q: TDataSet;
begin
  inherited;
  if not RemesaSeleccionada then
    ShowMessage_fza(SErrorRemesaCompraNoSeleccionada)
  else if dmmRemesasCompra.RemesaTieneCargo then
    ShowMessage_fza(SErrorAnadirEfectosRemesaCompraConCargo)
  else if dmmRemesasCompra.RemesaGenerada then
    ShowMessage_fza(SErrorRemesaCompraGenerada)
  else
  begin
    q := dmmRemesasCompra.unqryTablaG;
    frm := TfrmModalCargarEfectosRemesa.CrearParaCompra(
      nil,
      FRepositorioCargaEfectos);
    try
      frm.PrepararRemesaExistente(q.FieldByName('CODIGO_EMP_REMC').AsString,
        q.FieldByName('SERIE_REMC').AsString,
        q.FieldByName('NUMERO_REMC').AsString);
      if frm.ShowModal = mrOk then
      begin
        dmmRemesasCompra.RefrescarDatos;
        ActualizarBancoPago;
      end;
    finally
      frm.Free;
    end;
  end;
end;

procedure TfrmMtoRemesasCompra.btnQuitarEfectoClick(Sender: TObject);
begin
  inherited;
  if not RemesaSeleccionada then
    ShowMessage_fza(SErrorRemesaCompraNoSeleccionada)
  else if not dmmRemesasCompra.unqryEfectosRemesa.Active then
    ShowMessage_fza(SErrorEfectosRemesaCompraNoCargados)
  else if dmmRemesasCompra.unqryEfectosRemesa.IsEmpty then
    ShowMessage_fza(SErrorEfectoRemesaCompraNoSeleccionado)
  else if dmmRemesasCompra.RemesaTieneCargo then
    ShowMessage_fza(SErrorQuitarEfectosRemesaCompraConCargo)
  else if dmmRemesasCompra.RemesaGenerada then
    ShowMessage_fza(SErrorRemesaCompraGenerada)
  else if MessageDlg_fza(SPreguntaQuitarEfectoRemesaCompra,
          mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    if dmmRemesasCompra.QuitarEfectoActual then
      ShowMessage_fza(SInfoEfectoRemesaCompraQuitado)
    else
      ShowMessage_fza(SErrorQuitarEfectoRemesaCompra);
    ActualizarBancoPago;
  end;
end;

procedure TfrmMtoRemesasCompra.btnPagarEfectoClick(Sender: TObject);
var
  frm: TfrmModalRegistrarPago;
  q: TDataSet;
  iRes: Integer;
  fPend: Double;
begin
  inherited;
  if not RemesaSeleccionada then
    ShowMessage_fza(SErrorRemesaCompraNoSeleccionada)
  else if not BancoRemesaAsignado then
    ShowMessage_fza(SErrorBancoPagoRemesaNoAsignado)
  else if not dmmRemesasCompra.unqryEfectosRemesa.Active then
    ShowMessage_fza(SErrorEfectosRemesaCompraNoCargados)
  else if dmmRemesasCompra.unqryEfectosRemesa.IsEmpty then
    ShowMessage_fza(SErrorEfectoRemesaCompraNoSeleccionado)
  else
  begin
    q := dmmRemesasCompra.unqryEfectosRemesa;
    fPend := q.FieldByName('IMPORTE_PENDIENTE_EFEC').AsFloat;
    if fPend <= 0.0001 then
      ShowMessage_fza(SErrorEfectoRemesaCompraSinPendiente)
    else
    begin
      frm := TfrmModalRegistrarPago.Create(nil);
      try
        frm.SetDatos(Format(STextoEfectoPendienteRemesaCompra,
          [q.FieldByName('NUMERO_EFEC').AsInteger, fPend]), fPend);
        if frm.ShowModal = mrOk then
        begin
          iRes := dmmRemesasCompra.RegistrarPagoEfectoActual(frm.Fecha,
            frm.Importe, frm.Tipo, frm.Referencia);
          if iRes > 0 then
            ShowMessage_fza(SInfoEfectoRemesaCompraConciliado)
          else
            ShowMessage_fza(SErrorConciliarEfectoRemesaCompra);
          ActualizarBancoPago;
        end;
      finally
        frm.Free;
      end;
    end;
  end;
end;

procedure TfrmMtoRemesasCompra.btnPagarRemesaClick(Sender: TObject);
var
  frm: TfrmModalRegistrarPago;
  iRes: Integer;
  fPend: Double;
begin
  inherited;
  if not RemesaSeleccionada then
    ShowMessage_fza(SErrorRemesaCompraNoSeleccionada)
  else if not BancoRemesaAsignado then
    ShowMessage_fza(SErrorBancoPagoRemesaNoAsignado)
  else
  begin
    fPend := dmmRemesasCompra.PendienteRemesa;
    if fPend <= 0.0001 then
      ShowMessage_fza(SErrorRemesaCompraSinImportePendiente)
    else
    begin
      frm := TfrmModalRegistrarPago.Create(nil);
      try
        frm.SetDatos(Format(STextoRemesaCompraPendiente, [fPend]), fPend);
        if frm.ShowModal = mrOk then
        begin
          iRes := dmmRemesasCompra.RegistrarPagoRemesa(frm.Fecha,
            frm.Importe, frm.Tipo, frm.Referencia);
          if iRes > 0 then
            ShowMessage_fza(Format(SInfoEfectosRemesaCompraConciliados,
                               [iRes]))
          else
            ShowMessage_fza(SErrorConciliarRemesaCompra);
          ActualizarBancoPago;
        end;
      finally
        frm.Free;
      end;
    end;
  end;
end;

procedure TfrmMtoRemesasCompra.btnAsignarBancoClick(Sender: TObject);
var
  sCodigo: string;
begin
  inherited;
  if not RemesaSeleccionada then
    ShowMessage_fza(SErrorRemesaCompraNoSeleccionada)
  else if dmmRemesasCompra.RemesaGenerada then
    ShowMessage_fza(SErrorRemesaCompraGenerada)
  else
  begin
    sCodigo := VarToStr(cbbBancoPagoRemesa.EditValue);
    if sCodigo = '' then
      ShowMessage_fza(SErrorBancoPagoNoSeleccionado)
    else if dmmRemesasCompra.AsignarBancoRemesa(sCodigo) then
    begin
      ShowMessage_fza(SInfoBancoPagoRemesaAsignado);
      ActualizarBancoPago;
    end
    else
      ShowMessage_fza(SErrorAsignarBancoPagoRemesa);
  end;
end;

procedure TfrmMtoRemesasCompra.btnFechaCargoClick(Sender: TObject);
var
  sFecha: string;
  dFecha: TDateTime;
begin
  inherited;
  if not RemesaSeleccionada then
    ShowMessage_fza(SErrorRemesaCompraNoSeleccionada)
  else if dmmRemesasCompra.RemesaGenerada then
    ShowMessage_fza(SErrorRemesaCompraGenerada)
  else
  begin
    sFecha := FormatDateTime('dd/mm/yyyy', Date);
    if not dmmRemesasCompra.unqryTablaG.FieldByName('FECHA_CARGO_REMC')
       .IsNull then
      sFecha := FormatDateTime('dd/mm/yyyy',
        dmmRemesasCompra.unqryTablaG.FieldByName('FECHA_CARGO_REMC')
          .AsDateTime);
    if InputQuery_fza(STituloFechaCargoRemesa, SSolicitudFechaCargoRemesa,
                      sFecha) then
    begin
      if TryStrToDate(sFecha, dFecha) then
      begin
        if dmmRemesasCompra.ActualizarFechaCargo(dFecha) then
          ShowMessage_fza(SInfoFechaCargoRemesaActualizada)
        else
          ShowMessage_fza(SErrorActualizarFechaCargoRemesa);
        ActualizarBancoPago;
      end
      else
        ShowMessage_fza(SErrorFechaCargoRemesaNoValida);
    end;
  end;
end;

function TfrmMtoRemesasCompra.ConfirmarRegeneracionSepa(
  const AFichero: TFicheroSepaRemesaCompra): Boolean;
begin
  Result := AFichero.IdMensaje = '';
  if not Result then
    Result := MessageDlg_fza(Format(SPreguntaRegenerarSepaRemesaCompra,
      [DateTimeToStr(AFichero.Instante), AFichero.IdMensaje, sLineBreak,
       AFichero.Archivo, sLineBreak + sLineBreak]),
      mtWarning, [mbYes, mbNo], 0, mbNo) = mrYes;
end;

function TfrmMtoRemesasCompra.ElegirFormatoSepa(
  const AFichero: TFicheroSepaRemesaCompra;
  out AFormato: TFormatoSepaTransferencia): Boolean;
var
  eBotonDefecto: TMsgDlgBtn;
  iRespuesta: Integer;
begin
  AFormato := FormatoSepaTransferenciaDesdeNombre(AFichero.Formato,
    fstPain00100103);
  eBotonDefecto := mbYes;
  if AFormato = fstPain00100109 then
    eBotonDefecto := mbNo;
  iRespuesta := MessageDlgTextos_fza(SPreguntaFormatoSepaRemesaCompra,
    mtConfirmation, [mbYes, mbNo, mbCancel],
    [SBotonFormatoSepa2009, SBotonFormatoSepa2019, ''], eBotonDefecto);
  Result := iRespuesta in [mrYes, mrNo];
  if iRespuesta = mrYes then
    AFormato := fstPain00100103
  else if iRespuesta = mrNo then
    AFormato := fstPain00100109;
end;

function TfrmMtoRemesasCompra.ConfirmarAvisosSepa(
  const ARemesa: TRemesaSepaCompraValidada): Boolean;
begin
  Result := Length(ARemesa.Avisos) = 0;
  if not Result then
    Result := MessageDlg_fza(Format(SPreguntaRemesaCompraSepaAvisos,
      [sLineBreak + sLineBreak,
       string.Join(sLineBreak, ARemesa.Avisos),
       sLineBreak + sLineBreak]),
      mtWarning, [mbYes, mbNo], 0, mbNo) = mrYes;
end;

function TfrmMtoRemesasCompra.ElegirArchivoSepa(
  out AArchivo: string): Boolean;
var
  dlg: TSaveDialog;
  sNombre: string;
begin
  AArchivo := '';
  sNombre := Format(SNombreArchivoSepaRemesaCompra,
    [dmmRemesasCompra.unqryTablaG.FieldByName('SERIE_REMC').AsString,
     dmmRemesasCompra.unqryTablaG.FieldByName('NUMERO_REMC').AsString]);
  dlg := TSaveDialog.Create(nil);
  try
    dlg.DefaultExt := 'xml';
    dlg.Filter := SFiltroArchivoSepaRemesaCompra;
    dlg.Options := dlg.Options + [ofOverwritePrompt];
    dlg.FileName := LimpiarNombreArchivoSepa(sNombre) + '.xml';
    Result := dlg.Execute;
    if Result then
      AArchivo := dlg.FileName;
  finally
    dlg.Free;
  end;
end;

// Nada se graba hasta escribir el fichero: cancelar cualquier paso deja
// la remesa como estaba.
procedure TfrmMtoRemesasCompra.GenerarSepaRemesa;
var
  eFormato: TFormatoSepaTransferencia;
  rFichero: TFicheroSepaRemesaCompra;
  rRemesa: TRemesaSepaCompraValidada;
  rResultado: TResultadoSepaRemesaCompra;
  sArchivo: string;
begin
  rFichero := dmmRemesasCompra.LeerFicheroSepa;
  if ConfirmarRegeneracionSepa(rFichero) and
     ElegirFormatoSepa(rFichero, eFormato) then
  begin
    rRemesa := dmmRemesasCompra.PrepararRemesaSepa(eFormato);
    if ConfirmarAvisosSepa(rRemesa) and ElegirArchivoSepa(sArchivo) then
    begin
      Screen.Cursor := crHourGlass;
      try
        rResultado := dmmRemesasCompra.GenerarOrdenSepa(rRemesa, sArchivo);
      finally
        Screen.Cursor := crDefault;
      end;
      ActualizarBancoPago;
      ShowMessage_fza(Format(SInfoSepaRemesaCompraGenerada,
        [rResultado.NumPagos, CurrToStrF(rResultado.Total, ffCurrency, 2),
         sLineBreak + sLineBreak]));
    end;
  end;
end;

procedure TfrmMtoRemesasCompra.btnGenerarSepaClick(Sender: TObject);
begin
  inherited;
  if not RemesaSeleccionada then
    ShowMessage_fza(SErrorRemesaCompraNoSeleccionada)
  else if not BancoRemesaAsignado then
    ShowMessage_fza(SErrorRemesaCompraSepaSinBancoPago)
  else if dmmRemesasCompra.PendienteRemesa <= 0.0001 then
    ShowMessage_fza(SErrorRemesaCompraSinImportePendiente)
  else
  begin
    try
      GenerarSepaRemesa;
    except
      on E: Exception do
        ShowMessage_fza(Format(SErrorGenerarSepaRemesaCompra, [E.Message]));
    end;
  end;
end;

procedure TfrmMtoRemesasCompra.btnReabrirRemesaClick(Sender: TObject);
begin
  inherited;
  if not RemesaSeleccionada then
    ShowMessage_fza(SErrorRemesaCompraNoSeleccionada)
  else if (not dmmRemesasCompra.RemesaGenerada) or
          dmmRemesasCompra.RemesaTieneCargo then
    ShowMessage_fza(SErrorRemesaCompraNoGenerada)
  else if MessageDlg_fza(SPreguntaReabrirRemesaCompra, mtWarning,
          [mbYes, mbNo], 0, mbNo) = mrYes then
  begin
    if dmmRemesasCompra.ReabrirRemesa then
      ShowMessage_fza(SInfoRemesaCompraReabierta)
    else
      ShowMessage_fza(SErrorRemesaCompraNoGenerada);
    ActualizarBancoPago;
  end;
end;

initialization
  RegistrarPantalla(TfrmMtoRemesasCompra);
  ForceReferenceToClass(TfrmMtoRemesasCompra);
end.
