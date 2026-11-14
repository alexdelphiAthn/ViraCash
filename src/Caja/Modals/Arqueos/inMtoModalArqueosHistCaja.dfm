inherited frmModalArqueosHistCaja: TfrmModalArqueosHistCaja
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Hist'#243'rico de Arqueos'
  ClientHeight = 520
  ClientWidth = 980
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = 'Source Sans 3'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  TextHeight = 19
  object pnlPrincipal: TPanel
    Left = 0
    Top = 0
    Width = 980
    Height = 520
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object pnlSuperior: TPanel
      Left = 0
      Top = 0
      Width = 980
      Height = 56
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
      object lblTitulo: TcxLabel
        Left = 12
        Top = 8
        Caption = 'Hist'#243'rico de Arqueos'
        Style.Font.Charset = DEFAULT_CHARSET
        Style.Font.Color = clWindowText
        Style.Font.Height = -19
        Style.Font.Name = 'Source Sans 3'
        Style.Font.Style = [fsBold]
        Style.IsFontAssigned = True
        Transparent = True
      end
      object lblAyuda: TcxLabel
        Left = 13
        Top = 33
        Caption = 'F2 = Duplicado ticket    F3 = Duplicado cierre    ESC = Salir'
        Transparent = True
      end
    end
    object cxgrdArqueos: TcxGrid
      Left = 0
      Top = 56
      Width = 980
      Height = 404
      Align = alClient
      TabOrder = 1
      object dbtvArqueos: TcxGridDBTableView
        OnDblClick = dbtvArqueosDblClick
        DataController.DataSource = dsArqueos
        DataController.KeyFieldNames = 'CODIGO_ARQ'
        OptionsBehavior.FocusCellOnTab = True
        OptionsData.Editing = False
        OptionsSelection.CellSelect = False
        object colCodigo: TcxGridDBColumn
          Caption = 'C'#243'digo'
          DataBinding.FieldName = 'CODIGO_ARQ'
          Options.Editing = False
          Width = 130
        end
        object colDesde: TcxGridDBColumn
          Caption = 'Desde'
          DataBinding.FieldName = 'FECHA_DESDE_ARQ'
          Options.Editing = False
          PropertiesClassName = 'TcxDateEditProperties'
          Properties.DisplayFormat = 'dd/mm/yyyy hh:nn'
          Width = 125
        end
        object colHasta: TcxGridDBColumn
          Caption = 'Hasta'
          DataBinding.FieldName = 'FECHA_HASTA_ARQ'
          Options.Editing = False
          PropertiesClassName = 'TcxDateEditProperties'
          Properties.DisplayFormat = 'dd/mm/yyyy hh:nn'
          Width = 125
        end
        object colFase: TcxGridDBColumn
          Caption = 'Fase'
          DataBinding.FieldName = 'FASE_ARQ'
          Options.Editing = False
          Width = 80
        end
        object colVentas: TcxGridDBColumn
          Caption = 'Ventas'
          DataBinding.FieldName = 'CANTIDAD_VENTAS_ARQ'
          Options.Editing = False
          Width = 70
        end
        object colTotalVentas: TcxGridDBColumn
          Caption = 'Total Ventas'
          DataBinding.FieldName = 'TOTAL_VENTAS_ARQ'
          PropertiesClassName = 'TcxCurrencyEditProperties'
          Options.Editing = False
          Width = 110
        end
        object colEfectivo: TcxGridDBColumn
          Caption = 'Efectivo Caja'
          DataBinding.FieldName = 'TOTAL_EFECTIVO_CAJA_ARQ'
          PropertiesClassName = 'TcxCurrencyEditProperties'
          Options.Editing = False
          Width = 110
        end
        object colRecuento: TcxGridDBColumn
          Caption = 'Recuento'
          DataBinding.FieldName = 'TOTAL_RECUENTO_ARQ'
          PropertiesClassName = 'TcxCurrencyEditProperties'
          Options.Editing = False
          Width = 110
        end
        object colDiferencia: TcxGridDBColumn
          Caption = 'Diferencia'
          DataBinding.FieldName = 'DIFERENCIA_TOTAL_ARQ'
          PropertiesClassName = 'TcxCurrencyEditProperties'
          Options.Editing = False
          Width = 100
        end
        object colUsuario: TcxGridDBColumn
          Caption = 'Usuario'
          DataBinding.FieldName = 'USUARIO_ALTA'
          Options.Editing = False
          Width = 110
        end
      end
      object cxgrdlvlArqueos: TcxGridLevel
        GridView = dbtvArqueos
      end
    end
    object pnlBotones: TPanel
      Left = 0
      Top = 460
      Width = 980
      Height = 60
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 2
      object btnDupTicket: TcxButton
        Left = 360
        Top = 12
        Width = 190
        Height = 36
        Caption = 'Duplicado ticket (F2)'
        TabOrder = 0
        OnClick = btnDupTicketClick
      end
      object btnDupCierre: TcxButton
        Left = 560
        Top = 12
        Width = 190
        Height = 36
        Caption = 'Duplicado cierre (F3)'
        TabOrder = 1
        OnClick = btnDupCierreClick
      end
      object btnSalir: TcxButton
        Left = 800
        Top = 12
        Width = 160
        Height = 36
        Cancel = True
        Caption = 'Salir (ESC)'
        TabOrder = 2
        OnClick = btnSalirClick
      end
    end
  end
  object dsArqueos: TDataSource
    Left = 120
    Top = 240
  end
end
