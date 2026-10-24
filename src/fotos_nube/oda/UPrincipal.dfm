object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Gestor de Fotos'
  ClientHeight = 640
  ClientWidth = 880
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = 'Source Sans 3'
  Font.Style = []
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  TextHeight = 15
  object pcMain: TPageControl
    Left = 0
    Top = 0
    Width = 880
    Height = 640
    ActivePage = tsBatch
    Align = alClient
    TabOrder = 0
    ExplicitWidth = 878
    ExplicitHeight = 632
    object tsSubir: TTabSheet
      Caption = 'Subir foto'
      object edUrl: TLabeledEdit
        Left = 16
        Top = 32
        Width = 840
        Height = 23
        EditLabel.Width = 21
        EditLabel.Height = 15
        EditLabel.Caption = 'URL'
        TabOrder = 0
        Text = 'https://webservice.veryverifactu.com/upload_foto.php'
      end
      object edKey: TLabeledEdit
        Left = 16
        Top = 80
        Width = 840
        Height = 23
        EditLabel.Width = 40
        EditLabel.Height = 15
        EditLabel.Caption = 'API Key'
        TabOrder = 1
        Text = 'k7Hq9mZ2pXvR4nL8'
      end
      object edCarpetaCliente: TLabeledEdit
        Left = 16
        Top = 128
        Width = 264
        Height = 23
        EditLabel.Width = 79
        EditLabel.Height = 15
        EditLabel.Caption = 'Carpeta cliente'
        TabOrder = 2
        Text = 'cliente_demo'
      end
      object edArticulo: TLabeledEdit
        Left = 296
        Top = 128
        Width = 200
        Height = 23
        EditLabel.Width = 42
        EditLabel.Height = 15
        EditLabel.Caption = 'Art'#237'culo'
        TabOrder = 3
        Text = 'A1234'
      end
      object edColor: TLabeledEdit
        Left = 512
        Top = 128
        Width = 200
        Height = 23
        EditLabel.Width = 29
        EditLabel.Height = 15
        EditLabel.Caption = 'Color'
        TabOrder = 4
        Text = 'ROJO'
      end
      object edIndice: TLabeledEdit
        Left = 728
        Top = 128
        Width = 128
        Height = 23
        EditLabel.Width = 32
        EditLabel.Height = 15
        EditLabel.Caption = #205'ndice'
        TabOrder = 5
        Text = '1'
      end
      object edArchivo: TLabeledEdit
        Left = 16
        Top = 176
        Width = 752
        Height = 23
        EditLabel.Width = 41
        EditLabel.Height = 15
        EditLabel.Caption = 'Archivo'
        TabOrder = 6
        Text = ''
      end
      object btnSel: TButton
        Left = 778
        Top = 176
        Width = 78
        Height = 23
        Caption = 'Examinar...'
        TabOrder = 7
        OnClick = btnSelClick
      end
      object btnSubir: TButton
        Left = 16
        Top = 216
        Width = 840
        Height = 32
        Caption = 'Subir foto'
        TabOrder = 8
        OnClick = btnSubirClick
      end
      object mLogs: TMemo
        Left = 16
        Top = 264
        Width = 840
        Height = 329
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Consolas'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssBoth
        TabOrder = 9
        WordWrap = False
      end
    end
    object tsVer: TTabSheet
      Caption = 'Ver foto'
      ImageIndex = 1
      object lblResolucion: TLabel
        Left = 16
        Top = 184
        Width = 58
        Height = 15
        Caption = 'Resoluci'#243'n'
      end
      object imgFoto: TImage
        Left = 16
        Top = 240
        Width = 560
        Height = 353
        Center = True
        Proportional = True
        Stretch = True
      end
      object edUrlVer: TLabeledEdit
        Left = 16
        Top = 32
        Width = 840
        Height = 23
        EditLabel.Width = 21
        EditLabel.Height = 15
        EditLabel.Caption = 'URL'
        TabOrder = 0
        Text = 'https://webservice.veryverifactu.com/ver_foto.php'
      end
      object edKeyVer: TLabeledEdit
        Left = 16
        Top = 80
        Width = 840
        Height = 23
        EditLabel.Width = 40
        EditLabel.Height = 15
        EditLabel.Caption = 'API Key'
        TabOrder = 1
        Text = 'k7Hq9mZ2pXvR4nL8'
      end
      object edCarpetaClienteVer: TLabeledEdit
        Left = 16
        Top = 144
        Width = 200
        Height = 23
        EditLabel.Width = 79
        EditLabel.Height = 15
        EditLabel.Caption = 'Carpeta cliente'
        TabOrder = 2
        Text = 'cliente_demo'
      end
      object edArticuloVer: TLabeledEdit
        Left = 232
        Top = 144
        Width = 168
        Height = 23
        EditLabel.Width = 42
        EditLabel.Height = 15
        EditLabel.Caption = 'Art'#237'culo'
        TabOrder = 3
        Text = 'A1234'
      end
      object edColorVer: TLabeledEdit
        Left = 416
        Top = 144
        Width = 168
        Height = 23
        EditLabel.Width = 29
        EditLabel.Height = 15
        EditLabel.Caption = 'Color'
        TabOrder = 4
        Text = 'ROJO'
      end
      object edIndiceVer: TLabeledEdit
        Left = 600
        Top = 144
        Width = 80
        Height = 23
        EditLabel.Width = 32
        EditLabel.Height = 15
        EditLabel.Caption = #205'ndice'
        TabOrder = 5
        Text = '1'
      end
      object cbResolucion: TComboBox
        Left = 80
        Top = 200
        Width = 121
        Height = 23
        Style = csDropDownList
        ItemIndex = 0
        TabOrder = 6
        Text = '150'
        Items.Strings = (
          '150'
          '300'
          'real')
      end
      object btnVer: TButton
        Left = 224
        Top = 198
        Width = 632
        Height = 26
        Caption = 'Ver foto'
        TabOrder = 7
        OnClick = btnVerClick
      end
      object mLogsVer: TMemo
        Left = 592
        Top = 240
        Width = 264
        Height = 353
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Consolas'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssBoth
        TabOrder = 8
        WordWrap = False
      end
    end
    object tsBatch: TTabSheet
      Caption = 'Subida masiva'
      ImageIndex = 2
      object lblConcurrencia: TLabel
        Left = 600
        Top = 248
        Width = 110
        Height = 15
        Caption = 'Concurrencia (hilos):'
      end
      object lblBatchStatus: TLabel
        Left = 16
        Top = 320
        Width = 64
        Height = 15
        Caption = 'Esperando...'
      end
      object edUrlBatch: TLabeledEdit
        Left = 16
        Top = 32
        Width = 416
        Height = 23
        EditLabel.Width = 88
        EditLabel.Height = 15
        EditLabel.Caption = 'URL upload_foto'
        TabOrder = 0
        Text = 'https://webservice.veryverifactu.com/upload_foto.php'
      end
      object edUrlListBatch: TLabeledEdit
        Left = 448
        Top = 32
        Width = 408
        Height = 23
        EditLabel.Width = 81
        EditLabel.Height = 15
        EditLabel.Caption = 'URL listar_fotos'
        TabOrder = 1
        Text = 'https://webservice.veryverifactu.com/listar_fotos.php'
      end
      object edKeyBatch: TLabeledEdit
        Left = 16
        Top = 80
        Width = 416
        Height = 23
        EditLabel.Width = 40
        EditLabel.Height = 15
        EditLabel.Caption = 'API Key'
        TabOrder = 2
        Text = 'k7Hq9mZ2pXvR4nL8'
      end
      object edCarpetaClienteBatch: TLabeledEdit
        Left = 448
        Top = 80
        Width = 200
        Height = 23
        EditLabel.Width = 79
        EditLabel.Height = 15
        EditLabel.Caption = 'Carpeta cliente'
        TabOrder = 3
        Text = 'lochicos'
      end
      object edPrefijoLocal: TLabeledEdit
        Left = 664
        Top = 80
        Width = 192
        Height = 23
        EditLabel.Width = 108
        EditLabel.Height = 15
        EditLabel.Caption = 'Prefijo local de fotos'
        TabOrder = 4
        Text = 'C:\FOTOS\'
      end
      object edSqlServer: TLabeledEdit
        Left = 16
        Top = 144
        Width = 280
        Height = 23
        EditLabel.Width = 114
        EditLabel.Height = 15
        EditLabel.Caption = 'SQL Server (host\inst)'
        TabOrder = 5
        Text = '.\SQLEXPRESS'
      end
      object edSqlDatabase: TLabeledEdit
        Left = 312
        Top = 144
        Width = 200
        Height = 23
        EditLabel.Width = 48
        EditLabel.Height = 15
        EditLabel.Caption = 'Database'
        TabOrder = 6
        Text = 'ViraCash'
      end
      object edSqlUser: TLabeledEdit
        Left = 528
        Top = 144
        Width = 152
        Height = 23
        EditLabel.Width = 40
        EditLabel.Height = 15
        EditLabel.Caption = 'Usuario'
        TabOrder = 7
        Text = 'sa'
      end
      object edSqlPassword: TLabeledEdit
        Left = 696
        Top = 144
        Width = 160
        Height = 23
        EditLabel.Width = 60
        EditLabel.Height = 15
        EditLabel.Caption = 'Contrase'#241'a'
        PasswordChar = '*'
        TabOrder = 8
        Text = ''
      end
      object chkSqlWindowsAuth: TCheckBox
        Left = 528
        Top = 173
        Width = 240
        Height = 17
        Caption = 'Usar autenticaci'#243'n Windows'
        Checked = True
        State = cbChecked
        TabOrder = 9
      end
      object cbConcurrencia: TComboBox
        Left = 736
        Top = 244
        Width = 120
        Height = 23
        Style = csDropDownList
        TabOrder = 10
      end
      object btnLanzar: TButton
        Left = 16
        Top = 240
        Width = 280
        Height = 32
        Caption = 'Lanzar subida masiva'
        TabOrder = 11
        OnClick = btnLanzarClick
      end
      object btnCancelar: TButton
        Left = 312
        Top = 240
        Width = 152
        Height = 32
        Caption = 'Cancelar'
        TabOrder = 12
        OnClick = btnCancelarClick
      end
      object edDemoCarpeta: TLabeledEdit
        Left = 16
        Top = 200
        Width = 600
        Height = 23
        EditLabel.Width = 249
        EditLabel.Height = 15
        EditLabel.Caption = 'Carpeta de DEMO (cualquier carpeta con fotos)'
        TabOrder = 18
        Text = ''
      end
      object btnDemoSel: TButton
        Left = 624
        Top = 200
        Width = 90
        Height = 23
        Caption = 'Examinar...'
        TabOrder = 16
        OnClick = btnDemoSelClick
      end
      object btnDemoLanzar: TButton
        Left = 724
        Top = 196
        Width = 132
        Height = 28
        Caption = 'DEMO: subir fotos'
        TabOrder = 17
        OnClick = btnDemoLanzarClick
      end
      object pbBatch: TProgressBar
        Left = 16
        Top = 288
        Width = 840
        Height = 24
        TabOrder = 13
      end
      object sbSlots: TScrollBox
        Left = 16
        Top = 320
        Width = 840
        Height = 130
        HorzScrollBar.Visible = False
        VertScrollBar.Tracking = True
        Color = clWindow
        ParentColor = False
        TabOrder = 15
      end
      object mLogsBatch: TMemo
        Left = 16
        Top = 458
        Width = 840
        Height = 135
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Consolas'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssBoth
        TabOrder = 14
        WordWrap = False
      end
    end
    object tsBackup: TTabSheet
      Caption = 'Backup'
      ImageIndex = 3
      object lblBackupStatus: TLabel
        Left = 16
        Top = 248
        Width = 64
        Height = 15
        Caption = 'Esperando...'
      end
      object edUrlGenBackup: TLabeledEdit
        Left = 16
        Top = 32
        Width = 416
        Height = 23
        EditLabel.Width = 108
        EditLabel.Height = 15
        EditLabel.Caption = 'URL generar_backup'
        TabOrder = 0
        Text = 'https://localhost/generar_backup.php'
      end
      object edUrlEstadoBackup: TLabeledEdit
        Left = 448
        Top = 32
        Width = 408
        Height = 23
        EditLabel.Width = 103
        EditLabel.Height = 15
        EditLabel.Caption = 'URL estado_backup'
        TabOrder = 1
        Text = 'https://localhost/estado_backup.php'
      end
      object edKeyBackup: TLabeledEdit
        Left = 16
        Top = 80
        Width = 416
        Height = 23
        EditLabel.Width = 40
        EditLabel.Height = 15
        EditLabel.Caption = 'API Key'
        TabOrder = 2
        Text = 'k7Hq9mZ2pXvR4nL8'
      end
      object edCarpetaClienteBackup: TLabeledEdit
        Left = 448
        Top = 80
        Width = 200
        Height = 23
        EditLabel.Width = 79
        EditLabel.Height = 15
        EditLabel.Caption = 'Carpeta cliente'
        TabOrder = 3
        Text = 'cliente_demo'
      end
      object edPasswordBackup: TLabeledEdit
        Left = 664
        Top = 80
        Width = 192
        Height = 23
        EditLabel.Width = 80
        EditLabel.Height = 15
        EditLabel.Caption = 'Contrase'#241'a ZIP'
        PasswordChar = '*'
        TabOrder = 4
        Text = ''
      end
      object btnGenerarBackup: TButton
        Left = 16
        Top = 144
        Width = 840
        Height = 40
        Caption = 'Generar backup'
        TabOrder = 5
        OnClick = btnGenerarBackupClick
      end
      object pbBackup: TProgressBar
        Left = 16
        Top = 208
        Width = 840
        Height = 24
        TabOrder = 6
      end
      object mLogsBackup: TMemo
        Left = 16
        Top = 280
        Width = 840
        Height = 313
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Consolas'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssBoth
        TabOrder = 7
        WordWrap = False
      end
    end
  end
  object tmrBackup: TTimer
    Enabled = False
    OnTimer = tmrBackupTimer
    Left = 800
    Top = 8
  end
end
