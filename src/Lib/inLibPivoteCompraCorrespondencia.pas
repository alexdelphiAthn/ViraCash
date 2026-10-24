{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPivoteCompraCorrespondencia                              }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Caché y correspondencia entre filas, celdas, líneas reales y SKUs.       }
{******************************************************************************}
unit inLibPivoteCompraCorrespondencia;

interface

uses
  System.SysUtils, System.Variants, System.Generics.Collections,
  Data.DB,
  inLibGridPivoteCompraTipos,
  inLibGridPivoteCompraPersistenciaIntf;

type
  TCachePivoteCompra = class
  private
    FLineasRepresentantes: TList<Integer>;
    FCantidades           : TDictionary<Int64, Double>;
    FCantidadesRecibidas  : TDictionary<Int64, Double>;
    FTotalPedido          : TDictionary<Integer, Double>;
    FTotalRecibido        : TDictionary<Integer, Double>;
    FCeldaSku             : TDictionary<Int64, string>;
    FCeldaAlmacen         : TDictionary<Int64, string>;
    FCeldaLineaPedido     : TDictionary<Int64, string>;
    FColorTexto           : TDictionary<Integer, string>;
    FColorProveedor       : TDictionary<Integer, string>;
    FColorCodigo          : TDictionary<Integer, string>;
    FIdConjunto           : TDictionary<Integer, Integer>;
    FArticulo             : TDictionary<Integer, string>;
    FColorAtributo        : TDictionary<Integer, Integer>;
    FAlmacen              : TDictionary<Integer, string>;
    FSkuBase              : TDictionary<Integer, string>;
    FSkuPrefijo           : TDictionary<Integer, string>;
    // Copa (eje de pestañas) del grupo; '' con «Tallas y colores».
    FPestanaTexto         : TDictionary<Integer, string>;
    FVariacionSku         : TDictionary<Integer, string>;
    FSinTalla             : TDictionary<Integer, Boolean>;
    FMaximoAtributoTalla  : Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Limpiar;
    function ArticuloLinea(ALinea: Integer): string;
    property LineasRepresentantes: TList<Integer>
      read FLineasRepresentantes;
    property Cantidades: TDictionary<Int64, Double> read FCantidades;
    property CantidadesRecibidas: TDictionary<Int64, Double>
      read FCantidadesRecibidas;
    property TotalPedido: TDictionary<Integer, Double> read FTotalPedido;
    property TotalRecibido: TDictionary<Integer, Double>
      read FTotalRecibido;
    property CeldaSku: TDictionary<Int64, string> read FCeldaSku;
    property CeldaAlmacen: TDictionary<Int64, string> read FCeldaAlmacen;
    property CeldaLineaPedido: TDictionary<Int64, string>
      read FCeldaLineaPedido;
    property ColorTexto: TDictionary<Integer, string> read FColorTexto;
    property ColorProveedor: TDictionary<Integer, string>
      read FColorProveedor;
    property ColorCodigo: TDictionary<Integer, string> read FColorCodigo;
    property IdConjunto: TDictionary<Integer, Integer> read FIdConjunto;
    property Articulo: TDictionary<Integer, string> read FArticulo;
    property ColorAtributo: TDictionary<Integer, Integer>
      read FColorAtributo;
    property Almacen: TDictionary<Integer, string> read FAlmacen;
    property SkuBase: TDictionary<Integer, string> read FSkuBase;
    property SkuPrefijo: TDictionary<Integer, string> read FSkuPrefijo;
    property PestanaTexto: TDictionary<Integer, string> read FPestanaTexto;
    property VariacionSku: TDictionary<Integer, string> read FVariacionSku;
    property SinTalla: TDictionary<Integer, Boolean> read FSinTalla;
    property MaximoAtributoTalla: Integer
      read FMaximoAtributoTalla write FMaximoAtributoTalla;
  end;

  TCorrespondenciaPivoteCompra = class
  private
    FCfg        : TGridPivoteCompraConfig;
    FRepositorio: TRepositoriosGridPivoteCompra;
    FCache      : TCachePivoteCompra;
    function CampoLineaCopiable(const ANombre: string): Boolean;
    procedure AcumularCantidad(ADiccionario: TDictionary<Int64, Double>;
      AClave: Int64; AValor: Double);
    procedure AcumularTotal(
      ADiccionario: TDictionary<Integer, Double>;
      ALinea: Integer; AValor: Double);
    procedure ActualizarCacheLineaCreada(AClave: Int64;
      const ASku, AAlmacen, ALineaReal: string; ACantidad: Double);
  public
    constructor Create(const ACfg: TGridPivoteCompraConfig;
      const ARepositorio: TRepositoriosGridPivoteCompra);
    destructor Destroy; override;
    function ObtenerSerieNumero(out ASerie, ANumero: string): Boolean;
    procedure Cargar;
    procedure Limpiar;
    function ResolverSkuCelda(AClave: Int64; out ASku: string): Boolean;
    function CrearLineaRealDesdeCelda(AClave: Int64; ACantidad: Double;
      out ALineaReal: string): Boolean;
    property Cache: TCachePivoteCompra read FCache;
  end;

implementation

uses
  inLibPivoteCompraCalculo;

constructor TCachePivoteCompra.Create;
begin
  inherited Create;
  FLineasRepresentantes := TList<Integer>.Create;
  FCantidades := TDictionary<Int64, Double>.Create;
  FCantidadesRecibidas := TDictionary<Int64, Double>.Create;
  FTotalPedido := TDictionary<Integer, Double>.Create;
  FTotalRecibido := TDictionary<Integer, Double>.Create;
  FCeldaSku := TDictionary<Int64, string>.Create;
  FCeldaAlmacen := TDictionary<Int64, string>.Create;
  FCeldaLineaPedido := TDictionary<Int64, string>.Create;
  FColorTexto := TDictionary<Integer, string>.Create;
  FColorProveedor := TDictionary<Integer, string>.Create;
  FColorCodigo := TDictionary<Integer, string>.Create;
  FIdConjunto := TDictionary<Integer, Integer>.Create;
  FArticulo := TDictionary<Integer, string>.Create;
  FColorAtributo := TDictionary<Integer, Integer>.Create;
  FAlmacen := TDictionary<Integer, string>.Create;
  FSkuBase := TDictionary<Integer, string>.Create;
  FSkuPrefijo := TDictionary<Integer, string>.Create;
  FPestanaTexto := TDictionary<Integer, string>.Create;
  FVariacionSku := TDictionary<Integer, string>.Create;
  FSinTalla := TDictionary<Integer, Boolean>.Create;
  FMaximoAtributoTalla := 0;
end;

destructor TCachePivoteCompra.Destroy;
begin
  FreeAndNil(FSinTalla);
  FreeAndNil(FVariacionSku);
  FreeAndNil(FPestanaTexto);
  FreeAndNil(FSkuPrefijo);
  FreeAndNil(FSkuBase);
  FreeAndNil(FAlmacen);
  FreeAndNil(FColorAtributo);
  FreeAndNil(FArticulo);
  FreeAndNil(FIdConjunto);
  FreeAndNil(FColorCodigo);
  FreeAndNil(FColorProveedor);
  FreeAndNil(FColorTexto);
  FreeAndNil(FCeldaLineaPedido);
  FreeAndNil(FCeldaAlmacen);
  FreeAndNil(FCeldaSku);
  FreeAndNil(FTotalRecibido);
  FreeAndNil(FTotalPedido);
  FreeAndNil(FCantidadesRecibidas);
  FreeAndNil(FCantidades);
  FreeAndNil(FLineasRepresentantes);
  inherited;
end;

function TCachePivoteCompra.ArticuloLinea(ALinea: Integer): string;
begin
  if not FArticulo.TryGetValue(ALinea, Result) then
    Result := '';
end;

procedure TCachePivoteCompra.Limpiar;
begin
  FLineasRepresentantes.Clear;
  FCantidades.Clear;
  FCantidadesRecibidas.Clear;
  FTotalPedido.Clear;
  FTotalRecibido.Clear;
  FCeldaSku.Clear;
  FCeldaAlmacen.Clear;
  FCeldaLineaPedido.Clear;
  FColorTexto.Clear;
  FColorProveedor.Clear;
  FColorCodigo.Clear;
  FIdConjunto.Clear;
  FArticulo.Clear;
  FColorAtributo.Clear;
  FAlmacen.Clear;
  FSkuBase.Clear;
  FSkuPrefijo.Clear;
  FPestanaTexto.Clear;
  FVariacionSku.Clear;
  FSinTalla.Clear;
  FMaximoAtributoTalla := 0;
end;

constructor TCorrespondenciaPivoteCompra.Create(
  const ACfg: TGridPivoteCompraConfig;
  const ARepositorio: TRepositoriosGridPivoteCompra);
begin
  inherited Create;
  FCfg := ACfg;
  FRepositorio := ARepositorio;
  FCache := TCachePivoteCompra.Create;
end;

destructor TCorrespondenciaPivoteCompra.Destroy;
begin
  FreeAndNil(FCache);
  FRepositorio := Default(TRepositoriosGridPivoteCompra);
  inherited;
end;

function TCorrespondenciaPivoteCompra.ObtenerSerieNumero(
  out ASerie, ANumero: string): Boolean;
var
  bDisponible: Boolean;
begin
  ASerie := '';
  ANumero := '';
  bDisponible := (FCfg.SourceMaster <> nil) and
    (FCfg.SourceMaster.DataSet <> nil) and
    FCfg.SourceMaster.DataSet.Active and
    (not FCfg.SourceMaster.DataSet.IsEmpty);
  if bDisponible then
  begin
    ASerie := FCfg.SourceMaster.DataSet.FieldByName(
      FCfg.FieldSerieMaster).AsString;
    ANumero := FCfg.SourceMaster.DataSet.FieldByName(
      FCfg.FieldNumeroMaster).AsString;
  end;
  Result := bDisponible and (ASerie <> '') and (ANumero <> '');
end;

procedure TCorrespondenciaPivoteCompra.AcumularCantidad(
  ADiccionario: TDictionary<Int64, Double>;
  AClave: Int64; AValor: Double);
begin
  if ADiccionario.ContainsKey(AClave) then
    ADiccionario[AClave] := ADiccionario[AClave] + AValor
  else
    ADiccionario.Add(AClave, AValor);
end;

procedure TCorrespondenciaPivoteCompra.AcumularTotal(
  ADiccionario: TDictionary<Integer, Double>;
  ALinea: Integer; AValor: Double);
begin
  if ADiccionario.ContainsKey(ALinea) then
    ADiccionario[ALinea] := ADiccionario[ALinea] + AValor
  else
    ADiccionario.Add(ALinea, AValor);
end;

procedure TCorrespondenciaPivoteCompra.Cargar;
var
  oConsulta       : TDataSet;
  oRepresentantes : TDictionary<string, Integer>;
  sSerie          : string;
  sNumero         : string;
  sArticulo       : string;
  sClaveGrupo     : string;
  sSku            : string;
  sAlmacenLinea   : string;
  sAlmacenCabecera: string;
  sAlmacenEfectivo: string;
  sLineaReal      : string;
  sVariacionSku   : string;
  sPestana        : string;
  iLinea          : Integer;
  iConjunto       : Integer;
  iColor          : Integer;
  iTalla          : Integer;
  iLineaRepr      : Integer;
  iClaveCelda     : Int64;
  dCantidad       : Double;
  dRecibida       : Double;
begin
  FCache.Limpiar;
  if (FCfg.SourceLineas <> nil) and
     ObtenerSerieNumero(sSerie, sNumero) then
  begin
    sAlmacenCabecera := '';
    if (FCfg.FieldAlmacenMaster <> '') and
       (FCfg.SourceMaster <> nil) and
       (FCfg.SourceMaster.DataSet <> nil) and
       FCfg.SourceMaster.DataSet.Active and
       (not FCfg.SourceMaster.DataSet.IsEmpty) then
      sAlmacenCabecera := FCfg.SourceMaster.DataSet.FieldByName(
        FCfg.FieldAlmacenMaster).AsString;
    oRepresentantes := TDictionary<string, Integer>.Create;
    oConsulta := nil;
    try
      oConsulta := FRepositorio.Lineas.BuscarLineasPivote(
        sSerie, sNumero);
      while not oConsulta.Eof do
      begin
        iLinea := oConsulta.FieldByName('LINEA').AsInteger;
        sArticulo := oConsulta.FieldByName('ART').AsString;
        iConjunto := oConsulta.FieldByName('ID_AC').AsInteger;
        iColor := oConsulta.FieldByName('COLOR_AV').AsInteger;
        iTalla := oConsulta.FieldByName('TALLA_AV').AsInteger;
        dCantidad := oConsulta.FieldByName('CANTIDAD').AsFloat;
        dRecibida := oConsulta.FieldByName('RECIBIDA').AsFloat;
        sSku := oConsulta.FieldByName('SKU').AsString;
        sVariacionSku := oConsulta.FieldByName('VAR_SKU').AsString;
        sAlmacenLinea := oConsulta.FieldByName('ALM_LIN').AsString;
        sLineaReal := oConsulta.FieldByName('LINEA').AsString;
        sAlmacenEfectivo := sAlmacenCabecera;
        if Trim(sAlmacenLinea) <> '' then
          sAlmacenEfectivo := sAlmacenLinea;
        // Cada copa es una fila propia (tercera dimensión).
        sPestana := oConsulta.FieldByName('PESTANA_TXT').AsString;
        sClaveGrupo := sArticulo + '|' + IntToStr(iColor) + '|' + sPestana;
        if not oRepresentantes.TryGetValue(sClaveGrupo, iLineaRepr) then
        begin
          iLineaRepr := iLinea;
          oRepresentantes.Add(sClaveGrupo, iLineaRepr);
          FCache.LineasRepresentantes.Add(iLineaRepr);
          FCache.ColorTexto.AddOrSetValue(iLineaRepr,
            oConsulta.FieldByName('COLOR_TXT').AsString);
          FCache.ColorProveedor.AddOrSetValue(iLineaRepr,
            oConsulta.FieldByName('COLOR_PROV_TXT').AsString);
          FCache.ColorCodigo.AddOrSetValue(iLineaRepr,
            oConsulta.FieldByName('COLOR_COD').AsString);
          FCache.IdConjunto.AddOrSetValue(iLineaRepr, iConjunto);
          FCache.Articulo.AddOrSetValue(iLineaRepr, sArticulo);
          FCache.ColorAtributo.AddOrSetValue(iLineaRepr, iColor);
          FCache.Almacen.AddOrSetValue(iLineaRepr, sAlmacenEfectivo);
          FCache.SkuBase.AddOrSetValue(iLineaRepr, sSku);
          FCache.SkuPrefijo.AddOrSetValue(iLineaRepr,
            PrefijoSkuTallaPivoteCompra(sSku));
          FCache.VariacionSku.AddOrSetValue(iLineaRepr, sVariacionSku);
          FCache.PestanaTexto.AddOrSetValue(iLineaRepr, sPestana);
        end;
        AcumularTotal(FCache.TotalPedido, iLineaRepr, dCantidad);
        AcumularTotal(FCache.TotalRecibido, iLineaRepr, dRecibida);
        if iTalla > 0 then
        begin
          iClaveCelda := ClaveCeldaPivoteCompra(iLineaRepr, iTalla);
          AcumularCantidad(FCache.Cantidades,
            iClaveCelda, dCantidad);
          AcumularCantidad(FCache.CantidadesRecibidas,
            iClaveCelda, dRecibida);
          FCache.CeldaSku.AddOrSetValue(iClaveCelda, sSku);
          FCache.CeldaAlmacen.AddOrSetValue(iClaveCelda,
            sAlmacenEfectivo);
          FCache.CeldaLineaPedido.AddOrSetValue(iClaveCelda, sLineaReal);
          if iTalla > FCache.MaximoAtributoTalla then
            FCache.MaximoAtributoTalla := iTalla;
        end;
        if (iTalla <= 0) and (iConjunto <= 0) then
        begin
          FCache.SinTalla.AddOrSetValue(iLineaRepr, True);
          iClaveCelda := ClaveCeldaPivoteCompra(iLineaRepr,
            ID_AV_SIN_TALLA);
          AcumularCantidad(FCache.Cantidades,
            iClaveCelda, dCantidad);
          AcumularCantidad(FCache.CantidadesRecibidas,
            iClaveCelda, dRecibida);
          FCache.CeldaSku.AddOrSetValue(iClaveCelda, sSku);
          FCache.CeldaAlmacen.AddOrSetValue(iClaveCelda,
            sAlmacenEfectivo);
          FCache.CeldaLineaPedido.AddOrSetValue(iClaveCelda, sLineaReal);
        end;
        oConsulta.Next;
      end;
    finally
      FreeAndNil(oConsulta);
      FreeAndNil(oRepresentantes);
    end;
  end;
end;

procedure TCorrespondenciaPivoteCompra.Limpiar;
begin
  FCache.Limpiar;
end;

function TCorrespondenciaPivoteCompra.CampoLineaCopiable(
  const ANombre: string): Boolean;
var
  sNombre: string;
begin
  sNombre := UpperCase(Trim(ANombre));
  Result := sNombre <> '';
  if Result then
    Result := not SameText(ANombre, FCfg.FieldSerieLin);
  if Result then
    Result := not SameText(ANombre, FCfg.FieldNumeroLin);
  if Result then
    Result := not SameText(ANombre, FCfg.FieldLinea);
  if Result then
    Result := not SameText(ANombre, FCfg.FieldCantidad);
  if Result then
    Result := not SameText(ANombre, FCfg.FieldTotalUds);
  if Result then
    Result := not SameText(ANombre, FCfg.FieldTotalLinea);
  if Result then
    Result := not SameText(ANombre, FCfg.FieldCantidadRecibida);
  if Result then
    Result := sNombre <> 'INSTANTE_ALTA';
  if Result then
    Result := sNombre <> 'INSTANTE_MODIF';
  if Result then
    Result := sNombre <> 'USUARIO_ALTA';
  if Result then
    Result := sNombre <> 'USUARIO_MODIF';
  if Result then
    Result := Pos('_PEDC_ALBCLIN', sNombre) = 0;
  if Result then
    Result := Pos('_FAC_ALBCLIN', sNombre) = 0;
  if Result then
    Result := sNombre <> 'ESFACTURADA_ALBCLIN';
end;

function TCorrespondenciaPivoteCompra.ResolverSkuCelda(AClave: Int64;
  out ASku: string): Boolean;
var
  iLineaRepr: Integer;
  iTalla     : Integer;
  iColor     : Integer;
  iPestana   : Integer;
  sArticulo  : string;
  sSkuBase   : string;
  sPrefijo   : string;
  sTalla     : string;
  sVariacion : string;
begin
  ASku := '';
  Result := FCache.CeldaSku.TryGetValue(AClave, ASku) and
    (Trim(ASku) <> '');
  if (not Result) and (FCfg.Conexion <> nil) then
  begin
    iLineaRepr := LineaClavePivoteCompra(AClave);
    iTalla := AtributoClavePivoteCompra(AClave);
    sArticulo := '';
    if iTalla > 0 then
      FCache.Articulo.TryGetValue(iLineaRepr, sArticulo);
    if (iTalla > 0) and (sArticulo <> '') then
    begin
      iColor := 0;
      FCache.ColorAtributo.TryGetValue(iLineaRepr, iColor);
      // La copa (pestañas) sale del SKU de la línea del grupo; con
      // «Tallas y colores» vale 0 y la búsqueda es la de siempre.
      sSkuBase := '';
      FCache.SkuBase.TryGetValue(iLineaRepr, sSkuBase);
      iPestana := FRepositorio.Skus.IdValorPestanaSku(sSkuBase);
      ASku := FRepositorio.Skus.BuscarSku(sArticulo, iTalla, iColor,
        iPestana);
      Result := Trim(ASku) <> '';
      if not Result then
      begin
        sPrefijo := '';
        FCache.SkuPrefijo.TryGetValue(iLineaRepr, sPrefijo);
        if sPrefijo = '' then
          sPrefijo := sArticulo;
        sTalla := FRepositorio.Skus.BuscarValorAtributo(iTalla);
        if Trim(sTalla) <> '' then
        begin
          ASku := sPrefijo + '/' + sTalla;
          sVariacion := '';
          FCache.VariacionSku.TryGetValue(iLineaRepr, sVariacion);
          if sVariacion = '' then
            sVariacion := 'TC';
          FRepositorio.Skus.AsegurarSkuConAtributos(
            ASku, sArticulo, sVariacion,
            FCfg.ContextoSesion.Identidad.Usuario,
            iColor, iTalla, iPestana);
          Result := Trim(ASku) <> '';
          if Result and Assigned(FCfg.RegistroLog) then
            FCfg.RegistroLog.RegistrarInformacion(Format(
              'PivoteCompra.ResolverSku: creado/asegurado sku=%s',
              [ASku]));
        end;
      end;
    end;
  end;
end;

function TCorrespondenciaPivoteCompra.CrearLineaRealDesdeCelda(
  AClave: Int64; ACantidad: Double; out ALineaReal: string): Boolean;
var
  oValores    : TDictionary<string, Variant>;
  oParValor   : TPair<string, Variant>;
  oCampo      : TField;
  iCampo      : Integer;
  iLineaRepr  : Integer;
  iConjunto   : Integer;
  sLineaBase  : string;
  sSku        : string;
  sArticulo   : string;
  sAlmacen    : string;
  dPrecio     : Double;
  bPuedeCrear : Boolean;
  procedure PonerStringCampo(const ACampo, AValor: string);
  var
    oCampoLocal: TField;
  begin
    oCampoLocal := FCfg.SourceLineas.FindField(ACampo);
    if oCampoLocal <> nil then
      oCampoLocal.AsString := AValor;
  end;
  procedure PonerFloatCampo(const ACampo: string; AValor: Double);
  var
    oCampoLocal: TField;
  begin
    oCampoLocal := FCfg.SourceLineas.FindField(ACampo);
    if oCampoLocal <> nil then
      oCampoLocal.AsFloat := AValor;
  end;
  procedure PonerIntegerCampo(const ACampo: string; AValor: Integer);
  var
    oCampoLocal: TField;
  begin
    oCampoLocal := FCfg.SourceLineas.FindField(ACampo);
    if oCampoLocal <> nil then
      oCampoLocal.AsInteger := AValor;
  end;
begin
  ALineaReal := '';
  bPuedeCrear := (ACantidad > 0) and
    (FCfg.SourceLineas <> nil) and FCfg.SourceLineas.Active;
  iLineaRepr := LineaClavePivoteCompra(AClave);
  sLineaBase := Format('%.4d', [iLineaRepr]);
  sSku := '';
  if bPuedeCrear then
    bPuedeCrear := ResolverSkuCelda(AClave, sSku);
  if bPuedeCrear then
    bPuedeCrear := FCfg.SourceLineas.Locate(
      FCfg.FieldLinea, sLineaBase, []);
  if bPuedeCrear then
  begin
    sArticulo := '';
    FCache.Articulo.TryGetValue(iLineaRepr, sArticulo);
    iConjunto := 0;
    FCache.IdConjunto.TryGetValue(iLineaRepr, iConjunto);
    sAlmacen := '';
    FCache.Almacen.TryGetValue(iLineaRepr, sAlmacen);
    oValores := TDictionary<string, Variant>.Create;
    try
      for iCampo := 0 to FCfg.SourceLineas.Fields.Count - 1 do
      begin
        oCampo := FCfg.SourceLineas.Fields[iCampo];
        if (oCampo.FieldKind = fkData) and
           CampoLineaCopiable(oCampo.FieldName) then
          oValores.Add(oCampo.FieldName, oCampo.Value);
      end;
      FCfg.SourceLineas.Append;
      try
        for oParValor in oValores do
        begin
          oCampo := FCfg.SourceLineas.FindField(oParValor.Key);
          if (oCampo <> nil) and (oCampo.FieldKind = fkData) and
             (not oCampo.ReadOnly) then
            oCampo.Value := oParValor.Value;
        end;
        if sArticulo <> '' then
          PonerStringCampo(FCfg.FieldArt, sArticulo);
        PonerStringCampo(FCfg.FieldSku, sSku);
        PonerFloatCampo(FCfg.FieldCantidad, ACantidad);
        PonerFloatCampo(FCfg.FieldTotalUds, ACantidad);
        PonerFloatCampo(FCfg.FieldCantidadRecibida, 0);
        if iConjunto > 0 then
          PonerIntegerCampo(FCfg.FieldIdAcPivot, iConjunto);
        if sAlmacen <> '' then
          PonerStringCampo(FCfg.FieldAlmacen, sAlmacen)
        else
        begin
          oCampo := FCfg.SourceLineas.FindField(FCfg.FieldAlmacen);
          if oCampo <> nil then
            sAlmacen := oCampo.AsString;
        end;
        dPrecio := 0;
        oCampo := FCfg.SourceLineas.FindField(FCfg.FieldPrecioBase);
        if oCampo <> nil then
          dPrecio := oCampo.AsFloat;
        PonerFloatCampo(FCfg.FieldTotalLinea, ACantidad * dPrecio);
        FCfg.SourceLineas.Post;
        ALineaReal := FCfg.SourceLineas.FieldByName(
          FCfg.FieldLinea).AsString;
      except
        if FCfg.SourceLineas.State in dsEditModes then
          FCfg.SourceLineas.Cancel;
        raise;
      end;
      ActualizarCacheLineaCreada(AClave, sSku, sAlmacen,
        ALineaReal, ACantidad);
    finally
      FreeAndNil(oValores);
    end;
  end;
  Result := ALineaReal <> '';
  if Result and Assigned(FCfg.RegistroLog) then
    FCfg.RegistroLog.RegistrarInformacion(Format(
      'PivoteCompra.CrearLinea: key=%d linea=%s sku=%s cantidad=%g',
      [AClave, ALineaReal, sSku, ACantidad]));
end;

procedure TCorrespondenciaPivoteCompra.ActualizarCacheLineaCreada(
  AClave: Int64; const ASku, AAlmacen, ALineaReal: string;
  ACantidad: Double);
var
  iLineaRepr: Integer;
begin
  iLineaRepr := LineaClavePivoteCompra(AClave);
  FCache.CeldaSku.AddOrSetValue(AClave, ASku);
  FCache.CeldaAlmacen.AddOrSetValue(AClave, AAlmacen);
  FCache.CeldaLineaPedido.AddOrSetValue(AClave, ALineaReal);
  FCache.Cantidades.AddOrSetValue(AClave, ACantidad);
  FCache.CantidadesRecibidas.AddOrSetValue(AClave, 0);
  AcumularTotal(FCache.TotalPedido, iLineaRepr, ACantidad);
end;

end.
