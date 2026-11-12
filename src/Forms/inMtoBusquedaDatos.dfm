inherited frmMtoBusquedaDatos: TfrmMtoBusquedaDatos
  Caption = 'B'#250'squeda de datos de art'#237'culos (Ctrl+E)'
  ClientHeight = 720
  ClientWidth = 1240
  StyleElements = [seFont, seClient, seBorder]
  ExplicitLeft = 3
  ExplicitTop = 3
  ExplicitWidth = 1256
  ExplicitHeight = 759
  TextHeight = 17
  inherited pButtonPage: TPanel
    Width = 1100
    Height = 720
    StyleElements = [seFont, seClient, seBorder]
    ExplicitWidth = 1098
    ExplicitHeight = 712
    inherited pcPantalla: TcxPageControl
      Width = 1100
      Height = 610
      ExplicitWidth = 1098
      ExplicitHeight = 602
      ClientRectBottom = 606
      ClientRectRight = 1096
      inherited tsLista: TcxTabSheet
        ExplicitWidth = 1090
        ExplicitHeight = 594
        inherited cxGrdPrincipal: TcxGrid
          Top = 172
          Width = 1092
          Height = 430
          TabOrder = 1
          ExplicitTop = 172
          ExplicitWidth = 1090
          ExplicitHeight = 422
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            FilterRow.Visible = True
            OptionsView.GroupByBox = True
          end
        end
        object pnlCriterios: TPanel
          Left = 0
          Top = 0
          Width = 1092
          Height = 172
          Align = alTop
          BevelOuter = bvNone
          ParentBackground = False
          TabOrder = 0
          ExplicitWidth = 1090
          object lblCampo: TcxLabel
            Left = 12
            Top = 6
            Caption = 'Buscar por'
            TabOrder = 9
            Transparent = True
          end
          object cbbCampo: TcxComboBox
            Style.LookAndFeel.ScrollbarMode = sbmClassic
            StyleDisabled.LookAndFeel.ScrollbarMode = sbmClassic
            StyleFocused.LookAndFeel.ScrollbarMode = sbmClassic
            StyleHot.LookAndFeel.ScrollbarMode = sbmClassic
            Left = 12
            Top = 27
            Properties.DropDownListStyle = lsFixedList
            Properties.OnChange = cbbCampoPropertiesChange
            TabOrder = 0
            Width = 180
          end
          object lblValor: TcxLabel
            Left = 204
            Top = 6
            Caption = 'Texto a buscar'
            TabOrder = 10
            Transparent = True
          end
          object edtValor: TcxButtonEdit
            Left = 204
            Top = 27
            Properties.Buttons = <
              item
                Default = True
                Kind = bkEllipsis
              end>
            Properties.Nullstring = 'Introduzca el valor y pulse Entrar'
            Properties.OnButtonClick = edtValorPropertiesButtonClick
            TabOrder = 1
            OnKeyDown = edtValorKeyDown
            Width = 265
          end
          object lblCoincidencia: TcxLabel
            Left = 481
            Top = 6
            Caption = 'Coincidencia'
            TabOrder = 11
            Transparent = True
          end
          object cbbCoincidencia: TcxComboBox
            Left = 481
            Top = 27
            Properties.DropDownListStyle = lsFixedList
            TabOrder = 2
            Width = 135
          end
          object chkDistinguirMayusculas: TcxCheckBox
            Left = 628
            Top = 28
            Caption = 'May'#250'sculas/min'#250'sculas'
            TabOrder = 3
            Transparent = True
          end
          object btnBuscar: TcxButton
            Left = 831
            Top = 23
            Width = 120
            Height = 32
            Caption = '&Buscar'
            Default = True
            TabOrder = 4
            OnClick = btnBuscarClick
          end
          object btnLimpiar: TcxButton
            Left = 957
            Top = 23
            Width = 120
            Height = 32
            Caption = '&Limpiar'
            TabOrder = 5
            OnClick = btnLimpiarClick
          end
          object lblEstado: TcxLabel
            Left = 12
            Top = 62
            Caption = 'Estado'
            TabOrder = 12
            Transparent = True
          end
          object cbbEstado: TcxComboBox
            Left = 12
            Top = 82
            Properties.DropDownListStyle = lsFixedList
            TabOrder = 6
            Width = 145
          end
          object lblStock: TcxLabel
            Left = 169
            Top = 62
            Caption = 'Existencias'
            TabOrder = 13
            Transparent = True
          end
          object cbbStock: TcxComboBox
            Left = 169
            Top = 82
            Properties.DropDownListStyle = lsFixedList
            TabOrder = 7
            Width = 145
          end
          object lblLimite: TcxLabel
            Left = 326
            Top = 62
            Caption = 'M'#225'ximo de filas'
            TabOrder = 14
            Transparent = True
          end
          object cbbLimite: TcxComboBox
            Left = 326
            Top = 82
            Properties.DropDownListStyle = lsFixedList
            TabOrder = 8
            Width = 105
          end
          object lblAyuda: TcxLabel
            Left = 463
            Top = 81
            Caption = 'Los filtros previos reducen la carga antes de consultar SKU.'
            TabOrder = 15
            Transparent = True
          end
          object btnPerfiles: TcxButton
            Left = 947
            Top = 73
            Width = 130
            Height = 29
            Caption = '&Perfiles...'
            TabOrder = 16
            OnClick = btnPerfilesClick
          end
          object lblFamilia: TcxLabel
            Left = 12
            Top = 116
            Caption = 'Familias (opcional)'
            TabOrder = 20
            Transparent = True
          end
          object edtFamilias: TcxButtonEdit
            Left = 12
            Top = 137
            Properties.Buttons = <
              item
                Default = True
                Kind = bkEllipsis
              end>
            Properties.ReadOnly = True
            Properties.OnButtonClick = edtFamiliasPropertiesButtonClick
            TabOrder = 17
            Width = 250
          end
          object lblProveedor: TcxLabel
            Left = 274
            Top = 116
            Caption = 'Proveedor (opcional)'
            TabOrder = 21
            Transparent = True
          end
          object cbbProveedor: TcxLookupComboBox
            Left = 274
            Top = 137
            Properties.DropDownListStyle = lsEditList
            Properties.DropDownRows = 15
            Properties.DropDownWidth = 480
            Properties.KeyFieldNames = 'CODIGO_PRV_PRV'
            Properties.ListColumns = <
              item
                Caption = 'C'#243'digo'
                Width = 110
                FieldName = 'CODIGO_PRV_PRV'
              end
              item
                Caption = 'Nombre'
                Width = 350
                FieldName = 'NOMBRE_MOSTRADO_PRV'
              end>
            Properties.ListFieldIndex = 1
            Properties.ListOptions.CaseInsensitive = True
            Properties.ListOptions.ShowHeader = True
            Properties.ListSource = dsProveedoresBusqueda
            TabOrder = 18
            OnKeyPress = cbbProveedorKeyPress
            Width = 300
          end
          object lblTemporada: TcxLabel
            Left = 586
            Top = 116
            Caption = 'Temporada (opcional)'
            TabOrder = 22
            Transparent = True
          end
          object cbbTemporada: TcxComboBox
            Left = 586
            Top = 137
            Properties.DropDownListStyle = lsFixedList
            TabOrder = 19
            Width = 220
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        ExplicitWidth = 1092
        ExplicitHeight = 602
      end
      inherited tsPerfil: TcxTabSheet
        ExplicitWidth = 1092
        ExplicitHeight = 602
        inherited pnlPerfilTop: TPanel
          Width = 1092
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 1092
          inherited edtPerfilBusq: TcxTextEdit
            ExplicitHeight = 25
          end
        end
        inherited pnlPerfilDetail: TPanel
          Width = 1092
          Height = 545
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 1092
          ExplicitHeight = 545
          inherited cxgrdPerfil: TcxGrid
            Width = 1092
            Height = 545
            ExplicitWidth = 1092
            ExplicitHeight = 545
          end
        end
      end
    end
    inherited pnlTopPage: TPanel
      Width = 1100
      StyleElements = [seFont, seClient, seBorder]
      ExplicitWidth = 1098
      inherited pnlTopGrid: TPanel
        Width = 1100
        StyleElements = [seFont, seClient, seBorder]
        ExplicitWidth = 1098
        inherited sbExportExcel: TSpeedButton
          Visible = True
        end
        inherited edtBusqGlobal: TcxTextEdit
          ExplicitHeight = 25
        end
      end
    end
    inherited pnl1: TPanel
      Top = 650
      Width = 1100
      StyleElements = [seFont, seClient, seBorder]
      ExplicitTop = 642
      ExplicitWidth = 1098
      inherited btnAceptar: TcxButton
        Left = 735
        Caption = '&Abrir art'#237'culo (F12)'
        ExplicitLeft = 735
      end
      inherited btnCancelar1: TcxButton
        Caption = '&Cerrar (ESC)'
      end
      object lblResultados: TcxLabel
        Left = 220
        Top = 26
        Caption = '0 SKU encontrados'
        TabOrder = 2
        Transparent = True
      end
    end
  end
  inherited pButtonRightBar: TPanel
    Left = 1100
    Height = 720
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 1098
    ExplicitHeight = 712
    inherited pButtonGen: TPanel
      Top = 522
      StyleElements = [seFont, seClient, seBorder]
      ExplicitTop = 514
    end
    inherited pButtonBDStat: TPanel
      StyleElements = [seFont, seClient, seBorder]
      inherited pnStateDataSet: TPanel
        StyleElements = [seFont, seClient, seBorder]
      end
      inherited pnlDataSetName: TPanel
        StyleElements = [seFont, seClient, seBorder]
      end
    end
    object btnOcultar: TcxButton
      Left = 2
      Top = 202
      Width = 135
      Height = 29
      Caption = 'Ocultar criterios'
      TabOrder = 3
      OnClick = btnOcultarClick
    end
  end
  inherited dsTablaG: TDataSource
  end
  object dsProveedoresBusqueda: TDataSource
    Left = 880
    Top = 264
  end
end
