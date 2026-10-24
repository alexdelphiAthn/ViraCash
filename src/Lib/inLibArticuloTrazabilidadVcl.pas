{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArticuloTrazabilidadVcl                                  }
{    Tipo:       Librería (colaborador VCL)                                    }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Grupo «Trazabilidad» de la ficha de artículo (F-LOTEC-011): modo          }
{    (solo los activados por parámetro), caducidad obligatoria y días de       }
{    aviso. Sustituye a la casilla «Trazable», que deja de verse. Con todos    }
{    los interruptores apagados no crea nada: la ficha queda como antes.       }
{******************************************************************************}
unit inLibArticuloTrazabilidadVcl;

interface

uses
  System.Classes, Vcl.Controls, Data.DB,
  cxGroupBox, cxRadioGroup, cxCheckBox, cxLabel, cxSpinEdit, cxDBEdit,
  inLibTrazabilidad;

type
  TFichaTrazabilidadArticuloVcl = class(TComponent)
  private
    FActivacion: TActivacionTrazabilidad;
    FGrupo: TcxGroupBox;
    FModo: TcxDBRadioGroup;
    FCaducidad: TcxDBCheckBox;
    FEtiquetaDias: TcxLabel;
    FDias: TcxDBSpinEdit;
    FEtiquetaGarantia: TcxLabel;
    FGarantia: TcxDBSpinEdit;
    procedure Construir(AContenedor: TWinControl; AReferencia: TControl;
      ADatos: TDataSource);
    procedure ConstruirModo(ADatos: TDataSource);
    procedure ConstruirCaducidad(ADatos: TDataSource);
    procedure ConstruirGarantia(ADatos: TDataSource);
  public
    // AReferencia: el control que se sustituye (chkESTRAZABLE_ART); se
    // oculta siempre y el grupo ocupa su sitio.
    constructor CreateFicha(AOwner: TComponent; AContenedor: TWinControl;
      AReferencia: TControl; ADatos: TDataSource;
      const AActivacion: TActivacionTrazabilidad);
    // Lleva el foco al modo (validación al grabar). False si no se ve.
    function Enfocar: Boolean;
    property Grupo: TcxGroupBox read FGrupo;
    property Modo: TcxDBRadioGroup read FModo;
    property Caducidad: TcxDBCheckBox read FCaducidad;
    property Dias: TcxDBSpinEdit read FDias;
    property Garantia: TcxDBSpinEdit read FGarantia;
  end;

implementation

uses
  System.SysUtils, System.Math, cxContainer, cxEdit, cxGraphics,
  dxCoreGraphics, Vcl.Graphics,
  inLibMsgTrazabilidad,
  inLibMsgGarantias;

const
  // Medidas a 96 ppp.
  ANCHO_GRUPO = 570;
  ALTO_GRUPO = 104;
  MARGEN = 10;
  ALTO_MODO = 36;
  ALTO_FILA = 24;
  ANCHO_CADUCIDAD = 220;
  ANCHO_ETIQUETA_DIAS = 190;
  ANCHO_DIAS = 70;
  MAXIMO_DIAS_AVISO = 3650;
  ANCHO_ETIQUETA_GARANTIA = 190;
  MAXIMO_MESES_GARANTIA = 240;

constructor TFichaTrazabilidadArticuloVcl.CreateFicha(AOwner: TComponent;
  AContenedor: TWinControl; AReferencia: TControl; ADatos: TDataSource;
  const AActivacion: TActivacionTrazabilidad);
begin
  if not Assigned(AContenedor) then
    raise EArgumentNilException.Create('AContenedor');
  if not Assigned(AReferencia) then
    raise EArgumentNilException.Create('AReferencia');
  inherited Create(AOwner);
  FActivacion := AActivacion;
  AReferencia.Visible := False;
  if FActivacion.AlgunModoActivo then
    Construir(AContenedor, AReferencia, ADatos);
end;

procedure TFichaTrazabilidadArticuloVcl.Construir(AContenedor: TWinControl;
  AReferencia: TControl; ADatos: TDataSource);
begin
  FGrupo := TcxGroupBox.Create(Self);
  FGrupo.Parent := AContenedor;
  FGrupo.Caption := SCaptionGrupoTrazabilidad;
  // Tras asignar Parent las medidas van en píxeles físicos.
  FGrupo.SetBounds(AReferencia.Left, AReferencia.Top,
    AContenedor.ScaleValue(ANCHO_GRUPO), AContenedor.ScaleValue(ALTO_GRUPO));
  ConstruirModo(ADatos);
  ConstruirCaducidad(ADatos);
  if FActivacion.Garantias then
    ConstruirGarantia(ADatos);
end;

procedure TFichaTrazabilidadArticuloVcl.ConstruirModo(ADatos: TDataSource);
var
  oItem: TcxRadioGroupItem;
  oModo: TModoTrazabilidad;
  aModos: TModosTrazabilidad;
  iAlto: Integer;
begin
  FModo := TcxDBRadioGroup.Create(Self);
  FModo.Parent := FGrupo;
  FModo.Caption := '';
  // Sin cabecera: toda la altura pertenece a las opciones.
  FModo.Alignment := alCenterCenter;
  FModo.Style.BorderStyle := ebsNone;
  FModo.Transparent := True;
  aModos := FActivacion.ModosDisponibles;
  FModo.Properties.Columns := Length(aModos);
  for oModo in aModos do
  begin
    oItem := FModo.Properties.Items.Add;
    oItem.Caption := TextoModoTrazabilidad(oModo);
    oItem.Value := ModoACadena(oModo);
  end;
  FModo.DataBinding.DataSource := ADatos;
  FModo.DataBinding.DataField := 'TIPO_TRAZABILIDAD_ART';
  // Una fila sin cabecera, con margen para la fuente y el escalado DPI.
  iAlto := Max(FGrupo.ScaleValue(ALTO_MODO),
    cxTextHeight(FModo.Style.Font) + FGrupo.ScaleValue(12));
  FModo.SetBounds(FGrupo.ScaleValue(MARGEN), FGrupo.ScaleValue(ALTO_FILA),
    FGrupo.Width - FGrupo.ScaleValue(2 * MARGEN), iAlto);
  FGrupo.Height := FGrupo.Height + iAlto - FGrupo.ScaleValue(ALTO_MODO);
end;

procedure TFichaTrazabilidadArticuloVcl.ConstruirCaducidad(
  ADatos: TDataSource);
var
  iTop: Integer;
begin
  // Caducidad y días de aviso: solo con lotes activados.
  iTop := FModo.Top + FModo.Height + FGrupo.ScaleValue(4);
  FCaducidad := TcxDBCheckBox.Create(Self);
  FCaducidad.Parent := FGrupo;
  FCaducidad.Caption := SCaptionCaducidadObligatoria;
  FCaducidad.Transparent := True;
  FCaducidad.Properties.ValueChecked := 'S';
  FCaducidad.Properties.ValueUnchecked := 'N';
  FCaducidad.DataBinding.DataSource := ADatos;
  FCaducidad.DataBinding.DataField := 'ESCADUCIDAD_ART';
  FCaducidad.SetBounds(FGrupo.ScaleValue(MARGEN), iTop,
    FGrupo.ScaleValue(ANCHO_CADUCIDAD), FGrupo.ScaleValue(ALTO_FILA));
  FEtiquetaDias := TcxLabel.Create(Self);
  FEtiquetaDias.Parent := FGrupo;
  FEtiquetaDias.Caption := SCaptionDiasAvisoCaducidad;
  FEtiquetaDias.Transparent := True;
  FEtiquetaDias.SetBounds(FCaducidad.Left + FCaducidad.Width, iTop,
    FGrupo.ScaleValue(ANCHO_ETIQUETA_DIAS), FGrupo.ScaleValue(ALTO_FILA));
  FDias := TcxDBSpinEdit.Create(Self);
  FDias.Parent := FGrupo;
  FDias.Hint := SHintDiasAvisoCaducidad;
  FDias.ShowHint := True;
  FDias.Properties.MinValue := 0;
  FDias.Properties.MaxValue := MAXIMO_DIAS_AVISO;
  // NULL = el parámetro general: en blanco, no «0».
  FDias.Properties.UseNullString := True;
  FDias.DataBinding.DataSource := ADatos;
  FDias.DataBinding.DataField := 'DIAS_AVISO_CADUCIDAD_ART';
  FDias.SetBounds(FEtiquetaDias.Left + FEtiquetaDias.Width, iTop,
    FGrupo.ScaleValue(ANCHO_DIAS), FGrupo.ScaleValue(ALTO_FILA));
  FCaducidad.Visible := FActivacion.Lotes;
  FEtiquetaDias.Visible := FActivacion.Lotes;
  FDias.Visible := FActivacion.Lotes;
  FGrupo.Height := Max(FGrupo.Height, iTop +
    FGrupo.ScaleValue(ALTO_FILA + MARGEN));
end;

// F-LOTEC-021: meses de garantía (vacío = sin garantía). Ocupa la fila
// de la caducidad si los lotes están apagados; si no, una fila más.
procedure TFichaTrazabilidadArticuloVcl.ConstruirGarantia(
  ADatos: TDataSource);
var
  iTop: Integer;
begin
  iTop := FCaducidad.Top;
  if FActivacion.Lotes then
    iTop := FCaducidad.Top + FCaducidad.Height + FGrupo.ScaleValue(4);
  FEtiquetaGarantia := TcxLabel.Create(Self);
  FEtiquetaGarantia.Parent := FGrupo;
  FEtiquetaGarantia.Caption := SCaptionMesesGarantiaArticulo;
  FEtiquetaGarantia.Transparent := True;
  FEtiquetaGarantia.SetBounds(FGrupo.ScaleValue(MARGEN), iTop,
    FGrupo.ScaleValue(ANCHO_ETIQUETA_GARANTIA),
    FGrupo.ScaleValue(ALTO_FILA));
  FGarantia := TcxDBSpinEdit.Create(Self);
  FGarantia.Parent := FGrupo;
  FGarantia.Hint := SHintMesesGarantiaArticulo;
  FGarantia.ShowHint := True;
  FGarantia.Properties.MinValue := 0;
  FGarantia.Properties.MaxValue := MAXIMO_MESES_GARANTIA;
  // NULL = sin garantía: en blanco, no «0».
  FGarantia.Properties.UseNullString := True;
  FGarantia.DataBinding.DataSource := ADatos;
  FGarantia.DataBinding.DataField := 'MESES_GARANTIA_ART';
  FGarantia.SetBounds(FEtiquetaGarantia.Left + FEtiquetaGarantia.Width,
    iTop, FGrupo.ScaleValue(ANCHO_DIAS), FGrupo.ScaleValue(ALTO_FILA));
  FGrupo.Height := Max(FGrupo.Height, FGarantia.Top + FGarantia.Height +
    FGrupo.ScaleValue(MARGEN));
end;

function TFichaTrazabilidadArticuloVcl.Enfocar: Boolean;
begin
  Result := Assigned(FModo) and FModo.CanFocus;
  if Result then
    FModo.SetFocus;
end;

end.
