unit inLibDevolucionesCompraStock;

{
  Caso de uso para preparar la devolucion de todo el stock disponible
  de un articulo y color. La persistencia se consume mediante un puerto.
}

interface

type
  TEstadoStockDevolucionCompra = (
    esdcDisponible,
    esdcProveedorNoIndicado,
    esdcAlmacenNoIndicado,
    esdcArticuloNoIndicado,
    esdcRequiereColor,
    esdcSinStock
  );
  TParametrosStockDevolucionCompra = record
    Serie: string;
    Numero: string;
    CodigoArticulo: string;
    CodigoProveedor: string;
    CodigoAlmacen: string;
    Usuario: string;
    IdColor: Integer;
    IvaNormal: Double;
    IvaReducido: Double;
    IvaSuperreducido: Double;
    IvaExento: Double;
  end;
  IPersistenciaStockDevolucionCompra = interface
    ['{CC71FAAC-F25D-4C2A-9AC9-B6DA5CCB85C6}']
    function ConsultarEstado(
      const AParametros: TParametrosStockDevolucionCompra):
      TEstadoStockDevolucionCompra;
    function DevolverTodoStock(
      const AParametros: TParametrosStockDevolucionCompra;
      out ALineas: Integer;
      out AEstado: TEstadoStockDevolucionCompra): Boolean;
  end;

function ConsultarEstadoStockDevolucionCompra(
  const APersistencia: IPersistenciaStockDevolucionCompra;
  const AParametros: TParametrosStockDevolucionCompra):
  TEstadoStockDevolucionCompra;
function DevolverTodoStockCompra(
  const APersistencia: IPersistenciaStockDevolucionCompra;
  const AParametros: TParametrosStockDevolucionCompra;
  out ALineas: Integer;
  out AEstado: TEstadoStockDevolucionCompra): Boolean;

implementation

function ConsultarEstadoStockDevolucionCompra(
  const APersistencia: IPersistenciaStockDevolucionCompra;
  const AParametros: TParametrosStockDevolucionCompra):
  TEstadoStockDevolucionCompra;
begin
  if APersistencia = nil then
    Result := esdcSinStock
  else
    Result := APersistencia.ConsultarEstado(AParametros);
end;

function DevolverTodoStockCompra(
  const APersistencia: IPersistenciaStockDevolucionCompra;
  const AParametros: TParametrosStockDevolucionCompra;
  out ALineas: Integer;
  out AEstado: TEstadoStockDevolucionCompra): Boolean;
begin
  ALineas := 0;
  if APersistencia = nil then
  begin
    AEstado := esdcSinStock;
    Result := False;
  end
  else
    Result := APersistencia.DevolverTodoStock(
      AParametros,
      ALineas,
      AEstado);
end;

end.
