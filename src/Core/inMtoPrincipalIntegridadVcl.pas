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
  const AComparar: TFunc<Boolean> = nil): Boolean;

implementation

uses
  System.UITypes,
  System.Diagnostics,
  Vcl.Controls,
  Vcl.Dialogs,
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
  inMtoModalMensajeTexto;

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

function ValidarIntegridadEsquemaAlArrancar(
  AOwner: TForm;
  const AFabrica: IFabricaConexionesUniDAC;
  const ARegistroLog: IRegistroLog;
  const AActualizar: TFunc<Boolean>;
  const AComparar: TFunc<Boolean>): Boolean;
var
  oConexion: TUniConnection;
  oIdeal: TEsquemaIdeal;
  oComprobacion: TComprobacionIntegridad;
  iMilisegundos: Int64;
  sDetalle: string;
  bPuedeActualizar: Boolean;
  bPuedeComparar: Boolean;
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
        oBoton.ModalResult := mrRetry;
      end;
      iAccion := oDialogo.ShowModal;
    finally
      oDialogo.Free;
    end;
    if (iAccion = mrYes) and bPuedeActualizar then
    begin
      if AActualizar() then
        // Si los scripts no bastan, queda disponible la comparación.
        Result := ValidarIntegridadEsquemaAlArrancar(
          AOwner, AFabrica, ARegistroLog, nil, AComparar);
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
