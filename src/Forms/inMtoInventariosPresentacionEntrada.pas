{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoInventariosPresentacionEntrada                           }
{    Tipo:       Presentacion (sin formulario)                                 }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Edicion de atributos de una linea de inventario: selector de valor con    }
{    paleta, reconstruccion del SKU y volcado de atributos desde el SKU.       }
{    Recibe dataset y puertos; nunca el formulario.                            }
{******************************************************************************}
unit inMtoInventariosPresentacionEntrada;

interface

uses
  System.Classes,
  Vcl.Graphics,
  Data.DB,
  Uni,
  cxEdit,
  inLibArticulosAtributosIntf;

type
  TGenerarSkuInventario = reference to function(
    const ACodigoArticulo: string): string;
  TRellenarStockInventario = reference to procedure(
    const ACodigoUnidad: string);

  // Dependencias minimas para reconstruir el SKU de la linea activa.
  TEscrituraAtributoInventario = record
    Lineas: TDataSet;
    GenerarSku: TGenerarSkuInventario;
    RellenarStock: TRellenarStockInventario;
  end;

// Reconstruye CODIGO_UNIDAD_INVLIN desde los ATTRn de la linea y, si el
// SKU queda cerrado, recarga teorico y PMP.
procedure ReconstruirSkuLineaInventario(
  const AContexto: TEscrituraAtributoInventario);
// Escribe ATTRn_VALOR en la linea activa y reconstruye el SKU. Devuelve
// False si la posicion no es valida o la linea no admite edicion.
function EscribirValorAtributoInventario(
  const AContexto: TEscrituraAtributoInventario;
  AOrden: Integer; const AValor: string): Boolean;
// Valores de atributo validos para (articulo padre, posicion), en el
// ORDEN_AV de la paleta.
function ValoresAtributoInventario(
  const ALookup: IArticulosAtributosLookup;
  const ACodigoArticulo: string; AOrden: Integer): TArray<string>;
// Vuelca los valores del SKU en ATTR1..ATTR5 de la linea en edicion.
procedure RellenarAtributosDesdeSkuInventario(
  const ALookup: IArticulosAtributosLookup;
  ALineas: TDataSet; const ACodigoSku: string);
// Glyph con el color del AV actual y auto-apertura del selector cuando la
// celda esta vacia.
procedure ConfigurarEditorAtributoInventario(
  AConexion: TUniConnection; ALineas: TDataSet; AOrden: Integer;
  AEdit: TcxCustomEdit; ABitmap: TBitmap; AAlEntrar: TNotifyEvent);
// Selector de AV con cuadradito de paleta anclado bajo el editor.
function SeleccionarValorAtributoInventario(
  AConexion: TUniConnection; ALineas: TDataSet; AOrden: Integer;
  const AValores: TArray<string>; AEditor: TObject;
  out AValor: string): Boolean;

implementation

uses
  System.SysUtils,
  System.Types,
  System.Generics.Collections,
  Vcl.Controls,
  cxButtonEdit,
  inLibAtributosPaleta,
  inLibInventariosPresentacion,
  inLibInventariosPresentacionIntf;

const
  CAMPO_ARTICULO_LINEA = 'CODIGO_ART_INVLIN';
  CAMPO_UNIDAD_LINEA = 'CODIGO_UNIDAD_INVLIN';
  CAMPO_NUM_ATRIBUTOS_LINEA = 'NUM_ATRIBUTOS_REQ_INV_LINEA';

function CampoValorAtributo(AOrden: Integer): string;
begin
  Result := 'ATTR' + IntToStr(AOrden) + '_VALOR';
end;

function CampoNombreAtributo(AOrden: Integer): string;
begin
  Result := 'ATTR' + IntToStr(AOrden) + '_NOMBRE';
end;

procedure ReconstruirSkuLineaInventario(
  const AContexto: TEscrituraAtributoInventario);
var
  sSku: string;
begin
  if Assigned(AContexto.GenerarSku) then
  begin
    sSku := SkuEfectivoInventario(
      AContexto.GenerarSku(AContexto.Lineas.FieldByName(
        CAMPO_ARTICULO_LINEA).AsString),
      AContexto.Lineas.FieldByName(CAMPO_ARTICULO_LINEA).AsString);
    AContexto.Lineas.FieldByName(CAMPO_UNIDAD_LINEA).AsString := sSku;
    if EsSkuCompletoInventario(sSku,
         AContexto.Lineas.FieldByName(
           CAMPO_NUM_ATRIBUTOS_LINEA).AsInteger,
         AContexto.Lineas.FieldByName(CAMPO_ARTICULO_LINEA).AsString) and
       Assigned(AContexto.RellenarStock) then
      AContexto.RellenarStock(sSku);
  end;
end;

function EscribirValorAtributoInventario(
  const AContexto: TEscrituraAtributoInventario;
  AOrden: Integer; const AValor: string): Boolean;
begin
  Result := (AOrden >= 1) and (AOrden <= MAX_ATRIBUTOS_INVENTARIO) and
            (AContexto.Lineas <> nil) and AContexto.Lineas.Active and
            (not AContexto.Lineas.IsEmpty);
  if Result then
  begin
    if AContexto.Lineas.State = dsBrowse then
      AContexto.Lineas.Edit;
    Result := AContexto.Lineas.State in [dsEdit, dsInsert];
  end;
  if Result then
  begin
    AContexto.Lineas.FieldByName(
      CampoValorAtributo(AOrden)).AsString := AValor;
    ReconstruirSkuLineaInventario(AContexto);
  end;
end;

function ValoresAtributoInventario(
  const ALookup: IArticulosAtributosLookup;
  const ACodigoArticulo: string; AOrden: Integer): TArray<string>;
var
  Valores: TArray<TArticuloAtributoValor>;
  iValor: Integer;
begin
  SetLength(Result, 0);
  if Assigned(ALookup) and (Trim(ACodigoArticulo) <> '') and
     (AOrden >= 1) and (AOrden <= MAX_ATRIBUTOS_INVENTARIO) then
  begin
    Valores := ALookup.ObtenerAvsEnSkus(ACodigoArticulo, AOrden);
    SetLength(Result, Length(Valores));
    for iValor := 0 to High(Valores) do
      Result[iValor] := Valores[iValor].Valor;
  end;
end;

procedure RellenarAtributosDesdeSkuInventario(
  const ALookup: IArticulosAtributosLookup;
  ALineas: TDataSet; const ACodigoSku: string);
var
  Valores: TArray<TArticuloAtributoValor>;
  Valor: TArticuloAtributoValor;
begin
  if Assigned(ALookup) and (ACodigoSku <> '') and (ALineas <> nil) and
     (ALineas.State in [dsEdit, dsInsert]) then
  begin
    // Los valores se mapean por ORDEN_VISUAL_ATRIBUTO (= ORDEN_VA).
    Valores := ALookup.ObtenerAtributosDeSku(ACodigoSku);
    for Valor in Valores do
    begin
      if (Valor.Orden >= 1) and
         (Valor.Orden <= MAX_ATRIBUTOS_INVENTARIO) then
        ALineas.FieldByName(
          CampoValorAtributo(Valor.Orden)).AsString := Valor.Valor;
    end;
  end;
end;

function IdVariacionAtributo(
  AConexion: TUniConnection; const ANombreAtributo: string): string;
var
  Mapa: TDictionary<string, string>;
begin
  Result := '';
  Mapa := ObtenerMapaAtributosGlobal(AConexion);
  if Mapa <> nil then
    Mapa.TryGetValue(UpperCase(Trim(ANombreAtributo)), Result);
end;

procedure ConfigurarEditorAtributoInventario(
  AConexion: TUniConnection; ALineas: TDataSet; AOrden: Integer;
  AEdit: TcxCustomEdit; ABitmap: TBitmap; AAlEntrar: TNotifyEvent);
var
  oEditor: TcxButtonEdit;
  oBoton: TcxEditButton;
  sValorActual: string;
  sNombreAtributo: string;
  sIdVariacion: string;
  Info: TInfoBasico;
begin
  // (1) Glyph del boton = cuadradito del color del AV actual si esta en
  //     la paleta basica; si no, el boton vuelve a su look [...].
  // (2) Celda vacia: se auto-abre el selector al entrar.
  if (AOrden >= 1) and (AOrden <= MAX_ATRIBUTOS_INVENTARIO) and
     (AEdit is TcxButtonEdit) then
  begin
    oEditor := TcxButtonEdit(AEdit);
    if oEditor.Properties.Buttons.Count > 0 then
    begin
      oBoton := oEditor.Properties.Buttons[0];
      sValorActual := '';
      sNombreAtributo := '';
      if (ALineas <> nil) and ALineas.Active and
         (not ALineas.IsEmpty) then
      begin
        sValorActual := ALineas.FieldByName(
          CampoValorAtributo(AOrden)).AsString;
        sNombreAtributo := ALineas.FieldByName(
          CampoNombreAtributo(AOrden)).AsString;
      end;
      sIdVariacion := IdVariacionAtributo(AConexion, sNombreAtributo);
      Info := Default(TInfoBasico);
      if (sIdVariacion <> '') and (Trim(sValorActual) <> '') then
        ObtenerInfoBasico(AConexion, sIdVariacion, sValorActual, Info);
      if Info.EsValido and PintarSwatchEnBitmap(ABitmap, Info, 14) then
      begin
        oBoton.Glyph.Assign(ABitmap);
        oBoton.Kind := bkGlyph;
      end
      else
        oBoton.Kind := bkEllipsis;
      if Trim(sValorActual) = '' then
        oEditor.OnEnter := AAlEntrar
      else
        oEditor.OnEnter := nil;
    end;
  end;
end;

function SeleccionarValorAtributoInventario(
  AConexion: TUniConnection; ALineas: TDataSet; AOrden: Integer;
  const AValores: TArray<string>; AEditor: TObject;
  out AValor: string): Boolean;
var
  sValorActual: string;
  sIdVariacion: string;
  oControl: TWinControl;
  Punto: TPoint;
  iAncho: Integer;
begin
  AValor := '';
  sValorActual := ALineas.FieldByName(
    CampoValorAtributo(AOrden)).AsString;
  sIdVariacion := IdVariacionAtributo(AConexion,
    ALineas.FieldByName(CampoNombreAtributo(AOrden)).AsString);
  // Posicion donde sale el "desplegable": justo debajo del editor.
  Punto.X := -1;
  Punto.Y := -1;
  iAncho := 120;
  if AEditor is TWinControl then
  begin
    oControl := TWinControl(AEditor);
    Punto := oControl.ClientToScreen(Point(0, oControl.Height));
    iAncho := oControl.Width;
  end;
  Result := SeleccionarAvConPaleta(AConexion, sIdVariacion, AValores,
    sValorActual, AValor, Punto.X, Punto.Y, iAncho);
end;

end.
