{******************************************************************************}
{  Módulo:       inLibTicketLotes                                              }
{    Tipo:       Librería                                                      }
{   Fecha:       07/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Copias del ticket: oculta y agrupa lotes sin modificar la factura.        }
{    Las series se conservan para identificar las garantías.                   }
{******************************************************************************}
unit inLibTicketLotes;

interface

uses
  Data.DB, Datasnap.DBClient, inLibTicketsCajaIntf;

const
  PARAMETRO_IMPRIMIR_LOTES_TICKET = 'vgerImprimirLoteCaducidadTicket';

function ClaveAgrupacionTicket(ALinea: TDataSet): string;
function PrepararLineasTicket(ALineas: TDataSet;
  AImprimirLotes: Boolean): TClientDataSet;
function AgruparLotesTicket(const ALineas: TArray<TLineaTicketCaja>;
  AImprimirLotes: Boolean): TArray<TLineaTicketCaja>;

implementation

uses
  System.SysUtils, System.Variants, System.Generics.Collections;

function ClaveAgrupacionTicket(ALinea: TDataSet): string;
const
  Campos: array[0..12] of string = (
    'CODIGO_ART_FACLIN', 'CODIGO_UNIDAD_FACLIN',
    'DESCRIPCION_ARTICULO_FACLIN', 'TIPO_CANTIDAD_ARTICULO_FACLIN',
    'PRECIO_SALIDA_FACLIN', 'PORCENTAJE_DTO_FACLIN', 'PRECIO_DTO_FACLIN',
    'PRECIO_VENTA_SIVA_ARTICULO_FACLIN',
    'PRECIO_VENTA_CIVA_ARTICULO_FACLIN', 'TIPO_IVA_ARTICULO_FACLIN',
    'PORCENTAJE_IVA_FACLIN', 'CODIGO_TAR_FACLIN', 'VIENE_DE_DEPOSITO');
var
  Nombre, Valor: string;
  Campo: TField;
begin
  Result := '';
  for Nombre in Campos do
  begin
    Campo := ALinea.FindField(Nombre);
    Valor := '';
    if Assigned(Campo) then
      Valor := VarToStr(Campo.Value);
    Result := Result + IntToStr(Length(Valor)) + ':' + Valor;
  end;
  Result := Result + BoolToStr(
    ALinea.FieldByName('CANTIDAD_FACLIN').AsFloat < 0, True);
end;

function EsSerieTicket(ALinea: TDataSet): Boolean;
var
  Campo: TField;
begin
  Campo := ALinea.FindField('ESSERIE_LOTE');
  Result := Assigned(Campo) and SameText(Campo.AsString, 'S');
end;

function PrepararLineasTicket(ALineas: TDataSet;
  AImprimirLotes: Boolean): TClientDataSet;
var
  Campo: TField;
  Marca: TBookmark;
  Clave: string;
  Grupos: TDictionary<string, Integer>;
  Agrupar: Boolean;
begin
  Result := TClientDataSet.Create(nil);
  Grupos := TDictionary<string, Integer>.Create;
  ALineas.DisableControls;
  Marca := ALineas.Bookmark;
  try
    try
      for Campo in ALineas.Fields do
        Result.FieldDefs.Add(Campo.FieldName, Campo.DataType, Campo.Size);
      Result.CreateDataSet;
      ALineas.First;
      while not ALineas.Eof do
      begin
        Campo := ALineas.FindField('LOTE_FACLIN');
        Agrupar := not AImprimirLotes and Assigned(Campo) and
          (Trim(Campo.AsString) <> '') and not EsSerieTicket(ALineas);
        Clave := ClaveAgrupacionTicket(ALineas);
        if Agrupar and Grupos.ContainsKey(Clave) then
        begin
          Result.RecNo := Grupos[Clave];
          Result.Edit;
          for Campo in ALineas.Fields do
            if (Campo.FieldName = 'CANTIDAD_FACLIN') or
               Campo.FieldName.StartsWith('TOTAL_') then
              Result.FieldByName(Campo.FieldName).Value :=
                Result.FieldByName(Campo.FieldName).Value + Campo.Value;
        end
        else
        begin
          Result.Append;
          for Campo in ALineas.Fields do
            Result.FieldByName(Campo.FieldName).Value := Campo.Value;
        end;
        if Agrupar then
        begin
          Result.FieldByName('LOTE_FACLIN').Clear;
          if Result.FindField('DESCRIPCION_PRINT_FACLIN') <> nil then
            Result.FieldByName('DESCRIPCION_PRINT_FACLIN').AsString :=
              Result.FieldByName('DESCRIPCION_ARTICULO_FACLIN').AsString +
              sLineBreak +
              Result.FieldByName('CODIGO_UNIDAD_FACLIN').AsString;
          if Result.FindField('FECHA_CADUCIDAD_FACLIN') <> nil then
            Result.FieldByName('FECHA_CADUCIDAD_FACLIN').Clear;
        end;
        Result.Post;
        if Agrupar then
          Grupos.AddOrSetValue(Clave, Result.RecNo);
        ALineas.Next;
      end;
      Result.First;
    except
      FreeAndNil(Result);
      raise;
    end;
  finally
    if ALineas.BookmarkValid(Marca) then
      ALineas.Bookmark := Marca;
    ALineas.EnableControls;
    Grupos.Free;
  end;
end;

function AgruparLotesTicket(const ALineas: TArray<TLineaTicketCaja>;
  AImprimirLotes: Boolean): TArray<TLineaTicketCaja>;
var
  Linea: TLineaTicketCaja;
  Grupos: TDictionary<string, Integer>;
  Indice, Numero: Integer;
  Agrupar: Boolean;
begin
  Result := [];
  Grupos := TDictionary<string, Integer>.Create;
  try
    for Numero := 0 to High(ALineas) do
    begin
      Linea := ALineas[Numero];
      Agrupar := not AImprimirLotes and not Linea.EsSerie and
        (Linea.Lote <> '') and (Linea.ClaveAgrupacion <> '');
      if Agrupar and Grupos.TryGetValue(Linea.ClaveAgrupacion, Indice) then
      begin
        Result[Indice].Cantidad := Result[Indice].Cantidad + Linea.Cantidad;
        Result[Indice].Total := Result[Indice].Total + Linea.Total;
      end
      else
      begin
        if Agrupar then
        begin
          Linea.Lote := '';
          Linea.FechaCaducidad := 0;
          Grupos.Add(Linea.ClaveAgrupacion, Length(Result));
        end;
        Result := Result + [Linea];
      end;
    end;
  finally
    Grupos.Free;
  end;
end;

end.
