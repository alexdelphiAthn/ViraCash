object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 653
  ClientWidth = 969
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = 'Source Sans 3'
  Font.Style = []
  OnShow = FormShow
  TextHeight = 18
  object Panel2: TPanel
    Left = 0
    Top = 57
    Width = 969
    Height = 596
    Align = alClient
    Caption = 'Panel2'
    TabOrder = 1
    object cxVerticalGrid1: TcxVerticalGrid
      Left = 1
      Top = 1
      Width = 967
      Height = 594
      Align = alClient
      OptionsView.RowHeaderWidth = 304
      TabOrder = 0
      Version = 1
      object cxVerticalGrid1EditorRow1: TcxEditorRow
        Properties.Caption = 'Permitir s'#243'lo art'#237'culos que existan'
        Properties.EditPropertiesClassName = 'TcxCheckBoxProperties'
        Properties.DataBinding.ValueType = 'Boolean'
        Properties.Value = True
        ID = 0
        ParentID = -1
        Index = 0
        Version = 1
      end
      object cxVerticalGrid1EditorRow2: TcxEditorRow
        Properties.Caption = 'Permitir s'#243'lo art'#237'culos con stock'
        Properties.EditPropertiesClassName = 'TcxCheckBoxProperties'
        Properties.Value = 'True'
        ID = 1
        ParentID = -1
        Index = 1
        Version = 1
      end
      object cxVerticalGrid1EditorRow3: TcxEditorRow
        Properties.Caption = 'Presentar selecci'#243'n de Caja'
        Properties.EditPropertiesClassName = 'TcxCheckBoxProperties'
        Properties.Value = 'True'
        ID = 2
        ParentID = -1
        Index = 2
        Version = 1
      end
      object cxVerticalGrid1EditorRow4: TcxEditorRow
        Properties.Caption = 'Mantener empleado por Defecto'
        Properties.EditPropertiesClassName = 'TcxCheckBoxProperties'
        Properties.Value = 'False'
        ID = 3
        ParentID = -1
        Index = 3
        Version = 1
      end
      object cxVerticalGrid1EditorRow5: TcxEditorRow
        Properties.Caption = 'Tarifa por defecto en Caja'
        Properties.EditPropertiesClassName = 'TcxTextEditProperties'
        Properties.EditProperties.Alignment.Horz = taCenter
        Properties.Value = 'PVP'
        ID = 4
        ParentID = -1
        Index = 4
        Version = 1
      end
      object cxVerticalGrid1EditorRow6: TcxEditorRow
        Properties.Caption = 'N'#250'mero de operaciones pendientes'
        Properties.EditPropertiesClassName = 'TcxSpinEditProperties'
        Properties.EditProperties.Alignment.Horz = taCenter
        Properties.Value = '5'
        ID = 5
        ParentID = -1
        Index = 5
        Version = 1
      end
      object cxVerticalGrid1EditorRow7: TcxEditorRow
        Properties.Caption = 'Pedir Referencia en devoluciones'
        Properties.DataBinding.ValueType = 'Boolean'
        Properties.Value = True
        ID = 6
        ParentID = -1
        Index = 6
        Version = 1
      end
      object cxVerticalGrid1EditorRow8: TcxEditorRow
        Properties.Value = Null
        ID = 7
        ParentID = -1
        Index = 7
        Version = 1
      end
      object cxVerticalGrid1EditorRow9: TcxEditorRow
        Properties.Value = Null
        ID = 8
        ParentID = -1
        Index = 8
        Version = 1
      end
      object cxVerticalGrid1EditorRow10: TcxEditorRow
        Properties.Value = Null
        ID = 9
        ParentID = -1
        Index = 9
        Version = 1
      end
      object cxVerticalGrid1EditorRow11: TcxEditorRow
        Properties.Value = Null
        ID = 10
        ParentID = -1
        Index = 10
        Version = 1
      end
      object cxVerticalGrid1EditorRow12: TcxEditorRow
        Properties.Value = Null
        ID = 11
        ParentID = -1
        Index = 11
        Version = 1
      end
      object cxVerticalGrid1EditorRow13: TcxEditorRow
        Properties.Value = Null
        ID = 12
        ParentID = -1
        Index = 12
        Version = 1
      end
      object cxVerticalGrid1EditorRow14: TcxEditorRow
        Properties.Value = Null
        ID = 13
        ParentID = -1
        Index = 13
        Version = 1
      end
      object cxVerticalGrid1EditorRow15: TcxEditorRow
        Properties.Value = Null
        ID = 14
        ParentID = -1
        Index = 14
        Version = 1
      end
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 969
    Height = 57
    Align = alTop
    TabOrder = 0
    object cxButtonEdit1: TcxButtonEdit
      Left = 21
      Top = 8
      Properties.Buttons = <
        item
          Default = True
          Glyph.SourceDPI = 96
          Glyph.Data = {
            3C3F786D6C2076657273696F6E3D22312E302220656E636F64696E673D225554
            462D38223F3E0D0A3C7376672076657273696F6E3D22312E31222069643D224C
            61796572312220786D6C6E733D22687474703A2F2F7777772E77332E6F72672F
            323030302F7376672220786D6C6E733A786C696E6B3D22687474703A2F2F7777
            772E77332E6F72672F313939392F786C696E6B2220783D223070782220793D22
            307078222076696577426F783D2230203020333220333222207374796C653D22
            656E61626C652D6261636B67726F756E643A6E6577203020302033322033323B
            2220786D6C3A73706163653D227072657365727665223E262331333B26233130
            3B20203C7374796C6520747970653D22746578742F6373732220786D6C3A7370
            6163653D227072657365727665223E2E426C61636B262331333B262331303B20
            2020207B262331333B262331303B20202020202066696C6C3A23373237323732
            3B262331333B262331303B202020202020666F6E742D66616D696C793A266170
            6F733B64782D666F6E742D69636F6E732661706F733B3B262331333B26233130
            3B202020202020666F6E742D73697A653A333270783B262331333B262331303B
            202020207D262331333B262331303B20203C2F7374796C653E0D0A3C74657874
            20783D22302220793D2233322220636C6173733D22426C61636B223EEF9E8B3C
            2F746578743E0D0A3C2F7376673E0D0A}
          Kind = bkGlyph
        end>
      Properties.OnButtonClick = cxButtonEdit1PropertiesButtonClick
      TabOrder = 0
      OnKeyDown = cxButtonEdit1KeyDown
      Width = 420
    end
  end
end
