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
  cxGridCustomTableView, cxGridTableView, System.Classes, Vcl.Controls, cxDropDownEdit, cxMemo, cxLabel, cxPC,
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
    FHistorial: TcxTabSheet;
    FAvisos: TcxTabSheet;
    procedure CargarCatalogo;
    procedure CrearHistorial;
    procedure CrearAvisos;
    procedure EstadoAvisoGetDisplayText(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var AText: string);
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
  System.SysUtils, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Forms,
  cxGridDBTableView,
  inLibMsgReparaciones, inLibMensajesVcl;

constructor TPanelFasesReparacion.CreatePanel(AOwner: TComponent;
  AParent: TWinControl; ADatos: TDatosPantallaReparaciones;
  const AEnlaces: TEnlacesReparaciones);
var
  oRotulo: TcxLabel;
  oContenido: TPanel;
  oEdicion: TScrollBox;
  oHistoriales: TcxPageControl;
begin
  inherited;
  CrearBoton(SFaseGuardar, 185, GuardarClick);
  CrearBoton(SFaseAnadir, 110, AnadirClick);
  CrearBoton(SFaseAvisar, 215, AvisarClick);
  // La edición y los historiales comparten el ancho, no la altura.
  oContenido := TPanel.Create(Self);
  oContenido.Parent := Self;
  oContenido.BevelOuter := bvNone;
  oContenido.Align := alClient;
  oEdicion := TScrollBox.Create(Self);
  oEdicion.Parent := oContenido;
  oEdicion.BorderStyle := bsNone;
  oEdicion.Width := EscalarDpi(360);
  oEdicion.Align := alLeft;
  oHistoriales := TcxPageControl.Create(Self);
  oHistoriales.Parent := oContenido;
  oHistoriales.Align := alClient;
  FHistorial := TcxTabSheet.Create(Self);
  FHistorial.PageControl := oHistoriales;
  FHistorial.Caption := SFaseHistorialCambios;
  FAvisos := TcxTabSheet.Create(Self);
  FAvisos.PageControl := oHistoriales;
  FAvisos.Caption := SFaseHistorialAvisos;
  oHistoriales.ActivePage := FHistorial;
  FActual := TcxLabel.Create(Self);
  FActual.Parent := oEdicion;
  FActual.AutoSize := False;
  FActual.SetBounds(EscalarDpi(8), 0, EscalarDpi(336), EscalarDpi(28));
  FActual.Anchors := [akLeft, akTop, akRight];
  FActual.Transparent := True;
  FSelector := TcxComboBox.Create(Self);
  FSelector.Parent := oEdicion;
  FSelector.SetBounds(EscalarDpi(8), EscalarDpi(32),
    EscalarDpi(336), EscalarDpi(24));
  FSelector.Anchors := [akLeft, akTop, akRight];
  FSelector.Properties.DropDownListStyle := lsFixedList;
  oRotulo := TcxLabel.Create(Self);
  oRotulo.Parent := oEdicion;
  oRotulo.SetBounds(EscalarDpi(8), EscalarDpi(64),
    EscalarDpi(336), EscalarDpi(20));
  oRotulo.Transparent := True;
  oRotulo.Caption := SFaseObservaciones;
  FObservaciones := TcxMemo.Create(Self);
  FObservaciones.Parent := oEdicion;
  FObservaciones.SetBounds(EscalarDpi(8), EscalarDpi(90),
    EscalarDpi(336), EscalarDpi(65));
  FObservaciones.Anchors := [akLeft, akTop, akRight];
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
  oVista.Control.Parent := FHistorial;
  CrearColumna(oVista, 'INSTANTE_GARHIS', SFotosFecha, 155);
  CrearColumna(oVista, 'FASE_ANTERIOR_GARHIS', SFaseAnterior, 230);
  CrearColumna(oVista, 'FASE_GARHIS', SFaseNueva, 280);
  CrearColumna(oVista, 'USUARIO_ALTA', SMovimientoUsuario, 120);
  CrearColumna(oVista, 'OBSERVACIONES_GARHIS', SFaseObservaciones, 320);
end;

procedure TPanelFasesReparacion.EstadoAvisoGetDisplayText(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AText: string);
begin
  if AText = 'ERROR' then
    AText := SFaseAvisoNoEnviado
  else if AText = 'DESCONOCIDO' then
    AText := SFaseAvisoSinConfirmar
  else if AText = 'ENVIANDO' then
    AText := SFaseAvisoEnviando
  else if AText = 'ENVIADO' then
    AText := SFaseAvisoEnviado;
end;

procedure TPanelFasesReparacion.CrearAvisos;
var
  oVista: TcxGridDBTableView;
begin
  oVista := CrearVista(alClient, 0, FDatos.Fases.OrigenAvisos);
  oVista.Control.Parent := FAvisos;
  CrearColumna(oVista, 'INSTANTE_ALTA', SFotosFecha, 155);
  CrearColumna(oVista, 'EMAIL_GARAVI', SFaseDestinatario, 220);
  CrearColumna(oVista, 'ASUNTO_GARAVI', SFaseAsunto, 280);
  CrearColumna(oVista, 'ESTADO_GARAVI', SMovimientoEstado, 150)
    .OnGetDisplayText := EstadoAvisoGetDisplayText;
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
