inherited dmUsuarios: TdmUsuarios
  Height = 187
  Width = 399
  inherited unqryTablaG: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_usuarios'
      
        '  (USUARIO_USU, PASSWORD_USU, GRUPO_USU, ESACTIVO_USU, EMPRESA_DEFECTO_USU, ALMACEN_DEFECTO_USU, CAJA_DEFECTO_USU, ULTIMO_LOGIN_USU, INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF)'
      'VALUES'
      
        '  (:USUARIO_USU, :PASSWORD_USU, :GRUPO_USU, :ESACTIVO_USU, :EMPRESA_DEFECTO_USU, :ALMACEN_DEFECTO_USU, :CAJA_DEFECTO_USU, :ULTIMO_LOGIN_USU, :INSTANTE_MODIF, :INSTANTE_ALTA, :USUARIO_ALTA, :USUARIO_MODIF)')
    SQLDelete.Strings = (
      'DELETE FROM fza_usuarios'
      'WHERE'
      '  USUARIO_USU = :Old_USUARIO_USU')
    SQLUpdate.Strings = (
      'UPDATE fza_usuarios'
      'SET'
      
        '  USUARIO_USU = :USUARIO_USU, PASSWORD_USU = :PASSWORD_USU, GRUPO_USU = :GRUPO_USU, ESACTIVO_USU = :ESACTIVO_USU, EMPRESA_DEFECTO_USU = :EMPRESA_DEFECTO_USU, ALMACEN_DEFECTO_USU = :ALMACEN_DEFECTO_USU, CAJA_DEFECTO_USU = :CAJA_DEFECTO_USU' +
        ', ULTIMO_LOGIN_USU = :ULTIMO_LOGIN_USU, INSTANTE_MODIF = :INSTANTE_MODIF, INSTANTE_ALTA = :INSTANTE_ALTA, USUARIO_ALTA = :USUARIO_ALTA, USUARIO_MODIF = :USUARIO_MODIF'
      'WHERE'
      '  USUARIO_USU = :Old_USUARIO_USU')
    SQLLock.Strings = (
      
        'SELECT USUARIO_USU, PASSWORD_USU, GRUPO_USU, ESACTIVO_USU, EMPRESA_DEFECTO_USU, ALMACEN_DEFECTO_USU, CAJA_DEFECTO_USU, ULTIMO_LOGIN_USU, INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF FROM fza_usuarios'
      'WHERE'
      '  USUARIO_USU = :Old_USUARIO_USU'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      'SELECT * FROM vi_usuarios'
      'WHERE'
      '  USUARIO_USU = :USUARIO_USU')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_usuarios')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *  '
      'FROM vi_usuarios'
      '')
    AfterInsert = unqryTablaGAfterInsert
    Left = 24
  end
  object unqryGrupos: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *  '
      'FROM vi_usuarios_grupos'
      '')
    BeforeInsert = unqryTablaGBeforeInsert
    BeforePost = unqryTablaGBeforePost
    Left = 192
    Top = 24
  end
  object dsGrupos: TDataSource
    DataSet = unqryGrupos
    Left = 192
    Top = 80
  end
  object unqryEmpresas: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *  '
      'FROM vi_emp_busquedas'
      '')
    BeforeInsert = unqryTablaGBeforeInsert
    BeforePost = unqryTablaGBeforePost
    Left = 272
    Top = 24
  end
  object dsEmpresas: TDataSource
    DataSet = unqryEmpresas
    Left = 272
    Top = 80
  end
end
