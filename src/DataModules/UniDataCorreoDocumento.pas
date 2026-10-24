{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataCorreoDocumento                                        }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       22/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Adaptador UniDAC que lee de la cabecera del documento la empresa          }
{    emisora y de fza_tipos_documentos el nombre del tipo de documento.        }
{******************************************************************************}
unit UniDataCorreoDocumento;

interface

uses
  Uni, inLibCorreoTickets, inLibCorreoDocumentoIntf;

function CrearLectorDatosCorreoDocumento(
  AConexion: TUniConnection): ILectorDatosCorreoDocumento;
// SQL de la lectura y valores de :TIPO y :TABLA. Público para la prueba de
// integración con MariaDB (CorreoDocumentoIntegracion).
function SqlDatosCorreoDocumento(ATipo: TTipoDocumentoCorreo;
  out ATipoContador, ATabla: string): string;

implementation

uses
  System.SysUtils, Data.DB, inLibDocumentoIntf, inLibDocumento;

resourcestring
  SErrorTipoDocumentoCorreoSinTabla =
    'El tipo de documento no admite el envío por correo desde impresión.';

type
  TLectorDatosCorreoDocumento = class(
    TInterfacedObject,
    ILectorDatosCorreoDocumento)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function Leer(ATipo: TTipoDocumentoCorreo;
      const ASerie, ANumero: string): TDatosCorreoDocumento;
  end;

function ConfiguracionDocumentoCorreo(
  ATipo: TTipoDocumentoCorreo): TConfiguracionDocumento;
begin
  case ATipo of
    tdcFactura:
      Result := CrearConfiguracionDocumento(tdFactura, sdVenta);
    tdcPresupuesto:
      Result := CrearConfiguracionDocumento(tdPresupuesto, sdVenta);
    tdcPedido:
      Result := CrearConfiguracionDocumento(tdPedido, sdVenta);
    tdcAlbaran:
      Result := CrearConfiguracionDocumento(tdAlbaran, sdVenta);
    tdcPedidoCompra:
      Result := CrearConfiguracionDocumento(tdPedido, sdCompra);
    tdcAlbaranCompra:
      Result := CrearConfiguracionDocumento(tdAlbaran, sdCompra);
    tdcDevolucionCompra:
      Result := CrearConfiguracionDocumento(tdDevolucion, sdCompra);
    tdcFacturaCompra:
      Result := CrearConfiguracionDocumento(tdFactura, sdCompra);
  else
    raise EArgumentException.Create(SErrorTipoDocumentoCorreoSinTabla);
  end;
end;

function SqlDatosCorreoDocumento(ATipo: TTipoDocumentoCorreo;
  out ATipoContador, ATabla: string): string;
var
  oConfiguracion: TConfiguracionDocumento;
  sSufijo: string;
begin
  oConfiguracion := ConfiguracionDocumentoCorreo(ATipo);
  sSufijo := oConfiguracion.PrefijoCabecera;
  ATipoContador := oConfiguracion.TipoContador;
  ATabla := oConfiguracion.TablaCabecera;
  // El código del contador se cruza también con la tabla de origen: un
  // código reutilizado por otro maestro no debe dar nombre al documento.
  Result :=
    'SELECT D.RAZON_SOCIAL_EMPRESA_' + sSufijo + ' AS NOMBRE_EMPRESA,' +
    '       D.EMAIL_EMPRESA_' + sSufijo + ' AS EMAIL_EMPRESA,' +
    '       TD.DESCRIPCION_TIPO_DOCUMENTO_TD AS NOMBRE_DOCUMENTO,' +
    '       E.FORMATO_DOCUMENTO_EMP' +
    '  FROM ' + ATabla + ' D' +
    '  LEFT JOIN fza_empresas E' +
    '    ON E.CODIGO_EMP_EMP = D.CODIGO_EMP_' + sSufijo +
    '  LEFT JOIN fza_tipos_documentos TD' +
    '    ON TD.CODIGO_TIPO_DOCUMENTO_TD = :TIPO' +
    '   AND TD.TABLA_ORIGEN_TIPO_DOCUMENTO_TD = :TABLA' +
    ' WHERE D.SERIE_' + sSufijo + ' = :SERIE' +
    '   AND D.NUMERO_' + sSufijo + ' = :NUMERO';
end;

function CrearLectorDatosCorreoDocumento(
  AConexion: TUniConnection): ILectorDatosCorreoDocumento;
begin
  Result := TLectorDatosCorreoDocumento.Create(AConexion);
end;

constructor TLectorDatosCorreoDocumento.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TLectorDatosCorreoDocumento.Leer(ATipo: TTipoDocumentoCorreo;
  const ASerie, ANumero: string): TDatosCorreoDocumento;
var
  oConsulta: TUniQuery;
  sTabla: string;
  sTipoContador: string;
begin
  Result := Default(TDatosCorreoDocumento);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      SqlDatosCorreoDocumento(ATipo, sTipoContador, sTabla);
    oConsulta.ParamByName('TIPO').AsString := sTipoContador;
    oConsulta.ParamByName('TABLA').AsString := sTabla;
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.Open;
    Result.Encontrado := not oConsulta.IsEmpty;
    if Result.Encontrado then
    begin
      Result.FormatoDocumento :=
        oConsulta.FieldByName('FORMATO_DOCUMENTO_EMP').AsString;
      Result.NombreDocumento := Trim(
        oConsulta.FieldByName('NOMBRE_DOCUMENTO').AsString);
      Result.NombreEmpresa := Trim(
        oConsulta.FieldByName('NOMBRE_EMPRESA').AsString);
      Result.EmailEmpresa := Trim(
        oConsulta.FieldByName('EMAIL_EMPRESA').AsString);
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.
