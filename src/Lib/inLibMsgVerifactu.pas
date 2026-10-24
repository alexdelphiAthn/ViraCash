{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgVerifactu                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mensajes de emisión fiscal, firma y comunicaciones Verifactu.             }
{******************************************************************************}
unit inLibMsgVerifactu;

interface

resourcestring
  SErrorRepositorioExportacionNoVerifactuNoRegistrado =
    'No se ha registrado el repositorio de exportación NO VERI*FACTU.';
  SErrorRespuestaNtpNoValida =
    'sin respuesta NTP válida';
  SInfoRelojFiscalCorrecto =
    'Reloj fiscal correcto. Servidor=%s, diferencia=%d s.';
  SErrorRelojSistemaFueraMargenLegal =
    'Reloj del sistema fuera de margen legal. Servidor=%s, ' +
    'diferencia=%d s, margen=%d s.';
  SErrorComprobarRelojFiscalNtp =
    'No se pudo comprobar el reloj fiscal contra NTP.';
  SErrorExportarNoVerifactuSinCertificado =
    'No se puede exportar NO VERI*FACTU legal: el modo NO VERI*FACTU ' +
    'exige firma electrónica con certificado oficial.';
  SErrorExportarNoVerifactuSinColumnasEventos =
    'No se puede exportar NO VERI*FACTU legal: faltan columnas de firma ' +
    'en fza_verifactu_eventos.';
  SErrorExportarNoVerifactuSinColumnasFacturacion =
    'No se puede exportar NO VERI*FACTU legal: faltan columnas de firma ' +
    'en fza_facturas_consolidaciones.';
  SErrorExportarNoVerifactuRegistrosSinFirma =
    'No se puede exportar NO VERI*FACTU legal: %d evento(s) y %d ' +
    'registro(s) de facturación no tienen firma XAdES y datos de ' +
    'certificado.';
  SErrorConexionExportarNoVerifactu =
    'No hay conexión para exportar NO VERI*FACTU.';
  SErrorArchivoBaseExportacionNoIndicado =
    'No se ha indicado archivo base de exportación.';
  STextoTipoError = 'ERROR';
  STextoTipoAviso = 'AVISO';
  SFormatoDetalleVerificacion = '%s: %s';
  SErrorModoExportacionNoCoincide =
    '%s: ModoVerifactu no coincide con el otro fichero.';
  SErrorXmlFirmadoNoLegible =
    '%s: el XML firmado no se puede leer.';
  SErrorFirmaEventoRaizIncorrecta =
    '%s: la firma de evento debe envolver RegistroEvento.';
  SErrorEventoFirmadoNoEncontrado =
    '%s: falta el nodo Evento firmado.';
  SErrorFirmaXadesNodoAeatIncorrecto =
    '%s: la firma XAdES no está en el nodo exigido por AEAT.';
  SErrorFirmaXadesSinCertificado =
    '%s: falta certificado X509 en KeyInfo.';
  SErrorFirmaXadesSinSignedInfo =
    '%s: falta SignedInfo.';
  SErrorCanonicalizacionFirmaAeat =
    '%s: CanonicalizationMethod no coincide con AEAT.';
  SErrorMetodoFirmaNoRsaSha256 =
    '%s: SignatureMethod debe ser RSA-SHA256.';
  SErrorReferenciasSignedInfo =
    '%s: SignedInfo debe tener referencia al documento y a ' +
    'SignedProperties.';
  SErrorReferenciaDocumentoFirmado =
    '%s: falta Reference URI vacío al registro firmado.';
  SErrorTransformacionFirmaEnveloped =
    '%s: falta transform enveloped-signature.';
  SErrorDigestRegistroNoSha256 =
    '%s: digest del registro debe ser SHA-256.';
  SErrorReferenciaSignedProperties =
    '%s: falta Reference a SignedProperties.';
  SErrorCanonicalizacionSignedProperties =
    '%s: SignedProperties no usa canonicalizacion AEAT.';
  SErrorDigestSignedPropertiesNoSha256 =
    '%s: digest de SignedProperties debe ser SHA-256.';
  SErrorQualifyingPropertiesXades =
    '%s: falta QualifyingProperties XAdES.';
  SErrorSignedPropertiesXades =
    '%s: falta SignedProperties XAdES.';
  SErrorSigningCertificateXades =
    '%s: falta SigningCertificate.';
  SErrorPoliticaFirmaAge =
    '%s: falta politica de firma AGE.';
  SErrorIdentificadorPoliticaAge =
    '%s: identificador de politica AGE incorrecto.';
  SErrorDigestPoliticaAgeNoSha1 =
    '%s: digest de politica AGE debe ser SHA-1.';
  SErrorDigestValuePoliticaAge =
    '%s: DigestValue de politica AGE incorrecto.';
  SErrorUrlPoliticaAge =
    '%s: URL de politica AGE incorrecta.';
  SFormatoEtiquetaEvento = 'Evento %s';
  SErrorEventoHashPropioNoSha256 =
    'Evento %s: HashPropio no es SHA-256 hexadecimal.';
  SAvisoEventoPrimerHashAnteriorNoCero =
    'Evento %s: primer HashAnterior no es cero.';
  SErrorEventoHashAnteriorNoCoincide =
    'Evento %s: HashAnterior no coincide con el evento anterior.';
  SErrorEventoSinRegistroXmlFirmado =
    'Evento %s: falta RegistroXmlFirmado.';
  SErrorEventoHuellaNoCoincide =
    'Evento %s: HuellaEvento no coincide con HashPropio.';
  SErrorEventoFirmaGuardadaSinFirmaXml =
    'Evento %s: hay FirmaXades pero el XML no contiene firma.';
  SErrorEventoSinFirmaXades =
    'Evento %s: falta FirmaXades legal.';
  SErrorEventoSignatureValueNoCoincide =
    'Evento %s: SignatureValue no coincide con FirmaXades.';
  SErrorEventoFirmaDigitalNoCoincide =
    'Evento %s: FirmaDigital no coincide con FirmaXades.';
  SErrorFacturaSinFirmaDigitalXades =
    'Factura %s: falta FirmaDigitalXades legal.';
  STextoEventos = 'Eventos';
  SErrorFicheroEventosNoExiste =
    'No existe el fichero de eventos: %s';
  SErrorFicheroEventosRaizIncorrecta =
    'El fichero de eventos no tiene la raiz esperada.';
  SErrorFicheroEventosVacio =
    'El fichero de eventos no contiene eventos.';
  SErrorVerificarEventos =
    'No se pudo verificar eventos: %s';
  SInfoVerificacionCorrecta = 'Verificacion correcta.';
  SFormatoModoActual = '%s (modo actual)';
  SResumenVerificacionNoVerifactu =
    'Modo: %s' + sLineBreak +
    'Eventos: %d' + sLineBreak +
    'Registros de facturacion: %d' + sLineBreak +
    'Errores: %d' + sLineBreak +
    'Avisos: %d';
  SErrorAbrirProveedorCriptografico =
    'No se pudo abrir el proveedor criptográfico.';
  SErrorCrearHashCriptografico =
    'No se pudo crear el hash criptográfico.';
  SErrorCalcularHash = 'No se pudo calcular el hash.';
  SErrorObtenerTamanoHash =
    'No se pudo obtener el tamaño del hash.';
  SErrorObtenerValorHash =
    'No se pudo obtener el valor del hash.';
  SErrorOperacionCriptografica =
    '%s. Código: %s. %s';
  SErrorProveedorCertificadoSinSha256 =
    'El proveedor criptográfico del certificado no admite SHA-256 para ' +
    'firma RSA. No se puede generar XAdES rsa-sha256 con ese certificado ' +
    'tal como está instalado. Reinstala o importa el certificado con un ' +
    'proveedor compatible con SHA-256, como Microsoft Enhanced RSA and ' +
    'AES Cryptographic Provider o Microsoft Software Key Storage ' +
    'Provider. %s';
  STextoCertificadoTodaviaNoValido =
    'todavía no es válido';
  STextoCertificadoCaducado = 'está caducado';
  SErrorCertificadoNoVigente =
    'El certificado configurado %s. Vigencia: %s - %s. Seleccione un ' +
    'certificado vigente en la ficha de empresa.';
  SErrorCertificadoVigenteNoEncontrado =
    'No se encontró en el almacén personal de Windows un certificado ' +
    'vigente que coincida con el número de serie o titular configurado.';
  SErrorCertificadoEmpresaNoConfigurado =
    'No hay un certificado configurado en la ficha de la empresa.';
  SErrorCrearHashSha256Firma =
    'No se pudo crear el hash SHA-256 para firmar';
  SErrorCargarDatosFirma =
    'No se pudieron cargar los datos a firmar';
  SErrorCalcularTamanoFirmaSha256 =
    'No se pudo calcular el tamaño de la firma SHA-256';
  SErrorFirmarSha256 = 'No se pudo firmar con SHA-256';
  SErrorCalcularTamanoFirmaNCrypt =
    'NCryptSignHash falló al calcular el tamaño de la firma. Código: %d';
  SErrorFirmaNCrypt =
    'NCryptSignHash falló al firmar. Código: %d';
  SErrorAbrirClavePrivadaCertificado =
    'No se pudo abrir la clave privada del certificado';
  SErrorXmlMalFormadoCanonicalizar =
    'XML mal formado al canonicalizar.';
  SErrorElementoRaizXmlNoEncontrado =
    'No se encontró el elemento raiz del XML.';
  SErrorNombreNodoRaizNoDeterminado =
    'No se pudo determinar el nombre del nodo raiz.';
  SErrorCierreAperturaRaizNoEncontrado =
    'No se encontró el cierre de la apertura raiz.';
  SErrorCierreNodoRaizNoEncontrado =
    'No se encontró el cierre del nodo raiz %s.';
  SErrorCierreNodoNoEncontrado =
    'No se encontró el cierre del nodo %s.';
  SErrorNifProductorEventoVerifactuInvalido =
    'Parámetro appVerifactuSifNif vacío o no válido: "%s".';
  SErrorEmpresaEventosVerifactuNoConfigurada =
    'No hay empresa configurada para registrar eventos Verifactu.';
  SErrorNifEmisorEventoNoVerifactuInvalido =
    'NIF de la empresa emisora vacío o no válido para firmar eventos ' +
    'NO VERI*FACTU: "%s".';
  SErrorEmpresaSinNifEmisionFiscal =
    'La empresa %s no tiene un NIF válido para la emisión fiscal.';
  SErrorNifProductorVerifactuInvalido =
    'El parámetro appVerifactuSifNif no contiene un NIF de productor ' +
    'válido.';
  SErrorProductorSoftwareVerifactuNoAutorizado =
    'Parámetro appVerifactuSifNombreRazon (productor del software) no ' +
    'válido: "%s". No corresponde al productor de ViraCash.';
  SErrorNifProductorSoftwareVerifactuNoAutorizado =
    'Parámetro appVerifactuSifNif (NIF del productor del software) no ' +
    'válido: "%s". No corresponde al productor de ViraCash.';
  SErrorCertificadoFiscalEmpresaNoUtilizable =
    'La empresa %s no dispone de un certificado fiscal utilizable: %s';
  SErrorFirmaCertificadoNoVerifactuDesactivada =
    'El modo NO VERI*FACTU exige activar la firma con certificado en ' +
    'appVerifactuFirmaCertificado.';
  SErrorCertificadoEventosNoVerifactuNoConfigurado =
    'No hay certificado configurado en Empresas para firmar eventos ' +
    'NO VERI*FACTU.';
  SErrorFirmarEventoNoVerifactu =
    'No se pudo firmar el evento NO VERI*FACTU: %s';
  SErrorRelojEventoNoVerifactu =
    'No se pudo validar el reloj del evento NO VERI*FACTU: %s';
  STextoRegistroFacturacionNoVerifactu =
    'Registro de facturación NO VERI*FACTU';
  SErrorFirmaRegistroNoVerifactuObligatoria =
    'El modo NO VERI*FACTU exige firmar el registro de facturación con ' +
    'certificado oficial.';
  SErrorNifProductorSoftwareVerifactuInvalido =
    'Parámetro appVerifactuSifNif (NIF del productor del software) vacío ' +
    'o no válido: "%s". Rellenarlo en Parámetros de aplicación, categoría ' +
    'Verifactu.';
  SErrorNifEmisorVerifactuInvalido =
    'NIF de la empresa emisora vacío o no válido para Verifactu: "%s". ' +
    'Revisar la ficha de la empresa (NIF de 9 caracteres, sin guiones).';
  SErrorFacturaRegistroFiscalNoEncontrada =
    'Factura %s\%s no encontrada para el registro fiscal';
  SAvisoQrPngNoGenerado =
    '(QR PNG no generado: %s) ';
  SErrorFacturaEnvioVerifactuNoEncontrada =
    'Factura %s\%s no encontrada para el envío Verifactu';
  SErrorRespuestaServicioInesperada =
    'Respuesta inesperada del servicio';
  SErrorRespuestaHttpAeat = 'AEAT HTTP %d: %s';
  SErrorRespuestaAeatNoDefinitiva =
    'AEAT HTTP %d sin respuesta válida del servicio (proxy, portal o ' +
    'respuesta incompleta): se reintentará sin consumir intento';
  // FZ-ISSUE-308: con lo que contestó el SII (respuesta completa en el log)
  SErrorRespuestaSiiNoDefinitiva =
    'AEAT HTTP %d sin respuesta válida del SII; ha contestado: «%s». Se ' +
    'reintentará sin consumir intento (respuesta completa en el log)';
  SErrorRespuestaSiiPaginaWeb =
    'AEAT HTTP %d: en lugar del servicio del SII ha llegado una página web ' +
    '(«%s»). Suele ser el certificado de cliente (no se envía o no vale ' +
    'para el SII de este entorno) o un proxy. Se reintentará sin consumir ' +
    'intento (respuesta completa en el log)';
  SRespuestaSiiVacia = 'respuesta vacía';
  SErrorEnvioVerifactuCancelado =
    'Envío Verifactu interrumpido por el cierre de la aplicación: se ' +
    'reenviará el mismo registro';
  SErrorRegistroEnVueloPendiente =
    'Registro Verifactu en vuelo sin respuesta definitiva: se reenviará ' +
    'el mismo registro antes que ningún otro';
  SErrorRespuestaRegistroAeat = 'AEAT [%s] %s';
  SErrorEstadoEnvioAeat = 'EstadoEnvio: %s';
  SErrorServicioInstalacionHttp =
    'El servicio respondió con HTTP %d.';
  SErrorReferenciaGlobalInstalacionFaltante =
    'Falta la referencia global de la instalación.';
  SErrorServicioJsonInvalido =
    'El servicio no devolvió JSON válido.';
  SErrorServicioSinNumeroInstalacion =
    'El servicio no devolvió NumeroInstalacion.';
  SErrorServicioSinDatosDeclaracion =
    'El servicio no devolvió los datos de la declaración responsable.';
  SErrorDeclaracionVersionNoSolicitada =
    'La declaración recibida no corresponde a la versión solicitada.';
  SErrorDeclaracionSifIncorrecto =
    'La declaración recibida no corresponde al SIF FZ.';
  SErrorDeclaracionDescargadaVacia =
    'La declaración descargada está vacía.';
  SErrorPaginaPublicaHttp =
    'La página pública respondió con HTTP %d.';
  SErrorDeclaracionPaginaPublicaOtraVersion =
    'La página pública corresponde a otra versión.';
  SErrorDeclaracionResponsableNoDisponible =
    'No hay una declaración responsable disponible para la versión %s.' +
    #13#10 + 'Webservice: %s' + #13#10 + 'Caché: %s' +
    #13#10 + 'Página pública: %s';
  SDetalleDeclaracionNoDisponible = 'No disponible';
  SErrorEmpresaInstalacionSifNoConfigurada =
    'No hay empresa configurada para solicitar el número de instalación ' +
    'SIF.';
  SErrorEmpresaSinRazonSocial =
    'La empresa no tiene razón social.';
  SErrorNifEmpresaInstalacionInvalido =
    'El NIF de la empresa no es válido: "%s".';
  SErrorEmpresaSinNumeroInstalacionSif =
    'La empresa %s (%s) no tiene número de instalación SIF. Genéralo desde ' +
    'Archivo > Empresas.';
  SErrorNumeroInstalacionSifIncorrecto =
    'El número de instalación SIF de la empresa %s no corresponde al SIF ' +
    'FZ.';
  SErrorNumeroInstalacionSinVersion =
    'El número de instalación SIF de la empresa %s no tiene versión ' +
    'asociada. Genéralo de nuevo desde Archivo > Empresas.';
  SErrorVersionNumeroInstalacionIncorrecta =
    'El número de instalación SIF de la empresa %s fue generado para la ' +
    'versión %s y la versión actual es %s. Genéralo de nuevo desde ' +
    'Archivo > Empresas.';
  SAvisoSincronizacionInstalacionSifFallida =
    'No se pudo registrar la versión %s en el número de instalación SIF ' +
    'de las empresas.' + sLineBreak + sLineBreak +
    '%s' + sLineBreak + sLineBreak +
    'Mientras no se registre, las facturas con VERI*FACTU darán error al ' +
    'emitirse. Comprueba la conexión a Internet (una VPN o un cortafuegos ' +
    'pueden impedirla) y vuelve a abrir el programa, o genéralo desde ' +
    'Archivo > Empresas.';
  SInfoExportacionNoVerifactuGenerada =
    'Exportación NO VERI*FACTU generada:' + sLineBreak +
    '%s' + sLineBreak +
    '%s' + sLineBreak + sLineBreak +
    'Eventos: %d' + sLineBreak +
    'Registros de facturacion: %d' + sLineBreak +
    'Firmas: registros internos XAdES';
  SInfoVerificacionNoVerifactuCorrecta =
    'Verificacion NO VERI*FACTU correcta.' + sLineBreak +
    '%s' + sLineBreak + sLineBreak +
    'Informe:' + sLineBreak + '%s';
  SErrorVerificacionNoVerifactu =
    'Verificacion NO VERI*FACTU con errores.' + sLineBreak +
    '%s' + sLineBreak + sLineBreak +
    'Informe:' + sLineBreak + '%s';
  SInfoAnulacionVerifactuEncolada =
    'Anulación encolada: el hilo Verifactu la enviará en el próximo ciclo.';
  SInfoAnulacionNoVerifactuRegistrada =
    'Anulación registrada y firmada en NO VERI*FACTU.';
  SInfoAnulacionSinVerifactuRegistrada =
    'Anulación registrada en modo SIN VERIFACTU.';
  SInfoAccionFiscalEncolada =
    '%s encolada: el hilo Verifactu la enviará en el próximo ciclo. Puede ' +
    'seguirla en la columna "Cola Verifactu" y en Verifactu - Cola de ' +
    'Envíos.';
  SInfoAccionFiscalNoVerifactu =
    '%s registrada y firmada en NO VERI*FACTU.';
  SInfoAccionFiscalSinVerifactu =
    '%s registrada en modo SIN VERIFACTU.';
  SErrorTipoRectificativaFiscalInvalido =
    'El tipo fiscal de rectificativa debe ser I o S.';
  SErrorTipoFacturaVerifactuRectificativaInvalido =
    'El tipo VERI*FACTU de la rectificativa debe ser R1, R2, R3, R4 o R5.';
  SErrorIncidenciaFacturaNoSeleccionada =
    'Seleccione una factura para resolver la incidencia VERI*FACTU.';
  SErrorIncidenciaSoloVentaMayor =
    'La resolución guiada solo está disponible para facturas de venta ' +
    'mayor.';
  SErrorIncidenciaNoAceptadaConErrores =
    'Solo se puede resolver por esta vía un registro aceptado con errores.';
  SErrorIncidenciaSubsanacionActiva =
    'Ya existe una subsanación pendiente, procesándose o enviada.';
  // FZ-ISSUE-135: corrección guiada de un registro rechazado por la AEAT
  SPreguntaCorregirRechazoAeat =
    'La AEAT no ha registrado la factura %s\%s:' + sLineBreak +
    '%s' + sLineBreak + sLineBreak +
    'Se devolverá a BORRADOR y se anulará su envío para que corrija ' +
    'los datos y pulse Consolidar para relanzarla.' + sLineBreak +
    '¿Continuar?';
  SInfoMotivoRechazoAeatDesconocido =
    '(sin motivo registrado; consulte Verifactu > Cola de envíos)';
  SInfoRechazoAeatDestinatario =
    'El error está en los datos del destinatario: revise el NIF y la ' +
    'razón social en la pestaña Cliente antes de consolidar.';
  SAvisoReimprimirRechazoAeat =
    'Si ya entregó o envió la factura impresa, su código QR corresponde ' +
    'a un registro que la AEAT rechazó: reimprímala cuando la AEAT ' +
    'acepte el nuevo envío.';
  SErrorIncidenciaMotivoObligatorio =
    'Indique el motivo de la corrección.';
  SErrorIncidenciaClienteObligatorio =
    'Seleccione el cliente correcto para emitir la rectificativa R4.';
  SErrorIncidenciaSerieRectificativaObligatoria =
    'Indique la serie de la factura rectificativa.';
  SErrorIncidenciaFechaRectificativaObligatoria =
    'Indique la fecha de la factura rectificativa.';
  SErrorIncidenciaClienteNoEncontrado =
    'No existe el cliente %s.';
  SErrorIncidenciaClienteSinNif =
    'El cliente %s no tiene identificación fiscal.';
  SErrorIncidenciaRectificativaExistente =
    'La factura %s\%s ya tiene asociada la rectificativa %s\%s.';
  SErrorIncidenciaCrearRectificativa =
    'No se pudo crear la factura rectificativa R4.';
  SErrorIncidenciaEncolarSubsanacion =
    'No se pudo encolar la subsanación. Revise que el registro continúe ' +
    'aceptado con errores y que no exista otra subsanación activa.';
  SErrorIncidenciaEstadoCambio =
    'La subsanación ya no parte de un registro aceptado con errores.';
  SErrorSubsanacionTransaccion =
    'La corrección fiscal requiere una transacción activa.';
  SInfoSubsanacionNoVerifactuRegistrada =
    'Subsanación NO VERI*FACTU registrada';
  SInfoSubsanacionNoVerifactuMotivo = 'Motivo: %s';
  SErrorSubsanacionRegistroNoVigente =
    'La factura no tiene un registro fiscal aceptado y vigente.';
  SErrorSubsanacionColaActiva =
    'La factura tiene un envío fiscal pendiente, en curso o con errores. ' +
    'Debe resolverse antes de guardar otra subsanación.';
  SInfoIncidenciaSubsanacionEncolada =
    'Subsanación encolada. La factura original permanece inalterada.';
  SInfoIncidenciaRectificativaCreada =
    'Rectificativa R4 %s\%s creada y encolada.';
  STituloResolverIncidenciaVerifactu =
    'Resolver incidencia VERI*FACTU';
  STextoIncidenciaSubsanar =
    'La factura expedida es correcta: subsanar el registro enviado';
  STextoIncidenciaRectificar =
    'El dato incorrecto figura en la factura: emitir rectificativa R4';
  STextoIncidenciaCargarCliente = 'Cargar cliente';
  STextoIncidenciaResolver = 'Resolver';
  STextoIncidenciaCancelar = 'Cancelar';
  STextoIncidenciaFactura = 'Factura original';
  STextoIncidenciaErrorAeat = 'Incidencia comunicada por la AEAT';
  STextoIncidenciaDecision = 'Tratamiento de la incidencia';
  STextoIncidenciaMotivo = 'Motivo de la corrección';
  STextoIncidenciaClienteActual = 'Destinatario de la factura';
  STextoIncidenciaClienteCorrecto = 'Destinatario correcto';
  STextoIncidenciaSerieRectificativa = 'Serie rectificativa';
  STextoIncidenciaFechaRectificativa = 'Fecha rectificativa';
  SInfoBorradorVerifactuPendiente =
    'Borrador %s\%s en VERIFACTU_PENDIENTE: el QR ya puede imprimirse y ' +
    'el envío a la AEAT queda en la cola Verifactu.';
  SInfoBorradorSiiPendiente =
    'Borrador %s\%s en VERIFACTU_PENDIENTE: el envío al SII queda en la ' +
    'cola (las facturas del SII no llevan QR).';
  SInfoBorradorNoVerifactuRegistrado =
    'Borrador %s\%s registrado y firmado en NO VERI*FACTU.';
  SInfoBorradorSinVerifactuEmitido =
    'Borrador %s\%s emitido en modo SIN VERIFACTU.';
  SErrorPrepararImpresionDeclaracionResponsable =
    'No se pudo preparar el documento de impresión.';
  SErrorImprimirDeclaracionResponsable =
    'No se pudo imprimir la declaración responsable:' + sLineBreak;
  SInfoNumeroInstalacionSifDisponible =
    'Número de instalación SIF disponible: ';
  SErrorGenerarNumeroInstalacionSif =
    'No se pudo generar el número de instalación SIF:' + sLineBreak;
  // R11 - Declaración e instalación SIF
  SCaptionNumeroPendiente = '(pendiente)';
  SCaptionInstalacionSifTitulo =
    'Número de instalación SIF - %s (%s)';
  SCaptionInstalacionNumeroVersion = 'Número: %s | Versión: %s';
  SCaptionInstalacionSif = 'Número de instalación SIF';
  SCaptionSinEmpresaConfigurada = 'No hay empresa configurada.';
  SCaptionErrorLeerEmpresas = 'No se pudo leer fza_empresas.';
  SCaptionSolicitandoNumeroServicio =
    'Solicitando número al servicio...';
  SCaptionNumeroDisponibleGuardado = 'Número disponible y guardado.';
  // R16 - Log y exportación NO VERI*FACTU
  STituloGuardarExportacionNoVerifactu =
    'Guardar exportación NO VERI*FACTU';
  STituloVerificarFicherosNoVerifactu =
    'Verificar ficheros NO VERI*FACTU';
  SErrorSiiOperacionNoDisponible =
    'La operación %s todavía no se envía al SII.';
  SErrorColaSiiSinSistema =
    'Modo SII: la base de datos no tiene la columna SISTEMA_VFCOLA ' +
    '(script 791); no se puede encolar la factura.';
  SInfoDeclaracionResponsableNoAplicaSii =
    'Modo SII: los obligados al SII están excluidos del reglamento de ' +
    'sistemas informáticos de facturación (RD 1007/2023), así que no ' +
    'necesitan la declaración responsable. Se muestra solo a título ' +
    'informativo.';
  SAvisoColaSiiFueraDePlazo =
    'En rojo, las filas del SII pendientes o con error con más de %d ' +
    'días naturales desde la fecha de la factura. Aviso por antigüedad; ' +
    'consulte el plazo legal del SII.';
  SCaptionColumnaSistemaColaVerifactu = 'Sistema';
  SErrorSiiTipoRectificativaInvalido =
    'La factura %s %s\%s es rectificativa y su tipo fiscal debe ser I o S.';
  SErrorSiiRectificativaSinImporteOriginal =
    'La rectificativa sustitutiva %s %s\%s no tiene los importes de la ' +
    'factura original.';
  SErrorSiiTipoOperacionDesconocido =
    'El tipo de operación SII "%s" no es válido: use Entrega o ' +
    'PrestacionServicios.';

  SEstadoInstalacionPendiente = 'Pendiente';
  SEstadoInstalacionSifDistinto = 'SIF distinto';
  SEstadoInstalacionRequiereRegenerar = 'Requiere regenerar';
  SEstadoInstalacionValida = 'Válido';
  SCaptionSiEmpresaInstalacion = 'Sí';
  SCaptionNoEmpresaInstalacion = 'No';
  SInfoEmpresasInstalacionNoConfiguradas =
    'No hay empresas configuradas en esta base de datos.';
  SCaptionCodigoEmpresaInstalacion = 'Código';
  SCaptionRazonSocialEmpresaInstalacion = 'Razón social';
  SCaptionNifEmpresaInstalacion = 'NIF';
  SCaptionActivaEmpresaInstalacion = 'Activa';
  SCaptionNumeroEmpresaInstalacion = 'Nº instalación';
  SCaptionVersionEmpresaInstalacion = 'Versión';
  SCaptionSifEmpresaInstalacion = 'SIF';
  SCaptionFechaEmpresaInstalacion = 'Fecha generación';
  SCaptionEstadoEmpresaInstalacion = 'Estado';
  STituloAnexoEmpresasInstalacion =
    'Anexo: empresas e instalaciones SIF';
  SDescripcionAnexoEmpresasInstalacion =
    'Relación de empresas configuradas en ViraCash para el SIF FZ ' +
    'en la versión %s.';
  SErrorDescargarDeclaracionResponsable =
    'No se ha podido descargar la declaración responsable.' +
    #13#10 + #13#10 + 'Versión solicitada: %s' +
    #13#10 + #13#10 + 'Detalle: %s';
  SInfoDescargandoDeclaracionResponsable =
    'Descargando declaración responsable...' + #13#10 + #13#10 +
    'Versión: %s';

  SEstadoInstalacionSifPendienteGenerar =
    'Pendiente de generar desde el servicio.';
  SEstadoInstalacionSifNoCoincide =
    'El SIF guardado no coincide con FZ.';
  SEstadoInstalacionSifVersionPendiente =
    'Pendiente de registrar la versión %s en la instalación SIF.';
  SEstadoInstalacionSifValido =
    'Válido para la versión actual.';

  SErrorReferenciaInstalacionSifNoAutorizada =
    'La API no pertenece a la referencia indicada.';

implementation

end.
