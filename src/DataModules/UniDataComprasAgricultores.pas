{******************************************************************************}
{  Módulo: UniDataComprasAgricultores. Tipo: Persistencia                      }
{  Fecha: 02/11/2026. Autor: Alejandro Laorden Hidalgo                         }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción: Clientes agricultores como emisores de recibos REAGP.          }
{******************************************************************************}
unit UniDataComprasAgricultores;

interface

uses
  Data.DB, Uni;

const
  SQL_CLIENTES_AGRICULTORES =
    'SELECT C.CODIGO_CLI_CLI AS CODIGO_PRV_PRV, ' +
    'C.RAZON_SOCIAL_CLI AS NOMBRE_PRV, ' +
    'C.RAZON_SOCIAL_CLI AS RAZON_SOCIAL_PRV, C.NIF_CLI AS NIF_PRV, ' +
    'C.MOVIL_CLI AS MOVIL_PRV, C.EMAIL_CLI AS EMAIL_PRV, ' +
    'C.CODIGO_FP_CLI AS CODIGO_FP_PRV, ' +
    'C.CODIGO_EMPBAN_CLI AS CODIGO_EMPBAN_PRV, ' +
    'C.ESACTIVO_CLI AS ESACTIVO_PRV ' +
    'FROM fza_clientes C ' +
    'WHERE C.ESREGIMENESPECIALAGRICOLA_CLI=''S'' ' +
    'AND C.ESACTIVO_CLI=''S'' ORDER BY C.RAZON_SOCIAL_CLI';

function EsReciboAgricola(ACabecera: TDataSet): Boolean;
function CampoEmisorCompra(ACabecera: TDataSet): string;
function EsAgricolaHistorico(ACabecera: TDataSet): Boolean;
procedure ValidarAgricultorCompra(AConexion: TUniConnection;
  ACabecera: TDataSet);
procedure CopiarDatosAgricultorCompra(AConexion: TUniConnection;
  ACabecera: TDataSet);
// El llamador libera la consulta después de cerrar la búsqueda.
function ConsultarArticulosAgricultor(AConexion: TUniConnection): TDataSet;

implementation

uses
  System.SysUtils, System.Variants, inLibErroresBBDD, inLibMsgCompras;

function ConsultarArticulosAgricultor(AConexion: TUniConnection): TDataSet;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := 'SELECT CODIGO_ART_ART, DESCRIPCION_ART, ' +
      'CODIGO_FAM_ART, TIPO_IVA_ART, TIPO_CANTIDAD_ART ' +
      'FROM fza_articulos WHERE ESACTIVO_ART=''S'' ' +
      'ORDER BY ORDEN_ART, CODIGO_ART_ART';
    oConsulta.Open;
    Result := oConsulta;
  except
    FreeAndNil(oConsulta);
    raise;
  end;
end;

function EsReciboAgricola(ACabecera: TDataSet): Boolean;
begin
  Result := Assigned(ACabecera) and ACabecera.Active and
    (ACabecera.FieldByName('MODALIDAD_FACC').AsString = 'REAGP');
end;

function EsAgricolaHistorico(ACabecera: TDataSet): Boolean;
begin
  // Los recibos anteriores conservan su proveedor y su identidad fiscal.
  Result := EsReciboAgricola(ACabecera) and
    (ACabecera.State <> dsInsert) and
    (Trim(ACabecera.FieldByName('CODIGO_CLI_FACC').AsString) = '') and
    (StrToInt64Def(ACabecera.FieldByName('NUMERO_FACC').AsString, 0) > 0);
  if Result and (ACabecera.State = dsEdit) then
    Result :=
      (VarToStr(ACabecera.FieldByName('CODIGO_CLI_FACC').OldValue) = '') and
      (VarToStr(ACabecera.FieldByName('MODALIDAD_FACC').OldValue) = 'REAGP')
      and (StrToInt64Def(VarToStr(ACabecera.FieldByName(
        'NUMERO_FACC').OldValue), 0) > 0);
end;

function CampoEmisorCompra(ACabecera: TDataSet): string;
begin
  Result := 'CODIGO_PRV_FACC';
  if EsReciboAgricola(ACabecera) and
     not EsAgricolaHistorico(ACabecera) then
    Result := 'CODIGO_CLI_FACC';
end;

procedure ValidarAgricultorCompra(AConexion: TUniConnection;
  ACabecera: TDataSet);
var
  oConsulta: TUniQuery;
begin
  if EsReciboAgricola(ACabecera) and
     not EsAgricolaHistorico(ACabecera) then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      oConsulta.SQL.Text := 'SELECT 1 FROM fza_clientes ' +
        'WHERE CODIGO_CLI_CLI=:CLIENTE ' +
        'AND ESREGIMENESPECIALAGRICOLA_CLI=''S'' AND ESACTIVO_CLI=''S''';
      oConsulta.ParamByName('CLIENTE').AsString :=
        ACabecera.FieldByName('CODIGO_CLI_FACC').AsString;
      oConsulta.Open;
      if oConsulta.IsEmpty then
        raise EValidacionBBDD.Create(SClienteAgricultorObligatorio);
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

procedure CopiarDatosAgricultorCompra(AConexion: TUniConnection;
  ACabecera: TDataSet);
const
  CAMPOS: array[0..10] of string = (
    'RAZON_SOCIAL', 'NIF', 'MOVIL', 'EMAIL', 'DIRECCION1', 'DIRECCION2',
    'POBLACION', 'PROVINCIA', 'CODIGO_PAI', 'NOMBRE_PAI', 'CODIGO_POSTAL');
var
  oConsulta: TUniQuery;
  sCampo: string;
  oCliente: TField;
begin
  oCliente := ACabecera.FieldByName('CODIGO_CLI_FACC');
  if (ACabecera.State = dsInsert) or
     (oCliente.AsString <> VarToStr(oCliente.OldValue)) or
     (Trim(ACabecera.FieldByName('RAZON_SOCIAL_PRV_FACC').AsString) = '') then
  begin
    ValidarAgricultorCompra(AConexion, ACabecera);
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      oConsulta.SQL.Text := 'SELECT RAZON_SOCIAL_CLI, NIF_CLI, ' +
        'MOVIL_CLI, EMAIL_CLI, DIRECCION1_CLI, DIRECCION2_CLI, ' +
        'POBLACION_CLI, PROVINCIA_CLI, CODIGO_PAI_CLI, NOMBRE_PAI_CLI, ' +
        'CODIGO_POSTAL_CLI, IBAN_CLI, CODIGO_FP_CLI FROM fza_clientes ' +
        'WHERE CODIGO_CLI_CLI=:CLIENTE';
      oConsulta.ParamByName('CLIENTE').AsString := oCliente.AsString;
      oConsulta.Open;
      for sCampo in CAMPOS do
        ACabecera.FieldByName(sCampo + '_PRV_FACC').Value :=
          oConsulta.FieldByName(sCampo + '_CLI').Value;
      ACabecera.FieldByName('IBAN_FACC').Value :=
        oConsulta.FieldByName('IBAN_CLI').Value;
      ACabecera.FieldByName('FORMA_PAGO_FACC').Value :=
        oConsulta.FieldByName('CODIGO_FP_CLI').Value;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

end.
