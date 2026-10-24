{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalPrioridadesDistribucion                             }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       21/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Número de prioridad de cada almacén en la distribución entre tiendas:     }
{    el 1 se repone primero y dos tiendas pueden compartir número. Sin         }
{    número, el almacén no recibe traspasos desde la distribución (es lo que   }
{    lleva el almacén central). Solo edita: quien lo abre guarda.              }
{******************************************************************************}
unit inMtoModalPrioridadesDistribucion;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus, System.Actions, Vcl.ActnList,
  cxGraphics, cxLookAndFeels, cxLookAndFeelPainters, cxControls,
  cxContainer, cxEdit, cxTextEdit, cxLabel, cxButtons, cxClasses,
  cxLocalization, cxStyles, cxCustomData, cxFilter, cxData, cxDataStorage,
  cxNavigator, cxCurrencyEdit, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGrid, dxSkinsCore,
  dxDateRanges, dxScrollbarAnnotations,
  JvComponentBase, JvEnterTab,
  inMtoModalAceptCancel,
  inLibDistribucionTiendasIntf;

type
  TResultadoPrioridadesDistribucion = record
    Aceptado: Boolean;
    Prioridades: TPrioridadesAlmacenDistribucion;
  end;

  TfrmModalPrioridadesDistribucion = class(TfrmModalAceptCancel)
    lblAyuda: TcxLabel;
    cxgrdPrioridades: TcxGrid;
    tvPrioridades: TcxGridTableView;
    glPrioridades: TcxGridLevel;
    procedure cxgrdPrioridadesEnter(Sender: TObject);
    procedure cxgrdPrioridadesExit(Sender: TObject);
  private
    FCodigos: TArray<string>;
    FResultado: TResultadoPrioridadesDistribucion;
    function CrearColumna(
      const ATitulo: string; AAncho: Integer): TcxGridColumn;
    procedure CrearColumnas;
    procedure CargarAlmacenes(const AAlmacenes: TAlmacenesDistribucion);
    function LeerPrioridades: TPrioridadesAlmacenDistribucion;
  protected
    procedure DoCreate; override;
    procedure DoShow; override;
  public
    class function Ejecutar(
      AOwner: TComponent;
      const AAlmacenes: TAlmacenesDistribucion
    ): TResultadoPrioridadesDistribucion;
    function CloseQuery: Boolean; override;
  end;

implementation

{$R *.dfm}

uses
  System.Math,
  inLibMensajesVcl,
  inLibMsgDistribucionTiendas;

const
  COL_ALMACEN = 0;
  COL_NOMBRE = 1;
  COL_PRIORIDAD = 2;
  PRIORIDAD_MAXIMA = 9999;

class function TfrmModalPrioridadesDistribucion.Ejecutar(
  AOwner: TComponent;
  const AAlmacenes: TAlmacenesDistribucion
): TResultadoPrioridadesDistribucion;
var
  oFormulario: TfrmModalPrioridadesDistribucion;
begin
  Result := Default(TResultadoPrioridadesDistribucion);
  if Length(AAlmacenes) = 0 then
    ShowMessage_fza(SInfoPrioridadesDistribucionSinAlmacenes)
  else
  begin
    oFormulario := TfrmModalPrioridadesDistribucion.Create(AOwner);
    // El ancestro se libera solo al cerrar (caFree); aquí se libera a mano
    // para poder leer antes el resultado.
    oFormulario.OnClose := nil;
    try
      oFormulario.CargarAlmacenes(AAlmacenes);
      oFormulario.ShowModal;
      Result := oFormulario.FResultado;
    finally
      FreeAndNil(oFormulario);
    end;
  end;
end;

// Los textos se fijan tras la traducción del formulario base, que si no
// deja el título con el de su ancestro.
procedure TfrmModalPrioridadesDistribucion.DoCreate;
begin
  inherited DoCreate;
  Caption := STituloPrioridadesDistribucion;
  lblAyuda.Caption := STextoAyudaPrioridadesDistribucion;
  CrearColumnas;
end;

procedure TfrmModalPrioridadesDistribucion.DoShow;
begin
  inherited DoShow;
  if cxgrdPrioridades.CanFocus then
    cxgrdPrioridades.SetFocus;
  if tvPrioridades.DataController.RecordCount > 0 then
  begin
    tvPrioridades.Controller.FocusedRecordIndex := 0;
    tvPrioridades.Controller.FocusedItem :=
      tvPrioridades.Columns[COL_PRIORIDAD];
  end;
end;

function TfrmModalPrioridadesDistribucion.CrearColumna(
  const ATitulo: string; AAncho: Integer): TcxGridColumn;
begin
  Result := tvPrioridades.CreateColumn;
  Result.Caption := ATitulo;
  Result.Width := ScaleValue(AAncho);
  Result.Options.Editing := False;
  Result.Options.Focusing := False;
  Result.Options.Filtering := False;
  Result.DataBinding.ValueTypeClass := TcxStringValueType;
end;

// El cero sale en blanco: es "sin número".
procedure TfrmModalPrioridadesDistribucion.CrearColumnas;
var
  oColumna: TcxGridColumn;
  oPropiedades: TcxCurrencyEditProperties;
begin
  tvPrioridades.ClearItems;
  CrearColumna(SCaptionColAlmacenDistribucion, 120);
  CrearColumna(SCaptionColNombreAlmacenDistribucion, 380);
  oColumna := CrearColumna(SCaptionColPrioridadDistribucion, 130);
  oColumna.Options.Editing := True;
  oColumna.Options.Focusing := True;
  oColumna.HeaderAlignmentHorz := taCenter;
  oColumna.DataBinding.ValueTypeClass := TcxIntegerValueType;
  oColumna.PropertiesClass := TcxCurrencyEditProperties;
  oPropiedades := TcxCurrencyEditProperties(oColumna.Properties);
  oPropiedades.DisplayFormat := '0;-0;#';
  oPropiedades.EditFormat := '0;-0;#';
  oPropiedades.DecimalPlaces := 0;
  oPropiedades.MinValue := 0;
  oPropiedades.MaxValue := PRIORIDAD_MAXIMA;
  oPropiedades.Alignment.Horz := taCenter;
end;

procedure TfrmModalPrioridadesDistribucion.CargarAlmacenes(
  const AAlmacenes: TAlmacenesDistribucion);
var
  i: Integer;
begin
  SetLength(FCodigos, Length(AAlmacenes));
  tvPrioridades.BeginUpdate;
  try
    tvPrioridades.DataController.RecordCount := Length(AAlmacenes);
    for i := 0 to High(AAlmacenes) do
    begin
      FCodigos[i] := AAlmacenes[i].Codigo;
      tvPrioridades.DataController.Values[i, COL_ALMACEN] :=
        AAlmacenes[i].Codigo;
      tvPrioridades.DataController.Values[i, COL_NOMBRE] :=
        AAlmacenes[i].Nombre;
      if AAlmacenes[i].Prioridad > 0 then
        tvPrioridades.DataController.Values[i, COL_PRIORIDAD] :=
          AAlmacenes[i].Prioridad;
    end;
  finally
    tvPrioridades.EndUpdate;
  end;
end;

function TfrmModalPrioridadesDistribucion.LeerPrioridades:
  TPrioridadesAlmacenDistribucion;
var
  i: Integer;
  vValor: Variant;
begin
  SetLength(Result, Length(FCodigos));
  for i := 0 to High(FCodigos) do
  begin
    Result[i].CodigoAlmacen := FCodigos[i];
    Result[i].Prioridad := 0;
    vValor := tvPrioridades.DataController.Values[i, COL_PRIORIDAD];
    if not VarIsNull(vValor) and not VarIsEmpty(vValor) then
      Result[i].Prioridad := EnsureRange(
        Integer(vValor), 0, PRIORIDAD_MAXIMA);
  end;
end;

procedure TfrmModalPrioridadesDistribucion.cxgrdPrioridadesEnter(
  Sender: TObject);
begin
  DesactivarEnterAsTabTemporal(Sender);
end;

procedure TfrmModalPrioridadesDistribucion.cxgrdPrioridadesExit(
  Sender: TObject);
begin
  RestaurarEnterAsTabTemporal(Sender);
end;

// sFicha lo fija el ancestro: 'S' con Aceptar o F12 y 'N' con Cancelar o
// ESC. El número que se estuviera tecleando se da por escrito.
function TfrmModalPrioridadesDistribucion.CloseQuery: Boolean;
begin
  Result := inherited CloseQuery;
  if Result and (sFicha = 'S') then
  begin
    if tvPrioridades.Controller.IsEditing then
      tvPrioridades.Controller.EditingController.HideEdit(True);
    FResultado.Aceptado := True;
    FResultado.Prioridades := LeerPrioridades;
  end;
end;

end.
