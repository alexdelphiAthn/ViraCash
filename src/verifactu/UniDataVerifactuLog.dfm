inherited dmVerifactuLog: TdmVerifactuLog
  inherited unqryTablaG: TUniQuery
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_verifactu_eventos')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *'
      'FROM fza_verifactu_eventos'
      'ORDER BY ID_LOG DESC'
      '')
    Active = True
    Left = 24
  end
end
