unit inMtoModalSesionMaterializar;

{
  Modal de confirmación previa a la materialización de una sesión de compra.

  Muestra al usuario un resumen de lo que se va a generar (artículos, SKUs,
  EAN13, propiedades, enlaces a proveedor) y deja elegir si genera pedido
  de compra, albarán de compra, ambos o ninguno (sólo creación de artículos).

  Devuelve mrOk si el usuario confirma. Las flags ESGeneraPedido /
  ESGeneraAlbaran quedan en propiedades públicas.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.StdCtrls, System.Actions, Vcl.ActnList,
  inMtoFrmBase, JvComponentBase, JvEnterTab,
  cxClasses, cxLocalization, cxGraphics, cxLookAndFeels,
  cxLookAndFeelPainters, Vcl.Menus, cxButtons, cxContainer, cxEdit, cxLabel,
  cxCheckBox;

type
  TfrmModalSesionMaterializar = class(TfrmBase)
    pnlButton       : TPanel;
    btnCancelar     : TcxButton;
    btnAceptar      : TcxButton;
    pnlBody         : TPanel;
    lblTitulo       : TcxLabel;
    lblResumen      : TcxLabel;
    chkPedido       : TcxCheckBox;
    chkAlbaran      : TcxCheckBox;
    lblAviso        : TcxLabel;
    ActionList1     : TActionList;
    actAceptar      : TAction;
    actCancelar     : TAction;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure actAceptarExecute(Sender: TObject);
    procedure actCancelarExecute(Sender: TObject);
  private
    FESGeneraPedido  : Boolean;
    FESGeneraAlbaran : Boolean;
  public
    property ESGeneraPedido: Boolean read FESGeneraPedido
      write FESGeneraPedido;
    property ESGeneraAlbaran: Boolean read FESGeneraAlbaran
      write FESGeneraAlbaran;
  end;

implementation

{$R *.dfm}

procedure TfrmModalSesionMaterializar.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
end;

procedure TfrmModalSesionMaterializar.FormShow(Sender: TObject);
begin
  inherited;
  chkPedido.Checked  := FESGeneraPedido;
  chkAlbaran.Checked := FESGeneraAlbaran;
  if btnAceptar.CanBeFocused then btnAceptar.SetFocus;
end;

procedure TfrmModalSesionMaterializar.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  inherited;
  Action := caFree;
end;

procedure TfrmModalSesionMaterializar.btnAceptarClick(Sender: TObject);
begin
  inherited;
  FESGeneraPedido  := chkPedido.Checked;
  FESGeneraAlbaran := chkAlbaran.Checked;
  ModalResult := mrOk;
end;

procedure TfrmModalSesionMaterializar.btnCancelarClick(Sender: TObject);
begin
  inherited;
  ModalResult := mrCancel;
end;

procedure TfrmModalSesionMaterializar.actAceptarExecute(Sender: TObject);
begin
  inherited;
  btnAceptarClick(Sender);
end;

procedure TfrmModalSesionMaterializar.actCancelarExecute(Sender: TObject);
begin
  inherited;
  btnCancelarClick(Sender);
end;

end.
