{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalTiraCaja                                            }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       2.0.0                                                         }
{   Fecha:       18/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pregunta las opciones de la "tira de caja" antes de imprimirla: las       }
{    series de factura simplificada (multi-selección; ninguna marcada = todas),}
{    el agrupamiento (por tipo de documento o por orden cronológico) y si se   }
{    imprime el QR tributario por operación (solo cuando Verifactu está activo }
{    con envío PRE o PRO). Además ofrece incluir, de forma opcional, los       }
{    traspasos salientes (origen), los ingresos por caja, los gastos por caja  }
{    y las ventas a crédito (depósitos). Devuelve la elección por Ejecutar.    }
{******************************************************************************}
unit inMtoModalTiraCaja;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxTextEdit, cxMaskEdit, cxDropDownEdit,
  cxCheckBox, cxCheckComboBox, cxLabel, cxButtons, cxClasses, cxStyles,
  inMtoFrmBase;

type
  TfrmModalTiraCaja = class(TfrmBase)
    lblTitulo: TcxLabel;
    lblSerie: TcxLabel;
    ccbSerie: TcxCheckComboBox;
    lblAgrupamiento: TcxLabel;
    cbAgrupamiento: TcxComboBox;
    chkQR: TcxCheckBox;
    chkTraspasos: TcxCheckBox;
    chkIngresos: TcxCheckBox;
    chkGastos: TcxCheckBox;
    chkCredito: TcxCheckBox;
    btnImprimir: TcxButton;
    btnExcel: TcxButton;
    btnCancelar: TcxButton;
    procedure FormCreate(Sender: TObject);
  private
    FVerifactu: Boolean;
  public
    // Devuelve True si el usuario pulsa Imprimir o Ver Excel.
    //   ASeleccionSeries : series marcadas; vacío = todas las series.
    //   AImprimirQR      : solo puede salir True si AVerifactu lo era.
    //   ACronologico     : True = orden cronológico; False = por tipo de doc.
    //   AExcel           : True si se pulsó "Ver Excel" (en vez de Imprimir).
    //   AIncluir*        : bloques opcionales a adjuntar (traspasos, ingresos,
    //                      gastos, ventas a crédito).
    class function Ejecutar(AOwner: TComponent;
                            const ACaja: string;
                            const ASeries: TArray<string>;
                            AVerifactu: Boolean;
                            out ASeleccionSeries: TArray<string>;
                            out AImprimirQR: Boolean;
                            out ACronologico: Boolean;
                            out AExcel: Boolean;
                            out AIncluirTraspasos: Boolean;
                            out AIncluirIngresos: Boolean;
                            out AIncluirGastos: Boolean;
                            out AIncluirCredito: Boolean): Boolean;
  end;

implementation

{$R *.dfm}

uses
  inLibMsgCaja;

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmModalTiraCaja }

class function TfrmModalTiraCaja.Ejecutar(AOwner: TComponent;
                                          const ACaja: string;
                                          const ASeries: TArray<string>;
                                          AVerifactu: Boolean;
                                          out ASeleccionSeries: TArray<string>;
                                          out AImprimirQR: Boolean;
                                          out ACronologico: Boolean;
                                          out AExcel: Boolean;
                                          out AIncluirTraspasos: Boolean;
                                          out AIncluirIngresos: Boolean;
                                          out AIncluirGastos: Boolean;
                                          out AIncluirCredito: Boolean):
                                          Boolean;
var
  Frm: TfrmModalTiraCaja;
  Item: TcxCheckComboBoxItem;
  iResultado, i: Integer;
begin
  Result            := False;
  SetLength(ASeleccionSeries, 0);
  AImprimirQR       := False;
  ACronologico      := False;
  AExcel            := False;
  AIncluirTraspasos := False;
  AIncluirIngresos  := False;
  AIncluirGastos    := False;
  AIncluirCredito   := False;
  Frm := TfrmModalTiraCaja.Create(AOwner);
  try
    Frm.FVerifactu := AVerifactu;
    Frm.lblTitulo.Caption := Format(STituloTiraCajaNumero, [ACaja]);
    // Una entrada por serie; sin marcar ninguna se entienden todas. El índice
    // de cada item coincide con el de ASeries para mapear marcado -> serie.
    Frm.ccbSerie.Properties.Items.Clear;
    for i := 0 to High(ASeries) do
    begin
      Item := Frm.ccbSerie.Properties.Items.Add;
      Item.Description := ASeries[i];
    end;
    Frm.ccbSerie.Properties.EmptySelectionText := SCaptionTodasLasSeries;
    // Los ítems recién añadidos salen desmarcados (ninguna serie = todas).
    // Agrupamiento: por tipo de documento (índice 0) o cronológico (índice 1).
    Frm.cbAgrupamiento.Properties.Items.Clear;
    Frm.cbAgrupamiento.Properties.Items.Add(
      SCaptionAgrupamientoPorTipoDocumento);
    Frm.cbAgrupamiento.Properties.Items.Add(
      SCaptionAgrupamientoPorOrdenCronologico);
    Frm.cbAgrupamiento.ItemIndex := 0;
    // El QR solo se ofrece (y marca por defecto) si Verifactu está activo.
    Frm.chkQR.Enabled := AVerifactu;
    Frm.chkQR.Checked := AVerifactu;
    if not AVerifactu then
      Frm.chkQR.Caption := SCaptionImprimirQrNoDisponible;
    // Bloques opcionales: desmarcados por defecto, son ampliaciones de la tira.
    Frm.chkTraspasos.Checked := False;
    Frm.chkIngresos.Checked  := False;
    Frm.chkGastos.Checked    := False;
    Frm.chkCredito.Checked   := False;
    // Imprimir -> mrOk; Ver Excel -> mrYes. Ambos devuelven las selecciones.
    iResultado := Frm.ShowModal;
    if (iResultado = mrOk) or (iResultado = mrYes) then
    begin
      // Series marcadas (por índice). Si no hay ninguna, se deja vacío = todas.
      for i := 0 to High(ASeries) do
        if Frm.ccbSerie.States[i] = cbsChecked then
        begin
          SetLength(ASeleccionSeries, Length(ASeleccionSeries) + 1);
          ASeleccionSeries[High(ASeleccionSeries)] := ASeries[i];
        end;
      ACronologico      := Frm.cbAgrupamiento.ItemIndex = 1;
      AExcel            := iResultado = mrYes;
      AImprimirQR       := Frm.chkQR.Checked and AVerifactu;
      AIncluirTraspasos := Frm.chkTraspasos.Checked;
      AIncluirIngresos  := Frm.chkIngresos.Checked;
      AIncluirGastos    := Frm.chkGastos.Checked;
      AIncluirCredito   := Frm.chkCredito.Checked;
      Result := True;
    end;
  finally
    FreeAndNil(Frm);
  end;
end;

procedure TfrmModalTiraCaja.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
end;

initialization
  ForceReferenceToClass(TfrmModalTiraCaja);
end.
