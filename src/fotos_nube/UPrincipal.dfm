object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Gestor de Fotos'
  ClientHeight = 600
  ClientWidth = 760
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = 'Source Sans 3'
  Font.Style = []
  Position = poScreenCenter
  TextHeight = 15
  object pcMain: TPageControl
    Left = 0
    Top = 0
    Width = 760
    Height = 600
    ActivePage = tsSubir
    Align = alClient
    TabOrder = 0
    ExplicitWidth = 758
    ExplicitHeight = 592
    object tsSubir: TTabSheet
      Caption = 'Subir foto'
      object edUrl: TLabeledEdit
        Left = 16
        Top = 32
        Width = 720
        Height = 23
        EditLabel.Width = 21
        EditLabel.Height = 15
        EditLabel.Caption = 'URL'
        TabOrder = 0
        Text = 'https://localhost/upload_foto.php'
      end
      object edKey: TLabeledEdit
        Left = 16
        Top = 80
        Width = 720
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
        Width = 354
        Height = 23
        EditLabel.Width = 79
        EditLabel.Height = 15
        EditLabel.Caption = 'Carpeta cliente'
        TabOrder = 2
        Text = 'cliente_demo'
      end
      object edNombre: TLabeledEdit
        Left = 384
        Top = 128
        Width = 352
        Height = 23
        EditLabel.Width = 44
        EditLabel.Height = 15
        EditLabel.Caption = 'Nombre'
        TabOrder = 3
        Text = 'producto_001'
      end
      object edArchivo: TLabeledEdit
        Left = 16
        Top = 176
        Width = 632
        Height = 23
        EditLabel.Width = 41
        EditLabel.Height = 15
        EditLabel.Caption = 'Archivo'
        TabOrder = 4
        Text = ''
      end
      object btnSel: TButton
        Left = 658
        Top = 176
        Width = 78
        Height = 23
        Caption = 'Examinar...'
        TabOrder = 5
        OnClick = btnSelClick
      end
      object btnSubir: TButton
        Left = 16
        Top = 216
        Width = 720
        Height = 32
        Caption = 'Subir foto'
        TabOrder = 6
        OnClick = btnSubirClick
      end
      object mLogs: TMemo
        Left = 16
        Top = 264
        Width = 720
        Height = 289
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
    object tsVer: TTabSheet
      Caption = 'Ver foto'
      ImageIndex = 1
      object lblResolucion: TLabel
        Left = 384
        Top = 128
        Width = 58
        Height = 15
        Caption = 'Resoluci'#243'n'
      end
      object imgFoto: TImage
        Left = 16
        Top = 184
        Width = 480
        Height = 369
        Center = True
        Proportional = True
        Stretch = True
      end
      object edUrlVer: TLabeledEdit
        Left = 16
        Top = 32
        Width = 720
        Height = 23
        EditLabel.Width = 21
        EditLabel.Height = 15
        EditLabel.Caption = 'URL'
        TabOrder = 0
        Text = 'https://localhost/ver_foto.php'
      end
      object edKeyVer: TLabeledEdit
        Left = 16
        Top = 80
        Width = 720
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
        Width = 184
        Height = 23
        EditLabel.Width = 79
        EditLabel.Height = 15
        EditLabel.Caption = 'Carpeta cliente'
        TabOrder = 2
        Text = 'cliente_demo'
      end
      object edNombreVer: TLabeledEdit
        Left = 216
        Top = 144
        Width = 152
        Height = 23
        EditLabel.Width = 44
        EditLabel.Height = 15
        EditLabel.Caption = 'Nombre'
        TabOrder = 3
        Text = 'producto_001'
      end
      object cbResolucion: TComboBox
        Left = 384
        Top = 144
        Width = 121
        Height = 23
        Style = csDropDownList
        ItemIndex = 0
        TabOrder = 4
        Text = '150'
        Items.Strings = (
          '150'
          '300'
          'real')
      end
      object btnVer: TButton
        Left = 528
        Top = 144
        Width = 208
        Height = 24
        Caption = 'Ver foto'
        TabOrder = 5
        OnClick = btnVerClick
      end
      object mLogsVer: TMemo
        Left = 512
        Top = 184
        Width = 224
        Height = 369
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Consolas'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssBoth
        TabOrder = 6
        WordWrap = False
      end
    end
  end
end
