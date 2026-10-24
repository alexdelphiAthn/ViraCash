inherited dmUsuariosPerfiles: TdmUsuariosPerfiles
  OldCreateOrder = True
  inherited unqryTablaG: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *  '
      'FROM fza_usuarios_perfiles'
      '')
    Left = 24
  end
  inherited unqryPerfiles: TUniQuery
    Left = 128
  end
  inherited dsPerfiles: TDataSource
    Left = 128
  end
end
