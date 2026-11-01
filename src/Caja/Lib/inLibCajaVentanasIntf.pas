{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaVentanasIntf                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos y fábricas de las ventanas de operación y consulta de caja.     }
{******************************************************************************}
unit inLibCajaVentanasIntf;

interface

uses
  Winapi.Messages, System.Classes, Vcl.Forms, inLibCajaTipos, inLibPermisosIntf,
  inLibCajaSubsanacionIntf;

const
  WM_RESTAURAR_MENU_CAJA = WM_APP + 108;

type
  TModoVentanaTraspaso = (
    mvtTraspaso,
    mvtPeticion
  );
  TAtributosCargaTraspaso = array[1..5] of string;
  TLineaCargaTraspaso = record
    CodigoArticulo: string;
    CodigoSku: string;
    Descripcion: string;
    Cantidad: Double;
    NumeroAtributos: Integer;
    ValoresAtributos: TAtributosCargaTraspaso;
    NombresAtributos: TAtributosCargaTraspaso;
    // FZ-ISSUE-351: lote o serie de la línea (vacío = sin lote) y su
    // caducidad (0 = sin caducidad). Solo se agrupan líneas del mismo lote.
    Lote: string;
    FechaCaducidad: TDateTime;
  end;
  TLineasCargaTraspaso = TArray<TLineaCargaTraspaso>;
  // Linea que otro documento vuelca en una venta de caja: SKU y cantidad.
  // El precio lo pone la caja con su tarifa, como en una lectura.
  TLineaVentaCajaExterna = record
    CodigoSku: string;
    Cantidad: Double;
    Lote: string;
    FechaCaducidad: TDateTime;
  end;
  TLineasVentaCajaExterna = TArray<TLineaVentaCajaExterna>;

  IReceptorPresupuestoCaja = interface
    ['{2B58A4B2-88CE-493A-A18E-CF4681BCC0AE}']
    procedure ActualizarPresupuestoCaja(const AEmpresa, ASerie,
      ANumero: string);
  end;

  IOperacionCaja = interface
    ['{3C44C353-D264-4F82-8245-6F25AE19E4A0}']
    function FormularioCaja: TCustomForm;
    function IntentarCerrar: Boolean;
    function OperacionVacia: Boolean;
    function CargarSkuExterno(
      const ASku: string;
      ACant: Double; const ALote: string = '';
      ACaducidad: TDateTime = 0): Boolean;
    // Antes de volcar líneas externas: el cliente del documento y, si la
    // venta no tiene empleado, se pide una vez (FZ-ISSUE-785).
    procedure PrepararVentaExterna(const ACliente: string);
    procedure AsignarPresupuesto(const AEmpresa, ASerie, ANumero: string);
    procedure PrepararValores(
      const AEmpresa, AAlmacen, ACaja: string;
      AFecha: TDateTime);
    procedure CargarDevolucion(
      const ASerie, ANumero, AEmpresaOrigen,
      AAlmacenOrigen: string);
    procedure CargarSubsanacion(
      const AOperacion: TOperacionSubsanacionCaja;
      const AServicio: IServicioSubsanacionCaja);
    procedure CargarRectificacion(
      const ASerie, ANumero: string;
      ATipoRectificativa: TTipoRectificativaCaja;
      ATratamientoMovimientos:
        TTratamientoMovimientosRectificativa);
  end;

  IConsultaOperacionesCaja = interface
    ['{50D890C9-5772-47A0-9B53-530748886CBB}']
    function FormularioConsultaCaja: TCustomForm;
    procedure PrepararValores(
      const AEmpresa, AAlmacen, ACaja: string;
      AFecha: TDateTime);
    procedure RefrescarOperaciones;
  end;

  IReceptorFechaCaja = interface
    ['{31EB4CB2-7A61-4322-93D6-14A956327846}']
    procedure ActualizarFechaCaja(AFechaCaja: TDateTime);
    function FechaOperacionCaja(const AEmpresa, AAlmacen,
      ACaja: string): TDateTime;
  end;

  ITraspasoCaja = interface
    ['{8A0F8522-BC04-4D3B-AEA3-BC712D8BAF31}']
    function FormularioTraspaso: TCustomForm;
    procedure PrepararCargaExterna(
      AModo: TModoVentanaTraspaso;
      const AEmpresa, AAlmacen, ACaja: string;
      AFecha: TDateTime;
      const ALineas: TLineasCargaTraspaso);
  end;

  IAnfitrionCajaVentanas = interface
    ['{123C0301-B259-4C2C-842D-9BF3AE6C223C}']
    function CrearOperacionCaja(
      AOwner: TComponent;
      const APermisos: IPermisosAplicacion): IOperacionCaja;
    function CrearConsultaOperacionesCaja(
      AOwner: TComponent;
      const APermisos: IPermisosAplicacion): IConsultaOperacionesCaja;
    function CrearTraspasoCaja(
      AOwner: TComponent;
      const APermisos: IPermisosAplicacion): ITraspasoCaja;
  end;

function ExigirAnfitrionCaja(
  AObjeto: TObject): IAnfitrionCajaVentanas;
function BuscarOperacionCajaVacia: IOperacionCaja;
function BuscarOperacionCajaVisible: IOperacionCaja;
procedure ReactivarOperacionCajaVisible;
function PuedenCerrarOperacionesCaja: Boolean;
procedure LiberarOperacionesCaja;
procedure RefrescarConsultasOperacionesCaja;
procedure NotificarFechaCaja(AFecha: TDateTime);
function BuscarFechaOperacionCaja(const AEmpresa, AAlmacen,
  ACaja: string): TDateTime;
procedure NotificarPresupuestoCaja(const AEmpresa, ASerie,
  ANumero: string);

implementation

uses
  Winapi.Windows,
  System.SysUtils;

resourcestring
  SErrorAnfitrionCajaNoDisponible =
    'La aplicación no proporciona el servicio de ventanas de caja.';

function ExigirAnfitrionCaja(
  AObjeto: TObject): IAnfitrionCajaVentanas;
begin
  if not Supports(AObjeto, IAnfitrionCajaVentanas, Result) then
    raise EInvalidOpException.Create(
      SErrorAnfitrionCajaNoDisponible);
end;

function BuscarOperacionCajaVacia: IOperacionCaja;
var
  i: Integer;
  oOperacion: IOperacionCaja;
begin
  Result := nil;
  for i := 0 to Screen.FormCount - 1 do
  begin
    if (Result = nil) and
       Supports(Screen.Forms[i], IOperacionCaja, oOperacion) and
       oOperacion.OperacionVacia then
      Result := oOperacion;
  end;
end;

function BuscarOperacionCajaVisible: IOperacionCaja;
var
  i: Integer;
  oOperacion: IOperacionCaja;
begin
  Result := nil;
  for i := 0 to Screen.FormCount - 1 do
  begin
    if (Result = nil) and
       Supports(Screen.Forms[i], IOperacionCaja, oOperacion) and
       oOperacion.FormularioCaja.Visible then
      Result := oOperacion;
  end;
end;

procedure ReactivarOperacionCajaVisible;
var
  Formulario: TCustomForm;
  Operacion: IOperacionCaja;
begin
  Operacion := BuscarOperacionCajaVisible;
  if Operacion <> nil then
  begin
    Formulario := Operacion.FormularioCaja;
    if Assigned(Formulario) and
       not (csDestroying in Formulario.ComponentState) then
    begin
      if Formulario.WindowState = wsMinimized then
        Formulario.WindowState := wsNormal;
      Formulario.Show;
      SetWindowPos(
        Formulario.Handle,
        HWND_TOP,
        0,
        0,
        0,
        0,
        SWP_NOMOVE or SWP_NOSIZE or SWP_SHOWWINDOW);
      SetForegroundWindow(Formulario.Handle);
    end;
  end;
end;

function PuedenCerrarOperacionesCaja: Boolean;
var
  i: Integer;
  oOperacion: IOperacionCaja;
begin
  Result := True;
  i := Screen.FormCount - 1;
  while (i >= 0) and Result do
  begin
    if Supports(Screen.Forms[i], IOperacionCaja, oOperacion) and
       not oOperacion.IntentarCerrar then
      Result := False;
    Dec(i);
  end;
end;

procedure LiberarOperacionesCaja;
var
  i: Integer;
  oFormulario: TCustomForm;
  oOperacion: IOperacionCaja;
begin
  i := Screen.FormCount - 1;
  while i >= 0 do
  begin
    oFormulario := nil;
    if Supports(Screen.Forms[i], IOperacionCaja, oOperacion) then
      oFormulario := oOperacion.FormularioCaja;
    oOperacion := nil;
    if Assigned(oFormulario) then
      FreeAndNil(oFormulario);
    Dec(i);
  end;
end;

procedure RefrescarConsultasOperacionesCaja;
var
  i: Integer;
  oConsulta: IConsultaOperacionesCaja;
begin
  for i := 0 to Screen.FormCount - 1 do
  begin
    if Supports(
         Screen.Forms[i],
         IConsultaOperacionesCaja,
         oConsulta) then
      oConsulta.RefrescarOperaciones;
  end;
end;

function BuscarFechaOperacionCaja(const AEmpresa, AAlmacen,
  ACaja: string): TDateTime;
var
  i: Integer;
  Receptor: IReceptorFechaCaja;
  Fecha: TDateTime;
begin
  Result := 0;
  for i := 0 to Screen.FormCount - 1 do
    if Supports(Screen.Forms[i], IReceptorFechaCaja, Receptor) then
    begin
      Fecha := Receptor.FechaOperacionCaja(AEmpresa, AAlmacen, ACaja);
      if Fecha > 0 then
        Result := Fecha;
    end;
  if Result = 0 then
    Result := Now;
end;

procedure NotificarPresupuestoCaja(const AEmpresa, ASerie,
  ANumero: string);
var
  i: Integer;
  Receptor: IReceptorPresupuestoCaja;
begin
  for i := 0 to Screen.FormCount - 1 do
    if Supports(Screen.Forms[i], IReceptorPresupuestoCaja, Receptor) then
      Receptor.ActualizarPresupuestoCaja(AEmpresa, ASerie, ANumero);
end;

procedure NotificarFechaCaja(AFecha: TDateTime);
var
  i: Integer;
  oReceptor: IReceptorFechaCaja;
begin
  for i := 0 to Screen.FormCount - 1 do
  begin
    if Supports(Screen.Forms[i], IReceptorFechaCaja, oReceptor) then
      oReceptor.ActualizarFechaCaja(AFecha);
  end;
end;

end.
