{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalCambioArticuloColor                                 }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       21/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Permite cambiar el código de un artículo o un valor de color.             }
{******************************************************************************}
unit inMtoModalCambioArticuloColor;

interface

uses
  System.Actions, System.Classes, System.SysUtils, System.UITypes,
  Vcl.ActnList, Vcl.Controls, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Forms,
  cxButtons, cxContainer, cxControls, cxEdit, cxGraphics, cxGroupBox,
  cxLabel, cxLookAndFeelPainters, cxLookAndFeels, cxTextEdit,
  inMtoFrmBase, inLibCambioArticuloColorIntf,
  inLibCambioArticuloColorHistoricoConsultaIntf;

type
  TfrmModalCambioArticuloColor = class(TfrmBase)
    pnlPrincipal: TPanel;
    lblIntroduccion: TcxLabel;
    gbArticulo: TcxGroupBox;
    lblArticuloAntiguo: TcxLabel;
    txtArticuloAntiguo: TcxTextEdit;
    lblArticuloNuevo: TcxLabel;
    txtArticuloNuevo: TcxTextEdit;
    btnCambiarArticulo: TcxButton;
    gbColor: TcxGroupBox;
    lblColorAntiguo: TcxLabel;
    txtColorAntiguo: TcxTextEdit;
    lblColorNuevo: TcxLabel;
    txtColorNuevo: TcxTextEdit;
    btnCambiarColor: TcxButton;
    lblAdvertencia: TcxLabel;
    pnlBotones: TPanel;
    btnHistorico: TcxButton;
    btnCerrar: TcxButton;
    alAcciones: TActionList;
    actCambiarArticulo: TAction;
    actCambiarColor: TAction;
    actHistorico: TAction;
    actCerrar: TAction;
    procedure FormCreate(Sender: TObject);
    procedure actCambiarArticuloExecute(Sender: TObject);
    procedure actCambiarColorExecute(Sender: TObject);
    procedure actHistoricoExecute(Sender: TObject);
    procedure actCerrarExecute(Sender: TObject);
  private
    FServicio: IServicioCambioArticuloColor;
    FConsultaHistorico: IConsultaCambioArticuloColorHistorico;
    FUsuario: string;
    function ConfirmarCambio(
      const ATipo, AOrigen, ADestino: string): Boolean;
    function ConfirmarFusionArticulo(
      const AOrigen, ADestino: string): Boolean;
    function ConfirmarFusionColor(
      const AOrigen, ADestino: string): Boolean;
    function MensajeResultado(
      const AResultado: TResultadoCambioArticuloColor): string;
    function TipoMensajeResultado(
      const AResultado: TResultadoCambioArticuloColor): TMsgDlgType;
    procedure CambiarArticulo;
    procedure CambiarColor;
    procedure MostrarErrorInesperado(const AMensaje: string);
    procedure MostrarHistorico;
    procedure MostrarResultado(
      const AResultado: TResultadoCambioArticuloColor);
  public
    class procedure Ejecutar(
      AOwner: TComponent;
      const AServicio: IServicioCambioArticuloColor;
      const AConsultaHistorico: IConsultaCambioArticuloColorHistorico;
      const AUsuario: string);
  end;

implementation

uses
  inLibMensajesVcl,
  inMtoModalCambioArticuloColorHistorico;

{$R *.dfm}

resourcestring
  SPreguntaConfirmarCambio =
    '¿Confirma el cambio de %s "%s" por "%s" en todos los documentos ' +
    'relacionados?' + sLineBreak + sLineBreak +
    'Si existen ventas, la operación se cancelará por completo.' +
    sLineBreak + sLineBreak +
    'Ejecute esta utilidad sin otros usuarios trabajando y haga que ' +
    'reinicien ViraCash al terminar.';
  SAdvertenciaCambioColor =
    sLineBreak + sLineBreak + 'Se conservará el color básico y se ' +
    'reiniciarán las descripciones específicas del color.';
  STipoArticuloCambio = 'artículo';
  STipoColorCambio = 'color';
  SInfoCambioCorrecto =
    'El cambio se ha completado correctamente. Unidades afectadas: %d.';
  SErrorDatosCambioInvalidos =
    'Los datos introducidos no son válidos. Revise los valores antiguo y ' +
    'nuevo.';
  SErrorOrigenCambioNoExiste =
    'No existe el artículo o color antiguo indicado.';
  SErrorDestinoCambioYaExiste =
    'El artículo o color destino ya existe. No se ha realizado el cambio ' +
    'ni la fusión.';
  SPreguntaFusionarArticulo =
    'El artículo destino "%s" ya existe.' + sLineBreak + sLineBreak +
    '¿Desea fusionar "%s" dentro de ese artículo?' + sLineBreak +
    sLineBreak + 'El artículo y sus SKU antiguos se conservarán ' +
    'desactivados. Los documentos y movimientos pasarán al destino; el ' +
    'PMP se recalculará por empresa y almacén con todo el histórico ' +
    'combinado y prevalecerá la tarifa de venta más reciente. Si existe ' +
    'una factura o una colisión ' +
    'no conciliable, se cancelará toda la operación.';
  SPreguntaFusionarColor =
    'El color destino "%s" ya existe.' + sLineBreak + sLineBreak +
    '¿Desea fusionar el color "%s" con él?' + sLineBreak + sLineBreak +
    'Los SKU antiguos se conservarán desactivados y se perderá la ' +
    'clasificación de color básico del color fusionado. Los movimientos ' +
    'y el PMP se recalcularán históricamente por empresa y almacén. Si ' +
    'existe una factura o una colisión ' +
    'no conciliable, se cancelará toda la operación.';
  SErrorVentasImpidenCambio =
    'No se ha realizado ningún cambio porque existen ventas asociadas. ' +
    'La operación se ha cancelado por completo y no se puede forzar.';
  SErrorColisionUnidadesCambio =
    'El cambio produciría unidades o SKU duplicados, ambiguos o de más ' +
    'de 50 caracteres. No se ha modificado ningún dato.';
  SErrorDatosCambioInconsistentes =
    'Se han encontrado datos relacionados inconsistentes. La operación se ' +
    'ha cancelado por completo.';
  SErrorIntegracionExternaCambio =
    'No se ha realizado el cambio porque el artículo o color está ' +
    'publicado o pendiente de sincronización con PrestaShop.';
  SErrorCambioDesconocido =
    'No se ha podido determinar el resultado del cambio.';
  SErrorCambioInesperado =
    'No se ha podido confirmar el estado final de la operación. Compruebe ' +
    'el resultado antes de volver a intentarlo.' + sLineBreak + sLineBreak +
    '%s';

procedure ForceReferenceToClass(C: TClass);
begin
end;

function TfrmModalCambioArticuloColor.ConfirmarFusionArticulo(
  const AOrigen, ADestino: string): Boolean;
begin
  Result := MessageDlg_fza(
    Format(SPreguntaFusionarArticulo, [ADestino, AOrigen]),
    mtWarning,
    [mbYes, mbNo],
    0) = mrYes;
end;

function TfrmModalCambioArticuloColor.ConfirmarFusionColor(
  const AOrigen, ADestino: string): Boolean;
begin
  Result := MessageDlg_fza(
    Format(SPreguntaFusionarColor, [ADestino, AOrigen]),
    mtWarning,
    [mbYes, mbNo],
    0) = mrYes;
end;

class procedure TfrmModalCambioArticuloColor.Ejecutar(
  AOwner: TComponent;
  const AServicio: IServicioCambioArticuloColor;
  const AConsultaHistorico: IConsultaCambioArticuloColorHistorico;
  const AUsuario: string);
var
  oFormulario: TfrmModalCambioArticuloColor;
begin
  if not Assigned(AServicio) then
    raise EArgumentNilException.Create('AServicio');
  if not Assigned(AConsultaHistorico) then
    raise EArgumentNilException.Create('AConsultaHistorico');
  oFormulario := TfrmModalCambioArticuloColor.Create(AOwner);
  try
    oFormulario.FServicio := AServicio;
    oFormulario.FConsultaHistorico := AConsultaHistorico;
    oFormulario.FUsuario := Trim(AUsuario);
    oFormulario.ShowModal;
  finally
    oFormulario.FConsultaHistorico := nil;
    oFormulario.FServicio := nil;
    FreeAndNil(oFormulario);
  end;
end;

procedure TfrmModalCambioArticuloColor.FormCreate(Sender: TObject);
begin
  inherited;
  KeyPreview := True;
  Position := poMainFormCenter;
end;

function TfrmModalCambioArticuloColor.ConfirmarCambio(
  const ATipo, AOrigen, ADestino: string): Boolean;
var
  sPregunta: string;
begin
  sPregunta := Format(
    SPreguntaConfirmarCambio,
    [ATipo, AOrigen, ADestino]);
  if SameText(ATipo, STipoColorCambio) then
    sPregunta := sPregunta + SAdvertenciaCambioColor;
  Result := MessageDlg_fza(
    sPregunta,
    mtConfirmation,
    [mbYes, mbNo],
    0) = mrYes;
end;

procedure TfrmModalCambioArticuloColor.CambiarArticulo;
var
  oResultado: TResultadoCambioArticuloColor;
  sAnterior: string;
  sNuevo: string;
begin
  sAnterior := Trim(txtArticuloAntiguo.Text);
  sNuevo := Trim(txtArticuloNuevo.Text);
  if ConfirmarCambio(STipoArticuloCambio, sAnterior, sNuevo) then
  begin
    try
      Screen.Cursor := crHourGlass;
      try
        oResultado := FServicio.CambiarArticulo(
          sAnterior,
          sNuevo,
          FUsuario);
      finally
        Screen.Cursor := crDefault;
      end;
      if (oResultado.Motivo = mcacDestinoYaExiste) and
         ConfirmarFusionArticulo(sAnterior, sNuevo) then
      begin
        Screen.Cursor := crHourGlass;
        try
          oResultado := FServicio.FusionarArticulo(
            sAnterior,
            sNuevo,
            FUsuario);
        finally
          Screen.Cursor := crDefault;
        end;
      end;
      MostrarResultado(oResultado);
      if oResultado.EsCorrecto then
      begin
        txtArticuloAntiguo.Clear;
        txtArticuloNuevo.Clear;
        txtArticuloAntiguo.SetFocus;
      end;
    except
      on E: Exception do
        MostrarErrorInesperado(E.Message);
    end;
  end;
end;

procedure TfrmModalCambioArticuloColor.CambiarColor;
var
  oResultado: TResultadoCambioArticuloColor;
  sAnterior: string;
  sNuevo: string;
begin
  sAnterior := Trim(txtColorAntiguo.Text);
  sNuevo := Trim(txtColorNuevo.Text);
  if ConfirmarCambio(STipoColorCambio, sAnterior, sNuevo) then
  begin
    try
      Screen.Cursor := crHourGlass;
      try
        oResultado := FServicio.CambiarColor(
          sAnterior,
          sNuevo,
          FUsuario);
      finally
        Screen.Cursor := crDefault;
      end;
      if (oResultado.Motivo = mcacDestinoYaExiste) and
         ConfirmarFusionColor(sAnterior, sNuevo) then
      begin
        Screen.Cursor := crHourGlass;
        try
          oResultado := FServicio.FusionarColor(
            sAnterior,
            sNuevo,
            FUsuario);
        finally
          Screen.Cursor := crDefault;
        end;
      end;
      MostrarResultado(oResultado);
      if oResultado.EsCorrecto then
      begin
        txtColorAntiguo.Clear;
        txtColorNuevo.Clear;
        txtColorAntiguo.SetFocus;
      end;
    except
      on E: Exception do
        MostrarErrorInesperado(E.Message);
    end;
  end;
end;

function TfrmModalCambioArticuloColor.MensajeResultado(
  const AResultado: TResultadoCambioArticuloColor): string;
begin
  case AResultado.Motivo of
    mcacNinguno:
      Result := Format(
        SInfoCambioCorrecto,
        [AResultado.UnidadesAfectadas]);
    mcacDatosInvalidos:
      Result := SErrorDatosCambioInvalidos;
    mcacOrigenNoExiste:
      Result := SErrorOrigenCambioNoExiste;
    mcacDestinoYaExiste:
      Result := SErrorDestinoCambioYaExiste;
    mcacExistenVentas:
      Result := SErrorVentasImpidenCambio;
    mcacColisionUnidades:
      Result := SErrorColisionUnidadesCambio;
    mcacDatosInconsistentes:
      Result := SErrorDatosCambioInconsistentes;
    mcacIntegracionExterna:
      Result := SErrorIntegracionExternaCambio;
    else
      Result := SErrorCambioDesconocido;
  end;
  if (not AResultado.EsCorrecto) and
     (Trim(AResultado.Detalle) <> '') then
  begin
    Result := Result + sLineBreak + sLineBreak + AResultado.Detalle;
  end;
end;

function TfrmModalCambioArticuloColor.TipoMensajeResultado(
  const AResultado: TResultadoCambioArticuloColor): TMsgDlgType;
begin
  case AResultado.Motivo of
    mcacNinguno:
      Result := mtInformation;
    mcacDatosInvalidos,
    mcacOrigenNoExiste,
    mcacDestinoYaExiste:
      Result := mtWarning;
    mcacExistenVentas,
    mcacColisionUnidades,
    mcacDatosInconsistentes,
    mcacIntegracionExterna:
      Result := mtError;
    else
      Result := mtError;
  end;
end;

procedure TfrmModalCambioArticuloColor.MostrarErrorInesperado(
  const AMensaje: string);
begin
  MessageDlg_fza(
    Format(SErrorCambioInesperado, [AMensaje]),
    mtError,
    [mbOK],
    0);
end;

procedure TfrmModalCambioArticuloColor.MostrarHistorico;
begin
  TfrmModalHistoricoArtColor.Ejecutar(
    Self,
    FConsultaHistorico);
end;

procedure TfrmModalCambioArticuloColor.MostrarResultado(
  const AResultado: TResultadoCambioArticuloColor);
begin
  MessageDlg_fza(
    MensajeResultado(AResultado),
    TipoMensajeResultado(AResultado),
    [mbOK],
    0);
end;

procedure TfrmModalCambioArticuloColor.actCambiarArticuloExecute(
  Sender: TObject);
begin
  CambiarArticulo;
end;

procedure TfrmModalCambioArticuloColor.actCambiarColorExecute(
  Sender: TObject);
begin
  CambiarColor;
end;

procedure TfrmModalCambioArticuloColor.actHistoricoExecute(
  Sender: TObject);
begin
  MostrarHistorico;
end;

procedure TfrmModalCambioArticuloColor.actCerrarExecute(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

initialization
  ForceReferenceToClass(TfrmModalCambioArticuloColor);
end.
