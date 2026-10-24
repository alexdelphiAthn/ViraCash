{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataEmpleados                                              }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de empleados (operarios de caja, traspasos y arqueos).        }
{    Mantenimiento de fza_empleados. Independiente de fza_usuarios.            }
{******************************************************************************}
unit UniDataEmpleados;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  UniDataConn;

type
  TdmEmpleados = class(TdmBase)
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

uses
  inLibErroresBBDD, inLibMsgConfiguracion;

resourcestring
  SEtiquetaCodigoEmpleado = 'Código empleado';

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmEmpleados.unqryTablaGAfterInsert(DataSet: TDataSet);
var
  fld: TField;
begin
  inherited;
  // Empleado nuevo activo por defecto: caja, traspasos y arqueos listan solo
  // empleados con ESACTIVO_EMPL = 'S'.
  fld := unqryTablaG.FindField('ESACTIVO_EMPL');
  if (fld <> nil) then
    fld.AsString := 'S';
end;

// Sin código: aviso que nombra el campo, y la pantalla le da el foco
// (FZ-ISSUE-623).
procedure TdmEmpleados.unqryTablaGBeforePost(DataSet: TDataSet);
var
  fld: TField;
begin
  inherited;
  fld := DataSet.FieldByName('CODIGO_EMPL');
  if Trim(fld.AsString) = '' then
  begin
    fld.FocusControl;
    raise ECampoObligatorioBBDD.Create(fld.FieldName,
      Format(SErrorBBDDCampoObligatorio, [SEtiquetaCodigoEmpleado]));
  end;
end;

initialization
  RegistrarDataModule(TdmEmpleados);
  ForceReferenceToClass(TdmEmpleados);
end.
