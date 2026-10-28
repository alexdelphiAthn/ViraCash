{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataDatosProveedorDocumento                                }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       05/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Descripcion:                                                                }
{    Copia en la cabecera de un documento de compra (pedido, albaran,          }
{    factura, devolucion) los datos fiscales del proveedor, como se hace      }
{    con los de la empresa: lista, impresion y correo los leen de ahi.         }
{    FZ-ISSUE-249.                                                             }
{******************************************************************************}
unit UniDataDatosProveedorDocumento;

interface

uses
  Data.DB;

// Rellena RAZON_SOCIAL_PRV_<ASufijo>, NIF_PRV_<ASufijo>... desde la ficha
// del proveedor CODIGO_PRV_<ASufijo>. Solo en el alta, al cambiar de
// proveedor o si la cabecera no tiene razon social: lo ya grabado es una
// foto del documento y no se reescribe. ADataSet debe ser un TUniQuery
// (se usa su conexion) en dsInsert o dsEdit.
procedure CopiarDatosProveedorDocumento(ADataSet: TDataSet;
  const ASufijo: string);
// Igual para la empresa compradora: RAZON_SOCIAL_EMPRESA_<ASufijo>...
// desde CODIGO_EMP_<ASufijo>. La factura de compra no los copiaba y el
// recibo REAGP salía sin los datos de quien compra (FZ-ISSUE-745).
procedure CopiarDatosEmpresaDocumento(ADataSet: TDataSet;
  const ASufijo: string);

implementation

uses
  System.SysUtils, System.Variants, Uni;

const
  // Columnas de la cabecera sin el sufijo del documento; la
  // consulta las devuelve con el mismo nombre.
  CAMPOS_PROVEEDOR: array[0..10] of string = (
    'RAZON_SOCIAL_PRV', 'NIF_PRV', 'MOVIL_PRV', 'EMAIL_PRV',
    'DIRECCION1_PRV', 'DIRECCION2_PRV', 'POBLACION_PRV', 'PROVINCIA_PRV',
    'CODIGO_PAI_PRV', 'NOMBRE_PAI_PRV', 'CODIGO_POSTAL_PRV');
  SQL_PROVEEDOR =
    'SELECT COALESCE(NULLIF(TRIM(P.RAZON_SOCIAL_PRV), ''''), ' +
    '         P.NOMBRE_PRV) AS RAZON_SOCIAL_PRV, ' +
    '       P.NIF_PRV, P.MOVIL_PRV, P.EMAIL_PRV, ' +
    '       P.DIRECCION1_PRV, P.DIRECCION2_PRV, ' +
    '       P.POBLACION_PRV, P.PROVINCIA_PRV, P.CODIGO_PAI_PRV, ' +
    '       COALESCE(PA.NOMBRE_SPA_PAI, P.PAIS_PRV) AS NOMBRE_PAI_PRV, ' +
    '       P.CODIGO_POSTAL_PRV ' +
    '  FROM fza_proveedores P ' +
    '  LEFT JOIN fza_paises PA ON PA.CODIGO_PAI_PAI = P.CODIGO_PAI_PRV ' +
    ' WHERE P.CODIGO_PRV_PRV = :CODIGO';

  CAMPOS_EMPRESA: array[0..10] of string = (
    'RAZON_SOCIAL', 'NIF', 'MOVIL', 'EMAIL', 'DIRECCION1', 'DIRECCION2',
    'POBLACION', 'PROVINCIA', 'CODIGO_PAI', 'NOMBRE_PAI', 'CODIGO_POSTAL');
  SQL_EMPRESA =
    'SELECT E.RAZON_SOCIAL_EMP AS RAZON_SOCIAL, E.NIF_EMP AS NIF, ' +
    '       E.MOVIL_EMP AS MOVIL, E.EMAIL_EMP AS EMAIL, ' +
    '       E.DIRECCION1_EMP AS DIRECCION1, ' +
    '       E.DIRECCION2_EMP AS DIRECCION2, ' +
    '       E.POBLACION_EMP AS POBLACION, E.PROVINCIA_EMP AS PROVINCIA, ' +
    '       E.CODIGO_PAI_EMP AS CODIGO_PAI, ' +
    '       PA.NOMBRE_SPA_PAI AS NOMBRE_PAI, ' +
    '       E.CODIGO_POSTAL_EMP AS CODIGO_POSTAL ' +
    '  FROM fza_empresas E ' +
    '  LEFT JOIN fza_paises PA ON PA.CODIGO_PAI_PAI = E.CODIGO_PAI_EMP ' +
    ' WHERE E.CODIGO_EMP_EMP = :CODIGO';

function DebeCopiarTercero(ADataSet: TDataSet;
  const ACampoCodigo, ACampoRazon: string): Boolean;
var
  CampoCodigo, CampoRazon: TField;
begin
  CampoCodigo := ADataSet.FindField(ACampoCodigo);
  CampoRazon := ADataSet.FindField(ACampoRazon);
  Result := (CampoCodigo <> nil) and (CampoRazon <> nil) and
    (Trim(CampoCodigo.AsString) <> '') and
    ((ADataSet.State = dsInsert) or
     (Trim(CampoRazon.AsString) = '') or
     not SameText(Trim(CampoCodigo.AsString),
       Trim(VarToStr(CampoCodigo.OldValue))));
end;

function DebeCopiar(ADataSet: TDataSet; const ASufijo: string): Boolean;
begin
  Result := DebeCopiarTercero(ADataSet, 'CODIGO_PRV_' + ASufijo,
    'RAZON_SOCIAL_PRV_' + ASufijo);
end;

procedure CopiarDatosProveedorDocumento(ADataSet: TDataSet;
  const ASufijo: string);
var
  oConsulta: TUniQuery;
  Campo: TField;
  i: Integer;
begin
  if DebeCopiar(ADataSet, ASufijo) then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := TUniQuery(ADataSet).Connection;
      oConsulta.SQL.Text := SQL_PROVEEDOR;
      oConsulta.ParamByName('CODIGO').AsString :=
        Trim(ADataSet.FieldByName('CODIGO_PRV_' + ASufijo).AsString);
      oConsulta.Open;
      // Un codigo sin ficha (el '0' del alta) no borra lo que hubiera.
      if not oConsulta.IsEmpty then
      begin
        for i := Low(CAMPOS_PROVEEDOR) to High(CAMPOS_PROVEEDOR) do
        begin
          Campo := ADataSet.FindField(
            CAMPOS_PROVEEDOR[i] + '_' + ASufijo);
          if Campo <> nil then
            Campo.Value := oConsulta.FieldByName(
              CAMPOS_PROVEEDOR[i]).Value;
        end;
      end;
    finally
      oConsulta.Free;
    end;
  end;
end;

procedure CopiarDatosEmpresaDocumento(ADataSet: TDataSet;
  const ASufijo: string);
var
  oConsulta: TUniQuery;
  Campo: TField;
  i: Integer;
begin
  if DebeCopiarTercero(ADataSet, 'CODIGO_EMP_' + ASufijo,
    'RAZON_SOCIAL_EMPRESA_' + ASufijo) then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := TUniQuery(ADataSet).Connection;
      oConsulta.SQL.Text := SQL_EMPRESA;
      oConsulta.ParamByName('CODIGO').AsString :=
        Trim(ADataSet.FieldByName('CODIGO_EMP_' + ASufijo).AsString);
      oConsulta.Open;
      if not oConsulta.IsEmpty then
      begin
        for i := Low(CAMPOS_EMPRESA) to High(CAMPOS_EMPRESA) do
        begin
          Campo := ADataSet.FindField(
            CAMPOS_EMPRESA[i] + '_EMPRESA_' + ASufijo);
          if Campo <> nil then
            Campo.Value := oConsulta.FieldByName(CAMPOS_EMPRESA[i]).Value;
        end;
      end;
    finally
      oConsulta.Free;
    end;
  end;
end;

end.
