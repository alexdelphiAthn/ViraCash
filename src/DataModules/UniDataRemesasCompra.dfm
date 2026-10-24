inherited dmRemesasCompra: TdmRemesasCompra
  Height = 240
  Width = 360
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT r.*,'
      '       COALESCE(t.TOTAL_PENDIENTE_REMC, 0)'
      '         AS TOTAL_PENDIENTE_REMC,'
      '       GREATEST(COALESCE(r.TOTAL_REMC, 0) -'
      '                COALESCE(t.TOTAL_PENDIENTE_REMC, 0), 0)'
      '         AS TOTAL_CARGADO_REMC'
      '  FROM vi_remesas_compra r'
      '  LEFT JOIN ('
      '    SELECT SERIE_REMC_EFEC, NUMERO_REMC_EFEC,'
      '           SUM(COALESCE(IMPORTE_PENDIENTE_EFEC, 0))'
      '             AS TOTAL_PENDIENTE_REMC'
      '      FROM fza_efectos_compra'
      '     WHERE SERIE_REMC_EFEC IS NOT NULL'
      '       AND NUMERO_REMC_EFEC IS NOT NULL'
      '     GROUP BY SERIE_REMC_EFEC, NUMERO_REMC_EFEC'
      '  ) t ON t.SERIE_REMC_EFEC = r.SERIE_REMC'
      '     AND t.NUMERO_REMC_EFEC = r.NUMERO_REMC'
      ' ORDER BY r.FECHA_REMC DESC, r.SERIE_REMC, r.NUMERO_REMC')
    Left = 24
  end
  object unqryEfectosRemesa: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT SERIE_REMC_EFEC, NUMERO_REMC_EFEC,'
      '       SERIE_FACC_EFEC, NUMERO_FACC_EFEC, NUMERO_EFEC,'
      '       COALESCE(NOMBRE_PRV_VIEW_EFEC, RAZON_SOCIAL_PRV_EFEC)'
      '         AS PROVEEDOR_VIEW_EFEC,'
      '       DESCRIPCION_TEFE_VIEW_EFEC, CODIGO_TEFE_EFEC,'
      '       FECHA_VENCIMIENTO_EFEC, IMPORTE_EFEC,'
      '       IMPORTE_PAGADO_EFEC, IMPORTE_PENDIENTE_EFEC,'
      '       ESTADO_EFEC, REFERENCIA_DOCUMENTO_EFEC,'
      '       FECHA_PAGO_EFEC, DOC_EXTERNO_EFEC'
      '  FROM vi_efectos_compra'
      ' WHERE SERIE_REMC_EFEC = :SERIE_REMC'
      '   AND NUMERO_REMC_EFEC = :NUMERO_REMC'
      ' ORDER BY FECHA_VENCIMIENTO_EFEC, SERIE_FACC_EFEC,'
      '          NUMERO_FACC_EFEC, NUMERO_EFEC')
    MasterFields = 'SERIE_REMC;NUMERO_REMC'
    DetailFields = 'SERIE_REMC_EFEC;NUMERO_REMC_EFEC'
    Left = 184
    Top = 24
    ParamData = <
      item
        DataType = ftWideString
        Name = 'SERIE_REMC'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'NUMERO_REMC'
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
      '       ESDEFECTO_PAGO_EMPBAN, ORDEN_EMPBAN'
      '  FROM vi_empresas_bancos'
      ' WHERE CODIGO_EMP_EMPBAN = :CODIGO_EMP_REMC'
      '   AND COALESCE(ESACTIVO_EMPBAN, ''S'') = ''S'''
      ' ORDER BY ESDEFECTO_PAGO_EMPBAN DESC, ORDEN_EMPBAN,'
      '          NOMBRE_EMPBAN')
    MasterFields = 'CODIGO_EMP_REMC'
    DetailFields = 'CODIGO_EMP_EMPBAN'
    Left = 312
    Top = 24
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_EMP_REMC'
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
