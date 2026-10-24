{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGridPivoteCompraTipos                                    }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Tipos compartidos por los colaboradores del pivote de compra.             }
{******************************************************************************}
unit inLibGridPivoteCompraTipos;

interface

uses
  System.Generics.Collections, System.UITypes,
  Data.DB, Uni,
  cxGridDBTableView,
  inLibContextoSesionIntf, inLibGridTallasInline, inLibLogIntf;

type
  TGridPivoteCompraConfig = record
    Conexion               : TUniConnection;
    ContextoSesion         : IContextoSesionAplicacion;
    RegistroLog            : IRegistroLog;
    Grid                   : TcxGridDBTableView;
    SourceMaster           : TDataSource;
    SourceLineas           : TUniQuery;
    Gestor                 : TGestorGridTallas;
    ColColorPivot          : TcxGridDBColumn;
    ColColorProveedorPivot : TcxGridDBColumn;
    ColumnasTallas         : TArray<TcxGridDBColumn>;
    MaxColumnasTallas      : Integer;
    TablaLineas            : string;
    FieldSerieMaster       : string;
    FieldNumeroMaster      : string;
    FieldSerieLin          : string;
    FieldNumeroLin         : string;
    FieldLinea             : string;
    FieldArt               : string;
    FieldSku               : string;
    FieldCantidad          : string;
    FieldPrecioBase        : string;
    FieldTotalUds          : string;
    FieldTotalLinea        : string;
    FieldCantidadRecibida  : string;
    FieldIdAcPivot         : string;
    FieldAlmacen           : string;
    FieldAlmacenMaster     : string;
    FieldColorTexto        : string;
    CamposOcultosEnPivote  : TArray<string>;
  end;

  TCeldaARecibir = record
    LineaPedido  : string;
    CodigoSku    : string;
    CodigoAlmacen: string;
    Cantidad     : Double;
    // FZ-ISSUE-434: lote (o serie) y caducidad pedidos al recibir. Lote
    // vacío = los de la línea del pedido. Crear la celda con Default().
    Lote         : string;
    FechaCaducidad: TDateTime;
  end;

  TEstadoFilaRecibida = (efrIndefinido, efrNada, efrParcial, efrTotal);

const
  ID_AV_SIN_TALLA = 0;
  COL_REC_NADA: TColor = $0099FFFF;
  COL_REC_PARCIAL: TColor = $0099FF99;
  COL_REC_TOTAL: TColor = $00FFCC99;
  ALTURA_FILA_EXPANDIDA = 75;

implementation

end.
