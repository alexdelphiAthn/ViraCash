inherited frmModalSelAlmacenAlbaran: TfrmModalSelAlmacenAlbaran
  Caption = 'Crear albarán desde pedido'
  ClientHeight = 280
  ClientWidth = 560
  StyleElements = [seFont, seClient, seBorder]
  OnClose = FormClose
  OnShow = FormShow
  ExplicitWidth = 576
  ExplicitHeight = 319
  TextHeight = 19
  object pnlButton: TPanel [0]
    Left = 0
    Top = 221
    Width = 560
    Height = 59
    Align = alBottom
    TabOrder = 0
    object btnCancelar: TcxButton
      Left = 40
      Top = 9
      Width = 200
      Height = 40
      Cancel = True
      Caption = '&Cancelar (ESC)'
      ModalResult = 2
      TabOrder = 0
    end
    object btnAceptar: TcxButton
      Left = 320
      Top = 9
      Width = 200
      Height = 40
      Caption = '&Aceptar (F12)'
      TabOrder = 1
      OnClick = btnAceptarClick
    end
  end
  object pnlBody: TPanel [1]
    Left = 0
    Top = 0
    Width = 560
    Height = 221
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object lblPedido: TLabel
      Left = 16
      Top = 12
      Width = 528
      Height = 19
      AutoSize = False
      Caption = 'lblPedido'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object chkAnadirExistente: TcxCheckBox
      Left = 16
      Top = 44
      Caption = 'Añadir a un albarán ya existente de este pedido'
      TabOrder = 0
      OnClick = chkAnadirExistenteClick
    end
    object lblAlbaran: TcxLabel
      Left = 16
      Top = 78
      Caption = 'Albarán destino:'
      Transparent = True
    end
    object cbbAlbaran: TcxLookupComboBox
      Left = 16
      Top = 104
      Properties.DropDownAutoSize = True
      Properties.DropDownListStyle = lsFixedList
      Properties.DropDownSizeable = True
      Properties.KeyFieldNames = 'NUMERO_ALB'
      Properties.ListColumns = <
        item
          Caption = 'Número'
          Width = 90
          FieldName = 'NUMERO_ALB'
        end
        item
          Caption = 'Serie'
          Width = 70
          FieldName = 'SERIE_ALB'
        end
        item
          Caption = 'Fecha'
          Width = 100
          FieldName = 'FECHA_ALB'
        end
        item
          Caption = 'Estado'
          Width = 90
          FieldName = 'ESTADO_ALB'
        end
        item
          Caption = 'Total'
          Width = 100
          FieldName = 'TOTAL_LIQUIDO_ALB'
        end>
      TabOrder = 1
      Width = 460
    end
    object lblAlmacen: TcxLabel
      Left = 16
      Top = 148
      Caption = 'Almacén del albarán:'
      Transparent = True
    end
    object cbbAlmacen: TcxLookupComboBox
      Left = 16
      Top = 174
      Properties.DropDownAutoSize = True
      Properties.DropDownListStyle = lsFixedList
      Properties.DropDownSizeable = True
      Properties.KeyFieldNames = 'CODIGO_ALM_ALM'
      Properties.ListColumns = <
        item
          Caption = 'Código'
          Width = 100
          FieldName = 'CODIGO_ALM_ALM'
        end
        item
          Caption = 'Almacén'
          Width = 320
          FieldName = 'NOMBRE_ALM_ALM'
        end>
      TabOrder = 2
      Width = 460
    end
  end
  object ActionList1: TActionList
    Left = 456
    Top = 16
    object actAceptar: TAction
      Caption = 'Aceptar'
      ShortCut = 123
      OnExecute = actAceptarExecute
    end
  end
  object dsAlmacenes: TDataSource
    Left = 408
    Top = 16
  end
  object dsAlbaranesPed: TDataSource
    Left = 408
    Top = 72
  end
end
