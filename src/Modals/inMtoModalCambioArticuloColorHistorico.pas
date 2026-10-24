{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalCambioArticuloColorHistorico                        }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Consulta los últimos cambios y fusiones de artículos o colores.           }
{******************************************************************************}
unit inMtoModalCambioArticuloColorHistorico;

interface

uses
  System.Classes, System.SysUtils,
  Vcl.Controls, Vcl.ExtCtrls, Vcl.Forms,
  cxButtons, cxCalendar, cxClasses, cxControls, cxCustomData, cxData,
  cxDataStorage, cxEdit, cxFilter, cxGraphics, cxGrid, cxGridCustomTableView,
  cxGridCustomView, cxGridLevel, cxGridTableView, cxLabel,
  cxLookAndFeelPainters, cxLookAndFeels, cxNavigator, cxStyles,
  dxDateRanges, dxScrollbarAnnotations,
  inMtoFrmBase, inLibCambioArticuloColorHistoricoConsultaIntf;

type
  TfrmModalHistoricoArtColor = class(TfrmBase)
    pnlSuperior: TPanel;
    lblTitulo: TcxLabel;
    lblAyuda: TcxLabel;
    cxgrdHistorico: TcxGrid;
    tvHistorico: TcxGridTableView;
    colInstante: TcxGridColumn;
    colTipo: TcxGridColumn;
    colOrigen: TcxGridColumn;
    colDestino: TcxGridColumn;
    colUnidades: TcxGridColumn;
    colUsuario: TcxGridColumn;
    colEstado: TcxGridColumn;
    cxgrdlvlHistorico: TcxGridLevel;
    pnlBotones: TPanel;
    lblResultado: TcxLabel;
    btnCerrar: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
  private
    FConsulta: IConsultaCambioArticuloColorHistorico;
    function TextoEstado(
      AEstado: TEstadoHistoricoCambioArticuloColor): string;
    function TextoTipo(ATipo: TTipoHistoricoCambioArticuloColor): string;
    procedure ActualizarResumen(ACantidad: Integer);
    procedure CargarHistorico;
  public
    class procedure Ejecutar(
      AOwner: TComponent;
      const AConsulta: IConsultaCambioArticuloColorHistorico);
  end;

implementation

uses
  inLibMsgCambioArticuloColor;

{$R *.dfm}

const
  CANTIDAD_MAXIMA_HISTORICO = 100;

class procedure TfrmModalHistoricoArtColor.Ejecutar(
  AOwner: TComponent;
  const AConsulta: IConsultaCambioArticuloColorHistorico);
var
  oFormulario: TfrmModalHistoricoArtColor;
begin
  if not Assigned(AConsulta) then
    raise EArgumentNilException.Create('AConsulta');
  oFormulario := TfrmModalHistoricoArtColor.Create(AOwner);
  try
    oFormulario.FConsulta := AConsulta;
    oFormulario.ShowModal;
  finally
    oFormulario.FConsulta := nil;
    FreeAndNil(oFormulario);
  end;
end;

procedure TfrmModalHistoricoArtColor.FormCreate(Sender: TObject);
begin
  inherited;
  Self.KeyPreview := True;
  Self.Position := poScreenCenter;
end;

procedure TfrmModalHistoricoArtColor.FormShow(Sender: TObject);
begin
  inherited;
  CargarHistorico;
end;

procedure TfrmModalHistoricoArtColor.CargarHistorico;
var
  aCambios: TCambiosArticuloColorHistorico;
  i: Integer;
begin
  Screen.Cursor := crHourGlass;
  try
    aCambios := FConsulta.ConsultarUltimos(CANTIDAD_MAXIMA_HISTORICO);
    tvHistorico.DataController.RecordCount := 0;
    tvHistorico.DataController.RecordCount := Length(aCambios);
    for i := 0 to High(aCambios) do
    begin
      tvHistorico.DataController.Values[i, colInstante.Index] :=
        aCambios[i].Instante;
      tvHistorico.DataController.Values[i, colTipo.Index] :=
        TextoTipo(aCambios[i].Tipo);
      tvHistorico.DataController.Values[i, colOrigen.Index] :=
        aCambios[i].Origen;
      tvHistorico.DataController.Values[i, colDestino.Index] :=
        aCambios[i].Destino;
      tvHistorico.DataController.Values[i, colUnidades.Index] :=
        aCambios[i].Unidades;
      tvHistorico.DataController.Values[i, colUsuario.Index] :=
        aCambios[i].Usuario;
      tvHistorico.DataController.Values[i, colEstado.Index] :=
        TextoEstado(aCambios[i].Estado);
    end;
    ActualizarResumen(Length(aCambios));
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmModalHistoricoArtColor.ActualizarResumen(
  ACantidad: Integer);
begin
  if ACantidad = 0 then
    lblResultado.Caption := SCaptionHistoricoCambioArticuloColorVacio
  else if ACantidad = 1 then
    lblResultado.Caption := SCaptionUltimoCambioArticuloColor
  else
  begin
    lblResultado.Caption := Format(
      SCaptionUltimosCambiosArticuloColor,
      [ACantidad]);
  end;
end;

function TfrmModalHistoricoArtColor.TextoEstado(
  AEstado: TEstadoHistoricoCambioArticuloColor): string;
begin
  case AEstado of
    ehcacAplicado:
      Result := SCaptionEstadoHistoricoAplicado;
    ehcacRevertido:
      Result := SCaptionEstadoHistoricoRevertido;
    else
      Result := SCaptionHistoricoCambioArticuloColorDesconocido;
  end;
end;

function TfrmModalHistoricoArtColor.TextoTipo(
  ATipo: TTipoHistoricoCambioArticuloColor): string;
begin
  case ATipo of
    thcacCambioArticulo:
      Result := SCaptionHistoricoCambioArticulo;
    thcacFusionArticulo:
      Result := SCaptionHistoricoFusionArticulo;
    thcacCambioColor:
      Result := SCaptionHistoricoCambioColor;
    thcacFusionColor:
      Result := SCaptionHistoricoFusionColor;
    thcacReversion:
      Result := SCaptionHistoricoReversion;
    else
      Result := SCaptionHistoricoCambioArticuloColorDesconocido;
  end;
end;

procedure TfrmModalHistoricoArtColor.btnCerrarClick(
  Sender: TObject);
begin
  Close;
end;

end.
