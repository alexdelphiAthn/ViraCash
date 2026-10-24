{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataClientesAltaRapida                                     }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Alta rápida con los contadores y valores por defecto de clientes.        }
{******************************************************************************}
unit UniDataClientesAltaRapida;

interface

uses
  Uni, inLibClientesPersistenciaIntf;

function CrearAltaRapidaClientesUniDAC(
  AConexion: TUniConnection): IAltaRapidaClientes;

implementation

uses
  System.SysUtils, System.Generics.Collections, Data.DB,
  inLibClientesAltaRapida, inLibDocumentoFiscal,
  UniDataValoresAutomaticosRepositorio;

const
  fCodigo = 'CODIGO_CLI_CLI';
  fRazonSocial = 'RAZON_SOCIAL_CLI';
  fNif = 'NIF_CLI';
  fDireccion = 'DIRECCION1_CLI';
  fCodigoPostal = 'CODIGO_POSTAL_CLI';
  fPoblacion = 'POBLACION_CLI';
  fProvincia = 'PROVINCIA_CLI';
  fCodigoPais = 'CODIGO_PAI_CLI';
  fNombrePais = 'NOMBRE_PAI_CLI';
  SQL_CLIENTE_VACIO =
    'SELECT CODIGO_CLI_CLI, ESACTIVO_CLI, ORDEN_CLI, ' +
    'RAZON_SOCIAL_CLI, NIF_CLI, DIRECCION1_CLI, DIRECCION2_CLI, ' +
    'CODIGO_POSTAL_CLI, POBLACION_CLI, PROVINCIA_CLI, ' +
    'CODIGO_PAI_CLI, NOMBRE_PAI_CLI, ESIVA_RECARGO_CLI, ' +
    'ESRETENCIONES_CLI, ESIVA_EXENTO_CLI, ESINTRACOMUNITARIO_CLI, ' +
    'ESREGIMENESPECIALAGRICOLA_CLI, TOTAL_LIMITE_CREDITO_CLI, ' +
    'ESPERMITE_DEUDA_CLI, TOTAL_DEUDA_CLI, CODIGO_FP_CLI, ' +
    'TARIFA_ARTICULO_CLI, SERIE_CON_CLI, TEXTO_LEGAL_FACTURA_CLI, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF ' +
    'FROM fza_clientes WHERE 1 = 0';

type
  TAltaRapidaClientesUniDAC = class(TInterfacedObject, IAltaRapidaClientes)
  private
    FConexion: TUniConnection;
    procedure PrepararCliente(AConsulta: TUniQuery;
      const AUsuario, ATarifa: string);
    procedure AsignarDatos(AConsulta: TUniQuery;
      const ADatos: TDatosAltaRapidaCliente);
    function InsertarCliente(const ADatos: TDatosAltaRapidaCliente;
      const AUsuario, ATarifa: string): string;
  public
    constructor Create(AConexion: TUniConnection);
    function ConsultarPaises: TArray<TPaisAltaRapidaCliente>;
    function CrearCliente(const ADatos: TDatosAltaRapidaCliente;
      const AUsuario, ATarifa: string): string;
  end;

constructor TAltaRapidaClientesUniDAC.Create(AConexion: TUniConnection);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TAltaRapidaClientesUniDAC.ConsultarPaises:
  TArray<TPaisAltaRapidaCliente>;
var
  oConsulta: TUniQuery;
  oPaises: TList<TPaisAltaRapidaCliente>;
  oPais: TPaisAltaRapidaCliente;
begin
  oPaises := TList<TPaisAltaRapidaCliente>.Create;
  try
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text :=
        'SELECT CODIGO_PAI_PAI, NOMBRE_SPA_PAI ' +
        'FROM fza_paises ORDER BY ORDEN_PAI, NOMBRE_SPA_PAI';
      oConsulta.Open;
      while not oConsulta.Eof do
      begin
        oPais.Codigo := oConsulta.FieldByName('CODIGO_PAI_PAI').AsString;
        oPais.Nombre := oConsulta.FieldByName('NOMBRE_SPA_PAI').AsString;
        oPaises.Add(oPais);
        oConsulta.Next;
      end;
      Result := oPaises.ToArray;
    finally
      FreeAndNil(oConsulta);
    end;
  finally
    FreeAndNil(oPaises);
  end;
end;

procedure TAltaRapidaClientesUniDAC.PrepararCliente(
  AConsulta: TUniQuery; const AUsuario, ATarifa: string);
begin
  AConsulta.Connection := FConexion;
  AConsulta.SQL.Text := SQL_CLIENTE_VACIO;
  AConsulta.Open;
  AConsulta.Append;
  AplicarValoresPorDefecto(FConexion, AConsulta, 'fza_clientes');
  AConsulta.FieldByName(fCodigo).AsString :=
    ObtenerSiguienteContador(FConexion, 'CL', AUsuario);
  AConsulta.FieldByName('ORDEN_CLI').AsString :=
    ObtenerSiguienteContador(FConexion, 'CO', AUsuario);
  AConsulta.FieldByName('ESACTIVO_CLI').AsString := 'S';
  AConsulta.FieldByName('CODIGO_FP_CLI').AsString :=
    ObtenerValorPorDefecto(FConexion, 'fza_formas_pago',
      'CODIGO_FP_FP', 'ESDEFAULT_FORMA_PAGO_FP');
  AConsulta.FieldByName('TARIFA_ARTICULO_CLI').AsString := ATarifa;
  AConsulta.FieldByName('INSTANTE_ALTA').AsDateTime := Now;
  AConsulta.FieldByName('INSTANTE_MODIF').AsDateTime := Now;
  AConsulta.FieldByName('USUARIO_ALTA').AsString := AUsuario;
  AConsulta.FieldByName('USUARIO_MODIF').AsString := AUsuario;
end;

procedure TAltaRapidaClientesUniDAC.AsignarDatos(AConsulta: TUniQuery;
  const ADatos: TDatosAltaRapidaCliente);
var
  sNif: string;
begin
  sNif := Trim(ADatos.Nif);
  if PaisEsEspana(ADatos.Pais.Codigo, ADatos.Pais.Nombre) then
    sNif := LimpiarDocumentoFiscal(sNif);
  AConsulta.FieldByName(fRazonSocial).AsString := Trim(ADatos.RazonSocial);
  AConsulta.FieldByName(fNif).AsString := sNif;
  AConsulta.FieldByName(fDireccion).AsString := Trim(ADatos.Direccion);
  AConsulta.FieldByName(fCodigoPostal).AsString := Trim(ADatos.CodigoPostal);
  AConsulta.FieldByName(fPoblacion).AsString := Trim(ADatos.Poblacion);
  AConsulta.FieldByName(fProvincia).AsString := Trim(ADatos.Provincia);
  AConsulta.FieldByName(fCodigoPais).AsString := ADatos.Pais.Codigo;
  AConsulta.FieldByName(fNombrePais).AsString := ADatos.Pais.Nombre;
end;

function TAltaRapidaClientesUniDAC.InsertarCliente(
  const ADatos: TDatosAltaRapidaCliente;
  const AUsuario, ATarifa: string): string;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    PrepararCliente(oConsulta, AUsuario, ATarifa);
    AsignarDatos(oConsulta, ADatos);
    oConsulta.Post;
    Result := oConsulta.FieldByName(fCodigo).AsString;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TAltaRapidaClientesUniDAC.CrearCliente(
  const ADatos: TDatosAltaRapidaCliente;
  const AUsuario, ATarifa: string): string;
var
  sError: string;
  bTransaccionPropia: Boolean;
begin
  sError := ErrorDatosAltaRapidaCliente(ADatos);
  if sError <> '' then
    raise EArgumentException.Create(sError);
  bTransaccionPropia := not FConexion.InTransaction;
  if bTransaccionPropia then
    FConexion.StartTransaction;
  try
    Result := InsertarCliente(ADatos, AUsuario, ATarifa);
    if bTransaccionPropia then
      FConexion.Commit;
  except
    if bTransaccionPropia then
      FConexion.Rollback;
    raise;
  end;
end;

function CrearAltaRapidaClientesUniDAC(
  AConexion: TUniConnection): IAltaRapidaClientes;
begin
  Result := TAltaRapidaClientesUniDAC.Create(AConexion);
end;

end.
