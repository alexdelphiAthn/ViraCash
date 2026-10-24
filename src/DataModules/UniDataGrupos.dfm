inherited dmGrupos: TdmGrupos
  Width = 360
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *  '
      'FROM fza_usuarios_grupos'
      '')
    Left = 24
  end
  inherited unqryPerfiles: TUniQuery
    Left = 128
  end
  inherited dsPerfiles: TDataSource
    Left = 128
  end
  object unqryUsuariosGrupo: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *  '
      'FROM fza_usuarios'
      'WHERE GRUPO_USU = :GRUPO_USUGRP'
      '')
    MasterSource = frmMtoGrupos.dsTablaG
    MasterFields = 'GRUPO_USUGRP'
    DetailFields = 'GRUPO_USU'
    BeforePost = unqryTablaGBeforePost
    Left = 224
    Top = 24
    ParamData = <
      item
        DataType = ftWideString
        Name = 'GRUPO_USUGRP'
        ParamType = ptInput
        Value = nil
      end>
  end
  object dsUsuariosGrupo: TDataSource
    DataSet = unqryUsuariosGrupo
    Left = 224
    Top = 80
  end
end
