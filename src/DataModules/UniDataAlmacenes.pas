{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataAlmacenes                                              }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de almacenes.                                                 }
{    Maestro de fza_almacenes y consulta auxiliar de cajas por almacén.        }
{******************************************************************************}
unit UniDataAlmacenes;
interface
uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, System.Variants, UniDataGen, Data.DB,
  MemDS, DBAccess, Uni, inLibUser;
type
  TdmAlmacenes = class(TdmBase)
    qryAlmacenesCajas: TUniQuery;
    dsAlmacenesCajas: TDataSource;
    qryAlmacenesLookup: TUniQuery;
    dsAlmacenesLookup: TDataSource;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure qryAlmacenesCajasBeforeInsert(DataSet: TDataSet);
    procedure unqryTablaGAfterCancel(DataSet: TDataSet);
    procedure unqryTablaGAfterDelete(DataSet: TDataSet);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGAfterPost(DataSet: TDataSet);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
  private
    FAlmacenAnteriorWeb: string;
    FCambioSeleccionWeb: Boolean;
    function TipoUsoAlmacen(ADataSet: TDataSet; const ACodigo: string;
      out ATipoUso: string): Boolean;
    procedure ValidarAlmacenRelacionado(ADataSet: TDataSet;
      const ACampo, AEtiqueta: string; APermitirTransito: Boolean);
    procedure ValidarAlmacenesRelacionados(ADataSet: TDataSet);
    procedure ValidarTransitoCompartido(ADataSet: TDataSet);
    procedure ValidarCajasTransito(ADataSet: TDataSet);
    procedure RefrescarLookupAlmacenes;
  public
    // El form empuja su dsTablaG; el DM ya no usa GetOwnerForm.
    procedure AsignarMaestroCabecera(ADataSource: TDataSource); override;
    // Antes de tocar una caja: exige el código del almacén y pone la
    // cabecera en edición, para que Grabar/Cancelar incluyan la caja.
    procedure PrepararCambioCajas;
    // Operaciones de caja grabadas con la caja del almacén (por empresa,
    // almacén y caja, como el índice IDX_AGRUPACION_OPCAJA).
    function OperacionesDeCaja(const AEmpresa, AAlmacen,
      ACaja: string): Integer;
    function UsaCambiosDiferidos: Boolean; override;
    procedure AplicarCambiosDiferidos; override;
    procedure ConfirmarCambiosDiferidos; override;
    procedure RestaurarCambiosDiferidos; override;
  end;
implementation

uses
  inLibErroresBBDD, inLibMsgConfiguracion,
  UniDataPrestaShopEncolado;

resourcestring
  SAlmacenWebNoValido =
    'Solo un almacén activo, físico y de tipo ESTANDAR puede ' +
    'marcarse En web';
  SAlmacenRelacionadoNoExiste = '%s: el almacén %s no existe';
  SAlmacenRelacionadoPropio = '%s no puede ser el propio almacén';
  SAlmacenRelacionadoTransito =
    '%s no puede ser otro almacén de tránsito';
  SOrigenDestinoSoloTransito =
    'Almacén origen y destino solo se usan en almacenes de tránsito: ' +
    'vacíelos o cambie el tipo de uso';
  SEtiquetaAlmacenOrigen = 'Almacén origen';
  SEtiquetaAlmacenDestino = 'Almacén destino';
  SEtiquetaCodigoPadre = 'Código padre';
  SEtiquetaCodigoAlmacen = 'Código almacén';
  SEtiquetaCodigoCaja = 'Código caja';
  SEtiquetaDescripcionCaja = 'Descripción';
  SCajaEnAlmacenTransito =
    'Un almacén de tránsito no puede tener cajas: solo se usa en ' +
    'traspasos';
  STransitoConCajas =
    'El almacén %s tiene cajas: bórrelas antes de pasarlo a tránsito';

const
  TIPO_USO_TRANSITO = 'TRÁNSITO';
  TIPO_USO_TRANSITO_SIN_TILDE = 'TRANSITO';

{%CLASSGROUP 'Vcl.Controls.TControl'}
{$R *.dfm}
procedure ForceReferenceToClass(C: TClass); begin end;
procedure TdmAlmacenes.DataModuleCreate(Sender: TObject);
begin
  inherited;
  qryAlmacenesCajas.Connection := ConexionPrincipal;
  qryAlmacenesCajas.Open;
  qryAlmacenesLookup.Connection := ConexionPrincipal;
  qryAlmacenesLookup.Open;
end;

function EsTipoUsoTransito(const ATipoUso: string): Boolean;
begin
  Result := SameText(Trim(ATipoUso), TIPO_USO_TRANSITO) or
            SameText(Trim(ATipoUso), TIPO_USO_TRANSITO_SIN_TILDE);
end;

function TdmAlmacenes.TipoUsoAlmacen(ADataSet: TDataSet;
  const ACodigo: string; out ATipoUso: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := TUniQuery(ADataSet).Connection;
    oConsulta.SQL.Text :=
      'SELECT TIPO_USO_ALM FROM fza_almacenes ' +
      ' WHERE CODIGO_ALM_ALM = :CODIGO';
    oConsulta.ParamByName('CODIGO').AsString := ACodigo;
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
    ATipoUso := oConsulta.Fields[0].AsString;
  finally
    oConsulta.Free;
  end;
end;

// Origen, destino y padre son códigos de otro almacén: deben existir y
// no ser el propio (FZ-ISSUE-212). Una furgoneta no carga de otra.
procedure TdmAlmacenes.ValidarAlmacenRelacionado(ADataSet: TDataSet;
  const ACampo, AEtiqueta: string; APermitirTransito: Boolean);
var
  sCodigo: string;
  sTipoUso: string;
begin
  sCodigo := Trim(ADataSet.FieldByName(ACampo).AsString);
  if sCodigo <> '' then
  begin
    if SameText(sCodigo,
         Trim(ADataSet.FieldByName('CODIGO_ALM_ALM').AsString)) then
      raise EValidacionBBDD.CreateFmt(SAlmacenRelacionadoPropio,
        [AEtiqueta]);
    if not TipoUsoAlmacen(ADataSet, sCodigo, sTipoUso) then
      raise EValidacionBBDD.CreateFmt(SAlmacenRelacionadoNoExiste,
        [AEtiqueta, sCodigo]);
    if (not APermitirTransito) and EsTipoUsoTransito(sTipoUso) then
      raise EValidacionBBDD.CreateFmt(SAlmacenRelacionadoTransito,
        [AEtiqueta]);
  end;
end;

procedure TdmAlmacenes.ValidarAlmacenesRelacionados(ADataSet: TDataSet);
var
  bConOrigenDestino: Boolean;
begin
  bConOrigenDestino :=
    (Trim(ADataSet.FieldByName('ORIGEN_ACTUAL_ALM').AsString) <> '') or
    (Trim(ADataSet.FieldByName('DESTINO_ACTUAL_ALM').AsString) <> '');
  if bConOrigenDestino and
     (not EsTipoUsoTransito(
       ADataSet.FieldByName('TIPO_USO_ALM').AsString)) then
    raise EValidacionBBDD.Create(SOrigenDestinoSoloTransito);
  ValidarAlmacenRelacionado(ADataSet, 'ORIGEN_ACTUAL_ALM',
    SEtiquetaAlmacenOrigen, False);
  ValidarAlmacenRelacionado(ADataSet, 'DESTINO_ACTUAL_ALM',
    SEtiquetaAlmacenDestino, False);
  ValidarAlmacenRelacionado(ADataSet, 'CODIGO_PADRE_ALM',
    SEtiquetaCodigoPadre, True);
end;

// FZ-ISSUE-717: solo una furgoneta o agencia lleva cargas de varias
// empresas; en una tienda la marca no significaría nada.
procedure TdmAlmacenes.ValidarTransitoCompartido(ADataSet: TDataSet);
begin
  if SameText(ADataSet.FieldByName('ESCOMPARTIDO_ALM').AsString, 'S') and
     (not EsTipoUsoTransito(
       ADataSet.FieldByName('TIPO_USO_ALM').AsString)) then
    raise EValidacionBBDD.Create(SErrorCompartidoSoloTransito);
end;

// FZ-ISSUE-240: la furgoneta no es una tienda, no vende ni tiene cajas.
procedure TdmAlmacenes.ValidarCajasTransito(ADataSet: TDataSet);
var
  oConsulta: TUniQuery;
  sAlmacen: string;
begin
  if ADataSet = qryAlmacenesCajas then
  begin
    if EsTipoUsoTransito(
         unqryTablaG.FieldByName('TIPO_USO_ALM').AsString) then
      raise EValidacionBBDD.Create(SCajaEnAlmacenTransito);
  end
  else
  begin
    sAlmacen := Trim(VarToStr(
      ADataSet.FieldByName('CODIGO_ALM_ALM').OldValue));
    // Solo al pasarlo a tránsito: uno que ya lo era con cajas antiguas se
    // sigue pudiendo editar, y el selector de caja ya no las ofrece.
    if (ADataSet.State = dsEdit) and (sAlmacen <> '') and
       EsTipoUsoTransito(ADataSet.FieldByName('TIPO_USO_ALM').AsString) and
       not EsTipoUsoTransito(VarToStr(
         ADataSet.FieldByName('TIPO_USO_ALM').OldValue)) then
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := TUniQuery(ADataSet).Connection;
        oConsulta.SQL.Text :=
          'SELECT 1 FROM fza_almacenes_cajas ' +
          ' WHERE CODIGO_ALM_ALMCAJ = :CODIGO LIMIT 1';
        oConsulta.ParamByName('CODIGO').AsString := sAlmacen;
        oConsulta.Open;
        if not oConsulta.IsEmpty then
          raise EValidacionBBDD.CreateFmt(STransitoConCajas, [sAlmacen]);
      finally
        oConsulta.Free;
      end;
    end;
  end;
end;

// Un almacén nuevo, renombrado o borrado debe verse en los combos.
procedure TdmAlmacenes.RefrescarLookupAlmacenes;
begin
  if qryAlmacenesLookup.Active then
    qryAlmacenesLookup.Refresh;
end;

procedure ValorPorDefecto(ADataSet: TDataSet; const ACampo: string;
  const AValor: Variant);
var
  Campo: TField;
begin
  Campo := ADataSet.FindField(ACampo);
  if Assigned(Campo) and
     (Trim(Campo.AsString) = '') then
    Campo.Value := AValor;
end;

// Campo obligatorio vacío: aviso de validación que lo nombra, con el
// cursor en su control o en su celda (FZ-ISSUE-623).
procedure ExigirCampo(ADataSet: TDataSet; const ACampo, AEtiqueta: string);
var
  Campo: TField;
begin
  Campo := ADataSet.FieldByName(ACampo);
  if Trim(Campo.AsString) = '' then
  begin
    Campo.FocusControl;
    raise ECampoObligatorioBBDD.Create(ACampo,
      Format(SErrorBBDDCampoObligatorio, [AEtiqueta]));
  end;
end;

procedure TdmAlmacenes.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  // El SQLInsert envía todos los parámetros, incluidos los NULL, así que
  // el DEFAULT de la columna no actúa: los valores por defecto se ponen
  // aquí, coherentes con lo que pintan las casillas (FZ-ISSUE-213).
  if Assigned(DataSet) then
  begin
    ValorPorDefecto(DataSet, 'ESACTIVO_ALM', 'S');
    ValorPorDefecto(DataSet, 'ESFISICO_ALM', 'S');
    ValorPorDefecto(DataSet, 'ESWEB_ALM', 'N');
    ValorPorDefecto(DataSet, 'TIPO_USO_ALM', 'ESTANDAR');
    ValorPorDefecto(DataSet, 'ESCOMPARTIDO_ALM', 'N');
    ValorPorDefecto(DataSet, 'ORDEN_ALM', 0);
  end;
end;

procedure TdmAlmacenes.unqryTablaGBeforeDelete(DataSet: TDataSet);
begin
  inherited;
  FAlmacenAnteriorWeb := Trim(
    DataSet.FieldByName('CODIGO_ALM_ALM').AsString);
end;

procedure TdmAlmacenes.unqryTablaGAfterDelete(DataSet: TDataSet);
begin
  EncolarStockAlmacenPrestaShop(
    TUniQuery(DataSet).Connection,
    FAlmacenAnteriorWeb,
    IdentidadSesion.Usuario);
  FAlmacenAnteriorWeb := '';
  RefrescarLookupAlmacenes;
end;

procedure TdmAlmacenes.unqryTablaGBeforePost(DataSet: TDataSet);
var
  bAlmacenWebValido: Boolean;
  sValorAnterior: string;
begin
  if DataSet = qryAlmacenesCajas then
  begin
    ExigirCampo(DataSet, 'CODIGO_CAJA_ALMCAJ', SEtiquetaCodigoCaja);
    ExigirCampo(DataSet, 'DESCRIPCION_ALMCAJ', SEtiquetaDescripcionCaja);
  end;
  inherited;
  if DataSet = unqryTablaG then
    ExigirCampo(DataSet, 'CODIGO_ALM_ALM', SEtiquetaCodigoAlmacen);
  ValidarCajasTransito(DataSet);
  // qryAlmacenesCajas comparte este evento: lo demás es solo del almacén
  if DataSet <> unqryTablaG then
    Exit;
  FAlmacenAnteriorWeb := '';
  FCambioSeleccionWeb := DataSet.State = dsInsert;
  if DataSet.State = dsEdit then
  begin
    FAlmacenAnteriorWeb := DataSet.FieldByName(
      'CODIGO_ALM_ALM').OldValue;
    sValorAnterior := VarToStr(DataSet.FieldByName(
      'ESWEB_ALM').OldValue);
    FCambioSeleccionWeb :=
      not SameText(sValorAnterior,
        DataSet.FieldByName('ESWEB_ALM').AsString) or
      not SameText(VarToStr(DataSet.FieldByName(
        'ESACTIVO_ALM').OldValue),
        DataSet.FieldByName('ESACTIVO_ALM').AsString) or
      not SameText(VarToStr(DataSet.FieldByName(
        'ESFISICO_ALM').OldValue),
        DataSet.FieldByName('ESFISICO_ALM').AsString) or
      not SameText(Trim(VarToStr(DataSet.FieldByName(
        'TIPO_USO_ALM').OldValue)),
        Trim(DataSet.FieldByName('TIPO_USO_ALM').AsString)) or
      not SameText(VarToStr(DataSet.FieldByName(
        'CODIGO_EMP_ALM').OldValue),
        DataSet.FieldByName('CODIGO_EMP_ALM').AsString) or
      not SameText(FAlmacenAnteriorWeb,
        DataSet.FieldByName('CODIGO_ALM_ALM').AsString);
  end;
  bAlmacenWebValido :=
    SameText(DataSet.FieldByName('ESACTIVO_ALM').AsString, 'S') and
    SameText(DataSet.FieldByName('ESFISICO_ALM').AsString, 'S') and
    SameText(Trim(DataSet.FieldByName('TIPO_USO_ALM').AsString),
      'ESTANDAR');
  if SameText(DataSet.FieldByName('ESWEB_ALM').AsString, 'S') and
     (not bAlmacenWebValido) then
    raise EValidacionBBDD.Create(SAlmacenWebNoValido);
  ValidarAlmacenesRelacionados(DataSet);
  ValidarTransitoCompartido(DataSet);
end;

procedure TdmAlmacenes.unqryTablaGAfterPost(DataSet: TDataSet);
var
  sAlmacenActual: string;
begin
  if FCambioSeleccionWeb then
  begin
    sAlmacenActual := DataSet.FieldByName('CODIGO_ALM_ALM').AsString;
    EncolarStockAlmacenPrestaShop(
      TUniQuery(DataSet).Connection,
      sAlmacenActual,
      IdentidadSesion.Usuario);
    if (FAlmacenAnteriorWeb <> '') and
       (not SameText(FAlmacenAnteriorWeb, sAlmacenActual)) then
      EncolarStockAlmacenPrestaShop(
        TUniQuery(DataSet).Connection,
        FAlmacenAnteriorWeb,
        IdentidadSesion.Usuario);
  end;
  FAlmacenAnteriorWeb := '';
  FCambioSeleccionWeb := False;
  RefrescarLookupAlmacenes;
end;

procedure TdmAlmacenes.qryAlmacenesCajasBeforeInsert(DataSet: TDataSet);
begin
  PrepararCambioCajas;
end;

// La cabecera mantiene el estado pendiente hasta Grabar o Cancelar.
// No publicar aqui un almacen nuevo: Cancelar tambien debe descartarlo.
// Editar la cabecera refresca el detalle: se hace antes de que la caja
// entre en edición (FZ-ISSUE-624) y se vuelve a la caja en curso para no
// editar ni borrar otra.
procedure TdmAlmacenes.PrepararCambioCajas;
var
  Marca: TBookmark;
begin
  ExigirCampo(unqryTablaG, 'CODIGO_ALM_ALM', SEtiquetaCodigoAlmacen);
  if unqryTablaG.State = dsBrowse then
  begin
    Marca := nil;
    if qryAlmacenesCajas.Active and not qryAlmacenesCajas.IsEmpty then
      Marca := qryAlmacenesCajas.Bookmark;
    unqryTablaG.Edit;
    if (Length(Marca) > 0) and qryAlmacenesCajas.BookmarkValid(Marca) and
       (qryAlmacenesCajas.CompareBookmarks(Marca,
          qryAlmacenesCajas.Bookmark) <> 0) then
      qryAlmacenesCajas.Bookmark := Marca;
  end;
end;

procedure TdmAlmacenes.unqryTablaGAfterCancel(DataSet: TDataSet);
begin
  if qryAlmacenesCajas.Active then
  begin
    qryAlmacenesCajas.Cancel;
    qryAlmacenesCajas.CancelUpdates;
  end;
end;

function TdmAlmacenes.UsaCambiosDiferidos: Boolean;
begin
  Result := True;
end;

procedure TdmAlmacenes.AplicarCambiosDiferidos;
begin
  if qryAlmacenesCajas.Active and qryAlmacenesCajas.UpdatesPending then
    qryAlmacenesCajas.ApplyUpdates;
end;

procedure TdmAlmacenes.ConfirmarCambiosDiferidos;
begin
  if qryAlmacenesCajas.Active then
    qryAlmacenesCajas.CommitUpdates;
end;

procedure TdmAlmacenes.RestaurarCambiosDiferidos;
begin
  if qryAlmacenesCajas.Active then
    qryAlmacenesCajas.RestoreUpdates;
end;

function TdmAlmacenes.OperacionesDeCaja(const AEmpresa, AAlmacen,
  ACaja: string): Integer;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := qryAlmacenesCajas.Connection;
    oConsulta.SQL.Text :=
      'SELECT COUNT(*) AS OPERACIONES FROM fza_caja_operaciones ' +
      ' WHERE CODIGO_EMP_OPCAJA = :EMPRESA ' +
      '   AND CODIGO_ALM_OPCAJA = :ALMACEN ' +
      '   AND CODIGO_CAJA_OPCAJA = :CAJA';
    oConsulta.ParamByName('EMPRESA').AsString := AEmpresa;
    oConsulta.ParamByName('ALMACEN').AsString := AAlmacen;
    oConsulta.ParamByName('CAJA').AsString := ACaja;
    oConsulta.Open;
    Result := oConsulta.FieldByName('OPERACIONES').AsInteger;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TdmAlmacenes.AsignarMaestroCabecera(ADataSource: TDataSource);
begin
  inherited;
  qryAlmacenesCajas.MasterSource := ADataSource;
end;


procedure TdmAlmacenes.DataModuleDestroy(Sender: TObject);
begin
  qryAlmacenesCajas.Close;
  qryAlmacenesLookup.Close;
  inherited;
end;

initialization
  RegistrarDataModule(TdmAlmacenes);
  ForceReferenceToClass(TdmAlmacenes);
end.
