{******************************************************************************}
{  Módulo: UniDataProveedoresTexto. Tipo: Persistencia                         }
{  Fecha: 12/11/2026. Autor: Alejandro Laorden Hidalgo                         }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción: Texto con el que los combos muestran un proveedor: el          }
{    nombre comercial y, si está vacío, la razón social.                       }
{******************************************************************************}
unit UniDataProveedoresTexto;

interface

const
  // Columna calculada que llevan los lookups de proveedores.
  CAMPO_NOMBRE_MOSTRADO_PRV = 'NOMBRE_MOSTRADO_PRV';
  // Nombre comercial o, si es nulo o solo espacios, razón social. Sin
  // alias de tabla, para poder componer constantes SQL.
  SQL_NOMBRE_MOSTRADO_PRV =
    'COALESCE(NULLIF(TRIM(NOMBRE_PRV), ''''), RAZON_SOCIAL_PRV)';
  SQL_COLUMNA_NOMBRE_MOSTRADO_PRV =
    SQL_NOMBRE_MOSTRADO_PRV + ' AS ' + CAMPO_NOMBRE_MOSTRADO_PRV;

// La misma expresión con las columnas cualificadas por AAlias.
function SqlNombreMostradoProveedor(const AAlias: string): string;
// Lookup completo de fza_proveedores ordenado por código, para los
// combos de los documentos de compra, que buscan por código.
function SqlLookupProveedoresPorCodigo: string;

implementation

function SqlNombreMostradoProveedor(const AAlias: string): string;
var
  sPrefijo: string;
begin
  sPrefijo := '';
  if AAlias <> '' then
    sPrefijo := AAlias + '.';
  Result := 'COALESCE(NULLIF(TRIM(' + sPrefijo + 'NOMBRE_PRV), ''''), ' +
    sPrefijo + 'RAZON_SOCIAL_PRV)';
end;

function SqlLookupProveedoresPorCodigo: string;
begin
  Result := 'SELECT P.*, ' + SqlNombreMostradoProveedor('P') +
    ' AS ' + CAMPO_NOMBRE_MOSTRADO_PRV +
    ' FROM fza_proveedores P ORDER BY P.CODIGO_PRV_PRV';
end;

end.
