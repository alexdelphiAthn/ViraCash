{******************************************************************************}
{                                                                              }
{  Modulo:       inLibVentasPantallaCrearAlbaran                               }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Prepara las entregas de un pedido y ejecuta la creacion del albaran       }
{    mediante un puerto estrecho, sin conocer VCL, datasets ni UniDAC.         }
{******************************************************************************}
unit inLibVentasPantallaCrearAlbaran;

interface

type
  TLineaPedidoParaAlbaran = record
    Linea: string;
    CodigoAlmacen: string;
    CantidadEntregada: Currency;
    CantidadAAlbaranar: Currency;
  end;

  TLineasPedidoParaAlbaran = TArray<TLineaPedidoParaAlbaran>;

  TEntregaAlbaranPedido = record
    Linea: string;
    CantidadTotalEntregada: Currency;
  end;

  TEntregasAlbaranPedido = TArray<TEntregaAlbaranPedido>;

  TPreparacionAlbaranPedido = record
    Entregas: TEntregasAlbaranPedido;
    AlmacenComun: string;
    EsAlmacenUnico: Boolean;
    function TieneEntregas: Boolean;
    function AlmacenDefecto: string;
  end;

  // Datos del albarán nuevo elegidos en el diálogo común; vacíos = los
  // del pedido (serie y forma de pago), número del contador y hoy.
  TDatosAlbaranNuevoPedido = record
    Serie: string;
    NumeroManual: string;
    Fecha: TDateTime;
    FormaPago: string;
  end;

  TSolicitudCreacionAlbaranPedido = record
    SeriePedido: string;
    NumeroPedido: string;
    CodigoAlmacen: string;
    EsAlbaranExistente: Boolean;
    SerieAlbaranExistente: string;
    NumeroAlbaranExistente: string;
    Entregas: TEntregasAlbaranPedido;
    AlbaranNuevo: TDatosAlbaranNuevoPedido;
  end;

  TResultadoCreacionAlbaranPedido = record
    Creado: Boolean;
    Serie: string;
    Numero: string;
  end;

  IRepositorioCreacionAlbaranPedido = interface
    ['{3FD1E5C4-8A96-42E0-97B4-61A7BC258D32}']
    function Crear(
      const ASolicitud: TSolicitudCreacionAlbaranPedido):
      TResultadoCreacionAlbaranPedido;
  end;

  ICasoUsoCrearAlbaranPedido = interface
    ['{D458F5B1-C36A-4C8D-A175-92DE06741A6E}']
    function Ejecutar(
      const ASolicitud: TSolicitudCreacionAlbaranPedido):
      TResultadoCreacionAlbaranPedido;
  end;

  TPreparadorAlbaranPedido = class
  public
    class function Preparar(
      const ALineas: TLineasPedidoParaAlbaran):
      TPreparacionAlbaranPedido; static;
  end;

  TCasoUsoCrearAlbaranPedido = class(
    TInterfacedObject,
    ICasoUsoCrearAlbaranPedido)
  private
    FRepositorio: IRepositorioCreacionAlbaranPedido;
  public
    constructor Create(
      const ARepositorio: IRepositorioCreacionAlbaranPedido);
    function Ejecutar(
      const ASolicitud: TSolicitudCreacionAlbaranPedido):
      TResultadoCreacionAlbaranPedido;
  end;

implementation

uses
  System.SysUtils;

function TPreparacionAlbaranPedido.TieneEntregas: Boolean;
begin
  Result := Length(Entregas) > 0;
end;

function TPreparacionAlbaranPedido.AlmacenDefecto: string;
begin
  Result := '';
  if EsAlmacenUnico and (AlmacenComun <> '') then
    Result := AlmacenComun;
end;

class function TPreparadorAlbaranPedido.Preparar(
  const ALineas: TLineasPedidoParaAlbaran):
  TPreparacionAlbaranPedido;
var
  iEntrega: Integer;
  iLinea: Integer;
  EsPrimerAlmacen: Boolean;
  sAlmacen: string;
begin
  Result := Default(TPreparacionAlbaranPedido);
  Result.EsAlmacenUnico := True;
  EsPrimerAlmacen := True;
  for iLinea := 0 to High(ALineas) do
  begin
    if ALineas[iLinea].CantidadAAlbaranar > 0 then
    begin
      iEntrega := Length(Result.Entregas);
      SetLength(Result.Entregas, iEntrega + 1);
      Result.Entregas[iEntrega].Linea := ALineas[iLinea].Linea;
      Result.Entregas[iEntrega].CantidadTotalEntregada :=
        ALineas[iLinea].CantidadEntregada +
        ALineas[iLinea].CantidadAAlbaranar;
      sAlmacen := Trim(ALineas[iLinea].CodigoAlmacen);
      if EsPrimerAlmacen then
      begin
        Result.AlmacenComun := sAlmacen;
        EsPrimerAlmacen := False;
      end
      else if sAlmacen <> Result.AlmacenComun then
        Result.EsAlmacenUnico := False;
    end;
  end;
end;

constructor TCasoUsoCrearAlbaranPedido.Create(
  const ARepositorio: IRepositorioCreacionAlbaranPedido);
begin
  inherited Create;
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('ARepositorio');
  FRepositorio := ARepositorio;
end;

function TCasoUsoCrearAlbaranPedido.Ejecutar(
  const ASolicitud: TSolicitudCreacionAlbaranPedido):
  TResultadoCreacionAlbaranPedido;
begin
  Result := FRepositorio.Crear(ASolicitud);
end;

end.
