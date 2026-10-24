{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataIvas                                                   }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de tipos de IVA.                                              }
{    Mantenimiento de fza_ivas y zonas de IVA asociadas.                       }
{******************************************************************************}
unit UniDataIvas;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, System.Variants, UniDataGen, Data.DB,
  MemDS, DBAccess, Uni, inLibUser;

type
  TdmIvas = class(TdmBase)
    unstrdprcContador: TUniStoredProc;
    unqryZonasIVA: TUniQuery;
    dsZonas: TDataSource;
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryTablaGAfterDelete(DataSet: TDataSet);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGAfterPost(DataSet: TDataSet);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
  private
    FEncolarPrecioPrestaShop: Boolean;
    function CampoPrecioPrestaShopCambiado(
      DataSet: TDataSet): Boolean;
    function GrupoIvaAfectaPrestaShop(
      AConexion: TUniConnection;
      const AGrupoActual, AGrupoAnterior: string): Boolean;
    function ExisteGrupoZonaIVA(sCodigoGrupo:String):Boolean;
  public
    procedure GetCodigoAutoIva;
    procedure AbrirDetalles; override;
  end;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses
  inLibCadenas, inLibDatasets, System.Diagnostics,
  inLibMsgComun, UniDataPrestaShopEncolado;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmIvas.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  unqryTablaG.FindField('CODIGO_IVA').AsString := '0';
  unqryTablaG.FindField('IVA_IVAGRP').AsString := '0';
  unqryTablaG.FindField('PORCENTAJE_EXENTO_IVA').AsString := '0';
  unqryTablaG.FindField('PORCENTAJE_EXENTO_RE_IVA').AsString := '0';
  unqryTablaG.FindField('PORCENTAJE_NORMAL_IVA').AsString := '0';
  unqryTablaG.FindField('PORCENTAJE_NORMAL_RE_IVA').AsString := '0';
  unqryTablaG.FindField('PORCENTAJE_REDUCIDO_IVA').AsString := '0';
  unqryTablaG.FindField('PORCENTAJE_REDUCIDO_RE_IVA').AsString := '0';
  unqryTablaG.FindField('PORCENTAJE_SUPERREDUCIDO_IVA').AsString := '0';
  unqryTablaG.FindField('PORCENTAJE_SUPERREDUCIDO_RE_IVA').AsString := '0';
  unqryTablaG.FindField('FECHA_DESDE_IVA').AsDateTime := Now;
end;

procedure TdmIvas.unqryTablaGAfterDelete(DataSet: TDataSet);
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

procedure TdmIvas.unqryTablaGAfterPost(DataSet: TDataSet);
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

procedure TdmIvas.unqryTablaGBeforeDelete(DataSet: TDataSet);
begin
  inherited;
  FEncolarPrecioPrestaShop := False;
  FEncolarPrecioPrestaShop := GrupoIvaAfectaPrestaShop(
    TUniQuery(DataSet).Connection,
    DataSet.FieldByName('IVA_IVAGRP').AsString,
    '');
end;

function TdmIvas.CampoPrecioPrestaShopCambiado(
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
      Cambio('CODIGO_IVA') or
      Cambio('IVA_IVAGRP') or
      Cambio('PORCENTAJE_EXENTO_IVA') or
      Cambio('PORCENTAJE_NORMAL_IVA') or
      Cambio('PORCENTAJE_REDUCIDO_IVA') or
      Cambio('PORCENTAJE_SUPERREDUCIDO_IVA') or
      Cambio('FECHA_DESDE_IVA') or
      Cambio('FECHA_HASTA_IVA');
end;

function TdmIvas.GrupoIvaAfectaPrestaShop(
  AConexion: TUniConnection;
  const AGrupoActual, AGrupoAnterior: string): Boolean;
var
  sGrupoPrestaShop: string;
begin
  sGrupoPrestaShop := LeerGrupoIvaEmpresaPrestaShop(
    AConexion,
    IdentidadSesion.Usuario);
  Result := (sGrupoPrestaShop <> '') and
    (SameText(Trim(AGrupoActual), sGrupoPrestaShop) or
     SameText(Trim(AGrupoAnterior), sGrupoPrestaShop));
end;

procedure TdmIvas.unqryTablaGBeforePost(DataSet: TDataSet);
var
  sGrupoAnterior: string;
  sCodigo :String;
  bError  : Boolean;
  unqrySol: TUniQuery;
begin
  inherited;
  FEncolarPrecioPrestaShop := False;
  // Insert vacío (accidental): cancelar sin error
  if (DataSet.State = dsInsert) and
     (Trim(unqryTablaG.FindField('CODIGO_IVA').AsString) = '') then
    Abort;
  bError := False;
  sCodigo := Trim(unqryTablaG.FindField('CODIGO_IVA').AsString);
  if (sCodigo = '') or
     SimbolosProhibidos(sCodigo, PerfilesLectura) then
  begin
    NotificarError(Format(SErrorCodigoIva, [sCodigo]));
    bError := True;
  end;
  if (unqryTablaG.FindField('IVA_IVAGRP').AsString = '0') or
     not ExisteGrupoZonaIVA(
       unqryTablaG.FindField('IVA_IVAGRP').AsString) then
  begin
    NotificarError(Format(
      SErrorGrupoIvaNoExiste,
      [unqryTablaG.FindField('IVA_IVAGRP').AsString]));
    bError := True;
  end;
  if not bError then
  begin
    if not bError then
    begin
      unqrySol := TUniQuery.Create(nil);
      unqrySol.Connection := ConexionPrincipal;
      unqrySol.SQL.Text := 'SELECT * ' +
        '  FROM vi_ivas ' +
        ' WHERE IVA_IVAGRP = :IVA_IVAGRP' +
        '   AND CODIGO_IVA <> :CODIGO_PROPIO';
      unqrySol.ParamByName('IVA_IVAGRP').AsString :=
        unqryTablaG.FindField('IVA_IVAGRP').AsString;
      // Sin el propio registro: al editar se comparaba consigo mismo
      if DataSet.State = dsEdit then
        unqrySol.ParamByName('CODIGO_PROPIO').AsString :=
          VarToStr(unqryTablaG.FindField('CODIGO_IVA').OldValue)
      else
        unqrySol.ParamByName('CODIGO_PROPIO').AsString := '';
      unqrySol.Open;
    end;
    if not bError and
       not ExistePeriodoUnico(
         unqrySol,
         unqryTablaG.FindField('FECHA_DESDE_IVA'),
         unqryTablaG.FindField('FECHA_HASTA_IVA')) then
    begin
      raise ERangeError.CreateFmt(SErrorRangoFechasIva,
        [unqryTablaG.FindField('DESCRIPCION_IVA_IVAGRP').AsString]);
    end;
    if Assigned(unqrySol) then
    begin
      unqrySol.Close;
      FreeAndNil(unqrySol);
    end;
  end;
  if bError then
    Abort
  else
  begin
    GetCodigoAutoIva;
    sGrupoAnterior := '';
    if DataSet.State = dsEdit then
      sGrupoAnterior := VarToStr(
        DataSet.FieldByName('IVA_IVAGRP').OldValue);
    FEncolarPrecioPrestaShop :=
      CampoPrecioPrestaShopCambiado(DataSet) and
      GrupoIvaAfectaPrestaShop(
        TUniQuery(DataSet).Connection,
        DataSet.FieldByName('IVA_IVAGRP').AsString,
        sGrupoAnterior);
  end;
end;

procedure TdmIvas.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unstrdprcContador.Connection := ConexionPrincipal;
  unqryZonasIVA.Connection := ConexionPrincipal;
  // unqryZonasIVA.Open movido a AbrirDetalles.
end;

procedure TdmIvas.AbrirDetalles;
var
  swQ: TStopwatch;
begin
  inherited;
  if not unqryZonasIVA.Active then
  begin
    swQ := TStopwatch.StartNew;
    try
      unqryZonasIVA.Open;
      RegistroLog.RegistrarRendimiento('Ivas.AbrirDetalles',
        'unqryZonasIVA OK', swQ.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        RegistroLog.RegistrarRendimiento('Ivas.AbrirDetalles',
          'unqryZonasIVA ERROR=' + E.Message,
          swQ.ElapsedMilliseconds);
        raise;
      end;
    end;
  end;
end;

function TdmIvas.ExisteGrupoZonaIVA(sCodigoGrupo: String): Boolean;
var
  unqrySol: TUniQuery;
begin
  unqrySol := TUniQuery.Create(nil);
  unqrySol.Connection := ConexionPrincipal;
  unqrySol.SQL.Text := 'SELECT * ' +
                       '  FROM fza_ivas_grupos ' +
                       ' WHERE IVA_IVAGRP = :IVA_IVAGRP';
  unqrySol.ParamByName('IVA_IVAGRP').AsString := sCodigoGrupo;
  unqrySol.Open;
  if unqrySol.RecordCount = 0 then
    Result := False
  else
    Result := True;
  FreeAndNil(unqrySol);
end;

procedure TdmIvas.GetCodigoAutoIva;
begin
  if unqryTablaG.FindField('CODIGO_IVA').AsString = '0' then
  begin
    unstrdprcContador.Params.Clear;
    unstrdprcContador.Params.CreateParam(ftString, 'ptipodoc', ptInput);
    unstrdprcContador.Params.CreateParam(ftInteger, 'pcont', ptOutput);
    unstrdprcContador.Params.CreateParam(
      ftInteger, 'pUSUARIO_MODIF', ptInput);
    unstrdprcContador.ParamByName('pUSUARIO_MODIF').AsString :=
      IdentidadSesion.Usuario;
    unstrdprcContador.ParamByName('ptipodoc').AsString := 'IV';
    unstrdprcContador.ExecProc;
    unqryTablaG.FindField('CODIGO_IVA').AsString :=
      unstrdprcContador.ParamByName('pcont').AsString;
  end;
end;

initialization
  RegistrarDataModule(TdmIvas);
  ForceReferenceToClass(TdmIvas);
end.
