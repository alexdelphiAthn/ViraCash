{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataMovimientosAlmacen                                     }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de movimientos de almacén.                                    }
{    Contenedor de consultas sobre fza_movimientos_almacen (kardex).           }
{                                                                              }
{    Solo lectura desde la UI: cualquier intento de Insert/Edit/Delete         }
{    desde el grid de mantenimiento se bloquea con Abort. Los procesos         }
{    legítimos (albaranes, facturas, traspasos, regularización...) generan     }
{    movimientos llamando a PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT, no por este    }
{    data module.                                                              }
{******************************************************************************}
unit UniDataMovimientosAlmacen;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser, UniDataConn;

type
  TdmMovimientosAlmacen = class(TdmBase)
    procedure unqryTablaGBeforeInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforeEdit(DataSet: TDataSet);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
  private
    procedure BloquearEdicion(const aOp: string);
  end;

implementation

uses
  inLibMsgArticulos;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmMovimientosAlmacen.BloquearEdicion(const aOp: string);
begin
  NotificarAdvertencia(
    Format(SAvisoEdicionMovimientoAlmacen, [aOp]));
  Abort;
end;

procedure TdmMovimientosAlmacen.unqryTablaGBeforeInsert(DataSet: TDataSet);
begin
  inherited;
  BloquearEdicion('insertar');
end;

procedure TdmMovimientosAlmacen.unqryTablaGBeforeEdit(DataSet: TDataSet);
begin
  inherited;
  BloquearEdicion('editar');
end;

procedure TdmMovimientosAlmacen.unqryTablaGBeforeDelete(DataSet: TDataSet);
begin
  inherited;
  BloquearEdicion('borrar');
end;

initialization
  RegistrarDataModule(TdmMovimientosAlmacen);
  ForceReferenceToClass(TdmMovimientosAlmacen);
end.
