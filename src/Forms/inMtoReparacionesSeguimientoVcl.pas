{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoReparacionesSeguimientoVcl                               }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Seguimiento de reparaciones y conservación de evidencias.                 }
{******************************************************************************}
unit inMtoReparacionesSeguimientoVcl;

interface

uses
  System.Classes, Vcl.Controls, Vcl.ExtCtrls, cxGridDBTableView,
  cxDropDownEdit, cxListBox, cxLabel, cxMemo,
  inLibReparacionesEvidencias,
  inMtoGarantiasReparacionesVcl, UniDataReparacionesPantalla,
  inLibParametrosIntf;

type
  TPanelMovimientosReparacion = class(TPanelReparaciones)
  private
    FVista: TcxGridDBTableView;
    procedure EtiquetaFabricanteClick(Sender: TObject);
    procedure EtiquetaClienteClick(Sender: TObject);
    procedure ImprimirEtiqueta(AFabricante: Boolean);
    procedure NuevoClick(Sender: TObject);
    procedure SeguimientoClick(Sender: TObject);
    procedure ReintentarClick(Sender: TObject);
    procedure Anadir(ARelacionado, AReintento: Boolean);
  public
    constructor CreatePanel(AOwner: TComponent; AParent: TWinControl;
      ADatos: TDatosPantallaReparaciones;
      const AEnlaces: TEnlacesReparaciones); override;
  end;

  TPanelFotosReparacion = class(TPanelReparaciones)
  private
    FEvidencias: TArray<TEvidenciaReparacion>;
    FIndices: TArray<Integer>;
    FComentario: TcxMemo;
    FParametros: IParametrosAplicacion;
    FReparacion: Int64;
    FLista: TcxListBox;
    FImagen: TImage;
    FFase: TcxComboBox;
    FRotulo: TcxLabel;
    function Carpeta: string;
    procedure DescargarClick(Sender: TObject);
    procedure RefrescarClick(Sender: TObject);
    procedure SeleccionarClick(Sender: TObject);
    procedure RecibirFotos;
    procedure RefrescarFotos;
    procedure CargarFases;
    procedure MostrarEvidencias;
  public
    constructor CreatePanel(AOwner: TComponent; AParent: TWinControl;
      ADatos: TDatosPantallaReparaciones;
      const AEnlaces: TEnlacesReparaciones); override;
    procedure Configurar(const AParametros: IParametrosAplicacion);
    procedure MostrarReparacion(AReparacion: Int64);
  end;

implementation

uses
  System.SysUtils, System.IOUtils, System.Hash, Vcl.Imaging.pngimage,
  Vcl.StdCtrls,
  inLibReparacionesMovimientos, inMtoModalMovimientoReparacion,
  inLibMsgReparaciones, inLibMensajesVcl, inLibFotosNube,
  inLibViraCashApi;

constructor TPanelMovimientosReparacion.CreatePanel(AOwner: TComponent;
  AParent: TWinControl; ADatos: TDatosPantallaReparaciones;
  const AEnlaces: TEnlacesReparaciones);
begin
  inherited;
  CrearBoton(SImpresoEtiquetaFabricante, 150, EtiquetaFabricanteClick);
  CrearBoton(SImpresoEtiquetaCliente, 140, EtiquetaClienteClick);
  CrearBoton(SMovimientoNuevo, 130, NuevoClick);
  CrearBoton(SMovimientoContinuar, 155, SeguimientoClick);
  CrearBoton(SMovimientoReintentar, 150, ReintentarClick);
  FVista := CrearVista(alClient, 0, FDatos.Movimientos.Origen);
  CrearColumna(FVista, 'ID_GARMOV', 'Nº', 65);
  CrearColumna(FVista, 'INSTANTE_GARMOV', SMovimientoFecha, 135);
  CrearColumna(FVista, 'ORIGEN_GARMOV', SMovimientoOrigen, 130);
  CrearColumna(FVista, 'DESTINO_GARMOV', SMovimientoDestino, 130);
  CrearColumna(FVista, 'OBJETO_GARMOV', SMovimientoObjeto, 180);
  CrearColumna(FVista, 'ESTADO_GARMOV', SMovimientoEstado, 105);
  CrearColumna(FVista, 'AGENCIA_GARMOV', SMovimientoAgencia, 100);
  CrearColumna(FVista, 'TRACKING_GARMOV', SMovimientoTracking, 150);
  CrearColumna(FVista, 'INCIDENCIA_GARMOV', SMovimientoIncidencia, 280);
  CrearColumna(FVista, 'ID_ANTERIOR_GARMOV', SMovimientoAnterior, 110);
  CrearColumna(FVista, 'USUARIO_ALTA', SMovimientoUsuario, 100);
end;

procedure TPanelMovimientosReparacion.ImprimirEtiqueta(
  AFabricante: Boolean);
var
  iMovimiento: Int64;
begin
  Accion(
    procedure
    begin
      iMovimiento := FDatos.Movimientos.Actual.Anterior;
      if iMovimiento = 0 then
        raise EArgumentException.Create(SMovimientoSeleccionar);
      FEnlaces.Etiqueta(AFabricante, iMovimiento);
    end);
end;

procedure TPanelMovimientosReparacion.EtiquetaFabricanteClick(
  Sender: TObject);
begin
  ImprimirEtiqueta(True);
end;

procedure TPanelMovimientosReparacion.EtiquetaClienteClick(Sender: TObject);
begin
  ImprimirEtiqueta(False);
end;

procedure TPanelMovimientosReparacion.Anadir(ARelacionado,
  AReintento: Boolean);
var
  rMovimiento: TMovimientoReparacion;
begin
  rMovimiento := Default(TMovimientoReparacion);
  if ARelacionado then
    rMovimiento := FDatos.Movimientos.Actual;
  if ARelacionado and (rMovimiento.Anterior = 0) then
    raise EArgumentException.Create(SMovimientoSeleccionar);
  rMovimiento.Reparacion := FEnlaces.ReparacionActual();
  if rMovimiento.Reparacion <= 0 then
    raise EArgumentException.Create(SInfoSinReparacion);
  rMovimiento.Usuario := FEnlaces.Usuario;
  if AReintento then
    rMovimiento.Seguimiento := '';
  if TfrmModalMovimientoReparacion.Ejecutar(Self, rMovimiento) then
    FDatos.Movimientos.Registrar(rMovimiento);
end;

procedure TPanelMovimientosReparacion.NuevoClick(Sender: TObject);
begin
  Accion(
    procedure
    begin
      Anadir(False, False);
    end);
end;

procedure TPanelMovimientosReparacion.SeguimientoClick(Sender: TObject);
begin
  Accion(
    procedure
    begin
      Anadir(True, False);
    end);
end;

procedure TPanelMovimientosReparacion.ReintentarClick(Sender: TObject);
begin
  Accion(
    procedure
    begin
      Anadir(True, True);
    end);
end;

constructor TPanelFotosReparacion.CreatePanel(AOwner: TComponent;
  AParent: TWinControl; ADatos: TDatosPantallaReparaciones;
  const AEnlaces: TEnlacesReparaciones);
begin
  inherited;
  CrearBoton(SFotosDescargar, 215, DescargarClick);
  CrearBoton(SFotosRefrescar, 100, RefrescarClick);
  FFase := TcxComboBox.Create(Self);
  FFase.Parent := FBotonera;
  FFase.SetBounds(EscalarDpi(335), EscalarDpi(8), EscalarDpi(220), 26);
  FFase.Properties.DropDownListStyle := lsFixedList;
  FFase.Properties.Items.Add(SFotosTodasFases);
  FFase.ItemIndex := 0;
  FFase.Properties.OnChange := RefrescarClick;
  FRotulo := TcxLabel.Create(Self);
  FRotulo.Parent := Self;
  FRotulo.Align := alTop;
  FRotulo.Transparent := True;
  FRotulo.Properties.WordWrap := True;
  FRotulo.Height := EscalarDpi(48);
  FLista := TcxListBox.Create(Self);
  FLista.Parent := Self;
  FLista.Align := alLeft;
  FLista.Width := EscalarDpi(330);
  FLista.OnClick := SeleccionarClick;
  FComentario := TcxMemo.Create(Self);
  FComentario.Parent := Self;
  FComentario.Align := alBottom;
  FComentario.Height := EscalarDpi(110);
  FComentario.Properties.ReadOnly := True;
  FComentario.Properties.ScrollBars := ssVertical;
  FImagen := TImage.Create(Self);
  FImagen.Parent := Self;
  FImagen.Align := alClient;
  FImagen.Proportional := True;
  FImagen.Stretch := True;
  FImagen.Center := True;
end;

procedure TPanelFotosReparacion.Configurar(
  const AParametros: IParametrosAplicacion);
begin
  FParametros := AParametros;
end;

function TPanelFotosReparacion.Carpeta: string;
var
  sBase: string;
  sInstalacion: string;
begin
  sBase := FParametros.GetPath('appDirFotos');
  if Trim(sBase) = '' then
    raise EArgumentException.Create(SFotosConfigurarCarpeta);
  sInstalacion := THashSHA2.GetHashString(
    TClienteViraCashApi.Referencia(FParametros));
  Result := TPath.Combine(sBase, 'reparaciones');
  Result := TPath.Combine(Result, sInstalacion);
  Result := TPath.Combine(Result, IntToStr(FReparacion));
end;

procedure TPanelFotosReparacion.MostrarReparacion(AReparacion: Int64);
begin
  if AReparacion <> FReparacion then
  begin
    FReparacion := AReparacion;
    FRotulo.Caption := Format(SFotosInstrucciones, [FReparacion]);
    RefrescarFotos;
  end;
end;

procedure TPanelFotosReparacion.CargarFases;
var
  rEvidencia: TEvidenciaReparacion;
  sSeleccion: string;
begin
  sSeleccion := FFase.Text;
  FFase.Properties.OnChange := nil;
  try
    FFase.Properties.Items.Clear;
    FFase.Properties.Items.Add(SFotosTodasFases);
    for rEvidencia in FEvidencias do
      if FFase.Properties.Items.IndexOf(rEvidencia.Fase) < 0 then
        FFase.Properties.Items.Add(rEvidencia.Fase);
    FFase.ItemIndex := FFase.Properties.Items.IndexOf(sSeleccion);
    if FFase.ItemIndex < 0 then
      FFase.ItemIndex := 0;
  finally
    FFase.Properties.OnChange := RefrescarClick;
  end;
end;

procedure TPanelFotosReparacion.MostrarEvidencias;
var
  iIndice: Integer;
  rEvidencia: TEvidenciaReparacion;
begin
  FIndices := nil;
  for iIndice := 0 to High(FEvidencias) do
  begin
    rEvidencia := FEvidencias[iIndice];
    if (FFase.ItemIndex = 0) or (rEvidencia.Fase = FFase.Text) then
    begin
      SetLength(FIndices, Length(FIndices) + 1);
      FIndices[High(FIndices)] := iIndice;
      FLista.Items.Add(rEvidencia.Fase + ' · ' +
        Copy(rEvidencia.Nombre, LastDelimiter('_', rEvidencia.Nombre) + 1,
          MaxInt) + ' · ' + rEvidencia.Instante);
    end;
  end;
  if FLista.Items.Count > 0 then
  begin
    FLista.ItemIndex := 0;
    SeleccionarClick(nil);
  end;
end;

procedure TPanelFotosReparacion.RefrescarFotos;
begin
  FLista.Items.Clear;
  FImagen.Picture.Assign(nil);
  FComentario.Clear;
  FEvidencias := nil;
  if Assigned(FParametros) and (FReparacion > 0) and
     (Trim(FParametros.GetPath('appDirFotos')) <> '') then
    FEvidencias := LeerEvidenciasReparacion(Carpeta);
  CargarFases;
  MostrarEvidencias;
end;

procedure TPanelFotosReparacion.RecibirFotos;
var
  aArchivos: TArray<string>;
  sArchivo, sDestino, sError: string;
begin
  if FReparacion <= 0 then
    raise EArgumentException.Create(SInfoSinReparacion);
  if not DescargarFotosArticulo(FParametros, '', aArchivos, sError,
    FReparacion) then
    raise EArgumentException.Create(sError);
  try
    ForceDirectories(Carpeta);
    for sArchivo in aArchivos do
    begin
      sDestino := TPath.Combine(Carpeta, ExtractFileName(sArchivo));
      if TFile.Exists(sDestino) then
      begin
        if THashSHA2.GetHashStringFromFile(sArchivo) <>
           THashSHA2.GetHashStringFromFile(sDestino) then
          raise EArgumentException.Create(Format(SFotosConflicto,
            [ExtractFileName(sArchivo)]));
      end
      else
        TFile.Copy(sArchivo, sDestino, False);
    end;
  finally
    LimpiarDescargaTemporal(aArchivos);
  end;
  RefrescarFotos;
end;

procedure TPanelFotosReparacion.DescargarClick(Sender: TObject);
begin
  Accion(RecibirFotos);
end;

procedure TPanelFotosReparacion.RefrescarClick(Sender: TObject);
begin
  RefrescarFotos;
end;

procedure TPanelFotosReparacion.SeleccionarClick(Sender: TObject);
var
  rEvidencia: TEvidenciaReparacion;
begin
  FImagen.Picture.Assign(nil);
  FComentario.Clear;
  if FLista.ItemIndex >= 0 then
  begin
    rEvidencia := FEvidencias[FIndices[FLista.ItemIndex]];
    FComentario.Text := rEvidencia.Instante + ' UTC' + sLineBreak +
      rEvidencia.Comentario;
    if (rEvidencia.Archivo <> '') and FileExists(rEvidencia.Archivo) then
      FImagen.Picture.LoadFromFile(rEvidencia.Archivo);
  end;
end;

end.
