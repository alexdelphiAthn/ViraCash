{******************************************************************************}
{                                                                              }
{  Módulo:       RecuentoLocal                                                 }
{    Tipo:       Librería (App FMX)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Cola local offline de escaneos (SQLite vía UniDAC). Cada escaneo se       }
{    persiste aquí primero (con su uuid); la subida al servidor vacía la cola  }
{    por lotes. El uuid (PRIMARY KEY) evita duplicar al reintentar.            }
{******************************************************************************}
unit RecuentoLocal;

interface

uses
  System.SysUtils, System.IOUtils, Data.DB,
  Uni, SQLiteUniProvider, DBAccess, MemDS,
  RecuentoModelo;

type
  TRecuentoLocal = class
  private
    FConn: TUniConnection;
    procedure CrearEsquema;
  public
    constructor Create(const ARuta: string = '');
    destructor Destroy; override;
    procedure Encolar(AIdRecuento: Int64; const AEvento: TEventoRec);
    function ContarPendientes(AIdRecuento: Int64): Integer;
    function LeerLote(AIdRecuento: Int64; AMaxFilas: Integer): TArrEvento;
    procedure MarcarSubidos(const AUuids: TArray<string>);
    // Suma ya escaneada de un SKU en este recuento (feedback en pantalla).
    function ContarPorSku(AIdRecuento: Int64; const ASku: string): Double;
  end;

var
  oLocal: TRecuentoLocal;

implementation

constructor TRecuentoLocal.Create(const ARuta: string);
begin
  inherited Create;
  FConn := TUniConnection.Create(nil);
  FConn.ProviderName := 'SQLite';
  FConn.SpecificOptions.Values['Direct'] := 'True';
  if ARuta = '' then
    FConn.Database := TPath.Combine(TPath.GetDocumentsPath, 'recuento.db')
  else
    FConn.Database := ARuta;
  FConn.LoginPrompt := False;
  // En Windows SQLite no crea el fichero si no existe (Android sí): sin esto
  // el primer arranque falla con «unable to open database file».
  FConn.SpecificOptions.Values['ForceCreateDatabase'] := 'True';
  FConn.Connected := True;
  CrearEsquema;
end;

destructor TRecuentoLocal.Destroy;
begin
  if Assigned(FConn) then
    FConn.Connected := False;
  FreeAndNil(FConn);
  inherited Destroy;
end;

procedure TRecuentoLocal.CrearEsquema;
begin
  FConn.ExecSQL(
    'CREATE TABLE IF NOT EXISTS eventos (' +
    '  uuid TEXT PRIMARY KEY,' +
    '  id_recuento INTEGER,' +
    '  codigo_barras TEXT,' +
    '  codigo_articulo TEXT,' +
    '  codigo_unidad TEXT,' +
    '  cantidad REAL,' +
    '  lote TEXT,' +
    '  fecha_caducidad TEXT,' +
    '  instante_recuento TEXT,' +
    '  zona TEXT,' +
    '  subido INTEGER DEFAULT 0)');
end;

procedure TRecuentoLocal.Encolar(AIdRecuento: Int64;
  const AEvento: TEventoRec);
begin
  // INSERT OR IGNORE: si el uuid ya estaba (reintento del propio cliente), no
  // se duplica la fila.
  FConn.ExecSQL(
    'INSERT OR IGNORE INTO eventos (uuid, id_recuento, codigo_barras,' +
    ' codigo_articulo, codigo_unidad, cantidad, lote, fecha_caducidad,' +
    ' instante_recuento, zona, subido) VALUES' +
    ' (:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,0)',
    [AEvento.Uuid, AIdRecuento, AEvento.CodigoBarras, AEvento.CodigoArticulo,
     AEvento.CodigoUnidad, AEvento.Cantidad, AEvento.Lote,
     AEvento.FechaCaducidad, AEvento.InstanteRecuento, AEvento.Zona]);
end;

function TRecuentoLocal.ContarPendientes(AIdRecuento: Int64): Integer;
var
  oQry: TUniQuery;
begin
  Result := 0;
  oQry := TUniQuery.Create(nil);
  try
    oQry.Connection := FConn;
    oQry.SQL.Text :=
      'SELECT COUNT(*) AS N FROM eventos' +
      ' WHERE id_recuento = :ID AND subido = 0';
    oQry.ParamByName('ID').AsLargeInt := AIdRecuento;
    oQry.Open;
    if not oQry.IsEmpty then
      Result := oQry.FieldByName('N').AsInteger;
  finally
    FreeAndNil(oQry);
  end;
end;

function TRecuentoLocal.LeerLote(AIdRecuento: Int64;
  AMaxFilas: Integer): TArrEvento;
var
  oQry: TUniQuery;
  Rec: TEventoRec;
begin
  SetLength(Result, 0);
  oQry := TUniQuery.Create(nil);
  try
    oQry.Connection := FConn;
    oQry.SQL.Text :=
      'SELECT * FROM eventos WHERE id_recuento = :ID AND subido = 0' +
      ' ORDER BY instante_recuento LIMIT :MAX';
    oQry.ParamByName('ID').AsLargeInt := AIdRecuento;
    oQry.ParamByName('MAX').AsInteger := AMaxFilas;
    oQry.Open;
    while not oQry.Eof do
    begin
      Rec.Uuid             := oQry.FieldByName('uuid').AsString;
      Rec.CodigoBarras     := oQry.FieldByName('codigo_barras').AsString;
      Rec.CodigoArticulo   := oQry.FieldByName('codigo_articulo').AsString;
      Rec.CodigoUnidad     := oQry.FieldByName('codigo_unidad').AsString;
      Rec.Cantidad         := oQry.FieldByName('cantidad').AsFloat;
      Rec.Lote             := oQry.FieldByName('lote').AsString;
      Rec.FechaCaducidad   := oQry.FieldByName('fecha_caducidad').AsString;
      Rec.InstanteRecuento := oQry.FieldByName('instante_recuento').AsString;
      Rec.Zona             := oQry.FieldByName('zona').AsString;
      Result := Result + [Rec];
      oQry.Next;
    end;
  finally
    FreeAndNil(oQry);
  end;
end;

procedure TRecuentoLocal.MarcarSubidos(const AUuids: TArray<string>);
var
  i: Integer;
begin
  for i := 0 to High(AUuids) do
    FConn.ExecSQL('UPDATE eventos SET subido = 1 WHERE uuid = :1',
                  [AUuids[i]]);
end;

function TRecuentoLocal.ContarPorSku(AIdRecuento: Int64;
  const ASku: string): Double;
var
  oQry: TUniQuery;
begin
  Result := 0;
  oQry := TUniQuery.Create(nil);
  try
    oQry.Connection := FConn;
    oQry.SQL.Text :=
      'SELECT COALESCE(SUM(cantidad),0) AS T FROM eventos' +
      ' WHERE id_recuento = :ID AND codigo_unidad = :SKU';
    oQry.ParamByName('ID').AsLargeInt := AIdRecuento;
    oQry.ParamByName('SKU').AsString := ASku;
    oQry.Open;
    if not oQry.IsEmpty then
      Result := oQry.FieldByName('T').AsFloat;
  finally
    FreeAndNil(oQry);
  end;
end;

initialization
  {$IFNDEF VIRACASH_MOVIL}
  oLocal := TRecuentoLocal.Create;
  {$ENDIF}

finalization
  FreeAndNil(oLocal);

end.
