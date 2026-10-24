{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataBuscarSerie                                            }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Almacén - Buscar serie (F-LOTEC-018): una serie o lote sin saber el       }
{    artículo (PRC_FZA_LOTES_BUSCAR), sus movimientos con documento, cliente   }
{    y proveedor (PRC_FZA_LOTES_HISTORICO) y, con garantías, su venta, fin     }
{    de garantía y reclamaciones (PRC_FZA_GARANTIAS_DATOS_SERIE).              }
{******************************************************************************}
unit UniDataBuscarSerie;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes,
  Data.DB, MemDS, DBAccess, Uni,
  UniDataGen,
  inLibGarantias;

type
  TResultadoBuscarSerie = record
    Encontrada: Boolean;
    Articulos: Integer;
    Sku: string;
    Serie: string;
    Articulo: string;
    Descripcion: string;
    TipoLote: string;
    // «A01 (1), B02 (3)»; vacío si no queda stock.
    AlmacenesConStock: string;
    TieneEntrada: Boolean;
    FechaEntrada: TDateTime;
    Proveedor: string;
    TipoDocOrigen: string;
    SerieDocOrigen: string;
    NumeroDocOrigen: string;
    // Algún movimiento de almacén con la serie (si no, nunca tuvo stock).
    TieneMovimientos: Boolean;
    Garantia: TDatosSerieGarantia;
  end;

  TdmBuscarSerie = class(TdmBase)
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    procedure LeerCatalogo(AConsulta: TUniQuery;
      var AResultado: TResultadoBuscarSerie);
    function DatosGarantia(const ASerie, ASku: string): TDatosSerieGarantia;
  public
    unqryReclamaciones: TUniQuery;
    dsReclamaciones: TDataSource;
    // AConGarantias: consulta también la garantía y las reclamaciones
    // (solo con appGarantias; sin él, las tablas pueden no existir).
    function Buscar(const ASerie: string;
      AConGarantias: Boolean): TResultadoBuscarSerie;
  end;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

uses
  UniDataGarantiasReclamaciones;

const
  SQL_HISTORICO = 'CALL PRC_FZA_LOTES_HISTORICO(:SKU, :LOTE)';
  SQL_RECLAMACIONES =
    'SELECT G.ID_GAR, G.FECHA_RECLAMACION_GAR, G.LOTE_GAR, ' +
    '       G.CODIGO_UNIDAD_GAR, G.ESTADO_GAR, ' +
    '       COALESCE(G.RESOLUCION_GAR, '''') AS RESOLUCION_GAR, ' +
    '       COALESCE(G.LOTE_SUSTITUTO_GAR, '''') AS LOTE_SUSTITUTO_GAR, ' +
    '       COALESCE(G.MOTIVO_GAR, '''') AS MOTIVO_GAR, ' +
    '       G.FECHA_FIN_GARANTIA_GAR ' +
    '  FROM fza_garantias_reclamaciones G ' +
    ' WHERE G.LOTE_GAR = :LOTE OR G.LOTE_SUSTITUTO_GAR = :LOTE ' +
    ' ORDER BY G.FECHA_RECLAMACION_GAR DESC, G.ID_GAR DESC';

procedure ForceReferenceToClass(C: TClass);
begin
end;

procedure TdmBuscarSerie.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryTablaG.SQL.Text := SQL_HISTORICO;
  unqryTablaG.ReadOnly := True;
  unqryTablaG.ParamByName('SKU').AsString := '';
  unqryTablaG.ParamByName('LOTE').AsString := '';
  unqryReclamaciones := TUniQuery.Create(Self);
  unqryReclamaciones.Connection := unqryTablaG.Connection;
  unqryReclamaciones.SQL.Text := SQL_RECLAMACIONES;
  unqryReclamaciones.ReadOnly := True;
  dsReclamaciones := TDataSource.Create(Self);
  dsReclamaciones.DataSet := unqryReclamaciones;
end;

procedure TdmBuscarSerie.DataModuleDestroy(Sender: TObject);
begin
  CancelarEjecucionActiva;
  if Assigned(dsReclamaciones) then
    dsReclamaciones.DataSet := nil;
  if Assigned(unqryReclamaciones) and unqryReclamaciones.Active then
    unqryReclamaciones.Close;
  inherited;
end;

// Varias filas por SKU (una por almacén con stock): se resume la primera
// SKU y sus almacenes.
procedure TdmBuscarSerie.LeerCatalogo(AConsulta: TUniQuery;
  var AResultado: TResultadoBuscarSerie);
var
  oSkus: TStringList;
  sAlmacen: string;
begin
  oSkus := TStringList.Create;
  try
    oSkus.Sorted := True;
    oSkus.Duplicates := dupIgnore;
    AResultado.Sku := AConsulta.FieldByName('CODIGO_UNIDAD_LOT').AsString;
    AResultado.Articulo := AConsulta.FieldByName('CODIGO_ART_SKU').AsString;
    AResultado.Descripcion :=
      AConsulta.FieldByName('DESCRIPCION_ART').AsString;
    AResultado.TipoLote := AConsulta.FieldByName('TIPO_LOT').AsString;
    AResultado.TieneEntrada :=
      not AConsulta.FieldByName('FECHA_ENTRADA_LOT').IsNull;
    AResultado.FechaEntrada :=
      AConsulta.FieldByName('FECHA_ENTRADA_LOT').AsDateTime;
    AResultado.Proveedor := AConsulta.FieldByName('CODIGO_PRV_LOT').AsString;
    AResultado.TipoDocOrigen :=
      AConsulta.FieldByName('TIPO_DOC_ORIGEN_LOT').AsString;
    AResultado.SerieDocOrigen :=
      AConsulta.FieldByName('SERIE_DOC_ORIGEN_LOT').AsString;
    AResultado.NumeroDocOrigen :=
      AConsulta.FieldByName('NUMERO_DOC_ORIGEN_LOT').AsString;
    while not AConsulta.Eof do
    begin
      oSkus.Add(AConsulta.FieldByName('CODIGO_UNIDAD_LOT').AsString);
      sAlmacen := AConsulta.FieldByName('CODIGO_ALM_STK').AsString;
      if (sAlmacen <> '') and SameText(AResultado.Sku,
           AConsulta.FieldByName('CODIGO_UNIDAD_LOT').AsString) then
      begin
        if AResultado.AlmacenesConStock <> '' then
          AResultado.AlmacenesConStock := AResultado.AlmacenesConStock +
            ', ';
        AResultado.AlmacenesConStock := AResultado.AlmacenesConStock +
          Format('%s (%s)', [sAlmacen, FormatFloat('#,##0.###',
            AConsulta.FieldByName('CANTIDAD_STK').AsFloat)]);
      end;
      AConsulta.Next;
    end;
    AResultado.Articulos := oSkus.Count;
  finally
    FreeAndNil(oSkus);
  end;
end;

function TdmBuscarSerie.DatosGarantia(
  const ASerie, ASku: string): TDatosSerieGarantia;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := unqryTablaG.Connection;
    oConsulta.SQL.Text :=
      'CALL PRC_FZA_GARANTIAS_DATOS_SERIE(:SERIE, :SKU)';
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('SKU').AsString := ASku;
    oConsulta.Open;
    Result := LeerDatosSerieGarantia(oConsulta);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TdmBuscarSerie.Buscar(const ASerie: string;
  AConGarantias: Boolean): TResultadoBuscarSerie;
var
  oConsulta: TUniQuery;
begin
  Result := Default(TResultadoBuscarSerie);
  Result.Serie := Trim(ASerie);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := unqryTablaG.Connection;
    oConsulta.SQL.Text := 'CALL PRC_FZA_LOTES_BUSCAR(:LOTE)';
    oConsulta.ParamByName('LOTE').AsString := Result.Serie;
    oConsulta.Open;
    Result.Encontrada := not oConsulta.IsEmpty;
    if Result.Encontrada then
      LeerCatalogo(oConsulta, Result);
  finally
    FreeAndNil(oConsulta);
  end;
  if unqryTablaG.Active then
    unqryTablaG.Close;
  unqryTablaG.ParamByName('SKU').AsString := Result.Sku;
  unqryTablaG.ParamByName('LOTE').AsString := Result.Serie;
  unqryTablaG.Open;
  Result.TieneMovimientos := not unqryTablaG.IsEmpty;
  if Result.Encontrada and AConGarantias then
  begin
    Result.Garantia := DatosGarantia(Result.Serie, Result.Sku);
    if unqryReclamaciones.Active then
      unqryReclamaciones.Close;
    unqryReclamaciones.ParamByName('LOTE').AsString := Result.Serie;
    unqryReclamaciones.Open;
  end;
end;

initialization
  RegistrarDataModule(TdmBuscarSerie);
  ForceReferenceToClass(TdmBuscarSerie);
end.
