{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataModalArqueoOperacion                                  }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Coordina la validación, el cálculo y la persistencia del cierre de caja.  }
{******************************************************************************}
unit UniDataModalArqueoOperacion;

interface

uses
  System.SysUtils,
  inLibArqueo,
  inLibArqueoPersistencia,
  inLibModalArqueoPersistenciaIntf;

type
  TDatoRecuentoModalArqueo = record
    CodigoFormaPago: string;
    Descripcion: string;
    ImporteSistema: Currency;
    ImporteRecuento: Currency;
  end;
  TEntradaGrabacionModalArqueo = record
    Arqueo: TArqueoCaja;
    Solicitud: TSolicitudResumenModalArqueo;
    Recuento: TArray<TDatoRecuentoModalArqueo>;
    ImporteRetirada: Currency;
    ConceptoRetirada: string;
    DesgloseBilletes: string;
    Observaciones: string;
    CodigoVendedor: string;
    Usuario: string;
  end;
  TPlanGrabacionModalArqueo = record
    Lineas: TArray<TArqueoRecuentoLinea>;
    TotalSistema: Currency;
    TotalRecuento: Currency;
    DiferenciaTotal: Currency;
    EfectivoRecontado: Currency;
    EfectivoDejado: Currency;
  end;
  TEstadoPreparacionModalArqueo = (
    epmaPreparado,
    epmaVendedorNoIndicado,
    epmaVendedorNoValido,
    epmaArqueoDuplicado,
    epmaRecuentoNoDisponible);
  TResultadoPreparacionModalArqueo = record
    Estado: TEstadoPreparacionModalArqueo;
    CodigoVendedor: string;
    NombreVendedor: string;
    Plan: TPlanGrabacionModalArqueo;
    function PuedeGrabar: Boolean;
  end;
  TOperacionModalArqueo = class
  private
    FRepositorio: IRepositorioModalArqueo;
    FPersistencia: IArqueoPersistencia;
  public
    constructor Create(
      const ARepositorio: IRepositorioModalArqueo;
      const APersistencia: IArqueoPersistencia);
    function Preparar(
      const AEntrada: TEntradaGrabacionModalArqueo):
      TResultadoPreparacionModalArqueo;
    procedure Grabar(
      const AEntrada: TEntradaGrabacionModalArqueo;
      const APreparacion: TResultadoPreparacionModalArqueo);
  end;

function CalcularPlanGrabacionModalArqueo(
  const ARecuento: TArray<TDatoRecuentoModalArqueo>;
  AImporteRetirada: Currency): TPlanGrabacionModalArqueo;
procedure CalcularDistribucionEfectivoModalArqueo(
  AEfectivoRecontado: Currency;
  AEfectivoDejadoSolicitado: Currency;
  out AEfectivoDejado: Currency;
  out AImporteRetirada: Currency);

implementation

resourcestring
  SErrorPreparacionArqueoNoValida =
    'El arqueo no está preparado para su grabación.';

function CalcularEfectivoDejado(
  AEfectivoRecontado: Currency;
  AImporteRetirada: Currency): Currency;
begin
  Result := AEfectivoRecontado - AImporteRetirada;
  if Result < 0 then
    Result := 0;
end;

procedure CalcularDistribucionEfectivoModalArqueo(
  AEfectivoRecontado: Currency;
  AEfectivoDejadoSolicitado: Currency;
  out AEfectivoDejado: Currency;
  out AImporteRetirada: Currency);
var
  EfectivoDisponible: Currency;
begin
  EfectivoDisponible := AEfectivoRecontado;
  if EfectivoDisponible < 0 then
    EfectivoDisponible := 0;
  AEfectivoDejado := AEfectivoDejadoSolicitado;
  if AEfectivoDejado < 0 then
    AEfectivoDejado := 0;
  if AEfectivoDejado > EfectivoDisponible then
    AEfectivoDejado := EfectivoDisponible;
  AImporteRetirada := EfectivoDisponible - AEfectivoDejado;
end;

function CrearLineaRecuento(
  const ADato: TDatoRecuentoModalArqueo;
  AEsCajon: Boolean): TArqueoRecuentoLinea;
begin
  Result := Default(TArqueoRecuentoLinea);
  Result.CodigoFP := ADato.CodigoFormaPago;
  Result.Descripcion := ADato.Descripcion;
  if AEsCajon then
    Result.EsCajon := 'S'
  else
    Result.EsCajon := 'N';
  Result.Sistema := ADato.ImporteSistema;
  Result.Recuento := ADato.ImporteRecuento;
  Result.Diferencia := Result.Recuento - Result.Sistema;
end;

function CalcularPlanGrabacionModalArqueo(
  const ARecuento: TArray<TDatoRecuentoModalArqueo>;
  AImporteRetirada: Currency): TPlanGrabacionModalArqueo;
var
  i: Integer;
begin
  Result := Default(TPlanGrabacionModalArqueo);
  SetLength(Result.Lineas, Length(ARecuento));
  for i := 0 to High(ARecuento) do
  begin
    Result.Lineas[i] := CrearLineaRecuento(ARecuento[i], i = 0);
    Result.TotalSistema :=
      Result.TotalSistema + Result.Lineas[i].Sistema;
    Result.TotalRecuento :=
      Result.TotalRecuento + Result.Lineas[i].Recuento;
  end;
  Result.DiferenciaTotal :=
    Result.TotalRecuento - Result.TotalSistema;
  if Length(Result.Lineas) > 0 then
    Result.EfectivoRecontado := Result.Lineas[0].Recuento;
  Result.EfectivoDejado := CalcularEfectivoDejado(
    Result.EfectivoRecontado,
    AImporteRetirada);
end;

function TResultadoPreparacionModalArqueo.PuedeGrabar: Boolean;
begin
  Result := Estado = epmaPreparado;
end;

constructor TOperacionModalArqueo.Create(
  const ARepositorio: IRepositorioModalArqueo;
  const APersistencia: IArqueoPersistencia);
begin
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('ARepositorio');
  if not Assigned(APersistencia) then
    raise EArgumentNilException.Create('APersistencia');
  inherited Create;
  FRepositorio := ARepositorio;
  FPersistencia := APersistencia;
end;

function TOperacionModalArqueo.Preparar(
  const AEntrada: TEntradaGrabacionModalArqueo):
  TResultadoPreparacionModalArqueo;
begin
  Result := Default(TResultadoPreparacionModalArqueo);
  Result.CodigoVendedor := Trim(AEntrada.CodigoVendedor);
  if Result.CodigoVendedor = '' then
    Result.Estado := epmaVendedorNoIndicado
  else
  begin
    Result.NombreVendedor := FRepositorio.BuscarNombreVendedor(
      Result.CodigoVendedor);
    if Result.NombreVendedor = '' then
      Result.Estado := epmaVendedorNoValido
    else if FRepositorio.ExisteArqueoCerrado(AEntrada.Solicitud) then
      Result.Estado := epmaArqueoDuplicado
    else if Length(AEntrada.Recuento) = 0 then
      Result.Estado := epmaRecuentoNoDisponible
    else
    begin
      Result.Plan := CalcularPlanGrabacionModalArqueo(
        AEntrada.Recuento,
        AEntrada.ImporteRetirada);
      Result.Estado := epmaPreparado;
    end;
  end;
end;

procedure TOperacionModalArqueo.Grabar(
  const AEntrada: TEntradaGrabacionModalArqueo;
  const APreparacion: TResultadoPreparacionModalArqueo);
begin
  if not APreparacion.PuedeGrabar then
    raise EInvalidOpException.Create(SErrorPreparacionArqueoNoValida);
  FPersistencia.GrabarArqueo(
    AEntrada.Arqueo,
    APreparacion.Plan.Lineas,
    APreparacion.Plan.TotalRecuento,
    APreparacion.Plan.DiferenciaTotal,
    APreparacion.Plan.EfectivoDejado,
    AEntrada.ImporteRetirada,
    AEntrada.ConceptoRetirada,
    AEntrada.DesgloseBilletes,
    AEntrada.Observaciones,
    APreparacion.CodigoVendedor,
    AEntrada.Usuario);
end;

end.
