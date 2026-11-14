{******************************************************************************}
{                                                                             }
{  Módulo: inMtoModalCambioCodigoCliente                                      }
{  Tipo: Formulario modal                                                     }
{  Versión: 1.0.0                                                             }
{  Fecha: 14/11/2026                                                          }
{  Autor: Alejandro Laorden Hidalgo                                           }
{                                                                             }
{  Copyright (c) Alejandro Laorden Hidalgo.                                   }
{  Descripción:                                                               }
{  Cambio de código y consulta de posibles clientes duplicados.               }
{                                                                             }
{******************************************************************************}
unit inMtoModalCambioCodigoCliente;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms,
  cxClasses, cxControls, cxContainer, cxEdit, cxLabel, cxTextEdit,
  cxButtons, cxGrid, cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, inMtoFrmBase, inLibCambioCodigoCliente;

type
  TfrmModalCambioCodigoCliente = class(TfrmBase)
    lblIntroduccion: TcxLabel;
    lblOrigen: TcxLabel;
    lblDestino: TcxLabel;
    txtOrigen: TcxTextEdit;
    txtDestino: TcxTextEdit;
    btnCambiar: TcxButton;
    btnDuplicados: TcxButton;
    btnCerrar: TcxButton;
    lblResultado: TcxLabel;
    cxgrdDuplicados: TcxGrid;
    tvDuplicados: TcxGridTableView;
    lvDuplicados: TcxGridLevel;
    colCodigo: TcxGridColumn;
    colNombre: TcxGridColumn;
    colOtroCodigo: TcxGridColumn;
    colOtroNombre: TcxGridColumn;
    colMotivo: TcxGridColumn;
    procedure FormCreate(Sender: TObject);
    procedure CambiarClick(Sender: TObject);
    procedure DuplicadosClick(Sender: TObject);
    procedure CerrarClick(Sender: TObject);
    procedure OrigenChange(Sender: TObject);
  private
    FServicio: ICambioCodigoCliente;
    FUsuario: string;
    procedure CambiarCodigo;
    procedure MostrarDuplicados(const ADuplicados: TDuplicadosClientes);
    function MensajeResultado(const AResultado: TResultadoCambioCliente):
      string;
  public
    procedure AplicarTraduccionActual; override;
    class procedure Ejecutar(AOwner: TComponent;
      const AServicio: ICambioCodigoCliente; const AUsuario: string);
  end;

implementation

uses
  System.SysUtils, System.UITypes, Vcl.Dialogs,
  inLibMensajesVcl, inLibMsgCambioCodigoCliente;

{$R *.dfm}

class procedure TfrmModalCambioCodigoCliente.Ejecutar(AOwner: TComponent;
  const AServicio: ICambioCodigoCliente; const AUsuario: string);
var
  oFormulario: TfrmModalCambioCodigoCliente;
begin
  if not Assigned(AServicio) then
    raise EArgumentNilException.Create('AServicio');
  oFormulario := TfrmModalCambioCodigoCliente.Create(AOwner);
  try
    oFormulario.FServicio := AServicio;
    oFormulario.FUsuario := AUsuario;
    oFormulario.ShowModal;
  finally
    FreeAndNil(oFormulario);
  end;
end;

procedure TfrmModalCambioCodigoCliente.FormCreate(Sender: TObject);
begin
  inherited;
  AplicarTraduccionActual;
end;

procedure TfrmModalCambioCodigoCliente.AplicarTraduccionActual;
begin
  inherited;
  Caption := SCambioClienteTitulo;
  lblIntroduccion.Caption := SCambioClienteExplicacion;
  lblOrigen.Caption := SCambioClienteOrigen;
  lblDestino.Caption := SCambioClienteDestino;
  btnCambiar.Caption := SCambioClienteCambiar;
  btnDuplicados.Caption := SCambioClienteDuplicados;
  btnCerrar.Caption := SCambioClienteCerrar;
  colCodigo.Caption := SCambioClienteCodigo;
  colNombre.Caption := SCambioClienteNombre;
  colOtroCodigo.Caption := SCambioClienteOtroCodigo;
  colOtroNombre.Caption := SCambioClienteOtroNombre;
  colMotivo.Caption := SCambioClienteMotivo;
end;

function TfrmModalCambioCodigoCliente.MensajeResultado(
  const AResultado: TResultadoCambioCliente): string;
begin
  case AResultado.Estado of
    eccCorrecto:
      Result := Format(SCambioClienteCorrecto, [AResultado.Referencias]);
    eccDatosInvalidos:
      Result := SCambioClienteDatosInvalidos;
    eccOrigenNoExiste:
      Result := SCambioClienteNoExiste;
    eccDestinoOcupado:
      Result := SCambioClienteOcupado;
    eccTransaccionActiva:
      Result := SCambioClienteTransaccion;
  else
    Result := SCambioClienteEsquema;
  end;
end;

procedure TfrmModalCambioCodigoCliente.CambiarCodigo;
var
  rResultado: TResultadoCambioCliente;
  sAnterior, sNuevo: string;
begin
  sAnterior := Trim(txtOrigen.Text);
  sNuevo := Trim(txtDestino.Text);
  if not DatosCambioClienteValidos(sAnterior, sNuevo, FUsuario) then
    ShowMessage_fza(SCambioClienteDatosInvalidos)
  else if MessageDlg_fza(Format(SCambioClientePregunta,
    [sAnterior, sNuevo]), mtConfirmation, [mbYes, mbNo], 0, mbNo) = mrYes then
  begin
    Screen.Cursor := crHourGlass;
    try
      rResultado := FServicio.Cambiar(sAnterior, sNuevo, FUsuario);
    finally
      Screen.Cursor := crDefault;
    end;
    if rResultado.Estado = eccCorrecto then
    begin
      RegistroLog.RegistrarInformacion(Format(
        'Cambio de cliente: usuario=%s; anterior=%s; nuevo=%s; refs=%d',
        [FUsuario, sAnterior, sNuevo, rResultado.Referencias]));
      txtOrigen.Text := sNuevo;
      txtDestino.Clear;
    end;
    ShowMessage_fza(MensajeResultado(rResultado));
  end;
end;

procedure TfrmModalCambioCodigoCliente.CambiarClick(Sender: TObject);
begin
  CambiarCodigo;
end;

procedure TfrmModalCambioCodigoCliente.DuplicadosClick(Sender: TObject);
begin
  Screen.Cursor := crHourGlass;
  try
    MostrarDuplicados(FServicio.DetectarDuplicados(Trim(txtOrigen.Text)));
  finally
    Screen.Cursor := crDefault;
  end;
end;

function MotivoDuplicado(const ADuplicado: TDuplicadoCliente): string;
begin
  if ADuplicado.MismoNif and ADuplicado.MismoContacto then
    Result := SCambioClienteAmbos
  else if ADuplicado.MismoNif then
    Result := SCambioClienteNif
  else
    Result := SCambioClienteContacto;
end;

procedure TfrmModalCambioCodigoCliente.MostrarDuplicados(
  const ADuplicados: TDuplicadosClientes);
var
  iFila, iCantidad: Integer;
begin
  iCantidad := Length(ADuplicados);
  if iCantidad > LIMITE_DUPLICADOS_CLIENTES then
    iCantidad := LIMITE_DUPLICADOS_CLIENTES;
  tvDuplicados.BeginUpdate;
  try
    tvDuplicados.DataController.RecordCount := iCantidad;
    for iFila := 0 to iCantidad - 1 do
    begin
      tvDuplicados.DataController.Values[iFila, 0] :=
        ADuplicados[iFila].Codigo;
      tvDuplicados.DataController.Values[iFila, 1] :=
        ADuplicados[iFila].Nombre;
      tvDuplicados.DataController.Values[iFila, 2] :=
        ADuplicados[iFila].OtroCodigo;
      tvDuplicados.DataController.Values[iFila, 3] :=
        ADuplicados[iFila].OtroNombre;
      tvDuplicados.DataController.Values[iFila, 4] :=
        MotivoDuplicado(ADuplicados[iFila]);
    end;
  finally
    tvDuplicados.EndUpdate;
  end;
  if Length(ADuplicados) > iCantidad then
    lblResultado.Caption := Format(SCambioClienteLimiteDuplicados,
      [iCantidad])
  else if iCantidad = 0 then
    lblResultado.Caption := SCambioClienteSinDuplicados
  else
    lblResultado.Caption := Format(SCambioClienteResumenDuplicados,
      [iCantidad]);
end;

procedure TfrmModalCambioCodigoCliente.OrigenChange(Sender: TObject);
begin
  tvDuplicados.DataController.RecordCount := 0;
  lblResultado.Caption := '';
end;

procedure TfrmModalCambioCodigoCliente.CerrarClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
