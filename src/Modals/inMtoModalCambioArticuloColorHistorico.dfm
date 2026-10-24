inherited frmModalHistoricoArtColor: TfrmModalHistoricoArtColor
  BorderStyle = bsSizeable
  Caption = 'Histórico de cambios de artículos y colores'
  ClientHeight = 560
  ClientWidth = 980
  Constraints.MinHeight = 420
  Constraints.MinWidth = 760
  Position = poScreenCenter
  OnCreate = FormCreate
  OnShow = FormShow
  TextHeight = 19
  object pnlSuperior: TPanel [0]
    Left = 0
    Top = 0
    Width = 980
    Height = 68
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblTitulo: TcxLabel
      Left = 16
      Top = 8
      Caption = 'Últimos cambios realizados'
      Style.Font.Charset = DEFAULT_CHARSET
      Style.Font.Color = clWindowText
      Style.Font.Height = -19
      Style.Font.Name = 'Source Sans 3'
      Style.Font.Style = [fsBold]
      Style.IsFontAssigned = True
      TabOrder = 0
      Transparent = True
    end
    object lblAyuda: TcxLabel
      Left = 16
      Top = 38
      Caption =
        'Incluye cambios, fusiones y reversiones completadas, del más ' +
        'reciente al más antiguo.'
      TabOrder = 1
      Transparent = True
    end
  end
  object cxgrdHistorico: TcxGrid [1]
    Left = 0
    Top = 68
    Width = 980
    Height = 434
    Align = alClient
    TabOrder = 1
    object tvHistorico: TcxGridTableView
      OptionsBehavior.FocusCellOnTab = True
      OptionsData.Deleting = False
      OptionsData.DeletingConfirmation = False
      OptionsData.Editing = False
      OptionsData.Inserting = False
      OptionsSelection.CellSelect = False
      OptionsView.GroupByBox = False
      OptionsView.Indicator = True
      object colInstante: TcxGridColumn
        Caption = 'Fecha y hora'
        PropertiesClassName = 'TcxDateEditProperties'
        Properties.DisplayFormat = 'dd/mm/yyyy hh:nn:ss'
        Options.Editing = False
        Width = 145
      end
      object colTipo: TcxGridColumn
        Caption = 'Operación'
        Options.Editing = False
        Width = 155
      end
      object colOrigen: TcxGridColumn
        Caption = 'Origen'
        Options.Editing = False
        Width = 170
      end
      object colDestino: TcxGridColumn
        Caption = 'Destino'
        Options.Editing = False
        Width = 170
      end
      object colUnidades: TcxGridColumn
        Caption = 'Unidades'
        HeaderAlignmentHorz = taRightJustify
        Options.Editing = False
        Width = 75
      end
      object colUsuario: TcxGridColumn
        Caption = 'Usuario'
        Options.Editing = False
        Width = 120
      end
      object colEstado: TcxGridColumn
        Caption = 'Estado'
        Options.Editing = False
        Width = 90
      end
    end
    object cxgrdlvlHistorico: TcxGridLevel
      GridView = tvHistorico
    end
  end
  object pnlBotones: TPanel [2]
    Left = 0
    Top = 502
    Width = 980
    Height = 58
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object lblResultado: TcxLabel
      Left = 16
      Top = 19
      Caption = 'No hay cambios registrados.'
      TabOrder = 1
      Transparent = True
    end
    object btnCerrar: TcxButton
      Left = 824
      Top = 11
      Width = 140
      Height = 36
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Cerrar (ESC)'
      TabOrder = 0
      OnClick = btnCerrarClick
    end
  end
end
