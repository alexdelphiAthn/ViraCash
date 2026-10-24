{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoComprasSesionesPresentacionNavegacion                    }
{    Tipo:       Presentacion                                                  }
{ Version:       1.0.0                                                         }
{   Fecha:       10/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Coordina la navegacion desde una sesion a maestros y documentos.         }
{******************************************************************************}
unit inMtoComprasSesionesPresentacionNavegacion;

interface

uses
  System.Classes,
  System.SysUtils,
  Data.DB,
  Vcl.ActnList,
  cxButtons, cxDBEdit, cxGridDBTableView;

type
  TEstadoDestinoDocumentoSesion = (
    eddsValido,
    eddsSinDocumento,
    eddsTipoNoDisponible);

  TDestinoDocumentoSesion = record
    Estado: TEstadoDestinoDocumentoSesion;
    Mantenimiento: string;
    Clave: string;
    Tipo: string;
  end;

  TCargarSeriesNavegacionComprasSesion = reference to procedure(
    const AEmpresa: string;
    AItems: TStrings);

  TEntornoNavegacionComprasSesion = record
    Propietario: TComponent;
    AccionArticulos: TCustomAction;
    AccionAlbaranes: TCustomAction;
    AccionPedidos: TCustomAction;
    AccionProveedor: TCustomAction;
    BotonDocumento: TcxButton;
    BotonDocumentoLateral: TcxButton;
    BotonProveedor: TcxButton;
    VistaDocumentos: TcxGridDBTableView;
    ComboSerie: TcxDBComboBox;
    Documentos: TDataSet;
    Lineas: TDataSet;
    Cabecera: TDataSet;
    EmpresaDefecto: string;
    CargarSeries: TCargarSeriesNavegacionComprasSesion;
    ExisteArticulo: TFunc<string, Boolean>;
    class function Crear(
      APropietario: TComponent;
      AAccionArticulos: TCustomAction;
      AAccionAlbaranes: TCustomAction;
      AAccionPedidos: TCustomAction;
      AAccionProveedor: TCustomAction;
      ABotonDocumento: TcxButton;
      ABotonDocumentoLateral: TcxButton;
      ABotonProveedor: TcxButton;
      AVistaDocumentos: TcxGridDBTableView;
      AComboSerie: TcxDBComboBox;
      ADocumentos: TDataSet;
      ALineas: TDataSet;
      ACabecera: TDataSet;
      const AEmpresaDefecto: string;
      const ACargarSeries: TCargarSeriesNavegacionComprasSesion):
      TEntornoNavegacionComprasSesion; static;
    procedure Validar;
  end;

  TCoordinadorNavegacionComprasSesion = class
  private
    FEntorno: TEntornoNavegacionComprasSesion;
    FEventosConectados: Boolean;
    procedure ConectarEventos;
    procedure DesconectarEventos;
    procedure IrADocumento(Sender: TObject);
    procedure IrAArticulos(Sender: TObject);
    procedure IrAAlbaranes(Sender: TObject);
    procedure IrAPedidos(Sender: TObject);
    procedure IrAProveedor(Sender: TObject);
    procedure InicializarSeries(Sender: TObject);
  public
    constructor Create(
      const AEntorno: TEntornoNavegacionComprasSesion);
    destructor Destroy; override;
  end;

function ResolverDestinoDocumentoSesion(
  AHayDocumento: Boolean;
  const ATipo: string;
  const ASerie: string;
  const ANumero: string): TDestinoDocumentoSesion;

implementation

uses
  inLibMensajesVcl,
  System.UITypes,
  Vcl.Dialogs,
  inLibMsgCompras,
  inLibShowMto;

resourcestring
  SArticuloNoCreadoEncontrado = 'Artículo no creado/encontrado.';
  SErrorPropietarioNavegacionSesionNoDisponible =
    'No se proporciono el propietario de la navegacion de la sesion.';
  SErrorControlesNavegacionSesionNoDisponibles =
    'No se proporcionaron todos los controles de navegacion de la sesion.';
  SErrorDatosNavegacionSesionNoDisponibles =
    'No se proporcionaron todos los datasets de navegacion de la sesion.';

function ResolverDestinoDocumentoSesion(
  AHayDocumento: Boolean;
  const ATipo: string;
  const ASerie: string;
  const ANumero: string): TDestinoDocumentoSesion;
begin
  Result := Default(TDestinoDocumentoSesion);
  Result.Tipo := Trim(ATipo);
  if not AHayDocumento then
    Result.Estado := eddsSinDocumento
  else if SameText(Result.Tipo, 'ALBC') then
  begin
    Result.Estado := eddsValido;
    Result.Mantenimiento := 'AlbaranesCompra';
    Result.Clave := ASerie + ',' + ANumero;
  end
  else if SameText(Result.Tipo, 'PEDC') then
  begin
    Result.Estado := eddsValido;
    Result.Mantenimiento := 'PedidosCompra';
    Result.Clave := ASerie + ',' + ANumero;
  end
  else
    Result.Estado := eddsTipoNoDisponible;
end;

class function TEntornoNavegacionComprasSesion.Crear(
  APropietario: TComponent;
  AAccionArticulos: TCustomAction;
  AAccionAlbaranes: TCustomAction;
  AAccionPedidos: TCustomAction;
  AAccionProveedor: TCustomAction;
  ABotonDocumento: TcxButton;
  ABotonDocumentoLateral: TcxButton;
  ABotonProveedor: TcxButton;
  AVistaDocumentos: TcxGridDBTableView;
  AComboSerie: TcxDBComboBox;
  ADocumentos: TDataSet;
  ALineas: TDataSet;
  ACabecera: TDataSet;
  const AEmpresaDefecto: string;
  const ACargarSeries: TCargarSeriesNavegacionComprasSesion):
  TEntornoNavegacionComprasSesion;
begin
  Result := Default(TEntornoNavegacionComprasSesion);
  Result.Propietario := APropietario;
  Result.AccionArticulos := AAccionArticulos;
  Result.AccionAlbaranes := AAccionAlbaranes;
  Result.AccionPedidos := AAccionPedidos;
  Result.AccionProveedor := AAccionProveedor;
  Result.BotonDocumento := ABotonDocumento;
  Result.BotonDocumentoLateral := ABotonDocumentoLateral;
  Result.BotonProveedor := ABotonProveedor;
  Result.VistaDocumentos := AVistaDocumentos;
  Result.ComboSerie := AComboSerie;
  Result.Documentos := ADocumentos;
  Result.Lineas := ALineas;
  Result.Cabecera := ACabecera;
  Result.EmpresaDefecto := AEmpresaDefecto;
  Result.CargarSeries := ACargarSeries;
  Result.Validar;
end;

procedure TEntornoNavegacionComprasSesion.Validar;
begin
  if Propietario = nil then
  begin
    raise EArgumentNilException.Create(
      SErrorPropietarioNavegacionSesionNoDisponible);
  end;
  if (AccionArticulos = nil) or (AccionAlbaranes = nil) or
     (AccionPedidos = nil) or (AccionProveedor = nil) or
     (BotonDocumento = nil) or (BotonDocumentoLateral = nil) or
     (BotonProveedor = nil) or (VistaDocumentos = nil) or
     (ComboSerie = nil) then
  begin
    raise EArgumentNilException.Create(
      SErrorControlesNavegacionSesionNoDisponibles);
  end;
  if (Documentos = nil) or (Lineas = nil) or (Cabecera = nil) or
     not Assigned(CargarSeries) then
  begin
    raise EArgumentNilException.Create(
      SErrorDatosNavegacionSesionNoDisponibles);
  end;
end;

constructor TCoordinadorNavegacionComprasSesion.Create(
  const AEntorno: TEntornoNavegacionComprasSesion);
begin
  inherited Create;
  FEntorno := AEntorno;
  FEntorno.Validar;
  ConectarEventos;
end;

destructor TCoordinadorNavegacionComprasSesion.Destroy;
begin
  DesconectarEventos;
  inherited;
end;

procedure TCoordinadorNavegacionComprasSesion.ConectarEventos;
begin
  FEntorno.AccionArticulos.OnExecute := IrAArticulos;
  FEntorno.AccionAlbaranes.OnExecute := IrAAlbaranes;
  FEntorno.AccionPedidos.OnExecute := IrAPedidos;
  FEntorno.AccionProveedor.OnExecute := IrAProveedor;
  FEntorno.BotonDocumento.OnClick := IrADocumento;
  FEntorno.BotonDocumentoLateral.OnClick := IrADocumento;
  FEntorno.BotonProveedor.OnClick := IrAProveedor;
  FEntorno.VistaDocumentos.OnDblClick := IrADocumento;
  FEntorno.ComboSerie.Properties.OnInitPopup := InicializarSeries;
  FEventosConectados := True;
end;

procedure TCoordinadorNavegacionComprasSesion.DesconectarEventos;
begin
  if FEventosConectados then
  begin
    FEntorno.AccionArticulos.OnExecute := nil;
    FEntorno.AccionAlbaranes.OnExecute := nil;
    FEntorno.AccionPedidos.OnExecute := nil;
    FEntorno.AccionProveedor.OnExecute := nil;
    FEntorno.BotonDocumento.OnClick := nil;
    FEntorno.BotonDocumentoLateral.OnClick := nil;
    FEntorno.BotonProveedor.OnClick := nil;
    FEntorno.VistaDocumentos.OnDblClick := nil;
    FEntorno.ComboSerie.Properties.OnInitPopup := nil;
    FEventosConectados := False;
  end;
end;

procedure TCoordinadorNavegacionComprasSesion.IrADocumento(
  Sender: TObject);
var
  Destino: TDestinoDocumentoSesion;
  HayDocumento: Boolean;
begin
  HayDocumento := FEntorno.Documentos.Active and
    not FEntorno.Documentos.IsEmpty;
  if HayDocumento then
  begin
    Destino := ResolverDestinoDocumentoSesion(
      True,
      FEntorno.Documentos.FieldByName('TIPO').AsString,
      FEntorno.Documentos.FieldByName('SERIE').AsString,
      FEntorno.Documentos.FieldByName('NUMERO').AsString);
  end
  else
    Destino := ResolverDestinoDocumentoSesion(False, '', '', '');
  if Destino.Estado = eddsSinDocumento then
    ShowMessage_fza(SErrorSesionSinDocumentosCreados)
  else if Destino.Estado = eddsTipoNoDisponible then
  begin
    ShowMessage_fza(Format(
      SErrorMantenimientoTipoDocumentoNoDisponible,
      [Destino.Tipo]));
  end
  else
  begin
    ShowMto(
      FEntorno.Propietario,
      Destino.Mantenimiento,
      Destino.Clave);
  end;
end;

procedure TCoordinadorNavegacionComprasSesion.IrAArticulos(
  Sender: TObject);
var
  sCodigo: string;
begin
  sCodigo := CodigoMtoDataSet(FEntorno.Lineas,
    'CODIGO_ART_TENTATIVO_SESLIN');
  // Sin articulo creado, el atajo abre el mantenimiento sin buscar ficha.
  if sCodigo <> '' then
  begin
    if not Assigned(FEntorno.ExisteArticulo) then
      sCodigo := ''
    else if not FEntorno.ExisteArticulo(sCodigo) then
      sCodigo := '';
  end;
  if sCodigo = '' then
    ShowMessage_fza(SArticuloNoCreadoEncontrado);
  ShowMto(FEntorno.Propietario, 'Articulos', sCodigo);
end;

procedure TCoordinadorNavegacionComprasSesion.IrAAlbaranes(
  Sender: TObject);
begin
  ShowMto(FEntorno.Propietario, 'AlbaranesCompra');
end;

procedure TCoordinadorNavegacionComprasSesion.IrAPedidos(
  Sender: TObject);
begin
  ShowMto(FEntorno.Propietario, 'PedidosCompra');
end;

procedure TCoordinadorNavegacionComprasSesion.IrAProveedor(
  Sender: TObject);
begin
  ShowMtoCodigoDataSet(
    FEntorno.Propietario,
    'Proveedores',
    FEntorno.Cabecera,
    'CODIGO_PRV_SES');
end;

procedure TCoordinadorNavegacionComprasSesion.InicializarSeries(
  Sender: TObject);
var
  Empresa: string;
begin
  Empresa := '';
  if FEntorno.Cabecera.Active then
  begin
    Empresa := Trim(
      FEntorno.Cabecera.FieldByName('CODIGO_EMP_SES').AsString);
  end;
  if Empresa = '' then
    Empresa := Trim(FEntorno.EmpresaDefecto);
  FEntorno.CargarSeries(
    Empresa,
    FEntorno.ComboSerie.Properties.Items);
  if FEntorno.ComboSerie.Properties.Items.Count = 0 then
  begin
    if MessageDlg_fza(
      Format(SPreguntaAbrirSeriesSesionCompra, [Empresa]),
      mtConfirmation,
      [mbYes, mbNo],
      0) = mrYes then
    begin
      ShowMto(FEntorno.Propietario, 'Empresas');
    end;
  end;
end;

end.
