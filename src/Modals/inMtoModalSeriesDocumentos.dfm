inherited frmModalSeriesDocumentos: TfrmModalSeriesDocumentos
  BorderStyle = bsDialog
  Caption = 'Añadir serie a todos'
  ClientHeight = 250
  ClientWidth = 500
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 19
  object pnlPrincipal: TPanel [0]
    Left = 0
    Top = 0
    Width = 500
    Height = 200
    Align = alClient
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 0
    object lblTitulo: TcxLabel
      Left = 16
      Top = 10
      Caption = 'Series de empresa (ubicaci'#243'n opcional)'
      Style.TextColor = clNavy
      Style.Font.Size = 10
      Style.Font.Style = [fsBold]
      TabOrder = 6
      Transparent = True
    end
    object lblAlmacen: TcxLabel
      Left = 16
      Top = 46
      Caption = 'Almac'#233'n (opcional)'
      TabOrder = 7
      Transparent = True
    end
    object cbbAlmacen: TcxLookupComboBox
      Left = 180
      Top = 44
      Properties.KeyFieldNames = 'CODIGO_ALM_ALM'
      Properties.ListColumns = <
        item
          Caption = 'C'#243'digo'
          Width = 70
          FieldName = 'CODIGO_ALM_ALM'
        end
        item
          Caption = 'Almac'#233'n'
          FieldName = 'NOMBRE_ALM_ALM'
        end>
      Properties.ListOptions.ShowHeader = False
      Properties.ListSource = dsAlmacenes
      Properties.OnEditValueChanged = cbbAlmacenPropertiesEditValueChanged
      TabOrder = 0
      Width = 300
    end
    object lblCaja: TcxLabel
      Left = 16
      Top = 82
      Caption = 'Caja (opcional)'
      TabOrder = 8
      Transparent = True
    end
    object cbbCaja: TcxLookupComboBox
      Left = 180
      Top = 80
      Properties.KeyFieldNames = 'CODIGO_CAJA_ALMCAJ'
      Properties.ListColumns = <
        item
          Caption = 'C'#243'digo'
          Width = 70
          FieldName = 'CODIGO_CAJA_ALMCAJ'
        end
        item
          Caption = 'Caja'
          FieldName = 'DESCRIPCION_ALMCAJ'
        end>
      Properties.ListOptions.ShowHeader = False
      Properties.ListSource = dsCajas
      TabOrder = 1
      Width = 300
    end
    object lblSerieTokenizada: TcxLabel
      Left = 16
      Top = 118
      Caption = 'Serie base'
      TabOrder = 9
      Transparent = True
    end
    object txtSerieTokenizada: TcxTextEdit
      Left = 180
      Top = 116
      Properties.MaxLength = 11
      TabOrder = 2
      Width = 180
    end
    object lblLeyendaTokens: TcxLabel
      Left = 16
      Top = 150
      Caption =
        'Tokens: yyyy = 2026 | yy = 26 | q = trimestre | mm = mes | dd = d'#237'a'
      Style.TextColor = clGrayText
      Style.Font.Size = 8
      TabOrder = 10
      Transparent = True
    end
    object lblLeyendaSubtipos: TcxLabel
      Left = 16
      Top = 174
      Caption =
        'Facturas: base simplificada | +N normal | +R rectificativa'
      Style.TextColor = clGrayText
      Style.Font.Size = 8
      TabOrder = 11
      Transparent = True
    end
  end
  object pnlBotones: TPanel [1]
    Left = 0
    Top = 200
    Width = 500
    Height = 50
    Align = alBottom
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 1
    object btnAceptar: TcxButton
      Left = 218
      Top = 8
      Width = 130
      Height = 35
      Action = actAceptar
      Default = True
      TabOrder = 0
    end
    object btnCancelar: TcxButton
      Left = 356
      Top = 8
      Width = 130
      Height = 35
      Action = actCancelar
      Cancel = True
      TabOrder = 1
    end
  end
  object alAcciones: TActionList
    Left = 16
    Top = 208
    object actAceptar: TAction
      Caption = 'Aceptar (F12)'
      ShortCut = 123
      OnExecute = actAceptarExecute
    end
    object actCancelar: TAction
      Caption = 'Cancelar (ESC)'
      ShortCut = 27
      OnExecute = actCancelarExecute
    end
  end
  object dsAlmacenes: TDataSource
    Left = 96
    Top = 168
  end
  object dsCajas: TDataSource
    Left = 384
    Top = 168
  end
end
