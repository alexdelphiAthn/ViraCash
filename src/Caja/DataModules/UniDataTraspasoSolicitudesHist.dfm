inherited dmTraspasoSolicitudesHist: TdmTraspasoSolicitudesHist
  Height = 376
  Width = 592
  inherited unqryTablaG: TUniQuery
    SQLUpdate.Strings = (
      'UPDATE fza_traspasos_solicitudes'
      '   SET CODIGO_EMPLEADO_TRSOL = :CODIGO_EMPLEADO_TRSOL,'
      '       OBSERVACIONES_TRSOL = :OBSERVACIONES_TRSOL,'
      '       INSTANTE_MODIF = CURRENT_TIMESTAMP,'
      '       USUARIO_MODIF = :USUARIO_MODIF'
      ' WHERE NUMERO_TRSOL = :Old_NUMERO_TRSOL'
      '   AND SERIE_TRSOL = :Old_SERIE_TRSOL')
    SQLLock.Strings = (
      'SELECT NUMERO_TRSOL'
      '  FROM fza_traspasos_solicitudes'
      ' WHERE NUMERO_TRSOL = :Old_NUMERO_TRSOL'
      '   AND SERIE_TRSOL = :Old_SERIE_TRSOL'
      ' FOR UPDATE')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_traspasos_solicitudes')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT S.NUMERO_TRSOL,'
      '       S.SERIE_TRSOL,'
      '       S.FECHA_TRSOL,'
      '       S.INSTANTE_ALTA,'
      '       S.TIPO_TRSOL,'
      '       S.ESTADO_TRSOL,'
      '       S.INSTANTE_VENTAS_DESDE_TRSOL,'
      '       S.INSTANTE_VENTAS_HASTA_TRSOL,'
      '       CASE'
      '         WHEN S.TIPO_TRSOL = ''AUTO'' THEN ''AUTO'''
      '         WHEN S.ESTADO_TRSOL = ''PENDIENTE'' THEN ''PENDIENTE'''
      '         WHEN S.ESTADO_TRSOL IN (''COMPLETADO TOTAL'', ''ATENDIDA'')'
      '           THEN ''ATENDIDA'''
      '         WHEN S.ESTADO_TRSOL IN (''COMPLETADO PARCIAL'', ''PARCIAL'')'
      '           THEN ''RECHAZADA PARCIAL'''
      '         WHEN S.ESTADO_TRSOL IN (''DENEGADO TOTAL'', ''RECHAZADA'','
      '              ''CANCELADA'', ''CERRADA'')'
      '           THEN ''RECHAZADA TOTAL'''
      '         ELSE COALESCE(S.ESTADO_TRSOL, '''')'
      '       END AS MODO_PETICION_TRSOL,'
      '       CASE'
      '         WHEN S.TIPO_TRSOL = ''AUTO'' THEN ''NO APLICA'''
      '         WHEN COALESCE(R.CANTIDAD_SERVIDA_TRSOL, 0) = 0'
      '           THEN ''NO ATENDIDA'''
      '         WHEN COALESCE(R.CANTIDAD_PEDIDA_TRSOL, 0) > 0'
      '          AND COALESCE(R.CANTIDAD_SERVIDA_TRSOL, 0) ='
      '              COALESCE(R.CANTIDAD_PEDIDA_TRSOL, 0)'
      '           THEN ''ATENDIDA TOTAL'''
      '         ELSE ''ATENDIDA PARCIAL'''
      '       END AS ATENDIDA_TRSOL,'
      '       CASE WHEN COALESCE(T.TOTAL_TRASPASOS_TRSOL, 0) > 0'
      '            THEN ''S'' ELSE ''N'''
      '       END AS TIENE_TRASPASO_TRSOL,'
      '       COALESCE(T.TOTAL_TRASPASOS_TRSOL, 0)'
      '         AS TOTAL_TRASPASOS_TRSOL,'
      '       S.CODIGO_EMP_TRSOL,'
      '       EP.RAZON_SOCIAL_EMP AS NOMBRE_EMPRESA_TRSOL,'
      '       S.CODIGO_ALM_ORIGEN_TRSOL,'
      '       AO.NOMBRE_ALM_ALM AS NOMBRE_ALMACEN_ORIGEN_TRSOL,'
      '       S.CODIGO_EMP_CONTRA_TRSOL,'
      '       EC.RAZON_SOCIAL_EMP AS NOMBRE_EMPRESA_CONTRA_TRSOL,'
      '       S.CODIGO_ALM_DESTINO_TRSOL,'
      '       AD.NOMBRE_ALM_ALM AS NOMBRE_ALMACEN_DESTINO_TRSOL,'
      '       S.CODIGO_CAJA_TRSOL,'
      '       C.DESCRIPCION_ALMCAJ AS NOMBRE_CAJA_TRSOL,'
      '       S.CODIGO_EMPLEADO_TRSOL,'
      '       COALESCE(NULLIF(TRIM(E.NOMBRE_EMPL), ''''),'
      '                NULLIF(TRIM(E.DIMINUTIVO_TICKET_EMPL), ''''),'
      '                S.CODIGO_EMPLEADO_TRSOL)'
      '         AS NOMBRE_EMPLEADO_TRSOL,'
      '       S.OBSERVACIONES_TRSOL,'
      '       COALESCE(R.TOTAL_LINEAS_TRSOL, 0) AS TOTAL_LINEAS_TRSOL,'
      '       CASE WHEN S.TIPO_TRSOL = ''AUTO'' THEN 0 ELSE'
      '         COALESCE(R.LINEAS_ATENDIDAS_TRSOL, 0) END'
      '         AS LINEAS_ATENDIDAS_TRSOL,'
      '       CASE WHEN S.TIPO_TRSOL = ''AUTO'' THEN 0 ELSE'
      '         COALESCE(R.LINEAS_SERVIDAS_TRSOL, 0) END'
      '         AS LINEAS_SERVIDAS_TRSOL,'
      '       CASE WHEN S.TIPO_TRSOL = ''AUTO'' THEN 0 ELSE'
      '         COALESCE(R.LINEAS_RECHAZADAS_TRSOL, 0) END'
      '         AS LINEAS_RECHAZADAS_TRSOL,'
      '       COALESCE(R.LINEAS_PENDIENTES_TRSOL, 0)'
      '         AS LINEAS_PENDIENTES_TRSOL,'
      '       COALESCE(R.CANTIDAD_PEDIDA_TRSOL, 0)'
      '         AS CANTIDAD_PEDIDA_TRSOL,'
      '       CASE WHEN S.TIPO_TRSOL = ''AUTO'' THEN 0 ELSE'
      '         COALESCE(R.CANTIDAD_SERVIDA_TRSOL, 0) END'
      '         AS CANTIDAD_SERVIDA_TRSOL,'
      '       CASE WHEN S.TIPO_TRSOL = ''AUTO'' THEN 0 ELSE'
      '         COALESCE(R.CANTIDAD_PENDIENTE_TRSOL, 0) END'
      '         AS CANTIDAD_PENDIENTE_TRSOL,'
      '       CASE WHEN S.TIPO_TRSOL = ''AUTO'' THEN '''' ELSE'
      '         COALESCE(R.MOTIVOS_RECHAZO_TRSOL, '''') END'
      '         AS MOTIVOS_RECHAZO_TRSOL,'
      '       S.INSTANTE_MODIF,'
      '       S.USUARIO_ALTA,'
      '       S.USUARIO_MODIF'
      '  FROM fza_traspasos_solicitudes S'
      '  LEFT JOIN fza_empresas EP'
      '    ON EP.CODIGO_EMP_EMP = S.CODIGO_EMP_TRSOL'
      '  LEFT JOIN fza_empresas EC'
      '    ON EC.CODIGO_EMP_EMP = S.CODIGO_EMP_CONTRA_TRSOL'
      '  LEFT JOIN fza_almacenes AO'
      '    ON AO.CODIGO_ALM_ALM = S.CODIGO_ALM_ORIGEN_TRSOL'
      '  LEFT JOIN fza_almacenes AD'
      '    ON AD.CODIGO_ALM_ALM = S.CODIGO_ALM_DESTINO_TRSOL'
      '  LEFT JOIN fza_almacenes_cajas C'
      '    ON C.CODIGO_ALM_ALMCAJ = S.CODIGO_ALM_DESTINO_TRSOL'
      '   AND C.CODIGO_CAJA_ALMCAJ = S.CODIGO_CAJA_TRSOL'
      '  LEFT JOIN fza_empleados E'
      '    ON E.CODIGO_EMPL = S.CODIGO_EMPLEADO_TRSOL'
      '  LEFT JOIN ('
      '       SELECT L.NUMERO_TRSOL_TRSOLLIN,'
      '              L.SERIE_TRSOL_TRSOLLIN,'
      '              COUNT(*) AS TOTAL_LINEAS_TRSOL,'
      '              SUM(CASE WHEN L.ESATENDIDA_TRSOLLIN = ''S'''
      '                       THEN 1 ELSE 0 END)'
      '                AS LINEAS_ATENDIDAS_TRSOL,'
      '              SUM(CASE'
      '                    WHEN COALESCE('
      '                         L.CANTIDAD_SERVIDA_TRSOLLIN, 0) > 0'
      '                    THEN 1 ELSE 0 END)'
      '                AS LINEAS_SERVIDAS_TRSOL,'
      '              SUM(CASE'
      '                    WHEN COALESCE('
      '                         L.CANTIDAD_SERVIDA_TRSOLLIN, 0) = 0'
      '                     AND NULLIF(TRIM('
      '                         L.MOTIVO_RECHAZO_TRSOLLIN), '''')'
      '                         IS NOT NULL'
      '                    THEN 1 ELSE 0 END)'
      '                AS LINEAS_RECHAZADAS_TRSOL,'
      '              SUM(CASE'
      '                    WHEN COALESCE('
      '                         L.ESATENDIDA_TRSOLLIN, ''N'') <> ''S'''
      '                     AND NULLIF(TRIM('
      '                         L.MOTIVO_RECHAZO_TRSOLLIN), '''') IS NULL'
      '                    THEN 1 ELSE 0 END)'
      '                AS LINEAS_PENDIENTES_TRSOL,'
      '              SUM(COALESCE('
      '                  L.CANTIDAD_PEDIDA_TRSOLLIN, 0))'
      '                AS CANTIDAD_PEDIDA_TRSOL,'
      '              SUM(COALESCE('
      '                  L.CANTIDAD_SERVIDA_TRSOLLIN, 0))'
      '                AS CANTIDAD_SERVIDA_TRSOL,'
      '              SUM(GREATEST('
      '                  COALESCE(L.CANTIDAD_PEDIDA_TRSOLLIN, 0) -'
      '                  COALESCE(L.CANTIDAD_SERVIDA_TRSOLLIN, 0), 0))'
      '                AS CANTIDAD_PENDIENTE_TRSOL,'
      '              GROUP_CONCAT('
      '                NULLIF(TRIM(L.MOTIVO_RECHAZO_TRSOLLIN), '''')'
      '                ORDER BY L.LINEA_TRSOLLIN SEPARATOR '' | '')'
      '                AS MOTIVOS_RECHAZO_TRSOL'
      '         FROM fza_traspasos_solicitudes_lineas L'
      '        GROUP BY L.NUMERO_TRSOL_TRSOLLIN,'
      '                 L.SERIE_TRSOL_TRSOLLIN'
      '       ) R'
      '    ON R.NUMERO_TRSOL_TRSOLLIN = S.NUMERO_TRSOL'
      '   AND R.SERIE_TRSOL_TRSOLLIN = S.SERIE_TRSOL'
      '  LEFT JOIN ('
      '       SELECT O.NUMERO_REF_ORIGEN_OPCAJA,'
      '              O.SERIE_REF_ORIGEN_OPCAJA,'
      '              COUNT(*) AS TOTAL_TRASPASOS_TRSOL'
      '         FROM fza_caja_operaciones O'
      '        WHERE O.ESTRASPASO_OPCAJA = ''S'''
      '          AND O.NUMERO_REF_ORIGEN_OPCAJA IS NOT NULL'
      '          AND O.SERIE_REF_ORIGEN_OPCAJA IS NOT NULL'
      '        GROUP BY O.NUMERO_REF_ORIGEN_OPCAJA,'
      '                 O.SERIE_REF_ORIGEN_OPCAJA'
      '       ) T'
      '    ON T.NUMERO_REF_ORIGEN_OPCAJA = S.NUMERO_TRSOL'
      '   AND T.SERIE_REF_ORIGEN_OPCAJA = S.SERIE_TRSOL'
      ' ORDER BY S.INSTANTE_ALTA DESC,'
      '          S.SERIE_TRSOL DESC,'
      '          CAST(S.NUMERO_TRSOL AS UNSIGNED) DESC')
    ReadOnly = True
    UpdatingTable = 'S'
    KeyFields = 'NUMERO_TRSOL;SERIE_TRSOL'
    AfterOpen = unqryTablaGAfterOpen
    BeforeInsert = unqryTablaGBeforeInsert
    BeforeEdit = unqryTablaGBeforeEdit
    BeforeDelete = unqryTablaGBeforeDelete
    BeforePost = unqryTablaGBeforePost
    Left = 24
    Top = 24
  end
  object unqryLineas: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT L.NUMERO_TRSOL_TRSOLLIN,'
      '       L.SERIE_TRSOL_TRSOLLIN,'
      '       L.LINEA_TRSOLLIN,'
      '       L.CODIGO_ART_TRSOLLIN,'
      '       L.CODIGO_UNIDAD_TRSOLLIN,'
      '       L.CODIGO_ART_TRSOLLIN AS CODIGO_ART,'
      '       L.CODIGO_UNIDAD_TRSOLLIN AS CODIGO_UNIDAD,'
      '       COALESCE('
      '         NULLIF(TRIM(L.DESCRIPCION_ARTICULO_TRSOLLIN), ''''),'
      '         A.DESCRIPCION_ART, '''') AS DESCRIPCION_ART,'
      '       L.CANTIDAD_PEDIDA_TRSOLLIN,'
      '       CASE WHEN S.TIPO_TRSOL = ''AUTO'' THEN 0 ELSE'
      '         L.CANTIDAD_SERVIDA_TRSOLLIN END'
      '         AS CANTIDAD_SERVIDA_TRSOLLIN,'
      '       CASE WHEN S.TIPO_TRSOL = ''AUTO'' THEN 0 ELSE GREATEST('
      '         COALESCE(L.CANTIDAD_PEDIDA_TRSOLLIN, 0) -'
      '         COALESCE(L.CANTIDAD_SERVIDA_TRSOLLIN, 0), 0) END'
      '         AS CANTIDAD_PENDIENTE_TRSOLLIN,'
      '       CASE WHEN S.TIPO_TRSOL = ''AUTO'' THEN NULL ELSE'
      '         L.ESATENDIDA_TRSOLLIN END AS ESATENDIDA_TRSOLLIN,'
      '       CASE WHEN S.TIPO_TRSOL = ''AUTO'' THEN NULL ELSE'
      '         L.MOTIVO_RECHAZO_TRSOLLIN END'
      '         AS MOTIVO_RECHAZO_TRSOLLIN,'
      '       L.CODIGO_PRV_TRSOLLIN,'
      '       L.RAZON_SOCIAL_PRV_TRSOLLIN,'
      '       L.INSTANTE_MODIF,'
      '       L.INSTANTE_ALTA,'
      '       L.USUARIO_ALTA,'
      '       L.USUARIO_MODIF'
      '  FROM fza_traspasos_solicitudes_lineas L'
      '  JOIN fza_traspasos_solicitudes S'
      '    ON S.NUMERO_TRSOL = L.NUMERO_TRSOL_TRSOLLIN'
      '   AND S.SERIE_TRSOL = L.SERIE_TRSOL_TRSOLLIN'
      '  LEFT JOIN fza_articulos A'
      '    ON A.CODIGO_ART_ART = L.CODIGO_ART_TRSOLLIN'
      ' WHERE L.NUMERO_TRSOL_TRSOLLIN = :NUMERO_TRSOL'
      '   AND L.SERIE_TRSOL_TRSOLLIN = :SERIE_TRSOL'
      ' ORDER BY L.LINEA_TRSOLLIN')
    MasterFields = 'NUMERO_TRSOL;SERIE_TRSOL'
    DetailFields = 'NUMERO_TRSOL_TRSOLLIN;SERIE_TRSOL_TRSOLLIN'
    ReadOnly = True
    Left = 176
    Top = 24
    ParamData = <
      item
        DataType = ftString
        Name = 'NUMERO_TRSOL'
        Value = nil
      end
      item
        DataType = ftString
        Name = 'SERIE_TRSOL'
        Value = nil
      end>
  end
  object dsLineas: TDataSource
    DataSet = unqryLineas
    Left = 176
    Top = 88
  end
  object unqryTraspasos: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT O.ID_OPCAJA,'
      '       O.NUMERO_REF_ORIGEN_OPCAJA,'
      '       O.SERIE_REF_ORIGEN_OPCAJA,'
      '       O.CODIGO_EMP_OPCAJA,'
      '       EO.RAZON_SOCIAL_EMP AS NOMBRE_EMPRESA_ORIGEN_OPCAJA,'
      '       O.CODIGO_ALM_OPCAJA,'
      '       AO.NOMBRE_ALM_ALM AS NOMBRE_ALMACEN_ORIGEN_OPCAJA,'
      '       O.CODIGO_CAJA_OPCAJA,'
      '       C.DESCRIPCION_ALMCAJ AS NOMBRE_CAJA_OPCAJA,'
      '       O.NUMERO_OPERACION_OPCAJA,'
      '       O.TIPO_OPERACION_OPCAJA,'
      '       O.SERIE_FAC_OPCAJA,'
      '       O.NUMERO_FAC_OPCAJA,'
      '       CONCAT_WS(''-'', NULLIF(TRIM(O.SERIE_FAC_OPCAJA), ''''),'
      '                        NULLIF(TRIM(O.NUMERO_FAC_OPCAJA), ''''))'
      '         AS DOCUMENTO_OPCAJA,'
      '       O.FECHA_OPERACION_OPCAJA,'
      '       O.INSTANTE_ALTA AS INSTANTE_ALTA_OPCAJA,'
      '       O.CODIGO_EMPLEADO_OPCAJA,'
      '       COALESCE(NULLIF(TRIM(E.NOMBRE_EMPL), ''''),'
      '                NULLIF(TRIM(E.DIMINUTIVO_TICKET_EMPL), ''''),'
      '                O.CODIGO_EMPLEADO_OPCAJA)'
      '         AS NOMBRE_EMPLEADO_OPCAJA,'
      '       O.CODIGO_EMP_CONTRA_OPCAJA,'
      '       ED.RAZON_SOCIAL_EMP AS NOMBRE_EMPRESA_DESTINO_OPCAJA,'
      '       O.CODIGO_ALM_CONTRA_OPCAJA,'
      '       AD.NOMBRE_ALM_ALM AS NOMBRE_ALMACEN_DESTINO_OPCAJA,'
      '       O.IMPORTE_TOTAL_OPCAJA,'
      '       O.CONCEPTO_GASTO_INGRESO_OPCAJA,'
      '       O.USUARIO_ALTA AS USUARIO_ALTA_OPCAJA,'
      '       O.USUARIO_MODIF AS USUARIO_MODIF_OPCAJA'
      '  FROM fza_caja_operaciones O'
      '  LEFT JOIN fza_empresas EO'
      '    ON EO.CODIGO_EMP_EMP = O.CODIGO_EMP_OPCAJA'
      '  LEFT JOIN fza_empresas ED'
      '    ON ED.CODIGO_EMP_EMP = O.CODIGO_EMP_CONTRA_OPCAJA'
      '  LEFT JOIN fza_almacenes AO'
      '    ON AO.CODIGO_ALM_ALM = O.CODIGO_ALM_OPCAJA'
      '  LEFT JOIN fza_almacenes AD'
      '    ON AD.CODIGO_ALM_ALM = O.CODIGO_ALM_CONTRA_OPCAJA'
      '  LEFT JOIN fza_almacenes_cajas C'
      '    ON C.CODIGO_ALM_ALMCAJ = O.CODIGO_ALM_OPCAJA'
      '   AND C.CODIGO_CAJA_ALMCAJ = O.CODIGO_CAJA_OPCAJA'
      '  LEFT JOIN fza_empleados E'
      '    ON E.CODIGO_EMPL = O.CODIGO_EMPLEADO_OPCAJA'
      ' WHERE O.NUMERO_REF_ORIGEN_OPCAJA = :NUMERO_TRSOL'
      '   AND O.SERIE_REF_ORIGEN_OPCAJA = :SERIE_TRSOL'
      '   AND O.ESTRASPASO_OPCAJA = ''S'''
      ' ORDER BY O.FECHA_OPERACION_OPCAJA,'
      '          O.ID_OPCAJA')
    MasterFields = 'NUMERO_TRSOL;SERIE_TRSOL'
    DetailFields =
      'NUMERO_REF_ORIGEN_OPCAJA;SERIE_REF_ORIGEN_OPCAJA'
    ReadOnly = True
    Left = 320
    Top = 24
    ParamData = <
      item
        DataType = ftString
        Name = 'NUMERO_TRSOL'
        Value = nil
      end
      item
        DataType = ftString
        Name = 'SERIE_TRSOL'
        Value = nil
      end>
  end
  object dsTraspasos: TDataSource
    DataSet = unqryTraspasos
    Left = 320
    Top = 88
  end
  object unqryMovimientos: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT O.ID_OPCAJA,'
      '       M.NUMERO_MOV,'
      '       M.TIPO_DOC_MOV,'
      '       M.SERIE_DOC_MOV,'
      '       M.NUMERO_DOC_MOV,'
      '       M.LINEA_MOV,'
      '       M.FECHA_MOV,'
      '       M.CODIGO_EMP_MOV,'
      '       M.CODIGO_ALM_MOV,'
      '       AO.NOMBRE_ALM_ALM AS NOMBRE_ALMACEN_ORIGEN_MOV,'
      '       M.CODIGO_ALM_CONTRA_MOV,'
      '       AD.NOMBRE_ALM_ALM AS NOMBRE_ALMACEN_DESTINO_MOV,'
      '       M.CODIGO_ART_MOV,'
      '       M.CODIGO_UNIDAD_MOV,'
      '       COALESCE('
      '         NULLIF(TRIM(M.DESCRIPCION_ARTICULO_MOV), ''''),'
      '         A.DESCRIPCION_ART, '''') AS DESCRIPCION_ART,'
      '       M.TIPO_MOV,'
      '       M.CANTIDAD_MOV,'
      '       M.PRECIO_MEDIO_MOV,'
      '       M.TOTAL_COSTE_MOV,'
      '       M.INSTANTE_ALTA AS INSTANTE_ALTA_MOV,'
      '       M.USUARIO_ALTA AS USUARIO_ALTA_MOV'
      '  FROM fza_caja_operaciones O'
      '  JOIN fza_movimientos_almacen M'
      '    ON M.CODIGO_EMP_MOV = O.CODIGO_EMP_OPCAJA'
      '   AND M.CODIGO_ALM_DOC_MOV = O.CODIGO_ALM_OPCAJA'
      '   AND M.CODIGO_CAJA_DOC_MOV = O.CODIGO_CAJA_OPCAJA'
      '   AND M.NUMERO_OPERACION_DOC_MOV = O.NUMERO_OPERACION_OPCAJA'
      '  LEFT JOIN fza_articulos A'
      '    ON A.CODIGO_ART_ART = M.CODIGO_ART_MOV'
      '  LEFT JOIN fza_almacenes AO'
      '    ON AO.CODIGO_ALM_ALM = M.CODIGO_ALM_MOV'
      '  LEFT JOIN fza_almacenes AD'
      '    ON AD.CODIGO_ALM_ALM = M.CODIGO_ALM_CONTRA_MOV'
      ' WHERE O.ID_OPCAJA = :ID_OPCAJA'
      '   AND M.TIPO_MOV = ''S'''
      '   AND COALESCE(M.ESACTIVO_MOV, ''S'') = ''S'''
      ' ORDER BY M.LINEA_MOV, M.NUMERO_MOV')
    MasterFields = 'ID_OPCAJA'
    DetailFields = 'ID_OPCAJA'
    ReadOnly = True
    Left = 464
    Top = 24
    ParamData = <
      item
        DataType = ftLargeint
        Name = 'ID_OPCAJA'
        Value = nil
      end>
  end
  object dsMovimientos: TDataSource
    DataSet = unqryMovimientos
    Left = 464
    Top = 88
  end
end
