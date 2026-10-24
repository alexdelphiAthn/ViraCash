{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataAtributosBasicos                                       }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       14/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module del catálogo de atributos básicos (fza_atributos_basicos).    }
{    Provee la query principal y un lookup de variaciones/atributos para que   }
{    al alta el usuario elija de un combo el ID_VA_ATB (CO, TAL, TEMP…).       }
{******************************************************************************}
unit UniDataAtributosBasicos;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser;

type
  TdmAtributosBasicos = class(TdmBase)
    unqryAtributosLookup: TUniQuery;
    dsAtributosLookup: TDataSource;
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure AbrirDetalles; override;
  end;

implementation

uses
  System.Diagnostics, inLibMsgArticulos, UniDataAtributosBasicosUso;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmAtributosBasicos.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryAtributosLookup.Connection := ConexionPrincipal;
  ConfigurarBorradoAtributoBasico(unqryTablaG);
  unqryTablaG.BeforeDelete := unqryTablaGBeforeDelete;
  // unqryAtributosLookup.Open movido a AbrirDetalles.
end;

procedure TdmAtributosBasicos.AbrirDetalles;
var
  swQ: TStopwatch;
begin
  inherited;
  if not unqryAtributosLookup.Active then
  begin
    swQ := TStopwatch.StartNew;
    try
      unqryAtributosLookup.Open;
      RegistroLog.RegistrarRendimiento('AtributosBasicos.AbrirDetalles',
        'unqryAtributosLookup OK', swQ.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        RegistroLog.RegistrarRendimiento('AtributosBasicos.AbrirDetalles',
          'unqryAtributosLookup ERROR=' + E.Message,
          swQ.ElapsedMilliseconds);
        raise;
      end;
    end;
  end;
end;

procedure TdmAtributosBasicos.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
  // Insert vacío (accidental): cancelar sin error
  if (DataSet.State = dsInsert) and
     (Trim(DataSet.FieldByName('NOMBRE_ATB').AsString) = '') then
    Abort;
  if Trim(DataSet.FieldByName('ID_VA_ATB').AsString) = '' then
    raise Exception.Create(SErrorAtributoBasicoObligatorio);
  if Trim(DataSet.FieldByName('CODIGO_ATB').AsString) = '' then
    raise Exception.Create(SErrorCodigoAtributoBasicoObligatorio);
  if Trim(DataSet.FieldByName('NOMBRE_ATB').AsString) = '' then
    raise Exception.Create(SErrorNombreAtributoBasicoObligatorio);
  ActualizarAuditoria(DataSet);
end;

procedure TdmAtributosBasicos.unqryTablaGBeforeDelete(DataSet: TDataSet);
begin
  if AtributoBasicoEnUso(unqryTablaG.Connection,
    DataSet.FieldByName('ID_ATB').AsInteger,
    DataSet.FieldByName('ID_VA_ATB').AsString,
    DataSet.FieldByName('CODIGO_ATB').AsString) then
  begin
    NotificarAdvertencia(SErrorAtributoBasicoEnUso);
    Abort;
  end;
end;

initialization
  RegistrarDataModule(TdmAtributosBasicos);
  ForceReferenceToClass(TdmAtributosBasicos);
end.
