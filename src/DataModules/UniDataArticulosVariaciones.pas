{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataArticulosVariaciones                                  }
{    Tipo:       Composición UniDAC                                            }
{ Versión:       2.0.0                                                         }
{   Fecha:       06/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Compone los puertos de SKU y el gestor visual de variaciones.            }
{******************************************************************************}
unit UniDataArticulosVariaciones;

interface

uses
  Uni,
  inLibArticulosVariacionesIntf;

function CrearArticulosVariacionesUniDAC(
  AConexion: TUniConnection): IArticulosVariaciones;

implementation

uses
  System.SysUtils,
  Vcl.Forms,
  UniDataArticulosVariacionesSkuRepositorio,
  UniDataArticulosVariacionesGestor;

type
  TArticulosVariacionesUniDAC = class(
    TInterfacedObject,
    IArticulosVariaciones)
  private
    FConexion: TUniConnection;
    FLecturaSku: ILecturaSkuArticulosVariaciones;
    FEscrituraSku: IEscrituraSkuArticulosVariaciones;
  public
    constructor Create(AConexion: TUniConnection);
    procedure AsegurarSkuSinVariaciones(
      const ACodigoArticulo, AUsuario: string);
    procedure AsegurarSkuActivo(
      const ACodigoArticulo, AUsuario: string);
    function TieneSkuActivo(
      const ACodigoArticulo: string): Boolean;
    function CrearGestor(
      APanelAtributos: TScrollBox;
      const AUsuario: string): IGestorArticulosVariaciones;
  end;

constructor TArticulosVariacionesUniDAC.Create(
  AConexion: TUniConnection);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
  FLecturaSku :=
    CrearLecturaSkuArticulosVariacionesUniDAC(AConexion);
  FEscrituraSku :=
    CrearEscrituraSkuArticulosVariacionesUniDAC(
      AConexion, FLecturaSku);
end;

procedure TArticulosVariacionesUniDAC.AsegurarSkuSinVariaciones(
  const ACodigoArticulo, AUsuario: string);
begin
  FEscrituraSku.AsegurarSkuSinVariaciones(
    ACodigoArticulo, AUsuario);
end;

procedure TArticulosVariacionesUniDAC.AsegurarSkuActivo(
  const ACodigoArticulo, AUsuario: string);
begin
  FEscrituraSku.AsegurarSkuActivo(
    ACodigoArticulo, AUsuario);
end;

function TArticulosVariacionesUniDAC.TieneSkuActivo(
  const ACodigoArticulo: string): Boolean;
begin
  Result := FLecturaSku.TieneSkuActivo(ACodigoArticulo);
end;

function TArticulosVariacionesUniDAC.CrearGestor(
  APanelAtributos: TScrollBox;
  const AUsuario: string): IGestorArticulosVariaciones;
begin
  Result := CrearGestorArticulosVariacionesUniDAC(
    APanelAtributos, FConexion, AUsuario);
end;

function CrearArticulosVariacionesUniDAC(
  AConexion: TUniConnection): IArticulosVariaciones;
begin
  Result := TArticulosVariacionesUniDAC.Create(AConexion);
end;

end.
