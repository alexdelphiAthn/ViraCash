object frmPrincipal: TfrmPrincipal
  Left = 0
  Top = 0
  Caption = 'PruebaVentasWs - Careta del webservice de ventas'
  ClientHeight = 720
  ClientWidth = 1000
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 17
  object pnlConfig: TPanel
    Left = 0
    Top = 0
    Width = 1000
    Height = 145
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblUrl: TLabel
      Left = 16
      Top = 12
      Width = 132
      Height = 17
      Caption = 'URL base de la API'
    end
    object lblToken: TLabel
      Left = 592
      Top = 12
      Width = 39
      Height = 17
      Caption = 'Token'
    end
    object lblReferencia: TLabel
      Left = 848
      Top = 12
      Width = 68
      Height = 17
      Caption = 'Referencia'
    end
    object lblServidor: TLabel
      Left = 16
      Top = 68
      Width = 108
      Height = 17
      Caption = 'Servidor MariaDB'
    end
    object lblPuerto: TLabel
      Left = 204
      Top = 68
      Width = 43
      Height = 17
      Caption = 'Puerto'
    end
    object lblBaseDatos: TLabel
      Left = 272
      Top = 68
      Width = 92
      Height = 17
      Caption = 'Base de datos'
    end
    object lblUsuario: TLabel
      Left = 440
      Top = 68
      Width = 51
      Height = 17
      Caption = 'Usuario'
    end
    object lblPassword: TLabel
      Left = 588
      Top = 68
      Width = 63
      Height = 17
      Caption = 'Password'
    end
    object lblEstado: TLabel
      Left = 16
      Top = 122
      Width = 968
      Height = 17
      AutoSize = False
      Caption = 'Sin conexión a la base de datos.'
    end
    object edtUrl: TEdit
      Left = 16
      Top = 32
      Width = 560
      Height = 25
      TabOrder = 0
    end
    object edtToken: TEdit
      Left = 592
      Top = 32
      Width = 240
      Height = 25
      PasswordChar = '*'
      TabOrder = 1
    end
    object edtReferencia: TEdit
      Left = 848
      Top = 32
      Width = 136
      Height = 25
      MaxLength = 100
      TabOrder = 2
    end
    object edtServidor: TEdit
      Left = 16
      Top = 88
      Width = 180
      Height = 25
      TabOrder = 3
    end
    object edtPuerto: TEdit
      Left = 204
      Top = 88
      Width = 60
      Height = 25
      TabOrder = 4
    end
    object edtBaseDatos: TEdit
      Left = 272
      Top = 88
      Width = 160
      Height = 25
      TabOrder = 5
    end
    object edtUsuario: TEdit
      Left = 440
      Top = 88
      Width = 140
      Height = 25
      TabOrder = 6
    end
    object edtPassword: TEdit
      Left = 588
      Top = 88
      Width = 140
      Height = 25
      PasswordChar = '*'
      TabOrder = 7
    end
    object btnConectar: TButton
      Left = 736
      Top = 86
      Width = 110
      Height = 29
      Caption = 'Conectar BBDD'
      TabOrder = 8
      OnClick = btnConectarClick
    end
    object btnProbarApi: TButton
      Left = 856
      Top = 86
      Width = 128
      Height = 29
      Caption = 'Probar API'
      TabOrder = 9
      OnClick = btnProbarApiClick
    end
  end
  object pgcPrincipal: TPageControl
    Left = 0
    Top = 145
    Width = 1000
    Height = 575
    ActivePage = tsEnviar
    Align = alClient
    TabOrder = 1
    object tsEnviar: TTabSheet
      Caption = 'Enviar venta'
      object lblEnvSerie: TLabel
        Left = 16
        Top = 16
        Width = 35
        Height = 17
        Caption = 'Serie'
      end
      object lblEnvNumero: TLabel
        Left = 116
        Top = 16
        Width = 51
        Height = 17
        Caption = 'Número'
      end
      object lblTipoEvento: TLabel
        Left = 248
        Top = 16
        Width = 96
        Height = 17
        Caption = 'Tipo de evento'
      end
      object lblSecuencia: TLabel
        Left = 460
        Top = 16
        Width = 124
        Height = 17
        Caption = 'Secuencia / ID cola'
      end
      object lblJson: TLabel
        Left = 16
        Top = 76
        Width = 178
        Height = 17
        Caption = 'JSON del evento (editable)'
      end
      object lblEnvResultado: TLabel
        Left = 16
        Top = 440
        Width = 63
        Height = 17
        Anchors = [akLeft, akBottom]
        Caption = 'Resultado'
      end
      object edtEnvSerie: TEdit
        Left = 16
        Top = 36
        Width = 90
        Height = 25
        MaxLength = 20
        TabOrder = 0
      end
      object edtEnvNumero: TEdit
        Left = 116
        Top = 36
        Width = 120
        Height = 25
        MaxLength = 20
        TabOrder = 1
      end
      object cbbTipoEvento: TComboBox
        Left = 248
        Top = 36
        Width = 200
        Height = 25
        Style = csDropDownList
        TabOrder = 2
        Items.Strings = (
          'VENTA_CONFIRMADA'
          'FISCAL_ACTUALIZADO'
          'VENTA_ANULADA'
          'VENTA_SUSTITUIDA'
          'VENTA_REABIERTA'
          'TICKET_PDF_ACTUALIZADO'
          'FACTURA_PDF_ACTUALIZADO')
      end
      object edtSecuencia: TEdit
        Left = 460
        Top = 36
        Width = 120
        Height = 25
        TabOrder = 3
      end
      object btnGenerar: TButton
        Left = 592
        Top = 34
        Width = 130
        Height = 29
        Caption = 'Generar JSON'
        TabOrder = 4
        OnClick = btnGenerarClick
      end
      object btnEnviar: TButton
        Left = 732
        Top = 34
        Width = 130
        Height = 29
        Caption = 'Enviar al webservice'
        TabOrder = 5
        OnClick = btnEnviarClick
      end
      object btnCopiarJson: TButton
        Left = 872
        Top = 34
        Width = 100
        Height = 29
        Caption = 'Copiar JSON'
        TabOrder = 6
        OnClick = btnCopiarJsonClick
      end
      object mJson: TMemo
        Left = 16
        Top = 96
        Width = 956
        Height = 336
        Anchors = [akLeft, akTop, akRight, akBottom]
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Consolas'
        Font.Style = []
        ParentFont = False
        ScrollBars = ssBoth
        TabOrder = 7
        WordWrap = False
      end
      object mEnvResultado: TMemo
        Left = 16
        Top = 460
        Width = 956
        Height = 80
        Anchors = [akLeft, akRight, akBottom]
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 8
      end
    end
    object tsConsultar: TTabSheet
      Caption = 'Consultar ventas'
      ImageIndex = 1
      object lblConEmpresa: TLabel
        Left = 16
        Top = 16
        Width = 55
        Height = 17
        Caption = 'Empresa'
      end
      object lblConSerie: TLabel
        Left = 116
        Top = 16
        Width = 35
        Height = 17
        Caption = 'Serie'
      end
      object lblConNumero: TLabel
        Left = 216
        Top = 16
        Width = 51
        Height = 17
        Caption = 'Número'
      end
      object lblConTipo: TLabel
        Left = 336
        Top = 16
        Width = 96
        Height = 17
        Caption = 'Tipo de evento'
      end
      object lblDesde: TLabel
        Left = 536
        Top = 16
        Width = 106
        Height = 17
        Caption = 'Desde (aaaa-mm-dd)'
      end
      object lblHasta: TLabel
        Left = 676
        Top = 16
        Width = 103
        Height = 17
        Caption = 'Hasta (aaaa-mm-dd)'
      end
      object lblLimite: TLabel
        Left = 816
        Top = 16
        Width = 42
        Height = 17
        Caption = 'Límite'
      end
      object edtConEmpresa: TEdit
        Left = 16
        Top = 36
        Width = 90
        Height = 25
        MaxLength = 20
        TabOrder = 0
      end
      object edtConSerie: TEdit
        Left = 116
        Top = 36
        Width = 90
        Height = 25
        MaxLength = 20
        TabOrder = 1
      end
      object edtConNumero: TEdit
        Left = 216
        Top = 36
        Width = 110
        Height = 25
        MaxLength = 20
        TabOrder = 2
      end
      object cbbConTipo: TComboBox
        Left = 336
        Top = 36
        Width = 190
        Height = 25
        Style = csDropDownList
        TabOrder = 3
        Items.Strings = (
          ''
          'VENTA_CONFIRMADA'
          'FISCAL_ACTUALIZADO'
          'VENTA_ANULADA'
          'VENTA_SUSTITUIDA'
          'VENTA_REABIERTA'
          'TICKET_PDF_ACTUALIZADO'
          'FACTURA_PDF_ACTUALIZADO')
      end
      object edtDesde: TEdit
        Left = 536
        Top = 36
        Width = 130
        Height = 25
        MaxLength = 40
        TabOrder = 4
      end
      object edtHasta: TEdit
        Left = 676
        Top = 36
        Width = 130
        Height = 25
        MaxLength = 40
        TabOrder = 5
      end
      object edtLimite: TEdit
        Left = 816
        Top = 36
        Width = 70
        Height = 25
        TabOrder = 6
      end
      object btnListar: TButton
        Left = 896
        Top = 34
        Width = 76
        Height = 29
        Caption = 'Listar'
        Default = True
        TabOrder = 7
        OnClick = btnListarClick
      end
      object lvVentas: TListView
        Left = 16
        Top = 76
        Width = 956
        Height = 200
        Anchors = [akLeft, akTop, akRight]
        Columns = <
          item
            Caption = 'Empresa'
            Width = 90
          end
          item
            Caption = 'Serie'
            Width = 80
          end
          item
            Caption = 'Número'
            Width = 110
          end
          item
            Caption = 'Secuencia'
            Width = 90
          end
          item
            Caption = 'Último evento'
            Width = 200
          end
          item
            Caption = 'Modificado (UTC)'
            Width = 190
          end
          item
            Caption = 'Líneas'
            Width = 70
          end>
        ReadOnly = True
        RowSelect = True
        TabOrder = 8
        ViewStyle = vsReport
        OnDblClick = lvVentasDblClick
      end
      object btnDetalle: TButton
        Left = 16
        Top = 286
        Width = 120
        Height = 29
        Caption = 'Ver detalle'
        TabOrder = 9
        OnClick = btnDetalleClick
      end
      object btnDescargarTicket: TButton
        Left = 146
        Top = 286
        Width = 150
        Height = 29
        Caption = 'Descargar ticket PDF'
        TabOrder = 10
        OnClick = btnDescargarTicketClick
      end
      object btnDescargarFactura: TButton
        Left = 306
        Top = 286
        Width = 150
        Height = 29
        Caption = 'Descargar factura PDF'
        TabOrder = 11
        OnClick = btnDescargarFacturaClick
      end
      object mDetalle: TMemo
        Left = 16
        Top = 326
        Width = 956
        Height = 210
        Anchors = [akLeft, akTop, akRight, akBottom]
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Consolas'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssBoth
        TabOrder = 12
        WordWrap = False
      end
    end
  end
end
