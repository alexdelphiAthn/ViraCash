{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataTotalMaximoLinea                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Total máximo por línea (FZ-ISSUE-255) sobre el dataset de líneas de un    }
{    documento: lee el máximo de la empresa y pide confirmación al grabar      }
{    una línea cuyo total ha subido por encima de él. Si no se confirma, la    }
{    línea no se graba (Abort) y sigue en edición para corregirla. El TPV      }
{    no lo usa: pregunta al cambiar la línea (inLibCajaTotalMaximoLinea).      }
{******************************************************************************}
unit UniDataTotalMaximoLinea;

interface

uses
  System.Classes, Data.DB, Uni,
  inLibTotalMaximoLinea;

type
  TLectorTotalMaximoLinea = reference to function: Currency;

  // Se engancha a BeforeInsert, BeforeEdit y BeforePost del dataset de
  // líneas, encadenando los manejadores que ya tenía. El total previo se
  // toma al empezar la edición porque OldValue no sirve en un
  // TClientDataSet (TPV) ni con CachedUpdates. Al destruirse devuelve los
  // manejadores originales. Se comprueba todo lo que sube el total de una
  // línea, aunque lo grabe el código (la rejilla al cambiar de fila, el
  // recálculo de la matriz de tallas...): en ventas y compras siempre viene
  // del usuario, y abrir un documento no graba líneas.
  // ConfirmarTotalPendiente pregunta por un total ANTES de que llegue a la
  // línea (matriz de tallas: la celda se guarda aparte y el total de la
  // línea se recalcula después). Un sí vale para esa línea hasta grabarla.
  TVigilanteTotalMaximoLinea = class(TComponent)
  private
    FLineas: TDataSet;
    FCampoTotal: string;
    FLector: TLectorTotalMaximoLinea;
    FConfirmar: TConfirmacionTotalLinea;
    FTotalAlEditar: Currency;
    FTotalConfirmado: Currency;
    FMarcaConfirmada: TBookmark;
    FAntesInsertar: TDataSetNotifyEvent;
    FAntesEditar: TDataSetNotifyEvent;
    FAntesGrabar: TDataSetNotifyEvent;
    procedure LineasBeforeInsert(DataSet: TDataSet);
    procedure LineasBeforeEdit(DataSet: TDataSet);
    procedure LineasBeforePost(DataSet: TDataSet);
    function EsLineaConfirmada: Boolean;
    function TotalDeReferencia: Currency;
    procedure ComprobarTotalLinea;
    procedure Desenganchar;
  protected
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
  public
    constructor Create(
      AOwner                : TComponent;
      ALineas               : TDataSet;
      const ACampoTotal     : string;
      const ALector         : TLectorTotalMaximoLinea;
      const AConfirmar      : TConfirmacionTotalLinea); reintroduce;
    destructor Destroy; override;
    function ConfirmarTotalPendiente(ATotalNuevo: Currency): Boolean;
  end;

function LeerTotalMaximoLineaEmpresa(AConexion: TUniConnection;
  const AEmpresa: string): Currency;
// El de la empresa o, si no lo fija, el automático del artículo (precio de
// su tarifa activa más alta x 100). La decisión de FZ-ISSUE-255 lo pedía y
// faltaba: sin máximo en la empresa no había ningún límite (FZ-ISSUE-331).
function LeerTotalMaximoLinea(AConexion: TUniConnection;
  const AEmpresa, AArticulo: string): Currency;

implementation

uses
  System.SysUtils;

const
  fcampototalmaximo = 'TOTAL_MAXIMO_LINEA_EMP';

// Sin el script 20261006_empresas_total_maximo_linea.sql no hay columna y no
// hay límite.
function ExisteColumnaTotalMaximo(AConsulta: TUniQuery): Boolean;
begin
  AConsulta.SQL.Text :=
    'SELECT EXISTS(' +
    '  SELECT 1 ' +
    '    FROM INFORMATION_SCHEMA.COLUMNS C ' +
    '   WHERE C.TABLE_SCHEMA = DATABASE() ' +
    '     AND C.TABLE_NAME = ''fza_empresas'' ' +
    '     AND C.COLUMN_NAME = :COLUMNA) AS EXISTE';
  AConsulta.ParamByName('COLUMNA').AsString := fcampototalmaximo;
  AConsulta.Open;
  Result := AConsulta.FieldByName('EXISTE').AsInteger = 1;
  AConsulta.Close;
end;

function LeerTotalMaximoLineaEmpresa(AConexion: TUniConnection;
  const AEmpresa: string): Currency;
var
  oConsulta: TUniQuery;
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create(
      'LeerTotalMaximoLineaEmpresa: falta la conexión.');
  Result := 0;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    if ExisteColumnaTotalMaximo(oConsulta) then
    begin
      oConsulta.SQL.Text :=
        'SELECT E.' + fcampototalmaximo +
        '  FROM fza_empresas E ' +
        ' WHERE E.CODIGO_EMP_EMP = :EMPRESA';
      oConsulta.ParamByName('EMPRESA').AsString := AEmpresa;
      oConsulta.Open;
      if not oConsulta.Eof then
        Result := oConsulta.FieldByName(fcampototalmaximo).AsCurrency;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function LeerPrecioTarifaMasAlta(AConexion: TUniConnection;
  const AArticulo: string): Currency;
var
  oConsulta: TUniQuery;
begin
  Result := 0;
  if Trim(AArticulo) <> '' then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      oConsulta.SQL.Text :=
        'SELECT MAX(GREATEST(COALESCE(T.PRECIO_SALIDA_ARTTAR, 0), ' +
        '                    COALESCE(T.PRECIO_FINAL_ARTTAR, 0))) AS PRECIO ' +
        '  FROM fza_articulos_tarifas T ' +
        ' WHERE T.CODIGO_ART_ARTTAR = :ARTICULO ' +
        '   AND COALESCE(T.ESACTIVO_ARTTAR, ''S'') = ''S''';
      oConsulta.ParamByName('ARTICULO').AsString := Trim(AArticulo);
      oConsulta.Open;
      if not oConsulta.FieldByName('PRECIO').IsNull then
        Result := oConsulta.FieldByName('PRECIO').AsCurrency;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function LeerTotalMaximoLinea(AConexion: TUniConnection;
  const AEmpresa, AArticulo: string): Currency;
var
  cEmpresa: Currency;
begin
  cEmpresa := LeerTotalMaximoLineaEmpresa(AConexion, AEmpresa);
  if cEmpresa > 0 then
    Result := cEmpresa
  else
    Result := ResolverTotalMaximoLinea(0,
      LeerPrecioTarifaMasAlta(AConexion, AArticulo));
end;

{ TVigilanteTotalMaximoLinea }

constructor TVigilanteTotalMaximoLinea.Create(
  AOwner                : TComponent;
  ALineas               : TDataSet;
  const ACampoTotal     : string;
  const ALector         : TLectorTotalMaximoLinea;
  const AConfirmar      : TConfirmacionTotalLinea);
begin
  if not Assigned(ALineas) then
    raise EArgumentNilException.Create(
      'TVigilanteTotalMaximoLinea: falta el dataset de líneas.');
  if not Assigned(ALector) then
    raise EArgumentNilException.Create(
      'TVigilanteTotalMaximoLinea: falta el lector del máximo.');
  inherited Create(AOwner);
  FLineas := ALineas;
  FCampoTotal := ACampoTotal;
  FLector := ALector;
  FConfirmar := AConfirmar;
  FLineas.FreeNotification(Self);
  FAntesInsertar := FLineas.BeforeInsert;
  FAntesEditar := FLineas.BeforeEdit;
  FAntesGrabar := FLineas.BeforePost;
  FLineas.BeforeInsert := LineasBeforeInsert;
  FLineas.BeforeEdit := LineasBeforeEdit;
  FLineas.BeforePost := LineasBeforePost;
end;

destructor TVigilanteTotalMaximoLinea.Destroy;
begin
  Desenganchar;
  inherited;
end;

procedure TVigilanteTotalMaximoLinea.Desenganchar;
begin
  if Assigned(FLineas) then
  begin
    if TMethod(FLineas.BeforeInsert).Data = Self then
      FLineas.BeforeInsert := FAntesInsertar;
    if TMethod(FLineas.BeforeEdit).Data = Self then
      FLineas.BeforeEdit := FAntesEditar;
    if TMethod(FLineas.BeforePost).Data = Self then
      FLineas.BeforePost := FAntesGrabar;
    FLineas.RemoveFreeNotification(Self);
    FLineas := nil;
  end;
end;

procedure TVigilanteTotalMaximoLinea.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = FLineas) then
    FLineas := nil;
end;

procedure TVigilanteTotalMaximoLinea.LineasBeforeInsert(DataSet: TDataSet);
begin
  if Assigned(FAntesInsertar) then
    FAntesInsertar(DataSet);
  FTotalAlEditar := 0;
end;

procedure TVigilanteTotalMaximoLinea.LineasBeforeEdit(DataSet: TDataSet);
begin
  if Assigned(FAntesEditar) then
    FAntesEditar(DataSet);
  FTotalAlEditar := DataSet.FieldByName(FCampoTotal).AsCurrency;
end;

// El manejador propio del documento va primero: en ventas es él quien
// calcula el total de la línea (PrepararLineaFiscalVenta).
procedure TVigilanteTotalMaximoLinea.LineasBeforePost(DataSet: TDataSet);
begin
  if Assigned(FAntesGrabar) then
    FAntesGrabar(DataSet);
  ComprobarTotalLinea;
end;

function TVigilanteTotalMaximoLinea.EsLineaConfirmada: Boolean;
var
  Marca: TBookmark;
begin
  Result := False;
  if Length(FMarcaConfirmada) > 0 then
  begin
    Marca := FLineas.GetBookmark;
    Result := (Length(Marca) > 0) and
              (FLineas.CompareBookmarks(FMarcaConfirmada, Marca) = 0);
  end;
end;

// Total con el que se compara: el de antes de editar la línea o, si ya se
// confirmó uno mayor para esta misma línea, ese.
function TVigilanteTotalMaximoLinea.TotalDeReferencia: Currency;
begin
  if FLineas.State in dsEditModes then
    Result := FTotalAlEditar
  else
    Result := FLineas.FieldByName(FCampoTotal).AsCurrency;
  if EsLineaConfirmada and (Abs(FTotalConfirmado) > Abs(Result)) then
    Result := FTotalConfirmado;
end;

function TVigilanteTotalMaximoLinea.ConfirmarTotalPendiente(
  ATotalNuevo: Currency): Boolean;
var
  dReferencia: Currency;
begin
  dReferencia := TotalDeReferencia;
  Result := (not HaSubidoTotalLinea(dReferencia, ATotalNuevo)) or
            ConfirmarTotalLinea(dReferencia, ATotalNuevo, FLector(),
                                FConfirmar);
  if Result and HaSubidoTotalLinea(dReferencia, ATotalNuevo) then
  begin
    FTotalConfirmado := ATotalNuevo;
    FMarcaConfirmada := FLineas.GetBookmark;
  end;
end;

// El máximo solo se lee de la BBDD cuando el total ha subido.
procedure TVigilanteTotalMaximoLinea.ComprobarTotalLinea;
var
  dTotal, dReferencia: Currency;
begin
  dTotal := FLineas.FieldByName(FCampoTotal).AsCurrency;
  dReferencia := TotalDeReferencia;
  if HaSubidoTotalLinea(dReferencia, dTotal) and
     (not ConfirmarTotalLinea(dReferencia, dTotal, FLector(),
                              FConfirmar)) then
    Abort;
  FMarcaConfirmada := nil;
  FTotalConfirmado := 0;
end;

end.
