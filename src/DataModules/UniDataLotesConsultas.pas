{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataLotesConsultas                                         }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Consulta de stock por lote o serie y avisos de caducidad.               }
{******************************************************************************}
unit UniDataLotesConsultas;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes,
  Data.DB, MemDS, DBAccess, Uni,
  UniDataGen,
  inLibTraspasoOpePersistenciaIntf;

const
  FILTRO_LOTES_TODO = 'TODO';
  FILTRO_LOTES_CADUCADOS = 'CADUCADOS';
  FILTRO_LOTES_PROXIMOS = 'PROXIMOS';

type
  // Filtros de la consulta; '' = todos. Dias 0 = los de cada artículo.
  TFiltrosLotes = record
    Almacen: string;
    Articulo: string;
    TipoLote: string;
    Filtro: string;
    Dias: Integer;
    DiasDefecto: Integer;
  end;

  TAvisoCaducidades = record
    Caducados: Integer;
    Proximos: Integer;
    function HayAviso: Boolean;
  end;

  TdmLotesConsultas = class(TdmBase)
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    procedure AsignarFiltros(AConsulta: TUniQuery;
      const AFiltros: TFiltrosLotes);
  public
    unqryInforme: TUniQuery;
    procedure AplicarFiltros(const AFiltros: TFiltrosLotes);
    // Deja los filtros puestos sin abrir: la primera carga la hace el Mto.
    procedure PrepararFiltros(const AFiltros: TFiltrosLotes);
    function ListarAlmacenes: TAlmacenesDestinoTraspaso;
    // Para el informe: mismos filtros, por almacén, familia y caducidad.
    function AbrirInforme(const AFiltros: TFiltrosLotes): TDataSet;
  end;

// Para el aviso al arrancar, sin pantalla abierta.
function ContarCaducidades(AConexion: TUniConnection;
  const AEmpresa: string; ADiasDefecto: Integer): TAvisoCaducidades;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

const
  SQL_STOCK_LOTES =
    'CALL PRC_FZA_LOTES_STOCK_CONSULTA(:EMP, :ALM, :ART, :TIPO, :FILTRO, ' +
    ':DIAS, :DIAS_DEFECTO)';

procedure ForceReferenceToClass(C: TClass);
begin
end;

function TAvisoCaducidades.HayAviso: Boolean;
begin
  Result := (Caducados > 0) or (Proximos > 0);
end;

procedure TdmLotesConsultas.DataModuleCreate(Sender: TObject);
var
  Filtros: TFiltrosLotes;
begin
  inherited;
  unqryInforme := TUniQuery.Create(Self);
  unqryInforme.Connection := unqryTablaG.Connection;
  unqryInforme.SQL.Text := SQL_STOCK_LOTES;
  unqryInforme.ReadOnly := True;
  unqryTablaG.SQL.Text := SQL_STOCK_LOTES;
  unqryTablaG.ReadOnly := True;
  Filtros := Default(TFiltrosLotes);
  Filtros.Filtro := FILTRO_LOTES_PROXIMOS;
  AsignarFiltros(unqryTablaG, Filtros);
end;

procedure TdmLotesConsultas.DataModuleDestroy(Sender: TObject);
begin
  CancelarEjecucionActiva;
  if Assigned(unqryInforme) and unqryInforme.Active then
    unqryInforme.Close;
  inherited;
end;

procedure TdmLotesConsultas.AsignarFiltros(AConsulta: TUniQuery;
  const AFiltros: TFiltrosLotes);
begin
  AConsulta.ParamByName('EMP').AsString := Trim(UbicacionSesion.Empresa);
  AConsulta.ParamByName('ALM').AsString := Trim(AFiltros.Almacen);
  AConsulta.ParamByName('ART').AsString := Trim(AFiltros.Articulo);
  AConsulta.ParamByName('TIPO').AsString := Trim(AFiltros.TipoLote);
  AConsulta.ParamByName('FILTRO').AsString := AFiltros.Filtro;
  AConsulta.ParamByName('DIAS').DataType := ftInteger;
  if AFiltros.Dias > 0 then
    AConsulta.ParamByName('DIAS').AsInteger := AFiltros.Dias
  else
    AConsulta.ParamByName('DIAS').Clear;
  AConsulta.ParamByName('DIAS_DEFECTO').AsInteger := AFiltros.DiasDefecto;
end;

procedure TdmLotesConsultas.AplicarFiltros(const AFiltros: TFiltrosLotes);
begin
  PrepararFiltros(AFiltros);
  unqryTablaG.Open;
end;

procedure TdmLotesConsultas.PrepararFiltros(const AFiltros: TFiltrosLotes);
begin
  if unqryTablaG.Active then
    unqryTablaG.Close;
  AsignarFiltros(unqryTablaG, AFiltros);
end;

function TdmLotesConsultas.ListarAlmacenes: TAlmacenesDestinoTraspaso;
var
  oConsulta: TUniQuery;
  iAlmacen: Integer;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := unqryTablaG.Connection;
    oConsulta.SQL.Text :=
      'SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM ' +
      '  FROM fza_almacenes ' +
      ' WHERE ESACTIVO_ALM = ''S'' ' +
      '   AND (:EMP = '''' OR CODIGO_EMP_ALM = :EMP) ' +
      ' ORDER BY ORDEN_ALM, CODIGO_ALM_ALM';
    oConsulta.ParamByName('EMP').AsString := Trim(UbicacionSesion.Empresa);
    oConsulta.Open;
    SetLength(Result, oConsulta.RecordCount);
    iAlmacen := 0;
    while not oConsulta.Eof do
    begin
      Result[iAlmacen].Codigo :=
        oConsulta.FieldByName('CODIGO_ALM_ALM').AsString;
      Result[iAlmacen].Nombre :=
        oConsulta.FieldByName('NOMBRE_ALM_ALM').AsString;
      Inc(iAlmacen);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TdmLotesConsultas.AbrirInforme(
  const AFiltros: TFiltrosLotes): TDataSet;
begin
  if unqryInforme.Active then
    unqryInforme.Close;
  AsignarFiltros(unqryInforme, AFiltros);
  unqryInforme.Open;
  unqryInforme.IndexFieldNames :=
    'CODIGO_ALM_STK;DESCRIPCION_FAM;FECHA_CADUCIDAD;CODIGO_UNIDAD_STK';
  Result := unqryInforme;
end;

function ContarCaducidades(AConexion: TUniConnection;
  const AEmpresa: string; ADiasDefecto: Integer): TAvisoCaducidades;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'CALL PRC_FZA_LOTES_AVISO_CADUCIDAD(:EMP, :DIAS, @fza_cad, @fza_prox)';
    oConsulta.ParamByName('EMP').AsString := Trim(AEmpresa);
    oConsulta.ParamByName('DIAS').AsInteger := ADiasDefecto;
    oConsulta.Execute;
    oConsulta.SQL.Text :=
      'SELECT @fza_cad AS CADUCADOS, @fza_prox AS PROXIMOS';
    oConsulta.Open;
    Result.Caducados := oConsulta.FieldByName('CADUCADOS').AsInteger;
    Result.Proximos := oConsulta.FieldByName('PROXIMOS').AsInteger;
  finally
    FreeAndNil(oConsulta);
  end;
end;

initialization
  RegistrarDataModule(TdmLotesConsultas);
  ForceReferenceToClass(TdmLotesConsultas);
end.
