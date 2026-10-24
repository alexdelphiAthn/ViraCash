{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCorreoTicketPreviewVcl                                   }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Envío por correo del ticket abierto en el visor de tickets: pide el       }
{    destinatario, genera el PDF temporal y lo manda por el servicio web de    }
{    correo, igual que los documentos de los modales de impresión.             }
{******************************************************************************}
unit inLibCorreoTicketPreviewVcl;

interface

uses
  System.Classes, System.SysUtils, inLibPreviewTicket;

type
  TNombreEmpresaCorreo = reference to function(
    const AEmpresa: string): string;

// Parámetros, log y empresa de la sesión se piden al proveedor (el
// formulario principal) en cada envío: cambian al cambiar de empresa.
function CrearEnvioCorreoTicket(AProveedor: TComponent;
  const ANombreEmpresa: TNombreEmpresaCorreo): IEnvioCorreoTicket;

implementation

uses
  System.UITypes, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  inLibParametrosIntf, inLibLogIntf, inLibRegistroLogNulo,
  inLibContextoSesionIntf, inLibCorreoTickets, inLibCorreoDocumentoVcl,
  inLibMensajesVcl;

resourcestring
  SErrorTicketNoEnviadoCorreo = 'No se ha enviado el ticket.';

type
  TEnvioCorreoTicket = class(TInterfacedObject, IEnvioCorreoTicket)
  private
    FProveedor: TComponent;
    FNombreEmpresa: TNombreEmpresaCorreo;
    function ParametrosApp: IParametrosAplicacion;
    function RegistroLog: IRegistroLog;
    function NombreEmpresaSesion: string;
  public
    constructor Create(AProveedor: TComponent;
      const ANombreEmpresa: TNombreEmpresaCorreo);
    function Enviar(AOwner: TComponent; const AReferencia: string;
      const AExportarPdf: TProc<string>): Boolean;
  end;

function CrearEnvioCorreoTicket(AProveedor: TComponent;
  const ANombreEmpresa: TNombreEmpresaCorreo): IEnvioCorreoTicket;
begin
  Result := TEnvioCorreoTicket.Create(AProveedor, ANombreEmpresa);
end;

constructor TEnvioCorreoTicket.Create(AProveedor: TComponent;
  const ANombreEmpresa: TNombreEmpresaCorreo);
begin
  inherited Create;
  FProveedor := AProveedor;
  FNombreEmpresa := ANombreEmpresa;
end;

function TEnvioCorreoTicket.ParametrosApp: IParametrosAplicacion;
var
  oProveedor: IProveedorParametros;
begin
  Result := nil;
  if Supports(FProveedor, IProveedorParametros, oProveedor) then
    Result := oProveedor.ParametrosApp;
end;

function TEnvioCorreoTicket.RegistroLog: IRegistroLog;
var
  oProveedor: IProveedorRegistroLog;
begin
  Result := nil;
  if Supports(FProveedor, IProveedorRegistroLog, oProveedor) then
    Result := oProveedor.RegistroLog;
  if not Assigned(Result) then
    Result := CrearRegistroLogNulo;
end;

function TEnvioCorreoTicket.NombreEmpresaSesion: string;
var
  oProveedor: IProveedorContextoSesion;
  sEmpresa: string;
begin
  sEmpresa := '';
  if Supports(FProveedor, IProveedorContextoSesion, oProveedor) and
     Assigned(oProveedor.ContextoSesion) then
    sEmpresa := oProveedor.ContextoSesion.Ubicacion.Empresa;
  Result := '';
  if (sEmpresa <> '') and Assigned(FNombreEmpresa) then
  begin
    try
      Result := FNombreEmpresa(sEmpresa);
    except
      on E: Exception do
        RegistroLog.RegistrarError(
          'Nombre de empresa para el correo del ticket: ' + E.Message);
    end;
  end;
  if Result = '' then
    Result := sEmpresa;
end;

function TEnvioCorreoTicket.Enviar(AOwner: TComponent;
  const AReferencia: string; const AExportarPdf: TProc<string>): Boolean;
var
  oLog: IRegistroLog;
  oParametros: IParametrosAplicacion;
  oRutas: TStringList;
  sEmail: string;
  sMensaje: string;
  sRutaPdf: string;
begin
  Result := False;
  oParametros := ParametrosApp;
  if not CorreoTicketsConfigurado(oParametros, sMensaje) then
    ShowMessage_fza(sMensaje)
  else if SolicitarEmailDocumento(
    AOwner,
    TituloEnvioDocumentoCorreo(NombreDocumentoCorreo(tdcTicket)),
    '',
    sEmail) then
  begin
    oLog := RegistroLog;
    sRutaPdf := CrearRutaPdfTemporalCorreo(tdcTicket, '', AReferencia);
    oRutas := TStringList.Create;
    try
      Screen.Cursor := crHourGlass;
      try
        AExportarPdf(sRutaPdf);
        oRutas.Add(sRutaPdf);
        Result := EnviarDocumentosPorCorreo(
          oParametros,
          tdcTicket,
          AReferencia,
          NombreEmpresaSesion,
          sEmail,
          oRutas,
          oLog,
          sMensaje);
      finally
        Screen.Cursor := crDefault;
      end;
      if Result then
        MessageDlg_fza(sMensaje, mtInformation, [mbOK], 0)
      else
        MessageDlg_fza(
          SErrorTicketNoEnviadoCorreo + sLineBreak + sMensaje,
          mtError,
          [mbOK],
          0);
    finally
      FreeAndNil(oRutas);
      EliminarPdfTemporalCorreo(sRutaPdf, oLog);
    end;
  end;
end;

end.
