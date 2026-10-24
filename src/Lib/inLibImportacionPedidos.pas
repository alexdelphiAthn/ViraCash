{******************************************************************************}
{                                                                              }
{  Módulo:       inLibImportacionPedidos                                      }
{    Tipo:       Caso de uso                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Coordina la fuente externa y la persistencia de pedidos importados.       }
{******************************************************************************}
unit inLibImportacionPedidos;

interface

uses
  inLibImportacionPedidosIntf;

function CrearCasoUsoImportacionPedidos(
  const AFabricaFuente: IFabricaFuentePedidosImportacion;
  const ARepositorio: IRepositorioImportacionPedidos
): ICasoUsoImportacionPedidos;

// Clave de la tienda de origen: la URL de la API sin espacios, en
// minúsculas y sin barras finales.
function NormalizarOrigenPedidos(const ABaseURL: string): string;

implementation

uses
  System.SysUtils,
  inLibPresta;

type
  TCasoUsoImportacionPedidos = class(
    TInterfacedObject,
    ICasoUsoImportacionPedidos)
  private
    FFabricaFuente: IFabricaFuentePedidosImportacion;
    FRepositorio: IRepositorioImportacionPedidos;
    procedure Notificar(
      const AOnProgreso: TProgresoImportacionPedido;
      const AIdPedido: string;
      AEstado: TEstadoImportacionPedido;
      const AError: string);
    procedure MarcarImportados(
      const AOrigen: string;
      AIncluirImportados: Boolean;
      ALista: TResumenPedidosImportacion);
  public
    constructor Create(
      const AFabricaFuente: IFabricaFuentePedidosImportacion;
      const ARepositorio: IRepositorioImportacionPedidos);
    function Listar(
      const ABaseURL, AApiKey: string;
      AIncluirImportados: Boolean;
      ALista: TResumenPedidosImportacion): Boolean;
    function Ejecutar(
      const ASolicitud: TSolicitudImportacionPedidos;
      const AOnProgreso: TProgresoImportacionPedido
    ): TResultadoImportacionPedidos;
  end;

constructor TCasoUsoImportacionPedidos.Create(
  const AFabricaFuente: IFabricaFuentePedidosImportacion;
  const ARepositorio: IRepositorioImportacionPedidos);
begin
  inherited Create;
  if not Assigned(AFabricaFuente) then
    raise EArgumentNilException.Create('AFabricaFuente');
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('ARepositorio');
  FFabricaFuente := AFabricaFuente;
  FRepositorio := ARepositorio;
end;

procedure TCasoUsoImportacionPedidos.Notificar(
  const AOnProgreso: TProgresoImportacionPedido;
  const AIdPedido: string;
  AEstado: TEstadoImportacionPedido;
  const AError: string);
begin
  if Assigned(AOnProgreso) then
    AOnProgreso(AIdPedido, AEstado, AError);
end;

procedure TCasoUsoImportacionPedidos.MarcarImportados(
  const AOrigen: string;
  AIncluirImportados: Boolean;
  ALista: TResumenPedidosImportacion);
var
  i: Integer;
  oResumen: TResumenPedidoImportacion;
begin
  for i := ALista.Count - 1 downto 0 do
  begin
    oResumen := ALista[i];
    oResumen.Importado := FRepositorio.Existe(
      AOrigen,
      oResumen.IdPedido);
    if oResumen.Importado and not AIncluirImportados then
      ALista.Delete(i)
    else
      ALista[i] := oResumen;
  end;
end;

function TCasoUsoImportacionPedidos.Listar(
  const ABaseURL, AApiKey: string;
  AIncluirImportados: Boolean;
  ALista: TResumenPedidosImportacion): Boolean;
var
  iIdDesde: Int64;
  oFuente: IFuentePedidosImportacion;
  sOrigen: string;
begin
  if not Assigned(ALista) then
    raise EArgumentNilException.Create('ALista');
  sOrigen := NormalizarOrigenPedidos(ABaseURL);
  iIdDesde := 0;
  if not AIncluirImportados then
    iIdDesde := FRepositorio.UltimoIdImportado(sOrigen);
  oFuente := FFabricaFuente.Crear(ABaseURL, AApiKey);
  ALista.Clear;
  Result := oFuente.ListarResumen(iIdDesde, ALista);
  if Result then
    MarcarImportados(sOrigen, AIncluirImportados, ALista);
end;

function TCasoUsoImportacionPedidos.Ejecutar(
  const ASolicitud: TSolicitudImportacionPedidos;
  const AOnProgreso: TProgresoImportacionPedido
): TResultadoImportacionPedidos;
var
  i: Integer;
  oFuente: IFuentePedidosImportacion;
  oPedido: TOrder;
  sIdPedido: string;
  sOrigen: string;
begin
  Result := Default(TResultadoImportacionPedidos);
  sOrigen := NormalizarOrigenPedidos(ASolicitud.BaseURL);
  oFuente := FFabricaFuente.Crear(
    ASolicitud.BaseURL,
    ASolicitud.ApiKey);
  for i := 0 to Length(ASolicitud.IdsPedidos) - 1 do
  begin
    sIdPedido := ASolicitud.IdsPedidos[i];
    if FRepositorio.Existe(sOrigen, sIdPedido) then
      Notificar(AOnProgreso, sIdPedido, eipOmitido, '')
    else
    begin
      Notificar(AOnProgreso, sIdPedido, eipImportando, '');
      try
        oPedido := oFuente.CargarPedido(sIdPedido);
        try
          if FRepositorio.Importar(sOrigen, oPedido) then
          begin
            Inc(Result.Importados);
            Notificar(AOnProgreso, sIdPedido, eipImportado, '');
          end
          else
            Notificar(AOnProgreso, sIdPedido, eipOmitido, '');
        finally
          FreeAndNil(oPedido);
        end;
      except
        on E: Exception do
        begin
          Inc(Result.Errores);
          Notificar(AOnProgreso, sIdPedido, eipError, E.Message);
        end;
      end;
    end;
  end;
end;

function NormalizarOrigenPedidos(const ABaseURL: string): string;
begin
  Result := LowerCase(Trim(ABaseURL));
  while (Result <> '') and (Result[Length(Result)] = '/') do
    Delete(Result, Length(Result), 1);
end;

function CrearCasoUsoImportacionPedidos(
  const AFabricaFuente: IFabricaFuentePedidosImportacion;
  const ARepositorio: IRepositorioImportacionPedidos
): ICasoUsoImportacionPedidos;
begin
  Result := TCasoUsoImportacionPedidos.Create(
    AFabricaFuente,
    ARepositorio);
end;

end.
