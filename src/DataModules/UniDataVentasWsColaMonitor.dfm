inherited dmVentasWsColaMonitor: TdmVentasWsColaMonitor
  Height = 222
  Width = 486
  inherited unqryTablaG: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT C.ID_VWSC,'
      '       C.ID_EVENTO_VWSC,'
      '       C.CODIGO_EMP_VWSC,'
      '       E.RAZON_SOCIAL_EMP,'
      '       C.SERIE_FAC_VWSC,'
      '       C.NUMERO_FAC_VWSC,'
      '       C.TIPO_EVENTO_VWSC,'
      '       C.VERSION_CONTRATO_VWSC,'
      '       C.ESTADO_VWSC,'
      '       C.CONTADOR_INTENTOS_VWSC,'
      '       C.INSTANTE_PROXIMO_INTENTO_VWSC,'
      '       C.INSTANTE_ENVIO_VWSC,'
      '       C.ID_PETICION_VWSC,'
      '       C.MENSAJE_ERROR_VWSC,'
      '       C.INSTANTE_ALTA,'
      '       C.USUARIO_ALTA,'
      '       C.INSTANTE_MODIF,'
      '       C.USUARIO_MODIF'
      '  FROM fza_ventas_ws_cola C'
      '  LEFT JOIN fza_empresas E'
      '    ON E.CODIGO_EMP_EMP = C.CODIGO_EMP_VWSC'
      ' ORDER BY C.ID_VWSC DESC')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_ventas_ws_cola')
    ReadOnly = True
    Left = 24
    Top = 24
  end
  object unqryIntentos: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT I.ID_VWSCI,'
      '       I.CONTADOR_INTENTO_VWSCI,'
      '       I.ID_PETICION_VWSCI,'
      '       I.METODO_HTTP_VWSCI,'
      '       I.RECURSO_HTTP_VWSCI,'
      '       I.ESTADO_HTTP_VWSCI,'
      '       I.RESULTADO_VWSCI,'
      '       I.CANTIDAD_MILISEGUNDOS_VWSCI,'
      '       I.INSTANTE_INICIO_VWSCI,'
      '       I.INSTANTE_FIN_VWSCI'
      '  FROM fza_ventas_ws_cola_intentos I'
      ' WHERE I.ID_VWSC_VWSCI = :ID_COLA'
      ' ORDER BY I.ID_VWSCI DESC')
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
  object dsIntentos: TDataSource
    DataSet = unqryIntentos
    Left = 176
    Top = 104
  end
  object unqryContenidoIntento: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT I.PETICION_VWSCI,'
      '       I.RESPUESTA_VWSCI,'
      '       I.MENSAJE_VWSCI'
      '  FROM fza_ventas_ws_cola_intentos I'
      ' WHERE I.ID_VWSCI = :ID_INTENTO')
    ReadOnly = True
    Left = 344
    Top = 24
    ParamData = <
      item
        DataType = ftLargeint
        Name = 'ID_INTENTO'
        ParamType = ptInput
        Value = nil
      end>
  end
end
