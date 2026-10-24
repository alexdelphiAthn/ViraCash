{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataComprasSesionesDocumentosComun                        }
{    Tipo:       Repositorio                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Consulta común de líneas para documentos de compra materializados.        }
{******************************************************************************}
unit UniDataComprasSesionesDocumentosComun;

interface

uses
  Uni,
  inLibComprasSesionesLecturasIntf;

function ConsultarLineasDocumentoCompra(
  const ALecturas: ILecturasDocumentosMaterializacion;
  const ASerieSesion, ANumeroSesion, AAlmacenCabecera,
  AFiltroAlmacen: string;
  AExigirTrazabilidad: Boolean = True):
  TLineasDocumentoCompraMaterializacion;

// Siguiente número del contador (tipo, empresa, serie) del documento, el
// mismo que usa el alta a mano; '' si no lo hay. Sin COMMIT propio: queda
// dentro de la transacción de la materialización (FZ-ISSUE-141).
function ReservarNumeroDocumentoSesion(AConn: TUniConnection;
  const ATipoDocumento, AEmpresa, ASerie, AUsuario: string): string;

implementation

uses
  System.SysUtils, Data.DB, inLibComprasSesionesTrazabilidad;

const
  // Como PRC_GET_NEXT_CONT_FACT_SERIE: la serie sin contador lo estrena
  // con 6 dígitos. Ese SP no vale aquí porque hace START TRANSACTION.
  SQL_ASEGURAR_CONTADOR =
    'INSERT INTO fza_contadores ' +
    '  (TIPO_DOC_CON, EMPRESA_CON, SERIE_CON, CON, NUM_DIGITOS_CON, ' +
    '   ESACTIVO_CON, DEFAULT_CON, INSTANTE_ALTA, USUARIO_ALTA, ' +
    '   USUARIO_MODIF) ' +
    'VALUES (:tipo, :emp, :serie, 1, 6, ''S'', ''N'', NOW(), :u, :u) ' +
    'ON DUPLICATE KEY UPDATE CON = CON';

function ValorOGuion(const AValor: string): string;
begin
  Result := Trim(AValor);
  if Result = '' then
    Result := '-';
end;

function ReservarNumeroDocumentoSesion(AConn: TUniConnection;
  const ATipoDocumento, AEmpresa, ASerie, AUsuario: string): string;
var
  oConsulta: TUniQuery;
  oProcedimiento: TUniStoredProc;
  iNumero: Int64;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConn;
    oConsulta.SQL.Text := SQL_ASEGURAR_CONTADOR;
    oConsulta.ParamByName('tipo').AsString := ATipoDocumento;
    oConsulta.ParamByName('emp').AsString := ValorOGuion(AEmpresa);
    oConsulta.ParamByName('serie').AsString := ValorOGuion(ASerie);
    oConsulta.ParamByName('u').AsString := AUsuario;
    oConsulta.ExecSQL;
  finally
    FreeAndNil(oConsulta);
  end;
  oProcedimiento := TUniStoredProc.Create(nil);
  try
    oProcedimiento.Connection := AConn;
    oProcedimiento.StoredProcName := 'PRC_GET_NEXT_CONTADOR';
    oProcedimiento.Params.Clear;
    oProcedimiento.Params.CreateParam(
      ftString, 'pTipoDoc', ptInput).AsString := ATipoDocumento;
    oProcedimiento.Params.CreateParam(
      ftString, 'pEmpresa', ptInput).AsString := ValorOGuion(AEmpresa);
    oProcedimiento.Params.CreateParam(
      ftString, 'pSerie', ptInput).AsString := ValorOGuion(ASerie);
    oProcedimiento.Params.CreateParam(
      ftString, 'pUsuario', ptInput).AsString := AUsuario;
    oProcedimiento.Params.CreateParam(ftString, 'pContador', ptOutput);
    oProcedimiento.ExecProc;
    Result := Trim(oProcedimiento.ParamByName('pContador').AsString);
  finally
    FreeAndNil(oProcedimiento);
  end;
  if not (TryStrToInt64(Result, iNumero) and (iNumero > 0)) then
    Result := '';
end;

function ConsultarLineasDocumentoCompra(
  const ALecturas: ILecturasDocumentosMaterializacion;
  const ASerieSesion, ANumeroSesion, AAlmacenCabecera,
  AFiltroAlmacen: string;
  AExigirTrazabilidad: Boolean):
  TLineasDocumentoCompraMaterializacion;
begin
  Result := PrepararTrazabilidadSesion(ALecturas.ConsultarLineasDocumento(
    ASerieSesion,
    ANumeroSesion,
    AAlmacenCabecera,
    ''), AFiltroAlmacen, AExigirTrazabilidad);
end;


end.
