{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataDistribucionTiendas                                    }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       21/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Historial de las propuestas de traspaso de la distribución entre          }
{    tiendas y documentos de trabajo que se pueden distribuir.                 }
{******************************************************************************}
unit UniDataDistribucionTiendas;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes,
  Data.DB, MemDS, DBAccess, Uni,
  UniDataGen,
  inLibDistribucionTiendasIntf;

type
  TdmDistribucionTiendas = class(TdmBase)
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    procedure ConfigurarConsultas;
  public
    unqryDocumentos: TUniQuery;
    dsDocumentos: TDataSource;
    procedure AbrirDetalles; override;
    procedure AbrirDocumentos;
    procedure RefrescarHistorial;
    // Repositorio y confirmador sobre la conexión de esta pantalla.
    function CrearServicios: TServiciosDistribucionTiendas;
  end;

function SqlHistorialPropuestasTraspaso: string;
function SqlDocumentosTrabajoDistribuibles: string;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses
  inLibDocumentosTrabajoEstados,
  UniDataDistribucionTiendasComposicion;

{$R *.dfm}

const
  MAXIMO_DOCUMENTOS_DISTRIBUIBLES = 300;

procedure ForceReferenceToClass(C: TClass);
begin
end;

// Las unidades de lo trasladado (del todo o en parte) son las realmente
// traspasadas; las del resto, las propuestas.
function SqlHistorialPropuestasTraspaso: string;
begin
  Result :=
    'SELECT P.ID_TRPRO, P.ID_DTR_TRPRO, ' +
    '       COALESCE(DTR.TITULO_DTR, '''') AS TITULO_DTR, ' +
    '       P.INSTANTE_PROPUESTA_TRPRO, P.ESTADO_TRPRO, ' +
    '       CONCAT(P.CODIGO_ALM_ORIGEN_TRPRO, '' - '', ' +
    '              COALESCE(AO.NOMBRE_ALM_ALM, '''')) AS ORIGEN, ' +
    '       CONCAT(P.CODIGO_ALM_DESTINO_TRPRO, '' - '', ' +
    '              COALESCE(AD.NOMBRE_ALM_ALM, '''')) AS DESTINO, ' +
    '       (SELECT COALESCE(SUM(' +
    '                 CASE WHEN P.ESTADO_TRPRO IN (''TRASLADADO'', ' +
    '                                              ''TRASLADADO PARCIAL'') ' +
    '                      THEN L.CANTIDAD_TRASPASADA_TRPROLIN ' +
    '                      ELSE L.CANTIDAD_TRPROLIN END), 0) ' +
    '          FROM fza_traspasos_propuestas_lineas L ' +
    '         WHERE L.ID_TRPRO_TRPROLIN = P.ID_TRPRO) AS UNIDADES, ' +
    '       CONCAT_WS('' '', P.TIPO_DOC_TRPRO, ' +
    '                 CONCAT(P.SERIE_DOC_TRPRO, ''/'', ' +
    '                        P.NUMERO_DOC_TRPRO)) AS TRASPASO, ' +
    '       COALESCE(P.NUMERO_OPERACION_TRPRO, '''') ' +
    '         AS NUMERO_OPERACION_TRPRO, ' +
    '       P.INSTANTE_RESOLUCION_TRPRO, ' +
    '       COALESCE(P.USUARIO_RESOLUCION_TRPRO, '''') ' +
    '         AS USUARIO_RESOLUCION_TRPRO, ' +
    '       COALESCE(P.MOTIVO_RECHAZO_TRPRO, '''') ' +
    '         AS MOTIVO_RECHAZO_TRPRO, ' +
    '       P.USUARIO_ALTA ' +
    '  FROM fza_traspasos_propuestas P ' +
    '  LEFT JOIN fza_documentos_trabajo DTR ' +
    '    ON DTR.ID_DTR = P.ID_DTR_TRPRO ' +
    '  LEFT JOIN fza_almacenes AO ' +
    '    ON AO.CODIGO_ALM_ALM = P.CODIGO_ALM_ORIGEN_TRPRO ' +
    '  LEFT JOIN fza_almacenes AD ' +
    '    ON AD.CODIGO_ALM_ALM = P.CODIGO_ALM_DESTINO_TRPRO ' +
    ' ORDER BY P.ID_TRPRO DESC';
end;

// Los documentos abiertos y, además, los que aún tienen propuestas
// pendientes (o trasladadas en parte) aunque ya se haya trasladado alguna.
function SqlDocumentosTrabajoDistribuibles: string;
begin
  Result :=
    'SELECT DTR.ID_DTR, ' +
    '       CONCAT(DTR.ID_DTR, '' - '', COALESCE(DTR.TITULO_DTR, ''''), ' +
    '              '' ('', COALESCE(DTR.CODIGO_ALM_DTR, ''''), '')'') ' +
    '         AS DOCUMENTO ' +
    '  FROM fza_documentos_trabajo DTR ' +
    ' WHERE ' + CondicionSqlDocumentoTrabajoCreado('DTR.ESTADO_DTR') +
    '    OR EXISTS (SELECT 1 ' +
    '                 FROM fza_traspasos_propuestas P ' +
    '                WHERE P.ID_DTR_TRPRO = DTR.ID_DTR ' +
    '                  AND P.ESTADO_TRPRO IN (''PENDIENTE'', ' +
    '                                         ''TRASLADADO PARCIAL'')) ' +
    ' ORDER BY DTR.ID_DTR DESC ' +
    ' LIMIT ' + IntToStr(MAXIMO_DOCUMENTOS_DISTRIBUIBLES);
end;

procedure TdmDistribucionTiendas.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryDocumentos := TUniQuery.Create(Self);
  // Hereda la conexión que TdmBase.DoCreate ya dejó en unqryTablaG antes de
  // tocar SpecificOptions: UniDAC valida cada opción contra el proveedor de
  // la conexión y sin ella lanza "Connection is not defined".
  unqryDocumentos.Connection := unqryTablaG.Connection;
  dsDocumentos := TDataSource.Create(Self);
  dsDocumentos.DataSet := unqryDocumentos;
  ConfigurarConsultas;
end;

procedure TdmDistribucionTiendas.DataModuleDestroy(Sender: TObject);
begin
  CancelarEjecucionActiva;
  if Assigned(dsDocumentos) then
    dsDocumentos.DataSet := nil;
  if Assigned(unqryDocumentos) and unqryDocumentos.Active then
    unqryDocumentos.Close;
  inherited;
end;

procedure TdmDistribucionTiendas.ConfigurarConsultas;
begin
  unqryTablaG.SQL.Text := SqlHistorialPropuestasTraspaso;
  unqryTablaG.KeyFields := 'ID_TRPRO';
  unqryTablaG.ReadOnly := True;
  unqryDocumentos.SQL.Text := SqlDocumentosTrabajoDistribuibles;
  // Catálogo pequeño: se materializa antes de que el historial abra en
  // segundo plano, evitando un fetch pendiente sobre la misma conexión.
  if Assigned(unqryDocumentos.Connection) then
    unqryDocumentos.SpecificOptions.Values['FetchAll'] := 'True';
  unqryDocumentos.ReadOnly := True;
end;

procedure TdmDistribucionTiendas.AbrirDetalles;
begin
  inherited;
  AbrirDocumentos;
end;

procedure TdmDistribucionTiendas.AbrirDocumentos;
begin
  if unqryDocumentos.Active then
    unqryDocumentos.Refresh
  else
    unqryDocumentos.Open;
end;

procedure TdmDistribucionTiendas.RefrescarHistorial;
begin
  if unqryTablaG.Active then
    unqryTablaG.Refresh;
end;

function TdmDistribucionTiendas.CrearServicios:
  TServiciosDistribucionTiendas;
begin
  Result := CrearServiciosDistribucionTiendasUniDAC(
    Self, unqryTablaG.Connection, UbicacionSesion);
end;

initialization
  RegistrarDataModule(TdmDistribucionTiendas);
  ForceReferenceToClass(TdmDistribucionTiendas);
end.
