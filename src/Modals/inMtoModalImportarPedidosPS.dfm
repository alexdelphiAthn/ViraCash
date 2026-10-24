inherited frmModalImportarPedidosPS: TfrmModalImportarPedidosPS
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Importar pedidos de PrestaShop'
  ClientHeight = 540
  ClientWidth = 920
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = 'Source Sans 3'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 920
    Height = 90
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblConfiguracion: TcxLabel
      Left = 8
      Top = 35
      Caption =
        'Se usa la configuraci'#243'n efectiva de Par'#225'metros de Entorno'
      TabOrder = 1
      Transparent = True
    end
    object btnConectar: TcxButton
      Left = 760
      Top = 29
      Width = 140
      Height = 30
      Caption = 'Conectar y listar'
      TabOrder = 0
      OnClick = btnConectarClick
    end
    object chkMostrarImportados: TcxCheckBox
      Left = 8
      Top = 60
      Caption = 'Mostrar tambi'#233'n los pedidos ya importados y los anteriores'
      TabOrder = 2
      Transparent = True
      Width = 600
    end
  end
  object pnlMid: TPanel
    Left = 0
    Top = 90
    Width = 920
    Height = 400
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object cxgrdPedidos: TcxGrid
      Left = 0
      Top = 0
      Width = 920
      Height = 400
      Align = alClient
      TabOrder = 0
      object tvPedidos: TcxGridTableView
        OptionsView.GroupByBox = False
        object colSel: TcxGridColumn
          Caption = 'Sel.'
          PropertiesClassName = 'TcxCheckBoxProperties'
          Width = 50
        end
        object colId: TcxGridColumn
          Caption = 'ID PS'
          Width = 70
        end
        object colRef: TcxGridColumn
          Caption = 'Referencia'
          Width = 110
        end
        object colFecha: TcxGridColumn
          Caption = 'Fecha'
          Width = 130
        end
        object colCliente: TcxGridColumn
          Caption = 'Cliente'
          Width = 220
        end
        object colTotal: TcxGridColumn
          Caption = 'Total'
          Width = 100
        end
        object colEstado: TcxGridColumn
          Caption = 'Estado'
          Width = 160
        end
        object colImportado: TcxGridColumn
          Caption = 'Importado?'
          Width = 80
        end
      end
      object cxgrdlvlPedidos: TcxGridLevel
        GridView = tvPedidos
      end
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 490
    Width = 920
    Height = 50
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object lblEstado: TcxLabel
      Left = 8
      Top = 14
      Caption = 'Listo'
      TabOrder = 2
      Transparent = True
    end
    object btnImportar: TcxButton
      Left = 627
      Top = 12
      Width = 153
      Height = 28
      Caption = 'Importar selecci'#243'n'
      TabOrder = 0
      OnClick = btnImportarClick
    end
    object btnCerrar: TcxButton
      Left = 790
      Top = 12
      Width = 100
      Height = 28
      Caption = 'Cerrar'
      TabOrder = 1
      OnClick = btnCerrarClick
    end
  end
end
