{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPrestaCatalogoAlta                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       13/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Alta inactiva e idempotente del catálogo mediante la API PrestaShop.      }
{******************************************************************************}
unit inLibPrestaCatalogoAlta;

interface

uses
  inLibPrestaCatalogoIntf, inLibPrestaCatalogoAltaIntf;

type
  TClienteCatalogoAltaPresta = class(TInterfacedObject,
    IClienteCatalogoAltaPresta)
  private
    FTransporte: ITransporteAltaPresta;
    FIdiomasTienda: TArray<Integer>;
    FIdiomasLeidos: Boolean;
    function SolicitarXml(const ARecurso: string): string;
    function IdiomasEnvio(AIdIdioma: Integer): TArray<Integer>;
    function BuscarId(const ARecurso, AColeccion, AElemento,
      AIdentificacion: string): Integer;
    function CrearRecurso(const ARecurso, AElemento,
      AXml: string): Integer;
    function CrearResultado(AId: Integer;
      ACreado: Boolean): TResultadoAltaPresta;
  public
    constructor Create(const AUrlApi, AClaveApi: string); overload;
    constructor Create(
      const ATransporte: ITransporteAltaPresta); overload;
    function AsegurarCategoria(
      const ADatos: TAltaCategoriaPresta): TResultadoAltaPresta;
    function AsegurarGrupoAtributos(
      const ADatos: TAltaGrupoAtributosPresta): TResultadoAltaPresta;
    function AsegurarValorAtributo(
      const ADatos: TAltaValorAtributoPresta): TResultadoAltaPresta;
    function AsegurarProductoInactivo(
      const ADatos: TAltaProductoPresta): TResultadoAltaPresta;
    function AsegurarCombinacion(
      const ADatos: TAltaCombinacionPresta): TResultadoAltaPresta;
    function AsegurarImagenProductoSiVacia(
      AIdProducto, AIdTienda: Integer;
      const ARutaImagen: string): Boolean;
  end;

function CrearClienteCatalogoAltaPresta(const AUrlApi,
  AClaveApi: string): IClienteCatalogoAltaPresta;

implementation

uses
  System.SysUtils, System.Math, System.NetEncoding,
  System.Variants, System.Generics.Collections,
  Xml.XMLIntf, Xml.XMLDoc,
  inLibPrestaCatalogo;

const
  CNamespaceXlink = 'http://www.w3.org/1999/xlink';
  CCategorias = 'categories';
  CCategoria = 'category';
  CGruposAtributos = 'product_options';
  CGrupoAtributos = 'product_option';
  CValoresAtributos = 'product_option_values';
  CValorAtributo = 'product_option_value';
  CProductos = 'products';
  CProducto = 'product';
  CCombinaciones = 'combinations';
  CCombinacion = 'combination';

resourcestring
  STransporteAltaPrestaNoAsignado =
    'El transporte de alta de PrestaShop no está asignado.';
  SDatoAltaPrestaVacio =
    '%s no puede estar vacío.';
  SDatoAltaPrestaLargo =
    '%s supera los %d caracteres permitidos por PrestaShop.';
  SIdAltaPrestaPositivo =
    '%s debe ser mayor que cero.';
  SIdAltaPrestaNoNegativo =
    '%s no puede ser negativo.';
  SPrecioAltaPrestaInvalido =
    '%s no puede ser infinito ni NaN.';
  SPrecioProductoAltaPrestaInvalido =
    'El precio de producto no puede ser negativo.';
  STipoGrupoAltaPrestaInvalido =
    'El tipo de grupo debe ser select, radio o color.';
  SValorAtributoAltaPrestaAusente =
    'La combinación debe tener al menos un valor de atributo.';
  SImagenAltaPrestaAusente =
    'No existe la imagen que se quiere publicar: %s.';
  SImagenAltaPrestaTipoInvalido =
    'La imagen debe tener formato JPG, JPEG, PNG o GIF.';
  SXmlAltaPrestaVacio =
    'el documento XML está vacío';
  SXmlAltaPrestaNoValido =
    'el documento XML no se pudo interpretar';
  SNodoAltaPrestaAusente =
    'falta el nodo %s';
  SIdAltaPrestaInvalido =
    'el identificador devuelto no es válido';
  SValidacionAltaPresta =
    'PrestaShop rechazó el alta (HTTP 400 al ejecutar POST sobre %s): ' +
    '%s. Revise los datos del artículo; la cola no lo reintentará.';
  SValidacionAltaPrestaSinDetalle =
    'sin detalle del error';

function EscaparXml(const AValor: string): string;
begin
  Result := StringReplace(AValor, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
  Result := StringReplace(Result, '''', '&apos;', [rfReplaceAll]);
end;

function CodificarFiltro(const AValor: string): string;
begin
  Result := TNetEncoding.URL.Encode(AValor);
end;

function FormatearDecimal(AValor: Double): string;
begin
  Result := FormatFloat('0.000000', AValor,
    TFormatSettings.Invariant);
end;

function BooleanoXml(AValor: Boolean): string;
begin
  if AValor then
    Result := '1'
  else
    Result := '0';
end;

function CrearDocumento(const AElemento,
  AContenido: string): string;
begin
  Result := '<?xml version="1.0" encoding="UTF-8"?>' + sLineBreak +
    '<prestashop xmlns:xlink="' + CNamespaceXlink + '">' +
    sLineBreak + '  <' + AElemento + '>' + sLineBreak +
    AContenido + '  </' + AElemento + '>' + sLineBreak +
    '</prestashop>';
end;

function CampoXml(const ANombre, AValor: string): string;
begin
  Result := '    <' + ANombre + '>' + EscaparXml(AValor) + '</' +
    ANombre + '>' + sLineBreak;
end;

// El mismo texto va en todos los idiomas de la tienda: PrestaShop exige
// los campos obligatorios en su idioma por defecto (FZ-ISSUE-761).
function CampoIdiomaXml(const ANombre, AValor: string;
  const AIdiomas: TArray<Integer>): string;
var
  iIndice: Integer;
begin
  Result := '    <' + ANombre + '>' + sLineBreak;
  for iIndice := 0 to High(AIdiomas) do
  begin
    Result := Result + '      <language id="' +
      IntToStr(AIdiomas[iIndice]) + '">' + EscaparXml(AValor) +
      '</language>' + sLineBreak;
  end;
  Result := Result + '    </' + ANombre + '>' + sLineBreak;
end;

function CrearXmlCategoria(const ADatos: TAltaCategoriaPresta;
  const AIdiomas: TArray<Integer>): string;
var
  sContenido: string;
begin
  sContenido := CampoXml('id_parent', IntToStr(ADatos.IdPadre));
  sContenido := sContenido + CampoXml('active',
    BooleanoXml(ADatos.Activa));
  sContenido := sContenido + CampoXml('id_shop_default',
    IntToStr(ADatos.IdTienda));
  sContenido := sContenido + CampoXml('is_root_category', '0');
  sContenido := sContenido + CampoIdiomaXml('name', ADatos.Nombre,
    AIdiomas);
  sContenido := sContenido + CampoIdiomaXml('link_rewrite',
    ADatos.Enlace, AIdiomas);
  Result := CrearDocumento(CCategoria, sContenido);
end;

function CrearXmlGrupoAtributos(
  const ADatos: TAltaGrupoAtributosPresta;
  const AIdiomas: TArray<Integer>): string;
var
  sContenido: string;
begin
  sContenido := CampoXml('is_color_group',
    BooleanoXml(ADatos.EsColor));
  sContenido := sContenido + CampoXml('group_type',
    LowerCase(Trim(ADatos.TipoGrupo)));
  sContenido := sContenido + CampoIdiomaXml('name', ADatos.Nombre,
    AIdiomas);
  sContenido := sContenido + CampoIdiomaXml('public_name',
    ADatos.NombrePublico, AIdiomas);
  Result := CrearDocumento(CGrupoAtributos, sContenido);
end;

function CrearXmlValorAtributo(
  const ADatos: TAltaValorAtributoPresta;
  const AIdiomas: TArray<Integer>): string;
var
  sContenido: string;
begin
  sContenido := CampoXml('id_attribute_group',
    IntToStr(ADatos.IdGrupo));
  sContenido := sContenido + CampoXml('color', Trim(ADatos.Color));
  sContenido := sContenido + CampoIdiomaXml('name', ADatos.Nombre,
    AIdiomas);
  Result := CrearDocumento(CValorAtributo, sContenido);
end;

function NormalizarCategorias(
  const ADatos: TAltaProductoPresta): TArray<Integer>;
var
  iIndice: Integer;
  oIds: TList<Integer>;
begin
  oIds := TList<Integer>.Create;
  try
    oIds.Add(ADatos.IdCategoriaDefecto);
    for iIndice := 0 to High(ADatos.IdsCategorias) do
    begin
      if (ADatos.IdsCategorias[iIndice] > 0) and
         (not oIds.Contains(ADatos.IdsCategorias[iIndice])) then
        oIds.Add(ADatos.IdsCategorias[iIndice]);
    end;
    Result := oIds.ToArray;
  finally
    oIds.Free;
  end;
end;

function AsociacionesCategoriasXml(
  const AIds: TArray<Integer>): string;
var
  iIndice: Integer;
begin
  Result := '    <associations>' + sLineBreak +
    '      <categories>' + sLineBreak;
  for iIndice := 0 to High(AIds) do
  begin
    Result := Result + '        <category>' + sLineBreak +
      '          <id>' + IntToStr(AIds[iIndice]) + '</id>' +
      sLineBreak + '        </category>' + sLineBreak;
  end;
  Result := Result + '      </categories>' + sLineBreak +
    '    </associations>' + sLineBreak;
end;

function CrearXmlProductoInactivo(const ADatos: TAltaProductoPresta;
  const AIdiomas: TArray<Integer>): string;
var
  aCategorias: TArray<Integer>;
  sContenido: string;
begin
  aCategorias := NormalizarCategorias(ADatos);
  sContenido := CampoXml('id_category_default',
    IntToStr(ADatos.IdCategoriaDefecto));
  sContenido := sContenido + CampoXml('id_tax_rules_group',
    IntToStr(ADatos.IdGrupoReglasIva));
  sContenido := sContenido + CampoXml('type', 'standard');
  sContenido := sContenido + CampoXml('id_shop_default',
    IntToStr(ADatos.IdTienda));
  sContenido := sContenido + CampoXml('reference', ADatos.Referencia);
  sContenido := sContenido + CampoXml('state', '1');
  sContenido := sContenido + CampoXml('price',
    FormatearDecimal(ADatos.Precio));
  sContenido := sContenido + CampoXml('minimal_quantity', '1');
  sContenido := sContenido + CampoXml('active', '0');
  sContenido := sContenido + CampoXml('available_for_order', '1');
  sContenido := sContenido + CampoXml('show_price', '1');
  sContenido := sContenido + CampoXml('indexed', '0');
  sContenido := sContenido + CampoXml('visibility', 'both');
  sContenido := sContenido + CampoIdiomaXml('name', ADatos.Nombre,
    AIdiomas);
  sContenido := sContenido + CampoIdiomaXml('link_rewrite',
    ADatos.Enlace, AIdiomas);
  sContenido := sContenido + CampoIdiomaXml('description_short',
    ADatos.DescripcionCorta, AIdiomas);
  sContenido := sContenido + CampoIdiomaXml('description',
    ADatos.Descripcion, AIdiomas);
  sContenido := sContenido + AsociacionesCategoriasXml(aCategorias);
  Result := CrearDocumento(CProducto, sContenido);
end;

function AsociacionesValoresXml(
  const AIds: TArray<Integer>): string;
var
  iIndice: Integer;
begin
  Result := '    <associations>' + sLineBreak +
    '      <product_option_values>' + sLineBreak;
  for iIndice := 0 to High(AIds) do
  begin
    Result := Result + '        <product_option_value>' + sLineBreak +
      '          <id>' + IntToStr(AIds[iIndice]) + '</id>' +
      sLineBreak + '        </product_option_value>' + sLineBreak;
  end;
  Result := Result + '      </product_option_values>' + sLineBreak +
    '    </associations>' + sLineBreak;
end;

function CrearXmlCombinacion(
  const ADatos: TAltaCombinacionPresta): string;
var
  sContenido: string;
begin
  sContenido := CampoXml('id_product', IntToStr(ADatos.IdProducto));
  sContenido := sContenido + CampoXml('reference', ADatos.Referencia);
  sContenido := sContenido + CampoXml('price',
    FormatearDecimal(ADatos.ImpactoPrecio));
  sContenido := sContenido + CampoXml('minimal_quantity',
    IntToStr(ADatos.CantidadMinima));
  sContenido := sContenido + CampoXml('default_on',
    BooleanoXml(ADatos.Predeterminada));
  sContenido := sContenido + AsociacionesValoresXml(ADatos.IdsValores);
  Result := CrearDocumento(CCombinacion, sContenido);
end;

procedure ComprobarPositivo(AValor: Integer; const ANombre: string);
begin
  if AValor <= 0 then
    raise EConfiguracionPrestaInvalida.CreateFmt(
      SIdAltaPrestaPositivo, [ANombre]);
end;

procedure ComprobarNoNegativo(AValor: Integer; const ANombre: string);
begin
  if AValor < 0 then
    raise EConfiguracionPrestaInvalida.CreateFmt(
      SIdAltaPrestaNoNegativo, [ANombre]);
end;

procedure ComprobarTexto(const AValor, ANombre: string;
  ALongitudMaxima: Integer);
begin
  if Trim(AValor) = '' then
    raise EConfiguracionPrestaInvalida.CreateFmt(
      SDatoAltaPrestaVacio, [ANombre]);
  if Length(AValor) > ALongitudMaxima then
    raise EConfiguracionPrestaInvalida.CreateFmt(
      SDatoAltaPrestaLargo, [ANombre, ALongitudMaxima]);
end;

procedure ComprobarDecimal(AValor: Double; const ANombre: string);
begin
  if IsNan(AValor) or IsInfinite(AValor) then
    raise EConfiguracionPrestaInvalida.CreateFmt(
      SPrecioAltaPrestaInvalido, [ANombre]);
end;

procedure ValidarCategoria(const ADatos: TAltaCategoriaPresta);
begin
  ComprobarPositivo(ADatos.IdPadre, 'IdPadre');
  ComprobarPositivo(ADatos.IdTienda, 'IdTienda');
  ComprobarPositivo(ADatos.IdIdioma, 'IdIdioma');
  ComprobarTexto(ADatos.Nombre, 'Nombre', 128);
  ComprobarTexto(ADatos.Enlace, 'Enlace', 128);
end;

procedure ValidarGrupoAtributos(
  const ADatos: TAltaGrupoAtributosPresta);
var
  sTipo: string;
begin
  ComprobarPositivo(ADatos.IdTienda, 'IdTienda');
  ComprobarPositivo(ADatos.IdIdioma, 'IdIdioma');
  ComprobarTexto(ADatos.Nombre, 'Nombre', 128);
  ComprobarTexto(ADatos.NombrePublico, 'NombrePublico', 64);
  sTipo := LowerCase(Trim(ADatos.TipoGrupo));
  if (sTipo <> 'select') and (sTipo <> 'radio') and
     (sTipo <> 'color') then
    raise EConfiguracionPrestaInvalida.Create(
      STipoGrupoAltaPrestaInvalido);
end;

procedure ValidarValorAtributo(
  const ADatos: TAltaValorAtributoPresta);
begin
  ComprobarPositivo(ADatos.IdGrupo, 'IdGrupo');
  ComprobarPositivo(ADatos.IdTienda, 'IdTienda');
  ComprobarPositivo(ADatos.IdIdioma, 'IdIdioma');
  ComprobarTexto(ADatos.Nombre, 'Nombre', 128);
end;

procedure ValidarProducto(const ADatos: TAltaProductoPresta);
begin
  ComprobarPositivo(ADatos.IdCategoriaDefecto,
    'IdCategoriaDefecto');
  ComprobarNoNegativo(ADatos.IdGrupoReglasIva,
    'IdGrupoReglasIva');
  ComprobarPositivo(ADatos.IdTienda, 'IdTienda');
  ComprobarPositivo(ADatos.IdIdioma, 'IdIdioma');
  ComprobarTexto(ADatos.Referencia, 'Referencia', 64);
  ComprobarTexto(ADatos.Nombre, 'Nombre', 128);
  ComprobarTexto(ADatos.Enlace, 'Enlace', 128);
  ComprobarDecimal(ADatos.Precio, 'Precio');
  if ADatos.Precio < 0 then
    raise EConfiguracionPrestaInvalida.Create(
      SPrecioProductoAltaPrestaInvalido);
end;

procedure ValidarCombinacion(const ADatos: TAltaCombinacionPresta);
var
  iIndice: Integer;
begin
  ComprobarPositivo(ADatos.IdProducto, 'IdProducto');
  ComprobarPositivo(ADatos.IdTienda, 'IdTienda');
  ComprobarTexto(ADatos.Referencia, 'Referencia', 64);
  ComprobarDecimal(ADatos.ImpactoPrecio, 'ImpactoPrecio');
  ComprobarPositivo(ADatos.CantidadMinima, 'CantidadMinima');
  if Length(ADatos.IdsValores) = 0 then
    raise EConfiguracionPrestaInvalida.Create(
      SValorAtributoAltaPrestaAusente);
  for iIndice := 0 to High(ADatos.IdsValores) do
    ComprobarPositivo(ADatos.IdsValores[iIndice], 'IdValorAtributo');
end;

function CargarDocumento(const AXml,
  ARecurso: string): IXMLDocument;
begin
  if Trim(AXml) = '' then
    raise ERespuestaPrestaInvalida.Create(
      ARecurso, SXmlAltaPrestaVacio);
  Result := TXMLDocument.Create(nil);
  try
    Result.LoadFromXML(AXml);
    Result.Active := True;
  except
    on E: Exception do
      raise ERespuestaPrestaInvalida.Create(
        ARecurso, SXmlAltaPrestaNoValido);
  end;
end;

function BuscarHijo(const ANodo: IXMLNode;
  const ANombre: string): IXMLNode;
begin
  Result := nil;
  if Assigned(ANodo) then
    Result := ANodo.ChildNodes.FindNode(ANombre);
end;

function HijoObligatorio(const ANodo: IXMLNode;
  const ANombre, ARecurso: string): IXMLNode;
begin
  Result := BuscarHijo(ANodo, ANombre);
  if not Assigned(Result) then
    raise ERespuestaPrestaInvalida.Create(ARecurso,
      Format(SNodoAltaPrestaAusente, [ANombre]));
end;

function LeerIdNodo(const ANodo: IXMLNode;
  const ARecurso: string): Integer;
var
  oId: IXMLNode;
  sId: string;
begin
  oId := BuscarHijo(ANodo, 'id');
  if Assigned(oId) then
    sId := Trim(oId.Text)
  else if ANodo.HasAttribute('id') then
    sId := Trim(VarToStr(ANodo.Attributes['id']))
  else
    raise ERespuestaPrestaInvalida.Create(
      ARecurso, SIdAltaPrestaInvalido);
  if not TryStrToInt(sId, Result) or (Result <= 0) then
    raise ERespuestaPrestaInvalida.Create(
      ARecurso, SIdAltaPrestaInvalido);
end;

function ResolverIdBusqueda(const AXml, AColeccion, AElemento,
  AIdentificacion, ARecurso: string): Integer;
var
  iCantidad: Integer;
  iIndice: Integer;
  oColeccion: IXMLNode;
  oDocumento: IXMLDocument;
  oNodo: IXMLNode;
begin
  oDocumento := CargarDocumento(AXml, ARecurso);
  oColeccion := HijoObligatorio(oDocumento.DocumentElement,
    AColeccion, ARecurso);
  Result := 0;
  iCantidad := 0;
  for iIndice := 0 to oColeccion.ChildNodes.Count - 1 do
  begin
    oNodo := oColeccion.ChildNodes.Get(iIndice);
    if SameText(oNodo.NodeName, AElemento) then
    begin
      Inc(iCantidad);
      if iCantidad = 1 then
        Result := LeerIdNodo(oNodo, ARecurso);
    end;
  end;
  if iCantidad > 1 then
    raise ERecursoPrestaAmbiguo.Create(
      AElemento, AIdentificacion, iCantidad);
end;

function ResolverIdCreado(const AXml, AElemento,
  ARecurso: string): Integer;
var
  oDocumento: IXMLDocument;
  oNodo: IXMLNode;
begin
  oDocumento := CargarDocumento(AXml, ARecurso);
  oNodo := HijoObligatorio(oDocumento.DocumentElement,
    AElemento, ARecurso);
  Result := LeerIdNodo(oNodo, ARecurso);
end;

function ContarImagenesProducto(const AXml,
  ARecurso: string): Integer;
var
  iIndice: Integer;
  oAsociaciones: IXMLNode;
  oDocumento: IXMLDocument;
  oImagenes: IXMLNode;
  oProducto: IXMLNode;
begin
  oDocumento := CargarDocumento(AXml, ARecurso);
  oProducto := HijoObligatorio(oDocumento.DocumentElement,
    CProducto, ARecurso);
  oAsociaciones := HijoObligatorio(oProducto,
    'associations', ARecurso);
  oImagenes := HijoObligatorio(oAsociaciones, 'images', ARecurso);
  Result := 0;
  for iIndice := 0 to oImagenes.ChildNodes.Count - 1 do
  begin
    if SameText(oImagenes.ChildNodes.Get(iIndice).NodeName,
       'image') then
      Inc(Result);
  end;
end;

// Los campos multilingües de una lectura traen un <language id> por cada
// idioma instalado; así se conocen sin permiso sobre languages.
function LeerIdiomasCategoria(const AXml,
  ARecurso: string): TArray<Integer>;
var
  iId: Integer;
  iIndice: Integer;
  oCategoria: IXMLNode;
  oColeccion: IXMLNode;
  oDocumento: IXMLDocument;
  oIds: TList<Integer>;
  oNodo: IXMLNode;
  oNombre: IXMLNode;
begin
  oDocumento := CargarDocumento(AXml, ARecurso);
  oColeccion := HijoObligatorio(oDocumento.DocumentElement,
    CCategorias, ARecurso);
  oCategoria := BuscarHijo(oColeccion, CCategoria);
  oNombre := BuscarHijo(oCategoria, 'name');
  oIds := TList<Integer>.Create;
  try
    if Assigned(oNombre) then
    begin
      for iIndice := 0 to oNombre.ChildNodes.Count - 1 do
      begin
        oNodo := oNombre.ChildNodes.Get(iIndice);
        if SameText(oNodo.NodeName, 'language') and
           oNodo.HasAttribute('id') and
           TryStrToInt(VarToStr(oNodo.Attributes['id']), iId) and
           (iId > 0) and (not oIds.Contains(iId)) then
          oIds.Add(iId);
      end;
    end;
    Result := oIds.ToArray;
  finally
    oIds.Free;
  end;
end;

function LeerMensajeErrorPresta(const AXml,
  ARecurso: string): string;
var
  iIndice: Integer;
  oDocumento: IXMLDocument;
  oErrores: IXMLNode;
  oMensaje: IXMLNode;
begin
  Result := '';
  oDocumento := CargarDocumento(AXml, ARecurso);
  oErrores := BuscarHijo(oDocumento.DocumentElement, 'errors');
  if Assigned(oErrores) then
  begin
    for iIndice := 0 to oErrores.ChildNodes.Count - 1 do
    begin
      oMensaje := BuscarHijo(oErrores.ChildNodes.Get(iIndice),
        'message');
      if Assigned(oMensaje) and (Trim(oMensaje.Text) <> '') then
      begin
        if Result <> '' then
          Result := Result + '; ';
        Result := Result + Trim(oMensaje.Text);
      end;
    end;
  end;
  if Result = '' then
    Result := SValidacionAltaPrestaSinDetalle;
end;

function CrearClienteCatalogoAltaPresta(const AUrlApi,
  AClaveApi: string): IClienteCatalogoAltaPresta;
begin
  Result := TClienteCatalogoAltaPresta.Create(AUrlApi, AClaveApi);
end;

{ TClienteCatalogoAltaPresta }

constructor TClienteCatalogoAltaPresta.Create(
  const AUrlApi, AClaveApi: string);
begin
  inherited Create;
  FTransporte := CrearTransportePresta(AUrlApi, AClaveApi);
end;

constructor TClienteCatalogoAltaPresta.Create(
  const ATransporte: ITransporteAltaPresta);
begin
  inherited Create;
  if ATransporte = nil then
    raise EConfiguracionPrestaInvalida.Create(
      STransporteAltaPrestaNoAsignado);
  FTransporte := ATransporte;
end;

function TClienteCatalogoAltaPresta.SolicitarXml(
  const ARecurso: string): string;
var
  rRespuesta: TRespuestaHttpPresta;
begin
  rRespuesta := FTransporte.EjecutarGet(ARecurso);
  ComprobarRespuestaHttpPresta(rRespuesta, 'GET', ARecurso);
  Result := rRespuesta.Contenido;
end;

function TClienteCatalogoAltaPresta.BuscarId(const ARecurso,
  AColeccion, AElemento, AIdentificacion: string): Integer;
begin
  Result := ResolverIdBusqueda(SolicitarXml(ARecurso),
    AColeccion, AElemento, AIdentificacion, ARecurso);
end;

function TClienteCatalogoAltaPresta.CrearRecurso(const ARecurso,
  AElemento, AXml: string): Integer;
var
  rRespuesta: TRespuestaHttpPresta;
begin
  rRespuesta := FTransporte.EjecutarPostXml(ARecurso, AXml);
  try
    ComprobarRespuestaHttpPresta(rRespuesta, 'POST', ARecurso);
  except
    { Un 400 de PrestaShop es un error de validación: repetir el mismo XML
      no lo arregla, así que pasa a configuración inválida (incidencia
      terminal) con el motivo que da la tienda. }
    on E: EErrorHttpPresta do
    begin
      if E.EstadoHttp = 400 then
        raise EConfiguracionPrestaInvalida.CreateFmt(
          SValidacionAltaPresta, [ARecurso,
          LeerMensajeErrorPresta(rRespuesta.Contenido, ARecurso)]);
      raise;
    end;
  end;
  Result := ResolverIdCreado(rRespuesta.Contenido,
    AElemento, ARecurso);
end;

// Idioma configurado primero y después el resto de idiomas de la tienda,
// leídos una sola vez por cliente. Si la clave no puede leer categorías
// (401/403/404), se envía solo el idioma configurado, como hasta ahora.
function TClienteCatalogoAltaPresta.IdiomasEnvio(
  AIdIdioma: Integer): TArray<Integer>;
var
  iIndice: Integer;
  oIds: TList<Integer>;
  sRecurso: string;
begin
  if not FIdiomasLeidos then
  begin
    sRecurso := CCategorias + '?display=[id,name]&limit=1';
    try
      FIdiomasTienda := LeerIdiomasCategoria(SolicitarXml(sRecurso),
        sRecurso);
    except
      on E: EErrorHttpPresta do
        FIdiomasTienda := nil;
    end;
    FIdiomasLeidos := True;
  end;
  oIds := TList<Integer>.Create;
  try
    oIds.Add(AIdIdioma);
    for iIndice := 0 to High(FIdiomasTienda) do
    begin
      if not oIds.Contains(FIdiomasTienda[iIndice]) then
        oIds.Add(FIdiomasTienda[iIndice]);
    end;
    Result := oIds.ToArray;
  finally
    oIds.Free;
  end;
end;

function TClienteCatalogoAltaPresta.CrearResultado(AId: Integer;
  ACreado: Boolean): TResultadoAltaPresta;
begin
  Result.Id := AId;
  Result.Creado := ACreado;
end;

function TClienteCatalogoAltaPresta.AsegurarCategoria(
  const ADatos: TAltaCategoriaPresta): TResultadoAltaPresta;
var
  iId: Integer;
  sRecurso: string;
begin
  ValidarCategoria(ADatos);
  sRecurso := CCategorias + '?filter[id_parent]=[' +
    IntToStr(ADatos.IdPadre) + ']&filter[link_rewrite]=[' +
    CodificarFiltro(Trim(ADatos.Enlace)) + ']&display=[id]' +
    '&id_shop=' + IntToStr(ADatos.IdTienda);
  iId := BuscarId(sRecurso, CCategorias, CCategoria,
    'parent=' + IntToStr(ADatos.IdPadre) + ', link_rewrite=' +
    ADatos.Enlace);
  if iId = 0 then
  begin
    sRecurso := CCategorias + '?id_shop=' +
      IntToStr(ADatos.IdTienda);
    iId := CrearRecurso(sRecurso, CCategoria,
      CrearXmlCategoria(ADatos, IdiomasEnvio(ADatos.IdIdioma)));
    Result := CrearResultado(iId, True);
  end
  else
    Result := CrearResultado(iId, False);
end;

function TClienteCatalogoAltaPresta.AsegurarGrupoAtributos(
  const ADatos: TAltaGrupoAtributosPresta): TResultadoAltaPresta;
var
  iId: Integer;
  sRecurso: string;
begin
  ValidarGrupoAtributos(ADatos);
  sRecurso := CGruposAtributos + '?filter[name]=[' +
    CodificarFiltro(Trim(ADatos.Nombre)) + ']&display=[id]' +
    '&id_shop=' + IntToStr(ADatos.IdTienda);
  iId := BuscarId(sRecurso, CGruposAtributos, CGrupoAtributos,
    'name=' + ADatos.Nombre);
  if iId = 0 then
  begin
    sRecurso := CGruposAtributos + '?id_shop=' +
      IntToStr(ADatos.IdTienda);
    iId := CrearRecurso(sRecurso, CGrupoAtributos,
      CrearXmlGrupoAtributos(ADatos, IdiomasEnvio(ADatos.IdIdioma)));
    Result := CrearResultado(iId, True);
  end
  else
    Result := CrearResultado(iId, False);
end;

function TClienteCatalogoAltaPresta.AsegurarValorAtributo(
  const ADatos: TAltaValorAtributoPresta): TResultadoAltaPresta;
var
  iId: Integer;
  sRecurso: string;
begin
  ValidarValorAtributo(ADatos);
  sRecurso := CValoresAtributos +
    '?filter[id_attribute_group]=[' + IntToStr(ADatos.IdGrupo) +
    ']&filter[name]=[' + CodificarFiltro(Trim(ADatos.Nombre)) +
    ']&display=[id]&id_shop=' + IntToStr(ADatos.IdTienda);
  iId := BuscarId(sRecurso, CValoresAtributos, CValorAtributo,
    'group=' + IntToStr(ADatos.IdGrupo) + ', name=' + ADatos.Nombre);
  if iId = 0 then
  begin
    sRecurso := CValoresAtributos + '?id_shop=' +
      IntToStr(ADatos.IdTienda);
    iId := CrearRecurso(sRecurso, CValorAtributo,
      CrearXmlValorAtributo(ADatos, IdiomasEnvio(ADatos.IdIdioma)));
    Result := CrearResultado(iId, True);
  end
  else
    Result := CrearResultado(iId, False);
end;

function TClienteCatalogoAltaPresta.AsegurarProductoInactivo(
  const ADatos: TAltaProductoPresta): TResultadoAltaPresta;
var
  iId: Integer;
  sRecurso: string;
begin
  ValidarProducto(ADatos);
  sRecurso := CProductos + '?filter[reference]=[' +
    CodificarFiltro(Trim(ADatos.Referencia)) + ']&display=[id]' +
    '&id_shop=' + IntToStr(ADatos.IdTienda);
  iId := BuscarId(sRecurso, CProductos, CProducto,
    'reference=' + ADatos.Referencia);
  if iId = 0 then
  begin
    sRecurso := CProductos + '?id_shop=' +
      IntToStr(ADatos.IdTienda);
    iId := CrearRecurso(sRecurso, CProducto,
      CrearXmlProductoInactivo(ADatos,
        IdiomasEnvio(ADatos.IdIdioma)));
    Result := CrearResultado(iId, True);
  end
  else
    Result := CrearResultado(iId, False);
end;

function TClienteCatalogoAltaPresta.AsegurarCombinacion(
  const ADatos: TAltaCombinacionPresta): TResultadoAltaPresta;
var
  iId: Integer;
  sRecurso: string;
begin
  ValidarCombinacion(ADatos);
  sRecurso := CCombinaciones + '?filter[id_product]=[' +
    IntToStr(ADatos.IdProducto) + ']&filter[reference]=[' +
    CodificarFiltro(Trim(ADatos.Referencia)) + ']&display=[id]' +
    '&id_shop=' + IntToStr(ADatos.IdTienda);
  iId := BuscarId(sRecurso, CCombinaciones, CCombinacion,
    'product=' + IntToStr(ADatos.IdProducto) + ', reference=' +
    ADatos.Referencia);
  if iId = 0 then
  begin
    sRecurso := CCombinaciones + '?id_shop=' +
      IntToStr(ADatos.IdTienda);
    iId := CrearRecurso(sRecurso, CCombinacion,
      CrearXmlCombinacion(ADatos));
    Result := CrearResultado(iId, True);
  end
  else
    Result := CrearResultado(iId, False);
end;

function TClienteCatalogoAltaPresta.AsegurarImagenProductoSiVacia(
  AIdProducto, AIdTienda: Integer;
  const ARutaImagen: string): Boolean;
var
  iCantidad: Integer;
  rRespuesta: TRespuestaHttpPresta;
  sExtension: string;
  sRecurso: string;
begin
  ComprobarPositivo(AIdProducto, 'AIdProducto');
  ComprobarPositivo(AIdTienda, 'AIdTienda');
  sRecurso := CProductos + '/' + IntToStr(AIdProducto) +
    '?display=full&id_shop=' + IntToStr(AIdTienda);
  iCantidad := ContarImagenesProducto(
    SolicitarXml(sRecurso), sRecurso);
  Result := iCantidad = 0;
  if Result then
  begin
    if not FileExists(ARutaImagen) then
      raise EConfiguracionPrestaInvalida.CreateFmt(
        SImagenAltaPrestaAusente, [ARutaImagen]);
    sExtension := LowerCase(ExtractFileExt(ARutaImagen));
    if (sExtension <> '.jpg') and (sExtension <> '.jpeg') and
       (sExtension <> '.png') and (sExtension <> '.gif') then
      raise EConfiguracionPrestaInvalida.Create(
        SImagenAltaPrestaTipoInvalido);
    sRecurso := 'images/products/' + IntToStr(AIdProducto) +
      '?id_shop=' + IntToStr(AIdTienda);
    rRespuesta := FTransporte.EjecutarPostImagen(
      sRecurso, ARutaImagen);
    ComprobarRespuestaHttpPresta(rRespuesta, 'POST', sRecurso);
  end;
end;

end.
