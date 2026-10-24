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
  const ARegistroLog: IRegistroLog): Boolean;

implementation

uses
  System.SysUtils,
  System.UITypes,
  System.Diagnostics,
  Vcl.Dialogs,
  inLibMensajesVcl,
  inLibVentanaEspera,
  inLibFirmaEjecutable,
  inLibHuellaEsquemaIntf,
  inLibHuellaEsquema,
  inLibHuellaEsquemaRecurso,
  inLibInformeIntegridadEsquema,
  inLibMsgIntegridadEsquema,
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
  const ARegistroLog: IRegistroLog): Boolean;
var
  oConexion: TUniConnection;
  oIdeal: TEsquemaIdeal;
  oComprobacion: TComprobacionIntegridad;
  iMilisegundos: Int64;
  sDetalle: string;
begin
  Result := False;
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
      sDetalle := TextoInformeIntegridad(oComprobacion);
      Result := IntegridadPermiteArranque(oComprobacion);
    end;
  except
    on E: Exception do
    begin
      Result := False;
      sDetalle := Format(SErrorComprobarIntegridadArranque,
        [E.ClassName + ': ' + E.Message]);
    end;
  end;
  if not Result then
  begin
    sDetalle := SIntegridadArranqueBloqueado + sLineBreak +
      sLineBreak + sDetalle;
    ARegistroLog.RegistrarError(sDetalle);
    TfrmModalMensajeTexto.Mostrar(AOwner, STituloComprobarIntegridad,
      sDetalle);
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
