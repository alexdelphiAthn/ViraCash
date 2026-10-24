object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 442
  ClientWidth = 628
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = 'Source Sans 3'
  Font.Style = []
  TextHeight = 15
  object cxGrid1: TcxGrid
    Left = 0
    Top = 0
    Width = 628
    Height = 442
    Align = alClient
    TabOrder = 0
    ExplicitLeft = 192
    ExplicitTop = 144
    ExplicitWidth = 250
    ExplicitHeight = 200
    object cxGrid1DBTableView1: TcxGridDBTableView
      Navigator.Visible = True
      DataController.DataSource = DataSource1
      OptionsData.Appending = True
      OptionsView.ColumnAutoWidth = True
      OptionsView.GroupByBox = False
      object cxGrid1DBTableView1ClienteID: TcxGridDBColumn
        DataBinding.FieldName = 'ClienteID'
      end
      object cxGrid1DBTableView1Nombre: TcxGridDBColumn
        DataBinding.FieldName = 'Nombre'
        Width = 174
      end
      object cxGrid1DBTableView1Email: TcxGridDBColumn
        DataBinding.FieldName = 'Email'
        Width = 213
      end
      object cxGrid1DBTableView1DireccionID: TcxGridDBColumn
        DataBinding.FieldName = 'DireccionID'
        Width = 103
      end
      object cxGrid1DBTableView1Calle: TcxGridDBColumn
        DataBinding.FieldName = 'Calle'
        Width = 82
      end
      object cxGrid1DBTableView1Ciudad: TcxGridDBColumn
        DataBinding.FieldName = 'Ciudad'
        Width = 118
      end
    end
    object cxGrid1Level1: TcxGridLevel
      GridView = cxGrid1DBTableView1
    end
  end
  object UniQuery1: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO TablaCliente (ClienteID, Nombre, Email)'
      'VALUES (:ClienteID, :Nombre, :Email);'
      ''
      
        'INSERT INTO TablaDireccion (DireccionID, RefClienteID, Calle, Ciudad)'
      'VALUES (:DireccionID, :ClienteID, :Calle, :Ciudad);')
    SQLDelete.Strings = (
      '-- 1. Primero borramos el detalle (Hijo)'
      'DELETE FROM TablaDireccion'
      'WHERE DireccionID = :Old_DireccionID;'
      ''
      '-- 2. Luego borramos el maestro (Padre)'
      'DELETE FROM TablaCliente'
      'WHERE ClienteID = :Old_ClienteID;')
    SQLUpdate.Strings = (
      '-- Actualizamos la primera tabla'
      'UPDATE TablaCliente'
      'SET'
      '  Nombre = :Nombre,'
      '  Email = :Email'
      'WHERE'
      '  ClienteID = :Old_ClienteID;'
      ''
      '-- Actualizamos la segunda tabla'
      'UPDATE TablaDireccion'
      'SET'
      '  Calle = :Calle,'
      '  Ciudad = :Ciudad'
      'WHERE'
      '  DireccionID = :Old_DireccionID;')
    SQLLock.Strings = (
      '-- Bloqueamos ambas tablas seleccionando sus filas con bloqueo'
      'SELECT c.ClienteID, d.DireccionID '
      'FROM TablaCliente c'
      'INNER JOIN TablaDireccion d ON c.ClienteID = d.RefClienteID'
      'WHERE c.ClienteID = :Old_ClienteID'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      'SELECT '
      '    c.ClienteID,'
      '    c.Nombre,'
      '    c.Email,'
      '    d.DireccionID,'
      '    d.Calle,'
      '    d.Ciudad'
      'FROM TablaCliente c'
      'INNER JOIN TablaDireccion d ON c.ClienteID = d.RefClienteID'
      'WHERE c.ClienteID = :ClienteID')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM VistaClientes')
    Connection = UniConnection1
    SQL.Strings = (
      'select * from VistaClientes')
    Options.StrictUpdate = False
    Options.UpdateAllFields = True
    Active = False
    Left = 304
    Top = 224
  end
  object UniConnection1: TUniConnection
    ProviderName = 'MySQL'
    Port = 3306
    Database = 'prueba'
    Username = 'root'
    Server = '127.0.0.1'
    LoginPrompt = False
    Left = 432
    Top = 224
  end
  object MySQLUniProvider1: TMySQLUniProvider
    Left = 552
    Top = 224
  end
  object DataSource1: TDataSource
    DataSet = UniQuery1
    Left = 304
    Top = 312
  end
end
