{******************************************************************************}
{  Módulo: UniDataPropiedadesLineasDocumento                                   }
{  Tipo: Adaptador UniDAC. Fecha: 01/11/2026                                   }
{  Propiedades activas del artículo en documentos de venta.                    }
{******************************************************************************}
unit UniDataPropiedadesLineasDocumento;

interface

uses
  Uni;

function SqlPropiedadesLinea(const AArticulo, AUnidad: string): string;
procedure ConfigurarPropiedadesLineas(AConsulta: TUniQuery;
  const ASufijo: string);

implementation

uses
  System.SysUtils, DBAccess;

// Solo recibe expresiones de campos definidas por el programa.
// Prevalece el nivel más específico de cada propiedad, sin mezclar
// valores de otros colores o tallas. No requiere migrar documentos.
function SqlPropiedadesLinea(const AArticulo, AUnidad: string): string;
begin
  Result :=
    '(SELECT GROUP_CONCAT(CONCAT(P.NOMBRE_PROP_PROP, '': '', ' +
    'COALESCE(V.PV, A.VALOR_LIBRE_ARTPROP)) ' +
    'ORDER BY P.CODIGO_PROP_ARTPROP, V.PV, A.VALOR_LIBRE_ARTPROP ' +
    'SEPARATOR ''; '') FROM fza_articulos_propiedades A ' +
    'JOIN fza_propiedades P ' +
    'ON P.CODIGO_PROP_ARTPROP = A.CODIGO_PROP_ARTPROP ' +
    'LEFT JOIN fza_propiedades_valores V ' +
    'ON V.ID_PV_ARTPROP = A.ID_PV_ARTPROP ' +
    'WHERE A.CODIGO_ART_ART = ' + AArticulo +
    ' AND P.ESACTIVO_PROP = ''S'' ' +
    'AND TRIM(COALESCE(V.PV, A.VALOR_LIBRE_ARTPROP, '''')) <> '''' ' +
    'AND A.CODIGO_UNIDAD_ARTPROP = COALESCE((' +
    'SELECT B.CODIGO_UNIDAD_ARTPROP ' +
    'FROM fza_articulos_propiedades B ' +
    'WHERE B.CODIGO_ART_ART = A.CODIGO_ART_ART ' +
    'AND B.CODIGO_PROP_ARTPROP = A.CODIGO_PROP_ARTPROP ' +
    'AND (B.CODIGO_UNIDAD_ARTPROP = '''' ' +
    'OR B.CODIGO_UNIDAD_ARTPROP = ' + AUnidad +
    ' OR LEFT(' + AUnidad + ', ' +
    'CHAR_LENGTH(B.CODIGO_UNIDAD_ARTPROP) + 1) = ' +
    'CONCAT(B.CODIGO_UNIDAD_ARTPROP, ''/'')) ' +
    'ORDER BY CHAR_LENGTH(B.CODIGO_UNIDAD_ARTPROP) DESC LIMIT 1), ' +
    '''''))';
end;

function AgregarPropiedades(const ASql, ASufijo: string): string;
var
  iDesde: Integer;
begin
  // Las consultas de líneas son SELECT simples de una tabla o vista.
  iDesde := Pos('FROM ', UpperCase(ASql));
  if iDesde = 0 then
    raise EArgumentException.Create('SELECT de líneas sin FROM');
  Result := Copy(ASql, 1, iDesde - 1) + ', ' +
    SqlPropiedadesLinea('CODIGO_ART_' + ASufijo,
      'CODIGO_UNIDAD_' + ASufijo) +
    ' AS PROPIEDADES_ARTICULO ' + Copy(ASql, iDesde, MaxInt);
end;

procedure ConfigurarPropiedadesLineas(AConsulta: TUniQuery;
  const ASufijo: string);
var
  sCabecera: string;
begin
  sCabecera := Copy(ASufijo, 1, Length(ASufijo) - 3);
  if Trim(AConsulta.SQLRefresh.Text) = '' then
    AConsulta.SQLRefresh.Text := AConsulta.SQL.Text +
      ' WHERE NUMERO_' + sCabecera + '_' + ASufijo + ' = :NUMERO_' +
      sCabecera + '_' + ASufijo +
      ' AND SERIE_' + sCabecera + '_' + ASufijo + ' = :SERIE_' +
      sCabecera + '_' + ASufijo +
      ' AND LINEA_' + ASufijo + ' = :LINEA_' + ASufijo;
  AConsulta.SQL.Text := AgregarPropiedades(AConsulta.SQL.Text, ASufijo);
  AConsulta.SQLRefresh.Text :=
    AgregarPropiedades(AConsulta.SQLRefresh.Text, ASufijo);
  AConsulta.RefreshOptions := AConsulta.RefreshOptions +
    [roAfterInsert, roAfterUpdate];
end;

end.
