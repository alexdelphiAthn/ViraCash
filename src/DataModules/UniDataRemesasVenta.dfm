inherited dmRemesasVenta: TdmRemesasVenta
  Height = 240
  Width = 360
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT r.*,'
      '       COALESCE(t.TOTAL_PENDIENTE_REMV, 0)'
      '         AS TOTAL_PENDIENTE_REMV,'
      '       GREATEST(COALESCE(r.TOTAL_REMV, 0) -'
      '                COALESCE(t.TOTAL_PENDIENTE_REMV, 0), 0)'
      '         AS TOTAL_COBRADO_REMV'
      '  FROM vi_remesas_venta r'
      '  LEFT JOIN ('
      '    SELECT SERIE_REMV_EFV, NUMERO_REMV_EFV,'
      '           SUM(COALESCE(IMPORTE_PENDIENTE_EFV, 0))'
      '             AS TOTAL_PENDIENTE_REMV'
      '      FROM fza_efectos_venta'
      '     WHERE SERIE_REMV_EFV IS NOT NULL'
      '       AND NUMERO_REMV_EFV IS NOT NULL'
      '     GROUP BY SERIE_REMV_EFV, NUMERO_REMV_EFV'
      '  ) t ON t.SERIE_REMV_EFV = r.SERIE_REMV'
      '     AND t.NUMERO_REMV_EFV = r.NUMERO_REMV'
      ' ORDER BY r.FECHA_REMV DESC, r.SERIE_REMV, r.NUMERO_REMV')
    Left = 24
  end
  object unqryEfectosRemesa: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT SERIE_REMV_EFV, NUMERO_REMV_EFV,'
      '       SERIE_FAC_EFV, NUMERO_FAC_EFV, NUMERO_EFV,'
      '       COALESCE(NOMBRE_CLI_VIEW_EFV, RAZON_SOCIAL_CLI_EFV)'
      '         AS CLIENTE_VIEW_EFV,'
      '       DESCRIPCION_TEFE_VIEW_EFV, CODIGO_TEFE_EFV,'
      '       FECHA_VENCIMIENTO_EFV, IMPORTE_EFV,'
      '       IMPORTE_COBRADO_EFV, IMPORTE_PENDIENTE_EFV,'
      '       ESTADO_EFV, REFERENCIA_DOCUMENTO_EFV,'
      '       FECHA_COBRO_EFV, DOC_EXTERNO_EFV'
      '  FROM vi_efectos_venta'
      ' WHERE SERIE_REMV_EFV = :SERIE_REMV'
      '   AND NUMERO_REMV_EFV = :NUMERO_REMV'
      ' ORDER BY FECHA_VENCIMIENTO_EFV, SERIE_FAC_EFV,'
      '          NUMERO_FAC_EFV, NUMERO_EFV')
    MasterFields = 'SERIE_REMV;NUMERO_REMV'
    DetailFields = 'SERIE_REMV_EFV;NUMERO_REMV_EFV'
    Left = 184
    Top = 24
    ParamData = <
      item
        DataType = ftWideString
        Name = 'SERIE_REMV'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'NUMERO_REMV'
        ParamType = ptInput
        Value = nil
      end>
  end
  object dsEfectosRemesa: TDataSource
    DataSet = unqryEfectosRemesa
    Left = 184
    Top = 88
  end
  object unqryBancosEmpresa: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT CODIGO_EMPBAN, CODIGO_EMP_EMPBAN, NOMBRE_EMPBAN,'
      '       IBAN_EMPBAN, ENTIDAD_EMPBAN, OFICINA_EMPBAN,'
      '       DIGITO_CONTROL_EMPBAN, CUENTA_EMPBAN,'
      '       CONCAT(NOMBRE_EMPBAN, '' - '', IBAN_EMPBAN)'
      '         AS BANCO_VIEW_EMPBAN,'
      '       ESDEFECTO_COBRO_EMPBAN, ORDEN_EMPBAN'
      '  FROM vi_empresas_bancos'
      ' WHERE CODIGO_EMP_EMPBAN = :CODIGO_EMP_REMV'
      '   AND COALESCE(ESACTIVO_EMPBAN, ''S'') = ''S'''
      ' ORDER BY ESDEFECTO_COBRO_EMPBAN DESC, ORDEN_EMPBAN,'
      '          NOMBRE_EMPBAN')
    MasterFields = 'CODIGO_EMP_REMV'
    DetailFields = 'CODIGO_EMP_EMPBAN'
    Left = 312
    Top = 24
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_EMP_REMV'
        ParamType = ptInput
        Value = nil
      end>
  end
  object dsBancosEmpresa: TDataSource
    DataSet = unqryBancosEmpresa
    Left = 312
    Top = 88
  end
end


