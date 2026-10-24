{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataIvasGrupos                                             }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de grupos de IVA.                                             }
{    Mantenimiento de fza_ivas_grupos para la clasificación fiscal por zonas.  }
{******************************************************************************}
unit UniDataIvasGrupos;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, System.Variants, UniDataGen, Data.DB,
  MemDS, DBAccess, Uni, inLibUser, inLibCadenas,
  UniDataValoresAutomaticosRepositorio;

type
  TdmIvasGrupos = class(TdmBase)
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryTablaGAfterDelete(DataSet: TDataSet);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGAfterPost(DataSet: TDataSet);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
  private
    FEncolarPrecioPrestaShop: Boolean;
    function GrupoAfectaPrestaShop(
      AConexion: TUniConnection;
      const AGrupoActual, AGrupoAnterior: string): Boolean;
  public
    procedure GetCodigoAutoIvaGrupo;
  end;

implementation

uses
  inLibMsgComun, UniDataPrestaShopEncolado;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmIvasGrupos.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  unqryTablaG.FindField('IVA_IVAGRP').AsString := '0';
  unqryTablaG.FindField('ESIRPF_IMP_INCL_IVA_IVAGRP').AsString := 'N';
  unqryTablaG.FindField('ESIVAAGRICOLA_IVA_IVAGRP').AsString := 'N';
  unqryTablaG.FindField('ESAPLICA_RE_IVA_IVAGRP').AsString := 'S';
  unqryTablaG.FindField('ESDEFAULT_IVA_IVAGRP').AsString := 'N';
  unqryTablaG.FindField('PALABRA_REPORTS_IVA_IVAGRP').AsString := 'IVA';
end;

procedure TdmIvasGrupos.unqryTablaGAfterDelete(DataSet: TDataSet);
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

procedure TdmIvasGrupos.unqryTablaGAfterPost(DataSet: TDataSet);
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

procedure TdmIvasGrupos.unqryTablaGBeforeDelete(DataSet: TDataSet);
begin
  FEncolarPrecioPrestaShop := GrupoAfectaPrestaShop(
    TUniQuery(DataSet).Connection,
    DataSet.FieldByName('IVA_IVAGRP').AsString,
    '');
end;

function TdmIvasGrupos.GrupoAfectaPrestaShop(
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

procedure TdmIvasGrupos.unqryTablaGBeforePost(DataSet: TDataSet);
var
  sCodigo, sCodigoAnterior, sDescripcion: string;
  unqrySol: TUniQuery;
begin
  inherited;
  FEncolarPrecioPrestaShop := False;
  // Insert vacío (accidental): cancelar sin error
  if (DataSet.State = dsInsert) and
     (Trim(unqryTablaG.FindField('DESCRIPCION_IVA_IVAGRP').AsString) = '') then
    Abort;
  sCodigo := Trim(unqryTablaG.FindField('IVA_IVAGRP').AsString);
  sDescripcion :=
    Trim(unqryTablaG.FindField('DESCRIPCION_IVA_IVAGRP').AsString);
    if (sDescripcion = '') or
       SimbolosProhibidos(sDescripcion, PerfilesLectura) then
      raise ERangeError.CreateFmt(SErrorDescripcionGrupoIva,
                                  [sDescripcion]);
    if (sCodigo = '') or
       SimbolosProhibidos(sCodigo, PerfilesLectura) then
      raise ERangeError.CreateFmt(SErrorCodigoGrupoIva,
                                  [sCodigo]);
    if unqryTablaG.FindField('ESDEFAULT_IVA_IVAGRP').AsString = 'S' then
    begin
      unqrySol := TUniQuery.Create(nil);
      try
        unqrySol.Connection := ConexionPrincipal;
        unqrySol.SQL.Text := 'SELECT ESDEFAULT_IVA_IVAGRP ' +
                             '  FROM vi_ivas_grupos ' +
                             ' WHERE ESDEFAULT_IVA_IVAGRP = ' + QuotedStr('S');
        if (DataSet.State = dsEdit) then
          unqrySol.SQL.Text := unqrySol.SQL.Text +
                               ' AND IVA_IVAGRP <> ' + sCodigo;
        unqrySol.Open;
        if (unqrySol.RecordCount > 0) then
          raise EDataBaseError.Create(SErrorDosGruposIvaPredeterminados);
      finally
        FreeAndNil(unqrySol);
      end;
    end;
  GetCodigoAutoIvaGrupo;
  sCodigoAnterior := '';
  if DataSet.State = dsEdit then
    sCodigoAnterior := VarToStr(
      DataSet.FieldByName('IVA_IVAGRP').OldValue);
  FEncolarPrecioPrestaShop := GrupoAfectaPrestaShop(
    TUniQuery(DataSet).Connection,
    DataSet.FieldByName('IVA_IVAGRP').AsString,
    sCodigoAnterior);
end;

procedure TdmIvasGrupos.DataModuleCreate(Sender: TObject);
begin
  inherited;
end;

procedure TdmIvasGrupos.GetCodigoAutoIvaGrupo;
begin

  if unqryTablaG.FindField('IVA_IVAGRP').AsString = '0' then
  begin
    unqryTablaG.FindField('IVA_IVAGRP').AsString :=
                          ObtenerSiguienteContador(
                                                   ConexionPrincipal,
                                                   'IG',
                                                   IdentidadSesion.Usuario);
  end;
end;

initialization
  RegistrarDataModule(TdmIvasGrupos);
  ForceReferenceToClass(TdmIvasGrupos);
end.
