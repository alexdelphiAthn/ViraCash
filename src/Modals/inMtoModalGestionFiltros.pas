{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalGestionFiltros                                      }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.1.1                                                         }
{   Fecha:       11/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Lista los filtros guardados disponibles para el usuario actual en un      }
{    mantenimiento (propios y compartidos con él), y permite aplicar,          }
{    editar, reemplazar, copiar, borrar y compartir sus condiciones.           }
{    Compartir con un usuario concreto o con el propio grupo está abierto a    }
{    cualquier propietario; compartir con otro grupo distinto o con Todos      }
{    los usuarios requiere pertenecer al grupo administrador                   }
{    (`ContextoSesion.Identidad.EsAdministrador`).                             }
{******************************************************************************}
unit inMtoModalGestionFiltros;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls,
  inMtoFrmBase, cxClasses, cxContainer, cxEdit, cxLookAndFeels,
  cxLocalization, cxGraphics, cxControls, cxLookAndFeelPainters, cxLabel,
  cxTextEdit, cxButtons, cxListBox, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxNavigator, cxDBData, cxGridLevel,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid,
  cxGridCustomView, cxFilterControl, Data.DB, Datasnap.DBClient,
  inLibFiltrosGuardadosIntf, inLibDestinosFiltrosPersistenciaIntf;

type
  TGestionFiltrosResult = record
    Aplicado: Boolean;
    IdFiltro: Int64;
    FiltroBase64: string;
  end;

  TfrmModalGestionFiltros = class(TfrmBase)
    cxgrdFiltros: TcxGrid;
    tvFiltros: TcxGridDBTableView;
    lvlFiltros: TcxGridLevel;
    tvFiltrosNOMBRE_FILT: TcxGridDBColumn;
    tvFiltrosDESCRIPCION_FILT: TcxGridDBColumn;
    tvFiltrosUSUARIO_PROPIETARIO_FILT: TcxGridDBColumn;
    lblCompartidoCon: TcxLabel;
    lbCompartidoCon: TcxListBox;
    btnAplicar: TcxButton;
    btnRenombrar: TcxButton;
    btnBorrar: TcxButton;
    btnCompartirUsuario: TcxButton;
    btnCompartirGrupo: TcxButton;
    btnCompartirTodos: TcxButton;
    btnQuitarCompartido: TcxButton;
    btnCerrar: TcxButton;
    lblCondiciones: TcxLabel;
    pnlEditorFiltro: TPanel;
    btnGuardarCambios: TcxButton;
    btnReemplazarActual: TcxButton;
    btnGuardarCopia: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure tvFiltrosFocusedRecordChanged(
      Sender: TcxCustomGridTableView;
      APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
      ANewItemRecordFocusingChanged: Boolean);
    procedure tvFiltrosDblClick(Sender: TObject);
    procedure btnAplicarClick(Sender: TObject);
    procedure btnRenombrarClick(Sender: TObject);
    procedure btnBorrarClick(Sender: TObject);
    procedure btnCompartirUsuarioClick(Sender: TObject);
    procedure btnCompartirGrupoClick(Sender: TObject);
    procedure btnCompartirTodosClick(Sender: TObject);
    procedure btnQuitarCompartidoClick(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
    procedure btnGuardarCambiosClick(Sender: TObject);
    procedure btnReemplazarActualClick(Sender: TObject);
    procedure btnGuardarCopiaClick(Sender: TObject);
  private
    FMto: string;
    FVista: string;
    FResultado: TGestionFiltrosResult;
    FDestinos: TDestinosCompartidosList;
    FVistaComponente: TcxCustomGridTableView;
    FFiltroActualBase64: string;
    FControlFiltro: TcxFilterControl;
    FListadoFiltros: TClientDataSet;
    FDataSourceFiltros: TDataSource;
    FRepositorioDestinos: IRepositorioDestinosFiltros;
    function IdFiltroSeleccionado: Int64;
    function GuardarFiltroEditorBase64: string;
    function ResumirFiltro(const ABase64: string): string;
    procedure CrearEditorFiltro;
    procedure CrearListadoFiltros;
    procedure CargarFiltroEnControl(AControl: TcxFilterControl;
                                    const ABase64: string);
    procedure CargarFiltroEnEditor(const ABase64: string);
    procedure CargarFiltroSeleccionado;
    procedure RefrescarBotones;
    procedure RefrescarCompartidoCon;
  public
    procedure CargarDatos;
    class function Ejecutar(AOwner: TComponent;
                            const AMto, AVista: string;
                            AVistaComponente: TcxCustomGridTableView;
                            const AFiltroActualBase64: string
                            ): TGestionFiltrosResult; overload;
    class function Ejecutar(
      AOwner: TComponent;
      const AMto, AVista: string;
      AVistaComponente: TcxCustomGridTableView;
      const AFiltroActualBase64: string;
      const ARepositorio: IRepositorioDestinosFiltros
    ): TGestionFiltrosResult; overload;
  end;

implementation

{$R *.dfm}

uses
  inLibMensajesVcl,
  System.NetEncoding, inLibContextoSesionIntf, inLibGenBusq,
  inMtoModalGuardarFiltro, inLibMsgComun,
  UniDataConfiguracionPantalla;

resourcestring
  SInfoFiltroSinCondiciones = '(sin condiciones)';
  SNombreCopiaFiltro = '%s - copia';
  STituloCompartirFiltroUsuario = 'Compartir filtro con usuario';
  STituloCompartirFiltroGrupo = 'Compartir filtro con grupo';
  SInfoFiltroTodosUsuarios = 'Todos los usuarios';
  SInfoFiltroGrupo = 'Grupo: %s';
  SInfoFiltroUsuario = 'Usuario: %s';

type
  TcxFilterControlAcceso = class(TcxFilterControl)
  public
    function CopiarFiltro(ADestino: TcxFilterCriteria): Boolean;
  end;

procedure ForceReferenceToClass(C: TClass);
begin
end;

function TcxFilterControlAcceso.CopiarFiltro(
  ADestino: TcxFilterCriteria): Boolean;
begin
  ValueEditorHide(True);
  Result := IsValid;
  if Result then
  begin
    BuildFromRows;
    ADestino.AssignItems(Criteria);
  end;
end;

class function TfrmModalGestionFiltros.Ejecutar(AOwner: TComponent;
  const AMto, AVista: string;
  AVistaComponente: TcxCustomGridTableView;
  const AFiltroActualBase64: string): TGestionFiltrosResult;
begin
  Result := Default(TGestionFiltrosResult);
  ValidarDependenciaConfiguracion(
    nil,
    'destinos de filtros');
end;

class function TfrmModalGestionFiltros.Ejecutar(
  AOwner: TComponent;
  const AMto, AVista: string;
  AVistaComponente: TcxCustomGridTableView;
  const AFiltroActualBase64: string;
  const ARepositorio: IRepositorioDestinosFiltros
): TGestionFiltrosResult;
var
  frm: TfrmModalGestionFiltros;
begin
  ValidarDependenciaConfiguracion(
    ARepositorio,
    'destinos de filtros');
  frm := TfrmModalGestionFiltros.Create(AOwner);
  try
    frm.FMto := AMto;
    frm.FVista := AVista;
    frm.FVistaComponente := AVistaComponente;
    frm.FFiltroActualBase64 := AFiltroActualBase64;
    frm.FRepositorioDestinos := ARepositorio;
    frm.CargarDatos;
    frm.ShowModal;
    Result := frm.FResultado;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalGestionFiltros.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
  FResultado.Aplicado := False;
  FResultado.IdFiltro := 0;
  FResultado.FiltroBase64 := '';
  FDestinos := nil;
  FVistaComponente := nil;
  FFiltroActualBase64 := '';
  CrearListadoFiltros;
  CrearEditorFiltro;
end;

procedure TfrmModalGestionFiltros.FormDestroy(Sender: TObject);
begin
  inherited;
  if Assigned(FDestinos) then
  begin
    FreeAndNil(FDestinos);
  end;
  tvFiltros.DataController.DataSource := nil;
  FreeAndNil(FDataSourceFiltros);
  FreeAndNil(FListadoFiltros);
  FreeAndNil(FControlFiltro);
end;

procedure TfrmModalGestionFiltros.CrearEditorFiltro;
begin
  FControlFiltro := TcxFilterControl.Create(Self);
  FControlFiltro.Parent := pnlEditorFiltro;
  FControlFiltro.Align := alClient;
  FControlFiltro.ParentFont := True;
  FControlFiltro.Enabled := False;
end;

procedure TfrmModalGestionFiltros.CrearListadoFiltros;
begin
  FListadoFiltros := TClientDataSet.Create(Self);
  FListadoFiltros.FieldDefs.Add('ID_FILT', ftLargeint);
  FListadoFiltros.FieldDefs.Add('NOMBRE_FILT', ftString, 150);
  FListadoFiltros.FieldDefs.Add('DESCRIPCION_FILT', ftString, 500);
  FListadoFiltros.FieldDefs.Add(
    'USUARIO_PROPIETARIO_FILT',
    ftString,
    100);
  FListadoFiltros.FieldDefs.Add('ESPROPIO_FILT', ftString, 1);
  FListadoFiltros.CreateDataSet;
  FDataSourceFiltros := TDataSource.Create(Self);
  FDataSourceFiltros.DataSet := FListadoFiltros;
  tvFiltros.DataController.DataSource := FDataSourceFiltros;
end;

procedure TfrmModalGestionFiltros.CargarDatos;
var
  Filtros: TFiltrosGuardadosList;
  Info: TFiltroGuardadoInfo;
begin
  FControlFiltro.LinkComponent := FVistaComponente;
  FListadoFiltros.DisableControls;
  try
    FListadoFiltros.EmptyDataSet;
    if Assigned(FiltrosLectura) then
    begin
      Filtros := FiltrosLectura.ListarFiltros(FMto, FVista);
      try
        for Info in Filtros do
        begin
          FListadoFiltros.Append;
          FListadoFiltros.FieldByName('ID_FILT').AsLargeInt := Info.Id;
          FListadoFiltros.FieldByName('NOMBRE_FILT').AsString :=
            Info.Nombre;
          FListadoFiltros.FieldByName('DESCRIPCION_FILT').AsString :=
            Info.Descripcion;
          FListadoFiltros.FieldByName(
            'USUARIO_PROPIETARIO_FILT').AsString := Info.Propietario;
          if Info.EsPropio then
            FListadoFiltros.FieldByName('ESPROPIO_FILT').AsString := 'S'
          else
            FListadoFiltros.FieldByName('ESPROPIO_FILT').AsString := 'N';
          FListadoFiltros.Post;
        end;
      finally
        FreeAndNil(Filtros);
      end;
    end;
    if not FListadoFiltros.IsEmpty then
      FListadoFiltros.First;
  finally
    FListadoFiltros.EnableControls;
  end;
  CargarFiltroSeleccionado;
  RefrescarCompartidoCon;
end;

function TfrmModalGestionFiltros.IdFiltroSeleccionado: Int64;
begin
  Result := 0;
  if Assigned(FiltrosLectura) and
     FListadoFiltros.Active and
     (not FListadoFiltros.IsEmpty) then
  begin
    Result := FListadoFiltros.FieldByName('ID_FILT').AsLargeInt;
  end;
end;

procedure TfrmModalGestionFiltros.CargarFiltroEnControl(
  AControl: TcxFilterControl; const ABase64: string);
var
  oStreamBin: TMemoryStream;
  oStreamB64: TStringStream;
  oStreamOriginal: TMemoryStream;
begin
  if ABase64 = '' then
  begin
    AControl.Clear;
  end
  else
  begin
    oStreamB64 := TStringStream.Create(ABase64);
    oStreamBin := TMemoryStream.Create;
    oStreamOriginal := TMemoryStream.Create;
    try
      FVistaComponente.DataController.Filter.SaveToStream(
                                                    oStreamOriginal);
      oStreamB64.Position := 0;
      TNetEncoding.Base64.Decode(oStreamB64, oStreamBin);
      oStreamBin.Position := 0;
      FVistaComponente.BeginUpdate;
      try
        try
          FVistaComponente.DataController.Filter.LoadFromStream(
                                                        oStreamBin);
          AControl.UpdateFilter;
        finally
          oStreamOriginal.Position := 0;
          FVistaComponente.DataController.Filter.LoadFromStream(
                                                   oStreamOriginal);
        end;
      finally
        FVistaComponente.EndUpdate;
      end;
    finally
      FreeAndNil(oStreamOriginal);
      FreeAndNil(oStreamBin);
      FreeAndNil(oStreamB64);
    end;
  end;
end;

procedure TfrmModalGestionFiltros.CargarFiltroEnEditor(
  const ABase64: string);
begin
  CargarFiltroEnControl(FControlFiltro, ABase64);
end;

procedure TfrmModalGestionFiltros.CargarFiltroSeleccionado;
var
  sFiltroBase64: string;
begin
  sFiltroBase64 := '';
  if IdFiltroSeleccionado > 0 then
  begin
    sFiltroBase64 :=
      FiltrosLectura.CargarFiltroBase64(IdFiltroSeleccionado);
  end;
  CargarFiltroEnEditor(sFiltroBase64);
end;

function TfrmModalGestionFiltros.GuardarFiltroEditorBase64: string;
var
  oStreamBin: TMemoryStream;
  oStreamB64: TStringStream;
  oStreamOriginal: TMemoryStream;
begin
  Result := '';
  oStreamBin := TMemoryStream.Create;
  oStreamB64 := TStringStream.Create('');
  oStreamOriginal := TMemoryStream.Create;
  try
    FVistaComponente.DataController.Filter.SaveToStream(oStreamOriginal);
    FVistaComponente.BeginUpdate;
    try
      try
        if TcxFilterControlAcceso(FControlFiltro).CopiarFiltro(
                    FVistaComponente.DataController.Filter) then
        begin
          FVistaComponente.DataController.Filter.Active :=
            not FVistaComponente.DataController.Filter.IsEmpty;
          FVistaComponente.DataController.Filter.SaveToStream(oStreamBin);
        end;
      finally
        oStreamOriginal.Position := 0;
        FVistaComponente.DataController.Filter.LoadFromStream(
                                                 oStreamOriginal);
      end;
    finally
      FVistaComponente.EndUpdate;
    end;
    if oStreamBin.Size > 0 then
    begin
      oStreamBin.Position := 0;
      TNetEncoding.Base64.Encode(oStreamBin, oStreamB64);
      Result := oStreamB64.DataString;
    end;
  finally
    FreeAndNil(oStreamOriginal);
    FreeAndNil(oStreamB64);
    FreeAndNil(oStreamBin);
  end;
end;

function TfrmModalGestionFiltros.ResumirFiltro(
  const ABase64: string): string;
const
  MAX_CARACTERES_RESUMEN = 600;
var
  oControl: TcxFilterControl;
begin
  Result := SInfoFiltroSinCondiciones;
  if ABase64 <> '' then
  begin
    oControl := TcxFilterControl.Create(nil);
    try
      oControl.LinkComponent := FVistaComponente;
      CargarFiltroEnControl(oControl, ABase64);
      Result := Trim(oControl.FilterCaption);
      if Result = '' then
      begin
        Result := SInfoFiltroSinCondiciones;
      end
      else if Length(Result) > MAX_CARACTERES_RESUMEN then
      begin
        Result := Copy(Result, 1, MAX_CARACTERES_RESUMEN) + '...';
      end;
    finally
      FreeAndNil(oControl);
    end;
  end;
end;

procedure TfrmModalGestionFiltros.RefrescarBotones;
var
  bHayFiltro: Boolean;
  bEsPropio: Boolean;
begin
  bHayFiltro := Assigned(FiltrosLectura) and
                FListadoFiltros.Active and
                (not FListadoFiltros.IsEmpty);
  bEsPropio := False;
  if bHayFiltro then
  begin
    bEsPropio :=
      FListadoFiltros.FieldByName('ESPROPIO_FILT').AsString = 'S';
  end;
  btnAplicar.Enabled := bHayFiltro;
  btnGuardarCambios.Enabled := bHayFiltro and bEsPropio;
  btnReemplazarActual.Enabled := bHayFiltro and bEsPropio and
                                 (FFiltroActualBase64 <> '');
  btnGuardarCopia.Enabled := bHayFiltro;
  btnRenombrar.Enabled := bHayFiltro and bEsPropio;
  btnBorrar.Enabled := bHayFiltro and bEsPropio;
  btnCompartirUsuario.Enabled := bHayFiltro and bEsPropio;
  btnCompartirGrupo.Enabled := bHayFiltro and bEsPropio;
  btnCompartirTodos.Enabled := bHayFiltro and bEsPropio and
                               ContextoSesion.Identidad.EsAdministrador;
  btnQuitarCompartido.Enabled := bHayFiltro and bEsPropio and
                                 (lbCompartidoCon.ItemIndex >= 0);
  FControlFiltro.Enabled := bHayFiltro;
  if bHayFiltro and (not bEsPropio) then
  begin
    lblCondiciones.Caption := SCaptionCondicionesFiltroCompartido;
  end
  else
  begin
    lblCondiciones.Caption := SCaptionCondicionesFiltroSeleccionado;
  end;
end;

procedure TfrmModalGestionFiltros.RefrescarCompartidoCon;
var
  info: TDestinoCompartidoInfo;
  sLinea: string;
begin
  if Assigned(FDestinos) then
  begin
    FreeAndNil(FDestinos);
  end;
  lbCompartidoCon.Items.Clear;
  if IdFiltroSeleccionado > 0 then
  begin
    FDestinos := FiltrosComparticion.ListarDestinosCompartidos(
      IdFiltroSeleccionado);
    for info in FDestinos do
    begin
      if info.TipoDestino = 'TODOS' then
      begin
        sLinea := SInfoFiltroTodosUsuarios;
      end
      else if info.TipoDestino = 'GRUPO' then
      begin
        sLinea := Format(SInfoFiltroGrupo, [info.UsuarioGrupo]);
      end
      else
      begin
        sLinea := Format(SInfoFiltroUsuario, [info.UsuarioGrupo]);
      end;
      lbCompartidoCon.Items.Add(sLinea);
    end;
  end;
  RefrescarBotones;
end;

procedure TfrmModalGestionFiltros.tvFiltrosFocusedRecordChanged(
  Sender: TcxCustomGridTableView;
  APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  CargarFiltroSeleccionado;
  RefrescarCompartidoCon;
end;

procedure TfrmModalGestionFiltros.tvFiltrosDblClick(Sender: TObject);
begin
  btnAplicarClick(Sender);
end;

procedure TfrmModalGestionFiltros.btnAplicarClick(Sender: TObject);
var
  sFiltroBase64: string;
begin
  inherited;
  if IdFiltroSeleccionado = 0 then
  begin
    ShowMessage_fza(SErrorFiltroNoSeleccionado);
  end
  else
  begin
    sFiltroBase64 := GuardarFiltroEditorBase64;
    if (sFiltroBase64 = '') or
       (Trim(FControlFiltro.FilterCaption) = '') then
    begin
      ShowMessage_fza(SErrorFiltroSinCondicionesAplicar);
    end
    else
    begin
      FResultado.Aplicado := True;
      FResultado.IdFiltro := IdFiltroSeleccionado;
      FResultado.FiltroBase64 := sFiltroBase64;
      Close;
    end;
  end;
end;

procedure TfrmModalGestionFiltros.btnGuardarCambiosClick(Sender: TObject);
var
  sFiltroBase64: string;
  sNombre: string;
  sDescripcion: string;
begin
  inherited;
  sFiltroBase64 := GuardarFiltroEditorBase64;
  if (sFiltroBase64 = '') or
     (Trim(FControlFiltro.FilterCaption) = '') then
  begin
    ShowMessage_fza(SErrorFiltroSinCondicionesGuardar);
  end
  else
  begin
    sNombre := FListadoFiltros.FieldByName('NOMBRE_FILT').AsString;
    sDescripcion := FListadoFiltros.FieldByName(
      'DESCRIPCION_FILT').AsString;
    FiltrosEscritura.SobrescribirFiltro(
      IdFiltroSeleccionado,
      sNombre,
      sDescripcion,
      sFiltroBase64);
    CargarFiltroEnEditor(sFiltroBase64);
    ShowMessage_fza(SInfoCambiosFiltroGuardados);
  end;
end;

procedure TfrmModalGestionFiltros.btnReemplazarActualClick(
  Sender: TObject);
var
  sFiltroGuardado: string;
  sMensaje: string;
  sNombre: string;
  sDescripcion: string;
begin
  inherited;
  if FFiltroActualBase64 = '' then
  begin
    ShowMessage_fza(SErrorPantallaSinFiltroAplicado);
  end
  else
  begin
    sFiltroGuardado :=
      FiltrosLectura.CargarFiltroBase64(IdFiltroSeleccionado);
    sMensaje := Format(SPreguntaReemplazarFiltro,
      [ResumirFiltro(sFiltroGuardado),
       ResumirFiltro(FFiltroActualBase64)]);
    if MessageBox_fza(PChar(sMensaje), PChar(STituloReemplazarFiltro),
       MB_YESNO + MB_ICONQUESTION) = ID_YES then
    begin
      sNombre := FListadoFiltros.FieldByName('NOMBRE_FILT').AsString;
      sDescripcion := FListadoFiltros.FieldByName(
        'DESCRIPCION_FILT').AsString;
      FiltrosEscritura.SobrescribirFiltro(
        IdFiltroSeleccionado,
        sNombre,
        sDescripcion,
        FFiltroActualBase64);
      CargarFiltroEnEditor(FFiltroActualBase64);
      ShowMessage_fza(SInfoFiltroReemplazado);
    end;
  end;
end;

procedure TfrmModalGestionFiltros.btnGuardarCopiaClick(Sender: TObject);
var
  res: TGuardarFiltroResult;
  sFiltroBase64: string;
  sNombreInicial: string;
  sDescripcionInicial: string;
  iIdFiltro: Int64;
begin
  inherited;
  sFiltroBase64 := GuardarFiltroEditorBase64;
  if (sFiltroBase64 = '') or
     (Trim(FControlFiltro.FilterCaption) = '') then
  begin
    ShowMessage_fza(SErrorFiltroSinCondicionesGuardar);
  end
  else
  begin
    sNombreInicial := Format(SNombreCopiaFiltro,
      [FListadoFiltros.FieldByName('NOMBRE_FILT').AsString]);
    sDescripcionInicial := FListadoFiltros.FieldByName(
      'DESCRIPCION_FILT').AsString;
    res := TfrmModalGuardarFiltro.Ejecutar(Self, sNombreInicial,
                                           sDescripcionInicial);
    if res.Aceptado then
    begin
      iIdFiltro := FiltrosLectura.BuscarFiltroPropio(
        FMto,
        FVista,
        res.Nombre);
      if iIdFiltro > 0 then
      begin
        ShowMessage_fza(SErrorFiltroPropioDuplicado);
      end
      else
      begin
        FiltrosEscritura.GuardarFiltroNuevo(
          FMto,
          FVista,
          res.Nombre,
          res.Descripcion,
          sFiltroBase64);
        CargarDatos;
        ShowMessage_fza(SInfoCopiaFiltroGuardada);
      end;
    end;
  end;
end;

procedure TfrmModalGestionFiltros.btnRenombrarClick(Sender: TObject);
var
  res: TGuardarFiltroResult;
begin
  inherited;
  if IdFiltroSeleccionado = 0 then
  begin
    ShowMessage_fza(SErrorFiltroNoSeleccionado);
  end
  else
  begin
    res := TfrmModalGuardarFiltro.Ejecutar(Self,
      FListadoFiltros.FieldByName('NOMBRE_FILT').AsString,
      FListadoFiltros.FieldByName('DESCRIPCION_FILT').AsString);
    if res.Aceptado then
    begin
      FiltrosEscritura.RenombrarFiltro(
        IdFiltroSeleccionado,
        res.Nombre,
        res.Descripcion);
      CargarDatos;
    end;
  end;
end;

procedure TfrmModalGestionFiltros.btnBorrarClick(Sender: TObject);
begin
  inherited;
  if IdFiltroSeleccionado = 0 then
  begin
    ShowMessage_fza(SErrorFiltroNoSeleccionado);
  end
  else
  begin
    if MessageBox_fza(PChar(SPreguntaBorrarFiltro),
                              PChar(STituloConfirmarBorradoFiltro),
                              MB_YESNO + MB_ICONQUESTION) = ID_YES then
    begin
      FiltrosEscritura.BorrarFiltro(IdFiltroSeleccionado);
      CargarDatos;
    end;
  end;
end;

procedure TfrmModalGestionFiltros.btnCompartirUsuarioClick(Sender: TObject);
var
  oResultado: IResultadoDestinosFiltros;
  sUsuario: string;
  IdentidadActual: TIdentidadSesion;
begin
  inherited;
  IdentidadActual := ContextoSesion.Identidad;
  oResultado := FRepositorioDestinos.ConsultarUsuarios(
    IdentidadActual.Usuario);
  if BusquedaVisual.EjecutarBusquedaDataSet(
    STituloCompartirFiltroUsuario,
    oResultado.DataSet,
    'frmBuscarUsuarioFiltro',
    Self) then
  begin
    sUsuario := oResultado.DataSet.FieldByName('USUARIO').AsString;
    FiltrosComparticion.CompartirConDestino(
      IdFiltroSeleccionado,
      'USUARIO',
      sUsuario);
    RefrescarCompartidoCon;
  end;
end;

procedure TfrmModalGestionFiltros.btnCompartirGrupoClick(Sender: TObject);
var
  oResultado: IResultadoDestinosFiltros;
  sGrupo: string;
  IdentidadActual: TIdentidadSesion;
begin
  inherited;
  IdentidadActual := ContextoSesion.Identidad;
  if IdentidadActual.EsAdministrador then
  begin
    oResultado := FRepositorioDestinos.ConsultarGrupos;
    if BusquedaVisual.EjecutarBusquedaDataSet(
      STituloCompartirFiltroGrupo,
      oResultado.DataSet,
      'frmBuscarGrupoFiltro',
      Self) then
    begin
      sGrupo := oResultado.DataSet.FieldByName('GRUPO').AsString;
      FiltrosComparticion.CompartirConDestino(
        IdFiltroSeleccionado,
        'GRUPO',
        sGrupo);
      RefrescarCompartidoCon;
    end;
  end
  else
  begin
    FiltrosComparticion.CompartirConDestino(
      IdFiltroSeleccionado,
      'GRUPO',
      IdentidadActual.Grupo);
    RefrescarCompartidoCon;
    ShowMessage_fza(Format(SInfoFiltroCompartidoGrupo,
                       [IdentidadActual.Grupo]));
  end;
end;

procedure TfrmModalGestionFiltros.btnCompartirTodosClick(Sender: TObject);
begin
  inherited;
  FiltrosComparticion.CompartirConDestino(
    IdFiltroSeleccionado,
    'TODOS',
    '');
  RefrescarCompartidoCon;
  ShowMessage_fza(SInfoFiltroCompartidoTodos);
end;

procedure TfrmModalGestionFiltros.btnQuitarCompartidoClick(Sender: TObject);
begin
  inherited;
  if (lbCompartidoCon.ItemIndex >= 0) and Assigned(FDestinos) then
  begin
    FiltrosComparticion.QuitarDestinoCompartido(
      FDestinos[lbCompartidoCon.ItemIndex].Id);
    RefrescarCompartidoCon;
  end;
end;

procedure TfrmModalGestionFiltros.btnCerrarClick(Sender: TObject);
begin
  inherited;
  FResultado.Aplicado := False;
  FResultado.FiltroBase64 := '';
  Close;
end;

initialization
  ForceReferenceToClass(TfrmModalGestionFiltros);
end.
