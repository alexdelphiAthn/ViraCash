{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoPrincipalIntegridadVcl                                   }
{    Tipo:       Formulario (Core)                                             }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Ayuda > Comprobar integridad: lee el catálogo de la base conectada,       }
{    lo compara con el esquema ideal embebido y con PRC_FZA_HUELLA_ESQUEMA,    }
{    deja el resultado en el log y lo muestra.                                 }
{******************************************************************************}
unit inMtoPrincipalIntegridadVcl;

interface

uses
  System.SysUtils,
  Vcl.Forms,
  Uni,
  inLibConexionesIntf,
  inLibLogIntf;

procedure ComprobarIntegridadEsquemaVcl(
  AOwner: TForm;
  AConexion: TUniConnection;
  const ARegistroLog: IRegistroLog);
function ValidarIntegridadEsquemaAlArrancar(
  AOwner: TForm;
  const AFabrica: IFabricaConexionesUniDAC;
  const ARegistroLog: IRegistroLog;
  const AActualizar: TFunc<Boolean> = nil;
  const AComparar: TFunc<Boolean> = nil;
  const ACompararLocal: TFunc<Boolean> = nil): Boolean;

implementation

uses
  System.UITypes,
  System.Classes,
  System.Diagnostics,
  Winapi.Windows,
  Vcl.Controls,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  cxButtons,
  inLibMensajesVcl,
  inLibVentanaEspera,
  inLibFirmaEjecutable,
  inLibHuellaEsquemaIntf,
  inLibHuellaEsquema,
  inLibHuellaEsquemaRecurso,
  inLibInformeIntegridadEsquema,
  inLibMsgIntegridadEsquema,
  inLibMsgIntegraciones,
  UniDataHuellaEsquema,
  inMtoModalMensajeTexto, inMtoModalProcesosAuxiliaresBBDD;

const
  cConsultarEsquema = mrIgnore;
  cIntervaloMinimoComparacionMs = 1500;

type
  TComparacionArranque = class(TComponent)
  private
    FDialogo: TForm;
    FTemporizador: TTimer;
    FClics: Integer;
    procedure Pulsar(Sender: TObject);
    procedure VencerIntervalo(Sender: TObject);
  public
    constructor Create(ADialogo: TForm; ABoton: TcxButton); reintroduce;
  end;

constructor TComparacionArranque.Create(
  ADialogo: TForm; ABoton: TcxButton);
begin
  inherited Create(ADialogo);
  FDialogo := ADialogo;
  FTemporizador := TTimer.Create(Self);
  FTemporizador.Enabled := False;
  FTemporizador.Interval := GetDoubleClickTime;
  if FTemporizador.Interval < cIntervaloMinimoComparacionMs then
    FTemporizador.Interval := cIntervaloMinimoComparacionMs;
  FTemporizador.OnTimer := VencerIntervalo;
  ABoton.OnClick := Pulsar;
end;

procedure TComparacionArranque.Pulsar(Sender: TObject);
begin
  FTemporizador.Enabled := False;
  Inc(FClics);
  if (FClics = 3) or (GetKeyState(VK_CONTROL) < 0) then
  begin
    FClics := 0;
    FDialogo.ModalResult := cConsultarEsquema;
  end
  else
    FTemporizador.Enabled := True;
end;

procedure TComparacionArranque.VencerIntervalo(Sender: TObject);
begin
  FTemporizador.Enabled := False;
  FClics := 0;
  FDialogo.ModalResult := mrRetry;
end;

procedure AnotarFirma(var AComprobacion: TComprobacionIntegridad);
var
  oFirma: TResultadoFirmaEjecutable;
begin
  // La misma comprobación que al arrancar (sin red, unas décimas).
  oFirma := ComprobarFirmaEjecutable(ParamStr(0));
  AComprobacion.TextoFirma := TextoComprobacionFirma(ParamStr(0), oFirma);
  AComprobacion.FirmaPreocupante := DebeAvisarFirma(ParamStr(0), oFirma);
end;

function Comprobar(
  AOwner: TForm;
  AConexion: TUniConnection;
  AIdeal: TEsquemaIdeal;
  AComprobarFirma: Boolean;
  out AMilisegundos: Int64): TComprobacionIntegridad;
var
  oEspera: IVentanaEspera;
  oCronometro: TStopwatch;
begin
  oEspera := CrearVentanaEspera(AOwner.BoundsRect, AOwner.CurrentPPI,
                                Application.MainFormHandle);
  oEspera.Mostrar(SInfoComprobandoIntegridad);
  try
    oCronometro := TStopwatch.StartNew;
    Result := ComprobarIntegridadEsquema(
      CrearLectorCatalogoEsquemaUniDAC(AConexion), AIdeal);
    if AComprobarFirma then
      AnotarFirma(Result);
    AMilisegundos := oCronometro.ElapsedMilliseconds;
  finally
    oEspera.Ocultar;
  end;
end;

function MostrarInformeArranque(
  AOwner: TForm; const AInforme: string;
  const AFabrica: IFabricaConexionesUniDAC;
  const ACompararLocal: TFunc<Boolean>): Boolean;
var
  oInforme: TfrmModalMensajeTexto;
  oConexion: TUniConnection;
  oBoton: TcxButton;
  iAccion: TModalResult;
begin
  Result := False;
  oInforme := TfrmModalMensajeTexto.Create(AOwner);
  try
    oInforme.Caption := STituloComprobarIntegridad;
    oInforme.mTexto.Text := AInforme;
    oInforme.mTexto.SelStart := 0;
    if Assigned(ACompararLocal) then
    begin
      oBoton := TcxButton.Create(oInforme);
      oBoton.Parent := oInforme.pnlBotones;
      oBoton.SetBounds(12 * oInforme.CurrentPPI div 96,
        oInforme.btnCerrar.Top, 200 * oInforme.CurrentPPI div 96,
        oInforme.btnCerrar.Height);
      oBoton.Caption := SIntegridadBotonOperacionesAuxiliares;
      oBoton.ModalResult := mrYes;
    end;
    repeat
      iAccion := oInforme.ShowModal;
      if iAccion = mrYes then
      begin
        oConexion := AFabrica.CrearConexion(nil);
        try
          AFabrica.Conectar(oConexion);
          Result := TfrmModalProcesosAuxiliaresBBDD.ConsultarTablas(
            AOwner, oConexion, ACompararLocal);
        finally
          oConexion.Free;
        end;
      end;
    until (iAccion <> mrYes) or Result;
  finally
    oInforme.Free;
  end;
end;

function ValidarIntegridadEsquemaAlArrancar(
  AOwner: TForm;
  const AFabrica: IFabricaConexionesUniDAC;
  const ARegistroLog: IRegistroLog;
  const AActualizar: TFunc<Boolean>;
  const AComparar: TFunc<Boolean>;
  const ACompararLocal: TFunc<Boolean>): Boolean;
var
  oConexion: TUniConnection;
  oIdeal: TEsquemaIdeal;
  oComprobacion: TComprobacionIntegridad;
  iMilisegundos: Int64;
  sDetalle: string;
  bPuedeActualizar: Boolean;
  bPuedeComparar: Boolean;
  bComparacionLocalAplicada: Boolean;
  iAccion: TModalResult;
  oDialogo: TfrmModalMensajeTexto;
  oBoton: TcxButton;
begin
  Result := False;
  bPuedeActualizar := False;
  bPuedeComparar := False;
  try
    oIdeal := CargarEsquemaIdeal;
    if not Assigned(oIdeal) then
      sDetalle := SErrorSinEsquemaIdeal
    else
    begin
      try
        // El login manual ya ha cerrado su conexión. Se comprueba el
        // mismo perfil confirmado que utilizará la ventana principal.
        oConexion := AFabrica.CrearConexion(nil);
        try
          AFabrica.Conectar(oConexion);
          oComprobacion := Comprobar(AOwner, oConexion, oIdeal, False,
            iMilisegundos);
        finally
          oConexion.Free;
        end;
      finally
        oIdeal.Free;
      end;
      ARegistroLog.RegistrarInformacion(
        ResumenLogIntegridad(oComprobacion));
      ARegistroLog.RegistrarRendimiento('IntegridadEsquemaArranque',
        oComprobacion.Contexto.BaseDatos, iMilisegundos);
      sDetalle := TextoInformeIntegridad(oComprobacion, True);
      Result := IntegridadPermiteArranque(oComprobacion);
      bPuedeActualizar := Assigned(AActualizar) and
        oComprobacion.EsquemaIdealCoherente;
      bPuedeComparar := Assigned(AComparar) and
        oComprobacion.EsquemaIdealCoherente;
    end;
  except
    on E: Exception do
    begin
      Result := False;
      bPuedeActualizar := False;
      bPuedeComparar := False;
      sDetalle := Format(SErrorComprobarIntegridadArranque,
        [E.ClassName + ': ' + E.Message]);
    end;
  end;
  if not Result then
  begin
    sDetalle := SIntegridadArranqueBloqueado + sLineBreak +
      sLineBreak + sDetalle;
    if bPuedeActualizar or bPuedeComparar then
      sDetalle := SIntegridadActualizacionArranque + sLineBreak +
        sLineBreak + sDetalle;
    ARegistroLog.RegistrarError(sDetalle);
    oDialogo := TfrmModalMensajeTexto.Create(AOwner);
    try
      oDialogo.Caption := STituloComprobarIntegridad;
      oDialogo.mTexto.Text := sDetalle;
      if bPuedeComparar then
        oDialogo.ClientWidth := 780 * oDialogo.CurrentPPI div 96;
      oDialogo.Constraints.MinWidth := oDialogo.Width;
      if bPuedeActualizar then
      begin
        oDialogo.Constraints.MinWidth := oDialogo.Width;
        oBoton := TcxButton.Create(oDialogo);
        oBoton.Parent := oDialogo.pnlBotones;
        oBoton.SetBounds(12 * oDialogo.CurrentPPI div 96,
          oDialogo.btnCerrar.Top, 240 * oDialogo.CurrentPPI div 96,
          oDialogo.btnCerrar.Height);
        oBoton.Caption := SIntegridadBotonActualizar;
        oBoton.ModalResult := mrYes;
      end;
      if bPuedeComparar then
      begin
        oBoton := TcxButton.Create(oDialogo);
        oBoton.Parent := oDialogo.pnlBotones;
        if bPuedeActualizar then
          oBoton.Left := 264 * oDialogo.CurrentPPI div 96
        else
          oBoton.Left := 12 * oDialogo.CurrentPPI div 96;
        oBoton.SetBounds(oBoton.Left, oDialogo.btnCerrar.Top,
          156 * oDialogo.CurrentPPI div 96, oDialogo.btnCerrar.Height);
        oBoton.Caption := SBotonActualizarPorComparacion;
        TComparacionArranque.Create(oDialogo, oBoton);
      end;
      bComparacionLocalAplicada := False;
      repeat
        iAccion := oDialogo.ShowModal;
        if iAccion = cConsultarEsquema then
          bComparacionLocalAplicada := MostrarInformeArranque(AOwner,
            TextoInformeIntegridad(oComprobacion), AFabrica, ACompararLocal);
      until (iAccion <> cConsultarEsquema) or bComparacionLocalAplicada;
    finally
      oDialogo.Free;
    end;
    if bComparacionLocalAplicada then
      Result := ValidarIntegridadEsquemaAlArrancar(AOwner, AFabrica,
        ARegistroLog, AActualizar, AComparar, ACompararLocal)
    else if (iAccion = mrYes) and bPuedeActualizar then
    begin
      if AActualizar() then
        // Si los scripts no bastan, queda disponible la comparación.
        Result := ValidarIntegridadEsquemaAlArrancar(
          AOwner, AFabrica, ARegistroLog, nil, AComparar, ACompararLocal);
    end
    else if (iAccion = mrRetry) and bPuedeComparar then
    begin
      if AComparar() then
        // Toda reparación se valida; no se repite automáticamente.
        Result := ValidarIntegridadEsquemaAlArrancar(
          AOwner, AFabrica, ARegistroLog);
    end;
  end;
end;

procedure ComprobarIntegridadEsquemaVcl(
  AOwner: TForm;
  AConexion: TUniConnection;
  const ARegistroLog: IRegistroLog);
var
  oIdeal: TEsquemaIdeal;
  oComprobacion: TComprobacionIntegridad;
  iMilisegundos: Int64;
begin
  oIdeal := CargarEsquemaIdeal;
  if not Assigned(oIdeal) then
    MessageDlg_fza(SErrorSinEsquemaIdeal, mtWarning, [mbOk], 0)
  else
  begin
    try
      oComprobacion := Comprobar(AOwner, AConexion, oIdeal, True,
        iMilisegundos);
    finally
      oIdeal.Free;
    end;
    ARegistroLog.RegistrarInformacion(ResumenLogIntegridad(oComprobacion));
    if oComprobacion.FirmaPreocupante then
      ARegistroLog.RegistrarAviso('Firma del ejecutable: ' +
                                  oComprobacion.TextoFirma)
    else
      ARegistroLog.RegistrarInformacion('Firma del ejecutable: ' +
                                        oComprobacion.TextoFirma);
    ARegistroLog.RegistrarRendimiento('ComprobarIntegridadEsquema',
                                      oComprobacion.Contexto.BaseDatos,
                                      iMilisegundos);
    TfrmModalMensajeTexto.Mostrar(AOwner, STituloComprobarIntegridad,
                                  TextoInformeIntegridad(oComprobacion));
  end;
end;

end.
