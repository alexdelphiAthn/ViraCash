{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCajaOpePresentacionVcl                                   }
{    Tipo:       Adaptador VCL                                                 }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Traduce la rejilla de líneas de caja y las operaciones de artículo a     }
{    los puertos de inLibCajaOpePresentacionIntf. Recibe la vista, sus        }
{    columnas y callbacks concretos; nunca el formulario completo.            }
{******************************************************************************}
unit inMtoCajaOpePresentacionVcl;

interface

uses
  Winapi.Windows, System.Classes, Vcl.ExtCtrls,
  cxEdit, cxGridCustomTableView, cxGridTableView,
  inLibCajaOpePresentacionIntf;

type
  TColumnaAtributoCajaVcl = reference to function(
    AOrden: Integer): TcxGridColumn;
  TConsultaTextoCajaVcl = reference to function: string;
  TConsultaBooleanaCajaVcl = reference to function: Boolean;
  TConsultaCodigoCajaVcl = reference to function(
    const ACodigo: string): Boolean;
  TConsultaAtributosCajaVcl = reference to function(
    const ACodigo: string): Integer;
  TAccionCodigoCajaVcl = reference to procedure(
    const ACodigo: string);
  TAccionCajaVcl = reference to procedure;
  TOperacionesArticuloLineaCajaVcl = record
    BuscarArticulo: TConsultaTextoCajaVcl;
    CargarArticulo: TConsultaCodigoCajaVcl;
    MotivoRechazo: TConsultaTextoCajaVcl;
    ArticuloResuelto: TConsultaTextoCajaVcl;
    OlvidarArticuloResuelto: TAccionCajaVcl;
    PrepararColumnasAtributos: TConsultaAtributosCajaVcl;
    SkuVendible: TConsultaCodigoCajaVcl;
    VolcarAtributosDeSku: TAccionCodigoCajaVcl;
    AvanzarDeLinea: TConsultaBooleanaCajaVcl;
    Avisar: TAccionCodigoCajaVcl;
  end;
  // Puerto de rejilla. El editor en curso lo entrega el propio evento de
  // teclado, por eso se refresca con FijarEdicion antes de cada pasada.
  TRejillaLineaCajaVcl = class(
    TInterfacedObject,
    IRejillaLineaCaja)
  private
    FVista: TcxGridTableView;
    FColumnaArticulo: TcxGridColumn;
    FColumnaDescripcion: TcxGridColumn;
    FTemporizadorBusqueda: TTimer;
    FColumnaAtributo: TColumnaAtributoCajaVcl;
    FItem: TcxCustomGridTableItem;
    FEditor: TcxCustomEdit;
    function ColumnaDestino(
      ADestino: TDestinoFocoLineaCaja): TcxGridColumn;
  public
    constructor Create(
      AVista: TcxGridTableView;
      AColumnaArticulo, AColumnaDescripcion: TcxGridColumn;
      ATemporizadorBusqueda: TTimer;
      const AColumnaAtributo: TColumnaAtributoCajaVcl);
    procedure FijarEdicion(
      AItem: TcxCustomGridTableItem;
      AEditor: TcxCustomEdit);
    function RolColumnaActiva: TRolColumnaLineaCaja;
    function TextoEditor: string;
    procedure EscribirEditor(const AValor: string);
    procedure CerrarDesplegable;
    procedure PublicarValorEditor;
    procedure ReactivarBusquedaIncremental;
    procedure DetenerBusquedaIncremental;
    function EnfocarYEditar(
      ADestino: TDestinoFocoLineaCaja): Boolean;
  end;

// Traduce el código de tecla de Windows al vocabulario del núcleo.
function TraducirTeclaLineaCaja(AKey: Word): TTeclaOperacionCaja;

procedure CrearPuertosArticuloLineaCajaVcl(
  const AOperaciones: TOperacionesArticuloLineaCajaVcl;
  out APuertoArticulo: IArticuloLineaCaja;
  out AAvisos: IAvisosOperacionCaja);

implementation

uses
  System.SysUtils, System.Variants,
  cxTextEdit, cxDropDownEdit;

type
  TArticuloLineaCajaVcl = class(
    TInterfacedObject,
    IArticuloLineaCaja,
    IAvisosOperacionCaja)
  private
    FOperaciones: TOperacionesArticuloLineaCajaVcl;
  public
    constructor Create(
      const AOperaciones: TOperacionesArticuloLineaCajaVcl);
    function BuscarArticulo: string;
    function CargarArticulo(const ACodigo: string): Boolean;
    function MotivoRechazo: string;
    function ArticuloResuelto: string;
    procedure OlvidarArticuloResuelto;
    function PrepararColumnasAtributos(
      const AArticulo: string): Integer;
    function SkuVendible(const ACodigoSku: string): Boolean;
    procedure VolcarAtributosDeSku(const ACodigoSku: string);
    function AvanzarDeLinea: Boolean;
    procedure Avisar(const AMensaje: string);
  end;

function TraducirTeclaLineaCaja(AKey: Word): TTeclaOperacionCaja;
begin
  if AKey = VK_RETURN then
    Result := tocIntro
  else if AKey = VK_UP then
    Result := tocArriba
  else if AKey in [VK_ESCAPE, VK_DOWN, VK_TAB, VK_LEFT, VK_RIGHT] then
    Result := tocNavegacion
  else if (AKey >= VK_F1) and (AKey <= VK_F12) then
    Result := tocNavegacion
  else
    Result := tocOtra;
end;

constructor TRejillaLineaCajaVcl.Create(
  AVista: TcxGridTableView;
  AColumnaArticulo, AColumnaDescripcion: TcxGridColumn;
  ATemporizadorBusqueda: TTimer;
  const AColumnaAtributo: TColumnaAtributoCajaVcl);
begin
  if not Assigned(AVista) then
    raise EArgumentNilException.Create('AVista');
  inherited Create;
  FVista := AVista;
  FColumnaArticulo := AColumnaArticulo;
  FColumnaDescripcion := AColumnaDescripcion;
  FTemporizadorBusqueda := ATemporizadorBusqueda;
  FColumnaAtributo := AColumnaAtributo;
end;

procedure TRejillaLineaCajaVcl.FijarEdicion(
  AItem: TcxCustomGridTableItem;
  AEditor: TcxCustomEdit);
begin
  FItem := AItem;
  FEditor := AEditor;
end;

function TRejillaLineaCajaVcl.RolColumnaActiva: TRolColumnaLineaCaja;
begin
  if (FItem <> nil) and (FItem = FColumnaArticulo) then
    Result := rclArticulo
  else
    Result := rclOtra;
end;

function TRejillaLineaCajaVcl.TextoEditor: string;
begin
  Result := '';
  if FEditor is TcxCustomTextEdit then
    Result := Trim(TcxCustomTextEdit(FEditor).Text)
  else if FEditor <> nil then
    Result := Trim(VarToStr(FEditor.EditValue));
end;

procedure TRejillaLineaCajaVcl.EscribirEditor(const AValor: string);
begin
  if FEditor <> nil then
    FEditor.EditValue := AValor;
end;

procedure TRejillaLineaCajaVcl.CerrarDesplegable;
begin
  if (FEditor is TcxCustomDropDownEdit) and
     TcxCustomDropDownEdit(FEditor).DroppedDown then
    TcxCustomDropDownEdit(FEditor).DroppedDown := False;
end;

procedure TRejillaLineaCajaVcl.PublicarValorEditor;
begin
  if FEditor <> nil then
    FEditor.PostEditValue;
end;

procedure TRejillaLineaCajaVcl.ReactivarBusquedaIncremental;
begin
  if FTemporizadorBusqueda <> nil then
  begin
    FTemporizadorBusqueda.Enabled := False;
    FTemporizadorBusqueda.Enabled := True;
  end;
end;

procedure TRejillaLineaCajaVcl.DetenerBusquedaIncremental;
begin
  if FTemporizadorBusqueda <> nil then
    FTemporizadorBusqueda.Enabled := False;
end;

function TRejillaLineaCajaVcl.ColumnaDestino(
  ADestino: TDestinoFocoLineaCaja): TcxGridColumn;
begin
  Result := nil;
  if ADestino = dflArticulo then
    Result := FColumnaArticulo
  else if ADestino = dflDescripcion then
    Result := FColumnaDescripcion
  else if Assigned(FColumnaAtributo) then
    Result := FColumnaAtributo(1);
end;

function TRejillaLineaCajaVcl.EnfocarYEditar(
  ADestino: TDestinoFocoLineaCaja): Boolean;
var
  Columna: TcxGridColumn;
begin
  Columna := ColumnaDestino(ADestino);
  Result := Columna <> nil;
  if Result then
  begin
    if ADestino = dflPrimerAtributo then
      Columna.Visible := True;
    FVista.Controller.FocusedColumn := Columna;
    FVista.Controller.EditingController.ShowEdit;
  end;
end;

constructor TArticuloLineaCajaVcl.Create(
  const AOperaciones: TOperacionesArticuloLineaCajaVcl);
begin
  inherited Create;
  FOperaciones := AOperaciones;
end;

function TArticuloLineaCajaVcl.BuscarArticulo: string;
begin
  Result := '';
  if Assigned(FOperaciones.BuscarArticulo) then
    Result := FOperaciones.BuscarArticulo();
end;

function TArticuloLineaCajaVcl.CargarArticulo(
  const ACodigo: string): Boolean;
begin
  Result := Assigned(FOperaciones.CargarArticulo) and
    FOperaciones.CargarArticulo(ACodigo);
end;

function TArticuloLineaCajaVcl.MotivoRechazo: string;
begin
  Result := '';
  if Assigned(FOperaciones.MotivoRechazo) then
    Result := FOperaciones.MotivoRechazo();
end;

function TArticuloLineaCajaVcl.ArticuloResuelto: string;
begin
  Result := '';
  if Assigned(FOperaciones.ArticuloResuelto) then
    Result := FOperaciones.ArticuloResuelto();
end;

procedure TArticuloLineaCajaVcl.OlvidarArticuloResuelto;
begin
  if Assigned(FOperaciones.OlvidarArticuloResuelto) then
    FOperaciones.OlvidarArticuloResuelto();
end;

function TArticuloLineaCajaVcl.PrepararColumnasAtributos(
  const AArticulo: string): Integer;
begin
  Result := 0;
  if Assigned(FOperaciones.PrepararColumnasAtributos) then
    Result := FOperaciones.PrepararColumnasAtributos(AArticulo);
end;

function TArticuloLineaCajaVcl.SkuVendible(
  const ACodigoSku: string): Boolean;
begin
  Result := Assigned(FOperaciones.SkuVendible) and
    FOperaciones.SkuVendible(ACodigoSku);
end;

procedure TArticuloLineaCajaVcl.VolcarAtributosDeSku(
  const ACodigoSku: string);
begin
  if Assigned(FOperaciones.VolcarAtributosDeSku) then
    FOperaciones.VolcarAtributosDeSku(ACodigoSku);
end;

function TArticuloLineaCajaVcl.AvanzarDeLinea: Boolean;
begin
  Result := Assigned(FOperaciones.AvanzarDeLinea) and
    FOperaciones.AvanzarDeLinea();
end;

procedure TArticuloLineaCajaVcl.Avisar(const AMensaje: string);
begin
  if Assigned(FOperaciones.Avisar) then
    FOperaciones.Avisar(AMensaje);
end;

procedure CrearPuertosArticuloLineaCajaVcl(
  const AOperaciones: TOperacionesArticuloLineaCajaVcl;
  out APuertoArticulo: IArticuloLineaCaja;
  out AAvisos: IAvisosOperacionCaja);
var
  Adaptador: TArticuloLineaCajaVcl;
begin
  Adaptador := TArticuloLineaCajaVcl.Create(AOperaciones);
  APuertoArticulo := Adaptador;
  AAvisos := Adaptador;
end;

end.
