{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalHistoricoLote                                       }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Movimientos de un lote o serie (F-LOTEC-011): fecha, documento,           }
{    almacén, tipo, cantidad y cliente o proveedor. Solo consulta.             }
{******************************************************************************}
unit inMtoModalHistoricoLote;

interface

uses
  System.Classes, System.SysUtils, Vcl.Controls, Vcl.Forms,
  cxGraphics, cxStyles, cxCustomData, cxDataStorage, cxEdit, cxLabel,
  cxGrid, cxGridLevel, cxGridTableView,
  inMtoModalAceptCancel, inLibLotesPersistenciaIntf;

type
  TfrmModalHistoricoLote = class(TfrmModalAceptCancel)
    lblAviso: TcxLabel;
    grdMovimientos: TcxGrid;
    tvMovimientos: TcxGridTableView;
  private
    FLote: string;
    FReimprimir: TProc<string>;
    FMovimientos: TArray<TMovimientoLote>;
    procedure ReimprimirClick(Sender: TObject);
    procedure CrearBotonRetirada;
    function CrearColumna(const ACaption: string;
      AValueTypeClass: TcxValueTypeClass; AAncho: Integer): TcxGridColumn;
    procedure ConstruirRejilla(const AMovimientos: TArray<TMovimientoLote>);
    procedure CerrarSinLiberar(Sender: TObject; var Action: TCloseAction);
  protected
    procedure DoCreate; override;
  public
    constructor CreateHistorico(AOwner: TComponent;
      const AMovimientos: TArray<TMovimientoLote>; const ALote: string);
    class procedure Ejecutar(AOwner: TComponent;
      const ARepositorio: IRepositorioLotes;
      const ACodigoSku, ALote: string;
      const AReimprimir: TProc<string> = nil);
  end;

implementation

uses
  cxButtons, cxCurrencyEdit, inLibMsgRetiradaLotes, inLibTrazabilidad, inLibMsgTrazabilidad;

const
  // Medidas a 96 ppp; se aplican con ScaleValue.
  ANCHO_MODAL = 900;
  ALTO_MODAL = 460;
  ALTO_AVISO = 26;
  MARGEN = 8;
  ANCHO_FECHA = 90;
  ANCHO_DOCUMENTO = 170;
  ANCHO_SKU = 140;
  ANCHO_ALMACEN = 90;
  ANCHO_TIPO = 50;
  ANCHO_CANTIDAD = 80;
  ANCHO_TERCERO = 220;
  FORMATO_CANTIDAD = '#,##0.###';

function TextoDocumento(const AMovimiento: TMovimientoLote): string;
begin
  Result := Trim(AMovimiento.TipoDocumento + ' ' +
    AMovimiento.SerieDocumento + '/' + AMovimiento.NumeroDocumento);
  if AMovimiento.Linea > 0 then
    Result := Result + ' · ' + IntToStr(AMovimiento.Linea);
end;

function TextoAlmacen(const AMovimiento: TMovimientoLote): string;
begin
  Result := AMovimiento.CodigoAlmacen;
  if AMovimiento.CodigoAlmacenContra <> '' then
    Result := Result + ' → ' + AMovimiento.CodigoAlmacenContra;
end;

function TextoTercero(const AMovimiento: TMovimientoLote): string;
begin
  if AMovimiento.CodigoCliente <> '' then
    Result := Trim(AMovimiento.CodigoCliente + ' ' +
                   AMovimiento.RazonSocialCliente)
  else
    Result := Trim(AMovimiento.CodigoProveedor + ' ' +
                   AMovimiento.NombreProveedor);
end;

constructor TfrmModalHistoricoLote.CreateHistorico(AOwner: TComponent;
  const AMovimientos: TArray<TMovimientoLote>; const ALote: string);
begin
  inherited Create(AOwner);
  FLote := ALote;
  FMovimientos := AMovimientos;
  OnClose := CerrarSinLiberar;
  Position := poOwnerFormCenter;
  ClientWidth := ScaleValue(ANCHO_MODAL);
  ClientHeight := ScaleValue(ALTO_MODAL);
  // Solo consulta: un único botón para cerrar.
  btnAceptar.Visible := False;
  btnCancelar.Caption := SCaptionBotonCerrarHistorico;
  lblAviso := TcxLabel.Create(Self);
  lblAviso.Parent := pnlBody;
  lblAviso.AlignWithMargins := True;
  lblAviso.Margins.SetBounds(ScaleValue(MARGEN), 0, ScaleValue(MARGEN), 0);
  lblAviso.Align := alBottom;
  lblAviso.Height := ScaleValue(ALTO_AVISO);
  lblAviso.Transparent := True;
  lblAviso.Visible := Length(AMovimientos) = 0;
  lblAviso.Caption := SAvisoHistoricoVacio;
  ConstruirRejilla(AMovimientos);
end;

procedure TfrmModalHistoricoLote.DoCreate;
begin
  inherited;
  // TfrmBase traduce el Caption por la jerarquía de clases: sin clave
  // propia quedaría el título de TfrmBase.
  Caption := Format(STituloHistoricoLote, [FLote]);
end;

function TfrmModalHistoricoLote.CrearColumna(const ACaption: string;
  AValueTypeClass: TcxValueTypeClass; AAncho: Integer): TcxGridColumn;
begin
  Result := tvMovimientos.CreateColumn;
  Result.Caption := ACaption;
  Result.DataBinding.ValueTypeClass := AValueTypeClass;
  Result.Width := ScaleValue(AAncho);
  Result.Options.Editing := False;
end;

procedure TfrmModalHistoricoLote.ConstruirRejilla(
  const AMovimientos: TArray<TMovimientoLote>);
var
  iFila: Integer;
  oCantidad: TcxGridColumn;
  oDatos: TcxCustomDataController;
begin
  grdMovimientos := TcxGrid.Create(Self);
  grdMovimientos.Parent := pnlBody;
  grdMovimientos.AlignWithMargins := True;
  grdMovimientos.Margins.SetBounds(ScaleValue(MARGEN), ScaleValue(MARGEN),
    ScaleValue(MARGEN), ScaleValue(MARGEN));
  grdMovimientos.Align := alClient;
  tvMovimientos := grdMovimientos.CreateView(TcxGridTableView) as
    TcxGridTableView;
  grdMovimientos.Levels.Add.GridView := tvMovimientos;
  tvMovimientos.OptionsView.GroupByBox := False;
  tvMovimientos.OptionsData.Editing := False;
  tvMovimientos.OptionsData.Inserting := False;
  tvMovimientos.OptionsData.Deleting := False;
  CrearColumna(SCaptionColumnaFechaMov, TcxStringValueType, ANCHO_FECHA);
  CrearColumna(SCaptionColumnaDocumentoMov, TcxStringValueType,
    ANCHO_DOCUMENTO);
  CrearColumna(SCaptionColumnaSku, TcxStringValueType, ANCHO_SKU);
  CrearColumna(SCaptionColumnaAlmacen, TcxStringValueType, ANCHO_ALMACEN);
  CrearColumna(SCaptionColumnaTipoMov, TcxStringValueType, ANCHO_TIPO);
  oCantidad := CrearColumna(SCaptionColumnaCantidadMov, TcxFloatValueType,
    ANCHO_CANTIDAD);
  oCantidad.PropertiesClass := TcxCurrencyEditProperties;
  TcxCurrencyEditProperties(oCantidad.Properties).DisplayFormat :=
    FORMATO_CANTIDAD;
  CrearColumna(SCaptionColumnaCaducidad, TcxStringValueType, ANCHO_FECHA);
  CrearColumna(SCaptionColumnaTerceroMov, TcxStringValueType, ANCHO_TERCERO);
  oDatos := tvMovimientos.DataController;
  oDatos.BeginUpdate;
  try
    oDatos.RecordCount := Length(AMovimientos);
    for iFila := 0 to High(AMovimientos) do
    begin
      oDatos.Values[iFila, 0] := DateToStr(AMovimientos[iFila].Fecha);
      oDatos.Values[iFila, 1] := TextoDocumento(AMovimientos[iFila]);
      oDatos.Values[iFila, 2] := AMovimientos[iFila].CodigoSku;
      oDatos.Values[iFila, 3] := TextoAlmacen(AMovimientos[iFila]);
      oDatos.Values[iFila, 4] := AMovimientos[iFila].TipoMovimiento;
      oDatos.Values[iFila, 5] := AMovimientos[iFila].Cantidad;
      if AMovimientos[iFila].FechaCaducidad = SIN_FECHA then
        oDatos.Values[iFila, 6] := ''
      else
        oDatos.Values[iFila, 6] :=
          DateToStr(AMovimientos[iFila].FechaCaducidad);
      oDatos.Values[iFila, 7] := TextoTercero(AMovimientos[iFila]);
    end;
  finally
    oDatos.EndUpdate;
  end;
end;

// La base libera el modal al cerrarse (caFree); Ejecutar lo libera.
procedure TfrmModalHistoricoLote.CerrarSinLiberar(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caHide;
end;

procedure TfrmModalHistoricoLote.CrearBotonRetirada;
var
  Boton: TcxButton;
begin
  Boton := TcxButton.Create(Self);
  Boton.Parent := pnlButton;
  Boton.Align := alLeft;
  Boton.Width := ScaleValue(180);
  Boton.Caption := SBotonReimprimirRetirada;
  Boton.OnClick := ReimprimirClick;
end;

procedure TfrmModalHistoricoLote.ReimprimirClick(Sender: TObject);
var
  Indice: Integer;
begin
  Indice := tvMovimientos.DataController.FocusedRecordIndex;
  if Assigned(FReimprimir) and (Indice >= 0) and
     (Indice <= High(FMovimientos)) then
    FReimprimir(FMovimientos[Indice].NumeroMovimiento);
end;

class procedure TfrmModalHistoricoLote.Ejecutar(AOwner: TComponent;
  const ARepositorio: IRepositorioLotes; const ACodigoSku, ALote: string;
  const AReimprimir: TProc<string>);
var
  oFormulario: TfrmModalHistoricoLote;
begin
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('ARepositorio');
  oFormulario := TfrmModalHistoricoLote.CreateHistorico(AOwner,
    ARepositorio.Historico(ACodigoSku, ALote), ALote);
  try
    oFormulario.FReimprimir := AReimprimir;
    if Assigned(AReimprimir) then
      oFormulario.CrearBotonRetirada;
    oFormulario.ShowModal;
  finally
    FreeAndNil(oFormulario);
  end;
end;

end.
