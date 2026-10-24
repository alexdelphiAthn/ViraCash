{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalGenImpSave                                          }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal para guardar un formato de impresion personalizado.                 }
{    Solicita nombre, descripcion y permisos del nuevo formato.                }
{******************************************************************************}
unit inMtoModalGenImpSave;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  inMtoFrmBase, dxSkinsForm, cxClasses, cxContainer, cxEdit, cxLookAndFeels,
  cxLocalization, cxGraphics, cxControls, cxLookAndFeelPainters, cxLabel,
  cxTextEdit, Vcl.Menus, Vcl.StdCtrls, cxButtons, dxCore, cxMaskEdit,
  cxDropDownEdit, cxStyles, JvComponentBase, JvEnterTab,
  inLibLayoutForm;

type
  TfrmModalGenImpSave = class(TfrmBase)
    edtNombreOrigen: TcxTextEdit;
    lbl1: TcxLabel;
    edtDescripcion: TcxTextEdit;
    lbl2: TcxLabel;
    lbl3: TcxLabel;
    btnGuardar: TcxButton;
    btnCancelar: TcxButton;
    cbbPermisos: TcxComboBox;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnGuardarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FDescripcionSeleccionada: Boolean;
    procedure SeleccionarDescripcion;
  protected
    procedure DoShow; override;
    procedure Activate; override;
  public
    { Public declarations }
    sFicha:string;
  end;

function CrearSolicitudPermisoLayoutMto: ISolicitudPermisoLayout;

implementation

uses
  inLibGlobalVar, inLibMsgComun;

type
  TSolicitudPermisoLayoutMto = class(
    TInterfacedObject,
    ISolicitudPermisoLayout)
  public
    function Solicitar(const AFormKey, ADescripcion: string;
                       out APermisos: string): Boolean;
  end;

{$R *.dfm}

function CrearSolicitudPermisoLayoutMto: ISolicitudPermisoLayout;
begin
  Result := TSolicitudPermisoLayoutMto.Create;
end;

function TSolicitudPermisoLayoutMto.Solicitar(
  const AFormKey, ADescripcion: string;
  out APermisos: string): Boolean;
var
  oFormulario: TfrmModalGenImpSave;
begin
  Result := False;
  APermisos := '';
  oFormulario := TfrmModalGenImpSave.Create(Application);
  try
    oFormulario.edtNombreOrigen.Text := AFormKey;
    oFormulario.edtDescripcion.Enabled := False;
    oFormulario.edtDescripcion.Text := ADescripcion;
    oFormulario.ShowModal;
    if oFormulario.sFicha = 'S' then
    begin
      APermisos := oFormulario.cbbPermisos.Text;
      Result := True;
    end;
  finally
    FreeAndNil(oFormulario);
  end;
end;

procedure TfrmModalGenImpSave.btnCancelarClick(Sender: TObject);
begin
  inherited;
//  PostMessage(Handle, WM_CLOSE, 0, 0);
  ModalResult := mrOk;
end;

procedure TfrmModalGenImpSave.btnGuardarClick(Sender: TObject);
begin
  inherited;
  // El desplegable muestra «Todos» traducido; quien llama lee
  // cbbPermisos.Text y debe recibir el valor almacenado (oAll).
  if SameText(Trim(cbbPermisos.Text), SPermisoFormatoTodos) then
    cbbPermisos.Text := oAll;
  sFicha := 'S';
//  PostMessage(Handle, WM_CLOSE, 0, 0);
  ModalResult := mrOk;
end;

procedure TfrmModalGenImpSave.SeleccionarDescripcion;
begin
  // FZ-ISSUE-096: el nombre propuesto (p. ej. "Predeterminado") queda
  // seleccionado; al escribir se sustituye en lugar de concatenarse.
  if edtDescripcion.Enabled and edtDescripcion.CanFocus then
  begin
    ActiveControl := edtDescripcion;
    edtDescripcion.SelectAll;
  end;
end;

procedure TfrmModalGenImpSave.DoShow;
begin
  inherited;
  SeleccionarDescripcion;
end;

procedure TfrmModalGenImpSave.Activate;
begin
  inherited;
  // El foco llega al activarse la ventana: se repite una sola vez por
  // si el editor recoloca el cursor al recibirlo.
  if not FDescripcionSeleccionada then
  begin
    FDescripcionSeleccionada := True;
    SeleccionarDescripcion;
  end;
end;

procedure TfrmModalGenImpSave.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  inherited;
//  Action := caFree;
end;

procedure TfrmModalGenImpSave.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
  cbbPermisos.Properties.Items.BeginUpdate;
  try
    cbbPermisos.Properties.Items.Clear;
    cbbPermisos.Properties.Items.Add(IdentidadSesion.Usuario);
    cbbPermisos.Properties.Items.Add(IdentidadSesion.Grupo);
    if IdentidadSesion.GrupoRaiz = 'S' then
      cbbPermisos.Properties.Items.Add(SPermisoFormatoTodos);
    cbbpermisos.Text := IdentidadSesion.Usuario;
  finally
    cbbPermisos.Properties.Items.EndUpdate;
  end;
end;

end.
