inherited dmInformeFacturasProforma: TdmInformeFacturasProforma
  Height = 240
  Width = 400
  inherited unqryTablaG: TUniQuery
    Left = 32
    Top = 168
  end
  inherited unqryPerfiles: TUniQuery
    Left = 112
    Top = 168
  end
  inherited dsPerfiles: TDataSource
    Left = 192
    Top = 168
  end
  object unqryProforma: TUniQuery
    SQL.Strings = (
      'SELECT P.*'
      'FROM fza_proformas_caja P'
      'WHERE P.ID_PROCAJ = :id_proforma')
    Left = 48
    Top = 32
    ParamData = <
      item
        DataType = ftLargeint
        Name = 'id_proforma'
        ParamType = ptInput
      end>
  end
  object unqryLineas: TUniQuery
    SQL.Strings = (
      'SELECT L.*,'
      '  CASE WHEN L.TIPO_VINCULO_PROCLIN = '#39'AJUSTE'#39
      '    THEN '#39'AJUSTE POSTERIOR'#39
      '    ELSE '#39'VENTA'#39
      '  END AS DESCRIPCION_VINCULO_PROCLIN'
      'FROM fza_proformas_caja_lineas L'
      'WHERE L.ID_PROCAJ_PROCLIN = :id_proforma'
      'ORDER BY L.FECHA_OPERACION_PROCLIN,'
      '  L.ID_OPCAJA_PROCLIN, L.LINEA_PROCLIN')
    Left = 160
    Top = 32
    ParamData = <
      item
        DataType = ftLargeint
        Name = 'id_proforma'
        ParamType = ptInput
      end>
  end
end
