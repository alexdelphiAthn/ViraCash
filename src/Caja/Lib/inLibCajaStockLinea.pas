{******************************************************************************}
{  Módulo:       inLibCajaStockLinea                                           }
{    Tipo:       Librería                                                      }
{   Fecha:       11/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción: Vigila que las unidades de un SKU en el ticket de caja no      }
{               superen el stock de la tienda (FZ-ISSUE-424). Avisa o bloquea  }
{               según la política de stock de caja.                            }
{******************************************************************************}
unit inLibCajaStockLinea;

interface

uses
  System.SysUtils, Data.DB, inLibCajaVentaIntf;

type
  IVigilanteStockVentaCaja = interface
    ['{5B2F6C0E-3D41-4E0B-9B6C-7A1F0C8D4E21}']
    // Al identificar un artículo (lector o tecleado): una unidad más.
    function ComprobarUnidadMas(ALineas: TDataSet;
      const ACodigoSku: string): TResultadoPoliticaStockVenta;
    // Al grabar la línea: lo que esa línea deja vendido del SKU.
    function ComprobarLinea(
      ALinea: TDataSet): TResultadoPoliticaStockVenta;
    // Ticket nuevo: lo comprobado en el anterior ya no cuenta.
    procedure Reiniciar;
  end;

function CrearVigilanteStockVentaCaja(
  const APolitica: TFunc<IPoliticaStockVenta>;
  const AObtenerAlmacen: TFunc<string>): IVigilanteStockVentaCaja;

implementation

uses
  System.Generics.Collections, Datasnap.DBClient;

const
  CAMPO_SKU = 'CODIGO_UNIDAD_FACLIN';
  CAMPO_LINEA = 'LINEA_FACLIN';
  CAMPO_CANTIDAD = 'CANTIDAD_FACLIN';
  TOLERANCIA_CANTIDAD = 0.0000005;

type
  TVigilanteStockVentaCaja = class(
    TInterfacedObject,
    IVigilanteStockVentaCaja)
  private
    FPolitica: TFunc<IPoliticaStockVenta>;
    FObtenerAlmacen: TFunc<string>;
    // Unidades de cada SKU ya comprobadas en este ticket: solo se vuelve
    // a preguntar a la política cuando el total sube.
    FComprobado: TDictionary<string, Double>;
    function UnidadesOtrasLineas(ALineas: TDataSet;
      const ACodigoSku, ALineaExcluida: string): Double;
    function Comprobar(const ACodigoSku: string;
      ATotal: Double): TResultadoPoliticaStockVenta;
  public
    constructor Create(
      const APolitica: TFunc<IPoliticaStockVenta>;
      const AObtenerAlmacen: TFunc<string>);
    destructor Destroy; override;
    function ComprobarUnidadMas(ALineas: TDataSet;
      const ACodigoSku: string): TResultadoPoliticaStockVenta;
    function ComprobarLinea(
      ALinea: TDataSet): TResultadoPoliticaStockVenta;
    procedure Reiniciar;
  end;

function SinIncidencia: TResultadoPoliticaStockVenta;
begin
  Result.Permitida := True;
  Result.Motivo := msvNinguno;
  Result.Mensaje := '';
end;

constructor TVigilanteStockVentaCaja.Create(
  const APolitica: TFunc<IPoliticaStockVenta>;
  const AObtenerAlmacen: TFunc<string>);
begin
  inherited Create;
  if not Assigned(APolitica) then
    raise EArgumentNilException.Create('APolitica');
  if not Assigned(AObtenerAlmacen) then
    raise EArgumentNilException.Create('AObtenerAlmacen');
  FPolitica := APolitica;
  FObtenerAlmacen := AObtenerAlmacen;
  FComprobado := TDictionary<string, Double>.Create;
end;

destructor TVigilanteStockVentaCaja.Destroy;
begin
  FreeAndNil(FComprobado);
  inherited;
end;

procedure TVigilanteStockVentaCaja.Reiniciar;
begin
  FComprobado.Clear;
end;

// En un clon: no mueve el cursor de la rejilla ni dispara sus eventos. La
// línea en edición aún no está en el clon con su valor nuevo, por eso se
// excluye por su número y se suma aparte.
function TVigilanteStockVentaCaja.UnidadesOtrasLineas(ALineas: TDataSet;
  const ACodigoSku, ALineaExcluida: string): Double;
var
  oClon: TClientDataSet;
begin
  Result := 0;
  if (ALineas is TClientDataSet) and ALineas.Active then
  begin
    oClon := TClientDataSet.Create(nil);
    try
      oClon.CloneCursor(TClientDataSet(ALineas), True);
      oClon.First;
      while not oClon.Eof do
      begin
        if SameText(Trim(oClon.FieldByName(CAMPO_SKU).AsString),
             ACodigoSku) and
           ((ALineaExcluida = '') or
            (oClon.FieldByName(CAMPO_LINEA).AsString <> ALineaExcluida))
        then
          Result := Result + oClon.FieldByName(CAMPO_CANTIDAD).AsFloat;
        oClon.Next;
      end;
    finally
      FreeAndNil(oClon);
    end;
  end;
end;

function TVigilanteStockVentaCaja.Comprobar(const ACodigoSku: string;
  ATotal: Double): TResultadoPoliticaStockVenta;
var
  dComprobado: Double;
  sClave: string;
begin
  Result := SinIncidencia;
  sClave := UpperCase(ACodigoSku);
  if not FComprobado.TryGetValue(sClave, dComprobado) then
    dComprobado := 0;
  if ATotal > dComprobado + TOLERANCIA_CANTIDAD then
  begin
    Result := FPolitica().ValidarCantidad(ACodigoSku, FObtenerAlmacen(),
      ATotal);
    if Result.Permitida then
      FComprobado.AddOrSetValue(sClave, ATotal);
  end;
end;

function TVigilanteStockVentaCaja.ComprobarUnidadMas(ALineas: TDataSet;
  const ACodigoSku: string): TResultadoPoliticaStockVenta;
var
  sSku: string;
begin
  Result := SinIncidencia;
  sSku := Trim(ACodigoSku);
  if sSku <> '' then
    Result := Comprobar(sSku,
      UnidadesOtrasLineas(ALineas, sSku, '') + 1);
end;

function TVigilanteStockVentaCaja.ComprobarLinea(
  ALinea: TDataSet): TResultadoPoliticaStockVenta;
var
  sSku: string;
  dCantidad: Double;
begin
  Result := SinIncidencia;
  sSku := Trim(ALinea.FieldByName(CAMPO_SKU).AsString);
  dCantidad := ALinea.FieldByName(CAMPO_CANTIDAD).AsFloat;
  // Devoluciones (cantidad negativa) y líneas sin SKU no consumen stock.
  if (sSku <> '') and (dCantidad > 0) then
    Result := Comprobar(sSku, dCantidad + UnidadesOtrasLineas(ALinea, sSku,
      ALinea.FieldByName(CAMPO_LINEA).AsString));
end;

function CrearVigilanteStockVentaCaja(
  const APolitica: TFunc<IPoliticaStockVenta>;
  const AObtenerAlmacen: TFunc<string>): IVigilanteStockVentaCaja;
begin
  Result := TVigilanteStockVentaCaja.Create(APolitica, AObtenerAlmacen);
end;

end.
