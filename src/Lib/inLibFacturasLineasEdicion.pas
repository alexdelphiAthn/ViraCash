{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasLineasEdicion                                    }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Edición de artículos, SKU, fiscalidad y precios de líneas de factura.     }
{******************************************************************************}
unit inLibFacturasLineasEdicion;

interface

uses
  System.Generics.Collections, Data.DB, Uni,
  inLibArticulosAtributosIntf, inLibArticulosResolverIntf,
  inLibArticulosValidadorIntf, inLibFacturasLecturasIntf;

type
  TResultadoEdicionLineaFactura = record
    Aplicado: Boolean;
    RequiereSku: Boolean;
    RecalcularDesdeEditor: Boolean;
    CodigoArticulo: string;
    CodigoSku: string;
  end;

  TEditorLineasFactura = class
  private
    FCabecera: TDataSet;
    FCacheMostrarSku: TDictionary<string, Boolean>;
    FConexion: TUniConnection;
    FLineas: TDataSet;
    FLookupAtributos: IArticulosAtributosLookup;
    FResolver: IArticulosResolver;
    FRepositorioLecturas: IRepositorioLecturasFactura;
    FValidador: IArticulosValidador;
    FAplicando: Boolean;
    function AplicarEntradaComun(
      const AEntrada: string;
      APreservarSku: Boolean
    ): TResultadoEdicionLineaFactura;
    procedure AplicarDatosArticulo(
      const ADatos: TArticuloDatos;
      const APrecio: TArticuloPrecio;
      ARequiereSku: Boolean);
    procedure AplicarPrecio(
      const ADatos: TArticuloDatos;
      const APrecio: TArticuloPrecio);
    function FechaFactura: TDateTime;
    procedure SincronizarSku(
      const ACodigoArticulo, ACodigoSku: string);
    function TarifaFactura: string;
  public
    constructor Create(
      AConexion: TUniConnection;
      ACabecera, ALineas: TDataSet;
      const AValidador: IArticulosValidador;
      const AResolver: IArticulosResolver;
      const ALookupAtributos: IArticulosAtributosLookup;
      const ARepositorioLecturas: IRepositorioLecturasFactura);
    destructor Destroy; override;
    function AplicarDesdeEditor(
      const AEntrada: string
    ): TResultadoEdicionLineaFactura;
    function AplicarEntrada(
      const AEntrada: string
    ): TResultadoEdicionLineaFactura;
    procedure AplicarLineaNoCatalogo(const ACodigoArticulo: string);
    function DebeMostrarSku(const ACodigoArticulo: string): Boolean;
    function PorcentajeIva(const ATipoIva: string): Double;
    function PrecioSku(
      const ACodigoArticulo, ACodigoSku: string): Double;
    procedure VaciarCache;
  end;

// Vendedor para liquidar comisiones: al cambiar el de la cabecera lo
// siguen las líneas sin vendedor y las que tenían el anterior; las
// asignadas a otro vendedor se respetan. Un vendedor nuevo vacío deja sin
// asignar las que tenían el anterior. Devuelve cuántas líneas cambia.
function PropagarVendedorCabeceraALineas(
  ALineas: TDataSet;
  const AVendedorAnterior, AVendedorNuevo: string): Integer;

implementation

uses
  System.SysUtils, System.StrUtils, inLibFacturas,
  inLibColumnasSkuIntf, inLibImpuestosComun, inLibLineaSku;

constructor TEditorLineasFactura.Create(
  AConexion: TUniConnection;
  ACabecera, ALineas: TDataSet;
  const AValidador: IArticulosValidador;
  const AResolver: IArticulosResolver;
  const ALookupAtributos: IArticulosAtributosLookup;
  const ARepositorioLecturas: IRepositorioLecturasFactura);
begin
  inherited Create;
  FConexion := AConexion;
  FCabecera := ACabecera;
  FLineas := ALineas;
  FValidador := AValidador;
  FResolver := AResolver;
  FLookupAtributos := ALookupAtributos;
  FRepositorioLecturas := ARepositorioLecturas;
  FCacheMostrarSku := TDictionary<string, Boolean>.Create;
end;

destructor TEditorLineasFactura.Destroy;
begin
  FLookupAtributos := nil;
  FResolver := nil;
  FRepositorioLecturas := nil;
  FValidador := nil;
  FCacheMostrarSku.Free;
  inherited;
end;

procedure TEditorLineasFactura.SincronizarSku(
  const ACodigoArticulo, ACodigoSku: string);
var
  Campos: TCamposColumnasSku;
  i: Integer;
begin
  Campos := Default(TCamposColumnasSku);
  Campos.CodigoArt := 'CODIGO_ART_FACLIN';
  Campos.CodigoUnidad := 'CODIGO_UNIDAD_FACLIN';
  Campos.NumAtributos := 'NUM_ATRIBUTOS_FACLIN';
  for i := 1 to 5 do
  begin
    Campos.AttrValor[i] := 'ATTR' + IntToStr(i) +
      '_VALOR_FACLIN';
    Campos.AttrNombre[i] := 'ATTR' + IntToStr(i) +
      '_NOMBRE_FACLIN';
  end;
  SincronizarCamposLineaSku(
    FLineas,
    Campos,
    ACodigoArticulo,
    ACodigoSku,
    FLookupAtributos);
end;

function TEditorLineasFactura.FechaFactura: TDateTime;
begin
  Result := Date;
  if Assigned(FCabecera) and FCabecera.Active and
     (FCabecera.FindField('FECHA_FAC') <> nil) and
     (not FCabecera.FieldByName('FECHA_FAC').IsNull) then
    Result := FCabecera.FieldByName('FECHA_FAC').AsDateTime;
end;

function TEditorLineasFactura.TarifaFactura: string;
begin
  Result := '';
  if Assigned(FCabecera) and FCabecera.Active and
     (FCabecera.FindField('TARIFA_ARTICULO_CLIENTE_FAC') <> nil) then
    Result := FCabecera.FieldByName(
      'TARIFA_ARTICULO_CLIENTE_FAC').AsString;
end;

function TEditorLineasFactura.PorcentajeIva(
  const ATipoIva: string): Double;
begin
  Result := 0;
  if Assigned(FCabecera) and FCabecera.Active then
    Result := PorcentajeIvaCabecera(
      FCabecera,
      'FAC',
      ATipoIva);
end;

procedure TEditorLineasFactura.AplicarPrecio(
  const ADatos: TArticuloDatos;
  const APrecio: TArticuloPrecio);
var
  Porcentaje: Double;
begin
  FLineas.FieldByName('PRECIO_SALIDA_FACLIN').AsFloat :=
    APrecio.PrecioSalida;
  FLineas.FieldByName('PORCENTAJE_DTO_FACLIN').AsFloat :=
    APrecio.PorcentajeDto;
  FLineas.FieldByName('PRECIO_DTO_FACLIN').AsFloat :=
    APrecio.PrecioDto;
  FLineas.FieldByName('ESIMP_INCL_TARIFA_FACLIN').AsString :=
    IfThen(APrecio.EsImpIncl, 'S', 'N');
  Porcentaje := PorcentajeIva(ADatos.TipoIVA);
  if APrecio.EsImpIncl then
  begin
    FLineas.FieldByName(
      'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsFloat :=
        APrecio.PrecioFinal;
    FLineas.FieldByName(
      'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsFloat :=
        PrecioSinIvaDesdeConIva(APrecio.PrecioFinal, Porcentaje);
  end
  else
  begin
    FLineas.FieldByName(
      'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsFloat :=
        APrecio.PrecioFinal;
    FLineas.FieldByName(
      'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsFloat :=
        PrecioConIvaDesdeSinIva(APrecio.PrecioFinal, Porcentaje);
  end;
end;

procedure TEditorLineasFactura.AplicarDatosArticulo(
  const ADatos: TArticuloDatos;
  const APrecio: TArticuloPrecio;
  ARequiereSku: Boolean);
begin
  FCacheMostrarSku.AddOrSetValue(
    ADatos.CodigoArticulo,
    ADatos.EsVariacion or ADatos.RequiereSku);
  SincronizarSku(ADatos.CodigoArticulo, ADatos.CodigoSku);
  if FLineas.FindField('DESCRIPCION_VARIACION_FACLIN') <> nil then
    FLineas.FieldByName('DESCRIPCION_VARIACION_FACLIN').AsString :=
      ADatos.DescripcionSku;
  FLineas.FieldByName('DESCRIPCION_ARTICULO_FACLIN').AsString :=
    ADatos.DescripcionArticulo;
  if FLineas.FindField('TIPO_ARTICULO_FACLIN') <> nil then
    FLineas.FieldByName('TIPO_ARTICULO_FACLIN').AsString :=
      ADatos.TipoArticulo;
  FLineas.FieldByName('TIPO_CANTIDAD_ARTICULO_FACLIN').AsString :=
    ADatos.TipoCantidad;
  FLineas.FieldByName('TIPO_IVA_ARTICULO_FACLIN').AsString :=
    ADatos.TipoIVA;
  FLineas.FieldByName('CODIGO_FAM_FACLIN').AsString :=
    ADatos.CodigoFamilia;
  FLineas.FieldByName('NOMBRE_FAM_FACLIN').AsString :=
    ADatos.DescripcionFamilia;
  FLineas.FieldByName('CODIGO_TAR_FACLIN').AsString :=
    TarifaFactura;
  if ADatos.UltimoCoste.Encontrado then
  begin
    FLineas.FieldByName('ESPROVEEDORPRINCIPAL_FACLIN').AsString :=
      IfThen(ADatos.UltimoCoste.EsProveedorPrincipal, 'S', 'N');
    FLineas.FieldByName('CODIGO_PRV_FACLIN').AsString :=
      ADatos.UltimoCoste.CodigoProveedor;
    FLineas.FieldByName(
      'RAZON_SOCIAL_PROVEEDOR_FACLIN').AsString :=
        ADatos.UltimoCoste.RazonSocialProveedor;
    FLineas.FieldByName('PRECIO_ULT_COMPRA_FACLIN').AsFloat :=
      ADatos.UltimoCoste.PrecioUltCompra;
  end;
  if ARequiereSku then
  begin
    FLineas.FieldByName('PRECIO_SALIDA_FACLIN').AsFloat := 0;
    FLineas.FieldByName(
      'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsFloat := 0;
    FLineas.FieldByName(
      'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsFloat := 0;
    FLineas.FieldByName('PORCENTAJE_DTO_FACLIN').AsFloat :=
      APrecio.PorcentajeDto;
    FLineas.FieldByName('PRECIO_DTO_FACLIN').AsFloat :=
      APrecio.PrecioDto;
    FLineas.FieldByName('ESIMP_INCL_TARIFA_FACLIN').AsString :=
      IfThen(APrecio.EsImpIncl, 'S', 'N');
  end
  else
    AplicarPrecio(ADatos, APrecio);
end;

function TEditorLineasFactura.AplicarEntradaComun(
  const AEntrada: string;
  APreservarSku: Boolean): TResultadoEdicionLineaFactura;
var
  Datos: TArticuloDatos;
  DatosSku: TArticuloDatos;
  Precio: TArticuloPrecio;
  Resolucion: TArtResolucionEntrada;
  SkuAnterior: string;
begin
  Result := Default(TResultadoEdicionLineaFactura);
  if (not FAplicando) and (Trim(AEntrada) <> '') and
     Assigned(FLineas) and FLineas.Active then
  begin
    if not (FLineas.State in dsEditModes) then
    begin
      if FLineas.CanModify then
        FLineas.Edit;
    end;
    if FLineas.State in dsEditModes then
    begin
      FAplicando := True;
      try
        SkuAnterior := '';
        if APreservarSku and
           (FLineas.FindField('CODIGO_UNIDAD_FACLIN') <> nil) then
          SkuAnterior := Trim(
            FLineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString);
        Resolucion := FValidador.Resolver(Trim(AEntrada));
        if Resolucion.Encontrado then
        begin
          Datos := FResolver.ResolverDatos(
            Resolucion.CodigoArticulo,
            Resolucion.CodigoSku,
            TarifaFactura,
            FechaFactura);
          if Datos.Encontrado and Datos.RequiereSku and
             (Resolucion.CodigoSku = '') and (SkuAnterior <> '') then
          begin
            DatosSku := FResolver.ResolverDatos(
              Resolucion.CodigoArticulo,
              SkuAnterior,
              TarifaFactura,
              FechaFactura);
            if DatosSku.Encontrado and (DatosSku.CodigoSku <> '') then
              Datos := DatosSku;
          end;
          if Datos.Encontrado then
          begin
            Result.RequiereSku :=
              Datos.RequiereSku and (Datos.CodigoSku = '');
            if Result.RequiereSku then
              Precio := FResolver.ResolverPrecio(
                Resolucion.CodigoArticulo,
                '',
                TarifaFactura,
                FechaFactura)
            else
              Precio := Datos.PrecioPedido;
            AplicarDatosArticulo(Datos, Precio, Result.RequiereSku);
            Result.Aplicado := True;
            Result.RecalcularDesdeEditor := not Result.RequiereSku;
            Result.CodigoArticulo := Datos.CodigoArticulo;
            Result.CodigoSku := Datos.CodigoSku;
          end;
        end;
      finally
        FAplicando := False;
      end;
    end;
  end;
end;

function TEditorLineasFactura.AplicarDesdeEditor(
  const AEntrada: string): TResultadoEdicionLineaFactura;
begin
  Result := AplicarEntradaComun(AEntrada, True);
end;

function TEditorLineasFactura.AplicarEntrada(
  const AEntrada: string): TResultadoEdicionLineaFactura;
begin
  Result := AplicarEntradaComun(AEntrada, False);
  if Result.Aplicado and Result.RecalcularDesdeEditor then
    ActualizarLineaFactura(
      FConexion,
      FRepositorioLecturas,
      FLineas,
      FCabecera,
      'PRECIO_SALIDA_FACLIN',
      FLineas.FieldByName('PRECIO_SALIDA_FACLIN').Value);
end;

procedure TEditorLineasFactura.AplicarLineaNoCatalogo(
  const ACodigoArticulo: string);
var
  Codigo: string;
begin
  Codigo := Trim(ACodigoArticulo);
  if (not FAplicando) and (Codigo <> '') and Assigned(FLineas) and
     FLineas.Active then
  begin
    if not (FLineas.State in dsEditModes) then
    begin
      if FLineas.CanModify then
        FLineas.Edit;
    end;
    if FLineas.State in dsEditModes then
    begin
      FAplicando := True;
      try
        SincronizarSku(Codigo, '');
        if FLineas.FindField('DESCRIPCION_VARIACION_FACLIN') <> nil then
          FLineas.FieldByName(
            'DESCRIPCION_VARIACION_FACLIN').AsString := '';
        if Trim(FLineas.FieldByName(
             'DESCRIPCION_ARTICULO_FACLIN').AsString) = '' then
          FLineas.FieldByName(
            'DESCRIPCION_ARTICULO_FACLIN').AsString := Codigo;
        if Trim(FLineas.FieldByName(
             'TIPO_IVA_ARTICULO_FACLIN').AsString) = '' then
          FLineas.FieldByName('TIPO_IVA_ARTICULO_FACLIN').AsString :=
            'N';
        FLineas.FieldByName('CODIGO_TAR_FACLIN').AsString :=
          TarifaFactura;
        FLineas.FieldByName('ESIMP_INCL_TARIFA_FACLIN').AsString :=
          FCabecera.FieldByName(
            'ESIMP_INCL_TARIFA_CLIENTE_FAC').AsString;
        FLineas.FieldByName('PORCENTAJE_DTO_FACLIN').AsFloat := 0;
        FLineas.FieldByName('PRECIO_DTO_FACLIN').AsFloat := 0;
        FLineas.FieldByName('PRECIO_SALIDA_FACLIN').AsFloat := 0;
        FLineas.FieldByName(
          'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsFloat := 0;
        FLineas.FieldByName(
          'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsFloat := 0;
        if FLineas.FieldByName('CANTIDAD_FACLIN').AsFloat = 0 then
          FLineas.FieldByName('CANTIDAD_FACLIN').AsFloat := 1;
        ActualizarLineaFactura(
          FConexion,
          FRepositorioLecturas,
          FLineas,
          FCabecera,
          'PRECIO_SALIDA_FACLIN',
          FLineas.FieldByName('PRECIO_SALIDA_FACLIN').Value);
      finally
        FAplicando := False;
      end;
    end;
  end;
end;

function TEditorLineasFactura.DebeMostrarSku(
  const ACodigoArticulo: string): Boolean;
begin
  Result := True;
  if (ACodigoArticulo <> '') and
     (not FCacheMostrarSku.TryGetValue(ACodigoArticulo, Result)) then
  begin
    try
      Result := ArticuloFacturaDebeMostrarSku(
        FRepositorioLecturas,
        ACodigoArticulo);
      FCacheMostrarSku.AddOrSetValue(ACodigoArticulo, Result);
    except
      Result := True;
    end;
  end;
end;

function TEditorLineasFactura.PrecioSku(
  const ACodigoArticulo, ACodigoSku: string): Double;
var
  Datos: TArticuloDatos;
  Precio: TArticuloPrecio;
begin
  Result := 0;
  if Assigned(FCabecera) and FCabecera.Active then
  begin
    Datos := FResolver.ResolverDatos(
      ACodigoArticulo,
      ACodigoSku,
      TarifaFactura,
      FechaFactura);
    if Datos.Encontrado then
    begin
      Precio := Datos.PrecioPedido;
      if Precio.EsImpIncl then
        Result := Precio.PrecioFinal
      else
        Result := PrecioConIvaDesdeSinIva(
          Precio.PrecioFinal,
          PorcentajeIva(Datos.TipoIVA));
    end;
  end;
end;

procedure TEditorLineasFactura.VaciarCache;
begin
  FCacheMostrarSku.Clear;
end;

function PropagarVendedorCabeceraALineas(
  ALineas: TDataSet;
  const AVendedorAnterior, AVendedorNuevo: string): Integer;
var
  oCampo: TField;
  oMarcador: TBookmark;
  sAnterior: string;
  sLinea: string;
  sNuevo: string;
begin
  Result := 0;
  oCampo := nil;
  if Assigned(ALineas) and ALineas.Active then
    oCampo := ALineas.FindField('CODIGO_VENDEDOR_FACLIN');
  if Assigned(oCampo) and (ALineas.State = dsBrowse) and
     (not ALineas.IsEmpty) then
  begin
    sAnterior := Trim(AVendedorAnterior);
    sNuevo := Trim(AVendedorNuevo);
    oMarcador := ALineas.GetBookmark;
    ALineas.DisableControls;
    try
      ALineas.First;
      while not ALineas.Eof do
      begin
        sLinea := Trim(oCampo.AsString);
        if (not SameText(sLinea, sNuevo)) and
           ((sLinea = '') or SameText(sLinea, sAnterior)) then
        begin
          ALineas.Edit;
          if sNuevo = '' then
            oCampo.Clear
          else
            oCampo.AsString := sNuevo;
          ALineas.Post;
          Inc(Result);
        end;
        ALineas.Next;
      end;
      if ALineas.BookmarkValid(oMarcador) then
        ALineas.GotoBookmark(oMarcador);
    finally
      try
        ALineas.EnableControls;
      finally
        ALineas.FreeBookmark(oMarcador);
      end;
    end;
  end;
end;

end.
