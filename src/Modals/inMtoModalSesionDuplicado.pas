unit inMtoModalSesionDuplicado;

{
  Modal de resolución de duplicado de código de artículo en una sesión.

  Cuando el usuario teclea en una línea de la sesión un CODIGO_ART que ya
  existe en fza_articulos, este diálogo le ofrece tres caminos:

    - REUSAR    : la sesión enlaza al artículo existente y NO crea uno nuevo.
                  Al materializar se generarán los SKUs faltantes y se
                  añadirán códigos de barras sólo para las celdas con cantidad.
    - RENOMBRAR : el usuario teclea un código nuevo. Se reaplica la
                  detección de duplicados sobre ese nuevo código.
    - CANCELAR  : el diálogo se cierra sin elección. La línea queda marcada
                  como duplicada (esdduplicado_seslin='S') y bloquea la
                  materialización.

  La acción elegida se devuelve en la propiedad Accion, y si fue REUSAR se
  conserva en CodigoArt el código a reutilizar. Si fue RENOMBRAR, CodigoArt
  trae el código nuevo tecleado por el usuario.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.StdCtrls, System.Actions, Vcl.ActnList,
  inMtoFrmBase, JvComponentBase, JvEnterTab,
  cxClasses, cxLocalization, cxGraphics, cxLookAndFeels,
  cxLookAndFeelPainters, Vcl.Menus, cxButtons, cxContainer, cxEdit, cxLabel,
  cxTextEdit, cxRadioGroup;

type
  TfrmModalSesionDuplicado = class(TfrmBase)
    pnlBody         : TPanel;
    pnlButton       : TPanel;
    btnAceptar      : TcxButton;
    btnCancelar     : TcxButton;
    lblTitulo       : TcxLabel;
    lblCodigoExistente : TcxLabel;
    txtCodigo       : TcxTextEdit;
    rgAccion        : TcxRadioGroup;
    lblDescripcionExistente : TcxLabel;
    ActionList1     : TActionList;
    actAceptar      : TAction;
    actCancelar     : TAction;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure rgAccionPropertiesEditValueChanged(Sender: TObject);
    procedure actAceptarExecute(Sender: TObject);
    procedure actCancelarExecute(Sender: TObject);
  private
    FCodigoArt   : string;
    FAccion      : string; // REUSAR | RENOMBRAR | (vacío = cancelar)
    FDescripcion : string;
    FLineaOrigen: Integer;
  public
    property CodigoArt   : string read FCodigoArt   write FCodigoArt;
    property Accion      : string read FAccion;
    property Descripcion : string read FDescripcion write FDescripcion;
    property LineaOrigen: Integer read FLineaOrigen write FLineaOrigen;
  end;

implementation

{$R *.dfm}

uses
  inLibMsgCompras, inLibMensajesVcl;

procedure TfrmModalSesionDuplicado.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
end;

procedure TfrmModalSesionDuplicado.FormShow(Sender: TObject);
begin
  inherited;
  if FLineaOrigen > 0 then
    lblTitulo.Caption := Format(SCaptionCodigoPropuestoEnLinea,
      [FCodigoArt, FLineaOrigen])
  else
    lblTitulo.Caption := SCaptionCodigoPropuestoExistente;
  lblCodigoExistente.Caption := Format(SCaptionCodigoExistente,
                                       [FCodigoArt]);
  lblDescripcionExistente.Caption := FDescripcion;
  txtCodigo.Text := '';
  rgAccion.ItemIndex := 1;
  txtCodigo.Enabled := True;
  if FLineaOrigen > 0 then
    rgAccion.Properties.Items[0].Caption := SCaptionReusarArticuloSesion;
  btnCancelar.Caption := SCaptionCodigoDejarPendiente;
  // La VCL da el foco cuando la ventana termina de mostrarse.
  ActiveControl := txtCodigo;
end;

procedure TfrmModalSesionDuplicado.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  inherited;
  Action := caHide;
end;

procedure TfrmModalSesionDuplicado.rgAccionPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  txtCodigo.Enabled := (rgAccion.ItemIndex = 1);
end;

procedure TfrmModalSesionDuplicado.btnAceptarClick(Sender: TObject);
var
  bAceptar: Boolean;
  sCodigoNuevo: string;
begin
  inherited;
  bAceptar := True;
  case rgAccion.ItemIndex of
    0: FAccion := 'REUSAR';
    1: begin
         sCodigoNuevo := StringReplace(Trim(txtCodigo.Text), '/', '-',
           [rfReplaceAll]);
         bAceptar := (sCodigoNuevo <> '') and
           (Length(sCodigoNuevo) <= 20) and
           not SameText(sCodigoNuevo, FCodigoArt);
         if bAceptar then
         begin
           FAccion := 'RENOMBRAR';
           FCodigoArt := sCodigoNuevo;
         end
         else
           ShowMessage_fza(SErrorCodigoNuevoSesion);
       end;
  else
    FAccion := '';
  end;
  if bAceptar then
    ModalResult := mrOk;
end;

procedure TfrmModalSesionDuplicado.btnCancelarClick(Sender: TObject);
begin
  inherited;
  FAccion := '';
  ModalResult := mrCancel;
end;

procedure TfrmModalSesionDuplicado.actAceptarExecute(Sender: TObject);
begin
  inherited;
  btnAceptarClick(Sender);
end;

procedure TfrmModalSesionDuplicado.actCancelarExecute(Sender: TObject);
begin
  inherited;
  btnCancelarClick(Sender);
end;

end.
