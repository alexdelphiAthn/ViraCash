{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoReparacionesFasesVcl                                     }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Selector de fase e historiales de cambios y avisos al cliente.            }
{******************************************************************************}
unit inMtoReparacionesFasesVcl;

interface

uses
  System.Classes, Vcl.Controls, cxDropDownEdit, cxMemo, cxLabel,
  inLibReparacionesFases, inMtoGarantiasReparacionesVcl,
  UniDataReparacionesPantalla;

type
  TPanelFasesReparacion = class(TPanelReparaciones)
  private
    FCatalogo: TArray<TFaseReparacionCatalogo>;
    FReparacion: Int64;
    FCodigoActual: string;
    FSelector: TcxComboBox;
    FActual: TcxLabel;
    FObservaciones: TcxMemo;
    procedure CargarCatalogo;
    procedure CrearHistorial;
    procedure CrearAvisos;
    procedure GuardarCambio;
    procedure AnadirFase;
    procedure AvisarCliente;
    procedure GuardarClick(Sender: TObject);
    procedure AnadirClick(Sender: TObject);
    procedure AvisarClick(Sender: TObject);
  public
    constructor CreatePanel(AOwner: TComponent; AParent: TWinControl;
      ADatos: TDatosPantallaReparaciones;
      const AEnlaces: TEnlacesReparaciones); override;
    procedure MostrarReparacion(AReparacion: Int64;
      const ACodigo, ADescripcion: string);
  end;

implementation

uses
  System.SysUtils, Vcl.StdCtrls, cxGridDBTableView,
  inLibMsgReparaciones, inLibMensajesVcl;

constructor TPanelFasesReparacion.CreatePanel(AOwner: TComponent;
  AParent: TWinControl; ADatos: TDatosPantallaReparaciones;
  const AEnlaces: TEnlacesReparaciones);
var
  oRotulo: TcxLabel;
begin
  inherited;
  CrearBoton(SFaseGuardar, 185, GuardarClick);
  CrearBoton(SFaseAnadir, 110, AnadirClick);
  CrearBoton(SFaseAvisar, 215, AvisarClick);
  FActual := TcxLabel.Create(Self);
  FActual.Parent := Self;
  FActual.Align := alTop;
  FActual.Transparent := True;
  FActual.Height := EscalarDpi(32);
  FSelector := TcxComboBox.Create(Self);
  FSelector.Parent := Self;
  FSelector.Align := alTop;
  FSelector.Properties.DropDownListStyle := lsFixedList;
  oRotulo := TcxLabel.Create(Self);
  oRotulo.Parent := Self;
  oRotulo.Align := alTop;
  oRotulo.Transparent := True;
  oRotulo.Caption := SFaseObservaciones;
  FObservaciones := TcxMemo.Create(Self);
  FObservaciones.Parent := Self;
  FObservaciones.Align := alTop;
  FObservaciones.Height := EscalarDpi(65);
  FObservaciones.Hint := SFaseObservaciones;
  FObservaciones.ShowHint := True;
  FObservaciones.Properties.ScrollBars := ssVertical;
  CrearHistorial;
  CrearAvisos;
  CargarCatalogo;
end;

procedure TPanelFasesReparacion.CrearHistorial;
var
  oVista: TcxGridDBTableView;
begin
  oVista := CrearVista(alClient, 0, FDatos.Fases.Origen);
  CrearColumna(oVista, 'INSTANTE_GARHIS', SFotosFecha, 155);
  CrearColumna(oVista, 'FASE_ANTERIOR_GARHIS', SFaseAnterior, 230);
  CrearColumna(oVista, 'FASE_GARHIS', SFaseNueva, 280);
  CrearColumna(oVista, 'USUARIO_ALTA', SMovimientoUsuario, 120);
  CrearColumna(oVista, 'OBSERVACIONES_GARHIS', SFaseObservaciones, 320);
end;

procedure TPanelFasesReparacion.CrearAvisos;
var
  oVista: TcxGridDBTableView;
begin
  oVista := CrearVista(alBottom, EscalarDpi(180), FDatos.Fases.OrigenAvisos);
  CrearColumna(oVista, 'INSTANTE_ALTA', SFotosFecha, 155);
  CrearColumna(oVista, 'EMAIL_GARAVI', SFaseDestinatario, 220);
  CrearColumna(oVista, 'ASUNTO_GARAVI', SFaseAsunto, 280);
  CrearColumna(oVista, 'ESTADO_GARAVI', SMovimientoEstado, 120);
  CrearColumna(oVista, 'RESULTADO_GARAVI', SMovimientoIncidencia, 280);
  CrearColumna(oVista, 'USUARIO_ALTA', SMovimientoUsuario, 110);
  CrearColumna(oVista, 'TEXTO_GARAVI', SFaseMensaje, 400);
end;

procedure TPanelFasesReparacion.CargarCatalogo;
var
  iFase: Integer;
begin
  FCatalogo := FDatos.Fases.Catalogo;
  FSelector.Properties.Items.Clear;
  for iFase := 0 to High(FCatalogo) do
    FSelector.Properties.Items.Add(FCatalogo[iFase].Descripcion);
end;

procedure TPanelFasesReparacion.MostrarReparacion(AReparacion: Int64;
  const ACodigo, ADescripcion: string);
var
  iFase: Integer;
begin
  if FReparacion <> AReparacion then
    FObservaciones.Clear;
  FReparacion := AReparacion;
  FCodigoActual := ACodigo;
  FActual.Caption := SFaseActual + ': ' + ADescripcion;
  CargarCatalogo;
  FSelector.ItemIndex := -1;
  for iFase := 0 to High(FCatalogo) do
    if FCatalogo[iFase].Codigo = ACodigo then
      FSelector.ItemIndex := iFase;
  Enabled := AReparacion > 0;
end;

procedure TPanelFasesReparacion.GuardarCambio;
var
  rCambio: TCambioFaseReparacion;
  iReparacion: Int64;
begin
  if (FSelector.ItemIndex < 0) or
     (FSelector.ItemIndex > High(FCatalogo)) then
    raise EArgumentException.Create(SFaseSeleccionar);
  rCambio := Default(TCambioFaseReparacion);
  iReparacion := FReparacion;
  rCambio.Reparacion := iReparacion;
  rCambio.Anterior := FCodigoActual;
  rCambio.Nueva := FCatalogo[FSelector.ItemIndex].Codigo;
  rCambio.Usuario := FEnlaces.Usuario;
  rCambio.Observaciones := FObservaciones.Text;
  if rCambio.Nueva = FASE_ENTREGADA_CLIENTE then
    FEnlaces.Entregar()
  else
    FDatos.Fases.Cambiar(rCambio);
  FDatos.Fases.Refrescar;
  FEnlaces.Refrescar(iReparacion);
  FObservaciones.Clear;
end;

procedure TPanelFasesReparacion.AnadirFase;
var
  sNombre, sCodigo: string;
  iFase: Integer;
begin
  sNombre := '';
  if InputQuery_fza(SFaseAnadir, SFaseNuevaDescripcion, sNombre) then
  begin
    sCodigo := FDatos.Fases.Anadir(sNombre, FEnlaces.Usuario);
    CargarCatalogo;
    for iFase := 0 to High(FCatalogo) do
      if FCatalogo[iFase].Codigo = sCodigo then
        FSelector.ItemIndex := iFase;
  end;
end;

procedure TPanelFasesReparacion.AvisarCliente;
begin
  FEnlaces.AvisarFase(FDatos.Fases.AvisoSeleccionado);
end;

procedure TPanelFasesReparacion.GuardarClick(Sender: TObject);
begin
  Accion(GuardarCambio);
end;

procedure TPanelFasesReparacion.AnadirClick(Sender: TObject);
begin
  Accion(AnadirFase);
end;

procedure TPanelFasesReparacion.AvisarClick(Sender: TObject);
begin
  Accion(AvisarCliente);
end;

end.
