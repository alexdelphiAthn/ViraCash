{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataSeriesDocumentosRepositorio                            }
{    Tipo:       Repositorio                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Consultas de almacenes y cajas para el modal de series de documentos.     }
{******************************************************************************}
unit UniDataSeriesDocumentosRepositorio;

interface

uses
  System.Classes, Uni;

type
  TRepositorioSeriesDocumentos = class(TComponent)
  private
    FAlmacenes: TUniQuery;
    FCajas: TUniQuery;
  public
    constructor Create(
      AOwner: TComponent;
      AConexion: TUniConnection); reintroduce;
    procedure AbrirAlmacenes(const AEmpresa: string);
    procedure AbrirCajas(const AAlmacen: string);
    property Almacenes: TUniQuery read FAlmacenes;
    property Cajas: TUniQuery read FCajas;
  end;

implementation

constructor TRepositorioSeriesDocumentos.Create(
  AOwner: TComponent;
  AConexion: TUniConnection);
begin
  inherited Create(AOwner);
  FAlmacenes := TUniQuery.Create(Self);
  FAlmacenes.Connection := AConexion;
  FAlmacenes.SQL.Text :=
    'SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM ' +
    '  FROM fza_almacenes ' +
    ' WHERE CODIGO_EMP_ALM = :EMPRESA ' +
    '   AND ESACTIVO_ALM = ''S'' ' +
    ' ORDER BY COALESCE(ORDEN_ALM, 2147483647), CODIGO_ALM_ALM';
  FCajas := TUniQuery.Create(Self);
  FCajas.Connection := AConexion;
  FCajas.SQL.Text :=
    'SELECT CODIGO_CAJA_ALMCAJ, DESCRIPCION_ALMCAJ ' +
    '  FROM fza_almacenes_cajas ' +
    ' WHERE CODIGO_ALM_ALMCAJ = :ALMACEN ' +
    ' ORDER BY CODIGO_CAJA_ALMCAJ';
end;

procedure TRepositorioSeriesDocumentos.AbrirAlmacenes(
  const AEmpresa: string);
begin
  FAlmacenes.Close;
  FAlmacenes.ParamByName('EMPRESA').AsString := AEmpresa;
  FAlmacenes.Open;
end;

procedure TRepositorioSeriesDocumentos.AbrirCajas(
  const AAlmacen: string);
begin
  FCajas.Close;
  FCajas.ParamByName('ALMACEN').AsString := AAlmacen;
  FCajas.Open;
end;

end.
