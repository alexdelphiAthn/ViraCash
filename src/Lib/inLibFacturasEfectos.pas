{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasEfectos                                          }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Gestiona la persistencia de efectos y recibos de facturas de venta.       }
{    La persistencia entra por IRepositorioEfectosFactura.                     }
{******************************************************************************}
unit inLibFacturasEfectos;

interface

uses
  inLibFacturasServiciosIntf, inLibFacturasPersistenciaIntf;

type
  TServicioEfectosFactura = class(
    TInterfacedObject,
    IServicioEfectosFactura)
  private
    FRepositorio: IRepositorioEfectosFactura;
  public
    constructor Create(
      const ARepositorio: IRepositorioEfectosFactura);
    procedure EstamparBancoRecibos(
      const ASerie, ANumero, ACodigoBanco, AIban: string);
    function BancoDefectoCliente(
      const ACodigoCliente: string): string;
    function Generar(
      const ASerie, ANumero, AUsuario,
      ACodigoBanco, AIban: string): Integer;
    function RegistrarCobro(
      const ASerie, ANumero, AUsuario: string;
      ANumeroEfecto: Integer;
      AFecha: TDateTime;
      AImporte: Double;
      const ATipo, AReferencia: string): Integer;
    function CambiarEstado(
      const ASerie, ANumero, AUsuario: string;
      ANumeroEfecto: Integer;
      const AEstado: string): Boolean;
  end;

implementation

uses
  System.SysUtils;

constructor TServicioEfectosFactura.Create(
  const ARepositorio: IRepositorioEfectosFactura);
begin
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('ARepositorio');
  inherited Create;
  FRepositorio := ARepositorio;
end;

procedure TServicioEfectosFactura.EstamparBancoRecibos(
  const ASerie, ANumero, ACodigoBanco, AIban: string);
begin
  FRepositorio.EstamparBancoRecibos(ASerie, ANumero, ACodigoBanco,
    AIban);
end;

function TServicioEfectosFactura.BancoDefectoCliente(
  const ACodigoCliente: string): string;
begin
  Result := '';
  if (ACodigoCliente <> '') and
     (ACodigoCliente <> '0') then
  begin
    Result := FRepositorio.BancoDefectoCliente(ACodigoCliente);
  end;
end;

function TServicioEfectosFactura.Generar(
  const ASerie, ANumero, AUsuario,
  ACodigoBanco, AIban: string): Integer;
begin
  Result := FRepositorio.GenerarDesdeFactura(ASerie, ANumero, AUsuario,
    ACodigoBanco, AIban);
end;

function TServicioEfectosFactura.RegistrarCobro(
  const ASerie, ANumero, AUsuario: string;
  ANumeroEfecto: Integer;
  AFecha: TDateTime;
  AImporte: Double;
  const ATipo, AReferencia: string): Integer;
begin
  Result := FRepositorio.RegistrarCobro(ASerie, ANumero, AUsuario,
    ANumeroEfecto, AFecha, AImporte, ATipo, AReferencia);
end;

function TServicioEfectosFactura.CambiarEstado(
  const ASerie, ANumero, AUsuario: string;
  ANumeroEfecto: Integer;
  const AEstado: string): Boolean;
begin
  // La normalización del estado es regla de dominio.
  Result := FRepositorio.CambiarEstado(ASerie, ANumero, AUsuario,
    ANumeroEfecto, UpperCase(Trim(AEstado)));
end;

end.
