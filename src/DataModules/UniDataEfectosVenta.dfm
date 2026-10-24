inherited dmEfectosVenta: TdmEfectosVenta
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    SQLDelete.Strings = (
      'DELETE FROM `fza_efectos_venta`'
      'WHERE'
      '  `SERIE_FAC_EFV` = :`Old_SERIE_FAC_EFV`'
      '  AND `NUMERO_FAC_EFV` = :`Old_NUMERO_FAC_EFV`'
      '  AND `NUMERO_EFV` = :`Old_NUMERO_EFV`')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *'
      'FROM vi_efectos_venta'
      'ORDER BY FECHA_VENCIMIENTO_EFV, SERIE_FAC_EFV,'
      '         NUMERO_FAC_EFV, NUMERO_EFV')
    BeforeDelete = unqryTablaGBeforeDelete
    Left = 24
  end
end


