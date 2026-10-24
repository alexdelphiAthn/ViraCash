object dmBase: TdmBase
  OnCreate = DataModuleCreate
  OnDestroy = DataModuleDestroy
  Height = 188
  Width = 269
  PixelsPerInch = 120
  object unqryTablaG: TUniQuery
    BeforeInsert = unqryTablaGBeforeInsert
    BeforePost = unqryTablaGBeforePost
    Left = 10
    Top = 30
  end
  object unqryPerfiles: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * '
      'FROM fza_usuarios_perfiles '
      'WHERE USUARIO_GRUPO_USUPER = '#39'Nothing'#39)
    BeforePost = unqryPerfilesBeforePost
    Left = 120
    Top = 30
  end
  object dsPerfiles: TDataSource
    DataSet = unqryPerfiles
    Left = 120
    Top = 100
  end
end
