inherited frmModalFacturarAlbaranesFechas: TfrmModalFacturarAlbaranesFechas
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Crear borradores por fechas / serie'
  ClientHeight = 540
  ClientWidth = 980
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = 'Source Sans 3'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 17
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 980
    Height = 90
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    ExplicitWidth = 978
    object lblSerie: TcxLabel
      Left = 8
      Top = 8
      Caption = 'Serie albar'#225'n'
      TabOrder = 5
      Transparent = True
    end
    object edtSerie: TcxTextEdit
      Left = 8
      Top = 28
      TabOrder = 0
      Width = 150
    end
    object lblFechaDesde: TcxLabel
      Left = 170
      Top = 8
      Caption = 'Fecha desde'
      TabOrder = 6
      Transparent = True
    end
    object dteDesde: TcxDateEdit
      Left = 170
      Top = 28
      TabOrder = 1
      Width = 130
    end
    object lblFechaHasta: TcxLabel
      Left = 312
      Top = 8
      Caption = 'Fecha hasta'
      TabOrder = 7
      Transparent = True
    end
    object dteHasta: TcxDateEdit
      Left = 312
      Top = 28
      TabOrder = 2
      Width = 130
    end
    object chkAgruparPorCliente: TcxCheckBox
      Left = 452
      Top = 28
      Caption = 'Un borrador por cliente (consolidar)'
      TabOrder = 3
    end
    object btnBuscar: TcxButton
      Left = 826
      Top = 23
      Width = 130
      Height = 30
      Caption = 'Buscar'
      TabOrder = 4
      OnClick = btnBuscarClick
    end
  end
  object pnlMid: TPanel
    Left = 0
    Top = 90
    Width = 980
    Height = 400
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    ExplicitWidth = 978
    ExplicitHeight = 392
    object cxgrdAlbaranes: TcxGrid
      Left = 0
      Top = 0
      Width = 980
      Height = 400
      Align = alClient
      TabOrder = 0
      ExplicitWidth = 978
      ExplicitHeight = 392
      object tvAlbaranes: TcxGridTableView
        OptionsView.GroupByBox = False
        object colSel: TcxGridColumn
          Caption = 'Sel.'
          PropertiesClassName = 'TcxCheckBoxProperties'
          Width = 50
        end
        object colNumero: TcxGridColumn
          Caption = 'N'#250'mero'
          Width = 90
        end
        object colSerie: TcxGridColumn
          Caption = 'Serie'
          Width = 70
        end
        object colFecha: TcxGridColumn
          Caption = 'Fecha'
          Width = 110
        end
        object colCliente: TcxGridColumn
          Caption = 'C'#243'd. Cliente'
          Width = 153
        end
        object colRazonSocial: TcxGridColumn
          Caption = 'Raz'#243'n Social'
          Width = 290
        end
        object colTotal: TcxGridColumn
          Caption = 'Total'
          Width = 110
        end
      end
      object cxgrdlvlAlbaranes: TcxGridLevel
        GridView = tvAlbaranes
      end
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 490
    Width = 980
    Height = 50
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    ExplicitTop = 482
    ExplicitWidth = 978
    object lblEstado: TcxLabel
      Left = 8
      Top = 14
      Caption = 'Listo'
      TabOrder = 3
      Transparent = True
    end
    object btnSeleccionarTodos: TcxButton
      Left = 480
      Top = 12
      Width = 200
      Height = 28
      Caption = 'Marcar / Desmarcar'
      TabOrder = 0
      OnClick = btnSeleccionarTodosClick
    end
    object btnFacturar: TcxButton
      Left = 690
      Top = 12
      Width = 170
      Height = 28
      Caption = 'Generar borradores'
      TabOrder = 1
      OnClick = btnFacturarClick
    end
    object btnCerrar: TcxButton
      Left = 870
      Top = 12
      Width = 100
      Height = 28
      Caption = 'Cerrar'
      TabOrder = 2
      OnClick = btnCerrarClick
    end
  end
end
