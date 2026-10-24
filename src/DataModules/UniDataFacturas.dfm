inherited dmFacturas: TdmFacturas
  Height = 590
  Width = 1241
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO `fza_facturas`'
      
        '  (' +
      'PORCENTAJE_DTO_COMERCIAL_FAC, TOTAL_DTO_COMERCIAL_FAC, ' +
      'PORCENTAJE_DTO_FINANCIERO_FAC, TOTAL_DTO_FINANCIERO_FAC, ' +
      '`NUMERO_FAC`, `SERIE_FAC`, `FECHA_FAC`, `ESCONSOLIDADA_FAC`, ' +
        '`INSTANTECONSO_FAC`, `TIPO_FAC`, `FASE_FAC`, `CODIGO_EMP_FAC`, `' +
        'RAZON_SOCIAL_EMPRESA_FAC`, `NIF_EMPRESA_FAC`, `MOVIL_EMPRESA_FAC' +
        '`, `EMAIL_EMPRESA_FAC`, `DIRECCION1_EMPRESA_FAC`, `DIRECCION2_EM' +
        'PRESA_FAC`, `POBLACION_EMPRESA_FAC`, `PROVINCIA_EMPRESA_FAC`, `C' +
        'ODIGO_PAI_EMPRESA_FAC`, `NOMBRE_PAI_EMPRESA_FAC`, `CODIGO_POSTAL' +
        '_EMPRESA_FAC`, `ESRETENCIONES_EMPRESA_FAC`, `GRUPO_ZONA_IVA_EMPR' +
        'ESA_FAC`, `ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC`, `CODIGO_CLI_F' +
        'AC`, `RAZON_SOCIAL_CLIENTE_FAC`, `NIF_CLIENTE_FAC`, `MOVIL_CLIEN' +
        'TE_FAC`, `EMAIL_CLIENTE_FAC`, `DIRECCION1_CLIENTE_FAC`, `DIRECCI' +
        'ON2_CLIENTE_FAC`, `POBLACION_CLIENTE_FAC`, `PROVINCIA_CLIENTE_FA' +
        'C`, `CODIGO_POSTAL_CLIENTE_FAC`, `CODIGO_PAI_CLIENTE_FAC`, `NOMB' +
        'RE_PAI_CLIENTE_FAC`, `CODIGO_IVA_FAC`, `ESIVA_RECARGO_CLIENTE_FA' +
        'C`, `ESIVA_EXENTO_CLIENTE_FAC`, `ESREGIMENESPECIALAGRICOLA_CLIEN' +
        'TE_FAC`, `ESRETENCIONES_CLIENTE_FAC`, `TARIFA_ARTICULO_CLIENTE_F' +
        'AC`, `ESIMP_INCL_TARIFA_CLIENTE_FAC`, `ESINTRACOMUNITARIO_CLIENT' +
        'E_FAC`, `ESIRPF_IMP_INCL_ZONA_IVA_FAC`, `ESAPLICA_RE_ZONA_IVA_FA' +
        'C`, `ESIVAAGRICOLA_ZONA_IVA_FAC`, `PALABRA_REPORTS_ZONA_IVA_FAC`' +
        ', `ESVENTA_ACTIVO_FIJO_FAC`, `PORCENTAJE_IVAN_FAC`, `TOTAL_IVAN_' +
        'FAC`, `PORCENTAJE_REN_FAC`, `TOTAL_REN_FAC`, `TOTAL_BASEI_IVAN_F' +
        'AC`, `PORCENTAJE_IVAR_FAC`, `TOTAL_IVAR_FAC`, `PORCENTAJE_RER_FA' +
        'C`, `TOTAL_RER_FAC`, `TOTAL_BASEI_IVAR_FAC`, `PORCENTAJE_IVAS_FA' +
        'C`, `TOTAL_IVAS_FAC`, `PORCENTAJE_RES_FAC`, `TOTAL_RES_FAC`, `TO' +
        'TAL_BASEI_IVAS_FAC`, `PORCENTAJE_IVAE_FAC`, `TOTAL_IVAE_FAC`, `P' +
        'ORCENTAJE_REE_FAC`, `TOTAL_REE_FAC`, `TOTAL_BASEI_IVAE_FAC`, `TO' +
        'TAL_BASES_FAC`, `TOTAL_IMPUESTOS_FAC`, `FORMA_PAGO_FAC`, `PORCEN' +
        'TAJE_RETENCION_FAC`, `TOTAL_RETENCION_FAC`, `TOTAL_LIQUIDO_FAC`,' +
        ' `NUMERO_FAC_ABONO_FAC`, `SERIE_FAC_ABONO_FAC`, `TEXTO_LEGAL_CLI' +
        'ENTE_FAC`, `TEXTO_LEGAL_EMPRESA_FAC`, `DOCUMENTO_FAC`, `COMENTAR' +
        'IOS_FAC`, `CONTADOR_LINEAS_FAC`, `ESCREARARTICULOS_FAC`, `ESDESC' +
        'RIPCIONES_AMP_FAC`, `ESFECHADEENTREGA_FAC`, `XML_FAC`, `INSTANTE' +
        '_MODIF`, `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`, `CODI' +
        'GO_CAJERO_FAC`, `CODIGO_ALM_FAC`, `CODIGO_CAJA_FAC`, `NUMERO_OPE' +
        'RACION_FAC`, `TIPO_OPER_VFACTU_FAC`)'
      'VALUES'
      
        '  (' +
      ':PORCENTAJE_DTO_COMERCIAL_FAC, :TOTAL_DTO_COMERCIAL_FAC, ' +
      ':PORCENTAJE_DTO_FINANCIERO_FAC, :TOTAL_DTO_FINANCIERO_FAC, ' +
      ':`NUMERO_FAC`, :`SERIE_FAC`, :`FECHA_FAC`, :`ESCONSOLIDADA_FA' +
        'C`, :`INSTANTECONSO_FAC`, :`TIPO_FAC`, :`FASE_FAC`, :`CODIGO_EMP' +
        '_FAC`, :`RAZON_SOCIAL_EMPRESA_FAC`, :`NIF_EMPRESA_FAC`, :`MOVIL_' +
        'EMPRESA_FAC`, :`EMAIL_EMPRESA_FAC`, :`DIRECCION1_EMPRESA_FAC`, :' +
        '`DIRECCION2_EMPRESA_FAC`, :`POBLACION_EMPRESA_FAC`, :`PROVINCIA_' +
        'EMPRESA_FAC`, :`CODIGO_PAI_EMPRESA_FAC`, :`NOMBRE_PAI_EMPRESA_FA' +
        'C`, :`CODIGO_POSTAL_EMPRESA_FAC`, :`ESRETENCIONES_EMPRESA_FAC`, ' +
        ':`GRUPO_ZONA_IVA_EMPRESA_FAC`, :`ESREGIMENESPECIALAGRICOLA_EMPRE' +
        'SA_FAC`, :`CODIGO_CLI_FAC`, :`RAZON_SOCIAL_CLIENTE_FAC`, :`NIF_C' +
        'LIENTE_FAC`, :`MOVIL_CLIENTE_FAC`, :`EMAIL_CLIENTE_FAC`, :`DIREC' +
        'CION1_CLIENTE_FAC`, :`DIRECCION2_CLIENTE_FAC`, :`POBLACION_CLIEN' +
        'TE_FAC`, :`PROVINCIA_CLIENTE_FAC`, :`CODIGO_POSTAL_CLIENTE_FAC`,' +
        ' :`CODIGO_PAI_CLIENTE_FAC`, :`NOMBRE_PAI_CLIENTE_FAC`, :`CODIGO_' +
        'IVA_FAC`, :`ESIVA_RECARGO_CLIENTE_FAC`, :`ESIVA_EXENTO_CLIENTE_F' +
        'AC`, :`ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC`, :`ESRETENCIONES_C' +
        'LIENTE_FAC`, :`TARIFA_ARTICULO_CLIENTE_FAC`, :`ESIMP_INCL_TARIFA' +
        '_CLIENTE_FAC`, :`ESINTRACOMUNITARIO_CLIENTE_FAC`, :`ESIRPF_IMP_I' +
        'NCL_ZONA_IVA_FAC`, :`ESAPLICA_RE_ZONA_IVA_FAC`, :`ESIVAAGRICOLA_' +
        'ZONA_IVA_FAC`, :`PALABRA_REPORTS_ZONA_IVA_FAC`, :`ESVENTA_ACTIVO' +
        '_FIJO_FAC`, :`PORCENTAJE_IVAN_FAC`, :`TOTAL_IVAN_FAC`, :`PORCENT' +
        'AJE_REN_FAC`, :`TOTAL_REN_FAC`, :`TOTAL_BASEI_IVAN_FAC`, :`PORCE' +
        'NTAJE_IVAR_FAC`, :`TOTAL_IVAR_FAC`, :`PORCENTAJE_RER_FAC`, :`TOT' +
        'AL_RER_FAC`, :`TOTAL_BASEI_IVAR_FAC`, :`PORCENTAJE_IVAS_FAC`, :`' +
        'TOTAL_IVAS_FAC`, :`PORCENTAJE_RES_FAC`, :`TOTAL_RES_FAC`, :`TOTA' +
        'L_BASEI_IVAS_FAC`, :`PORCENTAJE_IVAE_FAC`, :`TOTAL_IVAE_FAC`, :`' +
        'PORCENTAJE_REE_FAC`, :`TOTAL_REE_FAC`, :`TOTAL_BASEI_IVAE_FAC`, ' +
        ':`TOTAL_BASES_FAC`, :`TOTAL_IMPUESTOS_FAC`, :`FORMA_PAGO_FAC`, :' +
        '`PORCENTAJE_RETENCION_FAC`, :`TOTAL_RETENCION_FAC`, :`TOTAL_LIQU' +
        'IDO_FAC`, :`NUMERO_FAC_ABONO_FAC`, :`SERIE_FAC_ABONO_FAC`, :`TEX' +
        'TO_LEGAL_CLIENTE_FAC`, :`TEXTO_LEGAL_EMPRESA_FAC`, :`DOCUMENTO_F' +
        'AC`, :`COMENTARIOS_FAC`, :`CONTADOR_LINEAS_FAC`, :`ESCREARARTICU' +
        'LOS_FAC`, :`ESDESCRIPCIONES_AMP_FAC`, :`ESFECHADEENTREGA_FAC`, :' +
        '`XML_FAC`, :`INSTANTE_MODIF`, :`INSTANTE_ALTA`, :`USUARIO_ALTA`,' +
        ' :`USUARIO_MODIF`, :`CODIGO_CAJERO_FAC`, :`CODIGO_ALM_FAC`, :`CO' +
        'DIGO_CAJA_FAC`, :`NUMERO_OPERACION_FAC`, :`TIPO_OPER_VFACTU_FAC`)')
    SQLDelete.Strings = (
      'DELETE FROM `fza_facturas`'
      'WHERE'
      
        '  `NUMERO_FAC` = :`Old_NUMERO_FAC` AND `SERIE_FAC` = :`Old_SERIE' +
        '_FAC`')
    SQLUpdate.Strings = (
      'UPDATE `fza_facturas`'
      'SET' +
      ' PORCENTAJE_DTO_COMERCIAL_FAC = ' +
      ':PORCENTAJE_DTO_COMERCIAL_FAC, TOTAL_DTO_COMERCIAL_FAC = ' +
      ':TOTAL_DTO_COMERCIAL_FAC, PORCENTAJE_DTO_FINANCIERO_FAC = ' +
      ':PORCENTAJE_DTO_FINANCIERO_FAC, TOTAL_DTO_FINANCIERO_FAC = ' +
      ':TOTAL_DTO_FINANCIERO_FAC, ' +
      ''
      
        '  `NUMERO_FAC` = :`NUMERO_FAC`, `SERIE_FAC` = :`SERIE_FAC`, `FEC' +
        'HA_FAC` = :`FECHA_FAC`, `ESCONSOLIDADA_FAC` = :`ESCONSOLIDADA_FA' +
        'C`, `INSTANTECONSO_FAC` = :`INSTANTECONSO_FAC`, `TIPO_FAC` = :`T' +
        'IPO_FAC`, `FASE_FAC` = :`FASE_FAC`, `CODIGO_EMP_FAC` = :`CODIGO_' +
        'EMP_FAC`, `RAZON_SOCIAL_EMPRESA_FAC` = :`RAZON_SOCIAL_EMPRESA_FA' +
        'C`, `NIF_EMPRESA_FAC` = :`NIF_EMPRESA_FAC`, `MOVIL_EMPRESA_FAC` ' +
        '= :`MOVIL_EMPRESA_FAC`, `EMAIL_EMPRESA_FAC` = :`EMAIL_EMPRESA_FA' +
        'C`, `DIRECCION1_EMPRESA_FAC` = :`DIRECCION1_EMPRESA_FAC`, `DIREC' +
        'CION2_EMPRESA_FAC` = :`DIRECCION2_EMPRESA_FAC`, `POBLACION_EMPRE' +
        'SA_FAC` = :`POBLACION_EMPRESA_FAC`, `PROVINCIA_EMPRESA_FAC` = :`' +
        'PROVINCIA_EMPRESA_FAC`, `CODIGO_PAI_EMPRESA_FAC` = :`CODIGO_PAI_' +
        'EMPRESA_FAC`, `NOMBRE_PAI_EMPRESA_FAC` = :`NOMBRE_PAI_EMPRESA_FA' +
        'C`, `CODIGO_POSTAL_EMPRESA_FAC` = :`CODIGO_POSTAL_EMPRESA_FAC`, ' +
        '`ESRETENCIONES_EMPRESA_FAC` = :`ESRETENCIONES_EMPRESA_FAC`, `GRU' +
        'PO_ZONA_IVA_EMPRESA_FAC` = :`GRUPO_ZONA_IVA_EMPRESA_FAC`, `ESREG' +
        'IMENESPECIALAGRICOLA_EMPRESA_FAC` = :`ESREGIMENESPECIALAGRICOLA_' +
        'EMPRESA_FAC`, `CODIGO_CLI_FAC` = :`CODIGO_CLI_FAC`, `RAZON_SOCIA' +
        'L_CLIENTE_FAC` = :`RAZON_SOCIAL_CLIENTE_FAC`, `NIF_CLIENTE_FAC` ' +
        '= :`NIF_CLIENTE_FAC`, `MOVIL_CLIENTE_FAC` = :`MOVIL_CLIENTE_FAC`' +
        ', `EMAIL_CLIENTE_FAC` = :`EMAIL_CLIENTE_FAC`, `DIRECCION1_CLIENT' +
        'E_FAC` = :`DIRECCION1_CLIENTE_FAC`, `DIRECCION2_CLIENTE_FAC` = :' +
        '`DIRECCION2_CLIENTE_FAC`, `POBLACION_CLIENTE_FAC` = :`POBLACION_' +
        'CLIENTE_FAC`, `PROVINCIA_CLIENTE_FAC` = :`PROVINCIA_CLIENTE_FAC`' +
        ', `CODIGO_POSTAL_CLIENTE_FAC` = :`CODIGO_POSTAL_CLIENTE_FAC`, `C' +
        'ODIGO_PAI_CLIENTE_FAC` = :`CODIGO_PAI_CLIENTE_FAC`, `NOMBRE_PAI_' +
        'CLIENTE_FAC` = :`NOMBRE_PAI_CLIENTE_FAC`, `CODIGO_IVA_FAC` = :`C' +
        'ODIGO_IVA_FAC`, `ESIVA_RECARGO_CLIENTE_FAC` = :`ESIVA_RECARGO_CL' +
        'IENTE_FAC`, `ESIVA_EXENTO_CLIENTE_FAC` = :`ESIVA_EXENTO_CLIENTE_' +
        'FAC`, `ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC` = :`ESREGIMENESPEC' +
        'IALAGRICOLA_CLIENTE_FAC`, `ESRETENCIONES_CLIENTE_FAC` = :`ESRETE' +
        'NCIONES_CLIENTE_FAC`, `TARIFA_ARTICULO_CLIENTE_FAC` = :`TARIFA_A' +
        'RTICULO_CLIENTE_FAC`, `ESIMP_INCL_TARIFA_CLIENTE_FAC` = :`ESIMP_' +
        'INCL_TARIFA_CLIENTE_FAC`, `ESINTRACOMUNITARIO_CLIENTE_FAC` = :`E' +
        'SINTRACOMUNITARIO_CLIENTE_FAC`, `ESIRPF_IMP_INCL_ZONA_IVA_FAC` =' +
        ' :`ESIRPF_IMP_INCL_ZONA_IVA_FAC`, `ESAPLICA_RE_ZONA_IVA_FAC` = :' +
        '`ESAPLICA_RE_ZONA_IVA_FAC`, `ESIVAAGRICOLA_ZONA_IVA_FAC` = :`ESI' +
        'VAAGRICOLA_ZONA_IVA_FAC`, `PALABRA_REPORTS_ZONA_IVA_FAC` = :`PAL' +
        'ABRA_REPORTS_ZONA_IVA_FAC`, `ESVENTA_ACTIVO_FIJO_FAC` = :`ESVENT' +
        'A_ACTIVO_FIJO_FAC`, `PORCENTAJE_IVAN_FAC` = :`PORCENTAJE_IVAN_FA' +
        'C`, `TOTAL_IVAN_FAC` = :`TOTAL_IVAN_FAC`, `PORCENTAJE_REN_FAC` =' +
        ' :`PORCENTAJE_REN_FAC`, `TOTAL_REN_FAC` = :`TOTAL_REN_FAC`, `TOT' +
        'AL_BASEI_IVAN_FAC` = :`TOTAL_BASEI_IVAN_FAC`, `PORCENTAJE_IVAR_F' +
        'AC` = :`PORCENTAJE_IVAR_FAC`, `TOTAL_IVAR_FAC` = :`TOTAL_IVAR_FA' +
        'C`, `PORCENTAJE_RER_FAC` = :`PORCENTAJE_RER_FAC`, `TOTAL_RER_FAC' +
        '` = :`TOTAL_RER_FAC`, `TOTAL_BASEI_IVAR_FAC` = :`TOTAL_BASEI_IVA' +
        'R_FAC`, `PORCENTAJE_IVAS_FAC` = :`PORCENTAJE_IVAS_FAC`, `TOTAL_I' +
        'VAS_FAC` = :`TOTAL_IVAS_FAC`, `PORCENTAJE_RES_FAC` = :`PORCENTAJ' +
        'E_RES_FAC`, `TOTAL_RES_FAC` = :`TOTAL_RES_FAC`, `TOTAL_BASEI_IVA' +
        'S_FAC` = :`TOTAL_BASEI_IVAS_FAC`, `PORCENTAJE_IVAE_FAC` = :`PORC' +
        'ENTAJE_IVAE_FAC`, `TOTAL_IVAE_FAC` = :`TOTAL_IVAE_FAC`, `PORCENT' +
        'AJE_REE_FAC` = :`PORCENTAJE_REE_FAC`, `TOTAL_REE_FAC` = :`TOTAL_' +
        'REE_FAC`, `TOTAL_BASEI_IVAE_FAC` = :`TOTAL_BASEI_IVAE_FAC`, `TOT' +
        'AL_BASES_FAC` = :`TOTAL_BASES_FAC`, `TOTAL_IMPUESTOS_FAC` = :`TO' +
        'TAL_IMPUESTOS_FAC`, `FORMA_PAGO_FAC` = :`FORMA_PAGO_FAC`, `PORCE' +
        'NTAJE_RETENCION_FAC` = :`PORCENTAJE_RETENCION_FAC`, `TOTAL_RETEN' +
        'CION_FAC` = :`TOTAL_RETENCION_FAC`, `TOTAL_LIQUIDO_FAC` = :`TOTA' +
        'L_LIQUIDO_FAC`, `NUMERO_FAC_ABONO_FAC` = :`NUMERO_FAC_ABONO_FAC`' +
        ', `SERIE_FAC_ABONO_FAC` = :`SERIE_FAC_ABONO_FAC`, `TEXTO_LEGAL_C' +
        'LIENTE_FAC` = :`TEXTO_LEGAL_CLIENTE_FAC`, `TEXTO_LEGAL_EMPRESA_F' +
        'AC` = :`TEXTO_LEGAL_EMPRESA_FAC`, `DOCUMENTO_FAC` = :`DOCUMENTO_' +
        'FAC`, `COMENTARIOS_FAC` = :`COMENTARIOS_FAC`, `CONTADOR_LINEAS_F' +
        'AC` = :`CONTADOR_LINEAS_FAC`, `ESCREARARTICULOS_FAC` = :`ESCREAR' +
        'ARTICULOS_FAC`, `ESDESCRIPCIONES_AMP_FAC` = :`ESDESCRIPCIONES_AM' +
        'P_FAC`, `ESFECHADEENTREGA_FAC` = :`ESFECHADEENTREGA_FAC`, `XML_F' +
        'AC` = :`XML_FAC`, `INSTANTE_MODIF` = :`INSTANTE_MODIF`, `INSTANT' +
        'E_ALTA` = :`INSTANTE_ALTA`, `USUARIO_ALTA` = :`USUARIO_ALTA`, `U' +
        'SUARIO_MODIF` = :`USUARIO_MODIF`, `CODIGO_CAJERO_FAC` = :`CODIGO' +
        '_CAJERO_FAC`, `CODIGO_ALM_FAC` = :`CODIGO_ALM_FAC`, `CODIGO_CAJA' +
        '_FAC` = :`CODIGO_CAJA_FAC`, `NUMERO_OPERACION_FAC` = :`NUMERO_OP' +
        'ERACION_FAC`, `TIPO_OPER_VFACTU_FAC` = :`TIPO_OPER_VFACTU_FAC`'
      'WHERE'
      
        '  `NUMERO_FAC` = :`Old_NUMERO_FAC` AND `SERIE_FAC` = :`Old_SERIE' +
        '_FAC`')
    SQLLock.Strings = (
      
        'SELECT' +
      ' PORCENTAJE_DTO_COMERCIAL_FAC, TOTAL_DTO_COMERCIAL_FAC, ' +
      'PORCENTAJE_DTO_FINANCIERO_FAC, TOTAL_DTO_FINANCIERO_FAC, ' +
      ' `NUMERO_FAC`, `SERIE_FAC`, `FECHA_FAC`, `ESCONSOLIDADA_FA' +
        'C`, `INSTANTECONSO_FAC`, `TIPO_FAC`, `FASE_FAC`, `CODIGO_EMP_FAC' +
        '`, `RAZON_SOCIAL_EMPRESA_FAC`, `NIF_EMPRESA_FAC`, `MOVIL_EMPRESA' +
        '_FAC`, `EMAIL_EMPRESA_FAC`, `DIRECCION1_EMPRESA_FAC`, `DIRECCION' +
        '2_EMPRESA_FAC`, `POBLACION_EMPRESA_FAC`, `PROVINCIA_EMPRESA_FAC`' +
        ', `CODIGO_PAI_EMPRESA_FAC`, `NOMBRE_PAI_EMPRESA_FAC`, `CODIGO_PO' +
        'STAL_EMPRESA_FAC`, `ESRETENCIONES_EMPRESA_FAC`, `GRUPO_ZONA_IVA_' +
        'EMPRESA_FAC`, `ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC`, `CODIGO_C' +
        'LI_FAC`, `RAZON_SOCIAL_CLIENTE_FAC`, `NIF_CLIENTE_FAC`, `MOVIL_C' +
        'LIENTE_FAC`, `EMAIL_CLIENTE_FAC`, `DIRECCION1_CLIENTE_FAC`, `DIR' +
        'ECCION2_CLIENTE_FAC`, `POBLACION_CLIENTE_FAC`, `PROVINCIA_CLIENT' +
        'E_FAC`, `CODIGO_POSTAL_CLIENTE_FAC`, `CODIGO_PAI_CLIENTE_FAC`, `' +
        'NOMBRE_PAI_CLIENTE_FAC`, `CODIGO_IVA_FAC`, `ESIVA_RECARGO_CLIENT' +
        'E_FAC`, `ESIVA_EXENTO_CLIENTE_FAC`, `ESREGIMENESPECIALAGRICOLA_C' +
        'LIENTE_FAC`, `ESRETENCIONES_CLIENTE_FAC`, `TARIFA_ARTICULO_CLIEN' +
        'TE_FAC`, `ESIMP_INCL_TARIFA_CLIENTE_FAC`, `ESINTRACOMUNITARIO_CL' +
        'IENTE_FAC`, `ESIRPF_IMP_INCL_ZONA_IVA_FAC`, `ESAPLICA_RE_ZONA_IV' +
        'A_FAC`, `ESIVAAGRICOLA_ZONA_IVA_FAC`, `PALABRA_REPORTS_ZONA_IVA_' +
        'FAC`, `ESVENTA_ACTIVO_FIJO_FAC`, `PORCENTAJE_IVAN_FAC`, `TOTAL_I' +
        'VAN_FAC`, `PORCENTAJE_REN_FAC`, `TOTAL_REN_FAC`, `TOTAL_BASEI_IV' +
        'AN_FAC`, `PORCENTAJE_IVAR_FAC`, `TOTAL_IVAR_FAC`, `PORCENTAJE_RE' +
        'R_FAC`, `TOTAL_RER_FAC`, `TOTAL_BASEI_IVAR_FAC`, `PORCENTAJE_IVA' +
        'S_FAC`, `TOTAL_IVAS_FAC`, `PORCENTAJE_RES_FAC`, `TOTAL_RES_FAC`,' +
        ' `TOTAL_BASEI_IVAS_FAC`, `PORCENTAJE_IVAE_FAC`, `TOTAL_IVAE_FAC`' +
        ', `PORCENTAJE_REE_FAC`, `TOTAL_REE_FAC`, `TOTAL_BASEI_IVAE_FAC`,' +
        ' `TOTAL_BASES_FAC`, `TOTAL_IMPUESTOS_FAC`, `FORMA_PAGO_FAC`, `PO' +
        'RCENTAJE_RETENCION_FAC`, `TOTAL_RETENCION_FAC`, `TOTAL_LIQUIDO_F' +
        'AC`, `NUMERO_FAC_ABONO_FAC`, `SERIE_FAC_ABONO_FAC`, `TEXTO_LEGAL' +
        '_CLIENTE_FAC`, `TEXTO_LEGAL_EMPRESA_FAC`, `DOCUMENTO_FAC`, `COME' +
        'NTARIOS_FAC`, `CONTADOR_LINEAS_FAC`, `ESCREARARTICULOS_FAC`, `ES' +
        'DESCRIPCIONES_AMP_FAC`, `ESFECHADEENTREGA_FAC`, `XML_FAC`, `INST' +
        'ANTE_MODIF`, `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`, `' +
        'CODIGO_CAJERO_FAC`, `CODIGO_ALM_FAC`, `CODIGO_CAJA_FAC`, `NUMERO' +
        '_OPERACION_FAC` FROM `fza_facturas`'
      'WHERE'
      
        '  `NUMERO_FAC` = :`Old_NUMERO_FAC` AND `SERIE_FAC` = :`Old_SERIE' +
        '_FAC`'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT' +
      ' PORCENTAJE_DTO_COMERCIAL_FAC, TOTAL_DTO_COMERCIAL_FAC, ' +
      'PORCENTAJE_DTO_FINANCIERO_FAC, TOTAL_DTO_FINANCIERO_FAC, ' +
      ' `NUMERO_FAC`, `SERIE_FAC`, `FECHA_FAC`, `ESCONSOLIDADA_FA' +
        'C`, `INSTANTECONSO_FAC`, `TIPO_FAC`, `FASE_FAC`, `CODIGO_EMP_FAC' +
        '`, `RAZON_SOCIAL_EMPRESA_FAC`, `NIF_EMPRESA_FAC`, `MOVIL_EMPRESA' +
        '_FAC`, `EMAIL_EMPRESA_FAC`, `DIRECCION1_EMPRESA_FAC`, `DIRECCION' +
        '2_EMPRESA_FAC`, `POBLACION_EMPRESA_FAC`, `PROVINCIA_EMPRESA_FAC`' +
        ', `CODIGO_PAI_EMPRESA_FAC`, `NOMBRE_PAI_EMPRESA_FAC`, `CODIGO_PO' +
        'STAL_EMPRESA_FAC`, `ESRETENCIONES_EMPRESA_FAC`, `GRUPO_ZONA_IVA_' +
        'EMPRESA_FAC`, `ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC`, `CODIGO_C' +
        'LI_FAC`, `RAZON_SOCIAL_CLIENTE_FAC`, `NIF_CLIENTE_FAC`, `MOVIL_C' +
        'LIENTE_FAC`, `EMAIL_CLIENTE_FAC`, `DIRECCION1_CLIENTE_FAC`, `DIR' +
        'ECCION2_CLIENTE_FAC`, `POBLACION_CLIENTE_FAC`, `PROVINCIA_CLIENT' +
        'E_FAC`, `CODIGO_POSTAL_CLIENTE_FAC`, `CODIGO_PAI_CLIENTE_FAC`, `' +
        'NOMBRE_PAI_CLIENTE_FAC`, `CODIGO_IVA_FAC`, `ESIVA_RECARGO_CLIENT' +
        'E_FAC`, `ESIVA_EXENTO_CLIENTE_FAC`, `ESREGIMENESPECIALAGRICOLA_C' +
        'LIENTE_FAC`, `ESRETENCIONES_CLIENTE_FAC`, `TARIFA_ARTICULO_CLIEN' +
        'TE_FAC`, `ESIMP_INCL_TARIFA_CLIENTE_FAC`, `ESINTRACOMUNITARIO_CL' +
        'IENTE_FAC`, `ESIRPF_IMP_INCL_ZONA_IVA_FAC`, `ESAPLICA_RE_ZONA_IV' +
        'A_FAC`, `ESIVAAGRICOLA_ZONA_IVA_FAC`, `PALABRA_REPORTS_ZONA_IVA_' +
        'FAC`, `ESVENTA_ACTIVO_FIJO_FAC`, `PORCENTAJE_IVAN_FAC`, `TOTAL_I' +
        'VAN_FAC`, `PORCENTAJE_REN_FAC`, `TOTAL_REN_FAC`, `TOTAL_BASEI_IV' +
        'AN_FAC`, `PORCENTAJE_IVAR_FAC`, `TOTAL_IVAR_FAC`, `PORCENTAJE_RE' +
        'R_FAC`, `TOTAL_RER_FAC`, `TOTAL_BASEI_IVAR_FAC`, `PORCENTAJE_IVA' +
        'S_FAC`, `TOTAL_IVAS_FAC`, `PORCENTAJE_RES_FAC`, `TOTAL_RES_FAC`,' +
        ' `TOTAL_BASEI_IVAS_FAC`, `PORCENTAJE_IVAE_FAC`, `TOTAL_IVAE_FAC`' +
        ', `PORCENTAJE_REE_FAC`, `TOTAL_REE_FAC`, `TOTAL_BASEI_IVAE_FAC`,' +
        ' `TOTAL_BASES_FAC`, `TOTAL_IMPUESTOS_FAC`, `FORMA_PAGO_FAC`, `PO' +
        'RCENTAJE_RETENCION_FAC`, `TOTAL_RETENCION_FAC`, `TOTAL_LIQUIDO_F' +
        'AC`, `NUMERO_FAC_ABONO_FAC`, `SERIE_FAC_ABONO_FAC`, `TEXTO_LEGAL' +
        '_CLIENTE_FAC`, `TEXTO_LEGAL_EMPRESA_FAC`, `DOCUMENTO_FAC`, `COME' +
        'NTARIOS_FAC`, `CONTADOR_LINEAS_FAC`, `ESCREARARTICULOS_FAC`, `ES' +
        'DESCRIPCIONES_AMP_FAC`, `ESFECHADEENTREGA_FAC`, `XML_FAC`, `INST' +
        'ANTE_MODIF`, `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`, `' +
        'CODIGO_CAJERO_FAC`, `CODIGO_ALM_FAC`, `CODIGO_CAJA_FAC`, `NUMERO' +
        '_OPERACION_FAC` FROM `fza_facturas`'
      'WHERE'
      '  `NUMERO_FAC` = :`NUMERO_FAC` AND `SERIE_FAC` = :`SERIE_FAC`')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_facturas')
    Connection = dmConn.conUni
    SQL.Strings = (
      'select * from vi_facturas'
      ' ORDER BY FECHA_FAC DESC, NUMERO_FAC DESC')
    BeforeInsert = nil
    AfterInsert = unqryTablaGAfterInsert
    BeforePost = unqryFacBeforePost
    AfterPost = unqryFacAfterPost
    BeforeDelete = unqryTablaGBeforeDelete
    Left = 45
    Top = 109
  end
  inherited unqryPerfiles: TUniQuery
    SQL.Strings = (
      'select *'
      'from fza_usuarios_perfiles')
    Left = 275
    Top = 141
  end
  inherited dsPerfiles: TDataSource
    Left = 274
    Top = 61
  end
  object dsLinFac: TDataSource
    DataSet = unqryLinFac
    OnStateChange = dsLinFacStateChange
    Left = 134
    Top = 38
  end
  object dsFacPrint: TDataSource
    DataSet = unqryFacPrint
    Left = 454
    Top = 429
  end
  object dsLinFacPrint: TDataSource
    DataSet = unqryLinFacPrint
    Left = 574
    Top = 429
  end
  object dsSeries: TDataSource
    DataSet = unqrySeries
    Left = 435
    Top = 38
  end
  object fxdsPrintFac: TfrxDBDataset
    Description = 'Facturas'
    UserName = 'Facturas'
    CloseDataSource = False
    DataSource = dsFacPrint
    BCDToCurrency = False
    DataSetOptions = []
    Left = 454
    Top = 346
  end
  object fxdstPrintLinFac: TfrxDBDataset
    Description = 'Lineas Facturas'
    UserName = 'Lineas Facturas'
    CloseDataSource = False
    DataSource = dsLinFacPrint
    BCDToCurrency = False
    DataSetOptions = []
    Left = 574
    Top = 346
    FieldDefs = <
      item
        FieldName = 'NUMERO_FAC_FACLIN'
        FieldAlias = 'NUMERO_FAC_FACLIN'
        FieldType = fftString
        Size = 20
      end
      item
        FieldName = 'SERIE_FAC_FACLIN'
        FieldAlias = 'SERIE_FAC_FACLIN'
        FieldType = fftString
        Size = 20
      end
      item
        FieldName = 'LINEA_FACLIN'
        FieldAlias = 'LINEA_FACLIN'
        FieldType = fftString
      end
      item
        FieldName = 'CODIGO_ART_FACLIN'
        FieldAlias = 'CODIGO_ART_FACLIN'
        FieldType = fftString
        Size = 20
      end
      item
        FieldName = 'CODIGO_UNIDAD_FACLIN'
        FieldAlias = 'CODIGO_UNIDAD_FACLIN'
        FieldType = fftString
        Size = 50
      end
      item
        FieldName = 'CODIGO_FAM_FACLIN'
        FieldAlias = 'CODIGO_FAM_FACLIN'
        FieldType = fftString
        Size = 20
      end
      item
        FieldName = 'NOMBRE_FAM_FACLIN'
        FieldAlias = 'NOMBRE_FAM_FACLIN'
        FieldType = fftString
        Size = 200
      end
      item
        FieldName = 'FECHA_ENTREGA_FACLIN'
        FieldAlias = 'FECHA_ENTREGA_FACLIN'
        FieldType = fftDateTime
      end
      item
        FieldName = 'TIPO_CANTIDAD_ARTICULO_FACLIN'
        FieldAlias = 'TIPO_CANTIDAD_ARTICULO_FACLIN'
        FieldType = fftString
        Size = 20
      end
      item
        FieldName = 'ESIMP_INCL_TARIFA_FACLIN'
        FieldAlias = 'ESIMP_INCL_TARIFA_FACLIN'
        FieldType = fftString
      end
      item
        FieldName = 'TIPO_IVA_ARTICULO_FACLIN'
        FieldAlias = 'TIPO_IVA_ARTICULO_FACLIN'
        FieldType = fftString
      end
      item
        FieldName = 'DESCRIPCION_ARTICULO_FACLIN'
        FieldAlias = 'DESCRIPCION_ARTICULO_FACLIN'
        FieldType = fftString
        Size = 100
      end
      item
        FieldName = 'DESCRIPCION_PRINT_FACLIN'
        FieldAlias = 'DESCRIPCION_PRINT_FACLIN'
        FieldType = fftString
        Size = 160
      end
      item
        FieldName = 'ID_OPERACION_CAJA_FACTURA'
        FieldAlias = 'ID_OPERACION_CAJA_FACTURA'
      end
      item
        FieldName = 'DOCUMENTO_OPERACION_CAJA'
        FieldAlias = 'DOCUMENTO_OPERACION_CAJA'
        FieldType = fftString
        Size = 80
      end
      item
        FieldName = 'FECHA_OPERACION_CAJA'
        FieldAlias = 'FECHA_OPERACION_CAJA'
        FieldType = fftDateTime
      end
      item
        FieldName = 'ESFACTURA_TA_CAJA'
        FieldAlias = 'ESFACTURA_TA_CAJA'
        FieldType = fftString
      end
      item
        FieldName = 'CODIGO_TAR_FACLIN'
        FieldAlias = 'CODIGO_TAR_FACLIN'
        FieldType = fftString
      end
      item
        FieldName = 'CANTIDAD_FACLIN'
        FieldAlias = 'CANTIDAD_FACLIN'
      end
      item
        FieldName = 'PRECIO_SALIDA_FACLIN'
        FieldAlias = 'PRECIO_SALIDA_FACLIN'
      end
      item
        FieldName = 'PORCENTAJE_DTO_FACLIN'
        FieldAlias = 'PORCENTAJE_DTO_FACLIN'
      end
      item
        FieldName = 'PRECIO_DTO_FACLIN'
        FieldAlias = 'PRECIO_DTO_FACLIN'
      end
      item
        FieldName = 'PRECIO_VENTA_SIVA_ARTICULO_FACLIN'
        FieldAlias = 'PRECIO_VENTA_SIVA_ARTICULO_FACLIN'
      end
      item
        FieldName = 'PORCENTAJE_IVA_FACLIN'
        FieldAlias = 'PORCENTAJE_IVA_FACLIN'
      end
      item
        FieldName = 'PRECIO_VENTA_CIVA_ARTICULO_FACLIN'
        FieldAlias = 'PRECIO_VENTA_CIVA_ARTICULO_FACLIN'
      end
      item
        FieldName = 'TOTAL_FACLIN'
        FieldAlias = 'TOTAL_FACLIN'
      end
      item
        FieldName = 'INSTANTE_MODIF'
        FieldAlias = 'INSTANTE_MODIF'
        FieldType = fftDateTime
      end
      item
        FieldName = 'INSTANTE_ALTA'
        FieldAlias = 'INSTANTE_ALTA'
        FieldType = fftDateTime
      end
      item
        FieldName = 'USUARIO_ALTA'
        FieldAlias = 'USUARIO_ALTA'
        FieldType = fftString
        Size = 100
      end
      item
        FieldName = 'USUARIO_MODIF'
        FieldAlias = 'USUARIO_MODIF'
        FieldType = fftString
        Size = 100
      end>
  end
  object unqryFacPrint: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *'
      'from vi_facturas_print'
      'where SERIE_FAC = '#39'ANA/2023'#39' '
      'AND NUMERO_FAC = '#39'000003'#39
      'order by NUMERO_FAC Asc')
    Left = 454
    Top = 506
  end
  object unqryLinFacPrint: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO `fza_facturas_lineas`'
      
        '  (`SERIE_FAC_FACLIN`, `NUMERO_FAC_FACLIN`, `LINEA_LINEA`, `CODI' +
        'GO_ARTICULO_LINEA`, `DESCRIPCION_ARTICULO_LINEA`, `ZONA`, `PRECI' +
        'OVENTA_ARTICULO_LINEA`, `CANTIDAD_LINEA`, `SUM_TOTAL_LINEA`, `OD' +
        'ONTOLOGO`)'
      'VALUES'
      
        '  (:`SERIE_FAC_FACLIN`, :`NUMERO_FAC_FACLIN`, :`LINEA_LINEA`, :`' +
        'CODIGO_ARTICULO_LINEA`, :`DESCRIPCION_ARTICULO_LINEA`, :`ZONA`, ' +
        ':`PRECIOVENTA_ARTICULO_LINEA`, :`CANTIDAD_LINEA`, :`SUM_TOTAL_LI' +
        'NEA`, :`ODONTOLOGO`)')
    SQLDelete.Strings = (
      'DELETE FROM `fza_facturas_lineas`'
      'WHERE'
      
        '  `SERIE_FAC_FACLIN` = :`Old_SERIE_FAC_FACLIN` AND `NUMERO_FAC_F' +
        'ACLIN` = :`Old_NUMERO_FAC_FACLIN` AND `LINEA_LINEA` = :`Old_LINE' +
        'A_LINEA`')
    SQLUpdate.Strings = (
      'UPDATE `fza_facturas_lineas`'
      'SET'
      
        '  `SERIE_FAC_FACLIN` = :`SERIE_FAC_FACLIN`, `NUMERO_FAC_FACLIN` ' +
        '= :`NUMERO_FAC_FACLIN`, `LINEA_LINEA` = :`LINEA_LINEA`, `CODIGO_' +
        'ARTICULO_LINEA` = :`CODIGO_ARTICULO_LINEA`, `DESCRIPCION_ARTICUL' +
        'O_LINEA` = :`DESCRIPCION_ARTICULO_LINEA`, `ZONA` = :`ZONA`, `PRE' +
        'CIOVENTA_ARTICULO_LINEA` = :`PRECIOVENTA_ARTICULO_LINEA`, `CANTI' +
        'DAD_LINEA` = :`CANTIDAD_LINEA`, `SUM_TOTAL_LINEA` = :`SUM_TOTAL_' +
        'LINEA`, `ODONTOLOGO` = :`ODONTOLOGO`'
      'WHERE'
      
        '  `SERIE_FAC_FACLIN` = :`Old_SERIE_FAC_FACLIN` AND `NUMERO_FAC_F' +
        'ACLIN` = :`Old_NUMERO_FAC_FACLIN` AND `LINEA_LINEA` = :`Old_LINE' +
        'A_LINEA`')
    SQLLock.Strings = (
      'SELECT * FROM fza_facturas_lineas'
      'WHERE'
      
        '  `SERIE_FAC_FACLIN` = :`Old_SERIE_FAC_FACLIN` AND `NUMERO_FAC_F' +
        'ACLIN` = :`Old_NUMERO_FAC_FACLIN` AND `LINEA_LINEA` = :`Old_LINE' +
        'A_LINEA`'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT `SERIE_FAC_FACLIN`, `NUMERO_FAC_FACLIN`, `LINEA_LINEA`, `' +
        'CODIGO_ARTICULO_LINEA`, `DESCRIPCION_ARTICULO_LINEA`, `ZONA`, `P' +
        'RECIOVENTA_ARTICULO_LINEA`, `CANTIDAD_LINEA`, `SUM_TOTAL_LINEA`,' +
        ' `ODONTOLOGO` FROM `fza_facturas_lineas`'
      'WHERE'
      
        '  `SERIE_FAC_FACLIN` = :`SERIE_FAC_FACLIN` AND `NUMERO_FAC_FACLI' +
        'N` = :`NUMERO_FAC_FACLIN` AND `LINEA_LINEA` = :`LINEA_LINEA`')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_facturas_lineas')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *'
      ' FROM vi_facturas_lineas_print'
      'WHERE NUMERO_FAC_FACLIN = :NUMERO_FAC'
      '  AND SERIE_FAC_FACLIN = :SERIE_FAC'
      'ORDER BY LINEA_FACLIN;')
    MasterSource = dsFacPrint
    MasterFields = 'SERIE_FAC;NUMERO_FAC'
    DetailFields = 'SERIE_FAC_FACLIN;NUMERO_FAC_FACLIN'
    Left = 574
    Top = 506
    ParamData = <
      item
        DataType = ftWideString
        Name = 'NUMERO_FAC'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'SERIE_FAC'
        ParamType = ptInput
        Value = nil
      end>
  end
  object unqrySeries: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT DISTINCT SERIE_CON, DEFAULT_CON'
      'FROM fza_contadores'
      'WHERE TIPO_DOC_CON='#39'FC'#39' AND ESACTIVO_CON = '#39'S'#39
      'ORDER BY DEFAULT_CON DESC')
    Left = 435
    Top = 115
  end
  object unqryCliDataFac: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_clientes'
      
        '  (CODIGO_CLI_CLI, ESACTIVO_CLI, RAZON_SOCIAL_CLI, NIF_CLI, MOVI' +
        'L_CLI, EMAIL_CLI, DIRECCION1_CLI, DIRECCION2_CLI, POBLACION_CLI,' +
        ' PROVINCIA_CLI, CODIGO_POSTAL_CLI, PAIS_CLIENTE, OBSERVACIONES_C' +
        'LI, REFERENCIA_CLI, CONTACTO_CLI, TELEFONO_CONTACTO_CLI, TELEFON' +
        'O_CLI, IBAN_CLI, IVA_RECARGO_CLIENTE, RETENCIONES_CLIENTE, CODIG' +
        'O_FORMA_PAGO, CODIGO_ZONA_IVA_CLIENTE, TEXTO_LEGAL_FACTURA_CLI, ' +
        'INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF)'
      'VALUES'
      
        '  (:CODIGO_CLI_CLI, :ESACTIVO_CLI, :RAZON_SOCIAL_CLI, :NIF_CLI, ' +
        ':MOVIL_CLI, :EMAIL_CLI, :DIRECCION1_CLI, :DIRECCION2_CLI, :POBLA' +
        'CION_CLI, :PROVINCIA_CLI, :CODIGO_POSTAL_CLI, :PAIS_CLIENTE, :OB' +
        'SERVACIONES_CLI, :REFERENCIA_CLI, :CONTACTO_CLI, :TELEFONO_CONTA' +
        'CTO_CLI, :TELEFONO_CLI, :IBAN_CLI, :IVA_RECARGO_CLIENTE, :RETENC' +
        'IONES_CLIENTE, :CODIGO_FORMA_PAGO, :CODIGO_ZONA_IVA_CLIENTE, :TE' +
        'XTO_LEGAL_FACTURA_CLI, :INSTANTE_MODIF, :INSTANTE_ALTA, :USUARIO' +
        '_ALTA, :USUARIO_MODIF)')
    SQLDelete.Strings = (
      'DELETE FROM fza_clientes'
      'WHERE'
      '  CODIGO_CLI_CLI = :Old_CODIGO_CLI_CLI')
    SQLUpdate.Strings = (
      'UPDATE fza_clientes'
      'SET'
      
        '  CODIGO_CLI_CLI = :CODIGO_CLI_CLI, ESACTIVO_CLI = :ESACTIVO_CLI' +
        ', RAZON_SOCIAL_CLI = :RAZON_SOCIAL_CLI, NIF_CLI = :NIF_CLI, MOVI' +
        'L_CLI = :MOVIL_CLI, EMAIL_CLI = :EMAIL_CLI, DIRECCION1_CLI = :DI' +
        'RECCION1_CLI, DIRECCION2_CLI = :DIRECCION2_CLI, POBLACION_CLI = ' +
        ':POBLACION_CLI, PROVINCIA_CLI = :PROVINCIA_CLI, CODIGO_POSTAL_CL' +
        'I = :CODIGO_POSTAL_CLI, PAIS_CLIENTE = :PAIS_CLIENTE, OBSERVACIO' +
        'NES_CLI = :OBSERVACIONES_CLI, REFERENCIA_CLI = :REFERENCIA_CLI, ' +
        'CONTACTO_CLI = :CONTACTO_CLI, TELEFONO_CONTACTO_CLI = :TELEFONO_' +
        'CONTACTO_CLI, TELEFONO_CLI = :TELEFONO_CLI, IBAN_CLI = :IBAN_CLI' +
        ', IVA_RECARGO_CLIENTE = :IVA_RECARGO_CLIENTE, RETENCIONES_CLIENT' +
        'E = :RETENCIONES_CLIENTE, CODIGO_FORMA_PAGO = :CODIGO_FORMA_PAGO' +
        ', CODIGO_ZONA_IVA_CLIENTE = :CODIGO_ZONA_IVA_CLIENTE, TEXTO_LEGA' +
        'L_FACTURA_CLI = :TEXTO_LEGAL_FACTURA_CLI, INSTANTE_MODIF = :INST' +
        'ANTE_MODIF, INSTANTE_ALTA = :INSTANTE_ALTA, USUARIO_ALTA = :USUA' +
        'RIO_ALTA, USUARIO_MODIF = :USUARIO_MODIF'
      'WHERE'
      '  CODIGO_CLI_CLI = :Old_CODIGO_CLI_CLI')
    SQLLock.Strings = (
      'SELECT * FROM fza_clientes'
      'WHERE'
      '  CODIGO_CLI_CLI = :Old_CODIGO_CLI_CLI'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT CODIGO_CLI_CLI, ESACTIVO_CLI, RAZON_SOCIAL_CLI, NIF_CLI, ' +
        'MOVIL_CLI, EMAIL_CLI, DIRECCION1_CLI, DIRECCION2_CLI, POBLACION_' +
        'CLI, PROVINCIA_CLI, CODIGO_POSTAL_CLI, PAIS_CLIENTE, OBSERVACION' +
        'ES_CLI, REFERENCIA_CLI, CONTACTO_CLI, TELEFONO_CONTACTO_CLI, TEL' +
        'EFONO_CLI, IBAN_CLI, IVA_RECARGO_CLIENTE, RETENCIONES_CLIENTE, C' +
        'ODIGO_FORMA_PAGO, CODIGO_ZONA_IVA_CLIENTE, TEXTO_LEGAL_FACTURA_C' +
        'LI, INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF F' +
        'ROM fza_clientes'
      'WHERE'
      '  CODIGO_CLI_CLI = :CODIGO_CLI_CLI')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_clientes')
    Connection = dmConn.conUni
    SQL.Strings = (
      'select * from vi_cli_busquedas')
    Left = 22
    Top = 429
  end
  object unqryArtDataLinFac: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'select v.*,'
      '       coalesce(pv.PV, ap.VALOR_LIBRE_ARTPROP, '#39#39') as TEMPORADA'
      '  from vi_art_busquedas v'
      '  left join fza_articulos_propiedades ap'
      '    on ap.CODIGO_ART_ART = v.CODIGO_ART_ART'
      '   and ap.CODIGO_PROP_ARTPROP = '#39'TEMPORADA'#39
      '   and ap.CODIGO_UNIDAD_ARTPROP = '#39#39
      '  left join fza_propiedades_valores pv'
      '    on pv.ID_PV_ARTPROP = ap.ID_PV_ARTPROP'
      ' where (v.CODIGO_TAR_ARTTAR = :tarifa'
      '    or v.CODIGO_TAR_ARTTAR is null)'
      '   and v.FECHA_DESDE_ARTTAR < :FECHA_FAC'
      '   and (v.FECHA_HASTA_ARTTAR is null'
      '        or v.FECHA_HASTA_ARTTAR > :FECHA_FAC)')
    Left = 200
    Top = 429
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'tarifa'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'FECHA_FAC'
        Value = nil
      end>
  end
  object unqryLinFac: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO `fza_facturas_lineas`'
      
        '  (`NUMERO_FAC_FACLIN`, `SERIE_FAC_FACLIN`, `LINEA_FACLIN`, `COD' +
        'IGO_ART_FACLIN`, `CODIGO_UNIDAD_FACLIN`, `CODIGO_FAM_FACLIN`, `N' +
        'OMBRE_FAM_FACLIN`, `PREC' +
        'IO_ULT_COMPRA_FACLIN`, `CODIGO_PRV_FACLIN`, `RAZON_SOCIAL_PROVEE' +
        'DOR_FACLIN`, `ESPROVEEDORPRINCIPAL_FACLIN`, `FECHA_ENTREGA_FACLI' +
        'N`, `TIPO_CANTIDAD_ARTICULO_FACLIN`, `ESIMP_INCL_TARIFA_FACLIN`,' +
        ' `TIPO_IVA_ARTICULO_FACLIN`, `DESCRIPCION_ARTICULO_FACLIN`, `DES' +
        'CRIPCION_VARIACION_FACLIN`, `CODIGO_TAR_FACLIN`, `CANTIDAD_FACLI' +
        'N`, `PRECIO_SALIDA_FACLIN`, `POR' +
        'CENTAJE_DTO_FACLIN`, `PRECIO_DTO_FACLIN`, `PRECIO_VENTA_SIVA_ART' +
        'ICULO_FACLIN`, `PORCENTAJE_IVA_FACLIN`, `PRECIO_VENTA_CIVA_ARTIC' +
        'ULO_FACLIN`, `TOTAL_FACLIN`, `TOTAL_FAC_SIVA_FACLIN`, `INSTANTE_' +
        'MODIF`, `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`)'
      'VALUES'
      
        '  (:`NUMERO_FAC_FACLIN`, :`SERIE_FAC_FACLIN`, :`LINEA_FACLIN`, :' +
        '`CODIGO_ART_FACLIN`, :`CODIGO_UNIDAD_FACLIN`, :`CODIGO_FAM_FACL' +
        'IN`, :`NOMBRE_FAM_FACLIN`,' +
        ' :`PRECIO_ULT_COMPRA_FACLIN`, :`CODIGO_PRV_FACLIN`, :`RAZON_SOCI' +
        'AL_PROVEEDOR_FACLIN`, :`ESPROVEEDORPRINCIPAL_FACLIN`, :`FECHA_EN' +
        'TREGA_FACLIN`, :`TIPO_CANTIDAD_ARTICULO_FACLIN`, :`ESIMP_INCL_TA' +
        'RIFA_FACLIN`, :`TIPO_IVA_ARTICULO_FACLIN`, :`DESCRIPCION_ARTICUL' +
        'O_FACLIN`, :`DESCRIPCION_VARIACION_FACLIN`, :`CODIGO_TAR_FACLIN' +
        '`, :`CANTIDAD_FACLIN`, :`PRECIO_SA' +
        'LIDA_FACLIN`, :`PORCENTAJE_DTO_FACLIN`, :`PRECIO_DTO_FACLIN`, :`' +
        'PRECIO_VENTA_SIVA_ARTICULO_FACLIN`, :`PORCENTAJE_IVA_FACLIN`, :`' +
        'PRECIO_VENTA_CIVA_ARTICULO_FACLIN`, :`TOTAL_FACLIN`, :`TOTAL_FAC' +
        '_SIVA_FACLIN`, :`INSTANTE_MODIF`, :`INSTANTE_ALTA`, :`USUARIO_AL' +
        'TA`, :`USUARIO_MODIF`)')
    SQLDelete.Strings = (
      'DELETE FROM `fza_facturas_lineas`'
      'WHERE'
      
        '  `NUMERO_FAC_FACLIN` = :`Old_NUMERO_FAC_FACLIN` AND `SERIE_FAC_' +
        'FACLIN` = :`Old_SERIE_FAC_FACLIN` AND `LINEA_FACLIN` = :`Old_LIN' +
        'EA_FACLIN`')
    SQLUpdate.Strings = (
      'UPDATE `fza_facturas_lineas`'
      'SET'
      
        '  `NUMERO_FAC_FACLIN` = :`NUMERO_FAC_FACLIN`, `SERIE_FAC_FACLIN`' +
        ' = :`SERIE_FAC_FACLIN`, `LINEA_FACLIN` = :`LINEA_FACLIN`, `CODIG' +
        'O_ART_FACLIN` = :`CODIGO_ART_FACLIN`, `CODIGO_UNIDAD_FACLIN` = :' +
        '`CODIGO_UNIDAD_FACLIN`, `CODIGO_FAM_FACLIN` = :`CODIGO_FAM_FACLI' +
        'N`, `NOMBRE_FAM_FACLIN` = :`NOMBRE_FAM_FACLIN`, `P' +
        'RECIO_ULT_COMPRA_FACLIN` = :`PRECIO_ULT_COMPRA_FACLIN`, `CODIGO_' +
        'PRV_FACLIN` = :`CODIGO_PRV_FACLIN`, `RAZON_SOCIAL_PROVEEDOR_FACL' +
        'IN` = :`RAZON_SOCIAL_PROVEEDOR_FACLIN`, `ESPROVEEDORPRINCIPAL_FA' +
        'CLIN` = :`ESPROVEEDORPRINCIPAL_FACLIN`, `FECHA_ENTREGA_FACLIN` =' +
        ' :`FECHA_ENTREGA_FACLIN`, `TIPO_CANTIDAD_ARTICULO_FACLIN` = :`TI' +
        'PO_CANTIDAD_ARTICULO_FACLIN`, `ESIMP_INCL_TARIFA_FACLIN` = :`ESI' +
        'MP_INCL_TARIFA_FACLIN`, `TIPO_IVA_ARTICULO_FACLIN` = :`TIPO_IVA_' +
        'ARTICULO_FACLIN`, `DESCRIPCION_ARTICULO_FACLIN` = :`DESCRIPCION_' +
        'ARTICULO_FACLIN`, `DESCRIPCION_VARIACION_FACLIN` = :`DESCRIPCIO' +
        'N_VARIACION_FACLIN`, `CODIGO_TAR_FACLIN` = :`CODIGO_TAR_FACLIN`,' +
        ' `C' +
        'ANTIDAD_FACLIN` = :`CANTIDAD_FACLIN`, `PRECIO_SALIDA_FACLIN` = :' +
        '`PRECIO_SALIDA_FACLIN`, `PORCENTAJE_DTO_FACLIN` = :`PORCENTAJE_D' +
        'TO_FACLIN`, `PRECIO_DTO_FACLIN` = :`PRECIO_DTO_FACLIN`, `PRECIO_' +
        'VENTA_SIVA_ARTICULO_FACLIN` = :`PRECIO_VENTA_SIVA_ARTICULO_FACLI' +
        'N`, `PORCENTAJE_IVA_FACLIN` = :`PORCENTAJE_IVA_FACLIN`, `PRECIO_' +
        'VENTA_CIVA_ARTICULO_FACLIN` = :`PRECIO_VENTA_CIVA_ARTICULO_FACLI' +
        'N`, `TOTAL_FACLIN` = :`TOTAL_FACLIN`, `TOTAL_FAC_SIVA_FACLIN` = ' +
        ':`TOTAL_FAC_SIVA_FACLIN`, `INSTANTE_MODIF` = :`INSTANTE_MODIF`, ' +
        '`INSTANTE_ALTA` = :`INSTANTE_ALTA`, `USUARIO_ALTA` = :`USUARIO_A' +
        'LTA`, `USUARIO_MODIF` = :`USUARIO_MODIF`'
      'WHERE'
      
        '  `NUMERO_FAC_FACLIN` = :`Old_NUMERO_FAC_FACLIN` AND `SERIE_FAC_' +
        'FACLIN` = :`Old_SERIE_FAC_FACLIN` AND `LINEA_FACLIN` = :`Old_LIN' +
        'EA_FACLIN`')
    SQLLock.Strings = (
      
        'SELECT `NUMERO_FAC_FACLIN`, `SERIE_FAC_FACLIN`, `LINEA_FACLIN`, ' +
        '`CODIGO_ART_FACLIN`, `CODIGO_UNIDAD_FACLIN`, `CODIGO_FAM_FACLIN' +
        '`, `NOMBRE_FAM_FACLIN`, `' +
        'PRECIO_ULT_COMPRA_FACLIN`, `CODIGO_PRV_FACLIN`, `RAZON_SOCIAL_PR' +
        'OVEEDOR_FACLIN`, `ESPROVEEDORPRINCIPAL_FACLIN`, `FECHA_ENTREGA_F' +
        'ACLIN`, `TIPO_CANTIDAD_ARTICULO_FACLIN`, `ESIMP_INCL_TARIFA_FACL' +
        'IN`, `TIPO_IVA_ARTICULO_FACLIN`, `DESCRIPCION_ARTICULO_FACLIN`, ' +
        '`DESCRIPCION_VARIACION_FACLIN`, `CODIGO_TAR_FACLIN`, `CANTIDAD_' +
        'FACLIN`, `PRECIO_SALIDA_FACLIN`, ' +
        '`PORCENTAJE_DTO_FACLIN`, `PRECIO_DTO_FACLIN`, `PRECIO_VENTA_SIVA' +
        '_ARTICULO_FACLIN`, `PORCENTAJE_IVA_FACLIN`, `PRECIO_VENTA_CIVA_A' +
        'RTICULO_FACLIN`, `TOTAL_FACLIN`, `TOTAL_FAC_SIVA_FACLIN`, `INSTA' +
        'NTE_MODIF`, `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF` FRO' +
        'M `fza_facturas_lineas`'
      'WHERE'
      
        '  `NUMERO_FAC_FACLIN` = :`Old_NUMERO_FAC_FACLIN` AND `SERIE_FAC_' +
        'FACLIN` = :`Old_SERIE_FAC_FACLIN` AND `LINEA_FACLIN` = :`Old_LIN' +
        'EA_FACLIN`'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT `NUMERO_FAC_FACLIN`, `SERIE_FAC_FACLIN`, `LINEA_FACLIN`, ' +
        '`CODIGO_ART_FACLIN`, `CODIGO_UNIDAD_FACLIN`, `CODIGO_FAM_FACLIN' +
        '`, `NOMBRE_FAM_FACLIN`, `' +
        'PRECIO_ULT_COMPRA_FACLIN`, `CODIGO_PRV_FACLIN`, `RAZON_SOCIAL_PR' +
        'OVEEDOR_FACLIN`, `ESPROVEEDORPRINCIPAL_FACLIN`, `FECHA_ENTREGA_F' +
        'ACLIN`, `TIPO_CANTIDAD_ARTICULO_FACLIN`, `ESIMP_INCL_TARIFA_FACL' +
        'IN`, `TIPO_IVA_ARTICULO_FACLIN`, `DESCRIPCION_ARTICULO_FACLIN`, ' +
        '`DESCRIPCION_VARIACION_FACLIN`, `CODIGO_TAR_FACLIN`, `CANTIDAD_' +
        'FACLIN`, `PRECIO_SALIDA_FACLIN`, ' +
        '`PORCENTAJE_DTO_FACLIN`, `PRECIO_DTO_FACLIN`, `PRECIO_VENTA_SIVA' +
        '_ARTICULO_FACLIN`, `PORCENTAJE_IVA_FACLIN`, `PRECIO_VENTA_CIVA_A' +
        'RTICULO_FACLIN`, `TOTAL_FACLIN`, `TOTAL_FAC_SIVA_FACLIN`, `INSTA' +
        'NTE_MODIF`, `INSTANTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF` FRO' +
        'M `fza_facturas_lineas`'
      'WHERE'
      
        '  `NUMERO_FAC_FACLIN` = :`NUMERO_FAC_FACLIN` AND `SERIE_FAC_FACL' +
        'IN` = :`SERIE_FAC_FACLIN` AND `LINEA_FACLIN` = :`LINEA_FACLIN`')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_facturas_lineas')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *'
      'FROM vi_facturas_lineas'
      'where NUMERO_FAC_FACLIN = :NUMERO_FAC'
      'AND SERIE_FAC_FACLIN = :SERIE_FAC'
      'order by NUMERO_FAC_FACLIN, SERIE_FAC_FACLIN, LINEA_FACLIN ASC')
    MasterSource = dsFactura
    MasterFields = 'SERIE_FAC;NUMERO_FAC'
    DetailFields = 'SERIE_FAC_FACLIN;NUMERO_FAC_FACLIN'
    BeforeInsert = unqryLinFacBeforeInsert
    AfterInsert = unqryLinFacAfterInsert
    BeforeEdit = unqryLinFacBeforeEdit
    BeforePost = unqryLinFacBeforePost
    AfterPost = unqryLinFacAfterPost
    AfterDelete = unqryLinFacAfterDelete
    Left = 134
    Top = 109
    ParamData = <
      item
        DataType = ftWideString
        Name = 'NUMERO_FAC'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'SERIE_FAC'
        ParamType = ptInput
        Value = nil
      end>
  end
  object unstrdprcCrearFacturaAbono: TUniStoredProc
    StoredProcName = 'PRC_CREAR_FACTURA_ABONO'
    SQL.Strings = (
      
        'CALL PRC_CREAR_FACTURA_ABONO(:pidseriefactura, :pidnumfactura, :' +
        'pidseriefacturaabono, :pidcodigo_empresa, :pfechafacturaabono, @' +
        'pidnumfacturaabono, :pUSUARIO); SELECT @pidnumfacturaabono AS '#39'@' +
        'pidnumfacturaabono'#39)
    Connection = dmConn.conUni
    Left = 958
    Top = 237
    ParamData = <
      item
        DataType = ftWideString
        Name = 'pidseriefactura'
        ParamType = ptInput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pidnumfactura'
        ParamType = ptInput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pidseriefacturaabono'
        ParamType = ptInput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pidcodigo_empresa'
        ParamType = ptInput
        Size = 200
        Value = nil
      end
      item
        DataType = ftDate
        Name = 'pfechafacturaabono'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pidnumfacturaabono'
        ParamType = ptOutput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pUSUARIO'
        ParamType = ptInput
        Size = 100
        Value = nil
      end>
    CommandStoredProcName = 'PRC_CREAR_FACTURA_ABONO'
  end
  object unstrdprcDuplicarFactura: TUniStoredProc
    StoredProcName = 'PRC_CREAR_FACTURA_DUPLICADA'
    SQL.Strings = (
      
        'CALL PRC_CREAR_FACTURA_DUPLICADA(:pidseriefactura, :pidnumfactur' +
        'a, :pidseriefacturaabono, :pidcodigo_empresa, :pfechafacturaabon' +
        'o, :pUSUARIO, @pidnumfacturaabono); SELECT @pidnumfacturaabono A' +
        'S '#39'@pidnumfacturaabono'#39)
    Connection = dmConn.conUni
    Left = 838
    Top = 237
    ParamData = <
      item
        DataType = ftWideString
        Name = 'pidseriefactura'
        ParamType = ptInput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pidnumfactura'
        ParamType = ptInput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pidseriefacturaabono'
        ParamType = ptInput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pidcodigo_empresa'
        ParamType = ptInput
        Size = 200
        Value = nil
      end
      item
        DataType = ftDate
        Name = 'pfechafacturaabono'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pUSUARIO'
        ParamType = ptInput
        Size = 100
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pidnumfacturaabono'
        ParamType = ptOutput
        Size = 200
        Value = nil
      end>
    CommandStoredProcName = 'PRC_CREAR_FACTURA_DUPLICADA'
  end
  object unstrdprcGetDataArticulo: TUniStoredProc
    StoredProcName = 'PRC_GET_DATA_ARTICULO'
    SQL.Strings = (
      
        'CALL PRC_GET_DATA_ARTICULO(:pidcodarticulo, @pidnomarticulo, @pt' +
        'ipoiva); SELECT @pidnomarticulo AS '#39'@pidnomarticulo'#39', @ptipoiva ' +
        'AS '#39'@ptipoiva'#39)
    Connection = dmConn.conUni
    Left = 422
    Top = 218
    ParamData = <
      item
        DataType = ftWideString
        Name = 'pidcodarticulo'
        ParamType = ptInput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pidnomarticulo'
        ParamType = ptOutput
        Size = 1000
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'ptipoiva'
        ParamType = ptOutput
        Size = 2
        Value = nil
      end>
    CommandStoredProcName = 'PRC_GET_DATA_ARTICULO'
  end
  object unstrdprcGetDataCliente: TUniStoredProc
    StoredProcName = 'PRC_GET_DATA_CLIENTE'
    SQL.Strings = (
      
        'CALL PRC_GET_DATA_CLIENTE(:pCODIGO_CLIENTE, @pRAZONSOCIAL_CLIENT' +
        'E, @pNIF_CLIENTE, @pCODIGO_ZONA_IVA_CLIENTE, @pMOVIL_CLIENTE, @p' +
        'ESIVA_RECARGO_CLIENTE, @pESRETENCIONES_CLIENTE, @pESIVA_EXENTO_C' +
        'LIENTE, @pESINTRACOMUNITARIO_CLIENTE, @pESREGIMENESPECIALAGRICOL' +
        'A_CLIENTE, @pEMAIL_CLIENTE, @pDIRECCION1_CLIENTE, @pDIRECCION2_C' +
        'LIENTE, @pPOBLACION_CLIENTE, @pPROVINCIA_CLIENTE, @pCPOSTAL_CLIE' +
        'NTE, @pTARIFA_ARTICULO_CLIENTE, @pTEXTO_LEGAL_FACTURA_CLIENTE, @' +
        'pPAIS_CLIENTE, @pCOD_PAIS_CLIENTE); SELECT @pRAZONSOCIAL_CLIENTE' +
        ' AS '#39'@pRAZONSOCIAL_CLIENTE'#39', @pNIF_CLIENTE AS '#39'@pNIF_CLIENTE'#39', C' +
        'AST(@pCODIGO_ZONA_IVA_CLIENTE AS SIGNED) AS '#39'@pCODIGO_ZONA_IVA_C' +
        'LIENTE'#39', @pMOVIL_CLIENTE AS '#39'@pMOVIL_CLIENTE'#39', @pESIVA_RECARGO_C' +
        'LIENTE AS '#39'@pESIVA_RECARGO_CLIENTE'#39', @pESRETENCIONES_CLIENTE AS ' +
        #39'@pESRETENCIONES_CLIENTE'#39', @pESIVA_EXENTO_CLIENTE AS '#39'@pESIVA_EX' +
        'ENTO_CLIENTE'#39', @pESINTRACOMUNITARIO_CLIENTE AS '#39'@pESINTRACOMUNIT' +
        'ARIO_CLIENTE'#39', @pESREGIMENESPECIALAGRICOLA_CLIENTE AS '#39'@pESREGIM' +
        'ENESPECIALAGRICOLA_CLIENTE'#39', @pEMAIL_CLIENTE AS '#39'@pEMAIL_CLIENTE' +
        #39', @pDIRECCION1_CLIENTE AS '#39'@pDIRECCION1_CLIENTE'#39', @pDIRECCION2_' +
        'CLIENTE AS '#39'@pDIRECCION2_CLIENTE'#39', @pPOBLACION_CLIENTE AS '#39'@pPOB' +
        'LACION_CLIENTE'#39', @pPROVINCIA_CLIENTE AS '#39'@pPROVINCIA_CLIENTE'#39', @' +
        'pCPOSTAL_CLIENTE AS '#39'@pCPOSTAL_CLIENTE'#39', @pTARIFA_ARTICULO_CLIEN' +
        'TE AS '#39'@pTARIFA_ARTICULO_CLIENTE'#39', @pTEXTO_LEGAL_FACTURA_CLIENTE' +
        ' AS '#39'@pTEXTO_LEGAL_FACTURA_CLIENTE'#39', @pPAIS_CLIENTE AS '#39'@pPAIS_C' +
        'LIENTE'#39', @pCOD_PAIS_CLIENTE AS '#39'@pCOD_PAIS_CLIENTE'#39)
    Connection = dmConn.conUni
    Left = 525
    Top = 237
    ParamData = <
      item
        DataType = ftWideString
        Name = 'pCODIGO_CLIENTE'
        ParamType = ptInput
        Size = 10
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pRAZONSOCIAL_CLIENTE'
        ParamType = ptOutput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pNIF_CLIENTE'
        ParamType = ptOutput
        Size = 50
        Value = nil
      end
      item
        DataType = ftInteger
        Name = 'pCODIGO_ZONA_IVA_CLIENTE'
        ParamType = ptOutput
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pMOVIL_CLIENTE'
        ParamType = ptOutput
        Size = 40
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pESIVA_RECARGO_CLIENTE'
        ParamType = ptOutput
        Size = 1
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pESRETENCIONES_CLIENTE'
        ParamType = ptOutput
        Size = 1
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pESIVA_EXENTO_CLIENTE'
        ParamType = ptOutput
        Size = 1
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pESINTRACOMUNITARIO_CLIENTE'
        ParamType = ptOutput
        Size = 1
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pESREGIMENESPECIALAGRICOLA_CLIENTE'
        ParamType = ptOutput
        Size = 1
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pEMAIL_CLIENTE'
        ParamType = ptOutput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pDIRECCION1_CLIENTE'
        ParamType = ptOutput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pDIRECCION2_CLIENTE'
        ParamType = ptOutput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pPOBLACION_CLIENTE'
        ParamType = ptOutput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pPROVINCIA_CLIENTE'
        ParamType = ptOutput
        Size = 200
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pCPOSTAL_CLIENTE'
        ParamType = ptOutput
        Size = 15
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pTARIFA_ARTICULO_CLIENTE'
        ParamType = ptOutput
        Size = 10
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pTEXTO_LEGAL_FACTURA_CLIENTE'
        ParamType = ptOutput
        Size = 1000
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pPAIS_CLIENTE'
        ParamType = ptOutput
        Size = 150
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pCOD_PAIS_CLIENTE'
        ParamType = ptOutput
        Size = 150
        Value = nil
      end>
    CommandStoredProcName = 'PRC_GET_DATA_CLIENTE'
  end
  object dsFormasPago: TDataSource
    DataSet = unqryFormaPago
    Left = 365
    Top = 64
  end
  object unqryVerifactuOpe: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT CODIGO_VFO, DESCRIPCION_VFO'
      'FROM fza_verifactu_operaciones'
      'WHERE ESACTIVO_VFO = '#39'S'#39
      'ORDER BY ORDEN_VFO')
    Left = 365
    Top = 118
  end
  object dsVerifactuOpe: TDataSource
    DataSet = unqryVerifactuOpe
    Left = 365
    Top = 172
  end
  object unqryFormaPago: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_formas_pago'
      
        '  (CODIGO_FP_FP, ESACTIVO_FORMA_PAGO_FP, ORDEN_FORMA_PAGO_FP, DE' +
        'SCRIPCION_FORMA_PAGO_FP, N_PLAZOS_FORMA_PAGO_FP, N_DIAS_ENTRE_PL' +
        'AZOS_FORMA_PAGO_FP, PORCENTAJE_ANTICIPO_FORMA_PAGO_FP, ESDEFAULT' +
        '_FORMA_PAGO_FP, INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USU' +
        'ARIO_MODIF)'
      'VALUES'
      
        '  (:CODIGO_FP_FP, :ESACTIVO_FORMA_PAGO_FP, :ORDEN_FORMA_PAGO_FP,' +
        ' :DESCRIPCION_FORMA_PAGO_FP, :N_PLAZOS_FORMA_PAGO_FP, :N_DIAS_EN' +
        'TRE_PLAZOS_FORMA_PAGO_FP, :PORCENTAJE_ANTICIPO_FORMA_PAGO_FP, :E' +
        'SDEFAULT_FORMA_PAGO_FP, :INSTANTE_MODIF, :INSTANTE_ALTA, :USUARI' +
        'O_ALTA, :USUARIO_MODIF)')
    SQLDelete.Strings = (
      'DELETE FROM fza_formas_pago'
      'WHERE'
      '  CODIGO_FP_FP = :Old_CODIGO_FP_FP')
    SQLUpdate.Strings = (
      'UPDATE fza_formas_pago'
      'SET'
      
        '  CODIGO_FP_FP = :CODIGO_FP_FP, ESACTIVO_FORMA_PAGO_FP = :ESACTI' +
        'VO_FORMA_PAGO_FP, ORDEN_FORMA_PAGO_FP = :ORDEN_FORMA_PAGO_FP, DE' +
        'SCRIPCION_FORMA_PAGO_FP = :DESCRIPCION_FORMA_PAGO_FP, N_PLAZOS_F' +
        'ORMA_PAGO_FP = :N_PLAZOS_FORMA_PAGO_FP, N_DIAS_ENTRE_PLAZOS_FORM' +
        'A_PAGO_FP = :N_DIAS_ENTRE_PLAZOS_FORMA_PAGO_FP, PORCENTAJE_ANTIC' +
        'IPO_FORMA_PAGO_FP = :PORCENTAJE_ANTICIPO_FORMA_PAGO_FP, ESDEFAUL' +
        'T_FORMA_PAGO_FP = :ESDEFAULT_FORMA_PAGO_FP, INSTANTE_MODIF = :IN' +
        'STANTE_MODIF, INSTANTE_ALTA = :INSTANTE_ALTA, USUARIO_ALTA = :US' +
        'UARIO_ALTA, USUARIO_MODIF = :USUARIO_MODIF'
      'WHERE'
      '  CODIGO_FP_FP = :Old_CODIGO_FP_FP')
    SQLLock.Strings = (
      'SELECT * FROM fza_formas_pago'
      'WHERE'
      '  CODIGO_FP_FP = :Old_CODIGO_FP_FP'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT CODIGO_FP_FP, ESACTIVO_FORMA_PAGO_FP, ORDEN_FORMA_PAGO_FP' +
        ', DESCRIPCION_FORMA_PAGO_FP, N_PLAZOS_FORMA_PAGO_FP, N_DIAS_ENTR' +
        'E_PLAZOS_FORMA_PAGO_FP, PORCENTAJE_ANTICIPO_FORMA_PAGO_FP, ESDEF' +
        'AULT_FORMA_PAGO_FP, INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA,' +
        ' USUARIO_MODIF FROM fza_formas_pago'
      'WHERE'
      '  CODIGO_FP_FP = :CODIGO_FP_FP')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_formas_pago')
    Connection = dmConn.conUni
    SQL.Strings = (
      'select * from vi_formapago'
      '')
    ReadOnly = True
    Left = 371
    Top = 141
  end
  object dsRecibos: TDataSource
    DataSet = unqryRecibos
    Left = 589
    Top = 64
  end
  object unqryRecibos: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO `fza_recibos`'
      
        '  (`NUMERO_FAC_REC`, `SERIE_FAC_REC`, `NUMERO_PLAZO_REC`, `FORMA' +
        '_PAGO_ORIGEN_RECIBO_REC`, `FORMA_PAGO_DESCRIPCION_ORIGEN_RECIBO_' +
        'REC`, `EUROS_RECIBO_REC`, `ESTADO_RECIBO_REC`, `FECHA_EXPEDICION' +
        '_RECIBO_REC`, `FECHA_VENCIMIENTO_RECIBO_REC`, `IBAN_CLI_REC`, `F' +
        'ECHA_PAGO_RECIBO_REC`, `LOCALIDAD_EXPEDICION_RECIBO_REC`, `CODIG' +
        'O_CLI_REC`, `RAZON_SOCIAL_CLI_REC`, `DIRECCION1_CLIENTE_RECIBO_R' +
        'EC`, `POBLACION_CLI_REC`, `PROVINCIA_CLI_REC`, `CODIGO_POSTAL_CL' +
        'I_REC`, `IMPORTE_LETRA_RECIBO_REC`, `INSTANTE_MODIF`, `INSTANTE_' +
        'ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF`)'
      'VALUES'
      
        '  (:`NUMERO_FAC_REC`, :`SERIE_FAC_REC`, :`NUMERO_PLAZO_REC`, :`F' +
        'ORMA_PAGO_ORIGEN_RECIBO_REC`, :`FORMA_PAGO_DESCRIPCION_ORIGEN_RE' +
        'CIBO_REC`, :`EUROS_RECIBO_REC`, :`ESTADO_RECIBO_REC`, :`FECHA_EX' +
        'PEDICION_RECIBO_REC`, :`FECHA_VENCIMIENTO_RECIBO_REC`, :`IBAN_CL' +
        'I_REC`, :`FECHA_PAGO_RECIBO_REC`, :`LOCALIDAD_EXPEDICION_RECIBO_' +
        'REC`, :`CODIGO_CLI_REC`, :`RAZON_SOCIAL_CLI_REC`, :`DIRECCION1_C' +
        'LIENTE_RECIBO_REC`, :`POBLACION_CLI_REC`, :`PROVINCIA_CLI_REC`, ' +
        ':`CODIGO_POSTAL_CLI_REC`, :`IMPORTE_LETRA_RECIBO_REC`, :`INSTANT' +
        'E_MODIF`, :`INSTANTE_ALTA`, :`USUARIO_ALTA`, :`USUARIO_MODIF`)')
    SQLDelete.Strings = (
      'DELETE FROM `fza_recibos`'
      'WHERE'
      
        '  `NUMERO_FAC_REC` = :`Old_NUMERO_FAC_REC` AND `SERIE_FAC_REC` =' +
        ' :`Old_SERIE_FAC_REC` AND `NUMERO_PLAZO_REC` = :`Old_NUMERO_PLAZ' +
        'O_REC`')
    SQLUpdate.Strings = (
      'UPDATE `fza_recibos`'
      'SET'
      
        '  `NUMERO_FAC_REC` = :`NUMERO_FAC_REC`, `SERIE_FAC_REC` = :`SERI' +
        'E_FAC_REC`, `NUMERO_PLAZO_REC` = :`NUMERO_PLAZO_REC`, `FORMA_PAG' +
        'O_ORIGEN_RECIBO_REC` = :`FORMA_PAGO_ORIGEN_RECIBO_REC`, `FORMA_P' +
        'AGO_DESCRIPCION_ORIGEN_RECIBO_REC` = :`FORMA_PAGO_DESCRIPCION_OR' +
        'IGEN_RECIBO_REC`, `EUROS_RECIBO_REC` = :`EUROS_RECIBO_REC`, `EST' +
        'ADO_RECIBO_REC` = :`ESTADO_RECIBO_REC`, `FECHA_EXPEDICION_RECIBO' +
        '_REC` = :`FECHA_EXPEDICION_RECIBO_REC`, `FECHA_VENCIMIENTO_RECIB' +
        'O_REC` = :`FECHA_VENCIMIENTO_RECIBO_REC`, `IBAN_CLI_REC` = :`IBA' +
        'N_CLI_REC`, `FECHA_PAGO_RECIBO_REC` = :`FECHA_PAGO_RECIBO_REC`, ' +
        '`LOCALIDAD_EXPEDICION_RECIBO_REC` = :`LOCALIDAD_EXPEDICION_RECIB' +
        'O_REC`, `CODIGO_CLI_REC` = :`CODIGO_CLI_REC`, `RAZON_SOCIAL_CLI_' +
        'REC` = :`RAZON_SOCIAL_CLI_REC`, `DIRECCION1_CLIENTE_RECIBO_REC` ' +
        '= :`DIRECCION1_CLIENTE_RECIBO_REC`, `POBLACION_CLI_REC` = :`POBL' +
        'ACION_CLI_REC`, `PROVINCIA_CLI_REC` = :`PROVINCIA_CLI_REC`, `COD' +
        'IGO_POSTAL_CLI_REC` = :`CODIGO_POSTAL_CLI_REC`, `IMPORTE_LETRA_R' +
        'ECIBO_REC` = :`IMPORTE_LETRA_RECIBO_REC`, `INSTANTE_MODIF` = :`I' +
        'NSTANTE_MODIF`, `INSTANTE_ALTA` = :`INSTANTE_ALTA`, `USUARIO_ALT' +
        'A` = :`USUARIO_ALTA`, `USUARIO_MODIF` = :`USUARIO_MODIF`'
      'WHERE'
      
        '  `NUMERO_FAC_REC` = :`Old_NUMERO_FAC_REC` AND `SERIE_FAC_REC` =' +
        ' :`Old_SERIE_FAC_REC` AND `NUMERO_PLAZO_REC` = :`Old_NUMERO_PLAZ' +
        'O_REC`')
    SQLLock.Strings = (
      'SELECT * FROM fza_recibos'
      'WHERE'
      
        '  `NUMERO_FAC_REC` = :`Old_NUMERO_FAC_REC` AND `SERIE_FAC_REC` =' +
        ' :`Old_SERIE_FAC_REC` AND `NUMERO_PLAZO_REC` = :`Old_NUMERO_PLAZ' +
        'O_REC`'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT `NUMERO_FAC_REC`, `SERIE_FAC_REC`, `NUMERO_PLAZO_REC`, `F' +
        'ORMA_PAGO_ORIGEN_RECIBO_REC`, `FORMA_PAGO_DESCRIPCION_ORIGEN_REC' +
        'IBO_REC`, `EUROS_RECIBO_REC`, `ESTADO_RECIBO_REC`, `FECHA_EXPEDI' +
        'CION_RECIBO_REC`, `FECHA_VENCIMIENTO_RECIBO_REC`, `IBAN_CLI_REC`' +
        ', `FECHA_PAGO_RECIBO_REC`, `LOCALIDAD_EXPEDICION_RECIBO_REC`, `C' +
        'ODIGO_CLI_REC`, `RAZON_SOCIAL_CLI_REC`, `DIRECCION1_CLIENTE_RECI' +
        'BO_REC`, `POBLACION_CLI_REC`, `PROVINCIA_CLI_REC`, `CODIGO_POSTA' +
        'L_CLI_REC`, `IMPORTE_LETRA_RECIBO_REC`, `INSTANTE_MODIF`, `INSTA' +
        'NTE_ALTA`, `USUARIO_ALTA`, `USUARIO_MODIF` FROM `fza_recibos`'
      'WHERE'
      
        '  `NUMERO_FAC_REC` = :`NUMERO_FAC_REC` AND `SERIE_FAC_REC` = :`S' +
        'ERIE_FAC_REC` AND `NUMERO_PLAZO_REC` = :`NUMERO_PLAZO_REC`')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_recibos')
    Connection = dmConn.conUni
    SQL.Strings = (
      'select * from vi_recibos'
      '')
    MasterSource = dsFactura
    MasterFields = 'NUMERO_FAC;SERIE_FAC'
    DetailFields = 'NUMERO_FAC_REC;SERIE_FAC_REC'
    Left = 589
    Top = 141
    ParamData = <
      item
        DataType = ftWideString
        Name = 'NUMERO_FAC'
        ParamType = ptInput
        Value = '00000021'
      end
      item
        DataType = ftWideString
        Name = 'SERIE_FAC'
        ParamType = ptInput
        Value = 'A1'
      end>
  end
  object dsRecibosPrint: TDataSource
    DataSet = unqryRecibosPrint
    Left = 701
    Top = 429
  end
  object fxdsRecibos: TfrxDBDataset
    Description = 'Recibos'
    UserName = 'Recibos'
    CloseDataSource = False
    DataSource = dsRecibosPrint
    BCDToCurrency = False
    DataSetOptions = []
    Left = 701
    Top = 346
  end
  object unqryRecibosPrint: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_recibos'
      
        '  (NUMERO_FAC_REC, SERIE_FAC_REC, NUMERO_PLAZO_REC, FORMA_PAGO_O' +
        'RIGEN_RECIBO_REC, FORMA_PAGO_DESCRIPCION_ORIGEN_RECIBO_REC, EURO' +
        'S_RECIBO_REC, ESTADO_RECIBO_REC, FECHA_EXPEDICION_RECIBO_REC, FE' +
        'CHA_VENCIMIENTO_RECIBO_REC, IBAN_CLI_REC, FECHA_PAGO_RECIBO_REC,' +
        ' LOCALIDAD_EXPEDICION_RECIBO_REC, CODIGO_CLI_REC, RAZON_SOCIAL_C' +
        'LI_REC, DIRECCION1_CLIENTE_RECIBO_REC, POBLACION_CLI_REC, PROVIN' +
        'CIA_CLI_REC, CODIGO_POSTAL_CLI_REC, CODIGO_PAI_CLI_REC, NOMBRE_P' +
        'AI_CLI_REC, IMPORTE_LETRA_RECIBO_REC, INSTANTE_MODIF, INSTANTE_A' +
        'LTA, USUARIO_ALTA, USUARIO_MODIF)'
      'VALUES'
      
        '  (:NUMERO_FAC_REC, :SERIE_FAC_REC, :NUMERO_PLAZO_REC, :FORMA_PA' +
        'GO_ORIGEN_RECIBO_REC, :FORMA_PAGO_DESCRIPCION_ORIGEN_RECIBO_REC,' +
        ' :EUROS_RECIBO_REC, :ESTADO_RECIBO_REC, :FECHA_EXPEDICION_RECIBO' +
        '_REC, :FECHA_VENCIMIENTO_RECIBO_REC, :IBAN_CLI_REC, :FECHA_PAGO_' +
        'RECIBO_REC, :LOCALIDAD_EXPEDICION_RECIBO_REC, :CODIGO_CLI_REC, :' +
        'RAZON_SOCIAL_CLI_REC, :DIRECCION1_CLIENTE_RECIBO_REC, :POBLACION' +
        '_CLI_REC, :PROVINCIA_CLI_REC, :CODIGO_POSTAL_CLI_REC, :CODIGO_PA' +
        'I_CLI_REC, :NOMBRE_PAI_CLI_REC, :IMPORTE_LETRA_RECIBO_REC, :INST' +
        'ANTE_MODIF, :INSTANTE_ALTA, :USUARIO_ALTA, :USUARIO_MODIF)')
    SQLDelete.Strings = (
      'DELETE FROM fza_recibos'
      'WHERE'
      
        '  NUMERO_FAC_REC = :Old_NUMERO_FAC_REC AND SERIE_FAC_REC = :Old_' +
        'SERIE_FAC_REC AND NUMERO_PLAZO_REC = :Old_NUMERO_PLAZO_REC')
    SQLUpdate.Strings = (
      'UPDATE fza_recibos'
      'SET'
      
        '  NUMERO_FAC_REC = :NUMERO_FAC_REC, SERIE_FAC_REC = :SERIE_FAC_R' +
        'EC, NUMERO_PLAZO_REC = :NUMERO_PLAZO_REC, FORMA_PAGO_ORIGEN_RECI' +
        'BO_REC = :FORMA_PAGO_ORIGEN_RECIBO_REC, FORMA_PAGO_DESCRIPCION_O' +
        'RIGEN_RECIBO_REC = :FORMA_PAGO_DESCRIPCION_ORIGEN_RECIBO_REC, EU' +
        'ROS_RECIBO_REC = :EUROS_RECIBO_REC, ESTADO_RECIBO_REC = :ESTADO_' +
        'RECIBO_REC, FECHA_EXPEDICION_RECIBO_REC = :FECHA_EXPEDICION_RECI' +
        'BO_REC, FECHA_VENCIMIENTO_RECIBO_REC = :FECHA_VENCIMIENTO_RECIBO' +
        '_REC, IBAN_CLI_REC = :IBAN_CLI_REC, FECHA_PAGO_RECIBO_REC = :FEC' +
        'HA_PAGO_RECIBO_REC, LOCALIDAD_EXPEDICION_RECIBO_REC = :LOCALIDAD' +
        '_EXPEDICION_RECIBO_REC, CODIGO_CLI_REC = :CODIGO_CLI_REC, RAZON_' +
        'SOCIAL_CLI_REC = :RAZON_SOCIAL_CLI_REC, DIRECCION1_CLIENTE_RECIB' +
        'O_REC = :DIRECCION1_CLIENTE_RECIBO_REC, POBLACION_CLI_REC = :POB' +
        'LACION_CLI_REC, PROVINCIA_CLI_REC = :PROVINCIA_CLI_REC, CODIGO_P' +
        'OSTAL_CLI_REC = :CODIGO_POSTAL_CLI_REC, CODIGO_PAI_CLI_REC = :CO' +
        'DIGO_PAI_CLI_REC, NOMBRE_PAI_CLI_REC = :NOMBRE_PAI_CLI_REC, IMPO' +
        'RTE_LETRA_RECIBO_REC = :IMPORTE_LETRA_RECIBO_REC, INSTANTE_MODIF' +
        ' = :INSTANTE_MODIF, INSTANTE_ALTA = :INSTANTE_ALTA, USUARIO_ALTA' +
        ' = :USUARIO_ALTA, USUARIO_MODIF = :USUARIO_MODIF'
      'WHERE'
      
        '  NUMERO_FAC_REC = :Old_NUMERO_FAC_REC AND SERIE_FAC_REC = :Old_' +
        'SERIE_FAC_REC AND NUMERO_PLAZO_REC = :Old_NUMERO_PLAZO_REC')
    SQLLock.Strings = (
      
        'SELECT NUMERO_FAC_REC, SERIE_FAC_REC, NUMERO_PLAZO_REC, FORMA_PA' +
        'GO_ORIGEN_RECIBO_REC, FORMA_PAGO_DESCRIPCION_ORIGEN_RECIBO_REC, ' +
        'EUROS_RECIBO_REC, ESTADO_RECIBO_REC, FECHA_EXPEDICION_RECIBO_REC' +
        ', FECHA_VENCIMIENTO_RECIBO_REC, IBAN_CLI_REC, FECHA_PAGO_RECIBO_' +
        'REC, LOCALIDAD_EXPEDICION_RECIBO_REC, CODIGO_CLI_REC, RAZON_SOCI' +
        'AL_CLI_REC, DIRECCION1_CLIENTE_RECIBO_REC, POBLACION_CLI_REC, PR' +
        'OVINCIA_CLI_REC, CODIGO_POSTAL_CLI_REC, CODIGO_PAI_CLI_REC, NOMB' +
        'RE_PAI_CLI_REC, IMPORTE_LETRA_RECIBO_REC, INSTANTE_MODIF, INSTAN' +
        'TE_ALTA, USUARIO_ALTA, USUARIO_MODIF FROM fza_recibos'
      'WHERE'
      
        '  NUMERO_FAC_REC = :Old_NUMERO_FAC_REC AND SERIE_FAC_REC = :Old_' +
        'SERIE_FAC_REC AND NUMERO_PLAZO_REC = :Old_NUMERO_PLAZO_REC'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT NUMERO_FAC_REC, SERIE_FAC_REC, NUMERO_PLAZO_REC, FORMA_PA' +
        'GO_ORIGEN_RECIBO_REC, FORMA_PAGO_DESCRIPCION_ORIGEN_RECIBO_REC, ' +
        'EUROS_RECIBO_REC, ESTADO_RECIBO_REC, FECHA_EXPEDICION_RECIBO_REC' +
        ', FECHA_VENCIMIENTO_RECIBO_REC, IBAN_CLI_REC, FECHA_PAGO_RECIBO_' +
        'REC, LOCALIDAD_EXPEDICION_RECIBO_REC, CODIGO_CLI_REC, RAZON_SOCI' +
        'AL_CLI_REC, DIRECCION1_CLIENTE_RECIBO_REC, POBLACION_CLI_REC, PR' +
        'OVINCIA_CLI_REC, CODIGO_POSTAL_CLI_REC, CODIGO_PAI_CLI_REC, NOMB' +
        'RE_PAI_CLI_REC, IMPORTE_LETRA_RECIBO_REC, INSTANTE_MODIF, INSTAN' +
        'TE_ALTA, USUARIO_ALTA, USUARIO_MODIF FROM fza_recibos'
      'WHERE'
      
        '  NUMERO_FAC_REC = :NUMERO_FAC_REC AND SERIE_FAC_REC = :SERIE_FA' +
        'C_REC AND NUMERO_PLAZO_REC = :NUMERO_PLAZO_REC')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_recibos')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * '
      'from vi_recibos'
      '')
    DMLRefresh = True
    Left = 701
    Top = 506
  end
  object unstrdprcGetRecibos: TUniStoredProc
    StoredProcName = 'PRC_CREAR_RECIBOS_FACTURA'
    SQL.Strings = (
      
        'CALL PRC_CREAR_RECIBOS_FACTURA(:pSERIE_FACTURA, :pNRO_FACTURA, :' +
        'pUSUARIO)')
    Connection = dmConn.conUni
    Left = 1024
    Top = 237
    ParamData = <
      item
        DataType = ftWideString
        Name = 'pSERIE_FACTURA'
        ParamType = ptInput
        Size = 12
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pNRO_FACTURA'
        ParamType = ptInput
        Size = 12
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pUSUARIO'
        ParamType = ptInput
        Size = 100
        Value = nil
      end>
    CommandStoredProcName = 'PRC_CREAR_RECIBOS_FACTURA'
  end
  object unqryIvas: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * '
      'FROM vi_ivas'
      '')
    Left = 537
    Top = 115
  end
  object dsIvas: TDataSource
    DataSet = unqryIvas
    Left = 538
    Top = 45
  end
  object unqryEmpDataFac: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_clientes'
      
        '  (CODIGO_CLI_CLI, ESACTIVO_CLI, RAZON_SOCIAL_CLI, NIF_CLI, MOVI' +
        'L_CLI, EMAIL_CLI, DIRECCION1_CLI, DIRECCION2_CLI, POBLACION_CLI,' +
        ' PROVINCIA_CLI, CODIGO_POSTAL_CLI, PAIS_CLIENTE, OBSERVACIONES_C' +
        'LI, REFERENCIA_CLI, CONTACTO_CLI, TELEFONO_CONTACTO_CLI, TELEFON' +
        'O_CLI, IBAN_CLI, IVA_RECARGO_CLIENTE, RETENCIONES_CLIENTE, CODIG' +
        'O_FORMA_PAGO, CODIGO_ZONA_IVA_CLIENTE, TEXTO_LEGAL_FACTURA_CLI, ' +
        'INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF)'
      'VALUES'
      
        '  (:CODIGO_CLI_CLI, :ESACTIVO_CLI, :RAZON_SOCIAL_CLI, :NIF_CLI, ' +
        ':MOVIL_CLI, :EMAIL_CLI, :DIRECCION1_CLI, :DIRECCION2_CLI, :POBLA' +
        'CION_CLI, :PROVINCIA_CLI, :CODIGO_POSTAL_CLI, :PAIS_CLIENTE, :OB' +
        'SERVACIONES_CLI, :REFERENCIA_CLI, :CONTACTO_CLI, :TELEFONO_CONTA' +
        'CTO_CLI, :TELEFONO_CLI, :IBAN_CLI, :IVA_RECARGO_CLIENTE, :RETENC' +
        'IONES_CLIENTE, :CODIGO_FORMA_PAGO, :CODIGO_ZONA_IVA_CLIENTE, :TE' +
        'XTO_LEGAL_FACTURA_CLI, :INSTANTE_MODIF, :INSTANTE_ALTA, :USUARIO' +
        '_ALTA, :USUARIO_MODIF)')
    SQLDelete.Strings = (
      'DELETE FROM fza_clientes'
      'WHERE'
      '  CODIGO_CLI_CLI = :Old_CODIGO_CLI_CLI')
    SQLUpdate.Strings = (
      'UPDATE fza_clientes'
      'SET'
      
        '  CODIGO_CLI_CLI = :CODIGO_CLI_CLI, ESACTIVO_CLI = :ESACTIVO_CLI' +
        ', RAZON_SOCIAL_CLI = :RAZON_SOCIAL_CLI, NIF_CLI = :NIF_CLI, MOVI' +
        'L_CLI = :MOVIL_CLI, EMAIL_CLI = :EMAIL_CLI, DIRECCION1_CLI = :DI' +
        'RECCION1_CLI, DIRECCION2_CLI = :DIRECCION2_CLI, POBLACION_CLI = ' +
        ':POBLACION_CLI, PROVINCIA_CLI = :PROVINCIA_CLI, CODIGO_POSTAL_CL' +
        'I = :CODIGO_POSTAL_CLI, PAIS_CLIENTE = :PAIS_CLIENTE, OBSERVACIO' +
        'NES_CLI = :OBSERVACIONES_CLI, REFERENCIA_CLI = :REFERENCIA_CLI, ' +
        'CONTACTO_CLI = :CONTACTO_CLI, TELEFONO_CONTACTO_CLI = :TELEFONO_' +
        'CONTACTO_CLI, TELEFONO_CLI = :TELEFONO_CLI, IBAN_CLI = :IBAN_CLI' +
        ', IVA_RECARGO_CLIENTE = :IVA_RECARGO_CLIENTE, RETENCIONES_CLIENT' +
        'E = :RETENCIONES_CLIENTE, CODIGO_FORMA_PAGO = :CODIGO_FORMA_PAGO' +
        ', CODIGO_ZONA_IVA_CLIENTE = :CODIGO_ZONA_IVA_CLIENTE, TEXTO_LEGA' +
        'L_FACTURA_CLI = :TEXTO_LEGAL_FACTURA_CLI, INSTANTE_MODIF = :INST' +
        'ANTE_MODIF, INSTANTE_ALTA = :INSTANTE_ALTA, USUARIO_ALTA = :USUA' +
        'RIO_ALTA, USUARIO_MODIF = :USUARIO_MODIF'
      'WHERE'
      '  CODIGO_CLI_CLI = :Old_CODIGO_CLI_CLI')
    SQLLock.Strings = (
      'SELECT * FROM fza_clientes'
      'WHERE'
      '  CODIGO_CLI_CLI = :Old_CODIGO_CLI_CLI'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT CODIGO_CLI_CLI, ESACTIVO_CLI, RAZON_SOCIAL_CLI, NIF_CLI, ' +
        'MOVIL_CLI, EMAIL_CLI, DIRECCION1_CLI, DIRECCION2_CLI, POBLACION_' +
        'CLI, PROVINCIA_CLI, CODIGO_POSTAL_CLI, PAIS_CLIENTE, OBSERVACION' +
        'ES_CLI, REFERENCIA_CLI, CONTACTO_CLI, TELEFONO_CONTACTO_CLI, TEL' +
        'EFONO_CLI, IBAN_CLI, IVA_RECARGO_CLIENTE, RETENCIONES_CLIENTE, C' +
        'ODIGO_FORMA_PAGO, CODIGO_ZONA_IVA_CLIENTE, TEXTO_LEGAL_FACTURA_C' +
        'LI, INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF F' +
        'ROM fza_clientes'
      'WHERE'
      '  CODIGO_CLI_CLI = :CODIGO_CLI_CLI')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_clientes')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM vi_emp_busquedas')
    Left = 106
    Top = 429
  end
  object dsTarifas: TDataSource
    DataSet = unqryTarifas
    Left = 486
    Top = 64
  end
  object unqryTarifas: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *'
      'FROM vi_tarifas'
      '')
    Left = 486
    Top = 141
  end
  object unstdGetContadorLinea: TUniStoredProc
    StoredProcName = 'PRC_FNC_GET_NEXT_LINEA_FACTURA'
    SQL.Strings = (
      
        'CALL PRC_FNC_GET_NEXT_LINEA_FACTURA(:pnumfac, :pserie, @presul);' +
        ' SELECT @presul AS '#39'@presul'#39)
    Connection = dmConn.conUni
    Left = 627
    Top = 269
    ParamData = <
      item
        DataType = ftWideString
        Name = 'pnumfac'
        ParamType = ptInput
        Size = 8
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pserie'
        ParamType = ptInput
        Size = 8
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'presul'
        ParamType = ptOutput
        Size = 3
        Value = '010'
      end>
    CommandStoredProcName = 'PRC_FNC_GET_NEXT_LINEA_FACTURA'
  end
  object unstdCalcularFactura: TUniStoredProc
    StoredProcName = 'PRC_CALCULAR_FACTURA_NETOS'
    SQL.Strings = (
      'CALL PRC_CALCULAR_FACTURA_NETOS(:pSERIE_FACTURA, :pNRO_FACTURA)')
    Connection = dmConn.conUni
    Left = 736
    Top = 237
    ParamData = <
      item
        DataType = ftWideString
        Name = 'pSERIE_FACTURA'
        ParamType = ptInput
        Size = 10
        Value = nil
      end
      item
        DataType = ftInteger
        Name = 'pNRO_FACTURA'
        ParamType = ptInput
        Value = nil
      end>
    CommandStoredProcName = 'PRC_CALCULAR_FACTURA_NETOS'
  end
  object dsSeriesEditCombo: TDataSource
    DataSet = unqrySeriesEditCombo
    Left = 678
    Top = 45
  end
  object unqrySeriesEditCombo: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      '')
    Left = 678
    Top = 115
  end
  object unstrdprcGetContadorFactura: TUniStoredProc
    StoredProcName = 'PRC_GET_NEXT_CONT_FACT_SERIE'
    SQL.Strings = (
      
        'CALL PRC_GET_NEXT_CONT_FACT_SERIE(:pserie, :pTipoDoc, :pEMPRESA_' +
        'CONTADOR, :pUSUARIOMODIF, @pcont); SELECT @pcont AS '#39'@pcont'#39)
    Connection = dmConn.conUni
    Left = 45
    Top = 237
    ParamData = <
      item
        DataType = ftWideString
        Name = 'pserie'
        ParamType = ptInput
        Size = 10
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pTipoDoc'
        ParamType = ptInput
        Size = 2
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pEMPRESA_CONTADOR'
        ParamType = ptInput
        Size = 10
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pUSUARIOMODIF'
        ParamType = ptInput
        Size = 100
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pcont'
        ParamType = ptOutput
        Size = 12
        Value = nil
      end>
    CommandStoredProcName = 'PRC_GET_NEXT_CONT_FACT_SERIE'
  end
  object unqryIvasTipos: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * '
      'FROM fza_ivas_tipos'
      '')
    Left = 767
    Top = 141
  end
  object dsIvasTipos: TDataSource
    DataSet = unqryIvasTipos
    Left = 768
    Top = 64
  end
  object dsFactura: TDataSource
    DataSet = unqryTablaG
    Left = 294
    Top = 352
  end
  object dsPaisesCli: TDataSource
    DataSet = unqryPaisesCli
    Left = 838
    Top = 51
  end
  object unqryPaisesCli: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_historia'
      
        '  (ID, CODIGO_ART_ART, DESCRIPCION_ART, CODIGO_CLI_CLI, PRECIOVE' +
        'NTA_ARTICULO, FECHA, ZONA, DESCRIPCION_HISTORIA, NUMERO_FAC, LIN' +
        'EA_LINEA, ODONTOLOGO, SERIE_FAC)'
      'VALUES'
      
        '  (:ID, :CODIGO_ART_ART, :DESCRIPCION_ART, :CODIGO_CLI_CLI, :PRE' +
        'CIOVENTA_ARTICULO, :FECHA, :ZONA, :DESCRIPCION_HISTORIA, :NUMERO' +
        '_FAC, :LINEA_LINEA, :ODONTOLOGO, :SERIE_FAC)')
    SQLDelete.Strings = (
      'DELETE FROM fza_historia'
      'WHERE'
      '  ID = :Old_ID')
    SQLUpdate.Strings = (
      'UPDATE fza_historia'
      'SET'
      
        '  ID = :ID, CODIGO_ART_ART = :CODIGO_ART_ART, DESCRIPCION_ART = ' +
        ':DESCRIPCION_ART, CODIGO_CLI_CLI = :CODIGO_CLI_CLI, PRECIOVENTA_' +
        'ARTICULO = :PRECIOVENTA_ARTICULO, FECHA = :FECHA, ZONA = :ZONA, ' +
        'DESCRIPCION_HISTORIA = :DESCRIPCION_HISTORIA, NUMERO_FAC = :NUME' +
        'RO_FAC, LINEA_LINEA = :LINEA_LINEA, ODONTOLOGO = :ODONTOLOGO, SE' +
        'RIE_FAC = :SERIE_FAC'
      'WHERE'
      '  ID = :Old_ID')
    SQLLock.Strings = (
      'SELECT * FROM fza_historia'
      'WHERE'
      '  ID = :Old_ID'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT ID, CODIGO_ART_ART, DESCRIPCION_ART, CODIGO_CLI_CLI, PREC' +
        'IOVENTA_ARTICULO, FECHA, ZONA, DESCRIPCION_HISTORIA, NUMERO_FAC,' +
        ' LINEA_LINEA, ODONTOLOGO, SERIE_FAC FROM fza_historia'
      'WHERE'
      '  ID = :ID')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_historia')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT CODIGO_PAI_PAI AS CODIGO, NOMBRE_SPA_PAI AS NOMBRE'
      ', COD_ALPHA2_PAI'
      'FROM fza_paises ORDER BY ORDEN_PAI, NOMBRE_SPA_PAI'
      '')
    ReadOnly = True
    Left = 838
    Top = 115
  end
  object unqryPaisesEmp: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_historia'
      
        '  (ID, CODIGO_ART_ART, DESCRIPCION_ART, CODIGO_CLI_CLI, PRECIOVE' +
        'NTA_ARTICULO, FECHA, ZONA, DESCRIPCION_HISTORIA, NUMERO_FAC, LIN' +
        'EA_LINEA, ODONTOLOGO, SERIE_FAC)'
      'VALUES'
      
        '  (:ID, :CODIGO_ART_ART, :DESCRIPCION_ART, :CODIGO_CLI_CLI, :PRE' +
        'CIOVENTA_ARTICULO, :FECHA, :ZONA, :DESCRIPCION_HISTORIA, :NUMERO' +
        '_FAC, :LINEA_LINEA, :ODONTOLOGO, :SERIE_FAC)')
    SQLDelete.Strings = (
      'DELETE FROM fza_historia'
      'WHERE'
      '  ID = :Old_ID')
    SQLUpdate.Strings = (
      'UPDATE fza_historia'
      'SET'
      
        '  ID = :ID, CODIGO_ART_ART = :CODIGO_ART_ART, DESCRIPCION_ART = ' +
        ':DESCRIPCION_ART, CODIGO_CLI_CLI = :CODIGO_CLI_CLI, PRECIOVENTA_' +
        'ARTICULO = :PRECIOVENTA_ARTICULO, FECHA = :FECHA, ZONA = :ZONA, ' +
        'DESCRIPCION_HISTORIA = :DESCRIPCION_HISTORIA, NUMERO_FAC = :NUME' +
        'RO_FAC, LINEA_LINEA = :LINEA_LINEA, ODONTOLOGO = :ODONTOLOGO, SE' +
        'RIE_FAC = :SERIE_FAC'
      'WHERE'
      '  ID = :Old_ID')
    SQLLock.Strings = (
      'SELECT * FROM fza_historia'
      'WHERE'
      '  ID = :Old_ID'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT ID, CODIGO_ART_ART, DESCRIPCION_ART, CODIGO_CLI_CLI, PREC' +
        'IOVENTA_ARTICULO, FECHA, ZONA, DESCRIPCION_HISTORIA, NUMERO_FAC,' +
        ' LINEA_LINEA, ODONTOLOGO, SERIE_FAC FROM fza_historia'
      'WHERE'
      '  ID = :ID')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_historia')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT CODIGO_PAI_PAI AS CODIGO, NOMBRE_SPA_PAI AS NOMBRE'
      ', COD_ALPHA2_PAI'
      'FROM fza_paises ORDER BY ORDEN_PAI, NOMBRE_SPA_PAI'
      '')
    ReadOnly = True
    Left = 896
    Top = 154
  end
  object dsPaisesEmp: TDataSource
    DataSet = unqryPaisesEmp
    Left = 896
    Top = 64
  end
  object dsConsolidacion: TDataSource
    DataSet = unqryConsolidacion
    Left = 1045
    Top = 54
  end
  object unqryConsolidacion: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_facturas_consolidaciones'
      
        '  (ID_FACCON, SERIE_FAC_FACCON, NUMERO_FAC_FACCON, REQUEST_ID_CO' +
        'NSOLIDACION_FACCON, QUEUE_ID_CONSOLIDACION_FACCON, QUEUE_ID_CANC' +
        'EL_FACCON, ISSUER_IRS_ID_CONSOLIDACION_FACCON, ISSUED_TIME_FACCO' +
        'N, CHAIN_NUMBER_FACCON, CHAIN_HASH_FACCON, VERIFACTU_URL_FACCON,' +
        ' QRCODE_BASE64_FACCON, QRCODE_PNG_FACCON, FECHA_PROCESAMIENTO_FA' +
        'CCON, ESTADO_FACCON, RESPUESTA_COMPLETA_FACCON, PETICION_COMPLET' +
        'A_FACCON)'
      'VALUES'
      
        '  (:ID_FACCON, :SERIE_FAC_FACCON, :NUMERO_FAC_FACCON, :REQUEST_I' +
        'D_CONSOLIDACION_FACCON, :QUEUE_ID_CONSOLIDACION_FACCON, :QUEUE_I' +
        'D_CANCEL_FACCON, :ISSUER_IRS_ID_CONSOLIDACION_FACCON, :ISSUED_TI' +
        'ME_FACCON, :CHAIN_NUMBER_FACCON, :CHAIN_HASH_FACCON, :VERIFACTU_' +
        'URL_FACCON, :QRCODE_BASE64_FACCON, :QRCODE_PNG_FACCON, :FECHA_PR' +
        'OCESAMIENTO_FACCON, :ESTADO_FACCON, :RESPUESTA_COMPLETA_FACCON, ' +
        ':PETICION_COMPLETA_FACCON)')
    SQLDelete.Strings = (
      'DELETE FROM fza_facturas_consolidaciones'
      'WHERE'
      '  ID_FACCON = :Old_ID_FACCON')
    SQLUpdate.Strings = (
      'UPDATE fza_facturas_consolidaciones'
      'SET'
      
        '  ID_FACCON = :ID_FACCON, SERIE_FAC_FACCON = :SERIE_FAC_FACCON, ' +
        'NUMERO_FAC_FACCON = :NUMERO_FAC_FACCON, REQUEST_ID_CONSOLIDACION' +
        '_FACCON = :REQUEST_ID_CONSOLIDACION_FACCON, QUEUE_ID_CONSOLIDACI' +
        'ON_FACCON = :QUEUE_ID_CONSOLIDACION_FACCON, QUEUE_ID_CANCEL_FACC' +
        'ON = :QUEUE_ID_CANCEL_FACCON, ISSUER_IRS_ID_CONSOLIDACION_FACCON' +
        ' = :ISSUER_IRS_ID_CONSOLIDACION_FACCON, ISSUED_TIME_FACCON = :IS' +
        'SUED_TIME_FACCON, CHAIN_NUMBER_FACCON = :CHAIN_NUMBER_FACCON, CH' +
        'AIN_HASH_FACCON = :CHAIN_HASH_FACCON, VERIFACTU_URL_FACCON = :VE' +
        'RIFACTU_URL_FACCON, QRCODE_BASE64_FACCON = :QRCODE_BASE64_FACCON' +
        ', QRCODE_PNG_FACCON = :QRCODE_PNG_FACCON, FECHA_PROCESAMIENTO_FA' +
        'CCON = :FECHA_PROCESAMIENTO_FACCON, ESTADO_FACCON = :ESTADO_FACC' +
        'ON, RESPUESTA_COMPLETA_FACCON = :RESPUESTA_COMPLETA_FACCON, PETI' +
        'CION_COMPLETA_FACCON = :PETICION_COMPLETA_FACCON'
      'WHERE'
      '  ID_FACCON = :Old_ID_FACCON')
    SQLLock.Strings = (
      
        'SELECT ID_FACCON, SERIE_FAC_FACCON, NUMERO_FAC_FACCON, REQUEST_I' +
        'D_CONSOLIDACION_FACCON, QUEUE_ID_CONSOLIDACION_FACCON, QUEUE_ID_' +
        'CANCEL_FACCON, ISSUER_IRS_ID_CONSOLIDACION_FACCON, ISSUED_TIME_F' +
        'ACCON, CHAIN_NUMBER_FACCON, CHAIN_HASH_FACCON, VERIFACTU_URL_FAC' +
        'CON, QRCODE_BASE64_FACCON, QRCODE_PNG_FACCON, FECHA_PROCESAMIENT' +
        'O_FACCON, ESTADO_FACCON, RESPUESTA_COMPLETA_FACCON, PETICION_COM' +
        'PLETA_FACCON FROM fza_facturas_consolidaciones'
      'WHERE'
      '  ID_FACCON = :Old_ID_FACCON'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT ID_FACCON, SERIE_FAC_FACCON, NUMERO_FAC_FACCON, REQUEST_I' +
        'D_CONSOLIDACION_FACCON, QUEUE_ID_CONSOLIDACION_FACCON, QUEUE_ID_' +
        'CANCEL_FACCON, ISSUER_IRS_ID_CONSOLIDACION_FACCON, ISSUED_TIME_F' +
        'ACCON, CHAIN_NUMBER_FACCON, CHAIN_HASH_FACCON, VERIFACTU_URL_FAC' +
        'CON, QRCODE_BASE64_FACCON, QRCODE_PNG_FACCON, FECHA_PROCESAMIENT' +
        'O_FACCON, ESTADO_FACCON, RESPUESTA_COMPLETA_FACCON, PETICION_COM' +
        'PLETA_FACCON FROM fza_facturas_consolidaciones'
      'WHERE'
      '  ID_FACCON = :ID_FACCON')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_facturas_consolidaciones')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT fc.*, '
      '       (SELECT q.ESTADO_VFCOLA '
      '          FROM fza_verifactu_cola q '
      '         WHERE q.SERIE_FAC_VFCOLA = fc.SERIE_FAC_FACCON '
      '           AND q.NUMERO_FAC_VFCOLA = fc.NUMERO_FAC_FACCON '
      '           AND q.TIPO_OPERACION_VFCOLA = '#39'SUBSANACION'#39' '
      '         ORDER BY q.ID_VFCOLA DESC LIMIT 1) '
      '         AS ESTADO_SUBSANACION '
      'FROM fza_facturas_consolidaciones fc '
      'WHERE fc.NUMERO_FAC_FACCON = :NUMERO_FAC '
      '  AND fc.SERIE_FAC_FACCON = :SERIE_FAC '
      'ORDER BY fc.ID_FACCON DESC')
    MasterSource = frmMtoFacturasBase.dsTablaG
    MasterFields = 'SERIE_FAC;NUMERO_FAC'
    DetailFields = 'SERIE_FAC_FACCON;NUMERO_FAC_FACCON'
    ReadOnly = True
    Left = 1045
    Top = 131
    ParamData = <
      item
        DataType = ftWideString
        Name = 'NUMERO_FAC'
        ParamType = ptInput
        Value = '000001'
      end
      item
        DataType = ftWideString
        Name = 'SERIE_FAC'
        ParamType = ptInput
        Value = 'A0'
      end>
  end
  object dsErrores: TDataSource
    DataSet = unqryErrores
    Left = 1155
    Top = 56
  end
  object unqryErrores: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *'
      'FROM fza_verifactu_eventos'
      'WHERE NUMERO_FAC_LOG = :NUMERO_FAC'
      '  AND SERIE_FAC_LOG  = :SERIE_FAC'
      'ORDER BY ID_LOG DESC')
    MasterSource = frmMtoFacturasBase.dsTablaG
    MasterFields = 'NUMERO_FAC;SERIE_FAC'
    DetailFields = 'NUMERO_FAC_LOG;SERIE_FAC_LOG'
    ReadOnly = True
    AutoCalcFields = False
    Left = 1155
    Top = 126
    ParamData = <
      item
        DataType = ftWideString
        Name = 'NUMERO_FAC'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'SERIE_FAC'
        ParamType = ptInput
        Value = nil
      end>
  end
  object unqryMovimientosFac: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT M.NUMERO_MOV, M.FECHA_MOV, M.LINEA_MOV, '
      '       M.CODIGO_ALM_MOV, M.NOMBRE_ALMACEN_ORIGEN, '
      '       M.CODIGO_ART_MOV, M.CODIGO_UNIDAD_MOV, '
      '       LEFT(COALESCE(M.DESCRIPCION_ARTICULO_MOV, '
      '                     A.DESCRIPCION_ART), 100) '
      '         AS DESCRIPCION_ARTICULO_MOV, '
      '       M.TIPO_MOV, M.CANTIDAD_MOV, '
      '       M.PRECIO_MEDIO_MOV, M.TOTAL_COSTE_MOV '
      '  FROM vi_movimientos M '
      '  LEFT JOIN fza_articulos A '
      '    ON A.CODIGO_ART_ART = M.CODIGO_ART_MOV '
      ' WHERE M.TIPO_DOC_MOV IN ('#39'FC'#39', '#39'VE'#39') '
      '   AND M.SERIE_DOC_MOV  = :SERIE_FAC '
      '   AND M.NUMERO_DOC_MOV = :NUMERO_FAC '
      ' ORDER BY M.LINEA_MOV')
    MasterSource = frmMtoFacturasBase.dsTablaG
    MasterFields = 'NUMERO_FAC;SERIE_FAC'
    ReadOnly = True
    Left = 1155
    Top = 196
    ParamData = <
      item
        DataType = ftWideString
        Name = 'NUMERO_FAC'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'SERIE_FAC'
        ParamType = ptInput
        Value = nil
      end>
  end
  object dsMovimientosFac: TDataSource
    DataSet = unqryMovimientosFac
    Left = 1235
    Top = 196
  end
  object unstrdprcInsertarMovFac: TUniStoredProc
    StoredProcName = 'PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT'
    Connection = dmConn.conUni
    Left = 1155
    Top = 266
  end
  object unqryAlmacenesFac: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM, CODIGO_EMP_ALM'
      '  FROM fza_almacenes'
      ' WHERE ESACTIVO_ALM = '#39'S'#39
      '   AND COALESCE(TIPO_USO_ALM, '#39#39') NOT IN ('#39'TR'#193'NSITO'#39', '#39'TRANSITO'#39')'
      '   AND CODIGO_EMP_ALM = :EMPRESA'
      ' ORDER BY COALESCE(ORDEN_ALM, 2147483647), CODIGO_ALM_ALM')
    ReadOnly = True
    Left = 1235
    Top = 266
    ParamData = <
      item
        DataType = ftString
        Name = 'EMPRESA'
        ParamType = ptInput
        Value = nil
      end>
  end
  object dsAlmacenesFac: TDataSource
    DataSet = unqryAlmacenesFac
    Left = 1315
    Top = 266
  end
end
