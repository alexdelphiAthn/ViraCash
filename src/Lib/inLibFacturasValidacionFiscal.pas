{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasValidacionFiscal                                 }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Valida la coherencia fiscal de una factura sin depender de formularios.   }
{******************************************************************************}
unit inLibFacturasValidacionFiscal;

interface

uses
  inLibFacturasServiciosIntf;

type
  TValidadorFiscalFactura = class(
    TInterfacedObject,
    IValidadorFiscalFactura)
  private
    FRepositorio: IRepositorioFacturas;
  public
    constructor Create(
      const ARepositorio: IRepositorioFacturas);
    procedure Validar(
      const ASolicitud: TSolicitudValidacionFiscalFactura);
  end;

// FZ-ISSUE-322: True si un fallo de la validación fiscal se deja para la
// grabación explícita de la cabecera. Al editar líneas la cabecera se graba
// sola mientras el motor recalcula los totales: la cuota de IVA está a medio
// calcular y su comprobación (cvfOperacionFiscal) abortaba la línea. País y
// NIF no dependen de los totales y se siguen comprobando.
function EsValidacionFiscalAplazable(ACampo: TCampoValidacionFac;
  AGrabacionPorLineas: Boolean): Boolean;

implementation

uses
  System.SysUtils, inLibMsgFacturas, inLibMsgVentas;

function EsValidacionFiscalAplazable(ACampo: TCampoValidacionFac;
  AGrabacionPorLineas: Boolean): Boolean;
begin
  Result := AGrabacionPorLineas and (ACampo = cvfOperacionFiscal);
end;

constructor TValidadorFiscalFactura.Create(
  const ARepositorio: IRepositorioFacturas);
begin
  inherited Create;
  FRepositorio := ARepositorio;
end;

procedure TValidadorFiscalFactura.Validar(
  const ASolicitud: TSolicitudValidacionFiscalFactura);
var
  Operacion: TOperacionFiscalFactura;
  TipoOperacion: string;
  CodigoPais: string;
  NifCliente: string;
  EsMiembroUE: Boolean;
  EsExtranjero: Boolean;
begin
  TipoOperacion := Trim(ASolicitud.TipoOperacion);
  CodigoPais := Trim(ASolicitud.CodigoPaisCliente);
  NifCliente := Trim(ASolicitud.NifCliente);
  EsMiembroUE := FRepositorio.EsPaisUE(CodigoPais);
  EsExtranjero := (CodigoPais <> '') and
    (CodigoPais <> '724') and
    (not SameText(CodigoPais, 'ES'));
  Operacion.Ambito := '';
  Operacion.RepercuteIva := True;
  if TipoOperacion <> '' then
  begin
    FRepositorio.ObtenerOperacionFiscal(
      TipoOperacion,
      Operacion);
  end;
  // Una operación sin tipo para un cliente extracomunitario se trata
  // como exportación y no repercute IVA.
  if (TipoOperacion = '') and
     EsExtranjero and
     (not EsMiembroUE) then
  begin
    Operacion.RepercuteIva := False;
  end;
  if SameText(Operacion.Ambito, 'UE') and
     (not EsMiembroUE) then
  begin
    raise EValidacionFactura.Create(
      Format(
        SErrorOperacionIntracomunitariaClienteNoUE,
        [TipoOperacion, CodigoPais]),
      cvfPais);
  end;
  if SameText(Operacion.Ambito, 'EXTRA_UE') and
     (EsMiembroUE or (not EsExtranjero)) then
  begin
    raise EValidacionFactura.Create(
      Format(
        SErrorOperacionExportacionClienteNoExtranjero,
        [TipoOperacion]),
      cvfPais);
  end;
  if (not Operacion.RepercuteIva) and
     (Abs(ASolicitud.TotalImpuestos) > 0.01) then
  begin
    raise EValidacionFactura.Create(
      Format(
        SErrorOperacionSinIvaConCuota,
        [FormatFloat(
          '#,##0.00',
          ASolicitud.TotalImpuestos)]),
      cvfOperacionFiscal);
  end;
  if EsExtranjero and
     (NifCliente = '') then
  begin
    raise EValidacionFactura.Create(
      Format(
        SErrorNifIvaClienteExtranjero,
        [CodigoPais]),
      cvfNifCliente);
  end;
end;

end.
