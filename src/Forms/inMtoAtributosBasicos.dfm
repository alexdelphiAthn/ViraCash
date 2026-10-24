inherited frmMtoAtributosBasicos: TfrmMtoAtributosBasicos
  Caption = 'Atributos b'#225'sicos'
  StyleElements = [seFont, seClient, seBorder]
  TextHeight = 19
  inherited pButtonPage: TPanel
    StyleElements = [seFont, seClient, seBorder]
    inherited pcPantalla: TcxPageControl
      Properties.ActivePage = tsLista
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 2
        ExplicitTop = 29
        ExplicitWidth = 947
        ExplicitHeight = 487
        inherited cxGrdPrincipal: TcxGrid
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            OptionsData.Editing = True
            object cxGrdDBTabPrinID_ATB: TcxGridDBColumn
              Caption = 'ID'
              DataBinding.FieldName = 'ID_ATB'
              Options.Editing = False
              Visible = False
              Width = 60
            end
            object cxGrdDBTabPrinID_VA_ATB: TcxGridDBColumn
              Caption = 'Atributo'
              DataBinding.FieldName = 'ID_VA_ATB'
              PropertiesClassName = 'TcxLookupComboBoxProperties'
              Properties.KeyFieldNames = 'ID_ATB_VA'
              Properties.ListColumns = <
                item
                  Caption = 'C'#243'd'
                  Width = 60
                  FieldName = 'ID_ATB_VA'
                end
                item
                  Caption = 'Nombre'
                  Width = 160
                  FieldName = 'NOMBRE_VA'
                end>
              Properties.ListFieldIndex = 1
              Width = 100
            end
            object cxGrdDBTabPrinCODIGO_ATB: TcxGridDBColumn
              Caption = 'C'#243'digo'
              DataBinding.FieldName = 'CODIGO_ATB'
              Width = 130
            end
            object cxGrdDBTabPrinNOMBRE_ATB: TcxGridDBColumn
              Caption = 'Nombre'
              DataBinding.FieldName = 'NOMBRE_ATB'
              Width = 200
            end
            object cxGrdDBTabPrinDESCRIPCION_ATB: TcxGridDBColumn
              Caption = 'Descripci'#243'n'
              DataBinding.FieldName = 'DESCRIPCION_ATB'
              Width = 240
            end
            object cxGrdDBTabPrinHEX_ATB: TcxGridDBColumn
              Caption = 'Paleta'
              DataBinding.FieldName = 'HEX_ATB'
              OnCustomDrawCell = cxGrdDBTabPrinHEX_ATBCustomDrawCell
              Width = 100
            end
            object cxGrdDBTabPrinVALOR_NUM_ATB: TcxGridDBColumn
              Caption = 'Valor'
              DataBinding.FieldName = 'VALOR_NUM_ATB'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.##;-#,##0.##; '
              HeaderAlignmentHorz = taRightJustify
              Width = 90
            end
            object cxGrdDBTabPrinUNIDAD_ATB: TcxGridDBColumn
              Caption = 'Unidad'
              DataBinding.FieldName = 'UNIDAD_ATB'
              Width = 70
            end
            object cxGrdDBTabPrinORDEN_ATB: TcxGridDBColumn
              Caption = 'Orden'
              DataBinding.FieldName = 'ORDEN_ATB'
              PropertiesClassName = 'TcxSpinEditProperties'
              HeaderAlignmentHorz = taRightJustify
              Width = 80
            end
            object cxGrdDBTabPrinESACTIVO_ATB: TcxGridDBColumn
              Caption = 'Activo'
              DataBinding.FieldName = 'ESACTIVO_ATB'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 70
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        ExplicitLeft = 2
        ExplicitTop = 29
        ExplicitWidth = 947
        ExplicitHeight = 487
        object pnlTopFicha: TPanel
          Left = 0
          Top = 0
          Width = 947
          Height = 285
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          object pnlBodyFicha: TPanel
            Left = 0
            Top = 0
            Width = 947
            Height = 285
            Align = alClient
            BevelOuter = bvNone
            TabOrder = 0
            object lblIdAtb: TcxLabel
              Left = 24
              Top = 16
              Caption = 'ID'
              Transparent = True
            end
            object txtID_ATB: TcxDBTextEdit
              Left = 176
              Top = 13
              DataBinding.DataField = 'ID_ATB'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = True
              TabOrder = 0
              Width = 100
            end
            object lblIdVaAtb: TcxLabel
              Left = 24
              Top = 48
              Caption = 'Atributo (CO, TAL, '#8230')'
              Transparent = True
            end
            object cbbID_VA_ATB: TcxDBLookupComboBox
              Left = 176
              Top = 45
              DataBinding.DataField = 'ID_VA_ATB'
              DataBinding.DataSource = dsTablaG
              Properties.KeyFieldNames = 'ID_ATB_VA'
              Properties.ListColumns = <
                item
                  Caption = 'C'#243'd'
                  Width = 60
                  FieldName = 'ID_ATB_VA'
                end
                item
                  Caption = 'Nombre'
                  Width = 180
                  FieldName = 'NOMBRE_VA'
                end>
              Properties.ListFieldIndex = 1
              TabOrder = 1
              Width = 220
            end
            object lblCodigo: TcxLabel
              Left = 24
              Top = 80
              Caption = 'C'#243'digo'
              Transparent = True
            end
            object txtCODIGO_ATB: TcxDBTextEdit
              Left = 176
              Top = 77
              DataBinding.DataField = 'CODIGO_ATB'
              DataBinding.DataSource = dsTablaG
              TabOrder = 2
              Width = 200
            end
            object lblNombre: TcxLabel
              Left = 24
              Top = 112
              Caption = 'Nombre'
              Transparent = True
            end
            object txtNOMBRE_ATB: TcxDBTextEdit
              Left = 176
              Top = 109
              DataBinding.DataField = 'NOMBRE_ATB'
              DataBinding.DataSource = dsTablaG
              TabOrder = 3
              Width = 320
            end
            object lblDescripcion: TcxLabel
              Left = 24
              Top = 144
              Caption = 'Descripci'#243'n'
              Transparent = True
            end
            object txtDESCRIPCION_ATB: TcxDBTextEdit
              Left = 176
              Top = 141
              DataBinding.DataField = 'DESCRIPCION_ATB'
              DataBinding.DataSource = dsTablaG
              TabOrder = 4
              Width = 520
            end
            object lblHex: TcxLabel
              Left = 24
              Top = 176
              Caption = 'Paleta (HEX)'
              Transparent = True
            end
            object btnHEX_ATB: TcxDBButtonEdit
              Left = 176
              Top = 173
              DataBinding.DataField = 'HEX_ATB'
              DataBinding.DataSource = dsTablaG
              Properties.Buttons = <
                item
                  Default = True
                  Kind = bkEllipsis
                end>
              Properties.OnButtonClick = btnHEX_ATBPropertiesButtonClick
              TabOrder = 5
              Width = 130
            end
            object lblValor: TcxLabel
              Left = 336
              Top = 176
              Caption = 'Valor num'#233'rico'
              Transparent = True
            end
            object txtVALOR_NUM_ATB: TcxDBTextEdit
              Left = 476
              Top = 173
              DataBinding.DataField = 'VALOR_NUM_ATB'
              DataBinding.DataSource = dsTablaG
              TabOrder = 6
              Width = 100
            end
            object lblUnidad: TcxLabel
              Left = 596
              Top = 176
              Caption = 'Unidad'
              Transparent = True
            end
            object txtUNIDAD_ATB: TcxDBTextEdit
              Left = 676
              Top = 173
              DataBinding.DataField = 'UNIDAD_ATB'
              DataBinding.DataSource = dsTablaG
              TabOrder = 7
              Width = 80
            end
            object lblOrden: TcxLabel
              Left = 24
              Top = 208
              Caption = 'Orden'
              Transparent = True
            end
            object spnORDEN_ATB: TcxDBSpinEdit
              Left = 176
              Top = 205
              DataBinding.DataField = 'ORDEN_ATB'
              DataBinding.DataSource = dsTablaG
              TabOrder = 8
              Width = 100
            end
            object chkESACTIVO_ATB: TcxDBCheckBox
              Left = 176
              Top = 240
              Caption = 'Activo'
              DataBinding.DataField = 'ESACTIVO_ATB'
              DataBinding.DataSource = dsTablaG
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              TabOrder = 9
              Transparent = True
            end
          end
        end
      end
    end
  end
end
