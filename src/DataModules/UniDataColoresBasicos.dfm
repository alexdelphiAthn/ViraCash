inherited dmColoresBasicos: TdmColoresBasicos
  inherited unqryTablaG: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_atributos_basicos'
      '  (ID_VA_ATB, CODIGO_ATB, NOMBRE_ATB, HEX_ATB, ORDEN_ATB,'
      '   ESACTIVO_ATB, INSTANTE_ALTA, INSTANTE_MODIF,'
      '   USUARIO_ALTA, USUARIO_MODIF)'
      'VALUES'
      '  (''CO'', :CODIGO_ATB, :NOMBRE_ATB, :HEX_ATB, :ORDEN_ATB,'
      '   :ESACTIVO_ATB, :INSTANTE_ALTA, :INSTANTE_MODIF,'
      '   :USUARIO_ALTA, :USUARIO_MODIF)')
    SQLUpdate.Strings = (
      'UPDATE fza_atributos_basicos'
      'SET NOMBRE_ATB = :NOMBRE_ATB, HEX_ATB = :HEX_ATB,'
      '    ORDEN_ATB = :ORDEN_ATB, ESACTIVO_ATB = :ESACTIVO_ATB,'
      '    INSTANTE_MODIF = :INSTANTE_MODIF,'
      '    USUARIO_MODIF = :USUARIO_MODIF'
      'WHERE ID_ATB = :Old_ID_ATB AND ID_VA_ATB = ''CO''')
    SQLRefresh.Strings = (
      'SELECT ID_ATB, ID_VA_ATB, CODIGO_ATB, NOMBRE_ATB, HEX_ATB,'
      '       ORDEN_ATB, ESACTIVO_ATB, INSTANTE_ALTA, INSTANTE_MODIF,'
      '       USUARIO_ALTA, USUARIO_MODIF'
      'FROM fza_atributos_basicos'
      'WHERE ID_ATB = :ID_ATB AND ID_VA_ATB = ''CO''')
    SQL.Strings = (
      'SELECT ID_ATB, ID_VA_ATB, CODIGO_ATB, NOMBRE_ATB, HEX_ATB,'
      '       ORDEN_ATB, ESACTIVO_ATB, INSTANTE_ALTA, INSTANTE_MODIF,'
      '       USUARIO_ALTA, USUARIO_MODIF'
      'FROM fza_atributos_basicos'
      'WHERE ID_VA_ATB = ''CO'''
      'ORDER BY ORDEN_ATB, NOMBRE_ATB, CODIGO_ATB')
    BeforeDelete = unqryTablaGBeforeDelete
    OnNewRecord = unqryTablaGNewRecord
  end
end
