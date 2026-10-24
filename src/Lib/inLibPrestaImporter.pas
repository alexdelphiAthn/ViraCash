{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPrestaImporter                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Importador de pedidos desde la API REST de PrestaShop.                    }
{    Conexión autenticada, listado y carga de pedidos completos.               }
{******************************************************************************}
unit inLibPrestaImporter;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  XMLIntf, XMLDoc, REST.Client, REST.Types, system.Variants,
  REST.Authenticator.Basic,
  inLibPresta, inLibLogIntf;

type
  TPrestaPedidoResumen = record
    IdPedido: string;
    Referencia: string;
    Fecha: string;
    Cliente: string;
    Total: string;
    Estado: string;
  end;

  TPrestaPedidoResumenList = TList<TPrestaPedidoResumen>;

  TPrestaConn = class
  private
    FBaseURL: string;
    FApiKey:  string;
    FClient:  TRESTClient;
    FRequest: TRESTRequest;
    FResponse: TRESTResponse;
    FAuth: THTTPBasicAuthenticator;
    FRegistroLog: IRegistroLog;
    procedure DoRequest(const sResource:string);
  public
    constructor Create(const aBaseURL, aApiKey:string;
      const ARegistroLog: IRegistroLog);
    destructor Destroy; override;
    // Resumen de los pedidos con ID mayor que AIdDesde (0 = todos), en
    // tres peticiones: pedidos, clientes y estados.
    function ListarPedidosResumen(
      AIdDesde: Int64;
      ALista: TPrestaPedidoResumenList): Boolean;
    function CargarPedido(const sIdPedido:string):TOrder;
    property Response: TRESTResponse read FResponse;
  end;

implementation

uses
  inLibMsgIntegraciones,
  inLibScanDateTime;

const
  CIdsPorPeticionPresta = 50;

type
  TListadoPedidosPresta = class
  private
    FConexion: TPrestaConn;
    FDocumento: IXMLDocument;
    FIdsClientes: TList<string>;
    FIdsEstados: TList<string>;
    FNombres: TDictionary<string, string>;
    function SolicitarColeccion(
      const Recurso, Coleccion: string): IXMLNode;
    function FormatearTotal(const Texto: string): string;
    function TextoIdioma(const Nodo: IXMLNode): string;
    function UnirIds(Ids: TList<string>;
      Desde, Hasta: Integer): string;
    procedure AnotarId(Ids: TList<string>; const Id: string);
    procedure LeerPedidos(IdDesde: Int64;
      Lista: TPrestaPedidoResumenList);
    procedure CargarNombres(Ids: TList<string>;
      const Recurso, Coleccion, Elemento, Prefijo: string);
    procedure AnotarNombreCliente(const Nodo: IXMLNode);
    procedure AnotarNombreEstado(const Nodo: IXMLNode);
    procedure SustituirNombres(Lista: TPrestaPedidoResumenList);
  public
    constructor Create(Conexion: TPrestaConn);
    destructor Destroy; override;
    procedure Ejecutar(IdDesde: Int64;
      Lista: TPrestaPedidoResumenList);
  end;

type
  TDestinoDireccionPresta = (ddpEntrega, ddpFacturacion);

  TCargaPedidoPresta = class
  private
    FConexion: TPrestaConn;
    FDocumento: IXMLDocument;
    FPedido: TOrder;
    FNodoPedido: IXMLNode;
    FIdPedido: string;
    FIdCliente: string;
    FIdDireccionEntrega: string;
    FIdDireccionFacturacion: string;
    FIdTransportista: string;
    FIdEstadoPedido: string;
    function SolicitarNodo(const Recurso, Coleccion,
      Elemento: string): IXMLNode;
    function LeerImporte(const Nodo: IXMLNode;
      const Campo: string): Currency;
    function LeerNif(const Nodo: IXMLNode;
      const PrimerNombre, SegundoNombre: string): string;
    procedure CargarPedidoBase(const IdPedido: string);
    procedure CargarCliente;
    procedure AsignarDireccion(const Nodo: IXMLNode;
      const Nif: string; Destino: TDestinoDireccionPresta);
    procedure CargarProvincia(const IdProvincia: string;
      Destino: TDestinoDireccionPresta);
    procedure CargarDireccion(const IdDireccion: string;
      Destino: TDestinoDireccionPresta);
    procedure CargarDirecciones;
    procedure CargarCabeceraEconomica;
    procedure CargarTransportista;
    procedure CargarEstadoPedido;
    procedure CargarLineas;
    procedure CargarMensajesHilo(const IdHilo: string);
    procedure CargarMensajes;
  public
    constructor Create(Conexion: TPrestaConn);
    destructor Destroy; override;
    function Ejecutar(const IdPedido: string): TOrder;
  end;

{ TPrestaConn }

constructor TPrestaConn.Create(const aBaseURL, aApiKey: string;
  const ARegistroLog: IRegistroLog);
begin
  inherited Create;
  FRegistroLog := ARegistroLog;
  FBaseURL := aBaseURL;
  FApiKey  := aApiKey;
  FClient   := TRESTClient.Create(nil);
  FRequest  := TRESTRequest.Create(nil);
  FResponse := TRESTResponse.Create(nil);
  FAuth     := THTTPBasicAuthenticator.Create(nil);
  FClient.BaseURL       := aBaseURL;
  FClient.Authenticator := FAuth;
  FAuth.Username        := aApiKey;
  FAuth.Password        := '';
  FRequest.Client   := FClient;
  FRequest.Response := FResponse;
end;

destructor TPrestaConn.Destroy;
begin
  FreeAndNil(FRequest);
  FreeAndNil(FResponse);
  FreeAndNil(FClient);
  FreeAndNil(FAuth);
  inherited;
end;

procedure TPrestaConn.DoRequest(const sResource: string);
begin
  FRequest.Resource := sResource;
  FRequest.Method   := rmGet;
  FRequest.Execute;
end;

function TPrestaConn.ListarPedidosResumen(
  AIdDesde: Int64;
  ALista: TPrestaPedidoResumenList): Boolean;
var
  Listado: TListadoPedidosPresta;
begin
  if not Assigned(ALista) then
    raise EArgumentNilException.Create('ALista');
  Listado := TListadoPedidosPresta.Create(Self);
  try
    Listado.Ejecutar(AIdDesde, ALista);
    Result := True;
  finally
    FreeAndNil(Listado);
  end;
end;

{ TListadoPedidosPresta }

constructor TListadoPedidosPresta.Create(Conexion: TPrestaConn);
begin
  inherited Create;
  FConexion := Conexion;
  FDocumento := NewXMLDocument;
  FIdsClientes := TList<string>.Create;
  FIdsEstados := TList<string>.Create;
  FNombres := TDictionary<string, string>.Create;
end;

destructor TListadoPedidosPresta.Destroy;
begin
  FreeAndNil(FNombres);
  FreeAndNil(FIdsEstados);
  FreeAndNil(FIdsClientes);
  FDocumento := nil;
  inherited;
end;

function TListadoPedidosPresta.SolicitarColeccion(
  const Recurso, Coleccion: string): IXMLNode;
var
  iEstado: Integer;
begin
  FConexion.DoRequest(Recurso);
  iEstado := FConexion.Response.StatusCode;
  if (iEstado < 200) or (iEstado >= 300) then
    raise Exception.CreateFmt(SErrorPrestaShopHttp, [iEstado, Recurso]);
  FDocumento.LoadFromXML(FConexion.Response.Content);
  FDocumento.Active := True;
  Result := FDocumento.DocumentElement.ChildNodes.FindNode(Coleccion);
end;

function TListadoPedidosPresta.FormatearTotal(const Texto: string): string;
begin
  Result := CurrToStrF(
    StrToFloatDef(Trim(Texto), 0, TFormatSettings.Invariant),
    ffNumber, 2);
end;

function TListadoPedidosPresta.TextoIdioma(const Nodo: IXMLNode): string;
var
  NodoIdioma: IXMLNode;
begin
  NodoIdioma := Nodo.ChildNodes.FindNode('language');
  if Assigned(NodoIdioma) then
    Result := NodoIdioma.Text
  else
    Result := Nodo.Text;
end;

function TListadoPedidosPresta.UnirIds(Ids: TList<string>;
  Desde, Hasta: Integer): string;
var
  i: Integer;
begin
  Result := '';
  for i := Desde to Hasta do
  begin
    if Result <> '' then
      Result := Result + '|';
    Result := Result + Ids[i];
  end;
end;

procedure TListadoPedidosPresta.AnotarId(Ids: TList<string>;
  const Id: string);
begin
  if (Id <> '') and (Id <> '0') and not Ids.Contains(Id) then
    Ids.Add(Id);
end;

procedure TListadoPedidosPresta.LeerPedidos(IdDesde: Int64;
  Lista: TPrestaPedidoResumenList);
var
  i: Integer;
  Nodo: IXMLNode;
  NodoPedidos: IXMLNode;
  Recurso: string;
  Resumen: TPrestaPedidoResumen;
begin
  Recurso := '/orders?display=[id,reference,date_add,id_customer,' +
    'current_state,total_paid_tax_incl]&sort=[id_ASC]';
  if IdDesde > 0 then
    Recurso := Recurso + '&filter[id]=>[' + IntToStr(IdDesde) + ']';
  NodoPedidos := SolicitarColeccion(Recurso, 'orders');
  if Assigned(NodoPedidos) then
  begin
    for i := 0 to NodoPedidos.ChildNodes.Count - 1 do
    begin
      Nodo := NodoPedidos.ChildNodes[i];
      if Nodo.NodeName = 'order' then
      begin
        Resumen := Default(TPrestaPedidoResumen);
        Resumen.IdPedido := Nodo.ChildNodes['id'].Text;
        Resumen.Referencia := Nodo.ChildNodes['reference'].Text;
        Resumen.Fecha := Nodo.ChildNodes['date_add'].Text;
        // Hasta resolver los nombres, Cliente y Estado guardan los ID.
        Resumen.Cliente := Nodo.ChildNodes['id_customer'].Text;
        Resumen.Estado := Nodo.ChildNodes['current_state'].Text;
        Resumen.Total := FormatearTotal(
          Nodo.ChildNodes['total_paid_tax_incl'].Text);
        AnotarId(FIdsClientes, Resumen.Cliente);
        AnotarId(FIdsEstados, Resumen.Estado);
        Lista.Add(Resumen);
      end;
    end;
  end;
end;

procedure TListadoPedidosPresta.AnotarNombreCliente(const Nodo: IXMLNode);
begin
  FNombres.AddOrSetValue(
    'C' + Nodo.ChildNodes['id'].Text,
    Trim(Nodo.ChildNodes['firstname'].Text + ' ' +
      Nodo.ChildNodes['lastname'].Text));
end;

procedure TListadoPedidosPresta.AnotarNombreEstado(const Nodo: IXMLNode);
begin
  FNombres.AddOrSetValue(
    'E' + Nodo.ChildNodes['id'].Text,
    TextoIdioma(Nodo.ChildNodes['name']));
end;

procedure TListadoPedidosPresta.CargarNombres(Ids: TList<string>;
  const Recurso, Coleccion, Elemento, Prefijo: string);
var
  i: Integer;
  iDesde: Integer;
  iHasta: Integer;
  Nodo: IXMLNode;
  NodoColeccion: IXMLNode;
begin
  iDesde := 0;
  while iDesde < Ids.Count do
  begin
    iHasta := iDesde + CIdsPorPeticionPresta - 1;
    if iHasta >= Ids.Count then
      iHasta := Ids.Count - 1;
    NodoColeccion := SolicitarColeccion(
      Recurso + '&filter[id]=[' + UnirIds(Ids, iDesde, iHasta) + ']',
      Coleccion);
    if Assigned(NodoColeccion) then
    begin
      for i := 0 to NodoColeccion.ChildNodes.Count - 1 do
      begin
        Nodo := NodoColeccion.ChildNodes[i];
        if (Nodo.NodeName = Elemento) and (Prefijo = 'C') then
          AnotarNombreCliente(Nodo)
        else if Nodo.NodeName = Elemento then
          AnotarNombreEstado(Nodo);
      end;
    end;
    iDesde := iHasta + 1;
  end;
end;

procedure TListadoPedidosPresta.SustituirNombres(
  Lista: TPrestaPedidoResumenList);
var
  i: Integer;
  Nombre: string;
  Resumen: TPrestaPedidoResumen;
begin
  for i := 0 to Lista.Count - 1 do
  begin
    Resumen := Lista[i];
    if FNombres.TryGetValue('C' + Resumen.Cliente, Nombre) then
      Resumen.Cliente := Nombre;
    if FNombres.TryGetValue('E' + Resumen.Estado, Nombre) then
      Resumen.Estado := Nombre;
    Lista[i] := Resumen;
  end;
end;

procedure TListadoPedidosPresta.Ejecutar(IdDesde: Int64;
  Lista: TPrestaPedidoResumenList);
begin
  LeerPedidos(IdDesde, Lista);
  CargarNombres(FIdsClientes,
    '/customers?display=[id,firstname,lastname]',
    'customers', 'customer', 'C');
  CargarNombres(FIdsEstados,
    '/order_states?display=[id,name]',
    'order_states', 'order_state', 'E');
  SustituirNombres(Lista);
end;

{ TCargaPedidoPresta }

constructor TCargaPedidoPresta.Create(Conexion: TPrestaConn);
begin
  inherited Create;
  FConexion := Conexion;
  FDocumento := NewXMLDocument;
  FPedido := TOrder.Create;
end;

destructor TCargaPedidoPresta.Destroy;
begin
  FreeAndNil(FPedido);
  FDocumento := nil;
  inherited;
end;

function TCargaPedidoPresta.SolicitarNodo(const Recurso, Coleccion,
  Elemento: string): IXMLNode;
var
  Nodo: IXMLNode;
begin
  FConexion.DoRequest(Recurso);
  FDocumento.LoadFromXML(FConexion.Response.Content);
  FDocumento.Active := True;
  Nodo := FDocumento.DocumentElement;
  Nodo := Nodo.ChildNodes[Coleccion];
  Result := Nodo.ChildNodes[Elemento];
end;

function TCargaPedidoPresta.LeerImporte(const Nodo: IXMLNode;
  const Campo: string): Currency;
var
  Texto: string;
begin
  Texto := Nodo.ChildNodes[Campo].Text;
  Result := StrToFloatDef(StringReplace(Texto, '.', ',', []), 0);
end;

function TCargaPedidoPresta.LeerNif(const Nodo: IXMLNode;
  const PrimerNombre, SegundoNombre: string): string;
begin
  if Assigned(Nodo.ChildNodes.FindNode(PrimerNombre)) then
    Result := Nodo.ChildNodes[PrimerNombre].Text
  else if Assigned(Nodo.ChildNodes.FindNode(SegundoNombre)) then
    Result := Nodo.ChildNodes[SegundoNombre].Text
  else
    Result := '';
end;

procedure TCargaPedidoPresta.CargarPedidoBase(const IdPedido: string);
begin
  FNodoPedido := SolicitarNodo(
    '/orders/?display=full&filter[id]=[' + IdPedido + ']',
    'orders', 'order');
  FIdPedido := FNodoPedido.ChildNodes['id'].Text;
  FIdCliente := FNodoPedido.ChildNodes['id_customer'].Text;
  FIdDireccionEntrega :=
    FNodoPedido.ChildNodes['id_address_delivery'].Text;
  FIdDireccionFacturacion :=
    FNodoPedido.ChildNodes['id_address_invoice'].Text;
  FPedido.idPedido := FIdPedido;
end;

procedure TCargaPedidoPresta.CargarCliente;
var
  Nodo: IXMLNode;
begin
  Nodo := SolicitarNodo(
    '/customers/?display=[firstname,lastname,email]&filter[id]=[' +
    FIdCliente + ']', 'customers', 'customer');
  FPedido.custName := Nodo.ChildNodes['firstname'].Text + ' ' +
    Nodo.ChildNodes['lastname'].Text;
  FPedido.custMail := Nodo.ChildNodes['email'].Text;
end;

procedure TCargaPedidoPresta.AsignarDireccion(const Nodo: IXMLNode;
  const Nif: string; Destino: TDestinoDireccionPresta);
begin
  if Destino = ddpEntrega then
  begin
    FPedido.idAddressDel := Nodo.ChildNodes['id'].Text;
    FPedido.FirstnameDel := Nodo.ChildNodes['firstname'].Text;
    FPedido.LastNameDel := Nodo.ChildNodes['lastname'].Text;
    FPedido.Address1Del := Nodo.ChildNodes['address1'].Text;
    FPedido.Address2Del := Nodo.ChildNodes['address2'].Text;
    FPedido.PostcodeDel := Nodo.ChildNodes['postcode'].Text;
    FPedido.CityDel := Nodo.ChildNodes['city'].Text;
    FPedido.PhoneDel := Nodo.ChildNodes['phone'].Text;
    FPedido.Phone_moDel := Nodo.ChildNodes['phone_mobile'].Text;
    FPedido.DniDel := Nodo.ChildNodes['dni'].Text;
    FPedido.CompanyDel := Nodo.ChildNodes['company'].Text;
    FPedido.Vat_numberDel := Nif;
  end
  else
  begin
    FPedido.idAddressBil := Nodo.ChildNodes['id'].Text;
    FPedido.FirstnameBil := Nodo.ChildNodes['firstname'].Text;
    FPedido.LastNameBil := Nodo.ChildNodes['lastname'].Text;
    FPedido.Address1Bil := Nodo.ChildNodes['address1'].Text;
    FPedido.Address2Bil := Nodo.ChildNodes['address2'].Text;
    FPedido.PostcodeBil := Nodo.ChildNodes['postcode'].Text;
    FPedido.CityBil := Nodo.ChildNodes['city'].Text;
    FPedido.PhoneBil := Nodo.ChildNodes['phone'].Text;
    FPedido.Phone_moBil := Nodo.ChildNodes['phone_mobile'].Text;
    FPedido.DniBil := Nodo.ChildNodes['dni'].Text;
    FPedido.CompanyBil := Nodo.ChildNodes['company'].Text;
    FPedido.Vat_numberBil := Nif;
  end;
end;

procedure TCargaPedidoPresta.CargarProvincia(const IdProvincia: string;
  Destino: TDestinoDireccionPresta);
var
  Nodo: IXMLNode;
  Nombre: string;
begin
  if (IdProvincia <> '0') and (IdProvincia <> '') then
  begin
    Nodo := SolicitarNodo(
      '/states/?display=[id,name]&filter[id]=[' + IdProvincia + ']',
      'states', 'state');
    Nombre := Nodo.ChildNodes['name'].Text;
    if Destino = ddpEntrega then
      FPedido.NameStateDel := Nombre
    else
      FPedido.NameStateBil := Nombre;
  end;
end;

procedure TCargaPedidoPresta.CargarDireccion(const IdDireccion: string;
  Destino: TDestinoDireccionPresta);
var
  Nodo: IXMLNode;
  IdProvincia: string;
  Nif: string;
begin
  Nodo := SolicitarNodo(
    '/addresses/?display=[id,firstname,lastname,address1,address2,' +
    'postcode,city,phone,phone_mobile,dni,id_state,company,vat_number]' +
    '&filter[id]=[' + IdDireccion + ']', 'addresses', 'address');
  IdProvincia := Nodo.ChildNodes['id_state'].Text;
  if Destino = ddpEntrega then
    Nif := LeerNif(Nodo, 'vatnumber', 'vat_number')
  else
    Nif := LeerNif(Nodo, 'vat_number', 'vatnumber');
  AsignarDireccion(Nodo, Nif, Destino);
  CargarProvincia(IdProvincia, Destino);
end;

procedure TCargaPedidoPresta.CargarDirecciones;
begin
  CargarDireccion(FIdDireccionEntrega, ddpEntrega);
  if FIdDireccionFacturacion = FIdDireccionEntrega then
  begin
    FPedido.SameAddress := True;
    FPedido.PutAdressDelinbil;
  end
  else
  begin
    FPedido.SameAddress := False;
    CargarDireccion(FIdDireccionFacturacion, ddpFacturacion);
  end;
end;

procedure TCargaPedidoPresta.CargarCabeceraEconomica;
begin
  FIdTransportista := FNodoPedido.ChildNodes['id_carrier'].Text;
  FIdEstadoPedido := FNodoPedido.ChildNodes['current_state'].Text;
  FPedido.FechaCreacion := FNodoPedido.ChildNodes['date_add'].Text;
  FPedido.FormaPago := FNodoPedido.ChildNodes['payment'].Text;
  FPedido.TotalPedCIVA :=
    LeerImporte(FNodoPedido, 'total_paid_tax_incl');
  FPedido.TotalPedSIVA :=
    LeerImporte(FNodoPedido, 'total_paid_tax_excl');
  FPedido.TotalPagadoReal :=
    LeerImporte(FNodoPedido, 'total_paid_real');
  FPedido.TotalProdSIVA :=
    LeerImporte(FNodoPedido, 'total_products');
  FPedido.TotalProdCIVA :=
    LeerImporte(FNodoPedido, 'total_products_wt');
  FPedido.TotalPortesCIVA :=
    LeerImporte(FNodoPedido, 'total_shipping_tax_incl');
  FPedido.TotalPortesSIVA :=
    LeerImporte(FNodoPedido, 'total_shipping_tax_excl');
  FPedido.ReferenciaCliente := FNodoPedido.ChildNodes['reference'].Text;
end;

procedure TCargaPedidoPresta.CargarTransportista;
var
  Nodo: IXMLNode;
begin
  if (FIdTransportista <> '') and (FIdTransportista <> '0') then
  begin
    Nodo := SolicitarNodo(
      '/carriers/?display=[name]&filter[id]=[' + FIdTransportista + ']',
      'carriers', 'carrier');
    FPedido.Transportista := Nodo.ChildNodes['name'].Text;
  end;
end;

procedure TCargaPedidoPresta.CargarEstadoPedido;
var
  Nodo: IXMLNode;
  NodoNombre: IXMLNode;
  NodoIdioma: IXMLNode;
begin
  if (FIdEstadoPedido <> '') and (FIdEstadoPedido <> '0') then
  begin
    Nodo := SolicitarNodo(
      '/order_states/?display=[name]&filter[id]=[' +
      FIdEstadoPedido + ']', 'order_states', 'order_state');
    NodoNombre := Nodo.ChildNodes['name'];
    NodoIdioma := NodoNombre.ChildNodes['language'];
    if Assigned(NodoIdioma) then
      FPedido.EstadoPedido := NodoIdioma.Text
    else
      FPedido.EstadoPedido := NodoNombre.Text;
  end;
end;

procedure TCargaPedidoPresta.CargarLineas;
var
  Nodo: IXMLNode;
  NodoAsociaciones: IXMLNode;
  NodoLineas: IXMLNode;
  Linea: TLineaPed;
  PrecioConIva: string;
  PrecioSinIva: string;
begin
  NodoAsociaciones := FNodoPedido.ChildNodes['associations'];
  if Assigned(NodoAsociaciones) then
  begin
    NodoLineas := NodoAsociaciones.ChildNodes['order_rows'];
    if Assigned(NodoLineas) then
    begin
      Nodo := NodoLineas.ChildNodes['order_row'];
      while Assigned(Nodo) and (Nodo.NodeName = 'order_row') do
      begin
        Linea.idLinea := Nodo.ChildNodes['id'].Text;
        Linea.idProducto := Nodo.ChildNodes['product_id'].Text;
        Linea.sCantidad := Nodo.ChildNodes['product_quantity'].Text;
        Linea.sDescripcion := Nodo.ChildNodes['product_name'].Text;
        Linea.sRefAtrib := Nodo.ChildNodes['product_attribute_id'].Text;
        Linea.sRefProd := Nodo.ChildNodes['product_reference'].Text;
        Linea.sCodEAN13 := Nodo.ChildNodes['product_ean13'].Text;
        PrecioConIva := Nodo.ChildNodes['unit_price_tax_incl'].Text;
        PrecioSinIva := Nodo.ChildNodes['unit_price_tax_excl'].Text;
        Linea.cPrecioCIVA := StrToFloatDef(
          StringReplace(PrecioConIva, '.', ',', []), 0);
        Linea.cPrecioSIVA := StrToFloatDef(
          StringReplace(PrecioSinIva, '.', ',', []), 0);
        FPedido.LineasPedido.Add(Linea);
        Nodo := Nodo.NextSibling;
      end;
    end;
  end;
end;

procedure TCargaPedidoPresta.CargarMensajesHilo(const IdHilo: string);
var
  Nodo: IXMLNode;
  NodoMensajes: IXMLNode;
  Mensaje: TMensaje;
begin
  NodoMensajes := SolicitarNodo(
    '/customer_messages/?display=full&filter[id_customer_thread]=[' +
    IdHilo + ']', 'customer_messages', 'customer_message');
  Nodo := NodoMensajes;
  while Assigned(Nodo) and (Nodo.NodeName = 'customer_message') do
  begin
    Mensaje.idMensaje := Nodo.ChildNodes['id'].Text;
    Mensaje.Texto := Nodo.ChildNodes['message'].Text;
    Mensaje.idEmpleado := Nodo.ChildNodes['id_employee'].Text;
    Mensaje.InstanteMsg := scandatetimernof(
      'yyyy-mm-dd hh:nn:ss', Nodo.ChildNodes['date_add'].Text);
    FPedido.MensajesPedido.LMensajes.Add(Mensaje);
    Nodo := Nodo.NextSibling;
  end;
end;

procedure TCargaPedidoPresta.CargarMensajes;
var
  NodoHilo: IXMLNode;
  NodoHilos: IXMLNode;
begin
  FConexion.DoRequest(
    '/customer_threads/?display=full&filter[id_order]=[' +
    FIdPedido + ']');
  FDocumento.LoadFromXML(FConexion.Response.Content);
  FDocumento.Active := True;
  NodoHilos := FDocumento.DocumentElement.ChildNodes['customer_threads'];
  if Assigned(NodoHilos) and
     Assigned(NodoHilos.ChildNodes.FindNode('customer_thread')) then
  begin
    NodoHilo := NodoHilos.ChildNodes['customer_thread'];
    FPedido.MensajesPedido.Estado :=
      NodoHilo.ChildNodes['status'].Text;
    FPedido.MensajesPedido.idCustomer_Threat :=
      NodoHilo.ChildNodes['id'].Text;
    CargarMensajesHilo(FPedido.MensajesPedido.idCustomer_Threat);
  end;
end;

function TCargaPedidoPresta.Ejecutar(const IdPedido: string): TOrder;
begin
  CargarPedidoBase(IdPedido);
  CargarCliente;
  CargarDirecciones;
  CargarCabeceraEconomica;
  CargarTransportista;
  CargarEstadoPedido;
  CargarLineas;
  try
    CargarMensajes;
  except
    // Los pedidos sin hilos de mensajes son válidos.
    on E: Exception do
      if Assigned(FConexion.FRegistroLog) then
        FConexion.FRegistroLog.RegistrarAviso(
        'PrestaImporter: mensajes del pedido ' + IdPedido +
        ' omitidos: ' + E.Message);
  end;
  Result := FPedido;
  FPedido := nil;
end;

function TPrestaConn.CargarPedido(const sIdPedido: string): TOrder;
var
  Carga: TCargaPedidoPresta;
begin
  Carga := TCargaPedidoPresta.Create(Self);
  try
    Result := Carga.Ejecutar(sIdPedido);
  finally
    FreeAndNil(Carga);
  end;
end;

end.
