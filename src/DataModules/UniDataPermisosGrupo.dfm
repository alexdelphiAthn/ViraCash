inherited dmPermisosGrupo: TdmPermisosGrupo
  Height = 200
  Width = 400
  inherited unqryTablaG: TUniQuery
    SQL.Strings = (
      'SELECT * FROM fza_permisos'
      ' ORDER BY USUARIO_GRUPO_PERM, CODIGO_PERM')
  end
end
