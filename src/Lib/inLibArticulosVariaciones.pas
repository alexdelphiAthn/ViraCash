{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArticulosVariaciones                                     }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Fachada sin SQL para variaciones y SKU de artículos.                     }
{******************************************************************************}
unit inLibArticulosVariaciones;

interface

uses
  System.Generics.Collections,
  Vcl.Forms,
  cxDropDownEdit, cxCheckBox,
  inLibArticulosVariacionesIntf;

type
  TAccionAsegurarSku = (
    aasNinguna,
    aasInsertar,
    aasActivar);
  TSlotVariacion = record
    IdAtributo: string;
    NombreAtributo: string;
    OrdenAtributo: Integer;
    IdConjunto: Integer;
    NombreConjunto: string;
    Ctrl: TcxComboBox;
    Opciones: TDictionary<Integer, string>;
  end;
  TSlotSku = record
    CodigoUnidad: string;
    Activo: Boolean;
    ActiveOriginal: Boolean;
    Chk: TcxCheckBox;
  end;
  TGestorVariaciones = class
  private
    FServicio: IGestorArticulosVariaciones;
    function GetCodigoArticulo: string;
    function GetModificado: Boolean;
  public
    constructor Create(
      APanelAtributos: TScrollBox;
      const AArticulosVariaciones: IArticulosVariaciones;
      const AUsuario: string);
    destructor Destroy; override;
    procedure CargarVariaciones(const CodigoArticulo: string);
    procedure MostrarTipoVariacion(
      const CodigoArticulo, TipoVariacion: string);
    procedure AsignarCodigoArticulo(const CodigoArticulo: string);
    function GuardarVariaciones: Boolean;
    function Validar: string;
    procedure ActualizarIdioma;
    property CodigoArticulo: string read GetCodigoArticulo;
    property Modificado: Boolean read GetModificado;
  end;

procedure AsegurarSkuArticuloSinVariaciones(
  const AArticulosVariaciones: IArticulosVariaciones;
  const ACodigoArticulo, AUsuario: string);
procedure AsegurarSkuArticuloActivo(
  const AArticulosVariaciones: IArticulosVariaciones;
  const ACodigoArticulo, AUsuario: string);
function ArticuloTieneSkuActivo(
  const AArticulosVariaciones: IArticulosVariaciones;
  const ACodigoArticulo: string): Boolean;
function ResolverSkuSinVariaciones(
  ACodigoPresente, ATieneVariaciones, ATieneSku: Boolean):
  TAccionAsegurarSku;
function ResolverSkuActivo(
  ACodigoPresente, ATieneActivo, ATieneBase: Boolean):
  TAccionAsegurarSku;

implementation

procedure TGestorVariaciones.ActualizarIdioma;
begin
  if Assigned(FServicio) then
    FServicio.ActualizarIdioma;
end;

constructor TGestorVariaciones.Create(
  APanelAtributos: TScrollBox;
  const AArticulosVariaciones: IArticulosVariaciones;
  const AUsuario: string);
begin
  inherited Create;
  FServicio := AArticulosVariaciones.CrearGestor(
    APanelAtributos, AUsuario);
end;

destructor TGestorVariaciones.Destroy;
begin
  FServicio := nil;
  inherited;
end;

procedure TGestorVariaciones.CargarVariaciones(
  const CodigoArticulo: string);
begin
  FServicio.CargarVariaciones(CodigoArticulo);
end;

procedure TGestorVariaciones.MostrarTipoVariacion(
  const CodigoArticulo, TipoVariacion: string);
begin
  FServicio.MostrarTipoVariacion(CodigoArticulo, TipoVariacion);
end;

procedure TGestorVariaciones.AsignarCodigoArticulo(
  const CodigoArticulo: string);
begin
  FServicio.AsignarCodigoArticulo(CodigoArticulo);
end;

function TGestorVariaciones.GuardarVariaciones: Boolean;
begin
  Result := FServicio.GuardarVariaciones;
end;

function TGestorVariaciones.Validar: string;
begin
  Result := FServicio.Validar;
end;

function TGestorVariaciones.GetCodigoArticulo: string;
begin
  Result := FServicio.ObtenerCodigoArticulo;
end;

function TGestorVariaciones.GetModificado: Boolean;
begin
  Result := FServicio.EstaModificado;
end;

procedure AsegurarSkuArticuloSinVariaciones(
  const AArticulosVariaciones: IArticulosVariaciones;
  const ACodigoArticulo, AUsuario: string);
begin
  AArticulosVariaciones.AsegurarSkuSinVariaciones(
    ACodigoArticulo, AUsuario);
end;

procedure AsegurarSkuArticuloActivo(
  const AArticulosVariaciones: IArticulosVariaciones;
  const ACodigoArticulo, AUsuario: string);
begin
  AArticulosVariaciones.AsegurarSkuActivo(
    ACodigoArticulo, AUsuario);
end;

function ArticuloTieneSkuActivo(
  const AArticulosVariaciones: IArticulosVariaciones;
  const ACodigoArticulo: string): Boolean;
begin
  Result := AArticulosVariaciones.TieneSkuActivo(
    ACodigoArticulo);
end;

function ResolverSkuSinVariaciones(
  ACodigoPresente, ATieneVariaciones, ATieneSku: Boolean):
  TAccionAsegurarSku;
begin
  Result := aasNinguna;
  if ACodigoPresente and
     (not ATieneVariaciones) and
     (not ATieneSku) then
    Result := aasInsertar;
end;

function ResolverSkuActivo(
  ACodigoPresente, ATieneActivo, ATieneBase: Boolean):
  TAccionAsegurarSku;
begin
  Result := aasNinguna;
  if ACodigoPresente and (not ATieneActivo) then
    if ATieneBase then
      Result := aasActivar
    else
      Result := aasInsertar;
end;

end.
