inherited frmMtoModalEmpCer: TfrmMtoModalEmpCer
  BorderIcons = []
  Caption = 'Seleccionar Certificado'
  ClientHeight = 183
  ClientWidth = 1071
  OnClose = FormClose
  ExplicitWidth = 1083
  ExplicitHeight = 221
  TextHeight = 19
  object pnl1: TPanel [0]
    Left = 0
    Top = 142
    Width = 1071
    Height = 41
    Align = alBottom
    TabOrder = 1
    ExplicitTop = 141
    ExplicitWidth = 461
    object btnCancelar1: TcxButton
      Left = 10
      Top = 6
      Width = 177
      Height = 25
      Caption = '&Cancelar'
      TabOrder = 0
      OnClick = btnCancelarClick
    end
    object btnAceptar: TcxButton
      Left = 248
      Top = 6
      Width = 177
      Height = 25
      Caption = '&Aceptar'
      TabOrder = 1
      OnClick = btnAceptarClick
    end
  end
  object cxgrdCertificados: TcxGrid [1]
    Left = 0
    Top = 0
    Width = 1071
    Height = 142
    Align = alClient
    TabOrder = 0
    ExplicitWidth = 461
    ExplicitHeight = 141
    object tvCertificados: TcxGridTableView
      OptionsData.Editing = False
      OptionsSelection.CellSelect = False
      OptionsView.GroupByBox = False
      object colTipoCertificado: TcxGridColumn
        Caption = 'Tipo'
        Width = 100
      end
      object colTitularCertificado: TcxGridColumn
        Caption = 'Titular/Empresa'
        Width = 250
      end
      object colNombreCertificado: TcxGridColumn
        Caption = 'Nombre'
        Width = 250
      end
      object colEmisorCertificado: TcxGridColumn
        Caption = 'Emisor'
        Width = 200
      end
      object colFechaHastaCertificado: TcxGridColumn
        Caption = 'V'#225'lido hasta'
        Width = 120
      end
      object colNumeroSerieCertificado: TcxGridColumn
        Caption = 'N'#250'mero de serie'
        Width = 150
      end
    end
    object lvCertificados: TcxGridLevel
      GridView = tvCertificados
    end
  end
  inherited Localizer1: TcxLocalizer
    Left = 232
    Top = 440
  end
end
