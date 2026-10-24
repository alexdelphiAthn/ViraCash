{******************************************************************************}
{                                                                              }
{  Modulo:       inLibStockConsultaEntrada                                     }
{    Tipo:       Aplicacion                                                    }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Resuelve entradas de stock y decide si aplicar, ofrecer opciones o avisar.}
{******************************************************************************}
unit inLibStockConsultaEntrada;

interface

uses
  inLibArticulosValidadorIntf,
  inLibStockConsultaEntradaIntf;

function CrearAplicacionEntradaStock(
  const ARepositorio: IRepositorioEntradaStock;
  const AValidador: IArticulosValidador;
  const AVista: IVistaEntradaStock): IAplicacionEntradaStock;

implementation

uses
  System.Classes,
  System.SysUtils;

type
  TAplicacionEntradaStock = class(
    TInterfacedObject,
    IAplicacionEntradaStock)
  private
    FRepositorio: IRepositorioEntradaStock;
    FValidador: IArticulosValidador;
    FVista: IVistaEntradaStock;
  public
    constructor Create(
      const ARepositorio: IRepositorioEntradaStock;
      const AValidador: IArticulosValidador;
      const AVista: IVistaEntradaStock);
    procedure ProcesarTexto(
      const AEntrada, ACodigoArticuloActual: string;
      AMostrarError: Boolean);
    procedure ProcesarCodigoBarras(const ACodigo: string);
  end;

constructor TAplicacionEntradaStock.Create(
  const ARepositorio: IRepositorioEntradaStock;
  const AValidador: IArticulosValidador;
  const AVista: IVistaEntradaStock);
begin
  inherited Create;
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('ARepositorio');
  if not Assigned(AValidador) then
    raise EArgumentNilException.Create('AValidador');
  if not Assigned(AVista) then
    raise EArgumentNilException.Create('AVista');
  FRepositorio := ARepositorio;
  FValidador := AValidador;
  FVista := AVista;
end;

procedure TAplicacionEntradaStock.ProcesarTexto(
  const AEntrada, ACodigoArticuloActual: string;
  AMostrarError: Boolean);
var
  Coincidencias: TCoincidenciasEntradaStock;
  Codigos: TStringList;
  Coincidencia: TCoincidenciaEntradaStock;
  sEntrada: string;
begin
  sEntrada := Trim(AEntrada);
  if sEntrada = '' then
    FVista.AplicarArticulo('', '')
  else if not SameText(sEntrada, Trim(ACodigoArticuloActual)) then
  begin
    Coincidencias := FRepositorio.ResolverTexto(sEntrada);
    if Length(Coincidencias) = 0 then
    begin
      if AMostrarError then
        FVista.MostrarTextoNoEncontrado(sEntrada);
      FVista.AplicarArticulo(sEntrada, '');
    end
    else
    begin
      Codigos := TStringList.Create;
      try
        for Coincidencia in Coincidencias do
        begin
          if Codigos.IndexOf(Coincidencia.CodigoArticulo) < 0 then
            Codigos.Add(Coincidencia.CodigoArticulo);
        end;
        if Codigos.Count = 1 then
          FVista.AplicarArticulo(
            Coincidencias[0].CodigoArticulo,
            Coincidencias[0].CodigoSku)
        else
          FVista.MostrarCoincidencias(Coincidencias, sEntrada);
      finally
        Codigos.Free;
      end;
    end;
  end;
end;

procedure TAplicacionEntradaStock.ProcesarCodigoBarras(
  const ACodigo: string);
var
  Resolucion: TArtResolucionEntrada;
begin
  Resolucion := FValidador.ResolverCodigoBarras(ACodigo);
  if Resolucion.Encontrado then
    FVista.AplicarArticulo(
      Resolucion.CodigoArticulo,
      Resolucion.CodigoSku)
  else
    FVista.MostrarCodigoBarrasNoEncontrado(ACodigo);
end;

function CrearAplicacionEntradaStock(
  const ARepositorio: IRepositorioEntradaStock;
  const AValidador: IArticulosValidador;
  const AVista: IVistaEntradaStock): IAplicacionEntradaStock;
begin
  Result := TAplicacionEntradaStock.Create(
    ARepositorio,
    AValidador,
    AVista);
end;

end.
