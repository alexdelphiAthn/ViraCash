{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataUnidadesMedida                                         }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de unidades de medida.                                        }
{    Mantenimiento de fza_unidades_medida: decimales por unidad y conversión   }
{    a la unidad estándar de cada magnitud (cm/mm->m, g->kg...).               }
{******************************************************************************}
unit UniDataUnidadesMedida;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser, UniDataConn;

type
  TdmUnidadesMedida = class(TdmBase)
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGAfterPost(DataSet: TDataSet);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

uses
  inLibUnidadesMedida;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmUnidadesMedida.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  // Valores por defecto: evitan violar NOT NULL al insertar desde la rejilla
  // y dejan la unidad lista para que el usuario solo teclee codigo/descripcion.
  unqryTablaG.FindField('DECIMALES_UNIMED').AsInteger := 2;
  unqryTablaG.FindField('MAGNITUD_UNIMED').AsString := 'OTROS';
  unqryTablaG.FindField('ESBASE_UNIMED').AsString := 'N';
  unqryTablaG.FindField('FACTOR_BASE_UNIMED').AsFloat := 1;
  unqryTablaG.FindField('ORDEN_UNIMED').AsInteger := 0;
  unqryTablaG.FindField('ESACTIVO_UNIMED').AsString := 'S';
end;

procedure TdmUnidadesMedida.unqryTablaGAfterPost(DataSet: TDataSet);
begin
  inherited;
  // Tras alta/modificacion refrescamos la cache para que los nuevos decimales
  // se apliquen en documentos e informes sin reiniciar el programa.
  if Assigned(UnidadesMedida) then
    UnidadesMedida.Cargar;
end;

initialization
  RegistrarDataModule(TdmUnidadesMedida);
  ForceReferenceToClass(TdmUnidadesMedida);
end.
