{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasBorrado                                          }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Valida y ejecuta el borrado transaccional de una factura de venta.        }
{    La persistencia entra por IRepositorioBorradoFactura.                     }
{******************************************************************************}
unit inLibFacturasBorrado;

interface

uses
  Uni, inLibFacturasServiciosIntf, inLibFacturasPersistenciaIntf,
  inLibVerifactuColaIntf;

type
  TServicioBorradoFactura = class(
    TInterfacedObject,
    IServicioBorradoFactura)
  private
    FConexion: TUniConnection;
    FRepositorio: IRepositorioBorradoFactura;
    FServicioVerifactuCola: IServicioVerifactuCola;
    FTransaccionPropia: Boolean;
    procedure BorrarMovimientos(
      const ASerie, ANumero: string);
  public
    constructor Create(
      AConexion: TUniConnection;
      const ARepositorio: IRepositorioBorradoFactura;
      const AServicioVerifactuCola: IServicioVerifactuCola);
    destructor Destroy; override;
    function Validar(
      const ASerie, ANumero, AFase: string
    ): TResultadoBorradoFactura;
    function Preparar(
      const ASerie, ANumero, AFase: string;
      const AUsuario: string = ''
    ): TResultadoBorradoFactura;
    procedure Confirmar;
    procedure Revertir;
  end;

implementation

uses
  System.SysUtils, inLibVerifactuCola;

constructor TServicioBorradoFactura.Create(
  AConexion: TUniConnection;
  const ARepositorio: IRepositorioBorradoFactura;
  const AServicioVerifactuCola: IServicioVerifactuCola);
begin
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('ARepositorio');
  if not Assigned(AServicioVerifactuCola) then
    raise EArgumentNilException.Create('AServicioVerifactuCola');
  inherited Create;
  FConexion := AConexion;
  FRepositorio := ARepositorio;
  FServicioVerifactuCola := AServicioVerifactuCola;
  FTransaccionPropia := False;
end;

destructor TServicioBorradoFactura.Destroy;
begin
  Revertir;
  inherited;
end;

function TServicioBorradoFactura.Validar(
  const ASerie, ANumero, AFase: string
): TResultadoBorradoFactura;
var
  bTieneEfectosCobrados: Boolean;
begin
  bTieneEfectosCobrados := False;
  if (Trim(AFase) = '') or SameText(AFase, 'BORRADOR') then
  begin
    bTieneEfectosCobrados :=
      FRepositorio.TieneEfectosCobrados(ASerie, ANumero);
  end;
  Result := EvaluarBorradoFactura(
    AFase,
    bTieneEfectosCobrados);
end;

procedure TServicioBorradoFactura.BorrarMovimientos(
  const ASerie, ANumero: string);
begin
  TVerifactuCola.BorrarMovimientosFactura(
    FServicioVerifactuCola,
    ASerie,
    ANumero);
end;

function TServicioBorradoFactura.Preparar(
  const ASerie, ANumero, AFase: string;
  const AUsuario: string
): TResultadoBorradoFactura;
begin
  FTransaccionPropia := not FConexion.InTransaction;
  if FTransaccionPropia then
    FConexion.StartTransaction;
  try
    Result := Validar(ASerie, ANumero, AFase);
    if Result.Permitido then
    begin
      FRepositorio.DesvincularAlbaranes(ASerie, ANumero, AUsuario);
      FRepositorio.BorrarEfectos(ASerie, ANumero);
      FRepositorio.BorrarLineas(ASerie, ANumero);
      FRepositorio.BorrarRecibos(ASerie, ANumero);
      BorrarMovimientos(ASerie, ANumero);
      // Un borrador rectificativo deja de apuntar a su original: se
      // retira la relación y la original recupera su fase si procede.
      FServicioVerifactuCola.DesvincularRectificativa(
        AUsuario, ASerie, ANumero);
    end
    else
    begin
      Revertir;
    end;
  except
    Revertir;
    raise;
  end;
end;

procedure TServicioBorradoFactura.Confirmar;
begin
  if FTransaccionPropia then
  begin
    FConexion.Commit;
    FTransaccionPropia := False;
  end;
end;

procedure TServicioBorradoFactura.Revertir;
begin
  if FTransaccionPropia then
  begin
    if Assigned(FConexion) and FConexion.InTransaction then
      FConexion.Rollback;
    FTransaccionPropia := False;
  end;
end;

end.
