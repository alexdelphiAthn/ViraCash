inherited dmCajaFormasPago: TdmCajaFormasPago
  inherited unqryTablaG: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *'
      '  FROM fza_caja_formas_pago'
      'ORDER BY ORDEN_VISUAL_FORMA_PAGO_CFP, CODIGO_FP_CFP')
    Active = True
    AfterInsert = unqryTablaGAfterInsert
    Left = 16
  end
  inherited unqryPerfiles: TUniQuery
    SQL.Strings = (
      'select *'
      'from fza_usuarios_perfiles'
      'where (KEY_USUPER = '#39'dmCajaFormasPago'#39
      'OR KEY_USUPER = '#39'frmMtoCajaFormasPago'#39')')
  end
end
