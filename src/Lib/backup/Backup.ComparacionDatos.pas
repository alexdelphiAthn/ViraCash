{******************************************************************************}
{                                                                              }
{  Módulo:       Backup.ComparacionDatos                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Lee, valida y transforma diferencias de datos sin modificar las BBDD.     }
{******************************************************************************}
unit Backup.ComparacionDatos;

interface

uses
  System.Classes,
  Data.DB,
  Backup.Types,
  Core_Interfaces;

type
  TTextosComparacionDatos = record
    AvisoSinClave: string;
    Sincronizar: string;
    ConIdentidad: string;
    Insertar: string;
    Actualizar: string;
    Eliminar: string;
  end;

  TServiciosComparacionDatos = record
    Origen: ILectorDatosBBDD;
    Destino: ILectorDatosBBDD;
    Writer: IScriptWriter;
    Valores: IGeneradorSqlValores;
    Modificacion: IGeneradorSqlModificacion;
    Textos: TTextosComparacionDatos;
  end;

  TLectorComparacionDatos = class
  private
    FOrigen: ILectorDatosBBDD;
    FDestino: ILectorDatosBBDD;
  public
    constructor Create(
      const AOrigen, ADestino: ILectorDatosBBDD);
    function AbrirOrigen(
      const ATabla: string;
      const AFiltro: string = ''): TDataSet;
    function AbrirDestino(
      const ATabla: string;
      const AFiltro: string = ''): TDataSet;
  end;

  TValidadorComparacionDatos = class
  public
    class procedure AnalizarEstructura(
      ATabla: TTableInfo;
      AClaves: TStrings;
      out ATieneIdentidad: Boolean); static;
    class procedure ValidarClaves(
      ADataSet: TDataSet;
      AClaves: TStrings); static;
  end;

  TTransformadorComparacionDatos = class
  private
    FValores: IGeneradorSqlValores;
    FModificacion: IGeneradorSqlModificacion;
    procedure PoblarCamposValores(
      ADataSet: TDataSet;
      ACampos, AValores: TStrings);
    function CampoRequiereCambio(
      ACampoOrigen: TField;
      ADestino: TDataSet;
      AClaves: TStrings): Boolean;
    procedure AnadirAsignacion(
      var AAsignaciones: string;
      ACampoOrigen: TField);
  public
    constructor Create(
      const AValores: IGeneradorSqlValores;
      const AModificacion: IGeneradorSqlModificacion);
    function CrearFiltroClave(
      AClaves: TStrings;
      ADataSet: TDataSet): string;
    function CrearInsercion(
      const ATabla: string;
      ADataSet: TDataSet;
      ATieneIdentidad: Boolean): string;
    function CrearAsignaciones(
      AOrigen, ADestino: TDataSet;
      AClaves: TStrings): string;
    function CrearActualizacion(
      const ATabla, AAsignaciones, AFiltro: string): string;
    function CrearEliminacion(
      const ATabla, AFiltro: string): string;
  end;

  TComparadorDatosBBDD = class
  private
    FLector: TLectorComparacionDatos;
    FTransformador: TTransformadorComparacionDatos;
    FWriter: IScriptWriter;
    FComprobarCancelacion: TThreadMethod;
    FTextos: TTextosComparacionDatos;
    procedure ComprobarCancelacion;
    procedure EscribirCabecera(
      const ATabla: string;
      ATieneIdentidad: Boolean);
    procedure CompararConClaves(
      const ATabla: string;
      AClaves: TStrings;
      ATieneIdentidad, ANoEliminar: Boolean);
    procedure CompararOrigen(
      const ATabla: string;
      AClaves: TStrings;
      ATieneIdentidad: Boolean);
    procedure CompararRegistroOrigen(
      const ATabla: string;
      AClaves: TStrings;
      AOrigen: TDataSet;
      ATieneIdentidad: Boolean);
    procedure EscribirInsercion(
      const ATabla, AFiltro: string;
      AOrigen: TDataSet;
      ATieneIdentidad: Boolean);
    procedure EscribirActualizacion(
      const ATabla, AFiltro: string;
      AOrigen, ADestino: TDataSet;
      AClaves: TStrings);
    procedure CompararDestino(
      const ATabla: string;
      AClaves: TStrings);
    procedure CompararRegistroDestino(
      const ATabla: string;
      AClaves: TStrings;
      ADestino: TDataSet);
  public
    constructor Create(
      const AServicios: TServiciosComparacionDatos;
      AComprobarCancelacion: TThreadMethod = nil);
    destructor Destroy; override;
    procedure Comparar(
      const ATabla: string;
      AEstructura: TTableInfo;
      ANoEliminar: Boolean);
  end;

implementation

uses
  System.SysUtils;

constructor TLectorComparacionDatos.Create(
  const AOrigen, ADestino: ILectorDatosBBDD);
begin
  inherited Create;
  if not Assigned(AOrigen) then
  begin
    raise EArgumentNilException.Create('AOrigen');
  end;
  if not Assigned(ADestino) then
  begin
    raise EArgumentNilException.Create('ADestino');
  end;
  FOrigen := AOrigen;
  FDestino := ADestino;
end;

function TLectorComparacionDatos.AbrirOrigen(
  const ATabla, AFiltro: string): TDataSet;
begin
  Result := FOrigen.GetData(ATabla, AFiltro);
end;

function TLectorComparacionDatos.AbrirDestino(
  const ATabla, AFiltro: string): TDataSet;
begin
  Result := FDestino.GetData(ATabla, AFiltro);
end;

class procedure TValidadorComparacionDatos.AnalizarEstructura(
  ATabla: TTableInfo;
  AClaves: TStrings;
  out ATieneIdentidad: Boolean);
var
  oColumna: TColumnInfo;
  sExtra: string;
begin
  if not Assigned(ATabla) then
  begin
    raise EArgumentNilException.Create('ATabla');
  end;
  if not Assigned(AClaves) then
  begin
    raise EArgumentNilException.Create('AClaves');
  end;
  AClaves.Clear;
  ATieneIdentidad := False;
  for oColumna in ATabla.Columns do
  begin
    if SameText(oColumna.ColumnKey, 'PRI') then
    begin
      AClaves.Add(oColumna.ColumnName);
    end;
    sExtra := UpperCase(oColumna.Extra);
    if ((Pos('IDENTITY', sExtra) > 0) or
        (Pos('AUTO_INCREMENT', sExtra) > 0)) then
    begin
      ATieneIdentidad := True;
    end;
  end;
end;

class procedure TValidadorComparacionDatos.ValidarClaves(
  ADataSet: TDataSet;
  AClaves: TStrings);
var
  iClave: Integer;
begin
  if not Assigned(ADataSet) then
  begin
    raise EArgumentNilException.Create('ADataSet');
  end;
  for iClave := 0 to AClaves.Count - 1 do
  begin
    ADataSet.FieldByName(AClaves[iClave]);
  end;
end;

constructor TTransformadorComparacionDatos.Create(
  const AValores: IGeneradorSqlValores;
  const AModificacion: IGeneradorSqlModificacion);
begin
  inherited Create;
  if not Assigned(AValores) then
  begin
    raise EArgumentNilException.Create('AValores');
  end;
  if not Assigned(AModificacion) then
  begin
    raise EArgumentNilException.Create('AModificacion');
  end;
  FValores := AValores;
  FModificacion := AModificacion;
end;

procedure TTransformadorComparacionDatos.PoblarCamposValores(
  ADataSet: TDataSet;
  ACampos, AValores: TStrings);
var
  iCampo: Integer;
begin
  ACampos.Clear;
  AValores.Clear;
  for iCampo := 0 to ADataSet.FieldCount - 1 do
  begin
    ACampos.Add(
      FValores.QuoteIdentifier(ADataSet.Fields[iCampo].FieldName));
    AValores.Add(FValores.ValueToSQL(ADataSet.Fields[iCampo]));
  end;
end;

function TTransformadorComparacionDatos.CrearFiltroClave(
  AClaves: TStrings;
  ADataSet: TDataSet): string;
var
  iClave: Integer;
  oCampo: TField;
begin
  Result := '';
  for iClave := 0 to AClaves.Count - 1 do
  begin
    if iClave > 0 then
    begin
      Result := Result + ' AND ';
    end;
    oCampo := ADataSet.FieldByName(AClaves[iClave]);
    Result := Result + FValores.QuoteIdentifier(AClaves[iClave]) +
      ' = ' + FValores.ValueToSQL(oCampo);
  end;
end;

function TTransformadorComparacionDatos.CrearInsercion(
  const ATabla: string;
  ADataSet: TDataSet;
  ATieneIdentidad: Boolean): string;
var
  oCampos: TStringList;
  oValores: TStringList;
begin
  oCampos := TStringList.Create;
  try
    oValores := TStringList.Create;
    try
      PoblarCamposValores(ADataSet, oCampos, oValores);
      Result := FValores.GenerateInsertSQL(
        ATabla,
        oCampos,
        oValores,
        ATieneIdentidad);
    finally
      FreeAndNil(oValores);
    end;
  finally
    FreeAndNil(oCampos);
  end;
end;

function TTransformadorComparacionDatos.CrearAsignaciones(
  AOrigen, ADestino: TDataSet;
  AClaves: TStrings): string;
var
  iCampo: Integer;
  oCampoOrigen: TField;
begin
  Result := '';
  for iCampo := 0 to AOrigen.FieldCount - 1 do
  begin
    oCampoOrigen := AOrigen.Fields[iCampo];
    if CampoRequiereCambio(oCampoOrigen, ADestino, AClaves) then
    begin
      AnadirAsignacion(Result, oCampoOrigen);
    end;
  end;
end;

function TTransformadorComparacionDatos.CampoRequiereCambio(
  ACampoOrigen: TField;
  ADestino: TDataSet;
  AClaves: TStrings): Boolean;
var
  oCampoDestino: TField;
begin
  Result := AClaves.IndexOf(ACampoOrigen.FieldName) < 0;
  if Result then
  begin
    oCampoDestino := ADestino.FindField(ACampoOrigen.FieldName);
    Result := Assigned(oCampoDestino);
    if Result then
    begin
      Result := FValores.ValueToSQL(ACampoOrigen) <>
        FValores.ValueToSQL(oCampoDestino);
    end;
  end;
end;

procedure TTransformadorComparacionDatos.AnadirAsignacion(
  var AAsignaciones: string;
  ACampoOrigen: TField);
begin
  if AAsignaciones <> '' then
  begin
    AAsignaciones := AAsignaciones + ', ';
  end;
  AAsignaciones := AAsignaciones + FValores.QuoteIdentifier(
    ACampoOrigen.FieldName) + ' = ' +
    FValores.ValueToSQL(ACampoOrigen);
end;

function TTransformadorComparacionDatos.CrearActualizacion(
  const ATabla, AAsignaciones, AFiltro: string): string;
begin
  Result := FModificacion.GenerateUpdateSQL(
    ATabla,
    AAsignaciones,
    AFiltro);
end;

function TTransformadorComparacionDatos.CrearEliminacion(
  const ATabla, AFiltro: string): string;
begin
  Result := FModificacion.GenerateDeleteSQL(ATabla, AFiltro);
end;

constructor TComparadorDatosBBDD.Create(
  const AServicios: TServiciosComparacionDatos;
  AComprobarCancelacion: TThreadMethod);
begin
  inherited Create;
  if not Assigned(AServicios.Writer) then
  begin
    raise EArgumentNilException.Create('AServicios.Writer');
  end;
  FLector := TLectorComparacionDatos.Create(
    AServicios.Origen,
    AServicios.Destino);
  try
    FTransformador := TTransformadorComparacionDatos.Create(
      AServicios.Valores,
      AServicios.Modificacion);
  except
    FreeAndNil(FLector);
    raise;
  end;
  FWriter := AServicios.Writer;
  FComprobarCancelacion := AComprobarCancelacion;
  FTextos := AServicios.Textos;
end;

destructor TComparadorDatosBBDD.Destroy;
begin
  FreeAndNil(FTransformador);
  FreeAndNil(FLector);
  inherited Destroy;
end;

procedure TComparadorDatosBBDD.ComprobarCancelacion;
begin
  if Assigned(FComprobarCancelacion) then
  begin
    FComprobarCancelacion;
  end;
end;

procedure TComparadorDatosBBDD.EscribirCabecera(
  const ATabla: string;
  ATieneIdentidad: Boolean);
var
  sIdentidad: string;
begin
  sIdentidad := '';
  if ATieneIdentidad then
  begin
    sIdentidad := FTextos.ConIdentidad;
  end;
  FWriter.AddComment(FTextos.Sincronizar + ATabla + sIdentidad);
end;

procedure TComparadorDatosBBDD.Comparar(
  const ATabla: string;
  AEstructura: TTableInfo;
  ANoEliminar: Boolean);
var
  bTieneIdentidad: Boolean;
  oClaves: TStringList;
begin
  oClaves := TStringList.Create;
  try
    TValidadorComparacionDatos.AnalizarEstructura(
      AEstructura,
      oClaves,
      bTieneIdentidad);
    if oClaves.Count = 0 then
    begin
      FWriter.AddComment(Format(FTextos.AvisoSinClave, [ATabla]));
    end
    else
    begin
      CompararConClaves(
        ATabla,
        oClaves,
        bTieneIdentidad,
        ANoEliminar);
    end;
  finally
    FreeAndNil(oClaves);
  end;
end;

procedure TComparadorDatosBBDD.CompararConClaves(
  const ATabla: string;
  AClaves: TStrings;
  ATieneIdentidad, ANoEliminar: Boolean);
begin
  EscribirCabecera(ATabla, ATieneIdentidad);
  CompararOrigen(ATabla, AClaves, ATieneIdentidad);
  if not ANoEliminar then
  begin
    CompararDestino(ATabla, AClaves);
  end;
end;

procedure TComparadorDatosBBDD.CompararOrigen(
  const ATabla: string;
  AClaves: TStrings;
  ATieneIdentidad: Boolean);
var
  oOrigen: TDataSet;
begin
  oOrigen := FLector.AbrirOrigen(ATabla);
  try
    while not oOrigen.Eof do
    begin
      ComprobarCancelacion;
      TValidadorComparacionDatos.ValidarClaves(oOrigen, AClaves);
      CompararRegistroOrigen(
        ATabla,
        AClaves,
        oOrigen,
        ATieneIdentidad);
      oOrigen.Next;
    end;
  finally
    FreeAndNil(oOrigen);
  end;
end;

procedure TComparadorDatosBBDD.CompararRegistroOrigen(
  const ATabla: string;
  AClaves: TStrings;
  AOrigen: TDataSet;
  ATieneIdentidad: Boolean);
var
  oDestino: TDataSet;
  sFiltro: string;
begin
  sFiltro := FTransformador.CrearFiltroClave(AClaves, AOrigen);
  oDestino := FLector.AbrirDestino(ATabla, sFiltro);
  try
    if oDestino.IsEmpty then
    begin
      EscribirInsercion(ATabla, sFiltro, AOrigen, ATieneIdentidad);
    end
    else
    begin
      EscribirActualizacion(
        ATabla,
        sFiltro,
        AOrigen,
        oDestino,
        AClaves);
    end;
  finally
    FreeAndNil(oDestino);
  end;
end;

procedure TComparadorDatosBBDD.EscribirInsercion(
  const ATabla, AFiltro: string;
  AOrigen: TDataSet;
  ATieneIdentidad: Boolean);
begin
  FWriter.AddComment(Format(FTextos.Insertar, [AFiltro]));
  FWriter.AddCommand(
    FTransformador.CrearInsercion(
      ATabla,
      AOrigen,
      ATieneIdentidad));
end;

procedure TComparadorDatosBBDD.EscribirActualizacion(
  const ATabla, AFiltro: string;
  AOrigen, ADestino: TDataSet;
  AClaves: TStrings);
var
  sAsignaciones: string;
begin
  sAsignaciones := FTransformador.CrearAsignaciones(
    AOrigen,
    ADestino,
    AClaves);
  if sAsignaciones <> '' then
  begin
    FWriter.AddComment(Format(FTextos.Actualizar, [AFiltro]));
    FWriter.AddCommand(
      FTransformador.CrearActualizacion(
        ATabla,
        sAsignaciones,
        AFiltro));
  end;
end;

procedure TComparadorDatosBBDD.CompararDestino(
  const ATabla: string;
  AClaves: TStrings);
var
  oDestino: TDataSet;
begin
  oDestino := FLector.AbrirDestino(ATabla);
  try
    while not oDestino.Eof do
    begin
      ComprobarCancelacion;
      TValidadorComparacionDatos.ValidarClaves(oDestino, AClaves);
      CompararRegistroDestino(ATabla, AClaves, oDestino);
      oDestino.Next;
    end;
  finally
    FreeAndNil(oDestino);
  end;
end;

procedure TComparadorDatosBBDD.CompararRegistroDestino(
  const ATabla: string;
  AClaves: TStrings;
  ADestino: TDataSet);
var
  oOrigen: TDataSet;
  sFiltro: string;
begin
  sFiltro := FTransformador.CrearFiltroClave(AClaves, ADestino);
  oOrigen := FLector.AbrirOrigen(ATabla, sFiltro);
  try
    if oOrigen.IsEmpty then
    begin
      FWriter.AddComment(Format(FTextos.Eliminar, [sFiltro]));
      FWriter.AddCommand(
        FTransformador.CrearEliminacion(ATabla, sFiltro));
    end;
  finally
    FreeAndNil(oOrigen);
  end;
end;

end.
