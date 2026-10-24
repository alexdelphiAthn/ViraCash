inherited frmFotoArticulo: TfrmFotoArticulo
  BorderIcons = [biSystemMenu, biMinimize, biMaximize]
  BorderStyle = bsSizeable
  Caption = 'Foto del art'#237'culo / SKU'
  ClientHeight = 520
  ClientWidth = 520
  Position = poDesigned
  StyleElements = [seFont, seClient, seBorder]
  OnClose = FormClose
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnShow = FormShow
  ExplicitWidth = 536
  ExplicitHeight = 559
  TextHeight = 19
  object pnlTop: TPanel [0]
    Left = 0
    Top = 0
    Width = 520
    Height = 26
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object btnToggle: TcxButton
      Left = 2
      Top = 2
      Width = 22
      Height = 22
      Caption = ''
      Hint = 'Mostrar u ocultar controles (F11)'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 0
      OnClick = btnToggleClick
    end
    object btnDescargarNube: TcxButton
      Left = 26
      Top = 2
      Width = 22
      Height = 22
      Caption = ''
      Hint = 'Bajar fotos del servidor'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 1
      OnClick = btnDescargarNubeClick
    end
    object lblOrigen: TcxLabel
      Left = 50
      Top = 3
      Anchors = [akLeft, akTop, akRight]
      Caption = 'Sin foto'
      Properties.WordWrap = True
      TabOrder = 2
      Visible = False
      Width = 346
      Transparent = True
    end
    object btnMarcarPredeterminada: TcxButton
      Left = 398
      Top = 2
      Width = 22
      Height = 22
      Anchors = [akTop, akRight]
      Caption = ''
      Hint = 'Establecer esta foto como predeterminada'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 3
      OnClick = btnMarcarPredeterminadaClick
    end
    object btnFotoAnterior: TcxButton
      Left = 422
      Top = 2
      Width = 22
      Height = 22
      Anchors = [akTop, akRight]
      Caption = ''
      Hint = 'Foto anterior'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 4
      OnClick = btnFotoAnteriorClick
    end
    object lblNumeroFoto: TcxLabel
      Left = 446
      Top = 3
      Anchors = [akTop, akRight]
      Caption = '0/0'
      Properties.Alignment.Horz = taCenter
      TabOrder = 5
      Transparent = True
      Width = 24
    end
    object btnFotoSiguiente: TcxButton
      Left = 472
      Top = 2
      Width = 22
      Height = 22
      Anchors = [akTop, akRight]
      Caption = ''
      Hint = 'Foto siguiente'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 6
      OnClick = btnFotoSiguienteClick
    end
    object btnAnadirFoto: TcxButton
      Left = 496
      Top = 2
      Width = 22
      Height = 22
      Anchors = [akTop, akRight]
      Caption = ''
      Hint = 'A'#241'adir foto'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 7
      OnClick = btnAnadirFotoClick
    end
  end
  object pnlControles: TPanel [1]
    Left = 0
    Top = 26
    Width = 520
    Height = 54
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    Visible = False
    object rgResolucion: TcxRadioGroup
      Left = 2
      Top = 1
      Caption = ''
      Hint = 'Resoluci'#243'n de la foto mostrada'
      ParentShowHint = False
      Properties.Columns = 3
      Properties.Items = <
        item
          Caption = '300'
          Value = '300'
        end
        item
          Caption = '600'
          Value = '600'
        end
        item
          Caption = 'Real'
          Value = 'real'
        end>
      Properties.OnEditValueChanged = rgResolucionPropertiesEditValueChanged
      ItemIndex = 0
      Style.BorderStyle = ebsOffice11
      ShowHint = True
      TabOrder = 0
      Height = 24
      Width = 194
    end
    object lblNivel: TcxLabel
      Left = 202
      Top = 2
      Caption = 'Nivel:'
      TabOrder = 8
      Transparent = True
    end
    object cbbNivelSku: TcxComboBox
      Left = 244
      Top = 2
      Anchors = [akLeft, akTop, akRight]
      Properties.DropDownListStyle = lsFixedList
      TabOrder = 1
      Width = 274
    end
    object btnCambiarArt: TcxButton
      Left = 2
      Top = 28
      Width = 26
      Height = 24
      Caption = ''
      Hint = 'Sustituir la foto predeterminada del art'#237'culo'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 2
      OnClick = btnCambiarArtClick
    end
    object btnCambiarSku: TcxButton
      Left = 30
      Top = 28
      Width = 26
      Height = 24
      Caption = ''
      Hint = 'Sustituir la foto predeterminada del nivel seleccionado'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 3
      OnClick = btnCambiarSkuClick
    end
    object btnQuitar: TcxButton
      Left = 114
      Top = 28
      Width = 26
      Height = 24
      Caption = ''
      Hint = 'Eliminar definitivamente la foto visible'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 6
      OnClick = btnQuitarClick
    end
    object btnRotarIzq: TcxButton
      Left = 58
      Top = 28
      Width = 26
      Height = 24
      Caption = ''
      Hint = 'Rotar la foto visible a la izquierda'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 4
      OnClick = btnRotarIzqClick
    end
    object btnRotarDer: TcxButton
      Left = 86
      Top = 28
      Width = 26
      Height = 24
      Caption = ''
      Hint = 'Rotar la foto visible a la derecha'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 5
      OnClick = btnRotarDerClick
    end
    object btnLayout: TcxButton
      Left = 142
      Top = 28
      Width = 26
      Height = 24
      Caption = ''
      Hint = 'Guardar posici'#243'n, tama'#241'o y resoluci'#243'n'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 7
      OnClick = btnLayoutClick
    end
  end
  object pnlImage: TPanel [2]
    Left = 0
    Top = 80
    Width = 520
    Height = 410
    Align = alClient
    BevelOuter = bvLowered
    TabOrder = 2
    object imgFoto: TImage
      Left = 1
      Top = 1
      Width = 518
      Height = 408
      Align = alClient
      Center = True
      Proportional = True
      Stretch = True
    end
  end
  object pnlTransparencia: TPanel [3]
    Left = 0
    Top = 490
    Width = 520
    Height = 30
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 3
    object lblTransparencia: TcxLabel
      Left = 4
      Top = 5
      Caption = 'Transparencia (%)'
      Transparent = True
      TabOrder = 0
    end
    object spnTransparencia: TcxSpinEdit
      Left = 148
      Top = 3
      ParentShowHint = False
      Properties.MinValue = 0.000000000000000000
      Properties.MaxValue = 90.000000000000000000
      Properties.Increment = 5.000000000000000000
      Properties.ValueType = vtInt
      Properties.OnEditValueChanged = spnTransparenciaPropertiesEditValueChanged
      ShowHint = True
      TabOrder = 1
      Value = 0
      Width = 64
    end
  end
  inherited Localizer1: TcxLocalizer
    Left = 424
  end
  object dlgAbrirFoto: TOpenDialog
    Filter = 
      'Im'#225'genes|*.png;*.jpg;*.jpeg;*.gif;*.webp;*.avif;*.heic;*.bmp|PNG' +
      '|*.png|JPG|*.jpg;*.jpeg|GIF|*.gif|WebP|*.webp|AVIF|*.avif|HEIC|*' +
      '.heic;*.heif|BMP|*.bmp|Todos|*.*'
    Title = 'Seleccionar foto'
    Left = 424
    Top = 16
  end
end
