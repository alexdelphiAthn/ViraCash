{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataVendedoresRepositorio                                  }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       10/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Vendedor (comercial) de clientes y documentos de venta, para liquidar     }
{    comisiones. Se asigna en la ficha del cliente, el pedido, el albarán y    }
{    la factura lo proponen al elegir el cliente y viaja de un documento al    }
{    siguiente. Siempre es opcional.                                           }
{                                                                              }
{    Las pantallas leen el vendedor de su vista y aquí se guarda aparte: una   }
{    base sin 20261010_vendedor_clientes_pedidos_albaranes.sql no trae la      }
{    columna y sigue grabando clientes y documentos como antes.                }
{******************************************************************************}
unit UniDataVendedoresRepositorio;

interface

uses
  System.Classes, Data.DB, Uni;

const
  CAMPO_CODIGO_VENDEDOR = 'CODIGO_EMPL';
  CAMPO_NOMBRE_VENDEDOR = 'NOMBRE_VENDEDOR';
  CAMPO_VENDEDOR_CLIENTE = 'CODIGO_VENDEDOR_CLI';
  // Empleados que pueden figurar como vendedor. Van todos, los activos
  // primero: un documento antiguo conserva el nombre de quien ya no está.
  SQL_VENDEDORES =
    'SELECT CODIGO_EMPL, ' +
    '       COALESCE(NULLIF(TRIM(NOMBRE_EMPL), ''''), ' +
    '                NULLIF(TRIM(DIMINUTIVO_TICKET_EMPL), ''''), ' +
    '                CODIGO_EMPL) AS NOMBRE_VENDEDOR, ' +
    '       ESACTIVO_EMPL ' +
    '  FROM fza_empleados ' +
    ' ORDER BY ESACTIVO_EMPL DESC, CODIGO_EMPL';

// Lista de vendedores para los desplegables; la abre quien la crea.
function CrearConsultaVendedores(
  APropietario: TComponent;
  AConexion: TUniConnection): TUniQuery;

// El documento en edición toma el vendedor asignado al cliente elegido.
// Un cliente sin vendedor no borra el que ya tuviera el documento.
// Devuelve True si lo cambia.
function ProponerVendedorCliente(
  ACliente, ADocumento: TDataSet;
  const ACampoDocumento: string): Boolean;

// Guarda el vendedor del registro recién grabado; en blanco queda a NULL.
// ACamposClave se llaman igual en el dataset y en la tabla. No hace nada
// si el dataset no trae el campo. Devuelve True si cambia el dato.
function GuardarVendedorRegistro(
  AConexion: TUniConnection;
  ARegistro: TDataSet;
  const ATabla, ACampoVendedor: string;
  const ACamposClave: array of string): Boolean;

implementation

uses
  System.SysUtils;

function CrearConsultaVendedores(
  APropietario: TComponent;
  AConexion: TUniConnection): TUniQuery;
begin
  Result := TUniQuery.Create(APropietario);
  Result.Connection := AConexion;
  Result.SQL.Text := SQL_VENDEDORES;
  Result.ReadOnly := True;
end;

function ProponerVendedorCliente(
  ACliente, ADocumento: TDataSet;
  const ACampoDocumento: string): Boolean;
var
  oCampoCliente: TField;
  oCampoDocumento: TField;
  sVendedor: string;
begin
  Result := False;
  oCampoCliente := nil;
  oCampoDocumento := nil;
  if Assigned(ACliente) and ACliente.Active then
    oCampoCliente := ACliente.FindField(CAMPO_VENDEDOR_CLIENTE);
  if Assigned(ADocumento) and (ADocumento.State in dsEditModes) then
    oCampoDocumento := ADocumento.FindField(ACampoDocumento);
  if Assigned(oCampoCliente) and Assigned(oCampoDocumento) then
  begin
    sVendedor := Trim(oCampoCliente.AsString);
    Result := (sVendedor <> '') and
      (not SameText(sVendedor, Trim(oCampoDocumento.AsString)));
    if Result then
      oCampoDocumento.AsString := sVendedor;
  end;
end;

function GuardarVendedorRegistro(
  AConexion: TUniConnection;
  ARegistro: TDataSet;
  const ATabla, ACampoVendedor: string;
  const ACamposClave: array of string): Boolean;
var
  i: Integer;
  oCampo: TField;
  oConsulta: TUniQuery;
  sCondicion: string;
begin
  Result := False;
  oCampo := nil;
  if Assigned(ARegistro) and ARegistro.Active then
    oCampo := ARegistro.FindField(ACampoVendedor);
  if Assigned(oCampo) then
  begin
    // Tabla y columnas las fija el código que llama; los valores van en
    // parámetros.
    sCondicion := '';
    for i := Low(ACamposClave) to High(ACamposClave) do
      sCondicion := sCondicion + Format(' AND %s = :CLAVE%d',
        [ACamposClave[i], i]);
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      oConsulta.SQL.Text := Format(
        'UPDATE %0:s ' +
        '   SET %1:s = NULLIF(TRIM(:VENDEDOR), '''') ' +
        ' WHERE COALESCE(TRIM(%1:s), '''') <> ' +
        '       COALESCE(TRIM(:VENDEDOR), '''')',
        [ATabla, ACampoVendedor]) + sCondicion;
      oConsulta.ParamByName('VENDEDOR').AsString := Trim(oCampo.AsString);
      for i := Low(ACamposClave) to High(ACamposClave) do
        oConsulta.ParamByName('CLAVE' + IntToStr(i)).AsString :=
          ARegistro.FieldByName(ACamposClave[i]).AsString;
      oConsulta.Execute;
      Result := oConsulta.RowsAffected > 0;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

end.
