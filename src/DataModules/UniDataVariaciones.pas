{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataVariaciones                                            }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de variaciones de artículos.                                  }
{    Mantenimiento de fza_variaciones, sus atributos, artículos vinculados y   }
{    SKUs generados.                                                           }
{******************************************************************************}
unit UniDataVariaciones;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser, UniDataConn, inLibEjesVariacion;

type
  TdmVariaciones = class(TdmBase)
    unqryArticulosVariacion: TUniQuery;
    dsArticulosVariacion: TDataSource;
    unqryAtributosVariacion: TUniQuery;
    dsAtributosVariacion: TDataSource;
    unqrySkusArticulo: TUniQuery;
    dsSkusArticulo: TDataSource;
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryAtributosVariacionAfterInsert(DataSet: TDataSet);
    procedure unqryAtributosVariacionBeforePost(DataSet: TDataSet);
    procedure PrepararCambioAtributos(DataSet: TDataSet);
    procedure PrepararEdicionAtributo(DataSet: TDataSet);
    procedure PrepararBorradoAtributo(DataSet: TDataSet);
    procedure AtributoConfirmado(DataSet: TDataSet);
    procedure AtributoBorrado(DataSet: TDataSet);
    procedure InvalidarLecturaAtributos(DataSet: TDataSet);
    procedure unqryTablaGAfterCancel(DataSet: TDataSet);
    procedure unqryTablaGAfterPost(DataSet: TDataSet);
    procedure unqryTablaGAfterDelete(DataSet: TDataSet);
  private
    FAtributosAntesDeEditar: TAtributosEjeVariacion;
    FAtributosParaConfirmar: TAtributosEjeVariacion;
    FVariacionAtributos: string;
    FAtributosLeidos: Boolean;
    FIdAtributoAntesDeEditar: string;
    FNuevaCabeceraEnCache: Boolean;
    function LeerOtrosAtributosVariacion(const AVariacion,
      AExcluido: string): TAtributosEjeVariacion;
    function AtributosConFilaEditada(
      ADataSet: TDataSet): TAtributosEjeVariacion;
  public
    // El form empuja su dsTablaG; el DM ya no usa GetOwnerForm.
    procedure AsignarMaestroCabecera(ADataSource: TDataSource); override;
    procedure AbrirDetalles; override;
    function UsaCambiosDiferidos: Boolean; override;
    procedure AplicarCambiosDiferidos; override;
    procedure ConfirmarCambiosDiferidos; override;
    procedure RestaurarCambiosDiferidos; override;
  end;

implementation

uses
  System.Diagnostics, UniDataAperturaConsultas,
  inLibMsgArticulos, inLibMsgConfiguracion, inLibErroresBBDD;

const
  fidvar = 'ID_VAR_VA';
  fidatb = 'ID_ATB_VA';
  fordenva = 'ORDEN_VA';
  fejeva = 'EJE_VA';

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmVariaciones.DataModuleCreate(Sender: TObject);
begin
  inherited;
  // Solo Connection. Los .Open estan en AbrirDetalles y los
  // MasterSource en AsignarMaestroCabecera.
  unqryArticulosVariacion.Connection := ConexionPrincipal;
  unqryAtributosVariacion.Connection := ConexionPrincipal;
  unqrySkusArticulo.Connection := ConexionPrincipal;
end;

// ESCOLOR_BASICO_VAR es NOT NULL: una variación nueva nace sin color
// básico hasta que el usuario marque la casilla (FZ-ISSUE-420).
procedure TdmVariaciones.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  // Solo el alta necesita publicar la clave sin escribir la cabecera.
  FNuevaCabeceraEnCache := True;
  if DataSet.FindField('ESCOLOR_BASICO_VAR') <> nil then
    DataSet.FieldByName('ESCOLOR_BASICO_VAR').AsString := 'N';
  if DataSet.FindField('ESACTIVO_VAR') <> nil then
    DataSet.FieldByName('ESACTIVO_VAR').AsString := 'S';
end;

procedure TdmVariaciones.AsignarMaestroCabecera(ADataSource: TDataSource);
begin
  inherited;
  unqryArticulosVariacion.MasterSource := ADataSource;
  unqryAtributosVariacion.MasterSource := ADataSource;
end;

procedure TdmVariaciones.AbrirDetalles;
const
  TAG = 'Variaciones.AbrirDetalles';
var sw: TStopwatch;
begin
  inherited;
  sw := TStopwatch.StartNew;
  AbrirConsultaConTiempo(
    unqryArticulosVariacion, TAG, 'unqryArticulosVariacion', RegistroLog);
  AbrirConsultaConTiempo(
    unqryAtributosVariacion, TAG, 'unqryAtributosVariacion', RegistroLog);
  AbrirConsultaConTiempo(
    unqrySkusArticulo, TAG, 'unqrySkusArticulo', RegistroLog);
  RegistroLog.RegistrarRendimiento(TAG, 'TOTAL', sw.ElapsedMilliseconds);
end;

procedure TdmVariaciones.unqryAtributosVariacionAfterInsert(DataSet: TDataSet);
begin
  inherited;
  DataSet.FieldByName('ID_VAR_VA').AsString :=
                                  unqryTablaG.FieldByName(
                                    'CODIGO_VAR').AsString;
end;

function TdmVariaciones.LeerOtrosAtributosVariacion(const AVariacion,
  AExcluido: string): TAtributosEjeVariacion;
var
  oAtributo: TAtributoEjeVariacion;
  oLectura: TUniQuery;
begin
  // La definicion se lee fuera del cursor conectado al editor. Los Post
  // y Delete actualizan esta copia tambien antes de grabar en la BBDD.
  if not FAtributosLeidos or
     not SameText(FVariacionAtributos, AVariacion) then
  begin
    FAtributosAntesDeEditar := nil;
    oLectura := TUniQuery.Create(nil);
    try
      oLectura.Connection := unqryAtributosVariacion.Connection;
      oLectura.SQL.Text :=
        'SELECT ID_ATB_VA, ORDEN_VA, EJE_VA ' +
        'FROM fza_variaciones_atributos WHERE ID_VAR_VA = :VARIACION ' +
        'ORDER BY ORDEN_VA, ID_ATB_VA';
      oLectura.ParamByName('VARIACION').AsString := AVariacion;
      oLectura.Open;
      while not oLectura.Eof do
      begin
        oAtributo.Id := oLectura.FieldByName(fidatb).AsString;
        oAtributo.Orden := oLectura.FieldByName(fordenva).AsInteger;
        oAtributo.EjeDeclarado := oLectura.FieldByName(fejeva).AsString;
        FAtributosAntesDeEditar := FAtributosAntesDeEditar + [oAtributo];
        oLectura.Next;
      end;
      FVariacionAtributos := AVariacion;
      FAtributosLeidos := True;
    finally
      oLectura.Free;
    end;
  end;
  Result := nil;
  for oAtributo in FAtributosAntesDeEditar do
    if not SameText(oAtributo.Id, AExcluido) then
      Result := Result + [oAtributo];
end;

// En una edición se excluye el código anterior del atributo, por si el
// usuario lo ha cambiado.
function TdmVariaciones.AtributosConFilaEditada(
  ADataSet: TDataSet): TAtributosEjeVariacion;
var
  oEditado: TAtributoEjeVariacion;
  sExcluido: string;
begin
  sExcluido := '';
  if ADataSet.State = dsEdit then
    sExcluido := FIdAtributoAntesDeEditar;
  Result := LeerOtrosAtributosVariacion(
    ADataSet.FieldByName(fidvar).AsString,
    sExcluido);
  oEditado.Id := ADataSet.FieldByName(fidatb).AsString;
  oEditado.Orden := ADataSet.FieldByName(fordenva).AsInteger;
  oEditado.EjeDeclarado := ADataSet.FieldByName(fejeva).AsString;
  Result := Result + [oEditado];
end;

procedure TdmVariaciones.unqryAtributosVariacionBeforePost(DataSet: TDataSet);
var
  oValidacion: TResultadoValidacionEjes;
begin
  inherited;
  if Trim(DataSet.FieldByName(fidatb).AsString) = '' then
    raise EValidacionBBDD.Create(SErrorCodigoAtributoVariacionObligatorio);
  // La posición definitiva se comprueba al guardar el tipo completo.
  FAtributosParaConfirmar := AtributosConFilaEditada(DataSet);
  oValidacion := ValidarEjesVariacion(FAtributosParaConfirmar, False);
  if oValidacion.Resultado <> vevValido then
    raise EValidacionBBDD.Create(
      MensajeValidacionEjesVariacion(oValidacion));
end;

procedure TdmVariaciones.PrepararCambioAtributos(DataSet: TDataSet);
begin
  if Trim(unqryTablaG.FieldByName('CODIGO_VAR').AsString) = '' then
    raise ECampoObligatorioBBDD.Create('CODIGO_VAR',
      Format(SErrorBBDDCampoObligatorio, ['CODIGO_VAR']));
  // La clave nueva debe ser visible en el maestro/detalle, sin escribirla.
  if unqryTablaG.State = dsInsert then
    unqryTablaG.Post;
  if unqryTablaG.State = dsBrowse then
    unqryTablaG.Edit;
  LeerOtrosAtributosVariacion(
    unqryTablaG.FieldByName('CODIGO_VAR').AsString, '');
end;

procedure TdmVariaciones.PrepararEdicionAtributo(DataSet: TDataSet);
begin
  PrepararCambioAtributos(DataSet);
  FIdAtributoAntesDeEditar := DataSet.FieldByName(fidatb).AsString;
end;

procedure TdmVariaciones.PrepararBorradoAtributo(DataSet: TDataSet);
begin
  PrepararCambioAtributos(DataSet);
  FIdAtributoAntesDeEditar := DataSet.FieldByName(fidatb).AsString;
end;

procedure TdmVariaciones.AtributoConfirmado(DataSet: TDataSet);
begin
  FAtributosAntesDeEditar := Copy(FAtributosParaConfirmar);
end;

procedure TdmVariaciones.AtributoBorrado(DataSet: TDataSet);
var
  aConservados: TAtributosEjeVariacion;
  oAtributo: TAtributoEjeVariacion;
begin
  aConservados := nil;
  for oAtributo in FAtributosAntesDeEditar do
    if not SameText(oAtributo.Id, FIdAtributoAntesDeEditar) then
      aConservados := aConservados + [oAtributo];
  FAtributosAntesDeEditar := aConservados;
end;

procedure TdmVariaciones.InvalidarLecturaAtributos(DataSet: TDataSet);
begin
  if not unqryAtributosVariacion.UpdatesPending then
  begin
    FAtributosLeidos := False;
    FAtributosAntesDeEditar := nil;
    FAtributosParaConfirmar := nil;
  end;
end;

procedure TdmVariaciones.unqryTablaGAfterCancel(DataSet: TDataSet);
begin
  FAtributosLeidos := False;
  FAtributosAntesDeEditar := nil;
  FAtributosParaConfirmar := nil;
  if unqryAtributosVariacion.Active then
  begin
    unqryAtributosVariacion.Cancel;
    unqryAtributosVariacion.CancelUpdates;
  end;
  if unqryTablaG.CachedUpdates then
  begin
    unqryTablaG.CancelUpdates;
    FNuevaCabeceraEnCache := False;
  end;
end;

// Las fichas existentes conservan la escritura de Post y Delete,
// incluida la desactivación desde el navegador. Solo el alta queda en
// caché hasta validar su definición completa al pulsar Grabar.
procedure TdmVariaciones.unqryTablaGAfterPost(DataSet: TDataSet);
begin
  if not FNuevaCabeceraEnCache then
  begin
    unqryTablaG.ApplyUpdates;
    unqryTablaG.CommitUpdates;
  end;
end;

procedure TdmVariaciones.unqryTablaGAfterDelete(DataSet: TDataSet);
begin
  if FNuevaCabeceraEnCache then
    unqryTablaGAfterCancel(DataSet)
  else
    unqryTablaGAfterPost(DataSet);
end;

function TdmVariaciones.UsaCambiosDiferidos: Boolean;
begin
  Result := True;
end;

procedure TdmVariaciones.AplicarCambiosDiferidos;
var
  oValidacion: TResultadoValidacionEjes;
begin
  inherited;
  oValidacion := ValidarEjesVariacion(LeerOtrosAtributosVariacion(
    unqryTablaG.FieldByName('CODIGO_VAR').AsString, ''));
  if oValidacion.Resultado <> vevValido then
    raise EValidacionBBDD.Create(
      MensajeValidacionEjesVariacion(oValidacion));
  if unqryTablaG.UpdatesPending then
    unqryTablaG.ApplyUpdates;
  if unqryAtributosVariacion.UpdatesPending then
    unqryAtributosVariacion.ApplyUpdates;
end;

procedure TdmVariaciones.ConfirmarCambiosDiferidos;
begin
  if unqryTablaG.Active and unqryTablaG.CachedUpdates then
  begin
    unqryTablaG.CommitUpdates;
    FNuevaCabeceraEnCache := False;
  end;
  if unqryAtributosVariacion.Active then
    unqryAtributosVariacion.CommitUpdates;
end;

procedure TdmVariaciones.RestaurarCambiosDiferidos;
begin
  if unqryTablaG.Active and unqryTablaG.CachedUpdates then
    unqryTablaG.RestoreUpdates;
  if unqryAtributosVariacion.Active then
  begin
    unqryAtributosVariacion.RestoreUpdates;
    // La recuperacion generica repone la edicion sin ejecutar BeforeEdit.
    // Conservar su ID evita contar dos veces el atributo restaurado.
    if not unqryAtributosVariacion.IsEmpty then
      FIdAtributoAntesDeEditar :=
        unqryAtributosVariacion.FieldByName(fidatb).AsString;
  end;
end;

initialization
  RegistrarDataModule(TdmVariaciones);
  ForceReferenceToClass(TdmVariaciones);
end.
