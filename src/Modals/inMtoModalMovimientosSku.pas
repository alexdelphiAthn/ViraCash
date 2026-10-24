{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalMovimientosSku                                      }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       1.0.0                                                         }
{   Fecha:       07/08/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Kardex de un SKU desde la consulta de stock. Permite reconstruir el       }
{    stock global y saltar al movimiento seleccionado.                         }
{******************************************************************************}
unit inMtoModalMovimientosSku;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls,
  Data.DB,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxLabel, cxButtons, cxCurrencyEdit, cxCalendar,
  cxCheckBox, cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator,
  cxDBData, cxGridLevel, cxClasses, cxStyles, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid,
  dxDateRanges, dxScrollbarAnnotations,
  inMtoFrmBase, inLibMovimientosSkuPersistenciaIntf;

type
  TfrmModalMovimientosSku = class(TfrmBase)
    pnlSuperior: TPanel;
    lblTitulo: TcxLabel;
    lblAyuda: TcxLabel;
    cxgrdMovimientos: TcxGrid;
    tvMovimientos: TcxGridDBTableView;
    cxgrdlvlMovimientos: TcxGridLevel;
    tvMovimientosNUMERO_MOV: TcxGridDBColumn;
    tvMovimientosFECHA_MOV: TcxGridDBColumn;
    tvMovimientosTIPO_DOC_MOV: TcxGridDBColumn;
    tvMovimientosSERIE_DOC_MOV: TcxGridDBColumn;
    tvMovimientosNUMERO_DOC_MOV: TcxGridDBColumn;
    tvMovimientosLINEA_MOV: TcxGridDBColumn;
    tvMovimientosCODIGO_ALM_MOV: TcxGridDBColumn;
    tvMovimientosCODIGO_ALM_CONTRA_MOV: TcxGridDBColumn;
    tvMovimientosTIPO_MOV: TcxGridDBColumn;
    tvMovimientosCANTIDAD_MOV: TcxGridDBColumn;
    tvMovimientosESACTIVO_MOV: TcxGridDBColumn;
    dsMovimientos: TDataSource;
    pnlBotones: TPanel;
    lblResultado: TcxLabel;
    btnReconstruirStock: TcxButton;
    btnIrMovimientos: TcxButton;
    btnCerrar: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure dsMovimientosDataChange(Sender: TObject; Field: TField);
    procedure btnReconstruirStockClick(Sender: TObject);
    procedure btnIrMovimientosClick(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
  private
    FCodigoSku: string;
    FDescripcionArticulo: string;
    FConsulta: IConsultaMovimientosSku;
    FRepositorio: IRepositorioMovimientosSku;
    FDatos: TDataSet;
    FNumeroNavegacion: string;
    FStockReconstruido: Boolean;
    procedure ActualizarAcciones;
    procedure ActualizarCabecera;
    procedure CargarMovimientos;
    function MovimientoSeleccionado(out ANumero: string): Boolean;
  public
    class function Ejecutar(
      AOwner: TComponent;
      const ARepositorio: IRepositorioMovimientosSku;
      const ACodigoSku, ADescripcionArticulo: string): Boolean;
  end;

implementation

uses
  inLibMensajesVcl,
  inLibShowMto, inLibMsgArticulos;

{$R *.dfm}

resourcestring
  SMovimientosSkuAyuda =
    'E = entrada   S = salida';
  SMovimientoSkuResultado = '1 movimiento';
  SMovimientosSkuResultado = '%d movimientos';
  SErrorRepositorioMovimientosSkuNoDisponible =
    'No está disponible la consulta de movimientos por SKU.';

class function TfrmModalMovimientosSku.Ejecutar(
  AOwner: TComponent;
  const ARepositorio: IRepositorioMovimientosSku;
  const ACodigoSku, ADescripcionArticulo: string): Boolean;
var
  frm: TfrmModalMovimientosSku;
begin
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create(
      SErrorRepositorioMovimientosSkuNoDisponible);
  frm := TfrmModalMovimientosSku.Create(AOwner);
  try
    frm.FRepositorio := ARepositorio;
    frm.FCodigoSku := ACodigoSku;
    frm.FDescripcionArticulo := ADescripcionArticulo;
    frm.ShowModal;
    Result := frm.FStockReconstruido;
    if frm.FNumeroNavegacion <> '' then
    begin
      if AOwner is TCustomForm then
        TCustomForm(AOwner).Hide;
      if Application.MainForm <> nil then
        ShowMto(
          Application.MainForm,
          'MovimientosAlmacen',
          frm.FNumeroNavegacion);
    end;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalMovimientosSku.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
  Self.KeyPreview := True;
  FNumeroNavegacion := '';
  FStockReconstruido := False;
  lblAyuda.Caption := SMovimientosSkuAyuda;
end;

procedure TfrmModalMovimientosSku.FormShow(Sender: TObject);
begin
  ActualizarCabecera;
  CargarMovimientos;
  ActualizarAcciones;
  if Assigned(FDatos) and FDatos.Active and
     (not FDatos.IsEmpty) and cxgrdMovimientos.CanFocus then
    cxgrdMovimientos.SetFocus;
end;

procedure TfrmModalMovimientosSku.ActualizarCabecera;
var
  sDescripcion: string;
begin
  sDescripcion := Trim(FDescripcionArticulo);
  if sDescripcion = '' then
    sDescripcion := FCodigoSku;
  lblTitulo.Caption := sDescripcion + ' · ' + FCodigoSku;
end;

procedure TfrmModalMovimientosSku.CargarMovimientos;
var
  iMovimientos: Integer;
begin
  FConsulta := FRepositorio.ConsultarMovimientos(FCodigoSku);
  if not Assigned(FConsulta) then
    raise EInvalidOpException.Create(
      SErrorRepositorioMovimientosSkuNoDisponible);
  FDatos := FConsulta.DataSet;
  if not Assigned(FDatos) then
    raise EInvalidOpException.Create(
      SErrorRepositorioMovimientosSkuNoDisponible);
  dsMovimientos.DataSet := FDatos;
  iMovimientos := 0;
  if Assigned(FDatos) and FDatos.Active and (not FDatos.IsEmpty) then
  begin
    FDatos.Last;
    iMovimientos := FDatos.RecordCount;
    FDatos.First;
  end;
  if iMovimientos = 1 then
    lblResultado.Caption := SMovimientoSkuResultado
  else
    lblResultado.Caption := Format(
      SMovimientosSkuResultado,
      [iMovimientos]);
end;

function TfrmModalMovimientosSku.MovimientoSeleccionado(
  out ANumero: string): Boolean;
begin
  ANumero := '';
  Result := Assigned(FDatos) and FDatos.Active and
            (not FDatos.IsEmpty);
  if Result then
  begin
    ANumero := Trim(FDatos.FieldByName('NUMERO_MOV').AsString);
    Result := ANumero <> '';
  end;
end;

procedure TfrmModalMovimientosSku.ActualizarAcciones;
var
  sNumero: string;
begin
  btnIrMovimientos.Enabled := MovimientoSeleccionado(sNumero);
end;

procedure TfrmModalMovimientosSku.dsMovimientosDataChange(
  Sender: TObject; Field: TField);
begin
  ActualizarAcciones;
end;

procedure TfrmModalMovimientosSku.btnReconstruirStockClick(
  Sender: TObject);
var
  sMensaje: string;
begin
  if MessageBox_fza(PChar(SPreguntaReconstruirStock),
       PChar(STituloReconstruirStock),
       MB_YESNO or MB_ICONQUESTION) = IDYES then
  begin
    Screen.Cursor := crHourGlass;
    try
      try
        sMensaje := FRepositorio.ReconstruirStock;
        FStockReconstruido := True;
        if Trim(sMensaje) = '' then
          sMensaje := SInfoStockReconstruido;
        MessageBox_fza(PChar(sMensaje),
          PChar(STituloReconstruirStock),
          MB_OK or MB_ICONINFORMATION);
      except
        on E: Exception do
          MessageBox_fza(PChar(Format(SErrorReconstruirStock, [E.Message])),
            PChar(STituloReconstruirStock),
            MB_OK or MB_ICONERROR);
      end;
    finally
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TfrmModalMovimientosSku.btnIrMovimientosClick(
  Sender: TObject);
begin
  if MovimientoSeleccionado(FNumeroNavegacion) then
    ModalResult := mrOk;
end;

procedure TfrmModalMovimientosSku.btnCerrarClick(Sender: TObject);
begin
  Close;
end;

end.
