{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoRestauracionCopiasVcl                                   }
{    Tipo:       Adaptador VCL                                                 }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Recoge y presenta la restauración iniciada por la pantalla principal.     }
{******************************************************************************}
unit inMtoRestauracionCopiasVcl;

interface

uses
  System.Classes,
  Vcl.Dialogs,
  inLibOperacionesAplicacionIntf;

type
  TComprobarDDLRestauracion = reference to function(
    const ASQL: string): Boolean;
  TSolicitarCopiaPreviaRestauracion = reference to function(
    out ARutaFichero: string): Boolean;
  TPreparacionRestauracionCopiasVcl = record
    RutaRestauracion: string;
    RutaCopiaPrevia: string;
  end;
  TContextoRestauracionCopiasVcl = record
    Owner: TComponent;
    Dialogo: TFileOpenDialog;
    CasoUso: ICasoUsoCopiasSeguridad;
    RutaCopias: string;
    Visible: Boolean;
    EsAdministrador: Boolean;
    ComprobarDDL: TComprobarDDLRestauracion;
    SolicitarCopiaPrevia: TSolicitarCopiaPreviaRestauracion;
  end;
  TCoordinadorRestauracionCopiasVcl = class
  private
    class procedure ConfigurarDialogo(
      const AContexto: TContextoRestauracionCopiasVcl); static;
    class function SolicitarOrigen(
      const AContexto: TContextoRestauracionCopiasVcl;
      out ARutaFichero: string): Boolean; static;
    class function LeerCabeceraSql(
      const ARutaFichero: string): string; static;
    class function ConfirmarCopiaPrevia(
      const AContexto: TContextoRestauracionCopiasVcl;
      const ARutaFichero: string;
      out ARutaCopiaPrevia: string): Boolean; static;
  public
    class function Ejecutar(
      const AContexto: TContextoRestauracionCopiasVcl;
      out APreparacion: TPreparacionRestauracionCopiasVcl): Boolean; static;
  end;

function SolicitarNuevaContrasenaCopia(
  AOwner: TComponent;
  out AContrasena: string): Boolean;

implementation

uses
  inLibMensajesVcl,
  System.SysUtils,
  System.UITypes,
  inMtoModalContrasenaCopia,
  inLibCopiasSeguridadIntf,
  inLibMsgComun,
  inLibMsgConfiguracion;

function SolicitarNuevaContrasenaCopia(
  AOwner: TComponent;
  out AContrasena: string): Boolean;
begin
  Result := TfrmModalContrasenaCopia.SolicitarNueva(
    AOwner,
    AContrasena);
end;

class procedure TCoordinadorRestauracionCopiasVcl.ConfigurarDialogo(
  const AContexto: TContextoRestauracionCopiasVcl);
var
  oTipoFichero: TFileTypeItem;
begin
  AContexto.Dialogo.Title := STituloRestaurarCopiaEjecutarScript;
  AContexto.Dialogo.FileTypes.Clear;
  oTipoFichero := AContexto.Dialogo.FileTypes.Add;
  if AContexto.EsAdministrador then
  begin
    oTipoFichero.DisplayName := SCaptionFiltroCopiasSqlCifradas;
    oTipoFichero.FileMask := '*.sql;*.zip;*.crypt';
    AContexto.Dialogo.DefaultExtension := 'sql';
  end
  else
  begin
    oTipoFichero.DisplayName := SCaptionFiltroCopiasScriptsCifrados;
    oTipoFichero.FileMask := '*.crypt';
    AContexto.Dialogo.DefaultExtension := 'crypt';
  end;
  AContexto.Dialogo.DefaultFolder := AContexto.RutaCopias;
  AContexto.Dialogo.Options := AContexto.Dialogo.Options +
    [fdoStrictFileTypes, fdoFileMustExist];
end;

class function TCoordinadorRestauracionCopiasVcl.SolicitarOrigen(
  const AContexto: TContextoRestauracionCopiasVcl;
  out ARutaFichero: string): Boolean;
begin
  ARutaFichero := '';
  ConfigurarDialogo(AContexto);
  Result := AContexto.Dialogo.Execute;
  if Result then
  begin
    ARutaFichero := AContexto.Dialogo.FileName;
    Result := AContexto.CasoUso.PuedeRestaurar(ARutaFichero);
    if not Result then
      ShowMessage_fza(SErrorTipoRestauracionNoPermitido);
  end;
end;

class function TCoordinadorRestauracionCopiasVcl.LeerCabeceraSql(
  const ARutaFichero: string): string;
var
  aBytes: TBytes;
  iBytesALeer: Int64;
  oFichero: TFileStream;
begin
  oFichero := TFileStream.Create(
    ARutaFichero,
    fmOpenRead or fmShareDenyNone);
  try
    iBytesALeer := oFichero.Size;
    if iBytesALeer > 65536 then
      iBytesALeer := 65536;
    SetLength(aBytes, iBytesALeer);
    oFichero.ReadBuffer(aBytes, iBytesALeer);
    Result := TEncoding.UTF8.GetString(aBytes);
  finally
    FreeAndNil(oFichero);
  end;
end;

class function TCoordinadorRestauracionCopiasVcl.ConfirmarCopiaPrevia(
  const AContexto: TContextoRestauracionCopiasVcl;
  const ARutaFichero: string;
  out ARutaCopiaPrevia: string): Boolean;
var
  bCifrada: Boolean;
  bCopiaCompleta: Boolean;
  bRequiereCopia: Boolean;
  iRespuesta: Integer;
  sPregunta: string;
begin
  ARutaCopiaPrevia := '';
  bCifrada := AContexto.CasoUso.RequiereContrasena(ARutaFichero);
  bCopiaCompleta := bCifrada or SameText(
    ExtractFileExt(ARutaFichero),
    '.zip');
  bRequiereCopia := bCopiaCompleta;
  sPregunta := SPreguntaCopiaAntesRestaurarCifrada;
  if not bCopiaCompleta then
  begin
    bRequiereCopia := AContexto.ComprobarDDL(
      LeerCabeceraSql(ARutaFichero));
    sPregunta := SPreguntaCopiaSeguridadAntesDDL;
  end;
  Result := True;
  if bRequiereCopia then
  begin
    iRespuesta := MessageDlg_fza(
      sPregunta,
      mtWarning,
      [mbYes, mbNo, mbCancel],
      0);
    case iRespuesta of
      mrYes:
        Result := AContexto.SolicitarCopiaPrevia(
          ARutaCopiaPrevia);
      mrCancel:
        Result := False;
    end;
    if not Result then
      ShowMessage_fza(SInfoScriptCancelado);
  end;
end;

class function TCoordinadorRestauracionCopiasVcl.Ejecutar(
  const AContexto: TContextoRestauracionCopiasVcl;
  out APreparacion: TPreparacionRestauracionCopiasVcl): Boolean;
begin
  APreparacion := Default(TPreparacionRestauracionCopiasVcl);
  Result := False;
  if AContexto.Visible then
  begin
    Result := SolicitarOrigen(
      AContexto,
      APreparacion.RutaRestauracion);
    if Result then
      Result := ConfirmarCopiaPrevia(
        AContexto,
        APreparacion.RutaRestauracion,
        APreparacion.RutaCopiaPrevia);
    if not Result then
      APreparacion := Default(TPreparacionRestauracionCopiasVcl);
  end;
end;

end.
