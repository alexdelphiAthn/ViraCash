{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoFacturasSubsanacionVcl                                   }
{    Tipo:       Presentación VCL                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Integra la subsanación del registro fiscal en Factura Venta Mayor:        }
{    botón «Subsanar registro» / «Registrar subsanación» y «Cancelar           }
{    subsanación» según la fase de la factura activa.                          }
{******************************************************************************}
unit inMtoFacturasSubsanacionVcl;

interface

uses
  System.Classes,
  System.SysUtils,
  Data.DB,
  cxButtons,
  inLibFacturasSubsanacionIntf,
  inLibLogIntf,
  inLibParametrosIntf;

type
  TAccionSubsanacionFacturaVcl = reference to procedure;
  TContextoSubsanacionFacturaVcl = record
    Propietario: TComponent;
    Cabecera: TDataSet;
    Servicio: IServicioSubsanacionFactura;
    ParametrosApp: IParametrosAplicacion;
    RegistroLog: IRegistroLog;
    // Graba la cabecera y las líneas en edición antes de registrar.
    GuardarPendiente: TAccionSubsanacionFacturaVcl;
    // Descarta la edición en curso antes de cancelar.
    DescartarPendiente: TAccionSubsanacionFacturaVcl;
  end;

// Botones visibles sólo en venta mayor con VERI*FACTU o NO VERI*FACTU:
// «Subsanar registro» en una factura con registro aceptado y «Registrar
// subsanación» / «Cancelar subsanación» en fase SUBSANACION.
procedure ActualizarBotonesSubsanacionVcl(
  ABotonSubsanar, ABotonCancelar: TcxButton;
  const ATipoFacturaFiltro: string;
  ACabecera: TDataSet;
  const AParametrosApp: IParametrosAplicacion);
procedure SubsanarFacturaVcl(
  const AContexto: TContextoSubsanacionFacturaVcl);
procedure CancelarSubsanacionFacturaVcl(
  const AContexto: TContextoSubsanacionFacturaVcl);

implementation

uses
  inLibFormatoDocumento,
  System.StrUtils,
  System.UITypes,
  Vcl.Dialogs,
  inLibMensajesVcl,
  inLibFacturas,
  inLibFacturasServiciosIntf,
  inLibFacturasSubsanacionReglas,
  inLibMsgFacturas,
  inLibVerifactu;

const
  LONGITUD_MOTIVO = 500;

function CabeceraViva(ACabecera: TDataSet): Boolean;
begin
  Result := Assigned(ACabecera) and ACabecera.Active and
    (not ACabecera.IsEmpty);
end;

function FaseCabecera(ACabecera: TDataSet): string;
begin
  Result := '';
  if Assigned(ACabecera.FindField(ffasefac)) then
    Result := Trim(ACabecera.FieldByName(ffasefac).AsString);
end;

function EnSubsanacion(ACabecera: TDataSet): Boolean;
begin
  Result := SameText(FaseCabecera(ACabecera), cFaseFacturaSubsanacion);
end;

procedure ActualizarBotonesSubsanacionVcl(
  ABotonSubsanar, ABotonCancelar: TcxButton;
  const ATipoFacturaFiltro: string;
  ACabecera: TDataSet;
  const AParametrosApp: IParametrosAplicacion);
var
  bVisible: Boolean;
  bEnSubsanacion: Boolean;
  sTipo: string;
begin
  bVisible := SameText(ATipoFacturaFiltro, 'NORMAL') and
    CabeceraViva(ACabecera) and Assigned(AParametrosApp) and
    (not SinVerifactuActivo(AParametrosApp));
  bEnSubsanacion := False;
  if bVisible then
  begin
    sTipo := '';
    if Assigned(ACabecera.FindField(ftipofac)) then
      sTipo := Trim(ACabecera.FieldByName(ftipofac).AsString);
    bEnSubsanacion := EnSubsanacion(ACabecera);
    bVisible := MatchText(sTipo, ['NORMAL', 'RECTIFICATIVA']) and
      (bEnSubsanacion or FaseAdmiteSubsanacion(FaseCabecera(ACabecera)));
  end;
  if bEnSubsanacion then
    ABotonSubsanar.Caption := SCaptionRegistrarSubsanacion
  else
    ABotonSubsanar.Caption := SCaptionSubsanarRegistro;
  ABotonSubsanar.Visible := bVisible;
  ABotonCancelar.Visible := bVisible and bEnSubsanacion;
end;

procedure IniciarSubsanacionVcl(
  const AContexto: TContextoSubsanacionFacturaVcl;
  const ASerie, ANumero: string);
var
  oValidacion: TResultadoOperacionFactura;
  sFormatoDocumento: string;
begin
  sFormatoDocumento := AContexto.Servicio.Cargar(
    ASerie, ANumero).FormatoDocumento;
  oValidacion := AContexto.Servicio.ValidarInicio(ASerie, ANumero);
  if not oValidacion.Exito then
    ShowMessage_fza(oValidacion.Mensaje)
  else if MessageDlg_fza(
            FormatearMensajeDocumentos(
              sFormatoDocumento,
              SPreguntaIniciarSubsanacionFactura, [ASerie, ANumero]),
            mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    AContexto.Servicio.Iniciar(ASerie, ANumero);
    AContexto.Cabecera.Refresh;
    ShowMessage_fza(FormatearMensajeDocumentos(
      sFormatoDocumento,
      SInfoSubsanacionFacturaIniciada,
      [ASerie, ANumero]));
  end;
end;

// Pide el motivo al registrar; False si el usuario cancela.
function PedirMotivoSubsanacionVcl(out AMotivo: string): Boolean;
var
  oValores: array of string;
begin
  SetLength(oValores, 1);
  Result := InputQuery_fza(STituloMotivoSubsanacionFactura,
    [SCaptionMotivoSubsanacionFactura], oValores,
    function(const AValores: array of string): Boolean
    begin
      Result := (Trim(AValores[0]) <> '') and
        (Length(Trim(AValores[0])) <= LONGITUD_MOTIVO);
      if not Result then
        ShowMessage_fza(SErrorSubsanacionMotivoObligatorio);
    end);
  AMotivo := '';
  if Result then
    AMotivo := Trim(oValores[0]);
end;

procedure RegistrarSubsanacionVcl(
  const AContexto: TContextoSubsanacionFacturaVcl;
  const ASerie, ANumero: string);
var
  sMotivo: string;
  oResultado: TResultadoSubsanacionFactura;
begin
  if Assigned(AContexto.GuardarPendiente) then
    AContexto.GuardarPendiente();
  if PedirMotivoSubsanacionVcl(sMotivo) then
  begin
    oResultado := AContexto.Servicio.Registrar(ASerie, ANumero, sMotivo);
    AContexto.Cabecera.Refresh;
    ShowMessage_fza(oResultado.Mensaje);
  end;
end;

procedure SubsanarFacturaVcl(
  const AContexto: TContextoSubsanacionFacturaVcl);
var
  sSerie: string;
  sNumero: string;
  sReferencia: string;
begin
  if CabeceraViva(AContexto.Cabecera) and Assigned(AContexto.Servicio) then
  begin
    sSerie := AContexto.Cabecera.FieldByName(fseriefac).AsString;
    sNumero := AContexto.Cabecera.FieldByName(fnrofac).AsString;
    sReferencia := FormatearDocumento('', sSerie, sNumero);
    try
      sReferencia := FormatearDocumento(
        AContexto.Servicio.Cargar(sSerie, sNumero).FormatoDocumento,
        sSerie, sNumero);
      if EnSubsanacion(AContexto.Cabecera) then
        RegistrarSubsanacionVcl(AContexto, sSerie, sNumero)
      else
        IniciarSubsanacionVcl(AContexto, sSerie, sNumero);
    except
      on E: Exception do
      begin
        if Assigned(AContexto.RegistroLog) then
          AContexto.RegistroLog.RegistrarError(
            'Subsanar factura ' + sReferencia + ': ' +
            E.Message);
        ShowMessage_fza(E.Message);
      end;
    end;
  end;
end;

procedure CancelarSubsanacionFacturaVcl(
  const AContexto: TContextoSubsanacionFacturaVcl);
var
  sSerie: string;
  sNumero: string;
  sFormatoDocumento: string;
  sReferencia: string;
  sPregunta: string;
  sDiferencias: string;
  bPuedeCancelar: Boolean;
begin
  if CabeceraViva(AContexto.Cabecera) and Assigned(AContexto.Servicio) and
     EnSubsanacion(AContexto.Cabecera) then
  begin
    sSerie := AContexto.Cabecera.FieldByName(fseriefac).AsString;
    sNumero := AContexto.Cabecera.FieldByName(fnrofac).AsString;
    sReferencia := FormatearDocumento('', sSerie, sNumero);
    try
      sFormatoDocumento := AContexto.Servicio.Cargar(
        sSerie, sNumero).FormatoDocumento;
      sReferencia := FormatearDocumento(
        sFormatoDocumento, sSerie, sNumero);
      // FZ-ISSUE-133: con importes o destinatario distintos del registro
      // aceptado sólo cabe registrar (o deshacer a mano y cancelar).
      sDiferencias := AContexto.Servicio.DiferenciasConRegistro(
        sSerie, sNumero);
      bPuedeCancelar := sDiferencias = '';
      if not bPuedeCancelar then
        MessageDlg_fza(FormatearMensajeDocumentos(
          sFormatoDocumento,
          SErrorCancelarSubsanacionConCambios,
          [sSerie, sNumero, sDiferencias]), mtWarning, [mbOK], 0)
      else if AContexto.Servicio.HayCambiosDesdeInicio(sSerie, sNumero) then
        sPregunta := FormatearMensajeDocumentos(
          sFormatoDocumento,
          SPreguntaCancelarSubsanacionConCambios,
          [sSerie, sNumero])
      else
        sPregunta := FormatearMensajeDocumentos(
          sFormatoDocumento,
          SPreguntaCancelarSubsanacionFactura,
          [sSerie, sNumero]);
      if bPuedeCancelar and
         (MessageDlg_fza(sPregunta, mtWarning, [mbYes, mbNo], 0) = mrYes) then
      begin
        if Assigned(AContexto.DescartarPendiente) then
          AContexto.DescartarPendiente();
        AContexto.Servicio.Cancelar(sSerie, sNumero);
        AContexto.Cabecera.Refresh;
      end;
    except
      on E: Exception do
      begin
        if Assigned(AContexto.RegistroLog) then
          AContexto.RegistroLog.RegistrarError(
            'Cancelar subsanación de ' + sReferencia + ': ' +
            E.Message);
        ShowMessage_fza(E.Message);
      end;
    end;
  end;
end;

end.
