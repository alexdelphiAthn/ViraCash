{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataVerifactuSubsanacionResultados                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Conserva el alta original y persiste la respuesta de subsanación.         }
{******************************************************************************}
unit UniDataVerifactuSubsanacionResultados;

interface

uses
  Uni, inLibVerifactuEnvio;

type
  TContextoSubsanacionFiscal = record
    IdCola: Int64;
    Serie: string;
    Numero: string;
    Usuario: string;
  end;

procedure ConservarHistorialSubsanacion(AConexion: TUniConnection;
  const AContexto: TContextoSubsanacionFiscal);
procedure GuardarIntentoSubsanacion(AConexion: TUniConnection;
  const AContexto: TContextoSubsanacionFiscal;
  const AResultado: TResultadoEnvioVerifactu);
procedure GuardarResultadoSubsanacion(
  AConexion: TUniConnection; AIdCola: Int64;
  const ASerie, ANumero, AUsuario, AEstado: string;
  const AResultado: TResultadoEnvioVerifactu);

implementation

uses
  System.SysUtils, System.Classes, Data.DB, inLibMsgVerifactu,
  inLibVerifactu;

function CamposInsercionHistorial: string;
begin
  Result :=
    ' INSERT INTO fza_verifactu_historial ' +
    ' (CLAVE_REGISTRO_VFHIST, ID_COLA_VFHIST, ID_FACCON_VFHIST, ' +
    '  TIPO_REGISTRO_VFHIST, SERIE_FAC_VFHIST, NUMERO_FAC_VFHIST, ' +
    '  MOTIVO_VFHIST, INSTANTE_ALTA, USUARIO_ALTA, ' +
    '  ESTADO_VFHIST,  ' +
    '  REQUEST_ID_VFHIST,  ' +
    '  CHAIN_NUMBER_VFHIST,  ' +
    '  CHAIN_HASH_VFHIST,  ' +
    '  CODIGO_ERROR_AEAT_VFHIST,  ' +
    '  DESCRIPCION_ERROR_AEAT_VFHIST,  ' +
    '  RESPUESTA_COMPLETA_VFHIST,  ' +
    '  PETICION_COMPLETA_VFHIST,  ' +
    '  REGISTRO_XML_VFHIST,  ' +
    '  FIRMA_DIGITAL_VFHIST,  ' +
    '  SERIE_CERTIFICADO_VFHIST,  ' +
    '  TITULAR_CERTIFICADO_VFHIST,  ' +
    '  HUELLA_CERTIFICADO_VFHIST, VERIFACTU_URL_VFHIST, ' +
    '  QRCODE_BASE64_VFHIST, QRCODE_PNG_VFHIST) ';
end;

function CampoInstantanea(AOriginal: Boolean;
  const AActual, AOriginalCampo: string): string;
begin
  Result := 'c.' + AActual;
  if AOriginal then
    Result := 'IF(c.ESTADO_ORIGINAL_FACCON IS NULL, c.' +
      AActual + ', c.' + AOriginalCampo + ')';
end;

function CamposInstantanea(AOriginal: Boolean): string;
begin
  Result :=
    CampoInstantanea(AOriginal, 'ESTADO_FACCON',
      'ESTADO_ORIGINAL_FACCON') + ', ' +
    CampoInstantanea(AOriginal, 'REQUEST_ID_CONSOLIDACION_FACCON',
      'REQUEST_ID_ORIGINAL_FACCON') + ', ' +
    CampoInstantanea(AOriginal, 'CHAIN_NUMBER_FACCON',
      'CHAIN_NUMBER_ORIGINAL_FACCON') + ', ' +
    CampoInstantanea(AOriginal, 'CHAIN_HASH_FACCON',
      'CHAIN_HASH_ORIGINAL_FACCON') + ', ' +
    CampoInstantanea(AOriginal, 'CODIGO_ERROR_AEAT_FACCON',
      'CODIGO_ERROR_ORIGINAL_FACCON') + ', ' +
    CampoInstantanea(AOriginal, 'DESCRIPCION_ERROR_AEAT_FACCON',
      'DESCRIPCION_ERROR_ORIGINAL_FACCON') + ', ' +
    CampoInstantanea(AOriginal, 'RESPUESTA_COMPLETA_FACCON',
      'RESPUESTA_ORIGINAL_FACCON') + ', ' +
    CampoInstantanea(AOriginal, 'PETICION_COMPLETA_FACCON',
      'PETICION_ORIGINAL_FACCON') + ', ' +
    CampoInstantanea(AOriginal, 'REGISTRO_XML_FACCON',
      'REGISTRO_XML_ORIGINAL_FACCON') + ', ' +
    CampoInstantanea(AOriginal, 'FIRMA_DIGITAL_FACCON',
      'FIRMA_DIGITAL_ORIGINAL_FACCON') + ', ' +
    CampoInstantanea(AOriginal, 'SERIE_CERTIFICADO_FACCON',
      'SERIE_CERTIFICADO_ORIGINAL_FACCON') + ', ' +
    CampoInstantanea(AOriginal, 'TITULAR_CERTIFICADO_FACCON',
      'TITULAR_CERTIFICADO_ORIGINAL_FACCON') + ', ' +
    CampoInstantanea(AOriginal, 'HUELLA_CERTIFICADO_FACCON',
      'HUELLA_CERTIFICADO_ORIGINAL_FACCON') + ', ' +
    'c.VERIFACTU_URL_FACCON, c.QRCODE_BASE64_FACCON, c.QRCODE_PNG_FACCON';
end;

procedure AsignarContextoHistorial(AConsulta: TUniQuery;
  const AContexto: TContextoSubsanacionFiscal);
begin
  AConsulta.ParamByName('SERIE').AsString := AContexto.Serie;
  AConsulta.ParamByName('NUMERO').AsString := AContexto.Numero;
  AConsulta.ParamByName('USUARIO').AsString := AContexto.Usuario;
end;

procedure ConservarInstantanea(AConexion: TUniConnection;
  const AContexto: TContextoSubsanacionFiscal; AOriginal: Boolean);
var
  oConsulta: TUniQuery;
  sClave: string;
  sTipo: string;
  sIdCola: string;
begin
  sTipo := 'ANTERIOR';
  sIdCola := 'NULL';
  sClave := 'SHA2(CONCAT(''C:'', c.ID_FACCON, '':'' , ' +
    'IFNULL(c.CHAIN_HASH_FACCON, '''')), 256)';
  if AOriginal then
  begin
    sTipo := 'ORIGINAL';
    sIdCola := 'c.QUEUE_ID_CONSOLIDACION_FACCON';
    sClave := 'SHA2(CONCAT(''O:'', c.ID_FACCON), 256)';
  end;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := CamposInsercionHistorial +
      ' SELECT ' + sClave + ', ' + sIdCola + ', ' +
      ' c.ID_FACCON, :TIPO, c.SERIE_FAC_FACCON, c.NUMERO_FAC_FACCON, ' +
      ' c.MOTIVO_SUBSANACION_FACCON, NOW(), :USUARIO, ' +
      CamposInstantanea(AOriginal) +
      ' FROM fza_facturas_consolidaciones c ' +
      ' WHERE c.SERIE_FAC_FACCON = :SERIE ' +
      '   AND c.NUMERO_FAC_FACCON = :NUMERO ' +
      '   AND c.ID_FACCON = (SELECT MAX(m.ID_FACCON) ' +
      '       FROM fza_facturas_consolidaciones m ' +
      '       WHERE m.SERIE_FAC_FACCON = :SERIE ' +
      '         AND m.NUMERO_FAC_FACCON = :NUMERO) ' +
      '   AND NOT EXISTS (SELECT 1 FROM fza_verifactu_historial h ' +
      '       WHERE h.CLAVE_REGISTRO_VFHIST = ' + sClave + ') ' +
      ' ORDER BY c.ID_FACCON DESC LIMIT 1';
    AsignarContextoHistorial(oConsulta, AContexto);
    oConsulta.ParamByName('TIPO').AsString := sTipo;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure ConservarHistorialSubsanacion(AConexion: TUniConnection;
  const AContexto: TContextoSubsanacionFiscal);
begin
  if not AConexion.InTransaction then
    raise EInvalidOpException.Create(SErrorSubsanacionTransaccion);
  ConservarInstantanea(AConexion, AContexto, True);
  ConservarInstantanea(AConexion, AContexto, False);
end;

procedure AsignarQrResultado(AConsulta: TUniQuery;
  const AResultado: TResultadoEnvioVerifactu);
var
  oImagen: TBytesStream;
begin
  AConsulta.ParamByName('URL').AsString := AResultado.VerifactuUrl;
  AConsulta.ParamByName('QRBASE64').AsString := AResultado.QRCodeBase64;
  AConsulta.ParamByName('QRPNG').DataType := ftBlob;
  AConsulta.ParamByName('QRPNG').Clear;
  if Length(AResultado.QRCodePng) > 0 then
  begin
    oImagen := TBytesStream.Create(AResultado.QRCodePng);
    try
      AConsulta.ParamByName('QRPNG').LoadFromStream(oImagen, ftBlob);
    finally
      FreeAndNil(oImagen);
    end;
  end;
end;

procedure AsignarResultadoFiscal(AConsulta: TUniQuery;
  const AResultado: TResultadoEnvioVerifactu);
begin
  AConsulta.ParamByName('REQUESTID').AsString := AResultado.RequestId;
  AConsulta.ParamByName('CHAINNUM').AsString := AResultado.ChainNumber;
  AConsulta.ParamByName('CHAINHASH').AsString := AResultado.ChainHash;
  AConsulta.ParamByName('CODERROR').AsString := AResultado.CodigoError;
  AConsulta.ParamByName('DESCERROR').AsString := AResultado.DescripcionError;
  AConsulta.ParamByName('RESPUESTA').AsString := AResultado.RespuestaCompleta;
  AConsulta.ParamByName('PETICION').AsString := AResultado.PeticionCompleta;
  AConsulta.ParamByName('REGISTROXML').AsString :=
    AResultado.RegistroXmlFirmado;
  AConsulta.ParamByName('FIRMA').AsString := AResultado.FirmaDigital;
  AConsulta.ParamByName('SERIECERT').AsString := AResultado.SerieCertificado;
  AConsulta.ParamByName('TITULARCERT').AsString :=
    AResultado.TitularCertificado;
  AConsulta.ParamByName('HUELLACERT').AsString :=
    AResultado.HuellaCertificado;
  AsignarQrResultado(AConsulta, AResultado);
end;

procedure GuardarIntentoSubsanacion(AConexion: TUniConnection;
  const AContexto: TContextoSubsanacionFiscal;
  const AResultado: TResultadoEnvioVerifactu);
var
  oConsulta: TUniQuery;
  oIdIntento: TGUID;
begin
  if (AResultado.PeticionCompleta <> '') or
     (AResultado.RegistroXmlFirmado <> '') then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      oConsulta.SQL.Text := CamposInsercionHistorial +
        ' SELECT :CLAVE, q.ID_VFCOLA, NULL, ''ENVIO'', ' +
        ' q.SERIE_FAC_VFCOLA, q.NUMERO_FAC_VFCOLA, ' +
        ' q.MOTIVO_VFCOLA, NOW(), :USUARIO, :ESTADO, ' +
        ' :REQUESTID, :CHAINNUM, :CHAINHASH, :CODERROR, :DESCERROR, ' +
        ' :RESPUESTA, :PETICION, :REGISTROXML, :FIRMA, ' +
        ' :SERIECERT, :TITULARCERT, :HUELLACERT, ' +
        ' :URL, :QRBASE64, :QRPNG ' +
        ' FROM fza_verifactu_cola q WHERE q.ID_VFCOLA = :IDCOLA ' +
        ' AND q.TIPO_OPERACION_VFCOLA = ''SUBSANACION'' ' +
        ' AND NOT EXISTS (SELECT 1 FROM fza_verifactu_historial h ' +
        ' WHERE h.CLAVE_REGISTRO_VFHIST = :CLAVE)';
      oConsulta.ParamByName('CLAVE').AsString := AResultado.IdIntento;
      if AResultado.IdIntento = '' then
      begin
        CreateGUID(oIdIntento);
        oConsulta.ParamByName('CLAVE').AsString := GUIDToString(oIdIntento);
      end;
      oConsulta.ParamByName('IDCOLA').AsLargeInt := AContexto.IdCola;
      oConsulta.ParamByName('USUARIO').AsString := AContexto.Usuario;
      oConsulta.ParamByName('ESTADO').AsString := AResultado.EstadoRegistro;
      if AResultado.EstadoRegistro = '' then
        oConsulta.ParamByName('ESTADO').AsString := 'ERROR_ENVIO';
      AsignarResultadoFiscal(oConsulta, AResultado);
      if AResultado.DescripcionError = '' then
        oConsulta.ParamByName('DESCERROR').AsString :=
          AResultado.MensajeError;
      oConsulta.Execute;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function SqlConservarPrimeraRespuesta: string;
begin
  // ESTADO_ORIGINAL se asigna al final para conservar también los NULL.
  Result :=
    ' REQUEST_ID_ORIGINAL_FACCON = ' +
    ' IF(ESTADO_ORIGINAL_FACCON IS NULL, ' +
    '    REQUEST_ID_CONSOLIDACION_FACCON, ' +
    '    REQUEST_ID_ORIGINAL_FACCON), ' +
    ' CHAIN_NUMBER_ORIGINAL_FACCON = ' +
    ' IF(ESTADO_ORIGINAL_FACCON IS NULL, ' +
    '    CHAIN_NUMBER_FACCON, ' +
    '    CHAIN_NUMBER_ORIGINAL_FACCON), ' +
    ' CHAIN_HASH_ORIGINAL_FACCON = ' +
    ' IF(ESTADO_ORIGINAL_FACCON IS NULL, ' +
    '    CHAIN_HASH_FACCON, ' +
    '    CHAIN_HASH_ORIGINAL_FACCON), ' +
    ' CODIGO_ERROR_ORIGINAL_FACCON = ' +
    ' IF(ESTADO_ORIGINAL_FACCON IS NULL, ' +
    '    CODIGO_ERROR_AEAT_FACCON, ' +
    '    CODIGO_ERROR_ORIGINAL_FACCON), ' +
    ' DESCRIPCION_ERROR_ORIGINAL_FACCON = ' +
    ' IF(ESTADO_ORIGINAL_FACCON IS NULL, ' +
    '    DESCRIPCION_ERROR_AEAT_FACCON, ' +
    '    DESCRIPCION_ERROR_ORIGINAL_FACCON), ' +
    ' RESPUESTA_ORIGINAL_FACCON = ' +
    ' IF(ESTADO_ORIGINAL_FACCON IS NULL, ' +
    '    RESPUESTA_COMPLETA_FACCON, ' +
    '    RESPUESTA_ORIGINAL_FACCON), ' +
    ' PETICION_ORIGINAL_FACCON = ' +
    ' IF(ESTADO_ORIGINAL_FACCON IS NULL, ' +
    '    PETICION_COMPLETA_FACCON, ' +
    '    PETICION_ORIGINAL_FACCON), ' +
    ' REGISTRO_XML_ORIGINAL_FACCON = ' +
    ' IF(ESTADO_ORIGINAL_FACCON IS NULL, ' +
    '    REGISTRO_XML_FACCON, ' +
    '    REGISTRO_XML_ORIGINAL_FACCON), ' +
    ' FIRMA_DIGITAL_ORIGINAL_FACCON = ' +
    ' IF(ESTADO_ORIGINAL_FACCON IS NULL, ' +
    '    FIRMA_DIGITAL_FACCON, ' +
    '    FIRMA_DIGITAL_ORIGINAL_FACCON), ' +
    ' SERIE_CERTIFICADO_ORIGINAL_FACCON = ' +
    ' IF(ESTADO_ORIGINAL_FACCON IS NULL, ' +
    '    SERIE_CERTIFICADO_FACCON, ' +
    '    SERIE_CERTIFICADO_ORIGINAL_FACCON), ' +
    ' TITULAR_CERTIFICADO_ORIGINAL_FACCON = ' +
    ' IF(ESTADO_ORIGINAL_FACCON IS NULL, ' +
    '    TITULAR_CERTIFICADO_FACCON, ' +
    '    TITULAR_CERTIFICADO_ORIGINAL_FACCON), ' +
    ' HUELLA_CERTIFICADO_ORIGINAL_FACCON = ' +
    ' IF(ESTADO_ORIGINAL_FACCON IS NULL, ' +
    '    HUELLA_CERTIFICADO_FACCON, ' +
    '    HUELLA_CERTIFICADO_ORIGINAL_FACCON), ' +
    ' ESTADO_ORIGINAL_FACCON = ' +
    ' IFNULL(ESTADO_ORIGINAL_FACCON, ESTADO_FACCON), ';
end;

function SqlAplicarResultado: string;
begin
  Result :=
    ' REQUEST_ID_CONSOLIDACION_FACCON = ' +
    ' IFNULL(NULLIF(:REQUESTID, ''''), ' +
    '        REQUEST_ID_CONSOLIDACION_FACCON), ' +
    ' CHAIN_NUMBER_FACCON = :CHAINNUM, CHAIN_HASH_FACCON = :CHAINHASH, ' +
    ' ESTADO_FACCON = :ESTADO, ' +
    ' CODIGO_ERROR_AEAT_FACCON = NULLIF(:CODERROR, ''''), ' +
    ' DESCRIPCION_ERROR_AEAT_FACCON = NULLIF(:DESCERROR, ''''), ' +
    ' RESPUESTA_COMPLETA_FACCON = :RESPUESTA, ' +
    ' PETICION_COMPLETA_FACCON = :PETICION, ' +
    ' REGISTRO_XML_FACCON = :REGISTROXML, FIRMA_DIGITAL_FACCON = :FIRMA, ' +
    ' SERIE_CERTIFICADO_FACCON = :SERIECERT, ' +
    ' TITULAR_CERTIFICADO_FACCON = :TITULARCERT, ' +
    ' HUELLA_CERTIFICADO_FACCON = :HUELLACERT, ' +
    ' VERIFACTU_URL_FACCON = :URL, QRCODE_BASE64_FACCON = :QRBASE64, ' +
    ' QRCODE_PNG_FACCON = :QRPNG, ' +
    ' MOTIVO_SUBSANACION_FACCON = (SELECT q.MOTIVO_VFCOLA ' +
    ' FROM fza_verifactu_cola q WHERE q.ID_VFCOLA = :IDCOLA), ' +
    ' INSTANTE_SUBSANACION_FACCON = NOW(), ' +
    ' USUARIO_SUBSANACION_FACCON = :USUARIO, ' +
    ' FECHA_PROCESAMIENTO_FACCON = NOW() ' +
    ' WHERE ID_FACCON = :IDFACCON';
end;

function BloquearConsolidacion(AConexion: TUniConnection;
  const AContexto: TContextoSubsanacionFiscal): Int64;
var
  oConsulta: TUniQuery;
  sEstado: string;
begin
  Result := 0;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      ' SELECT ID_FACCON, ESTADO_FACCON ' +
      ' FROM fza_facturas_consolidaciones ' +
      ' WHERE SERIE_FAC_FACCON = :SERIE ' +
      ' AND NUMERO_FAC_FACCON = :NUMERO ' +
      ' ORDER BY ID_FACCON DESC LIMIT 1 FOR UPDATE';
    oConsulta.ParamByName('SERIE').AsString := AContexto.Serie;
    oConsulta.ParamByName('NUMERO').AsString := AContexto.Numero;
    oConsulta.Open;
    if not oConsulta.Eof then
    begin
      sEstado := oConsulta.FieldByName('ESTADO_FACCON').AsString;
      if (sEstado = 'VERIFACTU_ACEPT_ERR') or
         (sEstado = 'VERIFACTU_PROCESADO') or
         (sEstado = 'VERIFACTU_DUPLICADO') or
         (sEstado = 'VERIFACTU_SUBSANADO') or
         (sEstado = 'VERIFACTU_OK') or
         EsEstadoSiiAceptado(sEstado) then
        Result := oConsulta.FieldByName('ID_FACCON').AsLargeInt;
    end;
    if Result = 0 then
      raise EArgumentException.Create(SErrorSubsanacionRegistroNoVigente);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure GuardarResultadoSubsanacion(
  AConexion: TUniConnection; AIdCola: Int64;
  const ASerie, ANumero, AUsuario, AEstado: string;
  const AResultado: TResultadoEnvioVerifactu);
var
  oConsulta: TUniQuery;
  oContexto: TContextoSubsanacionFiscal;
  iConsolidacion: Int64;
begin
  if not AConexion.InTransaction then
    raise EInvalidOpException.Create(SErrorSubsanacionTransaccion);
  oContexto.IdCola := AIdCola;
  oContexto.Serie := ASerie;
  oContexto.Numero := ANumero;
  oContexto.Usuario := AUsuario;
  iConsolidacion := BloquearConsolidacion(AConexion, oContexto);
  ConservarHistorialSubsanacion(AConexion, oContexto);
  GuardarIntentoSubsanacion(AConexion, oContexto, AResultado);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := ' UPDATE fza_facturas_consolidaciones SET ' +
      SqlConservarPrimeraRespuesta + SqlAplicarResultado;
    AsignarResultadoFiscal(oConsulta, AResultado);
    oConsulta.ParamByName('IDCOLA').AsLargeInt := AIdCola;
    oConsulta.ParamByName('USUARIO').AsString := AUsuario;
    oConsulta.ParamByName('ESTADO').AsString := AEstado;
    oConsulta.ParamByName('IDFACCON').AsLargeInt := iConsolidacion;
    oConsulta.Execute;
    if oConsulta.RowsAffected <> 1 then
      raise EArgumentException.Create(SErrorSubsanacionRegistroNoVigente);
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.
