inherited dmEfectosCompra: TdmEfectosCompra
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    SQLDelete.Strings = (
      'DELETE FROM `fza_efectos_compra`'
      'WHERE'
      '  `SERIE_FACC_EFEC` = :`Old_SERIE_FACC_EFEC`'
      '  AND `NUMERO_FACC_EFEC` = :`Old_NUMERO_FACC_EFEC`'
      '  AND `NUMERO_EFEC` = :`Old_NUMERO_EFEC`')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *'
      'FROM vi_efectos_compra'
      'ORDER BY FECHA_VENCIMIENTO_EFEC, SERIE_FACC_EFEC,'
      '         NUMERO_FACC_EFEC, NUMERO_EFEC')
    BeforeDelete = unqryTablaGBeforeDelete
    Left = 24
  end
end
