{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaEntrada                                              }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Orquesta una lectura de artículo de caja contra puertos independientes.  }
{******************************************************************************}
unit inLibCajaEntrada;

interface

uses
  inLibArticulosValidadorIntf,
  inLibCajaEntradaIntf;

function CrearAplicacionEntradaCaja(
  const AValidador: IArticulosValidador;
  const AOperaciones: IOperacionesEntradaCaja;
  const AVista: IVistaEntradaCaja;
  const ATrazabilidad: ITrazabilidadEntradaCaja = nil
): IAplicacionEntradaCaja;

implementation

uses
  System.SysUtils,
  inLibTrazabilidad,
  inLibMsgCaja;

type
  TAplicacionEntradaCaja = class(
    TInterfacedObject,
    IAplicacionEntradaCaja)
  private
    FOperaciones: IOperacionesEntradaCaja;
    FValidador: IArticulosValidador;
    FVista: IVistaEntradaCaja;
    FTrazabilidad: ITrazabilidadEntradaCaja;
    procedure AplicarSinLote(const ACodigoAplicar, ASku,
      AArticulo: string);
    procedure AplicarConLotes(const ACodigoAplicar, ASku,
      AArticulo: string; const AAsignaciones: TArray<TAsignacionLote>);
  public
    constructor Create(
      const AValidador: IArticulosValidador;
      const AOperaciones: IOperacionesEntradaCaja;
      const AVista: IVistaEntradaCaja;
      const ATrazabilidad: ITrazabilidadEntradaCaja);
    function ResolverEntrada(const ACodigo: string;
      out ACodigoAplicar: string): TArtResolucionEntrada;
    procedure Procesar(const ACodigo: string);
  end;

constructor TAplicacionEntradaCaja.Create(
  const AValidador: IArticulosValidador;
  const AOperaciones: IOperacionesEntradaCaja;
  const AVista: IVistaEntradaCaja;
  const ATrazabilidad: ITrazabilidadEntradaCaja);
begin
  if not Assigned(AValidador) then
    raise EArgumentNilException.Create('AValidador');
  if not Assigned(AOperaciones) then
    raise EArgumentNilException.Create('AOperaciones');
  if not Assigned(AVista) then
    raise EArgumentNilException.Create('AVista');
  inherited Create;
  FValidador := AValidador;
  FOperaciones := AOperaciones;
  FVista := AVista;
  FTrazabilidad := ATrazabilidad;
end;

procedure TAplicacionEntradaCaja.AplicarSinLote(const ACodigoAplicar, ASku,
  AArticulo: string);
begin
  FOperaciones.PrepararLinea;
  if (Trim(ASku) <> '') and FOperaciones.ConsolidarSku(ASku) then
    FVista.RefrescarConsolidacion
  else
    FOperaciones.AplicarCodigo(ACodigoAplicar, ASku, AArticulo);
end;

// F-LOTEC-015: una línea por lote o serie; un lote ya en el ticket suma
// en su línea (como la consolidación por SKU), una serie nunca.
procedure TAplicacionEntradaCaja.AplicarConLotes(const ACodigoAplicar, ASku,
  AArticulo: string; const AAsignaciones: TArray<TAsignacionLote>);
var
  rAsignacion: TAsignacionLote;
begin
  for rAsignacion in AAsignaciones do
  begin
    FOperaciones.PrepararLinea;
    if FTrazabilidad.Consolidar(ASku, rAsignacion) then
      FVista.RefrescarConsolidacion
    else
    begin
      FOperaciones.AplicarCodigo(ACodigoAplicar, ASku, AArticulo);
      FTrazabilidad.EscribirLote(rAsignacion);
    end;
  end;
end;

// Primero como código de barras (lector). Si no lo es, como en la
// rejilla de los documentos: código de artículo, SKU o referencia de
// proveedor, para vender por código artículos sin EAN, como los de
// metros (FZ-ISSUE-231). Solo se acepta si identifica una única prenda:
// con varias coincidencias no se da por encontrado y un artículo con
// tallas o colores sin SKU se deja para Buscar (F3).
function TAplicacionEntradaCaja.ResolverEntrada(const ACodigo: string;
  out ACodigoAplicar: string): TArtResolucionEntrada;
begin
  ACodigoAplicar := ACodigo;
  Result := FValidador.ResolverCodigoBarras(ACodigo);
  // F-LOTEC: la cadena GS1 entera (GTIN + lote + caducidad...) no es un
  // código que la línea sepa leer; se aplica el SKU que identifica.
  if Result.Encontrado and Result.EsGs1 and
     (Trim(Result.CodigoSku) <> '') then
    ACodigoAplicar := Result.CodigoSku;
  if not Result.Encontrado then
  begin
    Result := FValidador.Resolver(ACodigo);
    if Result.Encontrado and (Result.NumCoincidencias > 1) then
      Result.Encontrado := False;
    if Result.Encontrado then
    begin
      ACodigoAplicar := Result.CodigoSku;
      if Trim(ACodigoAplicar) = '' then
        ACodigoAplicar := Result.CodigoArticulo;
    end;
  end;
end;

procedure TAplicacionEntradaCaja.Procesar(const ACodigo: string);
var
  aAsignaciones: TArray<TAsignacionLote>;
  Resolucion: TArtResolucionEntrada;
  sCodigoAplicar: string;
  sSku: string;
begin
  if FOperaciones.Disponible then
  begin
    FOperaciones.Iniciar;
    try
      if not FOperaciones.VendedorAsignado then
      begin
        FVista.MostrarError(SErrorVendedorCajaNoAsignado);
        FVista.EnfocarVendedor;
      end
      else
      begin
        FVista.PrepararLectura;
        Resolucion := ResolverEntrada(ACodigo, sCodigoAplicar);
        sSku := Resolucion.CodigoSku;
        if not Resolucion.Encontrado then
        begin
          FVista.MostrarError(Format(
            SErrorCodigoBarrasVentaCajaNoEncontrado,
            [ACodigo]));
        end
        else if Resolucion.RequiereSku and (Trim(sSku) = '') then
        begin
          FVista.MostrarError(Format(
            SErrorArticuloCajaRequiereVariacion,
            [Resolucion.CodigoArticulo]));
        end
        else if (Trim(sSku) = '') or
                FOperaciones.PermitirSku(sSku) then
        begin
          aAsignaciones := [];
          if not Assigned(FTrazabilidad) or (Trim(sSku) = '') then
            AplicarSinLote(sCodigoAplicar, sSku, Resolucion.CodigoArticulo)
          else if FTrazabilidad.Decidir(Resolucion, aAsignaciones) then
          begin
            if Length(aAsignaciones) = 0 then
              AplicarSinLote(sCodigoAplicar, sSku,
                             Resolucion.CodigoArticulo)
            else
              AplicarConLotes(sCodigoAplicar, sSku,
                              Resolucion.CodigoArticulo, aAsignaciones);
          end;
        end;
        FVista.PrepararSiguiente;
      end;
    finally
      FOperaciones.Finalizar;
    end;
  end;
end;

function CrearAplicacionEntradaCaja(
  const AValidador: IArticulosValidador;
  const AOperaciones: IOperacionesEntradaCaja;
  const AVista: IVistaEntradaCaja;
  const ATrazabilidad: ITrazabilidadEntradaCaja
): IAplicacionEntradaCaja;
begin
  Result := TAplicacionEntradaCaja.Create(
    AValidador,
    AOperaciones,
    AVista,
    ATrazabilidad);
end;

end.
