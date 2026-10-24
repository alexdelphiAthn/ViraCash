{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCalculadoraVcl                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.2.0                                                         }
{   Fecha:       15/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Calculadora auxiliar de la aplicación, sobre el control de DevExpress.    }
{                                                                              }
{    Sustituye a la de JVCL, que montaba su ventana a mano con medidas         }
{    fijas pensadas para 96 puntos por pulgada: con el escalado de Windows     }
{    por encima del 100 % el panel de botones crecía, la ventana no, y las     }
{    últimas filas quedaban cortadas.                                          }
{                                                                              }
{    El control de DevExpress es solo la botonera y está pensado para          }
{    acompañar a un TcxCalcEdit: es el editor quien guarda y enseña el         }
{    número, y quien decide si se admite escritura. Suelto no funciona, así    }
{    que aquí se le da ese papel desde el propio control derivado y la         }
{    ventana pinta el visor.                                                   }
{                                                                              }
{    La ventana se dimensiona según los puntos por pulgada reales, así que     }
{    se ve igual a cualquier escala. No devuelve ningún valor: es una          }
{    calculadora de apoyo, como la anterior.                                   }
{******************************************************************************}
unit inLibCalculadoraVcl;

interface

uses
  System.Classes;

// Abre la calculadora como ventana modal, centrada sobre APropietario.
procedure MostrarCalculadora(APropietario: TComponent);

implementation

uses
  Winapi.Windows, System.Math, System.SysUtils, System.UITypes,
  Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.ExtCtrls,
  cxCalc, cxTextEdit;

resourcestring
  SCaptionCalculadora = 'Calculadora';

const
  // Medidas de referencia a 96 puntos por pulgada; se reescalan al DPI
  // real de la pantalla.
  ANCHO_BASE_CALCULADORA = 240;
  ALTO_BASE_BOTONERA = 160;
  ALTO_BASE_VISOR = 30;
  PPP_REFERENCIA = 96;
  TAMANO_FUENTE_VISOR = 14;

type
  // Hace de editor de la botonera: guarda el texto que ella escribe,
  // declara que se admite escritura (sin esto no entra ninguna tecla) y
  // avisa a la ventana para que refresque el visor.
  TCalculadoraCx = class(TcxCustomCalculator)
  strict private
    FTexto: string;
    FAlCambiarTexto: TNotifyEvent;
  protected
    function GetEditorValue: string; override;
    procedure SetEditorValue(const AValor: string); override;
    function GetReadOnly: Boolean; override;
  public
    property Texto: string read FTexto;
    property AlCambiarTexto: TNotifyEvent
      read FAlCambiarTexto write FAlCambiarTexto;
    property AutoFontSize;
    property BorderStyle;
    property Color;
    property ParentColor;
  end;

  TFormularioCalculadora = class(TForm)
  strict private
    FVisor: TcxTextEdit;
    FContenedor: TPanel;
    FCalculadora: TCalculadoraCx;
    procedure ActualizarVisor(ASender: TObject);
    procedure TeclaPulsada(
      ASender: TObject;
      var AKey: Word;
      AShift: TShiftState);
  public
    constructor CrearCalculadora(AOwner: TComponent); reintroduce;
  end;

function TCalculadoraCx.GetEditorValue: string;
begin
  Result := FTexto;
end;

procedure TCalculadoraCx.SetEditorValue(const AValor: string);
begin
  FTexto := AValor;
  if Assigned(FAlCambiarTexto) then
    FAlCambiarTexto(Self);
end;

function TCalculadoraCx.GetReadOnly: Boolean;
begin
  Result := False;
end;

function EscalarAPantalla(AMedida: Integer): Integer;
begin
  Result := MulDiv(AMedida, Screen.PixelsPerInch, PPP_REFERENCIA);
end;

constructor TFormularioCalculadora.CrearCalculadora(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := SCaptionCalculadora;
  BorderStyle := bsDialog;
  BorderIcons := [biSystemMenu];
  Position := poScreenCenter;
  KeyPreview := True;
  OnKeyDown := TeclaPulsada;
  ClientWidth := EscalarAPantalla(ANCHO_BASE_CALCULADORA);
  ClientHeight := EscalarAPantalla(
    ALTO_BASE_VISOR + ALTO_BASE_BOTONERA);

  FVisor := TcxTextEdit.Create(Self);
  FVisor.Parent := Self;
  FVisor.Align := alTop;
  FVisor.Height := EscalarAPantalla(ALTO_BASE_VISOR);
  FVisor.TabStop := False;
  FVisor.Properties.ReadOnly := True;
  FVisor.Properties.Alignment.Horz := taRightJustify;
  FVisor.Style.Font.Size := TAMANO_FUENTE_VISOR;
  FVisor.Text := '0';

  // La botonera rellena su fondo con el rectángulo que ocupa dentro del
  // padre, no con el suyo propio. Colgada del formulario, debajo del
  // visor, empezaría a pintar a la altura del visor y dejaría una banda
  // negra arriba: se ve en el hueco de la primera fila, donde no hay
  // botón que la tape. Dentro de este contenedor arranca en cero y los
  // dos rectángulos coinciden.
  FContenedor := TPanel.Create(Self);
  FContenedor.Parent := Self;
  FContenedor.Align := alClient;
  FContenedor.BevelOuter := bvNone;
  FContenedor.ParentBackground := False;

  FCalculadora := TCalculadoraCx.Create(Self);
  FCalculadora.Parent := FContenedor;
  FCalculadora.Align := alClient;
  FCalculadora.BorderStyle := bsNone;
  FCalculadora.ParentColor := True;
  // Reparte el tamaño disponible entre los botones, de modo que el
  // texto acompaña al escalado en vez de desbordarlo.
  FCalculadora.AutoFontSize := True;
  FCalculadora.TabStop := True;
  FCalculadora.AlCambiarTexto := ActualizarVisor;
  ActiveControl := FCalculadora;
end;

procedure TFormularioCalculadora.ActualizarVisor(ASender: TObject);
begin
  if Trim(FCalculadora.Texto) = '' then
    FVisor.Text := '0'
  else
    FVisor.Text := FCalculadora.Texto;
end;

procedure TFormularioCalculadora.TeclaPulsada(
  ASender: TObject;
  var AKey: Word;
  AShift: TShiftState);
begin
  if (AKey = vkEscape) and (AShift = []) then
  begin
    AKey := 0;
    Close;
  end;
end;

procedure MostrarCalculadora(APropietario: TComponent);
var
  oFormulario: TFormularioCalculadora;
begin
  oFormulario := TFormularioCalculadora.CrearCalculadora(APropietario);
  try
    oFormulario.ShowModal;
  finally
    oFormulario.Free;
  end;
end;

end.
