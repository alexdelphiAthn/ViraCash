{******************************************************************************}
{                                                                              }
{  Módulo:       inLibReparacionesDiseno                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Diseño común de documentos de reparación: A4, ticket y etiquetas.         }
{******************************************************************************}
unit inLibReparacionesDiseno;

interface

uses
  frxClass;

type
  TDisenoReparacion = class
  private
    FPagina: TfrxReportPage;
    FAncho: Extended;
    FOrden: Extended;
    FAlto: Extended;
    FEstrecho: Boolean;
    FClave: string;
    FTexto: Integer;
    FTrabajo: Integer;
    function Banda(const AClave: string): TfrxMasterData;
    function Texto(AParent: TfrxComponent; const ATexto: string;
      AX, AY, AAncho: Extended; ATamano: Integer;
      ANegrita: Boolean = False): TfrxMemoView;
    procedure CerrarBanda(ABanda: TfrxBand; AAlto: Extended);
  public
    constructor Create(AInforme: TfrxReport; AAncho, AAlto: Extended;
      AContinuo: Boolean);
    procedure Cabecera(const ATitulo, AReferencia, AFecha: string);
    procedure Sujetos(const AEmisor, ATercero: string);
    procedure Seccion(const ATitulo, ATexto: string;
      ATamano: Integer = 10);
    procedure Trabajo(const ADescripcion, ACantidad, AImporte: string);
    procedure CabeceraTrabajos;
    procedure Total(const ARotulo, AValor: string);
    procedure Firmas(const ATexto: string);
    procedure Pie(const AReferencia: string);
    procedure ValidarEtiqueta;
  end;

implementation

uses
  System.SysUtils, System.Math, Vcl.Graphics, frBaseGraphicsTypes,
  inLibMsgReparaciones;

const
  MM = 3.77953;
  COLOR_FONDO = $00EAEAEA;
  COLOR_LINEA = $00C8C8C8;

constructor TDisenoReparacion.Create(AInforme: TfrxReport;
  AAncho, AAlto: Extended; AContinuo: Boolean);
begin
  inherited Create;
  AInforme.Clear;
  AInforme.PreviewOptions.Modal := True;
  FEstrecho := AAncho < 150;
  FPagina := TfrxReportPage.Create(AInforme);
  FPagina.CreateUniqueName;
  FPagina.SetDefaults;
  FPagina.PaperWidth := AAncho;
  FPagina.PaperHeight := AAlto;
  FPagina.LeftMargin := 14;
  if FEstrecho then
    FPagina.LeftMargin := 4;
  FPagina.RightMargin := FPagina.LeftMargin;
  FPagina.TopMargin := FPagina.LeftMargin;
  FPagina.BottomMargin := FPagina.LeftMargin;
  FPagina.EndlessHeight := AContinuo;
  FAncho := (AAncho - FPagina.LeftMargin * 2) * MM;
end;

function TDisenoReparacion.Banda(const AClave: string): TfrxMasterData;
begin
  FClave := 'Rep_' + AClave;
  FTexto := 0;
  Result := TfrxMasterData.Create(FPagina);
  Result.Name := FClave;
  Result.Top := FOrden;
  FOrden := FOrden + 1000;
  Result.RowCount := 1;
  Result.Stretched := False;
  Result.AllowSplit := True;
end;

function TDisenoReparacion.Texto(AParent: TfrxComponent;
  const ATexto: string; AX, AY, AAncho: Extended; ATamano: Integer;
  ANegrita: Boolean): TfrxMemoView;
begin
  Result := TfrxMemoView.Create(AParent);
  Result.Name := FClave + '_Texto' + IntToStr(FTexto);
  Inc(FTexto);
  Result.SetBounds(AX, AY, AAncho, 20);
  Result.Font.Name := 'Arial';
  Result.Font.Size := ATamano;
  if ANegrita then
    Result.Font.Style := [fsBold];
  Result.WordWrap := True;
  Result.AllowExpressions := False;
  Result.StretchMode := smActualHeight;
  Result.GapX := 6;
  Result.GapY := 4;
  Result.Text := ATexto;
  Result.Height := Max(20, Result.CalcHeight + 2);
end;

procedure TDisenoReparacion.CerrarBanda(ABanda: TfrxBand;
  AAlto: Extended);
var
  oEspacio: TfrxMemoView;
begin
  oEspacio := TfrxMemoView.Create(ABanda);
  oEspacio.Name := ABanda.Name + '_Espacio';
  oEspacio.SetBounds(0, AAlto - 8, FAncho, 8);
  oEspacio.AllowExpressions := False;
  oEspacio.ShiftMode := smAlways;
  ABanda.Height := AAlto;
  if ABanda.Visible then
    FAlto := FAlto + AAlto;
end;

procedure TDisenoReparacion.Cabecera(const ATitulo, AReferencia,
  AFecha: string);
var
  oBanda: TfrxMasterData;
  oTexto: TfrxMemoView;
  dY: Extended;
begin
  oBanda := Banda('Cabecera');
  oBanda.AllowSplit := False;
  oTexto := Texto(oBanda, AnsiUpperCase(ATitulo), 0, 0, FAncho, 16, True);
  if FEstrecho then
    oTexto.Font.Size := 12;
  oTexto.Height := oTexto.CalcHeight + 4;
  oTexto.HAlign := haCenter;
  dY := oTexto.Height + 8;
  oTexto := Texto(oBanda, AReferencia, 0, dY, FAncho, 14, True);
  oTexto.Color := COLOR_FONDO;
  oTexto.HAlign := haCenter;
  dY := dY + oTexto.Height + 2;
  oTexto := Texto(oBanda, AFecha, 0, dY, FAncho, 9);
  oTexto.HAlign := haCenter;
  CerrarBanda(oBanda, dY + oTexto.Height + 12);
end;

procedure TDisenoReparacion.Sujetos(const AEmisor, ATercero: string);
var
  oBanda: TfrxMasterData;
  oEmisor, oTercero: TfrxMemoView;
  dMitad, dAlto: Extended;
begin
  if FEstrecho then
  begin
    Seccion(SImpresoEmisor, AEmisor, 9);
    Seccion(SImpresoCliente, ATercero);
  end
  else
  begin
    oBanda := Banda('Sujetos');
    dMitad := (FAncho - 16) / 2;
    Texto(oBanda, SImpresoEmisor, 0, 0, dMitad, 9, True);
    Texto(oBanda, SImpresoCliente, dMitad + 16, 0, dMitad, 9, True);
    oEmisor := Texto(oBanda, AEmisor, 0, 26, dMitad, 10);
    oTercero := Texto(oBanda, ATercero, dMitad + 16, 26, dMitad, 10);
    dAlto := Max(oEmisor.Height, oTercero.Height) + 8;
    oEmisor.Height := dAlto;
    oTercero.Height := dAlto;
    oEmisor.Frame.Typ := [ftLeft, ftRight, ftTop, ftBottom];
    oEmisor.Frame.Color := COLOR_LINEA;
    oTercero.Frame.Assign(oEmisor.Frame);
    CerrarBanda(oBanda, 26 + dAlto + 14);
  end;
end;

function ClaveSeccion(const ATitulo: string): string;
var
  aTitulos: TArray<string>;
  i: Integer;
begin
  aTitulos := [SImpresoEmisor, SImpresoCliente, SImpresoAparato,
    SImpresoMotivo, SImpresoEstadoRecepcion, SImpresoCondiciones,
    SImpresoAlbaran, SImpresoTrabajos, SImpresoResultado,
    SImpresoDestinatario, SImpresoRemitente, SImpresoTransporte];
  Result := '';
  for i := 0 to High(aTitulos) do
    if aTitulos[i] = ATitulo then
      Result := 'Seccion' + IntToStr(i);
  if Result = '' then
    raise EArgumentException.Create('Sección de impreso desconocida.');
end;

procedure TDisenoReparacion.Seccion(const ATitulo, ATexto: string;
  ATamano: Integer);
var
  oBanda: TfrxMasterData;
  oRotulo, oTexto: TfrxMemoView;
begin
  oBanda := Banda(ClaveSeccion(ATitulo));
  oBanda.Visible := Trim(ATexto) <> '';
  oRotulo := Texto(oBanda, AnsiUpperCase(ATitulo),
    0, 0, FAncho, 9, True);
  oRotulo.Color := COLOR_FONDO;
  if FEstrecho then
    oRotulo.Frame.Typ := [ftBottom];
  oTexto := Texto(oBanda, ATexto, 0, oRotulo.Height, FAncho, ATamano);
  CerrarBanda(oBanda, oRotulo.Height + oTexto.Height + 10);
end;

procedure TDisenoReparacion.CabeceraTrabajos;
var
  oBanda: TfrxMasterData;
  oTexto: TfrxMemoView;
begin
  if not FEstrecho then
  begin
    oBanda := Banda('TablaCabecera');
    oTexto := Texto(oBanda, SImpresoDescripcion, 0, 0,
      FAncho - 190, 9, True);
    oTexto.Color := COLOR_FONDO;
    oTexto := Texto(oBanda, SImpresoCantidadColumna,
      FAncho - 190, 0, 80, 9, True);
    oTexto.Color := COLOR_FONDO;
    oTexto.HAlign := haRight;
    oTexto := Texto(oBanda, SImpresoImporteColumna,
      FAncho - 110, 0, 110, 9, True);
    oTexto.Color := COLOR_FONDO;
    oTexto.HAlign := haRight;
    CerrarBanda(oBanda, oTexto.Height + 4);
  end;
end;

procedure TDisenoReparacion.Trabajo(const ADescripcion, ACantidad,
  AImporte: string);
var
  oBanda: TfrxMasterData;
  oTexto: TfrxMemoView;
  dAlto: Extended;
begin
  oBanda := Banda('Trabajo' + Format('%.4d', [FTrabajo]));
  Inc(FTrabajo);
  if FEstrecho then
  begin
    oTexto := Texto(oBanda, ADescripcion, 0, 0, FAncho, 10);
    dAlto := oTexto.Height;
    oTexto := Texto(oBanda, Format(SImpresoCantidad, [ACantidad]),
      0, dAlto, FAncho / 2, 9);
    dAlto := dAlto + oTexto.Height;
    oTexto := Texto(oBanda, AImporte, FAncho / 2,
      dAlto - oTexto.Height, FAncho / 2, 10, True);
  end
  else
  begin
    oTexto := Texto(oBanda, ADescripcion, 0, 0, FAncho - 190, 10);
    dAlto := oTexto.Height;
    oTexto := Texto(oBanda, ACantidad, FAncho - 190, 0, 80, 10);
    oTexto.HAlign := haRight;
    dAlto := Max(dAlto, oTexto.Height);
    oTexto := Texto(oBanda, AImporte, FAncho - 110, 0, 110, 10, True);
    dAlto := Max(dAlto, oTexto.Height);
  end;
  oTexto.HAlign := haRight;
  CerrarBanda(oBanda, dAlto + 6);
end;

procedure TDisenoReparacion.Total(const ARotulo, AValor: string);
var
  oBanda: TfrxMasterData;
  oTexto: TfrxMemoView;
begin
  oBanda := Banda('Total');
  oBanda.AllowSplit := False;
  oTexto := Texto(oBanda, ARotulo + sLineBreak + AValor,
    0, 6, FAncho, 12, True);
  oTexto.HAlign := haRight;
  oTexto.Color := COLOR_FONDO;
  if FEstrecho then
    oTexto.Frame.Typ := [ftTop, ftBottom];
  CerrarBanda(oBanda, oTexto.Height + 18);
end;

procedure TDisenoReparacion.Firmas(const ATexto: string);
var
  oBanda: TfrxMasterData;
  oTexto: TfrxMemoView;
begin
  oBanda := Banda('Firmas');
  oBanda.AllowSplit := False;
  oTexto := Texto(oBanda, ATexto, 0, 0, FAncho, 9);
  if FEstrecho then
    oTexto := Texto(oBanda, SImpresoFirmasTicket, 0,
      oTexto.Height + 48, FAncho, 9)
  else
    oTexto := Texto(oBanda, SImpresoFirmas, 0,
      oTexto.Height + 48, FAncho, 9);
  oTexto.Frame.Typ := [ftTop];
  oTexto.Frame.Color := COLOR_LINEA;
  CerrarBanda(oBanda, oTexto.Top + oTexto.Height + 10);
end;

procedure TDisenoReparacion.Pie(const AReferencia: string);
var
  oPie: TfrxPageFooter;
  oTexto: TfrxMemoView;
begin
  if not FEstrecho then
  begin
    FClave := 'Rep_Pie';
    FTexto := 0;
    oPie := TfrxPageFooter.Create(FPagina);
    oPie.CreateUniqueName;
    oPie.Height := 24;
    oTexto := Texto(oPie, AReferencia, 0, 0, FAncho - 90, 8);
    oTexto.Frame.Typ := [ftTop];
    oTexto := Texto(oPie, '[Page#]', FAncho - 90, 0, 90, 8);
    oTexto.AllowExpressions := True;
    oTexto.HAlign := haRight;
    oTexto.Frame.Typ := [ftTop];
  end;
end;

procedure TDisenoReparacion.ValidarEtiqueta;
begin
  if FAlto > (FPagina.PaperHeight - FPagina.TopMargin -
    FPagina.BottomMargin) * MM then
    raise EArgumentException.Create(SImpresoEtiquetaLarga);
end;

end.
