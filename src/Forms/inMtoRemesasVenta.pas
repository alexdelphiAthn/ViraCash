{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoRemesasVenta                                             }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       10/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Remesas de cobro que agrupan efectos (consulta).                          }
{******************************************************************************}
unit inMtoRemesasVenta;

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
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataRemesasVenta,
  cxCheckBox, cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, Vcl.AppEvnts, JvComponentBase, JvEnterTab, dxShellDialogs,
  cxDBEdit, cxMaskEdit, cxDropDownEdit, cxCalendar, cxCurrencyEdit, cxMemo,
  cxLookupEdit, cxDBLookupEdit, cxDBLookupComboBox,
  inLibPermisosIntf,
  inLibCargaEfectosRemesaPersistenciaIntf;

type
  TfrmMtoRemesasVenta = class(TfrmMtoGen)
    dbcGrdDBTabPrinNUMERO_REMV: TcxGridDBColumn;
    dbcGrdDBTabPrinSERIE_REMV: TcxGridDBColumn;
    dbcGrdDBTabPrinFECHA_REMV: TcxGridDBColumn;
    dbcGrdDBTabPrinESTADO_REMV: TcxGridDBColumn;
    dbcGrdDBTabPrinCODIGO_EMP_REMV: TcxGridDBColumn;
    dbcGrdDBTabPrinRAZON_SOCIAL_EMPRESA_VIEW_REMV: TcxGridDBColumn;
    dbcGrdDBTabPrinCONTADOR_EFECTOS_REMV: TcxGridDBColumn;
    dbcGrdDBTabPrinTOTAL_REMV: TcxGridDBColumn;
    dbcGrdDBTabPrinFECHA_CARGO_REMV: TcxGridDBColumn;
    dbcGrdDBTabPrinIBAN_REMV: TcxGridDBColumn;
    pnlFichaCabecera: TPanel;
    lblNumero: TcxLabel;
    txtNUMERO_REMV: TcxDBTextEdit;
    lblSerie: TcxLabel;
    txtSERIE_REMV: TcxDBTextEdit;
    lblFecha: TcxLabel;
    dteFECHA_REMV: TcxDBDateEdit;
    lblEstado: TcxLabel;
    txtESTADO_REMV: TcxDBTextEdit;
    lblEmpresa: TcxLabel;
    txtCODIGO_EMP_REMV: TcxDBTextEdit;
    lblRazonSocial: TcxLabel;
    txtRAZON_SOCIAL_EMPRESA_VIEW_REMV: TcxDBTextEdit;
    lblTotal: TcxLabel;
    curTOTAL_REMV: TcxDBCurrencyEdit;
    lblContadorEfectos: TcxLabel;
    txtCONTADOR_EFECTOS_REMV: TcxDBTextEdit;
    lblFechaCobro: TcxLabel;
    dteFECHA_CARGO_REMV: TcxDBDateEdit;
    lblIBAN: TcxLabel;
    txtIBAN_REMV: TcxDBTextEdit;
    lblCobroRealizado: TcxLabel;
    curTOTAL_COBRADO_REMV: TcxDBCurrencyEdit;
    lblPendienteCobro: TcxLabel;
    curTOTAL_PENDIENTE_REMV: TcxDBCurrencyEdit;
    lblBancoCobro: TcxLabel;
    cbbBancoCobroRemesa: TcxLookupComboBox;
    lblObservaciones: TcxLabel;
    memOBSERVACIONES_REMV: TcxDBMemo;
    pnlFichaDetalle: TPanel;
    pnlEfectosTitulo: TPanel;
    lblEfectosRemesa: TcxLabel;
    cxgrdEfectosRemesa: TcxGrid;
    tvEfectosRemesa: TcxGridDBTableView;
    tvEfectosRemesaNUMERO_FAC_EFV: TcxGridDBColumn;
    tvEfectosRemesaSERIE_FAC_EFV: TcxGridDBColumn;
    tvEfectosRemesaNUMERO_EFV: TcxGridDBColumn;
    tvEfectosRemesaCLIENTE_VIEW_EFV: TcxGridDBColumn;
    tvEfectosRemesaDESCRIPCION_TEFE_VIEW_EFV: TcxGridDBColumn;
    tvEfectosRemesaFECHA_VENCIMIENTO_EFV: TcxGridDBColumn;
    tvEfectosRemesaIMPORTE_EFV: TcxGridDBColumn;
    tvEfectosRemesaIMPORTE_COBRADO_EFV: TcxGridDBColumn;
    tvEfectosRemesaIMPORTE_PENDIENTE_EFV: TcxGridDBColumn;
    tvEfectosRemesaESTADO_EFV: TcxGridDBColumn;
    tvEfectosRemesaREFERENCIA_DOCUMENTO_EFV: TcxGridDBColumn;
    tvEfectosRemesaFECHA_COBRO_EFV: TcxGridDBColumn;
    tvEfectosRemesaDOC_EXTERNO_EFV: TcxGridDBColumn;
    lvlEfectosRemesa: TcxGridLevel;
    btnAnadirEfecto: TcxButton;
    btnQuitarEfecto: TcxButton;
    btnCobrarEfecto: TcxButton;
    btnCobrarRemesa: TcxButton;
    btnAsignarBanco: TcxButton;
    btnFechaCobro: TcxButton;
    btnGenerarSepa: TcxButton;
    dbcGrdDBTabPrinTOTAL_COBRADO_REMV: TcxGridDBColumn;
    dbcGrdDBTabPrinTOTAL_PENDIENTE_REMV: TcxGridDBColumn;
    procedure btnAnadirEfectoClick(Sender: TObject);
    procedure btnQuitarEfectoClick(Sender: TObject);
    procedure btnCobrarEfectoClick(Sender: TObject);
    procedure btnCobrarRemesaClick(Sender: TObject);
    procedure btnAsignarBancoClick(Sender: TObject);
    procedure btnFechaCobroClick(Sender: TObject);
    procedure btnGenerarSepaClick(Sender: TObject);
    procedure dteFECHA_CARGO_REMVClick(Sender: TObject);
  private
    FRepositorioCargaEfectos: IRepositorioCargaEfectosRemesa;
    procedure ActualizarBancoCobro;
    procedure actCrearRemesaExecute(Sender: TObject);
    procedure actEliminarRemesaExecute(Sender: TObject);
    procedure dsTablaGDataChangeHook(Sender: TObject; Field: TField);
    function CrearRemesaDesdeEfectos: Boolean;
    function EliminarRemesaActual: Boolean;
    procedure nvNavegadorButtonsButtonClick(Sender: TObject;
      AButtonIndex: Integer; var ADone: Boolean);
    function BancoRemesaAsignado: Boolean;
    function PedirFechaCobroRemesa: Boolean;
    function RemesaSeleccionada: Boolean;
  public
    dmmRemesasVenta: TdmRemesasVenta;
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
  inLibWin,
  inMtoModalCargarEfectosRemesa, inMtoModalRegistrarPago,
  inMtoModalSepaRemesaVenta, inLibSepaRemesasVenta,
  inLibMsgVentas;

{$R *.dfm}

resourcestring
  SNombreArchivoOrdenSepaRemesaVenta = 'remesa_cobro_%s_%s';
  SFiltroArchivoOrdenSepa = 'Orden SEPA XML (*.xml)|*.xml';

constructor TfrmMtoRemesasVenta.Create(
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

function LimpiarNombreArchivo(const AValor: string): string;
var
  i: Integer;
begin
  Result := Trim(AValor);
  for i := 1 to Length(Result) do
  begin
    if CharInSet(Result[i], ['\', '/', ':', '*', '?', '"', '<', '>', '|']) then
      Result[i] := '_';
  end;
  if Result = '' then
    Result := 'remesa';
end;

procedure TfrmMtoRemesasVenta.CrearTablaPrincipal;
begin
  inherited;
  dmmRemesasVenta := tdmDataModule as TdmRemesasVenta;
  tvEfectosRemesa.DataController.DataSource :=
    dmmRemesasVenta.dsEfectosRemesa;
  dmmRemesasVenta.unqryEfectosRemesa.MasterSource := dsTablaG;
  dmmRemesasVenta.unqryBancosEmpresa.MasterSource := dsTablaG;
  cbbBancoCobroRemesa.Properties.ListSource :=
    dmmRemesasVenta.dsBancosEmpresa;
  cbbBancoCobroRemesa.Properties.KeyFieldNames := 'CODIGO_EMPBAN';
  cbbBancoCobroRemesa.Properties.ListFieldNames := 'BANCO_VIEW_EMPBAN';
  dsTablaG.OnDataChange := dsTablaGDataChangeHook;
  actInsertarRegistro.Caption := SCaptionCrearRemesa;
  actInsertarRegistro.OnExecute := actCrearRemesaExecute;
  // La tabla principal es la vista vi_remesas_venta (JOIN, solo lectura): el
  // DELETE estandar del dataset falla, asi que el borrado se hace a mano.
  actEliminarRegistro.OnExecute := actEliminarRemesaExecute;
  nvNavegador.Buttons.Insert.Hint := SCaptionCrearRemesa;
  nvNavegador.Buttons.OnButtonClick := nvNavegadorButtonsButtonClick;
  pkFieldName := 'NUMERO_REMV;SERIE_REMV';
end;

procedure TfrmMtoRemesasVenta.ResetForm;
begin
  inherited;
end;

function TfrmMtoRemesasVenta.RemesaSeleccionada: Boolean;
begin
  Result := Assigned(dmmRemesasVenta) and
            dmmRemesasVenta.unqryTablaG.Active and
            (not dmmRemesasVenta.unqryTablaG.IsEmpty);
end;

function TfrmMtoRemesasVenta.CrearRemesaDesdeEfectos: Boolean;
var
  frm: TfrmModalCargarEfectosRemesa;
  sSerie: string;
  sNumero: string;
begin
  Result := False;
  frm := TfrmModalCargarEfectosRemesa.CrearParaVenta(
    nil,
    FRepositorioCargaEfectos);
  try
    frm.PrepararNuevaRemesa(UbicacionSesion.Empresa);
    if frm.ShowModal = mrOk then
    begin
      sSerie := frm.RemesaSerie;
      sNumero := frm.RemesaNumero;
      dmmRemesasVenta.RefrescarDatos;
      if (sSerie <> '') and (sNumero <> '') and
         dmmRemesasVenta.unqryTablaG.Active then
        dmmRemesasVenta.unqryTablaG.Locate('SERIE_REMV;NUMERO_REMV',
          VarArrayOf([sSerie, sNumero]), []);
      ActualizarBancoCobro;
      pcPantalla.ActivePage := tsFicha;
      Result := True;
    end;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmMtoRemesasVenta.actCrearRemesaExecute(Sender: TObject);
begin
  CrearRemesaDesdeEfectos;
end;

procedure TfrmMtoRemesasVenta.nvNavegadorButtonsButtonClick(Sender: TObject;
  AButtonIndex: Integer; var ADone: Boolean);
begin
  if AButtonIndex = NBDI_INSERT then
  begin
    ADone := True;
    CrearRemesaDesdeEfectos;
  end
  else if AButtonIndex = NBDI_DELETE then
  begin
    ADone := True;
    EliminarRemesaActual;
  end;
end;

procedure TfrmMtoRemesasVenta.actEliminarRemesaExecute(Sender: TObject);
begin
  EliminarRemesaActual;
end;

function TfrmMtoRemesasVenta.EliminarRemesaActual: Boolean;
begin
  Result := False;
  if not RemesaSeleccionada then
    ShowMessage_fza(SErrorRemesaVentaNoSeleccionada)
  else if dmmRemesasVenta.RemesaTieneCobro then
    ShowMessage_fza(SErrorEliminarRemesaVentaConCobro)
  else if MessageDlg_fza(SPreguntaEliminarRemesaVenta,
          mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    if dmmRemesasVenta.EliminarRemesa then
    begin
      ShowMessage_fza(SInfoRemesaVentaEliminada);
      ActualizarBancoCobro;
      Result := True;
    end
    else
      ShowMessage_fza(SErrorEliminarRemesaVenta);
  end;
end;

function TfrmMtoRemesasVenta.BancoRemesaAsignado: Boolean;
begin
  Result := RemesaSeleccionada and
            (Trim(dmmRemesasVenta.unqryTablaG.FieldByName('IBAN_REMV')
              .AsString) <> '');
end;

procedure TfrmMtoRemesasVenta.ActualizarBancoCobro;
var
  sIban: string;
begin
  cbbBancoCobroRemesa.EditValue := Null;
  if Assigned(dmmRemesasVenta) and dmmRemesasVenta.unqryBancosEmpresa.Active
     and RemesaSeleccionada then
  begin
    sIban := Trim(dmmRemesasVenta.unqryTablaG.FieldByName('IBAN_REMV')
      .AsString);
    if (sIban <> '') and
       dmmRemesasVenta.unqryBancosEmpresa.Locate('IBAN_EMPBAN', sIban, []) then
      cbbBancoCobroRemesa.EditValue :=
        dmmRemesasVenta.unqryBancosEmpresa.FieldByName('CODIGO_EMPBAN')
          .AsString
    else if (sIban = '') and
            (not dmmRemesasVenta.unqryBancosEmpresa.IsEmpty) then
    begin
      dmmRemesasVenta.unqryBancosEmpresa.First;
      cbbBancoCobroRemesa.EditValue :=
        dmmRemesasVenta.unqryBancosEmpresa.FieldByName('CODIGO_EMPBAN')
          .AsString;
    end;
  end;
end;

procedure TfrmMtoRemesasVenta.dsTablaGDataChangeHook(Sender: TObject;
  Field: TField);
begin
  if Field = nil then
    ActualizarBancoCobro;
end;

procedure TfrmMtoRemesasVenta.btnAnadirEfectoClick(Sender: TObject);
var
  frm: TfrmModalCargarEfectosRemesa;
  q: TDataSet;
begin
  inherited;
  if not RemesaSeleccionada then
    CrearRemesaDesdeEfectos
  else if dmmRemesasVenta.RemesaTieneCobro then
    ShowMessage_fza(SErrorAnadirEfectosRemesaVentaConCobro)
  else
  begin
    q := dmmRemesasVenta.unqryTablaG;
    frm := TfrmModalCargarEfectosRemesa.CrearParaVenta(
      nil,
      FRepositorioCargaEfectos);
    try
      frm.PrepararRemesaExistente(q.FieldByName('CODIGO_EMP_REMV').AsString,
        q.FieldByName('SERIE_REMV').AsString,
        q.FieldByName('NUMERO_REMV').AsString);
      if frm.ShowModal = mrOk then
      begin
        dmmRemesasVenta.RefrescarDatos;
        ActualizarBancoCobro;
      end;
    finally
      frm.Free;
    end;
  end;
end;

procedure TfrmMtoRemesasVenta.btnQuitarEfectoClick(Sender: TObject);
begin
  inherited;
  if not RemesaSeleccionada then
    ShowMessage_fza(SErrorRemesaVentaNoSeleccionada)
  else if not dmmRemesasVenta.unqryEfectosRemesa.Active then
    ShowMessage_fza(SErrorEfectosRemesaVentaNoCargados)
  else if dmmRemesasVenta.unqryEfectosRemesa.IsEmpty then
    ShowMessage_fza(SErrorEfectoRemesaVentaNoSeleccionado)
  else if dmmRemesasVenta.RemesaTieneCobro then
    ShowMessage_fza(SErrorQuitarEfectosRemesaVentaConCobro)
  else if MessageDlg_fza(SPreguntaQuitarEfectoRemesaVenta,
          mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    if dmmRemesasVenta.QuitarEfectoActual then
      ShowMessage_fza(SInfoEfectoRemesaVentaQuitado)
    else
      ShowMessage_fza(SErrorQuitarEfectoRemesaVenta);
    ActualizarBancoCobro;
  end;
end;

procedure TfrmMtoRemesasVenta.btnCobrarEfectoClick(Sender: TObject);
var
  frm: TfrmModalRegistrarPago;
  q: TDataSet;
  iRes: Integer;
  fPend: Double;
begin
  inherited;
  if not RemesaSeleccionada then
    ShowMessage_fza(SErrorRemesaVentaNoSeleccionada)
  else if not BancoRemesaAsignado then
    ShowMessage_fza(SErrorBancoCobroRemesaNoAsignado)
  else if not dmmRemesasVenta.unqryEfectosRemesa.Active then
    ShowMessage_fza(SErrorEfectosRemesaVentaNoCargados)
  else if dmmRemesasVenta.unqryEfectosRemesa.IsEmpty then
    ShowMessage_fza(SErrorEfectoRemesaVentaNoSeleccionado)
  else
  begin
    q := dmmRemesasVenta.unqryEfectosRemesa;
    fPend := q.FieldByName('IMPORTE_PENDIENTE_EFV').AsFloat;
    if fPend <= 0.0001 then
      ShowMessage_fza(SErrorEfectoRemesaVentaSinPendiente)
    else
    begin
      frm := TfrmModalRegistrarPago.Create(nil);
      try
        frm.SetDatos(Format(STextoEfectoPendienteRemesaVenta,
          [q.FieldByName('NUMERO_EFV').AsInteger, fPend]), fPend);
        if frm.ShowModal = mrOk then
        begin
          iRes := dmmRemesasVenta.RegistrarCobroEfectoActual(frm.Fecha,
            frm.Importe, frm.Tipo, frm.Referencia);
          if iRes > 0 then
            ShowMessage_fza(SInfoEfectoRemesaVentaConciliado)
          else
            ShowMessage_fza(SErrorConciliarEfectoRemesaVenta);
          ActualizarBancoCobro;
        end;
      finally
        frm.Free;
      end;
    end;
  end;
end;

procedure TfrmMtoRemesasVenta.btnCobrarRemesaClick(Sender: TObject);
var
  frm: TfrmModalRegistrarPago;
  iRes: Integer;
  fPend: Double;
begin
  inherited;
  if not RemesaSeleccionada then
    ShowMessage_fza(SErrorRemesaVentaNoSeleccionada)
  else if not BancoRemesaAsignado then
    ShowMessage_fza(SErrorBancoCobroRemesaNoAsignado)
  else
  begin
    fPend := dmmRemesasVenta.PendienteRemesa;
    if fPend <= 0.0001 then
      ShowMessage_fza(SErrorRemesaVentaSinImportePendiente)
    else
    begin
      frm := TfrmModalRegistrarPago.Create(nil);
      try
        frm.SetDatos(Format(STextoRemesaVentaPendiente, [fPend]), fPend);
        if frm.ShowModal = mrOk then
        begin
          iRes := dmmRemesasVenta.RegistrarCobroRemesa(frm.Fecha,
            frm.Importe, frm.Tipo, frm.Referencia);
          if iRes > 0 then
            ShowMessage_fza(Format(SInfoEfectosRemesaVentaConciliados,
                               [iRes]))
          else
            ShowMessage_fza(SErrorConciliarRemesaVenta);
          ActualizarBancoCobro;
        end;
      finally
        frm.Free;
      end;
    end;
  end;
end;

procedure TfrmMtoRemesasVenta.btnAsignarBancoClick(Sender: TObject);
var
  sCodigo: string;
begin
  inherited;
  if not RemesaSeleccionada then
    ShowMessage_fza(SErrorRemesaVentaNoSeleccionada)
  else
  begin
    sCodigo := VarToStr(cbbBancoCobroRemesa.EditValue);
    if sCodigo = '' then
      ShowMessage_fza(SErrorBancoCobroNoSeleccionado)
    else if dmmRemesasVenta.AsignarBancoRemesa(sCodigo) then
    begin
      ShowMessage_fza(SInfoBancoCobroRemesaAsignado);
      ActualizarBancoCobro;
    end
    else
      ShowMessage_fza(SErrorAsignarBancoCobroRemesa);
  end;
end;

procedure TfrmMtoRemesasVenta.btnFechaCobroClick(Sender: TObject);
begin
  inherited;
  PedirFechaCobroRemesa;
end;

procedure TfrmMtoRemesasVenta.dteFECHA_CARGO_REMVClick(Sender: TObject);
begin
  PedirFechaCobroRemesa;
end;

function TfrmMtoRemesasVenta.PedirFechaCobroRemesa: Boolean;
var
  sFecha: string;
  dFecha: TDateTime;
begin
  Result := False;
  if not RemesaSeleccionada then
    ShowMessage_fza(SErrorRemesaVentaNoSeleccionada)
  else
  begin
    sFecha := FormatDateTime('dd/mm/yyyy', Date);
    if not dmmRemesasVenta.unqryTablaG.FieldByName('FECHA_CARGO_REMV')
       .IsNull then
      sFecha := FormatDateTime('dd/mm/yyyy',
        dmmRemesasVenta.unqryTablaG.FieldByName('FECHA_CARGO_REMV')
          .AsDateTime);
    if InputQuery_fza(STituloFechaCobroRemesa, SSolicitudFechaCobroRemesa,
                      sFecha) then
    begin
      if TryStrToDate(sFecha, dFecha) then
      begin
        if dmmRemesasVenta.ActualizarFechaCobro(dFecha) then
        begin
          ShowMessage_fza(SInfoFechaCobroRemesaActualizada);
          Result := True;
        end
        else
          ShowMessage_fza(SErrorActualizarFechaCobroRemesa);
        ActualizarBancoCobro;
      end
      else
        ShowMessage_fza(SErrorFechaCobroRemesaNoValida);
    end;
  end;
end;

procedure TfrmMtoRemesasVenta.btnGenerarSepaClick(Sender: TObject);
var
  bSeguir: Boolean;
  dlg: TSaveDialog;
  iCobros: Integer;
  rDatosSepa: TDatosSepaRemesaVenta;
  sNombre: string;
begin
  inherited;
  if not RemesaSeleccionada then
    ShowMessage_fza(SErrorRemesaVentaNoSeleccionada)
  else if not BancoRemesaAsignado then
    ShowMessage_fza(SErrorBancoCobroRemesaNoAsignado)
  else
  begin
    bSeguir := True;
    if dmmRemesasVenta.unqryTablaG.FieldByName('FECHA_CARGO_REMV').IsNull then
      bSeguir := PedirFechaCobroRemesa;
    if bSeguir then
    begin
      if dmmRemesasVenta.PendienteRemesa <= 0.0001 then
        ShowMessage_fza(SErrorRemesaVentaSinImportePendiente)
      else
      begin
        try
          dmmRemesasVenta.CargarDatosSepa(rDatosSepa);
          if TfrmModalSepaRemesaVenta.Ejecutar(rDatosSepa) then
          begin
            dmmRemesasVenta.GuardarDatosSepa(rDatosSepa);
            sNombre := Format(SNombreArchivoOrdenSepaRemesaVenta,
              [dmmRemesasVenta.unqryTablaG.FieldByName(
                 'SERIE_REMV').AsString,
               dmmRemesasVenta.unqryTablaG.FieldByName(
                 'NUMERO_REMV').AsString]);
            dlg := TSaveDialog.Create(nil);
            try
              dlg.DefaultExt := 'xml';
              dlg.Filter := SFiltroArchivoOrdenSepa;
              dlg.FileName := LimpiarNombreArchivo(sNombre) + '.xml';
              if dlg.Execute then
              begin
                Screen.Cursor := crHourGlass;
                try
                  iCobros := dmmRemesasVenta.GenerarOrdenSepa(dlg.FileName);
                finally
                  Screen.Cursor := crDefault;
                end;
                ShowMessage_fza(Format(SInfoOrdenSepaRemesaVentaGenerada,
                  [iCobros]));
                ActualizarBancoCobro;
              end;
            finally
              dlg.Free;
            end;
          end;
        except
          on E: Exception do
          begin
            if Screen.Cursor <> crDefault then
              Screen.Cursor := crDefault;
            ShowMessage_fza(Format(SErrorGenerarOrdenSepaRemesaVenta,
                               [E.Message]));
          end;
        end;
      end;
    end;
  end;
end;

initialization
  RegistrarPantalla(TfrmMtoRemesasVenta);
  ForceReferenceToClass(TfrmMtoRemesasVenta);
end.
