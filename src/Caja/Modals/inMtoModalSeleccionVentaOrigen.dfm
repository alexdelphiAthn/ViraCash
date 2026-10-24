inherited frmModalSeleccionVentaOrigen: TfrmModalSeleccionVentaOrigen
  Caption = 'Seleccionar venta de origen de la devoluci'#243'n'
  ClientHeight = 480
  ClientWidth = 900
  Position = poScreenCenter
  StyleElements = [seFont, seClient, seBorder]
  OnShow = FormShow
  TextHeight = 17
  object pnlPrincipal: TPanel [0]
    Left = 0
    Top = 0
    Width = 900
    Height = 430
    Align = alClient
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 0
    object lblTitulo: TcxLabel
      Left = 16
      Top = 8
      Caption = 'Ventas que contienen el art'#237'culo'
      Style.TextColor = clNavy
      TabOrder = 1
      Transparent = True
    end
    object cxgrdVentas: TcxGrid
      Left = 0
      Top = 36
      Width = 900
      Height = 394
      Align = alBottom
      TabOrder = 0
      object dbtvVentas: TcxGridDBTableView
        OnDblClick = dbtvVentasDblClick
        DataController.DataSource = dsVentas
        OptionsBehavior.FocusCellOnTab = True
        OptionsBehavior.GoToNextCellOnEnter = True
        OptionsData.Deleting = False
        OptionsData.Editing = False
        OptionsData.Inserting = False
        OptionsSelection.CellSelect = False
        object colFecha: TcxGridDBColumn
          Caption = 'Fecha / hora'
          DataBinding.FieldName = 'FECHA'
          Width = 150
        end
        object colSerie: TcxGridDBColumn
          Caption = 'Serie'
          DataBinding.FieldName = 'SERIE_FAC'
          Width = 100
        end
        object colNumero: TcxGridDBColumn
          Caption = 'N'#250'mero'
          DataBinding.FieldName = 'NUMERO_FAC'
          Width = 100
        end
        object colAlmacen: TcxGridDBColumn
          Caption = 'Tienda'
          DataBinding.FieldName = 'CODIGO_ALM_FAC'
          Width = 90
        end
        object colCaja: TcxGridDBColumn
          Caption = 'Caja'
          DataBinding.FieldName = 'CODIGO_CAJA_FAC'
          Width = 70
        end
        object colUds: TcxGridDBColumn
          Caption = 'Uds.'
          DataBinding.FieldName = 'CANTIDAD'
          Width = 70
        end
        object colTotalLinea: TcxGridDBColumn
          Caption = 'Total art'#237'culo'
          DataBinding.FieldName = 'TOTAL_LINEA'
          Width = 110
        end
        object colTotalTicket: TcxGridDBColumn
          Caption = 'Total ticket'
          DataBinding.FieldName = 'TOTAL_TICKET'
          Width = 110
        end
      end
      object cxgrdlvlVentas: TcxGridLevel
        GridView = dbtvVentas
      end
    end
  end
  object pnlBotones: TPanel [1]
    Left = 0
    Top = 430
    Width = 900
    Height = 50
    Align = alBottom
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 1
    object btnAceptar: TcxButton
      Left = 560
      Top = 8
      Width = 160
      Height = 35
      Action = actAceptar
      Default = True
      TabOrder = 0
    end
    object btnCancelar: TcxButton
      Left = 730
      Top = 8
      Width = 160
      Height = 35
      Action = actCancelar
      Cancel = True
      TabOrder = 1
    end
  end
  object dsVentas: TDataSource
    Left = 24
    Top = 380
  end
  object alAcciones: TActionList
    Left = 80
    Top = 380
    object actAceptar: TAction
      Caption = 'Elegir venta (F12)'
      ShortCut = 123
      OnExecute = actAceptarExecute
    end
    object actCancelar: TAction
      Caption = 'Sin origen (ESC)'
      OnExecute = actCancelarExecute
    end
  end
end
