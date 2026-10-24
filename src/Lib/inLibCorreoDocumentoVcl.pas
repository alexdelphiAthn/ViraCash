{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCorreoDocumentoVcl                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       22/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Piezas VCL comunes del envío de documentos por correo desde los modales   }
{    de impresión: diálogo del destinatario, nombre del documento y PDF        }
{    temporal que se adjunta y se elimina después.                             }
{******************************************************************************}
unit inLibCorreoDocumentoVcl;

interface

uses
  System.Classes, inLibCorreoTickets, inLibLogIntf,
  inLibTraduccionesIntf;

// Pide el destinatario. El email escrito se valida antes de cerrar.
function SolicitarEmailDocumento(AOwner: TComponent;
  const ATitulo, AEmailInicial: string;
  out AEmail: string): Boolean;
// Nombre fijo del tipo, para cuando fza_tipos_documentos no lo tiene.
function NombreDocumentoCorreo(ATipo: TTipoDocumentoCorreo): string;
// El título usa el idioma de sesión; el nombre almacenado se conserva en es.
function NombreDocumentoCorreoTraducido(ATipo: TTipoDocumentoCorreo;
  const ANombreAlmacenado: string;
  const ATraducciones: IServicioTraducciones): string;
function TituloEnvioDocumentoCorreo(const ANombreDocumento: string): string;
// Ruta en una carpeta temporal propia; el nombre del fichero es el que
// recibe el destinatario (tipo, serie y número).
function CrearRutaPdfTemporalCorreo(ATipo: TTipoDocumentoCorreo;
  const ASerie, ANumero: string): string;
// Borra el PDF temporal (y su carpeta propia) y avisa si no se pudo; el
// detalle queda en el log.
procedure EliminarPdfTemporalCorreo(const ARutaPdf: string;
  const ARegistroLog: IRegistroLog);

implementation

uses
  Winapi.Windows, System.SysUtils, System.UITypes, System.IOUtils,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.Dialogs,
  inLibMensajesVcl, inLibCorreoValidacion, inLibMsgArticulos,
  inLibTraducciones;


const
  cCarpetaTemporalCorreo = 'ViraCash\Correo';

type
  TfrmConfirmarCorreoDocumento = class(TForm)
  private
    FEmail: TEdit;
    procedure ConfirmarClick(Sender: TObject);
    function EmailPuedeConfirmarse: Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    function Ejecutar(
      const ATitulo, AEmailInicial: string;
      out AEmail: string): Boolean;
  end;

{ TfrmConfirmarCorreoDocumento }

constructor TfrmConfirmarCorreoDocumento.Create(AOwner: TComponent);
var
  BotonCancelar: TButton;
  BotonConfirmar: TButton;
  EtiquetaEmail: TLabel;
begin
  inherited CreateNew(AOwner);
  ActivarTraduccionResourcestrings(ResolverServicioTraducciones(AOwner));
  BorderIcons := [biSystemMenu];
  BorderStyle := bsDialog;
  ClientHeight := 132;
  ClientWidth := 424;
  Font.Assign(Screen.MessageFont);
  Position := poScreenCenter;
  if AOwner is TCustomForm then
  begin
    PopupMode := pmExplicit;
    PopupParent := TCustomForm(AOwner);
  end;

  EtiquetaEmail := TLabel.Create(Self);
  EtiquetaEmail.Parent := Self;
  EtiquetaEmail.Caption := SSolicitudEmailDocumento;
  EtiquetaEmail.SetBounds(16, 14, 392, 20);

  FEmail := TEdit.Create(Self);
  FEmail.Parent := Self;
  FEmail.SetBounds(16, 36, 392, 25);
  FEmail.Anchors := [akLeft, akTop, akRight];

  BotonConfirmar := TButton.Create(Self);
  BotonConfirmar.Parent := Self;
  BotonConfirmar.Caption := SBotonConfirmarEnvioDocumento;
  BotonConfirmar.Default := True;
  BotonConfirmar.SetBounds(136, 84, 144, 30);
  BotonConfirmar.OnClick := ConfirmarClick;

  BotonCancelar := TButton.Create(Self);
  BotonCancelar.Parent := Self;
  BotonCancelar.Cancel := True;
  BotonCancelar.Caption := SBotonCancelarEnvioDocumento;
  BotonCancelar.ModalResult := mrCancel;
  BotonCancelar.SetBounds(288, 84, 120, 30);
end;

procedure TfrmConfirmarCorreoDocumento.ConfirmarClick(Sender: TObject);
begin
  if EmailPuedeConfirmarse then
    ModalResult := mrOk;
end;

function TfrmConfirmarCorreoDocumento.EmailPuedeConfirmarse: Boolean;
begin
  Result := Trim(FEmail.Text) <> '';
  if not Result then
  begin
    ShowMessage_fza(SErrorEmailDocumentoVacio);
    FEmail.SetFocus;
  end
  else
  begin
    Result := EmailDocumentoValido(FEmail.Text);
    if not Result then
    begin
      ShowMessage_fza(SErrorEmailDocumentoInvalido);
      FEmail.SetFocus;
    end;
  end;
end;

function TfrmConfirmarCorreoDocumento.Ejecutar(
  const ATitulo, AEmailInicial: string;
  out AEmail: string): Boolean;
begin
  Caption := ATitulo;
  FEmail.Text := AEmailInicial;
  ActiveControl := FEmail;
  FEmail.SelectAll;
  Result := ShowModal = mrOk;
  if Result then
    AEmail := Trim(FEmail.Text)
  else
    AEmail := '';
end;

{ Funciones públicas }

function SolicitarEmailDocumento(AOwner: TComponent;
  const ATitulo, AEmailInicial: string;
  out AEmail: string): Boolean;
var
  Formulario: TfrmConfirmarCorreoDocumento;
begin
  Formulario := TfrmConfirmarCorreoDocumento.Create(AOwner);
  try
    Result := Formulario.Ejecutar(ATitulo, AEmailInicial, AEmail);
  finally
    FreeAndNil(Formulario);
  end;
end;

function NombreDocumentoCorreo(ATipo: TTipoDocumentoCorreo): string;
begin
  case ATipo of
    tdcFactura:
      Result := SNombreCorreoFactura;
    tdcPresupuesto:
      Result := SNombreCorreoPresupuesto;
    tdcPedido:
      Result := SNombreCorreoPedido;
    tdcAlbaran:
      Result := SNombreCorreoAlbaran;
    tdcPedidoCompra:
      Result := SNombreCorreoPedidoCompra;
    tdcAlbaranCompra:
      Result := SNombreCorreoAlbaranCompra;
    tdcDevolucionCompra:
      Result := SNombreCorreoDevolucionCompra;
    tdcFacturaCompra:
      Result := SNombreCorreoFacturaCompra;
  else
    Result := SNombreCorreoTicket;
  end;
end;

function NombreDocumentoCorreoTraducido(ATipo: TTipoDocumentoCorreo;
  const ANombreAlmacenado: string;
  const ATraducciones: IServicioTraducciones): string;
const
  CLAVES: array[TTipoDocumentoCorreo] of string = (
    'SNombreCorreoTicket', 'SNombreCorreoFactura', 'SNombreCorreoPresupuesto',
    'SNombreCorreoPedido', 'SNombreCorreoAlbaran', 'SNombreCorreoPedidoCompra',
    'SNombreCorreoAlbaranCompra', 'SNombreCorreoDevolucionCompra',
    'SNombreCorreoFacturaCompra');
begin
  Result := Trim(ANombreAlmacenado);
  if Assigned(ATraducciones) and
     not SameText(ATraducciones.Idioma, IDIOMA_ESPANOL) then
    Result := ATraducciones.Traducir(
      'inLibMsgArticulos.' + CLAVES[ATipo], NombreDocumentoCorreo(ATipo))
  else if Result = '' then
    Result := NombreDocumentoCorreo(ATipo);
end;

function TituloEnvioDocumentoCorreo(const ANombreDocumento: string): string;
begin
  // fza_tipos_documentos guarda las descripciones en mayúsculas.
  Result := Format(STituloEnviarDocumentoCorreo,
    [AnsiLowerCase(Trim(ANombreDocumento))]);
end;

function PrefijoFicheroDocumentoCorreo(
  ATipo: TTipoDocumentoCorreo): string;
begin
  // El texto del tipo en el servicio web ya es ASCII: el servicio sustituye
  // cualquier otro carácter del nombre del adjunto por un guion bajo.
  Result := TipoDocumentoTexto(ATipo);
  Result[1] := UpCase(Result[1]);
end;

function TextoSeguroFichero(const ATexto: string): string;
var
  iCaracter: Integer;
begin
  Result := Trim(ATexto);
  for iCaracter := 1 to Length(Result) do
  begin
    if not CharInSet(Result[iCaracter],
      ['A'..'Z', 'a'..'z', '0'..'9', '-']) then
      Result[iCaracter] := '_';
  end;
end;

function CarpetaTemporalCorreo: string;
begin
  Result := TPath.Combine(TPath.GetTempPath, cCarpetaTemporalCorreo);
end;

function CrearRutaPdfTemporalCorreo(ATipo: TTipoDocumentoCorreo;
  const ASerie, ANumero: string): string;
var
  sCarpeta: string;
  sNombre: string;
begin
  // Una carpeta por envío: el nombre del adjunto puede repetirse entre
  // envíos sin pisar el PDF de otro que siga en curso.
  sCarpeta := TPath.Combine(CarpetaTemporalCorreo,
    TGUID.NewGuid.ToString.Trim(['{', '}']));
  ForceDirectories(sCarpeta);
  sNombre := PrefijoFicheroDocumentoCorreo(ATipo);
  if Trim(ASerie) <> '' then
    sNombre := sNombre + '_' + TextoSeguroFichero(ASerie);
  sNombre := sNombre + '_' + TextoSeguroFichero(ANumero) + '.pdf';
  Result := TPath.Combine(sCarpeta, sNombre);
end;

procedure EliminarCarpetaPropiaVacia(const ARutaPdf: string);
var
  sCarpeta: string;
begin
  // Solo la carpeta creada por CrearRutaPdfTemporalCorreo; nunca el TEMP.
  sCarpeta := ExcludeTrailingPathDelimiter(ExtractFilePath(ARutaPdf));
  if SameText(
       ExcludeTrailingPathDelimiter(ExtractFilePath(sCarpeta)),
       ExcludeTrailingPathDelimiter(CarpetaTemporalCorreo)) and
     TDirectory.Exists(sCarpeta) and TDirectory.IsEmpty(sCarpeta) then
  begin
    if not RemoveDir(sCarpeta) then
      OutputDebugString(PChar(
        'inLibCorreoDocumentoVcl: carpeta temporal no eliminada ' +
        sCarpeta + ': ' + SysErrorMessage(GetLastError)));
  end;
end;

procedure EliminarPdfTemporalCorreo(const ARutaPdf: string;
  const ARegistroLog: IRegistroLog);
var
  sRutaPdf: string;
begin
  sRutaPdf := Trim(ARutaPdf);
  if EliminarDocumentoTemporalSeguro(sRutaPdf, ARegistroLog) then
    EliminarCarpetaPropiaVacia(sRutaPdf)
  else
    MessageDlg_fza(
      Format(SAvisoPdfTemporalCorreoNoEliminado, [sRutaPdf]),
      mtWarning,
      [mbOK],
      0);
end;

end.
