inherited frmMtoPermisosArbol: TfrmMtoPermisosArbol
  Caption = 'Gesti'#243'n de Permisos'
  TextHeight = 19
  inherited pButtonPage: TPanel
    inherited pcPantalla: TcxPageControl
      Properties.ActivePage = tsGestion
      inherited tsLista: TcxTabSheet
        TabVisible = False
      end
      inherited tsFicha: TcxTabSheet
        TabVisible = False
      end
      object tsGestion: TcxTabSheet
        Caption = 'Gesti'#243'n'
        TabVisible = False
        object pnlSujeto: TPanel
          Left = 0
          Top = 0
          Width = 957
          Height = 64
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          object lblSujeto: TcxLabel
            Left = 12
            Top = 14
            Caption = 'Permisos de:'
            Transparent = True
          end
          object lblAvisoAdmin: TcxLabel
            Left = 12
            Top = 42
            Caption = ''
            AutoSize = False
            Transparent = True
            Height = 18
            Width = 930
          end
          object cbbSujeto: TcxComboBox
            Left = 110
            Top = 11
            Properties.DropDownListStyle = lsFixedList
            TabOrder = 0
            Width = 430
          end
          object btnRecargar: TcxButton
            Left = 556
            Top = 9
            Width = 110
            Height = 29
            Caption = 'Recargar'
            TabOrder = 1
          end
        end
        object pnlHerramientas: TPanel
          Left = 0
          Top = 64
          Width = 957
          Height = 40
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 1
          object lblFiltro: TcxLabel
            Left = 600
            Top = 12
            Caption = 'Filtro:'
            Transparent = True
          end
          object btnExpandir: TcxButton
            Left = 8
            Top = 6
            Width = 90
            Height = 28
            Caption = 'Expandir'
            TabOrder = 0
          end
          object btnContraer: TcxButton
            Left = 102
            Top = 6
            Width = 90
            Height = 28
            Caption = 'Contraer'
            TabOrder = 1
          end
          object btnPermitirRama: TcxButton
            Left = 206
            Top = 6
            Width = 120
            Height = 28
            Caption = 'Permitir rama'
            TabOrder = 2
          end
          object btnDenegarRama: TcxButton
            Left = 330
            Top = 6
            Width = 120
            Height = 28
            Caption = 'Denegar rama'
            TabOrder = 3
          end
          object btnHeredarRama: TcxButton
            Left = 454
            Top = 6
            Width = 120
            Height = 28
            Caption = 'Heredar (rama)'
            TabOrder = 4
          end
          object edtFiltro: TcxTextEdit
            Left = 648
            Top = 9
            TabOrder = 5
            Width = 240
          end
        end
        object pnlTransfer: TPanel
          Left = 0
          Top = 386
          Width = 957
          Height = 128
          Align = alBottom
          BevelOuter = bvNone
          TabOrder = 2
          object lblTransfer: TcxLabel
            Left = 12
            Top = 8
            Caption = 'Transferir / copiar permisos entre sujetos'
            Transparent = True
          end
          object lblDe: TcxLabel
            Left = 12
            Top = 40
            Caption = 'Copiar de:'
            Transparent = True
          end
          object lblA: TcxLabel
            Left = 436
            Top = 40
            Caption = 'a:'
            Transparent = True
          end
          object cbbOrigen: TcxComboBox
            Left = 92
            Top = 37
            Properties.DropDownListStyle = lsFixedList
            TabOrder = 0
            Width = 330
          end
          object cbbDestino: TcxComboBox
            Left = 456
            Top = 37
            Properties.DropDownListStyle = lsFixedList
            TabOrder = 1
            Width = 330
          end
          object rgModo: TcxRadioGroup
            Left = 12
            Top = 66
            Caption = 'Modo de copia'
            TabOrder = 2
            Height = 56
            Width = 470
          end
          object chkSoloMenu: TcxCheckBox
            Left = 500
            Top = 82
            Caption = 'Solo permisos de men'#250
            TabOrder = 3
            Transparent = True
            Width = 210
          end
          object btnCopiar: TcxButton
            Left = 730
            Top = 78
            Width = 160
            Height = 36
            Caption = 'Copiar permisos'
            TabOrder = 4
          end
        end
        object pnlArbol: TPanel
          Left = 0
          Top = 104
          Width = 957
          Height = 282
          Align = alClient
          BevelOuter = bvNone
          TabOrder = 3
        end
      end
    end
  end
end
