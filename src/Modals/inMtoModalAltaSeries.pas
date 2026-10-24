{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalAltaSeries                                          }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Captura de los números de serie de una entrada de compra                  }
{    (F-LOTEC-010): se leen con la pistola o se pegan, una por línea. Al       }
{    aceptar se rechazan las repetidas, las que no caben o no se pueden        }
{    imprimir en Code128, las de otras líneas del documento y las que ya       }
{    existen en otro artículo o están en stock. Nada se graba aquí.            }
{******************************************************************************}
unit inMtoModalAltaSeries;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms,
  cxGraphics, cxEdit, cxLabel, cxTextEdit, cxMemo, cxCheckBox,
  inMtoModalAceptCancel, inLibLotesPersistenciaIntf, inLibLotesVisualIntf;

type
  TfrmModalAltaSeries = class(TfrmModalAceptCancel)
    lblCabecera: TcxLabel;
    lblIndicacion: TcxLabel;
    memSeries: TcxMemo;
    lblContador: TcxLabel;
    chkImprimirEtiquetas: TcxCheckBox;
    lblAviso: TcxLabel;
  private
    FParametros: TParametrosAltaSeries;
    FRepositorio: IRepositorioLotes;
    FResultado: TResultadoAltaSeries;
    function AnadirEtiqueta(AAltura: Integer): TcxLabel;
    procedure ConstruirCabecera;
    procedure ConstruirPie;
    procedure ConstruirMemo;
    procedure ActualizarContador(Sender: TObject);
    function ErroresLista(const ASeries: TArray<string>): string;
    function ErroresCatalogo(const ASeries: TArray<string>): string;
    function Validar(out ASeries: TArray<string>): Boolean;
    procedure CerrarSinLiberar(Sender: TObject; var Action: TCloseAction);
  protected
    procedure DoCreate; override;
    procedure DoShow; override;
  public
    constructor CreateAltaSeries(
      AOwner: TComponent;
      const ARepositorio: IRepositorioLotes;
      const AParametros: TParametrosAltaSeries);
    function CloseQuery: Boolean; override;
    property Resultado: TResultadoAltaSeries read FResultado;
    class function Ejecutar(
      AOwner: TComponent;
      const ARepositorio: IRepositorioLotes;
      const AParametros: TParametrosAltaSeries): TResultadoAltaSeries;
  end;

implementation

uses
  System.SysUtils, System.StrUtils, System.UITypes, Vcl.Graphics,
  Vcl.StdCtrls,
  inLibMsgTrazabilidad, inLibSeriesCodigosBarras, inLibTrazabilidad;

const
  // Medidas a 96 ppp; se aplican con ScaleValue.
  ANCHO_MODAL = 560;
  ALTO_MODAL = 520;
  ALTO_CABECERA = 30;
  ALTO_LINEA = 24;
  ALTO_AVISO = 90;
  MARGEN = 8;
  COLOR_ERROR = TColor($000000C8);
  SEPARADOR_LISTA = ', ';

function ContieneTexto(
  const ALista: TArray<string>;
  const ATexto: string): Boolean;
var
  sElemento: string;
begin
  // Sin distinguir mayúsculas, como compara MariaDB.
  Result := False;
  for sElemento in ALista do
  begin
    if SameText(Trim(sElemento), ATexto) then
      Result := True;
  end;
end;

procedure AnadirLinea(var ATexto: string; const ALinea: string);
begin
  if ALinea <> '' then
  begin
    if ATexto <> '' then
      ATexto := ATexto + sLineBreak;
    ATexto := ATexto + ALinea;
  end;
end;

{ TfrmModalAltaSeries }

constructor TfrmModalAltaSeries.CreateAltaSeries(
  AOwner: TComponent;
  const ARepositorio: IRepositorioLotes;
  const AParametros: TParametrosAltaSeries);
begin
  inherited Create(AOwner);
  FRepositorio := ARepositorio;
  FParametros := AParametros;
  OnClose := CerrarSinLiberar;
  Position := poOwnerFormCenter;
  ClientWidth := ScaleValue(ANCHO_MODAL);
  ClientHeight := ScaleValue(ALTO_MODAL);
  ConstruirCabecera;
  ConstruirPie;
  ConstruirMemo;
  ActualizarContador(nil);
end;

procedure TfrmModalAltaSeries.DoCreate;
begin
  inherited;
  // TfrmBase traduce el Caption por la jerarquía de clases: sin clave
  // propia quedaría el título de TfrmBase.
  Caption := STituloAltaSeries;
end;

procedure TfrmModalAltaSeries.DoShow;
begin
  inherited;
  if memSeries.CanFocus then
  begin
    memSeries.SetFocus;
    memSeries.SelStart := Length(memSeries.Text);
  end;
end;

function TfrmModalAltaSeries.AnadirEtiqueta(AAltura: Integer): TcxLabel;
begin
  Result := TcxLabel.Create(Self);
  Result.Parent := pnlBody;
  Result.AutoSize := False;
  Result.Height := ScaleValue(AAltura);
  Result.AlignWithMargins := True;
  Result.Margins.SetBounds(ScaleValue(MARGEN), 0, ScaleValue(MARGEN), 0);
  Result.Transparent := True;
  Result.Properties.WordWrap := True;
end;

procedure TfrmModalAltaSeries.ConstruirCabecera;
begin
  lblCabecera := AnadirEtiqueta(ALTO_CABECERA);
  lblCabecera.Align := alTop;
  lblCabecera.Style.TextStyle := [fsBold];
  lblCabecera.Caption := Format(SCabeceraAltaSeries,
    [FParametros.CodigoSku, FParametros.DescripcionArticulo]);
  lblIndicacion := AnadirEtiqueta(ALTO_LINEA);
  lblIndicacion.Top := lblCabecera.Top + lblCabecera.Height;
  lblIndicacion.Align := alTop;
  lblIndicacion.Caption := SIndicacionAltaSeries;
end;

procedure TfrmModalAltaSeries.ConstruirPie;
begin
  lblAviso := AnadirEtiqueta(ALTO_AVISO);
  lblAviso.Align := alBottom;
  lblAviso.Style.TextColor := COLOR_ERROR;
  chkImprimirEtiquetas := TcxCheckBox.Create(Self);
  chkImprimirEtiquetas.Parent := pnlBody;
  chkImprimirEtiquetas.AlignWithMargins := True;
  chkImprimirEtiquetas.Margins.SetBounds(ScaleValue(MARGEN), 0,
    ScaleValue(MARGEN), 0);
  chkImprimirEtiquetas.Top := lblAviso.Top - ScaleValue(ALTO_LINEA);
  chkImprimirEtiquetas.Align := alBottom;
  chkImprimirEtiquetas.Transparent := True;
  chkImprimirEtiquetas.Caption := SCaptionImprimirEtiquetasSeries;
  // Oculta: las etiquetas por unidad se imprimen desde «Etiquetas» del
  // documento (FZ-ISSUE-300); el resultado sigue llevando la casilla.
  chkImprimirEtiquetas.Visible := False;
  lblContador := AnadirEtiqueta(ALTO_LINEA);
  lblContador.Top := chkImprimirEtiquetas.Top - ScaleValue(ALTO_LINEA);
  lblContador.Align := alBottom;
  lblContador.Style.TextStyle := [fsBold];
end;

procedure TfrmModalAltaSeries.ConstruirMemo;
begin
  memSeries := TcxMemo.Create(Self);
  memSeries.Parent := pnlBody;
  memSeries.AlignWithMargins := True;
  memSeries.Margins.SetBounds(ScaleValue(MARGEN), 0, ScaleValue(MARGEN),
    ScaleValue(MARGEN));
  memSeries.Align := alClient;
  memSeries.Properties.ScrollBars := ssVertical;
  memSeries.Properties.WantReturns := True;
  memSeries.Lines.Text := string.Join(sLineBreak,
                                      FParametros.SeriesIniciales);
  memSeries.Properties.OnChange := ActualizarContador;
end;

procedure TfrmModalAltaSeries.ActualizarContador(Sender: TObject);
var
  iLeidas: Integer;
begin
  iLeidas := Length(PrepararSeries(memSeries.Text).Series);
  if FParametros.Cantidad > 0 then
    lblContador.Caption := Format(SContadorAltaSeries,
                                  [iLeidas, FParametros.Cantidad])
  else
    lblContador.Caption := Format(SContadorAltaSeriesLibre, [iLeidas]);
end;

function TfrmModalAltaSeries.ErroresLista(
  const ASeries: TArray<string>): string;
var
  sSerie: string;
  sUsadas: string;
begin
  Result := '';
  sUsadas := '';
  if Length(ASeries) = 0 then
    AnadirLinea(Result, SErrorAltaSeriesVacia)
  else if (FParametros.Cantidad > 0) and
          (Length(ASeries) <> FParametros.Cantidad) then
    AnadirLinea(Result, Format(SErrorAltaSeriesCantidad,
                               [Length(ASeries), FParametros.Cantidad]));
  for sSerie in ASeries do
  begin
    if ContieneTexto(FParametros.SeriesDocumento, sSerie) then
      sUsadas := sUsadas + IfThen(sUsadas <> '', SEPARADOR_LISTA) + sSerie;
  end;
  if sUsadas <> '' then
    AnadirLinea(Result, Format(SErrorAltaSeriesEnDocumento, [sUsadas]));
end;

function TfrmModalAltaSeries.ErroresCatalogo(
  const ASeries: TArray<string>): string;
var
  rUbicacion: TUbicacionSerie;
  sSerie: string;
begin
  // Las series que ya traía la línea están grabadas con este documento:
  // seguirán en stock y no son un choque.
  Result := '';
  for sSerie in ASeries do
  begin
    if Assigned(FRepositorio) and
       not ContieneTexto(FParametros.SeriesIniciales, sSerie) and
       FRepositorio.BuscarSerie(sSerie, rUbicacion) then
    begin
      if not SameText(rUbicacion.Catalogo.CodigoSku,
                      FParametros.CodigoSku) then
        AnadirLinea(Result, Format(SErrorAltaSeriesOtroArticulo,
                                   [sSerie, rUbicacion.Catalogo.CodigoSku]))
      else if rUbicacion.CodigoAlmacen <> '' then
        AnadirLinea(Result, Format(SErrorAltaSeriesEnStock,
                                   [sSerie, rUbicacion.CodigoAlmacen]));
    end;
  end;
end;

function TfrmModalAltaSeries.Validar(out ASeries: TArray<string>): Boolean;
var
  rSeries: TSeriesPreparadas;
  sErrores: string;
begin
  rSeries := PrepararSeries(memSeries.Text);
  ASeries := rSeries.Series;
  sErrores := '';
  if Length(rSeries.Invalidas) > 0 then
    AnadirLinea(sErrores, Format(SErrorAltaSeriesInvalidas,
      [LONGITUD_MAXIMA_LOTE, string.Join(SEPARADOR_LISTA,
                                         rSeries.Invalidas)]));
  if Length(rSeries.Duplicadas) > 0 then
    AnadirLinea(sErrores, Format(SErrorAltaSeriesDuplicadas,
      [string.Join(SEPARADOR_LISTA, rSeries.Duplicadas)]));
  AnadirLinea(sErrores, ErroresLista(ASeries));
  // El catálogo solo se consulta con una lista limpia.
  if sErrores = '' then
    sErrores := ErroresCatalogo(ASeries);
  lblAviso.Caption := sErrores;
  Result := sErrores = '';
end;

function TfrmModalAltaSeries.CloseQuery: Boolean;
var
  aSeries: TArray<string>;
begin
  // sFicha lo asigna el ancestro: 'S' tras Aceptar o F12, 'N' al cancelar.
  Result := inherited CloseQuery;
  if Result and (sFicha = 'S') then
  begin
    Result := Validar(aSeries);
    if Result then
    begin
      FResultado.Aceptado := True;
      FResultado.Series := aSeries;
      FResultado.ImprimirEtiquetas := chkImprimirEtiquetas.Checked;
    end
    else
      sFicha := 'N';
  end;
end;

// La base libera el modal al cerrarse (caFree); Ejecutar lo libera.
procedure TfrmModalAltaSeries.CerrarSinLiberar(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caHide;
end;

class function TfrmModalAltaSeries.Ejecutar(
  AOwner: TComponent;
  const ARepositorio: IRepositorioLotes;
  const AParametros: TParametrosAltaSeries): TResultadoAltaSeries;
var
  oFormulario: TfrmModalAltaSeries;
begin
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('ARepositorio');
  oFormulario := TfrmModalAltaSeries.CreateAltaSeries(
    AOwner, ARepositorio, AParametros);
  try
    oFormulario.ShowModal;
    Result := oFormulario.Resultado;
  finally
    FreeAndNil(oFormulario);
  end;
end;

end.
