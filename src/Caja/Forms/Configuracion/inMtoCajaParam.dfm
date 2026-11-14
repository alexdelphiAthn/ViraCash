inherited frmMtoCajaParam: TfrmMtoCajaParam
  Left = 0
  Top = 0
  Caption = 'Par'#225'metros de Caja'
  ClientHeight = 637
  ClientWidth = 743
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -16
  Font.Name = 'Source Sans 3'
  Font.Style = []
  KeyPreview = True
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnShow = FormShow
  TextHeight = 18
  object Panel2: TPanel
    Left = 0
    Top = 57
    Width = 743
    Height = 580
    Align = alClient
    TabOrder = 1
    ExplicitWidth = 741
    ExplicitHeight = 572
    object JvInspector1: TJvInspector
      Left = 1
      Top = 1
      Width = 741
      Height = 578
      Style = isItemPainter
      Align = alClient
      BevelKind = bkSoft
      BevelOuter = bvRaised
      Divider = 300
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Source Sans 3'
      Font.Style = []
      ItemHeight = 23
      Painter = JvInspectorDotNETPainter1
      TabStop = True
      TabOrder = 0
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 743
    Height = 57
    Align = alTop
    TabOrder = 0
    ExplicitWidth = 741
    object edtBusqueda: TcxButtonEdit
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
      OnKeyDown = edtBusquedaKeyDown
      Width = 292
    end
    object cmbGrupoUsuario: TcxComboBox
      Left = 496
      Top = 15
      Properties.ReadOnly = False
      Properties.OnChange = cmbGrupoUsuarioPropertiesChange
      TabOrder = 1
      Width = 176
    end
    object btnGuardar: TcxButton
      Left = 319
      Top = 15
      Width = 154
      Height = 26
      Caption = '&Guardar (F12)'
      TabOrder = 2
      OnClick = btnGuardarClick
    end
    object btnChangeId: TcxButton
      Left = 689
      Top = 0
      Width = 58
      Height = 57
      OptionsImage.Glyph.SourceDPI = 96
      OptionsImage.Glyph.Data = {
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
        20783D22302220793D2233322220636C6173733D22426C61636B223EEEA38F3C
        2F746578743E0D0A3C2F7376673E0D0A}
      TabOrder = 3
      OnClick = btnChangeIdClick
    end
  end
  object JvInspectorDotNETPainter1: TJvInspectorDotNETPainter
    CategoryFont.Charset = DEFAULT_CHARSET
    CategoryFont.Color = clBtnText
    CategoryFont.Height = -16
    CategoryFont.Name = 'Source Sans 3'
    CategoryFont.Style = []
    NameFont.Charset = DEFAULT_CHARSET
    NameFont.Color = clWindowText
    NameFont.Height = -16
    NameFont.Name = 'Source Sans 3'
    NameFont.Style = []
    ValueFont.Charset = DEFAULT_CHARSET
    ValueFont.Color = clWindowText
    ValueFont.Height = -16
    ValueFont.Name = 'Source Sans 3'
    ValueFont.Style = []
    DrawNameEndEllipsis = False
    HideSelectFont.Charset = DEFAULT_CHARSET
    HideSelectFont.Color = clHighlightText
    HideSelectFont.Height = -16
    HideSelectFont.Name = 'Segoe UI'
    HideSelectFont.Style = []
    SelectedFont.Charset = DEFAULT_CHARSET
    SelectedFont.Color = clHighlightText
    SelectedFont.Height = -16
    SelectedFont.Name = 'Segoe UI'
    SelectedFont.Style = []
    Left = 368
    Top = 328
  end
  object ActionList1: TActionList
    Left = 608
    Top = 104
    object actGuardar: TAction
      Caption = 'actGuardar'
      ShortCut = 123
      OnExecute = actGuardarExecute
    end
    object actSalir: TAction
      Caption = 'actSalir'
      ShortCut = 27
      OnExecute = actSalirExecute
    end
    object actGuardarLayout: TAction
      Caption = 'Guardar Layout'
      ShortCut = 32891
      OnExecute = actGuardarLayoutExecute
    end
  end
end
