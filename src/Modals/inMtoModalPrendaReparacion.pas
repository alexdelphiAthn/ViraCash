{******************************************************************************}
{  Módulo: inMtoModalPrendaReparacion                                          }
{  Descripción: Selección de la unidad vendida que queda en reparación.        }
{******************************************************************************}
unit inMtoModalPrendaReparacion;

interface

uses
  System.Classes, Vcl.Forms, cxDropDownEdit, inMtoModalAceptCancel,
  inLibReparaciones;

type
  TfrmModalPrendaReparacion = class(TfrmModalAceptCancel)
  private
    FPrenda: TcxComboBox;
    procedure CrearSelector(const ATitulo: string;
      const APrendas: TArray<TPrendaVentaReparacion>);
    procedure CerrarSinLiberar(Sender: TObject; var Action: TCloseAction);
  public
    function CloseQuery: Boolean; override;
    class function Elegir(AOwner: TComponent; const ATitulo: string;
      const APrendas: TArray<TPrendaVentaReparacion>;
      out ASeleccion: Integer): Boolean;
  end;

implementation

uses
  System.SysUtils, System.UITypes, cxLabel, inLibMsgReparaciones,
  inLibMensajesVcl;

procedure TfrmModalPrendaReparacion.CrearSelector(const ATitulo: string;
  const APrendas: TArray<TPrendaVentaReparacion>);
var
  oRotulo: TcxLabel;
  Prenda: TPrendaVentaReparacion;
begin
  Caption := ATitulo;
  ClientWidth := ScaleValue(680);
  ClientHeight := ScaleValue(155);
  oRotulo := TcxLabel.Create(Self);
  oRotulo.Parent := pnlBody;
  oRotulo.Caption := SPrendaElegir;
  oRotulo.SetBounds(ScaleValue(12),ScaleValue(12),ScaleValue(630),
    ScaleValue(24));
  FPrenda := TcxComboBox.Create(Self);
  FPrenda.Parent := pnlBody;
  FPrenda.SetBounds(ScaleValue(12),ScaleValue(48),ScaleValue(640),
    ScaleValue(28));
  FPrenda.Properties.DropDownListStyle := lsFixedList;
  FPrenda.Properties.Items.Add(SPrendaFueraVenta);
  for Prenda in APrendas do
    FPrenda.Properties.Items.Add(Prenda.Descripcion);
  FPrenda.ItemIndex := -1;
end;

function TfrmModalPrendaReparacion.CloseQuery: Boolean;
begin
  Result := inherited CloseQuery;
  if Result and (sFicha='S') and (FPrenda.ItemIndex<0) then
  begin
    ShowMessage_fza(SPrendaSinSeleccion);
    Result := False;
  end;
end;

procedure TfrmModalPrendaReparacion.CerrarSinLiberar(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caHide;
end;

class function TfrmModalPrendaReparacion.Elegir(AOwner: TComponent;
  const ATitulo: string; const APrendas: TArray<TPrendaVentaReparacion>;
  out ASeleccion: Integer): Boolean;
var
  oFormulario: TfrmModalPrendaReparacion;
begin
  ASeleccion := -1;
  oFormulario := TfrmModalPrendaReparacion.Create(AOwner);
  try
    oFormulario.OnClose := oFormulario.CerrarSinLiberar;
    oFormulario.CrearSelector(ATitulo,APrendas);
    oFormulario.ShowModal;
    Result := oFormulario.sFicha='S';
    if Result then
      ASeleccion := oFormulario.FPrenda.ItemIndex-1;
  finally
    oFormulario.Free;
  end;
end;

end.
