{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataTraspasoSolicitudesHist                                }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       10/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Histórico global de solicitudes de traspaso, sus líneas y los             }
{    traspasos de almacén generados al atenderlas.                             }
{******************************************************************************}
unit UniDataTraspasoSolicitudesHist;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, System.Variants,
  Data.DB, MemDS, DBAccess, Uni,
  UniDataGen, UniDataConn;

type
  TdmTraspasoSolicitudesHist = class(TdmBase)
    unqryLineas: TUniQuery;
    dsLineas: TDataSource;
    unqryTraspasos: TUniQuery;
    dsTraspasos: TDataSource;
    unqryMovimientos: TUniQuery;
    dsMovimientos: TDataSource;
    procedure unqryTablaGAfterOpen(DataSet: TDataSet);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
    procedure unqryTablaGBeforeEdit(DataSet: TDataSet);
    procedure unqryTablaGBeforeInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
  private
    FControlesDetallesDesactivados: Boolean;
    FPuedeModificar: Boolean;
    function CampoEditable(const ANombreCampo: string): Boolean;
    function CampoAuditoria(const ANombreCampo: string): Boolean;
    procedure ConfigurarCamposEdicion;
    procedure ExigirEdicionAutorizada;
    procedure ValidarCambiosPermitidos(ADataSet: TDataSet);
  protected
    procedure DoCreate; override;
  public
    procedure AbrirDetalles; override;
    procedure AsignarMaestroCabecera(ADataSource: TDataSource); override;
    procedure ConfigurarEdicion(APuedeModificar: Boolean);
    procedure ReactivarControlesTrasAbrir; override;
  end;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

resourcestring
  SErrorEdicionSolicitudTraspasoNoAutorizada =
    'Solo un administrador puede modificar una solicitud del histórico.';
  SErrorAltaSolicitudTraspasoNoPermitida =
    'El histórico no permite crear solicitudes de traspaso.';
  SErrorBorradoSolicitudTraspasoNoPermitido =
    'El histórico no permite eliminar solicitudes de traspaso.';
  SErrorCampoSolicitudTraspasoNoEditable =
    'El campo %s no se puede modificar desde el histórico.';

procedure TdmTraspasoSolicitudesHist.AbrirDetalles;
begin
  inherited;
  unqryLineas.DisableControls;
  unqryTraspasos.DisableControls;
  unqryMovimientos.DisableControls;
  FControlesDetallesDesactivados := True;
  try
    if not unqryLineas.Active then
      unqryLineas.Open;
    if not unqryTraspasos.Active then
      unqryTraspasos.Open;
    if not unqryMovimientos.Active then
      unqryMovimientos.Open;
  except
    unqryMovimientos.EnableControls;
    unqryTraspasos.EnableControls;
    unqryLineas.EnableControls;
    FControlesDetallesDesactivados := False;
    raise;
  end;
end;

procedure TdmTraspasoSolicitudesHist.AsignarMaestroCabecera(
  ADataSource: TDataSource);
begin
  inherited;
  unqryLineas.MasterSource := ADataSource;
  unqryTraspasos.MasterSource := ADataSource;
  unqryMovimientos.MasterSource := dsTraspasos;
end;

function TdmTraspasoSolicitudesHist.CampoEditable(
  const ANombreCampo: string): Boolean;
begin
  Result := SameText(ANombreCampo, 'CODIGO_EMPLEADO_TRSOL') or
    SameText(ANombreCampo, 'OBSERVACIONES_TRSOL');
end;

function TdmTraspasoSolicitudesHist.CampoAuditoria(
  const ANombreCampo: string): Boolean;
begin
  Result := SameText(ANombreCampo, 'INSTANTE_MODIF') or
    SameText(ANombreCampo, 'USUARIO_MODIF');
end;

procedure TdmTraspasoSolicitudesHist.ConfigurarCamposEdicion;
var
  Campo: TField;
  Indice: Integer;
begin
  for Indice := 0 to unqryTablaG.FieldCount - 1 do
  begin
    Campo := unqryTablaG.Fields[Indice];
    Campo.ReadOnly := not (
      FPuedeModificar and CampoEditable(Campo.FieldName));
  end;
end;

procedure TdmTraspasoSolicitudesHist.ConfigurarEdicion(
  APuedeModificar: Boolean);
begin
  FPuedeModificar := APuedeModificar and
    IdentidadSesion.EsAdministrador;
  unqryTablaG.ReadOnly := not FPuedeModificar;
  if unqryTablaG.Active then
    ConfigurarCamposEdicion;
end;

procedure TdmTraspasoSolicitudesHist.DoCreate;
begin
  inherited;
  FControlesDetallesDesactivados := False;
  FPuedeModificar := False;
  unqryTablaG.ReadOnly := True;
end;

procedure TdmTraspasoSolicitudesHist.ReactivarControlesTrasAbrir;
begin
  inherited;
  if FControlesDetallesDesactivados then
  begin
    unqryMovimientos.EnableControls;
    unqryTraspasos.EnableControls;
    unqryLineas.EnableControls;
    FControlesDetallesDesactivados := False;
  end;
end;

procedure TdmTraspasoSolicitudesHist.ExigirEdicionAutorizada;
begin
  if (not FPuedeModificar) or
     (not IdentidadSesion.EsAdministrador) then
    raise EDatabaseError.Create(
      SErrorEdicionSolicitudTraspasoNoAutorizada);
end;

procedure TdmTraspasoSolicitudesHist.unqryTablaGAfterOpen(
  DataSet: TDataSet);
begin
  ConfigurarCamposEdicion;
end;

procedure TdmTraspasoSolicitudesHist.unqryTablaGBeforeDelete(
  DataSet: TDataSet);
begin
  raise EDatabaseError.Create(
    SErrorBorradoSolicitudTraspasoNoPermitido);
end;

procedure TdmTraspasoSolicitudesHist.unqryTablaGBeforeEdit(
  DataSet: TDataSet);
begin
  ExigirEdicionAutorizada;
end;

procedure TdmTraspasoSolicitudesHist.unqryTablaGBeforeInsert(
  DataSet: TDataSet);
begin
  raise EDatabaseError.Create(
    SErrorAltaSolicitudTraspasoNoPermitida);
end;

procedure TdmTraspasoSolicitudesHist.unqryTablaGBeforePost(
  DataSet: TDataSet);
const
  NombresCamposBase: array[0..4] of string = (
    'CODIGO_EMP_TRSOL',
    'CODIGO_ALM_ORIGEN_TRSOL',
    'CODIGO_EMP_CONTRA_TRSOL',
    'CODIGO_ALM_DESTINO_TRSOL',
    'USUARIO_MODIF');
var
  CamposBase: array[0..4] of TField;
  ValoresDominio: array[0..3] of Variant;
  SoloLectura: array[0..4] of Boolean;
  Indice: Integer;
begin
  ExigirEdicionAutorizada;
  if DataSet.State <> dsEdit then
    raise EDatabaseError.Create(
      SErrorAltaSolicitudTraspasoNoPermitida);
  ValidarCambiosPermitidos(DataSet);
  for Indice := Low(CamposBase) to High(CamposBase) do
  begin
    CamposBase[Indice] := DataSet.FindField(NombresCamposBase[Indice]);
    SoloLectura[Indice] := Assigned(CamposBase[Indice]) and
      CamposBase[Indice].ReadOnly;
    if Assigned(CamposBase[Indice]) then
    begin
      if Indice <= High(ValoresDominio) then
        ValoresDominio[Indice] := CamposBase[Indice].Value;
      CamposBase[Indice].ReadOnly := False;
    end;
  end;
  try
    inherited unqryTablaGBeforePost(DataSet);
  finally
    for Indice := Low(ValoresDominio) to High(ValoresDominio) do
      if Assigned(CamposBase[Indice]) then
        CamposBase[Indice].Value := ValoresDominio[Indice];
    for Indice := Low(CamposBase) to High(CamposBase) do
      if Assigned(CamposBase[Indice]) then
        CamposBase[Indice].ReadOnly := SoloLectura[Indice];
  end;
end;

procedure TdmTraspasoSolicitudesHist.ValidarCambiosPermitidos(
  ADataSet: TDataSet);
var
  Campo: TField;
  Indice: Integer;
begin
  for Indice := 0 to ADataSet.FieldCount - 1 do
  begin
    Campo := ADataSet.Fields[Indice];
    if (Campo.FieldKind = fkData) and
       (not CampoEditable(Campo.FieldName)) and
       (not CampoAuditoria(Campo.FieldName)) and
       (VarToStr(Campo.OldValue) <> VarToStr(Campo.Value)) then
      raise EDatabaseError.CreateFmt(
        SErrorCampoSolicitudTraspasoNoEditable,
        [Campo.FieldName]);
  end;
end;

initialization
  RegistrarDataModule(TdmTraspasoSolicitudesHist);

end.
