{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataColoresBasicos                                         }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento del catálogo de colores básicos.                            }
{******************************************************************************}
unit UniDataColoresBasicos;

interface

uses
  System.Classes, Data.DB, Uni, UniDataGen;

type
  TdmColoresBasicos = class(TdmBase)
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryTablaGNewRecord(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
  private
    procedure RechazarColor(const AMensaje: string);
    procedure ValidarColor(DataSet: TDataSet);
  end;

implementation

uses
  System.SysUtils, System.Variants, System.RegularExpressions,
  inLibRegistroPantallas, inLibMsgArticulos,
  UniDataAtributosBasicosUso;

{$R *.dfm}

const
  fid = 'ID_ATB';
  ftipo = 'ID_VA_ATB';
  fcodigo = 'CODIGO_ATB';
  fnombre = 'NOMBRE_ATB';
  fhex = 'HEX_ATB';

procedure TdmColoresBasicos.DataModuleCreate(Sender: TObject);
begin
  inherited;
  ConfigurarBorradoAtributoBasico(unqryTablaG);
end;

procedure TdmColoresBasicos.unqryTablaGNewRecord(DataSet: TDataSet);
begin
  DataSet.FieldByName(ftipo).AsString := 'CO';
  DataSet.FieldByName('ORDEN_ATB').AsInteger := 0;
  DataSet.FieldByName('ESACTIVO_ATB').AsString := 'S';
end;

procedure TdmColoresBasicos.RechazarColor(const AMensaje: string);
begin
  NotificarAdvertencia(AMensaje);
  Abort;
end;

procedure TdmColoresBasicos.ValidarColor(DataSet: TDataSet);
var
  sHex: string;
begin
  if DataSet.FieldByName(ftipo).AsString <> 'CO' then
    RechazarColor(SErrorSoloColoresBasicos);
  if Trim(DataSet.FieldByName(fcodigo).AsString) = '' then
    RechazarColor(SErrorCodigoAtributoBasicoObligatorio);
  if Trim(DataSet.FieldByName(fnombre).AsString) = '' then
    RechazarColor(SErrorNombreAtributoBasicoObligatorio);
  if (DataSet.State = dsEdit) and
     (DataSet.FieldByName(fcodigo).AsString <>
      VarToStr(DataSet.FieldByName(fcodigo).OldValue)) then
    RechazarColor(SErrorCodigoColorBasicoInmutable);
  sHex := UpperCase(Trim(DataSet.FieldByName(fhex).AsString));
  if (sHex <> '') and not TRegEx.IsMatch(sHex, '^#[0-9A-F]{6}$') then
    RechazarColor(SErrorPaletaColorBasicoInvalida);
  DataSet.FieldByName(fhex).AsString := sHex;
  DataSet.FieldByName(fnombre).AsString :=
    Trim(DataSet.FieldByName(fnombre).AsString);
  if DataSet.State = dsInsert then
    DataSet.FieldByName(fcodigo).AsString :=
      Trim(DataSet.FieldByName(fcodigo).AsString);
end;

procedure TdmColoresBasicos.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
  ValidarColor(DataSet);
end;

procedure TdmColoresBasicos.unqryTablaGBeforeDelete(DataSet: TDataSet);
begin
  if AtributoBasicoEnUso(unqryTablaG.Connection,
    DataSet.FieldByName(fid).AsInteger,
    DataSet.FieldByName(ftipo).AsString,
    DataSet.FieldByName(fcodigo).AsString) then
  begin
    NotificarAdvertencia(SErrorColorBasicoEnUso);
    Abort;
  end;
end;

initialization
  RegistrarDataModule(TdmColoresBasicos);

end.
