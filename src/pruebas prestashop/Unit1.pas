unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, REST.Types, Vcl.StdCtrls, Vcl.ExtCtrls,
  REST.Client, Data.Bind.Components, Data.Bind.ObjectScope, Datasnap.DBClient,
  XMLIntf, XMLDoc, Vcl.ToolWin, Vcl.ComCtrls, REST.Authenticator.Simple,
  REST.Authenticator.Basic,
  REST.Authenticator.OAuth, SynEditHighlighter, SynHighlighterXML, SynEdit,
  Data.DB, Vcl.Grids, Vcl.DBGrids;

type
  TForm1 = class(TForm)
    rstclnt1: TRESTClient;
    rstrqst1: TRESTRequest;
    pnl1: TPanel;
    pnl2: TPanel;
    btnXMLMaster: TButton;
    edtBaseURL: TEdit;
    lbl1: TLabel;
    rstrspns1: TRESTResponse;
    spl1: TSplitter;
    edtKey: TEdit;
    lbl2: TLabel;
    lstCategory: TListBox;
    lstDetail: TListBox;
    btnDetail: TButton;
    btnXMLDetail: TButton;
    tlb1: TToolBar;
    btnDelete: TButton;
    btnInsert: TButton;
    btnUpdate: TButton;
    btnSchema: TButton;
    htpbscthntctr1: THTTPBasicAuthenticator;
    edtFiltros: TEdit;
    lbl3: TLabel;
    btnGetGeneral: TButton;
    btnFiltros: TButton;
    SynXMLSyn1: TSynXMLSyn;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    m1: TSynEdit;
    TabSheet2: TTabSheet;
    PageControl2: TPageControl;
    Cliente: TTabSheet;
    cdsCli: TClientDataSet;
    cdsPed: TClientDataSet;
    cdsLinPed: TClientDataSet;
    DBGrid1: TDBGrid;
    TabSheet3: TTabSheet;
    DBGrid2: TDBGrid;
    TabSheet4: TTabSheet;
    DBGrid3: TDBGrid;
    btReadOrders: TButton;
    txtId: TEdit;
    procedure btnXMLMasterClick(Sender: TObject);
    procedure btnDetailClick(Sender: TObject);
    procedure btnXMLDetailClick(Sender: TObject);
    procedure btnInsertClick(Sender: TObject);
    procedure btnSchemaClick(Sender: TObject);
    procedure btnUpdateClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnGetGeneralClick(Sender: TObject);
    procedure btnFiltrosClick(Sender: TObject);
    procedure btReadOrdersClick(Sender: TObject);
  private
    { Private declarations }
  public
    procedure AsignarDatosBasicos;
//    function FormatXMLFile(const sXml:string):string;
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses
  inLibPresta,
  ScanDateTime;


{$R *.dfm}


//function TForm1.FormatXMLFile(const sXml:string):string;
//var
//   oXml : IXMLDocument;
// begin
//   Result := FormatXMLData(sXml);
// end;

procedure TForm1.AsignarDatosBasicos;
begin
   rstclnt1.BaseURL :=  edtBaseURL.Text;
   htpbscthntctr1.Username := edtKey.Text;
   if lstCategory.ItemIndex = -1 then
     lstCategory.ItemIndex := 0;
end;

procedure TForm1.btnDeleteClick(Sender: TObject);
begin
  AsignarDatosBasicos;
  //rstrqst1.ClearBody;
  rstrqst1.AddBody(m1.text, ctAPPLICATION_XML);
  rstrqst1.Resource := lstCategory.Items[lstCategory.ItemIndex] ;
  rstrqst1.Method := rmDELETE;
  rstrqst1.Execute;
  m1.Text := rstrspns1.Content;

end;

procedure TForm1.btnDetailClick(Sender: TObject);
var
  XMLDoc : IXMLDocument;
  ValueNode, LNode: IXMLNode;
  I:Integer;
  sId:WideString;
begin
  lstDetail.Clear;
  AsignarDatosBasicos;
  rstrqst1.Resource := lstCategory.Items[lstCategory.ItemIndex];
  rstrqst1.Execute;
  XMLDoc := TXMLDocument.Create(nil);
  XMLDoc.LoadFromXML(rstrspns1.Content);
  XMLDoc.Active := True;
  ValueNode := XMLDoc.ChildNodes.FindNode('prestashop');
  ValueNode := ValueNode.ChildNodes.Get(0);
  if (ValueNode <> nil) then
  begin
    for I := 0 to ValueNode.ChildNodes.Count - 1 do
    begin
      sId := ValueNode.ChildNodes.Get(I).NodeName;
      LNode :=  ValueNode.ChildNodes.Get(I);
      sId := LNode.Attributes['id'];
      lstDetail.Items.Add(sId);
    end;
    lstDetail.Sorted := True;
  end;
//  FreeAndNil(XmlDoc);
end;

procedure TForm1.btnFiltrosClick(Sender: TObject);
begin
    AsignarDatosBasicos;
    rstrqst1.Resource := edtFiltros.Text;
    rstrqst1.Method := rmGet;
    rstrqst1.Execute;
    m1.Text := rstrspns1.Content;
end;

procedure TForm1.btnGetGeneralClick(Sender: TObject);
begin
    AsignarDatosBasicos;
    rstrqst1.Resource := '';
    rstrqst1.Method := rmGet;
    rstrqst1.Execute;
    m1.Text := rstrspns1.Content;
end;

procedure TForm1.btnInsertClick(Sender: TObject);
begin
  AsignarDatosBasicos;
  //rstrqst1.ClearBody;
  rstrqst1.AddBody(m1.text, ctAPPLICATION_XML);
  rstrqst1.Resource := lstCategory.Items[lstCategory.ItemIndex] ;
  rstrqst1.Method := rmPost;
  rstrqst1.Execute;
  m1.Text := rstrspns1.Content;
end;

procedure TForm1.btnSchemaClick(Sender: TObject);
begin
  AsignarDatosBasicos;
  //rstrqst1.AddBody(m1.text, ctTEXT_XML);
  rstrqst1.Resource := lstCategory.Items[lstCategory.ItemIndex] +
                                                                '?schema=blank';
  rstrqst1.Method := rmGet;
  rstrqst1.Execute;
  m1.Text := rstrspns1.Content;
end;

procedure TForm1.btnUpdateClick(Sender: TObject);
begin
  AsignarDatosBasicos;
  //rstrqst1.ClearBody;
  rstrqst1.AddBody(m1.text, ctAPPLICATION_XML);
  rstrqst1.Resource := lstCategory.Items[lstCategory.ItemIndex] ;
  rstrqst1.Method := rmPUT;
  rstrqst1.Execute;
  m1.Text := rstrspns1.Content;
end;

procedure TForm1.btnXMLDetailClick(Sender: TObject);
begin
  if lstDetail.Count > 0 then
  begin
    if lstDetail.ItemIndex = -1 then
       lstDetail.ItemIndex := 0;
    rstrqst1.Resource := lstCategory.Items[lstCategory.ItemIndex]+'/'+
                         lstDetail.Items[lstDetail.ItemIndex];
    rstrqst1.Execute;
    m1.Text := rstrspns1.Content;
  end;
end;

procedure TForm1.btnXMLMasterClick(Sender: TObject);
begin
   AsignarDatosBasicos;
   rstrqst1.Resource := lstCategory.Items[lstCategory.ItemIndex];
   rstrqst1.Execute;
   m1.Text:=rstrspns1.Content;
end;

procedure TForm1.btReadOrdersClick(Sender: TObject);
var
  xmlDoc : IXMLDocument;
  xmlNode,
  xmlNodeOrder,
  xmlNodeOrders,
  xmlNodeCustomers,
  xmlNodeCustomer,
  xmlNodeAddresses,
  xmlNodeAddress,
  xmlNodeStates,
  xmlNodeOrderStates,
  xmlNodeOrderState,
  xmlNodeAssociations,
  xmlNodeRows,
  xmlNodeCarriers,
  xmlNodeCarrier,
  xmlNodeCustomerThreads,
  xmlNodeCustomerThread,
  xmlNodeCustomerThreadAssoc,
  xmlNodeMessages,
  xmlNodeMessage,
  xmlNodeState : IXMLNode;
  sID, sIdCli, sDirIn, sDirDe,
  sNom, sApell, sEmail, sidAdress,
  sFecha,
  sIdTransportista,
  sIdEstadoPedido,
  sTransportista,
  sEstadoPedido,
  sFirstname,
  sLastname,
  sAddress1,
  sAddress2,
  sPostcode,
  sCity,
  sPhone,
  sPhone_mobile,
  sDni,
  sCompany,
  sVat_number,
  sId_state,
  sFormaPago,
  sTotalPedidoSIVA,
  sTotalPedidoCIVA,
  sTotalProductosSIVA,
  sTotalProductosCIVA,
  sPagadoReal,
  sTotalPortesSIVA,
  sTotalPortesCIVA,
  sReferenciaPedido,
  sNameState,
  sIdLinea :string;
  FOrder : TOrder;
begin
  FOrder := TOrder.Create;
  //PRIMERA PARTE, TOMO LOS DATOS GENERALES DE CLIENTE DESDE PEDIDO 6
  AsignarDatosBasicos;
  rstrqst1.Resource := '/orders/?display=full' +
                                         '&filter[id]=['+ txtId.Text +']';
  rstrqst1.Method := rmGet;
  rstrqst1.Execute;
  //Sacamos el código del cliente y el código de la direción de envío
  xmlDoc := newXMLDocument;
  XMLDoc.LoadFromXML(rstrspns1.Content);
  XMLDoc.Active := True;
  xmlNode := XMLDoc.DocumentElement;
  xmlNodeOrders := xmlNode.ChildNodes['orders']; //orders
  xmlNodeOrder := xmlNodeOrders.ChildNodes['order']; //order
  xmlNode := xmlNodeOrder.ChildNodes['id']; //id
  sId := xmlNode.Text;
  xmlNode := xmlNodeOrder.ChildNodes['id_customer']; //id_customer
  sIdCli := xmlNode.text;
  xmlNode := xmlNodeOrder.ChildNodes['id_address_delivery'];
  sDirDe := xmlNode.text;
  xmlNode := xmlNodeOrder.ChildNodes['id_address_invoice'];//id_address_invoice
  sDirIn := xmlNode.text;
   Forder.idPedido := sID;
  //SEGUNDA PARTE, TOMO LOS DATOS DE CLIENTE, CON EL CÓDIGO QUE VIENE DE PEDIDO
  rstrqst1.Resource := '/customers/?display=[firstname,' +
                                            'lastname,' +
                                            'email' +
                                            ']&filter[id]=['+sIdCli+']';
  rstrqst1.Method := rmGet;
  rstrqst1.Execute;
  //Sacamos el código del cliente y el código de la direción de envío
  XMLDoc.LoadFromXML(rstrspns1.Content);
  XMLDoc.Active := True;
  xmlNode := XMLDoc.DocumentElement;  //prestashop
  xmlNodeCustomers := xmlNode.ChildNodes['customers']; //customers
  xmlNodeCustomer := xmlNodeCustomers.ChildNodes['customer']; //customer
  xmlNode := xmlNodeCustomer.ChildNodes['firstname']; //name
  sNom := xmlNode.Text;
  xmlNode := xmlNodeCustomer.ChildNodes['lastname']; //firstname
  sApell := xmlNode.Text;
  xmlNode := xmlNodeCustomer.ChildNodes['email']; //email
  sEmail := xmlNode.Text;
  FOrder.custName := sNom + ' ' + sApell;
  FOrder.custMail := sEmail;

  //TERCERA PARTE, TOMO LOS DATOS DE DIRECCION DE ENVIO, DEL CÓDIGO DE PEDIDO

  rstrqst1.Resource := '/addresses/?display=[id,'+
                                            'firstname, ' +
                                            'lastname, '+
                                            'address1, '+
                                            'address2, '+
                                            'postcode, '+
                                            'city, '+
                                            'postcode, '+
                                            'phone, '+
                                            'phone_mobile, '+
                                            'dni, '+
                                            'id_state, '+
                                            'company, '+
                                            'vat_number'+
                                            ']&filter[id]=['+sDirDe+']';
  rstrqst1.Method := rmGet;
  rstrqst1.Execute;
  XMLDoc.LoadFromXML(rstrspns1.Content);
  XMLDoc.Active := True;
  xmlNode := XMLDoc.DocumentElement;  //prestashop
  xmlNodeAddresses := xmlNode.ChildNodes['addresses']; //addresses
  xmlNodeAddress := xmlNodeAddresses.ChildNodes['address']; //address
  xmlNode := xmlNodeAddress.ChildNodes['id']; //id adress
  sidAdress := xmlNode.Text;
  xmlNode := xmlNodeAddress.ChildNodes['id_state']; //id_state
  sid_state := xmlNode.Text;
  xmlNode := xmlNodeAddress.ChildNodes['firstname']; //firstname
  sFirstname := xmlNode.Text;
  xmlNode := xmlNodeAddress.ChildNodes['lastname']; //lastname
  sLastname := xmlNode.Text;
  xmlNode := xmlNodeAddress.ChildNodes['address1']; //address1
  sAddress1 := xmlNode.Text;
  xmlNode := xmlNodeAddress.ChildNodes['address2']; //address2
  sAddress2 := xmlNode.Text;
  xmlNode := xmlNodeAddress.ChildNodes['postcode']; //postcode
  sPostcode := xmlNode.Text;
  xmlNode := xmlNodeAddress.ChildNodes['city']; //city
  sCity := xmlNode.Text;
  xmlNode := xmlNodeAddress.ChildNodes['phone']; //phone
  sPhone := xmlNode.Text;
  xmlNode := xmlNodeAddress.ChildNodes['phone_mobile']; //phone_mobile
  sPhone_mobile := xmlNode.Text;
  xmlNode := xmlNodeAddress.ChildNodes['dni']; //dni
  sDni := xmlNode.Text;
  xmlNode := xmlNodeAddress.ChildNodes['company']; //company
  sCompany := xmlNode.Text;
  xmlNode := xmlNodeAddress.ChildNodes['vatnumber']; //vatnumber
  sVat_number := xmlNode.Text;
  with FOrder do
  begin
    idAddressDel := sidAdress;
    FirstnameDel := sFirstname;
    LastNameDel := sLastname;
    Address1Del := sAddress1;
    Address2Del := sAddress2;
    PostcodeDel := sPostcode;
    CityDel := sCity;
    PhoneDel := sPhone;
    Phone_moDel := sPhone_mobile;
    DniDel := sDni;
    CompanyDel := sCompany;
    Vat_numberDel := sVat_number;
  end;
  if (sId_state <> '0') then
  begin
    //TERCERA PARTE, LOS DATOS DE LA PROVINCIA
    rstrqst1.Resource := '/states/?display=[id,name]&filter[id]=[' +
                                                                  sId_state+']';
    rstrqst1.Method := rmGet;
    rstrqst1.Execute;
    XMLDoc.LoadFromXML(rstrspns1.Content);
    XMLDoc.Active := True;
    xmlNode := XMLDoc.DocumentElement;  //prestashop
    xmlNodeStates := xmlNode.ChildNodes['states']; //states
    xmlNodeState := xmlNodeStates.ChildNodes['state']; //state
    xmlNode := xmlNodeState.ChildNodes['name']; //name
    sNameState := xmlNode.Text;
    FOrder.NameStateDel := sNameState
  end;
  if (sDirIn = sDirDe) then
  begin
    FOrder.SameAddress := True;
    FOrder.PutAdressDelinbil;
  end
  else
    FOrder.SameAddress := False;
  if sDirIn <> sDirDe then
  begin
    //QUINTA PARTE, TOMO LOS DATOS DE DIRECCION DE FACTURACION
    rstrqst1.Resource := '/addresses/?display=[id,'+
                                              'firstname, ' +
                                              'lastname, '+
                                              'address1, '+
                                              'address2, '+
                                              'postcode, '+
                                              'city, '+
                                              'postcode, '+
                                              'phone, '+
                                              'phone_mobile, '+
                                              'dni, '+
                                              'id_state, '+
                                              'company, '+
                                              'vat_number'+
                                              ']&filter[id]=['+sDirIn+']';
    rstrqst1.Method := rmGet;
    rstrqst1.Execute;
    XMLDoc.LoadFromXML(rstrspns1.Content);
  //  m1.Text := m1.Text + sLineBreak + rstrspns1.Content;
    XMLDoc.Active := True;
    xmlNode := XMLDoc.DocumentElement;  //prestashop
    ///showmessage(xmlNode.NodeName);
    xmlNodeAddresses := xmlNode.ChildNodes['addresses']; //addresses
    //showmessage(xmlNodeCustomers.NodeName);
    xmlNodeAddress := xmlNodeAddresses.ChildNodes['address']; //address
    xmlNode := xmlNodeAddress.ChildNodes['id']; //id adress
    sidAdress := xmlNode.Text;
    xmlNode := xmlNodeAddress.ChildNodes['id_state']; //id_state
    sid_state := xmlNode.Text;
    xmlNode := xmlNodeAddress.ChildNodes['firstname']; //firstname
    sFirstname := xmlNode.Text;
    xmlNode := xmlNodeAddress.ChildNodes['lastname']; //lastname
    sLastname := xmlNode.Text;
    xmlNode := xmlNodeAddress.ChildNodes['address1']; //address1
    sAddress1 := xmlNode.Text;
    xmlNode := xmlNodeAddress.ChildNodes['address2']; //address2
    sAddress2 := xmlNode.Text;
    xmlNode := xmlNodeAddress.ChildNodes['postcode']; //postcode
    sPostcode := xmlNode.Text;
    xmlNode := xmlNodeAddress.ChildNodes['city']; //city
    sCity := xmlNode.Text;
    xmlNode := xmlNodeAddress.ChildNodes['phone']; //phone
    sPhone := xmlNode.Text;
    xmlNode := xmlNodeAddress.ChildNodes['phone_mobile']; //phone_mobile
    sPhone_mobile := xmlNode.Text;
    xmlNode := xmlNodeAddress.ChildNodes['dni']; //dni
    sDni := xmlNode.Text;
    xmlNode := xmlNodeAddress.ChildNodes['company']; //company
    sCompany := xmlNode.Text;
    xmlNode := xmlNodeAddress.ChildNodes['vat_number']; //vat_number
    sVat_number := xmlNode.Text;
    with FOrder do
    begin
      idAddressBil := sidAdress;
      FirstnameBil := sFirstname;
      LastNameBil := sLastname;
      Address1Bil := sAddress1;
      Address2Bil := sAddress2;
      PostcodeBil := sPostcode;
      PhoneBil := sPhone;
      Phone_moBil := sPhone_mobile;
      DniBil := sDni;
      CompanyBil := sCompany;
      Vat_numberBil := sVat_number;
    end;
    if (sId_state <> '0') then
    begin
      //SEXTA PARTE, LOS DATOS DE LA PROVINCIA DE FACTURACION
      rstrqst1.Resource:= '/states/?display=[id,name]&filter[id]=['+
                                                                sId_state + ']';
      rstrqst1.Method := rmGet;
      rstrqst1.Execute;
      XMLDoc.LoadFromXML(rstrspns1.Content);
      XMLDoc.Active := True;
      xmlNode := XMLDoc.DocumentElement;  //prestashop
      xmlNodeStates := xmlNode.ChildNodes['states']; //states
      xmlNodeState := xmlNodeStates.ChildNodes['state']; //state
      xmlNode := xmlNodeState.ChildNodes['name']; //name
      sNameState := xmlNode.Text;
      FOrder.NameStateBil := sNameState;
    end;
  end;

  //SÉPTIMA PARTE, PROCESO LOS CAMPOS DEL PEDIDO EN SÍ.

  xmlNode := xmlNodeOrder.ChildNodes['id_carrier'];
  sIdTransportista := xmlNode.Text;
  xmlNode := xmlNodeOrder.ChildNodes['current_state']; //id estado pedido
  sIdEstadoPedido := xmlNode.Text;
  xmlNode := xmlNodeOrder.ChildNodes['date_add']; //fecha creación
  sFecha := xmlNode.Text;
  xmlNode := xmlNodeOrder.ChildNodes['payment']; //forma de pago
  sFormapago := xmlNode.Text;
  xmlNode := xmlNodeOrder.ChildNodes['total_paid_tax_incl']; //Total Pedido CIVA
  sTotalPedidoCIVA := xmlNode.Text;
  xmlNode := xmlNodeOrder.ChildNodes['total_paid_tax_excl']; //Total Pedido SIVA
  sTotalPedidoSIVA := xmlNode.Text;
  xmlNode := xmlNodeOrder.ChildNodes['total_paid_real']; //Total Pagado Real
  sPagadoReal := xmlNode.Text;
  xmlNode := xmlNodeOrder.ChildNodes['total_products']; //Total Productos SIVA
  sTotalProductosSIVA := xmlNode.Text;
  xmlNode := xmlNodeOrder.ChildNodes['total_products_wt']; //Total ProductosCIVA
  sTotalProductosCIVA := xmlNode.Text;
  xmlNode := xmlNodeOrder.ChildNodes['total_shipping_tax_incl'];
  sTotalPortesCIVA := xmlNode.Text;
  xmlNode := xmlNodeOrder.ChildNodes['total_shipping_tax_excl'];
  sTotalPortesSIVA := xmlNode.Text;
  xmlNode := xmlNodeOrder.ChildNodes['reference']; //Referencia PedidoPrestashop
  sReferenciaPedido := xmlNode.Text;
  with FOrder do
  begin
    FechaCreacion := sFecha;
    FormaPago := sFormaPago;
    TotalPedCIVA := StrToFloatDef(StringReplace(sTotalPedidoCIVA, '.', ',', []), 0);
    TotalPedSIVA := StrToFloatDef(StringReplace(sTotalPedidoSIVA, '.', ',', []), 0);
    TotalPagadoReal := StrToFloatDef(StringReplace(sPagadoReal, '.', ',', []), 0);
    TotalProdSIVA := StrToFloatDef(StringReplace(sTotalProductosSIVA, '.', ',', []), 0);
    TotalProdCIVA := StrToFloatDef(StringReplace(sTotalProductosCIVA, '.', ',', []), 0);
    TotalPortesCIVA := StrToFloatDef(StringReplace(sTotalPortesCIVA, '.', ',', []), 0);
    TotalPortesSIVA := StrToFloatDef(StringReplace(sTotalPortesSIVA, '.', ',', []), 0);
    ReferenciaCliente := sReferenciaPedido;
  end;

  //OCTAVA PARTE, TRANSPORTISTA

  rstrqst1.Resource := '/carriers/?display=[name'+
                                             ']&filter[id]=['+
                                             sIdTransportista+']';
  rstrqst1.Method := rmGet;
  rstrqst1.Execute;
  XMLDoc.LoadFromXML(rstrspns1.Content);
  XMLDoc.Active := True;
  xmlNode := XMLDoc.DocumentElement;  //prestashop
  xmlNodeCarriers := xmlNode.ChildNodes['carriers'];  //carriers
  xmlNodeCarrier := xmlNodeCarriers.ChildNodes['carrier']; //carrier
  xmlNode := xmlNodeCarrier.ChildNodes['name'];
  sTransportista := xmlNode.Text;
  FOrder.Transportista := sTransportista;

//NOVENA PARTE, ESTADO DEL PEDIDO

  rstrqst1.Resource := '/order_states/?display=[name]' +
                                             '&filter[id]=['+
                                             sIdEstadoPedido+']';
  rstrqst1.Method := rmGet;
  rstrqst1.Execute;
  XMLDoc.LoadFromXML(rstrspns1.Content);
  XMLDoc.Active := True;
  xmlNode := XMLDoc.DocumentElement;  //prestashop
  xmlNodeOrderStates := xmlNode.ChildNodes['order_states'];
  xmlNodeOrderState := xmlNodeOrderStates.ChildNodes['order_state'];
  xmlNodeOrderState := xmlNodeOrderState.ChildNodes['name'];
  xmlNode := xmlNodeOrderState.ChildNodes['language'];
  sEstadoPedido := xmlNode.Text;
  FORder.EstadoPedido := sEstadoPedido;
//DECIMA PARTE, DETALLE DE ARTÍCULOS
  xmlNodeAssociations := xmlNodeOrder.ChildNodes['associations'];
  xmlNodeRows := xmlNodeAssociations.ChildNodes['order_rows'];
  xmlNode := xmlNodeRows.ChildNodes['order_row'];
  var lp:TLineaPed;
  while assigned(xmlNode) and (xmlNode.NodeName = 'order_row') do
  begin
    lp.idLinea :=  xmlNode.ChildNodes['id'].Text;
    lp.idProducto := xmlNode.ChildNodes['product_id'].Text;
    lp.sCantidad := xmlNode.ChildNodes['product_quantity'].Text;
    lp.sDescripcion :=  xmlNode.ChildNodes['product_name'].Text;
    lp.sRefAtrib := xmlNode.ChildNodes['product_attribute_id'].Text;
    lp.sRefProd :=  xmlNode.ChildNodes['product_reference'].Text;
    lp.sCodEAN13 := xmlNode.ChildNodes['product_ean13'].Text;
    var sPrecioCIVA := xmlNode.ChildNodes['unit_price_tax_incl'].Text;
    var sPrecioSIVA := xmlNode.ChildNodes['unit_price_tax_excl'].Text;
    lp.cPrecioCIVA := StrToFloatDef(StringReplace(sPrecioCIVA,'.', ',', []), 0);
    lp.cPrecioSIVA := StrToFloatDef(StringReplace(sPrecioSIVA,'.', ',', []), 0);
    FOrder.LineasPedido.Add(lp);
    xmlNode := xmlNode.NextSibling;
  end;

  //UNDÉCIMA PARTE, MENSAJES DEL PEDIDO

  rstrqst1.Resource := '/customer_threads/?display=full&filter[id_order]=['+
                                                                        sId+']';
  rstrqst1.Method := rmGet;
  rstrqst1.Execute;
  XMLDoc.LoadFromXML(rstrspns1.Content);
  XMLDoc.Active := True;
  xmlNode := XMLDoc.DocumentElement;  //prestashop
  xmlNodeCustomerThreads := xmlNode.ChildNodes['customer_threads'];
  xmlNodeCustomerThread := xmlNodeCustomerThreads.ChildNodes['customer_thread'];
  xmlNode := xmlNodeCustomerThread;
  FOrder.MensajesPedido.Estado := xmlNode.ChildNodes['status'].Text;
  FOrder.MensajesPedido.idCustomer_Threat := xmlNode.ChildNodes['id'].Text;
  xmlNodeCustomerThreadAssoc := xmlNode.ChildNodes['associations'];
  xmlNode := xmlNodeCustomerThreadAssoc.ChildNodes['customer_messages'];

  //DUODÉCIMA PARTE, MENSAJES DEL CLIENTE PROCEDENTES DEL PEDIDO

  rstrqst1.Resource := '/customer_messages/?display=full&'+
                                          'filter[id_customer_thread]=['+
                              FOrder.MensajesPedido.idCustomer_Threat+']';
  rstrqst1.Method := rmGet;
  rstrqst1.Execute;
  XMLDoc.LoadFromXML(rstrspns1.Content);
  XMLDoc.Active := True;
  xmlNode := XMLDoc.DocumentElement;  //prestashop
  xmlNodeMessages := xmlNode.ChildNodes['customer_messages'];
  xmlNodeMessage := xmlNodeMessages.ChildNodes['customer_message'];
  xmlNode := xmlNodeMessage;
  var tm:TMensaje;
  while assigned(xmlNode) and (xmlNode.NodeName = 'customer_message') do
  begin
    tm.idMensaje := xmlNode.ChildNodes['id'].Text;
    tm.Texto := xmlNode.ChildNodes['message'].Text;
    tm.idEmpleado := xmlNode.ChildNodes['id_employee'].Text;
    tm.InstanteMsg := scandatetimernof('yyyy-mm-dd hh:nn:ss',
                                       xmlNode.ChildNodes['date_add'].Text);
    FOrder.MensajesPedido.LMensajes.Add(tm);
    xmlNode := xmlNode.NextSibling;
  end;
  m1.lines.Text := FOrder.ToString;
  FreeAndNil(FOrder);
end;

end.
