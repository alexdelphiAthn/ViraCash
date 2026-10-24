{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaStock                                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Consulta y aplica la política de disponibilidad para ventas de caja.      }
{******************************************************************************}
unit inLibCajaStock;

interface

uses
  inLibParametrosIntf, inLibCajaVentaIntf,
  inLibCajaStockPersistenciaIntf;

type
  TPoliticaStockVenta = class(TInterfacedObject, IPoliticaStockVenta)
  private
    FPersistencia: ICajaStockPersistencia;
    FParametrosCaja: IParametrosCaja;
    procedure CompletarMensaje(
      const ACodigoSku, AMensajeStock: string;
      var AResultado: TResultadoPoliticaStockVenta);
  public
    constructor Create(
      const APersistencia: ICajaStockPersistencia;
      const AParametrosCaja: IParametrosCaja);
    function Validar(
      const ACodigoSku, ACodigoAlmacen: string
    ): TResultadoPoliticaStockVenta;
    function ValidarCantidad(
      const ACodigoSku, ACodigoAlmacen: string;
      ACantidad: Double): TResultadoPoliticaStockVenta;
  end;

implementation

uses
  System.SysUtils, inLibMsgCaja, inLibMsgArticulos;

constructor TPoliticaStockVenta.Create(
  const APersistencia: ICajaStockPersistencia;
  const AParametrosCaja: IParametrosCaja);
begin
  inherited Create;
  if not Assigned(APersistencia) then
    raise EArgumentNilException.Create('APersistencia');
  FPersistencia := APersistencia;
  FParametrosCaja := AParametrosCaja;
end;

procedure TPoliticaStockVenta.CompletarMensaje(
  const ACodigoSku, AMensajeStock: string;
  var AResultado: TResultadoPoliticaStockVenta);
begin
  case AResultado.Motivo of
    msvSkuNoExiste:
      AResultado.Mensaje := Format(
        SErrorSkuVentaCajaNoExiste,
        [ACodigoSku]);
    msvSkuInactivo:
      AResultado.Mensaje := Format(
        SErrorSkuVentaCajaNoActivo,
        [ACodigoSku]);
    msvSinStock:
      begin
        AResultado.Mensaje := AMensajeStock;
        if AResultado.Mensaje = '' then
        begin
          AResultado.Mensaje := SErrorArticuloVentaCajaSinStock;
        end;
      end;
  end;
end;

function TPoliticaStockVenta.Validar(
  const ACodigoSku, ACodigoAlmacen: string
): TResultadoPoliticaStockVenta;
var
  Entrada: TEntradaPoliticaStockVenta;
  EstadoSku: TEstadoSkuCajaStock;
  sCodigoSku: string;
  sMensajeStock: string;
begin
  Entrada := Default(TEntradaPoliticaStockVenta);
  Entrada.Existe := True;
  Entrada.Activo := True;
  sCodigoSku := Trim(ACodigoSku);
  if sCodigoSku <> '' then
  begin
    Entrada.VerificarExistencia :=
      FParametrosCaja.GetBool('vgerChkExistOnly', True);
    if Entrada.VerificarExistencia then
    begin
      EstadoSku := FPersistencia.ObtenerEstadoSku(sCodigoSku);
      Entrada.Existe := EstadoSku.Existe;
      Entrada.Activo := EstadoSku.Activo;
    end;
    Entrada.BloquearSinStock :=
      FParametrosCaja.GetBool('vgerChkStockOnly', False);
    sMensajeStock := Trim(
      FParametrosCaja.GetString('vgerAvisoStockWarning', ''));
    Entrada.VerificarStock :=
      Entrada.BloquearSinStock or (sMensajeStock <> '');
    if Entrada.VerificarStock and
       ((not Entrada.VerificarExistencia) or
        (Entrada.Existe and Entrada.Activo)) then
    begin
      Entrada.CantidadDisponible :=
        FPersistencia.ObtenerCantidadDisponible(
          sCodigoSku,
          ACodigoAlmacen);
    end;
    Result := EvaluarPoliticaStockVenta(Entrada);
    CompletarMensaje(sCodigoSku, sMensajeStock, Result);
  end
  else
  begin
    Result.Permitida := True;
    Result.Motivo := msvNinguno;
    Result.Mensaje := '';
  end;
end;

// Mismos parámetros que Validar y que el albarán de venta (FZ-ISSUE-233):
// «Permitir sólo artículos con stock» bloquea; si no, se avisa con el texto
// de «Aviso en artículos sin stock» (vacío = sin aviso).
function TPoliticaStockVenta.ValidarCantidad(
  const ACodigoSku, ACodigoAlmacen: string;
  ACantidad: Double): TResultadoPoliticaStockVenta;
const
  TOLERANCIA = 0.0000005;
var
  bBloquear: Boolean;
  sAviso, sDetalle, sCodigoSku: string;
  dDisponible: Double;
begin
  Result.Permitida := True;
  Result.Motivo := msvNinguno;
  Result.Mensaje := '';
  sCodigoSku := Trim(ACodigoSku);
  bBloquear := FParametrosCaja.GetBool('vgerChkStockOnly', False);
  sAviso := Trim(FParametrosCaja.GetString('vgerAvisoStockWarning', ''));
  if (sCodigoSku <> '') and (ACantidad > 0) and
     (bBloquear or (sAviso <> '')) then
  begin
    dDisponible := FPersistencia.ObtenerCantidadDisponible(sCodigoSku,
      ACodigoAlmacen);
    if (dDisponible > 0) and (ACantidad > dDisponible + TOLERANCIA) then
    begin
      sDetalle := Format(SDetalleStockInsuficienteLinea,
        [sCodigoSku, FormatFloat('0.###', ACantidad),
         FormatFloat('0.###', dDisponible), ACodigoAlmacen]);
      Result.Motivo := msvSinStock;
      Result.Permitida := not bBloquear;
      if bBloquear then
        Result.Mensaje := Format(SErrorStockInsuficienteLinea, [sDetalle])
      else
        Result.Mensaje := sAviso + sLineBreak + sDetalle;
    end;
  end;
end;

end.
