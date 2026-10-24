inherited dmVerifactuCola: TdmVerifactuCola
  inherited unqryTablaG: TUniQuery
    SQLUpdate.Strings = (
      'UPDATE `fza_verifactu_cola`'
      'SET'
      '  `ESTADO_VFCOLA` = :`ESTADO_VFCOLA`, `CONTADOR_INTENTOS_VFCOLA` = ' +
      ':`CONTADOR_INTENTOS_VFCOLA`, `INSTANTE_PROXIMO_INTENTO_VFCOLA` = :`' +
      'INSTANTE_PROXIMO_INTENTO_VFCOLA`, `INSTANTE_MODIF` = :`INSTANTE_MOD' +
      'IF`, `USUARIO_MODIF` = :`USUARIO_MODIF`'
      'WHERE'
      '  `ID_VFCOLA` = :`Old_ID_VFCOLA`')
    SQLRefresh.Strings = (
      'SELECT * FROM `fza_verifactu_cola`'
      'WHERE'
      '  `ID_VFCOLA` = :`ID_VFCOLA`')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_verifactu_cola')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *'
      'FROM fza_verifactu_cola'
      'ORDER BY ID_VFCOLA DESC'
      '')
    Active = True
    Left = 24
  end
end
