{******************************************************************************}
{  Modulo: UniDataFiltroProveedorLoteSql                                       }
{  Filtro por proveedor de lotes y series, con respaldo por articulo.          }
{******************************************************************************}
unit UniDataFiltroProveedorLoteSql;

interface

// Los argumentos son expresiones SQL del repositorio, nunca valores de UI.
function SqlFiltroProveedorLote(const AParametro, ACampoSku,
  ACampoLote, ACampoArticulo: string): string;

implementation

function SqlFiltroProveedorLote(const AParametro, ACampoSku,
  ACampoLote, ACampoArticulo: string): string;
var
  sAsignado: string;
begin
  // Lotes y numeros de serie comparten catalogo y campos de movimiento.
  sAsignado :=
    'SELECT 1 FROM fza_articulos_lotes LP WHERE ' +
    'LP.CODIGO_UNIDAD_LOT = ' + ACampoSku +
    ' AND LP.LOTE_LOT = ' + ACampoLote +
    ' AND COALESCE(TRIM(LP.CODIGO_PRV_LOT), '''') NOT IN ('''', ''0'')';
  Result := '(' + AParametro + ' = '''' OR EXISTS (' + sAsignado +
    ' AND FIND_IN_SET(LP.CODIGO_PRV_LOT, ' + AParametro + ') > 0)' +
    ' OR (NOT EXISTS (' + sAsignado + ') AND EXISTS (' +
    'SELECT 1 FROM fza_articulos_proveedores APF ' +
    'WHERE APF.CODIGO_ART_AP = ' + ACampoArticulo +
    ' AND FIND_IN_SET(APF.CODIGO_PRV_AP, ' + AParametro + ') > 0)))';
end;

end.
