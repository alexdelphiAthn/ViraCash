inherited dmPaises: TdmPaises
  inherited unqryTablaG: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_paises'
      '  (CODIGO_PAI_PAI, COD_ALPHA3_PAI, COD_ALPHA2_PAI, NOMBRE_SPA_PAI, NOMBRE_ENG_PAI, ESMIEMBRO_UE_PAI, ORDEN_PAI)'
      'VALUES'
      '  (:CODIGO_PAI_PAI, :COD_ALPHA3_PAI, :COD_ALPHA2_PAI, :NOMBRE_SPA_PAI, :NOMBRE_ENG_PAI, :ESMIEMBRO_UE_PAI, :ORDEN_PAI)')
    SQLDelete.Strings = (
      'DELETE FROM fza_paises'
      'WHERE'
      '  CODIGO_PAI_PAI = :Old_CODIGO_PAI_PAI')
    SQLUpdate.Strings = (
      'UPDATE fza_paises'
      'SET'
      '  CODIGO_PAI_PAI = :CODIGO_PAI_PAI, COD_ALPHA3_PAI = :COD_ALPHA3_PAI, COD_ALPHA2_PAI = :COD_ALPHA2_PAI, NOMBRE_SPA_PAI = :NOMBRE_SPA_PAI, NOMBRE_ENG_PAI = :NOMBRE_ENG_PAI, ESMIEMBRO_UE_PAI = :ESMIEMBRO_UE_PAI, ORDEN_PAI = :ORDEN_PAI'
      'WHERE'
      '  CODIGO_PAI_PAI = :Old_CODIGO_PAI_PAI')
    SQLLock.Strings = (
      'SELECT CODIGO_PAI_PAI, COD_ALPHA3_PAI, COD_ALPHA2_PAI, NOMBRE_SPA_PAI, NOMBRE_ENG_PAI, ESMIEMBRO_UE_PAI, ORDEN_PAI FROM fza_paises'
      'WHERE'
      '  CODIGO_PAI_PAI = :Old_CODIGO_PAI_PAI'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      'SELECT CODIGO_PAI_PAI, COD_ALPHA3_PAI, COD_ALPHA2_PAI, NOMBRE_SPA_PAI, NOMBRE_ENG_PAI, ESMIEMBRO_UE_PAI, ORDEN_PAI FROM fza_paises'
      'WHERE'
      '  CODIGO_PAI_PAI = :CODIGO_PAI_PAI')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_paises')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *  '
      'FROM fza_paises'
      '')
    Active = True
    Left = 16
  end
end
