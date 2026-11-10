object frmLogon: TfrmLogon
  Left = 0
  Top = 0
  BorderIcons = [biMinimize]
  BorderStyle = bsSingle
  Caption = 'Login ViraCash'
  ClientHeight = 422
  ClientWidth = 702
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = 'Source Sans 3'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  OnClose = FormClose
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  TextHeight = 18
  object pnlMain: TPanel
    Left = 0
    Top = 0
    Width = 702
    Height = 422
    Align = alClient
    TabOrder = 0
    ExplicitWidth = 706
    ExplicitHeight = 438
    object pnlLogin: TPanel
      Left = 14
      Top = 24
      Width = 329
      Height = 156
      TabOrder = 0
      object lblUsuario: TcxLabel
        Left = 7
        Top = 0
        AutoSize = False
        Caption = 'Usuario'
        TabOrder = 4
        Transparent = True
        Height = 21
        Width = 312
      end
      object lblContrasena: TcxLabel
        Left = 7
        Top = 55
        AutoSize = False
        Caption = 'Contrase'#241'a'
        TabOrder = 5
        Transparent = True
        Height = 21
        Width = 335
      end
      object edtUser: TcxTextEdit
        Left = 7
        Top = 24
        TabOrder = 0
        Width = 312
      end
      object edtPass: TcxTextEdit
        Left = 7
        Top = 79
        Properties.EchoMode = eemPassword
        Properties.PasswordChar = '*'
        TabOrder = 1
        Width = 312
      end
      object chkRememberUser: TcxCheckBox
        Left = 0
        Top = 114
        Caption = 'Recordar Usuario'
        TabOrder = 2
      end
      object chkRememberPassword: TcxCheckBox
        Left = 156
        Top = 114
        Caption = 'Recordar Contrase'#241'a'
        TabOrder = 3
      end
    end
    object pnlButtons: TPanel
      Left = 14
      Top = 258
      Width = 329
      Height = 58
      TabOrder = 1
      object btnAceptar: TButton
        Left = 182
        Top = 11
        Width = 142
        Height = 30
        Caption = '&Aceptar (F12)'
        TabOrder = 0
        OnClick = btnAceptarClick
      end
      object btnSalir: TButton
        Left = 6
        Top = 11
        Width = 141
        Height = 30
        Caption = '&Salir (Esc)'
        TabOrder = 1
        OnClick = btnSalirClick
      end
    end
    object chkAuto: TcxCheckBox
      Left = 15
      Top = 186
      Caption = 'Arranque sin login'
      TabOrder = 2
    end
    object btnConf: TcxButton
      Left = 120
      Top = 218
      Width = 223
      Height = 31
      Caption = 'Configurar &Base de Datos ->'
      TabOrder = 3
      OnClick = btnConfClick
    end
  end
  object pnlBBDD: TPanel
    Left = 360
    Top = 0
    Width = 360
    Height = 360
    TabOrder = 1
    Visible = False
    object lblBBDDConfig: TcxLabel
      Left = 1
      Top = 1
      Align = alTop
      AutoSize = False
      Caption = 'Configuraci'#243'n BBDD'
      TabOrder = 9
      Transparent = True
      Height = 24
      Width = 358
    end
    object lblHostBBDD: TcxLabel
      Left = 24
      Top = 30
      AutoSize = False
      Caption = 'Host:'
      TabOrder = 10
      Transparent = True
      Height = 21
      Width = 312
    end
    object lblPortHost: TcxLabel
      Left = 264
      Top = 30
      AutoSize = False
      Caption = 'Puerto:'
      TabOrder = 11
      Transparent = True
      Height = 21
      Width = 72
    end
    object lblNomBBDD: TcxLabel
      Left = 24
      Top = 85
      AutoSize = False
      Caption = 'Nombre BD:'
      TabOrder = 12
      Transparent = True
      Height = 21
      Width = 312
    end
    object lblUserBBDD: TcxLabel
      Left = 24
      Top = 140
      AutoSize = False
      Caption = 'Usuario:'
      TabOrder = 13
      Transparent = True
      Height = 21
      Width = 312
    end
    object lblPassBBDD: TcxLabel
      Left = 24
      Top = 195
      AutoSize = False
      Caption = 'Contrase'#241'a:'
      TabOrder = 14
      Transparent = True
      Height = 21
      Width = 312
    end
    object edtHostName: TcxTextEdit
      Left = 24
      Top = 54
      OnMouseUp = EditorConexionMouseUp
      TabOrder = 0
      Width = 234
    end
    object edtPortBD: TcxTextEdit
      Left = 264
      Top = 54
      OnMouseUp = EditorConexionMouseUp
      TabOrder = 1
      Width = 72
    end
    object edtNomBD: TcxTextEdit
      Left = 24
      Top = 109
      OnMouseUp = EditorConexionMouseUp
      TabOrder = 2
      Width = 312
    end
    object edtUserBD: TcxTextEdit
      Left = 24
      Top = 164
      OnMouseUp = EditorConexionMouseUp
      TabOrder = 3
      Width = 312
    end
    object edtPassBD: TcxTextEdit
      Left = 24
      Top = 219
      Properties.EchoMode = eemPassword
      Properties.PasswordChar = '*'
      OnMouseUp = EditorConexionMouseUp
      TabOrder = 4
      Width = 312
    end
    object btnTest: TcxButton
      Left = 24
      Top = 258
      Width = 144
      Height = 30
      Caption = 'Proba&r Conexi'#243'n'
      TabOrder = 5
      OnClick = btnTestClick
    end
    object btnSubirScript: TcxButton
      Left = 174
      Top = 258
      Width = 162
      Height = 30
      Caption = '&Subir script'
      TabOrder = 6
      OnClick = btnSubirScriptClick
    end
    object btnCopiaSeguridad: TcxButton
      Left = 24
      Top = 294
      Width = 144
      Height = 30
      Caption = '&Copia seguridad'
      TabOrder = 7
      OnClick = btnCopiaSeguridadClick
    end
    object btnRecover: TcxButton
      Left = 174
      Top = 294
      Width = 162
      Height = 30
      Caption = '&Restaurar Copia'
      TabOrder = 8
      OnClick = btnRecoverClick
    end
  end
  object JvEnterAsTab1: TJvEnterAsTab
    Left = 274
    Top = 313
  end
  object saveDialog: TFileSaveDialog
    FavoriteLinks = <>
    FileTypes = <>
    Options = []
    Left = 160
    Top = 376
  end
  object openDialog: TFileOpenDialog
    FavoriteLinks = <>
    FileTypes = <>
    Options = []
    Left = 240
    Top = 368
  end
end
