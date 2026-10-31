inherited dmAlmacenes: TdmAlmacenes
  Height = 214
  Width = 534
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_almacenes'
      
        '  (CODIGO_ALM_ALM, CODIGO_EMP_ALM, ESACTIVO_ALM, ESWEB_ALM, NOMBRE_ALM_ALM, CODIGO_PADRE_ALM, ESFISICO_ALM, TIPO_USO_ALM, ESCOMPARTIDO_ALM, DIRECCION_ALM, POBLACION_ALM, CODIGO_POSTAL_ALM, TELEFONO_ALM, EMAIL_ALM, CODIGO_CLI_ALM,' +
        ' DESTINO_ACTUAL_ALM, ORIGEN_ACTUAL_ALM, ORDEN_ALM, INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF)'
      'VALUES'
      
        '  (:CODIGO_ALM_ALM, :CODIGO_EMP_ALM, :ESACTIVO_ALM, :ESWEB_ALM, :NOMBRE_ALM_ALM, :CODIGO_PADRE_ALM, :ESFISICO_ALM, :TIPO_USO_ALM, :ESCOMPARTIDO_ALM, :DIRECCION_ALM, :POBLACION_ALM, :CODIGO_POSTAL_ALM, :TELEFONO_ALM, :EMAIL_ALM, :CO' +
        'DIGO_CLI_ALM, :DESTINO_ACTUAL_ALM, :ORIGEN_ACTUAL_ALM, :ORDEN_ALM, :INSTANTE_MODIF, :INSTANTE_ALTA, :USUARIO_ALTA, :USUARIO_MODIF)')
    SQLDelete.Strings = (
      'DELETE FROM fza_almacenes'
      'WHERE'
      '  CODIGO_ALM_ALM = :Old_CODIGO_ALM_ALM')
    SQLUpdate.Strings = (
      'UPDATE fza_almacenes'
      'SET'
      
        '  CODIGO_ALM_ALM = :CODIGO_ALM_ALM, CODIGO_EMP_ALM = :CODIGO_EMP_ALM, ESACTIVO_ALM = :ESACTIVO_ALM, ESWEB_ALM = :ESWEB_ALM, NOMBRE_ALM_ALM = :NOMBRE_ALM_ALM, CODIGO_PADRE_ALM = :CODIGO_PADRE_ALM, ESFISICO_ALM = :ESFISICO_ALM' +
        ', TIPO_USO_ALM = :TIPO_USO_ALM, ESCOMPARTIDO_ALM = :ESCOMPARTIDO_ALM, DIRECCION_ALM = :DIRECCION_ALM, POBLACION_ALM = :POBLACION_ALM, CODIGO_POSTAL_ALM = :CODIGO_POSTAL_ALM, TELEFONO_ALM = :TELEFONO_ALM, EMAIL_ALM = :EMAIL_ALM, CODIGO_CLI' +
        '_ALM = :CODIGO_CLI_ALM, DESTINO_ACTUAL_ALM = :DESTINO_ACTUAL_ALM, ORIGEN_ACTUAL_ALM = :ORIGEN_ACTUAL_ALM, ORDEN_ALM = :ORDEN_ALM, INSTANTE_MODIF = :INSTANTE_MODIF, INSTANTE_ALTA = :INSTANTE_ALTA, USUA' +
        'RIO_ALTA = :USUARIO_ALTA, USUARIO_MODIF = :USUARIO_MODIF'
      'WHERE'
      '  CODIGO_ALM_ALM = :Old_CODIGO_ALM_ALM')
    SQLLock.Strings = (
      
        'SELECT CODIGO_ALM_ALM, CODIGO_EMP_ALM, ESACTIVO_ALM, ESWEB_ALM, NOMBRE_ALM_ALM, CODIGO_PADRE_ALM, ESFISICO_ALM, TIPO_USO_ALM, ESCOMPARTIDO_ALM, DIRECCION_ALM, POBLACION_ALM, CODIGO_POSTAL_ALM, TELEFONO_ALM, EMAIL_ALM, CODIGO_CLI_' +
        'ALM, DESTINO_ACTUAL_ALM, ORIGEN_ACTUAL_ALM, ORDEN_ALM, INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF FROM fza_almacenes'
      'WHERE'
      '  CODIGO_ALM_ALM = :Old_CODIGO_ALM_ALM'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT CODIGO_ALM_ALM, CODIGO_EMP_ALM, ESACTIVO_ALM, ESWEB_ALM, NOMBRE_ALM_ALM, CODIGO_PADRE_ALM, ESFISICO_ALM, TIPO_USO_ALM, ESCOMPARTIDO_ALM, DIRECCION_ALM, POBLACION_ALM, CODIGO_POSTAL_ALM, TELEFONO_ALM, EMAIL_ALM, CODIGO_CLI_' +
        'ALM, DESTINO_ACTUAL_ALM, ORIGEN_ACTUAL_ALM, ORDEN_ALM, INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF FROM fza_almacenes'
      'WHERE'
      '  CODIGO_ALM_ALM = :CODIGO_ALM_ALM')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_almacenes')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *  '
      'FROM fza_almacenes'
      '')
    Active = True
    KeyFields = 'CODIGO_ALM_ALM'
    AfterCancel = unqryTablaGAfterCancel
    AfterInsert = unqryTablaGAfterInsert
    AfterPost = unqryTablaGAfterPost
    BeforeDelete = unqryTablaGBeforeDelete
    AfterDelete = unqryTablaGAfterDelete
    BeforePost = unqryTablaGBeforePost
    Left = 16
  end
  object qryAlmacenesCajas: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_almacenes_cajas'
      
        '  (CODIGO_ALM_ALMCAJ, CODIGO_CAJA_ALMCAJ, DESCRIPCION_ALMCAJ)'
      'VALUES'
      
        '  (:CODIGO_ALM_ALMCAJ, :CODIGO_CAJA_ALMCAJ, :DESCRIPCION_ALMCAJ)')
    SQLDelete.Strings = (
      'DELETE FROM fza_almacenes_cajas'
      'WHERE'
      
        '  CODIGO_ALM_ALMCAJ = :Old_CODIGO_ALM_ALMCAJ AND CODIGO_CAJA_ALMCAJ = :Old_CODIGO_CAJA_ALMCAJ')
    SQLUpdate.Strings = (
      'UPDATE fza_almacenes_cajas'
      'SET'
      
        '  CODIGO_ALM_ALMCAJ = :CODIGO_ALM_ALMCAJ, CODIGO_CAJA_ALMCAJ = :CODIGO_CAJA_ALMCAJ, DESCRIPCION_ALMCAJ = :DESCRIPCION_ALMCAJ'
      'WHERE'
      
        '  CODIGO_ALM_ALMCAJ = :Old_CODIGO_ALM_ALMCAJ AND CODIGO_CAJA_ALMCAJ = :Old_CODIGO_CAJA_ALMCAJ')
    SQLLock.Strings = (
      
        'SELECT CODIGO_ALM_ALMCAJ, CODIGO_CAJA_ALMCAJ, DESCRIPCION_ALMCAJ FROM fza_almacenes_cajas'
      'WHERE'
      
        '  CODIGO_ALM_ALMCAJ = :Old_CODIGO_ALM_ALMCAJ AND CODIGO_CAJA_ALMCAJ = :Old_CODIGO_CAJA_ALMCAJ'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT CODIGO_ALM_ALMCAJ, CODIGO_CAJA_ALMCAJ, DESCRIPCION_ALMCAJ FROM fza_almacenes_cajas'
      'WHERE'
      
        '  CODIGO_ALM_ALMCAJ = :CODIGO_ALM_ALMCAJ AND CODIGO_CAJA_ALMCAJ = :CODIGO_CAJA_ALMCAJ')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_almacenes_cajas')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *  '
      'FROM fza_almacenes_cajas'
      '')
    MasterSource = frmMtoAlmacenes.dsTablaG
    MasterFields = 'CODIGO_ALM_ALM'
    DetailFields = 'CODIGO_ALM_ALMCAJ'
    Active = True
    KeyFields = 'CODIGO_ALM_ALMCAJ;CODIGO_CAJA_ALMCAJ'
    CachedUpdates = True
    Options.LocalMasterDetail = True
    BeforeEdit = qryAlmacenesCajasBeforeInsert
    BeforeDelete = qryAlmacenesCajasBeforeInsert
    BeforeInsert = qryAlmacenesCajasBeforeInsert
    BeforePost = unqryTablaGBeforePost
    Left = 256
    Top = 30
    ParamData = <
      item
        DataType = ftWideString
        Name = 'CODIGO_ALM_ALM'
        ParamType = ptInput
        Value = 'BCN'
      end>
  end
  object dsAlmacenesCajas: TDataSource
    DataSet = qryAlmacenesCajas
    Left = 256
    Top = 108
  end
  object qryAlmacenesLookup: TUniQuery
    SQL.Strings = (
      'SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM, CODIGO_EMP_ALM,'
      '       ESACTIVO_ALM, TIPO_USO_ALM'
      '  FROM fza_almacenes'
      ' ORDER BY CASE WHEN ESACTIVO_ALM = '#39'S'#39' THEN 0 ELSE 1 END,'
      '          CODIGO_ALM_ALM')
    ReadOnly = True
    Left = 376
    Top = 30
  end
  object dsAlmacenesLookup: TDataSource
    DataSet = qryAlmacenesLookup
    Left = 376
    Top = 108
  end
end
