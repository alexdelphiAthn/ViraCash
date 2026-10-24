{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataVerifactuColaOperaciones                               }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Operaciones fiscales UniDAC sin envío a AEAT: registro NO VERI*FACTU,     }
{    rectificativas, relaciones y reversión de movimientos.                    }
{******************************************************************************}
unit UniDataVerifactuColaOperaciones;

interface

uses
  Uni, inLibParametrosIntf, inLibEmisionFiscalIntf, inLibLogIntf,
  inLibVerifactuColaIntf;
type
  TOperacionesVerifactuColaUniDAC = class
  public
    // Genera y guarda el registro de facturación firmado sin enviarlo a
    // AEAT. Es el camino NO VERI*FACTU y debe ejecutarse al crear la
    // factura. AQryTrx participa en la transacción de la grabación.
    class procedure RegistrarFacturaNoVerifactu(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      AQryTrx: TUniQuery;
      const AUsuario, ASerie, ANumero, ATipoOperacion: string;
      ABorrarMovimientos: Boolean;
      const ARegistroLog: IRegistroLog); static;
    // Marca una factura recién abonada como RECTIFICATIVA, la enlaza con
    // la original (columnas ABONO) y delega el alta fiscal en el servicio
    // de emisión inyectado. La llama el modal de Rectificar de Facturas.
    class procedure EncolarRectificativa(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      AConn: TUniConnection;
      const AServicioEmision: IServicioEmisionFiscal;
      const AUsuario, ASerieOriginal, ANumeroOriginal,
      ASerieRect, ANumeroRect, ATipoRectificativa: string;
      ABorrarMovimientosOriginales: Boolean); static;
    // Enlace general: tipo I/S, tipo VERI*FACTU (R1..R5), motivo y
    // tratamiento de movimientos. Con EmitirAhora encola el alta en el
    // acto; sin él deja el borrador para revisarlo y consolidarlo.
    class procedure VincularRectificativa(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      AConn: TUniConnection;
      const AServicioEmision: IServicioEmisionFiscal;
      const ASolicitud: TSolicitudVinculoRectificativa); static;
    // Cierra el vínculo cuando se consolida una rectificativa creada sin
    // emitir: la original pasa a RECTIFICADA y, si la sustitutiva
    // reemplaza sus movimientos, los retira. Transacción del llamador.
    class procedure CompletarRectificativa(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      AConn: TUniConnection;
      const AUsuario, ASerieRect, ANumeroRect: string); static;
    // Al borrar un borrador rectificativo: retira la relación y, si la
    // original apuntaba a él, le devuelve su fase de registro.
    class procedure DesvincularRectificativa(
      AConn: TUniConnection;
      const AUsuario, ASerieRect, ANumeroRect: string); static;
    // Histórico N:1 de rectificaciones/sustituciones
    // (fza_facturas_relaciones): cada hija guarda su factura de origen
    class procedure RegistrarRelacionFactura(
      AConn: TUniConnection;
      const AUsuario, ASerie, ANumero,
      ASerieOrigen, ANumeroOrigen, ATipoRelacion: string); static;
    // Revierte los movimientos vinculados a una factura de caja (VE) o
    // creada desde el mantenimiento (FC). El SP mantiene stock y
    // acumulados.
    class procedure BorrarMovimientosFactura(
      AQry: TUniQuery;
      const ASerie, ANumero: string); static;
  end;
function ObtenerEstadoRegistroNoVerifactu(
  const ATipoOperacion: string): string;
implementation

uses
  inLibFormatoDocumento, UniDataFormatoDocumentoRepositorio,
  System.SysUtils, System.Classes, System.StrUtils, Data.DB,
  inLibMsgFacturas, inLibMsgVerifactu, inLibVerifactu, inLibVerifactuEnvio,
  inLibRelojFiscal, inLibVentasWsCola, UniDataVentasWsCola;
function ObtenerEstadoRegistroNoVerifactu(
  const ATipoOperacion: string): string;
begin
  if ATipoOperacion = 'ANULACION' then
    Result := 'NOVERIF_ANULADO'
  else if ATipoOperacion = 'SUBSANACION' then
    Result := 'NOVERIF_SUBSANADO'
  else
    Result := 'NOVERIF_REGISTRADO';
end;
function ColumnasFirmaFacturacionDisponibles(AConn: TUniConnection): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      ' SELECT COUNT(*) AS N ' +
      ' FROM INFORMATION_SCHEMA.COLUMNS ' +
      ' WHERE TABLE_SCHEMA = DATABASE() ' +
      '   AND TABLE_NAME = ''fza_facturas_consolidaciones'' ' +
      '   AND COLUMN_NAME IN (''REGISTRO_XML_FACCON'', ' +
      '       ''FIRMA_DIGITAL_FACCON'', ''SERIE_CERTIFICADO_FACCON'', ' +
      '       ''TITULAR_CERTIFICADO_FACCON'', ' +
      '       ''HUELLA_CERTIFICADO_FACCON'')';
    Qry.Open;
    Result := Qry.FieldByName('N').AsInteger = 5;
  finally
    FreeAndNil(Qry);
  end;
end;
procedure RegistrarIncidenciaNoVerifactuSeguro(
  const AParametrosApp: IParametrosAplicacion;
  AConn: TUniConnection;
  const AUsuario: string;
  ATipoEvento: Integer;
  const ADescripcion, AMensaje, ASerie, ANumero: string;
  const ARegistroLog: IRegistroLog);
begin
  try
    RegistrarEventoVerifactu(AParametrosApp, AConn, AUsuario,
      ATipoEvento, ADescripcion, AMensaje, ASerie, ANumero);
  except
    on E: Exception do
    begin
      if Assigned(ARegistroLog) then
        ARegistroLog.RegistrarError(
          'No se pudo registrar la incidencia NO VERI*FACTU: ' +
          E.Message);
    end;
  end;
end;
procedure ActualizarCadenaNoVerifactu(
  AQry: TUniQuery;
  const AUsuario, ASerie, ANumero: string;
  const AResultado: TResultadoEnvioVerifactu);
begin
  AQry.SQL.Text :=
    ' UPDATE fza_verifactu_cadena ' +
    ' SET CONTADOR_VFCAD = :CONTADOR, ' +
    '     SERIE_FAC_VFCAD  = :SERIE, ' +
    '     NUMERO_FAC_VFCAD = :NUMERO, ' +
    '     FECHA_FAC_VFCAD  = STR_TO_DATE(:FECHA, ''%d-%m-%Y''), ' +
    '     HUELLA_VFCAD = :HUELLA, ' +
    '     INSTANTE_MODIF = NOW(), ' +
    '     USUARIO_MODIF  = :USUARIO ' +
    ' WHERE NIF_VFCAD = :NIF';
  AQry.ParamByName('CONTADOR').AsString := AResultado.ChainNumber;
  AQry.ParamByName('SERIE').AsString    := ASerie;
  AQry.ParamByName('NUMERO').AsString   := ANumero;
  AQry.ParamByName('FECHA').AsString    := AResultado.FechaExpedicion;
  AQry.ParamByName('HUELLA').AsString   := AResultado.ChainHash;
  AQry.ParamByName('USUARIO').AsString  := AUsuario;
  AQry.ParamByName('NIF').AsString      := AResultado.IssuerIrsId;
  AQry.Execute;
end;
procedure PrepararActualizacionAnulacionNoVerifactu(
  AQry: TUniQuery);
begin
  AQry.SQL.Text :=
    ' UPDATE fza_facturas_consolidaciones ' +
    ' SET CHAIN_NUMBER_FACCON = :CHAINNUM, ' +
    '     CHAIN_HASH_FACCON = :CHAINHASH, ' +
    '     ISSUER_IRS_ID_CONSOLIDACION_FACCON = :ISSUERID, ' +
    '     ISSUED_TIME_FACCON = :ISSUEDTIME, ' +
    '     FECHA_PROCESAMIENTO_FACCON = NOW(), ' +
    '     ESTADO_FACCON = :ESTADO, ' +
    '     REGISTRO_XML_FACCON = :REGISTROXML, ' +
    '     FIRMA_DIGITAL_FACCON = :FIRMA, ' +
    '     SERIE_CERTIFICADO_FACCON = :SERIECERT, ' +
    '     TITULAR_CERTIFICADO_FACCON = :TITULARCERT, ' +
    '     HUELLA_CERTIFICADO_FACCON = :HUELLACERT ' +
    ' WHERE SERIE_FAC_FACCON = :SERIE ' +
    '   AND NUMERO_FAC_FACCON = :NUMERO';
end;
procedure PrepararAltaConsolidacionNoVerifactu(
  AQry: TUniQuery);
begin
  AQry.SQL.Text :=
    ' INSERT INTO fza_facturas_consolidaciones ' +
    ' (ID_FACCON, SERIE_FAC_FACCON, NUMERO_FAC_FACCON, ' +
    '  ISSUER_IRS_ID_CONSOLIDACION_FACCON, ISSUED_TIME_FACCON, ' +
    '  CHAIN_NUMBER_FACCON, CHAIN_HASH_FACCON, ' +
    '  VERIFACTU_URL_FACCON, QRCODE_BASE64_FACCON, ' +
    '  QRCODE_PNG_FACCON, ' +
    '  FECHA_PROCESAMIENTO_FACCON, ESTADO_FACCON, ' +
    '  REGISTRO_XML_FACCON, FIRMA_DIGITAL_FACCON, ' +
    '  SERIE_CERTIFICADO_FACCON, TITULAR_CERTIFICADO_FACCON, ' +
    '  HUELLA_CERTIFICADO_FACCON) ' +
    ' SELECT IFNULL(MAX(ID_FACCON), 0) + 1, :SERIE, :NUMERO, ' +
    '        :ISSUERID, :ISSUEDTIME, :CHAINNUM, :CHAINHASH, ' +
    '        NULLIF(:URL, ''''), NULLIF(:QRBASE64, ''''), :QRPNG, ' +
    '        NOW(), :ESTADO, :REGISTROXML, :FIRMA, :SERIECERT, ' +
    '        :TITULARCERT, :HUELLACERT ' +
    ' FROM fza_facturas_consolidaciones ' +
    ' ON DUPLICATE KEY UPDATE ' +
    '  ESTADO_FACCON = VALUES(ESTADO_FACCON), ' +
    '  CHAIN_NUMBER_FACCON = VALUES(CHAIN_NUMBER_FACCON), ' +
    '  CHAIN_HASH_FACCON = VALUES(CHAIN_HASH_FACCON), ' +
    '  VERIFACTU_URL_FACCON = VALUES(VERIFACTU_URL_FACCON), ' +
    '  QRCODE_BASE64_FACCON = VALUES(QRCODE_BASE64_FACCON), ' +
    '  QRCODE_PNG_FACCON = VALUES(QRCODE_PNG_FACCON), ' +
    '  REGISTRO_XML_FACCON = VALUES(REGISTRO_XML_FACCON), ' +
    '  FIRMA_DIGITAL_FACCON = VALUES(FIRMA_DIGITAL_FACCON), ' +
    '  SERIE_CERTIFICADO_FACCON = VALUES(SERIE_CERTIFICADO_FACCON), ' +
    '  TITULAR_CERTIFICADO_FACCON = ' +
    '    VALUES(TITULAR_CERTIFICADO_FACCON), ' +
    '  HUELLA_CERTIFICADO_FACCON = ' +
    '    VALUES(HUELLA_CERTIFICADO_FACCON)';
end;
procedure AsignarParametrosConsolidacionNoVerifactu(
  AQry: TUniQuery;
  const ASerie, ANumero, ATipoOperacion: string;
  const AResultado: TResultadoEnvioVerifactu);
var
  oPngStream: TBytesStream;
begin
  AQry.ParamByName('SERIE').AsString := ASerie;
  AQry.ParamByName('NUMERO').AsString := ANumero;
  AQry.ParamByName('ISSUERID').AsString := AResultado.IssuerIrsId;
  AQry.ParamByName('ISSUEDTIME').DataType := ftDateTime;
  AQry.ParamByName('ISSUEDTIME').AsDateTime := AResultado.IssuedTime;
  AQry.ParamByName('CHAINNUM').AsString := AResultado.ChainNumber;
  AQry.ParamByName('CHAINHASH').AsString := AResultado.ChainHash;
  AQry.ParamByName('ESTADO').AsString :=
    ObtenerEstadoRegistroNoVerifactu(ATipoOperacion);
  if ATipoOperacion <> 'ANULACION' then
  begin
    AQry.ParamByName('URL').AsString      := AResultado.VerifactuUrl;
    AQry.ParamByName('QRBASE64').AsString := AResultado.QRCodeBase64;
    AQry.ParamByName('QRPNG').DataType    := ftBlob;
    if Length(AResultado.QRCodePng) > 0 then
    begin
      oPngStream := TBytesStream.Create(AResultado.QRCodePng);
      try
        AQry.ParamByName('QRPNG').LoadFromStream(oPngStream, ftBlob);
      finally
        FreeAndNil(oPngStream);
      end;
    end
    else
      AQry.ParamByName('QRPNG').Clear;
  end;
  AQry.ParamByName('REGISTROXML').AsString :=
    AResultado.RegistroXmlFirmado;
  AQry.ParamByName('FIRMA').AsString := AResultado.FirmaDigital;
  AQry.ParamByName('SERIECERT').AsString := AResultado.SerieCertificado;
  AQry.ParamByName('TITULARCERT').AsString :=
    AResultado.TitularCertificado;
  AQry.ParamByName('HUELLACERT').AsString :=
    AResultado.HuellaCertificado;
end;
procedure GuardarConsolidacionNoVerifactu(
  AQry: TUniQuery;
  const ASerie, ANumero, ATipoOperacion: string;
  const AResultado: TResultadoEnvioVerifactu);
begin
  if ATipoOperacion = 'ANULACION' then
    PrepararActualizacionAnulacionNoVerifactu(AQry)
  else
    PrepararAltaConsolidacionNoVerifactu(AQry);
  AsignarParametrosConsolidacionNoVerifactu(
    AQry, ASerie, ANumero, ATipoOperacion, AResultado);
  AQry.Execute;
end;
procedure MarcarFacturaRegistradaNoVerifactu(
  AQry: TUniQuery;
  const AUsuario, ASerie, ANumero, ATipoOperacion: string);
begin
  AQry.SQL.Text :=
    ' UPDATE fza_facturas ' +
    ' SET ESCONSOLIDADA_FAC = ''S'', ' +
    '     INSTANTECONSO_FAC = NOW(), ' +
    '     FASE_FAC = :FASE, ' +
    '     INSTANTE_MODIF = NOW(), ' +
    '     USUARIO_MODIF  = :USUARIO ' +
    ' WHERE SERIE_FAC  = :SERIE ' +
    '   AND NUMERO_FAC = :NUMERO';
  if ATipoOperacion = 'ANULACION' then
    AQry.ParamByName('FASE').AsString := cFaseFacturaNoVerifactuAnulada
  else
    AQry.ParamByName('FASE').AsString := cFaseFacturaNoVerifactuOk;
  AQry.ParamByName('USUARIO').AsString := AUsuario;
  AQry.ParamByName('SERIE').AsString := ASerie;
  AQry.ParamByName('NUMERO').AsString := ANumero;
  AQry.Execute;
end;
procedure GuardarRegistroNoVerifactu(
  AQry: TUniQuery;
  const AUsuario, ASerie, ANumero, ATipoOperacion: string;
  const AResultado: TResultadoEnvioVerifactu;
  ABorrarMovimientos: Boolean);
begin
  if not ColumnasFirmaFacturacionDisponibles(AQry.Connection) then
    raise Exception.Create(
      SErrorColumnasFirmaFacturacionNoDisponibles);
  ActualizarCadenaNoVerifactu(
    AQry, AUsuario, ASerie, ANumero, AResultado);
  GuardarConsolidacionNoVerifactu(
    AQry, ASerie, ANumero, ATipoOperacion, AResultado);
  MarcarFacturaRegistradaNoVerifactu(
    AQry, AUsuario, ASerie, ANumero, ATipoOperacion);
  if ATipoOperacion = 'ANULACION' then
    TOperacionesVerifactuColaUniDAC.BorrarMovimientosFactura(
      AQry, ASerie, ANumero);
end;
// ===========================================================================
//   TOperacionesVerifactuColaUniDAC — operaciones sin envío
// ===========================================================================
class procedure TOperacionesVerifactuColaUniDAC.BorrarMovimientosFactura(
  AQry: TUniQuery;
  const ASerie, ANumero: string);
begin
  if (Trim(ASerie) <> '') and (Trim(ANumero) <> '') then
  begin
    AQry.SQL.Text :=
      'CALL PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE_DOC(:t, :s, :n)';
    AQry.ParamByName('t').AsString := 'VE';
    AQry.ParamByName('s').AsString := ASerie;
    AQry.ParamByName('n').AsString := ANumero;
    AQry.ExecSQL;
    AQry.SQL.Text :=
      'UPDATE fza_facturas_lineas ' +
      '   SET NUMERO_MOV_FACLIN = NULL ' +
      ' WHERE SERIE_FAC_FACLIN = :s ' +
      '   AND NUMERO_FAC_FACLIN = :n';
    AQry.ParamByName('s').AsString := ASerie;
    AQry.ParamByName('n').AsString := ANumero;
    AQry.ExecSQL;
    AQry.SQL.Text :=
      'CALL PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE_DOC(:t, :s, :n)';
    AQry.ParamByName('t').AsString := 'FC';
    AQry.ParamByName('s').AsString := ASerie;
    AQry.ParamByName('n').AsString := ANumero;
    AQry.ExecSQL;
  end;
end;
class procedure TOperacionesVerifactuColaUniDAC.RegistrarFacturaNoVerifactu(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  AQryTrx: TUniQuery;
  const AUsuario, ASerie, ANumero, ATipoOperacion: string;
  ABorrarMovimientos: Boolean;
  const ARegistroLog: IRegistroLog);
var
  oResultado: TResultadoEnvioVerifactu;
begin
  try
    ValidarRequisitosFiscalesEmision(AParametrosApp, AQryTrx.Connection,
      ASerie, ANumero);
    ExigirRelojFiscal(AParametrosApp,
      STextoRegistroFacturacionNoVerifactu);
    if not VerifactuFirmaCertificado(AParametrosApp) then
      raise Exception.Create(SErrorFirmaRegistroNoVerifactuObligatoria);
    oResultado := GenerarRegistroFacturaLocal(AParametrosApp,
      AQryTrx.Connection, AUsuario, ASerie, ANumero, ATipoOperacion);
    if not oResultado.Ok then
      raise Exception.Create(oResultado.MensajeError);
    GuardarRegistroNoVerifactu(AQryTrx, AUsuario, ASerie, ANumero,
      ATipoOperacion, oResultado, ABorrarMovimientos);
    RegistrarEventoVerifactu(AParametrosApp, AQryTrx.Connection, AUsuario,
      cEventoVerifactuInfo,
      'Registro de facturación NO VERI*FACTU registrado', ATipoOperacion,
      ASerie, ANumero);
    TVentasWsCola.RegistrarFactura(
      AParametrosCaja,
      CrearRepositorioVentasWsColaUniDAC(AQryTrx.Connection),
      AUsuario, ASerie, ANumero, ATipoOperacion);
  except
    on E: Exception do
    begin
      if Pos('reloj', LowerCase(E.Message)) > 0 then
        RegistrarIncidenciaNoVerifactuSeguro(AParametrosApp,
          AQryTrx.Connection, AUsuario,
          cEventoNoVerifactuIncidenciaReloj,
          'Incidencia de reloj NO VERI*FACTU', E.Message, ASerie, ANumero,
          ARegistroLog)
      else
        RegistrarIncidenciaNoVerifactuSeguro(AParametrosApp,
          AQryTrx.Connection, AUsuario,
          cEventoNoVerifactuIncidenciaCert,
          'Incidencia de certificado NO VERI*FACTU', E.Message,
          ASerie, ANumero, ARegistroLog);
      raise;
    end;
  end;
end;
// ===========================================================================
//   Rectificativas: vínculo con la original, emisión y desvinculación
// ===========================================================================
function ComentarioVinculoRectificativa(
  AConexion: TUniConnection;
  const ASolicitud: TSolicitudVinculoRectificativa): string;
begin
  if ASolicitud.TipoRectificativa = 'S' then
    Result := ' ESTA FACTURA RECTIFICA POR SUSTITUCIÓN A LA '
  else
    Result := ' ESTA FACTURA RECTIFICA POR DIFERENCIAS A LA ';
  Result := Result + FormatearReferenciaFactura(AConexion,
    ASolicitud.SerieOriginal, ASolicitud.NumeroOriginal);
  if Trim(ASolicitud.Motivo) <> '' then
    Result := Result + '. MOTIVO: ' + Trim(ASolicitud.Motivo);
end;
function NormalizarSolicitudVinculo(
  AConexion: TUniConnection;
  const ASolicitud: TSolicitudVinculoRectificativa):
  TSolicitudVinculoRectificativa;
begin
  Result := ASolicitud;
  Result.TipoRectificativa := UpperCase(Trim(ASolicitud.TipoRectificativa));
  if (Result.TipoRectificativa <> 'I') and
     (Result.TipoRectificativa <> 'S') then
    raise Exception.Create(SErrorTipoRectificativaFiscalInvalido);
  Result.TipoFacturaVerifactu :=
    UpperCase(Trim(ASolicitud.TipoFacturaVerifactu));
  if (Result.TipoFacturaVerifactu <> '') and
     (not MatchText(Result.TipoFacturaVerifactu,
       ['R1', 'R2', 'R3', 'R4', 'R5'])) then
    raise Exception.Create(
      SErrorTipoFacturaVerifactuRectificativaInvalido);
  // Sólo la sustitución que reemplaza los movimientos de la original
  // genera los suyos; un abono por diferencias nunca mueve stock.
  Result.ReemplazarMovimientosOriginales :=
    (Result.TipoRectificativa = 'S') and
    ASolicitud.ReemplazarMovimientosOriginales;
  if Trim(Result.DescripcionEvento) = '' then
    Result.DescripcionEvento :=
      'Rectificativa de ' + FormatearReferenciaFactura(AConexion,
        Result.SerieOriginal, Result.NumeroOriginal) + ' tipo ' + Result.TipoRectificativa +
      ' encolada desde Facturas';
end;
function RectificativaSinIdentificar(
  const ASerie, ANumero: string): Boolean;
begin
  Result := (Trim(ASerie) = '') or (Trim(ASerie) = '0') or
    (Trim(ANumero) = '') or (Trim(ANumero) = '0');
end;
function EsFaseFacturaAnulada(const AFase: string): Boolean;
begin
  Result := MatchText(Trim(AFase),
    [cFaseFacturaSinVerifactuAnulada, cFaseFacturaVerifactuAnulada,
     cFaseFacturaNoVerifactuAnulada]);
end;
procedure MarcarRectificativaVinculada(
  AQry: TUniQuery;
  const ASolicitud: TSolicitudVinculoRectificativa);
begin
  // Rectificativa: tipo y fase propios, sin enlace ABONO heredado de
  // la copia del SP, tipo VERI*FACTU elegido (si llega) y comentario
  // con la factura que rectifica y el motivo. ESMUEVE_STOCK decide si
  // la consolidación genera sus salidas de stock.
  AQry.SQL.Text :=
    ' UPDATE fza_facturas ' +
    ' SET TIPO_FAC = ''RECTIFICATIVA'', ' +
    '     TIPO_RECTIFICATIVA_FAC = :TIPORECT, ' +
    '     TIPO_FACTURA_VERIFACTU_FAC = IF(:TIPOVF = '''', ' +
    '       TIPO_FACTURA_VERIFACTU_FAC, :TIPOVF), ' +
    '     FASE_FAC = ''BORRADOR'', ' +
    '     ESMUEVE_STOCK_FAC = :MUEVE, ' +
    '     SERIE_FAC_ABONO_FAC  = NULL, ' +
    '     NUMERO_FAC_ABONO_FAC = NULL, ' +
    '     COMENTARIOS_FAC = TRIM(CONCAT(IFNULL(COMENTARIOS_FAC, ' +
    '         ''''), :COMENTARIO)), ' +
    '     INSTANTE_MODIF = NOW(), ' +
    '     USUARIO_MODIF  = :USUARIO ' +
    ' WHERE SERIE_FAC  = :SERIE ' +
    '   AND NUMERO_FAC = :NUMERO';
  AQry.ParamByName('TIPORECT').AsString := ASolicitud.TipoRectificativa;
  AQry.ParamByName('TIPOVF').AsString := ASolicitud.TipoFacturaVerifactu;
  if ASolicitud.ReemplazarMovimientosOriginales then
    AQry.ParamByName('MUEVE').AsString := 'S'
  else
    AQry.ParamByName('MUEVE').AsString := 'N';
  AQry.ParamByName('COMENTARIO').AsString :=
    ComentarioVinculoRectificativa(AQry.Connection, ASolicitud);
  AQry.ParamByName('USUARIO').AsString := ASolicitud.Usuario;
  AQry.ParamByName('SERIE').AsString := ASolicitud.SerieRectificativa;
  AQry.ParamByName('NUMERO').AsString := ASolicitud.NumeroRectificativa;
  AQry.Execute;
end;
procedure EnlazarOriginalConRectificativa(
  AQry: TUniQuery;
  const AUsuario, ASerieOriginal, ANumeroOriginal,
  ASerieRect, ANumeroRect: string);
begin
  // La ORIGINAL guarda en sus columnas ABONO la rectificativa vigente.
  // Sólo pasa a RECTIFICADA cuando la rectificativa se emite: hasta
  // entonces el borrador puede revisarse o borrarse sin dejar huella
  // (el puntero de un borrador lo fija RecalcularRectificativaVigente).
  AQry.SQL.Text :=
    ' UPDATE fza_facturas ' +
    ' SET FASE_FAC = ''RECTIFICADA'', ' +
    '     SERIE_FAC_ABONO_FAC  = :SERIERECT, ' +
    '     NUMERO_FAC_ABONO_FAC = :NUMERORECT, ' +
    '     INSTANTE_MODIF = NOW(), ' +
    '     USUARIO_MODIF  = :USUARIO ' +
    ' WHERE SERIE_FAC  = :SERIE ' +
    '   AND NUMERO_FAC = :NUMERO';
  AQry.ParamByName('SERIERECT').AsString  := ASerieRect;
  AQry.ParamByName('NUMERORECT').AsString := ANumeroRect;
  AQry.ParamByName('USUARIO').AsString    := AUsuario;
  AQry.ParamByName('SERIE').AsString      := ASerieOriginal;
  AQry.ParamByName('NUMERO').AsString     := ANumeroOriginal;
  AQry.Execute;
end;
procedure RecalcularRectificativaVigente(
  AQry: TUniQuery;
  const AUsuario, ASerieOriginal, ANumeroOriginal: string);
var
  sSerieRect: string;
  sNumeroRect: string;
begin
  // FZ-ISSUE-132: fza_facturas_relaciones es la fuente de verdad. Las
  // columnas ABONO de la original apuntan a la última rectificativa
  // emitida y, si no hay ninguna, a la última en borrador. Sin
  // relaciones no se toca (datos anteriores a las relaciones).
  AQry.Close;
  AQry.SQL.Text :=
    ' SELECT r.SERIE_FAC_FACREL, r.NUMERO_FAC_FACREL ' +
    ' FROM fza_facturas_relaciones r ' +
    ' JOIN fza_facturas h ' +
    '   ON h.SERIE_FAC = r.SERIE_FAC_FACREL ' +
    '  AND h.NUMERO_FAC = r.NUMERO_FAC_FACREL ' +
    ' WHERE r.SERIE_FAC_ORIGEN_FACREL = :SERIE ' +
    '   AND r.NUMERO_FAC_ORIGEN_FACREL = :NUMERO ' +
    '   AND r.TIPO_RELACION_FACREL = ''RECTIFICA'' ' +
    ' ORDER BY CASE WHEN COALESCE(h.FASE_FAC, '''') ' +
    '                    IN ('''', ''BORRADOR'') ' +
    '          THEN 1 ELSE 0 END, r.ID_FACREL DESC ' +
    ' LIMIT 1';
  AQry.ParamByName('SERIE').AsString := ASerieOriginal;
  AQry.ParamByName('NUMERO').AsString := ANumeroOriginal;
  AQry.Open;
  sSerieRect := AQry.FieldByName('SERIE_FAC_FACREL').AsString;
  sNumeroRect := AQry.FieldByName('NUMERO_FAC_FACREL').AsString;
  AQry.Close;
  if sNumeroRect <> '' then
  begin
    AQry.SQL.Text :=
      ' UPDATE fza_facturas ' +
      ' SET SERIE_FAC_ABONO_FAC  = :SERIERECT, ' +
      '     NUMERO_FAC_ABONO_FAC = :NUMERORECT, ' +
      '     INSTANTE_MODIF = NOW(), ' +
      '     USUARIO_MODIF  = :USUARIO ' +
      ' WHERE SERIE_FAC  = :SERIE ' +
      '   AND NUMERO_FAC = :NUMERO ' +
      '   AND (COALESCE(SERIE_FAC_ABONO_FAC, '''') <> :SERIERECT ' +
      '     OR COALESCE(NUMERO_FAC_ABONO_FAC, '''') <> :NUMERORECT)';
    AQry.ParamByName('SERIERECT').AsString := sSerieRect;
    AQry.ParamByName('NUMERORECT').AsString := sNumeroRect;
    AQry.ParamByName('USUARIO').AsString := AUsuario;
    AQry.ParamByName('SERIE').AsString := ASerieOriginal;
    AQry.ParamByName('NUMERO').AsString := ANumeroOriginal;
    AQry.Execute;
  end;
end;
procedure RetirarVentaSustituida(
  const AParametrosCaja: IParametrosCaja;
  AQry: TUniQuery;
  const AUsuario, ASerieOriginal, ANumeroOriginal: string);
begin
  // El webservice conserva el histórico, pero deja la original fuera
  // de las ventas activas cuando la rectificación es sustitutiva.
  TVentasWsCola.RegistrarFactura(
    AParametrosCaja,
    CrearRepositorioVentasWsColaUniDAC(AQry.Connection),
    AUsuario, ASerieOriginal, ANumeroOriginal,
    'SUSTITUCION');
end;
class procedure TOperacionesVerifactuColaUniDAC.VincularRectificativa(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  AConn: TUniConnection;
  const AServicioEmision: IServicioEmisionFiscal;
  const ASolicitud: TSolicitudVinculoRectificativa);
var
  Qry: TUniQuery;
  oSolicitud: TSolicitudVinculoRectificativa;
  oEmision: TSolicitudEmisionFiscal;
  bTransaccionPropia: Boolean;
begin
  if ASolicitud.EmitirAhora and (not Assigned(AServicioEmision)) then
    raise EArgumentNilException.Create('AServicioEmision');
  oSolicitud := NormalizarSolicitudVinculo(AConn, ASolicitud);
  // Guarda: una rectificativa sin serie/numero validos (p.ej. '0'/'0' por
  // una cabecera de caja que no se vuelca) encolaria un registro fantasma
  // que la AEAT rechaza y rompe el enlace ABONO de la original. Se deja
  // constancia en el log y no se toca nada mas.
  if RectificativaSinIdentificar(oSolicitud.SerieRectificativa,
       oSolicitud.NumeroRectificativa) then
  begin
    RegistrarEventoVerifactu(AParametrosApp, AConn, oSolicitud.Usuario,
      cEventoVerifactuEnvioError,
      'Rectificativa de ' + FormatearReferenciaFactura(AConn,
        oSolicitud.SerieOriginal, oSolicitud.NumeroOriginal) +
      ' NO encolada: la factura rectificativa carece de serie/numero ' +
      'validos (recibido ' + FormatearDocumento(
        CrearFormatoDocumentoLecturas(AConn).LeerFormatoFactura(
          oSolicitud.SerieOriginal, oSolicitud.NumeroOriginal),
        oSolicitud.SerieRectificativa, oSolicitud.NumeroRectificativa) + ')', '',
      oSolicitud.SerieOriginal, oSolicitud.NumeroOriginal);
    Exit;
  end;
  // Vínculo y emisión en una sola transacción: una rectificativa a
  // medio enlazar dejaría la original apuntando a un borrador fantasma.
  bTransaccionPropia := not AConn.InTransaction;
  if bTransaccionPropia then
    AConn.StartTransaction;
  try
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := AConn;
      MarcarRectificativaVinculada(Qry, oSolicitud);
      if oSolicitud.EmitirAhora then
        EnlazarOriginalConRectificativa(Qry, oSolicitud.Usuario,
          oSolicitud.SerieOriginal, oSolicitud.NumeroOriginal,
          oSolicitud.SerieRectificativa, oSolicitud.NumeroRectificativa);
      // Histórico N:1: cada rectificativa conserva su propio enlace
      // aunque la original se rectifique varias veces
      RegistrarRelacionFactura(AConn, oSolicitud.Usuario,
        oSolicitud.SerieRectificativa, oSolicitud.NumeroRectificativa,
        oSolicitud.SerieOriginal, oSolicitud.NumeroOriginal, 'RECTIFICA');
      // Un borrador no desplaza a la rectificativa ya emitida.
      if not oSolicitud.EmitirAhora then
        RecalcularRectificativaVigente(Qry, oSolicitud.Usuario,
          oSolicitud.SerieOriginal, oSolicitud.NumeroOriginal);
      if oSolicitud.EmitirAhora then
      begin
        // Solo se retiran los movimientos de la original cuando quien
        // rectifica crea los sustitutos (caja). La incidencia fiscal R4
        // duplica la factura sin generar movimientos, asi que pide
        // conservarlos: borrarlos dejaria la venta sin descontar stock.
        if oSolicitud.ReemplazarMovimientosOriginales then
          BorrarMovimientosFactura(Qry, oSolicitud.SerieOriginal,
            oSolicitud.NumeroOriginal);
        oEmision := TSolicitudEmisionFiscal.ParaAlta(
          oSolicitud.SerieRectificativa,
          oSolicitud.NumeroRectificativa,
          oSolicitud.Usuario,
          oSolicitud.DescripcionEvento);
        AServicioEmision.Emitir(oEmision);
        if oSolicitud.TipoRectificativa = 'S' then
          RetirarVentaSustituida(AParametrosCaja, Qry, oSolicitud.Usuario,
            oSolicitud.SerieOriginal, oSolicitud.NumeroOriginal);
      end;
    finally
      FreeAndNil(Qry);
    end;
    if bTransaccionPropia then
      AConn.Commit;
  except
    if bTransaccionPropia and AConn.InTransaction then
      AConn.Rollback;
    raise;
  end;
end;
class procedure TOperacionesVerifactuColaUniDAC.EncolarRectificativa(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  AConn: TUniConnection;
  const AServicioEmision: IServicioEmisionFiscal;
  const AUsuario, ASerieOriginal, ANumeroOriginal,
  ASerieRect, ANumeroRect, ATipoRectificativa: string;
  ABorrarMovimientosOriginales: Boolean);
var
  oSolicitud: TSolicitudVinculoRectificativa;
begin
  if not Assigned(AServicioEmision) then
    raise EArgumentNilException.Create('AServicioEmision');
  oSolicitud := Default(TSolicitudVinculoRectificativa);
  oSolicitud.Usuario := AUsuario;
  oSolicitud.SerieOriginal := ASerieOriginal;
  oSolicitud.NumeroOriginal := ANumeroOriginal;
  oSolicitud.SerieRectificativa := ASerieRect;
  oSolicitud.NumeroRectificativa := ANumeroRect;
  oSolicitud.TipoRectificativa := ATipoRectificativa;
  oSolicitud.ReemplazarMovimientosOriginales :=
    ABorrarMovimientosOriginales;
  oSolicitud.EmitirAhora := True;
  VincularRectificativa(AParametrosApp, AParametrosCaja, AConn,
    AServicioEmision, oSolicitud);
end;
class procedure TOperacionesVerifactuColaUniDAC.CompletarRectificativa(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  AConn: TUniConnection;
  const AUsuario, ASerieRect, ANumeroRect: string);
var
  Qry: TUniQuery;
  sSerieOriginal: string;
  sNumeroOriginal: string;
  sTipoRectificativa: string;
  sFaseOriginal: string;
  bReemplazarMovimientos: Boolean;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    // Último vínculo RECTIFICA de la rectificativa que se consolida.
    Qry.SQL.Text :=
      ' SELECT r.SERIE_FAC_ORIGEN_FACREL, r.NUMERO_FAC_ORIGEN_FACREL, ' +
      '        f.TIPO_RECTIFICATIVA_FAC, f.ESMUEVE_STOCK_FAC, ' +
      '        o.FASE_FAC AS FASE_ORIGINAL ' +
      ' FROM fza_facturas f ' +
      ' JOIN fza_facturas_relaciones r ' +
      '   ON r.SERIE_FAC_FACREL = f.SERIE_FAC ' +
      '  AND r.NUMERO_FAC_FACREL = f.NUMERO_FAC ' +
      '  AND r.TIPO_RELACION_FACREL = ''RECTIFICA'' ' +
      ' JOIN fza_facturas o ' +
      '   ON o.SERIE_FAC = r.SERIE_FAC_ORIGEN_FACREL ' +
      '  AND o.NUMERO_FAC = r.NUMERO_FAC_ORIGEN_FACREL ' +
      ' WHERE f.SERIE_FAC = :SERIE ' +
      '   AND f.NUMERO_FAC = :NUMERO ' +
      '   AND f.TIPO_FAC = ''RECTIFICATIVA'' ' +
      ' ORDER BY r.ID_FACREL DESC LIMIT 1 FOR UPDATE';
    Qry.ParamByName('SERIE').AsString := ASerieRect;
    Qry.ParamByName('NUMERO').AsString := ANumeroRect;
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      sSerieOriginal :=
        Qry.FieldByName('SERIE_FAC_ORIGEN_FACREL').AsString;
      sNumeroOriginal :=
        Qry.FieldByName('NUMERO_FAC_ORIGEN_FACREL').AsString;
      sTipoRectificativa := UpperCase(Trim(
        Qry.FieldByName('TIPO_RECTIFICATIVA_FAC').AsString));
      sFaseOriginal := Qry.FieldByName('FASE_ORIGINAL').AsString;
      bReemplazarMovimientos := (sTipoRectificativa = 'S') and
        SameText(Trim(Qry.FieldByName('ESMUEVE_STOCK_FAC').AsString),
          'S');
      Qry.Close;
      // Una original anulada conserva su fase: el vínculo queda en el
      // histórico sin resucitarla.
      if not EsFaseFacturaAnulada(sFaseOriginal) then
        EnlazarOriginalConRectificativa(Qry, AUsuario,
          sSerieOriginal, sNumeroOriginal, ASerieRect, ANumeroRect);
      if sTipoRectificativa = 'S' then
      begin
        // La sustitutiva que reemplaza los movimientos retira los de la
        // original antes de que la consolidación genere los suyos.
        if bReemplazarMovimientos then
          BorrarMovimientosFactura(Qry, sSerieOriginal, sNumeroOriginal);
        RetirarVentaSustituida(AParametrosCaja, Qry, AUsuario,
          sSerieOriginal, sNumeroOriginal);
      end;
      RegistrarEventoVerifactu(AParametrosApp, AConn, AUsuario,
        cEventoVerifactuInfo,
        'Rectificativa consolidada: la factura ' +
        FormatearReferenciaFactura(AConn,
          sSerieOriginal, sNumeroOriginal) + ' pasa a RECTIFICADA',
        'Tipo ' + sTipoRectificativa, ASerieRect, ANumeroRect);
    end;
  finally
    FreeAndNil(Qry);
  end;
end;
class procedure TOperacionesVerifactuColaUniDAC.DesvincularRectificativa(
  AConn: TUniConnection;
  const AUsuario, ASerieRect, ANumeroRect: string);
var
  Qry: TUniQuery;
  QryOriginal: TUniQuery;
  Originales: TStringList;
  i: Integer;
begin
  Qry := TUniQuery.Create(nil);
  QryOriginal := TUniQuery.Create(nil);
  Originales := TStringList.Create;
  try
    Qry.Connection := AConn;
    QryOriginal.Connection := AConn;
    Qry.SQL.Text :=
      ' SELECT r.SERIE_FAC_ORIGEN_FACREL, r.NUMERO_FAC_ORIGEN_FACREL, ' +
      '        (SELECT COUNT(*) FROM fza_facturas_relaciones r2 ' +
      '          WHERE r2.SERIE_FAC_ORIGEN_FACREL = ' +
      '                r.SERIE_FAC_ORIGEN_FACREL ' +
      '            AND r2.NUMERO_FAC_ORIGEN_FACREL = ' +
      '                r.NUMERO_FAC_ORIGEN_FACREL ' +
      '            AND r2.TIPO_RELACION_FACREL = ''RECTIFICA'' ' +
      '            AND r2.ID_FACREL <> r.ID_FACREL) AS OTRAS ' +
      ' FROM fza_facturas_relaciones r ' +
      ' WHERE r.SERIE_FAC_FACREL = :SERIE ' +
      '   AND r.NUMERO_FAC_FACREL = :NUMERO ' +
      '   AND r.TIPO_RELACION_FACREL = ''RECTIFICA''';
    Qry.ParamByName('SERIE').AsString := ASerieRect;
    Qry.ParamByName('NUMERO').AsString := ANumeroRect;
    Qry.Open;
    // La original sólo recupera su fase de registro si el borrador
    // borrado era su única rectificativa y la dejó en RECTIFICADA (una
    // rectificativa emitida y reabierta); la fase se deduce del registro
    // fiscal que conserva.
    QryOriginal.SQL.Text :=
      ' UPDATE fza_facturas f ' +
      ' SET SERIE_FAC_ABONO_FAC = NULL, ' +
      '     NUMERO_FAC_ABONO_FAC = NULL, ' +
      '     FASE_FAC = CASE ' +
      '       WHEN :OTRAS > 0 OR f.FASE_FAC <> ''RECTIFICADA'' ' +
      '         THEN f.FASE_FAC ' +
      '       WHEN EXISTS (SELECT 1 FROM fza_facturas_consolidaciones c ' +
      '                     WHERE c.SERIE_FAC_FACCON = f.SERIE_FAC ' +
      '                       AND c.NUMERO_FAC_FACCON = f.NUMERO_FAC ' +
      '                       AND c.ESTADO_FACCON LIKE ''NOVERIF%'') ' +
      '         THEN ''NOVERIFACTU_OK'' ' +
      '       WHEN EXISTS (SELECT 1 FROM fza_facturas_consolidaciones c ' +
      '                     WHERE c.SERIE_FAC_FACCON = f.SERIE_FAC ' +
      '                       AND c.NUMERO_FAC_FACCON = f.NUMERO_FAC ' +
      '                       AND c.ESTADO_FACCON LIKE ''VERIFACTU%'') ' +
      '         THEN ''VERIFACTU_OK'' ' +
      '       WHEN EXISTS (SELECT 1 FROM fza_verifactu_cola q ' +
      '                     WHERE q.SERIE_FAC_VFCOLA = f.SERIE_FAC ' +
      '                       AND q.NUMERO_FAC_VFCOLA = f.NUMERO_FAC ' +
      '                       AND q.TIPO_OPERACION_VFCOLA = ''ALTA'') ' +
      '         THEN ''VERIFACTU_PENDIENTE'' ' +
      '       WHEN f.ESCONSOLIDADA_FAC = ''S'' THEN ''SIN_VERIFACTU'' ' +
      '       ELSE ''BORRADOR'' END, ' +
      '     INSTANTE_MODIF = NOW(), ' +
      '     USUARIO_MODIF  = :USUARIO ' +
      ' WHERE f.SERIE_FAC  = :SERIEORIG ' +
      '   AND f.NUMERO_FAC = :NUMEROORIG ' +
      '   AND f.SERIE_FAC_ABONO_FAC  = :SERIERECT ' +
      '   AND f.NUMERO_FAC_ABONO_FAC = :NUMERORECT';
    while not Qry.Eof do
    begin
      QryOriginal.ParamByName('OTRAS').AsInteger :=
        Qry.FieldByName('OTRAS').AsInteger;
      QryOriginal.ParamByName('USUARIO').AsString := AUsuario;
      QryOriginal.ParamByName('SERIEORIG').AsString :=
        Qry.FieldByName('SERIE_FAC_ORIGEN_FACREL').AsString;
      QryOriginal.ParamByName('NUMEROORIG').AsString :=
        Qry.FieldByName('NUMERO_FAC_ORIGEN_FACREL').AsString;
      QryOriginal.ParamByName('SERIERECT').AsString := ASerieRect;
      QryOriginal.ParamByName('NUMERORECT').AsString := ANumeroRect;
      QryOriginal.Execute;
      Originales.Add(
        Qry.FieldByName('SERIE_FAC_ORIGEN_FACREL').AsString + '=' +
        Qry.FieldByName('NUMERO_FAC_ORIGEN_FACREL').AsString);
      Qry.Next;
    end;
    Qry.Close;
    Qry.SQL.Text :=
      ' DELETE FROM fza_facturas_relaciones ' +
      ' WHERE SERIE_FAC_FACREL = :SERIE ' +
      '   AND NUMERO_FAC_FACREL = :NUMERO ' +
      '   AND TIPO_RELACION_FACREL = ''RECTIFICA''';
    Qry.ParamByName('SERIE').AsString := ASerieRect;
    Qry.ParamByName('NUMERO').AsString := ANumeroRect;
    Qry.Execute;
    // FZ-ISSUE-132: la original vuelve a apuntar a la rectificativa que
    // sigue vigente en lugar de quedarse sin enlace.
    for i := 0 to Originales.Count - 1 do
      RecalcularRectificativaVigente(QryOriginal, AUsuario,
        Originales.Names[i], Originales.ValueFromIndex[i]);
  finally
    FreeAndNil(Originales);
    FreeAndNil(QryOriginal);
    FreeAndNil(Qry);
  end;
end;
class procedure TOperacionesVerifactuColaUniDAC.RegistrarRelacionFactura(
  AConn: TUniConnection;
  const AUsuario, ASerie, ANumero,
  ASerieOrigen, ANumeroOrigen, ATipoRelacion: string);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      ' INSERT INTO fza_facturas_relaciones ' +
      ' (SERIE_FAC_FACREL, NUMERO_FAC_FACREL, ' +
      '  SERIE_FAC_ORIGEN_FACREL, NUMERO_FAC_ORIGEN_FACREL, ' +
      '  TIPO_RELACION_FACREL, INSTANTE_ALTA, USUARIO_ALTA) ' +
      ' VALUES (:SERIE, :NUMERO, :SERIEORIG, :NUMEROORIG, :TIPO, ' +
      '         NOW(), :USUARIO) ' +
      ' ON DUPLICATE KEY UPDATE ' +
      '  SERIE_FAC_ORIGEN_FACREL  = :SERIEORIG, ' +
      '  NUMERO_FAC_ORIGEN_FACREL = :NUMEROORIG, ' +
      '  INSTANTE_MODIF = NOW(), ' +
      '  USUARIO_MODIF  = :USUARIO';
    Qry.ParamByName('SERIE').AsString      := ASerie;
    Qry.ParamByName('NUMERO').AsString     := ANumero;
    Qry.ParamByName('SERIEORIG').AsString  := ASerieOrigen;
    Qry.ParamByName('NUMEROORIG').AsString := ANumeroOrigen;
    Qry.ParamByName('TIPO').AsString       := ATipoRelacion;
    Qry.ParamByName('USUARIO').AsString    := AUsuario;
    Qry.Execute;
  finally
    FreeAndNil(Qry);
  end;
end;
end.
