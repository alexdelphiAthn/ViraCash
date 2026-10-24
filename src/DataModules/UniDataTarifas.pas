{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataTarifas                                                }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de tarifas.                                                   }
{    Mantenimiento de fza_tarifas y consulta de fza_articulos_tarifas          }
{    asociados.                                                                }
{******************************************************************************}
unit UniDataTarifas;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, System.Variants, UniDataGen, Data.DB,
  MemDS, DBAccess, Uni, inLibUser;

type
  TdmTarifas = class(TdmBase)
    unstrdprcContador: TUniStoredProc;
    unqryArticulosTarifas: TUniQuery;
    dsArticulosTarifas: TDataSource;
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGAfterDelete(DataSet: TDataSet);
    procedure unqryTablaGAfterPost(DataSet: TDataSet);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
    procedure unqryArticulosTarifasAfterDelete(DataSet: TDataSet);
    procedure unqryArticulosTarifasAfterPost(DataSet: TDataSet);
    procedure unqryArticulosTarifasBeforeDelete(DataSet: TDataSet);
    procedure unqryArticulosTarifasBeforePost(DataSet: TDataSet);
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
  private
    FArticuloTarifaAnteriorPrestaShop: string;
    FArticuloTarifaBorradoPrestaShop: string;
    FEncolarArticuloTarifaPrestaShop: Boolean;
    FEncolarPrecioPrestaShop: Boolean;
    function CampoPrecioPrestaShopCambiado(
      DataSet: TDataSet): Boolean;
    function EsTarifaPrestaShop(
      AConexion: TUniConnection;
      const ACodigoActual, ACodigoAnterior: string): Boolean;
  public
    procedure GetCodigoAutoFamilia;
    procedure ActualizarDescuentoArticulo(APorcentaje: Double);
    //procedure GetCodigoAutoRetencion;
  end;

implementation

uses
  UniDataPrestaShopEncolado;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmTarifas.ActualizarDescuentoArticulo(APorcentaje: Double);
var
  Consulta: TUniQuery;
begin
  if (APorcentaje < 0) or (APorcentaje > 100) then
    raise EArgumentOutOfRangeException.Create('APorcentaje');
  if not unqryArticulosTarifas.IsEmpty then
  begin
    Consulta := TUniQuery.Create(nil);
    try
      Consulta.Connection := unqryTablaG.Connection;
      Consulta.SQL.Text :=
        'UPDATE fza_articulos_tarifas SET ' +
        'PRECIO_FINAL_ARTTAR = ROUND(' +
        '  PRECIO_SALIDA_ARTTAR * (1 - :PORCENTAJE / 100), 2), ' +
        'PRECIO_DTO_ARTTAR = ' +
        '  PRECIO_SALIDA_ARTTAR - PRECIO_FINAL_ARTTAR, ' +
        'PORCENTAJE_DTO_ARTTAR = :PORCENTAJE, ' +
        'INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO ' +
        'WHERE CODIGO_UNICO_ARTTAR = :ID ' +
        'AND CODIGO_TAR_ARTTAR = :TARIFA AND ESACTIVO_ARTTAR = ''S''';
      Consulta.ParamByName('PORCENTAJE').AsFloat := APorcentaje;
      Consulta.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
      Consulta.ParamByName('ID').AsInteger :=
        unqryArticulosTarifas.FieldByName('CODIGO_UNICO_ARTTAR').AsInteger;
      Consulta.ParamByName('TARIFA').AsString :=
        unqryTablaG.FieldByName('CODIGO_TAR_ARTTAR').AsString;
      Consulta.Execute;
      if (Consulta.RowsAffected > 0) and
         EsTarifaPrestaShop(Consulta.Connection,
           unqryTablaG.FieldByName('CODIGO_TAR_ARTTAR').AsString, '') then
        EncolarPrecioPrestaShop(Consulta.Connection,
          unqryArticulosTarifas.FieldByName('CODIGO_ART_ARTTAR').AsString,
          IdentidadSesion.Usuario);
      unqryArticulosTarifas.Refresh;
    finally
      Consulta.Free;
    end;
  end;
end;

procedure TdmTarifas.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  unqryTablaG.FindField('CODIGO_TAR_ARTTAR').AsString := '0';
end;

procedure TdmTarifas.unqryArticulosTarifasAfterDelete(
  DataSet: TDataSet);
begin
  try
    if FArticuloTarifaBorradoPrestaShop <> '' then
      EncolarPrecioPrestaShop(
        TUniQuery(DataSet).Connection,
        FArticuloTarifaBorradoPrestaShop,
        IdentidadSesion.Usuario);
  finally
    FArticuloTarifaBorradoPrestaShop := '';
  end;
end;

procedure TdmTarifas.unqryArticulosTarifasAfterPost(
  DataSet: TDataSet);
var
  sArticuloActual: string;
begin
  try
    if FEncolarArticuloTarifaPrestaShop then
    begin
      sArticuloActual := Trim(
        DataSet.FieldByName('CODIGO_ART_ARTTAR').AsString);
      EncolarPrecioPrestaShop(
        TUniQuery(DataSet).Connection,
        sArticuloActual,
        IdentidadSesion.Usuario);
      if (FArticuloTarifaAnteriorPrestaShop <> '') and
         (not SameText(
           FArticuloTarifaAnteriorPrestaShop,
           sArticuloActual)) then
        EncolarPrecioPrestaShop(
          TUniQuery(DataSet).Connection,
          FArticuloTarifaAnteriorPrestaShop,
          IdentidadSesion.Usuario);
    end;
  finally
    FArticuloTarifaAnteriorPrestaShop := '';
    FEncolarArticuloTarifaPrestaShop := False;
  end;
end;

procedure TdmTarifas.unqryArticulosTarifasBeforeDelete(
  DataSet: TDataSet);
begin
  FArticuloTarifaBorradoPrestaShop := '';
  if EsTarifaPrestaShop(
    TUniQuery(DataSet).Connection,
    DataSet.FieldByName('CODIGO_TAR_ARTTAR').AsString,
    '') then
    FArticuloTarifaBorradoPrestaShop := Trim(
      DataSet.FieldByName('CODIGO_ART_ARTTAR').AsString);
end;

procedure TdmTarifas.unqryArticulosTarifasBeforePost(
  DataSet: TDataSet);
var
  sTarifaAnterior: string;
begin
  inherited unqryTablaGBeforePost(DataSet);
  GetCodigoAutoFamilia;
  FArticuloTarifaAnteriorPrestaShop := '';
  FEncolarArticuloTarifaPrestaShop := False;
  sTarifaAnterior := '';
  if DataSet.State = dsEdit then
  begin
    FArticuloTarifaAnteriorPrestaShop := Trim(VarToStr(
      DataSet.FieldByName('CODIGO_ART_ARTTAR').OldValue));
    sTarifaAnterior := VarToStr(
      DataSet.FieldByName('CODIGO_TAR_ARTTAR').OldValue);
  end;
  FEncolarArticuloTarifaPrestaShop := EsTarifaPrestaShop(
    TUniQuery(DataSet).Connection,
    DataSet.FieldByName('CODIGO_TAR_ARTTAR').AsString,
    sTarifaAnterior);
end;

procedure TdmTarifas.unqryTablaGAfterDelete(DataSet: TDataSet);
begin
  try
    if FEncolarPrecioPrestaShop then
      EncolarTodosWebPrestaShop(
        TUniQuery(DataSet).Connection,
        True,
        False,
        IdentidadSesion.Usuario);
  finally
    FEncolarPrecioPrestaShop := False;
  end;
end;

procedure TdmTarifas.unqryTablaGAfterPost(DataSet: TDataSet);
begin
  try
    if FEncolarPrecioPrestaShop then
      EncolarTodosWebPrestaShop(
        TUniQuery(DataSet).Connection,
        True,
        False,
        IdentidadSesion.Usuario);
  finally
    FEncolarPrecioPrestaShop := False;
  end;
end;

procedure TdmTarifas.unqryTablaGBeforeDelete(DataSet: TDataSet);
begin
  inherited;
  FEncolarPrecioPrestaShop := EsTarifaPrestaShop(
    TUniQuery(DataSet).Connection,
    DataSet.FieldByName('CODIGO_TAR_ARTTAR').AsString,
    '');
end;

function TdmTarifas.CampoPrecioPrestaShopCambiado(
  DataSet: TDataSet): Boolean;

  function Cambio(const ACampo: string): Boolean;
  begin
    Result := not SameText(
      VarToStr(DataSet.FieldByName(ACampo).OldValue),
      VarToStr(DataSet.FieldByName(ACampo).Value));
  end;

begin
  Result := DataSet.State = dsInsert;
  if DataSet.State = dsEdit then
    Result :=
      Cambio('CODIGO_TAR_ARTTAR') or
      Cambio('ESACTIVO_ARTTAR') or
      Cambio('ESIMP_INCL_TAR') or
      Cambio('FECHA_DESDE_DTO_TAR') or
      Cambio('FECHA_HASTA_DTO_TAR');
end;

function TdmTarifas.EsTarifaPrestaShop(
  AConexion: TUniConnection;
  const ACodigoActual, ACodigoAnterior: string): Boolean;
var
  sTarifa: string;
begin
  sTarifa := LeerCodigoTarifaPrestaShop(
    AConexion,
    IdentidadSesion.Usuario);
  Result := SameText(Trim(ACodigoActual), sTarifa) or
    SameText(Trim(ACodigoAnterior), sTarifa);
end;

procedure TdmTarifas.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unstrdprcContador.Connection := ConexionPrincipal;
  unqryArticulosTarifas.Connection := ConexionPrincipal;
  unqryArticulosTarifas.Open;
end;

procedure TdmTarifas.GetCodigoAutoFamilia;
begin
  if unqryTablaG.FindField('CODIGO_TAR_ARTTAR').AsString = '0' then
  begin
    unstrdprcContador.Params.Clear;
    unstrdprcContador.Params.CreateParam(ftString, 'ptipodoc', ptInput);
    unstrdprcContador.Params.CreateParam(ftInteger, 'pcont', ptOutput);
    unstrdprcContador.Params.CreateParam(
      ftInteger, 'pUSUARIO_MODIF', ptInput);
    unstrdprcContador.ParamByName('pUSUARIO_MODIF').AsString :=
      IdentidadSesion.Usuario;
    unstrdprcContador.ParamByName('ptipodoc').AsString := 'TF';
    unstrdprcContador.ExecProc;
    unqryTablaG.FindField('CODIGO_TAR_ARTTAR').AsString :=
      unstrdprcContador.ParamByName('pcont').AsString;
  end;
end;

procedure TdmTarifas.unqryTablaGBeforePost(DataSet: TDataSet);
var
  sCodigoAnterior: string;
begin
  inherited;
  FEncolarPrecioPrestaShop := False;
  GetCodigoAutoFamilia;
  sCodigoAnterior := '';
  if DataSet.State = dsEdit then
    sCodigoAnterior := VarToStr(
      DataSet.FieldByName('CODIGO_TAR_ARTTAR').OldValue);
  FEncolarPrecioPrestaShop :=
    CampoPrecioPrestaShopCambiado(DataSet) and
    EsTarifaPrestaShop(
      TUniQuery(DataSet).Connection,
      DataSet.FieldByName('CODIGO_TAR_ARTTAR').AsString,
      sCodigoAnterior);
end;

initialization
  RegistrarDataModule(TdmTarifas);
  ForceReferenceToClass(TdmTarifas);
end.
