inherited frmMtoColoresBasicos: TfrmMtoColoresBasicos
  Caption = 'Colores básicos'
  inherited pButtonPage: TPanel
    inherited pcPantalla: TcxPageControl
      Properties.ActivePage = tsLista
      inherited tsLista: TcxTabSheet
        inherited cxGrdPrincipal: TcxGrid
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            OptionsData.Editing = True
            object cxGrdDBTabPrinCODIGO_ATB: TcxGridDBColumn
              Caption = 'Código'
              DataBinding.FieldName = 'CODIGO_ATB'
              Options.Editing = False
              Width = 180
            end
            object cxGrdDBTabPrinNOMBRE_ATB: TcxGridDBColumn
              Caption = 'Nombre'
              DataBinding.FieldName = 'NOMBRE_ATB'
              Width = 300
            end
            object cxGrdDBTabPrinHEX_ATB: TcxGridDBColumn
              Caption = 'Paleta'
              DataBinding.FieldName = 'HEX_ATB'
              PropertiesClassName = 'TcxButtonEditProperties'
              Properties.Buttons = <
                item
                  Default = True
                  Kind = bkEllipsis
                end>
              Properties.OnButtonClick = CambiarPaleta
              OnCustomDrawCell = PintarPaleta
              Width = 160
            end
            object cxGrdDBTabPrinORDEN_ATB: TcxGridDBColumn
              Caption = 'Orden'
              DataBinding.FieldName = 'ORDEN_ATB'
              PropertiesClassName = 'TcxSpinEditProperties'
              Width = 80
            end
            object cxGrdDBTabPrinESACTIVO_ATB: TcxGridDBColumn
              Caption = 'Activo'
              DataBinding.FieldName = 'ESACTIVO_ATB'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 80
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        object pnlColor: TcxGroupBox
          Align = alClient
          PanelStyle.Active = True
          Style.BorderStyle = ebsNone
          Transparent = True
          TabOrder = 0
          Height = 487
          Width = 947
          object lblCodigo: TcxLabel
            Left = 24
            Top = 24
            Caption = 'Código'
            Transparent = True
          end
          object txtCODIGO_ATB: TcxDBTextEdit
            Left = 144
            Top = 21
            DataBinding.DataField = 'CODIGO_ATB'
            DataBinding.DataSource = dsTablaG
            Properties.MaxLength = 100
            TabOrder = 0
            Width = 280
          end
          object lblNombre: TcxLabel
            Left = 24
            Top = 64
            Caption = 'Nombre'
            Transparent = True
          end
          object txtNOMBRE_ATB: TcxDBTextEdit
            Left = 144
            Top = 61
            DataBinding.DataField = 'NOMBRE_ATB'
            DataBinding.DataSource = dsTablaG
            Properties.MaxLength = 100
            TabOrder = 1
            Width = 400
          end
          object lblPaleta: TcxLabel
            Left = 24
            Top = 104
            Caption = 'Paleta'
            Transparent = True
          end
          object btnHEX_ATB: TcxDBButtonEdit
            Left = 144
            Top = 101
            DataBinding.DataField = 'HEX_ATB'
            DataBinding.DataSource = dsTablaG
            Properties.Buttons = <
              item
                Default = True
                Kind = bkEllipsis
              end>
            Properties.OnButtonClick = CambiarPaleta
            TabOrder = 2
            Width = 180
          end
          object lblOrden: TcxLabel
            Left = 24
            Top = 144
            Caption = 'Orden'
            Transparent = True
          end
          object spnORDEN_ATB: TcxDBSpinEdit
            Left = 144
            Top = 141
            DataBinding.DataField = 'ORDEN_ATB'
            DataBinding.DataSource = dsTablaG
            TabOrder = 3
            Width = 100
          end
          object chkESACTIVO_ATB: TcxDBCheckBox
            Left = 144
            Top = 181
            Caption = 'Activo'
            DataBinding.DataField = 'ESACTIVO_ATB'
            DataBinding.DataSource = dsTablaG
            Properties.ValueChecked = 'S'
            Properties.ValueUnchecked = 'N'
            TabOrder = 4
            Transparent = True
          end
          object lblAyuda: TcxLabel
            Left = 24
            Top = 232
            Caption =
              'Puede cambiar la paleta aunque el color esté en uso.'
            Transparent = True
          end
        end
      end
    end
  end
  inherited dsTablaG: TDataSource
    OnStateChange = dsTablaGStateChange
  end
end
