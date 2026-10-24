{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalSelFamiliasArbol                                    }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       18/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{  Descripción:                                                                }
{    Selector de familias en árbol jerárquico con marca en cascada, el         }
{    mismo de los filtros de los informes, para filtrar por familias           }
{    desde otras pantallas. Devuelve los códigos marcados como CSV.            }
{******************************************************************************}
unit inMtoModalSelFamiliasArbol;

interface

uses
  Winapi.Messages, System.Classes, Vcl.Controls, Vcl.ExtCtrls,
  inMtoModalAceptCancel,
  cxControls, cxContainer, cxEdit, cxLabel, cxTextEdit, cxButtons,
  cxTL, cxTLData, cxInplaceContainer,
  cxGraphics, cxLookAndFeels, cxLookAndFeelPainters,
  inLibFamiliasArbol, inLibFamiliasArbolVcl;

type
  // Selector de familias en árbol: el mismo de los filtros de informes
  // (jerarquía padre→subfamilias, marca en cascada y buscador), montado
  // en código sobre el modal de aceptar/cancelar. Devuelve los códigos
  // marcados como CSV; vacío = todas.
  TfrmSelFamiliasArbol = class(TfrmModalAceptCancel)
  private
    FArbol: TcxTreeList;
    FGestor: TArbolFamiliasVcl;
    FedtBuscar: TcxTextEdit;
    FCsvFamilias: string;
    procedure CrearControles;
    procedure ColocarBotonera;
    procedure BuscarChange(Sender: TObject);
    procedure QuitarSeleccionClick(Sender: TObject);
    procedure AceptarClick(Sender: TObject);
    procedure CancelarClick(Sender: TObject);
  protected
    procedure DoCreate; override;
  public
    constructor Create(AOwner: TComponent;
      const AFamilias: TFamiliasArbol;
      const ACsvFamilias: string); reintroduce;
    destructor Destroy; override;
    function IsShortCut(var Message: TWMKey): Boolean; override;
    property CsvFamilias: string read FCsvFamilias;
  end;

// Abre el selector con AFamilias y la selección actual de ACsvFamilias.
// False si se cancela, y entonces ACsvFamilias no cambia.
function SeleccionarFamiliasArbol(AOwner: TComponent;
  const AFamilias: TFamiliasArbol; var ACsvFamilias: string): Boolean;

implementation

uses
  Winapi.Windows, System.SysUtils, System.UITypes, Vcl.Forms,
  inLibMsgComun;

resourcestring
  STituloSeleccionarFamilias = 'Seleccionar familias';
  SCaptionIncluirFamilia = 'Incluir';
  SCaptionCodigoFamilia = 'Código';
  SCaptionQuitarSeleccionFamilias = 'Quitar selección';

// Medidas a 96 ppp: el DFM heredado ya viene escalado al PPI del
// monitor, así que lo que se fija en código pasa por ScaleValue.
const
  ANCHO_MODAL = 620;
  ALTO_MODAL = 560;
  ALTO_CABECERA = 60;
  MARGEN = 6;
  ALTO_CONTROL = 28;
  ANCHO_BUSCADOR = 360;
  ANCHO_BOTON_QUITAR = 170;
  ANCHO_BOTON_MODAL = 150;
  ALTO_BOTONERA = 50;
  MARGEN_BOTONERA = 9;
  MARGEN_DERECHO = 12;
  SEPARACION = 8;

constructor TfrmSelFamiliasArbol.Create(AOwner: TComponent;
  const AFamilias: TFamiliasArbol;
  const ACsvFamilias: string);
begin
  inherited Create(AOwner);
  FCsvFamilias := ACsvFamilias;
  CrearControles;
  FGestor := TArbolFamiliasVcl.Create(
    FArbol,
    SCaptionFamilia,
    SCaptionIncluirFamilia,
    SCaptionCodigoFamilia);
  FGestor.Cargar(AFamilias);
  FGestor.MarcarCsv(FCsvFamilias);
  if FCsvFamilias <> '' then
    FArbol.FullExpand;
  if Assigned(btnAceptar) then
    btnAceptar.OnClick := AceptarClick;
  if Assigned(btnCancelar) then
    btnCancelar.OnClick := CancelarClick;
  ClientWidth := ScaleValue(ANCHO_MODAL);
  ClientHeight := ScaleValue(ALTO_MODAL);
  ColocarBotonera;
end;

destructor TfrmSelFamiliasArbol.Destroy;
begin
  FreeAndNil(FGestor);
  inherited Destroy;
end;

procedure TfrmSelFamiliasArbol.DoCreate;
begin
  inherited;
  // FormCreate de TfrmBase traduce el Caption buscando su clave por la
  // jerarquía de clases: sin clave propia aplica la de TfrmBase.
  Caption := STituloSeleccionarFamilias;
end;

// Cabecera fija con la ayuda, el buscador y el botón de quitar marcas;
// debajo, el árbol al completo.
procedure TfrmSelFamiliasArbol.CrearControles;
var
  pnlTop: TPanel;
  lblAyuda: TcxLabel;
  btnQuitar: TcxButton;
begin
  pnlTop := TPanel.Create(Self);
  pnlTop.Parent := pnlBody;
  pnlTop.Align := alTop;
  pnlTop.BevelOuter := bvNone;
  pnlTop.Height := ScaleValue(ALTO_CABECERA);
  lblAyuda := TcxLabel.Create(Self);
  lblAyuda.Parent := pnlTop;
  lblAyuda.Transparent := True;
  lblAyuda.Left := ScaleValue(MARGEN);
  lblAyuda.Top := ScaleValue(MARGEN);
  lblAyuda.Caption := SCaptionDobleClicMarcaFamilia;
  FedtBuscar := TcxTextEdit.Create(Self);
  FedtBuscar.Parent := pnlTop;
  FedtBuscar.Left := ScaleValue(MARGEN);
  FedtBuscar.Top := ScaleValue(ALTO_CABECERA - ALTO_CONTROL - MARGEN);
  FedtBuscar.Width := ScaleValue(ANCHO_BUSCADOR);
  FedtBuscar.Hint := SHintBuscarFamilia;
  FedtBuscar.ShowHint := True;
  FedtBuscar.Properties.OnEditValueChanged := BuscarChange;
  btnQuitar := TcxButton.Create(Self);
  btnQuitar.Parent := pnlTop;
  btnQuitar.Left := ScaleValue(MARGEN + ANCHO_BUSCADOR + SEPARACION);
  btnQuitar.Top := ScaleValue(ALTO_CABECERA - ALTO_CONTROL - MARGEN);
  btnQuitar.Width := ScaleValue(ANCHO_BOTON_QUITAR);
  btnQuitar.Height := ScaleValue(ALTO_CONTROL);
  btnQuitar.Caption := SCaptionQuitarSeleccionFamilias;
  btnQuitar.OnClick := QuitarSeleccionClick;
  FArbol := TcxTreeList.Create(Self);
  FArbol.Parent := pnlBody;
  FArbol.Align := alClient;
  FArbol.AlignWithMargins := True;
  FArbol.Margins.SetBounds(
    ScaleValue(MARGEN),
    ScaleValue(MARGEN),
    ScaleValue(MARGEN),
    ScaleValue(MARGEN));
end;

// La botonera del DFM base está pensada para modales anchos: aquí los
// dos botones se agrupan a la derecha.
procedure TfrmSelFamiliasArbol.ColocarBotonera;

  procedure Colocar(ABoton: TcxButton; AMargenDerecho: Integer);
  begin
    ABoton.Width := ScaleValue(ANCHO_BOTON_MODAL);
    ABoton.AlignWithMargins := True;
    ABoton.Margins.SetBounds(
      0,
      ScaleValue(MARGEN_BOTONERA),
      ScaleValue(AMargenDerecho),
      ScaleValue(MARGEN_BOTONERA));
    ABoton.Align := alRight;
  end;

begin
  pnlButton.Height := ScaleValue(ALTO_BOTONERA);
  if Assigned(btnAceptar) then
    Colocar(btnAceptar, MARGEN_DERECHO);
  if Assigned(btnCancelar) then
    Colocar(btnCancelar, SEPARACION);
end;

procedure TfrmSelFamiliasArbol.BuscarChange(Sender: TObject);
begin
  FGestor.Filtrar(FedtBuscar.Text);
end;

procedure TfrmSelFamiliasArbol.QuitarSeleccionClick(Sender: TObject);
begin
  FGestor.Desmarcar;
end;

procedure TfrmSelFamiliasArbol.AceptarClick(Sender: TObject);
begin
  FCsvFamilias := FGestor.CsvMarcadas;
  ModalResult := mrOk;
end;

procedure TfrmSelFamiliasArbol.CancelarClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

function TfrmSelFamiliasArbol.IsShortCut(var Message: TWMKey): Boolean;
begin
  if Message.CharCode = VK_ESCAPE then
  begin
    CancelarClick(Self);
    Result := True;
  end
  else if Message.CharCode = VK_F12 then
  begin
    // La acción F12 heredada llama al btnAceptarClick de la base, que
    // cierra como Cancelar, no al OnClick que asigna el constructor.
    AceptarClick(Self);
    Result := True;
  end
  else
    Result := inherited IsShortCut(Message);
end;

function SeleccionarFamiliasArbol(AOwner: TComponent;
  const AFamilias: TFamiliasArbol; var ACsvFamilias: string): Boolean;
var
  frm: TfrmSelFamiliasArbol;
begin
  frm := TfrmSelFamiliasArbol.Create(AOwner, AFamilias, ACsvFamilias);
  try
    Result := frm.ShowModal = mrOk;
    if Result then
      ACsvFamilias := frm.CsvFamilias;
  finally
    FreeAndNil(frm);
  end;
end;

end.
