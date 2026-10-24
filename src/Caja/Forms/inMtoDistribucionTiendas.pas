{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoDistribucionTiendas                                      }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       21/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Almacén - Distribuir entre tiendas: se elige el documento de trabajo que  }
{    se reparte y se ve el historial de las propuestas de traspaso con su      }
{    estado (pendiente, trasladado, no aceptado). Desde aquí se confirman, se  }
{    dan por no aceptadas, se imprimen y se fijan las prioridades de los       }
{    almacenes.                                                                }
{******************************************************************************}
unit inMtoDistribucionTiendas;

interface

uses
  inLibRegistroPantallas,
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Data.DB,
  cxClasses, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxEdit, cxNavigator, cxDBData, cxGridLevel,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxContainer, cxLabel, cxTextEdit,
  cxMaskEdit, cxDropDownEdit, cxLookupEdit, cxDBLookupEdit,
  cxDBLookupComboBox, cxButtons, cxPC, dxSkinsCore,
  dxSkinscxPCPainter, dxScrollbarAnnotations, dxDateRanges, dxCore,
  UniDataDistribucionTiendas, inLibDistribucionTiendasIntf, inMtoGen;

type
  TfrmMtoDistribucionTiendas = class(TfrmMtoGen)
    procedure FormCreate(Sender: TObject);
  private
    FControlesCreados: Boolean;
    dmmDistribucion: TdmDistribucionTiendas;
    pnlDistribucion: TPanel;
    cbbDocumento: TcxLookupComboBox;
    function EscalarDpi(AValor: Integer): Integer;
    procedure CrearControlesDinamicos;
    function CrearBoton(
      const ATexto: string; AIzq, ATop, AAncho: Integer;
      AAlPulsar: TNotifyEvent): TcxButton;
    function CrearColumna(
      const ACampo, ATitulo: string; AAncho: Integer): TcxGridDBColumn;
    procedure CrearColumnas;
    function HayPropuestaEnfocada: Boolean;
    function CampoEnfocado(const ACampo: string): TField;
    function PropuestaEnfocadaPendiente(out AIdPropuesta: Int64): Boolean;
    procedure AbrirEditor(AIdDocumento: Int64);
    procedure RefrescarTodo;
    procedure btnDistribuirClick(Sender: TObject);
    procedure btnAbrirClick(Sender: TObject);
    procedure btnConfirmarClick(Sender: TObject);
    procedure btnNoAceptarClick(Sender: TObject);
    procedure btnImprimirClick(Sender: TObject);
    procedure btnPrioridadesClick(Sender: TObject);
    procedure btnRefrescarClick(Sender: TObject);
  protected
    procedure DoCreate; override;
  public
    destructor Destroy; override;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

implementation

uses
  inLibMensajesVcl,
  inLibInformePropuestasTraspaso,
  inLibMsgDistribucionTiendas,
  inMtoModalDistribucionTiendas,
  inMtoModalPrioridadesDistribucion,
  inMtoModalImpPropuestasTraspaso;

{$R *.dfm}

const
  CAMPO_ID_PROPUESTA = 'ID_TRPRO';
  CAMPO_ID_DOCUMENTO = 'ID_DTR_TRPRO';
  CAMPO_ESTADO = 'ESTADO_TRPRO';
  CAMPO_ORIGEN = 'ORIGEN';
  CAMPO_DESTINO = 'DESTINO';
  CAMPO_UNIDADES = 'UNIDADES';
  FORMATO_UNIDADES = '0.###';

procedure ForceReferenceToClass(C: TClass);
begin
end;

procedure TfrmMtoDistribucionTiendas.FormCreate(Sender: TObject);
begin
  CrearControlesDinamicos;
  inherited;
end;

// El título se fija tras la traducción del formulario base, que si no lo
// deja con el de su ancestro.
procedure TfrmMtoDistribucionTiendas.DoCreate;
begin
  inherited DoCreate;
  Caption := STituloHistorialDistribucionTiendas;
end;

destructor TfrmMtoDistribucionTiendas.Destroy;
begin
  if Assigned(cbbDocumento) then
    cbbDocumento.Properties.ListSource := nil;
  inherited;
end;

function TfrmMtoDistribucionTiendas.EscalarDpi(AValor: Integer): Integer;
begin
  Result := MulDiv(AValor, CurrentPPI, 96);
end;

function TfrmMtoDistribucionTiendas.CrearBoton(
  const ATexto: string; AIzq, ATop, AAncho: Integer;
  AAlPulsar: TNotifyEvent): TcxButton;
begin
  Result := TcxButton.Create(Self);
  Result.Parent := pnlDistribucion;
  Result.Left := EscalarDpi(AIzq);
  Result.Top := EscalarDpi(ATop);
  Result.Width := EscalarDpi(AAncho);
  Result.Height := EscalarDpi(34);
  Result.Caption := ATexto;
  Result.OnClick := AAlPulsar;
end;

procedure TfrmMtoDistribucionTiendas.CrearControlesDinamicos;
var
  oEtiqueta: TcxLabel;
begin
  if not FControlesCreados then
  begin
    pnlDistribucion := TPanel.Create(Self);
    pnlDistribucion.Parent := tsLista;
    pnlDistribucion.Align := alTop;
    pnlDistribucion.Height := EscalarDpi(136);
    pnlDistribucion.BevelOuter := bvNone;
    oEtiqueta := TcxLabel.Create(Self);
    oEtiqueta.Parent := pnlDistribucion;
    oEtiqueta.Left := EscalarDpi(12);
    oEtiqueta.Top := EscalarDpi(16);
    oEtiqueta.Caption := SCaptionDocumentoDistribucion;
    oEtiqueta.Transparent := True;
    cbbDocumento := TcxLookupComboBox.Create(Self);
    cbbDocumento.Parent := pnlDistribucion;
    cbbDocumento.Left := EscalarDpi(190);
    cbbDocumento.Top := EscalarDpi(12);
    cbbDocumento.Width := EscalarDpi(560);
    cbbDocumento.Properties.DropDownListStyle := lsFixedList;
    cbbDocumento.Properties.KeyFieldNames := 'ID_DTR';
    cbbDocumento.Properties.ListFieldNames := 'DOCUMENTO';
    cbbDocumento.Properties.ListOptions.ShowHeader := False;
    cbbDocumento.Properties.DropDownRows := 16;
    CrearBoton(SCaptionDistribuirDocumento, 762, 10, 150,
      btnDistribuirClick);
    CrearBoton(SCaptionAbrirDistribucion, 12, 54, 180, btnAbrirClick);
    CrearBoton(SCaptionConfirmarPropuesta, 200, 54, 190,
      btnConfirmarClick);
    CrearBoton(SCaptionNoAceptarPropuesta, 398, 54, 130,
      btnNoAceptarClick);
    CrearBoton(SCaptionImprimirPropuesta, 536, 54, 110, btnImprimirClick);
    CrearBoton(SCaptionPrioridadesDistribucion, 654, 54, 140,
      btnPrioridadesClick);
    CrearBoton(SCaptionRefrescarHistorialDistribucion, 802, 54, 110,
      btnRefrescarClick);
    oEtiqueta := TcxLabel.Create(Self);
    oEtiqueta.Parent := pnlDistribucion;
    oEtiqueta.Left := EscalarDpi(12);
    oEtiqueta.Top := EscalarDpi(98);
    oEtiqueta.Caption := STextoAyudaHistorialDistribucion;
    oEtiqueta.Transparent := True;
    FControlesCreados := True;
  end;
end;

function TfrmMtoDistribucionTiendas.CrearColumna(
  const ACampo, ATitulo: string; AAncho: Integer): TcxGridDBColumn;
begin
  Result := cxGrdDBTabPrin.CreateColumn;
  Result.DataBinding.FieldName := ACampo;
  Result.Caption := ATitulo;
  Result.Width := EscalarDpi(AAncho);
  Result.Options.Editing := False;
end;

procedure TfrmMtoDistribucionTiendas.CrearColumnas;
begin
  if cxGrdDBTabPrin.ColumnCount = 0 then
  begin
    CrearColumna(CAMPO_ID_PROPUESTA, SCaptionColNumeroPropuesta, 90);
    CrearColumna('INSTANTE_PROPUESTA_TRPRO', SCaptionColFechaPropuesta,
      140);
    CrearColumna(CAMPO_ESTADO, SCaptionColEstadoPropuesta, 170);
    CrearColumna(CAMPO_ORIGEN, SCaptionColOrigenPropuesta, 210);
    CrearColumna(CAMPO_DESTINO, SCaptionColDestinoPropuesta, 210);
    CrearColumna(CAMPO_UNIDADES, SCaptionColUnidadesPropuesta, 90);
    CrearColumna('TRASPASO', SCaptionColTraspasoPropuesta, 170);
    CrearColumna('NUMERO_OPERACION_TRPRO', SCaptionColOperacionPropuesta,
      110);
    CrearColumna('INSTANTE_RESOLUCION_TRPRO',
      SCaptionColResolucionPropuesta, 140);
    CrearColumna('USUARIO_RESOLUCION_TRPRO',
      SCaptionColUsuarioResolucionPropuesta, 120);
    CrearColumna('MOTIVO_RECHAZO_TRPRO', SCaptionColMotivoPropuesta, 240);
    CrearColumna(CAMPO_ID_DOCUMENTO, SCaptionColDocumentoPropuesta, 90);
    CrearColumna('TITULO_DTR', SCaptionColDescripcionDistribucion, 260);
    CrearColumna('USUARIO_ALTA', SCaptionColUsuarioPropuesta, 120);
  end;
end;

procedure TfrmMtoDistribucionTiendas.CrearTablaPrincipal;
begin
  inherited;
  dmmDistribucion := tdmDataModule as TdmDistribucionTiendas;
  // El selector debe estar disponible aunque falle la carga del historial.
  dmmDistribucion.AbrirDocumentos;
  pkFieldName := CAMPO_ID_PROPUESTA;
  cxGrdDBTabPrin.OptionsData.Editing := False;
  cxGrdDBTabPrin.OptionsData.Inserting := False;
  cxGrdDBTabPrin.OptionsData.Deleting := False;
  tsFicha.TabVisible := False;
  nvNavegador.Visible := False;
  cbbDocumento.Properties.ListSource := dmmDistribucion.dsDocumentos;
  cbbDocumento.EditValue := Null;
  CrearColumnas;
end;

procedure TfrmMtoDistribucionTiendas.ResetForm;
begin
  inherited;
  pcPantalla.ActivePage := tsLista;
end;

// ===========================================================================
//   Propuesta enfocada
// ===========================================================================

function TfrmMtoDistribucionTiendas.HayPropuestaEnfocada: Boolean;
begin
  Result := Assigned(dsTablaG.DataSet) and dsTablaG.DataSet.Active and
    not dsTablaG.DataSet.IsEmpty;
  if not Result then
    ShowMessage_fza(SInfoSeleccionarPropuesta);
end;

function TfrmMtoDistribucionTiendas.CampoEnfocado(
  const ACampo: string): TField;
begin
  Result := dsTablaG.DataSet.FieldByName(ACampo);
end;

function TfrmMtoDistribucionTiendas.PropuestaEnfocadaPendiente(
  out AIdPropuesta: Int64): Boolean;
begin
  AIdPropuesta := 0;
  Result := HayPropuestaEnfocada;
  if Result then
  begin
    AIdPropuesta := CampoEnfocado(CAMPO_ID_PROPUESTA).AsLargeInt;
    Result := SameText(
      Trim(CampoEnfocado(CAMPO_ESTADO).AsString),
      ESTADO_PROPUESTA_TRASPASO_PENDIENTE);
    if not Result then
      ShowMessage_fza(Format(SInfoPropuestaYaNoPendiente, [AIdPropuesta]));
  end;
end;

// ===========================================================================
//   Acciones
// ===========================================================================

procedure TfrmMtoDistribucionTiendas.RefrescarTodo;
begin
  if Assigned(dmmDistribucion) then
  begin
    dmmDistribucion.RefrescarHistorial;
    dmmDistribucion.AbrirDocumentos;
  end;
end;

procedure TfrmMtoDistribucionTiendas.AbrirEditor(AIdDocumento: Int64);
var
  Configuracion: TConfiguracionDistribucionTiendas;
begin
  Configuracion := Default(TConfiguracionDistribucionTiendas);
  Configuracion.IdDocumento := AIdDocumento;
  Configuracion.Servicios := dmmDistribucion.CrearServicios;
  Configuracion.Usuario := Trim(IdentidadSesion.Usuario);
  Configuracion.PuedeImprimir := True;
  TfrmModalDistribucionTiendas.Ejecutar(Self, Configuracion);
  RefrescarTodo;
end;

procedure TfrmMtoDistribucionTiendas.btnDistribuirClick(Sender: TObject);
begin
  if VarIsNull(cbbDocumento.EditValue) or
     VarIsEmpty(cbbDocumento.EditValue) then
    ShowMessage_fza(SInfoElegirDocumentoDistribucion)
  else
    AbrirEditor(cbbDocumento.EditValue);
end;

procedure TfrmMtoDistribucionTiendas.btnAbrirClick(Sender: TObject);
begin
  if HayPropuestaEnfocada then
    AbrirEditor(CampoEnfocado(CAMPO_ID_DOCUMENTO).AsLargeInt);
end;

procedure TfrmMtoDistribucionTiendas.btnConfirmarClick(Sender: TObject);
var
  iIdPropuesta: Int64;
  Resultado: TResultadoConfirmacionPropuesta;
begin
  if PropuestaEnfocadaPendiente(iIdPropuesta) and
     (MessageDlg_fza(Format(SPreguntaConfirmarPropuesta, [
        iIdPropuesta,
        FormatFloat(FORMATO_UNIDADES,
          CampoEnfocado(CAMPO_UNIDADES).AsFloat),
        CampoEnfocado(CAMPO_ORIGEN).AsString,
        CampoEnfocado(CAMPO_DESTINO).AsString]),
        mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
  begin
    Screen.Cursor := crHourGlass;
    try
      Resultado := dmmDistribucion.CrearServicios.Confirmador.Confirmar(
        iIdPropuesta, Now);
    finally
      Screen.Cursor := crDefault;
    end;
    RefrescarTodo;
    if Resultado.Confirmada then
      ShowMessage_fza(Format(SInfoPropuestaConfirmada, [
        iIdPropuesta, Resultado.TipoDocumento, Resultado.SerieDocumento,
        Resultado.NumeroDocumento]))
    else
      ShowMessage_fza(Format(SErrorPropuestaNoConfirmada, [
        iIdPropuesta, Resultado.Mensaje]));
  end;
end;

procedure TfrmMtoDistribucionTiendas.btnNoAceptarClick(Sender: TObject);
var
  iIdPropuesta: Int64;
  sMotivo: string;
begin
  sMotivo := '';
  if PropuestaEnfocadaPendiente(iIdPropuesta) and
     InputQuery_fza(
       Format(STituloNoAceptarPropuesta, [iIdPropuesta]),
       SPreguntaMotivoNoAceptarPropuesta, sMotivo) then
  begin
    if Trim(sMotivo) = '' then
      ShowMessage_fza(SErrorMotivoNoAceptarObligatorio)
    else
    begin
      if dmmDistribucion.CrearServicios.Repositorio.RechazarPropuesta(
           iIdPropuesta, Trim(sMotivo), Trim(IdentidadSesion.Usuario)) then
        ShowMessage_fza(Format(SInfoPropuestaNoAceptada, [iIdPropuesta]))
      else
        ShowMessage_fza(Format(SInfoPropuestaYaNoPendiente, [
          iIdPropuesta]));
      RefrescarTodo;
    end;
  end;
end;

procedure TfrmMtoDistribucionTiendas.btnImprimirClick(Sender: TObject);
var
  Propuestas: TPropuestasTraspaso;
begin
  if HayPropuestaEnfocada then
  begin
    SetLength(Propuestas, 1);
    Propuestas[0] :=
      dmmDistribucion.CrearServicios.Repositorio.LeerPropuesta(
        CampoEnfocado(CAMPO_ID_PROPUESTA).AsLargeInt);
    TfrmPrintPropuestasTraspaso.Mostrar(
      Self,
      ComponerInformePropuestasTraspaso(Propuestas),
      Propuestas[0].IdDocumento);
  end;
end;

// Los números son del almacén: valen para todos los documentos.
procedure TfrmMtoDistribucionTiendas.btnPrioridadesClick(Sender: TObject);
var
  Servicios: TServiciosDistribucionTiendas;
  Resultado: TResultadoPrioridadesDistribucion;
begin
  Servicios := dmmDistribucion.CrearServicios;
  Resultado := TfrmModalPrioridadesDistribucion.Ejecutar(
    Self, Servicios.Repositorio.ListarAlmacenesDestino);
  if Resultado.Aceptado then
    Servicios.Repositorio.GuardarPrioridadesAlmacenes(
      Resultado.Prioridades, Trim(IdentidadSesion.Usuario));
end;

procedure TfrmMtoDistribucionTiendas.btnRefrescarClick(Sender: TObject);
begin
  RefrescarTodo;
end;

initialization
  RegistrarPantalla(TfrmMtoDistribucionTiendas);
  ForceReferenceToClass(TfrmMtoDistribucionTiendas);
end.
