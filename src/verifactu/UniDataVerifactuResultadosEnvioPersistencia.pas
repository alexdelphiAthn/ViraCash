{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataVerifactuResultadosEnvioPersistencia                  }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Adapta a UniDAC resultados y estados de los envíos Verifactu.             }
{******************************************************************************}
unit UniDataVerifactuResultadosEnvioPersistencia;

interface

uses
  Uni, UniDataVerifactuResultadosEnvioOperacion;

function CrearOperacionResultadosEnvioVerifactuUniDAC(
  AConexion: TUniConnection): TOperacionResultadosEnvioVerifactu;

implementation

uses
  System.SysUtils, System.Classes, Data.DB, inLibVerifactu,
  UniDataVerifactuSubsanacionResultados;

type
  TPersistenciaResultadosEnvioVerifactuUniDAC = class(
    TInterfacedObject,
    IPersistenciaResultadoEnvioVerifactu,
    IPersistenciaEstadoEnvioVerifactu)
  private
    FConexion: TUniConnection;
    function CrearConsulta: TUniQuery;
    procedure AsignarResultadoComun(
      AQry: TUniQuery;
      const AEntrada: TEntradaResultadoEnvioVerifactu);
    procedure PrepararAlta(AQry: TUniQuery);
    procedure PrepararActualizacionAlta(AQry: TUniQuery);
    function ExisteConsolidacion(const ASerie, ANumero: string): Boolean;
    procedure AsignarAlta(
      AQry: TUniQuery;
      const AEntrada: TEntradaResultadoEnvioVerifactu;
      const APlan: TPlanResultadoEnvioVerifactu);
    procedure GuardarAlta(
      const AEntrada: TEntradaResultadoEnvioVerifactu;
      const APlan: TPlanResultadoEnvioVerifactu);
    procedure GuardarAnulacion(
      const AEntrada: TEntradaResultadoEnvioVerifactu;
      const APlan: TPlanResultadoEnvioVerifactu);
    procedure GuardarSubsanacion(
      const AEntrada: TEntradaResultadoEnvioVerifactu;
      const APlan: TPlanResultadoEnvioVerifactu);
  public
    constructor Create(AConexion: TUniConnection);
    function EstaColaEnviada(AIdCola: Int64): Boolean;
    procedure ActualizarCadena(
      const AEntrada: TEntradaResultadoEnvioVerifactu);
    procedure GuardarResultado(
      const AEntrada: TEntradaResultadoEnvioVerifactu;
      const APlan: TPlanResultadoEnvioVerifactu);
    procedure ActualizarFactura(
      const AEntrada: TEntradaResultadoEnvioVerifactu;
      const APlan: TPlanResultadoEnvioVerifactu);
    procedure MarcarColaEnviada(
      const AEntrada: TEntradaResultadoEnvioVerifactu);
    procedure GuardarError(
      const AEntrada: TEntradaErrorEnvioVerifactu;
      const APlan: TPlanErrorEnvioVerifactu);
  end;

function CrearOperacionResultadosEnvioVerifactuUniDAC(
  AConexion: TUniConnection): TOperacionResultadosEnvioVerifactu;
var
  oEstados: IPersistenciaEstadoEnvioVerifactu;
  oPersistencia: TPersistenciaResultadosEnvioVerifactuUniDAC;
  oResultados: IPersistenciaResultadoEnvioVerifactu;
begin
  oPersistencia := TPersistenciaResultadosEnvioVerifactuUniDAC.Create(
    AConexion);
  oResultados := oPersistencia;
  oEstados := oPersistencia;
  Result := TOperacionResultadosEnvioVerifactu.Create(
    oResultados,
    oEstados);
end;

constructor TPersistenciaResultadosEnvioVerifactuUniDAC.Create(
  AConexion: TUniConnection);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
end;

function TPersistenciaResultadosEnvioVerifactuUniDAC.CrearConsulta:
  TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

procedure TPersistenciaResultadosEnvioVerifactuUniDAC.
  AsignarResultadoComun(
  AQry: TUniQuery;
  const AEntrada: TEntradaResultadoEnvioVerifactu);
begin
  AQry.ParamByName('CHAINNUM').AsString :=
    AEntrada.Resultado.ChainNumber;
  AQry.ParamByName('CHAINHASH').AsString := AEntrada.Resultado.ChainHash;
  AQry.ParamByName('RESPUESTA').AsString :=
    AEntrada.Resultado.RespuestaCompleta;
  AQry.ParamByName('PETICION').AsString :=
    AEntrada.Resultado.PeticionCompleta;
  AQry.ParamByName('REGISTROXML').AsString :=
    AEntrada.Resultado.RegistroXmlFirmado;
  AQry.ParamByName('FIRMA').AsString := AEntrada.Resultado.FirmaDigital;
  AQry.ParamByName('SERIECERT').AsString :=
    AEntrada.Resultado.SerieCertificado;
  AQry.ParamByName('TITULARCERT').AsString :=
    AEntrada.Resultado.TitularCertificado;
  AQry.ParamByName('HUELLACERT').AsString :=
    AEntrada.Resultado.HuellaCertificado;
end;

function TPersistenciaResultadosEnvioVerifactuUniDAC.EstaColaEnviada(
  AIdCola: Int64): Boolean;
var
  oQry: TUniQuery;
begin
  oQry := CrearConsulta;
  try
    oQry.SQL.Text :=
      ' SELECT ESTADO_VFCOLA ' +
      ' FROM fza_verifactu_cola ' +
      ' WHERE ID_VFCOLA = :ID';
    oQry.ParamByName('ID').AsLargeInt := AIdCola;
    oQry.Open;
    Result := not oQry.Eof;
    if Result then
      Result := SameText(oQry.Fields[0].AsString, 'ENVIADA');
  finally
    FreeAndNil(oQry);
  end;
end;

procedure TPersistenciaResultadosEnvioVerifactuUniDAC.ActualizarCadena(
  const AEntrada: TEntradaResultadoEnvioVerifactu);
var
  oQry: TUniQuery;
begin
  oQry := CrearConsulta;
  try
    oQry.SQL.Text :=
      ' UPDATE fza_verifactu_cadena ' +
      ' SET CONTADOR_VFCAD = :CONTADOR, SERIE_FAC_VFCAD = :SERIE, ' +
      '     NUMERO_FAC_VFCAD = :NUMERO, ' +
      '     FECHA_FAC_VFCAD = STR_TO_DATE(:FECHA, ''%d-%m-%Y''), ' +
      '     HUELLA_VFCAD = :HUELLA, INSTANTE_MODIF = NOW(), ' +
      '     USUARIO_MODIF = :USUARIO ' +
      ' WHERE NIF_VFCAD = :NIF';
    oQry.ParamByName('CONTADOR').AsString :=
      AEntrada.Resultado.ChainNumber;
    oQry.ParamByName('SERIE').AsString := AEntrada.Serie;
    oQry.ParamByName('NUMERO').AsString := AEntrada.Numero;
    oQry.ParamByName('FECHA').AsString :=
      AEntrada.Resultado.FechaExpedicion;
    oQry.ParamByName('HUELLA').AsString := AEntrada.Resultado.ChainHash;
    oQry.ParamByName('USUARIO').AsString := AEntrada.Usuario;
    oQry.ParamByName('NIF').AsString := AEntrada.Resultado.IssuerIrsId;
    oQry.Execute;
  finally
    FreeAndNil(oQry);
  end;
end;

procedure TPersistenciaResultadosEnvioVerifactuUniDAC.GuardarAnulacion(
  const AEntrada: TEntradaResultadoEnvioVerifactu;
  const APlan: TPlanResultadoEnvioVerifactu);
var
  oQry: TUniQuery;
begin
  oQry := CrearConsulta;
  try
    // VERIFACTU_ANULADO o SII_ANULADO, según el sistema de la fila
    oQry.SQL.Text :=
      ' UPDATE fza_facturas_consolidaciones ' +
      ' SET QUEUE_ID_CANCEL_FACCON = :IDCOLA, ' +
      '     ESTADO_FACCON = :ESTADO, ' +
      '     CHAIN_NUMBER_FACCON = :CHAINNUM, ' +
      '     CHAIN_HASH_FACCON = :CHAINHASH, ' +
      '     RESPUESTA_COMPLETA_FACCON = :RESPUESTA, ' +
      '     PETICION_COMPLETA_FACCON = :PETICION, ' +
      '     REGISTRO_XML_FACCON = :REGISTROXML, ' +
      '     FIRMA_DIGITAL_FACCON = :FIRMA, ' +
      '     SERIE_CERTIFICADO_FACCON = :SERIECERT, ' +
      '     TITULAR_CERTIFICADO_FACCON = :TITULARCERT, ' +
      '     HUELLA_CERTIFICADO_FACCON = :HUELLACERT, ' +
      '     FECHA_PROCESAMIENTO_FACCON = NOW() ' +
      ' WHERE SERIE_FAC_FACCON = :SERIE ' +
      '   AND NUMERO_FAC_FACCON = :NUMERO';
    oQry.ParamByName('IDCOLA').AsLargeInt := AEntrada.IdCola;
    oQry.ParamByName('ESTADO').AsString := APlan.EstadoConsolidacion;
    AsignarResultadoComun(oQry, AEntrada);
    oQry.ParamByName('SERIE').AsString := AEntrada.Serie;
    oQry.ParamByName('NUMERO').AsString := AEntrada.Numero;
    oQry.Execute;
  finally
    FreeAndNil(oQry);
  end;
end;

procedure TPersistenciaResultadosEnvioVerifactuUniDAC.GuardarSubsanacion(
  const AEntrada: TEntradaResultadoEnvioVerifactu;
  const APlan: TPlanResultadoEnvioVerifactu);
begin
  GuardarResultadoSubsanacion(
    FConexion,
    AEntrada.IdCola,
    AEntrada.Serie,
    AEntrada.Numero,
    AEntrada.Usuario,
    APlan.EstadoConsolidacion,
    AEntrada.Resultado);
end;

procedure TPersistenciaResultadosEnvioVerifactuUniDAC.PrepararAlta(
  AQry: TUniQuery);
begin
  AQry.SQL.Text :=
    ' INSERT INTO fza_facturas_consolidaciones ' +
    ' (ID_FACCON, SERIE_FAC_FACCON, NUMERO_FAC_FACCON, ' +
    '  REQUEST_ID_CONSOLIDACION_FACCON, ' +
    '  QUEUE_ID_CONSOLIDACION_FACCON, ' +
    '  ISSUER_IRS_ID_CONSOLIDACION_FACCON, ISSUED_TIME_FACCON, ' +
    '  CHAIN_NUMBER_FACCON, CHAIN_HASH_FACCON, ' +
    '  VERIFACTU_URL_FACCON, QRCODE_BASE64_FACCON, ' +
    '  QRCODE_PNG_FACCON, FECHA_PROCESAMIENTO_FACCON, ' +
    '  ESTADO_FACCON, CODIGO_ERROR_AEAT_FACCON, ' +
    '  DESCRIPCION_ERROR_AEAT_FACCON, ' +
    '  RESPUESTA_COMPLETA_FACCON, PETICION_COMPLETA_FACCON, ' +
    '  REGISTRO_XML_FACCON, FIRMA_DIGITAL_FACCON, ' +
    '  SERIE_CERTIFICADO_FACCON, TITULAR_CERTIFICADO_FACCON, ' +
    '  HUELLA_CERTIFICADO_FACCON) ' +
    ' SELECT IFNULL(MAX(ID_FACCON), 0) + 1, :SERIE, :NUMERO, ' +
    '        NULLIF(:REQUESTID, ''''), :IDCOLA, ' +
    '        NULLIF(:ISSUERID, ''''), :ISSUEDTIME, ' +
    '        NULLIF(:CHAINNUM, ''''), NULLIF(:CHAINHASH, ''''), ' +
    '        NULLIF(:URL, ''''), NULLIF(:QRBASE64, ''''), ' +
    '        :QRPNG, NOW(), :ESTADO, NULLIF(:CODERROR, ''''), ' +
    '        NULLIF(:DESCERROR, ''''), NULLIF(:RESPUESTA, ''''), ' +
    '        NULLIF(:PETICION, ''''), :REGISTROXML, :FIRMA, ' +
    '        :SERIECERT, :TITULARCERT, :HUELLACERT ' +
    ' FROM fza_facturas_consolidaciones';
end;

procedure TPersistenciaResultadosEnvioVerifactuUniDAC.
  PrepararActualizacionAlta(AQry: TUniQuery);
begin
  // Mismos parámetros que PrepararAlta, sobre la fila (SERIE, NUMERO)
  AQry.SQL.Text :=
    ' UPDATE fza_facturas_consolidaciones ' +
    ' SET REQUEST_ID_CONSOLIDACION_FACCON = NULLIF(:REQUESTID, ''''), ' +
    '     QUEUE_ID_CONSOLIDACION_FACCON = :IDCOLA, ' +
    '     ISSUER_IRS_ID_CONSOLIDACION_FACCON = NULLIF(:ISSUERID, ''''), ' +
    '     ISSUED_TIME_FACCON = :ISSUEDTIME, ' +
    '     CHAIN_NUMBER_FACCON = NULLIF(:CHAINNUM, ''''), ' +
    '     CHAIN_HASH_FACCON = NULLIF(:CHAINHASH, ''''), ' +
    '     VERIFACTU_URL_FACCON = NULLIF(:URL, ''''), ' +
    '     QRCODE_BASE64_FACCON = NULLIF(:QRBASE64, ''''), ' +
    '     QRCODE_PNG_FACCON = :QRPNG, ' +
    '     FECHA_PROCESAMIENTO_FACCON = NOW(), ' +
    '     ESTADO_FACCON = :ESTADO, ' +
    '     CODIGO_ERROR_AEAT_FACCON = NULLIF(:CODERROR, ''''), ' +
    '     DESCRIPCION_ERROR_AEAT_FACCON = NULLIF(:DESCERROR, ''''), ' +
    '     RESPUESTA_COMPLETA_FACCON = NULLIF(:RESPUESTA, ''''), ' +
    '     PETICION_COMPLETA_FACCON = NULLIF(:PETICION, ''''), ' +
    '     REGISTRO_XML_FACCON = :REGISTROXML, ' +
    '     FIRMA_DIGITAL_FACCON = :FIRMA, ' +
    '     SERIE_CERTIFICADO_FACCON = :SERIECERT, ' +
    '     TITULAR_CERTIFICADO_FACCON = :TITULARCERT, ' +
    '     HUELLA_CERTIFICADO_FACCON = :HUELLACERT ' +
    ' WHERE SERIE_FAC_FACCON = :SERIE ' +
    '   AND NUMERO_FAC_FACCON = :NUMERO';
end;

function TPersistenciaResultadosEnvioVerifactuUniDAC.ExisteConsolidacion(
  const ASerie, ANumero: string): Boolean;
var
  oQry: TUniQuery;
begin
  oQry := CrearConsulta;
  try
    oQry.SQL.Text :=
      ' SELECT 1 FROM fza_facturas_consolidaciones ' +
      ' WHERE SERIE_FAC_FACCON = :SERIE ' +
      '   AND NUMERO_FAC_FACCON = :NUMERO ' +
      ' LIMIT 1';
    oQry.ParamByName('SERIE').AsString := ASerie;
    oQry.ParamByName('NUMERO').AsString := ANumero;
    oQry.Open;
    Result := not oQry.IsEmpty;
  finally
    FreeAndNil(oQry);
  end;
end;

procedure TPersistenciaResultadosEnvioVerifactuUniDAC.AsignarAlta(
  AQry: TUniQuery;
  const AEntrada: TEntradaResultadoEnvioVerifactu;
  const APlan: TPlanResultadoEnvioVerifactu);
var
  oPng: TBytesStream;
begin
  AQry.ParamByName('SERIE').AsString := AEntrada.Serie;
  AQry.ParamByName('NUMERO').AsString := AEntrada.Numero;
  AQry.ParamByName('REQUESTID').AsString := AEntrada.Resultado.RequestId;
  AQry.ParamByName('IDCOLA').AsLargeInt := AEntrada.IdCola;
  AQry.ParamByName('ISSUERID').AsString :=
    AEntrada.Resultado.IssuerIrsId;
  AQry.ParamByName('ISSUEDTIME').DataType := ftDateTime;
  if AEntrada.Resultado.IssuedTime > 0 then
    AQry.ParamByName('ISSUEDTIME').AsDateTime :=
      AEntrada.Resultado.IssuedTime
  else
    AQry.ParamByName('ISSUEDTIME').Clear;
  AQry.ParamByName('URL').AsString := AEntrada.Resultado.VerifactuUrl;
  AQry.ParamByName('QRBASE64').AsString :=
    AEntrada.Resultado.QRCodeBase64;
  AQry.ParamByName('QRPNG').DataType := ftBlob;
  if Length(AEntrada.Resultado.QRCodePng) > 0 then
  begin
    oPng := TBytesStream.Create(AEntrada.Resultado.QRCodePng);
    try
      AQry.ParamByName('QRPNG').LoadFromStream(oPng, ftBlob);
    finally
      FreeAndNil(oPng);
    end;
  end
  else
    AQry.ParamByName('QRPNG').Clear;
  AQry.ParamByName('ESTADO').AsString := APlan.EstadoConsolidacion;
  AsignarResultadoComun(AQry, AEntrada);
  AQry.ParamByName('CODERROR').AsString := AEntrada.Resultado.CodigoError;
  AQry.ParamByName('DESCERROR').AsString :=
    AEntrada.Resultado.DescripcionError;
end;

procedure TPersistenciaResultadosEnvioVerifactuUniDAC.GuardarAlta(
  const AEntrada: TEntradaResultadoEnvioVerifactu;
  const APlan: TPlanResultadoEnvioVerifactu);
var
  oQry: TUniQuery;
begin
  oQry := CrearConsulta;
  try
    // Antes se insertaba siempre: un reenvío contestado como duplicado
    // chocaba con UK_FACTURA y la fila se reenviaba sin fin (FZ-ISSUE-319)
    case DecidirAltaConsolidacion(
      ExisteConsolidacion(AEntrada.Serie, AEntrada.Numero),
      AEntrada.Resultado.EstadoRegistro) of
      aacInsertar:
        begin
          PrepararAlta(oQry);
          AsignarAlta(oQry, AEntrada, APlan);
          oQry.Execute;
        end;
      aacActualizar:
        begin
          PrepararActualizacionAlta(oQry);
          AsignarAlta(oQry, AEntrada, APlan);
          oQry.Execute;
        end;
      aacConservar:
        ;
    end;
  finally
    FreeAndNil(oQry);
  end;
end;

procedure TPersistenciaResultadosEnvioVerifactuUniDAC.GuardarResultado(
  const AEntrada: TEntradaResultadoEnvioVerifactu;
  const APlan: TPlanResultadoEnvioVerifactu);
begin
  case APlan.TipoResultado of
    trevAlta:
      GuardarAlta(AEntrada, APlan);
    trevAnulacion:
      GuardarAnulacion(AEntrada, APlan);
    trevSubsanacion:
      GuardarSubsanacion(AEntrada, APlan);
  end;
end;

procedure TPersistenciaResultadosEnvioVerifactuUniDAC.ActualizarFactura(
  const AEntrada: TEntradaResultadoEnvioVerifactu;
  const APlan: TPlanResultadoEnvioVerifactu);
var
  oQry: TUniQuery;
begin
  oQry := CrearConsulta;
  try
    oQry.SQL.Text :=
      ' UPDATE fza_facturas ' +
      ' SET ESCONSOLIDADA_FAC = ''S'', INSTANTECONSO_FAC = NOW(), ' +
      '     FASE_FAC = :FASE, INSTANTE_MODIF = NOW(), ' +
      '     USUARIO_MODIF = :USUARIO ' +
      ' WHERE SERIE_FAC = :SERIE ' +
      '   AND NUMERO_FAC = :NUMERO';
    oQry.ParamByName('FASE').AsString := APlan.FaseFactura;
    oQry.ParamByName('USUARIO').AsString := AEntrada.Usuario;
    oQry.ParamByName('SERIE').AsString := AEntrada.Serie;
    oQry.ParamByName('NUMERO').AsString := AEntrada.Numero;
    oQry.Execute;
  finally
    FreeAndNil(oQry);
  end;
end;

procedure TPersistenciaResultadosEnvioVerifactuUniDAC.MarcarColaEnviada(
  const AEntrada: TEntradaResultadoEnvioVerifactu);
var
  oQry: TUniQuery;
begin
  oQry := CrearConsulta;
  try
    oQry.SQL.Text :=
      ' UPDATE fza_verifactu_cola ' +
      ' SET ESTADO_VFCOLA = ''ENVIADA'', ' +
      '     INSTANTE_ENVIO_VFCOLA = NOW(), ' +
      '     MENSAJE_ERROR_VFCOLA = NULLIF(:MENSAJE, ''''), ' +
      '     INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO ' +
      ' WHERE ID_VFCOLA = :ID';
    oQry.ParamByName('MENSAJE').AsString :=
      AEntrada.Resultado.MensajeError;
    oQry.ParamByName('USUARIO').AsString := AEntrada.Usuario;
    oQry.ParamByName('ID').AsLargeInt := AEntrada.IdCola;
    oQry.Execute;
  finally
    FreeAndNil(oQry);
  end;
end;

procedure TPersistenciaResultadosEnvioVerifactuUniDAC.GuardarError(
  const AEntrada: TEntradaErrorEnvioVerifactu;
  const APlan: TPlanErrorEnvioVerifactu);
var
  oQry: TUniQuery;
begin
  oQry := CrearConsulta;
  try
    oQry.SQL.Text :=
      ' UPDATE fza_verifactu_cola ' +
      ' SET ESTADO_VFCOLA = :ESTADO, ' +
      '     CONTADOR_INTENTOS_VFCOLA = CASE WHEN :AGOTAR = ''S'' ' +
      '       THEN GREATEST(CONTADOR_INTENTOS_VFCOLA + :INCREMENTO, ' +
      '         :MAXIMO) ' +
      '       ELSE CONTADOR_INTENTOS_VFCOLA + :INCREMENTO END, ' +
      '     INSTANTE_PROXIMO_INTENTO_VFCOLA = ' +
      '       DATE_ADD(NOW(), INTERVAL :ESPERA SECOND), ' +
      '     MENSAJE_ERROR_VFCOLA = :MENSAJE, ' +
      '     INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO ' +
      ' WHERE ID_VFCOLA = :ID';
    oQry.ParamByName('ESTADO').AsString := APlan.EstadoCola;
    if APlan.IncrementarIntentos then
      oQry.ParamByName('INCREMENTO').AsInteger := 1
    else
      oQry.ParamByName('INCREMENTO').AsInteger := 0;
    if APlan.AgotarIntentos then
      oQry.ParamByName('AGOTAR').AsString := 'S'
    else
      oQry.ParamByName('AGOTAR').AsString := 'N';
    oQry.ParamByName('MAXIMO').AsInteger := AEntrada.MaximoIntentos;
    oQry.ParamByName('ESPERA').AsInteger := APlan.EsperaSegundos;
    oQry.ParamByName('MENSAJE').AsString := AEntrada.Mensaje;
    oQry.ParamByName('USUARIO').AsString := AEntrada.Usuario;
    oQry.ParamByName('ID').AsLargeInt := AEntrada.IdCola;
    oQry.Execute;
    if APlan.ActualizarFactura then
    begin
      oQry.SQL.Text :=
        ' UPDATE fza_facturas ' +
        ' SET FASE_FAC = :FASE, INSTANTE_MODIF = NOW(), ' +
        '     USUARIO_MODIF = :USUARIO ' +
        ' WHERE SERIE_FAC = :SERIE ' +
        '   AND NUMERO_FAC = :NUMERO';
      oQry.ParamByName('FASE').AsString :=
        cFaseFacturaVerifactuError;
      oQry.ParamByName('USUARIO').AsString := AEntrada.Usuario;
      oQry.ParamByName('SERIE').AsString := AEntrada.Serie;
      oQry.ParamByName('NUMERO').AsString := AEntrada.Numero;
      oQry.Execute;
    end;
  finally
    FreeAndNil(oQry);
  end;
end;

end.
