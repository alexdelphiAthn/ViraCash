inherited dmIvas: TdmIvas
  Height = 159
  Width = 267
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_ivas'
      
        '  (CODIGO_IVA, IVA_IVAGRP, DESCRIPCION_IVA_IVAGRP, PORCENTAJE_EX' +
        'ENTO_IVA, PORCENTAJE_EXENTO_RE_IVA, PORCENTAJE_NORMAL_IVA, PORCE' +
        'NTAJE_NORMAL_RE_IVA, PORCENTAJE_REDUCIDO_IVA, PORCENTAJE_REDUCID' +
        'O_RE_IVA, PORCENTAJE_SUPERREDUCIDO_IVA, PORCENTAJE_SUPERREDUCIDO' +
        '_RE_IVA, FECHA_DESDE_IVA, FECHA_HASTA_IVA, INSTANTE_MODIF, INSTA' +
        'NTE_ALTA, USUARIO_ALTA, USUARIO_MODIF)'
      'VALUES'
      
        '  (:CODIGO_IVA, :IVA_IVAGRP, :DESCRIPCION_IVA_IVAGRP, :PORCENTAJ' +
        'E_EXENTO_IVA, :PORCENTAJE_EXENTO_RE_IVA, :PORCENTAJE_NORMAL_IVA,' +
        ' :PORCENTAJE_NORMAL_RE_IVA, :PORCENTAJE_REDUCIDO_IVA, :PORCENTAJ' +
        'E_REDUCIDO_RE_IVA, :PORCENTAJE_SUPERREDUCIDO_IVA, :PORCENTAJE_SU' +
        'PERREDUCIDO_RE_IVA, :FECHA_DESDE_IVA, :FECHA_HASTA_IVA, :INSTANT' +
        'E_MODIF, :INSTANTE_ALTA, :USUARIO_ALTA, :USUARIO_MODIF)')
    SQLDelete.Strings = (
      'DELETE FROM fza_ivas'
      'WHERE'
      '  CODIGO_IVA = :Old_CODIGO_IVA')
    SQLUpdate.Strings = (
      'UPDATE fza_ivas'
      'SET'
      
        '  CODIGO_IVA = :CODIGO_IVA, IVA_IVAGRP = :IVA_IVAGRP, DESCRIPCIO' +
        'N_IVA_IVAGRP = :DESCRIPCION_IVA_IVAGRP, PORCENTAJE_EXENTO_IVA = ' +
        ':PORCENTAJE_EXENTO_IVA, PORCENTAJE_EXENTO_RE_IVA = :PORCENTAJE_E' +
        'XENTO_RE_IVA, PORCENTAJE_NORMAL_IVA = :PORCENTAJE_NORMAL_IVA, PO' +
        'RCENTAJE_NORMAL_RE_IVA = :PORCENTAJE_NORMAL_RE_IVA, PORCENTAJE_R' +
        'EDUCIDO_IVA = :PORCENTAJE_REDUCIDO_IVA, PORCENTAJE_REDUCIDO_RE_I' +
        'VA = :PORCENTAJE_REDUCIDO_RE_IVA, PORCENTAJE_SUPERREDUCIDO_IVA =' +
        ' :PORCENTAJE_SUPERREDUCIDO_IVA, PORCENTAJE_SUPERREDUCIDO_RE_IVA ' +
        '= :PORCENTAJE_SUPERREDUCIDO_RE_IVA, FECHA_DESDE_IVA = :FECHA_DES' +
        'DE_IVA, FECHA_HASTA_IVA = :FECHA_HASTA_IVA, INSTANTE_MODIF = :IN' +
        'STANTE_MODIF, INSTANTE_ALTA = :INSTANTE_ALTA, USUARIO_ALTA = :US' +
        'UARIO_ALTA, USUARIO_MODIF = :USUARIO_MODIF'
      'WHERE'
      '  CODIGO_IVA = :Old_CODIGO_IVA')
    SQLLock.Strings = (
      'SELECT * FROM fza_ivas'
      'WHERE'
      '  CODIGO_IVA = :Old_CODIGO_IVA'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT CODIGO_IVA, IVA_IVAGRP, DESCRIPCION_IVA_IVAGRP, PORCENTAJ' +
        'E_EXENTO_IVA, PORCENTAJE_EXENTO_RE_IVA, PORCENTAJE_NORMAL_IVA, P' +
        'ORCENTAJE_NORMAL_RE_IVA, PORCENTAJE_REDUCIDO_IVA, PORCENTAJE_RED' +
        'UCIDO_RE_IVA, PORCENTAJE_SUPERREDUCIDO_IVA, PORCENTAJE_SUPERREDU' +
        'CIDO_RE_IVA, FECHA_DESDE_IVA, FECHA_HASTA_IVA, INSTANTE_MODIF, I' +
        'NSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF FROM fza_ivas'
      'WHERE'
      '  CODIGO_IVA = :CODIGO_IVA')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_ivas')
    Connection = dmConn.conUni
    SQL.Strings = (
      'select * from vi_ivas')
    Active = True
    AfterInsert = unqryTablaGAfterInsert
    AfterPost = unqryTablaGAfterPost
    BeforeDelete = unqryTablaGBeforeDelete
    AfterDelete = unqryTablaGAfterDelete
  end
  object unstrdprcContador: TUniStoredProc
    StoredProcName = 'PRC_GET_NEXT_CONT'
    SQL.Strings = (
      
        'CALL PRC_GET_NEXT_CONT(:pTipoDoc, :pUSUARIO_MODIF, @pcont); SELE' +
        'CT @pcont AS '#39'@pcont'#39)
    Connection = dmConn.conUni
    Left = 8
    Top = 84
    ParamData = <
      item
        DataType = ftWideString
        Name = 'pTipoDoc'
        ParamType = ptInput
        Size = 2
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pUSUARIO_MODIF'
        ParamType = ptInput
        Size = 100
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'pcont'
        ParamType = ptOutput
        Size = 20
        Value = nil
      end>
    CommandStoredProcName = 'PRC_GET_NEXT_CONT'
  end
  object unqryZonasIVA: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'select IVA_IVAGRP, DESCRIPCION_IVA_IVAGRP from fza_ivas_grupos')
    Active = True
    AfterInsert = unqryTablaGAfterInsert
    BeforePost = unqryTablaGBeforePost
    Left = 192
    Top = 24
  end
  object dsZonas: TDataSource
    DataSet = unqryZonasIVA
    Left = 192
    Top = 88
  end
end
