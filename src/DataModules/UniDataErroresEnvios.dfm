inherited dmErroresEnvios: TdmErroresEnvios
  Height = 180
  Width = 360
  inherited unqryTablaG: TUniQuery
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_errores_envios')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *'
      'FROM fza_errores_envios'
      'ORDER BY ID_ERENV DESC')
    Active = False
    Left = 24
  end
end
