inherited dmProveedores: TdmProveedores
  Height = 260
  Width = 386
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'select * from fza_proveedores')
    AfterInsert = unqryTablaGAfterInsert
  end
  inherited unqryPerfiles: TUniQuery
    SQL.Strings = (
      'select * from fza_usuarios_perfiles '
      'where ( KEY_USUPER = '#39'frmMtoProveedores'#39' OR'
      '        KEY_USUPER = '#39'dmProveedores'#39
      '       )')
  end
  object unqryArticulos: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'select * from vi_proveedores_articulos')
    MasterFields = 'CODIGO_PRV_PRV'
    DetailFields = 'CODIGO_PRV_PRV'
    Left = 184
    Top = 24
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_PRV_PRV'
        ParamType = ptInput
        Value = '10'
      end>
  end
  object dsArticulos: TDataSource
    DataSet = unqryArticulos
    Left = 176
    Top = 80
  end
  object unqryLinFacturasArticulos: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_articulos_tarifas'
      
        '  (CODIGO_ART_ARTTAR, ESACTIVO_ARTTAR, PRECIOVENTA_IVAINCL_TARIF' +
        'A, PRECIOVENTA_SIVA_TARIFA, FECHA_DESDE_ARTTAR, FECHA_HASTA_ARTT' +
        'AR, INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF)'
      'VALUES'
      
        '  (:CODIGO_ART_ARTTAR, :ESACTIVO_ARTTAR, :PRECIOVENTA_IVAINCL_TA' +
        'RIFA, :PRECIOVENTA_SIVA_TARIFA, :FECHA_DESDE_ARTTAR, :FECHA_HAST' +
        'A_ARTTAR, :INSTANTE_MODIF, :INSTANTE_ALTA, :USUARIO_ALTA, :USUAR' +
        'IO_MODIF)')
    SQLDelete.Strings = (
      'DELETE FROM fza_articulos_tarifas'
      'WHERE'
      '  CODIGO_ART_ARTTAR = :Old_CODIGO_ART_ARTTAR')
    SQLUpdate.Strings = (
      'UPDATE fza_articulos_tarifas'
      'SET'
      
        '  CODIGO_ART_ARTTAR = :CODIGO_ART_ARTTAR, ESACTIVO_ARTTAR = :ESA' +
        'CTIVO_ARTTAR, PRECIOVENTA_IVAINCL_TARIFA = :PRECIOVENTA_IVAINCL_' +
        'TARIFA, PRECIOVENTA_SIVA_TARIFA = :PRECIOVENTA_SIVA_TARIFA, FECH' +
        'A_DESDE_ARTTAR = :FECHA_DESDE_ARTTAR, FECHA_HASTA_ARTTAR = :FECH' +
        'A_HASTA_ARTTAR, INSTANTE_MODIF = :INSTANTE_MODIF, INSTANTE_ALTA ' +
        '= :INSTANTE_ALTA, USUARIO_ALTA = :USUARIO_ALTA, USUARIO_MODIF = ' +
        ':USUARIO_MODIF'
      'WHERE'
      '  CODIGO_ART_ARTTAR = :Old_CODIGO_ART_ARTTAR')
    SQLLock.Strings = (
      'SELECT * FROM fza_articulos_tarifas'
      'WHERE'
      '  CODIGO_ART_ARTTAR = :Old_CODIGO_ART_ARTTAR'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT CODIGO_ART_ARTTAR, ESACTIVO_ARTTAR, PRECIOVENTA_IVAINCL_T' +
        'ARIFA, PRECIOVENTA_SIVA_TARIFA, FECHA_DESDE_ARTTAR, FECHA_HASTA_' +
        'ARTTAR, INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MOD' +
        'IF FROM fza_articulos_tarifas'
      'WHERE'
      '  CODIGO_ART_ARTTAR = :CODIGO_ART_ARTTAR')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_articulos_tarifas')
    Connection = dmConn.conUni
    SQL.Strings = (
      'select *'
      'from vi_fac_lin_busquedas'
      'INNER JOIN vi_articulos_proveedores '
      'ON vi_fac_lin_busquedas.CODIGO_ART_FACLIN = '
      '   vi_articulos_proveedores.CODIGO_ART_ART'
      'INNER JOIN vi_fac_busquedas'
      
        'ON vi_fac_lin_busquedas.NUMERO_FAC_FACLIN = vi_fac_busquedas.NUM' +
        'ERO_FAC'
      
        'AND vi_fac_lin_busquedas.SERIE_FAC_FACLIN = vi_fac_busquedas.SER' +
        'IE_FAC')
    MasterFields = 'CODIGO_PRV_PRV'
    DetailFields = 'CODIGO_PRV_PRV'
    Left = 297
    Top = 24
    ParamData = <
      item
        DataType = ftInteger
        Name = 'CODIGO_PRV_PRV'
        ParamType = ptInput
        Value = 3
      end>
  end
  object dsLinFacturasArticulos: TDataSource
    DataSet = unqryLinFacturasArticulos
    Left = 297
    Top = 80
  end
  object unqryConjuntosTallas: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT ID_AC, NOMBRE_AC'
      '  FROM fza_atributos_conjuntos'
      ' WHERE ESACTIVO_AC = '#39'S'#39
      '   AND ID_VA_AC IN (SELECT ID_ATB_VA'
      '     FROM VI_VARIACIONES_EJES WHERE EJE_VA = '#39'P'#39')'
      ' ORDER BY NOMBRE_AC')
    Left = 8
    Top = 24
  end
  object dsConjuntosTallas: TDataSource
    DataSet = unqryConjuntosTallas
    Left = 8
    Top = 52
  end
  object unqryKits: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM fza_proveedores_kits'
      'WHERE CODIGO_PRV_PRVKIT = :CODIGO_PRV_PRV'
      'ORDER BY ORDEN_PRVKIT, CODIGO_PRVKIT')
    MasterFields = 'CODIGO_PRV_PRV'
    DetailFields = 'CODIGO_PRV_PRVKIT'
    BeforeInsert = unqryKitsBeforeInsert
    AfterInsert = unqryKitsAfterInsert
    BeforePost = unqryKitsBeforePost
    BeforeDelete = unqryKitsBeforeDelete
    Left = 96
    Top = 24
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_PRV_PRV'
        ParamType = ptInput
        Value = nil
      end>
  end
  object dsKits: TDataSource
    DataSet = unqryKits
    Left = 96
    Top = 80
  end
  object unqryKitsDet: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM fza_proveedores_kits_det'
      'WHERE CODIGO_PRV_PRVKITD = :CODIGO_PRV_PRVKIT'
      '  AND CODIGO_PRVKIT_PRVKITD = :CODIGO_PRVKIT'
      'ORDER BY ORDEN_PRVKITD, VALOR_DESTINO_PRVKITD')
    MasterSource = dsKits
    MasterFields = 'CODIGO_PRV_PRVKIT;CODIGO_PRVKIT'
    DetailFields = 'CODIGO_PRV_PRVKITD;CODIGO_PRVKIT_PRVKITD'
    BeforeInsert = unqryKitsDetBeforeInsert
    AfterInsert = unqryKitsDetAfterInsert
    BeforePost = unqryKitsDetBeforePost
    Left = 96
    Top = 136
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_PRV_PRVKIT'
        ParamType = ptInput
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'CODIGO_PRVKIT'
        ParamType = ptInput
        Value = nil
      end>
  end
  object dsKitsDet: TDataSource
    DataSet = unqryKitsDet
    Left = 96
    Top = 192
  end
  object unqryFormaPago: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'select * from vi_formapago')
    ReadOnly = True
    Left = 280
    Top = 136
  end
  object dsFormasPago: TDataSource
    DataSet = unqryFormaPago
    Left = 280
    Top = 192
  end
  object unqryEmpresasBancos: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM vi_empresas_bancos'
      ' WHERE ESACTIVO_EMPBAN = '#39'S'#39
      ' ORDER BY CODIGO_EMP_EMPBAN, NOMBRE_EMPBAN')
    ReadOnly = True
    Left = 184
    Top = 136
  end
  object dsEmpresasBancos: TDataSource
    DataSet = unqryEmpresasBancos
    Left = 184
    Top = 192
  end
  object unqryPaises: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT CODIGO_PAI_PAI AS CODIGO, NOMBRE_SPA_PAI AS NOMBRE'
      ', COD_ALPHA2_PAI'
      'FROM fza_paises ORDER BY ORDEN_PAI, NOMBRE_SPA_PAI')
    ReadOnly = True
    Left = 32
    Top = 136
  end
  object dsPaises: TDataSource
    DataSet = unqryPaises
    Left = 32
    Top = 192
  end
end
