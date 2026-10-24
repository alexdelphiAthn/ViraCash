unit inLibPresta;


interface

uses
  SysUtils, DateUtils, ScanDateTime, System.Generics.Collections;

type
  TAddress = record
    idAddress,
    Firstname,
    Lastname,
    Address1,
    Address2,
    Postcode,
    City,
    Phone,
    Phone_mo,
    Dni,
    Company,
    Vat_number,
    NameState :string
  end;

  TLineaPed = record
    idLinea:String;
    idProducto:String;
    sCantidad:String;
    sDescripcion:String;
    sRefAtrib:String;
    sRefProd:String;
    sCodEAN13:String;
    cPrecioCIVA:Currency;
    cPrecioSIVA:Currency
  end;

  TMensaje = record
    idMensaje:string;
    idEmpleado:string;
    InstanteMsg:TDateTime;
    Texto:String;
    Empleado:string;
  end;

  TMensajesPedido = record
    idCustomer_Threat:String;
    Estado:String;
    LMensajes:TList<TMensaje>;
  end;

  TOrder = class
  private
    _idPedido:String;
    _custName:string;
    _custMail:string;
    _FechaCreacion:String;
    _dFechaCreacion:TDateTime;
    _FormaPago:String;
    _TotalPedCIVA:Currency;
    _TotalPedSIVA:Currency;
    _TotalPagadoReal:Currency;
    _TotalProdSIVA:Currency;
    _TotalProdCIVA:Currency;
    _TotalPortesCIVA:Currency;
    _TotalPortesSIVA:Currency;
    _ReferenciaCliente:String;
    _custAddDel:TAddress;
    _custAddBil:TAddress;
    _bSameAddress:Boolean;
    _Transportista:String;
    _EstadoPedido:String;
    function GetcustName: String;
    procedure SetcustName(const Value: String);
    function GetAddress1Bil: String;
    function GetAddress1Del: String;
    function GetAddress2Bil: String;
    function GetAddress2Del: String;
    function GetCompanyBil: String;
    function GetCompanyDel: String;
    function GetcustMail: String;
    function GetDniBil: String;
    function GetDniDel: String;
    function GetFirstNameBil: String;
    function GetFirstNameDel: String;
    function GetLastNameBil: String;
    function GetLastNameDel: String;
    function GetNameStateBil: String;
    function GetNameStateDel: String;
    function GetPhone_moBil: String;
    function GetPhone_moDel: String;
    function GetPhoneBil: String;
    function GetPhoneDel: String;
    function GetPostcodeBil: String;
    function GetPostcodeDel: String;
    function GetVat_numberBil: String;
    function GetVat_numberDel: String;
    procedure SetAddress1Bil(const Value: String);
    procedure SetAddress1Del(const Value: String);
    procedure SetAddress2Bil(const Value: String);
    procedure SetAddress2Del(const Value: String);
    procedure SetCompanyBil(const Value: String);
    procedure SetCompanyDel(const Value: String);
    procedure SetcustMail(const Value: String);
    procedure SetDniBil(const Value: String);
    procedure SetDniDel(const Value: String);
    procedure SetGetFirstNameBil(const Value: String);
    procedure SetGetFirstNameDel(const Value: String);
    procedure SetLasNameBil(const Value: String);
    procedure SetLasNameDel(const Value: String);
    procedure SetNameStateBil(const Value: String);
    procedure SetNameStateDel(const Value: String);
    procedure SetPhone_moBil(const Value: String);
    procedure SetPhone_moDel(const Value: String);
    procedure SetPhoneBil(const Value: String);
    procedure SetPhoneDel(const Value: String);
    procedure SetPostcodeBil(const Value: String);
    procedure SetPostcodeDel(const Value: String);
    procedure SetVat_numberBil(const Value: String);
    procedure SetVat_numberDel(const Value: String);
    function GetCityBil: String;
    function GetCityDel: String;
    procedure SetCityBil(const Value: String);
    procedure SetCityDel(const Value: String);
    function GetIdPedido: String;
    procedure SetIdPedido(const Value: String);
    function GetidAddressDel: String;
    procedure SetidAddressDel(const Value: String);
    function GetidAddressBil: String;
    procedure SetidAddressBil(const Value: String);
    function GetSameAddress: Boolean;
    procedure SetSameAddress(const Value: Boolean);
    function GetdFechaCreacion: TDateTime;
    function GetFechaCreacion: String;
    function GetFormaPago: String;
    function GetReferenciaCliente: String;
    function GetTotalPagadoReal: Currency;
    function GetTotalPedCIVA: Currency;
    function GetTotalPedSIVA: Currency;
    function GetTotalPortesCIVA: Currency;
    function GetTotalPortesSIVA: Currency;
    function GetTotalProdCIVA: Currency;
    function GetTotalProdSIVA: Currency;
    procedure SetdFechaCreacion(const Value: TDateTime);
    procedure SetFechaCreacion(const Value: String);
    procedure SetFormaPago(const Value: String);
    procedure SetReferenciaCliente(const Value: String);
    procedure SetTotalPagadoReal(const Value: Currency);
    procedure SetTotalPedCIVA(const Value: Currency);
    procedure SetTotalPedSIVA(const Value: Currency);
    procedure SetTotalPortesCIVA(const Value: Currency);
    procedure SetTotalPortesSIVA(const Value: Currency);
    procedure SetTotalProdCIVA(const Value: Currency);
    procedure SetTotalProdSIVA(const Value: Currency);
    function GetTransportista: String;
    procedure SetTransportista(const Value: String);
    function GetEstadoPedido: String;
    procedure SetEstadoPedido(const Value: String);
    { private declarations }
  protected
    { protected declarations }
  public
    LineasPedido:TList<TLineaPed>;
    MensajesPedido:TMensajesPedido;
    procedure PutAdressDelinbil;
    //Datos b�sicos del pedido
    Property idPedido:String read GetIdPedido write SetIdPedido;
    //Datos b�sicos del cliente
    Property custName:String read GetcustName write SetcustName;
    Property custMail:String read GetcustMail write SetcustMail;
    Property SameAddress:Boolean read GetSameAddress write SetSameAddress;
    //Direcci�n de env�o
    Property idAddressDel:String read GetidAddressDel write SetidAddressDel;
    Property FirstnameDel:String read GetFirstNameDel write SetGetFirstNameDel;
    Property LastNameDel:String read GetLastNameDel write SetLasNameDel;
    Property Address1Del:String read GetAddress1Del write SetAddress1Del;
    Property Address2Del:String read GetAddress2Del write SetAddress2Del;
    Property CityDel:String read GetCityDel write SetCityDel;
    Property PostcodeDel:String read GetPostcodeDel write SetPostcodeDel;
    Property PhoneDel:String read GetPhoneDel write SetPhoneDel;
    Property Phone_moDel:String read GetPhone_moDel write SetPhone_moDel;
    Property DniDel:String read GetDniDel write SetDniDel;
    Property CompanyDel:String read GetCompanyDel write SetCompanyDel;
    Property Vat_numberDel:String read GetVat_numberDel write SetVat_numberDel;
    Property NameStateDel:String read GetNameStateDel write SetNameStateDel;
    //Direcci�n de Facturaci�n
    Property idAddressBil:String read GetidAddressBil write SetidAddressBil;
    Property FirstnameBil:String read GetFirstNameBil write SetGetFirstNameBil;
    Property LastNameBil:String read GetLastNameBil write SetLasNameBil;
    Property Address1Bil:String read GetAddress1Bil write SetAddress1Bil;
    Property Address2Bil:String read GetAddress2Bil write SetAddress2Bil;
    Property CityBil:String read GetCityBil write SetCityBil;
    Property PostcodeBil:String read GetPostcodeBil write SetPostcodeBil;
    Property PhoneBil:String read GetPhoneBil write SetPhoneBil;
    Property Phone_moBil:String read GetPhone_moBil write SetPhone_moBil;
    Property DniBil:String read GetDniBil write SetDniBil;
    Property CompanyBil:String read GetCompanyBil write SetCompanyBil;
    Property Vat_numberBil:String read GetVat_numberBil write SetVat_numberBil;
    Property NameStateBil:String read GetNameStateBil write SetNameStateBil;
    Property FechaCreacion:String     read GetFechaCreacion  write SetFechaCreacion;
    Property FormaPago:String         read GetFormaPago  write SetFormaPago;
    Property TotalPedCIVA:Currency    read GetTotalPedCIVA  write SetTotalPedCIVA;
    Property TotalPedSIVA:Currency    read GetTotalPedSIVA  write SetTotalPedSIVA;
    Property TotalPagadoReal:Currency read GetTotalPagadoReal  write SetTotalPagadoReal;
    Property TotalProdSIVA:Currency   read GetTotalProdSIVA  write SetTotalProdSIVA;
    Property TotalProdCIVA:Currency   read GetTotalProdCIVA  write SetTotalProdCIVA;
    Property TotalPortesCIVA:Currency read GetTotalPortesCIVA  write SetTotalPortesCIVA;
    Property TotalPortesSIVA:Currency read GetTotalPortesSIVA  write SetTotalPortesSIVA;
    Property ReferenciaCliente:String read GetReferenciaCliente  write SetReferenciaCliente;
    Property Transportista:String read GetTransportista  write SetTransportista;
    Property EstadoPedido:String read GetEstadoPedido  write SetEstadoPedido;
    { public declarations }
    Function ToString():String; override;
    published
        constructor Create;
    { published declarations }
  end;


implementation

{ TOrder }

function TOrder.GetCityBil: String;
begin
  Result := Self._custAddBil.City;
end;

function TOrder.GetCityDel: String;
begin
  Result := Self._custAddDel.City;
end;

constructor TOrder.Create;
begin
  LineasPedido := TList<TLineaPed>.Create;
  MensajesPedido.LMensajes := TList<TMensaje>.Create;
end;

function TOrder.GetAddress1Bil: String;
begin
  Result := Self._custAddBil.Address1;
end;

function TOrder.GetAddress1Del: String;
begin
  Result := Self._custAddDel.Address1;
end;

function TOrder.GetAddress2Bil: String;
begin
  Result := Self._custAddBil.Address2;
end;

function TOrder.GetAddress2Del: String;
begin
  Result := Self._custAddDel.Address2;
end;

function TOrder.GetCompanyBil: String;
begin
  Result := Self._custAddBil.Company;
end;

function TOrder.GetCompanyDel: String;
begin
  Result := Self._custAddDel.Company;
end;

function TOrder.GetcustMail: String;
begin
  Result := Self._custMail;
end;

function TOrder.GetcustName: String;
begin
  Result := Self._custName;
end;

function TOrder.GetdFechaCreacion: TDateTime;
begin
  Result := Self._dFechaCreacion;
end;

function TOrder.GetDniBil: String;
begin
  Result := Self._custAddBil.Dni;
end;

function TOrder.GetDniDel: String;
begin
  Result := Self._custAddDel.Dni;
end;

function TOrder.GetEstadoPedido: String;
begin
  Result := Self._EstadoPedido;
end;

function TOrder.GetFechaCreacion: String;
begin
  Result := Self._FechaCreacion;
end;

function TOrder.GetFirstNameBil: String;
begin
  Result := Self._custAddBil.Firstname;
end;

function TOrder.GetFirstNameDel: String;
begin
  Result := Self._custAddDel.Firstname;
end;

function TOrder.GetFormaPago: String;
begin
  Result := Self._FormaPago;
end;

function TOrder.GetidAddressBil: String;
begin
  Result := Self._custAddBil.idAddress;
end;

function TOrder.GetidAddressDel: String;
begin
  Result := Self._custAddDel.idAddress;
end;

function TOrder.GetIdPedido: String;
begin
  Result := Self._idPedido;
end;

function TOrder.GetLastNameBil: String;
begin
  Result := Self._custAddBil.Lastname;
end;

function TOrder.GetLastNameDel: String;
begin
  Result := Self._custAddDel.Lastname;
end;

function TOrder.GetNameStateBil: String;
begin
  Result := Self._custAddBil.NameState;
end;

function TOrder.GetNameStateDel: String;
begin
  Result := Self._custAddDel.NameState;
end;

function TOrder.GetPhoneBil: String;
begin
  Result := Self._custAddBil.Phone;
end;

function TOrder.GetPhoneDel: String;
begin
  Result := Self._custAddDel.Phone;
end;

function TOrder.GetPhone_moBil: String;
begin
  Result := Self._custAddBil.Phone;
end;

function TOrder.GetPhone_moDel: String;
begin
  Result := Self._custAddDel.Phone_mo;
end;

function TOrder.GetPostcodeBil: String;
begin
  Result := Self._custAddBil.Postcode;
end;

function TOrder.GetPostcodeDel: String;
begin
  Result := Self._custAddDel.Postcode;
end;

function TOrder.GetReferenciaCliente: String;
begin
  Result := _ReferenciaCliente;
end;

function TOrder.GetSameAddress: Boolean;
begin
  Result := Self._bSameAddress;
end;

function TOrder.GetTotalPagadoReal: Currency;
begin
  Result := Self._TotalPagadoReal;
end;

function TOrder.GetTotalPedCIVA: Currency;
begin
  Result := Self._TotalPedCIVA;
end;

function TOrder.GetTotalPedSIVA: Currency;
begin
  Result := Self._TotalPedSIVA;
end;

function TOrder.GetTotalPortesCIVA: Currency;
begin
  Result := Self._TotalPortesCIVA;
end;

function TOrder.GetTotalPortesSIVA: Currency;
begin
  Result := Self._TotalPortesSIVA;
end;

function TOrder.GetTotalProdCIVA: Currency;
begin
  Result := Self._TotalProdCIVA;
end;

function TOrder.GetTotalProdSIVA: Currency;
begin
  Result := Self._TotalProdSIVA;
end;

function TOrder.GetTransportista: String;
begin
  Result := Self.Transportista;
end;

function TOrder.GetVat_numberBil: String;
begin
  Result := Self._custAddBil.Vat_number;
end;

function TOrder.GetVat_numberDel: String;
begin
  Result := Self._custAddDel.Vat_number;
end;

procedure TOrder.PutAdressDelinbil;
begin
  with Self._custAddDel do
  begin
    Self._custAddBil.idAddress   := idAddress ;
    Self._custAddBil.Firstname   := Firstname ;
    Self._custAddBil.Lastname    := Lastname  ;
    Self._custAddBil.Address1    := Address1  ;
    Self._custAddBil.Address2    := Address2  ;
    Self._custAddBil.Postcode    := Postcode  ;
    Self._custAddBil.City        := City      ;
    Self._custAddBil.Phone       := Phone     ;
    Self._custAddBil.Phone_mo    := Phone_mo  ;
    Self._custAddBil.Dni         := Dni       ;
    Self._custAddBil.Company     := Company   ;
    Self._custAddBil.Vat_number  := Vat_number;
    Self._custAddBil.NameState   := NameState;
  end;
end;

procedure TOrder.SetAddress1Bil(const Value: String);
begin
  Self._custAddBil.Address1 := Value;
end;

procedure TOrder.SetAddress1Del(const Value: String);
begin
  Self._custAddDel.Address1 := Value;
end;

procedure TOrder.SetAddress2Bil(const Value: String);
begin
  Self._custAddBil.Address2 := Value;
end;

procedure TOrder.SetAddress2Del(const Value: String);
begin
  Self._custAddDel.Address2 := Value;
end;

procedure TOrder.SetCityBil(const Value: String);
begin
  Self._custAddBil.City := Value;
end;

procedure TOrder.SetCityDel(const Value: String);
begin
  Self._custAddDel.City := Value;
end;

procedure TOrder.SetCompanyBil(const Value: String);
begin
  Self._custAddBil.Company := Value;
end;

procedure TOrder.SetCompanyDel(const Value: String);
begin
  Self._custAddDel.Company := Value;
end;

procedure TOrder.SetcustMail(const Value: String);
begin
  Self._custMail := Value;
end;

procedure TOrder.SetcustName(const Value: String);
begin
  Self._custName := Value;
end;

procedure TOrder.SetdFechaCreacion(const Value: TDateTime);
begin
  _dFechaCreacion := Value;
end;

procedure TOrder.SetDniBil(const Value: String);
begin
  Self._custAddBil.Dni := Value;
end;

procedure TOrder.SetDniDel(const Value: String);
begin
  Self._custAddDel.Dni := Value;
end;

procedure TOrder.SetEstadoPedido(const Value: String);
begin
  Self._EstadoPedido := Value;
end;

procedure TOrder.SetFechaCreacion(const Value: String);
begin
  Self._FechaCreacion := Value;    //2023-11-18 15:57:17
  Self._dFechaCreacion := scandatetimernof('yyyy-mm-dd hh:nn:ss', Value);
end;

procedure TOrder.SetFormaPago(const Value: String);
begin
  Self._FormaPago := Value;
end;

procedure TOrder.SetGetFirstNameBil(const Value: String);
begin
  Self._custAddBil.Firstname := Value;
end;

procedure TOrder.SetGetFirstNameDel(const Value: String);
begin
  Self._custAddDel.Firstname := Value;
end;

procedure TOrder.SetidAddressBil(const Value: String);
begin
  Self._custAddBil.idAddress := Value;
end;

procedure TOrder.SetidAddressDel(const Value: String);
begin
  Self._custAddDel.idAddress := Value;
end;

procedure TOrder.SetIdPedido(const Value: String);
begin
  Self._idPedido := Value;
end;

procedure TOrder.SetLasNameBil(const Value: String);
begin
  Self._custAddBil.Lastname := Value;
end;

procedure TOrder.SetLasNameDel(const Value: String);
begin
  Self._custAddDel.Lastname := Value;
end;

procedure TOrder.SetNameStateBil(const Value: String);
begin
  Self._custAddBil.NameState := Value;
end;

procedure TOrder.SetNameStateDel(const Value: String);
begin
  Self._custAddDel.NameState := Value;
end;

procedure TOrder.SetPhoneBil(const Value: String);
begin
  Self._custAddBil.Phone := Value;
end;

procedure TOrder.SetPhoneDel(const Value: String);
begin
  Self._custAddDel.Phone := Value;
end;

procedure TOrder.SetPhone_moBil(const Value: String);
begin
  Self._custAddBil.Phone_mo := Value;
end;

procedure TOrder.SetPhone_moDel(const Value: String);
begin
  Self._custAddDel.Phone_mo := Value;
end;

procedure TOrder.SetPostcodeBil(const Value: String);
begin
  Self._custAddBil.Postcode := Value;
end;

procedure TOrder.SetPostcodeDel(const Value: String);
begin
  Self._custAddDel.Postcode := Value;
end;

procedure TOrder.SetReferenciaCliente(const Value: String);
begin
  Self._ReferenciaCliente := Value;
end;

procedure TOrder.SetSameAddress(const Value: Boolean);
begin
  Self._bSameAddress := Value;
end;

procedure TOrder.SetTotalPagadoReal(const Value: Currency);
begin
  Self._TotalPagadoReal := Value;
end;

procedure TOrder.SetTotalPedCIVA(const Value: Currency);
begin
  Self._TotalPedCIVA := Value;
end;

procedure TOrder.SetTotalPedSIVA(const Value: Currency);
begin
  Self._TotalPedSIVA := Value;
end;

procedure TOrder.SetTotalPortesCIVA(const Value: Currency);
begin
  Self._TotalPortesCIVA := Value;
end;

procedure TOrder.SetTotalPortesSIVA(const Value: Currency);
begin
  Self._TotalPortesSIVA := Value;
end;

procedure TOrder.SetTotalProdCIVA(const Value: Currency);
begin
  Self._TotalProdCIVA := Value;
end;

procedure TOrder.SetTotalProdSIVA(const Value: Currency);
begin
  Self._TotalProdSIVA := Value;
end;

procedure TOrder.SetTransportista(const Value: String);
begin
  Self._Transportista := Value;
end;

procedure TOrder.SetVat_numberBil(const Value: String);
begin
  Self._custAddBil.Vat_number := Value;
end;

procedure TOrder.SetVat_numberDel(const Value: String);
begin
  Self._custAddDel.Vat_number := Value;
end;

function TOrder.ToString: String;
var
 s:String;
 sCabecera, sDireccionDel, sDireccionBil:string;
begin
  sCabecera := 'Id Pedido PS: ' +  Self._idPedido  + sLineBreak +
               'Referencia : ' + Self._ReferenciaCliente + sLineBreak +
       '-------Datos generales del pedido--------------' + sLineBreak +
       'Nombre Cliente: ' + Self._custName + sLineBreak +
       'Email Cliente: ' + Self._custMail + sLineBreak +
       'Fecha de creaci�n: ' + FormatDateTime('dd/mm/yyyy hh:nn:ss',
                                              Self._dFechaCreacion) + sLineBreak +
       'Forma de pago: ' + Self._FormaPago + sLineBreak +
       'Total Pagado Real: ' + CurrToStrF(Self._TotalPagadoReal, ffCurrency, 2) + sLineBreak +
       'Total Productos SIVA: ' + CurrToStrF(Self._TotalProdSIVA, ffCurrency, 2) + sLineBreak +
       'Total Productos CIVA: ' + CurrToStrF(Self._TotalProdCIVA,  ffCurrency, 2) + sLineBreak +
       'Total Pedido CIVA: '   + CurrToStrF(Self._TotalPedCIVA, ffCurrency, 2) + sLineBreak +
       'Total Pedido SIVA: '   + CurrToStrF(Self._TotalPedSIVA,  ffCurrency, 2) + sLineBreak +
       'Total Portes CIVA: '   + CurrToStrF(Self._TotalPortesCIVA,  ffCurrency, 2) + sLineBreak +
       'Total Portes SIVA: '   + CurrToStrF(Self._TotalPortesSIVA,  ffCurrency, 2) + sLineBreak +
       'Transportista: ' + Self._Transportista + sLineBreak +
       'Estado del pedido: ' + Self.EstadoPedido + sLineBreak;
  sDireccionDel :=     '-------Direcci�n Env�o------------------------- ' + sLineBreak +
       'Id Direcci�n PS + ' + Self._custAddDel.idAddress + sLineBreak +
       'Nombre : ' + Self._custAddDel.Firstname  + sLineBreak +
       'Apellidos: ' + Self._custAddDel.Lastname + sLineBreak +
       'Direcci�n 1: ' + Self._custAddDel.Address1 + sLineBreak +
       'Direcci�n 2: ' + Self._custAddDel.Address2 + sLineBreak +
       'C�digo Postal: ' + Self._custAddDel.Postcode + sLineBreak +
       'Ciudad: ' + Self._custAddDel.City + sLineBreak +
       'Provincia: ' + Self._custAddDel.NameState + sLineBreak +
       'Tel�fono1: ' + Self._custAddDel.Phone + sLineBreak +
       'Tel�fono2: ' + Self._custAddDel.Phone_mo + sLineBreak +
       'Dni: '  + Self._custAddDel.Dni +  sLineBreak +
       'Empresa: '+ Self._custAddDel.Company + sLineBreak +
       'CIF Empresa: ' + Self._custAddDel.Vat_number + sLineBreak;
       if Self._bSameAddress then
       sDireccionBil := '------Direcci�n de Facturaci�n igual a la de env�o-----------' + sLineBreak
       else
       begin
         sDireccionBil := '-------Direcci�n Facturaci�n------------------- '+ sLineBreak +
         'Id Direcci�n PS + ' + Self._custAddDel.idAddress + sLineBreak +
         'Nombre : ' + Self._custAddBil.Firstname  + sLineBreak +
         'Apellidos: ' + Self._custAddBil.Lastname + sLineBreak +
         'Direcci�n 1: ' + Self._custAddBil.Address1 + sLineBreak +
         'Direcci�n 2: ' + Self._custAddBil.Address2 + sLineBreak +
         'C�digo Postal: ' + Self._custAddBil.Postcode + sLineBreak +
         'Ciudad: ' + Self._custAddBil.City + sLineBreak +
         'Provincia: ' + Self._custAddBil.NameState + sLineBreak +
         'Tel�fono1: ' + Self._custAddBil.Phone + sLineBreak +
         'Tel�fono2: ' + Self._custAddBil.Phone_mo + sLineBreak +
         'Dni: '  + Self._custAddBil.Dni +  sLineBreak +
         'Empresa: '+ Self._custAddBil.Company + sLineBreak +
         'CIF Empresa: ' + Self._custAddBil.Vat_number + sLineBreak;
       end;
       s := '-----------------------Detalle de Productos--------------------' + sLineBreak;
       var lp: TLineaPed;
       for lp in Self.LineasPedido do
       begin
         s := s + '_______________________________________________________' + sLineBreak;
         s:= s +sLineBreak + 'Id Linea Pedido: ' + lp.idLinea + sLineBreak;
         s := s + 'Id Producto Interna PS: ' + lp.idProducto + sLineBreak;
         s := s + 'Cantidad Pedida: ' + lp.sCantidad + sLineBreak;
         s := s + 'Descripci�n Producto: ' + lp.sDescripcion + sLineBreak;
         s := s + 'C�digo Producto: '+ lp.sRefProd + sLineBreak;
         s := s + 'Referencia Atributos: ' + lp.sRefAtrib + sLineBreak;
         s := s + 'C�digo de barras EAN13: ' + lp.sCodEAN13 + sLineBreak;
         s := s + 'Precio de Venta Sin IVA: ' + CurrToStrF(lp.cPrecioSIVA, ffCurrency, 2) + sLineBreak;
         s := s + 'Precio de Venta Con IVA: ' + CurrToStrF(lp.cPrecioCIVA, ffCurrency, 2) + sLineBreak;
         s := s + '_______________________________________________________' + sLineBreak;
       end;
       s := s + sLineBreak + '-------------Mensajes y Peticiones del Cliente-------------' + sLineBreak;
       s:= s +sLineBreak + 'Id Hilo Mensaje: ' + Self.MensajesPedido.idCustomer_Threat + sLineBreak;
       s:= s +sLineBreak + 'Estado Mensaje: ' + Self.MensajesPedido.Estado + sLineBreak;
       var tm: TMensaje;
       for tm in Self.MensajesPedido.LMensajes do
       begin
         s := s + '_______________________________________________________' + sLineBreak;
         s:= s +sLineBreak + 'Id Mensaje: ' + tm.idMensaje + sLineBreak;
         s:= s +sLineBreak + 'Id Empleado: ' + tm.idEmpleado + sLineBreak;
         s:= s +sLineBreak + 'Mensaje: ' + tm.Texto + sLineBreak;
         s:= s +sLineBreak + 'Fecha/Hora Env�o : ' + FormatDateTime(
                                'dd/mm/yyyy hh:nn:ss', tm.InstanteMsg) + sLineBreak;
         s := s + '_______________________________________________________' + sLineBreak;

       end;
  Result := sCabecera + SDireccionDel + sDireccionBil + s ;
end;

end.
