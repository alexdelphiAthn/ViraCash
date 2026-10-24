{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoPrestaShopCola                                           }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       14/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Consulta de la cola de PrestaShop, operaciones HTTP y respuestas.         }
{    Es una pantalla de diagnóstico sin acciones de edición ni reintento.      }
{******************************************************************************}
unit inMtoPrestaShopCola;

interface

uses
  System.SysUtils, System.Classes, Data.DB, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.ExtCtrls, cxButtons, cxCheckBox, cxGrid,
  cxGridDBTableView, cxGridLevel, cxLabel, cxMemo, cxPC,
  inMtoGen, UniDataPrestaShopColaMonitor;

type
  TfrmMtoPrestaShopCola = class(TfrmMtoGen)
    colIdCola: TcxGridDBColumn;
    colTienda: TcxGridDBColumn;
    colArticulo: TcxGridDBColumn;
    colNombreArticulo: TcxGridDBColumn;
    colCambioPrecio: TcxGridDBColumn;
    colCambioStock: TcxGridDBColumn;
    colAccionVisibilidad: TcxGridDBColumn;
    colPrecioReclamado: TcxGridDBColumn;
    colStockReclamado: TcxGridDBColumn;
    colAccionVisibilidadReclamada: TcxGridDBColumn;
    colEstado: TcxGridDBColumn;
    colIntentos: TcxGridDBColumn;
    colProximoIntento: TcxGridDBColumn;
    colUltimoCambio: TcxGridDBColumn;
    colUltimoEnvio: TcxGridDBColumn;
    colErrorCola: TcxGridDBColumn;
    colAlta: TcxGridDBColumn;
    pnlDetalle: TPanel;
    pnlTituloHistorial: TPanel;
    lblHistorial: TcxLabel;
    cxgrdEventos: TcxGrid;
    tvEventos: TcxGridDBTableView;
    lvEventos: TcxGridLevel;
    tvEventosId: TcxGridDBColumn;
    tvEventosIntento: TcxGridDBColumn;
    tvEventosOrden: TcxGridDBColumn;
    tvEventosMetodo: TcxGridDBColumn;
    tvEventosRecurso: TcxGridDBColumn;
    tvEventosHttp: TcxGridDBColumn;
    tvEventosEstadoHttp: TcxGridDBColumn;
    tvEventosResultado: TcxGridDBColumn;
    tvEventosInicio: TcxGridDBColumn;
    tvEventosDuracion: TcxGridDBColumn;
    pcContenido: TcxPageControl;
    tsPeticion: TcxTabSheet;
    tsRespuesta: TcxTabSheet;
    tsError: TcxTabSheet;
    mPeticion: TcxMemo;
    mRespuesta: TcxMemo;
    mError: TcxMemo;
    btnActualizar: TcxButton;
    btnIrAArticulo: TcxButton;
    btnEnviarYa: TcxButton;
    procedure btnActualizarClick(Sender: TObject);
    procedure btnIrAArticuloClick(Sender: TObject);
    // FZ-ISSUE-310: reactiva las filas pendientes o con error
    procedure btnEnviarYaClick(Sender: TObject);
  private
    FTemporizadorRefresco: TTimer;
    dmmPrestaShopCola: TdmPrestaShopColaMonitor;
    FIdColaActual: Int64;
    FIdEventoActual: Int64;
    FPuedeVerDetalle: Boolean;
    procedure RefrescarColaActiva(Sender: TObject);
    procedure ConfigurarSoloLectura;
    procedure ColaDataChange(Sender: TObject; Field: TField);
    procedure EventoDataChange(Sender: TObject; Field: TField);
    procedure LimpiarContenido;
    procedure MostrarErrorDetalle(const AContexto, AError: string);
  public
    destructor Destroy; override;
    procedure CrearTablaPrincipal; override;
    function SqlRestriccionUsuario: string; override;
    procedure ResetForm; override;
  end;

implementation

uses
  inLibPermisosIntf, inLibPrestaCatalogo, inLibRegistroPantallas,
  inLibShowMto, inLibColaEnviarYa, inLibColaEnviarYaVcl,
  inLibPrestaShopColaSenal, UniDataColaEnviarYa;

{$R *.dfm}

const
  CPermisoConsultar = 'PrestaShopCola.consultar';
  CPermisoDetalle = 'PrestaShopCola.detalle';

procedure ForceReferenceToClass(C: TClass);
begin
end;

procedure TfrmMtoPrestaShopCola.ConfigurarSoloLectura;
begin
  nvNavegador.Buttons.Insert.Visible := False;
  nvNavegador.Buttons.Append.Visible := False;
  nvNavegador.Buttons.Edit.Visible := False;
  nvNavegador.Buttons.Delete.Visible := False;
  nvNavegador.Buttons.Post.Visible := False;
  nvNavegador.Buttons.Cancel.Visible := False;
  actInsertarRegistro.Enabled := False;
  actInsertarRegistro.ShortCut := 0;
  actEditarRegistro.Enabled := False;
  actEliminarRegistro.Enabled := False;
  actEliminarRegistro.ShortCut := 0;
  actGrabarRegistro.Enabled := False;
  btnGrabar.Visible := False;
  btnCancelar.Visible := False;
end;

destructor TfrmMtoPrestaShopCola.Destroy;
begin
  FreeAndNil(FTemporizadorRefresco);
  inherited;
end;

procedure TfrmMtoPrestaShopCola.RefrescarColaActiva(Sender: TObject);
var
  sSincronizar: string;
begin
  sSincronizar := Trim(ParametrosApp.GetString(
    'appPrestaShopSincronizarStockPrecios', 'False'));
  if not (csDestroying in ComponentState) and Visible and Enabled and
     not ContextoSesion.CerrandoAplicacion and
     Assigned(dsTablaG.DataSet) and dsTablaG.DataSet.Active and
     (dsTablaG.DataSet.State = dsBrowse) and
     (SameText(sSincronizar, 'True') or (sSincronizar = '1') or
      SameText(sSincronizar, 'S')) then
  begin
    FTemporizadorRefresco.Enabled := False;
    try
      try
        btnActualizarClick(Self);
      except
        on E: Exception do
          RegistroLog.RegistrarError(
            'No se pudo refrescar la cola de PrestaShop: ' +
            E.Message);
      end;
    finally
      FTemporizadorRefresco.Enabled := True;
    end;
  end;
end;

procedure TfrmMtoPrestaShopCola.CrearTablaPrincipal;
begin
  inherited;
  dmmPrestaShopCola := tdmDataModule as TdmPrestaShopColaMonitor;
  pkFieldName := 'ID_PSCOLA';
  FIdColaActual := -1;
  FIdEventoActual := -1;
  ConfigurarSoloLectura;
  // FZ-ISSUE-310: «Enviar ya» actúa sobre las filas seleccionadas
  cxGrdDBTabPrin.OptionsSelection.MultiSelect := True;
  FPuedeVerDetalle := Assigned(Permisos) and
    Permisos.TienePermiso(CPermisoDetalle, paDenegar);
  pnlDetalle.Visible := FPuedeVerDetalle;
  if FPuedeVerDetalle then
  begin
    tvEventos.DataController.DataSource := dmmPrestaShopCola.dsEventos;
    dsTablaG.OnDataChange := ColaDataChange;
    dmmPrestaShopCola.dsEventos.OnDataChange := EventoDataChange;
  end;
  LimpiarContenido;
  FTemporizadorRefresco := TTimer.Create(Self);
  FTemporizadorRefresco.Enabled := False;
  FTemporizadorRefresco.Interval := 20000;
  FTemporizadorRefresco.OnTimer := RefrescarColaActiva;
  FTemporizadorRefresco.Enabled := True;
end;

procedure TfrmMtoPrestaShopCola.LimpiarContenido;
begin
  mPeticion.Lines.Clear;
  mRespuesta.Lines.Clear;
  mError.Lines.Clear;
end;

procedure TfrmMtoPrestaShopCola.MostrarErrorDetalle(
  const AContexto, AError: string);
begin
  LimpiarContenido;
  mError.Lines.Text := AError;
  pcContenido.ActivePage := tsError;
  RegistroLog.RegistrarError(AContexto + ': ' + AError);
end;

procedure TfrmMtoPrestaShopCola.ColaDataChange(
  Sender: TObject; Field: TField);
var
  iIdCola: Int64;
begin
  if FPuedeVerDetalle and Assigned(dmmPrestaShopCola) then
  begin
    iIdCola := 0;
    if Assigned(dsTablaG.DataSet) and dsTablaG.DataSet.Active and
       not dsTablaG.DataSet.IsEmpty then
      iIdCola := dsTablaG.DataSet.FieldByName('ID_PSCOLA').AsLargeInt;
    if iIdCola <> FIdColaActual then
    begin
      FIdColaActual := iIdCola;
      FIdEventoActual := -1;
      LimpiarContenido;
      try
        dmmPrestaShopCola.CargarEventos(iIdCola);
      except
        on E: Exception do
          MostrarErrorDetalle(
            'No se pudo cargar el historial de PrestaShop', E.Message);
      end;
    end;
  end;
end;

procedure TfrmMtoPrestaShopCola.EventoDataChange(
  Sender: TObject; Field: TField);
var
  iIdEvento: Int64;
  sError: string;
  sPeticion: string;
  sRespuesta: string;
begin
  if FPuedeVerDetalle and Assigned(dmmPrestaShopCola) then
  begin
    iIdEvento := 0;
    if dmmPrestaShopCola.unqryEventos.Active and
       not dmmPrestaShopCola.unqryEventos.IsEmpty then
      iIdEvento := dmmPrestaShopCola.unqryEventos.FieldByName(
        'ID_PSCEV').AsLargeInt;
    if iIdEvento <> FIdEventoActual then
    begin
      FIdEventoActual := iIdEvento;
      try
        dmmPrestaShopCola.LeerContenidoEvento(
          iIdEvento, sPeticion, sRespuesta, sError);
        mPeticion.Lines.Text := sPeticion;
        mRespuesta.Lines.Text := sRespuesta;
        mError.Lines.Text := sError;
      except
        on E: Exception do
          MostrarErrorDetalle(
            'No se pudo cargar el contenido HTTP de PrestaShop', E.Message);
      end;
    end;
  end;
end;

procedure TfrmMtoPrestaShopCola.btnActualizarClick(Sender: TObject);
var
  oCursorAnterior: TCursor;
begin
  oCursorAnterior := Screen.Cursor;
  Screen.Cursor := crHourGlass;
  try
    FIdColaActual := -1;
    FIdEventoActual := -1;
    dmmPrestaShopCola.ActualizarCola;
    ColaDataChange(Self, nil);
  finally
    Screen.Cursor := oCursorAnterior;
  end;
end;

procedure TfrmMtoPrestaShopCola.btnIrAArticuloClick(Sender: TObject);
var
  sArticulo: string;
begin
  sArticulo := '';
  if Assigned(dsTablaG.DataSet) and dsTablaG.DataSet.Active and
     not dsTablaG.DataSet.IsEmpty then
    sArticulo := dsTablaG.DataSet.FieldByName(
      'CODIGO_ART_PSCOLA').AsString;
  if sArticulo <> '' then
    ShowMto(Self.Owner, 'Articulos', sArticulo);
end;

procedure TfrmMtoPrestaShopCola.btnEnviarYaClick(Sender: TObject);
var
  oDefinicion: TDefinicionColaEnviarYa;
  iMaxIntentos: Integer;
  sUsuario: string;
begin
  oDefinicion := DefinicionColaPrestaShop;
  iMaxIntentos := ParametrosApp.GetInt(oDefinicion.ParametroMaxIntentos,
    oDefinicion.MaxIntentosDefecto);
  sUsuario := IdentidadSesion.Usuario;
  EnviarYaColaDesdeVista(cxGrdDBTabPrin, oDefinicion, 'PrestaShop',
    function(const AIds: TArray<Int64>): Integer
    begin
      Result := EjecutarEnviarYaCola(
        dmmPrestaShopCola.unqryTablaG.Connection, oDefinicion, AIds,
        iMaxIntentos, sUsuario);
    end,
    procedure
    begin
      SolicitarProcesadoPrestaShop;
    end,
    procedure
    begin
      btnActualizarClick(Self);
    end,
    RegistroLog);
end;

function TfrmMtoPrestaShopCola.SqlRestriccionUsuario: string;
var
  bDestinoValido: Boolean;
  iTienda: Integer;
  sClave: string;
  sEmpresaConfigurada: string;
  sEmpresaSesion: string;
  sUrl: string;
begin
  Result := '';
  if (not Assigned(Permisos)) or
     (not Permisos.TienePermiso(CPermisoConsultar, paDenegar)) then
    Result := ' AND 1 = 0'
  else if not IdentidadSesion.EsAdministrador then
  begin
    sUrl := '';
    iTienda := 0;
    sEmpresaConfigurada := '';
    if Assigned(ParametrosApp) then
    begin
      sUrl := Trim(ParametrosApp.GetString('appPrestaShopUrl', ''));
      iTienda := ParametrosApp.GetInt('appPrestaShopIdTienda', 1);
      sEmpresaConfigurada := Trim(ParametrosApp.GetString(
        'appPrestaShopEmpresa', ''));
    end;
    sEmpresaSesion := Trim(ContextoSesion.Ubicacion.Empresa);
    bDestinoValido := (sUrl <> '') and (iTienda > 0);
    if bDestinoValido and (sEmpresaConfigurada <> '') and
       (sEmpresaSesion <> '') then
      bDestinoValido := SameText(
        sEmpresaConfigurada, sEmpresaSesion);
    sClave := '';
    if bDestinoValido then
    begin
      try
        sClave := CalcularClaveInstalacionPresta(sUrl);
      except
        on E: Exception do
          RegistroLog.RegistrarError(
            'Destino PrestaShop no válido para filtrar la cola: ' +
            E.Message);
      end;
    end;
    if sClave = '' then
      Result := ' AND 1 = 0'
    else
      Result := ' AND C.CLAVE_INSTALACION_PSCOLA = ' +
        QuotedStr(sClave) + ' AND C.ID_TIENDA_PSCOLA = ' +
        IntToStr(iTienda);
  end;
end;

procedure TfrmMtoPrestaShopCola.ResetForm;
begin
  inherited;
end;

initialization
  RegistrarPantalla(TfrmMtoPrestaShopCola);
  ForceReferenceToClass(TfrmMtoPrestaShopCola);
end.
