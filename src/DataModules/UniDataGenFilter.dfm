inherited dmGenFilter: TdmGenFilter
  Width = 426
  object unqryEmpresas: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * '
      'FROM vi_emp_busquedas'
      '')
    Active = True
    BeforePost = unqryPerfilesBeforePost
    Left = 192
    Top = 24
  end
  object dsEmpresas: TDataSource
    DataSet = unqryEmpresas
    Left = 192
    Top = 80
  end
end
