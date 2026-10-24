{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoLogonRestauracionVcl                                    }
{    Tipo:       Adaptador VCL                                                 }
{ Versión:       1.1.0                                                         }
{   Fecha:       23/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Recoge la restauración solicitada desde la pantalla de conexión.          }
{******************************************************************************}
unit inMtoLogonRestauracionVcl;

interface

uses
  Vcl.Dialogs,
  inLibCopiasSeguridadIntf,
  inLibRestauracionCopiasConexionIntf;

type
  TEstablecerContrasenaConexion = reference to procedure(
    const AContrasena: string);
  TMostrarPreparacionRestauracion = reference to procedure;
  TContextoLogonRestauracionVcl = record
    Dialogo: TFileOpenDialog;
    CasoUso: ICasoUsoRestauracionConexion;
    Host: string;
    Puerto: string;
    BaseDatos: string;
    Usuario: string;
    RutaFichero: string;
    ContrasenaConexion: string;
    AdministradorAutenticado: Boolean;
    OnPrepararWorker: TPrepararWorkerRestauracionEvent;
    OnProgreso: TProgresoCopiaSeguridadEvent;
    OnFinalizar: TFinalizarCopiaSeguridadEvent;
    EstablecerContrasena: TEstablecerContrasenaConexion;
    MostrarPreparacion: TMostrarPreparacionRestauracion;
  end;
  TCoordinadorLogonRestauracionVcl = class
  private
    class procedure ConfigurarDialogo(
      ADialogo: TFileOpenDialog); static;
    class function SolicitarContrasenaCopia(
      ADialogo: TFileOpenDialog;
      const ARutaFichero: string;
      out AContrasena: string
    ): Boolean; static;
  public
    class procedure Ejecutar(
      const AContexto: TContextoLogonRestauracionVcl); static;
  end;

implementation

uses
  inLibMensajesVcl,
  System.SysUtils,
  inMtoModalContrasenaCopia,
  inLibDir,
  inLibMsgComun,
  inLibMsgConfiguracion;

class procedure TCoordinadorLogonRestauracionVcl.ConfigurarDialogo(
  ADialogo: TFileOpenDialog);
var
  oTipoFichero: TFileTypeItem;
begin
  ADialogo.Title := STituloCargarCopiaSeguridad;
  ADialogo.FileTypes.Clear;
  oTipoFichero := ADialogo.FileTypes.Add;
  oTipoFichero.DisplayName := SCaptionFiltroCopiasCifradas;
  oTipoFichero.FileMask := '*.crypt';
  ADialogo.DefaultExtension := 'crypt';
  ADialogo.DefaultFolder := GetUserDeskFolder;
end;

class function TCoordinadorLogonRestauracionVcl.
  SolicitarContrasenaCopia(
    ADialogo: TFileOpenDialog;
    const ARutaFichero: string;
    out AContrasena: string): Boolean;
begin
  AContrasena := '';
  Result := True;
  if SameText(ExtractFileExt(ARutaFichero), '.crypt') then
  begin
    Result := TfrmModalContrasenaCopia.SolicitarExistente(
      ADialogo.Owner,
      AContrasena);
  end;
end;

class procedure TCoordinadorLogonRestauracionVcl.Ejecutar(
  const AContexto: TContextoLogonRestauracionVcl);
var
  bContinuar: Boolean;
  oSolicitud: TSolicitudRestauracionConexion;
  sContrasena: string;
  sContrasenaCopia: string;
begin
  if not Assigned(AContexto.CasoUso) then
  begin
    raise EInvalidOpException.Create(
      SErrorServicioRestauracionNoDisponible);
  end;
  oSolicitud := Default(TSolicitudRestauracionConexion);
  sContrasena := AContexto.ContrasenaConexion;
  if AContexto.RutaFichero = '' then
  begin
    sContrasena := InputBox_fza(SGetPassBBDD, '', '');
    ConfigurarDialogo(AContexto.Dialogo);
    bContinuar := AContexto.Dialogo.Execute;
    if bContinuar then
      oSolicitud.RutaFichero := AContexto.Dialogo.FileName;
  end
  else
  begin
    bContinuar := True;
    oSolicitud.RutaFichero := AContexto.RutaFichero;
  end;
  AContexto.EstablecerContrasena(sContrasena);
  if bContinuar then
  begin
    bContinuar := SolicitarContrasenaCopia(
      AContexto.Dialogo,
      oSolicitud.RutaFichero,
      sContrasenaCopia);
    if bContinuar then
    begin
      oSolicitud.Host := AContexto.Host;
      oSolicitud.Puerto := StrToIntDef(AContexto.Puerto, 3306);
      oSolicitud.BaseDatos := AContexto.BaseDatos;
      oSolicitud.Usuario := AContexto.Usuario;
      oSolicitud.ContrasenaConexion := sContrasena;
      oSolicitud.ContrasenaCopia := sContrasenaCopia;
      oSolicitud.AdministradorAutenticado :=
        AContexto.AdministradorAutenticado;
      AContexto.MostrarPreparacion();
      AContexto.CasoUso.Ejecutar(
        oSolicitud,
        AContexto.OnPrepararWorker,
        AContexto.OnProgreso,
        AContexto.OnFinalizar);
    end;
  end
  else if AContexto.RutaFichero = '' then
    ShowMessage_fza(SCargaScriptCancelada);
end;

end.
