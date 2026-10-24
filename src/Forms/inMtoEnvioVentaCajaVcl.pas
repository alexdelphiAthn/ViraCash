{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoEnvioVentaCajaVcl                                        }
{    Tipo:       Presentación VCL                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       22/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Vuelca las líneas de un documento (SKU y cantidad) en una venta de caja   }
{    abierta: elige la caja, reutiliza una venta vacía o crea otra y carga    }
{    cada SKU como si se hubiera leído. Lo usan los documentos de trabajo y   }
{    los presupuestos.                                                         }
{******************************************************************************}
unit inMtoEnvioVentaCajaVcl;

interface

uses
  inMtoFrmBase,
  inLibCajasDefectoPersistenciaIntf,
  inLibCajaVentanasIntf;

type
  TResultadoEnvioVentaCaja = record
    LineasVolcadas: Integer;
    LineasNoVolcadas: Integer;
  end;

// Caja de destino: la de la sesión o, si el parámetro lo pide, la elegida
// en el selector. False si se cancela o queda incompleta (ya avisado).
function SeleccionarUbicacionVentaCaja(
  AFormulario: TfrmBase;
  const ACajasDefecto: IRepositorioCajasDefecto;
  out AEmpresa, AAlmacen, ACaja: string): Boolean;

// Abre (o reutiliza) una venta de caja y le vuelca las líneas. La venta
// queda en pantalla sin grabar: el usuario la cobra o la cancela. False si
// no se llegó a abrir la venta.
function EnviarLineasVentaCaja(
  AFormulario: TfrmBase;
  const ACajasDefecto: IRepositorioCajasDefecto;
  const ALineas: TLineasVentaCajaExterna;
  out AResultado: TResultadoEnvioVentaCaja): Boolean;

implementation

uses
  System.SysUtils,
  Vcl.Forms,
  inLibMensajesVcl,
  inLibMsgCaja,
  inMtoModalCajDef;

function SeleccionarUbicacionVentaCaja(
  AFormulario: TfrmBase;
  const ACajasDefecto: IRepositorioCajasDefecto;
  out AEmpresa, AAlmacen, ACaja: string): Boolean;
var
  oSelector: TfrmMtoModalCajDef;
begin
  AEmpresa := AFormulario.UbicacionSesion.Empresa;
  AAlmacen := AFormulario.UbicacionSesion.Almacen;
  ACaja := AFormulario.UbicacionSesion.Caja;
  Result := not AFormulario.ParametrosCaja.GetBool(
    'vgerShowCajaSelection', True);
  if not Result then
  begin
    oSelector := TfrmMtoModalCajDef.Create(AFormulario, ACajasDefecto);
    try
      oSelector.sEmpresa := AEmpresa;
      oSelector.sAlmacen := AAlmacen;
      oSelector.sCaja := ACaja;
      oSelector.ShowModal;
      Result := oSelector.sFicha = 'S';
      if Result then
      begin
        AEmpresa := oSelector.EmpresaSeleccionada;
        AAlmacen := oSelector.AlmacenSeleccionado;
        ACaja := oSelector.CajaSeleccionada;
      end;
    finally
      FreeAndNil(oSelector);
    end;
  end;
  if Result and
     ((AEmpresa = '') or (AAlmacen = '') or (ACaja = '')) then
  begin
    ShowMessage_fza(SErrorAsignarUbicacionCaja);
    Result := False;
  end;
end;

function AbrirVentaCaja(
  AFormulario: TfrmBase;
  const AEmpresa, AAlmacen, ACaja: string): IOperacionCaja;
var
  oAnfitrion: IAnfitrionCajaVentanas;
  oFormularioCaja: TCustomForm;
begin
  Result := BuscarOperacionCajaVacia;
  if Result = nil then
  begin
    oAnfitrion := ExigirAnfitrionCaja(Application.MainForm);
    Result := oAnfitrion.CrearOperacionCaja(
      Application, AFormulario.Permisos);
  end;
  oFormularioCaja := Result.FormularioCaja;
  try
    oFormularioCaja.PopupParent := AFormulario;
    if oFormularioCaja.Tag <= 0 then
      oFormularioCaja.Tag := 1;
    oFormularioCaja.Caption := Format(
      STituloOperacionNCajaReal,
      [oFormularioCaja.Tag, ACaja]);
    Result.PrepararValores(AEmpresa, AAlmacen, ACaja, Now);
    // CargarSkuExterno deja preparada la siguiente linea y le da foco.
    // La venta debe estar visible antes de empezar a volcar los SKU.
    oFormularioCaja.Show;
    if oFormularioCaja.WindowState = wsMinimized then
      oFormularioCaja.WindowState := wsNormal;
    oFormularioCaja.BringToFront;
  except
    FreeAndNil(oFormularioCaja);
    raise;
  end;
end;

function EnviarLineasVentaCaja(
  AFormulario: TfrmBase;
  const ACajasDefecto: IRepositorioCajasDefecto;
  const ALineas: TLineasVentaCajaExterna;
  out AResultado: TResultadoEnvioVentaCaja): Boolean;
var
  oOperacionCaja: IOperacionCaja;
  sEmpresa, sAlmacen, sCaja: string;
  i: Integer;
begin
  AResultado := Default(TResultadoEnvioVentaCaja);
  Result := SeleccionarUbicacionVentaCaja(
    AFormulario, ACajasDefecto, sEmpresa, sAlmacen, sCaja);
  if Result then
  begin
    oOperacionCaja := AbrirVentaCaja(
      AFormulario, sEmpresa, sAlmacen, sCaja);
    for i := 0 to High(ALineas) do
    begin
      // Sin SKU (articulo con variaciones sin elegir) no hay que leer.
      if (Trim(ALineas[i].CodigoSku) <> '') and
         oOperacionCaja.CargarSkuExterno(
           ALineas[i].CodigoSku, ALineas[i].Cantidad) then
        Inc(AResultado.LineasVolcadas)
      else
        Inc(AResultado.LineasNoVolcadas);
    end;
  end;
end;

end.
