inherited frmModalSesionMaterializar: TfrmModalSesionMaterializar
  Caption = 'Materializar sesi'#243'n de compra'
  ClientHeight = 360
  ClientWidth = 580
  StyleElements = [seFont, seClient, seBorder]
  OnClose = FormClose
  OnShow = FormShow
  ExplicitWidth = 580
  ExplicitHeight = 360
  TextHeight = 19
  object pnlBody: TPanel [0]
    Left = 0
    Top = 0
    Width = 580
    Height = 300
    Align = alClient
    TabOrder = 0
    object lblTitulo: TcxLabel
      Left = 16
      Top = 16
      Caption = 'Atenci'#243'n: esta acci'#243'n no se puede deshacer.'
      Style.Font.Style = [fsBold]
      Style.IsFontAssigned = True
      Transparent = True
    end
    object lblResumen: TcxLabel
      Left = 16
      Top = 50
      Caption = 'Se van a crear los art'#237'culos, SKUs, c'#243'digos de barras y enlaces al proveedor seg'#250'n el detalle de la sesi'#243'n.'
      Properties.WordWrap = True
      Width = 540
      Transparent = True
    end
    object chkPedido: TcxCheckBox
      Left = 16
      Top = 130
      Caption = 'Generar pedido de compra (no mueve stock)'
      Properties.ValueChecked = 'S'
      Properties.ValueUnchecked = 'N'
      TabOrder = 0
      Width = 540
    end
    object chkAlbaran: TcxCheckBox
      Left = 16
      Top = 160
      Caption = 'Generar albar'#225'n de compra (entra stock en el almac'#233'n destino)'
      Properties.ValueChecked = 'S'
      Properties.ValueUnchecked = 'N'
      TabOrder = 1
      Width = 540
    end
    object lblAviso: TcxLabel
      Left = 16
      Top = 220
      Caption = 'Si ambos documentos est'#225'n marcados se generan en orden: pedido primero, luego albar'#225'n.'
      Properties.WordWrap = True
      Width = 540
      Transparent = True
    end
  end
  object pnlButton: TPanel [1]
    Left = 0
    Top = 300
    Width = 580
    Height = 60
    Align = alBottom
    TabOrder = 1
    object btnCancelar: TcxButton
      Left = 40
      Top = 12
      Width = 180
      Height = 38
      Cancel = True
      Caption = '&Cancelar (ESC)'
      TabOrder = 0
      OnClick = btnCancelarClick
    end
    object btnAceptar: TcxButton
      Left = 360
      Top = 12
      Width = 180
      Height = 38
      Caption = '&Confirmar (F12)'
      Default = True
      TabOrder = 1
      OnClick = btnAceptarClick
    end
  end
  object ActionList1: TActionList
    Left = 480
    Top = 8
    object actAceptar: TAction
      Caption = 'Aceptar'
      ShortCut = 123
      OnExecute = actAceptarExecute
    end
    object actCancelar: TAction
      Caption = 'Cancelar'
      ShortCut = 27
      OnExecute = actCancelarExecute
    end
  end
end
