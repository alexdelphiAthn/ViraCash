inherited frmModalErrorAplicacion: TfrmModalErrorAplicacion
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSizeable
  Caption = 'Se ha producido un error'
  ClientHeight = 704
  ClientWidth = 844
  Constraints.MinHeight = 560
  Constraints.MinWidth = 700
  Position = poScreenCenter
  TextHeight = 19
  object pnlContacto: TPanel [0]
    Left = 0
    Top = 0
    Width = 844
    Height = 234
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblEvidencias: TcxLabel
      Left = 12
      Top = 8
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
      Caption = 'Detalle del error y evidencias que se enviarán.'
      Properties.WordWrap = True
      Transparent = True
      Height = 42
      Width = 820
    end
    object lblEmail: TcxLabel
      Left = 12
      Top = 56
      Caption = 'Email de contacto:'
      Transparent = True
    end
    object edtEmail: TcxTextEdit
      Left = 140
      Top = 54
      TabOrder = 0
      Width = 290
    end
    object lblTelefono: TcxLabel
      Left = 450
      Top = 56
      Anchors = [akTop, akRight]
      Caption = 'Teléfono de contacto:'
      Transparent = True
    end
    object edtTelefono: TcxTextEdit
      Left = 600
      Top = 54
      Anchors = [akTop, akRight]
      TabOrder = 1
      Width = 232
    end
    object lblDescripcion: TcxLabel
      Left = 12
      Top = 88
      Caption = '¿Qué estaba haciendo cuando ocurrió?'
      Transparent = True
    end
    object mDescripcion: TcxMemo
      Left = 12
      Top = 112
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 2
      Height = 48
      Width = 820
    end
    object chkEnviarCopia: TcxCheckBox
      Left = 12
      Top = 164
      Anchors = [akLeft, akTop, akRight]
      Caption = 'Enviar copia de seguridad protegida (ZIP)'
      TabOrder = 3
      Width = 820
    end
    object lblEstadoLog: TcxLabel
      Left = 12
      Top = 190
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
      Properties.WordWrap = True
      Transparent = True
      Height = 38
      Width = 820
    end
  end
  object pnlBotones: TPanel [1]
    Left = 0
    Top = 612
    Width = 844
    Height = 92
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnActivarLog: TcxButton
      Left = 12
      Top = 8
      Width = 180
      Height = 32
      Caption = 'Activar LOG completo'
      TabOrder = 0
    end
    object btnEnviar: TcxButton
      Left = 444
      Top = 8
      Width = 190
      Height = 32
      Anchors = [akTop, akRight]
      Caption = 'Enviar error al soporte'
      TabOrder = 1
    end
    object btnCopiar: TcxButton
      Left = 642
      Top = 8
      Width = 190
      Height = 32
      Anchors = [akTop, akRight]
      Caption = 'Copiar al portapapeles'
      TabOrder = 2
    end
    object btnSalirAplicacion: TcxButton
      Left = 534
      Top = 48
      Width = 190
      Height = 32
      Anchors = [akTop, akRight]
      Caption = 'Salir de la aplicación'
      TabOrder = 3
    end
    object btnCerrar: TcxButton
      Left = 732
      Top = 48
      Width = 100
      Height = 32
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Cerrar'
      Default = True
      ModalResult = 1
      TabOrder = 4
    end
  end
  object mDetalle: TcxMemo [2]
    Left = 0
    Top = 234
    Align = alClient
    Properties.ReadOnly = True
    Properties.ScrollBars = ssBoth
    Properties.WordWrap = False
    Style.Font.Charset = DEFAULT_CHARSET
    Style.Font.Color = clWindowText
    Style.Font.Height = -12
    Style.Font.Name = 'Consolas'
    Style.Font.Style = []
    Style.IsFontAssigned = True
    TabOrder = 2
    Height = 378
    Width = 844
  end
end
