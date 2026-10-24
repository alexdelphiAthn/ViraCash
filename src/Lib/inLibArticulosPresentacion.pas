{******************************************************************************}
{                                                                              }
{  Modulo:       inLibArticulosPresentacion                                    }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Decisiones de la pantalla de articulos que no necesitan VCL ni BBDD:      }
{    estado del filtro de carga, verificacion de codigos de barras, lista de   }
{    SKU del alta de tarifas, etiquetas de origen y color hexadecimal.         }
{******************************************************************************}
unit inLibArticulosPresentacion;

interface

uses
  inLibArticulosFiltro,
  inLibArticulosPresentacionIntf;

type
  // Recuento de la verificacion de codigos de barras de un articulo.
  TResumenCodigosBarrasArticulo = record
    Ean13Correctos: Integer;
    Ean8Correctos: Integer;
    Invalidos: Integer;
    Omitidos: Integer;
    DetalleErrores: string;
  end;

// Traduccion entre el indice del combo de estado y el codigo de perfil.
function IndiceEstadoFiltroDesdeCodigo(const ACodigo: string): Integer;
function CodigoEstadoFiltroDesdeIndice(AIndice: Integer): string;
function EstadoFiltroArticulosDesdeIndice(
  AIndice: Integer): TEstadoFiltroArticulos;
// CSV con ';' de los valores marcados, en el orden recibido.
function ComponerCsvSeleccion(const AValores: TArray<string>): string;
// Recuento y detalle de los codigos de barras de un articulo.
function VerificarCodigosBarrasArticulo(
  const ACodigos: TCodigosBarrasArticulo): TResumenCodigosBarrasArticulo;
// Lista que ve el modal de alta de precios: articulo, ARTICULO/COLOR y,
// debajo de cada color, sus SKU; después, ARTICULO/*/TALLA sin color, en el
// orden de la colección y con sus tallas aún sin SKU (FZ-ISSUE-637).
function ComponerListaSkusAltaTarifa(
  const ACodigoArticulo: string;
  const ADetalles: TDetallesSkuTarifaArticulo;
  const ATallasColeccion: TArray<string> = nil):
    TOpcionesSkuTarifaArticulo;
// Texto visible de FUENTE_ATB ('A', 'C', 'G').
function EtiquetaFuenteAtributoBasico(const ACodigo: string): string;
// '#RRGGBB' -> componentes. False si el texto no es un hex valido.
function DescomponerHexAtributo(const AHex: string;
  out ARojo, AVerde, AAzul: Integer): Boolean;
function ComponerHexAtributo(ARojo, AVerde, AAzul: Integer): string;
// Luminancia percibida por debajo del umbral de texto blanco.
function EsColorOscuroAtributo(ARojo, AVerde, AAzul: Integer): Boolean;

implementation

uses
  System.SysUtils, System.Classes,
  inLibEAN13,
  inLibArticulosAltaTarifas,
  inLibMsgArticulos;

const
  // Prefijo de los codigos provisionales pendientes de rellenar.
  PREFIJO_CODIGO_PENDIENTE = '_FAB_';
  LONGITUD_HEX = 7;
  UMBRAL_LUMINANCIA_OSCURA = 128;

function IndiceEstadoFiltroDesdeCodigo(const ACodigo: string): Integer;
begin
  if SameText(ACodigo, 'T') then
    Result := 0
  else if SameText(ACodigo, 'N') then
    Result := 2
  else
    // 'S' o cualquier valor desconocido: solo activos.
    Result := 1;
end;

function CodigoEstadoFiltroDesdeIndice(AIndice: Integer): string;
begin
  case AIndice of
    0:
      Result := 'T';
    2:
      Result := 'N';
  else
    Result := 'S';
  end;
end;

function EstadoFiltroArticulosDesdeIndice(
  AIndice: Integer): TEstadoFiltroArticulos;
begin
  case AIndice of
    1:
      Result := efaActivos;
    2:
      Result := efaInactivos;
  else
    Result := efaTodos;
  end;
end;

function ComponerCsvSeleccion(const AValores: TArray<string>): string;
var
  iValor: Integer;
begin
  Result := '';
  for iValor := 0 to High(AValores) do
  begin
    if Result <> '' then
      Result := Result + ';';
    Result := Result + AValores[iValor];
  end;
end;

function VerificarCodigosBarrasArticulo(
  const ACodigos: TCodigosBarrasArticulo): TResumenCodigosBarrasArticulo;
var
  iFila: Integer;
  oFila: TCodigoBarrasSkuArticulo;
begin
  Result := Default(TResumenCodigosBarrasArticulo);
  for iFila := 0 to High(ACodigos) do
  begin
    oFila := ACodigos[iFila];
    // Los placeholders pendientes de rellenar no cuentan como error.
    if (oFila.Codigo = '') or
       (Pos(PREFIJO_CODIGO_PENDIENTE, oFila.Codigo) = 1) then
      Inc(Result.Omitidos)
    else if (Length(oFila.Codigo) = 13) and
            EsEAN13Valido(oFila.Codigo) then
      Inc(Result.Ean13Correctos)
    else if (Length(oFila.Codigo) = 8) and
            EsEAN8Valido(oFila.Codigo) then
      Inc(Result.Ean8Correctos)
    else
    begin
      Inc(Result.Invalidos);
      Result.DetalleErrores := Result.DetalleErrores + sLineBreak +
        Format(SErrorDetalleCodigoBarrasInvalido,
          [oFila.Codigo, oFila.Sku, oFila.Tipo, Length(oFila.Codigo)]);
    end;
  end;
end;

procedure AnadirTallasCualquierColor(const ACodigoArticulo: string;
  const ADetalles: TDetallesSkuTarifaArticulo;
  const ATallasColeccion: TArray<string>;
  var AOpciones: TOpcionesSkuTarifaArticulo);
var
  oTallas: TStringList;
  oDetalle: TDetalleSkuTarifaArticulo;
  sTalla: string;

  procedure AnadirTalla(const ATalla: string);
  var
    iOpcion: Integer;
  begin
    if (ATalla <> '') and (oTallas.IndexOf(ATalla) < 0) then
    begin
      oTallas.Add(ATalla);
      iOpcion := Length(AOpciones);
      SetLength(AOpciones, iOpcion + 1);
      AOpciones[iOpcion].CodigoSku :=
        Trim(ACodigoArticulo) + '/*/' + ATalla;
      AOpciones[iOpcion].Talla := ATalla;
      AOpciones[iOpcion].EsTalla := True;
    end;
  end;

begin
  oTallas := TStringList.Create;
  try
    oTallas.CaseSensitive := False;
    // Las filas ART/*/TALLA son reglas de precio, no SKU: la colección
    // permite fijar el precio de las tallas que aún no se han comprado.
    for sTalla in ATallasColeccion do
      AnadirTalla(Trim(sTalla));
    for oDetalle in ADetalles do
      AnadirTalla(Trim(oDetalle.Talla));
  finally
    FreeAndNil(oTallas);
  end;
end;

function ComponerListaSkusAltaTarifa(
  const ACodigoArticulo: string;
  const ADetalles: TDetallesSkuTarifaArticulo;
  const ATallasColeccion: TArray<string>):
    TOpcionesSkuTarifaArticulo;
var
  iDetalle: Integer;
  iOpcion: Integer;
  sCodigoColor: string;
  sCodigoDetalle: string;
  sColor: string;
  sTalla: string;

  function IndiceOpcion(
    const AOpciones: TOpcionesSkuTarifaArticulo;
    const ACodigoSku: string): Integer;
  var
    iBusqueda: Integer;
  begin
    Result := -1;
    iBusqueda := 0;
    while (iBusqueda < Length(AOpciones)) and (Result = -1) do
    begin
      if SameText(AOpciones[iBusqueda].CodigoSku, ACodigoSku) then
        Result := iBusqueda
      else
        Inc(iBusqueda);
    end;
  end;
begin
  SetLength(Result, 1);
  // La fila del propio articulo siempre encabeza la lista del modal.
  Result[0].CodigoSku := cSkuFilaArticulo;
  for iDetalle := 0 to High(ADetalles) do
  begin
    sColor := Trim(ADetalles[iDetalle].Color);
    if sColor <> '' then
    begin
      sCodigoColor := Trim(ACodigoArticulo) + '/' + sColor;
      iOpcion := IndiceOpcion(Result, sCodigoColor);
      if iOpcion = -1 then
      begin
        iOpcion := Length(Result);
        SetLength(Result, iOpcion + 1);
        Result[iOpcion].CodigoSku := sCodigoColor;
        Result[iOpcion].Color := sColor;
        Result[iOpcion].HexColor := ADetalles[iDetalle].HexColor;
      end
      else if Result[iOpcion].HexColor = '' then
        Result[iOpcion].HexColor := ADetalles[iDetalle].HexColor;
      sCodigoDetalle := Trim(ADetalles[iDetalle].CodigoSku);
      sTalla := Trim(ADetalles[iDetalle].Talla);
      if (sTalla <> '') and (sCodigoDetalle <> '') and
         (not SameText(sCodigoDetalle, sCodigoColor)) and
         (IndiceOpcion(Result, sCodigoDetalle) = -1) then
      begin
        iOpcion := Length(Result);
        SetLength(Result, iOpcion + 1);
        Result[iOpcion].CodigoSku := sCodigoDetalle;
        Result[iOpcion].Color := sColor;
        Result[iOpcion].HexColor := ADetalles[iDetalle].HexColor;
        Result[iOpcion].Talla := sTalla;
        Result[iOpcion].EsTalla := True;
      end;
    end;
  end;
  AnadirTallasCualquierColor(ACodigoArticulo, ADetalles,
    ATallasColeccion, Result);

end;

function EtiquetaFuenteAtributoBasico(const ACodigo: string): string;
begin
  // 'A' = override por articulo, 'C' = conjunto del articulo, 'G' = global.
  if ACodigo = 'A' then
    Result := 'Artículo'
  else if ACodigo = 'C' then
    Result := 'Conjunto'
  else if ACodigo = 'G' then
    Result := 'Global'
  else
    Result := '';
end;

function DescomponerHexAtributo(const AHex: string;
  out ARojo, AVerde, AAzul: Integer): Boolean;
var
  sHex: string;
begin
  ARojo := 0;
  AVerde := 0;
  AAzul := 0;
  sHex := Trim(AHex);
  Result := (Length(sHex) = LONGITUD_HEX) and (sHex[1] = '#');
  if Result then
  begin
    try
      ARojo := StrToInt('$' + Copy(sHex, 2, 2));
      AVerde := StrToInt('$' + Copy(sHex, 4, 2));
      AAzul := StrToInt('$' + Copy(sHex, 6, 2));
    except
      on EConvertError do
        Result := False;
    end;
  end;
end;

function ComponerHexAtributo(ARojo, AVerde, AAzul: Integer): string;
begin
  Result := Format('#%.2X%.2X%.2X', [ARojo, AVerde, AAzul]);
end;

function EsColorOscuroAtributo(ARojo, AVerde, AAzul: Integer): Boolean;
var
  dLuminancia: Double;
begin
  dLuminancia := (ARojo * 0.299) + (AVerde * 0.587) + (AAzul * 0.114);
  Result := dLuminancia < UMBRAL_LUMINANCIA_OSCURA;
end;

end.
