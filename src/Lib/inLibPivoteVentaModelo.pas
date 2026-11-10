{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPivoteVentaModelo                                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modelo del pivote de venta (fascículo V3 del anexo SRP): propietario      }
{    de los grupos artículo+color+precio, celdas por talla, bandas,            }
{    cantidades, conjuntos (reales y virtuales) y volcado a albaranar.         }
{    Recibe el puerto IRepositorioModeloPivoteVenta; no conoce VCL,            }
{    UniDAC, TDataSet ni el formulario.                                        }
{******************************************************************************}
unit inLibPivoteVentaModelo;

interface

uses
  System.SysUtils, System.Generics.Collections,
  inLibPivoteVentaCalculo, inLibPivoteVentaIntf;

type
  // Datos ya resueltos de una línea real del documento.
  TDatosLineaPivoteVenta = record
    Articulo    : string;
    LineaTexto  : string;
    Linea       : Integer;
    Precio      : Double;
    PorcentajeDto: Double;
    TipoCantidad: string;
    Sku         : string;
    Info        : TInfoSkuPivoteVenta;
    Pedida      : Double;
    Entregada   : Double;
    AAlbaranar  : Double;
    Almacen     : string;
  end;
  // Campos crudos de la línea para resolver su SKU y atributos.
  TCamposEntradaLineaPivote = record
    Sku           : string;
    SkuAlternativo: string;
    CodigoBarras  : string;
    CodigoProdPs  : string;
    Articulo      : string;
  end;
  // Estado agregado de un grupo del pivote.
  TGrupoPivoteVenta = record
    Articulo    : string;
    TipoCantidad: string;
    ColorAv     : Integer;
    ColorTexto  : string;
    ColorCodigo : string;
    PestanaTexto: string;
    SkuPrefijo  : string;
    // SKU de la línea que abrió el grupo: de él sale la copa (pestañas)
    // con la que se resuelven y crean los SKU de sus celdas.
    SkuBase     : string;
    VarSku      : string;
    IdAc        : Integer;
    SinTalla    : Boolean;
    UdsGrupo    : Double;
    Precio      : Double;
    PorcentajeDto: Double;
    PreciosDistintos: Boolean;
    Tallas      : TArray<Integer>;
  end;
  // Celda del pivote: cantidades y línea real asociada.
  TCeldaPivoteVenta = record
    Pedida    : Double;
    Entregada : Double;
    AAlbaranar: Double;
    Sku       : string;
    Linea     : string;
    Almacen   : string;
  end;
  TModeloPivoteVenta = class
  private
    FRepositorio        : IRepositorioModeloPivoteVenta;
    FBandaUnica         : Boolean;
    FAgruparSinPrecio   : Boolean;
    FTextoAAlbaranar    : string;
    FLineasVista        : TList<Integer>;
    FLineaBase          : TDictionary<Integer, Integer>;
    FLineaBanda         : TDictionary<Integer, TBandaPivoteVenta>;
    FClavesGrupo        : TDictionary<string, Integer>;
    FGrupos             : TDictionary<Integer, TGrupoPivoteVenta>;
    FCeldas             : TDictionary<Int64, TCeldaPivoteVenta>;
    FSkuInfo            : TDictionary<string, TInfoSkuPivoteVenta>;
    FConjuntoVirtualIds : TDictionary<string, Integer>;
    FProxConjuntoVirtual: Integer;
    FPosConjuntos       : TDictionary<Integer, TValoresTallaPivoteVenta>;
    FHayColor           : Boolean;
    FHayTipoCantidadEspecial: Boolean;
    FGruposSinConjunto  : TList<Integer>;
    FTallasRecortadas   : TDictionary<string, Integer>;
    procedure RegistrarBandasGrupo(ALineaRepr: Integer);
    // FZ-ISSUE-410: clave del grupo donde cabe la línea. Si otra línea
    // real ya ocupa su talla en el grupo artículo+color+precio, pasa a
    // una fila de repetición ('|R2', '|R3'...) en vez de pisar la celda.
    function ClaveGrupoLibre(const ADatos: TDatosLineaPivoteVenta): string;
    // FZ-ISSUE-405: deja en APosiciones las tallas que caben en
    // horizontal, primero las que el grupo tiene en el documento.
    function RecortarTallasHorizontal(const AArticulo: string;
      var APosiciones: TValoresTallaPivoteVenta;
      const ATallasGrupo: TArray<Integer>): Boolean;
    procedure AnexarTallasFaltantes(var APosiciones:
      TValoresTallaPivoteVenta; const ATallas: TValoresTallaPivoteVenta);
    // Conserva el sistema y completa las tallas del articulo y documento.
    // La ampliacion es virtual: nunca modifica el sistema en la BBDD.
    function ResolverConjuntoGrupo(ALineaRepr, AConjunto: Integer;
      const ATallas: TArray<Integer>): Integer;
    procedure AjustarAAlbaranarCeldas;
  public
    constructor Create(const ARepositorio: IRepositorioModeloPivoteVenta;
                       ABandaUnica: Boolean;
                       const ATextoAAlbaranar: string);
    destructor Destroy; override;
    // Vacía la caché de posiciones de conjuntos reales (equivale a
    // recrear el gestor en cada Construir del modo).
    procedure InvalidarPosiciones;
    procedure IniciarCarga;
    // Alta de una línea real en la caché del pivote. Devuelve False si
    // la línea no es pivotable (sin artículo o sin número).
    function RegistrarLinea(const ADatos: TDatosLineaPivoteVenta;
                            out ALineaRepr: Integer;
                            out AGrupoNuevo: Boolean): Boolean;
    // Resuelve conjuntos reales o virtuales por grupo y normaliza la
    // caché de "a albaranar". Cierra una carga.
    procedure CompletarCarga;
    function ObtenerInfoSku(const ACodigoSku: string;
                            out AInfo: TInfoSkuPivoteVenta): Boolean;
    // Orden de resolución del SKU de una línea: campo SKU, campo
    // alternativo, código de barras (también para completar la talla),
    // código de plataforma y artículo con SKU único.
    function ResolverInfoLinea(const ACampos: TCamposEntradaLineaPivote;
                               out ASku: string;
                               out AInfo: TInfoSkuPivoteVenta): Boolean;
    function PosicionesConjunto(AIdAc: Integer)
                                : TValoresTallaPivoteVenta;
    function ObtenerLineaBase(ALinea: Integer): Integer;
    function BandaDesdeLinea(ALinea: Integer): TBandaPivoteVenta;
    function EsLineaVista(ALinea: Integer): Boolean;
    function Grupo(ALineaBase: Integer;
                   out AGrupo: TGrupoPivoteVenta): Boolean;
    function Celda(AClave: Int64;
                   out ACelda: TCeldaPivoteVenta): Boolean;
    function UdsGrupoDeLineaVista(ALineaVista: Integer;
                                  out AUds: Double): Boolean;
    function ValorCantidadBanda(AClave: Int64;
                                ABanda: TBandaPivoteVenta): Double;
    function PendienteBaseCelda(AClave: Int64): Double;
    function PendienteCelda(AClave: Int64): Double;
    function AAlbaranarCelda(AClave: Int64): Double;
    function TextoBanda(ABanda: TBandaPivoteVenta): string;
    function TextoTipoCantidad(ALineaBase: Integer;
                               ABanda: TBandaPivoteVenta): string;
    // Id de talla que corresponde a la posición 1..N de un grupo.
    function TallaAvEnPosicion(ALineaBase, APosicion: Integer;
                               out AIdAv: Integer): Boolean;
    // Número de columnas de talla a mostrar, capado a AMaxColumnas.
    function MaxPosicionesVisibles(AMaxColumnas: Integer): Integer;
    // Marca en caché todo el pendiente como "a albaranar" (documentos
    // sin campo persistible). Devuelve las celdas marcadas.
    function MarcarTodoAAlbaranarEnCache: Integer;
    procedure LimpiarAAlbaranarEnCache;
    // Vuelca las celdas con "a albaranar" (línea real, entregada +
    // a albaranar) e informa del almacén común.
    function VolcarAAlbaranar(ALineas: TList<TPair<string, Currency>>;
                              out AAlmacenComun: string;
                              out AAlmacenUnico: Boolean): Integer;
    // Líneas reales distintas del grupo: una por talla o la única
    // "sin talla".
    function LineasRealesDeGrupo(ALineaBase: Integer): TArray<string>;
    function GruposSinConjunto: TArray<Integer>;
    // Artículos de la última carga con más tallas de las que caben en
    // horizontal, con cuántas tienen.
    function TallasRecortadas: TArray<TPair<string, Integer>>;
    property AgruparSinPrecio: Boolean
      read FAgruparSinPrecio write FAgruparSinPrecio;
    property BandaUnica: Boolean read FBandaUnica;
    property HayColor: Boolean read FHayColor;
    property HayTipoCantidadEspecial: Boolean
      read FHayTipoCantidadEspecial;
    property LineasVista: TList<Integer> read FLineasVista;
  end;

procedure OrdenarTallasNumericas(var ATallas: TValoresTallaPivoteVenta);

implementation

procedure OrdenarTallasNumericas(var ATallas: TValoresTallaPivoteVenta);
var
  aCodigos: TArray<string>;
  aOrden: TArray<Integer>;
  aOriginal: TValoresTallaPivoteVenta;
  i: Integer;
begin
  SetLength(aCodigos, Length(ATallas));
  for i := 0 to High(ATallas) do
    aCodigos[i] := ATallas[i].Valor;
  aOrden := IndicesOrdenNumericoTallas(aCodigos);
  aOriginal := Copy(ATallas);
  for i := 0 to High(aOrden) do
    ATallas[i] := aOriginal[aOrden[i]];
end;

constructor TModeloPivoteVenta.Create(
  const ARepositorio: IRepositorioModeloPivoteVenta; ABandaUnica: Boolean;
  const ATextoAAlbaranar: string);
begin
  inherited Create;
  FRepositorio := ARepositorio;
  FBandaUnica := ABandaUnica;
  FTextoAAlbaranar := ATextoAAlbaranar;
  FLineasVista := TList<Integer>.Create;
  FLineaBase := TDictionary<Integer, Integer>.Create;
  FLineaBanda := TDictionary<Integer, TBandaPivoteVenta>.Create;
  FClavesGrupo := TDictionary<string, Integer>.Create;
  FGrupos := TDictionary<Integer, TGrupoPivoteVenta>.Create;
  FCeldas := TDictionary<Int64, TCeldaPivoteVenta>.Create;
  FSkuInfo := TDictionary<string, TInfoSkuPivoteVenta>.Create;
  FConjuntoVirtualIds := TDictionary<string, Integer>.Create;
  FProxConjuntoVirtual := -1;
  FPosConjuntos :=
    TDictionary<Integer, TValoresTallaPivoteVenta>.Create;
  FGruposSinConjunto := TList<Integer>.Create;
  FTallasRecortadas := TDictionary<string, Integer>.Create;
end;

destructor TModeloPivoteVenta.Destroy;
begin
  FreeAndNil(FTallasRecortadas);
  FreeAndNil(FGruposSinConjunto);
  FreeAndNil(FPosConjuntos);
  FreeAndNil(FConjuntoVirtualIds);
  FreeAndNil(FSkuInfo);
  FreeAndNil(FCeldas);
  FreeAndNil(FGrupos);
  FreeAndNil(FClavesGrupo);
  FreeAndNil(FLineaBanda);
  FreeAndNil(FLineaBase);
  FreeAndNil(FLineasVista);
  inherited;
end;

procedure TModeloPivoteVenta.InvalidarPosiciones;
begin
  FPosConjuntos.Clear;
end;

procedure TModeloPivoteVenta.IniciarCarga;
begin
  FLineasVista.Clear;
  FLineaBase.Clear;
  FLineaBanda.Clear;
  FClavesGrupo.Clear;
  FGrupos.Clear;
  FCeldas.Clear;
  FGruposSinConjunto.Clear;
  FTallasRecortadas.Clear;
  FHayColor := False;
  FHayTipoCantidadEspecial := False;
end;

procedure TModeloPivoteVenta.RegistrarBandasGrupo(ALineaRepr: Integer);
var
  iVista: Integer;
begin
  iVista := LineaVistaBandaPivoteVenta(ALineaRepr, bpvPedida);
  FLineasVista.Add(iVista);
  FLineaBase.AddOrSetValue(iVista, ALineaRepr);
  FLineaBanda.AddOrSetValue(iVista, bpvPedida);
  if not FBandaUnica then
  begin
    iVista := LineaVistaBandaPivoteVenta(ALineaRepr, bpvEntregada);
    FLineasVista.Add(iVista);
    FLineaBase.AddOrSetValue(iVista, ALineaRepr);
    FLineaBanda.AddOrSetValue(iVista, bpvEntregada);
    iVista := LineaVistaBandaPivoteVenta(ALineaRepr, bpvPendiente);
    FLineasVista.Add(iVista);
    FLineaBase.AddOrSetValue(iVista, ALineaRepr);
    FLineaBanda.AddOrSetValue(iVista, bpvPendiente);
  end;
end;

function TModeloPivoteVenta.ClaveGrupoLibre(
  const ADatos: TDatosLineaPivoteVenta): string;
var
  oCelda: TCeldaPivoteVenta;
  sClaveBase: string;
  iLineaRepr, iRepeticion: Integer;
  bOcupada: Boolean;
  rPrecioClave: Double;
begin
  rPrecioClave := ADatos.Precio;
  if FAgruparSinPrecio then
    rPrecioClave := 0;
  sClaveBase := ClaveGrupoPivoteVenta(ADatos.Articulo,
    ADatos.Info.ColorAv, rPrecioClave, ADatos.Info.TallaAv,
    ADatos.LineaTexto);
  // Cada copa es una fila propia; sin copa la clave es la de siempre.
  if ADatos.Info.PestanaTexto <> '' then
    sClaveBase := sClaveBase + '|C' + ADatos.Info.PestanaTexto;
  sClaveBase := sClaveBase + '|DTO' +
    FloatToStr(ADatos.PorcentajeDto, TFormatSettings.Invariant);
  Result := sClaveBase;
  iRepeticion := 1;
  repeat
    bOcupada := (ADatos.Info.TallaAv > 0) and
      FClavesGrupo.TryGetValue(Result, iLineaRepr) and
      FCeldas.TryGetValue(
        ClaveCeldaPivoteVenta(iLineaRepr, ADatos.Info.TallaAv),
        oCelda) and
      (oCelda.Linea <> ADatos.LineaTexto);
    if bOcupada then
    begin
      Inc(iRepeticion);
      Result := sClaveBase + '|R' + IntToStr(iRepeticion);
    end;
  until not bOcupada;
end;

function TModeloPivoteVenta.RegistrarLinea(
  const ADatos: TDatosLineaPivoteVenta; out ALineaRepr: Integer;
  out AGrupoNuevo: Boolean): Boolean;
var
  oGrupo: TGrupoPivoteVenta;
  oCelda: TCeldaPivoteVenta;
  sClave, sTipoCantidad, sPrefijo, sVarSku: string;
  iClaveCelda: Int64;
  iTalla, i: Integer;
  bTallaNueva: Boolean;
begin
  ALineaRepr := 0;
  AGrupoNuevo := False;
  Result := (ADatos.Articulo <> '') and (ADatos.Linea > 0);
  if Result then
  begin
    sTipoCantidad := ADatos.TipoCantidad;
    if sTipoCantidad = '' then
      sTipoCantidad := 'Uds';
    if not EsTipoCantidadPredeterminadoPivote(sTipoCantidad) then
      FHayTipoCantidadEspecial := True;
    if (ADatos.Info.ColorAv > 0) or
       (Trim(ADatos.Info.ColorTexto) <> '') or
       (Trim(ADatos.Info.ColorCodigo) <> '') then
      FHayColor := True;
    sClave := ClaveGrupoLibre(ADatos);
    if not FClavesGrupo.TryGetValue(sClave, ALineaRepr) then
    begin
      ALineaRepr := ADatos.Linea;
      AGrupoNuevo := True;
      FClavesGrupo.Add(sClave, ALineaRepr);
      oGrupo := Default(TGrupoPivoteVenta);
      oGrupo.Articulo := ADatos.Articulo;
      oGrupo.Precio := ADatos.Precio;
      oGrupo.PorcentajeDto := ADatos.PorcentajeDto;
      oGrupo.TipoCantidad := sTipoCantidad;
      oGrupo.ColorAv := ADatos.Info.ColorAv;
      oGrupo.ColorTexto := ADatos.Info.ColorTexto;
      oGrupo.ColorCodigo := ADatos.Info.ColorCodigo;
      oGrupo.PestanaTexto := ADatos.Info.PestanaTexto;
      sPrefijo := PrefijoSkuTallaPivoteVenta(ADatos.Sku);
      if sPrefijo = '' then
        sPrefijo := ADatos.Articulo;
      oGrupo.SkuPrefijo := sPrefijo;
      oGrupo.SkuBase := ADatos.Sku;
      sVarSku := ADatos.Info.VarSku;
      if sVarSku = '' then
        sVarSku := 'TC';
      oGrupo.VarSku := sVarSku;
      FGrupos.Add(ALineaRepr, oGrupo);
      RegistrarBandasGrupo(ALineaRepr);
    end;
    oGrupo := FGrupos[ALineaRepr];
    oGrupo.PreciosDistintos := oGrupo.PreciosDistintos or
      (Abs(oGrupo.Precio - ADatos.Precio) > 0.000001);
    if not EsTipoCantidadPredeterminadoPivote(sTipoCantidad) then
      oGrupo.TipoCantidad := sTipoCantidad;
    oGrupo.UdsGrupo := oGrupo.UdsGrupo + ADatos.Pedida;
    if ADatos.Info.TallaAv > 0 then
    begin
      iTalla := ADatos.Info.TallaAv;
      bTallaNueva := True;
      for i := 0 to High(oGrupo.Tallas) do
        if oGrupo.Tallas[i] = iTalla then
          bTallaNueva := False;
      if bTallaNueva then
      begin
        SetLength(oGrupo.Tallas, Length(oGrupo.Tallas) + 1);
        oGrupo.Tallas[High(oGrupo.Tallas)] := iTalla;
      end;
    end
    else
    begin
      iTalla := ID_AV_SIN_TALLA_PIVOTE;
      oGrupo.SinTalla := True;
    end;
    FGrupos[ALineaRepr] := oGrupo;
    iClaveCelda := ClaveCeldaPivoteVenta(ALineaRepr, iTalla);
    oCelda := Default(TCeldaPivoteVenta);
    oCelda.Pedida := ADatos.Pedida;
    oCelda.Entregada := ADatos.Entregada;
    oCelda.AAlbaranar := ADatos.AAlbaranar;
    oCelda.Sku := ADatos.Sku;
    oCelda.Linea := ADatos.LineaTexto;
    oCelda.Almacen := ADatos.Almacen;
    FCeldas.AddOrSetValue(iClaveCelda, oCelda);
  end;
end;

procedure TModeloPivoteVenta.AnexarTallasFaltantes(
  var APosiciones: TValoresTallaPivoteVenta;
  const ATallas: TValoresTallaPivoteVenta);
var
  i, j: Integer;
  bPresente: Boolean;
begin
  for i := 0 to High(ATallas) do
  begin
    bPresente := False;
    for j := 0 to High(APosiciones) do
      if APosiciones[j].IdAv = ATallas[i].IdAv then
        bPresente := True;
    if not bPresente then
    begin
      SetLength(APosiciones, Length(APosiciones) + 1);
      APosiciones[High(APosiciones)] := ATallas[i];
    end;
  end;
end;

function TModeloPivoteVenta.RecortarTallasHorizontal(
  const AArticulo: string; var APosiciones: TValoresTallaPivoteVenta;
  const ATallasGrupo: TArray<Integer>): Boolean;
var
  aIds, aVisibles: TArray<Integer>;
  aRecorte: TValoresTallaPivoteVenta;
  i: Integer;
begin
  Result := Length(APosiciones) > MAX_TALLAS_HORIZONTAL;
  if Result then
  begin
    FTallasRecortadas.AddOrSetValue(AArticulo, Length(APosiciones));
    SetLength(aIds, Length(APosiciones));
    for i := 0 to High(APosiciones) do
      aIds[i] := APosiciones[i].IdAv;
    aVisibles := IndicesTallasHorizontal(aIds, ATallasGrupo,
      MAX_TALLAS_HORIZONTAL);
    SetLength(aRecorte, Length(aVisibles));
    for i := 0 to High(aVisibles) do
      aRecorte[i] := APosiciones[aVisibles[i]];
    APosiciones := aRecorte;
  end;
end;

function TModeloPivoteVenta.ResolverConjuntoGrupo(
  ALineaRepr, AConjunto: Integer;
  const ATallas: TArray<Integer>): Integer;
var
  aPosiciones, aExtra: TValoresTallaPivoteVenta;
  aFaltantes: TArray<Integer>;
  oGrupo: TGrupoPivoteVenta;
  sClave: string;
  i, j, iLongitudSistema: Integer;
  bPresente, bRecortado: Boolean;
begin
  Result := AConjunto;
  aPosiciones := nil;
  if (FRepositorio <> nil) and Grupo(ALineaRepr, oGrupo) then
  begin
    if AConjunto > 0 then
      aPosiciones := Copy(PosicionesConjunto(AConjunto));
    iLongitudSistema := Length(aPosiciones);
    if oGrupo.Articulo <> '' then
      AnexarTallasFaltantes(aPosiciones,
        FRepositorio.TallasDeArticulo(oGrupo.Articulo));
    // Red de seguridad: tallas del grupo que no salieron por el
    // artículo se anexan al final para que su celda tenga columna.
    aFaltantes := nil;
    for i := 0 to High(ATallas) do
    begin
      bPresente := False;
      for j := 0 to High(aPosiciones) do
        if aPosiciones[j].IdAv = ATallas[i] then
          bPresente := True;
      if not bPresente then
      begin
        SetLength(aFaltantes, Length(aFaltantes) + 1);
        aFaltantes[High(aFaltantes)] := ATallas[i];
      end;
    end;
    if Length(aFaltantes) > 0 then
    begin
      aExtra := FRepositorio.TallasPorIds(aFaltantes);
      AnexarTallasFaltantes(aPosiciones, aExtra);
    end;
    OrdenarTallasNumericas(aPosiciones);
    // Recortado, el sistema real ya no sirve: sus posiciones no son
    // las que se enseñan y hace falta el conjunto virtual.
    bRecortado := RecortarTallasHorizontal(oGrupo.Articulo, aPosiciones,
      ATallas);
    if (Length(aPosiciones) > 0) and
       ((AConjunto = 0) or bRecortado or
        (Length(aPosiciones) > iLongitudSistema)) then
    begin
      // Un id virtual por LISTA de tallas: dos grupos con las mismas
      // tallas comparten conjunto y captions.
      SetLength(aFaltantes, Length(aPosiciones));
      for i := 0 to High(aPosiciones) do
        aFaltantes[i] := aPosiciones[i].IdAv;
      sClave := ClaveConjuntoVirtualPivoteVenta(aFaltantes);
      if not FConjuntoVirtualIds.TryGetValue(sClave, Result) then
      begin
        Result := FProxConjuntoVirtual;
        Dec(FProxConjuntoVirtual);
        FConjuntoVirtualIds.Add(sClave, Result);
      end;
      // Re-registrar SIEMPRE: las tallas del artículo pueden crecer
      // (alta de SKU desde una celda).
      FPosConjuntos.AddOrSetValue(Result, aPosiciones);
    end;
  end;
end;

procedure TModeloPivoteVenta.CompletarCarga;
var
  aLineasRepr: TArray<Integer>;
  oGrupo: TGrupoPivoteVenta;
  iAc, i: Integer;
begin
  aLineasRepr := FGrupos.Keys.ToArray;
  for i := 0 to High(aLineasRepr) do
  begin
    oGrupo := FGrupos[aLineasRepr[i]];
    if Length(oGrupo.Tallas) > 0 then
    begin
      iAc := 0;
      if FRepositorio <> nil then
        iAc := FRepositorio.ResolverConjuntoArticulo(
          oGrupo.Articulo, oGrupo.Tallas);
      // Incluir tambien tallas de SKU aun sin cantidad en el documento.
      iAc := ResolverConjuntoGrupo(aLineasRepr[i], iAc, oGrupo.Tallas);
      if iAc <> 0 then
      begin
        oGrupo.IdAc := iAc;
        FGrupos[aLineasRepr[i]] := oGrupo;
      end
      else
        // Error DOCUMENTADO: sin conjunto (ni real ni virtual) las
        // celdas del grupo no tienen columna donde pintarse.
        FGruposSinConjunto.Add(aLineasRepr[i]);
    end;
  end;
  AjustarAAlbaranarCeldas;
end;

procedure TModeloPivoteVenta.AjustarAAlbaranarCeldas;
var
  aClaves: TArray<Int64>;
  oCelda: TCeldaPivoteVenta;
  rAjustado: Double;
  i: Integer;
begin
  aClaves := FCeldas.Keys.ToArray;
  for i := 0 to High(aClaves) do
  begin
    oCelda := FCeldas[aClaves[i]];
    rAjustado := AjustarAAlbaranarPivoteVenta(oCelda.Pedida,
      oCelda.Entregada, oCelda.AAlbaranar);
    if Abs(rAjustado - oCelda.AAlbaranar) > 0.000001 then
    begin
      oCelda.AAlbaranar := rAjustado;
      FCeldas[aClaves[i]] := oCelda;
    end;
  end;
end;

function TModeloPivoteVenta.ObtenerInfoSku(const ACodigoSku: string;
  out AInfo: TInfoSkuPivoteVenta): Boolean;
var
  sSku: string;
begin
  sSku := Trim(ACodigoSku);
  AInfo := Default(TInfoSkuPivoteVenta);
  Result := False;
  if sSku <> '' then
  begin
    if FSkuInfo.TryGetValue(UpperCase(sSku), AInfo) then
      Result := True
    else if FRepositorio <> nil then
    begin
      AInfo := FRepositorio.ObtenerInfoSku(sSku);
      Result := AInfo.Encontrado;
      if Result then
        FSkuInfo.AddOrSetValue(UpperCase(sSku), AInfo);
    end;
  end;
end;

function TModeloPivoteVenta.ResolverInfoLinea(
  const ACampos: TCamposEntradaLineaPivote; out ASku: string;
  out AInfo: TInfoSkuPivoteVenta): Boolean;
var
  oInfoBarras: TInfoSkuPivoteVenta;
  sSkuBarras: string;
  function ProbarSku(const ACandidato: string): Boolean;
  var
    sCand: string;
  begin
    sCand := Trim(ACandidato);
    Result := (sCand <> '') and ObtenerInfoSku(sCand, AInfo);
    if Result then
      ASku := sCand;
  end;
begin
  ASku := '';
  AInfo := Default(TInfoSkuPivoteVenta);
  Result := ProbarSku(ACampos.Sku);
  if not Result then
    Result := ProbarSku(ACampos.SkuAlternativo);
  if (not Result) and (ACampos.CodigoBarras <> '') and
     (FRepositorio <> nil) then
  begin
    sSkuBarras :=
      FRepositorio.ResolverSkuDesdeCodigoBarras(ACampos.CodigoBarras);
    if (sSkuBarras <> '') and
       ObtenerInfoSku(sSkuBarras, oInfoBarras) then
    begin
      ASku := sSkuBarras;
      AInfo := oInfoBarras;
      Result := True;
    end;
  end;
  // El SKU de la línea puede venir sin talla: el código de barras
  // permite completarla con el SKU real escaneado.
  if Result and (AInfo.TallaAv <= 0) and
     (ACampos.CodigoBarras <> '') and (FRepositorio <> nil) then
  begin
    sSkuBarras :=
      FRepositorio.ResolverSkuDesdeCodigoBarras(ACampos.CodigoBarras);
    if (sSkuBarras <> '') and
       ObtenerInfoSku(sSkuBarras, oInfoBarras) and
       (oInfoBarras.TallaAv > 0) then
    begin
      ASku := sSkuBarras;
      AInfo := oInfoBarras;
    end;
  end;
  if not Result then
    Result := ProbarSku(ACampos.CodigoProdPs);
  if (not Result) and (ACampos.Articulo <> '') and
     (FRepositorio <> nil) then
    Result := ProbarSku(
      FRepositorio.ResolverSkuUnicoArticulo(ACampos.Articulo));
  if (not Result) and (ASku = '') then
  begin
    ASku := ACampos.Sku;
    if ASku = '' then
      ASku := ACampos.CodigoProdPs;
  end;
end;

function TModeloPivoteVenta.PosicionesConjunto(AIdAc: Integer)
  : TValoresTallaPivoteVenta;
begin
  Result := nil;
  if not FPosConjuntos.TryGetValue(AIdAc, Result) then
  begin
    // Ids negativos = conjuntos virtuales: solo existen en caché.
    if (AIdAc > 0) and (FRepositorio <> nil) then
    begin
      Result := FRepositorio.PosicionesConjunto(AIdAc);
      OrdenarTallasNumericas(Result);
      FPosConjuntos.Add(AIdAc, Result);
    end;
  end;
end;

function TModeloPivoteVenta.ObtenerLineaBase(ALinea: Integer): Integer;
begin
  if not FLineaBase.TryGetValue(ALinea, Result) then
    Result := ALinea;
end;

function TModeloPivoteVenta.BandaDesdeLinea(ALinea: Integer)
  : TBandaPivoteVenta;
begin
  if not FLineaBanda.TryGetValue(ALinea, Result) then
    Result := bpvPedida;
end;

function TModeloPivoteVenta.EsLineaVista(ALinea: Integer): Boolean;
begin
  Result := FLineaBase.ContainsKey(ALinea);
end;

function TModeloPivoteVenta.Grupo(ALineaBase: Integer;
  out AGrupo: TGrupoPivoteVenta): Boolean;
begin
  Result := FGrupos.TryGetValue(ALineaBase, AGrupo);
  if not Result then
    AGrupo := Default(TGrupoPivoteVenta);
end;

function TModeloPivoteVenta.Celda(AClave: Int64;
  out ACelda: TCeldaPivoteVenta): Boolean;
begin
  Result := FCeldas.TryGetValue(AClave, ACelda);
  if not Result then
    ACelda := Default(TCeldaPivoteVenta);
end;

function TModeloPivoteVenta.UdsGrupoDeLineaVista(ALineaVista: Integer;
  out AUds: Double): Boolean;
var
  oGrupo: TGrupoPivoteVenta;
  iBase: Integer;
begin
  AUds := 0;
  Result := FLineaBase.TryGetValue(ALineaVista, iBase) and
            Grupo(iBase, oGrupo);
  if Result then
    AUds := oGrupo.UdsGrupo;
end;

function TModeloPivoteVenta.ValorCantidadBanda(AClave: Int64;
  ABanda: TBandaPivoteVenta): Double;
var
  oCelda: TCeldaPivoteVenta;
begin
  case ABanda of
    bpvPedida:
      begin
        Celda(AClave, oCelda);
        Result := oCelda.Pedida;
      end;
    bpvEntregada:
      Result := AAlbaranarCelda(AClave);
  else
    Result := PendienteCelda(AClave);
  end;
end;

function TModeloPivoteVenta.PendienteBaseCelda(AClave: Int64): Double;
var
  oCelda: TCeldaPivoteVenta;
begin
  Celda(AClave, oCelda);
  Result := PendienteBasePivoteVenta(oCelda.Pedida, oCelda.Entregada);
end;

function TModeloPivoteVenta.PendienteCelda(AClave: Int64): Double;
var
  oCelda: TCeldaPivoteVenta;
begin
  Celda(AClave, oCelda);
  Result := PendientePivoteVenta(oCelda.Pedida, oCelda.Entregada,
                                 oCelda.AAlbaranar);
end;

function TModeloPivoteVenta.AAlbaranarCelda(AClave: Int64): Double;
var
  oCelda: TCeldaPivoteVenta;
begin
  Celda(AClave, oCelda);
  Result := oCelda.AAlbaranar;
end;

function TModeloPivoteVenta.TextoBanda(
  ABanda: TBandaPivoteVenta): string;
begin
  Result := TextoBandaPivoteVenta(ABanda, FBandaUnica,
                                  FTextoAAlbaranar);
end;

function TModeloPivoteVenta.TextoTipoCantidad(ALineaBase: Integer;
  ABanda: TBandaPivoteVenta): string;
var
  oGrupo: TGrupoPivoteVenta;
  sTipoCantidad: string;
begin
  sTipoCantidad := 'Uds';
  if Grupo(ALineaBase, oGrupo) and (oGrupo.TipoCantidad <> '') then
    sTipoCantidad := oGrupo.TipoCantidad;
  Result := TextoTipoCantidadPivoteVenta(sTipoCantidad, ABanda,
    FBandaUnica, FTextoAAlbaranar);
end;

function TModeloPivoteVenta.TallaAvEnPosicion(ALineaBase,
  APosicion: Integer; out AIdAv: Integer): Boolean;
var
  oGrupo: TGrupoPivoteVenta;
  aPosiciones: TValoresTallaPivoteVenta;
begin
  Result := False;
  AIdAv := 0;
  if (ALineaBase > 0) and (APosicion >= 1) and
     Grupo(ALineaBase, oGrupo) then
  begin
    if oGrupo.SinTalla then
    begin
      Result := APosicion = 1;
      if Result then
        AIdAv := ID_AV_SIN_TALLA_PIVOTE;
    end
    else if oGrupo.IdAc <> 0 then
    begin
      aPosiciones := PosicionesConjunto(oGrupo.IdAc);
      Result := APosicion <= Length(aPosiciones);
      if Result then
        AIdAv := aPosiciones[APosicion - 1].IdAv;
    end;
  end;
end;

function TModeloPivoteVenta.MaxPosicionesVisibles(
  AMaxColumnas: Integer): Integer;
var
  aLineasRepr: TArray<Integer>;
  oGrupo: TGrupoPivoteVenta;
  i, iLen: Integer;
  bHaySinTalla: Boolean;
begin
  Result := 0;
  bHaySinTalla := False;
  aLineasRepr := FGrupos.Keys.ToArray;
  for i := 0 to High(aLineasRepr) do
  begin
    oGrupo := FGrupos[aLineasRepr[i]];
    if oGrupo.SinTalla then
      bHaySinTalla := True;
    if oGrupo.IdAc <> 0 then
    begin
      iLen := Length(PosicionesConjunto(oGrupo.IdAc));
      if iLen > Result then
        Result := iLen;
    end;
  end;
  if bHaySinTalla and (Result < 1) then
    Result := 1;
  if Result > AMaxColumnas then
    Result := AMaxColumnas;
end;

function TModeloPivoteVenta.MarcarTodoAAlbaranarEnCache: Integer;
var
  aClaves: TArray<Int64>;
  oCelda: TCeldaPivoteVenta;
  rPendiente: Double;
  i: Integer;
begin
  Result := 0;
  aClaves := FCeldas.Keys.ToArray;
  for i := 0 to High(aClaves) do
  begin
    oCelda := FCeldas[aClaves[i]];
    rPendiente := PendienteBasePivoteVenta(oCelda.Pedida,
                                           oCelda.Entregada);
    if rPendiente > 0 then
    begin
      oCelda.AAlbaranar := rPendiente;
      FCeldas[aClaves[i]] := oCelda;
      Inc(Result);
    end;
  end;
end;

procedure TModeloPivoteVenta.LimpiarAAlbaranarEnCache;
var
  aClaves: TArray<Int64>;
  oCelda: TCeldaPivoteVenta;
  i: Integer;
begin
  aClaves := FCeldas.Keys.ToArray;
  for i := 0 to High(aClaves) do
  begin
    oCelda := FCeldas[aClaves[i]];
    if oCelda.AAlbaranar <> 0 then
    begin
      oCelda.AAlbaranar := 0;
      FCeldas[aClaves[i]] := oCelda;
    end;
  end;
end;

function TModeloPivoteVenta.VolcarAAlbaranar(
  ALineas: TList<TPair<string, Currency>>; out AAlmacenComun: string;
  out AAlmacenUnico: Boolean): Integer;
var
  oPar: TPair<Int64, TCeldaPivoteVenta>;
  oLin: TPair<string, Currency>;
  bAlmacenIniciado: Boolean;
begin
  Result := 0;
  AAlmacenComun := '';
  AAlmacenUnico := True;
  bAlmacenIniciado := False;
  if ALineas <> nil then
  begin
    for oPar in FCeldas do
    begin
      if oPar.Value.AAlbaranar > 0 then
      begin
        oLin.Key := oPar.Value.Linea;
        oLin.Value := oPar.Value.Entregada + oPar.Value.AAlbaranar;
        ALineas.Add(oLin);
        if not bAlmacenIniciado then
        begin
          AAlmacenComun := oPar.Value.Almacen;
          bAlmacenIniciado := True;
        end
        else if oPar.Value.Almacen <> AAlmacenComun then
          AAlmacenUnico := False;
        Inc(Result);
      end;
    end;
  end;
end;

function TModeloPivoteVenta.LineasRealesDeGrupo(
  ALineaBase: Integer): TArray<string>;
var
  oPar: TPair<Int64, TCeldaPivoteVenta>;
  oLineas: TList<string>;
begin
  oLineas := TList<string>.Create;
  try
    for oPar in FCeldas do
      if LineaBaseDesdeClaveCelda(oPar.Key) = ALineaBase then
        if not oLineas.Contains(oPar.Value.Linea) then
          oLineas.Add(oPar.Value.Linea);
    Result := oLineas.ToArray;
  finally
    FreeAndNil(oLineas);
  end;
end;

function TModeloPivoteVenta.GruposSinConjunto: TArray<Integer>;
begin
  Result := FGruposSinConjunto.ToArray;
end;

function TModeloPivoteVenta.TallasRecortadas
  : TArray<TPair<string, Integer>>;
begin
  Result := FTallasRecortadas.ToArray;
end;

end.
