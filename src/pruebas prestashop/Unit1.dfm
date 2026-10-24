object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 371
  ClientWidth = 871
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = 'Source Sans 3'
  Font.Style = []
  TextHeight = 13
  object spl1: TSplitter
    Left = 868
    Top = 0
    Height = 371
    Align = alRight
    Beveled = True
    ExplicitLeft = 408
    ExplicitTop = 128
    ExplicitHeight = 100
  end
  object pnl1: TPanel
    Left = 573
    Top = 0
    Width = 295
    Height = 371
    Align = alClient
    Caption = 'pnl1'
    TabOrder = 0
    ExplicitWidth = 291
    ExplicitHeight = 370
    object tlb1: TToolBar
      Left = 1
      Top = 327
      Width = 293
      Height = 43
      Align = alBottom
      ButtonHeight = 40
      Caption = 'tlb1'
      TabOrder = 0
      ExplicitTop = 326
      ExplicitWidth = 289
      object btnInsert: TButton
        Left = 0
        Top = 0
        Width = 97
        Height = 40
        Caption = 'Insertar POST'
        TabOrder = 1
        OnClick = btnInsertClick
      end
      object btnUpdate: TButton
        Left = 97
        Top = 0
        Width = 96
        Height = 40
        Caption = 'Update PUT'
        TabOrder = 2
        OnClick = btnUpdateClick
      end
      object btnDelete: TButton
        Left = 193
        Top = 0
        Width = 100
        Height = 40
        Caption = 'Delete DELETE'
        TabOrder = 0
        OnClick = btnDeleteClick
      end
    end
    object PageControl1: TPageControl
      Left = 1
      Top = 1
      Width = 293
      Height = 326
      ActivePage = TabSheet1
      Align = alClient
      TabOrder = 1
      ExplicitWidth = 289
      ExplicitHeight = 325
      object TabSheet1: TTabSheet
        Caption = 'XML Mode'
        object m1: TSynEdit
          Left = 0
          Top = 0
          Width = 285
          Height = 298
          Align = alClient
          Color = clAqua
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Consolas'
          Font.Style = []
          Font.Quality = fqClearTypeNatural
          TabOrder = 0
          UseCodeFolding = False
          BorderStyle = bsNone
          Gutter.Font.Charset = DEFAULT_CHARSET
          Gutter.Font.Color = clWindowText
          Gutter.Font.Height = -11
          Gutter.Font.Name = 'Consolas'
          Gutter.Font.Style = []
          Gutter.Bands = <
            item
              Kind = gbkMarks
              Width = 13
            end
            item
              Kind = gbkLineNumbers
            end
            item
              Kind = gbkFold
            end
            item
              Kind = gbkTrackChanges
            end
            item
              Kind = gbkMargin
              Width = 3
            end>
          Highlighter = SynXMLSyn1
          Options = [eoAltSetsColumnMode, eoAutoIndent,
            eoDisableScrollArrows, eoDragDropEditing, eoDropFiles,
            eoEnhanceHomeKey, eoEnhanceEndKey, eoGroupUndo,
            eoHideShowScrollbars, eoKeepCaretX, eoShowScrollHint,
            eoSmartTabDelete, eoSmartTabs, eoTabIndent, eoTabsToSpaces,
            eoShowLigatures]
          ReadOnly = True
          SelectedColor.Background = clAqua
          SelectedColor.Foreground = clSilver
          SelectedColor.Alpha = 0.400000005960464500
          SelectionMode = smLine
          WordWrap = True
          ExplicitWidth = 281
          ExplicitHeight = 297
        end
      end
      object TabSheet2: TTabSheet
        Caption = 'Grid Mode'
        ImageIndex = 1
        object PageControl2: TPageControl
          Left = 0
          Top = 0
          Width = 285
          Height = 298
          ActivePage = TabSheet4
          Align = alClient
          TabOrder = 0
          object Cliente: TTabSheet
            Caption = 'Cliente'
            object DBGrid1: TDBGrid
              Left = 0
              Top = 0
              Width = 277
              Height = 270
              Align = alClient
              TabOrder = 0
              TitleFont.Charset = DEFAULT_CHARSET
              TitleFont.Color = clWindowText
              TitleFont.Height = -15
              TitleFont.Name = 'Source Sans 3'
              TitleFont.Style = []
            end
          end
          object TabSheet3: TTabSheet
            Caption = 'Pedidos'
            ImageIndex = 1
            object DBGrid2: TDBGrid
              Left = 0
              Top = 0
              Width = 277
              Height = 270
              Align = alClient
              TabOrder = 0
              TitleFont.Charset = DEFAULT_CHARSET
              TitleFont.Color = clWindowText
              TitleFont.Height = -15
              TitleFont.Name = 'Source Sans 3'
              TitleFont.Style = []
            end
          end
          object TabSheet4: TTabSheet
            Caption = 'Lineas de Pedidos'
            ImageIndex = 2
            object DBGrid3: TDBGrid
              Left = 0
              Top = 0
              Width = 277
              Height = 270
              Align = alClient
              TabOrder = 0
              TitleFont.Charset = DEFAULT_CHARSET
              TitleFont.Color = clWindowText
              TitleFont.Height = -15
              TitleFont.Name = 'Source Sans 3'
              TitleFont.Style = []
            end
          end
        end
      end
    end
  end
  object pnl2: TPanel
    Left = 0
    Top = 0
    Width = 573
    Height = 371
    Align = alLeft
    TabOrder = 1
    ExplicitHeight = 370
    object lbl1: TLabel
      Left = 24
      Top = 9
      Width = 161
      Height = 13
      Caption = 'URL base de la tienda prestashop'
    end
    object lbl2: TLabel
      Left = 24
      Top = 54
      Width = 101
      Height = 13
      Caption = 'Clave del webservice'
    end
    object lbl3: TLabel
      Left = 24
      Top = 100
      Width = 29
      Height = 13
      Caption = 'Filtros'
    end
    object btnXMLMaster: TButton
      Left = 136
      Top = 335
      Width = 57
      Height = 25
      Caption = 'Leer GET'
      TabOrder = 0
      OnClick = btnXMLMasterClick
    end
    object edtBaseURL: TEdit
      Left = 24
      Top = 27
      Width = 433
      Height = 21
      TabOrder = 1
      Text = 'https://alejandrolaorden.averok.com/api'
    end
    object lstCategory: TListBox
      Left = 136
      Top = 160
      Width = 129
      Height = 161
      ItemHeight = 13
      Items.Strings = (
        'addresses'
        'carriers'
        'cart_rules'
        'carts'
        'categories'
        'combinations'
        'configurations'
        'contacts'
        'content_management_system'
        'countries'
        'currencies'
        'customer_messages'
        'customer_threads'
        'customers'
        'customizations'
        'deliveries'
        'employees'
        'groups'
        'guests'
        'image_types'
        'images'
        'languages'
        'manufacturers'
        'messages'
        'order_carriers'
        'order_details'
        'order_histories'
        'order_invoices'
        'order_payments'
        'order_slip'
        'order_states'
        'orders'
        'price_ranges'
        'product_customization_fields'
        'product_feature_values'
        'product_features'
        'product_option_values'
        'product_options'
        'product_suppliers'
        'products'
        'search'
        'shop_groups'
        'shop_urls'
        'shops'
        'specific_price_rules'
        'specific_prices'
        'states'
        'stock_availables'
        'stock_movement_reasons'
        'stock_movements'
        'stocks'
        'stores'
        'suppliers'
        'supply_order_details'
        'supply_order_histories'
        'supply_order_receipt_histories'
        'supply_order_states'
        'supply_orders'
        'tags'
        'tax_rule_groups'
        'tax_rules'
        'taxes'
        'translated_configurations'
        'warehouse_product_locations'
        'warehouses'
        'weight_ranges'
        'zones')
      TabOrder = 2
    end
    object btnDetail: TButton
      Left = 216
      Top = 335
      Width = 49
      Height = 25
      Caption = 'Detalle'
      TabOrder = 3
      OnClick = btnDetailClick
    end
    object btnXMLDetail: TButton
      Left = 288
      Top = 335
      Width = 73
      Height = 25
      Caption = 'Leer GET'
      TabOrder = 4
      OnClick = btnXMLDetailClick
    end
    object btnSchema: TButton
      Left = 448
      Top = 334
      Width = 119
      Height = 25
      Caption = 'Leer esquema vac'#237'o'
      TabOrder = 5
      OnClick = btnSchemaClick
    end
    object edtFiltros: TEdit
      Left = 24
      Top = 114
      Width = 433
      Height = 21
      TabOrder = 6
      Text = '/customers/?display=[firstname,lastname]'
    end
    object btnGetGeneral: TButton
      Left = 463
      Top = 25
      Width = 57
      Height = 25
      Caption = 'Leer GET'
      TabOrder = 7
      OnClick = btnGetGeneralClick
    end
    object btnFiltros: TButton
      Left = 463
      Top = 112
      Width = 57
      Height = 25
      Caption = 'Leer GET'
      TabOrder = 8
      OnClick = btnFiltrosClick
    end
    object btReadOrders: TButton
      Left = 404
      Top = 249
      Width = 126
      Height = 25
      Caption = 'Leer Pedidos y Clientes'
      TabOrder = 9
      OnClick = btReadOrdersClick
    end
    object txtId: TEdit
      Left = 536
      Top = 251
      Width = 31
      Height = 21
      TabOrder = 10
      Text = '7'
    end
  end
  object edtKey: TEdit
    Left = 24
    Top = 73
    Width = 473
    Height = 21
    TabOrder = 2
  end
  object lstDetail: TListBox
    Left = 288
    Top = 160
    Width = 73
    Height = 161
    ItemHeight = 13
    TabOrder = 3
  end
  object rstclnt1: TRESTClient
    Authenticator = htpbscthntctr1
    Accept = 'application/json, text/plain, text/xml; q=0.9, text/html;q=0.8,'
    AcceptCharset = 'ISO-8859-1, *;q=0.8'
    ContentType = 'text/xml'
    Params = <
      item
        Kind = pkHTTPHEADER
        Name = 'Output-Format'
        Value = 'text/xml'
      end
      item
        Kind = pkHTTPHEADER
        Name = 'Io-Format'
        Value = 'text/xml'
      end>
    SecureProtocols = [SSL2, SSL3, TLS1, TLS11, TLS12]
    SynchronizedEvents = False
    Left = 696
    Top = 272
  end
  object rstrqst1: TRESTRequest
    Client = rstclnt1
    Params = <
      item
        Kind = pkHTTPHEADER
        Name = 'Output-Format'
        Value = 'text/xml'
      end
      item
        Kind = pkHTTPHEADER
        Name = 'Io-Format'
        Value = 'text/xml'
      end>
    Response = rstrspns1
    SynchronizedEvents = False
    Left = 760
    Top = 272
  end
  object rstrspns1: TRESTResponse
    Left = 624
    Top = 272
  end
  object htpbscthntctr1: THTTPBasicAuthenticator
    Left = 816
    Top = 280
  end
  object SynXMLSyn1: TSynXMLSyn
    AttributeAttri.Foreground = clBlack
    WantBracesParsed = False
    Left = 824
    Top = 216
  end
  object cdsCli: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 416
    Top = 176
  end
  object cdsPed: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 488
    Top = 168
  end
  object cdsLinPed: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 456
    Top = 168
  end
end
