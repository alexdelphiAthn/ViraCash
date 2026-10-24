{******************************************************************************}
{  Módulo: inMtoModalCorregirPago                                              }
{  Tipo: Formulario modal de Caja                                              }
{  Versión: 1.0.0                                                              }
{  Fecha: 15/09/2026                                                           }
{  Descripción: Selecciona el cobro, su medio correcto y el motivo.            }
{******************************************************************************}
unit inMtoModalCorregirPago;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, cxControls,
  cxContainer, cxEdit, cxTextEdit, cxMaskEdit, cxDropDownEdit, cxButtons,
  cxLabel, inMtoFrmBase, inLibCorreccionPagoIntf;

type
  TfrmModalCorregirPago = class(TfrmBase)
    lblCobro: TcxLabel;
    cboCobro: TcxComboBox;
    lblMedio: TcxLabel;
    cboMedio: TcxComboBox;
    lblReferencia: TcxLabel;
    edtReferencia: TcxTextEdit;
    lblMotivo: TcxLabel;
    edtMotivo: TcxTextEdit;
    lblResumen: TcxLabel;
    btnGuardar: TcxButton;
    btnCancelar: TcxButton;
    procedure btnGuardarClick(Sender: TObject);
    procedure SeleccionChange(Sender: TObject);
  private
    FServicio: ICorreccionPago;
    FOperacion: TOperacionCorreccionPago;
    FCobros: TArray<TCobroCorregible>;
    FMedios: TArray<TMedioCorreccionPago>;
    procedure ActualizarSeleccion;
    procedure Preparar;
    function Solicitud: TSolicitudCorreccionPago;
    procedure Guardar;
  public
    class function Ejecutar(AOwner: TComponent;
      const AServicio: ICorreccionPago;
      const AOperacion: TOperacionCorreccionPago): Boolean;
  end;

implementation

{$R *.dfm}

uses
  System.SysUtils, inLibMensajesVcl, inLibMsgCaja;

class function TfrmModalCorregirPago.Ejecutar(AOwner: TComponent;
  const AServicio: ICorreccionPago;
  const AOperacion: TOperacionCorreccionPago): Boolean;
var
  Formulario: TfrmModalCorregirPago;
begin
  Formulario := TfrmModalCorregirPago.Create(AOwner);
  try
    Formulario.FServicio := AServicio;
    Formulario.FOperacion := AOperacion;
    Formulario.Preparar;
    Result := Formulario.ShowModal = mrOk;
  finally
    FreeAndNil(Formulario);
  end;
end;

procedure TfrmModalCorregirPago.Preparar;
var
  Cobro: TCobroCorregible;
  Medio: TMedioCorreccionPago;
begin
  Caption := SCaptionCorregirPago;
  lblCobro.Caption := SCaptionCorreccionPagoCobro;
  lblMedio.Caption := SCaptionCorreccionPagoMedio;
  lblReferencia.Caption := SCaptionCorreccionPagoReferencia;
  lblMotivo.Caption := SCaptionCorreccionPagoMotivo;
  btnGuardar.Caption := SCaptionCorregirPago;
  btnCancelar.Caption := SCaptionCorreccionPagoCancelar;
  FCobros := FServicio.Cobros(FOperacion);
  FMedios := FServicio.Medios;
  for Cobro in FCobros do
    cboCobro.Properties.Items.Add(Format(SItemCorreccionPago,
      [Cobro.Serie, Cobro.Linea, Cobro.Descripcion, Cobro.ImporteNeto]));
  for Medio in FMedios do
    cboMedio.Properties.Items.Add(Medio.Codigo + ' - ' + Medio.Descripcion);
  if Length(FCobros) > 0 then
    cboCobro.ItemIndex := 0;
  SeleccionChange(nil);
end;

function TfrmModalCorregirPago.Solicitud: TSolicitudCorreccionPago;
begin
  if (cboCobro.ItemIndex < 0) or (cboMedio.ItemIndex < 0) then
    raise EArgumentException.Create(SErrorCorreccionPagoSeleccion);
  Result := Default(TSolicitudCorreccionPago);
  Result.Operacion := FOperacion;
  Result.Serie := FCobros[cboCobro.ItemIndex].Serie;
  Result.Linea := FCobros[cboCobro.ItemIndex].Linea;
  Result.FormaPago := FMedios[cboMedio.ItemIndex].Codigo;
  Result.Referencia := Trim(edtReferencia.Text);
  Result.Motivo := Trim(edtMotivo.Text);
end;

procedure TfrmModalCorregirPago.SeleccionChange(Sender: TObject);
begin
  ActualizarSeleccion;
end;

procedure TfrmModalCorregirPago.ActualizarSeleccion;
var
  Cobro: TCobroCorregible;
begin
  btnGuardar.Enabled := (cboCobro.ItemIndex >= 0) and
    (cboMedio.ItemIndex >= 0);
  lblResumen.Caption := SAvisoCorreccionPagoSinCobros;
  if cboCobro.ItemIndex >= 0 then
  begin
    Cobro := FCobros[cboCobro.ItemIndex];
    lblResumen.Caption := Format(SResumenCorreccionPago,
      [Cobro.ImporteNeto, Cobro.Descripcion, Cobro.ImporteNeto]);
  end;
  lblReferencia.Caption := SCaptionCorreccionPagoReferencia;
  if (cboMedio.ItemIndex >= 0) and
     FMedios[cboMedio.ItemIndex].RequiereReferencia then
    lblReferencia.Caption := SCaptionCorreccionPagoReferenciaObligatoria;
end;

procedure TfrmModalCorregirPago.Guardar;
begin
  FServicio.Corregir(Solicitud);
  ModalResult := mrOk;
end;

procedure TfrmModalCorregirPago.btnGuardarClick(Sender: TObject);
begin
  try
    Guardar;
  except
    on E: EArgumentException do
      ShowMessage_fza(E.Message);
    on E: EInvalidOpException do
      ShowMessage_fza(E.Message);
  end;
end;

end.
