{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataComprasPantallaPersistencia                           }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Persistencia estrecha para la composición de pantallas de compra.        }
{******************************************************************************}
unit UniDataComprasPantallaPersistencia;

interface

uses
  Data.DB, Uni,
  inLibComprasPantallaIntf;

procedure CrearBusquedasComprasPantallaUniDAC(
  AConexion: TUniConnection;
  out AEmpresas: IBusquedaEmpresasComprasPantalla;
  out AProveedores: IBusquedaProveedoresComprasPantalla);
function CrearConsultasPedidoCompraPantallaUniDAC(
  AConexion: TUniConnection): IConsultasPedidoCompraPantalla;
function CrearPersistenciaPlantillasCompraPantallaUniDAC(
  AConexion: TUniConnection;
  AMaestroPlantillas: TDataSource): IPersistenciaPlantillasCompraPantalla;
function CrearUnidadTrabajoComprasPantallaUniDAC(
  AConexion: TUniConnection): IUnidadTrabajoComprasPantalla;

implementation

uses
  System.SysUtils,
  inLibPrestaShopColaSenal;

const
  SQL_EMPRESAS =
    'SELECT * FROM fza_empresas ORDER BY RAZON_SOCIAL_EMP';
  SQL_PROVEEDORES =
    'SELECT * FROM vi_proveedores ORDER BY RAZON_SOCIAL_PRV';
  SQL_EXISTE_COLUMNA_PEDIDO =
    'SELECT COUNT(*) AS N FROM INFORMATION_SCHEMA.COLUMNS ' +
    'WHERE TABLE_SCHEMA = DATABASE() ' +
    'AND TABLE_NAME = ''fza_pedidos_compra_lineas'' ' +
    'AND COLUMN_NAME = :c';
  SQL_ALMACEN_PRIMERA_LINEA =
    'SELECT IFNULL(NULLIF(L.CODIGO_ALMACEN_PEDCLIN, ''''), ' +
    'P.CODIGO_ALM_PEDC) AS ALM ' +
    'FROM fza_pedidos_compra_lineas L ' +
    'JOIN fza_pedidos_compra P ' +
    'ON P.SERIE_PEDC = L.SERIE_PEDC_PEDCLIN ' +
    'AND P.NUMERO_PEDC = L.NUMERO_PEDC_PEDCLIN ' +
    'WHERE L.SERIE_PEDC_PEDCLIN = :s ' +
    'AND L.NUMERO_PEDC_PEDCLIN = :n ' +
    'ORDER BY L.LINEA_PEDCLIN LIMIT 1';
  SQL_PLANTILLAS =
    'SELECT * FROM fza_compras_plantillas ORDER BY NOMBRE_SESPL';
  SQL_PROPIEDADES =
    'SELECT * FROM fza_compras_plantillas_props ' +
    'WHERE CODIGO_SESPL_SESPLPROP = :CODIGO_SESPL ' +
    'ORDER BY ORDEN_SESPLPROP';
  SQL_KITS =
    'SELECT * FROM fza_compras_plantillas_kits ' +
    'WHERE CODIGO_SESPL_SESPLKIT = :CODIGO_SESPL ' +
    'ORDER BY ORDEN_SESPLKIT';
  SQL_DETALLE_KITS =
    'SELECT * FROM fza_compras_plantillas_kits_det ' +
    'WHERE CODIGO_SESPL_SESPLKITD = :CODIGO_SESPL_SESPLKIT ' +
    'AND CODIGO_SESPLKIT_SESPLKITD = :CODIGO_SESPLKIT ' +
    'ORDER BY ORDEN_SESPLKITD';

type
  TConsultaComprasPantallaUniDAC = class(
    TInterfacedObject,
    IConsultaComprasPantalla)
  private
    FConsulta: TUniQuery;
  public
    constructor Create(AConsulta: TUniQuery);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;

  TBusquedasComprasPantallaUniDAC = class(
    TInterfacedObject,
    IBusquedaEmpresasComprasPantalla,
    IBusquedaProveedoresComprasPantalla)
  private
    FConexion: TUniConnection;
    function CrearConsulta(const ASql: string): IConsultaComprasPantalla;
  public
    constructor Create(AConexion: TUniConnection);
    function ConsultarEmpresas: IConsultaComprasPantalla;
    function ConsultarProveedores: IConsultaComprasPantalla;
  end;

  TConsultasPedidoCompraPantallaUniDAC = class(
    TInterfacedObject,
    IConsultasPedidoCompraPantalla)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function ColumnaLineasExiste(const ANombreColumna: string): Boolean;
    function AlmacenEfectivoPrimeraLinea(
      const ASerie, ANumero: string): string;
  end;

  TPersistenciaPlantillasCompraPantallaUniDAC = class(
    TInterfacedObject,
    IPersistenciaPlantillasCompraPantalla)
  private
    FPlantillas: TUniQuery;
    FPropiedades: TUniQuery;
    FKits: TUniQuery;
    FDetalleKits: TUniQuery;
    FDsPropiedades: TDataSource;
    FDsKits: TDataSource;
    FDsDetalleKits: TDataSource;
    function CrearConsulta(
      AConexion: TUniConnection;
      const ASql: string): TUniQuery;
  public
    constructor Create(
      AConexion: TUniConnection;
      AMaestroPlantillas: TDataSource);
    destructor Destroy; override;
    function DataSetPlantillas: TDataSet;
    function DataSourcePropiedades: TDataSource;
    function DataSourceKits: TDataSource;
    function DataSourceDetalleKits: TDataSource;
    procedure Abrir;
    procedure AnadirPropiedad;
    procedure BorrarPropiedad;
    procedure AnadirKit;
    procedure BorrarKit;
  end;

  TUnidadTrabajoComprasPantallaUniDAC = class(
    TInterfacedObject,
    IUnidadTrabajoComprasPantalla)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function EstaActiva: Boolean;
    procedure Iniciar;
    procedure Confirmar;
    procedure Revertir;
  end;

procedure ComprobarConexion(AConexion: TUniConnection);
begin
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
end;

procedure CrearBusquedasComprasPantallaUniDAC(
  AConexion: TUniConnection;
  out AEmpresas: IBusquedaEmpresasComprasPantalla;
  out AProveedores: IBusquedaProveedoresComprasPantalla);
var
  oBusquedas: TBusquedasComprasPantallaUniDAC;
begin
  oBusquedas := TBusquedasComprasPantallaUniDAC.Create(AConexion);
  AEmpresas := oBusquedas;
  AProveedores := oBusquedas;
end;

function CrearConsultasPedidoCompraPantallaUniDAC(
  AConexion: TUniConnection): IConsultasPedidoCompraPantalla;
begin
  Result := TConsultasPedidoCompraPantallaUniDAC.Create(AConexion);
end;

function CrearPersistenciaPlantillasCompraPantallaUniDAC(
  AConexion: TUniConnection;
  AMaestroPlantillas: TDataSource): IPersistenciaPlantillasCompraPantalla;
begin
  Result := TPersistenciaPlantillasCompraPantallaUniDAC.Create(
    AConexion,
    AMaestroPlantillas);
end;

function CrearUnidadTrabajoComprasPantallaUniDAC(
  AConexion: TUniConnection): IUnidadTrabajoComprasPantalla;
begin
  Result := TUnidadTrabajoComprasPantallaUniDAC.Create(AConexion);
end;

constructor TConsultaComprasPantallaUniDAC.Create(AConsulta: TUniQuery);
begin
  if AConsulta = nil then
    raise EArgumentNilException.Create('AConsulta');
  inherited Create;
  FConsulta := AConsulta;
end;

destructor TConsultaComprasPantallaUniDAC.Destroy;
begin
  FreeAndNil(FConsulta);
  inherited;
end;

function TConsultaComprasPantallaUniDAC.DataSet: TDataSet;
begin
  Result := FConsulta;
end;

constructor TBusquedasComprasPantallaUniDAC.Create(
  AConexion: TUniConnection);
begin
  ComprobarConexion(AConexion);
  inherited Create;
  FConexion := AConexion;
end;

function TBusquedasComprasPantallaUniDAC.CrearConsulta(
  const ASql: string): IConsultaComprasPantalla;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.Open;
    Result := TConsultaComprasPantallaUniDAC.Create(oConsulta);
    oConsulta := nil;
  finally
    oConsulta.Free;
  end;
end;

function TBusquedasComprasPantallaUniDAC.ConsultarEmpresas:
  IConsultaComprasPantalla;
begin
  Result := CrearConsulta(SQL_EMPRESAS);
end;

function TBusquedasComprasPantallaUniDAC.ConsultarProveedores:
  IConsultaComprasPantalla;
begin
  Result := CrearConsulta(SQL_PROVEEDORES);
end;

constructor TConsultasPedidoCompraPantallaUniDAC.Create(
  AConexion: TUniConnection);
begin
  ComprobarConexion(AConexion);
  inherited Create;
  FConexion := AConexion;
end;

function TConsultasPedidoCompraPantallaUniDAC.ColumnaLineasExiste(
  const ANombreColumna: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_EXISTE_COLUMNA_PEDIDO;
    oConsulta.ParamByName('c').AsString := ANombreColumna;
    oConsulta.Open;
    Result := oConsulta.FieldByName('N').AsInteger > 0;
  finally
    oConsulta.Free;
  end;
end;

function TConsultasPedidoCompraPantallaUniDAC.AlmacenEfectivoPrimeraLinea(
  const ASerie, ANumero: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  if (Trim(ASerie) <> '') and (Trim(ANumero) <> '') then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text := SQL_ALMACEN_PRIMERA_LINEA;
      oConsulta.ParamByName('s').AsString := ASerie;
      oConsulta.ParamByName('n').AsString := ANumero;
      oConsulta.Open;
      if not oConsulta.Eof then
        Result := oConsulta.FieldByName('ALM').AsString;
    finally
      oConsulta.Free;
    end;
  end;
end;

constructor TPersistenciaPlantillasCompraPantallaUniDAC.Create(
  AConexion: TUniConnection;
  AMaestroPlantillas: TDataSource);
begin
  ComprobarConexion(AConexion);
  if AMaestroPlantillas = nil then
    raise EArgumentNilException.Create('AMaestroPlantillas');
  inherited Create;
  FPlantillas := CrearConsulta(AConexion, SQL_PLANTILLAS);
  FPropiedades := CrearConsulta(AConexion, SQL_PROPIEDADES);
  FKits := CrearConsulta(AConexion, SQL_KITS);
  FDetalleKits := CrearConsulta(AConexion, SQL_DETALLE_KITS);
  FDsPropiedades := TDataSource.Create(nil);
  FDsKits := TDataSource.Create(nil);
  FDsDetalleKits := TDataSource.Create(nil);
  FPropiedades.MasterSource := AMaestroPlantillas;
  FKits.MasterSource := AMaestroPlantillas;
  FDetalleKits.MasterSource := FDsKits;
  FDsPropiedades.DataSet := FPropiedades;
  FDsKits.DataSet := FKits;
  FDsDetalleKits.DataSet := FDetalleKits;
end;

destructor TPersistenciaPlantillasCompraPantallaUniDAC.Destroy;
begin
  FreeAndNil(FDetalleKits);
  FreeAndNil(FDsDetalleKits);
  FreeAndNil(FKits);
  FreeAndNil(FDsKits);
  FreeAndNil(FPropiedades);
  FreeAndNil(FDsPropiedades);
  FreeAndNil(FPlantillas);
  inherited;
end;

function TPersistenciaPlantillasCompraPantallaUniDAC.CrearConsulta(
  AConexion: TUniConnection;
  const ASql: string): TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := AConexion;
  Result.SQL.Text := ASql;
end;

function TPersistenciaPlantillasCompraPantallaUniDAC.DataSetPlantillas:
  TDataSet;
begin
  Result := FPlantillas;
end;

function TPersistenciaPlantillasCompraPantallaUniDAC.DataSourcePropiedades:
  TDataSource;
begin
  Result := FDsPropiedades;
end;

function TPersistenciaPlantillasCompraPantallaUniDAC.DataSourceKits:
  TDataSource;
begin
  Result := FDsKits;
end;

function TPersistenciaPlantillasCompraPantallaUniDAC.DataSourceDetalleKits:
  TDataSource;
begin
  Result := FDsDetalleKits;
end;

procedure TPersistenciaPlantillasCompraPantallaUniDAC.Abrir;
begin
  FPlantillas.Open;
  FPropiedades.Open;
  FKits.Open;
  FDetalleKits.Open;
end;

procedure TPersistenciaPlantillasCompraPantallaUniDAC.AnadirPropiedad;
begin
  FPropiedades.Append;
end;

procedure TPersistenciaPlantillasCompraPantallaUniDAC.BorrarPropiedad;
begin
  if not FPropiedades.IsEmpty then
    FPropiedades.Delete;
end;

procedure TPersistenciaPlantillasCompraPantallaUniDAC.AnadirKit;
begin
  FKits.Append;
end;

procedure TPersistenciaPlantillasCompraPantallaUniDAC.BorrarKit;
begin
  if not FKits.IsEmpty then
    FKits.Delete;
end;

constructor TUnidadTrabajoComprasPantallaUniDAC.Create(
  AConexion: TUniConnection);
begin
  ComprobarConexion(AConexion);
  inherited Create;
  FConexion := AConexion;
end;

function TUnidadTrabajoComprasPantallaUniDAC.EstaActiva: Boolean;
begin
  Result := FConexion.InTransaction;
end;

procedure TUnidadTrabajoComprasPantallaUniDAC.Iniciar;
begin
  FConexion.StartTransaction;
end;

procedure TUnidadTrabajoComprasPantallaUniDAC.Confirmar;
begin
  FConexion.Commit;
  // La recepcion puede haber encolado stock para PrestaShop (FZ-ISSUE-146).
  SolicitarProcesadoPrestaShop;
end;

procedure TUnidadTrabajoComprasPantallaUniDAC.Revertir;
begin
  FConexion.Rollback;
end;

end.
