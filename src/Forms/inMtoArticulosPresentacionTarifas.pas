{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoArticulosPresentacionTarifas                             }
{    Tipo:       Colaborador VCL                                               }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Pestana de tarifas del articulo: recalculo de precios en linea, margen,   }
{    incorporacion desde el selector y alta masiva sku x tarifa. Recibe        }
{    dataset, vista y catalogos; nunca el formulario.                          }
{******************************************************************************}
unit inMtoArticulosPresentacionTarifas;

interface

uses
  System.SysUtils, System.Classes, System.Variants, System.UITypes,
  Vcl.ComCtrls, Data.DB,
  Uni,
  cxCustomData, cxEdit, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxListView,
  inLibArticulosPresentacionIntf,
  inLibMargenPersistenciaIntf, inLibMargenTarifa;

type
  // Precio del articulo padre para una tarifa; lo resuelve el data module.
  TObtenerPrecioTarifaPadre = reference to function(
    const ACodigoArticulo, ACodigoTarifa: string): Double;
  // Rellena el selector del modal con las tarifas disponibles.
  TRellenarTarifasDisponibles = reference to procedure(
    ALista: TcxListView);
  TCosteCompraLeido = record
    Clave: string;
    Compra: TUltimaCompraTarifa;
  end;
  // Aviso de que las filas de tarifa han cambiado (visibilidad de columnas).
  TTrasCambiarTarifasArticulo = reference to procedure;

  TPresentadorTarifasArticulo = class
  private
    FTarifas: TDataSet;
    FVista: TcxGridDBTableView;
    FColumnaPrecioSalida: TcxGridColumn;
    FConexion: TUniConnection;
    FCatalogo: ICatalogoAltaTarifasArticulo;
    FObtenerPrecioPadre: TObtenerPrecioTarifaPadre;
    FRellenarTarifas: TRellenarTarifasDisponibles;
    FTrasCambiar: TTrasCambiarTarifasArticulo;
    FRepositorioMargen: IRepositorioMargen;
    FModoMargen: TModoMargenTarifa;
    FTipoIvaLeido: string;
    FPorcentajeIvaLeido: Double;
    FIvaLeido: Boolean;
    FCostesCompra: TArray<TCosteCompraLeido>;
    FCostesCompraLeidos: UInt64;
    function PorcentajeIvaTipo(const ATipoIva: string): Double;
    function UltimaCompraFila(
      const ACodigoArticulo, ACodigoUnidad: string): TUltimaCompraTarifa;
    function CosteUltimaCompra(
      const ACodigoArticulo, ACodigoUnidad: string): Double;
    function ReferenciaCompraFila(ARegistro: TcxCustomGridRecord;
      const ACampo: string; out ACompra: TUltimaCompraTarifa): Boolean;
    function ValorFila(iRegistro: Integer;
      const ACampo: string): Variant;
    function EnEdicion: Boolean;
    function ValorEditado(ASender: TObject): string;
    function DescribirFilaMargen(const ACodigoArticulo, ACodigoUnidad,
      ADescripcionSku: string; AEsSkuExistente: Boolean): string;
    procedure IncorporarSeleccionadas(ALista: TcxListView);
  public
    constructor Create(
      ATarifas: TDataSet;
      AVista: TcxGridDBTableView;
      AColumnaPrecioSalida: TcxGridColumn;
      AConexion: TUniConnection;
      const ACatalogo: ICatalogoAltaTarifasArticulo;
      const AObtenerPrecioPadre: TObtenerPrecioTarifaPadre;
      const ARellenarTarifas: TRellenarTarifasDisponibles;
      const ATrasCambiar: TTrasCambiarTarifasArticulo;
      const ARepositorioMargen: IRepositorioMargen;
      AModoMargen: TModoMargenTarifa);
    function CaptionColumnaMargen: string;
    procedure RecalcularDesdePorcentajeDto(ASender: TObject);
    procedure RecalcularDesdePrecioFinal(ASender: TObject);
    procedure RecalcularDesdePrecioSalida(ASender: TObject);
    procedure RecalcularDesdePrecioDto(ASender: TObject);
    procedure MostrarCoste(ARegistro: TcxCustomGridRecord;
      var ATexto: string);
    // Fecha y proveedor de la última compra, como el coste: solo de
    // referencia en filas sin coste grabado y sin grabarlos.
    procedure MostrarFechaCompra(ARegistro: TcxCustomGridRecord;
      var ATexto: string);
    procedure MostrarProveedorCompra(ARegistro: TcxCustomGridRecord;
      var ATexto: string);
    procedure MostrarMargen(ARegistro: TcxCustomGridRecord;
      var ATexto: string);
    procedure AbrirCalculadoraMargen(APropietario: TComponent);
    procedure IncorporarTarifas(APropietario: TComponent);
    procedure AltaMasivaPrecios(APropietario: TComponent;
      const ACodigoArticulo: string);
  end;

implementation

uses
  System.Math,
  inLibMensajesVcl,
  Vcl.Dialogs,
  inMtoModalArtTar,
  inMtoModalAddPreciosTar,
  UniDataColumnasDocumentoRepositorio,
  inMtoModalCalcularMargen,
  inLibArticulosAltaTarifas,
  inLibArticulosPresentacion,
  inLibMsgArticulos;

constructor TPresentadorTarifasArticulo.Create(
  ATarifas: TDataSet;
  AVista: TcxGridDBTableView;
  AColumnaPrecioSalida: TcxGridColumn;
  AConexion: TUniConnection;
  const ACatalogo: ICatalogoAltaTarifasArticulo;
  const AObtenerPrecioPadre: TObtenerPrecioTarifaPadre;
  const ARellenarTarifas: TRellenarTarifasDisponibles;
  const ATrasCambiar: TTrasCambiarTarifasArticulo;
  const ARepositorioMargen: IRepositorioMargen;
  AModoMargen: TModoMargenTarifa);
begin
  inherited Create;
  if ATarifas = nil then
    raise EArgumentNilException.Create('ATarifas');
  if not Assigned(ACatalogo) then
    raise EArgumentNilException.Create('ACatalogo');
  FTarifas := ATarifas;
  FVista := AVista;
  FColumnaPrecioSalida := AColumnaPrecioSalida;
  FConexion := AConexion;
  FCatalogo := ACatalogo;
  FObtenerPrecioPadre := AObtenerPrecioPadre;
  FRellenarTarifas := ARellenarTarifas;
  FTrasCambiar := ATrasCambiar;
  if not Assigned(ARepositorioMargen) then
    raise EArgumentNilException.Create('ARepositorioMargen');
  FRepositorioMargen := ARepositorioMargen;
  FModoMargen := AModoMargen;
end;

function TPresentadorTarifasArticulo.CaptionColumnaMargen: string;
begin
  if FModoMargen = mmtCoeficiente then
    Result := SCaptionCoeficienteMargen
  else
    Result := SCaptionColumnaMargenVenta;
end;

// FZ-ISSUE-426: sin coste tecleado en la fila, el margen usa el último
// precio de compra de sus SKU. La rejilla lo pide en cada repintado: se
// guarda medio minuto por fila de tarifa.
function TPresentadorTarifasArticulo.UltimaCompraFila(
  const ACodigoArticulo, ACodigoUnidad: string): TUltimaCompraTarifa;
const
  VIGENCIA_MS = 30000;
var
  sClave: string;
  iLeido, iEncontrado: Integer;
begin
  Result := Default(TUltimaCompraTarifa);
  if Trim(ACodigoArticulo) <> '' then
  begin
    if TThread.GetTickCount64 - FCostesCompraLeidos > VIGENCIA_MS then
    begin
      FCostesCompra := nil;
      FCostesCompraLeidos := TThread.GetTickCount64;
    end;
    sClave := ACodigoArticulo + #31 + ACodigoUnidad;
    iEncontrado := -1;
    for iLeido := 0 to High(FCostesCompra) do
      if FCostesCompra[iLeido].Clave = sClave then
        iEncontrado := iLeido;
    if iEncontrado < 0 then
    begin
      iEncontrado := Length(FCostesCompra);
      SetLength(FCostesCompra, iEncontrado + 1);
      FCostesCompra[iEncontrado].Clave := sClave;
      FCostesCompra[iEncontrado].Compra :=
        FRepositorioMargen.UltimaCompra(ACodigoArticulo, ACodigoUnidad);
    end;
    Result := FCostesCompra[iEncontrado].Compra;
  end;
end;

function TPresentadorTarifasArticulo.CosteUltimaCompra(
  const ACodigoArticulo, ACodigoUnidad: string): Double;
begin
  Result := UltimaCompraFila(ACodigoArticulo, ACodigoUnidad).Coste;
end;

// Hay referencia de compra para la celda ACampo si la fila no tiene coste
// grabado (un coste manual, incluido cero, manda), la celda está vacía y
// los SKU de la fila tienen alguna compra.
function TPresentadorTarifasArticulo.ReferenciaCompraFila(
  ARegistro: TcxCustomGridRecord; const ACampo: string;
  out ACompra: TUltimaCompraTarifa): Boolean;
var
  iRegistro: Integer;
  vCoste: Variant;
begin
  ACompra := Default(TUltimaCompraTarifa);
  Result := False;
  iRegistro := -1;
  if (ARegistro <> nil) and (FVista <> nil) then
    iRegistro := ARegistro.RecordIndex;
  vCoste := Null;
  if iRegistro >= 0 then
    vCoste := ValorFila(iRegistro, 'PRECIO_COSTE_ARTTAR');
  if (iRegistro >= 0) and
     (VarIsNull(vCoste) or VarIsEmpty(vCoste)) and
     (Trim(VarToStr(ValorFila(iRegistro, ACampo))) = '') then
  begin
    ACompra := UltimaCompraFila(
      VarToStr(ValorFila(iRegistro, 'CODIGO_ART_ARTTAR')),
      VarToStr(ValorFila(iRegistro, 'CODIGO_UNIDAD_ARTTAR')));
    Result := ACompra.Coste > 0;
  end;
end;

procedure TPresentadorTarifasArticulo.MostrarFechaCompra(
  ARegistro: TcxCustomGridRecord; var ATexto: string);
var
  oCompra: TUltimaCompraTarifa;
begin
  if ReferenciaCompraFila(ARegistro, 'FECHA_ULT_COMPRA_ARTTAR', oCompra) and
     (oCompra.Fecha > 0) then
    ATexto := DateToStr(oCompra.Fecha);
end;

procedure TPresentadorTarifasArticulo.MostrarProveedorCompra(
  ARegistro: TcxCustomGridRecord; var ATexto: string);
var
  oCompra: TUltimaCompraTarifa;
begin
  if ReferenciaCompraFila(ARegistro, 'CODIGO_PRV_ARTTAR', oCompra) and
     (oCompra.Proveedor <> '') then
    ATexto := oCompra.Proveedor;
end;

// La rejilla pide el texto en cada repintado: el IVA se lee una vez por tipo.
function TPresentadorTarifasArticulo.PorcentajeIvaTipo(
  const ATipoIva: string): Double;
begin
  if (not FIvaLeido) or (not SameText(FTipoIvaLeido, ATipoIva)) then
  begin
    FPorcentajeIvaLeido := FRepositorioMargen.PorcentajeIva(ATipoIva);
    FTipoIvaLeido := ATipoIva;
    FIvaLeido := True;
  end;
  Result := FPorcentajeIvaLeido;
end;

function TPresentadorTarifasArticulo.ValorFila(iRegistro: Integer;
  const ACampo: string): Variant;
var
  oItem: TcxCustomGridTableItem;
begin
  Result := Null;
  oItem := FVista.GetColumnByFieldName(ACampo);
  if oItem <> nil then
    Result := FVista.DataController.Values[iRegistro, oItem.Index];
end;

function TPresentadorTarifasArticulo.EnEdicion: Boolean;
begin
  Result := FTarifas.State in [dsInsert, dsEdit];
end;

function TPresentadorTarifasArticulo.ValorEditado(ASender: TObject): string;
begin
  Result := VarToStr((ASender as TcxCustomEdit).EditingValue);
end;

procedure TPresentadorTarifasArticulo.RecalcularDesdePorcentajeDto(
  ASender: TObject);
begin
  if EnEdicion then
  begin
    FTarifas.FindField('PORCENTAJE_DTO_ARTTAR').AsString :=
      ValorEditado(ASender);
    FTarifas.FindField('PRECIO_FINAL_ARTTAR').AsFloat :=
      PrecioConDescuentoTarifa(
        FTarifas.FindField('PRECIO_SALIDA_ARTTAR').AsFloat,
        FTarifas.FindField('PORCENTAJE_DTO_ARTTAR').AsFloat);
    FTarifas.FindField('PRECIO_DTO_ARTTAR').AsFloat := RoundTo(
      FTarifas.FindField('PRECIO_SALIDA_ARTTAR').AsFloat -
      FTarifas.FindField('PRECIO_FINAL_ARTTAR').AsFloat, -6);
  end;
end;

procedure TPresentadorTarifasArticulo.RecalcularDesdePrecioFinal(
  ASender: TObject);
var
  dSalida, dFinal: Double;
begin
  if EnEdicion then
  begin
    FTarifas.FindField('PRECIO_FINAL_ARTTAR').AsString :=
      ValorEditado(ASender);
    dSalida := FTarifas.FindField('PRECIO_SALIDA_ARTTAR').AsFloat;
    dFinal := FTarifas.FindField('PRECIO_FINAL_ARTTAR').AsFloat;
    // Precio de salida fijo: el descuento sale de la diferencia entre los
    // dos precios. Sin salida, o con un final por encima (no hay recargos),
    // la salida pasa a ser el final y la fila queda sin descuento.
    if (dSalida > 0) and (dFinal <= dSalida) then
    begin
      // Seis decimales, los de la columna: 19,99 - 15,99 no deja 3,999...
      FTarifas.FindField('PRECIO_DTO_ARTTAR').AsFloat :=
        RoundTo(dSalida - dFinal, -6);
      FTarifas.FindField('PORCENTAJE_DTO_ARTTAR').AsFloat :=
        RoundTo(((dSalida - dFinal) / dSalida) * 100, -6);
    end
    else
    begin
      FTarifas.FindField('PRECIO_SALIDA_ARTTAR').AsString :=
        FTarifas.FindField('PRECIO_FINAL_ARTTAR').AsString;
      FTarifas.FindField('PRECIO_DTO_ARTTAR').AsFloat := 0;
      FTarifas.FindField('PORCENTAJE_DTO_ARTTAR').AsFloat := 0;
    end;
  end;
end;

procedure TPresentadorTarifasArticulo.RecalcularDesdePrecioSalida(
  ASender: TObject);
begin
  if EnEdicion then
  begin
    FTarifas.FindField('PRECIO_SALIDA_ARTTAR').AsString :=
      ValorEditado(ASender);
    FTarifas.FindField('PRECIO_FINAL_ARTTAR').AsFloat :=
      FTarifas.FindField('PRECIO_SALIDA_ARTTAR').AsFloat -
      FTarifas.FindField('PRECIO_DTO_ARTTAR').AsFloat;
  end;
end;

procedure TPresentadorTarifasArticulo.RecalcularDesdePrecioDto(
  ASender: TObject);
begin
  if EnEdicion then
  begin
    FTarifas.FindField('PRECIO_DTO_ARTTAR').AsString :=
      ValorEditado(ASender);
    if FTarifas.FindField('PRECIO_SALIDA_ARTTAR').AsFloat <> 0 then
    begin
      FTarifas.FindField('PORCENTAJE_DTO_ARTTAR').AsFloat :=
        (FTarifas.FindField('PRECIO_DTO_ARTTAR').AsFloat /
         FTarifas.FindField('PRECIO_SALIDA_ARTTAR').AsFloat) * 100;
      FTarifas.FindField('PRECIO_FINAL_ARTTAR').AsFloat :=
        FTarifas.FindField('PRECIO_SALIDA_ARTTAR').AsFloat -
        FTarifas.FindField('PRECIO_DTO_ARTTAR').AsFloat;
    end;
  end;
end;

procedure TPresentadorTarifasArticulo.MostrarCoste(
  ARegistro: TcxCustomGridRecord; var ATexto: string);
var
  oCompra: TUltimaCompraTarifa;
begin
  // Mostrar la referencia de compra sin grabarla en la tarifa ni sustituir
  // un coste manual, incluido cero. Reutiliza la consulta del margen.
  if ReferenciaCompraFila(ARegistro, 'PRECIO_COSTE_ARTTAR', oCompra) then
    ATexto := CurrToStrF(oCompra.Coste, ffCurrency, 2);
end;

procedure TPresentadorTarifasArticulo.MostrarMargen(
  ARegistro: TcxCustomGridRecord; var ATexto: string);
var
  oControlador: TcxCustomDataController;
  iRegistro: Integer;
  oItemCoste, oItemSalida: TcxCustomGridTableItem;
  vCoste, vSalida: Variant;
  dCoste, dSalida, dIva, dValor: Double;
  bLegible, bImpuestosIncluidos: Boolean;
begin
  ATexto := '';
  // DevExpress pide el texto con ARecord = nil cuando el editor no está
  // ligado a un registro (p. ej. al validar la celda con Tab): sin registro
  // no hay margen que mostrar.
  iRegistro := -1;
  if ARegistro <> nil then
    iRegistro := ARegistro.RecordIndex;
  oControlador := nil;
  if FVista <> nil then
    oControlador := FVista.DataController;
  if (iRegistro >= 0) and (oControlador <> nil) then
  begin
    oItemCoste := FVista.GetColumnByFieldName('PRECIO_COSTE_ARTTAR');
    oItemSalida := FVista.GetColumnByFieldName('PRECIO_SALIDA_ARTTAR');
    if (oItemCoste <> nil) and (oItemSalida <> nil) then
    begin
      vCoste := oControlador.Values[iRegistro, oItemCoste.Index];
      vSalida := oControlador.Values[iRegistro, oItemSalida.Index];
      bLegible := (not VarIsNull(vSalida)) and (not VarIsEmpty(vSalida));
      if bLegible then
      begin
        dCoste := 0;
        dSalida := 0;
        try
          if (not VarIsNull(vCoste)) and (not VarIsEmpty(vCoste)) then
            dCoste := vCoste;
          dSalida := vSalida;
        except
          // Valor no convertible: la columna queda sin margen visible.
          on Exception do
            bLegible := False;
        end;
        if bLegible and (dCoste <= 0) then
          dCoste := CosteUltimaCompra(
            VarToStr(ValorFila(iRegistro, 'CODIGO_ART_ARTTAR')),
            VarToStr(ValorFila(iRegistro, 'CODIGO_UNIDAD_ARTTAR')));
        // Antes salía precio / coste x 100 sobre el PVP con IVA: un
        // coeficiente presentado como margen (FZ-ISSUE-315).
        bImpuestosIncluidos := SameText(
          VarToStr(ValorFila(iRegistro, 'ESIMP_INCL_TAR')), 'S');
        dIva := 0;
        if bLegible and bImpuestosIncluidos and
           (FModoMargen = mmtMargenVenta) then
          dIva := PorcentajeIvaTipo(
            VarToStr(ValorFila(iRegistro, 'TIPO_IVA_ARTICULO')));
        if bLegible and CalcularMargenTarifa(FModoMargen, dCoste, dSalida,
             dIva, bImpuestosIncluidos, dValor) then
          ATexto := TextoMargenTarifa(FModoMargen, dValor);
      end;
    end;
  end;
end;

// FZ-ISSUE-627: las filas «art/*/talla» y «art/color» no son un SKU y la
// vista no les da descripción; la calculadora decía «(sin SKU)» y parecía
// tratarse de la fila general. Se nombra la regla con los rótulos de los
// ejes de la variación del artículo (Talla/Color por defecto).
function TPresentadorTarifasArticulo.DescribirFilaMargen(
  const ACodigoArticulo, ACodigoUnidad, ADescripcionSku: string;
  AEsSkuExistente: Boolean): string;
var
  sArticulo, sUnidad, sValor: string;
  iComodin: Integer;
begin
  Result := Trim(ADescripcionSku);
  sArticulo := Trim(ACodigoArticulo);
  sUnidad := Trim(ACodigoUnidad);
  if (Result = '') and (sUnidad <> '') then
  begin
    iComodin := Pos('/*/', sUnidad);
    if iComodin > 0 then
    begin
      sValor := Copy(sUnidad, iComodin + 3, MaxInt);
      Result := Format(SInfoReglaTarifaMargen,
        [RotuloEjeArticulo(FConexion, sArticulo, 'P', 'Talla'), sValor,
         LowerCase(RotuloEjeArticulo(FConexion, sArticulo, 'F', 'Color')),
         sUnidad]);
    end
    else if (not AEsSkuExistente) and (sArticulo <> '') and
            SameText(Copy(sUnidad, 1, Length(sArticulo) + 1),
              sArticulo + '/') then
    begin
      sValor := Copy(sUnidad, Length(sArticulo) + 2, MaxInt);
      if (sValor <> '') and (Pos('/', sValor) = 0) then
        Result := Format(SInfoReglaTarifaMargen,
          [RotuloEjeArticulo(FConexion, sArticulo, 'F', 'Color'), sValor,
           LowerCase(RotuloEjeArticulo(FConexion, sArticulo, 'P',
             'Talla')), sUnidad])
      else
        Result := sUnidad;
    end
    else
      Result := sUnidad;
  end;
end;

procedure TPresentadorTarifasArticulo.AbrirCalculadoraMargen(
  APropietario: TComponent);
var
  oCampoUnico: TField;
  iUnico: Integer;
  sCodigoUnidad, sCodigoArticulo, sDescripcionArticulo: string;
  sCodigoTarifa, sNombreTarifa, sDescripcionSku: string;
  dCoste, dPrecioSalida, dIva: Double;
  bImpuestosIncluidos: Boolean;
  oResultado: TCalcularMargenResult;
begin
  if (not FTarifas.Active) or FTarifas.IsEmpty then
    ShowMessage_fza(SErrorPrecioTarifaNoSeleccionado)
  else
  begin
    if EnEdicion then
      FTarifas.Post;
    oCampoUnico := FTarifas.FindField('CODIGO_UNICO_ARTTAR');
    if (oCampoUnico = nil) or oCampoUnico.IsNull then
      ShowMessage_fza(SErrorPrecioTarifaNoGuardado)
    else
    begin
      iUnico := oCampoUnico.AsInteger;
      sCodigoUnidad := '';
      sDescripcionArticulo := '';
      sNombreTarifa := '';
      sDescripcionSku := '';
      if FTarifas.FindField('CODIGO_UNIDAD_ARTTAR') <> nil then
        sCodigoUnidad :=
          FTarifas.FieldByName('CODIGO_UNIDAD_ARTTAR').AsString;
      sCodigoArticulo := FTarifas.FieldByName('CODIGO_ART_ARTTAR').AsString;
      if FTarifas.FindField('DESCRIPCION_ART') <> nil then
        sDescripcionArticulo :=
          FTarifas.FieldByName('DESCRIPCION_ART').AsString;
      sCodigoTarifa := FTarifas.FieldByName('CODIGO_TAR_ARTTAR').AsString;
      if FTarifas.FindField('NOMBRE_TAR_TAR') <> nil then
        sNombreTarifa := FTarifas.FieldByName('NOMBRE_TAR_TAR').AsString;
      if FTarifas.FindField('DESCRIPCION_SKU') <> nil then
        sDescripcionSku := FTarifas.FieldByName('DESCRIPCION_SKU').AsString;
      // ESACTIVO_SKU solo viene informado si la fila apunta a un SKU real.
      sDescripcionSku := DescribirFilaMargen(sCodigoArticulo, sCodigoUnidad,
        sDescripcionSku, (FTarifas.FindField('ESACTIVO_SKU') <> nil) and
        (not FTarifas.FieldByName('ESACTIVO_SKU').IsNull));
      dCoste := FTarifas.FieldByName('PRECIO_COSTE_ARTTAR').AsFloat;
      // FZ-ISSUE-426: la calculadora propone el de la última compra; en
      // filas de talla o color, la más reciente de los SKU que abarcan
      // (misma resolución que la columna de coste de la rejilla).
      if dCoste <= 0 then
        dCoste := FRepositorioMargen.UltimaCompra(
          sCodigoArticulo, sCodigoUnidad).Coste;
      dPrecioSalida :=
        FTarifas.FieldByName('PRECIO_SALIDA_ARTTAR').AsFloat;
      bImpuestosIncluidos := (FTarifas.FindField('ESIMP_INCL_TAR') <> nil)
        and SameText(FTarifas.FieldByName('ESIMP_INCL_TAR').AsString, 'S');
      dIva := 0;
      if bImpuestosIncluidos and
         (FTarifas.FindField('TIPO_IVA_ARTICULO') <> nil) then
        dIva := PorcentajeIvaTipo(
          FTarifas.FieldByName('TIPO_IVA_ARTICULO').AsString);
      oResultado := TfrmModalCalcularMargen.Ejecutar(
        APropietario, iUnico, sCodigoArticulo, sCodigoUnidad,
        sDescripcionArticulo, sCodigoTarifa, sNombreTarifa,
        sDescripcionSku, dCoste, dPrecioSalida, FRepositorioMargen,
        FModoMargen, dIva, bImpuestosIncluidos);
      if oResultado.Aceptado then
      begin
        FCostesCompra := nil;
        FTarifas.Refresh;
        if Assigned(FTrasCambiar) then
          FTrasCambiar();
      end;
    end;
  end;
end;

procedure TPresentadorTarifasArticulo.IncorporarSeleccionadas(
  ALista: TcxListView);
var
  bAnadida: Boolean;
  iItem: Integer;
  oItem: TListItem;
begin
  bAnadida := False;
  for iItem := 0 to ALista.Items.Count - 1 do
  begin
    oItem := ALista.Items[iItem];
    if oItem.Checked then
    begin
      // Evita duplicar: el modal consulta la BBDD y no ve las tarifas
      // aun pendientes de grabar. Si el articulo ya tiene esa tarifa a
      // nivel padre (CODIGO_UNIDAD_ARTTAR vacio) no se inserta.
      if not FTarifas.Locate('CODIGO_TAR_ARTTAR;CODIGO_UNIDAD_ARTTAR',
                             VarArrayOf([oItem.Caption, '']),
                             [loCaseInsensitive]) then
      begin
        FTarifas.Insert;
        FTarifas.FieldByName('CODIGO_TAR_ARTTAR').AsString := oItem.Caption;
        FTarifas.FieldByName('ESACTIVO_ARTTAR').AsString := 'S';
        FTarifas.FieldByName('FECHA_DESDE_ARTTAR').AsDateTime := Now;
        FTarifas.FieldByName('PRECIO_SALIDA_ARTTAR').AsInteger := 0;
        FTarifas.FieldByName('PRECIO_FINAL_ARTTAR').AsInteger := 0;
        FTarifas.FieldByName('CODIGO_UNIDAD_ARTTAR').AsString := '';
        FTarifas.Post;
        bAnadida := True;
      end;
    end;
  end;
  FTarifas.Refresh;
  if bAnadida and (FColumnaPrecioSalida <> nil) then
    FColumnaPrecioSalida.FocusWithSelection;
end;

procedure TPresentadorTarifasArticulo.IncorporarTarifas(
  APropietario: TComponent);
var
  oModal: TfrmMtoModalArtTar;
begin
  oModal := TfrmMtoModalArtTar.Create(APropietario);
  try
    oModal.Name := 'frmMtoModalArtTar';
    oModal.Caption := STituloSeleccionTarifasArticulo;
    if Assigned(FRellenarTarifas) then
      FRellenarTarifas(oModal.lstTarifas);
    oModal.ShowModal;
    if oModal.sFicha = 'S' then
      IncorporarSeleccionadas(oModal.lstTarifas);
  finally
    FreeAndNil(oModal);
  end;
end;

procedure TPresentadorTarifasArticulo.AltaMasivaPrecios(
  APropietario: TComponent; const ACodigoArticulo: string);
var
  oModal: TfrmMtoModalAddPreciosTar;
  iCombinacion: Integer;
  oListaTarifas: TStringList;
  oSkusSeleccionados, oTarifasSeleccionadas: TStringList;
  oCatalogoSkus: TOpcionesSkuTarifaArticulo;
  oCatalogoTarifas: TArray<string>;
  oMarca: TBookmark;
  dPrecioPadre: Double;
  oVigencia: TVigenciaTarifa;
  oExistentes: TFilasTarifaExistentes;
  oCombinaciones: TCombinacionesAltaTarifa;
  oFila: TFilaNuevaTarifa;
  oOmitidas: TArray<string>;
  oCerrables: TArray<string>;
  bCerrar: Boolean;
  bTransaccionPropia: Boolean;
  sEjeFila: string;
  sEjePivote: string;

  function DescribirLlaves(const ALlaves: TArray<string>): string;
  var
    sLlave: string;
  begin
    Result := '';
    for sLlave in ALlaves do
      Result := Result + '- ' + DescribirLlaveTarifa(sLlave) + #13#10;
    Result := TrimRight(Result);
  end;

  procedure CalcularAlta;
  begin
    oExistentes := LeerFilasTarifaExistentes(FTarifas);
    oCombinaciones := CalcularCombinacionesAltaTarifas(
      oSkusSeleccionados.ToStringArray,
      oTarifasSeleccionadas.ToStringArray, oExistentes, oVigencia);
    oOmitidas := CombinacionesOmitidasAltaTarifas(
      oSkusSeleccionados.ToStringArray,
      oTarifasSeleccionadas.ToStringArray, oCombinaciones);
  end;

begin
  oModal := TfrmMtoModalAddPreciosTar.Create(APropietario);
  // Evitamos el caFree heredado para poder hacer Free manual.
  oModal.OnClose := nil;
  oListaTarifas := TStringList.Create;
  oSkusSeleccionados := TStringList.Create;
  oTarifasSeleccionadas := TStringList.Create;
  try
    oCatalogoSkus := ComponerListaSkusAltaTarifa(
      ACodigoArticulo,
      FCatalogo.ListarSkus(ACodigoArticulo),
      FCatalogo.ListarTallasColeccion(ACodigoArticulo));
    // FZ-ISSUE-439: con «Aroma y medida» la lista dice Medida y aroma.
    sEjeFila := RotuloEjeArticulo(
      FConexion, ACodigoArticulo, 'F', '');
    sEjePivote := RotuloEjeArticulo(
      FConexion, ACodigoArticulo, 'P', '');
    if not (SameText(sEjeFila, 'Color') and
            SameText(sEjePivote, 'Talla')) then
      oModal.AsignarRotulosEjes(sEjeFila, sEjePivote);
    oModal.CargarSkus(oCatalogoSkus);
    oCatalogoTarifas := FCatalogo.ListarTarifasActivas;
    for iCombinacion := 0 to High(oCatalogoTarifas) do
      oListaTarifas.Add(oCatalogoTarifas[iCombinacion]);
    oModal.CargarTarifas(oListaTarifas);
    oModal.ShowModal;
    if oModal.sFicha = 'S' then
    begin
      oModal.ObtenerSkusSeleccionados(oSkusSeleccionados);
      oModal.ObtenerTarifasSeleccionadas(oTarifasSeleccionadas);
      oVigencia.Desde := oModal.FechaDesde;
      oVigencia.TieneHasta := oModal.TieneFechaHasta;
      if oVigencia.TieneHasta then
        oVigencia.Hasta := oModal.FechaHasta
      else
        oVigencia.Hasta := 0;
      // Las decisiones (solapamiento, ocupacion y herencia del precio
      // del padre) viven en inLibArticulosAltaTarifas; aqui queda el
      // dataset y el modal.
      FTarifas.DisableControls;
      try
        oMarca := FTarifas.GetBookmark;
        try
          CalcularAlta;
          if FTarifas.BookmarkValid(oMarca) then
            FTarifas.GotoBookmark(oMarca);
        finally
          FTarifas.FreeBookmark(oMarca);
        end;
        oCerrables := LlavesVigenciasCerrables(
          oExistentes, oVigencia, oOmitidas);
        bCerrar := False;
        if Length(oCerrables) > 0 then
          bCerrar := MessageDlg_fza(
            Format(SPreguntaCerrarPreciosSolapados,
              [Length(oCerrables), DescribirLlaves(oCerrables),
               DateToStr(oVigencia.Desde - 1)]),
            mtConfirmation, [mbYes, mbNo], 0, mbNo) = mrYes;
        // Cierre y alta forman una sola operacion: si falla una fila,
        // tampoco se pierde la vigencia del precio anterior.
        bTransaccionPropia := Assigned(FConexion) and
          (not FConexion.InTransaction) and
          (bCerrar or (Length(oCombinaciones) > 0));
        if bTransaccionPropia then
          FConexion.StartTransaction;
        try
          if bCerrar then
          begin
            CerrarVigenciasSolapadas(FTarifas, oVigencia, oCerrables);
            CalcularAlta;
          end;
          for iCombinacion := 0 to High(oCombinaciones) do
          begin
            if oCombinaciones[iCombinacion].EsFilaArticulo then
              dPrecioPadre := 0
            else
              dPrecioPadre := FObtenerPrecioPadre(
                ACodigoArticulo, oCombinaciones[iCombinacion].Tarifa);
            oFila := ComponerFilaNuevaTarifa(
              oCombinaciones[iCombinacion], dPrecioPadre, oVigencia);
            EscribirFilaNuevaTarifa(FTarifas, oFila);
          end;
          if bTransaccionPropia then
            FConexion.Commit;
        except
          if bTransaccionPropia then
          begin
            FConexion.Rollback;
            FTarifas.Cancel;
            FTarifas.Refresh;
          end;
          raise;
        end;
      finally
        FTarifas.EnableControls;
      end;
      FTarifas.Refresh;
      if Assigned(FTrasCambiar) then
        FTrasCambiar();
      if Length(oOmitidas) > 0 then
        ShowMessage_fza(Format(SAvisoPreciosSolapadosNoCreados,
          [Length(oOmitidas), DescribirLlaves(oOmitidas)]));
    end;
  finally
    FreeAndNil(oSkusSeleccionados);
    FreeAndNil(oTarifasSeleccionadas);
    FreeAndNil(oListaTarifas);
    FreeAndNil(oModal);
  end;
end;

end.
