inherited dmPrestaShopColaMonitor: TdmPrestaShopColaMonitor
  Height = 222
  Width = 486
  inherited unqryTablaG: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT C.ID_PSCOLA,'
      '       C.ID_TIENDA_PSCOLA,'
      '       C.CODIGO_ART_PSCOLA,'
      '       A.DESCRIPCION_ART,'
      '       C.ESCAMBIO_PRECIO_PSCOLA,'
      '       C.ESCAMBIO_STOCK_PSCOLA,'
      '       CASE C.ACCION_VISIBILIDAD_PSCOLA'
      '         WHEN ''A'' THEN ''Activar'''
      '         WHEN ''D'' THEN ''Desactivar'''
      '         ELSE ''Ninguna'''
      '       END AS VISIBILIDAD_PENDIENTE,'
      '       C.ESCAMBIO_PRECIO_RECLAMADO_PSCOLA,'
      '       C.ESCAMBIO_STOCK_RECLAMADO_PSCOLA,'
      '       CASE C.ACCION_VISIBILIDAD_RECLAMADA_PSCOLA'
      '         WHEN ''A'' THEN ''Activar'''
      '         WHEN ''D'' THEN ''Desactivar'''
      '         ELSE ''Ninguna'''
      '       END AS VISIBILIDAD_RECLAMADA,'
      '       C.VERSION_DESEADA_PSCOLA,'
      '       C.VERSION_RECLAMADA_PSCOLA,'
      '       C.ESTADO_PSCOLA,'
      '       C.CONTADOR_INTENTOS_PSCOLA,'
      '       C.INSTANTE_PROXIMO_INTENTO_PSCOLA,'
      '       C.INSTANTE_RECLAMACION_PSCOLA,'
      '       C.INSTANTE_ULTIMO_CAMBIO_PSCOLA,'
      '       C.INSTANTE_ULTIMO_ENVIO_PSCOLA,'
      '       C.MENSAJE_ERROR_PSCOLA,'
      '       C.INSTANTE_ALTA,'
      '       C.USUARIO_ALTA,'
      '       C.INSTANTE_MODIF,'
      '       C.USUARIO_MODIF'
      '  FROM fza_prestashop_cola C'
      '  LEFT JOIN fza_articulos A'
      '    ON A.CODIGO_ART_ART = C.CODIGO_ART_PSCOLA'
      ' ORDER BY C.ID_PSCOLA DESC')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_prestashop_cola')
    ReadOnly = True
    Left = 24
    Top = 24
  end
  object unqryEventos: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT E.ID_PSCEV,'
      '       E.CONTADOR_INTENTO_PSCEV,'
      '       E.ORDEN_OPERACION_PSCEV,'
      '       E.METODO_HTTP_PSCEV,'
      '       E.RECURSO_HTTP_PSCEV,'
      '       E.ESTADO_HTTP_PSCEV,'
      '       E.TEXTO_ESTADO_PSCEV,'
      '       E.RESULTADO_PSCEV,'
      '       E.CANTIDAD_MILISEGUNDOS_PSCEV,'
      '       E.INSTANTE_INICIO_PSCEV,'
      '       E.INSTANTE_FIN_PSCEV'
      '  FROM fza_prestashop_cola_eventos E'
      ' WHERE E.ID_PSCOLA_PSCEV = :ID_COLA'
      ' ORDER BY E.ID_PSCEV DESC')
    ReadOnly = True
    Left = 176
    Top = 24
    ParamData = <
      item
        DataType = ftLargeint
        Name = 'ID_COLA'
        ParamType = ptInput
        Value = nil
      end>
  end
  object dsEventos: TDataSource
    DataSet = unqryEventos
    Left = 176
    Top = 104
  end
  object unqryContenidoEvento: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT E.PETICION_PSCEV,'
      '       E.RESPUESTA_PSCEV,'
      '       E.MENSAJE_PSCEV'
      '  FROM fza_prestashop_cola_eventos E'
      ' WHERE E.ID_PSCEV = :ID_EVENTO')
    ReadOnly = True
    Left = 344
    Top = 24
    ParamData = <
      item
        DataType = ftLargeint
        Name = 'ID_EVENTO'
        ParamType = ptInput
        Value = nil
      end>
  end
end
